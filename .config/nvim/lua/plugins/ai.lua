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
  {
    "zbirenbaum/copilot-cmp",
    opts = function()
      local copilot_toggle = require("lazyvim.util.toggle").wrap({
        name = "Copilot Completion",
        get = function()
          return not require("copilot.client").is_disabled()
        end,
        set = function(state)
          if state then
            require("copilot.command").enable()
          else
            require("copilot.command").disable()
          end
        end,
      })

      LazyVim.toggle.map("<leader>ct", copilot_toggle)
    end,
  },
}
