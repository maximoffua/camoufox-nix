{
  lib,
  buildPythonPackage,
  fetchPypi,
  poetry-core,
  browserforge,
  geoip2,
  inquirer,
  language-tags,
  lxml,
  numpy,
  orjson,
  platformdirs,
  playwright,
  pysocks,
  pyyaml,
  requests,
  rich,
  rich-click,
  screeninfo,
  typing-extensions,
  ua-parser,
  makeWrapper,
  withGeoip ? true,
  camoufox-browser ? null,
}:

let
  camoufoxEnv = import ../camoufox-env.nix { inherit lib; };
in
buildPythonPackage rec {
  pname = "cloverlabs-camoufox";
  version = "0.5.5";
  pyproject = true;

  src = fetchPypi {
    pname = "cloverlabs_camoufox";
    inherit version;
    hash = "sha256-TzMHGeKtIdlMn0+uEIoHTgfd3627HiJD0dZ2IaPb/tc=";
  };

  build-system = [ poetry-core ];

  postPatch = ''
    python - <<'PY'
    from pathlib import Path
    p = Path("camoufox/pkgman.py")
    s = p.read_text()
    marker = 'def launch_path(browser_path: Optional[Path] = None) -> str:\n'
    replacement = marker + '    env_path = os.environ.get("CAMOUFOX_EXECUTABLE") or os.environ.get("CAMOUFOX_EXECUTABLE_PATH") or os.environ.get("CAMOFOX_EXECUTABLE") or os.environ.get("CAMOFOX_EXECUTABLE_PATH")\n    if env_path:\n        return env_path\n'
    s = s.replace(marker, replacement)
    p.write_text(s)
    PY
  '';

  dependencies = [
    browserforge
    inquirer
    language-tags
    lxml
    numpy
    orjson
    platformdirs
    playwright
    pysocks
    pyyaml
    requests
    rich
    rich-click
    screeninfo
    typing-extensions
    ua-parser
  ]
  ++ lib.optionals withGeoip [ geoip2 ];

  nativeBuildInputs = [ makeWrapper ];

  pythonImportsCheck = [ "camoufox" ];
  doCheck = false;

  postFixup = lib.optionalString (camoufox-browser != null) ''
    wrapProgram "$out/bin/camoufox" \
      ${camoufoxEnv.wrapperBrowserArgs camoufox-browser}
  '';

  meta = {
    description = "Cloverlabs Camoufox Python interface around Playwright";
    homepage = "https://github.com/CloverLabsAI/camoufox";
    changelog = "https://pypi.org/project/cloverlabs-camoufox/${version}/";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "camoufox";
  };
}
