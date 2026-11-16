Part of [MENUS.md](../MENUS.md): What each part of the kit does and what to change in it.

# Menus: how

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
  (details: [TEXT.md](../TEXT.md), "Text that fits").
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
  age of consent ([PLATFORM.md](../platform/PLATFORM_ADS.md#children-and-consent)). The `ageGate` part is that question: with it, `main_menu.js` (the
  `main-menu` part without `ageGate` has no such line) opens the `age_gate` panel over the title screen, the first time, when `platform.ads.audience` is `"mixed"` (any other audience
  never sees it). The player picks a year of birth on a slider that starts at no particular year, or presses "I would rather
  not say"; the script computes `underAge` (born 16 or fewer years ago, or declined: the highest age of consent in Europe,
  and a year alone is off by one), calls `platform.ads.setUnderAge(underAge)`, and keeps **only that boolean** in
  `storage` (`ageGate`), never the year. The panel cannot be closed with Back or Escape. On the next runs the stored
  answer is sent again at start and the panel stays closed. A game that asks the age its own way calls
  `platform.ads.setUnderAge` itself and deletes this part. `tests/age_gate.test.js` drives the gate with the pad against the
  fake store.
- **Analytics question.** <a id="analytics-question"></a>`analytics.event()` sends nothing until the player said yes
  ([ANALYTICS.md](../ANALYTICS.md)), so a game with an `"analytics"` section in factoria.json asks once. With the `analyticsConsent` part,
  `main_menu.js` opens the `analytics_consent` panel over the title screen on the first run, when `analytics.consent()` is still `"unknown"`
  (the age gate comes first when the audience is `"mixed"`; a game without the section, or whose ad consent already answered it with
  `consentFromAds`, never sees the panel). "Allow" and "No thanks" both call `analytics.setConsent`, both are kept and the question does
  not come back; Back and Escape cannot skip it. The options panel has the matching switch (`analytics_toggle`, shown only when
  `analytics.configured`): the player changes the answer there at any time, and switching it off forgets what waited to be sent. Edit
  `analyticsConsent.what` in `locales/*.json` so the text says what your game really sends ([LEGAL.md](../LEGAL.md)).
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
- **Editing a TextField (caret, selection, clipboard, IME).** A focused `TextField` has a caret (`caretIndex`, a code-point
  index into `text`; focusing a field puts it at the end) and a selection (`selectionStart` is the anchor, `selectionEnd`
  the moving end, equal = nothing selected; the UI clamps all three to the text every frame). What the player does, with
  Cmd instead of Ctrl on macOS: typing inserts at the caret and replaces the selection; Left / Right move the caret (they
  repeat while held; with Shift they extend the selection, with the word key a word at a time: Ctrl, or Alt on macOS);
  Home / End go to the ends; Backspace and Delete remove the selection, else the character (or the word) before / after the
  caret, and repeat; Ctrl/Cmd+A selects all; Ctrl/Cmd+C copies the selection (nothing happens without one), Ctrl/Cmd+X cuts
  it, Ctrl/Cmd+V pastes at the caret over the selection. A paste drops newlines and control characters, stops at `maxLength`
  (never inside an emoji sequence) and sends `ui.change` once; the letter of the chord is not typed. `ui.change` carries the whole
  text at that moment, and a frame can send two (a click that commits an input method's composition, then characters typed in the
  same frame): the last one is the text the field has now. A press with the mouse
  or a finger puts the caret there, a drag selects, a double click selects the word under the pointer, a triple click all of
  it. Up / Down still move the focus. The caret never stops inside a base character and its combining marks, an emoji
  sequence or a flag. A scripted write is honoured at once, key or no key: `caretIndex` moves the caret, `selectionStart` /
  `selectionEnd` select a range (the caret follows `selectionEnd`), and a new `text` alone puts the caret at the end.
  `password: true` draws every character (and the composition) as `*`, switches Copy and Cut off, keeps the platform's input
  method off, and treats the whole text as one word (word keys and a double click go to its ends or select all); a script
  can still read `text` and `composition` of a password field, so never log them. A text wider than the field scrolls
  (`scrollX`, runtime) to keep the caret visible; a field that loses the focus keeps its last scroll. Left and right arrows are
  for the caret in a TextField, not for the focus; a gamepad's d-pad does the same. Not covered: right-to-left caret and
  selection (they assume left-to-right text for now: arrows move through the text in reading order, not on screen), Hangul
  and Indic cluster rules. Phones have no clipboard for games (`window.supports("clipboard")`; docs/SCRIPTING.md
  "Clipboard").
- **IME composition.** The runtime, read-only `composition` of the focused field holds the pre-edit string an input method is
  composing (never part of `text` until committed; scripts read `input.composing` / `input.compositionText`),
  `compositionCaret` and `compositionSelection` the IME's caret and the part it is converting. The field draws it at the
  caret, underlined, with the converted part highlighted and the caret inside it. While a field has the focus (and is not a
  password) the UI turns the platform's IME on and sends it the exact rectangle of the caret in framebuffer pixels
  (`ime_set_enabled`, `ime_set_caret_rect`, fa/platform/ime.h). While the player composes, Backspace, Delete, Home, End and
  the arrows belong to the input method; a click inside the field, or moving the focus to another field, commits the
  composition as typed text (once). Which platforms send composition events is the backend's: docs/TEXT.md, "Typing text".
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
