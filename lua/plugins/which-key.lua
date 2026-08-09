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

    -- グループ名も desc と同じ規則で書く（lua/config/keymaps.lua の冒頭を参照）。
    -- 括弧の文字がそのままキーになるので、どの頭文字から来ているかが分かる。
    -- 語呂が成り立たない x（trouble の慣例）や ] [ は括弧を使わず平文にする
    spec = {
      { '<leader>b', group = '[B]uffer' },
      { '<leader>c', group = '[C]ode' },
      { '<leader>f', group = '[F]ind' },
      { '<leader>g', group = '[G]o to / [G]it' },
      { '<leader>h', group = '[H]unk' },
      { '<leader>n', group = '[N]otification' },
      { '<leader>r', group = '[R]eplace' },
      { '<leader>s', group = '[S]ession' },
      { '<leader>sn', group = '[N]pm packages' },
      { '<leader>u', group = '[U]I toggles' },
      { '<leader>w', group = '[W]indow' },
      { '<leader>x', group = 'Lists that stay open' },
      { ']', group = 'Next' },
      { '[', group = 'Prev' },
    },
  },
  keys = {
    {
      '<leader>?',
      function()
        require('which-key').show({ global = false })
      end,
      desc = 'Keymaps for this buffer',
    },
  },
}
