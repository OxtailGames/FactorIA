#!/usr/bin/env python3
"""Builds the trailer's scenes and its input replay (run from the game folder: python3 store/trailer/make_trailer.py).

Writes store/trailer/scenes/shot_N.scene.json (a level scene + the trailer director + captions + a black cover) and
.factoria/tmp/trailer_input.json (the recorded bot input of every level, cut to the length of its shot and laid out on one
global frame counter). The run that records the video is in SHIPPING.md ("Trailer").
"""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(os.path.dirname(HERE))
FPS = 60
SETTLE = 10          # frames the level scenes settle before the recorded input starts (see replays/)
DELTA = int(os.environ.get("TRAILER_DELTA", "1"))  # frames between scene.load and the first frame of the next scene

GOLD = [1, 0.8, 0.35, 0]
WHITE = [1, 1, 1, 0]

# (level, seconds, camera pitch keys, camera distance keys, captions [(text, t0, t1, size, kind)])
SHOTS = [
    ("rooftops_1", 7.5,
     [[0, 8], [3.2, 12], [5, 24], [7.5, 22]], [[0, 3.6], [3.2, 4.5], [5, 6.5], [7.5, 6]],
     [("Clockwork Courier", 0.5, 3.2, 110, "title"), ("A tiny robot. A big city. One spring.", 3.4, 7.2, 40, "sub")]),
    ("rooftops_3", 10.0,
     [[0, 20], [4, 34], [8, 18], [10, 20]], [[0, 6], [4, 8.5], [8, 5], [10, 6]],
     [("Race across the rooftops", 0.8, 4.6, 52, "sub"), ("Rope bridges, see-saws and wind keys", 5.2, 9.6, 40, "sub")]),
    ("market_1", 8.0,
     [[0, 14], [4, 26], [8, 20]], [[0, 4.5], [4, 7], [8, 6]],
     [("Then dive into the night market", 0.6, 4.4, 52, "sub")]),
    ("rooftops_2", 9.0,
     [[0, 22], [4.5, 12], [9, 28]], [[0, 6], [4.5, 4], [9, 8]],
     [("Mind the guard dogs", 0.6, 4.6, 52, "sub"), ("Shake them off. Keep winding.", 5, 8.6, 40, "sub")]),
    ("market_3", 9.0,
     [[0, 22], [3, 16], [6, 28], [9, 22]], [[0, 6], [3, 4.2], [6, 7.5], [9, 6]],
     [("Six levels. 18 stars. Every shortcut.", 0.6, 5.0, 46, "sub"), ("Clockwork Courier", 5.4, 9.0, 100, "title")]),
]


def text_entity(eid, text, size, color, y):
    return {"id": eid, "components": {
        "Transform": {"position": [0, y, 0]},
        "Text": {"text": text, "fontSize": size, "color": color, "align": "center", "space": "screen",
                 "anchor": [0.5, 0.5], "pivot": [0.5, 0.5], "layer": 400}}}


def main():
    scenes_dir = os.path.join(HERE, "scenes")
    os.makedirs(scenes_dir, exist_ok=True)
    start = 0
    frames = {}
    lengths = []
    for n, (level, secs, pk, dk, caps) in enumerate(SHOTS, 1):
        length = int(round(secs * FPS))
        end = start + length
        last = n == len(SHOTS)
        scene = json.load(open(os.path.join(GAME, "scenes", f"{level}.scene.json")))
        cards = []
        for i, (text, t0, t1, size, kind) in enumerate(caps):
            eid = f"trailer_card_{i}"
            y = -40 if kind == "title" else 300
            col = GOLD if kind == "title" else WHITE
            scene["entities"].append(text_entity(eid, text, size, col, y))
            cards.append({"id": eid, "t0": t0, "t1": t1})
        scene["entities"].append({"id": "trailer_black", "components": {
            "Transform": {"position": [0, 0, 0]},
            "Shape2D": {"shape": "rectangle", "size": [4000, 2400], "color": [0, 0, 0, 1], "space": "screen",
                        "anchor": [0.5, 0.5], "pivot": [0.5, 0.5], "layer": 500}}})
        scene["entities"].append({"id": "trailer", "components": {"Script": {
            "path": "store/trailer/trailer.js",
            "props": {
                "endFrame": 0 if last else length,
                "next": "" if last else f"store/trailer/scenes/shot_{n + 1}.scene.json",
                "pitchKeys": pk, "distanceKeys": dk, "cards": cards,
                "fadeIn": 0.5, "fadeOutFrame": length - 36, "fadeOutSeconds": 0.55}}}})
        json.dump(scene, open(os.path.join(scenes_dir, f"shot_{n}.scene.json"), "w"), indent=1)
        # the bot's input of that level, cut to the shot
        rep = json.load(open(os.path.join(HERE, "replays", f"{level}.json")))["frames"]
        pressed, axes = set(), set()
        for k in sorted(rep, key=int):
            g = start + SETTLE + int(k)
            if g >= end:
                break
            ev = rep[k]
            for a in ev.get("press", []):
                pressed.add(a)
            for a in ev.get("release", []):
                pressed.discard(a)
            for a in ev.get("gamepad", {}).get("axes", {}):
                axes.add(a)
            frames.setdefault(str(g), {}).update(ev)
        # let go of everything at the cut
        cut = frames.setdefault(str(end - 1), {})
        if pressed:
            cut.setdefault("release", []).extend(sorted(pressed))
        if axes:
            cut["gamepad"] = {"axes": {a: 0 for a in axes}}
        lengths.append((level, start, end))
        start = end + DELTA
    out = os.path.join(GAME, ".factoria", "tmp", "trailer_input.json")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    json.dump({"frames": frames}, open(out, "w"), separators=(",", ":"))
    total = lengths[-1][2] + 1
    print("shots:", lengths)
    print("total frames:", total, "=", round(total / FPS, 1), "s")


if __name__ == "__main__":
    main()
