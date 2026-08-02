-- Neovim 標準では判定されない拡張子をここで補う。
-- プラグイン読み込みより前（init.lua の時点）で登録しないと、
-- 起動直後に開いたファイルの判定に間に合わない
vim.filetype.add({
  extension = {
    -- MDX は独立したファイルタイプとして扱う（prettier での整形と
    -- Treesitter のハイライトが効く）。LSP は現状割り当てていない:
    -- mdx-analyzer 0.6.3 が依存の vscode-uri の破壊的変更で起動できないため
    mdx = 'mdx',
  },
  filename = {
    ['.env'] = 'sh',
  },
  pattern = {
    ['.*/%.vscode/.*%.json'] = 'jsonc', -- VSCode の設定はコメント付き JSON
    ['%.env%.[%w_.-]+'] = 'sh', -- .env.local / .env.production など
  },
})
