{flake, ...}: let
  inherit (flake.inputs) self;
in {
  imports = [
    self.homeModules.default
  ];

  sops = {
    age.keyFile = "/home/marco/.config/sops/age/keys.txt";
    defaultSopsFile = "${self}/secrets/hosts/armadillo.yaml";
    secrets = {
      "mcp/github-token" = {};
      "mcp/linear-token" = {};
    };
  };

  me = {
    username = "marco";
    fullname = "Marco";
    email = "mrcdsl@proton.me";

    github.username = "marcodsl";

    terminal.font = {
      family = "GeistMono Nerd Font";
      size = 11;
    };
  };

  home.stateVersion = "24.11";
}
