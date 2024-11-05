return {
  {
    "ThePrimeagen/harpoon",
    keys = function()
      local keys = {
        {
          "<leader>a",
          function()
            require("harpoon"):list():add()
            require("notify")("File added", "info", { title = "Harpoon" })
          end,
          desc = "Add file to Harpoon",
        },
        {
          "<C-e>",
          function()
            local harpoon = require("harpoon")
            harpoon.ui:toggle_quick_menu(harpoon:list())
          end,
          desc = "Harpoon Quick Menu",
        },
      }

      local arr = { "h", "j", "k", "l" }

      for i, key in ipairs(arr) do
        table.insert(keys, {
          "<M-" .. key .. ">",
          function()
            require("harpoon"):list():select(i)
          end,
          desc = "Harpoon to File " .. i,
        })
      end
      return keys
    end,
  },
}
