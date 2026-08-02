return {
  -- プロジェクト全体の検索・置換。検索結果が編集可能なバッファとして開き、
  -- そこを書き換えて一括反映する。fzf-lua は「探して1つ開く」ためのもので
  -- 置換の手段が無いため、役割が重複しない
  {
    'MagicDuck/grug-far.nvim',
    cmd = 'GrugFar',
    opts = { headerMaxWidth = 80 },
    keys = {
      {
        '<leader>rr',
        function()
          require('grug-far').open({ transient = true })
        end,
        desc = 'プロジェクト全体を検索・置換',
      },
      {
        '<leader>rw',
        function()
          require('grug-far').open({ transient = true, prefills = { search = vim.fn.expand('<cword>') } })
        end,
        desc = 'カーソル下の単語を検索・置換',
      },
      {
        '<leader>rf',
        function()
          require('grug-far').open({
            transient = true,
            prefills = { paths = vim.fn.expand('%') },
          })
        end,
        desc = 'このファイル内を検索・置換',
      },
    },
  },

  -- 1行に詰まった記述と複数行の記述を相互に変換する。
  -- 構文木を使うので、カンマや括弧の整合が崩れない。
  -- 例: { a: 1, b: 2 } ⇄ 各プロパティを1行ずつ、JSX の props の折り返しなど
  {
    'Wansmer/treesj',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    keys = {
      {
        '<leader>j',
        function()
          require('treesj').toggle()
        end,
        desc = '1行 ⇄ 複数行 を切り替え',
      },
    },
    opts = {
      use_default_keymaps = false, -- 既定の gJ / gS は張らない（S は flash が使う）
      max_join_length = 150,
    },
  },

  -- package.json を開くと各依存の最新版を行末に表示し、その場で更新できる
  {
    'vuki656/package-info.nvim',
    dependencies = { 'MunifTanjim/nui.nvim' },
    ft = 'json',
    opts = {
      hide_up_to_date = true, -- 最新のものは表示しない（更新が必要なものだけ目立たせる）
      package_manager = 'npm',
    },
    keys = {
      {
        '<leader>ns',
        function()
          require('package-info').show({ force = true })
        end,
        desc = '依存の最新版を表示',
      },
      {
        '<leader>nu',
        function()
          require('package-info').update()
        end,
        desc = 'カーソル行の依存を更新',
      },
      {
        '<leader>nc',
        function()
          require('package-info').change_version()
        end,
        desc = 'バージョンを選んで変更',
      },
    },
  },
}
