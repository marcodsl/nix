{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  installShellFiles,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}: let
  stdenv = stdenvNoCC;

  baseUrl = "https://releases.gitpod.io/cli/releases";

  manifest = builtins.fromJSON (builtins.readFile ./manifest.json);

  platformKey =
    {
      "x86_64-linux" = "linux-amd64";
      "aarch64-linux" = "linux-arm64";
      "x86_64-darwin" = "darwin-amd64";
      "aarch64-darwin" = "darwin-arm64";
    }
    .${
      stdenv.hostPlatform.system
    }
    or (throw "ona: unsupported system ${stdenv.hostPlatform.system}");

  entry =
    manifest.platforms.${platformKey}
    or (throw "ona: no manifest entry for ${platformKey}; available: ${lib.concatStringsSep ", " (lib.attrNames manifest.platforms)}");
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "ona";
    inherit (manifest) version;

    src = fetchurl {
      url = "${baseUrl}/${finalAttrs.version}/gitpod-${platformKey}";
      sha256 = entry.checksum;
    };

    dontUnpack = true;
    dontBuild = true;
    dontStrip = true;

    nativeBuildInputs =
      [installShellFiles]
      ++ lib.optionals stdenv.hostPlatform.isElf [autoPatchelfHook];

    strictDeps = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 $src $out/bin/ona
      runHook postInstall
    '';

    postInstall = ''
      installShellCompletion --cmd ona \
        --bash <($out/bin/ona completion bash) \
        --zsh <($out/bin/ona completion zsh) \
        --fish <($out/bin/ona completion fish)
    '';

    doInstallCheck = true;
    nativeInstallCheckInputs = [
      writableTmpDirAsHomeHook
      versionCheckHook
    ];
    versionCheckKeepEnvironment = ["HOME"];
    versionCheckProgramArg = "version";

    passthru.updateScript = ./update.py;

    meta = {
      description = "Ona CLI (formerly Gitpod) for driving background coding agents";
      homepage = "https://ona.com";
      downloadPage = "https://ona.com/docs/ona/integrations/cli";
      license = lib.licenses.unfree;
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      platforms = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      mainProgram = "ona";
    };
  })
