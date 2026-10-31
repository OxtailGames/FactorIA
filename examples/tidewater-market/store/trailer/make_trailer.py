#!/usr/bin/env python3
"""Writes the trailer's scene (run from anywhere: python3 store/trailer/make_trailer.py).

store/trailer/scenes/trailer.scene.json is the game scene, the director store/trailer/trailer.js, the captions and a black
cover. The bot is the player: the run passes the scene props that make it build the town in time lapse
(`--props`, PROPS below: `grow` days, `timelapse` frames per game day, `photo` = no interface). The run that records the video is in SHIPPING.md ("Trailer").
"""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(os.path.dirname(HERE))
FPS = 60
DAYS, LAPSE = 100, 4              # 400 frames of building, then the camera tours the town
SECONDS = 18
PROPS = {"grow": DAYS, "timelapse": LAPSE, "photo": True, "music": False, "zoom": 1.1}
GOLD = [1, 0.91, 0.55, 0]
WHITE = [1, 1, 1, 0]
# (text, from second, to second, size, kind)
CARDS = [
    ("Tidewater Market", 0.5, 3.2, 100, "title"),
    ("Start with a coast and a road.", 3.4, 6.6, 44, "sub"),
    ("Feed your villagers. Fill every order.", 7.8, 11.8, 44, "sub"),
    ("Grow a harbour town, one trade at a time.", 12.4, 16.2, 44, "sub"),
]


def caption(i, text, size, color, y):
    return {"id": f"trailer_card_{i}", "tags": ["caption"], "components": {
        "Transform": {"position": [0, y, 0]},
        "Text": {"text": text, "fontSize": size, "color": color, "align": "center", "space": "screen",
                 "anchor": [0.5, 0.5], "pivot": [0.5, 0.5], "layer": 400}}}


def main():
    scene = json.load(open(os.path.join(GAME, "scenes/game.scene.json")))
    cards = []
    for i, (text, t0, t1, size, kind) in enumerate(CARDS):
        y = -40 if kind == "title" else 290
        scene["entities"].append(caption(i, text, size, GOLD if kind == "title" else WHITE, y))
        cards.append({"id": f"trailer_card_{i}", "t0": t0, "t1": t1})
    scene["entities"].append({"id": "trailer_black", "components": {
        "Transform": {"position": [0, 0, 0]},
        "Shape2D": {"shape": "rectangle", "size": [4000, 2400], "color": [0, 0, 0, 1], "space": "screen",
                    "anchor": [0.5, 0.5], "pivot": [0.5, 0.5], "layer": 500}}})
    scene["entities"].append({"id": "trailer", "components": {"Script": {
        "path": "store/trailer/trailer.js",
        "props": {"zoomKeys": [[0, 1.1], [6.7, 0.8], [11, 0.95], [SECONDS, 0.7]],
                  "focusKeys": [[0, 0], [6.7, 0.7], [11, 1], [SECONDS, 0.6]],
                  "cards": cards, "fadeIn": 0.6, "fadeOutAt": SECONDS - 1.6, "fadeOutSeconds": 1.4}}}})
    out = os.path.join(HERE, "scenes")
    os.makedirs(out, exist_ok=True)
    json.dump(scene, open(os.path.join(out, "trailer.scene.json"), "w"), indent=1)
    print("--props", json.dumps(PROPS))
    print("store/trailer/scenes/trailer.scene.json:", SECONDS * FPS, "frames =", SECONDS, "s")


if __name__ == "__main__":
    main()
