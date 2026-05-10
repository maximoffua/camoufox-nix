{
  lib,
  buildNpmPackage,
  fetchurl,
  runCommand,
  makeWrapper,
  nodejs,
  python3,
  camoufox ? null,
}:

let
  camoufoxEnv = import ../camoufox-env.nix { inherit lib; };
  pname = "camofox-cli";
  npmName = "camoufox-cli";
  version = "0.2.0";

  srcWithLock = runCommand "${pname}-${version}-src-with-lock" { } ''
    mkdir -p $out
    tar -xzf ${
      fetchurl {
        url = "https://registry.npmjs.org/${npmName}/-/${npmName}-${version}.tgz";
        hash = "sha256-53nqE1Jnl1kSQvlOHhlHqe7WTdBeobRfuiupHZPpcZQ=";
      }
    } -C $out --strip-components=1
    cp ${./package-lock.json} $out/package-lock.json
  '';
in
buildNpmPackage {
  inherit pname version;

  src = srcWithLock;

  npmDepsHash = "sha256-nlBqeUgB4Vomu0LckIzIJxg0tSmOQ+g2SgiVBzmznc4=";

  makeCacheWritable = true;
  npm_config_build_from_source = "true";
  dontNpmBuild = true;

  nativeBuildInputs = [
    makeWrapper
    python3
  ];

  postPatch = ''
    substituteInPlace package.json \
      --replace-fail '"playwright-core": "^1.52.0"' '"playwright-core": "1.53.1"'
    substituteInPlace dist/cli.js \
      --replace-fail 'spawn("node", [daemonPath, ...args], {' 'spawn(process.execPath, [daemonPath, ...args], {'
    substituteInPlace dist/browser.js \
      --replace-fail '        execFileSync("npx", ["camoufox-js", "path"], { stdio: "pipe" });' '        const executablePath = ${camoufoxEnv.executableEnvJs};
        if (executablePath)
            return;
        execFileSync("npx", ["camoufox-js", "path"], { stdio: "pipe" });'
    substituteInPlace dist/browser.js \
      --replace-fail '        const launchOpts = { headless };' '        const launchOpts = { headless };
        const executablePath = ${camoufoxEnv.executableEnvJs};
        if (executablePath)
            launchOpts.executable_path = executablePath;'
    substituteInPlace dist/cli.js \
      --replace-fail '        execFileSync("npx", ["camoufox-js", "fetch"], { stdio: "inherit" });' '        if (${camoufoxEnv.executableEnvJs}) {
            console.error("[camoufox-cli] Browser managed by Nix wrapper.");
            return;
        }
        execFileSync("npx", ["camoufox-js", "fetch"], { stdio: "inherit" });'
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib/${pname}}

    npm prune --omit=dev
    ${camoufoxEnv.patchCamoufoxJs "node_modules/camoufox-js"}

    cp -r dist node_modules package.json LICENSE $out/lib/${pname}/

    makeWrapper ${lib.getExe nodejs} $out/bin/${pname} \
      --add-flags "$out/lib/${pname}/dist/cli.js" \
      ${camoufoxEnv.wrapperBrowserArgs camoufox}

    runHook postInstall
  '';

  passthru = {
    category = "Utilities";
    inherit npmName;
  };

  meta = {
    description = "Anti-detect browser automation CLI for AI agents powered by Camoufox";
    homepage = "https://github.com/Bin-Huang/camoufox-cli";
    changelog = "https://github.com/Bin-Huang/camoufox-cli/releases";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    platforms = lib.platforms.all;
    mainProgram = pname;
  };
}
