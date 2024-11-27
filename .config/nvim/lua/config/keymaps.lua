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
  -- harpoon keymaps
  vim.keymap.set("n", "<leader>a", function()
    vscode.action("vscode-harpoon.addEditor")
  end)
  vim.keymap.set("n", "<C-e>", function()
    vscode.action("vscode-harpoon.editEditors")
  end)
  vim.keymap.set("n", "<M-h>", function()
    vscode.action("vscode-harpoon.gotoEditor1")
  end)
  vim.keymap.set("n", "<M-j>", function()
    vscode.action("vscode-harpoon.gotoEditor2")
  end)
  vim.keymap.set("n", "<M-k>", function()
    vscode.action("vscode-harpoon.gotoEditor3")
  end)
  vim.keymap.set("n", "<M-l>", function()
    vscode.action("vscode-harpoon.gotoEditor4")
  end)
end

-- Move Lines
-- vim.keymap.set("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
-- vim.keymap.set("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
-- vim.keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
-- vim.keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
vim.keymap.set("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
vim.keymap.set("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- Override some default keymaps
if not vim.g.vscode then
  vim.keymap.del("n", "<leader>|")
end
vim.keymap.set("n", "<leader>\\", "<C-W>v", { desc = "Split Window Right", remap = true })

-- Move to end of line with alt-l
vim.keymap.set("n", "<S-l>", "$")
-- Move to start of line with alt-h
vim.keymap.set("n", "<S-h>", "^")

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
