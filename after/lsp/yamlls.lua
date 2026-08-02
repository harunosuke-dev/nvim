return {
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      -- yamlls 内蔵のスキーマ取得は切り、SchemaStore.nvim 側に一本化する
      -- （両方有効だと同じスキーマが二重に適用されて警告が重複する）
      schemaStore = { enable = false, url = '' },
      schemas = require('schemastore').yaml.schemas(),
    },
  },
}
