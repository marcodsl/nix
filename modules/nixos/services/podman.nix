{
  config,
  lib,
  pkgs,
  ...
}: let
  mapListToAttrs = m: f:
    lib.listToAttrs (map (name: {
        inherit name;
        value = f name;
      })
      m);
in {
  environment.systemPackages = with pkgs; [
    arion
    docker-client
  ];

  virtualisation = {
    containers.enable = true;

    podman = {
      enable = true;
      dockerCompat = true;

      defaultNetwork.settings = {
        dns_enabled = true;
      };
    };

    arion = {
      backend = "podman-socket";
      projects = {};
    };
  };

  users.users = mapListToAttrs config.users' (name: {
    extraGroups = ["podman"];
  });
}
