{
  lib,
  stdenvNoCC,
  bun,
  nodejs,
  writableTmpDirAsHomeHook,
  jq,
  source,
}:

let
  version = "0.2.36"; # claw-app version at pinned browserclaw/v0.51.1.2 revision
  src = "${source}/packages/browseros-agent";

  # bun uses the isolated linker in workspaces: dependency symlinks live in
  # per-package node_modules trees pointing into node_modules/.bun, so the
  # whole workspace tree must be captured, not just the root node_modules.
  bunDeps = stdenvNoCC.mkDerivation {
    pname = "browseros-neo-bun-deps";
    inherit version src;
    nativeBuildInputs = [
      bun
      writableTmpDirAsHomeHook
    ];
    dontConfigure = true;
    dontFixup = true;
    buildPhase = ''
      runHook preBuild
      export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
      bun install --frozen-lockfile --ignore-scripts --no-progress
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      cp -a . "$out"
      runHook postInstall
    '';
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-f3wfc0NUH9PkntR/T5A9AemECfi1/UZHuG+fwWEIAHc=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "browseros-neo-extension";
  inherit version src;
  nativeBuildInputs = [
    bun
    nodejs
    jq
  ];

  configurePhase = ''
    runHook preConfigure
    cp -a ${bunDeps}/. .
    chmod -R u+w .
    patchShebangs "$(readlink -f apps/claw-app/node_modules/.bin/wxt)"
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    cd apps/claw-app
    bun run build
    cd ../..
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/browseros-neo/extension"
    cp -R apps/claw-app/dist/chrome-mv3/. "$out/share/browseros-neo/extension/"
    # Nix updates all components as one unit. No extension OTA.
    jq 'del(.update_url)' "$out/share/browseros-neo/extension/manifest.json" > manifest.tmp
    mv manifest.tmp "$out/share/browseros-neo/extension/manifest.json"
    runHook postInstall
  '';

  meta = {
    description = "BrowserOS neo browser extension built from source";
    homepage = "https://github.com/browseros-ai/BrowserOS";
    license = lib.licenses.agpl3Plus;
    platforms = [ "x86_64-linux" ];
  };
}
