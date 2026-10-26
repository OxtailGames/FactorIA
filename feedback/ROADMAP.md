# Engine feedback report

Status: the four jam-sized example games reported 73 entries, all verified fixed-in-engine. Lantern Keep, the M21
reference game, reported 45 (none a blocker or major), triaged 2026-10-19: one was already fixed, two were duplicates,
and the 42 open ones became work packages, most of them M24, the rest in M20-M23. M24 fixed 37 of its entries
(M24.1-M24.16, 2026-10-20), two of them found on the way, M21 three, M22 two, M20 one and M23 the last one (MSIX,
2026-10-22): no entry is open. M1-M11 and M13-M15 are done; M12 (platform services) has its API, the Steam, Apple and
Google Play backends, AdMob ads with consent, leaderboard periods on the stores and the Steam Deck's keyboard (M27); M16
(mobile store-ready), M17 (web export), M18 (animation and production 3D), M20 (editor and tooling, 2026-10-22), M21
(docs and material for shipping), M22 (production quality and legal, 2026-10-21), M24, M25, M26, M27, M28 and M29 are
done; M23 has the Mac App Store and the Microsoft Store (MSIX) done, its consoles part is not started; M19 has the video
player, the navmesh's off-mesh links and walkable bodies (M27), tile pathfinding, behaviour trees, bus effects,
`http.fetch` and split screen (M29), the rest is not started (M10-M23 come from an external evaluation of v0.1.4,
re-triaged 2026-10-16: what it still takes to ship a game to the stores). M25, the second reference game (Clockwork
Courier: 3D, mobile first, 2026-10-22), reported 55 entries (FB-0053-FB-0055 came from the CI fix of its rope bridges),
triaged 2026-10-22: one was fixed on the way (CC/FB-0033), two were already fixed before the report (CC/FB-0007,
CC/FB-0022; their docs are added), two are duplicates, and 50 were open (11 major, 35 minor, 4 nice-to-have, no
blocker). M26's 23 packages fixed 49 of them (2026-10-24) and the game dropped their workarounds; M27 (2026-10-25) fixed
the last one, CC/FB-0051 (playing a video), the parts of three left to M12 (the real ads, the stores' leaderboard
periods, the Steam Deck's keyboard) and CC/FB-0056 (the navmesh over bridges and moving platforms), found by M26's
close-out: no entry is open. What is left of M12 and M19 is ranked in their sections and waits for a game that asks for
it. M28, the third reference game (Burrow Brigade: 2D, couch co-op, desktop and Steam first, 2026-10-25), reported 38
entries (14 major, 22 minor, 2 nice-to-have, no blocker), triaged 2026-10-25: one is a duplicate, two need docs only,
and the open ones became the 21 packages of M29 (built 2026-10-26), which also took most of what was left of M19 (tile
pathfinding and behaviour trees, audio effects, networking, split screen) and M12's analytics and remote config. M29
fixed the entries and the game dropped the workarounds that no longer had a reason; the few it keeps on purpose are
under M29, "Left open".
What only certificates, real devices or a device farm can close is under M8 and M9, "Left open". What finished
milestones built is in [ROADMAP_DONE.md](ROADMAP_DONE.md); this file keeps what they left open and the decisions to
respect.
Regenerate the ranked list with `factoria feedback collect examples/sky-hopper examples/neon-swarm examples/gem-roller examples/block-push examples/lantern-keep examples/clockwork-courier examples/burrow-brigade --out feedback/ROADMAP.md` (it rewrites the whole file: then put this status and the milestones section back).

38 entries from 7 project(s), 38 distinct gap(s). Ranked by total occurrences x severity weight (blocker 8, major 4, minor 2, nice-to-have 1).

## 1. Light2D has no occlusion, so unexplored mine stays visible

- **Category:** rendering-2d
- **Severity:** major (score 8)
- **Total occurrences:** 2
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0001
- **Suggestion:** Let a Light2D (or a Tilemap) opt into shadows from the solid tiles (a 2D shadow cast from Tilemap.solidTiles), or give Tilemap a per-tile 'explored' mask / fog-of-war layer that scripts can set.
- **Workarounds seen:**
  - A small lamp radius (96 world units, 20 when nearly dry), falloff 1.5 and SceneSettings.ambientLight 0.07, so the walls beyond a few tiles fall to near black. Walls next to the lamp still light up on the far side; a hand-made fog layer was not attempted in P1. P2: the fog of war grew on it: scripts/game/fog.js tracks seen tiles per miner and paints them on a second Tilemap.

## 2. Scripts cannot read or write the system clipboard

- **Category:** scripting
- **Severity:** major (score 8)
- **Total occurrences:** 2
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0016
- **Suggestion:** clipboard.read()/clipboard.write(text) in the factoria module (async on web), and Ctrl+V / Cmd+V in a focused TextField
- **Workarounds seen:**
  - scripts/game/clipboard.js keeps a session buffer behind copy()/paste() and a useSystem({write,read}) hook; the camp and results say honestly when the code only stayed in the game; the title has a Paste button that reads the buffer; scripts/game/text_entry.js (P5) cleans a typed code to an alphabet without 0/O/1/I, so a code read aloud or from a screen is typed back without mistakes

## 3. Per-gamepad input cannot use actions, so co-op pads are not rebindable

- **Category:** input
- **Severity:** minor (score 6)
- **Total occurrences:** 3
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0006
- **Suggestion:** Per-player action sets: input.gamepad(i).down('dig') resolving the project's binding for that action, or input.player(i).axis(...) with a rebind per player.
- **Workarounds seen:**
  - scripts/game/miner_input.js has three device kinds: 'any' (the project's actions: keyboard and every pad, one player), 'keys' (a fixed key block) and 'pad' (input.gamepad(i) with hard-coded left stick, d-pad and A/X). P2 added the torch button (B or Y on a pad, T on the keyboard) to the same three device kinds.

## 4. A daily leaderboard cannot be targeted by date

- **Category:** platform
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0021
- **Suggestion:** leaderboards.submit(id, score, {day:'YYYY-MM-DD'}) or game.today() with a utc option
- **Workarounds seen:**
  - scripts/game/boards.js posts to the daily board only when run.dailyKey (the local date the try began on, scripts/game/daily.js) is within one day of game.today().iso and records lastPost.daily.skipped otherwise

## 5. A declared Steam plugin without Valve's library logs an ERROR on every run and blocks the other platforms' exports

- **Category:** platform
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0031
- **Suggestion:** Let a plugin be optional per platform (skip with an INFO when the library is missing) or keep the backend declaration apart from the build of the library
- **Workarounds seen:**
  - plugins/steam is not committed (.gitignore); SHIPPING.md says to run platform.add_backend with sdk on each build machine before exporting. Without it the game runs with platform services off

## 6. Changing one tile rewrites the whole Tilemap tiles array

- **Category:** performance
- **Severity:** minor (score 4)
- **Total occurrences:** 2
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0003
- **Suggestion:** Expose a tile API on the Tilemap view: tilemap.setTile(tx, ty, index) / getTile, with a dirty-rect rebuild.
- **Workarounds seen:**
  - The shift keeps its own array, marks it dirty on every MineMap change and writes it once per frame in onLateUpdate, so several tiles dug in one frame cost one write. P2: the fog Tilemap and the flood and magma spreading rewrite tiles too, so scripts/game/fog.js and hazards.js batch their changes and write once per frame.

## 7. Light2D is capped at 16 per frame

- **Category:** rendering-2d
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0008
- **Suggestion:** Pick the 16 lights that matter on the engine side (nearest the camera, brightest) and say so in the Light2D docs; or raise the cap with a tiled/clustered 2D lighting pass.
- **Workarounds seen:**
  - scripts/game/lights.js keeps a pool of 16 minus one per miner and gives it to the sources nearest the miners, switching the others off; tests count the active Light2D entities.

## 8. No 2D or tile pathfinding

- **Category:** scripting
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0010
- **Suggestion:** A nav module: nav.findPath(tilemap, from, to, opts) with a passable callback and an invalidation counter fed by Tilemap edits.
- **Workarounds seen:**
  - scripts/game/pathfinding.js: A* over the mine grid (with dig cost, danger tiles, a path follower and a nav.version counter that tells followers when digging changed the map); tested in tests/pathfinding.test.js.

## 9. No HTTP, news, remote-config or analytics API

- **Category:** networking
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0020
- **Suggestion:** A promise-based http module with timeouts and a test fake (game.http), plus a consent-aware analytics.track
- **Workarounds seen:**
  - scripts/game/online.js is a transport seam (offline by default, a fake in tests); news, balance and analytics go through it, and every feature works offline. A real transport has to be plugged in when the engine offers one

## 10. No bus effects, ducking or snapshots

- **Category:** audio
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0026
- **Suggestion:** audio.bus(name).lowpass / reverb / duck({by, depth, seconds}) and audio.snapshot(name, {fadeSeconds}) over a table the game defines
- **Workarounds seen:**
  - scripts/game/mix.js owns the four bus volumes (user volume x snapshot factor x duck) and eases them; muffling is just quieter and the cavern echo is a delayed, quieter replay of the clip in scripts/game/sound.js

## 11. No gamepad connect/disconnect events and no stable pad identity

- **Category:** input
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0014
- **Suggestion:** input.on('gamepadConnected'|'gamepadDisconnected', {index, id}) and a stable pad id string (vendor/product/serial) on input.gamepad(i).
- **Workarounds seen:**
  - pad_watch.js polls connected every frame, pauses with a prompt, resumes on reconnect and lets a free pad (A) or the keyboard (Enter) take the miner over; join.js polls the four slots.

## 12. No layered or synced music, and a playing voice's volume cannot change

- **Category:** audio
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0025
- **Suggestion:** audio.musicLayers({name: path}) with setLayer(name, volume, fadeSeconds), all layers sample-synced; or a volume that audio.setVoiceVolume(handle, v, fade) can change
- **Workarounds seen:**
  - scripts/game/music.js plays one-bar loops of each layer on the bar lines of a real-time clock and starts or stops them as a chase rises or falls; the layers never fade, they come and go on the bar

## 13. No split screen: one camera, no viewports

- **Category:** rendering-2d
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0013
- **Suggestion:** Camera.viewport [x,y,w,h] normalised, several primary cameras per frame, each with its own Light2D culling and HUD space.
- **Workarounds seen:**
  - scripts/game/camera_views.js computes the split plan (clusters, viewports, zoom, hysteresis) and follow_camera.js zooms one shared camera out up to a limit; a leash (limitMove) stops miners going farther than the largest view. The plan is published and tested but not drawn.

## 14. No way to start a scene with parameters or to record an input replay

- **Category:** tooling
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0030
- **Suggestion:** factoria run --prop name=value (read through an engine API) and input.record(path) that writes the replay format
- **Workarounds seen:**
  - A generated scene per shot (store/make_store.py) holds a script with literal props; store/record.test.js drives MinerBots under factoria test and prints @@REPLAY lines the script turns into replays; scripts/game/busiest.js reads an override export for tests

## 15. Options Controls tab lists a hard-coded jump action

- **Category:** ui
- **Severity:** minor (score 4)
- **Total occurrences:** 2
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0005
- **Suggestion:** Build the list from input.actions() minus the ui_* ones, taking the label from options.action.<name> and falling back to the action name.
- **Workarounds seen:**
  - Edited the 'actions' list in scripts/ui/options.js and added options.action.move_up, move_down and dig to locales/en.json.

## 16. Text wrapping cannot break Thai (or Khmer, Lao, Burmese) at word boundaries

- **Category:** ui
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0036
- **Suggestion:** Break opportunities at ZWSP (U+200B) and WORD JOINER-free runs, or a dictionary-free Thai/Khmer/Lao/Burmese break iterator (ICU-style); then a locale could carry ZWSP between words
- **Workarounds seen:**
  - The Thai table writes a real space between phrases and keeps every space-free run under 17 base letters, checked by a test and by tools/thai_spaces.py

## 17. The exported player has no input replay, state dump or screenshot option

- **Category:** tooling
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0029
- **Suggestion:** Give factoria_player --input FILE, --state-out FILE and --screenshot-at in a release build too (headless or windowed), or document that the player is not testable
- **Workarounds seen:**
  - SHIPPING.md: the exported app is smoke-tested with --frames (exit 0, logs the scene load), input is proven by factoria run --headless --input with a state dump on the same project and scripts; the real keyboard and pad run on the exported build is a manual check

## 18. Audio docs do not say a scene load stops the music

- **Category:** docs
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0012
- **Suggestion:** Say in the audio.music doc string and in AUDIO.md what a scene load does to music, and offer a persistent music option.
- **Workarounds seen:**
  - scripts/game/music.js starts the stratum's track at every shift (play() always calls audio.music) and reports whether the track changed.

## 19. Menu kit always adds the shop and the age gate

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0004
- **Suggestion:** Give project.add_menu_kit flags such as {"shop": false, "ageGate": false}, default true only when factoria.json declares purchases or ads.
- **Workarounds seen:**
  - Deleted the shop and age-gate files by hand, removed their imports, the shop_button handler and the 'ageGate' and 'shop' locale blocks from scripts/main_menu.js, scenes/menu.scene.json and locales/en.json.

## 20. No Steam Deck detection API

- **Category:** input
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0022
- **Suggestion:** platform.device with {steamDeck, handheld}
- **Workarounds seen:**
  - scripts/game/deck.js isDeck() looks for a connected pad of type steamdeck, so a Deck driven by the keyboard or touch is not detected

## 21. No behaviour tree or other AI module

- **Category:** scripting
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0011
- **Suggestion:** Ship a behaviour-tree helper in the scripting module, or document the pattern in AI_GUIDE.md.
- **Workarounds seen:**
  - scripts/game/behavior_tree.js is a small generic tree (sequence, selector, condition, action with hooks, wait, cooldown, inverter, succeeder); scripts/game/enemy_brains.js builds the beetle, thief and Mole King trees on it.

## 22. No quit or window-close event

- **Category:** platform
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0023
- **Suggestion:** game.on('quit', fn) with a short grace period
- **Workarounds seen:**
  - Only the Quit button of the title flushes the analytics (scripts/main_menu.js quit()); closing the window loses the unsent events, which stay queued only in memory

## 23. No way to frame a still of the game from a camera that follows the players

- **Category:** rendering-2d
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0034
- **Suggestion:** assets.draw_capsules option for a safe area or a logo anchor so the focus keeps the subject clear of the logo
- **Workarounds seen:**
  - store/make_store.py renders a staged keyart scene, lifts the picture with PIL (KEYART_LIFT) so the logo sits below the miners, then calls assets.draw_capsules

## 24. Steam Remote Play Together guests are not exposed

- **Category:** platform
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0015
- **Suggestion:** platform.steam.remotePlay: {guests: [{index, name}]} plus an event, and the fake store able to add guests.
- **Workarounds seen:**
  - join.js and pad_watch.js treat every pad the same and poll, so a guest pad that appears mid-lobby joins with A; tested with a pad connected during the lobby on the test API (no fake Steam store hook exists for it).

## 25. The installed windows, linux and mobile players carry no build fingerprint

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0032
- **Suggestion:** Stamp the fingerprint when a player is built or fetched, or compare by engine version when it is absent
- **Workarounds seen:**
  - export with --allow-player-mismatch for windows and linux and say in SHIPPING.md that those two builds were not run

## 26. The test runner cannot press Enter on a TextField

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0024
- **Suggestion:** game.pressKey('Enter') or game.submit(id)
- **Workarounds seen:**
  - tests/deck.test.js checks onChange only; onSubmit in text_entry.js is used the same way and is untested

## 27. The window API has no borderless mode and no monitor choice

- **Category:** platform
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0027
- **Suggestion:** window.setMode('windowed' | 'borderless' | 'fullscreen') and window.monitors / window.setMonitor(i)
- **Workarounds seen:**
  - Options > Video offers windowed and full screen only, and shows the monitor's size as text (scripts/ui/options.js)

## 28. Tilemap tileset has no margin or spacing

- **Category:** rendering-2d
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0002
- **Suggestion:** Add Tilemap.margin and Tilemap.spacing (vec2, texture pixels), and the same for Sprite sheets in assets.generate_sprite_sheet / the editor tile picker.
- **Workarounds seen:**
  - assets/src/make_atlases.py cuts the tiles out of the source sheets and re-packs them margin-free into assets/tiles_topsoil.png, tiles_crystal.png and tiles_magma.png and assets/sprites.png (run once, output committed).

## 29. game.click on a widget of a panel opened in the same frame silently does nothing

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0019
- **Suggestion:** game.click throws 'widget not laid out yet: step once after activating it'
- **Workarounds seen:**
  - tests step twice after opening a panel before clicking in it (tests/cloud.test.js, tests/saves.test.js)

## 30. game.today() has no time of day, so the UTC date is not derivable

- **Category:** scripting
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0017
- **Suggestion:** add utcIso (the UTC date) or hour/minute to game.today(), still fixed by game.setDate in tests
- **Workarounds seen:**
  - scripts/game/daily.js keys the daily dig on the local date (game.today().iso); players in other time zones roll over at their own midnight, and the README says so

## 31. localization validate's glyph check misses U+0E4D that Thai sara am (U+0E33) needs

- **Category:** ui
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0037
- **Suggestion:** Run the glyph check on the characters the shaper actually draws (after the decomposition), or document it in docs/LOCALIZATION.md
- **Workarounds seen:**
  - The font subset script keeps U+0E4D explicitly and checks the decomposed forms (assets/fonts/make_subset.py --check)

## 32. platform.cloud has no modified time or conflict signal

- **Category:** platform
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0018
- **Suggestion:** cloud.stat(key) answering { modified, size } and a conflict event where the store has one (Steam Cloud, iCloud)
- **Workarounds seen:**
  - scripts/game/cloud.js stores a revision counter in every save and the revision last synced per slot (burrow.cloudBase.N), settles a conflict by play time and keeps the loser as burrow.backup.N

## 33. publish.steam refuses app 480 even in a dry run

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0033
- **Suggestion:** Allow dryRun with app 480 (print the plan and a warning) and refuse only the real upload
- **Workarounds seen:**
  - The dry run is shown with an explicit appId placeholder (factoria call publish.steam '{"dryRun":true,"appId":1234567}'); steam_appid.txt keeps 480 for the Spacewar check

## 34. renderStats().lights does not count Light2D

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0009
- **Suggestion:** Add lights2d (counted) and lights2dDropped to renderStats().
- **Workarounds seen:**
  - tests/helpers/world.js activeLights() counts the active entities that carry a Light2D component instead of the lights the renderer uses.

## 35. renderStats, perf.measure and maxLights do not count Light2D

- **Category:** performance
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0028
- **Suggestion:** Count Light2D in renderStats().lights (or add light2d) and let perf.json maxLights apply to both
- **Workarounds seen:**
  - tests/render_budget.test.js counts the active Light2D entities itself (cap 16) on the busiest floor, next to the draw call and entity budgets

## 36. ui.check_layout ignores ScrollList clipping and sees only scenes as they settle

- **Category:** ui
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0038
- **Suggestion:** Clip a widget's rectangle by its ScrollList ancestors in check_layout, and accept a list of steps (clicks) per scene to reach a state before checking
- **Workarounds seen:**
  - tests/helpers/layout.js reads ui.state (rectangles, overflowed) and clips by ScrollList ancestors; tests/layout.test.js drives every script-opened panel; the one known false positive is filtered by name

## 37. A test cannot write a file, so a recording has to go through stdout

- **Category:** tooling
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0035
- **Suggestion:** A files.write under the project's build/ folder available to tests (tools already have project files)
- **Workarounds seen:**
  - store/record.test.js prints one @@REPLAY JSON line per floor and make_store.py parses them out of the test output

## 38. assets.synth_sound presets come out much louder than the validator accepts

- **Category:** audio
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Burrow Brigade
- **Entries:** Burrow Brigade/FB-0007
- **Suggestion:** Have synth_sound normalise its output to about -18 LUFS, or write the normalize import setting to assets.json itself.
- **Workarounds seen:**
  - Set defaults.audio {normalize: true, targetLufs: -18} in assets.json so every effect plays at the same loudness.

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

Re-triage 2026-10-24, after M26 (#149-#176; each package's merge commit is in ROADMAP_DONE.md): 49 Clockwork Courier
entries are fixed, each with a `Fixed in <commit>` note, and the game dropped their workarounds in the `m26/bookkeeping`
PR (its own grid pathfinding, the eight copies of the level panels, the letter grid of the name screen, the dark-tint
paints, the hand resets between tests). CC/FB-0051 stays open for M19's video player; the parts left to M12 are in its
ranking. Moving the game onto the navmesh found one more entry, CC/FB-0056 (no rope bridge, seesaw or moving platform in
the mesh, no off-mesh links), ranked second in M19. M27 takes what the games asked of M12 and M19.

Re-triage 2026-10-25, after M27 (#179, #180, #182-#185; each package's merge commit is in ROADMAP_DONE.md): CC/FB-0051
and CC/FB-0056 are fixed, and so are the parts of CC/FB-0020, CC/FB-0028 and CC/FB-0030 left to M12; each has a
`Fixed in <commit>` note. Clockwork Courier's studio intro is a video (#182), its dogs cross the bridges (#179), and its
name screen's keyboard is the kit's again, which stays closed under Steam's (the `m27/bookkeeping` PR). No entry of any
example game is open: the ranked list above is empty.

Triage 2026-10-25 of the 38 entries of Burrow Brigade, the M28 reference game, against `c7e6ef6` (each checked in the
code; the doubtful ones reproduced in a scratch project with `factoria test` and `factoria call`): BB/FB-0028 is a
duplicate of BB/FB-0009 (the bookkeeping PR merges their occurrences), with one thing more: the `maxLights` perf budget
compares against a count that has no 2D lights, so it watches nothing. BB/FB-0024 and BB/FB-0035 need docs only
(`game.keyDown("Enter")` already submits a `TextField`; `fa.call("fs.write", ...)` works in a test). Three hold in part:
BB/FB-0031 (`optional: true` exists since `ce8b98c`, but `platform.add_backend steam` does not write it), BB/FB-0019
(`ui.layout()` is documented, but the lost click is silent) and BB/FB-0005 (the Controls tab already hides the actions a
game lacks). Verifying BB/FB-0012 found a bug no game reported: a scene that loads with the same music as the one before
plays nothing while `state().audio.music` says it plays (M29.7). The open entries became the 21 packages of M29 below; one
part of BB/FB-0036 (Thai without marked boundaries) and parts of BB/FB-0015 and BB/FB-0018 stay out (M29's last
paragraph).

Re-triage 2026-10-26, after M29 (the `m29/*` branches; each package's commit is in ROADMAP_DONE.md): the 21 packages are
built and the entries of Burrow Brigade have a `Fixed in <commit>` note (the `m29/bookkeeping` branch). Burrow Brigade
dropped its light pool and `activeLights` helper, its own A* and behaviour tree, its whole-array tile writes, its binding
table, its transport seam and its stdout recordings; what it keeps on purpose is under M29, "Left open".

Sizes: S = under a day for an AI agent, M = 1-3 days, L = a week or more. Ids are `<game>/FB-n`
(sky-hopper = SH, neon-swarm = NS, gem-roller = GR, block-push = BP, lantern-keep = LK, clockwork-courier = CC,
burrow-brigade = BB).

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

- M26 (2026-10-24): a command writes only what it is asked to: `scene.format` with neither `paths`, `all` nor `check`
  writes nothing, and `factoria.json` is patched (its order and formatting kept), never rewritten. A character is
  carried by the kinematic body it stands on (`carriedByPlatforms`, default true) and never shoves a body held by a
  joint. `game.today()` is a fixed date in tests and headless runs and the recorded one in a replay; `pauseOnSuspend` is
  on by default. A mesh under an animated node gets a rigid skin of one joint at import. `platform.release` is false in
  development runs and tests. The navmesh is a deterministic 2.5D grid baked from the static colliders. `connected: ""`
  on a joint is the world. `materialColors` replaces a material's base colour and `color` still tints the whole model.
  `fill` wins over `shrink` in a list; a slider value a script sets sends no `ui.change` (`game.setSlider` does). A
  spawn index outside the parent's children is an error, and a root takes no index. The simulation uses only
  `fa::det::` maths with no floating-point contraction, and CI compares one committed replay hash on every desktop job.
  `project.add_menu_kit` never replaces a key or a file the game edited unless asked (`overwrite`).
- M27 (2026-10-25): a plugin backend that offers only `ads` is an ads backend next to the store backend
  (`platform.ads.backend` picks one); development runs and tests keep the fake, and an export without `--release`
  always uses Google's test app id and ad units. Apple's tracking sheet comes only after Google's consent form, only
  with `trackingPrompt`, and never for a player under age; a `mixed` audience requests nothing until the game tells the
  age. A daily or weekly board is one Steam board per period. A platform keyboard takes a `TextField` through plugin API
  3 (versions 1 and 2 load unchanged) and the kit's keyboard stays closed while `input.platformKeyboard` is true. Video
  is MPEG-1 + MP2 decoded by pl_mpeg on the CPU, the same on every platform, on the game clock; other formats are
  converted at import, never played. An opaque `Video` skips its background and blending, and plain textured quads use
  a shader without the glyph, shape and light branches. A `navWalkable` body is left out of the static bake and
  re-marked where it is; off-mesh links are `NavLink3D` entities, and a path lists where it takes them.
- M29 (2026-10-26): every active `primary: true` camera draws into its `Camera.viewport`, in ascending `depth`, up to 8;
  bloom and `colorFilter` run once with the lowest-depth camera's settings and the UI is drawn once over the whole screen
  (a scene with a second primary camera that used to be ignored now draws it: `primary: false` turns one off). 2D lights
  add up in a light buffer (up to 256 per frame, 32 of them casting tile shadows, which are traced on the CPU), while a
  lit visual with a normal map, and a perspective camera, keep the per-pixel loop over the first 16. `analytics` and
  `remoteConfig` are script modules on `http.fetch`, not services: no analytics event is kept or sent before consent, and
  a game names its servers in `network.hosts`. `input.player(i)` gives each of up to four players their own actions from
  a pad or a key scheme (`input.schemes`); players do not read the mouse or touch. The tile A* (`nav.findTilePath`) and
  the `bt` module are deterministic. `window.setMode` takes `"windowed"`, `"borderless"` and `"fullscreen"`, which look
  the same on Windows and Linux. `game.click` throws, naming the widget, when it is inactive, has no area or is scrolled
  out of its `ScrollList`, instead of clicking nowhere. A scene load restarts its music unless `audio.music(path,
  {persist: true})` keeps it; bus effects and volumes stay across scene loads. A daily leaderboard without `day` is the
  local date's, and a game that wants one board worldwide passes `game.today().utc.iso`. Wrapped Thai breaks only at
  marked boundaries (U+200B). `assets.synth_sound` levels to -18 LUFS. A cloud save has no conflict signal: a game keeps
  a revision counter in the saved value.

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
- ~~The Steam Deck on-screen keyboard for `TextField` is not wired~~: done in M27.4 (plugin API 3, Steam's floating
  and full-screen keyboards, `input.platformKeyboard`), tested against the mock, not on a real Deck.
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

Left open (the next M12 packages): Epic Online Services and GOG Galaxy, push
notifications and deep links, the Android stores outside Play (ads with consent and the GDPR/COPPA screen are done in
M27.1-M27.2; analytics and remote config in M29.21). `PlatformServices` keeps no receipts or entitlement cache: a
backend answers `restore()` itself. Overlay and presence are one call each; there is no `achievements.onUnlocked`
event, rich presence has no localization, and `platform.stats.add` is a get then a set (not atomic across devices).
Cloud saves take JSON values only (no binary blobs, no conflict resolution beyond "last write wins" in the fake).

Next M12 packages, ranked 2026-10-22 with Clockwork Courier's entries: 1. ads with consent on M26.9's API and fake:
Google UMP and AdMob, Apple ATT and the GDPR/COPPA screen (CC/FB-0028); 2. leaderboard periods on Steam, Game Center and
Play Games (CC/FB-0030); 3. the Steam Deck's keyboard with Steamworks (CC/FB-0020; M26.17 makes the in-game one);
4. ~~analytics and remote config~~ (done in M29.21, after M29.20's networking); 5. push notifications and deep links; 6. Epic Online Services
and GOG Galaxy; 7. the Android stores outside Play. A game asked for the first three only: they are M27.1-M27.4, done
2026-10-25. The other four wait for a game that asks for them. Burrow Brigade asked for the fourth (BB/FB-0020), done in M29.21
on M29.20's `http.fetch`; the remaining three wait.

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

- Networking: ~~`http.fetch` (a Promise) in JS on every platform~~ (done in M29.20); WebSocket in JS; real-time
  multiplayer later.
- Saves: slots with their menu (on M10), a version field with a migration hook, optional encryption, cloud through
  M12's `platform`.
- Pathfinding: ~~grid A* on a Tilemap~~ (done in M29.11), ~~a navmesh for 3D (done in M26.10)~~, ~~off-mesh links and
  walkable moving platforms on `NavMesh3D`~~ (CC/FB-0056, done in M27.6), ~~a behaviour-tree helper module~~ (done in
  M29.11).
- ~~Video: a video player component for logos and cut-scenes~~ (CC/FB-0051, done in M27.5 with pl_mpeg).
- ~~`scene.loadAsync` with progress~~ (done as `scene.preload`, M26.7).
- ~~Split screen: a viewport rectangle on Camera~~ (done in M29.19).
- ~~Audio: effects on the buses (low-pass, reverb), ducking and snapshots~~ (done in M29.16).

Acceptance criteria: each item ships with its doctest or JS test and its docs, like any command or component.

Ranked 2026-10-22: the navmesh and `scene.loadAsync` moved to M26 (M26.10, M26.7) because Clockwork Courier needed them.
The rest, in this order: 1. video, for a studio intro (CC/FB-0051; recording an .mp4 is M26.19's); 2. off-mesh links and
walkable bridges and moving platforms on `NavMesh3D` (CC/FB-0056, added 2026-10-24: Courier's dogs stop at a bridge); 3.
save slots with a version and a migration hook (every store game saves); 4. networking (M12's analytics and remote
config need it); 5. audio effects, ducking and snapshots; 6. grid A* on a Tilemap and the behaviour-tree helper (they
can share M26.10's search); 7. split screen. A game asked for the first two only: they are M27.5 and M27.6, done
2026-10-25. The other five wait for a game that asks for them. Burrow Brigade asked for four of them: networking's
`http.fetch` (M29.20; WebSocket waits), audio effects (M29.16), grid A* and the behaviour tree (M29.11) and split screen
(M29.19), all done in M29 on 2026-10-26. Save slots and WebSocket wait.

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
- The 54 open Clockwork Courier entries were triaged 2026-10-22 ("Next engine milestones" above): 50 became M26's
  packages, done (below).
- The exports ran on the iOS Simulator, an Android emulator, a browser pane and macOS on one Mac, not on real phones;
  the Windows and Linux exports were not run. In-app purchases were tested on the engine's fake store only: StoreKit
  needs Xcode and `Products.storekit`.
- The trailer replays of `rooftops_3` and `market_3` drift after about 700 frames; the shots are cut before
  (examples/clockwork-courier/SHIPPING.md, "Trailer").

## M26. Found by the second reference game (S-L each, high; 50 Clockwork Courier entries) — DONE (PRs #149-#176 and the `m26/bookkeeping` PR)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M26 (M26.1-M26.23). 49 of the 50 Clockwork Courier entries are fixed, and the
game dropped their workarounds in the `m26/bookkeeping` PR: the dog and tap-to-move walk on a `NavMesh3D`, the level
panels are three shared prefabs, the name screen uses the menu kit's keyboard, the paints are material colours, the
tests reset their state with `game.resetState`, and `ui.check_layout` finds no issue in the game.

Left open:
- CC/FB-0051: the engine records a trailer as an .mp4 (`factoria setup ffmpeg`, M26.19) but plays no video in a game;
  that is M19's video player, first in its ranking. Done in M27.5.
- M12: the real ad networks and the leaderboard periods of the real stores (CC/FB-0028, CC/FB-0030; M26.9 made the API
  and the fake) and the Steam Deck's own keyboard (CC/FB-0020), first in M12's ranking. Done in M27.1-M27.4.
- M26.7: preloading reads whole files on the main thread within a time budget per frame; a worker thread is later (L).
- M26.13: numbers and stopwatch times only (no currency, percentages or spelled-out durations); a language outside the
  table (hi, th, vi...) is written like English.
- M26.17: the kit's on-screen keyboard has Latin (with each language's extra letters), Cyrillic and Greek keys;
  Japanese, Chinese, Korean and other scripts get the Latin keys, so a player with only a gamepad cannot type a Japanese
  name.
- M26.21: one replay hash holds on the Linux (GCC), Windows (MSVC) and macOS (Clang) jobs; the Android, iOS and web
  players are not compared.
- The trailer replays of `rooftops_3` and `market_3` still drift after about 700 frames (M25; the game's SHIPPING.md,
  "Trailer").
- CC/FB-0056, found by the close-out: the navmesh bakes static colliders only, so a guard dog never crosses a rope
  bridge, the seesaw or a moving platform, and there are no off-mesh links; second in M19's ranking. Done in M27.6.

Next: the first three packages of M12 and M19's first two (video, off-mesh links), the only ones a game asked for
(ranked in their sections): M27. M23's consoles wait for a game that needs them. Two ranked entries are open
(CC/FB-0051, CC/FB-0056).

## M27. What the games asked of M12 and M19 (M-L each, high; CC/FB-0028, 0030, 0020, 0051, 0056) — DONE (PRs #179, #180, #182-#185 and the `m27/bookkeeping` PR)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M27 (M27.1-M27.6). The last Clockwork Courier entries are fixed: rewarded
ads with consent on Android and iOS through AdMob (an ads-only backend next to the store's), daily and weekly
leaderboards on Steam, Game Center and Play Games, the Steam Deck's own keyboard through plugin API 3, a `Video`
component (the game's studio intro is now a video) and off-mesh links and walkable moving bodies on `NavMesh3D` (a dog
crosses the rope bridges). No entry of any example game is open.

Left open:
- Nothing ran against a real store account or device: Google's test ads only (an Android emulator with Google Play
  services and the iOS simulator), no real ad unit or published consent message; the leaderboard periods and both
  Steam keyboards are tested against the Steam mock only; no Game Center or Play Games account, no Steam Deck. The
  steps are in PLATFORM.md (the Steam, Apple, Google Play and ads sections). Not tried either: a refused tracking sheet,
  the `children` audience on iOS, the translated tracking sentence on a device. No CI job loads Google's iOS SDK.
- M27.2: macOS has no AdMob SDK, so a Mac game shows no ads (`platform.has("ads")` is false there).
- M27.3: each store starts a period at its own time (Apple's recurring boards when App Store Connect says, Google's at
  midnight Pacific time, the fake at the player's midnight), so one daily board resets at different hours per store.
- M27.4: `TextField` has no `multiline` or `password` yet, so a platform keyboard always gets a one-line, visible field.
- M27.5: MPEG-1 + MP2 only (bigger files than H.264 for the same picture, no OS decoder), decoded on the CPU, drawn on
  a UI entity only (no video on a 3D surface). A full-screen video still costs about 15 ms of CPU a frame on llvmpipe
  (sampling the scaled-up picture and uploading it each frame) and well under 1 ms on Metal.

Next: M28 below, the third reference game, reported 38 open entries; their triage (2026-10-25) is M29, which also takes
most of what was left of M12 and M19. The manual checks against real stores and devices (M8, M9, M12 and the list above) need
accounts and hardware this machine does not have.

## M28. A third reference game: couch co-op on the desktop (L, high) — DONE (the `m28/reference-game` PR)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M28. Burrow Brigade (`examples/burrow-brigade`) is a 2D mining game for one
to four players on one screen, for the desktop and Steam first, built in eight packages by game-maker AIs with no
engine change.

Left open:
- Its 38 entries (14 major, 22 minor, 2 nice-to-have; the ranked list above) were triaged 2026-10-25: M29 below.
- The Windows and Linux exports were made but not started (no machine here; their installed players carry no build
  fingerprint, BB/FB-0032). The macOS app starts, renders and exits on this Mac, but input on the exported binary was
  not checked: the player takes no input replay (BB/FB-0029), so it is the by-hand step in the game's `SHIPPING.md`.
- Nothing ran against Valve's library: app 480, the overlay, rich presence, Remote Play Together, a real upload. The
  online features ran against the game's fake server only, and no Steam Deck was tried.
- The Russian and Thai texts (game and store) were not read by a native speaker.

## M29. Found by the third reference game (S-L each, high; 37 Burrow Brigade entries) — DONE (the `m29/*` branches; PRs to open when GitHub is back)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M29 (M29.1-M29.21). The engine gained what Burrow Brigade asked for: Light2D in
the stats and the perf budget, a light buffer with no 16-light cap and tile shadows, split-screen cameras, per-player
actions (`input.player(i)`), gamepad events and the Steam Deck flag, monitor choice and window modes, tile pathfinding and
behaviour trees, tilemap margin and spacing with `setTile`, bus effects, ducking and snapshots, layered music and the
scene-load music fix, `http.fetch` on every platform with analytics and remote config on it, Remote Play guests and
`cloud.stat`, the clipboard and the quit event, the time of day in `game.today()` and daily boards by date, Thai breaks at
marked boundaries, a test runner that lays the UI out and throws for a hidden widget, `input.record` and scene props, the
exported player's `--input`, `--dump-state` and `--screenshot`, and a Steam export from one Mac. Burrow Brigade dropped
its `activeLights` helper and light pool, its own A* and behaviour tree, its whole-array tile writes, its binding table,
its transport seam for news, balance and analytics, its daily-board skip and its stdout recordings. Its entries carry
their `Fixed in` notes in the `m29/bookkeeping` PR; the workarounds it keeps on purpose are listed below.

Left open:
- Workarounds Burrow Brigade keeps on purpose (their "Fixed in" notes say why): the music layers and bus effects are
  still its own emulation (BB/FB-0025, BB/FB-0026: moving to `musicLayers`, filters and reverb means re-rendering the
  one-bar loops and listening); the store scenes are generated and the bot replays kept (BB/FB-0030); the capsules were
  not redrawn (BB/FB-0034); the exported builds were not checked by hand (BB/FB-0029, BB/FB-0033); the cloud revision
  counter stays because Apple has no modified time (BB/FB-0018); unmarked Thai needs a dictionary (BB/FB-0036).
- Out of M29, as planned: breaking unmarked Thai, Khmer, Lao and Burmese (a word dictionary), a cloud conflict event, mapping
  a Remote Play guest to a pad (needs ISteamInput wrapped), cross-compiling plugins from the Mac, and WebSocket.
- M29.1: the budget it compares against is 256 since M29.14.
- M29.2: the Burrow Brigade daily dig uses `game.today().utc`; Game Center and Play Games take only the local or UTC today.
- M29.5: the capsule focus is the worker's reading of the spec.
- M29.6: `game.click` now throws for a hidden or unlaid-out widget: a test that clicked one by mistake fails.
- M29.7: layers of unequal length drift.
- M29.8: the kit has an unused `platform` import.
- M29.9: the non-Apple pad backends are untested here; `SteamDeck=1` is Steam's unofficial variable.
- M29.10: slice limits, floor fragmentation, a 4096-edit cap, `tilemap.set_tile` missing from AI_GUIDE's MCP table, the
  `tileDims` native.
- M29.11: `nav.tileVersion` does not count replacing `tiles` as a whole; no `parallel` or `repeat` nodes.
- M29.12: no wheel, locked mouse or text in the replay; props are not in the replay.
- M29.13: the player has no `--props`; screenshots may differ across GPUs.
- M29.14: only Metal ran (the GL, GLES, D3D11 and WGSL shader headers compile but were not run); a visual with a normal
  map and a perspective camera keep the per-pixel loop over 16 lights; the Linux and Windows draw-call baselines (+1) are
  assumed, not measured; no `api_since` row for `lights2dShadowed`; the costs in PERFORMANCE.md come from one Mac.
- M29.15: players do not read the mouse or touch; no doctest of `input.schemes` parsing in project.cpp (the input doctests
  and Burrow's tests cover it).
- M29.16: effects persist across scene loads; attack and release are time constants; the CPU costs are estimates; only
  macOS tested.
- M29.17: no manual check on any OS; the Windows and Linux code is not compiled here; borderless and full screen are the
  same on Windows and Linux; macOS borderless is untested.
- M29.18: only the Steam mock is tested (no real Steam, Google Play or iCloud); the Windows, Linux, Android and Swift code
  is not compiled here; no mapping of a session to a pad and no conflict event.
- M29.19: only Metal ran; screen-space `lit` visuals get only ambient light in a frame with several cameras; the editor's
  outlines and gizmos project through the first camera only; no `api_since` rows for the new script functions (the file
  lists components and commands only).
- M29.20: the other platforms are not compiled here; Win32 disables cookies and automatic authentication; Android sends
  PATCH as POST with an override header and plain `http://localhost` does not work there; CORS applies on the web; the
  translated docs are not updated; no `api_since` rows; requests still in flight when a recording stops are not recorded.
- M29.21: Burrow's server URLs are placeholders (`burrow-brigade.example`, explained in its README); the iOS export's
  analytics privacy entry is untested; retries on network errors, 408, 429 and 5xx with backoff.
- Clockwork Courier's test `market_3 > the expert shortcut wins too` is close to its 60 s limit and times out when the
  machine is loaded (it did on `main` too).

Next: no feature is planned. The next milestone is whatever the next reference game or the store accounts ask for; what
is left of M12 (push notifications, deep links, Epic and GOG, the Android stores outside Play), M19 (save slots, WebSocket)
and M23 (consoles) waits for a game that needs it. The manual checks that need real stores, devices and operating
systems (M8, M9, M12, the lists above) need hardware this machine does not have.

## Out of scope: Roblox

Roblox is not an export target. Roblox games run Luau inside Roblox Studio with Roblox's own services (DataStore,
MarketplaceService); exporting to it would take a JavaScript-to-Luau transpiler and a converter from scenes to `.rbxlx`,
which is a different product. Not planned.
