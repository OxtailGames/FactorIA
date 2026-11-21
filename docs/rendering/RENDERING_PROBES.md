Part of [RENDERING.md](../RENDERING.md): the reflection probes, the captures of the scene around a point that the lighting reads
for reflections. The rest of the M73 lighting is in [RENDERING_LIGHTING.md](RENDERING_LIGHTING.md).

# Rendering: reflection probes (M73-P3b, P3c)

A `ReflectionProbe` entity captures the light around its position: the six directions of the scene are drawn, filtered into a
mirror picture and two to four rougher ones (the GGX lobes of a rougher surface: a 128 or 256 probe has four, a 64 one three, a 32
one two) and nine spherical-harmonics coefficients (the diffuse
light), and stored in one shared atlas. **The lit meshes read it** (see "What a mesh reflects" below): a mesh inside a probe's box
reflects the probe, one outside every box reflects the sky as before, and `render.supports("reflectionProbes")` is true on every GPU
that draws. `render.probes` shows what the renderer holds. How it is built: docs/design/ARCHITECTURE_PROBES.md (repository only, not in the binary).

- **Fields** (all in `docs.components`): `mode` (`baked`: read from `bakedMap`; `realtime`: captured while the game runs), `resolution`
  (32, 64, 128 or 256 texels per side; anything else is rounded to the nearest), `nearPlane` / `farPlane`, `clear` (`sky`, or `color`
  with `clearColor`) for what a capture shows where no mesh is drawn, `showTags` / `hideTags` (like a Camera's: hide what must not be
  reflected, for instance the entity of the player), `intensity` (a gain on the light the probe holds), `importance`, and `boxSize`,
  `boxOffset`, `blendDistance`, `boxProjection` (the region a probe lights and how reflections are corrected for it; the box turns and
  scales with the entity). A probe is placed at its entity's position; the capture looks all around. The editor draws the box of a
  selected probe in cyan.
- **Realtime.** `update` says when: `timeSliced` (the default; a capture is spread over frames), `everyFrame` or `onDemand` (captured when it
  appears, and again only when `render.probe_refresh` asks for it; `render.probe_refresh {}` without `entity` asks every realtime
  probe, and the C++ call is `Renderer::probe_refresh`). A capture is six faces and the filtering, and all realtime probes together draw
  at most two cube faces a frame by default (a probe at 128 is complete every three frames, `faceBudget` in `render.probes`), so a
  refresh shows after a few frames, never at once. Two probes are under way at once, so the cost of many probes is a number you
  choose, not the probes' count; `everyFrame` probes start their next capture before the others. While a capture is under way the
  probe keeps its last complete picture. A capture whose faces cannot be drawn (the GPU is out of memory) leaves the probe `failed`
  with the reason, and it is tried again after 30 frames. When the scene is reloaded or another one is loaded, every realtime probe
  captures the new scene from the start (an `onDemand` one included), keeping the atlas. A frame with no probe in the scene costs
  nothing.
- **Baked.** `probe.bake {"entity": "lobby"}` captures once, at full speed, and writes a Radiance page `<scene>.<entity>.probe.<hash>.hdr`
  and a manifest `<scene>.<entity>.probe.json` next to the scene (`path` picks another manifest, which must end in `.probe.json`;
  `apply: false` leaves `bakedMap` alone). Without `apply: false` the probe's `bakedMap` is set at once and the renderer reads the pair
  (keep it with `scene.save`). The same scene gives the same bytes; a changed one gives a new page and the old one is deleted. Rebaking
  while the game runs, or editing the manifest, reloads the probe. A baked probe whose files are missing says so in `render.probes`
  ("noBake" and the file) and the game runs on.
- **The atlas.** One 1024 x 1024 RGBA16F image (8 MB), made when the first probe appears or the scene's meshes first use the baked sky
  of a sky material (the sky alone keeps it: +8 MB in such a scene, with no probe), and released when neither is left. It holds the
  sky too (entry 0, from the environment the renderer already bakes). A 128 probe takes 196 x 131 texels, so about 35 fit; when the
  atlas is full a probe takes the place of one with a strictly lower `importance`, and an equal one is never evicted (`noRoom` in
  the report). At most 256 probes are kept; the report's `overLimit` counts the active ones beyond them (the smallest `importance`
  goes first), which have no entry in `probes`.
- **What a capture holds.** Scene values before tone mapping and without post effects, like the sky. On a GPU that cannot render to half
  floats the atlas is RGBA8, a realtime probe is captured in the scene's own (gamma) space, and `probe.bake` answers `unavailable`
  (a baked page is HDR).
- **What a mesh reflects.** Every lit mesh (an `unlit` one reflects nothing) is given up to TWO probes by the position of its bounds'
  centre, and the sky keeps the rest of the light. A probe reaches a mesh inside its box, with weight 1 deeper than `blendDistance`
  from the box's face and falling to 0 at the face (0 distance: a hard edge); weights are rounded to 1/32, so the meshes of a row of
  crates still share a draw. Of the probes that reach it, the larger `importance` is first, then the smaller box, then the nearer
  capture position, then the smaller id; the second is used only while the first is below weight 1 and takes what the first leaves
  (the sky has the rest). A surface of roughness r reads the filtered level of the map for r (the mirror picture at 0, the roughest at
  1; the two nearest are blended), and `boxProjection` bends the reflection ray to the box before it is read from the capture position
  (an interior's walls are where the box edge is). The sky reflection is the same reading of entry 0 of the atlas, so a probe fades
  into it with no seam. Cost: no probe in the scene is the sky-only frame, byte for byte; a probe adds a few texture reads for the meshes it
  reaches and no draw call (meshes with the same picks batch together). A realtime probe is read from the frame after its capture is done,
  and a probe that is `noRoom`, `noBake` or still `pending` is skipped (the sky fills in). The faces of a capture read the sky only (no
  reflection of another probe).
- **The diffuse light** of a lit mesh comes, in order: from its baked lightmap texel; else from the baked light probes that cover it
  (`LightProbeGroup`) over the share they cover (the share they leave goes to the sky and the reflection probes' SH, not to a `RealtimeGI` grid); else from a ready `RealtimeGI` grid where its probes surround the point (it fades out
  over half a probe spacing outside them); else from the nine spherical-harmonics coefficients of the reflection probes that reach it
  (blended by their shares with the sky's); else from the sky (a sky material's) or `ambientLight`. The first one that covers the
  fragment wins and what it does not cover goes to the next; a probe never adds to a lightmap. The specular part stays the reflection
  probes' and the sky's whatever gives the diffuse part. The reflection probes' specular part still applies on a lightmapped surface (a lightmap holds no reflections), and a
  lightmapped mesh's `fa_baked_keep` lights (baked into its lightmap) are not added again, as before. A mixed or custom material's
  `ambient()` receives the same value as `ambientColor`.
- **`render.probes`** lists the atlas (`size`, `format`, `tiles`, texels used and reserved), the sky's entry and each probe: `entity`
  (its scene id), `mode`, `state` (`ready`, `pending`, `capturing`, `noRoom`, `noBake`, `failed`), `tile`, `captures`,
  `lastFrame`, and for a realtime probe `facesDone`. It is `{"probes": [], "atlas": null}` while no probe exists. With `entity` (a mesh)
  the result also has `mesh: {probes: [{entity, share}], sky}`: what that mesh reflected in the last frame (the shares add up to 1;
  a mesh no probe reaches, or one that was not drawn, has `probes: []` and `sky: 1`).
