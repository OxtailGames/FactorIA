#!/usr/bin/env python3
"""The exported player checks a build: --input, --dump-state, --screenshot (docs/EXPORTING.md, "Checking an exported build").

usage: player_replay_test.py <path-to-factoria> <path-to-factoria_player>

Exports a small desktop game (a box a script moves while the `move_right` action is held), runs the exported player with
a replay, --dump-state and --screenshot, and compares them with `factoria run --headless` for the same replay and frame
count: the state dump must be byte-equal, the screenshot pixel-equal (both run offscreen on the same renderer; the
tolerance is 0). It also checks the errors that teach. The GPU is used (offscreen): label gpu.
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
failures = []


def check(cond, what, detail=""):
    print(("  ok    " if cond else "  FAIL  ") + what, flush=True)
    if not cond:
        failures.append(what)
        if detail:
            print(detail[-3000:])
    return cond


def read(path):
    with open(path, "rb") as f:
        return f.read()


def main():
    tmp = tempfile.mkdtemp(prefix="fa_player_replay_")
    try:
        game = os.path.join(tmp, "game")
        p = subprocess.run([FACTORIA, "new", game, "--template", "2d-empty", "--name", "Replay Game"], capture_output=True, text=True)
        if not check(p.returncode == 0, "factoria new", p.stdout + p.stderr):
            return
        os.makedirs(os.path.join(game, "scripts"), exist_ok=True)
        with open(os.path.join(game, "scripts", "mover.js"), "w", encoding="utf-8") as f:
            f.write('import { Behaviour, input, storage } from "factoria";\n'
                    "export default class Mover extends Behaviour {\n"
                    "  onUpdate() {\n"
                    "    const a = input.axis(\"move_left\", \"move_right\");\n"
                    "    this.entity.position.x += a * 4;\n"
                    "    if (a !== 0) storage.set(\"slot1\", { x: this.entity.position.x });  // the save a sandbox check looks for\n"
                    "  }\n"
                    "}\n")
        scene_file = os.path.join(game, "scenes", "main.scene.json")
        with open(scene_file, encoding="utf-8") as f:
            scene = json.load(f)
        scene["entities"].append({"id": "box", "name": "Box", "components": {
            "Transform": {"position": [0, 0, 0]},
            "Shape2D": {"shape": "rectangle", "size": [80, 80], "color": [1, 0.3, 0.2, 1]},
            "Script": {"path": "scripts/mover.js"}}})
        with open(scene_file, "w", encoding="utf-8") as f:
            json.dump(scene, f, indent=2)
        replay = os.path.join(tmp, "replay.json")
        with open(replay, "w", encoding="utf-8") as f:
            json.dump({"frames": {"3": {"press": ["move_right"]}, "30": {"release": ["move_right"]}}}, f)

        frames = "45"
        ref_state = os.path.join(tmp, "ref", "state.json")
        ref_shot = os.path.join(tmp, "ref", "shot.png")
        p = subprocess.run([FACTORIA, "run", game, "--headless", "--frames", frames, "--input", replay, "--state-out", ref_state,
                            "--screenshot-at", str(int(frames) - 1), "--screenshot-pattern", ref_shot], capture_output=True, text=True)
        if not check(p.returncode == 0 and os.path.isfile(ref_state) and os.path.isfile(ref_shot), "factoria run: state and screenshot", p.stdout + p.stderr):
            return
        no_input = os.path.join(tmp, "ref", "noinput.json")
        subprocess.run([FACTORIA, "run", game, "--headless", "--frames", frames, "--state-out", no_input], capture_output=True, text=True)
        check(os.path.isfile(no_input) and read(no_input) != read(ref_state), "the replay changes the state (the box moved)")

        exports = os.path.join(tmp, "export")
        p = subprocess.run([FACTORIA, "export", game, "--out", exports, "--player", PLAYER], capture_output=True, text=True)
        if not check(p.returncode == 0, "factoria export", p.stdout + p.stderr):
            return
        root = os.path.join(exports, "replay-game-" + HOST)
        if HOST == "macos":
            exe = os.path.join(root, "Replay Game.app", "Contents", "MacOS", "replay-game")
        else:
            exe = os.path.join(root, "replay-game" + (".exe" if HOST == "windows" else ""))
        home = os.path.join(tmp, "home")
        env = dict(os.environ, APPDATA=home, HOME=home, XDG_DATA_HOME=home)

        def play(*args, cwd=tmp):
            try:
                r = subprocess.run([exe, *args], env=env, capture_output=True, text=True, timeout=180, cwd=cwd)
                return r.returncode, r.stdout + r.stderr
            except subprocess.TimeoutExpired:
                return "timeout", ""

        out_state = os.path.join(tmp, "out", "state.json")  # the folder does not exist yet: the player makes it
        out_shot = os.path.join(tmp, "out", "shot.png")
        code, out = play("--frames", frames, "--input", replay, "--dump-state", out_state, "--screenshot", out_shot)
        if check(code == 0, "exported player with --input, --dump-state, --screenshot exits 0 (exit %s)" % code, out):
            check(os.path.isfile(out_state) and read(out_state) == read(ref_state), "the state dump equals factoria run's (byte for byte)")
            check(os.path.isfile(out_shot) and read(out_shot) == read(ref_shot), "the screenshot equals factoria run's (PNG bytes, tolerance 0)")
        # Relative paths resolve against the current directory.
        here = os.path.dirname(replay)
        code, out = play("--frames", frames, "--input", "replay.json", "--dump-state=rel_state.json", cwd=here)
        check(code == 0 and os.path.isfile(os.path.join(here, "rel_state.json")) and
              read(os.path.join(here, "rel_state.json")) == read(ref_state), "relative paths are relative to the current directory (exit %s)" % code, out)

        # --persist-storage: the save the replay makes lands in the user folder (HOME here), not in memory.
        saves = os.path.join(home, "Library", "Application Support") if HOST == "macos" else home
        slot = [os.path.join(d, f) for d, _, fs in os.walk(saves) for f in fs if f == "slot1.json"]
        check(not slot, "without --persist-storage the replay leaves no save file")
        code, out = play("--frames", frames, "--input", replay, "--persist-storage")
        slot = [os.path.join(d, f) for d, _, fs in os.walk(saves) for f in fs if f == "slot1.json"]
        if check(code == 0 and len(slot) == 1, "--persist-storage: the replay leaves a real save file (exit %s)" % code, out):
            with open(slot[0], encoding="utf-8") as f:
                saved = json.load(f)
            check(saved.get("key") == "slot1" and saved.get("value", {}).get("x", 0) > 0, "the save holds what the script stored: %s" % saved)
        code, out = play("--persist-storage")
        check(code == 2 and "--persist-storage" in out and "--frames" in out, "--persist-storage alone is a usage error (exit %s)" % code, out)

        code, out = play("--dump-state", out_state)
        check(code == 2 and "--frames" in out, "--dump-state without --frames is a usage error (exit %s)" % code, out)
        code, out = play("--frames", "5", "--input", os.path.join(tmp, "nope.json"))
        check(code == 2 and "nope.json" in out and "does not exist" in out, "a missing replay is exit 2 and names the file (exit %s)" % code, out)
        bad = os.path.join(tmp, "bad.json")
        with open(bad, "w", encoding="utf-8") as f:
            f.write('{"nothing": 1}')
        code, out = play("--frames", "5", "--input", bad)
        check(code == 2 and "Input replay must look like" in out, "a replay without frames is exit 2 and shows the format (exit %s)" % code, out)
        code, out = play("--frames", "5", "--screenshot")
        check(code == 2 and "--screenshot needs a file" in out, "--screenshot without a file is a usage error (exit %s)" % code, out)
        blocker = os.path.join(tmp, "blocker")
        with open(blocker, "w", encoding="utf-8") as f:
            f.write("x")
        code, out = play("--frames", "5", "--dump-state", os.path.join(blocker, "state.json"))
        check(code == 2 and "cannot write" in out, "an unwritable output path is exit 2 and says so (exit %s)" % code, out)

        # A script that throws: exit 1, like `factoria run`.
        with open(os.path.join(game, "scripts", "mover.js"), "w", encoding="utf-8") as f:
            f.write('import { Behaviour } from "factoria";\nexport default class Mover extends Behaviour {\n'
                    '  onUpdate() { throw new Error("boom on purpose"); }\n}\n')
        shutil.rmtree(exports)
        p = subprocess.run([FACTORIA, "export", game, "--out", exports, "--player", PLAYER], capture_output=True, text=True)
        if check(p.returncode == 0, "factoria export (throwing script)", p.stdout + p.stderr):
            code, out = play("--frames", "5", "--dump-state", out_state)
            check(code == 1 and "boom on purpose" in out, "a script error exits 1 and prints the error (exit %s)" % code, out)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


main()
if failures:
    print("%d check(s) failed: %s" % (len(failures), "; ".join(failures)))
    sys.exit(1)
print("player_replay_test: all checks passed")
