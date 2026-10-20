"""Store screenshots, from headless runs (no window, no GPU needed): python tools/make_screenshots.py [path to factoria]

The engine draws at the design size (1280x720) and has no render-scale option, so the store sizes are the 1280x720
renders enlarged with Lanczos (exactly 1.5x for 1920x1080). Writes store/screenshots/*.png (git-ignored; `export.exclude` in factoria.json keeps store/ out of every export).
"""
import json, os, subprocess, sys
from PIL import Image

FACTORIA = sys.argv[1] if len(sys.argv) > 1 else "factoria"
TMP = ".factoria/tmp"
OUT = "store/screenshots"
# centres of the buttons with the phone-landscape safe area: the buttons move in by its 89 px side insets
RIGHT, JUMP = [244 + 89, 620], [1170 - 89, 610]
os.makedirs(TMP, exist_ok=True)
os.makedirs(OUT, exist_ok=True)


def call(batch):
    r = subprocess.run([FACTORIA, "call", "--batch", json.dumps(batch)], capture_output=True, text=True)
    out = json.loads(r.stdout)
    assert out["ok"], r.stdout
    return out


def shot(name, scene, setup, frames):
    path = f"{TMP}/{name}.png"
    batch = [{"command": "scene.load", "args": {"path": scene}}, {"command": "game.step", "args": {"frames": 20}}]
    batch += setup
    batch += [{"command": "game.step", "args": {"frames": frames}}, {"command": "game.screenshot", "args": {"path": path}}]
    call(batch)
    return path


def sized(src, dst, size):
    Image.open(src).convert("RGB").resize(size, Image.LANCZOS).save(dst, optimize=True)


run = [{"command": "game.input", "args": {"press": ["move_right"]}}]
touch = [
    {"command": "screen.set_safe_area", "args": {"profile": "phone-landscape"}},
    {"command": "game.step", "args": {"frames": 2}},  # the buttons take their places before a finger lands on them
    {"command": "game.input", "args": {"touch": [{"id": 1, "position": RIGHT, "down": True}]}},
]
touch_jump = touch + [{"command": "game.input", "args": {"touch": [{"id": 2, "position": JUMP, "down": True}]}}]

steam = [
    ("01-menu", shot("menu", "scenes/menu.scene.json", [], 5)),
    ("02-courtyard", shot("c1", "scenes/levels/1-1.scene.json", run, 150)),
    ("03-gate", shot("c2", "scenes/levels/1-3.scene.json", run, 200)),
    ("04-cellars", shot("d1", "scenes/levels/2-1.scene.json", run, 160)),
    ("05-lantern-light", shot("d2", "scenes/levels/2-2.scene.json", run, 260)),
    ("06-level-end", "screenshots/level-end.png"),
]
for name, src in steam:
    sized(src, f"{OUT}/steam-1920x1080-{name}.png", (1920, 1080))

phone = [
    ("01-courtyard-touch", shot("p1", "scenes/levels/1-2.scene.json", touch, 100)),
    ("02-cellars-touch", shot("p2", "scenes/levels/2-3.scene.json", touch_jump, 40)),
]
for name, src in phone:
    sized(src, f"{OUT}/phone-landscape-1920x1080-{name}.png", (1920, 1080))
    sized(src, f"{OUT}/phone-landscape-2208x1242-{name}.png", (2208, 1242))
print("ok")
