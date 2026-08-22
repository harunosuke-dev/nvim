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

-- バッファ操作は barbar が持つ（lua/plugins/ui.lua）。
-- 移動は標準どおり ]b / [b だが、タブの並び順で動くよう barbar 側へ差し替えてある。
-- H / L に割り当てる設定は広く見かけるが、素の Vim では「画面の最上行 /
-- 最下行へ」という毎日使う移動キーで、潰すと素の環境で戸惑う

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

-- j / k は表示行で動かす。ただし回数を付けた時（5j など）は論理行のままにする。
-- 相対行番号が示すのは論理行なので、数字を打った時はそちらに従う方が合う。
-- 折り返しを切っている間は gj と j が同じ動作になるので、常に入れておいてよい
for _, key in ipairs({ 'j', 'k' }) do
  map({ 'n', 'x' }, key, function()
    return vim.v.count > 0 and key or ('g' .. key)
  end, { expr = true, desc = 'Move by display line' })
end
-- 行頭・行末も表示行に合わせる
map({ 'n', 'x' }, '0', 'g0', { desc = 'Start of the display line' })
map({ 'n', 'x' }, '$', 'g$', { desc = 'End of the display line' })

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

-- 挿入モードの移動・削除を emacs 方式に寄せる。ノーマルモードは一切変えない。
-- シェル（zsh は bindkey -e）と指の使い方を揃えるため。
-- dotfiles 側の vim（packages/vim/.config/vim/vimrc）にも同じものを入れてある。
--
-- 挿入中に行頭・行末へ飛ぶ標準の手段は <Esc>I / <Esc>A でモードを抜けるしかなく、
-- ここは実用上の穴になっている。
--
-- 置き換える標準と、その代わりの手段:
--   i_CTRL-A  直前に挿入したテキストを再挿入   出番が少ない
--   i_CTRL-E  下の行の同じ桁の文字をコピー     出番が少ない（上の行は C-y で残る）
--   i_CTRL-B  現代の Vim では未使用            失うものが無い
--   i_CTRL-F  現在行を再インデント             ノーマルの == で足りる
--   i_CTRL-D  インデントを一段戻す             下の <S-Tab> に同じものを置く
--
-- ノーマルの <C-a>（数値を増やす）は Vim の看板機能なので標準のまま残す。
--
-- blink.cmp は <C-e> <C-b> <C-f> を握っているが問題にならない。preset の
-- 末尾にある fallback は「blink 以外の割り当てがあればそれを実行する」作りで
-- （keymap/fallback.lua:54-64）、補完メニューが開いている時だけ blink の動作、
-- 閉じている時はここの割り当てになる。fallback_to_mappings との違いは
-- 「割り当てが1つも無かった時に組み込み動作へ渡すかどうか」だけ
map('i', '<C-a>', '<C-o>I', { desc = 'Start of line' })
map('i', '<C-e>', '<End>', { desc = 'End of line' })
map('i', '<C-b>', '<Left>', { desc = 'Back one character' })
map('i', '<C-f>', '<Right>', { desc = 'Forward one character' })
map('i', '<C-d>', '<Del>', { desc = 'Delete character under cursor' })

-- 上で潰した i_CTRL-D の代わり。インデントを一段戻す。
-- blink.cmp が <S-Tab> を snippet_backward に使っているが、これも fallback
-- なのでスニペットの穴が無い時だけこちらが動く
map('i', '<S-Tab>', '<C-\\><C-o><<', { desc = 'Dedent line' })

-- 触らない標準。emacs と意味が違うが、Vim 側の機能を残す価値が上回る
--   i_CTRL-K  ダイグラフ入力（<C-k>ae → æ）。blink のシグネチャ表示も載っている
--   i_CTRL-N  キーワード補完 / blink の候補送り
--   i_CTRL-P  同上（前の候補）
--   i_CTRL-R  レジスタの内容を挿入
--   i_CTRL-O  一発だけノーマルモードのコマンドを実行
--   i_CTRL-T  インデントを一段深くする
--   i_CTRL-V  次の1文字をそのまま入れる
--   i_CTRL-Y  上の行の同じ桁の文字をコピー
-- i_CTRL-H（Backspace）・i_CTRL-W（前の単語を削除）・i_CTRL-U（カーソルより
-- 前を削除）は元から emacs と同じ動きなので何もしなくてよい

-- 挿入モードを抜けるのは <Esc> / <C-[> だけにする。
-- jj / jk は j を1文字打って手を止めた時に timeoutlen ぶん表示が遅れるうえ、
-- 日本語入力中は IME が j を握るため働かない

-- ターミナルモードから抜ける
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
