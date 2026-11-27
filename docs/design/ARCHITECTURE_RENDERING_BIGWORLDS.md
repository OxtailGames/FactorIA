# FactorIA architecture: rendering, big worlds

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page; the rendering page is
[ARCHITECTURE_RENDERING.md](ARCHITECTURE_RENDERING.md)). The renderer's side of M75: the occlusion culling on the CPU and on the GPU, the floating origin, terrain and levels of detail. The user-facing description is docs/BIG_WORLDS.md.

## Occlusion culling on the CPU (M75.2)
`render/src/occlusion.h` is the GPU-free half (`OcclusionBuffer`: a 256-cell-wide depth buffer, the rasterizer, the conservative test of a
box) and `renderer_occlusion.cpp` the renderer's half (`Renderer::Impl::occlude_meshes`, called by `gather_meshes` once per main-view camera,
after the frustum test and only when `world.any<Occluder>()`). It sets `MeshItem::visible = false` on the meshes it proves hidden, which the
main pass skips and `stats.meshesCulled` counts; the shadow passes read the same items and are not culled by it (`meshesOccluded` is the
subset). Probe and GI captures (`fr.noProbes`, `fr.giCapture`) skip it. Conservative by construction: centre-sample coverage with integer edge
functions, the farthest depth a triangle can have inside a cell, the touched cells dilated by a ring, a near-plane crossing or a camera inside
the occluder means visible. Every result is independent of the thread count: the triangles are set up per occluder (one slot each) and
rasterised per band of rows, the cell being the maximum over the triangles. Caps count triangles (4096 per Occluder, 65536 per camera).

Areas and portals are the same pattern: `render/src/portal_graph.h` is the pure half (the start areas of the camera, the test of a mesh against the areas, the walk with
the NDC rectangle narrowed at each portal, the depth and step guards) and `renderer_portals.cpp` gathers the OcclusionArea and
OcclusionPortal entities with their drawn matrices, warns once per entity about unknown or equal area ids, and clears `MeshItem::visible`
of the meshes whose areas the walk did not reach (`stats.meshesCulledByArea`, `stats.portalsVisited`). It runs before `occlude_meshes`,
under one `world.any<OcclusionArea>()` check, and skips probe and GI captures too. A walk that hit a guard (`capped`) culls nothing.
`Renderer::occlusion_report` backs `render.occlusion` and `DebugView::Occlusion` draws the boxes with `DebugDraw`. Tests:
`engine/render/tests/occlusion_tests.cpp` (CPU, in `render_postprocess_core`) and `occlusion_render_tests.cpp` (a GPU scene).

## Occlusion culling on the GPU, the depth pyramid (M75.2b)
`SceneSettings.occlusionMode` (`cpu` default, `gpu`, `auto`) picks, per camera and exclusively, the Occluders above or this path;
`renderer_hiz.cpp` drives it, `hiz.h/.cpp` is the pure half (`HizPyramid`, `hiz_hidden`; `hiz_tests.cpp` proves its maths without a GPU) and
`shaders/hiz.glsl` the reduce. `gather_meshes` calls `hiz_cull` for a perspective camera that draws the world (not a probe or GI capture,
not a camera view), which sets `MeshItem::visible = false` like `occlude_meshes` (shadows are not culled) and returns the camera's `HizCamera`
in `ctx.hiz`; `plan_prepass` then forces the camera's depth and normal prepass (exact current geometry, sampleable, unlike the MSAA main
depth; it costs a second draw of the opaque meshes) and `build_graph` declares a side-effect pass `hiz-reduce` right after it: a compute
pass of one thread per cell turns the prepass image into 256 x (256 / aspect) cells of (nearest, farthest) view depth in a storage buffer
(a pixel with no mesh counts as no depth, so only a fully covered cell occludes).
The read-back never waits (`gpu::AsyncBufferRead` behind `Device::request_buffer_read`, gpu/sokol_native.h: a ring of 4 staging slots per camera; Metal a blit into a shared
buffer, OpenGL 4.3 `glCopyBufferSubData` + fence, D3D11 a STAGING copy + event query; GLES3 and WebGL2 have none and never get here). It is
asked for in `Renderer::begin_frame` BEFORE sokol's frame begins (on Metal the blit must follow the committed command buffer that holds the
reduce); a headless renderer waits for it right there, so its latency is always exactly one frame and a test counts frames, not time. The
CPU builds the mip chain (min of nearest, max of farthest) and `hiz_hidden` tests each box in the pose of the frame the picture was made in
(`HizPose`; the shift of a floating-origin rebase is applied to it, `hiz_shift`): corners projected with the old matrix, the mip whose
footprint is at most 2 cells, the footprint dilated by the parallax the camera's move can cause, and "hidden" only when the box's nearest
corner is behind the farthest depth of every cell it reads. Not culled: a corner at or behind the old near plane, a footprint crossing the
picture's border, a changed field of view or aspect (a cut), a cell with no mesh, a move needing more than `kHizMaxDilate` cells, a pyramid
older than `kHizMaxAgeFrames` frames or from before a jump of the world's frame. At most `kHizMaxCameras` cameras keep a pyramid; the world
or scene path changing drops them all. Support is `render.supports occlusionGpu` (`computeShaders`) plus `AsyncBufferRead::supported()`.
`hiz.glsl` starts with `// shdc-slang: glsl430:metal_macos:metal_ios:metal_sim:hlsl5:spirv_vk` (tools/shaders/compile_shaders.sh), so its generated
header carries no GLES3, WGSL or WebGL2 code and the web player does not grow. Tests: `hiz_tests.cpp` (CPU), `hiz_render_tests.cpp` (a GPU
scene; they return where there is no compute). Bench: `render.hiz3d`.



## The floating origin (M75.4b)
`render/src/renderer_origin.cpp`: `Renderer::Impl::watch_world` (called by `update()` and `render_world()`: one pointer compare when
nothing changed) registers `origin_shifted` with `World::on_origin_shifted` for the world it is given, and removes it from the world it
leaves (`World::lifetime()` expires with the world, so a renderer never touches a dead one, in either order of destruction).
`origin_shifted` runs on the main thread between frames and moves the state that holds world positions across frames: `prevViewProj`
(times a translation by the offset), `Gi2dSystem::shift` (field geometry and history origin), the realtime GI `anchor` and layout
origin, the occlusion debug boxes, the ray tracing scene's cache of the last frame's instance records (`RtScene::shift`; the TLAS itself is rebuilt each frame in rebased space, ARCHITECTURE_RT_SCENE.md), and re-collects `lastCams`. Where a position is snapped, the snap is in ABSOLUTE space with the
origin added in double (`fit_cascade(.., origin)`, `gi2d_geometry(.., originX, originY)`), so a shift lands on whole texels whatever
the texel size; height-fog bases (`fogHeightBase`, `volumetricHeightBase`) are absolute heights: their caps (1e6 and 10 000 m) apply to the authored value and the base is used as `base - origin.y`, subtracted in double and rounded to a float once. A world-space cache the origin changes without a rebase (`World::clear()` puts it back to 0, a scene load sets the file's) is shifted too: `set_origin` and `clear` call the observers with the change. State rebuilt each frame needs nothing. A
new cache of a world position in the renderer must be shifted there. Tests: `origin_render_tests.cpp`.

## Terrain (M75-P5a, P5d)

`render/src/renderer_terrain.{h,cpp}` (`TerrainRenderer`, a member of `Renderer::Impl`) draws the `Terrain` component through the ordinary mesh
pipeline. `terrain_lod.{h,cpp}` is the CPU half and is free of any GPU call (so tests read it): the quadtree bounds (`TerrainTileBounds`,
min/max raw height per node, updated by rectangle), the LOD ranges (`TerrainLodRanges`), the selection (`select_terrain_nodes`) and the CPU
twin of the vertex shader's formula (`terrain_vertex_raw`), which the tests compare with the physics collider's triangles.
`shaders/terrain.glsl` is the mesh template with a `vertex()` and a `surface()` (it is compiled with `FA_HAS_VERTEX` and `FA_INST_2`, named
by its `// shdc-defines:` line, which `compile_shaders.sh` hands to sokol-shdc).

- *Material.* `TerrainRenderer::material()` builds an in-memory `MaterialAsset` (kind mesh, `instanceVec4` 2, textures `height` nearest,
  `albedo`, `normal`, `control`) with the three programs of the shader (main, shadow, prepass), so `mesh_pipeline`, `shadow_pipeline` and
  `prepass_pipeline` draw it unchanged. Its patch is one `MeshAsset` of a 33 x 33 vertex grid (`<terrain-patch>`); a terrain with a holes
  mask uses the split patch (`<terrain-patch-split>`: 4 vertices of its own per cell, 32 x 32 cells) instead.
- *Layers (P5d).* `albedo` and `normal` are `SG_IMAGETYPE_ARRAY` textures (`device.make_image` of a `gpu::ImageType::Array`, one slice per layer, a mip chain made on the
  CPU) built by `update_layers` from `load_terrain_layer_images` (fa_scene: the size checks and the teaching errors) and OWNED by the
  `Entry`, never cached `TextureAsset*` from `Assets` (a clear or reload would leave them dangling; the entry follows
  `Assets::reload_generation()` and each file's version through a key). The pictures are decoded and their mip chains packed by a job
  (`LayerJob`, `jobs::submit`, like the foliage files; `update_pictures` adopts the result with one image creation, keeps the old array
  while the same layers reload, and a newer layer set drops a finished job's result), so a terrain draws neutral layers until the frame
  after the job; `Renderer::wait_terrain_loaded()` is for tests and captures (`terrain_loading()` stays true until a frame adopts a
  finished job; `Engine::capture_scaled` waits and draws again, so `game.screenshot` shows the finished layers). `control` is one RGBA8 array of 1 or 2 slices (splat map 0,
  splat map 1 when there is one; the holes are NOT in it) made from the planes of `TerrainHeights`: the first repaint converts it into a
  `copy_dst` array (staging buffer, whole), later ones copy only the rectangle each `TerrainSplat::mark_dirty` named
  (`TerrainSplat::dirty_since`, `Renderer::terrain_uploads().splatRects`), and anything unknown (a version bump with no rectangle, a
  resampled map (maps of different sizes: every stroke), a second write in the frame, a backend that cannot copy) rebuilds the array
  whole; the holes texture (R8, one byte a cell) copies the cells of each `TerrainHeights::mark_holes_dirty` the same way
  (`holes_dirty_since`, `terrain_uploads().holesRects`) and a bare `holesVersion` bump makes it whole; it takes ONE sampler because the
  terrain's fragment program reads all 16 of the 16 units (the test "terrain: the fragment stage reads exactly the 16 texture units..."
  pins the count: a new texture replaces one, or moves to the vertex stage as the holes did). Where there
  is no array a 1 x 1 dummy array is bound (a stage must have every texture it declares). The per-layer values are in the 8 `fa_t_layer`
  vec4 of the block, `fa_t_tex` has the counts and the colour-space fix of the albedo (`albedoFix`, applied after the fetch: 0 as sampled, 1 the shader decodes
  sRGB to linear (a linear scene whose GPU gave no sRGB texture format), 2 it encodes linear back to sRGB (a gamma scene, an sRGB format)).
- *Holes (P5d).* Cut in the vertex stage, in all three programs: `vertex()` fetches the holes texture (R8, one byte a cell, `fa_vs_holes`, bound to the VERTEX stage only through
  `MaterialInputs::vsTextures`, 255 = hole; a terrain with no mask binds a 1 x 1 dummy) at the middle cell of the quad of the
  vertex and, in a hole, moves all four vertices of the quad to one (degenerate triangles). A `discard` in the terrain's fragment program
  does not compile on Metal (its fragment program is at the compiler's size limit: with a `discard` AND dynamic shading writes the GPU
  compiler of macOS fails with `METAL_CREATE_RPS_FAILED`), and this way the shadow and prepass need no copy of it. At a coarse level the
  middle cell of the quad decides: a documented approximation. `mesh_common.glsl` is not touched.
- *Items.* `gather_meshes` calls `TerrainRenderer::gather` before the `render.mesh_frustum` job: per terrain it brings the RG8 height texture up
  to date (a sculpt copies only its rectangle: `copy_rect` writes a transient staging buffer and runs `sg_copy_buffer_to_image` outside a pass,
  once a frame per terrain, after `Gpu::begin_transient_writes()`; the first sculpt makes the texture again as a `copy_dst` one, the whole
  texture, which cannot carry initial data; a backend or a state that cannot copy re-creates it whole; nothing on a frame without edits), runs `render.terrain_select` (one job
  chunk per terrain) and appends one opaque `MeshItem` per node (`terrain` = its `TerrainDraw`, `terrainNode` = the instance data: first
  column, first row, step, level, morph start and end). `TerrainDraw` (kept in `DrawContext::terrainDraws`, a deque) holds the sixteen vec4 block
  and the four textures; its hash is the items' `paramsHash`, so draws of two terrains or cameras never share a batch.
  `pack_instance_extras` copies `terrainNode` for these items, `material_inputs` the draw's block and textures.
- *Sort key.* Terrain items carry `kTerrainSortKey` with `keyed = true` (mesh_batch.h), so `build_batches` orders them like any keyed item
  and the batches of one terrain stay together.
- *Stats.* The main pass counts a terrain batch in `terrainTiles` / `terrainTriangles`, not in `meshes` or the material counters.
- *Limits.* The height texture is RG8 (r high byte, g low byte) because R16 unorm is not portable on GLES3; it is read with `texelFetch` through
  a nearest sampler. A grid larger than `sg_query_limits().max_image_size_2d` is reported once (with the largest side that fits) and skipped; the layer arrays
  need `max_image_array_layers` and `max_image_size_array`, a terrain whose layers do not fit gets no layer arrays (neutral grey, one message), and `render.supports` reports the
  three numbers as `limits` (`FeatureEnv`). Entries not asked for during 120
  frames free their texture. The collider is in `engine/physics/src/heightfield3d.cpp` (`update_heightfield` for a `Terrain3D`), reading the
  same `TerrainHeights`.

## Levels of detail (M75-P1a)

The user page is docs/BIG_WORLDS_LOD.md, "Levels of detail". The selection is pure and lives in `engine/scene/{include/fa/scene,src}/lod.{h,cpp}`
(`lod_level_of` for a `MeshRenderer`, `lod_group_level` for a `LodGroup`, `lod_screen_size`, and the cross-fade state `LodFadeState` with
`lod_fade_step` / `lod_fade_amount`; `lod_mesh` stays the bit-identical distance function). `engine/render/src/renderer_lod.{h,cpp}`
(`LodFades`, a member of `Renderer::Impl`) holds the render-only state.

- *Scene.* `RenderScene` keeps a flag (`has_lods()`: some mesh has `lods` or some `LodGroup` exists); a scene without either skips every
  LOD step in `gather_meshes` (the cost of that is one branch). It also lists the `LodGroup`s with the sphere of their subtree and gives each
  mesh the chain of groups above it (`SceneMesh::chainFirst/chainCount`, `lod_chains()`), so the gather asks only "does every group above show my child".
- *Selection per camera.* `gather_meshes` runs once per camera job. The first `camera:*` job of the frame is the main view: it `remember`s
  its picks in `LodFades` (`main_pick`). The shadow passes use the items of the main view's list, so they draw what it chose. Probe and GI captures
  set `Frame::lodFollowMain` (`probe_face_frame`): they read `main_pick`, never fade, and are not counted. A target, `CameraView` or split-screen
  job has its own `plan.name`, so it steps its own fade slots with its own distance and field of view.
- *Fade state.* A slot per (camera name hash, entity bits, kind) holds a `LodFadeState`; it advances once per gather by `Frame::dt`, a new entity
  starts settled, and `end_frame` drops the slots nobody asked about that frame (a destroyed or hidden entity, a camera that went away).
- *Drawing.* A fading entity makes two `MeshItem`s: the level fading in has `lodFade = +a`, the one fading out `-a`
  (`a = t` clamped to [1/256, 255/256], so the sign survives and the dither never degenerates). `fill_fs` writes it into `fa_mesh_fs_params.fa_gi.w`
  and `fa_lod_dither()` of `mesh_common.glsl` (interleaved gradient noise on `gl_FragCoord`, `discard` below / above `a`) is called at the
  end of the main and depth-prepass fragment code (after the alpha clip), no sampler. The function and its calls exist only under
  `FA_LOD_DITHER` or `FA_ALPHA_CLIP`: the engine's own programs get four variants for it, `mesh_lod`, `mesh_skin_lod` (`fs_lod`) and
  `prepass_lod`, `prepass_skin_lod` (`prepass_fs_lod`), which `Gpu::mesh_pipeline` / `prepass_pipeline` pick with their `lod` argument for an
  item with `lodFade != 0` and no material (made on first use, `Gpu::builtin_shader`). A custom material only dithers when it is
  `alphaMode "clip"` (`FA_ALPHA_CLIP` is defined for its programs and the dither goes after the clip's own `discard`). The programs of every
  other draw have no `discard`, because a fragment shader with one (even behind a uniform branch) loses the early depth test and hidden
  surface removal of a tile-based GPU. The two draws are complementary, and the prepass dithers the same way, so what it writes is what the
  main pass shows. `lodFade` is part of `material_key` (main pass) and `order_key`, and breaks the tie of the keyed draw sort, so a fading
  item leaves its instanced batch; `same_shadow_material` ignores it. The shadow shader never dithers: the item fading out (`lodFade < 0`)
  is skipped in the shadow cull and the one fading in casts solid.
- *What does not fade* (`canFade` in `gather_meshes`): a full-shader material (`material->full`, `mesh_full_common.glsl`), a custom material
  that is not `alphaMode "clip"`, and a mesh with subsurface scattering (`subsurface_of(mr)[0] > 0`, whose extra pass has no variant) switch
  at once (the outgoing level is dropped). A mesh under a fading `LodGroup` also switches its own `lods` at once.
- *Stats.* `RenderStats::lodCrossFades` counts the visible items with `lodFade != 0` of every main-view job; a capture does not count.
- *Cost.* A scene without `lods` and `LodGroup` draws with the same programs as before (no `discard` in them) and one flag check per gather.
  With `crossFade` 0 `LodFades::step` keeps no slot; the main camera's picks are kept for the captures (`remember`) only where the world has a
  `ReflectionProbe` or a `RealtimeGI`; `RenderScene::build_lod_groups` finds the meshes of a group through a flat table indexed by entity.
  The four variants add about 120 KB of GLSL ES and 155 KB of WGSL (source embedded) to the player. The mesh template changed (its hash), so
  the twin fixtures of the renderer's tests were regenerated (`FA_UPDATE_FIXTURES=1`). `LodFades` drops every slot when the world or its
  scene generation changes (entity ids repeat from one scene to the next).
