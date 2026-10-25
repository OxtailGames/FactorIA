#!/usr/bin/env python3
"""Builds assets/fonts/NotoSansThai-Regular-subset.ttf: the Thai font of Burrow Brigade, small enough to ship.

Why: DejaVu Sans, the engine's built-in font, has no Thai (it does have Cyrillic, so Russian needs no extra font).
Google's Noto Sans Thai is a variable font (weight and width axes), and the engine draws a variable font's default instance,
so this script (1) pins it to the static Regular weight at normal width (wght 400, wdth 100) and (2) keeps only the
characters the game can draw, with the layout tables (Thai needs them: tone marks and vowels are placed by GPOS/GSUB).

Characters kept: every character of every string in locales/*.json (so a new Thai string needs a re-run), printable ASCII
(the digits and Latin letters inside Thai sentences come from the built-in font, but a Thai-only Text still needs them), the
nikhahit U+0E4D (the engine draws sara am U+0E33 as U+0E4D + U+0E32), the nikhahit U+0E4D (the engine draws sara am U+0E33 as U+0E4D + U+0E32), the dotted circle U+25CC (the base fonts shaping engines draw under a lone mark) and the no-break and zero-width spaces.

The source font is NOT in the repository. Get NotoSansThai[wdth,wght].ttf from
https://github.com/google/fonts/tree/main/ofl/notosansthai (SIL Open Font License 1.1) and run, from the project folder:

    PYTHONPATH=<folder with fontTools> python3 assets/fonts/make_subset.py --source path/to/NotoSansThai[wdth,wght].ttf

fontTools (https://github.com/fonttools/fonttools, `pip install fonttools`) is needed only here, never in the game.
Then `factoria validate`: it fails with the first characters (U+xxxx) of any string the font chain does not have.
`--check` lists the Thai characters of the locale files that the existing subset lacks (it needs fontTools too).
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(HERE, "NotoSansThai-Regular-subset.ttf")


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


def thai_only(chars):
    """The Thai characters, plus what the engine draws instead of a decomposable one (sara am U+0E33 is drawn as U+0E4D U+0E32)."""
    import unicodedata

    out = set()
    for c in chars:
        out.update(unicodedata.normalize("NFKD", c))
    return {c for c in out if 0x0E00 <= ord(c) <= 0x0E7F}


def wanted():
    chars = set(chr(c) for c in range(0x20, 0x7F))
    chars |= {"\u00a0", "\u200b", "\u25cc", "\u0e4d"}  # U+0E4D: the engine draws sara am (U+0E33) as nikhahit + sara aa
    chars |= locale_text()
    return sorted(c for c in chars if c.isprintable() or c == "\u200b")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--source", help="NotoSansThai[wdth,wght].ttf (the variable font)")
    ap.add_argument("--weight", type=int, default=400, help="wght of the instance (default 400, Regular)")
    ap.add_argument("--check", action="store_true", help="list the Thai locale characters the subset lacks, write nothing")
    args = ap.parse_args()
    try:
        from fontTools.ttLib import TTFont
        from fontTools import subset
        from fontTools.varLib import instancer
    except ImportError:
        sys.exit("fontTools is missing: pip install fonttools, or set PYTHONPATH to a folder that has it.")

    if args.check:
        cmap = TTFont(OUT).getBestCmap()
        missing = [c for c in sorted(thai_only(locale_text())) if ord(c) not in cmap]
        print("missing from the subset: " + (" ".join("U+%04X %s" % (ord(c), c) for c in missing) or "nothing"))
        sys.exit(1 if missing else 0)

    if not args.source:
        sys.exit("--source is required (the variable NotoSansThai[wdth,wght].ttf)")
    font = TTFont(args.source)
    font = instancer.instantiateVariableFont(font, {"wght": args.weight, "wdth": 100})
    options = subset.Options()
    options.layout_features = ["*"]  # keep the shaping tables
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
