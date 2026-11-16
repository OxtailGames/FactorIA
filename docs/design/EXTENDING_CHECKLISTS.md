# Extending the engine: checklists (section E)

Part of [Creating tools and extending the engine](../EXTENDING.md), for engine developers (these pages are the engine's source docs: they are not embedded in the binary and `docs.read` does not serve them; read them in a checkout).

## E. Checklists

### Naming

- Commands are `area.verb_object` in snake_case: `scene.list_entities`, `feedback.report`. Existing areas (the registry
  of the 0.19.0 engine; `factoria commands` lists the ones of your version, and a new area is a new prefix): `ai`,
  `anim`, `anim3d`, `api`, `assets`, `audio`, `bones`, `checkpoint`, `docs`, `engine`, `feedback`, `feel`, `fs`, `game`,
  `i18n`, `ik3d`, `image`, `input`, `jobs`, `load`, `material`, `mesh`, `model`, `music`, `nav`, `perf`, `physics`,
  `platform`, `play`, `player`, `prefab`, `project`, `publish`, `render`, `review`, `rig`, `scene`, `screen`, `script`,
  `setup`, `sfx`, `shader`, `sign`, `skills`, `skin`, `skin3d`, `storage`, `tilemap`, `ui`, `vector`, `vfx`.
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
- Rendering tests compare headless golden images in `engine/render/tests/golden/*.png` (`expect_golden(img, "name")`) against limits on the mean error, the share of differing pixels and the largest error. A missing golden fails the test; `FA_UPDATE_GOLDENS=1` writes it (docs/design/BUILDING_TESTS.md, "Golden images").
- Determinism: fixed seed, fixed steps, no timing assertions.
- A bug fix starts with a failing test.

### Documentation

- `docs/*.md` is embedded in the binary. Update it in the same change as any user-facing behaviour.
- Generated references (components, commands) need no edit.
- Every ```` ```js ```` block of `docs/` is parsed as a module and its `world.`, `ui.`, `tween.`... names are checked against the generated typings (`tools/common/tests/docs_js_test.cpp`). Write code that parses; a block that is only a piece of a script (a class method without its class, a `return` outside a function) opens with ```` ```js fragment ````, which skips the parse but not the name check. Keep the marker rare. A wrong name is a doc bug: fix the doc, never the API.
- `docs/AI_GUIDE.md` is the workflow for game-making AIs. `templates/common/AGENTS.md` is the short guide that `factoria new` writes into each project, so keep the two consistent.

### Rules from `CLAUDE.md`

- Module order is in `docs/design/ARCHITECTURE.md`: core, scene, platform, then render, physics, audio and ui, then script, runtime, tooling, mcp and ai, then editor and cli. A module includes only modules before it.
- No exceptions cross module boundaries, except `CommandError` inside command handlers. Return `fa::Result<T>` with a message and a hint.
- No `rand()`. No wall clock in simulation.
- Do not edit `external/`. Wrap third-party code from engine code.
- Sources are globbed: a new `.cpp` in a module's `src/` needs no CMake edit. Platform files use suffixes `_linux`, `_win32`, `_apple` (`.m`, `.mm`), `_android`, `_posix`, `_egl` and `_web`.
- Record every engine gap you notice in the example's `ENGINE_FEEDBACK.json`.

