-- oil のファイラに git の状態を出す。
--
-- oil のバッファは `oil://` という実ファイルでない名前なので、gitsigns は
-- attach しない（b:gitsigns_head も付かない）。そのため oil の win_options で
-- 確保されている符号列へ、こちらで extmark を置く。
--
-- 本文（oil の「列」）ではなく符号列に置いている。oil はバッファの本文を
-- 読み直してリネームや削除を確定するファイラで、本文に列を足すとその解析対象に
-- なる。git の状態は編集できるものではないので、本文の外へ出す。
--
-- 記号は git / lazygit の一覧と同じ文字（M / A / D / R / ? / U）を使い、
-- ステージ済みかどうかは色で分ける（lazygit と同じく、ステージ済みは緑）。
local M = {}

local ns = vim.api.nvim_create_namespace('user_oil_git')

--- porcelain の状態文字 → 出す記号。ここに無い文字は表示しない
local SIGN = {
  M = 'M', -- 変更
  T = 'T', -- 種別が変わった（ファイル ⇄ シンボリックリンク）
  R = 'R', -- 改名
  C = 'C', -- 複製
  A = 'A', -- 追加
  D = 'D', -- 削除
  U = 'U', -- 衝突（未解決）
  ['?'] = '?', -- 未追跡
}

--- 色は記号ではなくステージ済みかどうかで決める（lazygit と同じ）。
--- 赤＝まだ手を入れる余地がある、緑＝一手済んでいる、という読み方に揃える。
--- 未追跡も「まだ add していない」ので赤の側に入れる。
--- 衝突だけは赤緑の軸に乗らないので独立させる
local function hl_for(code, staged)
  if code == 'U' then
    return 'OilGitConflict'
  end
  return staged and 'OilGitStaged' or 'OilGitUnstaged'
end

--- ディレクトリを1行にまとめる時の優先度。中で最も強い状態を代表として出す。
--- 手を入れる必要が大きいものほど大きい数にしてある
local PRIORITY = { U = 6, D = 5, M = 4, T = 4, R = 4, C = 4, A = 3, ['?'] = 2 }

--- 色は gitsigns の記号の色をそのまま借りる。差分の配色は
--- lua/config/highlights.lua で揃えてあり、ファイラだけ別の色にする理由が無い
local HL_LINKS = {
  -- 未ステージ。削除の赤を借りる（差分の「まだ確定していない側」の色）
  OilGitUnstaged = 'GitSignsDelete',
  -- ステージ済み。追加の緑を借りる
  OilGitStaged = 'GitSignsAdd',
  OilGitConflict = 'DiagnosticError',
}

local function set_highlights()
  for name, link in pairs(HL_LINKS) do
    vim.api.nvim_set_hl(0, name, { link = link, default = true })
  end
end

--- `XY path` の2文字から、この行に出す状態を決める。
---
--- 1文字目がインデックス（ステージ済み）、2文字目が作業ツリー。
--- 作業ツリー側に何かあればそれを優先する。まだ保存しただけでコミットして
--- いない変更の方が、目で拾いたい対象だから。
--- 両方 ` ` の行は git が出さないので、戻り値が nil になるのは想定外の書式のみ
---@return string? code, boolean? staged
local function pick_status(x, y)
  if y ~= ' ' and y ~= '' then
    return y, false
  elseif x ~= ' ' and x ~= '' then
    return x, true
  end
end

--- 今の候補より新しい候補の方が強ければ差し替える。
--- 優先度が同じ時は未ステージを採る（ステージ済みは一手済んでいるため）
local function merge(current, code, staged)
  if not current then
    return { code = code, staged = staged }
  end
  local a, b = PRIORITY[code] or 0, PRIORITY[current.code] or 0
  if a > b or (a == b and current.staged and not staged) then
    return { code = code, staged = staged }
  end
  return current
end

--- git status の出力を「この画面に並ぶ名前」→ 状態の対応へ畳む。
---
--- porcelain のパスはリポジトリ根からの相対で、今開いているディレクトリからでは
--- ない。prefix（根から見た今のディレクトリ）を剥がしてから使う。
--- 剥がした残りに `/` が含まれていれば、それは下の階層のファイル。
--- 画面に並ぶのは最初の1階層目のディレクトリなので、そこへまとめる
local function parse(stdout, prefix)
  local map = {}
  for record in vim.gsplit(stdout, '\0', { plain = true }) do
    if #record > 3 then
      local code, staged = pick_status(record:sub(1, 1), record:sub(2, 2))
      local path = record:sub(4)
      if code and SIGN[code] and path:sub(1, #prefix) == prefix then
        local rest = path:sub(#prefix + 1)
        local name = rest:match('^([^/]+)/') or rest
        map[name] = merge(map[name], code, staged)
      end
    end
  end
  return map
end

local function render(bufnr, map)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local oil = require('oil')
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  for lnum = 1, vim.api.nvim_buf_line_count(bufnr) do
    local entry = oil.get_entry_on_line(bufnr, lnum)
    local status = entry and map[entry.name]
    if status then
      vim.api.nvim_buf_set_extmark(bufnr, ns, lnum - 1, 0, {
        sign_text = SIGN[status.code],
        sign_hl_group = hl_for(status.code, status.staged),
      })
    end
  end
end

--- 走り終わる前に別のディレクトリへ移ると、古い結果が新しい画面へ貼られる。
--- バッファごとに最後に投げた世代を覚えておき、古い応答は捨てる
local generation = {}

function M.refresh(bufnr)
  bufnr = bufnr or 0
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= 'oil' then
    return
  end
  -- ssh:// など files 以外のアダプタでは実パスが取れない
  local ok, dir = pcall(require('oil').get_current_dir, bufnr)
  if not ok or not dir then
    return
  end

  local gen = (generation[bufnr] or 0) + 1
  generation[bufnr] = gen

  -- 根からの相対位置と状態を続けて取る。git を2回叩くが、どちらも即返る
  vim.system({ 'git', '-C', dir, 'rev-parse', '--show-prefix' }, { text = true }, function(prefix_out)
    if prefix_out.code ~= 0 then
      -- git の管理下にない。前の画面の記号が残らないよう消す
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(bufnr) and generation[bufnr] == gen then
          vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
        end
      end)
      return
    end
    local prefix = vim.trim(prefix_out.stdout or '')

    -- -z: パスを NUL 区切りで生のまま出す。付けないと非 ASCII や空白を含む名前が
    --     引用符で囲まれて出るため、剥がす処理が要る
    -- --no-renames: 改名を「削除＋追加」に分ける。-z の改名は1レコードに
    --     2つのパスが入り、区切りの数え方が変わるため
    local cmd = {
      'git',
      '-C',
      dir,
      'status',
      '--porcelain=v1',
      '-z',
      '--untracked-files=all',
      '--no-renames',
      '--ignored=no',
    }
    vim.system(cmd, { text = true }, function(status_out)
      if status_out.code ~= 0 then
        return
      end
      local map = parse(status_out.stdout or '', prefix)
      vim.schedule(function()
        if generation[bufnr] == gen then
          render(bufnr, map)
        end
      end)
    end)
  end)
end

--- 開いている oil のバッファを全部貼り直す。
--- ファイルを保存した後にファイラへ戻る動きが多いため、書き込みを合図にする
local function refresh_all()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == 'oil' then
      M.refresh(bufnr)
    end
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup('user_oil_git', { clear = true })

  set_highlights()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = group,
    callback = set_highlights,
  })

  -- oil が描き終わった合図。ディレクトリを移動するたびに飛ぶ
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'OilEnter',
    callback = function(args)
      M.refresh(args.data.buf)
    end,
  })

  -- oil 自身での作成・削除・改名が確定した後
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'OilMutationComplete',
    callback = function()
      refresh_all()
    end,
  })

  -- ファイルを保存した後。oil のバッファは開いたまま残るので、
  -- 戻ってきた時に古い状態が出ていないようにする
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    callback = function()
      vim.schedule(refresh_all)
    end,
  })

  -- ここから下は「nvim の外で git が動いた」場合の取りこぼしを拾う。
  -- git add や commit は nvim の autocmd を何も起こさないため、
  -- ファイラへ戻ってくる動作そのものを合図にする。
  --
  -- ファイラのバッファへ入った時。lazygit のフロートを閉じて戻る場合もここを通る。
  -- oil_ready は oil が描き終わってから立てる印。開いた直後は OilEnter が
  -- 面倒を見るので、まだ描けていない間に走って記号を消さないようにする
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function(args)
      if vim.bo[args.buf].filetype == 'oil' and vim.b[args.buf].oil_ready then
        M.refresh(args.buf)
      end
    end,
  })

  -- 別の端末で git を触ってから nvim の窓へ戻ってきた時
  vim.api.nvim_create_autocmd('FocusGained', {
    group = group,
    callback = refresh_all,
  })

  vim.api.nvim_create_autocmd('BufDelete', {
    group = group,
    callback = function(args)
      generation[args.buf] = nil
    end,
  })
end

return M
