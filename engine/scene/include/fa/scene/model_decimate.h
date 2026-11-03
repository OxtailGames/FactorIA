// Mesh decimation for the model kernel: edge collapses ordered by the quadric error metric (Garland and Heckbert), on a closed or open
// triangle mesh whose vertices are WELDED (one vertex per position). Deterministic: ties are broken by vertex index, everything is double
// arithmetic with + - * / and sqrt.
//
// What it preserves. Each triangle has a part (`triParts`); an edge between triangles of different parts is a part boundary, and decimation
// keeps the boundary where it is: a vertex on a boundary only moves along the boundary (it never merges into the inside of a part), the
// boundary edges carry an extra quadric that stops them drifting, and a collapse that would cut across a part is refused. A collapse is also
// refused when it would flip a triangle, make the mesh non-manifold (the link condition) or collapse a tetrahedron into nothing, so a closed
// manifold mesh stays a closed manifold mesh. Open borders are kept the same way as part boundaries.
//
// Reused by LOD generation later (M58.3): the mesh form is plain vectors.
#pragma once

#include <cstddef>
#include <cstdint>
#include <vector>

#include "fa/core/math.h"

namespace fa {

struct ModelDecimateParams {
    std::size_t targetTriangles = 0;  // stop when this many are left (0: no target)
    double maxError = 0;              // stop when the cheapest collapse has more error than this, metres (0: no limit)
};

struct ModelDecimateStats {
    std::size_t trianglesBefore = 0, trianglesAfter = 0;
    std::size_t collapses = 0;
    double maxErrorReached = 0;  // the largest error of a collapse made, metres: root of the mean squared distance to the planes of the triangles around it
};

// Collapses edges of the mesh in place (positions and indices are compacted at the end; `triParts` follows the triangles). `triParts` may be empty
// (one part). The error of a collapse is sqrt(quadric / area weight): the root mean square distance of the new vertex from the planes of the
// original triangles it replaces, area weighted.
ModelDecimateStats model_decimate(std::vector<Vec3>& positions, std::vector<std::uint32_t>& indices, std::vector<std::uint32_t>& triParts,
                                  const ModelDecimateParams& params);

}  // namespace fa
