{
  lib,
  buildNpmPackage,
  fetchurl,
  runCommand,
  makeWrapper,
  nodejs,
  camoufox ? null,
}:

let
  camoufoxEnv = import ../camoufox-env.nix { inherit lib; };
  pname = "camofox-browser";
  version = "2.4.9";

  srcWithLock = runCommand "${pname}-${version}-src-with-lock" { } ''
    mkdir -p $out
    tar -xzf ${
      fetchurl {
        url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
        hash = "sha256-DCfZGZk37rnGxllk+5ac2YFg1itR+wpScRUGehtqujE=";
      }
    } -C $out --strip-components=1
    cp ${./package-lock.json} $out/package-lock.json
  '';
in
buildNpmPackage {
  inherit pname version;

  src = srcWithLock;

  npmDepsHash = "sha256-zn2voUcnWLtdxQQO88s8NhQl2AZY0+sNn5QoVF/IzEE=";

  npmDepsFetcherVersion = 2;
  makeCacheWritable = true;
  npmFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  postPatch = ''
    substituteInPlace package.json \
      --replace-fail '"camoufox-js": "^0.11.4"' '"camoufox-js": "0.13.0"'
    substituteInPlace dist/src/services/context-pool.js \
      --replace-fail 'const opts = await (0, camoufox_js_1.launchOptions)({' 'const opts = await (0, camoufox_js_1.launchOptions)({ ...(${camoufoxEnv.executableEnvJs} ? { executable_path: ${camoufoxEnv.executableEnvJs} } : {}),'
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib/${pname}}

    npm prune --omit=dev --ignore-scripts
    ${camoufoxEnv.patchCamoufoxJs "node_modules/camoufox-js"}

    cp -r dist bin node_modules package.json README.md CHANGELOG.md LICENSE $out/lib/${pname}/

    makeWrapper ${lib.getExe nodejs} $out/bin/camofox-browser \
      --add-flags "$out/lib/${pname}/bin/camofox-browser.js" \
      ${camoufoxEnv.wrapperBrowserArgs camoufox}

    runHook postInstall
  '';

  passthru.category = "Utilities";

  meta = {
    description = "Anti-detection browser server for AI agents powered by Camoufox";
    homepage = "https://github.com/redf0x1/camofox-browser";
    changelog = "https://github.com/redf0x1/camofox-browser/releases/tag/v${version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    platforms = lib.platforms.linux;
    mainProgram = "camofox-browser";
  };
}
