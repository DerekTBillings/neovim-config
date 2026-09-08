# Neovim Config

My personal Neovim configuration, built for working across Go, Python,
TypeScript, Rust, Protobuf, Lua, and Bazel/Starlark projects—including large
monorepositories.

The configuration uses [lazy.nvim](https://github.com/folke/lazy.nvim) for
plugins, Neovim's native LSP client, Telescope for navigation and search,
Treesitter for syntax highlighting, and Conform for formatting.

## Highlights

- Package-scoped and repository-scoped file/text search
- LSP completion, navigation, refactoring, and visible diagnostics
- Format-on-save for supported languages
- Automatic file saving when leaving a buffer or losing focus
- Automatic restoration of project buffers, tabs, splits, folds, and terminals
- Horizontal and vertical terminal mappings with stable resize behavior
- Rose Pine Main and Dawn themes
- Persistent undo without swap or backup files in the source tree
- Ignored local override directory for machine- or organization-specific settings

## Requirements

- Neovim 0.11 or newer
- Git
- [ripgrep](https://github.com/BurntSushi/ripgrep)
- `curl`, `tar`, `tree-sitter-cli`, and a C compiler for Treesitter parsers
- `make` (optional, used to build Telescope's native FZF extension)

Language features require the corresponding tools to be available on `PATH`:

| Language | Language server | Formatter |
| --- | --- | --- |
| Go | `gopls` | `gofmt` |
| Python | `basedpyright-langserver` | `ruff` |
| TypeScript/JavaScript | `vtsls` | `prettier` |
| Rust | `rust-analyzer` | LSP fallback |
| Protobuf | `protobuf-language-server` | — |
| Lua | `lua-language-server` | LSP fallback |
| Bazel/Starlark | `starpls` | `buildifier` |

Plugins and Treesitter parsers install automatically when Neovim starts.
Language servers and formatters are intentionally installed separately so the
same configuration works with system packages, development environments, and
toolchains managed by a repository.

## Installation

Back up or rename an existing Neovim configuration before cloning this one.

### macOS

Install Neovim and the command-line dependencies with Homebrew. Xcode Command
Line Tools provide the compiler used to build Treesitter parsers.

```bash
brew install neovim git ripgrep tree-sitter
xcode-select --install  # Skip this if the command-line tools are already installed
mkdir -p ~/.config
git clone https://github.com/DerekTBillings/neovim-config.git ~/.config/nvim
nvim
```

### Linux

Install Neovim 0.11 or newer using your distribution package manager or an
[official Neovim release](https://neovim.io/doc/install/). Distribution
packages can lag behind the current stable release, so confirm with
`nvim --version`. For Debian- and Ubuntu-based systems, install the supporting
tools with:

```bash
sudo apt update
sudo apt install git ripgrep curl tar build-essential
mkdir -p ~/.config
git clone https://github.com/DerekTBillings/neovim-config.git ~/.config/nvim
nvim
```

Install `tree-sitter-cli` through your system package manager if it is not
already available. On Windows Subsystem for Linux, use these Linux instructions
and clone the configuration inside the WSL home directory.

### Windows

Run the following commands in PowerShell. Neovim stores its configuration in
`$env:LOCALAPPDATA\nvim` on native Windows.

```powershell
winget install --id Neovim.Neovim --exact
winget install --id Git.Git --exact
winget install --id BurntSushi.ripgrep.MSVC --exact
git clone https://github.com/DerekTBillings/neovim-config.git "$env:LOCALAPPDATA\nvim"
nvim
```

Treesitter also needs `tree-sitter-cli` and a C compiler. Install a Windows C
toolchain such as Visual Studio Build Tools or LLVM and ensure the compiler is
on `PATH`. The optional native Telescope FZF extension is skipped when `make`
is unavailable; Telescope still works without it. The `:InitialSetup` workspace
command requires `tmux`, so it is intended for macOS, Linux, or WSL rather than
native Windows.

On first launch, lazy.nvim installs the pinned plugins from `lazy-lock.json`,
and Treesitter installs its configured parsers. Check installation health with:

```vim
:checkhealth
:Lazy
:ConformInfo
:LspInfo
```

## Key mappings

The leader key is `Space`.

### Files and search

| Mapping | Action |
| --- | --- |
| `Space p v` | Open the netrw file browser |
| `Ctrl-p` / `Space s f` | Find files in the nearest package |
| `Space s F` | Find files across the repository |
| `Space s g` | Grep within the nearest package |
| `Space s G` | Grep across the repository |
| `Space s w` | Search for the word under the cursor |
| `Space /` | Search within the current buffer |
| `Space s /` | Search within open buffers |
| `Space s .` | List recently opened files |
| `Space Space` | Switch between open buffers |
| `Space s r` | Resume the previous Telescope search |
| `Space s d` | List diagnostics |
| `Space s n` | Find files in this Neovim configuration |

Package scope is determined by the nearest `BUILD.in`, `BUILD.bazel`, or
`BUILD` file. Repository scope is determined by the nearest `.git` directory.
Generated `*.pb.go`, `*.pyi`, and `*stubs.py` files are omitted from Telescope
file and text searches, but remain available to LSP navigation. Python type
grep also omits generated `*.pb2.py` files.

Type-search arguments are `go` (`*.go`), `py` (`*.py`), `pr`/`proto`
(`*.proto`), `ts` (`*.ts` and `*.tsx`), `js` (`*.js`), and `te`/`test`
(filenames containing `test`). Language-specific type searches exclude test
filenames; use `test` to search test files directly. For example,
`:SearchFile go` finds non-test Go files and `:SearchGrep proto` greps Proto
files. The shorter `:SF` and `:SG` aliases provide the same behavior.

While Telescope is open, use `Ctrl-n`/`Ctrl-p` or the arrow keys to move,
`Enter` to open a result, and `Esc` to close it.

### LSP and completion

| Mapping | Action |
| --- | --- |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `grr` | Find references |
| `gri` | Find implementations |
| `Space r n` | Rename symbol |
| `Space c a` | Show code actions |
| `Space f` | Format the current buffer or selection |
| `Space s d` | Search diagnostics |

For Python, completion suggestions can add missing imports automatically.
Press `Ctrl-Space` while typing a symbol and accept the desired suggestion with
`Ctrl-y`. If an undefined symbol is already present, place the cursor on it and
use `Space c a` to select an available add-import action.

Completion controls:

| Mapping | Action |
| --- | --- |
| `Ctrl-Space` | Open completion or documentation |
| `Ctrl-n` / `Ctrl-p` | Select the next/previous suggestion |
| `Ctrl-y` | Accept the selected suggestion |
| `Ctrl-e` | Close completion |
| `Ctrl-k` | Toggle signature help |
| `Tab` / `Shift-Tab` | Move through snippet placeholders |

Diagnostics display an `E`, `W`, `I`, or `H` in the sign column, underline the
affected text, and show an inline message.

### Git

| Mapping | Action |
| --- | --- |
| `Space g s` | Open Telescope Git status |

### Windows and terminals

| Mapping | Action |
| --- | --- |
| `Ctrl-h/j/k/l` | Move to the left/lower/upper/right window |
| `Space s t` | Open a 30-row terminal at the bottom |
| `Space s v` | Open a terminal on the right at roughly one-quarter width |
| `Esc Esc` | Leave terminal-input mode |

Neovim opens horizontal splits below and vertical splits to the right. Standard
window commands still work, including `:leftabove vsplit` for a new panel on
the left, `:resize N` for height, and `:vr N` (short for
`:vertical resize N`) for width.

### Sessions

Sessions are saved per working directory and restored automatically.

| Mapping | Action |
| --- | --- |
| `Space w s` | Save the current workspace session |
| `Space w r` | Search saved sessions |
| `Space w a` | Toggle automatic session saving |

Running `nvim .` from the same project directory restores the previous layout.

## Commands

| Command | Action |
| --- | --- |
| `:CopyPath` | Copy the current path relative to the Git repository |
| `:CopyPathParent` | Copy the relative parent directory |
| `:CopyPathGrandParent` | Copy the relative directory one level above the parent |
| `:CopyPathFull` | Copy the absolute path |
| `:SearchFile TYPE` / `:SF TYPE` | Find repository files filtered by language or test type |
| `:SearchGrep TYPE` / `:SG TYPE` | Grep repository text filtered by language or test type |
| `:vr N` | Resize the current window to `N` columns |
| `:colorscheme rose-pine-main` | Use the dark Rose Pine theme |
| `:colorscheme rose-pine-dawn` | Use the light Rose Pine theme |

Lowercase aliases such as `:copy-path` are also supported.

## Local overrides

Files under `lua/dbillings/domains/` are intentionally ignored by Git. They can
augment or override the portable configuration without adding private or
environment-specific details to this repository.

Each override returns a Lua table. For example:

```lua
return {
  lsp = {
    gopls = {
      settings = {
        gopls = {
          expandWorkspaceToModule = false,
        },
      },
    },
  },
  telescope = {
    ignored_globs = {
      '!*.generated.go',
    },
  },
}
```

All override files in that directory are loaded in sorted filename order and
deep-merged over the portable defaults.
