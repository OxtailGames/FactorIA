#!/usr/bin/env python3
"""End-to-end test of the `factoria` binary.

usage: integration.py <path-to-factoria> [--strict-tests]

For every template: new -> validate -> run headless (+screenshot) -> test -> call
-> MCP session over stdio (initialize, tools/list, game_step, game_screenshot).
Then the smaller commands (docs, api, feedback, commands, ai, errors).

`factoria test` results are REPORTED but only fail this script with --strict-tests
(or FA_CLI_STRICT_TESTS=1): template tests depend on the scripting module.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

FACTORIA = os.path.abspath(sys.argv[1])
STRICT_TESTS = "--strict-tests" in sys.argv or os.environ.get("FA_CLI_STRICT_TESTS") == "1"
TEMPLATES = ["2d-empty", "2d-platformer", "3d-empty"]

failures = []
notes = []


def check(cond, what):
    print(("  ok    " if cond else "  FAIL  ") + what, flush=True)
    if not cond:
        failures.append(what)
    return cond


def run(args, cwd=None, env=None, timeout=180, stdin=None):
    e = dict(os.environ)
    e.update(env or {})
    p = subprocess.run([FACTORIA] + args, cwd=cwd, env=e, capture_output=True, text=True, timeout=timeout, input=stdin)
    return p.returncode, p.stdout, p.stderr


def jrun(args, **kw):
    code, out, err = run(args, **kw)
    try:
        return code, json.loads(out), err
    except json.JSONDecodeError:
        return code, None, out + err


def is_png(path):
    try:
        with open(path, "rb") as f:
            return f.read(8) == b"\x89PNG\r\n\x1a\n"
    except OSError:
        return False


class Mcp:
    def __init__(self, args, cwd):
        self.p = subprocess.Popen([FACTORIA] + args, cwd=cwd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE, text=True)
        self.n = 0
        self.stray = []

    def send(self, method, params=None, notify=False):
        msg = {"jsonrpc": "2.0", "method": method}
        if params is not None:
            msg["params"] = params
        if not notify:
            self.n += 1
            msg["id"] = self.n
        self.p.stdin.write(json.dumps(msg) + "\n")
        self.p.stdin.flush()
        if notify:
            return None
        while True:
            line = self.p.stdout.readline()
            if not line:
                raise RuntimeError("MCP server closed stdout; stderr: " + self.p.stderr.read())
            try:
                resp = json.loads(line)
            except json.JSONDecodeError:
                self.stray.append(line)  # stdout must carry protocol messages only
                continue
            if resp.get("id") == msg["id"]:
                return resp

    def call(self, tool, args=None):
        r = self.send("tools/call", {"name": tool, "arguments": args or {}})
        return r.get("result", r)

    def close(self):
        try:
            self.p.stdin.close()
            self.p.wait(timeout=30)
        except Exception:
            self.p.kill()


def mcp_session(args, cwd, expect_tools, label):
    m = Mcp(args, cwd)
    try:
        init = m.send("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                                     "clientInfo": {"name": "cli-integration", "version": "1"}})
        check("result" in init and "serverInfo" in init["result"], label + ": initialize")
        m.send("notifications/initialized", notify=True)
        tools = m.send("tools/list", {})["result"]["tools"]
        names = {t["name"] for t in tools}
        check(all(t in names for t in expect_tools), label + ": tools/list has " + ", ".join(expect_tools) + " (%d tools)" % len(names))
        return m, names
    except Exception as ex:  # noqa
        check(False, label + ": MCP session failed: %s" % ex)
        m.close()
        return None, set()


def test_template(tmp, template):
    print("== template %s" % template, flush=True)
    proj = os.path.join(tmp, "game-" + template)
    code, out, err = jrun(["new", proj, "--template", template, "--name", "Test " + template, "--json"])
    if not check(code == 0 and out is not None, "new --template %s" % template):
        print(err)
        return
    for f in ["factoria.json", "ENGINE_FEEDBACK.json", "AGENTS.md", ".mcp.json"]:
        check(os.path.exists(os.path.join(proj, f)), "created " + f)

    dts = open(os.path.join(proj, "types", "factoria.d.ts")).read()
    check('declare module "factoria"' in dts and "(placeholder)" not in dts and len(dts) > 2000,
          "new writes the real types/factoria.d.ts (%d bytes)" % len(dts))

    code, rep, err = jrun(["validate", proj, "--json"])
    check(code == 0 and rep is not None and rep.get("ok") is True, "validate (scripts checked: %s)" % (rep or {}).get("scriptsChecked"))
    if code != 0:
        print(err if rep is None else json.dumps(rep, indent=1))

    shot = os.path.join(tmp, template + "-shot.png")
    pattern = os.path.join(tmp, template + "-frame_{frame}.png")
    code, rep, err = jrun(["run", proj, "--headless", "--frames", "120", "--screenshot-at", "60,119",
                           "--screenshot-pattern", pattern, "--json"])
    check(code == 0 and rep is not None, "run --headless --frames 120 (exit %d)" % code)
    if rep is None:
        print(err)
    else:
        shots = rep.get("screenshots", [])
        check(len(shots) == 2 and all(is_png(s if isinstance(s, str) else s.get("path", "")) for s in shots),
              "headless screenshots are PNG files: %s" % shots)

    code, out, err = run(["screenshot", proj, "--frames", "10", "--out", shot])
    check(code == 0 and is_png(shot), "screenshot command")

    code, rep, err = jrun(["test", proj, "--json"])
    if rep is None:
        notes.append("%s: factoria test produced no JSON (exit %d): %s" % (template, code, err.strip()[:300]))
        check(not STRICT_TESTS, "test (no report)")
    else:
        msg = "%s: factoria test -> %d passed, %d failed, %d load errors" % (
            template, rep.get("passed", 0), rep.get("failed", 0), len(rep.get("loadErrors", [])))
        notes.append(msg)
        print("  info  " + msg)
        if STRICT_TESTS:
            check(code == 0, "test passes")

    code, rep, err = jrun(["call", "scene.list_entities", "--project", proj])
    check(code == 0 and rep is not None, "call scene.list_entities")
    code, rep, err = jrun(["call", "game.state", "{}", "--project", proj, "--frames-before", "5"])
    check(code == 0 and rep is not None, "call game.state --frames-before 5")
    code, out, err = run(["call", "no.such_command", "--project", proj])
    check(code == 1 and "unknown" in (out + err).lower(), "call unknown command fails with exit 1")

    # one engine for several commands: --batch
    batch = json.dumps([{"command": "game.step", "args": {"frames": 12}},
                        {"command": "script.eval", "args": {"code": "1+2"}},
                        {"command": "game.state", "args": {"maxEntities": 0}}])
    code, rep, err = jrun(["call", "--batch", batch, "--project", proj])
    ok = code == 0 and rep is not None and rep.get("ok") and len(rep["results"]) == 3
    check(ok and rep["results"][1]["result"]["value"] == 3 and rep["results"][2]["result"]["frame"] == 12,
          "call --batch runs several commands on ONE engine (state persists)")
    code, rep, err = jrun(["call", "--batch", json.dumps([{"command": "nope.nope"}, {"command": "game.step"}]), "--project", proj])
    check(code == 1 and rep is not None and rep["ok"] is False and len(rep["results"]) == 1, "call --batch stops at the first failure, exit 1")
    code, rep, err = jrun(["call", "game.state", "{}", "--project", proj, "--frames-before", "3", "--press", "nope_action"])
    check(code == 2, "call --press with an unknown action is a usage error")

    # session: JSON lines on one engine
    lines = [{"command": "game.step", "args": {"frames": 7}}, {"command": "script.eval", "args": {"code": "40+2"}},
             {"command": "game.state", "args": {"maxEntities": 0}}, {"command": "nope.nope"}]
    stdin = "\n".join(json.dumps(l) for l in lines) + "\nnot json\n"
    code, out, err = run(["session", proj], stdin=stdin)
    answers = [json.loads(l) for l in out.splitlines() if l.strip()]
    check(code == 0 and len(answers) == 6 and answers[0].get("ready") is True, "session: ready line + one answer per request (%d lines)" % len(answers))
    if len(answers) == 6:
        check(answers[1]["ok"] and answers[2]["result"]["value"] == 42 and answers[3]["result"]["frame"] == 7,
              "session: state persists between requests")
        check(answers[4]["ok"] is False and answers[4]["error"]["code"] == "unknown_command" and answers[5]["error"]["code"] == "invalid_json",
              "session: errors are JSON lines with code/hint")

    # fs.* works inside tests (same command set everywhere), and tests print each result once
    with open(os.path.join(proj, "tests", "zz_fs.test.js"), "w") as f:
        f.write('import { test, expect } from "factoria:test";\n'
                'import { fa } from "factoria";\n'
                'test("fs.write is available inside tests", () => {\n'
                '  fa.call("fs.write", { path: "tests/out/probe.txt", content: "hi" });\n'
                '  expect(fa.call("fs.read", { path: "tests/out/probe.txt" }).content).toContain("hi");\n'
                '});\n')
    code, out, err = run(["test", proj, "--filter", "fs.write is available"])
    check(code == 0 and "1 passed, 0 failed" in out and out.count("fs.write is available") == 1,
          "fs.* works inside factoria test; each result printed once")
    os.remove(os.path.join(proj, "tests", "zz_fs.test.js"))

    # console.log in tests/behaviours is shown by default, indented under the test, even with --log-level warn
    with open(os.path.join(proj, "tests", "zz_log.test.js"), "w") as f:
        f.write('import { test, expect } from "factoria:test";\n'
                'test("logs something", () => { console.log("hello-from-test"); console.warn("careful-now"); expect(1).toBe(1); });\n')
    code, out, err = run(["test", proj, "--filter", "logs something", "--log-level", "warn"])
    lines = out.splitlines()
    idx = next((i for i, l in enumerate(lines) if "logs something" in l), -1)
    check(code == 0 and idx >= 0 and any("hello-from-test" in l and l.startswith("        |") for l in lines[idx + 1:])
          and any("warn: careful-now" in l for l in lines[idx + 1:]), "factoria test shows console output under the test")
    check("hello-from-test" not in err and "INFO" not in err, "factoria test keeps engine info logs off stderr")
    code, rep, err = jrun(["test", proj, "--filter", "logs something", "--json"])
    check(code == 0 and rep is not None and rep["cases"][0].get("logs", [{}])[0].get("message") == "hello-from-test", "factoria test --json has per-case logs")
    os.remove(os.path.join(proj, "tests", "zz_log.test.js"))

    # factoria call: ToolError data is printed (human + --json), exit 1
    os.makedirs(os.path.join(proj, "tools"), exist_ok=True)
    with open(os.path.join(proj, "tools", "chk.js"), "w") as f:
        f.write('import { ToolError } from "factoria";\n'
                'export default { name: "chk", summary: "always fails", run() { throw new ToolError("bad level", "edit levels.json", { errors: ["row 3 is empty"] }); } };\n')
    code, out, err = run(["call", "project.chk", "--project", proj])
    check(code == 1 and "bad level" in err and "edit levels.json" in err and "row 3 is empty" in err, "call prints ToolError data (human)")
    code, rep, err = jrun(["call", "project.chk", "--project", proj, "--json"])
    check(code == 1 and rep is not None and rep["error"]["data"]["errors"] == ["row 3 is empty"] and rep["error"]["code"] == "tool_error",
          "call --json prints error.data")
    os.remove(os.path.join(proj, "tools", "chk.js"))

    # input replay typos warn instead of being ignored
    replay = os.path.join(tmp, "typo_replay.json")
    with open(replay, "w") as f:
        json.dump({"frames": {"0": {"pres": ["jump"]}}}, f)
    code, out, err = run(["run", proj, "--headless", "--frames", "3", "--input", replay])
    check(code == 0 and "unknown field 'pres'" in err and "press" in err, "run --input warns about a misspelled field")

    # unknown component names fail instead of creating a half-built entity
    code, out, err = run(["call", "scene.spawn", '{"components":{"Transform2D":{"position":[1,2]}}}', "--project", proj])
    check(code == 1 and "Transform" in (out + err), "scene.spawn with an unknown component exits 1 with a did-you-mean")

    # --input: a relative path is looked up in the current directory, then in the project, so it works from any folder;
    # the error lists the places tried. Outputs (--state-out) are relative to the current directory.
    os.makedirs(os.path.join(proj, "replays"), exist_ok=True)
    with open(os.path.join(proj, "replays", "probe.json"), "w") as f:
        json.dump({"frames": {"0": {}}}, f)
    elsewhere = os.path.join(tmp, "elsewhere-" + template)
    os.makedirs(elsewhere, exist_ok=True)
    code, out, err = run(["run", proj, "--headless", "--frames", "3", "--input", "replays/probe.json"], cwd=elsewhere)
    check(code == 0, "run --input replays/probe.json from another folder finds the file in the project (exit %d)" % code)
    code, out, err = run(["run", proj, "--headless", "--frames", "3", "--input", "replays/prob.json"], cwd=elsewhere)
    check(code == 2 and os.path.join(os.path.realpath(elsewhere), "replays", "prob.json") in err
          and os.path.join(proj, "replays", "prob.json") in err and "Did you mean 'replays/probe.json'" in err
          and "relative to the project root" not in err, "run --input: a missing file lists both places tried and suggests a name")
    code, rep, err = jrun(["run", proj, "--headless", "--frames", "3", "--state-out", "out/state.json", "--json"], cwd=elsewhere)
    check(code == 0 and os.path.exists(os.path.join(elsewhere, "out", "state.json"))
          and not os.path.exists(os.path.join(proj, "out", "state.json")), "run --state-out is relative to the current directory")

    # ASCII level import: ONE call writes the tilemap and its objects into the scene FILE (`path`), without touching the
    # running game; validate accepts it. `save: true` without `path` on the default main scene is refused.
    os.makedirs(os.path.join(proj, "prefabs"), exist_ok=True)
    with open(os.path.join(proj, "prefabs", "probe_gem.prefab.json"), "w") as f:
        json.dump({"format": "factoria.prefab/1", "entity": {"name": "Coin", "tags": ["coin"],
                   "components": {"Shape2D": {"shape": "circle", "size": [12, 12]}}}}, f)
    main_scene = os.path.join(proj, "scenes", "main.scene.json")
    main_before = open(main_scene).read()
    unsafe = {"rows": ["....", ".o.o", "####"], "legend": {"#": 0, "o": {"prefab": "prefabs/probe_gem.prefab.json"}}, "save": True}
    code, out, err = run(["call", "scene.import_ascii", json.dumps(unsafe), "--project", proj])
    check(code == 1 and "unsafe_save" in err and "scenes/main.scene.json" in err and '"path"' in err and open(main_scene).read() == main_before,
          "scene.import_ascii save:true without path on the default main scene is refused and changes nothing")
    level = {"rows": ["....", ".o.o", "####"], "legend": {"#": 0, "o": {"prefab": "prefabs/probe_gem.prefab.json"}},
             "path": "scenes/main.scene.json"}
    code, res, err = jrun(["call", "scene.import_ascii", json.dumps(level), "--project", proj])
    check(code == 0 and res is not None and res["width"] == 4 and res["height"] == 3 and res["tileCount"] == 4
          and [o["id"] for o in res["spawned"]] == ["probe_gem_1", "probe_gem_2"] and res["spawned"][0]["position"] == [24.0, -24.0]
          and res.get("saved") == "scenes/main.scene.json" and res.get("path") == "scenes/main.scene.json",
          "call scene.import_ascii (path) builds the level in one call")
    code, rep, err = jrun(["validate", proj, "--json"])
    check(code == 0 and rep is not None and rep.get("ok") is True, "validate accepts the imported level")
    code, res, err = jrun(["call", "scene.import_ascii", json.dumps(level), "--project", proj])
    check(code == 0 and res is not None and res["removed"] == ["probe_gem_1", "probe_gem_2"] and res["created"] is False,
          "re-importing replaces the objects of the previous import")
    scratch = dict(level, path=".factoria/tmp/probe.scene.json", **{"from": "scenes/main.scene.json"})
    code, res, err = jrun(["call", "scene.import_ascii", json.dumps(scratch), "--project", proj])
    check(code == 0 and res is not None and os.path.exists(os.path.join(proj, ".factoria", "tmp", "probe.scene.json")),
          "scene.import_ascii path/from writes a scratch file in .factoria/tmp")
    code, out, err = run(["call", "scene.import_ascii", json.dumps(dict(level, path=".factoria/save/probe.scene.json")), "--project", proj])
    check(code == 1 and ".factoria/tmp/" in err, "scene.import_ascii refuses .factoria/ outside .factoria/tmp/")
    code, res, err = jrun(["call", "fs.delete", json.dumps({"path": ".factoria/tmp", "recursive": True}), "--project", proj])
    check(code == 0 and not os.path.exists(os.path.join(proj, ".factoria", "tmp")), "fs.delete removes the scratch folder .factoria/tmp")
    code, out, err = run(["call", "scene.import_ascii", json.dumps({"rows": ["..x"], "legend": {"#": 0}}), "--project", proj])
    check(code == 1 and "'x'" in err and "row 0, column 2" in err and "hint:" in err, "scene.import_ascii unknown glyph: row, column and hint")

    # prefab.save: spawn in one engine (--batch), save the entity as a prefab; the file is canonical and validates
    batch = [{"command": "scene.spawn", "args": {"id": "probe_boss", "name": "Boss", "tags": ["boss"],
                                                  "components": {"Transform": {"position": [50, 20, 0]}, "Shape2D": {"size": [30, 30]}}}},
             {"command": "prefab.save", "args": {"id": "probe_boss", "path": "prefabs/probe_boss.prefab.json"}},
             {"command": "prefab.save", "args": {"id": "probe_boss", "path": "prefabs/probe_boss.prefab.json"}}]
    code, res, err = jrun(["call", "--batch", json.dumps(batch), "--keep-going", "--project", proj])
    saved = res["results"][1] if res else {}
    check(res is not None and saved.get("ok") and saved["result"]["path"] == "prefabs/probe_boss.prefab.json"
          and saved["result"]["children"] == 0 and not res["results"][2]["ok"]
          and res["results"][2]["error"]["code"] == "already_exists" and "overwrite" in res["results"][2]["error"]["hint"],
          "call prefab.save writes the prefab; a second save without overwrite is refused")
    prefab_file = os.path.join(proj, "prefabs", "probe_boss.prefab.json")
    prefab = json.load(open(prefab_file)) if os.path.exists(prefab_file) else {}
    check(prefab.get("format") == "factoria.prefab/1" and "id" not in prefab.get("entity", {})
          and "Transform" not in prefab.get("entity", {}).get("components", {}), "the saved prefab has no id and no instance position")
    code, rep, err = jrun(["validate", proj, "--json"])
    check(code == 0 and rep is not None and rep.get("ok") is True, "validate accepts the saved prefab")

    # scene.format: hand-written prefab -> listed by --check, rewritten, then idempotent; broken JSON reported with a position
    messy = os.path.join(proj, "prefabs", "probe_messy.prefab.json")
    with open(messy, "w") as f:
        f.write('{"format":"factoria.prefab/1","entity":{"name":"Messy",\n"components":{"Shape2D":{"size":[10,10]}}}}')
    broken = os.path.join(proj, "prefabs", "probe_broken.prefab.json")
    with open(broken, "w") as f:
        f.write('{\n  "format": "factoria.prefab/1",\n  "entity": {"name": "x",}\n}\n')
    code, res, err = jrun(["call", "scene.format", '{"check":true}', "--project", proj])
    check(code == 0 and res is not None and "prefabs/probe_messy.prefab.json" in res["notCanonical"]
          and res["errors"] and res["errors"][0]["file"] == "prefabs/probe_broken.prefab.json" and res["errors"][0]["line"] == 3,
          "call scene.format check lists the messy prefab and reports the broken one with its line")
    check(open(messy).read().startswith('{"format"'), "scene.format check writes nothing")
    code, res, err = jrun(["call", "scene.format", "{}", "--project", proj])
    check(code == 0 and res is not None and "prefabs/probe_messy.prefab.json" in res["formatted"], "call scene.format rewrites the messy prefab")
    check('"size": [10, 10]' in open(messy).read() and open(broken).read().endswith('"x",}\n}\n'), "the layout is canonical and the broken file is untouched")
    code, res, err = jrun(["call", "scene.format", "{}", "--project", proj])
    check(code == 0 and res is not None and res["formatted"] == [], "scene.format twice: the second run changes nothing")
    os.remove(broken)

    # Script.props typos are validate warnings
    scene_path = os.path.join(proj, "scenes", "main.scene.json")
    scene = json.load(open(scene_path))
    scripted = None
    def find(es):
        for e in es:
            sc = e.get("components", {}).get("Script")
            if sc and sc.get("path"):
                return sc
            r = find(e.get("children", []))
            if r:
                return r
        return None
    scripted = find(scene.get("entities", []))
    if scripted:
        scripted.setdefault("props", {})["noSuchPropForSure"] = 1
        json.dump(scene, open(scene_path, "w"))
        code, rep, err = jrun(["validate", proj, "--json"])
        check(code == 0 and rep is not None and any("noSuchPropForSure" in w.get("message", "") for w in rep.get("warnings", [])),
              "validate warns about Script.props keys the behaviour does not have")

    m, names = mcp_session(["mcp", "--project", proj], proj, ["game_step", "game_screenshot", "scene_list_entities"], "mcp")
    if m:
        try:
            step = m.call("game_step", {"frames": 3})
            check(not step.get("isError"), "mcp: game_step")
            png = os.path.join(tmp, template + "-mcp.png")
            res = m.call("game_screenshot", {"path": png})
            kinds = [c.get("type") for c in res.get("content", [])]
            check(not res.get("isError") and "image" in kinds and is_png(png), "mcp: game_screenshot returns an image block (%s)" % kinds)
            res = m.call("feedback_report", {"category": "other", "severity": "nice-to-have", "title": "integration probe",
                                             "missing": "nothing", "workaround": "none"})
            check(not res.get("isError"), "mcp: feedback_report")
            res = m.call("nope_tool")
            check(res.get("isError") is True or "error" in res, "mcp: unknown tool is an error result")
            check(not m.stray, "mcp: stdout carried only protocol messages (%s)" % m.stray[:2])
        except Exception as ex:  # noqa
            check(False, "mcp calls: %s" % ex)
        finally:
            m.close()


def test_misc(tmp):
    print("== misc commands", flush=True)
    code, out, err = run(["--version"])
    check(code == 0 and out.startswith("factoria "), "--version")
    code, out, err = run(["help"])
    check(code == 0 and "Commands:" in out, "help")
    for c in ["new", "run", "test", "validate", "call", "api", "mcp", "ai", "feedback", "docs", "export", "screenshot", "commands", "templates"]:
        code, out, err = run([c, "--help"])
        check(code == 0 and "Examples:" in out or code == 0 and "Subcommands:" in out, "%s --help" % c)
    code, out, err = run(["tset"])
    check(code == 2 and "test" in err, "unknown command -> exit 2 + did-you-mean")
    code, out, err = run(["run", "--hedless"])
    check(code == 2 and "--headless" in err, "unknown flag -> exit 2 + did-you-mean")
    code, out, err = run(["new"])
    check(code == 2, "missing argument -> exit 2")

    code, rep, err = jrun(["templates", "--json"])
    check(code == 0 and {t["name"] for t in rep} >= set(TEMPLATES), "templates --json")
    code, out, err = run(["docs"])
    check(code == 0 and "scripting" in out, "docs list")
    code, out, err = run(["docs", "scripting"])
    check(code == 0 and len(out) > 500, "docs <name>")
    code, rep, err = jrun(["docs", "search", "collision", "--json"])
    check(code == 0 and isinstance(rep, list), "docs search")

    code, rep, err = jrun(["commands", "--json"])
    names = {c["name"] for c in rep} if rep else set()
    check(code == 0 and {"scene.list_entities", "game.step", "docs.list", "feedback.report", "project.create"} <= names, "commands --json (%d)" % len(names))
    code, out, err = run(["commands", "game.step"])
    check(code == 0 and "frames" in out, "commands <name>")

    code, rep, err = jrun(["api", "--json"])
    check(code == 0 and rep is not None and {"components", "commands", "scripting"} <= set(rep), "api --json")
    code, out, err = run(["api", "--md"])
    check(code == 0 and "Transform" in out, "api --md")
    code, out, err = run(["api", "--schema", "project"])
    check(code == 0 and '"properties"' in out, "api --schema project")
    for kind in ("scene", "prefab"):
        code, out, err = run(["api", "--schema", kind])
        check(code == 0 and '"properties"' in out, "api --schema " + kind)

    # ai: never touch the real user config
    env = {"FACTORIA_AI_CONFIG": os.path.join(tmp, "no-ai.json")}
    code, rep, err = jrun(["ai", "doctor", "--json"], env=env)
    check(code == 0 and rep is not None and "providers" in rep, "ai doctor --json")
    code, rep, err = jrun(["ai", "providers", "--json"], env=env)
    check(code == 0 and rep is not None and "roles" in rep, "ai providers --json")
    code, out, err = run(["ai", "config"], env=env)
    check(code == 0 and "no-ai.json" in out and "sk-" not in out, "ai config")

    # feedback
    proj = os.path.join(tmp, "fb")
    run(["new", proj])
    code, out, err = run(["feedback", "add", "--project", proj, "--category", "physics", "--severity", "major", "--title",
                          "No one-way platforms", "--missing", "Collider2D has no oneWay option", "--workaround", "script toggles the collider", "--files", "scripts/a.js,scripts/b.js"])
    check(code == 0 and "FB-" in out, "feedback add")
    code, out, err = run(["feedback", "add", "--project", proj, "--json", json.dumps(
        {"category": "physics", "severity": "minor", "title": "No one way platforms", "missing": "Collider2D has no one way flag", "workaround": "a script disables the collider"})])
    check(code == 0 and "Merged" in out, "feedback add merges a similar entry")
    code, out, err = run(["feedback", "add", "--project", proj, "--category", "physics"])
    check(code == 2, "feedback add without required flags -> exit 2")
    code, rep, err = jrun(["feedback", "list", proj, "--json"])
    check(code == 0 and len(rep) == 1 and rep[0]["occurrences"] == 2, "feedback list")
    fb_id = rep[0]["id"]
    code, out, err = run(["feedback", "update", proj, fb_id, "--status", "fixed-in-engine", "--engine-issue", "abc123", "--note", "triaged"])
    check(code == 0 and "fixed-in-engine" in out, "feedback update")
    code, rep, err = jrun(["feedback", "update", proj, fb_id, "--note", "again", "--json"])
    check(code == 0 and rep["status"] == "fixed-in-engine" and rep["engineIssue"] == "abc123" and rep["notes"][-2:] == ["triaged", "again"],
          "feedback update --json keeps status/engineIssue and appends notes")
    code, out, err = run(["feedback", "update", proj, fb_id, "--status", "bogus"])
    check(code != 0 and "status" in err, "feedback update rejects an invalid status")
    code, out, err = run(["feedback", "update", proj, "FB-999", "--status", "open"])
    check(code != 0 and "FB-999" in err, "feedback update unknown id fails")
    code, rep, err = jrun(["feedback", "update", proj, fb_id, "--status", "open", "--json"])
    check(code == 0 and rep["status"] == "open", "feedback update back to open")
    code, out, err = run(["feedback", "validate", proj])
    check(code == 0, "feedback validate")
    report = os.path.join(tmp, "roadmap.md")
    code, out, err = run(["feedback", "collect", proj, "--out", report])
    check(code == 0 and os.path.exists(report) and "one-way" in open(report).read().lower().replace(" ", "-"), "feedback collect -> markdown")
    code, rep, err = jrun(["feedback", "collect", proj, "--format", "json"])
    check(code == 0 and rep is not None and rep.get("clusters"), "feedback collect --format json")

    # validate --fix-types replaces a placeholder
    dts_path = os.path.join(proj, "types", "factoria.d.ts")
    with open(dts_path, "w") as f:
        f.write("// FactorIA script API typings (placeholder).\n")
    code, rep, err = jrun(["validate", proj, "--json"])
    check(rep is not None and any("placeholder" in w.get("message", "") for w in rep.get("warnings", [])), "validate warns about a placeholder d.ts")
    code, out, err = run(["validate", proj, "--fix-types"])
    check(code == 0 and 'declare module "factoria"' in open(dts_path).read(), "validate --fix-types writes the real typings")

    # api --dts into a project
    code, out, err = run(["api", "--dts", "--project", proj])
    check(code == 0 and os.path.getsize(os.path.join(proj, "types", "factoria.d.ts")) > 200, "api --dts --project writes types/factoria.d.ts")

    # export (desktop) needs the player binary; only check that it is wired
    code, out, err = run(["export", proj, "--platform", "android", "--out", os.path.join(tmp, "exp")])
    check(code in (0, 1), "export is wired (exit %d)" % code)

    # MCP without a project: bootstrap tools only
    empty = os.path.join(tmp, "empty")
    os.makedirs(empty)
    m, names = mcp_session(["mcp"], empty, ["docs_list", "project_create", "project_templates"], "mcp (no project)")
    if m:
        try:
            made = os.path.join(tmp, "from-mcp")
            res = m.call("project_create", {"dir": made, "template": "2d-empty"})
            check(not res.get("isError") and os.path.exists(os.path.join(made, "factoria.json")), "mcp (no project): project_create")
            check("game_step" not in names, "mcp (no project): engine tools are absent")
        finally:
            m.close()


def main():
    tmp = tempfile.mkdtemp(prefix="factoria-cli-it-")
    try:
        for t in TEMPLATES:
            test_template(tmp, t)
        test_misc(tmp)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    print()
    for n in notes:
        print("note: " + n)
    if failures:
        print("\n%d FAILED:" % len(failures))
        for f in failures:
            print("  - " + f)
        return 1
    print("all integration checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
