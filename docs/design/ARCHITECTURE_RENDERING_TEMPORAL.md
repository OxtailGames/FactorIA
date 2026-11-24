# FactorIA architecture: rendering, motion vectors and temporal antialiasing

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page). The post-processing effects and the MetalFX
wrapper are on the page [rendering, the post-processing effects](ARCHITECTURE_RENDERING_POST.md); the upscale stage that reads
this page's history is on the [rendering page](ARCHITECTURE_RENDERING.md). This page has the camera jitter, the velocity image
and who writes it, the temporal antialiasing resolve and the texture LOD bias that goes with it (M76).

## Motion vectors and jitter (M76)

M76 adds temporal antialiasing (drawn since M76-P2, "Temporal antialiasing" below) and the open upscalers. The shared part
is the jitter of the projection, the velocity image the temporal passes read (written by the depth prepass since M76-P1a,
see "Who writes the velocity"), and the data they keep from one frame to the next.

- **Jitter (`include/fa/scene/jitter.h`, `src/jitter.cpp`).** `jitter_offset_pixels(frame, phases)` is the Halton(2,3)
  point number `frame % phases + 1`, minus 0.5, in pixels of the **render** resolution (x to the right, y down; `phases` is
  8 by default and clamped to 1..128, `kJitterPhasesDefault`, `kJitterPhasesMax`). It depends on the frame index only
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
- **The velocity contract (`VelocityRef` in `src/postprocess.h`; written by the depth prepass since M76-P1a, read by the temporal passes).** An optional RG16F image at the render
  resolution, `PostPlan::velocity`. Each texel holds `uvPrev - uvCurr` in UV units (so `uvPrev = uvCurr + velocity`),
  computed from the **unjittered** current and previous matrices (`uvCurr` is the texel without jitter). The sentinel
  `VelocityRef::kNone` (1024, outside the half range of any real motion; `is_none` is true for it, for NaN and for a
  magnitude of 512 or more) means "no object wrote here: reproject from the depth with the camera's matrices". Motion
  above `kMaxMotion` (4 UV) is not trusted by the temporal passes. The image is optional: a pass that finds none
  reprojects every texel from the depth, which is right for everything static.
- **Settings and rows.** The upscaler settings (`UpscalerSettings`, `render/upscaler.h`) are read by the upscale stage (`Renderer::upscaler()`);
  `effective_upscaler_mode(settings, caps)` is the one place that says which mode draws: `stretch`, `spatial` (M76-P3b) and `temporal`
  (M76-P4); the caps carry the pixel-art flag, what the backend can draw (`temporal`: the TAA shaders compiled) and whether the frame has
  one camera (`multiCamera`), and `metalfx` / `metalfxTemporal` (M76-P5b, from `metalfx::support()` on Metal, false after a failure). A
  temporal mode that cannot run draws as `spatial`. `render.supports`
  has the rows `motionVectors` (drawn since M76-P1a), `spatialUpscaler` (drawn since M76-P3b), `temporalUpscaler` (drawn since M76-P4),
  `metalfx` (drawn since M76-P5b where Metal has it), `dynamicResolution` (drawn since M76-P6c: the controller lives in `render/dynamic_resolution.*`, the engine feeds it and multiplies its factor into `apply_render_scale`; the renderer remakes its targets at a step and keeps the temporal history of the base scale); `temporalAA` is the row of the effect itself (`PostEffect::TemporalAA`, supported on every
  backend), not a second engine row.

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
  `inW/inH` (the picture) and `outW/outH` (the history and the target). The antialiasing calls it with both equal; `TaaFx::upscale` calls it
  with the render size and the output size (docs/design/ARCHITECTURE_RENDERING.md, "Upscale stage (M76)"). When the picture is smaller than the output
  the Gaussian of the 3x3 gather narrows by the ratio of the areas (`kern`), so the sum over the phases is as sharp as an output pixel allows.
- **NaN and the sky.** A NaN sample of the picture is left out of the gather and the moments, a NaN texel of the history (found by its bits, so
  fast-math cannot drop the test) is dropped (keep 0) and the pixel restarts from the picture, so a NaN never stays in the history; and the
  depth rejection of the history is not applied to the sky (the pixels no mesh drew), whose depth changes with every turn of the camera.
  `kJitterPhasesMax` is 128 (the upscaler at a third of the size needs 72).

### Texture LOD bias (M76-P4b)

- **Where it is computed.** `Renderer::Impl::mip_bias` (renderer.cpp), called by `build_camera` right after `apply_jitter`, so only a
  camera that was jittered has a bias: `CameraInfo::mipBias`. The temporal upscaler frame (`temporalPhases > 0`, the one full-window main
  camera) takes `log2(physW / targetW) + offset`, the temporal antialiasing alone takes `offset`, a jitter a test forced (`jitterForce`)
  none. The offset is the stack's `temporalAAMipBias` (the camera's TemporalAA on; else the PostProcess default, -0.5), clamped to -2..0; the
  sum to -4..0. The camera is built every frame after the render size is known, so a dynamic-resolution step moves the bias with it.
- **How it reaches the shader.** No new uniform block and no layout change: the free `w` lane of `fa_env_horizon` in `fa_mesh_fs_params`
  (`mesh_common.glsl` and its copy in `mesh_full_common.glsl`) holds it, filled once per camera by `Renderer::Impl::scene_uniforms` (`fuScene`, so `fuBlend` and
  every `fill_fs` copy carry it) and set back to 0 by the shadow pass. A fragment-stage `#define fa_mip_bias (fa_env_horizon.w)` names it.
  GLSL ES 3.0 and WebGL2 have `texture(sampler, uv, bias)` in the fragment stage only, which is the only place it is used; sokol-shdc turns
  it into `SampleBias` (HLSL) and `bias()` (MSL).
- **Reads that take it.** `fa_standard_surface` (five maps), `fa_base_sample` of the full template, the graph's `texture`, `texture.normal`
  and `triplanar` nodes (`$mip_bias`: `fa_mip_bias` in a mesh graph, `0.0` in sprite and post graphs), `terrain.glsl` (it scales the
  `textureGrad` derivatives by `exp2(bias)`) and `impostor.glsl` (it adds to the explicit level). Not touched: `quad_common.glsl`
  (sprites, UI, text), the post passes, the shadow passes, the splat control maps. A twin made with another template is refused as before: the template
  hashes of the mesh and full templates changed, so the committed fixture twins were made again (`FA_UPDATE_FIXTURES=1`).
- **Off is the same picture.** A camera without a jitter has `mipBias` 0 and `texture(s, uv, 0.0)` samples as `texture(s, uv)`.

### Who writes the velocity (M76-P1a)

The readers of the image: the temporal antialiasing and the temporal upscaler (renderer_taa), and since M76-P1e the per-object motion blur
(`src/renderer_dof.cpp`, "Depth of field and motion blur" on the page
[rendering, the post-processing effects](ARCHITECTURE_RENDERING_POST.md)).

- **Asking.** There is one request: `PostPlan::request_velocity()`. `make_post_plan` calls it for an effect that needs the motion
  (`post_effect_needs_velocity`: the temporal antialiasing; `post_mask_needs_velocity` for a mask of effects), and
  `plan_job` calls it for the debug view `motionVectors` and for `RendererTestAccess::force_velocity`. When nothing asks, nothing
  changes: the prepass has one colour attachment, the batches carry no previous model, the frame is bit-identical to one without
  the feature (tested).
- **The image.** The prepass (`prepass_pass` in `renderer_draw.cpp`, the same pass that writes the normals and the depth) gets a
  second colour attachment `color1` of format RG16F (`Gpu::velocity_format()`), cleared to `kNone`, a transient `<camera>/velocity`
  in the frame graph (`PostPlan::velocity`, read by `prepass-view` and by the temporal passes). It exists only when the GPU can
  render to RG16F (`Gpu::velocity_ready()`), the camera draws the world and no global illumination pass replaces the prepass.
  The pipeline of a frame with a velocity image is a different pipeline from the one without it (`TargetFormat::color1`).
- **The values.** The vertex shader of the prepass programs (`mesh_common.glsl`, blocks `fa_prepass_vs`, `fa_prepass_fs`) gets the
  previous model of the instance as vertex slot 6 (three `vec4` rows, 48 bytes per instance, `kPrevModelBuffer`), and the
  uniforms `fa_vel_vp` (the unjittered `viewProj`) and `fa_vel_prev_vp` (`PostPlan::prevViewProj`; the same matrix when the camera has
  no history). It outputs the clip position of the point with the current model and with the previous one, both through the
  unjittered matrices; the fragment shader writes `uvPrev - uvCurr` (uv y down), clamped to +-`kMaxMotion`. Terrain, impostors and
  foliage use the same blocks and are treated as static objects (previous model = model), so they hold the camera's motion.
- **The history of the models (`Impl::prevModels`).** Each opaque item the camera draws has an entry keyed by its entity: its
  previous and current model and the frame stamp (`postSerial`) it was last drawn in. `fill_prev_models` runs before
  `build_batches`: an entity drawn in the frame before takes its previous model; a new one, or one not drawn in the frame before
  (culled, hidden, another camera), takes its own current model (no motion of its own, only the camera's), and so does every item in the
  first frame after a camera cut (`PostPlan::prevValid` false). Entries not touched for a frame are dropped, once per frame. The floating
  origin shift moves both models of every entry by the same shift as the camera's matrices (`origin_shifted`), so a rebase is not a
  motion. Instances of one batch keep each their own previous model: the rows are uploaded next to the instance matrices, in the same order.
- **Skinned meshes (M76-P1b, M76-P1c).** `prepass_vs_skin` skins the vertex twice. The previous palette is kept per skinned entity
  (`Impl::prevPalettes`: one per skin of its Animator, the palette of the last frame it was drawn in, swapped with the current one each
  frame so the vectors keep their capacity; the same keying and lifetime as `prevModels`, pruned with it). The **current** palette stays in
  the `fa_skin` uniform block (rows 0..191 hold the 64 joints of `kMaxSkinJoints`, read with `fa_skin_matrix`); the **previous** one is an
  RGBA32F image read in the vertex stage with `texelFetch` (view slot 29, nearest sampler 11, block `fa_prev_palette`): 3 texels per joint, all
  `kPrevPaletteTexels` (192) of a palette padded with identity, one palette after the other as a stream of texels, texel `t` at
  `(t & 1023, t >> 10)`. `upload_prev_palettes` (called by `upload_instances`) writes the stream of every skinned batch of the frame with
  `Gpu::write_palette_image` (one image per camera job and frame, from a pool of its own that restarts with the transient buffers: the frame graph runs after every job has uploaded, so a second camera must not overwrite the first one's texels; the format and width of the light data, rows rounded up to 16 so the images are not made again for every skinned draw that comes or goes) before the frame graph runs, and the draw passes
  the first texel of its palette in `fa_vel_on.w`. So there is no joint limit beyond the skin's own 64: the 40-joint and 64-joint fixtures of
  the tests have real vectors. The program reads the texture only in the previous-model run (`fa_prev_model()` is called inside
  `if (want_prev)`, so a draw with no velocity never fetches). A frame that asks for no velocity does not upload any of this: the
  prepass is the same as before (tested bit for bit). The image needs RGBA32F **sampling** (`sg_query_pixelformat`; every GPU backend of the
  engine has it: GLES3 and WebGL2 vertex texture fetch of an unfilterable float texture is core, D3D11 and Metal sample it in the vertex stage,
  and it is the format of the light data image the engine already reads that way). Where it cannot be sampled, and for the more than
  `kPrevPaletteMaxRows` rows a frame of 5461 skinned palettes would need, the skinned draw writes the sentinel (`fa_vel_on.z` = 0) and one warning is
  logged (`warnedPrevPalette`). Palettes are in model space, so the origin shift does not touch them; a cut, an entity not drawn in the frame
  before or a change of the joint count uses the current palette as the previous one (no motion of its own). The prepass's `prepass_prev_attr` for
  a skinned program starts after the joints and weights (`kExtraAttrBaseSkinned`, 11).
- **Custom `vertex()` (M76-P1b).** The prepass vertex shader includes the material's `vertex()` and runs it **twice**: with the model of
  the frame and the game time of the frame (`fa_time`), then with the previous model (and the previous palette for a skinned mesh) and the
  **game time of the previous frame** (`world.time()` at the last frame the camera drew; the time now after a cut, or when no history is kept;
  `Impl::clockPrev`, uploaded as `fa_vel_on.y`). In the prepass `fa_time` is redirected to a variable that the second run changes
  (`FA_PREPASS_VS`), so a `vertex()` that animates with `fa_time.x` is right with no change. What the previous run does **not** have: the
  previous frame's instance data and material parameters (it reads this frame's), which only matters for a `vertex()` driven by a
  parameter or per-instance data that changes from frame to frame. Terrain and impostor cards run a `vertex()` of their own that
  ignores the model matrix (the chunk, the card's corner): they define `FA_VEL_STATIC_VERTEX` and keep the static formula (previous model = model).
  The second run changes **only `fa_time.x`**: `fa_time.yzw` is the camera position **of this frame** (what the vertex stage of a full-shader
  material gets there) in both runs, as are the instance data and the material parameters, so a `vertex()` that moves with the distance to the
  camera sees no motion from it.
- **What is not written (the sentinel `kNone`).** The previous model takes 3 vertex attributes (`fa_prev_r0..2`) after the program's own, and
  a pipeline has 16 (`SG_MAX_VERTEX_ATTRIBUTES`). Without a skin the engine's 9 mesh attributes leave room for the previous model and up to 4
  extra `vec4`s; a program with more than 4, and a skinned one (11 attributes before the extras) with 3 or more, does not fit: `prepass_prev_attr`
  returns -1 and the vertex shader writes the sentinel. The same for a material that draws from storage buffers, for a skinned draw whose
  previous palette cannot be uploaded (no RGBA32F sampling, or a frame past `kPrevPaletteMaxRows`), and for what no quad drew and no mesh
  covers (the sky, the background of a 2D scene, a blended or additive particle: see the next two entries). The pass that reads the image
  then reprojects those pixels from the depth with the camera's matrices (the contract above), which is right for anything static. Both
  sentinel paths of the palette image have tests (`RendererTestAccess::force_no_palette_sampling`, `set_palette_row_cap`).
- **Sprites, shapes, tiles, text, quads and particles (M76-P1d).** The 2D items of the world are pre-transformed quads
  (`Vertex2D`, world position), drawn by the main pass with no prepass of their own. When a camera needs the velocity (`request_velocity`,
  the temporal effects, the debug view, `force_velocity`) `plan_quad_motion` scans the items of the world and adds up to two passes after
  the prepass, each a single-attachment pass over the same batches and vertices as the main pass (`quad_motion_pass`, program
  `quad_motion.glsl`, `Gpu::quad_motion_pipeline`):
  - `quad-velocity` writes the velocity of an item whose batch is `Alpha` blended, whose coverage at the pixel is at least one half (the
    texture's alpha times the tint's, the glyph's, the circle of a `Shape2D` as a whole box) and that is not marked reactive: a **cutout**.
    It writes **over the prepass's image** (LOAD) when the camera has a prepass (a perspective camera with a mesh, or any effect that reads
    depth), and into an image of its own cleared to `kNone` otherwise (a 2D scene, where the temporal effect then has a velocity image and no
    depth: it reprojects from the far depth, which is exactly the camera's motion for an orthographic camera). In a perspective camera the quad is
    tested against the prepass's depth in the fragment shader (`texelFetch` of the view depth, with a small bias), so a sprite behind a mesh
    leaves the mesh's vector alone. A blended or additive batch writes **no** velocity: it never overwrites the opaque surface behind it.
  - `quad-reactive` writes the **reactive mask**: R8, cleared to 0, the MAX blend of the item's reactive value times its coverage (so
    overlapping particles do not add up past 1), with the same depth test. See the next entry.
  - **The motion.** Per vertex a second stream (vertex buffer 1, `kQuadMotionBuffer`, 4 floats: how far the vertex moved since the frame
    before, and its reactive value) says where the vertex was on the frame before: `position - motion`, through the previous view-projection.
    The item keeps its matrix on the frame before (`Impl::prevQuadOrigins`, keyed by the entity as `prevModels` is, stamped with
    `postSerial`, pruned once per frame, shifted with the floating origin) and `fill_quad_motion` turns the two matrices into a translation
    (`motion`, the origin now minus the origin before) and a 3x3 `turn = I - Lprev * Lcur^-1`, so `QuadList::flatten` writes, per vertex,
    `motion + turn * (p - origin)`: a sprite that turns or grows between two frames has the tangential or radial vectors of each corner, not
    one vector for the whole box. An item whose 3x3 did not change (or is singular) writes the constant translation, as before. An item with
    no history (new, not drawn the frame before, the first frame after a cut) has none: the camera's motion only. A **teleport** (the matrix
    jumps) gives a large vector, up to the +-4 clamp of the velocity image, as a mesh does: the temporal passes reject a vector that long.
    Sprites, shapes and tilemaps give their entity and transform (`QuadList::set_motion_source` in `scene2d.cpp`); text has no source yet and
    counts as still in the world (the camera's motion only). **Limitations:** a change of `size`, `region` or of the vertices themselves
    (a tile map that scrolls its cells, a sprite sheet that changes frame) is not followed, only the matrix of the entity; the whole box of
    a `Shape2D` counts as covered; an item that draws as instances or with a screen effect writes nothing; a batch with a clip rectangle writes
    nothing (the passes do not apply the clip, so they would cover other pixels than the colour: such a quad has the camera's motion and
    no mask; only screen items have a clip and they are in the HUD list anyway); a batch with a sprite material of its own writes **no
    velocity** (its `discard` or `vertex()` change the footprint) but, when it is reactive, **does write the mask** over the built-in footprint
    of its quads (the shape and the texture alpha, not the material's `discard`: a conservative mask, a little wider than the colour, that
    only lowers the weight of the history); and a particle writes no velocity at all (it is reactive instead). The 2D passes have no depth
    when the camera has no prepass, so a **particle behind an opaque sprite still marks the mask** there (it is drawn in the list order, and
    the mask does not know what covers it); in a perspective camera with a prepass the depth test removes it. The passes rasterise with
    `drawViewProj`, the matrix of the colour and the prepass (the jitter included), so their coverage and depth test hit the colour's
    pixels; the vectors use the matrices without the jitter. With `taa.on` false (a capture: `capture_world`, no temporal frame) the
    camera asks for neither image, and no velocity or mask pass is built even for a sprite with `reactive` set (`needsVelocity` only stays
    when a debug view or an effect pins it).
- **The reactive mask.** A pixel of the mask says "trust this frame here": `taa_resolve.glsl` lowers the weight of the history at that pixel by
  `1 - clamp(mask * temporalAAReactiveScale, 0, 1)` (the upscaler's resolve reads it the same way). Writers: a blended or additive **particle**
  or trail (`ParticleEmitter.reactive`, 0..1, default 1; 0 opts out; an `Additive` item with no value set counts as 1, as every
  `Additive` sprite does), and any quad item given a value with `QuadList::set_reactive`. The mask is declared only when the
  camera has a temporal effect and an item asks (`PostPlan::needsReactive`, dropped when the frame cannot resolve); with a temporal
  effect off the pass does not exist and the picture is the same bit for bit (tested). **The format is R8** (`Gpu::reactive_format()`): a
  single 8-bit channel is renderable and sampleable on GLES3, WebGL2, D3D11 and Metal, and the MAX blend (`SG_BLENDOP_MAX`) is core on all of
  them, where blending RGBA16F or R16F would need extensions on the GLES3 and WebGL2 floors. 256 steps are far more than the resolve needs.
  **What it does not do:** it holds the pixels the particle covers **now**. It cannot clear the trail on the pixels the particle has already
  left (nothing says they are stale), and on a flat background the neighbourhood clamp of the resolve already limits that trail; the mask is
  for the leading edge and the fine detail of a fast particle over a busy picture, where the history it would blend is a different picture
  (`quad_motion_tests.cpp`: the leading edge of a checkered additive square over a busy background is 6 times closer to the truth with the mask).
  **Not a persistent mask.** A mask that cleared a trail would need the mask of the frame before at the pixels the particle left, read
  by the TAA, the upscaler and the MetalFX resolves; those resolves belong to other work and the clamp already bounds the trail, so the mask
  stays "this frame, here". **Flags:** `Sprite.reactive` (-1..1, default -1 = by blend: an `Additive` sprite counts as 1, others as 0;
  0 = never reactive, which is how an `Additive` sprite opts out; above 0 = that value) marks a sprite or an in-world UI-like quad. A
  `Shape2D` has no flag of its own (mark a quad item from C++ with `set_reactive`, or use a `Sprite` or an emitter). There is no
  material-level flag either: a sprite material is a `.material.json` whose format is owned by the material-graph work, and
  `Sprite.reactive` already says it per sprite, so a second switch would only be a second place to look. Screen-space quads (`space: screen`)
  are in the HUD list, not the world list: they write neither velocity nor mask, and are drawn after the world picture is resolved.
- **No RG16F.** A GPU that cannot render to RG16F (`Gpu::velocity_ready()` false) gets no second attachment and no previous-model
  work (`ctx.collectPrev` is false); the renderer logs a warning once (`warnedNoVelocity`) and the temporal passes reproject from the depth.
- **Warm-up.** `warm_step` builds the velocity variant of the prepass pipelines (plain, double sided, skinned when an Animator exists) while
  a loading screen is up when a camera has `temporalAAEnabled`, so the first frame of the effect does not compile them. The two quad-motion programs (velocity, reactive) are built the same way when the world has a sprite, shape, tile map or emitter.
- **The probe.** `velocity_probe_pass` (tests and the debug view) reads the image with the debug view `prepass_view` mode 4, which is
  **test-only**: it returns the raw RG16F values; the GL row flip of the read-back is the one of `Device::read_image_rgba8` (reasoned, not measured on GL).
- **Cost.** With the image: 4 bytes per pixel of the prepass (RG16F) plus 48 bytes per drawn opaque instance per frame, one
  `unordered_map` entry per visible entity (a lookup per item per frame) and, per skinned entity, 192 texels x 16 bytes = 3 KB of previous
  palette uploaded each frame (a skin of 2 joints costs the same as one of 64: the palette is padded to 64), plus a copy of the current one kept
  for the next frame. Without it: the prepass programs read three more vertex attributes (a dummy buffer is bound, nothing is fetched from a
  real one), the vertex shader tests a uniform (`fa_vel_on`) and a skinned program binds a 1 x 1 white texture it never reads; the fragment shader
  has a second output that a pipeline without `color1` drops.
- **Seeing it.** `render.debug_view {"view":"motionVectors"}` paints the image over the picture: the hue is the direction of the
  motion, the brightness its length (a motion of 1/40 of the image is full brightness), black for no motion and a mid grey where
  nothing wrote one (the sentinel). `RendererTestAccess::read_velocity` reads the raw floats back for the tests
  (`engine/render/tests/velocity_tests.cpp`).
