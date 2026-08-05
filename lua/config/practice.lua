--- 操作の練習用ファイルを開く。
---
--- docs/practice/ にある教材を、そのまま開くのではなく作業用の場所へ複製してから
--- 開く。練習では実際にファイルを書き換えるので、原本を直接開くとリポジトリに
--- 差分が出てしまう。複製なら :Practice を実行し直すだけで初期状態に戻せる。
local M = {}

--- 教材の置き場。設定ディレクトリの中にある
local SOURCE = vim.fs.joinpath(vim.fn.stdpath('config'), 'docs', 'practice')

--- 複製先。設定とは別の、消えても困らない場所
local WORKDIR = vim.fs.joinpath(vim.fn.stdpath('state'), 'practice')

--- 教材の一覧を返す。ファイル名の先頭に番号を振ってあるので、並べれば順番になる
local function entries()
  local found = vim.fn.globpath(SOURCE, '*.md', false, true)
  table.sort(found)
  return found
end

--- 1行目の見出しを取り出す。一覧に出す時の説明として使う
local function title(path)
  local first = (vim.fn.readfile(path, '', 1) or {})[1] or ''
  return (first:gsub('^#%s*', ''))
end

--- 教材を作業用の場所へ複製して開く
function M.open(path)
  vim.fn.mkdir(WORKDIR, 'p')
  local target = vim.fs.joinpath(WORKDIR, vim.fs.basename(path))

  -- 開いたまま作業していた場合、複製してもバッファは古いままなので先に捨てる
  local existing = vim.fn.bufnr(target)
  if existing ~= -1 then
    vim.api.nvim_buf_delete(existing, { force = true })
  end

  local ok, err = vim.uv.fs_copyfile(path, target)
  if not ok then
    vim.notify('練習用ファイルを複製できませんでした: ' .. tostring(err), vim.log.levels.ERROR)
    return
  end

  vim.cmd.edit(vim.fn.fnameescape(target))
  vim.notify('やり直すときは :Practice、1手戻すときは u', vim.log.levels.INFO)
end

--- 一覧から選んで開く
function M.pick()
  local found = entries()
  if #found == 0 then
    vim.notify('練習用ファイルがありません: ' .. SOURCE, vim.log.levels.WARN)
    return
  end

  vim.ui.select(found, {
    prompt = '練習する操作を選ぶ',
    format_item = title,
  }, function(choice)
    if choice then
      M.open(choice)
    end
  end)
end

function M.setup()
  vim.api.nvim_create_user_command('Practice', function(args)
    if args.args == '' then
      M.pick()
      return
    end
    -- 番号や名前の一部でも選べるようにする
    for _, path in ipairs(entries()) do
      if vim.fs.basename(path):find(args.args, 1, true) then
        M.open(path)
        return
      end
    end
    vim.notify('見つかりません: ' .. args.args, vim.log.levels.WARN)
  end, {
    nargs = '?',
    complete = function()
      return vim.tbl_map(vim.fs.basename, entries())
    end,
    desc = '操作の練習用ファイルを開く',
  })
end

return M
