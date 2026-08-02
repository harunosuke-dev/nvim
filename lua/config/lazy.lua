-- lazy.nvim のブートストラップ（未インストールなら自動で clone する）
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    '--branch=stable',
    'https://github.com/folke/lazy.nvim.git',
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'lazy.nvim の clone に失敗しました:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\n何かキーを押すと終了します...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  -- lua/plugins/*.lua を自動で読み込む
  spec = { { import = 'plugins' } },
  install = { colorscheme = { 'iceberg' } },
  checker = { enabled = true, notify = false }, -- 更新チェックはするが通知はしない
  change_detection = { notify = false },
  -- luarocks を必要とするプラグインを1つも使っていないため無効化する。
  -- 有効のままだと hererocks の未導入が :checkhealth のエラーとして残り続ける
  rocks = { enabled = false },
  performance = {
    rtp = {
      -- 標準添付だが使わないプラグインを無効化して起動を早くする
      disabled_plugins = {
        'gzip',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
        'netrwPlugin', -- ファイラは oil.nvim を使うため
      },
    },
  },
})
