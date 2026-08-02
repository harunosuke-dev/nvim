return {
  -- ファイル種別のアイコン。oil.nvim のファイル一覧や fzf-lua の検索結果で使われる。
  -- 他のプラグインが require した時点で読み込まれるため、遅延ロードのままでよい
  {
    'nvim-tree/nvim-web-devicons',
    lazy = true,
    opts = {},
  },

  -- 画面上部にパンくずを表示する。ディレクトリ階層に加えて、
  -- カーソルが今どの関数・クラスの中にいるかを LSP / Treesitter から取得して並べる。
  -- 各要素は選択でき、そこからファイルやシンボルへ直接ジャンプできる
  {
    'Bekaboo/dropbar.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    keys = {
      {
        '<leader>;',
        function()
          require('dropbar.api').pick()
        end,
        desc = 'パンくずから選択してジャンプ',
      },
    },
    opts = {},
  },

  -- ステータスライン。Neovim 0.12 の標準ステータスラインにも診断数と LSP の進捗は
  -- 含まれるが、Git ブランチと装飾が無いためこちらに置き換える。
  -- 気に入らなければ <leader>uS で即座に隠せる
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = function()
      -- マクロ記録中の表示。q の誤爆で記録が始まった時に気づけるようにする
      local macro = {
        function()
          local reg = vim.fn.reg_recording()
          return reg ~= '' and ('recording @' .. reg) or ''
        end,
        color = { fg = '#e27878', gui = 'bold' }, -- iceberg の赤
      }

      -- 接続中の LSP サーバ名。補完が効かない時に切り分けられる
      local lsp = {
        function()
          local names = {}
          for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
            table.insert(names, client.name)
          end
          return table.concat(names, ' ')
        end,
        icon = ' ',
        cond = function()
          return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end,
      }

      return {
        options = {
          theme = 'auto', -- カラースキームに追従する
          globalstatus = true, -- 分割しても画面下に1本だけ
          icons_enabled = true,
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
        },
        -- アイコンは末尾に空白を含めて指定する。既定のままだと
        -- アイコンと数字が詰まって読みにくいため
        sections = {
          lualine_a = { 'mode' },
          lualine_b = {
            { 'branch', icon = ' ' },
            {
              'diff',
              symbols = { added = ' ', modified = ' ', removed = ' ' },
            },
          },
          lualine_c = {
            {
              'diagnostics',
              sources = { 'nvim_diagnostic' },
              update_in_insert = false,
              -- 記号の列（gitsigns の隣）で使っているものと揃える
              symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' },
            },
          },
          lualine_x = { macro, 'searchcount', lsp, { 'filetype', icon_only = false } },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
        -- oil や trouble のウィンドウでは、それぞれに適した表示へ切り替わる
        extensions = { 'oil', 'trouble', 'lazy', 'quickfix', 'mason', 'fzf' },
      }
    end,
  },
}
