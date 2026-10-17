# Menus fixture

The menu kit of `docs/MENUS.md` (AI guide section 9.24) as a project: main menu, loading screen, pause menu, options
(video, audio per bus, controls, language), credits and a shop. `tests/recipe.test.js` (the M10 acceptance test) and
`tests/menus.test.js` drive them with gamepad presses only. ctest runs `factoria validate` and `factoria test` on it
(`fixture_menus_*`), and a `cli` test checks that every file the doc gives is the file here: change both together.

The texts are localized (`docs/LOCALIZATION.md`): `factoria.json` `"localization"` lists English and Spanish,
`locales/en.json` and `locales/es.json` hold the strings, widgets and Texts carry a `key`, the scripts use `i18n.t()` for
the texts they write, and the Language tab of the options cycles through the languages and saves the choice.
`tests/i18n.test.js` is the M14 acceptance test: it switches the language at run time and checks every keyed Text and
widget (and that one without a key stays as it is).

The shop and the level's store hooks are the M12 acceptance test of the `platform` API (`docs/PLATFORM.md`): the
catalog is `factoria.json` `"platform"`, `scripts/ui/shop.js` sells gems and "Remove ads", `scripts/store_events.js`
pauses the game while the store overlay is open, and `tests/platform.test.js` drives all of it against the fake store.
