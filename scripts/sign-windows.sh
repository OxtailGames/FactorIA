#!/usr/bin/env bash
#
# Authenticode-signs the given files with signtool (timestamped). Used by .github/workflows/release.yml (Git Bash on
# the windows-2022 runner); setup in docs/BUILDING.md, "Releasing".
#
#   scripts/sign-windows.sh factoria.exe FactorIA-Editor.exe ...
#
# The certificate comes from the environment (repository secrets in CI):
#   WINDOWS_CERT_PFX_BASE64   the .pfx file, base64 encoded (`base64 -w0 cert.pfx`)
#   WINDOWS_CERT_PASSWORD     its password
# Without WINDOWS_CERT_PFX_BASE64 it only prints a notice and succeeds, so a release builds (unsigned) before the
# certificate exists.
set -euo pipefail

if [[ -z "${WINDOWS_CERT_PFX_BASE64:-}" ]]; then
    echo "::notice title=Windows code signing skipped::WINDOWS_CERT_PFX_BASE64 is not set, so $* stay unsigned (docs/BUILDING.md, Releasing)"
    exit 0
fi
if [[ -z "${WINDOWS_CERT_PASSWORD:-}" ]]; then
    echo "::error::WINDOWS_CERT_PFX_BASE64 is set but WINDOWS_CERT_PASSWORD is not"
    exit 1
fi

# signtool takes /f, /p ...: stop Git Bash from rewriting them as paths.
export MSYS2_ARG_CONV_EXCL='*'

# The newest Windows SDK that ships signtool (the runner image has several).
signtool="$(ls -d "/c/Program Files (x86)/Windows Kits/10/bin/"*/x64/signtool.exe 2>/dev/null | sort -V | tail -n 1)"
if [[ -z "$signtool" ]]; then
    echo "::error::signtool.exe not found: install the Windows 10/11 SDK"
    exit 1
fi

pfx="$(mktemp --suffix=.pfx)"
trap 'rm -f "$pfx"' EXIT
printf '%s' "$WINDOWS_CERT_PFX_BASE64" | base64 -d > "$pfx"

for file in "$@"; do
    win="$(cygpath -w "$file")"
    # A timestamp server that is down for a minute should not fail a release: try three times.
    for attempt in 1 2 3; do
        if "$signtool" sign /f "$(cygpath -w "$pfx")" /p "$WINDOWS_CERT_PASSWORD" /fd sha256 \
            /tr http://timestamp.digicert.com /td sha256 /d FactorIA "$win"; then
            break
        fi
        if [[ "$attempt" == 3 ]]; then echo "::error::signing $file failed"; exit 1; fi
        sleep 10
    done
    "$signtool" verify /pa "$win"
done
