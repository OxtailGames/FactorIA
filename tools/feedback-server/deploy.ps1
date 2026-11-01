# Deploy the FactorIA feedback server to Cloudflare (Worker + D1). One command; safe to run again.
# Needs Node.js 20 or newer (https://nodejs.org) and a free Cloudflare account. See README.md.
#   powershell -NoProfile -ExecutionPolicy Bypass -File deploy.ps1 [--rotate-admin]
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

$node = Get-Command node -ErrorAction SilentlyContinue
$npm = Get-Command npm -ErrorAction SilentlyContinue
if (-not $node -or -not $npm) {
    Write-Error 'Node.js (with npm) is required: install it from https://nodejs.org (or: winget install OpenJS.NodeJS.LTS), then run this again.'
    exit 1
}
$major = [int](& node -p 'process.versions.node.split(".")[0]')
if ($major -lt 20) {
    Write-Error "Node.js 20 or newer is required (found $(& node -v)). Update it from https://nodejs.org and run this again."
    exit 1
}

# Exactly the versions of package-lock.json.
& npm ci --no-audit --no-fund
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& node scripts/deploy.mjs @args
exit $LASTEXITCODE
