# 🦊 camoufox-nix

> Nix flake for [Camoufox](https://github.com/daijro/camoufox) — the anti-detect Firefox fork — and its automation ecosystem (CLIs, MCP servers, Python/Node SDKs, a CDP bridge, a Go agent runtime, and Docker images).

Built on `flake-parts`. Every package has its own folder under `packages/`, so forks and overrides are cheap. Repo is `jj`/git colocated.

> **Heads up for agents and automations:** this README is the contract. Each package below has a one-line purpose, a copy-paste `nix run` / `nix build` command, and the env vars that matter. If something is marked `placeholder`, it really is one — it exits non-zero on purpose. Don't pipe its output anywhere.

---

## 🚀 Quick start

```bash
# Show everything the flake exposes
nix flake show

# Smoke test the default app (python-camoufox)
nix run . -- --help

# Build the heavy one (full Firefox source build, takes a while)
nix build .#camoufox

# Drop into a dev shell with jj, formatters, node, python
nix develop
```

Need something fast? `nix run .#camoufox-python -- --help` finishes in seconds and pulls in the full Python SDK without compiling the browser.

---

## 📦 Packages at a glance

| Package | What it is | Build cost | Runs on |
|---|---|---|---|
| `camoufox` | Patched Firefox source build (daijro/camoufox) — the actual browser | 🔥 heavy | linux only |
| `camoufox-vulpineos` | Same builder, VulpineOS fork source | 🔥 heavy | linux only |
| `python-camoufox` *(default)* | Python SDK from PyPI, wired to the Nix browser | ⚡ fast | all |
| `cloverlabs-camoufox` | CloverLabsAI Python interface, GeoIP enabled | ⚡ fast | all |
| `camoufox-browser-cli` | Python CLI wrapper around cloverlabs-camoufox, optional MCP | ⚡ fast | all |
| `camofox-cli` | Bin-Huang Node CLI for Camoufox | ⚡ fast | all |
| `camofox-browser` | redf0x1 Node REST/browser server | ⚡ fast | all |
| `jo-camofox-browser` | jo-inc Node REST/browser server with OpenAPI docs and plugins | ⚡ fast | all |
| `camofox-mcp` | redf0x1 Node MCP server (working) | ⚡ fast | all |
| `camoufox-js` | ⚠️ placeholder (Apify, npm graph not vendored) | — | — |
| `camoufox-mcp-server` | ⚠️ placeholder (whit3rabbit, npm graph not vendored) | — | — |
| `foxbridge` | Go CDP-to-Firefox protocol proxy | ⚡ fast | all |
| `vulpineos` | Go browser-agent runtime | ⚡ fast | all |
| `vulpineos-camoufox-notes` | Reference note package, just docs | ⚡ trivial | all |
| `docker-camoufox-camofox-mcp` | OCI image: Camoufox + camofox-mcp | medium | all |
| `docker-vulpineos-foxbridge` | OCI image: VulpineOS + foxbridge + VulpineOS Camoufox | medium | all |

Default output (`nix run .` / `nix build .`) is **`python-camoufox`** — the cheapest sensible thing to test against.

---

## 📚 Per-package usage

### 🦊 `camoufox` — the browser

Patched Firefox source tree from [daijro/camoufox](https://github.com/daijro/camoufox). This is what every other "browser" package in this flake actually launches.

```bash
nix build .#camoufox
nix run .#camoufox -- --version
./result/bin/camoufox https://example.com
```

⚠️ **Linux only**, and the build is genuinely slow (full Firefox compile). For agents and CI: cache the output, point `CAMOUFOX_EXECUTABLE_PATH` at it, and reuse it across packages.

```bash
export CAMOUFOX_EXECUTABLE_PATH=$(nix build .#camoufox --no-link --print-out-paths)/bin/camoufox
```

The builder (`packages/camoufox/package.nix`) takes a `camoufoxSource` override — see `camoufox-vulpineos` for an example.

---

### 🐺 `camoufox-vulpineos` — VulpineOS fork of the browser

Same builder, swapped source. `excludedPatchFiles` skips `action-lock.patch` and `disable-remote-subframes.patch` because the fork already carries equivalents. Used by the VulpineOS Docker image.

```bash
nix build .#camoufox-vulpineos
nix run .#camoufox-vulpineos -- --version
```

Want your own fork? Override the source the same way `packages/default.nix` does — full example in the [Building your own fork](#-building-your-own-camoufox-fork) section below.

---

### 🐍 `python-camoufox` — Python SDK *(default app)*

PyPI [`camoufox`](https://pypi.org/project/camoufox/) wrapped so it picks up the Nix-built browser on Linux. This is the flake's default.

```bash
nix run .#camoufox-python -- --help
nix run .#camoufox-python -- fetch        # fetches the bundled browser blob (skipped on Nix linux)
```

Use it as a Python lib via `nix develop` or `nix shell .#python-camoufox`, then `import camoufox`.

---

### 🍀 `cloverlabs-camoufox` — Python interface (GeoIP-on)

[CloverLabsAI/camoufox](https://github.com/CloverLabsAI/camoufox) Python module. Built with `withGeoip = true` by default — useful when your automation wants location/timezone spoofing wired up.

```bash
nix build .#cloverlabs-camoufox
# library only — no executable. Use it from a Python session:
nix shell .#cloverlabs-camoufox -c python -c "import camoufox; print(camoufox.__file__)"
```

---

### 🛠️ `camoufox-browser-cli` — Python CLI

[rlgrpe/camoufox-browser-cli](https://github.com/rlgrpe/camoufox-browser-cli). Click-based browser automation CLI built on top of `cloverlabs-camoufox`. MCP support is enabled (`withMcp = true`).

```bash
nix run .#camoufox-browser-cli -- --help
```

Set `CAMOUFOX_EXECUTABLE_PATH` if you want it to use a specific Nix-built browser.

---

### 🟢 `camofox-cli` — Node CLI

[Bin-Huang/camoufox-cli](https://github.com/Bin-Huang/camoufox-cli). Packaged without forcing the heavy browser build. For real automation, point it at the Nix browser:

```bash
CAMOFOX_EXECUTABLE_PATH=$(nix build .#camoufox --no-link --print-out-paths)/bin/camoufox \
  nix run .#camofox-cli -- open about:blank
```

---

### 🟢 `camofox-browser` — Node REST / browser server

[redf0x1/camofox-browser](https://github.com/redf0x1/camofox-browser). Anti-detection browser server intended to back AI agents.

```bash
nix run .#camofox-browser -- --help
```

Same env-var pattern as `camofox-cli`: set `CAMOFOX_EXECUTABLE_PATH` (or `CAMOUFOX_EXECUTABLE_PATH`) to the Nix browser when you want a Nix-clean closure.

---

### 🟢 `jo-camofox-browser` — jo-inc Node REST / browser server

[jo-inc/camofox-browser](https://github.com/jo-inc/camofox-browser). Agent-focused browser server with OpenAPI docs, plugin support, tracing, cookie import, and optional auth. This is packaged separately from `camofox-browser` because that existing output tracks `redf0x1/camofox-browser`.

```bash
CAMOFOX_PORT=9377 nix run .#jo-camofox-browser

# In another shell:
curl http://localhost:9377/health
curl http://localhost:9377/openapi.json
```

The wrapper adds `Xvfb` to `PATH`, because upstream starts a virtual display on Linux. It does **not** bake the heavy Nix `camoufox` build into the runtime closure; set browser path explicitly when you want to launch real sessions:

```bash
export CAMOUFOX_EXECUTABLE_PATH=$(nix build .#camoufox --no-link --print-out-paths)/bin/camoufox
CAMOFOX_PORT=9377 nix run .#jo-camofox-browser
```

The wrapper also accepts upstream's shorter `CAMOFOX_EXECUTABLE_PATH` spelling, so either env var works.

Useful env vars: `CAMOFOX_PORT` / `PORT` for the server port, `CAMOFOX_ACCESS_KEY` for bearer auth, `CAMOFOX_API_KEY` for cookie import, and `CAMOFOX_ADMIN_KEY` for `/stop`.

---

### 🤖 `camofox-mcp` — MCP server (real, working)

[redf0x1/camofox-mcp](https://github.com/redf0x1/camofox-mcp) — Model Context Protocol server for anti-detection browsing.

```bash
CAMOFOX_EXECUTABLE_PATH=$(nix build .#camoufox --no-link --print-out-paths)/bin/camoufox \
  nix run .#camofox-mcp
```

This is the package the `docker-camoufox-camofox-mcp` image runs as its entrypoint. Wiring up an agent (Claude Code, Codex, OpenCode, Cursor, etc.) over MCP? **This is the one.** Not `camoufox-mcp-server`.

---

### ⚠️ `camoufox-js` — placeholder

[apify/camoufox-js](https://github.com/apify/camoufox-js), pinned to `camoufox-js@0.10.2`. The npm graph isn't vendored yet, so the binary just prints a `TODO` notice and exits with code 1.

```bash
nix run .#camoufox-js -- --help   # exits 1, prints upstream pointer
```

For real work, use `python-camoufox` or the `camofox-*` family.

---

### ⚠️ `camoufox-mcp-server` — placeholder

[whit3rabbit/camoufox-mcp](https://github.com/whit3rabbit/camoufox-mcp), pinned to `camoufox-mcp-server@1.5.0`. Same status as `camoufox-js` — placeholder, exits 1. **For a working MCP server, use `.#camofox-mcp`.**

---

### 🌉 `foxbridge` — CDP↔Firefox protocol bridge

[VulpineOS/foxbridge](https://github.com/VulpineOS/foxbridge). Go binary that bridges Juggler/BiDi to CDP, so anything that speaks Chrome DevTools Protocol can drive Camoufox.

```bash
nix run .#foxbridge -- --help
```

Common pattern: launch Camoufox, run `foxbridge` next to it, point your CDP client at `foxbridge`'s port.

---

### 🐺 `vulpineos` — browser-agent runtime

[VulpineOS/VulpineOS](https://github.com/VulpineOS/VulpineOS) main-branch Go entrypoint (`cmd/vulpineos`). Stealth-aware AI browser-agent runtime.

```bash
nix run .#vulpineos -- --help
```

Default entrypoint of the `docker-vulpineos-foxbridge` image.

---

### 📝 `vulpineos-camoufox-notes` — docs only

Tiny derivation that installs a reference README under `share/doc/vulpineos-camoufox/`. Pure note-tracking, no binaries.

---

### 🐳 `docker-camoufox-camofox-mcp` — OCI image

Layered image with `camoufox` + `camofox-mcp`. Entrypoint is `camofox-mcp`, `CAMOFOX_EXECUTABLE_PATH` is pre-wired to the Nix browser. CA bundle and `/tmp` set up; `HOME=/tmp`.

```bash
nix build .#docker-camoufox-camofox-mcp
docker load < result   # or: podman load < result
docker run --rm -i camoufox-camofox-mcp:latest
```

---

### 🐳 `docker-vulpineos-foxbridge` — OCI image

Layered image with `vulpineos` (entrypoint) + `foxbridge` + `camoufox-vulpineos`. Switch entrypoint with `--entrypoint` if you want `foxbridge` or the browser directly.

```bash
nix build .#docker-vulpineos-foxbridge
docker load < result
docker run --rm -i vulpineos-foxbridge:latest

# Run foxbridge instead:
docker run --rm -i --entrypoint /bin/foxbridge vulpineos-foxbridge:latest --help
```

---

## 🔌 Use as an overlay

For consumers who want these packages in an existing nixpkgs scope:

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

The overlay exports every package except `default`.

---

## 🏗️ Building your own Camoufox fork

`packages/camoufox/package.nix` accepts a `camoufoxSource` arg with `owner`, `repo`, `rev`, `hash`, `version`, `firefoxVersion`, `displayVersion`, `homepage`, `sourceName`, and `excludedPatchFiles`. The VulpineOS variant in `packages/default.nix` is the canonical example.

```nix
camoufox-myfork = camoufox.override {
  camoufoxSource = {
    owner = "me";
    repo = "my-camoufox";
    rev = "abcd...";
    hash = "sha256-...";
    version = "0-unstable-YYYY-MM-DD";
    firefoxVersion = "146.0.1";
    displayVersion = "146.0.1-myfork.1";
    homepage = "https://github.com/me/my-camoufox";
    sourceName = "me/my-camoufox";
    excludedPatchFiles = [ ];   # patches to skip from upstream
  };
};
```

---

## 🧪 Verifying a change

```bash
nix flake show                          # outputs sanity check
nix build .#python-camoufox             # cheap default
nix build .#jo-camofox-browser          # jo-inc REST/browser server
nix build .#foxbridge .#vulpineos       # Go ones, fast
nix build .#camoufox                    # heavy, only when needed
nix run .#camofox-cli -- --help         # smoke test
nix fmt                                 # treefmt: nixfmt + deadnix
nix flake check                         # runs the checks defined in the flake
```

Exposed `checks`: `python-camoufox`, `cloverlabs-camoufox`, `camoufox-browser-cli`, `foxbridge`, `vulpineos-camoufox-notes`, `treefmt`.

---

## 🧰 Dev shell

```bash
nix develop
```

Drops you into a shell with `jj`, `nixfmt-rfc-style`, `nixpkgs-fmt`, `nodejs`, `python3`. Repo is `jj`/git colocated, so use either freely.

---

## 🤖 For automations & agents — TL;DR

- **Default smoke check:** `nix run . -- --help` (this is `python-camoufox`).
- **Need an actual browser binary path:** `nix build .#camoufox --no-link --print-out-paths` and append `/bin/camoufox`. Linux only.
- **Need an MCP server:** use `.#camofox-mcp`. **Not** `.#camoufox-mcp-server` — that one is a placeholder.
- **Need a Node CLI:** `.#camofox-cli`.
- **Need jo-inc REST/OpenAPI browser server:** `.#jo-camofox-browser`.
- **Need a CDP client to drive Camoufox:** `.#foxbridge`.
- **Need a containerized stack:** the two `docker-*` outputs build OCI tarballs, `docker load`-ready.
- **Don't pipe output of:** `.#camoufox-js`, `.#camoufox-mcp-server` — they exit non-zero by design.
- **Env vars to know:** `CAMOFOX_EXECUTABLE_PATH`, `CAMOUFOX_EXECUTABLE_PATH` (different upstreams spell it differently — set both if unsure).

---

## 📂 Repo layout

```
.
├── flake.nix                # flake entrypoint, docker images, devShell, treefmt
├── packages/
│   ├── default.nix          # wires every package together
│   ├── apps.nix             # nix run targets
│   ├── flake-module.nix     # flake-parts module + overlay export
│   ├── camoufox/            # the browser source build
│   ├── camofox-cli/
│   ├── camofox-browser/
│   ├── jo-camofox-browser/
│   ├── camofox-mcp/
│   ├── camoufox-browser-cli/
│   ├── cloverlabs-camoufox/
│   ├── python-camoufox/
│   ├── foxbridge/
│   ├── vulpineos/
│   └── vulpineos-camoufox-notes/
└── AGENTS.md                # repo-level instructions for AI agents
```

`camoufox-vulpineos`, `camoufox-js` and `camoufox-mcp-server` don't have their own folders — they're produced by override / `writeShellApplication` directly in `packages/default.nix`.

---

## 📜 License & upstream

Each package keeps its upstream's license. Browser builds inherit Camoufox / Firefox terms. Linux is the only supported platform for the actual browser package; Python and Node packages eval on every system but only do useful work where the browser does.

PRs welcome — keep packages small, one folder per upstream, run `nix fmt` before committing.
