{ config, pkgs, lib, inputs, hostname, username, ... }:

{
  # ══════════════════════════════════════════════════════════════════════════════
  # Core Home Manager Settings
  # ══════════════════════════════════════════════════════════════════════════════
  
  home.username = lib.mkForce username;
  home.homeDirectory = lib.mkForce "/home/${username}";
  home.stateVersion = lib.mkForce "25.05";

  programs.home-manager.enable = true;

  # ══════════════════════════════════════════════════════════════════════════════
  # Hyprland - Declarative Window Manager Configuration
  # ══════════════════════════════════════════════════════════════════════════════
  
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    xwayland.enable = true;
    
    settings = {
      # ── Variables ───────────────────────────────────────────────────────────
      "$mainMod" = "SUPER";
      "$terminal" = "foot";
      "$fileManager" = "thunar";
      "$browser" = "firefox";
      "$menu" = "fuzzel";
      
      # ── Monitor Configuration ───────────────────────────────────────────────
      monitor = ",preferred,auto,1";
      
      # ── Environment Variables ───────────────────────────────────────────────
      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        "QT_QPA_PLATFORMTHEME,qt6ct"
        "QT_QPA_PLATFORM,wayland"
        "GDK_BACKEND,wayland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
      ];
      
      # ── Autostart ───────────────────────────────────────────────────────────
      exec-once = [
        "qs -c caelestia"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
      ];
      
      # ── General Settings ────────────────────────────────────────────────────
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(7aa2f7ee) rgba(bb9af7ee) 45deg";
        "col.inactive_border" = "rgba(414868aa)";
        resize_on_border = true;
        allow_tearing = false;
        layout = "dwindle";
      };
      
      # ── Decoration ──────────────────────────────────────────────────────────
      decoration = {
        rounding = 12;
        active_opacity = 1.0;
        inactive_opacity = 0.9;
        
        shadow = {
          enabled = true;
          range = 20;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
        
        blur = {
          enabled = true;
          size = 8;
          passes = 3;
          new_optimizations = true;
          vibrancy = 0.1696;
        };
      };
      
      # ── Animations ──────────────────────────────────────────────────────────
      animations = {
        enabled = true;
        
        bezier = [
          "wind, 0.05, 0.9, 0.1, 1.05"
          "winIn, 0.1, 1.1, 0.1, 1.1"
          "winOut, 0.3, -0.3, 0, 1"
          "liner, 1, 1, 1, 1"
          "overshot, 0.05, 0.9, 0.1, 1.1"
        ];
        
        animation = [
          "windows, 1, 6, wind, slide"
          "windowsIn, 1, 6, winIn, slide"
          "windowsOut, 1, 5, winOut, slide"
          "windowsMove, 1, 5, wind, slide"
          "border, 1, 1, liner"
          "borderangle, 1, 30, liner, loop"
          "fade, 1, 10, default"
          "workspaces, 1, 5, overshot, slide"
          "layers, 1, 5, wind, slide"
        ];
      };
      
      # ── Layouts ─────────────────────────────────────────────────────────────
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        smart_split = false;
        smart_resizing = true;
      };
      
      master = {
        new_status = "master";
      };
      
      # ── Misc ────────────────────────────────────────────────────────────────
      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        vfr = true;
        vrr = 0;  # Disable VRR to prevent flickering in VMs
      };
      
      # ── Input ───────────────────────────────────────────────────────────────
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
        
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
          drag_lock = true;
        };
      };
      
      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 3;
      };
      
      # ── Keybindings ─────────────────────────────────────────────────────────
      bind = [
        # Applications
        "$mainMod, Return, exec, $terminal"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, B, exec, $browser"
        "$mainMod, D, exec, $menu"
        
        # Window Management
        "$mainMod, Q, killactive,"
        "$mainMod SHIFT, Q, exit,"
        "$mainMod, V, togglefloating,"
        "$mainMod, F, fullscreen,"
        "$mainMod, P, pseudo,"
        "$mainMod, J, togglesplit,"
        
        # Focus
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"
        "$mainMod, H, movefocus, l"
        "$mainMod, L, movefocus, r"
        "$mainMod, K, movefocus, u"
        "$mainMod SHIFT, J, movefocus, d"
        
        # Move windows
        "$mainMod SHIFT, left, movewindow, l"
        "$mainMod SHIFT, right, movewindow, r"
        "$mainMod SHIFT, up, movewindow, u"
        "$mainMod SHIFT, down, movewindow, d"
        "$mainMod SHIFT, H, movewindow, l"
        "$mainMod SHIFT, L, movewindow, r"
        "$mainMod SHIFT, K, movewindow, u"
        "$mainMod CTRL, J, movewindow, d"
        
        # Resize
        "$mainMod CTRL, left, resizeactive, -20 0"
        "$mainMod CTRL, right, resizeactive, 20 0"
        "$mainMod CTRL, up, resizeactive, 0 -20"
        "$mainMod CTRL, down, resizeactive, 0 20"
        
        # Workspaces
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"
        
        # Move to workspace
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"
        
        # Special workspace
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"
        
        # Scroll workspaces
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
        
        # Screenshot
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
        "SHIFT, Print, exec, grim - | wl-copy"
        "$mainMod, Print, exec, grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"
        
        # Clipboard
        "$mainMod, C, exec, cliphist list | fuzzel -d | cliphist decode | wl-copy"
        
        # Lock
        "$mainMod SHIFT, L, exec, hyprlock"
      ];
      
      # Mouse bindings
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
      
      # Volume/brightness (key repeat enabled)
      bindel = [
        ", XF86AudioRaiseVolume, exec, pamixer -i 5"
        ", XF86AudioLowerVolume, exec, pamixer -d 5"
        ", XF86AudioMute, exec, pamixer -t"
        ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];
      
      # Media controls (locked)
      bindl = [
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioNext, exec, playerctl next"
      ];
      
      # ── Window Rules ────────────────────────────────────────────────────────
      windowrulev2 = [
        "suppressevent maximize, class:.*"
        "float, class:^(pavucontrol)$"
        "float, class:^(nm-connection-editor)$"
        "float, class:^(blueman-manager)$"
        "float, title:^(Picture-in-Picture)$"
        "float, title:^(File Operation Progress)$"
        "pin, title:^(Picture-in-Picture)$"
        "keepaspectratio, title:^(Picture-in-Picture)$"
        "opacity 0.9 0.9, class:^(foot)$"
        "opacity 0.95 0.95, class:^(thunar)$"
        "opacity 0.95 0.95, class:^(Code)$"
        "opacity 0.95 0.95, class:^(cursor)$"
      ];
      
      # Layer rules
      layerrule = [
        "blur, gtk-layer-shell"
        "ignorezero, gtk-layer-shell"
        "blur, quickshell"
        "ignorezero, quickshell"
      ];
    };
  };

  # ══════════════════════════════════════════════════════════════════════════════
  # Hyprlock - Lock Screen
  # ══════════════════════════════════════════════════════════════════════════════
  
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
        grace = 0;
        no_fade_in = false;
        no_fade_out = false;
      };
      
      background = [{
        monitor = "";
        path = "screenshot";
        blur_passes = 3;
        blur_size = 8;
        noise = 0.0117;
        contrast = 0.8916;
        brightness = 0.8172;
        vibrancy = 0.1696;
      }];
      
      input-field = [{
        monitor = "";
        size = "300, 50";
        outline_thickness = 3;
        dots_size = 0.33;
        dots_spacing = 0.15;
        dots_center = true;
        outer_color = "rgb(7aa2f7)";
        inner_color = "rgb(1a1b26)";
        font_color = "rgb(c0caf5)";
        fade_on_empty = true;
        placeholder_text = "<i>Password...</i>";
        hide_input = false;
        rounding = 15;
        check_color = "rgb(9ece6a)";
        fail_color = "rgb(f7768e)";
        fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
        capslock_color = "rgb(e0af68)";
        position = "0, -20";
        halign = "center";
        valign = "center";
      }];
      
      label = [
        {
          monitor = "";
          text = "cmd[update:1000] echo \"<span foreground='##c0caf5'>$(date +\"%H:%M\")</span>\"";
          text_align = "center";
          color = "rgba(200, 202, 245, 1.0)";
          font_size = 90;
          font_family = "JetBrainsMono Nerd Font Bold";
          position = "0, 150";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "cmd[update:60000] echo \"<span foreground='##a9b1d6'>$(date +\"%A, %B %d\")</span>\"";
          text_align = "center";
          color = "rgba(169, 177, 214, 1.0)";
          font_size = 24;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 60";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "Hi, $USER 👋";
          text_align = "center";
          color = "rgba(200, 202, 245, 1.0)";
          font_size = 18;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, -80";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  # ══════════════════════════════════════════════════════════════════════════════
  # Hypridle - Idle Management
  # ══════════════════════════════════════════════════════════════════════════════
  
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      
      listener = [
        {
          timeout = 300;
          on-timeout = "brightnessctl -s set 10";
          on-resume = "brightnessctl -r";
        }
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 900;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  # ══════════════════════════════════════════════════════════════════════════════
  # Shell & Terminal
  # ══════════════════════════════════════════════════════════════════════════════
  
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
      starship init fish | source
    '';
    shellAliases = {
      # File listing
      ls = "eza --icons --group-directories-first";
      ll = "eza -la --icons --group-directories-first --git";
      la = "eza -a --icons --group-directories-first";
      lt = "eza --tree --icons --group-directories-first --level=3";
      
      # Modern replacements
      cat = "bat --style=auto";
      grep = "rg";
      find = "fd";
      
      # Navigation
      cd.. = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      cls = "clear";
      
      # Safety
      rm = "trash-put";
      
      # Git
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph";
      gd = "git diff";
      
      # NixOS
      nrs = "sudo nixos-rebuild switch --flake /etc/nixos#${hostname}";
      nrt = "sudo nixos-rebuild test --flake /etc/nixos#${hostname}";
      ncg = "sudo nix-collect-garbage -d";
      
      # Caelestia
      cae-shell = "qs -c caelestia";
    };
  };

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
      
      nodejs.style = "bg:#e0af68 fg:#1a1b26";
      python.style = "bg:#e0af68 fg:#1a1b26";
      rust.style = "bg:#e0af68 fg:#1a1b26";
      
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
      mouse.hide-when-typing = "yes";
      colors = {
        alpha = 0.92;
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

  # ══════════════════════════════════════════════════════════════════════════════
  # Development Tools
  # ══════════════════════════════════════════════════════════════════════════════
  
  programs.git = {
    enable = true;
    userName = username;
    userEmail = "user@example.com";  # CHANGE THIS
    delta = {
      enable = true;
      options = {
        navigate = true;
        side-by-side = true;
      };
    };
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # ══════════════════════════════════════════════════════════════════════════════
  # System Utilities
  # ══════════════════════════════════════════════════════════════════════════════
  
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "tokyo-night";
      theme_background = false;
      vim_keys = true;
    };
  };

  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=12";
        terminal = "foot";
        layer = "overlay";
        prompt = "❯ ";
      };
      colors = {
        background = "1a1b26ee";
        text = "c0caf5ff";
        match = "7aa2f7ff";
        selection = "33467cff";
        selection-text = "c0caf5ff";
        selection-match = "7aa2f7ff";
        border = "7aa2f7ff";
      };
      border = {
        width = 2;
        radius = 12;
      };
    };
  };

  # ══════════════════════════════════════════════════════════════════════════════
  # Packages
  # ══════════════════════════════════════════════════════════════════════════════
  
  home.packages = with pkgs; [
    # Development
    nodejs
    python3
    
    # CLI tools
    ripgrep
    fzf
    jq
    yq
    
    # Fun
    cmatrix
    pipes
    sl
  ];

  # ══════════════════════════════════════════════════════════════════════════════
  # XDG & Theming
  # ══════════════════════════════════════════════════════════════════════════════
  
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
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # ══════════════════════════════════════════════════════════════════════════════
  # Session Variables & Extra Files
  # ══════════════════════════════════════════════════════════════════════════════
  
  home.sessionVariables = {
    EDITOR = "nano";
    VISUAL = "nano";
    BROWSER = "firefox";
    TERMINAL = "foot";
  };

  # Caelestia shell config (for when you run qs -c caelestia)
  home.file.".config/caelestia/shell.json".text = builtins.toJSON {
    wallpapers_path = "~/Pictures/Wallpapers";
    terminal = "foot";
    file_manager = "thunar";
    browser = "firefox";
  };

  # Ensure directories exist
  home.file."Pictures/Wallpapers/.keep".text = "";
  home.file."Pictures/Screenshots/.keep".text = "";

  # Clone caelestia shell for quickshell (still needed for the qs config)
  home.activation.cloneCaelestiaShell = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -d "$HOME/.config/quickshell/caelestia" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config/quickshell"
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/caelestia-dots/shell.git "$HOME/.config/quickshell/caelestia" || true
    fi
  '';
}
