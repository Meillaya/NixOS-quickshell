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
  time.timeZone = "America/New_York";  # CHANGE THIS

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
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
  virtualisation.virtualbox.guest.dragAndDrop = true;

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
    
    # Quickshell (from flake - unstable has wayland-protocols >= 1.41)
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
    libsForQt5.qt5ct
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

