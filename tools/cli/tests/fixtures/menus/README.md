# Menus fixture

The menu recipe of the AI guide (`docs/AI_GUIDE.md`, section 9.23) as a project: main menu, loading screen, pause menu,
options (video, audio per bus, controls, language slot) and credits. `tests/menus.test.js` drives them with gamepad
presses only. ctest runs `factoria validate` and `factoria test` on it (`fixture_menus_*`), and the `cli` tests check
that every recipe file in the guide is the same as the file here: change both together.
