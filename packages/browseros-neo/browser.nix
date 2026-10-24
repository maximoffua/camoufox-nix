{
  lib,
  chromium,
  gitMinimal,
  source,
  server,
  onboarding,
}:

# BrowserOS neo = patched Chromium (upstream product "browserclaw").
# Built on nixpkgs' chromium factory with upstream chromium_patches/ applied
# and upstream copy_resources.yaml operations reproduced for product browserclaw.
chromium.mkDerivation (base: rec {
  name = "browseros-neo-browser";
  packageName = "browseros-neo";
  buildTargets = [
    "chrome_sandbox"
    "chrome"
  ];

  outputs = [
    "out"
    "sandbox"
  ];

  sandboxExecutableName = "__chromium-suid-sandbox";

  nativeBuildInputs = base.nativeBuildInputs ++ [ gitMinimal ];

  gnFlags = {
    # Product identity baked at release, mirroring upstream CI
    # (bos_build/core/context.py get_product_gn_args for browserclaw/release).
    browseros_product = "browserclaw";
    browseros_allow_runtime_product_override = false;
    browseros_package_all_server_resources = false;
  };

  postPatch = base.postPatch + ''
      echo "browseros-neo: applying upstream chromium_patches" >&2
      patchesDir="${source}/packages/browseros/chromium_patches"
      failedPatches=""
      while IFS= read -r p; do
        if git apply --ignore-whitespace --whitespace=nowarn -p1 "$p" 2>/dev/null; then
          :
        elif patch -p1 -N -F3 --no-backup-if-mismatch -i "$p" >/dev/null 2>&1; then
          echo "  (fuzz) $p" >&2
        else
          failedPatches="$failedPatches$p\n"
        fi
      done < <(find "$patchesDir" -type f \
          ! -name '.*' \
          ! -name '*.deleted' ! -name '*.binary' ! -name '*.rename' \
          ! -name '.store.yaml' ! -name '.features.yaml' \
          ! -name 'store.yaml' ! -name 'features.yaml' \
          | sort)
      if [ -n "$failedPatches" ]; then
        echo "browseros-neo: patches failed to apply:" >&2
        printf '%b' "$failedPatches" >&2
        exit 1
      fi

      # nixpkgs unbundles libxml: configurePhase replace_gn_files.py
      # overwrites third_party/libxml/BUILD.gn from this template, so the
      # upstream visibility patch must land here too (xml_reader block only).
      substituteInPlace build/linux/unbundle/libxml.gn \
        --replace-fail '    "//components/policy/core/common:unit_tests",' '    "//chrome/browser/browseros/server:server",
    "//components/policy/core/common:unit_tests",'

      # Upstream bundles signed CRXs (bug reporter + product extension).
      # CRX signing keys are not published; Nix loads the extension via
      # --load-extension instead, so ship an empty bundle manifest.
      beDir="chrome/browser/browseros/bundled_extensions"
      echo '{}' > "$beDir/bundled_extensions.json"
      perl -pi -e 's/"[a-p]{32}\.crx",? ?//g' "$beDir/BUILD.gn"

      # Nix store is immutable: server-side OTA would only fail.
      substituteInPlace chrome/browser/browseros/server/browseros_server_config.h \
        --replace-fail "bool enable_updater = true;" "bool enable_updater = false;"

      echo "browseros-neo: copying browserclaw resources into the tree" >&2
      cp ${source}/packages/browseros/resources/BROWSEROS_VERSION chrome/BROWSEROS_VERSION
      resDir="${source}/packages/browseros/resources/browserclaw/icons"
      cp "$resDir"/*.png "$resDir"/*.svg "$resDir"/*.ai chrome/app/theme/chromium/ 2>/dev/null || true
      cp -R "$resDir"/chromeos chrome/app/theme/chromium/chromeos
      cp -R "$resDir"/linux chrome/app/theme/chromium/linux
      cp -R "$resDir"/default_100_percent chrome/app/theme/default_100_percent/chromium
      cp -R "$resDir"/default_200_percent chrome/app/theme/default_200_percent/chromium

      # claw-server resources (bos_build ServerBundle browserclaw-server,
      # chromium_resources_root): binary + skills the browser launches.
      serverRes="chrome/browser/browseros/claw_server/resources"
      mkdir -p "$serverRes/bin"
      cp ${server}/bin/browseros-claw-server "$serverRes/bin/browseros-claw-server"
      cp -R ${server}/share/browseros-neo/server/resources/skills "$serverRes/skills"

      # onboarding WebUI resources (copy_resources.yaml, required/managed).
      mkdir -p chrome/browser/browseros/onboarding/resources
      cp -R ${onboarding}/share/browseros-neo/onboarding/. chrome/browser/browseros/onboarding/resources/
  '';

  installPhase = ''
    libExecPath="$out/libexec/$packageName"
    mkdir -p "$libExecPath"
    cp -v "$buildPath/"*.so "$buildPath/"*.pak "$buildPath/"*.bin "$libExecPath/"
    cp -v "$buildPath/libvulkan.so.1" "$libExecPath/"
    cp -v "$buildPath/vk_swiftshader_icd.json" "$libExecPath/"
    cp -v "$buildPath/icudtl.dat" "$libExecPath/"
    cp -vR "$buildPath/locales" "$buildPath/resources" "$libExecPath/"
    cp -v "$buildPath/chrome_crashpad_handler" "$libExecPath/"
    cp -v "$buildPath/chrome" "$libExecPath/$packageName"

    if [ -n "$(find "$buildPath/swiftshader/" -maxdepth 1 -name '*.so' -print -quit)" ]; then
      mkdir -p "$libExecPath/swiftshader"
      cp -v "$buildPath/swiftshader/"*.so "$libExecPath/swiftshader/"
    fi

    mkdir -p "$sandbox/bin"
    cp -v "$buildPath/chrome_sandbox" "$sandbox/bin/${sandboxExecutableName}"

    if [ -e "$buildPath/chrome.1" ]; then
      mkdir -vp "$out/share/man/man1"
      cp -v "$buildPath/chrome.1" "$out/share/man/man1/$packageName.1"
    fi

    for icon_file in chrome/app/theme/chromium/product_logo_*[0-9].png; do
      num_and_suffix="''${icon_file##*logo_}"
      icon_size="''${num_and_suffix%.*}"
      expr "$icon_size" : '^[0-9][0-9]*$' >/dev/null || continue
      mkdir -vp "$out/share/icons/hicolor/''${icon_size}x''${icon_size}/apps"
      cp -v "$icon_file" "$out/share/icons/hicolor/''${icon_size}x''${icon_size}/apps/$packageName.png"
    done

    # Managed server bundle at the Linux layout the browser expects:
    # <exe_dir>/BrowserClawServer/default/resources (browseros_server_utils.cc).
    bundleRes="$libExecPath/BrowserClawServer/default/resources"
    mkdir -p "$bundleRes/bin"
    cp -v ${server}/bin/browseros-claw-server "$bundleRes/bin/browseros-claw-server"
    cp -R ${server}/share/browseros-neo/server/resources/skills "$bundleRes/skills"

    install -D chrome/installer/linux/common/desktop.template \
      $out/share/applications/browseros-neo.desktop
    # Chromium 155 template placeholders lack the closing @@ suffix.
    substituteInPlace $out/share/applications/browseros-neo.desktop \
      --replace-fail "@@MENUNAME" "BrowserOS neo" \
      --replace-fail "@@desktop_icon" "$packageName" \
      --replace-fail "@@desktop_exec" "$packageName" \
      --replace-fail "@@uri_scheme" "" \
      --replace-fail "@@startup_wm_class" "$packageName" \
      --replace-fail "@@extra_desktop_entries" ""
  ''
  + ''
    if grep -F '@@' $out/share/applications/browseros-neo.desktop ; then
      echo "error: browseros-neo.desktop contains unsubstituted placeholders" >&2
      exit 1
    fi
  '';

  passthru = { inherit sandboxExecutableName; };

  requiredSystemFeatures = [ "big-parallel" ];

  meta = {
    description = "BrowserOS neo — the open source browser for web agents (patched Chromium)";
    homepage = "https://github.com/browseros-ai/BrowserOS";
    license = lib.licenses.agpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "browseros-neo";
    hydraPlatforms = [ ];
    timeout = 172800;
  };
})
