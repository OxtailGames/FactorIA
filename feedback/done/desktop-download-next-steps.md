# Desktop download: next steps (*proactive*) — DONE in M8

`.github/workflows/release.yml` packages the desktop tools as a zip / tar.gz that runs without dev tools
(docs/GETTING_STARTED.md, "Download"). Left out of that first package, all done in M8:
- ~~A Windows installer that adds a Start menu entry and puts `factoria` on PATH, so `.mcp.json` (bare `factoria`
  command) works from any terminal without editing PATH by hand.~~ (`fb53f30`)
- ~~Code signing on Windows and signing plus notarization on macOS, so SmartScreen and Gatekeeper stop warning.~~ Wired
  up (`fb53f30`); it signs once the certificates exist (M8, "Left open").
- ~~Prebuilt Android and iOS player libraries in the package, so `factoria export --platform android|ios` works from the
  download (today it needs the engine source and the SDKs, docs/MOBILE.md).~~ (`f63632a`, `5055f85`)
- ~~A Linux AppImage (one file, no tar.gz) and a macOS x86_64 or universal build (the package is Apple Silicon only).~~
  (`fb53f30`)
