[Back to the index](../README.md)

# Commands: render

## `mesh.create` (modifies state)

Since 0.9.0.

Create a procedural mesh from arrays and get its id for MeshRenderer.mesh.

Builds geometry at run time, without writing a file: `positions` (three numbers per vertex), `indices` (three per triangle; left out = a triangle soup), and optionally `normals`, `uvs`, `tangents`, `colors` and `submeshes` (runs of the index list with their own material). Missing normals and tangents are computed. Conventions are glTF's: +Y up, right-handed, counter-clockwise triangles face front, uv (0,0) is the top-left of the image. Everything is checked and an error names the field, the counts and the fix (array length, index outside the vertices, submesh outside the index list). Result: the info of mesh.info with `id` ("mesh:N"). Set MeshRenderer.mesh (and Collider3D.mesh for a convex or mesh collider) to that id; culling, shadows, picking and the editor's selection use the mesh's real bounds. The mesh belongs to the running scene: loading a scene releases every mesh, and it is not written to scene files (scene validation rejects an id in a file): use mesh.save for a file. At most 256 meshes, 1048576 vertices and 6291456 indices each. Vertex colors multiply the base color. Example: mesh.create {"positions":[0,0,0, 1,0,0, 0,1,0],"indices":[0,1,2],"submeshes":[{"material":{"name":"skin","color":[0.9,0.7,0.5,1]}}]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `positions` | any | yes | Vertex positions: a flat list [x, y, z, x, y, z, ...] or a list of [x, y, z]. Three numbers per vertex. |
| `indices` | any | no | Vertex numbers, three per triangle (flat, or a list of [a, b, c]). create: left out = every three vertices make a triangle. update: left out = kept. |
| `normals` | any | no | Three numbers per vertex, normalized for you. Left out = computed (smooth, weighted by triangle area). Never kept from an earlier call. |
| `uvs` | any | no | Two numbers per vertex ((0,0) is the top-left of the image). Left out = zeros (create) or kept (update). |
| `tangents` | any | no | Four (xyz + handedness +1/-1) or three numbers per vertex, for normal maps. Left out = computed from the uvs. |
| `colors` | any | no | Three (rgb) or four (rgba) numbers per vertex. Drawn like glTF COLOR_0: they multiply the material's base color (rgb and alpha; alpha shows with a material with blend: true and cuts holes with a custom material that has alphaMode clip) in every 3D draw path, clamped to 0..1 with 8 bits per channel, and are saved as COLOR_0 in a .glb. Left out = white (create) or kept (update). |
| `submeshes` | array | no | Runs of the index list with their own material: [{material, start?, count?}]. material is a name or {name, color, texture, metallic, roughness, emissive, doubleSided, blend}; start and count count indices (multiples of 3); start defaults to where the previous submesh ends, count to the end of the index list. Left out = one submesh over all indices (update: the existing ones are kept). |

## `mesh.destroy` (modifies state)

Since 0.9.0.

Free a procedural mesh.

Entities that still name the id draw the missing-mesh placeholder and the engine logs why once: set their `mesh` first. Errors for an unknown id with the live ids. Result: {destroyed: id}. Example: mesh.destroy {"id":"mesh:1"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | The mesh ("mesh:N"). |

## `mesh.info`

Since 0.9.0.

Describe one procedural mesh: counts, bounds, submeshes and materials.

Result: {id, version, vertices, triangles, hasColors, bounds: {min, max}, submeshes: [{material, start, count}]}. `version` grows with every mesh.update. Errors for an unknown or destroyed id with the live ids. Example: mesh.info {"id":"mesh:1"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | The mesh ("mesh:N"). |

## `mesh.list`

Since 0.9.0.

List the live procedural meshes of the running scene.

Result: {meshes: [info...], count}. Each info: {id, version, vertices, triangles, hasColors, bounds, submeshes}. Example: mesh.list {}

## `mesh.save` (modifies state)

Since 0.9.0.

Write a procedural mesh as a .glb file that loads back as a normal model.

One node, one primitive per submesh with its material (name, base color, metallic/roughness, emissive, double-sided, blend, base color texture by a relative uri), vertex colors as COLOR_0. `path` is project-relative and ends in .glb; it may not be inside .factoria/ (except .factoria/tmp/). A material whose texture is a run-time texture cannot be saved (the file would point to nothing): use a project image. A mesh with no metallic/roughness set is written with the defaults (0 and 0.6). Afterwards MeshRenderer.mesh = the path loads it like any model. Result: {saved: path, submeshes}. Example: mesh.save {"id":"mesh:1","path":"assets/models/tree.glb"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | The mesh ("mesh:N"). |
| `path` | string | yes | Project-relative file ending in .glb. |

## `mesh.update` (modifies state)

Since 0.9.0.

Replace the data of a procedural mesh; arrays left out are kept.

Takes the same arrays as mesh.create. `positions`, `uvs`, `colors`, `indices` and `submeshes` that are left out are kept; normals and tangents are computed again unless given. Changing the vertex count needs the other per-vertex arrays to fit it (errors say which); changing `indices` of a mesh with several submeshes needs `submeshes` too. Cheap enough to call every frame: the GPU buffers are reused while the new data fits. A Collider3D (convex or mesh) that uses the mesh rebuilds its shape on every update, which is costly for big meshes. Result: the info of mesh.info. Example: mesh.update {"id":"mesh:1","positions":[0,0,0, 2,0,0, 0,2,0]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `positions` | any | no | Vertex positions: a flat list [x, y, z, x, y, z, ...] or a list of [x, y, z]. Three numbers per vertex. |
| `indices` | any | no | Vertex numbers, three per triangle (flat, or a list of [a, b, c]). create: left out = every three vertices make a triangle. update: left out = kept. |
| `normals` | any | no | Three numbers per vertex, normalized for you. Left out = computed (smooth, weighted by triangle area). Never kept from an earlier call. |
| `uvs` | any | no | Two numbers per vertex ((0,0) is the top-left of the image). Left out = zeros (create) or kept (update). |
| `tangents` | any | no | Four (xyz + handedness +1/-1) or three numbers per vertex, for normal maps. Left out = computed from the uvs. |
| `colors` | any | no | Three (rgb) or four (rgba) numbers per vertex. Drawn like glTF COLOR_0: they multiply the material's base color (rgb and alpha; alpha shows with a material with blend: true and cuts holes with a custom material that has alphaMode clip) in every 3D draw path, clamped to 0..1 with 8 bits per channel, and are saved as COLOR_0 in a .glb. Left out = white (create) or kept (update). |
| `submeshes` | array | no | Runs of the index list with their own material: [{material, start?, count?}]. material is a name or {name, color, texture, metallic, roughness, emissive, doubleSided, blend}; start and count count indices (multiples of 3); start defaults to where the previous submesh ends, count to the end of the index list. Left out = one submesh over all indices (update: the existing ones are kept). |
| `id` | string | yes | The mesh to change ("mesh:N"). |

