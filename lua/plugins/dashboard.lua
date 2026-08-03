-- 起動画面。引数なしで nvim を起動した時だけ出る。
--
-- snacks.nvim は多機能だが、ここでは dashboard だけを有効にしている。
-- opts に書いたモジュールだけが有効になる作りなので、他は読み込まれない。
--
-- アイコンは Codicons（cod-*）で揃えている。診断や LSP で使っているものと
-- 同じ系統にするため。縦の寸法（下端 -0.15〜-0.11、高さ 0.81〜0.91）も
-- 揃うものだけを選んだ。大きさが不揃いだとベースラインが乱れて見える。
-- プラグイン更新の Zzz（md-sleep）だけは lazy.nvim を表すため例外にした。
--
-- 表示は英語で統一する。日本語だと文字幅が2倍になり、桁が揃わないため
return {
  {
    'folke/snacks.nvim',
    priority = 1000, -- 起動画面なので他のプラグインより先に読む
    lazy = false,
    opts = {
      dashboard = {
        -- 狭いとパスが ~/R/g/H/... のように潰れる
        width = 70,

        preset = {
          -- header は指定しない。snacks 既定のブロック体をそのまま使う

          -- 実際の操作は既存のプラグインに投げる。
          -- 起動画面のためだけに別の実装を持たない。
          --
          -- h j k l は使わない。snacks はナビゲーション用のキーを割り当てて
          -- おらず、項目間の移動は通常のカーソル移動に頼っている。ここに
          -- 重ねると上下移動が奪われる
          keys = {
            { icon = ' ', key = 'f', desc = 'Find File', action = ':lua require("fzf-lua").files()' },
            { icon = ' ', key = 'g', desc = 'Live Grep', action = ':lua require("fzf-lua").live_grep()' },
            { icon = ' ', key = 's', desc = 'Restore Session', action = ':lua require("persistence").load()' },
            { icon = ' ', key = 'm', desc = 'Keymaps', action = ':lua require("fzf-lua").keymaps()' },
            { icon = '󰒲 ', key = 'u', desc = 'Update Plugins', action = ':Lazy update' },
            { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
          },
        },

        sections = {
          { section = 'header' },
          { section = 'keys', gap = 1, padding = 1 },
          { section = 'recent_files', title = 'Recent Files', icon = ' ', limit = 5, indent = 2, padding = 1 },
          { section = 'projects', title = 'Projects', icon = ' ', limit = 3, indent = 2, padding = 1 },
          { section = 'startup' },
        },
      },
    },
  },
}
