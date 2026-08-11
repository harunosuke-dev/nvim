return {
  -- TODO: to-do を書きます
  -- NOTE: note を書きます
  -- FIXME: bag を直します
  -- HACK: 常套手段でない方法で直しています
  -- TODO: FIXME: HACK: NOTE: などのコメントに色と記号を付け、一覧・ジャンプできるようにする
  {
    'folke/todo-comments.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      signs = true,
      -- highlight.after は既定の 'fg' のまま。キーワードの後ろの本文にも色が付く。
      -- 一度 after = '' にして本文を通常のコメント色へ戻したが、目印がバッジだけに
      -- なって見落とすため戻した
      -- バッジの色は「iceberg の構文色に無い値」を直接指定する。
      -- 既定は Diagnostic* を参照するが、iceberg では次のように構文と衝突し、
      -- コード中で目印として働かない（実測値）。
      --   DiagnosticInfo  #89b9c2 = 文字列リテラル（String / @string）
      --   DiagnosticHint  #6c7189 = コメント（色が付いていないように見える）
      --   DiagnosticWarn  #e2a578 = 見出し（Title）
      --
      -- 指定するのは**色名**であってキーワード名ではない。対応は次の通り。
      --   info    → TODO
      --   hint    → NOTE, INFO
      --   warning → HACK, WARN, WARNING, XXX
      --   error   → FIX, FIXME, BUG, FIXIT, ISSUE
      -- colors.note や colors.hack と書いても参照するキーワードが無いため
      -- 何も起きない
      colors = {
        info = { '#ff92d0' }, -- TODO : ピンク
        hint = { '#6ee7a8' }, -- NOTE : 緑。構文色に緑系が無いので埋もれない
        warning = { '#ffb86c' }, -- HACK / WARN : オレンジ。#e2a578 は見出しと同色
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
