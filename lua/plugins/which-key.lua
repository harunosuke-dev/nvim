-- <leader> を押して少し待つと、そこから続くキーの一覧が出る。
-- 各キーマップの desc をそのまま拾うので、説明は定義側に書けばよい
return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  opts = {
    preset = 'helix', -- 画面右側に縦一列で出る。項目数が多くても読みやすい
    -- timeoutlen (150) より小さくする。ポップアップが出る前に
    -- キー列がタイムアウトすると <leader> 操作が中断されてしまう
    delay = 100,
    -- グループ名には由来の英単語を添える。どの頭文字から来ているかが分かると
    -- 覚え直さずに思い出せる（例: f は Find なので ff = Find File）
    spec = {
      { '<leader>a', group = 'Argument 引数' },
      { '<leader>b', group = 'Buffer バッファ' },
      { '<leader>c', group = 'Code コード' },
      { '<leader>f', group = 'Find 探す' },
      { '<leader>g', group = 'Go to 移動 / Git' },
      { '<leader>h', group = 'Hunk 変更のかたまり' },
      { '<leader>n', group = 'Notification 通知' },
      { '<leader>r', group = 'Replace 置換' },
      { '<leader>s', group = 'Session セッション' },
      { '<leader>sn', group = 'NPM パッケージ' },
      { '<leader>u', group = 'UI 表示の切り替え' },
      { '<leader>x', group = '一覧（trouble の慣例）' },
      { ']', group = '次へ' },
      { '[', group = '前へ' },
    },
  },
  keys = {
    {
      '<leader>?',
      function()
        require('which-key').show({ global = false })
      end,
      desc = 'このバッファで使えるキーマップ',
    },
  },
}
