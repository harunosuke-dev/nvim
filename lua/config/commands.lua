-- 設定ファイルを nvim を開いたまま再読込する。
--
-- :source $MYVIMRC だけでは効かない。init.lua が require() で各モジュールを
-- 読んでおり、2回目以降は package.loaded のキャッシュがそのまま返るため、
-- ファイルを書き換えても再実行されないため。明示的にキャッシュを捨てる。
--
-- 対象外（再起動が必要なもの）:
--   - プラグインの opts（lazy.nvim が読み込み時に一度だけ setup へ渡すため）
--   - config.lazy 自体（再実行すると lazy.setup が二重に走る）
local reloadable = {
  'config.options',
  'config.filetype',
  'config.keymaps',
  'config.autocmds',
}

vim.api.nvim_create_user_command('ConfigReload', function()
  for _, mod in ipairs(reloadable) do
    package.loaded[mod] = nil
    require(mod)
  end
  vim.notify('設定を再読込しました: ' .. table.concat(reloadable, ', '), vim.log.levels.INFO)
end, { desc = '設定（lua/config/*）を再読込する' })
