#!/usr/bin/env python3
"""Puts a space between Thai words in locales/th.json wherever a run of Thai would be too long to wrap.

Why: the engine breaks a line only at a space (and between CJK characters); Thai is written without spaces between words and
the engine has no Thai word segmentation, so a long run would stick out of its box (ENGINE_FEEDBACK FB-0040). The game's
workaround: no space-free run of Thai may be longer than MAX_RUN base letters (tests/languages.test.js checks it), so a
line can always break between two words. Short phrases keep the spaces a Thai writer puts between clauses.

    PYTHONPATH=<folder with pythainlp> python3 tools/thai_spaces.py          # rewrite locales/th.json
    python3 tools/thai_spaces.py --check                                     # list the runs that are too long (no pythainlp needed)

pythainlp (https://github.com/PyThaiNLP/pythainlp, `pip install pythainlp`) is used only here, never in the game. Run it after
editing a Thai string, then read the result: the dictionary cuts words, not meaning.
"""
import json
import os
import re
import sys

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATH = os.path.join(PROJECT, "locales", "th.json")
MAX_RUN = 16  # base letters (not tone marks or vowel signs above and below) per space-free run
MARKS = set(range(0x0E31, 0x0E32)) | set(range(0x0E34, 0x0E3B)) | set(range(0x0E47, 0x0E4F))


def base_letters(text):
    return sum(1 for c in text if 0x0E01 <= ord(c) <= 0x0E5B and ord(c) not in MARKS)


def runs(text):
    """Space-free runs of Thai (placeholders `{x}` count as one letter each)."""
    for r in re.split(r"[ \n]+", text):
        yield re.sub(r"\{[^}]*\}", "x", r)


def too_long(text):
    return [r for r in runs(text) if base_letters(r) > MAX_RUN]


def split_run(run, tokenize):
    parts = re.split(r"(\{[^}]*\})", run)
    words = []
    for part in parts:
        if part.startswith("{") or not re.search("[฀-๿]", part):
            words.append(part)
        else:
            words.extend(tokenize(part))
    chunks, cur = [], ""
    for w in words:
        if cur and base_letters(cur) + base_letters(w) > MAX_RUN:
            chunks.append(cur)
            cur = w
        else:
            cur += w
    if cur:
        chunks.append(cur)
    return " ".join(chunks)


def fix(text, tokenize):
    out = []
    for piece in re.split(r"( +|\n)", text):
        if piece.strip() and base_letters(re.sub(r"\{[^}]*\}", "x", piece)) > MAX_RUN:
            piece = split_run(piece, tokenize)
        out.append(piece)
    return "".join(out)


def walk(node, fn, path=""):
    if isinstance(node, str):
        return fn(path, node)
    return {k: (v if k.startswith("$") else walk(v, fn, f"{path}.{k}" if path else k)) for k, v in node.items()}


def main():
    with open(PATH, encoding="utf-8") as f:
        data = json.load(f)
    if "--check" in sys.argv:
        bad = []
        walk(data, lambda p, t: bad.extend((p, r) for r in too_long(t)) or t)
        for p, r in bad:
            print(f"{p}: {r}")
        sys.exit(1 if bad else 0)
    from pythainlp.tokenize import word_tokenize

    out = walk(data, lambda p, t: fix(t, lambda s: word_tokenize(s, engine="newmm")))
    with open(PATH, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
        f.write("\n")


if __name__ == "__main__":
    main()
