return {
  'nvim-tree/nvim-tree.lua',
  version = '*',
  lazy = false,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require('nvim-tree').setup {
      disable_netrw = false,
      filters = {
        custom = { '.git', 'node_modules', '.vscode' },
        dotfiles = true,
      },
      git = {
        -- ignore = true
      },
      view = {
        adaptive_size = true,
        float = {
          enable = true,
        },
      },
    }

    vim.keymap.set('n', 'ú', ':NvimTreeToggle<CR>', { noremap = true })
    vim.keymap.set('n', 'ů', ':NvimTreeFindFile<CR>', { noremap = true })
  end,
}
