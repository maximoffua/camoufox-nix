#!/usr/bin/env bash
# Smoke test: BrowserOS neo launches, spawns bundled MCP server, listens.
# shortcut: headless + --no-sandbox only; windowed/sandboxed use needs manual review.
set -u
RES=${1:?usage: smoke.sh <browseros-neo wrapper pkg>}
PROFILE=$(mktemp -d)
REAL=$(grep -oE '/nix/store/[^" ]*/libexec/browseros-neo/browseros-neo' "$RES/bin/browseros-neo" | head -1)
"$RES/bin/browseros-neo" --headless=new --no-sandbox --user-data-dir="$PROFILE" --no-first-run about:blank >/dev/null 2>&1 &
BROWSER_PID=$!
sleep 15
fail=0
[ -x "$REAL" ] || { echo "FAIL: browser binary"; fail=1; }
[ -x "$(dirname "$REAL")/BrowserClawServer/default/resources/bin/browseros-claw-server" ] || { echo "FAIL: bundled server"; fail=1; }
pgrep -f "browseros-claw-server.*$(basename "$PROFILE")" >/dev/null && echo "PASS: server process running" || { echo "FAIL: server process"; fail=1; }
[ -f "$PROFILE/.browseros/config.json" ] && echo "PASS: .browseros config" || { echo "FAIL: .browseros config"; fail=1; }
PORT=$(python3 -c "import json;print(json.load(open('$PROFILE/.browseros/config.json'))['ports']['server'])" 2>/dev/null)
[ -n "${PORT:-}" ] && (echo > /dev/tcp/127.0.0.1/"$PORT") 2>/dev/null && echo "PASS: MCP server listening on $PORT" || { echo "FAIL: MCP port"; fail=1; }
kill $BROWSER_PID 2>/dev/null; pkill -f "browseros-claw-server.*$(basename "$PROFILE")" 2>/dev/null
wait $BROWSER_PID 2>/dev/null
rm -rf "$PROFILE"
[ $fail -eq 0 ] && echo "SMOKE: OK" || { echo "SMOKE: FAILED"; exit 1; }
