-- nvim-treesitter は main ブランチを使う。
-- master は Neovim 0.11 互換のため凍結されており、main とは API が別物。
-- main は遅延ロード非対応なので lazy = false 固定
local parsers = {
  -- Neovim の設定を書くため
  'lua',
  'luadoc',
  'vim',
  'vimdoc',
  'query',
  -- Next.js
  'javascript',
  'typescript',
  'tsx',
  'jsdoc',
  'css',
  'scss',
  'html',
  -- 設定ファイル（jsonc は独立したパーサではなく、Neovim が json に対応付け済み）
  'json',
  'yaml',
  'toml',
  -- ドキュメント
  'markdown',
  'markdown_inline',
  -- シェル
  'bash',
  -- git 関連（lazygit / gitsigns と組み合わせて差分やコミットメッセージを色分け）
  'diff',
  'git_config',
  'git_rebase',
  'gitcommit',
  'gitignore',
  -- その他
  'regex',
  'dockerfile',
}

-- 構文木ベースのテキストオブジェクトを登録する。
-- select は「選択・編集の対象」、move は「ジャンプ先」
local select_maps = {
  ['af'] = { '@function.outer', '関数（宣言ごと）' },
  ['if'] = { '@function.inner', '関数の中身' },
  ['ac'] = { '@class.outer', 'クラス／コンポーネント（宣言ごと）' },
  ['ic'] = { '@class.inner', 'クラス／コンポーネントの中身' },
  ['aa'] = { '@parameter.outer', '引数（区切りのカンマごと）' },
  ['ia'] = { '@parameter.inner', '引数そのもの' },
}

local move_maps = {
  [']f'] = { 'goto_next_start', '@function.outer', '次の関数の先頭へ' },
  ['[f'] = { 'goto_previous_start', '@function.outer', '前の関数の先頭へ' },
  [']F'] = { 'goto_next_end', '@function.outer', '次の関数の末尾へ' },
  ['[F'] = { 'goto_previous_end', '@function.outer', '前の関数の末尾へ' },
  [']a'] = { 'goto_next_start', '@parameter.inner', '次の引数へ' },
  ['[a'] = { 'goto_previous_start', '@parameter.inner', '前の引数へ' },
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').install(parsers)

      -- MDX 専用パーサは無いため markdown パーサを流用する。
      -- JSX 部分はプレーンテキスト扱いになるが、見出し・コード・リンクは色が付く
      vim.treesitter.language.register('markdown', 'mdx')

      -- main ブランチはハイライトを自動で有効化しないので自分で開始する。
      -- パーサ未導入のファイルタイプでは pcall が失敗して素通りする
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('user_treesitter', { clear = true }),
        callback = function(ev)
          -- 巨大ファイルでは起動しない（config/autocmds.lua が立てるフラグ）
          if vim.b[ev.buf].bigfile then
            return
          end
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },

  -- 構文木を使ったテキストオブジェクト。vaf で関数まるごと選択、cif で中身だけ置換など。
  -- textobjects も main ブランチで API が変わっており、キーマップは自前で張る方式
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('nvim-treesitter-textobjects').setup({
        select = {
          lookahead = true, -- カーソルが対象の手前にある時、次の対象まで先読みして選択する
          include_surrounding_whitespace = false,
          selection_modes = {
            ['@function.outer'] = 'V', -- 関数は行単位で選択したほうが扱いやすい
            ['@class.outer'] = 'V',
            ['@parameter.outer'] = 'v',
          },
        },
        move = { set_jumps = true }, -- ジャンプリストに積む（<C-o> で戻れる）
      })

      for key, spec in pairs(select_maps) do
        vim.keymap.set({ 'x', 'o' }, key, function()
          require('nvim-treesitter-textobjects.select').select_textobject(spec[1], 'textobjects')
        end, { desc = spec[2] })
      end

      for key, spec in pairs(move_maps) do
        vim.keymap.set({ 'n', 'x', 'o' }, key, function()
          require('nvim-treesitter-textobjects.move')[spec[1]](spec[2], 'textobjects')
        end, { desc = spec[3] })
      end

      -- 引数の並び替え。foo(a, b) にカーソルを置いて <leader>an で foo(b, a)
      vim.keymap.set('n', '<leader>an', function()
        require('nvim-treesitter-textobjects.swap').swap_next('@parameter.inner')
      end, { desc = '次の引数と入れ替え (Argument Next)' })
      vim.keymap.set('n', '<leader>ap', function()
        require('nvim-treesitter-textobjects.swap').swap_previous('@parameter.inner')
      end, { desc = '前の引数と入れ替え (Argument Previous)' })
    end,
  },

  -- JSX / HTML の閉じタグを自動生成し、開始タグの変更に追従してリネームする
  {
    'windwp/nvim-ts-autotag',
    event = 'InsertEnter',
    opts = {},
  },

  -- 対応する括弧をネストの深さごとに色分けする。
  --
  -- JSX の入れ子や、深くなったオブジェクトリテラルで対応関係を追いやすくする。
  --
  -- 色は VSCode の括弧色分けと同じ3色を循環させる。iceberg の色に寄せると
  -- 本文に溶けて判別できなくなり、色分けした意味がなくなる。素の
  -- rainbow-delimiters の7色（gruvbox 系）は色数が多く騒がしい。
  {
    'HiPhish/rainbow-delimiters.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      -- 色相が大きく離れた3色。隣り合う深さを見分けやすい。
      -- 4段目以降は1段目に戻る（実際のコードで4段を超える入れ子は稀）
      local palette = {
        RainbowDelimiterViolet = '#da70d6', -- 蘭紫（オーキッド）
        RainbowDelimiterBlue = '#179fff', -- 青
        RainbowDelimiterYellow = '#ffd700', -- 金
      }

      local function apply()
        for name, color in pairs(palette) do
          vim.api.nvim_set_hl(0, name, { fg = color })
        end
      end
      apply()
      -- カラースキームを切り替えると独自のハイライトが消えるため当て直す
      vim.api.nvim_create_autocmd('ColorScheme', {
        group = vim.api.nvim_create_augroup('user_rainbow', { clear = true }),
        callback = apply,
      })

      vim.g.rainbow_delimiters = {
        highlight = {
          'RainbowDelimiterViolet',
          'RainbowDelimiterBlue',
          'RainbowDelimiterYellow',
        },
      }
    end,
  },
}
