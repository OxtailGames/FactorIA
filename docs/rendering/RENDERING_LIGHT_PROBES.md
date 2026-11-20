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

`render.light_probes` answers what the renderer has: without arguments `{lightmaps, baked, probes, invalid, groups: [...]}`, with
`{"entity": "Player"}` also `source` (`probes`, `lightmap`, `sky` or `none`), `coverage`, `probesUsed`, the `sh` coefficients and the
`ambient` light that a surface facing up, down, east, west, north or south would get. `render.supports {"feature": "lightProbes"}` says
the GPU can draw them (every backend can).

In the editor the probes of a group are small spheres coloured by their baked light (grey before the first bake, or after the group was
edited), shown by **View > Lightmap > Show probes** and `LightProbeGroup.showGizmo` of each group.

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

## Not done yet

Probes are not updated at run time (a moving light or a destroyed wall does not change them: bake again), there is no occlusion of the
probe by geometry between the probe and the object (a probe on the other side of a thin wall still counts: put the grid where the object
is, or add points), and no reflection from a probe (reflections come from the sky and the reflection probes).
