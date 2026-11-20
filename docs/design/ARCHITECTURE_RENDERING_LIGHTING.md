# FactorIA architecture: rendering, the lighting of M73

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page; the rendering page is
[ARCHITECTURE_RENDERING.md](ARCHITECTURE_RENDERING.md)). The user-facing description of the fields is
[RENDERING_LIGHTING.md](../rendering/RENDERING_LIGHTING.md). This page is what the packages M73.1 .. M73.6 share: the shader files, the
texture slots of the mesh fragment shader, the feature rows and the new fields. M73-P0 landed it with no visible change.

## The shader files of the mesh program

`mesh_common.glsl` (the mesh and skinned-mesh program of a mesh material) and `mesh_full_common.glsl` (a full-shader material, mode
`"full"`) used to carry their own copy of the lights and of the shadow lookup. They now include three files under `engine/render/shaders/`
(sokol-shdc `@block`s, pulled in with `@include`):

- **`light_data.glsl`** (block `fa_light_data`): the `fa_lights` uniform block (binding 2: three `vec4[32]` of position and range, colour
  and kind, direction and cone) and `fa_light_sample(i, world_pos)`, which turns light `i` into a direction, an attenuation and a colour.
  M73.1 changes how the lights are read (clusters, area lights) here, once, for both templates.
- **`shadow_common.glsl`** (block `fa_shadow_common`): `fa_shadow_pcf(coord, n, l)`, the 3x3 PCF lookup of the single directional shadow
  map. M73.2 grows it into the cascaded and atlas lookups. It reads the shadow texture through the macros `FA_SHADOW_TEX` and
  `FA_SHADOW_SMP`, which each template defines for its own names: sokol-shdc wants every `@image_sample_type` and `@sampler_type`
  directive once per top file, and the full template declares `fa_full_shadow_tex` / `fa_full_shadow_smp` itself.
- **`light_loop.glsl`** (blocks `fa_light_hooks`, `fa_light_hooks_none`, `fa_light_loop`): the Cook-Torrance loop over the lights, or the
  custom `light()` of a material, as text included inside `main()`.

The split changes no arithmetic: the render goldens are unchanged. Changing any of these files changes the template hash, so the
twin fixtures under `engine/render/tests/data/materials/materials/*.shader` are regenerated with a real sokol-shdc
(`FA_UPDATE_FIXTURES=1`, docs/design/CUSTOM_SHADERS.md). `CMakeLists.txt`'s `FA_TEMPLATE_FILES_*` lists and `template_file_names()` in
`tools/common/src/shaders_generate.cpp` list the same files in the same order (a test compares them).

## The texture slots of the mesh fragment shader

GLES3 and WebGL2 guarantee 16 texture units per stage, sokol has `SG_MAX_VIEW_BINDSLOTS = 32` view slots and the engine
`kMeshSamplerSlots = 12` sampler slots. The lighting of M73 needs more data than that has room for as separate textures, so the
packages pack their data into a few slots, and the table in `engine/render/src/render_internal.h` (`kMeshFragmentViews`) gives each
its number up front, so no package renumbers another's. A package that needs a slot takes its row; one that needs another packs its data
into a row or changes the table together with the `static_assert`s under it.

| Slot (view, sampler) | Holds | Phases |
|---|---|---|
| 0 `fa_tex` (0, 0) | base colour | 0, 1, 2 |
| 1 `fa_shadow_tex` (1, 1) | the directional shadow map; from M73.2 the shadow atlas (cascades, spot and point faces), same slot, nearest sampler | 0, 1, 2 |
| 2..5 normal, metallic-roughness, occlusion, emissive (views 2..5, sampler 0) | the material's maps | 0, 1, 2 |
| 6..9 (samplers 2..5) | the four textures of a custom material | 0, 1, 2 |
| 14 `fa_env_tex` (sampler 10) | the baked sky, a prefiltered cube | 0, 1 |
| 15 `fa_irr_tex` (sampler 10) | its irradiance cube | 0, 1 |
| 14 `fa_probe_atlas` (sampler 10) | M73.3b/c: reflection probes and the sky, octahedral 2D, prefiltered by roughness; replaces the cube | 2 |
| 24 `fa_light_data` (no sampler, `texelFetch`) | M73.1a, RGBA32F: lights, the clusters' light lists, decals, the sky's spherical harmonics | 1, 2 |
| 25 `fa_light_atlas` (sampler 10) | M73.1b: cookies and IES profiles, one RGBA8 atlas | 1, 2 |
| 26 `fa_lightmap` (sampler 10) | M73.4a: the lightmap page of the entity drawn (RGBA16F, one page per draw; a white texel when it has none), read at its lightmap UV | 1, 2 |
| 27 `fa_decal_atlas` (sampler 10) | M73.5b: decal textures (their transforms are in `fa_light_data`) | 1, 2 |
| 28 `fa_screen_tex` (sampler 10) | M73.2c and M73.6b: the prepass depth for contact shadows, the opaque colour for transmission | 2 |

Rules the table follows, each checked by a `static_assert` (`mesh_fragment_views_valid()`, `mesh_fragment_units(phase)`) and by
`engine/render/tests/mesh_slots_tests.cpp`:

- The material keeps its views 6..9 and samplers 2..5. Its copies for the vertex stage (views 10..13, samplers 6..9) are in the
  VERTEX stage and do not count against the 16 fragment units.
- Views 16..23 are the read-only storage buffers of a mesh material (`kMeshBufferFirstView`, M72.4; GL 4.3, Metal and D3D11 only; they
  are not texture units). The views M73 adds therefore start at 24 (`kMeshNewViewFirst`).
- No two slots bound in the same phase share a view, every view is below 32 and every sampler below 12. Data read with `texelFetch`
  needs no sampler; every linear, clamped atlas shares sampler 10 (today's environment sampler).
- No phase binds more than 16 fragment units (`kMeshMaxFragmentUnits`).

The phases: 0 is today (12 units). Phase 1 is M73.1, M73.2, M73.4 and M73.5 landed while the sky is still the two cubes (16 units).
Phase 2 is M73.3 landed: M73.3a retires the irradiance cube (nine spherical-harmonics `vec4` in the light data texture) and M73.3b/c the
prefiltered cube (the probe atlas takes its view 14); phase 2 binds 16 units too, so **no fragment unit is left** in the final state.
The screen slot (view 28) exists only in phase 2: contact shadows (M73.2c) and transmission (M73.6b) read it, so they come after
M73.3a, or they pack what they need into another row.

## The feature rows

`render_features.cpp` has one row per feature (docs/design/ARCHITECTURE_RENDERING.md, "What the GPU can do"). M73-P0 added `float32Targets`
(the `needs` word `float32`: `R32F` and `RGBA32F` render and sample, read with `sg_query_pixelformat`) and 21 engine rows planned
`"M73"`: `clusteredLights`, `areaLights`, `lightCookies`, `iesProfiles`, `cascadedShadows`, `pointShadows`, `spotShadows`,
`contactShadows`, `environmentMap`, `reflectionProbes`, `physicalSky`, `lightmaps`, `lightProbes`, `volumetricFog`, `decals`,
`subsurface`, `realtimeGI`, `clearCoat`, `sheen`, `anisotropy`, `transmission`. Each carries the `needs` its pass will ask of the GPU.
`needs_met` runs before the planned check, so on a GPU that lacks the capability the answer names the capability, not the plan. The
package that draws a feature drops its `"M73"` text from the table.

## The new fields

`Light`, `SceneSettings` and `MeshRenderer` (`engine/scene/include/fa/scene/components.h`, registered in `components.cpp`) got the fields
listed in the user page, each with a doc string that says "No effect yet: M73.x brings it". They are plain reflected fields: range and
enum checks come from the reflection (`field_from_json`), and a default is not written to a scene file, so old scenes and the saved
form of an unchanged scene are the same. `LightType` gained `Area` (last, so the numbers of the others do not move); until M73.1 the
renderer treats it as a point light (`renderer_draw.cpp`, `scene2d.cpp`). The M73.x package that makes a field work removes "No effect
yet" from its doc string and updates the tables in RENDERING_LIGHTING.md.

## Lightmaps

M73.4a: the runtime that draws a baked lightmap, and the UVs it needs. The baker core is [ARCHITECTURE_BAKING.md](ARCHITECTURE_BAKING.md);
the `lightmap.bake` command that writes the files (M73.4c) and the light probes (M73.4d) are later packages. The user page is
"Lightmaps" in [RENDERING_LIGHTING.md](../rendering/RENDERING_LIGHTING.md).

**Lightmap UVs** (`fa/render/lightmap_geometry.h`, `fa/scene/lightmap_uv.h`). A mesh's lightmap UV is TEXCOORD_1 of its glTF when every
part has it (it must lie in 0..1 without overlap; one outside the square is refused with a message that says so), else an unwrap of the
whole mesh by `generate_lightmap_uv` (xatlas through `model_uv_apply`, single-threaded, `fa::det` trigonometry: the same bits on every
platform and run, no seed or setting). The unwrap splits vertices along the seams of its charts, so the drawn mesh is not the file's mesh:
`build_lightmap_mesh` returns the split vertices (every vertex field copied from the vertex it was split from) and the renderer keeps
them in buffers of their own next to the mesh (`MeshAsset::lightmap`), built on the first use and dropped when the mesh file reloads.
Nothing is written next to the model. The primitives (`cube`, `sphere`, ...) are unwrapped the same way. `lightmap_mesh_geometry(mesh)` is the
GPU-free half the baker calls, so bake and draw use the same vertices. A triangle with no area (a sphere's pole) is not placed by the
unwrap: its UVs are clamped into the square. `kLightmapUvVersion` is bumped when the unwrap changes what it returns.

**Files.** `SceneSettings.lightmaps` names a manifest (`scenes/level.lightmap.json`, `fa/scene/lightmap_manifest.h`) and the manifest names
the pages: Radiance `.hdr` images, project-relative, one per atlas. Each entry says which entity (its stable `EntityInfo.id`), which mesh
and UV kind and hash it was baked for, which page, and the rectangle `scaleOffset = [sx, sy, ox, oy]` of the page it owns: page uv =
lightmap uv * (sx, sy) + (ox, oy). Page uv (0, 0) is the top-left and the file's first row is the baker's row 0 (v = 0), a texel is
irradiance / pi in linear colour (what a white diffuse surface shows). `parse_lightmap_manifest` checks the keys (with a "did you mean"),
sizes, page indices and rectangles, and every error carries the file, the JSON pointer and the fix. Tests pin the orientation twice: the
scene module (bake row 0 against the file) and `engine/render/tests/lightmap_tests.cpp` (a glTF quad whose second UV set is the unit square).

**Loading.** `Assets::lightmaps(path)` reads the manifest and decodes the pages into RGBA16F images on the first frame of a scene that
names one, and keeps the result (a failure too, so a broken manifest is reported once, not per frame). Failures are
`Assets::note_failure` kinds in `render.assets`' `failures`: `lightmap` (manifest), `lightmap-page` (a page that cannot be read) and
`lightmap-stale` (an entry whose mesh hash or UV kind is not what the mesh gives now: the model changed since the bake). A failed entity or
page is drawn without a lightmap, as before; the rest of the scene is not touched. The runtime's hot reload watches `*.lightmap.json` and
`.hdr` files and calls `Assets::reload`, which drops the set and the per-mesh buffers.

**Drawing.** `RenderScene::build` asks for the entity's use (`Assets::lightmap_use`): the entity must be in the manifest, have
`MeshRenderer.receiveGI` and `lightmapScale > 0`, a mesh that is not skinned, and a material that can take the UV (below). A lightmapped
item is never batched with another (the entity bits are part of its sort, order and material keys) and is drawn with its own vertex buffers,
the page bound at view 26 and the rectangle in the vertex uniform `fa_lm_so` (x = 0 means not lightmapped). The vertex stage forwards
`fa_lm` (page uv, and 1 when lightmapped) and the fragment stage's `fa_indirect_diffuse(n)` returns the texel instead of `fa_ambient_light(n)`:
the baked irradiance **replaces** the ambient light and the sky's diffuse term of that surface, the specular IBL (`fa_sky_reflection`) stays.
Lights whose `mode` is `baked` are zeroed on lightmapped entities (a CPU copy of the light uniforms, so the shadow caster slots keep their
meaning); `mixed` and `realtime` lights are drawn as always, and an entity with no lightmap entry is lit by every light, baked ones
included: nothing goes dark before the bake. A scene without `SceneSettings.lightmaps` binds a white texel and the pictures are the same as
before (the goldens did not change).

**Materials.** The engine's own mesh program always has the `uv1` vertex attribute (location 9; a zero buffer, `Assets::zero_uv1`, when the
entity is not lightmapped). A custom mesh material gets the lightmap only if it lists `"uv1"` in `vertexAttributes` (`FA_CH_UV1`): its `uv1` then
carries the **lightmap UV** on a lightmapped entity instead of the model's TEXCOORD_1, so a material that textures with the second UV set
and is lightmapped must not be (give the entity `receiveGI: false`, or read the second set through its own `uv` channel). A full-shader
material and a material that reads compute buffers are drawn without the lightmap: they have no `fa_lm` varying, the entity is lit as
before. `FA_LM_BUILTIN` (defined only by `mesh.glsl`) and `FA_LM_PASS` (only the `vs` program) keep the shadow and depth-prepass programs
from declaring the attribute. The twin fixtures were regenerated for the new vertex layout.

**Decisions.** One page per draw (an entity is one rectangle of one page): batching and the 16-unit budget stay as they were. An entity
that `MeshRenderer.lods` draws with another mesh than `MeshRenderer.mesh` is lit as without a lightmap while that level is drawn (the
bake was made for the mesh the manifest names). Skinned meshes are never lightmapped.

