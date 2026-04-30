{...}: {
  imports = [
    ./direnv.nix
    ./nano.nix
  ];

  config = {
    programs = {
      firefox.enable = true;
      localsend.enable = true;
      zsh.enable = true;
    };
  };
}
