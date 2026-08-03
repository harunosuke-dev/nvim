local opt = vim.opt

-- 行番号・カーソル
opt.number = true
opt.relativenumber = true -- 相対行番号。3j / 5k のような移動がしやすい
opt.cursorline = true
opt.signcolumn = 'yes' -- 診断アイコンの出入りで画面が横にずれるのを防ぐ
-- 行番号と本文の間に余白を入れる。
-- 描画順は 記号(%s) → 行番号(%l) → 余白 → 続く文字列。
--
-- 余白は行番号側と本文側に1つずつ置き、数字が両側の境界に接しないようにする。
--   %l の直後の空白    行番号の列の色（%{% %} より前なので既定の色のまま）
--   %{% %} の後の空白  本文側の色
--
-- 本文側を gutter 色のままにすると、本文の左端にあるインデントガイド（│）が
-- gutter との境界に接して見づらい。
-- %{% %} は評価結果をさらに書式として解釈するので、行によって色を変えられる
opt.statuscolumn = "%s%l %{% v:relnum == 0 ? '%#CursorLine#' : '%#Normal#' %} "
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
-- キー列の入力を待つ時間。jk で挿入モードを抜ける割り当てがあるため、
-- 短いほど「単独の j を打って止めた時の表示遅れ」が減り、jk の判定も厳しくなる。
-- <leader> 操作は which-key がポップアップを出した時点で待ち受けに入るため、
-- この値を下げても猶予は短くならない（which-key の delay をこれより小さくすること）
opt.timeoutlen = 150
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
