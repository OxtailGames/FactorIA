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
| 26 `fa_lightmap` (sampler 10) | M73.4a: the lightmap atlas, UV2 of the mesh | 1, 2 |
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
