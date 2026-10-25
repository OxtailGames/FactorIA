#!/usr/bin/env python3
"""Paints the colour-free markers on the ore and hazard tiles of Burrow Brigade's three tilesets.

  python3 -I make_markers.py <assets-dir>

  <assets-dir>   the folder with tiles_topsoil.png, tiles_crystal.png and tiles_magma.png (the files are rewritten in place)

Why: a player who cannot tell colours apart must still read which tile is which ore and which tile hurts. Each ore and hazard
tile gets a small white shape with a dark outline in its top-left corner, the same in every stratum, so the shape reads in
greyscale and in the colour filters of Options > Video:

  copper  a disc            silver  two bars        gold  a triangle       gem  a diamond
  water   waves             magma   a cross         cracked floor  an exclamation mark

Run it AFTER make_atlases.py (which draws the colours): it only adds the markers, and running it twice gives the same bytes.
Only the Python standard library is used; the shapes are drawn here by the project and are CC0, like the rest of the art.
The atlas indices are the ones of scripts/game/tiles.js (KINDS[...].base).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_atlases import read_png, write_png, T  # noqa: E402

FILL = (246, 246, 240, 255)
EDGE = (16, 16, 20, 255)

GLYPHS = {
    "copper": [".###.", "#####", "#####", "#####", ".###."],
    "silver": [".....", "#####", ".....", "#####", "....."],
    "gold": ["..#..", ".###.", ".###.", "#####", "#####"],
    "gem": ["..#..", ".###.", "#####", ".###.", "..#.."],
    "water": [".....", ".#.#.", "#.#.#", ".....", "....."],
    "magma": ["#...#", ".#.#.", "..#..", ".#.#.", "#...#"],
    "shaky": ["..#..", "..#..", "..#..", ".....", "..#.."],
}

# atlas index -> glyph (the water and magma tiles have two pictures each)
PLACE = {17: "copper", 18: "silver", 19: "gold", 20: "gem", 24: "water", 25: "water", 26: "magma", 27: "magma", 28: "shaky"}


def stamp(img, tile, glyph, ox=1, oy=1):
    """Draws a 5x5 glyph with a 1 px outline into the atlas, its outline box starting at (ox, oy) of tile `tile`."""
    cols = len(img[0]) // T
    x0, y0 = (tile % cols) * T + ox, (tile // cols) * T + oy
    rows = GLYPHS[glyph]
    on = {(x + 1, y + 1) for y, line in enumerate(rows) for x, ch in enumerate(line) if ch == "#"}  # +1: room for the outline
    for y in range(7):
        for x in range(7):
            if (x, y) in on:
                img[y0 + y][x0 + x] = FILL
            elif any((x + dx, y + dy) in on for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                img[y0 + y][x0 + x] = EDGE


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    for name in ("topsoil", "crystal", "magma"):
        path = os.path.join(sys.argv[1], f"tiles_{name}.png")
        w, h, img = read_png(path)
        img = [list(r) for r in img]
        for tile, glyph in PLACE.items():
            stamp(img, tile, glyph)
        write_png(path, w, h, img)
        print(f"{path}: {len(PLACE)} markers")


if __name__ == "__main__":
    main()
