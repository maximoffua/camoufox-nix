{ fetchFromGitHub }:

# BrowserOS neo (BrowserClaw), not the separate BrowserOS product.
fetchFromGitHub {
  owner = "browseros-ai";
  repo = "BrowserOS";
  rev = "db227de2a98c65b1abc7b3be773c5ac16578a8bf"; # browserclaw/v0.51.1.2
  hash = "sha256-jnW4NrbsaZ1digRhLQ2ySEgGZvOrIt+U7TgcfoY1hHk=";
}
