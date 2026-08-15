local augroup = function(name)
  return vim.api.nvim_create_augroup('user_' .. name, { clear = true })
end

-- yank した範囲を一瞬ハイライトして、何をコピーしたか目視できるようにする
vim.api.nvim_create_autocmd('TextYankPost', {
  group = augroup('highlight_yank'),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- ファイルを開き直した時に前回のカーソル位置へ戻す
vim.api.nvim_create_autocmd('BufReadPost', {
  group = augroup('last_location'),
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- 巨大ファイルを開いた時に、バッファ全体を走査する処理を止める。
-- 13MB / 12万行の TypeScript で Treesitter の全体パースに 1.4 秒かかる実測があり、
-- 生成物・ログ・巨大 JSON を誤って開いた時にフリーズしたように見えるのを防ぐ。
--
-- 色は失われない。Treesitter の代わりに Vim の正規表現 syntax を使う。
-- こちらは画面に見えている範囲だけを遅延処理するため大きなファイルでも軽い。
-- 補完も buffer / path / snippet のソースは動き続ける（消えるのは LSP 由来のみ）
local BIGFILE_SIZE = 1.5 * 1024 * 1024

vim.api.nvim_create_autocmd('BufReadPre', {
  group = augroup('bigfile'),
  callback = function(args)
    local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(args.buf))
    if not stat or stat.size <= BIGFILE_SIZE then
      return
    end

    -- Treesitter と LSP 側はこのフラグを見て自分から降りる
    vim.b[args.buf].bigfile = true

    vim.opt_local.foldmethod = 'manual' -- Treesitter の foldexpr を評価させない
    vim.opt_local.undofile = false
    vim.opt_local.swapfile = false
    vim.opt_local.list = false

    -- filetype 判定より後に走らせる必要があるため schedule する
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(args.buf) then
        vim.bo[args.buf].syntax = vim.bo[args.buf].filetype
      end
    end)

    vim.notify(
      string.format(
        '巨大ファイル（%.1fMB）のため Treesitter と LSP を無効化しました',
        stat.size / 1024 / 1024
      ),
      vim.log.levels.WARN
    )
  end,
})

-- 日本語入力のまま normal モードに戻ると操作できないため、英字へ自動で切り替える。
--
--   InsertLeave  挿入モードを抜けた時。IME で変換中に <Esc> を押した場合、
--                1回目は IME が変換の取り消しに使って nvim に届かないため、
--                2回目で挿入モードを抜けてここが走る
--   FocusGained  tmux でペインを切り替えて nvim に戻ってきた時
--                （tmux.conf の focus-events on が前提）
--   CmdlineLeave コマンドラインを抜けた時
--   VimEnter     起動直後
--
-- 逆方向（英字 → 日本語）は行わない。macism が日本語への切り替えを受け付けず、
-- 指定してもエラーを返さないまま無視されるため。日本語を書く時は手動で切り替える
if vim.fn.has('mac') == 1 and vim.fn.executable('macism') == 1 then
  vim.api.nvim_create_autocmd({ 'InsertLeave', 'FocusGained', 'CmdlineLeave', 'VimEnter' }, {
    group = augroup('ime_ascii'),
    callback = function()
      -- 非同期で実行する。同期だと毎回プロセス起動を待つことになる
      vim.system({ 'macism', 'com.apple.keylayout.ABC' })
    end,
  })
end

-- 外部で書き換えられたファイルを読み直す。
--
-- autoread は既定で有効だが、これは「変更に気づいた時に読み直す」という設定で、
-- 気づくきっかけを自分で作る必要がある。checktime を呼ばない限り、nvim に
-- 留まっている間はバッファが古いまま残る。
--
-- AI エージェントや git の操作でファイルが書き換わる場面が増えたため、
-- 画面に戻った時と手を止めた時に確認する。
--   FocusGained  他のペインやアプリから戻ってきた時（tmux の focus-events が前提）
--   BufEnter     別のバッファへ移った時
--   CursorHold   updatetime のあいだ操作が止まった時
--
-- コマンドラインを開いている最中に読み直すと入力が壊れるため避ける
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'TermClose', 'TermLeave' }, {
  group = augroup('checktime'),
  callback = function()
    if vim.o.buftype == '' and vim.fn.mode() ~= 'c' then
      vim.cmd('checktime')
    end
  end,
})

-- 差分モードの間はカーソル行の強調を切る。
--
-- CursorLine は文字色を持たないと「低優先度」になり（:help hl-CursorLine）、
-- DiffAdd などの背景に負けて色が出ない。その代わりに下線として描かれ、
-- 追加・削除の色に重なって読みにくくなる。
--
-- 差分を見ている間はどの行を見ているかより、どこが変わったかの方が重要なので
-- 強調ごと切る。差分を閉じれば戻る。
--
-- あわせて、変更行の色を左右で塗り分ける。
--
-- Neovim は変更行の地（DiffChange）も、その中で変わった文字（DiffText）も、
-- 左右の窓で同じグループを使う。グループの定義だけでは分けられないので、
-- 窓ごとに効く winhighlight で読み替える。
--   古い側（gitsigns:// で始まるインデックスの写し） → 赤
--   新しい側（編集中のファイル）                     → 緑
--
-- git や GitHub は変更を「削除（赤）+ 追加（緑）」の組として表すので、これで揃う
-- DiffTextAdd（変更行の中で挿入された文字）も左右どちらにも出るので同じ扱いにする。
-- 名前から新しい側だけかと思えるが、実際は古い側にも現れて赤の中に緑が混ざる
local DIFF_WINHL = {
  old = { 'DiffChange:DiffChangeOld', 'DiffText:DiffTextOld', 'DiffTextAdd:DiffTextOld' },
  new = { 'DiffChange:DiffChangeNew', 'DiffText:DiffTextNew', 'DiffTextAdd:DiffTextNew' },
}

--- 自分が足した読み替えを取り除いた winhighlight を返す
local function without_diff_winhl(value)
  local mine = {}
  for _, list in pairs(DIFF_WINHL) do
    for _, item in ipairs(list) do
      mine[item] = true
    end
  end
  local kept = {}
  for item in vim.gsplit(value, ',', { trimempty = true }) do
    if not mine[item] then
      kept[#kept + 1] = item
    end
  end
  return kept
end

vim.api.nvim_create_autocmd('OptionSet', {
  group = augroup('diff_window'),
  pattern = 'diff',
  callback = function()
    vim.wo.cursorline = not vim.wo.diff

    local kept = without_diff_winhl(vim.wo.winhighlight)
    if vim.wo.diff then
      local side = vim.api.nvim_buf_get_name(0):match('^gitsigns://') and 'old' or 'new'
      vim.list_extend(kept, DIFF_WINHL[side])
    end
    vim.wo.winhighlight = table.concat(kept, ',')
  end,
})

-- 読み直した時に気づけるよう通知する。黙って中身が変わると混乱するため
vim.api.nvim_create_autocmd('FileChangedShellPost', {
  group = augroup('checktime_notify'),
  callback = function()
    vim.notify('ファイルが外部で変更されたため読み直しました', vim.log.levels.WARN)
  end,
})

-- 文章を書くファイルで、折り返しの見た目を整える。
--
-- 折り返し自体は全ファイルで有効（lua/config/options.lua）。表が崩れる時は
-- <Space>uw で切る。
--
--   linebreak    単語の途中で切らない
--   breakindent  折り返した行もインデントを保つ
--
-- コードでは単語の途中で切れた方が桁が揃うため、文章系にだけ入れる。
-- j / k と 0 / $ の表示行対応は全ファイル共通なので keymaps.lua にある
local prose_group = augroup('prose_wrap')

vim.api.nvim_create_autocmd('FileType', {
  group = prose_group,
  pattern = { 'markdown', 'mdx', 'text', 'gitcommit', 'gitrebase' },
  callback = function()
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
  end,
})

-- パンくずのメニュー（dropbar）ではカーソルを隠す。
-- 選択行は別途ハイライトされるためカーソルは不要で、
-- ブロックカーソルが白い四角として強く目立ってしまう。
--
-- guicursor は「モード:形状-ハイライトグループ」で色を指定できる。
-- 端末のカーソルは端末エミュレータ自身が描くため blend は効かない。
-- メニューではカーソルが常に選択行の上にあるので、選択行と同じ色にして溶け込ませる
vim.api.nvim_create_autocmd('FileType', {
  group = augroup('hide_cursor'),
  pattern = { 'dropbar_menu', 'dropbar_menu_fzf' },
  callback = function(args)
    -- カーソルのある行と同じ色にして溶け込ませる。
    -- 行の色そのものを読む。以前は PmenuSel から取っていたが、行の
    -- ハイライトを別の色に変えた際にずれて、帯の途中が暗く欠けて見えた
    -- 背景だけ行の色に溶かし、文字色は残す。
    -- fg まで背景色にするとカーソルの下にある文字（フォルダの > など）ごと
    -- 消えてしまう。ブロックだけを消して中身は読めるようにする
    local row = vim.api.nvim_get_hl(0, { name = 'DropBarMenuHoverEntry', link = false })
    local mark = vim.api.nvim_get_hl(0, { name = 'DropBarIconUIIndicator', link = false })
    vim.api.nvim_set_hl(0, 'DropBarMenuCursor', { fg = mark.fg, bg = row.bg })
    local saved = vim.o.guicursor
    vim.opt.guicursor:append('a:DropBarMenuCursor')

    -- メニューを離れたら元に戻す
    vim.api.nvim_create_autocmd({ 'BufLeave', 'BufWipeout' }, {
      buffer = args.buf,
      once = true,
      callback = function()
        vim.o.guicursor = saved
      end,
    })
  end,
})

-- quickfix ウィンドウの操作性を整える
local qf_group = augroup('quickfix')

vim.api.nvim_create_autocmd('FileType', {
  group = qf_group,
  pattern = { 'qf' },
  callback = function(args)
    -- flash.nvim が <CR> をグローバルに奪うため標準動作に戻す。
    -- quickfix の <CR>（該当箇所へジャンプ）はマッピングではなく Vim 組み込みの
    -- 挙動なので、グローバルマップがあると上書きされてしまう
    vim.keymap.set('n', '<CR>', '<CR>', { buffer = args.buf, remap = false, desc = 'Jump to the entry' })

    -- q で閉じる。未割り当てだと q がマクロ記録の開始になり、
    -- 一覧を閉じたつもりで記録が始まる事故が起きる
    vim.keymap.set('n', 'q', '<cmd>cclose<CR>', { buffer = args.buf, desc = 'Close the list' })

    -- j / k で一覧を上下するだけで、対象の位置を隣のウィンドウに追従表示する。
    -- 標準では <CR> を押すまで移動しないため、内容を確かめながら流し読みできない
    vim.api.nvim_create_autocmd('CursorMoved', {
      group = qf_group,
      buffer = args.buf,
      callback = function()
        if vim.fn.getqflist({ size = 0 }).size == 0 then
          return
        end
        local qf_win = vim.api.nvim_get_current_win()
        -- keepjumps を付けないと、一覧を j / k でなぞるたびにジャンプ履歴が積まれ、
        -- あとで <C-o> を押しても元居た場所まで一気に戻れなくなる
        pcall(vim.cmd, 'keepjumps silent! cc ' .. vim.fn.line('.'))
        if vim.api.nvim_win_is_valid(qf_win) then
          vim.api.nvim_set_current_win(qf_win) -- フォーカスは一覧側に戻す
        end
      end,
    })
  end,
})

-- 新規ファイルを初めて保存した時に読み直す。
--
-- 保存すると filetype は判定され Treesitter の色も付くが、LSP だけは起動しない。
-- 読み直すと BufRead から走り直すため起動する。
--
-- BufWritePre の時点でバッファ名は既に付いているので、名前の有無では判定できない。
-- ディスクにまだ実体が無いことを新規ファイルの印にする。
--
-- undo 履歴は失われる。書き始めたばかりの新規ファイルに限るので許容する
local first_write = augroup('reload_after_first_write')

vim.api.nvim_create_autocmd('BufWritePre', {
  group = first_write,
  callback = function(args)
    -- oil のような実ファイルでないバッファ（buftype が空でない）は対象外。
    -- 名前が oil:/// で filereadable も 0 のため、新規ファイルと区別が付かない
    local name = vim.api.nvim_buf_get_name(args.buf)
    vim.b[args.buf].was_new_file = vim.bo[args.buf].buftype == ''
      and name ~= ''
      and vim.fn.filereadable(name) == 0
  end,
})

vim.api.nvim_create_autocmd('BufWritePost', {
  group = first_write,
  callback = function(args)
    if not vim.b[args.buf].was_new_file then
      return
    end
    vim.b[args.buf].was_new_file = nil
    -- BufWritePost の最中は読み直しが効かないため、書き込み完了後に回す
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(args.buf) then
        vim.api.nvim_buf_call(args.buf, function()
          vim.cmd.edit()
        end)
      end
    end)
  end,
})

-- 保存時に行末の余分な空白を削除する
vim.api.nvim_create_autocmd('BufWritePre', {
  group = augroup('trim_whitespace'),
  callback = function(args)
    -- Markdown 系は行末の半角2スペースが「強制改行」を意味するため対象外にする
    local ft = vim.bo[args.buf].filetype
    if ft == 'markdown' or ft == 'mdx' then
      return
    end
    -- checkhealth の出力など読み取り専用バッファでは置換が E21 で失敗する
    if not vim.bo[args.buf].modifiable then
      return
    end
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- 非アクティブなウィンドウの左端の列（行番号・記号・折りたたみ）を沈ませる。
--
-- 本文は NormalNC、パンくずは WinBarNC という標準のグループがあるが、
-- 行番号にあたる LineNrNC は存在しない。ハイライトの定義はウィンドウごとに
-- 変わらないため、winhighlight でその窓だけ読み替える。
--
-- dropbar が同じ仕組みで DropBar* を読み替えているので、値は上書きせず
-- 自分の指定だけを足し引きする。通常のファイルを開いている窓に限り、
-- フロート窓には触らない。色の定義は lua/config/highlights.lua
local GUTTER_NC = {
  -- statuscolumn が %#Normal# を明示しているので、その窓では Normal 自体も
  -- 読み替える。行番号と本文の間の余白がアクティブ側の色で残るのを防ぐ
  'Normal:NormalNC',
  'LineNr:LineNrNC',
  -- 相対行番号ではこの2つが使われる。LineNr だけでは行番号の色が変わらない
  'LineNrAbove:LineNrAboveNC',
  'LineNrBelow:LineNrBelowNC',
  'CursorLineNr:CursorLineNrNC',
  'SignColumn:SignColumnNC',
  'FoldColumn:FoldColumnNC',
  -- カーソル行の帯と、カーソル下の単語のハイライト（illuminate）は消す。
  -- 読む場所ではない窓で「どこにカーソルがあるか」を示す必要はない
  'CursorLine:CursorLineNC',
  'CursorLineSign:CursorLineSignNC',
  'CursorLineFold:CursorLineFoldNC',
  'IlluminatedWordText:IlluminatedWordTextNC',
  'IlluminatedWordRead:IlluminatedWordReadNC',
  'IlluminatedWordWrite:IlluminatedWordWriteNC',
}

--- 自分が足した指定を取り除いた winhighlight を返す
local function without_gutter_nc(value)
  local kept = {}
  for item in vim.gsplit(value, ',', { trimempty = true }) do
    if not vim.tbl_contains(GUTTER_NC, item) then
      kept[#kept + 1] = item
    end
  end
  return kept
end

local function dim_inactive_gutter()
  -- 読み替え先のグループは iceberg 用にしか定義していない。他のテーマでは
  -- 未定義のグループを指すことになり、行番号などが素の色に化ける。
  -- テーマ側に同じ仕組み（kanagawa の dimInactive）があるので任せる
  local enabled = vim.g.colors_name == 'iceberg'
  local current = vim.api.nvim_get_current_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative == '' then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype == '' then
        local items = without_gutter_nc(vim.wo[win].winhighlight)
        if enabled and win ~= current then
          vim.list_extend(items, GUTTER_NC)
        end
        vim.wo[win].winhighlight = table.concat(items, ',')
      end
    end
  end
end

vim.api.nvim_create_autocmd({ 'WinEnter', 'WinNew', 'WinClosed', 'BufWinEnter', 'VimEnter', 'ColorScheme' }, {
  group = augroup('dim_inactive_gutter'),
  callback = vim.schedule_wrap(dim_inactive_gutter),
})

-- キー列の待ち時間をモードごとに変える。
--
-- ノーマルモードには mini.surround の s 始まりのキーがある（saiw) など）。
-- s は単独でも <Nop> として成立するため、次のキーが timeoutlen 以内に来ないと
-- そこで確定してしまい、続きが素の操作として解釈される。150ms では
-- 250ms 間隔の打鍵で `saiw]` が `hiw]ello world` になった（実測）。
--
-- 一方で挿入モードは短いままにしたい。jk で抜ける割り当てがあり、長いと
-- 単独の j を打って止めた時の表示遅れがそのぶん伸びる。
--
-- options.lua の初期値は挿入モード側。ここでノーマルへ戻す時に伸ばす。
-- ノーマル側は Vim の既定値と同じ 1000。s を単独で押すと1秒待って何も
-- 起きないが、s は mini.surround が <Nop> にしているので失うものは無い
local TIMEOUTLEN = { insert = 150, normal = 1000 }

vim.api.nvim_create_autocmd('InsertEnter', {
  group = augroup('timeoutlen_by_mode'),
  callback = function()
    vim.o.timeoutlen = TIMEOUTLEN.insert
  end,
})

vim.api.nvim_create_autocmd({ 'InsertLeave', 'VimEnter' }, {
  group = augroup('timeoutlen_by_mode_leave'),
  callback = function()
    vim.o.timeoutlen = TIMEOUTLEN.normal
  end,
})
