#!/usr/bin/env python3
"""Builds the margin-free 16 px atlases of Burrow Brigade from Kenney's CC0 packs: one tileset per stratum
(tiles_topsoil.png, tiles_crystal.png, tiles_magma.png), the sprites and the fog tiles.

  python3 -I make_atlases.py <tiny-dungeon-dir> <roguelike-caves-dir> <out-dir>

  <tiny-dungeon-dir>      the unzipped "Tiny Dungeon" pack (Tilemap/tilemap_packed.png, 16 px, no margin)
  <roguelike-caves-dir>   the unzipped "Roguelike Caves & Dungeons" pack (Spritesheet/roguelikeDungeon_transparent.png,
                          16 px tiles with a 1 px margin)
  <out-dir>               receives tiles_topsoil.png, tiles_crystal.png, tiles_magma.png, sprites.png and fog.png

Why this exists: the engine's Tilemap reads a tileset with no spacing field (docs/COMPONENTS.md, Tilemap), and the
Caves sheet has a 1 px margin, so its tiles are cut out and re-packed here. The same pass paints the ore tiles (a
decal over a dirt or rock tile), darkens the floor, draws the lift marks, one oil can and the mole, which the packs do
not have. Only the Python standard library is used. Both packs are Creative Commons Zero (CC0 1.0) by Kenney
(www.kenney.nl); the mole, the king's crown, the arrow, the cracks, the crystals, the magma, the warning marks and
the falling rock are drawn here by the project and are CC0 too. The three strata share one index table; each stratum
recolours the Topsoil pictures (Crystal Caves: blue and violet, Magma Deep: charcoal with a red glow).
The output is deterministic: running it again gives the same bytes.

Index tables (kept in sync by hand with scripts/game/tiles.js):
  tiles_*.png 8 columns: 0-3 floor, 4-7 dirt, 8-11 rock, 12-15 hard rock, 16 bedrock, 17 copper ore, 18 silver ore,
              19 gold ore, 20 gem ore, 21 start lift, 22 exit lift, 23 oil can, 24-25 water, 26-27 magma,
              28 cracked (shaky) floor, 29-30 crystal wall
  sprites.png 8 columns: 0-3 miners, 4 trapped mole, 5 rescued mole, 6 target cursor, 7 oil icon, 8-11 ore icons
              (copper, silver, gold, gem), 12-14 crack stages, 15 torch, 16 beetle, 17 goblin thief, 18 Mole King,
              19 warning mark, 20 falling rock
  fog.png     2 tiles of 16 px: 0 opaque black (never seen), 1 half-dark (seen before, out of sight now)
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


KING = {
    "o": OUT, "d": (118, 59, 54), "m": (189, 108, 74), "l": (234, 165, 108), "p": (236, 130, 150),
    "k": (24, 16, 28), "w": (255, 255, 255), "c": (247, 194, 130), "r": (232, 69, 55),
    "y": (255, 206, 60), "Y": (200, 140, 30), "g": (80, 200, 220),
}
MOLE_KING = [
    "...y..y..yy..y..",
    "...yyyyyyyyyy...",
    "...yYgyYYgyYy...",
    "....oyyyyyyo....",
    "...odddddddddo..",
    "..oddwkddwkdddo.",
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
WARNING = [
    "................",
    ".rrrrrrrrrrrrrr.",
    ".r............r.",
    ".r....rrrr....r.",
    ".r....rrrr....r.",
    ".r....rrrr....r.",
    ".r....rrrr....r.",
    ".r....rrrr....r.",
    ".r....rrrr....r.",
    ".r............r.",
    ".r....rrrr....r.",
    ".r....rrrr....r.",
    ".r............r.",
    ".rrrrrrrrrrrrrr.",
    "................",
    "................",
]
FALLING_ROCK = [
    "................",
    "................",
    "......oooo......",
    "....ooggggoo....",
    "...oggGGGgggo...",
    "...ogGGggggg o..".replace(" ", ""),
    "..oggGgggdggggo.",
    "..ogggggdddgggo.",
    "..oggggdddddggo.",
    "...oggggddddgo..",
    "...ooggggggoo...",
    ".....oooooooo...",
    "................",
    "................",
    "................",
    "................",
]
CRYSTAL_A = [
    "................",
    ".......aa.......",
    "......abba......",
    "......abBa......",
    ".....abBBba.....",
    "..aa.abBBba.aa..",
    ".abba.abBa.abba.",
    ".abBba.aa.abBba.",
    ".abBBba..abBBba.",
    "..abBBba.abBba..",
    "..aabBBbabBBa...",
    "....abBBbbBa....",
    ".....aabbbaa....",
    ".......aaa......",
    "................",
    "................",
]
CRYSTAL_B = [
    "................",
    "................",
    "...aa.....aa....",
    "..abba...abba...",
    "..abBba.abBba...",
    "..abBBbabBBba...",
    "...abBBbBBba..a.",
    "...abBBBBba..aba",
    "....abBBBba.abBa",
    ".aa.abBBBba.abBa",
    "abba.abBBa..abba",
    "abBba.aba....aa.",
    "abBBba.aa.......",
    ".abbba..........",
    "..aaa...........",
    "................",
]
CRYSTAL_PALETTES = {
    "topsoil": {"a": (60, 70, 120), "b": (110, 190, 235), "B": (210, 245, 255)},
    "crystal": {"a": (90, 40, 130), "b": (200, 110, 235), "B": (255, 215, 255)},
    "magma": {"a": (90, 40, 40), "b": (240, 130, 60), "B": (255, 230, 150)},
}
SHAKY = [
    "................",
    "................",
    "..1.............",
    "...1....1.......",
    "....1..1........",
    ".....11....1....",
    ".......1..1.....",
    ".......111......",
    "......1...1.....",
    ".....1.....1....",
    "....1.......1...",
    "...1.....1...1..",
    "........1.......",
    "................",
    "................",
    "................",
]


class Lcg:
    """A tiny seeded generator, so the drawn tiles are the same on every run."""

    def __init__(self, seed):
        self.s = seed & 0xFFFFFFFF

    def next(self):
        self.s = (self.s * 1664525 + 1013904223) & 0xFFFFFFFF
        return self.s >> 8


def water_tile(base, variant):
    """Deep blue-cyan water: the Caves sheet's water, darkened and rippled differently per variant."""
    r = Lcg(77 + variant)
    out = [list(row) for row in base]
    for _ in range(14):
        x, y = r.next() % 14 + 1, r.next() % 15
        for dx in range(2):
            p = out[y][x + dx]
            out[y][x + dx] = (min(255, p[0] + 60), min(255, p[1] + 60), min(255, p[2] + 40), 255)
    return shade(out, 0.82, (0.85, 0.95, 1.1))


def magma_tile(variant):
    """Glowing magma: dark red crust cracks over bright orange, drawn from a seeded generator."""
    r = Lcg(500 + variant * 17)
    t = blank()
    for y in range(T):
        for x in range(T):
            v = (r.next() % 100)
            if v < 45:
                c = (232, 69, 55)
            elif v < 80:
                c = (247, 128, 40)
            elif v < 94:
                c = (255, 190, 70)
            else:
                c = (255, 235, 150)
            t[y][x] = c + (255,)
    for _ in range(9):  # crust
        x, y = r.next() % 12 + 1, r.next() % 12 + 1
        for dx in range(r.next() % 3 + 2):
            for dy in range(r.next() % 2 + 1):
                if x + dx < T and y + dy < T:
                    t[y + dy][x + dx] = (96, 30, 30, 255)
    return t


def cracked_floor(floor):
    t = [list(row) for row in floor]
    for y, line in enumerate(SHAKY):
        for x, ch in enumerate(line):
            if ch == "1":
                t[y][x] = (24, 14, 20, 255)
    return [[(min(255, p[0] + 14), min(255, p[1] + 10), min(255, p[2] + 6), p[3]) for p in row] for row in t]


def crystal_wall(rock, rows, stratum):
    pal = {k: v for k, v in CRYSTAL_PALETTES[stratum].items()}
    return over(shade(rock, 0.7), draw(rows, pal))


def swap(tile, mix):
    """Recolours with a 3x3 matrix (rows give the new r, g, b from the old r, g, b)."""
    out = []
    for row in tile:
        r = []
        for p in row:
            c = [min(255, max(0, int(sum(mix[i][j] * p[j] for j in range(3))))) for i in range(3)]
            r.append((c[0], c[1], c[2], p[3]))
        out.append(r)
    return out


# how each stratum recolours the Topsoil pictures
LOOKS = {
    "topsoil": None,
    # brown -> blue/violet: the red and blue channels trade places and the green stays cool
    "crystal": [[0.30, 0.15, 0.85], [0.15, 0.62, 0.30], [0.70, 0.30, 0.20]],
    # brown -> charcoal with a warm red cast
    "magma": [[0.62, 0.30, 0.10], [0.22, 0.30, 0.08], [0.18, 0.20, 0.22]],
}


def build_tiles(st, parts):
    """The 31 tiles of one stratum's tileset."""
    look = LOOKS[st]
    f = (lambda t: t) if look is None else (lambda t: swap(t, look))
    floor, dirt, rock, hard = ([f(t) for t in parts[k]] for k in ("floor", "dirt", "rock", "hard"))
    bedrock = f(parts["bedrock"])
    if st == "magma":  # a red glow in the cracks of the deep floor
        floor = [shade(t, 1.15, (1.25, 0.85, 0.8)) for t in floor]
    ore_dirt, ore_rock, ore_hard = f(parts["ore_dirt"]), f(parts["ore_rock"]), f(parts["ore_hard"])
    d = parts["decals"]
    lifts = [over(floor[0], parts["rails_start"]), parts["lift_exit"](floor[1])]
    oil_can = over(floor[2], parts["oil_icon"])
    water_base = parts["water"]
    return floor + dirt + rock + hard + [
        bedrock,
        over(ore_dirt, d[0]), over(ore_rock, d[1]), over(ore_hard, d[2]), over(ore_hard, d[3]),
        lifts[0], lifts[1], oil_can,
        water_tile(water_base, 0), water_tile(water_base, 1),
        magma_tile(0), magma_tile(1),
        cracked_floor(floor[3]),
        crystal_wall(rock[0], CRYSTAL_A, st), crystal_wall(rock[1], CRYSTAL_B, st),
    ]


def fog_tiles():
    black = [[(0, 0, 0, 255)] * T for _ in range(T)]
    half = [[(0, 0, 0, 150)] * T for _ in range(T)]
    return [black, half]


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
    gray2_square = cv_tile(20, 17)

    floor = [shade(brown[i], 0.40, (1.0, 0.92, 0.9)) for i in range(4)]
    amber = {(139, 155, 180): (205, 120, 30), (192, 203, 220): (247, 194, 130), (170, 183, 204): (230, 160, 60),
             (118, 59, 54): (118, 59, 54)}
    oil_icon = recolor(td_tile(5, 9), amber)
    rails_exit = cv_tile(10, 17)
    arrow = draw(ARROW, {"g": (30, 120, 60), "G": (130, 235, 140)})
    parts = {
        "floor": floor,
        "dirt": [brown[i] for i in range(4)],
        "rock": [shade(gray[i], 0.80) for i in range(4)],
        "hard": [shade(gray2[i], 0.55, (0.9, 0.9, 1.0)) for i in range(4)],
        "bedrock": shade(gray2_square, 0.32, (0.9, 0.85, 1.0)),
        "ore_dirt": brown[4],
        "ore_rock": shade(gray[4], 0.80),
        "ore_hard": shade(gray2[4], 0.55, (0.9, 0.9, 1.0)),
        "decals": [cv_tile(14, 13), cv_tile(15, 10), cv_tile(15, 12), cv_tile(14, 12)],
        "rails_start": cv_tile(10, 16),
        "lift_exit": lambda fl: over(over(fl, rails_exit), arrow),
        "oil_icon": oil_icon,
        "water": cv_tile(1, 11),
    }
    os.makedirs(out_dir, exist_ok=True)
    for st in ("topsoil", "crystal", "magma"):
        tiles = build_tiles(st, parts)
        w, h, px = sheet(tiles, 8)
        write_png(os.path.join(out_dir, f"tiles_{st}.png"), w, h, px)

    # the goblin thief: the hooded wizard of Tiny Dungeon with its brown hat and robe turned green
    hood = recolor(td_tile(3, 9), {(138, 83, 56): (60, 110, 60), (188, 108, 74): (96, 160, 80), (234, 165, 108): (140, 200, 110)})
    # a brazier with a flame: the Caves sheet's lit one
    torch = cv_tile(13, 17)
    sprites = [
        td_tile(1, 7), td_tile(2, 7), td_tile(4, 7), td_tile(4, 9),
        draw(MOLE_TRAPPED, MOLE), draw(MOLE_FREE, MOLE),
        td_tile(0, 5), oil_icon,
        parts["decals"][0], parts["decals"][1], parts["decals"][2], parts["decals"][3],  # on a transparent background: HUD icons
        crack(CRACKS[0]), crack(CRACKS[1]), crack(CRACKS[2]),
        torch, td_tile(3, 10), hood, draw(MOLE_KING, KING),
        draw(WARNING, {"r": (240, 70, 60)}),
        draw(FALLING_ROCK, {"o": OUT, "g": (150, 150, 160), "G": (200, 200, 210), "d": (96, 96, 110)}),
    ]
    w, h, px = sheet(sprites, 8)
    write_png(os.path.join(out_dir, "sprites.png"), w, h, px)
    w, h, px = sheet(fog_tiles(), 2)
    write_png(os.path.join(out_dir, "fog.png"), w, h, px)
    print(f"wrote {out_dir}: tiles_topsoil/crystal/magma.png ({len(tiles)} tiles each), sprites.png ({len(sprites)} sprites), fog.png")


if __name__ == "__main__":
    main()
