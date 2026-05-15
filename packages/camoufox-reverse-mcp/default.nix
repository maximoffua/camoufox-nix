{
  lib,
  buildPythonApplication,
  fetchFromGitHub,
  hatchling,
  python,
  makeWrapper,
  mcp,
  esprima,
  playwright,
  pythonCamoufox,
  camoufox ? null,
}:

let
  camoufoxEnv = import ../camoufox-env.nix { inherit lib; };
in
buildPythonApplication rec {
  pname = "camoufox-reverse-mcp";
  version = "1.1.0-unstable-2026-05-08";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "WhiteNightShadow";
    repo = "camoufox-reverse-mcp";
    rev = "54a72d31b6537ac845fc775296f6d221a73ed137";
    hash = "sha256-OOv7IgiqFAGUTnax+PHaj5QimHWdiZTVucbEt+PaS8k=";
  };

  build-system = [ hatchling ];

  dependencies = [
    esprima
    mcp
    playwright
    pythonCamoufox
  ];

  nativeBuildInputs = [ makeWrapper ];

  pythonImportsCheck = [ "camoufox_reverse_mcp" ];

  # Upstream tests drive a live browser/MCP session. Keep the build cheap and
  # validate import/CLI wiring in flake checks instead.
  doCheck = false;

  postFixup = ''
    wrapProgram "$out/bin/camoufox-reverse-mcp" \
      --prefix PYTHONPATH : "$out/${python.sitePackages}" \
      ${camoufoxEnv.wrapperBrowserArgs camoufox}
  '';

  meta = {
    description = "Camoufox-based MCP server for JavaScript reverse engineering";
    homepage = "https://github.com/WhiteNightShadow/camoufox-reverse-mcp";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "camoufox-reverse-mcp";
  };
}
