return {
  'saghen/blink.cmp',
  -- タグ付きリリースにはビルド済みの Rust バイナリが同梱される。
  -- ブランチ指定にすると手元で cargo build が必要になるのでバージョン指定にする
  version = '1.*',
  -- CmdlineEnter を必ず含める。InsertEnter だけだと、一度も挿入モードに入って
  -- いない状態では blink.cmp 自体が未ロードで、: や / の補完が Neovim 内蔵の
  -- wildmenu にフォールバックしてしまう
  event = { 'InsertEnter', 'CmdlineEnter' },
  dependencies = { 'folke/lazydev.nvim' },
  opts = {
    -- zsh の auto-suggestion と同じ操作感にする。
    -- Tab = 候補があれば確定 / スニペットの穴があれば次へ / どちらも無ければインデント
    -- <C-n> <C-p> または ↑ ↓ で候補移動、<C-e> で取り消し、<C-k> でシグネチャ表示
    keymap = {
      preset = 'super-tab',
      -- スニペットの穴を Enter でも渡れるようにする。
      --
      -- super-tab の Tab はスニペット中だと accept() を先に試す作りで、
      -- 値を打った拍子に補完メニューが開いていると、そちらの確定に取られて
      -- 次の穴へ進めない。Enter は super-tab が使っていないので割り当てる。
      --
      -- 穴が残っていない時は nvim-autopairs の <CR>（括弧を開いて改行）へ
      -- 渡すため、fallback ではなく fallback_to_mappings を使う
      ['<CR>'] = { 'snippet_forward', 'fallback_to_mappings' },
      -- スニペットだけを一覧表示する。名前をうろ覚えのまま呼び出せる。
      -- 通常の補完は英数字を打った時にしか出ず、混ざると探しづらいため分ける
      ['<C-l>'] = {
        function(cmp)
          cmp.show({ providers = { 'snippets' } })
        end,
        'fallback',
      },
    },

    appearance = { nerd_font_variant = 'mono' },

    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
      -- 打つそばから1件目が自動選択され、確定後の姿が行内に薄く出る。
      -- auto_insert は false のまま（true にすると候補を移動しただけで
      -- バッファに実際の文字が入ってしまい、ゴーストテキストと役割が重複する）
      ghost_text = { enabled = true },
      menu = {
        border = 'rounded',
        -- 候補の移動はキーボードで行うため不要。
        -- つまみが背景色つきの別ウィンドウとして重なり、右上に四角く見えていた
        scrollbar = false,
      },
      list = { selection = { preselect = true, auto_insert = false } },
    },

    -- コマンドライン（: や /）の補完。既定でも有効だが、候補一覧は Tab を
    -- 押すまで出ない設定になっている。挿入モードと操作感を揃えて自動表示にする
    cmdline = {
      keymap = {
        preset = 'cmdline',
        -- プリセットは左右キーで候補を移動する割り当てだが直感的でないため、
        -- 上下キーと <C-j> / <C-k> を追加する。
        -- fallback を付けているので、候補が出ていない時は本来の動作
        -- （上下 = コマンド履歴の遡り）がそのまま働く
        ['<Up>'] = { 'select_prev', 'fallback' },
        ['<Down>'] = { 'select_next', 'fallback' },
        ['<C-k>'] = { 'select_prev', 'fallback' },
        ['<C-j>'] = { 'select_next', 'fallback' },
      },
      completion = {
        menu = { auto_show = true },
        ghost_text = { enabled = true },
        -- 既定の preselect = true だと1件目が最初から選択済みになり、
        -- Tab の「候補を選ぶ」処理が不成立になって2件目へ飛んでしまう。
        -- false にすることで、1回目の Tab で1件目が選ばれる
        list = { selection = { preselect = false, auto_insert = true } },
      },
    },

    signature = { enabled = true, window = { border = 'rounded' } },

    -- Neovim 標準の vim.snippet を使う。LuaSnip は入れない
    snippets = { preset = 'default' },

    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer', 'lazydev', 'math' },
      providers = {
        -- 数式定義の id を補完する。blog の public/math-index.json を直接読むので、
        -- 定義を増やしても再生成が要らない。
        -- <MathReference id=" の内側にいる時だけ候補を出す
        math = {
          name = 'Math',
          module = 'config.math_source',
        },
        snippets = {
          opts = {
            -- friendly-snippets の既製スニペットは読み込まない。
            -- <config>/snippets/ に置いた自作分だけを候補に出す
            friendly_snippets = false,
            -- ファイル名がそのまま filetype キーになる（typescriptreact.json など）。
            -- all.json は全ファイルタイプで有効
            search_paths = { vim.fn.stdpath('config') .. '/snippets' },
            -- 継承関係。tsx を書いている時に typescript / javascript の分も出す
            extended_filetypes = {
              typescript = { 'javascript' },
              typescriptreact = { 'typescript', 'javascript' },
              javascriptreact = { 'javascript' },
              mdx = { 'markdown' },
              scss = { 'css' },
            },
          },
        },
        -- Lua 設定ファイルを編集している時だけ Neovim API の補完を最優先で出す
        lazydev = {
          name = 'LazyDev',
          module = 'lazydev.integrations.blink',
          score_offset = 100,
        },
      },
    },

    fuzzy = { implementation = 'prefer_rust_with_warning' },
  },
  opts_extend = { 'sources.default' },

  init = function()
    -- BlinkCmpGhostText は既定で NonText にリンクされる。iceberg の NonText は
    -- #252941 で、背景 #161822 とのコントラスト比が約 1.1:1 しかなく実質見えない。
    -- Comment (#6c7189 / 約 3.7:1) に張り替える。
    -- blink 側は default = true で設定するため、先に定義しておけば上書きされない。
    -- :colorscheme でハイライトは一度消えるので ColorScheme でも張り直す
    local function set_ghost_text_hl()
      vim.api.nvim_set_hl(0, 'BlinkCmpGhostText', { link = 'Comment' })
    end

    vim.api.nvim_create_autocmd('ColorScheme', {
      group = vim.api.nvim_create_augroup('user_blink_ghost_text', { clear = true }),
      callback = set_ghost_text_hl,
    })
    set_ghost_text_hl()
  end,
}
