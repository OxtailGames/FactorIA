# FactorIA — instructions for AI agents working on the ENGINE

(Agents making a GAME with FactorIA: read the AGENTS.md generated inside the
game project instead, or `factoria docs ai-guide`.)

Read `docs/ARCHITECTURE.md` first. It explains modules, conventions and the
command/reflection systems everything is built on.

## Build & test (Linux; same commands on macOS/Windows with their presets)

```bash
cmake -S . -B build/dev -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build/dev -j4
ctest --test-dir build/dev --output-on-failure
```

- Build a single module's tests: `cmake --build build/dev --target fa_test_core`.
- GPU code without a display: headless EGL works with Mesa (llvmpipe). For
  windowed code use `xvfb-run -a -s "-screen 0 1280x720x24" <cmd>`.
- When several agents work in the same checkout, each uses its OWN build dir
  (`build/agent-<name>`) and builds with `-j2`.
- Shaders: edit `engine/render/shaders/*.glsl`, then run
  `tools/shaders/compile_shaders.sh` (fetches sokol-shdc into `.cache/` if
  needed) and commit the regenerated headers.

## Rules

- C++20, namespace `fa`, `snake_case` functions/variables, `PascalCase` types,
  `camelCase` JSON keys and component field names, 4-space indent, ~120 cols.
- Public headers: `engine/<module>/include/fa/<module>/*.h`. Private code:
  `engine/<module>/src/`. Sources are globbed: adding a `.cpp` needs no CMake
  edit. Platform files use suffixes `_linux`, `_win32`, `_apple` (.m/.mm),
  `_android`, `_posix`, `_egl`, `_web` (see cmake/FactoriaHelpers.cmake).
- Respect the module dependency order in ARCHITECTURE.md. Never include a
  module from a module below it.
- No exceptions across module boundaries (except `fa::CommandError` inside
  command handlers). Use `fa::Result<T>` with message + hint.
- Errors must teach: location (file, JSON pointer, line), what is wrong, how to
  fix it, and "did you mean" suggestions (`fa::did_you_mean`).
- Every reflected field and every command needs a doc string — they ARE the
  documentation AIs read.
- New capability that tools/AIs should use => register a command (C++ or JS
  tool), never a one-off CLI flag.
- Determinism: no `rand()`, no wall-clock in simulation; use `world.rng()` and
  the engine clock.
- Do not edit `external/`. Wrap or patch from engine code.
- Tests: add doctest cases in `engine/<module>/tests/` for new behaviour.
- Keep `docs/` in sync when changing user-facing behaviour (docs are embedded
  in the binary and served to AIs through MCP).
- Record engine gaps you notice while building examples in the example's
  `ENGINE_FEEDBACK.json` — the same loop we ask game-making AIs to follow.
