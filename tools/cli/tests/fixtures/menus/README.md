# Menus fixture

The menu kit of `docs/MENUS.md` (AI guide section 9.23) as a project: main menu, loading screen, pause menu, options
(video, audio per bus, controls, language slot) and credits. `tests/recipe.test.js` (the M10 acceptance test) and
`tests/menus.test.js` drive them with gamepad presses only. ctest runs `factoria validate` and `factoria test` on it
(`fixture_menus_*`), and a `cli` test checks that every file the doc gives is the file here: change both together.
