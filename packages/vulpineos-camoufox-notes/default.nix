{
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "vulpineos-camoufox-notes";
  version = "0.1.0";
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/doc/vulpineos-camoufox
    cp ${./README.md} $out/share/doc/vulpineos-camoufox/README.md
    runHook postInstall
  '';

  meta = {
    description = "Reference note package for VulpineOS Camoufox integration tracking";
    homepage = "https://github.com/VulpineOS/VulpineOS";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
