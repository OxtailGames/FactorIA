# Engine feedback report

Status: 73 entries reported by the four example games, all 73 verified fixed-in-engine (M6 closed the last 10). No entry is open and every milestone (M1-M6) is done; M5 closed the proactive 3D-physics and gamepad gaps.
Regenerate the ranked list with `factoria feedback collect examples/sky-hopper examples/neon-swarm examples/gem-roller examples/block-push --out feedback/ROADMAP.md` (then re-add the milestones section).

0 entries from 4 project(s), 0 distinct gap(s). Ranked by total occurrences x severity weight (blocker 8, major 4, minor 2, nice-to-have 1).

_No open feedback entries._

# Next engine milestones

Hand-written triage section (the ranked list above is generated; regenerate it with the command in
`feedback/README.md` and keep this section). Triage date 2026-10-13, against commit `e2b0090`: of the 55
entries from the four example games, the engine already fixed most; the work packages below cover what is left,
plus two packages for gaps seen while verifying that no game has hit yet (marked *proactive*).

Re-triage 2026-10-13, after `40b049c`: the last three open entries are fixed (SH/FB-0015 in `ebb054d`,
SH/FB-0014 in `ae8bb15`, NS/FB-0008 in `40b049c`). M1-M4 are done; M5 is the only package left and no game has
reported its gaps yet.

Re-triage 2026-10-13, after `99eebad`: the four examples were migrated off their workarounds (Neon Swarm `804c00d`,
Sky Hopper `9dc7fd5`, Block Push `53fab56`, Gem Roller `99eebad`; each removed workaround has a note on its entry).
The migrations found 18 new gaps: 8 were fixed right away (NS/FB-0011..0014 in `f649d8d`/`afbd0e9`, SH/FB-0017..0020
in `cc789f7`) and 10 are open, grouped in M6 below.

Re-triage 2026-10-14, after M6 (`303db3e`, `6e5b5b2`, `2ff6faa`): the 10 open entries are fixed and each has a
`Fixed in <commit>` note; the three that had a workaround in an example (BP/FB-0019, BP/FB-0020, SH/FB-0021) had it
removed in the same commit. No entry is open.

Re-triage 2026-10-14, after M5 (`d5ad914`, `c3b6073`, `022659c`; merges `bdff25f`, `fa07209`, `5c2296e`): the
proactive package is done, so no milestone is left. What is still open is listed under "Found while implementing" in
M5 and M6; no game has hit any of it yet.

Sizes: S = under a day for an AI agent, M = 1-3 days, L = a week or more. Ids are `<game>/FB-n`
(sky-hopper = SH, neon-swarm = NS, gem-roller = GR, block-push = BP).

## M1. Docs and templates match the engine (S, highest value per effort) — DONE in this release

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

## M2. CLI and test-harness diagnostics (S) — DONE in this release

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
  Done in `ebb054d` (plus the `audio.log` command for MCP/CLI agents; Sky Hopper's tests assert its sounds).

## M3. 2D level authoring and cameras (M) — DONE (`ae8bb15`)

Closes: SH/FB-0004, SH/FB-0014 (and removes the hand-made Python/JS level builders in sky-hopper).

Acceptance criteria:
- New `CameraFollow2D` behaviour/component (target id, offset, damping, `bounds` rect, clamps against the
  real view size, correct after a window resize); test: camera never shows outside `bounds` for 600 frames of
  a target running past the edge, in 1280x720 and 800x600.
- Tilemap object layer: `Tilemap.objects` (or `tilemap.paint` / `scene.import_ascii` commands) maps glyphs or
  tile ids to prefabs with position and props; `scene.import_ascii {rows, legend}` creates a Tilemap plus the
  spawned entities; round-trips through scene JSON. Test: a 10x6 ASCII level yields the expected tile ids,
  3 coins, 1 player spawn; `factoria validate` checks the legend.

Outcome: the object layer shipped as the `scene.import_ascii` command (rows + legend -> Tilemap + prefabs at cell
centres, tagged `tilemap:<entity>` so re-imports replace them; `save` writes the scene). The legend is not stored
in the scene, so `factoria validate` checks the Tilemap data instead (tiles vs width*height, rows, solidTiles,
tile indices vs the tileset image); the command itself rejects bad legends with row/column and suggestions.
`CameraFollow2D` was not built: SH/FB-0004 was closed by the AI_GUIDE 9.6 "Camera follow with level bounds" recipe.

## M4. Post-processing and glow (M) — DONE (`40b049c`)

Closes: NS/FB-0008 (additive blend already shipped in e2b0090; this is the bloom half).

Acceptance criteria:
- `Camera.bloom` `{ enabled, threshold, intensity, radius }` (default off, deterministic in headless).
- Test: a bright additive Shape2D on a dark background yields lit pixels outside its rectangle when bloom is on
  and none when off (`factoria run --headless --screenshot-at`, compare against pixel counts); cost under
  2 ms/frame at 1280x720 on llvmpipe.
- Documented in COMPONENTS.md and AI_GUIDE (neon recipe: additive + bloom, no hand-blurred sprites).

Outcome: flat fields `Camera.bloom`, `bloomThreshold`, `bloomIntensity`, `bloomRadius` (reflection has no nested
structs); AI_GUIDE 9.20. The cost target was missed: about 5 ms per drawn frame at 1280x720 on llvmpipe, because
the bright-pass read and the full-screen add are each ~1.5-2 ms on the software renderer. Headless tests only
draw for screenshots, so they do not pay it. Only the GL backend was run; D3D11, Metal and GLES3 compile the same
sokol-shdc shaders and fall back to "no bloom" with one error if creation fails.

## M5. 3D physics 2.0 and gamepad input (L, *proactive*, no game reported these yet) — DONE (`d5ad914`, `c3b6073`, `022659c`)

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

Outcome: three packages, one per commit. 3D physics (`d5ad914`): `Collider3D` boxes follow the entity's world rotation
(sphere vs box in the box frame, box vs box by 15-axis SAT; raycasts, overlaps, riders, events and debug output use the
oriented shape; unrotated boxes keep the exact axis-aligned paths); continuous collision is automatic (a dynamic body
moving more than half its smallest extent in a sub-step is swept against static and kinematic colliders; the test fires
900 spheres at 60 m/s through a 0.2 m wall); `RigidBody3D.rollingFriction` (default 0.02) replaces sliding friction for
spheres with `rollWithMotion`; `shape_cast3d`. Shape casts (`c3b6073`): `shape_cast2d` on Box2D's `b2World_CastShape`
(stops on the surface; a resting contact blocks only a cast moving towards it, as in 3D since the merge), one JSON
parser for `physics.shapeCast(shape, from, to, opts)` in scripts and the `physics.shape_cast` command. Gamepads
(`022659c`): the binding names keep the spelling reserved since 0.1 (`GamepadA`, `GamepadDpadLeft`,
`GamepadLeftStickLeft/Right/Up/Down`, `GamepadRightStick*`, `GamepadLeftTrigger`...), not `Gamepad:A`; a binding matches
any of 4 pads; `input.value(action)` is analog (max over bindings, radial deadzone from `input.deadzone`, default 0.2),
`axis()`/`vector()` use it and an action is down at 0.5; `input.gamepad(i)`; `game.gamepad(i).press/release/tap/axis`
in tests; replay frames and `game.input` take `gamepad` and `touch` (the M6 leftover). Device backends: XInput on Windows
(run here), the Linux joystick API (xpad layout) and Apple's GameController framework, both written without a machine
to run them on (CI compiles them); Android and web report no pads.

Found while implementing M5, not fixed (no game has hit them; record an ENGINE_FEEDBACK entry when one does):
- 3D bodies get no torque from collisions and have no inertia tensor: a box never tips over by itself.
- Continuous collision does not sweep dynamic-vs-dynamic pairs or kinematic motion within a sub-step, and drops the
  rest of a sub-step's movement after an impact.
- Linux pads with a non-Xbox layout (PlayStation, Switch, generic HID) map to the wrong buttons; Android and web have
  no gamepad backend.
- After focus loss a Linux pad shows as disconnected until it sends its next event (the joystick API only reports
  changes).
- The `physics.raycast` command takes no `ignore`/`ignoreTriggers`, unlike `physics.shape_cast` and the script API.

## M6. Polish found while migrating the examples (S-M) — DONE (`303db3e`, `6e5b5b2`, `2ff6faa`)

Closes: BP/FB-0019 (fa.call drops ToolError data), BP/FB-0020 (game.touch vs mouse), BP/FB-0021 (JSON import errors
without position), NS/FB-0015 (screen-space particles), NS/FB-0016 (triangle outline), NS/FB-0017 (polygon/star),
NS/FB-0018 (validate and non-canonical files), SH/FB-0021 (file-targeted component edits), SH/FB-0022 (atomic writes),
SH/FB-0023 (texture size query).

Acceptance criteria:
- `fa.call` of a tool that throws `ToolError(msg, hint, data)` throws an Error with `e.data` equal to `data`
  (script test), and Block Push's check_levels test asserts on the report.
- In tests, the first touch also moves the mouse and presses mouse-left, as on a device (or the difference is
  documented in SCRIPTING.md and AI_GUIDE section 10); a test taps to continue through the mouse branch.
- `factoria validate` reports a broken imported `.json` once, as `file:line:column`, with no cascading warnings.
- `ParticleEmitter.space` ("world" | "screen"); screen-space particles are drawn in the HUD pass when
  `bloomScreenSpace` is false.
- Triangle outlines grow inward like the other shapes (goldens regenerated and reviewed).
- `Shape2D` `polygon` (sides) and `star` (points, inner radius) shapes with pixel tests.
- `scene.format {check:true}` can fail (non-zero exit / ToolError) when files are not canonical, and
  `project.validate` warns about them.
- `scene.import_ascii` (or a new `scene.set_component {path}`) can patch components of the scene file it writes;
  Sky Hopper's generator drops its scratch base copy.
- Scene/prefab/JSON files are written to a temporary file and renamed over the target.
- A script can read a texture's pixel size (e.g. `assets.textureSize(path)`), and `entity.bounds()` uses it.

Outcome: three packages, one per commit. Scripting and input (`303db3e`): `fa.call` sets `e.data`; the first finger
drives the mouse inside `fa::Input`, so a device, `game.touch` and any other feed behave the same; `assets.textureSize`.
Files and tooling (`6e5b5b2`): `fs::write_bytes` writes a temporary file and renames it over the target, and the
tooling writer behind `fs.write`, scaffold and export now goes through it; the JSON module loader and validate report a
broken imported `.json` once as `file:line:column`; `scene.format` takes `strict` (with `check`: error `not_canonical`)
and `project.validate` warns per non-canonical scene/prefab through the shared `canonical_scene_layout`; the file-edit
API is an `edits` argument on `scene.import_ascii` (file mode only), applied with the `scene.set_component` code.
2D rendering (`2ff6faa`): one inward, mitred outline for triangle, diamond, polygon and star; `Shape2D` `polygon`
(`sides`) and `star` (`points`, `innerRadius`); `ParticleEmitter.space` + `anchor`. The `2d_shapes` and `2d_bloom`
goldens were regenerated and `2d_polygons` added on Windows (D3D11/WARP), not on Mesa llvmpipe: the first Linux CI run
confirms they stay within tolerance there.

Found while implementing M6, not fixed (no game has hit them; record an ENGINE_FEEDBACK entry when one does):
- ~~`--input` replay files have no touch events (only `press`, `release`, `keys`, `mouse`), so a replay cannot tap.~~
  Done in M5 (`022659c`): replay frames take `touch` (and `gamepad`).
- The scene loader does not enforce reflected `range()`: `"sides": 200` loads silently (the renderer clamps it to 64).
- `edits`, like `scene.set_component`, replaces `Script.props` as a whole; Sky Hopper's generator still reads the base
  scene once to keep `killY`. A merge mode would remove that read.
- `project.validate` checks the canonical layout only under `scenes/` and `prefabs/`; a scene kept elsewhere (Sky
  Hopper's `levels/generator_base.scene.json`) is covered by `scene.format {check, strict}` only.

## Found and fixed while migrating the templates — DONE (`20e1e34`, `cc14514`)

The templates have no ENGINE_FEEDBACK.json, so these three gaps are recorded here instead of as feedback entries.

- A dynamic `RigidBody2D` that fell asleep did not wake when a script wrote `Transform.position` or `rotation`: it
  hovered at the new place and `isGrounded()` kept the old ground. A teleport now wakes the body and every body
  touching it (moved platforms and tilemaps too). The collider hash also stopped rebuilding rotating bodies every few
  steps (float noise in the world scale), so resting bodies fall asleep and stop emitting contact events. (`cc14514`)
- The template tests skipped their level checks on hosts without `scene.import_ascii`. `fa_test_cli` now runs every
  template's tests on the engine `factoria test` builds, and the skip guard is gone. (`20e1e34`)
- Saved scenes showed `"settings": {}` and hid the default gravity. The writer now always emits `gravity2D` and
  `gravity3D`; committed scenes were regenerated with engine commands. (`20e1e34`)
