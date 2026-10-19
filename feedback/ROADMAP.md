# Engine feedback report

Status: the four jam-sized example games reported 73 entries, all verified fixed-in-engine. Lantern Keep, the M21
reference game, reported 45 (none a blocker or major: 30 minor, 15 nice-to-have); they are open, ranked below, and wait for
triage. M1-M11 and M13-M15 are done; M12 (platform services) has its API and the Steam, Apple and Google Play backends; M16 (mobile store-ready), M17 (web export) and M18 (animation and production 3D) are done; M21 has its reference game; M19, M20, M22 and M23 are not started (M10-M23 come from an external evaluation of v0.1.4, re-triaged 2026-10-16: what it still takes to ship a game to the stores). What only certificates, real devices or a device farm can close is under M8 and M9, "Left open". What finished milestones built is in [ROADMAP_DONE.md](ROADMAP_DONE.md); this file keeps what they left open and the decisions to respect.
Regenerate the ranked list with `factoria feedback collect examples/sky-hopper examples/neon-swarm examples/gem-roller examples/block-push examples/lantern-keep --out feedback/ROADMAP.md` (then re-add the milestones section).

45 entries from 5 project(s), 45 distinct gap(s). Ranked by total occurrences x severity weight (blocker 8, major 4, minor 2, nice-to-have 1).

## 1. Buttons, toggles and sliders do not size themselves to their label at a big ui.textScale

- **Category:** ui
- **Severity:** minor (score 4)
- **Total occurrences:** 2
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0031
- **Suggestion:** An opt-in autoSize flag on Button/Toggle/Slider: at least the design size, growing to the label at the current textScale and language; optionally wrap for Button labels.
- **Workarounds seen:**
  - scripts/ui/text_fit.js fitWidgets(root) sets size = max(design size, measured label + padding) for every widget under a screen; it runs at screen start, on i18n change and after the text size changes. Options, credits and the level end panel also choose their layout from the text size (wider panel, buttons beside the text).

## 2. Multi-line Button text is left-aligned and not clipped

- **Category:** ui
- **Severity:** minor (score 4)
- **Total occurrences:** 2
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0011
- **Suggestion:** Center each line of a multi-line Button label, add maxWidth/wrap to Button like Text has, and document newline support in Button.text.
- **Workarounds seen:**
  - Shortened the second line (no 'Best' label) and made the buttons 320 px wide; the lines are left-aligned as the engine draws them.

## 3. factoria docs read prints doubled carriage returns on Windows

- **Category:** tooling
- **Severity:** minor (score 4)
- **Total occurrences:** 2
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0001
- **Suggestion:** Write the document to stdout in binary mode (or do not translate 
 to 
 twice) so only 
 or at most 
 appears.
- **Workarounds seen:**
  - Read the doc through `factoria call docs.read` (JSON) or normalise with a replace of 

 to 
 before extracting.

## 4. 2D kinematic platforms do not carry the bodies standing on them

- **Category:** physics
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0003
- **Suggestion:** Carry dynamic 2D bodies that rest on a kinematic body (as 3D does), or expose the ground body (entity.groundBody / isGrounded() returning it) so a script can add its velocity without a raycast. Add a 2D moving-platform recipe to the AI guide.
- **Workarounds seen:**
  - player.js casts a short ray under the feet, and when the hit entity has a kinematic RigidBody2D it adds that body's velocity.x to the player's own horizontal speed.

## 5. A ScrollList cannot take the height the rest of a fit column leaves

- **Category:** ui
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0041
- **Suggestion:** ScrollList.fill (take the free height of the parent column, up to the screen) and a validate/runtime warning when a Panel with fit ends up taller than the screen.
- **Workarounds seen:**
  - fitList(panel, list) in scripts/ui/text_fit.js measures every other child with ui.measureText and sets the ScrollList height; tests/helpers/screens.js checks that every panel is inside the screen and big enough for its children.

## 6. Export has no way to leave project folders out

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0016
- **Suggestion:** export.exclude: a list of project-relative globs ("store/**", "screenshots/**", "levels/**") that neither the folder export nor game.pak nor the web/mobile exports ship, checked by factoria validate; and mention the dot-folder rule next to it in docs/EXPORTING.md.
- **Workarounds seen:**
  - Moved the store screenshots into a dot-folder, .store/screenshots (dot-folders are never exported), which is an obscure trick; levels/, screenshots/ and store/ (texts, small) still ship.

## 7. Gamepad focus navigation cannot be told its neighbours (a wide widget below a tab row steals DpadRight)

- **Category:** ui
- **Severity:** nice-to-have (score 2)
- **Total occurrences:** 2
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0033
- **Suggestion:** Only accept a candidate whose centre is within 45 degrees of the pressed direction (the dominant axis), or let widgets name their neighbours; document the rule in the Focus and navigation section.
- **Workarounds seen:**
  - The test focuses tabs with ui.focus(). Not fixed in the game: the player reaches the tab with DpadLeft from the other side or the mouse.

## 8. Layouts cannot be mirrored for right-to-left languages, and align does not follow the text direction

- **Category:** ui
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0040
- **Suggestion:** Text.align and Panel.align/justify values 'start' and 'end' that follow the current language's direction, and Panel.direction 'auto' for rows; an i18n.direction ('ltr' or 'rtl') in scripts.
- **Workarounds seen:**
  - text_fit.js isRtl() and fitWidgets set align right on wrapped Texts; hud.js swaps the HUD corners. The rows of buttons, the level end panel and the level select rows are NOT mirrored in Arabic (readable, but the first item is on the left).

## 9. Menu recipe has no Spanish string table

- **Category:** docs
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0004
- **Suggestion:** Ship the recipe's Spanish table in docs/MENUS.md (or as templates/menus/locales/es.json) and add `factoria new --menus` / a project.add_menus command that writes the whole recipe, so nobody copies 11 files out of Markdown.
- **Workarounds seen:**
  - Wrote locales/es.json by hand from locales/en.json; tests/menus.test.js checks that both tables have exactly the same keys.

## 10. No Microsoft Store packaging (MSIX) or publish command

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0023
- **Suggestion:** export.windows.msix (identityName, publisher, displayName, logos derived from the icon) writing an .msix next to the folder (unsigned, or signed with a pfx from the environment), and publish.microsoft later; at least a docs section 'Microsoft Store' saying what is and is not covered.
- **Workarounds seen:**
  - None: SHIPPING.md lists the hand steps (makeappx/MSIX Packaging Tool, Partner Center, the submission form). Not tried here: no Windows SDK tools were installed.

## 11. No render scale for store screenshots

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0017
- **Suggestion:** A `--render-scale 1.5` (or --output-size 1920x1080) for factoria run --headless and game.screenshot {scale}, drawing the same design at a larger resolution like a fullscreen window does.
- **Workarounds seen:**
  - Rendered at 1280x720 and enlarged with Pillow (Lanczos, exact 1.5x for 1920x1080). The result is soft, not native; recorded in SHIPPING.md.

## 12. No way to make a game icon without an asset provider

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0014
- **Suggestion:** A command like assets.draw_icon {shape/text/colors} (or `factoria new` templates shipping a neutral icon.png that factoria.json already points to) so a game made without a provider still has a real icon, and a PNG writer in the script API (image.save) for project tools.
- **Workarounds seen:**
  - Wrote tools/make_icon.py, a deterministic Pillow script that draws the lantern and the Android foreground layer, and recorded both files with assets.set_provenance (origin original, ai false). Needs Python and Pillow on the machine.

## 13. Scripts and entity.behaviour of inactive panels

- **Category:** scripting
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0010
- **Suggestion:** Document in the menus recipe how a panel script gets set up and refreshed when shown (or add an onEnable callback that also runs for panels shown by MenuStack), and say entity.behaviour is null for a never-activated entity.
- **Workarounds seen:**
  - Screen logic that other screens call (refresh, open) is exported as plain module functions (refreshSlots, refreshSelect) that look entities up with world.find; the Behaviour class only wires clicks.

## 14. Scripts have no API for the laid-out rectangle of a widget

- **Category:** docs
- **Severity:** nice-to-have (score 2)
- **Total occurrences:** 2
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0035
- **Suggestion:** Include Text entities (kind Text, rect, text) in ui.state, or give entity.bounds() a screen-space answer.
- **Workarounds seen:**
  - tests/accessibility.test.js reads fa.call('ui.state').widgets and measures Texts with ui.measureText.

## 15. Shape2D is not shaded by Light2D

- **Category:** rendering-2d
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0006
- **Suggestion:** Add `lit` to Shape2D (same rule as Sprite.lit).
- **Workarounds seen:**
  - Spikes and enemies are Sprites with small generated PNGs, platforms are solid-colour Sprites (no texture), all with lit true in the dark world. The player, embers and checkpoints stay Shape2D on purpose (they are light sources or must stay visible).

## 16. TEXT.md says ui.measureText is an approximation in headless runs, but factoria test measures with the real fonts

- **Category:** docs
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0042
- **Suggestion:** State in TEXT.md when measureText is exact (tests, headless runs with the built-in font) and when it is not; close FB-0032 if it is.
- **Workarounds seen:**
  - tests/helpers/screens.js trusts ui.measureText; the screenshots of the same screens agree with the test.

## 17. Test game object has no paused flag

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0005
- **Suggestion:** Add `paused` to the test game object (or say in docs scripting 'Tests' that the pause state is time.scale) and make reading an unknown member of the test game object throw with a did-you-mean instead of returning undefined.
- **Workarounds seen:**
  - Tests assert `time.scale` (imported from "factoria") is 0 / 1.

## 18. Vector fields read from scripts look like arrays but cannot be indexed or iterated

- **Category:** scripting
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0039
- **Suggestion:** Make component vec fields array-like (index and iterator), or have the d.ts say they are Vec2/Vec4 objects with .x .y .z .w and no array behaviour; JSON.stringify showing an array is what misleads.
- **Workarounds seen:**
  - Read vec2 as .x .y and vec4 as .x .y .z .w (padding is left, top, right, bottom); write them as plain [a, b] arrays.

## 19. What each export needs offline is spread over several docs

- **Category:** docs
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0022
- **Suggestion:** One table in docs/EXPORTING.md: platform x what it needs x whether a source build, the download or neither can do it offline.
- **Workarounds seen:**
  - Exported windows, windows --release, android --format gradle (no tools needed) and ios (project only); recorded the exact errors of linux, macos and web in SHIPPING.md.

## 20. a menu panel whose only autoFocus widget is not interactable has no focus for the pad

- **Category:** docs
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0027
- **Suggestion:** Make the focus rule skip non-interactable autoFocus widgets and fall back to the first interactable one in reading order, or add the warning to the shop part of the menus recipe.
- **Workarounds seen:**
  - Left the buy buttons interactable without a store: a click answers with the same plain sentence as the status line.

## 21. a store promise returned from a then callback is reported as an unhandled rejection

- **Category:** scripting
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0029
- **Suggestion:** Report an unhandled rejection only after the microtask queue drains (as Node does), or document that a platform promise needs its handler in the same turn.
- **Workarounds seen:**
  - Wrap the call: `then(async () => { try { await fn(); } catch {} })`, so the store promise gets its handler at once.

## 22. factoria test takes no test file path and its error misleads

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0012
- **Suggestion:** Accept test file paths or globs after the project (or a --file option), and when the argument is an existing file say 'give the project folder; use --filter to pick tests'.
- **Workarounds seen:**
  - Ran 'factoria test . --filter <words of the test name>' per test while developing.

## 23. game.paused = false resets time.scale to 1

- **Category:** scripting
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0036
- **Suggestion:** Make game.paused remember the scale it replaced and restore it, or document the reset next to time.scale in the scripting doc and the menus recipe (any game that uses time.scale for slow motion breaks with the recipe pause menu).
- **Workarounds seen:**
  - level.js refreshAssist() sets time.scale again at level start and after the pause menu resumes; a test checks it.

## 24. game.screenSize costs about 0.3 ms per read

- **Category:** performance
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0002
- **Suggestion:** Make game.screenSize a cheap property (cache the Vec2, or return a plain object); and have the 2d-platformer template's follow_camera.js cache it too.
- **Workarounds seen:**
  - scripts/follow_camera.js reads game.screenSize once and keeps the numbers.

## 25. no way to test the none backend (no store) in a test

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0025
- **Suggestion:** game.platform.set({ backend: "none" }) that makes the fake behave as the none backend (has false, calls reject unavailable, signIn answers signed out) until reset().
- **Workarounds seen:**
  - Tests replace platform.has with () => false for the duration of a test (the scripts check has() before every call, so they take the no-store path) and restore it in a finally. The real rejections with code unavailable are not exercised.

## 26. platform catalog names and descriptions cannot be localized

- **Category:** docs
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0024
- **Suggestion:** Let a catalog entry say name as a locale key or add a nameKey/descriptionKey, and have platform.achievements.list() and platform.purchases.products() return the translated text for the current language (or document that the catalog is for stores only).
- **Workarounds seen:**
  - The in-game screens ignore the catalog texts and read achievements.<id>.name / .description and shop.product.<id> from locales/*.json; the catalog keeps the English text for the store.

## 27. publish dry run needs the store's uploader installed

- **Category:** docs
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0018
- **Suggestion:** With dryRun, report a missing tool (and missing secret/app id) as a warning and still return the plan, or document the fake-tool trick in the 'Testing without a store' section.
- **Workarounds seen:**
  - Pointed FACTORIA_STEAMCMD, FACTORIA_BUTLER, FACTORIA_BUILDPATCHTOOL and FACTORIA_GOG_PIPELINE_BUILDER at C:/Windows/System32/whoami.exe, set FACTORIA_EPIC_CLIENT_SECRET=fake and passed appId 9000000: the dry runs then showed the plans (uploads, command lines, vdf files) for the fake ids. Nothing was downloaded or sent.

## 28. scene.import_ascii copies a prefab used by the base scene instead of keeping the reference

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0015
- **Suggestion:** Keep the entity as {id, prefab, overrides} in the written scene, or say in docs/ai-guide 9.8 that the base scene is expanded at import time.
- **Workarounds seen:**
  - Edit the prefab, then re-run scene.import_ascii for all six maps and scene.format (a loop in the shell).

## 29. scene.import_ascii copies prefab contents into the level scenes, so editing a prefab means rebuilding every level

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0034
- **Suggestion:** Let the legend place prefab instances (prefab plus overrides, as scenes can) instead of copies, so the prefab file stays the single source; or say in the ascii docs that a prefab edit needs the rebuild.
- **Workarounds seen:**
  - Ran factoria call scene.import_ascii @levels/<id>.json for the six levels, then scene.format.

## 30. test runtime lacks Array.prototype.at, expect().toMatchObject and array methods on component colors

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0026
- **Suggestion:** Ship ES2022 Array.prototype.at, add toMatchObject (the docs of factoria:test list the matchers), return real arrays for color fields, and name the missing method in the TypeError.
- **Workarounds seen:**
  - calls()[calls().length - 1], one expect(...).toBe per field, Array.from(color).

## 31. ui.measureText in headless runs and tests is only an estimate (0.6 x fontSize per character)

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0032
- **Suggestion:** Load the real font for measureText also when headless (it is in the binary), or let tests ask for exact metrics.
- **Workarounds seen:**
  - Tests use the estimate (the conservative side); the HUD and the options pick layouts from the same function, so test and game agree on the rule, not on the pixels. Screenshots, which render real text, were checked by eye.

## 32. world.emit from a test reaches listeners only at the next game.step

- **Category:** docs
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0028
- **Suggestion:** Say it in the scripting and testing docs next to world.emit, or deliver world.emit synchronously when called from a test.
- **Workarounds seen:**
  - A settle() helper that does game.step(1) after emitting, then awaits the script, in every store test.

## 33. LOCALIZATION.md lists i18n.state as a script member and the Text docs say DejaVu Sans has no Arabic

- **Category:** docs
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0045
- **Suggestion:** Say 'command' in LOCALIZATION.md section 2 and add Hebrew and Arabic to the Text.font description (docs/COMPONENTS generated from the reflection doc string).
- **Workarounds seen:**
  - tests/languages.test.js reads the table with fa.call('i18n.state'); no font was added for Arabic.

## 34. Long ASCII level maps are hard to author and edit by hand

- **Category:** tooling
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0009
- **Suggestion:** Let scene.import_ascii (or a new scene.ascii_edit command) take operations on an existing map: fill/replace a rectangle, insert or delete columns, place a glyph at (column, height above the ground), so an AI changes a map without rewriting every row; and report the column and row of every glyph in the result so it can be located again.
- **Workarounds seen:**
  - Drew the maps with a throwaway script outside the project (a cursor that appends 'motifs' such as spikes, a pit with a checkpoint, a staircase, then writes the rows); the committed source of truth is still the ASCII in levels/<id>.json.

## 35. No colour-blind or greyscale preview or filter

- **Category:** rendering-2d
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0037
- **Suggestion:** Camera.colorFilter enum (none, greyscale, protanopia, deuteranopia, tritanopia, high contrast) as a post-process that game.screenshot also applies, so players and AIs can use it.
- **Workarounds seen:**
  - Hazards and pickups differ by shape and outline (spikes = triangles, enemies = rounded boxes with eyes, ember = diamond, checkpoint = ring, exit = star in a lamp). The greyscale check was made outside the engine with Python Pillow on a screenshot (screenshots/a11y-hazards-colour-and-grey.png). No colour-blind filter option was built.

## 36. No guidance on testing a damaged save file

- **Category:** docs
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0013
- **Suggestion:** Document the corrupt storage.json behaviour (and keep a .bak) in the scripting docs, and add a save-file recipe with versioning, migration and a damaged-save screen.
- **Workarounds seen:**
  - A slot is stored as a string of JSON text and parsed with try/catch in scripts/saves.js; tests store broken text with storage.set.

## 37. No hook when an entity becomes active

- **Category:** scripting
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0008
- **Suggestion:** Add onEnable()/onDisable() hooks (called when the entity becomes active or inactive, also for the first time), and state in docs scripting when onStart runs for inactive-then-activated entities.
- **Workarounds seen:**
  - level_end.js has an open(result, info) method that fills the texts at once; level.js calls it instead of relying on onStart.

## 38. No way to read the operating system accessibility settings or to speak UI text

- **Category:** platform
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0038
- **Suggestion:** Read-only platform.accessibility { textScale, reduceMotion, highContrast, screenReader }, plus ui.speak(text) or a focus-change event a screen reader plugin can use.
- **Workarounds seen:**
  - Lantern Keep starts with its own saved options only (text 100%, shake on) and has no spoken menus.

## 39. No way to smoke-test an exported game for a few frames

- **Category:** tooling
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0019
- **Suggestion:** factoria_player --frames N (render N frames, then exit 0; non-zero when a script error or a crash happened), so `factoria export` can offer a --smoke-test.
- **Workarounds seen:**
  - Start-Process, sleep, check the process is alive and responding, read %APPDATA%/<id>/log.txt, Stop-Process.

## 40. The project .gitignore does not ignore build/translations

- **Category:** tooling
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0044
- **Suggestion:** Add build/ to the generated project .gitignore, or write exports under .factoria/.
- **Workarounds seen:**
  - Added build/ to the project's .gitignore by hand.

## 41. Touch control rectangles move with the safe area and tests have no helper to press a widget

- **Category:** docs
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0021
- **Suggestion:** game.touchWidget(id, frames?) for tests, and one sentence in MOBILE.md pointing at ui.state rects and the one-step rule.
- **Workarounds seen:**
  - Tests read the rects from fa.call("ui.state").widgets and tap their centre; the screenshot script steps two frames after set_safe_area.

## 42. factoria validate does not warn about textures that cannot be GPU-compressed

- **Category:** tooling
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0020
- **Suggestion:** Run the same check in factoria validate when platforms contains android or ios.
- **Workarounds seen:**
  - Gave assets/enemy.png an atlas group in assets.json ({"import":{"atlas":"characters"}}): atlas pages are always sized for it, and the warning is gone.

## 43. i18n.import writes a flat table for a language that has no file yet

- **Category:** tooling
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0043
- **Suggestion:** When the file does not exist, copy the structure of the default language's table (nested when it is nested).
- **Workarounds seen:**
  - After the import the file was rewritten nested, with the same strings (checked equal), by a short script.

## 44. no onEnable/onDisable for a panel shown by active, and behaviour is null before its first activation

- **Category:** scripting
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0030
- **Suggestion:** Add onEnable() / onDisable() to Behaviour, called when the entity (or an ancestor) becomes active or inactive, including the first time; or let MenuStack send a panel_shown event that hidden panels receive.
- **Workarounds seen:**
  - The panel script has an opened() method; main_menu.js calls world.find(id).behaviour?.opened() after MenuStack.show, and onStart calls opened() itself for the first visit.

## 45. scene.import_ascii warns about unused legend entries

- **Category:** scene
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0007
- **Suggestion:** Add `legendFrom: "levels/legend.json"` (a shared legend merged under the map's own) and do not warn about unused entries that come from it, or add `warnUnused: false`.
- **Workarounds seen:**
  - The legend written into each levels/<id>.json holds only the glyphs that map uses.

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

Sizes: S = under a day for an AI agent, M = 1-3 days, L = a week or more. Ids are `<game>/FB-n`
(sky-hopper = SH, neon-swarm = NS, gem-roller = GR, block-push = BP).

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
- Windows has no window read-back for the editor (D3D11), so the editor autotests are not registered there.
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
- Save slots with their menu are M19; a GDPR/COPPA consent screen on these menus is M22.

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

Left open (the next M12 packages): Epic Online Services and GOG Galaxy, ads with consent, analytics and remote config, push
notifications and deep links, the Android stores outside Play. `PlatformServices` keeps no receipts or entitlement cache: a
backend answers `restore()` itself. Overlay and presence are one call each; there is no `achievements.onUnlocked`
event, rich presence has no localization, and `platform.stats.add` is a get then a set (not atomic across devices).
Cloud saves take JSON values only (no binary blobs, no conflict resolution beyond "last write wins" in the fake).

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
- Pathfinding: grid A* on a Tilemap, a navmesh for 3D, a behaviour-tree helper module.
- Video: a video player component for logos and cut-scenes (e.g. pl_mpeg, MIT).
- `scene.loadAsync` with progress, for loading screens and larger worlds.
- Split screen: a viewport rectangle on Camera (four gamepads already work).
- Audio: effects on the buses (low-pass, reverb), ducking and snapshots.

Acceptance criteria: each item ships with its doctest or JS test and its docs, like any command or component.

## M20. Editor and tooling (L, medium-high)

Closes H-01, H-02, H-03, H-05, H-09 and the editor part of H-06.

- Hand editing: entity tree, an inspector built from reflection (every field already has a doc string and a range), an
  asset browser and transform gizmos; every edit goes through the commands the AI uses, so undo comes with them.
- A script debugger: breakpoints and stepping in QuickJS behind a Debug Adapter Protocol server, for VS Code.
- A profiler: CPU time per system and per behaviour class, GPU timings and memory, in `play.report` and an editor panel.
- The inspector also edits `MeshRenderer.material` / `materialParams` (typed by the material's params) and shows a
  material's compile error under the field (custom shaders P5 left it here: the editor has no inspector yet).
- Later: tile painting and object placement in the viewport, an animation timeline, particle and material editors.

Acceptance criteria:
- The editor autotest edits a field in the inspector and the scene file changes.
- An integration test drives the DAP server over stdio and stops at a breakpoint in a template behaviour.
- The profiler report lists each behaviour class with its milliseconds per frame.

## M21. Docs and material for shipping (M, high)

Closes D-01..D-05, D-07 and the store-page notes of the report.

- Docs marked by version ("since 0.1.x"); `factoria docs` already serves the docs of its own binary.
- A publishing guide per store with a checklist (Steam, Epic, GOG, Microsoft Store, Google Play, App Store, itch.io):
  what the engine does and what the developer still does by hand.
- A "finish your game" guide (menus, options, saves, localization, accessibility, credits) with M10-M14.
- A complete reference game built on M10-M14 and the fake platform backend, with its own ENGINE_FEEDBACK.json, so the
  feedback loop sees what jam-sized examples never reach.
- Tutorials for people and a browsable API reference generated from `factoria api --md`.
- An AI cost guide (tokens and money for a typical game, from `--max-cost` and the editor's usage records).
- Store page material: screenshots and capsule art at each store's sizes, gameplay video recorded from a replay,
  store metadata as text files per language.

Acceptance criteria: every guide is embedded in the binary and listed by `factoria docs`; a replay can be written to a
video file.

Done (the `m21/reference-game` PR, 2026-10-19): the reference game, first because the guides are better written with it
in hand. **Lantern Keep** (`examples/lantern-keep`, its README) is a 2D platformer, six short levels in two worlds, built
the way a game maker's AI builds a game (the generated AGENTS.md, `factoria docs`, the public commands, no engine change)
in six worker packages: core game and the menu kit (P1), three save slots, level select, a versioned save format and
cloud saves (P2), achievements, stats, leaderboards and a cosmetics shop on the fake store (P3), accessibility: text size,
assist mode, reduced effects, hazards readable without colour (P4), shipping: export and publish settings, icon, touch
gamepad, store texts and `SHIPPING.md` (P5), German and Arabic with every screen checked in four languages at 100 % and
200 % text (P6). 120 tests; ctest runs it as `example_lantern-keep_*`.

What it found: 45 open feedback entries (ranked at the top of this file), none a blocker or major, so M10-M18 hold up for
a complete small game. They cluster in UI layout at large text and right to left (widgets that do not fit their label, no
mirrored rows, focus navigation), tests (no `none` backend, no widget press helper, test runtime gaps), `scene.import_ascii`
copying prefabs into levels, `game.paused` resetting `time.scale`, rendering at store sizes, and exports that need
downloads or tools this machine lacks (web, Linux, macOS players; Android NDK; MSIX).

Left in M21: triage those entries into work packages; then the publishing guides per store from `SHIPPING.md`, the
"finish your game" guide from the game, versioned docs, tutorials and the API reference, the AI cost guide, store page
material (capsules at each store's sizes, video from a replay).

## M22. Production quality and legal (M, high)

Closes Q-04, Q-05, the rest of Q-06 and U-05 (except text scaling, in M14).

- Frame time and memory of every example on every CI runner, recorded and failing on regressions.
- Game updates: a content version in `factoria.json` and save migration (with M19's save versions).
- Templates and guidance: EULA, privacy policy, a GDPR/COPPA consent screen (on M10), age ratings (IARC, PEGI, ESRB).
- Accessibility: a subtitles component, colour-blind filters (post-processing), screen-reader hooks where the platform
  has them.

Acceptance criteria: a CI job fails when an example's frame time or memory regresses past its budget; the consent screen
and subtitles are in the M10 menu recipe and its fixture, with tests.

## M23. Closed stores and consoles (L each, later)

Closes E-08 and S-09, plus the Mac App Store and Microsoft Store rows of the report. Needs M11 and M12.

- Mac App Store: App Sandbox entitlements, Apple Distribution signing and a provisioning profile, a `.pkg` from
  `productbuild`, upload through the App Store Connect API (today only the Developer ID flow outside the store exists).
- Microsoft Store and PC Game Pass: MSIX packaging of the game (the engine's own installer is not one), Partner Center
  upload, the Microsoft GDK for Xbox services.
- Consoles (Switch, PlayStation, Xbox): their SDKs are under NDA and cannot live in this MIT repository. What this
  repository can do is the seam: a platform layer and render-backend interface (D3D12/GDKX, NVN, AGC) that a private M11
  plugin implements, and certification checklists (TRC, Lotcheck, XR) once a licensed developer contributes them.

Acceptance criteria: a sandboxed macOS export passes `codesign --verify --strict` with the App Sandbox entitlement and
runs; an MSIX of an exported game installs with `Add-AppxPackage`.

## Out of scope: Roblox

Roblox is not an export target. Roblox games run Luau inside Roblox Studio with Roblox's own services (DataStore,
MarketplaceService); exporting to it would take a JavaScript-to-Luau transpiler and a converter from scenes to `.rbxlx`,
which is a different product. Not planned.
