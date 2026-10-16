# Menus fixture

The menu kit of `docs/MENUS.md` (AI guide section 9.24) as a project: main menu, loading screen, pause menu, options
(video, audio per bus, controls, language slot), credits and a shop. `tests/recipe.test.js` (the M10 acceptance test) and
`tests/menus.test.js` drive them with gamepad presses only. ctest runs `factoria validate` and `factoria test` on it
(`fixture_menus_*`), and a `cli` test checks that every file the doc gives is the file here: change both together.

The shop and the level's store hooks are the M12 acceptance test of the `platform` API (`docs/PLATFORM.md`): the
catalog is `factoria.json` `"platform"`, `scripts/ui/shop.js` sells gems and "Remove ads", `scripts/store_events.js`
pauses the game while the store overlay is open, and `tests/platform.test.js` drives all of it against the fake store.
