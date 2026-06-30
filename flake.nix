{
  description = "Camoufox browser and automation tools packaged with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{
      flake-parts,
      systems,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import systems;

      imports = [
        treefmt-nix.flakeModule
        ./packages/flake-module.nix
      ];

      perSystem =
        {
          config,
          pkgs,
          ...
        }:
        let
          packages = config.packages;

          browserImageBase = [
            pkgs.cacert
            pkgs.dockerTools.binSh
          ];
        in
        {
          packages = {
            docker-camoufox-camofox-mcp = pkgs.dockerTools.buildLayeredImage {
              name = "camoufox-camofox-mcp";
              tag = "latest";
              maxLayers = 120;
              contents = browserImageBase ++ [
                packages.camoufox
                packages.camofox-mcp
              ];
              extraCommands = ''
                mkdir -m 1777 -p tmp var/tmp
              '';
              config = {
                Env = [
                  "CAMOUFOX_EXECUTABLE=${pkgs.lib.getExe packages.camoufox}"
                  "CAMOUFOX_EXECUTABLE_PATH=${pkgs.lib.getExe packages.camoufox}"
                  "CAMOFOX_EXECUTABLE=${pkgs.lib.getExe packages.camoufox}"
                  "CAMOFOX_EXECUTABLE_PATH=${pkgs.lib.getExe packages.camoufox}"
                  "HOME=/tmp"
                  "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                ];
                Entrypoint = [ (pkgs.lib.getExe packages.camofox-mcp) ];
                WorkingDir = "/tmp";
                Labels = {
                  "org.opencontainers.image.title" = "camoufox-camofox-mcp";
                  "org.opencontainers.image.description" = "Camoufox browser with camofox-mcp server";
                  "org.opencontainers.image.source" = "https://github.com/daijro/camoufox";
                };
              };
            };

            docker-vulpineos-foxbridge = pkgs.dockerTools.buildLayeredImage {
              name = "vulpineos-foxbridge";
              tag = "latest";
              maxLayers = 120;
              contents = browserImageBase ++ [
                packages.camoufox-vulpineos
                packages.foxbridge
                packages.vulpineos
              ];
              extraCommands = ''
                mkdir -m 1777 -p tmp var/tmp
              '';
              config = {
                Env = [
                  "CAMOUFOX_EXECUTABLE=${pkgs.lib.getExe packages.camoufox-vulpineos}"
                  "CAMOUFOX_EXECUTABLE_PATH=${pkgs.lib.getExe packages.camoufox-vulpineos}"
                  "CAMOFOX_EXECUTABLE=${pkgs.lib.getExe packages.camoufox-vulpineos}"
                  "CAMOFOX_EXECUTABLE_PATH=${pkgs.lib.getExe packages.camoufox-vulpineos}"
                  "HOME=/tmp"
                  "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                ];
                Entrypoint = [ (pkgs.lib.getExe packages.vulpineos) ];
                WorkingDir = "/tmp";
                Labels = {
                  "org.opencontainers.image.title" = "vulpineos-foxbridge";
                  "org.opencontainers.image.description" =
                    "VulpineOS runtime, VulpineOS Camoufox fork, and foxbridge";
                  "org.opencontainers.image.source" = "https://github.com/VulpineOS/VulpineOS";
                };
              };
            };
          };

          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.jujutsu
              pkgs.nixfmt-rfc-style
              pkgs.nixpkgs-fmt
              pkgs.nodejs
              pkgs.python3
            ];
          };

          formatter = config.treefmt.build.wrapper;

          treefmt = {
            programs.nixfmt.enable = true;
            programs.deadnix.enable = true;
          };
        };
    };
}
