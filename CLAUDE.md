# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Does

A cross-platform (macOS + Ubuntu/Debian) dotfiles installer that sets up a complete development environment. A single `./install.sh` run installs packages, configures tools, deploys configs via symlinks, and sets up editors/terminals.

## Key Commands

```bash
# Full install
./install.sh

# Install specific components only (safe to re-run)
./install.sh tmux nvim vscode claude

# Skip font installation
./install.sh --skip-fonts

# Run all smoke tests (CI-suitable, exits 1 on failure)
./test.sh

# Run a specific test scope
./test.sh tools
./test.sh symlinks
./test.sh configs
./test.sh shell
./test.sh fonts
./test.sh vscode
```

Valid component names: `packages`, `fonts`, `pyenv`, `zsh`, `bat`, `kitty`, `tmux`, `nvim`, `vscode`, `claude`, `configs`

## Architecture

### Core Scripts

**`install.sh`** — Monolithic bash installer (~900 lines). The `want()` function controls which components run: `want all` runs everything, `want tmux` runs only tmux. Each component is an idempotent block. Cross-platform branching uses `$PLATFORM` (`macos` or `linux`).

**`github_latest <owner/repo>`** — helper in `install.sh` that fetches the latest GitHub release tag. Used by nvim, lazygit, delta, and Nerd Fonts to always install the current release rather than a pinned version.

**`test.sh`** — Smoke test suite (~420 lines). Mirrors `install.sh`'s PATH extension logic to test the post-install state. Scoped via first argument (`tools`, `symlinks`, etc.) or `all`.

### Config Deployment

All configs in `configs/` are deployed as **symlinks** (except VS Code settings and `gitconfig.local`, which are copied). The installer uses `ln -sf` so re-running is safe.

```
configs/
  zsh/zshrc                     → ~/.zshrc
  zsh/zshrc.local.example       → (copy to ~/.zshrc.local for local overrides)
  git/gitconfig                 → ~/.gitconfig
  git/gitconfig.local.example   → (copied to ~/.gitconfig.local on first install)
  tmux/tmux.conf                → ~/.config/tmux/tmux.conf
  nvim/                         → ~/.config/nvim/
  kitty/kitty.conf              → ~/.config/kitty/kitty.conf
  claude/                       → ~/.claude/ (settings.json, statusline-command.sh)
```

### Local Override Pattern

The repo never stores personal info or machine-specific settings:

- **`~/.gitconfig.local`** — git identity (`[user]` name/email). Created from example on first install. Included by `configs/git/gitconfig` via `[include] path = ~/.gitconfig.local`.
- **`~/.zshrc.local`** — machine-specific shell config (proxy helpers, work aliases, etc.). Sourced at the end of `~/.zshrc` if it exists. Template: `configs/zsh/zshrc.local.example`.
- **`.gitignore`** blocks `*.local` files (except `*.local.example`) from being committed.

### Platform Differences Worth Knowing

| Concern | macOS | Linux |
|---|---|---|
| Package manager | Homebrew | apt + release binaries |
| `bat` binary | `bat` | `batcat` (symlinked to `~/.local/bin/bat`) |
| `fd` binary | `fd` | `fdfind` (aliased via OMZ plugin) |
| fzf shell integration | `$HOMEBREW_PREFIX/opt/fzf/shell/` | `/usr/share/doc/fzf/examples/` |
| npm prefix | Homebrew-managed | `~/.local` (configured in install) |
| Kitty install | Homebrew cask | Official installer → `~/.local/kitty.app` |
| Zsh plugins | Homebrew | Git-cloned by `install.sh` |

### Zsh Plugin Self-Healing (Linux)

On Linux, `configs/zsh/zshrc` auto-clones missing OMZ plugins at shell startup. This means the zshrc must tolerate missing plugins gracefully on first login before `install.sh` runs.

### VS Code Extension Install Logic

The installer pre-validates each extension against the marketplace (HTTP 200 check) before attempting install, classifies failures (not-found vs network), retries transient failures once after 5s, and prints a retry command for anything that failed.

### Claude Statusline

`configs/claude/statusline-command.sh` is a shell+jq script that renders a dynamic status bar showing git branch, model, context usage (progress bar), token count, cost (Sonnet 4.6 pricing), and rate limits. It's wired into `configs/claude/settings.json` via `"type": "command"`.

## Design Conventions

- **Idempotent**: every installer block is safe to re-run; backups use timestamped `.bak` files
- **Absolute paths** throughout scripts — no `cd` tricks
- **Dynamic versions**: delta, lazygit, nvim, and Nerd Fonts all fetch the latest release from GitHub at install time via `github_latest()`; Go fetches from go.dev/dl
- **No personal info in repo**: git identity lives in `~/.gitconfig.local`; proxy config lives in `~/.zshrc.local`
- **Theme**: Catppuccin Mocha everywhere (nvim, bat, kitty, fzf, zsh autosuggestions, delta)
- **ANSI 256-color** palette in shell scripts (compatible with VS Code terminal + standard terminals)
- **tmux prefix**: Ctrl+A (not default Ctrl+B)
- **fzf**: sourced directly in zshrc, not via OMZ plugin — avoids path inconsistencies across platforms
