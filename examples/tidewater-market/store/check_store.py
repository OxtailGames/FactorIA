#!/usr/bin/env python3
"""Checks the store texts against the stores' length limits (run from anywhere: python3 store/check_store.py).

App Store: name 30, subtitle 30, promotional text 170, keywords 100, description 4000, what's new 4000.
Google Play: title 30, short description 80, full description 4000, release notes 500.
Exit code 1 when a file is missing, empty or too long.
"""
import os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
LIMITS = {"name.txt": 30, "subtitle.txt": 30, "promotional_text.txt": 170, "short_description.txt": 80,
          "keywords.txt": 100, "long_description.txt": 4000, "whats_new.txt": 500}
bad = 0
for lang in sorted(d for d in os.listdir(HERE) if os.path.isdir(os.path.join(HERE, d)) and len(d) <= 7 and d != "trailer"):  # every language folder
    for fn, lim in LIMITS.items():
        p = os.path.join(HERE, lang, fn)
        if not os.path.isfile(p):
            print(f"MISSING {lang}/{fn}")
            bad += 1
            continue
        n = len(open(p, encoding="utf-8").read().strip())
        status = "ok" if 0 < n <= lim else "BAD"
        if status == "BAD":
            bad += 1
        print(f"{status:3} {lang}/{fn}: {n}/{lim}")
    for fn in ("age_rating.md", "privacy.md", "urls.txt", "category.txt"):
        if not os.path.isfile(os.path.join(HERE, lang, fn)):
            print(f"MISSING {lang}/{fn}")
            bad += 1
sys.exit(1 if bad else 0)
