// Boolean operations on closed solids, backed by Manifold (external/manifold, Apache-2.0).
//
// What goes in. Each operand becomes a Manifold MeshGL64 with 9 extra properties per vertex (normal, uv, colour) that the library
// interpolates over the triangles it cuts. Positions are welded first (kWeldTolerance), vertices that differ only in normal or uv are
// property rows of one welded vertex (the merge vectors), and a triangle that collapsed in the weld is left out. Every triangle carries
// a unique `faceID`, which the library passes to the result: that is how a result triangle finds the triangle it was cut from, and so its
// part. Booleans run serially (MANIFOLD_PAR=-1: no threads, no TBB), so the result is the same on every run.
//
// What comes out. The triangles with the carried properties; the faces a difference leaves in the first operand come from the subtracted
// ones and get their normals turned around. Normals are re-normalised after interpolation.
#include <cmath>
#include <cstring>
#include <format>
#include <unordered_map>

#include "fa/scene/model_modifiers.h"
#include "manifold/manifold.h"
#include "model_mesh_ops.h"

namespace fa {

using namespace mm;

namespace {

constexpr int kProps = 12;  // x y z, normal(3), uv(2), colour(4)

struct RowKey {
    std::array<std::uint32_t, kProps> w;
    bool operator==(const RowKey& o) const { return w == o.w; }
};
struct RowKeyHash {
    std::size_t operator()(const RowKey& k) const {
        std::uint64_t h = 1469598103934665603ull;
        for (std::uint32_t v : k.w) {
            h ^= v;
            h *= 1099511628211ull;
        }
        return static_cast<std::size_t>(h);
    }
};
std::uint32_t bits_of(float f) {
    f += 0.0f;
    std::uint32_t u;
    std::memcpy(&u, &f, sizeof u);
    return u;
}

std::string operand_name(const std::vector<std::string>& names, std::size_t i) {
    return i < names.size() && !names[i].empty() ? names[i] : std::format("operand {}", i + 1);
}

struct Prepared {
    manifold::MeshGL64 mesh;
    std::size_t triangles = 0;
};

// The operand as a MeshGL64, or an error that says why it is not a closed solid. `firstFace` is the faceID of its first triangle; the
// parts of its triangles are appended to `facePart`.
Result<Prepared> prepare(const ModelMesh& m, const std::string& name, std::uint32_t firstFace,
                         std::vector<std::uint32_t>& facePart, bool& hasColors, double& volumeOut) {
    std::vector<std::uint32_t> welded;
    const Soup s = to_soup(m, kWeldTolerance, &welded);
    Prepared out;
    if (s.tris.empty()) return out;
    const Edges edges = build_edges(s);
    std::size_t open = 0, bad = 0;
    for (std::size_t e = 0; e < edges.edges.size(); ++e) {
        if (edges.edges[e].count == 1)
            ++open;
        else if (!edges.regular(e))
            ++bad;
    }
    if (open > 0)
        return make_error(std::format("{} is not a closed solid: its surface has {} open edge(s), a hole", name, open),
                          "A boolean needs solids with no holes (box, sphere, cylinder, torus, capsule... or the "
                          "result of another boolean). A grid, a cone without `cap`, "
                          "a cylinder without a cap or a lathe with `cap: false` are open: close them, or use "
                          "`solidify` to give a surface thickness first.");
    if (bad > 0)
        return make_error(std::format("{} is not a manifold solid: {} edge(s) are shared by more than two faces, or by "
                                      "two faces that turn the same way",
                                      name, bad),
                          "Two solids that only touch along an edge make such an edge: move them apart or overlap "
                          "them, or put each in its own boolean.");
    double volume = 0;
    for (std::size_t t = 0; t < s.tris.size(); ++t) {
        const Vec3 a = s.pos[s.tris[t][0]], b = s.pos[s.tris[t][1]], c = s.pos[s.tris[t][2]];
        volume += double(dot(a, cross(b, c))) / 6.0;
    }
    volumeOut = volume;
    if (!(volume > 0))
        return make_error(
            std::format("{} has its faces turned inwards (its volume is negative) or has no volume", name),
            "A boolean needs the faces to point out of the solid. A node with a negative `scale` on one axis is "
            "mirrored; flip it back, or use `mirror`.");

    // property rows: one per distinct (position, normal, uv, colour)
    std::unordered_map<RowKey, std::uint32_t, RowKeyHash> rows;
    rows.reserve(s.tris.size() * 2);
    std::vector<std::uint32_t> repRow(s.pos.size(), UINT32_MAX);
    manifold::MeshGL64& g = out.mesh;
    g.numProp = kProps;
    g.triVerts.reserve(s.tris.size() * 3);
    g.faceID.reserve(s.tris.size());
    const bool colors = !m.colors.empty();
    hasColors = hasColors || colors;
    for (std::size_t t = 0; t < s.tris.size(); ++t) {
        for (int k = 0; k < 3; ++k) {
            const std::uint32_t w = s.tris[t][std::size_t(k)];
            const std::uint32_t mv = m.indices[std::size_t(s.src[t]) * 3 + std::size_t(k)];
            const Vec3 p = s.pos[w];
            const Vec3 n = mv < m.normals.size() ? m.normals[mv] : Vec3{0, 1, 0};
            const Vec2 uv = mv < m.uvs.size() ? m.uvs[mv] : Vec2{};
            const Vec4 c = colors && mv < m.colors.size() ? m.colors[mv] : Vec4{1, 1, 1, 1};
            const float vals[kProps] = {p.x, p.y, p.z, n.x, n.y, n.z, uv.x, uv.y, c.x, c.y, c.z, c.w};
            RowKey key;
            for (int q = 0; q < kProps; ++q) key.w[std::size_t(q)] = bits_of(vals[q]);
            auto [it, fresh] = rows.emplace(key, std::uint32_t(g.vertProperties.size() / kProps));
            if (fresh) {
                for (int q = 0; q < kProps; ++q) g.vertProperties.push_back(double(vals[q]));
                if (repRow[w] == UINT32_MAX)
                    repRow[w] = it->second;
                else {
                    g.mergeFromVert.push_back(it->second);
                    g.mergeToVert.push_back(repRow[w]);
                }
            }
            g.triVerts.push_back(it->second);
        }
        g.faceID.push_back(firstFace + std::uint64_t(t));
        facePart.push_back(s.part[t]);
    }
    out.triangles = s.tris.size();
    return out;
}

const char* status_text(manifold::Manifold::Error e) {
    using E = manifold::Manifold::Error;
    switch (e) {
        case E::NoError: return "no error";
        case E::NonFiniteVertex: return "a vertex is not a finite number";
        case E::NotManifold: return "the surface is not a closed manifold";
        case E::VertexOutOfBounds: return "an index is out of bounds";
        case E::ResultTooLarge: return "the result is too large for the library";
        case E::InvalidConstruction: return "the solid could not be built";
        default: return "the library refused the input";
    }
}

}  // namespace

Result<ModelMesh> model_boolean(const std::vector<ModelMesh>& operands, ModelBooleanMode mode,
                                const std::vector<std::string>& names) {
    if (operands.empty()) return ModelMesh{};
    std::size_t total = 0;
    for (const ModelMesh& m : operands) total += m.triangle_count();
    if (total > kModelMaxBooleanTriangles)
        return make_error(
            std::format("the boolean's solids have {} triangles together, more than the {} a boolean accepts", total,
                        kModelMaxBooleanTriangles),
            "Lower `segments` on the round primitives of its operands, or boolean smaller parts and combine them.");
    try {
        std::vector<manifold::Manifold> solids;
        std::vector<std::uint32_t> facePart;
        std::vector<std::size_t> firstFace;  // per kept operand
        std::vector<std::size_t> keptIndex;
        bool hasColors = false;
        bool emptyOperand = false;
        double smallest = 1e30;  // the volume of the smallest operand
        for (std::size_t i = 0; i < operands.size(); ++i) {
            const std::string name = operand_name(names, i);
            const std::size_t before = facePart.size();
            double volume = 0;
            auto prep = prepare(operands[i], name, std::uint32_t(before), facePart, hasColors, volume);
            if (!prep) return prep.error();
            if (prep->triangles == 0) {
                emptyOperand = true;
                if (mode == ModelBooleanMode::Difference && i == 0) return ModelMesh{};
                if (mode == ModelBooleanMode::Intersection) return ModelMesh{};
                continue;
            }
            manifold::Manifold solid(prep->mesh);
            if (solid.Status() != manifold::Manifold::Error::NoError)
                return make_error(std::format("{} could not be used as a solid: {}", name, status_text(solid.Status())),
                                  "Make sure it is closed and that no two of its faces cross each other.");
            smallest = std::min(smallest, volume);
            firstFace.push_back(before);
            keptIndex.push_back(i);
            solids.push_back(std::move(solid));
        }
        (void)emptyOperand;
        if (solids.empty()) return ModelMesh{};
        const manifold::OpType op = mode == ModelBooleanMode::Union        ? manifold::OpType::Add
                                    : mode == ModelBooleanMode::Difference ? manifold::OpType::Subtract
                                                                           : manifold::OpType::Intersect;
        manifold::Manifold result = solids.size() == 1 ? solids[0] : manifold::Manifold::BatchBoolean(solids, op);
        if (result.Status() != manifold::Manifold::Error::NoError)
            return make_error(std::format("the boolean failed: {}", status_text(result.Status())),
                              "Check that every operand is a closed solid.");
        manifold::MeshGL64 out = result.GetMeshGL64();
        ModelMesh mesh;
        const std::size_t tris = out.triVerts.size() / 3;
        if (tris > kModelMaxTriangles)
            return make_error(std::format("the boolean result has {} triangles, more than the {} a node may make", tris,
                                          kModelMaxTriangles),
                              "Lower `segments` on the operands.");
        const int np = int(out.numProp);
        const bool haveFace = out.faceID.size() == tris;
        // which operand (position among the kept ones) a face id belongs to: faces are numbered in operand order
        auto operand_of = [&](std::uint64_t face) {
            std::size_t k = 0;
            while (k + 1 < firstFace.size() && face >= firstFace[k + 1]) ++k;
            return k;
        };
        mesh.indices.reserve(tris * 3);
        mesh.triParts.reserve(tris);
        for (std::size_t t = 0; t < tris; ++t) {
            const std::uint64_t face = haveFace ? out.faceID[t] : 0;
            const bool turned = mode == ModelBooleanMode::Difference && haveFace && operand_of(face) > 0;
            mesh.triParts.push_back(haveFace && face < facePart.size() ? facePart[std::size_t(face)] : 0);
            for (int k = 0; k < 3; ++k) {
                const std::size_t v = std::size_t(out.triVerts[t * 3 + std::size_t(k)]) * std::size_t(np);
                const double* row = &out.vertProperties[v];
                mesh.positions.push_back({float(row[0]), float(row[1]), float(row[2])});
                Vec3 n{float(row[3]), float(row[4]), float(row[5])};
                if (turned) n = -n;
                mesh.normals.push_back(unit_or(n, Vec3{0, 1, 0}));
                mesh.uvs.push_back({float(row[6]), float(row[7])});
                if (hasColors) mesh.colors.push_back({float(row[8]), float(row[9]), float(row[10]), float(row[11])});
                mesh.indices.push_back(std::uint32_t(mesh.positions.size() - 1));
            }
        }
        ModelMesh cleaned = drop_degenerate(dedup_vertices(mesh));
        // solids that only touch can leave a sheet with no thickness: that is not a solid, there is nothing there
        if (!cleaned.empty()) {
            double vol = 0;
            for (std::size_t t = 0; t < cleaned.triangle_count(); ++t) {
                const Vec3 a = cleaned.positions[cleaned.indices[t * 3]],
                           b = cleaned.positions[cleaned.indices[t * 3 + 1]],
                           c = cleaned.positions[cleaned.indices[t * 3 + 2]];
                vol += double(dot(a, cross(b, c))) / 6.0;
            }
            if (vol <= 1e-7 * smallest) return ModelMesh{};
        }
        return cleaned;
    } catch (const std::exception& e) {
        return make_error(std::format("the boolean library stopped: {}", e.what()),
                          "Check that every operand is a closed solid with no self-intersections.");
    } catch (...) {
        return make_error("the boolean library stopped on an unknown error",
                          "Check that every operand is a closed solid with no self-intersections.");
    }
}

}  // namespace fa
