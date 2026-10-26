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
  through `factoria docs read` and `docs.read` and finds no CR. In 0.2.0 the CLI's stdout became binary on Windows (text
  mode still turned each LF into CRLF), `integration.py` checks the real binary's output and the release smoke test
  checks every package.
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

## M24.7-M24.14. Found by the reference game, last eight packages — DONE (PRs #103-#110)

Closes LK/FB-0003, LK/FB-0006, LK/FB-0007, LK/FB-0008, LK/FB-0010, LK/FB-0011, LK/FB-0012, LK/FB-0015, LK/FB-0016,
LK/FB-0018, LK/FB-0019, LK/FB-0020, LK/FB-0021, LK/FB-0024, LK/FB-0025, LK/FB-0026, LK/FB-0028, LK/FB-0031, LK/FB-0035,
LK/FB-0040, LK/FB-0041 and LK/FB-0044. Each entry has a `Fixed in <commit>` note; Lantern Keep dropped the workarounds in
the `m24/bookkeeping-2` PR.

- M24.7 Test helpers (PR #105, `da5f957`): `game.platform.set({ backend: "none" })` makes the fake store behave as the
  none backend until `reset()`, and `platform.set_fake` refuses unknown options with a did-you-mean.
  `expect(x).toMatchObject(subset)`; a `not a function` TypeError shows its source line with a caret. `factoria test
  [project] <file|folder|glob>...` and MCP `project.test` `files` run only those test files. `game.click` / `touch` /
  `touchStart` take a widget id or an Entity; `ui.state` lists screen-space `Text`, and `ui.rectOf(entityOrId)` gives the
  laid-out rectangle in scripts. Docs say a `world.emit` from a test reaches listeners at the next `game.step`.
- M24.8 Widgets that fit their labels (PR #109, `7506b4b`): opt-in `autoSize` on `Button`, `Toggle` and `Slider` (at least the
  design `size`, grown to the label at the current text scale and language; the design size is remembered). Multi-line
  button labels are centred per line, `Button.maxWidth` wraps and a label that still does not fit is clipped.
  `ScrollList.fill` takes the height a column leaves; a `fit` Panel larger than the screen warns once (and in `factoria
  validate`). Headless runs scale text measures by `ui.textScale`.
- M24.9 Export and publish checks (PR #104, `343a7b8`): `export.exclude` globs leave files out of every export, checked
  by `factoria validate`; `publish.<store> {dryRun: true}` plans with a warning and a `MISSING_*` placeholder for each
  missing tool, secret or id; `factoria_player --frames N` exits 0, or 1 after a script error; validate warns about
  textures that are not multiples of 4 for mobile; new projects ignore `build/`.
- M24.10 ASCII levels keep prefab references (PR #106, `7c29612`): in file mode `scene.import_ascii` writes legend
  objects and the base scene's prefab entries as prefab references (an entity `edits` touches is written expanded), so a
  prefab edit reaches every level without a re-import; `legendFrom` shares a legend between maps.
- M24.11 2D lit shapes and moving platforms (PR #103, `3768d21`): `Shape2D.lit` (every shape type, flat); a dynamic body
  resting on a kinematic `RigidBody2D` is carried by it, its `velocity` relative to the platform, as in 3D.
- M24.12 Entity activation (PR #107, `f4071e7`): `onEnable()` / `onDisable()` on every show and hide, the first time
  after `onStart`; they and `onStart` of a script-activated entity run before the frame is drawn
  (`ScriptSystem::settle_activation()` after `late_update`, at most 8 rounds); an inactive entity with a `Script` has its
  behaviour at once.
- M24.13 Right-to-left layouts (PR #110, `2320973`): `Text.align` `start` / `end` follow the language's direction (`left` /
  `right` stay explicit, as M14 decided); `Panel.direction` `ltr` (default) / `rtl` / `auto` mirrors rows, grids and the
  panel's `start` / `end`; `i18n.direction` in scripts; `World::rtl()` follows the language. The menus fixture has an
  Arabic table and a mirrored options panel, with a golden.
- M24.14 Translated store catalog (PR #108, `2e0fa55`): achievements `nameKey` / `descriptionKey` and products `titleKey`
  / `descriptionKey`; `achievements.list()` and the fake `purchases.products()` return the current language's text;
  validate reports a key the default table lacks.
- `glob_match` exists once, in `fa/core/strings.h` (it had a copy in the runtime and one in the tooling).

Found on the way:
- The 2D carry made Lantern Keep's own platform code count the platform's speed twice: a game that added the platform's
  velocity itself must drop that code.
- M24.9 changed the publish `dryRun` texts without regenerating COMPONENTS.md; M24.12 and M24.14 regenerated it.

## M24.15-M24.16. Found by the reference game, layout follow-ups — DONE (PRs #112, #113)

Closes LK/FB-0046 and LK/FB-0047. Each entry has a `Fixed in <commit>` note; Lantern Keep dropped its workarounds in
those two PRs (shop.js and options.js in #112, level_select.js in #113).

- M24.15 Layout now, and panels that wrap (PR #112, `62f24f9`): `ui.layout()` applies autoSize, fit sizes, the
  ScrollList fill, positions and the fallback choice at once, so a script reads `Button.size`, `Panel.size` and
  `ui.rectOf` after a text change with no `game.step` (a script's layout does not log the fit warning; the frame's own
  does). `Panel.fallbackLayout` (none / row / column / grid) is used instead of `layout` when the panel's content, or
  the outermost `fit` panel around it, would not fit the screen; the deepest panels switch first, every frame.
  `Panel.usingFallback` (read-only) says which layout is used, and `ScrollList.fill` follows it. Lantern Keep's shop
  column falls back to a row, options.js reads a tab's height after `ui.layout()`, and the level select's rows and
  worlds switch by `fallbackLayout`.
- M24.16 Siblings of one size (PR #113, `7b57f09`): `Panel.uniformSize` gives every `autoSize` Button, Toggle and Slider
  in the panel's active subtree the size of the largest one, width and height separately, on every layout, right after
  the autoSize step. The autoSize memo records that size as the applied one, so the buttons shrink back when the longest
  label gets shorter; widgets without `autoSize` keep their size and do not count. Lantern Keep's `select_worlds` has
  `uniformSize`, and level_select.js drops its label measure and its common-size writing.

## M21. Docs and material for shipping — DONE (PRs #115-#124, the `m21/reference-game` and `m21/ai-cost-guide` PRs)

Closes D-01..D-05, D-07 and the store-page notes of the external evaluation: a reference game, docs marked by version, a
publishing guide per store, a "finish your game" guide, tutorials for people, a browsable API reference, an AI cost
guide and store page material. Every guide is embedded in the binary and listed by `factoria docs`; a replay can be
written to a video file.

The reference game came first (the `m21/reference-game` PR, 2026-10-19), because the guides are better written with it
in hand. **Lantern Keep** (`examples/lantern-keep`, its README) is a 2D platformer, six short levels in two worlds, built
the way a game maker's AI builds a game (the generated AGENTS.md, `factoria docs`, the public commands, no engine change)
in six worker packages: core game and the menu kit (P1), three save slots, level select, a versioned save format and
cloud saves (P2), achievements, stats, leaderboards and a cosmetics shop on the fake store (P3), accessibility: text size,
assist mode, reduced effects, hazards readable without colour (P4), shipping: export and publish settings, icon, touch
gamepad, store texts and `SHIPPING.md` (P5), German and Arabic with every screen checked in four languages at 100 % and
200 % text (P6). 120 tests; ctest runs it as `example_lantern-keep_*`. It found 45 feedback entries, none a blocker or
major, so M10-M18 held up for a complete small game; most became M24.

The rest closes LK/FB-0014, LK/FB-0017 and LK/FB-0022; LK/FB-0023 stays open for M23's MSIX export. Each entry has a
`Fixed in <commit>` note; Lantern Keep dropped its workarounds in #116 and #117 (tools/make_icon.py,
tools/make_screenshots.py).

- Export table (PR #115, `02b1555`): docs/EXPORTING.md has "What each export needs", one row per export: the download or
  tool it needs, and for a Windows, Linux and macOS host whether a source build can make it offline, after a setup
  download, or not at all. Its "Microsoft Store" section says what the engine covers (the Windows folder export) and the
  steps to take by hand.
- Game icon without a provider (PR #116, `0e49b93`): `assets.draw_icon @tools/icon.json` draws the 1024x1024 icon and the
  432x432 Android foreground from shapes, gradients and text, on the CPU, so it needs no provider and no Python and gives
  the same bytes on every machine (docs/ASSETS.md). The files are recorded as original, and the export uses them.
- Render scale (PR #117, `97f693c`): `game.screenshot {scale}` (0.25 to 4) and `factoria run --render-scale S` (also
  `factoria screenshot --render-scale`) draw the same frame at a larger native size, sharp, with the same HUD and visible
  area. Lantern Keep's store screenshots are made that way instead of being enlarged with Pillow.
- Publishing guide (PR #118): docs/PUBLISHING.md, a "which store first" table and one checklist per store (Steam, Epic,
  GOG, Microsoft Store, Google Play, App Store, itch.io, own website): what FactorIA does, linked to its EXPORTING.md
  section, and what the developer still does by hand; store facts as of 2026-10.
- "Finish your game" guide (PR #119): docs/FINISHING.md, from a playable prototype to a game ready for a store in eight
  recipes with Lantern Keep's code (menus, options, saves with versions and migration, languages, accessibility, the
  platform services, credits and crash reports, tests) and a checklist. Its saves section is the M21 part of LK/FB-0013.
- Store page material (PR #121): `assets.draw_capsules` cover-crops one key art around a focal point and places a logo
  (an image or title text, drawn by `assets.draw_icon`'s rasterizer) at every image size of Steam, Epic, GOG, Microsoft
  Store, Google Play, the App Store and itch.io (one table, as of 2026-10; GOG and itch.io sizes not confirmed by an
  official page), into `store/capsules/<store>/`. `factoria run --headless --input replay.json --record-video out.avi`
  draws every frame at `--render-scale` into a Motion-JPEG AVI with the run's audio (no dependency; about 2 GB at most,
  stopped early past it); `.mp4` (H.264 + AAC) goes through ffmpeg, found like the store uploaders by one shared lookup
  (`find_machine_tool`). Lantern Keep has its key art, `tools/capsules.json` and a trailer replay.
- Versioned docs (PR #122, `6e9d3c7`): tools/common/api_since.json says which release added each component, field and
  command, filled in from the `factoria api --json` of every release from v0.1.0 to v0.1.6. docs/COMPONENTS.md,
  `factoria api` (`--md`, `--json`, `--dts` with `@since`) and MCP print "(Since 0.1.x)" or "Not released yet". The test
  `api_since` lists the lines a new entry needs and, once CHANGELOG.md has no "Unreleased" section, every `"unreleased"`
  left to replace. The hand-written guides carry no marks.
- Tutorials (PR #124): docs/FIRST_GAME_WITH_AI.md, six rounds with the editor and an AI from `2d-platformer` (the prompts
  word for word, what to look for, and undo: Ctrl+Z for scene edits, git for scripts and tests); docs/MAKE_BY_HAND.md,
  Gem Grab by hand from `2d-empty`, each file whole with its check (`validate`, `screenshot`, `run --headless`, `test`,
  `export`). The finished game is the fixture tools/cli/tests/fixtures/gem-grab, which ctest validates and tests, and a
  cli test fails when a file the guide shows differs from it. `docs.search` puts each doc's best section first, so the
  tutorials do not push the scripting reference out of the top hits.
- API reference (PR #123): `docs.write_reference {"out":"docs"}` writes docs/COMPONENTS.md and docs/reference/ (an index
  of every component and command with its version mark, then one page per component category and per command category)
  with the same generators as `factoria api --md`: sorted, LF only, the same on every OS. The test `api_reference` fails
  when the committed files differ and names the command to run. The pages are not embedded in the binary; AIs get the
  same data from `docs.components` and `docs.commands`.
- AI cost guide (the `m21/ai-cost-guide` PR): docs/AI_COSTS.md says what is billed (token kinds and prices, API key or subscription plan,
  asset providers), what Lantern Keep cost (466 model requests, about $20 at API prices, a floor), what makes a run
  cheap or dear, how to cap it (`limits` in ai.json, `--max-turns`, `--max-cost`) and where to see what was spent (the
  editor's usage lines, the summary of `factoria ai run`, the run transcripts).

## M22. Production quality and legal — DONE (PRs #126-#132 and the `m22/bookkeeping` PR)

Closes Q-04, Q-05, the subtitles of Q-06, U-05 (text size was M14's) and LK/FB-0037 and LK/FB-0038. Planned in #126
(2026-10-20, against `4553805`): versioned saves with migration and age ratings were already done (M21), the GDPR/COPPA
consent screen moved to M12's ads with consent (the engine collects nothing), and the system's settings became
`game.accessibility` because `platform` is the store services. Six worker packages, at most three building at once.
LK/FB-0037 and LK/FB-0038 have a `Fixed in <commit>` note; Lantern Keep does not use the features yet, the menus fixture
(tools/cli/tests/fixtures/menus) has an option for each.

- Colour filters (M22.2, PR #127, `972974b`): `Camera.colorFilter` (`none`, `greyscale`, `highContrast`, `protanopia`,
  `deuteranopia`, `tritanopia`) is the last post-process of the frame on every backend (shader `colorfilter.glsl`), HUD
  included, so screenshots and `--record-video` show it. The colour-blind modes are daltonize corrections (Machado 2009
  matrices, severity 1.0, then Fidaner's shift of the lost information). For checks, `simulate` of `game.screenshot` and
  `factoria run --screenshot-simulate` save a screenshot as a colour-blind viewer sees it, on the CPU, without changing
  the game. Goldens `2d_filter_*.png`; the menus fixture's Video tab cycles the filter.
- Text to speech (M22.4, PR #128, `8d40daa`): `ui.speak(text, { interrupt })`, `ui.stopSpeaking()` and
  `ui.speechAvailable`, in `i18n.language`: SAPI 5 on Windows, AVSpeechSynthesizer on macOS and iOS, TextToSpeech
  through JNI on Android, speech-dispatcher loaded at run time on Linux, `speechSynthesis` on the web (voices on the
  device first, #130). Also the commands `ui.speak` and `ui.stop_speaking`. Headless runs and tests speak nothing and
  record the lines (`game.spoken()`). The menus fixture reads the focused widget aloud behind a "Read menus aloud" option
  (`scripts/ui/read_aloud.js`, `tests/speech.test.js`).
- Performance budgets (M22.1, PR #129, `441405b`): the headless run report has `perf` (process CPU time per frame avg,
  p95 and max, peak memory, draw calls, entities, the graphics), and `perf.measure`, `perf.baseline` and `perf.check`
  measure a project and compare it with a budget file keyed by runner (`<os>-<compiler>-<renderer>`). A limit is
  `max(baseline * (1 + ratio), baseline + slack)`: CPU +100 % average and +150 % p95, memory +10 %, draw calls and
  entities +10 %. ctest runs `example_<name>_perf` for each example against `tools/cli/tests/perf/` and
  `perf_regression_detected`, which must fail. The bookkeeping PR added `requireBaseline`, so the engine's CI fails on a
  runner with no baseline instead of passing unchecked. With it, the CI runners printed their own entries: macOS's are
  new, and Windows's replace the ones measured on a PC with `FACTORIA_D3D11_WARP=1` (the runner's adapter, the Microsoft
  Basic Render Driver, is WARP and now has that runner id). gem-roller's Linux entry also comes from the runner (#132):
  GitHub's Linux runner uses about 25 MB more than WSL. docs/PERFORMANCE.md.
- Privacy policy and EULA (M22.6, PR #130, `67fe125`): docs/LEGAL.md says what the engine sends (nothing by itself),
  has a privacy policy template for a game that collects nothing and the paragraphs to add for analytics, ads, accounts,
  cloud saves or crash uploads, when a game needs an EULA beyond the stores' own, and a checklist. It says it is not legal
  advice; PUBLISHING.md, FINISHING.md, GETTING_STARTED.md and the README link it.
- The system's accessibility settings (M22.3, PR #131, `40ebbeb`): read-only `game.accessibility` `{ textScale,
  reduceMotion, highContrast, screenReader }`, read like the system language (`engine/platform/src/accessibility_*`:
  Windows `SystemParametersInfo` and `TextScaleFactor`, macOS NSWorkspace, iOS UIAccessibility, Android through JNI,
  Linux GNOME through `gsettings`, web `matchMedia`) when the game starts and again on focus or resume; `textScale` is
  clamped to 0.5-4. Only a game in its own window reads the system; `game.setAccessibility` sets it in tests. The menus
  fixture starts text size, reduced effects and "read menus aloud" from it on the first run.
- Captions (M22.5, PR #132): a `Captions` UI component (a box like any widget, `maxLines`, text styled like `Text`, with
  `ui.textScale`, the language's font chain and right to left), fed by `audio.play(path, { caption, captionKey, speaker,
  captionSeconds })` while the sound plays and by `ui.caption(text, seconds, { key, speaker })` (commands `ui.caption`,
  `ui.clear_captions`). A `key` follows a language change. `game.captions()` in tests; golden `2d_captions.png`; the menus
  fixture has a "Subtitles" option and `scripts/dialogue.js`.
- Bookkeeping (the `m22/bookkeeping` PR): docs/FINISHING.md section 5 lists the four features, CHANGELOG.md, this
  section, and LK/FB-0037 and LK/FB-0038 marked fixed.

## M20. Editor and tooling — DONE (PRs #134-#142, the `m20/debugger` and `m20/finish` PRs)

Closes H-01, H-02, H-03, H-05, H-09, the editor part of H-06 and LK/FB-0009. Every hand edit in the editor goes through
the commands the AI uses, so Undo and the scene file work as they do for any command.

- ASCII map edits (M20.1, PR #134, `9b92c45`): `scene.ascii_edit {file, ops, rebuild?, dryRun?}` edits the `rows` of a
  `scene.import_ascii` args file with ops applied in order, all or nothing: `fill`, `replace` (the whole map or a
  rectangle), `insertColumns`, `deleteColumns` and `put` (at a row, or above the ground of a column). Errors name the op
  and suggest legend glyphs. A file with a `path` is rebuilt through `scene.import_ascii`, whose `spawned` list (every
  object's glyph and cell) comes back merged. AI_GUIDE 9.8.
- Profiler (M20.2, PR #135, `bee7853`): `fa/core/profiler.h` times 12 engine systems and every behaviour class (own ms
  and calls per frame), the GPU frame through timer queries (D3D11 and GL; Metal, GLES3 and WebGL2 say why not) and
  memory (process, JS heap, textures, decoded audio). Off by default, and it only measures: state, replays and saves are
  byte-identical with it on. In `play.report` (`profile`), `perf.profile` and View > Profiler. `perf.*` inside a process
  that already has a graphics device fail with `gpu_busy` instead of aborting. docs/PERFORMANCE.md.
- Editor autotests on Windows (M20.3a, PR #136, `4f59ba4`): `ui::read_backbuffer` reads the D3D11 swap chain, so
  `editor_autotest` and `editor_autotest_welcome` run on Windows like on Linux and macOS.
- Hierarchy and Inspector (M20.3b, PR #137, `0ccdef0`): the entity tree (selection shared with the viewport, drag to
  re-parent, context menu, search) and an Inspector built from reflection (a widget per field kind, the doc string as
  tooltip, Add Component, one Undo step per drag, refused values shown under the field, edits to the running game taken
  back by Stop). `MeshRenderer.material` shows the material's compile error, and `materialParams` is typed by
  `material.info`. New command `scene.set_parent`.
- Transform gizmos (M20.3c-1, PR #139, `8da7a4e`): select, move, rotate and scale (Q, W, E, R) in 2D, 3D and screen
  space, Ctrl (Cmd on macOS) to snap, Esc to cancel; a whole drag is one `scene.set_component` Undo step.
- Project panel (M20.3c-2, PR #142, `78257ce`): the project's files with a folder tree, thumbnails, a type filter and a
  search; drag a file onto an Inspector field of its type or a prefab onto the viewport, double-click a scene to open it,
  show in the file manager, copy the path, delete. `asset_type_of` is the one asset classifier (`assets.list` reports
  `material` too).
- Script debugger (the `m20/debugger` PR): breakpoints (conditions, hit counts, logpoints), stepping, pause, exception
  stops, the call stack, variables, watches and the debug console for the project's JavaScript, in VS Code. QuickJS-ng
  has no debug API, so a debugged run compiles every project module from a copy instrumented with acorn (vendored in
  `external/acorn`, tooling only: exported games are never instrumented): a hook before each statement, a frame record
  per call and one closure per frame that evaluates in its scope. The runtime is `fa::ScriptDebugger` in `fa_script`,
  given to the engine in `EngineConfig::scriptDebugger`; `factoria dap` is the Debug Adapter Protocol server (launch
  modes play, headless and test); the setup component `vscode` installs the extension (`tools/vscode`) into VS Code,
  Insiders, VSCodium and Cursor, and new projects get `.vscode/launch.json`. `script.trace` gives an AI the same
  breakpoints on a headless run as JSON. Design: docs/design/SCRIPT_DEBUGGER.md; docs/DEBUGGING.md.
- Revert an AI run (the `m20/finish` PR): `fa/tooling/checkpoint.h` saves the project's files content-addressed in
  `.factoria/checkpoints/` (sha256 objects, one manifest per checkpoint, a stat cache that trusts size and mtime only
  for files older than 2 s, the newest 30 kept and unused objects deleted, every write through a temp file and a rename).
  Commands `checkpoint.create`, `checkpoint.list`, `checkpoint.diff` and `checkpoint.restore`; a restore checks that every
  object is there before it changes anything and first saves a "Before restoring" safety checkpoint. The editor takes
  one, plus the open scene in memory, before every AI run; the transcript's "This run changed N files" has Revert (files
  back, the scene as one Undo step, scripts reloaded), the "Reverted" item has Undo revert, Edit > Revert Last AI Run
  does the newest, and the next prompt tells the AI. Editor autotest section P. docs/EDITOR.md, "Revert an AI run".
- Screenshots folder (the `m20/finish` PR): the Screenshot toast has "Show in Finder / Explorer" (a toast can carry one
  button; it stays while hovered), and File > Open Screenshots Folder.
- Hand-written scenes in `factoria validate` (the `m20/finish` PR): no warning any more; the report has informational
  `notes` (text, `--json`, `project.validate`, the editor's Validation window) with one note naming the files whose
  layout differs from `scene.save`'s and the optional `scene.format`.

## M25. A second reference game: 3D and mobile — DONE (the `m25/reference-game` PR)

Lantern Keep (M21) is a 2D desktop game, so the feedback loop had never seen production 3D (M18), touch as the main
input, a game on phones and in a browser, the asset import pipeline (M15) with real packs, captions and
`game.accessibility` (M22) in a game, or a CJK language. **Clockwork Courier** (`examples/clockwork-courier`, its README
and `SHIPPING.md`; feedback ids `CC/FB-n`) is that game: a wind-up robot delivers parcels across six short 3D levels in two
districts, the Rooftops by day and the Night Market by night, before its spring runs down, while guard dogs patrol and
chase it. It was built like Lantern Keep, by game-maker AIs (Sonnet workers) with the generated AGENTS.md, `factoria docs`
and the public commands, in seven packages (planned 2026-10-22 against `3eeac02`):

- P1 courier, camera and touch: `CharacterController3D`, an `Animator` state machine with footstep events, a follow
  camera that does not go through walls, touch orbit and pinch, the on-screen controls, and the contracts the other
  packages build on (level list, progress, game events).
- P2 world: six levels from the kits, parcels, delivery doors, wind-up keys, checkpoints, guard dogs, crates, hinge gates,
  a seesaw, a rope bridge, day and night lighting, music per district, 3D particles, a loading screen, and a bot that
  finishes every level by its main route and its expert shortcut.
- P3 progress and saves: stars per level, the level select, a named profile with an on-screen keyboard, cloud saves, a
  daily route.
- P4 store services: achievements, leaderboards and a paint shop on the fake store, a rewarded "more time" offer and a
  "remove ads" purchase.
- P5 mobile comfort and accessibility: graphics quality and a frame-rate cap, haptics, pause on suspend, Android Back
  everywhere, a left-handed layout, control size and opacity, camera sensitivity, reduced motion, assist mode, captions
  for sound cues, markers readable without colour.
- P6 shipping: a studio intro, the icon, key art and capsules, store texts in three languages, store screenshots and a
  trailer recorded by the engine (both rebuilt by scripts, not in git), the Apple plugin (`Products.storekit` on export),
  a render and perf budget, and the exports run on the iOS Simulator, an Android emulator, a browser pane and macOS.
- P7 languages: Spanish and Japanese (a Noto Sans JP subset, line breaks without spaces), every screen at 100 % and
  200 % text.

Assets are CC0 only, imported with `assets.import` and recorded in `assets.json`: Quaternius' RobotExpressive, Kenney's
Fantasy Town Kit, Platformer Kit, Cube Pets, Impact Sounds, Interface Sounds and Music Jingles, and three OpenGameArt
loops. `factoria test` runs 444 tests; ctest runs the game as `example_clockwork-courier_*` (validate, test, perf).

It reported 52 entries, 11 of them major: unlike Lantern Keep, a complete 3D phone game still needs workarounds the
engine should remove (the ranked list in [ROADMAP.md](ROADMAP.md)). One was fixed on the way: CC/FB-0033 (`cc2f059`),
3D joints were solved in the order of their entity ids, so a rope bridge behaved differently after other scenes; they are
now solved in the scene's entity order and `Physics3D::reset()` drops joint state.

## M26. Found by the second reference game — DONE (PRs #149-#176 and the `m26/bookkeeping` PR)

What Clockwork Courier (M25: 3D, mobile first) found, triaged 2026-10-22. Eleven entries are major: each forced the
game's AI into a workaround a store game should not need (a Python script that rewrites glTF files, a letter grid for
names, a wall-clock date). Ordered like M24, by score (occurrences x severity weight) per unit of size, with two
exceptions: a package that needs another one comes after it, and packages that edit the same files say so (one worker
after the other, never two at once). Each ships with its doctest or JS test and its docs. When one merges, mark its
entries `fixed-in-engine` and let Clockwork Courier drop the workaround (its `workaroundFiles` say where); the store
backends of M12 and M19's video player stay in their milestones.

### M26.1 Commands write only what they change (S) — CC/FB-0016, CC/FB-0047

Done (#150, merge `7566e5b`): `scene.format` without `paths`, `all` or `check` writes nothing and teaches;
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

Done (#151, merge `299cd69`): kinematic platforms carry a character (displacement and turn;
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

Done (#152, merge `5f3900a`): `game.today()`, `game.setDate`, `--date` and the replay date;
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

Done (#155, merge `c71f1cc`): rigid skins for meshes on animated nodes, one palette per skin, Clockwork Courier
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

Done (#153, merge `7e0cd19`): `.glb`/`.gltf` import copies its uri files and warns on a name clash; validate
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

Done (#154, merge `060ca42`): `autoShrink`/`minFontSize`/`maxTextScale`, Toggle/Slider `maxWidth`, `labelAbove`,
`ui.overflowed`, one shared fit path (text_fit.h); Clockwork Courier uses them.

### M26.7 Scene and asset preload with progress (M) — CC/FB-0012

Done (#161, merge `d9bfb84`): `scene.preload` / `assets.preload` read ahead, 4 files per test frame, CC loading.js.

M19's `scene.loadAsync`, which a game now needs. `scene.preload(path)` and `assets.preload([paths])` return a handle
with `progress` (0..1), `done` and a Promise; they load within a time budget per frame (a worker thread later, L), so a
loading screen animates while a scene loads, and `scene.load` of a preloaded scene is immediate. MENUS.md gets a
loading-screen recipe.

Acceptance: a script test preloads a scene with several models and sees `progress` grow over more than one frame, then
loads it with no new file read; a loading-screen fixture keeps drawing frames while it loads.

### M26.8 Store fake and catalog in scripts (S) — CC/FB-0024, CC/FB-0025, CC/FB-0029

Done (#156, merge `49f77b3`): `platform.revoke` and `game.platform.revoke(id)` (a refund and its `revoked` purchase
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

Done (#163, merge `3669375`): `platform.ads`, `platform.release`, leaderboard `period`, fake ads; Courier uses them.

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

Done (#159, merge `016421a`): `NavMesh3D` baked from the static colliders into a deterministic 2.5D grid
(`fa/physics/nav.h`), `nav.bake`, `nav.find_path`, `nav.info` and `nav.findPath` in scripts, `Collider3D.navObstacle`
for moving obstacles, editor "Show navmesh"; docs/NAVIGATION.md. Clockwork Courier keeps its own scripts/nav.js for now.

M19's navmesh, which a game now needs. A `NavMesh3D` component baked from static colliders (`nav.bake`, with the
agent's radius, height, step and slope), `nav.find_path` and `nav.findPath(from, to, {radius})` in scripts next to
`physics.raycast3d`, a debug draw in the editor, and moving obstacles through a dirty flag. M19's grid A* on a Tilemap
and the behaviour-tree helper can share the search later.

Acceptance: `fa_test_physics` (or a new module's) cases on a fixture with walls, a ramp and a step too high; a script
test where a guard reaches the player around a wall; the bake is the same on every run.

### M26.11 Test API gaps (M) — CC/FB-0005, CC/FB-0006, CC/FB-0018, CC/FB-0026, CC/FB-0038, CC/FB-0044

Done (#172, merge `1474bc1`): `game.mouseDown/mouseUp/wheel`, `game.resetState`, `game.quitRequested` (a quit in a test
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

Done (#162, merge `7921217`): `keyArgs`, `TouchButton.key`, validate checks args; Courier uses them.

- `keyArgs` on `Text`, `Button` (`UiControl`) and `TouchButton`: the values of a key's `{placeholders}`, passed to
  `i18n.t` when the text is localized (localize.cpp), so a script sets `keyArgs` once instead of rewriting `text` every
  frame, and a language switch keeps them.
- `TouchButton` gets `key` like the other widgets.
- `factoria validate` checks a key's placeholders against the entity's `keyArgs` instead of warning about every key
  with placeholders.

Acceptance: `fa_test_scene` cases: a score label with `keyArgs` in two languages, a switch at run time, a TouchButton
with a key; validate warns only for a placeholder with no arg.

### M26.13 Locale-aware numbers (M) — CC/FB-0039

Done (#169, merge `aae84c3`): `fa/core/number_format.h` (table of separators and digits), placeholders `{v:number:N}` and
`{t:duration:N}`, `i18n.number` / `i18n.duration`, section 5b of LOCALIZATION.md; Courier's `fmt.js` calls them.

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

Done (#167, merge `bb13ed0`): start-overlap warning and validate, `Joint3D.stalled`, `damping`, joint islands, chains.

### M26.15 Graphics quality and render stats (M) — CC/FB-0036, CC/FB-0050

- `window.renderScale` (0.5..1, wired to the renderer's render scale), `window.supports(feature)` and `game.device`
  (`formFactor`, `gpuBackend`, a `tier` from the GPU and memory) for quality presets. The frame cap still throws where
  a phone cannot honour it; SCRIPTING.md says to read `window.supports("frameCap")` first.
- `game.renderStats()` in tests draws a frame when none has been drawn yet (today `game.state().renderStats` is zero
  headless) and adds `shadowCasters`; `perf.measure` records triangles, lights and texture memory, and `perf.check`
  takes budgets for them (`maxTriangles`...).

Acceptance: script tests for the render scale (the drawn size changes), the device fields headless, and render stats
of a fixture scene; a `perf.check` with a triangle budget fails when the scene goes over it.

Done (#166, merge `1ecb685`): `window.renderScale`, `window.supports`, `game.device` (fixed headless,
`setDevice` in tests), `game.renderStats()` drawing on demand with `shadowCasters`/`textureMB`, `game.render_stats`;
`perf.measure` records triangles/lights/textureMB and `perf.check` takes `budgets`; Clockwork Courier uses them.

### M26.16 Per-material colours (M) — CC/FB-0031

Done (#173, merge `c70c58b`): `MeshRenderer.materialColors` (replaces the glTF base colour factor of the named
material, `color` still tints the whole model, part of the batch key) and the `factoria validate` check with a "did you
mean"; Courier's `paints.js` can drop its dark-tint-plus-emissive trick (not changed in this package).

After M26.4 and M26.15 (the same model and renderer code). `MeshRenderer.materialColors` is an object keyed by glTF
material name, `{"Body": [0.2, 0.8, 0.7, 1]}`, applied per sub-mesh (the sub-mesh keeps its material name) and part of
the batch key; `factoria validate` checks the names against the model with a "did you mean".

Acceptance: a render test where one material of a two-material model changes colour and the other does not; validate
suggests the right name for a typo.

### M26.17 Text entry on every device (M) — CC/FB-0020, CC/FB-0052

Done (#171, merge `4832aa4`): the UI raises the phone's keyboard on focus, the MENUS.md kit has an on-screen keyboard
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

Done (#174, merge `f13577d`): `ui.set_slider` / `game.setSlider`, `Slider.format` and `formatKey`, `ScrollList.shrink`;
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

Done (#164, merge `069466c`): Products.storekit per language without the plugin; Android CMake from the SDK
or the system (`cmake.dir`); build fingerprint check (`--allow-player-mismatch`); `setup ffmpeg`.

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

Done (#168, merge `570a112`): `World::set_parent(..., index)`, `scene.set_parent {index}`, `scene.spawn {index, overrides}`,
`entity.setParent(parent, keepWorld, index)`, `world.spawn(json, {parent, index})` (an index outside 0..number of the
parent's other children is an error; a root takes no index); prefab references take `overrides` for the prefab's
descendants (by id, name or path) and `world.spawnPrefab(path, {childOverrides})` the same; docs/MENUS.md.

- A child can be put at a place among its siblings: `World::set_parent` with an index, `scene.set_parent {index}`,
  `entity.setParent(parent, keepWorld, index)` and `spawn({parent, index})`.
- MENUS.md shows a panel shared between scenes as a prefab; a prefab instance can override its children's fields
  (`overrides` in `expand_prefab`), so one panel serves two scenes with different texts.

Acceptance: `fa_test_scene` cases for each.

### M26.21 Physics determinism across platforms (S-M) — CC/FB-0055

- AI_GUIDE.md and SCRIPTING.md ("Tests") say what holds: the same build on the same platform gives the same result;
  another compiler or CPU may not.
- The engine builds with no floating-point contraction (`-ffp-contract=off`, `/fp:precise`) and the simulation uses its own
  deterministic sin/cos/atan2/asin/acos (`fa::det::`), so the same source gives the same numbers on every platform; CI
  compares a replay's hash with one committed value on the Linux, Windows and macOS jobs.
- `factoria:test` has a helper that runs a check under small perturbations, so a level test asserts what is robust
  instead of an exact frame count.

Acceptance: the replay hash matches across CI's Linux, Windows and macOS jobs, or the docs list where it does not.

Done (#175, merge `34ab785`): every target builds with `-ffp-contract=off` / `/fp:precise` and `-fmath-errno` (root
CMakeLists.txt; per-module flags were not enough, see the comment there). The first CI run showed a different hash on each
platform, from the C library's sin/cos/atan2/asin/acos (Euler angles of every world matrix, quaternion turns, hinge angles,
round collider sampling). They are replaced on the whole simulation path by `fa::det::` (`engine/core/include/fa/core/
det_math.h`: doubles, `+ - * / sqrt` only, range reduction and Taylor series; test_det_math.cpp checks accuracy against
`std::` and commits exact bit patterns), also behind `Quat`, `Mat4::rotate_*` and `from_angle_deg` in math.h; `std::hypot` in
the nav grid became `sqrt`. Box2D has its own cos/sin/atan2 (checked: v3 `b2ComputeCosSin`/`b2Atan2`), so its 2D part now
matches Windows' on the Mac. The test `physics_determinism` (`engine/physics/tests/test_determinism.cpp`) compares a replay
hash with ONE committed value on each CI job (no per-platform table) and prints `FA_PHYSICS_REPLAY_HASH`. `robust()` is in
`factoria:test`; Clockwork Courier's shortcut test uses it. The last Windows difference was the sign of a zero: `det::atan2`
took |y| as `y < 0 ? -y : y`, which keeps -0, and MSVC (even with `/fp:precise`) compiles that as `fabs`, so `asin(-0)` was
+0 with Clang and GCC and -0 with MSVC; it uses `std::fabs` now (a Clang build with `-fno-signed-zeros` reproduced MSVC's
hash locally). One hash holds on the Linux, Windows and macOS jobs; FB-0055 is fixed.

### M26.22 Menu kit command (M) — CC/FB-0003

Done (#176, merge `c944641`): `project.add_menu_kit` (tools/common/src/menu_kit.cpp), the kit in `templates/menus/` with
`kit.json` listing its parts; the menus fixture keeps a copy of every kit file that the `cli` test "the menus fixture holds
exactly the kit's files" keeps identical.

After M26.1 (the kit is formatted on write). The menus recipe moves to `templates/menus/` (scenes, prefabs, scripts and
locale keys), MENUS.md shows it from there, and `project.add_menu_kit {parts, overwrite}` copies the parts asked for
into a game and merges their keys into its locale files.

Acceptance: a tooling test adds the kit to a new project, which then validates and passes the kit's own test; adding it
twice changes nothing.

### M26.23 UI layout check (M) — CC/FB-0043

Done (#170, merge `057a8e6`): `ui.check_layout` (engine/runtime/src/ui_check.cpp), `I18n::set_pseudo`; Courier's
intro and profile keys shrink; its remaining findings are in its ENGINE_FEEDBACK.json notes.

After M26.6. `ui.check_layout {scenes, languages, textScales, pseudo}` loads each screen in each language and text scale
(and a pseudo-localized one that lengthens every string), and lists every text that overflows or overlaps, with the
entity and the key.

Acceptance: a tooling test on the menus fixture finds a planted overflow at 200 % in German and nothing else.

Close-out (the `m26/bookkeeping` PR, 2026-10-24): Clockwork Courier dropped the workarounds of the fixed entries. The
dog and tap-to-move walk on a `NavMesh3D` per level (`nav.findPath`; crates and gates are `navObstacle`s), and the
game's own grid (scripts/nav.js) is gone. The eight level scenes instance three UI prefabs (HUD, results, retry);
`more_time.js` spawns its button with `index: 0` in the retry row; the name screen uses the menu kit's keyboard; the
paints set `materialColors`; the stars are ★ and ☆; four lists use `shrink`; and `ui.check_layout` reports no issue in
any scene, language or text scale. Its tests reset with `game.resetState`, pick the system language with
`game.setSystemLanguages` and drive the mouse and the wheel. SHIPPING.md uses the Android export and
`--allow-player-mismatch`. The game has 458 headless tests. CC/FB-0051 (playing a video) stays open for M19, and moving
onto the navmesh found CC/FB-0056 (no bridge or moving platform in the mesh), ranked in M19 too.

## M27. What the games asked of M12 and M19 — DONE (PRs #179, #180, #182-#185 and the `m27/bookkeeping` PR)

Planned 2026-10-24, against `cf6852c`: the first three packages of M12's ranking and the first two of M19's, the only
ones a game asked for. Ads are two packages, one per platform. Each ships with its doctest or JS test and its docs.
Packages that edit the same files say so: one worker after the other, never two at once. When one merges, its entries
get a `Fixed in <commit>` note (the bookkeeping PR at the end) and Clockwork Courier drops what it no longer needs.
Order of work: M27.1, M27.5 and M27.6 first (three builds at once); M27.3 when one of them is done; M27.2 after M27.1;
M27.4 after M27.3.

### M27.1 Ads with consent on Android: Google UMP and AdMob (L) — CC/FB-0028

Done (#183, merge `bb4dcc9`): a plugin backend that offers only `ads` runs next to the store backend (`adsBackend`
and `adsWhy` in `platform.state`); the `admob` plugin for Android (UMP, then the Mobile Ads SDK, one kept rewarded ad
per placement); `platform.ads.audience`, `setUnderAge`, `privacyOptions`; the kit's `ageGate` part and its "Ad
privacy settings" button; the app id in the manifest, Google's test ids in a development export, validate's
warnings; `admob.status`. Checked by hand on a Pixel 7 API 35 emulator: the consent form and Google's test rewarded ad.

- **An ads backend next to the store's.** A plugin backend that offers only `["ads"]` is an ads backend: the engine
  sends `ads.*` to it and everything else to the store backend, so a game on Google Play has both. `platform.ads.backend`
  picks one when several load; `platform.state` shows `adsBackend` and why. Development and tests keep the fake.
- **`platforms/plugins/admob`** (the `"admob"` template, `platform.add_backend {"backend": "admob"}`): a C bridge (JNI,
  like googleplay's) and a Gradle module on the Google Mobile Ads SDK and the User Messaging Platform. On start it asks
  UMP for consent (Google's GDPR form where it applies), then starts Mobile Ads; `ads.available` loads and keeps one
  rewarded ad per placement, `ads.showRewarded` answers `{rewarded: true}` only on the reward callback, `ads.consent`
  maps UMP's status (`tracking` is `"notRequired"` on Android). The AdMob app id is in the catalog
  (`platform.ads.appIds.android`) and the export writes it into the manifest (the SDK stops the app without it). A run
  that is not `platform.release` always uses Google's test app id and test ad units, so development never shows a live
  ad; `factoria validate` warns about a release export with Google's sample ids or no app id.
- **COPPA and privacy options.** `platform.ads.audience`: `"general"` (default), `"children"` (every request tagged
  child-directed) or `"mixed"`: the game asks the age first with the menu kit's new `ageGate` part (a neutral birth-year
  screen, `project.add_menu_kit {"parts": ["ageGate"]}`) that calls `platform.ads.setUnderAge(bool)`; the engine keeps
  the answer and sends it to UMP and AdMob (under the age of consent, child-directed). `platform.ads.privacyOptions()`
  opens UMP's privacy options form when `consent().privacyOptions` is `"required"`; the kit's options screen shows that
  button only then. The fake answers all of it.
- Docs: PLATFORM.md's ads section (setup, test ids, release, consent, COPPA, manual checks), MENUS.md (the age gate),
  MOBILE.md (the manifest entry).

Acceptance: platform tests: an ads-only plugin backend gets `ads.*` while the store backend gets the rest;
`setUnderAge(true)` reaches the backend's requests; the kit's age gate test. Tooling tests: `add_backend` (dry run and
real), the manifest of an export with the app id, validate's warnings. Manual check on an emulator with Google Play
services (a Google APIs image): an exported Clockwork Courier shows Google's test rewarded ad and grants the 20 s (steps
in PLATFORM.md; CI's emulator has no Play services, so it checks that the bridge answers, like googleplay's).

### M27.2 Ads with consent on iOS: AdMob, UMP and App Tracking Transparency (M-L) — CC/FB-0028

Done (#185, merge `35b0277`): the plugin's Swift side (UMP, then Apple's tracking sheet only with `trackingPrompt`
and never for a player under age, then the SDK); `xcframeworks` and `infoPlist` in a plugin's `ios/plugin.json`;
`GADApplicationIdentifier`, `SKAdNetworkItems` and a translated `NSUserTrackingUsageDescription` in the export;
`add_backend {"sdk"}` copies Google's two XCFrameworks (git ignores them); `ids.admob_ios`. Checked by hand on the
iOS simulator: UMP's form with the EEA debug geography, the tracking sheet, Google's test rewarded ad.

After M27.1 (same plugin).
- iOS plugins take vendored XCFrameworks (M11 left this open): `"xcframeworks"` in `ios/plugin.json` (paths in the
  plugin folder), linked and embedded by the iOS export. Google's SDK is a download, never in the repository:
  `add_backend {"backend": "admob", "sdk": <zip or folder>}` copies it in, like Steam's.
- The plugin's iOS side (Swift, like the apple plugin): UMP first, then the App Tracking Transparency prompt only when
  `platform.ads.trackingPrompt` is true and only after UMP's form; `tracking` in `ads.consent` maps the ATT status.
  Info.plist gets `GADApplicationIdentifier`, `NSUserTrackingUsageDescription` (from the catalog, translated like the
  other plist texts) and Google's `SKAdNetworkItems`. Rewarded ads and test ids as on Android.
- macOS has no AdMob SDK: there the plugin offers no ads and `platform.has("ads")` is false.

Acceptance: tooling tests: an export with a stub XCFramework links and embeds it, and the plist has the keys. Manual
check on the iOS simulator: Clockwork Courier shows Google's test rewarded ad, the ATT prompt and UMP's form with the
EEA debug geography (steps in PLATFORM.md).

### M27.3 Leaderboard periods on the store backends (M) — CC/FB-0030

Done (#180, merge `24d1d4f`): Steam keeps one board per period (`<storeId> <periodKey>`, a handle cache of 64
names), Game Center uses a recurring board's current occurrence or a classic board's `.today` / `.week` scope, Play
Games `TIME_SPAN_DAILY` / `TIME_SPAN_WEEKLY`; `submit` and `entries` carry `periodStart` and `periodEnd` when the
store gives them; PLATFORM.md has each store's period boundaries.

- Steam has no periods: a daily or weekly board is one Steam board per period, `<storeId> <periodKey>`, made with
  `FindOrCreateLeaderboard` with the board's sort order; `entries` reads the current one.
- Game Center: a board whose `ids.apple` names a recurring leaderboard (set up in App Store Connect) is used as it is
  (its current occurrence); a classic one is read with the `.today` or `.week` time scope.
- Play Games: `TIME_SPAN_DAILY` and `TIME_SPAN_WEEKLY` of the same board.
- Each store starts a period at its own time (Apple's recurring boards when App Store Connect says, Google's at midnight
  Pacific time, the engine's at the player's midnight): answers carry `periodStart` and `periodEnd` when the store gives
  them, and PLATFORM.md has a table. These three backends stop rejecting periods with `unavailable`.

Acceptance: `steam_plugin_*` tests against the mock (two days give two boards, the second empty; a weekly board keeps
its week); `apple_backend_tests` send a daily board and get a signed-out answer, not `unavailable`; the Java builds in
the `android-apk` job.

### M27.4 The Steam Deck's own keyboard (M) — CC/FB-0020

Done (#184, merge `06294a1`): plugin API 3 (`add_text_input`, `submit_text`), `input.platformKeyboard`, the
Steam plugin's floating keyboard on a Deck or in Big Picture and the full-screen one where the floating one is not
offered; the kit's on-screen keyboard stays closed while a platform keyboard has the field. `TextField` has no
`multiline` or `password` yet, so the handler gets 0 for both.

After M27.3 (both edit the Steam plugin and its mock).
- Plugin API version 3: `add_text_input` registers a handler the engine calls when a `TextField` takes or loses the
  focus with a gamepad (the field's rectangle in window pixels, its text, `multiline`, `maxLength`, whether it is a
  password); the handler answers whether the platform shows its own keyboard. `submit_text` hands text back to the
  focused field (on the game thread, at the next frame). Version 2 plugins are unchanged.
- The Steam plugin, on a Steam Deck or in Big Picture, opens Steam's floating keyboard (`ShowFloatingGamepadTextInput`:
  Steam types into the window as key presses) and, where that is not offered, `ShowGamepadTextInput`, whose text comes
  back through `GamepadTextInputDismissed_t` and `GetEnteredGamepadTextInput`.
- When the platform keyboard took the field, the menu kit's on-screen keyboard stays closed (a flag the kit's script
  reads); otherwise it opens as today.

Acceptance: runtime tests with a test plugin (a pad focus calls the handler with the rectangle; `submit_text` fills the
field; a version 2 plugin sees nothing); `steam_plugin_*` tests against the mock for both keyboards and the dismissed
text; the kit keyboard's test with a platform keyboard. A real Deck is a manual check (PLATFORM.md).

### M27.5 Video player (L) — CC/FB-0051

Done (#182, merge `c3d102b`): the `Video` component and `entity.video` (`play`, `pause`, `stop`, `seek`, `time`,
`duration`, `playing`, `on("ended")`), pl_mpeg vendored in `external/`, sound through the mixer, time on the game
clock; `assets.import` converts mp4, m4v, mov, webm, mkv and avi with ffmpeg; `factoria validate` checks Video files;
MENUS.md's studio-intro recipe. Clockwork Courier's intro is a 4.8 s, 495 KB `.mpg` recorded from the animated scene
kept in `store/intro/`. To keep the courier's perf budgets on software renderers, plain textured quads use a shader
without the glyph, shape and 2D-light branches, and an opaque `Video` skips its background and blending (about half
the cost of a full-screen video on llvmpipe and WARP); the courier's baselines were refreshed for the video.

- A `Video` component: on a UI entity it fills the control like an image (`fit`: contain, cover or stretch), with
  `path`, `autoplay`, `loop`, `volume` and `bus`; scripts play, pause, stop and seek it and read `time`, `duration` and
  `playing`, and get an `ended` event.
- Decoding with pl_mpeg (MIT, one header, vendored in `external/` with its VERSIONS.md row and its notice): MPEG-1 video
  and MP2 sound in an `.mpg`, the same on every platform, the web included, with no OS decoder. Each new picture is
  converted into a texture; the sound plays through the engine's mixer on the chosen bus.
- Time follows the game clock (it pauses with the game), so tests and replays are deterministic; headless runs keep the
  same time and events.
- `assets.import` of an `.mp4`, `.mov` or `.webm` converts it to `.mpg` with ffmpeg (`factoria setup ffmpeg`, M26.19)
  and records its provenance; without ffmpeg the error names the setup command. `factoria validate` checks the videos
  scenes reference. MENUS.md gets a studio-intro recipe (any button skips it).

Acceptance: a doctest decodes a small committed `.mpg` fixture to the expected colours at known times; a script test
plays it, sees `time` follow the game clock, `ended` once, and a loop; a render test draws a frame into a UI rectangle.
Clockwork Courier's studio intro is a short video made from its animated intro scene, and its tests and perf budgets
pass.

### M27.6 Off-mesh links and walkable moving bodies on NavMesh3D (M) — CC/FB-0056

Done (#179, merge `a4e2d36`): `NavLink3D` (one way or both, with a cost; `nav.findPath` lists `links`),
`Collider3D.navWalkable` re-marked incrementally where the body is, `links` and `walkableBodies` in `nav.bake` and
`nav.info`, links drawn by the editor's Show navmesh. Clockwork Courier's mover, seesaw and bridges are walkable, a
dog follows the courier across a bridge, and `dog.js` makes one query.

- Off-mesh links: a `NavLink3D` component (its entity's position and an `end` point, `bidirectional`, `cost`) joins the
  cells under its two ends; `nav.findPath` may take it, and the result says where (`links`: the index of the point where
  the link starts and the link's entity) so a script can jump or climb there.
- `Collider3D.navWalkable` on a kinematic body or a body held by a joint (a rope-bridge plank, a seesaw, a moving
  platform): left out of the static bake like `navObstacle`, its top surface is added as walkable cells and re-marked as
  it moves (only the cells it left and entered), joined to the ground around it within `stepHeight`.
- `nav.info` and the editor's Show navmesh draw links and walkable bodies; NAVIGATION.md's limits follow.

Acceptance: `fa_test_physics` cases: a link joins two islands (a one-way link refuses the way back); a path across a
walkable plank bridge; a moving platform joins the path when it docks and gives `disconnected` when it is away; the
same path twice is the same bits. Clockwork Courier marks its bridges, seesaw and platforms `navWalkable`, a dog follows
the courier across a bridge, and `dog.js` drops its second query to the nearest point; its perf budgets pass.

## M28. A third reference game: couch co-op on the desktop — DONE (the `m28/reference-game` PR)

Lantern Keep (M21) is a 2D platformer for one player and Clockwork Courier (M25) a 3D phone game, so the feedback loop
had never seen several players at one screen, a world that changes under the players' feet, levels generated from a
seed, a dark world lit by many lights, online features, or the desktop and the Steam Deck as the main target. **Burrow
Brigade** (`examples/burrow-brigade`, its README and `SHIPPING.md`; feedback ids `BB/FB-n`) is that game: one to four
miners dig down through a mine seen from above, gather ore, rescue trapped moles and ride the lift back up before their
lamps burn out, while beetles, goblin thieves and, at the bottom, the Mole King hunt them through the tunnels they dig.
It was built like the other two, by game-maker AIs (Sonnet workers) with the generated AGENTS.md, `factoria docs` and
the public commands, no engine change, in eight packages (planned 2026-10-25 against `e9384f7`):

- P1 miner, digging and the mine: one miner on a top-down `Tilemap`, digging dirt and rock, ore, the lamp and its oil,
  darkness and a fog of unexplored tiles, the mine generator (rooms, tunnels, veins, the lift; one seed gives the same
  mine and hash everywhere), the shift flow, the HUD, and the contracts the other packages build on (generator, map,
  players, game events, run state).
- P2 world and enemies: the Topsoil, the Crystal Caves and the Magma Deep with water that floods an opened pocket,
  cave-ins and magma, torches and glowing crystals sharing the 16 lights, beetles, goblin thieves and the Mole King on
  the game's own A* over the dug grid and its own behaviour trees, music per stratum, and a bot that clears floors of
  every stratum from fixed seeds, alone and with four players.
- P3 couch co-op: a join screen for four pads or a keyboard and three pads, each player's device and colour, per-player
  bindings and their rebinding, a shared camera that zooms out with a leash (no split screen), downed miners revived by a
  friend, a pad unplugged mid-game, Remote Play Together guests treated as pads.
- P4 camp, progress and saves: the camp and its upgrades, three save slots whose format went from v1 to v2 with a
  migration (fixtures of both in the tests), cloud copies with a revision and a conflict rule, the daily dig and
  eight-character seed codes through a session clipboard.
- P5 Steam and online: achievements, stats and all-time and daily leaderboards on the fake store, rich presence, the
  Steam Deck checks and its keyboard, button glyphs per pad, and a news panel, remote balance values and opt-in analytics
  behind a transport seam that works offline.
- P6 sound, options and accessibility: music layers that rise in a chase, a mix with ducking and snapshots (muffled and
  echo faked by volume and a delayed replay), captioned sound cues, display options, hold or toggle for dig, a game speed
  for assist (not posted to the boards), ore and hazard markers readable without colour, reduced flashing near magma.
- P7 shipping: the icon, key art and Steam and itch.io capsules, store texts in English, Russian and Thai, store
  screenshots and a trailer rebuilt by scripts from four bots' input replays (not in git), the Steam settings (Valve's
  test app 480 for the manual check), the Windows, Linux and macOS exports, the render and perf budgets of the busiest
  floor (four miners, every torch), `SHIPPING.md`.
- P8 languages: Russian (its plural forms) and Thai (a Noto Sans Thai subset as a fallback font; the engine breaks lines
  only at spaces, so a tool puts one between words, BB/FB-0036), every screen at 100 % and 200 % text in the three
  languages.

Assets are CC0 only and recorded in `assets.json`: Kenney's Tiny Dungeon and Roguelike Caves and Dungeons, cut,
recoloured and extended by `assets/src/make_atlases.py`; the sounds come from `assets.synth_sound`, and the music, the
achievement and online art and the icon from the project's own scripts. `factoria test` runs 475 tests; ctest runs
the game as `example_burrow-brigade_*` (validate, test, perf).

It reported 38 entries (14 major, 22 minor, 2 nice-to-have), none a blocker: a co-op desktop game still needs
workarounds the engine should remove (the ranked list in [ROADMAP.md](ROADMAP.md)). The biggest are a dark world
(`Light2D` has no occlusion and stops at 16 lights, and the render stats do not count them), tile pathfinding and AI,
split screen, gamepad connect events and a stable pad identity, the system clipboard, HTTP for news, remote values and
analytics, layered music and bus effects, and an exported player that cannot take an input replay. Their triage is the
next milestone.

Acceptance: the bot clears floors of every stratum from fixed seeds, alone and with four players, and a test pins the
hash of a seed's mine on every desktop job; four simulated pads join, play a shift and revive a friend, and
keyboard-only and gamepad-only tests drive the menus; the three exports are made and the macOS one starts (input on it
is a by-hand check, ROADMAP.md); the busiest floor stays under its draw-call and light budgets in a headless run;
`factoria feedback collect` includes the game.

## M29. Found by the third reference game — DONE (the `m29/*` PRs)

Planned 2026-10-25, against `c7e6ef6`, from the triage above: 21 packages, ranked by points (occurrences x severity
weight) and size. Each ships with its doctest or JS test, its docs and the `"unreleased"` rows in
`tools/common/api_since.json` for the API it adds. When one merges, its entries get a `Fixed in <commit>` note in the
bookkeeping PR at the end, and Burrow Brigade drops the workaround it no longer needs (its `activeLights` helper, its own
A* and behaviour tree, its whole-array tile writes, its stdout recordings).
Order of work: three builds at once at most, a rolling pool; a package starts when the packages it comes after have
merged. Packages that only share a file run at once and the later one merges `origin/main` before its PR; packages that
change the same function or the same shader wait for each other (the "after" lines). First M29.1, M29.2 and M29.3;
then M29.4, M29.5 and M29.7; then the rest in order, as their "after" packages merge.

### M29.1 Light2D in the stats and the perf budget, a better choice of 16 (S) — BB/FB-0009, 0028, 0008 (part)

Done (branch `m29/light2d-stats`, `bef8abf1`): `RenderStats` has `lights2d` and `lights2dDropped` (`renderStats()`,
`game.render_stats`), and `perf.measure`'s `lights`, so the `maxLights` budget, counts the most 2D plus 3D lights of any
frame. The kept lights are the ones that light the view: directional first, then point lights whose radius reaches the
camera's rectangle, more of their radius in view first, then the brighter; one warning per scene when more are in view
than the budget. As planned; the budget is 256 since M29.14's light buffer, not 16 (that package changed this package's
test to expect 17 lights).

- `gather_lights` (scene2d.cpp) counts the 2D lights it keeps and drops: `RenderStats` gets `lights2d` and
  `lights2dDropped`, `renderStats()` and `game.render_stats` show them, and `perf.measure`'s `lights` (and so the
  `maxLights` budget) is the most 2D plus 3D lights of any frame: a budget that watched nothing now watches them.
- The 16 kept lights are the ones that light the view: directional lights first, then point lights whose radius reaches
  the camera's visible rectangle, ranked by how much of their radius is inside it and their intensity; a light entirely
  outside the view is never kept over one inside. More than 16 in view logs one warning per scene naming the count.
- `game.render_stats`' description, PERFORMANCE.md and the Light2D docs say what is counted and how the 16 are chosen.

Acceptance: render doctests: 20 lights give `lights2d` 16 and `lights2dDropped` 4, and the dropped ones are the
off-screen ones; `perf.measure` of a scene with 3 Light2D reports `lights` 3. Burrow Brigade's perf baselines get its
real light count, and its `perf.check` passes.

### M29.2 The time of day in `game.today()` and a daily leaderboard by date (S) — BB/FB-0017, 0021

Done (branch `m29/dates`, `120550c2`): `game.today()` has `hour`, `minute`, `second` and `utc: {year, month, day, iso}`;
a built game reads the clock again about once a minute and on focus or resume, `game.on("dayChanged")` runs once per
local day change, and `game.setDate`, `--date` and replay files take the time (and `game.setDate(iso,
{utcOffsetMinutes})` the zone). `leaderboard.submit` and `entries` take `{day}`; the fake and Steam keep every day, Game
Center and Play Games answer `unsupported` for a day that is neither the local nor the UTC today (the plan said "not the
current one"). A second commit (`4596f528`) says in the docs that a daily board without `day` is the local date's and
that `game.today().utc.iso` gives one board worldwide.

- `CalendarDate` (and `game.today()`) gets `hour`, `minute` and `second` next to `utcOffsetMinutes`, and a `utc` field
  with the UTC date. The date advances during play (the runner reads it again every minute and on focus or resume,
  not only at start), with a `dayChanged` event when the local date changes; replays record and play back the date
  fields, and `game.testSetDate` takes the new ones.
- `leaderboard.submit` and `entries` take `{day: "YYYY-MM-DD"}` on a daily board (a UTC day), and the fake keys the board
  by it; Game Center and Play Games answer `unsupported` for a day that is not the current one.
- SCRIPTING.md (dates) and PLATFORM.md (leaderboard periods) follow.

Acceptance: script tests: `game.today()` has the time and moves across midnight in a test that advances the clock
(with `dayChanged` once); a daily board read with yesterday's `day` returns yesterday's scores in the fake. A replay
recorded at 23:59 plays back on the same date.

### M29.3 Thai line breaks at marked boundaries and the sara am check (S) — BB/FB-0036 (part), 0037

Done (branch `m29/thai`, `2690d768`): A wrapped line breaks after U+200B (never drawn), the UAX #14 spaces and a hyphen
(`-` unless a digit follows, U+2010); `FontCoverage::missing`, `localization validate` and the runtime missing-glyph
warning check U+0E33 and U+0EB3 as the parts HarfBuzz decomposes them into (U+0E4D U+0E32, U+0ECD U+0EB2). TEXT.md and
LOCALIZATION.md say how to mark the boundaries; unmarked Thai, Khmer, Lao and Burmese still need a dictionary and are
not broken. As planned.

- `can_break_between` (text_shaper.cpp) breaks after U+200B ZERO WIDTH SPACE (which is not drawn) and after the UAX #14
  BA spaces (U+1680, U+2000-U+2006, U+2008-U+200A, U+205F) and the hyphen, so Thai, Khmer, Lao and Burmese text whose
  translator marks word boundaries with U+200B wraps there.
- `FontCoverage::missing` expands the composed vowels before checking: U+0E33 needs U+0E4D and U+0E32, U+0EB3 needs
  U+0ECD and U+0EB2. `localization validate` and the runtime missing-glyph warning name them.
- TEXT.md and LOCALIZATION.md: how to mark Thai boundaries; breaking unmarked Thai needs a dictionary and is not done.

Acceptance: text doctests: a Thai line with U+200B wraps at it and never inside a word, and draws no glyph for it; a
font without U+0E4D is reported missing for a string with U+0E33.

### M29.4 The clipboard and the window-close event (M) — BB/FB-0016, 0023

Done (branch `m29/clipboard-quit`, `d025e515`): `clipboard.read()` (a Promise) and `clipboard.write(text)` on Windows,
macOS, Linux and the web (`window.supports("clipboard")`), an in-memory clipboard in headless runs and tests (a replay's
`"clipboard"` entry sets it), and Ctrl/Cmd+V and Ctrl/Cmd+C in a focused `TextField`; phones answer `unsupported`.
`game.on("quit", fn)` is raised by the close button, Cmd+Q and Alt+F4, `event.cancel()` keeps the game running,
`game.quit()` closes without asking again, and the test helper `game.closeWindow()` raises it. As planned, except that a
replay sets the clipboard at its start instead of recording each read.

- `clipboard.read()` (a Promise) and `clipboard.write(text)`, with `supports("clipboard")`, on Windows, macOS, Linux and
  the web (`enable_clipboard` in the app descriptor; the web reads only inside a paste gesture). A focused `TextField`
  pastes with Ctrl+V (Cmd+V on macOS) and copies its text with Ctrl/Cmd+C. Headless runs and tests have an in-memory
  clipboard; a replay records what a read returned. Mobile answers `unsupported` for now.
- `game.on("quit", fn)`: the window's close button, Cmd+Q and Alt+F4 raise it (desktop only; `QuitRequested` is no longer
  dropped by the runner); a handler may call `event.cancel()` to keep the window open, and `game.quit()` closes it.
- SCRIPTING.md (clipboard, app events) and UI.md (`TextField`).

Acceptance: script tests: write then read gives the text back; a TextField pastes with Ctrl+V; a requested quit raises
`quit` once and a cancelled one keeps running. Replays of a paste are deterministic.

### M29.5 Steam from one Mac: optional plugin, exports, app 480, capsules (M) — BB/FB-0031, 0032, 0033, 0034

Done (branch `m29/steam-mac`, `f96d04d3`): The Steam plugin logs a warning, not an ERROR, without Valve's library, and
`project.new_plugin` (so `platform.add_backend`) writes `optional: true`; `project.export` takes `allowMissingPlugins`
(the result lists `pluginsLeftOut`); a player with no build fingerprint gets its own error; `publish.steam` accepts app
480 in a dry run with a warning; `assets.draw_capsules` takes `safeArea` and `logoAnchor`, and `focus` moves the logo
when the key art already has the capsule's proportions. Two follow-up commits fix a command description and regenerate
the reference. As planned.

- A plugin that cannot load its library logs a warning, not an ERROR; `platform.add_backend steam` and
  `project.new_plugin` write `optional: true` (already supported since `ce8b98c`).
- `project.export` takes `allowMissingPlugins` (like `allowPlayerMismatch`): a target whose plugin build is missing is
  exported without it, and the export lists what it left out.
- The player-build fingerprint check says what to do when the installed player predates fingerprints (0.2.0): install a
  newer player or pass `allowPlayerMismatch`; EXPORTING.md stops pointing in a circle.
- `publish.steam` accepts app 480 in a dry run (a warning that Spacewar is Valve's test app), still refused for a real
  upload.
- `assets.draw_capsules` takes `logoAnchor` and `safeArea` (per capsule, with defaults), and `focus` also moves the logo
  when the aspect ratios already match.

Acceptance: tooling tests: an export with a missing optional plugin build passes with `allowMissingPlugins` and lists
it, and fails without it; a dry run with app 480 passes with a warning; a capsule with `logoAnchor` puts the logo inside
its safe area. A run with a declared Steam plugin and no Valve library logs no ERROR.

### M29.6 Test runner and `ui.check_layout` (M) — BB/FB-0019, 0024, 0038, 0035

Done (branch `m29/test-runner`, `edb178ec`): `game.click` (and `mouseMove`, `touch`, `touchStart`, `touchMove` with a
widget) lays the UI out first and throws, naming the widget and why, for a widget that is inactive, has no area or is
scrolled out of its `ScrollList`; `game.tapKey(key)` presses and releases a key over one frame; `ui.check_layout` judges
a widget by the part its `ScrollList` shows and takes `steps` per scene; SCRIPTING.md shows `fa.call("fs.write", ...)`.
The throw broke one Clockwork Courier test (it clicked a hidden second ad button), which commit `73ac6212` now expects
to throw. As planned.

After M29.2 (both edit `factoria.js`'s test helpers).
- `game.click` on a widget of a panel opened in the same frame lays the UI out first (`posArg` runs the layout), and a
  click on a widget that is not laid out or not visible throws, naming it, instead of doing nothing.
- `game.tapKey(key)` presses and releases a key over one frame; the docs show `game.tapKey("Enter")` submitting a
  `TextField`.
- `ui.check_layout` intersects each widget's rectangle with its `ScrollList`'s clip, so a row half inside is checked on
  its visible part and a row fully outside is skipped, and takes `steps` per scene (clicks, keys, frames) run before the
  checks.
- SCRIPTING.md's tests section shows `fa.call("fs.write", {path, content})` to save a recording from a test.

Acceptance: JS tests for the click after `open()` and the error, and for `tapKey`; `ui_check_layout_test.cpp` cases for
a half-visible row and for `steps` that open a panel.

### M29.7 Music: the scene-load bug, voice volume, synced layers, synth loudness (M) — BB/FB-0012, 0025, 0007

Done (branch `m29/music`, `291f4b98`): A scene load restarts the new scene's music (the same track included),
`audio.music(path, {persist: true})` keeps a track across loads, `audio.setVoiceVolume(id, volume, fade?)`,
`audio.musicLayers({name: path}, opts)` and `audio.setLayer(name, level, fade?)` (stems start on the same sample, loop,
are never evicted, and the play log has a `layer` field), and `assets.synth_sound` levels every preset to about -18 LUFS
with a peak under -1 dBFS (the bytes of every seed change). The docs say a scene load stops sounds and music unless
persisted. As planned.

- The bug: `Audio::stop_all` leaves `sceneMusic` set, so a scene that loads with the same `settings.music` as the one
  before plays nothing while `state().audio.music` says it is playing. Loading a scene now starts its music again, and
  `audio.music(path, {persist: true})` keeps a track playing across scene loads.
- SCRIPTING.md, AI_GUIDE §9.7 and the SceneSettings docs say a scene load stops sounds and music unless persisted.
- `audio.setVoiceVolume(id, volume, fade?)` changes a playing voice's volume (the mixer already fades).
- `audio.musicLayers({name: path, ...}, opts)` starts several tracks on the same sample, and `audio.setLayer(name, volume,
  fade?)` mixes them; `stopMusic` stops them all and the play log names the layer.
- `assets.synth_sound` normalizes its presets to the loudness the validator accepts (-18 LUFS, the measurement in
  `fa/audio/analysis.h`) instead of peaking at -3 dBFS.

Acceptance: audio doctests: two scenes with the same music play it after the load; layers stay sample-aligned; a voice's
volume fades. A synth preset passes `factoria validate`'s loudness check.

### M29.8 Menu kit: optional shop and age gate, a Controls tab from the actions (M) — BB/FB-0004, 0005

Done (branch `m29/menu-kit`, `2af58d1d`): `project.add_menu_kit {"parts": ["main-menu"]}` writes a main menu without the
shop button, the shop panel and the age gate (and without their scripts); no `parts` still adds everything. The options
screen's Controls tab lists `input.actions()` except the `ui_*` ones, labelled with `options.action.<action>` (the
action's name when there is no string), and the Script's `actions` property picks and orders them. As planned.

- `main-menu` no longer requires `shop` and `ageGate`: the main menu shows the shop button and asks the age only when
  those parts are in (its script imports them only then), and `project.add_menu_kit` adds them only when asked.
- The options screen's Controls tab lists `input.actions()` without the `ui_*` ones, labelled with `i18n.t` (the action's
  name when no key exists); the `Options.actions` property the docs promise is declared, to pick and order them.
- MENUS.md follows.

Acceptance: `menu_kit_test.cpp`: a kit without shop and age gate validates and runs; a game with `dig` and `place`
actions sees them in Controls and can rebind them.

### M29.9 Gamepad connect events, a stable pad id and Steam Deck detection (M) — BB/FB-0014, 0022

Done (branch `m29/gamepads`, `fe840536`): `game.on("gamepadConnected" | "gamepadDisconnected", fn)` gives `{slot, id,
name, type}` (`input.gamepad(i).id` and `.name` too) on Windows, Linux, macOS, iOS, Android and the web, and a pad that
returns gets its old slot when it is free; tests use `game.gamepad(i).connect({...})`. `game.device.steamDeck` and
`handheld` come from the Steam plugin through plugin API version 4 (`set_device_fact`; commit `e4b614cc` makes the
engine read it when the entry point returns), else the `SteamDeck=1` environment variable; `game.setDevice` takes both.
The plan did not mention the plugin API bump. On Windows the id comes from the XInput slot, so it does not tell two pads
apart across slots.

- `game.on("gamepadConnected" | "gamepadDisconnected", fn)` with the pad's slot and a stable `id` (its name, vendor and
  product, and a serial or path where the backend has one), on the five backends (Windows, Linux, Apple, Android, web);
  a pad that comes back gets its old slot when it is free.
- `game.device.steamDeck` and `game.device.handheld` (the Steam plugin's `IsSteamRunningOnSteamDeck`, the `SteamDeck`
  environment variable otherwise); `game.setDevice` in tests takes them.
- INPUT docs and AI_GUIDE (which wrongly says the web has no pads).

Acceptance: input doctests: connect, disconnect and reconnect raise the events and keep the slot; script tests with a
test device that is a Steam Deck.

### M29.10 Tilemap: tileset margin and spacing, `setTile` without rewriting the array (M) — BB/FB-0002, 0003

Done (branch `m29/tilemap`, `390af568`): `Tilemap.margin` and `Tilemap.spacing` (pixels) are read by the 2D renderer
(also the normal map), the tile count, `factoria validate` and the level commands; `entity.tilemap.setTile(col, row,
id)` and `getTile(col, row)` and the command `tilemap.set_tile` change one tile in place, the renderer reads the grid
without a copy per frame and 2D physics rebuilds only the changed colliders (a whole-array write still works, caught by
a hash). A second commit (`97678e80`) makes `entity.tilemap` width and height native reads instead of copying the tiles
to the script. The plan called the script call `tilemap.setTile(x, y, id)`; it is a method of `entity.tilemap`.
`assets.slice_sheet` does not take margin or spacing.

- `Tilemap.margin` and `Tilemap.spacing` (pixels), used by the 2D renderer (also for the normal map), the tileset tile
  count, `factoria validate` and the level commands.
- `tilemap.setTile(x, y, id)` and `getTile(x, y)` (script) and a `tilemap.set_tile` command change one tile in place;
  the renderer stops copying the grid every frame, and 2D physics rebuilds only the colliders of the changed tiles.
- LEVELS docs and the component reference.

Acceptance: render doctests for a tileset with margin 1 and spacing 2; physics doctests: `setTile` opens a hole a body
falls through on the next step; a scripted 1 000 tile writes cost less than one whole-array write each.

### M29.11 Tile pathfinding and a behaviour-tree module (M) — BB/FB-0010, 0011

Done (branch `m29/tile-nav-bt`, `23c2aae8`): `nav.findTilePath(map, from, to, {costs, diagonals, maxNodes, closest,
allowBlockedGoal})` and the command `nav.find_tile_path` run a deterministic A* over a Tilemap or a `{width, height,
cost}` grid and return `cells` and world `points` (diagonals never cut corners); `nav.tileVersion(tilemap)` counts
`setTile` writes so a script can tell a kept path is stale. `import { bt } from "factoria"` has `Tree`, `sequence`,
`selector`, `condition`, `action`, `wait`, `cooldown`, `inverter`, `succeeder` and the three results; Burrow Brigade's
moles use both and dropped their copies. Commit `a018f4fb` makes a wrong option type a script error instead of an
exception through QuickJS. Beyond the plan: `allowBlockedGoal`, `tileVersion` and an enemies recipe (AI guide 9.27).

After M29.10 (it reads tiles through M29.10's API).
- `nav.findTilePath(tilemap | {width, height, cost}, from, to, {costs, diagonals, maxNodes, closest})`: A* on a
  Tilemap's cells (solid tiles block, `costs` per tile id), on the pattern of M26.10's search, with the
  `nav.find_tile_path` command; deterministic, and `closest` returns the nearest reachable cell.
- `import { bt } from "factoria"`: `Tree`, `sequence`, `selector`, `condition`, `action`, `wait`, `cooldown`,
  `inverter`, `succeeder` and `SUCCESS`, `FAILURE`, `RUNNING`, in plain JS like `tween`, ticked by a script.
- NAVIGATION.md and a SCRIPTING.md section on AI.

Acceptance: physics doctests (a path around walls, diagonals off, `closest`, the same path twice); JS tests for each
node type. Burrow Brigade's moles move onto both and drop their copies; their tests pass.

### M29.12 `input.record` and starting a scene with props (M) — BB/FB-0030

Done (branch `m29/input-record`, `21ce220b`): The input recorder moved from the editor into the engine and records keys,
mouse, touches, Back and gamepads; `input.record {action: "start" | "stop", path?}` returns the replay `factoria run
--input` plays. `scene.load(path, props)`, `game.load`, `game.loadJson`, the `scene.load` command's `props`, `factoria
run --props JSON|FILE` and `game.sceneProps()` hand values to the scene's first start (a reload keeps them). Not
recorded: the mouse wheel, locked-mouse movement and typed text. The plan also listed `run.start`'s `props`; the
CHANGELOG does not mention it and it was not checked.

- The input recorder moves from the editor into the runtime, records gamepads too, and is a command: `input.record`
  `{action: "start" | "stop"}` (stop returns the replay JSON `factoria run --input` plays).
- `scene.load(path, {props})` and `factoria run --props <json>` (and `run.start`'s `props`) hand values to the scene's
  scripts at start (`game.sceneProps()`).
- SCRIPTING.md and DEBUGGING.md.

Acceptance: runtime tests: a recorded keyboard and pad session replays to the same state hash; a scene started with
props sees them in its first `start()`.

### M29.13 The exported player takes an input replay, dumps its state and takes a screenshot (M) — BB/FB-0029

Done (branch `m29/player-replay`, `78e12e7a`): The exported player takes `--input <replay>`, `--dump-state <file>` and
`--screenshot <file>` with `--frames N`, headless through the same code as `factoria run --headless`; exit code 2 for a
missing replay, an unwritable output or a missing `--frames`. The new test `cli_player_replay` compares the state dump
and the screenshot with `factoria run`'s, and EXPORTING.md has "Checking an exported build". As planned.

After M29.12.
- The exported player accepts `--input <replay>`, `--dump-state <file>` and `--screenshot <file>` (with `--frames`),
  through the same `HeadlessRunOptions` as `factoria run`, so a shipped build can be checked by script.
- EXPORTING.md: checking an exported build.

Acceptance: a tooling test runs an exported desktop build with a replay and compares its state dump and screenshot with
`factoria run`'s.

### M29.14 Light2D on a light buffer: shadows from solid tiles and no 16-light cap (L) — BB/FB-0001, 0008 (the rest)

Done (branch `m29/light-buffer`, `0d306a3c`): Point lights are added up in a light buffer (one draw call, RGBA16F or
RGBA8 at half range) that lit sprites, tiles and shapes read, and a frame keeps up to 256 lights;
`SceneSettings.lightScale` sizes the buffer and `FA_LIGHT_FORMAT` picks its format. `Light2D.castShadows` and
`Tilemap.occludesLight` make solid tiles cast shadows: differing from the plan's shadow mask, the shadows are traced on
the CPU per light (1024 rays) and looked up on the GPU, for at most 32 lights per frame (new stat `lights2dShadowed`). A
lit visual with a normal map, and a perspective camera, still shade per pixel with the first 16 lights. A scene with lit
visuals adds one draw call (Burrow's baselines went from 10 to 11), and PERFORMANCE.md has the cost per light.

After M29.1 and M29.10.
- 2D lights render into a light buffer (one pass per light, or tiled), so a scene has as many as its budget allows;
  `Light2D.castShadows` and `Tilemap.occludesLight` make solid tiles cast shadows (a shadow mask per light built from
  the occluding tiles).
- Shaders regenerated for every backend; PERFORMANCE.md gives the cost per light.

Acceptance: render tests: a light behind a wall of tiles leaves the far side dark; 64 lights all light the scene; the
perf budgets of the 2D examples pass on the CI runners.

### M29.15 Per-player actions (L) — BB/FB-0006

Done (branch `m29/player-actions`, `4f6d6b63`): `input.player(i)` (0..3) gives each person their own `down`, `pressed`,
`released`, `value`, `axis` and `vector` from the devices assigned with `use({pad, padId, keys})`, key schemes (`"all"`,
`"left"`, `"right"` or `input.schemes` in `factoria.json`) and bindings of their own (`rebind`, `reset`, `export`,
`import`); the menu kit's options screen gets a Player button when its `players` property is above one, and Burrow
Brigade's four diggers use it. Three commits: the engine (`4f6d6b63`), the natives and `factoria.json` (`3f2862d2`) and
docs, schema, typings and the game (`099f3d15`); the last also fixed an invalid embedded project schema and regenerated
`schemas/project.schema.json`. Players do not read the mouse or touch, which the global actions still do.

After M29.8 and M29.9.
- `input.player(i)` gives a player their own actions bound to their pad (or keyboard half), with `pressed`, `held`,
  `axis` like the global ones, and rebinds saved per player; the kit's Controls tab rebinds a chosen player.
- INPUT docs.

Acceptance: input doctests: two pads drive two players' `move` independently; a rebind of player 2 leaves player 1's.
Burrow Brigade drives its four diggers with it.

### M29.16 Bus effects, ducking and snapshots (L) — BB/FB-0026

Done (branch `m29/bus-fx`, `44c0bc69`): Every bus is mixed into its own buffer before the master:
`audio.bus(name).lowpass(hz)`, `.reverb(mix)`, `.duck(byBus, amount, attack, release)` and `.unduck()` (`lowpass`,
`reverb` and `volume` take `{fade}`), `audio.snapshot(name, {fade})` from `audio.snapshots` in `factoria.json`
(validated), and the commands `audio.bus` and `audio.snapshot`. A volume change ramps over about 10 ms instead of
jumping. Effects stay across scene loads. As planned.

After M29.7.
- The mixer sums each bus before the master, with volume ramps; `audio.bus(name).lowpass(hz)`, `.reverb(mix)` and
  `.duck(byBus, amount, attack, release)`, and `audio.snapshot(name, {fade})` from the catalog, with commands.
- AUDIO docs.

Acceptance: audio doctests: a low-pass removes a high tone; a ducked bus drops while the other plays and recovers; a
snapshot fades in its time. The mix stays deterministic.

### M29.17 Monitor choice and window modes (M) — BB/FB-0027

Done (branch `m29/window-modes`, `7156bfaf`): `window.monitors()`, `window.monitor`, `window.setMonitor(i)`,
`window.setMode("windowed" | "borderless" | "fullscreen")`, `window.mode` and `window.supports("borderless" |
"monitors")`; on Windows and Linux full screen is a frameless window over the monitor, so `"fullscreen"` and
`"borderless"` look the same there, on macOS `"fullscreen"` is the native Space. The menu kit's options screen has a
Window mode button and a Monitor button (only with several monitors) and `settings.js` saves `windowMode` and `monitor`,
still reading the old `fullscreen`. The plan asked for a manual check per desktop OS; none was done.

After M29.4 (both touch the window host).
- `window.monitors()`, `window.setMonitor(i)` and `window.setMode("windowed" | "borderless" | "fullscreen")` on Windows,
  macOS and Linux; the options screen offers them.
- SCRIPTING.md (window).

Acceptance: platform tests through the headless window host; a manual check per desktop OS listed in the docs.

### M29.18 Steam Remote Play guests and `cloud.stat` (L) — BB/FB-0015, 0018

Done (branch `m29/remote-play`, `cd8fb526`): A `remotePlay` platform service: `platform.remotePlay.sessions()` and
`platform.on("remotePlay", ...)` with `{status, session}`, offered by the Steam plugin when the library has
`ISteamRemotePlay`, and a fake (`game.platform.remotePlayConnect` and `remotePlayDisconnect`, with their commands).
`platform.cloud.stat(key)` returns `{exists: false}` or `{exists: true, size, modified}` (Unix seconds, `null` on
Apple); the fake's time is a counter set by `cloudClock`. A guest's controls arrive as one more pad and the engine does
not say which one; commit `4800aad6` regenerates the reference after the merge with M29.20. Checked against the Steam
mock only.

After M29.2 and M29.5.
- A `remotePlay` service: `remotePlay.sessions()` and `remotePlay` connect and disconnect events (Steam's
  `SteamRemotePlay`), the fake for tests; a guest's input arrives as the pads Steam gives it.
- `cloud.stat(key)` returns its size and modified time (Steam `GetFileTimestamp`, Play's snapshot metadata; Apple
  returns null for the time).

Acceptance: `steam_plugin_*` tests against the mock for sessions and timestamps; fake tests for both APIs.

### M29.19 Split screen: camera viewports (L) — BB/FB-0013

Done (branch `m29/split-screen`, `f8ddc3e9`): `Camera.viewport` is `[x, y, width, height]` (0 to 1, top-left origin);
every active `primary: true` camera now draws in ascending `depth` with its own scissor, culling, 2D and 3D lights and
`clear`, up to 8; bloom and `colorFilter` run once with the lowest-depth camera's settings and the UI once over the
whole screen. Scripts get `camera.all`, `camera.at(point)`, `camera.screenRay` and an optional camera for
`worldToScreen` and `screenToWorld`; `input.mouse.world` uses the camera under the pointer. Beyond the plan: a second
primary camera that used to be ignored now draws (commit `ae68b5de` says so in the CHANGELOG). Burrow Brigade has
Options > Video > "Split screen when players part"; AI guide recipe 9.29.

After M29.14.
- `Camera.viewport` (a normalized rectangle) and a render loop per camera, in depth order: each draws its view into its
  rectangle with its own lights, and `screenToWorld` takes the camera; the contradictory Camera docs are fixed.
- RENDERING docs and a split-screen recipe.

Acceptance: render tests: two cameras draw two halves; four cameras in quarters; picking under the mouse picks the
right camera. Burrow Brigade gets a split-screen option for far-apart players.

### M29.20 `http.fetch` on every platform (L) — BB/FB-0020 (part)

Done (branch `m29/http-fetch`, `94047d90`): `import { http } from "factoria"`: `http.fetch(url, {method, headers, body,
timeout})` returns a Promise of `{status, ok, headers, text, json()}` on WinHTTP, `NSURLSession`, libcurl (loaded on
first use), `HttpURLConnection` and the browser's `fetch`; a game declares its servers in `factoria.json`
`network.hosts`, which `factoria validate` checks and the Android export turns into the `INTERNET` permission. Tests and
headless runs get a fake scripted by `game.platform.respond`, and an input recording keeps the answers (commit
`123c5f14`). New NETWORKING.md; LEGAL.md and MOBILE.md no longer say games have no network. Beyond the plan: the host
list and its checks.

- `http.fetch(url, {method, headers, body, timeout})` (a Promise of status, headers, text and JSON) on Windows (WinHTTP),
  macOS and iOS (NSURLSession), Linux (libcurl, loaded when present), Android (HttpURLConnection, the `INTERNET`
  permission when a game uses it) and the web (fetch). Tests and headless runs get a fake that answers what
  `game.platform.respond` gives it, and never touch the network.
- LEGAL.md and MOBILE.md stop saying games have no network; a NETWORKING doc.

Acceptance: script tests against the fake; a desktop doctest against a local test server; the Android and web builds
in CI.

### M29.21 Analytics with consent and remote config (M) — BB/FB-0020 (the rest)

Done (branch `m29/analytics`, `1c0beff9`): `analytics.event(name, props)` queues events and sends batches to the
`endpoint` of the `"analytics"` section of `factoria.json` only after `analytics.setConsent(true)` (or
`consentFromAds`); a quit waits at most 3 s for the last batch, and a failed send is retried at most 3 times per event.
`remoteConfig.get(key, fallback)` reads the `"remoteConfig"` section's JSON, caches it in `storage` and checks each
value against its fallback's type. Both are script modules on `http.fetch` (no new command), `factoria validate` checks
the sections, the iOS export adds the analytics privacy entry, and the menu kit has an `analyticsConsent` part and an
Options switch. The plan had the endpoint in "the catalog"; it is in `factoria.json`.

After M29.20.
- `analytics.event(name, props)` batched and sent through `http` only after the player consents (the ads consent, or the
  kit's privacy toggle), to an endpoint the catalog names; `remoteConfig.get(key, default)` fetched at start and cached,
  with the fake for tests.
- PLATFORM.md and LEGAL.md (what is sent and when).

Acceptance: fake tests: no event leaves before consent, a batch after it; remote config falls back to the cache offline.

Out of M29: breaking unmarked Thai, Khmer, Lao and Burmese (a word dictionary like ICU's, L), a cloud conflict event
(each store resolves it its own way), mapping a Remote Play guest to a pad (needs ISteamInput wrapped), cross-compiling
plugins from the Mac, and WebSocket.

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
