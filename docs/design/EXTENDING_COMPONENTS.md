# Extending the engine: components and systems (sections C and D)

Part of [Creating tools and extending the engine](../EXTENDING.md), for engine developers (these pages are the engine's source docs: they are not embedded in the binary and `docs.read` does not serve them; read them in a checkout).

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
| `int`, `std::int32_t` | Int | `.range(lo, hi)` works as for `float`. |
| `float` | Float | Add `.range(lo, hi)`: scene loading, `scene.set_component` and `project.validate` refuse a number outside it (an error with the JSON pointer, the range and the nearest allowed value; nothing is clamped silently). A script that writes a number outside it gets the same error, thrown. |
| `std::string` | String | |
| `Vec2`, `Vec3`, `Vec4`, `Color`, `Rect` | Vec2, Vec3, Vec4, Color, Rect | JSON arrays. See `json.h` for the accepted forms. |
| `fa::Entity` | Entity | Scene files reference entities by string id. |
| `fa::Json` | Json | Plain JSON value, for example `Script.props`. |
| `fa::ArrayI32`, `fa::ArrayF32`, `fa::ArrayU8` (`core/typed_array.h`) | ArrayI32, ArrayF32, ArrayU8 | A flat JSON array of integers, numbers or bytes 0..255, typed in memory and in scripts (below the table). `.range(lo, hi)` bounds every element. |
| `enum class E : std::int32_t` | Enum | `enum_field(name, &T::m, {"a", "b"}, doc)`. Names are lowercase and their index is the value. |
| `std::string` path | Asset | `asset_field(name, &T::m, "texture", doc)`. Types: `texture`, `mesh`, `audio`, `font`, `script`, `scene`, `prefab`, `any`. Validation checks that the file exists. |

Modifiers apply to the last field: `.range(lo, hi)`, `.runtime_only()` (not saved to scene files) and `.read_only()` (scripts may read but not write).

**Array fields.** `ArrayI32`, `ArrayF32` and `ArrayU8` are thin wrappers of a contiguous `std::vector` that count their
writes, so a system that derives data from one (a physics body, a render chunk) rebuilds only what changed:

- `version()` grows on every write through a mutable accessor (`a[i] = x`, a mutable `data()`, `set`, `fill`, `assign`,
  `resize`...). Read through a `const` reference (`std::as_const(a)[i]`, `cdata()`, `span()`) and nothing is counted. A
  consumer keeps the version it built from and rebuilds when it differs.
- `dirty_since(seen, begin, end)` gives the smallest half-open index range written after the array had version `seen`
  (a chunk size C means chunks `begin / C` to `(end - 1) / C`). Each consumer keeps its own `seen` (the `version()` it last
  read), so any number of consumers ask independently and nothing is "acknowledged": one consumer can never hide an
  edit from another. The array remembers its last `kHistory` (8) writes; when more than that happened since `seen`, or
  `seen` is newer than the array, `dirty_since` returns false and the consumer compares or rebuilds everything. A write
  that changes the size covers the whole array, and `end` may exceed `size()` after a shrink.
- `set(i, x)`, `fill`, `assign` and copy assignment write only what differs: the same contents change nothing, so a
  `scene.set_component` that repeats the array, or a patch of another field of the component, does not trigger a rebuild.
  `a[i] = x` cannot see whether `x` differs and always counts.
- The version and the range only mean something on one array object (a copy starts at version 0 again). A cache per
  component keeps `id()` next to the version: `id()` is unique in the process for every constructed or copy-constructed
  array (a component removed and added again, a world restored from a copy), kept by a move construction (a pool
  relocating the component) and by assignment (the destination's). The cache is valid while both `id()` and `version()`
  equal what it was built from. After a copy or move ASSIGNMENT the id is the destination's but the contents (and the
  version steps) come from another array: a side log of edits kept next to the array (the Tilemap's `edits`) must prove it
  covers every version step since the cache's version (as `tilemap_edits_since` does) and never be trusted by `(id, version)`
  alone. Not thread safe.
- JSON: an array of numbers, validated whole before anything is written (errors name the field and the element index;
  an integer kind refuses `2.5`, `ArrayU8` refuses 256, `ArrayF32` refuses what a 32-bit float cannot hold; at most
  16 Mi elements). `type_json_schema` gives `{"type": "array", "items": {"type": "integer"|"number", "minimum", "maximum"}}`.
- Scripts: reading the field gives an `Int32Array`, `Float32Array` or `Uint8Array` that is a COPY (writing into it changes
  nothing); assigning a typed array or a plain array of numbers replaces the whole field after every element is checked
  (`TestComponent.tiles[17] must be an integer from 0 to 255, got 300`). A typed array of the field's own type is copied
  as bytes.
- The editor's Inspector shows it as a JSON box with the array on one line, up to 512 elements; a longer array shows only
  its length (edit it with `scene.set_component` or a script).
- Not animatable by a clip, and `scene.set_component` with `merge` replaces the array (like any non-object value).

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
- **Docs.** `docs_components` and `docs.components`.
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
- **Know the order of `each`.** `world.each<A, B>` walks the pool with the fewest owners, in that pool's insertion order, so the order of a multi-type walk follows the counts. A system whose order is visible (events it queues, ids it hands out) drives by the type that must set the order: `world.each<A>(...)` and `world.get<B>(e)` inside.
- **Do not keep a `Transform&` or an `EntityInfo&` across a hierarchy read.** `world.world_matrix(e)` and `active_in_hierarchy(e)` come from a cache that a write through a mutable `get` drops; a reference stored before the read and written after it is not seen. Get it again after the read (docs/design/ARCHITECTURE_CORE.md, "The hierarchy cache").
- **Do not depend on graphics.** Headless runs without graphics have no renderer.
- **Keep the order documented.** Update the frame comment in `engine.h` and the module table in `docs/design/ARCHITECTURE.md` when you add a system.
- **Test it twice.** A C++ test calls the system directly (as in section C). A headless test checks the system inside a real frame when it changes the outcome of a game.

