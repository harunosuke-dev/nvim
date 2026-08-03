-- ここにはプラグインに依存しないキーマップだけを置く。
-- プラグイン固有のものは lua/plugins/*.lua の keys = {} に書く（遅延ロードを効かせるため）
local map = vim.keymap.set

-- 検索ハイライトを消す
map('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = '検索ハイライト解除' })

-- ウィンドウ間の移動
map('n', '<C-h>', '<C-w>h', { desc = '左のウィンドウへ' })
map('n', '<C-j>', '<C-w>j', { desc = '下のウィンドウへ' })
map('n', '<C-k>', '<C-w>k', { desc = '上のウィンドウへ' })
map('n', '<C-l>', '<C-w>l', { desc = '右のウィンドウへ' })

-- ウィンドウ分割
map('n', '<leader>-', '<C-w>s', { desc = '横に分割' })
map('n', '<leader>\\', '<C-w>v', { desc = '縦に分割' })

-- バッファ操作
map('n', '<S-h>', '<cmd>bprevious<CR>', { desc = '前のバッファ' })
map('n', '<S-l>', '<cmd>bnext<CR>', { desc = '次のバッファ' })
map('n', '<leader>bd', '<cmd>bdelete<CR>', { desc = 'バッファを閉じる (Buffer Delete)' })

-- quickfix（検索結果などの一覧）の開閉。移動は標準の ]q / [q
map('n', '<leader>uq', function()
  local open = false
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      open = true
    end
  end
  vim.cmd(open and 'cclose' or 'copen')
end, { desc = '検索結果の一覧を開閉 (UI Quickfix)' })

-- ステータスラインの表示を切り替える。画面を1行広く使いたい時や、
-- 表示が邪魔に感じた時にすぐ消せるようにしている
map('n', '<leader>uS', function()
  vim.o.laststatus = vim.o.laststatus == 0 and 3 or 0
  vim.notify('ステータスライン: ' .. (vim.o.laststatus == 0 and '非表示' or '表示'))
end, { desc = 'ステータスラインの表示 (UI Statusline)' })

-- 保存・終了
map('n', '<leader>w', '<cmd>write<CR>', { desc = '保存' })
map('n', '<leader>q', '<cmd>quit<CR>', { desc = '閉じる' })

-- インデント調整後も選択範囲を保持する
-- 行の折り返しを切り替える。
--
-- 文章のファイルでは既定で折り返すが、表を書いている最中は折り返さない方が
-- 桁が揃って見やすい。その場で切り替えられるようにする
map('n', '<leader>uw', function()
  local on = not vim.wo.wrap
  vim.wo.wrap = on
  vim.notify('折り返し: ' .. (on and 'する' or 'しない'))
end, { desc = '行の折り返しを切り替え (UI Wrap)' })

map('x', '<', '<gv', { desc = 'インデントを減らす' })
map('x', '>', '>gv', { desc = 'インデントを増やす' })

-- 選択した行をまとめて上下に移動する
map('x', 'J', ":m '>+1<CR>gv=gv", { desc = '選択行を下へ移動' })
map('x', 'K', ":m '<-2<CR>gv=gv", { desc = '選択行を上へ移動' })

-- スクロール・検索移動のあとカーソルを画面中央に寄せる
map('n', '<C-d>', '<C-d>zz', { desc = '半画面下スクロール' })
map('n', '<C-u>', '<C-u>zz', { desc = '半画面上スクロール' })
map('n', 'n', 'nzzzv', { desc = '次の検索結果' })
map('n', 'N', 'Nzzzv', { desc = '前の検索結果' })

-- 挿入モードを抜ける。ホームポジションから手を動かさずに済む。
-- jk（隣の指へ転がす）と jj（同じ指を2回）のどちらでも抜けられるようにしている。
-- どちらも1文字目が j なので、待ち時間の挙動は同じ。
--
-- 注: j を1文字だけ打って手を止めると、2文字目を待つ間（timeoutlen）表示が遅れる。
-- 日本語入力中は IME が j を握って nvim に届かないためこの割り当ては働かない
-- （その場合は <Esc> を2回押す。1回目は IME の変換取り消しに使われる）
for _, lhs in ipairs({ 'jk', 'jj' }) do
  map('i', lhs, '<Esc>', { desc = '挿入モードを抜ける' })
end

-- ターミナルモードから抜ける
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'ターミナルモードを抜ける' })
