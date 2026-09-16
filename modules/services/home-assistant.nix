{ config, pkgs, lib, ... }:

let
  cfg = config.myServices.homeAssistant;
in {
  options.myServices.homeAssistant = {
    enable = lib.mkEnableOption "HomeAssistant service with persistence";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8123;
      description = "Port for Home Assistant web interface";
    };
  };

  config = lib.mkIf cfg.enable {
    services.home-assistant = {
      enable = true;
      customComponents = with pkgs.home-assistant-custom-components; [
        adaptive_lighting
      ];
      extraComponents = [
        "default_config"
        "met"
        "thread"
        "esphome"
        "radio_browser"
        "google_translate"
        "tuya"
        "zha"
        "http"
        "mqtt"
        "google_health"
        "google_wifi"
        "withings"
        "google_photos"
        "google_weather"
        "google_assistant"
        "hue"
        "alexa"
        "alexa_devices"
        "matter"
        "spotify"
        "cast"
        "androidtv_remote"
        "sun"
        "switchbot"
        "switchbot_cloud"
        "jellyfin"
      ];
      config = {
        automation = "!include automations.yaml";
        default_config = {};
        http = {
          server_port = cfg.port;
          use_x_forwarded_for = true;
          trusted_proxies = [ "127.0.0.1" "::1" ];
        };
      };
    };

    services.matter-server = {
      enable = true;
      openFirewall = true;
      extraArgs = {
        "enable-test-net-dcl" = true;
        "paa-root-cert-dir" = "/var/lib/matter-server/credentials/paa-root-certs"; # taken from project-chip/connectedhomeip
      };
    };
    users.users.matter-server = {
      isSystemUser = true;
      group = "matter-server";
      home = "/var/lib/matter-server";
    };
    users.groups.matter-server = {};

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        cfg.port
        5580 # Matter Server WebSocket
        8482
      ];
      allowedUDPPorts = [
        5353 # mDNS
        5540 # matter commissioning and operational communication for Alexa
        5541 # matter commissioning and operational communication for Google
      ];
    };

    services.avahi = {
      enable = true;
      ipv4 = true;
      ipv6 = true;

      # Use nssmdns6 so the local resolver handles both IPv4 and IPv6
      nssmdns6 = true;

      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };

      # Automatically opens UDP port 5353 in both IPv4 and IPv6 firewall tables
      openFirewall = true;
    };

    environment.persistence."/nix/persist" = {
      directories = [
        {
          directory = "/var/lib/hass";
          user = "hass";
          group = "hass";
          mode = "0700";
        }

        {
          directory = "/var/lib/matter-server";
          user = "matter-server";
          group = "matter-server";
          mode = "0755";
        }

        {
          directory = "/var/lib/matter-hub";
          mode = "0700";
        }
      ];
    };
    virtualisation.oci-containers.containers.home-assistant-matter-hub = {
      image = "ghcr.io/t0bst4r/home-assistant-matter-hub:latest";
      autoStart = true;
      extraOptions = [
        "--net=host"
        ];

    # Load the secret token from your persistent storage
    environmentFiles = [
      "/nix/persist/etc/secrets/matter-hub.env"
    ];

    # Non-sensitive configuration remains in Nix
    environment = {
      HAMH_HOME_ASSISTANT_URL = "http://127.0.0.1:8123";
      HAMH_STORAGE_LOCATION = "/data";
      HAMH_WEB_PORT = "8482";
      # Setting fallback standard names as well:
      HOME_ASSISTANT_URL = "http://127.0.0.1:8123";
      STORAGE_LOCATION = "/data";
      WEB_PORT = "8482";
  };

    volumes = [
      "/nix/persist/var/lib/matter-hub:/data"
    ];
  };
    systemd.services.home-assistant = {
      after = [
        "network-online.target"
        "var-lib-hass.mount"
      ];
      requires = [
        "var-lib-hass.mount"
      ];
      wants = [
        "network-online.target"
      ];
    };
    environment.systemPackages = [ pkgs.cacert ];
    systemd.services.matter-server = {
      after = [
        "local-fs.target"
        "network-online.target"
        "var-lib-matter\\x2dserver.mount"
      ];
      bindsTo = [
        "var-lib-matter\\x2dserver.mount"
      ];
      wants = [ "network-online.target" ];

      environment = {
        SSL_CERT_FILE = pkgs.lib.mkForce "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        NIX_SSL_CERT_FILE = pkgs.lib.mkForce "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      };
      serviceConfig = {
        DynamicUser = pkgs.lib.mkForce false;
        User = "matter-server";
        Group = "matter-server";
      };
    };
    boot.kernel.sysctl = {
      "net.ipv6.conf.all.accept_ra" = 2;
      "net.ipv6.conf.default.accept_ra" = 2;
      "net.ipv6.conf.wlp3s0.accept_ra" = 2;
    };
  };
}
