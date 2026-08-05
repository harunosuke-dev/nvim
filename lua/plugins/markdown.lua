-- Markdown の表示。ドキュメントを書く時にだけ効く。
--
-- 見出し・表・コードブロック・チェックボックスをバッファの中で整形して描く。
-- 実際のファイルは書き換えず、表示だけを変える。
--
-- 完全に自動で、キー操作は不要
return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    -- mdx でも効かせる。ブログの記事が .mdx のため。
    -- JSX の部分（<Box> など）は Markdown ではないので素のまま残る
    ft = { 'markdown', 'markdown_inline', 'mdx' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    opts = {
      -- 挿入モードでは素のテキストに戻す。編集中に文字がずれると書きにくい
      render_modes = { 'n', 'c', 't' },

      -- リンクの [] () とパスを隠さない。
      --
      -- Neovim 標準の markdown_inline の定義が conceal "" を指定しており、
      -- conceallevel が 1 以上だと ![説明](/images/a.jpg) が「説明」だけに
      -- 畳まれる。どの画像を指しているのか分からず、パスを直す時に困る。
      --
      -- このプラグインは既定で 3 に上げるので、0 のままにさせる。
      -- 見出しや箇条書きの整形は仮想テキストで描かれるため影響を受けない
      win_options = {
        conceallevel = { default = 0, rendered = 0 },
      },
      code = {
        -- 背景を敷くだけにする。枠線は本文の邪魔になる。
        -- この形式では ```ts の行が隠れ、言語名が別に描かれる
        style = 'normal',
        width = 'block',
        left_pad = 2,
        right_pad = 2,
      },

      -- コードブロックの行では、ブロックの幅を超えた右側の余白を仮想テキストで
      -- 塗り直している。その色が既定で Normal に固定されているため、非アクティブな
      -- ウィンドウでもそこだけ減光されず、帯状に明るく残っていた。
      --
      -- 背景を持たないグループへ向けると、その窓の地の色（NormalNC）が透ける。
      -- 定義は lua/config/highlights.lua
      padding = { highlight = 'RenderMarkdownPadding' },

      -- 画像とリンクをアイコンに置き換えない。
      --
      -- 既定では ![alt](path) が 󰥶 のような記号1つに畳まれ、どのファイルを
      -- 指しているのか分からなくなる。パスを直したい時に開き直す必要があり、
      -- 執筆中は元の記述が見えている方が扱いやすい
      link = { enabled = false },

      -- 箇条書きの記号を置き換えない。
      --
      -- Markdown では - * + のどれも箇条書きになる。数式ブロックの中で
      -- 行頭に + を置くと、Markdown 側からは区別が付かず ● に化けていた。
      -- 元の記号がそのまま見える方が、書いている内容と一致して分かりやすい
      bullet = { enabled = false },
      heading = {
        -- 見出しの背景は敷かない。iceberg の配色に色を足さない方針に合わせる
        backgrounds = {},
      },
    },
  },
}
