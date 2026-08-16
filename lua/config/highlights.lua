-- iceberg 専用の配色調整。
--
-- 面は塗らない。本文・左端の列・パンくず・フロートはすべてテーマの既定に任せ、
-- 端末の背景を透けさせる（M.transparent()）。ここで足すのは文字の明度の階層と、
-- カーソル行の帯だけ。
--
-- 呼び出し側は M.setup() を一度だけ実行する。
-- gitsigns のように後から自前のハイライトを定義するプラグインからは
-- M.apply() を直接呼ぶ（下のコメント参照）
local M = {}

local ICEBERG = {
  cursor = 0x1f2233, -- カーソル行の帯。素の iceberg の行番号の列の色
  breadcrumb = 0x7d8296, -- 補助的な文字。本文より一段落とす
  linenr = 0x454d73, -- ステータスラインの文字。素の iceberg の行番号と同じ明度
  faint = 0x555b73, -- 補助的な文字。breadcrumb よりさらに一段落とす
  select = 0x3a4160, -- 一覧の中でカーソルがある行。反転をやめる代わりに敷く
  border = 0x6c7189, -- 分割の境界線。素の iceberg の FloatBorder と同じ値で揃える
}

--- 差分表示（:diffthis / <leader>hd）の配色。
---
--- テーマに依らず同じ色を使う。差分は「何が変わったか」を読むための表示で、
--- カラースキームごとに見え方が変わると読み方を切り替えることになるため。
---
--- 色は Claude Code の画面から実測した値。バイナリ内の定義は
--- rgb(122,41,54) / rgb(34,92,43) だが、実際の表示はこの値になる。
--- 端末側の扱いが絡んでいるらしく、定義から表示値は導けなかったため実測を採る。
---
--- 変わった文字（DiffText）は地より一段明るくして、行のどこが変わったかを示す。
--- 行を丸ごと書き換えた時はその行全体がこの色になるが、「全部変わった」という
--- 意味なので筋は通る。行の追加は DiffAdd になるのでこの色にはならない。
---
--- 文字色は変わった部分（DiffText）にだけ与える。iceberg の構文の色は
--- 彩度の低い淡色で、暗く彩度の高い赤や緑の上では沈んで読みにくい。
--- 行全体には与えない。与えるとその行が一色に潰れて構文が読めなくなる
local DIFF = {
  add = 0x015f00, -- 追加された行・変更行の地（新しい側）
  delete = 0x5f0000, -- 削除された行・変更行の地（古い側）
  add_word = 0x018700, -- 変更行の中で実際に変わった部分（新しい側）
  delete_word = 0x870000, -- 変更行の中で実際に変わった部分（古い側）
  fill = 0x7a3a3a, -- 削除側に並ぶ埋め文字。今は空白なので実質使わない
  word_fg = 0xffffff, -- 変わった部分の文字色。地の色に負けないよう白にする
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

--- 記号（診断・gitsigns・TODO）のハイライトから背景色を外す。
---
--- これらは記号の列と同じ背景色を持たされている。列の色を変えたり透過させたり
--- すると、記号のある行だけ左端の色が変わり、カーソル行でも光らない
--- （kanagawa-dragon の GitSignsChange など）。
--- 背景を外して SignColumn / CursorLineSign から受け継がせる。
---
--- 末尾が Ln のものは「行全体の着色」用で、記号の列とは役割が違うため除外する
local function clear_sign_backgrounds()
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
end

function M.apply()
  if vim.g.colors_name ~= 'iceberg' then
    return -- 他のテーマには手を入れない
  end

  -- iceberg / iceberg-dark / iceberg-light はどれも colors_name が 'iceberg' に
  -- なるため名前では区別できない。暗い配色にだけ適用する。
  --
  -- 背景を透過させていると Normal に bg が無く、色から明暗を判定できない。
  -- その場合は 'background' の値を見る
  local normal = vim.api.nvim_get_hl(0, { name = 'Normal', link = false })
  local light = normal.bg and is_light(normal.bg) or (not normal.bg and vim.o.background == 'light')
  if light then
    return
  end

  -- 非アクティブなウィンドウは M.build_inactive() の名前空間で沈める。
  -- ここは背景を敷かないように戻すだけ。敷くと透過が切れる
  vim.api.nvim_set_hl(0, 'NormalNC', { fg = normal.fg })

  -- カーソル行。本文・行番号・記号・折りたたみを同じ色で揃えて1本の帯にする。
  -- 面を塗る指定はこれだけ残す。位置を示すためのもので、地の色ではない
  set('CursorLine', ICEBERG.cursor)
  set('CursorLineNr', ICEBERG.cursor, { bold = true })
  set('CursorLineSign', ICEBERG.cursor)
  set('CursorLineFold', ICEBERG.cursor)

  -- 記号（診断・gitsigns・TODO）の背景を外して、カーソル行の帯を通す
  clear_sign_backgrounds()

  -- 枠の左上・右下に出る見出し。文字だけ橙から補助的な色へ落とす
  vim.api.nvim_set_hl(0, 'FloatTitle', { fg = ICEBERG.breadcrumb })
  vim.api.nvim_set_hl(0, 'FloatFooter', { fg = ICEBERG.faint })

  -- 分割の境界線。素の iceberg は文字色も背景と同じ #101218 で、面を透過させると
  -- 何も見えなくなる（端末背景に対してコントラスト 1.07）。フロートの枠と
  -- 同じ #6c7189 に上げて 4.15 にする
  vim.api.nvim_set_hl(0, 'WinSeparator', { fg = ICEBERG.border })
  vim.api.nvim_set_hl(0, 'VertSplit', { fg = ICEBERG.border })

  -- ポップアップのスクロールバー。軌道は透過のままにして、つまみだけ残す。
  -- 素の #c7c9d1 は本文と同じ明るさで白い棒として強く出るため、境界線と
  -- 同じ #6c7189 まで落とす
  vim.api.nvim_set_hl(0, 'PmenuThumb', { bg = ICEBERG.border })
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

  -- ステータスラインの文字色だけここで決める。背景は M.match_statusline()
  -- がテーマを問わず本文に合わせる
  vim.api.nvim_set_hl(0, 'StatusLine', { fg = ICEBERG.linenr })
  vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = ICEBERG.linenr })
  -- 補完メニュー（blink.cmp）の文字の明るさに階層をつける。
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
  vim.api.nvim_set_hl(0, 'BlinkCmpDoc', { fg = ICEBERG.breadcrumb })
  for _, group in ipairs({
    'BlinkCmpLabelDetail',
    'BlinkCmpLabelDescription',
    'BlinkCmpKind',
    'BlinkCmpSource',
  }) do
    vim.api.nvim_set_hl(0, group, { fg = ICEBERG.faint })
  end

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

  -- 進捗の本文（Loading workspace など）が読めない問題。
  --
  -- noice は既定で NonText を継承させる。iceberg の NonText は #252941 で、
  -- フロートの背景 #1f2233 とほぼ同じ明度のため文字が沈む。
  -- NonText は `~` を目立たせないための色であって、読ませる文字には向かない
  vim.api.nvim_set_hl(0, 'NoiceLspProgressTitle', { fg = ICEBERG.breadcrumb })

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

  -- 色が出揃った後に、非アクティブ用の複製を作り直す
  M.build_inactive()
end

--- 非アクティブなウィンドウ用の色。窓ごとの名前空間として持つ。
---
--- 背景を敷いて見分ける方法は透過と両立しない。全グループの複製を作って
--- 色だけ沈め、nvim_win_set_hl_ns で窓に当てる（lua/config/autocmds.lua）。
---
--- NormalNC の文字色を落とすやり方では足りない。構文色を持つ文字は自分の
--- 色で描かれるため沈まず、非アクティブ側の local が rgb(133,160,199) の
--- ままだった（実測）。名前空間なら構文色ごと沈む
local inactive_ns

--- 45% 沈める。コントラストは 12.10 対 3.93 で 3.1 倍の開き
local INACTIVE = 0.55

--- 非アクティブなウィンドウでは背景を持たせないグループ。
--- カーソル行の帯とカーソル下の単語（illuminate）は、今読んでいる窓だけでよい
local INACTIVE_NO_BG = {
  CursorLine = true,
  CursorLineNr = true,
  CursorLineSign = true,
  CursorLineFold = true,
  IlluminatedWordText = true,
  IlluminatedWordRead = true,
  IlluminatedWordWrite = true,
}

function M.inactive_ns()
  if not inactive_ns then
    inactive_ns = vim.api.nvim_create_namespace('user_inactive')
  end
  return inactive_ns
end

function M.build_inactive()
  local ns = M.inactive_ns()
  for name in pairs(vim.api.nvim_get_hl(0, {})) do
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    -- nvim_get_hl は default = true を含めて返す。そのまま渡すと
    -- 「既存定義があれば何もしない」書き込みになり、上書きできない
    hl.default = nil
    if hl.fg then
      hl.fg = dim(hl.fg, INACTIVE)
    end
    if hl.bg then
      hl.bg = dim(hl.bg, INACTIVE)
    end
    if INACTIVE_NO_BG[name] then
      hl.bg = nil
    end
    vim.api.nvim_set_hl(ns, name, hl)
  end
end

--- どのテーマでも、面を塗らずに端末の背景を透けさせる。
---
--- 対象は「UI の地」として塗られているものすべて。本文・左端の列・
--- ステータスライン・パンくずに加えて、フロートやポップアップの面、
--- 分割の境界、タブ、メッセージ行まで含める。
---
--- 入れないものが3つある。
---   NormalNC       非アクティブなウィンドウの減光（M.build_inactive() が沈める）
---   *Sel / WildMenu ポップアップの中で選んでいる行。CursorLine と同じ役割
---   Cursor / TermCursor カーソルそのもの
local TRANSPARENT_GROUPS = {
  -- 本文と左端の列
  'Normal',
  'SignColumn',
  'LineNr',
  'LineNrAbove',
  'LineNrBelow',
  'FoldColumn',
  'EndOfBuffer',
  'Conceal',
  -- 窓の縁
  'StatusLine',
  'StatusLineNC',
  'StatusLineTerm',
  'StatusLineTermNC',
  'WinBar',
  'WinBarNC',
  'WinSeparator',
  'VertSplit',
  'TabLine',
  'TabLineFill',
  'TabLineSel',
  'ToolbarLine',
  'ToolbarButton',
  -- フロート（K のホバー・which-key・noice など）
  'NormalFloat',
  'FloatBorder',
  'FloatTitle',
  'FloatFooter',
  'FloatShadow',
  'FloatShadowThrough',
  'DiagnosticFloatingError',
  'DiagnosticFloatingWarn',
  'DiagnosticFloatingInfo',
  'DiagnosticFloatingHint',
  'DiagnosticFloatingOk',
  -- ポップアップメニュー。軌道（Sbar）は透過させ、つまみ（Thumb）だけ
  -- M.apply() で色を当てて残す
  'Pmenu',
  'PmenuBorder',
  'PmenuExtra',
  'PmenuKind',
  'PmenuSbar',
  'PmenuShadow',
  'PmenuShadowThrough',
  -- メッセージ行
  'MsgArea',
  'MsgSeparator',
  'ErrorMsg',
  'WarningMsg',
  'StderrMsg',
  'StdoutMsg',
  'Error',
}

--- 差分表示の配色を当てる。テーマに依らず同じ色にする。
---
--- 追加は緑・削除は赤という git の慣例に寄せる。Neovim は「変更行」という
--- 状態を持つが、git や GitHub は変更を「削除（赤）+ 追加（緑）」の組で表すので、
--- 変更行の地と変わった文字は窓ごとに赤と緑へ振り分ける
--- （lua/config/autocmds.lua が winhighlight で読み替える）。
--- ここで定義する Old / New はその読み替え先。
---
--- 行全体を塗るものには文字色を指定しない。差分の中でも構文強調が見えた方が
--- 読みやすい。実際に変わった文字だけは白くして浮かせる。数文字ぶんしか
--- 塗られないので、構文の色を失う代償が小さい
function M.diff()
  -- DiffAdd は「git で追加された行」ではなく「この窓にだけあって相手の窓には
  -- 無い行」の意味。削除した行は古い側にしか無いので、素のままだと古い側で
  -- 緑になり、git の慣例と逆を向く。これも左右へ振り分ける
  vim.api.nvim_set_hl(0, 'DiffAdd', { bg = DIFF.add })
  vim.api.nvim_set_hl(0, 'DiffAddOld', { bg = DIFF.delete })
  vim.api.nvim_set_hl(0, 'DiffAddNew', { bg = DIFF.add })
  vim.api.nvim_set_hl(0, 'DiffChange', { bg = DIFF.delete })
  vim.api.nvim_set_hl(0, 'DiffChangeOld', { bg = DIFF.delete })
  vim.api.nvim_set_hl(0, 'DiffChangeNew', { bg = DIFF.add })
  vim.api.nvim_set_hl(0, 'DiffText', { bg = DIFF.delete_word, fg = DIFF.word_fg })
  vim.api.nvim_set_hl(0, 'DiffTextOld', { bg = DIFF.delete_word, fg = DIFF.word_fg })
  vim.api.nvim_set_hl(0, 'DiffTextNew', { bg = DIFF.add_word, fg = DIFF.word_fg })
  vim.api.nvim_set_hl(0, 'DiffTextAdd', { bg = DIFF.add_word, fg = DIFF.word_fg })
  -- 行が無い側に並ぶ埋め。相手側の色を持たせると「左に赤・右に緑」が崩れるので
  -- 何も塗らない。行が揃って表示されるため、空白でも欠けている場所は分かる
  vim.api.nvim_set_hl(0, 'DiffDelete', { fg = DIFF.fill })
end

--- カーソル行の帯を左端の列まで伸ばす。
---
--- 多くのテーマは本文の部分（CursorLine）にしか色を持たせておらず、行番号・
--- 記号・折りたたみの列で帯が途切れる。CursorLine の背景をそれらにも与えて
--- 1本の帯にする。
---
--- 文字色はテーマの指定をそのまま残す。行番号だけ色を変えて現在行を示す
--- テーマがあるため
function M.match_cursorline()
  local cursor = vim.api.nvim_get_hl(0, { name = 'CursorLine', link = false })
  if not cursor.bg then
    return
  end
  for _, group in ipairs({ 'CursorLineNr', 'CursorLineSign', 'CursorLineFold' }) do
    local current = vim.api.nvim_get_hl(0, { name = group, link = false })
    current.bg = cursor.bg
    -- nvim_get_hl は default = true を含めて返す。そのまま渡すと
    -- 「既存定義があれば何もしない」書き込みになり、上書きできない
    current.default = nil
    vim.api.nvim_set_hl(0, group, current)
  end
end

function M.transparent()
  if not vim.g.transparent_background then
    return
  end
  for _, group in ipairs(TRANSPARENT_GROUPS) do
    local current = vim.api.nvim_get_hl(0, { name = group, link = false })
    current.bg = 'NONE'
    -- 反転（reverse）だけは残さない。fg と bg を入れ替える指定なので、
    -- 背景を外した状態では文字色が背景として塗られ、透過にならない。
    -- 太字・イタリック・下線はテーマの指定をそのまま活かす
    current.reverse = nil
    -- nvim_get_hl は default = true を含めて返す。そのまま渡すと
    -- 「既存定義があれば何もしない」書き込みになり、上書きできない
    current.default = nil
    vim.api.nvim_set_hl(0, group, current)
  end
  clear_sign_backgrounds()
end

--- lualine の配色を組み立てる。
---
--- 全区画の背景を本文（Normal）と同じ色に揃え、区画ごとに色が変わる既定の
--- 見た目をやめる。本文と地続きの面にして、文字だけが乗って見えるようにする。
---
--- 本文の色はテーマによって違うので決め打ちにしない。iceberg では本文を
--- 塗っていない（端末の色を透けさせている）ため、塗らない指定になる。
---
--- 元の配色（auto テーマ）はカラースキームから生成されるので、それを土台に
--- 背景だけ差し替える。モード表示の区画は「濃い文字 + 明るい背景」の作りなので、
--- 背景色を文字色へ移して見分けを保つ
function M.lualine_theme()
  -- auto テーマは読み込み時のカラースキームから生成され、その結果が
  -- モジュールとしてキャッシュされる。テーマを切り替えても作り直されないので、
  -- 明示的に捨ててから読み込む。これをしないとモード表示の色が
  -- 最初のテーマのまま固定される
  package.loaded['lualine.themes.auto'] = nil
  local ok, auto = pcall(require, 'lualine.themes.auto')
  if not ok then
    return 'auto'
  end
  local normal = vim.api.nvim_get_hl(0, { name = 'Normal', link = false })
  local bg = normal.bg and string.format('#%06x', normal.bg) or 'NONE'
  local theme = vim.deepcopy(auto)
  for _, mode in pairs(theme) do
    for name, section in pairs(mode) do
      if name == 'a' and section.bg then
        section.fg = section.bg -- モードの色を文字側へ移す
        section.gui = 'bold'
      end
      section.bg = bg
    end
  end
  return theme
end

--- ステータスラインの背景を本文（Normal）に合わせる。
---
--- テーマごとに独自の色を持っているが、それだと帯だけ浮いて見える。
--- 本文と同じ面にして、文字だけが乗っている状態にしたい。
---
--- iceberg では本文を塗っていない（端末の色を透けさせている）ため、
--- 塗らない指定になる。どのテーマでも「本文と同じ」という結果は変わらない。
---
--- lualine は区画ごとに自前の背景を持つので、そちらのテーマも作り直す
--- （lua/plugins/ui.lua の flat_theme が Normal を読む）
function M.match_statusline()
  local normal = vim.api.nvim_get_hl(0, { name = 'Normal', link = false })
  for _, group in ipairs({ 'StatusLine', 'StatusLineNC' }) do
    local current = vim.api.nvim_get_hl(0, { name = group, link = false })
    vim.api.nvim_set_hl(0, group, { fg = current.fg, bg = normal.bg or 'NONE' })
  end

  -- lualine は区画ごとに自前の背景を持つので、そちらも作り直す。
  -- 現在の設定を取り出してテーマだけ差し替える（lazy.nvim の opts は
  -- キャッシュされていて評価し直せない）
  if package.loaded['lualine'] then
    local lualine = require('lualine')
    local config = lualine.get_config()
    config.options = config.options or {}
    config.options.theme = M.lualine_theme()
    pcall(lualine.setup, config)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup('user_highlights', { clear = true })

  -- カラースキームを切り替えるたびに当て直す（iceberg 以外では何もしない）
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = group,
    callback = function()
      -- 1. どのテーマでも面を透過させる
      M.transparent()
      -- 2. カーソル行の帯を左端の列まで伸ばす
      M.match_cursorline()
      -- 3. どのテーマでも差分の配色を揃える
      M.diff()
      -- 4. iceberg だけ、その上に階層（左端の列・パンくず）を作り直す
      M.apply()
      -- 5. ステータスラインと lualine を本文に合わせる
      vim.schedule(M.match_statusline)
    end,
  })
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
