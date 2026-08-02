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
  { 'folke/tokyonight.nvim', lazy = false },
  { 'rebelot/kanagawa.nvim', lazy = false },
  { 'projekt0n/github-nvim-theme', name = 'github-theme', lazy = false },
}
