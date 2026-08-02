return {
  -- コミット・ステージング・履歴閲覧など、腰を据えた git 操作は lazygit に任せる
  {
    'kdheepak/lazygit.nvim',
    cmd = { 'LazyGit', 'LazyGitCurrentFile', 'LazyGitFilter', 'LazyGitFilterCurrentFile' },
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      { '<leader>gg', '<cmd>LazyGit<cr>', desc = 'LazyGit を開く' },
      { '<leader>gG', '<cmd>LazyGitFilterCurrentFile<cr>', desc = 'このファイルのコミット履歴' },
    },
  },

  -- 編集中に見える範囲の差分表示と、hunk 単位の細かい操作は gitsigns が担当する
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      signs = {
        add = { text = '│' },
        change = { text = '│' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
        untracked = { text = '┆' },
      },
      current_line_blame = false, -- 常時表示はうるさいので <leader>hb で都度出す
      on_attach = function(bufnr)
        -- gitsigns はステージ済み変更用のハイライトを接続後（非同期）に定義するため、
        -- カラースキーム側のイベントでは取りこぼす。ここから当て直す
        require('config.highlights').apply()

        local gs = require('gitsigns')
        local function map(mode, key, fn, desc)
          vim.keymap.set(mode, key, fn, { buffer = bufnr, desc = 'Git: ' .. desc })
        end

        -- 変更箇所（hunk）の移動。差分モード中は標準の ]c / [c に委ねる
        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal({ ']c', bang = true })
          else
            gs.nav_hunk('next')
          end
        end, '次の変更箇所へ')
        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal({ '[c', bang = true })
          else
            gs.nav_hunk('prev')
          end
        end, '前の変更箇所へ')

        -- hunk 単位の操作。ビジュアル選択中は選んだ行だけが対象になる
        map('n', '<leader>hs', gs.stage_hunk, 'この変更をステージ')
        map('n', '<leader>hr', gs.reset_hunk, 'この変更を取り消す')
        map('x', '<leader>hs', function()
          gs.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
        end, '選択範囲をステージ')
        map('x', '<leader>hr', function()
          gs.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
        end, '選択範囲の変更を取り消す')
        map('n', '<leader>hS', gs.stage_buffer, 'ファイル全体をステージ')
        map('n', '<leader>hR', gs.reset_buffer, 'ファイル全体の変更を取り消す')

        -- 確認系
        map('n', '<leader>hp', gs.preview_hunk, 'この変更を吹き出しで確認')
        map('n', '<leader>hb', function()
          gs.blame_line({ full = true })
        end, 'この行を書いたコミットを表示')
        map('n', '<leader>hd', gs.diffthis, '直前のコミットとの差分')
        map('n', '<leader>hD', function()
          gs.diffthis('~')
        end, 'HEAD~ との差分')

        -- 表示の切り替え
        map('n', '<leader>ub', gs.toggle_current_line_blame, '行ブレームの常時表示を切替')

        -- テキストオブジェクト。dih で変更箇所を丸ごと捨てる、といった操作ができる
        vim.keymap.set({ 'o', 'x' }, 'ih', gs.select_hunk, { buffer = bufnr, desc = 'Git: 変更箇所' })
      end,
    },
  },
}
