# Creating tools and extending the engine

This guide has two readers. Game-making AIs read sections A and E to add a repeatable tool to a game project. Engine developers read sections B to F to add commands, components, systems and feedback processing to FactorIA itself.

The examples use the APIs of this build and were checked against it. The reference for the JavaScript side is `docs/SCRIPTING.md`. The reference for the frame and the built-in commands is `engine/runtime/include/fa/runtime/engine.h`.

## Where things go

| You want to add | Put it in | It becomes |
|---|---|---|
| A tool for one game | `tools/<name>.js` in the game project | command `project.<name>`, MCP tool `project_<name>` |
| A command for the running game | C++ `CommandRegistry::add`, in `engine/runtime/src/` | MCP tool, `factoria call`, editor command, `fa.call` |
| A command for project tooling | C++ `CommandRegistry::add`, in `tools/common/src/` | the same surfaces |
| A new component | a struct in `engine/scene/include/fa/scene/components.h`, registered in `components.cpp` | scene JSON, script views, typings, docs, MCP |
| A per-frame behaviour of the engine | a system called from the frame loop in `engine/runtime/src/` | runs in every game |
| Documentation for AIs | `docs/*.md` | embedded in the binary; MCP resources `factoria://docs/...` |

Every capability is registered once as a command. The same registry feeds MCP, the built-in agent, the CLI, the editor console and scripts. Do not add a one-off CLI flag for a capability that tools or AIs should use.

## A. Project tools (`tools/*.js`)

A project tool is a JavaScript module in the game's `tools/` folder. The file name is the tool name, so `tools/spawn_wave.js` becomes `project.spawn_wave` (CLI and `fa.call`) and MCP tool `project_spawn_wave`. This is the contract in `docs/SCRIPTING.md`.

```js
// tools/<name>.js
import { world, fa } from "factoria";

export default {
  name: "<name>",                 // keep it equal to the file name
  summary: "One line, imperative.",
  description: "What it does, its caveats, and one example call as JSON.",
  input: {                        // JSON Schema for the arguments
    type: "object",
    required: [],
    properties: {},
  },
  readOnly: false,                // true when the tool only reads
  run(args) {                     // args are validated; defaults from `input` are filled in
    return { /* any JSON-serializable value */ };
  },
};
```

- **Schema keywords** the validator checks: `type`, `properties`, `required`, `additionalProperties`, `default`, `enum`, `const`, `minimum`, `maximum`, `minLength`, `pattern`, `items`, `anyOf`, `oneOf`. Invalid arguments are refused before `run` is called. The error names the field and gives a hint, such as the allowed values.
- **Hot reload.** Saving the file reloads the tool. MCP clients receive `notifications/tools/list_changed`.
- **Errors.** Two kinds, and the caller sees them differently.
  - An *expected* failure, such as a check that found bad level data, is `throw new ToolError(message, hint, data?)` (import it from `"factoria"`). The caller gets code `tool_error`, the message, and your `hint`, which says how to fix the data or the call. `data` is an optional object with details. It appears in the JSON error of `factoria session` and `factoria call --batch`; MCP shows only the code, message and hint, so put what a fixer needs into the hint.
  - Any other exception is a script bug. The caller gets code `failed`, the message with `file:line`, and the error is also recorded as a script error.
  - Arguments that break the `input` schema are refused before `run` is called, with a message that names the field.
- **Calling.** MCP: `project_<name>`. CLI: `factoria call project.<name> '<json>'`. Scripts: `fa.call("project.<name>", {...})`.

### A.1 Level generator: writes a scene file

It builds a scene from parameters and writes it with the `fs.write` command. It is read-write, so the description says that it overwrites the file.

```js
// tools/gen_arena.js
import { fa, rng } from "factoria";

export default {
  name: "gen_arena",
  summary: "Generate a scene with random crates and write it to a .scene.json file.",
  description: 'Example: {"path":"scenes/arena.scene.json","crates":12,"width":800,"height":480,"seed":7}. Overwrites the file; the same seed gives the same arena. Run project_validate afterwards.',
  input: {
    type: "object",
    required: ["path"],
    properties: {
      path: { type: "string", pattern: "\\.scene\\.json$", description: "Project-relative path ending in .scene.json." },
      crates: { type: "integer", minimum: 0, maximum: 200, default: 12, description: "How many crates to place." },
      width: { type: "number", minimum: 100, default: 800, description: "Width of the area, in pixels." },
      height: { type: "number", minimum: 100, default: 480, description: "Height of the area, in pixels." },
      seed: { type: "integer", default: 1, description: "Seed; the same seed gives the same arena." },
    },
  },
  readOnly: false,
  run({ path, crates, width, height, seed }) {
    const r = rng.create(seed); // own generator: rng.seed() would reseed the one RNG the running game draws from
    const entities = [
      { id: "camera", components: { Camera: { projection: "orthographic", clearColor: [0.1, 0.1, 0.15, 1], primary: true } } },
    ];
    for (let i = 0; i < crates; i++) {
      entities.push({
        id: `crate_${i}`,
        tags: ["crate"],
        components: {
          Transform: { position: [r.range(-width / 2, width / 2), r.range(-height / 2, height / 2), 0] },
          Shape2D: { shape: "rectangle", size: [40, 40], color: [0.6, 0.4, 0.2, 1] },
        },
      });
    }
    const scene = { format: "factoria.scene/1", settings: { gravity2D: [0, 0] }, entities };
    const written = fa.call("fs.write", { path, content: JSON.stringify(scene, null, 2) + "\n" });
    return { path: written.path, entities: entities.length };
  },
};
```

`rng.create(seed)` returns an independent generator (`float`, `range`, `int`, `chance`, `pick`, `shuffle`, `seed`) that never touches the world RNG, so the tool does not change the random sequence of the game that is running. Its algorithm (mulberry32) is stable across engine versions, so a seed you store keeps giving the same arena. `rng.seed(n)` would reseed the game's own RNG instead.

To write the state of the live world instead, call `scene.save` with `fa.call` (its arguments are in `docs_commands`).

### A.2 Balancing tool: reads `game.state`

It is read-only. It reads the running game through `game.state` and reports the enemies that are too fast.

```js
// tools/balance_report.js
import { fa } from "factoria";

export default {
  name: "balance_report",
  summary: "Report the speed of every enemy in the running game and flag the fast ones.",
  description: 'Example: {"maxSpeed": 400}. Read-only. Reads game.state, so load the level first (scene_load or game_step).',
  input: {
    type: "object",
    properties: {
      maxSpeed: { type: "number", minimum: 0, default: 400, description: "Enemies faster than this are flagged." },
    },
  },
  readOnly: true,
  run({ maxSpeed }) {
    // Ask only for the Script component, and raise the default cap of 200 entities.
    const state = fa.call("game.state", { components: ["Script"], maxEntities: 1000 });
    // Entities have the scene-file shape (id, name, tags, components).
    const enemies = state.entities.filter((e) => (e.tags ?? []).includes("enemy"));
    if (enemies.length === 0) {
      throw new Error("No entity tagged 'enemy' in the running game. Load the level, or check the tags in its scene file.");
    }
    const flagged = [];
    for (const e of enemies) {
      const speed = e.components?.Script?.props?.speed;
      if (typeof speed === "number" && speed > maxSpeed) flagged.push({ id: e.id, speed });
    }
    // game.state sets "truncated" when some entities were left out.
    return { enemies: enemies.length, truncated: state.truncated === true, flagged };
  },
};
```

### A.3 Asset checker: finds unused and oversized files

It uses `fs.list` and `fs.read`. A file counts as used when its project-relative path appears in a scene, a prefab or a script. This is a heuristic, so check the list before you delete anything.

```js
// tools/check_assets.js
import { fa } from "factoria";

// Files under a project folder. A missing folder is treated as empty.
// fs.list returns at most 500 entries unless a limit is given, so ask for more.
function filesUnder(dir) {
  try {
    return fa.call("fs.list", { path: dir, recursive: true, limit: 10000 }).entries.filter((e) => e.type === "file");
  } catch (_) {
    return [];
  }
}

export default {
  name: "check_assets",
  summary: "List assets that no scene, prefab or script mentions, and assets over a size limit.",
  description: 'Example: {"maxKb": 512}. Read-only. Paths are project-relative, for example "assets/sfx/jump.wav".',
  input: {
    type: "object",
    properties: {
      maxKb: { type: "number", minimum: 1, default: 512, description: "Files larger than this are reported." },
    },
  },
  readOnly: true,
  run({ maxKb }) {
    const assets = filesUnder("assets");
    const sources = [];
    for (const dir of ["scenes", "prefabs", "scripts"]) {
      for (const f of filesUnder(dir)) sources.push(fa.call("fs.read", { path: f.path }).content);
    }
    const text = sources.join("\n");
    return {
      assets: assets.length,
      unused: assets.filter((a) => !text.includes(a.path)).map((a) => a.path),
      tooBig: assets
        .filter((a) => a.size > maxKb * 1024)
        .map((a) => ({ path: a.path, kb: Math.round(a.size / 1024) })),
    };
  },
};
```

### A.4 Rules for good project tools

- Keep one job per tool. Return ids and counts rather than large dumps.
- Set `readOnly: true` for queries. Agents use the flag to decide what is safe to call.
- Say in `description` whether the tool overwrites files or changes the running game.
- A tool does not step the simulation unless its description says so.
- Tools can use everything in `"factoria"` and every command through `fa.call`.
- A check that can find several problems reports all of them in one result (section A.5), not one error per run.

### A.5 A check that reports every problem

A `ToolError` names one failure. When the caller needs the whole list (every coin out of bounds, every broken reference), return the list as a normal result instead. Every surface shows a normal result in full, while MCP shows a thrown error only as its message and hint. Let the caller read `ok`:

```js
// tools/check_coins.js
import { world } from "factoria";

export default {
  name: "check_coins",
  summary: "List every coin below a height, so one run shows all of them.",
  description: 'Example: {"minY": -300}. Read-only. Returns every coin below minY, not just the first one.',
  input: {
    type: "object",
    properties: { minY: { type: "number", default: -300, description: "Coins below this height are reported." } },
  },
  readOnly: true,
  run({ minY }) {
    const coins = world.findByTag("coin");
    const low = coins.filter((c) => c.position.y < minY).map((c) => ({ id: c.id, y: c.position.y }));
    return { ok: low.length === 0, coins: coins.length, low };
  },
};
```

Use `throw new ToolError(...)` when the failure is a single fact and the hint can carry the whole fix, for example a missing scene file.

## B. C++ commands in the engine

A command is a named function from JSON to JSON, registered in `CommandRegistry` (`engine/core/include/fa/core/command.h`).

```cpp
CommandInfo info;
info.name = "area.verb_object";   // snake_case, "<area>.<verb_object>"
info.category = "area";           // grouping in docs and listings
info.readOnly = true;             // false when the command changes game or project state
info.summary = "One line, imperative.";
info.description = "What it does, caveats, and one example call.";
info.inputSchema = Json::parse(R"({ "type": "object", "properties": {}, "required": [] })");
registry.add(std::move(info), [](const Json& args) -> Json {
    // args are already validated and defaults are filled in.
    return Json::object({{"ok", true}});
});
```

- **Errors.** Throw `CommandError(code, message, hint, data)` (defined in `command.h`; `hint` and `data` are optional). `command.h` names the codes `not_found`, `invalid_argument`, `failed` and `unavailable`; use the one that fits. Any other exception becomes `failed`. The registry itself reports `unknown_command` (with a did-you-mean hint) and `invalid_arguments`.
- **Results.** `CommandRegistry::call` returns `CommandResult{ok, result, error}`. `error` is `{code, message, hint}`.
- **Replacement.** `add` replaces a command with the same name.
- **Schema keywords** are the same as in section A.

### Where to register

| The command needs | Write it in | Register it from |
|---|---|---|
| The running game (scene, input, screenshots) or only the `World` | `engine/runtime/src/` (with a public header in `engine/runtime/include/fa/runtime/` if tests need it) | `register_builtin_commands` in `engine/runtime/src/commands.cpp` (declared in `engine_impl.h`) |
| Project tooling: validation, docs, files, feedback | `tools/common/src/` | `register_tooling_commands(registry, projectDir)` (`tooling.h`) |
| The built-in AI agent | `tools/ai/src/` | `register_ai_commands` (`commands.h`) |

### B.1 Full example: `scene.find_by_tag`

The command returns the ids of the entities that carry a tag. It needs the `World`, so it lives in the runtime, which owns the world. Three new files and one call.

Header, `engine/runtime/include/fa/runtime/scene_commands.h` (new file):

```cpp
#pragma once

#include "fa/core/command.h"
#include "fa/scene/world.h"

namespace fa {

// Registers scene.find_by_tag. Called from register_builtin_commands().
void register_scene_commands(CommandRegistry& registry, World& world);

}  // namespace fa
```

Source, `engine/runtime/src/scene_commands.cpp` (new file):

```cpp
#include "fa/runtime/scene_commands.h"

namespace fa {

void register_scene_commands(CommandRegistry& registry, World& world) {
    CommandInfo info;
    info.name = "scene.find_by_tag";
    info.category = "scene";
    info.readOnly = true;
    info.summary = "List the ids of the entities that have a tag.";
    info.description =
        "Returns an empty array when no entity has the tag. Example: {\"tag\":\"enemy\"} returns "
        "{\"ids\":[\"enemy_1\",\"enemy_2\"]}. Pass an id to scene.get_entity to inspect one.";
    info.inputSchema = Json::parse(R"({
        "type": "object",
        "properties": {
            "tag": {"type": "string", "description": "Tag to search for, for example \"enemy\"."}
        },
        "required": ["tag"],
        "additionalProperties": false
    })");

    registry.add(std::move(info), [&world](const Json& args) -> Json {
        const std::string tag = args.at("tag").get<std::string>();
        if (tag.empty())
            throw CommandError("invalid_argument", "The tag is empty.", "Pass a tag such as {\"tag\":\"enemy\"}.");
        Json ids = Json::array();
        for (Entity e : world.find_by_tag(tag)) ids.push_back(world.info(e).id);
        return Json::object({{"ids", ids}});
    });
}

}  // namespace fa
```

Call it from `register_builtin_commands` in `engine/runtime/src/commands.cpp`, where the registry is `I.commands` and the world is `I.world`. Add this line next to the other registrations:

```cpp
register_scene_commands(I.commands, I.world);
```

Test, `engine/runtime/tests/test_scene_commands.cpp` (new file). `fa_add_tests(runtime)` in `engine/runtime/CMakeLists.txt` builds every `tests/*.cpp` into `fa_test_runtime`:

```cpp
#include <doctest.h>

#include "fa/core/command.h"
#include "fa/runtime/scene_commands.h"
#include "fa/scene/world.h"

using namespace fa;

TEST_CASE("scene.find_by_tag returns the ids of tagged entities") {
    World world;
    world.info(world.create("Grunt", "enemy_1")).tags = {"enemy"};
    world.info(world.create("Coin", "coin_1")).tags = {"pickup"};

    CommandRegistry registry;
    register_scene_commands(registry, world);

    CommandResult found = registry.call("scene.find_by_tag", Json::object({{"tag", "enemy"}}));
    REQUIRE(found.ok);
    CHECK(found.result["ids"] == Json::array({"enemy_1"}));

    CommandResult none = registry.call("scene.find_by_tag", Json::object({{"tag", "boss"}}));
    REQUIRE(none.ok);
    CHECK(none.result["ids"].empty());

    CommandResult empty = registry.call("scene.find_by_tag", Json::object({{"tag", ""}}));
    CHECK_FALSE(empty.ok);
    CHECK(empty.error["code"] == "invalid_argument");
}
```

Build and run it:

```bash
cmake --build --preset linux-debug --target fa_test_runtime
ctest --preset linux-debug -R runtime --output-on-failure
```

After this change the command is available as MCP tool `scene_find_by_tag`, as `factoria call scene.find_by_tag '{"tag":"enemy"}'`, in scripts as `fa.call("scene.find_by_tag", {tag: "enemy"})`, and to the built-in agent. Nothing else needs to change.

## C. Adding a component

**Components are data.** A component is a reflected struct with no behaviour. Logic belongs in a system (section D) or in a JavaScript behaviour that reads the component.

Steps:

1. **Write the struct** in `engine/scene/include/fa/scene/components.h`. Comment every field with its units, default and meaning.
2. **Register it** in `register_builtin_components` (`engine/scene/src/components.cpp`). Give it a PascalCase name, a doc string and a category (`Core`, `Camera`, `2D`, `3D`, `Physics`, `Audio`, `Scripting`, `Scene`, or a new one such as `Gameplay`). Add a doc string to every field.
3. **Write the system** that reads it (section D). Put it in the module that owns the behaviour.
4. **Test it.** Load a scene that uses the component and check the defaults. Add a system test (section D).
5. **Document it.** The field docs are the reference, because `docs_components` is generated from them. Add a line to the cheat-sheet in `docs/AI_GUIDE.md` if the component is a common building block.

Do not add a component for something a script can already do with `props`. Add one when several systems or many games need the data.

### C.1 Reflection cheat-sheet

| C++ field type | Field kind | Notes |
|---|---|---|
| `bool` | Bool | |
| `int`, `std::int32_t` | Int | |
| `float` | Float | Add `.range(lo, hi)` as a hint for editors and validation. |
| `std::string` | String | |
| `Vec2`, `Vec3`, `Vec4`, `Color`, `Rect` | Vec2, Vec3, Vec4, Color, Rect | JSON arrays. See `json.h` for the accepted forms. |
| `fa::Entity` | Entity | Scene files reference entities by string id. |
| `fa::Json` | Json | Plain JSON value, for example `Script.props`. |
| `enum class E : std::int32_t` | Enum | `enum_field(name, &T::m, {"a", "b"}, doc)`. Names are lowercase and their index is the value. |
| `std::string` path | Asset | `asset_field(name, &T::m, "texture", doc)`. Types: `texture`, `mesh`, `audio`, `font`, `script`, `scene`, `prefab`, `any`. Validation checks that the file exists. |

Modifiers apply to the last field: `.range(lo, hi)`, `.runtime_only()` (not saved to scene files) and `.read_only()` (scripts may read but not write).

### C.2 Full example: `Wobble`

`Wobble` moves an entity up and down around its starting height. It is an example. Do not add it to the engine unless it is a general need.

Struct, in `engine/scene/include/fa/scene/components.h`:

```cpp
// Bobs the entity up and down around its starting height. Systems: update_wobble() in wobble_system.h.
struct Wobble {
    float amplitude = 8.0f;   // distance above and below the base height, in world units
    float frequency = 1.0f;   // full up-and-down cycles per second
    float phase = 0.0f;       // starting offset of the cycle, in degrees (90 starts at the top)
    float baseY = 0.0f;       // runtime: height the entity oscillates around
    float elapsed = 0.0f;     // runtime: seconds since the first update
    bool started = false;     // runtime: true once baseY has been captured
};
```

Registration, in `register_builtin_components` in `engine/scene/src/components.cpp`:

```cpp
    // ---------------------------------------------------------- Gameplay ---
    r.add<Wobble>("Wobble",
                  "Bobs the entity up and down around its starting height. Updated every fixed step by update_wobble().",
                  "Gameplay")
        .field("amplitude", &Wobble::amplitude, "Distance above and below the base height, in world units.").range(0, 100000)
        .field("frequency", &Wobble::frequency, "Full up-and-down cycles per second.").range(0, 100)
        .field("phase", &Wobble::phase, "Starting offset of the cycle in degrees. 90 starts at the top.").range(-360, 360)
        .field("baseY", &Wobble::baseY, "Runtime state: the height the entity oscillates around.").runtime_only()
        .field("elapsed", &Wobble::elapsed, "Runtime state: seconds since the first update.").runtime_only()
        .field("started", &Wobble::started, "Runtime state: true once baseY has been captured.").runtime_only();
```

Test, `engine/scene/tests/test_wobble.cpp` (new file). The second case calls the system from section D:

```cpp
#include <doctest.h>

#include "fa/scene/components.h"
#include "fa/scene/serialize.h"
#include "fa/scene/wobble_system.h"
#include "fa/scene/world.h"

using namespace fa;

TEST_CASE("Wobble loads from scene JSON and fills in its defaults") {
    World world;
    Json scene = Json::parse(R"({
        "format": "factoria.scene/1",
        "entities": [{"id": "bob", "components": {"Wobble": {"amplitude": 4}}}]
    })");
    LoadReport report = load_scene(world, scene, "<test>");
    REQUIRE(report.ok());
    Entity bob = world.find_by_id("bob");
    REQUIRE(static_cast<bool>(bob));
    const Wobble* w = world.get<Wobble>(bob);
    REQUIRE(w != nullptr);
    CHECK(w->amplitude == doctest::Approx(4.0f));
    CHECK(w->frequency == doctest::Approx(1.0f));
}

TEST_CASE("Wobble oscillates around its starting height") {
    World world;
    Entity e = world.create("Bob", "bob");
    world.get<Transform>(e)->position.y = 100.0f;
    Wobble& w = world.add<Wobble>(e);
    w.amplitude = 10.0f;
    w.frequency = 1.0f;

    const float dt = 1.0f / 60.0f;
    for (int i = 0; i < 15; ++i) update_wobble(world, dt);  // a quarter cycle: the top
    CHECK(world.get<Transform>(e)->position.y == doctest::Approx(110.0f).epsilon(1e-3));
    for (int i = 0; i < 30; ++i) update_wobble(world, dt);  // three quarters: the bottom
    CHECK(world.get<Transform>(e)->position.y == doctest::Approx(90.0f).epsilon(1e-3));
}
```

### C.3 What you get without extra code

Once a component is registered, the engine derives these from the reflection data:

- **Scene and prefab JSON.** Loading, saving and error messages. An unknown field name produces a message with the JSON pointer and a did-you-mean hint (`engine/scene/include/fa/scene/serialize.h`).
- **JSON Schema.** `scene_json_schema()` and `prefab_json_schema()`, plus `type_json_schema()` for a single type.
- **Scripts.** `entity.get("Wobble")` returns a live view of exactly the reflected fields (`docs/SCRIPTING.md`). Writing `entity.get("Wobble").amplitude = 2` writes into the engine.
- **TypeScript typings.** `types/factoria.d.ts`, written by `factoria api --dts` (a project gets its own copy from `factoria validate --fix-types`).
- **Docs.** `docs_components`, `docs.components` and `factoria://docs/components`.
- **MCP and CLI.** `scene_set_component` and `scene.set_component` can patch the field.
- **Editor.** Desktop builds include the visual editor (`FA_BUILD_EDITOR`, on by default there). Start it with `factoria editor`.

## D. Adding a system to the frame loop

A system is a function that reads and writes components. The frame runs in a fixed order, documented at the top of `engine/runtime/include/fa/runtime/engine.h`:

```
input.begin_frame
N x fixed step @ fixedHz:  scripts.fixed_update -> physics.step -> scripts.dispatch_events
scripts.update(dt) -> animators/particles -> audio.update -> scripts.late_update
renderer: begin_frame -> render_world -> end_frame
world.flush() (deferred destroys), pending scene change, hot-reload poll
```

### Choose the phase

| Phase | Use it for | Rules |
|---|---|---|
| Fixed step, before `physics.step` | Anything that moves bodies or decides gameplay state | Use the fixed dt. Physics must see the result. |
| Variable update, after `scripts.update` | Animation, particles, audio effects | Use the frame dt. Do not change state that physics or gameplay read. |
| Late update (`scripts.late_update`) | Things that follow other things, such as cameras | Runs after all updates. |
| Rendering | Drawing only | `renderer()` is null when the game runs without graphics (`EngineConfig::graphics = false`). Check it. |

### D.1 Full example: `update_wobble`

The Wobble system from section C belongs to the scene module, because it only touches `World` data. It is a fixed-step system, so physics sees the moved transform.

Header, `engine/scene/include/fa/scene/wobble_system.h` (new file):

```cpp
#pragma once

#include "fa/scene/world.h"

namespace fa {

// Moves every active Wobble entity around its base height. Call it once per FIXED step, before physics.
void update_wobble(World& world, float fixedDt);

}  // namespace fa
```

Source, `engine/scene/src/wobble_system.cpp` (new file):

```cpp
#include "fa/scene/wobble_system.h"

#include <cmath>

#include "fa/scene/components.h"

namespace fa {

void update_wobble(World& world, float fixedDt) {
    constexpr float kTwoPi = 6.2831853f;
    world.each<Wobble, Transform>([&](Entity e, Wobble& w, Transform& t) {
        if (!world.active_in_hierarchy(e)) return;
        if (!w.started) {
            w.baseY = t.position.y;
            w.started = true;
        }
        w.elapsed += fixedDt;  // simulated time, so runs are reproducible
        const float angle = kTwoPi * w.frequency * w.elapsed + w.phase * kTwoPi / 360.0f;
        t.position.y = w.baseY + w.amplitude * std::sin(angle);
    });
}

}  // namespace fa
```

Call site: the fixed-step loop of `Engine::Impl::run_frame` in `engine/runtime/src/engine.cpp`. The new line goes after `scripts.fixed_update` and before `physics.step`, so physics reads the moved transform:

```cpp
const float fdt = float(fixedDt);
for (int i = 0; i < fixedSteps; ++i) {
    scripts.fixed_update(fdt);
    update_wobble(world, fdt);  // new: moves Wobble entities before physics reads them
    physics.step(world, fdt);
    scripts.dispatch_events();
    world.advance_clock(fixedDt);
}
```

Add `#include "fa/scene/wobble_system.h"` to that file. The system test in section C runs without the frame loop, so it stays fast.

### D.2 Rules for systems

- **Determinism.** Use the fixed dt, `world.rng()` for random numbers, and no wall clock. The same seed and the same input must give the same frames.
- **Skip inactive entities.** Check `world.active_in_hierarchy(e)`.
- **Be safe with deferred work.** `world.destroy(e)` is deferred to the end of the frame, so it is safe inside `world.each`. Do not call `load_scene` in the middle of a frame. Use `ScriptHost::request_scene_change`, which defers the change.
- **Do not depend on graphics.** Headless runs without graphics have no renderer.
- **Keep the order documented.** Update the frame comment in `engine.h` and the module table in `docs/ARCHITECTURE.md` when you add a system.
- **Test it twice.** A C++ test calls the system directly (as in section C). A headless test checks the system inside a real frame when it changes the outcome of a game.

## E. Checklists

### Naming

- Commands are `area.verb_object` in snake_case: `scene.find_by_tag`, `feedback.report`. Existing areas: `ai`, `api`, `assets`, `docs`, `engine`, `feedback`, `fs`, `game`, `physics`, `project`, `scene`, `script`.
- Tool files are snake_case. `tools/spawn_wave.js` becomes `project.spawn_wave`.
- Components are PascalCase. Fields are camelCase. Enum values are lowercase (`"orthographic"`).
- C++ functions and variables are snake_case, types are PascalCase, and source files are snake_case (`scene_commands.cpp`).
- Entity ids are stable and snake_case (`coin_3`).

### Doc strings

- Every reflected field and every command has a doc string. These strings are the documentation that AIs read.
- A command has a one-line imperative `summary` and a `description` with caveats and one example call.
- A field has one or two sentences with its units, its default and the meaning of each enum value.
- Write them for a reader who has never seen the code.

### Errors that teach

- Say where (file, JSON pointer or line), what went wrong, and how to fix it (the hint).
- Name the alternatives. Use `fa::did_you_mean(input, candidates)` or `fa::closest_match` from `engine/core/include/fa/core/strings.h`.
- Return a normal empty result for "nothing found" rather than an error.

```cpp
throw CommandError("not_found", "Entity 'enemy_9' not found.", "Use scene.list_entities to see valid ids.");
```

### Tests

- C++ tests are doctest cases in `engine/<module>/tests/test_*.cpp`. `fa_add_tests(<module>)` builds them into `fa_test_<module>`. Run one module with `cmake --build --preset linux-debug --target fa_test_<module>` and `ctest --preset linux-debug -R <module> --output-on-failure`.
- Tests that need a GPU carry the `gpu` label (`fa_add_tests(... LABELS gpu)`). Hosts without a GPU skip them with `ctest --preset linux-debug -LE gpu`.
- Game-level behaviour goes in `tests/*.test.js` and runs with `factoria test`.
- Rendering tests compare headless golden images in `engine/render/tests/golden/*.png` with a tolerance.
- Determinism: fixed seed, fixed steps, no timing assertions.
- A bug fix starts with a failing test.

### Documentation

- `docs/*.md` is embedded in the binary. Update it in the same change as any user-facing behaviour.
- Generated references (components, commands) need no edit.
- `docs/AI_GUIDE.md` is the workflow for game-making AIs. `templates/common/AGENTS.md` is the short guide that `factoria new` writes into each project, so keep the two consistent.

### Rules from `CLAUDE.md`

- Module order is in `docs/ARCHITECTURE.md`: core, scene, platform, then render, physics and audio, then script, runtime, tooling, mcp and ai, then editor and cli. A module includes only modules before it.
- No exceptions cross module boundaries, except `CommandError` inside command handlers. Return `fa::Result<T>` with a message and a hint.
- No `rand()`. No wall clock in simulation.
- Do not edit `external/`. Wrap third-party code from engine code.
- Sources are globbed: a new `.cpp` in a module's `src/` needs no CMake edit. Platform files use suffixes `_linux`, `_win32`, `_apple` (`.m`, `.mm`), `_android`, `_posix`, `_egl` and `_web`.
- Record every engine gap you notice in the example's `ENGINE_FEEDBACK.json`.

## F. Processing `ENGINE_FEEDBACK.json` (engine developers)

Each game records what the engine lacked in its `ENGINE_FEEDBACK.json` (`docs/ENGINE_FEEDBACK.md`). Engine developers merge those files to decide what to build next.

```bash
factoria feedback collect games/ examples/ --out roadmap.md
factoria feedback collect games/ --out roadmap.json --include-closed
```

- **Inputs.** Files, or directories. A directory contributes its `ENGINE_FEEDBACK.json` and any below it.
- **Output file.** `--out` writes the Markdown report, or the JSON report when the name ends in `.json`.
- **Scoring.** `score = sum(occurrences) x severity weight`, with weights blocker 8, major 4, minor 2 and nice-to-have 1. Only `open` entries count unless `--include-closed` is given.
- **Grouping.** Entries in the same category with similar titles form one cluster. Titles are compared by token overlap and edit distance, with a default threshold of 0.7.
- **Output (JSON).** `sources`, `projects`, `totalEntries`, `errors` and `clusters`. Each cluster has `rank`, `title`, `category`, `severity`, `score`, `totalOccurrences`, `projects`, `entries` (with `project`, `id`, `severity` and `status`), `bestSuggestion` and `sampleWorkarounds`.

A triage routine:

1. Collect, then read the top clusters.
2. For each cluster, decide: build it (a command, component or system, sections B to D), accept the workaround and document it, or mark it `wont-fix`.
3. When it is fixed, set `status` to `fixed-in-engine` and `engineIssue` to the issue or pull request. Use `feedback.update` from the project that holds the entry, or edit that file:

   ```json
   { "id": "FB-0001", "status": "fixed-in-engine", "engineIssue": "#42" }
   ```

4. Collect again. The cluster should disappear or shrink.

Notes:

- `feedback.update` changes only the `ENGINE_FEEDBACK.json` of the project it runs in. Entries in other projects are changed by editing their files.
- Wording matters for grouping. Reuse the same title for the same gap, and write titles as noun phrases ("No one-way platforms").
- A duplicate report is merged automatically into an open entry in the same category, so repeated reports raise `occurrences` and the score.
