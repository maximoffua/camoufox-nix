{ ... }:
let
  mkPackages = import ./default.nix;
  mkApps = import ./apps.nix;
in
{
  flake.overlays.default =
    final: prev:
    let
      packages = mkPackages { pkgs = final; };
    in
    removeAttrs packages [ "default" ]
    // {
      pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
        (python-final: _python-prev: {
          camoufox = python-final.callPackage ./python-camoufox/default.nix {
            camoufox-browser = final.camoufox;
          };
        })
      ];
    };

  perSystem =
    { pkgs, ... }:
    let
      packages = mkPackages { inherit pkgs; };
    in
    {
      inherit packages;

      legacyPackages.python3Packages.camoufox = packages.python-camoufox;

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
