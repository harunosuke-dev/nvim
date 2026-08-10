-- oil.nvim はディレクトリを「編集可能なバッファ」として開くファイラ。
-- 行を書き換えてリネーム、行を消して削除、行を足して新規作成し、:w で確定する。
-- 通常の Vim 操作（dd / p / cw / ビジュアル選択）がそのまま使えるのが利点
return {
  'stevearc/oil.nvim',
  -- netrw を置き換えるため遅延ロードしない（起動直後に nvim . で開けるように）
  lazy = false,
  keys = {
    -- oil の定番は - だが、素の Vim では「前の行の先頭へ」という移動キー。
    -- <leader>e と同じ動作を2箇所に置いても得るものが無いので、こちらだけ残す
    { '<leader>e', '<cmd>Oil<cr>', desc = 'Open the file explorer' },
  },
  opts = {
    default_file_explorer = true,
    -- ファイラのバッファを一覧に載せる。既定では載らないため、閉じると
    -- 戻る手段が無くなる。載せておけば ]b / <Space>fb で戻れるうえ、
    -- sessionoptions に buffers が入っているのでセッション復元でも残る
    buf_options = {
      buflisted = true,
      bufhidden = 'hide',
    },
    -- 隠れたファイラのバッファを消さない。既定は2秒後に削除するため、
    -- ファイラからファイルを開いて少し経つと戻り先が無くなっていた
    cleanup_delay_ms = false,
    delete_to_trash = true, -- 削除は :w 時にゴミ箱へ（復元可能）
    skip_confirm_for_simple_edits = false, -- 変更内容の確認は必ず出す
    view_options = {
      show_hidden = true, -- .env や .github を隠さない
    },
    win_options = {
      -- git の状態を出す列。gitsigns は oil のバッファ（oil:// という実ファイルで
      -- ない名前）に attach しないので、lua/config/oil-git.lua が自分で置く
      signcolumn = 'yes:2',
    },
    keymaps = {
      ['g?'] = 'actions.show_help',
      ['<CR>'] = 'actions.select',
      ['<C-s>'] = { 'actions.select', opts = { vertical = true } },
      ['<C-h>'] = false, -- ウィンドウ移動を優先するため無効化
      -- <C-t>（タブで開く）は張らない。タブページを使わない構成で、gT も
      -- 型定義ジャンプに充てているため
      ['<C-p>'] = 'actions.preview',
      ['<C-c>'] = 'actions.close',
      ['<C-l>'] = false, -- 同上（更新は <C-r> を使う）
      ['<C-r>'] = 'actions.refresh',
      ['-'] = 'actions.parent',
      ['_'] = 'actions.open_cwd',
      ['`'] = 'actions.cd',
      ['gs'] = 'actions.change_sort',
      ['gx'] = 'actions.open_external',
      ['g.'] = 'actions.toggle_hidden',
    },
    use_default_keymaps = false, -- 上の定義だけを使う（既定との二重定義を避ける）
  },
  config = function(_, opts)
    require('oil').setup(opts)
    -- 変更のあるファイルを符号列で示す。oil の公開 API（get_entry_on_line と
    -- User OilEnter）だけで動くので、oil 側の設定には手を入れない
    require('config.oil-git').setup()
  end,
}
