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
#   --cli-bin      path of the CLI to run instead of the one on the PATH (tests use a fake one)
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
cli_bin_override=""
workdir=""
reporter=""
report_only=""
print_policy=""
while [ $# -gt 0 ]; do
    case "$1" in
        --cli) cli="$2"; shift 2 ;;
        --factoria) fdir="$2"; shift 2 ;;
        --model) model="$2"; shift 2 ;;
        --out) out="$2"; shift 2 ;;
        --max-turns) max_turns="$2"; shift 2 ;;
        --max-seconds) max_seconds="$2"; shift 2 ;;
        --max-usd) max_usd="$2"; shift 2 ;;
        --cli-bin) cli_bin_override="$2"; shift 2 ;;
        --workdir) workdir="$2"; shift 2 ;;
        --reporter) reporter="$2"; shift 2 ;;
        --report-only) report_only="$2"; shift 2 ;;
        --print-policy) print_policy=1; shift ;;
        -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
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
[ -n "$report_only" ] && [ -f "$workdir/meta.env" ] && . "$workdir/meta.env"

if [ -z "$report_only" ]; then
    if [ -n "$(ls -A "$workdir/game")" ]; then echo "agent-cost: $workdir/game is not empty" >&2; exit 2; fi
    cli_bin="${cli_bin_override:-$(command -v "$cli")}" || { echo "agent-cost: $cli is not installed" >&2; exit 2; }
    : > "$transcript"
    echo "agent-cost: $cli $model, factoria $version, work folder $workdir"

    # The AI never touches the installed engine nor the real home: it gets a COPY of the engine and a `factoria` wrapper that
    # runs the copy with a throw-away HOME (so `setup`, `feedback share`, the updater... have nothing of yours to change).
    # The CLI itself keeps the real HOME: its login lives there.
    mkdir -p "$workdir/bin" "$workdir/home"
    cp -R "$fdir" "$workdir/engine"
    printf '#!/bin/sh\nHOME=%s exec %s "$@"\n' "'$workdir/home'" "'$workdir/engine/factoria'" > "$workdir/bin/factoria"
    chmod +x "$workdir/bin/factoria"
fi
safe_path="$workdir/bin:/usr/bin:/bin:/usr/sbin:/sbin"
[ -x "$workdir/bin/factoria" ] || safe_path="$fdir:/usr/bin:/bin:/usr/sbin:/sbin"

if [ -z "$report_only" ]; then
    # Only these `factoria` subcommands may run; the file tools need no entry: acceptEdits writes inside the work folder
    # and refuses every path outside it (checked: docs/AI_COSTS.md). Nothing else is allowed, and the denied ones win.
    run_cli() {
        case "$cli" in
            claude)
                cd "$workdir/game" || return 2
                # exec: the pid of this job is the CLI's own. Never bypassPermissions.
                exec env -i HOME="$HOME" USER="${USER:-}" LOGNAME="${USER:-}" TMPDIR="${TMPDIR:-/tmp}" SHELL=/bin/sh \
                    PATH="$safe_path" TERM=dumb LANG="${LANG:-en_US.UTF-8}" \
                    "$cli_bin" -p "$BRIEF" --model "$model" --output-format stream-json --verbose \
                    --setting-sources project --strict-mcp-config --disable-slash-commands \
                    --permission-mode acceptEdits --max-turns "$max_turns" --max-budget-usd "$max_usd" \
                    --allowedTools "${allowed[@]}" --disallowedTools "${denied[@]}" \
                    < /dev/null > "$transcript" 2> "$workdir/stderr.log"
                ;;
            *) echo "agent-cost: no entry for CLI '$cli' (add one to run_cli)" >&2; return 2 ;;
        esac
    }
    started=$(date +%s)
    set -m   # job control: each background job gets its own process group, so the cap can kill the CLI and its children
    run_cli &
    pid=$!
    # Wall-clock safety net (macOS has no timeout): kills the CLI's whole group, and ends with it when the CLI ends first.
    ( sleep "$max_seconds" & sl=$!
      trap 'kill "$sl" 2>/dev/null; exit 0' TERM
      wait "$sl"
      echo "agent-cost: the wall-clock cap of ${max_seconds}s passed: stopping the CLI" >&2
      kill -TERM -- "-$pid" 2>/dev/null; sleep 5; kill -KILL -- "-$pid" 2>/dev/null ) &
    wd=$!
    wait "$pid"; status=$?
    kill -TERM "$wd" 2>/dev/null; wait "$wd" 2>/dev/null
    set +m
    elapsed=$(( $(date +%s) - started ))
    echo "agent-cost: the CLI ended with status $status after ${elapsed}s"
    printf "status=%d\nelapsed=%d\n" "$status" "$elapsed" > "$workdir/meta.env"
fi

# Does the FINAL game reach the last level? play.auto of the engine the AI used, in the game's folder.
finalplay="$workdir/final-play.json"
if [ -f "$workdir/game/factoria.json" ]; then
    ( cd "$workdir/game" && PATH="$safe_path" "$fbin" call --project . play.auto > "$finalplay" 2> "$workdir/final-play.err" )
else
    echo '{"error":"no factoria.json in the work folder"}' > "$finalplay"
fi

args="$("$reporter" call --help >/dev/null 2>&1; printf '{"transcript":"%s","finalPlay":"%s","cli":"%s","model":"%s","brief":"%s","exitStatus":%d,"elapsedSeconds":%d,"factoriaVersion":"%s"}' \
    "$transcript" "$finalplay" "$cli" "$model" "$BRIEF_ID" "$status" "$elapsed" "$version")"
"$reporter" call agent.cost "$args" > "$out" || echo "agent-cost: the report failed (does $reporter have agent.cost? use --reporter)" >&2
echo "agent-cost: result $out"
echo "agent-cost: transcript $transcript"
