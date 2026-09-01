-- ホーム以下を検索する時に飛ばすもの。
--
-- ディレクトリは生成物と外部から取ってきたもの。拡張子は nvim で開いても
-- 意味の無いもの（写真・フォント・書庫・バイナリのデータ）。
-- これを外すと写真とデータだけで4万件を超え、目的のファイルが埋もれる。
local IGNORE_DIRS = {
  '.git',
  '.jj',
  'node_modules',
  '.next',
  'dist',
  'build',
  '.cache',
  '.venv',
  '__pycache__',
  'Library',
  '.Trash',
  '.local/share',
}

local IGNORE_EXTS = {
  -- 画像
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'heic',
  'bmp',
  'tiff',
  'ico',
  'icns',
  -- 動画・音声
  'mp4',
  'mov',
  'avi',
  'mkv',
  'mp3',
  'wav',
  'flac',
  'm4a',
  -- フォント
  'ttf',
  'otf',
  'woff',
  'woff2',
  'eot',
  -- 書庫・配布物
  'zip',
  'gz',
  'bz2',
  'xz',
  'tar',
  'dmg',
  'pkg',
  'app',
  'pdf',
  -- バイナリ・データ
  'dat',
  'toc',
  'journal',
  'thm',
  'plist',
  'sqlite',
  'sqlite3',
  'db',
  'o',
  'so',
  'dylib',
  'a',
  'class',
  'pyc',
  'wasm',
}

--- 拡張子は大文字も弾く。カメラから来たファイルは .JPG や .HEIC のことが多く、
--- fd の --exclude は大文字小文字を区別する
local function ext_globs()
  local globs = {}
  for _, ext in ipairs(IGNORE_EXTS) do
    globs[#globs + 1] = '*.' .. ext
    globs[#globs + 1] = '*.' .. ext:upper()
  end
  return globs
end

local function fd_excludes()
  local args = {}
  for _, dir in ipairs(IGNORE_DIRS) do
    args[#args + 1] = '--exclude ' .. vim.fn.shellescape(dir)
  end
  for _, glob in ipairs(ext_globs()) do
    args[#args + 1] = '--exclude ' .. vim.fn.shellescape(glob)
  end
  return table.concat(args, ' ')
end

local function rg_excludes()
  local args = {}
  for _, dir in ipairs(IGNORE_DIRS) do
    args[#args + 1] = "--glob '!" .. dir .. "/**'"
  end
  for _, glob in ipairs(ext_globs()) do
    args[#args + 1] = "--glob '!" .. glob .. "'"
  end
  return table.concat(args, ' ')
end

local HOME_FD_OPTS = '--color=never --type f --type l ' .. fd_excludes()

local HOME_RG_OPTS = '--column --line-number --no-heading --color=always --smart-case '
  .. '--max-columns=4096 '
  .. rg_excludes()

return {
  'ibhagwan/fzf-lua',
  cmd = 'FzfLua',
  keys = {
    -- ファイル系
    { '<leader>ff', '<cmd>FzfLua files<cr>', desc = '[F]ind [F]ile in this project' },
    { '<leader>fg', '<cmd>FzfLua live_grep<cr>', desc = '[F]ind by [G]rep in this project' },
    { '<leader>fb', '<cmd>FzfLua buffers<cr>', desc = '[F]ind [B]uffer already open / <Space><Space>' },
    { '<leader>fr', '<cmd>FzfLua oldfiles<cr>', desc = '[F]ind [R]ecent across projects' },

    -- kickstart から引き継いだ別名。fb / f/ と同じものを、指が覚えている位置にも置く
    { '<leader><leader>', '<cmd>FzfLua buffers<cr>', desc = 'Find buffers already open / <Space>fb' },
    { '<leader>/', '<cmd>FzfLua blines<cr>', desc = 'Search in this file / <Space>f/' },

    -- 検索の範囲を今いるディレクトリの外へ広げる3つ。
    --
    -- ff / fg は「今いるディレクトリ配下」しか見ない。別のプロジェクトを触りたい
    -- 時は、まず fp で移動先を選ぶ。zoxide はシェルで z を使うたびに訪問先を
    -- 覚えているので、よく行く場所ほど上に出る。
    --
    -- fF / fG はホーム以下を直接なめる。設定ファイルや別プロジェクトを
    -- 「どこにあるか思い出せないまま」探す時用。
    {
      '<leader>fp',
      function()
        local projects = require('config.projects').list()
        -- 表示は ~ を短縮した形。zoxide のスコアは出さない（並び順で意味は足りる）
        local labels = vim.tbl_map(function(path)
          return vim.fn.fnamemodify(path, ':~')
        end, projects)

        require('fzf-lua').fzf_exec(labels, {
          prompt = 'Project❯ ',
          -- 表示は ~ を短縮した形なので、プレビューに渡す前に実体へ戻す
          preview = 'dir=$(printf %s {} | sed "s|^~|$HOME|"); '
            .. 'eza --tree --level=2 --icons=always --color=always "$dir" 2>/dev/null || ls -la "$dir"',
          actions = {
            -- 選んだディレクトリへ移動し、そのままファイル検索へ繋ぐ
            ['default'] = function(selected)
              if not selected or not selected[1] then
                return
              end
              local dir = vim.fn.expand(selected[1])
              vim.cmd.tcd(vim.fn.fnameescape(dir))
              vim.notify('移動しました: ' .. vim.fn.fnamemodify(dir, ':~'))
              -- ファイル一覧ではなくファイラで開く。中身を見ながら辿れるうえ、
              -- バッファとして残るので閉じても ]b や <Space>fb で戻れる
              require('oil').open(dir)
            end,
          },
        })
      end,
      desc = '[F]ind [P]roject : cd and browse',
    },
    {
      '<leader>fF',
      function()
        require('fzf-lua').files({
          cwd = vim.env.HOME,
          prompt = 'Home❯ ',
          fd_opts = HOME_FD_OPTS,
        })
      end,
      desc = '[F]ind [F]ile under home',
    },
    {
      '<leader>fG',
      function()
        require('fzf-lua').live_grep({
          cwd = vim.env.HOME,
          prompt = 'Home❯ ',
          rg_opts = HOME_RG_OPTS,
        })
      end,
      desc = '[F]ind by [G]rep under home',
    },

    -- カーソル下の単語をそのまま検索。調べ物の起点として使用頻度が高い
    { '<leader>fw', '<cmd>FzfLua grep_cword<cr>', desc = '[F]ind [W]ord under cursor in project' },
    { '<leader>fw', '<cmd>FzfLua grep_visual<cr>', mode = 'x', desc = '[F]ind [W]ord from selection in project' },
    -- 現在のバッファ内だけを絞り込む。長いファイルの中を移動する時に速い
    { '<leader>f/', '<cmd>FzfLua blines<cr>', desc = '[F]ind [/] in this file / <Space>/' },
    { '<leader>fd', '<cmd>FzfLua diagnostics_document<cr>', desc = '[F]ind [D]iagnostics in this file' },
    { '<leader>fD', '<cmd>FzfLua diagnostics_workspace<cr>', desc = '[F]ind [D]iagnostics in project' },
    -- 直前の検索結果を条件ごと復元する。閉じてしまった時に打ち直さずに済む
    { '<leader>fR', '<cmd>FzfLua resume<cr>', desc = '[F]ind [R]esume : reopen last picker' },
    -- 設定・ヘルプ系
    { '<leader>fh', '<cmd>FzfLua helptags<cr>', desc = '[F]ind [H]elp tags' },
    {
      '<leader>fs',
      function()
        require('config.snippets').pick()
      end,
      desc = '[F]ind [S]nippet for this filetype',
    },
    { '<leader>fk', '<cmd>FzfLua keymaps<cr>', desc = '[F]ind [K]eymap' },
    { '<leader>fc', '<cmd>FzfLua colorschemes<cr>', desc = '[F]ind [C]olorscheme : preview live' },
    { '<leader>fz', '<cmd>FzfLua<cr>', desc = '[F]ind all fzf-lua pickers' },
    -- Git。変更のあるファイルを一覧にして、選んだものの差分をプレビューに出す。
    -- 左右でステージの出し入れができる。コミットを組み立てるのは lazygit（<leader>gg）
    { '<leader>gc', '<cmd>FzfLua git_status<cr>', desc = '[G]it [C]hanges : files to review' },
  },
  init = function()
    -- シェルの FZF_DEFAULT_OPTS を引き継がせない。
    --
    -- zsh 側で --preview（bat）や --bind を設定しており、fzf-lua がそれを
    -- そのまま受け取っていた。その結果、
    --   - Ctrl+n / Ctrl+p で候補を移動できない（プレビューの送りに潰れていた）
    --   - fzf-lua 自前のプレビューが bat に置き換わる
    -- という状態になっていた。zsh 側の割り当ては後に ctrl-u/d へ移したが、
    -- --preview や --color は依然として渡ってくるので、ここは残す。
    --
    -- 自前のプレビューは treesitter で色分けし、キーマップや LSP の結果など
    -- ファイル以外の候補にも対応している。bat で置き換わるとそれらが壊れる。
    -- 端末で直接 fzf を使う時の設定はそのまま残る
    vim.env.FZF_DEFAULT_OPTS = ''
  end,
  opts = {
    -- ファイル名を先に、パスを後ろに薄く表示する。
    -- Next.js のように page.tsx が大量にある構成では、これが無いと判別できない
    --
    -- fzf-lua は rg を起動する時 RIPGREP_CONFIG_PATH を空にする（fzf.lua:159）。
    -- そのままだと ~/.config/ripgrep/config の --hidden が効かず、dotfiles のように
    -- packages/<tool>/.config/... と隠しディレクトリを含む構成が丸ごと検索から漏れる。
    -- opts の直下に書いても provider には伝わらないため grep の中に置く。
    -- fd は rg の設定を読まないので、files 側は --hidden を直接足す
    files = {
      formatter = 'path.filename_first',
      fd_opts = '--color=never --type f --type l --hidden --exclude .git --exclude .jj',
    },
    grep = {
      formatter = 'path.filename_first',
      RIPGREP_CONFIG_PATH = vim.env.RIPGREP_CONFIG_PATH,
    },
    oldfiles = { formatter = 'path.filename_first', include_current_session = true },
    buffers = { formatter = 'path.filename_first' },
    -- f/ と / のバッファ内検索だけプレビューを畳む。今開いているファイルなので
    -- 候補行の周りは画面にそのまま見えている。
    --
    -- previewer = false ではなく hidden にしているのは、こちらは窓を隠すだけで
    -- <F4> でその場に出せるため（previewer = false はトグルごと殺す）
    blines = { winopts = { preview = { hidden = true } } },
    winopts = {
      height = 0.85,
      width = 0.85,
      preview = { layout = 'flex', scrollbar = 'float' },
    },
    keymap = {
      builtin = {
        ['<C-d>'] = 'preview-page-down',
        ['<C-u>'] = 'preview-page-up',
        ['<C-/>'] = 'toggle-help',
      },
      fzf = {
        ['ctrl-d'] = 'preview-page-down',
        ['ctrl-u'] = 'preview-page-up',
        -- 検索結果をまとめて quickfix に送る
        ['ctrl-q'] = 'select-all+accept',
      },
    },
  },
}
