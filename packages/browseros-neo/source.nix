{ fetchFromGitHub }:

# BrowserOS neo (BrowserClaw), not the separate BrowserOS product.
fetchFromGitHub {
  owner = "browseros-ai";
  repo = "BrowserOS";
  # Public source identified by build-provenance-0.52.1.json in browserclaw/v0.52.0.
  # Official binaries include newer private component revisions; we build public source.
  rev = "22a331a2b846df9cc233e9614ab0ae4696e79947";
  hash = "sha256-qedQJAyYXojzfU9vB4KzrpwDu40Z9gkjUs4GgEA5J58=";
}
