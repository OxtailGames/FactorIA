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

- The example games' tests (`example_*`, ctest label `example`) run the whole engine for minutes, so they are DISABLED in
  a Debug build and run on a Release one: `ctest -L example` in a Release build dir (`FA_EXAMPLE_TESTS`, docs/BUILDING.md).
  **`scripts/test-all.sh` is the one command that does both**: Debug build of every target + the Debug suite, then a
  Release build of `factoria` + `ctest -L example` (`--debug-only` / `--examples-only` for one half; Windows:
  `scripts\agent-build.ps1 build\agent-<name> -Test -Examples`). Script time limits (60 s per test, 5 s eval, 2 s
  callbacks) count CPU time, so a loaded machine does not fail them.

- Build a single module's tests: `cmake --build build/dev --target fa_test_core`.
- Editor autotest while iterating: `FA_EDITOR_AUTOTEST=1 FA_EDITOR_AUTOTEST_SECTIONS=K,M <build>/tools/editor/fa_editor_autotest`
  runs only those sections (docs/EDITOR.md, "Run only some sections"); the full run (`scripts/test-all.sh`) is still required before a push.
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
- Feedback from installations (`factoria feedback pull`): triage it before you act on it. Reports that claim a gap the engine already
  has (a component, field or command that exists) are rejected with a reason the sender reads in their editor, never built:
  `feedback pull` lists them as suggested rejections, then `feedback reject --suggested` (or `reject <shareId>... --reason`,
  `--file`), `feedback keep`, `feedback unreject`; nothing asks a question. The loop is in docs/ENGINE_FEEDBACK.md, "Triage loop".

## Models for agent work (every session on this project)

Split work across models the same way the engine's own AI roles do
(docs/AI_PROVIDERS.md). This holds for every Claude Code session on this
repository, not only the one where it was agreed.

**Pick the model and effort for each task.** Before you give any task to an
agent, decide which available model (`opus`, `sonnet` or `haiku`; never
`fable`) and which effort (`low`, `medium`, `high` or `xhigh`; never `max`)
does that task best for the least quota. Pass both on the Agent call (`model`
and `effort`), and say in one line which you picked and why. Weigh the rounds,
not only the price per token: one `opus` round on a hard or risky package can
cost less than three `sonnet` rounds, and a mechanical task wastes quota on a big
model. The roles below are the defaults to reason from, not a fixed table. The
`fast` agent type defaults to `max`, so always pass a lower effort for it.

- Hard, risky or design-heavy work (L packages; platform files, threads, render,
  the editor autotest, Windows path or file code): `opus` or `sonnet` at `high`
  or `xhigh`.
- Normal S and M features and fixes: `sonnet` at `medium` or `high`.
- Reviews: `sonnet` at `high`; `opus` for subtle concurrency or Windows path code.
- Searches, bookkeeping, doc and typing regeneration, renames: `haiku` at `low` or
  `medium`.

The default roles:

- **Orchestrator — `opus`.** The main session: plans, triages feedback, splits
  work into packages, reviews and integrates the results, runs the full test
  suite, commits and pushes.
- **Workers — `sonnet`.** Implement features and fixes: Agent tool with
  `subagent_type: "worker"` (`.claude/agents/worker.md`: sonnet, medium effort,
  engine tools only). One work package per worker, each in its own git worktree
  or its own build dir (`build/agent-<name>`, `-j8`), with tests and docs. The
  worker knows the build command, the checks before reporting and the report
  format, so the brief carries only the package. A package gets `effort: "high"`
  on the Agent call when it is L (its size in the ROADMAP) or when it touches
  code where CI finds what this host does not: `engine/core` public headers,
  platform files (`_win32`, `_linux`, `_apple`, `_android`, `_web`, ...), render
  code (GL and D3D11 paths, shaders), waits, timeouts, threads and file I/O
  (Windows file rules), and the editor autotest. Other S and M packages stay at
  medium, where time goes to builds and tests. A package that needs the browser
  pane: general-purpose, `model: "sonnet"`, the same effort rule.
- **Reviewer — `sonnet`, high effort.** Before a worker's package is merged into
  the integration branch, a reviewer (`subagent_type: "reviewer"`,
  `.claude/agents/reviewer.md`) reads its diff with fresh context, looking for
  what this host does not exercise (the list in "Finishing a task") and for
  bugs. Give it the branch and the base, not the worker's report or your own
  view of the change. It only reports; the orchestrator decides and has the
  worker (or a new one) fix what holds up. A preflight round costs hours, a
  review minutes.
- **Fast — `haiku`.** Small mechanical tasks (`subagent_type: "fast"`: haiku;
  pass `effort` yourself, its default is max): code searches, regenerating docs/typings,
  ENGINE_FEEDBACK/ROADMAP bookkeeping, renames.

## Finishing a task (every session on this project)

Nobody waits for CI. A task is done when its PR is open with auto-merge on and
nothing is left behind locally; GitHub merges it once the required `CI result`
check passes and deletes its branch:

- Start from the latest `origin/main` (`git fetch` first); merge `origin/main`
  into the branch again before opening the PR. If the task needs work whose PR
  has not merged yet, branch from that PR's branch instead.
- Before every push run `scripts/test-all.sh`: every target built in Debug and the full Debug `ctest`, then the example
  games on a Release build (`ctest -L example`), not only the tests of the module you changed. CI
  should only find what this machine cannot run (other platforms, mobile).
- A push must not fail CI: checking that a worker's package works is not enough. Before the push, read the branch's
  whole diff for what this host does not exercise and fix it first: Windows file rules (a file open elsewhere cannot
  be replaced or deleted, file times step ~15 ms, case-insensitive paths, CRLF), waits, timeouts and speed or memory
  budgets that a loaded 4-vCPU CI VM misses, other compilers (MSVC and GCC warnings, missing includes), the GL and
  D3D11 paths of render code. Run the editor autotest sections and examples the change touches a few times while the
  machine is busy (timing bugs hide on a fast idle machine), and every `scripts/ci-local.sh` job this host supports.
  `scripts/ci-preflight.sh` does all of it in one command (risk scan of the diff, `test-all.sh`, the stress pass under
  CPU load, the other platforms; docs/BUILDING.md, "Before a push"): run it before every push and read its SKIP lines.
  On a Mac it runs the Linux job in Docker (`scripts/setup-docker-macos.sh` once) and the native Windows check on the
  user's PC over SSH (`scripts/ci-remote-windows.sh`). The PC is often off: never switch it on or wake it; when that
  step exits 77 because the PC is off or nobody is logged in, ask the user in chat and wait until they say it is ready.
- Open the PR and turn on auto-merge with a merge commit (no need to ask):
  `gh pr merge <n> --auto --merge`. If CI fails, fix it on the same branch;
  never merge red. A PR that changes `.github/workflows/release.yml` is the
  exception: its Release run is not part of `CI result`, so merge it by hand once
  that run is green too.
- Each milestone (M<n>) raises the engine version when it lands, so the user sees which FactorIA they run (window
  title and the right end of the editor's menu bar): the minor for a milestone (0.4.0 -> 0.5.0), the patch for a batch
  of fixes only. Bump `VERSION` in CMakeLists.txt, rename `## Unreleased` in CHANGELOG.md to it with a one-paragraph
  summary, replace every `"unreleased"` in tools/common/api_since.json with it and regenerate the docs and typings
  (docs/ARCHITECTURE.md, "Versions").
- Every new engine version is also installed on the user's Mac, on top of CI and the GitHub release: build the
  macOS universal package locally (the steps of the macOS job in .github/workflows/release.yml: Android, iOS and Web
  players plus the `macos-release` universal build), keep the old install as `~/FactorIA-<old version>`, replace the
  files of `~/FactorIA` with the package's and check that `~/FactorIA/factoria --version` prints the new version.
  Swap each file by rename (`mv`, never copy over a binary) so a running editor survives, and do not run `factoria
  setup launcher`: the running editor restarts through the Dock app and the new one refreshes the launcher.
- Delete the local branch, remove the task's worktrees (agent worktrees
  included) and its `build/agent-<name>` dirs.
- Leave the main checkout on `main`, up to date with `origin/main`, clean.
