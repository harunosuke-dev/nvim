-- <leader> を押して少し待つと、そこから続くキーの一覧が出る。
-- 各キーマップの desc をそのまま拾うので、説明は定義側に書けばよい
return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  opts = {
    preset = 'helix', -- 画面右側に縦一列で出る。項目数が多くても読みやすい
    -- timeoutlen (150) より小さくする。ポップアップが出る前に
    -- キー列がタイムアウトすると <leader> 操作が中断されてしまう
    delay = 100,

    -- 修飾キーを記号ではなく綴りで出す。
    --
    -- 既定は Nerd Font の記号（Ctrl は 󰘴）で、フッタの「^ D/^ U scroll」の
    -- ように ^ に見えるうえ、記号に付いた余白でキーが離れて読みにくい。
    -- 記号を覚える手間も増えるので、そのまま Ctrl と書く
    icons = {
      keys = {
        C = 'Ctrl+',
        M = 'Alt+',
        D = 'Cmd+',
        S = 'Shift+',
      },
    },

    -- ポップアップの中のスクロール。
    --
    -- 既定は Ctrl+d / Ctrl+u だが、この設定ではどちらも「半画面スクロール＋zz」に
    -- 割り当ててあるため効かない。which-key は押されたキーに割り当てがあれば
    -- そちらを優先して実行し、スクロールの判定はその後にあるため
    -- （which-key/state.lua の分岐）。Ctrl+j / Ctrl+k も同じ理由で使えない
    -- （ウィンドウ移動に割り当て済み）。
    --
    -- 割り当てが無く、かつ「次 / 前」を意味するキーとして Ctrl+n / Ctrl+p を使う
    keys = {
      scroll_down = '<C-n>',
      scroll_up = '<C-p>',
    },

    -- グループ名には由来の英単語を添える。どの頭文字から来ているかが分かると
    -- 覚え直さずに思い出せる（例: f は Find なので ff = Find File）
    spec = {
      { '<leader>a', group = 'Argument 引数' },
      { '<leader>b', group = 'Buffer バッファ' },
      { '<leader>c', group = 'Code コード' },
      { '<leader>f', group = 'Find 探す' },
      { '<leader>g', group = 'Go to 移動 / Git' },
      { '<leader>h', group = 'Hunk 変更のかたまり' },
      { '<leader>n', group = 'Notification 通知' },
      { '<leader>r', group = 'Replace 置換' },
      { '<leader>s', group = 'Session セッション' },
      { '<leader>sn', group = 'NPM パッケージ' },
      { '<leader>u', group = 'UI 表示の切り替え' },
      { '<leader>w', group = 'Window ウィンドウ' },
      { '<leader>x', group = '一覧（trouble の慣例）' },
      { ']', group = '次へ' },
      { '[', group = '前へ' },
    },
  },
  keys = {
    {
      '<leader>?',
      function()
        require('which-key').show({ global = false })
      end,
      desc = 'このバッファで使えるキーマップ',
    },
  },
}
