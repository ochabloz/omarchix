{ lib, pkgs, config, ... }:

let
  nixvim = import (
    builtins.fetchGit {
      url = "https://github.com/nix-community/nixvim";
      # When using a different channel you can use `ref = "nixos-<version>"` to set it here
    }
  );

  # Map theme names to neovim colorschemes
  themeToColorscheme = theme:
    {
      "nord" = "nordfox";
      "tokyo-night" = "tokyonight";
      "catppuccin" = "catppuccin";
      "catppuccin-latte" = "catppuccin-latte";
      "gruvbox" = "gruvbox";
      "everforest" = "everforest";
      "rose-pine" = "rose-pine";
      "kanagawa" = "kanagawa";
      "matte-black" = "base16-black-metal";
      "osaka-jade" = "base16-greenscreen";
      "ristretto" = "base16-ashes";
    }.${theme} or "gruvbox"; # fallback to gruvbox if theme not found

  desktopTheme = config.desktop.theme or "gruvbox";
  nvimColorscheme = themeToColorscheme desktopTheme;
in
{
  imports = [
    nixvim.nixosModules.nixvim
  ];

  programs.nixvim = {
    enable = true;

    imports = [
      ./base.nix
      ./autocomplete.nix
      ./lsp.nix
      ./debugging.nix
    ];

    # Set colorscheme based on desktop theme
    colorscheme = nvimColorscheme;

    # Enable the corresponding colorscheme plugin (if available as a nixvim plugin)
    colorschemes = {
      gruvbox.enable = (nvimColorscheme == "gruvbox");
      tokyonight.enable = (nvimColorscheme == "tokyonight");
      catppuccin.enable = (nvimColorscheme == "catppuccin" || nvimColorscheme == "catppuccin-latte");
      rose-pine.enable = (nvimColorscheme == "rose-pine");
    };

    # Add extra plugins for colorschemes not available as nixvim plugins
    extraPlugins = with pkgs.vimPlugins; [
      ansible-vim
      roslyn-nvim
    ] ++ lib.optionals (nvimColorscheme == "nordfox") [ nightfox-nvim ]
      ++ lib.optionals (nvimColorscheme == "everforest") [ everforest ]
      ++ lib.optionals (nvimColorscheme == "kanagawa") [ kanagawa-nvim ]
      ++ lib.optionals (lib.hasPrefix "base16-" nvimColorscheme) [ base16-vim ];

    plugins.lualine.enable = true;
    plugins.web-devicons.enable = true;
    plugins.telescope.enable = true;
    plugins.treesitter = {
      enable = true;
      settings.indent.enable = true;
    };

    plugins.noice.enable = true;

    plugins.which-key.enable = true;

    plugins.statuscol = {
      enable = true;
    };
    keymaps = [
      {
        key = "<leader>ff";
        action = "<cmd>Telescope find_files<CR>";
        options.desc = "Telescope find files";
      }
      {
        key = "<leader>fb";
        action = "<cmd>Telescope buffers<CR>";
        options.desc = "switch between buffers";
      }
      {
        key = "<C-p>";
        action = "<cmd>Telescope git_files<CR>";
        options = {
          desc = "Telescope find git";
        };
      }
      {
        key = "<leader>e";
        action = "<cmd>Neotree toggle<CR>";
        options = {
          desc = "Neotree Open/Close";
        };
      }
      {
        key = "?";
        action = "<cmd>WhichKey<CR>";
        options = {
          desc = "which-key Open/Close";
        };
      }
    ];

    plugins.neo-tree.enable = true;

    extraPackages = with pkgs; [
      roslyn-ls
    ];

    extraConfigLua = ''
      local _border = "rounded"

      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
      vim.lsp.handlers.hover, {
          border = _border
      }
      )

      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
      vim.lsp.handlers.signature_help, {
          border = _border
      }
      )

      vim.diagnostic.config{
      float = { border = _border }
      }

      require('lspconfig.ui.windows').default_options = {
      border = _border
      }
    '';

  };
}
