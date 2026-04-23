{
  lib,
  buildPythonPackage,
  fetchPypi,
  poetry-core,
  browserforge,
  click,
  language-tags,
  lxml,
  numpy,
  orjson,
  platformdirs,
  playwright,
  pysocks,
  pyyaml,
  requests,
  screeninfo,
  tqdm,
  typing-extensions,
  ua-parser,
  makeWrapper,
  camoufox-browser ? null,
}:

buildPythonPackage rec {
  pname = "camoufox";
  version = "0.4.11";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-CiydJKxQcMEE58KxJcCjk39w76QWCE74iv6Uwypy7r4=";
  };

  build-system = [ poetry-core ];

  dependencies = [
    browserforge
    click
    language-tags
    lxml
    numpy
    orjson
    platformdirs
    playwright
    pysocks
    pyyaml
    requests
    screeninfo
    tqdm
    typing-extensions
    ua-parser
  ];

  nativeBuildInputs = [ makeWrapper ];

  pythonImportsCheck = [ "camoufox" ];

  postFixup = lib.optionalString (camoufox-browser != null) ''
    wrapProgram "$out/bin/camoufox" \
      --set CAMOUFOX_EXECUTABLE_PATH "${lib.getExe camoufox-browser}"
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
