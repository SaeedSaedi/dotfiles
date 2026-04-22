# Dotfiles — Saeed's Dev Environment

Full environment setup for macOS (Apple Silicon / Intel) and Ubuntu/Debian Linux.
One command installs everything and wires up all configs via symlinks.

## Quick start

```bash
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

## Install specific components

Pass one or more component names to install only those parts:

```bash
./install.sh claude          # deploy Claude Code config only
./install.sh nvim            # neovim plugin bootstrap only
./install.sh tmux            # tmux TPM + plugins only
./install.sh vscode          # VS Code extensions + settings only
./install.sh zsh             # Oh My Zsh + plugins + set as default shell
./install.sh kitty           # Kitty terminal install + config symlink
./install.sh configs         # re-link all config symlinks (zsh, git, tmux, nvim, kitty)
./install.sh nvim tmux       # multiple components at once
```

### Available components

| Component  | What it does                                                           |
|------------|------------------------------------------------------------------------|
| `packages` | Install OS packages (apt / Homebrew)                                   |
| `fonts`    | Install JetBrains Mono Nerd Font                                       |
| `pyenv`    | Install pyenv (Python version manager)                                 |
| `zsh`      | Oh My Zsh + plugins + set zsh as default shell                         |
| `bat`      | Install bat Catppuccin Mocha theme                                     |
| `kitty`    | Install Kitty terminal (cask on macOS) + deploy Catppuccin Mocha config|
| `tmux`     | TPM + headless plugin install                                          |
| `nvim`     | Bootstrap Neovim lazy.nvim plugins                                     |
| `vscode`   | Install VS Code extensions (with marketplace pre-check) + deploy settings|
| `claude`   | Symlink Claude Code `settings.json` + statusline script                |
| `configs`  | Symlink all configs: zsh, git, tmux, nvim, kitty                       |

### Legacy skip flags (full-install mode only)

| Flag             | Effect                              |
|------------------|-------------------------------------|
| `--skip-fonts`   | Skip Nerd Font installation         |
| `--skip-vscode`  | Skip VS Code extensions + settings  |
| `--skip-nvim`    | Skip Neovim plugin bootstrap        |
| `--skip-atuin`   | Skip atuin install (non-interactive)|

## Smoke tests

After installing, verify everything is set up correctly:

```bash
chmod +x test.sh
./test.sh              # run all checks
./test.sh tools        # check binaries only
./test.sh symlinks     # check config symlinks only
./test.sh configs      # check config file validity
./test.sh shell        # check shell environment (default shell, PATH, OMZ)
./test.sh fonts        # check Nerd Font installation
./test.sh vscode       # check VS Code extensions
```

The test script uses the same PATH extension logic as the installer, so it accurately
reflects the post-install state. It exits with code 1 if any check fails, making it
suitable for CI verification.

## What gets installed

### Shell
- **Zsh** with [Oh My Zsh](https://ohmyz.sh/)
- **zsh-autosuggestions** — inline history suggestions (Homebrew on macOS, auto-cloned on Linux)
- **zsh-syntax-highlighting** — command coloring
- **atuin** — searchable shell history (`Ctrl+R`) — optional, prompted during install
- **zoxide** — smart `cd` that learns your dirs

### Terminal tools
| Tool        | Purpose                              |
|-------------|--------------------------------------|
| `eza`       | Modern `ls` with icons and git info  |
| `bat`       | `cat` with syntax highlighting       |
| `fzf`       | Fuzzy finder (files, history, etc.)  |
| `fd`        | Fast `find` replacement              |
| `ripgrep`   | Fast `grep` replacement              |
| `lazygit`   | Terminal UI for git                  |
| `delta`     | Beautiful git diffs                  |
| `jq`        | JSON processor                       |
| `pyenv`     | Python version manager               |
| `direnv`    | Per-directory env vars               |
| `gh`        | GitHub CLI                           |

### fzf key bindings
fzf shell integration (key bindings and tab completion) is sourced directly rather
than via the Oh My Zsh plugin, so it works correctly on both macOS (Homebrew) and
Linux (apt `fzf` package, `/usr/share/doc/fzf/examples/`):

| Key            | Action                          |
|----------------|---------------------------------|
| `Ctrl+T`       | Fuzzy-find files, paste to CLI  |
| `Ctrl+R`       | Fuzzy search history (atuin if installed, else fzf) |
| `Alt+C`        | Fuzzy cd into directory         |

### Neovim
Configured with [lazy.nvim](https://github.com/folke/lazy.nvim):
- **Theme**: Catppuccin Mocha
- **LSP**: pyright (Python), gopls (Go), intelephense (PHP), lua_ls
- **Completion**: nvim-cmp + LuaSnip + friendly-snippets
- **Telescope**: fuzzy finder for files, grep, LSP symbols
- **Treesitter**: syntax highlighting for Python, Go, PHP, JS/TS, HTML, etc.
- **UI**: lualine, bufferline, neo-tree, alpha (dashboard), nvim-notify
- **Git**: gitsigns (gutter), lazygit.nvim
- **Utils**: which-key, trouble, todo-comments, toggleterm, nvim-surround

### tmux
- Prefix: `Ctrl+A`
- One Dark Pro color theme
- vim-style pane navigation (`h/j/k/l`)
- Session persistence via tmux-resurrect + tmux-continuum
- Status bar: session name, current path, git branch, date/time

### VS Code
- Theme: One Dark Pro
- Language support: Python (black), PHP/Laravel (intelephense + blade), Go, JS/TS (prettier), YAML
- Extensions: GitLens, Copilot, Claude Code, ErrorLens, indent-rainbow, REST Client, Todo Tree
- **Smart extension install**: the installer pre-checks each extension against the
  VS Code Marketplace before starting (saves time by skipping unavailable ones),
  verifies marketplace connectivity, classifies failures as "not found" vs network
  errors, and retries transient failures once with a 5-second pause.

### Kitty Terminal
- **Theme**: Catppuccin Mocha (matches Neovim + bat)
- **Font**: JetBrains Mono Nerd Font with ligatures, 13pt
- **Features**: GPU-accelerated, tab bar (powerline slanted), 0.96 background opacity
- **Shell**: `shell .` — uses the system default shell (set via `chsh`)
- **macOS**: installed as a Homebrew cask (`brew install --cask kitty`)
- **Linux**: installed via the official Kitty installer; set as default terminal via `update-alternatives`
- **Keybindings**: `Ctrl+Shift+T` new tab, `Ctrl+Shift+H/J/K/L` navigate splits, `Ctrl+Shift+Enter` new split
- **Config**: `~/.config/kitty/kitty.conf` deployed via symlink

### Claude Code
- **Statusline**: custom command-based statusline showing directory, git branch, model, context usage, token count, session cost, and rate limits
- **Config**: `~/.claude/settings.json` + `~/.claude/statusline-command.sh` deployed via symlinks
- **CLI**: installed automatically on Linux via `npm install -g @anthropic-ai/claude-code`

## Config locations (after install)

| Config          | Symlinked to                        | Source                                       |
|-----------------|-------------------------------------|----------------------------------------------|
| `zshrc`         | `~/.zshrc`                          | `configs/zsh/zshrc`                          |
| `nvim`          | `~/.config/nvim`                    | `configs/nvim/`                              |
| `tmux`          | `~/.config/tmux/tmux.conf`          | `configs/tmux/tmux.conf`                     |
| `git`           | `~/.gitconfig`                      | `configs/git/gitconfig`                      |
| `kitty`         | `~/.config/kitty/kitty.conf`        | `configs/kitty/kitty.conf`                   |
| `claude`        | `~/.claude/settings.json`           | `configs/claude/settings.json`               |
| `claude`        | `~/.claude/statusline-command.sh`   | `configs/claude/statusline-command.sh`       |
| VS Code         | `*/Code/User/settings.json`         | copied (not symlinked)                       |

## After install

1. **Set terminal font** to `JetBrainsMono Nerd Font Mono Regular`
2. Open a new terminal: `exec zsh`
3. Run `./test.sh` to verify everything is set up correctly
4. In Neovim, run `:Mason` to confirm LSP servers are installed
5. In tmux, press `Prefix+I` then `Enter` to confirm plugins are loaded
6. Run `claude` to log in on first launch

## Updating

Pull the repo and re-run `./install.sh` — it's fully idempotent (safe to run multiple times).

## Known platform differences

| Feature                  | macOS                          | Ubuntu / Debian                            |
|--------------------------|--------------------------------|--------------------------------------------|
| Kitty install            | `brew install --cask kitty`    | Official installer → `~/.local/kitty.app`  |
| Default terminal         | Set in System Settings         | `update-alternatives --set x-terminal-emulator` |
| bat binary name          | `bat`                          | `batcat` (symlinked to `bat` in `~/.local/bin`) |
| fd binary name           | `fd`                           | `fdfind` (use `fd` via Oh My Zsh alias)    |
| fzf shell integration    | Homebrew (`$BREW_PREFIX/opt/fzf/shell/`) | `/usr/share/doc/fzf/examples/`  |
| npm global prefix        | Homebrew-managed               | `~/.local` (no sudo needed)                |
| Go version               | Homebrew latest                | Fetched dynamically from go.dev/dl         |

## Proxy

The zshrc includes `enable_proxy` / `disable_proxy` helpers that toggle HTTP + git + npm + pip proxies.
Edit the `PROXY_HTTP` and `PROXY_SOCKS` variables at the top of the proxy section to match your setup.
