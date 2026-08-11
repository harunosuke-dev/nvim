return {
  -- TODO: to-do を書きます
  -- NOTE: note を書きます
  -- FIXME: bag を明示しておきます
  -- HACK: 常套手段でない方法で直しています
  --
  --コメントに色と記号を付け、一覧・ジャンプできるようにする
  {
    'folke/todo-comments.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      signs = true,
      --   info    → TODO
      --   hint    → NOTE, INFO
      --   warning → HACK, WARN, WARNING, XXX
      --   error   → FIX, FIXME, BUG, FIXIT, ISSUE
      colors = {
        info = { '#ff92d0' },
        hint = { '#6ee7a8' },
        warning = { '#ffb86c' },
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
  {
    'dmmulroy/ts-error-translator.nvim',
    ft = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
    opts = {},
  },
}
