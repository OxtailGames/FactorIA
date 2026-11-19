Part of [custom shaders](CUSTOM_SHADERS.md), "Kinds (M72)": the three kinds built on the mesh design, sprite, sky and post, with their
template, tooling and draw. The shared base (the `kind` key, the per-kind template hash, the skeletons) is on that page.

# Custom shaders: the sprite, sky and post kinds

## Sprite materials (M72.1, the template and the tooling)

`engine/render/shaders/quad_common.glsl` is the source of every 2D quad program, as `mesh_common.glsl` is for meshes.
`quad.glsl` is the template with the default snippet, an empty `fragment()`: it declares `@block fa_user` with
`void fragment(in QuadInput i, inout QuadSurface s) {}`, includes the template and declares the two programs the renderer
binds by generated names (`quad`, `quad_plain`; so every name `quad.glsl` already had is unchanged and a material must
not take it). A sprite material's generated top file has that very shape with its own `fa_user` block, so a material
whose `fragment()` is empty draws the pixels of the engine's own program (the tooling test "sprite template" compares the
generated top file with the built-in source modulo the user block; the render tests "sprite materials" compare the pixels of the two, in the lean and the full program).

- **Contract.** `void fragment(in QuadInput i, inout QuadSurface s)` (required) and `void vertex(inout QuadVertex v)`
  (optional, defines `FA_HAS_VERTEX`). `s.color` arrives holding what the engine would draw for the mode (the textured,
  lit, glyph, circle, ring, soft or SDF-shape result, alpha already including the coverage); the engine applies the flash,
  the multiply conversion and the fog to what the snippet leaves in it. `QuadInput` carries `uv`, `color` (the tint),
  `world_pos`, `screen_uv` (y down on every backend), `time`, `mode` and `custom` (zero for now). `fa_sample_main(uv)` samples the main texture in the colour space of the scene,
  `fa_scene_rgb(c)` takes an sRGB colour of the author to the scene's.
- **One program per variant.** `quad` has every mode; `quad_plain` is the lean program the renderer picks for a batch of
  plain textured quads (no lights, no multiply). The snippet runs in both, so it must not depend on anything the plain
  program does not have: `i.mode` is 0 in it. The twin carries both (`programs.quad`, `programs.quad_plain`).
- **Slots.** Uniform blocks: vertex 0 `quad_vs_params`, fragment 1 `quad_fs_params` (the engine's), 4 `fa_material_vs`
  (vertex stage) and 5 `fa_material` (fragment stage) are the material's, as for a mesh. Views 0-3 (`tex`, `normal_tex`,
  `light_tex`, `shadow_tex`) and samplers 0-2 are the engine's, so a material's textures take views 4..7 and samplers 3..6
  (`kMaterialSpriteFirstView`, `kMaterialSpriteFirstSampler` in `fa/tooling/shaders.h` and `engine/render/src/render_internal.h`;
  a mesh material uses views from 6 and samplers from 2, and a second set at 10.. and 6.. for the textures of its `vertex()`; a
  sprite has its second set at views 8.. and samplers 7.. (`kMaterialSpriteVsFirstView`, `kMaterialSpriteVsFirstSampler`),
  declared as `fa_vs_<name>` the way a mesh's are, so a sprite `vertex()` samples a material texture at mip 0).
  `fa_time` and
  `fa_target` are members of the fragment block `quad_fs_params`, and `fa_time` of the vertex block `vs_params`: the renderer
  fills them for a material's draws, and in the engine's own programs they stay zero and unread (the lean program has no
  uniform block at all). A material's `quad_plain` does get the fragment block (`fa_time`, `fa_target`: the lean built-in has
  none), so its draw binds UB1 too.
- **Not a material key.** `alphaMode: "clip"` (the mesh template's alpha test and implicit `alphaCutoff`) is an error for a
  sprite: write `discard` in `fragment()`. `lighting: "custom"` (the `light()` hook of a mesh material) is an error for a
  sprite; `"pbr"`/`"unlit"` and `doubleSided` mean nothing to a sprite and are ignored.
- **Tooling.** `generate_material_shader` sets `GeneratedShader::kind`, includes `quad_common.glsl`, defines
  `FA_MATERIAL` (and `FA_HAS_VERTEX`) and lists the programs `quad`, `quad_plain`; the cache key, the twin's `template`
  and the compile all use the hash of the kind (the sprite one covers `color_space.glsl`, `light_shadow.glsl` and
  `quad_common.glsl`). The error hints name `fragment()`, `QuadInput` and its fields. Export writes
  `<name>.material.json.<dialect>.shader` as for any kind.
- **Names.** The unprefixed names of the 2D program (vertex inputs, varyings, textures, samplers, uniform blocks and their
  members, helper functions) share one flat namespace with the params, so `parse_material` refuses a sprite param or texture
  that takes one (error at `/params/<name>` or `/textures/<name>`, with a rename); the list is derived from the bundled
  template files (`template_globals`, `tools/common/src/shaders_generate.cpp`), so it cannot drift. `noise` is refused for
  every kind (sokol-shdc cannot compile a texture called that).

## Sky materials (M72.1, the template, the tooling and the draw)

`engine/render/shaders/sky_common.glsl` is the source of the sky program, the engine's own and every material's: the full-screen
vertex stage, the fragment stage (uniform blocks `sky_vs_params` 0 and `sky_fs_params` 1, the colour-space helpers, `fa_scene_rgb`)
and a `main()` that builds `SkyInput` (`dir`, `sun_dir`, `time`), starts `SkySurface.color` at the gradient of
`SceneSettings.skyColor` and `horizonColor`, calls the snippet's `sky(in SkyInput, inout SkySurface)` and writes the colour
opaque. `sky.glsl` is the template with an empty `sky()` (so the engine's pixels are what they were) and declares
`@program sky vs fs`; a material's generated top file is the same with its own `fa_user` block. The template hash of the kind
covers `color_space.glsl` and `sky_common.glsl`; the sky defines no preprocessor macros and has no `vertex()`.

- **Slots.** The sky binds no texture of its own: a material's textures are views and samplers 0 and up
  (`kMaterialSkyFirstView`, `kMaterialSkyFirstSampler` in `render_internal.h`), its params block is fragment binding 5.
- **Tooling.** `shader.compile`, `material.info` (one program, `sky`), `factoria validate` and `factoria export` handle the kind;
  `lighting: "custom"` and `alphaMode` `"clip"`/`"blend"` are errors on `/lighting` and `/alphaMode` with the fix; `template_globals`
  gives the reserved names of the kind (`pos`, `ray_dir`, `frag_color`, `sky_color`...) as for a sprite.
- **Draw.** `SceneSettings.skyMaterial` / `skyMaterialParams` (`Renderer::Impl::sky_material`): a perspective camera that clears
  draws the sky through the material's program (`Gpu::sky_pipeline(format, shader)`, a pipeline per shader, the same uniforms
  as the built-in one plus the material's block and textures). A path that is not a built sky material (missing, another
  kind, a build error) draws the built-in gradient, with the reason logged once and the path listed in
  `RenderStats.materialFallbacks`. The sky is also baked into the cubes that light the meshes (`renderer_env.cpp`,
  "The sky material lights the meshes" below); without a sky material `fa_env_sky` and `fa_env_horizon` (the gradient) light them as before. The reflection
  probes keep following `skyColor` and `horizonColor`.
- **Editor.** View > Scene settings (`scene_settings_model.*`, `scene_settings_panel.cpp`) edits the settings through
  `scene.set_component` on `SceneSettings` with no `id` (`patch_settings` in `fa::scene` applies the fields all or nothing,
  `skyMaterialParams` merges); the editor's undo plan for it (`plan_set_settings`) puts back exactly the fields of the call.

Built (M72-P3, the `Sprite` draw): `Sprite` draws with its material (`scene2d.cpp` asks `Assets::sprite_material` while it
gathers, on the calling thread, and the emit jobs only copy the result).

- **`MaterialUse`.** The material, its packed params (UB5 layout) and its textures are one interned record per distinct
  (material, generation, values, textures), pooled in the `MaterialAsset` and swept after two frames without use. A
  `QuadItem` and a `QuadBatch` hold a `const MaterialUse*`, so flatten splits batches on pointer equality (never copies
  `materialParams` per frame), keeps the draw-order rules, and a donor Frame's items stay valid in another camera's Frame.
  The reload of a snippet or material bumps `generation`, which makes the next frame take a new use with the new programs.
- **Draw.** `draw_group` picks the material's `quad` or `quad_plain` program (the same blend and depth state as the built-in:
  `Gpu::quad_pipeline` takes the shader and keys its cache on it), writes UB0 (`fa_time`), UB1 (`fa_time`, `fa_target`: 1 / the
  target size in pixels and z = 1 on GL, where `screen_uv.y` is flipped to run down), UB4/UB5 and binds the textures at views
  4+ and samplers 3+. Views and samplers the program does not declare are cleared.
- **Error material.** A material that did not build, or whose kind is not `"sprite"`, makes the use an error use: flatten
  replaces the vertex colours by magenta (the alpha stays), the batch draws with the built-in program, and
  `RenderStats::materialFallbacks` names the material. The build error is logged once (`note_failure`); a wrong kind warns once.
- **Built (M72-P5):** `Shape2D`, `Tilemap`, `Text`, particles and UI call the same `QuadList::set_material`.
  `QuadInput.custom` is still reserved and zero: per-item values are the material's instanced params (below), read by name.

Built (M72-P4, per-sprite values): `"instanced": true` params of a sprite material travel with each quad.

- **Layout.** `instance_layout` is the mesh's (first fit, at most `kMaterialMaxInstanceVec4` = 3 vec4). `MaterialUse.instVec4`
  is the material's `instanceVec4`; the instanced values are NOT part of the use's key, so the batch key (the use pointer) is
  unchanged: sprites that differ only in instanced values share a use and a batch. The values are packed in
  `MaterialRef::inst` by `resolve_kind_material` (`pack_instance_params`) and copied by `QuadList::set_material` into
  `QuadItem::instFirst` of `QuadList::inst`; `append` and `append_items` remap `instFirst`, so items copied between cameras or
  built by jobs keep their values.
- **Stream.** `flatten(out, batches, &instOut)` writes the values of every quad four times (once per corner) in vertex order,
  and `QuadBatch::instFirst` is where a batch starts. `build_quad_stream` uploads the stream as a transient vertex buffer
  (`DrawContext::vinst`) bound as buffer 1; `draw_group` offsets it by the chunk's first quad. Only a material with
  `instVec4 > 0` uses it: `Gpu::quad_pipeline(..., instanceVec4)` then declares explicit offsets for the 7 `Vertex2D` attributes
  (stride 48) and attributes 7..9 (`kQuadInstAttr`) as float4 of buffer 1; the engine's own programs and the materials without
  instanced params keep the old layout. A use whose instVec4 no longer matches its material (a hot reload that changed the
  layout) is skipped for that frame. Ten attributes stay under the 16 of GLES3 and WebGL2 and D3D11's 32. Known cost: a
  Tilemap or a Text with an instanced material repeats the same values for every one of its quads (four copies each, like any
  quad); sharing one copy per item would need a per-item stream, which is not done.
- **Per-frame lookup.** `Assets::sprite_material` keeps its answers of the frame per material path: first by the address of
  the component's `materialParams` (the usual repeat: the same component, or a particle group), then by a hash of the values
  (`hash_params`), comparing values in place only on a hash match. There is no cap on distinct sets (instanced values give
  every sprite its own), and `materialResolves` counts one full lookup per distinct set. The address path relies on the
  Json being a component's own field that keeps its values until the cache is dropped (`FA_ASSERT` checks it in debug).
  `stats.materials` is deduplicated per frame (`Renderer::Impl::materialsCounted`), not per `draw_group` call.
- **`fa_target` and `screen_uv`.** Both count the image the pass draws into: the whole game target in the main pass (a
  camera with a viewport only draws into a part of it, so `screen_uv` there is still relative to the whole target), the
  camera's rectangle in the sprite coverage pass (`coverage_pass` hands `draw_group` the real size of its target).
- **Shader.** `quad_common.glsl` declares `fa_inst_d0..2` under `FA_INST_n`, unpacks them with the generated
  `fa_instance_unpack` before `vertex()` and passes them as `flat` varyings `fa_inst_v0..2` to `fa_inst_load()`, which runs before
  `fragment()`. The memory cost is 4 copies of the values per quad (48 bytes per vec4 of a quad): 192 bytes at 3 vec4, against
  the 192 bytes of the quad's four `Vertex2D`.
- **Particles.** The instanced values of a particle are its emitter's `materialParams`. `QuadInput.life` (new) is the particle's
  age over its lifetime (the vertex's `shape_half.x` of modes 0 and 3, which no other mode uses there); it is 0 for every other item, a particle's trail ribbon included. `custom`
  stays reserved.
- **Vertex textures.** A sprite's vertex-stage views and samplers are 8.. and 7.. (after the fragment stage's 4.. and 3..), bound
  by `draw_group` next to the fragment ones; a mesh's are at 10.. and 6... The count of views stays at most 4 textures x 2 stages.

## Post materials (M72.2)

`engine/render/shaders/post_common.glsl` is the one program of a post material (`material_program_names(Post)` = `{"post"}`): a
full-screen triangle whose fragment shader reads the picture (`fa_scene_color`) and optionally the depth and normal prepass
(`fa_depth`, `fa_normal`) and calls the snippet's `post(in PostInput, inout PostSurface)`. Bindings: uniform block 0 (vertex,
the GL flip), 1 (fragment, `fa_a` = GL flip and linear scene, `fa_rc` = the camera's rectangle as fractions, `fa_size`,
`fa_time`) and 5 (the material, `kMaterialUbFragment`); views 0 `fa_scene` and 1 `fa_prepass` with samplers 0 (linear, clamped)
and 1 (nearest), a material's textures at views and samplers 2+ (`kMaterialPostFirstView`). The prepass is bound only when the
program declares it (the snippet calls `fa_depth` or `fa_normal`), which is what makes the renderer draw it for the camera.
The history (`fa_history(uv)`, `fa_history_valid` = `fa_a.z`) is view 6 (`kMaterialPostHistoryView`, after the material's four textures),
read through sampler 0 with the same `fa_flip_uv` as the scratch images; like the prepass it is bound only when the program declares it
(sokol-shdc drops an unused texture), and the precheck in `shaders_compile.cpp` refuses `fa_history` as a texture, `fa_history_valid(...)` as
a call and either in another kind. Which image is bound, and when it is valid, is the renderer's (`renderer_custom_post.cpp`, `CustomPost`).
`lighting`, `alphaMode` and `doubleSided` are refused for the kind; a graph is not generated for it.

- **The entry.** `PostProcess.customPasses` (a flat `Json` field: the stack keeps its flat component) holds `{material,
  materialParams, enabled, position, name}` entries; `fa/render/post_custom.h` is the one parser (`parse_custom_post_passes`, used by
  `postprocess.set`, the resolve and the report) and the one position table. A position names a built-in effect and a side;
  each row maps to a `PostSlot`: the scene-linear places (`Main`, `AfterSsr`, `AfterShafts`, `AfterDof`, `AfterBloom`) and the
  display-referred ones between the screen effects of `post.glsl` (`AfterTonemap`, `AfterGrading`, `AfterVignette`, `AfterSharpen`,
  `AfterOutline`, `AfterPosterize`, `AfterGrain`; `post_slot_is_ldr`), the places `build_graph` has.
- **The frame graph.** `renderer_custom_post.cpp` (`CustomPost::add_passes`, called by `build_graph` at each slot) reads the
  picture through the graph (`game` imported resource), runs the entries of the slot in array order over the camera's rectangle,
  and ping-pongs between two transients of the picture's format (`custom-<slot>-pass<k>`); the last pass draws back into the
  rectangle of the picture with the bloom's destination rules (MSAA, hud over bloom), and a lone pass is copied back
  (`SceneFx::copy_into`). A display-referred slot cuts the final pass of `post.glsl` there (`PostSlice`, "The cut final pass" in
  ARCHITECTURE_RENDERING.md) and runs the entries on the image between two pieces, with `linear` false. The depth and normals are requested
  (`needsDepth`, `needsNormals`) only when a planned pass reads them.
- **Failures.** `make_custom_post_plan` asks `Assets::post_material` and a pass whose material did not build, is not a post
  material, is missing or needs a prepass the GPU lacks is dropped from the plan: `materialFallbacks` gets its path and the log
  one warning per `path|reason` (`warnedCustomPass`, cleared on a scene change). A hot reload swaps the material's programs as for
  the other kinds.
- **Reported.** `render.supports` has the Engine feature `postMaterials`; `postprocess.get {resolved: true}` has `customPasses`
  and `customPassProblems`; the editor's Post-processing panel edits the list (`postfx_custom.h` makes each edit one whole-array
  `postprocess.set`, one undo step).

## The sky material lights the meshes (M72 P15)

`engine/render/src/renderer_env.{h,cpp}` (`Environment`) bakes the sky program of the scene's sky material into a prefiltered cube
(128 x 128, 5 mips, GGX per mip) and an irradiance cube (8 x 8); the design, the pass count (60) and the format fallback are in
the header comment. `mesh_common.glsl` and `mesh_full_common.glsl` declare them (views 14 and 15, sampler 10; `fa_env_sky.w` is 1
when they are bound, `fa_env_horizon.w` the top mip) and `fa_environment()` and the new `fa_ambient_light(n)` read them, else the
analytic gradient and `fa_ambient.rgb` as before. Without a sky material the pixels and the draw calls are the same as before: no
pass, no environment image; only `blank_view()` makes a 1x1 black cube and a sampler at the first mesh draw (the built-in mesh
program always binds the slots), plus three bindings per draw and one uniform branch per fragment.

- **Plan.** `plan_env` (`renderer_draw.cpp`) declares a "sky-env" pass of the frame graph when a camera draws the world with a
  valid sky material. Its key hashes the material, its generation, params, textures, the scene's sky colours, the colour space,
  the sun when the twin says `usesSun` (the snippet reads `sun_dir` or `fa_sun`), and, for an **animated** material (the twin's
  `animated`, set by `compile_material` when the snippet reads `.time` or `fa_time`), the step `floor(time / kEnvTimeStep)`; the
  sky is baked at `step * kEnvTimeStep`: no wall clock, a replay gives the same frames. One environment per frame: the first job
  that wants it fixes the key, a job with another key uses the analytic path.
- **Order.** The shadow and prepass programs (and the `surface()` of an `alphaMode` `"clip"` material that runs in them) come
  before "sky-env": they read the cubes of the previous frame, black in the first one.
- **Faces.** The orientation is a table from the cube map specification (`env_face`); OpenGL renders bottom-up, so `up` is negated
  there. S0..S3 are separate 1-mip images, because GLES 3 and WebGL 2 cannot restrict a texture view to a mip.
- **Hook detection and the hints.** `lighting()` is the hook only with `SurfaceInput` and `Surface` as its first two parameters,
  and the errors that point at it (`definition`) use the same pattern, so an overload of the name is never the line they report. A
  name of the API that fails in the vertex stage (a helper compiled into both stages) gets the stage hint (fragment stage only,
  `#ifdef GL_FRAGMENT_SHADER`) with its signature, never "did you mean" itself. `fa_environment`, `fa_env_brdf`,
  `fa_sky_reflection` and `fa_ambient_light` may be called from `surface()`: they only read the sky images, which the shadow and
  depth programs of an `alphaMode` `"clip"` material have too.

Verified: Metal only (a mirror ball shows each side of a two-colour sky; a diffuse ball takes the ambient of the sky above and below;
no sky material: the same frame and draw calls; the bake runs again exactly when the key changes, for the sun only when the sky reads
it; the animated step; `ready()` after `blank_view()` keeps one sampler). Read only: the GL face orientation, D3D11, the RGBA8 fallback
and WebGL 2. Cost on Metal: about 2 to 3.5 ms on a frame that bakes (60 passes), 0.3 to 0.6 ms of it CPU (the test "what one bake of
the environment costs" reports it).
