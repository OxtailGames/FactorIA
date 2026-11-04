// The xatlas side of the UV maker. Two steps, so charts made by an unwrap and charts made by a projection share one texture:
//   1. unwrap_parts: xatlas cuts a part into charts and flattens them (AddMesh + ComputeCharts + PackCharts into an unbounded atlas, only to read
//      the charts back); the charts leave in metres of surface, upright and not mirrored.
//   2. pack_atlas: every chart of every part, whatever made it, goes into ONE xatlas packing (AddUvMesh, one mesh per chart) at the density the
//      parts ask for; when the charts do not fit the texture the density is lowered for all of them together.
// xatlas runs single-threaded (XA_MULTITHREADED=0) and with fa::det trigonometry, so the result is the same on every platform.
#include <algorithm>
#include <cmath>
#include <cstring>
#include <format>
#include <map>
#include <unordered_map>

#include "model_uv_internal.h"
#include "xatlas.h"

namespace fa::uv {

namespace {

struct AtlasGuard {
    xatlas::Atlas* atlas = xatlas::Create();
    ~AtlasGuard() { xatlas::Destroy(atlas); }
    AtlasGuard() = default;
    AtlasGuard(const AtlasGuard&) = delete;
    AtlasGuard& operator=(const AtlasGuard&) = delete;
};

std::uint32_t bits_of(float f) {
    std::uint32_t u;
    std::memcpy(&u, &f, sizeof u);
    return u;
}

CornerKey uv_key(std::uint32_t weld, Vec2 uv) { return {(std::uint64_t(weld) << 32) | bits_of(uv.x), bits_of(uv.y)}; }

float signed_area2(Vec2 a, Vec2 b, Vec2 c) { return cross(b - a, c - a); }

}  // namespace

Result<bool> unwrap_parts(Work& w, const std::vector<std::vector<std::uint32_t>>& partTris, float texelsPerMeter, const std::string& seams) {
    const ModelMesh& mesh = *w.mesh;
    const bool hasNormals = mesh.normals.size() == mesh.positions.size();
    struct Local {
        std::uint32_t part = 0;
        std::vector<Vec3> pos, nrm;
        std::vector<std::uint32_t> idx;
    };
    std::vector<Local> locals;
    AtlasGuard guard;
    std::vector<std::int32_t> toLocal(mesh.vertex_count(), -1);
    for (std::size_t p = 0; p < partTris.size(); ++p) {
        if (partTris[p].empty()) continue;
        Local L;
        L.part = std::uint32_t(p);
        std::vector<std::uint32_t> used;
        for (std::uint32_t t : partTris[p])
            for (int k = 0; k < 3; ++k) {
                const std::uint32_t v = w.corner_vertex(t, k);
                if (toLocal[v] < 0) {
                    toLocal[v] = std::int32_t(L.pos.size());
                    used.push_back(v);
                    L.pos.push_back(w.wpos[w.welded[v]]);
                    L.nrm.push_back(hasNormals ? mesh.normals[v] : Vec3{0, 1, 0});
                }
                L.idx.push_back(std::uint32_t(toLocal[v]));
            }
        for (std::uint32_t v : used) toLocal[v] = -1;
        locals.push_back(std::move(L));
    }
    for (const Local& L : locals) {
        xatlas::MeshDecl decl;
        decl.vertexCount = std::uint32_t(L.pos.size());
        decl.vertexPositionData = L.pos.data();
        decl.vertexPositionStride = sizeof(Vec3);
        if (hasNormals) {
            decl.vertexNormalData = L.nrm.data();
            decl.vertexNormalStride = sizeof(Vec3);
        }
        decl.indexData = L.idx.data();
        decl.indexCount = std::uint32_t(L.idx.size());
        decl.indexFormat = xatlas::IndexFormat::UInt32;
        decl.epsilon = 1e-6f;
        const xatlas::AddMeshError err = xatlas::AddMesh(guard.atlas, decl, std::uint32_t(locals.size()));
        if (err != xatlas::AddMeshError::Success)
            return make_error(std::format("part \"{}\" cannot be unwrapped: {}", w.names[L.part], xatlas::StringForEnum(err)),
                              "Check the part's geometry with model.info; use a projection (box, cylinder, sphere, planar) for it in `uv`.");
    }
    if (locals.empty()) return true;
    xatlas::ChartOptions chart;
    if (seams == "few") chart.maxCost = 4.0f;
    else if (seams == "many") chart.maxCost = 1.0f;
    xatlas::ComputeCharts(guard.atlas, chart);
    xatlas::PackOptions pack;
    pack.texelsPerUnit = texelsPerMeter;
    pack.resolution = 0;
    pack.padding = 0;
    pack.bilinear = false;
    pack.rotateCharts = false;
    pack.rotateChartsToAxis = true;
    xatlas::PackCharts(guard.atlas, pack);
    if (guard.atlas->meshCount != locals.size())
        return make_error("the unwrap returned " + std::to_string(guard.atlas->meshCount) + " meshes for " + std::to_string(locals.size()) + " parts",
                          "This is a bug in the UV maker: report it with the model document.");

    const float inv = 1.0f / texelsPerMeter;
    std::map<std::int32_t, std::int32_t> chartIds;  // xatlas chart index -> chart id of the Work
    std::vector<std::uint32_t> placedTris;
    for (std::size_t m = 0; m < locals.size(); ++m) {
        const Local& L = locals[m];
        const xatlas::Mesh& out = guard.atlas->meshes[m];
        const std::vector<std::uint32_t>& tris = partTris[L.part];
        if (out.indexCount != L.idx.size())
            return make_error("the unwrap of part \"" + w.names[L.part] + "\" returned " + std::to_string(out.indexCount / 3) + " triangles for " + std::to_string(tris.size()),
                              "This is a bug in the UV maker: report it with the model document.");
        // where each input vertex was placed, for the triangles xatlas ignored (no area): they borrow a neighbour's uv
        std::vector<char> hasUv(L.pos.size(), 0);
        std::vector<Vec2> anyUv(L.pos.size());
        for (std::uint32_t v = 0; v < out.vertexCount; ++v) {
            const xatlas::Vertex& vt = out.vertexArray[v];
            if (vt.atlasIndex < 0 || vt.xref >= L.pos.size() || hasUv[vt.xref]) continue;
            hasUv[vt.xref] = 1;
            anyUv[vt.xref] = {vt.uv[0] * inv, vt.uv[1] * inv};
        }
        for (std::size_t f = 0; f < tris.size(); ++f) {
            const std::uint32_t t = tris[f];
            int chartIndex = -1;
            Vec2 uv[3];
            bool placed = true;
            for (int k = 0; k < 3; ++k) {
                const xatlas::Vertex& vt = out.vertexArray[out.indexArray[f * 3 + std::size_t(k)]];
                if (vt.atlasIndex < 0 || vt.chartIndex < 0) {
                    placed = false;
                    break;
                }
                uv[k] = {vt.uv[0] * inv, vt.uv[1] * inv};
                chartIndex = vt.chartIndex;
            }
            if (!placed) {
                w.chart[t] = -2;
                for (int k = 0; k < 3; ++k) {
                    const std::uint32_t src = L.idx[f * 3 + std::size_t(k)];
                    w.uv[t * 3 + std::size_t(k)] = hasUv[src] ? anyUv[src] : Vec2{};
                }
                continue;
            }
            auto it = chartIds.find(chartIndex);
            if (it == chartIds.end()) it = chartIds.emplace(chartIndex, w.chartCount++).first;
            w.chart[t] = it->second;
            for (int k = 0; k < 3; ++k) w.uv[t * 3 + std::size_t(k)] = uv[k];
            placedTris.push_back(t);
        }
    }
    // xatlas does not promise a handedness: mirror the charts that came out reading backwards. Seen from outside a triangle that is
    // counter-clockwise in space has a NEGATIVE area in uvs whose v grows downwards.
    std::vector<double> sum(std::size_t(w.chartCount), 0.0);
    for (std::uint32_t t : placedTris) {
        const Vec2* c = &w.uv[t * 3];
        sum[std::size_t(w.chart[t])] += double(signed_area2(c[0], c[1], c[2]));
    }
    for (std::uint32_t t : placedTris)
        if (sum[std::size_t(w.chart[t])] > 0)
            for (int k = 0; k < 3; ++k) w.uv[t * 3 + std::size_t(k)].x = -w.uv[t * 3 + std::size_t(k)].x;
    return true;
}

namespace {

// One chart ready for packing: its own vertices (a welded point with a uv is one vertex), in the density of its part.
struct Piece {
    std::vector<std::uint32_t> tris;
    std::vector<std::uint32_t> idx;  // 3 per triangle, into verts
    std::vector<Vec2> verts;         // texels
    Vec2 extent{};
};

int next_pow2(int v) {
    int p = 1;
    while (p < v) p <<= 1;
    return p;
}

}  // namespace

Result<PackResult> pack_atlas(Work& w, const PackRequest& request) {
    const std::size_t charts = std::size_t(w.chartCount);
    std::vector<Piece> pieces(charts);
    for (std::size_t t = 0; t < w.triangle_count(); ++t)
        if (w.chart[t] >= 0) pieces[std::size_t(w.chart[t])].tris.push_back(std::uint32_t(t));
    // chart -> vertices (metres, from the chart's own corner: precision stays with small numbers)
    double texelArea = 0;
    float maxExtent = 0;
    std::size_t used = 0;
    for (Piece& p : pieces) {
        if (p.tris.empty()) continue;
        ++used;
        const float scale = request.texelsPerMeter[w.part[p.tris[0]]];
        Vec2 lo{1e30f, 1e30f};
        for (std::uint32_t t : p.tris)
            for (int k = 0; k < 3; ++k) {
                const Vec2 c = w.uv[t * 3 + std::size_t(k)];
                lo = {std::min(lo.x, c.x), std::min(lo.y, c.y)};
            }
        std::map<CornerKey, std::uint32_t> ids;
        Vec2 hi{0, 0};
        for (std::uint32_t t : p.tris)
            for (int k = 0; k < 3; ++k) {
                const Vec2 c = w.uv[t * 3 + std::size_t(k)];
                const CornerKey key = uv_key(w.corner_weld(t, k), c);
                auto it = ids.find(key);
                if (it == ids.end()) {
                    it = ids.emplace(key, std::uint32_t(p.verts.size())).first;
                    const Vec2 texel = (c - lo) * scale;
                    p.verts.push_back(texel);
                    hi = {std::max(hi.x, texel.x), std::max(hi.y, texel.y)};
                }
                p.idx.push_back(it->second);
            }
        p.extent = hi;
        maxExtent = std::max({maxExtent, hi.x, hi.y});
        for (std::size_t f = 0; f < p.tris.size(); ++f)
            texelArea += 0.5 * std::fabs(double(signed_area2(p.verts[p.idx[f * 3]], p.verts[p.idx[f * 3 + 1]], p.verts[p.idx[f * 3 + 2]])));
    }
    PackResult result;
    result.charts = used;
    if (used == 0) {
        result.textureSize = request.textureSize > 0 ? request.textureSize : kModelUvMinTextureSize;
        return result;
    }

    AtlasGuard guard;
    for (const Piece& p : pieces) {
        if (p.tris.empty()) continue;
        xatlas::UvMeshDecl decl;
        decl.vertexUvData = p.verts.data();
        decl.vertexStride = sizeof(Vec2);
        decl.vertexCount = std::uint32_t(p.verts.size());
        decl.indexData = p.idx.data();
        decl.indexCount = std::uint32_t(p.idx.size());
        decl.indexFormat = xatlas::IndexFormat::UInt32;
        const xatlas::AddMeshError err = xatlas::AddUvMesh(guard.atlas, decl);
        if (err != xatlas::AddMeshError::Success)
            return make_error(std::string("the charts cannot be packed: ") + xatlas::StringForEnum(err), "This is a bug in the UV maker: report it with the model document.");
    }
    xatlas::ComputeCharts(guard.atlas);  // charts of a UV mesh are found by their shared vertices; nothing is cut
    xatlas::PackOptions pack;
    pack.padding = std::uint32_t(request.padding);
    pack.bilinear = true;
    pack.rotateCharts = request.rotate;
    pack.rotateChartsToAxis = request.rotate;
    pack.bruteForce = used <= 256;
    pack.texelsPerUnit = 1.0f;
    pack.resolution = 0;

    int size = request.textureSize;
    double shrink = 1;
    bool done = false;
    if (size == 0) {
        // the smallest power of two the charts fit in at the asked density; past the biggest texture they are shrunk to it
        xatlas::PackCharts(guard.atlas, pack);
        size = std::max(kModelUvMinTextureSize, next_pow2(int(std::max(guard.atlas->width, guard.atlas->height))));
        if (size > kModelUvMaxTextureSize) size = kModelUvMaxTextureSize;
        else done = true;
    }
    if (!done) {
        // a fixed square: a chart bigger than it, or all the charts together, set the density lower for everything
        const double room = double(size - 2 * request.padding - 2);
        if (room < 1) return make_error("the texture is too small for its padding", "Raise `textureSize` or lower `padding`.");
        if (double(maxExtent) > room) shrink = room / double(maxExtent);
        const double need = texelArea * shrink * shrink / 0.62;
        if (need > double(size) * double(size)) shrink *= std::sqrt(double(size) * double(size) / need);
        bool fits = false;
        for (int attempt = 0; attempt < 30 && !fits; ++attempt) {
            pack.texelsPerUnit = float(shrink);
            pack.resolution = std::uint32_t(size);
            xatlas::PackCharts(guard.atlas, pack);
            if (guard.atlas->atlasCount <= 1) fits = true;
            else shrink *= std::max(0.5, std::min(0.97, std::sqrt(1.0 / double(guard.atlas->atlasCount)) * 0.98));
        }
        if (!fits)
            return make_error(std::format("the charts do not fit a {0}x{0} texture even at {1:.2f} of the asked density", size, shrink),
                              "Raise `textureSize`, lower `texelsPerUnit`, or leave `textureSize` out to let it grow.");
    }
    result.textureSize = size;
    result.shrink = shrink;
    std::size_t piece = 0;
    const float inv = 1.0f / float(size);
    for (std::size_t c = 0; c < charts; ++c) {
        const Piece& p = pieces[c];
        if (p.tris.empty()) continue;
        const xatlas::Mesh& out = guard.atlas->meshes[piece++];
        std::vector<char> placed(p.verts.size(), 0);
        Vec2 any{};
        bool haveAny = false;
        for (std::size_t v = 0; v < p.verts.size(); ++v) {
            const xatlas::Vertex& vt = out.vertexArray[v];
            if (vt.atlasIndex < 0) continue;
            placed[v] = 1;
            if (!haveAny) any = {vt.uv[0], vt.uv[1]};
            haveAny = true;
        }
        for (std::size_t f = 0; f < p.tris.size(); ++f)
            for (int k = 0; k < 3; ++k) {
                const std::uint32_t v = p.idx[f * 3 + std::size_t(k)];
                const xatlas::Vertex& vt = out.vertexArray[v];
                const Vec2 texel = placed[v] ? Vec2{vt.uv[0], vt.uv[1]} : any;  // a vertex only ignored triangles use: any point of the chart
                w.uv[p.tris[f] * 3 + std::size_t(k)] = texel * inv;
            }
    }
    return result;
}

void tile_uvs(Work& w, const std::vector<float>& texelsPerMeter, int textureSize) {
    const float inv = 1.0f / float(textureSize);
    for (std::size_t t = 0; t < w.triangle_count(); ++t) {
        const float scale = texelsPerMeter[w.part[t]] * inv;
        for (int k = 0; k < 3; ++k) w.uv[t * 3 + std::size_t(k)] = w.uv[t * 3 + std::size_t(k)] * scale;
    }
}

std::vector<std::int32_t> charts_by_uv(const Work& w, const std::vector<Vec2>& uv, std::int32_t& count) {
    std::vector<CornerKey> keys(w.triangle_count() * 3);
    for (std::size_t t = 0; t < w.triangle_count(); ++t)
        for (int k = 0; k < 3; ++k) keys[t * 3 + std::size_t(k)] = uv_key(w.corner_weld(t, k), uv[t * 3 + std::size_t(k)]);
    return components(keys, w.triangle_count(), count);
}

namespace {

struct VertexKey {
    std::uint32_t src, u, v;
    bool operator==(const VertexKey& o) const { return src == o.src && u == o.u && v == o.v; }
};
struct VertexKeyHash {
    std::size_t operator()(const VertexKey& k) const {
        std::uint64_t h = k.src * 0x9E3779B97F4A7C15ull;
        h ^= (std::uint64_t(k.u) << 1) * 0xC2B2AE3D27D4EB4Full;
        h ^= (std::uint64_t(k.v) << 17) * 0x165667B19E3779F9ull;
        return std::size_t(h ^ (h >> 29));
    }
};

}  // namespace

ModelMesh rebuild_mesh(const Work& w) {
    const ModelMesh& src = *w.mesh;
    ModelMesh out;
    out.triParts = src.triParts;
    out.indices.reserve(src.indices.size());
    const bool normals = src.normals.size() == src.positions.size(), colors = src.colors.size() == src.positions.size();
    std::unordered_map<VertexKey, std::uint32_t, VertexKeyHash> ids;
    ids.reserve(src.vertex_count());
    for (std::size_t t = 0; t < w.triangle_count(); ++t)
        for (int k = 0; k < 3; ++k) {
            const std::uint32_t v = w.corner_vertex(t, k);
            const Vec2 uv = w.uv[t * 3 + std::size_t(k)];
            const VertexKey key{v, bits_of(uv.x), bits_of(uv.y)};
            auto it = ids.find(key);
            if (it == ids.end()) {
                it = ids.emplace(key, std::uint32_t(out.positions.size())).first;
                out.positions.push_back(src.positions[v]);
                if (normals) out.normals.push_back(src.normals[v]);
                if (colors) out.colors.push_back(src.colors[v]);
                out.uvs.push_back(uv);
            }
            out.indices.push_back(it->second);
        }
    return out;
}

}  // namespace fa::uv
