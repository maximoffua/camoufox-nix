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
  version = "2.1.1";

  srcWithLock = runCommand "${pname}-${version}-src-with-lock" { } ''
    mkdir -p $out
    tar -xzf ${
      fetchurl {
        url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
        hash = "sha256-vcNKI0sbiNQgkymTB0qYm/KaujU7qQy3wn18otdGESk=";
      }
    } -C $out --strip-components=1
    cp ${
      fetchurl {
        url = "https://raw.githubusercontent.com/redf0x1/camofox-browser/main/package-lock.json";
        hash = "sha256-/sedDmDduHkIXMnGMlDwnd8QeUdpMd7nd+yP8tD2KqI=";
      }
    } $out/package-lock.json
  '';
in
buildNpmPackage {
  inherit pname version;

  src = srcWithLock;

  npmDepsHash = "sha256-u3jsYV9gfFRz9jn2na4OEBgUvE3w3o9FLOH1y1SwogQ=";

  makeCacheWritable = true;
  npmFlags = [ ];
  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  postPatch = ''
    substituteInPlace dist/src/services/context-pool.js \
      --replace-fail 'const opts = await (0, camoufox_js_1.launchOptions)({' 'const opts = await (0, camoufox_js_1.launchOptions)({ ...(${camoufoxEnv.executableEnvJs} ? { executable_path: ${camoufoxEnv.executableEnvJs} } : {}),'
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib/${pname}}

    npm prune --omit=dev
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
