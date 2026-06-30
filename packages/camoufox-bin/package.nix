{
  lib,
  stdenv,
  fetchzip,
  # updateScript runtime tools
  writeShellApplication,
  gh,
  jq,
  nix,
  unzip,
  coreutils,
  autoPatchelfHook,
  patchelfUnstable, # required for --no-clobber-old-sections (Firefox relrhack)
  wrapGAppsHook3,
  alsa-lib,
  adwaita-icon-theme,
  dbus-glib,
  gtk3,
  libGL,
  libva,
  libxtst,
  curl,
  pciutils,
  pipewire,
  # Prebuilt Camoufox release to wrap, read from versions.json so the updater
  # can rewrite it with jq. Override to track a different upstream release. Each
  # arch carries its own version because the upstream sub-version (alpha.N)
  # differs between them.
  camoufoxBinSource ? lib.importJSON ./versions.json,
}:
let
  inherit (camoufoxBinSource) release sources;
  homepage = "https://github.com/daijro/camoufox";

  displayVersion = lib.removePrefix "v" release;
  firefoxVersion = builtins.head (lib.splitString "-" displayVersion);
  camoufoxRelease = lib.removePrefix "${firefoxVersion}-" displayVersion;

  # Token used in the upstream asset name per Nix system.
  archTokens = {
    x86_64-linux = "x86_64";
    aarch64-linux = "arm64";
  };
  system = stdenv.hostPlatform.system;
  source =
    sources.${system}
      or (throw "camoufox-bin: unsupported system '${system}' (only x86_64-linux and aarch64-linux are supported)");
  asset = "camoufox-${source.version}-lin.${archTokens.${system}}.zip";

  libDir = "lib/camoufox-bin-${displayVersion}";
in
stdenv.mkDerivation {
  pname = "camoufox-bin";
  version = displayVersion;

  src = fetchzip {
    url = "${homepage}/releases/download/${release}/${asset}";
    inherit (source) hash;
    # The archive unpacks flat (camoufox-bin and the shared libraries sit at the
    # root), so there is no single directory to strip.
    stripRoot = false;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    patchelfUnstable
    wrapGAppsHook3
  ];

  buildInputs = [
    gtk3
    adwaita-icon-theme
    alsa-lib
    dbus-glib
    libxtst
  ];

  # dlopen()ed at runtime rather than linked, so autoPatchelf cannot discover
  # them; expose them on the final RUNPATH instead.
  runtimeDependencies = [
    curl
    pciutils
    libGL
    libva.out
  ];
  appendRunpaths = [ "${pipewire}/lib" ];

  # Firefox post-processes its own relocations from a fixed offset ("relrhack"),
  # so the patched binaries must keep their original section layout.
  patchelfFlags = [ "--no-clobber-old-sections" ];

  dontConfigure = true;
  dontBuild = true;

  # Default FONTCONFIG_FILE to the baked-in config so a bare `camoufox` launch
  # uses the bundled fonts. --set-default lets the python/JS launchers override
  # it with their own runtime-generated config.
  preFixup = ''
    gappsWrapperArgs+=(
      --set-default FONTCONFIG_FILE "$out/${libDir}/fontconfig/linux/fonts.conf"
    )
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/${libDir}"
    cp -r * "$out/${libDir}/"

    # The bundled fonts.conf resolves its font directory relative to the
    # process CWD (`<dir prefix="cwd">fonts</dir>`). Bake an absolute path so a
    # standalone launch uses Camoufox's bundled fonts (matching the fingerprint
    # the python/JS launchers produce, which rewrite this file the same way).
    substituteInPlace "$out/${libDir}/fontconfig/linux/fonts.conf" \
      --replace-fail '<dir prefix="cwd">fonts</dir>' \
        "<dir>$out/${libDir}/fonts</dir>"

    mkdir -p "$out/bin"
    ln -s "$out/${libDir}/camoufox" "$out/bin/camoufox"

    # Consumers (python-camoufox, camoufox-js, the MCP servers) locate the
    # release metadata next to the executable they are pointed at via
    # CAMOUFOX_EXECUTABLE. Mirror the layout the from-source package produces.
    cp -f "$out/${libDir}/properties.json" "$out/bin/properties.json"
    printf '{"version":"%s","release":"%s"}\n' \
      '${firefoxVersion}' '${camoufoxRelease}' > "$out/bin/version.json"

    runHook postInstall
  '';

  passthru = {
    inherit
      displayVersion
      firefoxVersion
      release
      ;
    category = "Browsers";
    updateScript = writeShellApplication {
      name = "camoufox-bin-update";
      runtimeInputs = [
        gh
        curl
        jq
        nix
        unzip
        coreutils
      ];
      text = builtins.readFile ./update.sh;
    };
  };

  meta = {
    description = "Camoufox browser from a prebuilt upstream release, patched to run on NixOS";
    longDescription = ''
      A NixOS-native wrapper around the official Camoufox binary release. The
      shared objects and launcher are autopatchelf'd against the Nix store and
      wrapped with the GTK runtime, avoiding the lengthy from-source Firefox
      build that the `camoufox` package performs.
    '';
    inherit homepage;
    license = lib.licenses.mpl20;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "camoufox";
  };
}
