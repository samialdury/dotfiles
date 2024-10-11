return {
  'iamcco/markdown-preview.nvim',
  ft = 'markdown',
  cmd = { 'MarkdownPreview' },
  dependencies = {
    'zhaozg/vim-diagram',
    'aklt/plantuml-syntax',
  },
  build = function()
    vim.fn['mkdp#util#install']()
  end,
}
