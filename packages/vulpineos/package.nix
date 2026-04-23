{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "vulpineos";
  version = "0-unstable-2026-04-29";
  rev = "main";

  src = fetchFromGitHub {
    owner = "VulpineOS";
    repo = "VulpineOS";
    inherit rev;
    hash = "sha256-Pl96JFx7+DTvr7aKMyFwN37Vbz0ckxsNcuv2ku80Zww=";
  };

  vendorHash = "sha256-mto81s8XYNli1GtQpYpXNaGHSL98W8tg5vzyw/PJpQg=";

  subPackages = [ "cmd/vulpineos" ];

  ldflags = [
    "-s"
    "-w"
    "-X"
    "main.Version=${version}"
  ];

  doCheck = false;

  meta = {
    description = "Stealth-aware AI browser agent runtime with browser-engine security";
    homepage = "https://github.com/VulpineOS/VulpineOS";
    license = lib.licenses.mpl20;
    platforms = lib.platforms.linux;
    mainProgram = "vulpineos";
  };
}
