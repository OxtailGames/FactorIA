# Performance budgets, page 2 of 3

Part of [Performance budgets](../PERFORMANCE.md) (the entry page lists every page).

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
  zones: [{name, avgMs, maxMs, callsPerFrame}],              // the 30 slowest named stretches: the renderer's passes
  threads: [{name, jobMsAvg, jobMsMax, busyPct, jobsPerFrame,  // "main", "worker 1".., "other"
             jobs: [{name, avgMs, maxMs, callsPerFrame}]}],    // that thread's 10 slowest job names
  gpu: {avgMs, p95Ms, maxMs, samples, reason},                // numbers, or null + reason
  overBudget: [{name, limitMs, frames, maxMs}],               // frames over runtime.scriptFrameBudgetMs; [] when none
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
- `zones` are stretches of a frame that have a name made at run time. The renderer reports every pass of its frame graph as
  one, named `<job>/<pass>` (`camera:0/game`, `camera:0/bloom-bright`, `target:minimap/view`; docs/RENDERING.md). `avgMs` is
  per frame like a behaviour's, and the time is the CPU time the pass took to record its draws (the part of `render`
  that is not in a pass is the gathering of the scene). A zone that is big here with a small `gpu` time is a pass that
  records too many draws; compare the passes with each other, not with `frameMs`.
- The GPU time of each pass is not in `profile`: call `render.frame_graph` for the frame graph of the last frame with
  `cpuMs` and `gpuMs` for every pass and job (`factoria call --project <dir> render.frame_graph '{"profileFrames":8}'`
  works with no editor and no running profile). `gpuMs` is measured with a timestamp before and after the pass on
  Direct3D 11 and desktop OpenGL, only while the profiler is on, for at most 64 passes of a frame, and reads the answer of
  a recent frame like `gpu`; it is `-1` where there is no number (and `gpu.reason` in the result says why). Nothing else
  switches the profiler on for that command, so `profileFrames` (default 8, 0 to 60) does: when the profiler is off and the
  backend can time, the command turns it on, draws the current state again until the first GPU times arrive (at most that
  many times; the result's `profileFrames` says how many it drew), reads the graph and puts the profiler back. Drawing
  again does not move the game (time does not advance) but it consumes the debug-draw queue: the redrawn pictures have
  no debug-draw lines, and lines queued since the last draw are lost. With `profileFrames: 0` (the call that only
  reads: no profiler, no frame drawn again), or while a profile or the editor's Profiler panel already runs, it only
  reads what is there. On Metal, GLES3 and WebGL2 no frame is drawn for it and
  `gpu.reason` says there is no GPU timer.
- `memory` samples the process (resident memory now and at its peak), the JavaScript heap, texture memory, decoded audio (`audioDecodedMB`: sounds, streaming buffers and the music cache; `musicMB` is the music part of it: a song costs about 10 MB per minute per stem, docs/MUSIC.md)
  and the entity count, at the start, the end and the peak of the run: a number that only grows over a long session is a leak.
- `threads` has one entry per thread of the job pool (main first, then every worker, idle ones too; `other` when a
  thread outside the pool ran jobs): the time it spent in jobs per frame and as a share of the frame (`busyPct`), and its
  slowest jobs by the name they were submitted with (a `parallel_for` chunk counts as one job). Which thread ran a job
  changes from run to run; the results do not (see "Job threads" below). A game whose engine work uses no jobs shows
  zeros there.
- Measuring has a small cost of its own (a few microseconds per behaviour callback); with it off there is none.

## Job threads

The engine hands pieces of its work to a pool of worker threads (docs/design/ARCHITECTURE_THREADS.md, "Jobs and threads"; repository only, not in the binary). How many is
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

What the per-worker queues of M94 changed, measured with `fa_bench --jobs 4 --filter jobs.` (Release, an Apple-silicon
Mac, median of 21 runs, once while the machine was quiet; with another build running the same numbers moved by a factor
of two or more, so read the ratios as an order of magnitude, and measure your own machine): one queue under one lock
(M70) against one queue per worker. `jobs.tiny` (40000 jobs) 40.6 ms to 12.1 ms (CPU time of the process 95 ms to 24 ms),
`jobs.graph` 26.8 ms to 16.1 ms, `jobs.nested_wait` 43.4 ms to 7.7 ms (CPU 99 ms to 23 ms). `parallel_for` over big or small
chunks and the main-thread queue did not change (11.9 ms and 8.7 ms before, 11.9 ms and 8.2 ms after).

What runs on the workers: the drawing work of a frame once it is big (the sprites, tilemaps, the quads of the particles, the 3D meshes'
matrices, culling and shadows, the sorts and the vertex stream; docs/design/ARCHITECTURE_THREADS.md, "Systems that run as jobs"
(repository only, not in the binary) lists each job with its threshold), the simulation of the particles and the poses of many animators. A game under every threshold (a few hundred
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

Physics, path searches and sound rendering use the job threads when the work is big enough, and always give the same
result as without them (docs/design/ARCHITECTURE_THREADS.md, "Physics, navigation and audio on jobs"; repository only, not in the binary). Nothing to switch on: a small
game never queues a job. The sizes below are counts of items, the same on every machine (never a measured time):

| Work | Runs on the job threads when | Not split further than |
| --- | --- | --- |
| 2D physics step (Box2D) | at least 1536 awake bodies or 4096 contacts | 4 pieces per task (the pool's size above 4 is not used) |
| 3D physics, contact tests and events | 256 or more rows (bodies) in the scan | chunks of 16 rows (each row asks the broad phase for its partners) |
| `nav.findPaths` / `nav.findTilePaths` | 8 or more queries in one call | 4 queries per chunk |
| `render_sfx` (and what uses it) | 2 or more layers and at least 24000 samples (half a second at 48 kHz) | one job per layer |

Measured on an Apple M5 (10 cores) with a Release build, the machine busy with other builds, so read the numbers as
orders of magnitude. Every number below is the time of ONE step in ms (the pit row: the mean of its first 10 steps; the
`render_sfx` row: one render of 3 s of sound), `inline` against 1, 2 and 8 worker threads. `fa_bench` reports a block of
steps per run instead (`physics.step3d_1000` is 10 steps, `physics.step3d` is 20), so its numbers are 10 or 20 times
these:

| Scene (ms per step) | inline | 1 | 2 | 8 |
| --- | --- | --- | --- | --- |
| 2D, 420 bodies (below the threshold) | 0.38 ms | 0.41 ms | 0.40 ms | 0.47 ms |
| 2D, 1000 bodies | 1.0 ms | 1.0 ms | 0.95 ms | 1.05 ms |
| 2D, 4000 bodies | 5.3 ms | 4.6 ms | 4.0 ms | 3.9 ms |
| 2D, 8000 bodies | 9.9 ms | 8.6 ms | 7.8 ms | 7.4 ms |
| 3D, 196 bodies (below the threshold) | 0.47 ms | 0.47 ms | 0.46 ms | 0.5 ms |
| 3D, 1000 bodies in a pit (mean of the first 10 steps) | 8.2 ms | 8.0 ms | 8.0 ms | 7.3 ms |
| `render_sfx`, 5 layers, 3 s (one render, not a step) | 13 ms | 9 ms | 8.6 ms | 9 ms |

The 2D gain is modest because Box2D already makes a step cheap and part of it (the solver's order, the joints) is
sequential; below about 1500 bodies the jobs cost as much as they save, which is why the threshold is there. The 3D
gain is small now: since the broad phase of M94 a scan row is cheap, so the jobs gain about 10% on 1000 bodies and cost
more than they save below about 250 (at a threshold of 64 rows the 196-body scene took 12.5 ms per block of 20 steps
with 4 workers against 9.2 on the calling thread, which is why the threshold is 256; the 3D rows were remeasured in
M94.4g with `fa_bench --jobs`, the 2D rows are older). The solver's iterations, the time-of-impact islands, sleeping,
joints, character controllers and the device's audio callback stay on one thread. The example games all stay below
these sizes: their draw calls, entities and per-frame time did not change (`perf.measure` with
`FA_JOB_THREADS=inline`, `4` and `8` on the examples gave the same numbers within noise), so no example budget was
tightened.

Memory: the 3D physics keeps the working vectors of a step (`StepScratch`) from one step to the next so a step
allocates nothing. They only grow: after a scene of thousands of bodies they keep that capacity until the physics
system is destroyed.

Box2D's constraint solver runs its worker tasks as jobs that spin-wait on each other during the solve (they wait for
the other pieces of each stage without sleeping). On a loaded machine, or with fewer cores than job threads, that
spinning costs CPU time and can make a wide step slower than on one thread; the sizes in the table are what keeps
small steps off it.

`cpuMsAvg` of `perf.measure` is the CPU time of the whole process: work moved to another thread does not lower it, it
lowers the wall time of the frame. Compare frames per second, or `jobs.info` (how busy each thread was), to see the gain.
