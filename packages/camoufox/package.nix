{
  lib,
  stdenv,
  buildMozillaMach,
  fetchFromGitHub,
  fetchurl,
  runCommand,
  camoufoxSource ? {
    owner = "daijro";
    repo = "camoufox";
    rev = "65f3454f4858a4a3ed2840a05ac7b339d5d352c5";
    hash = "sha256-tBqGRwy8dYErK0Qf54XVtowIVtKS1UhhQS4uWFuQN9k=";
    version = "0-unstable-2026-04-30";
    firefoxVersion = "146.0.1";
    displayVersion = "146.0.1-beta.25";
    homepage = "https://github.com/daijro/camoufox";
    sourceName = "daijro/camoufox";
    patchFixups = {
      "timezone-spoofing.patch" = {
        from = [
          "@@ -0,0 +1,72 @@"
          "@@ -0,0 +1,28 @@"
        ];
        to = [
          "@@ -0,0 +1,71 @@"
          "@@ -0,0 +1,27 @@"
        ];
      };
    };
  },
}:

let
  version = camoufoxSource.version;
  firefoxVersion = camoufoxSource.firefoxVersion;
  displayVersion = camoufoxSource.displayVersion;
  camoufoxRelease = lib.removePrefix "${firefoxVersion}-" displayVersion;
  rev = camoufoxSource.rev;
  homepage =
    camoufoxSource.homepage or "https://github.com/${camoufoxSource.owner}/${camoufoxSource.repo}";
  sourceName = camoufoxSource.sourceName or "${camoufoxSource.owner}/${camoufoxSource.repo}";
  excludedPatchFiles = camoufoxSource.excludedPatchFiles or [ ];
  patchFixups = camoufoxSource.patchFixups or { };

  upstreamSrc =
    camoufoxSource.src or (fetchFromGitHub {
      inherit (camoufoxSource) owner repo hash;
      inherit rev;
    });
  firefoxSrc = fetchurl {
    url = "https://archive.mozilla.org/pub/firefox/releases/${firefoxVersion}/source/firefox-${firefoxVersion}.source.tar.xz";
    hash = "sha256-6WeKDoRzkjlT4dwxLDeRkGhiO2qiCtreFiZgSSWBkes=";
  };

  patchTree = upstreamSrc + "/patches";
  settingsSource = upstreamSrc + "/settings";
  additionsSource = upstreamSrc + "/additions";

  linuxMozTarget =
    let
      cpuName = stdenv.hostPlatform.parsed.cpu.name or null;
    in
    if cpuName == "aarch64" || cpuName == "arm64" then
      "aarch64-unknown-linux-gnu"
    else if cpuName == "i686" then
      "i686-pc-linux-gnu"
    else if cpuName == "x86_64" then
      "x86_64-pc-linux-gnu"
    else
      throw "Unsupported Linux moz target CPU: ${toString cpuName}";

  listPatchFiles =
    dir:
    let
      entries = builtins.readDir dir;
      names = builtins.attrNames entries;
    in
    lib.concatMap (
      name:
      let
        entryType = entries.${name};
        path = dir + "/${name}";
      in
      if entryType == "directory" then
        listPatchFiles path
      else if entryType == "regular" && lib.hasSuffix ".patch" name then
        [ path ]
      else
        [ ]
    ) names;

  toRelativePatchPath =
    path:
    builtins.unsafeDiscardStringContext (lib.removePrefix "${toString patchTree}/" (toString path));
  fixPatchFile =
    path:
    let
      relativePath = toRelativePatchPath path;
      fixup = patchFixups.${relativePath} or null;
      safeName = builtins.replaceStrings [ "/" ] [ "-" ] relativePath;
      replacements = lib.zipListsWith (from: to: ''
        substituteInPlace "$out" \
          --replace-fail ${lib.escapeShellArg from} ${lib.escapeShellArg to}
      '') fixup.from fixup.to;
    in
    if fixup == null then
      path
    else
      runCommand safeName { } ''
        cp ${path} "$out"
        chmod u+w "$out"
        ${lib.concatStringsSep "\n" replacements}
      '';

  orderedPatchPaths =
    let
      patchRecords = map (
        path:
        let
          relativePath = toRelativePatchPath path;
        in
        {
          inherit path relativePath;
          baseName = baseNameOf relativePath;
          isRoverfox = lib.hasInfix "roverfox" relativePath;
        }
      ) (listPatchFiles patchTree);

      patchSortKey = patchRecord: "${patchRecord.baseName}	${patchRecord.relativePath}";
      sortedPatchRecords = builtins.sort (a: b: patchSortKey a < patchSortKey b) patchRecords;
    in
    map fixPatchFile (
      builtins.filter (path: !(builtins.elem (baseNameOf (toString path)) excludedPatchFiles)) (
        map (patchRecord: patchRecord.path) (
          builtins.filter (patchRecord: !patchRecord.isRoverfox) sortedPatchRecords
          ++ builtins.filter (patchRecord: patchRecord.isRoverfox) sortedPatchRecords
        )
      )
    );

  generatedMozconfig =
    builtins.replaceStrings
      [
        ''
          ac_add_options --enable-bootstrap
        ''
        "ac_add_options --enable-bootstrap"
        "ac_add_options --with-ccache=ccache"
      ]
      [ "" "" "" ]
      (builtins.readFile (upstreamSrc + "/assets/base.mozconfig"))
    + ''

      ac_add_options --target=${linuxMozTarget}
    ''
    + builtins.readFile (upstreamSrc + "/assets/linux.mozconfig");

  generatedMozconfigFile = builtins.toFile "camoufox-linux.mozconfig" generatedMozconfig;

  camoufox-unwrapped =
    (
      (buildMozillaMach {
        pname = "camoufox";
        inherit version;

        applicationName = "Camoufox";
        binaryName = "camoufox";
        src = upstreamSrc;

        requireSigning = false;
        allowAddonSideload = true;
        branding = "browser/branding/camoufox";

        unpackPhase = ''
          runHook preUnpack

          srcs="${firefoxSrc}"

          srcsArray=()
          concatTo srcsArray srcs

          dirsBefore=""
          for i in *; do
            if [ -d "$i" ]; then
              dirsBefore="$dirsBefore $i "
            fi
          done

          for i in "''${srcsArray[@]}"; do
            unpackFile "$i"
          done

          : "''${sourceRoot=}"

          if [ -n "''${setSourceRoot:-}" ]; then
            runOneHook setSourceRoot
          elif [ -z "$sourceRoot" ]; then
            for i in *; do
              if [ -d "$i" ]; then
                case $dirsBefore in
                  *\ $i\ *)
                    ;;
                  *)
                    if [ -n "$sourceRoot" ]; then
                      echo "unpacker produced multiple directories"
                      exit 1
                    fi
                    sourceRoot="$i"
                    ;;
                esac
              fi
            done
          fi

          if [ -z "$sourceRoot" ]; then
            echo "unpacker appears to have produced no directories"
            exit 1
          fi

          echo "source root is $sourceRoot"

          if [ "''${dontMakeSourcesWritable:-0}" != 1 ]; then
            chmod -R u+w -- "$sourceRoot"
          fi

          mkdir -p \
            "$sourceRoot/services/settings/dumps/main" \
            "$sourceRoot/build/vs" \
            "$sourceRoot/lw"

          cp -f "${upstreamSrc}/assets/search-config.json" "$sourceRoot/services/settings/dumps/main/search-config.json"
          cp -f "${upstreamSrc}/patches/librewolf/pack_vs.py" "$sourceRoot/build/vs/pack_vs.py"

          cp -f "${settingsSource}/camoufox.cfg" "$sourceRoot/lw/camoufox.cfg"
          cp -f "${settingsSource}/distribution/policies.json" "$sourceRoot/lw/policies.json"
          cp -f "${settingsSource}/defaults/pref/local-settings.js" "$sourceRoot/lw/local-settings.js"
          cp -f "${settingsSource}/chrome.css" "$sourceRoot/lw/chrome.css"
          cp -f "${settingsSource}/properties.json" "$sourceRoot/lw/properties.json"
          cp -f "${upstreamSrc}/scripts/mozfetch.sh" "$sourceRoot/lw/mozfetch.sh"
          : > "$sourceRoot/lw/moz.build"

          cp -R "${additionsSource}/." "$sourceRoot/"
          cp -f ${generatedMozconfigFile} "$sourceRoot/mozconfig"

          for versionFile in \
            "$sourceRoot/browser/config/version.txt" \
            "$sourceRoot/browser/config/version_display.txt"
          do
            printf '%s\n' '${displayVersion}' > "$versionFile"
          done

          chmod -R u+w -- "$sourceRoot"

          runHook postUnpack
        '';

        extraPatches = orderedPatchPaths;

        extraConfigureFlags = [
          "--disable-backgroundtasks"
          "--disable-default-browser-agent"
          "--disable-system-policies"
          "--with-unsigned-addon-scopes=app,system"
          "--target=${linuxMozTarget}"
        ];

        meta = {
          description = "Camoufox browser from ${sourceName}, built as a patched Firefox source tree";
          inherit homepage;
          license = lib.licenses.mpl20;
          sourceProvenance = with lib.sourceTypes; [ fromSource ];
          platforms = lib.platforms.linux;
          mainProgram = "camoufox";
        };
        extraPassthru = {
          inherit
            displayVersion
            firefoxVersion
            firefoxSrc
            rev
            sourceName
            upstreamSrc
            ;
        };
      }).override
      {
        enableDebugSymbols = false;
        crashreporterSupport = false;
        enableOfficialBranding = false;
        ltoSupport = false;
        pgoSupport = false;
      }
    ).overrideAttrs
      (old: {
        inherit version;
        configureFlags = builtins.filter (flag: flag != "--with-system-nss") old.configureFlags;
        passthru = old.passthru // {
          inherit version;
        };
        src = upstreamSrc;
      });
in
runCommand "camoufox-${version}"
  {
    pname = "camoufox";
    inherit version;
    passthru = camoufox-unwrapped.passthru // {
      unwrapped = camoufox-unwrapped;
    };
    meta = camoufox-unwrapped.meta;
  }
  ''
    mkdir -p "$out/bin"

    for entry in ${camoufox-unwrapped}/*; do
      name="$(basename "$entry")"
      if [ "$name" != bin ]; then
        ln -s "$entry" "$out/$name"
      fi
    done

    for entry in ${camoufox-unwrapped}/bin/* ${camoufox-unwrapped}/bin/.*; do
      name="$(basename "$entry")"
      if [ "$name" != . ] && [ "$name" != .. ]; then
        ln -s "$entry" "$out/bin/$name"
      fi
    done

    cp -f "${settingsSource}/properties.json" "$out/bin/properties.json"
    printf '{"version":"%s","release":"%s"}\n' '${firefoxVersion}' '${camoufoxRelease}' > "$out/bin/version.json"
  ''
