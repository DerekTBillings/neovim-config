
-- require('lazy').setup({
  --'NMAC427/guess-indent.nvim', -- Detect tabstop and shiftwidth automatically
return {
  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      local domain_telescope = require('dbillings.domain').get().telescope or {}
      local ignored_globs = {
        '!*.pb.go',
        '!*.pyi',
        '!*stubs.py',
      }
      vim.list_extend(ignored_globs, domain_telescope.ignored_globs or {})
      local function glob_arguments(globs)
        local arguments = {}
        for _, glob in ipairs(globs) do
          vim.list_extend(arguments, { '--glob', glob })
        end
        return arguments
      end

      local vimgrep_arguments = vim.deepcopy(require('telescope.config').values.vimgrep_arguments)
      vim.list_extend(vimgrep_arguments, glob_arguments(ignored_globs))

      require('telescope').setup {
        defaults = {
          -- Exclude generated sources from ripgrep searches without hiding
          -- them from LSP pickers such as go-to-definition.
          vimgrep_arguments = vimgrep_arguments,
        },
        pickers = {
          find_files = {
            find_command = vim.list_extend({ 'rg', '--files', '--color', 'never' },
              glob_arguments(ignored_globs)),
          },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      local function buffer_dir()
        local path = vim.api.nvim_buf_get_name(0)
        return path ~= '' and vim.fs.dirname(path) or vim.fn.getcwd()
      end

      local function package_root()
        local marker = vim.fs.find({ 'BUILD.in', 'BUILD.bazel', 'BUILD' }, {
          path = buffer_dir(),
          upward = true,
        })[1]
        return marker and vim.fs.dirname(marker) or buffer_dir()
      end

      local function repo_root()
        return vim.fs.root(buffer_dir(), '.git') or vim.fn.getcwd()
      end

      local type_searches = {
        go = { label = 'Go', globs = { '*.go' } },
        py = {
          label = 'Python',
          globs = { '*.py' },
          grep_ignored_globs = { '!*.pb2.py' },
        },
        pr = { label = 'Proto', globs = { '*.proto' } },
        ts = { label = 'TypeScript', globs = { '*.ts', '*.tsx' } },
        js = { label = 'JavaScript', globs = { '*.js' } },
        te = { label = 'test', globs = { '**/*test*' }, tests_only = true },
      }

      local type_aliases = {
        python = 'py',
        proto = 'pr',
        protobuf = 'pr',
        tsx = 'ts',
        typescript = 'ts',
        javascript = 'js',
        test = 'te',
        tests = 'te',
      }

      local command_type_names = { 'go', 'py', 'proto', 'ts', 'js', 'test' }

      local function resolve_type_search(argument)
        local search_type = vim.trim(argument):lower():gsub('^%.', '')
        search_type = type_aliases[search_type] or search_type
        local search = type_searches[search_type]
        if search then
          return search
        end

        vim.notify(
          ('Unknown search type %q. Use one of: %s'):format(argument, table.concat(command_type_names, ', ')),
          vim.log.levels.ERROR
        )
      end

      local function complete_search_type(argument_lead)
        local prefix = argument_lead:lower()
        return vim.tbl_filter(function(search_type)
          return vim.startswith(search_type, prefix)
        end, command_type_names)
      end

      local function search_globs(search)
        local globs = vim.deepcopy(search.globs)
        if not search.tests_only then
          table.insert(globs, '!**/*test*')
        end
        return globs
      end

      local function find_files_by_type(search)
        local find_command = { 'rg', '--files', '--color', 'never' }
        vim.list_extend(find_command, glob_arguments(ignored_globs))
        vim.list_extend(find_command, glob_arguments(search_globs(search)))
        builtin.find_files {
          cwd = repo_root(),
          find_command = find_command,
          prompt_title = ('Find %s files'):format(search.label),
        }
      end

      local function live_grep_by_type(search)
        builtin.live_grep {
          cwd = repo_root(),
          additional_args = function()
            local globs = search_globs(search)
            vim.list_extend(globs, search.grep_ignored_globs or {})
            return glob_arguments(globs)
          end,
          prompt_title = ('Grep %s files'):format(search.label),
        }
      end

      -- Remove both generations of the type-search mappings when this config
      -- is reloaded in an existing Neovim instance.
      for suffix in pairs(type_searches) do
        pcall(vim.keymap.del, 'n', '<leader>stf' .. suffix)
        pcall(vim.keymap.del, 'n', '<leader>stg' .. suffix)
        pcall(vim.keymap.del, 'n', '<leader>sof' .. suffix)
        pcall(vim.keymap.del, 'n', '<leader>sog' .. suffix)
      end

      local function search_file_command(options)
        local search = resolve_type_search(options.args)
        if search then
          find_files_by_type(search)
        end
      end

      local function search_grep_command(options)
        local search = resolve_type_search(options.args)
        if search then
          live_grep_by_type(search)
        end
      end

      local function create_type_search_command(name, callback, description)
        vim.api.nvim_create_user_command(name, callback, {
          nargs = 1,
          complete = complete_search_type,
          desc = description,
          force = true,
        })
      end

      create_type_search_command(
        'SearchFile',
        search_file_command,
        'Find repository files filtered by language or test type'
      )
      create_type_search_command('SF', search_file_command, 'Alias for :SearchFile')
      create_type_search_command(
        'SearchGrep',
        search_grep_command,
        'Live grep repository files filtered by language or test type'
      )
      create_type_search_command('SG', search_grep_command, 'Alias for :SearchGrep')

      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', function()
        builtin.find_files { cwd = package_root() }
      end, { desc = '[S]earch package [F]iles' })
      vim.keymap.set('n', '<leader>sF', function()
        builtin.find_files { cwd = repo_root() }
      end, { desc = '[S]earch repo [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', function()
        builtin.grep_string { cwd = package_root() }
      end, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', function()
        builtin.live_grep { cwd = package_root() }
      end, { desc = '[S]earch package by [G]rep' })
      vim.keymap.set('n', '<leader>sG', function()
        builtin.live_grep { cwd = repo_root() }
      end, { desc = '[S]earch repo by [G]rep' })
      vim.keymap.set('n', '<leader>gs', function()
        builtin.git_status { cwd = repo_root() }
      end, { desc = '[G]it [S]tatus' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
      vim.keymap.set('n', '<C-p>', function()
        builtin.find_files { cwd = package_root() }
      end, { desc = 'Find package files' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  }
}
