Part of [the rendering architecture](ARCHITECTURE_RENDERING.md): the PostProcess component, the linear HDR frame, the stack of post effects and how it is resolved and drawn. The other post-processing effects are on [ARCHITECTURE_RENDERING_POST.md](ARCHITECTURE_RENDERING_POST.md).

# Rendering: the PostProcess stack (M71)

M71 added a linear HDR frame (below, "Linear colour"), a stack of post effects (every effect of `kPostEffectOrder` is drawn) and the HDR
display output.

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
  R11G11B10 has no alpha (`scene_has_alpha`): view and render-target images and world captures share the scene's format, so on that
  format their background is opaque (`view_image` logs one warning; a format with alpha would need every pass that reads `scene_format()`
  to follow it); `FeatureEnv.r11g11b10` follows the same rule as the chain (blend, or GL where sokol does
  not report it; on GLES3/WebGL2 sokol ties filtering to `OES_texture_float_linear`, so a false there can mean that). The editor viewport shows `Impl::display_view()`: the finished game image in gamma; in linear, after
  `Renderer::set_editor_view(true)` (the editor, once; a game never), an RGBA8 copy that `update_editor_copy()` draws after each frame
  with blit_keep and `encode` on (not counted as a draw call, freed when the scene returns to gamma or the editor stops asking; until the
  copy exists, in the first frame or after a failed make_target, the viewport shows the unencoded image). M71-B4
  points `display_image()` / `display_view()` at its final target. Known approximations of the linear path: the ramps of Shape2D
  `gradientStops` are baked in 8 bits and blend on the sRGB values (the two-colour gradient blends in linear light); the 2D light buffer is
  RGBA8 with range 2 on a GPU that cannot render to a float format (`light_format()`), which bands in dark light; text lighting
  (`text_light_factor`) sums authored sRGB values, a little brighter than the mesh path's sum of linear light; mips of a colour
  texture are averaged in linear light when it is made as sRGB (`mip_chain(img, true)`), but a `.ktx2` twin keeps the mips the export
  made, on the encoded values. The shader helper `fa_tex_fix` is written with `if` branches on a
  uniform, so a gamma scene skips the pow() blocks on compilers that would run both sides of a `?:`.

- **Data, in `engine/scene`.** `SceneSettings.colorSpace` (`gamma`, the default, or `linear`), `hdrOutput` (`off` or `auto`) and
  `paperWhiteNits` (200) are stored and saved with the scene; an old scene without them loads as gamma. The `PostProcess` component
  (`fa/scene/postprocess.h`) is flat: the meta fields `enabled`, `shape` (`global`, `box`, `circle`, `sphere`), `size`,
  `blendDistance`, `priority`, `weight`, then for each effect `<effect>Enabled` and its parameters (`bloomIntensity`,
  `tonemapMode`, ...). A field belongs to the effect whose name its own starts with (`post_field_effect`), so the resolver blends a
  parameter added later without being edited. Everything is off by default. On a Camera it is that camera's own stack; on any other
  entity it is a volume.
- **Effect order, one list.** `kPostEffectOrder` (and `enum PostEffect`, same order) is the order the passes run, HDR effects first,
  display effects after the tonemap: `ssao`, `ssr`, `fog`, `sunShafts`, `exposure`, `temporalAA`, `depthOfField`, `motionBlur`, `radialBlur`,
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
  `computeShaders`, `float32Targets` (R32F and RGBA32F render and sample: the shadow atlas of M73.2); the engine features `linearColor` and `hdrOutput`; the 21 lighting rows of M73 (`clusteredLights` ... `transmission`, planned "M73" until their package lands, `clusteredLights` landed with M73.1a: docs/design/ARCHITECTURE_RENDERING_LIGHTING.md); and one per effect (the names above). Each row says the
  backends it can ever run on (GL, GLES3, WebGL2, D3D11, Metal; the headless dummy backend has none), what it needs from the GPU
  (read with `sg_query_pixelformat` / `sg_query_features`), and whether the engine draws it yet. A feature the engine does not draw
  answers false with the status "planned (<milestone>)" (`effect_drawn` in `render_features.cpp` for the effects: every effect of `kPostEffectOrder` is
  drawn, so none answers it, and a new effect stays planned until its pass lands; the lighting rows carry `"M73"` in the table). The `needs` words of a row (`half`, `depth`,
  `r11g11b10`, `compute`, `float32`) are what the effect asks of the GPU: the depth of field and the sun shafts need `half+depth` (their
  half-size images are RGBA16F), so `supports` never claims what the renderer cannot do; `kEffectRows` carries the effect's name and a
  `static_assert` checks it against `kPostEffectOrder`. The editor's post panel calls `Renderer::supports_report()` directly (the same
  table `render.supports` answers), not the command. Compute shaders exist on GL, D3D11 and Metal, never on GLES3 or WebGL2; `hdrOutput` only on D3D11 and Metal.
  The decision is a pure function of a `FeatureEnv` (backend + what the GPU reported), so a test asks what D3D11 would say.
- **Compute storage images (`engine/render/src/compute.cpp`, `fa/render/compute.h`, M72.17).** `Compute::create_image` makes an
  immutable sokol image with `usage.storage_image` AND `usage.color_attachment`: sokol cannot copy into a storage image (`copy_dst`
  excludes `immutable`), so a clearing pass over the attachment view zero-fills it (the GPU's memory is undefined). The image has a
  storage view (the dispatch binds it after the buffers' view slots, sorted by name) and, when `sg_query_pixelformat` says the format
  filters, a sampled view for the draws. A sampled view and a storage view of one image are never bound in one pass (sokol refuses
  it), so a dispatch whose texture param is an image it writes is an error. The texture id `compute:<id>` is resolved by
  `Assets::texture` through `ComputeImageResolver` to one stable `TextureAsset` per image (`describe_image_texture` refills it when
  `resize_image` remakes the GPU image, so a sprite keeps working); a destroyed image points its texture object at the white
  texture and keeps the object (up to 256) so a draw already recorded never reads a freed pointer, and the id answers
  "no live compute image" with the checker. Order inside a frame is the order of the calls: `Gpu::begin_compute_pass` and
  `end_compute_pass` close the pass, Metal and D3D11 track the hazard, sokol inserts the GL barriers. `read_image` commits, reads only
  the rectangle through `Device::read_storage_image` (Metal blit with an origin, D3D11 `CopySubresourceRegion`, GL `glReadPixels` from
  an FBO with `glGetTexImage` as fallback) under the 4M-number cap. Caps are counts (32 images, 8192 a side or the GPU's
  `max_image_size_2d`, 256 MiB each, 512 MiB in all), checked in 64-bit before the GPU allocates.
- **Commands.** `postprocess.get`, `postprocess.set` (thin wrappers of `scene.set_component` for `PostProcess`), `postprocess.presets` and
  `postprocess.apply_preset` are in `engine/runtime/src/postprocess_commands.cpp`. The looks are data
  (`engine/runtime/data/postprocess_presets.json`, `fa/runtime/postprocess_presets.h`; `postprocess_preset_fields` gives the fields a
  look writes, replace or `keep`, Entity fields never touched, and is shared with the editor's undo plan). `postprocess.get
  {resolved}` runs `resolve_post_stack` with a `PostTrace` (which layer wrote each field) through `fa::render::post_stack_report`
  (`post_report.h`) on the CPU, for the camera `rendering_cameras()` puts first. The editor's Post-processing panel
  (`tools/editor/src/postfx_panel.cpp`) draws that report and writes only through `postprocess.set` / `apply_preset`; its A/B check is
  `Renderer::set_post_bypass`, which makes `build_camera` declare no stack (data untouched).
- **The stack's passes and the final pass (`src/postprocess.{h,cpp}`, `shaders/post.glsl`, `shaders/exposure.glsl`).** `build_graph`
  declares them in the last job, one stack per camera: every camera job that draws pixels (`plan_job`) makes its own `PostPlan` from its
  own PostStack and keeps it in its `DrawContext`; `Impl::postCams` lists those contexts in drawing order. `PostPlan::rect` (a `PostRect`:
  top-left, physical pixels; empty = the whole picture) is the camera's rectangle, which the camera's `post` pass draws into (viewport
  and scissor) and reads from (post.glsl, mask bit 2048: `rc` is the rectangle as fractions of the picture, `src_uv` clamps to half a texel
  inside it and then flips on a bottom-up backend; `post_rect_uv`, `post_rect_uv_native` and `post_source_uv` in `postprocess.cpp` are the
  same maths on the CPU, with a test for the GL and the Metal/D3D11 flips). When the first camera's final pass does not cover the whole
  picture, a `post-base` pass (the plan of an empty stack: the encode of a linear scene, a copy of a gamma one, the colour filter) draws
  the whole picture first and the camera passes load it and draw over their rectangles; a camera without a stack that overlaps one with a
  stack gets that plain pass over its own rectangle too. Cameras with stacks that tile the picture need no `post-base`, nor does a first
  camera with a stack over the whole picture. An `AutoExposure` (its `exposure-luma` and `exposure-adapt` passes, named after the camera's
  job) is kept per camera, by `Entity::bits()` in `Impl::autoExposures`, and released after two frames without a request. Bloom and the
  colour filter are the exception: one of each per frame, with the settings of the first camera that draws a pixel (a camera whose
  rectangle has no pixel does not count). `make_post_plan` turns the stack into sanitised numbers
  (`PostPlan`); `PostPlan::convert()` (exposure, tonemap, or `linear`, which `make_post_plan` sets only for a linear scene that also has exposure, a tonemap or a colour filter: a linear scene with none keeps B1's encode in the present copy) decides whether the final pass runs. Encode matrix: `Impl::finalEncoded` is set by the `post` pass; the present copy and `read_rgba8` encode (`blit_fs_params.encode`) only when the scene is linear and it is false, and `display_image()` shows the final target itself and `update_editor_copy()` makes no copy when it is true. `filterTarget` and `hudTarget` are `Gpu::display_format()` (the scene format, but RGBA8 for SRGB8A8, whose writes would encode the display values again), and `hud_pass` draws as a gamma scene (`fr.linear` off) when the items go over the final picture Order: bloom
  (`bloom.h`, now with a soft knee in `q.y` of the bright pass and a lens dirt texture in the composite) -> `exposure-luma` /
  `exposure-adapt` (`AutoExposure`) -> `post` (exposure, tonemap, the sRGB encode, a one-step interleaved-gradient-noise dither, and
  the colour filter, in one fragment shader) -> `hud-over-post` -> `color-filter`. Four cases, by `plan.last`: (1) no conversion and
  no HUD after: the filter alone is `color-filter` (post.glsl with `convert` 0, the old filter's maths); (2)
  `bloomScreenSpace = false` without conversion: `hud-over-bloom`, then `color-filter`; (3) conversion and no screen-space items: one
  `post` pass game -> `filterTarget` with the filter fused in; (4) conversion with screen-space items: `post` game -> `hudTarget` (a
  game-like target made on demand by `ensure_hud_target`: same MSAA and depth, so the HUD pipelines draw into it), `hud-over-post`,
  then `color-filter` hudTarget -> `filterTarget` when a filter is on. `Impl::final_target()` is the image present, `capture()` and
  `read_rgba8` use; the `post` program is compiled only for a frame that converts or filters (`Gpu::post_ready()`, counted by
  `post_ready_calls()` in the tests), so a game without a stack never builds it; the pass sanitises NaN and Inf at the texel read.
  `Impl::finalEncoded` says the final pass already encoded it, so the present blit must not encode again.
  Automatic exposure never reads back: `exposure-luma` takes 8x8 fixed log2-luminance taps per texel into a 32x32 transient,
  `exposure-adapt` moves a stored 1x1 EV (two persistent targets used in turn, imported into the graph) toward
  `log2(0.18) - mean` by `1 - exp(-speed * dt)` (the EV targets are RGBA16F 1x1 on every GPU, the EV stored as two channels, `r = round(ev * 128) / 128` (exact in 16 bits up to
  +-16) and `g = ev - r`, read as `r + g`: one 16-bit number would lose the step under half a unit of its last place and the result
  would depend on the frame rate, and a 32-bit target cannot be filtered or rendered on WebGL2 and iOS) with the engine's frame dt;
  a first frame, new targets or a frame in which the passes were not declared (`lastSerial_ + 1 != serial`, where `serial` is
  `Impl::postSerial`, the count of the game's frames: `capture_world` calls `begin_frame_graph(false)` and does not advance it, so
  a capture neither resets the exposure nor, with `framePost` false, reads or writes the motion-blur matrices; `capture_camera` too) take the target at once;
  a target that cannot be made leaves the exposure manual for 300 frames (`kRetryFrames`) and then tries again, dt 0 leaves it as it is, and it needs the
  RGBA16F scene format (else one warning and the exposure stays manual). `CameraInfo::bloom` and `colorFilter` are always derived from the
  stack (`bloom_from_stack`); the six bloom and colour filter fields of `Camera` that 0.31.0 deprecated were removed in 0.33.0 (a scene
  that still has them fails to load, `removed_field_hint` in `deprecation.h` gives the text). The HDR output (`hdr_encode.h`): the frame
  takes `OutputTarget` (`select_output` of the last `update_output` answer: encode, headroom, paper white) when it starts;
  an extended one (an HDR encode, headroom above 1, a float display format) makes the final pass run `tonemap_hdr` (`p.z`
  and `h` of post.glsl, without a colour filter) and write sRGB-encoded values past 1, and `present_params` decodes them in
  blit.glsl and encodes them for the swapchain the window has at present time (sRGB, scRGB, PQ in Rec.2020, EDR linear),
  clamped to the frame's headroom only when its final pass went above white (`frameAboveWhite`). The CPU functions mirror
  the shaders; `renderer_force_output` and `renderer_read_floats` let the tests check them without an HDR display. Screen-space items are drawn after the final pass, so exposure and tonemap
  never touch them; in a linear scene their quad and text pipelines must write display-space values into `hudTarget`.
- **Custom post passes (M72.2, `PostProcess.customPasses`).** Full-screen passes drawn by kind `"post"` materials, between the built-in
  effects. Data: `fa/render/post_custom.h` (the entry parser `parse_custom_post_passes`, the position table `kCustomPostPositions`
  and the `PostSlot` places: `Main`, `AfterSsr`, `AfterShafts`, `AfterDof`, `AfterBloom` on the scene-linear picture and `AfterTonemap`,
  `AfterGrading`, `AfterVignette`, `AfterSharpen`, `AfterOutline`, `AfterPosterize`, `AfterGrain` on the display-referred one,
  `post_slot_is_ldr`). `resolve_post_stack` collects the entries (own, then volumes with strength >= 0.5) into `PostStack::custom`, with the
  entries it could not read in `customErrors` (logged once per scene, shown by `postprocess.get {resolved}`). `plan_job`
  (`renderer_draw.cpp`) turns them into a `CustomPostPlan` (`make_custom_post_plan`, `renderer_custom_post.{h,cpp}`): one entry per
  material that built as a post material, with its params packed for UB5 and its textures; a material that did not build, is not a post
  material, is missing or needs the prepass on a GPU without it is left out, listed in `RenderStats::materialFallbacks` and logged once
  (`warnedCustomPass`). `needsDepth` and `needsNormals` become true only when a planned pass reads the prepass (`fa_depth`/`fa_normal`
  make the program declare it), and `plan_prepass` draws it even for a camera with no mesh then. `build_graph` calls `custom_slot(slot)`
  at each place: `CustomPost::add_passes` declares one pass per entry reading the picture (the first) or the transient before it,
  ping-ponging between two transients of the picture's format (a pass cannot read what it writes) and drawing the last one into the
  camera's rectangle of the picture (viewport and scissor on a split screen, the bloom's MSAA and hud-over-bloom destination rules; a
  lone pass is copied back with `SceneFx::copy_into`). The pipeline is `Gpu::post_material_pipeline(format, shader)` (cache key 0xF00),
  the program `programs[0]` of the material, bound like the other kinds (`kMaterialPost*` in `render_internal.h`). The y-flip of a GL
  render target is in `fa_post_vs_params.fa_flip` and `fa_post_params.fa_a.x`, so a snippet always sees y running down. The feature
  `postMaterials` of `render.supports` is the Engine capability; the editor's panel edits the list (`tools/editor/src/postfx_custom.h`).
  *The cut final pass.* The stages of `post.glsl` are `PostStage` (`postprocess.h`: scene = lens/aberration/radial blur/haze + exposure
  + tonemap + sRGB encode, grade, vignette, sharpen, outline, posterize, grain, tail = flash/fade overlay + dither + colour filter) and
  `PostSlice` says which of them one draw runs (`run_post_pass(..., slice)` masks the effect bits, so the shader is the same). The slot
  `AfterTonemap + i` sits after stage `i`. `build_graph` (`declare` in `renderer_draw.cpp`) walks the stages: where an entry sits at a
  slot and a stage before it is active, it draws the pending stages into one of two persistent images `ldrMid[2]`
  (`Impl::ensure_ldr_targets`, the scene format, one sample, the picture's size), calls `add_passes` on that image with `linear` false
  (`custom_here`) and goes on from the next stage; the last piece (always including the tail) draws to the destination as the one pass
  did and is the only one that sets the HUD, filter and `frameAboveWhite` state. Slots with nothing active between them share one
  `add_passes` call, a chain on the game target in place needs no image when the first stage is inactive. Pieces are named
  `post-part<k>` and the last keeps `post` (or `post-base`); a frame with no display-referred entry never cuts, so its graph is the
  one it always was (`post_material_tests.cpp` counts the passes). The auto exposure is read in the scene piece only, the outline's
  source in the outline piece only, the dither and the colour filter in the tail only.
  *History (M72.16, `fa_history`).* A pass whose program declares view `kMaterialPostHistoryView` (the snippet calls `fa_history`:
  `CustomPostEntry::usesHistory`) keeps a `HistorySlot` in `CustomPost::history_`: two `Target`s of the camera's rectangle size and the
  picture's format, one slot per camera (`CustomHistoryFrame::camera`), job (two views of one camera), material path and ordinal (two entries
  of one material). `plan_history` runs when the frame is built: it makes or re-makes the images (size or format change; a 1 GiB budget,
  256 MiB on wasm32, or a refused image leaves the pass without history and logs once) and decides `valid`: the slot wrote in the frame
  before (`serial + 1 == postSerial`, which a capture does not advance; `capture_camera` keeps its histories under `kCaptureHistoryBit | camera bits` (renderer_present.cpp), valid when `captureSerial`, which counts the frames of every capture, is one before and the frame is not the first of the call, and frees them when it ends), the scene hash (path and `scene_generation`) is the
  same and the camera was continuous (`PostPlan::prevValid`: drawn in the frame before, no world-clock jump). The pass draws into
  `img[write]` and reads `img[read]`, both imported into the graph (`<prefix>-history<k>-in/-out`), so the order and liveness come from
  the graph; the image it wrote is also the picture the next pass reads, so the only extra draw is the copy into the picture when it is the
  last pass (a lone pass copies anyway). A slot nobody planned for `kHistoryIdleFrames` (120) frames is freed by `sweep_history`, called
  once per frame from `begin_frame_graph` (a frame count, not time, as P7b's cut images). `Renderer::reset_post_history(camera)` and the
  command `render.reset_post_history` only clear `wrote`. The history is read with `fa_flip_uv`, like the scratch images, so GL and the
  top-down backends agree.
- **The effects, one bullet each,** are on the page [rendering, the post-processing effects](ARCHITECTURE_RENDERING_POST.md): the grading and lens
effects, the radial blur and the transient screen effects, the outline, pixelate and posterize, the ambient occlusion, the depth and
normal prepass, and the depth of field and motion blur.
- **The lighting of M73** (shader files, texture slot table, feature rows, new fields) is on the page [rendering, the lighting of M73](ARCHITECTURE_RENDERING_LIGHTING.md).
