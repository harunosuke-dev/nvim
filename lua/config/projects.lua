--- <Space>fp で並べるプロジェクトの一覧を組み立てる。
---
--- 順番は「ここで指定したもの」→「zoxide が覚えている訪問先」。
--- 重複するものは zoxide 側を出さないので、こちらの並びが優先される。
local M = {}

--- 配下を1階層ぶん並べるディレクトリ。中のディレクトリがそれぞれ1件になる
M.roots = {
  '~/Repos/github.com/Harunosuke-web',
  '~/Projects',
}

--- 単体で足したいもの。上の roots に当てはまらない場所
M.paths = {
  '~/.dotfiles',
}

--- 末尾のスラッシュを落とし、シンボリックリンクも実体に寄せて比較できる形にする
local function normalize(path)
  local expanded = vim.fn.expand(path)
  return (vim.uv.fs_realpath(expanded) or expanded):gsub('/$', '')
end

--- zoxide が覚えている訪問先。入っていなければ空を返す
local function from_zoxide()
  if vim.fn.executable('zoxide') == 0 then
    return {}
  end
  local out = vim.fn.systemlist({ 'zoxide', 'query', '-l' })
  if vim.v.shell_error ~= 0 then
    return {}
  end
  return out
end

--- 表示と移動に使う一覧を返す。重複は先に出てきた方を残す
---@return string[] 絶対パスの配列
function M.list()
  local seen, result = {}, {}

  local function add(path)
    if path == '' or vim.fn.isdirectory(vim.fn.expand(path)) == 0 then
      return
    end
    local full = normalize(path)
    if not seen[full] then
      seen[full] = true
      result[#result + 1] = full
    end
  end

  for _, root in ipairs(M.roots) do
    local expanded = vim.fn.expand(root)
    local children = vim.fn.readdir(expanded, function(name)
      return vim.fn.isdirectory(expanded .. '/' .. name) == 1 and 1 or 0
    end)
    table.sort(children)
    for _, name in ipairs(children) do
      add(expanded .. '/' .. name)
    end
  end

  for _, path in ipairs(M.paths) do
    add(path)
  end

  for _, path in ipairs(from_zoxide()) do
    add(path)
  end

  return result
end

return M
