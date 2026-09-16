# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./modules/services/home-assistant.nix
    ./modules/services/zigbee.nix
  ];

  myServices.homeAssistant.enable = true;

  environment.persistence."/nix/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/etc/nixos"
      "/etc/secrets"
      "/etc/wpa_supplicant"
      "/var/cache"
      "/var/lib/bluetooth"
      "/var/lib/connman"
      "/var/lib/containers"
      "/var/lib/tailscale"
      "/var/lib/docker"
      "/var/lib/systemd"
      # PostgreSQL requires postgres ownership and strict permissions (0700 or 0750)
      {
        directory = "/var/lib/postgresql";
        user = "postgres";
        group = "postgres";
        mode = "0700";
      }

      # Immich state directory
      {
        directory = "/var/lib/immich";
        user = "immich";
        group = "immich";
        mode = "0750";
      }
      # Cloudflare Tunnel credentials and certs
      # { directory = "/var/lib/cloudflared"; user = "cloudflared"; group = "cloudflared"; mode = "0700"; }

      # Media Stack SQLite DBs & Metadata
      { directory = "/var/lib/radarr";   user = "radarr";   group = "radarr";   mode = "0700"; }
      { directory = "/var/lib/jellyfin"; user = "jellyfin"; group = "jellyfin"; mode = "0700"; }

      # # qBittorrent config owned by the dedicated user
      # {
      #   directory = "/var/lib/qbittorrent";
      #   user = "qbittorrent";
      #   group = "media";
      #   mode = "0770";
      # }

      # # Gateway VPN state
      # {
      #   directory = "/var/lib/tailscale-torrent";
      #   user = "root";
      #   group = "root";
      #   mode = "0700";
      # }
    ];
    files = [
      "/etc/machine-id"
      "/etc/nix/id_rsa"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_ed25519_key"
    ];
  };

  # Directory scaffolding for bulk storage on HDD (/data)
  # (All /var/lib paths are handled cleanly by Impermanence below)
  systemd.tmpfiles.settings."10-storage" = {
    "/data/media/movies".d = {
      mode = "0775";
      user = "radarr";
      group = "users";
    };
    "/data/media/shows".d = {
      mode = "0775";
      user = "radarr";
      group = "users";
    };
    "/data/immich".d = {
      mode = "0700"; # Retained upstream 0700 permissions
      user = "immich";
      group = "immich";
    };
    "/data/shares/general".d = {
      mode = "0777";
      user = "root";
      group = "users";
    };
    "/data/torrents/download".d = {
      mode = "0775";
      user = "qbittorrent";
      group = "media";
    };
    "/data/torrents/complete".d = {
      mode = "0775";
      user = "qbittorrent";
      group = "media";
    };
  };

  networking = {
    hostName = "deskmini-x300";
    useDHCP = false;
    interfaces.wlp3s0.useDHCP = true;

    wireless = {
      enable = true;
      userControlled = false;
      secretsFile = "/etc/wpa_supplicant/wireless.env";
      networks."EmilyInParis".pskRaw = "ext:EMILY_IN_PARIS";
    };
  };

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
  environment.enlightenment.excludePackages = [ pkgs.enlightenment.econnman ];

  # Enable acpid
  services.acpid.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
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
  virtualisation.docker.rootless.setSocketVariable = true;

  # Define user account.
  users.mutableUsers = false;
  users.users.root.initialPassword = "rootpass";
  users.users.tpopp = {
    createHome = true;
    home = "/home/tpopp";
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" ];
    packages = with pkgs; [
      firefox
    ];
    shell = pkgs.zsh;
    hashedPassword = "$6$f41S99x6sozYJkWi$waesjKdDS7MMnICRdTSJ376ODYk/XVhfVB2Hqz9dJqBR9dq7D.0T62/8c6.cPNfgPGO0CWquHb8goEJJ98Crb/";
  };
  users.users.tpopp.linger = true;

  # System level shell setting
  programs.zsh.enable = true;
  environment.shells = with pkgs; [ zsh ];

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # `locate` file indexer
  services.locate = {
    enable = true;
    interval = "daily";
    package = pkgs.plocate;
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

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    openFirewall = true;
  };

  system.stateVersion = "22.11";

  # Nix configuration
  nix = {
    package = pkgs.nix;
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

  # Spin down disk after 30 minutes of true I/O inactivity
  # Install hd-idle package and create systemd unit
  # hd-idle handles motor spindown based on OS I/O
  systemd.services.hd-idle = {
    description = "Disk spin-down daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.hd-idle}/bin/hd-idle -i 0 -a sda -i 1800";
      Restart = "always";
    };
  };

  # 2. hdparm only disables aggressive head parking (spindown disabled here via -S 0)
  powerManagement.powerUpCommands = with pkgs; ''
    ${hdparm}/bin/hdparm -S 0 -B 254 /dev/sda
  '';

  programs.fuse.userAllowOther = true;

  # System service handling the server, DB, Redis, and disk storage
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    port = 2283;
    mediaLocation = "/data/immich";
    openFirewall = true;
  };
  users.users.immich.extraGroups = [ "video" "render" ];

  services.radarr = {
    enable = true;
    openFirewall = true;         # Port 7878
    dataDir = "/var/lib/radarr"; # Points to persisted NVMe location
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;           # Port 8096
    dataDir = "/var/lib/jellyfin"; # Points to persisted NVMe location
  };
  fileSystems."/var/cache/jellyfin/transcodes" = {
  fsType = "tmpfs";
  device = "tmpfs";
  options = [
    "nosuid"
    "nodev"
    "noatime"
    "mode=0770"
    "size=4G" # 4 GB is more than double what throttled 4K requires
  ];
};
  # Shared group access for media manipulation
  users.users.jellyfin.extraGroups = [ "video" "render" "users" ];
  users.users.radarr.extraGroups = [ "users" "media" ];
  # Shared group for anything producing or consuming media
  users.groups.media = {};

  # Dedicated system user for the qBittorrent container process
  users.users.qbittorrent = {
    isSystemUser = true;
    group = "media";
    description = "qBittorrent container service user";
  };

  virtualisation.podman = {
    enable = true;
    # MUST be false: avoids symlink collisions between the podman and docker packages
    dockerCompat = false;
    # MUST be false: avoids fighting real Docker for /var/run/docker.sock
    dockerSocket.enable = false;
  };
  virtualisation.oci-containers.backend = "podman";

  services.nfs.server = {
    enable = true;
    mountdPort = 4002; # Lock mountd to a fixed port
    exports = ''
      # General read-write file share for computers on the local subnet
      /data/shares/general 192.168.0.0/16(rw,sync,no_subtree_check,no_root_squash,insecure)

      # Movies library: Read-only so network clients cannot delete media
      /data/media/movies   192.168.0.0/16(ro,sync,no_subtree_check,insecure)
      /data/media/shows   192.168.0.0/16(ro,sync,no_subtree_check,insecure)
    '';
  };

  networking.firewall.allowedTCPPorts = [ 2049 111 4002 ];
  networking.firewall.allowedUDPPorts = [ 2049 111 4002 ];

  # Host-level Tailscale
  # services.tailscale.enable = true;
  # networking.firewall.checkReversePath = "loose";
  # networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # Cloudflare Tunnel for secure remote ingress
  # services.cloudflared = {
  #   enable = true;
  #   tunnels = {
  #     "YOUR-TUNNEL-UUID" = {
  #       credentialsFile = "/var/lib/cloudflared/YOUR-TUNNEL-UUID.json";
  #       default = "http_status:404";
  #       ingress = {
  #         "photos.yourdomain.com" = "http://127.0.0.1:2283";
  #       };
  #     };
  #   };
  # };

  # Allow wheel users to reboot/poweroff over SSH without polkit errors
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id == "org.freedesktop.login1.reboot" ||
           action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
           action.id == "org.freedesktop.login1.power-off" ||
           action.id == "org.freedesktop.login1.power-off-multiple-sessions") &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # virtualisation.oci-containers.containers = {
  #   # Tailscale client container acting as the network gateway
  #   tailscale-torrent = {
  #     image = "tailscale/tailscale:latest";
  #     extraOptions = [
  #       "--cap-add=NET_ADMIN"
  #       "--device=/dev/net/tun:/dev/net/tun"
  #     ];
  #     environment = {
  #       TS_AUTHKEY = "tskey-auth-YOUR-REUSABLE-KEY";
  #       TS_STATE_DIR = "/var/lib/tailscale";
  #       TS_USERSPACE = "false";
  #       # Force all outgoing traffic through your remote non-German exit node
  #       TS_EXTRA_ARGS = "--exit-node=YOUR_REMOTE_NODE_NAME --exit-node-allow-lan-access=false";
  #     };
  #     volumes = [
  #       "/var/lib/tailscale-torrent:/var/lib/tailscale"
  #     ];
  #     ports = [
  #       "127.0.0.1:8080:8080" # Web UI local bind
  #     ];
  #   };

  #   # qBittorrent sharing the isolated VPN container's network stack
  #   qbittorrent = {
  #     image = "lscr.io/linuxserver/qbittorrent:latest";
  #     dependsOn = [ "tailscale-torrent" ];
  #     extraOptions = [
  #       "--network=container:tailscale-torrent"
  #     ];
  #     environment = {
  #       # Dynamically read the allocated host IDs from NixOS
  #       PUID = toString config.users.users.qbittorrent.uid;
  #       PGID = toString config.users.groups.media.gid;
  #       WEBUI_PORT = "8080";
  #       # Ensures new files/directories are group-writable (0775 / 0664) for Radarr
  #       UMASK = "002";
  #     };
  #     volumes = [
  #       "/var/lib/qbittorrent:/config" # Session state, fastresume, logs on NVMe
  #       "/data/torrents:/downloads"    # Incomplete & complete payload on HDD
  #     ];
  #   };
  # };
  # Keeps coredumps in memory (/run/systemd/coredump) so they disappear on reboot
  systemd.coredump.settings.Coredump = {
    Storage = "volatile";
    MaxUse = "1G";
  };
}
