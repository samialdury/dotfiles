return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    local harpoon = require 'harpoon'

    harpoon:setup {}

    vim.keymap.set('n', '<leader>a', function()
      harpoon:list():add()
    end, { desc = '[A]dd file to Harpoon' })
    vim.keymap.set('n', '<C-e>', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = 'Toggle Harpoon' })
    vim.keymap.set('n', '<M-h>', function()
      harpoon:list():select(1)
    end, { desc = 'Select file 1' })
    vim.keymap.set('n', '<M-j>', function()
      harpoon:list():select(2)
    end, { desc = 'Select file 2' })
    vim.keymap.set('n', '<M-k>', function()
      harpoon:list():select(3)
    end, { desc = 'Select file 3' })
    vim.keymap.set('n', '<M-l>', function()
      harpoon:list():select(4)
    end, { desc = 'Select file 4' })
  end,
}
