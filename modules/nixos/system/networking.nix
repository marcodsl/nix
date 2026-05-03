{
  config,
  pkgs,
  lib,
  ...
}: {
  options = {
    marco.wifi = {
      interface = lib.mkOption {
        type = lib.types.str;
        description = "Name of the Wi-Fi network interface (e.g. wlp2s0)";
      };

      staticAddress = lib.mkOption {
        type = lib.types.str;
        description = "Static IPv4 address with CIDR notation (e.g. 192.168.0.110/24)";
      };

      gateway = lib.mkOption {
        type = lib.types.str;
        description = "IPv4 address of the default gateway (e.g. 192.168.0.1)";
      };

      dns = lib.mkOption {
        type = lib.types.str;
        description = "Space-separated list of IPv4 addresses of DNS servers (e.g. '8.8.8.8 8.8.4.4')";
        default = config.marco.wifi.gateway;
      };
    };
  };

  config = {
    networking = {
      networkmanager = {
        enable = true;
        dns = "systemd-resolved";
      };

      nftables = {
        enable = true;
      };

      useDHCP = false;
      dhcpcd.enable = false;
    };

    services.resolved.enable = true;

    systemd.services.networkmanager-static-wifi = {
      description = "Apply static IPv4 settings to the Wi-Fi profile";
      wantedBy = ["multi-user.target" "network-online.target"];
      before = ["network-online.target"];
      after = ["NetworkManager.service"];
      requires = ["NetworkManager.service"];
      path = [pkgs.coreutils pkgs.networkmanager];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        wifi_profile="$(tr -d '\r\n' < ${config.sops.secrets."networkmanager/wifi_profile".path})"

        if ! nmcli connection modify "$wifi_profile" \
          connection.autoconnect yes \
          connection.interface-name "${config.marco.wifi.interface}" \
          ipv4.method manual \
          ipv4.addresses "${config.marco.wifi.staticAddress}" \
          ipv4.gateway "${config.marco.wifi.gateway}" \
          ipv4.dns "${config.marco.wifi.dns}" \
          ipv6.method auto; then
          echo "failed to configure NetworkManager Wi-Fi profile" >&2
          exit 1
        fi

        nmcli device reapply "${config.marco.wifi.interface}" || true
      '';
    };
  };
}
