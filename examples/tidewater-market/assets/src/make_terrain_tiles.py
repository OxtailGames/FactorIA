#!/usr/bin/env python3
"""Builds the terrain tilesets of Tidewater Market (needs Pillow).

    python3 assets/src/make_terrain_tiles.py             # from the project folder

writes assets/tiles/<season>.png, one per season of data/seasons.json. Each is a regular grid of tileSize cells (data/terrain.json,
"tileset") that the isometric Tilemap of scripts/game/map_view.js reads: water, rock, sand, grass, forest without trees,
the 16 road pieces by neighbour mask, and `treeVariants` forests with three trees each (a fixed generator places them, so the
files are the same bytes every run). The pictures are the frames in assets/src/frames (the Kenney terrain, road and tree
pieces); the season tint of data/seasons.json is multiplied into the sand, grass, forest and trees, so a season change swaps
the tileset instead of tinting the map (water, rock and roads are not tinted, as before).

A cell is 100 x 105: the ground piece (100 x 65, its diamond in the top 50 rows) sits groundOffset (40) rows down, and the
trees rise into the 40 rows above it.
"""
import json
import os
import random
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FRAMES = os.path.join(ROOT, "assets", "src", "frames")


def load_json(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return json.load(f)


def frame(name):
    return Image.open(os.path.join(FRAMES, name + ".png")).convert("RGBA")


def tint(img, t):
    """Multiply the colour (not the alpha) by t = [r, g, b, a], clamped like the GPU does."""
    r, g, b, a = img.split()
    mul = lambda band, k: band.point(lambda v: min(255, int(round(v * k))))
    return Image.merge("RGBA", (mul(r, t[0]), mul(g, t[1]), mul(b, t[2]), mul(a, t[3])))


def main():
    terrain = load_json("data/terrain.json")
    seasons = load_json("data/seasons.json")["seasons"]
    atlas = load_json("data/atlas.json")
    ts = terrain["tileset"]
    cw, ch = ts["tileSize"]
    off = ts["groundOffset"]
    cols = ts["columns"]
    kinds = terrain["terrain"]
    total = ts["treeTile"] + ts["treeVariants"]
    rows = (total + cols - 1) // cols

    # Where the three trees of each variant stand: inside the diamond, as the sprite-per-cell view used to place them.
    rng = random.Random(ts["treeSeed"])
    variants = []
    for _ in range(ts["treeVariants"]):
        trees = []
        for _ in range(3):
            a, b = rng.random(), rng.random()
            kind = int(rng.random() * 6)
            dx = (a * 2 - 1) * 34
            dy = (b * 2 - 1) * (17 - abs(dx) / 2) * 0.9
            trees.append((kind, dx, dy))
        trees.sort(key=lambda t: -t[2])  # the one that is higher up the screen first: the nearer ones cover the farther ones
        variants.append(trees)

    for season, info in seasons.items():
        st = info["tint"]
        sheet = Image.new("RGBA", (cols * cw, rows * ch), (0, 0, 0, 0))

        def put(index, img, at=(0, 0)):
            cell = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
            cell.alpha_composite(img, at)
            sheet.alpha_composite(cell, ((index % cols) * cw, (index // cols) * ch))
            return cell

        def ground(name, tints):
            img = frame(name)
            for t in tints:
                img = tint(img, t)
            return img

        for kind in kinds.values():
            seasonal = [st] if kind.get("seasonal") else []
            own = [kind["tint"]] if "tint" in kind else []
            put(kind["tile"], ground(kind["frame"], own + seasonal), (0, off))
        # roads: the frame of each neighbour mask, never tinted
        for mask in range(16):
            put(ts["roadTile"] + mask, frame(atlas["roadFrames"][str(mask)]), (0, off))
        # forests with trees: the forest ground and three trees, tinted by the season
        base = ground(kinds["forest"]["frame"], [kinds["forest"]["tint"], st])
        for i, trees in enumerate(variants):
            img = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
            img.alpha_composite(base, (0, off))
            for kind, dx, dy in trees:
                tree = tint(frame("tree.%d" % kind), st)
                foot_y = off + 25 - (dy - 2)  # the diamond's centre is 25 rows below its top corner; +y was up
                img.alpha_composite(tree, (int(round(cw / 2 + dx - tree.width / 2)), int(round(foot_y - tree.height))))
            put(ts["treeTile"] + i, img)
        out = os.path.join(ROOT, ts["seasons"][season])
        os.makedirs(os.path.dirname(out), exist_ok=True)
        sheet.save(out, optimize=True)
        print("wrote", os.path.relpath(out, ROOT), sheet.size)


if __name__ == "__main__":
    sys.exit(main())
