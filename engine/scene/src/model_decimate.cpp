// Mesh simplification on top of meshoptimizer (model_decimate.h).
#include "fa/scene/model_decimate.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <map>

#include "meshoptimizer.h"

namespace fa {

namespace {

struct PosKey {
    std::uint32_t x, y, z;
    bool operator<(const PosKey& o) const { return x != o.x ? x < o.x : y != o.y ? y < o.y : z < o.z; }
};
PosKey key_of(const Vec3& p) {
    PosKey k;
    const float v[3] = {p.x + 0.0f, p.y + 0.0f, p.z + 0.0f};  // -0 and +0 are one position
    std::memcpy(&k.x, &v[0], 4);
    std::memcpy(&k.y, &v[1], 4);
    std::memcpy(&k.z, &v[2], 4);
    return k;
}

// Edges used by more than two triangles, counting by position (a seam between parts is one edge).
std::size_t non_manifold_edges(const std::vector<Vec3>& positions, const std::vector<std::uint32_t>& indices) {
    std::map<std::pair<PosKey, PosKey>, std::uint32_t> uses;
    for (std::size_t i = 0; i + 2 < indices.size(); i += 3)
        for (int k = 0; k < 3; ++k) {
            PosKey a = key_of(positions[indices[i + std::size_t(k)]]),
                   b = key_of(positions[indices[i + std::size_t((k + 1) % 3)]]);
            if (b < a) std::swap(a, b);
            ++uses[{a, b}];
        }
    std::size_t bad = 0;
    for (const auto& [edge, n] : uses) bad += n > 2 ? 1 : 0;
    return bad;
}

ModelSimplifyResult simplify_once(const std::vector<Vec3>& positions, const std::vector<float>& attributes,
                                  std::size_t attributeStride, const std::vector<float>& weights,
                                  const std::vector<std::uint32_t>& indicesIn,
                                  const std::vector<std::uint32_t>& triPartsIn, const ModelSimplifyParams& params,
                                  bool lockSeams) {
    ModelSimplifyResult out;
    const std::size_t triCount = indicesIn.size() / 3;
    std::vector<std::uint32_t> parts = triPartsIn;
    if (parts.size() != triCount) parts.assign(triCount, 0);
    const bool haveAttr = attributeStride > 0 && attributes.size() >= positions.size() * attributeStride &&
                          weights.size() >= attributeStride;

    // Every part gets its own copy of each vertex it uses. Copies at one position are a seam to meshoptimizer: it collapses along the seam
    // moving all copies together, so a part boundary may shorten along itself but never opens a crack, and a collapse never joins two parts.
    std::vector<std::uint32_t> keep;  // copy -> input vertex
    std::vector<std::uint32_t> copyPart;
    std::vector<std::uint32_t> idx(indicesIn.size());
    {
        std::map<std::pair<std::uint32_t, std::uint32_t>, std::uint32_t> copies;
        for (std::size_t i = 0; i < indicesIn.size(); ++i) {
            const std::uint32_t part = parts[i / 3];
            auto [it, fresh] = copies.emplace(std::make_pair(indicesIn[i], part), std::uint32_t(keep.size()));
            if (fresh) {
                keep.push_back(indicesIn[i]);
                copyPart.push_back(part);
            }
            idx[i] = it->second;
        }
    }
    const std::size_t vcount = keep.size();
    std::vector<float> flat(vcount * 3);
    std::vector<float> attr;
    if (haveAttr) attr.resize(vcount * attributeStride);
    for (std::size_t i = 0; i < vcount; ++i) {
        const Vec3& p = positions[keep[i]];
        flat[i * 3] = p.x;
        flat[i * 3 + 1] = p.y;
        flat[i * 3 + 2] = p.z;
        if (haveAttr)
            std::copy(attributes.begin() + std::ptrdiff_t(keep[i] * attributeStride),
                      attributes.begin() + std::ptrdiff_t((keep[i] + 1) * attributeStride),
                      attr.begin() + std::ptrdiff_t(i * attributeStride));
    }

    // lockSeams: a vertex whose position is used by two parts does not move, so a part boundary stays exactly as it was
    std::vector<unsigned char> locked;
    if (lockSeams) {
        std::map<PosKey, std::uint32_t> firstPart;
        std::map<PosKey, bool> shared;
        for (std::size_t i = 0; i < vcount; ++i) {
            const PosKey k = key_of({flat[i * 3], flat[i * 3 + 1], flat[i * 3 + 2]});
            auto [it, fresh] = firstPart.emplace(k, copyPart[i]);
            if (!fresh && it->second != copyPart[i]) shared[k] = true;
        }
        locked.assign(vcount, 0);
        for (std::size_t i = 0; i < vcount; ++i)
            if (shared.count(key_of({flat[i * 3], flat[i * 3 + 1], flat[i * 3 + 2]}))) locked[i] = 1;
    }

    unsigned int options = meshopt_SimplifyErrorAbsolute;
    if (params.lockBorder) options |= meshopt_SimplifyLockBorder;
    const float maxError = params.maxError > 0 ? float(params.maxError) : 1e30f;
    const std::size_t targetIdx = params.targetTriangles > 0 ? params.targetTriangles * 3 : 0;
    float err = 0;
    const std::size_t n = meshopt_simplifyWithUpdate(
        idx.data(), idx.size(), flat.data(), vcount, 12, haveAttr ? attr.data() : nullptr,
        attributeStride * sizeof(float), haveAttr ? weights.data() : nullptr, haveAttr ? attributeStride : 0,
        lockSeams ? locked.data() : nullptr, targetIdx, maxError, options, &err);
    idx.resize(n);
    out.error = err;
    out.limitedByError = params.targetTriangles > 0 && n / 3 > params.targetTriangles && params.maxError > 0;

    // Compact: parts in increasing id (triangles in input order inside a part), vertices in order of first use.
    std::vector<std::uint32_t> order(n / 3);
    for (std::size_t t = 0; t < order.size(); ++t) order[t] = std::uint32_t(t);
    std::stable_sort(order.begin(), order.end(),
                     [&](std::uint32_t x, std::uint32_t y) { return copyPart[idx[x * 3]] < copyPart[idx[y * 3]]; });
    std::vector<std::uint32_t> remap(vcount, 0xFFFFFFFFu);
    for (std::uint32_t t : order) {
        for (int k = 0; k < 3; ++k) {
            const std::uint32_t v = idx[t * 3 + std::uint32_t(k)];
            if (remap[v] == 0xFFFFFFFFu) {
                remap[v] = std::uint32_t(out.keep.size());
                out.keep.push_back(keep[v]);
                out.positions.push_back({flat[v * 3], flat[v * 3 + 1], flat[v * 3 + 2]});
                if (haveAttr)
                    out.attributes.insert(out.attributes.end(), attr.begin() + std::ptrdiff_t(v * attributeStride),
                                          attr.begin() + std::ptrdiff_t((v + 1) * attributeStride));
            }
            out.indices.push_back(remap[v]);
        }
        out.triParts.push_back(copyPart[idx[t * 3]]);
    }
    return out;
}

}  // namespace

ModelSimplifyResult model_simplify(const std::vector<Vec3>& positions, const std::vector<float>& attributes,
                                   std::size_t attributeStride, const std::vector<float>& weights,
                                   const std::vector<std::uint32_t>& indices,
                                   const std::vector<std::uint32_t>& triParts, const ModelSimplifyParams& params) {
    ModelSimplifyResult out =
        simplify_once(positions, attributes, attributeStride, weights, indices, triParts, params, false);
    // Where several parts meet, meshoptimizer can leave an edge shared by three triangles. A mesh that had none must not get one: try again
    // with the part boundaries locked, and keep the input when even that is not clean.
    const std::size_t before = non_manifold_edges(positions, indices);
    if (non_manifold_edges(out.positions, out.indices) <= before) return out;
    out = simplify_once(positions, attributes, attributeStride, weights, indices, triParts, params, true);
    if (non_manifold_edges(out.positions, out.indices) <= before) return out;
    const std::size_t triangles = indices.size() / 3;
    ModelSimplifyResult same;
    same.indices = indices;
    same.triParts = triParts.size() == triangles ? triParts : std::vector<std::uint32_t>(triangles, 0);
    same.positions = positions;
    same.attributes = attributes;
    same.keep.resize(positions.size());
    for (std::size_t i = 0; i < positions.size(); ++i) same.keep[i] = std::uint32_t(i);
    return same;
}

ModelDecimateStats model_decimate(std::vector<Vec3>& positions, std::vector<std::uint32_t>& indices,
                                  std::vector<std::uint32_t>& triParts, const ModelDecimateParams& params) {
    ModelDecimateStats stats;
    stats.trianglesBefore = indices.size() / 3;
    ModelSimplifyParams sp;
    sp.targetTriangles = params.targetTriangles;
    sp.maxError = params.maxError;
    sp.lockBorder = true;
    const bool hadParts = triParts.size() == stats.trianglesBefore;
    ModelSimplifyResult r = model_simplify(positions, {}, 0, {}, indices, triParts, sp);
    positions = std::move(r.positions);
    indices = std::move(r.indices);
    if (hadParts) triParts = std::move(r.triParts);
    stats.trianglesAfter = indices.size() / 3;
    stats.collapses = stats.trianglesBefore - stats.trianglesAfter;
    stats.maxErrorReached = r.error;
    return stats;
}

}  // namespace fa
