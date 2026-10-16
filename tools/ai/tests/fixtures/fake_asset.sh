#!/bin/sh
# Fake asset program for the asset-command provider tests (fake_asset.cmd is the same for Windows): copies the file named by
# $FAKE_ASSET_SOURCE to the path in its first argument, and records every argument, one per line, in $FAKE_ARGV_FILE.
# FAKE_MODE=fail exits with code 3 and a message; FAKE_MODE=nothing exits 0 without writing a file.
if [ -n "$FAKE_ARGV_FILE" ]; then
  for a in "$@"; do printf '%s
' "$a" >> "$FAKE_ARGV_FILE"; done
fi
case "$FAKE_MODE" in
  fail) echo "the model is not loaded" >&2; exit 3 ;;
  nothing) exit 0 ;;
esac
cp "$FAKE_ASSET_SOURCE" "$1"
