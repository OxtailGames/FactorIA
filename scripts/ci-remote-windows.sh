#!/usr/bin/env bash
# Runs the native Windows check (MSVC Debug build + full ctest + the example games on a Release build, i.e.
# `scripts\agent-build.ps1 build\agent-preflight -Test -Examples`) on the Windows PC over SSH, for the commit checked
# out here. Nothing the user has on the PC is touched: the commit goes to the ref refs/heads/preflight/<branch> of the
# PC's clone and is built in its own worktree, FactorIA-preflight, next to the clone.
#
#   scripts/ci-remote-windows.sh [--no-examples] [--wsl]
#
#   --no-examples  skip the Release build and the example games' tests (Debug build + ctest only)
#   --wsl          also run `scripts/ci-local.sh linux android` in the PC's WSL Ubuntu-24.04, in its own clone
#                  (~/FactorIA-preflight), fed from the Windows worktree's repository; ANDROID_NDK_HOME must be
#                  exported in the WSL ~/.profile (CLAUDE.md), or the android job is skipped
#
# Only COMMITTED work is tested: uncommitted changes to tracked files are not sent (a warning lists them).
# Logs come back to build/ci-logs/windows-remote/.
# Exit status: 0 everything passed, 1 something failed, 77 not set up or the PC is unreachable (run
# scripts/setup-windows-remote.sh; docs/BUILDING.md, "Checking Windows from the Mac").
#
# Test hooks (scripts/tests are not shipped): FACTORIA_SSH / FACTORIA_SCP replace ssh / scp, FACTORIA_WINDOWS_HOST the
# `factoria-windows` alias, FACTORIA_WINDOWS_REPO the clone path, FACTORIA_REMOTE_FLAVOR=posix makes the commands that
# run on the far side POSIX shell instead of PowerShell (a fake "PC" on this machine).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2
EXAMPLES=1 WSL=0
for arg in "$@"; do
    case "$arg" in
        --no-examples) EXAMPLES=0 ;;
        --wsl) WSL=1 ;;
        -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
        *) echo "error: unknown argument '$arg' (see --help)" >&2; exit 2 ;;
    esac
done

SSH_BIN="${FACTORIA_SSH:-ssh}"
SCP_BIN="${FACTORIA_SCP:-scp}"
HOST="${FACTORIA_WINDOWS_HOST:-factoria-windows}"
FLAVOR="${FACTORIA_REMOTE_FLAVOR:-powershell}"
COMMON="$(git rev-parse --path-format=absolute --git-common-dir)"
CONF="$(dirname "$COMMON")/build/windows-remote.conf"
REPO="${FACTORIA_WINDOWS_REPO:-}"
if [ -z "$REPO" ] && [ -f "$CONF" ]; then
    REPO="$(sed -n 's/^FACTORIA_WINDOWS_REPO=//p' "$CONF" | head -1)"
fi

not_set_up() {
    echo "ci-remote-windows: $1" >&2
    echo "  Set it up once: scripts/setup-windows-remote.sh (it prints what to run on the PC; docs/BUILDING.md, \"Checking Windows from the Mac\")." >&2
    exit 77
}
[ -n "$REPO" ] || not_set_up "no path of the PC's FactorIA clone is stored ($CONF)."
REPO="$(printf '%s' "$REPO" | tr '\\' '/')"
WT="${REPO%/*}/FactorIA-preflight"

# Quote for a single-quoted PowerShell / sh string.
q() { printf '%s' "$1" | sed "s/'/''/g"; }

remote() { "$SSH_BIN" -o BatchMode=yes "$HOST" "$1"; }

SHA="$(git rev-parse HEAD)"
BRANCH="$(git symbolic-ref --short -q HEAD || echo detached)"
REF="preflight/$(printf '%s' "$BRANCH" | sed 's/[^A-Za-z0-9._-]/-/g')"

DIRTY="$(git status --porcelain --untracked-files=no)"
if [ -n "$DIRTY" ]; then
    echo "WARNING: uncommitted changes are NOT part of this check (only commit ${SHA:0:10} is sent):" >&2
    echo "$DIRTY" | sed 's/^/    /' >&2
fi

echo "== Windows check of ${SHA:0:10} ($BRANCH) on $HOST, clone $REPO"
if ! OUT="$("$SSH_BIN" -o BatchMode=yes -o ConnectTimeout=8 "$HOST" "git -C '$(q "$REPO")' rev-parse --git-dir" 2>&1)"; then
    not_set_up "cannot reach the PC or its FactorIA clone through 'ssh $HOST': ${OUT:-no output}"
fi

echo "== pushing to refs/heads/$REF"
if ! GIT_SSH_COMMAND="$SSH_BIN -o BatchMode=yes" git push --force --quiet \
        --receive-pack="git -C '$(q "$REPO")' receive-pack" "$HOST:." "$SHA:refs/heads/$REF"; then
    echo "ci-remote-windows: the push to the PC failed (is git installed there and the clone not damaged?)" >&2
    exit 1
fi

echo "== preparing the worktree $WT"
if [ "$FLAVOR" = posix ]; then
    PREP="w='$(q "$WT")'; r='$(q "$REPO")'; if [ -e \"\$w/.git\" ]; then git -C \"\$w\" checkout -q --force --detach $SHA; else git -C \"\$r\" worktree prune; git -C \"\$r\" worktree add -q --force --detach \"\$w\" $SHA; fi && git -C \"\$w\" reset -q --hard $SHA && git -C \"\$w\" clean -fdq"
else
    PREP="\$w='$(q "$WT")'; \$r='$(q "$REPO")'; if (Test-Path (\$w + '/.git')) { git -C \$w checkout --force --detach $SHA } else { git -C \$r worktree prune; git -C \$r worktree add --force --detach \$w $SHA }; if (\$LASTEXITCODE -eq 0) { git -C \$w reset --hard $SHA; git -C \$w clean -fdq }; exit \$LASTEXITCODE"
fi
if ! remote "$PREP"; then
    echo "ci-remote-windows: could not prepare the worktree on the PC" >&2
    exit 1
fi

STATUS=0
echo "== building and testing on the PC (the Debug build is incremental after the first run)"
if [ "$FLAVOR" = posix ]; then
    BUILD="cd '$(q "$WT")' && ${FACTORIA_REMOTE_BUILD_CMD:-true}"
else
    FLAGS="-Test"; [ "$EXAMPLES" -eq 1 ] && FLAGS="-Test -Examples"
    BUILD="Set-Location -LiteralPath '$(q "$WT")'; powershell -NoProfile -ExecutionPolicy Bypass -File scripts\\agent-build.ps1 build\\agent-preflight $FLAGS; exit \$LASTEXITCODE"
fi
remote "$BUILD"; RC=$?
if [ "$RC" -eq 255 ]; then echo "ci-remote-windows: the SSH connection dropped during the build" >&2; fi
[ "$RC" -eq 0 ] && echo "== Windows: PASSED" || { echo "== Windows: FAILED (exit $RC)"; STATUS=1; }

if [ "$WSL" -eq 1 ]; then
    echo "== WSL Ubuntu-24.04: scripts/ci-local.sh linux android"
    WSLSCRIPT="set -eu
SRC=\$(wslpath -u '$(q "$REPO")'); WTL=\$(wslpath -u '$(q "$WT")')
D=\"\$HOME/FactorIA-preflight\"
[ -d \"\$D/.git\" ] || git init -q \"\$D\"
git -C \"\$D\" -c safe.directory='*' fetch -q --force \"\$SRC\" 'refs/heads/$REF:refs/preflight/current'
git -C \"\$D\" checkout -q --force --detach refs/preflight/current
git -C \"\$D\" clean -fdq
cd \"\$D\"
rc=0; ./scripts/ci-local.sh linux android || rc=\$?
mkdir -p \"\$WTL/build\"; rm -rf \"\$WTL/build/wsl-ci-logs\"; cp -r build/ci-logs \"\$WTL/build/wsl-ci-logs\" || true
exit \$rc"
    if [ "$FLAVOR" = posix ]; then WSLCMD="sh -s"; else WSLCMD="wsl -d Ubuntu-24.04 --exec bash -l -s"; fi
    printf '%s\n' "$WSLSCRIPT" | "$SSH_BIN" -o BatchMode=yes "$HOST" "$WSLCMD"; RC=$?
    [ "$RC" -eq 0 ] && echo "== WSL: PASSED" || { echo "== WSL: FAILED (exit $RC)"; STATUS=1; }
fi

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

if [ "$STATUS" -eq 0 ]; then
    echo "== PASSED: Windows check of ${SHA:0:10}${DIRTY:+ (WITHOUT the uncommitted changes listed above)}"
else
    echo "== FAILED: Windows check of ${SHA:0:10}; the failing builds and tests are above, full logs in $DEST"
fi
exit "$STATUS"
