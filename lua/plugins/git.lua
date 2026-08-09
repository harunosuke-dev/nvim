return {
  -- コミット・ステージング・履歴閲覧など、腰を据えた git 操作は lazygit に任せる
  {
    'kdheepak/lazygit.nvim',
    cmd = { 'LazyGit', 'LazyGitCurrentFile', 'LazyGitFilter', 'LazyGitFilterCurrentFile' },
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      { '<leader>gg', '<cmd>LazyGit<cr>', desc = 'Open lazygit' },
      { '<leader>gG', '<cmd>LazyGitFilterCurrentFile<cr>', desc = 'Git history in this file' },
    },
  },

  -- 編集中に見える範囲の差分表示と、hunk 単位の細かい操作は gitsigns が担当する
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
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

        -- ステージングは張らない。コミットを組み立てる作業は lazygit（<leader>gg）に
        -- 任せる方が、全ファイルを見渡しながら選べて速い。
        -- ここに残すのは「今開いているバッファのカーソル位置」に紐づくものだけ。
        -- その文脈は lazygit へ移った時点で失われるため、代替が効かない

        -- 変更箇所（hunk）の移動。差分モード中は標準の ]c / [c に委ねる
        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal({ ']c', bang = true })
          else
            gs.nav_hunk('next')
          end
        end, 'Next change')
        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal({ '[c', bang = true })
          else
            gs.nav_hunk('prev')
          end
        end, 'Prev change')

        -- 取り消し。u で戻れない状況（保存後や他の編集を挟んだ後）の救済として残す。
        -- ビジュアル選択中は選んだ行だけが対象になる
        map('n', '<leader>hr', gs.reset_hunk, '[H]unk [R]eset : discard changes')
        map('x', '<leader>hr', function()
          gs.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
        end, '[H]unk [R]eset on selected lines')

        -- 確認系
        map('n', '<leader>hp', gs.preview_hunk, '[H]unk [P]review')
        map('n', '<leader>hb', function()
          gs.blame_line({ full = true })
        end, '[H]unk [B]lame : commit for line')
        map('n', '<leader>hd', gs.diffthis, '[H]unk [D]iff against index')
        map('n', '<leader>hD', function()
          gs.diffthis('~')
        end, '[H]unk [D]iff against HEAD~')

        -- 表示の切り替え
        map('n', '<leader>ub', gs.toggle_current_line_blame, '[U]I [B]lame : toggle inline')

        -- テキストオブジェクト。dih で変更箇所を丸ごと捨てる、といった操作ができる
        vim.keymap.set({ 'o', 'x' }, 'ih', gs.select_hunk, { buffer = bufnr, desc = 'Git: [i]nner [h]unk' })
      end,
    },
  },
}
