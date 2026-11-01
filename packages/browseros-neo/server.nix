{
  lib,
  rustPlatform,
  source,
}:

rustPlatform.buildRustPackage {
  pname = "browseros-neo-server";
  version = "0.0.90"; # claw-server version in the public 0.52.1 source
  src = "${source}/packages/browseros-agent";

  cargoLock.lockFile = "${source}/packages/browseros-agent/Cargo.lock";
  cargoBuildFlags = [
    "-p"
    "claw-server"
    "--bin"
    "browseros-claw-server-rs"
  ];
  cargoTestFlags = [
    "-p"
    "claw-server"
  ];

  # Browser lifecycle and CDP integration require a running patched browser.
  doCheck = false;

  installPhase = ''
    runHook preInstall
    install -Dm755 "$(find target -type f -name browseros-claw-server-rs -perm -u+x | head -n1)" \
      "$out/bin/browseros-claw-server"
    ln -s browseros-claw-server "$out/bin/browseros-claw-server-rs"
    install -Dm644 resources/skills/browserclaw/SKILL.md \
      "$out/share/browseros-neo/server/resources/skills/browserclaw/SKILL.md"
    runHook postInstall
  '';

  meta = {
    description = "BrowserOS neo MCP and browser automation server (built from source)";
    homepage = "https://github.com/browseros-ai/BrowserOS";
    license = lib.licenses.agpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "browseros-claw-server";
  };
}
