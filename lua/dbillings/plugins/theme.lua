return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    lazy = false,
    config = function()
      local in_screen = vim.env.STY and vim.env.STY ~= ''

      -- Coder's web terminal runs applications through GNU Screen 4.x,
      -- which cannot pass through Rose Pine's 24-bit RGB colors. Convert the
      -- active palette to xterm-256 colors there; normal terminals retain the
      -- original true-color palette.
      local function nearest_xterm_color(rgb)
        local red = math.floor(rgb / 0x10000) % 0x100
        local green = math.floor(rgb / 0x100) % 0x100
        local blue = rgb % 0x100
        local levels = { 0, 95, 135, 175, 215, 255 }
        local best_index = 16
        local best_distance = math.huge

        for index = 16, 255 do
          local candidate_red
          local candidate_green
          local candidate_blue
          if index < 232 then
            local offset = index - 16
            candidate_red = levels[math.floor(offset / 36) + 1]
            candidate_green = levels[math.floor(offset / 6) % 6 + 1]
            candidate_blue = levels[offset % 6 + 1]
          else
            local level = 8 + (index - 232) * 10
            candidate_red = level
            candidate_green = level
            candidate_blue = level
          end

          local distance = (red - candidate_red) ^ 2
              + (green - candidate_green) ^ 2
              + (blue - candidate_blue) ^ 2
          if distance < best_distance then
            best_index = index
            best_distance = distance
          end
        end

        return best_index
      end

      local function apply_screen_palette()
        if not in_screen then
          return
        end

        for name, highlight in pairs(vim.api.nvim_get_hl(0, {})) do
          if not highlight.link and (highlight.fg or highlight.bg) then
            local cterm = { update = true }
            if highlight.fg then
              cterm.ctermfg = nearest_xterm_color(highlight.fg)
            end
            if highlight.bg then
              cterm.ctermbg = nearest_xterm_color(highlight.bg)
            end
            vim.api.nvim_set_hl(0, name, cterm)
          end
        end

        vim.opt.termguicolors = false
      end

      vim.api.nvim_create_autocmd('ColorScheme', {
        group = vim.api.nvim_create_augroup('dbillings-screen-colors', { clear = true }),
        pattern = 'rose-pine*',
        callback = apply_screen_palette,
      })

      require("rose-pine").setup({
        variant = "main",
        styles = {
          -- GNU Screen 4.x interprets the italic escape sequence as standout
          -- text, which appears as reversed color blocks in Coder terminals.
          italic = not in_screen,
        },
      })
      vim.cmd.colorscheme('rose-pine-main')
    end,
  }
}
