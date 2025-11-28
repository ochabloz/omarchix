{ pkgs, ... }:


{
  opts = {
    relativenumber = true;
    number = true;
    colorcolumn = "100";
    statuscolumn = "%s %l %r";
    expandtab = true;
    tabstop = 4;
    shiftwidth = 4;
    softtabstop = 4;
    autoindent = true;
    smartindent = true;
  };

  viAlias = true;
  vimAlias = true;

  globals.mapleader = " ";

  # Colorscheme is now set in nixvim.nix based on desktop.theme

  # Per-filetype settings
  autoGroups = {
    filetype_settings = {
      clear = true;
    };
  };

  autoCmd = [
    # Nix files: 2 spaces
    {
      event = [ "FileType" ];
      pattern = [ "nix" ];
      group = "filetype_settings";
      command = "setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab";
    }

    # Python: 4 spaces (PEP 8)
    {
      event = [ "FileType" ];
      pattern = [ "python" ];
      group = "filetype_settings";
      command = "setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab";
    }

    # JavaScript/TypeScript: 2 spaces
    {
      event = [ "FileType" ];
      pattern = [
        "javascript"
        "typescript"
        "javascriptreact"
        "typescriptreact"
      ];
      group = "filetype_settings";
      command = "setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab";
    }

    # HTML/CSS: 2 spaces
    {
      event = [ "FileType" ];
      pattern = [
        "html"
        "css"
        "scss"
        "json"
        "yaml"
      ];
      group = "filetype_settings";
      command = "setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab";
    }

    # Go: actual tabs (Go convention)
    {
      event = [ "FileType" ];
      pattern = [ "go" ];
      group = "filetype_settings";
      command = "setlocal tabstop=4 shiftwidth=4 softtabstop=4 noexpandtab";
    }

    # Makefiles: must use real tabs
    {
      event = [ "FileType" ];
      pattern = [ "make" ];
      group = "filetype_settings";
      command = "setlocal tabstop=4 shiftwidth=4 softtabstop=4 noexpandtab";
    }
  ];
}
