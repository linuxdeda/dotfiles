{ config, pkgs, lib, ... }:

let
  # Funkcija koja generiše title sa datumom
  nixosTitle = name: 
    let
      now = builtins.substring 0 10 (builtins.toString (builtins.localTime));
    in
      "${name} ${now}";
in
{
  # Uvoz modula
  imports = [
    ./modules/common.nix
    ./modules/desktop/plasma.nix
    ./hardware-configuration.nix
  ];

  # Osnovna konfiguracija
  networking.hostName = "nixos";
  time.timeZone = "Europe/Belgrade";
  
  boot.kernelPackages = pkgs.linuxPackages_latest;  

  users.users.lxd = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.fish;
  };

  # Isključi konfliktni servis
services.power-profiles-daemon.enable = false;

services.tlp = {
  enable = true;
  settings = {
    # 1. STOP TURBO BOOST (Za tvojih 4.6GHz skokova)
    CPU_BOOST_ON_AC = 0;
    CPU_BOOST_ON_BAT = 0;
    CPU_HWP_DYN_BOOST_ON_AC = 0;
    CPU_HWP_DYN_BOOST_ON_BAT = 0;

    # 2. INTEL P-STATE (Limitiranje maksimalne frekvencije)
    # i5-1334U ima osnovni takt oko 1.3GHz.
    # Sa 70% limitom, on će raditi stabilno i hladno.
    CPU_MAX_PERF_ON_AC = 81;
    CPU_MAX_PERF_ON_BAT = 60;

    # 3. ENERGY PERFORMANCE PREFERENCE (EPP)
    # Ovo je najbitnije za Intel 13. gen "U" seriju.
    # 'power' tera procesor da favorizuje 8 E-jezgara umesto 2 P-jezgra.
    CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

    # 4. TERMALNI MENADŽMENT
    # Sprečava nagle skokove temperature koji pale ventilator.
    PLATFORM_PROFILE_ON_AC = "balanced";
    PLATFORM_PROFILE_ON_BAT = "low-power";
  };
};

  programs.fish.enable = true;

  # Home Manager korisnik konfiguracija
  home-manager.users.lxd = import ./home.nix;
  
  nixpkgs.config.allowUnfree = true;

  # Paketi
  environment.systemPackages = with pkgs; [
    kitty
    fastfetch
    figlet
    kdePackages.kpmcore
    vscode
    flatpak
    thunderbird
    bazaar
    planify
    github-desktop
    tlp
  ];
  
  # Servisi
  services.openssh.enable = true;
  services.flatpak.enable = true;

  # Bootloader sa automatskim title sa datumom
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # Verzija sistema
  system.stateVersion = "25.11";
}

