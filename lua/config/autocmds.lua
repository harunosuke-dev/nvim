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

-- 読み直した時に気づけるよう通知する。黙って中身が変わると混乱するため
vim.api.nvim_create_autocmd('FileChangedShellPost', {
  group = augroup('checktime_notify'),
  callback = function()
    vim.notify('ファイルが外部で変更されたため読み直しました', vim.log.levels.WARN)
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
    local sel = vim.api.nvim_get_hl(0, { name = 'PmenuSel', link = false })
    vim.api.nvim_set_hl(0, 'DropBarMenuCursor', { fg = sel.fg, bg = sel.bg })
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
    vim.keymap.set('n', '<CR>', '<CR>', { buffer = args.buf, remap = false, desc = '該当箇所へジャンプ' })

    -- q で閉じる。未割り当てだと q がマクロ記録の開始になり、
    -- 一覧を閉じたつもりで記録が始まる事故が起きる
    vim.keymap.set('n', 'q', '<cmd>cclose<CR>', { buffer = args.buf, desc = '一覧を閉じる' })

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
