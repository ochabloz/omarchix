{
  description = "OmarChix - NixOS configuration modules with sensible defaults";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    {
      # NixOS modules that can be imported
      nixosModules = {
        # Desktop module (Hyprland)
        desktop = ./desktop/hyprland.nix;

        # Nixvim module
        nixvim = ./nixvim/nixvim.nix;

        # Default module includes all modules
        default = { config, lib, pkgs, ... }: {
          imports = [
            ./desktop/hyprland.nix
            ./nixvim/nixvim.nix
          ];
        };
      };

      # Convenience: export all modules as a single attribute
      nixosModule = self.nixosModules.default;
    };
}
