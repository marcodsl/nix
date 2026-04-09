{pkgs, ...}: {
  config = {
    environment.systemPackages = with pkgs; [
      traceroute
    ];

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
  };
}
