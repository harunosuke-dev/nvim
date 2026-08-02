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
map('n', '<leader>bd', '<cmd>bdelete<CR>', { desc = 'バッファを閉じる' })

-- quickfix（検索結果などの一覧）の開閉。移動は標準の ]q / [q
map('n', '<leader>uq', function()
  local open = false
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      open = true
    end
  end
  vim.cmd(open and 'cclose' or 'copen')
end, { desc = '検索結果の一覧を開閉' })

-- 保存・終了
map('n', '<leader>w', '<cmd>write<CR>', { desc = '保存' })
map('n', '<leader>q', '<cmd>quit<CR>', { desc = '閉じる' })

-- インデント調整後も選択範囲を保持する
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

-- ターミナルモードから抜ける
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'ターミナルモードを抜ける' })
