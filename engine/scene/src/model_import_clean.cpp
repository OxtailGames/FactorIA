// model.import_clean's mesh work (model_import_clean.h): weld, floating pieces, winding, scale, origin, decimation. The remesh is model_import_remesh.cpp.
#include "fa/scene/model_import_clean.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstring>
#include <format>
#include <unordered_map>

#include "fa/scene/model_decimate.h"

namespace fa {

namespace {

constexpr std::size_t kMaxListedPieces = 20;

std::uint64_t edge_key(std::uint32_t a, std::uint32_t b) {
    return a < b ? (std::uint64_t(a) << 32) | b : (std::uint64_t(b) << 32) | a;
}

struct CellKey {
    std::int64_t x, y, z;
    bool operator==(const CellKey&) const = default;
};
struct CellHash {
    std::size_t operator()(const CellKey& k) const {
        std::uint64_t h = std::uint64_t(k.x) * 0x9E3779B97F4A7C15ull;
        h ^= std::uint64_t(k.y) * 0xC2B2AE3D27D4EB4Full + (h << 6) + (h >> 2);
        h ^= std::uint64_t(k.z) * 0x165667B19E3779F9ull + (h << 6) + (h >> 2);
        return std::size_t(h);
    }
};

// MeshData -> ModelMesh with the submesh of each triangle in triParts. Triangles outside every submesh are not drawn and are dropped.
ModelMesh to_model_mesh(const MeshData& d) {
    ModelMesh m;
    const std::size_t n = d.vertex_count();
    m.positions.resize(n);
    m.normals.resize(n);
    m.uvs.assign(n, Vec2{0, 0});
    for (std::size_t v = 0; v < n; ++v) {
        m.positions[v] = {d.positions[v * 3], d.positions[v * 3 + 1], d.positions[v * 3 + 2]};
        m.normals[v] = {d.normals[v * 3], d.normals[v * 3 + 1], d.normals[v * 3 + 2]};
        if (d.hasUvs && d.uvs.size() == n * 2) m.uvs[v] = {d.uvs[v * 2], d.uvs[v * 2 + 1]};
    }
    if (d.colors.size() == n * 4) {
        m.colors.resize(n);
        for (std::size_t v = 0; v < n; ++v)
            m.colors[v] = {d.colors[v * 4], d.colors[v * 4 + 1], d.colors[v * 4 + 2], d.colors[v * 4 + 3]};
    }
    for (std::size_t s = 0; s < d.submeshes.size(); ++s) {
        const MeshSubmesh& sm = d.submeshes[s];
        const std::uint32_t end = std::min<std::uint32_t>(sm.start + sm.count, std::uint32_t(d.indices.size()));
        for (std::uint32_t k = sm.start; k + 3 <= end; k += 3) {
            m.indices.insert(m.indices.end(), {d.indices[k], d.indices[k + 1], d.indices[k + 2]});
            m.triParts.push_back(std::uint32_t(s));
        }
    }
    return m;
}

Vec3 face_cross(const ModelMesh& m, std::size_t t) {
    const Vec3 a = m.positions[m.indices[t * 3]], b = m.positions[m.indices[t * 3 + 1]],
               c = m.positions[m.indices[t * 3 + 2]];
    return cross(b - a, c - a);
}

// Keeps only the vertices triangles use (in order of first use).
void compact(ModelMesh& m, std::vector<std::uint32_t>* outTopo = nullptr) {
    std::vector<std::int64_t> remap(m.positions.size(), -1);
    ModelMesh r;
    std::vector<std::uint32_t> topo;
    const bool hasCol = !m.colors.empty();
    for (std::uint32_t& i : m.indices) {
        if (remap[i] < 0) {
            remap[i] = std::int64_t(r.positions.size());
            r.positions.push_back(m.positions[i]);
            r.normals.push_back(m.normals[i]);
            r.uvs.push_back(m.uvs[i]);
            if (hasCol) r.colors.push_back(m.colors[i]);
            if (outTopo) topo.push_back((*outTopo)[i]);
        }
        i = std::uint32_t(remap[i]);
    }
    m.positions = std::move(r.positions);
    m.normals = std::move(r.normals);
    m.uvs = std::move(r.uvs);
    m.colors = std::move(r.colors);
    if (outTopo) *outTopo = std::move(topo);
}

struct Dsu {
    std::vector<std::uint32_t> p;
    explicit Dsu(std::size_t n) : p(n) {
        for (std::size_t i = 0; i < n; ++i) p[i] = std::uint32_t(i);
    }
    std::uint32_t find(std::uint32_t x) {
        while (p[x] != x) x = p[x] = p[p[x]];
        return x;
    }
    void unite(std::uint32_t a, std::uint32_t b) {
        a = find(a);
        b = find(b);
        if (a != b) (a < b ? p[b] = a : p[a] = b);
    }
};

Vec3 bounds_size(const ModelMesh& m) {
    Vec3 lo{}, hi{};
    m.bounds(lo, hi);
    return hi - lo;
}

// The vertices of the triangles `flipped` marks get a normal that agrees with the surface again.
void fix_normals_of_flipped(ModelMesh& m, const std::vector<char>& flipped) {
    const std::size_t n = m.positions.size();
    std::vector<Vec3> faceSum(n);
    std::vector<char> touched(n, 0);
    for (std::size_t t = 0; t < m.triangle_count(); ++t) {
        const Vec3 c = face_cross(m, t);
        for (int k = 0; k < 3; ++k) {
            const std::uint32_t v = m.indices[t * 3 + std::size_t(k)];
            faceSum[v] = faceSum[v] + c;
            if (flipped[t]) touched[v] = 1;
        }
    }
    for (std::size_t v = 0; v < n; ++v) {
        if (!touched[v]) continue;
        if (dot(m.normals[v], faceSum[v]) < 0) m.normals[v] = -m.normals[v];
    }
}

struct EdgeUse {
    std::uint32_t tri[2] = {0, 0};
    std::uint8_t count = 0;
};

}  // namespace

Result<ModelCleanResult> model_import_clean(const MeshData& source, const ModelCleanOptions& o) {
    ModelCleanResult result;
    ModelCleanReport& rep = result.report;
    if (o.upAxis != "y" && o.upAxis != "z")
        return make_error("upAxis '" + o.upAxis + "' is not y or z",
                          "Use \"y\" (glTF and the engine) or \"z\" (Blender and CAD exports).");
    if (o.origin != "keep" && o.origin != "center" && o.origin != "bottom" && o.origin != "bottom_center")
        return make_error("origin '" + o.origin + "' is not one of keep, center, bottom, bottom_center",
                          "\"bottom_center\" puts the origin at the middle of the model's feet.");
    if (o.height && o.scale)
        return make_error("give `height` or `scale`, not both",
                          "`height` scales to a size in metres; `scale` multiplies by a factor.");
    if (o.height && !(*o.height > 0.0001 && *o.height < 100000))
        return make_error("height must be between 0.0001 and 100000 metres", "A person is 1.8, a door 2.1, a house 8.");
    if (o.scale && !(*o.scale > 1e-6 && *o.scale < 1e6))
        return make_error("scale must be between 0.000001 and 1000000",
                          "A model exported in centimetres needs 0.01; in millimetres 0.001.");
    if (o.minPieceSize < 0 || o.minPieceSize > 1)
        return make_error("minPieceSize must be between 0 and 1",
                          "It is a fraction of the biggest piece's size: 0.02 removes pieces under 2% of it.");
    if (o.remeshCells < 16 || o.remeshCells > 400)
        return make_error("remeshCells must be between 16 and 400",
                          "The cells along the longest side; 128 is a good start, more is slower and finer.");

    ModelMesh m = to_model_mesh(source);
    if (m.empty()) return make_error("the mesh has no triangles", "Give a mesh that draws at least one triangle.");
    const bool hasUvs = source.hasUvs;
    rep.hadUvs = hasUvs;
    rep.verticesBefore = source.vertex_count();
    rep.trianglesBefore = m.triangle_count();
    if (o.upAxis == "z") {
        for (Vec3& p : m.positions) p = {p.x, p.z, -p.y};
        for (Vec3& n : m.normals) n = {n.x, n.z, -n.y};
    }
    rep.statsBefore = model_mesh_stats(m);
    rep.sizeBefore = bounds_size(m);
    {
        Vec3 lo{}, hi{};
        m.bounds(lo, hi);
        for (const Vec3& p : m.positions)
            if (!std::isfinite(p.x) || !std::isfinite(p.y) || !std::isfinite(p.z))
                return make_error("the mesh has a position that is NaN or infinite",
                                  "Export the model again; the tool that made it wrote a broken vertex.");
    }

    // ---- weld -------------------------------------------------------------------------------------------------------------------------
    Vec3 lo{}, hi{};
    m.bounds(lo, hi);
    const float diag = length(hi - lo);
    const float weld = o.weldDistance > 0 ? float(o.weldDistance) : std::max(diag * 1e-6f, 1e-9f);
    const std::size_t n0 = m.positions.size();
    std::vector<std::uint32_t> rep0(n0);  // the first vertex of the position cluster each vertex belongs to
    {
        std::unordered_map<CellKey, std::vector<std::uint32_t>, CellHash> grid;
        grid.reserve(n0);
        const float inv = 1.0f / weld;
        auto cell_of = [&](Vec3 p) {
            return CellKey{std::int64_t(std::floor(double(p.x) * inv)), std::int64_t(std::floor(double(p.y) * inv)),
                           std::int64_t(std::floor(double(p.z) * inv))};
        };
        for (std::size_t v = 0; v < n0; ++v) {
            const Vec3 p = m.positions[v];
            const CellKey c = cell_of(p);
            std::int64_t found = -1;
            for (std::int64_t dz = -1; dz <= 1 && found < 0; ++dz)
                for (std::int64_t dy = -1; dy <= 1 && found < 0; ++dy)
                    for (std::int64_t dx = -1; dx <= 1 && found < 0; ++dx) {
                        auto it = grid.find({c.x + dx, c.y + dy, c.z + dz});
                        if (it == grid.end()) continue;
                        for (std::uint32_t r : it->second)
                            if (length_sq(m.positions[r] - p) <= weld * weld) {
                                found = r;
                                break;
                            }
                    }
            if (found >= 0) {
                rep0[v] = std::uint32_t(found);
            } else {
                rep0[v] = std::uint32_t(v);
                grid[c].push_back(std::uint32_t(v));
            }
        }
    }
    // output vertices: one per (cluster, compatible attributes)
    std::vector<std::uint32_t> topo;  // of each output vertex: the cluster id (a source vertex index)
    std::vector<std::uint32_t> remap(n0);
    ModelMesh w;
    {
        const bool hasCol = !m.colors.empty();
        std::unordered_map<std::uint32_t, std::vector<std::uint32_t>> outs;
        outs.reserve(n0);
        for (std::size_t v = 0; v < n0; ++v) {
            const std::uint32_t r = rep0[v];
            auto& list = outs[r];
            std::int64_t same = -1;
            for (std::uint32_t o2 : list) {
                if (hasUvs &&
                    (std::fabs(w.uvs[o2].x - m.uvs[v].x) > 1e-5f || std::fabs(w.uvs[o2].y - m.uvs[v].y) > 1e-5f))
                    continue;
                if (hasCol && dot(w.colors[o2] - m.colors[v], w.colors[o2] - m.colors[v]) > 4e-6f) continue;
                if (dot(w.normals[o2], m.normals[v]) < 0.9999f) continue;
                same = o2;
                break;
            }
            if (same >= 0) {
                remap[v] = std::uint32_t(same);
                continue;
            }
            remap[v] = std::uint32_t(w.positions.size());
            list.push_back(remap[v]);
            w.positions.push_back(m.positions[r]);
            w.normals.push_back(m.normals[v]);
            w.uvs.push_back(m.uvs[v]);
            if (hasCol) w.colors.push_back(m.colors[v]);
            topo.push_back(r);
        }
    }
    rep.verticesWelded = n0 - w.positions.size();
    // triangles: drop the degenerate and the repeated
    {
        std::unordered_map<std::uint64_t, std::vector<std::array<std::uint32_t, 3>>> seen;
        const float areaEps = std::max(diag * diag * 1e-12f, 1e-30f);
        for (std::size_t t = 0; t < m.triangle_count(); ++t) {
            std::uint32_t c[3];
            for (int k = 0; k < 3; ++k) c[k] = remap[m.indices[t * 3 + std::size_t(k)]];
            const std::uint32_t tp[3] = {topo[c[0]], topo[c[1]], topo[c[2]]};
            if (tp[0] == tp[1] || tp[1] == tp[2] || tp[0] == tp[2]) {
                ++rep.degenerateRemoved;
                continue;
            }
            const Vec3 a = w.positions[c[0]], b = w.positions[c[1]], d = w.positions[c[2]];
            if (length_sq(cross(b - a, d - a)) <= areaEps * areaEps) {
                ++rep.degenerateRemoved;
                continue;
            }
            std::array<std::uint32_t, 3> sorted = {tp[0], tp[1], tp[2]};
            std::sort(sorted.begin(), sorted.end());
            const std::uint64_t key = (std::uint64_t(sorted[0]) * 0x9E3779B97F4A7C15ull) ^
                                      (std::uint64_t(sorted[1]) << 21) ^ (std::uint64_t(sorted[2]) << 42) ^ sorted[2];
            auto& bucket = seen[key];
            if (std::find(bucket.begin(), bucket.end(), sorted) != bucket.end()) {
                ++rep.duplicatesRemoved;
                continue;
            }
            bucket.push_back(sorted);
            w.indices.insert(w.indices.end(), {c[0], c[1], c[2]});
            w.triParts.push_back(m.triParts[t]);
        }
    }
    if (w.empty())
        return make_error("every triangle is degenerate after welding",
                          "The mesh has no surface: check that the file holds real geometry and that `weldDistance` is "
                          "not larger than the model's details.");
    m = std::move(w);
    compact(m, &topo);

    // ---- pieces: connected through shared (welded) vertices ------------------------------------------------------------------------
    {
        Dsu dsu(m.positions.size());
        // vertices of one cluster are the same point: join them first
        std::unordered_map<std::uint32_t, std::uint32_t> firstOfCluster;
        for (std::size_t v = 0; v < m.positions.size(); ++v) {
            auto [it, fresh] = firstOfCluster.emplace(topo[v], std::uint32_t(v));
            if (!fresh) dsu.unite(it->second, std::uint32_t(v));
        }
        for (std::size_t t = 0; t < m.triangle_count(); ++t) {
            dsu.unite(m.indices[t * 3], m.indices[t * 3 + 1]);
            dsu.unite(m.indices[t * 3], m.indices[t * 3 + 2]);
        }
        struct Piece {
            std::size_t triangles = 0;
            Vec3 lo{1e30f, 1e30f, 1e30f}, hi{-1e30f, -1e30f, -1e30f};
        };
        std::unordered_map<std::uint32_t, std::size_t> pieceOf;
        std::vector<Piece> pieces;
        std::vector<std::uint32_t> triPiece(m.triangle_count());
        for (std::size_t t = 0; t < m.triangle_count(); ++t) {
            const std::uint32_t root = dsu.find(m.indices[t * 3]);
            auto [it, fresh] = pieceOf.emplace(root, pieces.size());
            if (fresh) pieces.emplace_back();
            Piece& p = pieces[it->second];
            ++p.triangles;
            triPiece[t] = std::uint32_t(it->second);
            for (int k = 0; k < 3; ++k) {
                const Vec3 q = m.positions[m.indices[t * 3 + std::size_t(k)]];
                p.lo = min(p.lo, q);
                p.hi = max(p.hi, q);
            }
        }
        rep.pieces = pieces.size();
        double biggest = 0;
        for (const Piece& p : pieces) biggest = std::max(biggest, double(length(p.hi - p.lo)));
        if (o.removeFloating && pieces.size() > 1) {
            std::vector<char> drop(pieces.size(), 0);
            for (std::size_t i = 0; i < pieces.size(); ++i) {
                const double d = length(pieces[i].hi - pieces[i].lo);
                if (d < o.minPieceSize * biggest) {
                    drop[i] = 1;
                    ++rep.removedPieceCount;
                    rep.removedPieceTriangles += pieces[i].triangles;
                    if (rep.removedPieces.size() < kMaxListedPieces)
                        rep.removedPieces.push_back({pieces[i].triangles, d, (pieces[i].lo + pieces[i].hi) * 0.5f});
                }
            }
            if (rep.removedPieceCount > 0) {
                ModelMesh k;
                k.positions = std::move(m.positions);
                k.normals = std::move(m.normals);
                k.uvs = std::move(m.uvs);
                k.colors = std::move(m.colors);
                for (std::size_t t = 0; t < m.triParts.size(); ++t) {
                    if (drop[triPiece[t]]) continue;
                    k.indices.insert(k.indices.end(), {m.indices[t * 3], m.indices[t * 3 + 1], m.indices[t * 3 + 2]});
                    k.triParts.push_back(m.triParts[t]);
                }
                m = std::move(k);
                compact(m, &topo);
            }
        }
    }

    // ---- winding: neighbours agree, closed pieces face outward --------------------------------------------------------------------
    {
        const std::size_t tris = m.triangle_count();
        std::unordered_map<std::uint64_t, EdgeUse> edges;
        edges.reserve(tris * 2);
        auto corner = [&](std::size_t t, int k) { return topo[m.indices[t * 3 + std::size_t(k)]]; };
        for (std::size_t t = 0; t < tris; ++t)
            for (int k = 0; k < 3; ++k) {
                EdgeUse& e = edges[edge_key(corner(t, k), corner(t, (k + 1) % 3))];
                if (e.count < 2) e.tri[e.count] = std::uint32_t(t);
                if (e.count < 255) ++e.count;
            }
        std::vector<std::int8_t> state(tris, -1);  // -1 unvisited, 0 keep, 1 flip
        std::vector<std::uint32_t> pieceOfTri(tris, 0);
        std::vector<std::uint32_t> queue;
        std::uint32_t pieceCount = 0;
        // does triangle t (as stored) go a -> b along its edge?
        auto goes = [&](std::size_t t, std::uint32_t a, std::uint32_t b) {
            for (int k = 0; k < 3; ++k)
                if (corner(t, k) == a && corner(t, (k + 1) % 3) == b) return true;
            return false;
        };
        for (std::size_t seed = 0; seed < tris; ++seed) {
            if (state[seed] >= 0) continue;
            state[seed] = 0;
            pieceOfTri[seed] = pieceCount;
            queue.assign(1, std::uint32_t(seed));
            for (std::size_t head = 0; head < queue.size(); ++head) {
                const std::uint32_t t = queue[head];
                for (int k = 0; k < 3; ++k) {
                    const std::uint32_t a = corner(t, k), b = corner(t, (k + 1) % 3);
                    const EdgeUse& e = edges[edge_key(a, b)];
                    if (e.count != 2) continue;
                    const std::uint32_t u = e.tri[0] == t ? e.tri[1] : e.tri[0];
                    if (state[u] >= 0) continue;
                    // t, after its flip, goes a -> b (or b -> a when flipped); u must go the other way
                    const bool tGoesAB = state[t] == 0;  // as stored t goes a -> b by construction of the loop
                    const bool uStoredAB = goes(u, a, b);
                    state[u] = (uStoredAB == tGoesAB) ? 1 : 0;
                    pieceOfTri[u] = pieceCount;
                    queue.push_back(u);
                }
            }
            ++pieceCount;
        }
        // closed pieces with a negative volume face inward as a whole
        std::vector<double> volume(pieceCount, 0);
        std::vector<char> hasBoundary(pieceCount, 0);
        for (std::size_t t = 0; t < tris; ++t) {
            Vec3 a = m.positions[m.indices[t * 3]], b = m.positions[m.indices[t * 3 + 1]],
                 c = m.positions[m.indices[t * 3 + 2]];
            if (state[t] == 1) std::swap(b, c);
            volume[pieceOfTri[t]] += double(dot(a, cross(b, c))) / 6.0;
            for (int k = 0; k < 3; ++k)
                if (edges[edge_key(corner(t, k), corner(t, (k + 1) % 3))].count == 1) hasBoundary[pieceOfTri[t]] = 1;
        }
        std::vector<char> flipped(tris, 0);
        for (std::size_t t = 0; t < tris; ++t) {
            const std::uint32_t p = pieceOfTri[t];
            const bool inward = !hasBoundary[p] && volume[p] < 0;
            if ((state[t] == 1) != inward) {
                std::swap(m.indices[t * 3 + 1], m.indices[t * 3 + 2]);
                flipped[t] = 1;
                ++rep.trianglesReoriented;
            }
        }
        if (rep.trianglesReoriented > 0) fix_normals_of_flipped(m, flipped);
    }

    // ---- scale -------------------------------------------------------------------------------------------------------------------------
    {
        const Vec3 size = bounds_size(m);
        double factor = 1;
        rep.scaleReason = "none";
        if (o.height) {
            if (size.y < 1e-9f)
                return make_error(
                    "the model has no height to scale (it is flat in Y)",
                    "If it was exported with Z up, pass \"upAxis\": \"z\"; or use `scale` with a factor.");
            factor = *o.height / double(size.y);
            rep.scaleReason = std::format("height {:g} m (the model was {:.4g} m tall)", *o.height, double(size.y));
        } else if (o.scale) {
            factor = *o.scale;
            rep.scaleReason = std::format("factor {:g}", *o.scale);
        } else if (size.y < 0.02f || size.y > 50.0f) {
            rep.warnings.push_back(
                std::format("the model is {:.4g} m tall, which is not a size anything in a game usually has. If that "
                            "is a unit mistake, pass `height` (metres, e.g. 1.8 for a person) or `scale` (0.01 for "
                            "centimetres, 0.001 for millimetres).",
                            double(size.y)));
        }
        if (factor != 1) {
            const float f = float(factor);
            for (Vec3& p : m.positions) p = p * f;
        }
        rep.scaleFactor = factor;
    }

    // ---- origin ------------------------------------------------------------------------------------------------------------------------
    {
        Vec3 l{}, h{};
        m.bounds(l, h);
        Vec3 offset{};
        if (o.origin == "center")
            offset = (l + h) * -0.5f;
        else if (o.origin == "bottom")
            offset = {0, -l.y, 0};
        else if (o.origin == "bottom_center")
            offset = {-(l.x + h.x) * 0.5f, -l.y, -(l.z + h.z) * 0.5f};
        if (offset != Vec3{}) {
            for (Vec3& p : m.positions) p = p + offset;
        }
        rep.offset = offset;
    }

    // ---- remesh -----------------------------------------------------------------------------------------------------------------------
    std::vector<std::string> groupMaterial;
    for (const MeshSubmesh& sm : source.submeshes) groupMaterial.push_back(sm.material.name);
    bool uvsKept = hasUvs;
    if (o.remesh) {
        ModelRemeshInfo info;
        auto remeshed = model_remesh_mesh(m, o.remeshVoxel, o.remeshCells, groupMaterial, o.textureSampler, &info);
        if (!remeshed) return make_error("remesh: " + remeshed.error().message, remeshed.error().hint);
        if (remeshed->empty())
            return make_error("remesh: the distance field has no surface",
                              "The model is smaller than one cell: lower `remeshVoxel` or raise `remeshCells`.");
        m = std::move(*remeshed);
        rep.remeshed = true;
        rep.remeshVoxel = info.voxel;
        rep.remeshRawTriangles = info.rawTriangles;
        rep.texturesToColors = info.texturesToColors;
        rep.texturesDropped = true;
        uvsKept = false;
    }

    // ---- decimate -----------------------------------------------------------------------------------------------------------------------
    rep.trianglesBeforeDecimate = m.triangle_count();
    if (o.targetTriangles > 0 && m.triangle_count() > o.targetTriangles) {
        const std::size_t n = m.positions.size();
        const bool hasCol = !m.colors.empty();
        const std::size_t stride = 3 + (uvsKept ? 2 : 0) + (hasCol ? 4 : 0);
        std::vector<float> attr(n * stride), weights(3, 1.0f);
        if (uvsKept) weights.insert(weights.end(), 2, 0.5f);
        if (hasCol) weights.insert(weights.end(), 4, 0.25f);
        for (std::size_t v = 0; v < n; ++v) {
            float* a = &attr[v * stride];
            a[0] = m.normals[v].x;
            a[1] = m.normals[v].y;
            a[2] = m.normals[v].z;
            a += 3;
            if (uvsKept) {
                a[0] = m.uvs[v].x;
                a[1] = m.uvs[v].y;
                a += 2;
            }
            if (hasCol) {
                a[0] = m.colors[v].x;
                a[1] = m.colors[v].y;
                a[2] = m.colors[v].z;
                a[3] = m.colors[v].w;
            }
        }
        ModelSimplifyParams sp;
        sp.targetTriangles = o.targetTriangles;
        sp.lockBorder = false;
        const ModelSimplifyResult r = model_simplify(m.positions, attr, stride, weights, m.indices, m.triParts, sp);
        if (!r.indices.empty()) {
            ModelMesh d;
            const std::size_t vn = r.positions.size();
            d.positions = r.positions;
            d.normals.resize(vn);
            d.uvs.assign(vn, Vec2{0, 0});
            if (hasCol) d.colors.resize(vn);
            for (std::size_t v = 0; v < vn; ++v) {
                const float* a = &r.attributes[v * stride];
                Vec3 nrm = normalize(Vec3{a[0], a[1], a[2]});
                if (length_sq(nrm) < 0.5f) nrm = m.normals[r.keep[v]];
                d.normals[v] = nrm;
                a += 3;
                if (uvsKept) {
                    d.uvs[v] = {a[0], a[1]};
                    a += 2;
                }
                if (hasCol)
                    d.colors[v] = {clamp(a[0], 0.0f, 1.0f), clamp(a[1], 0.0f, 1.0f), clamp(a[2], 0.0f, 1.0f),
                                   clamp(a[3], 0.0f, 1.0f)};
            }
            d.indices = r.indices;
            d.triParts = r.triParts;
            m = std::move(d);
            rep.decimated = true;
            rep.decimateError = r.error;
            rep.reachedTarget = m.triangle_count() <= o.targetTriangles + o.targetTriangles / 20 + 2;
            if (!rep.reachedTarget) {
                if (rep.remeshed)
                    rep.warnings.push_back(
                        std::format("the decimation stopped at {} triangles, above the target of {}: the surface is a "
                                    "thin shell (an open sheet remeshes into one), and collapsing it further would "
                                    "pinch its two sides together. Close the holes in the source, or lower "
                                    "`remeshCells` / raise `remeshVoxel` for a coarser surface.",
                                    m.triangle_count(), o.targetTriangles));
                else
                    rep.warnings.push_back(
                        std::format("the decimation stopped at {} triangles, above the target of {}: the open borders "
                                    "and thin parts of the surface stay where they are. A remesh (`remesh`: true) "
                                    "closes the surface so it can go lower.",
                                    m.triangle_count(), o.targetTriangles));
            }
        } else {
            rep.warnings.push_back("the decimation removed every triangle, so it was skipped");
        }
    }

    // ---- result: triangles grouped by their submesh -------------------------------------------------------------------------------
    rep.verticesAfter = m.positions.size();
    rep.trianglesAfter = m.triangle_count();
    rep.statsAfter = model_mesh_stats(m);
    rep.sizeAfter = bounds_size(m);
    const std::size_t groupCount = source.submeshes.size();
    std::vector<std::uint32_t> counts(groupCount, 0);
    for (std::uint32_t g : m.triParts) ++counts[g];
    std::vector<std::uint32_t> start(groupCount, 0);
    for (std::size_t g = 1; g < groupCount; ++g) start[g] = start[g - 1] + counts[g - 1] * 3;
    std::vector<std::uint32_t> cursor = start;
    MeshInput in;
    in.hasIndices = true;
    in.indices.resize(m.indices.size());
    for (std::size_t t = 0; t < m.triParts.size(); ++t) {
        std::uint32_t& c = cursor[m.triParts[t]];
        for (std::size_t k = 0; k < 3; ++k) in.indices[c + k] = m.indices[t * 3 + k];
        c += 3;
    }
    for (const Vec3& p : m.positions) in.positions.insert(in.positions.end(), {p.x, p.y, p.z});
    for (const Vec3& nn : m.normals) in.normals.insert(in.normals.end(), {nn.x, nn.y, nn.z});
    if (uvsKept)
        for (const Vec2& t : m.uvs) in.uvs.insert(in.uvs.end(), {t.x, t.y});
    for (const Vec4& c : m.colors) in.colors.insert(in.colors.end(), {c.x, c.y, c.z, c.w});
    for (std::size_t g = 0; g < groupCount; ++g) {
        if (counts[g] == 0) continue;
        MeshSubmesh sm = source.submeshes[g];
        sm.start = start[g];
        sm.count = counts[g] * 3;
        in.submeshes.push_back(sm);
    }
    auto data = build_mesh_data(in);
    if (!data) return make_error("the cleaned mesh is not valid: " + data.error().message, data.error().hint);
    result.mesh = std::move(*data);
    if (rep.statsAfter.nonManifoldEdges > 0 || rep.statsAfter.boundaryEdges > 0) {
        if (!o.remesh)
            rep.warnings.push_back(
                std::format("the cleaned surface still has {} open edge(s) and {} non-manifold edge(s) (holes, or "
                            "three or more triangles on one edge). That is fine for drawing; for a solid that "
                            "booleans, a collider or a decimation to a low budget accept, pass `remesh`: true.",
                            rep.statsAfter.boundaryEdges, rep.statsAfter.nonManifoldEdges));
    }
    return result;
}

Json model_clean_report_json(const ModelCleanReport& r) {
    auto rnd = [](double v) { return std::round(v * 10000.0) / 10000.0 + 0.0; };
    auto vec = [&](Vec3 v) { return Json::array({rnd(v.x), rnd(v.y), rnd(v.z)}); };
    Json pieces = Json::array();
    for (const ModelCleanPiece& p : r.removedPieces)
        pieces.push_back(
            Json::object({{"triangles", p.triangles}, {"diagonal", rnd(p.diagonal)}, {"center", vec(p.center)}}));
    auto surface = [&](const ModelMeshStats& s) {
        return Json::object({{"vertices", s.vertices},
                             {"triangles", s.triangles},
                             {"closed", s.closed()},
                             {"boundaryEdges", s.boundaryEdges},
                             {"nonManifoldEdges", s.nonManifoldEdges},
                             {"degenerateTriangles", s.degenerateTriangles}});
    };
    Json out =
        Json::object({{"before", Json::object({{"vertices", r.verticesBefore},
                                               {"triangles", r.trianglesBefore},
                                               {"size", vec(r.sizeBefore)},
                                               {"surface", surface(r.statsBefore)}})},
                      {"after", Json::object({{"vertices", r.verticesAfter},
                                              {"triangles", r.trianglesAfter},
                                              {"size", vec(r.sizeAfter)},
                                              {"surface", surface(r.statsAfter)}})},
                      {"weld", Json::object({{"verticesMerged", r.verticesWelded},
                                             {"degenerateTrianglesRemoved", r.degenerateRemoved},
                                             {"duplicateTrianglesRemoved", r.duplicatesRemoved}})},
                      {"pieces", Json::object({{"found", r.pieces},
                                               {"removed", r.removedPieceCount},
                                               {"trianglesRemoved", r.removedPieceTriangles},
                                               {"list", pieces}})},
                      {"trianglesReoriented", r.trianglesReoriented},
                      {"nonManifoldEdgesFixed", r.statsBefore.nonManifoldEdges > r.statsAfter.nonManifoldEdges
                                                    ? r.statsBefore.nonManifoldEdges - r.statsAfter.nonManifoldEdges
                                                    : 0},
                      {"scale", Json::object({{"factor", rnd(r.scaleFactor)}, {"reason", r.scaleReason}})},
                      {"origin", Json::object({{"offset", vec(r.offset)}})}});
    if (r.remeshed)
        out["remesh"] = Json::object({{"voxel", rnd(r.remeshVoxel)},
                                      {"rawTriangles", r.remeshRawTriangles},
                                      {"texturesToVertexColors", r.texturesToColors}});
    if (r.decimated)
        out["decimate"] = Json::object({{"from", r.trianglesBeforeDecimate},
                                        {"to", r.trianglesAfter},
                                        {"maxError", rnd(r.decimateError)},
                                        {"reachedTarget", r.reachedTarget}});
    if (!r.warnings.empty()) out["warnings"] = r.warnings;
    return out;
}

}  // namespace fa
