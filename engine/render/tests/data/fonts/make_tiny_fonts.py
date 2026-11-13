#!/usr/bin/env python3
"""Writes tiny_glyf.ttf and tiny_composite.ttf next to this script (pip install fonttools).

Two 700-byte TrueType fonts with outlines made here (no licence to carry): 'A' is a quadratic curve, 'B' a box, and the
composite font adds a glyph 'AB' (the codepoint 0x43) made of both. font_check_tests.cpp damages copies of them (a glyph
that includes itself, tables cut short) to test the check that runs before stb_truetype reads a font; tools/fuzz/corpus/font/
holds the same two files as seeds.
"""
import os
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen


def make_font(path, composite):
    fb = FontBuilder(1000, isTTF=True)
    names = ['.notdef', 'A', 'B', 'AB']
    fb.setupGlyphOrder(names)
    fb.setupCharacterMap({65: 'A', 66: 'B', 0x43: 'AB'} if composite else {65: 'A', 66: 'B'})

    def box(x0, y0, x1, y1):
        p = TTGlyphPen(None)
        p.moveTo((x0, y0)); p.lineTo((x0, y1)); p.lineTo((x1, y1)); p.lineTo((x1, y0)); p.closePath()
        return p.glyph()

    def tri():
        p = TTGlyphPen(None)
        p.moveTo((50, 0)); p.qCurveTo((250, 700), (450, 0)); p.closePath()
        return p.glyph()

    glyphs = {'.notdef': box(50, 0, 450, 700), 'A': tri(), 'B': box(100, 0, 400, 500)}
    pen = TTGlyphPen(glyphs)
    pen.addComponent('A', (1, 0, 0, 1, 0, 0))
    pen.addComponent('B', (1, 0, 0, 1, 500, 0))
    glyphs['AB'] = pen.glyph()
    fb.setupGlyf(glyphs)
    fb.setupHorizontalMetrics({n: (600, 50) for n in names})
    fb.setupHorizontalHeader(ascent=800, descent=-200)
    fb.setupNameTable({'familyName': 'Seed', 'styleName': 'Regular'})
    fb.setupOS2()
    fb.setupPost()
    fb.save(path)


here = os.path.dirname(os.path.abspath(__file__))
make_font(os.path.join(here, 'tiny_glyf.ttf'), False)
make_font(os.path.join(here, 'tiny_composite.ttf'), True)
