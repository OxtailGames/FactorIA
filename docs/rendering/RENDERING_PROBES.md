Part of [RENDERING.md](../RENDERING.md): the reflection probes, the captures of the scene around a point that the lighting reads
for reflections. The rest of the M73 lighting is in [RENDERING_LIGHTING.md](RENDERING_LIGHTING.md).

# Rendering: reflection probes (M73-P3b)

A `ReflectionProbe` entity captures the light around its position: the six directions of the scene are drawn, filtered into a
mirror picture and two to four rougher ones (the GGX lobes of a rougher surface: a 128 or 256 probe has four, a 64 one three, a 32
one two) and nine spherical-harmonics coefficients (the diffuse
light), and stored in one shared atlas. **Captured and stored today; read by the meshes in M73-P3c.** The meshes still reflect the
sky as before, so a scene with probes looks the same until then; `render.probes` shows what the renderer holds, and
`render.supports("reflectionProbes")` stays false (planned) until a mesh reads a probe. How it is built: docs/design/ARCHITECTURE_PROBES.md (repository only, not in the binary).

- **Fields** (all in `docs.components`): `mode` (`baked`: read from `bakedMap`; `realtime`: captured while the game runs), `resolution`
  (32, 64, 128 or 256 texels per side; anything else is rounded to the nearest), `nearPlane` / `farPlane`, `clear` (`sky`, or `color`
  with `clearColor`) for what a capture shows where no mesh is drawn, `showTags` / `hideTags` (like a Camera's: hide what must not be
  reflected, for instance the entity of the player), `intensity` (a gain on the light the probe holds), `importance`, and `boxSize`,
  `boxOffset`, `blendDistance`, `boxProjection` (the region a probe lights and how reflections are corrected for it: stored now, used by
  M73-P3c). A probe is placed at its entity's position; the capture looks all around.
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
- **The atlas.** One 1024 x 1024 RGBA16F image (8 MB), made when the first probe appears and released with the last. It holds the
  sky too (entry 0, from the environment the renderer already bakes). A 128 probe takes 196 x 131 texels, so about 35 fit; when the
  atlas is full a probe takes the place of one with a strictly lower `importance`, and an equal one is never evicted (`noRoom` in
  the report). At most 256 probes are kept; the report's `overLimit` counts the active ones beyond them (the smallest `importance`
  goes first), which have no entry in `probes`.
- **What a capture holds.** Scene values before tone mapping and without post effects, like the sky. On a GPU that cannot render to half
  floats the atlas is RGBA8, a realtime probe is captured in the scene's own (gamma) space, and `probe.bake` answers `unavailable`
  (a baked page is HDR).
- **`render.probes`** lists the atlas (`size`, `format`, `tiles`, texels used and reserved), the sky's entry and each probe: `entity`
  (its scene id), `mode`, `state` (`ready`, `pending`, `capturing`, `noRoom`, `noBake`, `failed`), `tile`, `captures`,
  `lastFrame`, and for a realtime probe `facesDone`. It is `{"probes": [], "atlas": null}` while no probe exists.
