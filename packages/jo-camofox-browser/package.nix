{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  nodejs,
  pkg-config,
  python3,
  xorg-server,
  camoufox ? null,
}:

let
  camoufoxEnv = import ../camoufox-env.nix { inherit lib; };
in
buildNpmPackage rec {
  pname = "jo-camofox-browser";
  version = "1.9.1";

  src = fetchFromGitHub {
    owner = "maximoffua";
    repo = "camofox-browser";
    rev = "13faabc9bc15bd5e0f6ebc265b2ac3cd9cef0e06";
    hash = "sha256-pV+fqq0H2DRMBOcDNKdUOpxIhZzhHg1Db4WH9lbBCV4=";
  };

  npmDepsHash = "sha256-Ps5gZnX9AInbGSgkas+bsvx5f//LkHWpy96XZ/JvUm4=";

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
      --replace-fail '      const options = await launchOptions({' '      const options = await launchOptions({ ...(${camoufoxEnv.executableEnvJs} ? { executable_path: ${camoufoxEnv.executableEnvJs} } : {}),'
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib/${pname}}

    npm prune --omit=dev
    ${camoufoxEnv.patchCamoufoxJs "node_modules/camoufox-js"}
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
      ${camoufoxEnv.wrapperBrowserArgs camoufox} \
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
