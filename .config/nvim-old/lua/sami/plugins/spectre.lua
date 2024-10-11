return {
  'nvim-pack/nvim-spectre',
  config = function(opts)
    local spectre = require 'spectre'

    spectre.setup(opts)

    vim.keymap.set('n', '<leader>S', spectre.toggle, {
      desc = 'Toggle Spectre',
    })
  end,
}
