{ pkgs, ...}: {
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        address = "0.0.0.0";
        port = 1883;
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
        acl = [ "pattern readwrite #" ];
      }
    ];
  };

  services.zigbee2mqtt = {
    enable = true;
    settings = {
      serial = {
        port = "/dev/serial/by-id/usb-dresden_elektronik_ingenieurtechnik_GmbH_ConBee_II_DE2494054-if00";
        adapter = "deconz";
        
      };
      mqtt = {
        server = "mqtt://127.0.0.1:1883";
      };
      permit_join = true;
      frontend = {
        port = 8092;
        host = "0.0.0.0";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 8092 ];

  users.users.zigbee2mqtt.extraGroups = [ "dialout" ];

  environment.persistence."/nix/persist" = {
    directories = [
      {
        directory = "/var/lib/zigbee2mqtt";
        user = "zigbee2mqtt";
        group = "zigbee2mqtt";
        mode = "0700";
      }
      {
        directory = "/var/lib/mosquitto";
        user = "mosquitto";
        group = "mosquitto";
        mode = "0700";
      }
    ];
  };
}
