{
  flake,
  pkgs,
  ...
}: {
  config = let
    inherit (flake) inputs;
    inherit (inputs) self;

    system = pkgs.stdenv.hostPlatform.system;

    wordlists = pkgs.wordlists.override {
      lists = with pkgs; [
        rockyou
        seclists
      ];
    };

    burp-suite = self.packages.${system}.burp-suite-pro or pkgs.burpsuite;
    ghidra = pkgs.ghidra.withExtensions (extensions:
      with extensions; [
        findcrypt
        kaiju
        machinelearning
        ret-sync
        wasm
      ]);
  in {
    home.packages = with pkgs; [
      # Host assessment
      lynis
      vulnix

      # Reverse engineering & forensics
      cutter
      detect-it-easy
      flare-floss
      ghidra
      imhex
      pe-bear
      volatility3

      # Discovery & OSINT
      amass
      maltego
      sn0int
      subfinder

      # Port scanning & fingerprinting
      rustscan
      nmap
      naabu
      fingerprintx
      httpx
      katana

      # Web enumeration & testing
      feroxbuster
      ffuf
      nikto
      nuclei
      nuclei-templates
      sqlmap
      wapiti
      wpscan

      # Proxying & traffic analysis
      burp-suite
      caido
      mitmproxy
      mitmproxy2swagger

      # Exploitation & credentials
      chisel
      exploitdb
      metasploit
      netexec
      responder
      hashcat
      john
      thc-hydra

      # Wordlists
      wordlists
    ];
  };
}
