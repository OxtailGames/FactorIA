#!/usr/bin/env python3
"""factoria_player --frames N (docs/EXPORTING.md, "CI for your game").

usage: player_frames_test.py <path-to-factoria> <path-to-factoria_player>

The player draws N frames and exits 0; it exits 1 when a script failed by then, and 2 for a bad --frames value. It opens a
window, so the test carries the gpu label.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

FACTORIA = os.path.abspath(sys.argv[1])
PLAYER = os.path.abspath(sys.argv[2])
failures = []


def check(cond, what, detail=""):
    print(("  ok    " if cond else "  FAIL  ") + what, flush=True)
    if not cond:
        failures.append(what)
        if detail:
            print(detail[-3000:])
    return cond


def main():
    tmp = tempfile.mkdtemp(prefix="fa_player_frames_")
    try:
        game = os.path.join(tmp, "game")
        p = subprocess.run([FACTORIA, "new", game, "--template", "2d-empty", "--name", "Frames Game"], capture_output=True, text=True)
        if not check(p.returncode == 0, "factoria new", p.stdout + p.stderr):
            return
        home = os.path.join(tmp, "home")  # the player writes its log and saves into the user folder
        env = dict(os.environ, APPDATA=home, HOME=home, XDG_DATA_HOME=home)

        def play(*args):
            try:
                r = subprocess.run([PLAYER, game, *args], env=env, capture_output=True, text=True, timeout=120)
                return r.returncode, r.stdout + r.stderr
            except subprocess.TimeoutExpired:
                return "timeout", ""

        code, out = play("--frames", "5")
        check(code == 0, "--frames 5 draws five frames and exits 0 (exit %s)" % code, out)
        code, out = play("--frames=5")
        check(code == 0, "--frames=5 works too (exit %s)" % code, out)
        for bad in ("0", "abc", ""):
            code, out = play("--frames", bad)
            check(code == 2 and "--frames" in out, "--frames '%s' is a usage error (exit %s)" % (bad, code), out)

        # A script that throws every frame.
        os.makedirs(os.path.join(game, "scripts"), exist_ok=True)
        with open(os.path.join(game, "scripts", "boom.js"), "w", encoding="utf-8") as f:
            f.write('import { Behaviour } from "factoria";\n'
                    "export default class Boom extends Behaviour {\n"
                    '  onUpdate() { throw new Error("boom on purpose"); }\n'
                    "}\n")
        scene_file = os.path.join(game, "scenes", "main.scene.json")
        with open(scene_file, encoding="utf-8") as f:
            scene = json.load(f)
        scene["entities"].append({"id": "boom", "name": "Boom", "components": {"Script": {"path": "scripts/boom.js"}}})
        with open(scene_file, "w", encoding="utf-8") as f:
            json.dump(scene, f, indent=2)
        code, out = play("--frames", "5")
        check(code == 1 and "boom on purpose" in out, "a script error makes --frames exit 1 (exit %s)" % code, out)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


main()
if failures:
    print("%d check(s) failed: %s" % (len(failures), "; ".join(failures)))
    sys.exit(1)
print("player_frames_test: all checks passed")
