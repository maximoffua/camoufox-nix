{
  lib,
  buildPythonPackage,
  fetchPypi,
  python,
  poetry-core,
  callPackage,
  inquirer,
  language-tags,
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
  camoufox-browser ? null,
}:

let
  camoufoxEnv = import ../camoufox-env.nix { inherit lib; };
  fpgen = callPackage ../fpgen/package.nix { };
in
buildPythonPackage rec {
  pname = "camoufox";
  version = "0.5.9";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-jXHxyNNjI+4NLqH9TG3j7kp835W/KWuQuW2QltwvgCw=";
  };

  patches = [ ./nix-executable-env.patch ];

  # Upstream caps playwright at <1.63; nixpkgs-unstable ships 1.61.x.

  build-system = [ poetry-core ];

  dependencies = [
    fpgen
    inquirer
    language-tags
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
  ];

  nativeBuildInputs = [ makeWrapper ];

  pythonImportsCheck = [
    "camoufox"
    "fpgen"
  ];

  # Verify pinned model without network or writes into immutable fpgen data.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    ${lib.optionalString (camoufox-browser != null) ''
      export CAMOUFOX_EXECUTABLE=${lib.escapeShellArg (lib.getExe camoufox-browser)}
    ''}
    PYTHONPATH="$out/${python.sitePackages}:$PYTHONPATH" ${python.interpreter} <<'PY'
    from camoufox.fpgen_model import ensure_fpgen_model
    from camoufox.fingerprints import generate_fingerprint
    ensure_fpgen_model()
    assert generate_fingerprint(os='linux')
    from camoufox.pkgman import env_executable_path, installed_verstr
    from camoufox.utils import _load_properties, resolve_verstr
    executable = env_executable_path()
    if executable:
        assert executable.is_file()
        assert resolve_verstr(executable)
        assert installed_verstr()
        assert _load_properties(executable)
    PY
    runHook postInstallCheck
  '';

  postFixup = lib.optionalString (camoufox-browser != null) ''
    wrapProgram "$out/bin/camoufox" \
      ${camoufoxEnv.wrapperBrowserArgs camoufox-browser}
  '';

  meta = {
    description = "Python interface for launching Camoufox with Playwright";
    homepage = "https://github.com/daijro/camoufox";
    changelog = "https://pypi.org/project/camoufox/${version}/";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "camoufox";
  };
}
