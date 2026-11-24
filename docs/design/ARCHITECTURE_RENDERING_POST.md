# FactorIA architecture: rendering, the post-processing effects

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page). The shared part of M71 (the linear colour, the
`PostProcess` data, the effect order, the CPU resolve, `render.supports`, the commands, the stack's passes and the final pass) is on
the [rendering page](ARCHITECTURE_RENDERING.md#postprocess-m71); this page has the effects that use them, one bullet
each.

## PostProcess effects (M71)

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
- **Radial blur and the transient screen effects (M71-C3b; `scene/screen_fx.h`, `post_fx.{h,cpp}`, `post.glsl`).** Bits 4096 (shockwave),
  8192 (heat haze), 16384 (radial blur) and 32768 (flash / fade overlay) of `PostFx::mask()`. The radial blur is the `radialBlur*`
  fields of the stack and `render.supports` says it is drawn (`effect_drawn`); the other four have no field: they are the live
  `ScreenFx` of `World::feel().screenFx` (`scene`, `feel_update` advances them on the feel clock, `World::clear` drops them, `feel.cpp`
  runs the actions). `build_camera` copies the ones of a camera (`CameraInfo::screenFx`: its own, or the ones with no camera when it is not a render target),
  `make_post_plan` calls `add_screen_fx(fx, effects, queryViewProj)`, which turns them into uniforms in the camera's own coordinates
  (world centres projected by `queryViewProj`, dropped behind a perspective camera): the newest 4 rings (`sw[8]`, two vec4 each), 2 hazes
  (`hz[4]`), one radial blur (the PostProcess one and the pulses: the larger intensity wins, `rb`) and one overlay colour (`ov`: flash
  and fade, composited oldest first). A camera with none of them and no stack makes no plan, so a frame without effects is unchanged. The shader reads the scene through
  `read_scene`, which first adds `shock_offset` and `haze_offset` to the screen position (the displacement is part of where the whole
  pass reads, like the lens), the radial blur averages `samples` taps along the line to the centre, and the overlay is `mix(c,
  ov.rgb, ov.a)` after the grain and before the dither and the colour filter. A PostProcess is not needed: `plan.fx.any()` makes the
  final pass. The CPU mirrors (`shockwave_offset`, `haze_offset`, `radial_blur_taps`, `overlay_color` in `post_fx.cpp`) are what `screen_fx_render_tests.cpp`
  compares the read-back pixels with.
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
  to the aux texel by `ax` (scale xy: always 1, the prepass has the size of the camera's rectangle and the pass is in camera-local coordinates) and flips the row on a bottom-up
  backend (`ex.y`), because the prepass is drawn by the same camera as the game image and has the same orientation. `postprocess.cpp`
  drops the outline bit from the prepass read mask unless the resolved stack's outline is depth mode and on, so a sprite outline never
  makes a prepass; `plan_outline` calls `PostPlan::skip_outline()` (it clears `fx.outline` and recomputes `linear`, so the plan may
  drop the final pass altogether) when `plan_prepass` made none (`prepassWarned`: one error when the pool cannot make the image).
  *Sprite outline: the decision.* The three possible sources of the sprites' alpha were the game image's alpha, a coverage render and
  an edge detection on colour. The game image's alpha is useless (the clear colour has alpha 1 and a float scene has no usable alpha on
  R11G11B10), and colour edges find the borders of 3D and of the background as well as the sprites'. So when a sprite outline is on,
  `plan_outline` has the camera's job declare one more transient pass, `<job>/sprite-coverage` (`PostPlan::coverage`): an RGBA8 image of the camera's rectangle,
  one sample, no depth, cleared to 0, drawn by `draw_group` with the world's quad batches (`ctx.gWorld.batches`, camera `viewProj`, no depth
  test, `flatMode` 0 so no lights) and `TargetFormat` of its own (`draw_group` takes the format, since quad pipelines are made for the
  scene format by default). Alpha blending accumulates the union of the coverage in `.a`; additive and multiply blends leave `.a`
  alone; the `.rgb` is not used. The final pass reads it as `aux_tex` and draws the line outside the border: a pixel with `a >= ol.w` is
  untouched, any other pixel with such a texel in a ring of 8 taps at `round(width)` (and one at half of it for a thin sprite) takes the
  colour. Cost: per camera with the effect, one RGBA8 target of its rectangle and one more draw of its 2D world; it is declared for every
  camera job that draws the world, and only when the pool could make the image (else `coverageWarned`: one warning, that camera's outline
  is dropped). 3D meshes are not in it (a mesh is not "a sprite"), nor the clear colour, nor the
  screen-space items (the HUD is drawn after the final pass).
- **Ambient occlusion (M71-D1; `src/renderer_ssao.{h,cpp}`, `shaders/ssao.glsl`).** `PostPlan::ssao` (`ssao_from_stack`: quality 0..3,
  intensity 0..4, radius 0..20, off at intensity 0 or radius < 0.001) is what `make_post_plan` takes from the stack (not from `forceEffects`),
  and it asks for the prepass. `Ssao::add_passes` declares, per camera, right after its `<job>/prepass` and BEFORE its main pass, `<job>/ssao-ao` (GTAO,
  half resolution at low and medium, full at high and ultra: 2, 3, 3, 5 directions, 3, 5, 6, 8 steps), `ssao-blur-h` and `ssao-blur-v`
  (bilateral, the weights of the distance to the plane of the centre); the two RGBA16F images are transients of the graph
  (`<job>/ssao-a|b`). The apply is not a pass but a draw INSIDE the main pass (`Ssao::draw_apply`, called by `main_pass` between the opaque
  meshes and the blended ones, which is why the main pass lists the occlusion image and the prepass in its reads): a full-screen triangle over
  the camera's rectangle (viewport and scissor when it is a part of the picture), a multiply blend (`DST_COLOR`, `ZERO`) on the game image with
  the pipeline of the pass's own `TargetFormat` (so the same code runs with MSAA, reading the never multisampled prepass). The blended meshes,
  sprites, particles and text drawn after it, and the HUD, are not darkened; the bloom and the final pass see the darkened picture. The
  noise is a fixed 4x4 pattern: no random numbers. The three programs count uv and texel rows from the top of the camera's rectangle on
  every backend and flip only the texture fetches on OpenGL (`ssao_tex`): the texels of a half resolution image and the pattern fall on
  the same pixels everywhere, so OpenGL draws the picture Metal and D3D11 draw (counted from the bottom, a texel was computed at the
  lower row of its pair instead of the upper one and the pattern moved by a phase; with an odd height the pairs of rows themselves
  differed: the crease came out a row or two off). `cam.w` therefore means "OpenGL" and "every fetch is flipped" at once. A texel of the
  half resolution image is computed at the prepass pixel `2t` (the upper left of its block), and the apply's bilateral upsample puts it
  there too (a pixel `p` lies at `p / 2` in texel units; `(p + 0.5) / 2 - 0.5` would have put it half a pixel off, towards the lower
  right, on every backend). `DebugView::Ao` makes the same draw write the grey (`SsaoStage::View`) instead. The
  effect is skipped, with one warning, where the GPU has no RGBA16F target that blends and filters.
- **Depth and normal prepass** (`Renderer::Impl::plan_prepass`, `prepass_pass`, `prepass_view_pass` in `renderer_draw.cpp`). A pass
  of every camera job's graph that needs one, declared before "main" as `<job>/prepass`, with a transient of its own (`PostPlan::prepass`, a `PrepassRef` the effects that read
  it list in their reads; the pass is `GraphPass::sideEffect` because nothing reads it until an effect or the debug view does). One
  float image (`Gpu::prepass_color_format`: `RGBA32F`, else `RGBA16F`, else none and `prepass_ready()` is false, which is also what
  `render.supports` `sampledDepth` answers) with its own depth buffer, never multisampled: r = linear view depth in world units
  (cleared to `PrepassRef::kFarDepth` = 60000), gb = octahedral view-space normal, a = coverage. A multisampled depth cannot be sampled
  and depth is not a quantity to average across samples, so the effects read one sample per pixel. The programs `prepass` and
  `prepass_skin` of `mesh_common.glsl` reuse the mesh vertex stage (instancing, skinning, `vertex()`), run `surface()` (so the normal is the
  one the main pass lights with) and discard below `alphaCutoff` with `FA_ALPHA_CLIP`, like the shadow programs; they read the camera's view matrix through the slot the shadow programs use for the
  light's (`fa_light_vp`). The pass draws `opaqueBatches` with the same instance rows as the main pass, so its draw calls are one per
  batch part; a material twin without `prepass` programs (made before this version) falls back to the engine's program and draws its
  mesh without the material. `plan_prepass` is the only decision: the job is not a view, draws the world with at least one pixel, the camera's own
  resolved stack needs the depth or the normals (`post_mask_needs_depth` / `post_mask_needs_normals` of `postprocess_resolve.h`, masked
  by `post_drawn_mask()` so an effect the renderer does not draw yet costs nothing) or a debug view is on, it has an opaque mesh, and a
  pooled image of the size of the camera's rectangle (`ctx.camPx`) could be made (else one error and no prepass). A split screen
  therefore has one prepass per camera that asks, each the size of its own viewport, and the camera's final pass reads it by camera-local
  coordinates. `Impl::prevViewProj` keeps each camera's view-projection of the frame before (by entity,
  with the frame serial, forgotten after a frame without it) for `PostPlan::prevViewProj` and `prevValid`, which the motion blur reads (`SceneFx::plan`: no previous frame, no blur). Tests force an
  effect with `render::renderer_force_post_effects`; `Renderer::set_debug_view` (and `FA_RENDER_DEBUG_VIEW`) adds the "prepass-view"
  pass, which draws `prepass_view.glsl` over the game image (the main pass then keeps its multisampled colour). The tests read the image
  through that view because only RGBA8 can be read back.
- **Depth of field and motion blur** (`src/renderer_dof.*`, `shaders/dof.glsl`, `motion_blur.glsl`). `SceneFx` (a member of `Impl`) plans
  per camera in `plan_job` (`PostPlan::sceneFx`: the clamped numbers, the autofocus, the previous-frame matrices) and `build_graph`
  declares its passes (`add_passes`) before the bloom, so they work on the scene colour: with a stack that has them `plan_job` makes the
  HUD draw after the post stack (as `hudAfterBloom`), and the passes write the unresolved colour attachment or the resolved one as the
  bloom does. A pass cannot read what it writes, so the chain goes through one scratch transient and ends with a copy (or the last
  effect writes the picture itself). The focus per camera is state of `SceneFx` keyed by the camera entity, moved by the engine clock
  (`smooth_focus`), never by wall time. It owns its shaders and pipelines (made on first use, `release()` on shutdown).
  **Per-object motion blur (M76-P1e, `shaders/motion_object.glsl`).** `PostProcess.motionBlurMode` `object` (the default; `SceneFxPlan::objects`)
  draws, instead of the one `motion-blur` pass, `motion-velocity` (reads `PostPlan::velocity` and the prepass: writes RGBA16F `rg` = the
  blur vector in pixels = `uvPrev - uvCurr` times the shutter cut to the longest streak, `b` = the linear depth; where the velocity is the sentinel
  it rebuilds the camera's motion from the depth exactly as `motion_blur.glsl`), `motion-tile-x` and `motion-tile-y` (the longest vector
  of every K x K block, K = the clamped radius in pixels, `SceneFxPlan::maxRadiusPx`, in two passes) and `motion-blur` (the gather: the longest
  vector of the 3 x 3 blocks gives the line, the pixel's own vector a second line; the McGuire weights, `cone` and `cylinder`, up to 32
  taps, `motionBlurSamples` at most). It runs after the temporal antialiasing and the `after:shafts` custom passes, on the render-size
  image, and so before the temporal upscaler resolves; the velocity image is unjittered, so the jitter never reaches the blur. It needs the
  velocity image (`velocity.valid()`), its three programs (`ready_objects`, lazily made, one `FA_ERROR` on failure) and an RGBA16F transient
  for each of the three intermediates; missing any of them the frame draws the camera path (`objects` false), so a GPU that cannot do it
  loses the object blur only. `make_post_plan` calls `request_velocity()` for a drawn motion blur in object mode with an intensity above 0,
  on the first frame and a cut too (the previous models of the objects are kept only on frames that asked). The camera mode and the effect
  off request nothing and build none of this: their frames are bit-identical to before (tested).
- **Fog and sun shafts** (`src/renderer_fog.*`, `shaders/fog.glsl`, `sun_shafts.glsl`). `FogFx` (a member of `Impl`) owns the shaders and
  pipelines; `make_fog_plan` is pure CPU (clamped numbers, the sun's screen place from `sun_screen_position`). `plan_job` plans it right after
  `collect_lights` and before `plan_prepass`: the sun is slot 0 of `select_lights` when that is a directional light that shines, and shafts with
  no sun in view drop their prepass bits (`PostPlan::readMask`); after the prepass the plan is emptied when the prepass or a shader is
  missing, so only a fog that will draw (`fogFx.fog`) turns `SceneSettings.fogDensity` off (`scene_uniforms`): never both. The fog is a draw
  inside the main pass, like the ambient occlusion's apply (`FogFx::draw_fog`, after the apply and before the blended meshes): it reads only
  the prepass and blends `fogColor * f` with alpha `f` (no scratch copy), so it fogs the opaque meshes by their own depth and leaves the sky.
  What is drawn after it fogs itself with the same numbers and formula: the blended meshes through `fa_fog` / `fa_fog_b` / `fa_fog_c` of
  `mesh_common.glsl` (`DrawContext::fuBlend`, the scene's uniforms plus the stack's fog; the opaque batches keep `fuScene`, with no fog) and
  the quads of the world (sprites, particles, 3D text) through `fog_col` / `fog_b` / `fog_c` / `fog_eye` of `quad.glsl` (`draw_group`'s
  `fog` argument; a batch under fog uses the full quad program, an alpha batch fades to the fog colour, an additive one to 0 and a
  multiplying one to 1). `shafts-rays` makes the half resolution rays and `shafts-add` adds them; they run after the SSR passes and
  before the depth of field, on the same destination as the bloom. A camera with only fog forces no `hudAfterBloom`: only shafts, SSR,
  depth of field and motion blur do, because they work on the picture after the main pass.

## MetalFX (M76)

`src/metalfx.h` (`fa::render::metalfx`; the Metal side is `src/metalfx_apple.mm`, every other backend builds the stubs of
`src/metalfx.cpp`) wraps Apple's `MTLFXSpatialScaler` and `MTLFXTemporalScaler` over sokol images. The `metalfx` upscaler mode
(M76-P5b, "The renderer's MetalFX stage" below) calls it from `run_upscale`. What exists and what it costs:

- **Support** (`support()`). The framework is loaded at run time (`NSBundle`, classes by name), so nothing links against it and a player starts
  on an OS without it; an SDK without the headers builds the same "not available" answer. `Support` has `spatial` and `temporal` (each from
  `supportsDevice:`) and a `reason` that teaches: macOS 13 / iOS 16 needed, the iOS simulator has none, an old GPU, a build without the SDK, the
  OpenGL backend (`FA_GFX_BACKEND`) or any non-Metal backend. The project's iOS deployment target is 16.3 and macOS has none set (it builds for
  the host), so the checks are `@available(macOS 13.0, iOS 16.0, *)` plus the class lookup; nothing is weak linked.
- **Images.** `color`, `depth` and `motion` are any sokol images of the sizes and formats of the `Desc` (sampled only). `output` is written by
  MetalFX: it needs `usage.color_attachment` and `usage.storage_image` (`MTLTextureUsageRenderTarget | ShaderWrite`; the spatial scaler asks
  only for the first, the temporal one for both, so the wrapper asks for both) and an ordinary texture view for the passes that read it.
  `encode` checks sizes, formats, usage and sample count BEFORE it does any work, and its errors say what to change.
- **The ordering problem.** MetalFX encodes into an `MTLCommandBuffer`. sokol makes the frame's buffer at its first pass
  (`_sg_mtl_acquire_cmd_buffer`, which also `enqueue`s it on the queue) and commits it in `sg_commit`; it exposes the queue, the device and
  the current render or compute ENCODER (`sg_mtl_*`), never the buffer, and an encoder has no public way back to its buffer. The scene colour
  is written by passes of that buffer and the output is read by passes after it, in the same frame. Options, all without editing `external/`:
  1. *Own buffer, committed at the end of the frame.* The queue runs buffers in the order they were enqueued, and sokol's was enqueued at its
     first pass: the own buffer runs after the whole frame, so the passes that read the output see the PREVIOUS frame's picture. Correct only
     with a frame of latency and the HUD drawn from the old picture. Rejected.
  2. *`MTLEvent` / `MTLSharedEvent` between the buffers* (used, together with option 4). Signalling needs a buffer to encode into, and sokol's is
     out of reach through its public API; but its implementation is compiled in engine code (`engine/platform/src/sokol_impl_apple.m`), which
     exposes `fa_sg_mtl_command_buffer()` (it closes sokol's open blit encoder, acquires the frame's buffer if there is none and returns it).
     An event signalled from a separate, empty buffer orders nothing (a buffer behind another one does not wait for it), so the signal is
     encoded inside sokol's own buffer. A wait inside a buffer that is committed before the one that signals would deadlock the queue (an
     enqueued, uncommitted buffer blocks everything behind it), so every wait is in a buffer whose signal is already committed or in flight.
  3. *The encoder's buffer through a private selector.* Not public API; breaks with an OS update. Rejected.
  4. *Split the frame with `sg_commit()`, order the buffers with shared events and take the later buffer at once* (chosen). `Scaler::encode`
     takes sokol's buffer of the passes so far (`fa_sg_mtl_command_buffer`), encodes a signal of event value A in it, adds a completion
     handler that raises the event to A (a buffer that fails does not signal), and calls `sg_commit()`. The MetalFX buffer waits for A,
     runs, and signals B at its end (its completion handler also raises the event to B). Then `encode` takes sokol's buffer of the passes after
     it right away, which sokol would otherwise do at their first pass, and encodes a wait for B in it; it is left open for the HUD and the
     present, and a completion handler keeps the event alive (sokol's buffers hold resources unretained). A mid-frame `sg_commit` is something
     the renderer already does (a full transient pool, read-backs, `gi2d`). What the tests catch and what they do not: the test "frames queued
     without waiting for the GPU" (below) fails with the old code and passes with the early take alone, so it does NOT catch the events being
     removed: the events rest on Metal's contract, not on a test. The failure path (a MetalFX buffer that finishes with an error, whose handler
     raises the event) has one (POL-METALFX, "Failure and clean-up" below). The test `metalfx: a pass that writes the input and a pass that reads the output in the same
     frame ...` queues twelve frames without waiting for the GPU, each with its own grey, and checks every frame shows its own grey; with
     the `sg_commit()` taken out of `encode` all twelve frames show the wrong picture.
- **Cost of the split** (per frame that upscales): one more `sg_commit` (one more sokol command buffer, its garbage collection and uniform
  buffer rotation) and one command buffer of the scaler; no semaphore of our own, and two shared events values per frame. sokol's semaphore counts its own two buffers in flight
  (`SG_NUM_INFLIGHT_FRAMES`), so with two buffers per frame the CPU may run about one frame ahead of the GPU instead of two. `encode` does
  not tell `Gpu::note_commit()`: the commit listener counts it (`Gpu::frame()` moves on) and the frame still has work to come, so the pool of
  transient buffers keeps going (a buffer acquired before the split stays valid after it: its active slot rotates only when it is written
  again). It must be called outside a pass.
- **Jitter and motion** (temporal). `Frame::jitterX/Y` is how far the drawn picture was moved, in render pixels, right and down the image: a
  scene sampled at `(x + jx, y + jy)` passes `-jx, -jy`. The test runs both signs on a still scene: the documented one converges to 0.0007
  (mean error, 0..1) after 16 frames, the opposite one to 0.006. The temporal scaler is made with `requiresSynchronousInitialization` so
  its first frame is already scaled; the price is a hitch when it is made (at start and on a resize).
- **Limits.** `configure` refuses an output smaller than the input and formats outside the list in `metalfx_apple.mm`; MetalFX itself limits
  the ratio (the error says so). A scaler made again on a resize starts its history again.
- **Motion convention.** The motion image is UV units from the pixel to where it was (`uvPrev - uvCurr`), `motionScaleX/Y` the render size in
  pixels; `metalfx: the temporal scaler follows a moving pattern ...` shows the right sign beats the opposite and none. The wrapper's
  `Gpu::committed` flag is false after the split (`encode` does not call `note_commit`); code that asks it mid-frame must not rely on it.

### The renderer's MetalFX stage (M76-P5b)

`UpscaleImpl::MetalFx` (`render_upscale.h`) is the first case of `run_upscale`; the code is `src/renderer_metalfx.cpp`
(`Impl::metalfx_upscale`), the preparation program `shaders/upscale_mfx.glsl` (Metal dialects only; `src/render_upscale_metalfx.*`, class
`MetalFxPrep`) and the tests `metalfx_renderer_tests.cpp` (they skip with a MESSAGE where MetalFX is missing) and the P5b cases of
`upscale_tests.cpp`.

- **Which frame.** `Renderer::render` decides, with the rest of the upscale frame, `mfxFrame` (effective mode MetalFx with the temporal
  scaler, `UpscalerCaps::metalfxTemporal`, and the TAA shaders for the fallback) and `outStorage` (the upscale output image is made with
  `TargetDesc::storage`, `usage.storage_image`, which the temporal scaler writes). The jittered frame is the temporal upscaler's (same
  phases, `TaaPlan`); a frame of several cameras draws the spatial upscaler (`effective_upscaler_mode`: `metalfx_ok = caps.metalfx &&
  (!multiCamera || !metalfxTemporal)`). A GPU with the spatial scaler only draws an unjittered frame through it.
- **Preparation pass.** One pass at the render size (`upscale-metalfx-prep`, two colour targets): `R32F` depth `d/(d+1)` from the prepass
  (1 for the sky and for pixels without coverage) and `RG16F` motion from the velocity image, or, where it holds the sentinel
  (`VelocityRef::kNone`) or there is none, the camera's reprojection from the depth with the matrices of `TaaPlan` (`prevFromView`, `proj`) as
  `taa_resolve` does. The uniform `motionSign` (`mfxMotionSign`, default 1, tests only) flips it. `Frame::jitterX/Y` are `jitterPx *
  mfxJitterSign`, the motion scale the render size.
- **History.** `f.reset` is `!histValid` with `histValid` = a MetalFX frame just before (`mfxLastSerial + 1 == upscaleTaa.serial`), the same
  `sceneKey`, `originShifts` and render size and quality (`mfxLastConfig`), and `upscaleTaa.prevValid`; a new scaler resets itself. These are
  the events of `TaaFx::upscale`. `RendererTestAccess::mfx_reset/mfx_generation/mfx_encoded` expose them.
- **Failure.** `metalfx_fail` (a scaler that cannot be made, `encode` that fails, the prep shader that does not compile) sets `mfxFailed`: one
  warning, and `run_upscale` falls to the temporal upscaler, then the spatial one, for the rest of the run; `upscaler_caps().metalfx` is
  then false so `effectiveMode` says it. `mfx_force_create_failure` is the test hook.
- **Velocity ordering (a fix).** The velocity image is asked for (`PostPlan::request_velocity`) before `cull_and_batch`, which decides whether
  the draws collect their previous models; before P5b it was asked after, and the temporal upscaler alone never had object motion.
- **Headless.** Without a renderer `Engine::upscaler_caps` uses `metalfx_available_here()` (the system is asked, no window): `render.upscaler`
  reports `metalfx` for `auto` and `metalfx` on an Apple build where it is available (the P4 rule for `temporal`).
- **Proof of the motion (P5c).** `metalfx_tests.cpp` proves the sign in x and in y with the wrapper alone; `metalfx_renderer_tests.cpp` proves it in
  the renderer with a stripe texture that moves under a camera that pans and pitches (right sign under 0.8 times the error of the opposite one or
  none), reads the prep pass back (`RendererTestAccess::mfx_read_prep`: depth d/(d+1) and the UV motion at a pixel, against values worked out
  by hand) and checks that frames queued without waiting for the GPU give the same picture every time. The earlier "output does not depend on
  the sign" came from a race, not from the conventions: with the frame split in two sokol buffers (`Scaler::encode` calls `sg_commit`), the
  same frames queued without waiting for the GPU hashed differently from run to run. What was measured on an Apple GPU (the test "frames
  queued without waiting for the GPU", 4 repetitions of 2 and of 6 frames): without any of this it failed in nearly every run;
  a CPU wait for an empty buffer behind the earlier passes, a CPU wait for the MetalFX buffer and a 30 ms sleep all passed; a draining wait at
  the start of each frame, or a shared event signalled by an empty buffer, still failed (an event in a separate buffer does not wait for
  the buffers before it). What passes without any CPU wait, and is what the code does: `Scaler::encode` takes sokol's command buffer of the
  earlier passes (`fa_sg_mtl_command_buffer`, `engine/platform/src/sokol_impl_apple.m`: sokol hands out the encoder of a pass, never the
  buffer), has it signal a shared event, commits the frame, has the MetalFX buffer wait for the event and signal it again at its end, and
  takes sokol's buffer of the later passes right away (sokol takes it at their first pass) with a wait for that second signal. Taking the
  later buffer at once is what the test needed (8 of 8 and 10 of 10 runs passed with it alone, without the events; 7 of 8 failed without it and without the events); that it
  also has to be explicit in the GPU order is Metal's contract, and a failed buffer, which does not signal, signals from its completion
  handler so the queue cannot stall. The exact mechanism of the race was not isolated, so the test is what guards it. `encode` has no CPU wait of its own (taking sokol's buffer of the later passes at once can take sokol's frame semaphore, which only moves that wait earlier in the frame).
  The price of taking the later buffer at once: it is open and uncommitted after `encode`, and a command buffer queued behind it (a read back with
  its own buffer, `Device::read_image_rgba8`) would wait for it for ever, so `metalfx_upscale` calls `Gpu::note_work()` (a read back commits first) and the
  wrapper tests `sg_commit()` before they read back.
- **Failure and clean-up.** A MetalFX command buffer finishes on another thread: its completion handler sets an atomic flag (and keeps the
  message under a mutex) in a status shared with the scaler (`Scaler::command_failed`); `metalfx_upscale` reads it at the start of the next
  frame and calls `metalfx_fail` (one warning, the temporal upscaler from then on). `metalfx_fail` and any frame of another upscaler
  (`free_mfx_images`) destroy `mfxDepth` and `mfxMotion`; the preparation pass runs before `configure`, so a scaler MetalFX cannot make costs
  one preparation pass, once. `RendererTestAccess::mfx_force_support(spatial, temporal)` makes the renderer believe MetalFX is there, and
  `mfx_prep_only` stops after the preparation pass: with them every Metal GPU (the macOS CI VM, which has no MetalFX) runs the preparation
  shader, the creation failure with its one warning, the fall to the temporal upscaler and the clean-up; `mfx_images`, `mfx_last_wrote` and
  `mfx_read_prep` read the result.
  **The failure path is tested** (POL-METALFX) on any Metal GPU, with `Scaler::TestHooks` (`metalfx.h`): `emptyBuffers` makes a scaler that
  asks MetalFX for nothing (its buffers hold only the event wait and signal, so a GPU without MetalFX runs the whole ordering), `failBuffers`
  makes the buffer end as a failed one does: the completion handler reports an error and the buffer does **not** signal the event itself, so
  only the handler's `signal_at_least` releases the sokol buffer of the passes behind it. `Scaler::test_wait_signalled` waits for that event with
  a limit (and raises it itself when it times out, so a broken handler fails the test instead of hanging the queue); the tests are
  `metalfx: a command buffer that fails still releases ...` (wrapper, three rounds, a read back goes through the queue after each) and `metalfx
  renderer: a MetalFX command buffer that fails ...` (one warning, the temporal upscaler, the picture still drawn). With the handler's signal
  taken out both fail after the limit (checked). A real GPU error cannot be made on demand, so what the hook stands in for is the `status` of the
  buffer; the signal and the report are the production code.
- **The reactive mask (POL-METALFX).** `metalfx::Desc::reactiveMask` and `Frame::reactive` carry the renderer's R8 mask (`upscaleReactive`, the
  target of the camera's `PostPlan::reactive`, read by the `upscale` pass of a MetalFx frame as it is for the temporal one) to the
  `MTLFXTemporalScaler`: `reactiveMaskTextureEnabled` and `reactiveMaskTextureFormat` (R8Unorm) on the descriptor, `reactiveMaskTexture` on the
  scaler, all `macOS 14.4 / iOS 17.4` in the SDK (the descriptor's properties are marked so; the scaler's property sits in the base protocol
  without a mark, and is guarded by the same `@available`). **Always created with the input** (`metalfx_upscale` sets `d.reactiveMask` for the
  temporal kind), not made again when the first mask appears: the descriptor cannot change, a new scaler pays `requiresSynchronousInitialization`
  (a hitch) and drops its history in the very frame a particle appears, whereas a scaler with the input and no mask in the frame (`reactiveMaskTexture`
  nil) draws exactly as one made without it (`metalfx: a reactive mask ...` compares them). The mask is handed only when the frame has one
  (`upscaleReactive.target(c)` is null when no item asked: the pass does not exist then) and it is the render size and R8; else nil, and the
  wrapper refuses a mask of another size or format like any other image (`Frame.reactive ...`). On an older OS `reactiveOn` stays false: the
  descriptor is not touched, the frame's mask is ignored and `Scaler::reactive_mask()` says so. The engine's `temporalAAReactiveScale` is not applied
  (MetalFX takes the mask as is, 0 its own judgement, 1 no history); `Scaler::reactive_encoded()` and the test accessors
  `mfx_reactive_enabled`, `mfx_reactive_frames` and `mfx_no_reactive` (hand none: the contrast) show what was handed over.
