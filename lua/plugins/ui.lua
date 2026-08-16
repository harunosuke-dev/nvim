return {
  -- ファイル種別のアイコン。oil.nvim のファイル一覧や fzf-lua の検索結果で使われる。
  -- 他のプラグインが require した時点で読み込まれるため、遅延ロードのままでよい
  {
    'nvim-tree/nvim-web-devicons',
    lazy = true,
    opts = {},
  },

  -- 各ウィンドウの右上に、ファイル種別アイコンとファイル名を表示する。
  -- Neovim 全体は iceberg のまま、表示部分だけ solarized-osaka の色を使う
  {
    'b0o/incline.nvim',
    event = 'BufReadPre',
    priority = 1200,
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      'craftzdog/solarized-osaka.nvim',
    },
    config = function()
      local colors = require('solarized-osaka.colors').setup()

      require('incline').setup({
        highlight = {
          groups = {
            InclineNormal = { guibg = colors.magenta500, guifg = colors.base04 },
            InclineNormalNC = { guifg = colors.violet500, guibg = colors.base03 },
          },
        },
        window = {
          margin = { vertical = 0, horizontal = 1 },
          overlap = { borders = false },
        },
        hide = { cursorline = true },
        render = function(props)
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ':t')
          if filename == '' then
            filename = '[No Name]'
          end
          if vim.bo[props.buf].modified then
            filename = '[+] ' .. filename
          end

          local icon, color = require('nvim-web-devicons').get_icon_color(filename)
          return {
            { icon or '', guifg = color },
            { icon and ' ' or '' },
            { filename },
          }
        end,
      })
    end,
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
        desc = 'Pick from the breadcrumb bar',
      },
    },
    -- 残っている違和感: パンくず上で選択中の要素（DropBarCurrentContext、
    -- Visual を継承して #282d43）が、パンくず帯の背景 #07080d と揃わず
    -- 別の面のように見える。気になれば bg を #1a1d2e あたりに落とす。
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
      -- 通知は枠付きで右上に出す。mini（右下に小さく1行）より見落としにくい。
      -- 描画は snacks.nvim の notifier に任せる。noice が持つ 'notify' ビューは
      -- nvim-notify を要求するが、snacks は起動画面で既に入っているため
      -- プラグインを増やさずに済む。見逃しても <leader>nh で履歴を遡れる
      notify = { view = 'snacks' },
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
      { '<leader>nh', '<cmd>Noice history<cr>', desc = '[N]otification [h]istory' },
      { '<leader>nl', '<cmd>Noice last<cr>', desc = '[N]otification [l]ast message' },
      { '<leader>nd', '<cmd>Noice dismiss<cr>', desc = '[N]otification [d]ismiss all' },
      { '<leader>ne', '<cmd>Noice errors<cr>', desc = '[N]otification [e]rrors only' },
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

      return {
        options = {
          -- 配色は lua/config/highlights.lua が組み立てる。
          -- カラースキームを切り替えた時も、同じ関数で作り直す
          theme = require('config.highlights').lualine_theme(),
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

  -- 色指定（#7d8296 や rgb(...)）に、その値の色を背景として敷く。
  --
  -- CSS 系は cssls が textDocument/documentColor で同じことをするため除外する。
  -- 両方が描くと二重になる。ここが受け持つのは LSP が色を返さないファイル
  -- （Lua の設定、TSX の inline style、Markdown のドキュメントなど）。
  --
  -- norcalli/nvim-colorizer.lua は更新が止まっているため、保守されている
  -- fork を使う
  {
    'catgoose/nvim-colorizer.lua',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      filetypes = {
        'lua',
        'javascript',
        'javascriptreact',
        'typescript',
        'typescriptreact',
        'html',
        'markdown',
        'mdx',
        'toml',
        'yaml',
        'json',
        'conf',
        'sh',
        'zsh',
      },
      user_default_options = {
        -- 組み込みの document_color と同じ描き方に揃える
        mode = 'background',
        -- 'red' や 'blue' といった英単語は着色しない。
        -- 文章やコード中の普通の単語まで塗られて煩わしいため
        names = false,
        RRGGBBAA = true, -- #rrggbbaa（透明度付き）も拾う
        rgb_fn = true, -- rgb() / rgba()
        hsl_fn = true, -- hsl() / hsla()
      },
    },
  },
}
