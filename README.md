# omarchix

NixOS configuration modules with sensible defaults for desktop environments and development tools.

## Modules

- **desktop**: Hyprland desktop environment with theming, wallpaper management, and essential tools
- **nixvim**: Preconfigured Neovim with LSP, autocomplete, debugging, and theme integration

## Usage

### Using with Flakes (Recommended)

#### 1. Add omarchix to your flake inputs

In your main NixOS configuration's `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    omarchix.url = "github:YOUR_USERNAME/omarchix";
    # For local development (see below)
    # omarchix.url = "path:/path/to/omarchix";
  };

  outputs = { self, nixpkgs, omarchix, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        # Import all modules
        omarchix.nixosModules.default
        # OR import specific modules
        # omarchix.nixosModules.desktop
        # omarchix.nixosModules.nixvim
      ];
    };
  };
}
```

#### 2. Configure the modules in your `configuration.nix`

```nix
{ config, pkgs, ... }:

{
  # Enable desktop environment
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

### Using without Flakes

In your `/etc/nixos/configuration.nix`:

```nix
{ config, pkgs, ... }:

let
  omarchix = builtins.fetchGit {
    url = "https://github.com/YOUR_USERNAME/omarchix";
    ref = "main";
  };
in
{
  imports = [
    # Import all modules
    omarchix
    # OR import specific modules
    # "${omarchix}/desktop/hyprland.nix"
    # "${omarchix}/nixvim/nixvim.nix"
  ];

  desktop = {
    enable = true;
    username = "yourusername";
    theme = "gruvbox";
  };
}
```

## Local Development

For local development without committing/pushing changes, use a local path reference:

### Method 1: Local Flake Input (Recommended)

In your main configuration's `flake.nix`, change the input to a local path:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    omarchix.url = "path:/home/yourusername/path/to/omarchix";
    # OR use relative path
    # omarchix.url = "path:../omarchix";
  };

  # ... rest of your flake config
}
```

Then rebuild normally:

```bash
sudo nixos-rebuild switch --flake .#your-hostname
```

**Important**: Changes to the local omarchix directory are picked up immediately. You don't need to commit or push to test your changes.

### Method 2: Direct Import (without Flakes)

In your `/etc/nixos/configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  imports = [
    /home/yourusername/path/to/omarchix
    # OR
    # /home/yourusername/path/to/omarchix/desktop/hyprland.nix
    # /home/yourusername/path/to/omarchix/nixvim/nixvim.nix
  ];

  desktop = {
    enable = true;
    username = "yourusername";
  };
}
```

Rebuild:

```bash
sudo nixos-rebuild switch
```

### Method 3: NIX_PATH Override

Set `NIX_PATH` to include your local development directory:

```bash
sudo nixos-rebuild switch -I omarchix=/home/yourusername/path/to/omarchix
```

Then in your configuration:

```nix
{ config, pkgs, ... }:

{
  imports = [
    <omarchix>
  ];
}
```

### Switching Between Local and Remote

When you're done developing and want to use the committed version:

1. **Commit and push your changes**:
   ```bash
   cd /path/to/omarchix
   git add .
   git commit -m "Your changes"
   git push
   ```

2. **Switch back to git reference** in your main flake:
   ```nix
   omarchix.url = "github:YOUR_USERNAME/omarchix";
   ```

3. **Update the flake lock**:
   ```bash
   nix flake update omarchix
   ```

## Development Workflow

1. **Clone this repo** to your local machine
2. **Point your main config** to the local path (using one of the methods above)
3. **Make changes** to omarchix modules
4. **Test immediately** with `sudo nixos-rebuild switch`
5. **Iterate** without committing
6. **When satisfied**, commit and push your changes
7. **Optionally**, switch back to git reference in your main config

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

## Contributing

Feel free to open issues or submit pull requests to improve these modules.
