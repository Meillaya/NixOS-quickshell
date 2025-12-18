# NixOS + Caelestia + Quickshell Setup

A comprehensive, automated setup for NixOS with the beautiful Caelestia rice and Quickshell.

![Caelestia Rice](https://github.com/user-attachments/assets/0840f496-575c-4ca6-83a8-87bb01a85c5f)

## 📁 File Structure

```
.
├── install.sh                 # Main installation script (run from NixOS ISO)
├── nixos/
│   ├── configuration.nix      # NixOS system configuration
│   ├── flake.nix             # Nix flakes configuration
│   └── home.nix              # Home Manager configuration
└── dotfiles/
    ├── hypr/
    │   ├── hyprland.conf     # Hyprland window manager config
    │   ├── hyprlock.conf     # Lock screen config
    │   └── hypridle.conf     # Idle daemon config
    ├── foot/
    │   └── foot.ini          # Foot terminal config (Tokyo Night)
    ├── fish/
    │   └── config.fish       # Fish shell config
    ├── starship.toml         # Starship prompt config
    ├── btop/
    │   └── btop.conf         # Btop system monitor config
    └── caelestia/
        ├── shell.json        # Caelestia shell settings
        └── hypr-user.conf    # User Hyprland overrides
```

## 🚀 Quick Start

### Option 1: Automated Installation (Recommended)

1. Boot your VirtualBox VM with the NixOS minimal ISO
2. Set up networking:
   ```bash
   sudo systemctl start wpa_supplicant
   sudo systemctl start NetworkManager
   ```
3. SSH into the VM from your host machine
4. Download and run the installer:
   ```bash
   curl -sL https://raw.githubusercontent.com/YOUR_REPO/main/install.sh | sudo bash
   ```
   
   Or clone the repo first:
   ```bash
   nix-shell -p git
   git clone https://github.com/YOUR_REPO.git
   cd YOUR_REPO
   sudo ./install.sh
   ```

5. Follow the prompts to configure username, hostname, timezone, and disk
6. After installation, reboot and run the post-install script

### Option 2: Manual Installation

1. Partition and format your disk
2. Copy `nixos/` files to `/mnt/etc/nixos/`
3. Edit configurations to match your preferences
4. Run `nixos-install --flake /mnt/etc/nixos#caelestia`

## 📋 Post-Installation

After rebooting into your new NixOS system:

1. Log in with your username and password
2. Run the setup script:
   ```bash
   ./setup-caelestia.sh
   ```
3. Start Hyprland:
   ```bash
   Hyprland
   ```

## ⌨️ Key Bindings

| Binding | Action |
|---------|--------|
| `Super + Return` | Open terminal (foot) |
| `Super + D` | Open launcher |
| `Super + E` | Open file manager |
| `Super + B` | Open browser |
| `Super + Q` | Close window |
| `Super + V` | Toggle floating |
| `Super + F` | Toggle fullscreen |
| `Super + 1-9` | Switch workspace |
| `Super + Shift + 1-9` | Move window to workspace |
| `Super + Shift + L` | Lock screen |
| `Print` | Screenshot selection |
| `Super + C` | Clipboard history |

## 🎨 Customization

### Changing the Theme

```bash
caelestia scheme set  # Interactive theme picker
```

### Setting Wallpapers

1. Add wallpapers to `~/Pictures/Wallpapers/`
2. Use the launcher or:
   ```bash
   caelestia wallpaper /path/to/wallpaper.jpg
   ```

### Personal Hyprland Tweaks

Edit `~/.config/caelestia/hypr-user.conf`

### Shell Configuration

Edit `~/.config/caelestia/shell.json`

## 🔧 Troubleshooting

### Screen Flickering (VirtualBox)

Already handled in `hypr-user.conf`:
```conf
misc {
    vrr = 0
}
```

### Shell Not Starting

Run manually:
```bash
qs -c caelestia
```

Check logs:
```bash
journalctl --user -xe
```

### Missing Fonts

```bash
fc-cache -fv
```

### Rebuild NixOS After Changes

```bash
sudo nixos-rebuild switch --flake /etc/nixos#caelestia
```

### Update Home Manager

```bash
home-manager switch --flake /etc/nixos
```

## 📦 What's Included

### Desktop Environment
- **Hyprland** - Dynamic tiling Wayland compositor
- **Quickshell** - Qt6/QML-based shell framework
- **Caelestia Shell** - Beautiful, feature-rich shell

### Terminal & Shell
- **Foot** - Fast, lightweight Wayland terminal
- **Fish** - User-friendly shell
- **Starship** - Cross-shell prompt

### Utilities
- **btop** - Resource monitor
- **eza** - Modern ls replacement
- **bat** - Cat with syntax highlighting
- **fd** - Modern find replacement
- **ripgrep** - Fast grep replacement
- **fzf** - Fuzzy finder

### Theming
- **Tokyo Night** color scheme
- **Papirus** icons
- **adw-gtk3** GTK theme
- **Nerd Fonts** (JetBrains Mono)

## 🔗 Resources

- [Caelestia Dots](https://github.com/caelestia-dots/caelestia)
- [Caelestia Shell](https://github.com/caelestia-dots/shell)
- [Quickshell](https://quickshell.org/)
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)

## 📄 License

MIT License - Feel free to use, modify, and distribute.

---

Enjoy your beautiful NixOS rice! 🌙✨

