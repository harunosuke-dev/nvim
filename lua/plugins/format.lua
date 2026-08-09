-- prettierd を優先し、無ければ prettier にフォールバックする。
-- prettierd は常駐して起動コストを省くデーモン版で、保存時整形の待ち時間が短い
local prettier = { 'prettierd', 'prettier', stop_after_first = true }

local formatters_by_ft = {
  lua = { 'stylua' },
  sh = { 'shfmt' },
  bash = { 'shfmt' },
}

for _, ft in ipairs({
  'javascript',
  'javascriptreact',
  'typescript',
  'typescriptreact',
  'css',
  'scss',
  'less',
  'html',
  'json',
  'jsonc',
  'yaml',
  'markdown',
  'mdx',
}) do
  formatters_by_ft[ft] = prettier
end

return {
  'stevearc/conform.nvim',
  event = 'BufWritePre',
  cmd = 'ConformInfo',
  keys = {
    {
      '<leader>cf',
      function()
        require('conform').format({ async = true })
      end,
      mode = { 'n', 'x' },
      desc = '[C]ode [F]ormat',
    },
  },
  opts = {
    formatters_by_ft = formatters_by_ft,
    -- 対応するフォーマッタが無いファイルタイプは LSP の整形機能にフォールバック
    default_format_opts = { lsp_format = 'fallback' },
    format_on_save = function(bufnr)
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return nil
      end
      return { timeout_ms = 1000, lsp_format = 'fallback' }
    end,
  },
  init = function()
    -- gq で conform の整形を使えるようにする
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

    -- 一時的に保存時整形を切るためのコマンド。
    -- 他人のリポジトリを触る時など、整形差分でノイズを出したくない場面用
    vim.api.nvim_create_user_command('FormatDisable', function(args)
      if args.bang then
        vim.b.disable_autoformat = true -- このバッファだけ
      else
        vim.g.disable_autoformat = true -- 全体
      end
    end, { desc = 'Disable format on save (! for this buffer)', bang = true })

    vim.api.nvim_create_user_command('FormatEnable', function()
      vim.b.disable_autoformat = false
      vim.g.disable_autoformat = false
    end, { desc = 'Enable format on save' })
  end,
}
