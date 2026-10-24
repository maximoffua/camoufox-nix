{
  lib,
  stdenvNoCC,
  bun,
  nodejs,
  jq,
  source,
  bunDeps,
}:

stdenvNoCC.mkDerivation {
  pname = "browseros-neo-extension";
  version = "0.2.36"; # claw-app version at pinned browserclaw/v0.51.1.2 revision
  src = "${source}/packages/browseros-agent";

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
    # bun .bin entries are symlinks to regular-file shims with /usr/bin/env
    # shebangs; resolve and patch each target
    for d in node_modules/.bin apps/*/node_modules/.bin packages/*/node_modules/.bin; do
      [ -d "$d" ] || continue
      for f in "$d"/*; do
        patchShebangs "$(readlink -f "$f")" 2>/dev/null || true
      done
    done
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
