# Big worlds

Levels of detail, occlusion, streamed cells, a floating origin, terrain and foliage: what a game needs when its world is
kilometres wide. **Milestone M75 builds this in parts, and none of it draws or simulates anything yet.** Every part below is marked
"(planned, M75.n)". What exists today is the data and the names: the components and fields (they save, load and validate, and
do nothing yet), the project setting `world.floatingOrigin`, the counters in `renderStats`, the `render.supports` rows and the
commands, which fail with the error `not_built` (planned for a coming version) and name the package that fills them in. A game that adds them today loses nothing:
when a package lands, the scenes already written start to work. Nothing here changes a game that does not use it: every default
is "off" or "as before".

| Part | Package | What it adds |
|---|---|---|
| [Levels of detail](#levels-of-detail-planned-m751) | M75.1 | screen-size thresholds, dithered cross-fade, impostors, HLOD |
| [Occlusion](#occlusion-planned-m752) | M75.2 | occluders (CPU, then GPU), areas and portals |
| [Streaming](#streaming-planned-m753) | M75.3 | cells loaded and unloaded around `StreamingAnchor`s |
| [Floating origin](#floating-origin-planned-m754) | M75.4 | positions stay exact far from the origin |
| [Terrain](#terrain-planned-m755) | M75.5 | heightmap terrain with splat layers, holes, collision |
| [Foliage](#foliage-planned-m756) | M75.6 | instanced vegetation and rocks, scatter rules |

`renderer.supports` (the `render.supports` command) already lists a row per renderer feature, all `false` with the status
"planned (M75)" until its package lands: `lodCrossFade`, `impostors`, `occlusionCpu`, `occlusionGpu`, `terrain`, `foliage`. Ask
it before relying on one, as for every other feature (docs/RENDERING.md).

## Levels of detail (planned, M75.1)

`MeshRenderer.lods` already switches meshes by distance. M75.1 adds:

- `MeshRenderer.lodMode`: `"distance"` (default, the behaviour of every scene made before M75) or `"screenSize"`. With
  `screenSize`, an entry of `lods` is `{"mesh": "models/rock_lod1.glb", "screenSize": 0.25}`: the mesh replaces the one before it
  when the screen size drops below 0.25. Entries go from the largest `screenSize` to the smallest. The entries are saved and checked today: a
  `screenSize` that is not a number from 0 to 1 is an error, and an entry without the key of its mode, or whose `screenSize` is
  not below the one before it, is a warning, each with the JSON pointer of the entry.
- The screen size, for `MeshRenderer` and `LodGroup` alike, is the diameter of the world-space bounding sphere (of the mesh; of
  the whole subtree of a `LodGroup`) divided by the visible height at the entity's distance `d`: `2 * d * tan(fovY / 2)` in
  perspective, `2 * orthoSize` in orthographic. 1 = the sphere is as tall as the screen, 0.1 = a tenth of it. It is a fraction, so a
  threshold means the same at every resolution; it does change with the field of view, the zoom and the size of the object (a
  wider lens or a smaller object gives a smaller screen size), so tune thresholds with the camera the game uses.
- `MeshRenderer.lodCrossFade`: seconds a switch fades over (a dithered cross-fade, no popping). 0 = hard switch.
- `MeshRenderer.impostor` and `impostorDistance`: a baked ring of pictures that a camera-facing quad shows beyond the last LOD.
  `impostorDistance` is in the unit of `lodMode`. `impostor` empty means none.
- The `LodGroup` component on an entity whose children are the levels (child 0 the most detailed): `mode`, `thresholds` (one
  number per child but the first, at most 8, in the unit of `mode`, ordered), `crossFade`, and an HLOD proxy for a whole cell:
  `hlodProxy` (a mesh path) with `hlodThreshold` (needed when the proxy is set).
- `model.generate_lods {model, levels, ratios, maxError, apply}` simplifies a model into lower levels (deterministic) and writes
  them; `model.bake_impostor {model, views, resolution, apply}` bakes the impostor atlas. Both fail with `not_built` today.
- `renderStats` gets `lodCrossFades` and `impostors` (this frame's counts).

## Occlusion (planned, M75.2)

Meshes hidden behind big solid ones are not drawn.

- `Occluder` on an entity: `shape` (`"box"` or `"mesh"`), `size` and `center` (metres, a box), `mesh` (the mesh to rasterise;
  empty = the entity's `MeshRenderer.mesh`), `enabled`. A `shape` `"mesh"` with no mesh and no `MeshRenderer` is an error.
- `OcclusionArea` (a room): `size` in metres, `areaId` 1..65535 (0 is "outside every area"). `OcclusionPortal` (a door or window
  between two areas): `size`, `areaA`, `areaB` (the ids on its -Z and +Z side), `open` (a shut door blocks sight). Meshes in an
  area are drawn only when a chain of open portals leads from the camera's area to it.
- The CPU path rasterises the occluders at low resolution on the job system (`renderer.supports` `occlusionCpu`); the GPU path
  tests against a hierarchical depth buffer and needs compute shaders (`occlusionGpu`, not on GLES3 or WebGL2).
- `renderStats` gets `occluders`, `occlusionTests` and `meshesOccluded`.

## Streaming (planned, M75.3)

A world is an index file (`<name>.world.json`: the cell size, and for each cell its bounds and its scene file) plus one scene file
per cell. Cells load additively on the IO thread and apply on the main thread within the frame's budget; unloading destroys the
cell's root.

- `StreamingAnchor` on an entity (usually the player or the camera): `loadRadius` (metres: cells nearer than this load),
  `unloadRadius` (cells farther than this unload; it must be above `loadRadius`, the gap is the hysteresis that stops a cell from
  loading and unloading every frame), `priority` (the anchor with the higher one gets its cells first), `enabled`. The radii are
  measured on the plane of the streamed world: x and z for a world index whose dimension is `"3d"`, x and y for `"2d"`. Distances use
  absolute positions (the floating origin plus the local position), so a rebase of the origin never changes what is loaded.
- `world.split_cells {scene, cellSize, output, dryRun}` cuts a scene into a grid of cells and writes the files and the index;
  `world.merge_cells {manifest, output, dryRun}` joins them back so a level can be edited as one file. They write project files and
  fail with `not_built` today.
- `world.cells {state}` lists the cells and whether each is loaded; `world.stream_status {}` says what streaming is doing (loads
  in flight, cells loaded, pending cells, the last error), so a test can wait until the cells around the player are in. Both are
  read-only and fail with `not_built` today. A script that waits for them checks that its scene is still the current one first.
- Tests count units of work, not milliseconds, so a result does not depend on the speed of the machine.

## Floating origin (planned, M75.4)

`Transform` stays a float, which has a precision of about a millimetre at 8 km and a hand's width at 100 km. Far from the origin
things shake. The floating origin keeps what is near the camera near (0, 0, 0): the world holds a double-precision origin (`DVec3`
in `fa/core/math.h`), and when the anchor goes past a threshold the engine moves everything by a whole number of steps, on the
fixed tick (so it is deterministic): root positions, physics bodies, particles, audio sources, navigation data, the camera history
that motion vectors use. Scripts get an `originShifted` event with the offset. Saves and `world.absolute_position` add the origin and
the local position in double.

Off by default; a game opts in in `factoria.json`:

```json
"world": { "floatingOrigin": { "enabled": true, "threshold": 2048, "step": 256, "anchor": "camera" } }
```

| Key | Default | Meaning |
|---|---|---|
| `enabled` | `false` | turn the floating origin on |
| `threshold` | `2048` | metres from the origin at which the anchor causes a shift (16 to 10 000 000) |
| `step` | `256` | the origin moves by whole multiples of this, so repeated shifts stay exact: an integer power of two from 1 to 1 048 576 (2^20), so every shift is an exact float operation. Left out, it is the largest power of two at most `min(256, threshold)`, so `{"threshold": 128}` alone is valid (step 128). When you write it, it must not be above `threshold` |
| `anchor` | `"camera"` | `"camera"` (the active 3D camera) or `"entity:<id>"` (the entity with that id) |

The setting is read and checked today and changes nothing: a wrong key, number or anchor is an error that names the JSON pointer
(`/world/floatingOrigin/step`) and the fix. `"enabled": false` with the other keys at their defaults is not written back.

`world.origin {}` reads the origin; it always returns one shape, `{enabled, origin, rebases, threshold, step, anchor}` (with the
floating origin off: `enabled` false, `origin` `[0, 0, 0]`, `rebases` 0). `world.rebase {offset | entity}` moves it on demand
(tests, cutscenes). `world.absolute_position {entity}` returns `{entity, position, origin, local}`: `position` is the origin plus the
entity's world position, in doubles. All three fail with `not_built` today.

## Terrain (planned, M75.5)

The `Terrain` component draws a heightmap with a GPU level of detail (a quadtree of one grid mesh, read by vertex texture fetch, so
it also works on GLES3 and WebGL2) and splat-mapped material layers, with an automatic collider. In a scene and in scripts it is
called `Terrain` (the C++ type is `Terrain3D`: `Terrain` is already the 2D autotile type).

| Field | Meaning |
|---|---|
| `heightmap` | 16-bit greyscale PNG or `.r16` file (raw little-endian 16-bit, square: its side is `sqrt(bytes / 2)` samples, so 1025 x 1025 is 2 101 250 bytes); empty = flat at `heightOffset` |
| `size` | metres `[x, z]` the terrain covers, centred on the entity, each above 0 and at most 100 000. The heightmap is stretched over it: a 1025-sample map over 2048 m has a sample every 2 m, and resolution and `size` are independent |
| `heightScale`, `heightOffset` | metres of height of a white sample, and metres added after it |
| `splatMaps` | up to 2 RGBA PNG paths; channel c of map m weights `layers[4 * m + c]` |
| `layers` | up to 8 of `{albedo, normal, tileSize, roughness, metallic, normalScale}`. All the albedo textures share one size and format, and so do all the normal textures: the layers become texture arrays, because 8 layers of separate textures would need more than the 16 sampler pairs a shader stage can read |
| `holes` | greyscale PNG; a pixel of 128 or more cuts a hole (caves, wells) |
| `lodQuality`, `castShadows`, `collision` | mesh density multiplier, shadows, and the automatic `Heightfield3D` collider |

`terrain.create`, `terrain.sculpt`, `terrain.paint`, `terrain.holes` and `terrain.generate` (seeded noise and erosion, the same
arguments always give the same file) write the heightmap, splat and hole files. They fail with `not_built` today.
`renderStats` gets `terrainTiles` and `terrainTriangles`.

## Foliage (planned, M75.6)

`Foliage` draws many copies of a few meshes read from a data file, as GPU instances in chunks that are culled and faded by
distance, with wind. Its fields: `meshes` (an array of 1 to 16 primitive names or asset paths; the instances file stores a mesh
index into it for every instance, and its binary format is defined by the foliage package, M75.6 P6a), `instances` (the data file
that `foliage.paint` and `foliage.scatter` write; empty = none), `density` (0..1, the share drawn), `windStrength` (metres) and `windFrequency` (swings per
second), `lodDistance`, `fadeStart` and `fadeEnd` (metres; `fadeEnd` above `fadeStart`) and `castShadows`.

`ScatterRule` holds the recipe `foliage.scatter` fills the file from: `meshes` (up to 16 of `{mesh, weight}`), `density` (per square
metre), `minSpacing`, `slopeRange` (degrees), `heightRange` and `scaleRange`, `alignToNormal` (0..1), `layerMask` (bit mask of the
terrain layers it grows on, -1 = any), `seed` (the same rule and seed give the same instances) and `terrain` (the entity with the
`Terrain`; empty = this entity or its parent). `foliage.scatter` writes into ONE `Foliage` entity: it sets its `meshes` to all the
meshes of the rule and fills the instances file with their indices. `foliage.paint`, `foliage.scatter` and `foliage.clear` fail with
`not_built` today.
`renderStats` gets `foliageInstances` and `foliageInstancesCulled`.

## The errors a scene gets today

The loader checks these components when it loads a scene, and `factoria validate` prints the same text: the file, the JSON pointer,
what is wrong and how to fix it, with a "did you mean" for a misspelt name. A contradiction between fields (an `unloadRadius` that
is not above `loadRadius`, a `fadeEnd` that is not above `fadeStart`, an `hlodProxy` without `hlodThreshold`, more layers than
the splat maps weight) is reported before anything is built from it. A setting that does nothing (an `impostorDistance` with no
`impostor`) is a warning.

## Commands

| Command | Package | Writes files |
|---|---|---|
| `world.origin`, `world.rebase`, `world.absolute_position` | M75.4 | no |
| `world.cells`, `world.stream_status` | M75.3 | no |
| `world.split_cells`, `world.merge_cells` | M75.3 | yes |
| `model.generate_lods`, `model.bake_impostor` | M75.1 | yes |
| `terrain.create`, `terrain.sculpt`, `terrain.paint`, `terrain.holes`, `terrain.generate` | M75.5 | yes |
| `foliage.scatter`, `foliage.paint`, `foliage.clear` | M75.6 | yes |

`factoria commands <name>` and `docs.commands {name}` print the arguments of each.
