#!/usr/bin/env bash
# Deletes the older caches of ONE ccache on the ref this CI run builds, right after the run saved its own.
#
#   scripts/ci-prune-caches.sh <key prefix>        e.g. ccache-Linux-gcc-   (the key is <prefix><run id>)
#
# Needs the `gh` CLI, GH_TOKEN and GH_REPO in the environment and `actions: write` on the token. ci.yml runs it after each
# "Save ccache" step (also in a failed or cancelled round: those rounds save too, and a newer round of the same pull request
# would otherwise leave every one of them in the repository's 10 GB until GitHub's least-recently-used eviction picks
# main's caches first). Safe by construction:
#   - only caches of GITHUB_REF (this pull request or branch) are listed, never another ref's;
#   - only keys that are exactly <prefix><digits>: ccache-Linux-linux- does not touch ccache-Linux-linux-asan-<id>;
#   - nothing is deleted unless the cache this run saved (<prefix>$GITHUB_RUN_ID) is in the list, so a save that failed
#     keeps the older cache, and the run's own cache is never deleted.
# Any failure prints a warning and exits 0: pruning is housekeeping and must not turn a job red.
set -uo pipefail

prefix="${1:?usage: ci-prune-caches.sh <key prefix, e.g. ccache-Linux-gcc->}"
: "${GITHUB_REF:?GITHUB_REF is not set: this script runs inside GitHub Actions}"
: "${GITHUB_RUN_ID:?GITHUB_RUN_ID is not set}"
current="${prefix}${GITHUB_RUN_ID}"
base="${prefix%-}"

warn() { echo "::warning::ci-prune-caches: $*"; }

if ! keys=$(gh cache list --ref "$GITHUB_REF" --key "$prefix" --limit 100 --json id,key --jq '.[] | "\(.id) \(.key)"' 2>&1); then
    warn "could not list the caches of $GITHUB_REF (a pull request from a fork has a read-only token): $keys"
    exit 0
fi

keys="${keys//$'\r'/}"  # gh.exe on Windows may end lines with CRLF
if ! grep -qxE "[0-9]+ ${current}" <<< "$keys"; then
    echo "The cache $current is not in the list (the save failed, was skipped, or is not visible yet): nothing deleted."
    exit 0
fi

deleted=0
while read -r id key; do
    [[ -n "$id" && "$key" != "$current" ]] || continue
    if [[ "$key" =~ ^${base}-[0-9]+$ ]]; then
        if gh cache delete "$id" > /dev/null 2>&1; then
            echo "Deleted the older cache $key ($id)."
            deleted=$((deleted + 1))
        else
            warn "could not delete the cache $key ($id)"
        fi
    fi
done <<< "$keys"
echo "Kept $current; deleted $deleted older cache(s) of $GITHUB_REF."
exit 0
