-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.clipboard = "" -- Keep vim and system clipboard separate

-- PHP
-- use `intelephense` instead of `phpactor`
vim.g.lazyvim_php_lsp = "intelephense"

-- Prettier
-- only run `prettier` if there is a config file
vim.g.lazyvim_prettier_needs_config = true
