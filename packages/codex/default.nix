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
  version = "0.135.0";

  releaseUrl = "https://github.com/openai/codex/releases/download/rust-v${version}";
  npmUrl = "https://registry.npmjs.org/@openai/codex/-/codex-${version}.tgz";

  isNative = runtime == "native";
  isNode = runtime == "node";

  platformsBySystem = {
    "aarch64-darwin" = {
      native = "aarch64-apple-darwin";
      node = "darwin-arm64";
    };
    "x86_64-linux" = {
      native = "x86_64-unknown-linux-musl";
      node = "linux-x64";
    };
    "aarch64-linux" = {
      native = "aarch64-unknown-linux-musl";
      node = "linux-arm64";
    };
  };

  platforms = platformsBySystem.${stdenv.hostPlatform.system} or {};

  nativePlatform = platforms.native or null;
  nodePlatform = platforms.node or null;

  supportedSystems = lib.attrNames platformsBySystem;

  nativeHashes = {
    "aarch64-apple-darwin" = "0g5ksjb6kk910pazkjyjcliv6fdlsvc63dmar0a54s7bx2d55vmz";
    "x86_64-unknown-linux-musl" = "1qk3jc4rjg5sxk19qx8rr7l50vgfdxajkppf43hs193xcnnpspm1";
    "aarch64-unknown-linux-musl" = "0vgpl978jyjlc54mqsk4jhi6b1b0c2l6k4slypymzwiyb4fwx2sn";
  };

  nodeOptionalDepHashes = {
    "darwin-arm64" = "1n8vccv1w5cwvl0hbrr2iwf31sm5wrig34wy2lwgvgd1q7wa65d7";
    "linux-x64" = "1gybmb5l5849qf47l50g1v36i6wlj5khk4d3pf852jfk9sjh2nq1";
    "linux-arm64" = "0wfsfn6gxw49qq8px8dc95i71kvix6kkcd4rx4f98jiyv9247vik";
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
        sha256 = "19zvp386cv2crydkr6rg8gd0n6irpqrs5jmzgab5qr5d13migbaq";
      }
    else null;

  nodeOptionalDep =
    if isNode && nodePlatform != null
    then fetchReleaseTarball "codex-npm-${nodePlatform}-${version}.tgz" nodeOptionalDepHashes.${nodePlatform}
    else null;

  runtimes = {
    native = {
      nativeBuildInputs = [gnutar gzip makeWrapper] ++ lib.optionals needsPatchelf [patchelf];
      buildInputs = lib.optionals needsPatchelf [openssl libcap libz];
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
  needsPatchelf = isNative && nativePlatform != null && stdenv.isLinux && lib.hasSuffix "-unknown-linux-gnu" nativePlatform;
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

    ${lib.optionalString needsPatchelf ''
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

      dontPatchELF = isNative && !needsPatchelf;
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
