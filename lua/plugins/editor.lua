return {
  -- カーソル下の単語と同じものを画面内で薄くハイライトする。
  -- LSP が使える場面では「同じ綴りの別物」を除いた正確な参照だけを光らせる
  {
    'RRethy/vim-illuminate',
    event = { 'BufReadPost', 'BufNewFile' },
    -- 移動用のキーマップ（]] / [[ で同じ識別子へ）は張らない。
    -- 素の Vim ではセクション移動に割り当てられており、基本方針として標準は潰さない。
    -- このプラグインの主目的である「同じ識別子を薄く光らせる」表示だけを使う
    config = function()
      require('illuminate').configure({
        delay = 200,
        -- 上から順に試し、使えるものを採用する。
        -- lsp = 意味を理解した参照、treesitter = 構文上の同一シンボル、regex = 単純な文字列一致
        providers = { 'lsp', 'treesitter', 'regex' },
        filetypes_denylist = {
          'oil',
          'trouble',
          'lazy',
          'mason',
          'help',
          'checkhealth',
          'fzf',
          'gitcommit',
        },
        large_file_cutoff = 2000, -- 行数がこれを超えたら regex 版を使わない
      })

      -- 既定は下線だが、診断の警告表示にも下線を使っているため区別がつかない。
      -- 背景色に変える。色はカラースキームから引くので :colorscheme に追従する。
      --
      -- Visual を link しない理由が2つある。
      --
      --   1. Visual は背景しか持たない。colorizer が色コードへ付けた文字色
      --      （明るい色ほど黒くなる）が残り、黒背景に黒文字で読めなくなる
      --   2. Visual の背景はカーソル行との差が 1.16:1 しかなく、帯が見えない
      --
      -- 背景は Visual を 1.7 倍に持ち上げて 1.91:1 にし、文字色は Normal を明示する。
      -- この組み合わせで文字と背景は 4.98:1（WCAG AA の 4.5:1 以上）になる
      local function brighten(color, factor)
        local r = math.min(255, math.floor(math.floor(color / 65536) % 256 * factor + 0.5))
        local g = math.min(255, math.floor(math.floor(color / 256) % 256 * factor + 0.5))
        local b = math.min(255, math.floor(color % 256 * factor + 0.5))
        return r * 65536 + g * 256 + b
      end

      local function set_hl()
        local visual = vim.api.nvim_get_hl(0, { name = 'Visual', link = false })
        local normal = vim.api.nvim_get_hl(0, { name = 'Normal', link = false })
        -- 背景を持たないカラースキームでは Visual への link に戻す
        local hl = visual.bg and { bg = brighten(visual.bg, 1.7), fg = normal.fg } or { link = 'Visual' }
        for _, group in ipairs({ 'IlluminatedWordText', 'IlluminatedWordRead', 'IlluminatedWordWrite' }) do
          vim.api.nvim_set_hl(0, group, hl)
        end
      end
      vim.api.nvim_create_autocmd('ColorScheme', {
        group = vim.api.nvim_create_augroup('user_illuminate_hl', { clear = true }),
        callback = set_hl,
      })
      set_hl()
    end,
  },

  -- 括弧・引用符の自動補完。check_ts で構文木を見るため、
  -- 文字列やコメントの中では余計な補完をしない
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {
      check_ts = true,
      fast_wrap = {}, -- 挿入モードで <M-e> を押すと、カーソル後方の語を括弧で包む
    },
  },

  -- 囲み文字の操作。sa=追加 / sd=削除 / sr=置換 / sf=端へ飛ぶ / sh=光らせる
  -- 例: saiw) で単語を () で囲む、sr"' で "..." を '...' に変える、sd" で外す
  --
  -- vim-surround 系（nvim-surround の ys / cs / ds）から乗り換えた。
  -- ys の y は「you surround」の語呂で、yank とは無関係。読み違えやすい。
  -- こちらは surround add / replace / delete がそのまま語になっている。
  --
  -- 前置が s なので、素の Vim の s（1文字消して挿入）は単独で押すと
  -- timeoutlen ぶん待ってから動く。消えるわけではない。
  -- この設定は timeoutlen = 150 なので遅延は 0.15 秒（実測で確認済み）。
  --
  -- mini.ai と同じ n（次）/ l（前）の修飾子が使えるのも揃っていて良い
  {
    'echasnovski/mini.surround',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      n_lines = 500, -- mini.ai と揃える。対象を探す範囲
      -- 探索は既定の 'cover'（カーソルを覆っている囲みだけ）。外にいる時は
      -- n / l を挟んで向きを指定する（sdn" で次、sdl" で前）。
      -- 打鍵を減らしたくなったら下を有効にする。覆っていない時に前方を探すので
      -- n を省ける。代わりにどこが対象か目で確かめずに打つことになる
      -- search_method = 'cover_or_next',
    },
  },

  -- 2文字打つと画面内の該当箇所にラベルが出て、そのラベルキーで飛べる。
  -- f/t の1文字移動も強化され、行をまたいで検索できるようになる
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {
      modes = {
        -- f / F / t / T / ; / , を横取りして強化するモード。
        --
        -- 既定では飛んだ後もモードが続き、画面が沈んだまま次の候補へ 1打鍵で
        -- 飛べる状態が残る。押したのに終わっていない感覚になるので、
        -- 飛んだ時点で沈みを解除する。探している間だけ沈む形になる。
        --
        -- ; と , での繰り返しはそのまま使える
        char = { autohide = true },
      },
    },
    keys = {
      -- 起動は <CR>。標準の s（1文字消して挿入）と S（行を消して挿入）を
      -- 潰さずに済む。<CR> の標準動作は「次の行の先頭へ」で、+ が同じ働きをする。
      -- quickfix など <CR> に固有の意味がある場所では config/autocmds.lua で戻している
      {
        '<CR>',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').jump()
        end,
        desc = 'Jump anywhere on screen',
      },
      {
        '<leader><CR>',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').treesitter()
        end,
        desc = 'Expand selection by syntax node',
      },
      {
        'r',
        mode = 'o',
        function()
          require('flash').remote()
        end,
        desc = '[R]emote flash, then a motion (yr + iw)',
      },
      {
        '<C-s>',
        mode = 'c',
        function()
          require('flash').toggle()
        end,
        desc = 'Toggle flash labels while searching',
      },
    },
  },

  -- 括弧・引用符のテキストオブジェクトを賢くする。
  --
  -- 関数・クラス・引数（af if ac ic aa ia）は nvim-treesitter-textobjects が
  -- 持っており、そちらが優先される（Vim は長い方の割り当てを選ぶため、
  -- af は treesitter、a( は mini.ai に渡る）。
  --
  -- mini.ai が足すのは素の Vim より賢い括弧・引用符の扱い。
  --   ci(  カーソルが括弧の手前にあっても、次の括弧の中を対象にする
  --   ci"  複数行にまたがる文字列でも効く
  --   2i(  2つ外側の括弧の中
  {
    'echasnovski/mini.ai',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      n_lines = 500, -- 対象を探す範囲。大きなファイルでも関数全体を拾える
    },
  },
}
