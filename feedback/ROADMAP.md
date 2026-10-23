# Engine feedback report

Status: the four jam-sized example games reported 73 entries, all verified fixed-in-engine. Lantern Keep, the M21
reference game, reported 45 (none a blocker or major), triaged 2026-10-19: one was already fixed, two were duplicates,
and the 42 open ones became work packages, most of them M24, the rest in M20-M23. M24 fixed 37 of its entries
(M24.1-M24.16, 2026-10-20), two of them found on the way, M21 three, M22 two, M20 one and M23 the last one (MSIX,
2026-10-22): no entry is open. M1-M11 and M13-M15 are done; M12 (platform services) has its API and the Steam, Apple and Google Play
backends; M16 (mobile store-ready), M17 (web export), M18 (animation and production 3D), M20 (editor and tooling, 2026-10-22),
M21 (docs and material for shipping), M22 (production quality and legal, 2026-10-21), M24 and M25 are done; M23 has the Mac
App Store and the Microsoft Store (MSIX) done, its consoles part is not started; M19 is not started (M10-M23 come from an external evaluation of v0.1.4, re-triaged 2026-10-16: what it still takes to ship a game to the stores).
M25, the second reference game (Clockwork Courier: 3D, mobile first, 2026-10-22), reported 55 entries (FB-0053-FB-0055
came from the CI fix of its rope bridges), triaged 2026-10-22: one was fixed on the way (CC/FB-0033), two were already
fixed before the report (CC/FB-0007, CC/FB-0022; their docs are added), two are duplicates, and 50 are open, ranked below
(11 major, 35 minor, 4 nice-to-have, no blocker). They are M26's 23 work packages, which come next; the same triage
moved two M19 items into M26 and ranks the rest of M19 and of M12.
What only certificates, real devices or a device farm can close is under M8 and M9, "Left open". What finished
milestones built is in [ROADMAP_DONE.md](ROADMAP_DONE.md); this file keeps what they left open and the decisions to
respect.
Regenerate the ranked list with `factoria feedback collect examples/sky-hopper examples/neon-swarm examples/gem-roller examples/block-push examples/lantern-keep examples/clockwork-courier --out feedback/ROADMAP.md` (it rewrites the whole file: then put this status and the milestones section back).

50 entries from 6 project(s), 50 distinct gap(s). Ranked by total occurrences x severity weight (blocker 8, major 4, minor 2, nice-to-have 1).

## 1. glTF animation of rigid (non-skinned) meshes parented to bone nodes is ignored

- **Category:** animation
- **Severity:** major (score 8)
- **Total occurrences:** 2
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0001
- **Suggestion:** Support node-transform animation of non-skinned mesh nodes in the Animator (drive the node world matrix of a MeshRenderer model's nodes), or auto-convert rigid-per-bone meshes to a skin at load. At least print a warning when a model has clips but no skin.
- **Workarounds seen:**
  - Wrote a Python script (tools/skinify.py) that bakes every rigid mesh into model space, gives it JOINTS_0/WEIGHTS_0 = 100% its parent bone and builds a skin with inverse bind matrices; then the Animator plays it. [P2] The same happens with Kenney cube-pets animal-dog.glb, where the MESH nodes themselves are the animated bones (8 clips, no skin): the dog stood frozen in every clip. tools/skinify.py now also treats an animated mesh node as its own bone (7 joints), and the Animator then plays walk/run/idle. Second asset of two in this game with the same layout, so it is common in CC0 packs.

## 2. scene.format without paths rewrites every scene and prefab of the project

- **Category:** tooling
- **Severity:** major (score 8)
- **Total occurrences:** 2
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0016
- **Suggestion:** Make `paths` required (or default to `check: true`), and print how many files it will change before writing more than a few.
- **Workarounds seen:**
  - Always pass `{"paths": [...]}`; level generators write canonical JSON themselves and the project notes say never to run it bare.

## 3. A CharacterController3D is not carried by a kinematic platform it stands on

- **Category:** physics
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0010
- **Suggestion:** physics.moveCharacter should add the displacement of the kinematic body it is grounded on (the way it already treats dynamic bodies), with an option to turn it off.
- **Workarounds seen:**
  - scripts/courier.js reads the velocity of the kinematic body under its feet (the ground entity of the last move) and adds it to its own move every frame; scripts/mover.js drives the platform by velocity only, so the numbers agree.

## 4. A joint-driven body is silently stopped by an overlapping static collider

- **Category:** physics
- **Severity:** minor (score 4)
- **Total occurrences:** 2
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0015
- **Suggestion:** A validate or debug-draw warning when a Joint3D body overlaps a static collider it is not connected to at the start pose, or a `game_state` field listing joints that are stalled against the motor.
- **Workarounds seen:**
  - Levels leave 0.2 m of clearance around every hinge gate and the arena's gate sits between two walls with that gap.

## 5. A localized Text cannot take parameters and is rewritten every frame

- **Category:** ui
- **Severity:** minor (score 4)
- **Total occurrences:** 2
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0021
- **Suggestion:** Text.keyArgs (an object of replacements) or a {name} placeholder filled from a bound value, re-localized on language change.
- **Workarounds seen:**
  - Scripts clear Text.key and write the string built from i18n.t with replacements (level_flow.setText, results_view.js, level_select.js).

## 6. Catalog is not readable from scripts and leaderboards have no localizable name

- **Category:** platform
- **Severity:** minor (score 4)
- **Total occurrences:** 2
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0029
- **Suggestion:** platform.catalog (read only: ids, types, titles) and nameKey on leaderboards.
- **Workarounds seen:**
  - scripts/store.js keeps a TYPES table; the leaderboards screen builds its titles from the level name keys; a test compares the code's lists with game.platform.state().catalog.

## 7. Characters do not weigh on dynamic bodies and push them aside

- **Category:** physics
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0011
- **Suggestion:** Let the character controller optionally apply its weight (mass x gravity) to the dynamic body below, and expose `pushStrength` or a layer rule so it does not shove bodies that are jointed.
- **Workarounds seen:**
  - scripts/seesaw.js simulates the weight: while the courier is grounded on the plank the hinge motor drives the end it stands on down, and the plank's own velocity is zeroed every fixed step so the courier cannot push it off its pivot. scripts/rope_bridge.js lets the planks be walked on without reacting to the load (heavy damping keeps it calm).

## 8. No ads API: no rewarded ad, no consent or tracking-permission flow, no dev/release flag

- **Category:** platform
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0028
- **Suggestion:** A platform.ads service next to purchases: ads.available(placement), ads.showRewarded(placement) -> {rewarded}, ads.consent() (with the ATT/UMP sheets) and a platform.release boolean; the fake backend answers with a scripted test ad so games and tests share one path.
- **Workarounds seen:**
  - scripts/ads.js defines the provider interface (name, available(), showRewarded(placement) -> {rewarded, reason}) and a stub overlay (scripts/ad_stub.js) used only while platform.backend is 'fake'; any other backend has no provider and the retry screen shows no ad offer. A real SDK plugin would call ads.setProvider().

## 9. No calendar date API and no way to pin the date in tests

- **Category:** scripting
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0019
- **Suggestion:** Add `time.calendar()` (or `game.today()`) returning {year, month, day, utcOffsetMinutes, iso} from the real clock, recorded in replays, plus `game.setDate("2026-10-22")` in factoria:test (and a --date flag for headless runs) so date-driven logic is deterministic. Document the rule in the scripting guide next to rng.
- **Workarounds seen:**
  - scripts/clock.js is the only place that reads `new Date()`; everything else asks clock.today(), and tests pin the day with clock.setToday() (stored in `session`). Dates are YYYY-MM-DD of the local day.

## 10. No on-screen keyboard for gamepad players

- **Category:** ui
- **Severity:** minor (score 4)
- **Total occurrences:** 2
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0020
- **Suggestion:** A built-in virtual keyboard widget a TextField can open when focus came from a gamepad (letters, digits, space, delete, done; d-pad navigation; localised layouts), and `input.showKeyboard` calling the platform's own gamepad keyboard where one exists (Steam Big Picture, consoles).
- **Workarounds seen:**
  - profile.scene.json has a grid of 36 buttons built at runtime (key_A..key_9, space, delete) that edit the TextField text; d-pad focus walks the grid.

## 11. No path finding or navmesh for 3D characters

- **Category:** physics
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0009
- **Suggestion:** A `nav.findPath(from, to, {radius, stepHeight})` API (and a NavGrid/navmesh component baked from static colliders, with a dirty flag for moving obstacles) next to physics.raycast3d.
- **Workarounds seen:**
  - scripts/nav.js: a lazy height-field grid over the physics world (a ray straight down for the ground height, physics.overlapSphere for obstacles, a step-height rule for connections, A* with line-of-sight smoothing). It works but is slow to write, must be rebuilt when a gate or crate moves, and cannot know about doors or one-way drops.

## 12. No shrink-to-fit or per-screen text scale cap

- **Category:** ui
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0042
- **Suggestion:** Text.autoShrink (minFontSize) and Button.autoShrink, plus Widget.maxTextScale so a heading or a disc label can stop growing.
- **Workarounds seen:**
  - Four screens cap the effective size of their fixed-place texts in script (level_select capSizes, hud layoutHud, touch labels in hud.js, toast panel fit); menus use fit Panels with fallbackLayout and ScrollLists with fill.

## 13. Products.storekit exists only with a built Apple plugin and has one locale

- **Category:** platform
- **Severity:** minor (score 4)
- **Total occurrences:** 2
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0034
- **Suggestion:** Write Products.storekit whenever the catalog has products and the target is ios (the plugin only matters for the scheme), and one localization per locale of the project, from titleKey.
- **Workarounds seen:**
  - Checked on a scratch copy: add_backend apple, cmake build of the plugin, export; the four products came out right (ids, types, prices). The real project does not declare the plugin.

## 14. Scene loads are synchronous and there is no progress or preload API

- **Category:** assets
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0012
- **Suggestion:** scene.preload(path) returning a handle with progress 0..1 (loading assets on a worker), or scene.loadAsync plus an `onProgress` callback; the same for assets.preload([paths]).
- **Workarounds seen:**
  - scenes/loading.scene.json draws a step bar that counts the three frames the script really runs before the blocking scene.load; it is honest about being steps, not a percentage.

## 15. Scripts cannot see the app being suspended, resumed or losing focus

- **Category:** platform
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0035
- **Suggestion:** Expose game.onSuspend/onResume (and window focus) to scripts, and have a project setting that pauses the game on suspend by default.
- **Workarounds seen:**
  - scripts/comfort.js watches time.unscaledDt: a single frame longer than 0.75 s means the app was away, and it opens the pause menu. It cannot tell a suspend from a long hitch and cannot react before the suspend.

## 16. assets.import of a .glb does not copy the texture file it references

- **Category:** assets
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0008
- **Suggestion:** assets.import for .glb/.gltf should copy every external uri it references (keeping the relative layout under a folder named after the model or the pack), add provenance for them, and warn when the destination folder already holds a different file of the same name. validate should report a model whose external texture is missing.
- **Workarounds seen:**
  - Moved each kit into its own folder (assets/models/town, props, pets), copied that kit's Textures/colormap.png next to it by hand and re-keyed assets.json (with provenance for the png).

## 17. storage and the platform fake keep their state between tests of a run

- **Category:** tooling
- **Severity:** minor (score 4)
- **Total occurrences:** 2
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0026
- **Suggestion:** An option (or the default) that clears storage and resets game.platform before each test, or game.resetState().
- **Workarounds seen:**
  - tests/helpers/store.js: fresh() before and cleanup() after every test.

## 18. validate keeps the audio loudness warnings after defaults.audio.normalize is set

- **Category:** tooling
- **Severity:** minor (score 4)
- **Total occurrences:** 2
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0004
- **Suggestion:** Make the loudness check read the effective import settings (defaults merged with per-asset), or say in the warning that the default is already applied and the warning is about the source file.
- **Workarounds seen:**
  - Left the two warnings (they are not errors). [P2] P2 sounds: validate still warns for loopcity_0.ogg (peaks at 0.3 dBFS), pluck_001.ogg and toggle_001.ogg (loudness) although assets.json sets normalize: true for them; the warning should read the import settings.

## 19. 3D physics is not identical across platforms

- **Category:** physics
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0055
- **Suggestion:** Document that physics is deterministic per build, not across platforms; offer a robustness check (run a test N times with tiny perturbations) so games find chaotic spots before CI does; consider strict floating point (no FMA contraction) in the physics module.
- **Workarounds seen:**
  - Made the bridges settle (ends off the slabs) and checked the level route under small position nudges (±0.2 mm to ±1.5 cm of every plank and of the courier) so it passes whatever the rounding.

## 20. A chain of hinged planks rings for a long time; a rope bridge needs heavy damping and wide planks

- **Category:** physics
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0017
- **Suggestion:** A `Rope`/`Chain` component (or solver iterations per joint chain) that is stable by default, or a documented recipe for bridges in the physics guide.
- **Workarounds seen:**
  - scripts/rope_bridge.js uses linearDamping 3 and angularDamping 8, width 2 m, sag 0.35 and 9 planks; with these it hangs still and holds the courier.

## 21. A fill ScrollList makes its whole panel screen-tall

- **Category:** ui
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0046
- **Suggestion:** fill should take only the room left (maxHeight = screen minus the other rows), and let the panel shrink below it.
- **Workarounds seen:**
  - Each list gets a design size and fill: the panel uses the screen height only when the content is taller (credits, achievements, leaderboards, shop, options).

## 22. A headless test cannot set the system language

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0044
- **Suggestion:** game.setSystemLanguages([...]) in the test API, like setAccessibility, applied by the next scene load.
- **Workarounds seen:**
  - The rule is a pure function, settings.pickLanguage(systemLanguages, supported, fallback), tested with lists; the engine's own pick is not exercised.

## 23. Android export needs the exact CMake 3.31.6 in the SDK and a JDK, with no offline way around it

- **Category:** platform
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0048
- **Suggestion:** Accept any CMake >= the minimum (read from `cmake --version` or `export.android.cmake`), print the cmake.dir / JAVA_HOME / --offline recipe in the error, and let `factoria doctor` list both.
- **Workarounds seen:**
  - Scratch scripts outside the repo: a cmake.dir in local.properties pointing at the system CMake (4.4.4), -Pfactoria.cmakeVersion=4.4.4 and JAVA_HOME from a JDK that was already installed (the one bundled with Unity Hub); then Gradle --offline built a 52.8 MB apk in 2m23s.

## 24. Desktop export does not check that the bundled player matches the factoria that exports

- **Category:** platform
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0049
- **Suggestion:** Print the player path and version in the export report, and warn (or refuse without --allow-player-mismatch) when the player's version or build id differs from the factoria that exports. The Windows export already reads the player's version information; do the same on macOS and Linux (factoria_player --version).
- **Workarounds seen:**
  - Rebuilt the engine so factoria and factoria_player match (or pass --player <build dir>/player/factoria_player) and exported again; macOS verified running. SHIPPING.md says how to check.

## 25. Joint3D chains never come fully to rest and unrelated chains affect each other

- **Category:** physics
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0054
- **Suggestion:** Let jointed bodies sleep as a group once all of them are calm, and solve separate joint islands independently so one island cannot disturb another.
- **Workarounds seen:**
  - None in the engine: the autoplay route crosses the see-saw with smaller, more careful steps (tests/helpers/routes.js).

## 26. Joint3D connected empty string is rejected by the scene validator but documented as 'the world'

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0014
- **Suggestion:** Accept the empty string as the world (as documented), or change the doc to say 'leave the field out'.
- **Workarounds seen:**
  - scripts/rope_bridge.js only sets `connected` when there is a next plank; the last plank's joint omits the field.

## 27. MeshRenderer tints the whole model: no per-material colour

- **Category:** rendering-3d
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0031
- **Suggestion:** MeshRenderer.materialColors: {materialName: [r,g,b,a]} overrides, or a colour per glTF material slot.
- **Workarounds seen:**
  - scripts/paints.js stores a dark tint plus an emissive per paint, tuned by looking at screenshots.

## 28. No animal sounds (bark, growl) in the CC0 sound kits the engine suggests

- **Category:** assets
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0013
- **Suggestion:** Document a CC0 animal/creature pack in the assets guide, or add an `audio.synth` helper (noise burst plus filtered sweep) for simple barks, growls and whooshes.
- **Workarounds seen:**
  - A pitched heavy impact (impactPunch_heavy_000.ogg) stands in for the bark; the dog also flashes a red view cone and shows an exclamation mark, so the warning does not depend on sound.

## 29. No command to scaffold the menu kit; it can only be extracted from the docs by hand

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0003
- **Suggestion:** Add a command (and MCP tool) that writes the kit into the project, optionally with a choice of parts (pause only, settings only).
- **Workarounds seen:**
  - Wrote a small script that splits the doc's fenced blocks (```lang path) into files.

## 30. No graphics quality API: no render scale, no GPU info and the frame cap throws on phones

- **Category:** performance
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0036
- **Suggestion:** Add window.renderScale (0.5..1) and a read-only game.deviceTier or gpu info, and make window.frameCap a no-op that returns the real cap on phones instead of throwing.
- **Workarounds seen:**
  - The quality preset (scripts/accessibility.js) only changes what scripts own: Light.castShadows, view distance fog, particle counts and lantern lights. The frame cap option is disabled on phones (scripts/ui/options.js) and a phone starts at medium quality by a screen-size guess (scripts/settings.js).

## 31. No locale-aware number formatting

- **Category:** ui
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0039
- **Suggestion:** Number, percent and duration formatters in i18n (i18n.number(v, {digits}), i18n.duration) following the active language, and {value:number} style placeholders.
- **Workarounds seen:**
  - Each locale file states format.decimal and scripts/fmt.js applies it (decimal, clock) before the value goes into i18n.t.

## 32. No per-day or per-season leaderboards: the catalog is static

- **Category:** platform
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0030
- **Suggestion:** A `period` (daily, weekly) on a leaderboard that the backends map to their recurring boards, or leaderboards.submit(id, score, {suffix: date}).
- **Workarounds seen:**
  - One 'daily_route' board holds the best time ever; the day is only in the daily_route_finished event.

## 33. No way to share a UI panel between scenes

- **Category:** scene
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0023
- **Suggestion:** Document or support UI prefabs with child overrides, or a scene include, in the menus guide.
- **Workarounds seen:**
  - The layout stays duplicated; texts are written at runtime from one script (results_view.js).

## 34. Slider value set from a script sends no ui.change and shows the raw number

- **Category:** ui
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0037
- **Suggestion:** Add a test helper game.setSlider(id, value) that behaves like the user, and Slider.format (for example "{value:0%}").
- **Workarounds seen:**
  - tests/comfort.test.js clicks the middle of the track and checks the saved value is inside the range; the options show the multiplier as a plain number.

## 35. Test API cannot hold a mouse button or turn the wheel, so mouse drag orbit and wheel zoom are untestable end to end

- **Category:** input
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0005
- **Suggestion:** Add game.mouse(x, y), game.mouseDown(button), game.mouseUp(button) and game.wheel(dy) to the test API (same as game.input mouse/buttons).
- **Workarounds seen:**
  - tests/camera.test.js calls orbit() and zoom() directly; the drag and wheel reading in follow_camera.js readInput() has no test.

## 36. The fake store cannot simulate a refund or a revoked purchase

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0024
- **Suggestion:** game.platform.revoke(productId) (and an equivalent dev command) that removes the product from restore() and emits no event, like the Apple 'refunded transaction is never delivered' rule.
- **Workarounds seen:**
  - store.reconcile({authoritative:true}) revokes products the store no longer lists; tests call game.platform.reset() and then reconcile. On the fake backend the start-up reconcile is not authoritative (a dev run would lose its purchases at each start).

## 37. The test API cannot observe a quit request

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0038
- **Suggestion:** Add game.quitRequested to the test API and make game.quit() only set it in tests.
- **Workarounds seen:**
  - tests/comfort.test.js patches the quit function of the engine object for the duration of the test and restores it.

## 38. Toggle and Slider labels do not wrap or shrink

- **Category:** ui
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0041
- **Suggestion:** maxWidth on Toggle and Slider (wrap the label, grow the height), and a Slider label placed above the track.
- **Workarounds seen:**
  - Sliders are fixed size with an empty label and a Text above each one (maxWidth wraps it); the options list width follows ui.textScale (fitWidth in scripts/ui/options.js); the Toggle labels stay short in every locale.

## 39. TouchButton has no localization key

- **Category:** ui
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0040
- **Suggestion:** A `key` field on TouchButton, like Text and Button.
- **Workarounds seen:**
  - scripts/hud.js writes the label in the current language at start and at every i18n change, and sizes the font to fit the 96 px disc.

## 40. Validator flags a method named start() as a lifecycle-hook lookalike

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0006
- **Suggestion:** Only warn for names that differ from a hook by case or prefix (OnStart, onstart, on_start), not for generic verbs like start.
- **Workarounds seen:**
  - Renamed it to fill().

## 41. Web player: typing in a TextInput from the browser pane did not fill it

- **Category:** input
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0052
- **Suggestion:** Document how the web player receives text (keydown vs the text input event, hidden input element for mobile keyboards) so a game can test it, and add an autotest page to the web player.
- **Workarounds seen:**
  - Filled the name with the on-screen keyboard of the game (scripts/profile.js) for the check.

## 42. assets.set_provenance re-sorts the whole assets.json

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0045
- **Suggestion:** Keep the file order and touch only the entry.
- **Workarounds seen:**
  - The font entry was inserted by hand in assets.json, in the same shape.

## 43. glTF with two skins sharing the same joints: second skin is drawn wrong, no way to fix without editing the file

- **Category:** animation
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0002
- **Suggestion:** Merge skins that have the same joints/IBMs at load, or animate every skin of the file; the 'first skin' limit is a trap for exported characters.
- **Workarounds seen:**
  - Dropped the two hand meshes from the glb in the same script (the arms end in balls anyway).

## 44. perf.measure and the test API give no triangles or lights, and renderStats is zero headless

- **Category:** performance
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0050
- **Suggestion:** Add triangles, lights, shadowCasters and textureMB to perf.measure and to a `game.renderStats()` in factoria:test (the headless EGL/Metal renderer has them after one frame).
- **Workarounds seen:**
  - tests/budget.test.js counts entities, MeshRenderer, Light and ParticleEmitter of every level in the running scene (static numbers); perf.json holds the draw-call budget of the heaviest level.

## 45. platform.add_backend ignores dryRun and rewrites the whole factoria.json

- **Category:** platform
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0047
- **Suggestion:** Honour dryRun (print what would be written) and edit factoria.json in place without reformatting. Also exclude plugins/apple/build from the folder it creates, or say it is a build dir to ignore.
- **Workarounds seen:**
  - Kept the real result (it is what makes the export write Products.storekit) and committed it; the reformatting is in the same commit as the plugin.

## 46. purchases.finish() throws synchronously for an unknown transaction instead of rejecting

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0025
- **Suggestion:** Return a rejected Promise with the same message and hint, like the rest of the platform API.
- **Workarounds seen:**
  - store.grant wraps the call in try/await/catch.

## 47. No control over the sibling order of a spawned UI child

- **Category:** ui
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0032
- **Suggestion:** A `index` (or `before`) option in world.spawn's options and entity.setParent(parent, index).
- **Workarounds seen:**
  - scripts/more_time.js spawns the new button and then calls setParent again on the two stock buttons so they come after it.

## 48. No overflow or pseudo-localisation check

- **Category:** tooling
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0043
- **Suggestion:** `factoria validate --pseudo-loc` (or a ui.overflowing() query) that lists clipped labels and widgets outside the screen at a given text scale and language.
- **Workarounds seen:**
  - A tour script drove factoria session through every screen per language and scale and listed widgets whose ui.state rect left the screen; tests/i18n.test.js repeats the key screens.

## 49. No video playback, and --record-video writes a very large AVI

- **Category:** assets
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0051
- **Suggestion:** A Video component (mp4/webm with the platform decoder) and an --record-video output that is already H.264 mp4 when the OS offers an encoder (VideoToolbox, Media Foundation, MediaCodec).
- **Workarounds seen:**
  - The intro is an animated scene (scenes/intro.scene.json, scripts/intro.js). The trailer is a scripted director scene recorded with --record-video; SHIPPING.md has the ffmpeg command to make the mp4.

## 50. scene.load called from a test only takes effect in the next frame

- **Category:** tooling
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0018
- **Suggestion:** Document the difference in the testing guide, or make scene.load from a test start the scene immediately like game.load.
- **Workarounds seen:**
  - tests step two frames after scene.load before reading anything.

# Next engine milestones

Hand-written triage section (the ranked list above is generated; regenerate it with the command in
`feedback/README.md` and keep this section). Triage date 2026-10-13, against commit `e2b0090`: of the 55
entries from the four example games, the engine already fixed most; the work packages below cover what is left,
plus two packages for gaps seen while verifying that no game has hit yet (marked *proactive*).

Re-triage 2026-10-16, after `497303d` (v0.1.4), from an external evaluation: a veteran developer tried to take a game
from `factoria new` to every store with v0.1.4 and listed 82 numbered gaps plus a few notes (the ids below are the
report's: H tools, F engine features, E exports, S store services, A asset generation, D docs, U game menus, Q production
quality; the report itself is not in the repository). Every gap was checked against the code; all of them held.
- Fixed in the same PR as this triage: E-01 (the Windows player and every exported exe are GUI programs: no console
  window, and a terminal that starts one still gets its log), E-02 (the exe's version information is the game's name
  and version), E-06 in part (every run writes `log.txt` in the save folder; crash reporting is M13), E-11 (paths over
  260 characters on Windows; with `--json` a failure prints a JSON error object), Q-07 (a missing glyph logs one warning
  per font naming the characters and a font that has them) and D-06 (GETTING_STARTED status table).
- Already listed, not repeated: E-03 and Q-02 (M8, "Left open"), H-11 and the Android shutdown part of F-10 (M9, "Found
  while implementing M9"). Q-01 (the project's age, one maintainer) and Q-08 (a strength) are not engine work.
- Everything else, and the points of the report's per-store table that no id covers, is grouped in M10-M23 below, in
  the report's order of priority: what blocks any store release first.
  Roblox is out of scope (end of the list). None of these gaps came from the four example games, which are jam-sized and
  never needed menus, localization or stores; M21 adds a complete reference game to close that blind spot.

Triage 2026-10-19 of the 45 entries of Lantern Keep, the M21 reference game, against `04e751b` (each checked in the code
and in a scratch project with `factoria test` and `factoria call`): LK/FB-0032 was already fixed (`ui.measureText` is
exact wherever a renderer exists, tests included; only TEXT.md still says otherwise, LK/FB-0042), LK/FB-0030 is a
duplicate of LK/FB-0008 and LK/FB-0034 of LK/FB-0015 (their occurrences were merged), and every other entry still
holds. The 42 open ones are the packages of M24 below, plus LK/FB-0009 in M20, four in M21, two in M22 and LK/FB-0023
in M23.

Re-triage 2026-10-20, after M24.1-M24.6 (merges `b6c6f3b`, `1341def`, `2ee41ac`, `d891e92`, `43e03b9`, `acd5baf`): 13
Lantern Keep entries are fixed, each with a `Fixed in <commit>` note, and the game dropped their workarounds in the
`m24/bookkeeping` PR; LK/FB-0026 stays open for its matchers (M24.7). 29 Lantern Keep entries are open.

Re-triage 2026-10-20, after M24.7-M24.14 (merges `da5f957`, `7506b4b`, `343a7b8`, `7c29612`, `3768d21`, `f4071e7`, `2320973`,
`2e0fa55`): 22 more Lantern Keep entries are fixed, each with a `Fixed in <commit>` note, and the game dropped their
workarounds in the `m24/bookkeeping-2` PR (`scripts/ui/text_fit.js` is gone). Dropping it showed two new gaps,
LK/FB-0046 and LK/FB-0047 (M24.15, M24.16). 9 Lantern Keep entries are open.

Re-triage 2026-10-20, after M24.15-M24.16 (merges `62f24f9`, `7b57f09`): LK/FB-0046 and LK/FB-0047 are fixed, each with
a `Fixed in <commit>` note, and Lantern Keep dropped its workarounds in those PRs. 7 Lantern Keep entries are open:
LK/FB-0009 in M20; LK/FB-0014, LK/FB-0017, LK/FB-0022 and LK/FB-0023 in M21; LK/FB-0037 and LK/FB-0038 in M22;
LK/FB-0023 also in M23, for MSIX.

Re-triage 2026-10-20, after M21's #115-#117 (merges `02b1555`, `0e49b93`, `97f693c`): LK/FB-0014, LK/FB-0017 and
LK/FB-0022 are fixed, each with a `Fixed in <commit>` note, and Lantern Keep dropped its workarounds
(tools/make_icon.py, tools/make_screenshots.py) in those PRs. 4 Lantern Keep entries are open: LK/FB-0009 in M20;
LK/FB-0037 and LK/FB-0038 in M22; LK/FB-0023 in M23, for MSIX (its Microsoft Store docs are in, from #115).

Re-triage 2026-10-21, after M22 (merges `972974b`, `8d40daa`, `441405b`, `67fe125`, `40ebbeb` and #132): LK/FB-0037 and
LK/FB-0038 are fixed, each with a `Fixed in <commit>` note; Lantern Keep does not use those features yet. 2 Lantern Keep
entries are open: LK/FB-0009 in M20 and LK/FB-0023 in M23, for MSIX.

Re-triage 2026-10-22, after M20.1 (merge `9b92c45`, #134): LK/FB-0009 is fixed, with a `Fixed in <commit>` note; Lantern
Keep had no workaround to drop (its `levels/<id>.json` maps were already the source of truth). 1 Lantern Keep entry is
open: LK/FB-0023 in M23, for MSIX.

Re-triage 2026-10-22, after M23's Mac App Store and MSIX packages (`3ec0864`, `6364e8f`, the `m23/stores` PR): LK/FB-0023
is fixed, with a `Fixed in <commit>` note; Lantern Keep had no workaround to drop (its SHIPPING.md now points at the
export). No Lantern Keep entry is open.

Triage 2026-10-22 of the 55 entries of Clockwork Courier, the M25 reference game, against `0ffcee5` (each checked in
the code, several reproduced in a scratch project with `factoria test`, `factoria call` or `factoria validate`):
CC/FB-0033 was fixed during M25; CC/FB-0007 was already fixed (`entity.animator.get(name)`, `e3ab260`; ANIMATION.md now
shows it) and CC/FB-0022 was not an engine gap (the built-in font has ★ and ☆; TEXT.md now says so); CC/FB-0027 is a
duplicate of CC/FB-0021 and CC/FB-0053 of CC/FB-0015 (their occurrences were merged). Ten entries hold only in part, and
their notes say which part. Verifying CC/FB-0020 found a bug no game reported: a focused `TextField` does not raise the
phone's keyboard, though MOBILE.md says it does (M26.17). The 50 open entries are the packages of M26 below; parts of
three stay in M12 (the real ads and leaderboard-period backends, CC/FB-0028 and CC/FB-0030; the Steam Deck keyboard,
CC/FB-0020) and part of one in M19 (the video player, CC/FB-0051). Two M19 items moved to M26 because a game needed
them: the navmesh (M26.10) and `scene.loadAsync` (M26.7). What is left of M19 and of M12 is ranked in their sections.

Sizes: S = under a day for an AI agent, M = 1-3 days, L = a week or more. Ids are `<game>/FB-n`
(sky-hopper = SH, neon-swarm = NS, gem-roller = GR, block-push = BP, lantern-keep = LK, clockwork-courier = CC).

## M1-M7 — DONE

Docs and templates (M1), CLI diagnostics (M2), 2D level authoring (M3), bloom (M4), 3D physics 2.0 and gamepads (M5),
polish found while migrating the examples (M6), their leftovers and the mobile players in CI (M7). Nothing they found is
open; what they built is in [ROADMAP_DONE.md](ROADMAP_DONE.md).

## Decisions of finished milestones

Kept here because later work has to respect them (the full story is in ROADMAP_DONE.md):
- M3: there is no `CameraFollow2D` component; a camera that follows within level bounds is the AI_GUIDE 9.6 recipe.
  `scene.import_ascii` does not keep its legend in the scene, so `factoria validate` checks the Tilemap data instead.
- M4: bloom is flat `Camera` fields (`bloom`, `bloomThreshold`, `bloomIntensity`, `bloomRadius`) because reflection has
  no nested structs. It costs about 5 ms per drawn frame at 1280x720 on llvmpipe (the target was 2 ms); a backend that
  cannot create it logs one error and draws without bloom.
- M5: gamepad bindings keep the names reserved since 0.1 (`GamepadA`, `GamepadLeftStickLeft`...), not `Gamepad:A`; a
  binding matches any of 4 pads; `input.value` is analog with a radial deadzone (`input.deadzone`, default 0.2) and an
  action is down at 0.5.
- M6: file-targeted component edits are the `edits` argument of `scene.import_ascii` (file mode, the
  `scene.set_component` code); scene, prefab and JSON files are written through `fs::write_bytes` (a temporary file
  renamed over the target).
- M8: spheres with `rollWithMotion` keep the arcade model, other spheres are rigid bodies; boxes do not roll
  (`angularDamping` is their spin drag). Mobile exports use the package's prebuilt players (`mode: prebuilt`), the
  engine checkout only when asked for or when factoria runs from a source build (`mode: source`).
- M9: the players ask for OpenGL ES 3.0 and sokol_gfx is told 3.0 even when the driver reports more: the engine uses no
  ES 3.1 feature. On Android, sokol_app's exit in `onDestroy` is turned into `_exit(0)` and the activity is
  `stateNotNeeded`, so the system starts the game again in a new process. macOS exports are signed ad hoc after every
  file is written; Developer ID signing then needs `--force`.
- M10 (2026-10-16): templates stay minimal (the empty ones are a camera and nothing else); a game's AI builds menus
  from the recipe when its game needs them. UI focus comes only through `autoFocus` or `ui.focus`, so Space or A never
  clicks a HUD button.
- M11: a plugin that does not load is a warning, and its reason becomes the script's error.
- M14: headless runs, tests and the editor start in `localization.defaultLanguage` (output and saved scenes never depend
  on the machine); a game in its own window and an exported game start in the best match of the system's languages;
  `FA_LANGUAGE` / `EngineConfig::language` override both. A component with a `key` gets its text overwritten at run time.
  The font chain is the Text's `font`, `localization.languageFonts[language]`, `localization.fallbackFonts`, then DejaVu
  Sans; there is no per-Text fallback list. `align` is explicit (Left is the left edge for right-to-left text too). The
  engine saves neither the language choice nor `ui.textScale`: the game keeps them in `storage`.
- M15: exports ship the import settings of `assets.json` and drop provenance and style.
- M24 (2026-10-20): a direction press moves the focus to the nearest widget lined up with the focused one (overlapping
  it across the direction), and only when there is none to the nearest in that half of the screen; not a 45-degree
  cone, which sent Down from a narrow tab past the row under it. Script vectors keep `length()` as the magnitude (only
  `Color` and `Rect` have a numeric `length`). `game.paused = false` restores the `time.scale` that pausing saved. A
  `storage.json` that does not parse is kept beside the new one and never repaired; the game starts with empty data.
  A dynamic 2D body's `velocity` is relative to the kinematic body it stands on (as in 3D); a game adds no platform
  speed of its own. `onEnable` follows `onStart` on the first activation, and the activation hooks run before the frame
  is drawn. `autoSize` and the right-to-left values are opt-in: `Text.align` `left` / `right` stay explicit (M14),
  `start` / `end` and `Panel.direction` (default `ltr`) follow the language; a `size` a script or file writes is the new
  design size. In file mode `scene.import_ascii` writes prefab references. The catalog's translated texts are for the
  game's own screens and the fake store; Steam, the App Store and Google Play keep theirs in their own consoles.
  M24.15-M24.16 (2026-10-20): the fallback layout (`fallbackLayout`) is chosen again every frame, and the deepest panels
  switch first; `uniformSize` counts only `autoSize` widgets; a script's `ui.layout()` does not log the fit warning.
- M22 (2026-10-21): the system's accessibility settings are `game.accessibility`, not `platform.accessibility`
  (`platform` is the store services); like the language (M14), only a game in its own window reads them, headless runs,
  tests and the editor get the defaults, and the engine applies none of them: the game starts its options from them and
  saves its own choice. `Camera.colorFilter` is the last pass of the frame (HUD included) and is not saved by itself;
  `simulate` changes only the saved screenshot. Headless runs and tests speak nothing and record the lines
  (`game.spoken()`); the web prefers voices on the device, because an online voice sends the text to its provider. A
  caption's lifetime is its sound's unless `captionSeconds` is given (a looping sound needs it). Performance budgets: a
  time over its limit fails only in CI and is measured twice first, memory, draw calls and entities always fail, and the
  engine's own CI fails on a runner with no baseline (`requireBaseline`); a game's check passes there with the entry to
  commit.

## M8. Leftovers of M7, desktop download next steps (L, *proactive*)

Closes the "Found while implementing M7" and "Desktop download: next steps" lists (both in ROADMAP_DONE.md). One worker
branch per package, merged together in PR #29.

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M8.

Left open, not fixable in this repository alone:
- Certificates: an Authenticode certificate or Azure Trusted Signing is needed before the Windows signing step does
  anything (macOS signing is set up since M9). New Authenticode certificates come on a token or a cloud HSM, so the
  `.pfx` path in `scripts/sign-windows.sh` may have to become that service's signing action.
- GitHub-hosted runners cannot run an arm64 Android emulator (no KVM on `ubuntu-24.04-arm`, no nested virtualization on
  macOS) and have no real GPUs; that needs a device farm with an account. `simctl` cannot tap, so iOS touch is not run.
- No real gamepad has been used on Linux or Android; the Android Z/RZ trigger scaling is taken from Android's docs.
- 3D: a kinematic body's own rotation within a sub-step is not swept; in an extreme pile of impacts a body lags in time
  instead of tunnelling.
- The AppImage does not update itself (AppImageUpdate/zsync would), and after an in-place update the Windows "Apps" list
  still shows the installed version.

## M9. Run on Apple hardware (M, *proactive*) — DONE (PR #33 and the `m9-apple-hardware` PR)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M9.

Left open after M9:
- An Apple pad on iOS: same code as macOS, built and run, but not with a real pad. The iOS Simulator shows a virtual
  `Gamepad (MFi)` in slot 0.

Found while implementing M9, not fixed:
- Android: when the activity is destroyed the engine is not shut down (sokol_app calls `cleanup` only while a surface
  exists, and the surface is always gone by `onDestroy`; the process now ends with `_exit`), so a game gets no callback
  when it closes or restarts. `storage` saves on every write, so nothing is lost today.

## M10. Game UI and menus (L, blocker for every store) — DONE (PRs #47, #50, #51, #53)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M10.

Left open:
- `TextField`: the caret stays at the end (no caret movement, selection or IME composition). The Steam Deck floating
  keyboard is M12; mobile on-screen keyboard polish is M16.
- Layout and hit-tests ignore the rotation and scale of UI entities; a `Sprite` inside a container needs an explicit
  `size` (texture sizes are not measured by the layout). 9-slice for `Sprite` came with M18 (`Sprite.slice`).
- Window control on macOS, iOS, Android and a real Linux desktop is compiled in CI but was not run on those systems
  (Windows was). Android pads always report `generic`; X11 `displaySize` is the whole screen, not the usable area; on
  macOS vsync off tears but keeps the display's frame rate (sokol paces frames with a display link).
- Save slots with their menu are M19; a GDPR/COPPA consent screen on these menus is M12's (ads with consent).

## M11. Native plugins per game (L, blocker for M12 and the consoles) — DONE (PR #49 and the `m11/plugins-mobile` PR)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M11.

Left open:
- iOS takes static libraries only: no Swift packages or XCFrameworks (system frameworks, the Swift runtime and
  entitlements came with M12's Apple backend: the plugin's `ios/plugin.json`, docs/MOBILE.md).
- An Android plugin that is only a Maven dependency in its `build.gradle` (no Java/Kotlin sources, no `.aar` / `.jar`)
  keeps `hasCode="false"`; the export cannot see that it brings code.
- A missing ABI's `.so` on Android is not a warning (the module may build it itself); on a device of that ABI the
  plugin just does not load.
- The desktop export copies plugin folders with `std::filesystem::copy`: very deep plugin folders can hit MAX_PATH on
  Windows.

## M12. Platform services API (L, blocker for Steam and for any monetization)

Closes S-01..S-08 (S-09 is in M23), and the Play Integrity, iCloud and Steam Deck keyboard points of the per-store
table. Needs M11.

- A `platform` JS module: achievements, stats, leaderboards, cloud saves, purchases (with restore and receipts), overlay,
  presence, and `platform.has("achievements")`. A fake backend runs in `factoria test` and headless runs, with
  `game.platform` hooks to script store answers in tests.
- Backends as M11 plugins, in this order: Steamworks (S-02; `steam_appid.txt` in development runs), StoreKit 2 and Game
  Center (S-04, S-05), Play Billing and Play Games v2. Then Epic Online Services and GOG Galaxy (S-03), ads with
  consent (Google UMP, Apple ATT; S-06), analytics and remote config (S-07), push notifications and deep links (S-08).
- Steamworks also brings the Steam Deck's on-screen keyboard (`ShowGamepadTextInput`, the floating keyboard) for M10's
  text field; M16's keyboard is mobile only.
- Play Integrity (Google Play) next to Play Billing, and iCloud as a cloud-save backend next to StoreKit.
- Later: the purchase SDKs of Android stores outside Play (Amazon Appstore, Samsung Galaxy Store, Huawei AppGallery).

Acceptance criteria:
- Achievements and a purchase flow pass with the fake backend in a test (on the M10 menus fixture).
- With the Steamworks plugin and Valve's test AppID 480, an exported desktop game unlocks an achievement (manual check,
  steps in the docs).

Done so far (package A, branch `m12/platform-api`): the API, the fake backend and plugin ABI v2; no store backend yet.
- **`fa_services`** (new module, `fa/services/platform.h`): the `"platform"` catalog of factoria.json (achievements,
  stats, leaderboards, products, per-backend store `ids`, `backend`; teaching errors, `factoria validate` and the
  project schema), the request protocol `(method, args) -> one answer`, the `PlatformServices` dispatcher (ids checked
  and `storeId` filled in before a backend sees a request; answers from any thread, delivered at the start of a frame),
  the `PlatformBackend` interface, the deterministic fake backend (scripted answers, `delayFrames`, `signedIn`, events,
  a request log) and the "none" backend. The `platform.*` commands (`state`, `reset`, `respond`, `emit`, `set_fake`).
- **Scripts**: `platform` in the `factoria` module (every call a Promise; mistakes throw with a "did you mean", store
  failures reject with `.code` and `.hint`; `platform.on` for `purchase`, `overlay`, `player`), and `game.platform`
  in `factoria:test`; `await` works in tests.
- **Plugin ABI v2** (`fa_plugin.h`): `add_backend`, `FaRequest`, `resolve`, `reject`, `emit`; version 1 plugins load
  unchanged. Backend choice: `platform.backend`, `EngineConfig::platformBackend/platformFallback`; headless runs and
  tests use the fake, an exported game without a store plugin gets "none" (never free purchases). `project.new_plugin`
  takes a `template` (the folders of `platforms/plugins/`, none yet).
- **Docs and fixture**: `docs/PLATFORM.md` (API, catalog, errors, fake store and testing, writing a backend plugin);
  the menus fixture has a shop (consumable gems, a non-consumable, restore) and `tests/platform.test.js`: buying gems
  through the pad adds them and finishes the transaction, a cancelled buy and a `network` failure grant nothing, a
  delayed answer shows "waiting", restore returns the non-consumable, an achievement unlocks during play and the
  overlay event pauses the game (the first acceptance criterion).

Done so far (package B, branch `m12/steam`): the Steamworks backend.
- **`platforms/plugins/steam`** (the `"steam"` template of `project.new_plugin`, a C++17 plugin with no Valve file in the
  repository): it loads Valve's redistributable at run time (`steam_api64.dll`, `libsteam_api.dylib`, `libsteam_api.so`,
  next to the plugin first), declares the part of the flat API it uses itself and finds the versioned interfaces by name
  (checked against SDK 1.58 to 1.64; a newer SDK such as 1.65 is used with a warning when every function the plugin calls
  is present, probing up to five interface versions above the known ones; anything else is refused with what was tried). Steam
  starts in `fa_plugin_init`
  (`SteamAPI_InitFlat`, `SteamAPI_Init` on old libraries), callbacks run by manual dispatch in the plugin's `frame`, and
  the dev app id comes from `steam_appid.txt` (project folder or working folder; 480 is Valve's test app). Every failure to
  start is a teaching log line and the engine falls back (fake in development, none in an exported game).
  Achievements (unlock, progress, list, reset), stats, leaderboards (created on first use, keep-best uploads, top, around
  and friends), Steam Cloud (`<key>.json`), DLC purchases (`pending` through the overlay cart, a `purchase` event when the
  DLC arrives), overlay, rich presence, and the events `overlay`, `purchase`, `player`. Consumables and subscriptions are
  `unavailable` (Steam's microtransactions need the game's own server). The command `steam.status` shows what the plugin found.
- **Tests**: a mock of the Steamworks library (`platforms/plugins/steam/tests/mock_steam_api.cpp`, built as a shared library
  with the redistributable's file name, in a current, an older (SDK 1.58 to 1.60), a next (one interface version above the newest known) and a far-future variant) and ctest `steam_plugin_*`
  (Linux, Windows, macOS): the real plugin in an Engine with `platformBackend="steam"` covers every method and event, stats that
  load late, Steam failing to deliver or to start, a late answer after the engine ended, a stray call result, a missing
  library, Steam not running, no app id, the services again on a library with newer interface versions (used, one warning), a
  library too far ahead (refused), and the exit on Linux and macOS (stats stored, `SteamAPI_Shutdown`). `tooling` tests build
  the plugin through `platform.add_backend` with an SDK folder and a .zip.
- **`platform.add_backend {"backend": "steam"}`**: writes and builds the plugin, copies the three libraries from the SDK folder or
  .zip, writes `steam_appid.txt` (default 480), and `factoria export` never ships that file. Docs: the Steam section of
  `docs/PLATFORM.md` with the numbered manual check against app 480, and `plugins/steam/README.md`.

Left open (Steam):
- **The manual check with app 480 has not run**: it needs a Steam client and account, which the machine that built this did
  not have (`docs/PLATFORM.md`, "Manual check with Valve's test app 480"). Everything above is tested against the mock only,
  so struct layouts, callback ids and interface versions rest on the public Steamworks headers (SDK 1.58a to 1.64); a real
  SDK 1.65 library (it replaced `ISteamUtils::IsRunningOnSteamDeck`) has not been tried either. Whether
  Steam's overlay appears over the engine's Metal (macOS), OpenGL (Linux) and Direct3D 11 (Windows) windows is unchecked.
- **The Steam Deck on-screen keyboard for `TextField` is not wired.** The plugin API has no hook for it: it needs (1) a
  notification to the plugin when a text field takes or loses focus (with the field's rectangle, its text and whether it
  is multi-line; `Input::keyboard_shown()` is today applied by the windowed runtime to the phone soft keyboard only) so the
  Steam plugin can call `ISteamUtils::ShowFloatingGamepadTextInput` / `ShowGamepadTextInput`, and (2) a call for the plugin
  to hand text back to the focused field (`FloatingGamepadTextInputDismissed_t` / `GamepadTextInputDismissed_t` and
  `GetEnteredGamepadTextInput`). Players on the Deck can use Steam's own keyboard (Steam + X).
- Steam Inventory, microtransactions (`ISteamMicroTxn`), Steam Input and the workshop are not wrapped; there is no `SteamAPI_RestartAppIfNecessary`
  (a shipped game started outside Steam runs without platform services); prices of DLC are not shown (Steam gives them on its store page).
- On Windows the plugin does not call `SteamAPI_Shutdown` at exit (a DLL's exit handlers run after Steam's own DLL is gone);
  stats are stored every frame, so only the last frame's changes could be lost.
- Every engine that loads the plugin starts Steam, `factoria test` and MCP sessions included; the plugin API cannot tell a plugin
  which backend the engine chose, so the fake-store runs show up as "playing" in Steam. A lazy start needs an API call for
  "the engine uses your backend".

Done (package C, branch `m12/apple`): the Apple backend, `platforms/plugins/apple`, backend `"apple"` on iOS and macOS.
- **The plugin** (Swift, built with `xcrun swiftc` by its CMake file; a C file is the entry point): StoreKit 2
  purchases (products, buy with Ask to Buy, finish, restore, `purchase` events for updates and unfinished transactions;
  receipts are JWS), Game Center (sign-in with a `player` event, achievements, leaderboards, the access-point overlay),
  iCloud key-value cloud saves, and the command `apple.status`. No stats and no presence (Game Center has none).
  Tests (`apple_backend_tests`) load the real dylib into a real Engine with no signature or Apple Account: every
  request is answered once and in time, each refusal teaches.
- **Plugin manifests**: `ios/plugin.json` / `macos/plugin.json` (system frameworks, the Swift runtime, entitlements),
  merged by the exports: the iOS project links StoreKit and GameKit and the Swift runtime and is signed with
  `factoria_player.entitlements`; the macOS export writes `<game>.entitlements` for the developer's own signing.
  `factoria export --platform ios` also writes `Products.storekit` from the catalog and wires it into the Xcode
  scheme. `platform.add_backend {"backend": "apple"}` writes, declares and builds the plugin. CI: the `ios` job
  links the plugin into the simulator app and checks `Apple backend ready`, `probe backend=apple` and a Game Center
  answer (`FA_IOS_APPLE_PROBE=1`).

Left open for the Apple backend (manual checks, docs/PLATFORM.md "Manual checks"): a real purchase, Ask to Buy, restore,
Game Center sign-in, achievements, leaderboards and iCloud sync need App Store Connect, a development-signed app and a
sandbox account, so no CI job runs them. The scheme reference to `Products.storekit` and the file's schema version are
not yet checked in Xcode itself. A macOS app needs the developer's certificate and provisioning profile for Game Center
and iCloud (the export is ad hoc signed). No `cloudChanged` event when iCloud brings a newer save from another device.

Done (package D, branches `m12/integrity` and `m12/googleplay`): the Google Play backend and a new platform service.
- **`integrity`**, the eighth service (`fa_services`, `platform.integrity.token(challenge)` -> `{ token }`): a signed token
  that vouches for the app and the device, for the game's server to verify. The engine checks the challenge (16 to 500
  characters of URL-safe Base64) and the shape of the answer; the fake answers `fake-integrity-<n>`. Steam and Apple do not
  offer it (`unavailable`).
- **`platforms/plugins/googleplay`** (the `"googleplay"` template, backend `"googleplay"`, Android only): a C bridge (JNI:
  every request goes to `Backend.request` in Java, answers come back through `RegisterNatives` callbacks) and a Gradle
  module in Java on Play Billing 9.1, Play Games Services v2 22.1 and Play Integrity 1.6. Purchases (consumables are
  consumed, the rest acknowledged; pending payments; `purchase` events for unfinished purchases at start and on every
  resume; receipts are Google's signed purchase JSON and signature), the overlay (Play Games screens, the Play Store page)
  and integrity are always on; achievements, leaderboards (25 rows a call) and Saved Games only with a Play Games project
  id in `games-ids.xml` (the plugin removes Play Games' auto-start provider and starts it only then). No stats and no
  presence. Each request answers once, with a 30 s watchdog (restore 120 s). The command `googleplay.status` lists what
  the device lacks.
- **`platform.add_backend {"backend": "googleplay", "playGamesId"}`**: writes and declares the plugin, writes the project id,
  builds the bridge for arm64-v8a and x86_64 with the Android SDK's NDK, CMake and Ninja, and lists the Play Console steps
  with the catalog's ids (product ids Play refuses, achievements and leaderboards without `ids.googleplay`). The exported
  Android project now has `android.useAndroidX=true` (Billing and Play Games need AndroidX).
- **CI**: `android-apk` sets the backend up with `add_backend`, checks the APK (both libraries, the plugin's and Google's
  classes in the dex, the merged manifest and resources); `android-emulator` (an image with no Google Play) checks
  `Google Play backend ready`, the services, `googleplay.status`, and that `signIn()` and `integrity.token` come back
  through JNI as teaching `unavailable`s. Tooling tests cover the setup command and the export of the module.

Left open (Google Play): **nothing has run against Google's services.** Purchases, Play Games and Play Integrity need a
Play Console app, a build on a testing track, license testers and a phone with Google Play (docs/PLATFORM.md section 7,
"CI and manual checks"); CI's emulator has no Google Play, and this machine has no NDK, so the Java was only compiled with
`javac` against the real libraries before CI. Play Games events (increment-only counters) are not mapped to stats;
`achievements.reset()` and the "friends" overlay are `unavailable`; Play Integrity uses the classic request (no Standard
API, no cloud project number, so an app distributed outside Play cannot get tokens). Apple's App Attest is not an
`integrity` backend yet.

Left open (the next M12 packages): Epic Online Services and GOG Galaxy, ads with consent (and the GDPR/COPPA consent
screen, moved here from M22), analytics and remote config, push
notifications and deep links, the Android stores outside Play. `PlatformServices` keeps no receipts or entitlement cache: a
backend answers `restore()` itself. Overlay and presence are one call each; there is no `achievements.onUnlocked`
event, rich presence has no localization, and `platform.stats.add` is a get then a set (not atomic across devices).
Cloud saves take JSON values only (no binary blobs, no conflict resolution beyond "last write wins" in the fake).

Next M12 packages, ranked 2026-10-22 with Clockwork Courier's entries: 1. ads with consent on M26.9's API and fake:
Google UMP and AdMob, Apple ATT and the GDPR/COPPA screen (CC/FB-0028); 2. leaderboard periods on Steam, Game Center and
Play Games (CC/FB-0030); 3. the Steam Deck's keyboard with Steamworks (CC/FB-0020; M26.17 makes the in-game one);
4. analytics and remote config (after M19's networking); 5. push notifications and deep links; 6. Epic Online Services
and GOG Galaxy; 7. the Android stores outside Play. A game asked for the first three only.

## M13. Store-ready desktop export (M-L, high) — DONE (PRs #65, #66, #67, #68 and the `m13/sign` PR)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M13.

Left open:
- Crash reports have no upload URL yet (it needs M19's HTTP client). A stack overflow is reported on the main thread
  only, and the player ships no PDB, so a Windows minidump has addresses without symbols.
- Store uploads were tested against a fake store tool only: no real steamcmd, butler, BuildPatchTool or Galaxy Pipeline
  Builder run yet. GOG's Pipeline Builder takes its password as a command-line argument, which other processes can see.
- Native plugins still load from files next to `game.pak` (a shared library cannot load from inside the archive). The
  editor has no switch for `export.scriptBytecode`. A `--release` export runs on macOS and Linux only in CI.
- `sign.macos` was tested with fake `codesign`, `notarytool` and `stapler`: a real Developer ID signature and
  notarization are untested. No Flatpak (AppImage only). The editor's setup panel has no install button for the
  `appimage` component. Authenticode stays in M8.
- The sniper build was run with Docker, not Podman; the sniper SDK image tag is pinned and is bumped by hand. The
  sniper build has no libcurl, so the Linux download's AI features need the `curl` program.

## M14. Localization (L, blocker for a global release) — DONE (PRs #73, #74 and the `m14/finish` PR)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M14.

Left open:
- Line breaking is spaces plus Chinese, Japanese and Korean with a simple kinsoku rule, not UAX #14: no breaks inside Thai,
  Khmer or Lao words, after hyphens or around numbers with units. Line height comes from the Text's own font, so a much
  taller fallback font can touch the next line.
- Indic and Thai text is shaped by HarfBuzz but no test covers it. No vertical text, colour emoji or inline styles.
- `TextField` ignores right-to-left text: the caret stays at the end (M10's caret limits) and nothing is mirrored.
- No locale-aware formatting of numbers, dates or currency. Plural rules are written for 17 languages; the others use
  English's one/other.
- The translators' CSV and XLIFF files were tested as formats only: no spreadsheet or CAT tool was run, and the CSV import
  takes UTF-8 only (Excel's "CSV UTF-8").
- The system language was read on Windows only; the Apple, Android and Linux code ran in CI apps whose system is English.
- The editor's own interface is English only; its viewport always shows the default language.
- HarfBuzz and SheenBidi add about 700 KB to a Release player (measured with GCC before the linker drops unused code).

## M15. AI asset generation and import pipeline (L, blocker for "the AI does everything") — DONE (PRs #52, #55, #56, #57)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M15.

Left open:
- SDF/MSDF font atlases: the runtime rasterizes TTF/OTF at any size already; distance-field text belongs with the text
  work of M10/M14.
- Video import: waits for M19's video player, which decides the format.
- Importers: OBJ polygons are triangulated as fans (concave faces come out wrong); Aseprite blend modes are composed as
  normal and tilemap layers are skipped (both warn); PSD imports the flattened image only; FBX skins and animations are not
  imported (M18 plays skins and clips from glTF/GLB only).
- Providers: Meshy makes untextured preview meshes only; ElevenLabs music is instrumental; seeds are honoured by `fake`
  and `asset-command` only, reference images by OpenAI and `fake` only (the others warn).
- Audio: normalization has no limiter (the gain is capped so the peak stays under -1 dBFS); Android and iOS never
  measure loudness at run time, so sounds need the `analysis` records `assets.analyze_audio` or the export writes.
- Textures: ASTC and ETC2 are sampled in the Linux CI (llvmpipe) and were checked by software decoding, not on a phone
  GPU; ETC2 keeps less colour detail than ASTC and BC7 (one brightness offset for red, green and blue); KTX2 files use
  no Zstd supercompression (none vendored); textures whose sides are not multiples of 4 ship as PNG.

## M16. Mobile store-ready (M, high on mobile) — DONE (PR #77 and the `m16/touch-gamepad` PR)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M16.

Left open:
- Nothing ran on a real phone, the on-screen gamepad included (tested headless and drawn by the GPU tests only). The Android JNI code was only syntax-checked with the NDK before CI; the iOS code
  (`mobile_apple.mm`, the safe insets in `sokol_impl_apple.m`) and the privacy manifest's place in the bundle were never
  built on a Mac before CI. Predictive Back was not tried on an API 36 image.
- The Android keyboard takes plain key events only: no composed text (predictive, swipe, CJK, emoji, voice); the IME
  calls run on the sokol loop thread, not the UI thread. iOS vibration has no duration control (three haptic strengths,
  then the system buzz).
- No upload was ever sent: the altool and fastlane supply flags come from their docs, and a debug-signed AAB is detected by
  its file name and the keystore setting, not by reading its signature.
- Apple's reason codes and the store privacy answers in docs/MOBILE.md were written from the stores' docs as of 2026-10;
  recheck them when Apple or Google change the forms.
- On-screen gamepad: the stick is fixed where it is drawn (no floating stick that appears under the thumb), the knob is
  always a disc (no knob texture), a finger cannot slide from one button onto another, and a mouse click does not press
  the controls. The touch pad has no number, so `input.gamepad(i)` never sees it.

## M17. Web export (L, high) — DONE (the `m17/web` PR)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M17.

Left open:
- Only Chrome and Edge ran it (headless Chrome in CI): not Firefox, Safari or a phone browser, no touch input, no real
  gamepad (the Gamepad API mapping was checked with a faked `navigator.getGamepads`), no audible-sound check (only the
  AudioContext state and the log lines), no slow connection for the progress bar, no fullscreen from a script.
- No upload: the zip was checked against itch.io's documented limits (index.html at the root, 1000 files, 500 MB, 200 MB
  per file, 240-character paths), never uploaded. `publish` (butler) and the CI workflow template do not know web yet.
- No native plugins and no store backend on the web (`platform.*` answers "none"); no `log.txt` or crash reports (the log
  goes to the browser console). Textures ship as PNG (WebGL2 guarantees no compressed format).
- The wasm is about 6.5 MB (2.5 MB gzipped) at -O3; no size work yet. Box2D runs its scalar path (no `-msimd128`).
- The player exports `_emscripten_stack_get_current` and `__emscripten_stack_restore` by hand: Emscripten 6.0.10 does not
  link without them, cause not found. `web-debug` configures but was not compiled.

## M18. Animation and production 3D (L, high for 3D games) — DONE (the `m18/integration` PR)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M18.

Left open:
- Custom shaders per material: built (P1-P5 of [docs/design/CUSTOM_SHADERS.md](../docs/design/CUSTOM_SHADERS.md),
  guide docs/SHADERS.md; the factoria downloads carry sokol-shdc next to `factoria`, D3). Left: P6 custom lighting waits
  for a game that asks; the material inspector is M20.
- Rendering ran on D3D11 (WARP) and Linux llvmpipe only: never on Metal, a GLES3 phone or WebGL2. IBL is a procedural
  sky approximation (no environment texture or prefiltered cubemap); lighting stays in gamma space; the shadow map still
  fits every caster (no cascades), so shadows of big scenes are blurry. Blended meshes only batch with neighbours in their
  far-to-near order. glTF materials with a `pbrMetallicRoughness` block use their own metallic/roughness, not
  `MeshRenderer`'s.
- Animation: at most 64 joints and only the first skin per model (more = bind pose and a warning); no morph targets,
  layers/masks or root motion; node animation of meshes without a skin is ignored; a changed .gltf is not reloaded under
  a running Animator; starting a clip during a cross-fade drops the older outgoing clip. Every animated model is its own
  draw call (not instanced).
- 3D physics: convex hulls over 256 vertices are reduced to 256 extreme points; dynamic capsule/convex bodies use the
  inertia of their bounding box; a box or hull on a mesh rests on ray-probed corners (no full manifold); rays that graze a
  capsule or hull under ~3 degrees can miss; jointed bodies never sleep; the character controller is not carried by
  moving platforms; the collider mesh cache is not refreshed when a file changes while the game runs.
- 2D: at most 16 `Light2D` per frame, no spot lights, shadows or per-layer lights, no lit screen-space sprites;
  `Parallax` repeats Sprites only; `debug_state` does not list `Joint2D`s and rebuilding a body resets its joint's
  reference angle; the `scene.import_ascii` flip/rotate legend keys have no test of their own.

## M19. Runtime features (M each, medium; take them when a game needs them)

Closes F-07 (effects), F-09, F-10 (except the Android shutdown, M9), F-11, F-14, F-16, F-18, H-07 and U-08.

- Networking: `http.fetch` (a Promise) and WebSocket in JS on every platform; real-time multiplayer later.
- Saves: slots with their menu (on M10), a version field with a migration hook, optional encryption, cloud through
  M12's `platform`.
- Pathfinding: grid A* on a Tilemap, ~~a navmesh for 3D (done in M26.10)~~, a behaviour-tree helper module.
- Video: a video player component for logos and cut-scenes (e.g. pl_mpeg, MIT).
- ~~`scene.loadAsync` with progress~~ (done as `scene.preload`, M26.7).
- Split screen: a viewport rectangle on Camera (four gamepads already work).
- Audio: effects on the buses (low-pass, reverb), ducking and snapshots.

Acceptance criteria: each item ships with its doctest or JS test and its docs, like any command or component.

Ranked 2026-10-22: the navmesh and `scene.loadAsync` moved to M26 (M26.10, M26.7) because Clockwork Courier needed them.
The rest, in this order: 1. video, for a studio intro (CC/FB-0051; recording an .mp4 is M26.19's); 2. save slots with a
version and a migration hook (every store game saves); 3. networking (M12's analytics and remote config need it);
4. audio effects, ducking and snapshots; 5. grid A* on a Tilemap and the behaviour-tree helper (they can share M26.10's
search); 6. split screen. A game asked for the first one only.

## M20. Editor and tooling (L, medium-high) — DONE (PRs #134-#142, the `m20/debugger` and `m20/finish` PRs)

Closes H-01, H-02, H-03, H-05, H-09 and the editor part of H-06.

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M20. The three acceptance criteria hold: the editor autotest edits a field in
the Inspector and the scene file changes, `cli_dap` drives the DAP server over stdio and stops at a breakpoint in a
template behaviour, and `play.report` and `perf.profile` list each behaviour class with its milliseconds per frame.

Left open:
- Later, each its own item when users ask: tile painting and object placement in the viewport, an animation timeline,
  particle and material editors.
- Revert an AI run: the first checkpoint of a project copies every file into `.factoria/checkpoints/` (big assets take
  their size again on disk) on the editor's thread, before the run starts; it was not timed on a big project. Files
  outside the project and in folders starting with `.` are not covered. Tried with the autotest's scripted provider
  only, not with a real AI run (every provider goes through the same start and finish).
- Not taken: an example script and test in the empty templates (they stay minimal).
- The script debugger (docs/design/SCRIPT_DEBUGGER.md, "Left open"): attaching to the editor's running game (needs the
  game off the editor's UI thread, or a pause that keeps the editor drawing); restart frame, step back, data and column
  breakpoints; publishing the VS Code extension to the Marketplace and Open VSX. Not yet tried by hand: F5 in VS Code
  itself and the `play` mode (`cli_dap` covers headless and test mode over stdio); on Windows the protocol's private fd
  and the case-insensitive path mapping are covered only by CI.

## M21. Docs and material for shipping (M, high) — DONE (PRs #115-#124, the `m21/reference-game` and `m21/ai-cost-guide` PRs)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M21.

Left open:
- LK/FB-0023, the MSIX export for the Microsoft Store, was fixed by M23 (`6364e8f`).
- docs/FIRST_GAME_WITH_AI.md was not played through with a real AI: its rounds depend on what the AI answers, so only the
  buttons, keys and commands it names were checked against the editor's code.
- docs/AI_COSTS.md has one measured game (Lantern Keep, six Sonnet 5.5 workers on 2026-10-19): output tokens are
  estimated from the written content and the totals are a floor, because the model's thinking is not recorded. Its
  prices are as of 2026-10-20.
- Store facts (docs/PUBLISHING.md, the `assets.draw_capsules` sizes) are as of 2026-10; the GOG and itch.io sizes have
  no official page.

## M22. Production quality and legal (M, high) — DONE (PRs #126-#132 and the `m22/bookkeeping` PR)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M22.

Left open:
- Performance budgets run where ctest runs: Linux GCC (llvmpipe), Windows MSVC (D3D11 WARP) and macOS. The web, Android
  and iOS jobs have none. A GitHub runner whose time differs from the committed baseline gets its entry refreshed from
  that runner's output, never looser tolerances.
- Text to speech was not heard by ear anywhere: on Windows SAPI reports available and speaks with the en-US and es-ES
  voices; the macOS, iOS, Android, Linux and web backends are only built by CI. docs/MENUS.md has the manual check.
- The system's accessibility settings: on Windows the reader returned the defaults, matching the registry; no setting
  was toggled to see a change on any system. macOS gives text size 1 (it has no system text size for apps), Linux reads
  GNOME only (through `gsettings`), the web has no text size and no screen reader.
- The game's widgets are not handed to the system's screen reader (UI Automation, NSAccessibility, TalkBack): `ui.speak`
  talks instead, behind the game's "read menus aloud" option.
- Captions: the speaker name does not follow a language change (no `speakerKey`; pass `i18n.t(...)`), and a sound
  shorter than one frame never shows its caption.
- The colour filter goldens were made on WARP; Metal, GLES and WebGL2 are checked by CI only.
- Lantern Keep does not use M22's features yet (the colour filter, the system's settings, reading menus aloud,
  captions); the menus fixture does.

## M23. Closed stores and consoles (L each, later) — Mac App Store and MSIX DONE (the `m23/stores` PR)

Closes E-08 and S-09, plus the Mac App Store and Microsoft Store rows of the report. Needs M11 and M12.

- Mac App Store: App Sandbox entitlements, Apple Distribution signing and a provisioning profile, a `.pkg` from
  `productbuild`, upload through the App Store Connect API (today only the Developer ID flow outside the store exists).
- Microsoft Store and PC Game Pass: MSIX packaging of the game (the engine's own installer is not one), Partner Center
  upload, the Microsoft GDK for Xbox services. Lantern Keep (LK/FB-0023) asks for `export.windows.msix` (identity name,
  publisher, display name, tile logos made from the icon) writing an `.msix` next to the folder, unsigned or signed with
  a `.pfx` from the environment, then `publish.microsoft`.
- Consoles (Switch, PlayStation, Xbox): their SDKs are under NDA and cannot live in this MIT repository. What this
  repository can do is the seam: a platform layer and render-backend interface (D3D12/GDKX, NVN, AGC) that a private M11
  plugin implements, and certification checklists (TRC, Lotcheck, XR) once a licensed developer contributes them.

**Done so far (Mac App Store).** `sign.macos` takes `distribution: "appStore"`: App Sandbox entitlements (plus the
plugins' and `export.macos.entitlements`, with the identifiers read from the provisioning profile), nested code signed
with the store identity (helpers inherit the sandbox), the profile embedded, `codesign --verify --deep --strict` and a
read-back of the entitlements, then `productbuild` and `pkgutil --check-signature` for `<slug>-macos.pkg`.
`export.macos` gained `buildNumber`, `usesNonExemptEncryption` and `entitlements`; `publish.appstore` uploads the `.pkg`
(`platforms: ["macos"]`, `altool --type macos`). The macOS-only test signs an export ad hoc with the sandbox, verifies it
and runs it (the sandbox container appears); the rest is covered with a fake process runner.
Left open (Mac App Store): a real signing with Apple certificates and a real upload (they need a paid account) were not
tried; `altool --type macos` is unverified on Xcode 27; the arm64-only rule is only a `lipo` warning, not checked against
Apple's documentation; the sandbox's effect on the player (saves, network) is tried only by the ad hoc run; no
`factoria validate` check beyond the settings' own and `sign.macos`'s warnings.

**Done so far (MSIX and Microsoft Store).** `export.windows.format` / `--format msix` writes a deterministic, unsigned
`<slug>-windows.msix` from any host (shared zip writer with a ZIP64 end record as MakeAppx writes, block map, manifest,
logos from the icon, no `resources.pri`), `export.windows.msix` holds the Partner Center identity (editor Windows tab,
Export window menu, validate warning), `sign.windows` signs it with a `.pfx` (signtool, or osslsigncode 2.9 or newer;
Windows-only self-signed test certificate) and `publish.microsoft` uploads it with `msstore`. Doctests unzip the package
and check the hashes, manifest and content types with an independent reader; sign and publish run against fakes. By hand
on macOS, osslsigncode 2.14 signed an exported package and verified it.

Left open (MSIX): the package has not been installed on a real Windows PC with `Add-AppxPackage` (the acceptance
criterion below); loose qualified logos without a `resources.pri` are unverified; a real upload needs a Partner Center
account (msstore was never run for real); `testCertificate` is Windows-only; PC Game Pass and the GDK are untouched.

Acceptance criteria: a sandboxed macOS export passes `codesign --verify --strict` with the App Sandbox entitlement and
runs (met: the macOS-only doctest signs ad hoc, verifies and runs it); an MSIX of an exported game installs with
`Add-AppxPackage` (not met yet: it needs a run on a Windows PC; osslsigncode signs and verifies the package on macOS).

## M24. Found by the reference game (S-M each, medium; 37 Lantern Keep entries, all fixed) — DONE (PRs #95-#113)

What Lantern Keep found that no other milestone covers, triaged 2026-10-19. None is a blocker or major: each package
removes a workaround a game's AI had to write. When one merges, mark its entries `fixed-in-engine` and let Lantern Keep
drop the workaround (its `workaroundFiles` say where).

**M24.1-M24.16 are done** (PRs #95, #96, #98, #99, #100, #101, #103-#110, #112, #113 and the `m24/bookkeeping` and
`m24/bookkeeping-2` PRs; what they built is in [ROADMAP_DONE.md](ROADMAP_DONE.md), M24.1-M24.6, M24.7-M24.14 and
M24.15-M24.16). Left open from them:
- M24.6: the web (IndexedDB) and mobile save paths run the same code but were not run with a damaged file; the save
  recipe with versions and migration is M21's.
- M24.8: saving a scene while a widget is grown by `autoSize` (another language or a bigger text size than the design)
  writes the grown size as its design size.
- M24.13: anchors and pivots, the inside of a `Toggle` and a `Slider` and `ScrollList` content are not mirrored
  (LOCALIZATION.md section 6 has the HUD-corner recipe). The golden `menus_ar.png` was made on D3D11 hardware, the others
  on WARP.
- Lantern Keep: at 200 % text in German the main menu's title overlaps the logo (the game's layout, not the engine).
- `editor_autotest` can time out when `ctest` runs while other builds load the machine (alone it passes in about 40 s).

Next: M25 below, a second reference game, to find what M19 and M12's next packages should be. The MSIX package waits for
an install on a Windows PC (M23's acceptance criterion); M23's consoles wait for a game that needs them. No ranked entry
is open.

## M25. A second reference game: 3D and mobile (L, high) — DONE (the `m25/reference-game` PR)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M25.

Left open:
- The 54 open Clockwork Courier entries were triaged 2026-10-22 ("Next engine milestones" above): 50 are M26's
  packages, below.
- The exports ran on the iOS Simulator, an Android emulator, a browser pane and macOS on one Mac, not on real phones;
  the Windows and Linux exports were not run. In-app purchases were tested on the engine's fake store only: StoreKit
  needs Xcode and `Products.storekit`.
- The trailer replays of `rooftops_3` and `market_3` drift after about 700 frames; the shots are cut before
  (examples/clockwork-courier/SHIPPING.md, "Trailer").

## M26. Found by the second reference game (S-L each, high; 50 Clockwork Courier entries)

What Clockwork Courier (M25: 3D, mobile first) found, triaged 2026-10-22. Eleven entries are major: each forced the
game's AI into a workaround a store game should not need (a Python script that rewrites glTF files, a letter grid for
names, a wall-clock date). Ordered like M24, by score (occurrences x severity weight) per unit of size, with two
exceptions: a package that needs another one comes after it, and packages that edit the same files say so (one worker
after the other, never two at once). Each ships with its doctest or JS test and its docs. When one merges, mark its
entries `fixed-in-engine` and let Clockwork Courier drop the workaround (its `workaroundFiles` say where); the store
backends of M12 and M19's video player stay in their milestones.

### M26.1 Commands write only what they change (S) — CC/FB-0016, CC/FB-0047

Done (branch `m26/commands-write-only`): `scene.format` without `paths`, `all` or `check` writes nothing and teaches;
`dryRun` and unknown-argument errors on `platform.add_backend` and `project.new_plugin`; one JSON patcher
(`tools/common/src/json_patch.cpp`) used by both and by `save_export_settings`; plugin templates have a `.gitignore`.

- `scene.format` with neither `paths` nor `check` writes nothing: it fails with a teaching error that says how many
  files would change and names the first ones; formatting the whole project takes `all: true`. The validator's hint that
  suggests `scene.format` (validate.cpp) names the files, and every doc that shows the call with no arguments
  (AI_GUIDE.md, CLI.md, MAKE_BY_HAND.md, MENUS.md, the templates' AGENTS.md) and the editor's tools test pass `paths`.
- `platform.add_backend` and `project.new_plugin` honour `dryRun` (they list the files and keys they would write) and
  refuse an unknown argument with a "did you mean". They patch `factoria.json` instead of rewriting it: one JSON
  patcher in `tools/common` (from `save_export_settings`) changes the keys asked for and keeps the order, the formatting
  and the other keys. The plugin templates get a `.gitignore` for their build output.

Acceptance: tooling tests: `scene.format {}` on a project with an unformatted scene changes no file and fails naming
`paths` and `all`; `add_backend {"dryRun": true}` writes nothing; a real `add_backend` leaves every other line of a
hand-ordered `factoria.json` as it was.

### M26.2 Character controller on moving and dynamic bodies (M) — CC/FB-0010, CC/FB-0011

Done (branch `m26/character-platforms`): kinematic platforms carry a character (displacement and turn;
`carriedByPlatforms`), the character weighs on the dynamic body below (`applyWeight`, `mass`) and pushes free bodies
with `pushStrength` but never a jointed one; Clockwork Courier's workarounds are gone.

- `physics.moveCharacter` adds the displacement (and the turn) of the kinematic body the character stands on, as it
  already does for dynamic ones (physics3d_character.cpp); `CharacterController3D.carriedByPlatforms` (default true)
  turns it off. The comment in `physics.h` on what carries a character is fixed.
- The character weighs on the dynamic body below it (`CharacterController3D.mass`, used when `applyWeight` is on) and
  pushes the dynamic bodies it walks into with `pushStrength`; it never shoves a body held by a joint (a seesaw on its
  pivot, a bridge plank), which still tilts under its weight. AI_GUIDE.md's 3D physics section shows a moving platform
  and a seesaw.

Acceptance: `fa_test_physics` cases: a character on a moving kinematic platform keeps its place on it for 300 frames
(and slides off with `carriedByPlatforms: false`); a seesaw tilts toward the side the character stands on and stays on
its pivot; a free crate is pushed, a jointed one is not.

### M26.3 Calendar date and app lifecycle (M) — CC/FB-0019, CC/FB-0035

Done (branch `m26/calendar-lifecycle`): `game.today()`, `game.setDate`, `--date` and the replay date;
`game.on("suspend"|"resume"|"focus"|"blur")`, `game.focused`, `pauseOnSuspend` and the test hooks; Clockwork Courier
uses them.

- `game.today()` returns `{year, month, day, weekday, utcOffsetMinutes, iso}`: the real date in a player, a fixed date
  (`EngineConfig::date`) in `factoria test` and headless runs, the recorded one when a replay plays. `game.setDate(iso)`
  in `factoria:test` and `--date` on the CLI set it. SCRIPTING.md tells games to read the date there, never through
  `Date`, next to `world.rng`.
- Scripts see the app's life: `game.on("suspend" | "resume" | "focus" | "blur", fn)` (the runners already get these
  events, runners.cpp) and `game.focused`. A project setting `pauseOnSuspend` (default true) pauses the game and the
  music while the app is in the background. Test hooks `game.suspend()` and `game.resume()`. MOBILE.md, "Lifecycle",
  says what a script sees.

Acceptance: script tests for a daily seed from `game.today()` under `game.setDate`, a replay that keeps its date, and a
pause menu opened by `game.suspend()`; a headless run with `--date 2026-02-29` fails with a teaching error.

### M26.4 Rigid glTF animation and several skins (M) — CC/FB-0001, CC/FB-0002

Done (branch `m26/rigid-animation`): rigid skins for meshes on animated nodes, one palette per skin, Clockwork Courier
imports the original robot and dog (no `skinify.py`).

- Meshes that are children of animated nodes (a body part under a bone, or an animated mesh node with no skin at all,
  as in RobotExpressive and Kenney's cube pets) follow their node: the importer gives them a rigid skin of one joint
  (`parse_skeleton`, skeleton.cpp), so the Animator plays them with no change to the file. A model with clips that
  nothing can play gets one warning naming the clips.
- A model with several skins over the same joints is drawn with each mesh's own skin (today `build_palette` uses skin 0
  for all).

Acceptance: `fa_test_scene` / render tests with a small fixture of each layout: rigid parts under bones, animated mesh
nodes and two skins; a frame of the clip differs from the bind pose and matches the reference. Clockwork Courier
drops `tools/skinify.py` and imports the original models.

### M26.5 Model import and asset tooling (S-M) — CC/FB-0008, CC/FB-0045, CC/FB-0004, CC/FB-0013

Done (branch `m26/model-import`): `.glb`/`.gltf` import copies its uri files and warns on a name clash; validate
checks them; `assets.json` edits keep the file's order; loudness warnings use the normalize gain; `assets.synth_sound`.

- `assets.import` of a `.gltf` or `.glb` copies the files its `uri`s point at (textures, `.bin`) next to it, warns when
  the destination already has a different file with the same name, and `factoria validate` checks that every texture a
  model references exists.
- `assets.set_provenance` changes one entry and keeps the order of the rest of `assets.json` (asset_manifest.cpp sorts
  the whole file today).
- `factoria validate`'s loudness warnings use the gain that `defaults.audio.normalize` will apply (peak and LUFS after
  the gain), so a project that set it has no warning left.
- An offline sound maker, `assets.synth_sound {path, preset, seed}` (barks, growls and the usual game effects, a
  deterministic WAV, no provider and no key), with its provenance; ASSETS.md points at it next to the CC0 kits.

Acceptance: tooling tests: importing a `.gltf` with an external texture copies both and validate passes; one that
collides warns; `set_provenance` on a hand-ordered `assets.json` changes one entry; a normalized quiet sound gives no
warning; `synth_sound` gives the same bytes for the same seed.

### M26.6 Text that fits (M-L) — CC/FB-0042, CC/FB-0041

- `Text.autoShrink` with `minFontSize` (and the same on `Button` and `TouchButton`): the text shrinks to fit its box
  before it is cut, in every language and at every `ui.textScale`.
- `maxTextScale` on `Text` and `UiControl`: a heading or a round button label stops growing at that scale.
- The labels of `Toggle` and `Slider` wrap or shrink: `maxWidth` on both, `labelAbove` on `Slider`.
- The effective size goes through every place that measures or draws text (layout, `autoSize`, `ui.measureText`, the
  2D and 3D renderers), and `ui.overflowed(id)` tells a script or a test that a text still does not fit.

Acceptance: `fa_test_ui` cases for a German label in a fixed button at 200 % text (shrinks, stays inside, never under
`minFontSize`), a heading capped at 1.3, a long Toggle label that wraps; the M10 menus fixture's golden images at 200 %
show no overlap.

Done (branch `m26/text-fits`): `autoShrink`/`minFontSize`/`maxTextScale`, Toggle/Slider `maxWidth`, `labelAbove`,
`ui.overflowed`, one shared fit path (text_fit.h); Clockwork Courier uses them.

### M26.7 Scene and asset preload with progress (M) — CC/FB-0012

Done (branch `m26/scene-preload`): `scene.preload` / `assets.preload` read ahead, 4 files per test frame, CC loading.js.

M19's `scene.loadAsync`, which a game now needs. `scene.preload(path)` and `assets.preload([paths])` return a handle
with `progress` (0..1), `done` and a Promise; they load within a time budget per frame (a worker thread later, L), so a
loading screen animates while a scene loads, and `scene.load` of a preloaded scene is immediate. MENUS.md gets a
loading-screen recipe.

Acceptance: a script test preloads a scene with several models and sees `progress` grow over more than one frame, then
loads it with no new file read; a loading-screen fixture keeps drawing frames while it loads.

### M26.8 Store fake and catalog in scripts (S) — CC/FB-0024, CC/FB-0025, CC/FB-0029

Done (branch `m26/store-fake`): `platform.revoke` and `game.platform.revoke(id)` (a refund and its `revoked` purchase
event); `purchases.finish` of an unknown transaction rejects `unknownId`; leaderboard `nameKey`; the catalog is
documented; Clockwork Courier uses them.

- The fake store can take a purchase back: `platform.revoke` and `game.platform.revoke(id)` in tests (a refund), with
  the `purchase` event a real backend would send.
- `purchases.finish()` of an unknown transaction rejects its Promise with `unknownId` instead of throwing
  (platform.cpp); tests and PLATFORM.md follow.
- `game.project.platform` (the catalog, already readable) is documented in PLATFORM.md; leaderboards get a `nameKey`
  for their localized name, like achievements.

Acceptance: platform tests for a refund, the rejection and a leaderboard name in two languages.

### M26.9 Ads and leaderboard periods: the API and the fake (M) — CC/FB-0028, CC/FB-0030

Done (branch `m26/ads-periods`): `platform.ads`, `platform.release`, leaderboard `period`, fake ads; Courier uses them.

After M26.3 (the date of a period) and M26.8 (same catalog code).
- A `platform.ads` service like `purchases`: the catalog's `platform.ads.placements`, `ads.available(placement)`,
  `ads.showRewarded(placement)` resolving `{rewarded}`, `ads.consent()` (what the GDPR and tracking sheets answered) and
  `platform.release` (false in development runs and tests). The fake backend shows a scripted test ad, so games and
  tests share one path.
- Leaderboards with `period: "allTime" | "daily" | "weekly"` in the catalog and the API; the fake keys scores by period
  using `game.today()`.
- The real backends (Google UMP and AdMob, Apple ATT, store leaderboard periods) are M12's next packages.

Acceptance: platform tests for a rewarded ad that pays, one the player closes early, consent refused, and a daily
leaderboard that is empty again the next day under `game.setDate`.

### M26.10 Navmesh and paths for 3D (L) — CC/FB-0009

Done (branch `m26/navmesh`): `NavMesh3D` baked from the static colliders into a deterministic 2.5D grid
(`fa/physics/nav.h`), `nav.bake`, `nav.find_path`, `nav.info` and `nav.findPath` in scripts, `Collider3D.navObstacle`
for moving obstacles, editor "Show navmesh"; docs/NAVIGATION.md. Clockwork Courier keeps its own scripts/nav.js for now.

M19's navmesh, which a game now needs. A `NavMesh3D` component baked from static colliders (`nav.bake`, with the
agent's radius, height, step and slope), `nav.find_path` and `nav.findPath(from, to, {radius})` in scripts next to
`physics.raycast3d`, a debug draw in the editor, and moving obstacles through a dirty flag. M19's grid A* on a Tilemap
and the behaviour-tree helper can share the search later.

Acceptance: `fa_test_physics` (or a new module's) cases on a fixture with walls, a ramp and a step too high; a script
test where a guard reaches the player around a wall; the bake is the same on every run.

### M26.11 Test API gaps (M) — CC/FB-0005, CC/FB-0006, CC/FB-0018, CC/FB-0026, CC/FB-0038, CC/FB-0044

Done (branch `m26/test-api`): `game.mouseDown/mouseUp/wheel`, `game.resetState`, `game.quitRequested` (a quit in a test
only sets it; Back that nobody consumes too), `game.setSystemLanguages`, `checkHooks` counts arguments (`start(seconds)`
is a method, `update(dt)` still warns), SCRIPTING.md on `scene.load` vs `game.load`; tests in
`engine/script/tests/test_test_api.cpp`.

Not at the same time as M26.3 (the same `factoria:test` object in factoria.js).
- `game.mouseDown(button)`, `game.mouseUp(button)` and `game.wheel(dy)` (the natives exist), so drag and zoom can be
  tested.
- `checkHooks` in the validator counts arguments: `start(seconds)` is a method, `start()` still warns.
- SCRIPTING.md, "Tests", says `scene.load` from a test takes effect next frame and that `game.load` is immediate.
- `game.resetState({storage, platform})` resets the save data and the fake store between tests of one file (each file
  already starts clean).
- In tests a quit request sets `game.quitRequested` instead of stopping the run; it is reset for each test.
- `game.setSystemLanguages([...])` decides what `i18n` picks at start, reset for each test.

Acceptance: a JS test for each item, in `engine/script/tests`.

### M26.12 Localized text with parameters (M) — CC/FB-0021 (and its duplicate CC/FB-0027), CC/FB-0040

Done (branch `m26/i18n-args`): `keyArgs`, `TouchButton.key`, validate checks args; Courier uses them.

- `keyArgs` on `Text`, `Button` (`UiControl`) and `TouchButton`: the values of a key's `{placeholders}`, passed to
  `i18n.t` when the text is localized (localize.cpp), so a script sets `keyArgs` once instead of rewriting `text` every
  frame, and a language switch keeps them.
- `TouchButton` gets `key` like the other widgets.
- `factoria validate` checks a key's placeholders against the entity's `keyArgs` instead of warning about every key
  with placeholders.

Acceptance: `fa_test_scene` cases: a score label with `keyArgs` in two languages, a switch at run time, a TouchButton
with a key; validate warns only for a placeholder with no arg.

### M26.13 Locale-aware numbers (M) — CC/FB-0039

After M26.12 (same localize code). `{v:number:1}` and `{t:duration}` in keys, `i18n.number(v, {decimals})` and
`i18n.duration(seconds)` in scripts: decimal and group separators and digit forms per language from a small table in
the engine (no ICU). LOCALIZATION.md lists the languages it knows.

Acceptance: script tests for 1234.5 in English, Spanish, German, French and Arabic, and a time of 83.4 s.

### M26.14 Joints: overlaps, rest and bridges (L) — CC/FB-0015 (and its duplicate CC/FB-0053), CC/FB-0054, CC/FB-0017, CC/FB-0014

After M26.2 (the same physics files).
- A dynamic body that starts inside a static collider is reported once on the first step (and by `factoria validate`
  for scenes), and `Joint3D.stalled` (read only) tells a script that a driven joint cannot move.
- Islands are built across joints: a chain sleeps when it is at rest, a CCD event is solved per island instead of
  holding every body of the world, and two unrelated chains no longer move each other (physics3d.cpp).
- `Joint3D.damping` and more iterations for chains, so a plank bridge settles without heavy damping or wide planks;
  AI_GUIDE.md has a rope bridge recipe (and `physics.make_chain3d` if the recipe stays long).
- `connected: ""` means the world on `Joint3D` and `Joint2D` everywhere: in scene files, `factoria validate`, scripts
  and `scene.set_component`, as the docs say.

Acceptance: `fa_test_physics` cases: a body started in a wall is reported once; a hinge driven into a wall reads
`stalled`; a 12-plank bridge sleeps within 5 s; two bridges side by side give the same poses as each one alone; a joint
with `connected: ""` loads, validates and runs.

### M26.15 Graphics quality and render stats (M) — CC/FB-0036, CC/FB-0050

- `window.renderScale` (0.5..1, wired to the renderer's render scale), `window.supports(feature)` and `game.device`
  (`formFactor`, `gpuBackend`, a `tier` from the GPU and memory) for quality presets. The frame cap still throws where
  a phone cannot honour it; SCRIPTING.md says to read `window.supports("frameCap")` first.
- `game.renderStats()` in tests draws a frame when none has been drawn yet (today `game.state().renderStats` is zero
  headless) and adds `shadowCasters`; `perf.measure` records triangles, lights and texture memory, and `perf.check`
  takes budgets for them (`maxTriangles`...).

Acceptance: script tests for the render scale (the drawn size changes), the device fields headless, and render stats
of a fixture scene; a `perf.check` with a triangle budget fails when the scene goes over it.

Done (branch `m26/render-quality`): `window.renderScale`, `window.supports`, `game.device` (fixed headless,
`setDevice` in tests), `game.renderStats()` drawing on demand with `shadowCasters`/`textureMB`, `game.render_stats`;
`perf.measure` records triangles/lights/textureMB and `perf.check` takes `budgets`; Clockwork Courier uses them.

### M26.16 Per-material colours (M) — CC/FB-0031

After M26.4 and M26.15 (the same model and renderer code). `MeshRenderer.materialColors` is an object keyed by glTF
material name, `{"Body": [0.2, 0.8, 0.7, 1]}`, applied per sub-mesh (the sub-mesh keeps its material name) and part of
the batch key; `factoria validate` checks the names against the model with a "did you mean".

Acceptance: a render test where one material of a two-material model changes colour and the other does not; validate
suggests the right name for a typo.

### M26.17 Text entry on every device (M) — CC/FB-0020, CC/FB-0052

Done (branch `m26/text-entry`): the UI raises the phone's keyboard on focus, the MENUS.md kit has an on-screen keyboard
for pad players, the web player has a hidden `<input>` and the web smoke types into a field (CI runs it).

- A focused `TextField` raises the phone's keyboard and hides it on blur. MOBILE.md says it does; today only
  `input.showKeyboard` does it (found while verifying CC/FB-0020).
- An on-screen keyboard for gamepad players: a prefab the `TextField` opens when focus came from a pad (letters,
  digits, space, delete, done; the d-pad walks it; the layout follows the language's script), in MENUS.md. The Steam
  Deck's own keyboard is M12's, with Steamworks.
- Web: TEXT.md and EXPORTING.md ("Web") say the web player takes typed text from `keypress` (what a browser pane's
  synthetic key events may not send); the web autotest types into a field; a hidden `<input>` raises the keyboard on
  mobile browsers.

Acceptance: an input test where focusing a field shows the keyboard; a UI test that types a name with the pad alone;
the web autotest fills a field.

### M26.18 Slider and ScrollList (S-M) — CC/FB-0037, CC/FB-0046

Done (branch `m26/slider-scroll`): `ui.set_slider` / `game.setSlider`, `Slider.format` and `formatKey`, `ScrollList.shrink`;
Courier's slider formats and its comfort test use them (its lists keep `fill`).

After M26.6 (the same widgets).
- `game.setSlider(id, value)` in tests sends `ui.change` like a drag; a value set from a script does not (as today) and
  this is documented. `Slider.format` shows the value as `"{v}%"` or through a key.
- `ScrollList.shrink`: inside a `fit` parent a list is as tall as its content up to the space left, instead of the
  whole screen.
- Details: `format` takes `{v}`, `{v:N}` and `{percent}` (value x 100); `formatKey` is a key whose translation is the
  pattern. Several `shrink` lists share the room by water-filling; `fill` wins over `shrink`.

Acceptance: `fa_test_ui` cases for each.

### M26.19 Export and store material checks (S-M) — CC/FB-0034, CC/FB-0048, CC/FB-0049, CC/FB-0051 (ffmpeg)

- iOS: `Products.storekit` is written whenever the catalog has products, whether or not the Apple plugin is built
  (export_ios.cpp), with one localization per language of the game (storekit_config.cpp).
- Android: a CMake from the system (3.24 or newer) works through `cmake.dir`, the SDK's version is read instead of
  required to be 3.31.6, and the hint says how to get one offline.
- Desktop: the factoria binary and the player carry a build fingerprint; an export with a player from another build
  stops with a teaching error (`--allow-player-mismatch` to go on).
- `setup.install` can install ffmpeg, so `--record-video trailer.mp4` works without a manual step (the video player
  itself is M19's).

Acceptance: tooling tests for each export check and for the storekit file with two languages; `setup.install`'s
ffmpeg component is listed by `setup.status`.

### M26.20 Scene tree: sibling order and shared panels (S-M) — CC/FB-0032, CC/FB-0023

- A child can be put at a place among its siblings: `World::set_parent` with an index, `scene.set_parent {index}`,
  `entity.setParent(parent, keepWorld, index)` and `spawn({parent, index})`.
- MENUS.md shows a panel shared between scenes as a prefab; a prefab instance can override its children's fields
  (`overrides` in `expand_prefab`), so one panel serves two scenes with different texts.

Acceptance: `fa_test_scene` cases for each.

### M26.21 Physics determinism across platforms (S-M) — CC/FB-0055

- AI_GUIDE.md and SCRIPTING.md ("Tests") say what holds: the same build on the same platform gives the same result;
  another compiler or CPU may not.
- `fa_physics` and `fa_scene` build with no floating-point contraction (`-ffp-contract=off`, `/fp:precise`), so the same
  source gives the same numbers on more platforms; CI compares a replay's hash between the Linux and Windows jobs.
- `factoria:test` has a helper that runs a check under small perturbations, so a level test asserts what is robust
  instead of an exact frame count.

Acceptance: the replay hash matches across CI's Linux, Windows and macOS jobs, or the docs list where it does not.

### M26.22 Menu kit command (M) — CC/FB-0003

After M26.1 (the kit is formatted on write). The menus recipe moves to `templates/menus/` (scenes, prefabs, scripts and
locale keys), MENUS.md shows it from there, and `project.add_menu_kit {parts, overwrite}` copies the parts asked for
into a game and merges their keys into its locale files.

Acceptance: a tooling test adds the kit to a new project, which then validates and passes the kit's own test; adding it
twice changes nothing.

### M26.23 UI layout check (M) — CC/FB-0043

After M26.6. `ui.check_layout {scenes, languages, textScales, pseudo}` loads each screen in each language and text scale
(and a pseudo-localized one that lengthens every string), and lists every text that overflows or overlaps, with the
entity and the key.

Acceptance: a tooling test on the menus fixture finds a planted overflow at 200 % in German and nothing else.

## Out of scope: Roblox

Roblox is not an export target. Roblox games run Luau inside Roblox Studio with Roblox's own services (DataStore,
MarketplaceService); exporting to it would take a JavaScript-to-Luau transpiler and a converter from scenes to `.rbxlx`,
which is a different product. Not planned.
