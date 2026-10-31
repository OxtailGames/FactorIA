#!/usr/bin/env python3
"""Writes the key art, the store screenshots and the capsules (run from anywhere:
python3 store/make_store_images.py [path/to/factoria]; without a path it uses `factoria` from PATH).

Everything comes from the game's own renders, nothing is drawn by hand:
- store/keyart.png (1920x1080, in git): the game scene with the scene props `grow` (a bot plays that many days before the
  first frame), `zoom`, `photo` (no interface).
- store/screenshots/*.png (1920x1080, not in git): the game and title scenes at --render-scale 1.5, with an input replay
  for the overlay and the order board.
- store/capsules/{steam,itch}/ (not in git): cut from keyart.png by assets.draw_capsules.
tests/store_assets.test.js checks their sizes when they are there.
"""
import glob, json, os, shutil, subprocess, sys

GAME = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FACTORIA = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else "factoria"
TMP = os.path.join(GAME, ".factoria/tmp/store_images")

# (file, scene, props, frame to shoot, input frames {frame: event})
SHOTS = [
    ("01_title", "scenes/menu.scene.json", {}, 90, {}),
    ("02_first_harbour", "scenes/game.scene.json", {"grow": 14, "music": False, "zoom": 1.15}, 40, {}),
    ("03_growing_town", "scenes/game.scene.json", {"grow": 45, "music": False, "zoom": 0.85}, 90, {}),
    ("04_busy_town", "scenes/game.scene.json", {"grow": 100, "music": False, "zoom": 0.75}, 150, {}),
    ("05_overlay", "scenes/game.scene.json", {"grow": 60, "music": False, "zoom": 0.8}, 110,
     {"80": {"press": ["overlay"]}, "82": {"release": ["overlay"]}}),
    ("06_goods", "scenes/game.scene.json", {"grow": 60, "music": False, "zoom": 0.8}, 120,
     {"80": {"press": ["goods_table"]}, "82": {"release": ["goods_table"]}}),
]
KEYART = {"scene": "scenes/game.scene.json", "props": {"grow": 100, "music": False, "zoom": 0.85, "photo": True}, "frame": 150}
CAPSULES = {"keyArt": "store/keyart.png", "focus": [0.5, 0.55],
            "logo": {"text": "Tidewater Market", "fill": "#ffe9a8", "outline": "#1c3f57"},
            "stores": ["steam", "itch"], "name": "tidewater_market"}


def run(scene, props, frame, out, inp=None, scale=1.5):
    os.makedirs(TMP, exist_ok=True)
    cmd = [FACTORIA, "run", GAME, "--headless", "--scene", scene, "--width", "1280", "--height", "720",
           "--render-scale", str(scale), "--frames", str(frame + 2), "--screenshot-at", str(frame),
           "--screenshot-pattern", os.path.join(TMP, "shot_{frame}.png")]
    if props:
        cmd += ["--props", json.dumps(props)]
    if inp:
        p = os.path.join(TMP, "input.json")
        json.dump({"frames": inp}, open(p, "w"))
        cmd += ["--input", p]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, cwd=GAME)
    shutil.move(os.path.join(TMP, f"shot_{frame}.png"), out)


def main():
    run(KEYART["scene"], KEYART["props"], KEYART["frame"], os.path.join(GAME, "store/keyart.png"))
    print("store/keyart.png")
    dest = os.path.join(GAME, "store/screenshots")
    shutil.rmtree(dest, ignore_errors=True)
    os.makedirs(dest)
    for name, scene, props, frame, inp in SHOTS:
        run(scene, props, frame, os.path.join(dest, name + ".png"), inp)
    print(f"store/screenshots: {len(SHOTS)} screenshots")
    shutil.rmtree(os.path.join(GAME, "store/capsules"), ignore_errors=True)
    subprocess.run([FACTORIA, "call", "assets.draw_capsules", json.dumps(CAPSULES)], cwd=GAME, check=True,
                   stdout=subprocess.DEVNULL)
    for extra in glob.glob(os.path.join(GAME, "store/capsules/*/*_1920x1080.png")):
        os.remove(extra)  # the screenshot-sized images: the stores get the real screenshots
    print("store/capsules:", len(glob.glob(os.path.join(GAME, "store/capsules/*/*.png"))), "capsules")


if __name__ == "__main__":
    main()
