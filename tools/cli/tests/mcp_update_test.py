#!/usr/bin/env python3
"""`factoria mcp` after an update: the file replaced under a running server, and a client with an older .mcp.json.

usage: mcp_update_test.py <path-to-factoria>

Copies the factoria binary to a temp folder, starts `factoria mcp` from the copy over stdio and checks:
  1. replaced file (POSIX): another build (the copy with its fingerprint bytes changed) is renamed over the running file. The
     server keeps answering without a new initialize, sends notifications/tools/list_changed, a request written during the swap
     is answered, and the first tool result afterwards carries a notice; engine_update_status reports the new build.
     Windows cannot replace a running program: the server says so in the next tool result and a notifications/message.
  2. a project .mcp.json without `timeout`, client "claude-code": the server adds it and tells the AI (in a tool result) to ask the
     user to restart the client or reconnect.
Every wait has a timeout, so a hang fails the test instead of blocking ctest.
"""
import json
import os
import queue
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time

FACTORIA = os.path.abspath(sys.argv[1])
IS_WINDOWS = os.name == "nt"
failures = []


def check(cond, what, detail=""):
    print(("  ok    " if cond else "  FAIL  ") + what, flush=True)
    if not cond:
        failures.append(what)
        if detail:
            print(str(detail)[-3000:], flush=True)
    return cond


class Server:
    def __init__(self, exe, project, home, client="test"):
        env = dict(os.environ, HOME=home, APPDATA=home, XDG_DATA_HOME=home, USERPROFILE=home)
        self.p = subprocess.Popen([exe, "mcp", "--project", project], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                  stderr=subprocess.DEVNULL, env=env)
        self.q = queue.Queue()
        self.seen = []
        self.next_id = 1
        threading.Thread(target=self._read, daemon=True).start()
        r = self.rpc("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                                    "clientInfo": {"name": client, "version": "1"}})
        self.ok = r is not None and "result" in r
        self.send({"jsonrpc": "2.0", "method": "notifications/initialized"})

    def _read(self):
        for line in self.p.stdout:
            line = line.strip()
            if line:
                try:
                    self.q.put(json.loads(line))
                except ValueError:
                    self.q.put({"badline": line.decode("utf-8", "replace")})
        self.q.put(None)

    def send(self, msg):
        self.p.stdin.write((json.dumps(msg) + "\n").encode())
        self.p.stdin.flush()

    def wait(self, pred, timeout=30):
        deadline = time.time() + timeout
        for m in self.seen:
            if pred(m):
                self.seen.remove(m)
                return m
        while time.time() < deadline:
            try:
                m = self.q.get(timeout=0.2)
            except queue.Empty:
                continue
            if m is None:
                return None
            if pred(m):
                return m
            self.seen.append(m)
        return None

    def request(self, method, params=None):
        rid = self.next_id
        self.next_id += 1
        self.send({"jsonrpc": "2.0", "id": rid, "method": method, "params": params or {}})
        return rid

    def rpc(self, method, params=None, timeout=30):
        rid = self.request(method, params)
        return self.wait(lambda m: m.get("id") == rid, timeout)

    def tool(self, name, args=None, timeout=30):
        r = self.rpc("tools/call", {"name": name, "arguments": args or {}}, timeout)
        if r is None or "result" not in r:
            return None, ""
        texts = [c.get("text", "") for c in r["result"].get("content", [])]
        return r, "\n".join(texts)

    def close(self):
        try:
            self.p.stdin.close()
        except OSError:
            pass
        try:
            self.p.wait(timeout=10)
        except subprocess.TimeoutExpired:
            self.p.kill()


def another_build(src, dst):
    """A copy of `src` that says it is another build: its fingerprint is changed everywhere it is written in the bytes."""
    data = bytearray(open(src, "rb").read())
    m = re.search(rb"FA-BUILD-FINGERPRINT:([0-9a-zA-Z-]+);", bytes(data))
    if not m:
        return False
    fp = m.group(1)
    new = (b"0" if fp[:1] != b"0" else b"1") + fp[1:]
    data = bytearray(bytes(data).replace(fp, new))  # the marker, and the copy the program compares itself with
    open(dst, "wb").write(bytes(data))
    shutil.copymode(src, dst)
    if sys.platform == "darwin":  # arm64 macOS refuses a file whose signature no longer matches its bytes
        subprocess.run(["codesign", "--force", "-s", "-", dst], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return True


def main():
    tmp = tempfile.mkdtemp(prefix="fa_mcp_update_")
    home = os.path.join(tmp, "home")
    os.makedirs(home)
    try:
        bindir = os.path.join(tmp, "bin")
        os.makedirs(bindir)
        exe = os.path.join(bindir, "factoria" + (".exe" if IS_WINDOWS else ""))
        shutil.copy2(FACTORIA, exe)
        project = os.path.join(tmp, "game")
        r = subprocess.run([exe, "new", project], capture_output=True, text=True, env=dict(os.environ, HOME=home, APPDATA=home))
        check(r.returncode == 0, "factoria new makes the project", r.stdout + r.stderr)
        newexe = os.path.join(tmp, "factoria.new")
        if not check(another_build(exe, newexe), "the copy is turned into another build (the binary carries its markers)"):
            return

        print("-- the file is replaced under a running server")
        s = Server(exe, project, home)
        check(s.ok, "initialize")
        r, text = s.tool("engine_update_status")
        check(r is not None and '"state":"current"' in text.replace(" ", "").replace("\n", "") or "current" in text,
              "engine_update_status says current before the swap", text)
        before = json.loads(text.split("\n[FactorIA notice]")[0]) if r else {}
        running_before = before.get("running", {}).get("fingerprint", "")
        if IS_WINDOWS:  # a running program cannot be written over, only renamed: an installer moves it aside first
            os.replace(exe, exe + ".old")
        os.replace(newexe, exe)  # a rename over the running file, as an installer does
        # A request written while the server notices the change must not be lost.
        pid = s.request("ping")
        pong = s.wait(lambda m: m.get("id") == pid, 30)
        check(pong is not None and "result" in pong, "a request written during the swap is answered")
        if not IS_WINDOWS:
            changed = s.wait(lambda m: m.get("method") == "notifications/tools/list_changed", 40)
            check(changed is not None, "the restarted server sends notifications/tools/list_changed")
            r, text = s.tool("engine_update_status")
            check(r is not None, "the server keeps answering after the restart, without a new initialize", text)
            check("[FactorIA notice]" in text and "restarted itself in place" in text,
                  "the first tool result after the restart says it restarted", text)
            body = json.loads(text.split("\n[FactorIA notice]")[0]) if r else {}
            check(body.get("running", {}).get("fingerprint", "x") != running_before, "the new process runs the new build", text)
            check(body.get("state") == "current", "...and finds nothing left to restart", text)
            r, text = s.tool("engine_update_status")
            check("[FactorIA notice]" not in text, "the notice is given once", text)
        else:
            note = s.wait(lambda m: m.get("method") == "notifications/message", 40)
            check(note is not None, "Windows: the server says it is out of date in a notifications/message")
            r, text = s.tool("engine_update_status")
            check("/mcp" in text, "Windows: the next tool result asks for a reconnect", text)
        s.close()

        print("-- a project .mcp.json without a timeout")
        mcp_json = os.path.join(project, ".mcp.json")
        cfg = json.load(open(mcp_json))
        for entry in cfg.get("mcpServers", {}).values():
            entry.pop("timeout", None)
        json.dump(cfg, open(mcp_json, "w"), indent=2)
        time.sleep(0.05)
        s = Server(exe, project, home, client="claude-code")
        check(s.ok, "initialize (claude-code)")
        for _ in range(40):  # the server looks as soon as the client initialized, between two messages
            if "timeout" in open(mcp_json).read():
                break
            time.sleep(0.25)
        r, text = s.tool("engine_update_status")
        check(r is not None and "/mcp" in text and "timeout" in text,
              "the first tool result tells the AI to ask for a restart or /mcp, and what was added", text)
        fixed = json.load(open(mcp_json))
        timeouts = [e.get("timeout") for e in fixed.get("mcpServers", {}).values()]
        check(timeouts and all(isinstance(t, int) and t >= 3600000 for t in timeouts), "the missing timeout was added to .mcp.json", fixed)
        r, text = s.tool("engine_update_status")
        check("[FactorIA notice]" not in text, "the notice is given once", text)
        s.close()
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


try:
    main()
except Exception as e:  # a crash in the test is a failure, with its message
    check(False, "the test ran to the end", repr(e))
if failures:
    print("\n%d FAILED: %s" % (len(failures), "; ".join(failures)))
    sys.exit(1)
print("\nall ok")
