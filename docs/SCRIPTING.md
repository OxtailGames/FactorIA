# Scripting reference (JavaScript)

Gameplay code is JavaScript (ES2023 modules) run by QuickJS. Three kinds of
script live in a project:

| Folder | What | Runs |
|---|---|---|
| `scripts/` | **Behaviours** attached to entities via the `Script` component | every frame while the game runs |
| `tools/` | **Tools**: commands for AIs/editor/CLI (become MCP tools) | when called |
| `tests/` | **Tests** (`*.test.js`) | `factoria test` (headless) |

Type declarations for everything below are generated into
`types/factoria.d.ts`; add `// @ts-check` at the top of a file and run
`npx tsc -p .` to type-check (optional but recommended for AIs).

## Pages

The reference is split by topic (every heading keeps its name, so `docs.read scripting --heading <name>` finds it on its page):

- [World, input and window](scripting/SCRIPTING_WORLD_INPUT.md): `world`, `input`, `window`, device presets and gamepads: the entity API and the first modules.
- [Audio, physics, animation and particles](scripting/SCRIPTING_AUDIO_WORLD.md): `audio`, buses, `physics`, `nav`, behaviour trees, `time`, `camera`, tweens, tilemaps, video, music, particles.
- [UI, scenes, saves and the bot](scripting/SCRIPTING_UI_SCENES.md): UI widgets and HUD, assets, level generation, background loading, `scene` / `game` / `storage`, the bot, quit and clipboard.
- [Render, meshes, random, services and commands](scripting/SCRIPTING_RENDER_SERVICES.md): Render textures, procedural meshes, the date, `rng`, math, plugins, platform, http, i18n and `fa` (commands).
- [Tests, tools and hook modules](scripting/SCRIPTING_TESTS_TOOLS.md): Script tests (`tests/*.test.js`), tools (`tools/*.js`), hook modules and runtime notes.

## Behaviours

```js
// scripts/player.js
import { Behaviour, input, audio, vec2 } from "factoria";

export default class Player extends Behaviour {
  speed = 320;        // fields are defaults; Script.props in the scene override them
  jumpSpeed = 620;

  onStart() {
    this.body = this.entity.get("RigidBody2D");
  }

  onUpdate(dt) {
    const dir = input.axis("move_left", "move_right");
    this.body.velocity.x = dir * this.speed;          // component views write through
    if (input.pressed("jump") && this.entity.isGrounded()) {
      this.body.velocity.y = this.jumpSpeed;
      audio.play("assets/sfx/jump.wav");
    }
  }

  onCollisionEnter(other, info) {
    if (other.hasTag("coin")) {
      other.destroy();
      this.world.emit("coin_collected", { by: this.entity.id });
    }
  }
}
```

Scene usage: `"Script": { "path": "scripts/player.js", "props": { "speed": 400 } }`.

### When behaviours exist
The behaviour instance is constructed (class fields initialised, `Script.props`
applied) **synchronously** when its entity appears: right after `world.spawn`,
`world.spawnPrefab`, `entity.add("Script", ...)`, a scene load and `game.load`
in tests. So `world.spawn(...).behaviour` and `game.find("id").behaviour` are
usable immediately (configure it, call its methods). `onStart()` still runs
later: at the start of the next step, before the entity's first `onUpdate`
(so `game.load(...)` in a test followed by `game.step()` runs `onStart`; reading
`.behaviour` fields set in `onStart` needs one `game.step()` first).

This holds for **inactive** entities too: a panel spawned with `active: false`
already has its `.behaviour` (a never-shown panel can be configured by whoever
spawns it). Only its hooks wait: `onStart` runs the first time the entity is
active in the hierarchy (`active = true` on it or on an ancestor).

### Activation order
For each behaviour, in creation order:
1. First activation: `onStart()`, then `onEnable()`. So `onEnable` can rely on
   what `onStart` set up.
2. Every later `active = true` (or re-enabling the Script): `onEnable()`.
3. Every `active = false` (of the entity or any ancestor) or `Script.enabled =
   false`: `onDisable()`.
4. Destroying an entity that is active: `onDisable()`, then `onDestroy()`.

The hooks run at the start of the next callback phase of the frame and at the
latest at the end of the frame, **before it is drawn**: a panel shown by a script
(`MenuStack.show`, `panel.active = true`) never draws its prefab texts, because
`onEnable` already refreshed them. If `onStart` itself deactivates the entity,
`onEnable` is skipped. Changes made by an `onEnable`/`onDisable` hook are settled
in the same pass (bounded to 8 rounds). The order is deterministic (behaviour
creation order). Hot reload re-creates the behaviour without calling
`onDisable`/`onDestroy`, like `onDestroy`.

A `Script.props` key that is not an own field of the class (declare it as a
class field!) logs ONE warning naming the entity, with a "did you mean"
suggestion; `factoria validate` reports the same through
`ScriptSystem::check_props`.

### Cross-scene state
- `session` (from `"factoria"`) is a plain object that survives scene loads for
  the whole run: `session.score = 0; session.lives = 3`. It is not saved to disk
  (use `storage` for that) and is reset for every test file.
- Module-level variables (`let score = 0` in a module) also persist across
  scene loads, because modules are evaluated once per run. Behaviours,
  timers and `world.on` listeners do not: they are dropped when a scene loads.

### Lifecycle (all optional)

| Method | When |
|---|---|
| `onStart()` | once, the first time the entity is active, before its first update and before the frame is drawn (props already applied) |
| `onEnable()` | every time the entity becomes active in the hierarchy (first time: right after `onStart`), before the frame is drawn |
| `onDisable()` | every time it stops being active, and before `onDestroy` of an active entity |
| `onUpdate(dt)` | every frame, `dt` in seconds (scaled by `time.scale`; not called while it is 0 unless `runWhilePaused`) |
| `onFixedUpdate(dt)` | every fixed step (default 60 Hz), before physics |
| `onLateUpdate(dt)` | after all updates (cameras following targets) |
| `onDestroy()` | before the entity is removed |
| `onCollisionEnter(other, info)` / `onCollisionExit(other)` | physics contacts; `info = { point, normal, impulse }` |
| `onTriggerEnter(other)` / `onTriggerExit(other)` | overlaps with trigger colliders |
| `onEvent(name, data, source)` | any `world.emit` event (also `world.on(name, fn)`) |

The engine calls these by their exact names. A method that looks like a hook but
is not one (`start()`, `update()`, `fixedUpdate()` without the `on`, or a
near-miss such as `onupdate()` or `onStrat()`; a method that takes arguments, like `start(seconds)`, is a normal
method of the class and is not reported) is never called: the first
behaviour of the class created logs ONE warning per such method with a "did you
mean", and `factoria validate` reports the same for every behaviour script (under
`scripts/` or named by a `Script.path`). Helpers with other names (`loadLevel()`)
are not affected.

A class **field** with the name of a `Behaviour` member (`on`, `after`, `every`, `world`) replaces that member for the
instance: `on = false;` makes `this.on("x", fn)` fail. The first behaviour of the class created logs ONE warning naming the
field, and `factoria validate` reports it too; rename the field (`tradeOn`).

### What `factoria validate` checks in a script

Besides the syntax, `factoria validate` (`project.validate`) reads every script under `scripts/` and `tools/` against the
engine's API, by scanning the text (no type inference, comments and strings left out), and loads it the way the game does.
Each issue starts with `file:line:column`:

- **Imported names** (error): `import { Behaviour, wrold } from "factoria"` names a thing the module does not export, with a
  "did you mean". The same for `"factoria:test"`.
- **Members of an imported namespace** (error): `physics.raycats(...)`, `game.setTimeScale`, `ns.member` after
  `import * as ns from "factoria"`: the object is one of the engine's (`world`, `physics`, `game`, `fa`...) and its type has
  no such member. A local variable, parameter or function with the same name anywhere in the file turns the check off for
  that name; only members of the form `name.member` are checked, nothing deeper.
- **Literal component names** (warning): `entity.get("Transfrom")`, `add`, `has` and `remove` with a string that is not a
  component. A name that matches only ignoring case (`get("transform")`) is reported with the exact name. Without type
  inference the check cannot know the receiver is an entity: a PascalCase key of a `Map` or of your own object can be
  reported by mistake (receivers whose name says map, cache, storage, state... or is a plural such as `levels` are skipped, and a
  name that matches only ignoring case is still reported).
- **`fa.call("project.<name>")` in a game script** (warning, `file:line`): `<name>` is a command a module under `tools/`
  defines, and `tools/` is left out of an export, so the call fails in the shipped game. `factoria export` warns the same.
- **`fa.call("<command>")` of a command the exported player lacks** (warning, `file:line:column`; an error for `factoria
  export`): the player has the runtime commands and the ones of the game's native plugins, not the commands that write project
  files or author assets (`scene.format`, `prefab.save`...). A misspelled name gets "did you mean"; `mesh.*`, `anim.*` and
  `scene.import_ascii` name their JS way. Only a string literal is checked, in the scripts that ship (not `tools/`, `tests/` or
  `scripts/autoplay.js`); a name built at run time (`fa.call(name)`) is not (docs/EXPORTING.md, "What is shipped").
- **A module whose top level throws** (error): every script is imported in the validating engine, as the game loads it, so
  an exception at the top of the file (or of a module it imports) is reported with its own file and line. A top level that
  reads the scene (`world.find("player").x` outside a function) throws there because no scene is loaded (`factoria
  validate` and `factoria test` load none; the running game has one): keep that code in `onStart`. When `project.validate`
  runs inside a live engine (over MCP or in the editor) it imports the project's modules, `tools/` included, in that engine, so
  their top-level code runs there too.

A colour written as numbers is read as 0..255 when any of its channels is over 1 (`[255, 128, 0, 255]` is orange). A
mixed colour such as `[255, 255, 255, 1]` is therefore an alpha of 1/255, and validate warns about it (JSON pointer, both
readings) in scenes and prefabs; write every channel as 0..1 or every channel as 0..255. A colour with a channel over 1, no
channel between 0 and 1 and none over 8 (`[3, 2, 2, 3]`, an attempt at "brighter than white") is read as 0..255 too, which is
almost black: validate warns about that as well. For `MeshRenderer.emissive` both warnings point to `emissiveStrength` (the
HDR multiplier) as the way to glow above white.

### Reading a member that does not exist

In every run that is not an exported player (`factoria test`, `run`, `mcp`, the editor's Play) the engine's objects check
reads: an `Entity`, the namespaces of `"factoria"` (`input`, `world`, `audio`, `ui`, `physics`, `scene`, ...) and the
`expect` matchers. Reading a member they do not have throws instead of giving `undefined`:

```
'input' has no 'axs'. Did you mean 'axis'? Its members: pressed, released, down, value, axis, vector, ...
```

so a typo fails where it is written, with the line of your script, and not as `x is not a function` or a `NaN` later.
What passes: symbols, `then` (what `await` probes), `toJSON` (what `JSON.stringify` probes) and the members every object has
(`hasOwnProperty`, `toString`...). Writes are never checked, and an entity can carry a field you gave it (`entity.hp = 3`
and later `entity.hp` works; the members list then names `hp`), but reading a field nobody wrote throws: `entity.hp` before
`entity.hp = 3` is the mistake it finds, so keep game state in the `Behaviour` (`this.hp`) or in a component's fields.
`session` and `plugins` are the namespaces left open: `session` holds the game's own keys, and `plugins` is frozen and read with
`if (plugins.steam)`, so a plugin that is not there is `undefined`, not an error. The check sits behind the object (its
prototype), so reading a member that exists costs nothing; the exported player has no check at all, and there a missing
member is `undefined` again. `plugins` and `game` of `"factoria:test"` check their reads too.

In an exported player only, an error that says the player lacks a member of the engine (an import of `"factoria"` that is
not there, a call of a method the engine object has not) adds that the player may be older than the game's engine; in the
other runs engine and player are one binary and the sentence would be wrong.

A component name that is right except for its case (`entity.get("transform")`) works and logs one warning per name with
the exact spelling; use the exact one, it is what scene files, commands and the typings use. An unknown name
(`entity.get("NoSuch")`) lists the closest names and how many components there are.

### Which callback sees what (input)

A frame runs 0 to 5 fixed steps (a slow frame runs several, a fast one none), so a press must not be tied to the frame
that carries it. The engine keeps two views of the input, and a press, a release, a mouse click, a touch start, a
gamepad button edge, the wheel, the mouse motion, typed text and Back are seen **exactly once by `onFixedUpdate` and
exactly once by `onUpdate`**, whatever the number of steps in the frame:

| Callback | Reads | An edge (`pressed`, `released`, `mouse.wheel`, `mouse.delta`, `text`, `touch.pressed`) is seen |
|---|---|---|
| `onFixedUpdate` | the fixed-step view | by the first fixed step that runs after it happened; not by the later steps of the same frame. A frame with 0 steps keeps it for the next frame's first step. |
| `onUpdate`, `onLateUpdate`, `ui.on(...)` handlers, `after`/`every` timers, `input.onBack` | the frame view | by the frame that carries it, once; not by the next frame. |
| `onCollision*`, `onTrigger*`, `onEvent` | the view of the step (or of the frame, for an event sent after the steps) that delivers them | like `onFixedUpdate` for what physics and animation send in a step, like `onUpdate` for the rest |

Holds are the same in both views: `down`, `value`, `axis`, `vector`, `keyDown`, `mouse.down`, `touches` positions and
stick values are the state at the time of the call. Consequences:

- Put one-shot input (a jump, a shot, a menu choice) in either callback and it fires once. In `onFixedUpdate` it fires
  at 30 FPS and at 144 FPS alike, and never twice in a frame of 5 steps. Movement from held input needs no care.
- A press and its release that both happen between two fixed steps are both seen by the next step, in that order
  (`pressed` and `released` are both true there). A press that ends before any step runs is not lost.
- `input.consume(action)` hides the press from `pressed` for the callbacks that have not seen it yet; a fixed step that
  already took the press is not affected, and a later press is never hidden by it. One limit: the hiding ends when the
  input is let go, and the fixed step keeps one press flag per input, not a count. A press that was consumed and is
  released before the next fixed step ran (a tap shorter than one step, with no step in between) therefore reaches
  `onFixedUpdate` as a normal `pressed`, once.
- A tap that lands and lifts between two fixed steps still shows once in `input.touches[].pressed` (position where it
  lifted) in the next `onFixedUpdate`, and once in the next `onUpdate`; the next call after that no longer lists it.
- Input that arrives while a fixed step runs (a script injecting a key in `onFixedUpdate`, a test) is seen by the NEXT
  step, not lost with the one that is closing; behaviours that run later in the same step may see it too.
- A step run from inside another step (`game.step()` called in `onFixedUpdate`) shares the outer step's view of the
  input: a press reaches both the outer and the nested `onFixedUpdate`, and the step closes when the outer one ends.
- `game.paused = true` (`time.scale` 0): the steps still run, as steps of time 0, but `onFixedUpdate` is not called, and
  each step takes the edges like any other: a press made while the game is paused (a pause menu answered by the UI, a
  `runWhilePaused` behaviour reading it in `onUpdate`) is NOT seen by the first `onFixedUpdate` after the game resumes.
  The engine's own pause (`Engine::set_paused`, what the editor uses outside play, and the `game.pause` command) is
  different: `frame(dt)` only redraws, no step runs and no edge is taken, so a press made meanwhile is kept for the
  first step and the first update after it resumes.
- `game.step(n)` in a test runs one fixed step and one frame `n` times, so each `game.press`/`tap`/`touchStart` is seen by
  one `onFixedUpdate` and one `onUpdate` of the next `game.step`.
- Recorded input (`input.record`) and replays are not affected: the recording keeps each event and the frame timing
  (`dt` and the number of fixed steps), and a replay feeds the same events at the same frames, so it reproduces the same
  fixed steps. The format did not change.

### Behaviour members
- `this.entity` — the owning `Entity`; `this.world` — the world.
- `this.after(seconds, fn)` / `this.every(seconds, fn)` — timers, cancelled
  automatically on destroy; return a handle with `.cancel()`.
- `this.enabled` — `false` skips update callbacks.

## Vectors everywhere
Every API taking a position/vector (`world.spawn`/`spawnPrefab` options and
component fields, `entity.position`/`worldPosition`, `physics.*`, `camera.*`,
`debug.*`, `entity.set/add` fields) accepts a `Vec2`/`Vec3`, a plain `{x, y}` /
`{x, y, z}` object or an `[x, y]` / `[x, y, z]` array. 2D values set `z = 0`
(scale: `z = 1`). `rotation` may be a number (degrees around z) or a vector;
`scale` a number or a vector. Bad input throws an Error that lists the accepted
forms. Rects (`physics.overlapBox`, `debug.rect`) take `{x, y, w, h}` or
`[x, y, w, h]`; `(x, y)` is the minimum (bottom-left) corner. `entity.bounds()` returns a Rect.

## Imports
- `"./util.js"` / `"../lib/x.js"` resolve relative to the importing module;
  `"scripts/x.js"` (no leading dot) is relative to the project root. A path
  that leaves the project root is an error naming the import.
- JSON data: `import levels from "../data/levels.json";` gives the parsed
  file as the default export (hot reload aware). A JSON syntax error is
  reported against the .json file.
- A glob of JSON data: `import tables from "../data/dialogue/*.json";` gives an object of the parsed files directly in that
  folder, keyed by file name (`tables["ch1.json"]`), in sorted order; no match gives `{}`. `*` may stand in the file name only
  (no `**`, no `*` in a folder, only `.json`); an error names the import. It reads the same folder in an exported game
  (`game.pak`) and on the web. Editing a matched file reloads the importers; a file added while the game runs shows on the
  next start.
- Test files get fresh module instances (see Tests), so module state never leaks
  between test files.

## Modules

Everything is imported from `"factoria"`:

```js
import { Behaviour, world, input, window, audio, physics, time, camera, debug, scene, game,
         storage, rng, fa, vec2, vec3, color, Vec2, Vec3, Color, math,
         session, particles, ui, assets, ToolError } from "factoria";
```

## Debugging

F5 in VS Code runs the game (or the tests) with breakpoints, stepping, the Variables view and a debug console; the
command `script.trace` gives an AI the same facts as one JSON answer. Install the VS Code extension with
`factoria setup vscode`. Guide: [DEBUGGING.md](DEBUGGING.md).
