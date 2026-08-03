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

--- 一覧をまとめて出すための入り口。これを打てば全件が並ぶ
local ENTRY_WORDS = { 'mref', 'mathref', 'membed', 'mathembed' }

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
  local empty = { bare = {}, full = {} }
  local path = find_index()
  if not path then
    return empty
  end

  local stat = vim.uv.fs_stat(path)
  if not stat then
    return empty
  end
  if cache.path == path and cache.mtime == stat.mtime.sec and cache.bare then
    return cache
  end

  local ok, decoded = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(path), '\n'))
  end)
  if not ok or type(decoded) ~= 'table' then
    return empty
  end

  -- 2通りの候補を作る。
  --   bare  id だけ。既にあるタグの id を書き換える時に使う
  --   full  タグごと。mref と打つか、id の一部を打った時に一発で完成させる
  local bare, full = {}, {}
  local ref_kind = require('blink.cmp.types').CompletionItemKind.Reference

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

      bare[#bare + 1] = {
        label = entry.id,
        detail = detail,
        documentation = doc,
        kind = ref_kind,
        insertText = entry.id,
      }

      -- label は正式名で作る。blink の照合は「文字を順に拾えるか」なので、
      -- label に無い文字を含む語では引けない。mref-... だと h が無いため
      -- mathref と打っても一致しなかった。
      --
      -- 正式名にすると短縮形も通る。mref は mathref の中に m,r,e,f として
      -- 順に含まれるため。参照と埋め込みが混ざることもない
      -- （mref は mathembed に含まれない）。
      --
      -- filterText は使わない。blink はこれを絞り込みだけでなく置換範囲の
      -- 推定にも使うため、空白を含む値を渡すと候補が表示されなくなる
      for _, spec in ipairs({
        { name = 'mathref', component = 'MathReference' },
        { name = 'mathembed', component = 'MathEmbed' },
      }) do
        full[#full + 1] = {
          label = ('%s-%s'):format(spec.name, entry.id),
          detail = detail,
          documentation = doc,
          kind = ref_kind,
          -- 置き換える範囲は打った語の位置に依存するので、要求時に textEdit を
          -- 組み立てる。ここでは差し込む文字列だけ持たせておく
          newText = ('<%s id="%s" />'):format(spec.component, entry.id),
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
--- id=" のあとに1文字打つまで候補が出ない
function M:get_trigger_characters()
  return { '"' }
end

function M:get_completions(context, callback)
  -- 内蔵のソース（path など）と同じく非同期で返す。
  -- 同期で呼ぶと blink 側の処理と噛み合わないことがある
  callback = vim.schedule_wrap(callback)

  local before = context.line:sub(1, context.cursor[2])
  local loaded = load_items()

  local function done(items)
    callback({
      items = items or {},
      -- 打つたびに問い合わせ直させる。
      --
      -- false は「結果は完全なので以降は聞かなくてよい」という意味で、
      -- blink は最初の応答をキャッシュして使い回す。1文字目の「m」の時点で
      -- 空を返すとそれが確定してしまい、mref まで打っても候補が出なかった。
      -- 打った語によって返すものが変わるソースなので true が正しい
      is_incomplete_forward = true,
      is_incomplete_backward = true,
    })
  end

  -- 既にあるタグの id を書き換えている時は、id だけを候補にする
  if before:match('<Math%a*%s[^>]*id="[^"]*$') then
    done(loaded.bare)
    return
  end

  -- 打っている途中の語。日本語では blink がそもそも補完を起動しないため、
  -- 半角の英数字とハイフンだけを見れば足りる
  local word = before:match('([%w%-]+)$')
  if not word or #word < 2 then
    -- 1文字では候補を出さない。どの id にも当たってしまい邪魔になるため。
    -- is_incomplete_forward = true なので、続きを打てば聞き直される
    done({})
    return
  end
  local needle = word:lower()

  -- 打った語をタグごと置き換える。範囲を明示しないと blink は insertText の
  -- 見た目から置換範囲を推測しようとするが、<MathReference ... は打った語と
  -- 形が違いすぎて決められず、候補ごと捨てられてしまう
  local row = context.cursor[1] - 1
  local start_col = context.cursor[2] - #word
  local function with_edit(item)
    return vim.tbl_extend('force', item, {
      textEdit = {
        range = {
          start = { line = row, character = start_col },
          ['end'] = { line = row, character = context.cursor[2] },
        },
        newText = item.newText,
      },
    })
  end

  -- mref のような入り口の語なら全件を並べる。何があるか分からない時用
  for _, entry_word in ipairs(ENTRY_WORDS) do
    if entry_word:find(needle, 1, true) == 1 then
      done(vim.tbl_map(with_edit, loaded.full))
      return
    end
  end

  -- そうでなければ id に含まれる語を打った時だけ出す。euler と打てば
  -- euler-formula が出る。文章中のふつうの語はどの id にも当たらないので、
  -- 候補は出ない
  local matched = {}
  for _, item in ipairs(loaded.full) do
    -- label は mathref-<id> の形。接頭辞を外した部分が id にあたる
    local id = item.label:gsub('^math%a*%-', '')
    if id:lower():find(needle, 1, true) then
      matched[#matched + 1] = with_edit(item)
    end
  end
  done(matched)
end

return M
