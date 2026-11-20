// The second UV set of a lightmapped mesh (M73.4a, docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "Lightmaps"): every triangle gets its own
// place in the unit square, no two triangles overlap, and the charts keep a gutter around them for the baker's dilation. A mesh whose glTF has
// TEXCOORD_1 keeps it (the caller checks); every other mesh (the primitives, a glTF without it) is unwrapped here with xatlas through
// model_uv_apply, so the result is the same on every platform and run: it depends on the triangles and on nothing else (no setting, no seed).
//
// GPU-free. The renderer draws with the split vertices this returns and the baker (the `lightmap.bake` command) bakes onto the same ones: both
// call the same function, so they cannot disagree.
//
// Orientation: like every UV of the engine, uv (0, 0) is the TOP-LEFT of the image and v grows downwards. The baker's atlas stores v = 0 in
// its row 0 and the Radiance .hdr of a page stores its first row first, so a texel is found at the same place in the file, the bake and the
// shader (the "lightmap page orientation" test in engine/scene/tests pins it).
#pragma once

#include <cstdint>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

// Bumped when the unwrap changes what it returns for the same triangles (a new xatlas, other settings): the manifest of a bake stores it, so
// a bake made with another version is reported as stale instead of drawing wrong light.
inline constexpr int kLightmapUvVersion = 1;
// The most triangles one mesh may have to be unwrapped (the unwrap takes seconds beyond it).
inline constexpr std::size_t kLightmapUvMaxTriangles = 250000;
// The texture the charts are packed for (fixed: the density of a bake is chosen by the page rectangle the entity gets, not by the UVs).
inline constexpr int kLightmapUvReferenceSize = 128;
inline constexpr int kLightmapUvPadding = 4;  // empty texels of that texture around each chart

struct LightmapUvResult {
    std::vector<Vec2> uv;                // one per output vertex, inside [0, 1]^2
    std::vector<std::uint32_t> source;   // for each output vertex, the input vertex it was split from (copy position, normal, uv... from it)
    std::vector<std::uint32_t> indices;  // three per triangle, the same triangles in the same order as the input, indexing the output vertices
    double surfaceArea = 0;              // m^2 of the input triangles (a caller picks the texel density from it)
    double utilization = 0;              // share of the square the charts cover, 0..1
};

// Unwraps the triangles. `normals` may be empty (flat normals are made). Fails (with what to change) on an empty mesh, indices out of range,
// non-finite positions, more than kLightmapUvMaxTriangles triangles, or a mesh the packer cannot place.
Result<LightmapUvResult> generate_lightmap_uv(const std::vector<Vec3>& positions, const std::vector<Vec3>& normals,
                                              const std::vector<std::uint32_t>& indices);

}  // namespace fa
