return {
  settings = {
    json = {
      -- SchemaStore.nvim が package.json / tsconfig.json / .eslintrc などの
      -- スキーマを供給する。キー名の補完と値の検証が効くようになる
      schemas = require('schemastore').json.schemas(),
      validate = { enable = true },
    },
  },
}
