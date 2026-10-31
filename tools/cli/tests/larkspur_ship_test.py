#!/usr/bin/env python3
"""Larkspur Lodge's shipping check that needs no click: the exported player plays a replay that presses Play, skips the intro,
opens Pause, saves in slot 1 and names it, with --persist-storage, and leaves a real save file in the user folder
(LL/FB-0801; examples/larkspur-lodge/SHIPPING.md section 4). The same run inside the Mac App Store sandbox is the by-hand
step of that file: here HOME (APPDATA, XDG_DATA_HOME) is a temporary folder, which is where the sandbox container is.

usage: larkspur_ship_test.py <path-to-factoria> <path-to-factoria_player>
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

FACTORIA = os.path.abspath(sys.argv[1])
PLAYER = os.path.abspath(sys.argv[2])
HOST = {"darwin": "macos", "win32": "windows"}.get(sys.platform, "linux")
GAME = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "examples", "larkspur-lodge")
failures = []


def check(cond, what, detail=""):
    print(("  ok    " if cond else "  FAIL  ") + what, flush=True)
    if not cond:
        failures.append(what)
        if detail:
            print(detail[-3000:])
    return cond


def saves_named(root, name):
    return [os.path.join(d, f) for d, _, fs in os.walk(root) for f in fs if f == name]


def main():
    tmp = tempfile.mkdtemp(prefix="fa_larkspur_ship_")
    try:
        exports = os.path.join(tmp, "export")
        p = subprocess.run([FACTORIA, "export", os.path.abspath(GAME), "--out", exports, "--player", PLAYER], capture_output=True, text=True)
        if not check(p.returncode == 0, "factoria export larkspur-lodge", p.stdout + p.stderr):
            return
        root = os.path.join(exports, "larkspur-lodge-" + HOST)
        if HOST == "macos":
            exe = os.path.join(root, "Larkspur Lodge.app", "Contents", "MacOS", "larkspur-lodge")
        else:
            exe = os.path.join(root, "larkspur-lodge" + (".exe" if HOST == "windows" else ""))
        home = os.path.join(tmp, "home")
        os.makedirs(home)
        env = dict(os.environ, APPDATA=home, HOME=home, XDG_DATA_HOME=home)
        replay = os.path.abspath(os.path.join(GAME, "tests", "replays", "save_slot1.json"))
        screen = os.path.join(tmp, "after.png")

        def play(*args):
            try:
                r = subprocess.run([exe, *args], env=env, capture_output=True, text=True, timeout=240, cwd=tmp)
                return r.returncode, r.stdout + r.stderr
            except subprocess.TimeoutExpired:
                return "timeout", ""

        code, out = play("--frames", "520", "--input", replay, "--screenshot", screen)
        check(code == 0, "the replay plays on the exported player (exit %s)" % code, out)
        check(not saves_named(home, "slot1.json"), "in memory (the default) the replay leaves no save file")
        code, out = play("--frames", "520", "--input", replay, "--persist-storage", "--screenshot", screen)
        check(code == 0, "the replay plays with --persist-storage (exit %s)" % code, out)
        slot = saves_named(home, "slot1.json")
        if check(len(slot) == 1, "the save of slot 1 is a real file in the user folder", out):
            with open(slot[0], encoding="utf-8") as f:
                saved = json.load(f)
            record = json.loads(saved.get("value", "{}")) if isinstance(saved.get("value"), str) else saved.get("value", {})
            check(saved.get("key") == "slot1" and bool(record), "the file holds the slot record: %s" % str(saved)[:200])
        check(len(saves_named(home, "slot_auto.json")) == 1, "the autosave of the chapter start is there too")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


main()
if failures:
    print("%d check(s) failed: %s" % (len(failures), "; ".join(failures)))
    sys.exit(1)
print("larkspur_ship_test: all checks passed")
