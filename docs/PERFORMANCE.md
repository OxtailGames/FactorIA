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
| `triangles`, `lights`, `textureMB` | What the renderer drew: triangles of the main pass, the lights (3D lights of the main pass plus Light2D lights, which a frame keeps at most 256 of, the ones in view first: see "2D lights"), and GPU texture memory in MB. Maximum over the run (`lights` is the largest `lights + lights2d` of a frame); 0 without a renderer. Otherwise the same numbers as `game.renderStats()` in a test. |
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
| `triangles`, `lights`, `textureMB` (ratio) | 0.10 | Triangles, lights (3D plus Light2D) and texture memory | Deterministic for a fixed scene. Only checked when the runner's baseline has the field: a baseline written before these fields existed keeps passing. |
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
  `{"strictTime":true}` makes it fail anywhere. A time over its limit is measured up to twice more, and the best time of
  each metric counts: a shared CI machine can run a few times slower for some seconds, while a game that got heavier is
  slow every time. A failure is the error `perf_budget_exceeded`, with every metric's measured value, limit and baseline.
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

## 2D lights

`Light2D` point lights are added up in a light buffer that lit sprites, tiles and shapes read, so the number of lights costs
the pixels the lights cover, not a loop per pixel over every light.

A frame with several cameras (`Camera.viewport`, split screen) draws the world once per camera: culling, sorting, 2D lights and
their light buffer are per camera, so `drawCalls`, `triangles` and `lights` of `game.renderStats()` and `perf.measure` are the sum over
the cameras of the frame, and a four-camera frame costs about four times a one-camera frame. The screen-space items (UI, HUD) are
one more job over the whole screen, and the post effects run once. A game with one full-screen camera is unchanged. Budget two or
three cameras on phones, and give the lights a radius that stays in one view so each camera keeps only the lights that reach it.

What the budget is:

| | Limit | Beyond it |
| --- | --- | --- |
| Cameras drawn per frame (`Camera.viewport`, split screen) | 8: the lowest `depth`s | the others are not drawn, one warning |
| Lights that shade a frame (`lights2d`) | 256: directional first, then the point lights whose radius reaches the camera view | the rest is counted in `lights2dDropped`, one warning per scene |
| Lights that cast shadows (`lights2dShadowed`) | 32, the ones ranked first, and only lights with a solid tile of an `occludesLight` Tilemap within their radius | the others shine through walls, one warning per scene |
| Lights on a lit sprite or tile WITH a normal map | the first 16 of the order above (its shading depends on each light's direction) | the others still light flat surfaces |

The `maxLights` budget of `perf.json` counts `lights + lights2d` of one frame (see above): set it to the lights the game
should ever show, 2D and 3D together. A scene with lit visuals and a point light adds one draw call (the light pass); a
scene without `Light2D` or without lit visuals pays nothing.

What it costs, measured on one Mac (Apple M5, Metal, a Release build, a 1280x720 picture of one lit floor, lights of
radius 200 so each covers about 400x400 pixels, a frame read back to the CPU each time). Timings of this size are
noisy by half a millisecond or more: read the order of magnitude, and measure your own game on your own hardware with
`factoria call perf.measure`:

| Scene | ms per frame over the same floor with no light |
| --- | --- |
| 16 lights | about 0.5 |
| 64 lights | about 1 |
| 256 lights | about 2.5 to 3 |
| 16 to 32 lights that cast shadows, still or moving | about 0.5 more than the same lights without shadows |

That is roughly 0.01 ms per light of this size (it grows with the covered pixels, so a small torch is cheaper and a light
as big as the screen costs more), and roughly 0.03 ms per shadow-casting light. The rays of a shadow are traced on the CPU
(1024 per light); the result is kept while the light, its radius and the tiles around it stay the same, so only a light that
moves, or whose surroundings were edited, pays for its rays again. A still light costs its pixels, not its rays.

Advice for phones, tablets and the web (fill-rate bound GPUs):

- Set `SceneSettings.lightScale` to 0.5: the light buffer has a quarter of the pixels, the light looks a bit softer, and
  it is the cheapest way to keep many lights.
- Give `castShadows` to the few lights that matter (the one the player carries, a bonfire), not to every torch, and keep
  their radius no bigger than needed: a light costs the pixels of its bounding square.
- A smaller `radius` saves pixels; a smaller `intensity` saves nothing. A light entirely off the view is dropped for free.
- Which format the light buffer has: RGBA16F where the GPU can blend it (desktops and recent phones). Where it cannot, RGBA8
  holding half the brightness: the same look, a little coarser, and the lights added at one pixel cannot add up to more than
  2. Where the GPU cannot render to either, the engine shades per pixel with the first 16 lights, as it did before the
  light buffer. `FA_LIGHT_FORMAT=rgba16f|rgba8|none` forces one of them, to try it.

## Path finding on tile maps

`nav.findTilePath` with a `{ width, height, cost }` array converts the whole array on every call (to JSON, to a float
array, and a sweep for the cheapest cell), so one call costs about the size of the map however short the route. Two
tools change that (NAVIGATION.md, "Reusable grids and flow fields"):

- `nav.createGrid` keeps the cost grid natively: a call no longer converts or sweeps, and `grid.setCost` changes a cell.
- `nav.flowField(grid, goals)` searches once from the goals; each walker's next step, `field.stepToward(col, row)`, is a
  table lookup. Walkers heading for the same few goals share one field. After `grid.setCost` the next question redoes the
  search (one pass over the grid), so a field is worth keeping while the grid changes less often than walkers ask.

Measured by the benchmark test in `engine/script/tests/test_nav_tiles_script.cpp` (600 walkers on a 60 x 60 map with walls,
75 ticks, each walker asking for its next step toward one of 6 goals every tick; a Debug build on an Apple M5): the array form about 228 000 ms (measured for 3 ticks and scaled; the test prints it), the kept
grid about 8 200 ms, the flow fields about 160 ms. Tidewater Market, whose roads leave few open cells, measured 5 978 ms for the array form
against 442 ms for its own distance fields before the engine had these; it now uses `nav.flowField`.

## The engine's examples

Each example has a ctest, `example_<name>_perf`, comparing a 300-frame run with `tools/cli/tests/perf/<name>.perf.json`.
An example whose scenes cost differently may add `<name>-<suffix>.perf.json` files (each with its own `scene`): every
`<name>.perf.json` and `<name>-*.perf.json` becomes the ctest `example_<file name>_perf` (not `<name>*`, which would catch
another example with the same prefix).
`perf_regression_detected` proves that the check fails: it uses a baseline lowered far below what the game costs and
expects `perf_budget_exceeded`. After a change that makes an example heavier on purpose, refresh its entry on each runner
with `factoria call perf.baseline` (see the file's `runners`) in the same PR.

Not covered yet: the web and Android players report memory and time with the limits above but have no CI baseline.

## Loading

A play session (the editor's Play, `play.auto`) also measures how the game loads, and `play.report` returns it as `loading`:

```json
"loading": {
  "timeToFirstFrameMs": 412.3,
  "scenes": [ { "scene": "scenes/main.scene.json", "loadMs": 380.1, "files": 57, "bytes": 18234567 } ],
  "slowestAssets": [ { "kind": "texture", "path": "assets/sky.png", "bytes": 4194304, "readMs": 3.2, "decodeMs": 41.7 } ],
  "reads": { "count": 61, "bytes": 18301234, "fromPack": 0, "packStoredBytes": 0 },
  "note": "Times are this machine's, rounded to 0.1 ms: ..."
}
```

- `timeToFirstFrameMs`: from the start of the session to the end of its first frame.
- `scenes`: each scene loaded during the session, with the project files first read while it was the current scene and
  their bytes; its `loadMs` runs from the start of its load to the end of the first frame after it.
- `slowestAssets` (at most 10): the textures, meshes, sounds and fonts that took longest, split into the time spent
  reading the file (`readMs`) and the rest of the load (`decodeMs`: decoding, uploading, building). A large `decodeMs` on a
  PNG says to ship it as KTX2 ([EXPORTING.md](EXPORTING.md)); a large `readMs` says the file is big or the drive slow.
- `reads`: the project files read (an absolute path is not counted), how many came out of a mounted `game.pak`, and what
  those took in the pack (compressed).

The times are this machine's and are rounded: compare two runs on one machine, never pass or fail on them (no test does). A
time not reached yet (the session ended before its first frame) is `null`.

The same sessions, and `factoria run`, record which files each scene reads first, in that order, into
`.factoria/cache/load-order.json`; a `--release` export writes `game.pak` in that order, so a scene's files lie next to each
other on the drive and a load reads mostly forward ([EXPORTING.md](EXPORTING.md#compression-and-pack-order)). A `factoria run`
or `play.auto` (a fresh engine that reads every file it needs itself) sets a scene's order; an editor Play only adds the
files it was missing. Recording costs one short lock and a set lookup per file read while a session runs (nothing when none
does); the file is written when the session ends, under the project's lock, and the editor writes it on a background
thread so Stop never waits on the disk. An exported game records nothing.

## Background loading

`scene.load` reads, decodes and uploads a scene's files before the frame goes on, so a big level freezes the game for a
moment. Three calls do that work in the background instead, while frames keep running:

- `scene.load(path, props, { async: true })` (the command `scene.load {"path", "async": true}`) loads the scene in the
  background and switches to it at the end of the frame its files are ready. The new scene starts exactly as after a sync
  load: the same world, the same `game.sceneProps()`, the same files in the same first-use order.
- `scene.preload(path)` (command `scene.preload {"path"}`) reads a scene's files ahead; a later `scene.load` of that scene
  reads nothing from the disk.
- `assets.preload(paths)` (command `assets.preload {"paths"}`) does the same for a list of files: textures, models (a
  `.gltf` brings its `.bin` and images), fonts and sounds go into the engine's caches, any other file stays in memory.

Each answers at once with a handle in scripts (`progress` 0..1 that never goes down, `done`, `files`/`total`, `bytes`,
`uploadedBytes`, `error`, `cancelled`, `cancel()`, `promise`; docs/SCRIPTING.md) or a `loadId` for tools: `load.status
{"id"}` gives `{state, progress, items {done, total}, bytes, uploadedBytes, error?, hint?}` and `load.cancel {"id"}` stops
it. A missing file is an error at once, with "did you mean" and a hint; a file that cannot be read or decoded fails the
load with its message (an async scene load then does not switch). A newer `scene.load` (sync or async) or `scene.reload`
cancels an async scene load that is still loading: the last request wins.

How the work is split:

- **One IO thread** for the whole process reads the files (through `fa::fs`: a `game.pak`, an APK or a loose file alike)
  and **jobs** of the job pool decode them: PNG and KTX2/Basis to pixels, glTF to vertices, a sound to samples, a font file to
  a parsed face; the first item parses the scene's JSON to find the files it names. The **main thread** only takes what is finished and uploads it to the GPU or adopts it into the
  audio cache. Without worker threads (`runtime.jobThreads` 0 or `"inline"`, the web build) there is no IO thread: the main
  thread reads and decodes a share each frame.
- The work is counted in **items**: the first reads the scene (or the listed files) and everything it names that is text
  (prefabs, materials, scripts and their imports, `.gltf` files), then one item per binary file, models last. `progress`
  is items done over items, exact from the second frame on.
- **Per frame**, two budgets:
  - **exact** (tests, headless runs, `play.auto`, the editor, replays): exactly 4 items per frame, waiting for each that
    is not ready, so the frames a load takes and every `progress` value are the same on every machine and with any
    number of worker threads;
  - **timed** (a game with a window): only the items that are ready, in the same fixed order, until the frame has spent
    `runtime.loadBudgetMs` milliseconds (default 4) or uploaded `runtime.uploadBudgetMB` megabytes to the GPU (default 16).
    A frame never waits for a file. With worker threads it may take no item at all; without, it takes at least one. A
    texture bigger than the upload budget still goes up whole, in one frame.

```json
"runtime": { "loadBudgetMs": 4, "uploadBudgetMB": 16 }
```

- **Replays**: a recording of a timed run keeps how many items each frame took (`"loadUnits"` in the frame's entry), and
  its replay takes exactly those, so a session recorded in a window replays the same frames headless.
- **Memory**: the files of a running load are held in memory until a cache took what they hold. Those still held when it
  finishes (the scene file, scripts, prefabs, files no cache decodes) stay through the first scene load after it finished
  and are dropped at the second (or by `cancel()`/`release()`/`load.cancel`), so a preload costs about one scene's files
  beyond the one in use. `load.status {}` shows `warmBytes`, what is held now.
- **Load trace**: the files a background load reads ahead count in `play.report`'s `reads` when they are read, and enter a
  scene's first-use order (what `factoria export` packs `game.pak` by) only when the game first uses them, so an async load
  records the same order as a sync one. An async scene load's entry in `loading.scenes` has `"async": true`, `readyMs`
  (from the request to the frame the scene started) and `loadMs` from the request to the end of the scene's first frame; a
  cancelled one says `"cancelled": true`.

Cost: nothing while no background load runs (no thread, no work in the frame; frames, `game.state_hash` and `play.report`
stay as they were). While one runs: the IO thread and the decode jobs on the worker threads, and on the main thread at most
`loadBudgetMs` per frame (plus one item) in a window, or the 4 items in exact mode. A cancelled load throws away what it
decoded; a decode already running finishes on its worker and is dropped.

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
  threads: [{name, jobMsAvg, jobMsMax, busyPct, jobsPerFrame,  // "main", "worker 1".., "other"
             jobs: [{name, avgMs, maxMs, callsPerFrame}]}],    // that thread's 10 slowest job names
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
- `threads` has one entry per thread of the job pool (main first, then every worker, idle ones too; `other` when a
  thread outside the pool ran jobs): the time it spent in jobs per frame and as a share of the frame (`busyPct`), and its
  slowest jobs by the name they were submitted with (a `parallel_for` chunk counts as one job). Which thread ran a job
  changes from run to run; the results do not (see "Job threads" below). A game whose engine work uses no jobs shows
  zeros there.
- Measuring has a small cost of its own (a few microseconds per behaviour callback); with it off there is none.

## Job threads

The engine hands pieces of its work to a pool of worker threads (docs/ARCHITECTURE.md, "Jobs and threads"). How many is
the `runtime` setting of factoria.json:

```json
"runtime": { "jobThreads": "auto" }
```

- `"auto"` (the default): hardware threads - 1, at most 8 on desktop and 4 on phones (their slow cores count too, and
  the OS, the GPU driver and audio need room). The web build has no threads: 0 there.
- A number 0..32, written as a whole JSON number (`"4"` in quotes and `4.0` are refused with a hint): that many workers
  besides the main thread. `0` runs every job on the main thread, when something waits for it or at the end of the
  frame: the cheapest setting for a game that is light anyway.
- `"inline"`: every job runs at once on the thread that submits it, in submission order. For debugging only: a job's
  crash then has the plain call stack of its caller.
- The words are exact in the file: `"Inline"` or `" auto"` is refused with the spelling to use.
- The `FA_JOB_THREADS` environment variable (the same values, in any case, spaces around them ignored) overrides the
  file for one run:
  `FA_JOB_THREADS=0 factoria run`, `FA_JOB_THREADS=inline factoria test`. A bad value is reported at start and the
  file's setting is used; a bad value in the file stops the start with an error at `/runtime/jobThreads`.

Threads never change what the game computes. `factoria call game.state_hash` gives one hash of the whole simulation
state; the same replay gives the same hash with any setting (`{"perEntity":true}` lists one hash per entity to find which
one differs). `factoria call jobs.info` says what runs now: workers, mode, the setting and where it came from, the jobs
of the last frame, how busy each thread was, the threads waiting now (`waiting`) and this engine's unfinished jobs
(`enginePending`).

Cost: idle workers sleep and use no CPU. A job costs about one allocation and one lock, so the engine only splits work
big enough to gain from it. Each worker has a stack and a few kilobytes of its own: on a phone, fewer workers save a
little memory and battery.
