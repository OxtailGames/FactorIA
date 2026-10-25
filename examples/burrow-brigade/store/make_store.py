#!/usr/bin/env python3
"""Builds everything the store pages need from the game itself (run from anywhere; each step is a sub-command):

  python3 store/make_store.py [--factoria PATH] scenes      the store scenes in store/scenes/ (from scenes/busiest.scene.json)
  python3 store/make_store.py [--factoria PATH] record      plays four floors with four bots and writes store/replays/*.json
  python3 store/make_store.py [--factoria PATH] images      screenshots (1920x1080), key art and Steam/itch capsules
  python3 store/make_store.py [--factoria PATH] trailer     store/trailer.mp4 (needs ffmpeg: FACTORIA_FFMPEG or `factoria setup`)
  python3 store/make_store.py [--factoria PATH] all

The input replays (store/replays/) are what four gamepads would send: stick and button changes per frame, in the format of
`factoria run --input`. They are committed. Screenshots, capsules and the trailer are git-ignored; the key art
(store/keyart.png) is committed because the capsules are cut from it. Without --factoria it uses `factoria` from PATH.
"""
import copy, glob, json, os, shutil, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(HERE)
FACTORIA = "factoria"
TMP = os.path.join(GAME, ".factoria/tmp/store")

# store scene -> (stratum, floor, seed); stratum 0 Topsoil, 1 Crystal Caves, 2 Magma Deep; floor 3 of stratum 2 is the King's
PLAYS = {"topsoil": (0, 1, 2026), "crystal": (1, 2, 31), "magma": (2, 2, 77), "king": (2, 3, 9)}
# (file, scene, replay, frame): looked at one by one; the frames are where something happens (see record.test.js marks)
SHOTS = [
    ("01_crystal_caves", "play_crystal", "crystal", 1000),
    ("02_mole_king", "play_king", "king", 1320),
    ("03_magma_deep", "play_magma", "magma", 200),
    ("04_topsoil", "play_topsoil", "topsoil", 600),
    ("05_the_camp", "camp", None, 39),
    ("06_four_miners_join", "join", "join", 59),
    ("07_light_and_shadow", "play_crystal", "crystal", 300),
    ("08_torches", "play_topsoil", "topsoil", 400),
]
KEYART_LIFT = 250  # pixels of the 1080 high key art
CAPSULES = {"keyArt": "store/keyart.png", "focus": [0.5, 0.3], "logo": {"text": "Burrow Brigade", "fill": "#ffd04d"},
            "stores": ["steam", "itch"], "name": "burrow_brigade"}
# trailer shots: (play scene, replay, frames, [(caption, t0, t1, size)])
TRAILER = [
    ("play_topsoil", "topsoil", 450, [("Four miners. One mine.", 0.6, 6.8, 54)]),
    ("play_crystal", "crystal", 450, [("Light your way, one torch at a time", 0.6, 6.8, 46)]),
    ("play_magma", "magma", 420, [("Dig deeper. Mind the magma.", 0.6, 6.4, 50)]),
    ("play_king", "king", 1500, [("Wake the Mole King", 20.5, 24.5, 54)]),
    ("keyart", None, 300, [("Burrow Brigade", 0.4, 4.6, 100), ("1 to 4 miners, one lamp each", 1.6, 4.6, 36)]),
]


def run(args, **kw):
    return subprocess.run(args, check=True, **kw)


def write(path, data, indent=None):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=indent, separators=None if indent else (",", ":"))


def strip_hud(scene):
    scene["entities"] = [e for e in scene["entities"] if not e["id"].startswith("hud") and e["id"] != "sound_captions"]
    return scene


def step_scenes():
    base = json.load(open(os.path.join(GAME, "scenes/busiest.scene.json")))
    for name, (stratum, floor, seed) in PLAYS.items():
        s = copy.deepcopy(base)
        for e in s["entities"]:
            if e["id"] == "busiest":
                e["components"]["Script"]["props"] = {"stratum": stratum, "floor": floor, "seed": seed, "miners": 4,
                                                      "devices": "pads", "staged": False}
        write(os.path.join(HERE, "scenes", f"play_{name}.scene.json"), s, indent=2)
    write(os.path.join(HERE, "scenes/keyart.scene.json"), strip_hud(copy.deepcopy(base)), indent=2)
    camp = json.load(open(os.path.join(GAME, "scenes/camp.scene.json")))
    ids = [e["id"] for e in camp["entities"]]
    camp["entities"].insert(ids.index("camp_script"),
                            {"id": "store_setup", "components": {"Script": {"path": "store/store_setup.js", "props": {}}}})
    write(os.path.join(HERE, "scenes/camp.scene.json"), camp, indent=2)
    print("store/scenes: written")


def step_record():
    out = run([FACTORIA, "test", "store/record.test.js"], cwd=GAME, capture_output=True, text=True).stdout
    for line in out.splitlines():
        if "@@REPLAY " in line:
            d = json.loads(line.split("@@REPLAY ", 1)[1])
            write(os.path.join(HERE, "replays", d["name"] + ".json"), d["replay"])
            print(f"store/replays/{d['name']}.json: {d['frames']} frames, {d['outcome']}")
    join = {"0": {"gamepad": [{"index": i, "connected": True} for i in range(4)]}}
    for i in range(4):  # the four players press A one after the other
        join[str(10 + 6 * i)] = {"gamepad": [{"index": i, "buttons": {"A": True}}]}
        join[str(13 + 6 * i)] = {"gamepad": [{"index": i, "buttons": {"A": False}}]}
    write(os.path.join(HERE, "replays/join.json"), {"frames": join})


def step_images():
    os.makedirs(TMP, exist_ok=True)
    dest = os.path.join(HERE, "screenshots")
    shutil.rmtree(dest, ignore_errors=True)
    os.makedirs(dest)
    groups = {}
    for name, scene, replay, frame in SHOTS:
        groups.setdefault((scene, replay), []).append((name, frame))
    for (scene, replay), shots in groups.items():
        frames = sorted(f for _, f in shots)
        cmd = [FACTORIA, "run", GAME, "--headless", "--scene", f"store/scenes/{scene}.scene.json" if scene != "join" else "scenes/join.scene.json",
               "--render-scale", "1.5", "--frames", str(frames[-1] + 1), "--screenshot-at", ",".join(map(str, frames)),
               "--screenshot-pattern", os.path.join(TMP, f"{scene}_{{frame}}.png")]
        if replay:
            cmd += ["--input", os.path.join(HERE, "replays", replay + ".json")]
        run(cmd, stdout=subprocess.DEVNULL)
        for name, frame in shots:
            shutil.copy(os.path.join(TMP, f"{scene}_{frame}.png"), os.path.join(dest, name + ".png"))
    # key art: the lit cave of the busiest floor with the HUD hidden (store/scenes/keyart.scene.json)
    run([FACTORIA, "run", GAME, "--headless", "--scene", "store/scenes/keyart.scene.json", "--render-scale", "1.5",
         "--frames", "151", "--screenshot-at", "150", "--screenshot-pattern", os.path.join(TMP, "keyart.png")],
        stdout=subprocess.DEVNULL)
    # the capsules put the title in the middle: lift the lit cave (the screenshot is dark at its edges) so it sits above it
    from PIL import Image
    art = Image.open(os.path.join(TMP, "keyart.png")).convert("RGB")
    lifted = Image.new("RGB", art.size, (0, 0, 0))
    lifted.paste(art, (0, -KEYART_LIFT))
    lifted.save(os.path.join(HERE, "keyart.png"), optimize=True)
    print(f"store/screenshots: {len(SHOTS)} screenshots; store/keyart.png")
    shutil.rmtree(os.path.join(HERE, "capsules"), ignore_errors=True)
    run([FACTORIA, "call", "assets.draw_capsules", json.dumps(CAPSULES)], cwd=GAME, stdout=subprocess.DEVNULL)
    for extra in glob.glob(os.path.join(HERE, "capsules/*/*_1920x1080.png")):
        os.remove(extra)  # screenshot-sized: the stores get the real screenshots
    print("store/capsules:", len(glob.glob(os.path.join(HERE, "capsules/*/*.png"))), "capsules")


def text_entity(eid, text, size, color, y):
    return {"id": eid, "components": {
        "Transform": {"position": [0, y, 0]},
        "Text": {"text": text, "fontSize": size, "color": color, "align": "center", "space": "screen",
                 "anchor": [0.5, 0.5], "pivot": [0.5, 0.5], "layer": 400}}}


def step_trailer():
    scenes_dir = os.path.join(HERE, "trailer/scenes")
    shutil.rmtree(scenes_dir, ignore_errors=True)
    os.makedirs(scenes_dir)
    frames = {"0": {"gamepad": [{"index": i, "connected": True} for i in range(4)]}}
    start, total = 0, sum(t[2] for t in TRAILER)
    for n, (scene, replay, length, caps) in enumerate(TRAILER, 1):
        last = n == len(TRAILER)
        s = json.load(open(os.path.join(HERE, "scenes", scene + ".scene.json")))
        cards = []
        for i, (text, t0, t1, size) in enumerate(caps):
            eid = f"trailer_card_{i}"
            title = size >= 90
            s["entities"].append(text_entity(eid, text, size, [1, 0.8, 0.35, 0] if title else [1, 1, 1, 0],
                                             -30 if title and i == 0 else (-290 if not title else 40)))
            cards.append({"id": eid, "t0": t0, "t1": t1})
        s["entities"].append({"id": "trailer_black", "components": {
            "Transform": {"position": [0, 0, 0]},
            "Shape2D": {"shape": "rectangle", "size": [4000, 2400], "color": [0, 0, 0, 1], "space": "screen",
                        "anchor": [0.5, 0.5], "pivot": [0.5, 0.5], "layer": 500}}})
        s["entities"].append({"id": "trailer", "components": {"Script": {
            "path": "store/trailer/trailer.js",
            "props": {"endFrame": 0 if last else length,
                      "next": "" if last else f"store/trailer/scenes/shot_{n + 1}.scene.json",
                      "cards": cards, "fadeIn": 0.5, "fadeOutFrame": 0 if last else length - 36}}}})
        write(os.path.join(scenes_dir, f"shot_{n}.scene.json"), s, indent=1)
        # sticks and buttons of the previous shot let go, then this floor's recorded input on the global frame counter
        rel = {"gamepad": [{"index": i, "axes": {"LeftX": 0, "LeftY": 0}, "buttons": {"A": False, "B": False}} for i in range(4)]}
        frames.setdefault(str(start + 1), {}).setdefault("gamepad", []).extend(rel["gamepad"])
        if replay:
            for k, v in json.load(open(os.path.join(HERE, "replays", replay + ".json")))["frames"].items():
                g = start + 2 + int(k)
                if int(k) == 0 or g >= start + length:
                    continue
                frames.setdefault(str(g), {}).setdefault("gamepad", []).extend(v.get("gamepad", []))
        start += length
    inp = os.path.join(TMP, "trailer_input.json")
    write(inp, {"frames": frames})
    env = dict(os.environ)
    ff = os.path.expanduser("~/.factoria/tools/ffmpeg")
    if "FACTORIA_FFMPEG" not in env:
        found = glob.glob(os.path.join(ff, "*/ffmpeg*"))
        if found:
            env["FACTORIA_FFMPEG"] = found[0]
    out = os.path.join(HERE, "trailer.mp4")
    run([FACTORIA, "run", GAME, "--headless", "--scene", "store/trailer/scenes/shot_1.scene.json", "--input", inp,
         "--frames", str(total + 2), "--render-scale", "1.5", "--record-video", out], env=env, stdout=subprocess.DEVNULL)
    print(f"store/trailer.mp4: {total} frames ({total / 60:.1f} s)")


def main():
    global FACTORIA
    args = sys.argv[1:]
    if args[:1] == ["--factoria"]:
        FACTORIA = os.path.abspath(args[1])
        args = args[2:]
    steps = {"scenes": step_scenes, "record": step_record, "images": step_images, "trailer": step_trailer}
    todo = list(steps) if args in (["all"], []) else args
    for s in todo:
        steps[s]()


if __name__ == "__main__":
    main()
