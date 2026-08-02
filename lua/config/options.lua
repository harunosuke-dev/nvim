local opt = vim.opt

-- 行番号・カーソル
opt.number = true
opt.relativenumber = true -- 相対行番号。3j / 5k のような移動がしやすい
opt.cursorline = true
opt.signcolumn = 'yes' -- 診断アイコンの出入りで画面が横にずれるのを防ぐ
-- 行番号と本文の間に1文字分の余白を入れる。
-- 描画順は 記号(%s) → 行番号(%l) → 続く文字列。
-- 余白は「本文側の色」にする。gutter 色のままだと、本文の左端にある
-- インデントガイド（│）が gutter との境界に接して見づらいため。
-- %{% %} は評価結果をさらに書式として解釈するので、行によって色を変えられる
opt.statuscolumn = "%s%l%{% v:relnum == 0 ? '%#CursorLine#' : '%#Normal#' %} "
opt.scrolloff = 8 -- カーソル上下に最低8行を残す

-- インデント
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true

-- 検索
opt.ignorecase = true
opt.smartcase = true -- 大文字を含む場合のみ大小を区別する
opt.hlsearch = true
opt.inccommand = 'split' -- :%s/foo/bar の置換結果をプレビュー表示

-- 表示
opt.termguicolors = true
opt.wrap = false
opt.splitright = true -- 縦分割は右に開く
opt.splitbelow = true -- 横分割は下に開く
opt.list = true
opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' } -- 不可視文字の可視化
opt.winborder = 'rounded' -- Neovim 0.11+ : フローティングウィンドウの枠を一括指定

-- 折りたたみ（Treesitter の構文木を使う）
-- foldlevel = 99 なので開いた直後は全て展開済み。za / zc / zo で個別に操作する
opt.foldmethod = 'expr'
opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
opt.foldlevel = 99
opt.foldtext = '' -- 折りたたみ行も通常のハイライトで表示する（Neovim 0.10+）

-- ファイル
opt.undofile = true -- Neovim を閉じても undo 履歴を保持
opt.swapfile = false
opt.backup = false

-- 動作
opt.mouse = 'a'
opt.updatetime = 250 -- CursorHold の発火間隔。gitsigns / illuminate の反応速度に効く
opt.timeoutlen = 300 -- which-key のポップアップが出るまでの待ち時間
opt.confirm = true -- 未保存で終了しようとした時にエラーではなく確認を出す

-- 使っていない言語プロバイダを明示的に無効化する。
-- Python / Ruby / Perl / Node の remote plugin は1つも使っておらず、
-- 有効のままだと起動時に実行ファイルを探しに行き :checkhealth も警告し続ける
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

-- システムクリップボードと yank/paste を共有する
-- ※ nvim 内のコピーが常に OS のクリップボードを上書きします。不要なら削除してください
vim.schedule(function()
  opt.clipboard = 'unnamedplus'
end)
