--- カーソルの直前が日本語でないか。補完を出すかどうかの唯一の判定。
---
--- ファイル型では分けない。以前は markdown などで自動ポップアップを止めて
--- いたが、その理由が「日本語を打っている最中に窓が開いては閉じるのが
--- 煩わしい」だったので、条件そのもので判定すれば足りる。
--- コードの中の日本語コメントでも止まり、markdown の英語では出るようになる。
---
--- 入力ソースは見ない。IME の状態を毎キーストローク問い合わせるには macism の
--- プロセス起動が要るため。直前が ASCII のうちは出るので、日本語の文中で
--- 英単語を打ち始めれば戻る
local function is_ascii_context()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if col == 0 then
    return true
  end
  local before = vim.api.nvim_get_current_line():sub(1, col)
  local last = vim.fn.strcharpart(before, vim.fn.strchars(before) - 1, 1)
  local cp = vim.fn.char2nr(last)
  -- 3000-30ff 句読点・ひらがな・カタカナ / 4e00-9fff 漢字 / ff00-ffef 全角
  local japanese = (cp >= 0x3000 and cp <= 0x30ff) or (cp >= 0x4e00 and cp <= 0x9fff) or (cp >= 0xff00 and cp <= 0xffef)
  return not japanese
end

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

      -- ポップアップを出していない時でも候補を送れるようにする。
      --
      -- blink の can_select はメニューが閉じていると素通りする作りで、
      -- on_ghost_text を渡した時だけゴーストテキスト表示中の移動を許す。
      -- 既定の割り当ては渡していないため、文章のファイル（自動ポップアップ
      -- なし）で <C-n> / <C-p> が効かなかった
      ['<C-n>'] = {
        function(cmp)
          return cmp.select_next({ on_ghost_text = true })
        end,
        'fallback_to_mappings',
      },
      ['<C-p>'] = {
        function(cmp)
          return cmp.select_prev({ on_ghost_text = true })
        end,
        'fallback_to_mappings',
      },
      ['<Down>'] = {
        function(cmp)
          return cmp.select_next({ on_ghost_text = true })
        end,
        'fallback',
      },
      ['<Up>'] = {
        function(cmp)
          return cmp.select_prev({ on_ghost_text = true })
        end,
        'fallback',
      },
      -- 挿入モードのカーソル移動を優先する。
      --
      -- super-tab preset は <C-b> / <C-f> をドキュメント窓のスクロールに使うが、
      -- こちらは lua/config/keymaps.lua で1文字ぶんの移動に割り当てている。
      -- documentation.auto_show が有効で候補を選ぶたびに窓が出るため、その間
      -- 移動が効かなくなっていた。空テーブルを渡すとプリセットの割り当てを
      -- 無効化できる（keymap/init.lua:35）。
      --
      -- メニューを出したまま横へ動きたい時はそのまま動いて閉じるのが自然で、
      -- 長い説明はノーマルモードの K（hover）で読める
      ['<C-b>'] = {},
      ['<C-f>'] = {},

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
      ghost_text = {
        -- 日本語を打っている間は出さない。
        --
        -- 日本語には語の区切りが無いので buffer ソースが延々と候補を返し、
        -- 確定するそばから行内に薄い文字が割り込んでくる。IME の変換候補とも
        -- 場所を取り合う。コードを書いている間は今までどおり出す。
        --
        -- enabled は draw_preview() の中で毎回評価されるため、カーソル位置を
        -- 見て切り替えられる（blink.cmp の completion/windows/ghost_text/init.lua）
        enabled = is_ascii_context,
        -- メニューを開いていなくても、選択が無くても1件目を薄く出す
        show_without_selection = true,
        show_without_menu = true,
      },
      menu = {
        border = 'rounded',
        -- 候補の移動はキーボードで行うため不要。
        -- つまみが背景色つきの別ウィンドウとして重なり、右上に四角く見えていた
        scrollbar = false,

        -- 日本語を打っている間だけ自動で出さない。
        -- 区切りが無いので、1文字ごとに文がまるごと候補になってしまう
        auto_show = is_ascii_context,
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
