return {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      workspace = { checkThirdParty = false },
      -- 整形は stylua（conform.nvim 経由）に任せる
      format = { enable = false },
      hint = { enable = true, arrayIndex = 'Disable' },
      -- vim グローバルの型は lazydev.nvim が供給するため globals 指定は不要
    },
  },
}
