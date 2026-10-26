#!/usr/bin/env python3
"""Packs every picture the map draws into ONE atlas (assets/atlas.png) and writes data/atlas.json.

Why one texture: the renderer batches sprites that share a texture, so a map of 1600 tiles is a handful of draw calls
with one atlas and thousands when two textures alternate (see ENGINE_FEEDBACK.json).

Inputs
  assets/src/kenney/*.png   Kenney "Isometric Roads" (CC0): terrain tiles, road pieces and trees, imported with assets.import.
  this file                 the placeholder art drawn by hand: the buildings (4 rotations each), the rock tile, the goods icons, the walkers (2 kinds x 4 directions).
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


def draw_mill(cv, rot):
    """A stone tower with a cone roof and four sails on the +c face."""
    w, h = cv.w, cv.h
    cu, cvv = w / 2, h / 2
    cv.box(cu - 0.55, cvv - 0.55, cu + 0.55, cvv + 0.55, 0, 52, (222, 208, 184, 255))
    cv.hip(cu - 0.66, cvv - 0.66, cu + 0.66, cvv + 0.66, 52, 24, (150, 84, 60, 255))
    # sails: two crossed bars with cloth, on the plane just outside the +c face of the tower
    ux = cu + 0.56
    reach = 0.78
    zr = 40
    for k, (dv, dz) in enumerate([(1, 1), (-1, 1), (-1, -1), (1, -1)]):
        cv.poly([(ux + 0.01, cvv, 44), (ux + 0.01, cvv + dv * reach, 44 + dz * zr), (ux + 0.01, cvv + dv * reach + 0.18 * dz, 44 + dz * zr - 0.18 * dv * 40),
                 (ux + 0.01, cvv + 0.18 * dz, 44 - 0.18 * dv * 40)], (240, 232, 214, 255), 90 + k * 0.01, (120, 100, 80, 255))
    cv.poly([(ux + 0.02, cvv - 0.07, 44 - 3), (ux + 0.02, cvv + 0.07, 44 - 3), (ux + 0.02, cvv + 0.07, 44 + 3), (ux + 0.02, cvv - 0.07, 44 + 3)], (96, 70, 50, 255), 95)
    cv.box(cu - 0.3, cvv + 0.55, cu + 0.3, cvv + 0.8, 0, 14, (200, 170, 120, 255))
    facing_door(cv, rot, w, h, z1=18, width=0.16)


def draw_smokehouse(cv, rot):
    """A dark timber shed with a tall chimney and a few puffs of smoke."""
    w, h = cv.w, cv.h
    cv.box(0.14, 0.14, w - 0.14, h - 0.14, 0, 34, (126, 92, 66, 255))
    cv.hip(0.06, 0.06, w - 0.06, h - 0.06, 34, 16, (84, 70, 62, 255))
    cv.box(w - 0.62, 0.22, w - 0.4, 0.44, 34, 62, (110, 100, 96, 255))
    for k, (du, dz, r) in enumerate([(0.0, 68, 0.1), (0.05, 76, 0.13), (0.12, 85, 0.16)]):
        u, v = w - 0.5 + du, 0.33 + du * 0.5
        cv.poly([(u - r, v - r, dz), (u + r, v - r, dz), (u + r, v + r, dz), (u - r, v + r, dz)], (190, 190, 196, 200 - k * 40), 120 + k)
    # fish racks on the side
    for k in range(3):
        cv.box(0.3 + k * 0.5, h - 0.12, 0.42 + k * 0.5, h + 0.05, 0, 3, (226, 160, 90, 255), outline=False)
    facing_door(cv, rot, w, h, col=(52, 36, 28, 255), z1=20, width=0.2)


def draw_pier(cv, rot):
    """A plank walkway on posts with a bollard and a crate, the berth of the ships (P5)."""
    w, h = cv.w, cv.h
    cv.flat(0.0, 0.0, w, h, 5, (170, 128, 84, 255), 0)
    n = 8
    for k in range(n):
        if w >= h:
            cv.flat(k / n * w + 0.02, 0.06, (k + 1) / n * w - 0.02, h - 0.06, 6, (200, 158, 108, 255) if k % 2 == 0 else (182, 140, 94, 255), 0.5 + k * 0.01)
        else:
            cv.flat(0.06, k / n * h + 0.02, w - 0.06, (k + 1) / n * h - 0.02, 6, (200, 158, 108, 255) if k % 2 == 0 else (182, 140, 94, 255), 0.5 + k * 0.01)
    for (uu, vv) in [(0.1, 0.1), (w - 0.1, 0.1), (0.1, h - 0.1), (w - 0.1, h - 0.1)]:
        cv.box(uu - 0.06, vv - 0.06, uu + 0.06, vv + 0.06, 0, 16, (96, 66, 44, 255), outline=False)
    cv.box(w / 2 - 0.1, h / 2 - 0.1, w / 2 + 0.1, h / 2 + 0.1, 6, 20, (70, 60, 56, 255))
    cv.box(0.2, 0.2, 0.5, 0.5 if h > 0.6 else h - 0.2, 6, 20, (146, 100, 62, 255))


BUILDERS = {
    "pier": draw_pier,
    "house": draw_house, "farm": draw_farm, "fisher_dock": draw_dock, "lumber_camp": draw_lumber, "quarry": draw_quarry,
    "sawmill": draw_sawmill, "mill": draw_mill, "bakery": draw_bakery, "smokehouse": draw_smokehouse,
    "workshop": draw_workshop, "warehouse": draw_warehouse, "market": draw_market,
}
# base footprint (cells along c, cells along r) at rotation 0; odd rotations swap them. Kept in sync with data/buildings.json
# by the data validator (it fails when a building has no frames here).
SIZES = {"house": (1, 1), "farm": (2, 2), "fisher_dock": (2, 1), "lumber_camp": (2, 2), "quarry": (2, 2),
         "sawmill": (2, 2), "mill": (2, 2), "bakery": (2, 2), "smokehouse": (2, 2), "workshop": (2, 2), "warehouse": (3, 2),
         "market": (3, 2), "pier": (3, 1)}
HEIGHTS = {"house": 52, "farm": 44, "fisher_dock": 50, "lumber_camp": 40, "quarry": 54, "sawmill": 46, "bakery": 80,
           "workshop": 84, "warehouse": 70, "market": 56, "mill": 100, "smokehouse": 96, "pier": 24}


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
    elif name == "flour":
        d.polygon(q(6, 24, 4, 11, 9, 5, 19, 5, 24, 11, 22, 24), fill=(236, 226, 204, 255), outline=(150, 130, 96, 255))
        d.rectangle(q(8, 4, 20, 8), fill=(200, 180, 140, 255), outline=(150, 130, 96, 255))
        d.ellipse(q(10, 13, 18, 20), fill=(214, 198, 166, 255))
    elif name == "smoked_fish":
        d.ellipse(q(3, 8, 21, 20), fill=(170, 112, 60, 255), outline=(100, 62, 30, 255), width=SS)
        d.polygon(q(19, 14, 26, 7, 26, 21), fill=(170, 112, 60, 255), outline=(100, 62, 30, 255))
        d.ellipse(q(7, 11, 10, 14), fill=(250, 240, 220, 255))
        d.line(q(6, 24, 10, 20), fill=(150, 150, 156, 255), width=SS)
        d.line(q(14, 24, 17, 21), fill=(150, 150, 156, 255), width=SS)
    elif name == "pop":
        d.ellipse(q(9, 3, 19, 13), fill=(240, 200, 160, 255), outline=(150, 110, 70, 255), width=SS)
        d.polygon(q(5, 26, 7, 15, 21, 15, 23, 26), fill=(86, 130, 190, 255), outline=(50, 80, 130, 255))
    elif name == "tools":
        d.line(q(6, 22, 20, 8), fill=(120, 84, 52, 255), width=3 * SS)
        d.rectangle(q(15, 3, 25, 11), fill=(140, 140, 150, 255), outline=(80, 80, 90, 255), width=SS)
    elif name == "star":
        import math
        pts = []
        for k in range(10):
            r = 12 if k % 2 == 0 else 5.2
            a = -math.pi / 2 + k * math.pi / 5
            pts.append((14 + r * math.cos(a), 14.5 + r * math.sin(a)))
        d.polygon(q(*[v for pt in pts for v in pt]), fill=(240, 196, 60, 255), outline=(170, 120, 20, 255))
    elif name == "ship":
        d.polygon(q(3, 17, 25, 17, 21, 24, 7, 24), fill=(140, 96, 60, 255), outline=(90, 58, 34, 255))
        d.line(q(14, 17, 14, 4), fill=(90, 58, 34, 255), width=2 * SS)
        d.polygon(q(15, 5, 24, 15, 15, 15), fill=(240, 236, 220, 255), outline=(170, 160, 140, 255))
    return im.resize((s, s), Image.LANCZOS)


# ---- ships (P5) -------------------------------------------------------------------------------------------------
# A ship is 140 x 96 px, pivot at the bottom middle (the waterline centre). heading 0..3 as the walkers: 0 = +c (sails towards
# the lower right), 1 = +r (lower left), 2 = -c, 3 = -r. The three classes differ in size, hull and sail colours.
SHIP_CLASSES = {
    # name: (length in cells, hull colour, sail colour, masts)
    "skiff": (0.9, (150, 106, 68, 255), (236, 230, 210, 255), 1),
    "cog": (1.3, (118, 80, 52, 255), (222, 214, 190, 255), 2),
    "carrack": (1.7, (96, 62, 44, 255), (190, 60, 56, 255), 3),
}


def ship(cls, heading):
    length, hull, sail, masts = SHIP_CLASSES[cls]
    W, H = 140, 96
    im = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    ax = {0: (1, 1), 1: (-1, 1), 2: (-1, -1), 3: (1, -1)}[heading]  # screen direction of the keel (x, y) before scaling
    ox, oy = W / 2, H - 22

    def pt(u, v, z):  # u along the keel (cells), v across (cells), z up in px
        # the cross axis is the other iso axis: keel (a, b) -> cross (-a, b)
        cx, cy = -ax[0] * 50, ax[1] * 25
        kx, ky = ax[0] * 50, ax[1] * 25
        return ((ox + kx * u + cx * v) * SS, (oy + ky * u + cy * v - z) * SS)

    half = length / 2
    wd = 0.2
    # shadow on the water
    d.polygon([pt(-half - 0.1, -wd - 0.05, 0), pt(half + 0.2, -wd - 0.05, 0), pt(half + 0.2, wd + 0.05, 0), pt(-half - 0.1, wd + 0.05, 0)], fill=(10, 40, 70, 70))
    # hull: bottom outline, then the two sides and the deck
    bow = (half + 0.25, 0, 7)
    deck = [pt(-half, -wd, 8), pt(half, -wd, 8), pt(*bow), pt(half, wd, 8), pt(-half, wd, 8)]
    side_a = [pt(-half, wd, 8), pt(half, wd, 8), pt(half - 0.15, wd * 0.5, 0), pt(-half + 0.1, wd * 0.6, 0)]
    side_b = [pt(-half, -wd, 8), pt(half, -wd, 8), pt(half - 0.15, -wd * 0.5, 0), pt(-half + 0.1, -wd * 0.6, 0)]
    for poly, k in ((side_a, 0.72), (side_b, 0.9)):
        d.polygon(poly, fill=shade(hull, k), outline=shade(hull, 0.5))
    d.polygon(deck, fill=shade(hull, 1.25), outline=shade(hull, 0.5))
    # masts and sails (the sail is a quad across the ship)
    for m in range(masts):
        u = (m - (masts - 1) / 2) * (length * 0.55 / max(1, masts - 1) if masts > 1 else 0)
        top = 44 if cls != "skiff" else 38
        d.line([pt(u, 0, 8), pt(u, 0, top + 6)], fill=shade(hull, 0.5), width=2 * SS)
        sw = 0.28 if masts > 1 else 0.3
        quad = [pt(u, -sw, top), pt(u, sw, top), pt(u + 0.05, sw, 16), pt(u + 0.05, -sw, 16)]
        d.polygon(quad, fill=sail, outline=shade(sail, 0.6))
    return im.resize((W, H), Image.LANCZOS)


# ---- walkers ----------------------------------------------------------------------------------------------------
# A walker is 18 x 30 px, feet at the bottom middle. dir 0 = +c (walks towards the lower right), 1 = +r (lower left),
# 2 = -c (upper left, we see the back), 3 = -r (upper right, back). The two kinds differ in colour and the carrier's sack.


def walker(kind, direction):
    W, H = 18, 30
    im = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)

    def q(*xy):
        return [v * SS for v in xy]

    coat = (70, 110, 168, 255) if kind == "villager" else (176, 108, 56, 255)
    pants = (74, 64, 56, 255)
    skin = (240, 200, 160, 255)
    hair = (84, 58, 40, 255)
    lean = {0: 1.0, 1: -1.0, 2: -0.6, 3: 0.6}[direction]
    back = direction in (2, 3)
    # shadow
    d.ellipse(q(3, 25, 15, 30), fill=(0, 0, 0, 60))
    # legs
    d.line(q(8 - lean, 19, 7 - lean * 1.5, 27), fill=pants, width=2 * SS)
    d.line(q(10 + lean, 19, 11 + lean * 1.5, 27), fill=pants, width=2 * SS)
    # sack on the back of a carrier
    if kind == "carrier":
        sx = 9 - lean * 4
        d.ellipse(q(sx - 4, 8, sx + 4, 18), fill=(214, 190, 130, 255), outline=(140, 110, 60, 255), width=SS)
    # torso
    d.polygon(q(5.5 + lean * 0.5, 19, 6.5, 10, 11.5, 10, 12.5 + lean * 0.5, 19), fill=coat, outline=shade(coat, 0.6))
    # head
    d.ellipse(q(6, 2, 12, 9), fill=hair if back else skin, outline=shade(skin, 0.6), width=SS)
    if not back:
        ex = 9 + lean * 1.4
        d.ellipse(q(ex - 0.5, 5, ex + 0.7, 6.2), fill=(40, 30, 24, 255))
        d.pieslice(q(5.6, 1.4, 12.4, 8), 180, 360, fill=hair)
    return im.resize((W, H), Image.LANCZOS)


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
WALKER_KINDS = ["villager", "carrier"]
GOODS = ["fish", "grain", "wood", "stone", "planks", "bread", "tools", "flour", "smoked_fish", "pop"]
EXTRA_ICONS = ["star", "ship"]


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
    for g in GOODS + ["coin"] + EXTRA_ICONS:
        add("icon." + g, icon(g), (0.5, 0.5))
    for cls in SHIP_CLASSES:
        for heading in range(4):
            add("ship.%s.%d" % (cls, heading), ship(cls, heading), (0.5, 22 / 96))
    for kind in WALKER_KINDS:
        for direction in range(4):
            add("walker.%s.%d" % (kind, direction), walker(kind, direction), (0.5, 0.0))

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
