{
  lib,
  stdenv,
  makeWrapper,
  browser,
  extension,
}:

# The patched Chromium launches the MCP server itself from its libexec bundle;
# this wrapper only selects the Nix-built extension (upstream ships it as an
# unpacked directory too). Disable the upstream extension provider: its remote
# installs outrank command-line extensions and would replace the Nix-built UI.
stdenv.mkDerivation {
  pname = "browseros-neo";
  version = "0.52.1";

  dontUnpack = true;
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/share"
    ln -s "${browser}/share/applications" "$out/share/applications"
    ln -s "${browser}/share/icons" "$out/share/icons"
    ln -s "${browser}/share/man" "$out/share/man"
    makeWrapper "${browser}/libexec/browseros-neo/browseros-neo" "$out/bin/browseros-neo" \
      --set-default CHROME_DEVEL_SANDBOX "${browser.sandbox}/bin/__chromium-suid-sandbox" \
      --append-flags "--disable-browseros-extensions" \
      --append-flags "--disable-browseros-server-updater" \
      --append-flags "--load-extension=${extension}/share/browseros-neo/extension"
    runHook postInstall
  '';

  meta = {
    description = "BrowserOS neo — the open source browser for web agents";
    homepage = "https://github.com/browseros-ai/BrowserOS";
    license = lib.licenses.agpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "browseros-neo";
  };
}
