{
  pkgs,
  browserosChromium ? pkgs.chromium,
}:
let
  camoufox = pkgs.callPackage ./camoufox/package.nix { };

  camoufox-vulpineos = camoufox.override {
    camoufoxSource = {
      owner = "VulpineOS";
      repo = "VulpineOS";
      rev = "f8579728616e892c364aa4c571f05db5869bc59f";
      hash = "sha256-HGQ1FeJIG/i/fwIynqK3K/c3V1MS7ZjKvKSc23XjKg0=";
      version = "0-unstable-2026-06-29";
      firefoxVersion = "146.0.1";
      firefoxHash = "sha256-6WeKDoRzkjlT4dwxLDeRkGhiO2qiCtreFiZgSSWBkes=";
      displayVersion = "146.0.1-beta.25";
      mozTarget = pkgs.lib.replaceStrings [ "-pc-" ] [ "-unknown-" ] pkgs.stdenv.hostPlatform.config;
      homepage = "https://github.com/VulpineOS/VulpineOS";
      sourceName = "VulpineOS/VulpineOS";
      settingsConfig = "vulpine.cfg";
      binaryName = "vulpine";
      excludedPatchFiles = [
        "action-lock.patch"
        "disable-remote-subframes.patch"
      ];
    };
  };

  camofox-cli = pkgs.callPackage ./camofox-cli/package.nix {
    inherit camoufox;
  };
  camofox-browser = pkgs.callPackage ./camofox-browser/package.nix {
    inherit camoufox;
  };
  jo-camofox-browser = pkgs.callPackage ./jo-camofox-browser/package.nix {
    inherit camoufox;
  };
  camofox-mcp = pkgs.callPackage ./camofox-mcp/package.nix {
    inherit camoufox;
  };

  camoufox-mcp-sdk = pkgs.python3Packages.callPackage ./mcp-v1/package.nix { };
  camoufox-reverse-mcp = pkgs.python3Packages.callPackage ./camoufox-reverse-mcp/default.nix {
    inherit camoufox;
    mcp = camoufox-mcp-sdk;
    pythonCamoufox = python-camoufox;
    playwright = camoufox-playwright;
  };

  camoufox-playwright = pkgs.python3Packages.callPackage ./python-camoufox/playwright.nix { };
  python-camoufox = pkgs.python3Packages.callPackage ./python-camoufox/default.nix {
    camoufox-browser = camoufox;
    playwright = camoufox-playwright;
  };

  cloverlabs-camoufox = pkgs.python3Packages.callPackage ./cloverlabs-camoufox/default.nix {
    camoufox-browser = camoufox;
  };

  camoufox-browser-cli = pkgs.python3Packages.callPackage ./camoufox-browser-cli/default.nix {
    inherit cloverlabs-camoufox camoufox;
    withMcp = true;
    mcp = camoufox-mcp-sdk;
  };

  camoufox-js = pkgs.callPackage ./camoufox-js/package.nix {
    inherit camoufox;
  };

  camoufox-mcp-server = pkgs.writeShellApplication {
    name = "camoufox-mcp-server";
    text = ''
      printf '%s\n' 'TODO: package whit3rabbit/camoufox-mcp npm graph for camoufox-mcp-server@2.6.0.' >&2
      printf '%s\n' 'Use .#camofox-mcp or .#camoufox-reverse-mcp for a working MCP server.' >&2
      exit 1
    '';
    meta = {
      description = "Placeholder for whit3rabbit Camoufox MCP server";
      homepage = "https://github.com/whit3rabbit/camoufox-mcp";
      license = pkgs.lib.licenses.mit;
      platforms = pkgs.lib.platforms.unix;
      mainProgram = "camoufox-mcp-server";
    };
  };

  foxbridge = pkgs.callPackage ./foxbridge/package.nix { };
  vulpineos = pkgs.callPackage ./vulpineos/package.nix { };
  vulpineos-camoufox-notes = pkgs.callPackage ./vulpineos-camoufox-notes/default.nix { };
  browseros-neo-source = pkgs.callPackage ./browseros-neo/source.nix { };
  browseros-neo-server = pkgs.callPackage ./browseros-neo/server.nix {
    source = browseros-neo-source;
  };
  browseros-neo-extension = pkgs.callPackage ./browseros-neo/extension.nix {
    source = browseros-neo-source;
    bunDeps = browseros-neo-bun-deps;
  };
  browseros-neo-onboarding = pkgs.callPackage ./browseros-neo/onboarding.nix {
    source = browseros-neo-source;
    bunDeps = browseros-neo-bun-deps;
  };
  browseros-neo-bun-deps = pkgs.callPackage ./browseros-neo/bun-deps.nix {
    source = browseros-neo-source;
  };
  browseros-neo-browser = pkgs.callPackage ./browseros-neo/browser.nix {
    chromium = browserosChromium;
    source = browseros-neo-source;
    server = browseros-neo-server;
    onboarding = browseros-neo-onboarding;
  };
  browseros-neo = pkgs.callPackage ./browseros-neo/wrapper.nix {
    browser = browseros-neo-browser;
    extension = browseros-neo-extension;
  };

  # Collected once so camoufox-bin can derive its variants from the same set.
  packages = {
    inherit
      camoufox
      camoufox-vulpineos
      python-camoufox
      camofox-cli
      camofox-browser
      jo-camofox-browser
      camofox-mcp
      camoufox-reverse-mcp
      camoufox-js
      camoufox-mcp-server
      vulpineos-camoufox-notes
      cloverlabs-camoufox
      camoufox-browser-cli
      foxbridge
      vulpineos
      browseros-neo-server
      browseros-neo-extension
      browseros-neo-onboarding
      browseros-neo-browser
      browseros-neo
      ;
  };
in
packages
// {
  camoufox-bin = pkgs.callPackage ./camoufox-bin { tools = packages; };
  default = camoufox;
}
