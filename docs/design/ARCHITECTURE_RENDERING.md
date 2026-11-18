# FactorIA architecture: rendering

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page).

## Coordinates & units
Right-handed, +Y up, angles in degrees, colors 0..1. 2D world units = design
pixels (a default 2D camera shows exactly the design resolution, origin at the
center). Screen-space UI: design pixels, origin top-left, +Y down. 3D units =
meters. Details in `core/math.h` and `scene/components.h`.

## Rendering
sokol_gfx backends: D3D11 (Windows), Metal (macOS/iOS), GL 4.3 core (Linux),
GLES3 (Android). The game always renders into an offscreen target at design
resolution; `present()` letterboxes it to the window. Screenshots read that
target, so headless and windowed images match. `Camera.bloom` is a post-process
that adds its glow INTO that same target (`engine/render/src/bloom.cpp`,
`shaders/bloom.glsl`), so screenshots include it. The target is RGBA16F (`Gpu::scene_format()`) when the GPU renders to
it with blending, filtering and the requested MSAA, else RGBA8 (`FA_SCENE_FORMAT=rgba8` forces the fallback;
`Renderer::hdr_scene()` says which; when the GPU lists RGBA16F but `Impl::create_targets`, the first time it makes the targets,
finds the game target's images or views not VALID, as GLES3/WebGL2 with MSAA and no `EXT_color_buffer_float` can, and the
same size works in RGBA8, the format becomes RGBA8 (the pipelines made for RGBA16F stay in the cache under their own key; no flush) and the game is drawn
in RGBA8, on every backend. A later resize or render scale that fails never changes the format. Only the game target falls
back: a CameraView, a bloom level or the colour filter image that cannot be made keeps the format and its own warning, so
`hdr_scene()` can stay true with one of them invalid. `FA_SCENE_FORMAT=rgba16f_invalid` forces the fall-back in tests and `FA_SCENE_FORMAT=r11g11b10` makes a linear scene use R11G11B10 (no alpha) as if RGBA16F were not renderable; likewise a shadow map the GPU cannot make turns the
shadows off with one warning until the next resize, and `FA_SHADOW_MAP=invalid` forces that): a float target keeps a colour above white (`MeshRenderer.emissive` times
`emissiveStrength`), and the bright pass hands bloom that excess, so it glows more. The screen, screenshots and video stay
8-bit: `Impl::read_rgba8` copies a float target into an RGBA8 image (the `blit_keep` program, which keeps alpha) before
reading it, and the colour filter clamps its input for every mode but `none`. With `Camera.bloomScreenSpace = false`
the frame is split: world pass, bloom, then a second pass that draws the screen-space
groups (HUD) on top; with MSAA the glow is added to the multisampled image and the
HUD pass loads it again, so the HUD is multisampled too. The colour filter is the last post-process
(`Renderer::Impl::ensure_filter_target` and `post_pass`, `shaders/post.glsl`; `colorfilter.glsl` stays only for the GL copy of a
render target's picture): a pass cannot read what it writes, so the filter
draws the finished target into a second image of the same size, and `present()`, `capture()` (screenshots, video) and
the editor viewport read that image (`Impl::final_target()`) while a filter or the final pass is on; `none` skips the pass and the image. The colour-blind
CHECK (`simulate` of `game.screenshot`) is separate: `simulate_color_vision()` in `fa/core/image.h` on the captured
pixels. `game.screenshot` (whole view, `region` + `zoom` via `Engine::capture_region`, filmstrip), `render.inspect` and `render.pick` are in
`runtime/src/shot_commands.cpp`; pixel work (crop, contact sheet, line profile) is `fa/core/image_tools.h`, and which files a screenshot
may leave behind (temporary ones, pruning) is `fa/core/screenshot_files.h`. Pipelines (`Gpu`, `gpu.cpp`) are keyed by what
they draw (the getter's flags, a custom material program) AND by the `TargetFormat` of the pass they draw into (colour format,
depth format, sample count; `gpu_types.h`): every getter has an overload taking that format (`quad_pipeline(format, ...)`) and
a thin wrapper for the usual target (`scene_target_format()` for quads, meshes and the sky). So the same program in an RGBA8 and
an RGBA16F target, or with 1 and 4 samples, are two entries of one cache, and nothing is flushed when a format changes (the
RGBA16F fall-back above, a float render target). The cache is bounded by use: `begin_frame()` counts frames, and once it holds more
than 192 pipelines (`Gpu::kPipelineCacheCap`; the engine's own set is about 50) a pipeline no draw asked for during the last 300
frames (`kPipelineIdleFrames`) is destroyed, checked every 16 frames, and made again if it is ever asked for. A cache under the
cap keeps everything, and the pipelines the warm-up makes or asks for (`Renderer::warm_step` runs each group between `Gpu::set_warming(true)` and
`set_warming(false)`; a fixed set of about 20) are never destroyed at all, so a rarely used one that the warm-up paid for does not hitch (D3D11, Metal) when it comes back;
the limits count frames, never time. `pipelines`, `pipelineHits`,
`pipelinesMade` and `pipelinesEvicted` are in the start-up report (`loading.startup.gpu`). Shaders are GLSL annotated for
`sokol-shdc`; generated headers are committed (`tools/shaders/compile_shaders.sh`). Every mesh program (`mesh`,
`mesh_skin`, `prepass`, `prepass_skin`, `shadow`, `shadow_skin`) comes from one template, `shaders/mesh_common.glsl`: a top file defines the
`@block fa_user` (a `surface()` snippet, plus `vertex()` with `FA_HAS_VERTEX`), `@include`s the template and declares
the programs. `mesh.glsl` is that top file with an empty `surface()`; a custom material is the same with its own
snippet, so the engine and the materials share one source of truth (an empty `surface()` renders pixel-identical to a
`MeshRenderer` without a material). Engine identifiers in the template start with `fa_`; `fa_time` (vertex and
fragment) is `World::time()`, the engine clock. The template is embedded in `fa_tooling`.

**Passes and targets.** One way to begin a pass and one way to make a target (`render_internal.h`, `gpu_types.h`). Every
pass of the engine is a `PassDesc` (views, formats, load/store actions, clear values, label) given to `Gpu::begin_pass`,
and `Gpu::end_pass` ends it: `sg_begin_pass` appears nowhere else in `engine/`. The defaults of a `PassDesc` are
DONTCARE, not sokol's (a zero `sg_pass` CLEARS to grey), so each site says what it loads and stores. A pass into the
window is `PassDesc::for_swapchain`, which resolves sokol's 0 (colour format, depth format, sample count) against the
environment's defaults, so its `TargetFormat` is the one the pipelines are keyed by. In a Debug build `begin_pass`
records the pass's format and every pipeline fetched while it runs must match it (an assertion names the mismatch);
outside a pass, as in the warm-up, any format may be asked for. A `Target` is made by `make_target(TargetDesc)`: a
colour image, its resolve image when `samples > 1` (`resolveAsColor` also gives the resolve a colour-attachment view,
for bloom), an optional depth image, and their views (`colorAtt`, `resolveAtt`, `depthAtt`, `texView` for sampling),
`pass_into(target, label)` is the matching `PassDesc` and `destroy_target` frees the lot. The game, CameraView and
render-target images, the light buffer, the colour-filter image, the readback copy, the shadow map and the bloom levels
are all `Target`s (`renderer_targets.cpp`, `transient_targets.cpp`). `Target::valid()` also needs the attachment views
the target made (`colorAtt`, `resolveAtt`, `depthAtt`, `texView`), so a full view pool makes a target invalid, not only
a full image pool, and the game target then falls back to RGBA8 like any other target the GPU could not make. A game
that draws its own window pass (the editor: ImGui over the viewport) does it with `Renderer::begin_window_pass` /
`end_window_pass`, and the player clears its window with `Renderer::present_clear`, so neither `player/main.cpp` nor
`editor_app.cpp` calls sokol for the game. The ImGui backend (`tools/editor/src/imgui_backend.cpp`) is a separate GPU
client with its own pipelines and keeps using sokol directly.

**Cameras and viewports.** Every active `Camera` with `primary` draws, in ascending `depth`, into its `Camera.viewport`
(normalized `[x, y, w, h]` of the target, top-left origin, at most 8 cameras; the loader and `camera_viewport_problem` in
`scene/components.h` reject a bad rectangle). One camera over the whole target is ONE job, world and screen space together, exactly
the path there was before. Otherwise `Renderer::render` makes one world job per camera (own viewport and scissor, own culling, own
2D and 3D lights, own clear of its rectangle) and one more job for the screen-space groups, drawn once over the whole target after
them. The 2D light buffer is built per camera job, from the lights that reach that camera. Bloom, `bloomScreenSpace` and
`colorFilter` run once, on the finished target, with the lowest-`depth` camera's settings. `RenderStats` is per frame and adds up
over the cameras. `world_to_screen`, `screen_to_world` and `screen_ray` take an optional camera; without one they use
`camera_at(point)` (the camera whose viewport contains the point, else the first drawn), and `cameras()` lists those drawn. The
audio listener without an `AudioListener` is the first camera drawn. Known limit: a screen-space visual with `lit: true` is lit
by the scene's ambient light only when the frame has several cameras (the screen job gathers no `Light2D`). The editor viewport
shows the whole frame: its picking uses the camera under the pointer, but its outlines and gizmos project through the first
camera drawn, so in a split frame they line up with the first view only.

**One 2D gather for every camera.** `Renderer::render` makes one `Scene2D` (`scene2d.h`) per gather round and every camera, render
target and CameraView of the frame gathers through it. The first camera that draws a Sprite, a Shape2D or a world-space
ParticleEmitter builds its quads into its own `Frame` as before and `Scene2D` remembers where they are; the next cameras that draw it
append a copy of those items (`QuadList::append_items`) with their own sort key, instead of reading the components, walking the
parents for `Tint` and the flash and building the vertices again. What depends on the camera is still done for every camera: the
`showTags` / `hideTags` mask, the Parallax shift (an entity with a `Parallax` component is built for each camera), the 2D lights, a
Tilemap's visible cells, Text (raster size, pixel snap), an item that shows a render target's texture, billboard particles (`is3D`)
and screen space (built by the one frame that wants it). The lists are the ones the cameras made before, item for item, vertex for
vertex (`scene2d_shared_tests.cpp` compares them with a fresh `Scene2D` per camera); `apply_sprite_frames` is idempotent and runs once
per frame, before the first gather. The `render.gather_sprites` and `render.gather_particles` thresholds count what a camera builds,
not what it copies. A `Scene2D` keeps pointers to the lists of the Frames of its round, so the renderer reserves those vectors.

**The render scene.** The 3D world is gathered ONCE per frame, not once per camera job (`RenderScene`, `render_scene.h/.cpp`):
`Renderer::Impl::render` builds it after the render targets exist and before any job, and the cameras, the render-target
cameras and the CameraViews all read it. Per active `MeshRenderer` it holds the drawn matrix, the resolved mesh, texture,
normal map and material, the Animator that skins it, the flash colour, the culling box (skinned too), the blend flag and
the two hashes of `materialParams` / `materialColors`; the matrices, boxes and hashes are the jobs `render.mesh_matrices` and
`render.mesh_cull`, the asset lookups stay on the main thread, and the list keeps the world's order whatever the job threads
(a chunk writes only its own items). What stays per camera, in `gather_meshes`: the `showTags` / `hideTags` filter
(`CameraMask`), the distance, the frustum test (`render.mesh_frustum`) and the far-to-near sort of the blended meshes; so
`RenderStats.meshes` and `meshesCulled` still count per camera job and add up. Two things depend on the job and are looked up
again for the few items that need it: `MeshRenderer.lods` (the level follows the camera's distance, with its own box and
blend flag) and a `"target:<name>"` texture (a camera's own target is the checker in its own frame). `Renderer::capture_world`
builds a scene of its subject instead (`RenderScene::build` with a `scopeRoot`, the same rule as `Frame.scopeRoot`). The same
scene lists, when a camera renders into a target, which targets each mesh shows, so the dependency order of the targets reads
it too. The scene points into the world and is dropped when the frame ends. The hashes of the material overrides (items with
different overrides never share a draw) were `dump()` + `std::hash` per mesh, per camera, per frame. Nothing in `fa_scene` counts
the writes of a component field (any code holding a `MeshRenderer*` may assign it: reflection, a script view, a command,
a prefab, the inspector, an undo), so there is no choke point for a version counter; `MaterialHashCache` keeps instead, per
entity (`Entity::bits()`, so a reused slot is another key), a copy of the JSON the hashes are of and hashes again only
when the value differs from the copy (a JSON comparison, no allocation); entries nobody asked for in a frame (dead,
hidden or without overrides) are dropped at its end. The comparison is `Json::operator==`, which finds `1` and `1.0`
(and `0.0` and `-0.0`) equal while `dump()` prints them differently, so which of two equal-valued overrides hash alike
can depend on the edit history: a batch may split or merge by it, the pixels are the same. A build of a subtree
(`capture_world`) is not a
frame of the cache: it does not drop the entries of the rest of the world. The scene resolves the mesh, texture and
material of EVERY active `MeshRenderer`, also one no camera shows, so a broken asset path warns once even if the mesh is
hidden from every camera. A mesh's Animator is the one on the MeshRenderer's own entity.

**Sort keys of the opaque meshes.** `build_batches` used to sort each camera's opaque items with a comparator of 26 fields
(strings and floats); now every item carries a 64-bit `sortKey` (`SortKeyTable`, `mesh_batch.h`), made once per frame in
`RenderScene::build` and sorted as an integer (a stable sort of (key, index) pairs, `render.sort_meshes`). Layout, most
significant bits first: mesh name rank (12 bits), texture name rank (11), normal map name rank (11), "rest" rank (30: the
other MeshRenderer values, the skinning entity, the material name, the two override hashes, the flash, in the order the
comparator had). A rank is the position of the value among the DISTINCT values of the frame, in the order of the
comparator (names as text, floats through `order_float`), never an address or an id of a table that outlives the frame; the
table is rebuilt from nothing each frame, so it cannot grow, and the order equals the comparator's exactly (equal keys
exactly where the comparator finds the items equal). A camera that swaps a mesh (lods) or a render-target texture ranks that
item again from the same table. The limits count distinct NAMES in one frame: 4096 meshes (the lod levels of
every `MeshRenderer.lods` count as meshes, used or not), 2048 textures (colour and normal maps share the one table of names
and so the 2048, and the empty name of "no texture" counts as one texture), 2^30 "rest" values. Past a limit, or when a
camera's value is not in the table, the items are left unkeyed and that list is sorted by the comparator as before (the same
order, slower); the first frame that overflowed logs a warning that names the limit, and `RenderScene::sort_key_fallbacks()`
counts the frames. The table dedupes the assets by pointer first and ranks only the distinct names, and keeps its work
buffers between frames (one that a huge frame left with more than four times what the frame needs, plus 4096 elements, is
freed). Batches are runs of equal keys (unequal keys end a batch without reading the fields; equal ones are still checked
field by field).

**Cameras inside the UI.** A `CameraView` (a UiBox widget) names a Camera. The UI gather (`draw_camera_view` in `ui2d.cpp`)
asks the renderer for an image of the widget's size (`Frame::viewImage`; `Impl::viewTargets` caches one per widget, same formats
and sample count as the game target so the pipelines fit, freed at the end of a frame that did not ask for it) and registers a
`ViewRequest`; the widget's quad samples that image at `layer + 1`, so clipping, layers, the modal Panel and the mirroring are the
UI's own. `Renderer::render` gathers one extra world frame per request (`build_camera` with the widget's size: the viewport
forced to the whole image, always cleared, no screen space, no post effects, no debug draw, no 2D light buffer) and draws those
jobs before the frame's own (`draw_view_job` swaps the target members of `Impl` for the image's). `Camera.lighting = studio`
replaces the scene's directional/point lights, ambient, sky and fog on the CPU, in `draw_job`, with a camera-relative key, fill and
rim, so it needs no shader change. `Camera.viewportSpace = design` converts the viewport fractions of the design area to the
target's in `build_camera`. The pointer side is `fa_ui` (`view.cpp`): the topmost widget under the pointer (`ui_widget_at`)
decides, and the game event `ui.viewPointer` goes out like the other ui.* events.

**Custom materials** ([guide for game makers](../SHADERS.md), [design](CUSTOM_SHADERS.md)):

- *Template and hook points.* `mesh_common.glsl` defines the contract structs (`SurfaceInput`, `Surface`, `VertexData`)
  and calls `vertex(v)` (with `FA_HAS_VERTEX`) inside `fa_shade_vertex`, after the instance and skin matrices, and
  `surface(i, s)` in the fragment `main` after `fa_standard_surface`, before lighting. `FA_ALPHA_CLIP` makes the
  fragment `discard` below `alphaCutoff` and makes `shadow_fs` run `surface()` too. Uniform bindings: vertex 0 params,
  3 skin, 4 the material's vertex-stage block; fragment 1 params, 2 lights, 5 the material block; material textures use
  views 6-9 and samplers 2-5.
- *Generator* (`tools/common/src/shaders_generate.cpp`). `generate_material_shader` writes the sokol-shdc top file: the
  params as one alphabetical block (each padded to a `vec4`), the textures, the snippet verbatim with a line table, then
  `@include mesh_common.glsl` and the programs (`mesh`, `mesh_skin`, `prepass`, `prepass_skin`, plus `shadow`, `shadow_skin`
  with `vertex()` or `"clip"`). `shaders_compile.cpp` runs sokol-shdc through the injectable `SetupContext::run`, maps its errors back to
  the snippet's lines and adds hints, and reads the YAML reflection (`shaders_yaml.cpp`).
- *Twins and cache.* Each dialect becomes a `factoria.shader/1` JSON document, the *twin*
  `<material>.json.<slang>.shader` (cross-compiled source per program plus binding reflection, stamped with the engine
  version and the template hash). The cache `.factoria/shader-cache/<sha256>.<slang>.shader` is keyed by the generated
  top file, the snippet, the template, the dialect and the sokol-shdc pin, so an unchanged material starts no process.
- *Runtime flow.* `Assets` keeps a `MaterialAsset` per `.material.json` (`render/src/custom_shader.cpp`): the twin comes
  from `fa::fs` (an exported game) or from `EngineConfig::shaderCompiler` (the CLI and editor inject
  `make_engine_shader_compiler`, because `fa_runtime` may not depend on `fa_tooling`; host dialect only), and becomes
  `sg_shader`s. Pipelines are keyed by shader; the batch key holds the material and a hash of the entity's
  `materialParams`, so equal overrides batch together. A failed build draws the unlit magenta error material and is
  listed in `RenderStats::materialFallbacks` and `asset_report`.
- *Hot reload.* `Engine::poll_hot_reload` sees a changed `.material.json` or snippet, `Assets::reload` rebuilds the
  material in place; a failed rebuild keeps the previous programs and logs once.
- *Exports.* `convert_shaders` (`tools/common/src/export_shaders.cpp`) runs in `prepare_game_assets`: it compiles the
  platform's dialects (Windows `hlsl5`, Linux `glsl430`, macOS `metal_macos`, iOS `metal_ios` + `metal_sim`, Android and
  web `glsl300es`), adds the twins, drops the snippets, and fails the export on a compile error. The player has no
  compiler. `factoria validate` compiles every dialect of every material.
- *Frame graph.* `engine/render/src/frame_graph.h` and `target_pool.h` are the CPU core: passes declare the
  resources they read and write; `compile()` orders them (declaration order where there is no dependency), culls the
  ones nobody reads and plans which transients share one physical target; `TargetPool` reuses targets across frames
  (keyed by size and `TargetFormat`); `FrameGraph::to_json()` is the dump (`order` and
  `aliasSlots` are empty until `compile()` succeeds). `compile()` also rejects a transient with a width or height <= 0,
  an imported resource with handle 0 and two resources with the same name, and `PassContext::handle` answers (else 0)
  only for the resources the pass declared. The contents of a transient are undefined when it is acquired: its first
  writer clears it or uses DONTCARE, never LOAD. There is ONE graph per `render()` (and a small
  one of its own per `capture_world`): `begin_frame_graph` empties it, every job of the frame declares its passes
  (`plan_job`; `plan_view_job` for the jobs that draw into an image of their own), and `run_frame_graph` compiles,
  executes and then calls `release_callbacks()` (the callbacks hold references to the frame's state, so they are dropped
  while the declaration, the compiled plan and the stats stay for `to_json`; `graph.clear()` would lose them for the
  tests). The jobs are named `target:<name>` (a `Camera.renderTarget`), `view:<n>` (a CameraView), `camera:<i>` (a
  camera of the frame; `screen` for the screen-space job of a split frame) and `capture`, and a pass is `<job>/<pass>`:
  the light buffer (`light-buffer`), the shadow map (`shadow`, only when a light casts), the world (`game`, `view` for a
  view or target job, `game-hud` for the job of a split frame that draws only the screen-space groups), the bloom stages
  of the last job (`bloom-bright`, `bloom-down-<n>`, `bloom-blur-h`, `bloom-blur-v`, `bloom-composite`), the HUD over the
  glow (`hud-over-bloom`, with `bloomScreenSpace = false`), the exposure measure (`exposure-luma`, `exposure-adapt`), the final
  pass (`post`), the HUD over it (`hud-over-post`), the colour filter (`color-filter`) and, where the backend
  stores a target bottom-up (GL), `<job>/flip`, the copy of a target's picture into the image its texture samples; it
  exists only for render targets and only in GL, and it is declared right after the target's `view` pass (so in GL the
  order reads `target:B/view`, `target:B/flip`, `target:A/view`, `target:A/flip`, `camera:0/game`; Metal and D3D11 have
  no flip pass). The CPU phases of a job (gather, cull, batch, upload) run while it is declared, and that includes the
  upload of its 2D shadow rows: `upload_shadow_rows` keeps a ring of nine images that grows (and is trimmed at the next
  frame) when more jobs than that need distinct rows, because an image a planned job will bind is never replaced within
  its frame. The GPU work runs in `execute`, and each
  callback puts the job's `JobEnv` (target size, game image and views) back first, because the jobs of a frame draw
  into images of different sizes. *Order of the jobs:* the render targets first, then the CameraViews, then the cameras,
  as they were drawn before the graph. Among the targets, a small graph of its own (`CyclePolicy::Break`) orders one
  node per target by `Camera.depth`, then creation order, each after the targets it shows (a Sprite, Text, UI quad or
  mesh in its view whose texture is `target:<other>`); the result is the declaration order of the target jobs in the
  frame graph, so A showing B gives `target:B`, `target:A`, `camera:0`. A job that shows an image of another job (a
  target or a CameraView) READS that job's image resource, an imported resource of its own, so the
  graph keeps the order. *Cycles:* A shows B and B shows A cannot both be drawn first. `compile()` does not fail: the
  node declared first goes first and shows the other's picture of the previous frame (one frame late, the same way
  every frame, and one warning is logged), exactly what the frame did before the graph. A cycle in a frame graph that
  does not set the policy is still a compile error. *Imported* resources are the persistent images: the game (or view or
  target) image, the light buffer, the shadow map and the colour-filter image (imported, not transient, because the
  present and the read-back sample it after the frame); the game image, the light buffer and the shadow map are one
  resource for the whole frame, shared by the jobs that use them. *Transient* resources are the bloom levels and the
  blur's second image: `bloom.cpp` declares them with the format of the game image (`Gpu::scene_format()`, so RGBA8 when
  the GPU cannot render RGBA16F) and the `TransientTargets` of `Impl` (`transient_targets.h`, a `TargetPool` over
  `make_target`) makes them on the first frame and hands the same ones out on the next. Only the last job has post
  effects, so N views of the same size need no more transients than one, and two jobs never share a transient alive at
  the same time (the planner aliases only resources whose uses do not overlap). A transient's contents are UNDEFINED at
  its first writer: that pass must CLEAR it or DONTCARE and cover every pixel, never LOAD it. `execute` gives back every
  transient on every way out (an error or a pass that throws). A bloom whose targets cannot be made warns once and
  draws no glow until the size or the format changes, so a failed creation is not retried every frame.
  `FrameGraph::set_import_handle` rebinds an imported resource to another image without a new compile. Not graph passes
  yet: the read-back copies. The render tests reach the graph of the last frame and the pool's counters through
  `render::renderer_frame_graph` and `render::renderer_transient_stats`. *What a pass cost:* `execute` times every
  callback with the steady clock (`PassStats::cpuMs`, also when it throws) and calls the `PassHooks` of the graph around
  it (`FrameGraph::set_pass_hooks`, kept by `clear()` and `release_callbacks()`); the renderer sets them once. The
  `begin` hook starts a GPU timestamp pair of `GpuTimer` and the `end` hook closes it and adds a zone `<job>/<pass>` to
  the profiler (`Profiler::add_zone`, summed per name, listed in `profile.zones`); both only do something while the profiler is on.
  `Impl::pass_times` turns `graph.stats()` into `RenderStats::passes` and `jobs` (the job is the name up to the last `/`;
  a culled pass has no entry; `gpuMs` is -1 without a measurement), and `Renderer::frame_graph_report()` adds the
  graph's `to_json()`: that is the `render.frame_graph` command. `render()` does not build the strings each frame: it sets
  `passTimesPending` and `Renderer::stats()` builds them from the graph when asked for (`stats(false)` leaves them out:
  the runners, `game.render_stats` and the state report read the counters only). A `capture_world` leaves its small graph
  as the last one (`source: "capture"`) until the next `render()`, builds the pending pass times of the frame first
  (`settle_pass_times`), and does not touch `RenderStats`. `render.frame_graph`'s `profileFrames` switches the profiler on
  for the call when it is off and the backend can time (`Engine::redraw` draws the current state again until a GPU time
  arrives) and puts it back; a render with the profiler off calls `GpuTimer::forget()` so that switching it on again never
  shows the numbers of the earlier run.
- *GPU timer.* `gpu_timer.cpp` (`GpuTimer`, a ring of 6 slots, results a few frames late, never waited for). The whole
  frame is one query (`GL_TIME_ELAPSED` on GLCORE, a disjoint query with two timestamps on Direct3D 11); each pass has a
  pair of timestamps (`glQueryCounter(GL_TIMESTAMP)` on GLCORE, timestamp queries inside the disjoint one on D3D11),
  because `GL_TIME_ELAPSED` does not nest. At most `GpuTimer::kMaxTimedPasses` (64) passes of a frame are timed; the rest
  report -1. A disjoint D3D11 frame (a clock change) drops its pass times too. Metal, GLES3 and WebGL2 have no timer and
  `reason()` says so. The timestamp code of D3D11 and GL is not compiled on macOS: Windows and Linux CI build it.

## Start-up order and the shader cache
A window host (`run_windowed` in `runtime/src/runners.cpp`: the player and a windowed `factoria run`) starts in this order, decided by
`StartupSequence` (`runtime/startup_sequence.h`, one `on_frame()` per window frame):

1. *Frame 1.* The window and the graphics context exist (sokol_app opens them before the first frame callback). The frame
   presents a clear frame: `Renderer::present_clear`, black = the letterbox colour. `StartupTimeline` records `WindowReady` and
   `FirstPresent`. sokol_app presents when the callback returns, so this cannot happen inside the init callback: the first
   frame has to be a frame of its own.
2. *Frame 2.* `Engine::init` reads the game (scenes, scripts, textures, shaders). It adopts the context frame 1 opened
   (`EngineConfig::adoptGraphicsContext` -> `RendererDesc::adoptContext`: the renderer does not call `sg_setup` again, does
   not `sg_shutdown` it, and the runner calls `Renderer::close_context` at the end). A clear frame is presented again.
3. *Frames 3+.* `Engine::warm_step` -> `Renderer::warm_step` makes pipelines in groups (blit; the 2D quad pipelines; the blend
   variants; the 3D mesh, sky, skinned and shadow ones when a `MeshRenderer` exists), as many groups per window frame as fit in
   about 8 ms of wall time (at least one; the time only decides how many frames the warm-up takes, never what it makes: on GL,
   GLES and WebGL a pipeline links in the driver and costs milliseconds, on Metal microseconds), each frame presenting a clear
   frame. The groups are fixed lists, not a scan of what the scene draws, so the warm-up also makes pipelines a game may
   never use (Additive and Multiply sprites, the wire/lines variant, the mesh variants of a scene with one mesh). That is
   cheap: a pipeline is a small state object (a few KB) made once, the driver's own cache makes a repeat cheap, and the
   group is skipped for 3D when the scene has no `MeshRenderer`. A frame that draws before the warm-up finished makes a missing pipeline
   when it needs it, exactly as without the warm-up: pipelines are keyed through `Gpu::find_or_make`, so what is drawn never
   depends on the warm-up, and `state_hash`, recordings, replays and goldens are the same.
4. *Then* one game frame per window frame; the first one clamps its `dt` to 1/60 s (the start took longer than the 100 ms the
   frame-time filter allows).

A host without a window (headless, `perf.measure`, tests) runs none of this: `Engine::init` makes its own context and no
frame is presented (`firstPresentMs` is `null`). The timeline is recorded in `Engine::startup_timeline()`; the editor sets
`adoptGraphicsContext = false` (its context is its own).

**The shader cache** (`render/src/shader_cache.cpp`, `core/blob_cache.h`). `sokol-shdc` writes shader SOURCE (HLSL, MSL,
GLSL) into the committed headers, not compiled code, and sokol_gfx accepts a compiled program only on Direct3D 11
(`sg_shader_function.bytecode`). So only D3D11 has an engine cache: `make_shader` compiles each stage with `D3DCompile`
(`d3dcompiler_47.dll` loaded with `LoadLibrary`), stores the DXBC and hands sokol the bytecode next time. The key is
`d3d11|<engine version>|<flags>|src:<sha-256 of the source>` (DXBC is the same on every driver and card; the driver compiles
it to machine code), the files are `<cache_dir>/shaders/shader-<program>-<hash>-<stage>-<keyhash>.facache`, where `keyhash` is the first 8 hex characters of the hash of the whole key, so two engine versions or two games with a material of the same path keep separate files (the folder grows by one small file per shader per version; deleting it is safe). GL, GLES and Metal link or build from
source inside the driver or the OS, which keep their own caches; web has no folder. `BlobCache` is generic: magic `FABC`,
format version, key, payload size, SHA-256, payload; an unreadable file is reported as `Stale` (other key) or `Damaged`
(other magic or version, short, too big, bad checksum), logged once under category `cache`, ignored and rebuilt. A store goes
to a temporary file that `fs::replace_file` renames over the target. The folder is `fs::cache_dir()`, per user and never the game
folder (`FA_CACHE_DIR` overrides; the Android and iOS players call `fs::set_cache_dir`; empty means no cache). The renderer
creates all its programs through `make_shader`, which times them: `Renderer::startup_report` gives the counters.

## Textures
An export replaces a texture `x.png` by its twin `x.png.ktx2` (Basis Universal, written by `fa_tooling`'s
`export_textures.cpp`) and packs atlas groups into `assets/atlases/*.png`, recording each packed texture's rectangle
as `packed` in the shipped `assets.json`. The renderer (`render/src/ktx2.cpp`, `assets.cpp`) loads the twin in place of
the name scenes and scripts use, transcodes it to the best format `sg_query_pixelformat` reports (ASTC, BC7, ETC2,
else RGBA8; `FA_TEXTURE_FORMAT` forces one), and a packed texture borrows the atlas image with a sub-rectangle
(`TextureAsset::uv`). Only the Basis *transcoder* is in the runtime (`fa_render`, outputs the game never uses are
compiled out); the encoder is in `fa_tooling`. `core/image.h` (`texture_size`) is the one place that answers "how big is
this picture" whatever form it ships in.

## Bounds
Where a 2D entity is and how big it is has ONE definition, `fa/scene/bounds.h` (`visual_footprints`, `entity_world_rect`): Tilemap, Sprite,
Shape2D and Text from size, pivot and the world matrix. `entity.bounds()` in scripts and the editor's picking and selection outline
both call it, so what a script measures is what the editor outlines. File sizes and font layout are injected (`VisualMeasure`).

Text has ONE layout too: `Fonts::layout` (`render/src/fonts.cpp`) draws screen and world `Text`, UI labels and debug text, and
`Renderer::measure_text` returns its size. `text_shaper.cpp` is the GPU-free part (font chain per character, HarfBuzz shaping,
SheenBidi reordering, line breaking), so tests can look at glyph ids and positions; `fa/render/fonts.h` is its coverage check
for tools. Fallback fonts and the text size option live on the `Renderer` (`set_fallback_fonts`, `set_text_scale`). Details for
game makers: [TEXT.md](../TEXT.md).


## PostProcess (M71, in progress)
M71 adds a linear HDR frame and a stack of post effects. The first package lands the shared interface; the linear frame (below, "Linear
colour") and the effects listed in the last bullets (exposure, bloom, tonemap, colour filter, and the grading and lens effects of the
final pass) are drawn; the others are not yet.

- **Linear colour, where the conversions are** (`SceneSettings.colorSpace linear`; every one of them is a no-op in a gamma scene, so
  its pixels do not change). `Renderer::Impl::sync_color_space` (called first in `render` and in `capture_world`) tells the `Gpu`
  (`set_linear`) and makes the game target again when the scene format changes. The `Gpu` holds two format chains (`sceneChain_[0]`
  gamma: RGBA16F, RGBA8; `[1]` linear: RGBA16F, RG11B10F, SRGB8A8, RGBA8), each tried in order by `create_targets` (a creation that is not
  VALID moves to the next one); `scene_format()` is the active one. Authored colours are converted on the CPU with `color_space.h`
  (`to_scene`, `Frame::linear`): light, ambient, fog, sky, clear and material colours in `renderer_draw.cpp` and `scene2d.cpp`; vertex
  colours of the quad stream (sprites, shapes, text, particles, HUD) in the quad vertex shader (`vs_params.cspace.x`). Colour textures
  are made in the sRGB variant of their format when they are first uploaded in a linear scene (`Gpu::texture_format`,
  `TextureAsset::enc`); `TextureAsset::tex_fix(linearScene, colour)` gives the shader's correction when the use does not match the
  format (`fa_tex_fix`: quad `cspace.yz`, mesh `fa_maps.w` packing five 2-bit codes), so one asset serves both uses and a run-time
  switch makes no texture again. View and render-target images are `TexEncoding::Scene` (never corrected); the font atlas, ramps and
  video textures stay raw. The final blit encodes linear to sRGB (`blit_fs_params.encode`, replaced by the final pass of the stack) and
  so does `read_rgba8`; an SRGB8A8 target is encoded by the GPU on write, so a gamma-correct read-back of it is a plain read.
  R11G11B10 has no alpha (`scene_has_alpha`); `FeatureEnv.r11g11b10` follows the same rule as the chain (blend, or GL where sokol does
  not report it). The editor viewport shows `Impl::display_view()`: the finished game image in gamma; in linear, after
  `Renderer::set_editor_view(true)` (the editor, once; a game never), an RGBA8 copy that `update_editor_copy()` draws after each frame
  with blit_keep and `encode` on (not counted as a draw call, freed when the scene returns to gamma or the editor stops asking). M71-B4
  points `display_image()` / `display_view()` at its final target. The shader helper `fa_tex_fix` is written with `if` branches on a
  uniform, so a gamma scene skips the pow() blocks on compilers that would run both sides of a `?:`.

- **Data, in `engine/scene`.** `SceneSettings.colorSpace` (`gamma`, the default, or `linear`), `hdrOutput` (`off` or `auto`) and
  `paperWhiteNits` (200) are stored and saved with the scene; an old scene without them loads as gamma. The `PostProcess` component
  (`fa/scene/postprocess.h`) is flat: the meta fields `enabled`, `shape` (`global`, `box`, `circle`, `sphere`), `size`,
  `blendDistance`, `priority`, `weight`, then for each effect `<effect>Enabled` and its parameters (`bloomIntensity`,
  `tonemapMode`, ...). A field belongs to the effect whose name its own starts with (`post_field_effect`), so the resolver blends a
  parameter added later without being edited. Everything is off by default. On a Camera it is that camera's own stack; on any other
  entity it is a volume.
- **Effect order, one list.** `kPostEffectOrder` (and `enum PostEffect`, same order) is the order the passes run, HDR effects first,
  display effects after the tonemap: `ssao`, `ssr`, `fog`, `sunShafts`, `exposure`, `depthOfField`, `motionBlur`, `radialBlur`,
  `lensDistortion`, `chromaticAberration`, `bloom`, `tonemap`, `colorGrading`, `vignette`, `sharpen`, `outline`, `pixelate`,
  `posterize`, `filmGrain`, `colorFilter`. A pass never reorders it; `post_effect_is_hdr` tells the effects that run before the
  tonemap (up to `bloom`).
- **The CPU resolve, in `engine/render` (`src/postprocess_resolve.h`).** `resolve_post_stack(world, camera)` returns the one
  `PostStack` of a frame: `fx` (a PostProcess whose values are already blended), `mask` (bit i = effect `PostEffect(i)` runs),
  `sources` (how many components contributed). `build_camera` fills `CameraInfo::postStack`; the passes of the last job read it (`make_post_plan`, `src/postprocess.h`). It is pure CPU and
  deterministic: it starts from the neutral stack (`postprocess_neutral()`, every effect off at its identity values), applies the
  camera's own PostProcess, then the enabled volumes active in the hierarchy in ascending `priority`, equal priorities by entity id
  (so the last id wins), each with strength `weight * influence`. The influence is 1 inside the shape and falls linearly to 0 over
  `blendDistance` outside it (box: half extents `size * scale / 2` in the entity's rotated frame; circle: radius `size.x`; sphere:
  radius `size.x`; scale by the largest axis; a 2D camera tests x and y only). A component switching an effect on that the stack has
  off first sets it to the neutral values, so it fades in; numbers, vectors and colours are mixed `stack * (1 - s) + value * s`
  (integers rounded); switches, modes, textures, curves and the autofocus entity switch at `s >= 0.5`. A component that leaves an
  effect off never switches it off. A world without a PostProcess costs one count.
- **What the GPU can do, `Renderer::supports(name)` and the `render.supports` command (`src/render_features.h`).** One table of
  named features: the GPU capabilities `floatTargets` (RGBA16F renders, blends and filters), `r11g11b10`, `sampledDepth`,
  `computeShaders`; the engine features `linearColor` and `hdrOutput`; and one per effect (the names above). Each row says the
  backends it can ever run on (GL, GLES3, WebGL2, D3D11, Metal; the headless dummy backend has none), what it needs from the GPU
  (read with `sg_query_pixelformat` / `sg_query_features`), and whether the engine draws it yet. A feature the engine does not draw
  answers false with the status "planned (M71)": each M71 package turns its own on (`effect_drawn` in `render_features.cpp`: exposure,
  bloom, tonemap, colorFilter, lensDistortion, chromaticAberration, colorGrading, vignette, sharpen, outline, pixelate, posterize and filmGrain so far), so `supports` never claims what the renderer cannot do. Compute shaders exist on GL, D3D11 and Metal, never on GLES3 or WebGL2; `hdrOutput` only on D3D11 and Metal.
  The decision is a pure function of a `FeatureEnv` (backend + what the GPU reported), so a test asks what D3D11 would say.
- **Commands.** `postprocess.get`, `postprocess.set` (thin wrappers of `scene.set_component` for `PostProcess`), `postprocess.presets` and
  `postprocess.apply_preset` are in `engine/runtime/src/postprocess_commands.cpp`. The looks are data
  (`engine/runtime/data/postprocess_presets.json`, `fa/runtime/postprocess_presets.h`; `postprocess_preset_fields` gives the fields a
  look writes, replace or `keep`, Entity fields never touched, and is shared with the editor's undo plan). `postprocess.get
  {resolved}` runs `resolve_post_stack` with a `PostTrace` (which layer wrote each field) through `fa::render::post_stack_report`
  (`post_report.h`) on the CPU, for the camera `rendering_cameras()` puts first. The editor's Post-processing panel
  (`tools/editor/src/postfx_panel.cpp`) draws that report and writes only through `postprocess.set` / `apply_preset`; its A/B check is
  `Renderer::set_post_bypass`, which makes `build_camera` declare no stack (data untouched).
- **The stack's passes and the final pass (`src/postprocess.{h,cpp}`, `shaders/post.glsl`, `shaders/exposure.glsl`).** `build_graph`
  declares them for the last job, from the PostStack of the camera that drives post (`specs.front().cam`; a stack per camera job is a
  `PostPlan` and an `AutoExposure` per job, nothing else is shared). `make_post_plan` turns the stack into sanitised numbers
  (`PostPlan`); `PostPlan::convert()` (exposure, tonemap, or `linear`, which `make_post_plan` sets only for a linear scene that also has exposure, a tonemap or a colour filter: a linear scene with none keeps B1's encode in the present copy) decides whether the final pass runs. Encode matrix: `Impl::finalEncoded` is set by the `post` pass; the present copy and `read_rgba8` encode (`blit_fs_params.encode`) only when the scene is linear and it is false, and `display_image()` shows the final target itself and `update_editor_copy()` makes no copy when it is true. `filterTarget` and `hudTarget` are `Gpu::display_format()` (the scene format, but RGBA8 for SRGB8A8, whose writes would encode the display values again), and `hud_pass` draws as a gamma scene (`fr.linear` off) when the items go over the final picture Order: bloom
  (`bloom.h`, now with a soft knee in `q.y` of the bright pass and a lens dirt texture in the composite) -> `exposure-luma` /
  `exposure-adapt` (`AutoExposure`) -> `post` (exposure, tonemap, the sRGB encode, a one-step interleaved-gradient-noise dither, and
  the colour filter, in one fragment shader) -> `hud-over-post` -> `color-filter`. Four cases, by `plan.last`: (1) no conversion and
  no HUD after: the filter alone is `color-filter` (post.glsl with `convert` 0, the old filter's maths); (2) legacy
  `bloomScreenSpace = false` without conversion: `hud-over-bloom`, then `color-filter`; (3) conversion and no screen-space items: one
  `post` pass game -> `filterTarget` with the filter fused in; (4) conversion with screen-space items: `post` game -> `hudTarget` (a
  game-like target made on demand by `ensure_hud_target`: same MSAA and depth, so the HUD pipelines draw into it), `hud-over-post`,
  then `color-filter` hudTarget -> `filterTarget` when a filter is on. `Impl::final_target()` is the image present, `capture()` and
  `read_rgba8` use; the `post` program is compiled only for a frame that converts or filters (`Gpu::post_ready()`, counted by
  `post_ready_calls()` in the tests), so a game without a stack never builds it; the pass sanitises NaN and Inf at the texel read.
  `Impl::finalEncoded` says the final pass already encoded it, so the present blit must not encode again.
  Automatic exposure never reads back: `exposure-luma` takes 8x8 fixed log2-luminance taps per texel into a 32x32 transient,
  `exposure-adapt` moves a stored 1x1 EV (two persistent targets used in turn, imported into the graph) toward
  `log2(0.18) - mean` by `1 - exp(-speed * dt)` (the EV targets are R32F where it renders and filters, else the scene format: in 16 bits
  the step vanishes under half a unit of the last place and the result would depend on the frame rate) with the engine's frame dt; a first frame, new targets or a frame in which the
  passes were not declared (`lastSerial_ + 1 != frameSerial`) take the target at once, dt 0 leaves it as it is, and it needs the
  RGBA16F scene format (else one warning and the exposure stays manual). The legacy fields: `build_camera` builds an implicit
  `PostProcess` from the sanitised `Camera.bloom*` and `colorFilter` (knee 0, no dirt) and `resolve_post_stack` uses it when the
  camera has no enabled `PostProcess` of its own, so `CameraInfo::bloom` and `colorFilter` are always derived from the stack
  (`bloom_from_stack`); the six fields are in `api_since.json` "deprecated.components". The HDR output (`hdr_encode.h`): the frame
  takes `OutputTarget` (`select_output` of the last `update_output` answer: encode, headroom, paper white) when it starts;
  an extended one (an HDR encode, headroom above 1, a float display format) makes the final pass run `tonemap_hdr` (`p.z`
  and `h` of post.glsl, without a colour filter) and write sRGB-encoded values past 1, and `present_params` decodes them in
  blit.glsl and encodes them for the swapchain the window has at present time (sRGB, scRGB, PQ in Rec.2020, EDR linear),
  clamped to the frame's headroom only when its final pass went above white (`frameAboveWhite`). The CPU functions mirror
  the shaders; `renderer_force_output` and `renderer_read_floats` let the tests check them without an HDR display. Screen-space items are drawn after the final pass, so exposure and tonemap
  never touch them; in a linear scene their quad and text pipelines must write display-space values into `hudTarget`.
- **The grading and lens effects (`src/post_fx.{h,cpp}`, `include/fa/render/cube_lut.h`, `src/cube_lut.cpp`, `shaders/post.glsl`).** Six
  effects (the outline, pixelate and posterize join them in the next item) live in the same `post` fragment shader, switched by a bit mask (`PostFx::mask()`, uniform `ex.x`: 1 lens, 2 aberration, 4 grade,
  8 LUT, 16 vignette, 32 sharpen, 64 grain), so a stack without them takes the old code path and the B4/B5 goldens do not change.
  `make_post_fx(stack, frame)` sanitises the fields (clamp, NaN to the default; an effect whose values are neutral is off) into a `PostFx`
  that `make_post_plan` keeps in `PostPlan::fx`; `PostPlan::final_pass()` (`convert() || fx.any()`) is what decides the `post` pass,
  and `build_graph`/`plan_job` use it where they used `convert()` (the HUD goes after it, the program is built for it). The order in the
  shader: lens distortion and chromatic aberration move the texel read (the bloom glow is composited before, so it bends too; outside the
  lens the result is black, the aberration's samples are clamped), then the scene colour decode, exposure, tonemap and sRGB encode (only
  with a conversion), then in display space white balance, gain, lift, gamma, contrast, saturation, hue, the LUT, the vignette, the sharpen
  (it shades the four neighbours exactly like the pixel, so it needs no extra target), the grain, the dither and the colour filter.
  Nothing clamps at 1, so an HDR value stays above white; `frameAboveWhite` still needs the conversion, so effects alone do not go
  above paper white. The grain is an integer PCG hash of the cell (`grainSize` design pixels) and a seed that is
  `world.frame() & 0xFFFFFF` when `filmGrainAnimated` (the engine clock, never a wall clock), 0 otherwise. The LUT is a `LutAsset` of
  `Assets` (`assets->lut(path)`): `parse_cube_lut` reads the `.cube` (sizes 2..65, CRLF and BOM, errors with line numbers),
  `cube_lut_strip` tiles the slices of blue into an RGBA8 strip (`cols = ceil(sqrt(size))`) that the shader reads with two bilinear taps
  mixed by hand (trilinear), the same on every backend; `plan_job` resolves the path and drops the LUT when it is missing or invalid.
  The CPU functions of `post_fx.cpp` (`grade_color`, `apply_lut`, `vignette_amount`, `lens_source`, `sharpen_color`, `grain_color`)
  mirror the shader and are what `postfx_render_tests.cpp` compares the read-back pixels with. The importer
  (`tools/common/src/assets_import.cpp`) has a `.cube` route (`assets/luts/`) that runs `parse_cube_lut`, and the hot reload lists `.cube`
  among the render assets. The `colorGradingCurve*` fields are stored but not drawn yet.
- **The outline, pixelate and posterize (M71-C2; `post_fx.{h,cpp}`, `post.glsl`, `plan_outline` / `coverage_pass` in `renderer_draw.cpp`).**
  Four more bits of `PostFx::mask()` (128 depth outline, 256 sprite outline, 512 pixelate, 1024 posterize; `ex.x` is a float, so every
  mask below 2^24 is exact). `make_post_fx(stack, frame, designScale)` takes the render scale (`designScale` 0.05..16) so the width of the
  line and the block of the pixelation are design pixels (`outlineWidth`, `pixelateBlock` in physical pixels); neutral values (width 0,
  alpha 0, block 1, 256 levels) switch the bit off, so the effect is free and the frame is byte for byte the one without it. The shader:
  `pixelate_at` snaps `s` (the screen position, top-left origin) to an integer block centre (integer arithmetic: GLES3 and WebGL2 fragment
  shaders are `mediump`, the generated header makes every variable `highp`, but a float division would still wobble) before `shade`, so the grade,
  the vignette, the sharpen and the outline all read the block centre; the grain keeps `s_pixel`. The outline and posterize run after the
  sharpen, in that order, then the grain; posterize turns the one-step dither off (`q.w`), as a dither would move a value off its level.
  Posterize keeps what is above white (`floor(sat(c) * n + 0.5) / n + (c - sat(c))`).
  *Depth outline.* The image is `PostPlan::prepass` (B3: RGBA32F or RGBA16F, nearest, `texelFetch` through a nonfiltering sampler, hence
  `@image_sample_type aux_tex unfilterable_float`), bound to `aux_tex`; a Roberts cross of four texels (`lo = floor(w/2)` before and `hi =
  ceil(w/2)` after the pixel) with the silhouette (coverage differs), the relative depth jump (against `ol.y` divided by how face-on the
  two normals are, clamped to 0.2..1, so a grazing floor is not an edge) and the normal chord (`ol.z`). `aux_at` maps the screen position
  to the aux texel by `ax` (scale xy, offset zw: the identity today, the place for a camera rectangle) and flips the row on a bottom-up
  backend (`ex.y`), because the prepass is drawn by the same camera as the game image and has the same orientation. `postprocess.cpp`
  drops the outline bit from the prepass read mask unless the resolved stack's outline is depth mode and on, so a sprite outline never
  makes a prepass; `plan_outline` calls `PostPlan::skip_outline()` (it clears `fx.outline` and recomputes `linear`, so the plan may
  drop the final pass altogether) when `plan_prepass` made none (the one warning of `prepassSplitWarned` already says why).
  *Sprite outline: the decision.* The three possible sources of the sprites' alpha were the game image's alpha, a coverage render and
  an edge detection on colour. The game image's alpha is useless (the clear colour has alpha 1 and a float scene has no usable alpha on
  R11G11B10), and colour edges find the borders of 3D and of the background as well as the sprites'. So when a sprite outline is on,
  `plan_outline` has the job declare one more transient pass, `sprite-coverage` (`PostPlan::coverage`): an RGBA8 image of the frame size,
  one sample, no depth, cleared to 0, drawn by `draw_group` with the world's quad batches (`ctx.gWorld.batches`, camera `viewProj`, no depth
  test, `flatMode` 0 so no lights) and `TargetFormat` of its own (`draw_group` takes the format, since quad pipelines are made for the
  scene format by default). Alpha blending accumulates the union of the coverage in `.a`; additive and multiply blends leave `.a`
  alone; the `.rgb` is not used. The final pass reads it as `aux_tex` and draws the line outside the border: a pixel with `a >= ol.w` is
  untouched, any other pixel with such a texel in a ring of 8 taps at `round(width)` (and one at half of it for a thin sprite) takes the
  colour. Cost: one RGBA8 target and one more draw of the 2D world, only while the effect is on; it is declared only for one job that is
  the first and the last, draws the world and has a camera over the whole screen (else `coverageWarned`: one warning, the outline is
  dropped), and only when the pool could make the image. 3D meshes are not in it (a mesh is not "a sprite"), nor the clear colour, nor the
  screen-space items (the HUD is drawn after the final pass).
- **Depth and normal prepass** (`Renderer::Impl::plan_prepass`, `prepass_pass`, `prepass_view_pass` in `renderer_draw.cpp`). A pass
  of the last job's graph declared before "main", with a transient of its own (`PostPlan::prepass`, a `PrepassRef` the effects that read
  it list in their reads; the pass is `GraphPass::sideEffect` because nothing reads it until an effect or the debug view does). One
  float image (`Gpu::prepass_color_format`: `RGBA32F`, else `RGBA16F`, else none and `prepass_ready()` is false, which is also what
  `render.supports` `sampledDepth` answers) with its own depth buffer, never multisampled: r = linear view depth in world units
  (cleared to `PrepassRef::kFarDepth` = 60000), gb = octahedral view-space normal, a = coverage. A multisampled depth cannot be sampled
  and depth is not a quantity to average across samples, so the effects read one sample per pixel. The programs `prepass` and
  `prepass_skin` of `mesh_common.glsl` reuse the mesh vertex stage (instancing, skinning, `vertex()`), run `surface()` (so the normal is the
  one the main pass lights with) and discard below `alphaCutoff` with `FA_ALPHA_CLIP`, like the shadow programs; they read the camera's view matrix through the slot the shadow programs use for the
  light's (`fa_light_vp`). The pass draws `opaqueBatches` with the same instance rows as the main pass, so its draw calls are one per
  batch part; a material twin without `prepass` programs (made before this version) falls back to the engine's program and draws its
  mesh without the material. `plan_prepass` is the only decision: the job is the last one (`plan.last`), not a view, draws the world,
  the resolved stack needs the depth or the normals (`post_mask_needs_depth` / `post_mask_needs_normals` of `postprocess_resolve.h`, masked
  by `post_drawn_mask()` so an effect the renderer does not draw yet costs nothing) or a debug view is on, it has an opaque mesh, and a
  pooled image of the size could be made (else one error and no prepass). `plan_prepass` also requires `plan.first` and a camera over the
  whole screen (`CameraInfo::fullViewport()`): the `PostPlan` comes from the first camera, and when the screen-space job of a split frame is
  dropped (no HUD, no text) the last job is the last camera, so a frame split between cameras or with a partial viewport has no prepass
  (one `FA_WARN` when the stack needs depth there). `Impl::prevViewProj` keeps each camera's view-projection of the frame before (by entity,
  with the frame serial, forgotten after a frame without it) for `PostPlan::prevViewProj`, which motion blur will read. Tests force an
  effect with `render::renderer_force_post_effects`; `Renderer::set_debug_view` (and `FA_RENDER_DEBUG_VIEW`) adds the "prepass-view"
  pass, which draws `prepass_view.glsl` over the game image (the main pass then keeps its multisampled colour). The tests read the image
  through that view because only RGBA8 can be read back.
