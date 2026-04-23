# Dotfiles — Dev Environment Setup

Full environment setup for macOS (Apple Silicon / Intel) and Ubuntu/Debian Linux.
One command installs everything and wires up all configs via symlinks.

## Quick start

```bash
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh
```

After install, set your git identity (the repo doesn't store personal info):

```bash
# ~/.gitconfig.local is created from the example on first install
$EDITOR ~/.gitconfig.local
```

## Day-to-day commands

Once installed, a `dotfiles` shell function is available:

```bash
dotfiles update   # git pull + re-link configs + update nvim/tmux plugins
dotfiles check    # run health checks (same as ./test.sh)
dotfiles edit     # open repo in $EDITOR
dotfiles cd       # cd into repo
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
./install.sh update          # update everything (pull + plugins + configs)
./install.sh doctor          # run health checks
./install.sh nvim tmux       # multiple components at once
```

### Available components

| Component  | What it does                                                            |
|------------|-------------------------------------------------------------------------|
| `packages` | Install OS packages (apt / Homebrew)                                    |
| `fonts`    | Install JetBrains Mono Nerd Font                                        |
| `pyenv`    | Install pyenv (Python version manager)                                  |
| `zsh`      | Oh My Zsh + plugins + set zsh as default shell                          |
| `bat`      | Install bat Catppuccin Mocha theme                                      |
| `kitty`    | Install Kitty terminal (cask on macOS) + deploy Catppuccin Mocha config |
| `tmux`     | TPM + headless plugin install                                           |
| `nvim`     | Bootstrap Neovim lazy.nvim plugins                                      |
| `vscode`   | Install VS Code extensions (with marketplace pre-check) + deploy settings|
| `claude`   | Symlink Claude Code `settings.json` + statusline script                 |
| `configs`  | Symlink all configs: zsh, git, tmux, nvim, kitty                        |
| `update`   | Pull repo + upgrade packages + update nvim/tmux plugins + re-link configs |
| `doctor`   | Run all health checks (delegates to `test.sh`)                          |

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
./test.sh              # run all checks
./test.sh tools        # check binaries only
./test.sh symlinks     # check config symlinks only
./test.sh configs      # check config file validity
./test.sh shell        # check shell environment (default shell, PATH, OMZ)
./test.sh fonts        # check Nerd Font installation
./test.sh vscode       # check VS Code extensions
```

The test script mirrors the installer's PATH extension logic so it accurately reflects
the post-install state. It exits with code 1 if any check fails — suitable for CI.

## Local overrides

Machine-specific configuration that should never be committed lives in two files:

### `~/.gitconfig.local` — git identity

Created automatically from `configs/git/gitconfig.local.example` on first install.
Set your name and email here:

```gitconfig
[user]
    name = Your Name
    email = your@email.com
```

The shared `~/.gitconfig` uses `[include] path = ~/.gitconfig.local` to pull this in.

### `~/.zshrc.local` — shell overrides

`~/.zshrc` sources `~/.zshrc.local` at startup if it exists. Use it for:
- Proxy configuration (see `configs/zsh/zshrc.local.example` for a full template)
- Work-specific aliases and env vars
- JetBrains VM options hook
- Anything that differs between machines

```bash
cp ~/dotfiles/configs/zsh/zshrc.local.example ~/.zshrc.local
$EDITOR ~/.zshrc.local
```

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
fzf shell integration is sourced directly (not via the OMZ plugin) so it works on both
macOS (Homebrew) and Linux (`/usr/share/doc/fzf/examples/`):

| Key      | Action                                          |
|----------|-------------------------------------------------|
| `Ctrl+T` | Fuzzy-find files, paste to CLI                  |
| `Ctrl+R` | Fuzzy search history (atuin if installed, else fzf) |
| `Alt+C`  | Fuzzy cd into directory                         |

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
- **Smart extension install**: pre-checks each extension against the Marketplace before
  starting, verifies connectivity, classifies failures as "not found" vs network errors,
  and retries transient failures once with a 5-second pause.

### Kitty Terminal
- **Theme**: Catppuccin Mocha (matches Neovim + bat)
- **Font**: JetBrains Mono Nerd Font with ligatures, 13pt
- **Features**: GPU-accelerated, tab bar (powerline slanted), 0.96 background opacity
- **Shell**: `shell .` — uses the system default shell (set via `chsh`)
- **macOS**: installed as a Homebrew cask (`brew install --cask kitty`)
- **Linux**: installed via the official Kitty installer; set as default terminal via `update-alternatives`
- **Keybindings**: `Ctrl+Shift+T` new tab, `Ctrl+Shift+H/J/K/L` navigate splits, `Ctrl+Shift+Enter` new split

### Claude Code
- **Statusline**: custom command-based statusline showing directory, git branch, model,
  context usage (progress bar), token count, session cost, and rate limits
- **Config**: `~/.claude/settings.json` + `~/.claude/statusline-command.sh` deployed via symlinks
- **CLI**: installed automatically on Linux via `npm install -g @anthropic-ai/claude-code`

## Config locations

| Config          | Deployed to                         | Source in repo                               |
|-----------------|-------------------------------------|----------------------------------------------|
| `zshrc`         | `~/.zshrc`                          | `configs/zsh/zshrc`                          |
| git             | `~/.gitconfig`                      | `configs/git/gitconfig`                      |
| git identity    | `~/.gitconfig.local`                | copied from `configs/git/gitconfig.local.example` |
| `nvim`          | `~/.config/nvim`                    | `configs/nvim/`                              |
| `tmux`          | `~/.config/tmux/tmux.conf`          | `configs/tmux/tmux.conf`                     |
| `kitty`         | `~/.config/kitty/kitty.conf`        | `configs/kitty/kitty.conf`                   |
| `claude`        | `~/.claude/settings.json`           | `configs/claude/settings.json`               |
| `claude`        | `~/.claude/statusline-command.sh`   | `configs/claude/statusline-command.sh`       |
| VS Code         | `*/Code/User/settings.json`         | copied (not symlinked)                       |

## After install

1. Edit `~/.gitconfig.local` — add your name + email
2. Open a new terminal (or run `exec zsh`) — paths are now auto-loaded
3. Launch Kitty — font + theme are pre-configured
4. Run `./test.sh` to verify everything is set up correctly
5. In Neovim, run `:Mason` to confirm LSP servers are installed
6. In tmux, press `Prefix+I` to confirm plugins are loaded
7. Run `claude` to authenticate on first launch

## Updating

```bash
dotfiles update
# or: ./install.sh update
```

This pulls the latest repo changes, re-links all configs, upgrades Homebrew packages (macOS),
and updates Neovim + tmux plugins in one step. `~/.gitconfig.local` and `~/.zshrc.local` are
never touched.

## Known platform differences

| Feature                  | macOS                              | Ubuntu / Debian                              |
|--------------------------|------------------------------------|----------------------------------------------|
| Kitty install            | `brew install --cask kitty`        | Official installer → `~/.local/kitty.app`    |
| Default terminal         | Set in System Settings             | `update-alternatives --set x-terminal-emulator` |
| bat binary name          | `bat`                              | `batcat` (symlinked to `bat` in `~/.local/bin`) |
| fd binary name           | `fd`                               | `fdfind` (use `fd` via Oh My Zsh alias)      |
| fzf shell integration    | Homebrew (`$BREW_PREFIX/opt/fzf/shell/`) | `/usr/share/doc/fzf/examples/`          |
| npm global prefix        | Homebrew-managed                   | `~/.local` (no sudo needed)                  |
| Go version               | Homebrew latest                    | Fetched dynamically from go.dev/dl           |
| delta/lazygit/nvim       | Homebrew latest                    | Latest GitHub release (fetched dynamically)  |

## Proxy

Proxy helpers (`enable_proxy` / `disable_proxy`) live in `~/.zshrc.local`, not in the
shared config. Copy `configs/zsh/zshrc.local.example` to `~/.zshrc.local` and edit the
`PROXY_HTTP` / `PROXY_SOCKS` addresses to match your setup.
