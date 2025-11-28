{ config, pkgs, lib, inputs, ... }:

with lib;

let
  cfg = config.desktop;
in
{
  imports = [

    ./tooling.nix
    ./menu.nix
  ];
  options.desktop = {
    enable = mkEnableOption "OmniXY Hyprland desktop environment";

    monitors = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "DP-1,1920x1080@144,0x0,1" ];
      description = "Monitor configuration for Hyprland";
    };

    defaultTerminal = mkOption {
      type = types.str;
      default = "ghostty";
      description = "Default terminal emulator";
    };


    username = mkOption {
      type = types.str;
      default = "oly";
      description = "Default username";
    };

    defaultBrowser = mkOption {
      type = types.str;
      default = "firefox";
      description = "Default web browser";
    };

    wallpaper = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to wallpaper image (optional)";
    };

    idleSuspend = mkOption {
      type = types.bool;
      default = false;
      description = "Enable system suspend after idle timeout";
    };

    theme = mkOption {
      type = types.str;
      default = "gruvbox";
      description = "System theme name (used for neovim and other applications)";
      example = "nord";
    };
  };

  config = mkIf (cfg.enable) {
    ### Enable Hyprland
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;

      #package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.bash}/bin/bash -c 'sleep 3; exec ${pkgs.tuigreet}/bin/tuigreet --time -r --remember-user-session --cmd hyprland'";
          user = "greeter";
        };
      };
    };

    tooling = {
      enable = true;
      username = cfg.username;
    };

    # XDG portal for Wayland
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];
      config.common.default = "*";
    };

    # Session variables
    environment.sessionVariables = {
      # Wayland specific
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      GDK_BACKEND = "wayland";
      WLR_NO_HARDWARE_CURSORS = "1";

      # Default applications
      TERMINAL = cfg.defaultTerminal;
      BROWSER = cfg.defaultBrowser;
      EDITOR = "nvim";
    };

    # Copy wallpapers to /etc/olynix/themes/wallpapers
    system.activationScripts.copyWallpapers = ''
      WALLPAPER_SRC="/etc/nixos/themes/wallpapers/${cfg.theme}"
      WALLPAPER_DST="/etc/olynix/themes/wallpapers"

      if [ -d "$WALLPAPER_SRC" ]; then
        mkdir -p "$WALLPAPER_DST"
        rm -rf "$WALLPAPER_DST"/*
        cp -r "$WALLPAPER_SRC"/* "$WALLPAPER_DST"/ 2>/dev/null || true
        chmod -R 755 "$WALLPAPER_DST"
      fi
    '';

    # Initialize and validate wallpaper symlink for each user
    system.activationScripts.initWallpaperSymlink = ''
      for USER_HOME in /home/*; do
        if [ -d "$USER_HOME" ]; then
          USERNAME=$(basename "$USER_HOME")

          # Check if this is a real user (exists in passwd)
          if ! getent passwd "$USERNAME" >/dev/null 2>&1; then
            continue
          fi

          STATE_DIR="$USER_HOME/.local/state/olynix"
          SYMLINK="$STATE_DIR/current_background"
          WALLPAPER_DIR="/etc/olynix/themes/wallpapers"

          # Create state directory
          mkdir -p "$STATE_DIR"
          chown -R "$USERNAME:users" "$STATE_DIR"

          # Check if symlink is valid
          NEEDS_INIT=false
          if [ ! -L "$SYMLINK" ]; then
            NEEDS_INIT=true
          elif [ ! -e "$SYMLINK" ]; then
            # Symlink exists but points to non-existent file
            NEEDS_INIT=true
            rm -f "$SYMLINK"
          fi

          # Initialize symlink if needed
          if [ "$NEEDS_INIT" = true ]; then
            # Find first wallpaper
            FIRST_WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | sort | head -n 1)
            if [ -n "$FIRST_WALLPAPER" ]; then
              ln -sf "$FIRST_WALLPAPER" "$SYMLINK"
              chown -h "$USERNAME:users" "$SYMLINK"
              echo "Initialized wallpaper symlink for $USERNAME: $(basename "$FIRST_WALLPAPER")"
            fi
          fi
        fi
      done
    '';

    # Theme-based CSS files
    environment.etc =
      let
        # Color palettes for each theme
        colors = {
          "nord" = {
            bg = "#2e3440";
            fg = "#d8dee9";
            select = "#88c0d0";
            border = "#d8dee9";
          };
          "tokyo-night" = {
            bg = "#1a1b26";
            fg = "#cfc9c2";
            select = "#7dcfff";
            border = "#33ccff";
          };
          "catppuccin-latte" = {
            bg = "#eff1f5";
            fg = "#4c4f69";
            select = "#1e66f5";
            border = "#dce0e8";
          };
          "catppuccin" = {
            bg = "#24273a";
            fg = "#c6d0f5";
            select = "#8caaee";
            border = "#c6d0f5";
          };
          "gruvbox" = {
            bg = "#282828";
            fg = "#ebdbb2";
            select = "#fabd2f";
            border = "#ebdbb2";
          };
          "everforest" = {
            bg = "#2d353b";
            fg = "#d3c6aa";
            select = "#dbbc7f";
            border = "#d3c6aa";
          };
          "rose-pine" = {
            bg = "#faf4ed";
            fg = "#575279";
            select = "#88C0D0";
            border = "#575279";

          };
          "kanagawa" = {
            bg = "#1f1f28";
            fg = "#dcd7ba";
            select = "#dca561";
            border = "#dcd7ba";
         };
        }.${cfg.theme} or {
          bg = "#282828";
          fg = "#ebdbb2";
          select = "#d79921";
          border = "#b16286";
        };
      in
      {
        "olynix/themes/waybar.css".text = ''
          /* Waybar CSS with ${cfg.theme} theme */
          @define-color foreground ${colors.fg}; /* text */
          @define-color background ${colors.bg}; /* base */
          @define-color border     ${colors.border}; /* crust */
          @define-color accent     ${colors.select}; /* blue */
        '';

        "olynix/themes/walker.css".text = ''
          /* Walker CSS with ${cfg.theme} theme */
          @define-color selected-text ${colors.select};
          @define-color text ${colors.fg};
          @define-color base ${colors.bg};
          @define-color border ${colors.border};
          @define-color foreground ${colors.fg};
          @define-color background ${colors.bg};
        '';

        "olynix/themes/swayosd.css".text = ''
          /* SwayOSD CSS with ${cfg.theme} theme */
          @define-color background-color ${colors.bg};
          @define-color border-color ${colors.select};
          @define-color label ${colors.fg};
          @define-color image ${colors.fg};
          @define-color progress ${colors.fg};
        '';

        "olynix/themes/hyprland.conf".text = ''
          $activeBorderColor = rgb(${lib.toUpper (lib.removePrefix "#" colors.fg)})
          general {
              col.active_border = $activeBorderColor
          }

          group {
              col.border_active = $activeBorderColor
          }
        '';
      };

    # Essential packages for Hyprland
    environment.systemPackages =
      let
        # Wallpaper management script with persistent state
        wallpaper-set = pkgs.writeShellScriptBin "wallpaper-set" ''
          WALLPAPER_DIR="/etc/olynix/themes/wallpapers"
          STATE_FILE="$HOME/.local/state/olynix/wallpaper-index"
          SYMLINK="$HOME/.local/state/olynix/current_background"

          STATE_DIR="$(dirname "$STATE_FILE")"

          # Create state directory if it doesn't exist
          mkdir -p "$STATE_DIR"

          # Get sorted list of wallpapers
          WALLPAPERS=($(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | sort))
          TOTAL=''${#WALLPAPERS[@]}

          if [ "$TOTAL" -eq 0 ]; then
            echo "No wallpapers found in $WALLPAPER_DIR"
            exit 1
          fi

          # Read current index or start at 0
          if [ -f "$STATE_FILE" ]; then
            CURRENT=$(cat "$STATE_FILE")
          else
            CURRENT=0
          fi

          # Check if "next" argument is provided
          if [ "$1" = "next" ]; then
            # Increment and wrap around
            INDEX=$(( (CURRENT + 1) % TOTAL ))
            # Save new index
            echo "$INDEX" > "$STATE_FILE"
          else
            # Use current index
            INDEX=$CURRENT
          fi

          # Get the wallpaper path
          WALLPAPER="''${WALLPAPERS[$INDEX]}"

          # Update symlink
          ln -sf "$WALLPAPER" "$SYMLINK"

          # Restart swaybg
          ${pkgs.procps}/bin/pkill swaybg || true
          setsid uwsm-app -- ${pkgs.swaybg}/bin/swaybg -i "$SYMLINK" -m fill >/dev/null 2>&1 &

          echo "Wallpaper set to: $(basename "$WALLPAPER") [$((INDEX + 1))/$TOTAL]"
        '';

        # Map theme names to ghostty theme names
        ghosttyTheme = {
          "nord" = "Nord";
          "tokyo-night" = "TokyoNight";
          "catppuccin" = "Catppuccin Mocha";
          "catppuccin-latte" = "Catppuccin Latte";
          "gruvbox" = "Gruvbox Dark";
          "everforest" = "Everforest Dark Hard";
          "rose-pine" = "Rose Pine";
          "kanagawa" = "Kanagawa Dragon";
        }.${cfg.theme} or "Gruvbox Dark";

        # Wrapped ghostty with theme
        ghostty-themed = pkgs.symlinkJoin {
          name = "ghostty";
          paths = [ pkgs.ghostty ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/ghostty \
              --add-flags "--theme=${ghosttyTheme}"
          '';
        };
      in
      with pkgs; [
        # Wallpaper management
        wallpaper-set

        # Terminal with theme
        ghostty-themed
        tmux

        # Core Wayland utilities
        wayland
        wayland-protocols
        wayland-utils
        wlroots

        # Hyprland ecosystem
        hyprland-protocols
        hyprlock
        hypridle
        hyprpicker

        swayosd

        # Wallpaper daemon
        swaybg

        # Status bar and launcher
        waybar
        #wofi
        #rofi-wayland
        walker

        # Notification daemon
        mako
        libnotify

        # Clipboard
        wl-clipboard
        cliphist
        copyq

        # Screen management
        wlr-randr
        kanshi
        nwg-displays

        # Screenshots and recording
        grim
        swappy
        wf-recorder

        # System tray and applets
        networkmanagerapplet
        blueman
        pasystray

        #File managers
        nautilus

        # Polkit agent
        polkit_gnome

        # Themes and cursors
        pkgs.adwaita-icon-theme
        papirus-icon-theme
        bibata-cursors
        capitaine-cursors

      ];

    programs.yazi = {
      enable = true;
      package = pkgs.yazi;
      plugins = {
        "mount.yazi" = pkgs.yaziPlugins.mount;
      };
    };

    fonts.packages = with pkgs; [
      nerd-fonts.caskaydia-mono
      nerd-fonts.caskaydia-cove
    ];
  };
}
