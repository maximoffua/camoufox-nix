{
  playwright,
  fetchFromGitHub,
  fetchurl,
  runCommand,
}:

let
  # Camoufox 0.5.9 requires Playwright <1.63; keep Python API and driver paired.
  version = "1.62.0";
  driver = runCommand "playwright-core-${version}" { } ''
    mkdir -p "$out"
    tar -xzf ${
      fetchurl {
        url = "https://registry.npmjs.org/playwright-core/-/playwright-core-${version}.tgz";
        hash = "sha256-JXsOKfuAcDnT1n/nyRiKK5aWQDxXghsQy2yNY145eJo=";
      }
    } -C "$out" --strip-components=1
  '';
in
(playwright.override { playwright-driver = driver; }).overridePythonAttrs {
  inherit version;
  src = fetchFromGitHub {
    owner = "microsoft";
    repo = "playwright-python";
    tag = "v${version}";
    hash = "sha256-E9silyNQtFEPShimuEbWXvg5fgf+vqaiDez+Ri0jDTw=";
  };
}
