#!/usr/bin/env bash
# What a game costs an AI with no context (docs/AI_COSTS.md, "Measuring it"; ROADMAP M100.1).
#
# Starts an AI CLI non-interactively in an EMPTY folder outside the repository, with only the installed `factoria` on the
# PATH, gives it a fixed brief, records the whole transcript, then reports through `factoria call agent.cost` (tokens and
# steps to the first playable build, the engine errors met, the ones not caught). THIS SPENDS QUOTA: run it by hand.
#
#   scripts/agent-cost.sh [--cli claude] [--factoria DIR] [--model sonnet] [--out FILE] [--max-turns 400]
#                         [--max-seconds 5400] [--max-usd 5] [--workdir DIR] [--reporter BIN] [--report-only WORKDIR]
#
#   --cli          claude (the only one wired in; add a case to run_cli for another)
#   --factoria     folder (or the binary) of the installed engine the AI uses; default ~/FactorIA
#   --out          result file; default feedback/agent-cost/<version>-<cli>.json of this checkout
#   --workdir      the work folder; default a new one under $TMPDIR. Kept afterwards: it holds transcript.jsonl and the
#                  game. It is never inside the repository.
#   --reporter     the factoria that has the `agent.cost` command (default: the one under test; an older install lacks it)
#   --max-seconds  wall-clock cap (default 5400 = 90 min); --max-usd the CLI's own spending cap (default 5)
#   --final-seconds wall-clock cap of the `play.auto` that checks the finished game (default 600)
#   --cli-bin      path of the CLI to run instead of the one on the PATH (tests use a fake one)
#   --isolated-home run the CLI with a throw-away HOME and CLAUDE_CONFIG_DIR (no global CLAUDE.md or memory of yours). This
#                  is automatic when ANTHROPIC_API_KEY or CLAUDE_CODE_OAUTH_TOKEN is set (the CLI logs in with it); without
#                  either the CLI keeps the real HOME, because its login lives there, and the result says so
#   --report-only  do not run the AI: build the result from an earlier work folder (its transcript.jsonl and game/)
#   --print-policy print the allow and deny rules given to the CLI and exit (nothing runs)
set -u

# The brief is fixed so that runs compare. Change it only with a new BRIEF_ID, and say so in docs/AI_COSTS.md.
BRIEF_ID="platformer-3-levels-v1"
BRIEF='Make a platformer with three levels. Use the `factoria` command (it is on your PATH) to build the game in the current folder. Work only in this folder, and stop when the game is playable from the first level to the third.'

cli=claude
fdir="$HOME/FactorIA"
model=sonnet
out=""
max_turns=400
max_seconds=5400
max_usd=5
final_seconds=600
cli_bin_override=""
workdir=""
reporter=""
report_only=""
print_policy=""
force_isolated=""
while [ $# -gt 0 ]; do
    case "$1" in
        --cli) cli="$2"; shift 2 ;;
        --factoria) fdir="$2"; shift 2 ;;
        --model) model="$2"; shift 2 ;;
        --out) out="$2"; shift 2 ;;
        --max-turns) max_turns="$2"; shift 2 ;;
        --max-seconds) max_seconds="$2"; shift 2 ;;
        --max-usd) max_usd="$2"; shift 2 ;;
        --final-seconds) final_seconds="$2"; shift 2 ;;
        --cli-bin) cli_bin_override="$2"; shift 2 ;;
        --workdir) workdir="$2"; shift 2 ;;
        --reporter) reporter="$2"; shift 2 ;;
        --report-only) report_only="$2"; shift 2 ;;
        --isolated-home) force_isolated=1; shift ;;
        --print-policy) print_policy=1; shift ;;
        -h|--help) sed -n '2,24p' "$0"; exit 0 ;;
        *) echo "agent-cost: unknown option $1 (see --help)" >&2; exit 2 ;;
    esac
done

# What the measured AI may run (docs/AI_COSTS.md, "What the measured AI may do"). `factoria call` is allowed ONLY as
# `factoria call <family>.<command>` with the command name right after `call` (no flag, no quote before it, so no --batch,
# --json, -p...), for the families a game developer needs and that stay offline. A deny rule wins over an allow rule and is
# the second line; the first is the allow-list, and behind both the throw-away HOME and the engine copy.
allowed=()
for sub in new templates run screenshot test validate commands api docs version help; do allowed+=("Bash(factoria $sub:*)"); done
for fam in scene tilemap ui game play physics prefab script input render load nav feel vfx i18n perf anim shader material \
           project.info project.validate project.test project.templates checkpoint.list checkpoint.diff checkpoint.create \
           docs api skills.list skills.read; do
    case "$fam" in *.*) allowed+=("Bash(factoria call $fam*)") ;; *) allowed+=("Bash(factoria call $fam.*)") ;; esac
done
denied=()
for sub in setup feedback ai editor export mcp dap hooks session; do denied+=("Bash(factoria $sub:*)"); done
for pre in "-*" "\"*" "'*" "*--batch*" "*--project*" setup feedback ai engine update self_update publish ios_sim skills.new platform \
           project.export project.create assets image model music audio fs storage sign; do
    case "$pre" in
        [-\"\'*]*) denied+=("Bash(factoria call $pre)") ;;
        *) denied+=("Bash(factoria call $pre*)") ;;
    esac
done
# Paths: `factoria new`, `screenshot` and `game.screenshot` write where they are told, absolute or not. No argument may start with
# `/`, `~` or `..`, in the command line or inside a JSON argument (a quote right before), so a file lands in the work folder.
# This is the first line only (a glob cannot see every spelling); the transcript is audited for the rest after the run.
for sub in new templates run screenshot test validate commands api docs version help call; do
    for pat in '/*' '* /*' '*"/*' "*'/*" '*@/*' '~*' '* ~*' '*"~*' '*@~*' '..*' '* ..' '*../*'; do denied+=("Bash(factoria $sub $pat)"); done
done
if [ -n "$print_policy" ]; then
    for r in "${allowed[@]}"; do echo "allow $r"; done
    for r in "${denied[@]}"; do echo "deny $r"; done
    exit 0
fi

repo="$(cd "$(dirname "$0")/.." && pwd)"
[ -f "$fdir" ] && fdir="$(dirname "$fdir")"
fdir="$(cd "$fdir" 2>/dev/null && pwd)" || { echo "agent-cost: --factoria folder not found" >&2; exit 2; }
fbin="$fdir/factoria"
[ -x "$fbin" ] || { echo "agent-cost: $fbin is not executable" >&2; exit 2; }
version="$("$fbin" --version | awk '{print $2}')"
[ -n "$reporter" ] || reporter="$fbin"
[ -n "$out" ] || out="$repo/feedback/agent-cost/$version-$cli.json"
mkdir -p "$(dirname "$out")"

if [ -n "$report_only" ]; then workdir="$report_only"; fi
if [ -z "$workdir" ]; then workdir="$(mktemp -d "${TMPDIR:-/tmp}/agent-cost.XXXXXX")"; fi
mkdir -p "$workdir/game"
case "$(cd "$workdir" && pwd -P)" in
    "$repo"|"$repo"/*) echo "agent-cost: the work folder must be outside the repository" >&2; exit 2 ;;
esac
transcript="$workdir/transcript.jsonl"
status=0
elapsed=0
meta_cli_version=""
meta_home_isolated=""
[ -n "$report_only" ] && [ -f "$workdir/meta.env" ] && . "$workdir/meta.env"

# ---- processes -----------------------------------------------------------------------------------------------------------------
# The CLI and the final play.auto run as their own process group (job control), so a cap, Ctrl-C or kill can stop the program AND
# everything it started. `cleanup_pid` is the group leader being supervised: the traps below end its group when this script is
# interrupted or ends, so a Ctrl-C never leaves an orphan CLI spending quota (with `set -m` the CLI is not in this script's group).
cleanup_pid=""
cleanup_wd=""
stop_group() {
    [ -n "$cleanup_wd" ] && kill -TERM "$cleanup_wd" 2>/dev/null
    if [ -n "$cleanup_pid" ]; then
        local pid="$cleanup_pid"
        cleanup_pid=""
        kill -TERM -- "-$pid" 2>/dev/null && { sleep 2; kill -KILL -- "-$pid" 2>/dev/null; }
    fi
    cleanup_wd=""
}
trap 'echo "agent-cost: interrupted: stopping the CLI" >&2; stop_group; exit 130' INT
trap 'echo "agent-cost: terminated: stopping the CLI" >&2; stop_group; exit 143' TERM
trap 'stop_group' EXIT

# run_capped SECONDS COMMAND [ARGS...]: runs COMMAND (a function or a program) as its own process group; after SECONDS of wall-clock
# time it ends the group (TERM, KILL after 5 s). Sets run_status (its exit status; 143 when the cap ended it) and run_capped_hit (1
# when the cap fired). Whatever the program left running when it ended is stopped too.
run_status=0
run_capped_hit=0
run_capped() {
    local cap="$1" marker pid wd
    shift
    marker="$(mktemp "$workdir/.capped.XXXXXX")"
    set -m
    "$@" &
    pid=$!
    cleanup_pid=$pid
    ( sleep "$cap" & sl=$!
      trap 'kill "$sl" 2>/dev/null; exit 0' TERM
      wait "$sl"
      echo 1 > "$marker"
      echo "agent-cost: the wall-clock cap of ${cap}s passed: stopping the program" >&2
      kill -TERM -- "-$pid" 2>/dev/null; sleep 5; kill -KILL -- "-$pid" 2>/dev/null ) &
    wd=$!
    cleanup_wd=$wd
    { wait "$pid"; } 2>/dev/null
    run_status=$?
    if [ -s "$marker" ]; then kill -KILL "$wd" 2>/dev/null   # the cap fired: it is in its 5 s grace sleep, which ends alone
    else kill -TERM "$wd" 2>/dev/null; fi                      # still waiting: its trap stops the long sleep
    { wait "$wd"; } 2>/dev/null
    kill -TERM -- "-$pid" 2>/dev/null   # anything it left running (a server the AI started...)
    set +m
    cleanup_pid=""
    cleanup_wd=""
    run_capped_hit=0
    [ -s "$marker" ] && run_capped_hit=1
    rm -f "$marker"
    return 0
}

# json_str TEXT: TEXT as a JSON string (quotes and backslashes escaped; the paths and names given here have no control characters).
json_str() { printf '"%s"' "$(printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"; }
# sh_quote TEXT: TEXT in single quotes for /bin/sh, whatever it holds (a quote in the work folder's path included).
sh_quote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }

# ---- the run -------------------------------------------------------------------------------------------------------------------
home_isolated=0
if [ -z "$report_only" ]; then
    if [ -n "$(ls -A "$workdir/game")" ]; then echo "agent-cost: $workdir/game is not empty" >&2; exit 2; fi
    cli_bin="${cli_bin_override:-$(command -v "$cli")}" || { echo "agent-cost: $cli is not installed" >&2; exit 2; }
    cli_version="$("$cli_bin" --version 2>/dev/null | head -n 1)"
    : > "$transcript"
    echo "agent-cost: $cli ${cli_version:-(version unknown)} $model, factoria $version, work folder $workdir"

    # The AI never touches the installed engine nor the real home: it gets a COPY of the engine and a `factoria` wrapper that
    # runs the copy with a throw-away HOME (so `setup`, `feedback share`, the updater... have nothing of yours to change).
    mkdir -p "$workdir/bin" "$workdir/home"
    cp -R "$fdir" "$workdir/engine"
    printf '#!/bin/sh\nHOME=%s exec %s "$@"\n' "$(sh_quote "$workdir/home")" "$(sh_quote "$workdir/engine/factoria")" > "$workdir/bin/factoria"
    chmod +x "$workdir/bin/factoria"

    # The CLI's own HOME: its login normally lives in the real one (Keychain or ~/.claude), and so do your global CLAUDE.md and
    # memory, which would load into the run and change what it costs. With an API key or an OAuth token in the environment the CLI
    # needs no stored login, so it gets a throw-away HOME and CLAUDE_CONFIG_DIR; without, it keeps the real HOME and the result
    # (notes, `homeIsolated: false`) and this script say so.
    cli_env=(USER="${USER:-}" LOGNAME="${USER:-}" TMPDIR="${TMPDIR:-/tmp}" SHELL=/bin/sh TERM=dumb LANG="${LANG:-en_US.UTF-8}")
    [ -n "${ANTHROPIC_API_KEY:-}" ] && cli_env+=(ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY")
    [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ] && cli_env+=(CLAUDE_CODE_OAUTH_TOKEN="$CLAUDE_CODE_OAUTH_TOKEN")
    if [ -n "$force_isolated" ] || [ -n "${ANTHROPIC_API_KEY:-}" ] || [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
        home_isolated=1
        mkdir -p "$workdir/cli-home/.claude"
        cli_env+=(HOME="$workdir/cli-home" CLAUDE_CONFIG_DIR="$workdir/cli-home/.claude")
    else
        cli_env+=(HOME="$HOME")
        echo "agent-cost: WARNING the CLI keeps your real HOME (its login lives there): your global CLAUDE.md and memory may load into the run," >&2
        echo "agent-cost:   and transcript.jsonl may hold private data. Set ANTHROPIC_API_KEY or CLAUDE_CODE_OAUTH_TOKEN for a clean HOME." >&2
    fi

    # Only these `factoria` subcommands may run; the file tools need no entry: acceptEdits writes inside the work folder
    # and refuses every path outside it (checked: docs/AI_COSTS.md). Nothing else is allowed, and the denied ones win.
    safe_path="$workdir/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    run_cli() {
        case "$cli" in
            claude)
                cd "$workdir/game" || exit 2
                # exec: the pid of this job is the CLI's own. Never bypassPermissions.
                exec env -i "${cli_env[@]}" PATH="$safe_path" \
                    "$cli_bin" -p "$BRIEF" --model "$model" --output-format stream-json --verbose \
                    --setting-sources project --strict-mcp-config --disable-slash-commands \
                    --permission-mode acceptEdits --max-turns "$max_turns" --max-budget-usd "$max_usd" \
                    --allowedTools "${allowed[@]}" --disallowedTools "${denied[@]}" \
                    < /dev/null > "$transcript" 2> "$workdir/stderr.log"
                ;;
            *) echo "agent-cost: no entry for CLI '$cli' (add one to run_cli)" >&2; exit 2 ;;
        esac
    }
    started=$(date +%s)
    # Wall-clock safety net (macOS has no timeout): ends the CLI's whole group, and the watchdog ends with it when the CLI ends first.
    run_capped "$max_seconds" run_cli
    status=$run_status
    elapsed=$(( $(date +%s) - started ))
    echo "agent-cost: the CLI ended with status $status after ${elapsed}s"
    printf "status=%d\nelapsed=%d\nmeta_home_isolated=%d\nmeta_cli_version=%q\n" "$status" "$elapsed" "$home_isolated" "$cli_version" > "$workdir/meta.env"
else
    cli_version="$meta_cli_version"
    home_isolated="${meta_home_isolated:-}"
fi
safe_path="$workdir/bin:/usr/bin:/bin:/usr/sbin:/sbin"
[ -x "$workdir/bin/factoria" ] || safe_path="$fdir:/usr/bin:/bin:/usr/sbin:/sbin"

# ---- checks on what the run did ------------------------------------------------------------------------------------------------
if [ -s "$transcript" ]; then
    # The init message lists what the CLI loaded: MCP servers or plugins of yours would change the run.
    init="$(grep -m1 '"subtype":"init"' "$transcript" 2>/dev/null)"
    if printf '%s' "$init" | grep -Eq '"(mcp_servers|plugins)":\[\{'; then
        echo "agent-cost: WARNING the init message lists MCP servers or plugins: the CLI loaded settings of yours (check the init line of the transcript)" >&2
    fi
    if [ -z "$init" ]; then echo "agent-cost: note: the transcript has no init message" >&2; fi
    n="$(grep -c -F "$HOME/" "$transcript" 2>/dev/null)"
    if [ "${n:-0}" -gt 0 ]; then echo "agent-cost: WARNING transcript.jsonl names your home folder in $n line(s): read it before sharing it" >&2; fi
    # A path outside the work folder passed to `factoria` (the deny rules are globs; this reads what actually ran): list it.
    outside="$(grep -oE '"command":"factoria([^"\\]|\\.)*' "$transcript" 2>/dev/null | grep -E "[ \"'@\\\\](/|~|\.\./)" | cut -c1-200 | head -n 10)"
    if [ -n "$outside" ]; then
        echo "agent-cost: WARNING the AI passed paths outside the work folder to factoria (check nothing was written there):" >&2
        printf '%s\n' "$outside" | sed 's/^/agent-cost:   /' >&2
    fi
fi

# Does the FINAL game reach the last level? play.auto of the engine the AI used (its copy, throw-away HOME), in the game's folder,
# with a wall-clock cap: a game that never ends cannot hold the script.
finalplay="$workdir/final-play.json"
final_bin="$workdir/bin/factoria"
[ -x "$final_bin" ] || final_bin="$fbin"
final_play() {
    cd "$workdir/game" || exit 2
    PATH="$safe_path" exec "$final_bin" call --project . play.auto > "$finalplay" 2> "$workdir/final-play.err" < /dev/null
}
if [ -f "$workdir/game/factoria.json" ]; then
    run_capped "$final_seconds" final_play
    if [ "$run_capped_hit" = 1 ]; then
        echo "agent-cost: the final play.auto passed ${final_seconds}s and was stopped" >&2
        echo '{"error":"the final play.auto did not end within the time cap"}' > "$finalplay"
    fi
else
    echo '{"error":"no factoria.json in the work folder"}' > "$finalplay"
fi

# The arguments of agent.cost go in a file (@file): no quoting of paths or names inside a shell string.
argsfile="$workdir/agent-cost-args.json"
home_json=""
[ "$home_isolated" = 1 ] && home_json=',"homeIsolated":true'
[ "$home_isolated" = 0 ] && home_json=',"homeIsolated":false'
printf '{"transcript":%s,"finalPlay":%s,"cli":%s,"model":%s,"brief":%s,"exitStatus":%d,"elapsedSeconds":%d,"factoriaVersion":%s,"cliVersion":%s%s}\n' \
    "$(json_str "$transcript")" "$(json_str "$finalplay")" "$(json_str "$cli")" "$(json_str "$model")" "$(json_str "$BRIEF_ID")" \
    "$status" "$elapsed" "$(json_str "$version")" "$(json_str "${cli_version:-}")" "$home_json" > "$argsfile"
# Written beside the result and moved in only when the report worked: a failure never leaves a half file nor replaces an older result.
if "$reporter" call agent.cost "@$argsfile" > "$out.tmp"; then
    mv -f "$out.tmp" "$out"
else
    rm -f "$out.tmp"
    echo "agent-cost: the report failed (does $reporter have agent.cost? use --reporter)" >&2
    echo "agent-cost: transcript $transcript"
    exit 1
fi
echo "agent-cost: result $out"
echo "agent-cost: transcript $transcript"
