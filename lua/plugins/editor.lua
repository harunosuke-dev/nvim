return {
  -- カーソル下の単語と同じものを画面内で薄くハイライトする。
  -- LSP が使える場面では「同じ綴りの別物」を除いた正確な参照だけを光らせる
  {
    'RRethy/vim-illuminate',
    event = { 'BufReadPost', 'BufNewFile' },
    keys = {
      {
        ']]',
        function()
          require('illuminate').goto_next_reference(false)
        end,
        desc = '次の同じ識別子へ',
      },
      {
        '[[',
        function()
          require('illuminate').goto_prev_reference(false)
        end,
        desc = '前の同じ識別子へ',
      },
    },
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
      -- 背景色に変える。Visual にリンクしておけばカラースキームを変えても追従する
      local function set_hl()
        for _, group in ipairs({ 'IlluminatedWordText', 'IlluminatedWordRead', 'IlluminatedWordWrite' }) do
          vim.api.nvim_set_hl(0, group, { link = 'Visual' })
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

  -- 囲み文字の操作。ys=追加 / ds=削除 / cs=変更
  -- 例: ysiw" で単語を "" で囲む、cs"' で "..." を '...' に変える、ds" で外す
  {
    'kylechui/nvim-surround',
    event = 'VeryLazy',
    opts = {},
  },

  -- インデントの深さを縦線で示す。scope は現在のブロックだけを強調する
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      indent = { char = '│' },
      scope = { enabled = true, show_start = false, show_end = false },
      exclude = {
        filetypes = {
          'help',
          'lazy',
          'mason',
          'oil',
          'trouble',
          'checkhealth',
          'gitcommit',
          'markdown',
        },
      },
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
        desc = '画面内の任意の位置へジャンプ',
      },
      {
        '<leader><CR>',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').treesitter()
        end,
        desc = '構文ノード単位で選択を広げる',
      },
      {
        'r',
        mode = 'o',
        function()
          require('flash').remote()
        end,
        desc = '離れた位置を操作対象にする（例: yr で遠くの単語をコピー）',
      },
      {
        '<C-s>',
        mode = 'c',
        function()
          require('flash').toggle()
        end,
        desc = '検索中に Flash を切り替える',
      },
    },
  },

  -- w / e / b を camelCase・snake_case の区切りで止める。
  -- getUserName を getUserName の3語として扱えるので、長い識別子の一部だけを
  -- 直せる。新しいキーは増えず、既存の移動が細かくなるだけ
  {
    'chrisgrieser/nvim-spider',
    keys = {
      { 'w', function() require('spider').motion('w') end, mode = { 'n', 'o', 'x' }, desc = '次の語へ（camelCase 単位）' },
      { 'e', function() require('spider').motion('e') end, mode = { 'n', 'o', 'x' }, desc = '語の末尾へ（camelCase 単位）' },
      { 'b', function() require('spider').motion('b') end, mode = { 'n', 'o', 'x' }, desc = '前の語へ（camelCase 単位）' },
      { 'ge', function() require('spider').motion('ge') end, mode = { 'n', 'o', 'x' }, desc = '前の語の末尾へ（camelCase 単位）' },
    },
    opts = {
      -- 記号だけの塊は語として数えない。`)` や `;` で細かく止まると煩わしい
      skipInsignificantPunctuation = true,
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
