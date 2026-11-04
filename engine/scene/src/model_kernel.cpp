// ModelMesh operations (merge, transform, bounds) and the mesh measurements of fa/scene/model_kernel.h.
#include <array>
#include <cmath>
#include <map>
#include <utility>

#include "fa/scene/model_kernel.h"

namespace fa {

void ModelMesh::append(const ModelMesh& o) {
    if (o.positions.empty()) return;
    triParts.resize(triangle_count(), 0);
    const std::uint32_t base = std::uint32_t(positions.size());
    if (!colors.empty() || !o.colors.empty()) {
        colors.resize(positions.size(), Vec4{1, 1, 1, 1});
        if (o.colors.empty()) colors.resize(colors.size() + o.positions.size(), Vec4{1, 1, 1, 1});
        else colors.insert(colors.end(), o.colors.begin(), o.colors.end());
    }
    positions.insert(positions.end(), o.positions.begin(), o.positions.end());
    normals.insert(normals.end(), o.normals.begin(), o.normals.end());
    uvs.insert(uvs.end(), o.uvs.begin(), o.uvs.end());
    indices.reserve(indices.size() + o.indices.size());
    for (std::uint32_t i : o.indices) indices.push_back(i + base);
    if (o.triParts.size() == o.triangle_count()) triParts.insert(triParts.end(), o.triParts.begin(), o.triParts.end());
    else triParts.resize(triangle_count(), 0);
}

void ModelMesh::transform(const Mat4& m) {
    const Vec3 c0{m.at(0, 0), m.at(0, 1), m.at(0, 2)}, c1{m.at(1, 0), m.at(1, 1), m.at(1, 2)}, c2{m.at(2, 0), m.at(2, 1), m.at(2, 2)};
    // The normal matrix is the inverse transpose of the upper 3x3; its columns are these cross products divided by the determinant.
    const Vec3 n0 = cross(c1, c2), n1 = cross(c2, c0), n2 = cross(c0, c1);
    const float det = dot(c0, n0);
    const float sgn = det < 0 ? -1.0f : 1.0f;
    for (Vec3& p : positions) p = m.transform_point(p);
    for (Vec3& n : normals) {
        const Vec3 t = (n0 * n.x + n1 * n.y + n2 * n.z) * sgn;
        const Vec3 u = normalize(t);
        if (length_sq(u) > 0.5f) n = u;
    }
    if (det < 0)
        for (std::size_t i = 0; i + 2 < indices.size(); i += 3) std::swap(indices[i + 1], indices[i + 2]);
}

void ModelMesh::set_part(std::uint32_t part) { triParts.assign(triangle_count(), part); }

void ModelMesh::set_color(Vec4 rgba) { colors.assign(positions.size(), rgba); }

void ModelMesh::bounds(Vec3& bmin, Vec3& bmax) const {
    if (positions.empty()) {
        bmin = bmax = {};
        return;
    }
    bmin = bmax = positions[0];
    for (const Vec3& p : positions) {
        bmin = min(bmin, p);
        bmax = max(bmax, p);
    }
}

ModelMeshStats model_mesh_stats(const ModelMesh& m) {
    ModelMeshStats s;
    s.vertices = m.vertex_count();
    s.triangles = m.triangle_count();
    m.bounds(s.bmin, s.bmax);
    // weld the positions to 1e-5 so the seams made for uvs and hard edges do not count as holes
    std::map<std::array<long long, 3>, std::uint32_t> ids;
    std::vector<std::uint32_t> weld(m.positions.size());
    for (std::size_t i = 0; i < m.positions.size(); ++i) {
        const Vec3& p = m.positions[i];
        const std::array<long long, 3> key{std::llround(double(p.x) * 1e5), std::llround(double(p.y) * 1e5), std::llround(double(p.z) * 1e5)};
        auto it = ids.find(key);
        if (it == ids.end()) it = ids.emplace(key, std::uint32_t(ids.size())).first;
        weld[i] = it->second;
    }
    s.weldedVertices = ids.size();
    struct EdgeUse {
        int forward = 0, backward = 0;
    };
    std::map<std::pair<std::uint32_t, std::uint32_t>, EdgeUse> edges;
    for (std::size_t t = 0; t < m.triangle_count(); ++t) {
        const std::uint32_t i0 = m.indices[t * 3], i1 = m.indices[t * 3 + 1], i2 = m.indices[t * 3 + 2];
        const Vec3 a = m.positions[i0], b = m.positions[i1], c = m.positions[i2];
        const Vec3 cr = cross(b - a, c - a);
        const double dbl = std::sqrt(double(cr.x) * cr.x + double(cr.y) * cr.y + double(cr.z) * cr.z);
        s.area += dbl * 0.5;
        s.volume += (double(a.x) * (double(b.y) * c.z - double(b.z) * c.y) - double(a.y) * (double(b.x) * c.z - double(b.z) * c.x) +
                     double(a.z) * (double(b.x) * c.y - double(b.y) * c.x)) / 6.0;
        const std::uint32_t w[3] = {weld[i0], weld[i1], weld[i2]};
        if (dbl < 1e-12 || w[0] == w[1] || w[1] == w[2] || w[0] == w[2]) {
            ++s.degenerateTriangles;
            continue;
        }
        for (int e = 0; e < 3; ++e) {
            const std::uint32_t from = w[e], to = w[(e + 1) % 3];
            if (from < to) ++edges[{from, to}].forward;
            else ++edges[{to, from}].backward;
        }
    }
    for (const auto& [key, use] : edges) {
        const int total = use.forward + use.backward;
        if (total == 1) ++s.boundaryEdges;
        else if (total > 2 || use.forward != use.backward) ++s.nonManifoldEdges;
    }
    return s;
}

}  // namespace fa
