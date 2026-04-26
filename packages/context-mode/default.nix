{
  stdenvNoCC,
  lib,
  fetchurl,
  makeWrapper,
  nodejs_24,
}: let
  pname = "context-mode";
  version = "1.0.94";

  mkNpmTarball = {
    url,
    hash,
  }:
    fetchurl {inherit url hash;};

  contextModeTarball = mkNpmTarball {
    url = "https://registry.npmjs.org/context-mode/-/context-mode-${version}.tgz";
    hash = "sha256-WyLPIfEmS742M2ZVzrJmRh9uTZg/5nMPztI9Tm97Jr0=";
  };

  turndownTarball = mkNpmTarball {
    url = "https://registry.npmjs.org/turndown/-/turndown-7.2.0.tgz";
    hash = "sha256-jWcuLDuXNZfZOQqVEmyoqm18imBz1X5xJEQheKJXlqY=";
  };

  turndownPluginGfmTarball = mkNpmTarball {
    url = "https://registry.npmjs.org/turndown-plugin-gfm/-/turndown-plugin-gfm-1.0.2.tgz";
    hash = "sha256-bsg2M7O2uSMF+bHweccM8hBgXveghKLIDMtEmQKZYq4=";
  };

  dominoTarball = mkNpmTarball {
    url = "https://registry.npmjs.org/@mixmark-io/domino/-/domino-2.2.0.tgz";
    hash = "sha256-uCm8yglURkn2QyAg3WkVtvsFQVTXp362+LP7H0Flr+w=";
  };
in
  stdenvNoCC.mkDerivation {
    inherit pname version;
    dontUnpack = true;

    nativeBuildInputs = [makeWrapper];

    installPhase = ''
      extractPackage() {
        local src="$1"
        local target="$2"
        local tmp

        tmp="$(mktemp -d)"
        mkdir -p "$target"
        tar -xzf "$src" -C "$tmp"
        cp -R "$tmp/package/." "$target/"
        rm -rf "$tmp"
      }

      runHook preInstall

      pkgRoot="$out/libexec/context-mode"
      mkdir -p "$pkgRoot" "$pkgRoot/node_modules/@mixmark-io" "$out/bin"

      extractPackage ${contextModeTarball} "$pkgRoot"
      extractPackage ${turndownTarball} "$pkgRoot/node_modules/turndown"
      extractPackage ${turndownPluginGfmTarball} "$pkgRoot/node_modules/turndown-plugin-gfm"
      extractPackage ${dominoTarball} "$pkgRoot/node_modules/@mixmark-io/domino"

      makeWrapper ${lib.getExe nodejs_24} "$out/bin/context-mode" \
        --add-flags "$pkgRoot/cli.bundle.mjs"

      runHook postInstall
    '';

    meta = {
      description = "Context window optimization MCP server for AI coding agents";
      homepage = "https://github.com/mksglu/context-mode";
      license = lib.licenses.elastic20;
      mainProgram = "context-mode";
      platforms = nodejs_24.meta.platforms;
    };
  }
