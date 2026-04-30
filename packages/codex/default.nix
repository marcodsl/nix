{
  lib,
  stdenv,
  fetchurl,
  nodejs_22,
  cacert,
  makeWrapper,
  patchelf,
  gnutar,
  gzip,
  openssl,
  libcap,
  libz,
  bubblewrap,
  runtime ? "native",
  nativeBinName ? "codex",
  nodeBinName ? "codex-node",
}: let
  version = "0.125.0";

  releaseUrl = "https://github.com/openai/codex/releases/download/rust-v${version}";
  npmUrl = "https://registry.npmjs.org/@openai/codex/-/codex-${version}.tgz";

  isNative = runtime == "native";
  isNode = runtime == "node";

  platformsBySystem = {
    "aarch64-darwin" = {
      native = "aarch64-apple-darwin";
      node = "darwin-arm64";
    };
    "x86_64-darwin" = {
      native = "x86_64-apple-darwin";
      node = "darwin-x64";
    };
    "x86_64-linux" = {
      native = "x86_64-unknown-linux-gnu";
      node = "linux-x64";
    };
    "aarch64-linux" = {
      native = "aarch64-unknown-linux-gnu";
      node = "linux-arm64";
    };
  };

  platforms = platformsBySystem.${stdenv.hostPlatform.system} or {};

  nativePlatform = platforms.native or null;
  nodePlatform = platforms.node or null;

  supportedSystems = lib.attrNames platformsBySystem;

  nativeHashes = {
    "aarch64-apple-darwin" = "17vlrcwg8s1jqp7wjzcyf14i7jskgj8a3v9bnr4x6fcnrg06v4ka";
    "x86_64-apple-darwin" = "12f0nlgm0xdn8s42cylr2inqwdqdzxdsgglnaqilr08m9mc1jq5l";
    "x86_64-unknown-linux-gnu" = "1gnl9kskdq1ggmqwgkqvdim12fz8sjmphj7wy6lg6cdbp2ww0asj";
    "aarch64-unknown-linux-gnu" = "1rjnc6hbcshm864rkcw0k51afi4kvh56b4473dpnay3mzlkna1rd";
  };

  nodeOptionalDepHashes = {
    "darwin-arm64" = "1082035aark2zp93s1n9g4f6ibn9dgwc541f9i5ffk0hdcrs6a77";
    "darwin-x64" = "1hbhgz711ici4papy1sv6y6f79djyy0jvw4nbsqflqgs53rpa0ih";
    "linux-x64" = "1zs370wp6jdm2smlwy0ljd270yrhh893mrw9izr5hh4wf4rlf7r1";
    "linux-arm64" = "0yxicdlcd3y3i1jnif3z4vclnh2v0gkpwzwm1clhax1samn9cp7g";
  };

  fetchReleaseTarball = fileName: sha256:
    fetchurl {
      url = "${releaseUrl}/${fileName}";
      inherit sha256;
    };

  nativeBinary =
    if isNative && nativePlatform != null
    then fetchReleaseTarball "codex-${nativePlatform}.tar.gz" nativeHashes.${nativePlatform}
    else null;

  npmTarball =
    if isNode
    then
      fetchurl {
        url = npmUrl;
        sha256 = "16q1aifcrnaxlqi50pagh70apkxxria85xrmq8lbfcsm9mznjvvx";
      }
    else null;

  nodeOptionalDep =
    if isNode && nodePlatform != null
    then fetchReleaseTarball "codex-npm-${nodePlatform}-${version}.tgz" nodeOptionalDepHashes.${nodePlatform}
    else null;

  runtimes = {
    native = {
      nativeBuildInputs = [gnutar gzip makeWrapper] ++ lib.optionals stdenv.isLinux [patchelf];
      buildInputs = lib.optionals stdenv.isLinux [openssl libcap libz];
      description = "OpenAI Codex CLI (Native Binary) - AI coding assistant in your terminal";
      binName = nativeBinName;
    };
    node = {
      nativeBuildInputs = [nodejs_22 cacert makeWrapper];
      buildInputs = [];
      description = "OpenAI Codex CLI (Node.js) - AI coding assistant in your terminal";
      binName = nodeBinName;
    };
  };

  runtimeConfig = runtimes.${runtime};
  linuxRuntimePath = lib.makeBinPath (lib.optionals stdenv.isLinux [bubblewrap]);
  nodeModulesDir = "$out/lib/node_modules/@openai";
  codexDir = "${nodeModulesDir}/codex";
  rawBin = "$out/bin/codex-raw";

  nativeBuildPhase = ''
    runHook preBuild
    mkdir -p build
    tar -xzf ${nativeBinary} -C build
    mv build/codex-${nativePlatform} build/codex
    chmod u+w,+x build/codex

    ${lib.optionalString stdenv.isLinux ''
      patchelf \
        --set-interpreter "$(cat ${stdenv.cc}/nix-support/dynamic-linker)" \
        --set-rpath "${lib.makeLibraryPath [openssl libcap libz]}" \
        build/codex
    ''}

    runHook postBuild
  '';

  nodeBuildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR
    mkdir -p $HOME/.npm

    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
    export NODE_EXTRA_CA_CERTS=$SSL_CERT_FILE

    mkdir -p ${nodeModulesDir}
    tar -xzf ${npmTarball} -C ${nodeModulesDir}
    mv ${nodeModulesDir}/package ${codexDir}

    ${lib.optionalString (nodeOptionalDep != null) ''
      tar -xzf ${nodeOptionalDep} -C ${nodeModulesDir}
      mv ${nodeModulesDir}/package ${nodeModulesDir}/codex-${nodePlatform}
    ''}

    runHook postBuild
  '';

  nativeInstallPhase = ''
    runHook preInstall
    mkdir -p $out/bin

    cp build/codex ${rawBin}
    chmod +x ${rawBin}
    makeWrapper "${rawBin}" "$out/bin/${runtimeConfig.binName}" \
      --run 'export CODEX_EXECUTABLE_PATH="$HOME/.local/bin/${runtimeConfig.binName}"' \
      --set DISABLE_AUTOUPDATER 1 \
      ${lib.optionalString stdenv.isLinux ''--prefix PATH : "${linuxRuntimePath}"''}
    runHook postInstall
  '';

  nodeInstallPhase = ''
    runHook preInstall
    mkdir -p $out/bin

    makeWrapper ${nodejs_22}/bin/node "$out/bin/${runtimeConfig.binName}" \
      --add-flags --no-warnings \
      --add-flags "${codexDir}/bin/codex.js" \
      --set NODE_PATH "$out/lib/node_modules" \
      --run 'export CODEX_EXECUTABLE_PATH="$HOME/.local/bin/${runtimeConfig.binName}"' \
      --set DISABLE_AUTOUPDATER 1 \
      ${lib.optionalString stdenv.isLinux ''--prefix PATH : "${linuxRuntimePath}"''}
    runHook postInstall
  '';
in
  assert isNative
  -> nativePlatform
  != null
  || throw "Native runtime not supported on ${stdenv.hostPlatform.system}. Supported: ${lib.concatStringsSep ", " supportedSystems}";
    stdenv.mkDerivation {
      pname =
        if isNative
        then "codex"
        else "codex-${runtime}";
      inherit version;

      dontUnpack = true;

      dontPatchELF = isNative;
      dontStrip = isNative;

      nativeBuildInputs = runtimeConfig.nativeBuildInputs;
      buildInputs = runtimeConfig.buildInputs;

      buildPhase =
        if isNative
        then nativeBuildPhase
        else nodeBuildPhase;

      installPhase =
        if isNative
        then nativeInstallPhase
        else nodeInstallPhase;

      meta = with lib; {
        description = runtimeConfig.description;
        homepage = "https://github.com/openai/codex";
        license = licenses.asl20;
        platforms =
          if isNative
          then supportedSystems
          else platforms.all;
        mainProgram = runtimeConfig.binName;
      };
    }
