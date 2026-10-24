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
  pname = "browseros-neo-onboarding";
  version = "0.0.16"; # claw-onboard version at pinned browserclaw/v0.51.1.2 revision
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
    cd apps/claw-onboard
    bun run build:chromium
    cd ../..
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/browseros-neo/onboarding"
    cp -R apps/claw-onboard/dist/chromium/. "$out/share/browseros-neo/onboarding/"
    runHook postInstall
  '';

  meta = {
    description = "BrowserOS neo onboarding WebUI resources built from source";
    homepage = "https://github.com/browseros-ai/BrowserOS";
    license = lib.licenses.agpl3Plus;
    platforms = [ "x86_64-linux" ];
  };
}
