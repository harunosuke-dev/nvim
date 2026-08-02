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
      desc = 'このディレクトリのセッションを復元',
    },
    {
      '<leader>sl',
      function()
        require('persistence').load({ last = true })
      end,
      desc = '最後に使ったセッションを復元',
    },
    {
      '<leader>sd',
      function()
        require('persistence').stop()
      end,
      desc = '今回は保存しない（一時的な作業用）',
    },
  },
}
