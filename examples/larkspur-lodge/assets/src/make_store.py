"""Store page material of Larkspur Lodge, made from the game's own renders (no image tool, no AI picture).

Run it from the project folder with `python3 -I assets/src/make_store.py <step>`; FACTORIA names the factoria binary
(default: the one on PATH). Steps:
    shots    store/screenshots/*.png (1920x1080, the game only, no logo) and store/keyart.png (the same, HUD hidden)
    trailer  .factoria/store/trailer.mp4 (the intro cut-scene played from the title by store/replays/intro.json, 1480
             frames at 1920x1080 with its sound; needs ffmpeg; not committed)
    try      one picture to look at: try <area> <x> <z> <yaw> <hide hud 0|1> -> .factoria/tmp/try.png
Capsules and icons are made from store/keyart.png by assets.draw_capsules and assets.draw_icon (SHIPPING.md has the calls).
"""
import json
import os
import subprocess
import sys

FACTORIA = os.environ.get("FACTORIA", "factoria")

# name -> (area, x, z, porter yaw, camera pitch, camera distance, chapter)
SHOTS = {
    "hall": ("ground", 15.0, 21.6, 135, 30, 6.5, 1),
    "hall2": ("ground", 13.0, 20.0, 200, 24, 6.0, 1),
    "library": ("ground", 5.0, 6.0, 90, 30, 6.0, 1),
    "dining": ("ground", 16.0, 6.0, 60, 30, 6.5, 1),
    "kitchen": ("ground", 27.0, 5.0, 150, 30, 6.5, 1),
    "landing": ("upstairs", 10.0, 16.0, 120, 30, 6.5, 1),
    "cellar": ("cellar", 6.0, 6.0, 45, 32, 6.0, 4),
}


def call(batch):
    out = subprocess.run([FACTORIA, "call", "--batch", json.dumps(batch)], check=True, capture_output=True, text=True).stdout
    return json.loads(out)


def shot(area, x, z, yaw, hide_hud, path, scale=1.5, seconds=4.0, chapter=1, pitch=None, dist=None):
    code = (
        'const p=world.find("porter"); p.position=[%s,0.95,%s]; p.behaviour.faceYaw(%s); '
        'const c=world.find("camera").behaviour; %s %s c.snapBehind(%s); %s 1'
        % (x, z, yaw, "c.pitch=%s;" % pitch if pitch else "", "c.distance=%s;" % dist if dist else "", yaw, 'for (const n of ["hud","screens","hud_items","hud_notebook"]) { const e=world.find(n); if (e) e.active=false; }' if hide_hud else "")
    )
    batch = [
        {"command": "script.eval", "args": {"code": 'session.story = { flags: { chapter: %d, intro_seen: true }, counters: {} }; 1' % chapter}},
        {"command": "scene.load", "args": {"path": "scenes/%s.scene.json" % area}},
        {"command": "game.step", "args": {"frames": 60}},
        {"command": "script.eval", "args": {"code": code}},
        {"command": "game.step", "args": {"frames": int(seconds * 60)}},
        {"command": "game.screenshot", "args": {"path": path, "scale": scale}},
    ]
    return call(batch)


if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "shots"
    if what == "try":
        r = shot(sys.argv[2], float(sys.argv[3]), float(sys.argv[4]), float(sys.argv[5]), sys.argv[6] == "1", ".factoria/tmp/try.png")
        print(json.dumps(r)[:200])
    if what == "trailer":
        os.makedirs(".factoria/store", exist_ok=True)
        subprocess.run([FACTORIA, "run", "--headless", "--input", "store/replays/intro.json", "--frames", "1480",
                        "--render-scale", "1.5", "--record-video", ".factoria/store/trailer.mp4"], check=True)
    if what in ("shots", "survey"):
        scale = 0.4 if what == "survey" else 1.5
        out = ".factoria/tmp/survey" if what == "survey" else "store/screenshots"
        os.makedirs(out, exist_ok=True)
        for name, (area, x, z, yaw, pitch, dist, ch) in SHOTS.items():
            shot(area, x, z, yaw, True, "%s/%s.png" % (out, name), scale=scale, chapter=ch, pitch=pitch, dist=dist)
            print(name)
