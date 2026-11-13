# Performance budgets

A game can get slower or heavier without anyone noticing. FactorIA measures what a run costs and fails a check when it
goes past a budget you committed. The engine does this for its own examples in CI; a game does it with the same three
commands.

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

## Startup

What a player does between the click on its icon and a game you can play, in order (design in
[ARCHITECTURE.md](ARCHITECTURE.md#start-up-order-and-the-shader-cache)):

1. **The first frame is presented before any game file is read.** The window and the graphics context come first; the very
   first window frame shows a cleared frame (black, the letterbox colour) and returns, so the window is on screen at once
   instead of nothing. Only the next frame reads the game (scenes, scripts, textures, audio headers). It is on by default
   and cannot be turned off; it applies to the player and to a windowed `factoria run`. The game cannot tell: its first
   frame is the same frame 0, and `state_hash`, recordings, replays and goldens are identical with or without it.
2. **The GPU pipelines the first scene draws with are made in the background of the window**, as many groups per window
   frame as fit in about 8 ms (each frame still shows the cleared frame), so the first game frame does not stall on them. A frame that needs a pipeline
   the warm-up has not made yet makes it then, as before: the picture never depends on the warm-up.
3. **The game runs.** Its first frame uses at most 1/60 s of game time even when the start took longer.

The numbers, from the start of the process (`play.report` `loading.startup`, the headless report's `startup`, and one log
line `startup: first frame presented at ... ms, game ready at ... ms`):

| Field | Meaning |
| --- | --- |
| `firstPresentMs` | When the first frame (a cleared one) was presented. `null` with no window (a headless run, `perf.measure`, tests), where nothing is presented. |
| `firstGameFrameMs` | When the first frame of the GAME was done. The two are separate on purpose: the first is how long the player stares at nothing, the second how long until the game is playable. |
| `windowReadyMs`, `initMs`, `warmupMs` | Window and context ready; reading the game; making the first scene's pipelines. |
| `startupCpuMs` | CPU time from reading the files to the first game frame. The `startupMs` of `perf.*`, what `maxStartupMs` budgets. |
| `diskReadsAtFirstPresent`, `diskReadsAtFirstGameFrame` | Files read from disk by then. The first is 0 or the player's own few files: the game's files are read after the first frame. |
| `gpu` | The renderer's part: `backend`, `cache` (the mode: `d3d11-dxbc` where the engine keeps a shader cache, `none` elsewhere), `programs` and `createMs` (shader programs made and the wall time that took), the cache counters `stages`, `cacheHits`, `cacheMisses`, `cacheStale`, `cacheDamaged`, `cacheStored`, `cacheStoreFailed` (present where the engine has a cache), `pipelinesWarmed`, `warmMs`, `groupsLeft`. |

`loading.startup` is there for a session that starts its own engine (`factoria run`, `play.auto`, the player); a Play inside the
editor has none, because the editor's engine started once with the editor and its start-up numbers say nothing about the session.
`startupMs` and `startupCpuMs` are the CPU time of the WHOLE process between the two marks (all its threads, like
`cpuMsAvg`), not of the game's thread alone: measured from a terminal (`factoria call perf.measure`, `perf.check`) the process
is the game, but a number taken inside the editor would also count the editor's own threads (its UI, background loaders, the AI).

Times are this machine's and rounded to 0.1 ms: compare two runs on one machine, never pass or fail on them (no test
does; `startupMs` is a CPU time with a wide budget for that reason).

**Keeping start-up low.** The usual causes, in the order to look at them:

- The start scene instances or loads too much: put what is not on the first screen in a scene or prefab loaded later.
- Big textures: `play.report` `loading.slowestAssets` lists them with the time to read and to decode; ship PNGs as KTX2
  ([EXPORTING.md](EXPORTING.md)).
- Work in `onStart` of a script: generating a large map, building tables. Spread it over frames or generate it ahead of time
  into a file.
- Many custom materials: each one is shader programs to build (compare `gpu.cacheHits` with `gpu.cacheMisses`: on a first run everything is a miss, on later runs a hit).

### The shader cache and the backends

A shader program must be turned into the graphics card's machine code before it draws. Where the engine can keep part of that
work between runs it does, in the per-user cache folder (`fs::cache_dir()`: macOS `~/Library/Caches/FactorIA`, Windows
`%LOCALAPPDATA%\FactorIA\Cache`, Linux `$XDG_CACHE_HOME/factoria` or `~/.cache/factoria`, Android the app's `cache` folder, iOS
`Library/Caches`; `FA_CACHE_DIR` overrides it; never the game folder). A cache file holds a header (magic, format version, a key,
the payload size and its SHA-256) and the payload; a file with another key (another engine version, other source), a bad header or a
bad checksum is ignored with one log line (category `cache`) and rebuilt, and a file is written to a temporary name and renamed
over the old one, so a crash never leaves half a file. Deleting the folder is always safe.

| Backend | Where | Engine disk cache | What it cannot do (documented elsewhere in these docs) |
| --- | --- | --- | --- |
| Direct3D 11 | Windows | Yes: the compiled bytecode (DXBC) of each stage, made with `d3dcompiler_47` (loaded at run time; without it sokol compiles as before). The first run compiles every program (about 0.3-1 s for the built-in ones); later runs hand the bytecode to the driver and load no compiler. | Nothing the others lack: it reports GPU times. |
| OpenGL 4.3 core | Linux | No: sokol hands the driver GLSL source and the link happens inside the driver, with no way to give it a binary. The driver's own shader cache (Mesa, NVIDIA) does that. | A driver without GL 4.3 cannot start the renderer. It reports GPU times. |
| Metal | macOS, iOS | No: the Metal library is built from source text by the OS, which caches it itself. | No GPU times through the graphics layer the engine uses (see "Finding what is slow"). |
| OpenGL ES 3 | Android | No: as GL (the driver's cache); the player gives the cache folder to the engine for the day a backend there can use it. | No GPU times; at least the 256 vec4 uniforms of the minimum (64 joints per skin); textures may be ETC2 where nothing better exists. |
| WebGL2 | Web | No, and it cannot have one: a page has no folder of its own to keep files in (the browser caches compiled shaders itself). | The same limits as GL ES 3, and textures stay PNG. |

Whether a given feature works on every backend is documented where the feature is (for example [SHADERS.md](SHADERS.md)); a
`renderer.supports(...)` query that scripts and tools can ask is planned (ROADMAP, M71 onward) and does not exist yet.

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
  memory: {start, end, peak: {processMB, jsHeapMB, textureMB, audioDecodedMB, musicMB, entities}}
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
- `memory` samples the process (resident memory now and at its peak), the JavaScript heap, texture memory, decoded audio (`audioDecodedMB`: sounds, streaming buffers and the music cache; `musicMB` is the music part of it: a song costs about 10 MB per minute per stem, docs/MUSIC.md)
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

Cost: idle workers sleep and use no CPU. A job costs about one allocation and the short lock of one worker's queue
(each worker has its own and steals from the others when it runs out), so the engine only splits work big enough to
gain from it. Each worker has a stack and a few kilobytes of its own: on a phone, fewer workers save a
little memory and battery.

What runs on the workers: the drawing work of a frame once it is big (the sprites, tilemaps, the quads of the particles, the 3D meshes'
matrices, culling and shadows, the sorts and the vertex stream; docs/ARCHITECTURE.md, "Systems that run as jobs"
lists each job with its threshold), the simulation of the particles and the poses of many animators. A game under every threshold (a few hundred
sprites, under 2048 particles, under 256 meshes: most games) runs exactly as with 0 workers. In `perf.profile`'s
`threads` these show as `render.gather_sprites`, `scene.particles`, `render.mesh_cull`, `scene.animation_poses` and
the like on the worker lanes.

Choosing `jobThreads`:

- Keep `"auto"` unless a measurement says otherwise. A game whose `threads` show no render or animation jobs on the
  workers gains nothing from more of them; `0` then saves the workers' memory.
- A crowded scene (thousands of sprites or particles, hundreds of meshes) gains on the CPU side of `render`. What the
  workers cannot take is the submission to the GPU (one call per draw, on the main thread), so `drawCalls` still sets
  the floor: batch first (shared textures and materials), then add threads.
- `perf.measure`'s `cpuMs` is the CPU time of the whole process (every thread), so threads do not lower it: compare
  `perf.profile`'s `frameMs` and `systems.render` (wall clock) with `FA_JOB_THREADS=0` and with the setting you want.
- The picture and `game.state_hash` are the same with every setting; `"inline"` and 0 workers take the one-chunk path,
  the cheapest when there is nobody to share the work with.

### Physics on jobs

Physics, path searches and sound rendering use the job threads when the work is big enough, and always give the same result
as without them (docs/ARCHITECTURE.md, "Physics, navigation and audio on jobs"). Nothing to switch on: a small game never
queues a job. The sizes below are counts of items, the same on every machine (never a measured time):

| Work | Runs on the job threads when | Not split further than |
| --- | --- | --- |
| 2D physics step (Box2D) | at least 1536 awake bodies or 4096 contacts | 4 pieces per task (the pool's size above 4 is not used) |
| 3D physics, contact tests and events | bodies^2 >= about 16384 (128 bodies or more) | chunks of about 4096 body pairs |
| `nav.findPaths` / `nav.findTilePaths` | 8 or more queries in one call | 4 queries per chunk |
| `render_sfx` (and what uses it) | 2 or more layers and at least 24000 samples (half a second at 48 kHz) | one job per layer |

Measured on an Apple M5 (10 cores) with a Release build, the machine busy with other builds, so read the numbers as
orders of magnitude; the time of one step, `inline` against 1, 2 and 8 worker threads:

| Scene | inline | 1 | 2 | 8 |
| --- | --- | --- | --- | --- |
| 2D, 420 bodies (below the threshold) | 0.38 ms | 0.41 ms | 0.40 ms | 0.47 ms |
| 2D, 1000 bodies | 1.0 ms | 1.0 ms | 0.95 ms | 1.05 ms |
| 2D, 4000 bodies | 5.3 ms | 4.6 ms | 4.0 ms | 3.9 ms |
| 2D, 8000 bodies | 9.9 ms | 8.6 ms | 7.8 ms | 7.4 ms |
| 3D, 100 bodies (below the threshold) | 0.9 ms | 0.9 ms | 0.9 ms | 0.9 ms |
| 3D, 250 bodies | 4.9 ms | 3.6 ms | 3.2 ms | 3.0 ms |
| 3D, 600 bodies | 23 ms | 17 ms | 15 ms | 12 ms |
| `render_sfx`, 5 layers, 3 s | 13 ms | 9 ms | 8.6 ms | 9 ms |

The 2D gain is modest because Box2D already makes a step cheap and part of it (the solver's order, the joints) is
sequential; below about 1500 bodies the jobs cost as much as they save, which is why the threshold is there. The 3D gain is
bigger because its pair loops dominate. The solver's iterations, the time-of-impact islands,
sleeping, joints, character controllers and the device's audio callback stay on one thread. The example games all stay
below these sizes: their draw calls, entities and per-frame time did not change (`perf.measure` with `FA_JOB_THREADS=inline`,
`4` and `8` on the examples gave the same numbers within noise), so no example budget was tightened.

Box2D's constraint solver runs its worker tasks as jobs that spin-wait on each other during the solve (they wait for the
other pieces of each stage without sleeping). On a loaded machine, or with fewer cores than job threads, that spinning costs
CPU time and can make a wide step slower than on one thread; the sizes in the table are what keeps small steps off it.

`cpuMsAvg` of `perf.measure` is the CPU time of the whole process: work moved to another thread does not lower it, it
lowers the wall time of the frame. Compare frames per second, or `jobs.info` (how busy each thread was), to see the gain.

## Microbenchmarks (`fa_bench`)

The budgets above watch whole games. `fa_bench` watches the engine's own hot paths, so a change that makes the ECS, the
hierarchy, a physics step, the renderer's gather, a command call, the script bridge or the mixer slower is found in the
pull request that did it, not when an example later goes over its budget. It is a program of the engine's repository
(`tools/bench/`, target `fa_bench`, built with the tools); it has its own small harness and no dependency.

| Benchmark | What one run does |
| --- | --- |
| `ecs.each`, `ecs.entities_with`, `ecs.spawn_destroy` | `World::each` over 20000 entities (two, three and a small pool's worth of components), `World::entities_with`, creating and destroying 30000 entities |
| `hierarchy.deep`, `hierarchy.wide` | `World::world_matrix` for every entity of a chain 400 deep, and `World::world_position` for 20000 leaves of a tree 4 levels deep |
| `physics.step2d`, `physics.step3d` | 60 `Physics::step`s of 576 falling 2D bodies (Box2D) and 20 of 196 3D bodies (the engine's solver, which costs more per body); the scene is rebuilt before every run, because bodies fall asleep |
| `physics.step3d_1000`, `physics.step3d_stack100` | 10 `Physics::step`s of 1000 falling 3D spheres, capsules and boxes in a walled pit (the case a broadphase must make cheap: every pair is tested today), and 60 steps of a column of 100 boxes on a floor (stacking: contacts and sleeping) |
| `render.frame2d`, `render.frame3d` | 8 headless frames of 5000 sprites and 120 texts, and of 1600 meshes with a sun and 4 point lights, at 640x360 |
| `command.call` | 20000 `CommandRegistry::call`s over 300 commands with a schema, every 50th with arguments that are refused |
| `script.native_calls`, `script.component_access`, `script.behaviours` | JS to C++ calls, component fields read and written from JS, and 30 frames of 300 behaviours |
| `audio.mix_voices`, `audio.mix_bus_fx` | Two seconds of the software mixer with 48 looping voices (pitch and pan), without and with a low-pass and a reverb on the buses (the null device, offline) |
| `jobs.tiny`, `jobs.for_small_grain`, `jobs.for_large_grain`, `jobs.graph`, `jobs.nested_wait`, `jobs.main_queue` | The job system's scheduling: 20000 tiny jobs submitted from one thread; `parallel_for` with 1250 small chunks per call and with 32 large ones; fan-out/fan-in rounds and a chain of dependent jobs; jobs that submit jobs and wait for them; 96000 main-thread tasks posted and run. Each job does almost no work, so the numbers are the queues' and waits' own cost. The baselines are `--jobs inline`; run `--jobs 4` to measure the pool (wider warn and fail ratios, x1.8 and x3) |

Every input is built from a fixed seed (`fa::Rng`), so two runs do the same work (the report says when the repeats did not).
A run takes about 10 to 110 ms (macOS, Release). The render benchmarks need a graphics context (EGL with Mesa on Linux, Metal, D3D11) and are
skipped, with the reason, when there is none; the others need nothing.

```bash
fa_bench                            # all of them: median, spread (p75 - p25 over the median), min, max and CPU time of 9 runs
fa_bench --filter ecs,physics.step3d   # the benchmarks whose name contains one of these words; --list shows them
fa_bench --repeats 21 --warmup 3 --out numbers.json   # more runs; --json prints the file instead of the table
```

The job system runs inline by default (`--jobs inline`, one thread: the steadiest numbers); `--jobs auto` or `--jobs 4`
measures the pool (big physics steps use it, see "Job threads"), and a baseline is only compared with a run made with the same
`--jobs`. A benchmark that fails the comparison is measured up to two more times (`--retries`) and the best run counts, so a
slow second on a shared machine does not fail it.

### Baselines

`tools/bench/baselines/<runner>.json` (format `factoria.bench/1`) holds the medians of one kind of machine. The runner id is
`<os>-<compiler>`, with `-debug` at the end for a build without `NDEBUG` (no graphics part, unlike the ids above: these
benchmarks do not measure the GPU): `linux-gcc`, `windows-msvc`, `macos-clang`. `FACTORIA_BENCH_RUNNER=name` sets your own.
A baseline from a Mac's own CPU is not the baseline of GitHub's Linux runner, so each runner has its file, and only the
Linux one is enforced by CI.

```bash
fa_bench --compare                # against tools/bench/baselines/<this runner>.json, found from the working directory upwards
fa_bench --baseline other.json    # against this file
fa_bench --update-baseline        # write (merge into) the baseline file of this runner; --filter updates one benchmark
```

The limit of a benchmark is its baseline median times a ratio, or the baseline plus a few tenths of a millisecond when that
is more (a time under a millisecond moves by more than a ratio from one run to the next). Past the **warning** ratio (x1.4;
x1.6 for the render benchmarks, which run a GPU driver beside the engine) the run passes and prints a warning, in CI an
annotation; past the **fail** ratio (x2, render x2.5) `fa_bench --compare` exits with status 1 and the message names the
benchmark, the baseline, the measured value and how to refresh the baseline. A run under 70% of the baseline passes and
says that the baseline can be refreshed. An entry can carry its own `"warnRatio"` and `"failRatio"`; `--update-baseline`
keeps them. The bands are wide on purpose: the check is for a regression of a half or more, which a shared machine cannot
fake, not for a few percent.

A benchmark with no entry in the baseline, a runner with no baseline file, a file of another format and a file measured with
another `--jobs` are not failures: the comparison says so, the numbers are printed and `--out` still writes them.
`--require-baseline` turns a missing entry into a failure.

### In CI

The `bench` job of `.github/workflows/ci.yml` builds `fa_bench` in Release on the Linux runner, runs it under Xvfb with
Mesa's llvmpipe like the tests, compares with `tools/bench/baselines/linux-gcc.json` and uploads `measurements.json` and
`comparison.json` as the artifact `bench-linux` (the job summary has the table). It is part of `CI result`. While
`linux-gcc.json` does not exist it only warns and uploads the numbers.

Refreshing a baseline is a decision, not a way to make a check pass: do it when the code got slower or faster on purpose.
The Mac, Windows PC or runner of that baseline measures it: on your machine `fa_bench --update-baseline` from a Release
build; for the CI runner, "Run workflow" with **benchBaselines** ticked builds nothing else and runs the `Bench baselines`
job on Linux, Windows and macOS, whose artifacts `bench-baselines-<os>` hold the files to copy into `tools/bench/baselines/`.
The first `linux-gcc.json` is made that way, or from the `measurements.json` of a `bench-linux` artifact (`fa_bench --out`
writes the baseline format).
