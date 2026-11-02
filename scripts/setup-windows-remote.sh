#!/usr/bin/env bash
# One-time setup on the Mac for the remote Windows check (scripts/ci-remote-windows.sh; docs/BUILDING.md, "Checking
# Windows from the Mac"). Safe to run again.
#
#   scripts/setup-windows-remote.sh                          # step 1: key + the line to paste on the PC
#   scripts/setup-windows-remote.sh --host IP --user NAME --repo 'C:\Users\NAME\Documents\GitHub\FactorIA'
#                                                            # step 2: the line the PC printed at the end of its setup
#
# Step 1 creates ~/.ssh/factoria_windows (ed25519, no passphrase: the Mac runs the check unattended) if missing, copies
# to the clipboard (pbcopy) and prints ONE PowerShell line. Paste it in an ADMINISTRATOR PowerShell on the PC: it carries
# scripts/setup-windows-remote.ps1 and the public key, so nothing has to be cloned or downloaded first.
# Step 2 asks before it writes the `Host factoria-windows` block of ~/.ssh/config (between marker comments, so a rerun
# replaces it), tests the connection and stores the clone path in <main checkout>/build/windows-remote.conf.
#   --yes   do not ask before writing ~/.ssh/config
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY="${FACTORIA_WINDOWS_KEY:-$HOME/.ssh/factoria_windows}"
ALIAS="factoria-windows"
SSH_CONFIG="${FACTORIA_SSH_CONFIG:-$HOME/.ssh/config}"
BEGIN_MARK="# >>> factoria-windows (scripts/setup-windows-remote.sh) >>>"
END_MARK="# <<< factoria-windows <<<"
COMMON="$(git -C "$ROOT" rev-parse --path-format=absolute --git-common-dir)"
CONF="$(dirname "$COMMON")/build/windows-remote.conf"
SSH_BIN="${FACTORIA_SSH:-ssh}"

HOST="" USER_NAME="" REPO="" YES=0
while [ $# -gt 0 ]; do
    case "$1" in
        --host) HOST="$2"; shift 2 ;;
        --user) USER_NAME="$2"; shift 2 ;;
        --repo) REPO="$2"; shift 2 ;;
        --yes) YES=1; shift ;;
        -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
        *) echo "error: unknown argument '$1' (see --help)" >&2; exit 2 ;;
    esac
done

mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
if [ ! -f "$KEY" ]; then
    ssh-keygen -q -t ed25519 -N "" -C "factoria-windows@$(hostname -s)" -f "$KEY"
    echo "created $KEY"
fi
PUB="$(cat "$KEY.pub")"

if [ -z "$HOST" ]; then
    # Step 1. The script travels inside the line (base64 in a temp file), so the PC needs nothing but an admin PowerShell.
    B64="$(base64 < "$ROOT/scripts/setup-windows-remote.ps1" | tr -d '\n')"
    LINE="\$f=Join-Path \$env:TEMP 'factoria-setup-ssh.ps1'; [IO.File]::WriteAllBytes(\$f,[Convert]::FromBase64String('$B64')); powershell -NoProfile -ExecutionPolicy Bypass -File \$f -PublicKey '$PUB'"
    if command -v pbcopy >/dev/null 2>&1; then printf '%s' "$LINE" | pbcopy; COPIED=" (already in the clipboard)"; else COPIED=""; fi
    cat <<MSG

STEP 1 - on the Windows PC
  Open PowerShell as administrator (Start menu > PowerShell > right click > Run as administrator) and paste this
  single line$COPIED, then press Enter. It installs and starts the SSH server, opens port 22 on private networks only,
  authorizes this Mac's key and finishes by printing the command for step 2.

$LINE

  If the clone is not at %USERPROFILE%\\Documents\\GitHub\\FactorIA, add  -RepoPath 'C:\\your\\clone'  at the end.
  Once this branch is merged, the PC can also run its clone's copy:
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts\\setup-windows-remote.ps1 -PublicKey '$PUB'

STEP 2 - back on this Mac
  Run the command the PC printed (scripts/setup-windows-remote.sh --host <ip> --user <name> --repo '<clone>').
MSG
    exit 0
fi

[ -n "$USER_NAME" ] || { echo "error: --user is required with --host (the PC printed it)" >&2; exit 2; }
[ -n "$REPO" ] || REPO="C:\\Users\\$USER_NAME\\Documents\\GitHub\\FactorIA"

BLOCK="$BEGIN_MARK
Host $ALIAS
    HostName $HOST
    User $USER_NAME
    IdentityFile $KEY
    IdentitiesOnly yes
    ServerAliveInterval 30
    ServerAliveCountMax 20
    ConnectTimeout 8
    StrictHostKeyChecking accept-new
$END_MARK"

echo "This will put the following in $SSH_CONFIG (replacing a previous factoria-windows block):"
echo "$BLOCK"
if [ "$YES" -ne 1 ]; then
    printf 'Write it? [y/N] '
    read -r ANSWER
    case "$ANSWER" in y|Y|yes|YES) ;; *) echo "not written; nothing changed."; exit 1 ;; esac
fi
touch "$SSH_CONFIG" && chmod 600 "$SSH_CONFIG"
TMP="$(mktemp)"
# Drop the old block (markers included), then append the new one.
awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
    $0 == b { skip = 1; next }
    skip && $0 == e { skip = 0; next }
    !skip { if ($0 == "") { blank++ } else { while (blank > 0) { print ""; blank-- } print } }' "$SSH_CONFIG" > "$TMP"
{ cat "$TMP"; [ -s "$TMP" ] && echo; echo "$BLOCK"; } > "$SSH_CONFIG"
rm -f "$TMP"
echo "wrote $SSH_CONFIG"

mkdir -p "$(dirname "$CONF")"
printf 'FACTORIA_WINDOWS_REPO=%s\n' "$(printf '%s' "$REPO" | tr '\\' '/')" > "$CONF"
echo "stored the PC's clone path in $CONF"

echo "Testing the connection..."
REPO_FWD="$(printf '%s' "$REPO" | tr '\\' '/')"
TESTCMD="git --version; git -C '$REPO_FWD' rev-parse --is-inside-work-tree"
if OUT="$($SSH_BIN -o BatchMode=yes "$ALIAS" "$TESTCMD" 2>&1)"; then
    echo "$OUT"
    echo "OK. Run scripts/ci-remote-windows.sh before a push."
else
    echo "$OUT" >&2
    cat >&2 <<MSG
error: could not run a command on the PC. Check, in this order:
  - the PC is on and on the same network (ping $HOST), and its network is "Private" (the firewall rule is private-only);
  - step 1 finished without warnings on the PC (re-running it is safe);
  - the clone exists at $REPO and git is installed there.
MSG
    exit 1
fi
