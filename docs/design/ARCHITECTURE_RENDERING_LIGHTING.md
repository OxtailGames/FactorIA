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
| 24 `fa_light_data` (sampler 1, nearest, `texelFetch`) | M73.1a, RGBA32F: the lights and the clusters' light lists, M73.5b the decal records and their cluster lists (landed); later the sky's spherical harmonics | 1, 2 |
| 25 `fa_light_atlas` (sampler 10) | M73.1b (landed): ONE RGBA16F atlas with the LTC tables of the area lights (a reserved block at (0, 0), packed first), the cookies and the IES profiles ("The light atlas") | 1, 2 |
| 26 `fa_lightmap` (sampler 10) | M73.4a: the lightmap page of the entity drawn (RGBA16F, one page per draw; a white texel when it has none), read at its lightmap UV | 1, 2 |
| 27 `fa_decal_atlas` (sampler 10) | M73.5b (landed): decal textures, RGBA8 with mips (their transforms are in `fa_light_data`); the white image while a view has no decals | 1, 2 |
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
  default fade" and three reserved components); in a view where any light is an area light or has a cookie or an IES profile every light has **eight** texels (`kLightTexelsExt`; the stride is in `fa_ambient.w`, 0 or 4 meaning four: `fa_counts.y` is the decal region's base since M73.5b), the extension at `+4 .. +7` ("The light atlas"); then one texel per cluster (slot of its first light
  index, how many lights, and since M73.5b the slot of its first decal index and how many decals: 0, 0 without decals), slice-major, then
  row, then column; then the light indices, four to a texel; then the shadow region of the local lights (M73.2b, only with local shadows), then the decal
  region (only when the view has decals, see "Decals"). Light n is at texel `n * stride` (`fa_light_base`): every reader of a light's texels (`fa_light_sample`, `fa_shadow_local`, the standard loop) goes through it.
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
  important of equal ones; each request has `minSize`, `priority` and `tier`), then the least important map is dropped. The budget works on
  the highest tier that still has a map: the sun is tier 0 and every local tile tier 1, so the cascades keep their asked size until every
  local tile is at its minimum, and lose a map only once no local tile is left (a request with the default tier is laid out as before). Nothing depends on
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

## Decals (M73.5b)

The user page is docs/rendering/RENDERING_LIGHTING.md, "Decals". A projected decal is **forward**, not deferred: the opaque and the
blended meshes are drawn as before, and the mesh fragment shader paints the decals of its cluster over the surface (albedo and shading
normal) before the lights read them. There is no G-buffer and no extra pass; a view without decals binds the white image at view 27 and a
`fa_counts.y` of 0, and its pixels and its light data texture are the same as before (a test compares a scene with the decal code on and
off).

- **Which decals.** `collect_decals` (`renderer_draw.cpp`) walks the world's `Decal` components of the active entities in the order of the
  world, keeps the first `kMaxDecals` (256; the rest count in `stats.decalsDropped`, warned once), then sorts them **stably** by
  `sortOrder` (ties keep the order the world visited them): the order in the shader is the order of painting, so a later decal covers an
  earlier one, and it is also the order the cluster lists are filled in. It also gathers every texture path
  the decals name (sorted, normalised) so the atlas is built for all of them, not only for the ones in view.
- **Boxes in the cluster grid.** `make_decal_records` turns each decal into a `DecalRecord` (the inverse of its world matrix, so
  `world -> box` is three rows; the box is the cube -0.5..0.5 of the entity's local space, the projector looks along local -Z) and a
  `DecalBox` of eight world corners. `build_decal_clusters` (`light_clusters.cpp`) gives each box the range of clusters its corners
  reach, with the same margins as a light sphere (`decal_cluster_range`), and fills lists with the same deterministic job as the lights
  (chunks, per-slice fill, serial prefix): the lists are the same bytes for any number of workers. Limits are counts: 32 decals per cluster
  (the first 32 in drawing order stay, that is the lowest `sortOrder`), 131072 list entries per view; what is lost is in `stats.decalClusterClipped`. A view with decals
  and no lights builds the clusters with no light spheres.
- **The decal region of `fa_light_data`**: view 24 has one texel cursor in a fixed order, `lights | clusters | light indices | shadow
  region (M73.2b, only with local shadows) | decal region`, and every base is passed by uniform, never assumed (`shadowBase` as
  `fa_shadow_lcfg.x - 1`, the decals' at `fa_counts.y`; `usedTexels` is the end of the last region). The decal region starts at texel `fa_counts.y`: header texel (count, atlas width, atlas
  height, first texel of the decal indices); texel 1 `.x` the colour mode (below); then 7 texels per decal (`kDecalTexels`): the three rows of
  `world -> box`, the albedo rectangle in atlas uv (`x0, y0, x1, y1`; empty when there is no albedo), the normal rectangle, the tint
  (linear in a linear scene) with the colour's alpha, and `(opacity, normalStrength, angleScale, layers)`; then the decal indices, four to a texel.
  `angleScale = 1 / max(cos(angleFade), 1e-3)`, `layers` is the mask (0 is stored as 65535). Texel 0 of every cluster has, in z and w, the
  slot of the cluster's first decal index and the count.
- **The receiver.** `fa_counts.w` (set per draw in `fill_fs`) is 0 for a mesh with `receiveDecals` false, else `1 + decalLayer`
  (clamped to 0..15). `decal_recv(mr)` (`mesh_batch.cpp`) is the same number and is part of the batch and the sort key, so two meshes with
  different values never share a draw (the uniform is per draw, not per instance).
- **`fa_apply_decals(world_pos, geo_normal, inout albedo, inout normal)`** (block `fa_decals` of `light_data.glsl`) is called once in `main()`
  of the mesh template, after `surface(i, s)` and **before** the alpha-clip `discard`: it takes `dFdx`/`dFdy` of the position (the
  mip level of the atlas lookup), which must happen in uniform control flow, and the early outs that follow it do not (the two tests that return first are on uniforms, `fa_counts.y` and `.w`, so every fragment of a quad takes them together). In each decal of
  the fragment's cluster: the box test (`|b| <= 0.5`), the angle fade `clamp(dot(geoNormal, axis) * angleScale, 0, 1)`, an edge fade over
  the last 10 % of the box in z (the sides cut sharply), then `albedo = mix(albedo, tint * texel, cover * texel.a * tint.a)` and a
  perturbation of the normal in box space weighted by the same cover. `metallic`, `roughness` and the rest of the surface stay the mesh's. The
  full template (`mesh_full_common.glsl`) declares the atlas as `fa_full_decal_tex` and includes the same block; it does **not** call the
  function (a full shader has no surface hook): the author calls it (docs/shaders/SHADERS_LIGHTING.md, "Decals"). The depth prepass and
  the shadow programs do not include the block, so a decal casts no shadow and never changes the depth.
- **The atlas** (`decal_atlas.h/.cpp`, CPU, pure and tested without a GPU): every texture the decals name is read (the order of
  `Assets::load_texture`: the export-packed atlas, then a `.ktx2` twin, then the file), scaled so its longer side is at most 1024, put in a
  cell with a 16 px edge-replicated gutter (the cell is a multiple of 16, so mips down to 16 px never blend neighbours), and packed in
  shelves sorted by height, width and path (so the layout does not depend on the order the decals are in) into the smallest square power
  of two from 64 up to `min(4096, max_image_size_2d)`, its height then trimmed to a power of two. When they do not fit, the biggest tile is
  halved (down to 16 px), then the last is dropped (warned once, `stats.decalsDropped`); the budget is 96 MB, checked in 64-bit before the
  allocation. `Renderer::Impl::ensure_decal_atlas` (`renderer_decals.cpp`) rebuilds the image only when a requested path is not in the
  atlas, when `Assets::reload_generation()` changed (a reloaded file) or when the colour mode changed; the paths it holds are the union of
  the ones asked for before and the new ones while that is at most 512 (`kMaxDecalTextures`), so two views with different decals do not
  rebuild it by turns. The replaced image goes to `decalRetired` and is freed at the start of the next frame (an earlier job of this frame
  may still draw with it), like the shadow targets.
- **Colour.** Mode 0 (a gamma scene): the atlas is RGBA8 and the shader mixes raw bytes. Mode 1 (a linear scene without an sRGB format): RGBA8, and the shader
  decodes the albedo (`fa_dc_to_linear`). Mode 2 (a linear scene with `SRGB8A8`): the hardware decodes the albedo and the shader encodes
  the normal map's texels back (`fa_dc_to_srgb`), because a normal map holds data, not colour. The mips of mode 2 are built in linear space.
- **Backends.** Only `texelFetch` on the RGBA32F data (as the lights) and one filtered 2D lookup per tile (`textureLod`): nothing a
  GL, GLES3, WebGL2, D3D11 or Metal driver lacks, and no `float32` target is needed (`render.supports decals` is true wherever the renderer
  draws). The tile uv is clamped to 0..1 of the tile and the mip level to 0..4 (a 16 px gutter keeps four mips inside the cell), so the
  filter never reads a neighbour. The golden `3d_decals.png` was made on Metal; the other backends are compared with it by CI.
- **Stats** (`RenderStats`): `decals` (decals drawn, summed over the frame's views), `decalsDropped` (over 256, no albedo in the atlas, or no
  atlas), `decalClusterClipped` (list entries lost).
- **Not the same as the model `texturing` decals** (`model_texture.h`): those are baked by the CPU into a model's texture when it is made, one
  fixed picture, no component, no runtime cost; this section is the live component. The two do not share code.

## Shadows of point and spot lights (M73.2b)

CPU: `engine/render/src/local_shadows.{h,cpp}` (no GPU; `tests/local_shadows_tests.cpp`), wired in `shadow_bounds`, `cull_and_batch`,
`upload_lights` and `shadow_pass` of `renderer_draw.cpp`. GPU: `fa_shadow_local` in `shadow_common.glsl`, called from `fa_light_shadowed` and
`fa_light_shadow` (`light_loop.glsl`) and from the full template's `fa_light` (`mesh_full_common.glsl`). The renderer test is
`tests/local_shadow_render_tests.cpp` (goldens `3d_shadows_spot`, `3d_shadows_point`).

- **Tiles.** A spot light is one perspective tile of tangent `tan(spotAngle)`; a point light (and a spot over `kMaxSpotTileAngle` = 70
  degrees) is six face tiles with `cube_face_basis` (+X, -X, +Y, -Y, +Z, -Z, each a 90 degree view). The shader picks the face by the
  largest component of the direction from the light (`cube_face_of`, the same table). A tile is a few texels wider than the region it
  serves, a guard band of `kLocalShadowGuard` = 17 texels, the widest radius `fa_shadow_filter` reads (PCSS searches up to 12, blurs up to 16) plus the
  texel of the inset (`tan` is scaled by `half / (half - guard)`; a tile under 68 texels takes a quarter of its side, and there the edge row
  can be read clamped: the shader does not shorten its radius). The filter clamps to the
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
  `texelCoef * distance` metres wide (`texelCoef = 2 tan / tile`), so the automatic bias is 1.5 texels at the receiver's distance. The slope of the receiver is measured against the tile's axis, not
  against the ray to the light: `dw/dtexel = texel_m * sqrt(1 - (n.a)^2) / |n.r|` with `a` the axis (xyz of row 3 of `S`) and `r` the ray
  from the light divided by the distance along the axis; a surface that faces the light at the diagonal of a cube face has `sin(t) cos(t)` = 0.5 (t = the angle off the axis) where
  the angle between the normal and the light says 0, and one that is square to the axis (the floor under a lamp, seen by its -Y face) has
  exactly 0 where that angle would over-bias it. The normal offset still uses the angle to the light.
- **Baked lights.** `LightData::baked` lights stay in the table for the moving objects; `shadow_bounds` gives one a map only when a mesh that
  is not lightmapped and receives shadows is within its range (a second box of `shadow_bounds`), because a lightmapped fragment skips the light
  before any shadow lookup (`fa_light_shadowed`) and its direct shadows are in the lightmap.
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

## The light atlas

M73.1b (area lights, cookies, IES profiles; the user page is [RENDERING_LIGHTING.md](../rendering/RENDERING_LIGHTING.md); the LTC tables and
the fit are in [ARCHITECTURE_AREA_LIGHTS.md](ARCHITECTURE_AREA_LIGHTS.md)). The CPU half is `engine/render/src/light_atlas.h` (`.cpp`) and
`engine/render/include/fa/render/ies.h` (`src/ies.cpp`), the wiring `collect_lights` and `upload_lights` in `renderer_draw.cpp`, the GPU side
`light_data.glsl` (`fa_atlas_fetch`, `fa_cookie_sample`, `fa_ies_sample`, the extension texels in `fa_light_sample`) and `light_loop.glsl`
(`fa_area_light`: `fa_area_form`, `fa_area_shade`, and a branch of the standard loop).

- **One image, no new unit.** The slots of the mesh fragment stage are all spoken for (16 units in the final phase), so the LTC tables
  share the image with the cookies and the profiles. The image is RGBA16F, 1024 texels wide, a power-of-two rows tall (up to 4096: 32 MB),
  slot `fa_light_atlas` (view 25, the sky's linear clamp sampler 10), read bilinearly with `textureLod(.., 0)`. Its layout is
  deterministic (`layout_light_atlas`: the LTC block first, then shelves of tiles, tallest first, ties by kind and path; the same SET of
  tiles is the same layout in any order; tiles over the 4096 rows are dropped and counted):
  the LTC matrix (`a, b, c, d` of M^-1) at (0, 0) and the BRDF integrals (magnitude, Fresnel) at (64, 0), each 64 x 64 texels, half floats
  with signs (the matrix has negative entries); a cookie is a 256 x 256 tile (a point light's: a 768 x 512 cube of six; 254 x 254 of picture, a border that wraps so a tiled
  directional cookie has no seam, rgb premultiplied by alpha); an IES profile is a 66 x 34 tile (64 x 32 values, a border that wraps across
  and clamps down). The image is made by `LightAtlas::sync` when a light asks for it (`request_ltc`, `request`), made again when the set of
  keys changes or `invalidate(path)` says a file changed (the hot reload; the old image is retired and freed a frame later like the
  shadow atlas', so the frame in flight keeps the one it captured). A view without such a light makes none and binds a dummy.
- **Texels of a light** (`light_data.glsl`, header). Texels 0..3 are unchanged. `+4`: xyz the light's right axis, w the half width of a
  rectangle or tube or the radius of a disc (for a directional cookie, `1 / size.x`); `+5`: xyz the up axis, w the half height of a
  rectangle, the radius of a disc, the half thickness of a tube (for a directional cookie, `1 / size.y`); `+6`: xy the origin of the cookie
  tile (a point light's: of its 3 x 2 cube), z 1 when there is one, w the shape (0 rectangle, 1 disc, 2 tube); `+7`: xy the origin of the IES tile, z 1 when there is one, w the
  extent, the radius of the sphere around the emitter. The light type is 3 for an area light. Other packages that add per-light data in this
  texture (local shadows, decals, the lightmap) take more texels after `+7` or their own regions, never these.
- **Shading.** `fa_light_sample_n(li, pos, n)` (`fa_light_sample` is it with `n = 0`) gives an area light to every path as a point light at
  the REPRESENTATIVE POINT of its emitter, with the window attenuation measured from the emitter's surface (`reach = dist - extent`); a
  spot's cookie is a perspective lookup, a directional one an orthographic one tiled with `fract`, a point light's a cube (below), the
  colour is multiplied by `fa_light_tint`, and an IES profile multiplies the attenuation by the table at the angle from the light's forward
  axis (vertical) and around it (horizontal). The standard loop (`fa_area_light`) replaces the point-light terms with the LTC polygon
  integrals, for a material with layers too (`fa_area_layers`): the details, the approximations and the shadows are in
  ARCHITECTURE_AREA_LIGHTS.md, "Representative point, layers, shadows and point cookies".
- **Energy.** The area colour is scaled by `(pi d^2 + A) / A` (d the distance to the centre, A the area) before the form factor, so far away the
  light is a point light of the same intensity (a render test compares them), and near the emitter, where the form factor tends to 1, the
  result is bounded by the term `pi d^2 / A + 1` instead of growing without a limit. A rectangle and a disc emit from the front only (the polygon
  is clipped by the light's plane), a tube from all around.
- **Precision (GLES3, WebGL2).** The generated GLSL ES 3.00 fragment shader begins `precision mediump float;` and sokol-shdc qualifies
  every declaration `highp`, so the area path runs in full float; it must, because `ltc.glsl` guards its divisions with `1e-24` and `1e-10` and
  adds vectors a few hundred metres long, which fp16 flushes. `light_atlas_tests.cpp` reads the generated `mesh_fs_source_glsl300es` in
  `mesh.glsl.h` and fails when a float, vector or matrix declaration of it has no `highp` (the literal tables of the material layers are
  the one exception). The header of `ltc.glsl` says so; do not write `mediump` or `lowp` in it. (An earlier version of this page said the file was
  "validated with sokol-shdc": the compile only proves it is legal GLSL, not that its numbers are right; the test and the render goldens are the checks.)
- **IES** (`ies.h`): our own LM-63 reader (no code from another engine). It reads `IESNA` header lines and keywords, `TILT=NONE` and
  `TILT=INCLUDE` (the tilt table is read and dropped), the 10 numbers of the lamp line, the angles and the candela table. Photometric type
  C only (A and B are refused with the type found); the vertical angles must ascend within 0..180, the horizontal ones within
  0..360 and be one plane or span 0..90, 0..180 or 0..360 (the others are refused naming the range); a candela value is a finite number
  of at least 0 and the table has some light in it. Every count is checked against the caps (1024 angles per axis, 2^20 values, 4 MB
  of text) before anything is allocated. `candela_at(h, v)` interpolates bilinearly and folds the symmetry; `ies_bake` samples it on a
  64 x 32 grid (columns the horizontal angle over the circle, rows the vertical angle over 0..180 at the texel centres) and divides by
  the table's peak: **the baked value is candela / peak**, so the file only shapes the light. Errors are `name:line: what` with a hint,
  like the `.cube` reader's. `assets.import` has a `.ies` route (`assets/lights/`, `import_ies` in `tools/common/src/assets_import.cpp`:
  the same parser, the file copied as it is) and the hot reload lists `.ies`.
- **Not done, and why.** A cookie or an IES profile on an area light (the renderer warns once), an IES profile on a directional one, and
  the 2D light, which stays a point.
- **Tests.** `ies_tests.cpp` (parser, bake, errors; fixtures written for the tests), `light_atlas_tests.cpp` (layout determinism and
  overlap, half floats, the LTC block texel by texel, the tiles' borders, the 4 and 8 texel light table, the highp scan),
  `area_light_render_tests.cpp` (goldens `3d_area_light_rect`, `3d_area_light_shadow`, `3d_light_cookie_spot`, `3d_light_cookie_point`, `3d_light_ies`; area against point energy; no change
  for a scene without the features; the hot reload).

## The feature rows

`render_features.cpp` has one row per feature (docs/design/ARCHITECTURE_RENDERING.md, "What the GPU can do"). M73-P0 added `float32Targets`
(the `needs` word `float32`: `R32F` and `RGBA32F` render and sample, read with `sg_query_pixelformat`) and 21 engine rows planned
`"M73"`: `clusteredLights`, `areaLights`, `lightCookies`, `iesProfiles`, `cascadedShadows`, `pointShadows`, `spotShadows`,
`contactShadows`, `environmentMap`, `reflectionProbes`, `physicalSky`, `lightmaps`, `lightProbes`, `volumetricFog`, `decals`,
`subsurface`, `realtimeGI`, `clearCoat`, `sheen`, `anisotropy`, `transmission`. Each carries the `needs` its pass will ask of the GPU.
`needs_met` runs before the planned check, so on a GPU that lacks the capability the answer names the capability, not the plan. The
package that draws a feature drops its `"M73"` text from the table (`clusteredLights` did in M73.1a, `cascadedShadows` in M73.2a: it needs only `float32`, `decals` in M73.5b: it needs nothing, and `areaLights`, `lightCookies` and `iesProfiles` in M73.1b: they need `half`, RGBA16F images that filter, the atlas format).

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

