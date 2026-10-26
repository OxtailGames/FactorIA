#!/usr/bin/env python3
"""Builds assets/fonts/NotoSansSC-Regular-subset.ttf: the Simplified Chinese font of Tidewater Market, small enough to ship.

Why: DejaVu Sans, the engine's built-in font, has no Simplified Chinese. Google's Noto Sans JP is a 17 MB variable font, so this
script (1) instances it to the static Regular weight (wght 400; the variable font's default is Thin, 100, and the engine
draws a variable font's default instance), and (2) keeps only the characters the game can draw, with the layout tables.

Characters kept: every character of every string in locales/*.json (so a new Simplified Chinese string needs a re-run), printable
ASCII, the Chinese punctuation line breaking uses, Latin-1 (the French and Spanish letters), the full-width forms and the ten
ASCII digits.

The source font is NOT in the repository (17 MB). Get NotoSansSC[wght].ttf from
https://github.com/google/fonts/tree/main/ofl/notosansjp (SIL Open Font License 1.1) and run, from the project folder:

    PYTHONPATH=<folder with fontTools> python3 assets/fonts/make_subset.py --source path/to/NotoSansSC[wght].ttf

fontTools (https://github.com/fonttools/fonttools, `pip install fonttools`) is needed only here, never in the game.
Then `factoria validate`: it fails with the first characters (U+xxxx) of any string the font does not have.
`--check` only lists the characters of the locale files the existing subset lacks (it needs fontTools too).
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(HERE, "NotoSansSC-Regular-subset.ttf")

# Punctuation and symbols line breaking and the kinsoku rule need, plus the ones the strings use.
EXTRA = "、。，．·：；？！—…‥「」『』（）［］｛｝【】〈〉《》〔〕“”‘’※★☆♪←→↑↓＋－×÷＝％＄＃＆＊／＼｜“”«»¡¿\u00a0\u202f"


def locale_text():
    chars = set()

    def walk(v):
        if isinstance(v, str):
            chars.update(v)
        elif isinstance(v, dict):
            for x in v.values():
                walk(x)

    folder = os.path.join(PROJECT, "locales")
    for name in sorted(os.listdir(folder)):
        if name.endswith(".json"):
            with open(os.path.join(folder, name), encoding="utf-8") as f:
                walk(json.load(f))
    return chars


def wanted():
    chars = set(chr(c) for c in range(0x20, 0x7F))
    chars |= set(chr(c) for c in range(0xA1, 0x100))  # Latin-1 (the French and Spanish letters)
    chars |= set(chr(c) for c in range(0xFF01, 0xFF5F))  # full-width ASCII forms
    chars |= set(EXTRA)
    chars |= locale_text()
    return sorted(c for c in chars if c.isprintable() and not c.isspace() or c == " ")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--source", help="NotoSansSC[wght].ttf (the variable font)")
    ap.add_argument("--weight", type=int, default=400, help="wght of the instance (default 400, Regular)")
    ap.add_argument("--check", action="store_true", help="list the locale characters the subset lacks, write nothing")
    args = ap.parse_args()
    try:
        from fontTools.ttLib import TTFont
        from fontTools import subset
        from fontTools.varLib import instancer
    except ImportError:
        sys.exit("fontTools is missing: pip install fonttools, or set PYTHONPATH to a folder that has it.")

    if args.check:
        cmap = TTFont(OUT).getBestCmap()
        missing = [c for c in sorted(locale_text()) if ord(c) not in cmap and not c.isspace()]
        print("missing from the subset: " + (" ".join("U+%04X %s" % (ord(c), c) for c in missing) or "nothing"))
        sys.exit(1 if missing else 0)

    if not args.source:
        sys.exit("--source is required (the variable NotoSansSC[wght].ttf)")
    font = TTFont(args.source)
    font = instancer.instantiateVariableFont(font, {"wght": args.weight})
    options = subset.Options()
    options.layout_features = ["*"]  # keep the shaping tables (vertical forms, kerning, ...)
    options.name_IDs = ["*"]  # keep the license and copyright strings
    options.notdef_outline = True
    options.glyph_names = False
    options.hinting = False
    options.drop_tables += ["DSIG"]
    subsetter = subset.Subsetter(options)
    subsetter.populate(text="".join(wanted()))
    subsetter.subset(font)
    font.save(OUT)
    print("wrote %s (%d bytes, %d characters)" % (OUT, os.path.getsize(OUT), len(font.getBestCmap())))


if __name__ == "__main__":
    main()
