-- リーダーキーは何よりも先に定義する
-- （プラグイン読み込み後に定義すると、既に登録済みのマップが古い値のままになる）
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('config.options')
require('config.filetype')
require('config.keymaps')
require('config.autocmds')
require('config.commands')
require('config.snippets').setup()
require('config.lazy')
