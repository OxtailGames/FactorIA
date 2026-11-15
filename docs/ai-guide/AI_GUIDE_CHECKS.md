# AI guide: tests, debugging and finishing

Part of [AI guide](../AI_GUIDE.md): sections 10 to 14: tests, debugging and replays, common mistakes, performance, where to read more.

## 10. Tests

Each test file starts with fresh module state, an empty `session` and storage, and the project's start scene and seed, so results are deterministic. Drive the game through inputs and assert on the result:

```js
import { test, expect, game } from "factoria:test";

test("player runs right", () => {
  game.load("scenes/main.scene.json");
  game.step(60);                  // let the player land
  const player = game.find("player");
  const x0 = player.position.x;
  game.press("move_right");
  game.step(30);
  game.release("move_right");
  expect(player.position.x).toBeGreaterThan(x0 + 100);
});
```

The `game` object under test:

- Scenes: `load(path)` (reseeds the RNG; behaviours exist at once, `onStart` runs on the first `step`), `loadJson(sceneObject)` for a scene built in the test.
- Time: `step(frames = 1)`. 60 frames is one second of game time.
- Actions: `press(action)` and `release(action)` hold an action until released; `tap(action)` presses for one frame.
- Keys and mouse: `keyDown(key)`, `keyUp(key)`, `mouseMove(screenPos)`, `click(screenPos, button?)`.
- Widgets: `click`, `touch` and `touchStart` also take a widget id or an Entity instead of a position and use the centre of its laid-out rectangle (safe area included). `ui.rectOf(entityOrId)` gives that rectangle (a widget or a screen-space `Text`; the `rect` of `ui.state` lists the same). After `game.setSafeArea(...)` take a `game.step(1)` before reading a rectangle or touching a control anchored to the safe area.
- Timing: `world.emit` from a test reaches its listeners at the next `game.step`; `platform.*` answers are ready at once.
- Touch: `touch(screenPos, frames)` for a finger held for some frames, `touchStart(screenPos, id?)`, `touchMove(screenPos, id?)`, `touchEnd(id?)`. `input.touches[0].pressed` is true on the first frame only. As on a device, the first finger also moves the mouse and holds the left button (`input.mouse.pressed("left")` is true on that first frame), so a touch test also covers the mouse branch of your code: do not add a `click` to simulate it. A script that handles both the mouse and `input.touches` sees one tap twice, so make the second handling harmless (for example, act on the target cell only if it is not already taken).
- Queries: `find(idOrName)`, `world`, `time`, `state()`, `screenshot(path)` (needs graphics).
- Store: `game.platform` controls the fake store every test run uses (not the `game.platform` of the `factoria` module, which is the OS name): `respond(method, answer, times = 1)` makes the next `"purchases.buy"` fail (`{ error: "network" }`), cancel (`{ status: "cancelled" }`) or answer something else, `emit("purchase" | "overlay" | "player", data)`, `set({ signedIn, delayFrames, backend })` (`backend: "none"` plays a game without a store until `reset()`: `platform.has` is false and calls reject `unavailable`), `state()`, `calls()`, `reset()`; `await platform.purchases.buy(...)` works in a test (`docs_read {"name":"platform"}`).
- Web requests: `http.fetch(url, { method, headers, body, timeout })` (`import { http } from "factoria"`) needs the hosts in `factoria.json` `"network": {"hosts": ["api.example.com"], "purpose": "..."}` (https only; an undeclared host throws). Tests never reach the network: `game.platform.respond("http.fetch", { status: 200, json: {...} })` (or `{ error: "network" }`) scripts the next answer, `game.platform.calls()` shows the requests. The answer may come after the scene changed: check `scene.current` before using it (`docs_read {"name":"networking"}`).
- Sound: `audioLog()` lists the sounds played since the test started (`{frame, time, path, volume, pitch, pan, bus, loop, music, source, ok}`, oldest first); it is cleared before each test, and `clearAudioLog()` clears it by hand.

Assert sounds with `toContainPlayed` (alias `toHavePlayed`). The path can be the full project path, just the file name, or a RegExp; options `times` (exact count), `bus` and `source` (entity or id) narrow it. Plays whose clip failed to load do not count, and the failure message lists what did play:

```js
test("jumping plays the jump sound once", () => {
  game.load("scenes/main.scene.json");
  game.step(60);
  game.clearAudioLog();                      // ignore sounds from the level start
  game.tap("jump");
  expect(game.audioLog()).toContainPlayed("assets/sfx/jump.wav", { times: 1 });
  expect(game.audioLog()).not.toContainPlayed("hurt.wav");
});
```

Patterns that work:

- Settle first with `game.step(...)`, then act, then assert. Read values after the step, not before.
- Reach behaviour fields through the entity: `game.find("enemy_1").behaviour.dir`.
- Test behaviour, not implementation: positions, component values, whether an entity still exists (`game.find(id) === null`).
- Use `toBeCloseTo(n, digits)` for floats, and `toBeGreaterThan` for "moved far enough".
- Physics is exact for one build on one platform, not across them (next section). Where a level test depends on a chaotic setup (a rope bridge, a stack, a seesaw), wrap it in `robust(check, { runs, nudge })`: the check runs under small, repeatable nudges of the bodies, so it asserts what survives rounding (reached, delivered, a range) instead of an exact frame count.
- `game.load` gives a test a known starting state. Within one file, anything else (variables, `session`, behaviour fields) carries over between tests unless the test loads or resets it.
- Storage is an empty in-memory store for each test file, so tests never read or write the real save. `session` is also reset per file.
- Keep tests fast: headless steps do not draw, so `game.step(600)` costs little. Take a screenshot only where you need to see something, and avoid `--render-all`, which draws every frame in software and is much slower.
- **A test fails when the game fails.** A test passes only if its assertions hold AND no game script threw while it ran (a callback, an event handler, a module's top level) AND the engine logged no `ERROR` (a sound or texture that is not there, a refused command). The first such error is the test's message, so a script bug cannot hide behind green assertions. `console.error` is the game's own message and is not an error. A test that is about an error says so: `game.expectErrors(/part of the text/)` inside the test, or `test(name, fn, { expectErrors: [/part of the text/] })`; an expected error that is never logged fails the test too. Fix the script; use `expectErrors` only where the error is what the test checks.
- **What a script may call.** `fa.call` in a game script (and in a test) runs with `{read, state}`: it can read and change the running game but not write files, reach the network or start programs, and a refused call fails with `capability_denied` and a hint. A test that has to write a project file (rebuild a level with `scene.import_ascii` and a `path`, `fs.write`, `scene.save`) asks for it: `test(name, fn, { capabilities: ["writeProject"] })` (never more than whoever runs the tests). A project tool (`tools/*.js`) runs with the permissions of whoever calls it; one that only changes the running game declares `capabilities: ["read", "state"]` so a game script can call it.
- `console.log`, `console.warn` and `console.error` in scripts are log lines with category `script`. `factoria test` shows what each test printed, indented under the test (and under `logs` with `--json`). Use `console.log` while you debug, and remove it before you finish.
- Import JSON data in tests the same way as in scripts (`import levels from "../data/levels.json";`).

### Physics and platforms

What holds: the same source, seed and input give the same physics, bit for bit, on Linux, Windows and macOS (and Debug and Release agree). The engine gets there in three ways. It is built with no floating-point contraction (`-ffp-contract=off`, `/fp:precise` on MSVC), so `a * b + c` is never fused into one rounding on arm64 or on CPUs with FMA. The simulation never calls the C library's `sin`, `cos`, `atan2`, `asin` or `acos`, whose last bit differs between glibc, Apple's libm and the MSVC CRT: it uses `fa::det::` (`fa/core/det_math.h`), which is built only from `+ - * / sqrt` on doubles, and those IEEE 754 rounds the same everywhere. Ties in sorts are broken by index or entity id, never by the standard library's own order. Box2D (2D) has its own cosine, sine and atan2 and is built with the same flags.

CI runs a physics replay on its Linux, Windows and macOS jobs, prints its hash (`FA_PHYSICS_REPLAY_HASH`) and compares it with the ONE value committed in `engine/physics/tests/test_determinism.cpp`; a platform that differs fails the job.

The same holds for what the simulation computes besides physics: particles, the feel effects (shake, squash, flash, knockback), the animation clips, the nav bake and path search, and the `Math.*` of game scripts (the exponential, power, logarithm and trigonometric functions, which are `fa::det::f64` and not the C library's). A test of the source (`engine/core/tests/test_det_scan.cpp`) fails when the simulation calls `std::exp`, `std::pow`, `std::sin`, `std::cos` or any other C library transcendental; ARCHITECTURE.md, "Determinism of the maths", lists the files it reads and how to add one.

CI also runs replays of particles, feel, scripts (the math of a seeded loop), 2D physics, 3D physics and nav, prints their hashes (`FA_DET_HASH`) and compares them with committed values; the scripts, physics and nav replay (`tools/cli/tests/determinism_probe.js`) runs in the Android emulator, the iOS simulator and a browser too.

What is not promised: the same engine version only. A change to the physics code, or to a game's own scene, moves the result (and so the committed hash) on every platform together. Rendering is not part of this: the GPU's last bit and the pixels it draws differ between backends. `Math.sqrt` and the other exact functions are the same everywhere, so a script that feeds `Math.atan2` or `Math.pow` into physics is as repeatable as the physics itself.

For your game: do not assert an exact frame count or an exact position after a long physics run. Use `robust()` (SCRIPTING.md, "Tests") and give chaotic setups a margin (bridges that settle before the player arrives, ledges wider than the worst nudge).

## 11. Debugging, live sessions and replays

| Command | MCP tool | What it tells you |
|---|---|---|
| `factoria validate`, `project.validate` | `project_validate` | Structure and references, before anything runs. |
| `script.errors` | `script_errors` | Exceptions thrown by scripts, with file, line and stack. |
| `game.logs` | `game_logs` | Log lines, each with `wallTime` (local ISO 8601). `console.log/warn/error` in scripts appear with category `script`; the engine's own warning that a frame spent too long in scripts has the category `script.budget` (docs/PERFORMANCE.md, "Script budgets"). |
| `audio.log` | `audio_log` | Which sounds played, on which frame and bus, and whether the clip loaded. |
| `audio.bus`, `audio.snapshot` | `audio_bus`, `audio_snapshot` | The mixer's effects and snapshots: what a bus is set to, and which snapshot is applied. |
| `game.state` | `game_state` | Entities, components, physics, logs and errors of the running game. |
| `scene.get_entity` | `scene_get_entity` | One entity by id. |
| `script.trace` | `script_trace` | Run the project headless and record the stack, locals and watch expressions every time given script lines run (with an optional condition), or collect logpoint lines: `{"points":[{"file":"scripts/player.js","line":17,"condition":"this.body.velocity.y > 0","watch":["this.body.velocity","dt"]}],"frames":300,"maxHits":20}`. Returns `hits`, `logs`, `errors`, `framesRun`, `truncated`. Use it instead of adding `console.log` and re-running. `docs_read {"name":"debugging"}`. |

A person debugs the same scripts with breakpoints and stepping in VS Code (F5; `factoria setup vscode` installs the
extension): [DEBUGGING.md](../DEBUGGING.md).

### 11.1 Stateful debugging: `factoria session` and `call --batch`

`factoria call <command> '<json>'` starts a new engine every time, so game state does not carry over between calls. To act on one running game, use one of these two:

- `factoria session` reads one JSON request per line on stdin and writes one JSON answer per line. The game keeps running between lines:

  ```
  printf '%s\n' '{"command":"game.step","args":{"frames":30}}' \
    '{"command":"script.eval","args":{"code":"world.find(\"player\").position"}}' \
    '{"command":"session.quit"}' | factoria session
  ```

- `factoria call --batch '<json array>'` runs the commands in order on one engine and prints `{"ok", "results": [...]}`. It stops at the first failure (add `--keep-going` to continue). Options such as `--scene`, `--press a,b` (actions held before the first command) or `--input replay.json` go after the array:

  ```
  factoria call --batch '[{"command":"game.step","args":{"frames":30}},{"command":"script.eval","args":{"code":"time.elapsed"}}]'
  factoria call --batch '[{"command":"game.state","args":{"entities":["player"]}}]' --press move_right
  ```

Inside `script.eval`, the globals are the `"factoria"` names: `world`, `input`, `time`, `session`, `physics`, `rng` and the rest. `game` there is the game object (`game.paused`, `game.project`, `game.screenSize`), not the test object: `game.world` and `game.time` do not exist in scripts.

### 11.2 Input replays

`factoria run --headless --frames N --input replay.json --state-out state.json --json` drives a headless run from a file. Frames are 0-based. An entry is applied before its frame is simulated. A screenshot listed for frame N is taken after frame N was simulated. Each entry may hold:

- `press` and `release`: action names (held until released) or key names.
- `keys`: raw keys, `{"Space": true}` for down, `false` for up.
- `mouse`: `{"position": [x, y], "left": true, "right": false, "middle": false}` in design pixels.
- `gamepad`: `{"index": 0, "buttons": {"A": true, "DpadLeft": false}, "axes": {"LeftX": -1, "RightTrigger": 0.5}}`, or an array of those for several pads. `index` is 0 to 3 (default 0), `"connected": false` unplugs the pad. Buttons are `A B X Y Start Back Guide DpadLeft DpadRight DpadUp DpadDown LeftShoulder RightShoulder LeftThumb RightThumb`; axes are `LeftX LeftY RightX RightY` (-1..1, +Y up) and `LeftTrigger RightTrigger` (0..1). The state stays until a later frame sets it again, so set an axis back to 0 to release the stick.
- `clipboard`: a string put on the (in-memory) clipboard before the frame; a focused TextField reads it when `keys` presses Ctrl+V.
- `http`: an array of answers to the game's `http.fetch` calls from this frame on, first in first out: `{"result": {"status": 200, "headers": {}, "text": "{}"}}` or `{"error": "network", "message": "timed out", "hint": "Try again."}`. The headless run uses the fake backend, so a request nobody has an answer for is rejected with `network`. Editor play sessions record what the server said ([NETWORKING.md](../NETWORKING.md), "Replays").
- `touch`: `{"id": 1, "position": [x, y], "down": true}`, or an array for several fingers. `down` defaults to true: a new `id` begins a finger, a known `id` moves it; `"down": false` lifts it (`position` is not needed then). The first finger also drives the mouse, as on a device.

```json
{
  "frames": {
    "0":  { "press": ["move_right"], "mouse": { "position": [640, 360], "left": true, "right": false, "middle": false } },
    "5":  { "keys": { "Q": true } },
    "6":  { "keys": { "Q": false } },
    "30": { "release": ["move_right"], "mouse": { "position": [640, 360], "left": false } }
  }
}
```

Optional `"timing": [[dt, fixedSteps], ...]` (one pair per frame, from frame 0) makes `factoria run --headless` run frame N with that frame time and that many fixed steps instead of one fixed step. Editor play sessions record it so their replay is exact; frames past its end step normally.

The same format works with `factoria call --input` and `factoria session --input`, which apply it while stepping (they ignore `timing`).

### 11.3 Other checks

- Errors name their location (file and JSON pointer), what is wrong and how to fix it. Unknown component or field names come with a "did you mean" hint. Read the hint first.
- A command (or a `project_<name>` tool) refuses an argument it does not declare: code `invalid_arguments`, message `Invalid arguments for 'game.input': /frame: unknown property 'frame'`, hint `Did you mean 'frames'? Valid: ...` with the accepted keys. Nothing runs, so the call changed nothing: fix the spelling or drop the key, and call `describe`/`tools/list` to see the accepted arguments. A required argument you misspelled shows up as two errors (the missing one and the unknown one); the hint of the first names your near miss. Your own tool in `tools/<name>.js` works the same: declare every key it reads in `input.properties`; `additionalProperties: true` on an object is the explicit opt-out for free-form keys.
- Black or empty screenshot: check for a primary `Camera`, that sprites have a `layer` and a size, that colours are 0..1 (not 0..255), and that world and screen space are not mixed up. A Text or panel in the wrong corner usually has the wrong `anchor` or `pivot` (section 9.4). If the machine has no GPU, the engine runs in logic-only mode and `game_screenshot` says so. Then rely on `game_state` and `game_logs`.
- Body that does not move: check its `type` (static never moves), that it has a collider, its `layer` and `mask`, and the sign of gravity in `settings.gravity2D`.
- A patrol or sensor that turns around on its first step: the first physics step has not run yet (section 9.14).
- Results differ between runs: look for `Date.now()` or `new Date()` (the real clock; `Math.random` is routed to the
  seeded world RNG), or for timing. A script that never reads the real clock repeats exactly.
- Tool errors: a tool that throws `ToolError` returns `code` `tool_error`, the `message` and the `hint`. The hint is how to fix the data. Extra `data` appears in the JSON error of `factoria session` and `call --batch`, and as `e.data` on the Error that `fa.call` throws inside a script or test; MCP shows only the code, message and hint, so put the facts a fixer needs in the hint.

### 11.4 REVIEW.md: make the game easy to review

When the user asks for an art critique or a game review (editor AI panel, `factoria ai review`), read-only agents play the
build in a few minutes and give a score ([AI_PROVIDERS.md](../AI_PROVIDERS.md), "Reviews"). They can only look and play, so
the game must show itself to them. Keep these in place as the game grows:

- **`REVIEW.md` at the project root**, the note they read first. It is never exported. Sections: *How to play* (controls,
  the goal, what a session looks like), *Status* (what is finished and what is a placeholder, so nobody judges a
  placeholder as final), *Reach everything fast* (every scene, level and state and how to get there in one step),
  *Bot-playable flows* (`scripts/autoplay.js`, the hook that `play.auto` runs, and input replays or tests that play the first minutes, a whole level, the ending) and *Known issues*
  (what not to report again).
- **Every scene and state reachable in one call**: a boss, the shop, game over or the last level must not need an hour of
  play. Name the way in REVIEW.md: scene paths for `scene_load`, a project tool in `tools/*.js`, a debug key or cheat
  action, start-scene props, saved states under `review/`.
- **Stable screenshots**: a fixed seed, and no random camera shake or fade at the moment a picture is taken.
- **No debug overlay in normal play**: cheats and debug entry points live behind a key, an action or a tool that REVIEW.md names.
- **A `scripts/autoplay.js` that plays the game** (section 11.5): the game reviewers run `play.auto` after they have played
  by hand, and its phases tell them which parts they did not reach. It supports their hands and never replaces them (the
  bot finishing the level says nothing about whether a person finds it clear or fair).

### 11.5 Play the game yourself: `play.auto`

After a feature or a fix, and BEFORE you ask the user to play, run `play_auto` (`factoria call play.auto`): a bot plays the
game headless and fast for `seconds` of game time and writes a play session. Without a hook it explores the declared input
actions with a seeded generator; with `scripts/autoplay.js` (`game.autoplay`, [SCRIPTING.md](../SCRIPTING.md#the-bot-gameautoplay))
it plays the way you describe, marks the stages (`game.phase`) and says when the level is done. Read the answer in this order:

1. `ended`: `won`, `lost`, `timeout` (it played the whole time without a problem), `stuck` (nothing moved or changed) or
   `broken` (a fall, a NaN position, a script error every frame, or a hook that could not load: mark kind `hook` means
   `scripts/autoplay.js` failed to import, nothing was played).
2. `problems`: one mark each (kind `stuck`, `menu`, `fall`, `not finite`, `exception loop`, `hook`) with the step, the game time, a note and a
   screenshot. `play_report {"session": "...", "mark": 2}` shows the next one. A `menu` mark is a screen the bot could not
   leave: give it a button the actions can reach, or teach the hook to press it.
3. `phases`, the score and the perf: which stages it reached and how long each took. A phase missing from the list is one
   it never reached, which is worth a look by hand.
4. The warnings and errors the game logged during the run.

The session's `input.json` replays a problem: `factoria run --headless --input <input.json> --seed <seed>`. Keep
`scripts/autoplay.js` in step with the game: when the way through changes, the bot must still finish the level. A green run
means the game can be finished by a script, not that a person finds it clear or fun: that is still the user's call. In the
editor the user can start the same run from **Play > Let the AI play**; it appears in the Play sessions list marked "auto".

## 12. Common mistakes

- Reading raw keys in gameplay. Declare an action in `factoria.json` and read the action.
- Using `Date.now()` or `new Date()` (the real clock) or `Math.random` (it works, drawing from `rng`, but write `rng`).
  Use `rng`, `dt` and `game.today()`.
- Mixing colour scales. `[255, 128, 0, 255]` is read as 0..255 because a channel is over 1, so `[255, 255, 255, 1]` has an alpha of 1/255 and `[1, 1, 1, 255]` is black; use 0..1 for every channel, or `"#rrggbb"`. `factoria validate` warns about a mixed array (JSON pointer, both readings).
- Misspelling what a script imports or calls: a wrong name in `import { Behaviour } from "factoria"`, `physics.raycats`, `entity.get("Transfrom")`, a `fa.call("project.<tool>")` in a game script (tools are not exported), or a top level that throws. `factoria validate` reports each with `file:line:column` and a "did you mean" (docs/SCRIPTING.md, "What `factoria validate` checks in a script"); run it after every script edit.
- Keeping your own data on an entity (`entity.hp = 3`) and reading it before it is written. In `test`, `run` and the editor reading a member an `Entity`, `input`, `world`, `expect(...)` or another namespace does not have throws (`'input' has no 'axs'. Did you mean 'axis'?`); the exported player gives `undefined` instead, so fix it where it throws. Keep state in the Behaviour (`this.hp`) or in a component's fields (docs/SCRIPTING.md, "Reading a member that does not exist").
- Writing a component name in the wrong case (`entity.get("transform")`). It works and logs one warning with the exact name; write `"Transform"`.
- Expecting +Y to point down in the world. In the world +Y is up. Only screen-space UI has +Y down.
- Treating tilemap row 0 as the bottom row. Row 0 is the top row.
- Forgetting the primary `Camera`.
- Using `pivot: [0, 0]` for top-left screen text. Text pivots are y-up: top-left is `[0, 1]`.
- Expecting Tilemap solid tiles to be one-way. Use a one-way entity for jump-through ledges.
- Copying the map size into camera limit props (`minX`, `maxX`, ...). They go stale when the map changes. Read the rectangle from the Tilemap with `entity.bounds()` (section 9.6).
- Seeding a level generator with `rng.seed(n)`. That reseeds the game's one RNG. Use `rng.create(n)` (section 9.16).
- Placing coins, enemies and spawn points by hand, or writing a script that generates the level. Put them in the legend of `scene.import_ascii` (section 9.8) and re-import after every edit.
- Probing for ground in the first fixed step after a spawn (section 9.14).
- Reading `game.world` or `game.time` in `script.eval`. Use `world` and `time`.
- Editing `types/factoria.d.ts` or `.factoria/`. Both are generated.
- Guessing a component field or command argument. Check `factoria api --md` and `factoria commands`.
- Changing only the running game (`scene_spawn`, `scene_set_component`) and then forgetting that the scene file did not change. Save the scene (`scene_save`) or write it in the file.
- Writing a prefab file by hand to capture something you already built in the running game, or laying out JSON by hand. Save it with `prefab_save` and tidy hand edits with `scene_format` (section 6).
- Skipping THE FEEDBACK RULE because the workaround "works".

## 13. Performance

- Build a level with one `Tilemap` rather than hundreds of sprites. Its solid tiles become a small number of merged colliders. An isometric ground (`projection: "isometric"`) is also one Tilemap, not a sprite per cell (Tidewater Market went from about 2700 ground entities to one).
- Use `burst` with `autoDestroy` for one-shot effects, and set `maxParticles` for continuous ones.
- Look up entities once in `onStart` and keep the references. Calling `world.find` every frame adds up.
- Use `RigidBody2D.bullet: true` only for fast, small bodies.
- 3D physics handles spheres, capsules, convex hulls, static triangle meshes and (oriented) boxes, plus hinge/ball/fixed joints and a character controller. Fast bodies are swept against every solid collider. A `mesh` collider is static only; jointed bodies never sleep. Path finding over 3D ground (around walls, up ramps): a `NavMesh3D` component baked from the static colliders and `nav.findPath(from, to)` in scripts, see [NAVIGATION.md](../NAVIGATION.md) (`docs_read {"name":"navigation"}`). 2D tile maps: `nav.findTilePath(map, from, to)` (A* over a Tilemap or your own cost grid) and `import { bt } from "factoria"` for behaviour trees, section 9.27.
- Keep iteration runs short. 120 frames is 2 seconds of game time.
- Load big levels in the background (`scene.load(path, props, { async: true })`, section 9.11): the frame never waits for a file in a windowed game, and each frame spends at most `runtime.loadBudgetMs` (default 4) and uploads at most `runtime.uploadBudgetMB` (default 16) to the GPU on it. It costs nothing while no load runs; while one runs, the files read ahead (about one scene's) stay in memory until the second scene load after it. `load.status` shows the progress and `warmBytes` (PERFORMANCE.md, "Background loading").
- The engine spreads some of its own work over worker threads; `runtime.jobThreads` in factoria.json sets how many (`"auto"`, the default, a number 0..32 written without quotes, or `"inline"` to debug). Threads never change what the game computes: `game.state_hash` gives one hash of the whole state, the same at the same frame with any setting, and `jobs.info` says what runs (PERFORMANCE.md, "Job threads").
- **Start-up.** A new project ships a `perf.json` with `"budgets": {"maxStartupMs": 5000}` (`perf.startup`): the most CPU milliseconds the game may take from reading its files to its first frame (`startupMs` in `perf.measure`; `factoria call perf.check` fails over it when `CI` is set and warns elsewhere). The player already shows a first (black) frame before it reads the game, and makes the first scene's GPU pipelines over the next frames, so you never wait for that; `play.report` `loading.startup` has `firstPresentMs` (how long the window stared at nothing) and `firstGameFrameMs` (until the game is playable) apart. Keep `startupMs` low by loading only the first screen in the start scene (the rest in a scene or prefab loaded later), shipping big PNGs as KTX2, and keeping heavy work out of `onStart` (spread it over frames or generate it ahead of time). Keep the budget wide (a few seconds) so it catches a game that became slow, not a busy machine; see [PERFORMANCE.md](../PERFORMANCE.md#startup).

## 14. Where to read more

- `factoria docs read scripting` (MCP `docs_read {"name":"scripting"}`): the full JavaScript API, tools and tests.
- `factoria api --md` and `factoria commands` (MCP `docs_components` and `docs_commands`): generated references for this build.
- `factoria docs read game-feel` (MCP `docs_read {"name":"game-feel"}`): camera shake, hit-stop, flash, knockback and squash and stretch, their clocks and accessibility.
- `factoria docs read effects` (MCP `docs_read {"name":"effects"}`): the draft, film, look, refine loop for hit sparks, pickups and fires, with three worked examples.
- `factoria docs read animation` (MCP `docs_read {"name":"animation"}`): the Animator component (clips, cross-fades, events, state machine) and `tween` / `ease`.
- `factoria docs read extending` (MCP `docs_read {"name":"extending"}`): how to add project tools, native plugins (C/C++ for one game) and engine commands.
- `factoria docs read cli` (MCP `docs_read {"name":"cli"}`): every command and flag.
- `factoria docs read menus` (MCP `docs_read {"name":"menus"}`): a main menu, options, credits, a loading screen
  and a pause menu to copy into a game, and a shop for a game with in-app purchases.
- `factoria docs read platform` (MCP `docs_read {"name":"platform"}`): achievements, stats, leaderboards, cloud saves
  and purchases through one API, the fake store for tests, and how a native plugin becomes a store backend.
- `factoria docs read localization` (MCP `docs_read {"name":"localization"}`): string tables, `key` fields,
  plurals and placeholders, the `i18n` script API, `i18n.state` / `i18n.set_language` / `i18n.export` / `i18n.import`,
  fonts per language, what `factoria validate` checks, and how the start language is chosen.
- `factoria docs read finishing` (MCP `docs_read {"name":"finishing"}`): the ordered path from a playable prototype to a
  game ready for a store: menus, options that persist, versioned saves with migration and a damaged-save screen,
  localization and right-to-left checked at 200 % text, accessibility, store services, credits, tests and a checklist.
- `factoria docs read ai-costs` (MCP `docs_read {"name":"ai-costs"}`): what a whole game cost in tokens and money
  (measured), what drives the cost, the `limits` that cap it and where to see what was spent. Tell the user when a
  task is going to be long or dear.
- `factoria docs read analytics` (MCP `docs_read {"name":"analytics"}`): usage events sent after the player consents,
  values read from your server with an offline cache, the menu kit's question, tests without a server and what to tell the
  stores. `factoria docs read networking` has the `http.fetch` they stand on.
- The project's `AGENTS.md`: short rules for this game.
