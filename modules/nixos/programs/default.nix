{...}: {
  imports = [
    ./direnv.nix
    ./nh.nix
    ./nano.nix
  ];

  config = {
    programs = {
      localsend.enable = true;
      zsh.enable = true;
    };
  };
}
