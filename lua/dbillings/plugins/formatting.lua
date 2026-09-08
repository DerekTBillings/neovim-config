return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = { 'n', 'v' },
        desc = 'Format buffer',
      },
    },
    opts = {
      notify_on_error = true,
      formatters_by_ft = {
        bzl = { 'buildifier' },
        go = { 'gofmt' },
        javascript = { 'prettier' },
        javascriptreact = { 'prettier' },
        python = { 'ruff_format' },
        typescript = { 'prettier' },
        typescriptreact = { 'prettier' },
      },
      format_on_save = function(bufnr)
        local enabled = {
          bzl = true,
          go = true,
          javascript = true,
          javascriptreact = true,
          python = true,
          typescript = true,
          typescriptreact = true,
        }
        if not enabled[vim.bo[bufnr].filetype] then
          return
        end
        return { timeout_ms = 3000, lsp_format = 'never' }
      end,
    },
  },
}
