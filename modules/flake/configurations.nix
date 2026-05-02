{
  inputs,
  lib,
  self,
  ...
}: let
  flakeArgs = import ./internal/mk-flake-args.nix {inherit inputs self;};
  homeManagerLib = inputs.home-manager.lib;
  userHomeModule = username: "${self}/users/${username}/home.nix";
  defaultHomePkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
    overlays = lib.attrValues self.overlays;
  };

  homeCommonModule = {
    config,
    pkgs,
    ...
  }: let
    homeRoot =
      if pkgs.stdenv.isDarwin
      then "/Users"
      else "/home";
  in {
    home.homeDirectory = lib.mkDefault "${homeRoot}/${config.home.username}";

    home.sessionPath = lib.mkIf pkgs.stdenv.isDarwin [
      "/etc/profiles/per-user/$USER/bin"
      "/nix/var/nix/profiles/system/sw/bin"
      "/usr/local/bin"
    ];
  };

  homeConfigurationModules = username: [
    inputs.sops-nix.homeManagerModules.sops
    homeCommonModule
    (userHomeModule username)
  ];

  mkHomeConfiguration = {
    pkgs,
    username,
  }:
    homeManagerLib.homeManagerConfiguration {
      inherit pkgs;

      extraSpecialArgs = flakeArgs;
      modules = homeConfigurationModules username;
    };
in {
  flake = {
    homeConfigurations.marco = mkHomeConfiguration {
      pkgs = defaultHomePkgs;
      username = "marco";
    };

    nixosConfigurations.armadillo = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = flakeArgs;

      modules = [
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            extraSpecialArgs = flakeArgs;
            sharedModules = [
              homeCommonModule
              inputs.sops-nix.homeManagerModules.sops
            ];
            useUserPackages = true;
          };
        }
        "${self}/hosts/armadillo"
      ];
    };
  };

  perSystem = {pkgs, ...}: {
    legacyPackages.homeConfigurations.marco = mkHomeConfiguration {
      inherit pkgs;
      username = "marco";
    };
  };
}
