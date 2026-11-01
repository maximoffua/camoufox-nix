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
  pname = "camofox-mcp";
  version = "1.16.0";

  srcWithLock = runCommand "${pname}-${version}-src-with-lock" { } ''
    mkdir -p $out
    tar -xzf ${
      fetchurl {
        url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
        hash = "sha256-fDSriu1n3cah0NCriDX6T2A533lAOUiWPP0bBNU2CrI=";
      }
    } -C $out --strip-components=1
    cp ${./package-lock.json} $out/package-lock.json
  '';
in
buildNpmPackage {
  inherit pname version;

  src = srcWithLock;

  npmDepsHash = "sha256-3iyzC8Zi2GpBdD+PMXDpZWiF3PsLBxBMCcJpzFzNt9Y=";

  npmDepsFetcherVersion = 2;
  makeCacheWritable = true;
  npmFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib/${pname}}

    npm prune --omit=dev --ignore-scripts
    ${camoufoxEnv.patchCamoufoxJs "node_modules/camoufox-js"}

    cp -r dist node_modules package.json README.md LICENSE $out/lib/${pname}/

    makeWrapper ${lib.getExe nodejs} $out/bin/camofox-mcp \
      --add-flags "$out/lib/${pname}/dist/index.js" \
      ${camoufoxEnv.wrapperBrowserArgs camoufox}

    makeWrapper ${lib.getExe nodejs} $out/bin/camofox-mcp-http \
      --add-flags "$out/lib/${pname}/dist/http.js" \
      ${camoufoxEnv.wrapperBrowserArgs camoufox}

    runHook postInstall
  '';

  passthru.category = "Utilities";

  meta = {
    description = "Anti-detection browser MCP server for AI agents";
    homepage = "https://github.com/redf0x1/camofox-mcp";
    changelog = "https://github.com/redf0x1/camofox-mcp/releases/tag/v${version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    platforms = lib.platforms.linux;
    mainProgram = "camofox-mcp";
  };
}
