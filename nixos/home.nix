{ config, pkgs, lib, inputs, hostname, username, ... }:

{
  # Use mkForce so your values win if any imported module defines these too.
  # (We intentionally do NOT import Caelestia's HM module by default because it has caused
  # username/stateVersion conflicts during ISO installs.)
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
    
    # Fun terminal stuff
    cmatrix
    pipes
    sl
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = username;
    userEmail = "user@example.com";  # CHANGE THIS
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
    delta = {
      enable = true;
      options = {
        navigate = true;
        light = false;
        side-by-side = true;
      };
    };
  };

  # Fish shell
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Disable greeting
      set -g fish_greeting
      
      # Initialize starship
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
      
      # Git
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph";
      gd = "git diff";
      
      # NixOS
      nrs = "sudo nixos-rebuild switch --flake /etc/nixos#caelestia";
      nrt = "sudo nixos-rebuild test --flake /etc/nixos#caelestia";
      nrb = "sudo nixos-rebuild boot --flake /etc/nixos#caelestia";
      nfu = "nix flake update";
      ncg = "sudo nix-collect-garbage -d";
      
      # Caelestia
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
      
      nodejs = {
        symbol = "";
        style = "bg:#e0af68 fg:#1a1b26";
        format = "[ $symbol ($version) ]($style)";
      };
      
      python = {
        symbol = "";
        style = "bg:#e0af68 fg:#1a1b26";
        format = "[ $symbol ($version) ]($style)";
      };
      
      rust = {
        symbol = "";
        style = "bg:#e0af68 fg:#1a1b26";
        format = "[ $symbol ($version) ]($style)";
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

  # Create necessary directories and config files
  home.file = {
    # Hyprland config
    ".config/hypr/hyprland.conf".text = ''
      # Caelestia Hyprland Configuration
      # Source the main caelestia config
      source = ~/.config/caelestia-dots/hypr/hyprland.conf
      
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
      # Add your personal customizations here
      
      # Disable VRR (helps with flickering in VMs)
      misc {
          vrr = 0
      }
      
      # Example: Custom keybinds
      # bind = $mainMod, T, exec, foot
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
      # Clone caelestia dotfiles if not present
      if [ ! -d "$HOME/.config/caelestia-dots" ]; then
        $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/caelestia-dots/caelestia.git "$HOME/.config/caelestia-dots" || true
      fi
      
      # Clone caelestia shell if not present
      if [ ! -d "$HOME/.config/quickshell/caelestia" ]; then
        $DRY_RUN_CMD mkdir -p "$HOME/.config/quickshell"
        $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/caelestia-dots/shell.git "$HOME/.config/quickshell/caelestia" || true
      fi
    '';
  };
}

