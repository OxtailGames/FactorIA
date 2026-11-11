#!/usr/bin/env bash
# Tests scripts/agent-cost.sh against a FAKE engine and a FAKE CLI: nothing here starts a model or spends quota.
#
#   scripts/agent-cost-selftest.sh <path of a factoria that has agent.cost>
#
# It proves what a hand test only showed once: the wall-clock cap and a TERM sent to the script end the CLI's whole process
# group (the fake CLI starts a child and sleeps), the CLI gets a clean environment and, with a token or --isolated-home, a
# throw-away HOME, the `factoria` wrapper works from a work folder whose path holds a quote, the final play.auto has its own cap,
# and the report carries the CLI version and whether HOME was isolated. ctest runs it as `agent_cost_script` (POSIX hosts).
set -u
here="$(cd "$(dirname "$0")" && pwd)"
script="$here/agent-cost.sh"
reporter="${1:-}"
[ -x "$reporter" ] || { echo "usage: $0 <factoria binary with agent.cost>" >&2; exit 2; }
reporter="$(cd "$(dirname "$reporter")" && pwd)/$(basename "$reporter")"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/agent-cost-selftest.XXXXXX")"
tmp="$(cd "$tmp" && pwd -P)"
trap 'for f in "$tmp"/*/*.pid "$tmp"/*/*/*.pid; do [ -f "$f" ] && kill -KILL "$(cat "$f")" 2>/dev/null; done; rm -rf "$tmp"' EXIT
fail=0
check() {  # check DESCRIPTION CONDITION-EXIT-STATUS
    if [ "$2" -ne 0 ]; then echo "FAIL: $1"; fail=1; else echo "ok: $1"; fi
}
# A zombie (state Z: ended, not yet reaped by its parent) answers kill -0 but is gone for our purpose.
alive() {
    kill -0 "$1" 2>/dev/null || return 1
    case "$(ps -o stat= -p "$1" 2>/dev/null | tr -d ' ')" in Z*) return 1 ;; esac
    return 0
}
wait_for_file() {  # wait_for_file FILE SECONDS
    local i=0
    while [ ! -s "$1" ] && [ "$i" -lt $(( $2 * 5 )) ]; do sleep 0.2; i=$((i + 1)); done
    [ -s "$1" ]
}
wait_gone() {  # wait_gone PID SECONDS
    local i=0
    while alive "$1" && [ "$i" -lt $(( $2 * 5 )) ]; do sleep 0.2; i=$((i + 1)); done
    ! alive "$1"
}

# The fake engine: `--version`, and `call ... play.auto` answering a 3-level win (or sleeping, to test the final cap).
engine="$tmp/engine"
mkdir -p "$engine"
cat > "$engine/factoria" <<'EOF'
#!/bin/sh
here="$(cd "$(dirname "$0")" && pwd)"
case "$1" in
    --version) echo "factoria 9.9.9" ;;
    call)
        if [ -f "$here/hang-play" ]; then sleep 300 & echo $! > "$here/play-child.pid"; wait; fi
        echo '{"ended":"won","endedWhy":"fake","phases":[{"name":"scenes/a.scene.json","kind":"scene"},{"name":"scenes/b.scene.json","kind":"scene"},{"name":"scenes/c.scene.json","kind":"scene"}],"scriptErrors":[]}' ;;
    *) echo "fake factoria: $*" ;;
esac
EOF
chmod +x "$engine/factoria"

# The fake CLI. Its mode is the first line of `mode` beside it: ok (writes a short stream-json transcript and a game) or hang
# (starts a child, sleeps). It records its pid, its environment and its arguments in the work folder (the parent of its cwd).
cli="$tmp/fake-claude"
cat > "$cli" <<'EOF'
#!/bin/sh
here="$(cd "$(dirname "$0")" && pwd)"
case "$1" in --version) echo "9.9.9 (Fake Code)"; exit 0 ;; esac
echo $$ > ../fake.pid
env > ../fake-env.txt
printf '%s\n' "$@" > ../fake-args.txt
factoria --version > ../fake-factoria.txt 2>&1
case "$(cat "$here/mode")" in
    hang) sleep 300 & echo $! > ../child.pid; wait ;;
    ok|outside)
        echo '{}' > factoria.json
        echo '{"type":"system","subtype":"init","cwd":".","model":"fake","mcp_servers":[],"plugins":[]}'
        echo '{"type":"assistant","message":{"id":"m1","role":"assistant","usage":{"input_tokens":1,"output_tokens":2,"cache_creation_input_tokens":0,"cache_read_input_tokens":3},"content":[{"type":"tool_use","id":"t1","name":"Bash","input":{"command":"factoria new ."}}]},"timestamp":"2026-11-11T13:00:00.000Z"}'
        [ "$(cat "$here/mode")" = outside ] && echo '{"type":"assistant","message":{"id":"m2","role":"assistant","usage":{"input_tokens":1,"output_tokens":2},"content":[{"type":"tool_use","id":"t2","name":"Bash","input":{"command":"factoria call game.screenshot {\"path\":\"/tmp/evil.png\"}"}}]}}'
        echo '{"type":"result","subtype":"success","num_turns":1,"total_cost_usd":0.01,"terminal_reason":"completed","usage":{"input_tokens":1,"output_tokens":2,"cache_creation_input_tokens":0,"cache_read_input_tokens":3}}' ;;
esac
EOF
chmod +x "$cli"

run() {  # run MODE WORKDIR [script options...]: stdout and stderr of the script in $tmp/last.log
    echo "$1" > "$tmp/mode"
    local mode="$1" wd="$2"
    shift 2
    env -u ANTHROPIC_API_KEY -u CLAUDE_CODE_OAUTH_TOKEN AGENT_COST_TEST_SECRET=leak "$script" --factoria "$engine" --cli-bin "$cli" \
        --reporter "$reporter" --workdir "$wd" --out "$wd.result.json" "$@" > "$tmp/last.log" 2>&1
}

# 1. A normal run, in a work folder whose path holds a quote and a space.
wd="$tmp/it's here"
run ok "$wd"
check "a normal run ends with status 0" $?
grep -q '"cliVersion": "9.9.9 (Fake Code)"' "$wd.result.json"; check "the result records the CLI version" $?
grep -q 'real HOME' "$wd.result.json"; check "the result says in its notes that the CLI ran with the real HOME" $?
grep -q '"homeIsolated":false' "$wd/agent-cost-args.json"; check "the report is told the HOME was not isolated" $?
grep -q 'factoria 9.9.9' "$wd/fake-factoria.txt"; check "the factoria wrapper runs from a work folder with a quote in its path" $?
grep -q "^HOME=$HOME\$" "$wd/fake-env.txt"; check "without a token the CLI keeps the real HOME (and the script warned)" $?
grep -q 'WARNING the CLI keeps your real HOME' "$tmp/last.log"; check "the real HOME is warned about" $?
grep -q 'AGENT_COST_TEST_SECRET' "$wd/fake-env.txt"; check "the CLI environment is clean (no variable of the caller)" $((1 - $?))
grep -qx -- '--setting-sources' "$wd/fake-args.txt" && grep -qx 'acceptEdits' "$wd/fake-args.txt"; check "the CLI gets project settings only and acceptEdits" $?
grep -q 'bypassPermissions' "$wd/fake-args.txt"; check "never bypassPermissions" $((1 - $?))
grep -q '"reachedLastLevel": true' "$wd.result.json"; check "the final play.auto of the engine copy is read" $?

# 2. A token (or --isolated-home): a throw-away HOME and CLAUDE_CONFIG_DIR, the token passed through.
wd="$tmp/iso"
echo ok > "$tmp/mode"
ANTHROPIC_API_KEY=dummy-key "$script" --factoria "$engine" --cli-bin "$cli" --reporter "$reporter" --workdir "$wd" --out "$wd.result.json" > "$tmp/last.log" 2>&1
check "a run with ANTHROPIC_API_KEY ends with status 0" $?
grep -q "^HOME=$wd/cli-home\$" "$wd/fake-env.txt" && grep -q "^CLAUDE_CONFIG_DIR=$wd/cli-home/.claude\$" "$wd/fake-env.txt"; check "the CLI gets a throw-away HOME and CLAUDE_CONFIG_DIR" $?
grep -q '^ANTHROPIC_API_KEY=dummy-key$' "$wd/fake-env.txt"; check "the API key is passed through the clean environment" $?
grep -q '"homeIsolated":true' "$wd/agent-cost-args.json" && ! grep -q 'real HOME' "$wd.result.json"; check "the report is told the HOME was isolated" $?
[ ! -e "$wd/cli-home" ] && [ ! -e "$wd/home" ]; check "the throw-away home/ and cli-home/ are removed at the end" $?
grep -q 'env -u ANTHROPIC_API_KEY -u CLAUDE_CODE_OAUTH_TOKEN' "$wd/bin/factoria"; check "the factoria wrapper drops the credentials" $?
[ "$(grep -c 'exec env -u ANTHROPIC_API_KEY -u CLAUDE_CODE_OAUTH_TOKEN' "$script")" -ge 2 ]; check "the final play.auto drops the credentials too" $?
wd="$tmp/iso2"
run ok "$wd" --isolated-home
grep -q "^HOME=$wd/cli-home\$" "$wd/fake-env.txt" && ! grep -q '^ANTHROPIC_API_KEY=' "$wd/fake-env.txt"; check "--isolated-home isolates HOME without a token" $?

# 3. The wall-clock cap ends the CLI and the child it started.
wd="$tmp/cap"
start=$(date +%s)
run hang "$wd" --max-seconds 5
elapsed=$(( $(date +%s) - start ))
check "the cap ended the run in time (${elapsed}s)" $((elapsed > 30))
cpid="$(cat "$wd/child.pid" 2>/dev/null)"; fpid="$(cat "$wd/fake.pid" 2>/dev/null)"
[ -n "$cpid" ] && [ -n "$fpid" ]; check "the fake CLI and its child started" $?
if [ -n "$cpid" ]; then wait_gone "$cpid" 8; check "the CLI's child is gone after the cap" $?; fi
if [ -n "$fpid" ]; then wait_gone "$fpid" 8; check "the CLI is gone after the cap" $?; fi
grep -q '^status=143$' "$wd/meta.env"; check "the cap is recorded as status 143" $?
grep -q 'wall-clock cap of 5s' "$tmp/last.log"; check "the cap says why it stopped the CLI" $?
grep -q 'Terminated' "$tmp/last.log"; check "no shell job message ('Terminated') in the output" $((1 - $?))

# 4. A TERM sent to the script (Ctrl-C ends the same way) stops the CLI's group too.
wd="$tmp/term"
echo hang > "$tmp/mode"
"$script" --factoria "$engine" --cli-bin "$cli" --reporter "$reporter" --workdir "$wd" --out "$wd.result.json" --max-seconds 300 > "$tmp/last.log" 2>&1 &
spid=$!
wait_for_file "$wd/child.pid" 20; check "the fake CLI started under the script" $?
cpid="$(cat "$wd/child.pid" 2>/dev/null)"; fpid="$(cat "$wd/fake.pid" 2>/dev/null)"
kill -TERM "$spid" 2>/dev/null
wait_gone "$spid" 15; check "the script ended after TERM" $?
if [ -n "$cpid" ]; then wait_gone "$cpid" 10; check "the CLI's child is gone after TERM" $?; fi
if [ -n "$fpid" ]; then wait_gone "$fpid" 10; check "the CLI is gone after TERM" $?; fi

# 5. The final play.auto has its own cap, and the report still gets written.
wd="$tmp/final"
touch "$engine/hang-play"
run ok "$wd" --final-seconds 4
check "a run whose final play.auto hangs still ends with status 0" $?
rm -f "$engine/hang-play"
grep -q 'final play.auto passed 4s' "$tmp/last.log"; check "the final play.auto was stopped by its cap" $?
grep -q '"reachedLastLevel": false' "$wd.result.json"; check "the stopped play.auto does not count as a win" $?
pp="$(cat "$wd/engine/play-child.pid" 2>/dev/null)"
if [ -n "$pp" ]; then wait_gone "$pp" 8; check "the child of the stopped play.auto is gone" $?; fi

# 6. A path outside the work folder passed to factoria is listed after the run.
wd="$tmp/outside"
run outside "$wd"
check "a run with an outside path still ends with status 0" $?
grep -q 'passed paths outside the work folder' "$tmp/last.log" && grep -q '/tmp/evil.png' "$tmp/last.log"; check "the outside path is listed in the warning" $?

[ $fail -eq 0 ] && echo "agent-cost script: ok"
exit $fail
