# Finish your game: from playable to ready for a store

A prototype that plays is not a game a store accepts. Players expect a menu, options that stay set, saves that survive an
update, their own language, text they can read, and no surprises on a bad day. This is the path from one to the other, in
the order that costs least. Each section is a short recipe with real code from **Lantern Keep**
(`examples/lantern-keep` in the FactorIA repository), a complete 2D platformer built exactly this way, and a link to the
reference doc instead of a copy of it. Paths in the snippets are relative to the game's folder. For a 3D game made for
phones, **Clockwork Courier** (`examples/clockwork-courier`) is the second model: on-screen controls, haptics, pause on
suspend, Android Back, a Japanese font cut to the game's characters (`assets/fonts/make_subset.py`) and every screen
checked at 200 % text. For a desktop game for several players at one screen, **Burrow Brigade**
(`examples/burrow-brigade`) is the third: a join screen, per-player rebinding, save slots whose format changed once
(with the migration and fixtures of both versions), a game speed and hold-or-toggle for assist, a Thai fallback font
(its `tools/thai_spaces.py` puts real spaces between Thai words; a line also breaks after U+200B, which takes no width, so
a translation can mark word boundaries with that instead), and `SHIPPING.md` for
Steam and the desktop exports.

Do the sections in order: the menu comes first because options, saves and languages all live behind it; tests come last
but each section ends with the test that keeps it true. Export and the store steps are after the checklist at the end.

Everything named here exists in the engine today. Where a recipe needs something the engine does not have, the section
says so under "Not in the engine".

## 1. Main menu, pause and the menu kit

Read [MENUS.md](MENUS.md) (`factoria docs read menus`) and add its kit with `project.add_menu_kit` (`factoria call
project.add_menu_kit`; it copies the files as they are and merges their texts into your locales): main menu, options,
credits, loading screen and pause menu, driven by FactorIA's own tests with a gamepad only. The steps there are the whole recipe;
the parts a finished game must not skip:

- `factoria.json` starts on the menu and has a `pause` action: `"mainScene": "scenes/menu.scene.json"`, and in
  `input.actions` `"pause": ["Escape", "P", "GamepadStart"]`.
- **One `pause_menu` entity in every level scene.** It sets `game.paused = true` (physics, animations and other
  scripts stop; the menu script keeps running because of `runWhilePaused = true`) and `game.paused = false` to resume.
  Pausing remembers `time.scale` and resuming restores it, so a slowed game stays slowed.

```js
// scripts/pause_menu.js
if (input.pressed("pause") && !MenuStack.busy) game.paused ? this.back() : this.pause();
```

- Every screen works with the keyboard, the mouse and the gamepad alone. Focus comes only from `autoFocus` or
  `ui.focus`, so a HUD button is never clicked by Space. Set `autoFocus` on the first button of every panel.
- Give `Button`, `Toggle` and `Slider` `"autoSize": true` from the start: they grow to their label in any language and
  text size (sections 4 and 5 depend on it).
- A level can end: add a panel with Next, Retry and Menu (`scripts/ui/level_end.js`, `prefabs/ui/level_end.prefab.json`).

Keep it alive with a test that taps through the menus with `game.gamepad(0)` (`tests/menus.test.js`, section 8).

## 2. Options that persist

The menu kit's `scripts/settings.js` keeps one object under the `settings` key of `storage` and `apply()`s it once per run
(`applyOnce()` from the main menu and the pause menu). `scripts/ui/options.js` edits it. Lantern Keep's list is the
one to match:

```js
// scripts/settings.js
const DEFAULTS = {
  volume: { master: 1, music: 0.6, sfx: 1, ui: 1 },
  fullscreen: null, resolution: null, vsync: null, frameCap: 0,
  bindings: {},          // action -> binding names, only for actions the player rebound
  language: null,        // null: the language the game started in
  textScale: 1,          // ui.textScale, 1 to 2 in steps
  uiScale: null,         // ui.scale (the interface size); null: the factoria.json "ui": {"scale"}
  assist: { speed: 1, invincible: false },
  shake: true, reducedEffects: false,
};
```

What `apply()` does for each (all of it is in the kit; keep it when you change the list):

| Option | Call |
|---|---|
| Volumes | `audio.setVolume(bus, value)` for `master`, `music`, `sfx`, `ui` |
| Text size | `ui.textScale = math.clamp(s.textScale, 0.5, 3)` (the engine never saves it: you do) |
| Interface size | `ui.scale = math.clamp(s.uiScale, 0.5, 3)` when `s.uiScale` is not null (the engine never saves it either) |
| Language | `i18n.setLanguage(tag)` (rewrites every Text and widget with a `key` at once) |
| Controls | `input.rebind(action, bindingNames)` for each saved action |
| Video | `window.setFullscreen`, `window.setSize`, `window.setVsync`, `window.frameCap`, only when `window.available` (not in headless runs and tests) |

Rules that keep options honest:

- A saved value the game cannot apply any more (a language you removed, a binding name that no longer exists) is
  `console.warn`ed and skipped inside `try/catch`, never thrown: a player must not be locked out by an old file.
- **Rebinding.** List only the actions a player may change in `Options.actions`, label them with the strings
  `options.action.<action>`, and replace only the bindings of the device that was pressed, so rebinding the keyboard keeps
  the pad:

```js
// scripts/ui/options.js
const pad = (b) => b.startsWith("Gamepad");
const keep = input.bindings(action).filter((b) => pad(b) !== pad(pressed));
const list = [pressed, ...keep];
input.rebind(action, list);
this.s.bindings[action] = list;
settings.save(this.s);
```

  `input.lastPressed()` gives the key or button the player pressed. Escape cancels the rebinding.
- Add a "reset to defaults" for controls (`this.s.bindings = {}`) so a bad rebinding can always be undone.
- Settings are not part of a save slot: they belong to the player, not to a game in progress.

Test: every option is saved, applied after a restart, and effective (`tests/accessibility.test.js`, "saved options are
applied when the game starts again and the tab shows them").

## 3. Saves

The engine part: `storage` (JSON values in `<save folder>/storage.json`) saves through a temporary file and a rename, so a
crash during a save leaves the previous file intact. A `storage.json` that does not parse is **kept** as
`storage.corrupt.json` (then `storage.corrupt.2.json`...) with a warning, `storage.corrupt` is `true` and the game starts
with empty data; the kept file is never overwritten ([SCRIPTING.md](SCRIPTING.md), "storage"). That protects the file as
a whole. Everything below is the game's part, and Lantern Keep's recipe for it is `scripts/saves.js`:

**A version field, one migration step per old version.** A slot is a string of JSON text under `slot1`, `slot2`, `slot3`
(plus `lastSlot`, a number). Keep the layout in one table, bump `VERSION` when you change it, and write one
`migrateN` per old version that turns version N into N+1. `parse` reads any version and always returns the newest:

```js
// scripts/saves.js
export const VERSION = 2;
const version = raw.version === undefined ? 1 : raw.version;           // a file from before `version` existed is 1
if (version > VERSION) return { ok: false, reason: `version ${version} is newer than this game's (${VERSION})` };
const data = version === 1 ? migrate1(raw) : raw;
```

```js
/** Version 1 -> 2. Version 1 knew finished levels and best times, not embers (they start unfound). */
export function migrate1(old) { /* { cleared: [...], best: {...} } -> { counter: 0, levels: {...} } */ }
```

The next save writes the newest version. When you add version 3, add `migrate2`, run the chain
(1 -> 2 -> 3), and keep a **fixture of every old layout** in `tests/fixtures/` (Lantern Keep: `save_v1.json`). Ship the
migration with the update that changes the layout, never later: players update.

**Three slots, one unit of damage.** Every slot is checked on its own with `parse(text)`, which returns
`{ ok: true, data }` or `{ ok: false, reason }` and never throws. Text that is not JSON, not an object, from a newer game
(a player who went back a version) or not shaped like a save is **damaged**; unknown level ids are dropped. This is
separate from `storage.corrupt` on purpose: a slot can be valid JSON of the wrong shape, and a cloud copy can be anything.

**A damaged-save screen.** The slot screen asks `peek(n)`, which says `empty`, `used` or `damaged`:

```js
// scripts/saves.js
export function peek(n) {
  const text = storage.get(key(n), null);
  if (text === null) return { status: "empty" };
  const r = parse(text);
  if (!r.ok) return { status: "damaged", reason: r.reason };
  /* ... { status: "used", data, summary } */
}
```

`scripts/ui/slots.js` shows "New game", a summary (levels, embers, time) or "Damaged"; a damaged slot cannot be chosen and
has a Delete button that asks first (`scripts/ui/delete_confirm.js`, the focus starts on "Keep it"). Nothing in the game
throws on bad data. Lantern Keep shows no message for a whole-file `storage.corrupt`; a finished game should add one line
on the slot screen when `storage.corrupt` is `true` ("Your save file was damaged; a copy was kept") and, if it has the
folder, tell the player where `storage.corrupt.json` is.

**Writing.** Save after every meaningful event, not on exit (a phone kills a game without warning):
`progress.record()` calls `saves.save()` after each finished level. Never read the wall clock: a `counter` that goes up by
one on every save orders copies (determinism, and cloud sync below).

**Cloud copy.** With `platform.has("cloudSave")` each save is also uploaded under the same key, and when the slot
screen opens `syncCloud()` compares each slot with its cloud copy: the higher `counter` wins, a better local copy is
uploaded, a failed call changes nothing. The local save is written first and never waits for the store
(`platform.cloud.save/load/remove/list`, [PLATFORM.md](PLATFORM.md)). Deleting a slot deletes its cloud copy; a failed
delete can bring it back at the next sync (a known limit).

**Where the file is.**

| Platform | Save folder |
|---|---|
| Windows | `%APPDATA%\<game id>` |
| Linux | `~/.local/share/<game id>` |
| macOS | `~/Library/Application Support/<game id>` |
| Android | the app's private folder (`internalDataPath`) |
| iOS | the app's `Documents/` |
| Web | the browser's **IndexedDB**, one database per game id: loaded before the game starts, copied back half a second after a write (a closing tab flushes it). It belongs to the site: it survives reloads, is lost when the player clears the site's data, and a private window keeps it only until it closes |

([EXPORTING.md](EXPORTING.md), [MOBILE.md](MOBILE.md).) Consequences for the game: do not tell a web player a save is
permanent (offer cloud saves where a store exists), keep the save small (it is one JSON file on every platform), and do not
write files of your own outside `storage` unless you handle the same cases.

Tests (`tests/saves.test.js`): a v1 fixture migrates; slots with broken text, a newer version and a wrong shape say
"Damaged", cannot be chosen and can be deleted; `game.setStorageText('{"slot1": "{\\"version\\": 2, ')` makes
`storage.corrupt` `true`, the slots start empty and saving still works (call `game.setStorageText(null)` after);
cloud copies win by counter and survive failures (`game.platform.respond("cloud.save", { error: "network" })`).

## 4. Localization and right-to-left

[LOCALIZATION.md](LOCALIZATION.md) is the reference; the recipe is:

1. `factoria.json`: `"localization": { "defaultLanguage": "en", "languages": ["en", "es", "de", "ar"] }`.
2. A `locales/<tag>.json` per language with the same keys, and a `key` on every Text and widget that scenes and
   prefabs write. Text that scripts build uses `i18n.t("hud.embers", { found: 3, total: 18 })`, and is written again in
   `i18n.on("change", ...)`.
3. Make the other tables with the translators' tools, not by hand: `i18n.export {"format":"csv"}` (or `"xliff"`), fill
   the column, then `i18n.import` (try it with `dryRun` first), then `factoria validate`, which also checks that the fonts
   have every glyph.
4. **Right-to-left.** Arabic and Hebrew are ordered and joined by the engine. The layout is yours: `"direction": "auto"` on
   row panels and `"align": "start"` on wrapped Texts, and pick HUD corners from `i18n.direction`:

```js
// scripts/hud.js (anchors and pivots are not mirrored by the engine)
const rtl = i18n.direction === "rtl";
text.anchor = [right ? 1 : 0, 0];   // `right` is rtl for the level name and !rtl for the embers
```

5. **Check every screen at 100 % and 200 % text in every language.** German is the stress test (long words), Arabic the
   direction test. Lantern Keep does it with a test that opens each screen, sets `ui.textScale`, and asks the same
   questions of all of them with `ui.state` (every visible widget rectangle) and `ui.measureText`:

```js
// tests/helpers/screens.js
const problems = screenProblems("main menu");  // widgets inside the screen, labels inside their widget,
expect(problems).toEqual([]);                   // no text wider than its box, panels big enough for content
```

   Also look: `FA_LANGUAGE=ar factoria run --headless --frames 3 --screenshot-at 2`, then open the PNG
   (`examples/lantern-keep/screenshots/` has the Arabic menu and German at 200 % as models).
6. Plurals: a language can have up to six forms (Arabic does); a text with a count needs every form the language has, and
   the `i18n.import` check says which are missing.
7. Store page texts have their own translations (`nameKey`/`descriptionKey` for the platform catalog, store texts per
   language: [PLATFORM.md](PLATFORM.md), "Translated texts").

## 5. Accessibility

What a player can ask for without a store requiring it, and what Lantern Keep built (its README section "Accessibility"):

| Feature | How |
|---|---|
| **Text size** 100 to 200 % | `ui.textScale` ([TEXT.md](TEXT.md), "Text size"). `autoSize: true` on every widget, `ScrollList.fill` on lists, a wider options panel at big sizes, a `fit` Panel with `fallbackLayout` where a row no longer fits |
| **Assist mode** | game speed 100 to 60 % (`time.scale`, applied when a level starts by `scripts/assist.js`) and invincibility (spikes and enemies do nothing; a fall puts the player back and is not a death). Mark such runs: `level_completed` carries `assisted: true`, and the level end panel says so; keep assisted runs off leaderboards (`scripts/store_stats.js`) |
| **Screen shake off** | every shake goes through one function (`scripts/effects.js` `deathShake()`), gated by an option |
| **Reduced effects** | every particle burst and flash goes through one function (`emberSpark()`), gated by an option |
| **Hazards readable without colour** | shape and outline, not hue: spikes are three sharp triangles with a dark outline, enemies a rounded box with eyes, collectibles a diamond, a checkpoint hollow until reached and solid after. Check a greyscale copy of a screenshot |

```js
// scripts/effects.js
export function deathShake() {
  if (!settings.load().shake) return;
  const camera = world.find("camera")?.behaviour;
  if (camera && typeof camera.shake === "function") camera.shake(0.3, 10);
}
```

Rules: route every effect through a small function so one option can gate it; never use colour as the only signal (add a
shape, an icon or a word); keep every action a single press unless a hold is truly needed; let every menu work with one
input device. Tests check each option is saved, applied and effective, and that a run with assist on is flagged
(`tests/accessibility.test.js`).

The engine also has these; the menu kit ([MENUS.md](MENUS.md)) has an option for each, so copy it from there:

| Feature | How |
|---|---|
| **Colour filter** | `Camera.colorFilter` (`greyscale`, `highContrast`, `protanopia`, `deuteranopia`, `tritanopia`) on the scene's camera, chosen by the player and set again in every scene. To check how a colour-blind player sees the game without changing it: `factoria run --headless --screenshot-at 60 --screenshot-simulate deuteranopia` ([CLI.md](CLI.md)), or `simulate` of `game.screenshot` |
| **Start from the system's settings** | `game.accessibility` (`textScale`, `reduceMotion`, `highContrast`, `screenReader`) gives the first-run values of text size, reduced effects and "read menus aloud"; save the player's own choice, which wins from then on |
| **Read menus aloud** | `ui.speak(text)` with the system's text to speech, speaking the focused widget on each `ui.focus` event; tests read `game.spoken()` ([SCRIPTING.md](SCRIPTING.md)) |
| **Subtitles** | a `Captions` entity, then `audio.play(path, { caption })` for a voice line, or `ui.caption(text)` for a line with no sound; an option turns the entity off. Tests read `game.captions()` ([TEXT.md](TEXT.md), "Captions") |

Not in the engine: handing the game's widgets to the system's screen reader (it does not see them; `ui.speak` talks
instead). A game that needs more builds it itself; record the gap in `ENGINE_FEEDBACK.json`.

## 6. Achievements, stats, leaderboards, cloud saves

All through `platform` ([PLATFORM.md](PLATFORM.md)): declare them in `factoria.json` `"platform"`, call the same API on
every store, and the fake backend runs by default in development and in every headless run. Lantern Keep has 8
achievements, 4 stats, 7 leaderboards and 2 products.

- **Check the service before using it:** `platform.has("achievements")`, `"stats"`, `"leaderboards"`, `"cloudSave"`. An
  exported game without a store plugin has the `none` backend: every call rejects `unavailable`, and the game must not
  care.
- **Best effort, in a queue.** A store that is down, a player who is not signed in or a failed call never stops the game.
  Lantern Keep sends everything from one script fed by the game's events, one request after the other:

```js
// scripts/store_stats.js
unlock(id) {
  if (platform.has("achievements")) this.run(() => platform.achievements.unlock(id));
}
run(fn) { this.chain = this.chain.then(() => fn()).catch(() => {}); return this.chain; }   // best effort
```

  Counts go through `platform.stats.add("jumps", n)` and `platform.achievements.progress(id, fraction)`; times through
  `platform.leaderboards.submit(id, ms)` (whole numbers only; remember what you already sent in `storage` so you submit
  only a better time).
- **Show them in the game too** (a screen for achievements and for the leaderboard), reading
  `platform.achievements.list()` and `platform.leaderboards.entries(id, { range: "top", count: 10 })`; the texts are
  translated through `nameKey` and `descriptionKey` in the catalog.
- **Test against the fake store** (`import { game } from "factoria:test"`): `game.platform.state().fake` shows what was
  unlocked and submitted; `game.platform.set({ signedIn: false })` and `game.platform.respond("leaderboards.submit",
  { error: "network" })` test the bad days; `game.platform.set({ backend: "none" })` tests a game with no store; and
  `game.platform.reset()` between tests. `tests/store.test.js` and `tests/store_screens.test.js` are the model.
- The same calls reach the real stores with one setup command per backend (Steam, Apple, Google Play) described in
  PLATFORM.md; the game does not change.

## 7. Credits, license notices, AI content disclosure, crash reports

- **Credits screen.** The menu kit's `scripts/ui/credits.js` shows your lines and then the software inside the FactorIA
  runtime from `game.notices()`. Put your team, music and font credits in the string table (`credits.*`), not in the script.
- **License notices.** Every export writes `FACTORIA_NOTICES.txt` where the platform ships it; keep it in what you
  distribute. `factoria docs licenses` prints the same list. Your own third-party assets (fonts, music, sprites) need their
  licenses honoured: put their credits on the credits screen and keep their license files ([EXPORTING.md](EXPORTING.md#license-notices)).
- **AI content disclosure.** Stores ask whether the game has AI-generated content. Record where every asset came from
  (`assets.set_provenance` for files you did not generate through the engine), and `assets.disclosure` answers
  from the records; the export writes the same text as `AI_CONTENT_DISCLOSURE.md` next to the game
  ([EXPORTING.md](EXPORTING.md#ai-content-disclosure), [ASSETS.md](ASSETS.md)). Fix the "assets without provenance" list
  before you export.
- **`log.txt` and crash reports.** Every desktop run writes `log.txt` in the save folder (rewritten at each start); a
  crash writes a report to `crashes/` next to it, and the next start logs one line naming it. Nothing is sent anywhere. Tell
  players, on the support page, to send the `crashes` folder with `log.txt`. On the web there is no `log.txt` (the log goes
  to the browser console); Android and iOS use their own crash logs (`adb logcat -s factoria`; see [MOBILE.md](MOBILE.md)).
  Make your own errors teach: `console.error` with what failed and what to do, never a silent `catch`.
- **Privacy.** The engine collects nothing and connects to nothing by itself. If you add analytics, ads or accounts,
  the store forms change ([MOBILE.md](MOBILE.md), "Store privacy forms"). Privacy policy and EULA templates:
  [LEGAL.md](LEGAL.md).

## 8. Tests that keep it finished

A game is finished only while its tests pass. Run `factoria test` before every release. Lantern Keep's suites are the model,
one file per promise (about 75 seconds in all):

| File | Keeps true |
|---|---|
| `tests/levels.test.js` | every scene is what its map builds; every level has its parts |
| `tests/mechanics.test.js`, `play.test.js` | the mechanics work; a bot (`tests/helpers/autoplay.js`) finishes every level |
| `tests/menus.test.js` | main menu, pause, options, language and the level end panel, with the gamepad only |
| `tests/saves.test.js` | slots, migration from a fixture, damaged saves, `storage.corrupt`, cloud saves and their failures |
| `tests/accessibility.test.js` | every option saved, applied and effective; every screen in every language at 100 % and 200 % |
| `tests/languages.test.js` | every table has the same keys and placeholders; the language button; Arabic mirrored |
| `tests/store.test.js`, `store_screens.test.js` | stats, achievements and leaderboards from game events; the screens, with the fake store |
| `tests/shipping.test.js` | the settings exports rely on: icon, touch controls, safe area, store texts in every language |

Habits that make them work:

- Tests start from nothing: a `fresh()` that removes the slots and settings, resets `session`, sets the language and
  `time.scale = 1`, and calls `game.platform.reset()`. Tests use an in-memory `storage` and never touch a real save.
- Drive menus with `game.gamepad(0).tap("A")` and assert on `ui.focused`, widget values and `ui.on` events: if a menu works
  with the pad alone, it works with anything.
- A bug fix starts with a failing test; a feature is done when its test is in `tests/`.
- Keep a fixture of every old save layout and every language table in the repository.

## Before you call it finished

- [ ] The game starts on a main menu; Play, Options, Credits and Quit (not on the web or mobile) work with pad, keyboard and mouse.
- [ ] Pause works in every level, and resuming restores the game's speed.
- [ ] Volumes per bus, text size, controls and language are options, are saved, and are applied on the next start.
- [ ] Controls can be rebound and reset; no action depends on a key a player cannot change.
- [ ] Saves have a `version`, a migration for every old layout (with a fixture each), three slots, and a "Damaged" state
      that never throws. `storage.corrupt` is handled.
- [ ] Progress is written after each meaningful event, not on exit.
- [ ] Every language has the same keys; every screen fits at 100 % and 200 % in every language; right-to-left looks right.
- [ ] Text size, assist mode, shake and reduced effects are options; no hazard or goal depends on colour alone.
- [ ] Achievements, stats and leaderboards (if any) are declared, translated, tested against the fake store, and do
      nothing harmful when there is no store or no sign-in.
- [ ] A credits screen; `FACTORIA_NOTICES.txt` ships; asset provenance is complete and `AI_CONTENT_DISCLOSURE.md` is read.
- [ ] A way for a player to send `log.txt` and the `crashes` folder.
- [ ] `factoria validate` has no errors or warnings you cannot explain; `factoria test` passes.
- [ ] You looked at screenshots of the menu, a level and the options, in the default language and one other, at 200 % text.

Then export and publish: [EXPORTING.md](EXPORTING.md) for the export steps and [PUBLISHING.md](PUBLISHING.md) for each store.
