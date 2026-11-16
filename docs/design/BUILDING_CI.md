# Building FactorIA: formatting, before a push and continuous integration

Part of [Building FactorIA](BUILDING.md) (the entry page lists every page).

## Formatting and lint

First-party C and C++ (`.c .cc .cpp .h .hpp` under `engine/`, `tools/`, `player/`, `platforms/`, `examples/`,
`templates/`) follows `.clang-format` (the CLAUDE.md style: 4 spaces, 120 columns, attached braces, no indent inside
namespaces, indented `case`, `T* p`, two spaces before a trailing comment; includes keep the order the author wrote).
`.clang-format-ignore` lists what is never formatted: `external/`, the shader headers `tools/shaders` generates and the
byte-exact test data. Objective-C (`.m`, `.mm`) is not formatted. `.editorconfig` has the whitespace rules for every other
file type (LF, UTF-8, final newline; CRLF only for `.bat` and `.cmd`, as `.gitattributes` says).

```bash
scripts/format.sh                      # format every file in place
scripts/format.sh --check              # change nothing; list the files that need it, exit 1 if any
scripts/format.sh --changed origin/main        # only the files changed against a base (and uncommitted ones)
scripts/format.sh --check --changed origin/main
scripts/tidy-changed.sh origin/main    # clang-tidy over the changed .cpp files
```

The scripts use one pinned `clang-format` and `clang-tidy` (the versions are at the top of `scripts/lint-tools.sh`;
formatting differs between versions, so a different one gives different results). The first run installs them as pip
wheels into a venv in `build/lint-venv`: nothing is installed system wide, and it is the same on macOS, Linux and
Windows (Git Bash). To change a version, edit that file.

`.clang-tidy` enables bug finders only (use after move, dangling views, `sizeof` mistakes, `memset` and string
constructor mistakes, redundant expressions, `std::move` of a const...), no style or modernizing checks, and every hit is
an error. `scripts/tidy-changed.sh <base> [build-dir]` runs them over the first-party `.cpp` files changed against the
base, with the `compile_commands.json` of a CMake configure (`build/tidy`, configured on first use: configure only,
nothing is compiled). Files that only a commit of `.git-blame-ignore-revs` changed (a repository-wide reformat) are
left out. A false positive: rewrite the line or end it with `// NOLINT(<check>)` and a reason.

Both scripts exit 0 when clean, 1 when they found something (files to format, a tidy diagnostic) and 2 when the tool
or its setup failed (no Python, pip, git diff against an unknown base, a CMake configure, a clang crash): a 2 is never a
finding. `scripts/tidy-changed.sh --all` checks every first-party `.cpp` (about an hour on a laptop; the CI job only
checks what a change touches). The configure also builds the one generated header the sources need
(`fa_build_fingerprint.h`).

CI has a `lint` job (Ubuntu, cheap, part of `CI result`): `scripts/format.sh --check --changed <base>` and
`scripts/tidy-changed.sh <base>`, where the base is the pull request's base commit (the commit before, on a push);
`scripts/ci-preflight.sh --lint-only` runs the same steps on your machine ("Before a push"). When
every file is formatted, set `FORMAT_SCOPE: all` in that job's `env` in `.github/workflows/ci.yml` and the check covers
the whole repository. A repository-wide reformat is one commit with no other change; add its hash to a `.git-blame-ignore-revs` file
(`git config blame.ignoreRevsFile .git-blame-ignore-revs`) so `git blame` skips it.

## Before a push

`scripts/ci-preflight.sh` is the one command to run before every push, so the PR passes GitHub CI the first time. It
covers what CI exercises and a developer machine does not (Windows file semantics, waits and budgets on loaded 4-vCPU VMs,
compilers other than yours, other platforms):

1. **Risk scan.** The lines the branch adds (`git diff <base>...HEAD`, base `origin/main`) are checked against a table of
   patterns that failed CI before: `std::ofstream` or `rename`/`remove` on files others may hold open, `sleep_for`, wall-clock
   time and timeouts in tests and editor autotests, perf/memory budget files, platform `#if` branches, `.glsl` edits without
   regenerated headers, render-backend code, headers using `std::format`/`<ranges>`/`<thread>`/`<chrono>`/`<cstring>` without
   the include, `long`/`%ld` formats, text parsing that may see CRLF, case-only path clashes and workflow changes. It prints
   file:line, why it matters and what to check. The table is the `RULES` block of the script: add a line to add a pattern.
   The scan reads commits only, and never fails the run unless `--strict`.
2. **Lint.** What the `lint` job of CI runs, against the same base: `scripts/format.sh --check --changed <base>`,
   `scripts/check-ci-cache-keys.py`, `scripts/check-player-includes.py` (player/ and templates/ never include
   `fa/runtime/internal/`), `scripts/ctest_shard.py --self-test` and `scripts/tidy-changed.sh <base>` (clang-tidy,
   the slow one: `FA_TIDY_JOBS`, half the CPUs by default). Each has its own line in the summary, and one that fails
   does not stop the others. `--lint-only` runs the risk scan and this step and nothing else: it builds nothing and takes
   minutes, so run it before every push, also the push of a fix (a file left unformatted costs a whole CI round).
3. **`scripts/test-all.sh`**, with the same environment variables.
4. **Stress.** The editor autotests (`editor_autotest_*`, in the Debug dir) and the example tests (`example_<name>_*`, in the
   Release dir) the diff touches run with `ctest --repeat until-fail:N` while one CPU burner per core keeps the machine busy.
   `tools/editor/**` selects the editor autotests, `examples/<name>/**` that example's tests, `engine/**`, `tools/cli/**`,
   `tools/common/**`, `external/**` and the CMake files all of both; docs and scripts select nothing. The example tests get twice their
   ctest limit (`FA_EXAMPLE_TEST_TIMEOUT`) in this pass, since the burners halve their CPU; it is put back afterwards. The
   burners are killed when the script ends, fails or is interrupted. `--plan` prints the selection only.
5. **Other platforms.** The `scripts/ci-local.sh` jobs this host supports (Mac: `macos ios web android`; Linux: `linux windows
   android web`; a job without its tooling skips itself), then on a Mac `scripts/ci-docker.sh linux` (the Linux job in
   Docker; its MinGW + Wine Windows job is not a reference on a Mac, see below) and `scripts/ci-remote-windows.sh`, the
   native Windows check on a PC (exit 0 pass, 1 fail, 77 not set up, PC off or nobody logged in: reported as SKIP).

It ends with a PASS/FAIL/SKIP table with the time of each step and exits 1 if any step failed. Logs:
`build/ci-logs/preflight-<step>.log`.

```bash
scripts/ci-preflight.sh                      # everything
scripts/ci-preflight.sh --lint-only          # risk scan + lint (minutes, no build): before every push
scripts/ci-preflight.sh --quick              # risk scan + lint + test-all only
scripts/ci-preflight.sh --no-stress --no-platforms
scripts/ci-preflight.sh --repeat 5 --base origin/main --strict
scripts/ci-preflight.sh --scan-only          # the risk scan alone (seconds)
scripts/ci-preflight.sh --no-test --no-platforms  # stress only, on the build dirs of an earlier run
```

On a Windows host the script (Git Bash) runs the risk scan and the lint step without clang-tidy, and then points to `scripts\agent-build.ps1 build\agent-<name>
-Test -Examples`, the Windows build and test path.

## Continuous integration (local, no GitHub minutes)

CI runs on your own machine with one script. It runs every job the host can run
and reports the others as skipped, with the reason:

```bash
./scripts/ci-local.sh            # all jobs this machine supports
./scripts/ci-local.sh linux      # just one job
```

| Job | Runs on | What it checks |
|---|---|---|
| `linux` | Linux, or a Mac with Docker (see below) | full build + every ctest suite (GPU tests through Xvfb + Mesa llvmpipe) |
| `windows` | Linux with `g++-mingw-w64-x86-64-posix` (+ `wine64 wine` to run tests), or a Mac with Docker (see below) | Windows x64 cross-build (D3D11 backend), every unit-test `.exe` under Wine, and a CLI smoke test that creates, validates, tests and renders a game through D3D11 |
| `android` | any host with `ANDROID_NDK_HOME` (NDK r27+) | `factoria_player` for arm64-v8a |
| `macos` | a Mac | macOS build + ctest |
| `ios` | a Mac with Xcode | iOS Simulator app bundle with a demo game |
| `web` | any host with `EMSDK` set (Emscripten 6.0.10), Node 22+ and Chrome or Chromium (`CHROME_BIN`) | the web player (`web-release`), the `factoria` CLI, a template game exported with `--platform web`, the zip checked as itch.io takes it (`index.html` at the root, at most 1000 files and 500 MB) and the export run in headless Chrome until `player: 60 frames rendered` (`scripts/web-smoke.sh`) |
| `sniper` | Linux with Docker or Podman, or a Mac with Docker; only when named (`./scripts/ci-local.sh sniper`) | the Linux release programs built in the Steam Runtime sniper container, their symbol versions checked, and run in the sniper runtime (`scripts/build-sniper.sh all`) |

Logs go to `build/ci-logs/`. The exit code is non-zero if any job that ran failed.

**Linux and Windows jobs on a Mac (Docker).** Run `./scripts/setup-docker-macos.sh` once: it installs Colima and the
Docker CLI with Homebrew and starts a Colima VM (Apple Virtualization.framework with Rosetta, 6 CPUs, 8 GiB, 100 GiB
disk; `FA_DOCKER_CPUS`, `FA_DOCKER_MEMORY` and `FA_DOCKER_DISK` change them). It is safe to run again. After that
`./scripts/ci-local.sh` runs the `linux`, `windows` and `sniper` jobs through `./scripts/ci-docker.sh`, which you can
also run on its own (`./scripts/ci-docker.sh linux windows`; exit code 77 means Docker is not set up, and `ci-local.sh`
then skips those jobs). The jobs run in an Ubuntu 24.04 `linux/amd64` container (`tools/ci/docker/Dockerfile`, the
GitHub runner's OS, built the first time) with the checkout mounted at `/src`. The Linux build trees, ccache, the Wine
prefix and `~/.factoria` in the container live in Docker volumes (`factoria-ci-home` for ccache, the Wine prefix and
`~/.factoria`; `factoria-ci-linux-<hash>` and `factoria-ci-windows-<hash>` for the build trees), so the second run is
warm and your macOS build directories never see a Linux object. Each checkout and git worktree has its own build-tree
volumes, named by a hash of its path: a tree shared by two checkouts would keep objects newer than the other branch's
sources and link them; the shared ccache keeps a new worktree's first build fast. `FA_CI_DOCKER_RESET=1` deletes
this checkout's volumes and the shared one; the volumes of a removed worktree stay until `docker volume prune`. A worktree's git directory is mounted read-only at its host path, so the
build has an identity in the container.

What the container does not reproduce. The `linux` job is the reliable one: the same Ubuntu 24.04 and GCC as the
runner, with three differences. The `*_perf` budget tests are not run (the numbers are the runner's; emulated x86-64
uses about 30% more memory and twice the CPU time; `FA_CI_DOCKER_PERF=1` runs them), and an example game's test may
run 900 s instead of 300 (`FA_EXAMPLE_TEST_TIMEOUT`; the longest takes ~170 s on the runner and over 300 s emulated). The image has Node 22 like the
runner, so the feedback server's tests run. The `windows` job (MinGW-w64 under
Wine) is not a reference on a Mac: Ubuntu's Wine 9.0 under Rosetta has no `atan2` in its HLSL compiler, so every
test that renders through D3D11 fails, some Windows file and process tests fail on the bind mount, and a hung
program is stopped after `FA_CI_WINE_TIMEOUT` seconds (600). The build half of that job (the MinGW cross-compile)
does catch Windows compile and link errors. For the Windows tests use a Windows host (`scripts/ci-remote-windows.sh`
or the native MSVC build). Neither job reproduces MSVC, WARP, or the GitHub runner's CPU and ccache state.

**The shader compiler.** Custom materials (`*.material.json`) are compiled with sokol-shdc, a separate program the
build does not make (the release downloads carry it next to `factoria`, see Releasing). Install the pinned one with the CLI you just built: `factoria setup shaders` (about 10 MB, SHA-256
checked, into `~/.factoria/tools/sokol-shdc/<commit>/`; `SOKOL_SHDC=/path/to/sokol-shdc` or a sokol-shdc next to
`factoria` also works). Without it the doctests that run the real compiler (`real sokol-shdc: ...` in `fa_test_tooling`,
the exports of materials) skip themselves and `factoria validate` only warns, so a change to the shaders can look green
while untested. The CI jobs that run ctest on a desktop (Linux, Windows, macOS) and `ci-local.sh linux` therefore run
`factoria setup shaders` right after the build (it fails when the install does) and run ctest with
`FA_REQUIRE_SHDC=1`: with it those doctests FAIL when no compiler is found instead of skipping, so a broken install
cannot turn into silent skips (the variable is not set locally, where skipping is the right answer on a machine without the
compiler). On Windows, Windows Defender flags the pinned `sokol-shdc.exe` by mistake and may remove it (the setup says so
when it sees it go); if it happens on a runner, the job fails at that step or at the tests, never skips. The `Linux (Steam
Runtime sniper)` job builds release programs and runs no ctest, so it does not install the compiler; the Windows (MinGW +
Wine) job of `ci-local.sh` runs the unit-test programs without it, and the MSVC run of `ci-local.sh` (`build.ps1`) does
not set `FA_REQUIRE_SHDC`.
MinGW is not MSVC: Visual Studio-only issues still need `scripts/build.ps1` on a
Windows PC.

`.github/workflows/ci.yml` runs the full five-platform matrix (Linux, Windows/MSVC,
macOS, iOS Simulator, Android) on GitHub-hosted runners; standard hosted runners
are free for public repositories. It runs once per change:

- **Pull requests**: every push to a branch with an open pull request.
- **`main`**: every push (including merged pull requests).
- **Other branches**: no automatic run, so a PR branch is not built twice. Start
  one by hand from the Actions tab ("Run workflow"; every job) or open a pull request.
- **`v*` tags**: no run of this workflow. The tag goes on the merge commit of a pull request: the push to `main` already
  ran this workflow on that very commit, so a run on the tag would repeat it. Check that run is green before tagging
  (`gh run list --commit <sha> --workflow CI`; a later push to `main` cancels it, then run it again from the Actions tab);
  `release.yml` builds and tests the packages on the tag.

A run only builds what the change can break (the `changes` job compares it with its
base): a change to docs only (`docs/`, `feedback/`, top-level `*.md`) builds nothing,
and the iOS and Android jobs run only when the change touches what they build or run
(`engine/`, `player/`, `platforms/`, `external/`, `cmake/`, `templates/`,
`tools/common/`, `tools/cli/`, `scripts/`, the top-level CMake files or `ci.yml`).
The jobs `Linux (Clang, ASan + UBSan)` and `Linux (Clang, TSan, threaded tests)` build with sanitizers and run the Debug
suite and the threaded tests ("Sanitizers" in [BUILDING_TESTS.md](BUILDING_TESTS.md#sanitizers)), each with its own ccache. The job `Linux (Steam Runtime sniper)` builds the Linux release programs as `release.yml` does and runs them in Valve's
sniper runtime image (`scripts/build-sniper.sh`, "Linux release" in [BUILDING_SCRIPTS.md](BUILDING_SCRIPTS.md#linux-release-scriptsbuild-snipersh)), with its own ccache. The last job,
`CI result`, fails if any job that ran failed. It is the only check that
the branch protection of `main` requires, so a pull request with auto-merge on
(`gh pr merge <n> --auto --merge`) merges itself when it passes, and GitHub then
deletes its branch. `release.yml` is not part of `CI result`: a pull request that
changes it is merged by hand once its Release run is green.

The Linux and macOS test steps run `ctest --parallel` with the runner's vCPUs (4 on Linux, 3 on macOS). Windows runs
one test at a time: its editor autotests draw with the software D3D11 renderer (WARP), which already fills the runner's
4 vCPUs, so running tests side by side made the step slower and its timing-sensitive tests fail. Instead the Windows job is a
matrix of three machines (`Windows (... tests 1/3)` to `3/3`): each builds (with a warm ccache that takes about a
minute) and runs a third of the tests, chosen by `scripts/ctest_shard.py`. Every machine lists the same tests and
splits them the same way, balancing the expected time of each third with the times measured on the runner (the table
in the script, one per preset, taken from a green CI run named in its comment; a test not listed counts 2 s and a disabled one 0),
so a new test runs in exactly one shard (the script checks that before it runs anything, and `python scripts/ctest_shard.py
--self-test`, run by the `lint` job, checks the split on a made-up list). Only shard 1 saves the ccache and prints the
physics replay hash. `python scripts/ctest_shard.py --preset <preset> --shard 1 --of 3` runs one third on your machine too.
The `linux-asan` job is split the same way into two (`--preset linux-asan --of 2`, each shard with `ctest --parallel 4`, only
shard 1 trims, saves and prunes the ccache, the failure artifacts are `linux-asan-test-output-1` and `-2`); its table holds the
times of the run with all tests on one machine, measured four tests at a time. The `tooling` test, then one process, took
19 of that run's 21 minutes of testing and so set the length of the round; it is now the five entries `tooling_1` ...
`tooling_5` (`ctest -L tooling` runs them; `tools/common/CMakeLists.txt`, docs/design/ARCHITECTURE.md "Testing"), which the table
lists with estimates (a fifth of the old time each) until a green run of the split gives real ones. With them the two
shards are expected to take about 6.6 and 6.7 minutes of testing, and a third machine would only bring that to 5.3 (the
longest test, `runtime`, is the floor), so two stay. The performance
budgets have the `RUN_SERIAL` property, so `ctest` runs each of them alone and the other tests cannot skew their times.
A newer push to the same pull request or branch cancels the older run (not a manual "Perf baselines" run
of that ref: the event and the `perfBaselines` and `benchBaselines` ticks are part of the concurrency group). The `bench`
job builds only `fa_bench` and compares the engine's microbenchmarks with `tools/bench/baselines/linux-gcc.json`
(docs/PERFORMANCE.md, "Microbenchmarks"). A `_perf` test that passes inside
the warning band is invisible to ctest; the step "Performance warnings" of the Linux, Windows and macOS jobs lists those
in the job summary (`scripts/ci-perf-warnings.sh`, docs/PERFORMANCE.md "The band").
Each job that compiles restores a ccache and saves it again right after the build, so a run whose tests fail still
leaves the next run a warm cache. Three rules keep that cache from shrinking or piling up:

- The trim (`ccache --evict-older-than 7200s`, which keeps only the entries this build used) runs only after a build
  that succeeded. A build that fails after a minute used almost nothing: trimming then would save a cache smaller than the
  one restored, and as the newest cache of the pull request it would hide `main`'s (Windows once restored 15 MB where
  `main`'s was 258 MB). Without the trim the saved cache is the restored one plus the new objects.
- The save runs whenever the build step started: after a green build, after a build that failed (the objects that did
  compile) and when a newer push cancelled the job in the middle of the build (`if: always() && ...`; the next round of
  the pull request starts warm instead of from the older cache: a cold Windows build takes 75-80 minutes, a warm one 8-14).
  It does not run when the restore failed or the build step was skipped (an earlier step failed), and Windows saves from
  shard 1 only.
- Every job that saved then deletes the older caches of the same ccache on the same branch or pull request
  (`scripts/ci-prune-caches.sh <key prefix>`, step "Delete this ref's older ccaches", which needs `actions: write` on the
  job's token). It lists only the caches of `GITHUB_REF`, only keys of exactly the form `<prefix><run id>` (so
  `ccache-Linux-gcc-` never touches another job's `ccache-Linux-linux-asan-<id>`), and deletes nothing unless the cache
  this run just saved is in the list. A failure is a warning, never a red job (a pull request from a fork has a read-only
  token). Failed and cancelled rounds save too, so without this the repository's 10 GB would fill with them and GitHub's
  eviction of the least recently used caches would remove `main`'s first, which every pull request starts from. A
  cancelled job saves but deletes nothing (`if: !cancelled() && ...`): the newer round that cancelled it may be
  downloading the very cache it would delete; that round deletes them all once it has saved its own. `CI result` still
  deletes the older ccaches of the ref at the end of a round, as a net under that.
Every Ninja build of `ci.yml` (and `scripts/build-sniper.sh`, which `release.yml` uses too) runs `cmake --build ... -- -k 0`: after a compile error
Ninja keeps building everything that does not depend on the broken file, so one round lists every error and warning
(`FA_WARNINGS_AS_ERRORS`) instead of the first, and ccache stores every object that did compile for the next round. The
Windows builds (Visual Studio/MSBuild) and the iOS one (Xcode) take no `-k`; the baseline jobs pass it to Linux and macOS only.
A ccache is found by the START of its key (`restore-keys` gives a job the newest cache whose key begins with its prefix), so
no job's prefix may begin another job's key: the GCC job's `ccache-Linux-gcc-` (it was `ccache-Linux-linux-`, which the
Clang jobs' `ccache-Linux-linux-asan-`, `-tsan-`, `-fuzz-` and `-coverage-` also begin with, so the GCC job restored a Clang
cache and compiled everything again). `scripts/check-ci-cache-keys.py` reads every workflow in `.github/workflows`, expands
`runner.os` and the matrices, and fails the `lint` job with the file, line and both jobs when a restore prefix is a proper
prefix of another cache's key; two jobs that share a cache on purpose (`bench` reads the `linux` job's) have equal prefixes
and pass. Run it by hand after editing a key.
`./scripts/ci-local.sh` runs the same kind of checks on your own machine before
you push.

The job `Web (Emscripten, headless Chrome)` installs the Emscripten SDK (cached), builds the web player and the CLI,
exports a game with `factoria export --platform web` and runs `scripts/web-smoke.sh`: the zip check and the export opened
in the runner's Chrome until the player has rendered its first frames. On failure it uploads the screenshot and the
export. It runs when the mobile jobs do. `release.yml` builds the web player once and every release package carries it in
`FactorIA/web/` (`factoria_player.js` and `.wasm`), like the Android libraries in `FactorIA/mobile/`.

The mobile jobs also RUN the app: `ios` boots an iPhone simulator and builds the touch UI test while `ios-build` builds
the app, then runs it (`scripts/ios-smoke.sh`), and `android-emulator` boots an API 34 `x86_64` emulator with KVM,
installs the debug APK that `android-apk` built and starts it (`scripts/android-smoke.sh`). Both assert that the process
stays alive, the player logged `player: 60 frames rendered`, an audio device is open and being pulled, the app survives being sent to the
background and back and renders again, a tap in the middle of the screen reaches the player at the middle of the design
(on iOS a UI test taps, `platforms/ios/touch-test`), nothing crashed and the screenshot shows a picture (Android also
changes the font size), and upload their logs, the screenshot and crash reports as the artifacts `ios-smoke` and
`android-smoke` (look there when one of them fails). The `ios` job asks for the conclusion of `ios-build` while it
waits for the app, so a build that ended without one (failed, or cancelled because GitHub found no macOS runner) fails
the step at once with that message instead of timing out. The Android game also carries a native plugin (built by
`android-apk` with the NDK, outside the game's folder through `FA_CI_PLUGINS`), and the emulator job checks that its
script got the plugin's answers. What they cover and what not is in [MOBILE.md](../MOBILE.md).

### Checking Windows from the Mac

GitHub's Windows job (MSVC) is the one that fails most, and a Mac cannot build with MSVC. If you also have a Windows PC
on the same home network, the Mac can run the native check on it over SSH before a push: the commit checked out on the
Mac is pushed to a repository the check owns on the PC (to the ref `refs/heads/preflight/<branch>`), built in a
worktree of it, and checked with
`scripts\agent-build.ps1 build\agent-preflight -Test -Examples` (Debug build and ctest, then the Release build and the
example games' tests). The output streams to the Mac terminal. The PC needs no clone of FactorIA: the check works in its
own folder `%USERPROFILE%\FactorIA-remote` (a bare repository `repo.git` and the worktree `work`, whose `build\` is kept
between runs) and never touches any other folder. A folder that is a git repository of its own, or holds anything else, is
refused (`--repo` on the Mac, `-RemoteDir` on the PC pick another one).

**Setup, once** (two commands, one on each machine):

1. On the Mac: `scripts/setup-windows-remote.sh`. It creates the key `~/.ssh/factoria_windows` if missing and prints (and
   copies to the clipboard) one PowerShell line that carries `scripts/setup-windows-remote.ps1` and the public key.
2. On the PC: open PowerShell **as administrator** and paste that line (or, from a clone that has the script, run
   `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\setup-windows-remote.ps1 -PublicKey '<key>' [-RemoteDir C:\path\FactorIA-remote]`).
   It installs and starts the OpenSSH Server, opens port 22 on **private networks only** (the rule Windows creates itself
   is turned off; if the home network is set to "Public" it warns and gives the command to change it), makes PowerShell
   the SSH shell, authorizes the key (`C:\ProgramData\ssh\administrators_authorized_keys` with the ACL sshd requires for
   an administrator, `~\.ssh\authorized_keys` otherwise), creates the check's folder, checks git,
   Visual Studio 2022 with the C++ tools and its CMake and Ninja (what `agent-build.ps1` uses), prints what is missing with
   the `winget` / installer command to add it (it installs none of them), and ends by printing the command for the Mac.
   Running it again changes nothing that is already right.
3. On the Mac: run the command the PC printed, `scripts/setup-windows-remote.sh --host <ip> --user <name>` (with `--repo` only if the PC folder is not the default).
   It shows the `Host factoria-windows` block it will write to `~/.ssh/config` and asks first (a rerun replaces the
   block between its marker comments), stores the PC folder in `build/windows-remote.conf` of the main checkout and tests
   the connection (`scripts/ci-remote-windows.sh --check`).

**Every time:**

```bash
scripts/ci-remote-windows.sh              # Windows: Debug build + ctest + Release example games
scripts/ci-remote-windows.sh --no-examples
scripts/ci-remote-windows.sh --wsl        # also scripts/ci-local.sh linux android in the PC's WSL Ubuntu-24.04
```

Exit status: 0 = passed, 1 = a build or a test failed, 77 = the check could not be done or finished, which is not a
failure (`scripts/ci-preflight.sh` records it as a skip): not set up (the message names the setup script), the PC is off
or unreachable, the connection was lost halfway, or the windowed tests were skipped because nobody is logged in.

**The PC is often off, and the script never switches it on or puts it to sleep.** It first checks that the PC answers
(5 s at most). If it does not: in a terminal it asks "Can you switch it on?" and Enter means "I am switching it on, wait
for it" (it waits for sshd, up to `--wait-timeout SECONDS`, default 300, with a note every 15 s), `s` skips (exit 77). Without a
terminal (an AI agent runs it) it exits 77 at once saying so, and the agent asks you; once you say you are switching the
PC on, it runs the script again with `--wait`. While the PC is off, the MinGW cross-compile of the Docker `windows`
job and the Windows file rules that `ctest` turns on (see "Running tests" in [BUILDING_TESTS.md](BUILDING_TESTS.md#running-tests)) still cover part of what the MSVC check finds.
If the connection drops during the run (the PC went to sleep or off, the network failed) the script says which part had
run, that this is not a build or test failure, and exits 77; a dead PC is noticed after about a minute.
Only committed work is tested: uncommitted changes to tracked files are listed in a warning and not sent. The first run
builds everything cold on the PC; later runs reuse `build\agent-preflight` and `build\agent-preflight-release` in the
worktree. Do not start two runs at once (they share that worktree). The logs come back to `build/ci-logs/windows-remote/`.
**Windowed tests.** An SSH session on Windows has no desktop, so a D3D11 swap chain cannot be created there. The tests
that open a window carry the ctest label `window` (`editor_autotest_*`, `cli_player_frames`, `cli_plugin`, which exports
and runs a game) and are left out of the SSH run (`agent-build.ps1 -NoWindowTests`). The script then runs them in the desktop
session of the user logged in on the PC (`scripts\windows-run-interactive.ps1`, `agent-build.ps1 -WindowTestsOnly`): a
one-shot scheduled task with an interactive logon for that user, whose output and exit code come back through the SSH
session, and which is deleted afterwards even if the run is stopped (nothing persistent is left, and power and sleep
settings are not touched). While it runs, windows may flash on that desktop. If nobody is logged in, those tests are
reported as `SKIPPED` (not passed) in the summary and the exit status is 77; the one-line fix is to log in to the PC (it
can be locked afterwards) and run the script again.

**Timing checks in tests.** A test that asserts a speed budget scales it with `fa::test_speed_budget_scale()`
(`fa/core/perf.h`): 4 on an MSVC Debug build, whose unoptimized code ran `script_instrument`'s 1000 ms check in 2.1 s,
and 1 everywhere else, so an optimized build keeps the tight budget.

`--wsl` fetches the commit into its own clone `~/FactorIA-preflight` in WSL (made by the first run, from the PC's
`repo.git`); your `~/FactorIA` there is not used. It needs the WSL set-up of "Continuous integration" above, with
`ANDROID_NDK_HOME` exported in `~/.profile` for the android job. The linux job runs its tests under `xvfb-run` whenever it is
installed (WSL sets `DISPLAY=:0` in an SSH session where no X server answers) and with `LP_NUM_THREADS=4`, like the CI job's
4 vCPUs: llvmpipe's memory grows with its threads, and the examples' `peakMemoryMB` baselines were measured with four.
The perf budget tests (`*_perf`) are left out of the WSL run, as in `scripts/ci-docker.sh`: WSL on the PC measures about
10% more peak memory than GitHub's runner with the same commit, so they would fail without a regression
(`FA_CI_WSL_PERF=1` runs them). The CI job on GitHub's runner checks them, and `scripts/test-all.sh` runs them on this host.

