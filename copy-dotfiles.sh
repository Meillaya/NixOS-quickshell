#!/usr/bin/env bash
#
# Copy dotfiles to their correct locations
# Run this after the system is installed
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Dotfiles Installer                          ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if dotfiles directory exists
if [ ! -d "$DOTFILES_DIR" ]; then
    log_warn "Dotfiles directory not found at $DOTFILES_DIR"
    exit 1
fi

# Create necessary directories
log_info "Creating directories..."
mkdir -p ~/.config/{hypr,foot,fish,btop/themes,caelestia,quickshell,starship}
mkdir -p ~/Pictures/Wallpapers
mkdir -p ~/.local/bin

# Copy Hyprland configs
if [ -d "$DOTFILES_DIR/hypr" ]; then
    log_info "Copying Hyprland configuration..."
    cp -r "$DOTFILES_DIR/hypr/"* ~/.config/hypr/
    log_success "Hyprland config installed"
fi

# Copy Foot config
if [ -f "$DOTFILES_DIR/foot/foot.ini" ]; then
    log_info "Copying Foot terminal configuration..."
    cp "$DOTFILES_DIR/foot/foot.ini" ~/.config/foot/
    log_success "Foot config installed"
fi

# Copy Fish config
if [ -f "$DOTFILES_DIR/fish/config.fish" ]; then
    log_info "Copying Fish shell configuration..."
    cp "$DOTFILES_DIR/fish/config.fish" ~/.config/fish/
    log_success "Fish config installed"
fi

# Copy Starship config
if [ -f "$DOTFILES_DIR/starship.toml" ]; then
    log_info "Copying Starship prompt configuration..."
    cp "$DOTFILES_DIR/starship.toml" ~/.config/starship.toml
    # Also copy to default location
    cp "$DOTFILES_DIR/starship.toml" ~/.config/
    log_success "Starship config installed"
fi

# Copy btop configs
if [ -d "$DOTFILES_DIR/btop" ]; then
    log_info "Copying btop configuration..."
    cp "$DOTFILES_DIR/btop/btop.conf" ~/.config/btop/
    if [ -d "$DOTFILES_DIR/btop/themes" ]; then
        cp -r "$DOTFILES_DIR/btop/themes/"* ~/.config/btop/themes/
    fi
    log_success "Btop config installed"
fi

# Copy Caelestia configs
if [ -d "$DOTFILES_DIR/caelestia" ]; then
    log_info "Copying Caelestia configuration..."
    cp "$DOTFILES_DIR/caelestia/"* ~/.config/caelestia/
    log_success "Caelestia config installed"
fi

# Clone Caelestia repositories if not present
log_info "Checking Caelestia repositories..."

if [ ! -d ~/.config/caelestia-dots ]; then
    log_info "Cloning caelestia-dots repository..."
    git clone https://github.com/caelestia-dots/caelestia.git ~/.config/caelestia-dots || log_warn "Failed to clone caelestia-dots"
else
    log_info "caelestia-dots already exists, pulling latest..."
    cd ~/.config/caelestia-dots && git pull || true
    cd -
fi

if [ ! -d ~/.config/quickshell/caelestia ]; then
    log_info "Cloning caelestia-shell repository..."
    mkdir -p ~/.config/quickshell
    git clone https://github.com/caelestia-dots/shell.git ~/.config/quickshell/caelestia || log_warn "Failed to clone caelestia-shell"
else
    log_info "caelestia-shell already exists, pulling latest..."
    cd ~/.config/quickshell/caelestia && git pull || true
    cd -
fi

# Set correct permissions
log_info "Setting permissions..."
chmod +x ~/.config/fish/config.fish 2>/dev/null || true

# Download a sample wallpaper
log_info "Downloading sample wallpaper..."
if command -v curl > /dev/null; then
    curl -sL "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/wallpapers/nix-wallpaper-dracula.png" \
        -o ~/Pictures/Wallpapers/nix-wallpaper.png 2>/dev/null && \
        log_success "Sample wallpaper downloaded" || \
        log_warn "Could not download sample wallpaper"
fi

echo ""
log_success "All dotfiles installed successfully!"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Log out and log back in (to apply fish/starship changes)"
echo "  2. Start Hyprland: Hyprland"
echo "  3. Add more wallpapers to ~/Pictures/Wallpapers/"
echo ""
echo -e "${GREEN}Enjoy your Caelestia rice! 🌙${NC}"

