#!/usr/bin/env bash
# Runs the native Windows check (MSVC Debug build + full ctest + the example games on a Release build, i.e.
# `scripts\agent-build.ps1 build\agent-preflight -Test -Examples`) on the Windows PC over SSH, for the commit checked
# out here. The check owns a folder on the PC (default %USERPROFILE%\FactorIA-remote: a bare repository repo.git that the
# Mac pushes refs/heads/preflight/<branch> to, and the worktree work\ it builds in, kept between runs so the build is
# incremental). Nothing the user has on the PC is touched, and a folder that is a git repository of its own is refused.
#
#   scripts/ci-remote-windows.sh [--no-examples] [--wsl] [--wait] [--wait-timeout SECONDS]
#
#   --no-examples   skip the Release build and the example games' tests (Debug build + ctest only)
#   --wsl           also run `scripts/ci-local.sh linux android` in the PC's WSL Ubuntu-24.04, in its own clone
#                   (~/FactorIA-preflight), fed from the Windows worktree's repository; ANDROID_NDK_HOME must be
#                   exported in the WSL ~/.profile (CLAUDE.md), or the android job is skipped
#   --check         only check that the PC answers and that its folder is ready (created on first use), then exit
#   --wait          when the PC does not answer, wait for it to come up without asking (for when the user said they are
#                   switching it on)
#   --wait-timeout  how long to wait for the PC to come up (default 300 s)
#
# The PC is often off and this script never switches it on or puts it to sleep. The first thing done is a 5 s
# reachability check. If the PC does not answer: in a terminal the script asks whether you are switching it on (Enter =
# wait for it, s = skip, exit 77); without a terminal (an AI agent) it exits 77 at once, so the agent asks the user, and
# --wait makes it wait instead.
# Only COMMITTED work is tested: uncommitted changes to tracked files are not sent (a warning lists them).
# Logs come back to build/ci-logs/windows-remote/.
# The tests that open a window (ctest label "window": editor autotests, player frames, exported game) cannot run in an
# SSH session, which has no desktop: they run in the desktop session of the user logged in on the PC, through a one-shot
# scheduled task that is deleted afterwards (scripts/windows-run-interactive.ps1). With nobody logged in they are
# reported as SKIPPED (not passed) and the exit status is 77.
# Exit status: 0 everything passed, 1 a build or test failed, 77 the check could not be done or finished: not set up,
# the PC is off/unreachable, the connection was lost mid-run, or the windowed tests were skipped for lack of a logged-in
# user (never reported as a failure; scripts/ci-preflight.sh records SKIP).
#
# Test hooks: FACTORIA_SSH / FACTORIA_SCP replace ssh / scp, FACTORIA_WINDOWS_HOST the `factoria-windows` alias,
# FACTORIA_WINDOWS_DIR the stored folder on the PC, FACTORIA_ASSUME_TTY=1 treats stdin as a terminal,
# FACTORIA_REMOTE_FLAVOR=posix makes the commands that run on the far side POSIX shell instead of PowerShell (a fake
# "PC" on this machine; FACTORIA_REMOTE_BUILD_CMD is then the build, FACTORIA_REMOTE_WINDOW_CMD the windowed tests).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2
EXAMPLES=1 WSL=0 WAIT=0 WAIT_TIMEOUT=300 CHECK=0
while [ $# -gt 0 ]; do
    case "$1" in
        --no-examples) EXAMPLES=0 ;;
        --wsl) WSL=1 ;;
        --check) CHECK=1 ;;
        --wait) WAIT=1 ;;
        --wait-timeout) WAIT_TIMEOUT="${2:-}"; shift ;;
        --wait-timeout=*) WAIT_TIMEOUT="${1#*=}" ;;
        -h|--help) sed -n '2,40p' "$0"; exit 0 ;;
        *) echo "error: unknown argument '$1' (see --help)" >&2; exit 2 ;;
    esac
    shift
done
case "$WAIT_TIMEOUT" in ''|*[!0-9]*) echo "error: --wait-timeout takes a number of seconds" >&2; exit 2 ;; esac

SSH_BIN="${FACTORIA_SSH:-ssh}"
SCP_BIN="${FACTORIA_SCP:-scp}"
HOST="${FACTORIA_WINDOWS_HOST:-factoria-windows}"
FLAVOR="${FACTORIA_REMOTE_FLAVOR:-powershell}"
COMMON="$(git rev-parse --path-format=absolute --git-common-dir)"
CONF="$(dirname "$COMMON")/build/windows-remote.conf"
conf_get() { [ -f "$CONF" ] && sed -n "s/^$1=//p" "$CONF" | head -1; }
DIR="${FACTORIA_WINDOWS_DIR:-$(conf_get FACTORIA_WINDOWS_DIR)}"

SKIP_MSG="Windows PC off/unreachable: native MSVC check skipped; the Docker MinGW+Wine job and the Windows file-rules emulation still cover part of it."
not_set_up() {
    echo "ci-remote-windows: $1" >&2
    echo "  Set it up once: scripts/setup-windows-remote.sh (it prints what to run on the PC; docs/BUILDING.md, \"Checking Windows from the Mac\")." >&2
    exit 77
}
[ -n "$DIR" ] || not_set_up "the PC's folder for the check is not stored ($CONF)."
DIR="$(printf '%s' "$DIR" | tr '\\' '/')"
# The check owns this folder on the PC: a bare repository (repo.git) the Mac pushes to and the worktree (work) it builds in.
# It never uses a clone of the user's (a folder with a .git of its own, or any other content, is refused).
REPO="$DIR/repo.git"
WT="$DIR/work"

# Quote for a single-quoted PowerShell / sh string.
q() { printf '%s' "$1" | sed "s/'/''/g"; }

remote() { "$SSH_BIN" -o BatchMode=yes "$HOST" "$1"; }

# What runs on the PC to find or create the folder this check owns. Exit 3 = refused (not ours), other non-zero = git missing.
if [ "$FLAVOR" = posix ]; then
    ENSURE="d='$(q "$DIR")'; g=\"\$d/repo.git\"; if [ -e \"\$d/.git\" ]; then echo \"REFUSED: \$d is a git repository of its own; use a dedicated folder\"; exit 3; fi; if [ ! -d \"\$g\" ]; then if [ -d \"\$d\" ] && [ -n \"\$(ls -A \"\$d\")\" ]; then echo \"REFUSED: \$d is not empty and is not a FactorIA-remote folder; use an empty or new one\"; exit 3; fi; mkdir -p \"\$d\" && git init --bare -q \"\$g\" || exit 4; fi; git -C \"\$g\" rev-parse --is-bare-repository >/dev/null"
else
    ENSURE="\$d='$(q "$DIR")'; \$g = \$d + '/repo.git'; if (Test-Path (\$d + '/.git')) { 'REFUSED: ' + \$d + ' is a git repository of its own, not this check; use a dedicated folder'; exit 3 }; if (-not (Test-Path \$g)) { if ((Test-Path \$d) -and @(Get-ChildItem -Force \$d).Count -gt 0) { 'REFUSED: ' + \$d + ' is not empty and is not a FactorIA-remote folder; use an empty or new one'; exit 3 }; New-Item -ItemType Directory -Force \$d | Out-Null; git init --bare -q \$g; if (\$LASTEXITCODE) { exit 4 } }; git -C \$g rev-parse --is-bare-repository | Out-Null; exit \$LASTEXITCODE"
fi

# Reachability: 0 answers (and the folder is ready), 1 refused / git missing / ssh refused the key, 2 no answer (off, asleep, other network).
PROBE_OUT=""
probe() {
    PROBE_OUT="$("$SSH_BIN" -o BatchMode=yes -o ConnectTimeout=5 "$HOST" "$ENSURE" 2>&1)"
    local rc=$?
    [ "$rc" -eq 0 ] && return 0
    if [ "$rc" -eq 255 ]; then
        case "$PROBE_OUT" in *"Permission denied"*|*"Host key verification"*|*"Could not resolve"*) return 1 ;; esac
        return 2
    fi
    return 1
}

# Exit 77 for a connection that went away (not a test failure), saying which part had run.
interrupted() {
    echo "== INTERRUPTED: the connection to the PC was lost during: $1. This is NOT a build or test failure." >&2
    echo "   $2" >&2
    echo "   (The PC may have gone to sleep or off; run the script again.)" >&2
    exit 77
}

SHA="$(git rev-parse HEAD)"
BRANCH="$(git symbolic-ref --short -q HEAD || echo detached)"
REF="preflight/$(printf '%s' "$BRANCH" | sed 's/[^A-Za-z0-9._-]/-/g')"

DIRTY="$(git status --porcelain --untracked-files=no)"
if [ -n "$DIRTY" ]; then
    echo "WARNING: uncommitted changes are NOT part of this check (only commit ${SHA:0:10} is sent):" >&2
    echo "$DIRTY" | sed 's/^/    /' >&2
fi

echo "== Windows check of ${SHA:0:10} ($BRANCH) on $HOST, folder $DIR"
probe; P=$?
if [ "$P" -eq 1 ]; then
    not_set_up "'ssh $HOST' answers but the PC's folder for the check is not usable: ${PROBE_OUT:-no output}"
fi
if [ "$P" -eq 2 ]; then
    echo "ci-remote-windows: $SKIP_MSG" >&2
    if [ "$WAIT" -eq 0 ]; then
        if [ -t 0 ] || [ "${FACTORIA_ASSUME_TTY:-0}" = 1 ]; then
            printf 'The Windows PC is off or unreachable. Can you switch it on? Enter = I am switching it on, wait for it; s = skip: ' >&2
            read -r ANSWER
            case "$ANSWER" in s|S|skip|n|N) echo "ci-remote-windows: skipped at your request." >&2; exit 77 ;; esac
        else
            echo "  (No terminal to ask on.) Ask the user to switch the PC on, then run this again with --wait [--wait-timeout SECONDS]." >&2
            exit 77
        fi
    fi
    echo "== waiting up to ${WAIT_TIMEOUT}s for the PC to answer ssh (switch it on)"
    START=$SECONDS NEXT_NOTE=15
    while :; do
        probe; P=$?
        [ "$P" -eq 0 ] && break
        if [ "$P" -eq 1 ]; then not_set_up "the PC is up but ssh cannot use it: ${PROBE_OUT:-no output}"; fi
        ELAPSED=$((SECONDS - START))
        if [ "$ELAPSED" -ge "$WAIT_TIMEOUT" ]; then
            echo "ci-remote-windows: the PC did not answer in ${WAIT_TIMEOUT}s. $SKIP_MSG" >&2
            exit 77
        fi
        if [ "$ELAPSED" -ge "$NEXT_NOTE" ]; then echo "   still waiting for the PC (${ELAPSED}s)..."; NEXT_NOTE=$((NEXT_NOTE + 15)); fi
        sleep 3
    done
    echo "== the PC is up after $((SECONDS - START))s"
fi

if [ "$CHECK" -eq 1 ]; then echo "== the PC answers and $DIR is ready"; exit 0; fi

# From here the PC answered. A command that fails with the PC no longer answering is an interruption, not a failure.
fail_or_interrupted() {
    if probe; then echo "ci-remote-windows: $1" >&2; exit 1; fi
    interrupted "$2" "$3"
}

echo "== pushing to refs/heads/$REF"
if ! GIT_SSH_COMMAND="$SSH_BIN -o BatchMode=yes -o ConnectTimeout=5" git push --force --quiet \
        --receive-pack="git -C '$(q "$REPO")' receive-pack" "$HOST:." "$SHA:refs/heads/$REF"; then
    fail_or_interrupted "the push to the PC failed (is git installed there and the clone not damaged?)" \
        "the push" "Nothing was built."
fi

echo "== preparing the worktree $WT"
if [ "$FLAVOR" = posix ]; then
    PREP="w='$(q "$WT")'; r='$(q "$REPO")'; if [ -e \"\$w/.git\" ]; then git -C \"\$w\" checkout -q --force --detach $SHA; else git -C \"\$r\" worktree prune; git -C \"\$r\" worktree add -q --force --detach \"\$w\" $SHA; fi && git -C \"\$w\" reset -q --hard $SHA && git -C \"\$w\" clean -fdq"
else
    PREP="\$w='$(q "$WT")'; \$r='$(q "$REPO")'; if (Test-Path (\$w + '/.git')) { git -C \$w checkout --force --detach $SHA } else { git -C \$r worktree prune; git -C \$r worktree add --force --detach \$w $SHA }; if (\$LASTEXITCODE -eq 0) { git -C \$w reset --hard $SHA; git -C \$w clean -fdq }; exit \$LASTEXITCODE"
fi
if ! remote "$PREP"; then
    fail_or_interrupted "could not prepare the worktree on the PC" "preparing the worktree" "The commit was pushed; nothing was built."
fi

STATUS=0 LOST="" WINDOWED=""
echo "== building and testing on the PC (the Debug build is incremental after the first run)"
if [ "$FLAVOR" = posix ]; then
    BUILD="cd '$(q "$WT")' && ${FACTORIA_REMOTE_BUILD_CMD:-true}"
else
    FLAGS="-Test -NoWindowTests"; [ "$EXAMPLES" -eq 1 ] && FLAGS="-Test -Examples -NoWindowTests"
    BUILD="Set-Location -LiteralPath '$(q "$WT")'; powershell -NoProfile -ExecutionPolicy Bypass -File scripts\\agent-build.ps1 build\\agent-preflight $FLAGS; exit \$LASTEXITCODE"
fi
# A dead PC is noticed after 4 missed keep-alives (about a minute) instead of the 10 minutes of ~/.ssh/config.
"$SSH_BIN" -o BatchMode=yes -o ServerAliveInterval=15 -o ServerAliveCountMax=4 "$HOST" "$BUILD"; RC=$?
RC_MAIN=$RC
if [ "$RC" -eq 255 ]; then
    RC_MAIN_TXT=INTERRUPTED
    LOST="the Windows build and tests"
    echo "== Windows: INTERRUPTED (connection lost)"
elif [ "$RC" -eq 0 ]; then
    echo "== Windows: PASSED"
else
    echo "== Windows: FAILED (exit $RC)"; STATUS=1
fi

# The windowed tests (ctest label "window": editor autotests, player frames, exported game) need a desktop, which an SSH
# session does not have. They run in the desktop session of the user logged in on the PC (windows-run-interactive.ps1).
if [ -z "$LOST" ]; then
    echo "== windowed tests in the PC's desktop session"
    if [ "$FLAVOR" = posix ]; then
        WINBUILD="cd '$(q "$WT")' && ${FACTORIA_REMOTE_WINDOW_CMD:-exit 78}"
    else
        WINBUILD="Set-Location -LiteralPath '$(q "$WT")'; powershell -NoProfile -ExecutionPolicy Bypass -File scripts\\windows-run-interactive.ps1 -WorkDir '$(q "$WT")'; exit \$LASTEXITCODE"
    fi
    "$SSH_BIN" -o BatchMode=yes -o ServerAliveInterval=15 -o ServerAliveCountMax=4 "$HOST" "$WINBUILD"; RC=$?
    case "$RC" in
        255) LOST="the windowed tests"; WINDOWED="INTERRUPTED"; echo "== Windowed tests: INTERRUPTED (connection lost)" ;;
        0)   WINDOWED="PASSED"; echo "== Windowed tests: PASSED" ;;
        78)  WINDOWED="SKIPPED"; echo "== Windowed tests: SKIPPED (not run, NOT passed): nobody is logged in on the PC desktop" ;;
        79)  WINDOWED="FAILED"; STATUS=1; echo "== Windowed tests: FAILED (did not finish in time)" ;;
        *)   WINDOWED="FAILED"; STATUS=1; echo "== Windowed tests: FAILED (exit $RC)" ;;
    esac
fi

if [ "$WSL" -eq 1 ] && [ -z "$LOST" ]; then
    echo "== WSL Ubuntu-24.04: scripts/ci-local.sh linux android"
    # The perf budgets (CPU time, peak memory) are the numbers of GitHub's 4-vCPU runner; WSL on the PC measures about
    # 10% more peak memory with the same commit (origin/main included), so they fail there without a regression, as in
    # scripts/ci-docker.sh. FA_CI_WSL_PERF=1 runs them anyway.
    WSL_EXCLUDE="${FA_CI_CTEST_EXCLUDE-}"
    if [ -z "$WSL_EXCLUDE" ] && [ "${FA_CI_WSL_PERF:-}" != 1 ]; then
        WSL_EXCLUDE='_perf$'
        echo "   the perf budget tests (*_perf) are not run in WSL: it measures more memory than GitHub's runners (FA_CI_WSL_PERF=1 runs them)"
    fi
    WSLSCRIPT="set -eu
SRC=\$(wslpath -u '$(q "$REPO")'); WTL=\$(wslpath -u '$(q "$WT")')
D=\"\$HOME/FactorIA-preflight\"
[ -d \"\$D/.git\" ] || git init -q \"\$D\"
git -C \"\$D\" -c safe.directory='*' fetch -q --force \"\$SRC\" 'refs/heads/$REF:refs/preflight/current'
git -C \"\$D\" checkout -q --force --detach refs/preflight/current
git -C \"\$D\" clean -fdq
cd \"\$D\"
rc=0; FA_CI_CTEST_EXCLUDE='$(q "$WSL_EXCLUDE")' ./scripts/ci-local.sh linux android || rc=\$?
mkdir -p \"\$WTL/build\"; rm -rf \"\$WTL/build/wsl-ci-logs\"; cp -r build/ci-logs \"\$WTL/build/wsl-ci-logs\" || true
exit \$rc"
    if [ "$FLAVOR" = posix ]; then WSLCMD="sh -s"; else WSLCMD="wsl -d Ubuntu-24.04 --exec bash -l -s"; fi
    printf '%s\n' "$WSLSCRIPT" | "$SSH_BIN" -o BatchMode=yes -o ServerAliveInterval=15 -o ServerAliveCountMax=4 "$HOST" "$WSLCMD"; RC=$?
    if [ "$RC" -eq 255 ]; then LOST="the WSL job"; echo "== WSL: INTERRUPTED (connection lost)"
    elif [ "$RC" -eq 0 ]; then echo "== WSL: PASSED"
    else echo "== WSL: FAILED (exit $RC)"; STATUS=1; fi
fi

if [ -z "$LOST" ]; then
    echo "== copying the logs to build/ci-logs/windows-remote/"
    DEST="$ROOT/build/ci-logs/windows-remote"
    rm -rf "$DEST"; mkdir -p "$DEST"
    if [ "$FLAVOR" = posix ]; then
        COLLECT="w='$(q "$WT")'; mkdir -p \"\$w/build\" && cd \"\$w/build\" && rm -f preflight-logs.zip && zip -q -r preflight-logs.zip agent-preflight* 2>/dev/null || true"
    else
        COLLECT="\$w='$(q "$WT")'; \$s = \$w + '\\build\\preflight-logs'; Remove-Item -Recurse -Force \$s -ErrorAction SilentlyContinue; New-Item -ItemType Directory -Force \$s | Out-Null; foreach (\$d in 'agent-preflight','agent-preflight-release') { Get-ChildItem -Path (\$w + '\\build\\' + \$d + '\\agent-*.log') -ErrorAction SilentlyContinue | ForEach-Object { Copy-Item \$_.FullName (\$s + '\\' + \$d + '-' + \$_.Name) } }; Copy-Item -Recurse -ErrorAction SilentlyContinue (\$w + '\\build\\wsl-ci-logs') (\$s + '\\wsl-ci-logs'); Remove-Item (\$w + '\\build\\preflight-logs.zip') -ErrorAction SilentlyContinue; Compress-Archive -Path (\$s + '\\*') -DestinationPath (\$w + '\\build\\preflight-logs.zip')"
    fi
    if remote "$COLLECT" >/dev/null 2>&1 \
            && "$SCP_BIN" -q -o BatchMode=yes "$HOST:$WT/build/preflight-logs.zip" "$DEST/logs.zip" 2>/dev/null \
            && unzip -o -q "$DEST/logs.zip" -d "$DEST" 2>/dev/null; then
        rm -f "$DEST/logs.zip"
        echo "   logs in $DEST"
    else
        echo "   (could not copy the logs; they are in $WT\\build\\agent-preflight*\\ on the PC)" >&2
    fi
fi

echo "== summary: build and tests (no window): $([ "$RC_MAIN" = 0 ] && echo PASSED || echo "${RC_MAIN_TXT:-FAILED}"); windowed tests: ${WINDOWED:-not reached}"
if [ "$STATUS" -ne 0 ]; then
    echo "== FAILED: Windows check of ${SHA:0:10}; the failing builds and tests are above, full logs in ${DEST:-build/ci-logs/windows-remote}"
    exit 1
fi
if [ -n "$LOST" ]; then
    interrupted "$LOST" "Not a failure, but not a pass either: the check of ${SHA:0:10} did not finish. Everything before it passed or was not reached."
fi
if [ "$WINDOWED" = SKIPPED ]; then
    echo "== INCOMPLETE: everything that runs without a desktop passed, but the windowed tests were NOT run." >&2
    echo "   Log in to the PC (and unlock it if you like), then run this again; it only needs the desktop to be logged in." >&2
    exit 77
fi
echo "== PASSED: Windows check of ${SHA:0:10}${DIRTY:+ (WITHOUT the uncommitted changes listed above)}"
exit 0
