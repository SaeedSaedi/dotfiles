#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  Dotfiles installer — macOS (Apple Silicon / Intel) + Ubuntu/Debian Linux
#
#  Full install:
#    ./install.sh
#
#  Install specific components only:
#    ./install.sh claude
#    ./install.sh nvim tmux
#    ./install.sh vscode
#
#  Components: packages fonts paths pyenv zsh bat kitty tmux nvim vscode claude configs
#
#  Legacy skip flags (still work in full-install mode):
#    --skip-fonts   --skip-vscode   --skip-nvim
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Flags & component selection ───────────────────────────────────────────────
SKIP_FONTS=false
SKIP_VSCODE=false
SKIP_NVIM=false
ONLY=()   # if non-empty, run only the listed components

for arg in "$@"; do
    case "$arg" in
        --skip-fonts)  SKIP_FONTS=true  ;;
        --skip-vscode) SKIP_VSCODE=true ;;
        --skip-nvim)   SKIP_NVIM=true   ;;
        --*)           echo "[!] Unknown flag: $arg" >&2 ;;
        *)             ONLY+=("$arg")   ;;
    esac
done

# want <component> → true when running everything OR component is in ONLY list
want() { [[ ${#ONLY[@]} -eq 0 ]] || printf '%s\n' "${ONLY[@]}" | grep -qx "$1"; }

# ── Colors / helpers ──────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

log()     { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
err()     { echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }
section() { echo -e "\n${BOLD}${BLUE}══════ $* ══════${NC}"; }

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── OS detection ──────────────────────────────────────────────────────────────
OS=""
ARCH=$(uname -m)
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS="linux"
    DISTRO="${ID:-unknown}"
else
    err "Unsupported OS. Only macOS and Linux are supported."
fi

# ── Extend PATH for the duration of this script ───────────────────────────────
# Ensures already-installed tools in ~/.local/bin or /usr/local/go are detected
# correctly by command -v checks, even before the shell profile is sourced.
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:/usr/local/go/bin:$HOME/go/bin:$PATH"

section "Dotfiles installer  |  OS: $OS  |  Arch: $ARCH"
echo "  Dotfiles: $DOTFILES"
echo "  Home:     $HOME"
[[ ${#ONLY[@]} -gt 0 ]] && echo "  Components: ${ONLY[*]}"
echo ""

# ── Backup helper ─────────────────────────────────────────────────────────────
backup_existing() {
    local target="$1"
    if [[ -e "$target" && ! -L "$target" ]]; then
        local bak="${target}.bak.$(date +%Y%m%d_%H%M%S)"
        mv "$target" "$bak"
        warn "Backed up: $target  →  $bak"
    fi
}

symlink() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    backup_existing "$dest"
    ln -sf "$src" "$dest"
    log "Linked: $(basename "$dest")"
}

# ── Homebrew (macOS) ──────────────────────────────────────────────────────────
install_homebrew() {
    section "Homebrew"
    if command -v brew &>/dev/null; then
        log "Homebrew already installed — updating"
        brew update --quiet
    else
        log "Installing Homebrew…"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ "$ARCH" == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
}

# ── macOS packages ────────────────────────────────────────────────────────────
install_packages_macos() {
    section "macOS packages (Homebrew)"

    local brews=(
        neovim tmux kitty git curl wget jq tree
        fzf fd bat eza zoxide atuin
        lazygit git-delta ripgrep
        pyenv direnv
        go node
        gh pwgen
        zsh-autosuggestions zsh-syntax-highlighting
    )

    for pkg in "${brews[@]}"; do
        if brew list --formula "$pkg" &>/dev/null 2>&1; then
            log "Already installed: $pkg"
        else
            log "Installing: $pkg"
            brew install "$pkg"
        fi
    done
}

# ── Nerd Font (macOS) ─────────────────────────────────────────────────────────
install_font_macos() {
    $SKIP_FONTS && return
    section "JetBrains Mono Nerd Font (macOS)"
    if [[ -d "$HOME/Library/Fonts" ]] && ls "$HOME/Library/Fonts"/JetBrainsMonoNerd* &>/dev/null 2>&1; then
        log "Font already installed"
    else
        log "Installing JetBrains Mono Nerd Font…"
        brew install --cask font-jetbrains-mono-nerd-font
    fi
}

# ── Ubuntu/Debian packages ────────────────────────────────────────────────────
install_packages_linux() {
    section "Linux packages (apt + extras)"

    log "Updating apt…"
    sudo apt-get update -qq

    local apt_pkgs=(
        git curl wget jq tree build-essential
        tmux zsh
        ripgrep fd-find
        fzf
        direnv
        gh
        pwgen
        unzip
        ca-certificates
        software-properties-common
        libssl-dev libffi-dev zlib1g-dev
        libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev
        xz-utils tk-dev libxml2-dev libxmlsec1-dev liblzma-dev
    )

    sudo apt-get install -y "${apt_pkgs[@]}"

    # ── VS Code — official Microsoft build (not code-oss) ─────────────────────
    # code-oss from Ubuntu repos uses Open VSX and can't install Microsoft-
    # marketplace extensions (Copilot, Pylance, GitLens, etc.). We always
    # install from Microsoft's own apt repo so 'code' is the real VS Code.
    if ! command -v code &>/dev/null; then
        log "Installing VS Code (Microsoft apt repo)…"
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
            | gpg --dearmor \
            | sudo tee /etc/apt/keyrings/microsoft-vscode.gpg >/dev/null
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft-vscode.gpg] \
https://packages.microsoft.com/repos/code stable main" \
            | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
        sudo apt-get update -qq
        sudo apt-get install -y code
        log "VS Code installed: $(code --version 2>/dev/null | head -1)"
    else
        log "VS Code already installed: $(code --version 2>/dev/null | head -1)"
    fi

    # ── Neovim — official binary release ──────────────────────────────────────
    if ! command -v nvim &>/dev/null; then
        log "Installing Neovim (binary release)…"
        local nvim_arch
        case "$ARCH" in
            x86_64)  nvim_arch="x86_64" ;;
            aarch64) nvim_arch="arm64"  ;;
            *)       err "Unsupported arch: $ARCH" ;;
        esac
        local tmpdir
        tmpdir=$(mktemp -d)
        local tag
        tag=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest \
              | grep '"tag_name"' | cut -d'"' -f4)
        curl -Lo "$tmpdir/nvim.tar.gz" \
            "https://github.com/neovim/neovim/releases/download/${tag}/nvim-linux-${nvim_arch}.tar.gz"
        tar -xzf "$tmpdir/nvim.tar.gz" -C "$tmpdir"
        sudo install -Dm755 "$tmpdir/nvim-linux-${nvim_arch}/bin/nvim" /usr/local/bin/nvim
        sudo cp -r "$tmpdir/nvim-linux-${nvim_arch}/share/nvim" /usr/local/share/
        rm -rf "$tmpdir"
        log "Neovim installed: $(nvim --version | head -1)"
    else
        log "Neovim already installed: $(nvim --version | head -1)"
    fi

    # ── Go ────────────────────────────────────────────────────────────────────
    if ! command -v go &>/dev/null; then
        log "Installing Go…"
        local go_version="1.23.0"
        local go_arch
        case "$ARCH" in
            x86_64)  go_arch="amd64" ;;
            aarch64) go_arch="arm64" ;;
        esac
        local tmpdir; tmpdir=$(mktemp -d)
        curl -Lo "$tmpdir/go.tar.gz" "https://go.dev/dl/go${go_version}.linux-${go_arch}.tar.gz"
        sudo tar -C /usr/local -xzf "$tmpdir/go.tar.gz"
        rm -rf "$tmpdir"
        log "Go installed"
    else
        log "Go already installed: $(go version)"
    fi

    # ── Node.js via NodeSource ─────────────────────────────────────────────────
    if ! command -v node &>/dev/null; then
        log "Installing Node.js…"
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
    else
        log "Node.js already installed: $(node --version)"
    fi

    # Ensure npm global installs go to ~/.local so no sudo is needed and the
    # binaries land in ~/.local/bin which is already in PATH.
    local npm_prefix
    npm_prefix=$(npm config get prefix 2>/dev/null || true)
    if [[ "$npm_prefix" != "$HOME/.local" ]]; then
        npm config set prefix "$HOME/.local"
        log "npm global prefix → ~/.local"
    fi
    # Make sure the newly configured prefix bin is in PATH for this session
    export PATH="$HOME/.local/bin:$PATH"

    # ── Claude Code CLI ────────────────────────────────────────────────────────
    if ! command -v claude &>/dev/null; then
        log "Installing Claude Code CLI…"
        npm install -g @anthropic-ai/claude-code || \
            warn "Claude Code install failed — run: npm install -g @anthropic-ai/claude-code"
    else
        log "Claude Code already installed: $(claude --version 2>/dev/null | head -1)"
    fi

    # ── bat (binary is called batcat on Ubuntu) ────────────────────────────────
    if ! command -v bat &>/dev/null && ! command -v batcat &>/dev/null; then
        log "Installing bat…"
        sudo apt-get install -y bat
    fi
    # Create bat symlink so scripts/aliases always use 'bat'
    if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        log "Created bat → batcat symlink in ~/.local/bin"
    fi

    # ── eza ───────────────────────────────────────────────────────────────────
    if ! command -v eza &>/dev/null; then
        log "Installing eza…"
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
            | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
            | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
        sudo apt-get update -qq
        sudo apt-get install -y eza
    else
        log "eza already installed"
    fi

    # ── zoxide ────────────────────────────────────────────────────────────────
    # Installs to ~/.local/bin — PATH is already extended above so command -v works
    if ! command -v zoxide &>/dev/null; then
        log "Installing zoxide…"
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    else
        log "zoxide already installed"
    fi

    # ── atuin ─────────────────────────────────────────────────────────────────
    # Installs to ~/.local/bin — PATH is already extended above so command -v works
    if ! command -v atuin &>/dev/null; then
        log "Installing atuin…"
        bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
    else
        log "atuin already installed"
    fi

    # ── git-delta ─────────────────────────────────────────────────────────────
    if ! command -v delta &>/dev/null; then
        log "Installing git-delta…"
        local delta_ver="0.17.0"
        local delta_arch
        case "$ARCH" in
            x86_64)  delta_arch="x86_64-unknown-linux-musl" ;;
            aarch64) delta_arch="aarch64-unknown-linux-musl" ;;
        esac
        local tmpdir; tmpdir=$(mktemp -d)
        curl -Lo "$tmpdir/delta.tar.gz" \
            "https://github.com/dandavison/delta/releases/download/${delta_ver}/delta-${delta_ver}-${delta_arch}.tar.gz"
        tar -xzf "$tmpdir/delta.tar.gz" -C "$tmpdir"
        sudo install -Dm755 "$tmpdir/delta-${delta_ver}-${delta_arch}/delta" /usr/local/bin/delta
        rm -rf "$tmpdir"
        log "git-delta installed"
    else
        log "git-delta already installed"
    fi

    # ── lazygit ───────────────────────────────────────────────────────────────
    if ! command -v lazygit &>/dev/null; then
        log "Installing lazygit…"
        local lg_ver
        lg_ver=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
                 | grep '"tag_name"' | cut -d'"' -f4 | sed 's/v//')
        local lg_arch
        case "$ARCH" in
            x86_64)  lg_arch="x86_64" ;;
            aarch64) lg_arch="arm64"  ;;
        esac
        local tmpdir; tmpdir=$(mktemp -d)
        curl -Lo "$tmpdir/lazygit.tar.gz" \
            "https://github.com/jesseduffield/lazygit/releases/download/v${lg_ver}/lazygit_${lg_ver}_Linux_${lg_arch}.tar.gz"
        tar -xzf "$tmpdir/lazygit.tar.gz" -C "$tmpdir"
        sudo install -Dm755 "$tmpdir/lazygit" /usr/local/bin/lazygit
        rm -rf "$tmpdir"
        log "lazygit installed"
    else
        log "lazygit already installed"
    fi
}

# ── Kitty terminal (Linux) ───────────────────────────────────────────────────
install_kitty_linux() {
    section "Kitty terminal"
    # Kitty installs to ~/.local/kitty.app and symlinks into ~/.local/bin
    if command -v kitty &>/dev/null; then
        log "Kitty already installed: $(kitty --version 2>/dev/null | head -1)"
        return
    fi
    log "Installing Kitty (official installer)…"
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
    mkdir -p "$HOME/.local/bin"
    ln -sf "$HOME/.local/kitty.app/bin/kitty"  "$HOME/.local/bin/kitty"
    ln -sf "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten"
    # Desktop entry so it appears in app launcher
    mkdir -p "$HOME/.local/share/applications"
    cp "$HOME/.local/kitty.app/share/applications/kitty.desktop" \
        "$HOME/.local/share/applications/" 2>/dev/null || true
    sed -i \
        "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" \
        "$HOME/.local/share/applications/kitty.desktop" 2>/dev/null || true
    log "Kitty installed — launch with: kitty"
}

# ── Nerd Font (Linux) ─────────────────────────────────────────────────────────
install_font_linux() {
    $SKIP_FONTS && return
    section "JetBrains Mono Nerd Font (Linux)"
    local font_dir="$HOME/.local/share/fonts"
    if ls "$font_dir"/JetBrainsMonoNerd* &>/dev/null 2>&1; then
        log "Font already installed"
        return
    fi
    log "Downloading JetBrains Mono Nerd Font…"
    mkdir -p "$font_dir"
    local tmpdir; tmpdir=$(mktemp -d)
    curl -Lo "$tmpdir/JetBrainsMono.zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip"
    unzip -q "$tmpdir/JetBrainsMono.zip" -d "$font_dir"
    fc-cache -fv "$font_dir" >/dev/null
    rm -rf "$tmpdir"
    log "Font installed — set your terminal to 'JetBrainsMonoNLNFM Regular'"
}

# ── pyenv ─────────────────────────────────────────────────────────────────────
install_pyenv() {
    section "pyenv"
    if [[ -d "$HOME/.pyenv" ]]; then
        log "pyenv already installed"
        return
    fi
    log "Installing pyenv…"
    curl -fsSL https://pyenv.run | bash
}

# ── Oh My Zsh ─────────────────────────────────────────────────────────────────
install_ohmyzsh() {
    section "Oh My Zsh"
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log "Oh My Zsh already installed"
        return
    fi
    log "Installing Oh My Zsh…"
    RUNZSH=no CHSH=no \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

# ── zsh plugins (for Linux / manual install) ──────────────────────────────────
install_zsh_plugins_custom() {
    local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

    if [[ ! -d "$custom/zsh-autosuggestions" ]]; then
        log "Installing zsh-autosuggestions…"
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
            "$custom/zsh-autosuggestions"
    else
        log "zsh-autosuggestions already present"
    fi

    if [[ ! -d "$custom/zsh-syntax-highlighting" ]]; then
        log "Installing zsh-syntax-highlighting…"
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
            "$custom/zsh-syntax-highlighting"
    else
        log "zsh-syntax-highlighting already present"
    fi
}

# ── Set default shell to zsh ──────────────────────────────────────────────────
set_zsh_default() {
    local zsh_path
    zsh_path=$(command -v zsh)
    if [[ "$SHELL" != "$zsh_path" ]]; then
        log "Setting zsh as default shell…"
        if ! grep -qx "$zsh_path" /etc/shells; then
            echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
        fi
        chsh -s "$zsh_path"
    else
        log "zsh is already the default shell"
    fi
}

# ── Persist tool paths to ~/.profile and ~/.bashrc (Linux) ───────────────────
# ~/.zshrc already handles zsh sessions. ~/.profile is sourced by GNOME and
# bash login shells, so all tools are reachable before/outside zsh.
setup_paths_linux() {
    section "Configuring PATH (~/.profile + ~/.bashrc)"

    local begin="# >>> dotfiles-paths >>>"
    local end="# <<< dotfiles-paths <<<"

    # Path block to inject
    local block
    block=$(cat << 'PATHBLOCK'
# >>> dotfiles-paths >>>
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
if [ -d "$HOME/.pyenv" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
fi
# <<< dotfiles-paths <<<
PATHBLOCK
)

    for rc in "$HOME/.profile" "$HOME/.bashrc"; do
        # Remove existing block (idempotent re-runs)
        if grep -q "$begin" "$rc" 2>/dev/null; then
            # Use temp file for portability
            local tmp; tmp=$(mktemp)
            awk "/$begin/{found=1} !found{print} /$end/{found=0}" "$rc" > "$tmp"
            mv "$tmp" "$rc"
        fi
        printf '\n%s\n' "$block" >> "$rc"
        log "PATH block written to $rc"
    done
}

# ── Bat Catppuccin theme ──────────────────────────────────────────────────────
install_bat_theme() {
    section "bat Catppuccin Mocha theme"
    local bat_cmd
    bat_cmd=$(command -v bat 2>/dev/null || command -v batcat 2>/dev/null || true)
    [[ -z "$bat_cmd" ]] && { warn "bat not found, skipping theme"; return; }

    local theme_dir
    theme_dir="$("$bat_cmd" --config-dir 2>/dev/null)/themes"
    mkdir -p "$theme_dir"

    if [[ -f "$theme_dir/Catppuccin Mocha.tmTheme" ]]; then
        log "bat Catppuccin Mocha theme already installed"
        return
    fi

    curl -Lo "$theme_dir/Catppuccin Mocha.tmTheme" \
        "https://github.com/catppuccin/bat/releases/download/v0.2.3/Catppuccin%20Mocha.tmTheme"
    "$bat_cmd" cache --build >/dev/null
    log "bat theme installed"
}

# ── Deploy core config symlinks ───────────────────────────────────────────────
deploy_configs() {
    section "Deploying configs (symlinks)"

    symlink "$DOTFILES/configs/zsh/zshrc"       "$HOME/.zshrc"
    symlink "$DOTFILES/configs/git/gitconfig"   "$HOME/.gitconfig"
    symlink "$DOTFILES/configs/tmux/tmux.conf"  "$HOME/.config/tmux/tmux.conf"

    backup_existing "$HOME/.config/nvim"
    ln -sf "$DOTFILES/configs/nvim" "$HOME/.config/nvim"
    log "Linked: nvim config dir"
    mkdir -p "$HOME/.vim/undodir"

    symlink "$DOTFILES/configs/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
}

# ── Deploy Claude Code config ─────────────────────────────────────────────────
deploy_claude_configs() {
    section "Deploying Claude configs (symlinks)"
    mkdir -p "$HOME/.claude"
    symlink "$DOTFILES/configs/claude/settings.json"          "$HOME/.claude/settings.json"
    symlink "$DOTFILES/configs/claude/statusline-command.sh"  "$HOME/.claude/statusline-command.sh"
    chmod +x "$DOTFILES/configs/claude/statusline-command.sh"
}

# ── TPM (tmux plugin manager) ─────────────────────────────────────────────────
install_tpm() {
    section "TPM — tmux plugin manager"
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ -d "$tpm_dir" ]]; then
        log "TPM already installed — pulling latest"
        git -C "$tpm_dir" pull --quiet
    else
        log "Cloning TPM…"
        git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm_dir"
    fi

    if command -v tmux &>/dev/null; then
        log "Installing tmux plugins headlessly…"
        "$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1 || true
        log "Plugins installed (or already up to date)"
    fi
}

# ── Neovim bootstrap ──────────────────────────────────────────────────────────
bootstrap_nvim() {
    $SKIP_NVIM && return
    section "Neovim — bootstrapping lazy.nvim plugins"
    if ! command -v nvim &>/dev/null; then
        warn "nvim not found, skipping bootstrap"
        return
    fi
    log "Running Lazy sync (first run may take a minute)…"
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || \
        nvim --headless -c "lua require('lazy').sync()" -c "qa" 2>/dev/null || \
        warn "Neovim bootstrap had warnings (normal on first run)"
    log "Neovim plugins installed"
}

# ── VS Code extensions ────────────────────────────────────────────────────────
install_vscode_extensions() {
    $SKIP_VSCODE && return
    section "VS Code extensions"

    if ! command -v code &>/dev/null; then
        warn "VS Code 'code' CLI not found — skipping extension install"
        warn "Install VS Code from: https://code.visualstudio.com/docs/setup/linux"
        return
    fi

    # Detect code-oss / VSCodium — they can't access Microsoft's marketplace.
    # The Microsoft build has marketplace.visualstudio.com in its product.json.
    local code_bin
    code_bin=$(readlink -f "$(command -v code)")
    local product_json
    product_json=$(dirname "$code_bin")/../resources/app/product.json
    if [[ -f "$product_json" ]] && ! grep -q "marketplace.visualstudio.com" "$product_json"; then
        warn "Detected code-oss / VSCodium — Microsoft marketplace extensions will fail."
        warn "Install official VS Code: https://code.visualstudio.com/docs/setup/linux"
        warn "Skipping extension install."
        return
    fi

    local extensions_file="$DOTFILES/configs/vscode/extensions.txt"
    local installed
    installed=$(code --list-extensions 2>/dev/null)

    while IFS= read -r ext; do
        [[ -z "$ext" || "$ext" == \#* ]] && continue
        if echo "$installed" | grep -qi "^${ext}$"; then
            log "Already installed: $ext"
        else
            log "Installing: $ext"
            local out attempt
            for attempt in 1 2; do
                if out=$(code --install-extension "$ext" 2>&1); then
                    break
                elif [[ $attempt -eq 1 ]]; then
                    warn "Retrying: $ext"
                    sleep 3
                else
                    warn "Failed to install: $ext"
                    warn "  └ $(echo "$out" | tail -1)"
                fi
            done
        fi
    done < "$extensions_file"

    local vscode_settings_dir
    if [[ "$OS" == "macos" ]]; then
        vscode_settings_dir="$HOME/Library/Application Support/Code/User"
    else
        vscode_settings_dir="$HOME/.config/Code/User"
    fi
    mkdir -p "$vscode_settings_dir"
    backup_existing "$vscode_settings_dir/settings.json"
    cp "$DOTFILES/configs/vscode/settings.json" "$vscode_settings_dir/settings.json"
    log "VS Code settings deployed"
}

# ── Final notes ───────────────────────────────────────────────────────────────
print_summary() {
    section "Done!"
    echo ""
    echo -e "  ${GREEN}What's installed / deployed:${NC}"
    echo "  • Neovim + lazy.nvim (all plugins)"
    echo "  • tmux + TPM plugins (One Dark Pro theme)"
    echo "  • Zsh + Oh My Zsh + autosuggestions + syntax-highlighting"
    echo "  • atuin (Ctrl+R history), zoxide (smart cd), eza, bat, lazygit"
    echo "  • pyenv, direnv, git-delta, fzf, ripgrep, fd"
    echo "  • Kitty terminal (Catppuccin Mocha)"
    echo "  • VS Code extensions + settings"
    echo "  • Claude Code CLI + statusline config"
    echo ""
    echo -e "  ${YELLOW}Manual steps remaining:${NC}"
    echo "  1. Open a new terminal (or run: exec zsh) — paths are now auto-loaded"
    echo "  2. Launch Kitty — font + theme are pre-configured"
    echo "  3. In Neovim, run :Lazy to verify plugins"
    echo "  4. In Neovim, run :Mason to install LSP servers (pyright, gopls, etc.)"
    echo "  5. Log in to Claude:  claude  (runs auth on first launch)"
    echo ""
    echo -e "  ${BLUE}Git config:${NC}  review ~/.gitconfig — update name/email if needed"
    echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    # ── Packages ──────────────────────────────────────────────────────────────
    if want packages; then
        if [[ "$OS" == "macos" ]]; then
            install_homebrew
            install_packages_macos
        else
            install_packages_linux
        fi
    fi

    # ── Fonts ─────────────────────────────────────────────────────────────────
    if want fonts; then
        [[ "$OS" == "macos" ]] && install_font_macos || install_font_linux
    fi

    # ── Kitty terminal ────────────────────────────────────────────────────────
    if want kitty; then
        [[ "$OS" == "linux" ]] && install_kitty_linux || log "Kitty: install via Homebrew (brew install --cask kitty)"
    fi

    # ── PATH setup (Linux — writes ~/.profile + ~/.bashrc) ───────────────────
    # Run whenever packages or zsh are being set up, or as a standalone target.
    if [[ "$OS" == "linux" ]] && { want packages || want zsh || want paths; }; then
        setup_paths_linux
    fi

    # ── Zsh stack ─────────────────────────────────────────────────────────────
    if want zsh; then
        install_pyenv
        install_ohmyzsh
        [[ "$OS" == "linux" ]] && install_zsh_plugins_custom
        set_zsh_default
    fi

    # ── pyenv standalone ──────────────────────────────────────────────────────
    # (also run as part of 'zsh'; this allows './install.sh pyenv' on its own)
    want pyenv && ! want zsh && install_pyenv

    # ── bat theme ─────────────────────────────────────────────────────────────
    want bat && install_bat_theme

    # ── Core config symlinks ──────────────────────────────────────────────────
    want configs && deploy_configs

    # ── Claude config symlinks ────────────────────────────────────────────────
    want claude && deploy_claude_configs

    # ── tmux plugins ─────────────────────────────────────────────────────────
    want tmux && install_tpm

    # ── Neovim plugin bootstrap ───────────────────────────────────────────────
    want nvim && bootstrap_nvim

    # ── VS Code ───────────────────────────────────────────────────────────────
    want vscode && install_vscode_extensions

    print_summary
}

main "$@"
