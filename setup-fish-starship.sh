#!/usr/bin/env bash
set -e

# ===========================
# Helper Functions
# ===========================
log() { echo -e "\e[32m[INFO]\e[0m $1"; }
error() { echo -e "\e[31m[ERROR]\e[0m $1"; }
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# ===========================
# 1. Install Fish and set default shell
# ===========================
if ! command -v fish >/dev/null 2>&1; then
    DISTRO=$(detect_distro)
    log "Installing Fish shell for $DISTRO..."
    case "$DISTRO" in
        ubuntu)
            sudo apt-add-repository ppa:fish-shell/release-3
            sudo apt update && sudo apt install -y fish
            ;;
        arch)
            sudo pacman -Sy --noconfirm fish
            ;;
        fedora)
            sudo dnf install -y fish
            ;;
        *)
            error "Unsupported distro: $DISTRO. Install fish manually."
            ;;
    esac
else
    log "Fish shell already installed"
fi

# Set fish as default shell if not already
if [ "$SHELL" != "$(which fish)" ]; then
    log "Setting fish as default shell..."
    chsh -s "$(which fish)" || error "Could not change default shell. Run manually."
else
    log "Fish is already the default shell"
fi

# ===========================
# 2. Set Fish greeting to nothing
# ===========================
FISH_CONFIG="$HOME/.config/fish/config.fish"
mkdir -p "$(dirname "$FISH_CONFIG")"
if ! grep -q "set -g fish_greeting" "$FISH_CONFIG" 2>/dev/null; then
    log "Disabling fish greeting..."
    echo "set -g fish_greeting ''" >> "$FISH_CONFIG"
else
    log "Fish greeting already disabled"
fi

# ===========================
# 3. Install Starship
# ===========================
if ! command -v starship >/dev/null 2>&1; then
    log "Installing Starship prompt..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    log "Starship already installed"
fi

# Add Starship init to fish config if not present
if ! grep -q "starship init fish" "$FISH_CONFIG"; then
    log "Adding Starship initialization to fish config..."
    echo "starship init fish | source" >> "$FISH_CONFIG"
else
    log "Starship already initialized in fish config"
fi

# ===========================
# 4. Download Starship template
# ===========================
STARSHIP_FILE="$HOME/.config/starship.toml"
STARSHIP_TEMPLATE_URL="https://raw.githubusercontent.com/Galgathor/server-config/main/templates/starship.toml"

if [ ! -f "$STARSHIP_FILE" ]; then
    log "Downloading starship template ($TEMPLATE_NAME) for $DISTRO..."
    curl -fsSL "$STARSHIP_TEMPLATE_URL" -o "$STARSHIP_FILE" || error "Failed to download starship template"
else
    log "Starship template already exists"
fi

# ===========================
# 5. Delete script after execution
# ===========================
SCRIPT_PATH="${BASH_SOURCE[0]}"
log "Cleaning up..."
rm -f "$SCRIPT_PATH"

log "Setup complete! Restart your terminal or run 'fish' to start using Fish with Starship."
