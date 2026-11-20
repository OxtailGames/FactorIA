# FactorIA architecture: rendering, the lighting of M73

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page; the rendering page is
[ARCHITECTURE_RENDERING.md](ARCHITECTURE_RENDERING.md)). The user-facing description of the fields is
[RENDERING_LIGHTING.md](../rendering/RENDERING_LIGHTING.md). This page is what the packages M73.1 .. M73.6 share: the shader files, the
texture slots of the mesh fragment shader, the feature rows and the new fields. M73-P0 landed it with no visible change.

## The shader files of the mesh program

`mesh_common.glsl` (the mesh and skinned-mesh program of a mesh material) and `mesh_full_common.glsl` (a full-shader material, mode
`"full"`) used to carry their own copy of the lights and of the shadow lookup. They now include three files under `engine/render/shaders/`
(sokol-shdc `@block`s, pulled in with `@include`):

- **`light_data.glsl`** (block `fa_light_data`): `fa_light_texel(t)` (a `texelFetch` of the light data texture, view 24), the
  cluster lookup of a world position (`fa_cluster_lookup`, `fa_cluster_index`) and `fa_light_sample(li, world_pos)`, which turns
  light `li` of the table into a direction, an attenuation and a colour. Since M73.1a there is no `fa_lights` uniform block (it was
  three `vec4[32]`): see "Clustered lights" below. Area lights (M73.1b) change how a light is read here, once, for both templates.
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
| 24 `fa_light_data` (sampler 1, nearest, `texelFetch`) | M73.1a, RGBA32F: the lights and the clusters' light lists (landed); later decals, the sky's spherical harmonics | 1, 2 |
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
  is declared `unfilterable_float` and read through the nearest sampler 1 (sokol-shdc and WebGL2 want a sampler object in the
  shader even for a fetch; sampler 1 is the shadow atlas' nearest one); every linear, clamped atlas shares sampler 10 (today's
  environment sampler).
- No phase binds more than 16 fragment units (`kMeshMaxFragmentUnits`).

The phases: 0 is today (12 units). Phase 1 is M73.1, M73.2, M73.4 and M73.5 landed while the sky is still the two cubes (16 units).
Phase 2 is M73.3 landed: M73.3a retires the irradiance cube (nine spherical-harmonics `vec4` in the light data texture) and M73.3b/c the
prefiltered cube (the probe atlas takes its view 14); phase 2 binds 16 units too, so **no fragment unit is left** in the final state.
The screen slot (view 28) exists only in phase 2: contact shadows (M73.2c) and transmission (M73.6b) read it, so they come after
M73.3a, or they pack what they need into another row.

## Clustered lights (M73.1a)

The view is cut into a grid of **tiles of 64 px** (doubled while the grid would have more than 65536 clusters) by **24 depth
slices** between the camera's near and far depth, exponential (`slice = floor(log2(depth / near) * slices / log2(far / near))`). Every
local light is a sphere (its position and `range`); `src/light_clusters.cpp` gives each the box of clusters it reaches, the CPU builds
the list of lights of every cluster, and the lights and the lists are packed into **one RGBA32F texture** (1024 texels per row, a
power of two rows, texel `t` at `(t & 1023, t >> 10)`), written once per view (`Gpu::write_light_image`, a sokol transient image, so a
frame with more than 16 views commits like the transient buffers) and read by the fragment shader with `texelFetch`, the same on GL,
GLES3, WebGL2, D3D11 and Metal. No compute shader, no storage buffer: the build is a CPU job.

- **Layout** (documented at the top of `light_data.glsl`): `[0, 4L)` the light table, four texels per light (position and range, or the
  direction to a directional light; colour times intensity and the type; the spot axis and `cos(outer)`; `cos(inner)`, 2 meaning "the
  default fade" and three reserved components for the cookie and IES of M73.1b); then one texel per cluster (slot of its first light
  index, how many lights), slice-major, then row, then column; then the light indices, four to a texel.
- **Who is in the table.** The directional lights come first (at most 32, `kMaxDirectionalLights`; the shadow caster is light 0) and
  belong to every cluster, they are not in the lists. Then the local lights in the order of `select_lights` (at most 1024 in all,
  `kMaxLights`). A light list is in ascending table order, so a loop over "the directional lights, then the cluster's list" adds the
  lights in the order of the old loop over the table: a frame with up to 32 lights is the same picture as before (the goldens did not
  change). `Light.innerAngle` is stored in texel 3.
- **Which cluster a fragment is in** is computed in the shader from the same `viewProj` rows the vertex stage uses (`fa_cl_vpx`,
  `fa_cl_vpy`, `fa_cl_vpw`, in `fa_mesh_fs_params`) and a forward-depth row (`fa_cl_fwd`), never from the window position, so GL's and
  D3D's window conventions and a render target's flip do not matter. A fragment outside the view's tile range gets no local lights.
  The CPU range of a light is conservative: two pixels of margin per tile, a relative margin of 2e-3 in depth, and a corner of the
  light's box nearer than 1e-4 to the camera plane makes the whole view its range.
- **Deterministic job.** The ranges are computed per light in chunks, the counts and the fill per slice (the clusters of a slice belong
  to one chunk), the prefix is serial in cluster order and the lights are added in ascending order: the lists are the same bytes with
  the pool stopped, inline or with 1, 2 or 8 workers (`light_clusters_tests.cpp`). Every limit is a count: **1024 lights** per view,
  **32 directional**, **128 lights per cluster** (the first 128 in table order stay), **524288 list entries per view** (the last
  clusters lose the rest). The renderer reports them in the render stats: `lightsDropped` (over 1024 or 32), `lightsCulled` (local
  lights whose range is outside the camera frustum, left out of the table), `lightClusters`, `lightClusterEntries`,
  `lightMaxPerCluster`, `lightClusterClipped` (entries lost to the 128 and the 524288: 0 is normal).
- **The shader API keeps its names.** In the `lighting()` hook of a snippet material `fa_light_count()` and `fa_light(n, i)` now give
  the lights of **this fragment's cluster**: the directional lights, then the local lights that reach it, so a loop over them costs a
  few lights, not hundreds. The standard PBR loop and `light()` run over the same list. A **full shader** (`mode: "full"`) has no
  surface to ask the cluster of, so its `fa_light_count()` is `min(lights, 32)` (the first lights of the table, as before) and its
  `fa_light(index, ...)` takes an index of the table; it gets `fa_cluster_light_count(world_pos)` and `fa_cluster_light_index(n,
  world_pos)` for the lights of a position's cluster.
- **Cost.** The cluster build of 1000 lights on a 1920x1080 view (30 x 17 x 24 clusters, about 300000 list entries) takes under a
  millisecond on one core of an M-series Mac (`light_clusters_tests.cpp` prints it); the texture of such a view is 1 MiB of RGBA32F.
  A view with no local light builds no clusters: its texture holds the directional lights only.
- **Not here yet.** Area lights, cookies and IES profiles (M73.1b) use the reserved texel components; a spot's cone is bounded by its
  full sphere (a tighter cone bound would only shorten the lists); shadows of local lights are M73.2.

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
