Part of [rendering, the lighting of M73](ARCHITECTURE_RENDERING_LIGHTING.md): the shadow atlas, decals and the shadows of point and spot lights. The shader files, the texture slots, the clustered lights and the rest of the M73 lighting are on that page.

# Rendering: the shadow atlas, point and spot shadows and decals (M73)

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

