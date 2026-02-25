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

BASH_CONFIG="$HOME/.bashrc"
DISTRO=$(detect_distro)

# ===========================
# 1. Install Dependencies
# ===========================
log "Detected Distro: $DISTRO"
log "Installing dependencies for ble.sh and Starship..."

case "$DISTRO" in
    ubuntu|debian|raspbian)
        sudo apt update && sudo apt install -y git make gawk curl
        ;;
    arch|manjaro)
        sudo pacman -Sy --noconfirm git make gawk curl
        ;;
    fedora)
        sudo dnf install -y git make gawk curl
        ;;
    *)
        log "Warning: Unknown distro. Attempting to use 'apt' as a fallback..."
        sudo apt update && sudo apt install -y git make gawk curl || error "Could not install dependencies."
        ;;
esac

# ===========================
# 2. Install ble.sh (Bash Line Editor)
# ===========================
if [ ! -d "$HOME/.local/share/blesh" ]; then
    log "Cloning and installing ble.sh (this provides Fish-like features)..."
    git clone --recursive --depth 1 https://github.com/akinomyoga/ble.sh.git
    make -C ble.sh install PREFIX=~/.local
    rm -rf ble.sh
else
    log "ble.sh already installed"
fi

# Inject ble.sh into .bashrc (Top and Bottom)
if ! grep -q "blesh/ble.sh" "$BASH_CONFIG"; then
    log "Adding ble.sh hooks to $BASH_CONFIG..."
    # Add to top (required for keybinding interception)
    sed -i '1i [[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh --noattach' "$BASH_CONFIG"
    # Add to bottom (required to trigger the attach)
    echo '[[ ${BLE_VERSION-} ]] && ble-attach' >> "$BASH_CONFIG"
fi

# ===========================
# 3. Install Starship
# ===========================
if ! command -v starship >/dev/null 2>&1; then
    log "Installing Starship prompt (ARM compatible)..."
    # The official Starship script automatically detects ARM/Raspberry Pi architecture
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    log "Starship already installed"
fi

# Add Starship init for BASH
if ! grep -q "starship init bash" "$BASH_CONFIG"; then
    log "Adding Starship initialization to $BASH_CONFIG..."
    echo 'eval "$(starship init bash)"' >> "$BASH_CONFIG"
fi

# ===========================
# 4. Download Starship template
# ===========================
STARSHIP_DIR="$HOME/.config"
STARSHIP_FILE="$STARSHIP_DIR/starship.toml"
STARSHIP_TEMPLATE_URL="https://raw.githubusercontent.com/Galgathor/server-config/main/templates/starship.toml"

mkdir -p "$STARSHIP_DIR"
if [ ! -f "$STARSHIP_FILE" ]; then
    log "Downloading custom Starship template..."
    curl -fsSL "$STARSHIP_TEMPLATE_URL" -o "$STARSHIP_FILE" || error "Failed to download starship template"
else
    log "Starship configuration already exists at $STARSHIP_FILE"
fi

# ===========================
# 5. Delete script after execution
# ===========================
SCRIPT_PATH="${BASH_SOURCE[0]}"
log "Cleaning up setup script..."
rm -f "$SCRIPT_PATH"

log "Done! Your terminal is now enhanced."
log "Please run: source ~/.bashrc"