#!/usr/bin/env python3
"""End-to-end test of native plugins (docs/EXTENDING.md, "Native plugins").

usage: plugin_test.py <path-to-factoria> <path-to-the-example-plugin-library>

The library is platforms/plugin/src/plugin.c (the template project.new_plugin writes) built by the engine's build as
the plugin "example". The test makes a game, scaffolds the plugin in a private folder outside it (${VARIABLE} path),
checks `factoria validate` before and after the build is in place, runs the game headless (`plugins.example.add(1, 2)`
and the command example.info from a script, and `factoria call example.info`), exports it for this computer and runs
the exported game, which must find the plugin next to its executable.
"""
import json
import os
import platform
import shutil
import subprocess
import sys
import tempfile

FACTORIA = os.path.abspath(sys.argv[1])
LIBRARY = os.path.abspath(sys.argv[2])
HOST = {"Windows": "windows", "Darwin": "macos"}.get(platform.system(), "linux")
failures = []

PROBE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "plugin_probe.js")


def check(cond, what, detail=""):
    print(("  ok    " if cond else "  FAIL  ") + what, flush=True)
    if not cond:
        failures.append(what)
        if detail:
            print(detail[-3000:])
    return cond


def run(args, env=None, timeout=180):
    p = subprocess.run([FACTORIA] + args, env={**os.environ, **(env or {})}, capture_output=True, text=True, timeout=timeout)
    return p.returncode, p.stdout, p.stderr


def main():
    tmp = tempfile.mkdtemp(prefix="fa_plugin_test_")
    try:
        game = os.path.join(tmp, "game")
        private = os.path.join(tmp, "private")
        env = {"FA_TEST_PLUGINS": private}
        code, out, err = run(["new", game, "--template", "2d-empty", "--name", "Plugin Game"])
        if not check(code == 0, "factoria new", out + err):
            return

        # The plugin, outside the game's folder: its path goes through an environment variable.
        args = json.dumps({"name": "example", "path": "${FA_TEST_PLUGINS}/example"})
        code, out, err = run(["call", "project.new_plugin", args, "--project", game], env=env)
        check(code == 0, "project.new_plugin", out + err)
        folder = os.path.join(private, "example")
        java = "android/src/main/java/factoria/plugin/example/Plugin.java"  # the Gradle module of the Android build
        for f in ["src/plugin.c", "include/fa_plugin.h", "CMakeLists.txt", "README.md", "android/build.gradle",
                  "android/consumer-rules.pro", "android/src/main/AndroidManifest.xml", java]:
            check(os.path.isfile(os.path.join(folder, f)), "the plugin has " + f)
        with open(os.path.join(folder, java), encoding="utf-8") as f:
            check("package factoria.plugin.example;" in f.read(), "the Java class is in the plugin's package")
        for dirpath, _, names in os.walk(folder):
            for name in names:
                path = os.path.join(dirpath, name)
                with open(path, encoding="utf-8") as f:
                    check("{{NAME}}" not in path + f.read(), "the template's {{NAME}} is replaced in " + path)
        with open(os.path.join(game, "factoria.json"), encoding="utf-8") as f:
            declared = json.load(f).get("plugins", {}).get("example", {})
        check(declared == {"path": "${FA_TEST_PLUGINS}/example", "platforms": [HOST]}, "factoria.json declares it: %s" % declared)
        code, out, err = run(["call", "project.new_plugin", args, "--project", game], env=env)
        check(code != 0 and "already declared" in out + err, "a second project.new_plugin of the same name fails", out + err)
        code, out, err = run(["call", "project.new_plugin", '{"name": "scene"}', "--project", game], env=env)
        check(code != 0 and "a name the engine uses" in out + err, "an engine area is not a plugin name", out + err)

        # validate: the build is missing, then the variable is not set.
        code, out, err = run(["validate", game], env=env)
        check(code != 0 and "build is missing" in out + err, "validate reports the missing build", out + err)
        code, out, err = run(["validate", game], env={"FA_TEST_PLUGINS": ""})
        check(code != 0 and "FA_TEST_PLUGINS" in out + err, "validate names the variable that is not set", out + err)

        # The build, where the plugin's CMakeLists.txt would copy it.
        dest = os.path.join(folder, HOST)
        os.makedirs(dest, exist_ok=True)
        shutil.copy(LIBRARY, os.path.join(dest, {"windows": "example.dll", "macos": "libexample.dylib"}.get(HOST, "libexample.so")))
        code, out, err = run(["validate", game], env=env)
        check(code == 0, "validate passes with the build in place", out + err)

        # factoria run: a script calls the function and the command.
        os.makedirs(os.path.join(game, "scripts"), exist_ok=True)
        shutil.copy(PROBE, os.path.join(game, "scripts", "probe.js"))
        scene_file = os.path.join(game, "scenes", "main.scene.json")
        with open(scene_file, encoding="utf-8") as f:
            scene = json.load(f)
        scene["entities"].append({"id": "probe", "name": "Probe", "components": {"Script": {"path": "scripts/probe.js", "props": {"quitAfter": 5}}}})
        with open(scene_file, "w", encoding="utf-8") as f:
            json.dump(scene, f, indent=2)
        code, out, err = run(["run", game, "--headless", "--frames", "10"], env=env)
        check(code == 0, "factoria run: the probe script gets add(1, 2) = 3 and example.info", out + err)
        code, out, err = run(["call", "example.info", "--project", game], env=env)
        check(code == 0 and '"example"' in out, "factoria call example.info", out + err)

        # factoria export, then the exported game alone (no environment variable: the library ships with it).
        exports = os.path.join(tmp, "export")
        code, out, err = run(["export", game, "--out", exports], env=env)
        if not check(code == 0, "factoria export", out + err):
            return
        root = os.path.join(exports, "plugin-game-" + HOST)
        if HOST == "macos":
            exe = os.path.join(root, "Plugin Game.app", "Contents", "MacOS", "plugin-game")
            shipped = os.path.join(root, "Plugin Game.app", "Contents", "Frameworks", "libexample.dylib")
        else:
            exe = os.path.join(root, "plugin-game" + (".exe" if HOST == "windows" else ""))
            shipped = os.path.join(root, "example.dll" if HOST == "windows" else "libexample.so")
        check(os.path.isfile(shipped), "the export puts the library next to the executable: " + shipped)
        # The player writes log.txt into the game's user folder: point it into the temporary folder.
        home = os.path.join(tmp, "home")
        user_env = dict(os.environ, APPDATA=home, HOME=home, XDG_DATA_HOME=home)
        user_env.pop("FA_TEST_PLUGINS", None)
        try:
            p = subprocess.run([exe], env=user_env, capture_output=True, text=True, timeout=120)
            code = p.returncode
        except subprocess.TimeoutExpired:
            code = "timeout"
        logs = []
        for dirpath, _, files in os.walk(home):
            for f in files:
                if f == "log.txt":
                    with open(os.path.join(dirpath, f), encoding="utf-8", errors="replace") as fh:
                        logs.append(fh.read())
        log = "\n".join(logs)
        check(code == 0 and "probe add=3" in log, "the exported game: plugins.example.add(1, 2) is 3 (exit %s)" % code, log)
        check('"plugin":"example"' in log, "the exported game: fa.call('example.info')", log)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


main()
if failures:
    print("%d check(s) failed: %s" % (len(failures), "; ".join(failures)))
    sys.exit(1)
print("plugin_test: all checks passed")
