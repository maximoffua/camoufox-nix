# Project instructions

- Use jj for VCS; this is a colocated jj/git repo.
- Keep flake-parts structure.
- Prefer small Nix packages under `packages/<name>/`.
- Verify with `nix flake show`, `nix build .#<pkg>` where feasible, and `nix fmt`.
- smoke test with `nix run .#<pkg> -- <args...>`
- Source recipe reference copied from `/home/smaximov/gh/llm-agents-camoufox/packages` to `packages.seed/`.
- Communication/report style requested by user: caveman full, concise.
