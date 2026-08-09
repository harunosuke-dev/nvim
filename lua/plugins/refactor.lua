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
        desc = '[R]eplace across the project',
      },
      {
        '<leader>rw',
        function()
          require('grug-far').open({ transient = true, prefills = { search = vim.fn.expand('<cword>') } })
        end,
        desc = '[R]eplace [w]ord under cursor',
      },
      {
        '<leader>rf',
        function()
          require('grug-far').open({
            transient = true,
            prefills = { paths = vim.fn.expand('%') },
          })
        end,
        desc = '[R]eplace in this [f]ile',
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
        desc = '[J]oin or split into lines',
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
      -- <leader>n は通知（noice）が使うため、npm 関連は <leader>sn 配下に置く。
      --
      -- 行末への表示は autostart（既定で有効）が package.json を開いた時に
      -- 自動で行う。sns はそれを手動で出し直すためのもの。
      -- バージョンを選んで変える change_version は張らない。使う場面が稀で、
      -- 番号を直接書き換えて npm install した方が結果が見える
      {
        '<leader>sns',
        function()
          require('package-info').show({ force = true })
        end,
        desc = 'Show npm dependency versions',
      },
      {
        '<leader>snu',
        function()
          require('package-info').update()
        end,
        desc = 'Update dependency on this line',
      },
    },
  },
}
