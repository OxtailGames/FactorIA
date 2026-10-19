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
- Windows, from any shell (loads MSVC itself; prints only errors, unique warnings and failing tests, full logs in the
  build dir): `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\agent-build.ps1 build\agent-<name>
  [-Target fa_test_core] [-Tests core | -Test]`.
- GPU code without a display: headless EGL works with Mesa (llvmpipe). For
  windowed code use `xvfb-run -a -s "-screen 0 1280x720x24" <cmd>`.
- Each agent uses its OWN build dir (`build/agent-<name>`) and builds with `-j8`
  (at most three agents building at once; fewer jobs on a machine with under 16
  hardware threads). Install ccache (docs/BUILDING.md): with GCC/Clang every
  checkout and git worktree shares one compile cache; with MSVC each checkout
  keeps its own (sharing gave stale objects). Run the final full `ctest` while no
  other build runs: some tests are timing-sensitive.
- CI: `scripts/ci-local.sh linux windows` reproduces the Linux job and a Windows build (MinGW-w64 + Wine, D3D11)
  locally; run it before pushing a CI fix. The `/ci` Claude Code mod in `.claude/mods/ci` shows the GitHub checks
  of the branch's PR (`/plugin install ci --marketplace OxtailGames/FactorIA`, or `claude --plugin-dir .claude/mods/ci`).
- On a Windows host the Windows check is the native MSVC build plus the full `ctest` (Finishing a task); the MinGW +
  Wine `windows` job is for Linux-only hosts. Run the Linux and Android jobs in WSL (Ubuntu 24.04 set up with
  scripts/bootstrap-linux.sh and an Android NDK): push the branch, `git fetch && git checkout <branch>` in the WSL
  clone, then `wsl -d Ubuntu-24.04 --exec bash -lc 'cd ~/FactorIA && ./scripts/ci-local.sh linux android'` (logs in
  `build/ci-logs/`). `bash -lc` does not read `~/.bashrc`: export `ANDROID_NDK_HOME` in `~/.profile`, or android is
  skipped. Put the clone back on `main` afterwards.
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
- Language: the engine (code, comments, identifiers, error messages, CLI
  output, templates) and its documentation are in ENGLISH. English docs are the
  reference. Translations are welcome but optional: `README.<lang>.md` and
  `docs/i18n/<lang>/<SAME_NAME>.md`, with a language selector at the top. Update
  the English text first; a translation that falls behind must say so at the
  top. Translations are not embedded in the binary (AIs read English).
- Record engine gaps you notice while building examples in the example's
  `ENGINE_FEEDBACK.json` — the same loop we ask game-making AIs to follow.

## Models for agent work (every session on this project)

Split work across models the same way the engine's own AI roles do
(docs/AI_PROVIDERS.md). This holds for every Claude Code session on this
repository, not only the one where it was agreed:

- **Orchestrator — `opus`.** The main session: plans, triages feedback, splits
  work into packages, reviews and integrates the results, runs the full test
  suite, commits and pushes.
- **Workers — `sonnet`.** Implement features and fixes: Agent tool with
  `subagent_type: "worker"` (`.claude/agents/worker.md`: sonnet, medium effort,
  engine tools only). One work package per worker, each in its own git worktree
  or its own build dir (`build/agent-<name>`, `-j8`), with tests and docs. The
  worker knows the build command and the report format, so the brief carries only
  the package. A package that needs the browser pane: general-purpose,
  `model: "sonnet"`, `effort: "medium"`.
- **Fast — `haiku`.** Small mechanical tasks (`subagent_type: "fast"`: haiku,
  max effort): code searches, regenerating docs/typings,
  ENGINE_FEEDBACK/ROADMAP bookkeeping, renames.

## Finishing a task (every session on this project)

Nobody waits for CI. A task is done when its PR is open with auto-merge on and
nothing is left behind locally; GitHub merges it once the required `CI result`
check passes and deletes its branch:

- Start from the latest `origin/main` (`git fetch` first); merge `origin/main`
  into the branch again before opening the PR. If the task needs work whose PR
  has not merged yet, branch from that PR's branch instead.
- Before every push, build every target (`cmake --build <dir>`, no `--target`)
  and run the full `ctest`, not only the tests of the module you changed. CI
  should only find what this machine cannot run (other platforms, mobile).
- Open the PR and turn on auto-merge with a merge commit (no need to ask):
  `gh pr merge <n> --auto --merge`. If CI fails, fix it on the same branch;
  never merge red. A PR that changes `.github/workflows/release.yml` is the
  exception: its Release run is not part of `CI result`, so merge it by hand once
  that run is green too.
- Delete the local branch, remove the task's worktrees (agent worktrees
  included) and its `build/agent-<name>` dirs.
- Leave the main checkout on `main`, up to date with `origin/main`, clean.
