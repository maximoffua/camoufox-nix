{
  lib,
  buildNpmPackage,
  fetchurl,
  runCommand,
  makeWrapper,
  nodejs,
  pkg-config,
  python3,
  camoufox ? null,
}:

let
  camoufoxEnv = import ../camoufox-env.nix { inherit lib; };
  pname = "camoufox-js";
  version = "0.10.2";

  srcWithLock = runCommand "${pname}-${version}-src-with-lock" { } ''
    mkdir -p $out
    tar -xzf ${
      fetchurl {
        url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
        hash = "sha256-4/ni5Ne2N6/A3gGwwb6hqxTJRwvweCH9z6hQ/lJfOYg=";
      }
    } -C $out --strip-components=1
    substituteInPlace $out/package.json \
      --replace-fail '"xml2js": "^0.6.2"' '"xml2js": "^0.6.2", "playwright-core": "^1.53.1"'
    sed -i '/"playwright-core": "\^1.53.1",/d' $out/package.json
    cp ${./package-lock.json} $out/package-lock.json
  '';
in
buildNpmPackage {
  inherit pname version;

  src = srcWithLock;

  npmDepsHash = "sha256-SMuQS1IP94ncCQTaVcRVSl+6f91/8nNN/CNLHo89tzU=";

  makeCacheWritable = true;
  npmFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;

  nativeBuildInputs = [
    makeWrapper
    pkg-config
    python3
  ];

  postPatch = camoufoxEnv.patchCamoufoxJs ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib/${pname}}

    npm prune --omit=dev
    npm rebuild better-sqlite3 --build-from-source --offline
    find node_modules/better-sqlite3/build/Release -mindepth 1 \
      ! -name better_sqlite3.node \
      -exec rm -rf {} +

    cp -r dist node_modules package.json README.md LICENSE.md $out/lib/${pname}/

    makeWrapper ${lib.getExe nodejs} $out/bin/camoufox-js \
      --add-flags "$out/lib/${pname}/dist/__main__.js" \
      ${camoufoxEnv.wrapperBrowserArgs camoufox}

    runHook postInstall
  '';

  passthru.category = "Utilities";

  meta = {
    description = "JavaScript interface and CLI for launching Camoufox with Playwright";
    homepage = "https://github.com/apify/camoufox-js";
    changelog = "https://www.npmjs.com/package/camoufox-js/v/${version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    platforms = lib.platforms.all;
    mainProgram = "camoufox-js";
  };
}
