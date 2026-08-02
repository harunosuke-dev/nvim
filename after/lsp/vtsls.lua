-- 型の推論結果を行内に薄く表示する設定。<leader>uh で表示/非表示を切り替えられる
local inlay_hints = {
  parameterNames = { enabled = 'literals' }, -- foo(true) の "true" が何の引数かを表示
  parameterTypes = { enabled = true },
  variableTypes = { enabled = false }, -- 変数の型まで出すと行が煩雑になるので off
  propertyDeclarationTypes = { enabled = true },
  functionLikeReturnTypes = { enabled = true },
  enumMemberValues = { enabled = true },
}

return {
  settings = {
    typescript = {
      inlayHints = inlay_hints,
      updateImportsOnFileMove = { enabled = 'always' }, -- ファイル移動時に import を自動修正
      -- tsconfig の paths（Next.js の "@/*"）を優先して import を書く
      preferences = { importModuleSpecifier = 'non-relative' },
    },
    javascript = {
      inlayHints = inlay_hints,
      updateImportsOnFileMove = { enabled = 'always' },
    },
    vtsls = {
      autoUseWorkspaceTsdk = true, -- プロジェクトの node_modules の TypeScript を使う
      experimental = {
        completion = { enableServerSideFuzzyMatch = true },
      },
    },
  },
}
