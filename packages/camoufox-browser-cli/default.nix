{
  lib,
  buildPythonApplication,
  fetchPypi,
  hatchling,
  python,
  click,
  pydantic,
  cloverlabs-camoufox,
  mcp ? null,
  withMcp ? false,
  camoufox ? null,
}:

let
  camoufoxEnv = import ../camoufox-env.nix { inherit lib; };
in
buildPythonApplication rec {
  pname = "camoufox-browser";
  version = "0.1.1";
  pyproject = true;

  src = fetchPypi {
    pname = "camoufox_browser";
    inherit version;
    hash = "sha256-IOMZIK02a95R32J6BBAW4y+3mf+x9zIUYbTHwRLCX2M=";
  };

  build-system = [ hatchling ];

  postPatch = ''
    python - <<'PY'
    from pathlib import Path
    p = Path("camoufox_mcp/cli/main.py")
    s = p.read_text()
    s = s.replace(
        '    with open(log_file, "w") as log:\n',
        '    daemon_env = os.environ.copy()\n'
        '    daemon_env["PYTHONPATH"] = os.pathsep.join(sys.path)\n'
        '\n'
        '    with open(log_file, "w") as log:\n',
    )
    s = s.replace(
        '            stderr=subprocess.STDOUT,\n        )',
        '            stderr=subprocess.STDOUT,\n            env=daemon_env,\n        )',
        1,
    )
    p.write_text(s)

    p = Path("camoufox_mcp/config.py")
    s = p.read_text()
    s = s.replace('from dataclasses import dataclass, field\n', 'from dataclasses import dataclass, field\nimport os\n')
    s = s.replace(
        '        if self.os is not None:\n            kwargs["os"] = self.os\n',
        '        executable_path = os.environ.get("CAMOUFOX_EXECUTABLE") or os.environ.get("CAMOUFOX_EXECUTABLE_PATH") or os.environ.get("CAMOFOX_EXECUTABLE") or os.environ.get("CAMOFOX_EXECUTABLE_PATH")\n        if executable_path:\n            kwargs["executable_path"] = executable_path\n\n        if self.os is not None:\n            kwargs["os"] = self.os\n',
    )
    p.write_text(s)
    PY
  '';

  dependencies = [
    click
    pydantic
    cloverlabs-camoufox
  ]
  ++ lib.optionals (withMcp && mcp != null) [ mcp ];

  pythonImportsCheck = [ "camoufox_mcp" ];
  doCheck = false;

  postFixup = ''
    wrapProgram "$out/bin/camoufox-browser" \
      --prefix PYTHONPATH : "$out/${python.sitePackages}" \
      ${camoufoxEnv.wrapperBrowserArgs camoufox}
  '';

  meta = {
    description = "CLI-first browser automation powered by Camoufox, with optional MCP support";
    homepage = "https://github.com/rlgrpe/camoufox-browser-cli";
    changelog = "https://github.com/rlgrpe/camoufox-browser-cli/releases/tag/v${version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "camoufox-browser";
  };
}
