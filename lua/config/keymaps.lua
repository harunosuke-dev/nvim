-- ここにはプラグインに依存しないキーマップだけを置く。
-- プラグイン固有のものは lua/plugins/*.lua の keys = {} に書く（遅延ロードを効かせるため）
--
-- desc の書き方（この設定全体の規則。プラグイン側の keys = {} にも同じものを使う）
--
--   [U]I [W]rap : toggle line wrap
--   └ 括弧を拾うとキー ┘ └ 動作の説明 ┘
--
-- 1. 括弧に入れた文字を順に読むとキーそのものになる（kickstart.nvim の流儀）。
--    <leader>ws → [W]indow [S]plit、gd → [G]o to [D]efinition。
--    ただし語呂が成り立つ時だけ。こじつけになるなら括弧を使わず説明だけ書く
--    （<leader>gg → Open lazygit）
-- 2. ` : ` は「何をするか」の説明の前にだけ置く。
--    範囲や対象の限定は説明ではないので、区切らずそのまま続ける。
--      [F]ind [F]ile under home        ← 範囲。: を使わない
--      [U]I [W]rap : toggle line wrap  ← 動作。: を使う
-- 3. 全体で 49 桁まで。which-key（helix preset）は win.width.max = 60 で、
--    行に使えるのは box_width - layout.spacing = 57 桁（view.lua:346）。
--    そこからキー列・区切り・アイコン列を引いた残りが desc に回る
-- 4. 日本語は混ぜない。1文字で2桁を食うため、途中で切れて読めなくなる
--    （説明を厚くしたい時は :help か、この設定のコメント側に書く）
local map = vim.keymap.set

-- 検索ハイライトを消す
map('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })

-- ウィンドウ間の移動
map('n', '<C-h>', '<C-w>h', { desc = 'Move focus to the left window' })
map('n', '<C-j>', '<C-w>j', { desc = 'Move focus to the lower window' })
map('n', '<C-k>', '<C-w>k', { desc = 'Move focus to the upper window' })
map('n', '<C-l>', '<C-w>l', { desc = 'Move focus to the right window' })

-- ウィンドウ操作。素の Vim の Ctrl+w に全部揃っているので、そちらを覚えるのが
-- 本筋。ただし分割は使用頻度が高いので、押しやすい場所にも置く。
-- 一覧では機能ごとに1箇所へまとまる
map('n', '<leader>ws', '<C-w>s', { desc = '[W]indow [S]plit horizontal' })
map('n', '<leader>wv', '<C-w>v', { desc = '[W]indow split [V]ertical' })
-- 閉じる・サイズ変更は Ctrl+w q / Ctrl+w o / Ctrl+w = などに揃っている

-- バッファ操作
-- バッファの移動は Neovim 0.11 標準の ]b / [b を使う。
-- H / L に割り当てる設定は広く見かけるが、素の Vim では「画面の最上行 /
-- 最下行へ」という毎日使う移動キーで、潰すと素の環境で戸惑う
map('n', '<leader>bd', '<cmd>bdelete<CR>', { desc = '[B]uffer [D]elete' })

-- quickfix（検索結果などの一覧）の開閉。移動は標準の ]q / [q
map('n', '<leader>uq', function()
  local open = false
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      open = true
    end
  end
  vim.cmd(open and 'cclose' or 'copen')
end, { desc = '[U]I [Q]uickfix : toggle the list' })

-- ステータスラインの表示を切り替える。画面を1行広く使いたい時や、
-- 表示が邪魔に感じた時にすぐ消せるようにしている
map('n', '<leader>uS', function()
  vim.o.laststatus = vim.o.laststatus == 0 and 3 or 0
  vim.notify('ステータスライン: ' .. (vim.o.laststatus == 0 and '非表示' or '表示'))
end, { desc = '[U]I [S]tatusline : toggle' })

-- 保存と終了は標準どおりコマンドラインから（:w / :q）。
-- ノーマルモードに「保存だけ」のキーは無く、ZZ が保存して終了、
-- ZQ が保存せず終了。ウィンドウを閉じるのは Ctrl+w q

-- インデント調整後も選択範囲を保持する
-- 行の折り返しを切り替える。
--
-- 文章のファイルでは既定で折り返すが、表を書いている最中は折り返さない方が
-- 桁が揃って見やすい。その場で切り替えられるようにする
map('n', '<leader>uw', function()
  local on = not vim.wo.wrap
  vim.wo.wrap = on
  vim.notify('折り返し: ' .. (on and 'する' or 'しない'))
end, { desc = '[U]I [W]rap : toggle line wrap' })

map('x', '<', '<gv', { desc = 'Indent left : keep selection' })
map('x', '>', '>gv', { desc = 'Indent right : keep selection' })

-- 選択した行をまとめて上下に移動する
map('x', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
map('x', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })

-- スクロール・検索移動のあとカーソルを画面中央に寄せる
map('n', '<C-d>', '<C-d>zz', { desc = 'Scroll down : keep cursor centered' })
map('n', '<C-u>', '<C-u>zz', { desc = 'Scroll up : keep cursor centered' })
map('n', 'n', 'nzzzv', { desc = 'Next match : keep cursor centered' })
map('n', 'N', 'Nzzzv', { desc = 'Prev match : keep cursor centered' })

-- yank だけを OS のクリップボードへ送る。
--
-- clipboard=unnamedplus にすると d や x や c まで OS 側を上書きしてしまい、
-- コピーしておいた内容が消える（lua/config/options.lua の注記を参照）。
--
-- レジスタを明示すると無名レジスタにも同じ内容が入るので、y のあとは p で
-- そのまま貼れる。d や x の内容も無名レジスタに入るため p で貼れるが、
-- そちらは OS には出て行かない。
--
-- 逆向き（他のアプリでコピーしたものを貼る）は "+p
map({ 'n', 'x' }, 'y', '"+y', { desc = 'Yank to system clipboard' })
map('n', 'Y', '"+y$', { desc = 'Yank to end of line into clipboard' })
map('x', 'Y', '"+Y', { desc = 'Yank whole lines into clipboard' })

-- * / g* を「その場に留まる」動きにする。
--
-- 標準の * は検索語を登録したうえで次の出現へ飛ぶ。そのため cgn で置換を
-- 始めると1つ目が飛ばされる。直後に N で戻せば済むが、毎回打つことになる。
--
-- keepjumps を通すのは、行って戻る2回ぶんがジャンプリストに載るのを防ぐため。
-- Ctrl-o の戻り先が * を押すたびに埋まらない
map('n', '*', '<Cmd>keepjumps normal! *N<CR>', { desc = 'Search word : stay in place' })
map('n', 'g*', '<Cmd>keepjumps normal! g*N<CR>', { desc = 'Search partial word : stay in place' })

-- 挿入モードを抜ける。ホームポジションから手を動かさずに済む。
-- jk（隣の指へ転がす）と jj（同じ指を2回）のどちらでも抜けられるようにしている。
-- どちらも1文字目が j なので、待ち時間の挙動は同じ。
--
-- 注: j を1文字だけ打って手を止めると、2文字目を待つ間（timeoutlen）表示が遅れる。
-- 日本語入力中は IME が j を握って nvim に届かないためこの割り当ては働かない
-- （その場合は <Esc> を2回押す。1回目は IME の変換取り消しに使われる）
for _, lhs in ipairs({ 'jk', 'jj' }) do
  map('i', lhs, '<Esc>', { desc = 'Exit insert mode' })
end

-- ターミナルモードから抜ける
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
