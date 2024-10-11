-- https://github.com/rhysd/vim-clang-format
return {
  'rhysd/vim-clang-format',
  init = function()
    vim.cmd [[
autocmd FileType proto ClangFormatAutoEnable
]]
  end,
}
