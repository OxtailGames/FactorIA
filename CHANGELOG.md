# What's new in FactorIA

The editor shows these notes when it offers an update, and each release on GitHub uses its section. Newest first.

Older versions, one file per minor version with its patch releases: [0.27](changelog/0.27.md), [0.26](changelog/0.26.md), [0.25](changelog/0.25.md), [0.24](changelog/0.24.md), [0.23](changelog/0.23.md), [0.22](changelog/0.22.md), [0.21](changelog/0.21.md), [0.20](changelog/0.20.md), [0.19](changelog/0.19.md), [0.18](changelog/0.18.md), [0.17](changelog/0.17.md), [0.16](changelog/0.16.md), [0.15](changelog/0.15.md), [0.14](changelog/0.14.md), [0.13](changelog/0.13.md), [0.12](changelog/0.12.md), [0.11](changelog/0.11.md), [0.10](changelog/0.10.md), [0.9](changelog/0.9.md), [0.8](changelog/0.8.md), [0.7](changelog/0.7.md), [0.6](changelog/0.6.md), [0.5](changelog/0.5.md), [0.4](changelog/0.4.md), [0.3](changelog/0.3.md), [0.2](changelog/0.2.md), [0.1](changelog/0.1.md).

## Unreleased

- **A new library, `fa_authoring`, for the commands only developer tools need.** The first step of splitting `fa_runtime`
  so that an exported game's player carries no authoring code: `tools/authoring` links on top of the runtime, and the
  `factoria` CLI, the editor, the MCP/DAP/AI servers and their tests get its commands, the player does not (the CMake
  configure fails when `factoria_player` reaches it). `prefab.save` and `scene.format` are the first to move; their
  names, arguments and results do not change. For engine developers: `fa/runtime/command_extension.h` is a process-wide
  list of command extensions that `Engine::init` runs after the built-in and plugin commands, `fa::authoring::install()`
  registers the authoring one (call it once before the first Engine), and `Engine::runtime_command_names()` lists what the
  player has. `Engine::Impl` is now declared in `fa/runtime/internal/engine_impl.h`, for engine tools only.
  The clip, bones and skin commands (`anim.*`, `bones.create`, `skin.*`) moved there too, with their tests; same names,
  arguments and results.

### Fixes

- Audio: two memory leaks the weekly fuzz run found. A SoundFont whose `pdta` list repeats a table is refused with an
  error that names the table and its offset (TinySoundFont leaked the first copy). A damaged Ogg Vorbis setup header no
  longer leaks the scratch blocks stb_vorbis holds when it gives up: the engine's Vorbis wrapper frees them. Both
  inputs are in the fuzz corpus and in `fa_test_audio`.

## 0.28.0

FactorIA 0.28.0 (M95) gives the renderer the core that HDR and what follows will stand on, and draws the same pictures
as 0.27. The GPU layer has one way to begin a pass and one way to make a target, and its pipelines are keyed by the
format of the target they draw into. The 2D and 3D worlds are gathered once per frame and shared by every camera, render
target and CameraView, and the opaque meshes are sorted by 64-bit keys. Every frame is one frame graph: render targets,
views and cameras are its jobs, their passes are timed on the CPU and the GPU, and the new `render.frame_graph` command
and the profiler show them. A shadow map the GPU cannot make turns the shadows off with a warning instead of failing the
frame. The CI rounds are shorter and the tests that depended on timing now wait for events.

- Renderer (no change in what is drawn): one frame graph per frame (`FrameGraph`, `TargetPool`). Render targets, CameraViews
  and cameras are its jobs (`target:<name>`, `view:<n>`, `camera:<i>`), the light, shadow, main, bloom, HUD and colour-filter
  stages are their passes (named `<job>/<pass>`), and targets and views are imported resources. Targets are drawn in the
  order of what they show, and a cycle is broken the same way every frame (the earlier job shows the previous frame's
  picture). The bloom levels are transients taken from a pool, so equal sizes and formats share their images; the
  shadow-rows ring never reuses an image that a job of the same frame still binds, and it grows and is trimmed by what the
  last 60 frames needed. `compile()` rejects empty transients, handle-0 imports and duplicate resource names, with the
  names in the message.
- Renderer (no change in what is drawn): the GPU layer (`Gpu`). Pipelines are keyed by the `TargetFormat` of the pass they
  draw into, so a float or an RGBA8 target gets its own pipeline; the cache is bounded and evicts the pipelines that stayed
  idle, but keeps the ones the warm-up made. `Gpu::begin_pass` over a `PassDesc` is the one way to begin a pass and
  `make_target` over a `TargetDesc` the one way to make a render target; the player and the editor draw the game's
  window passes through the Renderer API instead of their own sokol calls.
- Renderer (no change in what is drawn): the 2D world (sprites, shapes and world-space particles) is gathered once per
  frame into a `Scene2D`; the other cameras copy the items they show, and `apply_sprite_frames` runs once per frame.
- Renderer (no change in what is drawn): the opaque meshes are sorted by a 64-bit rank key (mesh, texture, normal map and the other
  MeshRenderer values) built once per frame, in the same order as before. A frame that needs more distinct names than the key
  has falls back to the old order and counts it in `RenderStats.sortKeyFallbacks`, with one warning that names the limit
  and what to change.
- Shadows: a shadow map that the GPU cannot make (a size or format the backend refuses) turns the shadows off with one
  warning until the next resize, which tries again, instead of failing every frame. `FA_SHADOW_MAP=invalid` forces that
  failure, for tests. On Direct3D 11 the GPU timer flushes a frame that is being measured, so the pass times of a

- Renderer (no change in what is drawn): the warning for render targets that show each other names the target that is drawn
  first and the ones it waited for ("'A' and 'B' show each other, so 'A' is drawn first and shows the picture 'B' had in the
  previous frame"); a frame graph that cannot be built or run is logged with its frame number and its jobs. Bloom remembers
  an intermediate target it could not make per size and format (two views of different sizes no longer retry each other's
  failure every frame), and the shadow-rows ring keeps the images of a scene with more than 9 shadowed render targets
  instead of uploading three again every frame.
- Renderer (no change in what is drawn): every pass of the frame graph is timed. New command `render.frame_graph` returns the
  graph of the last frame with `cpuMs` and `gpuMs` for each pass and job, the backend and whether GPU times exist; the
  passes are `zones` named `<job>/<pass>` in `perf.profile`'s `profile.zones`. GPU times per pass come from
  timestamp queries on Direct3D 11 and desktop OpenGL while the profiler is on (-1 plus a reason elsewhere; Metal, GLES3 and
  WebGL2 have no timer). `RenderStats` gained `passes`, `jobs` and `sortKeyFallbacks` (also in `game.render_stats` and in the typings of
  `game.renderStats()`). `render.frame_graph` takes `profileFrames` (default 8, 0 to 60): it switches the profiler on for the
  call, draws the current state until the GPU times arrive and puts the profiler back, so the GPU time of each pass is also
  there without the editor. The pass times are built when `Renderer::stats()` is asked for them (`stats(false)` leaves
  them out), not on every frame, and a profiler switched off forgets its old GPU times.
- Renderer (no change in what is drawn): the 3D world is gathered once per frame and shared by every camera, render target and
  CameraView (a `RenderScene`: matrices, resolved assets, boxes, flashes and blend flags), so a camera only filters by
  `showTags`/`hideTags`, tests its frustum and sorts its blended meshes; the hash of `MeshRenderer.materialParams` and
  `materialColors` is computed when the value changes, not per mesh per camera per frame. A new job, `render.mesh_frustum`, in
  `perf.profile`. The scene resolves the mesh, texture and material of every active `MeshRenderer`, also one that no camera
  shows (a tag filter, outside every frustum), so a broken path now warns once even if the mesh is hidden from every
  camera. `Renderer::capture_world` (editor thumbnails) no longer makes the next frame hash every material override again.
- Continuous integration (no engine change): the GCC job's ccache key no longer starts with the Clang jobs' keys (it restored
  a Clang cache and compiled everything again; `scripts/check-ci-cache-keys.py` in the `lint` job fails on such a
  collision). A failed build no longer trims the ccache it saves, a cancelled round saves its objects too, and each job
  deletes the older caches of its own branch. Every Ninja build keeps going after an error (`-k 0`), so one round lists
  all errors. A `v*` tag no longer runs `ci.yml` (`release.yml` builds the tag). The Windows test split uses times
  from a recent run, and the ASan job runs its tests on two machines (`scripts/ctest_shard.py`, with a self-test).
  `scripts/ci-preflight.sh` runs what CI's `lint` job runs (format, the cache keys, the test split, clang-tidy), and
  `--lint-only` runs just the risk scan and those: minutes before a push instead of a CI round after it.
- `scripts/agent-build.sh` on a Mac whose displays are all asleep (lid closed, or idle): the tests that open a window
  (ctest label `window`) are left out and listed as `SKIPPED`, never as passed, and the run ends as `agent-build: DONE
  INCOMPLETE` (status 77) instead of waiting five minutes for each of them to time out; `FA_TEST_NO_WINDOW=1` tells a
  test case not to start a windowed program (`sign.macos`'s sandboxed app), and the note lists that case as well.
  `FA_AGENT_WINDOW_TESTS=run` runs them anyway.
- The `tooling` ctest entry, one process of 100 s (20 minutes under ASan) and the longest test of the suite, is five
  entries `tooling_1` ... `tooling_5` (label `tooling`) that `ctest -j` runs at the same time, with the same test cases:
  `fa_test_tooling --fa-files=a_test.cpp,...` / `--fa-files-exclude=...` (every doctest executable has them) pick test
  files by name, the fifth entry takes every file the others do not name, and the ctest entry `tooling_split_check` fails
  unless the entries together list exactly the test cases of the whole executable.
- Flaky tests made deterministic (CI T-1): the tests of the MCP HTTP server, the music transport, the file retries
  (new `fs::sharing_retries()` counter), the script watchdog and `cli_mcp_update` wait for events and counts with
  generous deadlines instead of wall-clock budgets and fixed sleeps. The HTTP server's behaviour is unchanged; it only
  gains `McpHttpServer::idle_connections()`, which a test waits on.
