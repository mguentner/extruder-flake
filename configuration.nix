{ config, modulesPath, pkgs, lib, ... }:
let
  secrets = import ./secrets.nix;
in
{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
  ];

  # disable zfs
  nixpkgs.overlays = [(final: super: {
    zfs = super.zfs.overrideAttrs(_: {
      meta.platforms = [];
    });
  })];

  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  };

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
      options = [ "defaults" ];
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };

  environment = {
    systemPackages = [
      pkgs.mkpasswd # for generating password files
      pkgs.vim
      pkgs.screen
      pkgs.socat
      pkgs.usbutils
      pkgs.atop
      pkgs.git
      pkgs.tcpdump
      pkgs.tmux
      pkgs.jq
      # for serial
      pkgs.minicom
      pkgs.atinout
    ];
    variables.GC_INITIAL_HEAP_SIZE = "1M";
  };

  documentation.enable = false;
  documentation.nixos.enable = false;

  networking = {
    useDHCP = false;
    useNetworkd = true;
    hostName = "extruder";
    usePredictableInterfaceNames = false;
    wireless = {
      enable = true;
      interfaces  =  [ "wlan0" ];
      networks = lib.mkDefault secrets.wirelessNetworks;
    };
    interfaces = {
      eth0 = {
        useDHCP = true;
      };
      wlan0 = {
        ipv4.addresses = [
          { address = "192.168.178.130"; prefixLength = 24; }
        ];
      };
    };
    defaultGateway = { address = "192.168.178.1"; };
    nameservers = [ "8.8.8.8" "8.8.4.4" ];
    # we want a firewall
    firewall = {
      enable = true;
      interfaces = {
        eth0 = {
          allowedTCPPorts = [ 22 80 7125 ];
        };
        wlan0 = {
          allowedTCPPorts = [ 22 80 7125 ];
        };
      };
    };
  };

  systemd.services.systemd-networkd-wait-online.serviceConfig.ExecStart = [
    "" # don't wait for dhcp
    "${config.systemd.package}/lib/systemd/systemd-networkd-wait-online --ignore eth0"
  ];
  services.timesyncd.servers = [ "185.244.195.159" "213.172.105.106" "213.209.109.45" "80.153.195.191" ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  services.moonraker = {
    user = "root";
    enable = true;
    address = "0.0.0.0";
    settings = {
      octoprint_compat = { };
      history = { };
      authorization = {
        force_logins = true;
        cors_domains = [
          "*.local"
          "*.lan"
          "*://app.fluidd.xyz"
          "*://my.mainsail.xyz"
        ];
        trusted_clients = [
          "127.0.0.1"
          "10.0.0.0/8"
          "127.0.0.0/8"
          "169.254.0.0/16"
          "172.16.0.0/12"
          "192.168.1.0/24"
          "192.168.178.0/24"
          "FE80::/10"
          "::1/128"
        ];
      };
    };
  };

  services.fluidd.enable = true;
  services.fluidd.nginx.locations."/webcam".proxyPass = "http://127.0.0.1:8080/stream";
  # Increase max upload size for uploading .gcode files from PrusaSlicer
  services.nginx.clientMaxBodySize = "1000m";

  systemd.services.copy-klipper-config = {
    wantedBy = [ "moonraker.service" "klipper.service" ];
    before  = [ "moonraker.service" "klipper.service" ];
    description = "copy static klipper config";
    path = [ pkgs.coreutils ];
    script =  ''
       mkdir -p /var/lib/moonraker/config
       cp -an ${./klipper_config}/* /var/lib/moonraker/config/.
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  services.klipper = {
    user = "root";
    group = "root";
    enable = true;
    configFile = "/var/lib/moonraker/config/printer.cfg";
    mutableConfig = true;
    mutableConfigFolder = "/var/lib/moonraker/config";
  };

  systemd.services.ustreamer = {
    wantedBy = [ "multi-user.target" ];
    description = "uStreamer for video0";
    serviceConfig = {
      Type = "simple";
      ExecStart = ''${pkgs.ustreamer}/bin/ustreamer --encoder=HW --persistent --drop-same-frames=30 -r 1280x720'';
    };
  };


  users.users = {
    nixos = {
      initialHashedPassword = lib.mkDefault secrets.users.nixos.initialHashedPassword;
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "video" ];
      openssh.authorizedKeys.keys = lib.mkDefault secrets.users.nixos.opensshKeys;
    };
    root = {
      initialHashedPassword = lib.mkDefault secrets.users.root.initialHashedPassword;
    };
    hass = {
      isNormalUser = true;
      initialHashedPassword = lib.mkDefault secrets.users.hass.initialHashedPassword;
      openssh.authorizedKeys.keys = lib.mkDefault secrets.users.hass.opensshKeys; 
    };
  };

  security.sudo = {
    enable = true;
    extraRules = [{
      commands = [
        {
          command = "${pkgs.systemd}/bin/reboot";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.systemd}/bin/poweroff";
          options = [ "NOPASSWD" ];
        }
      ];
      users = [ "hass" ];
    }];
  };

  system.stateVersion = "23.05"; # Did you read the comment?
}
