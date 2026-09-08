vim.g.mapleader = " "
vim.g.maplocalleader = ' '
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- This allows for shifting highlighted lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- This improves page scrolling
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- This retains the copy in buffer when replacing a word
vim.keymap.set("x", "<leader>p", "\"_dP")

-- Copy to system buffer (clipboard)
vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>Y", "\"+Y")

-- Delete to void register
vim.keymap.set("n", "<leader>d", "\"_d")
vim.keymap.set("v", "<leader>d", "\"_d")

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- disable direction keys
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- simple remap for window navigation
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- highlight the text that will be yanked
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})


vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('custom-term-open', { clear = true }),
  callback = function()
    vim.opt.number = false
    vim.opt.relativenumber = false

    local win = vim.api.nvim_get_current_win()
    if #vim.api.nvim_tabpage_list_wins(0) > 1 and vim.w[win].dbillings_terminal_layout == nil then
      local width_ratio = vim.api.nvim_win_get_width(win) / vim.o.columns
      local height_ratio = vim.api.nvim_win_get_height(win) / vim.o.lines
      vim.w[win].dbillings_terminal_layout = width_ratio < height_ratio and 'vertical' or 'horizontal'
    end
  end,
})

local function terminal_height()
  return 30
end

local function terminal_width()
  return math.max(20, math.floor(vim.o.columns / 4))
end

local function resize_windows()
  -- Start from a predictable layout, then restore the intentionally smaller
  -- utility panels.
  vim.cmd('wincmd =')

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local terminal_layout = vim.w[win].dbillings_terminal_layout
    if terminal_layout == 'horizontal' then
      pcall(vim.api.nvim_win_set_height, win, terminal_height())
    elseif terminal_layout == 'vertical' then
      pcall(vim.api.nvim_win_set_width, win, terminal_width())
    else
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == 'netrw' and #vim.api.nvim_tabpage_list_wins(0) > 1 then
        pcall(vim.api.nvim_win_set_width, win, terminal_width())
      end
    end
  end

  -- Terminal applications receive their new PTY size asynchronously. Force a
  -- complete redraw after the split dimensions have settled.
  vim.cmd('redraw!')
end

vim.keymap.set('n', '<leader>st', function()
  vim.cmd('belowright split')
  vim.cmd.term()
  local win = vim.api.nvim_get_current_win()
  vim.w[win].dbillings_terminal_layout = 'horizontal'
  vim.cmd('resize 30')
end, { desc = 'Open 30-row bottom terminal' })

vim.keymap.set('n', '<leader>sv', function()
  vim.cmd('rightbelow vnew')
  vim.cmd.term()
  local win = vim.api.nvim_get_current_win()
  vim.w[win].dbillings_terminal_layout = 'vertical'
  vim.api.nvim_win_set_width(win, terminal_width())
end, { desc = 'Open vertical terminal' })

vim.api.nvim_create_autocmd('VimResized', {
  group = vim.api.nvim_create_augroup('dbillings-resize-windows', { clear = true }),
  desc = 'Rebalance splits and redraw terminals after resizing Neovim',
  callback = function()
    vim.schedule(resize_windows)
  end,
})
