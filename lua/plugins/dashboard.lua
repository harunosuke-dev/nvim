-- 起動画面。引数なしで nvim を起動した時だけ出る。
--
-- snacks.nvim は多機能だが、ここでは dashboard だけを有効にしている。
-- opts に書いたモジュールだけが有効になる作りなので、他は読み込まれない。
--
-- アイコンは Codicons（cod-*）で揃えている。診断や LSP で使っているものと
-- 同じ系統にするため。縦の寸法（下端 -0.15〜-0.11、高さ 0.81〜0.91）も
-- 揃うものだけを選んでいる。大きさが不揃いだとベースラインが乱れて見える
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
          -- 既定は6行のアスキーアート。起動のたびに見るものなので簡素にする
          header = 'N E O V I M',

          -- 実際の操作は既存のプラグインに投げる。
          -- 起動画面のためだけに別の実装を持たない
          keys = {
            { icon = ' ', key = 'f', desc = 'ファイルを探す', action = ':lua require("fzf-lua").files()' },
            { icon = ' ', key = 'g', desc = '文字列で検索', action = ':lua require("fzf-lua").live_grep()' },
            { icon = ' ', key = 's', desc = 'セッションを復元', action = ':lua require("persistence").load()' },
            { icon = ' ', key = 'k', desc = 'キーマップ一覧', action = ':lua require("fzf-lua").keymaps()' },
            { icon = ' ', key = 'l', desc = 'プラグインを更新', action = ':Lazy update' },
            { icon = ' ', key = 'q', desc = '終了', action = ':qa' },
          },
        },

        sections = {
          { section = 'header' },
          { section = 'keys', gap = 1, padding = 1 },
          { section = 'recent_files', title = '最近開いたファイル', icon = ' ', limit = 5, indent = 2, padding = 1 },
          { section = 'projects', title = 'プロジェクト', icon = ' ', limit = 3, indent = 2, padding = 1 },
          { section = 'startup' },
        },
      },
    },
  },
}
