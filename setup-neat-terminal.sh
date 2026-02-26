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

# Change directory to $HOME to ensure all operations are done in the user's home directory
cd "$HOME"

# ===========================
# 1. Install Dependencies
# ===========================
log "Installing dependencies for ble.sh and Starship on $DISTRO..."
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
        log "Unknown distro, attempting apt fallback..."
        sudo apt update && sudo apt install -y git make gawk curl || error "Could not install dependencies."
        ;;
esac

# ===========================
# 2. Install ble.sh
# ===========================
if [ ! -d "$HOME/.local/share/blesh" ]; then
    log "Cloning and installing ble.sh..."
    git clone --recursive --depth 1 https://github.com/akinomyoga/ble.sh.git
    make -C ble.sh install PREFIX=~/.local
    rm -rf ble.sh
else
    log "ble.sh already installed"
fi

# ===========================
# 3. Install Starship
# ===========================
if ! command -v starship >/dev/null 2>&1; then
    log "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    log "Starship already installed"
fi

# ===========================
# 4. Configure .bashrc (Correct Order)
# ===========================
log "Finalizing .bashrc configuration..."

# Remove any existing ble/starship lines to prevent duplicates and ensure order
sed -i '/blesh\/ble.sh/d' "$BASH_CONFIG"
sed -i '/starship init bash/d' "$BASH_CONFIG"
sed -i '/ble-attach/d' "$BASH_CONFIG"
sed -i '/ble\/prompt\/unit\/update/d' "$BASH_CONFIG"

# 1. Add ble.sh source to the VERY TOP
sed -i '1i [[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh --noattach' "$BASH_CONFIG"

# 2. Add Starship and ble-attach to the VERY BOTTOM
{
    echo ""
    echo "# Starship Prompt Initialization"
    echo 'eval "$(starship init bash)"'
    echo ""
    echo "# Attach ble.sh"
    echo '[[ ${BLE_VERSION-} ]] && ble-attach'
} >> "$BASH_CONFIG"

# ===========================
# 5. Download Starship Template
# ===========================
STARSHIP_DIR="$HOME/.config"
STARSHIP_FILE="$STARSHIP_DIR/starship.toml"
STARSHIP_TEMPLATE_URL="https://raw.githubusercontent.com/Galgathor/server-config/main/templates/starship.toml"

mkdir -p "$STARSHIP_DIR"
if [ ! -f "$STARSHIP_FILE" ]; then
    log "Downloading Starship template..."
    curl -fsSL "$STARSHIP_TEMPLATE_URL" -o "$STARSHIP_FILE" || error "Failed to download template"
fi

# ===========================
# 6. Cleanup
# ===========================
SCRIPT_PATH="${BASH_SOURCE[0]}"
log "Cleaning up..."
rm -f "$SCRIPT_PATH"

log "Setup complete! Restart your terminal or run: source ~/.bashrc"