{
  flake,
  pkgs,
  ...
}: {
  imports = [
    (flake.inputs.self + /modules/shared/common)
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
