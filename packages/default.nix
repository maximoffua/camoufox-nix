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
    jo-camofox-browser
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
