{ config, pkgs, ... }:

{
  home.username = "linuxdeda";
  home.homeDirectory = "/home/linuxdeda";

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # Dodaj ~/bin u $PATH za sesije koje Home Manager kreira
  home.sessionPath = [
    "$HOME/bin"
  ];

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    history.size = 1000;
    initExtra = ''
      PROMPT='%F{blue}%n@%m%f %F{green}%~%f %# '

      # Ako ~/bin nije u PATH, dodaj ga odmah
      if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
        export PATH="$HOME/bin:$PATH"
      fi
    '';
    shellAliases = {
      ll = "ls -lah";
      gs = "git status";
      clean = "cleanup-nixos";  # alias koji poziva skriptu u ~/bin
    };
  };

  home.packages = with pkgs; [
    neofetch
    git
    htop
    curl
  ];
}

