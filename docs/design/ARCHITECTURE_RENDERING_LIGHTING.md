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
power of two rows, texel `t` at `(t & 1023, t >> 10)`), written once per view (`Gpu::write_light_image`, a sokol transient image: 16 per frame, and when the 16 are used the next
`Gpu::begin_frame` forces a commit, like the transient buffers) and read by the fragment shader with `texelFetch`, the same on GL,
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
- **Not here yet.** Area lights, cookies and IES profiles (M73.1b) use the reserved texel components; a spot's cone is bounded by its
  full sphere (a tighter cone bound would only shorten the lists); shadows of local lights are M73.2b.

## The shadow atlas

M73.2a (cascades of the sun); M73.2b (point and spot) adds tiles to the same atlas, see "Shadows of point and spot lights" below. The CPU side is `engine/render/src/shadow_cascades.h`
(pure functions, `tests/shadow_cascades_tests.cpp`) and `local_shadows.h` (`tests/local_shadows_tests.cpp`), the wiring is `Renderer::Impl::shadow_bounds` / `scene_uniforms` / `shadow_pass` in
`renderer_draw.cpp`, the targets `create_shadow_targets` in `renderer_targets.cpp`, the GPU side `shadow_common.glsl`.

- **One 2D atlas, not cube arrays.** The image in slot 1 (`fa_shadow_tex`, view 1, sampler 1, nearest: the 32-bit float image cannot be
  filtered on GLES3 and WebGL2) is `R32F` colour plus a depth buffer. The shadow pass writes `gl_FragCoord.z` as colour, so every
  backend stores the same 0..1 number; the lookup compares by hand (no hardware comparison sampler). The format follows the
  `float32Targets` row: a GPU without it draws no shadow, warns once with the hint to ask `render.supports cascadedShadows`, and the
  feature row says so. It never falls back to another format silently (that would be a different look on a different GPU).
- **Layout.** `layout_shadow_atlas(maxSize, requests)` places square power-of-two tiles with a buddy allocator, biggest first, each in the
  smallest free square that fits, topmost and leftmost first, so equal requests give equal tiles and the used part is a compact block
  at the top left. The budget is deterministic: when the requests do not fit, the largest map that can still shrink is halved (the least
  important of equal ones; each request has `minSize` and `priority`), then the least important map is dropped. Nothing depends on
  timing. `plan_local_shadows` adds the requests of M73.2b (six tiles per point light, one per spot) to the same call, with priorities after
  the sun's cascades; the sun asks for `shadowCascades` tiles of `shadowResolution` (0 = 2048 for one, 1024 for several), minimum 128, priority = cascade
  index (the farthest shrinks first).
- **Size.** The image is the used part of the layout (power-of-two sides, at most `SceneSettings.shadowAtlasSize` and the GPU's
  `max_image_size_2d`), grown when a frame needs more and never shrunk. A frame plans every job before the frame graph runs, so a
  grown image retires the old one (`shadowRetired`, freed at the next frame's start) and each job keeps its own copy of the target.
  Allocation is checked against `kShadowAtlasMaxBytes` (512 MB) in 64 bits before it is made. `FA_SHADOW_MAP=invalid` is a test hook that makes the creation fail on a GPU that never would.
- **Cascades.** `plan_cascades` cuts the range from the camera's near plane to the shadow distance; with none set the range is `auto_shadow_far` (the Euclidean distance to the farthest caster corner plus the casters' diagonal, rounded up to 3 bits of mantissa), never a distance along the view axis, so turning the camera changes no split and no cascade size. `cascade_splits` is the practical scheme (`shadowCascadeSplit` blends even and logarithmic steps; without a positive near
  distance, an orthographic camera, even steps). Each cascade is the sphere that holds its slice of the camera's frustum
  (`slice_sphere`: independent of the camera's orientation, its radius rounded up by `quantize_up` so float noise does not change the
  size), widened by the blend band of the cascade before it and by two texels of margin on each side. `fit_cascade` snaps the sphere's centre to whole
  texels along the light's x and y, so the shadow of a still object lands on the same texels whatever the camera does between those
  steps, and pulls the near plane back to the nearest caster of the scene so that a caster outside the sphere still shades it.
  `shadow_sample_matrix` takes a world position to the atlas's (u, v) and the 0..1 depth over the cascade's own range, with the
  render-target v flip of OpenGL; `shadow_tile_rect` gives the tile's rectangle, which the filter clamps to so it never reads a
  neighbour.
- **Culling.** A shadow view is one tile of the layout: the sun's cascades are views `0..want-1`, the tiles of the local lights follow.
  `MeshItem::castMask` is 64 bits, one per view (`kMaxShadowViews` = 64); a caster is drawn in every view whose volume holds its box
  (for a local tile first the sphere of the light's range, then the frustum of the tile). A batch keeps its instances as sparse
  `ShadowRun {view, first, count, extra}` entries, in ascending view order, in one shared vector (`MeshBatch::runFirst/runCount`,
  filled by `build_batches`), and the shadow pass loops over the views with a viewport and scissor of the tile and a cursor per batch.
- **The uniform block.** `fa_shadows` is binding 7, the last of the 8 uniform-block slots of a mesh program (`UB_mesh_fa_shadows`): per
  cascade a matrix, a rectangle, and the metres per texel and depth range; the split distances; the filter, blend and bias settings; the
  eye and forward axis (the cascade is chosen by the distance along the camera's forward axis, as the splits were made). It is
  applied in the main pass, the prepass and the shadow-pass programs. There is no free slot: the shadows of local lights are in the light
  data texture (view 24), and this block only gained `fa_shadow_lcfg` (below), never a ninth block.
  Dynamic indexing of a `vec4` by a variable does not cross SPIRV-Cross to every target, so the split lookup is a ternary helper.
- **The filters.** `pcf` takes 16 taps of the Vogel disk (radius 1.5 texels), `pcss` a 16-tap blocker search (radius from the light's
  angular size, `tan(0.05 * shadowSoftness)`), then 24 taps sized by the penumbra (1.5..16 texels), `hard` one tap. The disk is turned by
  interleaved gradient noise of the pixel (fixed, no time input). A slope-scaled plane term keeps a tilted receiver from shadowing
  itself across the kernel. The bias is in metres (`shadowBias`; 0 = 1.5 texels of the cascade), and the normal offset likewise.
- **The two templates.** The mesh template and the full-shader template include the same block and name the image through the
  macros `FA_SHADOW_TEX` / `FA_SHADOW_SMP`. `fa_shadow_coord` of the full template is now the world position (`vec4(world, 1)`);
  `fa_shadow(...)` finishes the lookup, so a full shader that calls it needs no change. The twin fixtures were regenerated.
- **Debug view.** `render.debug_view cascades` (`DebugView::Cascades`; also `FA_RENDER_DEBUG_VIEW=cascades`) sets `fa_shadow_eye.w` and
  the mesh fragment tints its colour by cascade (`fa_shadow_debug`); the prepass is not planned for that view.

## Shadows of point and spot lights (M73.2b)

CPU: `engine/render/src/local_shadows.{h,cpp}` (no GPU; `tests/local_shadows_tests.cpp`), wired in `shadow_bounds`, `cull_and_batch`,
`upload_lights` and `shadow_pass` of `renderer_draw.cpp`. GPU: `fa_shadow_local` in `shadow_common.glsl`, called from `fa_light_shadowed` and
`fa_light_shadow` (`light_loop.glsl`) and from the full template's `fa_light` (`mesh_full_common.glsl`). The renderer test is
`tests/local_shadow_render_tests.cpp` (goldens `3d_shadows_spot`, `3d_shadows_point`).

- **Tiles.** A spot light is one perspective tile of tangent `tan(spotAngle)`; a point light (and a spot over `kMaxSpotTileAngle` = 70
  degrees) is six face tiles with `cube_face_basis` (+X, -X, +Y, -Y, +Z, -Z, each a 90 degree view). The shader picks the face by the
  largest component of the direction from the light (`cube_face_of`, the same table). A tile is a few texels wider than the region it
  serves, a guard band of `kLocalShadowGuard` = 8 texels (`tan` is scaled by `half / (half - guard)`), and the filter clamps to the
  tile's rectangle inset by a texel, so a fragment at the edge of a face reads its own face's texels and never the neighbour's.
- **Views.** View v = tile v of the layout: the sun's cascades take `0..want-1` (`want` requested, `cascades` placed; a cascade that did
  not fit leaves its view unused), then the local lights in importance order. At most `kMaxShadowViews` = 64 views per frame (the
  `castMask` width); a light that would pass it is lost (`plan.lost`).
- **The budget** (`plan_local_shadows`). Importance = `brightness * r^2 / (r^2 + d^2)` (r = range, d = distance to the camera); the order is
  by importance, equal scores by table index (`std::stable_sort`, so inputs in any order give the same plan). Wanted tile: `shadowResolution`
  rounded down to a power of two in 64..2048, else 1024 (512 for a cube) times `min(1, range / d)`, a power of two, at least 64. The
  requests (sun, then each light's tiles with priority `kLocalShadowPriority` + rank, minimum 64) go to `layout_shadow_atlas`, which halves
  the largest then drops the least important tile; any light left with an unplaced tile is removed whole and the layout is made again
  (all or nothing), until every kept light is complete. Which lights ask is decided before: `Light.castShadows`, the casters' box meets the light's sphere, and the
  light is within `shadowDistance + range` of the camera. The result is counts only: no time, no thread, no float noise that is branched
  on beyond the importance (computed with the same operations each frame). A one-time warning (`warnedShadowBudget`) names the fixes.
- **Depth convention of a local tile.** The shadow pass stores the window depth z (0..1 on every backend: `gl_FragCoord.z`) of a
  perspective projection with near `n = max(0.05, range / 200)` and far `f = range`. The shader turns it into metres along the tile's
  axis, `c = n f / (f - z (f - n))`: the clip w of the projection is that distance, which is also what `dot(row3, world)` of the sample
  matrix gives for the receiver. Bias, the PCF slope and the PCSS search compare in metres. The cleared value 1.0 is `far`. A texel is
  `texelCoef * distance` metres wide (`texelCoef = 2 tan / tile`), so the automatic bias is 1.5 texels at the receiver's distance.
- **The sample matrix** `S = T' * viewProj` (`local_sample_matrix`): `T'` takes clip x, y, w to `(u w, v w, -, w)` of the tile, with the
  v convention of `shadow_sample_matrix` (`isGl`: the render target's v runs bottom up in OpenGL, top down in D3D11 and Metal). The shader
  computes `uv = (S.row0 . p, S.row1 . p) / (S.row3 . p)` and the depth is `S.row3 . p`. The sun's filter code is reused:
  `fa_shadow_filter(uv, rect, z, texel_m, unit, reach, plane, conv, mode, k)` and `fa_shadow_fetch(uv, rect, conv)` take the receiver depth
  in the map's own unit (the sun: 0..1 of the cascade, `conv = vec3(0)`; a local tile: metres, `conv = (1, n, f)` decodes the stored z),
  so there is one PCF, one PCSS and one hard filter.
- **View 24, the shadow region.** After the cluster index lists (`LightTexture::shadowBase`), one texel per table light then the records:
  `[base, base + L)`: `x` = the texel of the record, or -1 (no shadow). A record is 2 header texels and 6 per tile. Header 0: `x` kind
  (1 spot, 2 six faces), `y` fade distance (0 = never), `z` filter (0 pcf, 1 hard, 2 pcss), `w` softness `tan(0.05 k)`. Header 1: `x` bias,
  `y` normal bias (metres, 0 = automatic). Tile texels 0..3: the four rows of `S`; texel 4: the rectangle in the atlas (u0, v0, u1, v1)
  inset by a texel; texel 5: `(texelCoef, near, far)`. `layout` and constants: `shaders/light_data.glsl`, `local_shadows.h`. With
  no record the texture is bit-identical to before (`pack_light_texture` without records). `fa_shadows` gained `vec4 fa_shadow_lcfg` at
  its end: `x` = 1 + `shadowBase` (0 = no local shadows, so a zeroed block means none). The base is known after `upload_lights`, which
  runs after `fill_shadow_block`, so `scene_uniforms` sets it afterwards. The branches that merge with this (decals, physical sky,
  lightmaps) add their own texels after the shadow region: read `shadowBase`, never a fixed offset.
- **Fade.** The shadow of a local light is multiplied toward 1 by `1 - smoothstep(0.75 D, D, |p - camera|)`, D = the light's
  `shadowDistance` (else the scene's; 0 = none, the light's range limits it).
- **Culling and cost.** `cull_and_batch` tests an item against each local tile first with the sphere of the light (a conservative world
  sphere of the item), then `box_in_frustum` of the tile; `noCull` items go in every active view. Each draw of a tile counts in
  `stats.drawCalls`, and `shadowCasters` counts items drawn into any view. No new stat.
- **Backends.** The same `float32Targets` atlas as the sun; GLES3 and WebGL2 use `highp` (the generated header is made with the
  same template); the v flip is the `isGl` branch of `local_sample_matrix` (the matrix of both conventions is checked on the CPU in
  `local_shadows_tests.cpp`; the renderer goldens run the backend of the host: Metal on a Mac, D3D11 or llvmpipe on CI).

## The feature rows

`render_features.cpp` has one row per feature (docs/design/ARCHITECTURE_RENDERING.md, "What the GPU can do"). M73-P0 added `float32Targets`
(the `needs` word `float32`: `R32F` and `RGBA32F` render and sample, read with `sg_query_pixelformat`) and 21 engine rows planned
`"M73"`: `clusteredLights`, `areaLights`, `lightCookies`, `iesProfiles`, `cascadedShadows`, `pointShadows`, `spotShadows`,
`contactShadows`, `environmentMap`, `reflectionProbes`, `physicalSky`, `lightmaps`, `lightProbes`, `volumetricFog`, `decals`,
`subsurface`, `realtimeGI`, `clearCoat`, `sheen`, `anisotropy`, `transmission`. Each carries the `needs` its pass will ask of the GPU.
`needs_met` runs before the planned check, so on a GPU that lacks the capability the answer names the capability, not the plan. The
package that draws a feature drops its `"M73"` text from the table (`clusteredLights` did in M73.1a and `cascadedShadows` in M73.2a: it needs only `float32`).

## The new fields

`Light`, `SceneSettings` and `MeshRenderer` (`engine/scene/include/fa/scene/components.h`, registered in `components.cpp`) got the fields
listed in the user page, each with a doc string that says "No effect yet: M73.x brings it" (the layers of M73.6a are drawn: see "The material layers"). They are plain reflected fields: range and
enum checks come from the reflection (`field_from_json`), and a default is not written to a scene file, so old scenes and the saved
form of an unchanged scene are the same. `LightType` gained `Area` (last, so the numbers of the others do not move); until M73.1 the
renderer treats it as a point light (`renderer_draw.cpp`, `scene2d.cpp`). The M73.x package that makes a field work removes "No effect
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
