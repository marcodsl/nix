{inputs, ...}: {
  imports = [
    inputs.nixos-unified.flakeModules.default
    inputs.nixos-unified.flakeModules.autoWire
  ];

  perSystem = {
    self',
    pkgs,
    system,
    ...
  }: {
    formatter = pkgs.alejandra;

    packages.default = self'.packages.activate;

    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;

      config = {
        allowUnfree = true;
      };
    };
  };
}
