# Astral: High-performance developer tools for the Python ecosystem.
{...}: {
  programs = {
    uv = {
      enable = true;
      # Python comes from devshells only - uv must not fetch or install its own.
      settings = {
        python-downloads = "never";
        python-preference = "only-system";
        link-mode = "hardlink";
        compile-bytecode = true;
        exclude-newer = "P7D";
      };
    };

    ruff = {
      enable = true;
      settings = {
        target-version = "py312";
        line-length = 88;

        lint = {
          extend-select = [
            "E"
            "F"
            "W"
            "I"
            "N"
            "UP"
            "B"
            "C4"
            "FA"
            "ISC"
            "ICN"
            "PIE"
            "PT"
            "RET"
            "SIM"
            "TID"
            "TC"
            "PTH"
            "RUF"
          ];
        };

        format = {
          line-ending = "lf";
        };
      };
    };
  };
}
