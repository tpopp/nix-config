# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./machine/deskmini-x300.nix
    ];


  networking.hostName = "nixos"; # Define your hostname.
  # Enable networking
  # `connmanctl`
  services.connman.enable = true;

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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the Enlightenment Desktop Environment.
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.enlightenment.enable = true;

  # Enable acpid
  services.acpid.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tpopp.isNormalUser = true;
  users.users.tpopp.extraGroups = [ "networkmanager" "wheel" ];

  # Home Manager cannot control this system level setting, so set it here
  programs.zsh.enable = true;
  users.users.tpopp.shell = pkgs.zsh;
  environment.shells = with pkgs; [ zsh ];

# Bluetooth
# Use with `blueman-manager`
hardware.bluetooth.enable = true;
services.blueman.enable = true;

# `locate` to find files from updatedb runs
services.locate = {
  enable = true;
  interval = "4h";
  locate = pkgs.mlocate;
  localuser = null; # silence warnings that this runs as root
};

  # dynamic DNS
  services.ddclient = {
    enable = true;
    configFile = "/etc/ddclient.conf";
  };

  # Plex as a media server
  services.plex = {
    enable = true;
    openFirewall = true;
    # TODO: setup a better data dir without crashing process
    # dataDir = "/hdd/plex";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  dhcpcd
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Disable sshd enabling due to conflicting with tailscale
  services.openssh.enable = false;
  # services.openssh.ports = [ 22 ];

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
  # Strict reverse path filtering breaks Tailscale exit node use
  networking.firewall.checkReversePath = "loose";
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

  # auto-prepare upgrades, but don't reboot automatically
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;

# Unstable and flakes
nix.package = pkgs.nixUnstable;
nix.extraOptions = ''
experimental-features = nix-command flakes
'';

 # TODO: This isn't working properly
 # Backup tpopp files
 services.borgbackup.jobs = {
    tpoppBackup = {
      paths = "/home/tpopp";
      repo = "/hdd/tpopp";
      user = "tpopp";
      exclude = [ "***/[.]git" ];
      doInit = true;
      compression = "auto,lzma";
      startAt = "daily";
      encryption = {
        mode = "repokey";
        passCommand = "cat /run/keys/borgbackup_tpopp_passphrase";
      };
    };
  };


# TODO: Below command should work to find all HDDs and configure them but doesn't for some reason
#       2 different attempts are shown
# powerManagement.powerUpCommands = with pkgs;'' 
# ${hdparm}/bin/hdparm -S 9 -B 63 $(${utillinux}/bin/lsblk -dnp -o name,rota |${gnugrep}/bin/grep \'.*\\s1\'|${coreutils}/bin/cut -d \' \' -f 1)
# ${bash}/bin/bash -c '${hdparm}/bin/hdparm -S 9 -B 63 $(${utillinux}/bin/lsblk -dnp -o name,rota |${gnugrep}/bin/grep \'.*\\s1\'|${coreutils}/bin/cut -d \' \' -f 1)'
# '';

# Confgure sda (a hard drive) to stop spinning after 45 seconds idle.
powerManagement.powerUpCommands = with pkgs;'' 
  ${hdparm}/bin/hdparm -S 9 -B 63 /dev/sda
'';

# Tailscale is like a vpn service
 services.tailscale.enable = true;
   # ...
 
   # create a oneshot job to authenticate to Tailscale
   systemd.services.tailscale-autoconnect = {
     description = "Automatic connection to Tailscale";
 
     # make sure tailscale is running before trying to connect to tailscale
     after = [ "network-pre.target" "tailscale.service" ];
     wants = [ "network-pre.target" "tailscale.service" ];
     wantedBy = [ "multi-user.target" ];
 
     # set this service as a oneshot job
     serviceConfig.Type = "oneshot";
 
     # have the job run this shell script
     script = with pkgs; ''
       # wait for tailscaled to settle
       sleep 2
 
       # check if we are already authenticated to tailscale
       #status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
       if [ $status = "Running" ]; then # if so, then do nothing
         exit 0
       fi
 
       # otherwise authenticate with tailscale
       ${tailscale}/bin/tailscale up -authkey tskey-auth-kT5d8X4CNTRL-gWwEW4yyz9C4DktnemxPCCaGjtScHKDg
     '';
  };

}
