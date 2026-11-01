{
  lib,
  buildPythonPackage,
  fetchPypi,
  fetchurl,
  python,
  poetry-core,
  click,
  httpx,
  indexed-zstd,
  numpy,
  orjson,
  zstandard,
  unzip,
}:

buildPythonPackage rec {
  pname = "fpgen";
  version = "1.3.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-AXzBXq83PswEEEvI49QX1KJIqcPD6TcW+UrF62QqU0w=";
  };

  build-system = [ poetry-core ];
  dependencies = [
    click
    httpx
    indexed-zstd
    numpy
    orjson
    zstandard
  ];
  nativeBuildInputs = [ unzip ];

  # Nix manages model updates; normalized store timestamps must not trigger downloads.
  postPatch = ''
    substituteInPlace fpgen/pkgman.py \
      --replace-fail 'datetime.now() - timedelta(weeks=5)' 'datetime.min'
  '';

  postInstall =
    let
      model = fetchurl {
        url = "https://github.com/scrapfly/fingerprint-generator/releases/download/model-2/2026/model-release.zip";
        hash = "sha256-ZTC4MizapOwEKSHI2aA2mg5uAmm6Y2wBpyA+Si8QmTY=";
      };
    in
    ''
      modelDir="$out/${python.sitePackages}/fpgen/data"
      mkdir -p "$modelDir"
      unzip ${model} -d "$modelDir"
      printf '%s\n' 6530b8322cdaa4ec042921c8d9a0369a0e6e0269ba636c01a7203e4a2f109936 \
        > "$modelDir/.pinned-model"
    '';

  pythonImportsCheck = [ "fpgen" ];

  meta = {
    description = "Fingerprint generator with Camoufox's pinned offline model";
    homepage = "https://github.com/scrapfly/fingerprint-generator";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
