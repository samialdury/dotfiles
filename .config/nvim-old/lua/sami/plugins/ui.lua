return {
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    enabled = false,
    config = function()
      require('tokyonight').setup {
        style = 'moon',
        -- Borderless Telescope
        on_highlights = function(hl, c)
          local prompt = '#2d3149'
          hl.TelescopeNormal = {
            bg = c.bg_dark,
            fg = c.fg_dark,
          }
          hl.TelescopeBorder = {
            bg = c.bg_dark,
            fg = c.bg_dark,
          }
          hl.TelescopePromptNormal = {
            bg = prompt,
          }
          hl.TelescopePromptBorder = {
            bg = prompt,
            fg = prompt,
          }
          hl.TelescopePromptTitle = {
            bg = prompt,
            fg = prompt,
          }
          hl.TelescopePreviewTitle = {
            bg = c.bg_dark,
            fg = c.bg_dark,
          }
          hl.TelescopeResultsTitle = {
            bg = c.bg_dark,
            fg = c.bg_dark,
          }
        end,
      }

      vim.opt.background = 'dark'
      vim.cmd.colorscheme 'tokyonight'
    end,
  },
  {
    'catppuccin/nvim',
    lazy = false,
    name = 'catppuccin',
    priority = 999,
    enabled = true,
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
          indent_blankline = { enabled = true },
          mini = true,
          mason = true,
          markdown = true,
          nvimtree = true,
          telescope = true,
          treesitter = true,
          which_key = true,
        },
      }

      vim.opt.background = 'dark'
      vim.cmd.colorscheme 'catppuccin'
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
