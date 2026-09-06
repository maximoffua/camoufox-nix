{
  lib,
  stdenv,
  buildMozillaMach,
  buildPackages,
  fetchFromGitHub,
  fetchurl,
  runCommand,
  unstableGitUpdater,
  camoufoxSource ? {
    owner = "daijro";
    repo = "camoufox";
    rev = "0583c3ec94f5a9df5cb2d09553fbfe80589b6e2d";
    hash = "sha256-Fe/1t1ihDoZML87muiIZ9hQZyal7PUW8pUymoZnuMTo=";
    version = "152.0.4";
    firefoxVersion = "152.0.4";
    firefoxHash = "sha256-/YmYIgLNpTU6JzB9hdSJAtRldtRtHJ421VdA5jtSFrs=";
    displayVersion = "152.0.4";
    homepage = "https://github.com/daijro/camoufox";
    sourceName = "daijro/camoufox";
  },
}:

let
  version = camoufoxSource.version;
  firefoxVersion = camoufoxSource.firefoxVersion;
  firefoxHash = camoufoxSource.firefoxHash;
  displayVersion = camoufoxSource.displayVersion;
  camoufoxRelease = lib.removePrefix "${firefoxVersion}-" displayVersion;
  rev = camoufoxSource.rev;
  homepage =
    camoufoxSource.homepage or "https://github.com/${camoufoxSource.owner}/${camoufoxSource.repo}";
  sourceName = camoufoxSource.sourceName or "${camoufoxSource.owner}/${camoufoxSource.repo}";
  excludedPatchFiles = camoufoxSource.excludedPatchFiles or [ ];
  patchFixups = camoufoxSource.patchFixups or { };
  settingsConfig = camoufoxSource.settingsConfig or "camoufox.cfg";
  binaryName = camoufoxSource.binaryName or "camoufox";

  upstreamSrc =
    camoufoxSource.src or (fetchFromGitHub {
      inherit (camoufoxSource) owner repo hash;
      inherit rev;
    });
  firefoxSrc = fetchurl {
    url = "https://archive.mozilla.org/pub/firefox/releases/${firefoxVersion}/source/firefox-${firefoxVersion}.source.tar.xz";
    hash = firefoxHash;
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
        ''
          # Use ccache for faster incremental rebuilds if available
          if command -v ccache >/dev/null 2>&1; then
            ac_add_options --with-ccache=ccache
          fi
        ''
        "ac_add_options --with-ccache=ccache"
      ]
      [
        ""
        ""
        ""
        ""
      ]
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
        inherit binaryName;
        src = upstreamSrc;

        # nixpkgs removed requireSigning/allowAddonSideload from the
        # buildMozillaMach head; the knobs moved into the mach package's
        # own args (set in the .override below).
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

          cp -f "${settingsSource}/${settingsConfig}" "$sourceRoot/lw/${settingsConfig}"
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

        # Bug 2046162 (drop redundant `pub` BudgetType qualifiers) landed in
        # Firefox 152; only needed to backport for older source trees.
        extraPatches =
          (lib.optional (lib.versionOlder firefoxVersion "152") ./153-cbindgen-0.29.4-compat.patch)
          ++ orderedPatchPaths;

        extraConfigureFlags = [
          "READELF=${lib.getExe' buildPackages.binutils-unwrapped "readelf"}"
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
          mainProgram = binaryName;
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
        # nixpkgs buildMozillaMach API rename (nixpkgs >= 801bef6-era):
        # crashreporterSupport -> enableCrashReporter, ltoSupport ->
        # enableLTO, pgoSupport -> enablePGO; addon knobs added here after
        # being removed from the head args.
        enableDebugSymbols = false;
        enableCrashReporter = false;
        enableOfficialBranding = false;
        enableLTO = false;
        enablePGO = false;
        # was: requireSigning = false (head arg) — camoufox sideloads its own
        # patches/settings, unsigned addons must load.
        enableAddonSigning = false;
        # was: allowAddonSideload = true (head arg).
        enableAddonSideload = true;
      }
    ).overrideAttrs
      (old: {
        inherit version;
        configureFlags = builtins.filter (flag: flag != "--with-system-nss") old.configureFlags;
        passthru = old.passthru // {
          inherit version;
          updateScript = unstableGitUpdater {
            url = "https://github.com/${sourceName}.git";
          };
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
      updateScript = unstableGitUpdater {
        url = "https://github.com/${sourceName}.git";
      };
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
