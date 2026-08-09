return {
  -- TODO: FIXME: HACK: NOTE: などのコメントに色と記号を付け、一覧・ジャンプできるようにする
  {
    'folke/todo-comments.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      signs = true,
      highlight = {
        -- キーワードの後ろの本文まで着色すると、コメント全体が主張して読みにくい。
        -- 空にすると通常のコメント色に戻り、目印はバッジだけになる
        after = '',
      },
      colors = {
        -- TODO のバッジ色。既定は DiagnosticInfo を参照するが、iceberg では
        -- それが文字列リテラル（String / @string）と同じ #89b9c2 で、
        -- コード中に埋もれてしまう。本文で使われていない色を直接指定する
        info = { '#ff92d0' },
      },
    },
    keys = {
      { '<leader>ft', '<cmd>TodoFzfLua<cr>', desc = '[F]ind [T]odo in this project' },
      {
        ']t',
        function()
          require('todo-comments').jump_next()
        end,
        desc = 'Next TODO comment',
      },
      {
        '[t',
        function()
          require('todo-comments').jump_prev()
        end,
        desc = 'Prev TODO comment',
      },
    },
  },

  -- 診断・シンボル・検索結果を、閉じずに置いておける一覧として表示する。
  -- fzf-lua が「絞り込んで1つ選ぶ」ためのものなのに対し、
  -- こちらは「一覧を開いたまま順に潰していく」用途に向く
  {
    'folke/trouble.nvim',
    cmd = 'Trouble',
    opts = {
      focus = true, -- 開いたらそのウィンドウにカーソルを移す
    },
    keys = {
      { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Diagnostics list in project' },
      {
        '<leader>xX',
        '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
        desc = 'Diagnostics list in this file',
      },
      {
        '<leader>xs',
        '<cmd>Trouble symbols toggle win.position=right<cr>',
        desc = 'Symbol tree on the right',
      },
      { '<leader>xl', '<cmd>Trouble lsp toggle win.position=right<cr>', desc = 'LSP defs and refs on the right' },
      { '<leader>xt', '<cmd>Trouble todo toggle<cr>', desc = 'TODO list, keep it open' },
      { '<leader>xq', '<cmd>Trouble qflist toggle<cr>', desc = 'Quickfix list in trouble' },
    },
  },

  -- TypeScript のエラーメッセージを平易な文に置き換える。
  --
  -- tsserver のエラーは型の全体を展開して出すため、原因が文章に埋もれる。
  -- 置き換え後は「何が期待されていて、実際は何が来たのか」が先に来る。
  --
  -- 完全に自動で、キー操作は不要。訳出先は日本語ではなく平易な英語
  {
    'dmmulroy/ts-error-translator.nvim',
    ft = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
    opts = {},
  },
}
