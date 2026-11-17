# Performance budgets

A game can get slower or heavier without anyone noticing. FactorIA measures what a run costs and fails a check when it
goes past a budget you committed. The engine does this for its own examples in CI; a game does it with the same three
commands.

## Pages

- [Budgets by area](performance/PERFORMANCE_AREAS.md): What each budget covers: 2D lights, render interpolation, path finding, startup, loading, script budgets, background loading.
- [Profiler and job threads](performance/PERFORMANCE_PROFILING.md): Finding what is slow: the profiler and the job threads.
- [Microbenchmarks](performance/PERFORMANCE_BENCH.md): Microbenchmarks (fa_bench).

## What is measured

`factoria run --headless --json` has a `perf` object in its report:

| Field | Meaning |
| --- | --- |
| `cpuMsAvg`, `cpuMsMedian`, `cpuMsP95`, `cpuMsMax` | CPU time the engine used per frame, in ms: the average, the median frame, the 95th percentile (nearest rank) and the slowest frame. It is the CPU time of the process (all threads, so GPU driver threads count), not the wall clock: a busy machine moves it less. `perf.check` gates the median and the p95; the average and the maximum are only reported, because one slow frame decides them. |
| `slowestFrames` | The five slowest frames of the run, `[{frame, ms}]`, slowest first. The first frames are usually there: assets and shaders load in them. `perf.check` names them in its message, so a spike is seen, not hidden in a number. |
| `cpuClock` | `process`, or `wall` on the web, where the browser gives no CPU time (the web numbers are wall-clock and noisier). |
| `peakMemoryMB` | Peak resident memory of the process. Windows: peak working set. Linux, Android, macOS: `ru_maxrss`. Web: the size of the wasm heap (it never shrinks). |
| `drawCalls`, `entities` | Maximum over the run. |
| `triangles`, `lights`, `textureMB` | What the renderer drew: triangles of the main pass, the lights (3D lights of the main pass plus Light2D lights, which a frame keeps at most 256 of, the ones in view first: see "2D lights"), and GPU texture memory in MB. Maximum over the run (`lights` is the largest `lights + lights2d` of a frame); 0 without a renderer. Otherwise the same numbers as `game.renderStats()` in a test. |
| `startupMs` | CPU milliseconds from the moment the engine starts reading the game's files to the end of its first frame (scenes, scripts, textures, shader programs). The CPU time of the process, so a busy machine moves it less than the clock; the window and the first presented frame are not in it. See "Startup". |
| `graphics` | The GPU used, `none` when there is no renderer (then `drawCalls` is 0). |

`factoria call perf.measure` runs a project the same way (drawing every frame with the GPU renderer) and returns this as a
`sample` together with the `runner` id. The sample also reports `audioDecodedMB` (decoded sounds, streaming buffers and music)
and `musicMB` (the decoded music alone), the max over the run (`musicMB` after every frame; `audioDecodedMB` every 8th frame and at
the end, so a spike of a few frames in between can be missed); in MiB (1048576 bytes); they are never gated and never written to a baseline.

## Runners and baselines

A baseline is only valid for the kind of machine and build it was measured on, so budget files key their baselines by a
runner id, `<os>-<compiler>-<renderer>`, with `-debug` at the end for a Debug build:

| Runner id | Where |
| --- | --- |
| `linux-gcc-llvmpipe` | Linux, GCC, Mesa llvmpipe (software GL) |
| `windows-msvc-d3d11-warp` | Windows, MSVC, D3D11 WARP (software): a CI runner has no graphics card, so its adapter is the Microsoft Basic Render Driver, which is WARP. On a PC with a card the id is `windows-msvc-d3d11`; `FACTORIA_D3D11_WARP=1` makes a release build render with WARP and use this id, with numbers close to a runner's but not equal (below) |
| `macos-clang-metal-paravirtual` | macOS, Apple clang, Metal on the Apple Paravirtual device: the GPU of a macOS virtual machine, which is what GitHub's macOS runners are |
| `macos-clang-metal` | macOS, Apple clang, Metal on a Mac's own GPU (Apple M1, M5...) |
| `macos-clang-metal-debug` (any id + `-debug`) | The same machine with a Debug build (CMake `Debug`: no `NDEBUG`) |

The GPU and the build each move peak memory past the tolerance. The `block-push` example's peak memory: 30 MB on
GitHub's macOS runner (paravirtual GPU, release build), 36 MB on an M5 MacBook with the same release build, 44 MB with a
Debug build there. Unoptimized code is bigger and slower, so a `-debug` id never meets a release baseline, and the
engine's CI builds release.

Two machines of the same kind still differ: GitHub's Linux runner uses about 25 MB more than WSL on the same code, and
Windows WARP on a PC and on a runner differ by up to 15 MB either way. So a runner's entry is measured on that runner,
and the engine's own entries come from its CI runners' output (a job with no entry prints it, see below). A developer's
own machine (a Mac's own GPU, a PC with a graphics card, any Debug build) has no entry in the engine's budget files, so
its `example_*_perf` tests pass with `no_baseline`; CI enforces the budgets.
Set `FACTORIA_PERF_RUNNER=name` to use your own id (a build machine of your own). A runner with no entry in a budget file is
not an error: the check passes with status `no_baseline`, and its result carries `baselineEntry`, the exact JSON to add
under `runners`. `{"requireBaseline":true}` makes it fail instead (error `perf_no_baseline`, with the same entry), so a CI
job cannot pass without checking anything; the engine's own CI does this.

## Budget file

```json
{
  "format": "factoria.perf/1",
  "frames": 300,
  "input": "replays/play.json",
  "tolerance": { "cpuMedian": 1.0, "memory": 0.1 },
  "runners": {
    "linux-gcc-llvmpipe": { "frames": 300, "cpuMsAvg": 4.1, "cpuMsMedian": 3.9, "cpuMsP95": 6.6, "cpuMsMax": 34.3,
                            "peakMemoryMB": 76.8, "drawCalls": 2, "entities": 45, "triangles": 1200, "lights": 2,
                            "textureMB": 3.5, "graphics": "..." }
  }
}
```

`frames` (default 300), `scene` and `input` (a project-relative input replay, see [CLI.md](CLI.md)) say what is run; use
`input` to reach the heavy part of the game, because a game waiting on its title menu costs little.

### The band

A metric is one of two kinds, and the check treats them differently:

- **Counters** (`drawCalls`, `entities`, `triangles`, `lights`): the same on every run of a fixed scene and input on a
  runner, so they are enforced **exactly**. One more than the baseline fails, on any machine and also outside CI; fewer
  passes (refresh the baseline to tighten it). A counter never needs slack: if it moved, the scene changed.
- **Noise** (the median and p95 frame time, peak memory): a shared CI runner runs a few times slower for seconds, and
  memory differs by tens of MB between two runners of the same kind. These have **two limits**:
  - the **warn limit**, `max(baseline * (1 + ratio), baseline + slack)`: past it the status is `warn` and the message
    lists the metric under "Inside the warning band". It never fails the check and needs no baseline refresh;
  - the **fail limit**, `max(baseline * (1 + failRatio), baseline + failSlack)`, the edge of the band: only past it does
    the check fail (a time only when `CI` is set or `strictTime` is true, memory always).

| Metric | Warn limit | Fail limit |
| --- | --- | --- |
| `cpuMsMedian` | `max(baseline * 2, baseline + 1 ms)` | `max(baseline * 6, baseline + 10 ms)` |
| `cpuMsP95` | `max(baseline * 2.5, baseline + 1 ms)` | `max(baseline * 6, baseline + 10 ms)` |
| `peakMemoryMB` | `max(baseline * 1.1, baseline + 8 MB)` | `max(baseline * 1.5, baseline + 32 MB)` |

Why the band is this wide: it has to cover what GitHub's macOS runner measured. `gem-roller`'s p95 was 1.745 ms against
a baseline of 0.464 ms (3.8 times: warn, not fail; under a millisecond a ratio alone is noise, which is what the absolute
slack is for). `kindlewatch` had one frame of 1924 ms that moved its average from 4 to 9.3 ms while its median and p95 stayed
where they were, which is why the average and the maximum are not gated. A game that really got slower or heavier is
several times over its baseline, not 3.8: the check still finds it, and a baseline is never refreshed only to make a
check pass. The re-measures (a time past its fail limit is measured twice more and the best value of each metric counts)
stay as a second net, but it is the band that absorbs the noise, not the retry.

What the band does not fail, on purpose: a time that is **3 times its baseline for good** (a median of 5 ms that
becomes 15 ms) or a memory leak of **about 30 MB** (the fail limit of a time is 6 times the baseline or 10 ms more; that
of memory 1.5 times or 32 MB more) only give `warn`: the check passes and exits 0. We do not narrow the fail limits because
CI already has false reds from noise (the p95 of PR 210 is described in feedback/ROADMAP.md, near M100.10), and a check
that cries wolf is switched off. So a `warn` is read, not ignored: CI lists every `_perf` test that passed inside the
warning band, with the metric, the measured value and the limit, as a `::warning::` annotation and in the job summary
(step "Performance warnings" of the Linux, Windows and macOS jobs, `scripts/ci-perf-warnings.sh`, which reads ctest's
`Testing/Temporary/LastTest.log`; locally `ctest -R perf -V` or `factoria call perf.check` show it). A metric that warns on
every run is a game that got slower: find why, or refresh its baseline on purpose.

A baseline written before `cpuMsMedian` existed has no median: its average stands in for it, which is never lower than
the median, so the comparison is only more lenient. Texture memory keeps a small band (`max(baseline * 1.1, baseline + 1
MB)`, a failing limit, because it is computed from the sizes of the textures); `startupMs` keeps its single wide limit.

A baseline entry with `"provisional": true` is an estimate (numbers written by hand for a runner nobody has measured
yet): only the counters are enforced, and the message says so. Time, memory, texture memory and start-up are not
compared. `perf.baseline` writes the measured numbers without the flag, so refreshing an entry makes it final. The
absolute caps (`budgets`, below) apply to a provisional entry too: they are the game's own limits, not an estimate.

| Tolerance key | Default | Applies to |
| --- | --- | --- |
| `cpuMedian`, `cpuP95` (ratio) | 1.0, 1.5 | The warn limit of the median and p95 frame time (`cpuAvg` is the old name of `cpuMedian` and is still read) |
| `cpuFail` (ratio), `cpuFailSlackMs` | 5.0, 10 | The fail limit of both |
| `cpuSlackMs` | 1 | The slack of their warn limit |
| `memory` (ratio), `memorySlackMB` | 0.10, 8 | The warn limit of peak memory |
| `memoryFail` (ratio), `memoryFailSlackMB` | 0.5, 32 | The fail limit of peak memory |
| `drawCalls`, `entities`, `triangles`, `lights` (ratio), `countSlack` | 0, 0 | The counters: exact. Raise them only for a scene that is not deterministic. `triangles` and `lights` are only checked when the baseline has the field |
| `textureMB` (ratio), `textureSlackMB` | 0.10, 1 | Texture memory (only when the baseline has the field) |
| `startup` (ratio), `startupSlackMs` | 2.0, 500 | `startupMs`, the CPU time to the first frame: start-up reads files and makes GPU programs, so it differs a lot between a cold and a warm disk and between drivers (only when the baseline has the field) |

## The commands

All three work on the project they run in (`--project DIR`) and are also MCP tools.

- `factoria call perf.baseline` measures (3 runs, median time) and writes this runner's entry in `perf.json` (or `{"file":
  "path"}`), keeping the other runners' entries. Run it once per kind of machine, and again when the game got heavier on
  purpose. `{"frames":600,"input":"replays/play.json","tolerance":{"memory":0.2}}` also sets the file's run settings and
  tolerances.
- `factoria call perf.check` measures with the settings of the file and compares (see "The band"). A counter past its
  baseline always fails, and so does memory past its fail limit. A time past its fail limit fails when the `CI`
  environment variable is set (GitHub Actions sets it) and only warns elsewhere, because a developer machine can be busy
  while the full test suite runs; `{"strictTime":true}` makes it fail anywhere. A time past its fail limit is measured up
  to twice more, and the best value of each metric counts. Inside the band the status is `warn` (`"status": "warn"`). A
  failure is the error `perf_budget_exceeded`, with every metric's measured value, limits and baseline, and the slowest
  frames of the run. Each row of `rows` has `limit` (where it fails) and, for the noise metrics, `warnLimit` and `warned`.
- `factoria call perf.measure` just measures. Its `sample` has the median and the `slowestFrames`.
- **Budgets for what a scene draws.** Besides the baseline, `perf.json` may hold absolute caps that fail whatever the
  baseline says, on any runner and also where there is no baseline yet:
  `"budgets": { "maxTriangles": 200000, "maxLights": 8, "maxTextureMB": 120, "maxDrawCalls": 300, "maxEntities": 600, "maxStartupMs": 5000 }`.
  `perf.check` takes the same object as its `budgets` argument (its keys win over the file's). A typo in a key is an
  error with a "did you mean". The failure names the cap: `maxTriangles 26 > budget 25`.
- **`perf.startup`: the start-up budget.** `maxStartupMs` is the most CPU milliseconds the game may take from reading its
  files to its first frame (`startupMs` of the sample). The three templates (`2d-empty`, `2d-platformer`, `3d-empty`) ship a
  `perf.json` with `"maxStartupMs": 5000`: about a hundred times what they cost on a developer machine, so only a game that
  became slow trips it, never a busy CI machine. It is a time, so it fails when `CI` is set and warns elsewhere (see above);
  the message says what to do ("Startup").

Peak memory is the whole process's, so run the check the same way each time; the engine's own tests use
`factoria call --project <game> perf.check @args.json` (`factoria call` gives `perf.*` no GPU of its own; the engine the command starts inside has it).
A process has one graphics device, so a `perf.*` command called where one is already in use (the editor's Console or AI, a
window) fails with the error `gpu_busy` and says so, instead of crashing: run it from a terminal.

### Baselines from CI

The engine's baselines come from the runners themselves. Run the "CI" workflow by hand (GitHub, Actions, Run workflow,
tick `perfBaselines`). GitHub offers "Run workflow" (and the `perfBaselines` tick) only for a workflow file that is on the
default branch, so the job cannot be run from a branch that adds or changes it until that branch has merged; after the
merge it runs on any branch you pick, with that branch's `ci.yml`. Only the "Perf baselines" job runs, on a Linux, a Windows and a macOS runner. Each one builds a
release `factoria`, runs `scripts/perf-baselines.sh` (`perf.baseline` for every file of `tools/cli/tests/perf`, 3 runs
each) and uploads the files as the artifact `perf-baselines-<os>`. Copy `runners.<runner id>` of each file into the file of
the same name in `tools/cli/tests/perf/`, which makes the entry final (not `provisional`). The script runs on any
machine: `scripts/perf-baselines.sh build/dev/tools/cli/factoria out/` leaves the entries of this one in `out/`.

### Setting a budget for your game

1. Make a replay that plays the heaviest part (the editor records one; see CLI.md `--input`).
2. `factoria call perf.baseline '{"input":"replays/play.json"}'` and commit `perf.json`.
3. In your CI, after `factoria test`: `factoria call perf.check`. Add the baseline of the CI runner: the first run prints
   `baselineEntry`; paste it under `runners` (or run `perf.baseline` on that machine).
