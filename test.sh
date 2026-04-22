#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  Dotfiles smoke tests
#
#  Run after ./install.sh to verify the environment is correctly set up.
#
#  Usage:
#    ./test.sh              # run all tests
#    ./test.sh tools        # only tool / binary checks
#    ./test.sh symlinks     # only config symlink checks
#    ./test.sh vscode       # only VS Code extension checks
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

PASS=0; FAIL=0; SKIP=0
FAILED_TESTS=()

# ── Helpers ───────────────────────────────────────────────────────────────────
section() { echo -e "\n${BOLD}${BLUE}══════ $* ══════${NC}"; }

pass() {
    echo -e "  ${GREEN}✓${NC}  $*"
    (( PASS++ )) || true
}

fail() {
    echo -e "  ${RED}✗${NC}  $*"
    (( FAIL++ )) || true
    FAILED_TESTS+=("$*")
}

skip() {
    echo -e "  ${YELLOW}–${NC}  $* (skipped)"
    (( SKIP++ )) || true
}

warn() {
    echo -e "  ${YELLOW}[!]${NC}  $*"
}

# check_cmd <display-name> <command...>
check_cmd() {
    local name="$1"; shift
    if command -v "$1" &>/dev/null; then
        local ver
        ver=$("$1" --version 2>/dev/null | head -1 || true)
        pass "$name  →  ${ver:-$(command -v "$1")}"
    else
        fail "$name  →  not found in PATH"
    fi
}

# check_symlink <display-name> <path> [<expected-target-substring>]
check_symlink() {
    local name="$1" path="$2" substr="${3:-}"
    if [[ ! -e "$path" ]]; then
        fail "$name  →  $path does not exist"
    elif [[ ! -L "$path" ]]; then
        fail "$name  →  $path exists but is not a symlink"
    elif [[ -n "$substr" ]] && ! readlink "$path" | grep -q "$substr"; then
        fail "$name  →  symlink target doesn't contain '$substr'  ($(readlink "$path"))"
    else
        pass "$name  →  $(readlink "$path")"
    fi
}

# check_file <display-name> <path>
check_file() {
    local name="$1" path="$2"
    if [[ -f "$path" ]]; then
        pass "$name  →  $path"
    else
        fail "$name  →  $path not found"
    fi
}

# check_dir <display-name> <path>
check_dir() {
    local name="$1" path="$2"
    if [[ -d "$path" ]]; then
        pass "$name  →  $path"
    else
        fail "$name  →  $path not found"
    fi
}

# ── OS detection ──────────────────────────────────────────────────────────────
IS_MACOS=false
[[ "$OSTYPE" == "darwin"* ]] && IS_MACOS=true

# Extend PATH the same way install.sh does so tests reflect the installed state
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:/usr/local/go/bin:$HOME/go/bin:$PATH"

# ── Scope selection ───────────────────────────────────────────────────────────
ONLY="${1:-all}"

want() { [[ "$ONLY" == "all" || "$ONLY" == "$1" ]]; }

# ─────────────────────────────────────────────────────────────────────────────
#  1. Required tools
# ─────────────────────────────────────────────────────────────────────────────
if want tools; then
    section "Core tools"

    check_cmd "zsh"       zsh
    check_cmd "nvim"      nvim
    check_cmd "tmux"      tmux
    check_cmd "git"       git
    check_cmd "curl"      curl
    check_cmd "jq"        jq
    check_cmd "gh"        gh

    section "Modern CLI tools"

    # bat may be called batcat on Ubuntu
    if command -v bat &>/dev/null; then
        pass "bat  →  $(bat --version 2>/dev/null | head -1)"
    elif command -v batcat &>/dev/null; then
        pass "bat (batcat)  →  $(batcat --version 2>/dev/null | head -1)"
    else
        fail "bat  →  neither bat nor batcat found"
    fi

    check_cmd "eza"      eza
    check_cmd "fzf"      fzf
    check_cmd "zoxide"   zoxide
    check_cmd "lazygit"  lazygit
    check_cmd "delta"    delta
    check_cmd "rg"       rg

    # fd may be called fdfind on Ubuntu
    if command -v fd &>/dev/null; then
        pass "fd  →  $(fd --version 2>/dev/null | head -1)"
    elif command -v fdfind &>/dev/null; then
        pass "fd (fdfind)  →  $(fdfind --version 2>/dev/null | head -1)"
    else
        fail "fd  →  neither fd nor fdfind found"
    fi

    check_cmd "direnv"   direnv

    section "Language runtimes"

    check_cmd "go"       go
    check_cmd "node"     node
    check_cmd "npm"      npm
    check_cmd "python3"  python3
    check_cmd "pyenv"    pyenv

    section "Optional tools"

    if command -v atuin &>/dev/null; then
        pass "atuin  →  $(atuin --version 2>/dev/null | head -1)"
    else
        skip "atuin  →  not installed (optional)"
    fi

    if command -v kitty &>/dev/null; then
        pass "kitty  →  $(kitty --version 2>/dev/null | head -1)"
    else
        skip "kitty  →  not installed (optional)"
    fi

    if command -v claude &>/dev/null; then
        pass "claude  →  $(claude --version 2>/dev/null | head -1)"
    else
        skip "claude  →  not installed (optional)"
    fi

    check_cmd "code"     code

    # npm global prefix check (Linux only — must be ~/.local to avoid sudo)
    if ! $IS_MACOS; then
        section "npm configuration"
        local_prefix="$HOME/.local"
        actual_prefix=$(npm config get prefix 2>/dev/null || echo "unknown")
        if [[ "$actual_prefix" == "$local_prefix" ]]; then
            pass "npm prefix  →  $actual_prefix (no sudo needed)"
        else
            fail "npm prefix  →  $actual_prefix  (expected $local_prefix — run: npm config set prefix ~/.local)"
        fi
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
#  2. Config symlinks
# ─────────────────────────────────────────────────────────────────────────────
if want symlinks; then
    section "Config symlinks"

    check_symlink "zshrc"       "$HOME/.zshrc"                        "configs/zsh/zshrc"
    check_symlink "gitconfig"   "$HOME/.gitconfig"                    "configs/git/gitconfig"
    check_symlink "tmux.conf"   "$HOME/.config/tmux/tmux.conf"        "configs/tmux/tmux.conf"
    check_symlink "nvim dir"    "$HOME/.config/nvim"                  "configs/nvim"
    check_symlink "kitty.conf"  "$HOME/.config/kitty/kitty.conf"      "configs/kitty/kitty.conf"

    section "Claude Code config"

    check_symlink "claude settings"   "$HOME/.claude/settings.json"         "configs/claude/settings.json"
    check_symlink "claude statusline" "$HOME/.claude/statusline-command.sh"  "configs/claude/statusline-command.sh"

    if [[ -f "$HOME/.claude/statusline-command.sh" ]]; then
        if [[ -x "$HOME/.claude/statusline-command.sh" ]]; then
            pass "statusline-command.sh is executable"
        else
            fail "statusline-command.sh is not executable"
        fi
    fi

    section "VS Code settings"

    if $IS_MACOS; then
        vsc_settings="$HOME/Library/Application Support/Code/User/settings.json"
    else
        vsc_settings="$HOME/.config/Code/User/settings.json"
    fi
    check_file "VS Code settings.json" "$vsc_settings"
fi

# ─────────────────────────────────────────────────────────────────────────────
#  3. Config file validity
# ─────────────────────────────────────────────────────────────────────────────
if want configs; then
    section "Config file validity"

    # zshrc: basic syntax check
    if [[ -f "$HOME/.zshrc" ]]; then
        if zsh -n "$HOME/.zshrc" 2>/dev/null; then
            pass "zshrc  →  syntax OK"
        else
            fail "zshrc  →  syntax errors detected (run: zsh -n ~/.zshrc)"
        fi
    else
        fail "zshrc  →  not found"
    fi

    # tmux: version and config check
    if command -v tmux &>/dev/null && [[ -f "$HOME/.config/tmux/tmux.conf" ]]; then
        if tmux -f "$HOME/.config/tmux/tmux.conf" new-session -d -s __test__ 2>/dev/null; then
            pass "tmux config  →  loads without errors"
            tmux kill-session -t __test__ 2>/dev/null || true
        else
            # tmux might already be running — just check it can parse the config
            if tmux -f "$HOME/.config/tmux/tmux.conf" list-keys &>/dev/null 2>&1; then
                pass "tmux config  →  parses OK"
            else
                fail "tmux config  →  errors when loading (run: tmux -f ~/.config/tmux/tmux.conf)"
            fi
        fi
    fi

    # kitty config: basic presence check
    if [[ -f "$HOME/.config/kitty/kitty.conf" ]]; then
        if grep -q "font_family" "$HOME/.config/kitty/kitty.conf"; then
            pass "kitty.conf  →  font config present"
        else
            fail "kitty.conf  →  font_family not set"
        fi
        if grep -q "Catppuccin\|#1e1e2e" "$HOME/.config/kitty/kitty.conf"; then
            pass "kitty.conf  →  Catppuccin Mocha colors present"
        else
            fail "kitty.conf  →  color theme not found"
        fi
    else
        skip "kitty.conf  →  not deployed"
    fi

    # bat theme
    if command -v bat &>/dev/null || command -v batcat &>/dev/null; then
        bat_cmd=$(command -v bat 2>/dev/null || command -v batcat 2>/dev/null)
        if "$bat_cmd" --list-themes 2>/dev/null | grep -q "Catppuccin Mocha"; then
            pass "bat theme  →  Catppuccin Mocha available"
        else
            fail "bat theme  →  Catppuccin Mocha not installed (run: ./install.sh bat)"
        fi
    fi

    # pyenv: check it can be initialised
    if [[ -d "$HOME/.pyenv" ]]; then
        if [[ -x "$HOME/.pyenv/bin/pyenv" ]]; then
            pass "pyenv  →  $("$HOME/.pyenv/bin/pyenv" --version)"
        else
            fail "pyenv  →  directory exists but binary missing"
        fi
    else
        skip "pyenv  →  not installed"
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
#  4. Shell environment (PATH, default shell)
# ─────────────────────────────────────────────────────────────────────────────
if want shell; then
    section "Shell environment"

    # Default shell
    default_shell=$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || \
                    dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')
    if echo "$default_shell" | grep -q "zsh"; then
        pass "Default login shell  →  $default_shell"
    else
        fail "Default login shell  →  $default_shell  (expected zsh — run: chsh -s $(command -v zsh))"
    fi

    # PATH sanity
    for dir in "$HOME/.local/bin" "$HOME/go/bin"; do
        if echo "$PATH" | tr ':' '\n' | grep -qx "$dir"; then
            pass "PATH includes  →  $dir"
        else
            fail "PATH missing   →  $dir  (re-open terminal or source ~/.profile)"
        fi
    done

    # Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        pass "Oh My Zsh  →  installed"
    else
        fail "Oh My Zsh  →  not found at ~/.oh-my-zsh"
    fi

    # Autosuggestions plugin
    omz_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if $IS_MACOS; then
        brew_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"
        if [[ -f "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] || \
           [[ -d "$omz_custom/plugins/zsh-autosuggestions" ]]; then
            pass "zsh-autosuggestions  →  installed"
        else
            fail "zsh-autosuggestions  →  not found"
        fi
    else
        if [[ -d "$omz_custom/plugins/zsh-autosuggestions" ]]; then
            pass "zsh-autosuggestions  →  $omz_custom/plugins/zsh-autosuggestions"
        else
            fail "zsh-autosuggestions  →  not found in $omz_custom/plugins/"
        fi
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
#  5. Fonts
# ─────────────────────────────────────────────────────────────────────────────
if want fonts; then
    section "Fonts"
    if $IS_MACOS; then
        font_dir="$HOME/Library/Fonts"
    else
        font_dir="$HOME/.local/share/fonts"
    fi
    if ls "$font_dir"/JetBrainsMonoNerd* &>/dev/null 2>&1 || \
       ls "$font_dir"/JetBrainsMono* &>/dev/null 2>&1; then
        pass "JetBrains Mono Nerd Font  →  found in $font_dir"
    else
        fail "JetBrains Mono Nerd Font  →  not found in $font_dir  (run: ./install.sh fonts)"
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
#  6. VS Code extensions
# ─────────────────────────────────────────────────────────────────────────────
if want vscode; then
    section "VS Code extensions"

    if ! command -v code &>/dev/null; then
        skip "code CLI not found — cannot check extensions"
    else
        installed=$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')
        extensions_file="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/configs/vscode/extensions.txt"
        missing=0

        while IFS= read -r ext; do
            [[ -z "$ext" || "$ext" == \#* ]] && continue
            ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
            if echo "$installed" | grep -qx "$ext_lower"; then
                pass "$ext"
            else
                fail "$ext  →  not installed"
                (( missing++ )) || true
            fi
        done < "$extensions_file"

        if [[ $missing -eq 0 ]]; then
            echo ""
            echo -e "  ${GREEN}All VS Code extensions are installed.${NC}"
        else
            echo ""
            warn "$missing extension(s) missing. Run: ./install.sh vscode"
        fi
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
#  Summary
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${BLUE}══════ Test Results ══════${NC}"
echo -e "  ${GREEN}Passed:${NC}  $PASS"
echo -e "  ${RED}Failed:${NC}  $FAIL"
echo -e "  ${YELLOW}Skipped:${NC} $SKIP"
echo ""

if [[ $FAIL -gt 0 ]]; then
    echo -e "${BOLD}${RED}Failed checks:${NC}"
    for t in "${FAILED_TESTS[@]}"; do
        echo -e "  ${RED}✗${NC}  $t"
    done
    echo ""
    exit 1
else
    echo -e "${GREEN}${BOLD}All checks passed.${NC}"
    echo ""
    exit 0
fi
