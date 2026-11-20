// The geometry a lightmap is baked onto and drawn with (M73.4a, docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "Lightmaps").
//
// A mesh's lightmap UVs are TEXCOORD_1 of its glTF when every part has it, else an unwrap of the whole mesh made by
// generate_lightmap_uv (fa/scene/lightmap_uv.h). The renderer draws a lightmapped entity with exactly the vertices this returns and the
// `lightmap.bake` command bakes onto them, so the bake and the draw cannot disagree. The result depends on the mesh file alone (no
// setting, no clock): the same on every platform and run. Nothing is written next to the model; the renderer keeps its copy in memory
// with the mesh.
//
// GPU-free: reads the model through fa::fs and builds CPU arrays. Takes seconds for a mesh of 100,000 triangles that has no TEXCOORD_1
// (the unwrap), so a caller that wants it often keeps the result.
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa::render {

struct LightmapMeshGeometry {
    // The drawn vertices of every part, one after the other (a generated unwrap splits vertices along the seams of its charts).
    std::vector<Vec3> positions;  // model space
    std::vector<Vec3> normals;
    std::vector<Vec2> uv;                  // the lightmap UV, inside [0, 1]^2, (0, 0) = top-left of the page
    std::vector<std::uint32_t> indices;    // three per triangle, into the arrays above
    std::vector<std::uint32_t> partFirstIndex;  // parts + 1 entries: part p owns indices [partFirstIndex[p], partFirstIndex[p + 1])
    std::string uvKind;                    // "gltf" (TEXCOORD_1 of the file) or "generated"
    std::uint64_t hash = 0;                // of the geometry, as lightmap_hash_hex(): the manifest's meshHash
    double surfaceArea = 0;                // m^2 of the triangles in model space (the bake picks its texel counts from it)
};

// Builds the geometry of a MeshRenderer.mesh value: a primitive name ("cube", "sphere", ...) or the project path of a .gltf/.glb.
// Fails, saying what to change, for a missing or unreadable file, a mesh without triangles, one with more triangles than the unwrap
// takes (fa::kLightmapUvMaxTriangles; give it a TEXCOORD_1 or a lower-poly mesh for the bake) or a procedural mesh (a script-made
// "mesh:N" cannot be lightmapped: it is not a file).
Result<LightmapMeshGeometry> lightmap_mesh_geometry(const std::string& mesh);

}  // namespace fa::render
