{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
  makeBinaryWrapper,
  autoPatchelfHook,
  procps,
  ripgrep,
  bubblewrap,
  socat,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}: let
  stdenv = stdenvNoCC;

  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";

  manifest = builtins.fromJSON (builtins.readFile ./manifest.json);

  platformKey = "${stdenv.hostPlatform.node.platform}-${stdenv.hostPlatform.node.arch}";

  entry =
    manifest.platforms.${platformKey}
    or (throw "claude-code: no manifest entry for ${platformKey}; available: ${lib.concatStringsSep ", " (lib.attrNames manifest.platforms)}");
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "claude-code";
    inherit (manifest) version;

    src = fetchurl {
      url = "${baseUrl}/${finalAttrs.version}/${platformKey}/claude";
      sha256 = entry.checksum;
    };

    dontUnpack = true;
    dontBuild = true;
    dontStrip = true;
    __noChroot = stdenv.hostPlatform.isDarwin;

    nativeBuildInputs =
      [
        installShellFiles
        makeBinaryWrapper
      ]
      ++ lib.optionals stdenv.hostPlatform.isElf [autoPatchelfHook];

    strictDeps = true;

    installPhase = ''
      runHook preInstall

      installBin $src

      wrapProgram $out/bin/claude \
        --set DISABLE_AUTOUPDATER 1 \
        --set-default FORCE_AUTOUPDATE_PLUGINS 1 \
        --set DISABLE_INSTALLATION_CHECKS 1 \
        --set USE_BUILTIN_RIPGREP 0 \
        --prefix PATH : ${
        lib.makeBinPath (
          [
            procps
            ripgrep
          ]
          ++ lib.optionals stdenv.hostPlatform.isLinux [
            bubblewrap
            socat
          ]
        )
      }

      runHook postInstall
    '';

    doInstallCheck = true;
    nativeInstallCheckInputs = [
      writableTmpDirAsHomeHook
      versionCheckHook
    ];
    versionCheckKeepEnvironment = ["HOME"];
    versionCheckProgramArg = "--version";

    passthru.updateScript = ./update.py;

    meta = {
      description = "Agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster";
      homepage = "https://github.com/anthropics/claude-code";
      downloadPage = "https://claude.com/product/claude-code";
      changelog = "https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md";
      license = lib.licenses.unfree;
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      platforms = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      mainProgram = "claude";
    };
  })
