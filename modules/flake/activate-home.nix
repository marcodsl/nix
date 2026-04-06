{
  perSystem = {
    self',
    pkgs,
    lib,
    ...
  }: {
    apps.default = {
      inherit (self'.packages.activate) meta;

      program = pkgs.writeShellApplication {
        name = "activate-home";
        text = ''
          set -x
          ${lib.getExe self'.packages.activate} "$(id -un)"@
        '';
      };
    };
  };
}
