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
  select = 0x3a4160, -- 一覧の中でカーソルがある行。他の選択色より一段明るくする
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

--- 色を暗い方へ寄せる。ratio が 0.75 なら 25% 沈む
local function dim(color, ratio)
  local r = math.floor(math.floor(color / 65536) % 256 * ratio)
  local g = math.floor(math.floor(color / 256) % 256 * ratio)
  local b = math.floor(color % 256 * ratio)
  return r * 65536 + g * 256 + b
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

  -- 非アクティブなウィンドウを見分けられるようにする（kanagawa の dimInactive と
  -- 同じこと）。テーマ固有の機能ではなく NormalNC を変えているだけなので、
  -- 設定項目を持たない iceberg でもできる。
  --
  -- 背景は暗くするのではなく「明るく」する。本文の #0d0e14 は既に黒に近く、
  -- 暗い方向には余地が無い（chrome まで落としても 1.04 倍しか差が出ない）。
  -- 明るい方へ振れば 1.09 倍まで開き、アクティブ側の色を変えずに済む。
  -- tmux のペインも同じ関係（アクティブが暗く、非アクティブが明るい）。
  --
  -- 文字は 25% 沈める。背景の差だけでは足りないぶんをこちらで補う
  vim.api.nvim_set_hl(0, 'NormalNC', {
    fg = dim(normal.fg, 0.75),
    bg = ICEBERG.gutter,
  })

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
  -- 補完メニューとその周辺（blink.cmp）。
  --
  -- 既定は Pmenu を継ぐので、カーソル行と同じ #1f2233 になり本文より明るい。
  -- パンくず・行番号の列・ステータスラインと同じ色に揃えて、「本文ではない面」
  -- として一体に見せる。本文（#0d0e14）より暗いので内容と UI が分かれる。
  --
  -- 選択行だけは一段持ち上げて位置が分かるようにする
  for _, group in ipairs({
    'BlinkCmpMenu',
    'BlinkCmpMenuBorder',
    'BlinkCmpDoc',
    'BlinkCmpDocBorder',
    'BlinkCmpDocSeparator',
    'BlinkCmpSignatureHelp',
    'BlinkCmpSignatureHelpBorder',
  }) do
    set(group, ICEBERG.chrome)
  end
  set('BlinkCmpMenuSelection', ICEBERG.cursor)
  set('BlinkCmpDocCursorLine', ICEBERG.cursor)

  -- 文字の明るさに階層をつける。
  --
  -- 既定はどれも本文と同じ #c7c9d1 で、候補名も種類も出どころも同列に
  -- 並んで主張が強い。読む必要があるのは「候補名のどこが一致したか」で、
  -- 種類や出どころは目に入れば足りる。
  --
  --   一致した部分  本文と同じ明るさ … ここだけ拾えばよい
  --   候補名        一段落とす
  --   種類・詳細    さらに落とす
  local normal_fg = vim.api.nvim_get_hl(0, { name = 'Normal', link = false }).fg
  vim.api.nvim_set_hl(0, 'BlinkCmpLabelMatch', { fg = normal_fg, bold = true })
  vim.api.nvim_set_hl(0, 'BlinkCmpLabel', { fg = ICEBERG.breadcrumb })
  vim.api.nvim_set_hl(0, 'BlinkCmpDoc', { fg = ICEBERG.breadcrumb, bg = ICEBERG.chrome })
  for _, group in ipairs({
    'BlinkCmpLabelDetail',
    'BlinkCmpLabelDescription',
    'BlinkCmpKind',
    'BlinkCmpSource',
  }) do
    vim.api.nvim_set_hl(0, group, { fg = ICEBERG.faint })
  end
  -- スクロールバーは出さない設定だが、軌道が明るいままだと枠に線が見える
  set('BlinkCmpScrollBarGutter', ICEBERG.chrome)
  set('BlinkCmpScrollBarThumb', ICEBERG.gutter)

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

  -- Markdown の整形表示（render-markdown）。
  --
  -- 既定では H1 から H6 まで6段階すべてが @markup.heading.N.markdown を継ぎ、
  -- iceberg ではどれも同じオレンジ（#e2a578）になる。階層の区別が付かないうえ、
  -- 見出しの多い文書ではオレンジだらけになる。
  --
  -- 色ではなく明度と太字で階層を作る。診断以外に色を使わない方針に合わせる。
  -- 見出しの背景（*Bg）は Diff の色（緑・赤・青）を継ぐので使わない
  vim.api.nvim_set_hl(0, 'RenderMarkdownH1', { fg = normal.fg, bold = true })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH2', { fg = normal.fg, bold = true })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH3', { fg = ICEBERG.breadcrumb, bold = true })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH4', { fg = ICEBERG.breadcrumb })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH5', { fg = ICEBERG.faint })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH6', { fg = ICEBERG.faint })

  -- 実際に文字を塗っているのは treesitter の @markup.* 側。
  -- iceberg では見出しが Title（#e2a578 オレンジ）、表や強調が Special
  -- （#b5bf82 オリーブ）になり、文書全体が賑やかになる。
  -- RenderMarkdown* を直すだけでは変わらないので、こちらも揃える
  for _, group in ipairs({
    '@markup.heading',
    '@markup.heading.1.markdown',
    '@markup.heading.2.markdown',
    '@markup.heading.3.markdown',
    '@markup.heading.4.markdown',
    '@markup.heading.5.markdown',
    '@markup.heading.6.markdown',
  }) do
    vim.api.nvim_set_hl(0, group, { fg = normal.fg, bold = true })
  end
  -- 表の罫線・区切り・引用など。本文より落として構造だけ見えれば足りる
  for _, group in ipairs({
    '@markup.list.markdown',
    '@markup.quote.markdown',
    '@punctuation.special.markdown',
    '@markup.link.label.markdown_inline',
  }) do
    vim.api.nvim_set_hl(0, group, { fg = ICEBERG.breadcrumb })
  end

  -- 数式（$...$）。地の文から浮かせて境目が分かるようにする。
  -- 中身は明度だけで区別し、区切りの $ にだけ色を付けて範囲を示す。
  --
  -- 空行を挟んだ $$...$$ には効かない。Markdown が空行を段落の区切りとして
  -- 扱うため、そこで latex_block が途切れる。パーサの構造上の制約
  vim.api.nvim_set_hl(0, '@markup.math', { fg = ICEBERG.breadcrumb })
  vim.api.nvim_set_hl(0, '@markup.math.markdown_inline', { fg = ICEBERG.breadcrumb })
  -- 太字にはしない。色だけで十分に区別が付き、$ 1文字を太くしても情報は
  -- 増えない。区切り記号を強調するのは一般的な慣習とも逆
  vim.api.nvim_set_hl(0, '@markup.math.delimiter', { fg = 0x8fbf7f })
  vim.api.nvim_set_hl(0, '@markup.math.delimiter.markdown_inline', { fg = 0x8fbf7f })

  -- 記号類も彩度を落とす。コードブロックの言語名とチェック済みの印は
  -- 既定で #b5bf82 のオリーブ
  vim.api.nvim_set_hl(0, 'RenderMarkdownCodeInfo', { fg = ICEBERG.faint })
  vim.api.nvim_set_hl(0, 'RenderMarkdownChecked', { fg = ICEBERG.breadcrumb })
  vim.api.nvim_set_hl(0, 'RenderMarkdownUnchecked', { fg = ICEBERG.faint })
  vim.api.nvim_set_hl(0, 'RenderMarkdownBullet', { fg = ICEBERG.breadcrumb })
  vim.api.nvim_set_hl(0, 'RenderMarkdownTableHead', { fg = ICEBERG.breadcrumb })
  vim.api.nvim_set_hl(0, 'RenderMarkdownTableRow', { fg = ICEBERG.faint })

  -- コードブロックの行で、ブロックの幅を超えた右側の余白を塗るためのもの。
  -- render-markdown の padding.highlight から参照される（lua/plugins/markdown.lua）。
  --
  -- 既定では Normal が使われるが、ハイライトの定義はウィンドウごとに変わらない
  -- ため、非アクティブなウィンドウでもそこだけ減光されず帯状に明るく残っていた。
  -- 背景を持たせなければ、その窓の地の色（NormalNC）が透ける
  vim.api.nvim_set_hl(0, 'RenderMarkdownPadding', {})

  -- --- を横線として描く時の色。既定は LineNr へのリンクだが、こちらで
  -- 行番号の列の背景を本文より暗くしているため、その背景ごと引き継いで
  -- 横線の1行だけ帯状に沈んで見えていた。文字色だけ受け取り、背景は敷かない
  vim.api.nvim_set_hl(0, 'RenderMarkdownDash', { fg = ICEBERG.linenr })

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

  -- パンくずのメニューで、カーソルのある行が白い帯になる問題。
  --
  -- dropbar は「今いる項目」を DropBarMenuHoverEntry で示し、これは既定で
  -- IncSearch を継承する。iceberg の IncSearch は色を持たず reverse（反転）
  -- だけを指定しているため、本文の文字色（#c7c9d1）が背景として塗られる。
  --
  -- 反転は元の色を入れ替えるだけなので、アイコンや区切り記号がそれぞれ別の
  -- 色で反転し、行全体がちぐはぐな見た目になっていた。
  --
  -- 明示的に色を与えて反転をやめる。選択行として分かる程度に持ち上げるだけで
  -- 十分で、白く塗る必要はない
  -- 背景だけを与える。文字色は指定しない。
  -- fg まで上書きするとアイコンの色が潰れ、そこだけ浮いて見えるため
  for _, group in ipairs({
    'DropBarMenuHoverEntry',
    'DropBarMenuHoverIcon',
    'DropBarMenuHoverSymbol',
  }) do
    vim.api.nvim_set_hl(0, group, { bg = ICEBERG.select, reverse = false })
  end

  -- 展開マーク（>）だけが #b5bf82 のオリーブで、彩度が高く浮いていた。
  -- 同じ補助記号である区切り（DropBarIconUISeparator = #6c7189）に揃える
  vim.api.nvim_set_hl(0, 'DropBarIconUIIndicator', { fg = ICEBERG.breadcrumb })

  -- マウスが乗った要素の強調。既定は reverse = true で、色を持たないため
  -- 本文色が背景として塗られる。マウスを使わなくても、フォルダの > の
  -- ところに帯として出てしまう。行の強調と同じ色にして目立たせない
  vim.api.nvim_set_hl(0, 'DropBarMenuHoverIcon', { bg = ICEBERG.select, reverse = false })

  -- 展開マーク（>）の位置に出る帯。DropBarPreview は Visual を継承しており、
  -- カーソルのある行以外の > にも背景が付いて見えていた。背景を持たせない
  local preview = vim.api.nvim_get_hl(0, { name = 'DropBarPreview', link = false })
  preview.bg = nil
  preview.reverse = nil
  preview.default = nil
  vim.api.nvim_set_hl(0, 'DropBarPreview', preview)

  -- メニュー自体の背景。フロート全般と揃える
  vim.api.nvim_set_hl(0, 'DropBarMenuNormalFloat', { link = 'NormalFloat' })
  vim.api.nvim_set_hl(0, 'DropBarMenuFloatBorder', { link = 'FloatBorder' })

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
