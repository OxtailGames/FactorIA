#!/usr/bin/env python3
"""Builds assets/fonts/NotoSansKR-Regular-subset.ttf: Noto Sans KR cut to the characters of locales/*.json, the jamo and the syllables of KS X 1001 (names typed on the pad).

Run from anywhere, again whenever a Korean string changes (`factoria validate` fails on a character the font lacks):

    python3 -I assets/src/build_fonts.py [--source /path/to/NotoSansKR[wght].ttf] [--factoria /path/to/factoria]

The source is the variable font of the Google Fonts repository (SIL Open Font License 1.1). Without --source it is
downloaded to .factoria/tmp/ (git-ignored). The cut is done by the engine's own command `assets.subset_font` (no Python
font library): it keeps the characters of every language table plus Latin, punctuation and the full-width forms, keeps the
shaping tables and pins the variable font to wght 400. The OFL text is written next to the font (assets/fonts/OFL.txt).
Provenance (source URL, SHA-256 of the source, licence) is in assets.json.
"""
import argparse
import hashlib
import json
import os
import subprocess
import sys
import urllib.request

PROJECT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
URL = "https://github.com/google/fonts/raw/main/ofl/notosanskr/NotoSansKR%5Bwght%5D.ttf"
OFL_URL = "https://github.com/google/fonts/raw/main/ofl/notosanskr/OFL.txt"
OUT = "assets/fonts/NotoSansKR-Regular-subset.ttf"


def fetch(url, dest):
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    if not os.path.isfile(dest):
        print("downloading", url)
        urllib.request.urlretrieve(url, dest)
    return dest


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", help="NotoSansKR variable font (default: download)")
    ap.add_argument("--ofl", help="OFL.txt of the font (default: download)")
    ap.add_argument("--factoria", default="factoria", help="the factoria executable")
    a = ap.parse_args()
    tmp = os.path.join(PROJECT, ".factoria", "tmp")
    source = a.source or fetch(URL, os.path.join(tmp, "NotoSansKR[wght].ttf"))
    ofl = a.ofl or fetch(OFL_URL, os.path.join(tmp, "OFL.txt"))
    sha = hashlib.sha256(open(source, "rb").read()).hexdigest()
    os.makedirs(os.path.join(PROJECT, "assets", "fonts"), exist_ok=True)
    open(os.path.join(PROJECT, "assets", "fonts", "OFL.txt"), "wb").write(open(ofl, "rb").read())
    # The on-screen keyboard (scripts/ui/keyboard.js) types a save's name from jamo: keep the jamo and the 2350 syllables of
    # KS X 1001 (the ones a name is made of), not only the syllables of the tables.
    jamo = "".join(chr(c) for c in range(0x3131, 0x3164))
    syllables = "".join(bytes([hi, lo]).decode("euc-kr", errors="ignore") for hi in range(0xB0, 0xC9) for lo in range(0xA1, 0xFF))
    args = {"source": os.path.abspath(source), "out": OUT, "axes": {"wght": 400}, "locales": ["ko"], "keep": jamo + syllables}
    r = subprocess.run([a.factoria, "call", "--project", PROJECT, "assets.subset_font", json.dumps(args)],
                       capture_output=True, text=True)
    sys.stdout.write(r.stdout)
    sys.stderr.write(r.stderr)
    if r.returncode != 0:
        sys.exit(r.returncode)
    print("source sha256", sha)


if __name__ == "__main__":
    main()
