Part of [custom shaders](CUSTOM_SHADERS.md), "Kinds (M72)": the two kinds built on the mesh design, sprite and sky, with their
template, tooling and draw. The shared base (the `kind` key, the per-kind template hash, the skeletons) is on that page.

# Custom shaders: the sprite and sky kinds

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
  a mesh material uses views from 6 and samplers from 2, and a second set at 10.. and 6.. for the textures of its `vertex()`: a
  sprite has no vertex-stage views, so the compiler refuses a sprite `vertex()` that samples a material texture). `fa_time` and
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
  `RenderStats.materialFallbacks`. The meshes' ambient and reflection light (`fa_env_sky`, `fa_env_horizon`) and the
  reflection probes keep following `skyColor` and `horizonColor`: a sky material only paints the background.
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
- **Left for the next package:** `Shape2D`, `Tilemap`, `Text`, particles and UI call the same `QuadList::set_material`;
  `QuadInput.custom` stays zero.
