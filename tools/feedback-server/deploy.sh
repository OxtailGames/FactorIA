#!/usr/bin/env bash
# Deploy the FactorIA feedback server to Cloudflare (Worker + D1). One command; safe to run again.
# Needs Node.js 20 or newer (https://nodejs.org) and a free Cloudflare account. See README.md.
#   ./deploy.sh [--rotate-admin]
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    echo "Node.js (with npm) is required: install it from https://nodejs.org (or: brew install node), then run this again." >&2
    exit 1
fi
major="$(node -p 'process.versions.node.split(".")[0]')"
if [ "$major" -lt 20 ]; then
    echo "Node.js 20 or newer is required (found $(node -v)). Update it from https://nodejs.org and run this again." >&2
    exit 1
fi

# Exactly the versions of package-lock.json.
npm ci --no-audit --no-fund
exec node scripts/deploy.mjs "$@"
