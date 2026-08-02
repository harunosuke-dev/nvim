-- <leader> を押して少し待つと、そこから続くキーの一覧が出る。
-- 各キーマップの desc をそのまま拾うので、説明は定義側に書けばよい
return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  opts = {
    preset = 'helix', -- 画面右側に縦一列で出る。項目数が多くても読みやすい
    delay = 300, -- timeoutlen と揃えている
    spec = {
      { '<leader>a', group = '引数（Treesitter）' },
      { '<leader>b', group = 'バッファ' },
      { '<leader>c', group = 'コード' },
      { '<leader>f', group = '検索（fzf-lua）' },
      { '<leader>g', group = 'Git / LSP ジャンプ' },
      { '<leader>h', group = 'Git hunk' },
      { '<leader>n', group = 'npm パッケージ' },
      { '<leader>r', group = '検索・置換' },
      { '<leader>s', group = 'セッション' },
      { '<leader>u', group = '表示の切り替え' },
      { '<leader>x', group = '一覧（trouble）' },
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
