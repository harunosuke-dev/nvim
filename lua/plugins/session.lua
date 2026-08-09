-- 作業ディレクトリごとにセッション（開いていたバッファ・分割・カーソル位置）を
-- ディスクへ保存する。ファイルとして残るので PC を再起動してもまたいで復元できる。
--
-- 起動時の自動復元はしない。意図せず前回の状態に戻ると混乱するため、
-- <leader>ss で明示的に読み込む方式にしている
return {
  'folke/persistence.nvim',
  event = 'BufReadPre',
  opts = {
    -- 復元する要素。既定から folds を足している（Treesitter の折りたたみ状態を保つ）
    options = { 'buffers', 'curdir', 'tabpages', 'winsize', 'folds' },
  },
  keys = {
    {
      '<leader>ss',
      function()
        require('persistence').load()
      end,
      desc = '[S]ession re[s]tore for this dir',
    },
    {
      '<leader>sl',
      function()
        require('persistence').load({ last = true })
      end,
      desc = '[S]ession [l]oad the last one',
    },
    {
      '<leader>sd',
      function()
        require('persistence').stop()
      end,
      desc = '[S]ession [d]o not save this time',
    },
  },
}
