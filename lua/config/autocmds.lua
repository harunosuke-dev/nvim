local augroup = function(name)
  return vim.api.nvim_create_augroup('user_' .. name, { clear = true })
end

-- yank した範囲を一瞬ハイライトして、何をコピーしたか目視できるようにする
vim.api.nvim_create_autocmd('TextYankPost', {
  group = augroup('highlight_yank'),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- ファイルを開き直した時に前回のカーソル位置へ戻す
vim.api.nvim_create_autocmd('BufReadPost', {
  group = augroup('last_location'),
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- 巨大ファイルを開いた時に、バッファ全体を走査する処理を止める。
-- 13MB / 12万行の TypeScript で Treesitter の全体パースに 1.4 秒かかる実測があり、
-- 生成物・ログ・巨大 JSON を誤って開いた時にフリーズしたように見えるのを防ぐ。
--
-- 色は失われない。Treesitter の代わりに Vim の正規表現 syntax を使う。
-- こちらは画面に見えている範囲だけを遅延処理するため大きなファイルでも軽い。
-- 補完も buffer / path / snippet のソースは動き続ける（消えるのは LSP 由来のみ）
local BIGFILE_SIZE = 1.5 * 1024 * 1024

vim.api.nvim_create_autocmd('BufReadPre', {
  group = augroup('bigfile'),
  callback = function(args)
    local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(args.buf))
    if not stat or stat.size <= BIGFILE_SIZE then
      return
    end

    -- Treesitter と LSP 側はこのフラグを見て自分から降りる
    vim.b[args.buf].bigfile = true

    vim.opt_local.foldmethod = 'manual' -- Treesitter の foldexpr を評価させない
    vim.opt_local.undofile = false
    vim.opt_local.swapfile = false
    vim.opt_local.list = false

    -- filetype 判定より後に走らせる必要があるため schedule する
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(args.buf) then
        vim.bo[args.buf].syntax = vim.bo[args.buf].filetype
      end
    end)

    vim.notify(
      string.format(
        '巨大ファイル（%.1fMB）のため Treesitter と LSP を無効化しました',
        stat.size / 1024 / 1024
      ),
      vim.log.levels.WARN
    )
  end,
})

-- 保存時に行末の余分な空白を削除する
vim.api.nvim_create_autocmd('BufWritePre', {
  group = augroup('trim_whitespace'),
  callback = function(args)
    -- Markdown 系は行末の半角2スペースが「強制改行」を意味するため対象外にする
    local ft = vim.bo[args.buf].filetype
    if ft == 'markdown' or ft == 'mdx' then
      return
    end
    -- checkhealth の出力など読み取り専用バッファでは置換が E21 で失敗する
    if not vim.bo[args.buf].modifiable then
      return
    end
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})
