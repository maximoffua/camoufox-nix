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

  camofox-cli = pkgs.callPackage ./camofox-cli/package.nix { };
  camofox-browser = pkgs.callPackage ./camofox-browser/package.nix {
    inherit camoufox;
  };
  camofox-mcp = pkgs.callPackage ./camofox-mcp/package.nix { };

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

  camoufox-js = pkgs.writeShellApplication {
    name = "camoufox-js";
    runtimeInputs = [ pkgs.nodejs ];
    text = ''
      echo "camoufox-js package source: https://github.com/apify/camoufox-js"
      echo "npm package: camoufox-js@0.10.2"
      echo "Full npm dependency packaging still TODO; use camoufox / python-camoufox for Nix-built browser bits."
      exit 1
    '';
    meta = {
      description = "Apify camoufox-js tarball launcher placeholder";
      homepage = "https://github.com/apify/camoufox-js";
      mainProgram = "camoufox-js";
    };
  };

  camoufox-mcp-server = pkgs.writeShellApplication {
    name = "camoufox-mcp-server";
    runtimeInputs = [ pkgs.nodejs ];
    text = ''
      echo "whit3rabbit/camoufox-mcp source: https://github.com/whit3rabbit/camoufox-mcp"
      echo "npm package: camoufox-mcp-server@1.5.0"
      echo "Full npm dependency packaging still TODO; redf0x1 camofox-mcp is packaged as .#camofox-mcp."
      exit 1
    '';
    meta = {
      description = "whit3rabbit camoufox-mcp packaging placeholder";
      homepage = "https://github.com/whit3rabbit/camoufox-mcp";
      mainProgram = "camoufox-mcp-server";
    };
  };

  foxbridge = pkgs.callPackage ./foxbridge/package.nix { };
  vulpineos = pkgs.callPackage ./vulpineos/package.nix { };
  vulpineos-camoufox-notes = pkgs.callPackage ./vulpineos-camoufox-notes/default.nix { };
in
{
  inherit
    camoufox
    camoufox-vulpineos
    python-camoufox
    camofox-cli
    camofox-browser
    camofox-mcp
    camoufox-js
    camoufox-mcp-server
    vulpineos-camoufox-notes
    cloverlabs-camoufox
    camoufox-browser-cli
    foxbridge
    vulpineos
    ;

  default = python-camoufox;
}
