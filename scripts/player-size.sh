#!/usr/bin/env bash
#
# Player size budgets (docs/design/BUILDING_RELEASE.md, "Player size budgets"): measures factoria_player, compares it with
# tools/size/player_size_budget.json and writes player-size-<platform>.json and .md (and $GITHUB_STEP_SUMMARY).
#
#   scripts/player-size.sh measure --platform <key> [--build-dir <dir>] [--out-dir <dir>]
#   scripts/player-size.sh update player-size-<key>.json ...     take a measurement as the new baseline (+10 % budget)
#   scripts/player-size.sh validate | self-test                  see `scripts/player-size.sh --help`
#
# The work is in player-size.py (standard library only: JSON, the link maps of four linkers and the strip tools are not
# bash's business); this wrapper only finds a Python 3 on Linux, macOS and Windows (Git Bash), where it is `python`.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for py in python3 python py; do
    if command -v "$py" >/dev/null 2>&1 && "$py" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)' >/dev/null 2>&1; then
        exec "$py" -I "$here/player-size.py" "$@"
    fi
done
echo "error: scripts/player-size.sh needs Python 3.8 or newer (python3, python or py in PATH)." >&2
exit 2
