#!/usr/bin/env python3
"""Builds the two margin-free 16 px atlases of Burrow Brigade from Kenney's CC0 packs.

  python3 -I make_atlases.py <tiny-dungeon-dir> <roguelike-caves-dir> <out-dir>

  <tiny-dungeon-dir>      the unzipped "Tiny Dungeon" pack (Tilemap/tilemap_packed.png, 16 px, no margin)
  <roguelike-caves-dir>   the unzipped "Roguelike Caves & Dungeons" pack (Spritesheet/roguelikeDungeon_transparent.png,
                          16 px tiles with a 1 px margin)
  <out-dir>               receives tiles.png and sprites.png

Why this exists: the engine's Tilemap reads a tileset with no spacing field (docs/COMPONENTS.md, Tilemap), and the
Caves sheet has a 1 px margin, so its tiles are cut out and re-packed here. The same pass paints the ore tiles (a
decal over a dirt or rock tile), darkens the floor, draws the lift marks, one oil can and the mole, which the packs do
not have. Only the Python standard library is used. Both packs are Creative Commons Zero (CC0 1.0) by Kenney
(www.kenney.nl); the mole, the arrow and the cracks are drawn here by the project and are CC0 too.
The output is deterministic: running it again gives the same bytes.

Index tables (kept in sync by hand with scripts/game/tiles.js):
  tiles.png   8 columns: 0-3 floor, 4-7 dirt, 8-11 rock, 12-15 hard rock, 16 bedrock, 17 copper ore, 18 silver ore,
              19 gold ore, 20 gem ore, 21 start lift, 22 exit lift, 23 oil can
  sprites.png 8 columns: 0-3 miners, 4 trapped mole, 5 rescued mole, 6 target cursor, 7 oil icon, 8-11 ore icons
              (copper, silver, gold, gem), 12-14 crack stages
"""
import os
import struct
import sys
import zlib

T = 16


def read_png(path):
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit(f"{path}: not a PNG")
    pos, idat, plte, trns = 8, b"", None, None
    while pos < len(data):
        (ln,) = struct.unpack(">I", data[pos:pos + 4])
        typ, body = data[pos + 4:pos + 8], data[pos + 8:pos + 8 + ln]
        pos += 12 + ln
        if typ == b"IHDR":
            w, h, bd, ct, _, _, il = struct.unpack(">IIBBBBB", body)
        elif typ == b"PLTE":
            plte = body
        elif typ == b"tRNS":
            trns = body
        elif typ == b"IDAT":
            idat += body
    if bd != 8 or il != 0:
        raise SystemExit(f"{path}: only 8-bit non-interlaced PNGs are read")
    ch = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ct]
    raw, stride = zlib.decompress(idat), w * ch
    rows, prev, p = [], bytearray(stride), 0
    for _ in range(h):
        f = raw[p]
        p += 1
        line = bytearray(raw[p:p + stride])
        p += stride
        for i in range(stride):
            a = line[i - ch] if i >= ch else 0
            b = prev[i]
            c = prev[i - ch] if i >= ch else 0
            if f == 1:
                line[i] = (line[i] + a) & 255
            elif f == 2:
                line[i] = (line[i] + b) & 255
            elif f == 3:
                line[i] = (line[i] + ((a + b) >> 1)) & 255
            elif f == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                line[i] = (line[i] + (a if (pa <= pb and pa <= pc) else (b if pb <= pc else c))) & 255
        rows.append(line)
        prev = line
    out = []
    for line in rows:
        r = []
        for x in range(w):
            if ct == 6:
                r.append(tuple(line[x * 4:x * 4 + 4]))
            elif ct == 2:
                r.append((line[x * 3], line[x * 3 + 1], line[x * 3 + 2], 255))
            elif ct == 3:
                i = line[x]
                r.append((plte[i * 3], plte[i * 3 + 1], plte[i * 3 + 2], trns[i] if trns and i < len(trns) else 255))
            elif ct == 4:
                r.append((line[x * 2], line[x * 2], line[x * 2], line[x * 2 + 1]))
            else:
                r.append((line[x], line[x], line[x], 255))
        out.append(r)
    return w, h, out


def write_png(path, w, h, px):
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        for x in range(w):
            raw.extend(px[y][x])

    def chunk(t, b):
        c = struct.pack(">I", len(b)) + t + b
        return c + struct.pack(">I", zlib.crc32(t + b) & 0xFFFFFFFF)

    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))
    open(path, "wb").write(png)


def cut(img, x, y):
    return [row[x:x + T] for row in img[y:y + T]]


def blank():
    return [[(0, 0, 0, 0)] * T for _ in range(T)]


def over(base, top):
    """Alpha-composites top over base (both 16x16)."""
    out = []
    for yb, yt in zip(base, top):
        row = []
        for b, t in zip(yb, yt):
            a = t[3] / 255.0
            if t[3] == 255:
                row.append(t)
            elif t[3] == 0:
                row.append(b)
            else:
                ba = b[3] / 255.0
                oa = a + ba * (1 - a)
                c = [int(round((t[i] * a + b[i] * ba * (1 - a)) / oa)) for i in range(3)] if oa else [0, 0, 0]
                row.append((c[0], c[1], c[2], int(round(oa * 255))))
        out.append(row)
    return out


def shade(tile, f, tint=(1.0, 1.0, 1.0)):
    return [[(min(255, int(p[0] * f * tint[0])), min(255, int(p[1] * f * tint[1])), min(255, int(p[2] * f * tint[2])),
              p[3]) for p in row] for row in tile]


def recolor(tile, table):
    return [[(table[p[:3]] + (p[3],)) if p[:3] in table else p for p in row] for row in tile]


def flip_x(tile):
    return [list(reversed(row)) for row in tile]


def draw(rows, palette):
    """16 strings of up to 16 characters; '.' is transparent."""
    t = blank()
    for y, line in enumerate(rows):
        for x, ch in enumerate(line):
            if ch != "." and ch in palette:
                t[y][x] = palette[ch] + (255,)
    return t


OUT = (63, 38, 49)
MOLE = {
    "o": OUT, "d": (118, 59, 54), "m": (189, 108, 74), "l": (234, 165, 108), "p": (236, 130, 150),
    "k": (24, 16, 28), "w": (255, 255, 255), "c": (247, 194, 130), "r": (232, 69, 55),
}
MOLE_TRAPPED = [
    "................",
    "................",
    ".....oooooo.....",
    "....oddddddo....",
    "...odddddddddo..",
    "..oddwkddwkdddo.",
    "..odddddddddddo.",
    "..odddddppddddo.",
    "..oddddpppppddo.",
    "...oddddppddddo.",
    "..occoddddddocco",
    ".occcodddddoccco",
    ".occcooooooocccc",
    "..ooo.oo..oo.ooo",
    "................",
    "................",
]
MOLE_FREE = [
    "................",
    "................",
    ".....oooooo.....",
    "....oddddddo....",
    "...odddddddddo..",
    "..oddkkddkkdddo.",
    "..odddddddddddo.",
    "..odddddppddddo.",
    "..oddddpppppddo.",
    "...odddrrrrdddo.",
    "..occoddddddocco",
    ".occcodddddoccco",
    ".occcooooooocccc",
    "..ooo.oo..oo.ooo",
    "................",
    "................",
]
ARROW = [
    "................",
    "................",
    "....gggggggg....",
    "....gGGGGGGg....",
    ".....gGGGGg.....",
    ".....gGGGGg.....",
    "..gggggGGggggg..",
    "...gGGGGGGGGg...",
    "....gGGGGGGg....",
    ".....gGGGGg.....",
    "......gGGg......",
    ".......gg.......",
    "................",
    "................",
    "................",
    "................",
]
CRACKS = [
    # three stages, 1 = darkest line pixel
    ["................", "................", "......1.........", ".......1........", "......11........",
     ".......1........", "................", "................", "................", "................",
     "................", "................", "................", "................", "................", "................"],
    ["................", "..1.............", "...1...1........", "....1.1.........", "......1.....1...",
     ".....11....1....", "......1...1.....", ".............1..", "......1.........", "......11........",
     ".......1........", "................", "................", "................", "................", "................"],
    ["..1.......1.....", "...1.....1......", "....1...1...1...", ".....1.1...1....", "......1...1.....",
     "...11..1.1......", "....1111111.....", ".......1..1.....", "......1....1....", "..1..11.....1...",
     "...1.1.......1..", "....11...1.......", "......1.1........", ".......1.........", "........1.......",
     "................"],
]


def crack(rows):
    t = blank()
    for y, line in enumerate(rows):
        for x, ch in enumerate(line):
            if ch == "1":
                t[y][x] = (24, 14, 20, 230)
    return t


def sheet(tiles, cols):
    rows = (len(tiles) + cols - 1) // cols
    px = [[(0, 0, 0, 0)] * (cols * T) for _ in range(rows * T)]
    for i, tile in enumerate(tiles):
        ox, oy = (i % cols) * T, (i // cols) * T
        for y in range(T):
            for x in range(T):
                px[oy + y][ox + x] = tile[y][x]
    return cols * T, rows * T, px


def main():
    if len(sys.argv) != 4:
        raise SystemExit(__doc__)
    td_dir, caves_dir, out_dir = sys.argv[1:4]
    _, _, td = read_png(os.path.join(td_dir, "Tilemap", "tilemap_packed.png"))
    _, _, cv = read_png(os.path.join(caves_dir, "Spritesheet", "roguelikeDungeon_transparent.png"))

    def td_tile(c, r):
        return cut(td, c * T, r * T)

    def cv_tile(c, r):  # 16 px tiles, 1 px margin: pitch 17
        return cut(cv, c * 17, r * 17)

    brown = [cv_tile(16 + i, 12) for i in range(5)]
    gray = [cv_tile(16 + i, 10) for i in range(5)]
    gray2 = [cv_tile(16 + i, 16) for i in range(5)]
    brown_checker = cv_tile(18, 13)
    gray2_square = cv_tile(20, 17)

    floor = [shade(brown[i], 0.40, (1.0, 0.92, 0.9)) for i in range(4)]
    dirt = [brown[i] for i in range(4)]
    rock = [shade(gray[i], 0.80) for i in range(4)]
    hard = [shade(gray2[i], 0.55, (0.9, 0.9, 1.0)) for i in range(4)]
    bedrock = shade(gray2_square, 0.32, (0.9, 0.85, 1.0))
    ore_dirt = brown[4]
    ore_rock = shade(gray[4], 0.80)
    ore_hard = shade(gray2[4], 0.55, (0.9, 0.9, 1.0))
    decal_copper, decal_silver = cv_tile(14, 13), cv_tile(15, 10)
    decal_gold, decal_gem = cv_tile(15, 12), cv_tile(14, 12)

    rails_start, rails_exit = cv_tile(10, 16), cv_tile(10, 17)
    lift_start = over(floor[0], rails_start)
    lift_exit = over(over(floor[1], rails_exit), draw(ARROW, {"g": (30, 120, 60), "G": (130, 235, 140)}))
    amber = {(139, 155, 180): (205, 120, 30), (192, 203, 220): (247, 194, 130), (170, 183, 204): (230, 160, 60),
             (118, 59, 54): (118, 59, 54)}
    oil_icon = recolor(td_tile(5, 9), amber)
    oil_can = over(floor[2], oil_icon)

    tiles = floor + dirt + rock + hard + [
        bedrock,
        over(ore_dirt, decal_copper), over(ore_rock, decal_silver), over(ore_hard, decal_gold), over(ore_hard, decal_gem),
        lift_start, lift_exit, oil_can,
    ]
    w, h, px = sheet(tiles, 8)
    os.makedirs(out_dir, exist_ok=True)
    write_png(os.path.join(out_dir, "tiles.png"), w, h, px)

    sprites = [
        td_tile(1, 7), td_tile(2, 7), td_tile(4, 7), td_tile(4, 9),
        draw(MOLE_TRAPPED, MOLE), draw(MOLE_FREE, MOLE),
        td_tile(0, 5), oil_icon,
        decal_copper, decal_silver, decal_gold, decal_gem,  # the decals sit on a transparent background: HUD icons
        crack(CRACKS[0]), crack(CRACKS[1]), crack(CRACKS[2]),
    ]
    w, h, px = sheet(sprites, 8)
    write_png(os.path.join(out_dir, "sprites.png"), w, h, px)
    print(f"wrote {out_dir}/tiles.png ({len(tiles)} tiles) and sprites.png ({len(sprites)} sprites)")


if __name__ == "__main__":
    main()
