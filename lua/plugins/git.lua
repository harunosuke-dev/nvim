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
        -- 差分表示は開閉のトグルにする。
        --
        -- diffthis は縦分割でインデックス側のバッファ（名前が gitsigns:// で始まる）を
        -- 開くが、カーソルは元のファイル側に残る。そこで :q を押すと「自分のファイルの
        -- 窓」が閉じ、インデックス側だけが残る。中身がほぼ同じなので気づきにくく、
        -- 「gitsigns の記号が消えた」ように見えてしまう。
        -- 実際には差分ゼロの読み取り用バッファを見ているだけで、壊れてはいない
        --
        -- 閉じる時は **先に差分モードを解いてから** 窓を閉じること。逆順にすると落ちる。
        --
        -- diff のまま nvim_win_close を呼ぶと、窓を解放する途中で残った窓の幅が
        -- 変わり、その再計算のために差分が引き直される。そこから DiffUpdated が
        -- 飛び、autocmd の中で win_findbuf がウィンドウ一覧を辿るが、この時点の
        -- 一覧は解放しかけで壊れているため NULL を踏んで SIGSEGV になる。
        --
        --   nvim_win_close → win_free_mem → frame_new_width → win_set_inner_size
        --     → update_topline → win_get_fill → diff_check_with_linestatus
        --     → ex_diffupdate → apply_autocmds(DiffUpdated) → win_findbuf → 落ちる
        --
        -- DiffUpdated を拾っているのは render-markdown（core/manager.lua）なので、
        -- **markdown を開いている時だけ**落ちる。他のファイル型では再現しない。
        -- 素性は Neovim 側の再入バグだが、diffoff! を先に済ませておけば
        -- 解放中に差分の引き直しが起きなくなり、autocmd 自体が飛ばない。
        --
        -- 素の diffoff（bang 無し）は今の窓にしか効かず、残る側の scrollbind や
        -- foldmethod が差分用のまま取り残される。bang 付きでタブページ全体を戻す
        local function close_diff()
          local targets = {}
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.api.nvim_buf_get_name(buf):match('^gitsigns://') then
              targets[#targets + 1] = win
            end
          end
          if #targets == 0 then
            return false
          end

          vim.cmd('diffoff!')
          for _, win in ipairs(targets) do
            pcall(vim.api.nvim_win_close, win, false)
          end
          return true
        end

        map('n', '<leader>hd', function()
          if not close_diff() then
            gs.diffthis()
          end
        end, '[H]unk [D]iff against index')
        map('n', '<leader>hD', function()
          if not close_diff() then
            gs.diffthis('~')
          end
        end, '[H]unk [D]iff against HEAD~')

        -- 表示の切り替え
        map('n', '<leader>ub', gs.toggle_current_line_blame, '[U]I [B]lame : toggle inline')

        -- テキストオブジェクト。dih で変更箇所を丸ごと捨てる、といった操作ができる
        vim.keymap.set({ 'o', 'x' }, 'ih', gs.select_hunk, { buffer = bufnr, desc = 'Git: [i]nner [h]unk' })
      end,
    },
  },
}
