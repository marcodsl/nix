{flake, ...}: let
  inherit (flake.inputs) self;
in {
  imports = [
    self.homeModules.default
  ];

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
