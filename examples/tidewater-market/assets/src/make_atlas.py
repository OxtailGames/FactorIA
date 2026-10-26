#!/usr/bin/env python3
"""Packs every picture the map draws into ONE atlas (assets/atlas.png) and writes data/atlas.json.

Why one texture: the renderer batches sprites that share a texture, so a map of 1600 tiles is a handful of draw calls
with one atlas and thousands when two textures alternate (see ENGINE_FEEDBACK.json).

Inputs
  assets/src/kenney/*.png   Kenney "Isometric Roads" (CC0): terrain tiles, road pieces and trees, imported with assets.import.
  this file                 the placeholder art drawn by hand: the buildings (4 rotations each), the rock tile, the goods icons.
Outputs
  assets/atlas.png          the atlas.
  data/atlas.json           name -> { rect: [x, y, w, h] in atlas pixels (top-left origin), pivot: [px, py] for Sprite.pivot (+Y up) }.

Run from the project folder:  python3 assets/src/make_atlas.py   (needs Pillow). Deterministic: same bytes every run.
Everything drawn here is original placeholder art (CC0); P7 replaces it with finished art under the same frame names.
"""
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.normpath(os.path.join(HERE, "..", ".."))
KENNEY = os.path.join(HERE, "kenney")
SS = 4  # supersampling for the drawn art

# ---- building art -----------------------------------------------------------------------------------------------
# A building of w x h cells is drawn in an image (w + h) * 50 wide whose bottom vertex of the ground diamond is at
# (w * 50, height): the sprite pivot is [w / (w + h), 0] and the entity sits on that vertex (see scripts/game/iso.js).
# 3D point (u, v, z): u along +c (towards the lower right), v along +r (towards the lower left), z up in pixels.


def shade(col, k):
    return tuple(max(0, min(255, int(c * k))) for c in col[:3]) + ((col[3],) if len(col) > 3 else (255,))


class Canvas:
    def __init__(self, w, h, height_px):
        self.w, self.h = w, h
        self.W = (w + h) * 50
        self.H = (w + h) * 25 + height_px + 12
        self.img = Image.new("RGBA", (self.W * SS, self.H * SS), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)
        self.faces = []

    def p(self, u, v, z):
        x = self.h * 50 + (u - v) * 50
        y = self.H - (self.w + self.h) * 25 + (u + v) * 25 - z
        return (x * SS, y * SS)

    def poly(self, pts, col, depth, outline=None):
        self.faces.append((depth, [self.p(*q) for q in pts], col, outline))

    def box(self, u0, v0, u1, v1, z0, z1, col, outline=True):
        """Three visible faces of a box: top, the +c face (lit) and the +r face (shaded)."""
        edge = shade(col, 0.7) if outline else None
        d = (u0 + u1 + v0 + v1) / 2 + z0 / 100.0
        self.poly([(u1, v0, z0), (u1, v1, z0), (u1, v1, z1), (u1, v0, z1)], shade(col, 0.86), d + 0.2, edge)
        self.poly([(u0, v1, z0), (u1, v1, z0), (u1, v1, z1), (u0, v1, z1)], shade(col, 0.68), d + 0.2, edge)
        self.poly([(u0, v0, z1), (u1, v0, z1), (u1, v1, z1), (u0, v1, z1)], shade(col, 1.08), d + 0.3, edge)

    def flat(self, u0, v0, u1, v1, z, col, depth=None):
        self.poly([(u0, v0, z), (u1, v0, z), (u1, v1, z), (u0, v1, z)], col, (u0 + u1 + v0 + v1) / 2 - 0.5 if depth is None else depth)

    def hip(self, u0, v0, u1, v1, z, rh, col):
        """A hipped roof: eaves at height z, ridge rh pixels higher."""
        d = (u0 + u1 + v0 + v1) / 2 + z / 100.0 + 0.5
        cu, cv = (u0 + u1) / 2, (v0 + v1) / 2
        if (u1 - u0) >= (v1 - v0):
            a, b = (u0 + (v1 - v0) / 2, cv, z + rh), (u1 - (v1 - v0) / 2, cv, z + rh)
        else:
            a, b = (cu, v0 + (u1 - u0) / 2, z + rh), (cu, v1 - (u1 - u0) / 2, z + rh)
        c = [(u0, v0, z), (u1, v0, z), (u1, v1, z), (u0, v1, z)]
        # back slopes first, then the two we see
        self.poly([c[0], c[1], b, a], shade(col, 0.95), d, shade(col, 0.6))
        self.poly([c[3], c[0], a], shade(col, 0.9), d, shade(col, 0.6))
        self.poly([c[1], c[2], b], shade(col, 1.0), d + 0.1, shade(col, 0.6))
        self.poly([c[2], c[3], a, b], shade(col, 0.72), d + 0.2, shade(col, 0.6))
        self.poly([c[1], c[2], b], shade(col, 0.88), d + 0.2, shade(col, 0.6))

    def face_quad(self, face, a0, a1, z0, z1, col, off=0.0):
        """A flat rectangle on the +c face ('c', along v from a0 to a1) or the +r face ('r', along u)."""
        if face == "c":
            pts = [(self.w + off, a0, z0), (self.w + off, a1, z0), (self.w + off, a1, z1), (self.w + off, a0, z1)]
            depth = self.w + a1 + 2
        else:
            pts = [(a0, self.h + off, z0), (a1, self.h + off, z0), (a1, self.h + off, z1), (a0, self.h + off, z1)]
            depth = self.h + a1 + 2
        self.poly(pts, col, depth + 50)

    def render(self):
        for depth, pts, col, outline in sorted(self.faces, key=lambda f: f[0]):
            self.d.polygon(pts, fill=col)
            if outline:
                self.d.line(pts + [pts[0]], fill=outline, width=SS)
        out = self.img.resize((self.W, self.H), Image.LANCZOS)
        return out


def facing_door(cv, rot, w, h, col=(70, 45, 30, 255), z1=18, width=0.34):
    """A door on the face the building looks at: rotation 0 faces +c, 1 faces +r (the other two are not visible)."""
    if rot == 0:
        m = h / 2
        cv.face_quad("c", m - width, m + width, 0, z1, col, 0.01)
    elif rot == 1:
        m = w / 2
        cv.face_quad("r", m - width, m + width, 0, z1, col, 0.01)


def windows(cv, rows, zs, col=(60, 78, 100, 255)):
    for (z0, z1) in zs:
        for k in range(1, rows + 1):
            f = k / (rows + 1)
            cv.face_quad("c", f * cv.h - 0.12, f * cv.h + 0.12, z0, z1, col, 0.01)
        for k in range(1, rows + 1):
            f = k / (rows + 1)
            cv.face_quad("r", f * cv.w - 0.12, f * cv.w + 0.12, z0, z1, col, 0.01)


WALL = (232, 214, 170, 255)
TIMBER = (172, 122, 78, 255)
STONE = (150, 150, 156, 255)
RED = (184, 78, 58, 255)
BLUE = (70, 112, 160, 255)
ORANGE = (222, 140, 60, 255)
THATCH = (205, 170, 90, 255)
SLATE = (96, 104, 120, 255)
GREEN = (110, 160, 70, 255)
FIELD1 = (146, 170, 70, 255)
FIELD2 = (126, 152, 58, 255)


def draw_house(cv, rot):
    cv.box(0.12, 0.12, 0.88, 0.88, 0, 30, WALL)
    cv.hip(0.04, 0.04, 0.96, 0.96, 30, 20, RED)
    facing_door(cv, rot, 1, 1, z1=16, width=0.16)
    windows(cv, 1, [(14, 24)])


def draw_farm(cv, rot):
    w, h = cv.w, cv.h
    cv.flat(0.04, 0.04, w - 0.04, h - 0.04, 1, (150, 112, 70, 255), 0)
    n = 0
    u = 0.15
    while u < w - 0.5:
        cv.flat(u, 0.5, min(u + 0.28, w - 0.1), h - 0.1, 2, FIELD1 if n % 2 == 0 else FIELD2, 1 + n * 0.01)
        u += 0.4
        n += 1
    cv.box(0.1, 0.1, 0.9, 0.7, 0, 26, (200, 80, 60, 255))
    cv.hip(0.04, 0.04, 0.96, 0.76, 26, 16, SLATE)
    facing_door(cv, rot, w, h, z1=14, width=0.2) if (w, h) == (1, 1) else None


def draw_dock(cv, rot):
    w, h = cv.w, cv.h
    cv.flat(0.0, 0.0, w, h, 6, (182, 140, 92, 255), 0)
    n = 6
    for k in range(n):
        f0 = k / n * w
        cv.flat(f0 + 0.02, 0.05, f0 + w / n - 0.02, h - 0.05, 7, (196, 154, 104, 255) if k % 2 == 0 else (178, 136, 90, 255), 0.5 + k * 0.01)
    for (uu, vv) in [(0.1, 0.1), (w - 0.1, 0.1), (0.1, h - 0.1), (w - 0.1, h - 0.1)]:
        cv.box(uu - 0.05, vv - 0.05, uu + 0.05, vv + 0.05, 0, 22, (110, 76, 50, 255), outline=False)
    cv.box(0.2, 0.25, 0.7, h - 0.25, 7, 34, TIMBER)
    cv.hip(0.12, 0.17, 0.78, h - 0.17, 34, 14, BLUE)
    facing_door(cv, rot, w, h, z1=22, width=0.12)


def draw_lumber(cv, rot):
    w, h = cv.w, cv.h
    cv.box(0.15, 0.15, 1.05, 1.05, 0, 24, TIMBER)
    cv.hip(0.08, 0.08, 1.12, 1.12, 24, 16, (110, 82, 60, 255))
    facing_door(cv, rot, w, h, z1=14, width=0.14) if False else None
    for k in range(3):  # a stack of logs
        cv.box(1.25 + k * 0.0, 0.25 + k * 0.5, 1.8, 0.65 + k * 0.5, 0, 9 + 0, (146, 100, 62, 255))
        cv.box(1.3, 0.3 + k * 0.5, 1.75, 0.6 + k * 0.5, 9, 17, (160, 112, 70, 255))


def draw_quarry(cv, rot):
    w, h = cv.w, cv.h
    cv.flat(0.04, 0.04, w - 0.04, h - 0.04, 1, (168, 140, 104, 255), 0)
    cv.box(0.15, 0.2, 0.75, 0.8, 0, 22, (170, 170, 176, 255))
    cv.box(0.9, 0.3, 1.4, 0.8, 0, 14, (134, 134, 140, 255))
    cv.box(1.2, 1.1, 1.8, 1.7, 0, 30, (156, 156, 162, 255))
    cv.box(0.3, 1.2, 0.8, 1.7, 0, 10, (186, 186, 190, 255))
    cv.box(1.1, 0.2, 1.3, 0.6, 14, 24, (120, 120, 126, 255))
    # a small crane
    cv.box(0.85, 1.3, 0.95, 1.4, 0, 42, (110, 80, 56, 255), outline=False)
    cv.box(0.85, 1.3, 1.5, 1.4, 42, 48, (110, 80, 56, 255), outline=False)


def draw_sawmill(cv, rot):
    w, h = cv.w, cv.h
    cv.box(0.12, 0.12, w - 0.12, h - 0.4, 0, 28, (190, 150, 100, 255))
    cv.hip(0.04, 0.04, w - 0.04, h - 0.32, 28, 16, (126, 70, 52, 255))
    cv.box(0.3, h - 0.34, 1.1, h - 0.1, 0, 8, (214, 182, 130, 255))
    cv.box(0.4, h - 0.3, 1.0, h - 0.14, 8, 14, (230, 200, 150, 255))
    cv.box(w - 0.5, h - 0.34, w - 0.2, h - 0.12, 0, 6, (150, 100, 66, 255))
    facing_door(cv, rot, w, h, z1=16, width=0.2)


def draw_bakery(cv, rot):
    w, h = cv.w, cv.h
    cv.box(0.12, 0.12, w - 0.12, h - 0.12, 0, 32, (238, 206, 150, 255))
    cv.hip(0.04, 0.04, w - 0.04, h - 0.04, 32, 20, ORANGE)
    cv.box(w - 0.5, 0.2, w - 0.32, 0.38, 32, 58, (150, 90, 70, 255))
    facing_door(cv, rot, w, h, z1=18, width=0.2)
    windows(cv, 1, [(14, 24)])


def draw_workshop(cv, rot):
    w, h = cv.w, cv.h
    cv.box(0.12, 0.12, w - 0.12, h - 0.12, 0, 36, STONE)
    cv.hip(0.04, 0.04, w - 0.04, h - 0.04, 36, 14, SLATE)
    cv.box(0.3, 0.2, 0.46, 0.36, 36, 60, (90, 90, 96, 255))
    facing_door(cv, rot, w, h, z1=20, width=0.2)
    windows(cv, 1, [(16, 28)])


def draw_warehouse(cv, rot):
    w, h = cv.w, cv.h
    cv.box(0.1, 0.1, w - 0.1, h - 0.1, 0, 44, (180, 140, 96, 255))
    cv.hip(0.02, 0.02, w - 0.02, h - 0.02, 44, 22, (138, 92, 66, 255))
    facing_door(cv, rot, w, h, col=(84, 56, 38, 255), z1=30, width=0.5)
    cv.box(w - 0.5, h - 0.35, w - 0.15, h - 0.12, 0, 12, (214, 182, 130, 255))


def draw_market(cv, rot):
    w, h = cv.w, cv.h
    cv.flat(0.05, 0.05, w - 0.05, h - 0.05, 1, (200, 180, 140, 255), 0)
    for (uu, vv) in [(0.2, 0.2), (w - 0.2, 0.2), (0.2, h - 0.2), (w - 0.2, h - 0.2)]:
        cv.box(uu - 0.04, vv - 0.04, uu + 0.04, vv + 0.04, 0, 34, (120, 84, 56, 255), outline=False)
    cv.box(0.45, 0.45, w - 0.45, h - 0.45, 0, 12, (190, 150, 100, 255))
    cv.box(0.55, 0.55, 0.9, 0.9, 12, 20, (210, 90, 60, 255))
    cv.box(w - 0.9, h - 0.9, w - 0.55, h - 0.55, 12, 20, (230, 190, 70, 255))
    # striped awning
    stripes = 6
    for k in range(stripes):
        a = 0.15 + (w - 0.3) * k / stripes
        b = 0.15 + (w - 0.3) * (k + 1) / stripes
        cv.poly([(a, 0.15, 34), (b, 0.15, 34), (b, h - 0.15, 34), (a, h - 0.15, 34)],
                (200, 60, 50, 255) if k % 2 == 0 else (240, 232, 220, 255), 40 + k * 0.01, (150, 50, 40, 255))
    cv.poly([(w - 0.15, 0.15, 34), (w - 0.15, h - 0.15, 34), (w - 0.15, h - 0.15, 24), (w - 0.15, 0.15, 24)], (190, 56, 46, 255), 44)
    cv.poly([(0.15, h - 0.15, 34), (w - 0.15, h - 0.15, 34), (w - 0.15, h - 0.15, 24), (0.15, h - 0.15, 24)], (160, 44, 38, 255), 44)


BUILDERS = {
    "house": draw_house, "farm": draw_farm, "fisher_dock": draw_dock, "lumber_camp": draw_lumber, "quarry": draw_quarry,
    "sawmill": draw_sawmill, "bakery": draw_bakery, "workshop": draw_workshop, "warehouse": draw_warehouse,
    "market": draw_market,
}
# base footprint (cells along c, cells along r) at rotation 0; odd rotations swap them. Kept in sync with data/buildings.json
# by the data validator (it fails when a building has no frames here).
SIZES = {"house": (1, 1), "farm": (2, 2), "fisher_dock": (2, 1), "lumber_camp": (2, 2), "quarry": (2, 2),
         "sawmill": (2, 2), "bakery": (2, 2), "workshop": (2, 2), "warehouse": (3, 2), "market": (3, 2)}
HEIGHTS = {"house": 52, "farm": 44, "fisher_dock": 50, "lumber_camp": 40, "quarry": 54, "sawmill": 46, "bakery": 80,
           "workshop": 84, "warehouse": 70, "market": 56}


def draw_building(bid, rot):
    bw, bh = SIZES[bid]
    w, h = (bw, bh) if rot % 2 == 0 else (bh, bw)
    cv = Canvas(w, h, HEIGHTS[bid])
    BUILDERS[bid](cv, rot)
    # footprints that are not symmetric are drawn for each rotation by the same code: the shapes do not turn, only the door does
    return cv.render(), w, h


# ---- icons ------------------------------------------------------------------------------------------------------


def icon(name):
    s = 28
    im = Image.new("RGBA", (s * SS, s * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)

    def q(*xy):
        return [v * SS for v in xy]

    if name == "coin":
        d.ellipse(q(3, 3, 25, 25), fill=(236, 188, 52, 255), outline=(168, 120, 20, 255), width=2 * SS)
        d.ellipse(q(8, 8, 20, 20), outline=(190, 140, 30, 255), width=2 * SS)
    elif name == "fish":
        d.ellipse(q(3, 8, 21, 20), fill=(96, 160, 210, 255), outline=(50, 100, 150, 255), width=SS)
        d.polygon(q(19, 14, 26, 7, 26, 21), fill=(96, 160, 210, 255), outline=(50, 100, 150, 255))
        d.ellipse(q(7, 11, 10, 14), fill=(255, 255, 255, 255))
    elif name == "grain":
        for k in range(3):
            x = 7 + k * 7
            d.line(q(x, 25, x, 6), fill=(150, 120, 50, 255), width=2 * SS)
            for j in range(3):
                d.ellipse(q(x - 3, 4 + j * 5, x + 3, 10 + j * 5), fill=(232, 196, 70, 255), outline=(170, 130, 30, 255))
    elif name == "wood":
        d.rectangle(q(3, 8, 25, 20), fill=(150, 104, 64, 255), outline=(100, 66, 36, 255), width=SS)
        d.ellipse(q(2, 8, 10, 20), fill=(214, 170, 110, 255), outline=(100, 66, 36, 255), width=SS)
        d.ellipse(q(4, 11, 8, 17), outline=(150, 104, 64, 255), width=SS)
    elif name == "stone":
        d.polygon(q(4, 21, 8, 10, 17, 6, 24, 12, 25, 21), fill=(160, 160, 166, 255), outline=(96, 96, 104, 255))
        d.polygon(q(8, 10, 17, 6, 15, 14), fill=(196, 196, 200, 255))
    elif name == "planks":
        for k in range(3):
            d.rectangle(q(3, 5 + k * 7, 25, 10 + k * 7), fill=(214, 176, 118, 255), outline=(150, 108, 64, 255), width=SS)
    elif name == "bread":
        d.ellipse(q(3, 8, 25, 22), fill=(214, 150, 70, 255), outline=(150, 92, 34, 255), width=SS)
        for k in range(3):
            d.line(q(8 + k * 5, 11, 10 + k * 5, 17), fill=(246, 214, 150, 255), width=SS)
    elif name == "tools":
        d.line(q(6, 22, 20, 8), fill=(120, 84, 52, 255), width=3 * SS)
        d.rectangle(q(15, 3, 25, 11), fill=(140, 140, 150, 255), outline=(80, 80, 90, 255), width=SS)
    return im.resize((s, s), Image.LANCZOS)


# ---- Kenney pieces ----------------------------------------------------------------------------------------------


def kenney(name):
    return Image.open(os.path.join(KENNEY, name + ".png")).convert("RGBA")


def rock_tile():
    """The rock terrain: the grass tile recoloured to grey stone with a few boulders on top (original art)."""
    im = kenney("grass")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a and g > r + 8 and g > b + 8:  # the green top and sides
                lum = int(0.45 * r + 0.45 * g + 0.1 * b)
                top = y < 52 and g > 150
                px[x, y] = (lum + (14 if top else -6), lum + (14 if top else -6), lum + (20 if top else -2), a)
    big = im.resize((im.width * SS, im.height * SS), Image.NEAREST)
    d = ImageDraw.Draw(big)
    for (cx, cy, rx, ry, c) in [(38, 24, 11, 6, (150, 150, 156, 255)), (60, 28, 8, 5, (128, 128, 134, 255)), (50, 18, 6, 4, (170, 170, 176, 255))]:
        d.ellipse([(cx - rx) * SS, (cy - ry) * SS, (cx + rx) * SS, (cy + ry) * SS], fill=c, outline=shade(c, 0.6), width=SS)
        d.ellipse([(cx - rx * 0.5) * SS, (cy - ry * 0.9) * SS, (cx + rx * 0.2) * SS, (cy - ry * 0.2) * SS], fill=shade(c, 1.2))
    return big.resize(im.size, Image.LANCZOS)


# road piece for each mask of road neighbours: N = -c (up-left), E = -r (up-right), S = +c (down-right), W = +r (down-left)
N, E, S, W = 1, 2, 4, 8
ROAD_PIECE = {
    0: "road", N: "roadNS", S: "roadNS", N | S: "roadNS", E: "roadEW", W: "roadEW", E | W: "roadEW",
    N | E: "roadNE", E | S: "roadES", S | W: "roadSW", W | N: "roadNW",
    N | E | S: "crossroadNES", E | S | W: "crossroadESW", N | S | W: "crossroadNSW", N | E | W: "crossroadNEW",
    N | E | S | W: "crossroad",
}
GOODS = ["fish", "grain", "wood", "stone", "planks", "bread", "tools"]


def main():
    items = []  # (frame name, image, pivot as (fx, fy) from the bottom-left, fy up)

    def add(name, im, pivot):
        items.append((name, im, pivot))

    def ground(name, im):
        # a ground tile is 100 x 65 (water 100 x 58): the top diamond is 100 x 50 at the top of the picture
        add(name, im, (0.5, 1 - 25 / im.height))

    ground("terrain.grass", kenney("grass"))
    ground("terrain.sand", kenney("beach"))
    ground("terrain.water", kenney("water"))
    ground("terrain.rock", rock_tile())
    for piece in sorted(set(ROAD_PIECE.values())):
        ground("road." + piece, kenney(piece))
    for i, t in enumerate(["coniferTall", "coniferShort", "coniferAltTall", "coniferAltShort", "treeTall", "treeShort"]):
        im = kenney(t)
        add("tree.%d" % i, im, (0.5, 0.0))
    for bid in BUILDERS:
        for rot in range(4):
            im, w, h = draw_building(bid, rot)
            add("building.%s.%d" % (bid, rot), im, (w / (w + h), 0.0))
    for g in GOODS + ["coin"]:
        add("icon." + g, icon(g), (0.5, 0.5))

    # shelf packing, tallest first, in a 2048 wide atlas with a 2 px gutter of transparent pixels
    gutter = 2
    order = sorted(range(len(items)), key=lambda i: (-items[i][1].height, items[i][0]))
    width = 2048
    x = y = row_h = 0
    placed = {}
    for i in order:
        name, im, pivot = items[i]
        if x + im.width + gutter > width:
            x, y, row_h = 0, y + row_h + gutter, 0
        placed[name] = (x + gutter // 2 + 0, y + gutter // 2 + 0)
        x += im.width + gutter
        row_h = max(row_h, im.height + gutter)
    atlas_h = y + row_h + gutter
    h = 1
    while h < atlas_h:
        h *= 2
    atlas = Image.new("RGBA", (width, h), (0, 0, 0, 0))
    frames = {}
    for name, im, pivot in items:
        px, py = placed[name]
        atlas.paste(im, (px, py))
        frames[name] = {"rect": [px, py, im.width, im.height], "pivot": [round(pivot[0], 4), round(pivot[1], 4)]}
    out_png = os.path.join(PROJECT, "assets", "atlas.png")
    atlas.save(out_png, optimize=True)
    data = {
        "$comment": "Generated by assets/src/make_atlas.py - do not edit. rect = [x, y, w, h] in atlas pixels (top-left origin); "
                    "pivot = Sprite.pivot (+Y up) that puts the frame's anchor (ground diamond centre, tree foot, building's bottom vertex) on the entity.",
        "texture": "assets/atlas.png",
        "size": [width, h],
        "roadFrames": {str(k): "road." + ROAD_PIECE[k] for k in sorted(ROAD_PIECE)},
        "frames": frames,
    }
    with open(os.path.join(PROJECT, "data", "atlas.json"), "w") as f:
        json.dump(data, f, indent=1, sort_keys=False)
        f.write("\n")
    print("atlas %dx%d, %d frames" % (width, h, len(frames)))


if __name__ == "__main__":
    os.makedirs(os.path.join(PROJECT, "data"), exist_ok=True)
    sys.exit(main())
