local M = {}

local cached_config

function M.get()
  if cached_config then
    return cached_config
  end

  local config = {}
  local domain_dir = vim.fn.stdpath('config') .. '/lua/dbillings/domains'
  local files = vim.fn.glob(domain_dir .. '/*.lua', false, true)
  table.sort(files)

  for _, path in ipairs(files) do
    local ok, domain_config = pcall(dofile, path)
    if not ok then
      error(('Failed to load domain config %s: %s'):format(path, domain_config))
    end
    if type(domain_config) ~= 'table' then
      error(('Domain config %s must return a table'):format(path))
    end
    config = vim.tbl_deep_extend('force', config, domain_config)
  end

  cached_config = config
  return cached_config
end

return M
