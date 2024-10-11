-- https://github.com/hrsh7th/nvim-cmp
return {
  'hrsh7th/nvim-cmp',
  event = 'InsertEnter',
  dependencies = {
    {
      'L3MON4D3/LuaSnip',
      build = 'make install_jsregexp',
      dependencies = {
        -- `friendly-snippets` contains a variety of premade snippets.
        --    See the README about individual language/framework/plugin snippets:
        --    https://github.com/rafamadriz/friendly-snippets
        {
          'rafamadriz/friendly-snippets',
          config = function()
            require('luasnip.loaders.from_vscode').lazy_load()
          end,
        },
      },
    },
    'onsails/lspkind-nvim', -- lspkind (VS pictograms)
    'saadparwaiz1/cmp_luasnip',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-path',
    { 'roobert/tailwindcss-colorizer-cmp.nvim', config = true },
  },
  config = function()
    local luasnip = require 'luasnip'
    local types = require 'luasnip.util.types'

    -- Display virtual text to indicate snippet has more nodes
    luasnip.config.setup {
      ext_opts = {
        [types.choiceNode] = {
          active = { virt_text = { { '⇥', 'GruvboxRed' } } },
        },
        [types.insertNode] = {
          active = { virt_text = { { '⇥', 'GruvboxBlue' } } },
        },
      },
    }

    local cmp = require 'cmp'
    local lspkind = require 'lspkind'
    local tailwindcss_colorizer = require 'tailwindcss-colorizer-cmp'

    cmp.setup {
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      completion = { completeopt = 'menu,menuone,noinsert' },
      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },
      mapping = cmp.mapping.preset.insert {
        -- Select the [n]ext item
        ['<C-n>'] = cmp.mapping.select_next_item(),
        -- Select the [p]revious item
        ['<C-p>'] = cmp.mapping.select_prev_item(),

        -- Scroll the documentation window [b]ack / [f]orward
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),

        -- If you prefer more traditional completion keymaps,
        -- you can uncomment the following lines
        --['<CR>'] = cmp.mapping.confirm { select = true },
        --['<Tab>'] = cmp.mapping.select_next_item(),
        --['<S-Tab>'] = cmp.mapping.select_prev_item(),

        -- Accept ([y]es) the completion.
        --  This will auto-import if your LSP supports it.
        --  This will expand snippets if the LSP sent a snippet.
        ['<C-y>'] = cmp.mapping.confirm { select = true },
        ['<CR>'] = cmp.mapping.confirm { select = true },

        -- Manually trigger a completion from nvim-cmp.
        --  Generally you don't need this, because nvim-cmp will display
        --  completions whenever it has completion options available.
        ['<M-Space>'] = cmp.mapping.complete(),

        --
        ['<Tab>'] = cmp.mapping(function(fallback)
          --   if require('copilot.suggestion').is_visible() then
          --     require('copilot.suggestion').accept()
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.locally_jumpable(1) then
            luasnip.jump(1)
          else
            fallback()
          end
        end, { 'i', 's' }),
      },
      sources = {
        {
          name = 'lazydev',
          -- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
          group_index = 0,
        },
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'path' },
      },
      formatting = {
        format = function(entry, vim_item)
          tailwindcss_colorizer.formatter(entry, vim_item)

          return lspkind.cmp_format {
            mode = 'symbol_text',
            maxwidth = 70,
            show_labelDetails = true,
          }(entry, vim_item)
        end,
      },
    }
  end,
}
