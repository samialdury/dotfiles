return {
  {
    'fatih/vim-go',
    config = function()
      -- we disable most of these features because treesitter and nvim-lsp
      -- take care of it
      vim.g['go_gopls_enabled'] = 0
      vim.g['go_code_completion_enabled'] = 0
      vim.g['go_fmt_autosave'] = 0
      vim.g['go_imports_autosave'] = 0
      vim.g['go_mod_fmt_autosave'] = 0
      vim.g['go_doc_keywordprg_enabled'] = 0
      vim.g['go_def_mapping_enabled'] = 0
      vim.g['go_textobj_enabled'] = 0
      vim.g['go_list_type'] = 'quickfix'
    end,
  },
  -- Alternate between files, such as foo.go and foo_test.go
  {
    'rgroli/other.nvim',
    config = function()
      require('other-nvim').setup {
        mappings = {
          'rails', --builtin mapping
          {
            pattern = '(.*).go$',
            target = '%1_test.go',
            context = 'test',
          },
          {
            pattern = '(.*)_test.go$',
            target = '%1.go',
            context = 'file',
          },
        },
      }

      vim.api.nvim_create_user_command('A', function(opts)
        require('other-nvim').open(opts.fargs[1])
      end, { nargs = '*' })

      vim.api.nvim_create_user_command('AV', function(opts)
        require('other-nvim').openVSplit(opts.fargs[1])
      end, { nargs = '*' })

      vim.api.nvim_create_user_command('AS', function(opts)
        require('other-nvim').openSplit(opts.fargs[1])
      end, { nargs = '*' })
    end,
  },
}
