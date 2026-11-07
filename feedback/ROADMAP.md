# Engine feedback report

Status: the four jam-sized example games reported 73 entries, all verified fixed-in-engine. Lantern Keep, the M21
reference game, reported 45 (none a blocker or major), triaged 2026-10-19: one was already fixed, two were duplicates,
and the 42 open ones became work packages, most of them M24, the rest in M20-M23. M24 fixed 37 of its entries
(M24.1-M24.16, 2026-10-20), two of them found on the way, M21 three, M22 two, M20 one and M23 the last one (MSIX,
2026-10-22): no entry is open. M1-M11 and M13-M15 are done; M12 (platform services) has its API, the Steam, Apple and
Google Play backends, AdMob ads with consent, leaderboard periods on the stores and the Steam Deck's keyboard (M27); M16
(mobile store-ready), M17 (web export), M18 (animation and production 3D), M20 (editor and tooling, 2026-10-22), M21
(docs and material for shipping), M22 (production quality and legal, 2026-10-21), M24, M25, M26, M27, M28, M29, M30 and
M31 (and M32, M33 below) are done; M23 has the Mac App Store and the Microsoft Store (MSIX) done, its consoles part is not started; M19 has the video
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
fixed them all (2026-10-26): no entry is open. The game dropped the workarounds that no longer had a reason; the few it
keeps on purpose are under M29, "Left open".
M30, the fourth reference game (Tidewater Market: a management game played with the mouse, web and desktop first,
2026-10-26), reported 52 entries: one was fixed on the way (TM/FB-0070, the web page downloaded the wasm twice), one
was withdrawn (TM/FB-0015), one is a duplicate, and 49 are open (9 major, 27 minor, 13 nice-to-have, no blocker),
triaged 2026-10-26: five need docs only or are already supported, and the open ones became the 26 packages of M31 (planned
2026-10-26, built 2026-10-27), which closed 46 of the 49 (each `fixed-in-engine` with a `Fixed in` note), and three stay
open (TM/FB-0003, the optional undo helper; TM/FB-0051, the Windows and Linux players of a development build; TM/FB-0055,
a Timeline component for trailers), ranked below; the game dropped the workarounds that no longer had a reason (M31,
"Left open", lists what it keeps and what each package left).
M32, the fifth reference game (Larkspur Lodge: a 3D narrative adventure for the Mac App Store, the Microsoft Store, the
iPad and the Steam Deck, 2026-10-27), reported 36 entries (2 major, 25 minor, 9 nice-to-have, no blocker), triaged
2026-10-27: one is already documented (LL/FB-0010), one is a duplicate of TM/FB-0051 (LL/FB-0804), two are half
supported already, and the 34 open ones became the 15 packages of M33 (planned 2026-10-27, built 2026-10-28), which fixed
all of them (each entry is `fixed-in-engine` with a `Fixed in <commit>` note; LL/FB-0010 was documented already and
LL/FB-0804 is a duplicate of TM/FB-0051), so no Larkspur Lodge entry is open. Three of M32's acceptance criteria are only
partly met (M32, "Left open"); M33 closed what it could of them (M33, "Left open" lists what is still unseen).
Roguestory (the user's own game, not a reference example: a 2D roguelike inside a hand-drawn book, 2026-10-28) reported
6 entries (1 major, 5 minor), and its first session showed three gaps of its own: the console had no wall-clock time, and a
delegated agent was silent for minutes, then cut off by Claude Code's 5-minute tool timeout. M34 (built 2026-10-28) fixed
all of them; Roguestory's entries are `fixed-in-engine` with a `Fixed in` note.
What only certificates, real devices or a device farm can close is under M8 and M9, "Left open". What finished
milestones built is in [ROADMAP_DONE.md](ROADMAP_DONE.md); this file keeps what they left open and the decisions to
respect.
Regenerate the ranked list with `factoria feedback collect examples/sky-hopper examples/neon-swarm examples/gem-roller examples/block-push examples/lantern-keep examples/clockwork-courier examples/burrow-brigade examples/tidewater-market examples/larkspur-lodge --out feedback/ROADMAP.md` (it rewrites the whole file: then put this status and the milestones section back).

3 entries from 9 project(s), 3 distinct gap(s). Ranked by total occurrences x severity weight (blocker 8, major 4, minor 2, nice-to-have 1).

## 1. No way to get players for a development build

- **Category:** platform
- **Severity:** major (score 4)
- **Total occurrences:** 1
- **Projects affected:** Tidewater Market
- **Entries:** Tidewater Market/FB-0051
- **Suggestion:** Let setup players fetch the latest release or CI artifact for a development build, and document the emcc setup next to the web export.
- **Workarounds seen:**
  - Exported macOS (the engine's own player) and an old web player; Windows and Linux exports were refused. Later the orchestrator built the web player with the emsdk in ~/emsdk (Emscripten 6.0.10, the CI version); Windows and Linux are still refused.

## 2. A trailer needs a custom director script and a long recording

- **Category:** tooling
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Tidewater Market
- **Entries:** Tidewater Market/FB-0055
- **Suggestion:** A Timeline or Cutscene component (camera keys, text cards, fades) and a progress line for --record-video.
- **Workarounds seen:**
  - store/trailer/trailer.js and make_trailer.py.

## 3. No undo/redo or data-table validation helpers for game state

- **Category:** scripting
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Tidewater Market
- **Entries:** Tidewater Market/FB-0003
- **Suggestion:** Document a recipe for validating data tables in a project tool (file, pointer, hint, did-you-mean), and offer a did-you-mean helper to scripts so each game does not write its own; optionally a small history helper.
- **Workarounds seen:**
  - scripts/game/state.js (transactions with exact deltas, undo and redo refuse and emit action.rejected), scripts/game/data.js (validateTables with file, JSON pointer, hint and didYouMean) and the project tool project.validate_data.

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
  None of these gaps came from the four example games, which are jam-sized and never needed menus, localization or
  stores; M21 adds a complete reference game to close that blind spot.

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

Re-triage 2026-10-26, after M29 (the `m29/*` PRs; each package's commit is in ROADMAP_DONE.md): the 21 packages are
built and the 38 entries of Burrow Brigade are closed, each with a `Fixed in <commit>` note (BB/FB-0028 as a duplicate of
BB/FB-0009; the `m29/bookkeeping` PR). Burrow Brigade dropped its light pool and `activeLights` helper, its own A* and
behaviour tree, its whole-array tile writes, its binding table, its transport seam and its stdout recordings; its
Options offer the three window modes and a monitor, and a pad player follows its pad by id. What it keeps on purpose is
under M29, "Left open".

Triage 2026-10-26 of the 49 open entries of Tidewater Market, the M30 reference game, against `cf2664d` (each checked in
the code, by three read-only passes over the UI, the platform and export code, and the scripting and tooling code;
nothing was reproduced in a scratch project). TM/FB-0070 was fixed during M30, TM/FB-0015 was withdrawn and TM/FB-0030
is a duplicate of TM/FB-0010 (merged in M30's close-out). The ranked list counts 48 gaps because `feedback collect`
merged TM/FB-0010 (rich text) and TM/FB-0011 (an icon button), which are different (TM/FB-0072, M31.9). Five need docs
only or are already supported: TM/FB-0018 (`Button.autoShrink` and `minFontSize`, on main after 0.2.0), TM/FB-0046
(`game.press` holds an action until `release`; `game.tap` presses it for one frame), TM/FB-0063 (`fa.call` runs any
command from a test, and `i18n.state` is documented that way), TM/FB-0035 (a child is offset from its parent's
`Transform.position`, not from the panel's corner as the entry says: neither the parent's anchor nor its pivot applies)
and TM/FB-0016 (`activeInHierarchy` exists, with an empty doc string; `ui.rectOf` still returns a rectangle for a child
of a hidden panel, where `ui.state` does not). Thirteen hold in part: TM/FB-0001 (the draw order inside a layer is in
COMPONENTS.md since 2026-10-13), TM/FB-0004 (`factoria test FILE --filter` starts one engine per run, not per file),
TM/FB-0011 (a Sprite inside a Button does not take its clicks), TM/FB-0031 (a bold `.ttf` per Text works), TM/FB-0032
(`generator.seed(n)` sets the state; nothing reads it), TM/FB-0033 (the menu kit has `MenuStack`), TM/FB-0034 (exports
pack atlases by group, and Sprites keep naming the source PNGs), TM/FB-0037 (PLATFORM.md says `stats.add` is a get and a
set, but not in its test section), TM/FB-0045 (`activeVoices` is in the `state` command's `audio` only), TM/FB-0051
(the emsdk setup is in BUILDING.md, not next to the web export), TM/FB-0062 (TEXT.md explains `pyftsubset` by hand),
TM/FB-0064 (`maxTextScale` and wrapping at `maxWidth` exist) and TM/FB-0065 (column Panels stack Texts). Verifying
TM/FB-0060 found its cause, a bug: with a renderer a wrapped text measures at least its `maxWidth` (`fonts.cpp` takes
the larger of the two), while headless it measures its widest line, so a layout test passes where the window overflows
and `autoShrink` shrinks a short label for nothing (M31.4). Two more found on the way: SCRIPTING.md's test section calls
`ui.state()`, which scripts do not have (M31.3), and a `storage.set` inside a web `pagehide` handler only schedules the
500 ms IndexedDB flush, which may never run (M31.16). The open entries are the 26 packages of M31 below; the Timeline
part of TM/FB-0055, Windows and Linux players of a development build from CI artifacts (TM/FB-0051) and case and
agreement beyond gender (TM/FB-0061) stay out (M31's last paragraph).

Re-triage 2026-10-27, after M31 (the `m31/*` branches; each package's commit is in ROADMAP_DONE.md): the 26 packages are
built and 46 of the 49 open Tidewater Market entries are `fixed-in-engine`, each with a `Fixed in <commit>` note (the
`m31/bookkeeping` branch); TM/FB-0003, TM/FB-0051 and TM/FB-0055 stay open for the parts M31 left out. Tidewater Market
dropped the workarounds listed under M31, "Left open", and its README and SHIPPING.md lost the sentences that described
them. Its ground is one isometric Tilemap now, so its perf files say 246 entities (game), 112 (title) and 1029 (stress).

Sizes: S = under a day for an AI agent, M = 1-3 days, L = a week or more. Ids are `<game>/FB-n`
(sky-hopper = SH, neon-swarm = NS, gem-roller = GR, block-push = BP, lantern-keep = LK, clockwork-courier = CC,
burrow-brigade = BB, tidewater-market = TM).

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
4. ~~analytics and remote config~~ (done in M29.21, on M29.20's networking); 5. push notifications and deep links;
6. Epic Online Services and GOG Galaxy; 7. the Android stores outside Play. A game asked for the first three only: they
are M27.1-M27.4, done 2026-10-25. The other four wait for a game that asks for them. Burrow Brigade asked for the
fourth (BB/FB-0020), done in M29.21 on M29.20's `http.fetch`; the remaining three wait.

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
(M29.19), all done in M29 on 2026-10-26. Save slots and WebSocket wait. Tidewater Market (M30) wrote its own three
slots with a version and a migration on `storage`, and asked only for storage that scales (TM/FB-0022, done in M31.16) and a
picture of the town for a slot (TM/FB-0020, done in M31.24); the engine's save slots still wait.

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

## M29. Found by the third reference game (S-L each, high; 37 Burrow Brigade entries) — DONE (the `m29/*` PRs)

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
  not redrawn (BB/FB-0034); the exported builds were checked on macOS only, and not played by hand (BB/FB-0029,
  BB/FB-0033, see "Manual checks on macOS" below); the cloud revision counter stays because Apple has no modified time
  (BB/FB-0018); unmarked Thai needs a dictionary (BB/FB-0036).
- Out of M29, as planned: breaking unmarked Thai, Khmer, Lao and Burmese (a word dictionary), a cloud conflict event,
  mapping a Remote Play guest to a pad (needs ISteamInput wrapped), cross-compiling plugins from the Mac, and WebSocket.
- M29.1: the light budget it reports against is M29.14's 256 per frame, not 16 (its test expects 17 lights kept).
- M29.2: the Burrow Brigade daily dig uses `game.today().utc`; Game Center and Play Games take only the local or UTC today.
- M29.5: the capsule focus is the worker's reading of the spec.
- M29.6: `game.click` now throws for a hidden or unlaid-out widget: a test that clicked one by mistake fails.
- M29.7: layers of unequal length drift.
- M29.8: the kit has an unused `platform` import.
- M29.9: the non-Apple pad backends are untested here; `SteamDeck=1` is Steam's unofficial variable.
- M29.10: slice limits, floor fragmentation, a 4096-edit cap, the `tileDims` native.
- M29.11: `nav.tileVersion` hashes the whole map on each call (O(tiles)) to see replacements of `tiles`; the first call
  only takes the baseline.
- M29.12: no wheel, locked mouse or text in the replay; props are not in the replay.
- M29.13: the player has no `--props`; screenshots may differ across GPUs.
- M29.14: only Metal and WebGL2 ran (the GL, D3D11 and WGSL shader headers compile but were not run); a visual with a
  normal map and a perspective camera keep the per-pixel loop over 16 lights; the Linux and Windows draw-call baselines
  (+1) are assumed, not measured; `lights2dShadowed` has no `api_since` row of its own (it is a key of what
  `renderStats()` returns); the costs in PERFORMANCE.md come from one Mac.
- M29.15: players do not read the mouse or touch; no doctest of `input.schemes` parsing in project.cpp (the input doctests
  and Burrow's tests cover it).
- M29.16: effects persist across scene loads; attack and release are time constants; the CPU costs are estimates; only
  macOS tested.
- M29.17: checked by hand on macOS only (below); no second monitor was connected, so moving between monitors is
  untested; the Windows and Linux code is not compiled here; borderless and full screen are the same on Windows and
  Linux; macOS borderless covers the notch (a 16:9 game is letterboxed clear of it, a 16:10 one would draw under it).
- M29.18: only the Steam mock is tested (no real Steam, Google Play or iCloud); the Windows, Linux, Android and Swift code
  is not compiled here; no mapping of a session to a pad and no conflict event.
- M29.19: only Metal and WebGL2 ran; screen-space `lit` visuals get only ambient light in a frame with several cameras;
  the editor's outlines and gizmos project through the first camera only. Burrow Brigade's HUD is screen space, so in a
  top/bottom split its top-left text covers a miner standing at the top-left of the upper view.
- M29.20: the other platforms are not compiled here; Win32 disables cookies and automatic authentication; Android sends
  PATCH as POST with an override header and plain `http://localhost` does not work there; CORS applies on the web; the
  translated docs are not updated; requests still in flight when a recording stops are not recorded.
- M29.21: Burrow's server URLs are placeholders (`burrow-brigade.example`, explained in its README); the iOS export's
  analytics privacy entry is untested; retries on network errors, 408, 429 and 5xx with backoff.
- Manual checks on macOS (2026-10-26, MacBook Air M5, the `m29/player-size` build, one built-in display):
  - M29.17 window modes, from a script in a windowed `factoria run`: windowed 1280x720 comes back to the same frame and
    position after borderless and after full screen; borderless fills the display (1470x956 points) and hides the menu bar
    and Dock; full screen gets its own Space (1470x923, below the notch); full screen to borderless and `setMonitor` in full
    screen throw messages that say what to do; borderless to full screen and `setMonitor(0)` in borderless work;
    `setSize(960, 540)` keeps the top-left corner.
  - Burrow Brigade's macOS export (`--release`): a 15 MB app (16 MB before `-dead_strip`) with a 10.5 MB arm64 binary;
    `codesign --verify --deep --strict` passes; `store/replays/join.json` replayed for 200 frames by the exported player
    gives the same state dump and the same screenshot, byte for byte, as `factoria run --headless`, with all four players
    joined (BB/FB-0029); a windowed `--frames 300` run exits 0; the `publish.steam` dry run with app 480 is accepted
    with the Spacewar warning (BB/FB-0033). Not done: a real upload with 480 (to see it refused) and playing the app by
    hand.
  - M29.19 split screen, windowed on Metal with two players and the option on: together, one camera with the full
    viewport; parted across, two side-by-side views with the dark gap, each following its miner; parted down, two views
    one above the other, the higher miner on top. Each view stays inside the mine.
- Web check in the browser pane (2026-10-26, Emscripten 6.0.10, the `m29/player-size` player): a scene with 40 point
  lights (half with `castShadows`), a light-blocking Tilemap and two cameras side by side draws on WebGL2 as on Metal,
  with no console errors. Burrow Brigade's web export gets through the title, the slot choice and the join; the mine is
  lit by the miner's lamp and a torch can be placed. Not done: two players in a split screen on the web (needs a pad or a
  second keyboard player). The wasm is 8.0 MB, 3.0 MB with gzip (6.8 MB and 2.7 MB in v0.2.0).
- Clockwork Courier's tests `rooftops_3` and `market_3 > the expert shortcut wins too` are close to their 60 s limit and
  time out when the machine is loaded (they did on `main` too).

Next: no feature is planned. The next milestone is whatever the next reference game or the store accounts ask for; what
is left of M12 (push notifications, deep links, Epic and GOG, the Android stores outside Play), M19 (save slots, WebSocket)
and M23 (consoles) waits for a game that needs it. The manual checks that need real stores, devices and operating
systems (M8, M9, M12, the lists above) need hardware this machine does not have. M30, the fourth reference game, is
done (ROADMAP_DONE.md): its 49 open entries were triaged 2026-10-26, and they are M31 below.

## M30. A fourth reference game: management with the mouse, web and desktop first (L, high) — DONE (the `m30/reference-game` PR)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M30. Tidewater Market (`examples/tidewater-market`) is a 2D management game in
a harbour town on an isometric grid, played with the mouse first, for the web and the desktop, built in eight packages
by game-maker AIs with no engine change but one: the web page downloaded the wasm twice (TM/FB-0070).

Left open:
- Its 49 open entries (9 major, 27 minor, 13 nice-to-have) were triaged 2026-10-26 and became M31 below, which closed 46.
- The Windows and Linux exports were refused: there is no player of a development build on this Mac (TM/FB-0051; M31.11
  built the web player and the release fallback, the Windows and Linux players from CI artifacts stay open).

## M31. Found by the fourth reference game (S-L each, high; 49 Tidewater Market entries) — DONE (the `m31/*` branches)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M31 (M31.1-M31.26). The engine gained what Tidewater Market asked for: a UI hit
test (`ui.widgetAt`, `ui.pointerOverUi`), a virtual pointer (`ui.setPointer`), the wheel a `ScrollList` keeps and an empty
focus that holds; tooltips; drag and drop; a `Chart`; icon Buttons; rich text and bold (`Text.markup`, the `text` section);
an interface scale (`ui.scale`), `Panel.minSize` and `maxSize` and the scale events; modal Panels and the menu kit's choice
card and strategy camera rig; wrapped text measured by its widest line and Toggles that fit; modifier chords in bindings;
project audio buses, `audio.activeVoices`, `onEnded` and `AudioListener.zoom`; an AudioWorklet backend for the web player;
the web's hide and close signals and per-key storage with `setAsync` and compression; reusable nav grids and flow fields;
camera helpers (`zoomAt`, `panBy`, `clampTo`); `assets.pack_atlas` and `assets.subset_font`; isometric Tilemaps with
`cellAt` and `cellToWorld`; `render.captureTexture` with `texture.toPNG`; gendered strings; `rng.create` state,
`script.eval` of a module, `didYouMean` and a warning for a field that shadows a Behaviour method; player checks for the
web, Android and iOS exports, `factoria setup webplayer`, the export's size report and a favicon; `feedback collect` that
no longer merges different gaps, perf files of several scenes, and a progress line for `--record-video`. Tidewater Market
dropped its widget scan and focus sink, its wheel flag, its Tooltips class, drag code, chart rectangles, markup renderer
and fake bold, its widget registry and rule spacers for the interface size, its own Rng, its distance fields, its camera
maths and rig, its ambience emulation and voice list, `make_atlas.py` and `make_subset.py`, and its ground is one
isometric Tilemap (game scene 2826 to 246 entities). Its entries carry their `Fixed in` notes in the `m31/bookkeeping`
branch: 47 are `fixed-in-engine`, one is the withdrawn FB-0015, one a duplicate (FB-0030), and three stay open.

Left open:
- Out of M31, as planned, and still open: a Timeline or cut-scene component for trailers (the rest of TM/FB-0055, L, next
  to the editor's animation timeline in M20's "Left open"); Windows and Linux players of a development build from CI
  artifacts (TM/FB-0051; they need a GitHub token, so those exports are still refused on this Mac); grammatical case beyond
  gender (TM/FB-0061: phrase around it, LOCALIZATION.md 5c); an undo history helper (the optional half of TM/FB-0003; the
  validation recipe and `didYouMean` are done); brotli sizes in the web report; and `ui.check_layout` on the current frame
  without reloading (the rest of TM/FB-0063).
- M31.13 tooltips: `Text` has no `tooltip` field and is not hit by the pointer, so a tooltip on a Text is the panel
  that holds it; tooltips are off on touch unless `tooltipOnTouch`; the tooltip is World state drawn by the renderer,
  not entities, so a test reads it through `ui.tooltip` or `ui.state`.
- M31.14 drag and drop: Tidewater Market's hold-free "carry" mode (two clicks) stays game-specific.
- M31.15 Chart: the baseline rule crosses the "last 7 days" text of Tidewater's chart panel; the hover is tested through
  `ui.on("chartHover")`, but there is no test of a Chart's tooltip.
- M31.16 web storage: `pagehide` raises `quit`, which cannot be cancelled there; `storage.setAsync` on the web runs
  between frames, not on a thread, and the writes still waiting are made after the `suspend` and `quit` handlers.
- M31.17 Button.icon: `iconSize` is fixed (it does not follow the font size), the icon has no tint, and a right-to-left
  layout does not flip it.
- M31.18 chords: a modifier pressed on its own is reported on release, not on press (a change for a "press a key" screen
  that waited for the press); mouse chords are kept out of per-player bindings (players do not read the mouse).
- M31.19 modal Panel: it does not handle Escape itself (the card closes through its own choice or the game's `ui_cancel`
  handler); the card's `holdClock` pauses the game with `game.paused`.
- M31.20 web audio: measured in Chromium only (latency about 65-75 ms, in EXPORTING.md); the ScriptProcessorNode fallback
  was not forced or tested; the queue (2048 frames) and the chunk (512 frames) are fixed.
- M31.21 camera: `camera.screenToWorld` reads the last frame, so a script that moves the camera and converts a point in
  the same frame uses the old view.
- M31.22 atlas: the `text.icons` regions in `factoria.json` must be resynced by hand after a repack
  (Tidewater's `rich_text.test.js` fails when they differ); only macOS ran, the Windows and Linux builds of the packer were
  not compiled here.
- M31.23 gender: an entry cannot be plural and a select entry at once; the other examples keep their own copies of the
  kit's `loading.js` (only the CLI fixture and Tidewater Market were migrated).
- M31.24 captureTexture: run on Metal only (GL, WebGL2 and D3D11 readback are the screenshot code, untested for this
  command here); `toPNG` returns Base64 text, not bytes; a slot's picture does not travel with its cloud copy.
- M31.25 isometric Tilemap: Tidewater's trees are part of the ground layer, so a building covers the trees in front of it;
  the editor has no tile painting tool (the plan said its painting follows the projection); the title and stress scenes
  draw one call more (a second texture) and their `maxEntities` budgets were lowered to 1500, 600 and 400.
- M31.26 subset_font: Thai, Khmer and Lao decomposed vowel parts must be listed in `keep`; burrow-brigade and
  clockwork-courier keep their own `make_subset.py`; the subset library's linking was not tried on GNU ld or MSVC.
- Everything: GitHub is suspended, so no CI ran on M29-M31; the Windows, Linux and Android code of these milestones was
  never compiled here, and only macOS (Metal) ran the render tests.

Next: no feature is planned. The next milestone is whatever the next reference game or the store accounts ask for; what
is left of M12, M19 (save slots, WebSocket) and M23 (consoles) waits for a game that needs it, and the manual checks that
need real stores, devices and operating systems (M8, M9, M12, the lists above) need hardware this machine does not have.
The three Tidewater Market entries still open (TM/FB-0003, 0051, 0055) are in the ranked list above. M32 below is a
fifth reference game that asks for some of them.

## M32. A fifth reference game: a 3D narrative adventure for the closed stores, the iPad and the Steam Deck (L, high) — DONE (the `m32/reference-game` branch)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M32. Larkspur Lodge (`examples/larkspur-lodge`) is a 3D mystery in third
person on one snowed-in night in a mountain lodge: branching dialogue, data-driven cut-scenes, an inventory with a 3D item
view, a notebook and a deduction board, four puzzles, three endings, five save slots with a v1-to-v2 migration, five
languages (English, Spanish, German, Korean, Hebrew), for the Mac App Store, the Microsoft Store, the iPad and the Steam
Deck. It was built in eight packages by game-maker AIs with no engine change; `factoria test` runs 340 tests.

Acceptance, checked 2026-10-27 against `8fe80b55`:
- Met: the story bot reaches each of the three endings and pins each state's hash (`tests/story_bot.test.js`); the
  dialogue validation runs on every table and fails on the broken fixture (`tests/dialogue_data.test.js`).
- Met: a v1 save fixture loads in the v2 game and a save in each slot round-trips with its picture (`tests/saves.test.js`).
- Met: every gap met is an `ENGINE_FEEDBACK.json` entry (36), and `feedback collect` includes the game.
- Partly: each device has its own tests per feature (walking by mouse, pad and tap in `movement.test.js`, talking with a
  pad in `dialogue_ui.test.js`, saving with a pad and with touch in `saves.test.js`, the screens with a pad), and
  `cutscene.test.js` skips a cut-scene; but no single mouse-only, gamepad-only or touch-only test walks, talks, uses an
  item and saves in one run.
- Partly: the sandboxed `.pkg` started on this Mac and created its container
  (`~/Library/Containers/com.oxtailgames.larkspurlodge/`), but no save could be made in it (the exported player cannot
  be driven to save, LL/FB-0801; a manual step in the game's `SHIPPING.md`); the iPad build ran on the iOS Simulator, the
  title screen only (LL/FB-0803); the MSIX (18 MB) and the Linux build (23 MB) were made with `--allow-player-mismatch`
  and not run.
- Partly: the busiest room stays under its budgets headless: draw calls at 1280x800 (223) and at the iPad's sizes (214 at
  1180x820, 213 at 2732x2048) are checked by the game's `store/check_budgets.py`, which ctest does not run; the frame
  time is measured by the perf ctest at the design size only.

Left open:
- Its 36 entries (2 major, 25 minor, 9 nice-to-have, no blocker) were triaged 2026-10-27 and became M33 below.
- The acceptance gaps above: one end-to-end test per device, a save made inside the sandbox container (LL/FB-0801), the
  iPad played beyond the title screen (LL/FB-0803), the 1280x800 and iPad budgets in ctest.
- In the game: no voice clips (no voice provider here, LL/FB-0601: the captions run on the step's seconds); loading a
  save made mid-chapter replays that chapter's opening cut-scene; one NPC stands in a wrong pose in the hall screenshot;
  about 21 MB of PNG and WAV sit in the example (store art and the synthesised loops); the Spanish, German, Korean and
  Hebrew texts are machine-made and need a native review before a release.
- TM/FB-0055: the game built its cut-scenes as JSON data played by a script (`scripts/cutscene.js`), so a Timeline
  component is still not asked for by a game; TM/FB-0003: the deduction board built its own undo, which a helper would
  not have shortened much.

Next: M33 (done).

## M33. Found by the fifth reference game (S-L each, high; 36 Larkspur Lodge entries) — DONE (the `m33/*` branches)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M33 (M33.1-M33.15). The engine gained what Larkspur Lodge asked for: widgets
under a plain entity and `ui.focus` on a disabled widget (a boolean), a glyph atlas that grows to 4096 and refills its texts,
`Text.visibleCharacters` and `Text.wordBreak`, `ui.mirrorRtl` with `UiBox.mirror` and `Text.direction`, a `CameraView`
widget with `ui.viewPointer`, studio lighting and `Camera.viewportSpace`, `input.consume`, `input.textInputMode` and
`Panel.wheelPassThrough`, `raycast3dAll` and `raycast2dAll` with `Collider.enabled`, tests that drive the UI like a player
(`game.tap` through the UI, `game.checkLayout`, an atomic fake `stats.add`, `resetState` stopping audio), `world.entities()`
without destroyed entities and `scene.generation`, the glob import of JSON data, the menu kit's `textSpeed` and `slots`
parts, the player's `--persist-storage` with `player.run_ios_sim` and a flat-memory `--record-video`, `generate_voice` without
a provider, `generate_loop` and `convert_audio` (Ogg), Hangul on the kit's on-screen keyboard, and docs and a `validate`
warning for what was already there. Larkspur Lodge dropped its transparent HUD root Panel, its re-cast loops and removed
collider, its typewriter padding and hand-written Korean wrapping, `kit.mx` and the U+200F marks, the four bands and the 0.45
colour factor of its item view, its `MenuStack.busy` routing, its serial id prefixes and `porter.alive` check, its own slot
code and `make_sound.py`; its 36 entries carry their `Fixed in` notes in the `m33/bookkeeping` branch (34 fixed by a
package, LL/FB-0010 documented already, LL/FB-0804 a duplicate of TM/FB-0051).

Left open:
- Out of M33, as planned, and still open: Windows and Linux players of a development build from CI artifacts (TM/FB-0051
  with LL/FB-0804), a Timeline component for trailers (TM/FB-0055) and an undo helper (TM/FB-0003); all three are in the
  ranked list above.
- Resolved (M33.6): with `MenuStack.busy` gone from Larkspur, P opened the pause menu over the journal or a puzzle
  screen. At the user's request P was removed from Larkspur's `pause` action: Escape and gamepad Start pause, as in most
  games, and P does nothing.
- Never seen: `player.run_ios_sim` was not run on a real Simulator or an iPad (M33.12; a `dryRun` test covers its steps),
  and the save made from a replay was not repeated inside the signed sandbox container (`cli_larkspur_ship` runs outside it).
  The M32 gaps that need hardware (a mouse-only, gamepad-only and touch-only end-to-end test, the iPad beyond the title
  screen) stay as M32 lists them.
- M33.2: the atlas still clears when 4096 is full (the retry gathers again in the same frame, so nothing stays blank).
- M33.3: `ui.measureText` has no `wordBreak` option.
- M33.4: not covered by `ui.mirrorRtl`: a screen `Text` or `Sprite` with no parent, the insides of a `TextField`, measuring
  a text with its direction, and the editor's drag gizmos; a `CameraView`'s rectangle is mirrored but its image and u/v are not.
- M33.5: `CameraView` takes a named camera only (no render-texture variant); only Metal ran, the GL flip of the offscreen
  image is untested.
- M33.6: `Panel.wheelPassThrough` is a bool, not a rectangle.
- M33.7: `Collider.enabled` takes effect at the next physics sync; `raycast*All` returns one hit per entity.
- M33.9: `alive` stays true until the end of the frame; a script checks `scene.generation` or the lists.
- M33.10: a file added while the game runs is seen on the next start; Larkspur's cut-scene data still lists its imports by hand.
- M33.11: Larkspur keeps its own Text speed row, older than the kit part.
- M33.13: no search of CC0 sound packs (no source has a keyless API); the Ogg encoder is simple (no stereo coupling, so files
  are larger than a tuned encoder's).
- M33.14: the system-keyboard alternative on pad platforms was not done; only Hangul has a built-in IME.
- M33.15: the `expand` camera behaviour in MOBILE.md is described from the code, not seen on a screen.
- Larkspur's perf baseline on `macos-clang-metal-debug` was refreshed (`peakMemoryMB` 81.1 -> 90.0): the P6 baseline
  predated M32 P7/P8, and the M33 starting point already measured 89.1-89.5 MB; M33 adds about 0.5 MB. `drawCalls` (225)
  and `entities` (331) are unchanged.
- Everything: GitHub is suspended, so no CI ran on M33; the Windows, Linux and Android code of this milestone was never
  compiled here, and only macOS (Metal) ran the render tests.

Next: no feature is planned. The next milestone is whatever the next reference game or the store accounts ask for; what is
left of M12, M19 (WebSocket) and M23 (consoles) waits for a game that needs it, and the manual checks that need real stores,
devices and operating systems (M8, M9, M12, the lists above) need hardware this machine does not have.

## M34. Found by the user's own game, Roguestory (S-L each, high; 6 entries and the agent's silence) — DONE (the `m34/*` branches)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M34 (M34.1-M34.8): wall-clock time on every log line, live progress of
delegated agents with a stuck check, `game.click` and docs that fit an MCP result, `Shape2D` corners, softness and
gradients, four bundled OFL font families with real bold and italic, `assets.generate_texture` and `assets.rasterize_svg`,
the `Interactable` component (any entity composition is a widget, in world or screen space), and an engine that
notices it was updated on disk (the editor offers Restart, `factoria mcp` restarts itself in place).

Left open:
- M34.2 was run with a fake CLI and HTTP requests, not with the real Claude Code inside the editor on a long delegation, and
  not on Windows. Projects made before M34 need `"timeout": 14400000` in their `.mcp.json` (the examples' files too).
- M34.4: the 2D vertex grew from 32 to 48 bytes (HALF2 attributes); only Metal ran, so the GL and D3D11 backends and CI's
  CPU time and memory budgets are unseen.
- M34.5: the export finds a built-in font only when its name is written literally; `game.notices()` does not list the fonts
  copied on demand; the web player was not measured (no emscripten here).
- M34.6: textures are reproducible per factoria build, not bit-exact across platforms; the wood and leather presets read
  as materials but are plain.
- M34.7: no tooltips on an Interactable; a slider drag is approximate under strong perspective; Roguestory still has
  `scripts/ink_ui.js` until it moves to `Interactable`.
- M34.8: Windows cannot restart `factoria mcp` in place (it asks the client to reconnect) and its `_win32` stdin reader was
  never compiled; an engine older than M34.8 has no watch, so the first update to it still needs a manual restart.
- Everything: GitHub is suspended, so no CI ran on M34; Windows, Linux, Android and web were never compiled here.
- The full ctest on the Mac (Debug) passes except the bot playthroughs of clockwork-courier (rooftops_3) and
  tidewater-market (scenarios) when the machine is loaded: they take 24-56 s against the 60 s per-test limit, the same
  with the engine from before M34. Give those tests more room or a lighter bot before CI runs them on slow runners.

## M35. Asked by the user after building Roguestory in the editor (L; 4 packages) — DONE (the `m35/*` branches)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M35 (M35.1-M35.4): `artist`, `audio`, `artCritic` and `reviewer` roles with
reviews that only run when the user presses a button (saved, scored, sent to the orchestrator on request), live tokens, cost
and limits during a run, the editor's open panels kept with the layout, closed feedback archived to
`ENGINE_FEEDBACK.archive.json`, and up to three AI chats running at once with Revert per run.

Left open:
- M35.1: the reviews were run with a fake CLI; no real art critique or game review of Roguestory yet. A reviewer sees the
  game through screenshots and `game.*` commands, so a game without `REVIEW.md` gets a shallower review.
- M35.2: Claude Code reports a message's final `output_tokens` only at its end and the plan windows once per message, so the
  live numbers run a little short until then (the tooltip says "As of HH:MM").
- M35.3: a whole layout reset after reopening was never reproduced; only the closed panels were found lost. Two editors
  open at once share one layout file, a possible cause that was not tested.
- M35.4: the same-file warning comes from tool calls and the end-of-run checkpoint, so a file written by Bash is only seen
  when its run ends; `checkpoint_restore` with a file list is C++ only, not a command.
- Everything: GitHub is suspended, so no CI ran on M35; Windows, Linux, Android and web were never compiled here.

## M36. More from Roguestory and the user's look at the AI panel (S-M each; FB-0007-FB-0010 and 4 requests) — DONE (the `m36/*` branches)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M36 (M36.1-M36.3): `scene.save` leaves out what scripts spawned at runtime,
a `Shape2D` gradient with a transparent `color` draws, `world.spawn` waits for Entity fields that name later children,
`focusOnHover` on a widget that appears under a resting pointer and `InteractableVisual.when: "highlighted"`; in the editor
the review buttons next to **Roles...** with a Start confirmation, gizmo buttons only with a selection, and a live cost
estimate that prices Claude Code's 1-hour cache writes.

Left open:
- M36.1: `project.validate` does not warn about a scene that already holds entities its scripts spawn (the duplicate-id
  warning at load does); an entity a script makes through the `scene.spawn` command is saved like an authored one.
- M36.2: `world.spawnPrefab` stays strict about Entity references to entities that do not exist yet; Roguestory still has
  its workarounds (`scripts/book.js`, `scripts/ink_ui.js`, `scripts/menu.js`).
- M36.3: the plan windows still update once per message (Claude Code reports them so); `output_tokens` still lags until a
  message ends.
- Everything: GitHub is suspended, so no CI ran on M36; Windows, Linux, Android and web were never compiled here.

## M37. The FactorIA program icon (S; the user) — DONE (`m37/app-icon`)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M37: a factory with an AI brain on a navy tile, in the editor's window
(Windows, Linux), the macOS Dock and the executables; the program is called FactorIA wherever the system names it.

Left open:
- The Windows resource (`.rc`, `factoria.ico`) was never compiled here.

## M38. Roles you can turn off, AI settings, Roguestory FB-0011-FB-0015 (S-M each; 4 packages and 2 requests) — DONE (`m38/integrated`)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M38 (M38.1-M38.4 and the launcher): the Roles window in three groups with an
**Enabled** checkbox per role (the orchestrator always on), the **AI settings...** window (asset providers, asset sites and
"use only these sites"), `storage.list` / `storage.clear`, tools and edited modules picked up mid-session, the mouse reset
before every test, `planks` options and a painterly `style` for `assets.rasterize_svg`, and `factoria setup launcher`.

Left open:
- M38.1: the Roles window was only checked by the editor autotest, not by eye; a CLI orchestrator (Claude Code, Codex)
  with roles turned off is covered only with the fake provider.
- M38.4: `style` is a pixel post-process, so it does not follow the SVG's shapes (an ink line appears on every colour
  border, also between two fills that should read as one shape).
- Launcher: on Linux the `.desktop` entry was only tested with a fake HOME; Windows has none (the installer's shortcuts
  cover it).
- Everything: GitHub is suspended, so no CI ran on M37 or M38; Windows, Linux, Android and web were never compiled here.

## M39. The AI panel's global controls, screenshots that do not fill the disk, Roguestory FB-0016-FB-0026 (S-L each; 5 packages and 6 requests) — DONE (`m39/integrated`)

Asked by the user after more work on Roguestory in the editor, plus the 11 entries its AI opened.

- M39.1 (M) Editor layout: an **AI** menu in the menu bar with **AI Settings...** (the Roles move into it), **Export Game**
  in the menu bar instead of the toolbar's Export, the review row and the plan windows above the chat tabs (they are
  global, not per chat), the cost estimate says it is the API price (a subscription is not billed per token), and the
  Engine Feedback panel keeps its size with one scrollbar however many lines it has.
- M39.2 (L) Screenshots for agents: a screenshot without `path` is not kept on disk once the client has it, old
  `.factoria/screenshots` files are pruned, `game.screenshot {region, zoom}` (FB-0020), a filmstrip / contact sheet of an
  animation (FB-0025), a luminance profile with seam detection and `render.pick` (FB-0021), `Camera.zoom` in pixel mode.
- M39.3 (M) Scripts and checkpoints: tweens of destroyed entities and behaviours are cancelled and never resume script
  code (FB-0024), `tween.pauseAll` / `tween.timeScale` and tweens frozen while the game is paused (FB-0025),
  `checkpoint.read` and `checkpoint.restore {paths}` (FB-0017).
- M39.4 (L) 2D rendering: Shape2D gradient stops and easing (FB-0022), a tint inherited by a group of entities (FB-0026),
  a skewed / deformable 2D sprite for page curls and flags (FB-0019).
- M39.5 (M) Generated art: `clipPath` and `pattern` in `assets.rasterize_svg` (FB-0016), a fabric preset with no visible
  period plus a `linen` preset (FB-0018), a narrow, irregular paper vignette with `vignetteWidth` (FB-0023).

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M39 (M39.1-M39.5): the **AI** menu (AI Settings with the Roles tab, Roles...)
and **Export Game** in the menu bar, the provider box, review row and plan windows above the chat tabs, "API cost est."
with a subscription note, one scrollbar in the Engine Feedback panel; temporary screenshots that are deleted once the
client has the image, pruning of `.factoria/screenshots`, `game.screenshot {region, zoom, frames}`, `render.inspect` and
`render.pick`; dropped tweens that never resume script code, `tween.pauseAll` / `timeScale`, `Tween.seek`,
`Behaviour.tween` / `wait`, `checkpoint.read` / `checkpoint.restore {paths}`; Shape2D gradient stops and easing, the
`Tint` component, `Sprite.skew` and the deformable sprite mesh; `clipPath`, `mask` and `pattern` in
`assets.rasterize_svg`, a fabric with no visible period, `linen`, and a narrow irregular vignette with `vignetteWidth`.
`Camera.zoom` was not added: `camera.setZoom` already works in pixel mode.

Left open:
- M39.2: `render.pick` tests each entity's box (its footprint), not its pixels, so a transparent corner of a sprite still
  picks it; a filmstrip advances the running game by the frames it captures; screenshots taken through `factoria call`
  (no MCP or AI client to hand the image to) stay until the next prune.
- M39.3: a `Promise.all` over tweens of which one is dropped never settles (dropped tweens never resolve, on purpose).
- M39.4: the gradient ramp and the sprite mesh were only run on Metal; D3D11 and GL were never run.
- M39.5: `clipPathUnits="objectBoundingBox"` is not supported (user space only).
- Everything: GitHub is suspended, so no CI ran on M39; Windows, Linux, Android and web were never compiled here.

## M40. The editor's menus in the macOS menu bar (L; 1 package and 1 request) — DONE (`m40/integrated`, 0.5.0)

Asked by the user: "on the Mac the menus should be in the Mac's own top bar, like every Mac app".

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M40: a platform-neutral menu model drawn with ImGui on Windows and Linux and
mirrored into NSMenu on macOS (FactorIA app menu with About and Settings..., File, Edit, View, AI, Export, Window,
Help; Cmd shortcuts that a focused text box gets first). From this milestone on every milestone raises the engine
version (0.4.0 for M29-M39, 0.5.0 for M40).

Left open:
- The open menus, the About panel and the tooltips were only checked by the NSMenu tests, not by eye (no accessibility
  permission to drive the menus); real Cmd+Z in a text box only with synthetic events.
- Native menus stay active while an ImGui modal popup is open.
- Windows and Linux were not compiled here (GitHub is suspended, no CI).

## M41. Animations drawn with code, baked into sprite sheets (L; 4 packages and 1 request) — DONE (`m41/integrated`, 0.6.0)

Asked by the user: draw each frame of an animation with code at a deterministic time, pack the frames into a sprite
sheet with its manifest, check it, play it in the game and keep the source so the sheet can be made again; "do all
three" (the code-drawn sheet, the regenerable source and baking engine-drawn entities).

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M41: `assets.animate_svg` (a sandboxed JS module or a SMIL SVG, sampled per
frame), `assets.bake_sheet` (an entity the engine draws, captured on the GPU), recipes in every made asset's
provenance with `assets.regenerate` and stale warnings (validate and the editor), and `SpriteAnimator.clip` with
`mode`, `clipEnded`, the sheet's pivot and padding, plus `assets.preview_sheet`. Neon Swarm's kill effect is a sheet
made with `assets.animate_svg`.

Left open:
- `assets.bake_sheet`'s D3D11 and GL/EGL capture paths were only compiled on macOS and never run (GitHub is suspended,
  no CI); its canvas is capped at 4096 px.
- `assets.animate_svg`'s `clips` need a JS module (a SMIL SVG is one clip).
- `loop: true` on a SpriteAnimator cannot make a clip baked without loop repeat; only `loop: false` overrides
  (neon-swarm FB-0019).
- An `assets.pack_atlas` recipe does not see a frame added later to the folder: list it and run the command again.
- The editor's sheet preview, clip list and Regenerate banner were checked by the autotest (sections Y and Z), not by
  eye.

## M42. 2D animation in parts: keyframed clips, 2D bones and a timeline (L; 5 packages and 1 request) — DONE (`m42/integrated`, 0.7.0)

Asked by the user: build a character or an object in parts and animate each part on its own, not only with sprite
sheets. What exists: the `Animator` plays glTF clips (3D, rigid parts too), `tween()` animates any field from code, and
`Sprite.skew` and the 2D mesh (`meshColumns`, `meshRows`, `vertexOffsets`, M39.4) bend a sprite. What is missing: a
clip saved as an asset with keys and curves, a component that plays it by name, 2D bones with skinned sprites and IK,
and any animation panel in the editor (it has none). A part-built character can then ship as a sprite sheet with
`assets.bake_sheet` (M41.3).

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M42: `*.anim.json` clips played by the Animator (cross-fades, layers with
masks and additive mode, events, the state machine, `animator.sample`), `Bone2D`, `SpriteSkin` (auto or explicit
weights, grid or `outline` mesh) and `IK2D` (`twoBone`, `ccd`), the `anim.*`, `bones.create` and `skin.*` commands with
`anim.check` and `anim.filmstrip`, clips checked by `factoria validate`, the editor's Animation panel (dopesheet, curves,
record mode, onion skin) and bone tools (autotest sections B2 and C2), and `assets.bake_sheet` by clip name. Sky
Hopper's hero is built in parts with bones, clips and IK feet; its crawler is baked from parts into a sheet.

Left open:
- The Animation panel and the bone tools were checked by the autotest (B2, C2) and unit tests, not by hand with a mouse.
- The panel edits one clip at a time: `Animator.layers` and the state machine are set in the Inspector.
- `SpriteSkin.outline` needs the texture's source image: a packed or `.ktx2`-only texture falls back to the full grid
  (one warning). Skinned sprites deform in world space only; a screen-space one is drawn undeformed. No 3D bones.
- `Bone2D.minAngle`/`maxAngle` are kept only by `IK2D`; a script that writes the rotation is not limited.
- Duplicating in the editor and `entity.clone()` copy the posed values of animated parts, not their rest values.
- The CPU and memory budgets of the `skinned-sprites` perf fixture are estimates until CI measures them; only macOS was
  built and tested (GitHub is suspended, no CI for Windows, Linux, Android, iOS or web).

## M43. External tool servers (MCP) the AI can use (L) — DONE (0.8.0)

Asked by the user: let the AI use services such as Scenario (`https://mcp.scenario.com/mcp`, OAuth or
`Authorization: Basic base64(KEY:SECRET)`) when it sees fit, without making FactorIA Scenario-specific.

Built: `mcpServers` in the user `ai.json`; wired for Claude Code (`--mcp-config`), Codex (`-c mcp_servers...`), the
generic CLI agent (`{mcp_config}`) and the API providers (a built-in MCP client over Streamable HTTP and stdio, on top of
the new `fa::ChildProcess`); an "External tools" prompt section; the `ai.tool_servers` command and `factoria ai doctor`
lines; the editor's AI settings > External tools tab (autotest section D2).

Left open:
- OAuth is not implemented (the built-in agent and Codex need a key or header; Claude Code can log in with `/mcp`).
- Not checked against the real Scenario service, nor with real Claude Code or Codex runs (only fake MCP servers and
  scripted CLIs).
- `fa::ChildProcess` for Windows (`child_process_win32.cpp`) was written but not built or run (macOS host only).
- Only tools are used: MCP resources and prompts, sampling and the old SSE transport are not supported.

## M44. Roguestory's 3D book: procedural meshes, render targets, stale tools and run timelines (S-L each; FB-0027, FB-0029-FB-0035) — DONE (0.9.0)

Roguestory (the user's own game) built a 3D book for its menu and opened 8 entries on the way: it had to write its own
glTF encoder to make a mesh in code, could not put its 2D menu on a page, its project tool ran stale code, and nobody
could tell where 17 minutes of an AI run went.

- M44.1 (M) AI tooling: a `project_<name>` tool re-imports `tools/*.js` (and what they import) when a file changed on
  disk since it was loaded, like `script.eval {module}` does, and its result says which file version ran (FB-0029);
  every event of `.factoria/ai/sessions/*.jsonl` carries `t` (ISO time), `tool_end` carries `ms`, a thinking event
  records its duration even when its text is hidden, and a read-only `ai.session_timeline {session, minGapSeconds}`
  lists the gaps with what was going on (tool, thinking, waiting for the model) (FB-0035).
- M44.2 (L) Procedural meshes: `mesh.create({positions, normals, uvs, tangents?, colors?, indices, submeshes})` returns
  an id that `MeshRenderer.mesh` accepts (like `render.captureTexture` ids), `mesh.update` changes it per frame for
  deformation, `mesh.destroy`, and `mesh.save {id, path}` writes a `.glb` (with its materials) so tools need no encoder
  of their own; bounds, picking and shadows work with such meshes (FB-0030).
- M44.3 (L) Render targets: a 2D or 3D camera can render into a texture (`Camera.renderTarget`, a texture id with a
  size) that `MeshRenderer.texture`, material texture params, `Sprite`, `Panel` and `Button` accept, live every frame;
  pointer input reaches the Interactables of that camera through the mesh's UVs (ray -> mesh UV -> 2D camera), so a
  menu drawn on a curved or turning page stays clickable (FB-0031); `render.captureTexture({entity | rect, space,
  scale})` renders an entity subtree or a world rectangle off-screen at an explicit pixel scale, even when it is
  hidden, covered or off camera, with no frame drawn first and no 2048 px cap from the window (FB-0032).
- M44.4 (M) Text and sprites: `Text.fontSize` down to 0.001 so a world Text can be sized in meters, TEXT.md says how
  Text behaves under a perspective camera, and `Text.lit` shades it with the 3D lights (FB-0027); `Sprite.vertexColors`
  (one RGBA per grid vertex, multiplied with `color`) on the deformable sprite (FB-0033); a destroyed entity and its
  children never reach the next drawn frame or capture, with a test that destroys and spawns a group in one frame and
  captures the next (FB-0034).
- M44.5 (L, added while integrating) The two packages built in parallel met: the pointer through a render target reaches
  procedural meshes (and follows `mesh.update`), and vertex colors (`mesh.create {colors}` and glTF `COLOR_0`) are drawn,
  multiplying the material's base color in every 3D path.

Built: `project_<name>` tools reload changed modules before the call and report `toolVersion`; session logs carry `t`
and `ms` and `ai.session_timeline` reads them (M44.1). `mesh.create/update/destroy/save/list/info` with bounds, culling,
shadows, `Collider3D` shapes and the editor's picking on the real geometry (M44.2). `Camera.renderTarget` and
`"target:<name>"` textures, the pointer through the hit triangle's UV, off-screen `render.captureTexture({entity |
rect, space: "world", scale})` up to 4096 and docs/RENDERING.md (M44.3). `Text.fontSize` down to 0.001, `Text.lit`,
`Sprite.vertexColors`, and an entity destroyed in a frame is not drawn in that frame (M44.4). Procedural meshes behind
the render-target pointer and vertex colors drawn (M44.5).

Left open:
- Only Metal ran: the render targets, the procedural mesh uploads and the 52-byte mesh vertex with its color attribute
  are not run on GL, GLES or D3D11 yet (CI sees them first).
- The render-target pointer takes the nearest page mesh: other 3D things in front do not block it; a Sprite, Panel or
  Button that shows a target forwards no input.
- `Text.lit` is one Lambert term per Text at its origin (no shadows, no per-pixel light) and uses the 3D `Light`s even
  in a 2D scene.
- Vertex colors are 8 bits per channel, clamped to 0..1; their alpha shows only with `blend` or a clip material.
- A `Collider3D` on a procedural mesh is rebuilt on every `mesh.update` (costly for a mesh deformed each frame).
- The editor picks glTF models and primitives by their unit box; only procedural meshes use their triangles.

## M45. Extensions the user adds (skills, hooks, plugins) and fewer tokens per step (S-L each; the user) — DONE (0.11.0)

Asked by the user (2026-10-31) after seeing Microsoft's TokenEconomizer (a Claude Code / Codex / Copilot CLI plugin, Apache
2.0, Python 3.10+: learned repo facts injected at session start, unused tools denied in `.claude/settings.local.json`, and
a judge model that redirects a turn stuck in a failure loop; 18-31% lower cost on SWE-Bench): can FactorIA use it, and
can the user add skills, hooks and plugins of their own to the engine?

What the code says today:
- A game's AI runs never see such a plugin unless it is installed at the user level of the CLI: FactorIA starts `claude
  -p` in the game's folder, and nothing in `ai.json` names plugins, skills or hooks. The API providers run FactorIA's own
  loop, where a CLI plugin cannot reach at all.
- AI_COSTS.md: about 72% of a game's cost is cache reads, so the cost is context size x steps. The biggest single item
  of the context is FactorIA's own: the built-in loop sends every command as a tool, with summary, full description and
  schema (`tools_from_registry`, session.cpp). Measured on 0.9.0: 186 tools, 337 KB of JSON, roughly 80k tokens on every
  step, before the system prompt and the conversation.
- What TokenEconomizer does by hooks (SessionStart, UserPromptSubmit, PostToolUse, PostToolUseFailure, Stop, SessionEnd)
  can be done by the engine for every provider, and its own cost then shows in the run's costs and limits.
- Its tool pruning writes deny rules into the game's `.claude/settings.local.json`; a FactorIA tool used rarely
  (`project_export`, `publish_*`) can be denied there and missing when a later task needs it. The role restrictions FactorIA
  passes (`--allowedTools`, `--disallowedTools`) cannot undo a deny rule.
- It supports Claude Code 2.1.300-2.1.310; this Mac runs 2.1.312.

Packages (M45.1 first: M45.3 and M45.4 build on its config section; M45.2 is independent; M45.5 needs M45.2 and M45.4;
M45.6 needs M45.1):

- M45.1 (L) Extensions in `ai.json` and the CLI bridge: an `extensions` section (user `ai.json`, and a project file
  `.factoria/extensions.json` that holds no keys) lists plugins (a directory, a `.zip`, or a Claude Code `name@marketplace`
  the user installed), skill folders and hooks, each with `roles` and `enabled` like `mcpServers`. Claude Code gets
  `--plugin-dir` per plugin and a per-run `--settings` file with the hooks (named per run, deleted after, like the MCP
  config); Codex gets what its config takes (`-c` keys, its skills folder); the generic CLI gets `{plugin_dirs}` and
  `{settings}` placeholders, and a run whose CLI cannot take an extension says so. Whether the user's own installed CLI
  plugins load in FactorIA's runs becomes a setting (`inheritUserPlugins`, through `--setting-sources`), on by default as
  today. Anything that runs a program and comes from a project (a plugin, a command hook) runs only after the user trusts
  that project once in the editor (the trust is kept per project path and file hash, and dropped when the file changes),
  so opening a downloaded game never runs its code. Deny rules on `mcp__factoria__*` found in the project's
  `.claude/settings*.json` are reported by the run and by `factoria ai doctor`, with the tool and how to give it back.
  A read-only `ai.extensions {role?}` lists what each role gets and from where, with problems and fixes; the editor's AI
  settings get an **Extensions** tab (add folder, paste a `hooks` JSON, turn on and off per role, trust a project). Docs:
  AI_PROVIDERS.md "Extensions". Tests for the argv of each provider, the trust gate and the schema; autotest section.
- M45.2 (L) Fewer tool tokens on every step: the built-in loop offers a core set of tools in full (scene, files, game,
  docs, the ones a role uses most) and every other command as one line of a catalog; `tools.search {query}` and
  `tools.load {names}` bring in the full definition when the model needs it, and a loaded tool stays offered for the
  rest of the conversation so the prompt cache keeps hitting. Long descriptions move behind `factoria commands <name>` /
  a `commands.describe` call where the summary is enough to choose. A role can name tool groups to always load. The cost
  panel and `ai.session_timeline` split the context of a step into system prompt, tool definitions and conversation, so
  the saving is visible. Claude Code gets the same through its own MCP tool search (`ENABLE_TOOL_SEARCH`), checked
  against the installed CLI. Measured before and after: the same scripted task with the fake provider (bytes sent per
  step) and one real run of a reference-game task; the numbers go into AI_COSTS.md.
- M45.3 (L) Skills for every provider: the Agent Skills format (`SKILL.md` with `name` and `description` frontmatter and
  files beside it), so a skill written for Claude Code or Codex works unchanged. Sources: the engine's own (topic guides
  such as exporting, publishing, 2D bones, shaders, cut from the always-sent prompt and loaded when needed), the user's
  (`~/.factoria/skills`) and the project's (`skills/`). The built-in loop puts one line per skill in the system prompt
  and reads a skill with `skills.read {name, file?}`; Claude Code and Codex get them through M45.1 natively. `skills.list`,
  `skills.new {name}` (a template), `factoria validate` checks the frontmatter with "did you mean" for names, and the
  editor lists them with on/off per role. Docs: a SKILLS.md and the AI guide.
- M45.4 (L) Hooks for every provider: the events of Claude Code's hooks (SessionStart, UserPromptSubmit, PreToolUse,
  PostToolUse, PostToolUseFailure, Stop, SessionEnd) with the same JSON on stdin and the same decisions on stdout
  (`additionalContext`, block a tool call with a reason, stop), so one hook script serves Claude Code and FactorIA's own
  loop; plus `beforeCommand` / `afterCommand {match}` on the command registry, for every caller (an MCP client, the CLI,
  the editor). A hook is a program (user level, or a trusted project) or a JS module in the project's `hooks/` that runs
  in the engine's script sandbox and needs no trust. Timeouts, the hook's output and its time go to the session log
  (`hook` events) and the run timeline; a failing hook is reported, never silent. For Claude Code the same hooks go into
  M45.1's `--settings` file. Docs: HOOKS.md; tests for each event and decision with the fake provider.
- M45.5 (M) The engine's own token savers, for every provider and counted in the run's costs and limits, each with a
  switch in the Extensions tab: (a) loop guard: the same command failing with the same error code three times in a turn
  gets one short redirect (what failed, the hint, a different way), with no model call; an optional judge through a
  role the user picks, its tokens in the run's cost; (b) learned tool groups: per project, the tools that runs load
  (M45.2) are counted and the editor proposes the groups to load up front, applied only when the user accepts; nothing
  is ever denied, only offered later; (c) project facts: a command that fails the same way in several runs until one
  fix works proposes a line for the project's AGENTS.md, written only when the user accepts.
- M45.6 (S) TokenEconomizer through M45.1 on a real game: a one-click **Add TokenEconomizer** in the Extensions tab that
  shows what it will install (its marketplace and plugin, and that it needs Python 3.10+) and runs the CLI's own plugin
  commands for the user; then a reference-game task run three times with Claude Code, with and without it, checking that
  its hooks fire in `-p` runs, that its tool pruning does not hide a FactorIA tool a later task needs (or that M45.1's
  warning catches it), and what it saves next to M45.2 and M45.5. The result goes into AI_COSTS.md and the example's
  ENGINE_FEEDBACK.json.

Result (2026-11-01): all six packages landed in 0.11.0. M45.6's six paid runs (Sky Hopper, Claude Code + Sonnet, three with
TokenEconomizer and three without, alternated) all finished green: $1.27 with it and $1.08 without, a difference within the
2.5x run-to-run spread. Its hooks fired in `-p` runs, but in three sessions it injected no fact, proposed no tool to prune
and redirected no loop (0 tokens of overhead), so the pruning of FactorIA tools was not reached; M45.1's deny-rule warning
covers it when it happens. Details in docs/AI_COSTS.md; the gap the runs reported (FB-0027, `legendFrom` not named by the
unused-glyph warning) is fixed.

## M46. Feedback from every game reaches the engine developer (L; 4 packages; the user) — DONE (0.10.0)

Asked by the user (2026-10-31): FactorIA has one developer, and the feedback of games made by other people must reach
them. Today `ENGINE_FEEDBACK.json` stays on each user's machine and `feedback collect` only reads folders the developer
has. Agreed design (docs/design/FEEDBACK_SHARING.md): a generic copy of each entry (`share`, engine terms only, cleaned
by a sanitizer, nothing about the game) goes to the developer's own Cloudflare Worker after the user's consent; the
server validates, rate-limits and bans; the ranking counts installations, not reports; GitHub sign-in is an optional
identity that gives a report full weight; the user's AI checks a report before it is sent; the developer pulls into an
inbox outside the repository with an AI classifier and a quarantine; each release ships the list of fixed gaps, which
closes matching entries in the users' games.

- M46.1 (L) The server: tools/feedback-server (Worker + D1, `node --test` suite in ctest), deploy script, privacy page.
- M46.2 (L) The client: `share`/`reviewed`/`shared` fields, sanitizer, consent and outbox, the `feedback.share*`
  commands and CLI, GitHub device flow, the embedded `feedback/fixed.json` and `feedback.check_fixed`.
- M46.3 (L, after M46.2) The editor and the AI: consent dialog, Settings > Feedback, ask-mode confirmation, a new-entry
  form, `ai.review_feedback`, AI_GUIDE.md and AGENTS.md.
- M46.4 (L) The developer's side: `feedback pull` with classification and quarantine, bans, the per-installation
  ranking in `collect`, `feedback fixed`.

## M47. Roguestory's storybook: a culling mask by tags and presses while paused (S-L; FB-0036, FB-0037) — DONE (0.12.0)

Roguestory (the user's own game) reported two gaps on 2026-10-31 while building its 3D storybook: a press sent with
`game.input` to a paused game never reached `input.pressed`, and its page cameras could not leave out what they should
not draw, so the pages lived on a stage at x 5000.

- M47.1 (S-M) `Engine::frame` no longer clears input edges on a paused frame (only mouse motion, wheel and typed text),
  so the edge waits for the next simulated frame; `game.input {frames}` steps like `game.step` (FB-0036). Left open:
  commands accept unknown arguments silently (their schemas do not declare `additionalProperties`); a registry-wide
  check with "did you mean" is a package of its own (M48).
- M47.2 (L) `Camera.showTags` / `Camera.hideTags`, inherited from ancestors, for every world-space visual, shadows,
  picking and the pointer through render targets; `factoria validate` checks the tags (FB-0037). Left open:
  `debug.line` and editor overlays are not tied to an entity and are not filtered; the editor has only the game view, so
  its picking uses the masks.

Both are in `feedback/fixed.json`, which closes the matching Roguestory entries when the editor opens the project.

## M48. Commands reject unknown arguments (L) — DONE (0.13.0)

Found while fixing FB-0036: `game.input {"frames": 2}` was accepted and ignored by an engine that had no `frames`, because
no command schema said `additionalProperties`. Silent no-ops cost AIs whole debugging loops.

- M48.1 (L) `CommandRegistry::add` closes every object schema with `properties` (`fa::close_object_schemas`), so what
  `describe`/MCP show is what `call` enforces; an unknown key is `invalid_arguments` with its JSON pointer, a "did you
  mean" and the accepted keys; `additionalProperties: true` (or a schema) opts out; MCP's `_meta` is not an argument.
  Every command, JS tool and project tool goes through it; `game.input.mouse` now declares its keys; a registry-wide test
  keeps new commands closed. Left open: `game.input.gamepad`/`touch` keep their own "unknown field (ignored)" warning
  (shared with replays), and the per-command unknown-key checks in shots, assets and levels are now redundant.

## M49. Send feedback with one button; game.click through render targets (L) — DONE (0.14.0)

The user tried to send FB-0038 (Roguestory, written by an AI) and found it could not go until they typed a share text by
hand in four boxes and pressed three buttons. Entries an AI wrote already say what is missing.

- M49.1 (L) Engine Feedback panel: **Add feedback** (form with Add / Cancel) and **Send feedback** (every entry that would
  go, all checked, with the exact text that leaves the computer; Send / Cancel). The share text is the entry's `share` or
  one made from the entry by the sanitizer; an AI check runs by itself when a model is set up (`ai.review_feedback` takes a
  candidate `share`). Unchecked entries are `skipped` and come back unchecked. The share editor, "Sharing..." and
  "Archive closed" left the panel (closed entries archive themselves); the table no longer hides rows in a short panel.
  AIs are told to include `share` in every `feedback.report`. Left open: in Always mode an entry that already has a
  `share` still goes out as it is recorded, without the window.
- M49.2 (L) `game.click` names the widget the pointer reached through a page shown on a mesh (`widget`, `via: {mesh,
  target}`; `render.pick` too), and `game.click {id}` aims backwards through the mesh to click a widget only a page shows,
  with a teaching error when no visible point exists (FB-0038). Left open: a target shown inside another target.

FB-0038 is in `feedback/fixed.json`, so Roguestory's entry closes when the editor opens the project.

## M50. A push that passes CI the first time (M) — DONE (0.15.0)

Pushes kept failing CI on what this Mac does not exercise (Windows file sharing and file times, budgets on 4-vCPU runners,
MSVC-only errors), and every fix-and-push round cost a day.

- M50.1 (M) `scripts/ci-preflight.sh`: risk scan of the diff, `test-all.sh`, a stress pass of the touched editor
  autotests and examples under load, every `ci-local.sh` job the host has, Docker and the Windows PC, one summary.
- M50.2 (L) Windows file rules in `fa::fs` (`FA_FS_WINDOWS_RULES`, on for every ctest run on macOS and Linux):
  `fs::ReadStream` holds a file against replace/delete, file times step 15.625 ms; the readers and change detectors of
  tools moved to `fs::`. Found on the way: file times were negative with libstdc++ (`fs::file_time_ns`).
- M50.3 (M) `scripts/setup-docker-macos.sh` + `scripts/ci-docker.sh`: the Linux and MinGW jobs in an Ubuntu 24.04
  amd64 container on the Mac.
- M50.4 (M) `scripts/ci-remote-windows.sh`: the native MSVC build, ctest and examples on a Windows PC over SSH, the
  windowed tests in the logged-in desktop session; a PC that is off is a SKIP, never woken.
- CI saves each job's ccache right after the build. Left open: the Mac's Wine job is not a reference (no HLSL `atan2`
  under Rosetta), so Windows tests need the PC.

## Art, 3D and audio tools inside the engine (M51-M60): shared rules (planned 2026-11-03)

M50 is the CI work of another session (0.15.0); these tools start at M51.

Asked by the user (2026-11-03): would games made by AI be better with art tools inside the engine (a raster and a vector
editor, 3D modeling, sound and music tools)? Yes, if the tools are made for the AI first: an AI does not drive a brush
or drag vertices, it writes and edits data it can read, rerun and check. Building a Photoshop or a Blender clone is not
the goal; giving the AI editable sources, operations as commands and a way to see and hear the result is.

What exists to build on: provider generation (M15: `assets.generate_image`, `_sprite_sheet`, `_sound`, `_music`,
`_voice`, `_model`), the house `style` in `assets.json`, `assets.rasterize_svg`, `assets.animate_svg` and recipes with
`assets.regenerate` (M41), `assets.generate_texture`, `assets.synth_sound` (fixed presets), `assets.generate_loop`,
`assets.analyze_audio`, the engine's Vorbis encoder, `mesh.create`/`mesh.save` (M44.2), keyframed 2D clips, `Bone2D` and
`SpriteSkin` (M42), the glTF `Animator` (skinned playback, no 3D bones made in the engine). PSD imports flattened.

Rules for every milestone below:
- **No external program.** Nothing may need Blender, Photoshop, a DAW, ffmpeg or anything else the user may lack:
  everything is factoria's own code or a vendored library with a permissive license (candidates are named per package;
  each package checks the license and records it in `external/VERSIONS.md` and LEGAL.md). External programs stay what
  they are today: optional MCP servers the user adds (M43).
- **AI first.** Every capability is a command with doc strings and teaching errors. The editor panel of each area is a
  view over the same commands, with the same undo.
- **Readable sources, baked outputs.** The source of an asset is a document an AI can read and diff (`*.image.json`, SVG,
  `*.model.json`, `*.sfx.json`, `*.audio.json`, `*.song.json`); the PNG, GLB or OGG the game loads is baked from it with
  the recipe in its provenance (M41.2), so `assets.regenerate` remakes it and a changed source warns as stale.
- **See and hear every edit.** Each editing command returns a preview (the picture, a turntable, a waveform and
  spectrogram) and the checks of M51, so the loop is make, look, check, fix.
- **Offline and deterministic.** Same document and seed, same output; no key needed. An asset provider, when one is set
  up, is an optional input (a generated layer, an inpainted selection), never required.
- **Shipped like every feature.** Docs (one new doc per area, embedded), typings, `factoria validate` checks, autotest
  sections for the panels, `api_since`, and an example game that adopts the tool and records gaps in its
  `ENGINE_FEEDBACK.json`. M51-M60 ship together, in one PR and as one version (0.16.0), when M60 is done (the user, 2026-11-03).

Order: M51 first (it multiplies every later tool), then 2D images (M52-M54: most FactorIA games are 2D), then audio
(M55-M56), then 3D (M57-M59), then a reference game that uses only these tools (M60). The audio and 3D blocks do not
depend on the 2D block and can move earlier if a game asks for them.

## M51. Eyes and ears: the AI sees and hears what it made (L; 5 packages) — DONE (0.16.0)

- M51.1 (M) A measurable style guide: `style` in `assets.json` gains rules a check can measure, next to `prompt`,
  `references` and `palette`: `outline` (colour, width in pixels), `lightDirection`, `texelsPerUnit` (pixel density),
  `pixelArt`, value and saturation ranges, and loudness targets per audio bus. Every tool of M52-M59 takes them as its
  defaults; `factoria validate` warns about an asset that breaks them, with the rule and the fix.
- M51.2 (L) `assets.check_art {path | paths}`: palette fit (colour count, distance to the style palette), contrast against
  the backgrounds the asset is drawn over, readability at the size the camera shows it (downscaled silhouette and edge
  clarity, phone and desktop), halos and fringes on alpha edges, mixed pixel density inside a set, outline consistency,
  value structure (a greyscale thumbnail). Each rule gives a number, a verdict and a fix hint; the result carries an
  annotated picture.
- M51.3 (M) `assets.contact_sheet {paths, backgrounds, sizes}`: a set side by side at its on-screen size, over the game's
  backgrounds, light and dark, plus greyscale; `assets.preview_in_scene {path, scene, at}` places the asset in a running
  scene and returns the screenshot at phone and desktop resolutions.
- M51.4 (M) Ears: `assets.spectrogram` (waveform, spectrogram and loudness curve as a picture) and `assets.check_mix`
  (every sound measured together: loudness spread per bus, music masking the bands of the effects, clicks at the start
  or end, loop seams, clipping, true peak), each finding with its fix.
- M51.5 (S) The review loop (make, preview, check, fix) in AI_GUIDE.md and in the asset part of the prompt; with a vision
  model set up, `assets.review {path}` compares an asset with the style references and returns concrete fixes (optional,
  like `ai.review_feedback`).

## M52. Layered images: the engine's raster editor (L; 5 packages) — DONE (0.16.0)

- M52.1 (L) `*.image.json` and its compositor: canvas size; layers of pixels (a PNG next to the document), fill, gradient,
  `assets.generate_texture` arguments, SVG (rasterized), text (engine fonts) and a provider image (with its recipe);
  groups, opacity, blend modes (normal, multiply, screen, overlay, add, colour and the usual rest), pixel and vector
  masks, clipping. One CPU compositor, shared by commands and editor, bakes the PNG on save.
- M52.2 (M) Non-destructive adjustments and effects: levels and curves, hue/saturation/value, palette remap and quantize
  (the style palette), posterize, dither (ordered, error diffusion), outline and stroke, drop shadow, inner and outer
  glow, blur, sharpen, noise, colour overlay, gradient map, shading from a normal map.
- M52.3 (M) Commands: `image.create`, `image.layer.add/set/remove/move`, `image.select` (by colour and tolerance, by
  alpha, by rectangle, ellipse or polygon, by a layer's mask; grow, shrink, feather), `image.edit` on a selection (fill,
  recolour, move, transform, delete, copy to a new layer), `image.paint` (strokes as point lists with size and hardness),
  `image.info`, `image.export`. Each result returns the preview and the changed region. A PSD imports as an image
  document with its layers (the flatten warning goes away).
- M52.4 (L) Editor: an Image panel with the canvas (zoom, pan), the layer list, brushes (paint, erase, fill, picker),
  selections, a transform gizmo and the adjustment inspector; autotest section.
- M52.5 (M) With an image provider (optional): `image.inpaint {selection, prompt}` and `image.generate_layer` (a
  generated picture as a layer with a mask); without one the commands say so and point at the offline route. IMAGES.md,
  and an example game that keeps its art as image documents.

## M53. Pixel art and tiles (L; 5 packages) — DONE (0.16.0)

- M53.1 (M) Indexed image documents: a canvas locked to the style palette, colour ramps (shade and light per colour),
  pixel-exact lines, ellipses and fills with no anti-aliasing, `image.pixel` to draw exact pixel lists.
- M53.2 (L) Frames and tags in the document (cels per layer per frame, durations, tags), baked into a sheet with its
  SpriteAnimator clips (M41.4); onion skin; `image.frame.*`; an Aseprite file imports as such a document.
- M53.3 (M) Pixel helpers: inner and outer outlines (selective outline too), shading from the light direction, dither
  ramps, clean-up (orphan pixels, jagged lines), RotSprite-style rotation and scaling, and `image.to_pixel_art` (a
  painted or generated picture downscaled, quantized to the palette and cleaned).
- M53.4 (L) Tiles: tile mode (editing wraps around, seam check), an autotile generator that builds the 16 and 47-tile
  sets from a few parts (inside, edge, corner) with the Tilemap rules, and variations by seed (`image.tileset.*`).
- M53.5 (M) Editor pixel tools (pixel grid, palette bar, frame timeline with onion skin, tiled preview), docs, and an
  example game whose pixel art is redrawn with them.

## M54. Vector illustration (L; 4 packages) — DONE (0.16.0)

- M54.1 (L) SVG stays the document (AIs already write it) and the engine adds operations: path booleans (union,
  subtract, intersect, exclude), offset and inset, stroke to path, simplify, smooth (Clipper2, Boost license, is the
  candidate), align, distribute, repeat (grid, radial) and `vector.style` (apply the style's outline and palette), all
  as `vector.*` commands with a rasterized preview.
- M54.2 (M) Shape builders AIs get wrong by hand: smooth organic shapes from a few points, mirror symmetry, parametric
  shapes (star, gear, rounded polygon, arrow, speech bubble, ribbon), text to paths, and an automatic shadow and
  highlight pass from the light direction (offset and intersect).
- M54.3 (M) Characters in parts: an SVG with named groups becomes part PNGs, pivots and a `Bone2D` skeleton for M42
  (`vector.to_rig`), so an illustrated character animates in parts with no other step.
- M54.4 (L) Editor: a Vector panel (pen, node editing, shape tools, boolean buttons, layers), also used for the SVG
  layers of image documents; docs; an example.

## M55. Sound design: the engine's synthesizer (L; 4 packages) — DONE (0.16.0)

- M55.1 (L) `*.sfx.json` patches: oscillators (sine, square with duty, saw, triangle, noise colours, a drawn wavetable),
  FM and ring modulation, pitch and amplitude envelopes, sweeps, arpeggios, filters with envelopes, distortion,
  bitcrush, delay, reverb, and layers with offsets, rendered offline. The presets of `assets.synth_sound` become patches
  an AI can open and change; the command keeps working.
- M55.2 (M) Variations and families: N variants of one patch by seed for sounds that must not repeat (an `AudioSource`
  picks one), macros an AI can turn by meaning (attack, brightness, weight, tail), and `sfx.family` for a consistent set
  of interface sounds from one patch.
- M55.3 (M) `*.audio.json`: a non-destructive chain over a WAV or OGG (trim, fade, normalize, pitch and time stretch, EQ,
  compressor, reverb, layering, crossfaded loops, granular textures from a sample), so imported CC0 sounds become
  editable sources.
- M55.4 (M) Editor: a Sound panel (waveform, spectrogram, macros as knobs, play and loop, A/B of variants); docs; an
  example game whose sounds become patches.

## M56. Music: composed as data, adaptive at runtime (L; 5 packages) — DONE (0.16.0)

- M56.1 (L) `*.song.json`: tempo, meter, key, sections (intro, loop, outro), tracks with an instrument and patterns written
  as note text, drums by name, velocity, swing and automation, and an arrangement of patterns per section. Helpers:
  chords by name (`Am7`), scales, arpeggiators, basslines from chords, drum patterns by style; `music.check` finds
  off-key notes, clashes between tracks, notes out of an instrument's range and loudness problems.
- M56.2 (L) Instruments: synthesized from M55 patches (leads, pads, basses, plucks, bells, ensembles, chiptune) and a
  synthesized drum kit; a mixer per track (volume, pan, effects) with a master limiter and the style's loudness target.
  Decision for the package: optional SoundFont (SF2) instruments from a file the project brings (an asset, never a
  dependency) through a vendored player (TinySoundFont, MIT, is the candidate).
- M56.3 (M) `music.render` to OGG or WAV with loop points the `AudioSource` honours, and stems per layer; MIDI import and
  export (own parser) so a composer's MIDI becomes a song document.
- M56.4 (L) Adaptive music: a `MusicPlayer` component plays a song (live, or its pre-rendered stems on low-end phones)
  with layers by `intensity`, section changes on the beat or bar, stingers, beat events for scripts and crossfades
  between songs.
- M56.5 (L) Editor: a Music panel (piano roll, arrangement, mixer); MUSIC.md; an example game with an adaptive score.

## M57. 3D modeling by recipe (L; 5 packages) — DONE (0.16.0)

- M57.1 (L) `*.model.json`: a tree of operations evaluated to a mesh by an engine mesh kernel (module chosen per
  ARCHITECTURE.md). Primitives (box, rounded box, cylinder, cone, sphere, capsule, torus, grid, stairs, arch, pipe,
  text), transforms, groups, named parts with materials or vertex colours; baked to `.glb` through `mesh.save` with the
  recipe.
- M57.2 (L) Modifiers: mirror, array and radial array, bevel, Catmull-Clark subdivision, solidify, booleans (Manifold,
  Apache-2.0, is the candidate), lathe, sweep along a curve, loft between profiles, bend, twist, taper, noise
  displacement, smooth, weld, flat or smooth shading.
- M57.3 (L) Organic shapes without sculpting: SDF modeling (spheres, capsules, ellipsoids, rounded boxes with smooth
  union and subtraction) meshed by surface nets or dual contouring and decimated: creatures, rocks, trees, props.
- M57.4 (M) Edits on selections chosen by meaning, not by index (faces by normal direction, by part, by region, top or
  bottom): extrude, inset, loop cut, bevel edges, delete; stable when the tree is evaluated again.
- M57.5 (L) Eyes and editor: `model.preview` (a turntable sheet of 4-8 views, wireframe, a 1.8 m reference figure,
  triangle count) and `model.check` (scale, flipped normals, non-manifold edges, triangles over the platform budget); a
  Model panel (operation tree, parameter sliders, live viewport, part selection); MODELING.md; an example.

## M58. 3D materials, UVs and game-ready models (L; 4 packages) — DONE (0.16.0)

- M58.1 (L) UVs: automatic unwrap (xatlas, MIT, is the candidate), box, cylinder and sphere projections per part,
  packing and the style's texel density (`model.uv`).
- M58.2 (L) Texturing: materials per part from `assets.generate_texture`, triplanar baking, low-poly vertex-colour
  palettes, baked AO, curvature and thickness as masks for wear (edges, dirt), decals; a model's texture opens as an
  image document (M52) to paint on.
- M58.3 (M) Game-ready: LODs (meshoptimizer, MIT), colliders (box or capsule fit, convex hull, convex decomposition with
  V-HACD, BSD), origin and ground, merging, a triangle budget per platform.
- M58.4 (M) `model.import_clean`: a generated (`assets.generate_model`) or imported mesh is welded, stripped of floating
  bits, recentred, scaled to a reference, decimated to the budget, remeshed and unwrapped, and wrapped in a model
  document so later operations apply to it.

## M59. 3D rigging and animation (L; 4 packages) — DONE (0.16.0)

- M59.1 (L) Skeletons from templates (humanoid, quadruped, bird, tail or chain, generic) fitted to a model by its parts
  and landmarks (`rig.create`, `rig.fit`), saved as a glTF skin.
- M59.2 (L) Skin weights: automatic (heat diffusion or voxel binding), rigid per part for robot-style models,
  `skin3d.*` edits and a weight preview.
- M59.3 (L) Clips: the `.anim.json` clips of M42 for 3D bones, 3D IK (two-bone, look-at, foot placement), generators
  (walk and run cycles from stride parameters, idle breathing, swings, hit reactions) and retargeting between template
  skeletons.
- M59.4 (L) Editor: M42's Animation panel and bone tools in 3D (gizmos, IK handles), a filmstrip from several angles;
  docs; an example whose 3D character is made, rigged and animated entirely in the engine.

## M60. A sixth reference game made only with the engine's tools (L) — DONE (0.16.0)

A complete game whose every picture, model, sound and song is made with the commands of M51-M59: no asset provider and
no imported asset. It measures what the AI reaches with these tools against the reference games that used providers,
records every gap in its `ENGINE_FEEDBACK.json`, and a triage milestone turns them into packages, as after M21-M32.

## M61. Roles and AI settings per project (L; 4 packages) — DONE (0.17.0)

Asked by the user: the choice of roles is made for each project, not once for every project, and the same goes for
every other setting that belongs to a project. Today everything the AI settings window edits lives in the user's
`ai.json` (only extensions have a project file, `.factoria/extensions.json`), so turning the artist off for a
small puzzle game turns it off for the 3D game next to it too.

What stays the user's, on purpose: providers (commands, addresses, headers, keys), the definitions of `mcpServers` and
their keys, `defaultProvider`, `inheritUserPlugins`, `~/.factoria/export.json` (SDK paths, keystore passwords), the
editor's layout and recent projects, and `~/.factoria/skills` (projects already have `skills/`). Export and publish
settings are already per project (`factoria.json`).

- M61.1 (M) A project settings file, `<project>/.factoria/ai/settings.json` (inside `.factoria/`, which game projects
  keep out of git: it is this user's choice for this project, not part of the game). It holds `roles` (enabled,
  provider, model, effort, maxTokens, maxContextTokens, toolGroups), `limits`, `assets` (the provider per kind of
  asset, model, voice), `assetSources`, the `savers` switches, and which of the user's `mcpServers` and extensions are
  on for this project. The user's `ai.json` values for the same keys become the defaults every project starts from.
  Resolution, key by key and role by role: engine defaults, then `ai.json`, then the project file. The project file
  may only NAME providers and servers the user's `ai.json` defines: never a command, address, header, environment or
  key, so a copied project cannot run a program or spend a key (the error says which key is not allowed and where it
  belongs). A project file the user did not save on this computer (it came inside a copied or unzipped project) is
  shown and must be accepted once, with the same trust as a project's extensions (`ai-trust.json`). Schema
  `schemas/ai-project-settings.schema.json`; errors name the JSON pointer and the fix. A project without the file
  behaves exactly as today; nothing is rewritten.
- M61.2 (M) Editor: with a project open, the AI settings window and the Roles window edit THAT project (the title says
  "This project: <name>"). Each row says whether its value is the project's or comes from your defaults, with
  **Reset to my defaults** per row and per tab, and **Save as my defaults** writes the current values into `ai.json`
  for new projects. Without a project open the window edits the defaults. Switching project reloads the roles, limits
  and asset settings the next message uses. Autotest section: two projects with different roles; switching shows and
  uses each project's roles.
- M61.3 (S) Commands and CLI: `ai.settings.get {scope: "resolved" | "project" | "user"}` (each resolved value with
  where it came from: `project`, `you`, `default`) and `ai.settings.set {scope, pointer, value}`; `factoria ai run`,
  `ai review` and `ai doctor` resolve the project they run in (`doctor` lists the project's overrides); the MCP
  server a CLI orchestrator (Claude Code, Codex) uses resolves the roles of the project it serves, so `ai_run` and
  `agent_delegate` honour that project's roles that are off.
- M61.4 (S) Feedback sharing per project: `feedback-sharing.json`'s `mode` is the default and a project can set its
  own (`never` for a game under NDA, `always` for one the user wants to share); the editor's consent asks once per
  project when the project's mode is `ask`. Docs: AI_PROVIDERS.md (Config file, Roles, The AI settings window),
  EDITOR.md, ENGINE_FEEDBACK.md; CHANGELOG.

## M62-M64: ideas taken from outside projects (planned 2026-11-05)

From the user's bookmarks (2026-11-05). Rule for these three: an outside project is only a reference for HOW something
is done. FactorIA builds its own version; no code, effect, asset or shader of the outside project is copied or bundled,
and nothing is shipped "in case a game uses it" (a repository can disappear or change its licence). What enters the
engine is a capability that helps make games: commands, a script API, a generator, an AI loop, and a few worked
examples written for the docs. Each milestone names its reference so a worker can read it, not copy it.

## M62. Game feel and effects drawn as code (L; 4 packages) — DONE (0.17.0)

Reference: pixelfx (github.com/patch-gg/pixelfx): every hit is acted (wind-up, freeze on contact, the target rocking
back, recovery), effects take a palette ramp, and its skill draws, renders, looks and refines. Today the engine has no
camera shake, hit-stop or flash: Kindlewatch wrote its own shake (`examples/kindlewatch/scripts/camera.js`).

- M62.1 (M) Game feel API: camera shake (trauma that decays, per camera, seeded by the engine's RNG, 2D and 3D),
  hit-stop (`time.hitStop(seconds, {scale})`: the game freezes or slows for a moment while the UI and audio go on),
  flash (an entity drawn in one colour for a moment, sprites and meshes), knockback (an impulse with a short loss of
  control) and squash and stretch. Script API, commands to try them from the AI, typings. All of them follow
  `game.accessibility.reduceMotion` / `reducedEffects` (docs/MENUS.md). Kindlewatch drops its own shake.
- M62.2 (M) Hits with timing: the clip events of `Animator`, `SpriteAnimator` and the M42 timeline can carry game-feel
  actions (`hitStop`, `shake`, `flash`, `push`, spawn an effect, play a sound), so an attack's anticipation, impact and
  recovery are data the AI writes and tunes, not code spread over behaviours. Check first what the clip events already
  allow and extend them rather than adding a format.
- M62.3 (M) Effects as code with a palette: the code-drawn animations of M41 (`assets.animate_svg`) take a palette ramp
  (dark to bright) so one effect is recoloured without touching its code, a back and a front layer (behind and in
  front of the character) and an additive light pass; the baked sheet keeps its pivot and timing. Check what M41 and
  the indexed images of M53 already give and fill only the gaps.
- M62.4 (S) The AI's loop for effects: the artist's guidance draws a draft, renders a filmstrip at the game's size,
  looks at it and refines (readability at game size, anticipation, impact and recovery, palette), with three or four
  worked examples written by us in docs (an impact, a pickup, a fire loop): no effect library. An example game adopts
  M62.1-M62.3 and records the gaps in its `ENGINE_FEEDBACK.json`.

## M63. Level generation from an example (L; 4 packages) — DONE (0.17.0)

Reference: WaveFunctionCollapse (github.com/mxgmn/WaveFunctionCollapse), a published algorithm: levels that only
contain the NxN patterns of a small example, filled cell by cell from the one with the fewest options. And a puzzle
generator that searches the board to guarantee it can be solved from any start. Today AI_GUIDE.md tells the AI not to
write a level generator script, and there is nothing in its place for roguelikes and replayable levels.

- M63.1 (L) `tilemap.generate {sample, size, seed, model, n, symmetry, periodic}`: FactorIA's own C++ implementation,
  written from the published algorithm. `overlapping` learns the NxN patterns of a sample (a Tilemap or an ASCII level
  of `scene.import_ascii`); `tiled` uses adjacency rules (the tileset's terrain rules of M53.4). Deterministic: the
  same sample and seed give the same level on every platform (engine RNG, no `rand()`). A contradiction restarts up to a
  limit, and the error teaches: where it failed, and what to try (a bigger sample, a smaller `n`, fewer constraints).
- M63.2 (M) Constraints and playability: fixed cells (entrance, exit, borders), required and forbidden tiles, min and
  max counts (chests, enemies), and a check that the level can be played: reachability from start to exit and to every
  required cell with the walkable rules of the Tilemap (`nav.findTilePath`), retried or repaired until it holds; the
  result reports the path length and any unreachable area.
- M63.3 (M) At run time: the same generator from scripts (`tilemap.generate(...)`, a per-run seed from `rng.create`),
  spread over frames within a budget so a phone does not stall; the markers of the sample (spawn points, coins, enemies)
  become entities the way `scene.import_ascii` places them.
- M63.4 (S) Editor and docs: a preview to regenerate with other seeds and keep one; AI_GUIDE.md says when to generate and
  when to write the ASCII level by hand; an example game (a roguelike floor or a replayable puzzle) uses it and
  records the gaps.

## M64. Richer particles, effect documents and a particle editor (L; 4 packages) — DONE (0.17.0)

Reference: effekseer-vfx-skill (a coding agent builds game effects, films them and a second agent grades the
filmstrip). Effekseer itself is not integrated. Today `ParticleEmitter` has one start and one end colour and size, no
curves, no animated textures, no turbulence and no sub-emitters, and the particle editor is still open from M20.

- M64.1 (L) `ParticleEmitter`: colour gradients with several keys, curves over life for size, speed and alpha, flipbook
  textures (a sprite sheet per particle, random start frame), rotation and spin, drag, noise and turbulence, emission
  shapes (point, circle, box, cone, edge, a mesh's surface in 3D), inherited velocity, trails, sub-emitters on birth,
  death and collision, collision with a plane and with a Tilemap, and a pixel mode (positions on the pixel grid,
  colours from the style palette). Seeded and deterministic; the current fields keep their meaning. GL, D3D11, Metal and
  the web.
- M64.2 (M) Effect documents, `*.vfx.json`: several emitters plus a light flash, a shake, a hit-stop and a sound (M62)
  as one effect, played with `vfx.play` and placed like a prefab.
- M64.3 (M) Editor: a Particle panel with a live preview, gradient and curve editors and a time scrubber, over the same
  commands and undo; autotest section.
- M64.4 (M) The review loop: `vfx.filmstrip` (M51) and the art critic grading an effect's filmstrip against a checklist
  (readability, timing, palette, overdraw) with concrete fixes; a budget check (particles alive, overdraw) for phones.
  Docs (ANIMATION.md or a new VFX.md) and an example game that remakes its effects with it.

## M65. Efficiency feedback: how game-making AIs could work cheaper (L; 4 packages) — DONE (0.17.0)

Today ENGINE_FEEDBACK holds what the engine lacks or gets wrong. The AI that makes a game also knows where its own work
went: a system it understood only after forty steps, a doc it read five times, a command it called ten times where one
call with an extra option would do. That is worth reporting too ("with a guide for X, or if Y worked like this, this game
would have taken N fewer steps, M fewer minutes, K fewer tokens"), but only when it is measured and worth its fix. A
report that asks to rebuild a system to save a few minutes or tokens is refused: an engine change goes on the ROADMAP
only when the reports that ask for it add up to thousands of dollars or tens of hours across games.

Rules every package keeps:
- **Measured, not guessed.** The engine computes the numbers from the transcripts (`.factoria/ai/sessions`); the AI points
  at the span where the waste happened. Built-in agent: steps, tokens and cost per step. Claude Code and Codex: steps, tool
  calls and minutes (the `t` and `ms` fields), with tokens estimated from bytes as `ai.session_timeline` does, and said so.
- **The fix is part of the report, and its cost decides.** The cheapest fix that removes the waste wins: a doc section or
  topic guide, then an example, a command option, a new command, and last an engine change.
- **A guide is not free either.** Text loaded on every step (AGENTS.md, the system prompt) costs tokens on every step of
  every run, so a fix of that kind must save more than it adds; most go to on-demand topic guides (skills) instead.
- **Only what helps other games.** A lesson true only for this game is a project fact (`savers.projectFacts`,
  AGENTS.md "Project facts"), not engine feedback. Model choice, effort and limits are the user's settings: the
  retrospective can suggest them to the user (M61), never file them.

- M65.1 (M) The entry kind `efficiency` in `ENGINE_FEEDBACK.json` (schema, `feedback.report`, `feedback add --kind`),
  next to the gap/bug entries and with the same category list. Extra fields: `waste` (what took the time, in engine
  terms), `evidence` (`[{session, fromStep, toStep}]` spans; the engine measures them and stores `measured` {steps,
  toolCalls, minutes, tokens, costUsd, estimated}), `fixType` (doc, guide, example, commandOption, newCommand,
  engineChange), `expectedSaving` (the share of the measured span the fix removes, with one line of why) and
  `appliesTo` (every game, a genre, a feature). The report gate refuses, with a teaching reason: no evidence or a span
  that does not exist; a saving under the threshold of its fix type (one table in ENGINE_FEEDBACK.md: for example a doc
  or guide from 10 minutes or 100k tokens per game where it applies, a command option or command from 30 minutes or 500k
  tokens and `appliesTo` wider than one feature, an engine change from 1 hour or $5 per game and only as a candidate for
  triage); a "missing guide" for a doc that `docs.search` finds with the report's own words (then it is a
  findability report: say which words you searched, and the fix is the doc's title and keywords); and anything on the
  rules above. Deduplication merges efficiency entries by fix, adding the measured numbers. Doctest cases for the gate.
- M65.2 (M) `ai.retrospective {sessions?, since?}`: a mechanical pass over a project's transcripts (no model) that finds
  the usual waste and measures it: the same command failing with the same code, the same doc or file read again and
  again, tool results over a size budget, long edit-run-check loops on one system, many screenshots in a row, long gaps
  waiting on a tool, workarounds already recorded in ENGINE_FEEDBACK. It returns candidates with their numbers and the
  fix type each suggests. The fast role then turns at most three candidates that pass the gate into entries (one short
  call, its cost added to the run and shown); the rest is dropped, and project-only lessons become project-fact
  proposals. It runs on demand (`factoria ai retrospective`, a button in the Feedback panel) and, when the project's
  setting is on (M61, `savers.retrospective`), after a run longer than a threshold (default 150 steps or $3), at most
  once per run and never inside another retrospective. Efficiency entries show their saving in the Feedback panel.
  Autotest section.
- M65.3 (S) The developer side: `share` carries the measured numbers and the fix type (engine terms only, never the
  game's names, as for gaps). `factoria feedback pull` and `collect` rank efficiency entries by the total saving across
  installations (per game times reports) next to their fix cost, with a verdict per entry: "doc now", "command: worth
  it", or "engine change: below threshold (N of the $1000 / 20 hours it needs)" with a ready reason for
  `feedback reject`. An entry fixed in the engine records the version, and the next retrospectives of games that use it
  compare the same pattern before and after, so a fix that saved nothing is visible.
- M65.4 (S) Docs and the loop: ENGINE_FEEDBACK.md "Efficiency feedback" (when to file, the threshold table, three good
  reports and three refused ones: "rewrite the scene format to save 2k tokens", "use a cheaper model", "a guide for X"
  when the guide exists and was found); the rule in AI_GUIDE.md and the AGENTS.md template (one line, the rest on
  demand); AI_COSTS.md links it. Run the retrospective over the transcripts of a reference game built with the engine
  (M60 or a new short one) and file what passes, so the first entries are real.

## M66-M69: ideas from the second look at outside projects (planned 2026-11-06)

References: dsh-game-studio (one sentence to a browser game, a self-playing playtest that reports, art candidates with a
cost card before spending, LAN play by QR, one-file HTML export) and a post about an agent that made hundreds of game
and mockup variants that nobody could review. Their ideas only: nothing of theirs is bundled, and each milestone is
FactorIA's own version over its commands. They start after the M61-M65 block ships.

## M66. Paid asset generation shows its cost and asks first (M; 3 packages) — DONE (0.18.0)

Today asset providers (image, voice, sound, 3D) bill per call and FactorIA does not know their prices
(AI_PROVIDERS.md, "Cost"); `limits.maxCostUsd` covers LLM runs only, so a batch can spend without anyone seeing it.

- M66.1 (S) Prices: `pricing` on asset providers (per image by size and quality, per 1000 characters of voice, per
  second of sound, per 3D model), built-in defaults for the presets with the date they were checked and the pricing
  page, and an `estimatedCostUsd` in every generation result and in the run's cost (said to be an estimate).
- M66.2 (M) Limits and approval: `limits.maxAssetCostUsd` per run and per day (the project's AI settings, M61), checked
  before each call with a teaching error (which limit, how to raise it). A call or batch over the project's
  `askAboveUsd` (default $0.50) waits for the user: in the editor a card with what will be made, how many, the provider
  and the estimate (Approve, Approve all for this run, Cancel); over MCP and the CLI the call returns
  `needsApproval` with the plan, and runs with `approved: true` only after the user said yes. `fake` and local
  providers never ask.
- M66.3 (S) Candidates: `count` on image generation (default 1, at most 4) gives numbered candidates for one slot on one
  contact sheet (M69), and `assets.pick {slot, n}` keeps one and moves the rest to `.factoria/assets/candidates/`
  (cleaned after 7 days). The estimate is for all candidates. Docs (ASSETS.md, AI_COSTS.md), tests with the fake
  provider.

## M67. The AI plays the game and reports, with nobody at the keyboard (L; 4 packages) — DONE (0.18.0)

`play.report` reads what happened while a person played; Lantern Keep and Clockwork Courier carry their own bot
(`tests/helpers/autoplay.js`) for tests only. A game-making AI should be able to play its game end to end and read the
same report before it shows the game to the user.

- M67.1 (M) The bot hook: a game declares how to play itself in `scripts/autoplay.js` (`game.autoplay(fn)`: called
  every step with the state, returns the actions to press), and the templates ship one that finishes their sample
  level. Without a hook, a generic explorer presses the declared input actions in seeded patterns (never random:
  `world.rng`) so a game still gets smoke-played.
- M67.2 (M) `play.auto {scene?, seconds?, seed?, speed?}` runs the game headless at fast speed with the bot and writes a
  session in the same format as an editor session (`.factoria/sessions/`, `"source": "auto"`): perf, spikes, warnings and
  script errors, plus `phases` (the scenes and the game's own `game.phase("boss")` marks, with times), `score` and
  `ended` (won, lost, timed out, stuck: no state change for N seconds) and a screenshot per phase and at the end.
  `play.report` reads it unchanged.
- M67.3 (S) Stuck and broken detection: same position or state for N seconds, an exception loop, falling out of the
  world, a soft lock in a menu; each becomes a mark with a screenshot and the step, and `input.record` keeps the inputs
  so `factoria run --input` replays the problem.
- M67.4 (M) The loop: AI_GUIDE.md and the AGENTS.md template say to run `play.auto` after a feature and before asking
  the user to play; the Play menu gets "Let the AI play" with the report in the Play sessions list; an example game
  (Lantern Keep) swaps its test bot for the hook. Autotest section.

## M68. Try it on the phone: LAN play by QR and a one-file web build (M; 3 packages) — DONE (0.18.0)

Today the web export has to be served by hand (`python -m http.server`, EXPORTING.md) and a phone needs a full Android or
iOS build to try the game.

- M68.1 (M) `project.serve_web {lan?: bool}`: exports the web build in debug mode if it is stale, serves it from a small
  HTTP server inside the editor (localhost by default; on the LAN only when asked, on a random port with a random path
  token, stopped with the editor or `project.serve_web {stop:true}`), and returns the URLs. A changed script or asset
  re-exports and the page reloads.
- M68.2 (S) The editor's "Play on phone" button shows the LAN URL as a QR code drawn by the engine (our own encoder, no
  library download) and says what to check when the phone cannot open it (same Wi-Fi, firewall prompt on Windows and
  macOS, guest networks that isolate devices). Logs and errors from the phone's page come back to the editor console.
- M68.3 (S) `project.export {platform:"web", singleFile:true}`: one HTML file with the player, wasm and `game.pak`
  inlined (base64), that runs offline from a double click; refused with a teaching error over a size limit (default
  64 MB) and when a feature needs a server (threads, which need cross-origin isolation). EXPORTING.md, MOBILE.md.

## M69. Reviewing many variants at once: contact sheets (M; 2 packages) — DONE (0.18.0)

When an AI makes many versions of something (candidates of a sprite, layouts of a menu, seeds of a level, effects,
whole prototypes), looking at them one by one costs the user more than making them did.

- M69.1 (M) `review.sheet {items, columns?, label?}`: one image with numbered thumbnails of scenes, prefabs, images,
  levels (`tilemap.generate` seeds), vector art or effects (the middle frame of `vfx.filmstrip`), each with its label
  and a short line of numbers (size, colours, particles); the result carries the picture so the art critic or the user
  picks by number. `review.pick {sheet, n}` records the choice and drops the rest (asked first in the editor).
- M69.2 (M) Editor: a Review window that shows a sheet big, with keyboard picking (1-9, arrows), a "compare two" view
  and the history of past picks; the asset candidates (M66.3) and the Level generator's seeds open in it. Autotest
  section; docs in EDITOR.md and AI_GUIDE.md ("make N, show one sheet, ask for one number").

## M70-M80: a renderer and runtime for every kind of game (planned 2026-11-06)

The user, 2026-11-06: FactorIA is for 2D and 3D, simple and ambitious, retro and cutting-edge games on PC, consoles,
phones and the web, so it gets everything a leading engine has, not only what a 2D game needs. Today: loading reads a
little every frame on the main thread, the game loop is single-threaded, lighting is in gamma space with no HDR, the
only screen effects are bloom and the colour filter, only the directional light casts shadows (one map, no cascades),
IBL is a procedural sky, custom materials exist for `MeshRenderer` only, there is no LOD, occlusion culling, streaming,
temporal antialiasing, upscaler or ray tracing, and the backends are sokol_gfx's (GL, GLES3, WebGL2, D3D11, Metal).

Rules for all of them:
- Off by default and free when off: a simple or retro game pays nothing (no extra pass, target or memory) for a feature
  it does not use, and its look does not change unless it opts in (linear lighting included: a project setting with a
  migration note, old projects keep gamma).
- Every feature degrades with a teaching message where a backend cannot do it (GLES3/WebGL2 without float targets or
  compute, a GPU without ray tracing), says so in `renderer.supports(feature)` and in the docs table per backend, and
  has goldens per backend in CI.
- Each is a component field or a command with doc strings, in the menu kit's graphics page where a player would set it,
  in the Inspector, and in AI_GUIDE.md with when to use it and what it costs (perf budgets, `perf.measure`).
- Simulation stays deterministic: threads never change results (fixed merge order, `world.rng`).
- Our own implementation; outside SDKs only where a vendor requires its own (M78), fetched at setup like sokol-shdc,
  never committed, with their licenses checked first.

Order: M70 and M71 first; M72 and M73 need M71; M74 needs M72; M75 needs M70; M76 needs M71; M77 stands alone;
M78 needs M76 and M77; M79 needs M73 and M77; M80 needs M71 and M72.

## M70. Loading, threads and fast storage (L; 5 packages) — the user, 2026-11-06

- M70.1 (L) Job system: a fixed pool of worker threads (cores - 1, capped; one on the web without cross-origin
  isolation), jobs with dependencies, a main-thread fallback, profiler lanes per thread, and a debug mode that runs
  every job on the main thread to compare results. Tests for determinism (same frame hash with 1 and N threads).
- M70.2 (L) Parallel engine systems: culling, skinning, particles and vfx, animation sampling, tilemap and mesh
  batching, nav queries, audio mixing and the render command build run as jobs; simulation systems that can split
  (physics broadphase and islands where the backend allows) merge in a fixed order. Perf budgets of the examples prove
  the gain on 4 and 8 cores.
- M70.3 (M) Background loading: an IO thread and decode jobs (PNG, KTX2/Basis, audio, glTF, fonts, scenes), GPU uploads
  budgeted per frame (ms and MB), `scene.preload`/`assets.preload` and `scene.load {async:true}` with progress and
  cancel, and the loading screen of the menu kit fed by real progress. A frame never waits for a file unless asked.
- M70.4 (M) Storage built for SSDs: `game.pak` read with memory mapping (with a read fallback), packed in first-use
  order recorded by `play.auto`/play sessions so a level loads as few big sequential reads, compressed per block
  (LZ4/Zstd, fast decode) with the choice per asset type, and a load-time report (`play.report`: time to first frame,
  per scene, the slowest assets).
- M70.5 (S) Startup: the player shows its first frame before the game's assets are read, shader pipelines compiled in
  the background with a cache on disk (per backend and driver), and a `perf.startup` budget in the templates.

## M71. Linear HDR and a post-processing stack (L; 5 packages) — the user, 2026-11-06

- M71.1 (L) Linear HDR pipeline: `SceneSettings.colorSpace` "gamma" (today) or "linear", float render targets
  (RGBA16F, R11G11B10 where supported, RGBA8 + dithering fallback), sRGB textures marked as such, tonemapping (neutral,
  ACES, AgX, Reinhard, none), exposure (manual and automatic with adaptation speed), and HDR display output where the
  platform allows (Windows HDR10/scRGB, macOS EDR) with paper-white nits. 2D lights and sprites use the same pipeline.
- M71.2 (L) The stack: a `PostProcess` component (on a Camera, or a volume: global, box or circle in 2D/3D with blend
  distance and priority) with ordered effects: colour grading (lift/gamma/gain, white balance, curves, `.cube` LUTs),
  vignette, chromatic aberration, film grain, lens distortion, sharpen, bloom moved into it (lens dirt, threshold
  knee), outline (depth/normal edges, 2D sprite outlines), pixelate and posterize. Effects share passes where they can.
- M71.3 (L) Depth-based effects (3D): SSAO (GTAO quality levels), depth of field (bokeh, near/far, autofocus on a
  target), camera motion blur (from depth; per-object with M76), screen-space reflections, height and distance fog
  moved into the stack, sun shafts.
- M71.4 (M) 2D screen effects: shockwave and heat-haze distortion (screen-space, spawned by `feel`/vfx), radial blur,
  screen flash and fade moved into the stack, split-screen cameras each with their own stack.
- M71.5 (M) Tools: a Post-processing panel with live preview and A/B, `postprocess.*` commands, presets (cinematic,
  stylised, clean, retro hooks for M80), goldens per backend, the cost of each effect in the profiler and in docs.

## M72. Custom shaders for everything (L; 5 packages) — the user, 2026-11-06

SHADERS.md "Not available yet" becomes empty.
- M72.1 (L) Materials for `Sprite`, `Shape2D`, `Tilemap`, `Text`, particles and vfx, trails, the sky and UI images: the
  same snippet model as meshes (`fragment()`, `vertex()`), batching kept for sprites that share a material, per-sprite
  values through instance data.
- M72.2 (M) Post-process materials: a custom pass in the M71 stack (reads colour, depth, normals, previous passes),
  ordered with the built-in effects.
- M72.3 (L) Full shaders and custom lighting: own `main` and vertex layout, several passes, a custom light loop (toon
  ramps, cel bands, hatching), textures in `vertex()`, per-instance values in one instanced draw.
- M72.4 (L) Compute shaders where the backend has them (D3D11, Metal, GL 4.3, Vulkan/D3D12 with M77): GPU particles,
  culling, simulation helpers; a clear refusal on GLES3/WebGL2 with the CPU path named.
- M72.5 (L) A node graph material editor that writes the same JSON/snippet an AI writes (graph and code stay one
  document), with live preview on mesh, sprite and quad, and a library of nodes (noise, dissolve, flow, fresnel,
  triplanar, parallax occlusion).

## M73. 3D lighting of a leading engine (L; 6 packages) — the user, 2026-11-06

- M73.1 (L) Clustered forward lighting: hundreds of lights instead of 32, light cookies, IES profiles, area lights.
- M73.2 (L) Shadows: cascaded shadow maps for the directional light (stable, blended cascades), point (cube) and spot
  shadows in an atlas with a budget, soft shadows (PCF/PCSS), contact shadows, per-light resolution and distance.
- M73.3 (L) Environment: HDRI import, prefiltered environment cubemaps for IBL, reflection probes (baked and realtime,
  box projection, blending), sky models (physical sun and atmosphere, clouds) feeding IBL.
- M73.4 (L) Baked lighting: a deterministic lightmap baker (CPU path tracer, multi-threaded on M70, GPU with M79),
  lightmap UVs generated, light probes for moving objects, mixed lights; bake jobs with progress and cancel.
- M73.5 (M) Volumetrics and decals: volumetric fog and light shafts per light, projected decals (deferred-style on
  forward), screen-space subsurface for skin and wax, and a realtime GI option without ray tracing (probe grid, DDGI-style
  updated over frames).
- M73.6 (M) Materials catch up: clear coat, sheen, transmission, anisotropy, glTF extensions for them, and the
  material inspector showing which ones cost a pass.

## M74. Ambitious 2D lighting and effects (M; 4 packages) — the user, 2026-11-06

- M74.1 (M) Soft 2D shadows (penumbra by light size), shadow casters on sprites and shapes (`ShadowCaster2D` from the
  sprite's alpha or a polygon), self-shadowing off/on, more than 32 shadowed lights with an atlas.
- M74.2 (M) Emission and masks: emissive maps on sprites (feeding HDR bloom), light masks per layer, light cookies, a
  normal map generated from height or from the sprite itself, rim light. The normal map is also an image layer the AI
  and the user can edit (paint, smooth, flip a channel) with the M52 tools, previewed under a moving light.
- M74.3 (L) 2D global illumination: radiance-cascades-style GI (light bounces off coloured walls, emissive sprites
  light the scene), quality levels, off by default.
- M74.4 (M) 2D water and refraction: reflective water planes, refraction and distortion zones through M72 materials,
  shown in an example scene.

## M75. Big worlds: LOD, occlusion, streaming, terrain (L; 6 packages) — the user, 2026-11-06

- M75.1 (L) LOD: automatic mesh simplification on import (our own simplifier, deterministic), LOD groups with screen-size
  thresholds and cross-fade, impostors for far objects, HLOD for cells.
- M75.2 (L) Occlusion culling: a CPU software rasteriser of occluders on the M70 jobs (every backend) and GPU Hi-Z where
  compute exists, portals for interiors; `renderStats` counts what each culled.
- M75.3 (L) World streaming: worlds split into cells (3D scenes and 2D tilemap chunks) loaded and unloaded around the
  camera or chosen anchors on the M70 IO thread, with budgets, priorities and a debug view; an editor workflow to edit
  one big world in cells.
- M75.4 (M) Large coordinates: origin shifting (or double-precision positions) so worlds of hundreds of km keep
  precision in physics and rendering.
- M75.5 (L) Terrain: heightmap terrain with GPU LOD, splat material layers, holes, collision, sculpt and paint tools in
  the editor and as commands, generation from noise and erosion.
- M75.6 (M) Foliage and scattering: GPU-instanced grass, trees and rocks with per-instance data, wind, LOD and culling,
  painted or scattered by rules.

## M76. Temporal antialiasing and open upscalers (L; 4 packages) — the user, 2026-11-06

- M76.1 (L) The temporal base: per-pixel motion vectors (static, moving, skinned meshes, particles, sprites), camera
  jitter, a depth buffer every pass can read, TAA with history rejection, per-object motion blur from M71.3.
- M76.2 (M) Spatial upscaling everywhere: FSR 1 (EASU + RCAS) or our own equivalent on every backend, web and phones
  included, replacing the stretch of `window.renderScale`; integer scaling kept for pixel art (orthoSize 0).
- M76.3 (L) Temporal upscalers: FSR 2/3 upscaling (open source) where compute exists, MetalFX spatial and temporal on
  Apple, with quality modes (Native AA, Quality, Balanced, Performance, Ultra Performance).
- M76.4 (M) Scaling to a budget: dynamic resolution that holds a frame-time target, graphics quality presets (Low to
  Ultra, auto-detected from the GPU and a short benchmark) that every M70-M80 feature reads, and the menu kit graphics
  page with all of it.

## M77. Modern backends: D3D12 and Vulkan (L; 6 packages) — the user, 2026-11-06

sokol_gfx stays for GL, GLES3, WebGL2, D3D11 and Metal; D3D12 and Vulkan are our own backends behind the same render
interface (external/ is not edited). They are the base of M78, M79, DirectStorage and the Xbox seam of M23.
- M77.1 (L) The render interface split so a second backend family fits (resources, pipelines, passes, barriers).
- M77.2 (L) D3D12 backend: descriptor heaps, pipeline state cache on disk, upload rings, resource barriers, debug layer
  in tests, WARP for CI.
- M77.3 (L) Vulkan backend: Windows, Linux and Android, validation layers in tests, lavapipe for CI, pipeline cache.
- M77.4 (M) Shaders: the shader tool emits DXIL and SPIR-V (with the M72 snippets), reflection kept for the material
  inspector.
- M77.5 (M) Async compute and multi-threaded command recording on the M70 jobs, bindless where supported.
- M77.6 (M) DirectStorage on Windows (GPU decompression of `game.pak` blocks) behind the M70 storage layer, and a
  backend choice in `project.json` and the launcher with automatic fallback.

## M78. Vendor upscalers, frame generation and latency (M; 4 packages) — the user, 2026-11-06

- M78.1 (S) Licences and setup: NVIDIA DLSS/Streamline, Intel XeSS, AMD FidelityFX terms checked; the SDK binaries are
  fetched by `factoria setup` on demand and shipped with exported games when used, never committed.
- M78.2 (M) DLSS Super Resolution and Ray Reconstruction (D3D12/Vulkan, D3D11 where the SDK allows), XeSS Super
  Resolution (every GPU, D3D11/D3D12/Vulkan), behind the M76 quality modes with automatic choice by GPU.
- M78.3 (M) Frame generation: DLSS Frame Generation, FSR 3 frame generation, XeSS frame generation, with UI drawn
  without artefacts and a refusal under the minimum base frame rate.
- M78.4 (S) Latency: NVIDIA Reflex, AMD Anti-Lag 2, Intel XeLL, a latency readout in the profiler.

## M79. Ray tracing (L; 5 packages) — the user, 2026-11-06

- M79.1 (L) Acceleration structures: BLAS/TLAS for meshes (skinned refit, instances), on DXR (D3D12), Vulkan RT and
  Metal RT, with `renderer.supports("raytracing")`.
- M79.2 (L) Ray-traced shadows (soft, area lights) and ambient occlusion.
- M79.3 (L) Ray-traced reflections and translucency, falling back to M71.3/M73.3 per pixel.
- M79.4 (L) Ray-traced global illumination (probes updated by rays, then per-pixel with denoising; DLSS Ray
  Reconstruction from M78 when present).
- M79.5 (M) A path-traced reference mode for screenshots, store art and checking the raster look, and GPU baking for
  M73.4 lightmaps.

## M80. Retro looks done right (M; 4 packages) — the user, 2026-11-06

- M80.1 (M) Low-resolution rendering: render at a console-like resolution (320x240, 256x224...) with integer or
  aspect-correct scaling and a sharp-bilinear option, for 2D and 3D.
- M80.2 (M) Palettes and dithering: palette quantization (built-in palettes and `.pal`/`.gpl`/image import), ordered and
  error-diffusion dithering, colour limits per sprite, 1-bit and 4-colour handheld presets. Also blue-noise dithering
  (our own generated blue-noise texture, void-and-cluster, no shipped file), at runtime and as a `blueNoise` method of
  the image tools' `dither` (today bayer2/4/8, floydSteinberg, atkinson).
- M80.3 (M) Screens: CRT (scanlines, shadow mask, curvature, bloom, phosphor persistence), NTSC/PAL composite artefacts,
  LCD grid, VHS.
- M80.4 (M) Retro 3D: vertex snapping, affine texture mapping, no filtering, low colour depth, draw distance fog, per
  material or for the whole game; a retro template for 2D and one for 3D that use these presets.

## M81. Cleaner art from rough sources (M; 4 packages) — the user, 2026-11-07

From the user's X bookmarks (pixel-art grid detectors, video-to-sprite tools, parametric model kits). Ideas only: each
is FactorIA's own command, nothing of those projects is bundled, depended on or wrapped as a provider. Checked against
the roadmap and docs first: none of these is done or planned.
- M81.1 (M) Automatic pixel grid: `image.to_pixel_art {pixelSize: "auto"}` finds the art-pixel size and offset of an
  upscaled or AI-made "fake pixel art" image (edge spacing and colour runs per axis), reports the grid it found with
  its confidence, and snaps to it; `image.detect_pixel_grid` returns the grid alone. Today `pixelSize` is given by hand.
- M81.2 (M) Video to sprite sheet: `image.sheet_from_video {path, fps?, from?, to?, crop?, background?}` takes the
  frames of an imported video (the same decoders as video import), drops near-duplicates, keys out a plain background
  and bakes a sheet with its animation clip, so a filmed or generated clip becomes a game animation.
- M81.3 (S) Remove a fringe or a background: `image.clean_edges` removes the halo `assets.check_art` reports (dark or
  light fringe around the alpha edge, matte decontamination) and `image.remove_background` keys out a flat or
  near-flat background colour; both as M52 layer operations, and as a fix `assets.check_art` offers.
- M81.4 (M) Parametric kits and variants: a model document declares shared top-level knobs (size, roof pitch, wear,
  palette...) that drive its nodes' params, and `model.variants {path, count, vary?, seed}` makes a set of seeded
  variants; with M69 contact sheets to review them and a pick that saves the chosen ones as assets.

## M82. Secondary motion and more generated animation (L; 3 packages) — the user, 2026-11-08

From the user's X bookmarks (TailorRig and HairDeck for clothing and hair bones, UniMate and Prompt2Rig for motion from
a description, DirtyMoCap and a mocap clean-up app). Those are trained models; ours are procedural and live in the
engine, nothing of theirs is bundled, depended on or wrapped. Checked against the roadmap and docs first: rigs today
have only the body (plus `tail`/`chain` templates for whole models), `anim3d.generate` makes 7 kinds, and nothing
cleans an imported clip.
- M82.1 (L) Secondary chains and spring bones: `rig.add_chain {rig, part, from, segments}` adds bone chains for hair,
  capes, skirts, sleeves and ears to a fitted rig, with skin weights kept on their part (they do not leak into the legs
  or the body); a `SpringBones` component (3D, and the same for `Bone2D` chains) moves them at runtime with stiffness,
  damping, gravity and collider spheres, deterministic on the fixed step; the Animation panel shows them, and
  `anim3d.preview` can draw them settling.
- M82.2 (M) More generated actions: `anim3d.generate` kinds `jump`, `attack`, `wave`, `crouch`, `death`, `climb`,
  `sit`, `fall`, `turn` and `push`, from the rig's proportions with IK for contacts and the same `params` and
  `generated` record as today; for the humanoid, quadruped and bird templates where each makes sense (a teaching error
  otherwise).
- M82.3 (M) Clean an imported clip: `anim3d.clean {path, rig, out?}` filters jitter, finds the foot contacts and locks
  them (no foot skating), keeps the root over the feet, reduces keys within an error budget and reports what it changed
  with a before/after filmstrip; `anim.check` gains a `foot_skate` finding that suggests it.
