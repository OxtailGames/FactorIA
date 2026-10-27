#!/usr/bin/env python3
"""Checks the store texts: python3 -I store/check_store.py (from anywhere).

One folder per language under store/ (en today; P8 adds es, de, ko, he with the same five files). Limits are the strictest
of the stores: Steam's short description 300 characters, name 80 (Microsoft 100, App Store 30 is checked as a warning),
long description 8000, what's new 8000. Each language folder must have every file, none empty, and no text may contain a
machine path or a placeholder marker. Exit code 1 on any problem.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
LIMITS = {"name.txt": 80, "short_description.txt": 300, "long_description.txt": 8000, "features.txt": 2000,
          "whats_new.txt": 8000}
SCRIPTS = {"he": re.compile(r"[֐-׿]"), "ko": re.compile(r"[가-힯]")}
langs = sorted(d for d in os.listdir(HERE) if os.path.isdir(os.path.join(HERE, d)) and len(d) == 2)
bad = 0
for lang in langs:
    for fn, lim in LIMITS.items():
        p = os.path.join(HERE, lang, fn)
        if not os.path.isfile(p):
            print("MISSING %s/%s" % (lang, fn))
            bad += 1
            continue
        text = open(p, encoding="utf-8").read().strip()
        ok = 0 < len(text) <= lim
        if ok and fn != "name.txt" and lang in SCRIPTS and not SCRIPTS[lang].search(text):
            print("BAD %s/%s: no %s letters (still English?)" % (lang, fn, lang))
            ok = False
        if re.search(r"/Users/|[A-Z]:\\|TODO|FIXME|lorem", text, re.I):
            print("BAD %s/%s: path or placeholder in the text" % (lang, fn))
            ok = False
        if fn == "name.txt" and len(text) > 30:
            print("note %s/%s: the App Store name limit is 30 characters" % (lang, fn))
        bad += 0 if ok else 1
        print("%-3s %s/%s: %d/%d" % ("ok" if ok else "BAD", lang, fn, len(text), lim))
if not langs:
    print("no language folder")
    bad += 1
sys.exit(1 if bad else 0)
