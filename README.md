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
./install.sh configs         # re-link all config symlinks (zsh, git, tmux, nvim)
./install.sh nvim tmux       # multiple components at once
```

### Available components

| Component  | What it does                                                  |
|------------|---------------------------------------------------------------|
| `packages` | Install OS packages (apt / Homebrew)                          |
| `fonts`    | Install JetBrains Mono Nerd Font                              |
| `pyenv`    | Install pyenv (Python version manager)                        |
| `zsh`      | Oh My Zsh + plugins + set zsh as default shell                |
| `bat`      | Install bat Catppuccin Mocha theme                            |
| `tmux`     | TPM + headless plugin install                                 |
| `nvim`     | Bootstrap Neovim lazy.nvim plugins                            |
| `vscode`   | Install VS Code extensions + deploy settings                  |
| `claude`   | Symlink Claude Code `settings.json` + statusline script       |
| `configs`  | Symlink all configs: zsh, git, tmux, nvim                     |

### Legacy skip flags (full-install mode only)

| Flag             | Effect                              |
|------------------|-------------------------------------|
| `--skip-fonts`   | Skip Nerd Font installation         |
| `--skip-vscode`  | Skip VS Code extensions + settings  |
| `--skip-nvim`    | Skip Neovim plugin bootstrap        |

## What gets installed

### Shell
- **Zsh** with [Oh My Zsh](https://ohmyz.sh/)
- **zsh-autosuggestions** — inline history suggestions
- **zsh-syntax-highlighting** — command coloring
- **atuin** — searchable shell history (`Ctrl+R`)
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
| `claude`        | `~/.claude/settings.json`           | `configs/claude/settings.json`               |
| `claude`        | `~/.claude/statusline-command.sh`   | `configs/claude/statusline-command.sh`       |
| VS Code         | `*/Code/User/settings.json`         | copied (not symlinked)                       |

## After install

1. **Set terminal font** to `JetBrainsMono Nerd Font Mono Regular`
2. Open a new terminal: `exec zsh`
3. In Neovim, run `:Mason` to confirm LSP servers are installed
4. In tmux, press `Prefix+I` then `Enter` to confirm plugins are loaded
5. Run `claude` to log in on first launch

## Updating

Pull the repo and re-run `./install.sh` — it's fully idempotent (safe to run multiple times).

## Proxy

The zshrc includes `enable_proxy` / `disable_proxy` helpers that toggle HTTP + git + npm + pip proxies.
Edit the `PROXY_HTTP` and `PROXY_SOCKS` variables at the top of the proxy section to match your setup.
