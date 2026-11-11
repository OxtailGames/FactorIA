#!/usr/bin/env bash
# What a game costs an AI with no context (docs/AI_COSTS.md, "Measuring it"; ROADMAP M100.1).
#
# Starts an AI CLI non-interactively in an EMPTY folder outside the repository, with only the installed `factoria` on the
# PATH, gives it a fixed brief, records the whole transcript, then reports through `factoria call agent.cost` (tokens and
# steps to the first playable build, the engine errors met, the ones not caught). THIS SPENDS QUOTA: run it by hand.
#
#   scripts/agent-cost.sh [--cli claude] [--factoria DIR] [--model sonnet] [--out FILE] [--max-turns 400]
#                         [--minutes 90] [--workdir DIR] [--reporter BIN] [--report-only WORKDIR]
#
#   --cli          claude (the only one wired in; add a case to run_cli for another)
#   --factoria     folder (or the binary) of the installed engine the AI uses; default ~/FactorIA
#   --out          result file; default feedback/agent-cost/<version>-<cli>.json of this checkout
#   --workdir      the work folder; default a new one under $TMPDIR. Kept afterwards: it holds transcript.jsonl and the
#                  game. It is never inside the repository.
#   --reporter     the factoria that has the `agent.cost` command (default: the one under test; an older install lacks it)
#   --report-only  do not run the AI: build the result from an earlier work folder (its transcript.jsonl and game/)
set -u

# The brief is fixed so that runs compare. Change it only with a new BRIEF_ID, and say so in docs/AI_COSTS.md.
BRIEF_ID="platformer-3-levels-v1"
BRIEF='Make a platformer with three levels. Use the `factoria` command (it is on your PATH) to build the game in the current folder. Work only in this folder, and stop when the game is playable from the first level to the third.'

cli=claude
fdir="$HOME/FactorIA"
model=sonnet
out=""
max_turns=400
minutes=90
workdir=""
reporter=""
report_only=""
while [ $# -gt 0 ]; do
    case "$1" in
        --cli) cli="$2"; shift 2 ;;
        --factoria) fdir="$2"; shift 2 ;;
        --model) model="$2"; shift 2 ;;
        --out) out="$2"; shift 2 ;;
        --max-turns) max_turns="$2"; shift 2 ;;
        --minutes) minutes="$2"; shift 2 ;;
        --workdir) workdir="$2"; shift 2 ;;
        --reporter) reporter="$2"; shift 2 ;;
        --report-only) report_only="$2"; shift 2 ;;
        -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
        *) echo "agent-cost: unknown option $1 (see --help)" >&2; exit 2 ;;
    esac
done

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
# Only the engine's folder plus the system essentials; the CLI itself is called by absolute path.
safe_path="$fdir:/usr/bin:/bin:/usr/sbin:/sbin"
status=0
elapsed=0
[ -n "$report_only" ] && [ -f "$workdir/meta.env" ] && . "$workdir/meta.env"

if [ -z "$report_only" ]; then
    if [ -n "$(ls -A "$workdir/game")" ]; then echo "agent-cost: $workdir/game is not empty" >&2; exit 2; fi
    cli_bin="$(command -v "$cli")" || { echo "agent-cost: $cli is not installed" >&2; exit 2; }
    : > "$transcript"
    echo "agent-cost: $cli $model, factoria $version, work folder $workdir"

    run_cli() {
        case "$cli" in
            claude)
                # acceptEdits plus an allow-list; anything else is refused (nobody is there to ask). Never bypassPermissions.
                cd "$workdir/game" || return 2
                env -i HOME="$HOME" USER="${USER:-}" LOGNAME="${USER:-}" TMPDIR="${TMPDIR:-/tmp}" SHELL=/bin/sh \
                    PATH="$safe_path" TERM=dumb LANG="${LANG:-en_US.UTF-8}" \
                    "$cli_bin" -p "$BRIEF" --model "$model" --output-format stream-json --verbose \
                    --setting-sources project --strict-mcp-config --disable-slash-commands \
                    --permission-mode acceptEdits --max-turns "$max_turns" \
                    --allowedTools "Read" "Write" "Edit" "Glob" "Grep" "Bash(factoria:*)" "Bash(ls:*)" "Bash(cat:*)" \
                    "Bash(mkdir:*)" "Bash(pwd)" "Bash(head:*)" "Bash(tail:*)" "Bash(wc:*)" "Bash(grep:*)" "Bash(echo:*)" \
                    "Bash(cp:*)" "Bash(mv:*)" \
                    < /dev/null > "$transcript" 2> "$workdir/stderr.log"
                ;;
            *) echo "agent-cost: no entry for CLI '$cli' (add one to run_cli)" >&2; return 2 ;;
        esac
    }
    started=$(date +%s)
    run_cli &
    pid=$!
    # Wall-clock safety net (macOS has no timeout).
    ( sleep $((minutes * 60)); kill -TERM "$pid" 2>/dev/null; sleep 5; kill -KILL "$pid" 2>/dev/null ) &
    wd=$!
    wait "$pid"; status=$?
    kill "$wd" 2>/dev/null; wait "$wd" 2>/dev/null
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
