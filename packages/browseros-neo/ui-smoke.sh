#!/usr/bin/env bash
# Requires agent-browser and python3; isolated headless profile, never user data.
set -euo pipefail
package=${1:?usage: ui-smoke.sh <browseros-neo package>}
# Fail before creating a profile if launcher blocks normal user extensions.
if grep -q -- '--disable-extensions-except' "$package/bin/browseros-neo"; then
  echo 'FAIL: launcher restricts user extensions' >&2
  exit 1
fi
profile=$(mktemp -d)
session="neo-smoke-$$"
port=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1])')
cleanup() {
  agent-browser --session "$session" close >/dev/null 2>&1 || true
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  pkill -f "browseros-claw-server.*$profile" 2>/dev/null || true
  rm -rf "$profile"
}
"$package/bin/browseros-neo" --headless=new --no-sandbox \
  --remote-debugging-port="$port" --user-data-dir="$profile" \
  --host-resolver-rules='MAP * ~NOTFOUND,EXCLUDE localhost' \
  --no-first-run chrome://browseros/claw >"$profile/browser.log" 2>&1 &
pid=$!
trap cleanup EXIT
for _ in {1..30}; do
  if agent-browser --session "$session" --cdp "http://127.0.0.1:$port" get url >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
agent-browser --session "$session" open chrome://browseros/claw >/dev/null
url=$(agent-browser --session "$session" get url)
[[ "$url" == 'chrome-extension://pjimfkbpehlcllblajnpfamdfjhhlgkc/newtab.html' ]]
agent-browser --session "$session" snapshot -i | grep -q '"Cockpit"'
echo 'PASS: dashboard renders bundled extension UI without network'
agent-browser --session "$session" open chrome://extensions >/dev/null
agent-browser --session "$session" eval 'new Promise(resolve => chrome.developerPrivate.getExtensionsInfo({includeDisabled: true, includeTerminated: true}, items => resolve(items.some(e => e.id === "pjimfkbpehlcllblajnpfamdfjhhlgkc" && e.state === "ENABLED" && e.path.startsWith("/nix/store/")))))' | grep -qx true
echo 'PASS: enabled dashboard extension comes from Nix store'
echo 'PASS: launcher does not restrict user extensions'
