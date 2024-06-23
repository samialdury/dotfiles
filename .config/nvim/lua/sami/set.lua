-- See `:help vim.opt`

-- Disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- vim.opt.guicursor = ""

-- Show line numbers
vim.opt.number = true
-- Enable relative line numbers
vim.opt.relativenumber = true
-- Enable mouse support
vim.opt.mouse = 'a'
-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false
-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
-- vim.opt.clipboard = 'unnamedplus'
-- Enable break indent
vim.opt.breakindent = true
-- Save undo history
vim.opt.undofile = true
-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true
-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'
-- Decrease update time
vim.opt.updatetime = 250
-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300
-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true
-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'
-- Show which line your cursor is on
vim.opt.cursorline = true
-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10
-- expand tabs into spaces
vim.opt.expandtab = true
-- number of spaces to use for each step of indent.
vim.opt.shiftwidth = 4
-- number of spaces a TAB counts for
vim.opt.tabstop = 4
-- number of spaces to use for each step of indent.
vim.opt.softtabstop = 4
-- copy indent from current line when starting a new line
vim.opt.autoindent = true
vim.opt.smartindent = true
-- don't wrap lines
vim.opt.wrap = false
-- Enable 24-bit RGB colors
vim.opt.termguicolors = true
-- Enable spell checking
vim.opt.spell = true
vim.opt.spelllang = 'en_us'
-- Set the color column to 120 characters
vim.opt.colorcolumn = '120'
-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
-- Incremental search
vim.opt.incsearch = true
-- Show matching brackets when text indicator is over them
vim.opt.showmatch = true

vim.opt.isfname:append '@-@'
vim.opt.wildignore:append { '*/node_modules/*' }

-- make all keymaps silent by default
local keymap_set = vim.keymap.set
---@diagnostic disable-next-line: duplicate-set-field
vim.keymap.set = function(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  return keymap_set(mode, lhs, rhs, opts)
end
