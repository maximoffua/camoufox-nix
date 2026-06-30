# Prebuilt Camoufox browser, with bin-wired variants of every camoufox-using
# tool exposed under its passthru as `.#camoufox-bin.<name>`.
{
  lib,
  callPackage,
  tools ? { },
}:
let
  browser = callPackage ./package.nix { };

  argsOf = drv: if drv ? override then lib.functionArgs drv.override else { };

  # Argument names a package receives the browser under, preferred first.
  browserArgNames = [
    "camoufox"
    "camoufox-browser"
  ];
  browserArg = drv: lib.findFirst (name: argsOf drv ? ${name}) null browserArgNames;

  # Dependency argument names that don't match the tool they carry.
  depAliases = {
    pythonCamoufox = "python-camoufox";
  };
  argTool = name: depAliases.${name} or name;

  # Arguments of a package that carry one of the given wired tools.
  wiredDepArgs =
    wiredTools: drv:
    builtins.filter (name: wiredTools ? ${argTool name}) (builtins.attrNames (argsOf drv));

  # Fixpoint: a package is wired once it takes the browser directly or through a
  # dependency that is itself wired.
  wired = lib.converge (
    acc: lib.filterAttrs (_: drv: browserArg drv != null || wiredDepArgs acc drv != [ ]) tools
  ) { };

  variants = builtins.mapAttrs (
    _name: drv:
    let
      browserOverride = lib.optionalAttrs (browserArg drv != null) {
        ${browserArg drv} = browser;
      };
      depOverrides = lib.genAttrs (wiredDepArgs variants drv) (name: variants.${argTool name});
    in
    drv.override (browserOverride // depOverrides)
  ) wired;
in
browser.overrideAttrs (old: {
  passthru = (old.passthru or { }) // variants;
})
