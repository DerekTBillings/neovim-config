local function current_file_path()
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' then
    error('Current buffer has no file path')
  end

  return vim.fs.normalize(file)
end

local function relative_file_path()
  local file = current_file_path()
  local root = vim.fs.root(file, '.git') or vim.fn.getcwd()
  return vim.fs.relpath(root, file)
end

local function copy_path(path)
  vim.fn.setreg('+', path)
  vim.notify(('Copied path: %s'):format(path))
end

vim.api.nvim_create_user_command('CopyPath', function()
  copy_path(relative_file_path())
end, { desc = 'Copy the current file path relative to the repository root', force = true })

vim.api.nvim_create_user_command('CopyPathParent', function()
  copy_path(vim.fs.dirname(relative_file_path()))
end, { desc = 'Copy the current file parent path relative to the repository root', force = true })

vim.api.nvim_create_user_command('CopyPathGrandParent', function()
  local parent = vim.fs.dirname(relative_file_path())
  copy_path(vim.fs.dirname(parent))
end, { desc = 'Copy the current file grandparent path relative to the repository root', force = true })

vim.api.nvim_create_user_command('CopyPathFull', function()
  copy_path(current_file_path())
end, { desc = 'Copy the current file absolute path', force = true })

local function is_primary_window(win)
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.bo[buf].buftype == '' and vim.bo[buf].filetype ~= 'netrw'
end

local function find_primary_window()
  local current = vim.api.nvim_get_current_win()
  if is_primary_window(current) then
    return current
  end

  local fallback
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if is_primary_window(win) then
      return win
    end
    if not fallback and vim.bo[buf].buftype == '' then
      fallback = win
    end
  end

  if fallback then
    return fallback
  end
  error('InitialSetup: could not find a normal file or directory window')
end

local function initial_setup()
  if vim.fn.executable('tmux') ~= 1 then
    error('InitialSetup: tmux is not executable')
  end

  local primary_win = find_primary_window()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= primary_win then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].modified then
        error('InitialSetup: save changes in ' .. vim.api.nvim_buf_get_name(buf) .. ' before rebuilding the layout')
      end
    end
  end

  vim.api.nvim_set_current_win(primary_win)
  vim.cmd('only')

  vim.cmd('rightbelow vnew')
  local agent_win = vim.api.nvim_get_current_win()

  vim.cmd('belowright new')
  local git_win = vim.api.nvim_get_current_win()
  vim.cmd.term()
  vim.w[git_win].dbillings_terminal_layout = 'horizontal'
  vim.w[git_win].dbillings_terminal_height = 10
  vim.api.nvim_win_set_height(git_win, 10)

  vim.api.nvim_set_current_win(agent_win)
  vim.cmd('terminal tmux new -A -s nvim_agent')
  -- Keep the workspace column at the normal split width. The lower terminal
  -- owns the shared column's explicit height.
  vim.w[agent_win].dbillings_terminal_layout = 'workspace'

  vim.api.nvim_set_current_win(primary_win)
end

local initial_setup_group = vim.api.nvim_create_augroup('dbillings-initial-setup', { clear = true })
vim.api.nvim_create_user_command('InitialSetup', function()
  if vim.v.vim_did_enter == 1 then
    initial_setup()
    return
  end

  -- AutoSession restores on VimEnter. Register this during startup and defer
  -- once more so the saved code buffer and cursor position are restored first.
  vim.api.nvim_create_autocmd('VimEnter', {
    group = initial_setup_group,
    once = true,
    callback = function()
      vim.schedule(function()
        local ok, err = pcall(initial_setup)
        if not ok then
          vim.notify(err, vim.log.levels.ERROR)
        end
      end)
    end,
  })
end, { desc = 'Create the code, Codex, and git terminal workspace', force = true })

-- User commands must start with an uppercase letter and cannot contain
-- hyphens. Command-line mappings provide the requested spellings.
local function command_alias(alias, command)
  vim.keymap.set('c', alias, function()
    if vim.fn.getcmdtype() == ':' and vim.fn.getcmdline() == '' then
      return command
    end
    return alias
  end, { expr = true, desc = ('Alias :%s to :%s'):format(alias, command) })
end

command_alias('copy-path', 'CopyPath')
command_alias('copy-path-parent', 'CopyPathParent')
command_alias('copy-path-grand-parent', 'CopyPathGrandParent')
command_alias('copy-path-full', 'CopyPathFull')
command_alias('vr', 'vertical resize')

-- Remove the previous names when this file is reloaded in a running session.
pcall(vim.api.nvim_del_user_command, 'CopyParentPath')
pcall(vim.keymap.del, 'c', 'copy-parent-path')
