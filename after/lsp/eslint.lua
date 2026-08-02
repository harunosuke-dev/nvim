return {
  settings = {
    -- monorepo でもファイルごとに正しい eslint 設定を探させる
    workingDirectories = { mode = 'auto' },
  },
  -- ESLint の自動修正は :EslintFixAll（nvim-lspconfig が定義するコマンド）で行う。
  -- 保存時整形は prettier（conform.nvim）が担当し、役割を分ける
}
