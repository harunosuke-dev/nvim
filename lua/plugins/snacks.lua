-- snacks.nvim の設定。
--
-- 多機能な詰め合わせだが、opts に書いたモジュールだけが有効になる作りなので、
-- 使うものだけを並べる。設定は1箇所にまとめる必要があるため、用途ごとに
-- ファイルを分けずここへ集約する。
--
--   notifier   通知の描画。noice から view = 'snacks' で呼ばれる
--
-- 起動画面（dashboard）は持たない。項目がどれも別の入口と重なっていた
-- （Find File は <Space>ff、Recent Files は <Space>fr、など）。
-- 引数なしで開いた時に何を出すかは lua/plugins/oil.lua が決める
return {
  {
    'folke/snacks.nvim',
    -- 通知は他のプラグインより先に用意する。noice が読み込み時に参照する
    priority = 1000,
    lazy = false,
    opts = {
      -- 通知の描画。noice から view = 'snacks' で呼ばれる。
      -- 画面右上に枠付きで出て、既定の3秒で消える（timeout は指定しない）
      notifier = {
        enabled = true,
        margin = { top = 0, right = 1, bottom = 0 },
        -- 既定は画面幅の 40% まで。tmux でペインを分割していると
        -- それだけでは足りず、長い文が途中で切れる
        width = { min = 30, max = 0.6 },
        height = { min = 1, max = 0.6 },
      },

      -- 通知の窓そのものの見た目。notifier の設定とは別枠で、
      -- Snacks.config.style で上書きする
      styles = {
        notification = {
          -- 既定は wrap = false で、幅に収まらない分は黙って切り捨てられる。
          -- 通知は読めなければ意味がないので折り返す
          wo = { wrap = true },
        },
      },
    },
  },
}
