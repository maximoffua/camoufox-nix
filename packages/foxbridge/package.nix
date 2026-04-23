{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "foxbridge";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "VulpineOS";
    repo = "foxbridge";
    rev = "v${version}";
    hash = "sha256-YH8TWESpPuzeu9h0a2KPes9FX8UrsINz6QZyW9dr2vM=";
  };

  vendorHash = "sha256-Edr6beVlkHcHj1Jx4vxnJBeVov5sSPKO8dR1G2fQ7l8=";

  subPackages = [ "cmd/foxbridge" ];

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "CDP-to-Firefox protocol proxy bridging Juggler/BiDi to CDP clients";
    homepage = "https://github.com/VulpineOS/foxbridge";
    changelog = "https://github.com/VulpineOS/foxbridge/releases/tag/v${version}";
    license = lib.licenses.mpl20;
    platforms = lib.platforms.unix;
    mainProgram = "foxbridge";
  };
}
