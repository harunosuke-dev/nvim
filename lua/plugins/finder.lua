return {
  'ibhagwan/fzf-lua',
  cmd = 'FzfLua',
  keys = {
    -- ファイル系
    { '<leader>ff', '<cmd>FzfLua files<cr>', desc = 'ファイル検索' },
    { '<leader>fg', '<cmd>FzfLua live_grep<cr>', desc = '全文検索（grep）' },
    { '<leader>fb', '<cmd>FzfLua buffers<cr>', desc = 'バッファ一覧' },
    { '<leader>fr', '<cmd>FzfLua oldfiles<cr>', desc = '最近開いたファイル' },
    -- カーソル下の単語をそのまま検索。調べ物の起点として使用頻度が高い
    { '<leader>fw', '<cmd>FzfLua grep_cword<cr>', desc = 'カーソル下の単語を検索' },
    { '<leader>fw', '<cmd>FzfLua grep_visual<cr>', mode = 'x', desc = '選択範囲を検索' },
    -- 現在のバッファ内だけを絞り込む。長いファイルの中を移動する時に速い
    { '<leader>f/', '<cmd>FzfLua blines<cr>', desc = 'このバッファ内を検索' },
    { '<leader>fd', '<cmd>FzfLua diagnostics_document<cr>', desc = '診断一覧（このファイル）' },
    { '<leader>fD', '<cmd>FzfLua diagnostics_workspace<cr>', desc = '診断一覧（プロジェクト全体）' },
    -- 直前の検索結果を条件ごと復元する。閉じてしまった時に打ち直さずに済む
    { '<leader>fR', '<cmd>FzfLua resume<cr>', desc = '直前の検索を再開' },
    -- 設定・ヘルプ系
    { '<leader>fh', '<cmd>FzfLua helptags<cr>', desc = 'ヘルプを検索' },
    { '<leader>fk', '<cmd>FzfLua keymaps<cr>', desc = 'キーマップ一覧' },
    { '<leader>fc', '<cmd>FzfLua colorschemes<cr>', desc = 'カラースキームを切り替え' },
    { '<leader>fz', '<cmd>FzfLua<cr>', desc = 'fzf-lua の全コマンド' },
  },
  opts = {
    -- ファイル名を先に、パスを後ろに薄く表示する。
    -- Next.js のように page.tsx が大量にある構成では、これが無いと判別できない
    files = { formatter = 'path.filename_first' },
    grep = { formatter = 'path.filename_first' },
    oldfiles = { formatter = 'path.filename_first', include_current_session = true },
    winopts = {
      height = 0.85,
      width = 0.85,
      preview = { layout = 'flex', scrollbar = 'float' },
    },
    keymap = {
      builtin = {
        ['<C-d>'] = 'preview-page-down',
        ['<C-u>'] = 'preview-page-up',
        ['<C-/>'] = 'toggle-help',
      },
      fzf = {
        ['ctrl-d'] = 'preview-page-down',
        ['ctrl-u'] = 'preview-page-up',
        -- 検索結果をまとめて quickfix に送る
        ['ctrl-q'] = 'select-all+accept',
      },
    },
  },
}
