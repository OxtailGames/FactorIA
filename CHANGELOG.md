# What's new in FactorIA

The editor shows these notes when it offers an update, and each release on GitHub uses its section. Newest first.

## Unreleased

Menu kit command

- `project.add_menu_kit {parts, overwrite}` (`factoria call project.add_menu_kit`) copies the menu kit of `docs/MENUS.md`
  into a game: main menu, options, credits, shop, pause, loading screen, on-screen keyboard and subtitles, each part with
  what it needs. It merges the kit's texts into the game's `locales/<language>.json` without replacing a key, leaves a
  file the game changed alone unless `overwrite` is true, and does nothing the second time. The kit lives in
  `templates/menus/`. The Controls tab of the options leaves out an action the game does not have.

Text entry on every device

- A focused `TextField` raises the phone's keyboard and hides it on blur (not for gamepad players). The menu kit in
  `docs/MENUS.md` has an on-screen keyboard for gamepad players (Latin, Cyrillic and Greek layouts; other scripts fall
  back to Latin). The web player takes typed text on mobile browsers through a hidden input, and the web smoke types
  into a field.

A 3D example game for phones

- Clockwork Courier (`examples/clockwork-courier`) is a complete 3D game made for phones first, the way your AI makes a
  game: a wind-up robot delivers parcels across six toy-town levels before its spring runs down, with touch controls
  (stick, buttons, drag to orbit, pinch to zoom), keyboard and gamepad, imported CC0 models and sounds, guard dogs,
  physics props, a studio intro and a loading screen, achievements, leaderboards, a paint shop, a "remove ads" purchase
  and a rewarded "more time" offer on the test store, comfort and accessibility options (left-handed layout, control size,
  reduced motion, assist mode, captions), English, Spanish and Japanese, and store texts, images and a trailer. Its
  `SHIPPING.md` says how each export was run (iOS Simulator, Android emulator, browser, macOS) and what is still done by
  hand.

Sliders and lists

- `Slider.format` shows the value as a pattern: `"{v:1}x"`, `"{percent}%"` (the value times 100); `Slider.formatKey` takes the
  pattern from a string table, so it can differ per language. `game.setSlider(id, value)` in a test drags a slider like a
  player: clamped, snapped to `step`, `ui.change` sent (the `ui.set_slider` command); writing `Slider.value` from a script
  still sends nothing. `ScrollList.shrink` makes a list as tall as its content up to the room the other children leave, so a
  short list in a `fit` panel makes a short panel.

Tests

- `factoria:test` can hold a mouse button and turn the wheel (`game.mouseDown`, `mouseUp`, `wheel`), so a drag orbit and a
  wheel zoom are tested through the input path. `game.resetState({ storage, platform })` clears the save data and the fake
  store between tests of one file, `game.setSystemLanguages([...])` sets what `i18n.systemLanguages` answers, and a quit
  request in a test (`game.quit()`, Back nobody consumes) sets `game.quitRequested` instead of stopping the run.
  SCRIPTING.md says `scene.load` from a test takes effect next frame while `game.load` is immediate. The hook warning
  skips a method that takes arguments, like `start(seconds)`.

Animation

- Models animated by node transforms play with no change to the file: a body part that is a child of an animated bone
  (RobotExpressive) and an animated mesh node with no skin at all (Kenney's cube pets) follow their node, through a
  rigid skin the importer makes. A file with clips that nothing can play logs one warning naming the clips.
- A glTF with several skins is drawn with each mesh's own skin (it used the first skin's palette for all, which bent the
  second skin's mesh out of shape). `Animator::skinPalettes` holds one palette per skin. Clockwork Courier imports the
  original robot and dog again and drops `tools/skinify.py` (FB-0001, FB-0002).

Graphics quality

- `window.renderScale` (0.5 to 1) draws the picture at a share of the window's size, in games and in tests;
  `window.supports("frameCap" | "renderScale" | "fullscreen" | "resize")` says what this run can do (the frame cap still
  throws on a phone: read it first); `game.device` gives `formFactor`, `gpuBackend`, `memoryGB` and a `tier` (`"low"`,
  `"medium"`, `"high"`) to pick a preset, with fixed values headless; tests pretend with `game.setDevice(...)`.
- `game.renderStats()` in tests (and the `game.render_stats` command) draws a frame when none was drawn yet and adds
  `shadowCasters` and `textureMB`. `perf.measure` records `triangles`, `lights` and `textureMB`; `perf.check` fails when
  they pass the baseline (only for baselines that have them) or the new `budgets` (`maxTriangles`, `maxLights`,
  `maxTextureMB`, `maxDrawCalls`, `maxEntities`).

Rendering

- `MeshRenderer.materialColors` colours one material of a glTF model: `{"Body": [0.2, 0.8, 0.7, 1]}` replaces the
  base colour factor of the material named "Body" on its sub-meshes (its texture still multiplies it), while
  `color` keeps tinting the whole model and the other materials keep their own colour. Entities that differ only in
  `materialColors` are drawn in separate batches. `factoria validate` checks the names against the model and suggests
  the right one for a typo (FB-0031).

Scripts

- `scene.preload(path)` and `assets.preload(paths)` read a scene's files (or a list of assets) ahead of time, a few per
  frame, and return a handle with `progress` (0..1), `done` and a `promise`: a loading screen keeps animating while the
  next level is read, and the `scene.load` that follows reads nothing from the disk. Tests do a fixed amount of work per
  frame, so they give the same result on every machine; `game.fileReads()` counts disk reads. Clockwork Courier's
  loading bar now shows real progress and its intro reads the title screen while it plays (FB-0012).

Platform services

- Ads: the new `platform.ads` service (`available(placement)`, `showRewarded(placement)` resolving `{rewarded, reason?}`
  and `consent()`) works with the placements of `factoria.json` `platform.ads.placements`, and `platform.release` is
  false in development runs, tests and the MCP server. The fake store answers with a scripted test ad (nothing is
  drawn): `game.platform.ad("watched" | "closedEarly" | "noFill" | "consentRefused")` chooses how it ends (command `platform.set_ad`). The real
  networks (Google UMP and AdMob, Apple ATT) are not in yet: the native backends answer `unavailable`.
- A leaderboard takes `period`: `"allTime"` (default), `"daily"` or `"weekly"`. The fake keeps one board per day or
  week of `game.today()`, so a daily board is empty again after `game.setDate` moves to the next day; a store backend
  rejects a daily or weekly board with `unavailable` until its recurring boards are mapped.
- Clockwork Courier uses them instead of its ad stub and its single daily board (FB-0028, FB-0030).
- The fake store can take a purchase back, as a refund does: `game.platform.revoke(productId)` in tests (command
  `platform.revoke`) removes it from `restore()` and sends the `purchase` event with `status: "revoked"`.
- `platform.purchases.finish()` of a transaction the game was not told about now rejects its Promise with code
  `unknownId` (it used to throw at the call), so `.catch()` handles it like any store failure.
- Leaderboards in factoria.json take a `nameKey` (a locale key) instead of `name`, like achievements; the request
  the backend gets carries the name in the current language. PLATFORM.md documents `game.project.platform`, the
  catalog scripts can read.

Localization

- Numbers and times follow the language: `{v:number:1}` and `{t:duration}` in a string table and `i18n.number(v, {decimals})`
  and `i18n.duration(seconds)` in scripts write 1234.5 as "1,234.5", "1234,5" (Spanish; "12.345,5" from five digits),
  "1.234,5" (German), "1 234,5" (French, narrow no-break space) or "١٬٢٣٤٫٥" (Arabic digits), and 83.4 seconds as "1:23.4".
  A small table in the engine, no ICU; a language it does not know is written like English (docs/LOCALIZATION.md).
  Clockwork Courier uses it instead of its own helper (FB-0039).
- `keyArgs` on `Text`, `Button`, `Toggle`, `Slider`, `TextField` and `TouchButton`: the values of a key's `{placeholders}`
  (and the `count` of a plural entry), so a script sets them once instead of rewriting `text` every frame, and a language
  switch keeps them. `TouchButton` has a localization `key` like the other widgets. `factoria validate` checks a key's
  placeholders against the entity's `keyArgs`: it warns for a placeholder with no arg and for an arg no translation uses,
  not for every key with placeholders.
- `ui.check_layout {scenes, languages, textScales, pseudo}` loads each screen with UI in each language and text size
  (default: every language, scales 1 and 2) plus a pseudo-localized pass that lengthens every string by 40 %, and lists
  every text that overflows its box (the `ui.overflowed` test), overlaps another or leaves the screen, with the scene,
  the entity and its path, the key and the languages and scales where it happens. Clockwork Courier's profile keys and
  intro texts that broke at 200 % now shrink (FB-0043).

Tools

- `scene.format` with neither `paths`, `all` nor `check` writes nothing and fails with `paths_required`, saying how many
  scene and prefab files would change and the first ones; `paths` names the files or folders to format and
  `"all": true` takes the whole project. `factoria validate`'s hint names the files.
- `project.new_plugin` and `platform.add_backend` take `dryRun` (they list the `files` and the `keys` of
  `factoria.json` they would write, and write nothing) and refuse an argument they do not know, with a "did you mean".
- They patch `factoria.json` instead of rewriting it: only `plugins.<name>` is added, and the other keys, their order
  and the layout stay as they were. `export` and `icon` saves (the editor, `assets.draw_icon`) use the same patcher.
- The plugin templates come with a `.gitignore` for their build output.
- `factoria api --dts` lists a native plugin that is not built without its load error, so the typings no longer
  carry this machine's folders and come out the same on every machine.

Exports and store files

- `Products.storekit` is written by every iOS export whose catalog has products, with or without the Apple plugin, and
  holds one localization per language of the game (names and descriptions from the products' `titleKey` /
  `descriptionKey` in `locales/`).
- An Android source build reads the CMake version it will use instead of requiring `cmake;3.31.6`: the SDK's, else the
  newest 3.24+ in the SDK, else a 3.24+ of the computer (passed to Gradle as `cmake.dir`), so it works offline. The error
  hint says how to get one.
- `factoria` and `factoria_player` carry a build fingerprint (the commit, `-dirty` when it had uncommitted changes;
  `factoria version` prints it). A desktop export with a player from another build stops with an error that names both
  builds; `--allow-player-mismatch` (the `export` command's `allowPlayerMismatch`) bundles it anyway.
- `setup.install {"component": "ffmpeg"}` (`factoria setup ffmpeg`) downloads a pinned static ffmpeg, so
  `factoria run --record-video trailer.mp4` works without installing it by hand; `setup.status` lists the component.

Assets

- `assets.import` of a `.glb` or `.gltf` copies the textures and buffers its `uri`s point at next to the model (with
  provenance), shares an identical file already there, warns when the destination holds a different image of the same
  name (kits that ship different `colormap.png` files) and stops on a different buffer; `factoria validate` reports a
  model whose texture or buffer file is missing.
- `assets.set_provenance` (and every command that edits `assets.json`) keeps the order of a hand-ordered file instead of
  sorting all of it; a sorted file stays sorted.
- `factoria validate`'s loudness warnings use the sound as it plays: a project with `defaults.audio.normalize` has no
  peak or loudness warning left for it.
- New `assets.synth_sound {path, preset, seed}` makes barks, growls, meows and the usual effects (coin, jump, hit,
  explosion, laser...) offline as a deterministic WAV, with its provenance; no provider and no key.

Physics

- 3D physics no longer depends on what the World held before a scene loaded: `Joint3D` constraints are solved in the
  scene's entity order instead of the order of their entity ids, so a rope bridge or a seesaw behaves the same after
  other scenes, destroyed entities or reused entity slots (a level test could take 2000 or 2800 frames depending on
  which tests ran first).
- `CharacterController3D` on moving and dynamic bodies: a kinematic platform it stands on carries it (displacement, and the
  turn of a spinning platform; `carriedByPlatforms`, default true), it presses on the dynamic body below with
  `mass` x gravity (`applyWeight`, `mass`), so a seesaw tips and a bridge plank sags, and `pushStrength` scales the push on
  the free dynamic bodies it walks into (a body held by a `Joint3D` is never shoved). Clockwork Courier dropped its
  workarounds (FB-0010, FB-0011).
- A dynamic body that starts inside a static collider is reported once in the log (both entities, the depth and the fix),
  and `factoria validate` warns about it for scenes.
- Joints form islands: a chain of planks falls asleep when it is at rest, a collision in one island no longer stops the
  rest of the world, and two bridges side by side move exactly as each would alone. Chains of three or more jointed
  bodies get more solver iterations and settle by themselves, so a rope bridge no longer needs heavy damping
  (FB-0014, FB-0015, FB-0017, FB-0053, FB-0054).
- `Joint3D.damping` (friction on the relative turning) and `Joint3D.stalled` (read only: a motor pushes and the joint
  cannot turn, for example a gate against a wall). `docs/AI_GUIDE.md` has a rope bridge recipe.
- `connected: ""` means the world on `Joint3D` and `Joint2D` in scenes, `factoria validate` and scripts.

Navigation

- Path finding for 3D characters. A `NavMesh3D` component (`size`, `cellSize`, `agentRadius`, `agentHeight`,
  `stepHeight`, `maxSlope`) is baked by itself from the static colliders inside its box into a walkable grid;
  `nav.findPath(from, to, { radius })` in scripts and `nav.find_path` return the few corner points of a path around
  walls and up ramps, never up a step above `stepHeight`. A start or goal off the walkable ground, or in another
  area, comes back as a result that says how far the nearest walkable point is and how to fix it; a `radius` bigger
  than the mesh was baked for is an error that says to bake for the bigger agent. `nav.bake` and `nav.info` report the
  cells and areas (no timing: two bakes are identical). A collider with `navObstacle` is left out of the bake and blocks
  the cells it covers each time it moves (a gate, a crate). The editor draws the walkable cells (Window > Show navmesh).
  Guide: docs/NAVIGATION.md (FB-0009).

Native plugins

- `"optional": true` on a plugin in `factoria.json` says the game runs without it: when its build for your computer is
  missing (a store SDK only some developers build), `factoria validate` warns instead of failing. Exporting for a
  platform still needs that platform's build.

Mac App Store

- `sign.macos` takes `distribution: "appStore"`: it signs the macOS export with the App Sandbox, an Apple Distribution
  certificate and a provisioning profile, and builds the signed installer `<game-slug>-macos.pkg` with `productbuild`.
  `identity: "-"` signs ad hoc so you can run the sandboxed game on your own Mac.
- `publish.appstore` uploads that `.pkg` too (`platforms: ["macos"]`).
- New `export.macos` settings: `buildNumber`, `usesNonExemptEncryption` and `entitlements`.

Microsoft Store

- `factoria export --platform windows --format msix` (or `export.windows.format: "msix"`) writes
  `<slug>-windows.msix` next to the Windows folder, from any computer: the unsigned package the Microsoft Store takes, with
  the manifest, the logos cut from your icon and the block map. The identity comes from the new `export.windows.msix`
  settings (the editor's Windows tab and Export window have them).
- New `sign.windows` signs the package with your `.pfx` (`signtool`, or `osslsigncode` on macOS and Linux) to install it on
  a PC; on Windows `testCertificate` makes a self-signed one. The password is only read from the environment.
- New `publish.microsoft` uploads the package with the Microsoft Store Developer CLI.
- The web export and the AppImage use a shared zip writer; their bytes did not change in meaning.

Scripting

- New `game.today()` returns `{ year, month, day, weekday, utcOffsetMinutes, iso }`: the player's real local date in a
  built game, the fixed date `2026-01-01` in `factoria test` and headless runs, and the date a replay recorded when it
  plays (an old replay without one uses the fixed date). `game.setDate("YYYY-MM-DD")` in `factoria:test` changes it, and
  `--date` does the same for `run`, `screenshot`, `test`, `call`, `session` and `mcp`. An impossible date (`2026-02-29`)
  or another format is an error that says what is wrong. Read the date with `game.today()`, never `Date`.
- New `game.on("suspend" | "resume" | "focus" | "blur", fn)` and `game.focused` tell scripts when the app goes to the
  background and back, or the window loses the focus. The new `factoria.json` setting `pauseOnSuspend` (default `true`)
  pauses the game and the music while the app is in the background; `game.suspend()`, `game.resume()`, `game.focus()`
  and `game.blur()` in `factoria:test` test it. A pause menu opened by a `suspend` handler stays after resume.
- Clockwork Courier uses the date and the lifecycle API instead of its workarounds (FB-0019, FB-0035).
- `factoria test` no longer stops a test file after 600 s in all: only a single test over 60 s is stopped, so a long file
  of quick tests passes in a Debug build on a busy machine. The message says which limit it was.

UI

- A child can be put at a place among its siblings, which is the order a `column` or `row` layout follows:
  `scene.set_parent {id, parent, index}` (also `scene.spawn {index}`), `entity.setParent(parent, keepWorld, index)` and
  `world.spawn(json, { parent, index })` / `world.spawnPrefab(path, { parent, index })`. 0 is first; an index outside
  0..(number of the parent's other children) is an error that says the range. The order is saved with the scene.
- One panel can serve several scenes: a prefab reference takes `overrides`, a map from a child of the prefab (its id,
  name or a path like `"Panel/Title"`) to the `name`, `tags`, `active` and `components` to change, and
  `world.spawnPrefab(path, { childOverrides })` and `scene.spawn {prefab, overrides}` do the same. A child or field that
  does not exist is an error with a "did you mean". docs/MENUS.md shows it. Clockwork Courier's FB-0032 and FB-0023.
- Text that fits: `autoShrink` (with `minFontSize`, default 10) on `Text`, `Button`, `Toggle`, `Slider` and `TouchButton`
  shrinks the font until the text fits its box (`Text.maxWidth` x the new `Text.maxHeight`, or the room the widget leaves
  its label), never under `minFontSize` times `ui.textScale`. `maxTextScale` on `Text`, every widget and `TouchButton`
  stops `ui.textScale` from growing that text past a scale (a heading at 1.3). `Toggle.maxWidth` and `Slider.maxWidth`
  wrap long labels, `Slider.labelAbove` puts the label above the track. Layout, `autoSize`, `ui.measureText` (new
  options, returns `fontSize` too), `ui.rectOf` and the 2D and 3D renderers use the same size.
- New `ui.overflowed(idOrEntity)` and `"overflowed": true` in `ui.state` say a text still does not fit its box.
- Clockwork Courier dropped its text-fit workarounds in the level select, HUD, toasts and options (FB-0041, FB-0042).

## 0.2.0

FactorIA 0.2.0 is about finishing and shipping a game: edit scenes by hand next to your AI, translate the game, add
achievements and purchases on Steam, the App Store and Google Play, and export it for desktop stores, phones and the
browser.

Edit by hand in the editor

- The editor has a Hierarchy and an Inspector now. The Hierarchy lists every entity as a tree: click one to select it (a
  click in the game view selects it there too), drag it onto another to make it a child, drop it on the empty space to
  make it a top-level entity, and right-click for create child, duplicate, rename, active and delete. There is a search box.
- The Inspector shows the selected entity's components with a field for every value: tick boxes, number drags that
  respect each field's range, vectors, colour pickers, drop-downs for choices and for other entities, file pickers for
  pictures, sounds and materials, and a text box for free-form JSON. Hover a name to read what it does. Add Component and
  the x on a component's header add and remove components.
- Everything you change by hand goes through the same commands the AI uses, so Undo works (one drag is one step) and a
  value a field does not accept is refused with the reason. While the game plays you can edit the running game; Stop
  takes those edits back.
- A `MeshRenderer` shows its material's settings with the right widgets (sliders, vectors, colour pickers) and a Reset
  button for each, and a material that does not compile shows its error right under the material field.
- The new Project panel (a tab next to Console, also in the View menu) lists the project's files with thumbnails, a folder
  tree, a type filter and a search box. Drag a picture, sound, font, mesh, script or material onto an Inspector field of that
  type to set it, drag a prefab onto the game view to spawn it where you drop it, double-click a scene to open it, and
  right-click a file to show it in the file manager, copy its path or delete it. `assets.list` now also reports `material`
  for `.material.json` files.
- New command `scene.set_parent` moves an entity under another one (or to the top level), for the AI too.
- Move, rotate and scale in the game view: select something and drag the arrows (W), the rings (E) or the handles (R) that
  appear on it; Q goes back to just selecting. The four buttons next to Undo do the same. Hold Ctrl to snap, press Esc in
  the middle of a drag to cancel it. A whole drag is one Undo step, it works for 2D and 3D, for things on the screen (like
  a score) and for things inside another, and while the game is paused it edits the running game.

Revert an AI run

- Before each AI run the editor now saves a checkpoint of the project's files. When the run changed something, the chat
  shows "This run changed N files" with a Revert button: one click (after a confirmation) puts back every file, deletes the
  ones the run created and puts the scene back as one Undo step. Undo revert takes it back, and Edit > Revert Last AI Run
  does the same from the menu. The AI is told about the revert in your next message. Checkpoints are kept in
  `.factoria/checkpoints/` (newest 30) and are also available as the commands `checkpoint.create`, `checkpoint.list`,
  `checkpoint.diff` and `checkpoint.restore`.

Debug your scripts in VS Code

- Press F5 in VS Code on a FactorIA project: the game starts and stops on your breakpoints. Step through your code line
  by line, look at every variable and at `this`, watch expressions, and type JavaScript in the debug console to read or
  change the running game. `factoria setup vscode` (or Install in the editor's Setup window) adds the extension to VS
  Code, and to Insiders, VSCodium and Cursor when you have them; new projects come with a `.vscode/launch.json`.
- Breakpoints can have a condition, a hit count or a message to print instead of stopping (a logpoint, with
  `{expressions}` filled in). The debugger can stop on every error your scripts throw or only on the ones nothing
  catches, and Pause stops the game wherever it is, even in an endless loop.
- Three ways to start: play the game in its window, run it without a window for a number of frames (with an input
  replay), or run your tests and stop inside them.
- For the AI: `script.trace` puts the same breakpoints on a headless run and returns what it saw as JSON (the call stack,
  the local variables and your watch expressions at each hit, and the logpoint lines), so it can find out why a script
  misbehaves without guessing. See `factoria docs read debugging`.
- Exported games cannot be debugged: debug the project.

Find out what makes your game slow

- A profiler: it tells you where the time of a frame goes, per part of the engine (physics, scripts, sound, drawing...) and
  per script class, with the milliseconds each class takes per frame and how often it runs, plus the GPU time (on
  Windows and Linux; other systems say why not) and memory use. It only measures: your game plays exactly the same.
- In the editor, View > Profiler shows it live while you play. Every play session you record now also keeps this
  summary in `play.report`, so the AI can see which script is the slow one.
- `perf.profile` does the same on a headless run, with an optional input replay to reach the heavy part of the game. See
  `factoria docs read performance`.

Your game in every language

- Keep your texts in string tables (`locales/en.json`, `locales/es.json`...) and show them with a `key` on a `Text` or an
  interface widget, or with `i18n.t("score", { points: 3 })` in scripts: placeholders, plural forms for each language and
  a fallback language are built in. The game starts in the player's system language, and `i18n.setLanguage("es")`
  switches at any moment, every text at once.
- Text is laid out properly in every script: Arabic letters join and right-to-left lines start from the right, Chinese,
  Japanese and Korean lines break between characters, and fallback fonts (`fallbackFonts` for the whole game,
  `languageFonts` per language, in the `localization` part of `factoria.json`) fill in the characters your main font
  does not have.
- A text size option for players: `ui.textScale` makes every on-screen text and widget label bigger or smaller.
- `factoria validate` finds missing and leftover keys (with "did you mean"), wrong placeholders and plural forms, and
  any character none of your fonts can draw, naming the text and the file.
- Send your texts to translators as a spreadsheet (CSV) or an XLIFF file with the command `i18n.export`, and bring the
  translations back with `i18n.import`.
- `factoria docs read localization` is the guide, and the ready-made menus have a Language option.

Achievements, leaderboards, cloud saves and purchases

- One script API for what a store gives a game: `platform` has achievements, stats, leaderboards, cloud saves, in-game
  purchases (with restore), the store's overlay and rich presence. You write your game once, and the store it runs in
  answers. List your achievements, leaderboards and products in the `platform` part of `factoria.json`.
- Steam, Apple (App Store purchases, Game Center, iCloud) and Google Play (Play Billing, Play Games, Play Integrity):
  `factoria call platform.add_backend '{"backend": "steam"}'` (or `"apple"`, `"googleplay"`) sets one up in one step and
  lists what is left for you to do in the store's dashboard.
- While you make the game, and in every test, a pretend store answers, so your AI can test a purchase, a cancelled one
  or an achievement without a store account. An exported game with no store set up never gives purchases away.
- `platform.integrity.token` gives your game's server a signed token that vouches for the app and the device (Google
  Play).
- So far these were tried against simulated stores only: make a test purchase with the store's sandbox or test account
  before you release. `factoria docs read platform` is the guide.

Ready for the desktop stores

- `factoria export --release` on Windows, macOS and Linux puts the whole game in one file, `game.pak`, with the scripts
  compiled to bytecode. Exports no longer copy the project's top-level `README.md`.
- When an exported game crashes it writes a report (what happened, where in the code, the last lines of the log) in a
  `crashes` folder next to `log.txt`, plus a minidump on Windows. Nothing is sent anywhere: a player can send it to you.
- Upload your game to Steam (`publish.steam`, with steamcmd), itch.io (`publish.itch`, with butler), the Epic Games
  Store (`publish.epic`, with BuildPatchTool) and GOG (`publish.gog`, with Galaxy Pipeline Builder) from your AI or the
  command line, each with a dry run to try first. Passwords and keys stay in environment variables or your user
  folder, never in the project.
- macOS: `factoria call sign.macos` signs your exported app with your Developer ID, has Apple notarize it and staples
  the ticket, so players can open it without a warning.
- Linux: `factoria export --platform linux --format appimage` makes the game one AppImage file with its icon and menu
  entry. Linux games exported from the FactorIA download now run on older systems and in the Steam Linux Runtime (glibc
  2.31 or newer).
- `factoria call project.new_ci_workflow` writes a GitHub Actions workflow that validates, tests and exports your game on
  every push.

Phones and tablets

- Change to know about: `factoria export --platform android --release` now stops when your game has no signing key,
  because Google Play rejects an app signed with the debug key. The message tells you how to make a key. To try a release
  build on your own phone anyway, add `--allow-debug-key` (the export command's `allowDebugKey` option).
- Menus and heads-up displays can keep clear of the notch, rounded corners and system bars: switch on `safeArea` next to
  `anchor` on a sprite, text, shape, particle emitter or interface widget, and it is placed against the free part of the
  screen. Scripts can read it as `screen.safeArea`. You can try a notched phone without one with
  `screen.set_safe_area {"profile":"phone-portrait"}`.
- The Android Back button and gesture now reach your game as `input.onBack`: close a menu or go up one screen and the game
  stays open. If nothing handles it the game closes, as before.
- `input.vibrate()` makes a phone vibrate (a light tap on iPhones). Exported Android games include the permission for it.
- Android games can raise the on-screen keyboard for text fields and receive what is typed. Keyboards that compose words
  (predictive text, swipe typing, emoji, Asian languages) still cannot type into an Android game; physical keyboards work.
- An on-screen gamepad for games made for a controller: add a `TouchStick` and a few `TouchButton`s to a scene and players
  move with the thumb and press A, B... on the screen. They press the same gamepad buttons and stick a real controller
  does, so your game needs no other change. Several fingers work at once, the controls stay clear of the notch, and they
  only show while the player is using touch (they hide when a real controller or keyboard is used).
- Tests can press Back, fake a notch, check vibrations and touch the on-screen gamepad without a device.
- iPhone and iPad exports include the privacy file the App Store asks for (`PrivacyInfo.xcprivacy`), listing the few
  system features FactorIA uses and saying that nothing is collected or tracked. If your game or a plugin collects data,
  tracks players or uses more system features, add them under `export.ios.privacy` in `factoria.json`; mistakes in it are
  reported with the fix. The app also says it uses no special encryption, so App Store Connect stops asking at every
  upload (`export.ios.usesNonExemptEncryption` changes it).
- `factoria setup players --platforms mobile` now also downloads the iPhone and iPad libraries on Windows and Linux, so
  you can prepare an iOS project there without pointing at a macOS download. Building it still needs a Mac.
- The mobile guide lists what to answer in Google Play's Data safety form and in App Store Connect's App Privacy section.

Upload your phone builds

- Upload your iOS build to TestFlight and App Store Connect from your AI or the command line (`publish.appstore`,
  on a Mac): you archive the game in Xcode as before, FactorIA sends the `.ipa` with an App Store Connect API key. Run it
  with `dryRun` first to see the exact command.
- Upload your Android release bundle to Google Play (`publish.googleplay`, needs fastlane): pick the track (internal
  testing by default), leave the release as a draft or roll it out, and send the "What's new" text per language from
  files of your project. A bundle signed with the debug key is refused before anything is sent. Google Play still wants the
  first bundle of a new app uploaded by hand.
- Your keys stay in files outside the project and are never shown or logged.

Games in the browser

- Export your game for the web: `factoria export --platform web` (or Web in the editor's Export window) makes a folder
  with an `index.html` that plays the game in any modern browser, and a `.zip` of it ready to upload to itch.io as an
  HTML5 game. The page shows a loading bar and explains in plain words when something is wrong (an old browser, a
  download that failed).
- In the browser, saves made with `storage` are kept between visits, sound starts with the player's first click or key,
  and gamepads work. Native plugins and store services (achievements, purchases) are not available on the web.
- The web player comes with every FactorIA download; `factoria setup players --platforms web` installs it if you need it.

Better looking 3D, and much bigger 3D scenes

- Materials look like real materials: `metallic` and `roughness` now use physically based shading, and shiny surfaces
  reflect the sky of your scene (`skyColor` and `horizonColor`), so a metal sphere looks like metal without any extra
  file. Scenes you already have look close to before, with a faint sheen on plastic and stone.
- Normal maps: give a `MeshRenderer` a `normalMap` picture to add bumps, scratches or bricks without extra triangles, and
  `normalScale` to make them stronger or softer.
- glTF models keep their materials: metallic and roughness (with their textures), normal maps, ambient occlusion and
  glowing parts are read from the file. Models without tangents get them generated.
- Big scenes are cheaper: anything outside the camera's view is skipped, and many copies of the same mesh with the same
  material are drawn together. Ten thousand identical cubes now cost one draw.
- Up to 32 lights at once instead of 8. With more, the engine keeps the sun and the brightest, nearest lights.
- The render statistics (`play.report`) now also count `meshesCulled`, `meshBatches` and `lightsDropped`.
- Your own shaders: a `MeshRenderer` can use a material file (`material`) with a few lines of GLSL that change how the
  surface looks (a pulsing glow, cut-out leaves, moving water) or move its vertices. Shadows follow the moved or cut-out
  shape, each entity can change the material's values (`materialParams`), and a change to the file shows up at once
  while the game runs. A material that does not compile draws magenta and says which line is wrong.
- A new guide for your own shaders (`factoria docs read shaders`): how to write a material, the rules for its few lines
  of GLSL, and five ready examples: a pulsing glow, dissolving, water, wind on grass and a rim light. The shader
  compiler comes with FactorIA, next to `factoria` in every download, so there is nothing to install. If Windows
  Defender removes `sokol-shdc.exe` by mistake, restore it from Windows Security > Protection history, or run
  `factoria setup shaders` to get it again.
- In the editor, saving a material, a shader or a texture updates the game view right away, while editing and while
  playing. A mistake in a shader keeps the last picture that worked and shows one error in the Console with the file
  and the line.
- The Gem Roller example has glowing, pulsing gems made with a custom material.
- Not yet: an environment picture for reflections.

Animation

- 3D models with skeletons: a glTF/GLB with named animation clips plays through the new `Animator` component, which goes on
  the entity with the model's `MeshRenderer`. Switch clips with a smooth cross-fade (`entity.animator.play("Run", 0.2)`),
  change the speed, and get an event when a clip reaches a moment you chose (a footstep at 0.3 s) with `world.on`.
- A small state machine is built in: list the parameters, the states (a clip each) and the transitions in the scene file
  (`"when": "speed > 0.1"`), then your script only sets values: `entity.animator.set("speed", 3)`. Animation runs in the
  fixed step, so tests and replays give the same result every time.
- New `tween` and `ease` in the scripting API: slide a menu in, fade a sprite, grow a pickup. Works on numbers, vectors
  and colors of anything, in 2D and 3D, with 30 easings (`"backOut"`, `"bounceOut"`...), delay, repeat, yoyo, chaining and
  `await tween(...).finished`.
- Animated models are drawn deformed by the animation, shadows included (up to 64 joints per model; a model with more
  is drawn in its bind pose and a warning says so). The new guide is `factoria docs read animation`.

3D physics: new shapes, joints and a character controller

- 3D colliders can now be capsules (`shape: "capsule"` with `radius` and `height`), convex shapes (`"convex"`, the
  smallest solid that wraps a model) and triangle meshes (`"mesh"`, the exact surface of a model, for terrain, ramps and
  level geometry). For the last two, set `Collider3D.mesh` to a primitive name or to your `.glb`/`.gltf` file, usually
  the same as the entity's `MeshRenderer.mesh`. All shapes collide with each other, and raycasts, shape casts, triggers,
  sleeping and the physics debug view work with all of them.
- A mesh collider is for things that never move. Put it on a body that moves and the engine tells you once, in plain
  words, to use a convex collider or several boxes and capsules instead.
- Joints: add a `Joint3D` to an entity that has a body to make a hinge (doors, pendulums, wheels, with optional angle
  limits and a motor), a ball joint (chains, shoulders) or a fixed joint, hanging from the world or from another body.
  A swinging pendulum keeps its real period.
- Character controller: add `CharacterController3D` to an entity and call `physics.moveCharacter(entity, delta)` each
  frame. It slides along walls, steps up stairs and kerbs (`stepOffset`), refuses slopes steeper than `slopeLimit`, stays
  on the ground going down a ramp, pushes crates, and tells you if it is on the ground (`isGrounded`, `groundNormal`).
  You add your own gravity and jump.
- Limits for now: a model with more than 256 vertices used as a convex collider is simplified to 256 points, jointed
  bodies never fall asleep, and the character is not carried by moving platforms.

More for 2D games

- Flipped and rotated tiles: a tile number can carry a flip or turn, so one picture serves four directions. In
  `scene.import_ascii` a legend entry accepts `flipX`, `flipY` and `rotate` (0, 90, 180, 270). Collision follows the
  plain tile number.
- 9-slice sprites: give a `Sprite` a `slice` (left, top, right, bottom in pixels of the picture) and it stretches like a
  button background, corners intact. It works with flips and with pictures packed in an atlas.
- 2D lights: a `Light2D` entity (point or directional) lights the sprites and tilemaps that set `lit`. Add a
  `normalMap` and the sprite shows bumps that react to the light. `SceneSettings.ambientLight` is the unlit brightness.
  Up to 16 lights at once; the nearest to the camera win.
- Parallax: a `Parallax` component makes a far background move slower than the camera (or faster, for foreground), and
  a sprite can repeat endlessly with `repeatX` / `repeatY`.
- Joints: a `Joint2D` on a body ties it to the world or another body as a hinge (revolute), rope (distance), slider
  (prismatic) or glue (weld), with limits, motors and springs. Scripts can read the reaction force and switch a motor.

Accessibility, speed checks and legal texts

- Colour filters for players: `colorFilter` on the `Camera` turns the whole picture greyscale, raises the contrast, or
  corrects the colours for players who cannot tell red from green (`protanopia`, `deuteranopia`) or blue from yellow
  (`tritanopia`). Your options screen sets it from the player's choice.
- See your game as a colour-blind player does: `factoria run --headless --screenshot-at 60 --screenshot-simulate
  deuteranopia` (or `simulate` in `game.screenshot`) saves the screenshot that way without changing the game, so you or
  your AI can check that hazards still stand out.
- Read menus aloud: `ui.speak(text)` says a line with the computer's or phone's own voice, in the game's language, and
  `ui.speechAvailable` tells whether the system can speak. Speak the button that has the focus and players who cannot
  read the screen can use your menus. Tests check what would be said with `game.spoken()`, without sound.
- Start from the player's own settings: `game.accessibility` tells you the text size the player set on their system,
  and whether they asked for less motion, high contrast or use a screen reader. Use it to set your options on the first
  run; what the player then chooses in your game wins.
- Subtitles: add a `Captions` entity to your scene, then `audio.play("voice.wav", { caption: "Watch out!" })` shows the
  line while the sound plays, and `ui.caption(text)` shows one with no sound. They follow the text size and the player's
  language, and an option can turn them off. Tests list them with `game.captions()`.
- `factoria docs read menus` shows each of these as an option of the ready-made menus, and the accessibility part of
  `factoria docs read finishing` lists them all.
- Speed and memory checks: `factoria call perf.baseline` measures how much CPU time and memory your game uses and how
  many things it draws, and saves it in `perf.json`. `factoria call perf.check` then fails when the game got much
  heavier, so you notice before your players do. `factoria docs read performance` explains how to use it in your own
  checks.
- Privacy policy and license: `factoria docs read legal` says what FactorIA sends from your game (nothing by itself),
  gives a privacy policy you can copy for a game that collects nothing, the paragraphs to add when you use analytics,
  ads, accounts or cloud saves, and when you need a license agreement of your own. It is not legal advice.

Guides for finishing and publishing

- `factoria docs read finishing` takes a game that plays to a game a store accepts, step by step with Lantern Keep's
  code: menus, options that stay set, saves that survive updates, languages, accessibility, credits and tests.
- `factoria docs read publishing` has one checklist per store (Steam, Epic, GOG, Microsoft Store, Google Play, App
  Store, itch.io, your own site): what FactorIA does for you and what you still do by hand, with fees and review times.
- Store images and trailers: `assets.draw_capsules` makes every picture a store page asks for (Steam capsules, Epic,
  GOG, Microsoft Store, Google Play, App Store screenshots, the itch.io cover) from one picture of your game and your
  logo or title. `factoria run --headless --input replay.json --record-video trailer.avi` records a trailer from an
  input replay, with sound; ask for `trailer.mp4` when ffmpeg is installed.

A complete example game

- Lantern Keep (`examples/lantern-keep`) is a small but complete 2D platformer, made the way your AI makes a game: six
  levels, menus, three save slots with a level select and cloud saves, achievements, leaderboards and a shop of cosmetics
  on the test store, accessibility options (text size, a slower game, invincibility, no screen shake), four languages
  including Arabic, an on-screen gamepad for phones and export settings ready for the stores. Read it, copy from it, or
  point your AI at it. Its `SHIPPING.md` lists what each store needs and what is still done by hand.

Learn FactorIA

- Two tutorials for people. `factoria docs read first-game-with-ai` makes your first game with the editor and an AI in
  six rounds, starting from the 2D platformer template: what to type, what to look for and how to undo.
  `factoria docs read make-by-hand` builds a small game by hand from the empty template (collect four gems, then a "You
  win!" screen), one whole file at a time, with a check after each step.
- What a game costs to make with AI: `factoria docs read ai-costs` shows what a complete game cost in a real run, what
  makes a run cheap or expensive, how to set a spending limit and where to see what you spent.
- A browsable API reference in the FactorIA repository: `docs/reference/` has an index of every component and command,
  one page per category, and the version that added each one.
- Searching the docs (`factoria docs search`, and your AI over MCP) shows the best section of each guide first, so a
  name like `onTriggerEnter` finds the scripting reference instead of many sections of one tutorial.

Fixed while making Lantern Keep

Lantern Keep showed what a complete game still had to work around. These are now in the engine, so your AI writes less
code of its own:

- Menus fit their texts: `autoSize` on `Button`, `Toggle` and `Slider` grows the widget to its label at a big text
  size or in a longer language. A button label with several lines is centred line by line, `maxWidth` wraps it, and a
  label that still does not fit is cut at the button's edge. `ScrollList.fill` lets a list take the height the rest of a
  column leaves, and a fitted panel bigger than the screen logs a warning naming it.
- Scripts can apply the layout right away: `ui.layout()` sizes and places the widgets at once, so a script that changes
  a text can read the real sizes (`Button.size`, `Panel.size`, `ui.rectOf`) straight after, without waiting for the next
  frame.
- Panels that do not fit: `fallbackLayout` (row, column or grid) is used instead of `layout` when the panel would leave
  the screen, for example a column that becomes a row at a big text size. `uniformSize` makes the `autoSize` buttons,
  toggles and sliders in a panel all as wide as the widest one and as tall as the tallest one.
- Right-to-left languages: a `Text` with `align: "start"` or `"end"` follows the language's direction, and a panel with
  `direction: "auto"` lays out its rows right to left in Arabic or Hebrew. Scripts read `i18n.direction`.
- Panels: a script hook `onEnable()` runs every time an entity is shown and `onDisable()` every time it is hidden, before
  the frame is drawn, so a panel never shows its placeholder texts for a frame. A hidden panel already has its
  `.behaviour`.
- Focus with a gamepad or the keyboard goes to the widget you expect in the direction you press, and a greyed-out
  `autoFocus` button no longer keeps the focus.
- 2D: a moving platform carries the bodies standing on it, also when the player's script sets its speed every frame
  (that speed is now relative to the platform; drop any carry code of your own). `Shape2D.lit` lets the placeholder
  shapes be lit by `Light2D`.
- ASCII levels: `scene.import_ascii` keeps prefabs as references, so editing a prefab changes every level without
  importing the maps again, and level files stay small. Several maps can share one legend file (`legendFrom`).
- Scripts: vectors and colours work like small arrays (`const [x, y] = position`, `position[0]`, `...color`), reading
  `game.screenSize` is about 60 times faster, and a promise rejection you handle a moment later is no longer reported.
  Unpausing the game keeps the speed you set in `time.scale`.
- Saves: a save file is written in one go, so a crash cannot leave half a file. A save file that does not load is kept
  as `storage.corrupt.json` instead of being overwritten, and `storage.corrupt` tells your game.
- Store texts can be translated: achievements and products in `factoria.json` can name a key of your `locales` files
  (`nameKey`, `descriptionKey`, `titleKey`), and the game lists them in the player's language.
- Tests: `factoria test tests/saves.test.js` runs one test file (or several, or a pattern). `game.click("playButton")`
  presses a widget by its id, `ui.rectOf` gives where a widget is on screen, `expect(x).toMatchObject({...})` checks
  some fields of an object, `game.platform.set({ backend: "none" })` tests the game as on a store-less build, and a
  "not a function" error shows the line with a mark under the call.
- Exports: `export.exclude` in `factoria.json` leaves folders out of every export (`"store/**"`). A publish dry run
  works before the store's upload tool is installed and lists what is missing. The exported game takes `--frames 120` to
  run a few frames and exit, as a quick check in CI. `factoria validate` warns about pictures phones cannot compress, and
  new projects keep `build/` out of git.
- The export guide (`factoria docs read exporting`) has one table of what each export needs (downloads, Android tools,
  Xcode) and whether your computer can make it at all, offline or after a download. A new Microsoft Store section says
  what FactorIA covers and what you still do by hand.
- A game icon without an image service: `assets.draw_icon` draws your icon and the Android icon from shapes, colours and
  text, so you need no paid picture provider and no Python.
- Store screenshots at full size: `game.screenshot` takes a `scale` (so does `factoria run --render-scale`), so a
  1280x720 game makes sharp 1920x1080 pictures instead of enlarged ones. The HUD and the visible area stay the same.
- `i18n.import` for a new language keeps the shape of your main language file, and `factoria docs read` prints clean
  text on Windows.
- The reference (`factoria api`, `docs/COMPONENTS.md`, the MCP tool list) now says which version added each component,
  field and command, and marks with "Not released yet" what is only on the main branch, so you can tell what your
  installed FactorIA has.
- Editing an ASCII level no longer means counting characters: `scene.ascii_edit` changes the map file of a level with
  operations (fill a rectangle, replace a glyph, insert or delete columns, put a coin "2 tiles above the ground" of
  column 40), rewrites only the rows and rebuilds the level, and tells you where every object ended up.
- On Windows, deleting a folder that holds files with very long paths (a macOS export nests four folders) now deletes
  all of it: exporting again into the same folder, `fs.delete` and deleting a project from the editor no longer leave
  old files behind.

Smaller improvements

- The editor's Screenshot toast has a "Show in Finder" / "Show in Explorer" button (it names your file manager) that reveals
  the new PNG, and File > Open Screenshots Folder opens the hidden `.factoria/screenshots/` folder (creating it if needed).
  A toast with a button stays longer and does not vanish while the mouse is over it.
- `factoria validate` no longer warns that a hand-written scene or prefab is "not in the canonical layout": such a file is
  valid. The report has a new informational `notes` list (`note:` lines in the text, `notes` in `--json`, the
  `project.validate` result and the editor's Validation report) with ONE entry naming those files and the optional
  `factoria call scene.format`. `scene.format {check, strict}` is still the CI gate.
- On Windows `factoria` now prints LF line endings like on macOS and Linux, so a doc or a JSON answer saved with `>`
  has no carriage returns.
- A Linux game named "game" now exports with the executable `game-bin`, so it no longer clashes with the `game` data
  folder next to it.

## 0.1.6

Menus and on-screen interface

- New interface pieces for your game: buttons, toggles, sliders, text fields, scrolling lists and panels with
  stretchable backgrounds, laid out in rows, columns or grids. Players use them with the mouse, the keyboard or a
  gamepad.
- Scripts can switch to full screen, change the window size, vsync and frame-rate cap, let players remap the controls,
  show the right button names for their gamepad, take typed text, and show or hide the cursor.
- A menus guide your AI follows to build a main menu, options, a pause menu, credits and a loading screen when your game
  needs them. New projects still start empty.
- Pausing really pauses now: physics, particles and animations stop too, while a pause menu keeps working.

Art, sound and music made by AI

- Your AI can generate images, sprite sheets, sound effects, music, voices and 3D models with the providers you set up
  (OpenAI, ElevenLabs, Meshy), keeping one style and colour palette across a game.
- Every generated or imported file remembers where it came from, and exports include `AI_CONTENT_DISCLOSURE.md` with
  the answers Steam asks about AI-generated content.
- Import Aseprite, Photoshop (PSD), OBJ and FBX files (FBX needs Blender or FBX2glTF installed), and cut sprite sheets
  into frames automatically.
- Lighter games: textures are compressed for each platform and packed into atlases, long music streams instead of
  loading whole into memory, and sounds can be evened out to the same loudness.
- `factoria validate` warns about images that are too big, sounds that clip or are too quiet, and games over a store's
  size limit.

Native plugins

- A game can bring its own native code as a plugin (C or C++ on desktop, Java or Kotlin on Android, libraries on iOS)
  without changing the engine. Plugins can live outside the game's folder, for SDKs you are not allowed to share.

## 0.1.5

- Exported Windows games open without a black console window, and the `.exe` carries your game's name and version
  (Properties in File Explorer shows them).
- Every run of a game writes a `log.txt` in the game's save folder, so a player can send it to you when something goes
  wrong.
- Exporting no longer fails on Windows when the output folder is deep enough to make paths longer than 260 characters.
- When a text uses characters its font does not have (Chinese, Japanese or Korean with the default font, for example),
  the log says which characters are missing and which font has them, instead of leaving the text blank without a word.
- When a command fails, your AI assistant always gets an error it can read and act on.

## 0.1.4

- Android: export your game as an APK to test or an AAB for Google Play, signed with your own key, with its icon.
- New Export window in the editor, with a button per platform and the settings each one needs (name, version, icons).
  What an export still lacks (Android SDK, players for another system) is installed in one click, or with
  `factoria setup` from a terminal.
- macOS: FactorIA is signed and notarized by Apple, so it opens without a security warning.
- iPhone, iPad and Apple Silicon Macs: touches and clicks land where they should, and games run on real devices.
- Android: a game you leave and open again starts correctly.
- The editor's title shows the FactorIA version and the open project.
- Exporting again only replaces a folder an earlier export made, never a folder of yours.
- Scripts: a warning when a method looks like a misspelled event name (for example `onUpdat`), which would otherwise
  never be called.
- License: FactorIA is MIT and the templates are MIT-0, so your game's code is yours to license as you like. Exported
  games include the license notices they need (`FACTORIA_NOTICES.txt`).

## 0.1.3

- Windows installer: installs for your user without an administrator prompt, adds FactorIA to the Start menu and
  makes `factoria` work in any terminal.
- Linux: a single-file AppImage, besides the `.tar.gz`. macOS: one download for Apple Silicon and Intel.
- Android and iOS export work straight from the download: you no longer need the engine's source code.
- Gamepads: hundreds more models are recognised on Linux, and on Android an unplugged pad frees its slot.
- 3D physics: balls roll and spin naturally when hit off-centre, resting bodies sleep and wake like in 2D, and fast
  objects no longer pass through walls.

## 0.1.2

- Editor: fixes in the AI chat, and projects can be deleted from the project list.
- Destroying an object also removes its physics body.
- Your AI assistant can export the game by itself.
- Screenshots taken by tests always show a complete, up-to-date frame.

## 0.1.1

- Editor: Ctrl+C and Ctrl+V work.

## 0.1.0

The first release of FactorIA, a 2D and 3D game engine made for an AI to build your game.

- Games are plain text (scenes in JSON, logic in JavaScript), so an AI can read and change every part of them, check
  its work and run tests.
- The editor is built around an AI chat: send pictures as references, keep several chats with their history, see how
  much of your plan you have used, and choose the model for each AI role.
- Templates to start from: a 2D platformer, an empty 2D game and an empty 3D game.
- 2D and 3D physics, gamepads, and play sessions that can be replayed exactly, with a report your AI can read.
- Downloads for Windows, macOS and Linux. The editor offers each new version and updates itself when you say so.
