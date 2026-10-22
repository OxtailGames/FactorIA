#!/usr/bin/env python3
"""`factoria dap`: the Debug Adapter Protocol server of the script debugger, driven over stdio.

usage: dap_test.py <path-to-factoria>

Makes a project from the 2d-platformer template and checks: a breakpoint in scripts/player.js (stopped, stack, locals,
evaluate, next, logpoint, continue to the end), a test-mode stop, a bad launch key, and disconnect while stopped.
Every wait has a timeout, so a hang fails the test instead of blocking ctest.
"""
import json
import os
import queue
import shutil
import subprocess
import sys
import tempfile
import threading
import time

FACTORIA = os.path.abspath(sys.argv[1])
failures = []
TIMEOUT = 90


def check(cond, what, detail=""):
    print(("  ok    " if cond else "  FAIL  ") + what, flush=True)
    if not cond:
        failures.append(what)
        if detail:
            print(str(detail)[-3000:], flush=True)
    return cond


class Dap:
    def __init__(self, cwd, home):
        env = dict(os.environ, HOME=home, APPDATA=home, XDG_DATA_HOME=home)
        self.p = subprocess.Popen([FACTORIA, "dap"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                  stderr=subprocess.DEVNULL, cwd=cwd, env=env)
        self.seq = 0
        self.msgs = queue.Queue()
        self.backlog = []
        self.badstdout = False
        threading.Thread(target=self._read, daemon=True).start()

    def _read(self):
        out = self.p.stdout
        while True:
            length = None
            while True:
                line = out.readline()
                if not line:
                    self.msgs.put(None)
                    return
                line = line.strip()
                if not line:
                    break
                if line.lower().startswith(b"content-length:"):
                    length = int(line.split(b":")[1])
                else:
                    self.badstdout = True
            if length is None:
                self.badstdout = True
                continue
            self.msgs.put(json.loads(out.read(length)))

    def send(self, command, **arguments):
        self.seq += 1
        body = json.dumps({"seq": self.seq, "type": "request", "command": command, "arguments": arguments}).encode()
        self.p.stdin.write(b"Content-Length: %d\r\n\r\n" % len(body) + body)
        self.p.stdin.flush()
        return self.seq

    def wait(self, pred, timeout=TIMEOUT):
        """Next message (earlier ones first) for which pred is true; None on timeout or end of stream."""
        for i, m in enumerate(self.backlog):
            if pred(m):
                return self.backlog.pop(i)
        end = time.time() + timeout
        while time.time() < end:
            try:
                m = self.msgs.get(timeout=max(0.05, end - time.time()))
            except queue.Empty:
                break
            if m is None:
                return None
            if pred(m):
                return m
            self.backlog.append(m)
        return None

    def request(self, command, **arguments):
        n = self.send(command, **arguments)
        return self.wait(lambda m: m.get("type") == "response" and m.get("request_seq") == n)

    def event(self, name, timeout=TIMEOUT):
        return self.wait(lambda m: m.get("type") == "event" and m.get("event") == name, timeout)

    def outputs(self):
        return "".join(m["body"]["output"] for m in self.backlog if m.get("event") == "output")

    def close(self):
        try:
            self.p.stdin.close()
        except Exception:
            pass
        try:
            self.p.wait(timeout=10)
        except subprocess.TimeoutExpired:
            self.p.kill()


def top_frame(d):
    st = d.request("stackTrace", threadId=1)
    return st["body"]["stackFrames"][0] if st and st.get("success") else None


def main():
    tmp = tempfile.mkdtemp(prefix="fa_dap_")
    try:
        game = os.path.join(tmp, "game")
        home = os.path.join(tmp, "home")
        os.makedirs(home)
        p = subprocess.run([FACTORIA, "new", game, "--template", "2d-platformer", "--name", "Dap Game"], capture_output=True, text=True)
        if not check(p.returncode == 0, "factoria new 2d-platformer", p.stdout + p.stderr):
            return
        player = os.path.join(game, "scripts", "player.js")

        # ---- headless: breakpoint, inspect, step, logpoint, run to the end
        d = Dap(game, home)
        r = d.request("initialize", adapterID="factoria", linesStartAt1=True, columnsStartAt1=True)
        check(r and r["success"] and r["body"].get("supportsLogPoints"), "initialize answers the capabilities", r)
        check(d.event("initialized") is not None, "initialized event")
        d.send("launch", type="factoria", request="launch", name="Headless", mode="headless", project=game, frames=60,
               noDebug=False, __sessionId="abc", presentation={"hidden": False}, factoriaPath="x")
        r = d.request("setBreakpoints", source={"path": player}, breakpoints=[{"line": 17}])
        bp = r["body"]["breakpoints"][0] if r and r.get("success") else {}
        check(bp.get("verified") and bp.get("line") == 17, "breakpoint on player.js:17 is verified", r)
        d.request("setExceptionBreakpoints", filters=["uncaught"])
        check(d.request("configurationDone")["success"], "configurationDone")
        st = d.event("stopped")
        check(st and st["body"]["reason"] == "breakpoint", "stopped with reason breakpoint", st)
        f = top_frame(d)
        check(f and f["name"] == "Player.onUpdate" and f["line"] == 17, "top frame is Player.onUpdate line 17", f)
        check(f and os.path.realpath(f["source"]["path"]) == os.path.realpath(player), "frame path is the absolute path", f)
        sc = d.request("scopes", frameId=f["id"])
        locals_ = next((s for s in sc["body"]["scopes"] if s["name"] == "Locals"), None)
        names = []
        if locals_:
            v = d.request("variables", variablesReference=locals_["variablesReference"])
            names = [x["name"] for x in v["body"]["variables"]]
        check("dt" in names and "this" in names, "Locals has dt and this", names)
        r = d.request("evaluate", expression="this.speed", frameId=f["id"], context="watch")
        check(r and r["success"] and r["body"]["result"] == "300", "evaluate this.speed is 300", r)
        r = d.request("evaluate", expression="nope.x", frameId=f["id"], context="repl")
        check(r and not r["success"] and r.get("message"), "a failing evaluate is an error response", r)
        d.request("next", threadId=1)
        st = d.event("stopped")
        f = top_frame(d)
        check(st and st["body"]["reason"] == "step" and f and f["line"] == 18, "next stops at line 18", (st, f))
        # a logpoint on line 17 replaces the breakpoint; the game keeps running
        r = d.request("setBreakpoints", source={"path": player}, breakpoints=[{"line": 17, "logMessage": "speed={this.speed}"}])
        d.request("continue", threadId=1)
        end = d.event("terminated")
        check(end is not None, "game runs to the end after continue (terminated)")
        ex = d.wait(lambda m: m.get("event") == "exited", 5)
        # the exited event comes before terminated: it may already be in the backlog
        if ex is None:
            ex = next((m for m in d.backlog if m.get("event") == "exited"), None)
        check(ex is not None and ex["body"]["exitCode"] == 0, "exited with code 0", ex)
        check("speed=300" in d.outputs(), "logpoint printed its message", d.outputs()[-500:])
        d.request("disconnect")
        d.close()
        check(not d.badstdout, "stdout carried only protocol")

        # ---- clearing breakpoints and continuing in a fresh session: runs without stopping
        d = Dap(game, home)
        d.request("initialize", adapterID="factoria")
        d.send("launch", mode="headless", project=game, frames=30)
        d.request("setBreakpoints", source={"path": player}, breakpoints=[])
        d.request("configurationDone")
        check(d.event("terminated") is not None, "no breakpoints: the game just runs to the end")
        d.request("disconnect")
        d.close()

        # ---- file outside the project
        d = Dap(game, home)
        d.request("initialize", adapterID="factoria")
        d.send("launch", mode="headless", project=game, frames=5)
        r = d.request("setBreakpoints", source={"path": os.path.join(tmp, "other.js")}, breakpoints=[{"line": 1}])
        b = r["body"]["breakpoints"][0]
        check(not b["verified"] and "outside the project" in b.get("message", ""), "a file outside the project is unverified, with why", r)
        d.request("configurationDone")
        d.event("terminated")
        d.request("disconnect")
        d.close()

        # ---- bad launch keys teach
        d = Dap(game, home)
        d.request("initialize", adapterID="factoria")
        r = d.request("launch", moed="headless", project=game)
        check(r and not r["success"] and "mode" in r["message"] and "Did you mean" in r["message"], "unknown launch key: did you mean", r)
        d.request("disconnect")
        d.close()
        d = Dap(game, home)
        d.request("initialize", adapterID="factoria")
        r = d.request("launch", mode="headles", project=game)
        check(r and not r["success"] and "headless" in r["message"], "bad mode: did you mean headless", r)
        d.request("disconnect")
        d.close()

        # ---- test mode: stop inside a template test
        d = Dap(game, home)
        d.request("initialize", adapterID="factoria")
        d.send("launch", mode="test", project=game, tests=["tests/platformer.test.js"])
        testfile = os.path.join(game, "tests", "platformer.test.js")
        r = d.request("setBreakpoints", source={"path": testfile}, breakpoints=[{"line": 10}])
        check(r and r["body"]["breakpoints"][0]["verified"], "breakpoint in a test file is verified", r)
        d.request("configurationDone")
        st = d.event("stopped")
        f = top_frame(d)
        check(st and f and f["line"] == 10 and f["source"]["path"].endswith("platformer.test.js"), "test mode stops in the template test", (st, f))
        # ---- disconnect while stopped ends the process promptly
        t0 = time.time()
        d.request("disconnect")
        try:
            d.p.wait(timeout=20)
        except subprocess.TimeoutExpired:
            pass
        check(d.p.poll() is not None and time.time() - t0 < 20, "disconnect while stopped ends the process", d.p.poll())
        d.close()
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


try:
    main()
except Exception as e:  # a hang shows as a missing response (None): report it as a failure
    import traceback
    traceback.print_exc()
    failures.append("exception: %r" % (e,))
if failures:
    print("\n%d FAILED: %s" % (len(failures), "; ".join(failures)))
    sys.exit(1)
print("\nall ok")
