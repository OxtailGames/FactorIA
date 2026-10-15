#!/usr/bin/env bash
#
# Signs the given executables with a Developer ID Application certificate (hardened runtime, timestamped) and has Apple
# notarize them. Used by .github/workflows/release.yml (macOS runner); setup in docs/BUILDING.md, "Releasing".
#
#   scripts/sign-macos.sh build/macos-release/tools/cli/factoria build/macos-release/player/factoria_player
#
# The credentials come from the environment (repository secrets in CI):
#   APPLE_CERT_P12_BASE64   the "Developer ID Application" certificate with its private key, as .p12, base64 encoded
#   APPLE_CERT_PASSWORD     the password the .p12 was exported with
#   APPLE_ID, APPLE_TEAM_ID, APPLE_APP_PASSWORD   Apple ID, its 10-character Team ID and an app-specific password
#                                                 (appleid.apple.com), for `xcrun notarytool`
# Without APPLE_CERT_P12_BASE64 it only prints a notice and succeeds, so a release builds (unsigned) before the
# certificate exists. With the certificate but without the Apple ID secrets it signs but does not notarize.
#
# Bare executables cannot be stapled (only .app, .pkg and .dmg can take a ticket), so Gatekeeper checks the
# notarization online the first time a downloaded executable runs. Signing happens BEFORE the package is made: sign the
# files that go into the tar.gz, not the archive.
set -euo pipefail

if [[ -z "${APPLE_CERT_P12_BASE64:-}" ]]; then
    echo "::notice title=macOS signing skipped::APPLE_CERT_P12_BASE64 is not set, so $* stay unsigned and not notarized (docs/BUILDING.md, Releasing)"
    exit 0
fi
if [[ -z "${APPLE_CERT_PASSWORD:-}" ]]; then
    echo "::error::APPLE_CERT_P12_BASE64 is set but APPLE_CERT_PASSWORD is not"
    exit 1
fi

work="$(mktemp -d)"
keychain="$work/fa-signing.keychain-db"
cleanup() {
    security delete-keychain "$keychain" 2>/dev/null || true
    rm -rf "$work"
}
trap cleanup EXIT

# A throwaway keychain holds the certificate for this job only.
keychain_password="$(uuidgen)"
security create-keychain -p "$keychain_password" "$keychain"
security set-keychain-settings -lut 21600 "$keychain"
security unlock-keychain -p "$keychain_password" "$keychain"
printf '%s' "$APPLE_CERT_P12_BASE64" | base64 --decode > "$work/cert.p12"
security import "$work/cert.p12" -k "$keychain" -P "$APPLE_CERT_PASSWORD" -T /usr/bin/codesign
# Lets codesign use the key without a GUI prompt.
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$keychain_password" "$keychain" > /dev/null
# codesign finds the certificate through the keychain search list.
# shellcheck disable=SC2046
security list-keychains -d user -s "$keychain" $(security list-keychains -d user | tr -d '"')

identity="$(security find-identity -v -p codesigning "$keychain" | sed -n 's/.*"\(Developer ID Application:.*\)".*/\1/p' | head -n 1)"
if [[ -z "$identity" ]]; then
    echo "::error::no 'Developer ID Application' identity in APPLE_CERT_P12_BASE64 (a 'Mac Development' or 'Apple Distribution' certificate cannot sign downloads)"
    exit 1
fi

for file in "$@"; do
    codesign --force --options runtime --timestamp --sign "$identity" --keychain "$keychain" "$file"
    codesign --verify --strict --verbose=2 "$file"
done

if [[ -z "${APPLE_ID:-}" || -z "${APPLE_TEAM_ID:-}" || -z "${APPLE_APP_PASSWORD:-}" ]]; then
    echo "::notice title=macOS notarization skipped::APPLE_ID, APPLE_TEAM_ID and APPLE_APP_PASSWORD are not all set: the executables are signed but not notarized, so Gatekeeper still warns"
    exit 0
fi

# notarytool takes a zip, pkg or dmg, not a bare executable: the zip is only the way to hand the files over.
zip -j -q "$work/notarize.zip" "$@"
result="$(xcrun notarytool submit "$work/notarize.zip" --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_PASSWORD" --wait --timeout 40m --output-format json)" || true
echo "$result"
if ! grep -Eq '"status" *: *"Accepted"' <<< "$result"; then
    # The log says why Apple refused (unsigned library, missing hardened runtime, ...).
    id="$(sed -n 's/.*"id" *: *"\([^"]*\)".*/\1/p' <<< "$result" | head -n 1)"
    [[ -n "$id" ]] && xcrun notarytool log "$id" --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_PASSWORD" || true
    echo "::error::Apple did not accept the notarization (log above)"
    exit 1
fi
echo "Notarized: $*"
