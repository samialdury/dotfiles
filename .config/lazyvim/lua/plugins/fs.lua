return {
  {
    "stevearc/oil.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local oil = require("oil")

      oil.setup({
        default_file_explorer = true,
        delete_to_trash = true,
        skip_confirm_for_simple_edits = true,
        view_options = {
          show_hidden = true,
          is_always_hidden = function(name)
            return name == ".." or name == ".git"
          end,
        },
      })

      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
      -- vim.keymap.set("n", "<leader>-", oil.toggle_float, { desc = "Toggle oil float" })
    end,
  },
}
