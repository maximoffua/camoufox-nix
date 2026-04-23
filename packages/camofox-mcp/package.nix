{
  lib,
  buildNpmPackage,
  fetchurl,
  runCommand,
  makeWrapper,
  nodejs,
}:

let
  pname = "camofox-mcp";
  version = "1.13.1";

  srcWithLock = runCommand "${pname}-${version}-src-with-lock" { } ''
    mkdir -p $out
    tar -xzf ${
      fetchurl {
        url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
        hash = "sha256-JoohZ46aw3TpNy47YJLENpaPodI3WEx9JEJw1ZqWzag=";
      }
    } -C $out --strip-components=1
    cp ${
      fetchurl {
        url = "https://raw.githubusercontent.com/redf0x1/camofox-mcp/main/package-lock.json";
        hash = "sha256-TDf/RwxipJBz+64JwssX97Gt4RuPF5/SSHCe9vE7Wcs=";
      }
    } $out/package-lock.json
  '';
in
buildNpmPackage {
  inherit pname version;

  src = srcWithLock;

  npmDepsHash = "sha256-YdeHlxb3XZlMI4TSnmPYWKIXxQfH87J+qHJi4xG8Ku8=";

  makeCacheWritable = true;
  npmFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib/${pname}}

    npm prune --omit=dev

    cp -r dist node_modules package.json README.md LICENSE $out/lib/${pname}/

    makeWrapper ${lib.getExe nodejs} $out/bin/camofox-mcp \
      --add-flags "$out/lib/${pname}/dist/index.js"

    makeWrapper ${lib.getExe nodejs} $out/bin/camofox-mcp-http \
      --add-flags "$out/lib/${pname}/dist/http.js"

    runHook postInstall
  '';

  passthru.category = "Utilities";

  meta = {
    description = "Anti-detection browser MCP server for AI agents";
    homepage = "https://github.com/redf0x1/camofox-mcp";
    changelog = "https://github.com/redf0x1/camofox-mcp/releases/tag/v${version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    platforms = lib.platforms.all;
    mainProgram = "camofox-mcp";
  };
}
