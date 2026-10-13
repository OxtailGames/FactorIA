# Engine feedback report

16 entries from 4 project(s), 14 distinct gap(s). Ranked by total occurrences x severity weight (blocker 8, major 4, minor 2, nice-to-have 1).

## 1. Docs mark working CLI commands as planned

- **Category:** docs
- **Severity:** minor (score 6)
- **Total occurrences:** 3
- **Projects affected:** Block Push, Gem Roller, Neon Swarm
- **Entries:** Neon Swarm/FB-0002, Gem Roller/FB-0002, Block Push/FB-0001
- **Suggestion:** Remove the (planned) labels for commands that ship, keep them only for real gaps, and add a short list of which commands work from the CLI.
- **Workarounds seen:**
  - Tried the commands anyway.
  - Tried each command anyway; all worked.
  - Ran the CLI commands directly, checked each with --help and its output, and ignored the (planned) labels.

## 2. EXTENDING.md marks project tools and factoria call as planned

- **Category:** docs
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Block Push
- **Entries:** Block Push/FB-0017
- **Suggestion:** Update EXTENDING.md and every (planned) label to match the build. Add a docs check that fails when a command documented as planned already runs.
- **Workarounds seen:**
  - Used project tools and factoria call anyway, after confirming them with factoria commands and a test run.

## 3. No 3D gameplay recipes in the AI guide

- **Category:** docs
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Gem Roller
- **Entries:** Gem Roller/FB-0010
- **Suggestion:** Add 3D recipes: chase camera, camera-relative movement, ground check, trigger pickups, moving platforms, and a note on which components a 3D trigger needs.
- **Workarounds seen:**
  - Experimented with probe tests (tests/gem_roller.test.js covers the results).

## 4. Project tools cannot fail a check and still return a report

- **Category:** tooling
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Block Push
- **Entries:** Block Push/FB-0018
- **Suggestion:** Let a tool return a result with ok: false that makes factoria call exit 1 while still printing the result. Or let it throw an error that carries both a result and a hint. Document which one a check tool should use.
- **Workarounds seen:**
  - Kept returning the full report with ok: false and exit 0, so CI would have to parse the JSON. The throw path was tested in a scratch copy only.

## 5. Replay input format and console.log in tests undocumented

- **Category:** docs
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Neon Swarm
- **Entries:** Neon Swarm/FB-0010
- **Suggestion:** Document mouse/key entries in replay files, warn on unknown replay keys, and show test console output in the report.
- **Workarounds seen:**
  - Guessed the game.input shape; used --log-level info.

## 6. Screen-space Text pivot confusing and template HUD text is clipped

- **Category:** docs
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Neon Swarm
- **Entries:** Neon Swarm/FB-0004
- **Suggestion:** Fix the template and 9.4 example, or document that pivot y=1 means top even in +Y-down screen space; add an anchor option (top-left/top-right) to screen-space UI.
- **Workarounds seen:**
  - Used pivot [0,1] (left) and [1,1] (right).

## 7. Template docs contradict: AGENTS.md says 2D origin is screen centre, camera needs manual placement for tilemap levels

- **Category:** docs
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Sky Hopper
- **Entries:** Sky Hopper/FB-0004
- **Suggestion:** Add CameraFollow2D component or camera.viewSize / game.screenSize-based bounds clamp helper; document.
- **Workarounds seen:**
  - scripts/follow_camera.js with minX/maxX/minY/maxY props and hardcoded 1280x720 view.

## 8. Tilemap collision details undocumented (ghost edges, solid tile index semantics, trigger vs tile)

- **Category:** docs
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Sky Hopper
- **Entries:** Sky Hopper/FB-0016
- **Suggestion:** Document how Tilemap collision is generated.
- **Workarounds seen:**
  - Used friction 0 on characters; no issues seen in tests.

## 9. Tilemap has no per-tile entity hooks (coins/enemies/spawn must be separate entities)

- **Category:** scene
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Sky Hopper
- **Entries:** Sky Hopper/FB-0014
- **Suggestion:** Tilemap object layer or 'scene.import_ascii' / 'tilemap.paint' commands; tile-to-prefab mapping.
- **Workarounds seen:**
  - Scene generation scripts (scratch + tools/generate_level.js).

## 10. TouchInfo.pressed is undocumented

- **Category:** docs
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Block Push
- **Entries:** Block Push/FB-0013
- **Suggestion:** Document each TouchInfo field, for example: pressed is true only on the frame the touch starts. Add a held or down field for a touch that is still in contact.
- **Workarounds seen:**
  - Assumed pressed means the touch started this frame, and reacted only to that.

## 11. getting-started is in Spanish and marks working features as in development

- **Category:** docs
- **Severity:** minor (score 2)
- **Total occurrences:** 1
- **Projects affected:** Block Push
- **Entries:** Block Push/FB-0002
- **Suggestion:** Publish getting-started in English (or add an English version), and update its status table to match the CLI that ships.
- **Workarounds seen:**
  - Read AI_GUIDE.md, CLI.md and SCRIPTING.md instead, and trusted each command's --help over the status table.

## 12. No additive blend mode / glow for neon looks

- **Category:** rendering-2d
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Neon Swarm
- **Entries:** Neon Swarm/FB-0008
- **Suggestion:** Add blendMode (alpha|additive) on Sprite/ParticleEmitter/Shape2D and a simple bloom camera option.
- **Workarounds seen:**
  - Generated blurred white glow PNGs (assets/img/glow_*.png) tinted via Sprite.color.

## 13. No way to verify audio events in tests

- **Category:** audio
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Sky Hopper
- **Entries:** Sky Hopper/FB-0015
- **Suggestion:** Add game.audioLog() / expect(audio).toHavePlayed(path) in tests.
- **Workarounds seen:**
  - Checked --record-audio output non-empty; no assertion in tests.

## 14. Shape2D anchor not documented

- **Category:** docs
- **Severity:** nice-to-have (score 1)
- **Total occurrences:** 1
- **Projects affected:** Block Push
- **Entries:** Block Push/FB-0015
- **Suggestion:** State in COMPONENTS.md that rectangles and circles are centred on the entity position, or add a pivot field to Shape2D.
- **Workarounds seen:**
  - Placed panels by measuring screenshots.


---

# Next engine milestones

Hand-written triage section (the ranked list above is generated; regenerate it with the command in
`feedback/README.md` and keep this section). Triage date 2026-10-13, against commit `e2b0090`: of the 55
entries from the four example games, the engine already fixed most; the work packages below cover what is left,
plus two packages for gaps seen while verifying that no game has hit yet (marked *proactive*).

Sizes: S = under a day for an AI agent, M = 1-3 days, L = a week or more. Ids are `<game>/FB-n`
(sky-hopper = SH, neon-swarm = NS, gem-roller = GR, block-push = BP).

## M1. Docs and templates match the engine (S, highest value per effort)

Closes: NS/FB-0002, GR/FB-0002, BP/FB-0001 (AI_GUIDE "planned" markers), BP/FB-0017 (EXTENDING "planned"),
BP/FB-0002 (GETTING_STARTED in Spanish, stale status table), BP/FB-0013 (TouchInfo fields), BP/FB-0015
(Shape2D pivot/anchor in COMPONENTS.md), NS/FB-0004 (2d-empty template and AI_GUIDE 9.4 use a clipped
`pivot [0,0]` HUD text), SH/FB-0016 (tilemap collision rules), GR/FB-0010 (3D recipes), NS/FB-0010 (replay
format). Only the entries whose text is still missing from `docs/*.md` stay open; see each entry's notes.

Acceptance criteria:
- `grep -n "(planned)" docs/*.md` lists only commands that really do not exist (check each with
  `factoria commands` / `--help`); a docs test fails when a command documented as planned runs.
- `docs/GETTING_STARTED.md` (or an English twin) is English and its status table matches the shipped CLI.
- Templates `2d-empty` and AI_GUIDE 9.4 use a HUD that is not clipped (test: screenshot of the template at
  frame 3 has text pixels in rows 0..60 and none missing at the top; use `anchor [0,0]` + `pivot [0,1]`).
- AI_GUIDE has a "3D recipes" section with: chase camera, camera-relative movement, ground check, trigger
  pickup (state which components a 3D trigger needs), moving platform; every code block runs in a test.
- `docs/COMPONENTS.md` is regenerated from `factoria api --md` and shows `pivot`, `anchor`, `blend`,
  `autoDestroy`, `oneWay`, `rollWithMotion`; TouchInfo fields are commented in the typings.

## M2. CLI and test-harness diagnostics (S)

Closes: BP/FB-0018, NS/FB-0010 (code part), SH/FB-0015.

Acceptance criteria:
- `factoria call project.<tool>` for a tool that throws `ToolError(msg, hint, data)` exits 1 and prints
  `data` (JSON) on stderr or stdout, same content as `call --batch` (test in `tools/cli/tests/integration.py`).
  The docs say clearly that only `ToolError` fails a call (a returned `{ok:false}` exits 0), or `{ok:false}`
  is made to exit 1 as well.
- `--input replay.json` and `game.input` warn (and `factoria run` exits non-zero with `--strict`) on unknown keys
  such as `"bogus"` or a misspelt `"press"`; the warning names the frame and key.
- `factoria test` prints `console.log` from tests under the failing/passing test without `--log-level info`.
- Test harness exposes `game.audioLog()` (list of `{frame, path, volume, bus}`) and
  `expect(game.audioLog()).toContainPlayed(path)`; a test plays a sound from a behaviour and asserts it.

## M3. 2D level authoring and cameras (M)

Closes: SH/FB-0004, SH/FB-0014 (and removes the hand-made Python/JS level builders in sky-hopper).

Acceptance criteria:
- New `CameraFollow2D` behaviour/component (target id, offset, damping, `bounds` rect, clamps against the
  real view size, correct after a window resize); test: camera never shows outside `bounds` for 600 frames of
  a target running past the edge, in 1280x720 and 800x600.
- Tilemap object layer: `Tilemap.objects` (or `tilemap.paint` / `scene.import_ascii` commands) maps glyphs or
  tile ids to prefabs with position and props; `scene.import_ascii {rows, legend}` creates a Tilemap plus the
  spawned entities; round-trips through scene JSON. Test: a 10x6 ASCII level yields the expected tile ids,
  3 coins, 1 player spawn; `factoria validate` checks the legend.

## M4. Post-processing and glow (M)

Closes: NS/FB-0008 (additive blend already shipped in e2b0090; this is the bloom half).

Acceptance criteria:
- `Camera.bloom` `{ enabled, threshold, intensity, radius }` (default off, deterministic in headless).
- Test: a bright additive Shape2D on a dark background yields lit pixels outside its rectangle when bloom is on
  and none when off (`factoria run --headless --screenshot-at`, compare against pixel counts); cost under
  2 ms/frame at 1280x720 on llvmpipe.
- Documented in COMPONENTS.md and AI_GUIDE (neon recipe: additive + bloom, no hand-blurred sprites).

## M5. 3D physics 2.0 and gamepad input (L, *proactive*, no game reported these yet)

Found while verifying GR/FB-0003/0005: rotation is visual only (colliders are axis-aligned), friction decelerates
a rolling sphere like a sliding one (a ball launched at 3 m/s with friction 0.5 is stopped within 1 s), there is
no shape-cast, fast bodies tunnel (`AI_GUIDE` says so), and gamepad bindings are "reserved, not supported".
Create entries in `ENGINE_FEEDBACK.json` when a game hits them; the package is planned from the physics header.

Acceptance criteria:
- `Collider3D` honours `Transform.rotation` for boxes (oriented box vs sphere/box); a box rotated 45 deg blocks a
  sphere at the rotated edge, not the AABB corner.
- Continuous collision (`RigidBody3D.bullet` or automatic for speeds above one body size per step): a 60 m/s
  sphere never passes a 0.2 m wall in 600 trials.
- Rolling resistance: a sphere with `rollWithMotion` on friction 0.5 keeps rolling (its speed decays by
  `rollingFriction` only); test the distance travelled before stopping.
- `physics.shapeCast(shape, from, to, opts)` for 2D and 3D, honouring `ignore`/`mask`.
- Gamepad: `input.actions` bindings `"Gamepad:A"`, `"Gamepad:LeftStickX"` (+/-), `axis()` and `vector()` work;
  `game.gamepad(index).press/axis(...)` in tests; replay JSON accepts the same.
