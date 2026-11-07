#!/usr/bin/env python3
"""Lantern Keep played by `play.auto` with the game's own bot (examples/lantern-keep/scripts/autoplay.js): every level is finished
from its scene, and the default start (the main menu, then the loading screen, then level 1-1) is played through its menus to the
exit. This is the coverage the old test-only bot had (a bot finishes every level) through the command the AI uses; the JS tests
(tests/play.test.js) drive the same bot step by step for what needs the game's events and progress.

The project is copied to a temporary folder first: play.auto writes its sessions into the project it plays.

usage: lantern_autoplay_test.py <path-to-factoria>
"""
import glob
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

FACTORIA = os.path.abspath(sys.argv[1])
GAME = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "examples", "lantern-keep")
failures = []


def check(cond, what, detail=""):
    print(("  ok    " if cond else "  FAIL  ") + what, flush=True)
    if not cond:
        failures.append(what)
        if detail:
            print(str(detail)[-3000:])
    return cond


def play_auto(project, args):
    """Runs `factoria call play.auto` in a child process; returns the result object or None."""
    try:
        r = subprocess.run([FACTORIA, "call", "--no-graphics", "--json", "--project", project, "play.auto", json.dumps(args)],
                           capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=240)
    except subprocess.TimeoutExpired:
        check(False, "play.auto %s answers within 240 s" % json.dumps(args))
        return None
    try:
        return json.loads(r.stdout)
    except ValueError:
        check(False, "play.auto %s prints a JSON result" % json.dumps(args), r.stdout + r.stderr)
        return None


def main():
    tmp = tempfile.mkdtemp(prefix="fa_lantern_autoplay_")
    try:
        project = os.path.join(tmp, "lantern-keep")
        shutil.copytree(GAME, project, ignore=shutil.ignore_patterns(".factoria", "screenshots", "replays"))
        scenes = sorted(os.path.relpath(p, project).replace(os.sep, "/") for p in glob.glob(os.path.join(project, "scenes", "levels", "*.scene.json")))
        check(len(scenes) >= 6, "the example has its levels (%d scenes)" % len(scenes))
        for scene in scenes:
            r = play_auto(project, {"scene": scene, "bot": "hook", "seconds": 90, "screenshots": False})
            if not check(r is not None and r.get("ok") is not False, "play.auto plays %s" % scene, r):
                continue
            check(r["ended"] == "won", "the bot finishes %s (ended %s: %s)" % (scene, r["ended"], r.get("endedWhy")), r)
            check(15 < r["gameSeconds"] < 60, "...in a level's time, not a stroll and not a minute (%s s)" % r["gameSeconds"])
            deaths = re.search(r"(\d+) deaths", r.get("endedWhy", ""))
            check(deaths is not None and int(deaths.group(1)) < 3, "...with fewer than 3 deaths (%s)" % r.get("endedWhy"))
            check(r["problems"] == [] and r["scriptErrors"] == [], "...and no problem found", r)
            check(r["bot"] == "hook", "...played by the game's own bot")
        # The default start: the main menu, Play, the loading screen, level 1-1.
        r = play_auto(project, {"seconds": 90, "screenshots": False})
        if check(r is not None and r.get("ok") is not False, "play.auto plays from the main scene", r):
            check(r["ended"] == "won", "the bot gets from the main menu through the loading screen to an exit (ended %s)" % r["ended"], r)
            names = [p["name"] for p in r["phases"]]
            check(len(names) >= 3 and names[0].endswith("menu.scene.json") and names[-1].endswith("1-1.scene.json"),
                  "...the phases are the scenes it went through (%s)" % names)
        # play.report reads the session of the last run unchanged.
        if r and r.get("session"):
            rep = subprocess.run([FACTORIA, "call", "--no-graphics", "--json", "--project", project, "play.report", json.dumps({"session": r["session"]})],
                                 capture_output=True, text=True, encoding="utf-8", errors="replace")
            try:
                doc = json.loads(rep.stdout)
            except ValueError:
                doc = {}
            check(doc.get("source") == "auto" and doc.get("ended") == r["ended"], "play.report reads the session (%s)" % rep.stdout[:200])
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


main()
if failures:
    print("%d check(s) failed: %s" % (len(failures), "; ".join(failures)))
    sys.exit(1)
