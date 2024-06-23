return {
  {
    'JoosepAlviste/nvim-ts-context-commentstring',
    config = function()
      local commentstring = require 'ts_context_commentstring'

      commentstring.setup {
        enable_autocmd = false,
      }
    end,
  },
  {
    'numToStr/Comment.nvim',
    config = function()
      local comment = require 'Comment'

      comment.setup {
        pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
      }
    end,
  },
  {
    'folke/todo-comments.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    opts = {},
  },
}
