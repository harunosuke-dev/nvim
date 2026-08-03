--- 数式定義の id を補完する blink.cmp のソース。
---
--- ブログでは `<MathReference id="..." />` で別ページの定義を参照する。
--- id は `npm run generate:math-index` が作る public/math-index.json に載っている。
---
--- 以前は生成結果を .vscode/mdx.code-snippets へ書き出していたが、定義を
--- 増やすたびに再生成が要り、忘れると静かにずれる。実際、索引の11件と
--- スニペットの12件で一致するものが1つも無い状態になっていた。
---
--- ここでは索引を直接読む。生成物を複製しないので、ずれようがない。
local M = {}

--- 索引の位置。プロジェクトの直下にある
local INDEX_PATH = 'public/math-index.json'

--- 読み込み結果を持ち回す。ファイルの更新時刻が変わった時だけ読み直す
local cache = { path = nil, mtime = nil, items = nil }

--- 種類の表示名。索引の type をそのまま出しても分かりにくい
local TYPE_LABEL = {
  definition = '定義',
  theorem = '定理',
  lemma = '補題',
  corollary = '系',
  axiom = '公理',
  example = '例',
  proposition = '命題',
}

--- 現在のバッファから上へ辿って索引を探す。
--- 複数のプロジェクトを開いていても、そのファイルが属する方を読む
local function find_index()
  local start = vim.api.nvim_buf_get_name(0)
  if start == '' then
    start = vim.uv.cwd()
  end
  local found = vim.fs.find(INDEX_PATH, { path = vim.fs.dirname(start), upward = true, type = 'file' })
  return found[1]
end

--- 索引を読む。更新されていなければ前回の結果を返す
local function load_items()
  local path = find_index()
  if not path then
    return {}
  end

  local stat = vim.uv.fs_stat(path)
  if not stat then
    return {}
  end
  if cache.path == path and cache.mtime == stat.mtime.sec and cache.items then
    return cache.items
  end

  local ok, decoded = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(path), '\n'))
  end)
  if not ok or type(decoded) ~= 'table' then
    return {}
  end

  local items = {}
  for _, entry in ipairs(decoded.items or {}) do
    if entry.id then
      local kind = TYPE_LABEL[entry.type] or entry.type or ''
      -- 本文は HTML と TeX が混ざっているので、タグだけ落として要約に使う
      local summary = (entry.content or ''):gsub('<[^>]->', ''):gsub('%s+', ' ')
      items[#items + 1] = {
        label = entry.id,
        -- 候補の右側に出る補助表示。id だけでは何の定義か分からないため
        detail = ('%s｜%s｜%s'):format(kind, entry.title or '', entry.category or ''),
        documentation = {
          kind = 'markdown',
          value = table.concat({
            ('**%s**  %s'):format(entry.title or entry.id, kind),
            '',
            summary,
            '',
            ('分野: %s'):format(entry.field or '-'),
          }, '\n'),
        },
        kind = require('blink.cmp.types').CompletionItemKind.Reference,
        insertText = entry.id,
      }
    end
  end

  cache = { path = path, mtime = stat.mtime.sec, items = items }
  return items
end

function M.new()
  return setmetatable({}, { __index = M })
end

--- mdx と markdown でのみ働く
function M:enabled()
  return vim.tbl_contains({ 'mdx', 'markdown' }, vim.bo.filetype)
end

function M:get_completions(context, callback)
  local before = context.line:sub(1, context.cursor[2])

  -- <MathReference id=" や <MathEmbed id=" の内側にいる時だけ候補を出す。
  -- 常に出すと通常の文章を書いている最中にも混ざって邪魔になる
  if not before:match('<Math%a*%s[^>]*id="[^"]*$') then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return
  end

  callback({
    items = load_items(),
    is_incomplete_forward = false,
    is_incomplete_backward = false,
  })
end

return M
