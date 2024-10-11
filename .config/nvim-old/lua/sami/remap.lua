-- Set leader to <Space>
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Move to end of line with shift-l
vim.keymap.set('n', '<S-l>', '$')
-- Move to start of line with shift-h
vim.keymap.set('n', '<S-h>', '^')
-- Jump down half a page with shift-j
-- vim.keymap.set('n', '<S-j>', '<C-d>')
-- Jump up half a page with shift-k
-- vim.keymap.set('n', '<S-k>', '<C-u>')

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Fast saving and quitting
vim.keymap.set('n', '<Leader>W', ':write!<CR>', { desc = 'Save' })
vim.keymap.set('n', '<Leader>Q', ':q!<CR>', { desc = 'Quit' })

-- Clear search highlights
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- A function to move selected lines down in visual mode
function Move_lines_down_visual()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local last_line = vim.api.nvim_buf_line_count(0)

  local selected_lines_count = vim.fn.line "'>" - vim.fn.line "'<"

  if current_line + selected_lines_count < last_line then
    vim.api.nvim_command "'<, '>m '>+1"
    vim.api.nvim_command 'normal! gv=gv'
  -- When we hit the bottom we just reselect the lines
  else
    vim.api.nvim_command 'normal! gv'
  end
end

-- A function to move selected lines up in visual mode
function Move_lines_up_visual()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]

  if current_line > 1 then
    vim.api.nvim_command "'<, '>m '<-2"
    vim.api.nvim_command 'normal! gv=gv'
  -- When we hit the top we just reselect the lines
  else
    vim.api.nvim_command 'normal! gv'
  end
end

-- Move selected line / block of text in visual mode up and down
-- vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
-- vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set('v', 'J', ':lua Move_lines_down_visual()<CR>')
vim.keymap.set('v', 'K', ':lua Move_lines_up_visual()<CR>')

-- Cursor should stay in place when joining lines
vim.keymap.set('n', 'J', 'mzJ`z')

-- Keep the cursor in the middle when scrolling
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')

-- These will make it so that going to the next one in a
-- search will center on the line it's found in.
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- If I visually select words and paste from clipboard, don't replace my
-- clipboard with the selected word, instead keep my old word in the
-- clipboard
-- vim.keymap.set('x', 'p', '"_dP')
vim.keymap.set('x', '<leader>p', [["_dP]])

-- Yank to system clipboard
vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]], {
  desc = '[Y]ank to system clipboard',
})
vim.keymap.set('n', '<leader>Y', [["+Y]], {
  desc = '[Y]ank line to system clipboard',
})

-- Delete without yanking
vim.keymap.set({ 'n', 'v' }, '<leader>d', [["_d]])

-- If I do a ctrl-v and select lines vertically,
-- insert stuff, they get lost for all lines if we use
-- ctrl-c, but not if we use ESC. So just let's assume Ctrl-c is ESC.
vim.keymap.set('i', '<C-c>', '<Esc>')

vim.keymap.set('n', 'Q', '<nop>')

-- Don't jump forward if I higlight and search for a word
local function stay_star()
  local sview = vim.fn.winsaveview()
  local args = string.format('keepjumps keeppatterns execute %q', 'sil normal! *')
  vim.api.nvim_command(args)
  vim.fn.winrestview(sview)
end
vim.keymap.set('n', '*', stay_star, { noremap = true })
-- vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

-- conform takes care of the formatting, see lua/sami/plugins/format.lua
-- vim.keymap.set('n', '<leader>f', vim.lsp.buf.format)

-- Quickfix and location list navigation
vim.keymap.set('n', '<C-k>', '<cmd>cnext<CR>zz')
vim.keymap.set('n', '<C-j>', '<cmd>cprev<CR>zz')
vim.keymap.set('n', '<leader>k', '<cmd>lnext<CR>zz')
vim.keymap.set('n', '<leader>j', '<cmd>lprev<CR>zz')

-- Split window
vim.keymap.set('n', 'ss', ':split<Return>')
vim.keymap.set('n', 'sv', ':vsplit<Return>')

-- Stay in indent mode
vim.keymap.set('v', '<', '<gv', { noremap = true, silent = true })
vim.keymap.set('v', '>', '>gv', { noremap = true, silent = true })

-- Resize with arrows
vim.keymap.set('n', '<C-Down>', '<C-w>-')
vim.keymap.set('n', '<C-Up>', '<C-w>+')
vim.keymap.set('n', '<C-Left>', '<C-w>5<')
vim.keymap.set('n', '<C-Right>', '<C-w>5>')

vim.keymap.set('n', '<leader>rr', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], {
  desc = 'Replace the word under the cursor',
})

-- Make the current file executable
-- vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })
