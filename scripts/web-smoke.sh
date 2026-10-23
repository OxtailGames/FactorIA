#!/usr/bin/env bash
# Web export smoke test (the `web` job of ci.yml and ci-local.sh): makes a game from a template, exports it with
# `factoria export --platform web`, checks the zip as itch.io takes it (index.html at the root, at most 1000 files, 500 MB)
# and opens the export in headless Chrome until the player has rendered its first frames (platforms/web/smoke.mjs). The game
# gets a TextField and a script that logs what it holds; the smoke then types "hello" into the page with real key events and
# waits for that log line: the web player takes typed text from the keypress events of the window (docs/TEXT.md).
#
#   scripts/web-smoke.sh <factoria> <web player folder> [work dir (default build/web-smoke)]
#
# Needs Node 22+, Chrome/Chromium (or CHROME_BIN) and python3. Exit code 0 = the game ran.
set -euo pipefail

factoria="${1:?usage: web-smoke.sh <factoria> <web player folder> [work dir]}"
player="${2:?usage: web-smoke.sh <factoria> <web player folder> [work dir]}"
work="${3:-build/web-smoke}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

rm -rf "$work"; mkdir -p "$work"
"$factoria" new "$work/game" --template 2d-platformer --name "Web Smoke"

# A name field with the focus, and a script that logs every edit: "smoke text: <what the field holds>".
cat > "$work/game/scripts/smoke_text.js" <<'JS'
import { Behaviour, ui } from "factoria";

export default class SmokeText extends Behaviour {
  onStart() {
    ui.on("change", "smoke_name", (e) => console.log("smoke text: " + e.value));
  }
}
JS
python3 - "$work/game/scenes/main.scene.json" <<'PY'
import json, sys
path = sys.argv[1]
scene = json.load(open(path))
scene["entities"].append({"id": "smoke_name", "components": {
    "TextField": {"size": [300, 48], "anchor": [0.5, 0.0], "pivot": [0.5, 0.0], "layer": 500, "autoFocus": True},
    "Script": {"path": "scripts/smoke_text.js"}}})
json.dump(scene, open(path, "w"), indent=2)
PY
"$factoria" export "$work/game" --platform web --player "$player" --out "$work/export"

dir="$(find "$work/export" -maxdepth 1 -type d -name '*-web' | head -n 1)"
zip="$(find "$work/export" -maxdepth 1 -type f -name '*-web.zip' | head -n 1)"
test -n "$dir" && test -n "$zip" || { echo "FAIL: the export has no <slug>-web folder and zip"; exit 1; }

python3 - "$zip" <<'PY'
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
names = z.namelist()
size = sum(i.file_size for i in z.infolist())
print(f"zip: {len(names)} files, {size / 1e6:.1f} MB unpacked")
assert "index.html" in names, "index.html is not at the root of the zip"
assert len(names) <= 1000, "itch.io takes at most 1000 files"
assert size <= 500 * 1000 * 1000, "itch.io takes at most 500 MB"
assert z.testzip() is None, "the zip is corrupt"
PY

node "$here/platforms/web/smoke.mjs" "$dir" --timeout 90 --screenshot "$work/web-smoke.png" \
    --type hello --expect "smoke text: "
