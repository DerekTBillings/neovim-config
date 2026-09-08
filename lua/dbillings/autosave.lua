local autosave_group = vim.api.nvim_create_augroup('dbillings-autosave', { clear = true })

local function save_file_buffer(event)
  local bufnr = event.buf
  local buffer = vim.bo[bufnr]

  if not buffer.modified
    or not buffer.modifiable
    or buffer.readonly
    or buffer.buftype ~= ''
    or vim.api.nvim_buf_get_name(bufnr) == ''
  then
    return
  end

  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd('silent update')
  end)
end

vim.api.nvim_create_autocmd({ 'BufLeave', 'FocusLost' }, {
  group = autosave_group,
  callback = save_file_buffer,
  desc = 'Save modified file buffers when leaving them or Neovim loses focus',
})
