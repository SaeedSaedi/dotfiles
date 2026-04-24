#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  GNOME desktop setup — Ubuntu + GNOME (Catppuccin Mocha)
#
#  Full setup:   ./setup-gnome.sh
#  Partial:      ./setup-gnome.sh theme icons cursor extensions fonts dconf
#  Force re-install extensions: ./setup-gnome.sh extensions --force-extensions
#
#  Components: deps theme icons cursor extensions fonts dconf
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

ONLY=()
FORCE_EXTENSIONS=false
for arg in "$@"; do
    case "$arg" in
        --force-extensions) FORCE_EXTENSIONS=true ;;
        --*) echo "[!] Unknown flag: $arg" >&2 ;;
        *)   ONLY+=("$arg") ;;
    esac
done

want() { [[ ${#ONLY[@]} -eq 0 ]] || printf '%s\n' "${ONLY[@]}" | grep -qx "$1"; }

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

log()     { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
err()     { echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }
section() { echo -e "\n${BOLD}${BLUE}══════ $* ══════${NC}"; }

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ "$(uname -s)" != "Linux" ]] && err "This script is Linux-only."
command -v gsettings &>/dev/null || err "gsettings not found — are you on GNOME?"

GNOME_VERSION=$(gnome-shell --version 2>/dev/null | grep -oP '\d+\.\d+' | head -1 || echo "unknown")
GNOME_MAJOR=$(echo "$GNOME_VERSION" | cut -d. -f1)

section "GNOME setup  |  GNOME ${GNOME_VERSION}  |  $(lsb_release -ds 2>/dev/null || echo Linux)"
[[ ${#ONLY[@]} -gt 0 ]] && echo "  Components: ${ONLY[*]}"

backup_existing() {
    local t="$1"
    if [[ -e "$t" && ! -L "$t" ]]; then
        mv "$t" "${t}.bak.$(date +%Y%m%d_%H%M%S)"
        warn "Backed up: $t"
    fi
}

github_latest() {
    curl -sf "https://api.github.com/repos/$1/releases/latest" \
        | grep '"tag_name"' | cut -d'"' -f4
}

gsetting() {
    local schema="$1" key="$2" val="$3"
    if gsettings get "$schema" "$key" &>/dev/null 2>&1; then
        gsettings set "$schema" "$key" "$val"
        log "  $key = $val"
    else
        warn "  schema key not found: $schema $key"
    fi
}

main() {
    want deps       && install_deps
    want theme      && install_theme
    want icons      && install_icons
    want cursor     && install_cursor
    want extensions && install_extensions
    want fonts      && configure_fonts
    want dconf      && apply_dconf
    print_summary
}

# ── Placeholder stubs (filled below) ─────────────────────────────────────────
install_deps() {
    section "Dependencies"
    sudo apt-get update -qq
    sudo apt-get install -y \
        gnome-tweaks gnome-shell-extension-manager \
        dconf-cli dconf-editor \
        curl wget git unzip \
        papirus-icon-theme \
        libglib2.0-bin
    log "Dependencies installed"
}
install_theme() {
    section "Catppuccin Mocha GTK theme"
    # Release naming: catppuccin-mocha-blue-standard+default (+ is %2B in URL)
    local zip_name="catppuccin-mocha-blue-standard+default"
    local name="$zip_name"
    local dir="$HOME/.local/share/themes/$name"

    if [[ ! -d "$dir" ]]; then
        log "Downloading Catppuccin GTK theme…"
        local tag tmpdir
        tag=$(github_latest "catppuccin/gtk")
        tmpdir=$(mktemp -d)
        # %2B is URL-encoded + — GitHub requires this in the filename
        curl -fsSL -o "$tmpdir/theme.zip" \
            "https://github.com/catppuccin/gtk/releases/download/${tag}/catppuccin-mocha-blue-standard%2Bdefault.zip"
        mkdir -p "$HOME/.local/share/themes"
        unzip -q "$tmpdir/theme.zip" -d "$HOME/.local/share/themes/"
        rm -rf "$tmpdir"
        log "Theme installed: $name"
    else
        log "Theme already installed: $name"
    fi

    # GTK4 / libadwaita symlink
    local gtk4="$HOME/.config/gtk-4.0"
    mkdir -p "$gtk4"
    for f in gtk.css gtk-dark.css; do
        local src="$dir/gtk-4.0/$f"
        [[ -f "$src" ]] || continue
        if [[ ! -L "$gtk4/$f" ]]; then
            backup_existing "$gtk4/$f"
            ln -sf "$src" "$gtk4/$f"
            log "Linked: $f (libadwaita)"
        fi
    done

    gsettings set org.gnome.desktop.interface gtk-theme "$name"
    log "GTK theme applied"
}
install_icons() {
    section "Papirus-Dark icons + Catppuccin folders"

    if [[ ! -d /usr/share/icons/Papirus-Dark ]]; then
        log "Installing Papirus via PPA…"
        sudo add-apt-repository -y ppa:papirus/papirus 2>/dev/null || true
        sudo apt-get update -qq
        sudo apt-get install -y papirus-icon-theme
    else
        log "Papirus-Dark already installed"
    fi

    # Catppuccin folder colors — correct 3-step process:
    #   1. Copy catppuccin SVGs into the system Papirus dir
    #   2. Fetch the papirus-folders script (PapirusDevelopmentTeam)
    #   3. Run it with -C cat-mocha-blue --theme Papirus-Dark
    local stamp="$HOME/.local/share/icons/.catppuccin-papirus-mocha-blue"
    if [[ ! -f "$stamp" ]]; then
        log "Applying Catppuccin Mocha folder colors…"
        local tmpdir; tmpdir=$(mktemp -d)

        # Step 1: clone catppuccin/papirus-folders and copy SVGs into Papirus
        git clone --depth=1 --quiet \
            https://github.com/catppuccin/papirus-folders "$tmpdir/ctp-folders"
        sudo cp -r "$tmpdir/ctp-folders/src/"* /usr/share/icons/Papirus/
        log "Catppuccin SVGs copied to Papirus"

        # Step 2: get the papirus-folders color-switcher script
        curl -fsSL --max-time 15 \
            "https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders" \
            -o "$tmpdir/papirus-folders"
        chmod +x "$tmpdir/papirus-folders"

        # Step 3: apply Mocha Blue to Papirus-Dark
        "$tmpdir/papirus-folders" -C cat-mocha-blue --theme Papirus-Dark
        touch "$stamp"
        log "Catppuccin Mocha Blue folder colors applied"

        rm -rf "$tmpdir"
    else
        log "Catppuccin folder colors already applied"
    fi

    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
    log "Icon theme applied"
}
install_cursor() {
    section "Catppuccin Mocha cursors"
    local name="catppuccin-mocha-dark-cursors"
    local dir="$HOME/.local/share/icons/$name"

    if [[ ! -d "$dir" ]]; then
        log "Downloading Catppuccin cursors…"
        local tag tmpdir
        tag=$(github_latest "catppuccin/cursors")
        tmpdir=$(mktemp -d)
        curl -fsSL -o "$tmpdir/cursors.zip" \
            "https://github.com/catppuccin/cursors/releases/download/${tag}/${name}.zip"
        mkdir -p "$HOME/.local/share/icons"
        unzip -q "$tmpdir/cursors.zip" -d "$HOME/.local/share/icons/"
        rm -rf "$tmpdir"
        log "Cursors installed: $name"
    else
        log "Cursors already installed"
    fi

    gsettings set org.gnome.desktop.interface cursor-theme "$name"
    gsettings set org.gnome.desktop.interface cursor-size  24
    log "Cursor theme applied"
}
_install_ext() {
    local uuid="$1"
    local extdir="$HOME/.local/share/gnome-shell/extensions/$uuid"
    if [[ -d "$extdir" ]] && ! $FORCE_EXTENSIONS; then
        log "Already installed: $uuid"; return 0
    fi
    local ver="${GNOME_VERSION}"
    local info
    info=$(curl -sf --max-time 15 \
        "https://extensions.gnome.org/extension-info/?uuid=${uuid}&shell_version=${ver}" \
        2>/dev/null || true)
    # fall back to major version if exact not found
    if [[ -z "$info" ]]; then
        info=$(curl -sf --max-time 15 \
            "https://extensions.gnome.org/extension-info/?uuid=${uuid}&shell_version=${GNOME_MAJOR}" \
            2>/dev/null || true)
    fi
    if [[ -z "$info" ]]; then
        warn "Not available on EGO for GNOME $ver: $uuid"; return 1
    fi
    # JSON has a space after colon: "download_url": "/path" — use jq, fall back to grep with optional space
    local dl_url
    dl_url=$(echo "$info" | python3 -c "import sys,json; print(json.load(sys.stdin).get('download_url',''))" 2>/dev/null || true)
    # dl_url is a path like /download-extension/... — prepend base only if it starts with /
    local full_url
    if [[ "$dl_url" == /* ]]; then
        full_url="https://extensions.gnome.org${dl_url}"
    else
        full_url="https://extensions.gnome.org/download-extension/${uuid}.shell-extension.zip?shell_version=${ver}"
    fi
    local tmpdir; tmpdir=$(mktemp -d)
    if ! curl -fsSL --max-time 30 -o "$tmpdir/ext.zip" "$full_url" 2>/dev/null; then
        warn "Download failed: $uuid"; rm -rf "$tmpdir"; return 1
    fi
    mkdir -p "$extdir"
    unzip -q -o "$tmpdir/ext.zip" -d "$extdir"
    rm -rf "$tmpdir"
    gnome-extensions enable "$uuid" 2>/dev/null && \
        log "Installed + enabled: $uuid" || \
        log "Installed (re-login to enable): $uuid"
}

install_extensions() {
    section "GNOME Shell extensions"
    mkdir -p "$HOME/.local/share/gnome-shell/extensions"
    local failed=()
    local exts=(
        "blur-my-shell@aunetx"
        "just-perfection-desktop@just-perfection"
        "dash-to-dock@micxgx.gmail.com"
        "forge@jmmaranan.com"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "caffeine@patapon.info"
        "appindicatorsupport@rgcjonas.gmail.com"
    )
    for uuid in "${exts[@]}"; do
        _install_ext "$uuid" || failed+=("$uuid")
    done
    if [[ ${#failed[@]} -gt 0 ]]; then
        warn "Failed extensions (install manually at extensions.gnome.org):"
        for u in "${failed[@]}"; do warn "  • $u"; done
        warn "Or retry: ./setup-gnome.sh extensions --force-extensions"
    fi
}
configure_fonts() {
    section "System fonts"
    # Refresh cache so fc-list reflects fonts in ~/.local/share/fonts
    fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null || true

    local font_dir="$HOME/.local/share/fonts"
    local mono_font="Monospace 11"
    if ls "$font_dir"/JetBrainsMonoNerdFontMono-Regular* &>/dev/null 2>&1; then
        mono_font="JetBrainsMono Nerd Font Mono Regular 11"
        log "Nerd Font: JetBrainsMono Nerd Font Mono"
    elif ls "$font_dir"/JetBrainsMono* &>/dev/null 2>&1; then
        mono_font="JetBrainsMono Nerd Font Regular 11"
        log "Nerd Font: JetBrainsMono Nerd Font"
    else
        warn "JetBrains Mono Nerd Font not found — run: ./install.sh fonts && ./setup-gnome.sh fonts"
    fi

    # Install Inter for UI
    local ui_font="Cantarell 11"
    if ! fc-list | grep -qi "Inter"; then
        log "Installing Inter UI font…"
        local tmpdir; tmpdir=$(mktemp -d)
        curl -fsSL -o "$tmpdir/inter.zip" \
            "https://github.com/rsms/inter/releases/latest/download/Inter.zip" 2>/dev/null || true
        if [[ -f "$tmpdir/inter.zip" ]]; then
            mkdir -p "$HOME/.local/share/fonts/inter"
            unzip -q "$tmpdir/inter.zip" "*.ttf" -d "$HOME/.local/share/fonts/inter" 2>/dev/null || true
            fc-cache -f "$HOME/.local/share/fonts/inter" 2>/dev/null || true
            ui_font="Inter 11"
            log "Inter font installed"
        fi
        rm -rf "$tmpdir"
    else
        ui_font="Inter 11"
        log "Inter already installed"
    fi

    gsettings set org.gnome.desktop.interface font-name           "$ui_font"
    gsettings set org.gnome.desktop.interface document-font-name  "$ui_font"
    gsettings set org.gnome.desktop.interface monospace-font-name "$mono_font"
    gsettings set org.gnome.desktop.wm.preferences titlebar-font  "Inter Bold 11"
    gsettings set org.gnome.desktop.interface font-antialiasing   "rgba"
    gsettings set org.gnome.desktop.interface font-hinting        "slight"
    log "Fonts configured"
}
apply_dconf() {
    section "Applying GNOME settings"
    local iface="org.gnome.desktop.interface"
    local wm="org.gnome.desktop.wm.preferences"
    local power="org.gnome.settings-daemon.plugins.power"
    local color="org.gnome.settings-daemon.plugins.color"
    local tp="org.gnome.desktop.peripherals.touchpad"

    # Appearance
    gsetting "$iface"  color-scheme              "prefer-dark"
    gsetting "$iface"  gtk-theme                 "catppuccin-mocha-blue-standard+default"
    gsetting "$iface"  icon-theme                "Papirus-Dark"
    gsetting "$iface"  cursor-theme              "catppuccin-mocha-dark-cursors"
    gsetting "$iface"  cursor-size               24
    gsetting "$iface"  enable-hot-corners        false
    gsetting "$iface"  show-battery-percentage   true

    # Shell theme — write the value unconditionally; the extension picks it up on load.
    # Also try to enable the extension via D-Bus (works inside a live GNOME session).
    local ut_uuid="user-theme@gnome-shell-extensions.gcampax.github.com"
    local ut_dir="$HOME/.local/share/gnome-shell/extensions/$ut_uuid"
    if [[ -d "$ut_dir" ]]; then
        gnome-extensions enable "$ut_uuid" 2>/dev/null && \
            log "user-theme extension enabled" || \
            log "user-theme installed — will activate on next login"
        # Write directly via dconf — no schema registration required
        dconf write /org/gnome/shell/extensions/user-theme/name \
            "'catppuccin-mocha-blue-standard+default'" && \
            log "Shell theme set: catppuccin-mocha-blue-standard+default" || \
            warn "dconf write failed — re-run after login"
    else
        warn "user-theme extension not installed — run: ./setup-gnome.sh extensions"
    fi

    # Window manager
    gsetting "$wm" button-layout    "close,minimize,maximize:"
    gsetting "$wm" focus-mode       "click"
    gsetting "$wm" num-workspaces   4

    # Workspaces
    gsetting org.gnome.mutter dynamic-workspaces    false
    gsetting org.gnome.mutter center-new-windows    true

    # Clock
    gsetting "$iface" clock-format      "24h"
    gsetting "$iface" clock-show-weekday true
    gsetting org.gnome.desktop.calendar show-weekdate true

    # Touchpad
    gsetting "$tp" tap-to-click              true
    gsetting "$tp" natural-scroll            true
    gsetting "$tp" two-finger-scrolling-enabled true

    # Power / idle
    gsetting "$power" sleep-inactive-ac-timeout      1800
    gsetting "$power" sleep-inactive-battery-timeout  900
    gsetting org.gnome.desktop.session idle-delay     600

    # Night light
    gsetting "$color" night-light-enabled             true
    gsetting "$color" night-light-temperature         3500
    gsetting "$color" night-light-schedule-automatic  true

    # Privacy
    gsetting org.gnome.desktop.privacy remember-recent-files false
    gsetting org.gnome.desktop.privacy old-files-age         "uint32 30"

    # Keyboard shortcut: Super+E → Files, Super+T → Kitty
    gsetting org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"
    local kitty="$HOME/.local/bin/kitty"
    if [[ -x "$kitty" ]]; then
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
            "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']" 2>/dev/null || true
        local kb="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0"
        gsettings set "$kb" name    "Kitty Terminal"  2>/dev/null || true
        gsettings set "$kb" command "$kitty"          2>/dev/null || true
        gsettings set "$kb" binding "<Super>t"        2>/dev/null || true
        log "Shortcut: Super+T → Kitty"
    fi

    local ext_base="$HOME/.local/share/gnome-shell/extensions"

    # Extension settings written via dconf directly — schemas may not be active
    # until GNOME Shell loads the extension on next login.
    local dconf_ext="/org/gnome/shell/extensions"

    if [[ -d "$ext_base/blur-my-shell@aunetx" ]]; then
        dconf write "$dconf_ext/blur-my-shell/brightness" "0.75" 2>/dev/null || true
        dconf write "$dconf_ext/blur-my-shell/sigma"      "15"   2>/dev/null || true
        log "Blur my Shell settings written"
    fi

    if [[ -d "$ext_base/just-perfection-desktop@just-perfection" ]]; then
        dconf write "$dconf_ext/just-perfection/animation" "3"     2>/dev/null || true
        dconf write "$dconf_ext/just-perfection/dash"      "false" 2>/dev/null || true
        log "Just Perfection settings written"
    fi

    if [[ -d "$ext_base/dash-to-dock@micxgx.gmail.com" ]]; then
        dconf write "$dconf_ext/dash-to-dock/dock-position"      "'BOTTOM'" 2>/dev/null || true
        dconf write "$dconf_ext/dash-to-dock/extend-height"      "false"    2>/dev/null || true
        dconf write "$dconf_ext/dash-to-dock/dock-fixed"         "false"    2>/dev/null || true
        dconf write "$dconf_ext/dash-to-dock/autohide"           "true"     2>/dev/null || true
        dconf write "$dconf_ext/dash-to-dock/intellihide"        "true"     2>/dev/null || true
        dconf write "$dconf_ext/dash-to-dock/dash-max-icon-size" "40"       2>/dev/null || true
        log "Dash to Dock settings written"
    fi

    log "All settings applied"
}
print_summary() {
    section "Done!"
    echo ""
    echo -e "  ${GREEN}Configured:${NC}"
    echo "  • Catppuccin Mocha GTK theme (GTK3 + GTK4/libadwaita)"
    echo "  • Papirus-Dark icons with Catppuccin folder colors"
    echo "  • Catppuccin Mocha Dark cursors"
    echo "  • GNOME extensions: Blur my Shell, Just Perfection, Dash to Dock, Pop Shell"
    echo "  • Inter UI font + JetBrains Mono Nerd Font (monospace)"
    echo "  • Dark mode, 24h clock, Night Light, touchpad tap-to-click"
    echo "  • Keyboard shortcuts: Super+E → Files, Super+T → Kitty"
    echo ""
    echo -e "  ${YELLOW}Required follow-up steps:${NC}"
    echo ""

    if ! fc-list | grep -qi "JetBrainsMono"; then
        echo -e "  ${RED}[missing]${NC} Nerd Font not installed yet:"
        echo "           ./install.sh fonts"
        echo "           ./setup-gnome.sh fonts   ← apply to GNOME after"
        echo ""
    fi

    echo "  1. Log out and back in — extensions activate on next GNOME session"
    echo "  2. After login, apply shell theme:"
    echo "     ./setup-gnome.sh dconf"
    echo "  3. Forge tiling: Super+Alt+H/J/K/L to tile windows"
    echo ""
    echo -e "  ${BLUE}Re-run individual components:${NC}"
    echo "  ./setup-gnome.sh theme | icons | cursor | extensions | fonts | dconf"
    echo ""
}

main "$@"
