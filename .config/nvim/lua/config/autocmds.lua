-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Go
local goAuGroup = vim.api.nvim_create_augroup("goFileType", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  group = goAuGroup,
  callback = function()
    vim.opt_local.list = false
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4

    vim.keymap.set("n", "<leader>E", "oif err != nil {<CR>}<Esc>Oreturn err<Esc>", {
      desc = "Insert error handling",
      buffer = 0,
    })
  end,
})
