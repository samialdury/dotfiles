return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      local catppuccin = require 'catppuccin'

      catppuccin.setup {
        flavour = 'auto', -- latte, frappe, macchiato, mocha
        background = { -- :h background
          light = 'latte',
          dark = 'mocha',
        },
        term_colors = true,
        styles = {
          conditionals = {},
          functions = { 'italic' },
          types = { 'bold' },
        },
        integrations = {
          barbar = true,
          cmp = true,
          gitsigns = true,
          mini = true,
          mason = true,
          markdown = true,
          nvimtree = true,
          telescope = true,
          treesitter = true,
          which_key = true,
        },
      }

      vim.cmd.colorscheme 'catppuccin'
      vim.opt.background = 'dark'
    end,
  },
  {
    'folke/twilight.nvim',
    opts = {},
  },
  {
    'folke/zen-mode.nvim',
    cmd = 'ZenMode',
    opts = {
      plugins = {
        gitsigns = true,
        tmux = true,
        alacritty = {
          enabled = false,
        },
      },
    },
    keys = { { '<leader>z', '<cmd>ZenMode<cr>', desc = 'Zen Mode' } },
  },
}
