-- iceberg 専用の配色調整。
--
-- 素の iceberg は「カーソル行の背景」と「行番号の列の背景」がまったく同じ色
-- （#1f2233）のため、カーソルがどの行にあるか判別しづらい。
-- 3つの領域に別々の明度を割り当てて解消する。
--
--   本文        最も暗い    … 面積が広く、目を休ませたい部分
--   行番号の列  やや明るい  … 本文との境界が分かる程度
--   カーソル行  最も明るい  … 行番号・記号の列ごと帯状に光らせる
--
-- 呼び出し側は M.setup() を一度だけ実行する。
-- gitsigns のように後から自前のハイライトを定義するプラグインからは
-- M.apply() を直接呼ぶ（下のコメント参照）
local M = {}

local ICEBERG = {
  body = 0x0d0e14, -- 本文の背景
  gutter = 0x161822, -- 行番号・記号（gitsigns）・折りたたみの列。素の iceberg の本文色
  cursor = 0x1f2233, -- カーソル行。素の iceberg の行番号の列の色
  breadcrumb = 0x7d8296, -- 補助的な文字。本文より一段落とす
  chrome = 0x07080d, -- パンくず・行番号の列・ステータスラインの背景。本文より暗く沈める
  linenr = 0x454d73, -- 行番号・パンくず・ステータスラインの文字。3箇所で揃える
  float = 0x1f2233, -- フロートの背景。素の iceberg は #3d425c で本文から浮きすぎる
  faint = 0x555b73, -- 補助的な文字。breadcrumb よりさらに一段落とす
}

--- 背景が明るい配色かどうかを、色そのものの明度から判定する
local function is_light(color)
  local r = math.floor(color / 65536) % 256
  local g = math.floor(color / 256) % 256
  local b = color % 256
  return (0.299 * r + 0.587 * g + 0.114 * b) > 128
end

--- 文字色は元の指定を保ったまま、背景色だけ差し替える
local function set(group, bg, extra)
  local current = vim.api.nvim_get_hl(0, { name = group, link = false })
  vim.api.nvim_set_hl(0, group, vim.tbl_extend('force', { fg = current.fg, bg = bg }, extra or {}))
end

function M.apply()
  if vim.g.colors_name ~= 'iceberg' then
    return -- 他のテーマには手を入れない
  end

  -- iceberg / iceberg-dark / iceberg-light はどれも colors_name が 'iceberg' に
  -- なるため名前では区別できない。暗い配色にだけ適用する
  local normal = vim.api.nvim_get_hl(0, { name = 'Normal', link = false })
  if not normal.bg or is_light(normal.bg) then
    return
  end

  set('Normal', ICEBERG.body)
  set('NormalNC', ICEBERG.body)

  -- 左端の列。カーソル行以外はすべてこの色になる。
  -- パンくず・ステータスラインと同じ背景に揃え、周辺情報として一体に見せる
  for _, group in ipairs({ 'LineNr', 'LineNrAbove', 'LineNrBelow', 'SignColumn', 'FoldColumn' }) do
    set(group, ICEBERG.chrome)
  end

  -- カーソル行。本文・行番号・記号・折りたたみを同じ色で揃えて1本の帯にする
  set('CursorLine', ICEBERG.cursor)
  set('CursorLineNr', ICEBERG.cursor, { bold = true })
  set('CursorLineSign', ICEBERG.cursor)
  set('CursorLineFold', ICEBERG.cursor)

  -- 記号（診断・gitsigns・TODO）のハイライトは個別に背景色を持たされている。
  -- そのままだと記号のある行だけ左端の色が変わり、カーソル行でも光らない。
  -- 背景の指定を消して SignColumn / CursorLineSign から受け継がせる。
  --
  -- 末尾が Ln のものは「行全体の着色」用で、記号の列とは役割が違うため除外する
  for name in pairs(vim.api.nvim_get_hl(0, {})) do
    local is_gutter_sign = name:find('Sign')
      and name ~= 'SignColumn'
      and name ~= 'CursorLineSign'
      and not name:match('Ln$')
    if is_gutter_sign then
      -- link = false で解決してから見る。GitSignsChange のように
      -- 別グループ（GitGutterChange）へのリンクとして定義されているものがあり、
      -- リンクのまま判定すると背景色の有無が分からない
      local resolved = vim.api.nvim_get_hl(0, { name = name, link = false })
      if resolved.bg ~= nil then
        resolved.bg = nil
        -- nvim_get_hl は default = true を含めて返す。そのまま渡すと
        -- 「既存定義があれば何もしない」書き込みになり、上書きできない
        resolved.default = nil
        vim.api.nvim_set_hl(0, name, resolved)
      end
    end
  end

  -- フロート（補完メニュー・ホバー・which-key・noice のコマンドライン）の背景。
  -- 素の iceberg は #3d425c で、本文を #0d0e14 まで暗くした構成では明るすぎる。
  -- カーソル行と同じ色にして、本文よりわずかに浮く程度に抑える
  for _, group in ipairs({ 'NormalFloat', 'FloatBorder', 'Pmenu' }) do
    set(group, ICEBERG.float)
  end
  -- スクロールバー。既定のつまみは #c7c9d1（ほぼ白）で、暗くした本文の上では
  -- 白い四角として強く目立つ。軌道はフロート背景、つまみは gutter 程度に抑える
  set('PmenuSbar', ICEBERG.float)
  set('PmenuThumb', ICEBERG.gutter)
  -- 選択行。既定は #5c638a と明るく、フロート内で浮く。
  -- 位置が分かれば足りるので、フロート背景から一段上げる程度に留める
  set('PmenuSel', ICEBERG.cursor + 0x0a0c14)

  -- コメントとキーワードをイタリックにする。
  -- 「実行される処理そのものではないもの（コメント）」と「制御構造（if / function /
  -- return など）」を字形で分け、視覚的な層を作る。
  -- 型や関数名まで広げるとイタリックが多くなりすぎて逆に読みにくい。
  --
  -- iceberg 自体はスタイルの設定項目を持たないため、ここで付与する。
  -- 表示には端末とフォントの両方の対応が要る（tmux は sitm / ritm を持つ
  -- tmux-256color が必要。screen-256color では握り潰される）
  for _, group in ipairs({
    'Comment',
    '@comment',
    'Keyword',
    'Statement',
    'Conditional',
    'Repeat',
    'Exception',
    '@keyword',
    '@keyword.function',
    '@keyword.conditional',
    '@keyword.repeat',
    '@keyword.return',
    '@keyword.operator',
    '@keyword.import',
  }) do
    local current = vim.api.nvim_get_hl(0, { name = group, link = false })
    vim.api.nvim_set_hl(0, group, vim.tbl_extend('force', current, { italic = true }))
  end

  -- 画面上部のパンくず（dropbar）の文字を控えめにする。
  -- dropbar は要素の種類ごとにハイライトを分けており、
  --   DropBarIconKind*  アイコン（種類ごとの色。そのまま残す）
  --   DropBarKind*      ファイル名や関数名の文字（本文と同じ明るさで主張が強い）
  -- 後者だけ落として、視線が本文へ向くようにする。
  --
  -- DropBarKind* 自体は色を持たず winbar の既定色を継承するため、
  -- WinBar を落とすのが本体。DropBarKind* にも同じ色を当てて、
  -- 種類ごとに色が付く実装に変わっても揃うようにしておく。
  --
  -- 色は行番号と同じ #454d73。パンくず・行番号・ステータスラインの3箇所を
  -- ひとつの明度に揃えて、周辺情報として一体に見えるようにする。
  -- lualine は WinBar の色を読むので、ここを変えれば追従する
  vim.api.nvim_set_hl(0, 'WinBar', { fg = ICEBERG.linenr, bg = ICEBERG.chrome })
  vim.api.nvim_set_hl(0, 'WinBarNC', { fg = ICEBERG.linenr, bg = ICEBERG.chrome })
  -- lualine が塗るのは区画の中だけで、その外側は StatusLine が使われる。
  -- 揃えておかないと帯の一部だけ色が残る
  vim.api.nvim_set_hl(0, 'StatusLine', { fg = ICEBERG.linenr, bg = ICEBERG.chrome })
  vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = ICEBERG.linenr, bg = ICEBERG.chrome })
  -- インデントの縦線（indent-blankline）。
  --
  -- 既定では IblIndent に色が設定されておらず、本文と同じ明るさ（#c7c9d1）で
  -- 描かれる。一方で強調したいスコープ線は IblScope（#454d73）とそれより暗い。
  -- 全ての行に本文と同じ濃さの線が並ぶうえ、目立たせたい方が沈んでいた。
  --
  -- 通常の線は背景に沈め、カーソルのあるブロックの線だけを浮かせる。
  -- 色は足さず明度だけで区別する
  local non_text = vim.api.nvim_get_hl(0, { name = 'NonText', link = false })
  vim.api.nvim_set_hl(0, 'IblIndent', { fg = non_text.fg })
  vim.api.nvim_set_hl(0, 'IblWhitespace', { fg = non_text.fg })
  vim.api.nvim_set_hl(0, 'IblScope', { fg = ICEBERG.breadcrumb })

  -- 起動画面（snacks の dashboard）。
  --
  -- 既定では見出しが Title（#e2a578 橙）、ファイル名が Special（#b5bf82 緑）に
  -- リンクされており、彩度の高いファイル名の方が見出しより前に出てしまう。
  -- ディレクトリ部分は NonText（#252941）で本文の背景とほぼ同じ明度になり読めない。
  --
  -- 色ではなく明度と太字で区別する。診断以外に色を使わない方針に合わせる。
  local normal = vim.api.nvim_get_hl(0, { name = 'Normal', link = false })
  -- 見出しと操作の名前は太字。押せるもの・区切りとして先に目に入るようにする
  vim.api.nvim_set_hl(0, 'SnacksDashboardTitle', { fg = normal.fg, bold = true })
  vim.api.nvim_set_hl(0, 'SnacksDashboardDesc', { fg = normal.fg, bold = true })
  vim.api.nvim_set_hl(0, 'SnacksDashboardHeader', { fg = ICEBERG.breadcrumb })
  vim.api.nvim_set_hl(0, 'SnacksDashboardFooter', { fg = ICEBERG.faint })
  vim.api.nvim_set_hl(0, 'SnacksDashboardIcon', { fg = ICEBERG.breadcrumb })
  vim.api.nvim_set_hl(0, 'SnacksDashboardKey', { fg = ICEBERG.breadcrumb })
  vim.api.nvim_set_hl(0, 'SnacksDashboardSpecial', { fg = ICEBERG.breadcrumb })
  -- snacks はパスを「前半のディレクトリ」と「末尾の名前」に分けて塗る。
  -- File はファイル名とプロジェクトのフォルダ名の両方に当たるため、ここを
  -- 本文と同じ明るさにして、パスの前半だけを背景へ退かせる。
  -- 見出しは太字なので、明るさが並んでも階層は保たれる
  vim.api.nvim_set_hl(0, 'SnacksDashboardFile', { fg = normal.fg })
  vim.api.nvim_set_hl(0, 'SnacksDashboardDir', { fg = ICEBERG.breadcrumb })

  for name in pairs(vim.api.nvim_get_hl(0, {})) do
    if name:match('^DropBarKind') then
      vim.api.nvim_set_hl(0, name, { fg = ICEBERG.linenr })
    end
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup('user_highlights', { clear = true })

  -- カラースキームを切り替えるたびに当て直す（iceberg 以外では何もしない）
  vim.api.nvim_create_autocmd('ColorScheme', { group = group, callback = M.apply })
  -- プラグインが後から記号のハイライトを定義するため、読み込みのたびに当て直す
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = { 'VeryLazy', 'LazyLoad' },
    callback = function()
      vim.schedule(M.apply)
    end,
  })
end

return M
