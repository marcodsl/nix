{...}: {
  imports = [
    ./host-assessment.nix
    ./reverse-engineering.nix
    ./discovery-osint.nix
    ./scanning.nix
    ./static-analysis.nix
    ./web-testing.nix
    ./proxying.nix
    ./exploitation.nix
    ./wordlists.nix
  ];
}
