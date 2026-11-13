// Colliders for a mesh (model_game_ready.h): box, sphere and capsule fits, the convex hull (Manifold's quickhull, reduced with meshoptimizer's
// simplifier) and the convex decomposition of a concave mesh (V-HACD v4, synchronous: it starts no thread; its header is patched at configure
// time to keep its hulls in an ordered map and break ties in its merge queue, so every machine and standard library gives the same hulls).
#include <algorithm>
#include <cmath>
#include <format>
#include <map>
#include <set>

#include "vhacd_deterministic.h"
#include "fa/core/strings.h"
#include "fa/scene/model_game_ready.h"
#include "manifold/manifold.h"
#include "meshoptimizer.h"

namespace fa {

namespace {

double hull_volume(const ModelHull& h) {
    double v = 0;
    for (std::size_t i = 0; i + 2 < h.indices.size(); i += 3) {
        const Vec3 a = h.points[h.indices[i]], b = h.points[h.indices[i + 1]], c = h.points[h.indices[i + 2]];
        v += double(a.x) * (double(b.y) * c.z - double(b.z) * c.y) -
             double(a.y) * (double(b.x) * c.z - double(b.z) * c.x) +
             double(a.z) * (double(b.x) * c.y - double(b.y) * c.x);
    }
    return std::fabs(v) / 6.0;
}

double mesh_volume(const MeshData& m) {
    double v = 0;
    for (const MeshSubmesh& s : m.submeshes)
        for (std::size_t i = s.start; i + 2 < std::size_t(s.start) + s.count && i + 2 < m.indices.size(); i += 3) {
            const float* a = &m.positions[m.indices[i] * 3];
            const float* b = &m.positions[m.indices[i + 1] * 3];
            const float* c = &m.positions[m.indices[i + 2] * 3];
            v += double(a[0]) * (double(b[1]) * c[2] - double(b[2]) * c[1]) -
                 double(a[1]) * (double(b[0]) * c[2] - double(b[2]) * c[0]) +
                 double(a[2]) * (double(b[0]) * c[1] - double(b[1]) * c[0]);
        }
    return std::fabs(v) / 6.0;
}

// The hull of the points exactly, by Manifold's quickhull (serial; the same points give the same hull).
ModelHull exact_hull(const std::vector<Vec3>& pts) {
    ModelHull h;
    if (pts.size() < 4) return h;
    std::vector<manifold::vec3> in;
    in.reserve(pts.size());
    for (const Vec3& p : pts) in.push_back({double(p.x), double(p.y), double(p.z)});
    manifold::Manifold m = manifold::Manifold::Hull(in);
    if (m.Status() != manifold::Manifold::Error::NoError || m.IsEmpty()) return h;
    const manifold::MeshGL64 g = m.GetMeshGL64();
    const std::size_t np = std::size_t(g.numProp);
    for (std::size_t v = 0; v < g.vertProperties.size() / np; ++v)
        h.points.push_back({float(g.vertProperties[v * np]), float(g.vertProperties[v * np + 1]),
                            float(g.vertProperties[v * np + 2])});
    for (std::uint64_t i : g.triVerts) h.indices.push_back(std::uint32_t(i));
    h.volume = hull_volume(h);
    if (h.volume <= 1e-12) return ModelHull{};  // flat points have no hull
    return h;
}

}  // namespace

ModelHull model_convex_hull(const std::vector<Vec3>& points, int maxVertices) {
    maxVertices = std::clamp(maxVertices, 4, kGameReadyMaxHullVertices);
    ModelHull h = exact_hull(points);
    // Too many points: let the simplifier pick the ones that matter (it never moves a vertex here), then take the hull of those. Each round asks
    // for fewer triangles; a convex hull of V points has 2V - 4.
    std::size_t target = std::size_t(maxVertices) * 2 - 4;
    for (int round = 0; round < 12 && h.points.size() > std::size_t(maxVertices); ++round) {
        std::vector<float> flat;
        for (const Vec3& p : h.points) {
            flat.push_back(p.x);
            flat.push_back(p.y);
            flat.push_back(p.z);
        }
        std::vector<std::uint32_t> idx(h.indices.size());
        const std::size_t n =
            meshopt_simplify(idx.data(), h.indices.data(), h.indices.size(), flat.data(), h.points.size(), 12,
                             target * 3, 1e30f, meshopt_SimplifyErrorAbsolute, nullptr);
        idx.resize(n);
        std::set<std::uint32_t> used(idx.begin(), idx.end());
        std::vector<Vec3> kept;
        for (std::uint32_t v : used) kept.push_back(h.points[v]);
        ModelHull next = exact_hull(kept);
        if (next.points.empty()) break;
        h = std::move(next);
        target = std::max<std::size_t>(4, target * 4 / 5);
    }
    return h;
}

MeshData model_hull_mesh(const ModelHull& h) {
    // flat shaded: one vertex per triangle corner
    MeshInput in;
    for (std::size_t t = 0; t < h.indices.size() / 3; ++t) {
        const Vec3 a = h.points[h.indices[t * 3]], b = h.points[h.indices[t * 3 + 1]],
                   c = h.points[h.indices[t * 3 + 2]];
        const Vec3 n = normalize(cross(b - a, c - a));
        for (const Vec3& p : {a, b, c}) {
            in.positions.insert(in.positions.end(), {p.x, p.y, p.z});
            in.normals.insert(in.normals.end(), {n.x, n.y, n.z});
        }
    }
    in.hasIndices = false;
    auto built = build_mesh_data(in);
    return built.ok() ? std::move(*built) : MeshData{};
}

Result<ModelCollider> model_fit_collider(const MeshData& m, const ModelColliderSpec& spec) {
    if (m.indices.empty() || m.submeshes.empty())
        return make_error("the mesh has no triangles to fit a collider to",
                          "Fit a collider to a mesh that has triangles.");
    if (!spec.part.empty()) {
        // the submeshes of one part (a merged submesh lists its parts joined with "+")
        MeshData sub = m;
        sub.submeshes.clear();
        std::vector<std::string> names;
        for (const MeshSubmesh& s : m.submeshes) {
            std::size_t from = 0;
            bool hit = false;
            while (from <= s.part.size()) {
                std::size_t plus = s.part.find('+', from);
                if (plus == std::string::npos) plus = s.part.size();
                const std::string one = s.part.substr(from, plus - from);
                if (!one.empty() && std::find(names.begin(), names.end(), one) == names.end()) names.push_back(one);
                hit = hit || one == spec.part;
                from = plus + 1;
            }
            if (hit) sub.submeshes.push_back(s);
        }
        if (sub.submeshes.empty()) {
            std::string list;
            for (const std::string& n : names) list += (list.empty() ? "" : ", ") + n;
            return make_error(
                "the model has no part named '" + spec.part + "' to fit the collider to",
                (names.empty() ? std::string("The model has no named parts: give nodes a `part` (docs/MODELING.md).")
                               : did_you_mean(spec.part, names) + " The parts are: " + list + "."));
        }
        ModelColliderSpec whole = spec;
        whole.part.clear();
        auto r = model_fit_collider(sub, whole);
        if (r.ok()) r->warnings.insert(r->warnings.begin(), "fitted to the part '" + spec.part + "' only.");
        return r;
    }
    ModelCollider c;
    c.shape = spec.shape;
    // the points of the triangles that are drawn
    std::vector<Vec3> pts;
    {
        std::set<std::uint32_t> used;
        for (const MeshSubmesh& s : m.submeshes)
            for (std::size_t i = s.start; i < std::size_t(s.start) + s.count && i < m.indices.size(); ++i)
                used.insert(m.indices[i]);
        for (std::uint32_t v : used)
            pts.push_back({m.positions[v * 3], m.positions[v * 3 + 1], m.positions[v * 3 + 2]});
    }
    if (pts.empty()) return make_error("the mesh has no drawn triangles", "Check its submeshes.");
    Vec3 lo = pts[0], hi = pts[0];
    for (const Vec3& p : pts) {
        lo = min(lo, p);
        hi = max(hi, p);
    }
    const Vec3 mid = (lo + hi) * 0.5f, size = hi - lo;
    c.meshVolume = mesh_volume(m);
    const double pi = 3.14159265358979323846;

    if (spec.shape == "none") {
        return c;
    } else if (spec.shape == "box") {
        c.center = mid;
        c.size = size;
        c.volume = double(size.x) * size.y * size.z;
    } else if (spec.shape == "sphere") {
        float r2 = 0;
        for (const Vec3& p : pts) r2 = std::max(r2, length_sq(p - mid));
        c.center = mid;
        c.radius = spec.radius > 0 ? float(spec.radius) : std::sqrt(r2);
        c.volume = 4.0 / 3.0 * pi * double(c.radius) * c.radius * c.radius;
    } else if (spec.shape == "capsule") {
        // along Y, the way Collider3D's capsule stands: the radius reaches the farthest point from the axis through the middle
        float r2 = 0;
        for (const Vec3& p : pts) r2 = std::max(r2, (p.x - mid.x) * (p.x - mid.x) + (p.z - mid.z) * (p.z - mid.z));
        c.center = mid;
        c.radius = std::min(std::sqrt(r2), size.y * 0.5f);
        c.height = std::max(size.y, 2 * c.radius);
        const bool wide = std::sqrt(r2) > size.y * 0.5f + 1e-6f && spec.radius <= 0;
        if (spec.radius > 0) c.radius = float(spec.radius);
        if (spec.height > 0) c.height = float(spec.height);
        if (spec.height > 0 && c.height < 2 * c.radius)
            c.warnings.push_back(
                std::format("collider.height {:.3g} is less than twice the radius ({:.3g}), so the capsule was made "
                            "{:.3g} tall: a capsule is never shorter than its two caps. "
                            "Give a height of at least {:.3g}, or a smaller collider.radius, or use shape \"sphere\".",
                            double(spec.height), double(c.radius), double(2 * c.radius), double(2 * c.radius)));
        c.height = std::max(c.height, 2 * c.radius);
        if (wide)
            c.warnings.push_back("the model is wider than it is tall, so a capsule standing on Y clips its sides; use "
                                 "a box or sphere, or lay it out along Y.");
        const double r = c.radius;
        c.volume = pi * r * r * (double(c.height) - 2 * r) + 4.0 / 3.0 * pi * r * r * r;
    } else if (spec.shape == "convex") {
        ModelHull h = model_convex_hull(pts, spec.maxVertices);
        if (h.points.empty())
            return make_error("the mesh is flat or has fewer than four distinct points, so it has no convex hull",
                              "Use a box collider for a flat mesh.");
        c.volume = h.volume;
        c.hulls.push_back(std::move(h));
    } else if (spec.shape == "decomposed") {
        std::vector<float> flat;
        std::vector<std::uint32_t> remap(m.vertex_count(), 0xFFFFFFFFu);
        std::vector<std::uint32_t> idx;
        for (const MeshSubmesh& s : m.submeshes)
            for (std::size_t i = s.start; i < std::size_t(s.start) + s.count && i < m.indices.size(); ++i) {
                const std::uint32_t v = m.indices[i];
                if (remap[v] == 0xFFFFFFFFu) {
                    remap[v] = std::uint32_t(flat.size() / 3);
                    flat.insert(flat.end(), {m.positions[v * 3], m.positions[v * 3 + 1], m.positions[v * 3 + 2]});
                }
                idx.push_back(remap[v]);
            }
        VHACD::IVHACD* vhacd = VHACD::CreateVHACD();  // the synchronous one: no threads
        VHACD::IVHACD::Parameters p;
        p.m_asyncACD = false;
        p.m_maxConvexHulls = std::uint32_t(spec.maxHulls);
        p.m_resolution = std::uint32_t(spec.resolution);
        p.m_maxNumVerticesPerCH = std::uint32_t(spec.maxVertices);
        p.m_shrinkWrap = true;
        p.m_fillMode = VHACD::FillMode::FLOOD_FILL;
        const bool ok =
            vhacd->Compute(flat.data(), std::uint32_t(flat.size() / 3), idx.data(), std::uint32_t(idx.size() / 3), p);
        if (ok) {
            for (std::uint32_t i = 0; i < vhacd->GetNConvexHulls(); ++i) {
                VHACD::IVHACD::ConvexHull ch;
                if (!vhacd->GetConvexHull(i, ch)) continue;
                std::vector<Vec3> hp;
                for (const VHACD::Vertex& v : ch.m_points) hp.push_back({float(v.mX), float(v.mY), float(v.mZ)});
                ModelHull h =
                    model_convex_hull(hp, spec.maxVertices);  // exact hull of V-HACD's points, within the vertex limit
                if (h.points.empty() || h.volume <= 1e-12) continue;
                c.volume += h.volume;
                c.hulls.push_back(std::move(h));
            }
        }
        vhacd->Release();
        if (c.hulls.empty()) {
            ModelHull h = model_convex_hull(pts, spec.maxVertices);
            if (h.points.empty())
                return make_error("the mesh could not be decomposed and is too flat for a convex hull",
                                  "Use a box collider.");
            c.warnings.push_back("the decomposition produced no pieces (the mesh may be too thin for the resolution), "
                                 "so the collider is the convex hull; raise `resolution`.");
            c.volume = h.volume;
            c.hulls.push_back(std::move(h));
            c.shape = "convex";
        }
    } else {
        return make_error("unknown collider shape '" + spec.shape + "'",
                          "Use none, box, sphere, capsule, convex or decomposed.");
    }
    if (c.meshVolume > 1e-12) {
        c.volumeRatio = c.volume / c.meshVolume;
        if (c.volumeRatio > 3.0)
            c.warnings.push_back(
                std::format("the {} is {:.1f} times the volume of the mesh: things will bump into empty space. Try {}.",
                            c.shape, c.volumeRatio,
                            c.shape == "box" || c.shape == "sphere" || c.shape == "capsule"
                                ? "\"convex\" or \"decomposed\""
                                : "a higher `resolution` or more `maxHulls`"));
    } else {
        c.warnings.push_back(
            "the mesh is not a closed solid, so the collider's fit cannot be measured against its volume.");
    }
    return c;
}

}  // namespace fa
