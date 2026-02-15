{ config, pkgs, ... }:

{
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  environment.systemPackages = with pkgs; [
    kdePackages.dolphin
    kdePackages.dolphin
    kdePackages.ktorrent
    kdePackages.partitionmanager
    kdePackages.kcalc
    kdePackages.kdenlive
  ];

  services.pulseaudio.enable = false;
}
