# FactorIA — instructions for AI agents working on the ENGINE

(Agents making a GAME with FactorIA: read the AGENTS.md generated inside the
game project instead, or `factoria docs ai-guide`.)

`docs/ARCHITECTURE.md` explains the modules, conventions and the command/reflection systems everything is built on.
It is long: list its headings (`grep -n '^#' docs/ARCHITECTURE.md`), always read "Design principles", "Repository
layout", "Reflection", "Commands" and "Testing", and then the sections your task touches (threads, loading, files,
rendering...).

## Build & test (Linux; same commands on macOS/Windows with their presets)

```bash
cmake -S . -B build/dev -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build/dev -j4
ctest --test-dir build/dev --output-on-failure
```

- The example games' tests (`example_*`, ctest label `example`) run the whole engine for minutes, so they are DISABLED
  in a Debug build and run on a Release one: `ctest -L example` in a Release build dir (`FA_EXAMPLE_TESTS`,
  docs/BUILDING.md). `scripts/test-all.sh` does both: Debug build of every target + the Debug suite, then a Release
  build of `factoria` + `ctest -L example` (`--debug-only` / `--examples-only` for one half). Script time limits (60 s
  per test, 5 s eval, 2 s callbacks) count CPU time, so a loaded machine does not fail them.
- One module's tests: `cmake --build build/dev --target fa_test_core`.
- Editor autotest while iterating: `FA_EDITOR_AUTOTEST=1 FA_EDITOR_AUTOTEST_SECTIONS=K,M <build>/tools/editor/fa_editor_autotest`
  runs only those sections (docs/EDITOR.md, "Run only some sections").
- Windows, from any shell (loads MSVC itself; prints only errors, unique warnings and failing tests, full logs in the
  build dir): `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\agent-build.ps1 build\agent-<name>
  [-Target fa_test_core] [-Tests core | -Test] [-Examples]`.
- GPU code without a display: headless EGL works with Mesa (llvmpipe). Windowed code: `xvfb-run -a -s "-screen 0
  1280x720x24" <cmd>`.
- Each agent uses its OWN build dir (`build/agent-<name>`) and builds with `-j8` (at most three agents building at
  once; fewer jobs under 16 hardware threads). ccache (docs/BUILDING.md): with GCC/Clang every checkout and worktree
  shares one cache; with MSVC each checkout keeps its own. Run the final full `ctest` while no other build runs: some
  tests are timing-sensitive.
- Other platforms locally: `scripts/ci-local.sh linux windows` runs the Linux job and a Windows build (MinGW-w64 +
  Wine, D3D11) on a Linux host. On a Windows host run the Linux and Android jobs in WSL (Ubuntu 24.04 set up with
  scripts/bootstrap-linux.sh, `ANDROID_NDK_HOME` exported in `~/.profile`, since `bash -lc` skips `~/.bashrc`): push
  the branch, check it out in the WSL clone, `wsl -d Ubuntu-24.04 --exec bash -lc 'cd ~/FactorIA &&
  ./scripts/ci-local.sh linux android'` (logs in `build/ci-logs/`), then put the clone back on `main`. The `/ci` mod
  in `.claude/mods/ci` shows the GitHub checks of the branch's PR.
- Shaders: edit `engine/render/shaders/*.glsl`, run `tools/shaders/compile_shaders.sh` (fetches sokol-shdc into
  `.cache/`) and commit the regenerated headers.

## Rules

- C++20, namespace `fa`, `snake_case` functions/variables, `PascalCase` types, `camelCase` JSON keys and component
  field names, 4-space indent, ~120 cols.
- Public headers: `engine/<module>/include/fa/<module>/*.h`. Private code: `engine/<module>/src/`. Sources are
  globbed: adding a `.cpp` needs no CMake edit. Platform files use suffixes `_linux`, `_win32`, `_apple` (.m/.mm),
  `_android`, `_posix`, `_egl`, `_web` (cmake/FactoriaHelpers.cmake).
- Module dependency order; a module never includes a module below it:
  `core -> scene -> platform -> render, physics, audio, ui, services -> script -> runtime -> tooling -> mcp, dap, ai -> editor -> cli`.
- No exceptions across module boundaries (except `fa::CommandError` inside command handlers). Use `fa::Result<T>`
  with message + hint.
- Errors must teach: location (file, JSON pointer, line), what is wrong, how to fix it, and "did you mean"
  suggestions (`fa::did_you_mean`).
- Every reflected field and every command needs a doc string — they ARE the documentation AIs read.
- New capability that tools/AIs should use => register a command (C++ or JS tool), never a one-off CLI flag.
- Determinism: no `rand()`, no wall-clock in simulation; use `world.rng()` and the engine clock.
- Do not edit `external/`. Wrap or patch from engine code.
- Tests: add doctest cases in `engine/<module>/tests/` for new behaviour.
- Keep `docs/` in sync when changing user-facing behaviour (docs are embedded in the binary and served to AIs
  through MCP).
- Language: the engine (code, comments, identifiers, error messages, CLI output, templates) and its documentation are
  in ENGLISH, the reference. Translations are optional: `README.<lang>.md` and `docs/i18n/<lang>/<SAME_NAME>.md`, with
  a language selector at the top. Update the English text first; a translation that falls behind says so at the top.
  Translations are not embedded in the binary (AIs read English).
- Record engine gaps you notice while building examples in the example's `ENGINE_FEEDBACK.json`.
- Feedback from installations (`factoria feedback pull`): triage it before you act on it. Reports that claim a gap the
  engine already has (a component, field or command that exists) are rejected with a reason, never built (`feedback
  reject --suggested`, `keep`, `unreject`; docs/ENGINE_FEEDBACK.md, "Triage loop").

## Agent work (every session on this project)

- **Orchestrator: the main session.** Plans, triages feedback, splits a milestone into packages, briefs and reviews
  them, integrates, runs the tests, commits and pushes.
- **Model and effort per agent.** Before each Agent call pick the model (`opus`, `sonnet`, `haiku`; never `fable`)
  and the effort (`low` to `xhigh`; never `max`) that does that task best for the least quota, pass both, and say in
  one line which and why. Weigh rounds, not only price: one `opus` round can cost less than three `sonnet` rounds, and
  mechanical work wastes a big model. Defaults:
  - Workers (`subagent_type: "worker"`): one package each, in its own worktree or build dir. The worker file carries
    the build commands, the checks before reporting and the report format, so the brief carries only the package.
    `sonnet` `medium` for S and M packages; `high` for L packages and for code where CI finds what this host does not
    (`engine/core` public headers, platform files, render GL/D3D11 and shaders, waits, timeouts, threads, file I/O,
    the editor autotest). `opus` only where the host cannot test the risk (threads, file I/O and Windows paths,
    render, platform files): in M70 a bigger model did not save rounds, the review did. A package that needs the
    browser pane: general-purpose with `sonnet`.
  - Reviewers (`subagent_type: "reviewer"`): every package, before it merges into the milestone branch. `sonnet`
    `high`; `opus` only for subtle concurrency or Windows path/file code. Give it the branch and the base, not the
    worker's report or your view of the change.
  - `fast` (`haiku`): code searches, docs and typings regeneration, ENGINE_FEEDBACK/ROADMAP bookkeeping, renames.
- **Fix rounds.** Only BLOCKING review findings send a package back, strictly: a review with no BLOCKING finding gets
  no round, however important its POLISH items look. POLISH goes on one list, fixed in one package at the end of the
  milestone, before the version bump.

## Finishing a task (every session on this project)

GitHub is touched once per milestone (or per block of milestones the user groups): one `m<N>/integrated` branch, one
PR, one version, one tag. Workers stay in local worktrees and branches; no per-package PRs, no pushes of work in
progress.

- Cut the branch from the latest `origin/main` (`git fetch` first) and merge `origin/main` into it again before the
  PR. If it needs work whose PR has not merged yet, cut it from that PR's branch.
- Version: the minor for a milestone (0.4.0 -> 0.5.0), the patch for a batch of fixes only. Bump `VERSION` in
  CMakeLists.txt, rename `## Unreleased` in CHANGELOG.md to it with a one-paragraph summary, replace every
  `"unreleased"` in tools/common/api_since.json with it and regenerate the docs and typings (docs/ARCHITECTURE.md,
  "Versions"). The user sees it in the window title and at the right end of the editor's menu bar.
- Before the push: the Debug build of every target and the full Debug `ctest` (`scripts/test-all.sh --debug-only`),
  and read the whole diff for what this host does not exercise: Windows file rules (a file open elsewhere cannot be
  replaced or deleted, file times step ~15 ms, case-insensitive paths, CRLF), waits, timeouts and speed or memory
  budgets a loaded 4-vCPU CI VM misses, MSVC and GCC warnings and missing includes, the GL and D3D11 paths of render
  code. No `scripts/ci-preflight.sh` before the push (it took hours and CI still found failures): CI is the
  cross-platform check. The preflight and the native Windows check on the user's PC (`scripts/ci-remote-windows.sh`)
  are for when the user asks or to confirm a CI fix; the PC is often off: never switch it on or wake it, ask the user.
- Open the PR and turn on auto-merge with a merge commit (no need to ask): `gh pr merge <n> --auto --merge`. If CI
  fails, fix it on the same branch and push again; never merge red. A PR that changes `.github/workflows/release.yml`
  is the exception: its Release run is not part of `CI result`, so merge it by hand once that run is green too.
- Install every new version on the user's Mac too: build the macOS universal package (the macOS job of
  .github/workflows/release.yml: Android, iOS and Web players plus the `macos-release` universal build;
  on the Mac the untracked `build/build-release-local.sh` of the main checkout does it, output
  `build/dist/FactorIA-macos-universal.tar.gz`), keep the old
  install as `~/FactorIA-<old version>`, swap each file of `~/FactorIA` by rename (`mv`, never copy over a binary) so
  a running editor survives, and check that `~/FactorIA/factoria --version` prints the new version. Do not run
  `factoria setup launcher`: the running editor restarts through the Dock app and the new one refreshes the launcher.
- Once the PR merges: tag `v<version>` on its merge commit, only with the user's OK.
- Delete the local branch, the task's worktrees (agent worktrees included) and its `build/agent-<name>` dirs. Leave
  the main checkout on `main`, up to date with `origin/main`, clean.
