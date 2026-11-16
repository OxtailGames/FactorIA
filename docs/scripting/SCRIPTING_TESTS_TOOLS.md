Part of [SCRIPTING.md](../SCRIPTING.md): Script tests (`tests/*.test.js`), tools (`tools/*.js`), hook modules and runtime notes.

# Scripting: tests tools

## Tools (`tools/*.js`)

```js
// tools/spawn_wave.js — becomes command "project.spawn_wave" / MCP tool "project_spawn_wave"
import { world, rng, vec2 } from "factoria";

export default {
  name: "spawn_wave",
  summary: "Spawn a wave of enemies at random positions.",
  description: "Example: {\"count\": 8}. Returns the ids of the spawned enemies.",
  input: { type: "object", properties: { count: { type: "integer", minimum: 1, default: 5 } } },
  readOnly: false,
  run({ count }) {
    const ids = [];
    for (let i = 0; i < count; i++) {
      const e = world.spawnPrefab("prefabs/enemy.prefab.json", { position: vec2(rng.range(-600, 600), 300) });
      ids.push(e.id);
    }
    return { spawned: ids };
  },
};
```

A tool's arguments are closed: a key that `input` does not declare is refused before `run` (`invalid_arguments`,
`/cuont: unknown property 'cuont'`, hint with the closest declared key and the accepted ones), and a tool with no `input`
takes no arguments. Declare every key `run` reads. For an object whose keys are open-ended, opt out on that object:
`additionalProperties: true` (any key) or a schema such as `{ type: "number" }` (every extra value must match it).

Tools hot-reload when the file changes; MCP clients are notified. A tool file created while `factoria mcp` runs (even
when the project had no `tools/` folder at start) is registered before the next request is handled, so `tools/list`,
the MCP tool `project_<name>` and `fa.call("project.<name>")` see it at once; `script.eval {module, call}` re-imports
every loaded module whose file changed on disk before it runs, so the call never uses the code from before the edit.
(The watcher is off with `factoria mcp --no-hot-reload`; then use `script.reload` or `scene.reload`.)

Calling a project tool never runs a stale version either, watcher or not (also in the editor's MCP session): before the
call, the tool file and every module it imports are compared with their modification time on disk, and what changed is
re-imported (not while another command is running: a tool that calls a tool uses what was loaded at the outer call).
When the tool returns an object, the result gets a `toolVersion` field `{file, hash, loadedAt}`: the first 16 hex digits
of the sha256 of the tool file as it ran, and when it was loaded (UTC). A result that is an array or a scalar has none.
A `toolVersion` your tool returns itself is kept. If a result lists old behaviour, compare `hash` with the file.

**Failing a tool.** `throw new ToolError(message, hint, data?)` (from `"factoria"`) reports an *expected* failure
(for example a check tool that found bad level data): the caller gets code `tool_error`, the message, your `hint`
(how to fix the data, not the tool) and, if given, `data` (any JSON). `data` travels as the structured field `error.data`
(MCP and `factoria call` print it next to the message; it is not appended to the message). Any other thrown Error is a script bug: code `failed`, the message with `file:line`, and it is
also recorded as a script error. `ToolError` is not recorded as a script error.

## Hook modules (`hooks/*.js`)

A hook module is a JavaScript file in the project's `hooks/` folder that FactorIA runs when the AI or the engine reaches an event
(before a tool call, after a command, when the AI wants to stop...). It is **not a game script and not a tool**: it runs in a
QuickJS runtime of its own with the language and `console` and nothing else. There is no `world`, `fa`, `input` or `assets`, no
`fetch`, no files, no timers and no way to start a program, which is why it needs no trust even in a downloaded project. It has the
handler's `timeout` (default 60 s) and a 64 MB memory limit, and answers synchronously. `import "./helpers.js"` works for files inside
the project; there are no packages.

The module exports one function per event, named like the event (`SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`,
`PostToolUseFailure`, `Stop`, `SessionEnd`, `beforeCommand`, `afterCommand`), on the default export or as named exports; a default export
that is a function is called for every event. The argument is the event as an object (`tool_name`, `tool_input`, `command`, `args`...) and the return
value is the answer: `{decision: "block", reason}` refuses where the event can, `{continue: false, stopReason}` stops the run,
`{hookSpecificOutput: {additionalContext, updatedInput}}` adds context or changes the arguments, a string is context for
`SessionStart` and `UserPromptSubmit`, and nothing means "no opinion". `console.log` goes to the hook's log, not to the model.

```js
// hooks/guard.js
export default {
  PreToolUse(input) {
    if (input.tool_name === "scene_delete") return { decision: "block", reason: "Ask the user before deleting a scene." };
  },
};
```

Register it in `extensions` (`{"type": "js", "module": "hooks/guard.js"}`), try it with `factoria call ai.hooks_test` or
`factoria hooks run hooks/guard.js`. The events, the fields and every decision are in [HOOKS.md](../HOOKS.md).

## Tests (`tests/*.test.js`)

```js
import { test, expect, game } from "factoria:test";

test("player jumps", () => {
  game.load("scenes/main.scene.json");
  game.step(5);                         // let things settle
  const player = game.find("player");
  const y0 = player.position.y;
  game.press("jump");
  game.step(10);
  game.release("jump");
  expect(player.position.y).toBeGreaterThan(y0);
});
```

- `test(name, fn, options?)`, `test.skip`, `describe(name, fn)`
- **A test fails when the game fails.** Besides its assertions, a test fails when a game script threw while it ran (a callback such as `onUpdate`, an event handler, a promise, a module's top level) or the engine logged an `ERROR` (a missing sound or file, a refused command). The message is the first such error with its file and line, and the summary counts these failures (`2 passed, 1 failed (1 because the game logged an error ...)`, and `loggedError: true` on the case with `--json`); the exit code follows. A script error is reported to every test that causes it, not only the first. `console.error` and `console.assert` are not errors. A test that is about an error says so with `game.expectErrors(/pattern/, ...)` (a RegExp, or a string that is part of the text) or `test(name, fn, { expectErrors: [/pattern/] })`: those errors do not fail it, any other one still does, and an expected error that is never logged fails it too. Each test starts with the once-per-run errors of the audio system (a missing audio file) and of scripts forgotten (the engine's other once-per-run errors are not), so every test that causes one sees it, whatever ran before and whatever `--filter` selected. Errors count from just before the test's own reset (not from the test file's import: an import error is reported as a load error of the file). An `expectErrors` pattern is matched against the error's message, which for a script error includes its stack text. `test.skip` checks its arguments like `test`; `test.skip("name")` with no function is a pending test (reported as skipped). If a run logs more than 20000 ERROR records, the extra ones are counted in a final error that says how many were dropped. Fix the script rather than expecting its error.
- `robust(check, { runs = 5, nudge = 0.005 })`: runs `check(p)` `runs` times under small repeatable perturbations and fails naming the run that failed. Run 0 is not perturbed; `p.nudge(...entitiesOrIds)` moves entities by up to `nudge` metres per axis and `p.nudgeBodies()` does it for every RigidBody2D/3D (call it after `game.load`, before the first `game.step`; the check loads its own scene). Offsets are a hash of the run, the entity id and the axis, not the RNG, so a test nudges the same way everywhere. The engine's physics gives the same bits on Linux, Windows and macOS (AI_GUIDE.md, "Physics and platforms"), but a change to a level, to a script that feeds numbers into physics, or to the engine moves a chaotic setup anyway: use `robust` where a level test would otherwise assert an exact frame count or position of such a setup, and assert what holds for every run (reached, delivered, a range, "not slower than").
- `expect(v)`: `toBe toEqual toBeCloseTo(n, digits) toBeGreaterThan toBeGreaterThanOrEqual toBeLessThan
  toBeLessThanOrEqual toBeTruthy toBeFalsy toBeNull toBeDefined toContain toHaveLength toThrow`, and `.not`;
  for sounds `expect(game.audioLog()).toContainPlayed(path, { times?, bus?, source? })` (alias `toHavePlayed`; `path`
  is a project path, a file name such as `"jump.wav"`, or a RegExp; plays whose clip failed to load do not count)
- `game`: `load(path)` (behaviours are constructed immediately, `onStart` runs on the first `step`),
  `loadJson(sceneObject)`, `step(frames = 1)`, `touch(pos, frames = 1)`, `touchStart(pos, id?)`, `touchMove(pos, id?)`,
  `touchEnd(id?)` (fill `input.touches`; `pressed` is true for the frame after `touchStart`; like a finger on a device,
  the first finger also moves the mouse and holds the left button, so `touch` alone tests mouse handling too: no
  `click` needed), `press(action)`, `release(action)`, `tap(action)`
  (taps the first key, else the first gamepad button, bound to the action, so the UI and every action on that key see it:
  `tap("ui_submit")` presses the focused Button or Toggle; an action with only a stick, mouse or no binding is held as the action),
  `keyDown(key)`, `keyUp(key)` (hold and release; `"Ctrl"`, `"Shift"`, `"Alt"`, `"Super"` work, so `keyDown("Shift"); click(pos);
  keyUp("Shift")` is a Shift+click), `tapKey(key)` (`tapKey("Ctrl+Z")` holds Ctrl while Z is tapped), `gamepad(index = 0)`, `mouseMove(screenPos)`, `click(screenPos, button?)`, `find(idOrName)`,
  `world`, `time`, `screenshot(path, {scale?})` (scale 0.25 to 4 renders natively larger), `state()`, `audioLog()` (sounds played since the test started:
  `[{ kind, voice, fade, seq, frame, time, path, volume, pitch, pan, bus, loop, music, source, ok, layer }]`, cleared before each test),
  `today()`, `setDate("YYYY-MM-DD")` (the fixed date is `2026-01-01`; reset before each test), `focused`, `suspend()`, `resume()`,
  `focus()`, `blur()` (what the OS does to the app, so lifecycle code can be tested),
  `renderStats()` (what the renderer drew in the picture now, drawing a frame first when none was drawn: `{ drawCalls,
  triangles, lights, shadowCasters, meshes, textureMB, width, height, renderScale, ... }`; throws without graphics),
  `setDevice({ formFactor?, gpuBackend?, memoryGB?, tier?, steamDeck?, handheld? })` (see `game.device`),
  `clearAudioLog()`, `spoken()` (what `ui.speak` was asked to say: `[{ text, language, interrupt }]`, cleared before each test), `clearSpoken()`

More `game` calls for tests: `mouseDown(button = "left")` and `mouseUp(button)` hold and release a mouse button (`input.mouse.down(button)`
follows; with `mouseMove` they test a drag), `wheel(dy)` turns the wheel for the next frame
(`input.mouse.wheel`), `quitRequested` (true once the game asked to quit with `game.quit()` or an unconsumed Back; a test
run never stops because of it, and it is cleared before each test), `closeWindow()` (the player pressed the close
button: raises `game.on("quit")` and returns true when the window would close, false when a handler cancelled), `setSystemLanguages(["es-ES", "en"])` (what
`i18n.systemLanguages` answers, so a game's own first-run language choice can be tested; the engine's start language is
not picked again, a test starts in the default language; empty again before each test) and
`resetState({ storage = true, platform = true, audio = true })`, which clears the save data, resets the fake store (purchases,
unlocks, ads, leaderboards; see docs/PLATFORM.md) and stops the music (`persist: true` too, at once) and every voice, between tests of one file. Each test file already starts clean; tests of
one file share storage and the fake store unless you call `resetState`.

**Clicking a widget.** `game.click(widget)` (also `mouseMove`, `touch`, `touchStart`, `touchMove`) given an `Entity` or an
id/name lays the UI out first, so a panel opened in the same frame (`panel.active = true`, then `game.click("close")`) is
already in place with no `game.step` or `ui.layout()` between. It throws, naming the widget and why, when the widget cannot
be clicked: it or a parent is inactive, it has no area (size 0), or it is scrolled out of its `ScrollList`. Pass a position
`{x, y}` to click a spot whatever is there. Outside a test, the command `game.click` (MCP `game_click`: `{"id":"close"}`, `{"position":[x,y]}` or `{"world":[x,y]}`) does the same sequence on the running game.

**Keys.** `game.tapKey(key)` presses and releases a key over one frame (press, step, release, step), as `tap` does for an
action; `keyDown` / `keyUp` hold it. `game.tap(action)` is `tapKey` of the action's first key (or a tap of its first pad
button), so it goes through the UI like a player: `game.tap("ui_submit")` presses the focused Button. A `TextField` reads the Enter key itself, not an action, so this submits it:

```js
test("Enter submits the name", () => {
  game.load("scenes/menu.scene.json");
  const submitted = [];
  ui.on("submit", "name_field", (e) => submitted.push(e.value));
  game.click("name_field");                              // focuses the TextField
  game.find("name_field").set("TextField", { text: "Mara" });
  game.tapKey("Enter");                                  // the field sends ui.submit { id, value: "Mara" }
  expect(submitted).toEqual(["Mara"]);
});
```

**Saving a file from a test.** A test can call any command with `fa.call`, and `fs.write` writes a project file (text up to
8 MiB; `.factoria/` is refused except `.factoria/tmp/`): keep a recording or a layout dump to look at afterwards.

```js
test("dump the menu layout", () => {
  game.load("scenes/menu.scene.json");
  game.step(5);
  fa.call("fs.write", { path: "build/menu_layout.json", content: JSON.stringify(fa.call("ui.state"), null, 2) });
});
```

**Commands from a test.** `fa.call(name, args)` runs any command and returns its result. Scripts have no `ui.state()`
function (`ui` has `rectOf`, `widgetAt`, `focus`...): the list of widgets is the command, `fa.call("ui.state")`, and the
localization state is `fa.call("i18n.state")`.

The registry of a test is that of `factoria test`: the engine's commands and the project's tooling commands (`game.*`,
`ui.*`, `fs.*`, `project.*`, `assets.regenerate`, `anim.*`...), plus the read-only `assets.provenance` and `assets.disclosure`
(what an assets test needs: every asset has a recipe or a record, no file without provenance). A command that is not there
answers "Unknown command". The ones missing are those of the AI module, which call a provider, the user's AI settings or
the review queue, or write the manifest by hand; they belong to `factoria call`, the MCP server and the editor. A test
keeps this list true.

<!-- fa-call-not-in-tests -->
- Not available: `ai.*`, `skills.*`, `assets.generate_image`, `assets.generate_sprite_sheet`, `assets.generate_sound`, `assets.generate_music`,
  `assets.generate_voice`, `assets.generate_model`, `assets.pick`, `assets.review`, `assets.set_provenance`,
  `image.generate_layer`, `image.inpaint`, `vfx.review`
<!-- end -->

```js
test("every widget fits and the Spanish table is complete", () => {
  game.load("scenes/menu.scene.json");
  game.step(5);
  const widgets = fa.call("ui.state").widgets;             // the current frame: ids, rect, focused, visible
  expect(widgets.some((w) => w.id === "play_button")).toBe(true);
  const es = fa.call("i18n.state").languages.find((l) => l.code === "es");
  expect(es.missing).toBe(0);                              // keys the default table has and Spanish lacks
  const report = fa.call("ui.check_layout", { textScales: [1, 2] });  // see below: it reloads the scenes
  expect(report.issues).toEqual([]);
});
```

`ui.check_layout` loads each scene again (in each language and text size) and then loads the running scene once more, so
it does not see the state of the current frame and the game state is lost: call it on a fresh scene, and read
`ui.state` before it, not after.

**Layout of what is open.** `game.checkLayout(options?)` is `ui.check_layout` with `current: true`: it measures the scene that
runs, as it is now, with the panels the test opened, and loads nothing (the game state is kept; it steps a few frames per
case and puts the language, text size and interface scale back). `options` are `languages`, `textScales`, `uiScales`,
`pseudo` and `settleFrames` of the command.

```js
test("the options panel fits at 200 % text in every language", () => {
  game.load("scenes/menu.scene.json");
  game.click("options_button");
  expect(game.checkLayout({ textScales: [1, 2], pseudo: false }).issues).toEqual([]);
});
```

### Scene props

`scene.load(path, { level: 3 })` starts the scene with props: a plain JSON object (numbers, strings, booleans, arrays, objects;
not functions) that the new scene's scripts read with `game.sceneProps()`, from their first `onStart`. Each call returns a
fresh copy, so changing it changes nothing. `factoria run --props '{"level":3}'` (or a `.json` file) starts the first scene with
props; `game.load(path, props)` and `game.loadJson(scene, props)` do the same in a test.

```js
onStart() { const level = game.sceneProps().level ?? 1; }
```

- A **reload** (`scene.reload()`, the `scene.reload` command, hot reload of the scene you are running) keeps the props.
- A load **without props** (`scene.load(path)`, `game.load(path)`) gives the new scene `{}`: props never leak into the next
  scene by themselves. Pass them again to keep them: `scene.load(path, game.sceneProps())`.
- When several loads are asked in one frame, the last one wins, props included.
- `scene.load` command: `props` is an object argument with the same meaning.

**`scene.load` and `game.load` differ.** `scene.load(path)` called from a test (or from a script) takes effect at the start
of the next frame, as in a game: `scene.current` changes at once but the new scene's scripts start on the next
`game.step()`. `game.load(path)` is immediate: the scene is loaded and its behaviours constructed before it returns. After
`scene.load` step one or two frames before reading the new scene's state.

`game.gamepad(index = 0)` drives a pad: `press(button)`, `release(button)`, `tap(button)` (press, step, release, step, like
`game.tap`), `axis(name, value)`, `connect()` and `disconnect()`. Like `keyDown`, `press`, `release` and `axis` act at once and
the next `game.step` sees them; they connect the pad. Actions bound to `Gamepad*` names react as they do to a real pad:

```js
test("the stick moves the player", () => {
  game.load("scenes/main.scene.json");
  game.gamepad(0).axis("LeftX", 1);        // a full push right: input.axis("move_left", "move_right") is 1
  game.step(30);
  expect(game.find("player").position.x).toBeGreaterThan(0);
  game.gamepad(0).tap("A");                // jump
});
```

Bad button or axis names and indices outside 0..3 throw with a "did you mean".

`game.setSlider("music_volume", 0.5)` drags a Slider to a value the way a player does: the value is clamped to `min`..`max` and
snapped to `step`, the slider takes focus and `ui.change` `{ id, value }` is sent (nothing when it already had that value). It
throws for an entity that is no Slider, or is inactive or not interactable. Writing `slider.value = 0.5` from a script is
different: it changes the value and sends NO `ui.change` (the same for a Toggle's `value` and a TextField's `text`), so a test
that wants the game's `ui.on("change", ...)` code to run uses `game.setSlider`. The same thing is the `ui.set_slider` command.

Options-menu tests: `game.typeText("héllo")` types characters (what `input.text` returns for the next step; control
characters are skipped) and `game.gamepad(i).setType("playstation")` plugs the pad in as that family, so
`input.buttonName("jump")` answers "Cross" instead of "A". `rebind`, the cursor and the keyboard request are reset
between tests. `window.*` setters throw in tests (no window): test the logic around them, not the toggle itself.

Phone tests: `game.pressBack()` is the Back button (the next `game.step` runs the `input.onBack` handlers; with none
consuming it the headless run asks to quit), `game.setSafeArea("phone-portrait")` fakes a notch (`"phone-landscape"`,
`"none"`, or `{ top, left, right, bottom }` in design pixels) so `screen.safeArea` and every `safeArea: true` item move,
and `game.vibrations()` lists the seconds `input.vibrate` was asked for. All three are cleared between tests.

Each test FILE starts from fresh module instances (module-level state is
re-created, tools are re-evaluated against them), an empty in-memory `storage`
(the real save file is never read or written) and an empty `session`. Within a
file, state carries over between tests unless you reset it.

Tests run inside the current engine (only one renderer can exist per
process). Between test files the runner reloads the project's start scene,
reseeds the world RNG with the project seed, clears input overrides, timers and
behaviours; `game.load` also reseeds. Before each test input overrides, the gamepads (unplugged),
`input.deadzone` and `ui.scale` (back to the project's value), `ui.textScale` (1), `time.scale`, the game feel effects, hit-stops and `feel.reduceMotion` / `feel.reducedEffects` (back to following the system), the audio log and the
mouse (position back at 0, 0, no wheel; a `game.click` or the last test of the previous file does not decide what the pointer hovers) are reset;
keys, mouse buttons and touches are released. Results are deterministic. Extras: `describe.skip`,
`beforeEach(fn)` / `afterEach(fn)` inside `describe`, matchers `toBeUndefined`,
`toBeNaN`, `toMatch`, `toBeInstanceOf`, `toMatchObject(subset)` (every field of the subset is in the
received object with an equal value, recursively; the object may have more). Failures print expected/received and
`file:line` of the failing `expect`. A `TypeError: ... is not a function` in a test or a script shows the source line
with a caret under the call, because QuickJS does not name the missing function.
A test that spends more than 60 s of CPU time (an endless loop, a `while` waiting for something that never happens) is
stopped, and the rest of its file is skipped; a file has no limit of its own, so split a test, not the file. The limit counts
the time the engine actually computed, not the wall clock, so a busy machine does not fail a test; a test blocked without
using CPU is stopped after 8 times the limit (480 s) on the clock. The limit is fixed (60 s per test, 5 s for
`script.eval`): if a test needs more, it does too much for one test, so split it or lower the amount of work (fewer
entities, fewer steps).

Timing in a test: `world.emit(name, data)` is queued, and its listeners (`world.on`, `onEvent`) run at the next
`game.step`, so call `game.step(1)` after emitting before you check or await a script that waits for it. The answers
of `platform.*` (the fake store) are served inside the call, unless `game.platform.set({ delayFrames })` holds them; the Promise settles in the next microtask, one per `await` of a chain (docs/PLATFORM.md, "The fake store"). Run only some
test files with `factoria test <project> tests/saves.test.js "tests/ui*.test.js"` (MCP `project_test` takes `files`).

## Runtime notes
- `Math.random()` is routed to the deterministic world RNG (`rng.*`; write `rng`). `Date` is NOT replaced in game
  scripts: `Date.now()` and `new Date()` read the real wall clock, so never use them in simulation (`game.today()`).
  Only `assets.animate_svg` modules (`.anim.js`) get a fixed `Date` (ASSETS.md).
- `Math.sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`, `exp`, `expm1`, `log`, `log2`, `log10`, `log1p`, `pow` (and
  `**`), `sinh`, `cosh`, `tanh`, `asinh`, `acosh`, `atanh`, `cbrt` and `hypot` are the engine's deterministic functions
  (`fa::det::f64`, built only from `+ - * / sqrt` on doubles): the same bits on Windows, Linux, macOS, Android, iOS and the
  web, where the C library's last bit differs between them. They are accurate to a few units in the last place of the exact result:
  `exp`, `log`, `log2`, `log10`, `cosh`, `cbrt` and `hypot` within 2 ulp, `sin` and `cos` within 3 (up to 1.6e6 radians),
  `tan`, `atan`, `atan2`, `asin`, `acos`, `expm1`, `log1p` and the other hyperbolics within 6, and `pow` loses up to about 1.5 ulp per unit of
  `|y * ln(x)|` on large results. A script sees the numbers it expects: `Math.pow(2, 10)` is exactly 1024, the integer
  powers and roots that are exact stay exact, and `10 ** n` is the double nearest to 10^n for every `n` from -307 to 308,
  so `Math.floor(Math.log10(1e25))` is 25. Do not compare the result of a transcendental with `===` against a number you
  computed another way: allow a small tolerance. `Math.sqrt`, `floor`, `ceil`, `round`, `trunc`, `abs`, `min`, `max`, `fround`, `imul` and `clz32` are exact
  in IEEE 754 and unchanged. This applies to EVERY script the engine runs, because there is one JavaScript engine: game
  scripts, tests, script tools (`tools/*.js`), `scripts/autoplay.js` hooks and editor scripts all get the same `Math`; no
  script sees the C library's. A script needs nothing to opt in.
- Callbacks using more than 2 s of CPU time are aborted ("script took too long") and the
  behaviour is disabled until its file is reloaded. A timer, tween or `world.on`
  listener stopped this way ends alone; the scripts after it run. Exceptions are recorded once
  per (file, line, message) with a hint; the behaviour keeps running.
  **A cut callback makes the run invalid**, because the rest of the callback was skipped at a point that depends on how fast
  the machine is, so no replay or hash taken from the run can be trusted. It is never silent: the engine logs an error
  naming the script and the callback ("the script watchdog stopped 'onUpdate' of scripts/boss.js (> 2 s of CPU time)"),
  counts it, and then (1) `factoria run --headless` exits with code 1 whatever `--allow-script-errors` says and its report has
  `"replayValid": false`, the cuts in `watchdogCuts` (the latest 100) and a line in `problems` that
  counts them; (2) a test that ran while a callback was cut (even if its own asserts passed) fails with the script and
  callback of the first five cuts named, then "... and N more"; (3) `game.autoplay` / `play.auto` report
  "INVALID RUN" in their notes and the cut in `scriptErrors`; (4) a windowed run with `--frames` exits with code 1. Fix
  the loop that spins (the cause is almost always a `while` that never ends or a pathfinding call per frame), do not raise
  the limit. `script.trace` is the one tool that keeps running after a cut, to show where the time goes.
  Long before the watchdog, `runtime.scriptFrameBudgetMs` (default 8 ms of script time per frame) logs a `script.budget` warning
  naming the slowest callbacks and marks the frame in the profile; `runtime.scriptMemoryMB` (default 768) is the heap cap,
  and both can be set per platform (docs/PERFORMANCE.md, "Script budgets").
- `world.on(name, fn)` listeners get `(data, source)`; `this.on(name, fn)` is the
  same. All listeners/timers are dropped when a scene loads.
- Unknown input actions, keys, components and fields throw errors with
  "did you mean" suggestions. Component views reject unknown field assignment.
- Hot reload (`reload_module`) re-imports the module and every module that
  imports it, recreates affected behaviours (entity state kept, props re-applied,
  `onStart` runs again, `onDestroy` is NOT called) and reloads tools.
- `scene.load`, `scene.reload` and `project.test` re-import every module whose file changed on disk (by mtime; the modules
  importing it too) and `scene.load`/`scene.reload` clear `script.errors`, so an MCP client sees edited scripts without a
  restart. `script.reload` does the same without touching the world (`force` re-imports everything). They also re-read
  `factoria.json` when it changed: input actions, `fixedHz` and the gamepad deadzone (window size, scale mode and the
  renderer need a restart).
- A tool never replaces a built-in command: a tool whose `project.<name>`
  already exists is rejected with a script error.
- `entity.get("Script").props` (a JSON field) returns a copy; assign to write.
