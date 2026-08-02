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
    -- TODO: パンくずをクリックして開くメニューの見た目がまだ整っていない。
    -- 以下は対処済みだが、それでも違和感が残るとの報告あり。原因は未特定。
    --   - NormalFloat / FloatBorder / Pmenu の背景を #3d425c -> #1f2233
    --   - PmenuSbar / PmenuThumb（スクロールバー）を暗い色へ
    --   - PmenuSel（選択行）を #5c638a -> #292e47
    --   - メニュー内のカーソルを選択行と同色にして隠す（config/autocmds.lua）
    -- 次に見るとすれば DropBarMenuHoverEntry（IncSearch にリンク）と
    -- DropBarPreview（Visual にリンク）あたり
    --
    -- dropbar は読み込み時に 200 以上のハイライトを自前で定義する。
    -- カラースキーム側のイベントでは取りこぼすため、ここから当て直す
    config = function(_, opts)
      require('dropbar').setup(opts)
      require('config.highlights').apply()
    end,
    opts = {},
  },

  -- コマンドライン・メッセージ・LSP のホバーをフロートウィンドウに置き換える。
  -- 画面下部の1行を占有していたコマンドラインが浮くため、その分だけ本文が広く使える
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    dependencies = { 'MunifTanjim/nui.nvim' },
    opts = {
      cmdline = {
        enabled = true,
        view = 'cmdline_popup', -- 画面中央付近にフロート表示する
      },
      messages = {
        enabled = true,
        view = 'mini', -- 通常のメッセージは右下に小さく出す
        view_error = 'mini',
        view_warn = 'mini',
        view_history = 'messages', -- :messages は従来どおり全画面
      },
      -- コマンドライン補完の描画は blink.cmp が担当するため、noice 側は使わない。
      -- 両方が有効だとメニューが二重に出る
      popupmenu = { enabled = false },
      notify = { view = 'mini' },
      lsp = {
        -- ホバーやシグネチャの Markdown を Treesitter で色付けする
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
        },
        signature = { enabled = false }, -- blink.cmp が担当
        progress = { enabled = true, view = 'mini' }, -- LSP の初期化進捗
      },
      presets = {
        -- bottom_search は無効。/ による検索も : と同じくフロート表示にする
        long_message_to_split = true, -- 長いメッセージは分割ウィンドウへ逃がす
        lsp_doc_border = true, -- ホバーに枠を付ける
      },
    },
    keys = {
      { '<leader>nh', '<cmd>Noice history<cr>', desc = 'メッセージ・通知の履歴' },
      { '<leader>nl', '<cmd>Noice last<cr>', desc = '直前のメッセージを再表示' },
      { '<leader>nd', '<cmd>Noice dismiss<cr>', desc = '表示中の通知を消す' },
      { '<leader>ne', '<cmd>Noice errors<cr>', desc = 'エラーだけ抽出' },
    },
  },

  -- ステータスライン。Neovim 0.12 の標準ステータスラインにも診断数と LSP の進捗は
  -- 含まれるが、Git ブランチと装飾が無いためこちらに置き換える。
  -- 気に入らなければ <leader>uS で即座に隠せる
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = function()
      -- 控えめな要素はパンくずと同じ色に揃える。WinBar から読むので、
      -- config/highlights.lua 側で色を変えれば自動的に追従する
      local function dim()
        local win_bar = vim.api.nvim_get_hl(0, { name = 'WinBar', link = false })
        return win_bar.fg and string.format('#%06x', win_bar.fg) or nil
      end

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
        icon = '',
        color = { fg = dim() },
        cond = function()
          return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end,
      }

      -- lualine の全区画の背景を、画面上部のパンくず（winbar）と同じ色に揃える。
      -- 区画ごとに背景色が変わる既定の見た目をやめ、上下とも同じ黒い帯にする。
      --
      -- 元の配色（auto テーマ）はカラースキームから生成されるので、
      -- それを土台に背景だけ差し替える。モード表示の区画は
      -- 「濃い文字 + 明るい背景」の作りなので、背景色を文字色へ移して見分けを保つ
      local function flat_theme()
        local ok, auto = pcall(require, 'lualine.themes.auto')
        local win_bar = vim.api.nvim_get_hl(0, { name = 'WinBar', link = false })
        if not ok or not win_bar.bg then
          return 'auto'
        end
        local bg = string.format('#%06x', win_bar.bg)
        local theme = vim.deepcopy(auto)
        for _, mode in pairs(theme) do
          for name, section in pairs(mode) do
            if name == 'a' and section.bg then
              section.fg = section.bg -- モードの色を文字側へ移す
              section.gui = 'bold'
            end
            section.bg = bg
          end
        end
        return theme
      end

      return {
        options = {
          theme = flat_theme(),
          globalstatus = true, -- 分割しても画面下に1本だけ
          icons_enabled = true,
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
        },
        sections = {
          lualine_a = { 'mode' },
          -- Git 情報は lualine_b ではなく lualine_c に置く。
          -- lualine_b はテーマ側が専用の背景色を持つ区画で、
          -- lualine_c なら素の背景のまま表示できる
          lualine_b = {},
          lualine_c = {
            {
              'branch',
              -- 他の控えめな要素と同じ色。太字だけ付けてわずかに目立たせる
              color = { fg = dim(), gui = 'bold' },
              icon = ' ',
            },
            {
              'diff',
              colored = false, -- 追加・変更・削除を色分けしない
              color = { fg = dim() },
              symbols = { added = ' ', modified = ' ', removed = ' ' },
            },
            {
              'diagnostics',
              sources = { 'nvim_diagnostic' },
              update_in_insert = false,
              -- 目立たせるのはエラーと警告だけにする。
              -- 情報とヒントは通常の文字色（lualine_c の既定）に揃える
              diagnostics_color = {
                info = { fg = dim() },
                hint = { fg = dim() },
              },
              -- 記号の列（gitsigns の隣）で使っているものと揃える
              symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' },
            },
          },
          lualine_x = {
            macro,
            { 'searchcount', color = { fg = dim() } },
            lsp,
            { 'filetype', colored = false, color = { fg = dim() } },
          },
          lualine_y = { { 'progress', color = { fg = dim() } } },
          lualine_z = { { 'location', color = { fg = dim() } } },
        },
        -- oil や trouble のウィンドウでは、それぞれに適した表示へ切り替わる
        extensions = { 'oil', 'trouble', 'lazy', 'quickfix', 'mason', 'fzf' },
      }
    end,
  },
}
