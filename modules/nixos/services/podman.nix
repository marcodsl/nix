{
  config,
  lib,
  pkgs,
  ...
}: let
  listToAttrsByName = names: valueForName:
    lib.listToAttrs (map (name: {
        inherit name;
        value = valueForName name;
      })
      names);
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

  users.users = listToAttrsByName config.users' (name: {
    extraGroups = ["podman"];
  });
}
