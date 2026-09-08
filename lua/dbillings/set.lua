vim.g.mapleader = " "
vim.o.cursorline = true

vim.opt.nu = true
vim.opt.relativenumber = true

-- `number` and `relativenumber` are window-local. Terminal windows turn them
-- off, so re-enable them whenever that window is later used for a normal file
-- (including after restoring a session).
local line_numbers_group = vim.api.nvim_create_augroup('dbillings-line-numbers', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter', 'SessionLoadPost' }, {
    group = line_numbers_group,
    desc = 'Keep relative line numbers enabled in file windows',
    callback = function()
        if vim.bo.buftype == '' then
            vim.wo.number = true
            vim.wo.relativenumber = true
        end
    end,
})

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.o.breakindent = true
vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
local undo_dir = vim.fn.stdpath('state') .. '/undo'
vim.fn.mkdir(undo_dir, 'p')
vim.opt.undodir = undo_dir
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.o.inccommand = "split"

vim.opt.termguicolors = true

vim.opt.scrolloff = 8

vim.opt.updatetime = 250
-- Give multi-key leader mappings enough time to complete. With a very short
-- timeout, a partially entered `<leader>sg` falls through to Vim's `s`
-- command and starts editing the buffer instead of opening Telescope.
vim.o.timeoutlen = 2000

vim.opt.colorcolumn = "80"

vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.signcolumn = "yes"

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.confirm = true
vim.o.autowriteall = true
