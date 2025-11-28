# omarchix

NixOS configuration modules with sensible defaults for desktop environments and development tools.

## Modules

- **desktop**: Hyprland desktop environment with theming, wallpaper management, and essential tools
- **nixvim**: Preconfigured Neovim with LSP, autocomplete, debugging, and theme integration

## Usage

### Basic Setup

In your `/etc/nixos/configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  imports = [
    /path/to/omarchix  # Import all modules
    # OR import specific modules:
    # /path/to/omarchix/desktop/hyprland.nix
    # /path/to/omarchix/nixvim/nixvim.nix
  ];

  # Enable and configure desktop environment
  desktop = {
    enable = true;
    username = "yourusername";
    monitors = [ "DP-1,1920x1080@144,0x0,1" ];
    theme = "gruvbox";  # Options: nord, tokyo-night, catppuccin, gruvbox, everforest, rose-pine, kanagawa
    defaultTerminal = "ghostty";
    defaultBrowser = "firefox";
  };

  # Nixvim is automatically configured with the desktop theme
}
```

Then rebuild:
```bash
sudo nixos-rebuild switch
```

### Using from GitHub

If you want to pull from GitHub instead of a local path:

```nix
{ config, pkgs, ... }:

let
  omarchix = builtins.fetchGit {
    url = "https://github.com/ochabloz/omarchix";
    ref = "main";  # or specify a branch/tag
  };
in
{
  imports = [ omarchix ];

  desktop = {
    enable = true;
    username = "yourusername";
    theme = "gruvbox";
  };
}
```

**Note**: `fetchGit` will fetch the latest version on each rebuild. For pinning to specific commits, see the Advanced Options section below.

## Local Development

The simplest workflow for developing omarchix without committing:

1. **Clone this repository** somewhere on your system:
   ```bash
   git clone https://github.com/ochabloz/omarchix ~/omarchix
   ```

2. **Point your configuration** to the local path:
   ```nix
   {
     imports = [ /home/yourusername/omarchix ];
     desktop.enable = true;
   }
   ```

3. **Make changes** to the omarchix files

4. **Test immediately**:
   ```bash
   sudo nixos-rebuild switch
   ```

5. **Iterate** - changes are picked up instantly, no commits needed!

6. **When satisfied**, commit and push:
   ```bash
   cd ~/omarchix
   git add .
   git commit -m "Your changes"
   git push
   ```

7. **Optionally switch to GitHub reference** in your main config

### Development Tips

- Keep the absolute path import (`/home/you/omarchix`) during development
- Changes to any `.nix` file are immediately available on rebuild
- No need to update lockfiles or flake inputs
- Switch to `fetchGit` when you want a stable, committed version

## Available Options

### Desktop Module

- `desktop.enable`: Enable the Hyprland desktop environment
- `desktop.monitors`: List of monitor configurations
- `desktop.username`: Default username
- `desktop.defaultTerminal`: Default terminal emulator (default: "ghostty")
- `desktop.defaultBrowser`: Default web browser (default: "firefox")
- `desktop.theme`: System theme name (default: "gruvbox")
- `desktop.wallpaper`: Path to wallpaper image (optional)
- `desktop.idleSuspend`: Enable system suspend after idle timeout (default: false)

### Nixvim Module

Nixvim automatically inherits the theme from `desktop.theme` and requires no additional configuration. It includes:
- LSP support
- Autocompletion
- Debugging support
- Telescope file finder
- Neo-tree file explorer
- Theme integration with desktop environment

## Themes

Available themes:
- `gruvbox` (default)
- `nord`
- `tokyo-night`
- `catppuccin`
- `catppuccin-latte`
- `everforest`
- `rose-pine`
- `kanagawa`

Themes are applied consistently across:
- Neovim (nixvim)
- Terminal (ghostty)
- Waybar
- Walker launcher
- SwayOSD
- Hyprland borders

## Wallpapers

Wallpapers are automatically fetched from the [omarchy repository](https://github.com/basecamp/omarchy) during system build. Each theme has a corresponding wallpaper collection in `/themes/[theme_name]/backgrounds`.

The system:
- Fetches wallpapers using `pkgs.fetchFromGitHub` with sparse checkout for efficiency
- Copies theme-matching wallpapers to `/etc/olynix/themes/wallpapers` during activation
- Initializes a symlink at `~/.local/state/olynix/current_background` pointing to the first wallpaper
- Provides the `wallpaper-set` command to cycle through wallpapers:
  - `wallpaper-set` - Display current wallpaper
  - `wallpaper-set next` - Switch to next wallpaper in the collection

**Note:** On first build, Nix will prompt you to add the correct hash for the omarchy repository. This is normal - just copy the suggested hash into `desktop/hyprland.nix` and rebuild.

## Advanced Options

### Pinning to a Specific Commit

```nix
let
  omarchix = builtins.fetchGit {
    url = "https://github.com/ochabloz/omarchix";
    rev = "abc123...";  # specific commit hash
  };
in
{ imports = [ omarchix ]; }
```

### Using NIX_PATH

```bash
sudo nixos-rebuild switch -I omarchix=/path/to/omarchix
```

Then in your configuration:
```nix
{ imports = [ <omarchix> ]; }
```

### Flakes Support

If you prefer using flakes, you can add a `flake.nix` to this repository. The modules are already structured to work with flakes - just expose them as `nixosModules` in the flake outputs.

## Contributing

Feel free to open issues or submit pull requests to improve these modules.
