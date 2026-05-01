{
  config,
  flake,
  lib,
  pkgs,
  ...
}: let
  primaryUser = lib.head config.users';
  primaryUserAccount = config.users.users.${primaryUser};

  nhExe = lib.getExe pkgs.nh;
  repoRoot = "${primaryUserAccount.home}/.config/nixos";
  flakeRef = toString flake.self;
  hostName = config.networking.hostName;

  mkNhSwitchRule = target: dryRun: {
    command = "${nhExe} os switch -H ${hostName} -R${lib.optionalString dryRun " --dry"} ${target}";
    options = ["NOPASSWD"];
  };

  nhSwitchRules =
    lib.concatMap (target: [
      (mkNhSwitchRule target false)
      (mkNhSwitchRule target true)
    ]) [
      repoRoot
      flakeRef
    ];
in {
  security.sudo.enable = lib.mkDefault false;
  security.sudo-rs = {
    enable = lib.mkDefault true;
    wheelNeedsPassword = lib.mkDefault true;
    extraRules = [
      {
        users = [primaryUser];
        commands = nhSwitchRules;
      }
    ];
  };
}
