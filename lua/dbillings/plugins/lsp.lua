return {
    -- Autocomplete
    {
        'saghen/blink.cmp',
        event = 'VimEnter',
        version = '1.*',
        dependencies = {
            -- Snippet Engine
            {
                'L3MON4D3/LuaSnip',
                version = '2.*',
                build = (function()
                    -- Build Step is needed for regex support in snippets.
                    -- This step is not supported in many windows environments.
                    -- Remove the below condition to re-enable on windows.
                    if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
                        return
                    end
                    return 'make install_jsregexp'
                end)(),
                dependencies = {
                    -- `friendly-snippets` contains a variety of premade snippets.
                    --    See the README about individual language/framework/plugin snippets:
                    --    https://github.com/rafamadriz/friendly-snippets
                    -- {
                    --   'rafamadriz/friendly-snippets',
                    --   config = function()
                    --     require('luasnip.loaders.from_vscode').lazy_load()
                    --   end,
                    -- },
                },
                opts = {},
            },
            'folke/lazydev.nvim',
        },
        --- @module 'blink.cmp'
        --- @type blink.cmp.Config
        opts = {
            keymap = {
                -- 'default' (recommended) for mappings similar to built-in completions
                --   <c-y> to accept ([y]es) the completion.
                --    This will auto-import if your LSP supports it.
                --    This will expand snippets if the LSP sent a snippet.
                -- 'super-tab' for tab to accept
                -- 'enter' for enter to accept
                -- 'none' for no mappings
                --
                -- For an understanding of why the 'default' preset is recommended,
                -- you will need to read `:help ins-completion`
                --
                -- No, but seriously. Please read `:help ins-completion`, it is really good!
                --
                -- All presets have the following mappings:
                -- <tab>/<s-tab>: move to right/left of your snippet expansion
                -- <c-space>: Open menu or open docs if already open
                -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
                -- <c-e>: Hide menu
                -- <c-k>: Toggle signature help
                --
                -- See :h blink-cmp-config-keymap for defining your own keymap
                preset = 'default',

                -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
                --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
            },

            appearance = {
                nerd_font_variant = 'mono',
            },

            completion = {
                documentation = { auto_show = true, auto_show_delay_ms = 200 },
            },

            sources = {
                default = { 'lsp', 'path', 'snippets', 'lazydev' },
                providers = {
                    lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
                },
            },

            snippets = { preset = 'luasnip' },

            -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
            -- which automatically downloads a prebuilt binary when enabled.
            --
            -- By default, we use the Lua implementation instead, but you may enable
            -- the rust implementation via `'prefer_rust_with_warning'`
            --
            -- See :h blink-cmp-config-fuzzy for more information
            fuzzy = { implementation = 'lua' },
            -- fuzzy = { implementation = 'prefer_rust_with_warning' },

            -- Shows a signature help window while you type arguments for a function
            signature = { enabled = true },
        },
    },

    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "saghen/blink.cmp",
            {
                "folke/lazydev.nvim",
                ft = "lua", -- only load on lua files
                opts = {
                    library = {
                        -- See the configuration section for more details
                        -- Load luvit types when the `vim.uv` word is found
                        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
                    },
                },
            },
        },
        config = function()
            local capabilities = require('blink.cmp').get_lsp_capabilities()
            local domain_lsp = require('dbillings.domain').get().lsp or {}

            vim.diagnostic.config({
                severity_sort = true,
                update_in_insert = true,
                underline = true,
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = 'E',
                        [vim.diagnostic.severity.WARN] = 'W',
                        [vim.diagnostic.severity.INFO] = 'I',
                        [vim.diagnostic.severity.HINT] = 'H',
                    },
                },
                virtual_text = {
                    spacing = 2,
                    source = 'if_many',
                    prefix = '●',
                },
                float = {
                    border = 'rounded',
                    source = true,
                },
            })

            vim.lsp.config('*', { capabilities = capabilities })

            local gopls_config = {
                cmd = function(dispatchers, config)
                    -- gopls disables automatic Go toolchain switching for the
                    -- `go` commands it launches. Resolve GOROOT from this
                    -- workspace first so repos whose go.work is newer than the
                    -- Homebrew launcher still use the requested toolchain.
                    local go_env = vim.system({ 'go', 'env', 'GOROOT' }, {
                        cwd = config.root_dir,
                        text = true,
                    }):wait()
                    if go_env.code ~= 0 then
                        error('gopls: failed to resolve the workspace Go toolchain: ' .. vim.trim(go_env.stderr))
                    end

                    local go_bin = vim.fs.joinpath(vim.trim(go_env.stdout), 'bin')
                    local path_separator = package.config:sub(3, 3)
                    return vim.lsp.rpc.start({ 'gopls' }, dispatchers, {
                        cwd = config.cmd_cwd or config.root_dir,
                        env = vim.tbl_extend(
                            'force',
                            config.cmd_env or {},
                            { PATH = go_bin .. path_separator .. vim.env.PATH }
                        ),
                        detached = config.detached,
                    })
                end,
                settings = {
                    gopls = {
                        staticcheck = false,
                        diagnosticsTrigger = 'Edit',
                        diagnosticsDelay = '250ms',
                        importShortcut = 'Definition',
                        linksInHover = false,
                        codelenses = {
                            generate = true,
                            regenerate_cgo = true,
                            tidy = false,
                            upgrade_dependency = false,
                            test = false,
                        },
                    },
                },
            }
            vim.lsp.config('gopls', vim.tbl_deep_extend(
                'force',
                gopls_config,
                domain_lsp.gopls or {}
            ))

            local basedpyright_config = {
                settings = {
                    basedpyright = {
                        analysis = {
                            autoImportCompletions = true,
                            autoSearchPaths = true,
                            diagnosticMode = 'openFilesOnly',
                            useLibraryCodeForTypes = true,
                        },
                    },
                },
            }
            vim.lsp.config('basedpyright', vim.tbl_deep_extend(
                'force',
                basedpyright_config,
                domain_lsp.basedpyright or {}
            ))

            local protobuf_language_server_config = {
                cmd = {
                    'protobuf-language-server',
                    '-stdio',
                    '-logs',
                    vim.fn.stdpath('state') .. '/protobuf-language-server.log',
                },
                filetypes = { 'proto' },
                root_markers = { '.git' },
                single_file_support = true,
            }
            vim.lsp.config('protobuf_language_server', vim.tbl_deep_extend(
                'force',
                protobuf_language_server_config,
                domain_lsp.protobuf_language_server or {}
            ))

            vim.lsp.config('vtsls', {
                settings = {
                    vtsls = {
                        autoUseWorkspaceTsdk = true,
                    },
                    typescript = {
                        format = { enable = false },
                        preferences = { importModuleSpecifier = 'non-relative' },
                        tsserver = { maxTsServerMemory = 8192 },
                        workspaceSymbols = {
                            excludeLibrarySymbols = true,
                            scope = 'currentProject',
                        },
                    },
                    javascript = {
                        format = { enable = false },
                        preferences = { importModuleSpecifier = 'non-relative' },
                    },
                },
            })

            vim.lsp.enable({
                'lua_ls',
                'gopls',
                'basedpyright',
                'vtsls',
                'starpls',
                'rust_analyzer',
                'protobuf_language_server',
            })

            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup('dbillings-lsp-attach', { clear = true }),
                callback = function(event)
                    local function map(keys, action, description)
                        vim.keymap.set('n', keys, action, {
                            buffer = event.buf,
                            desc = 'LSP: ' .. description,
                        })
                    end

                    map('gd', function()
                        require('telescope.builtin').lsp_definitions()
                    end, 'Goto definition')
                    map('gD', vim.lsp.buf.declaration, 'Goto declaration')
                    map('grr', function()
                        require('telescope.builtin').lsp_references()
                    end, 'Goto references')
                    map('gri', function()
                        require('telescope.builtin').lsp_implementations()
                    end, 'Goto implementation')
                    map('<leader>rn', vim.lsp.buf.rename, 'Rename')
                    map('<leader>ca', vim.lsp.buf.code_action, 'Code action')
                end,
            })
        end,
    }
}
