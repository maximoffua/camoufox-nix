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
  version = "0.13.0";

  srcWithLock = runCommand "${pname}-${version}-src-with-lock" { } ''
    mkdir -p $out
    tar -xzf ${
      fetchurl {
        url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
        hash = "sha256-AVP9rOlCNusfTL6gziKYNXXMWs+HIeV+Sdp+kwn2ssc=";
      }
    } -C $out --strip-components=1
    substituteInPlace $out/package.json \
      --replace-fail '"xml2js": "^0.6.2"' '"xml2js": "^0.6.2", "playwright-core": "<1.63.0"'
    cp ${./package-lock.json} $out/package-lock.json
  '';
in
buildNpmPackage {
  inherit pname version;

  src = srcWithLock;

  npmDepsHash = "sha256-o9stGO6QOOzLL53SehG5sLu/BchlPzFSdgj1igca8oE=";

  makeCacheWritable = true;
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

    # better-sqlite3 13 ships ABI-stable N-API prebuilds (prebuilds/linux-*.node),
    # so no native compilation is needed.

    cp -r dist node_modules package.json README.md LICENSE.md $out/lib/${pname}/

    makeWrapper ${lib.getExe nodejs} $out/bin/camoufox-js \
      --add-flags "$out/lib/${pname}/dist/__main__.js" \
      ${camoufoxEnv.wrapperBrowserArgs camoufox}

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    ${lib.getExe nodejs} --input-type=module <<'JS'
    import assert from 'node:assert/strict';
    import fs from 'node:fs';
    import os from 'node:os';
    import path from 'node:path';
    import { camoufoxPath, ensureCamoufoxInstalled, installedVerStr, launchPath } from './dist/pkgman.js';
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'camoufox-env-'));
    const executable = path.join(dir, 'camoufox');
    fs.writeFileSync(executable, "");
    fs.writeFileSync(path.join(dir, 'version.json'), JSON.stringify({version: '158.0.1', release: 'beta.41'}));
    try {
      for (const key of ['CAMOUFOX_EXECUTABLE', 'CAMOUFOX_EXECUTABLE_PATH', 'CAMOFOX_EXECUTABLE', 'CAMOFOX_EXECUTABLE_PATH']) {
        for (const name of ['CAMOUFOX_EXECUTABLE', 'CAMOUFOX_EXECUTABLE_PATH', 'CAMOFOX_EXECUTABLE', 'CAMOFOX_EXECUTABLE_PATH']) delete process.env[name];
        process.env[key] = executable;
        assert.equal(launchPath(), executable);
        assert.equal(camoufoxPath(), dir);
        assert.ok(installedVerStr().includes('158.0.1'));
        await ensureCamoufoxInstalled();
      }
    } finally {
      fs.rmSync(dir, {recursive: true});
    }
    JS
    runHook postInstallCheck
  '';

  passthru.category = "Utilities";

  meta = {
    description = "JavaScript interface and CLI for launching Camoufox with Playwright";
    homepage = "https://github.com/apify/camoufox-js";
    changelog = "https://www.npmjs.com/package/camoufox-js/v/${version}";
    license = lib.licenses.mpl20;
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    platforms = lib.platforms.linux;
    mainProgram = "camoufox-js";
  };
}
