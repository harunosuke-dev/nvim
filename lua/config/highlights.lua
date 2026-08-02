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

  -- 左端の列。カーソル行以外はすべてこの色になる
  for _, group in ipairs({ 'LineNr', 'LineNrAbove', 'LineNrBelow', 'SignColumn', 'FoldColumn' }) do
    set(group, ICEBERG.gutter)
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
