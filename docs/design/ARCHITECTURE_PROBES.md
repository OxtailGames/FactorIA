Part of [ARCHITECTURE.md](ARCHITECTURE.md).

# Reflection probes: capture, atlas and mesh sampling (M73-P3b, P3c)

What a `ReflectionProbe` becomes in the renderer: the capture of the scene around it, the octahedral map it is stored as, the one
atlas image that holds the maps of every probe (and of the sky), the scheduler that spreads the captures of the realtime probes over
the frames, and the files of a baked probe; and how the lit meshes read the atlas (P3c). The user's side (the fields, the commands, what to expect) is in
[RENDERING_PROBES.md](../rendering/RENDERING_PROBES.md). This page is for whoever changes the renderer.

**State after P3c.** Probes are captured (or loaded from a baked page) into the atlas, listed by `render.probes`, and read by the mesh
fragment shader at view 14 (the sky is the atlas' entry 0): each draw reflects up to two probes picked on the CPU plus the sky, with
box projection and roughness levels. The sky's prefiltered cube is only the source the "sky-env" pass copies into entry 0. "What the
meshes read" says how; "What P5d-2 can use" what the next package may build on.

## Where the code is

| What | File |
|---|---|
| The CPU half: the octahedral maths, the tile layout, the allocator, the scheduler, the manifest | `engine/render/include/fa/render/probe.h`, `src/probe.cpp` |
| The GPU programs (capture copy, pyramid, GGX filter, SH projection, upload blit) | `engine/render/shaders/probe.glsl` and its generated headers |
| `ProbeGpu` (programs, atlas image, scratch cubes) and the bookkeeping `ProbeSystem` | `src/renderer_probes.h`, `src/renderer_probes_gpu.cpp` |
| The per-frame plan and finish, the report, the synchronous capture | `src/renderer_probes.cpp` |
| Which probes a mesh reflects: the pure `pick_probes` and `ProbeVolume` (P3c) | `src/probe_select.{h,cpp}`; `render_scene.cpp` calls it per mesh |
| The mesh shader's reads (`fa_probe_*`, `fa_environment`, `fa_ambient_light`) and the CPU side of its uniforms (`fill_probe_fs`) | `shaders/mesh_common.glsl`, `mesh_full_common.glsl`; `src/renderer_draw.cpp` |
| The `render.probes` command | `engine/runtime/src/shot_commands.cpp` |
| The `probe.bake` command | `tools/authoring/src/probe_commands.cpp` |
| The tests | `engine/render/tests/probe_tests.cpp` (CPU), `probe_render_tests.cpp` (GPU), `probe_sampling_tests.cpp` (the pick on the CPU; the sampling on the GPU), `tools/authoring/tests/probe_commands_tests.cpp`, `engine/runtime/tests/shot_tests.cpp` |

The CPU half has no GPU in it, so every rule below that is not about pixels (placement, eviction, slicing, files) is tested without one.

## The octahedral map

A probe's picture is the sphere of directions folded onto a square: the half around +Y is the inner diamond, the half around -Y is
the four corner triangles (`oct_encode` / `oct_decode`, y down the image). The map has a ONE-TEXEL BORDER that holds the texel across
the edge (`oct_fold`: the coordinate beyond [-1, 1] is mirrored back and the other coordinate negated), so a bilinear tap at the
edge of a level reads the right neighbours with a clamped sampler: the shader needs no wrap code and the filter passes write the
border like any texel, by direction.

Each texel of a level of `size` texels has the solid angle `oct_texel_weight` (they sum to 4 pi); every projection (the SH, the
GGX filter's normalisation) uses it, the GPU's and the CPU's `probe_sh_from_page` alike.

## The tile

A tile of resolution R is one rectangle of the atlas. R is 32, 64, 128 or 256 (`probe_resolution` rounds a request to the nearest,
ties up). `probe_layout(R)` gives the rectangles:

```
 x = 0                     x = R+2
 +------------------------+---------------+
 | level 0                | level 1       |   level k has (R >> k) texels + the border all around
 | R x R (+2 border)      | (R/2)+2 square|
 |                        +---------------+
 |                        | level 2       |   levels k >= 1 are stacked in a column to the right of level 0
 |                        +---------------+
 |                        | level 3 ...   |
 +------------------------+---------------+
 | SH row: 9 texels, y = tileH - 1        |
 +----------------------------------------+
```

- **Levels.** `probe_levels(R)` = 3, 4, 5, 5 for R = 32, 64, 128, 256. Level k holds the scene convolved with the GGX lobe of
  roughness `k / (levels - 1)` (`probe_level_roughness`): a surface of roughness r reads level `r * (levels - 1)`, the atlas has no
  mip chain, so a reader blends the two nearest levels by hand. Level 0 is the mirror.
- **Size.** The tile is `(R + 2) + (R/2 + 2)` wide and `R + 2 + 1` tall: 52 x 35, 100 x 67, 196 x 131, 388 x 259 texels.
- **The SH row.** The nine L2 spherical-harmonics coefficients of the probe's light (the diffuse ambient term) are the nine texels
  of the LAST ROW of the tile, coefficient i at x = i, RGB each. In RGBA16F they are the raw values; in the RGBA8 fallback each
  channel is `clamp(c / 4, -1, 1) * 0.5 + 0.5` (so a coefficient is read back as `(t * 2 - 1) * 4`, a resolution of 1/64 and a range
  of +-4). The SH is projected, in one pass, from the 16 x 16 image of the pyramid (`probe_sh_source`), so its cost does not depend
  on R.
- **A baked page** is the tile without the SH row (`probe_page_width` x `probe_page_height`); the SH is nine numbers in the manifest.

## The atlas

One 2D image, `kProbeAtlasSize` = 1024 square, RGBA16F (8 MB), made when the first probe appears, or when the scene's meshes first use the baked sky (the sky alone keeps it: +8 MB
with no probe in the scene), and released when neither is left (`render.probes` answers an empty report while no probe exists). Every reader of a probe's picture needs exactly one texture and one
sampler, which is why a 2D atlas and not cube maps: sokol has no cube arrays, and the mesh fragment shader's sixteen units are all
taken (P3c put the atlas where view 14 was, the sky's cube: the units stay 16 of 16, the sampler is the shared `LinearClamp` one, sampler 10).

- **On a GPU that cannot render to half floats** the atlas is RGBA8 and the captures are what a gamma-coded picture holds. A
  synchronous capture (`probe.bake`) refuses it: the baked page is HDR, so it asks for RGBA16F and says so.
- **Atlas entry 0 is the sky** (`kProbeSkyId` = 0, `kProbeSkyResolution` = 128, importance `INT_MAX`: never evicted). It is written
  from the environment cube the renderer already bakes (renderer_env.h): the five levels from its prefiltered lods, the SH row from
  its mip 5 (the 4 x 4 mip that the sky's own SH pass already writes, face +X). So meshes that fall back to the sky (where no
  probe's box reaches) read the same tile as a probe. The entry is written at the tail of the "sky-env" pass (`probes_write_sky`) when
  the sky's re-bake keys change, and by `probes_plan` when the atlas was just made over a baked cube, so no frame draws the tile before
  it holds the sky. A scene with no sky material has `skyState` "noSky": the meshes keep the gradient, as before (`fa_env_sky.w` = 0).
- **Allocation** (`ProbeAtlasAllocator`). A tile goes into a SHELF of its own height (a row of equal slots, one resolution per
  shelf), shelves are stacked from the top, and a shelf whose slots are all free is given back. Deterministic: the same requests
  in the same order give the same places on every machine. With every probe at 128 the 1024 atlas holds 5 x 7 = 35 tiles; with
  256 about 2 x 3 = 6, and a mix is bounded by the shelves.
- **Eviction.** When no slot is free a request takes the place of a probe of STRICTLY lower importance (the lowest importance, then
  the one used longest ago, then the largest id). Equal importance never evicts: two probes would push each other out every frame.
  An evicted probe is "noRoom" in the report, and returns by itself when a tile is free. The sky is never evicted.
- **Budget.** `kProbeMaxCount` = 256 probes are kept; more are not kept (the report's `overLimit` counts them, and there is one warning in the log). The texels are bounded by
  the atlas, so the cost is at most 8 MB plus the scratch cubes (`probe_set_budget` does not change memory).
- **Release.** A removed `ReflectionProbe` (or its entity) gives its tile back at the next frame; a changed resolution moves it.

## The capture

The six faces of the scene, as seen from the probe, are drawn by ordinary VIEW JOBS of the frame graph: each face is a camera of
90 degrees into a square RGBA16F image, so a capture draws what a camera draws (meshes, particles, the sky) with the probe's
`nearPlane`, `farPlane`, `clear` and tags (`showTags` / `hideTags` like a Camera). The face camera is right-handed (`probe_face`).
No tone mapping and no post effect runs on a capture: the probe holds scene-referred light. In a scene whose format is RGBA8 (no
half-float targets) the captured values are therefore gamma-space (document, not fix: this GPU also gets the RGBA8 atlas).

Then, in the same frame the sixth face is ready:

1. `face_to_cube`: each face picture is copied BY DIRECTION into face f of the slot's scratch cube S0 (the cube map's own face basis
   is left-handed and the capture camera right-handed, so projecting by direction makes the handedness irrelevant, and the GL
   read-back flip is a rule of the face job, not of the filter).
2. The pyramid S1 .. S(P-1): each the bilinear down-sampling of the one before (the passes of the sky's pyramid).
3. `filter`: level 0 of the tile is S0 sampled by direction; level k the GGX lobe of roughness k / (levels - 1) read from S_k (the
   pyramid level whose texel size matches the lobe, so the sample count is fixed); the SH row is the projection of the 16 x 16
   image. Every pass draws one rectangle of the atlas (a level with its border, or the nine SH texels). The `intensity` of the
   component multiplies the light here (a realtime probe) or when a baked page is uploaded.

The scratch cubes belong to a SLOT: the scheduler's set of six face images, because the faces of a time-sliced capture accumulate
in S0 over several frames. There are `kProbeSlots` (2) of them plus one for the SYNCHRONOUS capture (`Renderer::probe_capture`, used
by `probe.bake` and the tests), which draws its six faces at once into a 512 atlas of its own and so never disturbs a probe under
way. The scratch cubes of a slot are made again when the resolution changes and freed with the synchronous capture's end. They are made
when the frame is PLANNED and the filtering of a capture runs at the end of the frame, so the scheduler never gives a slot to a
probe of another resolution in the call in which the slot's capture completed (the other probe takes the other slot or waits one
frame; a probe of the same resolution may follow at once, its faces are copied into the cube after the first one's filtering, in the job order).

## The scheduler (`ProbeScheduler`)

`update` of a realtime probe: `everyFrame` (captures whenever it can: it draws up to its six faces a frame within the budget),
`timeSliced` (the default: one capture after another as the budget allows) or `onDemand` (once when it appears, and then only after
`probe_refresh`, which is the command `render.probe_refresh`). The budget is the faces ALL realtime probes may draw in a frame: `kProbeFaceBudget` = 2 by default (a 128 probe
is complete every three frames), `probe_set_budget` clamps it to 1..12. At most `kProbeSlots` probes are under way at once; the
next waits. Captures under way continue first (in the order of their slots, so a newcomer never starves them); a free slot then goes
to the due probe that was never captured or was refreshed, then an `everyFrame` one, then the larger importance, the capture
longest ago and the smaller id, so the work does not depend on the order of the scene. The plan is a function of (probes, budget, frame) alone, never of time or of the CPU.

A face the renderer cannot draw (its probe lost its tile, the scratch or face images cannot be made) is given back with
`ProbeScheduler::abandon`: the capture starts again from the first face (a capture that `plan()` had completed is undone, and an
`onDemand` probe still owes its refresh), the rest of its faces in the plan are not drawn, and a real failure (no images) keeps the
probe out of the plan for `kProbeRetryFrames` (30) frames, `state` "failed" meanwhile. A face that was not drawn never counts as drawn.

The probes of the renderer are keyed by entity bits, which the scene's reload and a switch to another scene reuse. So the renderer
keeps the `World` and `World::scene_generation()` it planned for; when either changes it forgets every entry and the scheduler's
state (the atlas stays, and its tiles are given back through the entries), and the probes of the new scene capture from zero.

While a capture is under way the tile keeps the last complete picture (the sixth face's filter overwrites it in one frame), so a
reader never sees half a capture. `render.probes` shows `facesDone` (0..5) and `captures` for each probe.

A frame with no probe runs none of this: no atlas, no programs, no jobs, no draw call. The perf budgets of the examples are
unchanged by P3b for that reason (`drawCalls` and `entities` in tools/cli/tests/perf).

## Baked probes

`probe.bake` (tools/authoring) captures one probe synchronously and writes, in this order:

1. the page `<stem>.<entity>.probe.<hash16>.hdr`: a Radiance `.hdr` of the tile without its SH row, encoded by the repo's own
   `encode_hdr`, so the bytes are the same on every machine (the name holds the first 16 hex digits of the SHA-256 of the bytes);
2. the manifest `<stem>.<entity>.probe.json` (`ProbeManifest`: version, resolution, levels, page, entity, `hash`, `sh` as nine
   RGB triples) atomically, with `fs::write_bytes` (it replaces the file; a reader sees the old pair or the new one);
3. the old page, removed after the manifest names the new one (best effort and silent: a page that Windows still holds open stays
   as an orphan with its hash in the name, and only a file named `<stem>.probe.<hash>.hdr` of that manifest is ever removed).

An unchanged scene gives the same page bytes, so nothing is rewritten. `apply` (default true) sets `ReflectionProbe.bakedMap` to
the manifest in memory (keep it with `scene.save`) and asks the renderer to reload it; `Renderer::reload_asset(manifest)` is also
what the hot reload of a changed manifest calls, and the renderer compares the hash, so a rewrite with the same bytes uploads
nothing. A baked probe's page is uploaded to its tile (times `intensity`) by the `upload` pass, and again when its tile moves or its
gain changes. States of a baked probe in the report: "ready", "noBake" (no `bakedMap`, or the manifest/page is missing or broken:
the `message` names the file and the fix), "noRoom".

## What the meshes read (P3c)

**The binding.** `kMaterialEnvView` (14) / `kMaterialEnvSampler` (10) of every mesh program: the atlas image (`ProbeSystem::atlas.tex`) and
the shared `LinearClamp` sampler, or a white image while no atlas exists (`bind_textures`). The constants keep the name of the sky's cube
they once held. The shadow and prepass programs of a clip material bind it too. A capture frame (`Frame::noProbes`) reflects the sky
only (no bounce).

**The atlas is not always square.** It is 1024 wide and 1024 tall, but P5d-1 makes it taller (1024 x 1156: a band of GI blocks below the
reflection tiles) while a `RealtimeGI` exists, and square again after. The shader therefore never divides by one number: every lookup
uses `fa_atlas_size()` (`textureSize` of the bound image), so it is right for any size, and `fa_atlas.x` (the width) is only what the CPU
wrote for the tests. CPU code that turns texels into a uv or a viewport uses the atlas' width AND height (`ProbeGpu::Atlas`).

**The pick (CPU).** `pick_probes` (`probe_select.cpp`) is a pure function of the probes' boxes (`ProbeVolume`, built once a frame by
`probes_build_volumes` from the probes that hold a capture, in the entries' id order) and the position of the mesh (the centre of its
bounds, `render_scene.cpp`). A probe reaches a point inside its box (the entity's matrix, scale included) with the weight
`clamp(inside / blendDistance, 0, 1)`, `inside` being the smallest distance to a face along the box's own axes, rounded to 1/32; a
weight of 0 does not reach. The best two are kept: the larger `importance`, the smaller box volume, the nearer capture position, the
smaller id. B is dropped when A has weight 1. The shares of the light are A = w_A, B = w_B x (1 - w_A) and the sky
has the rest, so they add up to 1. `ProbePick::key()` (the two indices and weights, 0 = none) is folded into `SceneMesh::probeKey`, the
same key the baked light probes use, so the batches merge exactly the meshes that reflect the same, and the shadow batches are not
touched. A mesh no probe reaches has `key() == 0` and the keys it had before. At most 511 volumes are looked at. The scene is built once
a frame with the volumes of the probes captured in EARLIER frames (`renderer.cpp`), so a probe is read from the frame after its capture is
complete; `Renderer::probe_mesh_report` (the `entity` argument of `render.probes`) answers from the picks of that build.

**The uniforms (`fa_mesh_fs_params`, 11 vec4 more: the block is 50 vec4, 800 B, it was 39).** `fa_atlas`: x = the
atlas' size, y = 1 for RGBA8 (its SH row is coded), zw = the sky tile's origin. `fa_rpa_tile` / `fa_rpb_tile`: xy = the tile's origin, z =
its resolution, w = its share. `fa_rpa_pos` / `fa_rpb_pos`: xyz = the capture position, w = 1 when box projection is on.
`fa_rpa_bx/by/bz` (likewise `fa_rpb_*`): the three rows of the world -> unit box map (`ProbeVolume::rows`; the box is where all three
are in [-1, 1]). `fa_env_sky.w` = 1 when the sky's entry holds the baked sky. `fill_probe_fs` writes them per draw, and zeroes the probes of
an unlit mesh, a capture frame and a probe that is not in the atlas (evicted, or not captured yet): the sky takes its share.

**The reads (GLSL, `fa_env_funcs`).** `fa_oct_encode` (the shader copy of `oct_encode`) -> `fa_probe_level(origin, res, level, e)`, a
bilinear tap inside level k of the tile (the border texel keeps it from reading a neighbour), `fa_probe_radiance` blends the two levels
nearest `roughness * (levels - 1)` (levels = 5, 4 or 3 by the tile's resolution, as `probe_layout`), `fa_probe_box_dir` bends the
direction to the box (`#ifdef FA_ENV_PARALLAX`, defined in the built-in program only: a full-shader material's `lighting()` reads the
probes without parallax), `fa_probe_sh_coef(origin, res, k)` reads texel k of the SH row. `fa_environment(d, rough)` is
`sky x (1 - sa - sb) + A x sa + B x sb` (the sky from its tile with `fa_env_sky.w`, else the gradient) and replaces the old cube read, so
the specular IBL, the clear coat, sheen and anisotropy layers and `fa_sky_light` all see probes. `fa_ambient_light(n)` blends the nine
SH coefficients of the sky and the probes by the same shares and evaluates once.

**The diffuse precedence** (`fa_indirect_diffuse`): the lightmap texel; else the baked light probes (M73.4d) over the coverage they
have, mixed with `fa_ambient_light(n)` (the reflection probes' SH and the sky's) for the rest; else `fa_ambient_light(n)`. A lightmapped
surface keeps its specular reflection of the probes (a lightmap holds no direction), and `fa_baked_keep` (the baked direct lights a mixed
light must not add again) is untouched: the probes add no direct light, so there is nothing to subtract.

**Cost.** A scene with no probe in reach is the sky-only frame byte for byte (a test compares the two; the extra reads sit behind
`share > 0` branches); a probe adds no draw call. The atlas stays at 8 MB (4 MB RGBA8), made by the sky alone too. The pick is a
loop over the probes of the scene per mesh on the scene build (the job split does not change it).

**The editor.** `tools/editor/src/viewport.cpp` draws the box of a selected ReflectionProbe (a perspective view only), and the
Inspector's `render.probes {entity}` is the way to ask which probes a mesh reflects.

## What P5d-2 can use

- The atlas is one image at fragment view 14 with the unit's sampler 10: anything that stores a map in it as a tile (the GI grid of P5d-1)
  is read by the same functions given the tile's origin and resolution. `fa_probe_radiance(origin, res, dir, roughness)` and
  `fa_probe_sh_coef(origin, res, k)` take ANY tile, not only a ReflectionProbe's. The binding needs no change: P6b's transmission
  keeps its own unit (view 28).
- To make a draw read another tile, fill `fa_rpa_*` / `fa_rpb_*` in `fill_probe_fs` (a pick with a tile and a share; `fa_rpX_pos.w` = 0
  skips the parallax) or add vec4s next to them; every fs-params change is mirrored in `mesh_full_common.glsl` (a test compares the
  two blocks) and costs a regeneration of the shader header and of the fixtures (`FA_UPDATE_FIXTURES=1` through `fa_test_tooling`).
- Sharing the two picks with a third source means a change to the share rule (`ProbePick::shares`: the sky has what the probes leave) and
  to the batch key (`ProbePick::key()` has 9 + 6 + 9 + 6 bits, 30 of 32; a larger pick needs a wider key).
- A probe that is `noRoom` or not yet captured is simply absent from `probeVolumes`, so the sky takes its share: a new source of tiles
  should follow the same rule (a tile that holds nothing yet is never listed).

## Limits and what is not verified

- 256 probes (`kProbeMaxCount`); the atlas 1024 square; the faces per frame 1..12; resolutions 32, 64, 128, 256.
- A probe captures what the frame graph draws: no reflection of another probe (no bounce), no screen-space effect, no transparent
  sorting beyond what a view job does.
- The GPU tests ran on Metal (the hardware of the developer's Mac), the RGBA8 fallback only forced on Metal. OpenGL, D3D11 and the
  software backends (llvmpipe, WARP) are checked by CI; the read-back flip of the face jobs on GL (`flipH`) is the part with the
  least cover on this host.
