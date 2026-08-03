--- スニペットを一覧から選んで挿入する。
---
--- 補完（<C-l>）は名前をうろ覚えでも呼び出せるが、そもそも何があるのか
--- 分からない時には使えない。こちらは中身をプレビューしながら選ぶための入口。
---
--- スニペットの実体は <config>/snippets/<filetype>.json（VSCode 形式）。
--- blink.cmp が補完に使っているものと同じファイルを読む。
local M = {}

local SNIPPET_DIR = vim.fn.stdpath('config') .. '/snippets'

--- filetype の継承関係。completion.lua の extended_filetypes と揃える。
--- tsx を書いている時に typescript / javascript のスニペットも候補に出す
local EXTENDED = {
  typescript = { 'javascript' },
  typescriptreact = { 'typescript', 'javascript' },
  javascriptreact = { 'javascript' },
  mdx = { 'markdown' },
  scss = { 'css' },
}

--- 読み込む filetype を並べる。all は常に含める
local function target_filetypes(ft)
  local list = { 'all' }
  if ft ~= '' then
    table.insert(list, ft)
    vim.list_extend(list, EXTENDED[ft] or {})
  end
  return list
end

--- VSCode 形式の body は文字列か文字列の配列。行の配列に揃える
local function to_lines(body)
  if type(body) == 'table' then
    return body
  end
  return vim.split(tostring(body), '\n')
end

--- 現在の filetype で使えるスニペットを集める
local function collect()
  local items = {}
  for _, ft in ipairs(target_filetypes(vim.bo.filetype)) do
    local path = ('%s/%s.json'):format(SNIPPET_DIR, ft)
    if vim.fn.filereadable(path) == 1 then
      local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), '\n'))
      if ok and type(decoded) == 'table' then
        for name, spec in pairs(decoded) do
          -- prefix は文字列か配列。複数の呼び出し名を持てる
          local prefixes = type(spec.prefix) == 'table' and spec.prefix or { spec.prefix }
          for _, prefix in ipairs(prefixes) do
            items[#items + 1] = {
              prefix = prefix,
              name = name,
              description = spec.description or '',
              lines = to_lines(spec.body),
              filetype = ft,
            }
          end
        end
      else
        vim.notify(('スニペットを読めませんでした: %s'):format(path), vim.log.levels.WARN)
      end
    end
  end
  table.sort(items, function(a, b)
    return a.prefix < b.prefix
  end)
  return items
end

--- 一覧を出して、選んだものをカーソル位置へ展開する
function M.pick()
  local items = collect()
  if #items == 0 then
    -- 「無い」だけでは次に何をすればよいか分からないので、置き場所まで示す。
    -- all.json は全ファイルタイプで有効
    local ft = vim.bo.filetype ~= '' and vim.bo.filetype or 'all'
    vim.notify(
      ('%s のスニペットはありません\nsnippets/%s.json に追加できます'):format(ft, ft),
      vim.log.levels.INFO
    )
    return
  end

  -- 表示用の行と、そこから元の項目を引くための対応表
  local labels, by_label = {}, {}
  for _, item in ipairs(items) do
    local label = ('%-14s %s'):format(item.prefix, item.description ~= '' and item.description or item.name)
    labels[#labels + 1] = label
    by_label[label] = item
  end

  local ok, fzf = pcall(require, 'fzf-lua')
  if not ok then
    -- fzf-lua が無い環境では標準の選択画面に落とす
    vim.ui.select(labels, { prompt = 'Snippets' }, function(choice)
      if choice then
        M.expand(by_label[choice])
      end
    end)
    return
  end

  fzf.fzf_exec(labels, {
    prompt = 'Snippets> ',
    winopts = { title = ' スニペット ', preview = { hidden = false } },
    -- 選択中のスニペットの中身をそのまま見せる。
    -- 展開前の $1 $0 も見えた方が、どこにカーソルが来るか分かる
    previewer = false,
    fzf_opts = {
      ['--preview'] = fzf.shell.raw_action(function(selected)
        local item = by_label[selected[1]]
        return item and item.lines or {}
      end),
      ['--preview-window'] = 'right:60%',
    },
    actions = {
      ['default'] = function(selected)
        local item = selected and by_label[selected[1]]
        if item then
          M.expand(item)
        end
      end,
    },
  })
end

--- 選んだスニペットをカーソル位置へ展開する。
--- vim.snippet を使うので $1 $2 は Tab で渡り歩ける
function M.expand(item)
  if not item then
    return
  end
  vim.schedule(function()
    if vim.fn.mode() ~= 'i' then
      vim.cmd('startinsert')
    end
    vim.snippet.expand(table.concat(item.lines, '\n'))
  end)
end

function M.setup()
  vim.api.nvim_create_user_command('Snippets', M.pick, {
    desc = 'スニペットを一覧から選んで挿入する',
  })
end

return M
