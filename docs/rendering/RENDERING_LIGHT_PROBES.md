Part of [RENDERING.md](../RENDERING.md) and [Lighting](RENDERING_LIGHTING.md): the light probes that light moving objects with baked light, and what a light of each
mode does to each kind of receiver.

# Rendering: light probes and mixed lights (M73.4d)

A lightmap lights static meshes. A moving object (a character, a crate you push, a skinned mesh) has no lightmap, so before probes it
got only the scene's ambient light or the sky's diffuse light and looked flat next to the baked level around it. A **light probe** is a
point where the bake stored the light that reaches it from every direction (nine spherical-harmonics coefficients per colour channel,
"SH"). The renderer blends the probes around a moving object and uses that as its ambient and sky-diffuse light, so a sphere next to a red
wall gets red light on its red side.

## What you set

1. Add a `LightProbeGroup` component to an entity (an empty one is fine). By default it is a grid of probes: `size` metres (10 x 4 x 10),
   one probe every `spacing` metres (2), centred at the entity's position plus `offset`; `size` 0 on an axis makes one layer. `grid` off
   keeps only `points`, up to 256 single probes `[[x, y, z], ...]` in world metres; a point lights what is within 5 m of it. Put the grid
   where objects move, not around the whole level: a probe costs bake time and a file entry (at most 16384 per group and 65536 per
   scene; the bake names the field and what to change when you pass them).
2. Bake: `lightmap.bake` (or **View > Lightmap > Start**). The probes are baked by the same job as the pages, in their own phase
   `probes` (progress and Cancel work as for the pages), and written to `<name>.lightmap.<hash>.probes` next to them; the manifest lists
   the file in its `probes` key (`file`, `count`, `invalid`). A scene with a `LightProbeGroup` and no mesh to light is still a valid bake.
   The result, `lightmap.bake_status` and the Lightmap window say how many probes there are and how many are `invalid`.
3. Nothing else: the manifest is already `SceneSettings.lightmaps`. A scene without probes (no group, or never baked) is drawn bit for
   bit as before.

A probe whose rays mostly hit the **back** of a surface lies inside geometry (a wall, the floor): it is flagged `invalid`, drawn as a red
cross by the editor, and the objects around it ignore it and use the probes next to it. Move it out of the solid, or leave it.

## Who receives them

A mesh is lit by the probes when it has `receiveGI` on, is not `unlit` and has **no lightmap entry** (or its lightmap entry was refused:
`lightmapScale` 0, a stale mesh). A skinned mesh is included. A mesh whose material is a full shader or reads compute buffers is not (as
with lightmaps). The position the probes are read at is the centre of the mesh's bounds, or the position of `MeshRenderer.probeAnchor`
(an entity: use it for a long object, or one whose bounds centre sits in the floor). The result is the weighted mean of the valid probes
around that point (trilinear in a grid, a smooth falloff outside the box over one `spacing`, then back to the sky's ambient light). The
blend with the sky is `coverage`: 1 inside the probes, 0 where none reaches.

`render.light_probes` answers what the renderer has: without arguments `{lightmaps, baked, probes, invalid, groups: [...], unbaked: [...]}`
(a group is `stale` when its component was edited after the bake, `unbaked` lists the scene's groups the file does not hold: bake again), with
`{"entity": "Player"}` also `source` (`probes`, `lightmap`, `sky` or `none`), `coverage`, `probesUsed`, the `sh` coefficients and the
`ambient` light that a surface facing up, down, east, west, north or south would get. `render.supports {"feature": "lightProbes"}` says
the GPU can draw them (every backend can).

In the editor the probes of a group are small spheres coloured by their baked light (grey before the first bake, or after the group was
edited), shown by **View > Show light probes** (the Lightmap window's **Show probes** is the same switch) and `LightProbeGroup.showGizmo` of each
group. Probes behind the camera are not drawn and at most 2048 are drawn in all, so a big grid thins out; the Lightmap window says how many groups
changed since the bake.

## Light mode against receiver

`Light.mode` says where a light's contribution lives; the receiver says what it can read. This is the whole table:

| Receiver | `baked` light | `mixed` light | `realtime` light |
|---|---|---|---|
| Lightmapped mesh | not lit at run time: its direct light and bounce are in the page | lit at run time (direct light, shadows, highlights); only its bounce is in the page | lit at run time |
| Moving mesh inside the probes | not lit at run time: its direct light and bounce are in the probes, scaled by `1 - coverage` for the fraction not covered | lit at run time; only its bounce is in the probes | lit at run time |
| Mesh that nothing baked covers | lit at run time, as a realtime light (nothing goes dark before the bake) | lit at run time | lit at run time |
| `receiveGI` off | lit at run time | lit at run time | lit at run time |

Two consequences. A `baked` sun lights a character exactly as long as it has probes under it, and its shadow moves with the geometry
only in the bake: a character in a baked level has the *colour* of the baked light but no shadow cast by the baked sun. Use a `mixed` light
for the lights a moving object should cast and receive shadows from: the direct light stays realtime, only the bounce is baked.


## Cost

The probes are read on the CPU once per mesh and frame in the culling job (a few dozen float operations); on the GPU the nine coefficients are
uniforms of the mesh pass, so no texture unit and no extra pass. The probes are read at the sample point rounded to a 0.25 m lattice, so
meshes within that distance of each other get the same light and are drawn in one instanced draw (equal light to 1/1024 batches too);
meshes with different light are separate draws, so objects spread over a big grid with a strong gradient cost more draws than a
cluster. Shadow draws ignore the probe light and batch as without probes. `probeAnchor` on a group of objects lets them share one
value. A disabled or missing anchor entity counts as none.

## Realtime global illumination

A baked probe never changes. A **`RealtimeGI`** component is the live version, without ray tracing: a grid of probes over a box that the
renderer captures again while the game runs, a few probes a frame, so a moving light or a door that opens changes the light of a room within
a second or two. The idea is the one of the DDGI grids of other engines: each probe keeps the diffuse light that reaches it and how far the walls
around it are (so light does not leak through them), and a capture is blended into the old value so the light does not flicker.

**What the meshes read.** Every lit mesh whose point lies inside the probes of a ready grid gets its diffuse ambient light from the eight probes
around it: the light each one keeps, weighted by how near it is, by whether the probe faces the surface and by a visibility test against the walls
between (so a thin wall keeps the light of a room from leaking through it). The order of the diffuse light is: the lightmap texel; the baked light probes over the share
they cover (the rest of that pixel is the reflection probes' light and the sky or `ambientLight`, never the grid); else the `RealtimeGI` grid; else the reflection probes' light and the sky or `ambientLight`. A grid fades out over half a spacing outside its
probes (a floor lying on the face of the box gets no light from it: let the box reach beyond the surfaces to light), and a grid that is not ready
(it says `updating` in `render.gi_grid`, until every probe has been captured once) changes nothing: the frame is the one of a scene without it.
`intensity` multiplies what the meshes take from the grid. The reflections stay the sky's and the reflection probes'. Because a capture draws the scene with
the lighting the meshes have, the next capture of a probe sees the grid's earlier light, times `bounce`: that is the extra bounces, one more each time
the probes are refreshed (`bounce` 0 makes the captures of the grid's probes ignore the grid; the camera and the captures of a ReflectionProbe always see it at full strength). Light from an emissive mesh
or a light that moves reaches the walls in the time a cycle of the probes takes.

1. Add a `RealtimeGI` component to an entity. `size` is the box (default 20 x 6 x 20 m, centred on the entity plus `offset`; 0 on an axis is one layer),
   `spacing` the distance between two probes (2 m: the default box has 11 x 4 x 11 = 484 probes; halving the spacing makes eight times as many).
   All grids of a scene together may have 1224 probes and a scene keeps 8 grids: a bigger one is listed with state `noRoom` and what to change.
2. `probesPerFrame` (default 2, at most 32 over all grids) is the cost: each probe draws the scene six times at `resolution` x `resolution` texels
   (16 or 32). The probes are refreshed in a fixed order, the ones never captured first and then the one captured longest ago, so the same scene
   gives the same result on every run; a grid of n probes at b a frame is refreshed every ceil(n / b) frames.
3. `hysteresis` (default 0.9) is the share of the old value a new capture keeps: more is calmer and slower to follow a change.
   The atlas holds half floats, so a blend of 1 % (0.99) cannot move a value it is within about 2 % of: it settles that close to a steady target, not on it.
   `nearExclusion` and `maxDistance` are the near and far planes of the captures; `showTags` and `hideTags` leave things out of them (the
   player, particles) as on a Camera.
4. Look at it with `factoria call render.gi_grid`: per grid the probe count, `captured` and `progress` (how many probes have a first capture),
   `cycles`, the memory (`bytes` of the grid, and the atlas's), the last frames' captures and the probes that lie **inside geometry**
   (`invalidProbes`, with their positions: a probe whose rays mostly hit the back of a surface is invalid, and the shading will ignore it, as with
   baked probes; move the grid or the spacing). `meshesRead` says whether the lit meshes read the grid (it is `ready`). A wrong component (a field out of its range, too many probes) has state `invalid` with the field and
   the fix in `message`.

Cost: a scene without a `RealtimeGI` pays nothing (no pass, no image, the same bytes). With one, the probe atlas grows by 132 rows (about 1 MB) and each
captured probe adds six tiny passes of the scene plus a few filtering passes; nothing is read back from the GPU while the game runs (only
`render.gi_grid` reads the markers of the probes). The GPU must be able to blend into RGBA16F images;
where it cannot (the RGBA8 fallback of the probe atlas) the grid says `unsupported` and nothing is captured. The distances come from the depth prepass
of the opaque meshes: transparent surfaces and particles show in the light of a capture but not in its distances.

**With rays (M79).** Turn on ray tracing (`render.rayTracing.enabled`) and set `render.rayTracing.gi` to `"probes"` (docs/RAY_TRACING.md, "Global
illumination") on a GPU that traces rays, and the probes are updated by a compute shader that casts `raysPerProbe` rays (16 to 256, default 64) instead of
the six captures: `rtProbesPerFrame` (1 to 64, default 16; 64 over all grids together) is then the cost, `hysteresis`, `bounce`, `intensity`,
`maxDistance`, `backfaceTolerance` and `nearExclusion` (where the rays start) mean the same, an emissive surface lights the room without a capture,
and `resolution`, `probesPerFrame`, `showTags` and `hideTags` are not used by the rays (they see the traced scene of ray tracing). `render.gi_grid`
says `updatedBy: "rays"`. Without a device that traces, the captures above keep working.

## Not done yet

Baked probes are not updated at run time (a moving light or a destroyed wall does not change them: bake again, or use a `RealtimeGI` grid), there is no occlusion of the
probe by geometry between the probe and the object (a probe on the other side of a thin wall still counts: put the grid where the object
is, or add points; a `RealtimeGI` grid does test it), and no reflection from a realtime grid (reflections come from the sky and the reflection probes).
