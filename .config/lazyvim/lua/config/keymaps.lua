-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Disable arrow keys in normal mode
vim.keymap.set("n", "<left>", '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set("n", "<right>", '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set("n", "<up>", '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set("n", "<down>", '<cmd>echo "Use j to move!!"<CR>')

-- Yank to system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], {
  desc = "[Y]ank to system clipboard",
})
vim.keymap.set("n", "<leader>Y", [["+Y]], {
  desc = "[Y]ank line to system clipboard",
})

-- Delete without yanking
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])
