# FactorIA architecture: baked lighting (the CPU baker)

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page). This page describes the core of the lightmap
baker of M73.4: `engine/scene/include/fa/scene/lightmap_bake.h` and `bvh.h`, with `src/lightmap_bake.cpp` and `src/bvh.cpp`. It is
plain data in and float buffers out: no renderer, no file format and no command (the lightmap runtime and the UV2 generation,
the `lightmap.bake` command that writes Radiance `.hdr` files, and the probe grid are later packages that build on this API).

## The pieces

- **`TriBvh` (`bvh.h`).** A bounding volume hierarchy over triangles (three points each, copied in). The tree depends only on the
  triangles: a median split on the longest axis of the centroids, ties broken by triangle index. `closest()` gives the nearest hit
  (distance, triangle, barycentric weights), `occluded()` stops at the first one, `nearest()` is the distance only. Both faces
  are hit and a triangle with no area is left out. The model texture maps (`model_texture_maps.cpp`, ambient occlusion and
  thickness) use the same class, so their results did not change when it was promoted from `src/`. (`engine/physics` has
  another BVH, for shapes; the scene module is below physics and does not use it.)
- **`BakeScene`.** Meshes in world space (positions, optional normals, one lightmap UV per vertex that is 0..1 of its atlas, a
  material per triangle), materials (`albedo` 0..1 and `emissive` radiance), lights, the atlas sizes and a sky. A mesh with
  `atlas = -1` only shadows and bounces; `castsShadow = false` only receives. `validate_bake()` checks all of it and names the
  field with a JSON-pointer-like path (`/meshes/2/lightmapUv/17`) and what to change.
- **`bake_lightmap(scene, settings)`.** One `BakedAtlas` per atlas: `rgb` (three floats per texel, row 0 first; v = 0 is row 0),
  a `mask` (`kBakeEmpty`, `kBakeBaked`, `kBakeDilated`) and counts, plus `BakeStats` (texels, rays, the budgets used).
  `hash_bake_result()` is a 64-bit hash of every bit of it, for tests and logs.
- **`sample_irradiance_sh(scene, points, settings)`.** The light around each point as nine spherical-harmonics coefficients
  (`ShL2`, bands 0..2; the first four are an L1 probe) from the same tracer; `sh_irradiance(sh, normal)` evaluates the diffuse
  light for a normal (the radiance convolved with the clamped cosine). The probe grid and the mixed lights are a later package.
- **Helpers.** `dilate_texels()` (the gutter, usable on any atlas), `suggest_atlas_size(area, texelsPerMeter, maxSize)`.

## Units

A texel value is the light a white diffuse surface shows: the runtime multiplies it by the albedo. So a sky or an emissive surface
of radiance L lights an open surface with L (the stored value is irradiance / pi), and a directional light of intensity I lights
a surface that faces it with I (the realtime light loop has no 1/pi either). A point or spot light keeps the realtime falloff
`(1 - (d / range)^2)^2` and the realtime cone (a smoothstep from the cosine of the half angle to a quarter of the way to 1) by
default, so the baked and the realtime light of the same lamp match; `BakeFalloff::InverseSquare` gives `1 / d^2` instead. An
area light is a one-sided rectangle with the radiance `intensity`. Colors are linear. +Y is up and the sky is a gradient
(zenith, horizon, ground, scaled by `intensity`) or an equirectangular float image (`u = 0.5 + atan2(z, x) / 2 pi`, `v = acos(y) / pi`)
that replaces it. Emissive surfaces light the others, not themselves.

## The algorithm

1. **Validate and budget.** Settings ranges, atlas sizes (`maxAtlasSize`, the texel density cap), indices, finite numbers, UV range,
   materials, lights and sky. The memory estimate is `texels * 80 + triangles * 240` bytes (probes: 160 per point) in 64-bit
   saturating maths (a 32-bit `size_t` on wasm cannot wrap it) and is compared with `maxMemoryBytes` before anything is allocated.
2. **Flatten.** Corners, shading normals, UVs, face normals (turned to the side the vertex normals point to), materials; the BVH
   over the triangles that cast shadows; `rayEpsilon` (0 = a ten-thousandth of the scene's size).
3. **Rasterise each atlas.** A texel belongs to the first triangle (in mesh and triangle order) whose UV triangle covers the texel's
   centre; its barycentric weights place a point on the surface. UVs that overlap are counted (`overlappedTexels`). The covered texels are the work list. The ray budget
   `maxRays` is checked now, before any ray: `texels * (samples * (1 + bounces * (1 + lights)) + shadowSamples * lights)`.
4. **Trace each texel** (the same code serves a probe, from any point and direction):
   - the *direct* light: for every light that is `Baked`, `shadowSamples` points on the light (a disc facing the texel for a sphere
     light, the sun disc for a directional light, the rectangle for an area light), each with a shadow ray; the average of what
     passes, times N.L;
   - the *gather*: `samples` rays with a cosine-weighted direction (a Hammersley set shifted per texel). A ray that escapes adds the sky.
     A ray that hits a surface adds its emission, then (while `bounces` allows) the direct light that reaches the hit point times its
     albedo (`IndirectOnly` lights count here, so a mixed light bakes only what it bounces), and continues with a new cosine-weighted
     direction and the throughput times the albedo. From the second hit on, Russian roulette ends a path with
     probability `1 - max(throughput)` (at least 5 % survive) and weighs the survivors by `1 / p`.
   - `bounces = 0` is direct light, the visible sky and emitters; each further bounce reflects the light once more.
   A shading normal that leans below the face discards the rays that go into the surface.
5. **Post.** A cross-bilateral denoise (`denoiseRadius`, `denoiseSigma`): neighbours in the atlas weigh by distance, by the
   agreement of their normals (cos^8) and planes (in texel spacings of the surface) and by how close their light is relative to the
   light itself, so shadow edges stay. Then the gutter: `dilatePasses` passes copy the mean of the filled 8-neighbours into empty
   texels (`kBakeDilated`). Seams between pieces are not stitched yet.

## Determinism

The rules are those of the jobs (docs/design/ARCHITECTURE_THREADS.md, "Jobs and threads"), and the test case "the same bits with no pool,
one worker and many workers" holds them:

- No `rand()`, no clock, no thread id. Every random number is `hash(seed, atlas, texel, sample, bounce, dimension)`
  (a SplitMix64 finaliser), so a texel gets the same numbers whichever thread traces it.
- Each texel writes only its own slot (colour, mask, position, normal), and the count of rays is the sum of per-chunk
  counts added in chunk order (`parallel_map_chunks`). Chunk bounds depend only on the counts. The denoise reads one buffer and
  writes another.
- Only `+ - * /`, `sqrt`, `floor` and `fa::det` trigonometry and `exp`; the build has no floating-point contraction, so the bits
  are the same on every platform too (not asserted by a committed hash yet).
- Progress and cancel work on batches: the work list is cut into batches of `max(256, count / 40)` texels, each a `parallel_for`
  (chunks of 16 texels; 256 for the denoise, 2 for probes); after each batch the calling thread reports
  `lightmap bake: atlas 1/2, texels 2048/4096 (50%)` through `report_command_progress` (the sink is per thread, so only this
  thread reports) and reads the cancel flag of its `CommandCancelScope`. Every chunk also polls that flag for each texel (the flag is
  per thread too, so it is read once on the calling thread and the pointer is shared). A cancelled bake returns the error
  `cancelled` and no result. Cutting into batches changes nothing in the result.

## Budgets and refusals

`maxAtlasSize` (default 4096), `maxMemoryBytes` (1 GiB) and `maxRays` (5e10) are deterministic work counts, never times. Each refusal is
an `fa::Result` error that names the field, the numbers and what to change, and says that nothing was allocated or traced.

## Not done yet

Textured albedo and emission (a material is one color per triangle), seam stitching, importance sampling of a bright sun in an
HDRI (a very bright small light is noisy; use a directional light for it), and any GPU path (M79).
