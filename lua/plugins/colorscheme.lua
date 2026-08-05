-- メインは iceberg。他は :colorscheme <name> で即座に切り替えられるよう
-- rtp には載せておき、起動時の処理は走らせない（lazy = false / config なし）
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

  -- 以下は試用candidate。:colorscheme で切り替えて確認する
  -- iceberg / iceberg-light
  -- tokyonight / tokyonight-night / tokyonight-storm / tokyonight-moon / tokyonight-day
  -- kanagawa / kanagawa-wave / kanagawa-dragon / kanagawa-lotus
  -- github_dark / github_dark_default / github_dark_dimmed / github_dark_high_contrast
  -- everforest
  -- gruvbox-material
  -- gruvbox
  { 'folke/tokyonight.nvim', lazy = false },
  {
    'rebelot/kanagawa.nvim',
    lazy = false,
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
  { 'projekt0n/github-nvim-theme', name = 'github-theme', lazy = false },

  -- 明るさは vim.g.everforest_background で 'hard' / 'medium' / 'soft'
  { 'neanias/everforest-nvim', lazy = false },

  -- 同じ作者の gruvbox-material。vim.g.gruvbox_material_background で明るさ、
  -- vim.g.gruvbox_material_foreground で 'material' / 'mix' / 'original'
  { 'sainnhe/gruvbox-material', lazy = false },

  -- 素の gruvbox（Lua 移植版）
  { 'ellisonleao/gruvbox.nvim', lazy = false },
}
