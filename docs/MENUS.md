# Game menus: main menu, options, credits, loading screen, pause

New projects start with a camera and nothing else. When a game needs menus, the files below give it the usual set in a
few steps: a main menu, options (video, a colour filter for colour-blind players, audio per bus, controls, language), credits that list the software inside
the runtime, a loading screen and a pause menu. Everything works with only a keyboard, only a mouse or only a gamepad,
and the player's settings are saved between runs.

FactorIA's own tests run exactly these files, driven with gamepad presses only. The kit lives in the FactorIA install
as `templates/menus/` (it is not a project template: `factoria new` does not list it), and one command copies the parts
a game wants and merges their texts into its string tables. The widgets and `ui` events the files use are in the AI guide
(section 9.22) and in `factoria docs read components` (`Panel`, `Button`, `Toggle`, `Slider`, `ScrollList`).

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
5. **Loading screen.** `scenes/loading.scene.json` and `scripts/loading.js`.
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
   Text and widget the scenes and prefabs write (below; [LOCALIZATION.md](LOCALIZATION.md)). The scripts take their
   texts from the tables (`i18n.t`), so a game with one language keeps the section with that language and
   `locales/en.json`: `"localization": { "defaultLanguage": "en", "languages": ["en"] }`.
12. **Check.** `factoria call scene.format '{"paths":["scenes","prefabs"]}'` (the files below are written short; it rewrites them in the canonical
   layout), `factoria validate`, a screenshot of the menu (`factoria run --headless --frames 3 --screenshot-at 2`),
   and a test that drives the menus with the pad, such as `tests/recipe.test.js` and `tests/keyboard.test.js` at the end. `ui.state` lists every
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
- **Loading screen.** `scene.load` blocks the frame it runs in, so the loading scene first reads the next scene's files
  ahead with `scene.preload(session.nextScene)`, a few files per frame, and shows `job.progress` (0..1) while it runs; when
  the Promise resolves the `scene.load` that follows reads nothing from the disk (`session` outlives scene loads).
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
  each platform reads). The engine applies none of them. `settings.js` starts its options from them for a player who
  never chose: text size from `textScale` (`ui.textScale`), `reducedEffects` from `reduceMotion` (your screen shake, flashes
  and particles check it), "Read menus aloud" from `screenReader`. The first `save()` stores every setting, so the
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
  (Russian, Ukrainian, Bulgarian, Serbian, Macedonian) and Greek. Every other language (Arabic, Hebrew, Chinese,
  Japanese, Korean, Thai, Hindi...) gets the **Latin keys**: a pad cannot compose those scripts, so on a PC or phone the
  player uses the system keyboard and IME, and a game that must take a name in such a script on a pad adds a layout:
  `LAYOUTS.ja = "..."` and `SCRIPT_OF.ja = "ja"` (one character per key, lower case first). The labels of Space,
  Delete and Done are the strings `keyboard.space`, `keyboard.delete` and `keyboard.done` of the locale tables.
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

The files are listed in "The files" below. `tests/slots.test.js` builds its own scene, so it passes in any game with the part.

## Text speed

`{"parts":["textSpeed"]}` (or the whole kit) adds a "Text speed" button to the Options Audio tab: slow, normal, fast and instant
(`TEXT_SPEEDS` in `scripts/settings.js`), kept as `settings.load().textSpeed` in characters per second (0 = a whole line at once; the
default is 45, or 0 when the system asks to reduce motion). The kit does not draw dialogue lines: the game's dialogue box sets
`Text.visibleCharacters = settings.revealedCharacters(secondsSinceTheLineAppeared)`. For any other row of the game, call
`addOptionsRow("audio", { id, text, click })` of `scripts/ui/options.js` before the panel is spawned (its comment says how).

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

- **Modal.** The card's backdrop Panel has `modal: true` (`Panel.modal`, see `factoria docs read components`): while it is
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
  of a 2D scene with many lights costs more than the main frame does; a studio camera draws no sky. Only a named camera can be
  shown: a render texture as the source does not exist yet.
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

Each block is a file of the kit (`templates/menus/`) or, for the demo scene `scenes/name.scene.json`, the locale
entries of the demo and the tests other than `tests/recipe.test.js`, a file of the tested menus project
(`tools/cli/tests/fixtures/menus`, which holds a copy of every kit file). A test of FactorIA keeps the blocks, the kit
and that project the same. Scenes and prefabs are printed in a shorter layout than the canonical one `scene.format`
writes.

### `scripts/settings.js`

```js scripts/settings.js
// @ts-check
// The player's settings (volumes, video, interface size, colour filter, controls, language), kept in storage under "settings" and applied once per run.
// scripts/ui/options.js edits them; main_menu.js and pause_menu.js call applyOnce() when their scene starts.
import { storage, audio, window, input, session, i18n, world, ui, game } from "factoria";

/** Audio buses the options menu shows, in order. */
export const BUSES = ["master", "music", "sfx", "ui"];

/**
 * Speeds of the dialogue text, in characters per second (0 = a whole line at once): the choices of the options "Text speed" row
 * (project.add_menu_kit with textSpeed: true) and the locale name `options.speed.<name>`. settings.load().textSpeed is the chosen
 * speed; the game's dialogue box reveals a line with Text.visibleCharacters = revealedCharacters(seconds).
 */
export const TEXT_SPEEDS = [
  { name: "slow", cps: 20 },
  { name: "normal", cps: 45 },
  { name: "fast", cps: 90 },
  { name: "instant", cps: 0 },
];

/** Values of Camera.colorFilter the options menu cycles through (accessibility: the last post-process of the frame). */
export const COLOR_FILTERS = ["none", "greyscale", "highContrast", "protanopia", "deuteranopia", "tritanopia"];

/**
 * What a player who never chose gets. The accessibility ones start from the system's settings (game.accessibility): they
 * follow the system on every run until the player saves their own choice (save() stores all the settings), which then wins.
 */
function defaults() {
  const system = game.accessibility;
  return {
    volume: { master: 1, music: 0.6, sfx: 1, ui: 1 },
    windowMode: null, // "windowed" | "borderless" | "fullscreen", or null: keep factoria.json display.fullscreen
    monitor: null, // { index, name } of the monitor the player chose (see monitorChoice), or null: where the OS opens the window
    resolution: null, // [width, height] of the window, or null: the factoria.json size
    vsync: null, // null: keep factoria.json display.vsync
    frameCap: 0, // 0 = no cap
    colorFilter: "none", // one of COLOR_FILTERS
    bindings: {}, // action -> binding names, only for actions the player rebound
    playerBindings: {}, // player ("0"."3") -> input.player(i).export(), only for a game with several local players (options.js `players`)
    language: null, // null: the language the game started in (the player's system language, else the default one)
    readAloud: system.screenReader, // say the focused menu widget with text to speech (scripts/ui/read_aloud.js)
    textScale: system.textScale, // the text size, 1 = 100 % (ui.textScale)
    uiScale: null, // the interface size (ui.scale), or null: keep the factoria.json ui.scale
    reducedEffects: system.reduceMotion, // less screen shake, flashes and particles: the effects code checks it
    subtitles: true, // show captions (the "captions" entity, a Captions component); off = that entity is inactive
    textSpeed: system.reduceMotion ? 0 : 45, // dialogue text reveal in characters per second (TEXT_SPEEDS), 0 = a whole line at once
  };
}

/** The saved settings merged over the defaults (a fresh object each call). */
export function load() {
  const saved = storage.get("settings", {});
  if (saved.windowMode === undefined && typeof saved.fullscreen === "boolean") saved.windowMode = saved.fullscreen ? "fullscreen" : "windowed"; // saved by an older kit
  const base = defaults();
  return { ...base, ...saved, volume: { ...base.volume, ...saved.volume }, bindings: { ...saved.bindings }, playerBindings: { ...saved.playerBindings } };
}

/** The value for Text.visibleCharacters of a dialogue line `seconds` after it appeared, at the player's text speed: -1 (everything) when the speed is 0. */
export function revealedCharacters(seconds, s = load()) {
  return s.textSpeed > 0 ? Math.floor(seconds * s.textSpeed) : -1;
}

export function save(s) {
  storage.set("settings", s);
}

/** What save() stores for the monitor `index` of window.monitors(): its name too, because the numbers change when a monitor is unplugged. */
export function monitorChoice(index) {
  return { index, name: window.monitors()[index]?.name ?? "" };
}

/** The index in window.monitors() of the monitor the player chose: the same name (the same place when several share it), or -1 when it is not connected now. */
function savedMonitorIndex(choice) {
  const same = window.monitors().filter((m) => m.name === choice.name);
  return same.length ? (same.find((m) => m.index === choice.index) ?? same[0]).index : -1;
}

/** Camera.colorFilter of the scene's camera (the entity with the id "camera"): every scene has its own camera, so each scene sets it again. */
export function applyColorFilter(s = load()) {
  const camera = world.find("camera");
  if (camera) camera.get("Camera").colorFilter = s.colorFilter;
}

/** Captions follow the "Subtitles" option by switching the scene's "captions" entity on or off. The game keeps calling audio.play({ caption }) and ui.caption(): they are tracked while hidden. */
export function applySubtitles(s = load()) {
  const captions = world.find("captions");
  if (captions) captions.active = s.subtitles;
}

/** What belongs to the scene's own entities (camera, captions): every scene has new ones, so each scene sets them again. */
export function applyScene(s = load()) {
  applyColorFilter(s);
  applySubtitles(s);
}

/** Puts `s` into effect: bus volumes, colour filter, subtitles, text size, interface size, language, rebound controls and, when the game has a real window, the video settings. */
export function apply(s = load()) {
  for (const bus of BUSES) audio.setVolume(bus, s.volume[bus]);
  applyScene(s);
  ui.textScale = s.textScale;
  if (s.uiScale !== null) ui.scale = s.uiScale;
  if (s.language && s.language !== i18n.language) {
    try {
      i18n.setLanguage(s.language); // rewrites every Text and widget with a key at once
    } catch (e) {
      console.warn(`settings: the saved language was ignored: ${e.message}`);
    }
  }
  for (const [action, list] of Object.entries(s.bindings)) {
    try {
      input.rebind(action, list);
    } catch (e) {
      console.warn(`settings: the saved controls of "${action}" were ignored: ${e.message}`);
    }
  }
  for (const [player, rebound] of Object.entries(s.playerBindings)) {
    const index = Number(player);
    if (!Number.isInteger(index) || index < 0 || index > 3) continue;
    for (const problem of input.player(index).import(rebound)) console.warn(`settings: the saved controls of player ${index + 1}: ${problem}`);
  }
  if (!window.available) return; // headless runs and tests have no window
  const tryApply = (what, fn) => {
    try {
      fn();
    } catch (e) {
      console.warn(`settings: ${what} was not applied: ${e.message}`);
    }
  };
  // The monitor first: a full screen or borderless window covers the monitor it is on when it switches.
  if (s.monitor && window.supports("monitors")) {
    const index = savedMonitorIndex(s.monitor);
    if (index >= 0 && index !== window.monitor) tryApply("monitor", () => window.setMonitor(index));
  }
  if (s.windowMode !== null) {
    const mode = s.windowMode === "borderless" && !window.supports("borderless") ? "fullscreen" : s.windowMode;
    tryApply("window mode", () => window.setMode(mode));
  }
  if (s.resolution && !window.fullscreen) tryApply("window size", () => window.setSize(s.resolution[0], s.resolution[1]));
  if (s.vsync !== null) tryApply("vsync", () => window.setVsync(s.vsync));
  if (s.frameCap) tryApply("frame cap", () => (window.frameCap = s.frameCap));
}

/** apply() the first time it is called in a run: session values outlive scene loads (and each test starts afresh). */
export function applyOnce() {
  if (session.settingsApplied) return applyScene(); // a new scene has a new camera and new captions
  session.settingsApplied = true;
  apply();
}
```

### `scripts/ui/menu_stack.js`

```js scripts/ui/menu_stack.js
// @ts-check
// A stack of menu panels. show(id) hides the current panel and shows another one over it; back() returns to the
// previous panel and gives the focus back to the widget that had it. Panels are entities shown and hidden with `active`;
// the first widget with autoFocus in a panel that appears takes the focus by itself (docs: UI focus rules).
import { world, ui } from "factoria";

export class MenuStack {
  /** True while a panel captures input for itself (options: "press a key"): back() does nothing then. */
  static busy = false;

  /** @param {string | null} root the panel that is always there (the main menu), or null (gameplay: nothing open) */
  constructor(root) {
    MenuStack.busy = false; // a new scene builds a new stack: a flag a scene that went left on must not block the next one
    this.root = root;
    /** @type {Array<{ id: string, focus: any }>} */
    this.open = root ? [{ id: root, focus: null }] : [];
  }

  /** Id of the panel on top, or null when nothing is open. */
  get top() {
    return this.open.length ? this.open[this.open.length - 1].id : null;
  }

  /** Shows panel `id` over the current one. */
  show(id) {
    const below = this.open[this.open.length - 1];
    if (below) {
      below.focus = ui.focused;
      world.find(below.id).active = false;
    }
    this.open.push({ id, focus: null });
    world.find(id).active = true;
  }

  /** Closes the top panel (never the root). Returns false when there was nothing to close. */
  back() {
    if (MenuStack.busy || this.open.length === 0 || (this.root && this.open.length === 1)) return false;
    world.find(this.open.pop().id).active = false;
    const below = this.open[this.open.length - 1];
    if (below) {
      world.find(below.id).active = true;
      if (below.focus && below.focus.alive) ui.focus(below.focus);
    }
    return true;
  }

  /** Closes every panel but the root. */
  closeAll() {
    while (this.back());
  }
}
```

### `scenes/menu.scene.json`

```json scenes/menu.scene.json
{
  "format": "factoria.scene/1",
  "entities": [
    { "id": "camera", "components": { "Transform": { "position": [640, 360, 0] }, "Camera": { "clearColor": [0.1, 0.12, 0.18, 1] } } },
    { "id": "captions", "components": { "Transform": { "position": [0, -24, 0] }, "Captions": { "maxLines": 3, "fontSize": 30 } } },
    { "id": "main_menu",
      "components": {
        "Transform": { "position": [0, 20, 0] },
        "Panel": { "anchor": [0.5, 0.5], "color": [0, 0, 0, 0], "layout": "column", "spacing": 12, "fit": true },
        "Script": { "path": "scripts/main_menu.js" } },
      "children": [
        { "id": "title", "components": { "Text": { "text": "My Game", "key": "menu.title", "fontSize": 64, "space": "screen" } } },
        { "id": "play", "components": { "Button": { "autoSize": true, "text": "Play", "key": "menu.play", "autoFocus": true } } },
        { "id": "options_button", "components": { "Button": { "autoSize": true, "text": "Options", "key": "menu.options" } } },
        { "id": "credits_button", "components": { "Button": { "autoSize": true, "text": "Credits", "key": "menu.credits" } } },
        { "id": "shop_button", "active": false, "components": { "Button": { "autoSize": true, "text": "Shop", "key": "menu.shop" } } },
        { "id": "quit", "components": { "Button": { "autoSize": true, "text": "Quit", "key": "menu.quit" } } }
      ] },
    { "id": "options", "active": false, "prefab": "prefabs/ui/options.prefab.json" },
    { "id": "age_gate", "active": false, "prefab": "prefabs/ui/age_gate.prefab.json" },
    { "id": "analytics_consent", "active": false, "prefab": "prefabs/ui/analytics_consent.prefab.json" },
    { "id": "shop", "active": false,
      "components": {
        "Panel": { "size": [760, 520], "anchor": [0.5, 0.5], "layer": 300, "layout": "column", "spacing": 16, "padding": [24, 24, 24, 24] },
        "Script": { "path": "scripts/ui/shop.js" } },
      "children": [
        { "id": "shop_title", "components": { "Text": { "text": "Shop", "key": "shop.title", "fontSize": 40, "space": "screen", "layer": 301 } } },
        { "id": "gems_label", "components": { "Text": { "text": "Gems: 0", "fontSize": 28, "space": "screen", "layer": 301 } } },
        { "id": "buy_gems", "components": { "Button": { "autoSize": true, "text": "100 gems", "layer": 302, "autoFocus": true } } },
        { "id": "buy_remove_ads", "components": { "Button": { "autoSize": true, "text": "Remove ads", "layer": 302 } } },
        { "id": "restore", "components": { "Button": { "autoSize": true, "text": "Restore purchases", "key": "shop.restore", "layer": 302 } } },
        { "id": "shop_status", "components": { "Text": { "text": "", "fontSize": 22, "color": [0.75, 0.8, 0.9, 1], "space": "screen", "maxWidth": 700, "layer": 301 } } },
        { "id": "shop_back", "tags": ["back"], "components": { "Button": { "autoSize": true, "text": "Back", "key": "menu.back", "layer": 302 } } }
      ] },
    { "id": "credits", "active": false,
      "components": {
        "Panel": { "size": [760, 620], "anchor": [0.5, 0.5], "layer": 300, "layout": "column", "spacing": 16, "padding": [24, 24, 24, 24] },
        "Script": { "path": "scripts/ui/credits.js" } },
      "children": [
        { "id": "credits_list", "components": { "ScrollList": { "size": [712, 476], "layer": 301, "color": [0, 0, 0, 0.25], "spacing": 14, "padding": [16, 16, 16, 16] } } },
        { "id": "credits_back", "tags": ["back"], "components": { "Button": { "autoSize": true, "text": "Back", "key": "menu.back", "layer": 302, "autoFocus": true } } }
      ] }
  ]
}
```

### `scripts/main_menu.js`

A line that ends with `// @kit:<part>` belongs to that optional part: `project.add_menu_kit` leaves it out when the
part is not added and removes the marker when it is, so the game's copy has no markers.

```js scripts/main_menu.js
// @ts-check
// The title screen (scenes/menu.scene.json): Play, Options, Credits, Quit, and Shop when the shop part is in the game.
// Panels open over each other with MenuStack; a button tagged "back" or ui_cancel (Escape, gamepad B) returns to the previous panel.
import { Behaviour, ui, game, scene, session, platform } from "factoria";
import { applyOnce } from "./settings.js";
import { MenuStack } from "./ui/menu_stack.js";
import { readMenusAloud } from "./ui/read_aloud.js";
import { openAgeGate } from "./ui/age_gate.js"; // @kit:ageGate
import { openAnalyticsConsent } from "./ui/analytics_consent.js"; // @kit:analyticsConsent

export default class MainMenu extends Behaviour {
  /** Scene the Play button starts, through the loading screen. */
  firstScene = "scenes/level.scene.json";

  onStart() {
    applyOnce();
    readMenusAloud();
    this.menus = new MenuStack("main_menu");
    // The Shop button is for games with in-app purchases: it appears when this run has a store (docs/PLATFORM.md).  // @kit:shop
    if (platform.has("purchases")) this.world.find("shop_button").active = true; // @kit:shop
    if (game.platform === "ios" || game.platform === "android") this.world.find("quit").active = false; // mobile apps do not quit themselves
    // A game for children and adults (platform.ads.audience "mixed") asks the birth year once, before any ad (docs/MENUS.md).  // @kit:ageGate
    if (platform.ads.audience === "mixed") openAgeGate(this.menus); // @kit:ageGate
    // A game with an "analytics" section in factoria.json asks once whether it may count usage; nothing is sent before the answer (docs/ANALYTICS.md).  // @kit:analyticsConsent
    else openAnalyticsConsent(this.menus); // @kit:analyticsConsent
    ui.on("click", "play", () => {
      session.nextScene = this.firstScene; // scenes/loading.scene.json shows the progress of reading it, then loads it
      scene.load("scenes/loading.scene.json");
    });
    ui.on("click", "options_button", () => this.menus.show("options"));
    ui.on("click", "credits_button", () => this.menus.show("credits"));
    ui.on("click", "shop_button", () => this.menus.show("shop")); // @kit:shop
    ui.on("click", "quit", () => game.quit());
    ui.on("click", (e) => e.entity.hasTag("back") && this.menus.back());
    ui.on("cancel", () => this.menus.back());
  }
}
```

### `scripts/ui/read_aloud.js`

Reads the focused widget aloud when the player turned on "Read menus aloud" (Options > Audio). It is the recipe for
text to speech in a menu: the engine sends `ui.focus` whenever the focus moves, and `ui.speak` says a line with the
system's voice for the game's current language. `main_menu.js` and `pause_menu.js` call `readMenusAloud()` once. The
option is hidden where `ui.speechAvailable` is false (Linux without speech-dispatcher, Android without a speech engine).

```js scripts/ui/read_aloud.js
// @ts-check
// "Read menus aloud": when the player turned the option on (Options > Audio), the widget that takes focus is said with
// the system's text to speech, in the game's language. The behaviours of the menus call readMenusAloud() once.
import { ui, i18n } from "factoria";
import * as settings from "../settings.js";

/** What to say for a focused widget (its text, already localized by the engine, plus its state), or "" for none. */
export function describe(entity) {
  if (entity.has("Button")) return entity.get("Button").text;
  if (entity.has("Toggle")) {
    const toggle = entity.get("Toggle");
    return `${toggle.label}, ${i18n.t(toggle.value ? "options.on" : "options.off")}`;
  }
  if (entity.has("Slider")) {
    const slider = entity.get("Slider");
    const percent = Math.round(((slider.value - slider.min) / (slider.max - slider.min)) * 100);
    return `${slider.label}, ${i18n.t("options.percent", { value: percent })}`;
  }
  if (entity.has("TextField")) return entity.get("TextField").placeholder;
  return "";
}

/** Says the focused widget while the option is on; interrupts, so moving quickly never queues old lines. */
export function readMenusAloud() {
  ui.on("focus", (e) => {
    if (!settings.load().readAloud) return;
    const text = describe(e.entity);
    if (text) ui.speak(text);
  });
}
```

### `scripts/dialogue.js`

The helper the game calls for spoken lines and hints, with the captions from the string tables.

```js scripts/dialogue.js
// @ts-check
// Subtitles for spoken lines and for hints: say("captions.welcome", { sound: "assets/sfx/hello.wav", speaker: "captions.guide" })
// plays the sound with its caption, say("captions.hint") shows a caption without a sound. Lines are string-table keys, so a caption
// that is on screen changes language with the game. The "captions" entity of the scene (a Captions component) draws them; the
// Subtitles option (settings.js) switches that entity off, the calls here stay the same.
import { audio, ui, i18n } from "factoria";

/**
 * @param {string} line  localization key of the line (locales/*.json)
 * @param {{ sound?: string, speaker?: string, seconds?: number }} [options]
 *   sound: clip to play (the caption lives as long as it plays); speaker: key of the speaker's name; seconds: how long the caption
 *   shows (default: the sound's length, or 3 seconds without a sound)
 */
export function say(line, { sound, speaker, seconds } = {}) {
  const who = speaker ? i18n.t(speaker) : undefined; // the name is written when the line starts
  if (sound) return audio.play(sound, { captionKey: line, speaker: who, captionSeconds: seconds });
  ui.caption("", seconds ?? 3, { key: line, speaker: who });
  return 0;
}
```

### `scripts/ui/credits.js`

```js scripts/ui/credits.js
// @ts-check
// The credits panel: the game's own lines, then the software inside the FactorIA runtime (game.notices(), the
// parts whose licenses FACTORIA_NOTICES.txt holds next to the exported game). ui_up/ui_down scroll the list.
import { Behaviour, game, input } from "factoria";

export default class Credits extends Behaviour {
  /** String-table keys of the lines shown after the game's name (factoria.json "name") and before the engine's notices. */
  lines = ["credits.madeWith"];
  /** Scroll speed of ui_up/ui_down in pixels per second. */
  scrollSpeed = 500;

  onStart() {
    this.list = this.world.find("credits_list");
    const text = (s, fontSize = 22, color = [1, 1, 1, 1], key = "") =>
      this.world.spawn({ components: { Text: { text: s, key, fontSize, color, space: "screen", maxWidth: 680, layer: 302 } } }, { parent: this.list });
    // A Text with a key is translated by the engine, also when the player changes the language while the credits are open.
    const keyed = (key, fontSize, color) => text(key, fontSize, color, key);
    text(game.project.name, 34);
    for (const key of this.lines) keyed(key, 26);
    keyed("credits.software", 22, [0.75, 0.8, 0.9, 1]);
    for (const n of game.notices()) text(`${n.name}  (${n.license})\n${n.usedFor}\n${n.url}`, 20);
    keyed("credits.licenses", 18, [0.75, 0.8, 0.9, 1]);
  }

  onUpdate(dt) {
    if (!this.entity.active) return;
    this.list.get("ScrollList").scroll += input.axis("ui_up", "ui_down") * this.scrollSpeed * dt;
  }
}
```

### `scripts/ui/shop.js`

```js scripts/ui/shop.js
// @ts-check
// The shop panel of the main menu (scenes/menu.scene.json), shown by the Shop button when the run has a store. It sells
// the products of factoria.json "platform.products": gems (a consumable) and "Remove ads" (a non-consumable). A purchase
// is granted first and finished after: the store keeps a purchase "unfinished" and hands it over again on the next run
// until finish() is called, so a crash between the two never loses what the player paid for.
import { Behaviour, ui, platform, storage, i18n } from "factoria";

/** What the player owns, kept in storage under "wallet". `seen` holds the transactions already granted. */
function wallet() {
  return { gems: 0, noAds: false, seen: [], ...storage.get("wallet", {}) };
}

export default class Shop extends Behaviour {
  /** Gems one "gems_100" purchase gives. */
  gemsPerPack = 100;

  onStart() {
    this.busy = false; // a purchase is waiting for the store: the buttons do nothing meanwhile
    this.status = this.world.find("shop_status").get("Text");
    ui.on("click", "buy_gems", () => this.buy("gems_100"));
    ui.on("click", "buy_remove_ads", () => this.buy("remove_ads"));
    ui.on("click", "restore", () => this.restore());
    // Purchases that finish outside buy(): a parent approves an "ask to buy", or the store hands over a purchase the last run left
    // unfinished.
    platform.on("purchase", (p) => p.status === "purchased" && this.grant(p).then(() => this.say(i18n.t("shop.arrived"))));
    this.refresh();
    i18n.on("change", () => this.refresh()); // the gems line is written by this script, not translated by the engine
    // The store's own titles and prices (already formatted for the player's country) go on the buttons.
    platform.purchases.products().then((list) => {
      for (const p of list) {
        const button = this.world.find(p.id === "gems_100" ? "buy_gems" : "buy_remove_ads");
        button.get("Button").text = `${p.title} - ${p.price}`;
      }
    }, () => {});
  }

  say(message) {
    this.status.text = message;
  }

  refresh() {
    const w = wallet();
    this.world.find("gems_label").get("Text").text = i18n.t(w.noAds ? "shop.gemsNoAds" : "shop.gems", { count: w.gems });
  }

  /** Gives the player what the purchase bought, once per transaction, then tells the store it is done. */
  async grant(purchase) {
    const w = wallet();
    if (!w.seen.includes(purchase.transactionId)) {
      if (purchase.productId === "gems_100") w.gems += this.gemsPerPack;
      if (purchase.productId === "remove_ads") w.noAds = true;
      w.seen.push(purchase.transactionId);
      storage.set("wallet", w);
      this.refresh();
    }
    await platform.purchases.finish(purchase.transactionId);
  }

  async buy(productId) {
    if (this.busy) return;
    this.busy = true;
    this.say(i18n.t("shop.waiting"));
    try {
      const r = await platform.purchases.buy(productId);
      if (r.status === "purchased") {
        const finished = this.grant(r); // the wallet changes at once; telling the store it is done may take a moment
        this.say(i18n.t("shop.thanks"));
        await finished;
      } else if (r.status === "pending") {
        this.say(i18n.t("shop.pending")); // the "purchase" event grants it
      } else {
        this.say(i18n.t("shop.cancelled"));
      }
    } catch (e) {
      // e.code is "network", "unavailable", "notSignedIn"...; e.hint says what to try.
      this.say(i18n.t("shop.unreachable", { code: e.code, detail: e.hint ?? e.message }));
    } finally {
      this.busy = false;
    }
  }

  async restore() {
    if (this.busy) return;
    this.busy = true;
    this.say(i18n.t("shop.asking"));
    try {
      const w = wallet();
      for (const owned of await platform.purchases.restore()) if (owned.productId === "remove_ads") w.noAds = true;
      storage.set("wallet", w);
      this.refresh();
      this.say(i18n.t(w.noAds ? "shop.restored" : "shop.nothingToRestore"));
    } catch (e) {
      this.say(i18n.t("shop.unreachable", { code: e.code, detail: e.hint ?? e.message }));
    } finally {
      this.busy = false;
    }
  }
}
```

### `scripts/store_events.js`

```js scripts/store_events.js
// @ts-check
// Put this behaviour on one entity of every level: while the store's overlay (Steam, the App Store sheet) is open the
// game pauses, and it resumes when the overlay closes. A game the player paused itself stays paused.
import { Behaviour, game, platform } from "factoria";

export default class StoreEvents extends Behaviour {
  onStart() {
    this.pausedByOverlay = false;
    platform.on("overlay", (e) => {
      if (e.open && !game.paused) {
        game.paused = true;
        this.pausedByOverlay = true;
      } else if (!e.open && this.pausedByOverlay) {
        game.paused = false;
        this.pausedByOverlay = false;
      }
    });
  }
}
```

### `prefabs/ui/options.prefab.json`

```json prefabs/ui/options.prefab.json
{
  "format": "factoria.prefab/1",
  "entity": {
    "name": "Options",
    "components": {
      "Panel": { "size": [760, 680], "anchor": [0.5, 0.5], "layer": 300, "layout": "column", "direction": "auto", "align": "start",
        "spacing": 12, "padding": [20, 20, 20, 20] },
      "Script": { "path": "scripts/ui/options.js" }
    },
    "children": [
      { "name": "Title", "components": { "Text": { "text": "Options", "key": "options.title", "fontSize": 40, "space": "screen", "layer": 301 } } },
      { "name": "Tabs",
        "components": { "Panel": { "layer": 301, "color": [0, 0, 0, 0], "layout": "row", "direction": "auto", "padding": [0, 0, 0, 0], "fit": true } },
        "children": [
          { "id": "tab_video", "components": { "Button": { "autoSize": true, "text": "Video", "key": "options.tab.video", "size": [160, 48], "layer": 302, "autoFocus": true } } },
          { "id": "tab_audio", "components": { "Button": { "autoSize": true, "text": "Audio", "key": "options.tab.audio", "size": [160, 48], "layer": 302 } } },
          { "id": "tab_controls", "components": { "Button": { "autoSize": true, "text": "Controls", "key": "options.tab.controls", "size": [160, 48], "layer": 302 } } },
          { "id": "tab_language", "components": { "Button": { "autoSize": true, "text": "Language", "key": "options.tab.language", "size": [160, 48], "layer": 302 } } }
        ] },
      { "id": "video_section",
        "components": { "Panel": { "size": [712, 424], "layer": 301, "color": [0, 0, 0, 0.25], "layout": "column", "direction": "auto", "align": "start", "spacing": 8 } },
        "children": [
          { "id": "window_mode", "components": { "Button": { "autoSize": true, "text": "Window mode", "size": [560, 44], "layer": 302, "fontSize": 22 } } },
          { "id": "monitor", "components": { "Button": { "autoSize": true, "text": "Monitor", "size": [560, 44], "layer": 302, "fontSize": 22 } } },
          { "id": "resolution", "components": { "Button": { "autoSize": true, "text": "Window size", "size": [560, 44], "layer": 302, "fontSize": 22 } } },
          { "id": "vsync", "components": { "Toggle": { "autoSize": true, "label": "VSync", "key": "options.vsync", "size": [560, 44], "layer": 302 } } },
          { "id": "frame_cap", "components": { "Button": { "autoSize": true, "text": "Frame cap", "size": [560, 44], "layer": 302, "fontSize": 22 } } },
          { "id": "ui_scale", "components": { "Button": { "autoSize": true, "text": "Interface size", "size": [560, 44], "layer": 302, "fontSize": 22 } } },
          { "id": "color_filter", "components": { "Button": { "autoSize": true, "text": "Color filter", "size": [560, 44], "layer": 302, "fontSize": 22 } } },
          { "id": "video_note", "components": { "Text": { "text": "Video settings apply when the game runs in its own window.", "key": "options.videoNote",
            "fontSize": 18, "color": [0.75, 0.8, 0.9, 1], "space": "screen", "align": "start", "maxWidth": 560, "layer": 302 } } }
        ] },
      { "id": "audio_section",
        "components": { "Panel": { "size": [712, 392], "layer": 301, "color": [0, 0, 0, 0.25], "layout": "column", "spacing": 12 } },
        "children": [
          { "id": "master_volume", "components": { "Slider": { "autoSize": true, "label": "Master", "key": "options.volume.master", "size": [560, 44], "layer": 302 } } },
          { "id": "music_volume", "components": { "Slider": { "autoSize": true, "label": "Music", "key": "options.volume.music", "size": [560, 44], "layer": 302 } } },
          { "id": "sfx_volume", "components": { "Slider": { "autoSize": true, "label": "Effects", "key": "options.volume.effects", "size": [560, 44], "layer": 302 } } },
          { "id": "ui_volume", "components": { "Slider": { "autoSize": true, "label": "Interface", "key": "options.volume.interface", "size": [560, 44], "layer": 302 } } },
          { "id": "read_aloud", "components": { "Toggle": { "autoSize": true, "label": "Read menus aloud", "key": "options.readAloud", "size": [560, 44], "layer": 302 } } },
          { "id": "subtitles", "components": { "Toggle": { "autoSize": true, "label": "Subtitles", "key": "options.subtitles", "value": true, "size": [560, 44], "layer": 302 } } },
          { "id": "text_speed", "components": { "Button": { "autoSize": true, "text": "Text speed", "size": [560, 44], "layer": 302, "fontSize": 22 } } }
        ] },
      { "id": "controls_section",
        "components": { "Panel": { "size": [712, 340], "layer": 301, "color": [0, 0, 0, 0.25], "layout": "column", "spacing": 12 } },
        "children": [
          { "id": "bindings", "components": { "Panel": { "layer": 301, "color": [0, 0, 0, 0], "layout": "column", "padding": [0, 0, 0, 0], "fit": true } } },
          { "id": "reset_controls", "components": { "Button": { "autoSize": true, "text": "Reset to defaults", "key": "options.resetControls", "size": [560, 44], "layer": 302, "fontSize": 22 } } }
        ] },
      { "id": "language_section",
        "components": { "Panel": { "size": [712, 340], "layer": 301, "color": [0, 0, 0, 0.25], "layout": "column", "spacing": 12 } },
        "children": [
          { "id": "language", "components": { "Button": { "autoSize": true, "text": "Language: English", "size": [560, 44], "layer": 302 } } }
        ] },
      { "id": "analytics_toggle", "active": false, "components": { "Toggle": { "autoSize": true, "label": "Share anonymous usage data", "key": "options.analytics", "size": [560, 44], "layer": 302 } } },
      { "id": "privacy_options", "active": false, "components": { "Button": { "autoSize": true, "text": "Ad privacy settings", "key": "options.privacyOptions", "size": [560, 44], "layer": 302, "fontSize": 22 } } },
      { "id": "options_back", "tags": ["back"], "components": { "Button": { "autoSize": true, "text": "Back", "key": "menu.back", "layer": 302 } } }
    ]
  }
}
```

### `scripts/ui/options.js`

```js scripts/ui/options.js
// @ts-check
// The options panel (prefabs/ui/options.prefab.json), opened by the main menu and by the pause menu. Tabs: Video (window mode,
// monitor, size, vsync, frame cap, the interface size and the colour filter, two accessibility options that work without a window),
// Audio (one slider per bus), Controls (rebinding every action of the game; with `players` above 1, for the player you pick) and Language
// (cycles through the game's languages). Every change is applied at once and saved (scripts/settings.js), so the next run starts with it. The texts are string-table keys
// (locales/*.json): the widgets with a `key` are translated by the engine, the ones this script writes use i18n.t().
import { Behaviour, ui, input, window, audio, world, i18n, platform, analytics, screen } from "factoria";
import * as settings from "../settings.js";
import { MenuStack } from "./menu_stack.js";

const TABS = ["video", "audio", "controls", "language"];
/** Frame caps the "Frame cap" button cycles through (0 = off). */
const FRAME_CAPS = [0, 30, 60, 120, 144];
/** Interface sizes (ui.scale) the "Interface size" button cycles through; only the ones this panel still fits the screen at are offered. */
const UI_SCALES = [0.75, 1, 1.25, 1.5, 2];
const TAB_COLOR = [0.16, 0.18, 0.24, 0.92];
const TAB_SELECTED = [0.3, 0.36, 0.52, 0.96];

/** @type {Array<{ section: string, id: string, text: () => string, click: () => void }>} */
const gameRows = [];

/**
 * Adds a row of the GAME to a section of the options (a Button that the panel keeps in step with the language), without editing the
 * panel's files. Call it before the panel is spawned: when the module that owns the game's setting loads, or in the host's onStart before
 * it spawns prefabs/ui/options.prefab.json. `section` is "video", "audio", "controls" or "language". `text()` returns the label (use
 * i18n.t; it is called again when the language changes and after every click), `click()` changes the setting (save it with
 * settings.save, the panel does not know it). The section grows by one row; the panel is sized for its Video tab, so a section with more
 * rows than that needs a taller prefab. A second call with the same id replaces the row.
 *   addOptionsRow("audio", { id: "screen_shake", text: () => i18n.t("options.shake", { on: s.shake }), click: () => toggleShake() });
 * @param {string} section
 * @param {{ id: string, text: () => string, click: () => void }} row
 */
export function addOptionsRow(section, row) {
  if (!TABS.includes(section)) throw new Error(`addOptionsRow: there is no options section "${section}". The sections are ${TABS.join(", ")}.`);
  const at = gameRows.findIndex((r) => r.id === row.id);
  if (at >= 0) gameRows.splice(at, 1);
  gameRows.push({ section, ...row });
}

export default class Options extends Behaviour {
  runWhilePaused = true; // the pause menu opens it while game.paused
  /**
   * Actions the Controls tab lets the player rebind, in this order. null (the default) lists every action the game has
   * except the ui_* ones. Set it in the prefab: "Script": { "path": "scripts/ui/options.js", "props": { "actions": ["move", "dig"] } }.
   * The labels are the strings "options.action.<action>"; an action without one is labelled with its name.
   */
  actions = null;
  /**
   * Local players that rebind their own controls (docs: scripting, input.player). 1 (the default) is a game with one set of
   * bindings: the Controls tab changes the global input. Above 1 the tab gets a "Player N" button on top that cycles through the
   * players, and each rebinds the keys and the gamepad buttons of input.player(i) only; what a player rebound is saved by player
   * (settings.playerBindings) and put back by settings.apply(). Set it in the prefab: "Script": { "path": "scripts/ui/options.js", "props": { "players": 2 } }.
   */
  players = 1;

  onStart() {
    this.s = settings.load();
    this.waiting = null; // the action waiting for "press a key or button"
    this.seat = 0; // the player the Controls tab shows (only when players > 1)
    this.release = false;
    for (const tab of TABS) ui.on("click", `tab_${tab}`, () => this.showTab(tab));
    this.showTab("video");
    this.setupVideo();
    this.setupAudio();
    this.setupTextSpeed();
    this.setupControls();
    this.setupLanguage();
    this.setupPrivacy();
    this.setupGameRows();
    // The texts this script writes are not translated by the engine: write them again in the new language.
    i18n.on("change", () => {
      this.refreshVideo();
      this.refreshTextSpeed();
      this.refreshControls();
      this.refreshLanguage();
      this.refreshGameRows();
    });
  }

  showTab(name) {
    for (const tab of TABS) {
      world.find(`${tab}_section`).active = tab === name;
      world.find(`tab_${tab}`).get("Button").color = tab === name ? TAB_SELECTED : TAB_COLOR;
    }
  }

  // ------------------------------------------------------------------------------------------------------------ video
  setupVideo() {
    const s = this.s;
    const has = window.available; // false in headless runs and tests: the rows stay visible, greyed out
    world.find("video_note").active = !has;
    const vsync = world.find("vsync").get("Toggle");
    vsync.value = window.vsync;
    vsync.interactable = world.find("frame_cap").get("Button").interactable = world.find("window_mode").get("Button").interactable = has;
    // The monitor row only exists where the game can move between monitors and this computer has more than one.
    world.find("monitor").active = window.supports("monitors") && window.monitors().length > 1;
    this.refreshVideo();
    ui.on("scale", () => this.refreshVideo()); // the size changed (here, or a script): write the percentage again

    ui.on("click", "window_mode", () => {
      // windowed -> borderless -> fullscreen -> windowed (macOS cannot go from fullscreen straight to borderless); a platform without borderless skips it.
      const modes = window.supports("borderless") ? ["windowed", "borderless", "fullscreen"] : ["windowed", "fullscreen"];
      const next = modes[(modes.indexOf(window.mode) + 1) % modes.length];
      this.video("window mode", () => { window.setMode(next); s.windowMode = next; });
    });
    ui.on("click", "monitor", () => {
      const count = window.monitors().length;
      const next = (window.monitor + 1) % count;
      this.video("monitor", () => { window.setMonitor(next); s.monitor = settings.monitorChoice(next); });
    });
    ui.on("change", "vsync", (e) => this.video("vsync", () => { window.setVsync(e.value); s.vsync = e.value; }));
    ui.on("click", "resolution", () => {
      const sizes = window.resolutions();
      const now = window.size;
      const i = sizes.findIndex((r) => r.width === Math.round(now.x) && r.height === Math.round(now.y));
      const next = sizes[(i + 1) % sizes.length];
      this.video("window size", () => { window.setSize(next.width, next.height); s.resolution = [next.width, next.height]; });
    });
    ui.on("click", "frame_cap", () => {
      const next = FRAME_CAPS[(FRAME_CAPS.indexOf(window.frameCap) + 1) % FRAME_CAPS.length];
      this.video("frame cap", () => { window.frameCap = next; s.frameCap = next; });
    });
    ui.on("click", "ui_scale", () => {
      const sizes = this.uiScales();
      const next = sizes.find((k) => k > ui.scale + 1e-3) ?? sizes[0];
      ui.scale = next; // every widget of every screen, this panel included, at once (docs/TEXT.md, "Interface size")
      s.uiScale = next;
      settings.save(s);
      this.refreshVideo();
    });
    ui.on("click", "color_filter", () => {
      const all = settings.COLOR_FILTERS;
      s.colorFilter = all[(all.indexOf(s.colorFilter) + 1) % all.length];
      settings.applyColorFilter(s); // Camera.colorFilter: the whole frame, this panel included
      settings.save(s);
      this.refreshVideo();
    });
  }

  /**
   * The interface sizes to offer: the ones where this panel, drawn ui.scale times as big, still fits the screen (a bigger one
   * would leave the panel's edges and its Back button off screen), plus the size now in use, whatever it is.
   */
  uiScales() {
    const panel = this.entity.get("Panel").size; // in UI units: the size before ui.scale
    const screenSize = screen.size;
    const fits = UI_SCALES.filter((k) => panel.x * k <= screenSize.x && panel.y * k <= screenSize.y);
    if (!fits.includes(ui.scale)) fits.push(ui.scale);
    return fits.sort((a, b) => a - b);
  }

  /** Runs a window change (which also updates this.s); saves it when it worked, shows why when it did not. */
  video(what, change) {
    try {
      change();
      settings.save(this.s);
    } catch (e) {
      console.warn(`options: ${what} could not be changed: ${e.message}`);
    }
    this.refreshVideo();
  }

  refreshVideo() {
    const size = window.size;
    world.find("window_mode").get("Button").text = i18n.t("options.windowMode", { mode: i18n.t(`options.mode.${window.mode}`) });
    const monitors = window.monitors();
    world.find("monitor").get("Button").text = i18n.t("options.monitor", { n: window.monitor + 1, name: monitors[window.monitor]?.name ?? "" });
    const resolution = world.find("resolution").get("Button");
    resolution.text = window.fullscreen
      ? i18n.t("options.windowSizeFullscreen")
      : i18n.t("options.windowSize", { width: Math.round(size.x), height: Math.round(size.y) });
    resolution.interactable = window.available && !window.fullscreen; // full screen uses the display's size
    world.find("frame_cap").get("Button").text = window.frameCap
      ? i18n.t("options.frameCap", { fps: window.frameCap })
      : i18n.t("options.frameCapOff");
    const uiScale = world.find("ui_scale").get("Button");
    uiScale.text = i18n.t("options.uiScale", { percent: Math.round(ui.scale * 100) });
    uiScale.interactable = this.uiScales().length > 1; // nothing to choose when no other size fits
    world.find("color_filter").get("Button").text = i18n.t("options.colorFilter", { filter: i18n.t(`options.filter.${this.s.colorFilter}`) });
  }

  // ------------------------------------------------------------------------------------------------------------ audio
  setupAudio() {
    for (const bus of settings.BUSES) {
      world.find(`${bus}_volume`).get("Slider").value = this.s.volume[bus];
      ui.on("change", `${bus}_volume`, (e) => {
        this.s.volume[bus] = e.value;
        audio.setVolume(bus, e.value);
        settings.save(this.s);
      });
    }
    // Only where the system can speak (Linux without speech-dispatcher, Android without a speech engine: hidden).
    const readAloud = world.find("read_aloud");
    readAloud.active = ui.speechAvailable;
    readAloud.get("Toggle").value = this.s.readAloud;
    ui.on("change", "read_aloud", (e) => {
      this.s.readAloud = e.value;
      settings.save(this.s);
      if (e.value) ui.speak(readAloud.get("Toggle").label); // so the player hears that it works
      else ui.stopSpeaking();
    });
    // Subtitles: captions are drawn by the scene's "captions" entity; the option switches it (settings.applySubtitles).
    world.find("subtitles").get("Toggle").value = this.s.subtitles;
    ui.on("change", "subtitles", (e) => {
      this.s.subtitles = e.value;
      settings.applySubtitles(this.s);
      settings.save(this.s);
    });
  }

  // ------------------------------------------------------------------------------------------------------ text speed
  /** The "Text speed" button (added with `textSpeed: true`; without it the prefab has no such row and this does nothing). */
  setupTextSpeed() {
    if (!world.find("text_speed")) return;
    ui.on("click", "text_speed", () => {
      const all = settings.TEXT_SPEEDS;
      const at = all.findIndex((x) => x.cps === this.s.textSpeed);
      this.s.textSpeed = all[(at + 1) % all.length].cps;
      settings.save(this.s);
      this.refreshTextSpeed();
    });
    this.refreshTextSpeed();
  }

  refreshTextSpeed() {
    const row = world.find("text_speed");
    if (!row) return;
    const speed = settings.TEXT_SPEEDS.find((x) => x.cps === this.s.textSpeed);
    row.get("Button").text = i18n.t("options.textSpeed", { speed: i18n.t(`options.speed.${speed ? speed.name : "custom"}`) });
  }

  // ------------------------------------------------------------------------------------------------------- game rows
  /** Builds the buttons of addOptionsRow(). */
  setupGameRows() {
    for (const row of gameRows) {
      const section = world.find(`${row.section}_section`);
      if (!section || world.find(row.id)) continue;
      world.spawn({ id: row.id, components: { Button: { text: "", size: [560, 44], fontSize: 22, layer: 302, autoSize: true } } }, { parent: section });
      const panel = section.get("Panel");
      panel.size = [panel.size.x, panel.size.y + 44 + panel.spacing];
      ui.on("click", row.id, () => {
        row.click();
        this.refreshGameRows();
      });
    }
    this.refreshGameRows();
  }

  refreshGameRows() {
    for (const row of gameRows) {
      const entity = world.find(row.id);
      if (entity) entity.get("Button").text = row.text();
    }
  }

  // --------------------------------------------------------------------------------------------------------- controls
  setupControls() {
    const list = world.find("bindings");
    this.players = Math.max(1, Math.min(4, Math.round(Number(this.players)) || 1));
    if (this.players > 1) {
      world.spawn({ id: "controls_player", components: { Button: { text: "Player 1", size: [560, 44], fontSize: 22, layer: 302 } } }, { parent: list });
      ui.on("click", "controls_player", () => {
        if (this.waiting) return;
        this.seat = (this.seat + 1) % this.players;
        this.refreshControls();
      });
    }
    const have = input.actions();
    // An action the game does not have gets no row; without a list, every action but the menus' own ui_* ones.
    this.actions = this.actions ? this.actions.filter((action) => have.includes(action)) : have.filter((action) => !action.startsWith("ui_"));
    for (const action of this.actions) {
      const button = world.spawn({ id: `bind_${action}`, components: { Button: { text: action, size: [560, 44], fontSize: 22, layer: 302 } } }, { parent: list });
      ui.on("click", button, () => {
        if (this.waiting) return; // a press while waiting is the new binding (onUpdate), not a click
        this.waiting = { action, button, since: world.frame };
        MenuStack.busy = true; // Escape cancels the rebinding instead of closing the panel
        this.refreshControls();
      });
    }
    ui.on("click", "reset_controls", () => {
      if (this.players > 1) {
        input.player(this.seat).reset(); // this player only
        delete this.s.playerBindings[String(this.seat)];
      } else {
        input.resetBindings();
        this.s.bindings = {};
      }
      settings.save(this.s);
      this.refreshControls();
    });
    this.refreshControls();
  }

  /** The translated name of an action; the action's own name when the game has no "options.action.<action>" string. */
  actionLabel(action) {
    const key = `options.action.${action}`;
    return i18n.has(key) ? i18n.t(key) : action;
  }

  /** The buttons bound to an action for one list of a player ("keys" or "pad") as the player reads them: "Space / J", or "-" for none. */
  playerButtons(action, family) {
    const player = input.player(this.seat);
    const names = player.bindings(action, family);
    return names.length ? names.map((name) => input.buttonName(name, Math.max(0, player.pad))).join(" / ") : "-";
  }

  refreshControls() {
    if (this.players > 1) world.find("controls_player").get("Button").text = i18n.t("options.player", { n: this.seat + 1 });
    for (const action of this.actions) {
      const label = this.actionLabel(action);
      const text =
        this.players > 1
          ? i18n.t("options.playerBinding", { action: label, keys: this.playerButtons(action, "keys"), pad: this.playerButtons(action, "pad") })
          : i18n.t("options.binding", { action: label, button: input.buttonName(action) });
      world.find(`bind_${action}`).get("Button").text = this.waiting?.action === action ? i18n.t("options.pressKey", { action: label }) : text;
    }
  }

  // ------------------------------------------------------------------------------------------------------- language
  setupLanguage() {
    ui.on("click", "language", () => {
      const all = i18n.languages;
      const next = all[(all.indexOf(i18n.language) + 1) % all.length];
      i18n.setLanguage(next); // every Text and widget with a key changes at once; "change" listeners run next frame
      this.s.language = next;
      settings.save(this.s);
    });
    this.refreshLanguage();
  }

  refreshLanguage() {
    const button = world.find("language").get("Button");
    button.text = i18n.t("options.language", { language: i18n.name(i18n.language) });
    button.interactable = i18n.languages.length > 1; // a game with one language has nothing to choose
  }

  // ------------------------------------------------------------------------------------------------------- privacy
  /** The "Ad privacy settings" button: only where ads exist and the consent sheet says the player must be able to change their choice. */
  setupPrivacy() {
    this.setupAnalytics();
    if (!platform.has("ads")) return;
    const button = world.find("privacy_options");
    platform.ads
      .consent()
      .then((consent) => {
        if (button.alive) button.active = consent.privacyOptions === "required"; // the panel may be gone by now
      })
      .catch((e) => console.warn(`options: the ad consent state could not be read: ${e.message}`));
    ui.on("click", "privacy_options", () => {
      platform.ads.privacyOptions().catch((e) => console.warn(`options: the privacy form did not open: ${e.message}`));
    });
  }

  /** The usage-data switch: only in a game whose factoria.json has an "analytics" section. It is the player's answer (analytics.setConsent); off forgets what waits to be sent. */
  setupAnalytics() {
    const row = world.find("analytics_toggle");
    row.active = analytics.configured;
    if (!analytics.configured) return;
    row.get("Toggle").value = analytics.consent() === "granted";
    ui.on("change", "analytics_toggle", (e) => row.alive && analytics.setConsent(e.value));
  }

  onUpdate() {
    if (this.release) {
      // One frame after the capture, so the menus (and the pause key) ignored the press that was captured.
      MenuStack.busy = this.release = false;
    }
    if (!this.waiting || world.frame === this.waiting.since) return; // skip the press that clicked the button
    const pressed = input.lastPressed();
    if (!pressed) return;
    const { action, button } = this.waiting;
    this.waiting = null;
    this.release = true;
    if (pressed !== "Escape" && this.players > 1) {
      // A key or a chord (Ctrl+Z) replaces the keyboard list of the action for this player and a gamepad button or stick replaces its gamepad list; the
      // mouse and touch (also in a chord) belong to every player, so they are not bindings. The engine refuses a name the player's key scheme does not have.
      const player = input.player(this.seat);
      if (!/(^|\+)(Mouse|Touch)/.test(pressed)) {
        try {
          player.rebind(action, [pressed], pressed.startsWith("Gamepad") ? "pad" : "keys");
          this.s.playerBindings[String(this.seat)] = player.export();
          settings.save(this.s);
        } catch (e) {
          console.warn(`options: ${pressed} was not taken as a binding: ${e.message}`);
        }
      }
    } else if (pressed !== "Escape") {
      // Replace the bindings of the device that was pressed and keep the other device's: rebinding the keyboard
      // does not take the gamepad's buttons away.
      const pad = (b) => b.startsWith("Gamepad");
      const keep = input.bindings(action).filter((b) => pad(b) !== pad(pressed));
      const list = [pressed, ...keep];
      input.rebind(action, list);
      this.s.bindings[action] = list;
      settings.save(this.s);
    }
    this.refreshControls();
    ui.focus(button); // the key that was pressed may also have moved the focus
  }
}
```

### `prefabs/ui/age_gate.prefab.json`

```json prefabs/ui/age_gate.prefab.json
{
  "format": "factoria.prefab/1",
  "entity": {
    "name": "AgeGate",
    "components": {
      "Panel": {
        "size": [760, 460],
        "anchor": [0.5, 0.5],
        "layer": 300,
        "layout": "column",
        "spacing": 16,
        "padding": [24, 24, 24, 24]
      }
    },
    "children": [
      {
        "id": "age_title",
        "components": {
          "Text": { "text": "Before you play", "key": "ageGate.title", "fontSize": 40, "space": "screen", "layer": 301 }
        }
      },
      {
        "id": "age_question",
        "components": {
          "Text": {
            "text": "In which year were you born?",
            "key": "ageGate.question",
            "fontSize": 28,
            "space": "screen",
            "align": "start",
            "maxWidth": 700,
            "layer": 301
          }
        }
      },
      {
        "id": "birth_year",
        "components": {
          "Slider": {
            "autoSize": true,
            "label": "Birth year",
            "key": "ageGate.year",
            "size": [640, 48],
            "min": 1900,
            "max": 2026,
            "value": 2000,
            "step": 1,
            "format": "{v:0}",
            "layer": 302,
            "autoFocus": true
          }
        }
      },
      {
        "id": "age_why",
        "components": {
          "Text": {
            "text": "We only use this to choose which ads can be shown. We keep whether you are a child, not your birth year.",
            "key": "ageGate.why",
            "fontSize": 18,
            "color": [0.75, 0.8, 0.9, 1],
            "space": "screen",
            "align": "start",
            "maxWidth": 700,
            "layer": 301
          }
        }
      },
      {
        "id": "age_continue",
        "components": {
          "Button": { "autoSize": true, "text": "Continue", "key": "ageGate.continue", "layer": 302 }
        }
      },
      {
        "id": "age_skip",
        "components": {
          "Button": { "autoSize": true, "text": "I would rather not say", "key": "ageGate.skip", "layer": 302 }
        }
      }
    ]
  }
}
```

### `scripts/ui/age_gate.js`

```js scripts/ui/age_gate.js
// @ts-check
// The age gate (prefabs/ui/age_gate.prefab.json): a neutral screen that asks for the birth YEAR, for a game whose
// factoria.json has platform.ads.audience "mixed" (children and adults play). It does not say which age matters, starts
// on no special year and lets the player decline. The answer goes to platform.ads.setUnderAge(), so the ad network treats a
// child as a child (no personalised ads, no consent sheet), and is kept in storage as a boolean: the birth year is not saved.
import { ui, world, storage, platform, game } from "factoria";
import { MenuStack } from "./menu_stack.js";

/** storage key of the saved answer: { underAge: boolean }. */
const KEY = "ageGate";
/** The highest age of consent in Europe (GDPR lets states pick 13 to 16). A year of birth alone is off by one, so the gate counts anyone born up to 16 years ago as a child. */
export const CONSENT_AGE = 16;

/** True when the player is a child by the birth year they gave, or declined to give one (declining counts as a child). */
export function isUnderAge(birthYear, year = game.today().year) {
  return birthYear === null || year - birthYear <= CONSENT_AGE;
}

/** The answer saved by an earlier run ({ underAge }), or null when the player has not answered. */
export function savedAge() {
  return storage.get(KEY, null);
}

/** Tells the ad network the answer the player gave in an earlier run. Does nothing when there is none. */
export function applySavedAge() {
  const saved = savedAge();
  if (saved) tell(saved.underAge === true);
}

/** Sends the answer to the ad network. A game without ads support, or a rejected call, still plays: ads just stay off. */
function tell(underAge) {
  platform.ads.setUnderAge(underAge).catch((e) => console.warn(`age gate: the ad network was not told: ${e.message}`));
}

/**
 * For a game with platform.ads.audience "mixed" (the main menu calls it only then), from the scene that opens first: opens the
 * gate over the menu when the player has not answered yet, otherwise tells the network the saved answer. `menus` is the
 * scene's MenuStack, `panel` the id of the gate's entity in the scene (prefabs/ui/age_gate.prefab.json). Returns true when
 * the gate is open. The player cannot close it with Back: an answer (or "I would rather not say") is needed.
 */
export function openAgeGate(menus, panel = "age_gate") {
  if (savedAge()) {
    applySavedAge();
    return false;
  }
  const field = world.find("birth_year");
  const slider = field.get("Slider");
  slider.max = game.today().year;
  slider.value = Math.min(slider.value, slider.max);
  const answer = (/** @type {number | null} */ birthYear) => {
    const underAge = isUnderAge(birthYear);
    storage.set(KEY, { underAge });
    tell(underAge);
    MenuStack.busy = false;
    menus.back();
  };
  // A click reaches the handler of every gate this scene opened; only the gate that is still there answers.
  ui.on("click", "age_continue", () => field.alive && answer(Math.round(slider.value)));
  ui.on("click", "age_skip", () => field.alive && answer(null));
  menus.show(panel);
  ui.focus(world.find("birth_year")); // a widget under the gate may hold the focus (a stack without a root panel does not move it)
  MenuStack.busy = true; // Escape / gamepad B must not skip the question
  return true;
}
```

### `tests/age_gate.test.js`

```js tests/age_gate.test.js
// The age gate (scripts/ui/age_gate.js): it asks for the birth year, tells the ad network whether the player is under the age
// of consent, keeps only that boolean, cannot be skipped with Back, and is not asked again. The gate is spawned from its prefab
// into whatever scene the test starts in, so this test passes in any game that has the ageGate part. The fake store plays the
// ad network (docs/PLATFORM.md), driven with a gamepad like the other menu tests.
import { test, expect, game } from "factoria:test";
import { world, ui, storage, platform } from "factoria";
import { MenuStack } from "../scripts/ui/menu_stack.js";
import { openAgeGate, isUnderAge } from "../scripts/ui/age_gate.js";

const pad = game.gamepad(0);

// An empty store, then the gate over a menu stack of its own. Returns the stack.
function open() {
  storage.clear();
  game.platform.reset();
  world.find("age_gate")?.destroy(); // the panel of the test before
  game.step(1);
  const panel = world.spawnPrefab("prefabs/ui/age_gate.prefab.json");
  panel.id = "age_gate"; // MenuStack shows panels by id
  panel.active = false;
  const menus = new MenuStack(null);
  expect(openAgeGate(menus)).toBe(true);
  game.step(2);
  expect(menus.top).toBe("age_gate");
  expect(world.find("age_gate").active).toBe(true);
  return menus;
}

// Sets the year on the slider the way a drag would, then presses Continue with the gamepad.
function answer(year) {
  world.find("birth_year").get("Slider").value = year;
  ui.focus(world.find("age_continue")); // the menu under the gate has widgets of its own: do not walk to Continue
  pad.tap("A");
  game.step(2);
}

test("the year decides: born 16 years ago or less counts as a child, a year of birth alone is off by one", () => {
  expect(isUnderAge(2020, 2026)).toBe(true);
  expect(isUnderAge(2010, 2026)).toBe(true); // 15 or 16: counted as a child
  expect(isUnderAge(2009, 2026)).toBe(false); // 16 or 17
  expect(isUnderAge(1980, 2026)).toBe(false);
  expect(isUnderAge(null, 2026)).toBe(true); // "I would rather not say"
});

test("a child's birth year: the network is told under age, and only that is saved", () => {
  const menus = open();
  expect(platform.ads.underAge).toBe(null);
  answer(game.today().year - 9);
  expect(platform.ads.underAge).toBe(true);
  expect(storage.get("ageGate")).toEqual({ underAge: true }); // not the year
  expect(menus.top).toBe(null);
  expect(world.find("age_gate").active).toBe(false);
  expect(game.platform.calls().filter((c) => c.method === "ads.setUnderAge").map((c) => c.args.underAge)).toEqual([true]);
});

test("an adult's birth year", () => {
  open();
  answer(1985);
  expect(platform.ads.underAge).toBe(false);
  expect(storage.get("ageGate")).toEqual({ underAge: false });
});

test("\"I would rather not say\" counts as a child", () => {
  open();
  ui.focus(world.find("age_skip")); // I would rather not say
  pad.tap("A");
  game.step(2);
  expect(platform.ads.underAge).toBe(true);
  expect(storage.get("ageGate")).toEqual({ underAge: true });
});

test("Back does not skip the question", () => {
  const menus = open();
  pad.tap("B");
  game.step(1);
  expect(menus.top).toBe("age_gate");
  expect(world.find("age_gate").active).toBe(true);
  expect(platform.ads.underAge).toBe(null);
  expect(MenuStack.busy).toBe(true);
  answer(1990);
  expect(MenuStack.busy).toBe(false);
});

test("the next run does not ask again and tells the network the saved answer", () => {
  open();
  answer(2015);
  expect(platform.ads.underAge).toBe(true);
  // A new run: the network forgot the answer (the fake is reset), storage kept it.
  game.platform.reset();
  expect(platform.ads.underAge).toBe(null);
  const menus = new MenuStack(null);
  expect(openAgeGate(menus)).toBe(false);
  game.step(2);
  expect(menus.top).toBe(null);
  expect(platform.ads.underAge).toBe(true);
});
```

### `prefabs/ui/analytics_consent.prefab.json`

```json prefabs/ui/analytics_consent.prefab.json
{
  "format": "factoria.prefab/1",
  "entity": {
    "name": "AnalyticsConsent",
    "components": {
      "Panel": {
        "size": [760, 420],
        "anchor": [0.5, 0.5],
        "layer": 300,
        "layout": "column",
        "spacing": 16,
        "padding": [24, 24, 24, 24]
      }
    },
    "children": [
      {
        "id": "analytics_title",
        "components": {
          "Text": { "text": "Help us improve the game?", "key": "analyticsConsent.title", "fontSize": 40, "space": "screen", "layer": 301 }
        }
      },
      {
        "id": "analytics_what",
        "components": {
          "Text": {
            "text": "We would like to count which levels are played and how they end, and which game version you use. We never collect your name, your contacts or anything you type.",
            "key": "analyticsConsent.what",
            "fontSize": 24,
            "space": "screen",
            "align": "start",
            "maxWidth": 700,
            "layer": 301
          }
        }
      },
      {
        "id": "analytics_change",
        "components": {
          "Text": {
            "text": "You can change your mind in Options at any time. If you say no, nothing is sent.",
            "key": "analyticsConsent.change",
            "fontSize": 18,
            "color": [0.75, 0.8, 0.9, 1],
            "space": "screen",
            "align": "start",
            "maxWidth": 700,
            "layer": 301
          }
        }
      },
      {
        "id": "analytics_allow",
        "components": {
          "Button": { "autoSize": true, "text": "Allow", "key": "analyticsConsent.allow", "layer": 302, "autoFocus": true }
        }
      },
      {
        "id": "analytics_deny",
        "components": {
          "Button": { "autoSize": true, "text": "No thanks", "key": "analyticsConsent.deny", "layer": 302 }
        }
      }
    ]
  }
}
```

### `scripts/ui/analytics_consent.js`

```js scripts/ui/analytics_consent.js
// @ts-check
// The analytics question (prefabs/ui/analytics_consent.prefab.json), for a game whose factoria.json has an "analytics" section
// (docs/ANALYTICS.md): analytics.event() sends nothing until the player said yes, so the game asks once, on its first screen.
// Both answers are fine: "No thanks" is kept like "Allow" (analytics.setConsent in storage), the question does not come back, and
// the player can change the answer in Options (the "analytics_consent" switch, scripts/ui/options.js). Say what is collected in your
// privacy policy and edit the texts "analyticsConsent.what" in locales/*.json to match what your game sends (docs/LEGAL.md).
import { ui, world, analytics } from "factoria";
import { MenuStack } from "./menu_stack.js";

/**
 * From the scene that opens first (the main menu calls it only when analytics.configured): opens the question over the menu
 * when the player has not answered yet. `menus` is the scene's MenuStack, `panel` the id of the entity of the prefab in the scene.
 * Returns true when the question is open; false when the game has no analytics or the player already answered (the answer
 * of an earlier run, or the ad consent when factoria.json says "consentFromAds"). The player cannot close it with Back.
 */
export function openAnalyticsConsent(menus, panel = "analytics_consent") {
  if (!analytics.configured || analytics.consent() !== "unknown") return false;
  const allow = world.find("analytics_allow");
  const answer = (/** @type {boolean} */ yes) => {
    analytics.setConsent(yes);
    MenuStack.busy = false;
    menus.back();
  };
  // A click reaches the handler of every question this scene opened; only the one that is still there answers.
  ui.on("click", "analytics_allow", () => allow.alive && answer(true));
  ui.on("click", "analytics_deny", () => allow.alive && answer(false));
  menus.show(panel);
  ui.focus(allow); // a widget under the question may hold the focus
  MenuStack.busy = true; // Escape / gamepad B must not skip the question
  return true;
}
```

### `tests/analytics_consent.test.js`

```js tests/analytics_consent.test.js
// The analytics question (scripts/ui/analytics_consent.js): asked once, both answers are kept, it cannot be skipped with Back, and
// nothing is queued until the player said yes. The prompt is spawned from its prefab into whatever scene the test starts in, so
// this test passes in any game with the analyticsConsent part; a game without an "analytics" section in factoria.json has nothing
// to ask and the tests only check that. The fake network plays the server (docs/ANALYTICS.md), driven with a gamepad.
import { test, expect, game } from "factoria:test";
import { world, ui, storage, analytics } from "factoria";
import { MenuStack } from "../scripts/ui/menu_stack.js";
import { openAnalyticsConsent } from "../scripts/ui/analytics_consent.js";

const pad = game.gamepad(0);

// An empty store, then the question over a menu stack of its own. Returns the stack.
function open() {
  storage.clear();
  game.platform.reset();
  game.analytics.restart();
  world.find("analytics_consent")?.destroy(); // the panel of the test before
  game.step(1);
  const panel = world.spawnPrefab("prefabs/ui/analytics_consent.prefab.json");
  panel.id = "analytics_consent"; // MenuStack shows panels by id
  panel.active = false;
  const menus = new MenuStack(null);
  expect(openAnalyticsConsent(menus)).toBe(true);
  game.step(2);
  expect(menus.top).toBe("analytics_consent");
  return menus;
}

function press(id) {
  ui.focus(world.find(id)); // the menu under the question has widgets of its own: do not walk to the button
  pad.tap("A");
  game.step(2);
}

test("a game without analytics has nothing to ask", () => {
  if (analytics.configured) return;
  expect(openAnalyticsConsent(new MenuStack(null))).toBe(false);
  expect(analytics.consent()).toBe("unknown");
});

test("before the answer no event is kept; Allow lets them through", () => {
  if (!analytics.configured) return;
  const menus = open();
  expect(analytics.event("level_start", { level: 1 })).toBe(false);
  expect(game.analytics.queued().length).toBe(0);
  press("analytics_allow");
  expect(analytics.consent()).toBe("granted");
  expect(menus.top).toBe(null);
  expect(MenuStack.busy).toBe(false);
  expect(analytics.event("level_start", { level: 1 })).toBe(true);
  expect(game.analytics.queued().map((e) => e.name)).toEqual(["level_start"]);
});

test("No thanks is an answer too: nothing is kept and it is not asked again", () => {
  if (!analytics.configured) return;
  open();
  press("analytics_deny");
  expect(analytics.consent()).toBe("denied");
  expect(analytics.event("level_start")).toBe(false);
  expect(openAnalyticsConsent(new MenuStack(null))).toBe(false); // the next run
});

test("Back does not skip the question", () => {
  if (!analytics.configured) return;
  const menus = open();
  pad.tap("B");
  game.step(1);
  expect(menus.top).toBe("analytics_consent");
  expect(analytics.consent()).toBe("unknown");
  expect(MenuStack.busy).toBe(true);
  press("analytics_allow");
  expect(MenuStack.busy).toBe(false);
});
```

### `prefabs/ui/card.prefab.json`

```json prefabs/ui/card.prefab.json
{
  "format": "factoria.prefab/1",
  "entity": {
    "name": "Card",
    "components": {
      "Panel": {
        "size": [1280, 720],
        "anchor": [0.5, 0.5],
        "layer": 290,
        "color": [0, 0, 0, 0.55],
        "layout": "column",
        "justify": "center",
        "modal": true
      }
    },
    "children": [
      {
        "id": "card_box",
        "components": {
          "Panel": {
            "layer": 300,
            "color": [0.08, 0.1, 0.14, 0.97],
            "layout": "column",
            "align": "start",
            "spacing": 12,
            "padding": [24, 16, 24, 24],
            "fit": true,
            "minSize": [640, 0],
            "maxSize": [640, 0]
          }
        },
        "children": [
          {
            "id": "card_kind",
            "components": {
              "Text": {
                "text": "",
                "fontSize": 18,
                "color": [0.66, 0.69, 0.75, 1],
                "space": "screen",
                "align": "start",
                "maxWidth": 592,
                "maxTextScale": 1.25,
                "layer": 301
              }
            }
          },
          {
            "id": "card_title",
            "components": {
              "Text": {
                "text": "",
                "fontSize": 32,
                "color": [1, 0.82, 0.29, 1],
                "space": "screen",
                "align": "start",
                "maxWidth": 592,
                "maxTextScale": 1.25,
                "layer": 301
              }
            }
          },
          {
            "id": "card_body",
            "components": {
              "Text": {
                "text": "",
                "fontSize": 20,
                "space": "screen",
                "align": "start",
                "maxWidth": 592,
                "maxTextScale": 1.25,
                "layer": 301
              }
            }
          },
          {
            "id": "card_choices",
            "components": {
              "Panel": {
                "layer": 301,
                "color": [0, 0, 0, 0],
                "layout": "column",
                "align": "start",
                "spacing": 8,
                "padding": [0, 0, 0, 0],
                "fit": true
              }
            }
          },
          {
            "id": "card_effects",
            "components": {
              "Text": {
                "text": "",
                "fontSize": 22,
                "space": "screen",
                "align": "start",
                "maxWidth": 592,
                "maxTextScale": 1.25,
                "layer": 301
              }
            }
          },
          {
            "id": "card_continue",
            "components": {
              "Button": {
                "text": "Continue",
                "key": "card.continue",
                "size": [160, 44],
                "autoSize": true,
                "autoShrink": true,
                "minFontSize": 10,
                "maxTextScale": 1.25,
                "layer": 302,
                "autoFocus": true
              }
            }
          }
        ]
      }
    ]
  }
}
```

### `scripts/ui/card.js`

```js scripts/ui/card.js
// @ts-check
// A choice card (prefabs/ui/card.prefab.json): a modal panel with a title, a wrapped body, choice buttons that each have a
// detail line, a choice that is greyed out with the reason shown, and a result stage with a Continue button. It is the
// event / story / dialogue card of a management game. The panel is `modal` (Panel.modal): while it is open only its widgets
// get the mouse, the wheel, the arrows and the pad, so the game under it neither hovers nor clicks, and the focus stays on the
// card. Mouse, keyboard and pad all work through the widgets: the arrows move between the choices that can be chosen, Enter,
// Space or gamepad A picks one.
import { world, ui, game, scene } from "factoria";

/** One choice of the card. `text` and `detail` are rich text (Text.markup: [b], [c:colour], [icon:name]). */
/** @typedef {{ id: string, text: string, detail?: string, disabled?: string | boolean }} CardChoice */

/** The colour of a disabled choice's reason: a built-in colour name, a colour of factoria.json text.colors or #rrggbb. */
const REASON_COLOR = "#ff8a80";
const COLOR_CHOICE = [0.18, 0.26, 0.38, 1];
const COLOR_DISABLED = [0.14, 0.16, 0.2, 1];

export class Card {
  /**
   * Opens the card (spawns the prefab). Fill it with ask(), then answer(), and end it with close().
   * @param {object} [options]
   * @param {(id: string) => void} [options.onChoose] the player picked the choice `id` (mouse, key or pad); disabled choices never get here
   * @param {() => void} [options.onContinue] the player pressed Continue on the result stage
   * @param {boolean} [options.holdClock] true: game.paused is true while the card is open (what was paused before stays paused)
   * @param {string} [options.reasonColor] colour of a disabled choice's reason (default a light red)
   * @param {string} [options.prefab] the card's prefab, when the game keeps its own copy
   */
  constructor(options = {}) {
    this.onChoose = options.onChoose || null;
    this.onContinue = options.onContinue || null;
    this.reasonColor = options.reasonColor || REASON_COLOR;
    this.sceneId = scene.current;
    this.root = world.spawnPrefab(options.prefab || "prefabs/ui/card.prefab.json");
    this.root.id = "card";
    /** @type {any[]} */ this.rows = [];
    this.stage = "none";
    this.heldPause = false;
    if (options.holdClock && !game.paused) {
      game.paused = true;
      this.heldPause = true;
    }
    // Listeners end with the scene; a click that arrives after the card was closed or the scene changed does nothing.
    this.off = ui.on("click", (e) => this.#click(e.id));
  }

  /** True while the card is on screen (not closed, and its scene is still the current one). */
  get isOpen() {
    return !!this.root && this.root.alive && scene.current === this.sceneId;
  }

  /**
   * The question stage: a title, a body and the choices. A choice with `disabled` (a reason, or true) cannot be picked, and
   * its detail line shows the reason; the first choice that can be picked has the focus.
   * @param {object} spec
   * @param {string} [spec.kind] small line over the title ("Event", "Story")
   * @param {string} spec.title
   * @param {string} [spec.body] rich text
   * @param {CardChoice[]} spec.choices
   */
  ask(spec) {
    if (!this.isOpen) return;
    this.stage = "choose";
    this.#text("card_kind", spec.kind || "");
    this.#text("card_title", spec.title);
    this.#text("card_body", spec.body || "");
    this.#text("card_effects", "");
    this.#clearRows();
    const parent = world.find("card_choices");
    parent.active = true;
    let first = true;
    for (const choice of spec.choices) {
      const reason = typeof choice.disabled === "string" ? choice.disabled : "";
      const disabled = !!choice.disabled;
      const row = world.spawn(
        { id: `choice_row_${choice.id}`, components: { Panel: { layer: 301, color: [0, 0, 0, 0], layout: "column", align: "start", spacing: 2, padding: [0, 0, 0, 0], fit: true } } },
        { parent },
      );
      world.spawn(
        {
          id: `choice_${choice.id}`,
          components: {
            Button: {
              text: choice.text,
              size: [592, 44],
              autoSize: true,
              maxWidth: 570,
              autoShrink: true,
              minFontSize: 10,
              maxTextScale: 1.25,
              markup: true,
              layer: 302,
              interactable: !disabled,
              color: disabled ? COLOR_DISABLED : COLOR_CHOICE,
              autoFocus: !disabled && first,
            },
          },
        },
        { parent: row },
      );
      if (!disabled) first = false;
      const detail = reason ? `[c:${this.reasonColor}]${reason}[/c]` : choice.detail || "";
      if (detail)
        world.spawn(
          {
            id: `choice_${choice.id}_detail`,
            components: { Text: { text: detail, fontSize: 18, space: "screen", align: "start", maxWidth: 570, maxTextScale: 1.25, markup: true, color: [0.75, 0.8, 0.9, 1], layer: 301 } },
          },
          { parent: row },
        );
      this.rows.push(row);
    }
    world.find("card_continue").active = false;
    this.#focusFirst();
  }

  /**
   * The result stage: what happened, the effects line, and a Continue button (it has the focus).
   * @param {object} spec
   * @param {string} spec.body rich text
   * @param {string} [spec.effects] rich text, drawn under the body in a larger size
   * @param {string} [spec.continueText] replaces the Continue label (otherwise the card.continue string)
   */
  answer(spec) {
    if (!this.isOpen) return;
    this.stage = "result";
    this.#text("card_body", spec.body);
    this.#text("card_effects", spec.effects || "");
    this.#clearRows();
    world.find("card_choices").active = false;
    const button = world.find("card_continue");
    button.active = true;
    if (spec.continueText) {
      button.get("Button").key = ""; // a key would replace the text
      button.get("Button").text = spec.continueText;
    }
    this.#focusFirst();
  }

  /** Closes the card: its panel goes, and the game goes on if the card paused it. Safe to call twice. */
  close() {
    this.off();
    if (this.root && this.root.alive) this.root.destroy();
    this.root = null;
    this.stage = "none";
    if (this.heldPause) {
      this.heldPause = false;
      game.paused = false;
    }
  }

  /** @param {string} id @param {string} text */
  #text(id, text) {
    const e = world.find(id);
    // Rich text is switched on here, not in the prefab: `factoria validate` warns about markup in a prefab of a game that has no bold font.
    if (id === "card_body" || id === "card_effects") e.get("Text").markup = true;
    e.get("Text").text = text;
    e.active = text !== "";
  }

  #clearRows() {
    for (const row of this.rows) {
      if (!row.alive) continue;
      row.active = false; // destroy() happens at the end of the frame: until then the old rows must not take room in the layout
      row.destroy();
    }
    this.rows = [];
  }

  #focusFirst() {
    const target = this.stage === "result" ? world.find("card_continue") : this.rows.map((r) => r.children[0]).find((b) => b.get("Button").interactable);
    if (target) ui.focus(target);
  }

  /** @param {string} id */
  #click(id) {
    if (!this.isOpen || typeof id !== "string") return;
    if (this.stage === "choose" && id.startsWith("choice_")) {
      const button = world.find(id);
      if (button?.get("Button")?.interactable) this.onChoose?.(id.slice("choice_".length));
    } else if (this.stage === "result" && id === "card_continue") {
      this.onContinue?.();
    }
  }
}
```

### `tests/card.test.js`

```js tests/card.test.js
// The choice card (scripts/ui/card.js): a modal panel over the game. A click on a button under it does nothing and the
// focus stays on the card; the arrows move between its choices (a disabled one is skipped and shows why); the pad picks;
// the result stage ends with Continue; holdClock pauses the game while it is open. The scene is built here, so this test
// passes in any game that has the card part.
import { test, expect, game } from "factoria:test";
import { world, ui } from "factoria";
import { Card } from "../scripts/ui/card.js";

const pad = game.gamepad(0);

/** A scene with a button under where the card will be, then the card with three choices (the second cannot be chosen). */
function open(options = {}) {
  game.loadJson({
    format: "factoria.scene/1",
    entities: [{ id: "under", components: { Button: { text: "Under", size: [200, 60], anchor: [0.5, 0.5], layer: 10 } } }],
  });
  game.step(2);
  const clicks = [];
  ui.on("click", (e) => clicks.push(e.id));
  const chosen = [];
  const card = new Card({ onChoose: (id) => chosen.push(id), onContinue: () => chosen.push("continue"), ...options });
  card.ask({
    kind: "Event",
    title: "A stranger at the gate",
    body: "A long body of text that has to wrap onto several lines inside the card, because the card is only 640 pixels wide and this sentence is longer than that.",
    choices: [
      { id: "help", text: "Help", detail: "Costs 2 wood" },
      { id: "buy", text: "Buy the map", detail: "Never shown", disabled: "Needs 50 coins" },
      { id: "leave", text: "Leave", detail: "Nothing happens" },
    ],
  });
  game.step(3);
  return { card, clicks, chosen };
}

test("a click on a button under the card does nothing, and the focus stays on the card", () => {
  const { card, clicks } = open();
  expect(ui.focused.id).toBe("choice_help");
  game.click("under");
  game.step(2);
  expect(clicks).not.toContain("under");
  expect(ui.hovered?.id ?? null).not.toBe("under");
  expect(ui.focused.id.startsWith("choice_")).toBe(true);
  expect(ui.pointerOverUi).toBe(true);
  card.close();
  game.step(2);
  game.click("under");
  game.step(2);
  expect(clicks).toContain("under");
});

test("the arrows move between the choices and skip the disabled one", () => {
  const { chosen } = open();
  expect(ui.focused.id).toBe("choice_help");
  game.tap("ui_down");
  game.step(2);
  expect(ui.focused.id).toBe("choice_leave"); // choice_buy cannot be chosen: no focus
  game.tap("ui_down");
  game.step(2);
  expect(ui.focused.id).toBe("choice_leave"); // the last one: the focus never leaves the card
  game.tap("ui_up");
  game.step(2);
  expect(ui.focused.id).toBe("choice_help");
  game.tap("ui_up");
  game.step(2);
  expect(ui.focused.id).toBe("choice_help");
  game.tap("ui_submit");
  game.step(2);
  expect(chosen).toEqual(["help"]);
});

test("a disabled choice does nothing and shows why", () => {
  const { chosen } = open();
  const buy = world.find("choice_buy");
  expect(buy.get("Button").interactable).toBe(false);
  game.click("choice_buy");
  game.step(2);
  expect(chosen).toEqual([]);
  expect(world.find("choice_buy_detail").get("Text").text).toContain("Needs 50 coins");
  expect(world.find("choice_buy_detail").get("Text").text).not.toContain("Never shown");
  expect(world.find("choice_help_detail").get("Text").text).toBe("Costs 2 wood");
});

test("the pad picks a choice, the result stage has Continue, and closing gives the game back", () => {
  const { card, clicks, chosen } = open();
  pad.tap("DpadDown");
  game.step(2);
  expect(ui.focused.id).toBe("choice_leave");
  pad.tap("A");
  game.step(2);
  expect(chosen).toEqual(["leave"]);
  card.answer({ body: "You walk away.", effects: "[b]Nothing changed[/b]" });
  game.step(3);
  expect(world.find("choice_leave")).toBe(null);
  expect(world.find("card_continue").activeInHierarchy).toBe(true);
  expect(ui.focused.id).toBe("card_continue");
  game.click("under");
  game.step(2);
  expect(clicks).not.toContain("under");
  pad.tap("A");
  game.step(2);
  expect(chosen).toEqual(["leave", "continue"]);
  card.close();
  game.step(2);
  expect(world.find("card")).toBe(null);
});

test("holdClock pauses the game while the card is open; a game that was paused stays paused", () => {
  game.paused = false;
  const { card } = open({ holdClock: true });
  expect(game.paused).toBe(true);
  card.close();
  expect(game.paused).toBe(false);
  game.paused = true;
  const again = open({ holdClock: true });
  again.card.close();
  expect(game.paused).toBe(true);
  game.paused = false;
});

test("the card blocks the pointer by being modal, not only by its backdrop", () => {
  const { card, clicks } = open();
  world.find("card").get("Panel").color = [0, 0, 0, 0]; // a backdrop that draws nothing is not hit...
  game.step(2);
  game.click("under"); // ...but Panel.modal still keeps the pointer from every widget outside the card
  game.step(2);
  expect(clicks).not.toContain("under");
  expect(ui.focused.id.startsWith("choice_")).toBe(true);
  card.close();
});
```

### `scenes/loading.scene.json`

```json scenes/loading.scene.json
{
  "format": "factoria.scene/1",
  "entities": [
    { "id": "camera", "components": { "Transform": { "position": [640, 360, 0] }, "Camera": { "clearColor": [0.1, 0.12, 0.18, 1] } } },
    { "id": "loading",
      "components": {
        "Transform": { "position": [-48, -48, 0] },
        "Text": { "text": "Loading...", "fontSize": 36, "space": "screen", "anchor": [1, 1], "pivot": [1, 0] },
        "Script": { "path": "scripts/loading.js" } } }
  ]
}
```

### `scripts/loading.js`

```js scripts/loading.js
// @ts-check
// scenes/loading.scene.json: reads the scene the main menu put in session.nextScene ahead of time, a few files every
// frame, so this scene keeps running (and drawing) meanwhile; then loads it, which reads nothing from the disk.
// A full recipe with a bar: set the width of a Shape2D from `job.progress` in onUpdate, like the text below.
import { Behaviour, i18n, scene, session } from "factoria";

export default class Loading extends Behaviour {
  onStart() {
    this.job = scene.preload(session.nextScene);
    // A scene that could not be read ahead still loads: scene.load reports what is wrong with it.
    const go = () => {
      if (this.gone) return; // this scene was left first (a test that moved on): the Promise must not load a scene now
      this.loading = true;
      scene.load(session.nextScene);
    };
    this.job.promise.then(go, go);
  }

  onDestroy() {
    this.gone = true;
    if (!this.loading) this.job.release(); // left before the files were in: give them back
  }

  onUpdate() {
    // No key on the Text: the line is built here, so the percentage sits inside the translated sentence.
    this.entity.get("Text").text = i18n.t("loading.progress", { percent: Math.round(this.job.progress * 100) });
  }
}
```

### `prefabs/ui/pause.prefab.json`

```json prefabs/ui/pause.prefab.json
{
  "format": "factoria.prefab/1",
  "entity": {
    "name": "Pause",
    "components": {
      "Panel": { "size": [1280, 720], "anchor": [0.5, 0.5], "layer": 290, "color": [0, 0, 0, 0.55], "layout": "column", "justify": "center" }
    },
    "children": [
      { "id": "pause_box",
        "components": { "Panel": { "layer": 300, "layout": "column", "spacing": 12, "padding": [32, 24, 32, 32], "fit": true } },
        "children": [
          { "id": "pause_title", "components": { "Text": { "text": "Paused", "key": "pause.title", "fontSize": 40, "layer": 301, "space": "screen" } } },
          { "id": "resume", "components": { "Button": { "autoSize": true, "text": "Resume", "key": "pause.resume", "layer": 302, "autoFocus": true } } },
          { "id": "pause_options", "components": { "Button": { "autoSize": true, "text": "Options", "key": "menu.options", "layer": 302 } } },
          { "id": "to_main_menu", "components": { "Button": { "autoSize": true, "text": "Main menu", "key": "pause.mainMenu", "layer": 302 } } }
        ] }
    ]
  }
}
```

### `scripts/pause_menu.js`

```js scripts/pause_menu.js
// @ts-check
// Put this behaviour on one entity of every level: the "pause" action (Escape, P, gamepad Start) pauses the game and
// opens the pause menu. game.paused freezes physics, animations and the other scripts; this one keeps running
// (runWhilePaused) to drive the menu and its options panel.
import { Behaviour, ui, input, game, scene, world } from "factoria";
import { applyOnce } from "./settings.js";
import { MenuStack } from "./ui/menu_stack.js";
import { readMenusAloud } from "./ui/read_aloud.js";

export default class PauseMenu extends Behaviour {
  runWhilePaused = true;

  onStart() {
    applyOnce();
    readMenusAloud();
    this.menus = new MenuStack(null);
    // Spawned, not written into the level: any level works with this one entity, even one scene.import_ascii rebuilds.
    for (const [id, prefab] of [["pause_panel", "pause"], ["options", "options"]]) {
      const panel = world.spawnPrefab(`prefabs/ui/${prefab}.prefab.json`);
      panel.id = id; // MenuStack shows panels by id
      panel.active = false;
    }
    ui.on("click", "resume", () => this.resume());
    ui.on("click", "pause_options", () => this.menus.show("options"));
    ui.on("click", "to_main_menu", () => {
      game.paused = false; // time.scale outlives scene loads
      scene.load("scenes/menu.scene.json");
    });
    ui.on("click", (e) => e.entity.hasTag("back") && this.back());
    // ui_cancel (Escape, gamepad B) goes back one panel. Escape is also "pause": onUpdate handles that press.
    ui.on("cancel", () => !input.pressed("pause") && this.back());
  }

  onUpdate() {
    if (this.resuming) {
      // Unpaused here, after this frame's gameplay was skipped: the A or Space press that clicked "Resume" must not
      // also reach the player as a jump.
      this.resuming = false;
      game.paused = false;
      return;
    }
    // The pause key opens the menu, and inside it goes back one panel like ui_cancel (from the pause panel: resume).
    if (input.pressed("pause") && !MenuStack.busy) game.paused ? this.back() : this.pause();
  }

  pause() {
    game.paused = true;
    this.menus.show("pause_panel");
  }

  resume() {
    this.menus.closeAll();
    this.resuming = true;
  }

  back() {
    if (this.menus.top === "pause_panel") this.resume();
    else this.menus.back();
  }
}
```

### `prefabs/ui/keyboard.prefab.json`

```json prefabs/ui/keyboard.prefab.json
{
  "format": "factoria.prefab/1",
  "entity": {
    "name": "Keyboard",
    "components": {
      "Panel": {
        "size": [1280, 720],
        "anchor": [0.5, 0.5],
        "layer": 390,
        "color": [0, 0, 0, 0.6],
        "layout": "column",
        "justify": "center"
      }
    },
    "children": [
      {
        "id": "keyboard_box",
        "components": {
          "Panel": {
            "layer": 400,
            "layout": "column",
            "spacing": 12,
            "padding": [28, 20, 28, 28],
            "fit": true,
            "color": [0.05, 0.07, 0.12, 0.96]
          }
        },
        "children": [
          {
            "id": "keyboard_preview",
            "components": {
              "Text": {
                "text": "",
                "fontSize": 36,
                "layer": 401,
                "space": "screen",
                "color": [1, 0.85, 0.3, 1]
              }
            }
          },
          {
            "id": "keyboard_keys",
            "components": {
              "Panel": {
                "layer": 401,
                "layout": "grid",
                "columns": 10,
                "fit": true,
                "spacing": 6,
                "color": [0, 0, 0, 0]
              }
            }
          },
          {
            "id": "keyboard_actions",
            "components": {
              "Panel": {
                "layer": 401,
                "layout": "row",
                "fit": true,
                "spacing": 10,
                "color": [0, 0, 0, 0]
              }
            },
            "children": [
              {
                "id": "osk_shift",
                "tags": ["osk"],
                "components": {
                  "Button": {
                    "autoSize": true,
                    "size": [96, 52],
                    "text": "Aa",
                    "layer": 402
                  }
                }
              },
              {
                "id": "osk_space",
                "tags": ["osk"],
                "components": {
                  "Button": {
                    "autoSize": true,
                    "size": [150, 52],
                    "text": "Space",
                    "key": "keyboard.space",
                    "layer": 402
                  }
                }
              },
              {
                "id": "osk_delete",
                "tags": ["osk"],
                "components": {
                  "Button": {
                    "autoSize": true,
                    "size": [150, 52],
                    "text": "Delete",
                    "key": "keyboard.delete",
                    "layer": 402
                  }
                }
              },
              {
                "id": "osk_done",
                "tags": ["osk"],
                "components": {
                  "Button": {
                    "autoSize": true,
                    "size": [150, 52],
                    "text": "Done",
                    "key": "keyboard.done",
                    "layer": 402
                  }
                }
              }
            ]
          }
        ]
      }
    ]
  }
}
```

### `scripts/ui/keyboard.js`

```js scripts/ui/keyboard.js
// @ts-check
// An on-screen keyboard for players with only a gamepad. Put this behaviour on one entity of every scene that has a
// TextField. When a TextField takes the focus because the player used the pad (input.lastDevice is "gamepad"), or when
// the player presses A on a focused TextField, the keyboard (prefabs/ui/keyboard.prefab.json) opens over the game: the
// d-pad walks the keys, A types one, "Delete" removes the last character, "Done" closes it and sends ui.submit for the
// field (what Enter does), B closes it and keeps the text. Typing goes through the same events a real keyboard sends
// (ui.change), so the game's code does not know the difference. Phones and keyboards use their own keyboard: the engine
// raises the phone's when a TextField gets the focus, and this one stays closed unless the last input was a pad. A
// platform that has a keyboard for pads (the Steam Deck, through a native plugin) shows its own: while
// input.platformKeyboard is true this one stays closed too.
//
// The keys follow the language (i18n.language): see LAYOUTS. A language whose script is not listed gets the Latin keys.
import { Behaviour, ui, input, world, i18n } from "factoria";

/** Lowercase letters of each script, then the digits are added. A game can add its own: LAYOUTS.ja = "...". */
export const LAYOUTS = {
  latin: "abcdefghijklmnopqrstuvwxyz",
  cyrillic: "абвгдежзийклмнопрстуфхцчшщъыьэюя",
  greek: "αβγδεζηθικλμνξοπρστυφχψω",
};
/** Language code -> script of LAYOUTS (languages not listed use "latin"). */
export const SCRIPT_OF = { ru: "cyrillic", uk: "cyrillic", bg: "cyrillic", sr: "cyrillic", mk: "cyrillic", el: "greek" };
/** Extra letters a Latin language needs, after the digits. */
export const EXTRA = {
  es: "ñáéíóúü", fr: "àâçèéêëîïôùûœ", de: "äöüß", pt: "ãõçáéíóúâê", it: "àèéìòù", pl: "ąćęłńóśźż",
  tr: "çğıişöü", sv: "åäö", da: "åæø", nb: "åæø", no: "åæø", cs: "áčďéěíňóřšťúůýž",
};
const DIGITS = "0123456789";

/** The characters of the keyboard for a language such as "es" or "pt-BR". */
export function keysFor(language) {
  const base = String(language || "en").toLowerCase().split(/[-_]/)[0];
  const script = SCRIPT_OF[base] ?? "latin";
  return Array.from(LAYOUTS[script] + DIGITS + (script === "latin" ? (EXTRA[base] ?? "") : ""));
}

export default class OnScreenKeyboard extends Behaviour {
  runWhilePaused = true;

  /** True while a keyboard is open: a game's own ui.cancel handler should do nothing then (B closes the keyboard). */
  static isOpen = false;

  onStart() {
    OnScreenKeyboard.isOpen = false;
    input.textInputMode = false;
    this.panel = world.spawnPrefab("prefabs/ui/keyboard.prefab.json");
    this.panel.id = "keyboard";
    this.panel.active = false;
    this.field = null; // the TextField being edited while the keyboard is open
    this.shift = false;
    this.built = ""; // the characters of the keys that exist now
    this.lastKey = null;
    this.ignore = null; // the field that just got the focus back from us: it must not reopen the keyboard
    this.ignoreAge = 0;
    ui.on("focus", (e) => this.onFocus(e.entity));
    ui.on("click", (e) => e.entity.hasTag("osk") && this.onClick(e.entity));
    ui.on("cancel", () => {
      if (!this.field) return false;
      this.close(false);
      return true; // B / Escape closed the keyboard: nothing else acts on this press (ui_cancel is consumed)
    });
  }

  onDestroy() {
    OnScreenKeyboard.isOpen = false;
  }

  onUpdate() {
    if (this.ignore && ++this.ignoreAge > 2) this.ignore = null;
    if (this.field) {
      if (!this.field.alive || !this.field.activeInHierarchy) return this.close(false);
      // Somebody picked up a keyboard or touched the screen: the field takes their typing, the pad keyboard goes away.
      if (input.lastDevice === "keyboard" || input.lastDevice === "touch") this.close(false);
      return;
    }
    // A on a focused field opens the keyboard again after B closed it.
    const f = ui.focused;
    if (!this.ignore && f && f.has("TextField") && input.lastDevice === "gamepad" && !input.platformKeyboard && input.pressed("ui_submit"))
      this.open(f);
  }

  onFocus(entity) {
    if (this.field) {
      // The d-pad left the keys (the widgets behind the keyboard are still focusable): bring the focus back.
      if (!entity.hasTag("osk") && this.lastKey?.alive) ui.focus(this.lastKey);
      else if (entity.hasTag("osk")) this.lastKey = entity;
      return;
    }
    if (this.ignore === entity.id) return; // the focus we gave back ourselves (onUpdate forgets it two frames later)
    if (entity.has("TextField") && input.lastDevice === "gamepad" && !input.platformKeyboard) this.open(entity);
  }

  open(field) {
    this.field = field;
    this.shift = false;
    OnScreenKeyboard.isOpen = true;
    input.textInputMode = true; // the typed keys belong to the keyboard: game actions on letters read as up meanwhile
    this.build(keysFor(i18n.language));
    this.holdOthers();
    this.panel.active = true;
    this.showText();
    ui.layout();
    const first = world.find("osk_key_0");
    this.lastKey = first;
    ui.focus(first);
  }

  /** Closes the keyboard and gives the focus back to the field. done = the player pressed "Done": send ui.submit. */
  close(done) {
    const field = this.field;
    this.field = null;
    OnScreenKeyboard.isOpen = false;
    this.panel.active = false;
    this.releaseOthers();
    if (!field?.alive) return;
    this.ignore = field.id;
    this.ignoreAge = 0;
    if (field.activeInHierarchy && input.lastDevice === "gamepad") ui.focus(field);
    else this.ignore = null;
    if (done) world.emit("ui.submit", { id: field.id, value: field.get("TextField").text }, field);
  }

  /**
   * The d-pad picks the nearest widget in its direction, and the menu behind the keyboard has widgets too: while the
   * keyboard is open they stop taking focus (interactable = false), and close() gives them back.
   */
  holdOthers() {
    this.held = [];
    for (const e of world.entities()) {
      if (e.hasTag("osk") || !e.activeInHierarchy) continue;
      for (const kind of ["Button", "Toggle", "Slider", "TextField"]) {
        if (!e.has(kind) || !e.get(kind).interactable) continue;
        e.get(kind).interactable = false;
        this.held.push([e, kind]);
      }
    }
  }

  releaseOthers() {
    for (const [e, kind] of this.held ?? []) if (e.alive) e.get(kind).interactable = true;
    this.held = [];
  }

  /** Makes one Button per character (not again when the characters are the same as last time). */
  build(chars) {
    const key = chars.join("");
    if (key === this.built) {
      this.relabel();
      return;
    }
    const grid = world.find("keyboard_keys");
    for (const child of grid.children) child.destroy();
    chars.forEach((ch, i) => {
      world.spawn(
        { id: "osk_key_" + i, tags: ["osk"], components: { Button: { size: [64, 56], text: ch, layer: 402, fontSize: 28, color: [0.24, 0.27, 0.36, 0.95] } } },
        { parent: grid },
      );
    });
    this.built = key;
    this.base = chars;
    this.relabel();
  }

  /** Letters in upper case while shift is on. A letter with no upper-case form of one character (the German ß) stays. */
  relabel() {
    this.base.forEach((ch, i) => {
      const up = ch.toUpperCase();
      world.find("osk_key_" + i).get("Button").text = this.shift && Array.from(up).length === 1 ? up : ch;
    });
  }

  onClick(entity) {
    if (!this.field) return;
    const text = this.field.get("TextField").text;
    switch (entity.id) {
      case "osk_done": return this.close(true);
      case "osk_space": return this.type(" ");
      case "osk_delete": return this.set(Array.from(text).slice(0, -1).join(""));
      case "osk_shift":
        this.shift = !this.shift;
        return this.relabel();
      default:
        if (entity.id.startsWith("osk_key_")) this.type(entity.get("Button").text);
    }
  }

  /** Adds one character, within the field's maxLength. */
  type(ch) {
    const f = this.field.get("TextField");
    if (f.maxLength > 0 && Array.from(f.text).length >= f.maxLength) return;
    this.set(f.text + ch);
  }

  /** Writes the field's text and sends ui.change, as a real keyboard's typing does. */
  set(text) {
    this.field.get("TextField").text = text;
    world.emit("ui.change", { id: this.field.id, value: text }, this.field);
    this.showText();
  }

  showText() {
    world.find("keyboard_preview").get("Text").text = this.field.get("TextField").text + "_";
  }
}
```

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

### `locales/en.json`

The strings of the default language; `locales/es.json` below has the same keys in Spanish. `{name}` is replaced by
the argument of `i18n.t(key, args)`; a nested object is a dotted key (`options.tab.video`).

```json locales/en.json
{
  "$name": "English",
  "menu": {
    "title": "My Game",
    "play": "Play",
    "options": "Options",
    "credits": "Credits",
    "shop": "Shop",
    "quit": "Quit",
    "back": "Back"
  },
  "loading": { "progress": "Loading... {percent}%" },
  "captions": { "welcome": "Welcome, traveller.", "hint": "Watch the edge!", "guide": "Guide" },
  "pause": { "title": "Paused", "resume": "Resume", "mainMenu": "Main menu" },
  "options": {
    "title": "Options",
    "tab": { "video": "Video", "audio": "Audio", "controls": "Controls", "language": "Language" },
    "windowMode": "Window mode: {mode}",
    "mode": {
      "windowed": "windowed",
      "borderless": "borderless",
      "fullscreen": "full screen"
    },
    "monitor": "Monitor: {n} - {name}",
    "vsync": "VSync",
    "windowSize": "Window size: {width} x {height}",
    "windowSizeFullscreen": "Window size: full screen",
    "frameCap": "Frame cap: {fps} fps",
    "frameCapOff": "Frame cap: off",
    "uiScale": "Interface size: {percent}%",
    "colorFilter": "Color filter: {filter}",
    "filter": { "none": "off", "greyscale": "greyscale", "highContrast": "high contrast", "protanopia": "protanopia (red)", "deuteranopia": "deuteranopia (green)", "tritanopia": "tritanopia (blue)" },
    "videoNote": "Video settings apply when the game runs in its own window.",
    "volume": { "master": "Master", "music": "Music", "effects": "Effects", "interface": "Interface" },
    "action": { "move_left": "Move left", "move_right": "Move right", "jump": "Jump", "pause": "Pause" },
    "binding": "{action}: {button}",
    "player": "Player {n}",
    "playerBinding": "{action}: {keys}  |  {pad}",
    "pressKey": "{action}: press a key or button (Esc cancels)",
    "resetControls": "Reset to defaults",
    "language": "Language: {language}",
    "readAloud": "Read menus aloud",
    "subtitles": "Subtitles",
    "privacyOptions": "Ad privacy settings",
    "analytics": "Share anonymous usage data",
    "on": "on",
    "off": "off",
    "percent": "{value} percent",
    "textSpeed": "Text speed: {speed}",
    "speed": {
      "slow": "slow",
      "normal": "normal",
      "fast": "fast",
      "instant": "instant",
      "custom": "custom"
    }
  },
  "credits": {
    "madeWith": "Made with FactorIA",
    "software": "This game uses the following software:",
    "licenses": "The full license texts are in FACTORIA_NOTICES.txt, shipped with the game."
  },
  "shop": {
    "title": "Shop",
    "gems": "Gems: {count}",
    "gemsNoAds": "Gems: {count}   (ads removed)",
    "restore": "Restore purchases",
    "waiting": "Waiting for the store...",
    "asking": "Asking the store...",
    "thanks": "Thank you!",
    "arrived": "Your purchase arrived.",
    "pending": "Waiting for approval. The purchase arrives when it is approved.",
    "cancelled": "Purchase cancelled. Nothing was charged.",
    "restored": "Your purchases were restored.",
    "nothingToRestore": "There was nothing to restore.",
    "unreachable": "The store could not be reached ({code}). {detail}"
  },
  "keyboard": { "space": "Space", "delete": "Delete", "done": "Done" },
  "name": { "title": "Your name", "placeholder": "Name", "next": "Continue" },
  "ageGate": {
    "title": "Before you play",
    "question": "In which year were you born?",
    "why": "We only use this to choose which ads can be shown. We keep whether you are a child, not your birth year.",
    "year": "Birth year",
    "continue": "Continue",
    "skip": "I would rather not say"
  },
  "analyticsConsent": {
    "title": "Help us improve the game?",
    "what": "We would like to count which levels are played and how they end, and which game version you use. We never collect your name, your contacts or anything you type.",
    "change": "You can change your mind in Options at any time. If you say no, nothing is sent.",
    "allow": "Allow",
    "deny": "No thanks"
  },
  "card": {
    "continue": "Continue"
  },
  "slots": {
    "titleSave": "Save game",
    "titleLoad": "Load game",
    "empty": "Slot {n}: empty",
    "emptyAuto": "Autosave: empty",
    "used": "Slot {n}: {name}\nChapter {chapter}, {time}",
    "usedAuto": "Autosave: {name}\nChapter {chapter}, {time}",
    "damaged": "Slot {n}: damaged (delete it to free the slot)",
    "damagedAuto": "Autosave: damaged (delete it)",
    "damagedNote": "A slot cannot be read. Delete it, or load another.",
    "unnamed": "Unnamed",
    "autoName": "autosave",
    "delete": "Delete",
    "nameTitle": "Name the save in slot {n}",
    "namePlaceholder": "Name this save",
    "confirmSave": "Save",
    "cancel": "Cancel",
    "deleteTitle": "Delete slot {n}?",
    "confirmDelete": "Delete",
    "saved": "Saved to slot {n}.",
    "noGame": "There is no game to save yet.",
    "busy": "You cannot save right now.",
    "noSave": "Saving is not available here."
  }
}
```

### `locales/es.json`

The same keys in Spanish. A game with two languages from the start copies this file as it is, or translates it into a
third language by editing the values only (keep the keys and the `{placeholders}`).

```json locales/es.json
{
  "$name": "Español",
  "menu": {
    "title": "Mi juego",
    "play": "Jugar",
    "options": "Opciones",
    "credits": "Créditos",
    "shop": "Tienda",
    "quit": "Salir",
    "back": "Atrás"
  },
  "loading": { "progress": "Cargando... {percent}%" },
  "captions": { "welcome": "Bienvenido, viajero.", "hint": "¡Cuidado con el borde!", "guide": "Guía" },
  "pause": { "title": "En pausa", "resume": "Reanudar", "mainMenu": "Menú principal" },
  "options": {
    "title": "Opciones",
    "tab": { "video": "Vídeo", "audio": "Audio", "controls": "Controles", "language": "Idioma" },
    "windowMode": "Modo de ventana: {mode}",
    "mode": {
      "windowed": "ventana",
      "borderless": "sin bordes",
      "fullscreen": "pantalla completa"
    },
    "monitor": "Monitor: {n} - {name}",
    "vsync": "VSync",
    "windowSize": "Tamaño de ventana: {width} x {height}",
    "windowSizeFullscreen": "Tamaño de ventana: pantalla completa",
    "frameCap": "Límite de fotogramas: {fps} fps",
    "frameCapOff": "Límite de fotogramas: sin límite",
    "uiScale": "Tamaño de la interfaz: {percent}%",
    "colorFilter": "Filtro de color: {filter}",
    "filter": { "none": "desactivado", "greyscale": "escala de grises", "highContrast": "alto contraste", "protanopia": "protanopia (rojo)", "deuteranopia": "deuteranopia (verde)", "tritanopia": "tritanopia (azul)" },
    "videoNote": "Los ajustes de vídeo se aplican cuando el juego se ejecuta en su propia ventana.",
    "volume": { "master": "General", "music": "Música", "effects": "Efectos", "interface": "Interfaz" },
    "action": { "move_left": "Mover a la izquierda", "move_right": "Mover a la derecha", "jump": "Saltar", "pause": "Pausa" },
    "binding": "{action}: {button}",
    "player": "Jugador {n}",
    "playerBinding": "{action}: {keys}  |  {pad}",
    "pressKey": "{action}: pulsa una tecla o botón (Esc cancela)",
    "resetControls": "Restablecer valores",
    "language": "Idioma: {language}",
    "readAloud": "Leer los menús en voz alta",
    "subtitles": "Subtítulos",
    "privacyOptions": "Privacidad de los anuncios",
    "analytics": "Compartir datos de uso anónimos",
    "on": "activado",
    "off": "desactivado",
    "percent": "{value} por ciento",
    "textSpeed": "Velocidad del texto: {speed}",
    "speed": {
      "slow": "lenta",
      "normal": "normal",
      "fast": "rápida",
      "instant": "instantánea",
      "custom": "personalizada"
    }
  },
  "credits": {
    "madeWith": "Hecho con FactorIA",
    "software": "Este juego usa el siguiente software:",
    "licenses": "Los textos completos de las licencias están en FACTORIA_NOTICES.txt, junto al juego."
  },
  "shop": {
    "title": "Tienda",
    "gems": "Gemas: {count}",
    "gemsNoAds": "Gemas: {count}   (sin anuncios)",
    "restore": "Restaurar compras",
    "waiting": "Esperando a la tienda...",
    "asking": "Consultando a la tienda...",
    "thanks": "¡Gracias!",
    "arrived": "Tu compra ha llegado.",
    "pending": "Esperando aprobación. La compra llega cuando se apruebe.",
    "cancelled": "Compra cancelada. No se ha cobrado nada.",
    "restored": "Tus compras se han restaurado.",
    "nothingToRestore": "No había nada que restaurar.",
    "unreachable": "No se pudo contactar con la tienda ({code}). {detail}"
  },
  "keyboard": { "space": "Espacio", "delete": "Borrar", "done": "Hecho" },
  "name": { "title": "Tu nombre", "placeholder": "Nombre", "next": "Continuar" },
  "ageGate": {
    "title": "Antes de jugar",
    "question": "¿En qué año naciste?",
    "why": "Solo lo usamos para elegir qué anuncios se pueden mostrar. Guardamos si eres menor, no tu año de nacimiento.",
    "year": "Año de nacimiento",
    "continue": "Continuar",
    "skip": "Prefiero no decirlo"
  },
  "analyticsConsent": {
    "title": "¿Nos ayudas a mejorar el juego?",
    "what": "Nos gustaría contar qué niveles se juegan y cómo terminan, y qué versión del juego usas. Nunca recogemos tu nombre, tus contactos ni nada de lo que escribes.",
    "change": "Puedes cambiar de opinión en Opciones cuando quieras. Si dices que no, no se envía nada.",
    "allow": "Permitir",
    "deny": "No, gracias"
  },
  "card": {
    "continue": "Continuar"
  },
  "slots": {
    "titleSave": "Guardar partida",
    "titleLoad": "Cargar partida",
    "empty": "Ranura {n}: vacía",
    "emptyAuto": "Autoguardado: vacío",
    "used": "Ranura {n}: {name}\nCapítulo {chapter}, {time}",
    "usedAuto": "Autoguardado: {name}\nCapítulo {chapter}, {time}",
    "damaged": "Ranura {n}: dañada (bórrala para liberar la ranura)",
    "damagedAuto": "Autoguardado: dañado (bórralo)",
    "damagedNote": "No se puede leer una ranura. Bórrala o carga otra.",
    "unnamed": "Sin nombre",
    "autoName": "autoguardado",
    "delete": "Borrar",
    "nameTitle": "Nombre de la partida en la ranura {n}",
    "namePlaceholder": "Ponle un nombre a la partida",
    "confirmSave": "Guardar",
    "cancel": "Cancelar",
    "deleteTitle": "¿Borrar la ranura {n}?",
    "confirmDelete": "Borrar",
    "saved": "Guardado en la ranura {n}.",
    "noGame": "Todavía no hay ninguna partida que guardar.",
    "busy": "Ahora no se puede guardar.",
    "noSave": "Aquí no se puede guardar."
  }
}
```

### `tests/recipe.test.js`

```js tests/recipe.test.js
// The test that ships with the menu kit (project.add_menu_kit): it opens the kit's main menu itself, so it passes whatever the
// game's mainScene is, and drives the menus with a gamepad only.
import { test, expect, game } from "factoria:test";
import { ui, storage, audio, scene, analytics } from "factoria";

// Each test file starts on the project's mainScene with empty storage.
test("gamepad only: main menu -> options -> music volume -> back, and the volume is saved", () => {
  if (analytics.configured) analytics.setConsent(true); // a game with analytics: the question of the first run is answered (tests/analytics_consent.test.js)
  scene.load("scenes/menu.scene.json");
  const pad = game.gamepad(0);
  game.step(2);
  pad.tap("DpadDown"); // Options
  pad.tap("A");
  pad.tap("DpadRight"); // the Audio tab
  pad.tap("A");
  pad.tap("DpadDown"); // Master
  pad.tap("DpadDown"); // Music
  pad.tap("DpadRight"); // 0.6 -> 0.7
  pad.tap("B"); // back to the main menu
  expect(ui.focused.id).toBe("options_button");
  expect(audio.getVolume("music")).toBeCloseTo(0.7);
  expect(storage.get("settings").volume.music).toBeCloseTo(0.7);
});
```

### `scripts/slots.js`

The records: `Slots` reads and writes the slots in `storage` (and the cloud when the player is signed in), `formatTime` and `capturePic` help the screen. The game passes `upgrade` (migrate an older save, or say why it cannot be read) and `describe` (chapter and play time of a bare save).

```js scripts/slots.js
// @ts-check
// Save slots: named slots and an autosave in `storage`, each a string of JSON text and, when the player is signed in to a store,
// a copy in the cloud under the same key. A slot holds a RECORD:
//
//   { "counter": 7, "name": "Before the cellar", "chapter": 3, "playTime": 3725.5, "pic": "<base64 PNG>" | null, "data": <the game's save> }
//
// `data` is whatever the game saves (any JSON); the rest is what the slot screen (scripts/ui/slot_screen.js) shows without opening
// the slot. `counter` goes up by one on every save (the wall clock is never read): when a cloud copy and a local one differ, the
// higher counter wins (syncCloud). A text that is not a record (no "data" field) is read as a bare save: a record without a
// name, picture or counter, so a game can start with plain saves and move to slots later.
//
//   const slots = new Slots({ upgrade: (data) => ({ ok: true, data }), describe: (data) => ({ chapter: data.chapter, playTime: data.playTime }) });
//   slots.write(1, { name: "Before the cellar", data: mySave, chapter: 3, playTime: 3725.5, pic: capturePic() });
//   const p = slots.peek(1);                  // { status: "used", record } | { status: "empty" } | { status: "damaged", reason, hint }
//   if (p.status === "used") load(p.record.data);
//   await slots.syncCloud();                  // when the slot screen opens, and again when the game starts
//
// The game decides WHEN it may save (a cut-scene or a loading screen may not) and what is in `data`; this file never looks inside it
// except through `upgrade` (migrates an older save when it is read) and `describe` (chapter and play time of a bare save).
import { storage, platform, render } from "factoria";

/** Size of the picture kept with a slot (16:9, a few KB as PNG). */
export const PIC = Object.freeze({ width: 192, height: 108 });

/** "h:mm:ss" for a number of seconds. */
export function formatTime(seconds) {
  const s = Math.max(0, Math.floor(Number(seconds) || 0));
  const pad = (n) => String(n).padStart(2, "0");
  return `${Math.floor(s / 3600)}:${pad(Math.floor(s / 60) % 60)}:${pad(s % 60)}`;
}

/**
 * A picture of the game as the player sees it (render.captureTexture), as base64 PNG, or null when nothing real can be drawn (a
 * headless run has no graphics). Take it before a menu covers the game.
 * @param {{ width: number, height: number }} [size]
 */
export function capturePic(size = PIC) {
  try {
    const tex = render.captureTexture({ width: size.width, height: size.height });
    const png = tex.placeholder ? null : tex.toPNG();
    tex.destroy();
    return png;
  } catch (e) {
    console.warn(`slots: no picture for the slot: ${e.message}`);
    return null;
  }
}

/**
 * @typedef {{ counter: number, name: string, chapter: number, playTime: number, pic: string | null, data: any }} SlotRecord
 * @typedef {{ ok: true, data: any } | { ok: false, message: string, hint?: string }} Upgraded
 */

export class Slots {
  /**
   * @param {object} [options]
   * @param {Array<number | string>} [options.ids] the manual slots, default 1 to 5. The slot screen's prefab has a row for each of 1..5 and "auto".
   * @param {string | null} [options.auto] id of the autosave slot ("auto"); null = no autosave
   * @param {string} [options.keyPrefix] storage (and cloud) key of slot N is `${keyPrefix}${N}`, "slot1"; the autosave is `${keyPrefix}_${auto}`
   * @param {string} [options.counterKey] storage key of the highest counter handed out
   * @param {string} [options.lastKey] storage key of the id of the slot saved last (for a "Continue" button)
   * @param {(data: any) => Upgraded} [options.upgrade] migrates the data of a slot to the newest layout when it is read; a not-ok result makes the slot "damaged" with that message
   * @param {(data: any) => { chapter?: number, playTime?: number }} [options.describe] chapter and play time of a bare save (a record's own fields win)
   */
  constructor(options = {}) {
    this.SLOTS = Object.freeze([...(options.ids ?? [1, 2, 3, 4, 5])]);
    this.AUTO = options.auto === undefined ? "auto" : options.auto;
    /** Every slot the screen shows, the autosave first. */
    this.ALL = Object.freeze(this.AUTO === null ? [...this.SLOTS] : [this.AUTO, ...this.SLOTS]);
    this.keyPrefix = options.keyPrefix ?? "slot";
    this.counterKey = options.counterKey ?? "saveCounter";
    this.lastKey = options.lastKey ?? "lastSlot";
    this.upgrade = options.upgrade ?? ((data) => ({ ok: true, data }));
    this.describe = options.describe ?? (() => ({}));
  }

  /** The storage key (and cloud key) of a slot id. */
  key(id) {
    return id === this.AUTO ? `${this.keyPrefix}_${id}` : `${this.keyPrefix}${id}`;
  }

  /**
   * Reads the text of a slot (or a cloud copy). `{ ok: true, record }` with the data in the newest layout, or `{ ok: false, reason, hint }`
   * for text that is not JSON, not an object, or refused by `upgrade`. Never throws.
   * @param {any} text
   * @returns {{ ok: true, record: SlotRecord } | { ok: false, reason: string, hint: string }}
   */
  parse(text) {
    let raw;
    try {
      raw = typeof text === "string" ? JSON.parse(text) : text;
    } catch (e) {
      return { ok: false, reason: `not valid JSON (${e.message})`, hint: "Delete the slot." };
    }
    if (!raw || typeof raw !== "object" || Array.isArray(raw)) return { ok: false, reason: "not a JSON object", hint: "Delete the slot." };
    const bare = !Object.hasOwn(raw, "data");
    let up;
    try {
      up = this.upgrade(bare ? raw : raw.data);
    } catch (e) {
      up = { ok: false, message: `the save could not be read (${e.message})` };
    }
    if (!up.ok) return { ok: false, reason: up.message, hint: up.hint ?? "Delete the slot." };
    const info = this.describe(up.data) ?? {};
    const number = (v) => (typeof v === "number" && Number.isFinite(v) ? v : undefined);
    return {
      ok: true,
      record: {
        counter: !bare && Number.isInteger(raw.counter) && raw.counter >= 0 ? raw.counter : 0,
        name: !bare && typeof raw.name === "string" ? raw.name : "",
        chapter: (bare ? undefined : number(raw.chapter)) || number(info.chapter) || 0,
        playTime: (bare ? undefined : number(raw.playTime)) ?? number(info.playTime) ?? 0,
        pic: !bare && typeof raw.pic === "string" && raw.pic !== "" ? raw.pic : null,
        data: up.data,
      },
    };
  }

  /** What the slot screen shows: `{ status: "empty" | "used" | "damaged", reason?, hint?, record? }`. */
  peek(id) {
    const text = storage.get(this.key(id), null);
    if (text === null) return { status: "empty" };
    const r = this.parse(text);
    if (!r.ok) return { status: "damaged", reason: r.reason, hint: r.hint };
    return { status: "used", record: r.record };
  }

  /** The id of the slot that was saved last, if it still exists, else null. */
  last() {
    const id = storage.get(this.lastKey, null);
    return id !== null && this.ALL.includes(id) && this.peek(id).status === "used" ? id : null;
  }

  nextCounter() {
    let top = storage.get(this.counterKey, 0);
    for (const id of this.ALL) {
      const p = this.peek(id);
      if (p.status === "used") top = Math.max(top, p.record.counter);
    }
    storage.set(this.counterKey, top + 1);
    return top + 1;
  }

  /**
   * Saves into slot `id`: the record gets the next counter, is written to storage and uploaded to the cloud when the player is signed in
   * (a failed upload never matters: the local save stands). `name` is trimmed; empty stays empty (the screen shows "Unnamed").
   * Returns the record.
   * @param {number | string} id
   * @param {{ data: any, name?: string, chapter?: number, playTime?: number, pic?: string | null }} save
   * @returns {SlotRecord}
   */
  write(id, { data, name = "", chapter = 0, playTime = 0, pic = null }) {
    const record = { counter: this.nextCounter(), name: String(name).trim(), chapter, playTime, pic, data };
    const text = JSON.stringify(record);
    storage.set(this.key(id), text);
    storage.set(this.lastKey, id);
    this.upload(id, text);
    return record;
  }

  /** Empties slot `id` here and in the cloud (otherwise the next sync would bring it back). */
  remove(id) {
    storage.remove(this.key(id));
    if (storage.get(this.lastKey, null) === id) storage.remove(this.lastKey);
    if (platform.has("cloudSave")) platform.cloud.remove(this.key(id)).catch(() => {}); // a failed delete can come back at the next sync
  }

  upload(id, text) {
    if (platform.has("cloudSave")) platform.cloud.save(this.key(id), text).catch(() => {}); // the local save stands whatever the store says
  }

  /**
   * Compares every slot with its cloud copy: the one with the higher counter wins (a cloud copy replaces the local slot, a better
   * local one is uploaded). A store that is down or a player who is not signed in changes nothing. Resolves with true when a local
   * slot was replaced. The caller checks that its scene is still the current one before it draws the result.
   */
  async syncCloud() {
    if (!platform.has("cloudSave")) return false;
    let replaced = false;
    for (const id of this.ALL) {
      try {
        const cloud = await platform.cloud.load(this.key(id));
        const local = this.peek(id);
        const remote = cloud === undefined || cloud === null ? null : this.parse(cloud);
        if (remote?.ok && (local.status !== "used" || remote.record.counter > local.record.counter)) {
          storage.set(this.key(id), JSON.stringify(remote.record));
          replaced = true;
        } else if (local.status === "used" && (!remote?.ok || local.record.counter > remote.record.counter)) {
          this.upload(id, storage.get(this.key(id)));
        }
      } catch {
        return replaced; // offline or signed out: keep what is here
      }
    }
    return replaced;
  }
}
```

### `scripts/ui/slot_screen.js`

The screen: the host (pause menu, title screen) builds one `SlotScreen` with its `MenuStack` and opens it in `"save"` or `"load"` mode.

```js scripts/ui/slot_screen.js
// @ts-check
// The save / load screen (prefabs/ui/slots.prefab.json) and the small dialog that names a save or asks before a delete
// (prefabs/ui/slot_dialog.prefab.json). Not a behaviour: the pause menu (save and load) and the title screen (load) each build one
// with their MenuStack and call tick() every frame.
//
//   const slots = new Slots();                                 // scripts/slots.js: the records
//   const screen = new SlotScreen(menus, {
//     slots,
//     launch: (data) => startGameFrom(data),                    // load: put the game back from a slot's data -> { ok, message?, hint? }
//     snapshot: () => ({ data: mySave(), chapter: 3, playTime: 3725.5 }),   // save: what goes into the slot
//     cannotSave: () => (cutscene ? "slots.busy" : ""),         // a string-table key saying why saving is not possible now, or ""
//     defaultName: () => i18n.t("level.title"),                 // the name of a save the player left unnamed
//     getPic: () => this.pic,                                   // the picture to keep with a save (capturePic() taken before the menu opened) or null
//   });
//   screen.open("save");  // or "load"
//
// Six rows: the autosave (never a save target) and the five slots, each with its picture, name, chapter and play time. Mouse, touch and
// gamepad all use the same Buttons. Saving a slot opens the dialog with a TextField for the name (the on-screen keyboard of
// scripts/ui/keyboard.js opens by itself for a gamepad player, and its entity is spawned here); Enter or Done saves, Cancel / Escape / B
// goes back. The host's ui.on("cancel") handler returns screen.cancel() first, which closes the dialog and consumes the press (ui_cancel).
// The cloud copies are compared when the screen opens (slots.syncCloud) and the rows are drawn again if one replaced a slot.
import { ui, i18n, world, scene, render } from "factoria";
import { MenuStack } from "./menu_stack.js";
import OnScreenKeyboard from "./keyboard.js";
import { formatTime } from "../slots.js";

export class SlotScreen {
  /**
   * @param {MenuStack} menus the host's panel stack
   * @param {object} opts
   * @param {import("../slots.js").Slots} opts.slots the records
   * @param {(data: any) => { ok: boolean, message?: string, hint?: string }} [opts.launch] load mode: starts playing from a slot's data; not ok = it shows `message` and `hint` on the screen. Without it the screen only saves.
   * @param {() => { data: any, chapter?: number, playTime?: number }} [opts.snapshot] save mode: what goes into the slot (the screen adds the name and the picture). Without it (and without `save`) the screen only loads.
   * @param {(id: number | string, save: { name: string, pic: string | null }) => (import("../slots.js").SlotRecord | null)} [opts.save] save mode, instead of `snapshot`: writes the slot yourself (slots.write) and returns the record, or null when the game cannot be saved now
   * @param {() => string} [opts.cannotSave] a string-table key that says why saving is not possible now ("" = it is); the save rows are greyed out and the key is the note under the title
   * @param {() => string} [opts.defaultName] the name offered for a new save (and used when the player clears the field)
   * @param {() => (string | null)} [opts.getPic] the picture to keep with a save (base64 PNG) or null
   */
  constructor(menus, opts) {
    this.menus = menus;
    this.slots = opts.slots;
    this.launch = opts.launch ?? null;
    this.snapshot = opts.snapshot ?? null;
    this.saveSlot = opts.save ?? null;
    this.cannotSave = opts.cannotSave ?? (() => (this.saveSlot || this.snapshot ? "" : "slots.noSave"));
    this.defaultName = opts.defaultName ?? (() => "");
    this.getPic = opts.getPic ?? (() => null);
    /** "save" | "load" */
    this.mode = "load";
    /** The line under the title: a result ("Saved to slot 2."), else why saving is not possible, else nothing. */
    this.message = "";
    /** @type {{ kind: "name" | "delete", id: any } | null} */
    this.dialog = null;
    /** Runtime textures of the pictures shown, freed before they are drawn again. */
    this.pics = [];
    this.kbWasOpen = false;
    for (const id of ["slots", "slot_dialog"]) {
      const panel = world.spawnPrefab(`prefabs/ui/${id}.prefab.json`);
      panel.id = id; // MenuStack shows panels by id
      panel.active = false;
    }
    // The on-screen keyboard for a gamepad player who names a save (it opens by itself on a TextField).
    world.spawn({ id: "keyboard_host", components: { Script: { path: "scripts/ui/keyboard.js" } } });
    for (const id of this.slots.ALL) {
      ui.on("click", `slot_${id}`, () => this.pick(id));
      ui.on("click", `delete_${id}`, () => this.openDialog("delete", id));
    }
    ui.on("click", "dialog_confirm", () => this.confirm());
    ui.on("click", "dialog_cancel", () => this.closeDialog());
    ui.on("submit", "save_name", () => this.confirm());
    i18n.on("change", () => this.menus.top === "slots" && this.refresh());
  }

  /** Call every frame: remembers whether the on-screen keyboard was open before this frame's presses. */
  tick() {
    this.kbWasOpen = OnScreenKeyboard.isOpen;
  }

  /**
   * The host calls this for Escape / the pad's B: while the dialog is on top it closes it (but not when the on-screen keyboard was open
   * at the start of the frame: that press only closes the keyboard) and returns true, so the host does not also go back.
   */
  cancel() {
    if (!this.dialogOpen) return false;
    if (!this.kbWasOpen) this.closeDialog();
    return true;
  }

  /** True while the dialog is the panel on top. */
  get dialogOpen() {
    return this.menus.top === "slot_dialog";
  }

  /** Shows the screen in mode "save" or "load". */
  open(mode) {
    this.mode = mode;
    this.message = "";
    this.menus.show("slots");
    this.refresh();
    this.focusFirst();
    const generation = scene.generation; // a reload of the same scene counts too
    this.slots
      .syncCloud()
      .then((changed) => {
        if (changed && scene.generation === generation && this.menus.top === "slots") this.refresh(); // the scene may be gone by now
      })
      .catch(() => {});
  }

  focusFirst() {
    let first = "slots_back";
    if (this.mode === "save") {
      if (!this.cannotSave()) first = "slot_1";
    } else {
      const id = this.slots.ALL.find((i) => this.slots.peek(i).status === "used");
      if (id !== undefined) first = `slot_${id}`;
    }
    ui.focus(world.find(first));
  }

  /** Frees the runtime textures (the host calls it when the scene goes). */
  dispose() {
    for (const id of this.slots.ALL) {
      const row = world.find(`pic_${id}`);
      if (row) row.get("Panel").texture = "";
    }
    for (const tex of this.pics) tex.destroy();
    this.pics = [];
  }

  /** Writes the rows from the slots. */
  refresh() {
    this.dispose();
    const reason = this.mode === "save" ? this.cannotSave() : "";
    let damaged = false;
    for (const id of this.slots.ALL) {
      const p = this.slots.peek(id);
      const auto = id === this.slots.AUTO;
      const button = world.find(`slot_${id}`).get("Button");
      if (p.status === "used") {
        const r = p.record;
        button.text = i18n.t(auto ? "slots.usedAuto" : "slots.used", {
          n: id,
          name: r.name || i18n.t("slots.unnamed"),
          chapter: r.chapter,
          time: formatTime(r.playTime),
        });
      } else if (p.status === "damaged") {
        button.text = i18n.t(auto ? "slots.damagedAuto" : "slots.damaged", { n: id });
        damaged = true;
      } else {
        button.text = i18n.t(auto ? "slots.emptyAuto" : "slots.empty", { n: id });
      }
      button.interactable = this.mode === "save" ? !auto && !reason : p.status === "used";
      world.find(`delete_${id}`).get("Button").interactable = p.status !== "empty";
      const pic = world.find(`pic_${id}`).get("Panel");
      if (p.status === "used" && p.record.pic) {
        try {
          const tex = render.textureFromPNG(p.record.pic);
          this.pics.push(tex);
          pic.texture = tex.id;
          pic.color = [1, 1, 1, 1];
        } catch (e) {
          console.warn(`slots: the picture of slot ${id} is not an image: ${e.message}`);
          pic.color = [0.08, 0.09, 0.12, 1];
        }
      } else pic.color = [0.08, 0.09, 0.12, 1];
    }
    world.find("slots_title").get("Text").text = i18n.t(this.mode === "save" ? "slots.titleSave" : "slots.titleLoad");
    const note = this.message || (reason ? i18n.t(reason) : damaged ? i18n.t("slots.damagedNote") : "");
    world.find("slots_note").get("Text").text = note;
  }

  pick(id) {
    const p = this.slots.peek(id);
    if (this.mode === "load") {
      if (p.status !== "used") return;
      this.dispose();
      const r = this.launch ? this.launch(p.record.data) : { ok: false, message: "this screen has no launch()", hint: "pass launch to the SlotScreen" };
      if (!r.ok) {
        this.message = `${r.message}. ${r.hint ?? ""}`;
        this.refresh();
      }
      return;
    }
    if (id === this.slots.AUTO || this.cannotSave()) return;
    this.openDialog("name", id);
  }

  /** Writes slot `id`; null when the game cannot be saved now. */
  write(id, typed) {
    if (this.cannotSave()) return null;
    const name = typed.trim() || this.defaultName();
    const pic = this.getPic();
    if (this.saveSlot) return this.saveSlot(id, { name, pic });
    if (!this.snapshot) return null;
    return this.slots.write(id, { ...this.snapshot(), name, pic });
  }

  openDialog(kind, id) {
    this.dialog = { kind, id };
    const name = world.find("save_name");
    const field = name.get("TextField");
    if (kind === "name") {
      const p = this.slots.peek(id);
      field.text = p.status === "used" ? p.record.name : this.defaultName();
      world.find("dialog_title").get("Text").text = i18n.t("slots.nameTitle", { n: id });
      world.find("dialog_confirm").get("Button").text = i18n.t("slots.confirmSave");
    } else {
      world.find("dialog_title").get("Text").text = i18n.t("slots.deleteTitle", { n: id === this.slots.AUTO ? i18n.t("slots.autoName") : id });
      world.find("dialog_confirm").get("Button").text = i18n.t("slots.confirmDelete");
    }
    this.menus.show("slot_dialog");
    name.active = kind === "name";
    ui.focus(world.find(kind === "name" ? "save_name" : "dialog_cancel"));
  }

  closeDialog() {
    this.dialog = null;
    this.menus.back(); // gives the focus back to the button that opened the dialog
    this.refresh();
  }

  confirm() {
    const d = this.dialog;
    if (!d || this.menus.top !== "slot_dialog") return;
    if (d.kind === "name") {
      const record = this.write(d.id, world.find("save_name").get("TextField").text);
      this.message = record ? i18n.t("slots.saved", { n: d.id }) : i18n.t(this.cannotSave() || "slots.busy");
    } else {
      this.slots.remove(d.id);
      this.message = "";
    }
    this.closeDialog();
    if (d.kind === "name") ui.focus(world.find(`slot_${d.id}`));
    else this.focusFirst();
  }
}
```

### `prefabs/ui/slots.prefab.json`

The panel: a row per slot (picture, name, chapter and play time, a Delete button) and a Back button.

```json prefabs/ui/slots.prefab.json
{
  "format": "factoria.prefab/1",
  "entity": {
    "name": "Slots",
    "components": {
      "Panel": {
        "size": [980, 640],
        "anchor": [0.5, 0.5],
        "layer": 300,
        "layout": "column",
        "spacing": 10,
        "padding": [20, 16, 20, 16],
        "color": [0.06, 0.07, 0.1, 0.97]
      }
    },
    "children": [
      {
        "id": "slots_title",
        "components": {
          "Text": {
            "text": "Save game",
            "fontSize": 36,
            "space": "screen",
            "layer": 301
          }
        }
      },
      {
        "id": "slots_note",
        "components": {
          "Text": {
            "text": "",
            "fontSize": 20,
            "space": "screen",
            "layer": 301,
            "maxWidth": 900
          }
        }
      },
      {
        "id": "slots_list",
        "components": {
          "ScrollList": {
            "size": [940, 420],
            "layer": 301,
            "spacing": 8,
            "padding": [6, 6, 6, 6],
            "color": [0, 0, 0, 0.25]
          }
        },
        "children": [
          {
            "id": "row_auto",
            "components": {
              "Panel": {
                "layer": 302,
                "color": [0, 0, 0, 0],
                "layout": "row",
                "spacing": 10,
                "padding": [0, 0, 0, 0],
                "fit": true
              }
            },
            "children": [
              {
                "id": "pic_auto",
                "components": {
                  "Panel": {
                    "size": [128, 72],
                    "layer": 303,
                    "color": [0.08, 0.09, 0.12, 1]
                  }
                }
              },
              {
                "id": "slot_auto",
                "components": {
                  "Button": {
                    "text": "Empty",
                    "size": [560, 72],
                    "layer": 303,
                    "fontSize": 22,
                    "autoShrink": true,
                    "minFontSize": 10
                  }
                }
              },
              {
                "id": "delete_auto",
                "components": {
                  "Button": {
                    "text": "Delete",
                    "key": "slots.delete",
                    "size": [150, 72],
                    "layer": 303,
                    "fontSize": 22,
                    "autoShrink": true,
                    "minFontSize": 14
                  }
                }
              }
            ]
          },
          {
            "id": "row_1",
            "components": {
              "Panel": {
                "layer": 302,
                "color": [0, 0, 0, 0],
                "layout": "row",
                "spacing": 10,
                "padding": [0, 0, 0, 0],
                "fit": true
              }
            },
            "children": [
              {
                "id": "pic_1",
                "components": {
                  "Panel": {
                    "size": [128, 72],
                    "layer": 303,
                    "color": [0.08, 0.09, 0.12, 1]
                  }
                }
              },
              {
                "id": "slot_1",
                "components": {
                  "Button": {
                    "text": "Empty",
                    "size": [560, 72],
                    "layer": 303,
                    "fontSize": 22,
                    "autoShrink": true,
                    "minFontSize": 10
                  }
                }
              },
              {
                "id": "delete_1",
                "components": {
                  "Button": {
                    "text": "Delete",
                    "key": "slots.delete",
                    "size": [150, 72],
                    "layer": 303,
                    "fontSize": 22,
                    "autoShrink": true,
                    "minFontSize": 14
                  }
                }
              }
            ]
          },
          {
            "id": "row_2",
            "components": {
              "Panel": {
                "layer": 302,
                "color": [0, 0, 0, 0],
                "layout": "row",
                "spacing": 10,
                "padding": [0, 0, 0, 0],
                "fit": true
              }
            },
            "children": [
              {
                "id": "pic_2",
                "components": {
                  "Panel": {
                    "size": [128, 72],
                    "layer": 303,
                    "color": [0.08, 0.09, 0.12, 1]
                  }
                }
              },
              {
                "id": "slot_2",
                "components": {
                  "Button": {
                    "text": "Empty",
                    "size": [560, 72],
                    "layer": 303,
                    "fontSize": 22,
                    "autoShrink": true,
                    "minFontSize": 10
                  }
                }
              },
              {
                "id": "delete_2",
                "components": {
                  "Button": {
                    "text": "Delete",
                    "key": "slots.delete",
                    "size": [150, 72],
                    "layer": 303,
                    "fontSize": 22,
                    "autoShrink": true,
                    "minFontSize": 14
                  }
                }
              }
            ]
          },
          {
            "id": "row_3",
            "components": {
              "Panel": {
                "layer": 302,
                "color": [0, 0, 0, 0],
                "layout": "row",
                "spacing": 10,
                "padding": [0, 0, 0, 0],
                "fit": true
              }
            },
            "children": [
              {
                "id": "pic_3",
                "components": {
                  "Panel": {
                    "size": [128, 72],
                    "layer": 303,
                    "color": [0.08, 0.09, 0.12, 1]
                  }
                }
              },
              {
                "id": "slot_3",
                "components": {
                  "Button": {
                    "text": "Empty",
                    "size": [560, 72],
                    "layer": 303,
                    "fontSize": 22,
                    "autoShrink": true,
                    "minFontSize": 10
                  }
                }
              },
              {
                "id": "delete_3",
                "components": {
                  "Button": {
                    "text": "Delete",
                    "key": "slots.delete",
                    "size": [150, 72],
                    "layer": 303,
                    "fontSize": 22,
                    "autoShrink": true,
                    "minFontSize": 14
                  }
                }
              }
            ]
          },
          {
            "id": "row_4",
            "components": {
              "Panel": {
                "layer": 302,
                "color": [0, 0, 0, 0],
                "layout": "row",
                "spacing": 10,
                "padding": [0, 0, 0, 0],
                "fit": true
              }
            },
            "children": [
              {
                "id": "pic_4",
                "components": {
                  "Panel": {
                    "size": [128, 72],
                    "layer": 303,
                    "color": [0.08, 0.09, 0.12, 1]
                  }
                }
              },
              {
                "id": "slot_4",
                "components": {
                  "Button": {
                    "text": "Empty",
                    "size": [560, 72],
                    "layer": 303,
                    "fontSize": 22,
                    "autoShrink": true,
                    "minFontSize": 10
                  }
                }
              },
              {
                "id": "delete_4",
                "components": {
                  "Button": {
                    "text": "Delete",
                    "key": "slots.delete",
                    "size": [150, 72],
                    "layer": 303,
                    "fontSize": 22,
                    "autoShrink": true,
                    "minFontSize": 14
                  }
                }
              }
            ]
          },
          {
            "id": "row_5",
            "components": {
              "Panel": {
                "layer": 302,
                "color": [0, 0, 0, 0],
                "layout": "row",
                "spacing": 10,
                "padding": [0, 0, 0, 0],
                "fit": true
              }
            },
            "children": [
              {
                "id": "pic_5",
                "components": {
                  "Panel": {
                    "size": [128, 72],
                    "layer": 303,
                    "color": [0.08, 0.09, 0.12, 1]
                  }
                }
              },
              {
                "id": "slot_5",
                "components": {
                  "Button": {
                    "text": "Empty",
                    "size": [560, 72],
                    "layer": 303,
                    "fontSize": 22,
                    "autoShrink": true,
                    "minFontSize": 10
                  }
                }
              },
              {
                "id": "delete_5",
                "components": {
                  "Button": {
                    "text": "Delete",
                    "key": "slots.delete",
                    "size": [150, 72],
                    "layer": 303,
                    "fontSize": 22,
                    "autoShrink": true,
                    "minFontSize": 14
                  }
                }
              }
            ]
          }
        ]
      },
      {
        "id": "slots_back",
        "tags": ["back"],
        "components": {
          "Button": {
            "text": "Back",
            "key": "menu.back",
            "autoSize": true,
            "layer": 302
          }
        }
      }
    ]
  }
}
```

### `prefabs/ui/slot_dialog.prefab.json`

The dialog that names a save or confirms a delete.

```json prefabs/ui/slot_dialog.prefab.json
{
  "format": "factoria.prefab/1",
  "entity": {
    "name": "SlotDialog",
    "components": {
      "Panel": {
        "anchor": [0.5, 0.5],
        "layer": 310,
        "layout": "column",
        "spacing": 14,
        "padding": [28, 24, 28, 24],
        "fit": true,
        "minSize": [560, 0],
        "color": [0.06, 0.07, 0.1, 0.97]
      }
    },
    "children": [
      {
        "id": "dialog_title",
        "components": {
          "Text": {
            "text": "Name this save",
            "fontSize": 30,
            "space": "screen",
            "layer": 311,
            "maxWidth": 520
          }
        }
      },
      {
        "id": "save_name",
        "components": {
          "TextField": {
            "size": [500, 52],
            "layer": 311,
            "maxLength": 28,
            "placeholder": "Name this save",
            "key": "slots.namePlaceholder"
          }
        }
      },
      {
        "id": "dialog_buttons",
        "components": {
          "Panel": {
            "layer": 311,
            "color": [0, 0, 0, 0],
            "layout": "row",
            "spacing": 12,
            "padding": [0, 0, 0, 0],
            "fit": true
          }
        },
        "children": [
          {
            "id": "dialog_confirm",
            "components": {
              "Button": {
                "text": "Save",
                "key": "slots.confirmSave",
                "autoSize": true,
                "layer": 312
              }
            }
          },
          {
            "id": "dialog_cancel",
            "components": {
              "Button": {
                "text": "Cancel",
                "key": "slots.cancel",
                "autoSize": true,
                "layer": 312
              }
            }
          }
        ]
      }
    ]
  }
}
```

### `tests/slots.test.js`

The kit's test of the slots part: records, the cloud merge, the screen's save, load and delete, and a cloud answer that arrives after the scene is gone.

```js tests/slots.test.js
// The save slots (scripts/slots.js) and their screen (scripts/ui/slot_screen.js): the record, the counter, a bare save, a damaged
// slot, the cloud merge by counter, the screen's save dialog (a name typed, the default name, cancel), loading, deleting (the cloud
// copy too) and a game that cannot be saved right now. The scene is built here, so this test passes in any game that has the slots part.
import { test, expect, game } from "factoria:test";
import { world, ui, storage, platform, scene } from "factoria";
import { MenuStack } from "../scripts/ui/menu_stack.js";
import { Slots, formatTime } from "../scripts/slots.js";
import { SlotScreen } from "../scripts/ui/slot_screen.js";

// A 1x1 PNG: a picture that is certainly valid, whatever a headless renderer captures.
const PNG = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg==";
const label = (id) => world.find(id).get("Button").text;

/** The slots of this test's imaginary game: its save is { level, gold } and a save with "old" in it is from a game version nobody can read. */
function makeSlots() {
  return new Slots({
    upgrade: (data) => (data.old ? { ok: false, message: "this save is from an older version", hint: "Delete the slot." } : { ok: true, data }),
    describe: (data) => ({ chapter: data.level, playTime: data.seconds }),
  });
}

/** Lets the store's answers through (they are Promises). */
async function settle() {
  for (let frame = 0; frame < 12; frame++) {
    for (let i = 0; i < 10; i++) await Promise.resolve();
    game.step(1);
  }
}

/** A clean run: empty storage, a signed-in fake store, an empty scene. */
function clean() {
  storage.clear();
  game.platform.reset();
  game.loadJson({ format: "factoria.scene/1", entities: [] });
  game.step(2);
}

/** The screen over a menu stack of its own, for a game that can always be saved except when `state.busy`. */
function openScreen(mode, state = { busy: false, level: 3, loaded: [] }, seed = () => {}) {
  clean();
  const slots = makeSlots();
  seed(slots);
  const menus = new MenuStack(null);
  const screen = new SlotScreen(menus, {
    slots,
    snapshot: () => ({ data: { level: state.level, gold: 40, seconds: 3725.5 }, chapter: state.level, playTime: 3725.5 }),
    launch: (data) => {
      state.loaded.push(data);
      return { ok: true };
    },
    cannotSave: () => (state.busy ? "slots.busy" : ""),
    defaultName: () => `Level ${state.level}`,
    getPic: () => PNG,
  });
  screen.open(mode);
  game.step(2);
  return { slots, menus, screen, state };
}

test("a record: counter, name, chapter, play time, picture and data; the counter goes up by one on every save", () => {
  clean();
  const slots = makeSlots();
  expect(slots.ALL).toEqual(["auto", 1, 2, 3, 4, 5]);
  expect(slots.key(2)).toBe("slot2");
  expect(slots.key("auto")).toBe("slot_auto");
  expect(slots.peek(1).status).toBe("empty");
  const a = slots.write(1, { data: { level: 2, gold: 5, seconds: 70 }, name: "  Before the cellar  ", chapter: 2, playTime: 70, pic: PNG });
  const b = slots.write(2, { data: { level: 3, gold: 9, seconds: 80 }, chapter: 3, playTime: 80 });
  expect([a.counter, b.counter]).toEqual([1, 2]);
  const p = slots.peek(1);
  expect(p.status).toBe("used");
  expect(p.record).toEqual({ counter: 1, name: "Before the cellar", chapter: 2, playTime: 70, pic: PNG, data: { level: 2, gold: 5, seconds: 70 } });
  expect(slots.peek(2).record.pic).toBe(null);
  expect(slots.last()).toBe(2);
  slots.remove(2);
  expect(slots.peek(2).status).toBe("empty");
  expect(slots.last()).toBe(null);
  expect(slots.write(3, { data: { level: 1 } }).counter).toBe(3); // a removed slot's counter is not given again
  expect(formatTime(3725.5)).toBe("1:02:05");
  expect(formatTime(-4)).toBe("0:00:00");
});

test("a bare save is read as a record without a name; text that is not a save damages the slot with a reason", () => {
  clean();
  const slots = makeSlots();
  storage.set("slot1", JSON.stringify({ level: 4, gold: 1, seconds: 125 })); // no "data" field: the game's save as it is
  const bare = slots.peek(1);
  expect(bare.status).toBe("used");
  expect(bare.record).toEqual({ counter: 0, name: "", chapter: 4, playTime: 125, pic: null, data: { level: 4, gold: 1, seconds: 125 } });
  storage.set("slot2", "{ not json");
  storage.set("slot3", "[1, 2]");
  storage.set("slot4", JSON.stringify({ counter: 3, name: "x", data: { old: true } }));
  for (const id of [2, 3, 4]) {
    const p = slots.peek(id);
    expect(p.status).toBe("damaged");
    expect(p.reason.length).toBeGreaterThan(0);
    expect(p.hint).toBeTruthy();
  }
  expect(slots.peek(4).reason).toBe("this save is from an older version");
  expect(slots.parse("{ not json").ok).toBe(false);
  expect(slots.nextCounter()).toBe(1); // counters of readable slots only: the damaged slot 4 (counter 3) does not count
});

test("the cloud: a save is uploaded, a delete removes the copy, the higher counter wins, failures never lose the local save", async () => {
  clean();
  const slots = makeSlots();
  slots.write(2, { data: { level: 1 }, name: "Cloudy" });
  await settle();
  expect(Object.keys(game.platform.state().fake.cloud)).toContain("slot2");
  expect(JSON.parse(await platform.cloud.load("slot2")).name).toBe("Cloudy");
  slots.remove(2);
  await settle();
  expect(Object.keys(game.platform.state().fake.cloud)).not.toContain("slot2");
  expect(await slots.syncCloud()).toBe(false);
  expect(slots.peek(2).status).toBe("empty");

  const rec = (counter, name) => JSON.stringify({ counter, name, chapter: 1, playTime: 10, pic: null, data: { level: 1 } });
  storage.set("slot1", rec(2, "local old"));
  storage.set("slot2", rec(9, "local new"));
  storage.set("slot3", "{ damaged");
  await platform.cloud.save("slot1", rec(4, "cloud new"));
  await platform.cloud.save("slot2", rec(3, "cloud old"));
  await platform.cloud.save("slot3", rec(1, "cloud only"));
  expect(await slots.syncCloud()).toBe(true);
  expect(slots.peek(1).record.name).toBe("cloud new");
  expect(slots.peek(2).record.name).toBe("local new");
  expect(JSON.parse(await platform.cloud.load("slot2")).counter).toBe(9); // the better local one went up
  expect(slots.peek(3).record.name).toBe("cloud only");

  game.platform.respond("cloud.save", { error: "network" });
  expect(slots.write(1, { data: { level: 1 }, name: "Offline" })).toBeTruthy();
  await settle();
  expect(slots.peek(1).record.name).toBe("Offline");
  game.platform.set({ backend: "none" }); // no store: nothing to do
  expect(await slots.syncCloud()).toBe(false);
  expect(slots.write(2, { data: { level: 1 }, name: "No store" })).toBeTruthy();
  game.platform.reset();
});

test("the screen saves: a click on a slot asks for a name; typing one and Save writes it with the picture", () => {
  const { slots, menus } = openScreen("save");
  expect(world.find("slots").active).toBe(true);
  expect(world.find("slots_title").get("Text").text).toBe("Save game");
  expect(world.find("slot_auto").get("Button").interactable).toBe(false); // the autosave is never a target
  expect(label("slot_1")).toBe("Slot 1: empty");
  expect(ui.focused.id).toBe("slot_1");
  game.click(world.find("slot_1"));
  game.step(2);
  expect(menus.top).toBe("slot_dialog");
  const field = world.find("save_name").get("TextField");
  expect(field.text).toBe("Level 3"); // the default name
  field.text = "";
  game.typeText("Pale oil");
  game.step(2);
  game.click(world.find("dialog_confirm"));
  game.step(2);
  const r = slots.peek(1).record;
  expect([r.name, r.chapter, r.playTime, r.pic]).toEqual(["Pale oil", 3, 3725.5, PNG]);
  expect(r.data).toEqual({ level: 3, gold: 40, seconds: 3725.5 });
  expect(menus.top).toBe("slots");
  expect(label("slot_1")).toBe("Slot 1: Pale oil\nChapter 3, 1:02:05");
  expect(world.find("slots_note").get("Text").text).toBe("Saved to slot 1.");
  expect(world.find("pic_1").get("Panel").texture).not.toBe("");
  expect(world.find("pic_2").get("Panel").texture).toBe("");
});

test("an empty name saves under the default one; cancel writes nothing and Escape closes the dialog before the screen", () => {
  const { slots, menus, screen } = openScreen("save");
  game.click(world.find("slot_2"));
  game.step(2);
  world.find("save_name").get("TextField").text = "   ";
  game.click(world.find("dialog_confirm"));
  game.step(2);
  expect(slots.peek(2).record.name).toBe("Level 3");
  game.click(world.find("slot_3"));
  game.step(2);
  expect(screen.dialogOpen).toBe(true);
  expect(screen.cancel()).toBe(true); // what the host's ui.on("cancel") handler asks first
  game.step(1);
  expect(menus.top).toBe("slots");
  expect(slots.peek(3).status).toBe("empty");
  expect(screen.cancel()).toBe(false); // nothing to close: the host goes back itself
});

test("the screen loads: only used slots can be picked, and the slot's data reaches launch()", () => {
  const state = { busy: false, level: 3, loaded: [] };
  clean();
  const first = makeSlots();
  first.write(4, { data: { level: 2, gold: 7, seconds: 9 }, name: "Night 4", chapter: 2, playTime: 9 });
  storage.set("slot5", "{ damaged");
  const menus = new MenuStack(null);
  const screen = new SlotScreen(menus, { slots: makeSlots(), launch: (data) => (state.loaded.push(data), { ok: true }) });
  screen.open("load");
  game.step(2);
  expect(world.find("slots_title").get("Text").text).toBe("Load game");
  expect(ui.focused.id).toBe("slot_4"); // the first used slot
  expect(world.find("slot_1").get("Button").interactable).toBe(false);
  expect(label("slot_5")).toContain("damaged");
  expect(world.find("slots_note").get("Text").text).toContain("cannot be read");
  game.click(world.find("slot_1"));
  game.step(1);
  expect(state.loaded.length).toBe(0);
  game.click(world.find("slot_4"));
  game.step(1);
  expect(state.loaded).toEqual([{ level: 2, gold: 7, seconds: 9 }]);
  screen.dispose();
});

test("a load that fails says why on the screen", () => {
  clean();
  const slots = makeSlots();
  slots.write(1, { data: { level: 1 }, name: "Broken" });
  const screen = new SlotScreen(new MenuStack(null), { slots, launch: () => ({ ok: false, message: "the level is gone", hint: "Start again." }) });
  screen.open("load");
  game.step(2);
  game.click(world.find("slot_1"));
  game.step(1);
  expect(world.find("slots_note").get("Text").text).toBe("the level is gone. Start again.");
});

test("a delete asks first and removes the slot and its cloud copy", async () => {
  const { slots } = openScreen("load", undefined, (slots) => slots.write(3, { data: { level: 1 }, name: "Under the stairs" }));
  await settle();
  expect(Object.keys(game.platform.state().fake.cloud)).toContain("slot3");
  expect(label("slot_3")).toContain("Under the stairs");
  game.click(world.find("delete_3"));
  game.step(2);
  expect(world.find("slot_dialog").active).toBe(true);
  expect(world.find("save_name").active).toBe(false); // a delete asks, it does not name
  game.click(world.find("dialog_confirm"));
  game.step(2);
  await settle();
  expect(slots.peek(3).status).toBe("empty");
  expect(label("slot_3")).toBe("Slot 3: empty");
  expect(Object.keys(game.platform.state().fake.cloud)).not.toContain("slot3");
});

test("a game that cannot be saved right now greys the slots out and says why", () => {
  const { slots, menus } = openScreen("save", { busy: true, level: 1, loaded: [] });
  expect(world.find("slot_1").get("Button").interactable).toBe(false);
  expect(world.find("slots_note").get("Text").text).toBe("You cannot save right now.");
  game.click(world.find("slot_1"));
  game.step(1);
  expect(menus.top).toBe("slots"); // no dialog
  expect(slots.peek(1).status).toBe("empty");
});

/** A screen opened while the cloud holds a better copy of slot 4; counts how often it draws its rows. */
async function openWithCloudCopy() {
  clean();
  const slots = makeSlots();
  await platform.cloud.save("slot4", JSON.stringify({ counter: 5, name: "From the cloud", chapter: 1, playTime: 1, pic: null, data: { level: 1 } }));
  const screen = new SlotScreen(new MenuStack(null), { slots });
  const counter = { draws: 0 };
  const draw = screen.refresh.bind(screen);
  screen.refresh = () => (counter.draws++, draw());
  screen.open("load"); // draws the rows once; the store's answer comes later, not before this test lets a frame or a Promise through
  return { slots, counter };
}

test("the cloud answer redraws the screen while its scene is current", async () => {
  const { counter } = await openWithCloudCopy();
  const before = counter.draws;
  await settle();
  expect(counter.draws).toBeGreaterThan(before);
  expect(label("slot_4")).toContain("From the cloud");
});

test("the cloud answer draws nothing into a scene that replaced the screen's", async () => {
  const { slots, counter } = await openWithCloudCopy();
  const before = counter.draws;
  const generation = scene.generation;
  game.loadJson({ format: "factoria.scene/1", entities: [] });
  game.step(2);
  expect(scene.generation).not.toBe(generation);
  await settle();
  expect(counter.draws).toBe(before);
  expect(slots.peek(4).record.name).toBe("From the cloud"); // the sync still stored the copy
});
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
