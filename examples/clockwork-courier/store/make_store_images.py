#!/usr/bin/env python3
"""Writes the store screenshots and capsules, which are not in git (run from anywhere:
python3 store/make_store_images.py [path/to/factoria]; without a path it uses `factoria` from PATH).

Screenshots: store/screenshots/{phone,tablet,desktop}/NN_<level>.png, recorded headless from the bot input in
store/trailer/replays/ (the input the trailer uses). Capsules: store/capsules/{steam,itch,googleplay}/, cut from
store/keyart.png by assets.draw_capsules. tests/budget.test.js checks their sizes when they are there.
"""
import glob, json, os, shutil, subprocess, sys

GAME = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FACTORIA = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else "factoria"
SETTLE = 10  # frames the level scenes settle before the recorded input starts (as in store/trailer/make_trailer.py)

# (file name, level, frame of the recorded run)
SHOTS = [
    ("01_rooftops_1", "rooftops_1", 800),
    ("02_rooftops_3", "rooftops_3", 650),
    ("03_market_2", "market_2", 650),
    ("04_market_2", "market_2", 2150),
    ("05_rooftops_1", "rooftops_1", 1350),
]
# form: window size, render scale (the PNG is size x scale) and whether a finger shows the on-screen controls
FORMS = {
    "phone": (1434, 660, 2, True),      # 2868x1320
    "tablet": (1376, 1032, 2, True),    # 2752x2064
    "desktop": (1280, 720, 1.5, False),  # 1920x1080
}
CAPSULES = {"keyArt": "store/keyart.png", "focus": [0.5, 0.5], "logo": {"text": "Clockwork Courier", "fill": "#ffd04d"},
            "stores": ["steam", "itch", "googleplay"], "name": "clockwork_courier"}


def replay(level, touch, out):
    frames = {str(int(k) + SETTLE): v
              for k, v in json.load(open(os.path.join(GAME, "store/trailer/replays", level + ".json")))["frames"].items()}
    if touch:  # a finger touches the free screen for a moment, then lifts: the on-screen controls appear
        frames.setdefault("3", {})["touch"] = {"id": 1, "position": [900, 360], "down": True}
        frames.setdefault("5", {})["touch"] = {"id": 1, "position": [900, 360], "down": False}
    json.dump({"frames": frames}, open(out, "w"), separators=(",", ":"))


def main():
    tmp = os.path.join(GAME, ".factoria/tmp/store_images")
    os.makedirs(tmp, exist_ok=True)
    for form, (w, h, scale, touch) in FORMS.items():
        dest = os.path.join(GAME, "store/screenshots", form)
        os.makedirs(dest, exist_ok=True)
        for level in sorted({s[1] for s in SHOTS}):
            at = sorted(f for _, l, f in SHOTS if l == level)
            replay(level, touch, os.path.join(tmp, level + ".json"))
            subprocess.run([FACTORIA, "run", GAME, "--headless", "--scene", f"scenes/{level}.scene.json",
                            "--width", str(w), "--height", str(h), "--render-scale", str(scale),
                            "--input", os.path.join(tmp, level + ".json"), "--frames", str(at[-1] + 2),
                            "--screenshot-at", ",".join(map(str, at)),
                            "--screenshot-pattern", os.path.join(tmp, f"{form}_{level}_{{frame}}.png")],
                           check=True, stdout=subprocess.DEVNULL)
        for name, level, frame in SHOTS:
            shutil.copy(os.path.join(tmp, f"{form}_{level}_{frame}.png"), os.path.join(dest, name + ".png"))
        print(f"store/screenshots/{form}: {len(SHOTS)} screenshots")

    shutil.rmtree(os.path.join(GAME, "store/capsules"), ignore_errors=True)
    subprocess.run([FACTORIA, "call", "assets.draw_capsules", json.dumps(CAPSULES)], cwd=GAME, check=True,
                   stdout=subprocess.DEVNULL)
    for extra in glob.glob(os.path.join(GAME, "store/capsules/*/*_1920x1080.png")):
        os.remove(extra)  # the screenshot-sized images: the stores get the real screenshots above
    print("store/capsules:", len(glob.glob(os.path.join(GAME, "store/capsules/*/*.png"))), "capsules")


if __name__ == "__main__":
    main()
