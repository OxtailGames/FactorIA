# Gem Grab fixture

The finished game of the tutorial `docs/MAKE_BY_HAND.md` ("Make a small game by hand"), as a project: a square you move
with WASD, four gems to collect, a score on screen, a win screen and a test. ctest runs `factoria validate` and
`factoria test` on it (`fixture_gem_grab_*` in `tools/cli/CMakeLists.txt`), and a `cli` test checks that every file the
tutorial gives is the file here: change both together.

The tutorial writes the scene files in a short layout; here they are in the canonical one (`factoria call scene.format`).
