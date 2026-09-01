# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, inputs, ... }:

{
  imports = [ ];

  environment.persistence."/nix/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/etc/nixos"
      "/etc/secrets"
      "/var/cache"
      "/var/lib/bluetooth"
      "/var/lib/connman"
      "/var/lib/containers"
      "/var/lib/docker"
      "/var/lib/lxd"
    ];
    files = [
      "/etc/machine-id"
      "/etc/nix/id_rsa"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_ed25519_key"
    ];
  };

  networking.hostName = "nixos";
  
  # Enable Connman with wpa_supplicant backend for network & wireless management
  services.connman = {
    enable = true;
    wifi.backend = "wpa_supplicant";
  };
  networking.wireless.wpa_supplicant.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # XDG Portal configuration
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.config.common.default = "*";
  
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the Enlightenment Desktop Environment.
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.enlightenment.enable = true;

  # Enable acpid
  services.acpid.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  hardware.pulseaudio.support32Bit = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Container and Virtualization
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless.enable = true;
  virtualisation.lxd.enable = true;

  # Define user account.
  users.mutableUsers = false;
  users.users.root.initialPassword = "rootpass";
  users.users.tpopp = {
    createHome = true;
    home = "/home/tpopp";
    isNormalUser = true;
    extraGroups = [ "lxd" "wheel" "audio" "docker" ];
    packages = with pkgs; [
      firefox
    ];
    shell = pkgs.zsh;
    hashedPassword = "$6$f41S99x6sozYJkWi$waesjKdDS7MMnICRdTSJ376ODYk/XVhfVB2Hqz9dJqBR9dq7D.0T62/8c6.cPNfgPGO0CWquHb8goEJJ98Crb/";
  };

  # System level shell setting
  programs.zsh.enable = true;
  environment.shells = with pkgs; [ zsh ];

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # `locate` file indexer
  services.locate = {
    enable = true;
    interval = "4h";
    package = pkgs.mlocate;
    localuser = null;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    vim
    git
    dhcpcd
    home-manager
    dconf
    wpa_supplicant
  ];

  # Disable sshd auto-enable due to tailscale
  services.openssh.enable = false;
  networking.firewall.checkReversePath = "loose";

  system.stateVersion = "22.11";

  # Nix configuration
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Backup tpopp files
  services.borgbackup.jobs = {
    tpoppBackup = {
      paths = "/nix/persist/";
      repo = "/hdd/backup";
      exclude = [ "***/[.]git" ];
      doInit = true;
      compression = "auto,lzma";
      startAt = "daily";
      encryption = {
        mode = "repokey";
        passCommand = "cat /etc/secrets/borg.password";
      };
    };
  };

  # Configure sda to stop spinning after 45 seconds idle.
  powerManagement.powerUpCommands = with pkgs; '' 
    ${hdparm}/bin/hdparm -S 9 -B 63 /dev/sda
  '';

  programs.fuse.userAllowOther = true;
}
