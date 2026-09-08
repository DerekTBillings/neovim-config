local parsers = {
  'bash',
  'c',
  'diff',
  'go',
  'gomod',
  'gosum',
  'gotmpl',
  'gowork',
  'html',
  'javascript',
  'json',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'proto',
  'python',
  'query',
  'rust',
  'sql',
  'toml',
  'tsx',
  'typescript',
  'vim',
  'vimdoc',
  'yaml',
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      local treesitter = require('nvim-treesitter')
      treesitter.setup {}
      treesitter.install(parsers)

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('dbillings-treesitter', { clear = true }),
        callback = function(event)
          pcall(vim.treesitter.start, event.buf)
        end,
      })
    end,
  },
}
