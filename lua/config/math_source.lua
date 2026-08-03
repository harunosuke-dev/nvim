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
local cache = { path = nil, mtime = nil, bare = nil, full = nil }

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
  if cache.path == path and cache.mtime == stat.mtime.sec and cache.bare then
    return cache
  end

  local ok, decoded = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(path), '\n'))
  end)
  if not ok or type(decoded) ~= 'table' then
    return {}
  end

  -- 2通りの候補を作る。
  --   bare  id だけ。既にあるタグの id を書き換える時に使う
  --   full  タグごと。mref / membed と打った時に一発で完成させる
  local bare, full = {}, {}
  for _, entry in ipairs(decoded.items or {}) do
    if entry.id then
      local kind = TYPE_LABEL[entry.type] or entry.type or ''
      -- 本文は HTML と TeX が混ざっているので、タグだけ落として要約に使う
      local summary = (entry.content or ''):gsub('<[^>]->', ''):gsub('%s+', ' ')
      local detail = ('%s｜%s｜%s'):format(kind, entry.title or '', entry.category or '')
      local doc = {
        kind = 'markdown',
        value = table.concat({
          ('**%s**  %s'):format(entry.title or entry.id, kind),
          '',
          summary,
          '',
          ('分野: %s'):format(entry.field or '-'),
        }, '\n'),
      }
      local ref_kind = require('blink.cmp.types').CompletionItemKind.Reference

      bare[#bare + 1] = {
        label = entry.id,
        detail = detail,
        documentation = doc,
        kind = ref_kind,
        insertText = entry.id,
      }

      -- 短い名前と正式名の両方で引けるようにする。
      -- 絞り込みは filterText を見るので、候補を二重に作らずに済む
      for _, spec in ipairs({
        { short = 'mref', long = 'mathref', component = 'MathReference' },
        { short = 'membed', long = 'mathembed', component = 'MathEmbed' },
      }) do
        full[#full + 1] = {
          label = ('%s-%s'):format(spec.short, entry.id),
          -- 表示は短い方だけにして一覧を詰める
          filterText = ('%s %s %s %s'):format(spec.short, spec.long, entry.id, entry.title or ''),
          detail = detail,
          documentation = doc,
          kind = ref_kind,
          insertText = ('<%s id="%s" />'):format(spec.component, entry.id),
        }
      end
    end
  end

  cache = { path = path, mtime = stat.mtime.sec, bare = bare, full = full }
  return cache
end

function M.new()
  return setmetatable({}, { __index = M })
end

--- mdx と markdown でのみ働く
function M:enabled()
  return vim.tbl_contains({ 'mdx', 'markdown' }, vim.bo.filetype)
end

--- id=" を打った時点で候補を出す。
---
--- 補完は既定では英数字を打った時にしか起動しないため、これが無いと
--- id=" のあとに1文字打つまで候補が出ない。id は覚えていない前提なので、
--- 打つ前に一覧が見えないと意味がない。
---
--- " は mdx のどこでも打たれるが、id=" の内側以外では get_completions が
--- 空を返すのでメニューは出ない
function M:get_trigger_characters()
  return { '"' }
end

function M:get_completions(context, callback)
  local before = context.line:sub(1, context.cursor[2])
  local loaded = load_items()

  local function done(items)
    callback({
      items = items or {},
      is_incomplete_forward = false,
      is_incomplete_backward = false,
    })
  end

  -- 既にあるタグの id を書き換えている時は、id だけを候補にする
  if before:match('<Math%a*%s[^>]*id="[^"]*$') then
    done(loaded.bare)
    return
  end

  -- mref / membed と打ち始めた時は、タグごと完成させる候補を出す。
  -- スニペットで <MathReference id="" /> を展開すると引用符が先に入ってしまい、
  -- 起動文字が発火しない。補完だけで完結させた方が手数が少ない
  if before:match('m[a-z]*$') then
    done(loaded.full)
    return
  end

  done({})
end

return M
