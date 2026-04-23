# camoufox-nix

Nix flake for Camoufox and related automation tools. The project keeps the
flake-parts structure and uses standalone package expressions under packages/.
The repo is jj/git-colocated and standalone; seed material was used only during bootstrapping.

## Packages

- camoufox: Linux-only Camoufox browser from daijro/camoufox main, built as a patched Firefox source tree. This is a heavy browser build and the default browser fork.
- camoufox-vulpineos: VulpineOS/VulpineOS Camoufox fork, built with the same reusable package expression and fork-specific patch exclusions.
- camoufox-python: Python camoufox module from PyPI, wrapped to use the Nix browser on Linux.
- camofox-cli: Bin-Huang/camoufox-cli Node CLI from the seed recipe.
- camofox-browser: redf0x1/camofox-browser REST/browser server from the seed recipe.
- camofox-mcp: seed Node MCP package for camofox-mcp.
- camoufox-js: Apify camoufox-js package placeholder pinned to npm package 0.10.2; full dependency packaging still TODO.
- camoufox-mcp-server: whit3rabbit/camoufox-mcp package placeholder pinned to npm package 1.5.0; full dependency packaging still TODO.
- vulpineos-camoufox-notes: small reference package for VulpineOS/VulpineOS tracking.
- cloverlabs-camoufox: CloverLabsAI/camoufox Python interface from PyPI, with GeoIP support enabled.
- camoufox-browser-cli: rlgrpe/camoufox-browser-cli Python browser automation CLI with optional MCP support.
- foxbridge: VulpineOS/foxbridge CDP-to-Firefox protocol proxy for Camoufox-compatible automation.
- vulpineos: VulpineOS browser-agent runtime built from the Go entrypoint on the main branch.
- docker-camoufox-camofox-mcp: minimal Docker image tarball with default Camoufox and camofox-mcp.
- docker-vulpineos-foxbridge: minimal Docker image tarball with VulpineOS, foxbridge, and the VulpineOS Camoufox fork.

## Build and Eval

```bash
nix flake show
nix build .#camoufox-python
nix build .#camofox-cli
nix build .#camofox-browser
nix build .#camoufox
nix build .#camoufox-vulpineos
nix build .#docker-camoufox-camofox-mcp
nix build .#docker-vulpineos-foxbridge
nix build .#cloverlabs-camoufox
nix build .#camoufox-browser-cli
nix build .#foxbridge
nix build .#vulpineos
nix run .#camoufox-python -- --help
nix run .#foxbridge -- --help
nix run .#vulpineos -- --help
nix run .#camoufox-js -- --help
nix run .#camoufox-mcp-server -- --help
nix fmt
```

The full camoufox browser package builds Firefox/Camoufox from source and can take a long time.
Use camoufox-python or the Node tools for fast smoke checks before starting the browser build.
`packages/camoufox/package.nix` accepts a `camoufoxSource` override, so forks can reuse the same browser builder with another source, version, Firefox version, and patch exclusion list.

The flake also exports `overlays.default` for nixpkgs consumers:

```nix
{
  inputs.camoufox-nix.url = "github:OWNER/camoufox-nix";

  outputs = { nixpkgs, camoufox-nix, ... }: {
    packages.x86_64-linux.default =
      let
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = [ camoufox-nix.overlays.default ];
        };
      in
      pkgs.camoufox;
  };
}
```

Docker image outputs build OCI-compatible tarballs. Load them with Docker or Podman:

```bash
nix build .#docker-camoufox-camofox-mcp
docker load < result

nix build .#docker-vulpineos-foxbridge
docker load < result
```

The Camoufox MCP image starts `camofox-mcp` by default and sets `CAMOFOX_EXECUTABLE_PATH` to the Nix-built browser. The VulpineOS image starts `vulpineos` by default; `foxbridge` and `camoufox-vulpineos` are also in the image closure and can be selected with `--entrypoint`.

`camofox-cli` is packaged without forcing a browser build. For real browser automation,
point it at a built browser:

```bash
CAMOFOX_EXECUTABLE_PATH=$(nix build .#camoufox --no-link --print-out-paths)/bin/camoufox \
  nix run .#camofox-cli -- open about:blank
```

camoufox-js and camoufox-mcp-server are intentionally placeholders for now because their Node graphs need separate lock/vendor packaging. The redf0x1 camofox-mcp package is packaged as `.#camofox-mcp`.
