#!/usr/bin/env python3
"""Checks the Steam store texts (run from anywhere: python3 store/check_store.py).

Steam limits: short description 300 characters, long description (About this game) 8000, what's new 8000
(a patch note is also capped by the Steamworks form), name 80. Every language folder must have the same files, none
empty, and no text may contain a machine path or a placeholder marker. Exit code 1 on any problem.
"""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
LANGS = ("en", "ru", "th")
LIMITS = {"name.txt": 80, "short_description.txt": 300, "long_description.txt": 8000, "features.txt": 2000,
          "whats_new.txt": 8000}
SCRIPTS = {"ru": re.compile(r"[Ѐ-ӿ]"), "th": re.compile(r"[฀-๿]")}
bad = 0
for lang in LANGS:
    for fn, lim in LIMITS.items():
        p = os.path.join(HERE, lang, fn)
        if not os.path.isfile(p):
            print(f"MISSING {lang}/{fn}")
            bad += 1
            continue
        text = open(p, encoding="utf-8").read().strip()
        n = len(text)
        ok = 0 < n <= lim
        if ok and fn != "name.txt" and lang in SCRIPTS and not SCRIPTS[lang].search(text):
            print(f"BAD {lang}/{fn}: no {lang} letters (still English?)")
            ok = False
        if re.search(r"/Users/|[A-Z]:\\\\|TODO|FIXME|lorem", text, re.I):
            print(f"BAD {lang}/{fn}: path or placeholder in the text")
            ok = False
        if not ok:
            bad += 1
        print(f"{'ok' if ok else 'BAD':3} {lang}/{fn}: {n}/{lim}")
sys.exit(1 if bad else 0)
