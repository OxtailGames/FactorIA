#!/usr/bin/env python3
"""Draws the achievement icons and the controller glyphs of Burrow Brigade (package P5). No source art is used: every shape is
computed here, so the files are original and CC0 (like the moles and the king of make_atlases.py).

  python3 -I make_online_art.py <out-dir>        # the project's assets/ folder

Writes:
  <out-dir>/achievements/<id>.png            64 x 64, one per achievement of factoria.json "platform"
  <out-dir>/glyphs/<family>/<slug>.png       64 x 64 button pictures for the families xbox, playstation, nintendo, steamdeck
The slug of a button is in scripts/game/glyphs.js (SLUGS). Only the Python standard library is used. Deterministic: the same
bytes every run.
"""
import math
import os
import struct
import sys
import zlib

N = 64
SS = 3  # samples per pixel side


def png(path, pix):
    raw = b"".join(b"\x00" + bytes(c for px in pix[y * N:(y + 1) * N] for c in px) for y in range(N))

    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)

    data = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", N, N, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)


class Canvas:
    def __init__(self):
        self.px = [(0, 0, 0, 0)] * (N * N)

    def shape(self, inside, color):
        """Paints `color` (r, g, b, a) where inside(x, y) is true, antialiased by supersampling."""
        r, g, b, a = color
        for y in range(N):
            for x in range(N):
                n = 0
                for sy in range(SS):
                    for sx in range(SS):
                        if inside(x + (sx + 0.5) / SS, y + (sy + 0.5) / SS):
                            n += 1
                if not n:
                    continue
                cov = n / (SS * SS) * a / 255
                br, bg, bb, ba = self.px[y * N + x]
                oa = cov + ba / 255 * (1 - cov)
                if oa <= 0:
                    continue
                f = lambda s, d: round((s * cov + d * (ba / 255) * (1 - cov)) / oa)
                self.px[y * N + x] = (f(r, br), f(g, bg), f(b, bb), round(oa * 255))

    def save(self, path):
        png(path, self.px)


def disc(cx, cy, r):
    return lambda x, y: (x - cx) ** 2 + (y - cy) ** 2 <= r * r


def rrect(x0, y0, x1, y1, r):
    def f(x, y):
        if x < x0 or x > x1 or y < y0 or y > y1:
            return False
        dx = max(x0 + r - x, 0, x - (x1 - r))
        dy = max(y0 + r - y, 0, y - (y1 - r))
        return dx * dx + dy * dy <= r * r
    return f


def poly(pts):
    def f(x, y):
        inside = False
        j = len(pts) - 1
        for i in range(len(pts)):
            xi, yi = pts[i]
            xj, yj = pts[j]
            if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi:
                inside = not inside
            j = i
        return inside
    return f


def seg(x0, y0, x1, y1, w):
    dx, dy = x1 - x0, y1 - y0
    L = dx * dx + dy * dy

    def f(x, y):
        t = 0 if L == 0 else max(0, min(1, ((x - x0) * dx + (y - y0) * dy) / L))
        px, py = x0 + t * dx, y0 + t * dy
        return (x - px) ** 2 + (y - py) ** 2 <= (w / 2) ** 2
    return f


def ring(cx, cy, r, w):
    return lambda x, y: (r - w / 2) ** 2 <= (x - cx) ** 2 + (y - cy) ** 2 <= (r + w / 2) ** 2


def union(*fs):
    return lambda x, y: any(f(x, y) for f in fs)


# 5 x 7 bitmap font for the few letters the glyphs need.
FONT = {
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    "B": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
    "X": ["10001", "10001", "01010", "00100", "01010", "10001", "10001"],
    "Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
    "L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
    "R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    "T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
    "Z": ["11111", "00001", "00010", "00100", "01000", "10000", "11111"],
    "1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
    "2": ["01110", "10001", "00001", "00110", "01000", "10000", "11111"],
}


def text(cv, s, cx, cy, scale, color):
    w = len(s) * 5 * scale + (len(s) - 1) * scale
    x0 = cx - w / 2
    y0 = cy - 7 * scale / 2
    for i, ch in enumerate(s):
        for ry, row in enumerate(FONT[ch]):
            for rx, bit in enumerate(row):
                if bit == "1":
                    px = x0 + i * 6 * scale + rx * scale
                    py = y0 + ry * scale
                    cv.shape(lambda x, y, px=px, py=py: px <= x < px + scale and py <= y < py + scale, color)


WHITE = (255, 255, 255, 255)
DARK = (38, 40, 48, 255)
GREY = (92, 96, 108, 255)


def button(cv, fill, ink, label):
    cv.shape(disc(32, 32, 28), DARK)
    cv.shape(disc(32, 32, 25), fill)
    text(cv, label, 32, 32, 4, ink)


def shoulder(cv, label, scale=3):
    cv.shape(rrect(4, 14, 60, 50, 10), DARK)
    cv.shape(rrect(7, 17, 57, 47, 8), GREY)
    text(cv, label, 32, 32, scale, WHITE)


def bars(cv):
    for y in (22, 32, 42):
        cv.shape(seg(20, y, 44, y, 5), WHITE)


def view(cv):
    cv.shape(rrect(18, 20, 38, 38, 3), WHITE)
    cv.shape(rrect(22, 24, 42, 44, 3), GREY)
    cv.shape(rrect(24, 26, 44, 46, 3), WHITE)


def small(cv, shape):
    cv.shape(rrect(8, 12, 56, 52, 12), DARK)
    cv.shape(rrect(11, 15, 53, 49, 10), GREY)
    shape(cv)


def write_glyphs(out):
    G = lambda fam, slug: os.path.join(out, "glyphs", fam, slug + ".png")
    face = {"a": ((70, 170, 90, 255), "A"), "b": ((205, 70, 64, 255), "B"), "x": ((70, 120, 210, 255), "X"), "y": ((220, 180, 50, 255), "Y")}
    for fam in ("xbox", "steamdeck"):
        for slug, (fill, lab) in face.items():
            cv = Canvas(); button(cv, fill, WHITE, lab); cv.save(G(fam, slug))
    # xbox shoulders and triggers, Steam Deck calls them L1 R1 L2 R2
    for slug, lab in (("lb", "LB"), ("rb", "RB"), ("lt", "LT"), ("rt", "RT")):
        cv = Canvas(); shoulder(cv, lab); cv.save(G("xbox", slug))
    for slug, lab in (("l1", "L1"), ("r1", "R1"), ("l2", "L2"), ("r2", "R2")):
        cv = Canvas(); shoulder(cv, lab); cv.save(G("steamdeck", slug))
    for fam in ("xbox", "steamdeck"):
        cv = Canvas(); small(cv, bars); cv.save(G(fam, "menu"))
        cv = Canvas(); small(cv, view); cv.save(G(fam, "view"))
    # PlayStation: coloured symbols on dark discs
    def sym(draw, col):
        cv = Canvas(); cv.shape(disc(32, 32, 28), DARK); cv.shape(disc(32, 32, 25), (58, 62, 78, 255)); draw(cv, col); return cv
    cross = lambda cv, c: (cv.shape(seg(20, 20, 44, 44, 6), c), cv.shape(seg(44, 20, 20, 44, 6), c))
    circle = lambda cv, c: cv.shape(ring(32, 32, 12, 5), c)
    square = lambda cv, c: cv.shape(lambda x, y: rrect(20, 20, 44, 44, 2)(x, y) and not rrect(25, 25, 39, 39, 1)(x, y), c)
    tri = lambda cv, c: cv.shape(lambda x, y: poly([(32, 17), (47, 44), (17, 44)])(x, y) and not poly([(32, 25), (40, 40), (24, 40)])(x, y), c)
    sym(cross, (110, 150, 235, 255)).save(G("playstation", "cross"))
    sym(circle, (225, 90, 85, 255)).save(G("playstation", "circle"))
    sym(square, (230, 140, 200, 255)).save(G("playstation", "square"))
    sym(tri, (90, 200, 150, 255)).save(G("playstation", "triangle"))
    for slug, lab in (("l1", "L1"), ("r1", "R1"), ("l2", "L2"), ("r2", "R2")):
        cv = Canvas(); shoulder(cv, lab); cv.save(G("playstation", slug))
    cv = Canvas(); small(cv, bars); cv.save(G("playstation", "options"))
    cv = Canvas(); small(cv, view); cv.save(G("playstation", "create"))
    # Nintendo: the bottom button is B
    for slug, lab in (("b", "B"), ("a", "A"), ("y", "Y"), ("x", "X")):
        cv = Canvas(); button(cv, (200, 60, 60, 255) if slug == "a" else (70, 74, 86, 255), WHITE, lab); cv.save(G("nintendo", slug))
    for slug, lab, sc in (("l", "L", 4), ("r", "R", 4), ("zl", "ZL", 3), ("zr", "ZR", 3)):
        cv = Canvas(); shoulder(cv, lab, sc); cv.save(G("nintendo", slug))
    plus = lambda cv: (cv.shape(seg(20, 32, 44, 32, 6), WHITE), cv.shape(seg(32, 20, 32, 44, 6), WHITE))
    minus = lambda cv: cv.shape(seg(20, 32, 44, 32, 6), WHITE)
    cv = Canvas(); small(cv, plus); cv.save(G("nintendo", "plus"))
    cv = Canvas(); small(cv, minus); cv.save(G("nintendo", "minus"))


def write_achievements(out):
    A = lambda name: os.path.join(out, "achievements", name + ".png")

    def base(cv, top, bottom):
        cv.shape(rrect(2, 2, 62, 62, 10), (30, 26, 34, 255))
        cv.shape(rrect(5, 5, 59, 59, 8), top)
        cv.shape(lambda x, y: rrect(5, 5, 59, 59, 8)(x, y) and y > 32, bottom)

    cv = Canvas(); base(cv, (62, 52, 70, 255), (52, 44, 60, 255))  # first_ore: a gem
    gem = [(32, 14), (48, 26), (40, 50), (24, 50), (16, 26)]
    cv.shape(poly(gem), (90, 205, 235, 255))
    cv.shape(poly([(32, 14), (48, 26), (32, 30)]), (170, 235, 250, 255))
    cv.shape(poly([(32, 30), (40, 50), (24, 50)]), (50, 140, 190, 255))
    cv.save(A("first_ore"))

    cv = Canvas(); base(cv, (64, 52, 44, 255), (54, 44, 38, 255))  # mole_rescuer: a mole face with a heart
    cv.shape(disc(32, 36, 17), (120, 100, 90, 255))
    cv.shape(disc(23, 22, 5), (120, 100, 90, 255)); cv.shape(disc(41, 22, 5), (120, 100, 90, 255))
    cv.shape(disc(26, 33, 2.6), (20, 20, 24, 255)); cv.shape(disc(38, 33, 2.6), (20, 20, 24, 255))
    cv.shape(disc(32, 42, 5), (235, 140, 160, 255))
    cv.shape(poly([(46, 10), (54, 10), (58, 15), (50, 24), (42, 15), (42, 11)]), (230, 70, 80, 255))
    cv.save(A("mole_rescuer"))

    cv = Canvas(); base(cv, (58, 44, 70, 255), (48, 36, 60, 255))  # mole_king: a crown
    cv.shape(poly([(12, 48), (14, 22), (24, 34), (32, 16), (40, 34), (50, 22), (52, 48)]), (240, 200, 70, 255))
    cv.shape(rrect(12, 46, 52, 54, 2), (210, 160, 40, 255))
    for x, c in ((24, (220, 70, 70, 255)), (32, (90, 190, 235, 255)), (40, (220, 70, 70, 255))):
        cv.shape(disc(x, 50, 2.6), c)
    cv.save(A("mole_king"))

    cv = Canvas(); base(cv, (36, 40, 74, 255), (30, 32, 62, 255))  # bright_stratum: a lit lamp
    for k in range(8):
        a = k * math.pi / 4
        cv.shape(seg(32 + math.cos(a) * 17, 32 + math.sin(a) * 17, 32 + math.cos(a) * 25, 32 + math.sin(a) * 25, 3.5), (250, 220, 110, 255))
    cv.shape(disc(32, 32, 13), (255, 232, 130, 255))
    cv.shape(disc(32, 32, 7), (255, 250, 220, 255))
    cv.save(A("bright_stratum"))

    cv = Canvas(); base(cv, (44, 62, 56, 255), (36, 52, 46, 255))  # full_house: four miners
    for i, (cx, cy) in enumerate(((20, 24), (44, 24), (20, 46), (44, 46))):
        col = ((235, 190, 70, 255), (110, 190, 235, 255), (235, 110, 100, 255), (130, 210, 130, 255))[i]
        cv.shape(disc(cx, cy, 8), col)
        cv.shape(rrect(cx - 8, cy - 11, cx + 8, cy - 3, 4), (250, 240, 200, 255))
    cv.save(A("full_house"))

    cv = Canvas(); base(cv, (62, 46, 40, 255), (52, 38, 34, 255))  # bug_squasher: a beetle with a cross
    cv.shape(disc(32, 36, 15), (70, 150, 90, 255))
    cv.shape(disc(32, 18, 7), (60, 120, 76, 255))
    for dx in (-1, 1):
        cv.shape(seg(32 + dx * 14, 30, 32 + dx * 24, 24, 3), (60, 120, 76, 255))
        cv.shape(seg(32 + dx * 15, 38, 32 + dx * 25, 38, 3), (60, 120, 76, 255))
        cv.shape(seg(32 + dx * 14, 46, 32 + dx * 24, 52, 3), (60, 120, 76, 255))
    cv.shape(seg(20, 24, 44, 48, 5), (230, 80, 70, 255)); cv.shape(seg(44, 24, 20, 48, 5), (230, 80, 70, 255))
    cv.save(A("bug_squasher"))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    write_achievements(sys.argv[1])
    write_glyphs(sys.argv[1])
