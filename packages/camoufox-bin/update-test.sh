#!/usr/bin/env bash
# Offline regression: a failed prefetch must not erase a valid version pin.
set -euo pipefail
script=$(realpath "$(dirname "$0")/update.sh")
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir "$work/bin"
cat > "$work/bin/gh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' '{"tagName":"v1.0-beta.1","assets":[{"name":"camoufox-1.0-beta.1-lin.x86_64.zip"},{"name":"camoufox-1.0-beta.1-lin.arm64.zip"}]}'
SH
cat > "$work/bin/nix" <<'SH'
#!/usr/bin/env bash
printf '%s\n' '{"hash":""}'
SH
chmod +x "$work/bin/gh" "$work/bin/nix"
printf '%s\n' '{"release":"keep-me","sources":{}}' > "$work/versions.json"
cp "$work/versions.json" "$work/expected.json"
if PATH="$work/bin:$PATH" CAMOUFOX_BIN_VERSIONS="$work/versions.json" bash "$script" >"$work/log" 2>&1; then
  echo 'FAIL: updater accepted invalid hash' >&2
  exit 1
fi
cmp "$work/expected.json" "$work/versions.json"
echo 'PASS: failed prefetch preserves existing pin'

# A failed write after successful prefetches must preserve the pin too.
cat > "$work/bin/nix" <<'SH'
#!/usr/bin/env bash
printf '%s\n' '{"hash":"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="}'
SH
if {
  (
    ulimit -c 0
    ulimit -f 0
    PATH="$work/bin:$PATH" CAMOUFOX_BIN_VERSIONS="$work/versions.json" bash "$script"
  )
} >/dev/null 2>&1; then
  echo 'FAIL: updater accepted failed write' >&2
  exit 1
fi
cmp "$work/expected.json" "$work/versions.json"
echo 'PASS: failed write preserves existing pin'
