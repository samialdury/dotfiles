return {
  {
    "zbirenbaum/copilot.lua",
    opts = {
      filetypes = {
        -- disable for `.env` files
        env = false,
        ["."] = false,
        sh = function()
          if string.match(vim.fs.basename(vim.api.nvim_buf_get_name(0)), "^%.env.*") then
            return false
          end
          return true
        end,
      },
    },
  },
}
