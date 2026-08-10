local opt = vim.opt

-- 行番号・カーソル
opt.number = true
opt.relativenumber = true -- 相対行番号。3j / 5k のような移動がしやすい
opt.cursorline = true
opt.signcolumn = 'yes' -- 診断アイコンの出入りで画面が横にずれるのを防ぐ
-- 描画順は 行番号(%l) → 余白 → 記号(%s) → 続く文字列。
--
-- 記号は既定では左端（行番号の手前）に出るが、本文の近くにある方が
-- 「どの行が変わったか」と本文を一度に見られる。余白の位置へ移す。
--
-- カーソル行だけ余白を本文と同じ色にして、帯が行番号の列から本文まで
-- 途切れずに繋がるようにする。%{% %} は評価結果をさらに書式として解釈するので、
-- 行によって色を変えられる。
--
-- &cursorline も見る。差分モードでは帯そのものを切っている
-- （lua/config/autocmds.lua）ため、これを見ないと行番号の右の1桁だけが
-- 塗られて取り残される。
--
-- 差分の色で行番号の列まで塗ることは諦めた。%l は「行番号の列」を描く項目で
-- 自前で LineNr 系のハイライトを当てるため、先に %#...# を置いても上書きされる。
-- 番号を自分で描けば色は乗るが、桁幅と LineNr / LineNrAbove / LineNrBelow /
-- CursorLineNr の振り分けまで再現することになり、見合わない
opt.statuscolumn = "%l %{% v:relnum == 0 && &cursorline ? '%#CursorLine#' : '%#LineNr#' %}%s"
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
--
-- 本文の背景を塗らず、端末の背景を透けさせる。
-- ここで nvim_set_hl を直接呼んでも、この後に読まれるカラースキームが
-- Normal を塗り直すため効かない。フラグを見て lua/config/highlights.lua が
-- 最後に適用する
vim.g.transparent_background = true
opt.termguicolors = true
-- 長い行は折り返す。j / k は表示行で動かし、回数を付けた時だけ論理行にするので
-- （lua/config/keymaps.lua）、折り返していても相対行番号とずれない
opt.wrap = true
opt.splitright = true -- 縦分割は右に開く
opt.splitbelow = true -- 横分割は下に開く
opt.list = true
opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' } -- 不可視文字の可視化

-- 差分表示で、片側にしか無い行の反対側に敷かれる埋め文字。
-- 既定は - で、削除された量だけ ---------- が並んで目を引く。
-- 空白にすると、その分の高さだけ空いて位置合わせだけが残る
opt.fillchars:append({ diff = ' ' })

-- 差分モードに入ると foldcolumn が 2 になる（:help 'diffopt' の foldcolumn:{n}）。
-- statuscolumn の幅は %C を書いていなくても foldcolumn に合わせて広がるため、
-- 使っていない2桁が余白として空く。折りたたみ自体は zo / zc / za / zR で
-- 操作できるので、列は出さない
opt.diffopt:append('foldcolumn:0')
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
opt.autoread = true

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

-- clipboard は既定（空）のまま使う。
--
-- unnamedplus を入れると、ヘルプに明記されている通り yank だけでなく
-- delete・change・put まで OS のクリップボードを経由する。そのため
-- 「コピーした語を貼ろうとしたら、途中で消した行に変わっていた」という
-- 事故が起きる。d でクリップボードを上書きして嬉しい場面はほとんどない。
--
-- 代わりに y だけを "+ へ送る（lua/config/keymaps.lua）。d や x の内容は
-- Vim のレジスタに残るので p で貼れるが、OS 側は汚さない
