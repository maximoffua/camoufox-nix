# camoufox-nix

Nix packages for [Camoufox](https://github.com/daijro/camoufox), its Python and
Node interfaces, browser servers, MCP servers, protocol tools, VulpineOS, and
two OCI images. The flake uses `flake-parts` and exports packages through its
default overlay.

No status or release badges are included: this repository does not expose
verified badge URLs.

## Quick start

```console
$ nix flake show github:maximoffua/camoufox-nix
$ nix run github:maximoffua/camoufox-nix -- --help
$ nix build github:maximoffua/camoufox-nix#camoufox
$ nix shell github:maximoffua/camoufox-nix#python-camoufox
```

`nix run` and `nix build` without an attribute select `python-camoufox`. Use
`.` from a checkout.

## Packages

Versions below are the values declared by package sources. `unstable-YYYY-MM-DD`
versions identify source snapshots, not upstream releases.

| Flake package | Version | Description | Declared platforms |
| --- | --- | --- | --- |
| `camoufox` | `150.0.2` | Patched Camoufox/Firefox browser source build | Linux |
| `camoufox-bin` | `150.0.2-beta.25` | Prebuilt Camoufox release patched for NixOS; no Firefox compile | Linux `x86_64`, `aarch64` |
| `camoufox-vulpineos` | `0-unstable-2026-04-29` | VulpineOS Camoufox fork; browser display version `146.0.1-beta.25` | Linux |
| `python-camoufox` | `0.5.3` | Python interface for launching Camoufox with Playwright | Unix |
| `cloverlabs-camoufox` | `0.6.0` | CloverLabs Python interface; GeoIP enabled by default | Unix |
| `camoufox-browser-cli` | `0.1.1` | Python CLI with optional MCP support; built here with MCP enabled | Unix |
| `camofox-cli` | `0.7.1` | Node automation CLI | Linux |
| `camofox-browser` | `2.4.6` | Node anti-detection browser server | Linux |
| `jo-camofox-browser` | `1.9.1` | Node browser server from `maximoffua/camofox-browser` | Linux |
| `camofox-mcp` | `1.14.5` | Node MCP server; also provides `camofox-mcp-http` | Linux |
| `camoufox-reverse-mcp` | `1.1.0-unstable-2026-05-08` | Python MCP server for JavaScript reverse engineering | Unix |
| `camoufox-js` | `0.11.2` | JavaScript interface and CLI for Playwright | Linux |
| `camoufox-mcp-server` | `1.5.0` target | Placeholder for `whit3rabbit/camoufox-mcp`; exits non-zero | Unix |
| `foxbridge` | `0.1.1` | CDP-to-Firefox protocol proxy | Unix |
| `vulpineos` | `0-unstable-2026-04-29` | VulpineOS browser-agent runtime | Linux |
| `vulpineos-camoufox-notes` | `0.1.0` | Reference documentation derivation; no binary | All |
| `docker-camoufox-camofox-mcp` | `latest` | OCI image containing `camoufox` and `camofox-mcp` | OCI tarball |
| `docker-vulpineos-foxbridge` | `latest` | OCI image containing VulpineOS, foxbridge, and VulpineOS Camoufox | OCI tarball |

## Prebuilt browser

`camoufox-bin` unpacks an official
[Camoufox release](https://github.com/daijro/camoufox/releases) and patches it
for NixOS with `autoPatchelfHook` and a GTK wrapper instead of compiling Firefox
from source. It exposes the same `bin/camoufox`, `version.json`, and
`properties.json` as `camoufox`, so every consumer that reads the browser
executable environment variables works against it unchanged.

```console
$ nix build .#camoufox-bin
$ nix run .#camoufox-bin -- --version
$ ./result/bin/camoufox https://example.com
```

Write a headless screenshot to confirm it renders:

```console
$ nix run .#camoufox-bin -- --headless --screenshot "$PWD/camoufox-bin.png" https://example.com
```

`camoufox-bin` declares Linux `x86_64` and `aarch64` only. It skips the Firefox
compile but fetches a release archive of roughly 660 MB on the first build. Its
bundled fonts are wired through `FONTCONFIG_FILE`, so a bare launch fingerprints
the same as the Python and JavaScript launchers.

### Ready-made tool variants

Every tool in this flake that uses Camoufox is also exposed pre-wired to the
prebuilt browser, as a subpackage under `camoufox-bin`. No override needed:

```console
$ nix build .#camoufox-bin.python-camoufox
$ nix run .#camoufox-bin.camoufox-reverse-mcp -- --help
```

These variants are derived automatically: any package wired to Camoufox, either
directly or transitively through another package to any depth, gets a
`camoufox-bin.<name>` variant whose whole closure uses the prebuilt browser and
never builds Firefox from source.

To wire up a package outside this flake, each tool still takes the browser as a
`callPackage` argument, named `camoufox` for most tools and `camoufox-browser`
for the two Python interfaces:

```nix
# in your own flake, with camoufox-nix as an input:
let p = camoufox-nix.packages.${system};
in p.camofox-mcp.override { camoufox = p.camoufox-bin; }
```

The pin lives in `packages/camoufox-bin/versions.json`. Run
`nix run .#camoufox-bin.updateScript` from the repository root, optionally with
`-- <tag>`, to bump it to the latest release. To track a different release ad
hoc, override `camoufoxBinSource` with the `release` tag plus each
architecture's `version`, the differing `alpha.N`, and `hash`; the asset name
and Firefox version are derived:

```nix
camoufox-bin-next = camoufox-bin.override {
  camoufoxBinSource = {
    release = "v150.0.2-beta.25";
    sources = {
      x86_64-linux = { version = "150.0.2-alpha.26"; hash = "sha256-..."; };
      aarch64-linux = { version = "150.0.2-alpha.25"; hash = "sha256-..."; };
    };
  };
};
```

## Consumer examples

### Run, shell, and build

```console
# Python CLI (default app)
$ nix run github:maximoffua/camoufox-nix#camoufox-python -- --help

# Browser
$ nix run github:maximoffua/camoufox-nix#camoufox -- --version

# Temporary environment
$ nix shell github:maximoffua/camoufox-nix#python-camoufox

# Store path without linking result
$ nix build github:maximoffua/camoufox-nix#camoufox

# Several outputs
$ nix build .#foxbridge .#vulpineos
```

The full browser build compiles Firefox and is Linux-only. Reuse its path with
browser tools:

```console
$ export CAMOUFOX_EXECUTABLE_PATH="$(nix build .#camoufox --no-link --print-out-paths)/bin/camoufox"
$ nix run .#camofox-mcp
```

Packages accept all four source-compatible names when selecting a browser:
`CAMOUFOX_EXECUTABLE`, `CAMOUFOX_EXECUTABLE_PATH`, `CAMOFOX_EXECUTABLE`, and
`CAMOFOX_EXECUTABLE_PATH`.

### Install into a profile or system

```console
$ nix profile install github:maximoffua/camoufox-nix#camofox-cli
$ nix profile install github:maximoffua/camoufox-nix#python-camoufox
```

NixOS flake configuration:

```nix
{
  inputs.camoufox-nix.url = "github:maximoffua/camoufox-nix";

  # In configuration.nix or a flake module:
  environment.systemPackages = [ inputs.camoufox-nix.packages.${system}.camofox-cli ];
}
```

### Docker images

Both outputs are `dockerTools.buildLayeredImage` tarballs tagged `latest`.

```console
$ nix build .#docker-camoufox-camofox-mcp
$ docker load < result
$ docker run --rm -i camoufox-camofox-mcp:latest

$ nix build .#docker-vulpineos-foxbridge
$ podman load < result
$ podman run --rm -i vulpineos-foxbridge:latest

# The second image's alternate binary:
$ docker run --rm -i --entrypoint /bin/foxbridge vulpineos-foxbridge:latest --help
```

The first image starts `camofox-mcp`. The second starts `vulpineos`; both set
browser executable environment variables and `HOME=/tmp`.

### Overlay and Python extension

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    camoufox-nix.url = "github:maximoffua/camoufox-nix";
  };

  outputs = { self, nixpkgs, camoufox-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ camoufox-nix.overlays.default ];
      };
    in {
      packages.${system}.default = pkgs.camoufox;
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.python3Packages.camoufox ];
      };
    };
}
```

`inputs.camoufox-nix.overlays.default` adds flake packages to the package set
(excluding `default`) and appends a Python package extension. That extension
provides `pkgs.python3Packages.camoufox`, wired to the overlay's `pkgs.camoufox`
browser. The browser itself remains Linux-only.

## `camoufox-js` note

`camoufox-js` is packaged at `0.11.2`; it is not the old placeholder. The Nix
recipe adds its lockfile, injects `playwright-core`, rebuilds its
`better-sqlite3` native module offline, and uses `--ignore-scripts`. Its wrapper
accepts the executable environment variables above. When a Nix browser path is
provided, `fetch` reports that the browser is managed by Nix instead of
downloading one. The package declares Linux-only support.

`camoufox-mcp-server` is different: it remains an intentional placeholder for
`whit3rabbit/camoufox-mcp` and exits with status 1. Use `camofox-mcp` for the
packaged working Node MCP server, or `camoufox-reverse-mcp` for the Python
reverse-engineering server.

## Linux caveat

The actual Camoufox browser builds, `camoufox-js`, Node browser tools, and
VulpineOS runtime declare Linux platforms. Unix-declared Python and Go outputs
can evaluate or build elsewhere, but browser operation still needs a supported
Camoufox browser. The browser builder supports Linux `x86_64`, `aarch64`, and
`i686` targets in its source.

## Development and verification

```console
$ nix develop
$ nix flake show
$ nix build .#python-camoufox
$ nix build .#jo-camofox-browser
$ nix run .#camofox-cli -- --help
$ nix fmt
$ nix flake check
```

The development shell contains `jj`, `nixfmt-rfc-style`, `nixpkgs-fmt`,
`nodejs`, and `python3`. Formatting uses treefmt with Nix formatter and
deadnix. Flake checks include `python-camoufox`,
`vulpineos-camoufox-notes`, `cloverlabs-camoufox`, `camoufox-browser-cli`, and
`foxbridge`.

## Continuous cache

GitHub Actions builds every named `x86_64-linux` package on pushes to `main`
and manual runs, then pushes built paths to [Cachix `mtech`](https://mtech.cachix.org).
Configure repository Actions secret `CACHIX_AUTH_TOKEN` with a Cachix write token.
Never commit or print this token.

## Repository layout

```text
.
├── flake.nix
└── packages/
    ├── default.nix
    ├── apps.nix
    ├── flake-module.nix
    ├── camoufox/
    ├── camoufox-bin/
    ├── python-camoufox/
    ├── camoufox-js/
    ├── camofox-cli/
    ├── camofox-browser/
    ├── jo-camofox-browser/
    ├── camofox-mcp/
    ├── camoufox-reverse-mcp/
    ├── camoufox-browser-cli/
    ├── cloverlabs-camoufox/
    ├── foxbridge/
    ├── vulpineos/
    └── vulpineos-camoufox-notes/
```

Each package keeps its upstream license metadata. Browser packages use the
Camoufox/Firefox source and MPL-2.0 metadata; individual interfaces declare
their own metadata in package sources.
