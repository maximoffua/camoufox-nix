{ ... }:

let
  mkPackages = import ./default.nix;
  mkApps = import ./apps.nix;
in
{
  flake.overlays.default = final: _prev: removeAttrs (mkPackages { pkgs = final; }) [ "default" ];

  perSystem =
    { pkgs, ... }:
    let
      packages = mkPackages { inherit pkgs; };
    in
    {
      inherit packages;

      apps = mkApps { inherit pkgs packages; };

      checks = {
        inherit (packages)
          python-camoufox
          vulpineos-camoufox-notes
          cloverlabs-camoufox
          camoufox-browser-cli
          foxbridge
          ;
      };
    };
}
