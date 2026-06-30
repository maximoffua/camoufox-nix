{ pkgs }:
let
  camoufox = pkgs.callPackage ./camoufox/package.nix { };

  camoufox-vulpineos = camoufox.override {
    camoufoxSource = {
      owner = "VulpineOS";
      repo = "VulpineOS";
      rev = "main";
      hash = "sha256-Pl96JFx7+DTvr7aKMyFwN37Vbz0ckxsNcuv2ku80Zww=";
      version = "0-unstable-2026-04-29";
      firefoxVersion = "146.0.1";
      displayVersion = "146.0.1-beta.25";
      homepage = "https://github.com/VulpineOS/VulpineOS";
      sourceName = "VulpineOS/VulpineOS";
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

  camoufox-reverse-mcp = pkgs.python3Packages.callPackage ./camoufox-reverse-mcp/default.nix {
    inherit camoufox;
    pythonCamoufox = python-camoufox;
  };

  python-camoufox = pkgs.python3Packages.callPackage ./python-camoufox/default.nix {
    camoufox-browser = camoufox;
  };

  cloverlabs-camoufox = pkgs.python3Packages.callPackage ./cloverlabs-camoufox/default.nix {
    camoufox-browser = camoufox;
  };

  camoufox-browser-cli = pkgs.python3Packages.callPackage ./camoufox-browser-cli/default.nix {
    inherit cloverlabs-camoufox camoufox;
    withMcp = true;
  };

  camoufox-js = pkgs.callPackage ./camoufox-js/package.nix {
    inherit camoufox;
  };

  camoufox-mcp-server = pkgs.writeShellApplication {
    name = "camoufox-mcp-server";
    text = ''
      printf '%s\n' 'TODO: package whit3rabbit/camoufox-mcp npm graph for camoufox-mcp-server@1.5.0.' >&2
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
      ;
  };
in
packages
// {
  camoufox-bin = pkgs.callPackage ./camoufox-bin { tools = packages; };
  default = python-camoufox;
}
