#!/usr/bin/env python3
"""Prints the FA_SHEEN_E table of engine/render/shaders/brdf_layers.glsl.

The table is the directional albedo E(roughness, cos view) of the sheen lobe (Charlie distribution D, Ashikhmin visibility V,
as in brdf_layers.glsl) integrated over the hemisphere with a midpoint rule: the shader scales the base layer by
1 - max(sheenColor) * E so the layers never add energy. Nodes: roughness 0.1 + 0.9 * (i / 6)^2 (7 rows), cos(view) = (j / 8)^2
(9 columns); the shader reads it with a bilinear lookup in those coordinates. Run `python3 tools/shaders/sheen_albedo.py` and paste
the output into the shader; `--check` also prints the error of the lookup against the integral (worst about 0.06, mean 0.003).
"""
import math
import sys

NR, NV, RMIN = 7, 9, 0.1


def charlie_d(r, ndh):
    a = r * r
    ia = 1.0 / a
    sin2 = max(1.0 - ndh * ndh, 0.0078125)
    return (2.0 + ia) * pow(sin2, ia * 0.5) / (2.0 * math.pi)


def ashikhmin_v(ndl, ndv):
    return min(max(1.0 / (4.0 * (ndl + ndv - ndl * ndv)), 0.0), 1.0)


def albedo(r, ndv, n=240, m=96):
    sv = math.sqrt(max(1.0 - ndv * ndv, 0.0))
    v = (sv, 0.0, ndv)
    total = 0.0
    for i in range(n):
        c = (i + 0.5) / n
        s = math.sqrt(1.0 - c * c)
        for j in range(m):
            ph = 2.0 * math.pi * (j + 0.5) / m
            l = (s * math.cos(ph), s * math.sin(ph), c)
            h = [l[0] + v[0], l[1] + v[1], l[2] + v[2]]
            ln = math.sqrt(sum(x * x for x in h))
            total += charlie_d(r, h[2] / ln) * ashikhmin_v(c, ndv) * c
    return min(total * 2.0 * math.pi / (n * m), 1.0)


def rnode(i):
    return RMIN + (1.0 - RMIN) * (i / (NR - 1)) ** 2


def vnode(j):
    return (j / (NV - 1)) ** 2


def main():
    tab = [[albedo(rnode(i), max(vnode(j), 0.01)) for j in range(NV)] for i in range(NR)]
    if "--check" in sys.argv:
        def look(r, v):
            fr = min(max(math.sqrt(max(r - RMIN, 0.0) / (1 - RMIN)) * (NR - 1), 0), NR - 1 - 1e-6)
            fv = min(max(math.sqrt(v) * (NV - 1), 0), NV - 1 - 1e-6)
            i, j = int(fr), int(fv)
            tr, tv = fr - i, fv - j
            a = tab[i][j] + (tab[i][j + 1] - tab[i][j]) * tv
            b = tab[i + 1][j] + (tab[i + 1][j + 1] - tab[i + 1][j]) * tv
            return a + (b - a) * tr
        worst = total = count = 0
        for k in range(34):
            r = RMIN + (1 - RMIN) * k / 33
            for q in range(1, 25):
                v = q / 24
                d = abs(albedo(r, v, 160, 64) - look(r, v))
                worst, total, count = max(worst, d), total + d, count + 1
        print("worst error %.3f, mean %.4f" % (worst, total / count))
    for i, row in enumerate(tab):
        print("    " + ", ".join("%.3f" % x for x in row) + ("," if i < NR - 1 else ");"))


if __name__ == "__main__":
    main()
