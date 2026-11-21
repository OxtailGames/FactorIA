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
target, so headless and windowed images match. The bloom of a `PostProcess` is a post-process
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
reading it, and the colour filter clamps its input for every mode but `none`. With `PostProcess.bloomScreenSpace = false`
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
the colour filter (all of `PostProcess`) run once, on the finished target, with the lowest-`depth` camera's settings. `RenderStats` is per frame and adds up
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
  3 skin, 4 the material's vertex-stage block; fragment 1 params, 2 lights, 5 the material block. A material's textures
  are bound twice, under a different slot per stage: fragment views 6-9 with samplers 2-5, vertex views 10-13 with
  samplers 6-9 (`vertex()` reads them through `#define <name> fa_vs_<name>`); the baked sky cubes are fragment views
  14-15 with sampler 10. With `"lighting": "custom"` the template defines `FA_CUSTOM_LIGHT`: the engine's light loop
  keeps choosing the lights (their number, attenuation and shadow) and calls the snippet's `light(i, s, l)` for each
  one with a `LightSample l`, and its `ambient(i, s, ambientColor)` once (`FA_HAS_AMBIENT`); or the snippet defines
  `lighting(i, s)` (`FA_HAS_LIGHTING`), the whole loop, and the template declares `fa_light_count()`, `fa_light(n, i)`,
  `fa_light_unshadowed()`, `fa_light_shadow()` and `fa_sky_light()` before the snippet (stubs in the shadow and prepass
  programs); the cap of 1024 lights (32 directional) and their order are `select_lights`' (CUSTOM_SHADERS_PACKAGES.md, P14); a fragment reads the lights of its cluster (ARCHITECTURE_RENDERING_LIGHTING.md, "Clustered lights").
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
- *Sky environment.* A scene with a valid sky material (`SceneSettings.skyMaterial`) bakes that sky into two small cube images
  (`renderer_env.{h,cpp}`, a "sky-env" pass of the graph, shared by the jobs of the frame) that the mesh shaders read for the ambient
  and the reflection light; no sky material, no pass and no environment image, only a 1x1 black cube and a sampler that fill the slot
  (`docs/design/CUSTOM_SHADERS_KINDS.md`, "The sky material lights the meshes").
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
  glow (`hud-over-bloom`, with `PostProcess.bloomScreenSpace = false`), per camera of the frame the exposure measure (`camera:<i>/exposure-luma`,
  `camera:<i>/exposure-adapt`), the final pass (`post` of each camera over its own rectangle, plus `post-base` when no camera's pass
  covers the whole picture first), the HUD over it (`hud-over-post`), the colour filter (`color-filter`) and, where the backend
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
  `make_target`) makes them on the first frame and hands the same ones out on the next. Only the last job declares the
  frame's bloom and final passes (a camera's prepass, coverage and exposure measure are its own job's), so N views of the same size need no more transients than one, and two jobs never share a transient alive at
  the same time (the planner aliases only resources whose uses do not overlap). A transient's contents are UNDEFINED at
  its first writer: that pass must CLEAR it or DONTCARE and cover every pixel, never LOAD it. `execute` gives back every
  transient on every way out (an error or a pass that throws). A bloom whose targets cannot be made warns once and
  draws no glow until the size or the format changes, so a failed creation is not retried every frame.
  `FrameGraph::set_import_handle` rebinds an imported resource to another image without a new compile. Not graph passes
  yet: the read-back copies. The render tests reach the graph of the last frame and the pool's counters through
  `render::renderer_frame_graph` and `render::renderer_transient_stats` (the test accessors live in `src/renderer_test_access.h`, behind the one friend `RendererTestAccess`; the public `renderer.h` has none). *What a pass cost:* `execute` times every
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
(`d3dcompiler_47.dll` loaded with `LoadLibrary`), stores the DXBC and hands sokol the bytecode next time (with no cache folder it still compiles each stage itself, without storing it). Its flags are sokol's (column-major matrices, `OPTIMIZATION_LEVEL3`) plus `PREFER_FLOW_CONTROL`: without it the compiler flattens the branches of the 3D lighting and on some custom materials recurses until its stack overflows. The key is
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



## PostProcess (M71)

The linear HDR frame, the `PostProcess` stack, its CPU resolve and the passes that draw it are on the page
[rendering, the PostProcess stack](ARCHITECTURE_POSTPROCESS.md); the effects, one bullet each, are on
[rendering, the post-processing effects](ARCHITECTURE_RENDERING_POST.md).

- **The 2D global illumination field** (M74.3: the emission, occluder and distance images of a 2D camera and the contract the radiance cascades read) is on the page [rendering, the 2D GI field](ARCHITECTURE_RENDERING_GI2D.md).
- **The lighting of M73** (shader files, texture slot table, feature rows, new fields) is on the page [rendering, the lighting of M73](ARCHITECTURE_RENDERING_LIGHTING.md).
