# Game menus: main menu, options, credits, loading screen, pause

New projects start with a camera and nothing else. When a game needs menus, the kit gives it the usual set in a
few steps: a main menu, options (video, a colour filter for colour-blind players, audio per bus, controls, language), credits that list the software inside
the runtime, a loading screen and a pause menu. Everything works with only a keyboard, only a mouse or only a gamepad,
and the player's settings are saved between runs.

FactorIA's own tests run exactly these files, driven with gamepad presses only. The kit lives in the FactorIA install
as `templates/menus/` (it is not a project template: `factoria new` does not list it), and one command copies the parts
a game wants and merges their texts into its string tables. The widgets and `ui` events the files use are in the AI guide
(section 9.22) and in `docs.components` (`Panel`, `Button`, `Toggle`, `Slider`, `ScrollList`).

## Add the kit with a command

```bash
factoria call project.add_menu_kit                              # every part
factoria call project.add_menu_kit '{"parts":["pause","loading"]}'   # only these (and what they need)
```

(`project_add_menu_kit` over MCP.) Every file goes to the same path in the game, so the paths in the steps below are the
paths in your project. The parts, in the order of `templates/menus/kit.json`:

| Part | Files | Strings |
|---|---|---|
| `core` | `scripts/settings.js`, `scripts/ui/menu_stack.js`, `scripts/ui/read_aloud.js` | `menu.*` |
| `options` | `prefabs/ui/options.prefab.json`, `scripts/ui/options.js` | `options.*` |
| `textSpeed` | none (a row of the options prefab) | `options.textSpeed`, `options.speed.*` |
| `credits` | `scripts/ui/credits.js` | `credits.*` |
| `shop` | `scripts/ui/shop.js`, `scripts/store_events.js` | `shop.*` |
| `ageGate` | `prefabs/ui/age_gate.prefab.json`, `scripts/ui/age_gate.js`, `tests/age_gate.test.js` | `ageGate.*` |
| `analyticsConsent` | `prefabs/ui/analytics_consent.prefab.json`, `scripts/ui/analytics_consent.js`, `tests/analytics_consent.test.js` | `analyticsConsent.*` |
| `main-menu` | `scenes/menu.scene.json`, `scripts/main_menu.js`, `tests/recipe.test.js` | none of its own |
| `pause` | `prefabs/ui/pause.prefab.json`, `scripts/pause_menu.js` | `pause.*` |
| `loading` | `scenes/loading.scene.json`, `scripts/loading.js` | `loading.*` |
| `keyboard` | `prefabs/ui/keyboard.prefab.json`, `scripts/ui/keyboard.js` | `keyboard.*` |
| `slots` | `scripts/slots.js`, `scripts/ui/slot_screen.js`, `prefabs/ui/slots.prefab.json`, `prefabs/ui/slot_dialog.prefab.json`, `tests/slots.test.js` | `slots.*` |
| `dialogue` | `scripts/dialogue.js` | `captions.*` (sample lines) |
| `card` | `prefabs/ui/card.prefab.json`, `scripts/ui/card.js`, `tests/card.test.js` | `card.*` |
| `cameraRig` | `scripts/camera_rig.js`, `tests/camera_rig.test.js` | none |

A part brings the parts it needs: `pause` adds `core` and `options`, `textSpeed` adds `core` and `options` (and without it `options.prefab.json` has no `text_speed` row), `slots` adds `core` and `keyboard`, `ageGate` and `analyticsConsent` add `core`, `card` needs nothing else, `main-menu` adds `core`, `options` and `credits`. `cameraRig` is not a menu: it is the strategy camera of AI_GUIDE.md section 9.6.1, shipped in the kit because it is added the same way (it adds its `camera_*` input actions to `factoria.json`). The result
lists them in `requiredBy`. The shop, the age gate and the analytics question are optional for the main menu: with no `parts` (everything) it has the Shop button, the shop
panel and the lines that open the age gate and the analytics question; `{"parts":["main-menu"]}` writes a main menu without them (no `shop_button`, `shop`,
`age_gate` or `analytics_consent` in the scene, no import of `age_gate.js` or `analytics_consent.js` in `scripts/main_menu.js`), and
`{"parts":["main-menu","shop"]}`, `["main-menu","ageGate"]` or `["main-menu","analyticsConsent"]` adds just that one.
Adding a part to a game that already has the main menu changes `scenes/menu.scene.json` and `scripts/main_menu.js`: they are listed in `skipped`
(the game's files are never touched) until you pass `overwrite: true` or add the button, panel and lines yourself, as in steps 7 and 8.

- **Files.** A file the game does not have is `added`. One that is already the kit's file is `unchanged`, so running the
  command twice changes nothing. One the game has edited is left alone and listed in `skipped` with the reason, unless
  you pass `overwrite: true`, which replaces it (`overwritten`). Scenes and prefabs are written in the canonical layout
  of `scene.format`.
- **Texts.** The kit's strings are merged into `locales/<language>.json` for every language in `factoria.json`
  `"localization"`: keys the game does not have are added (listed per file in `locales[].merged`), a key it has is never
  replaced, with or without `overwrite`. The kit ships English, Spanish and Arabic; any other language gets the English
  text, which reads better than a key name until a translator replaces it (`locales[].note` says so; see
  [LOCALIZATION.md](LOCALIZATION.md)). A game without a `"localization"` section gets one with English.
- **factoria.json.** Only what the kit needs and the game lacks: the `localization` section above, and the `pause`
  input action for the `pause` part. `settings[]` in the result says what changed.
- **What is left to you** (`nextSteps[]`): the start scene and the first level, the entity with `pause_menu.js` in every
  level, the actions the options let the player rebind. These are the steps below; the command does not guess them.
- **Check.** `tests/recipe.test.js` ships with the `main-menu` part: it opens the menu itself and drives it with a
  gamepad, so it passes whatever `mainScene` is. Run `factoria validate` and `factoria test`.

## Steps

What the command does, file by file; do it by hand when you want to see each file or the command is not at hand.

1. **factoria.json.** Start on the menu, and add a `pause` action:
   `"mainScene": "scenes/menu.scene.json"` and, in `input.actions`, `"pause": ["Escape", "P", "GamepadStart"]`.
2. **Shared scripts.** `scripts/settings.js` keeps the player's settings in `storage` and applies them once per run;
   `scripts/ui/menu_stack.js` opens panels over each other and goes back.
3. **Main menu and credits.** `scenes/menu.scene.json`, `scripts/main_menu.js` and `scripts/ui/credits.js`. Put the
   game's name in the `title` Text and its first level in `MainMenu.firstScene`.
4. **Options.** `prefabs/ui/options.prefab.json` and `scripts/ui/options.js`. The Controls tab lists every action the game has in
   `input.actions` except the `ui_*` ones, labelled with the string `options.action.<action>` (the action's own name when the
   game has no such string). To pick and order them, set the `actions` property of the prefab's Script:
   `"Script": { "path": "scripts/ui/options.js", "props": { "actions": ["move", "dig", "place"] } }`; an action the game does
   not have gets no row. A game with local multiplayer (several people on one machine, each on their own pad or key
   block with `input.player(i)`) sets `"players": 2` (up to 4) in the same `props`: the Controls tab gets a "Player N" button
   on top, and each player rebinds their own keys and pad buttons, saved by player.
5. **Loading screen.** `scenes/loading.scene.json` and `scripts/loading.js`: it loads the first level in the background
   (`scene.load` with `{ async: true }`) and shows the real progress.
6. **Pause.** `prefabs/ui/pause.prefab.json`, `scripts/pause_menu.js`, and one entity in every level scene:
   `{ "id": "pause_menu", "components": { "Script": { "path": "scripts/pause_menu.js" } } }`.
7. **Shop (only when the game sells things).** `scripts/ui/shop.js` and the `shop` panel and `shop_button` of
   `scenes/menu.scene.json`, with the products declared in `factoria.json` `"platform"`
   ([PLATFORM.md](PLATFORM.md)). Without a store (the exported game before a store plugin is added) the button stays
   hidden; a game with nothing to sell leaves the `shop` part out (`parts` without it: the button, the panel and the script are not
   written; by hand, delete them and the three `shop` lines of `main_menu.js`). One entity with
   `scripts/store_events.js` in every level pauses the game while the store's overlay is open.
8. **Age gate (only for ads that reach children and adults).** `prefabs/ui/age_gate.prefab.json`, `scripts/ui/age_gate.js`, the
   `age_gate` panel of `scenes/menu.scene.json`, and the line in `main_menu.js` that opens it; all of them come with the `ageGate` part, and a
   game whose ads do not reach children and adults leaves it out. See "Age gate" below.
9. **On-screen keyboard (only for a game with a TextField).** `prefabs/ui/keyboard.prefab.json` and
   `scripts/ui/keyboard.js`, and one entity with that script in every scene that has a TextField (`keyboard_host` in
   `scenes/name.scene.json`). See "On-screen keyboard" below.
10. **Analytics question (only for a game with an `"analytics"` section).** `prefabs/ui/analytics_consent.prefab.json`,
   `scripts/ui/analytics_consent.js`, the `analytics_consent` panel of `scenes/menu.scene.json`, the line in `main_menu.js` that opens it and the
   `analytics_toggle` switch of the options panel (that one comes with `options`); see "Analytics question" below and [ANALYTICS.md](ANALYTICS.md).
11. **Languages.** `factoria.json` `"localization"`, one `locales/<language>.json` per language, and a `key` on every
   Text and widget the scenes and prefabs write ([LOCALIZATION.md](LOCALIZATION.md)). The scripts take their
   texts from the tables (`i18n.t`), so a game with one language keeps the section with that language and
   `locales/en.json`: `"localization": { "defaultLanguage": "en", "languages": ["en"] }`.
12. **Check.** `factoria call scene.format '{"paths":["scenes","prefabs"]}'` (the demo scene below is written short; it rewrites it in the canonical
   layout), `factoria validate`, a screenshot of the menu (`factoria run --headless --frames 3 --screenshot-at 2`),
   and a test that drives the menus with the pad, such as `tests/recipe.test.js` (`docs.read menu-kit/tests/recipe.test.js`) and `tests/keyboard.test.js` at the end of this page. `ui.state` lists every
   widget with its rectangle, focus and value.

## How it works, and what to change

- **Labels that fit.** Every button, toggle and slider of the kit has `"autoSize": true`: it is at least the `size` the
  file gives and grows to its label in the player's language and at the player's text size (`ui.textScale`), so a Spanish
  label or 200 % text never sticks out and no script measures anything. The main menu is a `fit` column, which grows
  with its buttons. A long label can wrap with `maxWidth` on the button, and a two-line label (`
`) is centred line by
  line. A column that holds a `ScrollList` (a list of saves, achievements) gives it `"fill": true`: the list takes the
  height the other children leave and the column stays inside the screen. `"shrink": true` instead makes the list only as
  tall as its content when that is less than the room left, so a short list makes a short, centred panel and a long one
  stops at the screen height and scrolls. A `fit` panel that is still bigger than the
  screen logs a warning, and `factoria validate` reports it for the design size.
- **Fixed places.** A widget that must keep its size (a card, a round touch button) uses `"autoShrink": true` (with
  `minFontSize`) instead: its label shrinks until it fits, at any text size and in any language. `maxTextScale` stops a
  heading or a label from growing past a scale, a long `Toggle` or `Slider` label wraps with `maxWidth` (a `Slider` can
  put it above the track with `labelAbove`), `ui.overflowed(id)` tells a test that a label still does not fit, and
  `ui.check_layout` finds every such label in every scene, language and text size at once (run it after adding a
  language or a menu)
  (details: [TEXT.md](TEXT.md), "Text that fits").
- **Siblings of one size.** `"uniformSize": true` on a `Panel` makes every `autoSize` button, toggle and slider inside it
  (also in the panels and lists it holds) as big as the largest of them, width and height separately, and it follows
  the labels: when the longest one gets shorter they all shrink. Widgets without `autoSize` keep their size. A grid of
  level buttons as wide as the widest label:
  `{ "id": "levels", "components": { "Panel": { "layout": "grid", "columns": 3, "fit": true, "uniformSize": true } } }`
  with children `{ "components": { "Button": { "autoSize": true, "text": "Level 1" } } }`, `"Level 10"`, `"Level 100"`.
- **Panels that wrap.** A panel can name a second layout for when the first would not fit the screen:
  `"layout": "column", "fallbackLayout": "row"` stands a column's children side by side at a big text size, and a row of
  buttons with `"fallbackLayout": "column"` stacks them. The panel (its content plus padding, and every `fit` panel
  around it) must fit the screen; the deepest panels switch first, so a level select stacks its rows of buttons
  before it puts the worlds side by side. It is chosen again every frame, so it follows the text size and the language.
  A script that must adapt (narrow a text when the column became a row) reads `Panel.usingFallback`. To read a size
  right after changing a text, call `ui.layout()` instead of measuring labels and adding margins.

- **Focus and navigation.** Direction presses (`ui_up/down/left/right`) move the focus to the nearest interactable widget
  in the pressed direction that is lined up with the focused one: its rectangle overlaps the focused rectangle across
  the direction (for Right, they share some rows of pixels). So Right from a tab reaches the next tab and not a wide
  button below the row, and Down from a narrow tab reaches the slider under it, not the Back button further down. Only
  when no widget is lined up does the search take the nearest widget anywhere in that half of the screen (sideways
  distance counts double). When a panel opens and its `autoFocus` widget is not `interactable` (a greyed-out buy
  button), the first interactable widget in reading order (top to bottom, then left to right) takes the focus instead of
  nothing.
- **Panels over panels.** `MenuStack.show(id)` hides the panel on top and shows panel `id`; its `autoFocus` widget takes
  the focus (a focused widget that becomes inactive loses it). `back()` closes the top panel and gives the focus back to
  the widget that had it. Pad B, Escape (`ui_cancel`) and any button tagged `back` call it.
- **A panel that refreshes itself each time it is shown.** Write the refresh in `onEnable()`: it runs every time the
  panel becomes active (the first time right after `onStart`) and before that frame is drawn, so the panel never shows
  the texts of its prefab for a frame. `onDisable()` runs every time it is hidden. A panel spawned inactive already has
  its `.behaviour` (`world.find("level_end").behaviour`), so the code that shows it can pass data first.
  ```js
  export default class LevelEnd extends Behaviour {
    onStart() { this.title = this.world.find("level_end_title"); }   // look up once
    onEnable() { this.title.get("Text").text = `Time: ${session.time}`; } // every show
    onDisable() { game.paused = false; }                             // every hide
  }
  ```
- **Resume without a jump.** The A or Space press that clicks "Resume" is also `jump`. `pause_menu.js` unpauses in its
  next `onUpdate`, not in the click handler: that frame's gameplay was already skipped, so the press never reaches the
  player.
- **Pause and scene loads.** `game.paused` (`time.scale` 0) freezes physics, animations and every behaviour without
  `runWhilePaused = true`. `time.scale` outlives scene loads: set `game.paused = false` before `scene.load`.
  `game.paused = false` restores the `time.scale` the game had when it paused (slow motion, an assist speed), so the
  pause menu needs no code to remember it. In a test, `game.paused` reads the same flag after the menu opens.
- **One options panel in two places.** The menu scene places the prefab as an inactive entity; the pause menu spawns it,
  and the pause panel, when the level starts. A level needs only the `pause_menu` entity, even a level that
  `scene.import_ascii` rebuilds.
- **A panel shared between scenes.** Put the panel in a prefab (like `options.prefab.json`) and give each scene a
  `{ "prefab": ... }` entity. An `overrides` object next to `prefab` changes the prefab's own children for that
  instance: each key is a child's `id`, its `name` or a path of them like `"Panel/Title"`, each value holds `name`,
  `tags`, `active` and `components` (components deep-merge, so `{ "Text": { "text": "You won" } }` keeps the font and
  layer the prefab set). Fields next to `prefab` still change the root, and `children` there are appended after the
  prefab's. In a script, `world.spawnPrefab(path, { childOverrides: { Title: { components: { Text: { text: "You won" } } } } })`
  does the same. A `Text` with a `key` shows its key's text, so override `key` (not `text`) to change it. A key that
  names no child, or a field that does not exist, is an error with a "did you mean". Only the
  prefab's own descendants can be named; a child that is itself a prefab reference takes the same keys as that reference.
  Example, two scenes sharing `prefabs/ui/result.prefab.json`:

  ```json
  { "id": "result", "active": false, "prefab": "prefabs/ui/result.prefab.json",
    "overrides": { "title": { "components": { "Text": { "text": "Level complete" } } },
                   "next_button": { "components": { "Button": { "text": "Next level" } } } } }
  ```

- **Order of a panel's children.** A layout (`column`, `row`) follows the order of the children. `world.spawn(json,
  { parent, index })`, `world.spawnPrefab(path, { parent, index })`, `entity.setParent(parent, keepWorld, index)` and
  `scene.set_parent {id, parent, index}` put a child at a place (0 = first); a button added at run time can go on top
  without touching the others. The order is saved with the scene. An index counts the parent's other children and must
  be between 0 and their number, otherwise it is an error that says the range.
- **Loading screen.** The loading scene loads the next scene in the background with
  `scene.load(session.nextScene, null, { async: true })`: the IO thread reads its files and jobs decode them while the
  loading scene keeps running, a share of the GPU uploads goes in each frame, and `job.progress` (0..1, never goes down)
  is the real share of the files done. The engine switches to the next scene at the end of the frame its files are ready
  (`session` outlives scene loads). Leaving the screen first cancels the load (`job.cancel()` in onDestroy); a scene that
  cannot be loaded in the background (its JSON is broken) falls back to the sync `scene.load`, which reports what is
  wrong. The cost and the budgets are in docs/PERFORMANCE.md, "Background loading".
- **Quit** has no place on phones and tablets, where the system closes apps: `main_menu.js` hides it when
  `game.platform` is `"ios"` or `"android"`.
- **Credits.** `game.notices()` lists the software inside the runtime with its license; the full texts ship next to the
  exported game in `FACTORIA_NOTICES.txt`. Add your own lines (people, music, fonts) to `Credits.lines`.
- **Audio.** One `Slider` per bus (`master`, `music`, `sfx`, `ui`); the defaults are `DEFAULTS.volume` in `settings.js`.
  `audio.getVolume(bus)` reads a volume back.
- **Video.** `window.setMode` (a button that cycles windowed, borderless and full screen; a platform without
  borderless skips it), `window.setMonitor` (a button that cycles the monitors; the row is hidden unless
  `window.supports("monitors")` and the computer has more than one), `setSize` (one of `window.resolutions()`),
  `setVsync` and `frameCap`. They throw when there is no window (headless runs, tests): with `window.available` false
  the rows are greyed out and a note says why. The mode and the monitor are saved in `settings.js` (`windowMode`, and
  `monitor` as `{ index, name }`: the name finds the monitor again when the numbers change) and restored at start, the
  monitor first so a full screen window covers the right one. A save from an older kit (`fullscreen: true`) is read as
  `windowMode`.
- **Interface size.** An "Interface size: 100%" button on the Video tab cycles through `UI_SCALES` in `options.js` (75, 100,
  125, 150 and 200 %) and sets `ui.scale` (docs/TEXT.md, "Interface size"), which makes every screen-space widget, the
  panel itself included, that many times as big at once. Only the sizes at which the panel (760 x 680 UI units) still fits
  the screen are offered, plus the one in use: at the 1280 x 720 design size that is 75 % and 100 %, and the button is
  greyed out when only one is left; a game with a smaller panel `size` in the prefab offers more sizes. The button's text is
  the string `options.uiScale` ("Interface size: {percent}%").
  The choice is saved in `settings.js` as `uiScale` (`null` keeps the `ui.scale` of `factoria.json`) and applied by
  `apply()`; the button writes its percentage again on the `ui.on("scale")` event, so it stays right when a script changes
  the size. The text size has no button in the kit: set `ui.textScale` from `textScale` of the settings the same way.
- **Controls.** A click on an action's button waits for the next press (`input.lastPressed()`, skipping the frame of the
  click), then `input.rebind(action, [pressed, ...the other device's bindings])` and saves the list. While it waits,
  `MenuStack.busy` keeps Escape and B from closing the panel (and `MenuStack.busy` is cleared whenever a scene builds a new `MenuStack`). `input.buttonName(action)` names the button as the
  player's pad shows it (Cross on a PlayStation pad, A on an Xbox pad); "Reset to defaults" is `input.resetBindings()`.
  `input.lastPressed()` gives a chord when modifiers are held ("Ctrl+Z", "Shift+MouseLeft"), so the player records one by
  holding the modifiers and pressing the key; a modifier pressed on its own is taken when it is let go ("LeftShift"), and
  the button shows the chord as `input.buttonName` prints it ("Ctrl+Z"). The binding the kit writes is the chord itself.
  With the `players` property above 1 (local multiplayer) the tab starts with a "Player N" button that cycles through the
  players and every row shows the player's keys and its pad buttons (`input.player(i).bindings(action, "keys")` and
  `"pad"`, which also work for a player with no device yet, as in a menu). A key replaces the keyboard list of the
  action, a pad button the pad list: `input.player(i).rebind(action, [pressed], family)` for that player only, and the
  other players keep theirs. The mouse and touch are not bindings there (they belong to every player), and a key outside
  the player's key scheme is refused by the engine and logged. `player(i).export()` is saved in `settings.playerBindings`
  (by player), "Reset to defaults" is `input.player(i).reset()` for the shown player, and `settings.apply` imports
  them again at the next start, logging what `import()` skipped. Assigning the devices (`input.player(i).use(...)`)
  stays with the game: the menu only edits bindings. With `players` at 1 (the default) nothing changes.
- **Language.** The Language tab's button names the current language (`i18n.name`) and cycles through `i18n.languages`
  with `i18n.setLanguage`: every Text and widget with a `key` is rewritten at once. The choice is saved in `settings`
  (`language`); `settings.apply` restores it at the next start, and ignores, with a warning, a language the game no
  longer has. Without a saved choice the game starts in the player's system language when it has it, else in
  `defaultLanguage`. A game with one language greys the button out.
- **Texts: with a key, or written by a script.** A Text or widget with a `key` shows `i18n.t(key)` and is rewritten when
  the language changes, so a script must not write its `text` (the next frame puts the translation back). Text a script
  builds (`Window size: 1280 x 720`, the controls' buttons, the shop's messages) uses `i18n.t(key, args)` with
  `{placeholders}` and writes it again on `i18n.on("change", ...)`. A panel's script starts when the panel first opens,
  so it reads the language then. Credits spawn their Texts with a `key` too: they change while the panel is open.
- **Shop.** A purchase is granted first and finished after (`platform.purchases.finish`): the store hands over a
  purchase that was never finished again on the next run, so a crash between the two loses nothing, and the wallet
  remembers the transactions it already granted so the player is not paid twice. A cancelled purchase and a store error
  (`e.code`, `e.hint`) show a message and grant nothing. "Restore purchases" returns the non-consumables. The tests are
  `tests/platform.test.js` in the fixture: they drive the shop with the pad against the fake store.
- **Age gate.** <a id="age-gate"></a>A game whose ads reach children and adults (`"platform": { "ads": { "audience": "mixed" } }`
  in factoria.json) must not request an ad, or show Google's consent form, before it knows whether the player is under the
  age of consent ([PLATFORM.md](PLATFORM.md#children-and-consent)). The `ageGate` part is that question: with it, `main_menu.js` (the
  `main-menu` part without `ageGate` has no such line) opens the `age_gate` panel over the title screen, the first time, when `platform.ads.audience` is `"mixed"` (any other audience
  never sees it). The player picks a year of birth on a slider that starts at no particular year, or presses "I would rather
  not say"; the script computes `underAge` (born 16 or fewer years ago, or declined: the highest age of consent in Europe,
  and a year alone is off by one), calls `platform.ads.setUnderAge(underAge)`, and keeps **only that boolean** in
  `storage` (`ageGate`), never the year. The panel cannot be closed with Back or Escape. On the next runs the stored
  answer is sent again at start and the panel stays closed. A game that asks the age its own way calls
  `platform.ads.setUnderAge` itself and deletes this part. `tests/age_gate.test.js` drives the gate with the pad against the
  fake store.
- **Analytics question.** <a id="analytics-question"></a>`analytics.event()` sends nothing until the player said yes
  ([ANALYTICS.md](ANALYTICS.md)), so a game with an `"analytics"` section in factoria.json asks once. With the `analyticsConsent` part,
  `main_menu.js` opens the `analytics_consent` panel over the title screen on the first run, when `analytics.consent()` is still `"unknown"`
  (the age gate comes first when the audience is `"mixed"`; a game without the section, or whose ad consent already answered it with
  `consentFromAds`, never sees the panel). "Allow" and "No thanks" both call `analytics.setConsent`, both are kept and the question does
  not come back; Back and Escape cannot skip it. The options panel has the matching switch (`analytics_toggle`, shown only when
  `analytics.configured`): the player changes the answer there at any time, and switching it off forgets what waited to be sent. Edit
  `analyticsConsent.what` in `locales/*.json` so the text says what your game really sends ([LEGAL.md](LEGAL.md)).
  `tests/analytics_consent.test.js` checks the question; in a game without the section it only checks that there is nothing to ask. A
  game of your own that has no main menu calls `openAnalyticsConsent(menus)` from its first scene. A test of yours that loads the
  main menu of a game with analytics sets the answer first, as `tests/recipe.test.js` does.
- **Ad privacy button.** The options panel has a hidden "Ad privacy settings" button (`privacy_options`). `options.js` shows
  it only when the game has the `ads` service and `platform.ads.consent().privacyOptions` is `"required"`, and its click
  calls `platform.ads.privacyOptions()`, which opens Google's form where the player changes their ad choices.
- **Read menus aloud.** `ui.speak(text)` says a line with the operating system's text to speech (Windows SAPI, macOS and
  iOS AVSpeechSynthesizer, Android TextToSpeech, Linux speech-dispatcher, the browser's `speechSynthesis`), in
  `i18n.language`; `ui.stopSpeaking()` stops it and `ui.speechAvailable` says whether the system can speak at all. The
  kit's Options > Audio has a "Read menus aloud" toggle (`settings.readAloud`, off until the player turns it on: the
  first run starts it on only when the system has a screen reader, see below) and `scripts/ui/read_aloud.js` speaks the focused widget's text, in the language the
  player chose. Headless runs and tests speak nothing and record the lines: `game.spoken()` in `factoria:test` returns
  `[{ text, language, interrupt }]` (fixture `tests/speech.test.js` moves the focus through the menu and checks them).
  Speech only helps while someone can hear it: the manual check below says how to listen on each system. The option
  starts on when the system has a screen reader running (`game.accessibility.screenReader`, next item).
- **Start from the system's accessibility settings.** `game.accessibility` is `{ textScale, reduceMotion, highContrast,
  screenReader }` as the player's operating system has them (`textScale` 1 = 100 %; read when the game starts and again
  when the window regains focus; every value is `1` / `false` where the system cannot say: docs/SCRIPTING.md lists what
  each platform reads). The engine applies none of them except the game feel effects (GAME_FEEL.md), which follow `reduceMotion`. `settings.js` starts its options from them for a player who
  never chose: text size from `textScale` (`ui.textScale`), "Read menus aloud" from `screenReader`, and the reduced effects from
  `reduceMotion`: `reducedEffects` stays `null` (follow the system, also when the system changes later) until the player picks `true` or `false`; `applyFeel` passes it to the
  engine's `feel.reduceMotion` / `feel.reducedEffects`, which turn down shake, squash, hit-stop and flashes, and your own particles check
  `settings.reducedEffects(s)`. An options row that changes it calls `settings.applyFeel(s)` and then `settings.save(s)`. The first `save()` stores every other setting, so the
  player's own choice wins from then on. Tests set the system with `game.setAccessibility({ textScale: 1.5 })`
  (`tests/accessibility.test.js` checks the first-run values and that a saved choice wins).
- **Captions (subtitles).** A `Captions` component on one entity of the scene (`captions` in the kit's menu and level
  scenes) draws the lines the game puts on the caption list: `audio.play(path, { captionKey, speaker })` shows a line while
  that sound plays (it goes when the sound ends or is stopped; `captionSeconds` overrides, and a looping sound needs it)
  and `ui.caption(text, seconds, { key, speaker })` shows one without a sound. `caption` is plain text; `captionKey` /
  `key` is a string-table key, so a line on screen changes language with the game. The component places itself like any
  widget (anchor, safe area), shows the newest `maxLines` lines on a background that hugs them, and follows
  `ui.textScale`, the font chain and right-to-left. The kit's `scripts/dialogue.js` is the helper the game calls
  (`say("captions.welcome", { sound, speaker })`). Options > Audio has a "Subtitles" toggle (`settings.subtitles`, on by
  default): "off" means the `captions` entity is switched off by `settings.applyScene()` in every scene, so the game
  keeps making the same calls and the lines are only tracked. A scene with no `Captions` entity draws nothing and the log
  says so once. In `factoria:test`, `game.captions()` returns `[{ text, speaker, key, source }]` (fixture
  `tests/captions.test.js`: a sound and a line, in English, Spanish and Arabic, and the toggle). The speaker name is plain
  text written when the line starts (use `i18n.t`).
- **Paste and copy.** A focused `TextField` pastes the clipboard with Ctrl+V (Cmd+V on macOS) and copies its whole text
  with Ctrl/Cmd+C. A paste is appended at the end, drops newlines and control characters, stops at `maxLength` and sends
  `ui.change` once; the letter of the chord is not typed. Phones have no clipboard for games
  (`window.supports("clipboard")`; docs/SCRIPTING.md "Clipboard").
- **On-screen keyboard (gamepad players).** A `TextField` takes typed text from a keyboard, and a phone raises its own
  keyboard when one gets the focus (the engine does that, not the game: docs/MOBILE.md). A player with only a pad has
  neither, so `scripts/ui/keyboard.js` (a behaviour: put it on one entity of the scene) opens
  `prefabs/ui/keyboard.prefab.json` over the game when a `TextField` takes the focus *and the last input was a gamepad*
  (`input.lastDevice`), or when A is pressed on a focused `TextField` (after B closed it). It is made of plain `Panel`
  and `Button` widgets: the d-pad walks the keys like any menu, A types the key, and the bottom row has Shift (upper
  case), Space, Delete and Done. The widgets behind it stop taking focus while it is open. Typing writes the field's
  `text` and sends `ui.change`, exactly as a real keyboard does, so the game's code is the same on every device; Done
  closes it and sends `ui.submit` (what Enter does), B (`ui.cancel`) closes it and keeps the text. It respects
  `maxLength`, and it closes by itself when the player touches the screen or presses a keyboard key. A game's own
  `ui.cancel` handler should do nothing while `OnScreenKeyboard.isOpen` is true
  (`import OnScreenKeyboard from "./ui/keyboard.js"`). On a Steam Deck (or in Big Picture) the Steam plugin shows Steam's own keyboard for a field a pad focuses
  (docs/PLATFORM.md, "Steam Deck keyboard"); the engine then sets `input.platformKeyboard` and this keyboard stays closed
  for that field. It opens as above everywhere the platform shows none.
  *Layout and languages.* The keys follow `i18n.language`: Latin (a-z, the digits and the accented letters of Spanish,
  French, German, Portuguese, Italian, Polish, Turkish, Swedish, Danish, Norwegian and Czech: `EXTRA`), Cyrillic
  (Russian, Ukrainian, Bulgarian, Serbian, Macedonian), Greek and Korean (Hangul jamo, below). Every other language (Arabic,
  Hebrew, Chinese, Japanese, Thai, Hindi...) gets the **Latin keys**: on a PC or phone the player uses the system keyboard
  and IME, and a game that must take a name in such a script on a pad adds a layout: `LAYOUTS.he = "..."` and
  `SCRIPT_OF.he = "he"` (one character per key, lower case first). The labels of Space, Delete and Done are the strings
  `keyboard.space`, `keyboard.delete` and `keyboard.done` of the locale tables.
  *Input methods (IME).* A script whose letters are parts of characters needs more than one character per key. `IME` maps a
  language code to `{ compose(text, ch), decompose(text) }`: `compose` returns the field's text after the key `ch` is typed (it
  may change the last character) and `decompose` the text after Delete (it may take only a part of the last character away).
  Both look at the text alone and keep no state; the field's `maxLength` counts the characters of the result. Korean's is built
  in (`hangulIme`, for `ko` and `ko-KR`): the keys are the jamo of the two-set layout (consonants, then vowels; Shift gives the
  doubled ones, `SHIFTED`), a vowel after a consonant makes a syllable (ㄱ + ㅏ = 가), a consonant after it is its final
  (가 + ㄴ = 간, compound finals such as 닭 included), a vowel after a final takes that consonant to a new syllable
  (간 + ㅏ = 가나), and Delete takes the last jamo away (간 -> 가 -> ㄱ -> nothing). A game with another such language sets
  `IME.xx = { compose, decompose }`. The Text's font must have the jamo and the syllables a name can hold (docs/TEXT.md,
  `assets.subset_font` with `keep`). `tests/slots.test.js` types a Korean slot name through the slot dialog with the pad.
- **Add an option.** Add a widget to `options.prefab.json` (with a `key` for its label), read and write its value in
  `options.js`, and keep it in `settings.js` (`defaults()` and `apply`). The colour filter of the Video tab is such an
  option: it sets `Camera.colorFilter` on the scene's camera (the entity with the id `camera`), so `applyOnce()` sets it
  again in every scene; rename the id in `settings.js` if your camera has another.
- **Add a language.** Add its tag to `localization.languages`, copy `locales/en.json` to `locales/<tag>.json` and
  translate it (a missing key shows the default language's text and is listed by `factoria call i18n.state`). Put the
  language's own name in `"$name"`: it is what the Language button shows.
  For a right-to-left language (Arabic, Hebrew, Persian, Urdu) the options panel mirrors itself: the engine mirrors the
  screen-space UI (`ui.mirrorRtl`, on by default), its tabs row has `"direction": "auto"` and the panels and the wrapped
  note use `"align": "start"`; a widget that must stay put has `"mirror": false` (docs/LOCALIZATION.md, section 6).
- **Restyle.** `color`, `textColor`, `accentColor`, or a `texture` with `slice` (9-slice) on any widget: AI guide
  section 9.22.
- **Phones: notch and Back.** A panel or text pinned to a screen edge (a top bar, a corner button, the "Loading..." text)
  hides under a notch or the home indicator; set `safeArea: true` next to its `anchor` and the anchor is that edge of
  the safe area instead. The centred menu panels above need nothing. To check it without a phone, run
  `screen.set_safe_area {"profile":"phone-portrait"}`, then `game.step` and `game.screenshot` (or `game.setSafeArea` in a
  test). Android's Back button is `input.onBack`: register one handler per open screen (options closes to the main menu,
  the pause menu resumes) that returns `true`, and let the root menu return `false` so Back leaves the game
  (docs/MOBILE.md, "Phone features").
- **Phones: playing without a pad.** The menus already work by touch. For the game itself, add a `TouchStick` and a few
  `TouchButton`s to the game scene: they press the same gamepad bindings a real pad does, show only while the player
  uses touch and sit in the safe area (docs/MOBILE.md, "On-screen gamepad").

## Save slots

The `slots` part is the save / load screen of a game with several saves: five named slots and an autosave, each a record
`{ counter, name, chapter, playTime, pic, data }` in `storage` (key `slot1`..`slot5`, `slot_auto`), where `data` is whatever the game
saves. `counter` goes up by one on every save, so with cloud saves (`platform.has("cloudSave")`) the copy with the higher counter wins
when the screen opens (`slots.syncCloud()`); a delete removes the cloud copy too. A text in a slot that has no `data` is read as a bare
save (a game can start with plain saves), and one that cannot be read or is from a version `upgrade` rejects is `damaged`: the row says
so, with the reason, and the player can delete it. The game supplies two things: what is saved (`snapshot`, or `save` to write the slot
yourself) and how a slot is loaded (`launch`). Everything else is the kit's: the screen builds `prefabs/ui/slots.prefab.json` and
`slot_dialog.prefab.json`, a click on a slot in save mode opens the dialog with a TextField for the name (the on-screen keyboard opens
by itself for a gamepad player), an empty name saves under `defaultName()`, and a delete asks first. `cannotSave()` returns a string-table
key (`"slots.busy"`) while the game may not be saved (a cut-scene, a loading screen); the save rows are greyed out and the key is shown
under the title. A cloud answer that arrives after the scene changed draws nothing (the screen compares `scene.generation`).

```js
const slots = new Slots({ upgrade: migrate, describe: (d) => ({ chapter: d.level, playTime: d.seconds }) });
const screen = new SlotScreen(menus, {
  slots,
  launch: (data) => startFrom(data),                              // load
  snapshot: () => ({ data: mySave(), chapter: 3, playTime: 3725 }), // save
  cannotSave: () => (inCutscene ? "slots.busy" : ""),
  getPic: () => pic,                                              // capturePic() taken before the menu opened
});
screen.open("save");                                             // or "load"; call screen.tick() every frame
```

The files are read with `docs.read menu-kit` (see "The files" below). `tests/slots.test.js` builds its own scene, so it passes in any game with the part.

## Text speed

`{"parts":["textSpeed"]}` (or the whole kit) adds a "Text speed" button to the Options Audio tab: slow, normal, fast and instant
(`TEXT_SPEEDS` in `scripts/settings.js`), kept as `settings.load().textSpeed` in characters per second (0 = a whole line at once; the
default is 45, or 0 when the system asks to reduce motion). The kit does not draw dialogue lines: the game's dialogue box sets
`Text.visibleCharacters = settings.revealedCharacters(secondsSinceTheLineAppeared)`. For any other row of the game, call
`addOptionsRow("audio", { id, text, click })` of `scripts/ui/options.js` before the panel is spawned (its comment says how).

## Anchors and pivots

A widget is placed by two points that count Y in opposite directions. `anchor` is a point of the screen as a fraction,
counted from the top-left with Y DOWN (`[0, 0]` top-left, `[1, 1]` bottom-right). `pivot` is a point of the widget, counted
with Y UP (`[0, 0]` its bottom-left corner, `[1, 1]` its top-right, `[0.5, 0.5]` its centre). The widget's pivot sits on
the anchor point, moved by `position`. So a bar on the bottom edge is `anchor [0.5, 1]` with `pivot [0.5, 0]`: its bottom
edge rests on the screen's bottom edge. With `pivot [0.5, 1]` the same bar would hang below the screen.

```
anchor Y (down)            pivot Y (up)

(0,0)---------(1,0)        (0,1)---------(1,1)    pivot [0.5, 0] = middle of the
  |   screen     |           |    widget    |      bottom edge, so with
  |              |           |      x       |      anchor [0.5, 1] the widget
(0,1)---------(1,1)        (0,0)---------(1,0)    stands ON the screen's bottom
```

`factoria validate` warns about a widget of a scene that lies completely outside the design size, which is what a wrong
pivot Y usually does: the warning names the widget, the rectangle it covers and the fix.

## Pressing the focused widget in a test

`game.tap("ui_submit")` presses the focused widget, like Enter, Space or the pad's A: it holds the action for one frame,
steps, releases it and steps again, so the widget gets one click (`ui.focus("play_button")` first to choose it).
`game.press("ui_submit")` holds the action until `game.release("ui_submit")`; the UI reacts to the frame the action goes
down, so pressing it again while it is still held presses nothing. Use `tap` for a click and `press`/`release` only to test a
hold; after a `press`, `release` it before the next one.

```js
ui.focus("play_button");
game.tap("ui_submit");          // one click on Play
game.press("ui_submit");        // clicks the focused widget once, now held...
game.step(3);
game.press("ui_submit");        // ...so this presses nothing
game.release("ui_submit");
```

## A gamepad cursor over the menus (and the game)

A game played mostly with the mouse that also supports a pad moves a cursor with a stick. The UI needs no scan of the
scene for it. Each frame: add the stick to the cursor position, then `ui.setPointer(x, y, { down: input.down("primary") })`
(the UI takes the pointer and left button from there from the next frame on: `ui.hovered`, the press, the click on
release, a Slider drag and the wheel's target all follow it); `ui.widgetAt(x, y)` answers what is under a point
(the topmost visible widget or Panel, nothing for a row a ScrollList clips) and `ui.pointerOverUi` whether the cursor is
over any. When the mouse moves again call `ui.setPointer(null)`. If the same button is also bound to `ui_submit`
(`GamepadA` is, by default), a focused widget is clicked by that action as well, so either clear the focus while the
cursor rests (`ui.focus(null)` stays empty until the next D-pad press, an open panel's `autoFocus` does not take it back)
or move only the hover (`down: false`) and let `ui_submit` press the widget you focused under the cursor.

## A choice card, and modal panels

An event, a story beat or a decision in a management game is a card: a title, a body, two or three choices that each say
what they cost, one choice greyed out because the player cannot pay for it, and then what happened. The `card` part is that
card: `new Card(options)` spawns `prefabs/ui/card.prefab.json`, `card.ask(...)` shows the question and `card.answer(...)` the
result with a Continue button, and `card.close()` removes it.

```js
import { Card } from "./ui/card.js";

const card = new Card({
  holdClock: true, // game.paused while the card is open (what was paused before stays paused)
  onChoose: (id) => {
    const result = resolve(id); // the game's own rules
    card.answer({ body: result.text, effects: result.effects }); // "[c:#8fe38f]+4 wood[/c]"
  },
  onContinue: () => card.close(),
});
card.ask({
  kind: "Event",
  title: "A stranger at the gate",
  body: "Asks for [b]shelter[/b].", // rich text: [b], [c:colour], [icon:name] (Text.markup)
  choices: [
    { id: "help", text: "Help", detail: "Costs 2 wood" },
    { id: "buy", text: "Buy the map", disabled: "Needs 50 coins" }, // greyed out, and the line under it says why
    { id: "leave", text: "Leave", detail: "Nothing happens" },
  ],
});
```

- **Modal.** The card's backdrop Panel has `modal: true` (`Panel.modal`, see `docs.components`): while it is
  active the mouse, the wheel, the arrows and the pad reach only the widgets inside it. A button under it gets no hover, no
  press and no click, a tooltip does not show over it, nothing under it takes a drop, the focus leaves it for the card and
  never goes back until the card closes, and `ui.pointerOverUi` is true everywhere, so a map camera or a click-to-build
  handler stands down. It does not pause the game: that is `holdClock`, which sets `game.paused` (scripts that must keep
  running meanwhile set `runWhilePaused`). A game with its own clock (a speed control) leaves `holdClock` off and holds
  that clock itself, as Tidewater Market does.
- **The wheel and Escape under a modal.** A modal consumes the mouse wheel (a ScrollList inside still scrolls); set
  `wheelPassThrough: true` on it when a script should keep the wheel, such as a zoom in an inventory view. Escape is
  `ui_cancel` and usually `pause`: a `ui.on("cancel", ...)` handler that closes the panel returns `true`, which consumes
  the press (`input.consume("ui_cancel")`), so the pause handler of the same frame does not also open the pause menu. While
  a TextField or the on-screen keyboard has the focus, actions bound to letters read as not pressed (`input.textInputMode`),
  so typing P does not pause. The kit's `MenuStack` resets `MenuStack.busy` when a scene builds one.
- **Mouse, keyboard, pad.** The choices are Buttons in a column: up and down (arrows, D-pad, left stick) move between the
  ones that can be chosen, Enter, Space or gamepad A picks, a click picks. The first choice that can be chosen has the focus,
  Continue has it on the result stage. A disabled choice is not focusable and a click on it does nothing: its `disabled`
  text is drawn in its detail line (`reasonColor` changes the colour; `[c:...]` names the game's `text.colors`).
  Escape and gamepad B do nothing: the card is answered with a choice.
- **Looks.** Everything is laid out by the engine (column layouts, wrapped texts, fit panels), so a longer translation or a bigger
  text size (`ui.textScale`, up to 125 % here) makes the card taller, not clipped. Copy the prefab to change the size, the
  colours or the fonts; `new Card({ prefab })` takes the copy. Ids are stable (`card_title`, `card_body`, `choice_<id>`,
  `choice_<id>_detail`, `card_effects`, `card_continue`) for tests.
- **Test.** `tests/card.test.js` shows a click under the card doing nothing, the arrows skipping a disabled choice, the pad
  and the result stage. `Panel.modal` alone works on any panel (a confirm dialog, the pause menu): set `"modal": true` on the
  root Panel of a screen that must own the input.

## Widgets from your own entities

A shop sign you hit with the mouse, a book whose pages turn, a menu painted on a wall in a 3D-looking scene, a card hand,
a map marker: these are not rectangles in a Panel. Give any entity the `Interactable` component and it is a widget of the same
system as Button, Toggle and Slider, whatever it is made of (sprites, shapes, text, children), in world space or on the
screen. There is no second UI behind it: it takes focus, arrow-key and pad navigation, `Tab`, `ui_submit` and `ui_cancel`,
hover and press, `Panel.modal` scopes, `game.click`, `ui.widgetAt`, `ui.rectOf` and the `ui.*` commands exactly like a Button.

```json
{ "id": "start", "components": {
    "Transform": { "position": [-60, 40] },
    "Shape2D": { "size": [60, 20] },
    "Interactable": { "autoFocus": true } },
  "children": [
    { "id": "start_glow", "components": {
        "Shape2D": { "size": [64, 24], "color": [1, 1, 0, 1] },
        "InteractableVisual": { "mode": "show", "when": "hover" } } } ] }
```

- **The hit area.** `size` and `offset` give a rectangle in the entity's own space (so it scales and turns with the entity and its
  parents). With `size` `[0, 0]` the area is the box around the visuals of the entity and its active children (sprites, shapes,
  text); not counted are a child that is an `InteractableVisual` which shows and hides with the state (a glow that
  appears on hover must not make the area grow), a slider's `knob` and `fill`, and a child that is an Interactable itself (it
  is a widget of its own). An entity with no area cannot be hit or clicked: `game.click` says so.
- **World or screen.** `space: "auto"` is screen space when the entity or a child draws in screen space (a `Text` or `Sprite`
  with `space: "screen"`), else world space; `"world"` and `"screen"` force it. A world-space area is projected through the
  camera that draws at the pointer (several cameras with viewports work, each pointer position uses the one drawing there), so a
  widget on a swaying sign or a page turning in 3D is hit where it is drawn, and follows parents that move, scale or rotate.
  A screen-space widget wins over a world-space one under the same point, and a modal `Panel` blocks the Interactables
  outside it like any other widget outside it. An Interactable on an entity that is also a Button, Toggle, Slider,
  TextField, Panel or other UI-box component is ignored: the built-in widget wins. The hit test is the quad of the
  area's four projected corners (exact under a perspective camera too); a slider drag measures how far along the projected
  track the pointer is, which is only approximate under strong perspective.
- **`kind`.** `button` sends `ui.click {id}` when the pointer is released over it after being pressed on it, or on `ui_submit`
  while it has the focus. `toggle` flips `on` the same way and sends `ui.change {id, value}` (a boolean; a toggle sends no
  `click`). `slider` keeps a number `value` between `min` and `max`, snapped to `step`: dragging along the area, or
  left / right (down / up with `axis: "y"`) while focused, sets it and sends `ui.change {id, value}`. The track is the area along
  `axis`. `knob` (a child of the Interactable) is moved along the track to the value, and `fill` (a child with its pivot at the
  start of the track) is scaled along `axis` to the fraction; they are placed in world space, or in screen space when `size`
  is set. Scripts may write `on` and `value`: no event is sent for a write (`game.setSlider(id, value)` and the
  `ui.set_slider` command do send it, as a drag would). In a script, `knob` and `fill` may name children spawned after the slider: `world.spawn` leaves them empty with a warning and links them when an entity with that id appears (or put the children in the same call with `children`); a field set by hand in between wins, and an id that never appears is reported again after about 10 seconds of frames.
- **States, without code.** `Interactable.state` is the one state the visuals show: `disabled` (`enabled` is false), else
  `pressed`, else `hover`, else `focused`, else `normal`; `hovered`, `focused` and `pressed` are the flags (read-only, written by the
  UI). Put `InteractableVisual` on a child of the Interactable (or set `target`): `mode: "show"` makes that entity active only while
  `when` holds (`hover`, `pressed`, `focused`, `highlighted` = hovered OR focused, one look for the pointer and the keyboard / gamepad, `normal`, `disabled`, `on` / `off` for a toggle, `always`); `mode: "tint"` sets the colour
  of its Sprite, Shape2D or Text from `normal`, `hover`, `pressed`, `focused` and `disabled`. A check mark that shows while a toggle is on
  is a child with `when: "on"`. `InteractableVisual` on the Interactable's own entity does nothing in `show` mode.
- **Focus and navigation.** The same rules as the built-in widgets (see SCRIPTING.md, "Focus and navigation"): nothing is
  focused until an `autoFocus` widget takes it, the arrows and the d-pad move the focus to the nearest widget in that direction
  among Buttons and Interactables alike (using their areas as seen on the screen), `ui_cancel` sends `ui.cancel`. `Tab` (`ui_next`) and
  `Shift+Tab` (`ui_previous`) walk the focusable widgets in reading order, wrapping around (new default actions for every widget); like the arrows they need a focus
  to start from (focus one with `autoFocus` or `ui.focus(entity)`). `focusOnHover: true` moves the focus to the widget when the
  pointer enters it, once per entry (a widget that appears, or is switched on, under a resting pointer is an entry too, so a page turn leaves the focus and the hover tint on the same widget); the default, like a Button, moves it on a press. `enabled: false` makes it a greyed-out
  widget: never hovered, focused or clicked, skipped by navigation.
- **Events** (`ui.on`, or `this.on("ui.<type>", ...)`): `click`, `change`, `focus` and `cancel` as for the built-ins, plus
  `hover` (`value` true when the pointer came over it, false when it left), `blur` (the focus left it), `press` (the pointer went down
  on it) and `release` (the pointer went up; `value` is true when it was still over the widget, and then `click` follows). `hover`,
  `blur`, `press` and `release` come from Interactables only; Button, Toggle and Slider do not send them.
- **Finding it.** `ui.widgetAt(x, y)` returns it, `ui.rectOf(id)` is the box of its area on the screen (design pixels, y down), `ui.focus(id)` focuses it
  (false when it is disabled), `ui.state` lists it with `kind: "Interactable"`, `interactableKind`, `state`, `world`, `value` (a toggle's or slider's)
  and `text` (its accessibility label), and `game.click(id)` / `game.mouseMove(id)` / the `game.click` command aim at the centre of its area.
  `label` is the accessibility label; empty, it is the first `Text` among the entity and its children; `key` and `keyArgs` translate it
  like a Button's. There are no tooltips on an Interactable yet.
- **A test plays it like a person.** Nothing in this menu is a Button, and the test only presses, moves and clicks:

```js
import { test, expect, game } from "factoria:test";
import { ui } from "factoria";
import menu from "../scenes/main.scene.json";

test("the world menu works with the pointer and the keyboard", () => {
  game.loadJson(menu);
  game.step(1);
  expect(ui.focused.id).toBe("start");                // autoFocus
  game.mouseMove("music");                            // the centre of its area, as the camera shows it
  game.step(1);
  expect(ui.hovered.id).toBe("music");
  game.click("music");                                // a toggle: press, release, ui.change
  expect(game.find("music").get("Interactable").on).toBe(true);
  expect(game.find("music_tick").active).toBe(true);  // an InteractableVisual child with when: "on"
  game.tap("ui_down");                                // the arrows walk world widgets like Buttons
  game.setSlider("volume", 0.5);                      // a slider Interactable: ui.change, and the knob moves
  const track = ui.rectOf("volume");
  game.drag("volume", [track.x + track.w, track.y + track.h / 2]);      // dragging to the end of the track
  expect(game.find("volume").get("Interactable").value).toBe(1);
});
```

The engine's own test of this (`engine/runtime/tests/ui_tests.cpp`, "a world-space menu of plain entities") runs a menu of a button with a
hover glow, a toggle with a tick, a slider with a knob and a disabled card, next to a screen-space Button.

## Tooltips

A tooltip is a small box with a title and lines that shows beside the pointer after it rests on something. The engine
keeps the timer, the placement and the drawing; the game says what it says.

```json
{ "id": "buy", "components": { "Button": { "text": "Buy", "tooltip": { "title": "tip.buy.title", "lines": ["tip.buy.cost"], "args": { "cost": 12 } } } } }
```

- **Content.** A string (one line), or `{ "title": text, "lines": [text | {"text", "color"}], "args": {...} }`. Every text
  is a localization key when localization is on and the current language has that key (`args` fills its `{placeholders}`;
  the box follows a language change while it shows), and plain text otherwise. Empty lines are skipped.
- **Where it can be set.** The `tooltip` field of any widget or Panel. The pointer's widget is the topmost one
  (`ui.widgetAt`); if it has no tooltip, its nearest ancestor with one is used, so a tooltip on a Panel covers its children.
  A Panel that draws nothing (alpha 0, no texture) is not hit, so it shows none. `Text` is not hit either: put the tooltip on
  a Panel around it, or use `ui.setWorldTooltip`.
- **From a script.** `ui.setTooltip(entity, () => ({ title: "Wheat", lines: [`${n} in stock`] }))` calls the function
  when the pointer has rested for the delay and again every frame while the box shows, so the numbers stay current;
  returning `null` shows nothing. `ui.setTooltip(entity, content)` writes the field, `ui.setTooltip(entity, null)` clears
  it. `ui.setWorldTooltip((x, y) => content | null)` is asked when the pointer rests over no widget. Registrations end
  with the scene. A game that pauses its scripts returns null from its functions while paused.
- **Not a widget.** `ui.showTooltip(content, { x, y })` shows at once, at `x, y` in design pixels (default the pointer),
  and stays until `ui.hideTooltip()`, a pointer move of more than 5 pixels, or a scene load.
- **When.** After `ui.tooltipDelay` seconds of rest (default 0.5; the pointer may drift 5 pixels), counted with the UI
  clock, not wall time. Moving farther, reaching another target, pressing the pointer button or loading a scene hides it. On
  a phone it stays off until the last input was not a touch, unless `"tooltipOnTouch": true`.
- **Placement.** Down and right of the pointer by `gap`; if that crosses the screen edge (4 pixels margin) it flips to the
  other side of the pointer, and in the end it is clamped inside the screen.
- **Theme**, in `factoria.json`:

```json
"ui": {
  "tooltipDelay": 0.4,
  "tooltipOnTouch": false,
  "tooltip": { "color": [0.03, 0.04, 0.07, 0.96], "textColor": [0.92, 0.94, 0.98, 1], "titleColor": [1, 0.82, 0.3, 1],
               "font": "assets/fonts/ui.ttf", "fontSize": 18, "titleSize": 20, "maxWidth": 300, "spacing": 3,
               "padding": [10, 8, 10, 8], "gap": 16, "layer": 1000, "texture": "assets/ui/tip.png", "slice": [8, 8, 8, 8] }
}
```

  Sizes are UI units, so `ui.scale` and `ui.textScale` apply. A line longer than `maxWidth` wraps. `layer` is the draw
  order (1000: above every widget). An unknown key or a wrong type is an error that names the key and what it accepts.
- **Tests.** `ui.tooltip` is `null` or `{ title, lines, rect, source, widget }` (`source` is `"widget"`, `"script"`,
  `"world"` or `"manual"`; `rect` is `[x, y, w, h]` in screen pixels). Move the pointer with `ui.setPointer(x, y)`,
  `game.step` past `ui.tooltipDelay`, and assert. `ui.check_layout` reports a `tooltip` issue for a visible widget
  whose static tooltip is invalid or whose box is larger than the screen in some language or size.

## Drag and drop

A widget with `draggable` can be picked up with the pointer and put down on another widget or on the world (the map). The
engine does the press, the slop, the target under the pointer and the events; the game decides what a drop means.

```json
{ "id": "worker_3", "components": { "Button": { "text": "#3", "draggable": { "payload": { "worker": 3 }, "slop": 6 } } } }
```

```js
ui.setDropTarget("farm_slot", (d) => canWork(d.payload.worker));   // true, false or a function; null removes the rule
ui.on("dragStart", (e) => ui.setDragImage("drag_chip"));            // the chip follows the pointer
ui.on("drop", (e) => assign(e.payload.worker, e.target ? e.target.id : mapCellAt(e.x, e.y)));
ui.on("dragCancel", (e) => hideChip());                             // e.reason: "rejected" | "cancel" | "gone" | "script"
```

- **Starting.** `draggable` is `true` or `{ "payload": any JSON, "slop": pixels }` (slop 0 to 100, default 6). A press on
  the widget, or on a child that is not draggable itself, followed by a move of `slop` pixels starts the drag: `dragStart`.
  A press released before that is an ordinary click. A Slider or a TextField under the press keeps the pointer for itself.
  When the drag starts the press is dropped, so the release makes no `click` and flips no Toggle, and a tooltip hides.
- **Events** (`ui.on`): `dragStart`, `dragOver` (the pointer moved, or the thing under it or whether it accepts changed:
  once per frame at most), `drop` and `dragCancel`. Each has `id` / `entity` / `source` (the dragged widget), `payload`,
  `x`, `y` (the pointer, design pixels), `target` (an Entity, or `null` over the world) and `accepts`; `dragCancel` also has
  `reason`. `ui.on("drop", widget, fn)` filters by the drop target, the other three by the dragged widget.
- **Targets.** The target is the topmost widget under the pointer (`ui.widgetAt`, the drag image left out), moved up to the
  nearest ancestor that has a rule when one does. A rule is set with `ui.setDropTarget(widget, true | false | fn | null)`;
  a function gets `{ source, payload, x, y }` every frame the drag is over the widget, so it can also colour the target. A
  widget with no rule refuses. The world (no widget under the pointer) accepts, unless `ui.setWorldDropTarget(false | fn)`
  says otherwise. Rules end with the scene.
- **Ending.** Releasing the button over a target that accepts sends `drop`. Anywhere else it sends `dragCancel` with
  `reason: "rejected"`. `ui_cancel` (Escape, the pad's B) cancels with `"cancel"` and then does not send `ui.cancel`;
  `ui.cancelDrag()` with `"script"`; a source that is destroyed or deactivated with `"gone"`. A scene load ends a drag
  silently. After a `drop` or `dragCancel` the mouse button is still down for a while: nothing else reacts to it.
- **The image.** `ui.setDragImage(widget)` (call it from `dragStart`) keeps that widget's centre under the pointer; it
  is ignored by hover and by `widgetAt`. The engine only moves it: show it in `dragStart`, hide it in `drop` and
  `dragCancel`. It moves the widget's own `position`, so keep it free of a layout parent.
- **Reading it.** `ui.dragging` is `null`, or `{ source, payload, from: {x, y}, x, y, target, accepts }`. A script that
  reads the mouse for the map skips while `ui.dragging` is set, and a press that began on the UI is already ignored by
  `ui.pointerOverUi`.
- **Gamepad and tests.** A drag follows the UI pointer, so a gamepad cursor drags by holding `ui.setPointer(x, y,
  { down: true })` and moving it, and a touch drags like the mouse. `game.drag(from, to)` presses on a position or
  widget, moves to the other in four frames and releases: `game.drag("worker_3", "farm_slot")`, or a position such as
  `{ x: 640, y: 650 }` for a drop over the world. A press-and-click mode for players who cannot hold a button is the
  game's own (two clicks); the engine's drag needs the held button.

## Charts

A `Chart` draws numbers as bars or lines inside its rectangle. It is a widget like a Panel: placed by `size`, `anchor`,
`pivot` and `layer`, with `color` as the background, a `tooltip` of its own, and a child of a Panel or a ScrollList like
the others. The UI layer draws all its bars or lines in one batch, so a chart of hundreds of samples costs one draw call
more than its background.

```json
{ "id": "coins_chart", "components": { "Chart": { "size": [540, 110], "kind": "line", "colors": ["#ffd166"], "includeBaseline": false } } }
```

```js
const chart = world.find("coins_chart").get("Chart");
chart.values = history;                                  // [3, 5, 2, ...] or [[3, 5], [1, 4]] for two series
ui.on("chartHover", "coins_chart", (e) => {              // e.index: -1 when the pointer left the chart
  if (e.index >= 0) ui.showTooltip({ title: `Day ${e.index + 1}`, lines: [String(e.value)] });
  else ui.hideTooltip();
});
```

- **Data.** `values` is an array of numbers (one series) or an array of arrays (a series each, oldest value first). A
  value that is not a number counts as 0. Write a whole new array when the data changes; the chart redraws every frame.
- **Kinds.** `bar` (default) gives each sample a column, the series side by side in it, each bar growing from `baseline`
  with `barGap` empty between columns; a bar is at least one unit tall. `line` draws one polyline per series through its
  points, spanning the plot edge to edge with `lineWidth`.
- **The axis.** Automatic: the lowest and highest value, always including `baseline` (0 unless you set it), so bars scale to
  the maximum and start at zero. `includeBaseline: false` fits the data tightly (a line of coins that stays near 5000),
  `min` and `max` fix a side. The maximum and minimum are written in the plot's top-left and bottom-left corners (`showLabels`,
  `decimals`, `font`, `fontSize`, `textColor`) in the current language's number format: "1,234.5" in English, "1.234,5" in
  Spanish. The rule at `baseline` is `showBaseline`; `marks` is a list of sample indexes that get a thin vertical rule (the
  first day of a season).
- **Slots.** A series shorter than `slots` is right-aligned: a chart that fills over time keeps each sample's width, the
  empty room is on the left. With `slots` 0 the plot has room for the longest series.
- **Hover.** The pointer over the plot is reported as the sample under it: for bars the column (and the bar of it, in
  `series`), for lines the point closest horizontally (and the closest series vertically). `ui.on("chartHover", fn)` (or
  `ui.on("chartHover", chart, fn)` for one chart) gets `{ id, entity, index, series, value }` each time that sample changes
  and `index` and `series` -1, no `value`, when the pointer leaves the plot or the chart. `Chart.hoverIndex` and `hoverSeries`
  hold the same. A chart is not focusable, but it counts as a widget for `ui.pointerOverUi` and `ui.widgetAt`, so a click on
  it does not reach the world. `game.mouseMove([x, y])` and one `game.step()` hover it in a test; a chart is also listed in
  `ui.state` as kind `Chart`.

## A camera inside the UI

A `CameraView` draws a `Camera` inside its rectangle: an item turning on a stage in an inventory, a character portrait, a
minimap of a 3D level, a small second view of the world. It is a widget like a Panel (`size`, `anchor`, `pivot`, `layer`,
`color` as the background, a child of a Panel or a ScrollList), so the picture is clipped by a ScrollList and is covered by
a modal Panel or a Button with a higher layer, with no hole to leave in the page. The camera is drawn into an image the size of the rectangle (so its aspect follows the
rectangle, whatever `Camera.viewport` says), before the frame's UI, and the UI then draws that image in the rectangle at
`layer` + 1 (the background is at `layer`: a widget meant to sit on the picture needs a layer of at least `layer` + 2).

```json
{ "id": "item_stage", "components": {
    "Transform": { "position": [0, 300, 4] },
    "Camera": { "projection": "perspective", "fov": 35, "primary": false, "lighting": "studio", "clearColor": [0.09, 0.1, 0.15, 1] } } }
{ "id": "item_view", "components": {
    "CameraView": { "camera": "item_stage", "size": [400, 360], "layer": 305 } } }
```

```js
const spin = { yaw: 0 };
ui.on("viewPointer", "item_view", (e) => {               // e.phase: "down" | "drag" | "up" | "wheel"
  if (e.phase === "drag") spin.yaw += e.dx * 0.7;        // e.dx, e.dy: pixels moved since the last event
  if (e.phase === "wheel") zoom = Math.min(1.5, Math.max(0.45, zoom - e.wheel * 0.1));
});
```

- **The camera.** `CameraView.camera` is an entity id (or a name). Give that Camera `primary: false`: a primary one also draws
  in the main view. The camera and the widget both have to be active. A camera that is missing, inactive or not yet made draws
  only the widget's `color` (the script may spawn it a frame later); nothing is logged. The same camera can be shown by several
  views, each with its own image.
- **Studio lighting.** `Camera.lighting: "studio"` ignores the scene's `Light`s, ambient, sky and fog and lights what the camera
  sees with its own key, fill and rim lights (fixed directions relative to the camera) and a soft ambient, so a model looks
  the same on a stage far from the level or in the middle of a bright scene. `Camera.studioIntensity` (default 1) scales the
  rig. Add `emissive` to a part if it should glow. `lighting: "scene"` (default) uses the scene's lights, as any camera does.
- **Pointer.** A press over the view, a move while it is held and the release send the game event `ui.viewPointer`
  (`ui.on("viewPointer", fn)`, or with a target `ui.on("viewPointer", "item_view", fn)`): `{ id, entity, phase, x, y, u, v, dx,
  dy, wheel }` where `x, y` is the pointer in design pixels, `u, v` its place in the view (0..1 from the top-left; outside that
  while a drag leaves the view), `dx, dy` the move since the previous event and `wheel` the notches of a "wheel" phase. The
  widget under the pointer decides: a Button above the view keeps its click, a view under a modal Panel hears nothing, a view
  clipped by a ScrollList hears only the visible part. A drag ends with the release wherever the pointer is. A finger works like
  the mouse. `pointerEvents: false` turns all of it off (the view still blocks clicks to the world). `captureWheel` (default true)
  makes the wheel over the view a "wheel" event and keeps it from `input.mouse.wheel` and from the list under it.
  The view is not focusable: keys and a pad turn what it shows from your own script (`input.axis`).
- **Cost and limits.** Every view is one more render pass of its camera per frame and one image of its size (`resolution`, 1 by
  default: 0.5 for a soft, cheap picture, up to 2). The images of views that went away are freed in the same frame. A view
  draws the world its camera sees, not the UI or the `space: "screen"` items (so a CameraView cannot show another); `bloom`,
  `colorFilter` and the debug draw belong to the main frame and are not applied in it; 2D lights are read per pixel, so a view
  of a 2D scene with many lights costs more than the main frame does; a studio camera draws no sky. Only a camera can be shown, not a
  texture. To put a camera's live picture on a `Panel.texture` or a `Button.icon` instead, give that camera a
  `Camera.renderTarget` and use `"target:<name>"` there (docs/RENDERING.md, "Render targets"): the widget shows the picture and
  forwards no pointer input to the world behind it, so use a CameraView when the player has to drag what the camera shows.
- **Test.** `game.mouseMove`, `game.mouseDown`, `game.wheel` and `game.touchStart` over the rectangle send the events; a
  render test compares pixels of the view (the engine's own tests do this with a cube on a stage).

## A studio intro: a video that any button skips

A game that opens with a logo film uses a `Video` component and a few lines of script. It is not part of the kit (the
film is yours); Clockwork Courier's `scenes/intro.scene.json` and `scripts/intro.js` are this recipe running.

1. **The file.** An MPEG-1 video with MP2 sound in a `.mpg` (that is the only format the engine decodes; a clip of a few
   seconds at 640x360 is well under a megabyte). Bring any other video with
   `factoria call assets.import '{"source":"C:/art/logo.mp4"}'`: it converts the file with ffmpeg (`factoria setup ffmpeg`
   installs one) into `assets/video/logo.mpg`, scales it down to at most 1280 pixels wide, and records where it came from.
2. **The scene.** A camera, a `Video` that fills the screen (`anchor` and `pivot` at the centre, `size` the design size,
   `fit: "contain"` keeps the picture's shape and shows `color` in the bars), and an entity with the script. A visible
   Skip button helps touch players; any tap, key or pad button skips too.
3. **The script.** It loads the next scene when the video ends or when the player presses anything.

```json
{
  "format": "factoria.scene/1",
  "entities": [
    { "id": "camera", "components": { "Transform": { "position": [640, 360, 0] }, "Camera": { "clearColor": [0, 0, 0, 1] } } },
    { "id": "intro_video",
      "components": {
        "Video": { "path": "assets/video/logo.mpg", "size": [1280, 720], "anchor": [0.5, 0.5], "pivot": [0.5, 0.5],
                   "fit": "contain", "color": [0, 0, 0, 1], "bus": "sfx" } } },
    { "id": "intro", "components": { "Script": { "path": "scripts/intro.js" } } }
  ]
}
```

```js
// @ts-check
// scripts/intro.js: plays scenes/intro.scene.json (the Video plays by itself: autoplay is on) and goes to the menu when
// the video ends or the player presses anything.
import { Behaviour, scene, input, world } from "factoria";

const SCENE = "scenes/intro.scene.json";
const NEXT = "scenes/menu.scene.json";

export default class Intro extends Behaviour {
  onStart() {
    this.frames = 0;
    this.left = false;
    // "ended" comes once, when the video reaches its end (never for a Video with loop on).
    this.offEnded = world.find("intro_video")?.video.on("ended", () => this.leave());
    // Android Back skips the intro instead of quitting the game in the middle of it.
    this.offBack = input.onBack(() => {
      this.leave();
      return true;
    });
  }

  onDestroy() {
    this.offEnded?.();
    this.offBack?.();
  }

  /** Loads the next scene once, and only while this intro is the scene that is playing. */
  leave() {
    if (this.left || scene.current !== SCENE) return;
    this.left = true;
    scene.load(NEXT);
  }

  onUpdate() {
    // Any key, tap, click or pad button. The first frame is skipped: the press that started the game must not skip the film.
    if (this.frames > 0 && input.lastPressed()) this.leave();
    this.frames += 1;
  }
}
```

- **Once.** To show the intro only on the first launch, `storage.set("introSeen", true)` in `onStart` and call
  `scene.load(NEXT)` at once when `storage.get("introSeen", false)` is true (Clockwork Courier does).
- **The check on `scene.current`.** The `ended` event and a press can come in the same frame, or after another script
  moved to a different scene; `leave()` only acts while this intro is still the current scene, so a late answer never
  loads the menu over a level.
- **Time is the game clock.** The film pauses with the game (`time.scale` 0), and a headless test steps it with
  `game.step`: `game.step(60 * 6)` plays a five-second film to its end, which is how a test checks that the
  intro ends. `video.time`, `video.duration`, `video.playing` and `video.ended` are readable; `video.seek(s)`,
  `video.pause()`, `video.play()` and `video.stop()` control it ([SCRIPTING.md](SCRIPTING.md), `entity.video`).
- **A video with no sound** works (the file just has no audio track); `factoria validate` reports a `.mpg` the engine
  cannot play (a different codec inside the file, or not an MPEG file) with the ffmpeg command that fixes it.

## Manual check: hear the speech

Tests cannot hear anything, so once per system run the game (`factoria run <project>` or the exported game), open
Options > Audio, turn "Read menus aloud" on (you hear "Read menus aloud"), go back and move the focus with the arrows or
the pad: each widget is said. Change the language in Options > Language and move again: the voice should follow it when
the system has a voice for that language (otherwise the default voice reads it, possibly with the wrong accent).

- **Windows.** Needs nothing: SAPI 5 voices are part of Windows (Settings > Time & language > Speech lists them; add a
  language's voice there). The voice is chosen by the language's locale.
- **macOS.** Nothing to install; extra voices are in System Settings > Accessibility > Spoken Content > System voice.
- **Linux.** Install speech-dispatcher and a speech engine (`sudo apt install speech-dispatcher espeak-ng`; the game
  loads `libspeechd.so.2` when it first speaks) and start the dispatcher (`spd-say hello` must be audible). Without
  them `ui.speechAvailable` is false and the first `ui.speak` logs one warning.
- **Android.** Needs a speech engine (Google Speech Services is on most phones; Settings > System > Languages & input >
  Text-to-speech output). The first line spoken right after the game starts is kept until the engine is ready.
- **iOS.** Nothing to install; check with the device's volume up and the ringer switch in both positions.
- **Web.** Open the exported page in a browser and click or press a key in it once (browsers refuse to speak before the
  player has touched the page). The voices are the browser's.

## The files

The kit's files are not copied into this page: they are in the FactorIA install (`templates/menus/`), the same ones
`project.add_menu_kit` writes and FactorIA's own tests run, so what you read is always what the command copies.

- `docs.read {"name":"menu-kit"}` lists them with their sizes (`docs.list` names it too); on the command line
  `factoria docs read menu-kit`.
- `docs.read {"name":"menu-kit/scripts/ui/options.js"}` reads one (`factoria docs read menu-kit/scripts/ui/options.js`);
  a long file comes in parts like any page (`startLine`, `maxLines`). `kit.json` says which files make each part.
- A game that changes a file adds the part with `project.add_menu_kit` and edits its copy; it never needs to paste a
  file from here.

Two files are not part of the kit. They belong to the demo of FactorIA's tests (the menus project
`tools/cli/tests/fixtures/menus` in the repository, which holds a copy of every kit file too), and a test keeps their
text here equal to the demo's. The scene is printed in a shorter layout than the canonical one `scene.format` writes.


### `scenes/name.scene.json`

```json scenes/name.scene.json
{
  "format": "factoria.scene/1",
  "entities": [
    {
      "id": "camera",
      "components": {
        "Transform": {
          "position": [640, 360, 0]
        },
        "Camera": {
          "clearColor": [0.1, 0.12, 0.18, 1]
        }
      }
    },
    {
      "id": "name_box",
      "components": {
        "Panel": {
          "anchor": [0.5, 0.5],
          "color": [0, 0, 0, 0],
          "layout": "column",
          "spacing": 14,
          "fit": true
        }
      },
      "children": [
        {
          "id": "name_title",
          "components": {
            "Text": {
              "text": "Your name",
              "key": "name.title",
              "fontSize": 40,
              "space": "screen"
            }
          }
        },
        {
          "id": "name_field",
          "components": {
            "TextField": {
              "size": [420, 56],
              "placeholder": "Name",
              "key": "name.placeholder",
              "maxLength": 12,
              "fontSize": 28,
              "autoFocus": true
            }
          }
        },
        {
          "id": "name_next",
          "components": {
            "Button": {
              "autoSize": true,
              "text": "Continue",
              "key": "name.next"
            }
          }
        }
      ]
    },
    {
      "id": "keyboard_host",
      "components": {
        "Script": {
          "path": "scripts/ui/keyboard.js"
        }
      }
    }
  ]
}
```



### `tests/keyboard.test.js`

```js tests/keyboard.test.js
import { test, expect, game } from "factoria:test";
import { input, ui } from "factoria";
import { keysFor } from "../scripts/ui/keyboard.js";

// A player with only a gamepad types a name through the on-screen keyboard (scripts/ui/keyboard.js).
const pad = game.gamepad(0);
const field = () => game.find("name_field").get("TextField");
const open = () => game.find("keyboard").activeInHierarchy;

/** Walks the d-pad to the key that shows `ch` (the keys are a grid of 10 columns) and presses A. */
function typeKey(ch, chars) {
  const target = chars.indexOf(ch);
  const at = Number(ui.focused.id.slice("osk_key_".length));
  const dx = (target % 10) - (at % 10);
  const dy = Math.floor(target / 10) - Math.floor(at / 10);
  for (let i = 0; i < Math.abs(dx); i++) pad.tap(dx > 0 ? "DpadRight" : "DpadLeft");
  for (let i = 0; i < Math.abs(dy); i++) pad.tap(dy > 0 ? "DpadDown" : "DpadUp");
  expect(ui.focused.get("Button").text).toBe(ch);
  pad.tap("A");
}

/** Moves the focus from a key down to the row of Shift, Space, Delete and Done, then along it to `id`. */
function toAction(id) {
  for (let i = 0; i < 8 && ui.focused.id.startsWith("osk_key_"); i++) pad.tap("DpadDown");
  const order = ["osk_shift", "osk_space", "osk_delete", "osk_done"];
  for (let i = 0; i < 4 && ui.focused.id !== id; i++) pad.tap(order.indexOf(id) > order.indexOf(ui.focused.id) ? "DpadRight" : "DpadLeft");
  expect(ui.focused.id).toBe(id);
}

test("the keyboard stays closed until a pad is used, then types a name with the pad alone", () => {
  game.load("scenes/name.scene.json");
  game.step(2);
  expect(ui.focused.id).toBe("name_field"); // autoFocus at the start: the last input was not a pad
  expect(open()).toBe(false);
  pad.tap("DpadDown"); // to the button ...
  pad.tap("DpadUp"); // ... and back to the field with the pad: the keyboard opens
  expect(open()).toBe(true);
  expect(ui.focused.id).toBe("osk_key_0");

  const chars = keysFor("en");
  const changes = [];
  const stop = ui.on("change", "name_field", (e) => changes.push(e.value));
  pad.tap("A"); // "a", the first key
  typeKey("m", chars);
  pad.tap("A"); // another m
  toAction("osk_shift");
  pad.tap("A"); // upper case from now on
  pad.tap("DpadUp"); // back to the keys
  typeKey("Z", chars.map((c) => c.toUpperCase()));
  expect(field().text).toBe("ammZ");
  stop();
  expect(changes).toEqual(["a", "am", "amm", "ammZ"]);

  // Done closes the keyboard, sends ui.submit like Enter, and the focus goes back to the field without reopening it.
  const submitted = [];
  ui.on("submit", "name_field", (e) => submitted.push(e.value));
  toAction("osk_done");
  pad.tap("A");
  game.step(3);
  expect(submitted).toEqual(["ammZ"]);
  expect(open()).toBe(false);
  expect(ui.focused.id).toBe("name_field");
  expect(game.find("name_next").get("Button").interactable).toBe(true); // the menu behind the keyboard is back

  // A on the field opens it again; B closes it and keeps the text.
  pad.tap("A");
  expect(open()).toBe(true);
  pad.tap("B");
  expect(open()).toBe(false);
  expect(field().text).toBe("ammZ");
});

test("the keys follow the language and the field's maxLength", () => {
  expect(keysFor("es")).toContain("ñ");
  expect(keysFor("pt-BR")).toContain("ã");
  expect(keysFor("ru")[0]).toBe("а");
  expect(keysFor("el")[0]).toBe("α");
  expect(keysFor("ar")).toEqual(keysFor("en")); // a script with no keys of its own gets the Latin ones
  game.load("scenes/name.scene.json");
  game.step(2);
  field().text = "123456789012"; // maxLength 12: full
  pad.tap("DpadDown");
  pad.tap("DpadUp");
  pad.tap("A"); // "a" does not fit
  expect(field().text).toBe("123456789012");
});

test("a platform keyboard takes the field: the on-screen keyboard stays closed", () => {
  game.load("scenes/name.scene.json");
  game.step(2);
  // The engine sets input.platformKeyboard when a native plugin (the Steam Deck's) shows its own keyboard for the focused field.
  const engineGetter = Object.getOwnPropertyDescriptor(input, "platformKeyboard");
  Object.defineProperty(input, "platformKeyboard", { get: () => true, configurable: true });
  try {
    pad.tap("DpadDown");
    pad.tap("DpadUp"); // back to the field with the pad: the platform keyboard is up, this one is not
    expect(ui.focused.id).toBe("name_field");
    expect(open()).toBe(false);
    pad.tap("A"); // A on the field asks the platform again, not this keyboard
    expect(open()).toBe(false);
  } finally {
    Object.defineProperty(input, "platformKeyboard", engineGetter);
  }
});
```
