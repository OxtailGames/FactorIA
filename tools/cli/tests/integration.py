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
    code, out, err = run(["feedback", "validate", proj])
    check(code == 0, "feedback validate")
    report = os.path.join(tmp, "roadmap.md")
    code, out, err = run(["feedback", "collect", proj, "--out", report])
    check(code == 0 and os.path.exists(report) and "one-way" in open(report).read().lower().replace(" ", "-"), "feedback collect -> markdown")
    code, rep, err = jrun(["feedback", "collect", proj, "--format", "json"])
    check(code == 0 and rep is not None and rep.get("clusters"), "feedback collect --format json")

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
