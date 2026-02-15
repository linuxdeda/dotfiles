{ config, pkgs, ... }:

let
  cfgDir = ./user-configs;  # folder sa tvojim config fajlovima
in
{
  home.username = "lxd";
  home.homeDirectory = "/home/lxd";

  # NE uključuj programs.kitty.enable jer ćeš koristiti svoj config
  # programs.kitty.enable = true;

  home.packages = with pkgs; [
    vlc
    firefox
    libreoffice-qt6-fresh
    gimp
    telegram-desktop
    hardinfo2
    alacritty
    thunderbird
    bazaar
    planify
    megasync
  ];

  programs.git = {
  enable = true;
  settings.user.name  = "linuxdeda";
  settings.user.email = "linuxdeda@gmail.com";
  };

  # Linkovanje sopstvenih konfiguracija
  home.file.".config/kitty/kitty.conf".source = "${cfgDir}/kitty.conf";

  home.stateVersion = "25.11";
}

