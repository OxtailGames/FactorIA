# Performance budgets, page 1 of 3

Part of [Performance budgets](../PERFORMANCE.md) (the entry page lists every page).

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

## Render interpolation

`"render": { "interpolation": true }` (docs/RENDERING.md, "Render interpolation") costs only the entities it interpolates: a
128-byte record each (three transforms and a few flags, in a dense list, plus 4 bytes per entity slot to find it), one read of
the Transforms before each fixed step and two per frame (after the steps, and before drawing, which finds what scripts moved),
and a blended local pose per moving entity when its matrix is built. The work on records is proportional to the interpolated
entities. With the setting off (the default) and no `Interpolation` component there is no pass and `drawn_matrix` is what it was.
Measured with `fa_bench --filter interpolation.` (Release, Apple silicon, CPU time): 20000 interpolated entities, every one moved by a step each frame, take about 0.29 microseconds per entity and frame in total (the passes, the move and the draw matrix of each entity), so about 5.8 ms for 20000 and well under 0.1 ms for the few hundred moving entities of a typical scene. Put `Interpolation` mode `"off"` on
what never moves smoothly (static scenery in a project that turned it on is already free: a pose is only blended when a step
moved it, but the pass still reads its Transform).

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
[ARCHITECTURE.md](../design/ARCHITECTURE.md#start-up-order-and-the-shader-cache), repository only, not in the binary):

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
| `gpu` | The renderer's part: `backend`, `cache` (the mode: `d3d11-dxbc` where the engine keeps a shader cache, `none` elsewhere), `programs` and `createMs` (shader programs made and the wall time that took), the cache counters `stages`, `cacheHits`, `cacheMisses`, `cacheStale`, `cacheDamaged`, `cacheStored`, `cacheStoreFailed` (present where the engine has a cache), `pipelinesWarmed`, `pipelines` (pipelines in the cache now), `pipelineHits` (asks answered from the cache), `pipelinesMade` and `pipelinesEvicted` (made, and destroyed for being idle: see ARCHITECTURE.md, "Rendering"; repository only, not in the binary), `warmMs`, `groupsLeft`. |

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
  ([EXPORTING.md](../EXPORTING.md)).
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

Whether a given feature works on every backend is documented where the feature is (for example [SHADERS.md](../SHADERS.md)); a
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
  PNG says to ship it as KTX2 ([EXPORTING.md](../EXPORTING.md)); a large `readMs` says the file is big or the drive slow.
- `reads`: the project files read (an absolute path is not counted), how many came out of a mounted `game.pak`, and what
  those took in the pack (compressed).

The times are this machine's and are rounded: compare two runs on one machine, never pass or fail on them (no test does). A
time not reached yet (the session ended before its first frame) is `null`.

The same sessions, and `factoria run`, record which files each scene reads first, in that order, into
`.factoria/cache/load-order.json`; a `--release` export writes `game.pak` in that order, so a scene's files lie next to each
other on the drive and a load reads mostly forward ([EXPORTING.md](../exporting/EXPORTING_DESKTOP.md#compression-and-pack-order)). A `factoria run`
or `play.auto` (a fresh engine that reads every file it needs itself) sets a scene's order; an editor Play only adds the
files it was missing. Recording costs one short lock and a set lookup per file read while a session runs (nothing when none
does); the file is written when the session ends, under the project's lock, and the editor writes it on a background
thread so Stop never waits on the disk. An exported game records nothing.

## Script budgets

Two `runtime` settings of factoria.json bound what scripts may use. Both take a number, or an object with one number per
platform (`windows`, `macos`, `linux`, `ios`, `android`, `web`) and a `default` for the platforms it does not name; the
value of the platform the game runs on is the one used, and a platform that nothing names gets the engine's default.

```
"runtime": {
  "scriptMemoryMB": { "default": 768, "android": 384, "web": 256 },
  "scriptFrameBudgetMs": 8
}
```

- `scriptMemoryMB` (default 768, from 16 to 2048) is the cap of the JavaScript heap, set when the script runtime starts. A
  script that goes past it fails with `out of memory`, and the error names the setting, its value and the platform
  ("runtime.scriptMemoryMB is 384 MB on android"). A phone or a browser tab has less memory than a desktop: lower the cap
  there, so a leak fails early and at the same place on every run instead of when the system kills the game. The size of
  the heap of a run is `memory.peak.jsHeapMB` of the profile (below).
- `scriptFrameBudgetMs` (default 8, from 0 to 1000; 0 turns the check off) is the time the scripts of ONE frame may
  take: every callback the engine runs for scripts in the frame (updates, fixed updates, events, timers, platform and back
  callbacks), added up. The watchdog stops a callback after 2 s, which is far too late for a game that wants 60 frames a
  second; the budget warns long before. The time is the CPU time of the thread, so a loaded machine does not trip it (on
  Windows and in the web build, where the engine has no per-thread clock, it is wall-clock time). The frame that loads a
  scene (its `onStart` calls, the first spawns) and the one after it when the load happens inside a callback are not
  counted: they are what a loading screen is for (spread a big load with background loading, below).

A frame over the budget does two things, and neither changes what the game computes (no callback is cut, and `game.state`
and replays are the same: the warning is left out of the `recentLogs` of `game.state`, because it carries measured
milliseconds):

- With the profiler on (`perf.profile`, `play.report`'s `profile`, the editor's Profiler panel) the frame is recorded in
  `profile.overBudget`: `[{name: "scripts", limitMs, frames, maxMs}]`, the number of frames of the run that went over and
  the worst one. An empty list means no frame went over.
- A `warn` log in the category `script.budget`, with the profiler on or off: the frame number, the time, the budget, the
  three callbacks that took longest (`scripts/boss.js#onUpdate 5.2 ms`; the callbacks under 50 microseconds are added up in
  one entry, "N callbacks (each under 50 us, all together)") and the setting to change. It is written the first time, and
  then at most once every 5 seconds of GAME time (the sum of the frame steps, not the wall clock, so it does not depend on
  how fast the machine is), and says how many frames went over since the last one. `game.logs`, the console and
  `play.report`'s `logs` list it, under the category `script.budget` (a filter on `script`, the category of `console.log`, does not show it).

The callbacks named are the ones the engine calls (`onUpdate` of a behaviour, a timer, a `world.on` listener), not the
functions they call: find those with `script.trace` or the profile's `behaviours`. A game that is over budget only on a
frame that loads or spawns a lot is better served by spreading that work over frames than by raising the number.

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
