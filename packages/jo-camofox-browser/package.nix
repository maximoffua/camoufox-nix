{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  nodejs,
  pkg-config,
  python3,
  xorg-server,
}:

buildNpmPackage rec {
  pname = "jo-camofox-browser";
  version = "1.8.15";

  src = fetchFromGitHub {
    owner = "jo-inc";
    repo = "camofox-browser";
    rev = "2a0be78c732c6b7efacaec0193a88ca22c4925b4";
    hash = "sha256-FMPwkLwFhMVF04NasmBb/RJe6Z0Ta1fqZm4piaHQOdE=";
  };

  npmDepsHash = "sha256-vtxkCVXOKr335LummXm4aznt642qbDVpGh+pu23pLaI=";

  makeCacheWritable = true;
  npmFlags = [
    "--ignore-scripts"
  ];
  dontBuild = true;
  dontNpmBuild = true;

  nativeBuildInputs = [
    makeWrapper
    pkg-config
    python3
  ];

  postPatch = ''
    substituteInPlace server.js \
      --replace-fail '      const options = await launchOptions({' '      const options = await launchOptions({ ...(process.env.CAMOFOX_EXECUTABLE_PATH ? { executable_path: process.env.CAMOFOX_EXECUTABLE_PATH } : {}),'
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib/${pname}}

    npm prune --omit=dev
    npm rebuild better-sqlite3 --build-from-source --offline
    find node_modules/better-sqlite3/build/Release -mindepth 1 \
      ! -name better_sqlite3.node \
      -exec rm -rf {} +

    cp -r \
      AGENTS.md \
      LICENSE \
      README.md \
      camofox.config.json \
      lib \
      node_modules \
      openapi.json \
      openclaw.plugin.json \
      package.json \
      plugins \
      scripts \
      server.js \
      $out/lib/${pname}/

    makeWrapper ${lib.getExe nodejs} $out/bin/jo-camofox-browser \
      --add-flags "$out/lib/${pname}/server.js" \
      --chdir "$out/lib/${pname}" \
      --run 'export CAMOFOX_EXECUTABLE_PATH="''${CAMOFOX_EXECUTABLE_PATH:-''${CAMOUFOX_EXECUTABLE_PATH:-}}"' \
      --prefix PATH : ${lib.makeBinPath [ xorg-server ]}

    makeWrapper $out/bin/jo-camofox-browser $out/lib/${pname}/run.sh

    runHook postInstall
  '';

  passthru.category = "Utilities";

  meta = {
    description = "Anti-detection browser server for AI agents from jo-inc";
    homepage = "https://github.com/jo-inc/camofox-browser";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    platforms = lib.platforms.all;
    mainProgram = "jo-camofox-browser";
  };
}
