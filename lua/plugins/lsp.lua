-- 有効化する LSP サーバ一覧
-- 各サーバの詳細設定は after/lsp/<name>.lua に置く
-- （nvim-lspconfig が配る lsp/<name>.lua の「あと」に読まれ、確実に上書きできる）
local servers = {
  'lua_ls', -- Lua（Neovim の設定を書くため）
  'vtsls', -- TypeScript / JavaScript / React
  'eslint', -- ESLint
  'cssls', -- CSS / SCSS
  'cssmodules_ls', -- CSS Modules（styles.foo から .module.css へ定義ジャンプ）
  'html', -- HTML
  'jsonls', -- JSON（package.json / tsconfig.json のスキーマ補完）
  'bashls', -- sh / bash（shellcheck 連携）
  'marksman', -- Markdown
  'yamlls', -- YAML（GitHub Actions など）
  'taplo', -- TOML
}

-- conform.nvim / bashls から使う外部ツール
local tools = {
  'prettierd', -- JS/TS/CSS/JSON/MD/YAML の整形
  'stylua', -- Lua の整形
  'shfmt', -- シェルスクリプトの整形
  'shellcheck', -- シェルスクリプトの静的解析（bashls が内部で使う）
}

return {
  -- Neovim の Lua API と、読み込み中のプラグインの型定義を lua_ls に食わせる。
  -- これが無いと vim.* が「未定義のグローバル」として警告される
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },

  -- LSP サーバ / フォーマッタのインストーラ
  { 'mason-org/mason.nvim', cmd = 'Mason', opts = {} },

  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'mason-org/mason.nvim',
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      -- jsonls / yamlls にスキーマを供給する（データのみのプラグイン）
      'b0o/SchemaStore.nvim',
    },
    config = function()
      -- 診断表示の設定 -------------------------------------------------------
      vim.diagnostic.config({
        severity_sort = true, -- 同じ行に複数ある場合は深刻なものを優先表示
        underline = { severity = vim.diagnostic.severity.WARN },
        float = { border = 'rounded', source = 'if_many' },
        virtual_text = { spacing = 2, source = 'if_many' },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = ' ',
            [vim.diagnostic.severity.WARN] = ' ',
            [vim.diagnostic.severity.INFO] = ' ',
            [vim.diagnostic.severity.HINT] = ' ',
          },
        },
      })

      -- LSP が接続したバッファにだけ効くキーマップ ---------------------------
      -- 注: Neovim 0.11 以降、以下は標準で割り当て済みなので再定義しない
      --   grn = リネーム / gra = コードアクション / grr = 参照 / gri = 実装
      --   gO  = ドキュメントシンボル / <C-s>(挿入) = シグネチャヘルプ
      --   K   = ホバー / ]d [d = 次/前の診断 / <C-w>d = 診断をフロート表示
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('user_lsp_attach', { clear = true }),
        callback = function(event)
          -- 巨大ファイルには接続しない。サーバ側がプロジェクト全体の解析ごと詰まるため
          if vim.b[event.buf].bigfile then
            vim.schedule(function()
              vim.lsp.buf_detach_client(event.buf, event.data.client_id)
            end)
            return
          end

          -- 色指定（#0d0e14 や rgb(...)）にその場で色を付ける。
          -- Neovim 0.12 の組み込み機能で、サーバから textDocument/documentColor を
          -- 受け取って描く。CSS Modules を書く時に効く。
          -- 対応していないサーバでは何も起きないので、条件を絞らず有効にしてよい
          vim.lsp.document_color.enable(true, { bufnr = event.buf })

          local map = function(keys, fn, desc)
            vim.keymap.set('n', keys, fn, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          -- fzf-lua のピッカー経由にする。候補が1件なら即ジャンプ、
          -- 複数あればプレビュー付きの一覧が出る（jump1 = true）
          map('<leader>gd', '<cmd>FzfLua lsp_definitions jump1=true<cr>', '定義へジャンプ (Go to Definition)')
          map('<leader>gr', '<cmd>FzfLua lsp_references jump1=true<cr>', '参照一覧 (Go to References)')
          map(
            '<leader>gi',
            '<cmd>FzfLua lsp_implementations jump1=true<cr>',
            '実装へジャンプ (Go to Implementation)'
          )
          map('<leader>gt', '<cmd>FzfLua lsp_typedefs jump1=true<cr>', '型定義へジャンプ (Go to Type)')
          map('<leader>gD', vim.lsp.buf.declaration, '宣言へジャンプ (Go to Declaration)')
          map(
            '<leader>gs',
            '<cmd>FzfLua lsp_document_symbols<cr>',
            'このファイルのシンボル一覧 (Go to Symbols)'
          )
          map('<leader>gS', '<cmd>FzfLua lsp_live_workspace_symbols<cr>', '全体のシンボル検索 (Go to Symbols)')

          -- インレイヒント（引数名や推論された型をグレーで行内表示）の切り替え
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method('textDocument/inlayHint') then
            map('<leader>uh', function()
              local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf })
              vim.lsp.inlay_hint.enable(not enabled, { bufnr = event.buf })
            end, 'インレイヒント切り替え (UI Hints)')
          end
        end,
      })

      -- インストールと有効化 -------------------------------------------------
      require('mason-lspconfig').setup({
        ensure_installed = servers,
        automatic_enable = {
          -- 導入済みサーバを自動で vim.lsp.enable() に流す。ただし stylua は除外する:
          -- nvim-lspconfig には stylua を整形専用 LSP として扱う設定が同梱されており、
          -- 整形ツールとして入れた stylua を拾って lua バッファに接続してしまう。
          -- 整形は conform.nvim に一本化するため不要
          exclude = { 'stylua' },
        },
      })

      require('mason-tool-installer').setup({
        ensure_installed = tools,
        run_on_start = true,
      })
    end,
  },
}
