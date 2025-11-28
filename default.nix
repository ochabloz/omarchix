# Default module - imports all omarchix modules
{ config, lib, pkgs, ... }:

{
  imports = [
    ./desktop/hyprland.nix
    ./nixvim/nixvim.nix
  ];
}
