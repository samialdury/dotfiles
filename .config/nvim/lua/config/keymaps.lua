-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

if vim.g.vscode then
  local vscode = require("vscode")
  vim.keymap.set("n", "<leader>ff", function()
    vscode.action("find-it-faster.findFiles")
  end)
  vim.keymap.set("n", "<leader>/", function()
    vscode.action("find-it-faster.findWithinFiles")
  end)
  vim.keymap.set("n", "<leader>ca", function()
    vscode.action("editor.action.sourceAction")
  end)
end

-- Override some default keymaps
vim.keymap.del("n", "<leader>|")
vim.keymap.set("n", "<leader>\\", "<C-W>v", { desc = "Split Window Right", remap = true })

-- Move to end of line with alt-l
vim.keymap.set("n", "<A-l>", "$")
-- Move to start of line with alt-h
vim.keymap.set("n", "<A-h>", "^")

-- Keep the cursor in the middle when scrolling
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

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
