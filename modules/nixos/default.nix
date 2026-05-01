{
  flake,
  pkgs,
  ...
}: {
  imports = [
    (flake.inputs.self + /modules/shared)
    ./programs
    ./services
    ./system
  ];

  config = {
    environment = {
      shells = with pkgs; [zsh];
      localBinInPath = true;
    };
  };
}
