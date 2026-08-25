-- 有効化する LSP サーバ一覧
-- 各サーバの詳細設定は after/lsp/<name>.lua に置く
-- （nvim-lspconfig が配る lsp/<name>.lua の「あと」に読まれ、確実に上書きできる）
local servers = {
  'lua_ls', -- Lua（Neovim の設定を書くため）
  'vtsls', -- TypeScript / JavaScript / React
  'eslint', -- ESLint
  'cssls', -- CSS / SCSS
  'cssmodules_ls', -- CSS Modules（styles.foo から .module.css へ定義ジャンプ）
  'css_variables', -- CSS カスタムプロパティ（var(--x) の補完と定義ジャンプ）
  'html', -- HTML
  'jsonls', -- JSON（package.json / tsconfig.json のスキーマ補完）
  'bashls', -- sh / bash（shellcheck 連携）
  'marksman', -- Markdown
  'yamlls', -- YAML（GitHub Actions など）
  'taplo', -- TOML
}

-- NOTE: CSS 系は3つが同じバッファに attach する。
-- cssls が構文検証、cssmodules_ls がクラス名のジャンプ、css_variables が変数を担う。
-- cssls と css_variables は var(--x) の候補が重なる。
-- lua/plugins/completion.lua の transform_items で cssls 側を落としている。

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
      -- 注: 以下は Neovim 標準で割り当て済みなので再定義しない
      --   gO = ドキュメントシンボル / <C-s>(挿入) = シグネチャヘルプ
      --   K  = ホバー / ]d [d = 次/前の診断 / <C-w>d = 診断をフロート表示
      --
      -- 一方 gr* （Neovim 0.11 以降の LSP 用プレフィックス）は使わない。
      -- 参照一覧を gr の2打鍵で出したいので、gr に nowait を付けて即発火させる。
      -- その代わり gr で始まる標準マップは全て届かなくなるため、下記へ移してある。
      --
      --   grn リネーム       → <leader>cr
      --   gra コードアクション → <leader>ca
      --   grr 参照           → gr / <leader>gr
      --   gri 実装           → gI / <leader>gi
      --   grt 型定義         → gT / <leader>gt
      --   grx コードレンズ    → 再定義しない（有効化しているサーバが出さない）
      --   grD 宣言           → 再定義しない。vtsls / lua_ls では定義と同じ位置を返すか
      --                        未対応で、押しやすい場所を割く価値がない
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

          local map = function(keys, fn, desc, opts)
            vim.keymap.set(
              'n',
              keys,
              fn,
              vim.tbl_extend('force', { buffer = event.buf, desc = 'LSP: ' .. desc }, opts or {})
            )
          end

          -- fzf-lua のピッカー経由にする。候補が1件なら即ジャンプ、
          -- 複数あればプレビュー付きの一覧が出る（jump1 = true）
          --
          -- 2打鍵の g 系と、一覧から選べる <leader>g 系の両方を張る。
          -- g 系はどれも Vim のビルトインを潰しているので、何を失うか記しておく:
          --   gd → ローカル宣言へジャンプ（テキスト検索ベースで C 向け。LSP が上位互換）
          --   gr → gr{char} 仮想置換（R や r で代替できる）
          --   gI → 1列目から挿入（0i で代替できる。gi「前回の挿入位置」は温存する）
          --   gT → 前のタブページへ（タブを使わない構成のため。gt は残る）
          map('<leader>gd', '<cmd>FzfLua lsp_definitions jump1=true<cr>', '[G]o to [D]efinition')
          map('gd', '<cmd>FzfLua lsp_definitions jump1=true<cr>', '[G]o to [D]efinition')

          map('<leader>gr', '<cmd>FzfLua lsp_references jump1=true<cr>', '[G]o to [R]eferences')
          -- nowait が要る。付けないと Neovim 標準の grn / gra / grr / gri / grt / grx が
          -- 残っているせいで gr が確定せず、timeoutlen（150ms）待たされる。
          -- 付けると gr で始まる標準マップは全て届かなくなる（移設先は上のコメント）
          map('gr', '<cmd>FzfLua lsp_references jump1=true<cr>', '[G]o to [R]eferences', { nowait = true })

          map('<leader>gi', '<cmd>FzfLua lsp_implementations jump1=true<cr>', '[G]o to [I]mplementation')
          map('gI', '<cmd>FzfLua lsp_implementations jump1=true<cr>', '[G]o to [I]mplementation')

          map('<leader>gt', '<cmd>FzfLua lsp_typedefs jump1=true<cr>', '[G]o to [T]ype definition')
          map('gT', '<cmd>FzfLua lsp_typedefs jump1=true<cr>', '[G]o to [T]ype definition')

          map('<leader>gs', '<cmd>FzfLua lsp_document_symbols<cr>', '[G]o to [S]ymbols in this file')
          map('<leader>gS', '<cmd>FzfLua lsp_live_workspace_symbols<cr>', '[G]o to [S]ymbols in workspace')

          -- gr に潰される標準マップの移設先。Code グループ（<leader>c）へ寄せる。
          -- リネームはカーソル下の識別子を、プロジェクト全体の参照ごと一括で改名する
          map('<leader>cr', vim.lsp.buf.rename, '[C]ode [R]ename')
          -- コードアクションは選択範囲にも出せるよう、標準の gra と同じくビジュアルモードでも受ける
          vim.keymap.set({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action, {
            buffer = event.buf,
            desc = 'LSP: [C]ode [A]ction',
          })

          -- インレイヒント（引数名や推論された型をグレーで行内表示）の切り替え
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method('textDocument/inlayHint') then
            map('<leader>uh', function()
              local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf })
              vim.lsp.inlay_hint.enable(not enabled, { bufnr = event.buf })
            end, '[U]I inlay [H]ints : toggle')
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
