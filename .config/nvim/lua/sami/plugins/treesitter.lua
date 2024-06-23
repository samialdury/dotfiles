-- Highlight, edit, and navigate code
return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
    'nvim-treesitter/nvim-treesitter-refactor',
  },
  opts = {
    ensure_installed = {
      'bash',
      'c',
      'diff',
      'fish',
      'csv',
      'css',
      'dockerfile',
      'gitignore',
      'go',
      'gomod',
      'gosum',
      'gowork',
      'html',
      'javascript',
      'typescript',
      'tsx',
      'json',
      'lua',
      'luadoc',
      'vim',
      'vimdoc',
      'markdown',
      'markdown_inline',
      'make',
      'proto',
      'sql',
      'yaml',
    },
    auto_install = true,
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
      -- Disable slow highlight for large files
      disable = function(_, buf)
        local max_filesize = 100 * 1024 -- 100 KB
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > max_filesize then
          return true
        end
      end,
    },
    refactor = {
      highlight_definitions = { enable = true },
      highlight_current_scope = { enable = false },
      smart_rename = {
        enable = true,
        keymaps = {
          smart_rename = 'rs',
        },
      },
    },
    autopairs = {
      enable = true,
    },
    indent = { enable = true, disable = { 'ruby' } },
    -- incremental_selection = {
    --   enable = true,
    --   keymaps = {
    --     init_selection = '<space>', -- maps in normal mode to init the node/scope selection with space
    --     node_incremental = '<space>', -- increment to the upper named parent
    --     node_decremental = '<bs>', -- decrement to the previous node
    --     scope_incremental = '<tab>', -- increment to the upper scope (as defined in locals.scm)
    --   },
    -- },
    textobjects = {
      select = {
        enable = true,
        lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
        keymaps = {
          -- You can use the capture groups defined in textobjects.scm
          ['aa'] = {
            query = '@parameter.outer',
            desc = 'Around function parameter',
          },
          ['ia'] = {
            query = '@parameter.inner',
            desc = 'Inside function parameter',
          },
          ['af'] = {
            query = '@function.outer',
            desc = 'Around function',
          },
          ['if'] = {
            query = '@function.inner',
            desc = 'Inside function',
          },
          ['ac'] = {
            query = '@class.outer',
            desc = 'Around class',
          },
          ['ic'] = {
            query = '@class.inner',
            desc = 'Inside class',
          },
          ['iB'] = {
            query = '@block.inner',
            desc = 'Inside block',
          },
          ['aB'] = {
            query = '@block.outer',
            desc = 'Around block',
          },
        },
      },
      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          [']]'] = {
            query = '@function.outer',
            desc = 'Next function start',
          },
        },
        goto_next_end = {
          [']['] = {
            query = '@function.outer',
            desc = 'Next function end',
          },
        },
        goto_previous_start = {
          ['[['] = {
            query = '@function.outer',
            desc = 'Previous function start',
          },
        },
        goto_previous_end = {
          ['[]'] = {
            query = '@function.outer',
            desc = 'Previous function end',
          },
        },
      },
      swap = {
        enable = true,
        swap_next = {
          ['<leader>sn'] = {
            query = '@parameter.inner',
            desc = 'Swap with next parameter',
          },
        },
        swap_previous = {
          ['<leader>sp'] = {
            query = '@parameter.inner',
            desc = 'Swap with previous parameter',
          },
        },
      },
    },
  },
  config = function(_, opts)
    local treesitter = require 'nvim-treesitter.configs'

    -- Prefer git instead of curl in order to improve connectivity in some environments
    require('nvim-treesitter.install').prefer_git = true

    treesitter.setup(opts)
  end,
}
