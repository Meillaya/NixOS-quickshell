#!/usr/bin/env bash
#
# NixOS + Caelestia + Quickshell Automated Installer
# Run this from the NixOS minimal ISO after SSH'ing in
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration - EDIT THESE
USERNAME="${USERNAME:-nixos}"
HOSTNAME="${HOSTNAME:-caelestia}"
TIMEZONE="${TIMEZONE:-America/New_York}"
LOCALE="${LOCALE:-en_US.UTF-8}"
DISK="${DISK:-/dev/sda}"

# Partition sizes
BOOT_SIZE="512MB"
SWAP_SIZE="8GB"

print_header() {
    echo -e "${PURPLE}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║     NixOS + Caelestia + Quickshell Automated Installer        ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

prompt_config() {
    print_header
    
    echo -e "${CYAN}Current Configuration:${NC}"
    echo "  Username:  $USERNAME"
    echo "  Hostname:  $HOSTNAME"
    echo "  Timezone:  $TIMEZONE"
    echo "  Locale:    $LOCALE"
    echo "  Disk:      $DISK"
    echo ""
    
    read -p "Would you like to change these settings? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Username [$USERNAME]: " input
        USERNAME="${input:-$USERNAME}"
        
        read -p "Hostname [$HOSTNAME]: " input
        HOSTNAME="${input:-$HOSTNAME}"
        
        read -p "Timezone [$TIMEZONE]: " input
        TIMEZONE="${input:-$TIMEZONE}"
        
        read -p "Locale [$LOCALE]: " input
        LOCALE="${input:-$LOCALE}"
        
        echo ""
        echo "Available disks:"
        lsblk -d -o NAME,SIZE,TYPE | grep disk
        echo ""
        read -p "Target disk [$DISK]: " input
        DISK="${input:-$DISK}"
    fi
    
    echo ""
    echo -e "${RED}WARNING: This will ERASE ALL DATA on $DISK${NC}"
    read -p "Are you sure you want to continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "Installation cancelled."
        exit 1
    fi
}

partition_disk() {
    log_info "Partitioning disk $DISK..."
    
    # Unmount any existing partitions
    umount -R /mnt 2>/dev/null || true
    swapoff -a 2>/dev/null || true
    
    # Create GPT partition table
    parted -s "$DISK" -- mklabel gpt
    
    # Create partitions
    # 1: EFI System Partition (512MB)
    # 2: Root partition (rest minus swap)
    # 3: Swap partition (8GB at end)
    parted -s "$DISK" -- mkpart ESP fat32 1MB "$BOOT_SIZE"
    parted -s "$DISK" -- set 1 esp on
    parted -s "$DISK" -- mkpart root ext4 "$BOOT_SIZE" "-$SWAP_SIZE"
    parted -s "$DISK" -- mkpart swap linux-swap "-$SWAP_SIZE" 100%
    
    # Wait for partitions to appear
    sleep 2
    partprobe "$DISK"
    sleep 2
    
    log_success "Disk partitioned successfully"
}

format_partitions() {
    log_info "Formatting partitions..."
    
    # Determine partition naming scheme
    if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
        PART_PREFIX="${DISK}p"
    else
        PART_PREFIX="${DISK}"
    fi
    
    mkfs.fat -F 32 -n boot "${PART_PREFIX}1"
    mkfs.ext4 -L nixos "${PART_PREFIX}2"
    mkswap -L swap "${PART_PREFIX}3"
    
    log_success "Partitions formatted successfully"
}

mount_partitions() {
    log_info "Mounting partitions..."
    
    if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
        PART_PREFIX="${DISK}p"
    else
        PART_PREFIX="${DISK}"
    fi
    
    mount "${PART_PREFIX}2" /mnt
    mkdir -p /mnt/boot
    mount "${PART_PREFIX}1" /mnt/boot
    swapon "${PART_PREFIX}3"
    
    log_success "Partitions mounted successfully"
}

generate_config() {
    log_info "Generating NixOS configuration..."
    
    nixos-generate-config --root /mnt
    
    log_success "Hardware configuration generated"
}

create_nixos_config() {
    log_info "Creating NixOS configuration with Caelestia support..."
    
    cat > /mnt/etc/nixos/configuration.nix << 'NIXCONFIG'
{ config, pkgs, lib, inputs, hostname, username, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel parameters for better Wayland/Hyprland support
  boot.kernelParams = [ "nvidia_drm.modeset=1" ];

  # Networking
  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  # Time zone
  time.timeZone = "TIMEZONE_PLACEHOLDER";

  # Locale
  i18n.defaultLocale = "LOCALE_PLACEHOLDER";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "LOCALE_PLACEHOLDER";
    LC_IDENTIFICATION = "LOCALE_PLACEHOLDER";
    LC_MEASUREMENT = "LOCALE_PLACEHOLDER";
    LC_MONETARY = "LOCALE_PLACEHOLDER";
    LC_NAME = "LOCALE_PLACEHOLDER";
    LC_NUMERIC = "LOCALE_PLACEHOLDER";
    LC_PAPER = "LOCALE_PLACEHOLDER";
    LC_TELEPHONE = "LOCALE_PLACEHOLDER";
    LC_TIME = "LOCALE_PLACEHOLDER";
  };

  # Enable flakes and new nix command
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # User account
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
    shell = pkgs.fish;
  };

  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # XDG Portal for screen sharing, file dialogs, etc.
  xdg.portal = {
    enable = true;
    extraPortals = [ 
      pkgs.xdg-desktop-portal-hyprland 
      pkgs.xdg-desktop-portal-gtk 
    ];
  };

  # Graphics - OpenGL/Vulkan
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # VirtualBox Guest Additions (comment out if not using VirtualBox)
  virtualisation.virtualbox.guest.enable = true;
  virtualisation.virtualbox.guest.dragAndDrop = true;  # Fixed capitalization

  # Audio via Pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # Fish shell
  programs.fish.enable = true;

  # Enable dbus
  services.dbus.enable = true;

  # Enable GVFS for file manager features
  services.gvfs.enable = true;

  # Thunar plugins
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  # Enable SSH
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  # Polkit for privilege escalation
  security.polkit.enable = true;

  # System packages - all dependencies for Caelestia
  environment.systemPackages = with pkgs; [
    # Core utilities
    git
    wget
    curl
    vim
    nano
    unzip
    zip
    p7zip
    
    # Hyprland ecosystem
    hyprpicker
    hyprpaper
    hypridle
    hyprlock
    hyprshot
    
    # Quickshell (from flake input)
    inputs.quickshell.packages.${pkgs.system}.default
    
    # Wayland utilities
    wl-clipboard
    cliphist
    wlr-randr
    wl-screenrec
    grim
    slurp
    
    # Terminal & shell
    foot
    fish
    starship
    
    # File management
    trash-cli
    xdg-utils
    
    # System utilities
    btop
    htop
    fastfetch
    neofetch
    jq
    yq
    eza
    fd
    ripgrep
    fzf
    bat
    inotify-tools
    libnotify
    
    # Networking utilities
    networkmanagerapplet
    
    # Theming
    adw-gtk3
    papirus-icon-theme
    libsForQt5.qt5ct  # Fixed: was qt5ct
    qt6ct
    libsForQt5.qtstyleplugin-kvantum
    
    # Additional dependencies for Caelestia shell
    libqalculate
    brightnessctl
    playerctl
    pamixer
    pavucontrol
    
    # Qt6 dependencies
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtsvg
    qt6.qtimageformats
    qt6.qtmultimedia
    qt6.qt5compat
    qt6.qtwayland
    
    # Image viewing/editing
    imv
    imagemagick
    
    # Apps
    firefox
    
    # For building caelestia shell from source if needed
    cmake
    ninja
    gcc
    pkg-config
    
    # Polkit agent
    polkit_gnome
  ];

  # Fonts
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      jetbrains-mono
      (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" "Hack" "Iosevka" ]; })
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
      };
    };
  };

  # Environment variables for Wayland/Qt
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    GDK_BACKEND = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    QT_QPA_PLATFORMTHEME = "qt6ct";
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # System version - DO NOT CHANGE after initial install
  system.stateVersion = "25.05";
}
NIXCONFIG

    # Replace placeholders (hostname and username are now passed via specialArgs, not sed)
    sed -i "s|TIMEZONE_PLACEHOLDER|$TIMEZONE|g" /mnt/etc/nixos/configuration.nix
    sed -i "s/LOCALE_PLACEHOLDER/$LOCALE/g" /mnt/etc/nixos/configuration.nix
    
    log_success "NixOS configuration created"
}

create_post_install_script() {
    log_info "Creating post-install setup script..."
    
    mkdir -p /mnt/home/$USERNAME
    
    cat > /mnt/home/$USERNAME/setup-caelestia.sh << 'POSTINSTALL'
#!/usr/bin/env bash
#
# Post-install Caelestia Setup Script
# Run this after rebooting into your new NixOS installation
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${PURPLE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           Caelestia Post-Installation Setup                    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Create necessary directories
log_info "Creating directory structure..."
mkdir -p ~/.config/{hypr,quickshell,caelestia,foot,fish,starship,btop}
mkdir -p ~/Pictures/Wallpapers
mkdir -p ~/.local/share/applications
mkdir -p ~/.local/bin

# Clone Caelestia repositories
log_info "Cloning Caelestia dotfiles..."

if [ ! -d ~/.config/caelestia-dots ]; then
    git clone https://github.com/caelestia-dots/caelestia.git ~/.config/caelestia-dots
fi

if [ ! -d ~/.config/quickshell/caelestia ]; then
    git clone https://github.com/caelestia-dots/shell.git ~/.config/quickshell/caelestia
fi

# Copy/link configurations from caelestia
log_info "Setting up Caelestia configurations..."

# Link Hyprland config
if [ -d ~/.config/caelestia-dots/hypr ]; then
    ln -sf ~/.config/caelestia-dots/hypr ~/.config/hypr/caelestia
fi

# Link other configs
for config in foot fish btop; do
    if [ -d ~/.config/caelestia-dots/$config ]; then
        rm -rf ~/.config/$config
        ln -sf ~/.config/caelestia-dots/$config ~/.config/$config
    fi
done

# Create main Hyprland config that sources Caelestia
log_info "Creating Hyprland configuration..."
cat > ~/.config/hypr/hyprland.conf << 'HYPRCONF'
# Caelestia Hyprland Configuration
# Source the main caelestia config
source = ~/.config/caelestia-dots/hypr/hyprland.conf

# User overrides - add your customizations here
# source = ~/.config/caelestia/hypr-user.conf

# Autostart Caelestia shell
exec-once = qs -c caelestia

# Polkit agent for privilege escalation dialogs
exec-once = /run/current-system/sw/libexec/polkit-gnome-authentication-agent-1
HYPRCONF

# Create user override file
mkdir -p ~/.config/caelestia
cat > ~/.config/caelestia/hypr-user.conf << 'USRCONF'
# User Hyprland overrides
# Add your personal customizations here

# Example: Disable VRR (helps with flickering in VMs)
misc {
    vrr = 0
}

# Example: Custom keybinds
# bind = $mainMod, T, exec, foot
USRCONF

# Create shell.json config
cat > ~/.config/caelestia/shell.json << 'SHELLCONF'
{
    "wallpapers_path": "~/Pictures/Wallpapers",
    "terminal": "foot",
    "file_manager": "thunar",
    "browser": "firefox"
}
SHELLCONF

# Create foot terminal config
log_info "Creating foot terminal configuration..."
cat > ~/.config/foot/foot.ini << 'FOOTCONF'
[main]
font=JetBrainsMono Nerd Font:size=11
dpi-aware=yes
pad=12x12

[cursor]
style=beam
blink=yes

[mouse]
hide-when-typing=yes

[colors]
alpha=0.9
background=1a1b26
foreground=c0caf5
regular0=15161e
regular1=f7768e
regular2=9ece6a
regular3=e0af68
regular4=7aa2f7
regular5=bb9af7
regular6=7dcfff
regular7=a9b1d6
bright0=414868
bright1=f7768e
bright2=9ece6a
bright3=e0af68
bright4=7aa2f7
bright5=bb9af7
bright6=7dcfff
bright7=c0caf5
FOOTCONF

# Create fish config
log_info "Creating fish shell configuration..."
mkdir -p ~/.config/fish
cat > ~/.config/fish/config.fish << 'FISHCONF'
# Fish Configuration for Caelestia

# Disable greeting
set -g fish_greeting

# Environment variables
set -gx EDITOR nano
set -gx VISUAL nano
set -gx BROWSER firefox
set -gx TERMINAL foot

# Add local bin to path
fish_add_path ~/.local/bin

# Aliases
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias la='eza -a --icons --group-directories-first'
alias lt='eza --tree --icons --group-directories-first'
alias cat='bat --style=auto'
alias grep='rg'
alias find='fd'
alias vim='nvim'
alias cd..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cls='clear'
alias rm='trash-put'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph'
alias gd='git diff'

# NixOS aliases
alias nrs='sudo nixos-rebuild switch'
alias nrt='sudo nixos-rebuild test'
alias nrb='sudo nixos-rebuild boot'
alias nfu='nix flake update'
alias ncg='sudo nix-collect-garbage -d'

# Caelestia aliases
alias cae-shell='qs -c caelestia'
alias cae-reload='caelestia shell reload'

# Initialize starship prompt
if command -v starship > /dev/null
    starship init fish | source
end

# Fastfetch on new terminal (optional - comment out if annoying)
# fastfetch
FISHCONF

# Create starship config
log_info "Creating starship prompt configuration..."
cat > ~/.config/starship.toml << 'STARSHIPCONF'
# Starship Prompt Configuration

format = """
[](#7aa2f7)\
$os\
$username\
[](bg:#bb9af7 fg:#7aa2f7)\
$directory\
[](fg:#bb9af7 bg:#9ece6a)\
$git_branch\
$git_status\
[](fg:#9ece6a bg:#e0af68)\
$c\
$rust\
$golang\
$nodejs\
$python\
$nix_shell\
[](fg:#e0af68 bg:#f7768e)\
$docker_context\
[](fg:#f7768e bg:#1a1b26)\
$time\
[ ](fg:#1a1b26)\
\n$character"""

[os]
disabled = false
style = "bg:#7aa2f7 fg:#1a1b26"
format = '[ $symbol ]($style)'

[os.symbols]
NixOS = ""

[username]
show_always = true
style_user = "bg:#7aa2f7 fg:#1a1b26"
style_root = "bg:#7aa2f7 fg:#1a1b26"
format = '[$user ]($style)'

[directory]
style = "bg:#bb9af7 fg:#1a1b26"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
symbol = ""
style = "bg:#9ece6a fg:#1a1b26"
format = '[ $symbol $branch ]($style)'

[git_status]
style = "bg:#9ece6a fg:#1a1b26"
format = '[$all_status$ahead_behind ]($style)'

[nodejs]
symbol = ""
style = "bg:#e0af68 fg:#1a1b26"
format = '[ $symbol ($version) ]($style)'

[python]
symbol = ""
style = "bg:#e0af68 fg:#1a1b26"
format = '[ $symbol ($version) ]($style)'

[rust]
symbol = ""
style = "bg:#e0af68 fg:#1a1b26"
format = '[ $symbol ($version) ]($style)'

[golang]
symbol = ""
style = "bg:#e0af68 fg:#1a1b26"
format = '[ $symbol ($version) ]($style)'

[nix_shell]
symbol = ""
style = "bg:#e0af68 fg:#1a1b26"
format = '[ $symbol ($name) ]($style)'

[docker_context]
symbol = ""
style = "bg:#f7768e fg:#1a1b26"
format = '[ $symbol $context ]($style)'

[time]
disabled = false
time_format = "%R"
style = "bg:#1a1b26 fg:#c0caf5"
format = '[ $time ]($style)'

[character]
success_symbol = '[❯](bold green)'
error_symbol = '[❯](bold red)'
STARSHIPCONF

# Download a sample wallpaper
log_info "Downloading sample wallpaper..."
if command -v curl > /dev/null; then
    curl -sL "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/wallpapers/nix-wallpaper-dracula.png" \
        -o ~/Pictures/Wallpapers/nix-wallpaper.png 2>/dev/null || true
fi

# Create .face placeholder for dashboard profile picture
if [ ! -f ~/.face ]; then
    log_info "Creating placeholder profile picture..."
    # Create a simple placeholder (you should replace this with your actual photo)
    touch ~/.face
fi

# Set correct permissions
log_info "Setting permissions..."
chmod +x ~/.config/fish/config.fish 2>/dev/null || true

# Build caelestia shell if needed
if [ -d ~/.config/quickshell/caelestia ] && [ -f ~/.config/quickshell/caelestia/CMakeLists.txt ]; then
    log_info "Building Caelestia shell components..."
    cd ~/.config/quickshell/caelestia
    if [ ! -d build ]; then
        mkdir build
        cd build
        cmake .. -DINSTALL_QSCONFDIR=~/.config/quickshell/caelestia
        make -j$(nproc)
    fi
    cd ~
fi

log_success "Caelestia setup complete!"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "  1. Log out and log back in (or reboot)"
echo "  2. At the TTY, type: Hyprland"
echo "  3. Add wallpapers to ~/Pictures/Wallpapers/"
echo "  4. Set your profile picture at ~/.face"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "  caelestia wallpaper <path>  - Set wallpaper"
echo "  caelestia scheme set        - Change color scheme"
echo "  caelestia shell -s          - Show shell IPC commands"
echo ""
echo -e "${GREEN}Enjoy your Caelestia rice! 🌙${NC}"
POSTINSTALL

    chmod +x /mnt/home/$USERNAME/setup-caelestia.sh
    
    log_success "Post-install script created at /home/$USERNAME/setup-caelestia.sh"
}

create_flake_config() {
    log_info "Creating flake.nix for reproducible builds..."
    
    cat > /mnt/etc/nixos/flake.nix << FLAKECONFIG
{
  description = "NixOS configuration with Caelestia and Quickshell";

  inputs = {
    # Use unstable for latest packages (required for wayland-protocols >= 1.41)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";  # master branch for unstable
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Quickshell flake - use GitHub mirror (more reliable)
    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, quickshell, ... }@inputs:
    let
      system = "x86_64-linux";
      hostname = "$HOSTNAME";
      username = "$USERNAME";
      
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations.\${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs hostname username; };
        modules = [
          ./configuration.nix
          
          # Home Manager as a NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.\${username} = import ./home.nix;
            home-manager.extraSpecialArgs = { inherit inputs hostname username; };
          }
        ];
      };
      
      # Dev shell for working on configs
      devShells.\${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nil
          nixpkgs-fmt
        ];
      };
    };
}
FLAKECONFIG
    
    log_success "flake.nix created"
}

create_home_manager_config() {
    log_info "Creating Home Manager configuration..."
    
    cat > /mnt/etc/nixos/home.nix << 'HOMECONFIG'
{ config, pkgs, lib, inputs, hostname, username, ... }:

{
  # Use mkForce to override any conflicting values from imported modules
  home.username = lib.mkForce username;
  home.homeDirectory = lib.mkForce "/home/${username}";
  home.stateVersion = lib.mkForce "25.05";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # NOTE: We don't import Caelestia's HM module during install because it conflicts
  # with username/stateVersion settings. After booting, you can clone and set up
  # caelestia-dots manually with the setup-caelestia.sh script.

  # User packages (in addition to system packages)
  home.packages = with pkgs; [
    # Development tools
    nodejs
    python3
    
    # Additional utilities
    ripgrep
    fzf
    jq
    yq
    
    # Fun
    cmatrix
    pipes
    sl
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = username;
    userEmail = "user@example.com";  # Change this!
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  # Fish shell
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
      starship init fish | source
    '';
    shellAliases = {
      ls = "eza --icons --group-directories-first";
      ll = "eza -la --icons --group-directories-first";
      la = "eza -a --icons --group-directories-first";
      lt = "eza --tree --icons --group-directories-first";
      cat = "bat --style=auto";
      grep = "rg";
      find = "fd";
      cd.. = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      cls = "clear";
      rm = "trash-put";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph";
      gd = "git diff";
      nrs = "sudo nixos-rebuild switch --flake /etc/nixos#${hostname}";
      nrt = "sudo nixos-rebuild test --flake /etc/nixos#${hostname}";
      ncg = "sudo nix-collect-garbage -d";
      cae-shell = "qs -c caelestia";
      cae-reload = "caelestia shell reload";
    };
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    settings = {
      format = lib.concatStrings [
        "[](#7aa2f7)"
        "$os"
        "$username"
        "[](bg:#bb9af7 fg:#7aa2f7)"
        "$directory"
        "[](fg:#bb9af7 bg:#9ece6a)"
        "$git_branch"
        "$git_status"
        "[](fg:#9ece6a bg:#e0af68)"
        "$nodejs"
        "$python"
        "$rust"
        "$nix_shell"
        "[](fg:#e0af68 bg:#1a1b26)"
        "$time"
        "[ ](fg:#1a1b26)"
        "\n$character"
      ];
      os = {
        disabled = false;
        style = "bg:#7aa2f7 fg:#1a1b26";
        format = "[ $symbol ]($style)";
        symbols.NixOS = "";
      };
      username = {
        show_always = true;
        style_user = "bg:#7aa2f7 fg:#1a1b26";
        style_root = "bg:#7aa2f7 fg:#1a1b26";
        format = "[$user ]($style)";
      };
      directory = {
        style = "bg:#bb9af7 fg:#1a1b26";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
      };
      git_branch = {
        symbol = "";
        style = "bg:#9ece6a fg:#1a1b26";
        format = "[ $symbol $branch ]($style)";
      };
      git_status = {
        style = "bg:#9ece6a fg:#1a1b26";
        format = "[$all_status$ahead_behind ]($style)";
      };
      nix_shell = {
        symbol = "";
        style = "bg:#e0af68 fg:#1a1b26";
        format = "[ $symbol ($name) ]($style)";
      };
      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:#1a1b26 fg:#c0caf5";
        format = "[ $time ]($style)";
      };
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
    };
  };

  # Direnv for automatic environment switching
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Btop configuration
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "tokyo-night";
      theme_background = false;
      vim_keys = true;
    };
  };

  # Foot terminal
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=11";
        dpi-aware = "yes";
        pad = "12x12";
      };
      cursor = {
        style = "beam";
        blink = "yes";
      };
      mouse = {
        hide-when-typing = "yes";
      };
      colors = {
        alpha = 0.9;
        background = "1a1b26";
        foreground = "c0caf5";
        regular0 = "15161e";
        regular1 = "f7768e";
        regular2 = "9ece6a";
        regular3 = "e0af68";
        regular4 = "7aa2f7";
        regular5 = "bb9af7";
        regular6 = "7dcfff";
        regular7 = "a9b1d6";
        bright0 = "414868";
        bright1 = "f7768e";
        bright2 = "9ece6a";
        bright3 = "e0af68";
        bright4 = "7aa2f7";
        bright5 = "bb9af7";
        bright6 = "7dcfff";
        bright7 = "c0caf5";
      };
    };
  };

  # XDG directories
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
    };
  };

  # GTK theming
  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Adwaita";
      size = 24;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Qt theming
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  # Cursor theme
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Session variables
  home.sessionVariables = {
    EDITOR = "nano";
    VISUAL = "nano";
    BROWSER = "firefox";
    TERMINAL = "foot";
  };

  # Create config files
  home.file = {
    # Hyprland config
    ".config/hypr/hyprland.conf".text = ''
      # Caelestia Hyprland Configuration
      # Source the main caelestia config (after running setup-caelestia.sh)
      # source = ~/.config/caelestia-dots/hypr/hyprland.conf
      
      # User overrides
      source = ~/.config/caelestia/hypr-user.conf
      
      # Autostart Caelestia shell
      exec-once = qs -c caelestia
      
      # Polkit agent
      exec-once = ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
    '';
    
    # User hyprland overrides
    ".config/caelestia/hypr-user.conf".text = ''
      # User Hyprland overrides
      # Disable VRR (helps with flickering in VMs)
      misc {
          vrr = 0
      }
    '';
    
    # Caelestia shell config
    ".config/caelestia/shell.json".text = builtins.toJSON {
      wallpapers_path = "~/Pictures/Wallpapers";
      terminal = "foot";
      file_manager = "thunar";
      browser = "firefox";
    };
    
    # Create Pictures/Wallpapers directory marker
    "Pictures/Wallpapers/.keep".text = "";
  };

  # Activation script to clone caelestia repos
  home.activation = {
    cloneCaelestia = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -d "$HOME/.config/caelestia-dots" ]; then
        $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/caelestia-dots/caelestia.git "$HOME/.config/caelestia-dots" || true
      fi
      if [ ! -d "$HOME/.config/quickshell/caelestia" ]; then
        $DRY_RUN_CMD mkdir -p "$HOME/.config/quickshell"
        $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/caelestia-dots/shell.git "$HOME/.config/quickshell/caelestia" || true
      fi
    '';
  };
}
HOMECONFIG
    
    log_success "home.nix created"
}

install_nixos() {
    log_info "Installing NixOS (this may take a while)..."
    
    # Enable flakes for the install command
    export NIX_CONFIG="experimental-features = nix-command flakes"
    
    # Install using flakes
    nixos-install --flake /mnt/etc/nixos#$HOSTNAME --extra-experimental-features "nix-command flakes"
    
    log_success "NixOS installed successfully!"
}

set_passwords() {
    log_info "Setting up user passwords..."
    
    echo ""
    echo -e "${CYAN}Set password for root:${NC}"
    nixos-enter --root /mnt -- passwd root
    
    echo ""
    echo -e "${CYAN}Set password for $USERNAME:${NC}"
    nixos-enter --root /mnt -- passwd $USERNAME
    
    log_success "Passwords set successfully"
}

finalize() {
    log_info "Finalizing installation..."
    
    # Set correct ownership for user home
    chown -R 1000:100 /mnt/home/$USERNAME
    
    # Create a simple README
    cat > /mnt/home/$USERNAME/README.txt << 'README'
╔═══════════════════════════════════════════════════════════════╗
║           Welcome to NixOS with Caelestia!                     ║
╚═══════════════════════════════════════════════════════════════╝

FIRST BOOT INSTRUCTIONS:

1. After booting, log in at the TTY with your username and password

2. Run the post-installation setup script:
   ./setup-caelestia.sh

3. Start Hyprland:
   Hyprland

4. Customize your setup:
   - Add wallpapers to ~/Pictures/Wallpapers/
   - Set your profile picture: cp your-photo.jpg ~/.face
   - Edit ~/.config/caelestia/hypr-user.conf for Hyprland tweaks
   - Edit ~/.config/caelestia/shell.json for shell settings

USEFUL COMMANDS:

  caelestia wallpaper <path>  - Set wallpaper
  caelestia scheme set        - Change color scheme
  caelestia shell -s          - Show shell IPC commands
  caelestia shell reload      - Reload the shell

  sudo nixos-rebuild switch   - Apply NixOS config changes
  home-manager switch         - Apply home-manager changes

TROUBLESHOOTING:

  - Screen flickering? Add to ~/.config/caelestia/hypr-user.conf:
    misc { vrr = 0 }

  - Shell not starting? Run: qs -c caelestia

  - Missing fonts? Run: fc-cache -fv

For more info, visit:
  - https://github.com/caelestia-dots/caelestia
  - https://github.com/caelestia-dots/shell
  - https://quickshell.org/docs/

Enjoy your rice! 🌙
README
    
    chown 1000:100 /mnt/home/$USERNAME/README.txt
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           Installation Complete!                               ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Reboot: ${YELLOW}reboot${NC}"
    echo "  2. Log in as $USERNAME"
    echo "  3. Run: ${YELLOW}./setup-caelestia.sh${NC}"
    echo "  4. Start Hyprland: ${YELLOW}Hyprland${NC}"
    echo ""
    echo -e "${PURPLE}Your config files are at: /etc/nixos/${NC}"
    echo -e "${PURPLE}Post-install script at: /home/$USERNAME/setup-caelestia.sh${NC}"
    echo ""
}

main() {
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run as root (use sudo)"
        exit 1
    fi
    
    # Check if running from NixOS installer
    if [ ! -f /etc/NIXOS ]; then
        log_warn "This doesn't appear to be a NixOS system"
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    prompt_config
    partition_disk
    format_partitions
    mount_partitions
    generate_config
    create_nixos_config
    create_flake_config
    create_home_manager_config
    create_post_install_script
    install_nixos
    set_passwords
    finalize
}

# Run main function
main "$@"

