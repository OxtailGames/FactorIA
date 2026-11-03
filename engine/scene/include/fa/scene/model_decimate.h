// Mesh simplification for the model kernel: one engine, meshoptimizer's edge-collapse simplifier (external/meshoptimizer, MIT), used by the
// SDF mesher (model_decimate), by the LODs of a game-ready model (model_simplify, model_game_ready.h) and by the collider hulls.
// Deterministic: serial, float arithmetic with + - * / and sqrt, ties broken by meshoptimizer's fixed order.
//
// What it preserves. Each triangle has a part (`triParts`); the triangles of a part are simplified on their own, and every vertex whose
// position is used by two parts is locked, so a part boundary stays exactly where it was and no crack opens between parts. Open borders are
// locked too (`lockBorder`, on by default for model_decimate). Attributes (normals, uvs, colours) are optional extra terms of the error:
// a collapse that would smear a seam or a colour edge costs more, and the vertices that stay keep their own attributes.
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
    double maxErrorReached = 0;  // the largest deviation from the input surface, metres
};

// Simplifies `indices` (three per triangle over `positions`) per part. `attributes` (optional) is `attributeStride` floats per vertex and
// `weights` one weight per float of it. The result has the vertices it uses (compacted, in order of first use) with the positions and
// attributes the simplifier moved them to; `keep` says which input vertex each one came from.
struct ModelSimplifyParams {
    std::size_t targetTriangles = 0;  // stop when this many are left (0: no target, only the error limit)
    double maxError = 0;              // metres; the most any collapse may displace the surface (0: no limit)
    bool lockBorder = false;          // open borders do not move
};
struct ModelSimplifyResult {
    std::vector<std::uint32_t> indices, triParts;
    std::vector<std::uint32_t> keep;  // result vertex -> input vertex
    std::vector<Vec3> positions;      // of the result vertices: moved to where the simplified surface follows the input best
    std::vector<float> attributes;    // the same for the attributes (a normal may need normalising again)
    double error = 0;                 // metres, the largest deviation of the result from the input surface (an upper bound after several passes)
    bool limitedByError = false;      // stopped at maxError before reaching the target
};
ModelSimplifyResult model_simplify(const std::vector<Vec3>& positions, const std::vector<float>& attributes, std::size_t attributeStride,
                                   const std::vector<float>& weights, const std::vector<std::uint32_t>& indices,
                                   const std::vector<std::uint32_t>& triParts, const ModelSimplifyParams& params);

// Collapses edges of the mesh in place (positions and indices are compacted at the end; `triParts` follows the triangles). `triParts` may be empty
// (one part). Open borders are kept.
ModelDecimateStats model_decimate(std::vector<Vec3>& positions, std::vector<std::uint32_t>& indices, std::vector<std::uint32_t>& triParts,
                                  const ModelDecimateParams& params);

}  // namespace fa
