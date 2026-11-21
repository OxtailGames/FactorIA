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
- **`shadow_common.glsl`** (block `fa_shadow_common`): the `fa_shadows` uniform block (binding 7) and `fa_shadow_sun(world, n, l)`, the
  cascaded lookup of the directional shadow (cascade choice, blend between two, hard, PCF or PCSS filter), and `fa_shadow_debug`, the
  cascade tint of the debug view (see "The shadow atlas"). It reads the shadow texture through the macros `FA_SHADOW_TEX` and
  `FA_SHADOW_SMP`, which each template defines for its own names: sokol-shdc wants every `@image_sample_type` and `@sampler_type`
  directive once per top file, and the full template declares `fa_full_shadow_tex` / `fa_full_shadow_smp` itself.
- **`light_loop.glsl`** (blocks `fa_light_hooks`, `fa_light_hooks_none`, `fa_light_loop`): the Cook-Torrance loop over the lights, or the
  custom `light()` of a material, as text included inside `main()`.

The split of M73-P0 changed no arithmetic; M73.2a then replaced the shadow lookup (the goldens with shadows changed). Changing any of these files changes the template hash, so the
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
| 14 `fa_probe_atlas` (sampler 10) | M73-P3c: ONE 2D atlas, octahedral: entry 0 the baked sky, the others the reflection probes (prefiltered by roughness, an SH row each); the meshes no longer read the sky's cube | 0, 1, 2 |
| 15 | free: the irradiance cube is retired (its unit is the screen slot, 28) | 0 |
| 24 `fa_light_data` (sampler 1, nearest, `texelFetch`) | M73.1a, RGBA32F: the lights and the clusters' light lists, M73.5b the decal records and their cluster lists (landed) | 1, 2 |
| 25 `fa_light_atlas` (sampler 10) | M73.1b: ONE RGBA16F atlas: the LTC tables, the cookies and the IES profiles ("The light atlas") | 1, 2 |
| 26 `fa_lightmap` (sampler 10) | M73.4a: the lightmap page of the entity drawn (RGBA16F, one page per draw; a white texel when it has none), read at its lightmap UV | 1, 2 |
| 27 `fa_decal_atlas` (sampler 10) | M73.5b (landed): decal textures, RGBA8 with mips (their transforms are in `fa_light_data`); the white image while a view has no decals | 1, 2 |
| 28 `fa_screen_tex` (sampler 1, nearest, `texelFetch`) | M73.2c (landed, [screen effects](ARCHITECTURE_SCREEN_EFFECTS.md)): the prepass for contact shadows; M73.6b: the opaque colour | 1, 2 |

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
M73-P3e (M73.3a) retired the irradiance cube: the program binds 15 units and the freed one is the screen slot (view 28), the prepass of the
contact shadows (M73.2c) and later the opaque colour of transmission (M73.6b). Phase 2 is M73.3b/c landed: the prefiltered cube is
replaced by the probe atlas (it takes view 14); 16 units, so **no fragment unit is left** in the final state. The sky's nine
spherical-harmonics coefficients did not go into `fa_light_data` as first planned (see "The sky's spherical harmonics"); M73.3b/c moves
them to the probe atlas with the rest of the sky.

## Clustered lights (M73.1a)

The view is cut into a grid of **tiles of 64 px** (doubled while the grid would have more than 65536 clusters) by **24 depth
slices** between the camera's near and far depth, exponential (`slice = floor(log2(depth / near) * slices / log2(far / near))`). Every
local light is a sphere (its position and `range`); `src/light_clusters.cpp` gives each the box of clusters it reaches, the CPU builds
the list of lights of every cluster, and the lights and the lists are packed into **one RGBA32F texture** (1024 texels per row, a
power of two rows, texel `t` at `(t & 1023, t >> 10)`), written once per view (`Gpu::write_light_image`, a sokol transient image: 16 per frame, and when the 16 are used the next
`Gpu::begin_frame` forces a commit, like the transient buffers) and read by the fragment shader with `texelFetch`, the same on GL,
GLES3, WebGL2, D3D11 and Metal. No compute shader, no storage buffer: the build is a CPU job.

- **Layout** (documented at the top of `light_data.glsl`): `[0, 4L)` the light table, four texels per light (position and range, or the
  direction to a directional light; colour times intensity and the type; the spot axis and `cos(outer)`; `cos(inner)`, 2 meaning "the
  default fade" and three reserved components); in a view where any light is an area light or has a cookie or an IES profile every light has **eight** texels (`kLightTexelsExt`; the stride is in `fa_ambient.w`, 0 or 4 = four), the extension at `+4 .. +7` ("The light atlas"); then one texel per cluster (slot of its first light
  index, how many lights, and since M73.5b the slot of its first decal index and how many decals: 0, 0 without decals), slice-major, then
  row, then column; then the light indices, four to a texel; then the shadow region of the local lights (M73.2b, only with local shadows), then the decal
  region (only when the view has decals, see "Decals"). Light n is at texel `fa_light_base(n)` (`n * stride`); every reader of a light's texels goes through it.
- **Who is in the table.** The directional lights come first (at most 32, `kMaxDirectionalLights`; the shadow caster is light 0) and
  belong to every cluster, they are not in the lists. Then the local lights in the order of `select_lights` (at most 1024 in all,
  `kMaxLights`). A light list is in ascending table order, so a loop over "the directional lights, then the cluster's list" adds the
  lights in the order of the old loop over the table: a frame with up to 32 lights is the same picture as before (the goldens did not
  change). `Light.innerAngle` is stored in texel 3.
- **Which cluster a fragment is in** is computed in the shader from the same `viewProj` rows the vertex stage uses (`fa_cl_vpx`,
  `fa_cl_vpy`, `fa_cl_vpw`, in `fa_mesh_fs_params`) and a forward-depth row (`fa_cl_fwd`), never from the window position, so GL's and
  D3D's window conventions and a render target's flip do not matter. A fragment whose tile or slice falls outside the grid (the clamp of rounding at the edge of the view) reads the nearest edge cluster; one that is not in front of the camera, or a frame without clusters (`fa_cl_info.x = -1`, the value the renderer writes first for every view, also when it has no light), gets no local lights.
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
- **Not here yet.** A spot's cone is bounded by its full sphere (a tighter cone bound would only shorten the lists); shadows of
  local lights are M73.2b. An area light's sphere is its range plus the radius of its emitter (`LightData::extent`), so the clusters
  and the culling see the real extent.

## The shadow atlas, point and spot shadows and decals

The shadow atlas, the shadows of point and spot lights (M73.2b) and the decals (M73.5b) are on the page
[ARCHITECTURE_SHADOWS_DECALS.md](ARCHITECTURE_SHADOWS_DECALS.md).

## The light atlas

M73.1b: ONE RGBA16F image (view 25, `fa_light_atlas`) holds the LTC tables of the area lights, the cookies and the IES profiles, and the
light table has eight texels per light when a light uses them (the stride is in `fa_ambient.w`). The whole description (layout of the
image, the texels of a light, shading, shadows, approximations, tests) is in
[ARCHITECTURE_AREA_LIGHTS.md](ARCHITECTURE_AREA_LIGHTS.md), "The light atlas and the area-light shading".

## The feature rows

`render_features.cpp` has one row per feature (docs/design/ARCHITECTURE_RENDERING.md, "What the GPU can do"). M73-P0 added `float32Targets`
(the `needs` word `float32`: `R32F` and `RGBA32F` render and sample, read with `sg_query_pixelformat`) and 21 engine rows planned
`"M73"`: `clusteredLights`, `areaLights`, `lightCookies`, `iesProfiles`, `cascadedShadows`, `pointShadows`, `spotShadows`,
`contactShadows`, `environmentMap`, `reflectionProbes`, `physicalSky`, `lightmaps`, `lightProbes`, `volumetricFog`, `decals`,
`subsurface`, `realtimeGI`, `clearCoat`, `sheen`, `anisotropy`, `transmission`. Each carries the `needs` its pass will ask of the GPU.
`needs_met` runs before the planned check, so on a GPU that lacks the capability the answer names the capability, not the plan. The
package that draws a feature drops its `"M73"` text from the table (`clusteredLights` did in M73.1a, `cascadedShadows` in M73.2a: it needs only `float32`, `decals` in M73.5b: it needs nothing, `areaLights`, `lightCookies` and `iesProfiles` in M73.1b: they need `half`, RGBA16F images that filter, the atlas format, `environmentMap` in M73-P3a-2: it needs `half`, the RGBA16F targets the environment cubes are, and `volumetricFog` in M73.5, with `half+depth`, and `contactShadows` in M73.2c, with `depth`).

## The new fields

`Light`, `SceneSettings` and `MeshRenderer` (`engine/scene/include/fa/scene/components.h`, registered in `components.cpp`) got the fields
listed in the user page, each with a doc string that says "No effect yet: M73.x brings it" (the layers of M73.6a and the area, cookie and IES fields of M73.1b are drawn: see "The material layers" and "The light atlas"). They are plain reflected fields: range and
enum checks come from the reflection (`field_from_json`), and a default is not written to a scene file, so old scenes and the saved
form of an unchanged scene are the same. `LightType` gained `Area` (last, so the numbers of the others do not move); the 3D renderer shades it with the LTC tables since M73.1b, the 2D
lighting (`scene2d.cpp`) still treats it as a point light. The M73.x package that makes a field work removes "No effect
yet" from its doc string and updates the tables in RENDERING_LIGHTING.md.

## The material layers

M73.6a (clear coat, sheen, anisotropy, specular / IOR; the user page is [RENDERING_LIGHTING.md](../rendering/RENDERING_LIGHTING.md)).

**Where it lives.** `brdf_layers.glsl` (blocks `fa_layers_env`, `fa_layers_light`, included by `mesh_common.glsl` and
`mesh_full_common.glsl`) holds `struct FaLayers`, `fa_layers_setup`, `fa_layers_ibl`, `fa_layers_light` and the sheen albedo table
`FA_SHEEN_E`; the `Surface` struct of both templates gained `clearcoat`, `clearcoat_roughness`, `sheen_color`, `sheen_roughness`,
`anisotropy`, `anisotropy_rotation`, `specular`, `specular_color` and `ior` (so a custom material's snippet can write them, all default to
"off"; the existing snippets compile unchanged). `light_loop.glsl` calls `fa_layers_light` for each light in a branch `if (lay.on)`;
the else branch is the Cook-Torrance code as it was before, line for line, so a material without layers is bit-identical.

**Uniforms.** Four vec4 appended at the END of `fa_mesh_fs_params` (and of its copy in `mesh_full_common.glsl`; a test compares them):
`fa_layers_a` = coat, coat roughness, anisotropy, rotation (radians); `fa_layers_b` = sheen colour rgb, sheen roughness;
`fa_layers_c` = specular, ior, flags of the packed textures (z), unused; `fa_layers_d` = specular colour rgb. Filled by `fill_layers` in
`renderer_draw.cpp`: a MeshRenderer value not at its default replaces the model's (`SubMesh::layers`, from the glTF) field by field;
a material in error draws no layer. The values are clamped (clearcoat and roughnesses 0..1, anisotropy -1..1, specular 0..1,
specularColor 0..16, ior 1..3; NaN is the default).

**The model.** Khronos' layering. Sheen: the base is scaled by `1 - max(sheenColor) * E(n.v, roughness)` and the Charlie lobe
(Estevez and Kulla) is added; `E` is the table `FA_SHEEN_E`, 7 roughness nodes `0.1 + 0.9 (i/6)^2` by 9 `n.v` nodes `(j/8)^2`, bilinear
(`tools/shaders/sheen_albedo.py --check`: worst error 0.06, mean 0.003). Coat: `keep = 1 - coat * F(n.v)` with F0 0.04 scales
the base and the coat has its own GGX lobe (Smith, F0 0.04) on the geometric normal. Anisotropy: GGX with `alpha_t` and `alpha_b` from
the roughness and the strength, the tangent turned by the rotation. Specular: `f0 = ((ior-1)/(ior+1))^2 * specular * specularColor` for
a dielectric. Defaults are bit-identical because the branches compare the exact defaults (`specular != 1 || ior != 1.5 || ...`),
and ior 1.5 with specular 1 is F0 0.04 exactly.

**Image-based light (approximations).** Coat: the environment along the geometric normal at the coat's roughness, with F0 0.04 and
`fa_env_brdf`. Sheen: the environment along the normal at the sheen roughness times `sheenColor` times `E`. Anisotropy: the reflection
vector is bent toward the tangent (the bent normal of McAuley 2015) before the lookup. None of them is energy-conserving beyond what the formulas
above give.

**The textures.** `pack_layer_textures` (`engine/render/src/layer_textures.cpp`, called by `prepare_material` in `assets.cpp` for both
the loader of models and the `MeshData` path) builds the two composite images described in the user page; they are
`PreparedTextureRef::Kind::Image` named `<gltf-layers:path:material>:occlusion|metalRough`, shared by the parts of a model through
`MeshLoader::packedTextures_`. The shader reads the flags in `fa_layers_c.z` (bit 1: the occlusion map holds coat G, coat roughness B,
sheen roughness A; bit 2: the metallic-roughness map holds anisotropy R and specular A), so a model without packing keeps the
channels it always had. Sources are decoded from the file; an export that lost the PNG uses the `.ktx2` twin. Everything not packed is
a warning from `prepare_layers`.

**Where the factors are read.** `read_material_layers` (`engine/scene/src/material_layers.cpp`) is the one reader: the render loader and
`gltf_mesh.cpp` (editable meshes; `MeshMaterial::layers`, written back by `mesh_to_glb` with `extensionsUsed`) both call it.

**Tests.** `engine/scene/tests/test_material_layers.cpp` (each extension read, clamped, round-tripped);
`engine/render/tests/material_layers_tests.cpp` (the packing, `decode_gltf` of small glTF files, the F0 equivalence, a layer that has
nothing to add draws the plain picture, the golden `3d_material_layers`: a row of spheres per layer).

## The physical sky (M73-P3d)

`SceneSettings.skyModel = physical` (user page: RENDERING_LIGHTING.md, "The physical sky"). The code is four files:

- `src/physical_sky.h/.cpp`: the CPU half, plain `double`/`float` arithmetic with no GPU object (so the tests check it and every machine
  agrees): the coefficients of the air in km (`sky_air`: Rayleigh from the molecular-scattering formula with the King factor, aerosols
  from the turbidity-to-optical-depth law, ozone from its cross sections), the optical depth along a ray (`sky_optical_depth`, the same
  quadratic-step march the GPU table uses), the colour factor of the sun light (`sky_sun_light_factor`: air times the cloud factor, relative
  to a sun overhead), the clamped settings (`physical_sky_settings`: a script can write any number), the quantisation of the environment's
  state and the hashes (keys) of each table, and the 8 `vec4` of the shader's block (`sky_shader_params`).
- `shaders/sky_physical.glsl` (module `skyphys`, four programs): `transmittance` (128 x 64: the optical depth of the air towards the top of
  the atmosphere, parameterised by the stable horizon cosine `muH = -sqrt(h(2R+h))/(R+h)` so it has no seam at the horizon), `multiscatter`
  (32 x 32: the second order and onwards as a geometric series, 32 directions x 16 steps, psi = L / (1 - F)), `skyview` (128 x 128: the
  sky radiance as a function of the elevation, concentrated at the horizon, and the azimuth relative to the sun, so the table does not turn
  with the sun) and `sky` (the full-screen draw: the table, the sun disc with limb darkening, the clouds, the encoding to sRGB in a gamma
  scene). Radiance is stored per unit of sun irradiance; `fs_sky` multiplies by the colour of the light, the exposure and pi (the engine's
  lights are not divided by pi). The tables are drawn with `gl_FragCoord / size`, so the image is the same on GL, D3D11 and Metal.
  The atmosphere maths needs `highp`: the generated GLSL ES 3.00 fragment shaders default to `precision mediump float;` but sokol-shdc qualifies every float, vector and matrix declaration `highp`, and a test (`physical_sky_tests.cpp`) scans the four programs' GLES3 sources for a declaration without it. The tables are RGBA16F.
- `src/renderer_sky_phys.h/.cpp` (`PhysicalSky`): owns the shaders, the four images, the pipelines and a sampler; `ready()` makes them on first
  use and refuses (logging once) a GPU without RGBA16F render targets that filter; `update(slot, state)` draws the air tables when
  `sky_air_key` changed and the sky view of the slot when `sky_view_key` (air + the sun's height) changed; `draw()` draws the sky into the open
  pass. Slot 0 is the picture (the sun and the clock of the frame), slot 1 the environment (the quantised ones), so the environment never
  depends on the frame rate.
- `src/renderer_draw.cpp`: `collect_lights` finds the sun (lights[0] after `select_lights`, when directional: the shadow caster, else the brightest directional light) and multiplies it by the transmittance and cloud
  factor (`skyTintsSun`); `plan_env` plans the bake for a physical sky as it does for a sky material, with the key `sky_env_key`; the frame graph
  gets a `sky-view` pass (first job of the frame that shows the sky; the main pass reads its resource) and the `sky-env` pass calls
  `PhysicalSky::update(1)` at the start of a bake.

**Bake amortisation.** `Environment` (`renderer_env.h`) bakes in 60 passes: the sky into the cube, the pyramid, the GGX prefilter of the mips,
the irradiance. `bake_slice` runs them in `kEnvSlices = 3` calls (24, 18, 18 passes), one per frame: the first draws the sky of that moment
(the later slices finish the images from it, so a sequence never mixes two skies) and the old cubes stay valid until a slice replaces a part.
`plan_env` decides per frame (`decide`): a whole bake when nothing was baked, when the static key (`sky_env_static_key`: air, sun colour,
exposure, clouds' shape, linear flag) differs from the tag stored with the last bake, or when the sun's quantised direction is further than
`kSkyBakeJump` (1/64 of a chord, about a degree) from it; a slice sequence when only the sun (a quarter of a degree steps) or the clouds'
clock (2 s steps, only for drifting clouds) changed, or while a sequence is running. Everything that picks the work is a deterministic
count of frames and quantised state, never time or the speed of the machine. The sun disc is left out of the environment bake (the
light is the sun there: it would count twice).

Not done here: clouds that cast per-point shadows on the ground (the sun light is tinted by the average of the cloud layer), the aerial
perspective of the atmosphere on the meshes (fog is the fog), an observer that moves up through the air, a physical night sky (stars,
moon). The tests are `engine/render/tests/physical_sky_tests.cpp` (the CPU half, the tables built when they should be, the amortisation,
four goldens: noon, sunset, overcast, a metal sphere).

## The environment from an HDRI (M73-P3a-2)

`SceneSettings.environmentMap` (user page: RENDERING_LIGHTING.md, "The environment map"). One bake, one set of cubes: the picture is drawn into
the cube the sky was drawn into, and the prefilter and the SH pass that follow are the sky's. The files:

- `include/fa/render/hdri.h`, `src/hdri.cpp`: the CPU half, shared by the renderer, `assets.import` and `project.validate` so a file one
  accepts is a file the others load, with the same words when not. `hdri_check` (header only: `hdr_info` in core reads the size and the
  exposure; layout rule within 1 % of 2:1 with a named wrong layout; the decode budget 8192 x 4096 on 64-bit, 4096 x 2048 on 32-bit; checked
  before any pixel memory), `hdri_from_bytes` (decode, NaN/negative to 0, box-shrink to `kHdriMaxWidth`, scale texels above `kHdriMaxValue` by
  one factor for the three channels, convert to half bits, the whole mip chain), `hdri_uv` (the CPU twin of the shader's mapping; a test
  compares orientation and rotation).
- `shaders/hdri.glsl` (module `hdri`, one program, generated header committed): a full-screen triangle that rebuilds the world ray from the
  inverse view-projection, rotates it by minus the rotation, maps it with `atan2` / `asin`, and samples the picture. The mip is computed in the
  shader from `length(fwidth(dir))`, not from the UV derivatives, so the seam of `atan2` does not pick the smallest mip. The sampler repeats in u
  and clamps in v. No orientation difference between GL, Metal and D3D11: the ray comes from the same matrix as the physical sky's, not
  from the texture's row order. `fs_params.p`: rotation (radians), gain, 1 to encode sRGB, width.
- `src/renderer_hdri.h/.cpp` (`HdriSky`): the program and the pipelines (`ready()` makes them once, logs once when it cannot, as `PhysicalSky`
  does) and `draw()`. The comment at the top of the header is the one place that states the precedence.
- `src/assets.cpp` `Assets::hdri(path)`: a cache of `HdriAsset` (the RGBA16F image with its mips; a serial that changes on hot reload, a retry
  once for a file that is still being written, `note_failure` kind "hdri", counted in `texture_bytes()`); `reload()` and `clear()` drop it.
  Needs the RGBA16F sample and filter capability: else one error and no map.
- `shaders/env.glsl` / `src/renderer_env.cpp`: `Environment::set_look(gain, tapLimit)` (two numbers the bake takes when it starts; a slice sequence
  keeps the look it started with). The level-0 copy, the prefilter and the SH pass multiply by the gain, so the intensity also lights from a
  sky material or the physical sky; a tap limit of 0 (every sky but an HDRI) leaves the maths as it was, and with gain 1 the multiplications are
  exact: scenes without an `environmentMap` are bit-identical (their goldens did not change).
- `src/renderer_draw.cpp` `plan_env`: loads the picture, decides `hdriMain` (the main pass draws the HDRI: it loaded, `environmentBackground`,
  no `skyMaterial`), builds the key (path hash, the asset's serial, the image id, the rotation rounded, the linear flag, the gain) and calls
  `set_look`; `decide` compares it as for a sky material, so only a change of map, rotation, intensity or file bakes, in one frame (a whole
  bake, never sliced: nothing moves slowly). `skyMaterial` still wins the background: `mat` is null while an HDRI lights, so the sky material
  is drawn by the main pass and not baked.

Highlights: see the user page. After the gain (`environmentIntensity`, up to 100) `env_out` in env.glsl and the background in hdri.glsl limit the brightest channel to 65000, colour kept, because the cubes and the scene target are RGBA16F (max 65504); the GPU test "a sun at the largest value times a big intensity" guards it (Metal turns an infinity into white, so it is D3D11 and GL that it catches). The two limits are `kHdriMaxValue` (60000, on the CPU, so the half never overflows to infinity before the gain) and `kHdriTapLimit` (64, per
sample of the blurred levels and the SH pass, in the shader). Not done here: a picture as a light source that casts shadows (the sun of
the picture does not cast a shadow: place a directional light), several maps blended, a cube map or a mirror-ball file, a map per camera or per
area (reflection probes, M73.3). The tests are `engine/render/tests/hdri_tests.cpp` (the CPU half, the orientation and the rotation, the
colour spaces and the intensity, the bake key counted in draw calls, hot reload, a file that cannot be used, precedence, determinism, the golden
`3d_hdri_spheres`) and `tools/common/tests/assets_hdri_test.cpp` (import, its errors and validate).

## The sky's spherical harmonics (M73-P3e)

The diffuse ambient light under a sky (sky material, physical sky, HDRI) is the sky's radiance as **L2 real spherical harmonics, nine RGB
coefficients**, convolved with the clamped cosine and divided by pi in the mesh shader (`fa_sh_eval`, `light_data.glsl`). The 8 x 8
irradiance cube (view 15) is gone. The CPU half is `ShL2` of `fa/scene/lightmap_bake.h` (`sh_basis`, `sh_irradiance`, `sh_project_cube`,
which the tests compare the GPU with): the sky and the light probes of M73.4d share one basis (Y00, y, z, x, xy, yz, 3z^2-1, xz, x^2-y^2),
one normalisation and one evaluation.

Why the coefficients live in a mip of the sky cube (the other choices: a `fa_light_data` row or a uniform; a texture of their own):

- **They must exist for every sky.** A sky material is only a GPU program and sokol has no general GPU readback, so the CPU cannot compute
  them for a row or a uniform. The pass `fs_sh` (`Environment::bake_sh`, 6 of the 60 passes of `kEnvPasses`) sums the smallest pyramid
  image (16 x 16 per face), each texel at its exact centre, times the basis times its solid angle normalised to 4 pi (a sky of one colour
  gives `c0 = L * sqrt(4 pi)` and `L` toward every normal). The loop is fixed, so a sky gives the same coefficients every run.
- **No new texture unit** (16 of 16 on GLES3 and WebGL2). The cube (view 14) is bound already and its mip 5 (4 x 4 per face,
  `kEnvShMip`) is below what a reflection reads (mip 4 at most): texel (c, r) of face +X holds coefficient c + 4 r, the rest is zero,
  and `fa_sky_sh_coef` reads it with `textureLod(..., 5.0)` at the texel centre (no filtering error).
- **The same re-bake keys**: baked with the sky (`envKey`, the slices of `bake_slice`, the one-frame bake of an HDRI), never per frame.
- A lightmapped surface keeps the P4a rule: its baked texel replaces the diffuse ambient (`fa_indirect_diffuse`), the specular IBL stays.

**Windowing.** Three bands cannot hold a sun and ring below zero on its far side. No extra window: the clamped-cosine factors (1, 2/3, 1/4)
already are the smoothest window an irradiance can have, a further one (Hanning, Lanczos) darkens a smooth sky for nothing, an HDRI's
sun is limited to `kHdriTapLimit` per tap, and `fa_sh_eval` clamps at 0. Measured against the brute-force cosine integral (what the old
cube held): `test_lightmap_bake.cpp` "sky SH" (gradient within 0.0001, cosine lobe 0.005; a 3 degree sun of 2000 over 0.2 is the worst
case, 12 % mean error: use a directional light for a sun) and `env_sh_tests.cpp` on the GPU (colour 0..1, 14 normals: the worst normal of
the gradient, the physical sky and an HDRI picture is within 0.003, 0.005, 0.005).

**Formats.** RGBA16F: the coefficients as they are (a component limited to 65000). RGBA8 (`fa_atlas.y` = 1; `force_rgba8_for_tests`):
`clamp(c / 4, -1, 1) * 0.5 + 0.5`; a sky of radiance 1 has `c0 = 3.5`, so an LDR sky fits (0.015 from the half-float result in the test).
**GLES3:** every float of `fs_sh` and of `fa_sh_eval`, `fa_sky_sh_coef`, `fa_ambient_light` is `highp` (a test scans the GLSL ES 3.00
source); the face table is a function because sokol-shdc leaves a global constant array at mediump. `fa_ambient_light(n)` works wherever
view 14 is bound (`surface()`, `light()`, `ambient()`, `lighting()`, the shadow and depth passes).

## Lightmaps

M73.4a: the runtime that draws a baked lightmap, and the UVs it needs. The baker core is [ARCHITECTURE_BAKING.md](ARCHITECTURE_BAKING.md);
the `lightmap.bake` commands that write the files (M73.4c) are in the same page, "The lightmap.bake commands"; the light probes (M73.4d) are a later package. The user page is
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
`fa_lm` (page uv, and 1 when lightmapped; declared last in both stages, after the vertex colour, so the varyings match by order on every backend; the shadow and prepass programs have no `fa_lm`) and the fragment stage's `fa_indirect_diffuse(n)` returns the texel instead of `fa_ambient_light(n)`:
the baked irradiance **replaces** the ambient light and the sky's diffuse term of that surface, the specular IBL (`fa_sky_reflection`, and
`fa_layers_ibl` with material layers) stays. A layered material (clear coat, sheen, ...) takes the texel where it took the ambient light
(`fa_indirect_diffuse(n) * diffuse_color * occlusion`, then times the layers' `base_scale`): the layers' own ambient terms are specular
(their IBL reflection), so the ambient is not counted twice and not missing.
Lights whose `mode` is `baked` carry a flag in the light data texture (texel +3, component w: 1 = baked, 0 otherwise, the same texel as
the spot's inner cone, in the place the cookie/IES reservation left spare: y and z stay reserved) and the cluster loop skips them on a
lightmapped fragment (`fa_lm.z > 0.5`) before any shadow lookup, so their shadow costs nothing there; `fa_light_shadowed`, which the
custom-light API (`fa_light()`) goes through, answers "no light" for them too. `mixed` and `realtime` lights are drawn as always, and an entity with no lightmap entry is lit by every light, baked ones
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
