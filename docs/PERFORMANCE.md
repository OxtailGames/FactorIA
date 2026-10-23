# Performance budgets

A game can get slower or heavier without anyone noticing. FactorIA measures what a run costs and fails a check when it
goes past a budget you committed. The engine does this for its own examples in CI; a game does it with the same three
commands.

## What is measured

`factoria run --headless --json` has a `perf` object in its report:

| Field | Meaning |
| --- | --- |
| `cpuMsAvg`, `cpuMsP95`, `cpuMsMax` | CPU time the engine used per frame, in ms. It is the CPU time of the process (all threads, so GPU driver threads count), not the wall clock: a busy machine moves it less. |
| `cpuClock` | `process`, or `wall` on the web, where the browser gives no CPU time (the web numbers are wall-clock and noisier). |
| `peakMemoryMB` | Peak resident memory of the process. Windows: peak working set. Linux, Android, macOS: `ru_maxrss`. Web: the size of the wasm heap (it never shrinks). |
| `drawCalls`, `entities` | Maximum over the run. |
| `triangles`, `lights`, `textureMB` | What the renderer drew: triangles and lights of the main pass, and GPU texture memory in MB. Maximum over the run; 0 without a renderer. The same numbers as `game.renderStats()` in a test. |
| `graphics` | The GPU used, `none` when there is no renderer (then `drawCalls` is 0). |

`factoria call perf.measure` runs a project the same way (drawing every frame with the GPU renderer) and returns this as a
`sample` together with the `runner` id.

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
  "tolerance": { "cpuAvg": 1.0, "memory": 0.1 },
  "runners": {
    "linux-gcc-llvmpipe": { "frames": 300, "cpuMsAvg": 4.1, "cpuMsP95": 6.6, "cpuMsMax": 34.3,
                            "peakMemoryMB": 76.8, "drawCalls": 2, "entities": 45, "triangles": 1200, "lights": 2,
                            "textureMB": 3.5, "graphics": "..." }
  }
}
```

`frames` (default 300), `scene` and `input` (a project-relative input replay, see [CLI.md](CLI.md)) say what is run; use
`input` to reach the heavy part of the game, because a game waiting on its title menu costs little.

A limit is `max(baseline * (1 + ratio), baseline + slack)`; the slack keeps a tiny baseline from failing on noise.

| Tolerance key | Default | Applies to | Why |
| --- | --- | --- | --- |
| `cpuAvg`, `cpuP95` (ratio) | 1.0, 1.5 | CPU time per frame, average and 95th percentile | Measured: the same run varies by about 5% on one machine, but CI runners are shared and differ by up to 2x between jobs. The budget catches a game that becomes 2-3x slower, not 20%. |
| `memory` (ratio) | 0.10 | Peak memory | Repeated runs differ by about 1-2%. |
| `drawCalls`, `entities` (ratio) | 0.10 | Max draw calls / entities | Deterministic for a fixed scene and input. |
| `triangles`, `lights`, `textureMB` (ratio) | 0.10 | Triangles, lights and texture memory | Deterministic for a fixed scene. Only checked when the runner's baseline has the field: a baseline written before these fields existed keeps passing. |
| `cpuSlackMs`, `memorySlackMB`, `textureSlackMB`, `countSlack` | 1, 8, 1, 2 | The slack of each kind of limit | |

`cpuMsMax` is recorded but not checked: one slow frame is mostly the machine.

## The commands

All three work on the project they run in (`--project DIR`) and are also MCP tools.

- `factoria call perf.baseline` measures (3 runs, median time) and writes this runner's entry in `perf.json` (or `{"file":
  "path"}`), keeping the other runners' entries. Run it once per kind of machine, and again when the game got heavier on
  purpose. `{"frames":600,"input":"replays/play.json","tolerance":{"memory":0.2}}` also sets the file's run settings and
  tolerances.
- `factoria call perf.check` measures with the settings of the file and compares. Memory, draw calls and entities past
  their limit always fail. A time past its limit fails when the `CI` environment variable is set (GitHub Actions sets it)
  and only warns (`status: "warn"`) elsewhere, because a developer machine can be busy while the full test suite runs;
  `{"strictTime":true}` makes it fail anywhere. A time over its limit is measured a second time before it counts. A
  failure is the error `perf_budget_exceeded`, with every metric's measured value, limit and baseline.
- `factoria call perf.measure` just measures.
- **Budgets for what a scene draws.** Besides the baseline, `perf.json` may hold absolute caps that fail whatever the
  baseline says, on any runner and also where there is no baseline yet:
  `"budgets": { "maxTriangles": 200000, "maxLights": 8, "maxTextureMB": 120, "maxDrawCalls": 300, "maxEntities": 600 }`.
  `perf.check` takes the same object as its `budgets` argument (its keys win over the file's). A typo in a key is an
  error with a "did you mean". The failure names the cap: `maxTriangles 26 > budget 25`.

Peak memory is the whole process's, so run the check the same way each time; the engine's own tests use
`factoria call --project <game> perf.check @args.json` (`factoria call` gives `perf.*` no GPU of its own; the engine the command starts inside has it).
A process has one graphics device, so a `perf.*` command called where one is already in use (the editor's Console or AI, a
window) fails with the error `gpu_busy` and says so, instead of crashing: run it from a terminal.

### Setting a budget for your game

1. Make a replay that plays the heaviest part (the editor records one; see CLI.md `--input`).
2. `factoria call perf.baseline '{"input":"replays/play.json"}'` and commit `perf.json`.
3. In your CI, after `factoria test`: `factoria call perf.check`. Add the baseline of the CI runner: the first run prints
   `baselineEntry`; paste it under `runners` (or run `perf.baseline` on that machine).

## The engine's examples

Each example has a ctest, `example_<name>_perf`, comparing a 300-frame run with `tools/cli/tests/perf/<name>.perf.json`.
`perf_regression_detected` proves that the check fails: it uses a baseline lowered far below what the game costs and
expects `perf_budget_exceeded`. After a change that makes an example heavier on purpose, refresh its entry on each runner
with `factoria call perf.baseline` (see the file's `runners`) in the same PR.

Not covered yet: the web and Android players report memory and time with the limits above but have no CI baseline.

## Finding what is slow: the profiler

A budget says THAT the game got slower. The profiler says WHERE the time goes. It measures the CPU time of every engine
system and of every script behaviour class, the GPU time of drawing, and memory. It is off unless you ask (when off it
costs one branch per probe) and it only measures: `game.state`, replays, saves and screenshots are byte-identical with it
on or off.

Three ways to read it, all with the same `profile` section:

- `factoria call perf.profile '{"frames":300,"warmup":30,"input":"replays/play.json"}'` runs the game headless with the
  profiler on. (Inside the editor it answers `gpu_busy`: the editor already holds the graphics device. Use View > Profiler
  there, or `play.report`'s `profile`.)
- `play.report` of an editor play session has a `profile` section covering the whole session (Play .. Stop).
- The editor's **View > Profiler** panel shows it live while the game plays (EDITOR.md).

```
profile: {
  frames, clock: "wall",
  frameMs: {avg, p95, max},                       // engine time of one frame
  systems: {platform, physics, scriptsFixedUpdate, animation, scriptsEvents, ui, scriptsUpdate, audio,
            scriptsLateUpdate, localization, render, endOfFrame: {avgMs, p95Ms, maxMs}},
  behaviours: [{class, path, avgMs, maxMs, callsPerFrame}],   // slowest first
  gpu: {avgMs, p95Ms, maxMs, samples, reason},                // numbers, or null + reason
  memory: {start, end, peak: {processMB, jsHeapMB, textureMB, audioDecodedMB, entities}}
}
```

Reading it:

- Times are wall-clock milliseconds of the engine's own work and vary a little between runs: compare the order and the
  big gaps, not the decimals. `p95Ms` is over the last 20000 frames.
- A system includes what it runs: `scriptsUpdate` holds every `onUpdate` and the timers. A behaviour class's `avgMs` is per
  frame (a class that runs on one frame of four with 8 ms shows 2 ms) and covers every callback of it (`onStart`,
  `onUpdate`, `onFixedUpdate`, `onLateUpdate`, collision and trigger handlers, `onEvent`, `onEnable`/`onDisable`/`onDestroy`),
  without the time of other behaviours it triggered. Timers, `world.on` handlers and promise jobs belong to no behaviour:
  they are the class `(timers, events and promises)`. `callsPerFrame` above 1 means fixed steps or many handlers.
- Start with `frameMs`, then the biggest `systems`, then the first `behaviours`. A game that is slow in `render` with a small
  `gpu` time spends it recording many separate draws (see `drawCalls` in `play.report`); a big `gpu` time means the pictures
  are heavy (resolution, bloom, lights, overdraw).
- `gpu` is the time the GPU took to draw the world (not the final copy to the window). It is read from timer queries that
  come back a few frames late and are never waited for, so it describes recent frames, not the exact one. It is measured on
  Direct3D 11 (Windows) and desktop OpenGL (Linux). Everywhere else the numbers are `null` and `reason` says why: Metal
  (macOS, iOS) exposes no GPU times through the graphics layer the engine uses, and OpenGL ES 3 and WebGL2 (Android, web)
  would need the `EXT_disjoint_timer_query` extension, which is not used. A run with no GPU at all also gives `null`.
- `memory` samples the process (resident memory now and at its peak), the JavaScript heap, texture memory, decoded audio
  and the entity count, at the start, the end and the peak of the run: a number that only grows over a long session is a leak.
- Measuring has a small cost of its own (a few microseconds per behaviour callback); with it off there is none.
