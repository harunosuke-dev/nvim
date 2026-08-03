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
      code = {
        -- コードブロックは背景を敷くだけにする。枠線は本文の邪魔になる
        style = 'normal',
        width = 'block',
        left_pad = 2,
        right_pad = 2,
      },
      heading = {
        -- 見出しの背景は敷かない。iceberg の配色に色を足さない方針に合わせる
        backgrounds = {},
      },
    },
  },
}
