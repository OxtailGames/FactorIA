# Finished engine milestones

What each finished milestone of [ROADMAP.md](ROADMAP.md) built, and what was found and fixed on the way. What they
left open, and the decisions later work has to respect, stay in ROADMAP.md.

## Earlier re-triages

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

Re-triage 2026-10-14, after M7 (merges `6b9b85d`, `46d12bb`, `79d6f1e`, `2eadd1e`): every item of the M5 and M6
"Found while implementing" lists is done (each is struck through with its commit), and CI now runs the mobile players
on a simulator and an emulator. What M7 left open is listed under "Found while implementing M7".

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
- ~~3D bodies get no torque from collisions and have no inertia tensor: a box never tips over by itself.~~ Done in M7
  (`e37aebe`): dynamic boxes are rigid bodies; `RigidBody3D.lockRotation` keeps one upright.
- ~~Continuous collision does not sweep dynamic-vs-dynamic pairs or kinematic motion within a sub-step, and drops the
  rest of a sub-step's movement after an impact.~~ Done in M7 (`e37aebe`).
- ~~Linux pads with a non-Xbox layout (PlayStation, Switch, generic HID) map to the wrong buttons; Android and web have
  no gamepad backend.~~ Done in M7 (`3e1f4d8`) for Linux (SDL GameControllerDB mappings) and Android; web has no build.
- ~~After focus loss a Linux pad shows as disconnected until it sends its next event (the joystick API only reports
  changes).~~ Done in M7 (`3e1f4d8`).
- ~~The `physics.raycast` command takes no `ignore`/`ignoreTriggers`, unlike `physics.shape_cast` and the script API.~~
  Done in M7 (`a90dee2`).

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
- ~~The scene loader does not enforce reflected `range()`: `"sides": 200` loads silently (the renderer clamps it to 64).~~
  Wrong: the loader already refused it. M7 made the error teach (range and nearest value, `c604211`), made
  `project.validate` load prefab files on their own (a bad prefab no scene placed passed), and made script writes
  throw the same error (`233939d`).
- ~~`edits`, like `scene.set_component`, replaces `Script.props` as a whole; Sky Hopper's generator still reads the base
  scene once to keep `killY`. A merge mode would remove that read.~~ Done in M7 (`a90dee2`): `merge: true` /
  `"$merge": true` (RFC 7386); the generator no longer reads the base scene.
- ~~`project.validate` checks the canonical layout only under `scenes/` and `prefabs/`; a scene kept elsewhere (Sky
  Hopper's `levels/generator_base.scene.json`) is covered by `scene.format {check, strict}` only.~~ Done in M7
  (`c604211`): every `*.scene.json` / `*.prefab.json` of the project, like `scene.format`.

## M7. Leftovers of M5 and M6, mobile players run in CI (M-L, *proactive*) — DONE (`6b9b85d`, `46d12bb`, `79d6f1e`, `2eadd1e`)

Closes every item of the two lists above, plus "the mobile builds have never run" (docs/MOBILE.md).

Outcome: four packages, one merge each.
- Tooling (`c604211`, `a90dee2`, `d97f54c`, `233939d`): range errors name the range and the nearest allowed value, from
  scene files, commands and script writes alike (`check_range`); `project.validate` checks and loads every scene and
  prefab of the project (shared `project_scene_files`, the list `scene.format` uses) and each prefab on its own;
  `scene.set_component {merge}` and `"$merge"` in `scene.import_ascii` edits; `physics.raycast` takes `mask`, `ignore`
  and `ignoreTriggers` through the same parser and schema as `physics.shape_cast`.
- Gamepads (`3e1f4d8`): Linux pads go through SDL GameControllerDB mapping lines (built in: DualShock 4, DualSense,
  DualSense Edge, Switch Pro, matching SDL's entries for the kernel drivers; xpad layout as the fallback; more lines from
  `SDL_GAMECONTROLLERCONFIG`); a pad stays connected through focus loss; Android pads come through sokol's
  `native_event_cb` hook. Parser and Android mapping are platform-neutral and unit-tested.
- 3D physics (`cd1feda`, `e37aebe`, `ae0f8ac`, `d89bf31`, `68e2993`): dynamic boxes have an inertia tensor, contact
  manifolds (up to 8 points) and impulses at the contact points, so they tip, tumble and settle; `lockRotation`,
  `angularDamping`. Continuous collision sweeps every pair with a dynamic body in relative motion (dynamic, kinematic,
  static), and after a time of impact the rest of the sub-step continues (slide). No template or example changed.
- Mobile players run in CI (`2f2d25b`, `35ca2aa`, `b8156b0`, `d6222c2`, `efddf3b`): the `ios` job runs the app on the
  iOS Simulator and a new `android-emulator` job runs the APK on an API 34 x86_64 emulator; both wait for the player's
  `player: 60 frames rendered` log line, check for errors and crashes, and check that a screenshot is not blank. The
  first runs found two real bugs, both fixed: the player asked for OpenGL ES 3.1 (the emulator has 3.0 only; it now
  asks for 3.0), and textures without mipmaps sampled black on drivers that do not clamp the mip range of
  `glTexStorage2D` textures (every image now sets `GL_TEXTURE_MAX_LEVEL`).

Found while implementing M7 (all handled in M8 below, except what cannot run on hosted CI):
- ~~Spheres get no torque from contacts (they keep the arcade `rollWithMotion` model), 3D bodies never sleep, there is
  no gyroscopic term, edge-edge and sphere-box contacts are single-point, and boxes have no rolling friction.~~ Done in
  M8; the single-point contacts and the boxes' rolling friction were not gaps (tests prove it, `47fe537`).
- ~~Continuous collision ignores a box's own rotation within a sub-step and drops the movement left after 6 impacts in
  one sub-step.~~ Done in M8 (`1e9abb1`).
- ~~Linux built-in mappings cover the kernel-driver layouts only (hid-sony, hid-playstation, hid-nintendo); a pad on the
  generic HID driver or any other non-xpad pad needs an `SDL_GAMECONTROLLERCONFIG` line. Android keeps an unplugged
  pad's slot and cannot tell pads that use Z/RZ as triggers from pads that use them as the right stick.~~ Done in M8
  (`75c378c`, `3e7088c`). No real pad has been used on Linux or Android yet.
- ~~CI runs the mobile players on a simulator and an x86_64 emulator with a software GPU: arm64 Android code, real GPUs,
  touch, audio and suspend/resume are not covered. The Android smoke script waits 20 s after the emulator boots.~~ Done
  in M8 (`0fc77c2`, `c3b4de0`) for touch (Android), audio, suspend/resume and the 20 s wait. arm64 Android code, real
  GPUs and touch on the iOS Simulator are still not covered (see M8).

## M8. Leftovers of M7, desktop download next steps (L, *proactive*)

Outcome:
- 3D physics (`546a216`, `164a00d`, `cea851d`, `1e9abb1`, `47fe537`, `d739ae8`): a sphere with `rollWithMotion` off is a
  rigid body (inertia 2/5 m r^2) turned by contact friction, so it rolls down a slope and spins when hit off-centre;
  arcade spheres are unchanged. Calm 3D bodies fall asleep as an island (under 5 cm/s for 0.5 s) and wake on touch,
  Transform/velocity writes, forces, gravity changes and lost support, like 2D. An implicit midpoint gyroscopic term
  keeps energy and angular momentum within 0.05% (a single Newton step, Bullet-style, lost 18% in 10 s). Continuous
  collision sweeps a box's own rotation and re-sweeps pairs left touching after an impact (a 40 rad/s rod at 150 m/s
  tunnelled 24 times in 100, now 0); up to 32 impacts per sub-step, the rest of the movement carries over instead of
  being applied unswept. Not gaps: a box on an edge parallel to a face gets a two-point manifold through face clipping,
  and boxes do not roll (`angularDamping` is their spin drag).
- Gamepads (`75c378c`, `3e7088c`, `2fd406a`): the 744 Linux lines of SDL_GameControllerDB are embedded
  (`external/sdl_gamecontrollerdb`, zlib), plus an optional `<project>/gamecontrollerdb.txt`; priority
  `SDL_GAMECONTROLLERCONFIG` > project file > built-in DB > xpad. Android asks `InputDevice` through JNI: an unplugged
  pad frees its slot, and Z/RZ are the right stick or the triggers depending on which axes the device reports.
- Mobile CI (`0fc77c2`, `c3b4de0`, `54b3442`): no fixed wait; a readiness gate (boot, package manager, provisioning,
  keyguard). The cause was most likely an activity restart: the emulator's SIM changes mcc/mnc a few seconds after boot,
  the activity was not declared to handle it, and sokol_app exits the process on destroy. The manifest now handles
  every configuration change, and a font-scale change in the smoke test guards it. The smoke tests check audio (output
  device open, stream running), touch (Android: a tap reaches `input: first touch`), suspend/resume (same process,
  60 frames after resume, a new native window on Android) and a configuration change.
- Prebuilt mobile players (`f63632a`, `4c8e4a1`, `5055f85`, `3a14bdf`, `fd7ab75`, `d1be230`): every package carries
  `mobile/android/jniLibs/<abi>/libfactoria_player.so` (arm64-v8a, x86_64) and the macOS one also the iOS static
  libraries (device arm64, simulator arm64 + x86_64). `factoria export --platform android|ios` uses them (`mode:
  prebuilt`): the Gradle project needs no NDK or CMake, the iOS project needs Xcode and CMake but no engine source.
  The engine checkout is still used when asked for or when factoria runs from a source build (`mode: source`). The
  editor's updater swaps folders too, so `mobile/` stays in sync.
- Desktop download (`083ad58`, `fb53f30`): `FactorIA-windows-x64-setup.exe` (Inno Setup, per user, Start menu, user
  PATH, uninstaller that also removes what the updater leaves), `FactorIA-linux-x64.AppImage` (editor by default,
  `factoria` CLI with arguments or through a `factoria` link; it does not update itself) and a universal macOS
  package, `FactorIA-macos-universal.tar.gz` (the release also uploads it as `FactorIA-macos-arm64.tar.gz` for editors up
  to 0.1.2). Code signing (signtool) and signing + notarization (codesign, notarytool) run when the repository secrets
  exist (docs/BUILDING.md, "Releasing"); without them the packages stay unsigned.

## M9. Run on Apple hardware (M, *proactive*) — DONE (PR #33 and the `m9-apple-hardware` PR)

CI builds macOS and iOS but had never run the GPU tests on Metal, the editor on macOS, an Apple gamepad or an iOS device.
The first full run on a Mac (Apple M5, macOS 26, Xcode 27) passed every registered test, GPU ones included: render goldens
(bloom too), `cli_integration` and the four examples. It found the editor gaps below.

1. Editor on macOS — DONE (`b955fa0`, PR #33). The window read-back behind the autotest screenshots was GL-only, so on Metal 14
   of the editor autotest's 103 checks failed; and the autotest exited with 0 anyway, because `sapp_run()` never returns on
   macOS (Cocoa ends the process with 0). Now: Metal read-back (`tools/editor/src/backbuffer_apple.mm`: the layer is made
   readable in autotest mode, the frame's drawable is blitted after `sg_commit()`); `AppDesc.exit_code`, which `run_app`
   passes to `exit()` on macOS, so a windowed `factoria run` and the editor return their real code there too; both editor
   autotests registered in ctest on macOS; the macOS CI job runs the whole suite (no `-LE gpu`).
2. Gamepads — DONE. An Xbox Wireless Controller over Bluetooth on macOS 26.6: every button by position (A bottom, B
   right, X left, Y top), LB/RB, L3/R3, Menu = `Start`, View = `Back`, both sticks with +Y up and +X right, triggers
   0..1, and power off/on gives the same slot back. `gamepad_apple.mm` used to number pads by their index in
   `[GCController controllers]`, so unplugging one renumbered the others; a pad now keeps its slot while connected (like
   Linux and Android) and the backend logs `gamepad: pad 0 connected: Controller (Xbox One)`.
3. iOS — DONE. The first runs on the iOS 27 Simulator and on an iPhone 16 (A18, iOS 27): Block Push, Neon Swarm and Gem
   Roller render (2D, 3D, bloom), play audible sound, take taps, survive Home and back and a turn to the other landscape
   side. CI now taps too (see below).
4. The unsigned macOS download — DONE. Gatekeeper on macOS 26.6 and the editor's updater (0.1.2 to 0.1.3 with the Update
   button) behave as below; docs/GETTING_STARTED.md describes the steps that were checked.

Found and fixed while implementing M9 (Android, the `android-emulator` job of CI run 38821970366 on `main`):
- The job failed with "no process for dev.factoria.cigame right after am start": the activity, started right after the
  install, was relaunched for an assets-path change (`wm_relaunch_resume_activity ... 80000000`, `CONFIG_ASSETS_PATHS`,
  which no `configChanges` value covers) while ActivityManager was still delivering `BOOT_COMPLETED` and the install's
  broadcasts. `android-smoke.sh` now waits for `am wait-for-broadcast-idle` after the install.
- That relaunch showed a real bug. sokol_app ends the process with `exit(0)` in `onDestroy`, and `exit()` ran the C++
  static destructors while other threads still ran: the engine (owned by static `AppDesc`s) shut down on the main thread
  with no GL context ("call to OpenGL ES API with no current context"), and the logger's mutex was destroyed while
  sokol's loop thread still logged ("FORTIFY: pthread_mutex_lock called on a destroyed mutex", SIGABRT). Even a clean
  exit lost the game: Android drops an activity whose process died without saved state ("app died, no saved state"),
  so on a phone a wallpaper-colour or theme change (Android 12+) or an overlay closed the game. Now
  `engine/platform/src/sokol_impl.c` wraps sokol_app's `ANativeActivity_onCreate` and turns that exit into `_exit(0)`,
  and the activity is `stateNotNeeded`, so the system starts the game again in a new process. The smoke test's new
  relaunch step (`am update-appinfo`, the update an overlay change sends) checks that the game comes back with no native
  signal; with the old player it fails ("the game did not come back after the relaunch"). Checked on an arm64 API 35
  emulator: `am update-appinfo`, the display-cutout overlay on and off, and Back (the game ends, no restart).

Found and fixed while implementing M9 (Apple hardware):
- Every touch on iOS landed 3x too far from the finger, and mouse clicks 2x on a Retina Mac (and on a Windows display
  scaled to 200%): `to_design()` in `engine/platform/src/app.cpp` scaled sokol_app's event positions by
  `sapp_dpi_scale()`, but sokol_app already reports them in framebuffer pixels on every platform. Only Android (scale 1)
  and 100% desktop displays worked. The editor's game view had its own, correct conversion.
- iOS touch was not covered in CI (`simctl` cannot tap). `scripts/ios-smoke.sh` now builds a UI test
  (`platforms/ios/touch-test`, XCUITest, generated with CMake) that taps the middle of the running app's screen, and
  checks that `input: first touch` lands at the middle of the design; with the old `to_design()` it fails ("landed at
  design (2205, 1080), expected about (640, 360)").
- From the iOS 27 runtime (Xcode 27) on, `simctl launch --stdout/--stderr` opens the paths inside the simulator's own file
  system, so the smoke test saw an empty console and failed on a healthy app. It captures the console with
  `--console-pty` now (and asks the simulator's launchd for the pid), which works with older Xcodes too.
- `build_ios.sh --build` (export) could not build for a device the first time: `cmake --build` builds a target, and
  `xcodebuild -target` ignores `-destination`, so Xcode could not register the connected iPhone with the team ("Your team
  has no devices from which to generate a provisioning profile"). Device builds are scheme builds now, with the
  connected device as destination and `-allowProvisioningDeviceRegistration`; simulator builds need no team; and
  `--run` installs the app and starts it with its console in the terminal (`simctl` or `devicectl`), so an AI can run a
  game on an iPhone without Xcode's UI.
- On a Retina screen the editor autotest saved 2x screenshots (2940x1782 on a MacBook Air), about a second each to encode
  in a Debug build. They are saved at the window's logical size now (the pixel checks still read full resolution): the
  autotest went from 17 s to 12 s.
- Gatekeeper, checked on macOS 26.6 with the 0.1.3 package: a browser download is quarantined, and unpacking keeps the
  quarantine with Archive Utility (Finder) and with `tar` in Terminal alike. Each quarantined executable is blocked on
  its first run ("Apple could not verify..."; Done ends it with exit 137); System Settings > Privacy & Security > Open
  Anyway, then Open Anyway again on the next run, approves that one executable (`factoria_player` stays blocked).
  Files written by an approved `factoria` are quarantined too but run without asking (an exported game did).
  `xattr -dr com.apple.quarantine <folder>` clears it all. The docs now say this instead of right-click > Open.
- The updater on macOS: the 0.1.2 editor updated itself to 0.1.3 and reopened. It did not bring `mobile/`, because 0.1.2's
  updater swapped files only (folders came in 0.1.3); the next update fills it in. `FA_UPDATE_LIVE=1 fa_test_editor`
  runs the current `install_update` against the newest real release (download, unpack, `mobile/`, the new `factoria`
  runs); it passes on macOS.
- A Debug APK aborted in `sg_setup` on an arm64 API 35 emulator started with `-gpu swiftshader_indirect`
  (sokol_gfx asserts `glGetError() == 0` in `_sg_gl_init_limits`). The player asks for an ES 3.0 context; that
  emulator's GL stack (gfxstream over ANGLE/SwiftShader) answers `GL_MAJOR_VERSION`/`GL_MINOR_VERSION` with its highest
  version, 3.1, so sokol_gfx turned on compute and queried `GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS`, which gfxstream
  rejects on a 3.0 context (`GL error 0x500`). `engine/platform/src/sokol_impl.c` now gives sokol_gfx the version the
  player asked for whenever the driver reports a newer one (the engine uses no ES 3.1 feature, and every device runs
  the same sokol_gfx code). `android-smoke.sh` passes on that emulator with `-gpu swiftshader_indirect` (ES 3.1) and
  `-gpu host` (ES 3.0 on Metal); CI's x86_64 emulator reports 3.0 and is unchanged.
- macOS signing is set up (Apple Developer Program, individual): a Developer ID Application certificate and the five
  `APPLE_*` repository secrets of docs/BUILDING.md. A release run started by hand (nothing published) signed `factoria`
  and `factoria_player` (hardened runtime, timestamp) and Apple accepted the notarization in under half a minute; the
  package, downloaded and unpacked with a browser's quarantine, ran `factoria version`, `new`, `test`, `run --headless`
  and the editor with no Gatekeeper prompt (the unsigned 0.1.3 was blocked in the same test). The first signed release
  is the next tag after v0.1.3.
- With the player signed, every game exported for macOS had a broken seal: the export copies `factoria_player` into the
  `.app` and adds `Info.plist` and the game files, which the player's own signature does not cover (`codesign --verify`:
  "code has no resources but signature indicates they must be present"), so a downloaded copy would be called damaged,
  with no Open Anyway. The export now signs the finished bundle ad hoc, after every file is written (the notices too),
  and its next steps add `--force` to the Developer ID command (a signed app is not re-signed without it).
- Windows with the display scaled above 100%, checked after the `to_design()` fix on Windows 11 at 125% (120 dpi, a
  1600x900 px window for the 1280x720 design): real clicks (`SendInput`) on a probe game that logs
  `input.mouse.position` land on the design point under the cursor, to within a pixel, in `factoria run` (also with the
  window resized to bars on the sides and on top and bottom), in the exported game and in the editor's game view
  (Play). Nothing needed changing.
- The probe behaviour of that check, written with `start()`/`update()` instead of `onStart()`/`onUpdate()`, ran
  nothing, and nothing said why: `factoria validate` passed and `run` logged nothing, even at `--log-level debug`. A
  behaviour method that is a hook without its `on` (`update`, `fixedUpdate`) or a near-miss of a hook name starting
  with `on` (`onupdate`, `onStrat`) now logs one warning per class and method when the first behaviour of the class is
  created ("did you mean 'onUpdate()'?"), and `factoria validate` reports it for every behaviour script
  (`ScriptSystem::check_hooks`). Helpers such as `loadLevel()` stay silent.

## M10. Game UI and menus (L, blocker for every store) — DONE (PRs #47, #50, #51, #53)

Closes F-01, F-12, U-01..U-04, U-07, U-09 and the script half of F-08. Today the scripting API has `ui.measureText` and no
widget component, so no game can have a main menu, options or an in-game shop; the window cannot go full screen from a
script; and text entry, the cursor and input remapping exist only in C++ (`Input::text_input()`).

- Widgets as components: Button, Slider, Toggle, scrolling List, text field, Panel with 9-slice; row/column/grid layout
  on top of the existing `anchor`/`pivot`; focus and navigation with keyboard and gamepad (Steam Deck and consoles
  require it); `ui` events in JS.
- Settings an options menu needs, in JS: full screen, resolution, vsync and a frame cap (`window.*`); rebinding actions
  and per-pad button names (`input.rebind`, `input.buttonName`); text entry and cursor show/lock.
- Menus as a recipe plus a test fixture: the AI guide's recipe builds a main menu, pause (on `game.paused`), options
  (video, audio volume per bus with `audio.setVolume`, controls, a language slot for M14), credits that list
  `FACTORIA_NOTICES.txt` and a loading screen in a few steps; a fixture project under the tests is that recipe, run by
  ctest.

Acceptance criteria:
- A headless test drives the menus fixture (`tools/cli/tests/fixtures/menus`) from the main menu to options, changes the
  music volume and comes back using only gamepad presses, then checks the saved setting.
- A 9-slice panel drawn at three sizes keeps its corners unscaled (golden image).
- `window.setFullscreen(true)` toggles a windowed run; headless runs return a teaching error instead of doing nothing.
- Every widget field and command has a doc string; COMPONENTS.md and the typings are regenerated.

What was built:
- **Widgets** (#51): `Panel` (9-slice, row/column/grid layout with `spacing`, `padding`, `align`, `justify`, `fit`),
  `Button`, `Toggle`, `Slider`, `TextField`, `ScrollList` (scrolls with the wheel and the focus, clips its children), in
  a new `fa_ui` module. Focus only through `autoFocus` or `ui.focus`, so Space/A never clicks a HUD button; keyboard,
  gamepad and mouse navigation with auto-repeat; default `ui_*` actions; `ui.on`, `ui.focus`, `ui.focused`,
  `ui.hovered`; the `ui.state` command. Goldens `2d_nine_slice` (the acceptance criterion: corners compared pixel by
  pixel at three sizes) and `2d_widgets`.
- **Settings in JS** (#50): `window.*` (full screen, size, resolutions, vsync, frame cap; teaching errors without a
  window), `input.rebind` / `bindings` / `resetBindings`, `input.lastPressed()`, `lastDevice`, `buttonName` and
  `gamepad(i).type` per pad family, `input.text`, `showKeyboard`, `mouse.visible` / `locked`; a real-window full screen
  test (`runtime_windowed_fullscreen`, Linux CI under xvfb). `display.vsync: false` now works (it was ignored).
- **Pause that pauses** (#47): `game.paused` freezes physics, particles, animators, timers and `onUpdate`;
  `runWhilePaused` behaviours keep running with the real `dt`; `game.notices()` for credits; `audio.getVolume(bus)`,
  `game.platform`.
- **Menus recipe and fixture** (#53): `docs/MENUS.md` (`factoria docs read menus`) gives every file of a main menu
  (Quit hidden on phones), a loading screen, a pause menu, options (video, audio per bus, controls rebinding, a language
  slot for M14) saved in `storage` and applied at start, and credits from `game.notices()`; AI_GUIDE 9.22 (widgets) and
  9.24 (the steps) lead to it. `tools/cli/tests/fixtures/menus` is the same files as a project (`fixture_menus_validate`,
  `fixture_menus_test`), driven with gamepad presses only: `tests/recipe.test.js` (main menu -> options -> music volume
  -> back -> saved setting, the doc's sample) and `tests/menus.test.js` (rebinding, pause, credits, loading). A `cli`
  test fails when a file in the doc differs from the fixture's.

## M11. Native plugins per game (L, blocker for M12 and the consoles) — DONE (PR #49 and the `m11/plugins-mobile` PR)

Closes F-13. Adding C++ means changing the engine and rebuilding the players (docs/EXTENDING.md), and the exported
Android manifest says `android:hasCode="false"`, so no store SDK (all of them native, Java or Swift) can be used, and
console SDKs, which are under NDA, cannot live in this MIT repository.

- A C ABI for per-game native modules (`fa_plugin_init(const FaPluginApi*)`) that registers commands and JS functions.
- Desktop: a DLL/so/dylib next to the exe, declared in `factoria.json`; mobile: static libraries, AARs or Swift packages
  linked by the generated Gradle and Xcode projects (`hasCode` true when a plugin has Java or Kotlin).
- Plugins can live outside the game repository (a private folder), for SDKs that cannot be published.
- `factoria validate` checks each declared plugin exists for the target platform; the export copies or links it.

Acceptance criteria:
- A test plugin adds `plugins.example.add(1, 2)` and a command; both work in `factoria run`, in the exported Windows,
  Linux and macOS games, and in the Android project CI builds and runs on the emulator (with a Java class from the
  plugin).

Done: the C ABI `engine/runtime/include/fa/runtime/fa_plugin.h` (commands and `plugins.<name>.<fn>()` with doc
strings), `"plugins"` in `factoria.json` (paths with `${VAR}`, so a plugin can live in a private folder), the loader in
`engine/runtime` (a plugin that does not load is a warning, and its reason is the script's error), `factoria validate`
(the missing file of each declared platform, teaching), the export (desktop: next to the exe or in
`Contents/Frameworks`; Android: the plugin's Gradle module or `.aar` / `.jar`, `hasCode` true when it brings code; iOS:
two static libraries linked by `platforms/ios/plugins.cmake`) and `factoria call project.new_plugin`, which writes a
plugin that builds for every platform (`platforms/plugin`). CI: ctest `cli_plugin` runs `factoria run` and an exported
game on Linux, Windows and macOS; `android-apk` builds the plugin with the NDK and `android-emulator` checks that the
sum came from the plugin's Java class; `ios-build` / `ios` link it into the simulator app and check the same log.

## M13. Store-ready desktop export (M-L, high) — DONE (PRs #65, #66, #67, #68 and the `m13/sign` PR)

Closes E-04, E-05, E-06 (the crash half), E-09 (the desktop half; mobile uploads are M16), E-10, F-15, Q-03 and H-10.
Authenticode signing is M8, "Left open".

- Linux: the release player needs glibc 2.38 and GLIBCXX 3.4.31 (`release.yml` builds on `ubuntu-24.04`), so it does
  not start in the Steam Linux Runtime "sniper" (glibc 2.31), Ubuntu 22.04 or Debian 12. Build it in the sniper SDK
  container or an old-glibc image.
- Packing: with `--release` the game ships as one archive read through `fa::fs` instead of loose files, with optional
  QuickJS bytecode instead of plain `.js`. The export copies the project's `README.md` today; leave out files that are
  not game data.
- Crash reporting next to `log.txt`: a minidump on Windows (`SetUnhandledExceptionFilter`, `MiniDumpWriteDump`), a
  backtrace on POSIX; an optional upload URL, off by default.
- Upload as commands an AI can call: steamcmd (writes the app build VDF), butler (itch.io), Epic's BuildPatchTool and
  GOG's Galaxy Pipeline Builder, with a dry run.
- macOS: Developer ID signing and notarization of the exported `.app` as a command (codesign, notarytool, stapler),
  instead of the manual steps in docs/EXPORTING.md ("To distribute the game...").
- Linux direct distribution: an AppImage or Flatpak of the exported game with its `.desktop` file (the export writes a
  folder and suggests a tar).
- A CI workflow for game projects (validate, test, export), from a template file or `factoria new`.
- `scripts/build.ps1` asks only PATH for `cmake`, so a Visual Studio install with its bundled CMake fails with "cmake
  not found"; find it through vswhere, and warn about checkout paths deep enough for MSBuild's FTK1011 (MAX_PATH).

Acceptance criteria:
- CI runs the release Linux player (`--version` and a headless frame) inside the Steam Runtime sniper container.
- A `--release` desktop export has no loose `.js` and no README.md, and still runs.
- A deliberate crash leaves a crash file with a stack in the save folder.
- `build.ps1` builds on a machine whose only CMake is the one Visual Studio installs.

What was built (docs/EXPORTING.md is the reference):
- Linux (#68): the release Linux programs are built in the Steam Runtime sniper SDK container (`scripts/build-sniper.sh`,
  preset `linux-sniper`: GCC 14, static libstdc++ with `FA_LINUX_STATIC_LIBSTDCXX`, `libGL.so.1` through
  `OpenGL_GL_PREFERENCE=LEGACY`, no libcurl). The CI job "Linux (Steam Runtime sniper)" builds there, checks the glibc
  and GLIBCXX symbol versions against the runtime's own libraries and, in the sniper runtime container, runs
  `factoria_player --version`, `factoria new` and one headless frame; `release.yml` builds linux-x64 the same way and
  `scripts/ci-local.sh sniper` runs it locally. `scripts/build.ps1` finds Visual Studio's CMake through vswhere and warns
  about checkout paths near Windows' 260-character limit.
- Packing (#67): `factoria export --release` (`project_export {"release": true}`) writes the game as one `game.pak`
  (`fa/core/pack.h`, mounted by `fa::fs`; the player finds it next to itself), with QuickJS bytecode instead of `.js`
  unless `export.scriptBytecode` is false (`fa/script/bytecode.h`); the project's README.md is no longer exported.
- Crash reports (#65): `fa/core/crash.h`. The player writes `crashes/crash-<UTC time>.txt` (signal or exception, stack,
  last log lines) next to `log.txt`, plus a minidump on Windows; the newest five are kept and the next run can hand the
  last one out once (`take_previous_crash_report`).
- Uploads (#66): `publish.steam` (writes the app build VDF for steamcmd), `publish.itch` (butler), `publish.epic`
  (BuildPatchTool) and `publish.gog` (Galaxy Pipeline Builder), each with `dryRun`; settings in the project's `publish`
  object, secrets only from environment variables or `~/.factoria/`.
- macOS signing, AppImage and CI (the `m13/sign` PR): `sign.macos` signs the exported `.app` with a Developer ID
  (hardened runtime, entitlements), notarizes it with notarytool, staples the ticket and zips it; `project_export
  {"format": "appimage"}` wraps the Linux export with its `.desktop` file and icon (appimagetool from the setup component
  `appimage`, pinned by SHA-256); `project.new_ci_workflow` writes `.github/workflows/factoria.yml` (validate, test,
  export).

Acceptance:
- The sniper CI job above runs the release Linux player (`--version` and a headless frame) in the sniper runtime.
- `tools/common/tests/export_pack_test.cpp`, "export --release: a desktop game is one game.pak, with no loose scripts and
  no README.md"; `engine/runtime/tests/pack_tests.cpp`, "pack: an Engine runs the game from a mounted pack for some
  frames".
- `engine/core/tests/test_crash.cpp`: a null write, `abort()`, an uncaught exception and a stack overflow each leave a
  report with a stack.
- `build.ps1` was run on a Windows machine whose only CMake is the one Visual Studio Build Tools installs.

Found while implementing M13:
- ccache shared across git worktrees gave stale objects with MSVC: a cache hit replays `cl /showIncludes` with the
  absolute header paths of the checkout that filled the cache, so Ninja watched another worktree's headers. Since #69
  only GCC and Clang share the cache across checkouts (docs/BUILDING.md).

## M14. Localization (L, blocker for a global release) — DONE (PRs #73, #74 and the `m14/finish` PR)

Closes F-02, H-08, U-06 and the text-scaling part of U-05.

- String tables (`locales/<lang>.json`), `i18n.t(key, args)` in JS, a `key` field on Text, the system language on every
  platform, a fallback language, `i18n.setLanguage` at run time.
- A font fallback chain (project-wide and per Text), so a CJK font fills what the main font lacks.
- Shaping with HarfBuzz (MIT) and bidirectional line layout for Arabic, Hebrew and Indic scripts.
- `factoria validate` reports characters in string tables and scene texts that no configured font covers, with the file
  and the character (the run-time warning added in this PR is the starting point); CSV or XLIFF export and import for
  translators.

Acceptance criteria:
- `日本語 中文 한국어 العربية` renders every script with Noto fonts, Arabic joined and right to left (golden image).
- `validate` fails on a missing glyph and names the character, the text and the file.
- Switching language at run time updates every Text that has a `key`.

What was built (docs/LOCALIZATION.md and docs/TEXT.md are the reference):
- Localization runtime (#73): string tables `locales/<language>.json` (`fa/core/i18n.h`: nested keys, CLDR plural entries,
  `{placeholders}`, `$name`, the fallback chain language -> base language -> default language, the best match of the
  system's languages), the `"localization"` section of factoria.json, the system languages in fa_platform (Windows,
  Apple, Android, Linux), `key` on Text and every UiControl rewritten after each scene load, spawn and frame
  (`fa/scene/localize.h`), `i18n` in scripts (`t`, `setLanguage`, `on("change")`...), the commands `i18n.state` and
  `i18n.set_language`, hot reload of the tables, and the menus recipe and fixture in English and Spanish with a Language
  option.
- Text engine (#74): HarfBuzz 14.6.0 and SheenBidi 3.0.0 vendored; a font fallback chain (`Renderer::set_fallback_fonts`),
  shaping by glyph index (kerning, ligatures, Arabic joining), bidirectional reordering per line, line breaks between
  CJK characters, one layout for Text, widget labels, debug text and `measure_text`, cached per text and size; the text
  size option `ui.textScale` / `ui.set_text_scale`; the GPU-free coverage check `fa/render/fonts.h`; docs/TEXT.md.
- Finish (the `m14/finish` PR): the renderer's fallback fonts follow the language (`localization.languageFonts`, then
  `fallbackFonts`); `factoria validate` checks the tables (missing and stale keys with "did you mean", placeholders,
  plural forms per language), the `key`s of scenes and prefabs, and every text against its font chain, naming the
  character, the text, the file and the fix; `i18n.export` / `i18n.import` write and read CSV (spreadsheets) and XLIFF 1.2
  (CAT tools) for translators.

Acceptance:
- `engine/render/tests/text_tests.cpp`, "text: Japanese, Chinese, Korean and Arabic draw together through the fallback chain
  (golden)" (`2d_text_scripts.png`, Noto subsets) and "text: Arabic letters take their joined forms, and a right-to-left
  line starts at its right end".
- `tools/common/tests/validate_localization_test.cpp`, "validate: a character no font has is an error that names the
  character, the text, the file and the fix".
- `tools/cli/tests/fixtures/menus/tests/i18n.test.js`, "the Language tab switches every Text and widget that has a key, at
  once"; `engine/runtime/tests/localization_tests.cpp`, "engine: the renderer's fallback fonts follow the language, so a
  Japanese Text with font "" draws only in Japanese".

## M15. AI asset generation and import pipeline (L, blocker for "the AI does everything") — DONE (PRs #52, #55, #56, #57)

Closes A-01..A-07, H-04 and F-07 (music streaming). Today an AI can only write a PNG through `fs.write`; `assets.list` is
the only asset command, textures stay uncompressed RGBA8, and music is decoded whole into memory
(`stb_vorbis_decode_memory`: a 3-minute track takes about 60 MB).

- Asset providers configured like the LLM providers (docs/AI_PROVIDERS.md): images and sprite sheets, sound effects,
  music and voice, 3D models; commands such as `assets.generate_image` write into `assets/`.
- A provenance record for every generated or imported asset (provider, model, prompt, license, date) and an export
  summary for Steam's AI-generated content disclosure.
- Per-asset import settings: atlas packing, texture compression (BC7 on desktop, ASTC or ETC2 on mobile, e.g. KTX2 with
  Basis Universal), audio conversion, loudness normalization and streamed music.
- Sprite-sheet slicing and style consistency (palette lock, reference images passed to the provider).
- Importers for Aseprite, PSD and OBJ; FBX through conversion to glTF; SDF/MSDF font atlases; video files (for M19's
  video player).
- `project.validate` checks asset size, alpha, weight and loudness (LUFS).

Acceptance criteria:
- With a fake provider in tests, `assets.generate_image` writes a PNG and its provenance record.
- A 3-minute OGG plays with under 2 MB of decoded audio resident.
- A mobile export ships compressed textures and still matches the render golden.

What was built (docs/ASSETS.md is the reference):
- `assets.json` at the project root: per-asset import settings (with `defaults` per kind) and provenance; validated by
  `project.validate`; exports ship the import settings and drop provenance and style.
- Generation (#57): an `assets` section in `ai.json` maps image, sound, music, voice and 3D models to
  providers (OpenAI, ElevenLabs, Meshy, a local `asset-command`, and `fake` for tests); `assets.generate_image`,
  `_sprite_sheet`, `_sound`, `_music`, `_voice`, `_model` write under `assets/` with provenance; house style (prompt,
  reference images, palette lock); `assets.provenance`, `assets.set_provenance`, `assets.disclosure`, and exports write
  `AI_CONTENT_DISCLOSURE.md` (Steam's pre-generated / live-generated answer) when an asset is AI-made. Acceptance:
  `tools/ai/tests/test_assets.cpp`, "assets.generate_image with the fake provider writes the PNG and its provenance".
- Import (#52): `assets.import` for Aseprite (tags as clips), PSD (flattened), OBJ + MTL (to glTF), FBX (through
  FBX2glTF or Blender), and copies of the formats the engine reads; `assets.slice_sheet` (grid check, or auto-slicing of
  uneven sheets with background removal); validate checks texture size, alpha, file weight and store size limits.
- Audio (#55): streamed playback (per-voice decoders), BS.1770-4 loudness with `assets.analyze_audio` and `normalize` /
  `targetLufs`, WAV to QOA conversion at export, a loudness check in validate. Acceptance:
  `engine/audio/tests/test_streaming.cpp` plays a 3-minute OGG with at most 40 KB of decoded audio resident (about 60 MB
  decoded whole).
- Textures (#56): Basis Universal KTX2 twins written by mobile exports (`compression`), transcoded at load to ASTC 4x4,
  BC7, ETC2 or RGBA8; atlas groups (`atlas`) packed by the export for sprites, particles and UI widgets. Acceptance:
  `tools/cli/tests/acceptance_textures_test.cpp` against `tools/cli/tests/golden/export_2d_platformer.png`.

## M16. Mobile store-ready (M, high on mobile) — DONE (PR #77 and the `m16/touch-gamepad` PR)

Closes F-17, the device half of F-08, the mobile half of E-09, E-12, E-13 and the mobile part of Q-06. Store SDKs on
mobile come with M11 and M12.

- `screen.safeArea` in JS (Android window insets, iOS `safeAreaInsets`), and anchors that can follow it.
- Android Back: an event the game can consume; today the system Back leaves the app.
- An on-screen keyboard for M10's text field, an optional on-screen gamepad, vibration.
- The iOS export writes `PrivacyInfo.xcprivacy` (the required-reason APIs the engine uses) and
  `ITSAppUsesNonExemptEncryption`; the docs list what to declare in Google Play's data safety form.
- `setup players --platforms mobile` on Windows and Linux installs the iOS libraries too (only the macOS package has
  them today, so an iOS project from Windows needs `--mobile-dir` pointed at a macOS package).
- Upload as commands with a dry run: App Store Connect and TestFlight (App Store Connect API), and the Google Play
  Developer API (or fastlane).
- An Android `--release` export without a keystore is an error unless `--allow-debug-key` is passed: today it is only a
  warning, and the AAB it produces is one Google Play rejects.

Acceptance criteria:
- The emulator smoke test sends Back and the game receives the event; a notched device profile reports non-zero insets.
- A test reads `PrivacyInfo.xcprivacy` from the generated Xcode project.
- `export --platform android --release` without a keystore fails with a teaching error.

What was built (docs/MOBILE.md is the reference):
- Runtime (#77): `screen.safeArea` / `screen.insets` in JS and `safeArea: true` next to `anchor` on Sprite, Shape2D, Text,
  ParticleEmitter and UiBox (Android window insets and display cutout through JNI, iOS `safeAreaInsets`; refreshed on
  resize and every 15 frames); `screen.set_safe_area` and `game.setSafeArea` fake a notched phone in tests.
  `input.onBack(fn)` (newest handler first; returning `false` passes it on; unconsumed = quit, as before; the manifest
  sets `enableOnBackInvokedCallback="false"` so Android 13+ still sends the key). `input.vibrate(seconds)` (VIBRATE is in
  the manifest template). The Android on-screen keyboard through `InputMethodManager`, characters from the key events.
- Export (#77): `PrivacyInfo.xcprivacy` (FileTimestamp C617.1, SystemBootTime 35F9.1; more from `export.ios.privacy`) at
  the root of the app bundle, `ITSAppUsesNonExemptEncryption` (`export.ios.usesNonExemptEncryption`), `allowDebugKey` /
  `--allow-debug-key`, `setup players` takes `mobile/` from the macOS package on every host. docs/MOBILE.md "Store privacy
  forms" covers Data safety and App Privacy.
- Upload (#77): `publish.appstore` (`xcrun altool --upload-package` with an App Store Connect API key, macOS only) and
  `publish.googleplay` (`fastlane supply`, track and release status, release notes per language), both with `dryRun`.
- CI (#77): the emulator job runs `mobile_probe.js` and sends Back (`FA_SMOKE_BACK` in scripts/android-smoke.sh).
- On-screen gamepad (the `m16/touch-gamepad` PR): the `TouchStick` and `TouchButton` UI widgets (UiBox, `safeArea` on by
  default, `touchOnly` shows them only while `input.lastDevice` is touch; a phone starts as touch). fa_ui hands their
  rectangles to `Input::set_touch_controls` every frame; a finger landing on one belongs to it until it lifts and drives
  the TOUCH PAD (`pads_[kMaxGamepads]`), which the action bindings read like any pad and the numbered pad queries never
  see; such a finger is kept out of `touches()`, the Touch binding and the mouse. Drawn by fa_render as discs (or the
  9-slice texture), listed by `ui.state`. Acceptance: `engine/ui/tests/test_ui.cpp`, "on-screen gamepad: a stick and a
  button feed the pad actions, several fingers at once, and keep their fingers"; `engine/runtime/tests/ui_tests.cpp`,
  "on-screen gamepad: a JavaScript test plays the pad actions with two fingers"; `engine/render/tests/ui_render_tests.cpp`,
  "on-screen gamepad: discs, the knob follows the stick value, a hidden control draws nothing".

## M17. Web export (L, high) — DONE (the `m17/web` PR)

Closes E-07 and the web gamepad gap (docs/MOBILE.md).

- An Emscripten preset and player (WebGL2), `export --platform web` writing `index.html`, the wasm and a data pack;
  audio unlocked on the first input; `storage` in IndexedDB; gamepads through the browser Gamepad API.
- A loading page with progress for the wasm and data download.

Acceptance criteria:
- CI builds the web player and runs an exported template in headless Chromium until its first frame renders.
- The export is a zip that itch.io accepts as an HTML5 game.

What was built (docs/EXPORTING.md "Web" and docs/BUILDING.md "Web" are the reference), in three worker branches merged
into `m17/web`:
- Player (`m17/web-player`): presets `web-release` / `web-debug` (Emscripten 6.0.10, pinned in docs/BUILDING.md), output
  `build/web-release/player/factoria_player.{js,wasm}` (MODULARIZE, `createFactoriaPlayer`, no pthreads, so no COOP/COEP
  headers, `-fwasm-exceptions`, Box2D without SIMD). The page `platforms/web/shell.html` (one file: streamed download
  progress, plain-words errors, `{{title}}`, `{{wasmBytes}}`, `{{pakBytes}}`) writes the pack to `/game.pak`; main()
  mounts it, restores the save folder `/save/<game id>` from IndexedDB (IDBFS) and starts the game, whose frames come from
  requestAnimationFrame. `fs::user_dir_changed()` (called by `storage`) syncs to IndexedDB half a second later and at
  once when the page hides. `audio_web.cpp` resumes the AudioContext on input until it runs; `gamepad_web.cpp` maps the
  browser's standard layout; the system language from `navigator.languages`; `input.vibrate` is `navigator.vibrate`.
  Plugins, processes, the crash reporter and the headless GPU are teaching stubs. `web` is a platform in factoria.json;
  plugins without a `platforms` list default to the native platforms.
- Export (`m17/web-export`): `factoria export --platform web` (aliases html5, browser, wasm; `project.export`; the
  editor's Export window) writes `<out>/<slug>-web/` (index.html, the player, game.pak always, notices) and
  `<out>/<slug>-web.zip` (index.html at its root, deterministic, deflated with the miniz basisu vendors). The player
  comes from `--player`, `<factoria dir>/web/`, `factoria setup players --platforms web`, or a source build; textures
  ship as PNG, atlas pages up to 2048 px. Tests: `tools/common/tests/export_web_test.cpp` (fake player) and setup tests.
- CI and release (`m17/web-ci`): the `web` job of ci.yml builds the player and the CLI, runs `scripts/web-smoke.sh`
  (exports the 2d-platformer, checks the zip against itch.io's limits, runs `platforms/web/smoke.mjs` in the runner's
  headless Chrome until `player: 60 frames rendered`); `scripts/ci-local.sh web` does the same. release.yml builds the
  player once (`web-player` job) and puts `FactorIA/web/` in every package, checked by exporting from the unpacked package.

## M18. Animation and production 3D (L, high for 3D games) — DONE (the `m18/integration` PR)

Closes F-03, F-04, F-05, F-06 and the run-time part of H-06.

Acceptance criteria:
- A skinned glTF sample plays two clips and blends between them (golden image).
- 10 000 instanced cubes draw in one draw call per material; off-screen meshes are not submitted (render stats).
- A capsule body walks up a triangle-mesh ramp; a revolute-joint pendulum keeps its period.

What was built, in four worker branches merged into `m18/integration` (docs/AI_GUIDE.md 9.9, 9.18, 9.25, 9.26 and
docs/ANIMATION.md are the reference):
- Rendering (`m18/render3d`): `mesh.glsl` is Cook-Torrance GGX PBR with a procedural sky IBL (`skyColor`,
  `horizonColor`) and a Karis environment BRDF; glTF metallic-roughness, normal, occlusion and emissive textures (and
  `KHR_materials_emissive_strength`); `MeshRenderer.normalMap` / `normalScale`; `MeshVertex` is 48 bytes with a tangent
  (glTF TANGENT or generated per triangle). Frustum culling, then instanced batches (same mesh, textures and material
  values; the model matrix per instance in vertex buffer 1; the shadow pass instanced too); the CPU side is GPU-free in
  `render/src/mesh_batch.{h,cpp}`. `kMaxLights` 32 in a separate `mesh_lights` uniform block; beyond it the shadow caster,
  then directional lights, then point/spot lights by brightness over distance. Stats: `meshesCulled`, `meshBatches`,
  `lightsDropped`. Tests in `render/tests/render3d_tests.cpp` (10 000 cubes = one draw, 100 culled, golden
  `3d_pbr_normalmap_ibl`; `3d_primitives` and `3d_shadows_fog` regenerated).
- Animation (`m18/anim`): `fa/scene/skeleton.h` reads skins, rest poses and clips (LINEAR, STEP, CUBICSPLINE) and the
  per-vertex joints/weights GPU-free; the cgltf implementation moved to fa_scene and every glTF reader goes through
  `fa::fs` (`fa/scene/gltf_file.h`). The `Animator` component (`fa/scene/animation.h`) runs in the fixed step after
  physics: cross-fades, clip events and `anim.finished` on `world.events().game`, a JSON state machine (`params`,
  `states`, `transitions` with `when` conditions, triggers, `onFinish`) and the joint palette. Scripts: `entity.animator`
  and `tween` / `ease` / `cancelTweens` in "factoria" (ticked with the timers). GPU skinning: a second program in
  `mesh.glsl` and `shadow.glsl` (`mesh_skin`, `shadow_skin`; the fragment shader is shared), joints and weights in vertex
  buffer 2, 64 joints as 3x4 matrices; skinned items are never instanced and are culled with `skinned_bounds`. Tests in
  `scene/tests/test_animation.cpp`, `script/tests/test_animation_script.cpp`, a runtime test, and the goldens
  `3d_skinned_bend` and `3d_skinned_crossfade` of `render/tests/data/skinned_two_bone.gltf`.
- 3D physics (`m18/physics3d`): `Collider3D` shapes `capsule`, `convex` and `mesh` (static only; BVH) with the `mesh`
  field read GPU-free by `fa/scene/mesh_geometry.h`; GJK/EPA in `physics/src/shape3d.cpp`. `Joint3D` (hinge, ball, fixed;
  limits and motor) in the sequential-impulse loop; `CharacterController3D` with `physics.moveCharacter(entity, delta)`.
  Tests in `physics/tests/test_physics3d_shapes.cpp`: every shape pair, a 6400-triangle ramp climbed by the controller and
  by a capsule body, a hinge pendulum within 1.5% of the analytic period, bit-identical reruns.
- 2D (`m18/2d`): tile flag bits (flip X, flip Y, transpose: `make_tile`, `tile_index`, `tile_flags` in
  `fa/scene/tilemap.h`; `flipX`/`flipY`/`rotate` in `scene.import_ascii` legends), `Sprite.slice` (9-slice shared with the
  UI through `render/src/nine_slice.h`), `Light2D` with `Sprite`/`Tilemap` `lit` and `normalMap` (16 lights per frame,
  `quad.glsl`), `Parallax` (`visual_world_matrix` in `bounds.h` keeps bounds and picking right) and `Joint2D` (Box2D
  revolute, distance, prismatic, weld; limits, motor, spring, reaction force). Tests in
  `physics/tests/test_joints2d.cpp` (revolute pendulum within 2%) and `render/tests/render2d_features_tests.cpp` (goldens
  `2d_tile_flags`, `2d_sprite_nine_slice`, `2d_lit_normal_map`, `2d_parallax`).

## M24.1-M24.6. Found by the reference game, first six packages — DONE (PRs #95, #96, #98, #99, #100, #101)

Closes LK/FB-0001, LK/FB-0002, LK/FB-0004, LK/FB-0005, LK/FB-0013, LK/FB-0027, LK/FB-0029, LK/FB-0033, LK/FB-0036,
LK/FB-0039, LK/FB-0042, LK/FB-0043, LK/FB-0045 and the colour part of LK/FB-0026 (its matchers are M24.7). Each entry
has a `Fixed in <commit>` note; Lantern Keep dropped the workarounds in the `m24/bookkeeping` PR.

- M24.1 Script values and promise rejections (PR #96, `1341def`): `Vec2`, `Vec3`, `Color`, `Rect` and the Vec4 view
  (live component views included) can be indexed (writes too), spread, destructured, iterated and passed to
  `Array.from`, and keep `.x .y .z .w` / `.r .g .b .a`; index and iterator properties are not enumerable and
  `Array.isArray` stays false. `length` is the component count on `Color` and `Rect`; vectors keep `length()` as the
  magnitude. `game.screenSize` / `screen.size` no longer copy the project settings (`ScriptHost::design_size()`,
  overridden by `Engine`; 281 µs per read before, 4.5 µs after, `world.find` 4.3 µs). A promise rejection is reported
  only if still unhandled once the job queue drains, once. Tests in `engine/script/tests/test_values.cpp`.
- M24.2 Pause keeps the game speed (PR #101, `acd5baf`): `game.paused = true` remembers `time.scale`,
  `game.paused = false` restores it; a scale above 0 set while paused is the one restored. The test `game` object has
  `paused`, and a member it does not have throws with a "did you mean". Tests in
  `engine/script/tests/test_pause_scale.cpp`.
- M24.3 Docs print LF on Windows (PR #95, `b6c6f3b`): `cmake/EmbedFiles.cmake` embeds text files (md, json, js, glsl,
  LICENSE/NOTICE/COPYING...) with LF, so a CRLF checkout builds the same binary as an LF one; `fa_test_cli` reads a doc
  through `factoria docs read` and `docs.read` and finds no CR.
- M24.4 Focus navigation (PR #98, `2ee41ac`): a direction press moves the focus to the nearest interactable widget in the
  beam (its rectangle overlaps the focused one across the direction); only when there is none, the nearest in that
  half of the screen (sideways distance doubled). When every visible `autoFocus` widget is not interactable, the first
  interactable widget in reading order takes the focus. `fa_test_ui` cases: a tab row above a wide button, an options
  panel (narrow tab, wide offset row, Back further down), a greyed-out `autoFocus` button.
- M24.5 Localization tools and text docs (PR #100, `43e03b9`): `i18n.import` writing a new language copies the shape of
  the default table (nested or flat); LOCALIZATION.md calls `i18n.state` a command; the `Text.font` doc and TEXT.md list
  Hebrew and Arabic in the built-in font; TEXT.md says `ui.measureText` is exact wherever a renderer exists; MENUS.md
  prints the recipe's `locales/es.json`, and a doc test checks both tables against the fixture.
- M24.6 Save file safety (PR #99, `d891e92`): `storage` saves through `fs::write_bytes` (temporary file, rename); a
  `storage.json` that does not parse is kept as `storage.corrupt.json` (then `storage.corrupt.2.json`...) with a warning
  naming it, the game starts with empty save data, and `storage.clear()` loads first so it never overwrites a damaged
  file. `storage.corrupt` tells scripts; `game.setStorageText(text | null)` in `factoria:test` sets the text the next
  load reads (never written to disk, reset per test file). Runtime and JS tests.

Found on the way:
- M24.4 asked for a 45-degree cone around the pressed direction. A centre cone sent Down from a narrow tab to a far-away
  Back button instead of the wide row under the tab, and broke the menus fixture and Lantern Keep's gamepad tests; the
  beam rule (as Android's focus finder) keeps the tab-row fix.
- `editor_autotest` can time out (300 s) when `ctest` runs while other builds load the machine; alone it passes in
  about 40 s.

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

## Found and fixed while starting a game from the editor on Windows

The editor's AI Assistant had never run with a real CLI agent on Windows (the process runner had no Windows test), so
the first try failed three ways, each fixed and covered by a test:

- `claude` and `codex` are npm `.cmd` shims, and `cmd.exe` cut the prompt at its first line break (it would also expand
  `%VAR%` and run text after `&`). The built-in templates now send the prompt on standard input (a template without
  `{prompt}` does this); arguments a `.cmd` cannot take safely are refused; a `.cmd` path with spaces works (`/s`).
- The MCP server `factoria` was not found when `factoria` was started by path: it now puts its own directory first on
  PATH for the agents it starts.
- In `-p` mode Claude Code asked before every MCP tool, so the agent could not use the engine: the template now passes
  `--allowedTools mcp__factoria`.
- Ctrl+V and Ctrl+C did nothing in any text box of the editor (the AI Assistant's input included): sokol_app's clipboard
  was never enabled, and sokol_imgui swallows the Ctrl+V key to paste on the clipboard event instead. Pasting a picture
  into the AI Assistant never worked either. The clipboard is now on (1 MB of text), and on Windows a clipboard with a
  picture and no text no longer pastes the previous text again, so Ctrl+V attaches the picture. The editor autotest
  pastes into the AI Assistant input.

## Desktop download: next steps (*proactive*) — DONE in M8

`.github/workflows/release.yml` packages the desktop tools as a zip / tar.gz that runs without dev tools
(docs/GETTING_STARTED.md, "Download"). Left out of that first package, all done in M8:
- ~~A Windows installer that adds a Start menu entry and puts `factoria` on PATH, so `.mcp.json` (bare `factoria`
  command) works from any terminal without editing PATH by hand.~~ (`fb53f30`)
- ~~Code signing on Windows and signing plus notarization on macOS, so SmartScreen and Gatekeeper stop warning.~~ Wired
  up (`fb53f30`); it signs once the certificates exist (M8, "Left open").
- ~~Prebuilt Android and iOS player libraries in the package, so `factoria export --platform android|ios` works from the
  download (today it needs the engine source and the SDKs, docs/MOBILE.md).~~ (`f63632a`, `5055f85`)
- ~~A Linux AppImage (one file, no tar.gz) and a macOS x86_64 or universal build (the package is Apple Silicon only).~~
  (`fb53f30`)
