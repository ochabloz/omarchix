{ config, lib, pkgs, ... }:


with lib;

let
  cfg = config.tooling;
  localshareDir = "/home/${cfg.username}/.local/share/olynix";
  logo_file = "${localshareDir}/logo.txt";
  screensaver_file = "${localshareDir}/screensaver.txt";
  screensaver_cfg = "${localshareDir}/alacritty_screensaver.toml";
in

{
  options.tooling = {
    enable = mkEnableOption "add specific tools to distro";
    username = mkOption {
      type = types.str;
      description = "Username for the home directory";
    };
  };

  config = mkIf cfg.enable {


    system.activationScripts.createLocalFile = ''
            if [ ! -f ${logo_file} ]; then
              mkdir -p ${localshareDir}
              cat > ${logo_file} << 'EOF'
                       ▄▄▄
       ▄█████▄    ▄███████████▄    ▄███████   ▄███████   ▄███████   ▄█   █▄    ▄█   █▄
      ███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
      ███   ███  ███   ███   ███  ███   ███  ███   ███  ███   █▀   ███   ███  ███   ███
      ███   ███  ███   ███   ███ ▄███▄▄▄███ ▄███▄▄▄██▀  ███       ▄███▄▄▄███▄ ███▄▄▄███
      ███   ███  ███   ███   ███ ▀███▀▀▀███ ▀███▀▀▀▀    ███      ▀▀███▀▀▀███  ▀▀▀▀▀▀███
      ███   ███  ███   ███   ███  ███   ███ ██████████  ███   █▄   ███   ███  ▄██   ███
      ███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
       ▀█████▀    ▀█   ███   █▀   ███   █▀   ███   ███  ███████▀   ███   █▀    ▀█████▀
                                             ███   █▀
      EOF
              chown ${cfg.username}:users ${logo_file}
        
            fi
      
            if [ ! -f ${screensaver_file} ]; then
              mkdir -p ${localshareDir}
              cp ${logo_file} ${screensaver_file}
            fi

            if [ ! -f ${screensaver_cfg} ]; then
              mkdir -p ${localshareDir}
              cat > ${screensaver_cfg} << 'EOF'
      [colors.primary]
      background = "0x000000"

      [colors.cursor]
      cursor = "0x000000"

      [font]
      size = 18.0

      [window]
      opacity = 1.0
      EOF
              chown ${cfg.username}:users ${logo_file}
            fi
    '';


    environment.systemPackages = with pkgs; [

      # Core utilities
      coreutils
      findutils
      gnugrep
      gnused
      gawk

      # Shells
      # ghostty is provided by desktop/hyprland.nix with theme wrapper
      alacritty
      starship

      # System tools
      htop
      btop
      bat
      neofetch
      tree
      wget
      curl

      # systems settings
      blueberry # bluetooth settings
      pamixer # audio settings
      wiremix # audio settings

      # CLI tools
      ripgrep
      fd
      bat
      eza
      fzf
      zoxide
      jq
      yq
      httpie


      # Development basics
      git
      gnumake
      gcc

      # Nix tools
      nix-prefetch-git
      nixpkgs-fmt
      nil


      slurp
      satty
      hyprshot

      # GUI tools
      imv # image viewer

      (writeShellScriptBin "olynix-cmd-screenshot" ''
        #!/bin/bash

        OUTPUT_DIR="''${OLYNIX_SCREENSHOT_DIR:-''${XDG_PICTURES_DIR:-$HOME/Pictures}}"

        if [[ ! -d "$OUTPUT_DIR" ]]; then
        notify-send "Screenshot directory does not exist: $OUTPUT_DIR" -u critical -t 3000
        exit 1
        fi

        pkill slurp || hyprshot -m ''${1:-region} --raw |
        satty --filename - \
            --output-filename "$OUTPUT_DIR/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png" \
            --early-exit \
            --actions-on-enter save-to-clipboard \
            --save-after-copy \
            --copy-command 'wl-copy'
      '')

      brave # Make sure brave is installed
      (writeShellScriptBin "olynix-launch-webapp" ''

      exec setsid uwsm app -- ${pkgs.brave}/bin/brave --app="''$1" "''${@:2}"
      '')

      (writeShellScriptBin "olynix-lock" ''

      pidof hyprlock || hyprlock --grace 5 &  # Lock the screen

      # Ensure 1password is locked
      if pgrep -x "1password" >/dev/null; then
        1password --lock &
      fi

      # Avoid running screensaver when locked
      pkill -f "$TERMINAL --class Screensaver"
      '')

      (writeShellScriptBin "olynix-launch-editor" ''

      case "${EDITOR:-nvim}" in
      nvim | vim | nano | micro | hx)
        exec setsid uwsm app -- "$TERMINAL" -e "$EDITOR" "$@"
        ;;
      *)
        exec setsid uwsm app -- "$EDITOR" "$@"
        ;;
      esac
      '')

      (writeShellScriptBin "olynix-launch-floating-terminal-with-presentation" ''

      cmd="$*"
      exec setsid uwsm app -- alacritty --class=Olynix --title=OLYnix -e bash -c "olynix-show-logo; $cmd; olynix-show-done"
      '')

      (writeShellScriptBin "olynix-show-logo" ''
        #!/bin/bash

        clear
        echo -e "\033[32m"
        cat <${logo_file}
        echo -e "\033[0m"
        echo
      '')

      gum
      (writeShellScriptBin "olynix-show-done" ''

      echo
      ${pkgs.gum}/bin/gum spin --spinner "globe" --title "Done! Press any key to close..." -- bash -c 'read -n 1 -s'
      '')

      terminaltexteffects

      (writeShellScriptBin "olynix-cmd-screensaver" ''
        #!/bin/bash

        screensaver_in_focus() {
          hyprctl activewindow -j | jq -e '.class == "Screensaver"' >/dev/null 2>&1
        }

        exit_screensaver() {
          hyprctl keyword cursor:invisible false
          pkill -x tte 2>/dev/null
          pkill -f "alacritty --class Screensaver" 2>/dev/null
          exit 0
        }

        trap exit_screensaver SIGINT SIGTERM SIGHUP SIGQUIT

        hyprctl keyword cursor:invisible true

        while true; do
          effect=$(tte 2>&1 | grep -oP '{\K[^}]+' | tr ',' ' ' | tr ' ' '\n' | sed -n '/^beams$/,$p' | sort -u | shuf -n1)
          tte -i ${screensaver_file} \
            --frame-rate 240 --canvas-width 0 --canvas-height $(($(tput lines) - 2)) --anchor-canvas c --anchor-text c \
            "$effect" &
          tte_pid=$!

          while kill -0 $tte_pid 2>/dev/null; do
            if read -n 1 -t 3 || ! screensaver_in_focus; then
              exit_screensaver
            fi
          done
        done
      '')

      (writeShellScriptBin "olynix-launch-screensaver" ''
        # Exit early if screensave is already running
        pgrep -f "alacritty --class Screensaver" && exit 0

        # Allow screensaver to be turned off but also force started
        if [[ -f ~/.local/state/olynix/toggles/screensaver-off ]] && [[ $1 != "force" ]]; then
          exit 1
        fi

        focused=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')

        for m in $(hyprctl monitors -j | jq -r '.[] | .name'); do
          hyprctl dispatch focusmonitor $m

          # FIXME: Find a way to make this generic where we it can work for kitty + ghostty
          hyprctl dispatch exec -- \
            alacritty --class Screensaver \
            --config-file ${screensaver_cfg} \
            -e olynix-cmd-screensaver
        done

        hyprctl dispatch focusmonitor $focused
      '')

      (writeShellScriptBin "olynix-toggle-screensaver" ''

      STATE_FILE=~/.local/state/olynix/toggles/screensaver-off

      if [[ -f $STATE_FILE ]]; then
        rm -f $STATE_FILE
        notify-send "󱄄   Screensaver enabled"
      else
        mkdir -p "$(dirname $STATE_FILE)"
        touch $STATE_FILE
        notify-send "󱄄   Screensaver disabled"
      fi
      '')

      gum
      (writeShellScriptBin "olynix-webapp-install" ''

      if [ "$#" -lt 3 ]; then
        echo -e "\e[32mLet's create a new web app you can start with the app launcher.\n\e[0m"
        APP_NAME=$(gum input --prompt "Name> " --placeholder "My favorite web app")
        APP_URL=$(gum input --prompt "URL> " --placeholder "https://example.com")
        ICON_REF=$(gum input --prompt "Icon URL> " --placeholder "See https://dashboardicons.com (must use PNG!)")
        CUSTOM_EXEC=""
        MIME_TYPES=""
        INTERACTIVE_MODE=true
      else
        APP_NAME="$1"
        APP_URL="$2"
        ICON_REF="$3"
        CUSTOM_EXEC="$4" # Optional custom exec command
        MIME_TYPES="$5"  # Optional mime types
        INTERACTIVE_MODE=false
      fi

      # Ensure valid execution
      if [[ -z "$APP_NAME" || -z "$APP_URL" || -z "$ICON_REF" ]]; then
        echo "You must set app name, app URL, and icon URL!"
        exit 1
      fi

      # Refer to local icon or fetch remotely from URL
      ICON_DIR="$HOME/.local/share/applications/icons"
      mkdir -p $ICON_DIR
      if [[ $ICON_REF =~ ^https?:// ]]; then
        ICON_PATH="$ICON_DIR/$APP_NAME.png"
        if curl -sL -o "$ICON_PATH" "$ICON_REF"; then
          ICON_PATH="$ICON_DIR/$APP_NAME.png"
        else
          echo "Error: Failed to download icon."
          exit 1
        fi
      else
        ICON_PATH="$ICON_DIR/$ICON_REF"
      fi

      # Use custom exec if provided, otherwise default behavior
      if [[ -n $CUSTOM_EXEC ]]; then
        EXEC_COMMAND="$CUSTOM_EXEC"
      else
        EXEC_COMMAND="olynix-launch-webapp $APP_URL"
      fi

      # Create application .desktop file
      DESKTOP_FILE="$HOME/.local/share/applications/$APP_NAME.desktop"

      cat >"$DESKTOP_FILE" <<EOF
      [Desktop Entry]
      Version=1.0
      Name=$APP_NAME
      Comment=$APP_NAME
      Exec=$EXEC_COMMAND
      Terminal=false
      Type=Application
      Icon=$ICON_PATH
      StartupNotify=true
      EOF

      # Add mime types if provided
      if [[ -n $MIME_TYPES ]]; then
        echo "MimeType=$MIME_TYPES" >>"$DESKTOP_FILE"
      fi

      chmod +x "$DESKTOP_FILE"

      if [[ $INTERACTIVE_MODE == true ]]; then
        echo -e "You can now find $APP_NAME using the app launcher (SUPER + SPACE)\n"
      fi
      '')

      (writeShellScriptBin "olynix-webapp-remove" ''

      ICON_DIR="$HOME/.local/share/applications/icons"
      DESKTOP_DIR="$HOME/.local/share/applications/"

      if [ "$#" -eq 0 ]; then
        # Find all web apps
        while IFS= read -r -d $'\0' file; do
          if grep -q '^Exec=.*olynix-launch-webapp.*' "$file"; then
            WEB_APPS+=("$(basename "''${file%.desktop}")")
          fi
        done < <(find "$DESKTOP_DIR" -name '*.desktop' -print0)

        if ((''${#WEB_APPS[@]})); then
          IFS=$'\n' SORTED_WEB_APPS=($(sort <<<"''${WEB_APPS[*]}"))
          unset IFS
          APP_NAMES_STRING=$(gum choose --no-limit --header "Select web app to remove..." --selected-prefix="✗ " "''${SORTED_WEB_APPS[@]}")
          # Convert newline-separated string to array
          APP_NAMES=()
          while IFS= read -r line; do
            [[ -n "$line" ]] && APP_NAMES+=("$line")
          done <<< "$APP_NAMES_STRING"
        else
          echo "No web apps to remove."
          exit 1
        fi
      else
        # Use array to preserve spaces in app names
        APP_NAMES=("$@")
      fi

      if [[ ''${#APP_NAMES[@]} -eq 0 ]]; then
        echo "You must provide web app names."
        exit 1
      fi

      for APP_NAME in "''${APP_NAMES[@]}"; do
        rm -f "$DESKTOP_DIR/$APP_NAME.desktop"
        rm -f "$ICON_DIR/$APP_NAME.png"
        echo "Removed $APP_NAME"
      done
      '')

    ];
  };
}
