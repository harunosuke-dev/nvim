-- CSS Modules の語彙（composes / :global / :local）を cssls に教える。
-- これが無いと .module.css で「Unknown property: 'composes'」が出続ける。
--
-- 注意: vscode-css-language-server は settings.css.customData を読まない。
-- 実装を追うと 'css/customDataChanged' 通知でのみデータパスを受け取るため、
-- 接続後に自分で通知を送る必要がある（cssServer.js の onNotification 参照）
local custom_data_uri = vim.uri_from_fname(vim.fn.stdpath('config') .. '/data/css-custom-data.json')

return {
  -- on_attach ではなく on_init で送る。on_attach は didOpen と競合し、
  -- データ読み込み前に検証が走って警告が残ってしまう
  on_init = function(client)
    -- params を配列で渡すと JSON-RPC の「位置引数」として展開され、
    -- サーバ側が文字列を受け取ってしまう。配列をもう一段包んで渡す
    client:notify('css/customDataChanged', { { custom_data_uri } })
  end,
  settings = {
    -- @tailwind などの未知の at-rule を使う可能性に備えて警告を抑制
    css = { lint = { unknownAtRules = 'ignore' } },
    scss = { lint = { unknownAtRules = 'ignore' } },
    less = { lint = { unknownAtRules = 'ignore' } },
  },
}
