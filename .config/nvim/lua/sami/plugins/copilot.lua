return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  build = ':Copilot auth',
  lazy = true,
  event = 'InsertEnter',
  config = function()
    local copilot = require 'copilot'

    copilot.setup {
      panel = {
        enabled = true,
        auto_refresh = false,
        keymap = {
          jump_prev = '[[',
          jump_next = ']]',
          accept = '<CR>',
          refresh = 'gr',
          open = '<M-CR>',
        },
        layout = {
          position = 'bottom', -- | top | left | right
          ratio = 0.4,
        },
      },
      suggestion = {
        enabled = true,
        auto_trigger = true, -- This
        debounce = 75,
        keymap = {
          accept = '<C-a>',
          accept_word = false,
          accept_line = false,
          next = '<M-]>',
          prev = '<M-[>',
          dismiss = '<C-]>',
        },
      },
      filetypes = {
        go = true,
        yaml = true,
        markdown = true,
        help = false,
        gitcommit = false,
        gitrebase = false,
        hgcommit = false,
        svn = false,
        cvs = false,
        ['.'] = false,
        ['*'] = true,
      },
      copilot_node_command = 'node', -- Node.js version must be > 18.x
      server_opts_overrides = {},
    }

    vim.keymap.set('n', '<Leader>cd', '<Cmd>Copilot disable<CR>', {
      noremap = true,
      desc = 'Disable Copilot',
    })
    vim.keymap.set('n', '<Leader>ce', '<Cmd>Copilot enable<CR>', {
      noremap = true,
      desc = 'Enable Copilot',
    })
  end,
}
