return {
  {
    'rmagatti/auto-session',
    lazy = false,
    init = function()
      -- Restore buffers, tabs, splits, folds, window sizes, and terminals.
      vim.o.sessionoptions = 'blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions'
    end,
    opts = {
      -- Avoid creating sessions for broad directories that are not projects.
      suppressed_dirs = { '~/', '/' },
      show_auto_restore_notif = true,
      post_restore_cmds = {
        function()
          -- Sessions restore window-local appearance after plugins load.
          -- Preserve the currently selected Rose Pine light/dark variant.
          local colorscheme = vim.o.background == 'light'
              and 'rose-pine-dawn'
              or 'rose-pine-main'
          vim.cmd.colorscheme(colorscheme)
        end,
      },
      session_lens = {
        picker = 'telescope',
      },
    },
    keys = {
      { '<leader>wr', '<cmd>AutoSession search<CR>', desc = '[W]orkspace session sea[R]ch' },
      { '<leader>ws', '<cmd>AutoSession save<CR>', desc = '[W]orkspace [S]ave session' },
      { '<leader>wa', '<cmd>AutoSession toggle<CR>', desc = '[W]orkspace toggle [A]utosave' },
    },
  },
}
