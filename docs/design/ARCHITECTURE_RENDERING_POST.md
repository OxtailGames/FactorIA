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
`src/metalfx.cpp`) wraps Apple's `MTLFXSpatialScaler` and `MTLFXTemporalScaler` over sokol images. It is a building block: the `metalfx`
upscaler mode that calls it from `present()` is a later package. What exists and what it costs:

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
  2. *`MTLEvent` / `MTLSharedEvent` between the buffers.* Signalling needs a buffer to encode into (the sokol one is out of reach), and a
     wait before the sokol buffer is committed deadlocks the queue (an enqueued, uncommitted buffer blocks everything behind it). Rejected.
  3. *The encoder's buffer through a private selector.* Not public API; breaks with an OS update. Rejected.
  4. *Split the frame with `sg_commit()`* (chosen). `Scaler::encode` calls `sg_commit()`: the sokol buffer with the passes so far (the scene)
     is committed; the own buffer, made after it, is enqueued behind it and committed; the next sokol pass makes a new buffer, enqueued behind
     the MetalFX one. One in-order queue, so the scaler reads this frame's colour and the later passes read this frame's output; sokol's
     resources are hazard tracked, so no fence or event is needed. A mid-frame `sg_commit` is something the renderer already does (a full
     transient pool, read-backs, `gi2d`). The test `metalfx: a pass that writes the input and a pass that reads the output in the same
     frame ...` queues twelve frames without waiting for the GPU, each with its own grey, and checks every frame shows its own grey; with
     the `sg_commit()` taken out of `encode` all twelve frames show the wrong picture.
- **Cost of the split** (per frame that upscales): one more `sg_commit` (one more sokol command buffer, its garbage collection and uniform
  buffer rotation) and one command buffer of the scaler; no semaphore of our own. sokol's semaphore counts its own two buffers in flight
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

## Motion vectors and jitter (M76)

M76 adds temporal antialiasing (drawn since M76-P2, "Temporal antialiasing" below) and the open upscalers. The shared part
is the jitter of the projection, the velocity contract the temporal passes read, and the data they keep from one frame to
the next.

- **Jitter (`include/fa/scene/jitter.h`, `src/jitter.cpp`).** `jitter_offset_pixels(frame, phases)` is the Halton(2,3)
  point number `frame % phases + 1`, minus 0.5, in pixels of the **render** resolution (x to the right, y down; `phases` is
  8 by default and clamped to 1..16, `kJitterPhasesDefault`, `kJitterPhasesMax`). It depends on the frame index only
  (`postSerial`, the game frames counted by the renderer), never on a clock, so a replay jitters the same way.
  `jitter_pixels_to_ndc` turns it into the clip-space shift `(2 jx / W, -2 jy / H)`.
- **Which matrices are jittered.** `CameraGeometry` (`camera_geometry.h`) keeps `proj`, `viewProj` and `invViewProj` **unjittered**
  and adds `drawProj` and `drawViewProj` (= the unjittered ones until `apply_jitter` runs). Only the draw sites use the drawn
  ones: the `fa_view_proj` uniform of the mesh programs, the contact shadows, the light volumes, the world's quad batches, the
  debug lines. Everything that asks a question about the world stays unjittered: culling, picking, `world_to_screen`, the
  `query*` matrices, the cluster grid, the Hi-Z pyramid and occlusion, the terrain and foliage culling, the environment
  bake and the screen-space effects that rebuild a position from the prepass (ssao, ssr, fog, depth of field, Hi-Z).
  **The sky and the HDRI jitter with the meshes**: their fullscreen pass inverts `CameraGeometry::drawInvViewProj` (the
  inverse of `drawViewProj`; equal to `invViewProj` while the jitter is 0), so the horizon of a mesh scene is resolved like
  its edges and a bright HDRI does not shimmer against them. Nothing "undoes" the jitter afterwards: the resolve reads the
  jitter of the frame (`TaaPlan::jitterPx`) and samples the current picture at the unjittered position.
- **When the renderer jitters (`Impl::jitter_phases`).** Only when the camera is one of the game's frame (a `CameraView`, a
  render-target camera and a `camera.capture` are built with a view size and are never jittered: nothing would resolve them),
  its stack has `TemporalAA` on, the effect is drawable (`post_drawn_mask`) and `TaaFx` is usable (its shaders compiled and no
  history was refused: `TaaFx::unavailable`), or when a test forces it with `RendererTestAccess::force_jitter(r, phases)`
  (0 returns to the rule); `RendererTestAccess::last_jitter` reads what each camera of the last frame used. Without jitter the
  drawn matrices are the unjittered ones, bit for bit, and the frame is the one of M75.
- **What a camera keeps (`PrevCamera`).** The previous frame's `prevViewProj` (unjittered), `jittered` (viewProj with the jitter of
  that frame) and `jitterPx`, and the same three of the frame before (`before*`). `origin_shifted` multiplies the matrices of both
  by the same shift as `prevViewProj`, so a floating-origin move does not read as motion. `PostPlan` carries them as
  `prevJitteredViewProj`, `jitterPx`, `jitterNdc`, `prevJitterPx`, `prevJitterNdc`.
- **The velocity contract (`VelocityRef` in `src/postprocess.h`; written by the velocity pass of M76-P1a, read by the temporal passes).** An optional RG16F image at the render
  resolution, `PostPlan::velocity`. Each texel holds `uvPrev - uvCurr` in UV units (so `uvPrev = uvCurr + velocity`),
  computed from the **unjittered** current and previous matrices (`uvCurr` is the texel without jitter). The sentinel
  `VelocityRef::kNone` (1024, outside the half range of any real motion; `is_none` is true for it, for NaN and for a
  magnitude of 512 or more) means "no object wrote here: reproject from the depth with the camera's matrices". Motion
  above `kMaxMotion` (4 UV) is not trusted by the temporal passes. The image is optional: a pass that finds none
  reprojects every texel from the depth, which is right for everything static.
- **Settings and rows.** The upscaler settings (`UpscalerSettings`, `render/upscaler.h`) are stored and reported only;
  `effective_upscaler_mode` is the one place that will say which mode draws (today always `stretch`). `render.supports`
  has the rows `motionVectors`, `spatialUpscaler`, `temporalUpscaler`, `metalfx`, `dynamicResolution` (planned M76); `temporalAA` is
  the row of the effect itself (`PostEffect::TemporalAA`, supported on every backend), not a second engine row.

### Temporal antialiasing (`src/renderer_taa.h`, `shaders/taa.glsl`, `shaders/taa_shared.glsl`)

- **Passes.** `TaaFx::add_passes` declares two fragment passes per camera in the frame graph, at the `TemporalAA` slot of the
  post stack (after the sun shafts and the custom passes `after:ssr`, before depth of field and motion blur, the bloom and the
  final pass): `taa-resolve` (picture + prepass + velocity + history -> the next history image) and `taa-output` (history ->
  the camera's rectangle of the picture, sharpened by `temporalAASharpen`; it writes RGB only, so the picture's alpha stays;
  the history itself is not sharpened, or it would sharpen again at every frame). Render resolution, every backend, never
  compute. `hudAfterBloom` counts the effect, so the HUD is drawn over the resolved picture. With the effect off none of this
  exists: no pass, no image, no jitter, and the frame is bit for bit the one without it (a test compares them).
- **History.** One ping-pong pair of images per camera (`TaaFx::Slot`, keyed by the camera entity), the size of the camera's
  rectangle, RGBA16F (rgb = colour, a = the linear depth of the pixel, for the depth rejection) or RGBA8 where the GPU cannot
  render to, sample and filter half floats (rgb only, a note in the log once; no depth rejection, colours above 1 clipped).
  The budget is 1 GiB (256 MiB on wasm32), computed in saturated 64-bit before anything is allocated; a refused history logs once
  and makes `unavailable()` true, so cameras stop being jittered for a pass that does not run. A camera that did not plan a
  frame loses its history (`sweep`).
- **Resolve (`taa_resolve` in `taa_shared.glsl`).** The 3x3 neighbourhood of the unjittered position (Gaussian weights) gives a
  mean and a deviation in YCoCg; the sample with the closest depth in it picks the motion: the velocity when the pixel has one
  (`VelocityRef`, not `is_none`), else the camera's own movement from the prepass depth through `prevFromView`
  (`prevViewProj * view^-1`, the unjittered matrices of `PrevCamera`). The prepass is drawn with the **jittered** matrix, so the
  current depth is read at the unjittered texel. The history is read with a 5-tap Catmull-Rom filter, its depth is compared with
  the reprojected depth (a pixel the surface uncovered has another one: smoothstep over a relative difference of 0.08 to 0.2;
  skipped where the velocity is known), the colour is clipped to a box of `temporalAAVarianceGamma` deviations around the mean,
  and the mix keeps `temporalAAFeedback` of the history, less where the reactive mask is set (scaled by
  `temporalAAReactiveScale`; no mask is bound today, a caller of `TaaFx::resolve` can pass one). The colours are squeezed so that
  the largest channel is unchanged up to 1 and goes to 2 - 1/m above it: an edge of 50% coverage averages to 50% (the picture
  converges to the supersampled one), a very bright pixel cannot outweigh its neighbours.
- **The history starts again** (the frame shows its own jittered picture alone and a new history begins; `TaaFx::resets()` counts
  it) on: a **cut** (`PostPlan::prevValid` false: the camera did not draw the frame before, the world clock went back or jumped
  more than 8 ticks, a non-finite matrix), a **resize** or a **render-scale change** (the images have another size; the
  renderer's `destroy_targets` also forgets them), a **floating-origin shift** (any rebase: the shifted previous matrix has a float
  error larger than a pixel for near geometry; one frame without antialiasing), a **frame the effect did not run for the
  camera** (it was off, another camera drew), another **scene** (`scene_path` and `scene_generation`), and a stack that **lost the
  effect**. A change of `temporalAAFeedback`, `Sharpen`, `VarianceGamma` or `ReactiveScale` does not reset: it applies from the
  next frame.
- **Not antialiased.** `CameraView`, render-target and `camera.capture` cameras (no post stack is declared for a view job, and they are
  built with a view size, so they are not jittered), the frames of `capture_world` (`framePost` false: they neither read nor
  write a history and are not jittered). The editor's viewport draws like the game (it is the same renderer, its camera has the
  stack), except where the editor bypasses the stack (`postBypass`): no effect, no jitter.
- **Shared with the temporal upscaler (M76-P4).** `taa_shared.glsl` holds the whole resolve with the input size and the history size
  as separate arguments (`taa_resolve(uv, inSize, outSize, jitter)`), and `TaaFx::resolve(gpu, pass, TaaResolveInput)` draws it with
  `inW/inH` (the picture) and `outW/outH` (the history and the target). The antialiasing calls it with both equal.
