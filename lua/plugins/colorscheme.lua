-- メインは iceberg。他は :colorscheme <name> で即座に切り替えられるよう
-- rtp には載せておく。lazy.nvim は既定で遅延しないので、読み込みの指定は要らない。
-- config は書かない（配色を当てるのは iceberg だけ）
return {
  {
    'oahlen/iceberg.nvim', -- Lua 移植版。Treesitter / LSP セマンティックトークン対応
    lazy = false,
    priority = 1000, -- 他プラグインより先に読み込む
    config = function()
      -- 配色の微調整は lua/config/highlights.lua に集約している
      require('config.highlights').setup()
      vim.cmd.colorscheme('iceberg')
    end,
  },

  -- iceberg
  -- tokyonight
  -- kanagawa
  -- github_dark
  -- everforest
  -- gruvbox, gruvbox-material, gruvbox-minor
  { 'folke/tokyonight.nvim' },
  {
    'rebelot/kanagawa.nvim',
    opts = {
      -- 非アクティブなウィンドウを沈ませる。NormalNC・WinSeparator・WinBarNC の
      -- 背景が bg_dim になる。tmux のペインで同じことをしているのと揃う
      dimInactive = true,

      -- 既定は非アクティブ側を暗くするが、こちらは逆に明るくする。iceberg で
      -- 同じことをしているのに揃え、tmux のペイン（アクティブが暗く、非アクティブが
      -- 明るい）とも向きを合わせる。差は 1.09 倍前後。
      --
      -- 文字も 25% 沈める。既定の fg_dim（oldWhite #c8c093）は本文とほぼ同じ
      -- 明るさで（dragon では 1.10 倍）、色味が変わるだけで沈まないため。
      -- 背景の 1.09 倍だけでは見分けられない
      colors = {
        theme = {
          wave = { ui = { bg_dim = '#262630', fg_dim = '#a5a18c' } },
          dragon = { ui = { bg_dim = '#201e1e', fg_dim = '#939693' } },
        },
      },
    },
  },
  { 'projekt0n/github-nvim-theme', name = 'github-theme' },
  { 'neanias/everforest-nvim' },
  { 'sainnhe/gruvbox-material' },
  { 'ellisonleao/gruvbox.nvim' }, -- 素の gruvbox（Lua 移植版）
  { 'ricardoraposo/gruvbox-minor.nvim' },
  { 'vague-theme/vague.nvim' },
}
