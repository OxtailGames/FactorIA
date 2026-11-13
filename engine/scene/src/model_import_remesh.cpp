// The remesh of model.import_clean (model_import_clean.h): a mesh with holes, non-manifold edges or self-intersections is turned into the surface of
// its thickened distance field. The unsigned distance to the triangles is sampled on a grid near the surface; the grid's border is flood-filled
// through the cells farther than the thickness to tell outside from inside; the shell is `distance - thickness` and the enclosed cells are
// negative (a chamfer distance from the shell), so the field is a signed one and the SDF mesher (model_sdf.h, a `Volume` shape) makes a closed
// manifold surface of it. The surface is then moved back by the thickness, and parts, vertex colours and texture colours come from the nearest
// source triangle. Deterministic: serial, + - * / and sqrt.
#include <algorithm>
#include <cmath>
#include <format>
#include <limits>

#include "fa/core/det_math.h"
#include "fa/scene/model_import_clean.h"
#include "fa/scene/model_sdf.h"

namespace fa {

namespace {

// The thickened surface is moved back inward by this share of the thickness: 1 would put a closed solid's wall exactly where it was but collapse a thin sheet's
// two walls onto each other (zero volume, coincident triangles); a little less keeps the wall within a fraction of a cell and leaves a sheet a thin shell.
constexpr float kMoveBack = 0.75f;

struct Closest {
    Vec3 point;
    float u = 0, v = 0, w = 0;  // barycentric of the closest point (a + u*ab... as weights of a, b, c)
    float distSq = 0;
};

// Ericson, Real-Time Collision Detection 5.1.5.
Closest closest_on_triangle(Vec3 p, Vec3 a, Vec3 b, Vec3 c) {
    const Vec3 ab = b - a, ac = c - a, ap = p - a;
    const float d1 = dot(ab, ap), d2 = dot(ac, ap);
    auto done = [&](Vec3 q, float wa, float wb, float wc) { return Closest{q, wa, wb, wc, length_sq(p - q)}; };
    if (d1 <= 0 && d2 <= 0) return done(a, 1, 0, 0);
    const Vec3 bp = p - b;
    const float d3 = dot(ab, bp), d4 = dot(ac, bp);
    if (d3 >= 0 && d4 <= d3) return done(b, 0, 1, 0);
    const float vc = d1 * d4 - d3 * d2;
    if (vc <= 0 && d1 >= 0 && d3 <= 0) {
        const float v = d1 / (d1 - d3);
        return done(a + ab * v, 1 - v, v, 0);
    }
    const Vec3 cp = p - c;
    const float d5 = dot(ab, cp), d6 = dot(ac, cp);
    if (d6 >= 0 && d5 <= d6) return done(c, 0, 0, 1);
    const float vb = d5 * d2 - d1 * d6;
    if (vb <= 0 && d2 >= 0 && d6 <= 0) {
        const float w = d2 / (d2 - d6);
        return done(a + ac * w, 1 - w, 0, w);
    }
    const float va = d3 * d6 - d5 * d4;
    if (va <= 0 && (d4 - d3) >= 0 && (d5 - d6) >= 0) {
        const float w = (d4 - d3) / ((d4 - d3) + (d5 - d6));
        return done(b + (c - b) * w, 0, 1 - w, w);
    }
    const float denom = 1.0f / (va + vb + vc);
    const float v = vb * denom, w = vc * denom;
    return done(a + ab * v + ac * w, 1 - v - w, v, w);
}

}  // namespace

Result<ModelMesh> model_remesh_mesh(const ModelMesh& mesh, double voxelIn, int cells,
                                    const std::vector<std::string>& groupMaterial, const ModelTextureSampler& sampler,
                                    ModelRemeshInfo* info) {
    if (mesh.empty()) return make_error("remesh: the mesh has no triangles", "Give a mesh with at least one triangle.");
    Vec3 lo{}, hi{};
    mesh.bounds(lo, hi);
    const Vec3 size = hi - lo;
    const float longest = std::max({size.x, size.y, size.z, 1e-6f});
    float cell = voxelIn > 0 ? float(voxelIn) : longest / float(std::max(cells, 16));
    if (!(cell > 0))
        return make_error("remesh: the voxel size is not positive",
                          "Pass `remeshVoxel` > 0 or `remeshCells` between 16 and 400.");
    const float thick = 0.6f * cell;
    const float band = thick + 2.0f * cell;
    const float pad = band + cell;
    const Vec3 origin = lo - Vec3{pad, pad, pad};
    const int nx = int(std::ceil((size.x + 2 * pad) / cell)) + 1, ny = int(std::ceil((size.y + 2 * pad) / cell)) + 1,
              nz = int(std::ceil((size.z + 2 * pad) / cell)) + 1;
    const std::size_t total = std::size_t(nx) * std::size_t(ny) * std::size_t(nz);
    if (total > kModelSdfMaxSamples) {
        const double fit = det::f64::cbrt(double(size.x + 2 * pad) * double(size.y + 2 * pad) *
                                          double(size.z + 2 * pad) / double(kModelSdfMaxSamples)) *
                           1.1;
        return make_error(std::format("remesh: a {:.4g} m voxel needs {}x{}x{} = {} samples, more than the {} allowed",
                                      double(cell), nx, ny, nz, total, kModelSdfMaxSamples),
                          std::format("Use a voxel of at least {:.3g} m (`remeshVoxel`) or fewer `remeshCells`.", fit));
    }
    auto idx = [&](int x, int y, int z) {
        return (std::size_t(z) * std::size_t(ny) + std::size_t(y)) * std::size_t(nx) + std::size_t(x);
    };

    // ---- unsigned distance near the triangles ----
    constexpr float kFar = 1e30f;
    std::vector<float> dist(total, kFar);
    std::vector<std::int32_t> nearest(total, -1);
    std::size_t tests = 0;
    const std::size_t tris = mesh.triangle_count();
    for (std::size_t t = 0; t < tris; ++t) {
        const Vec3 a = mesh.positions[mesh.indices[t * 3]], b = mesh.positions[mesh.indices[t * 3 + 1]],
                   c = mesh.positions[mesh.indices[t * 3 + 2]];
        const Vec3 tl = min(min(a, b), c) - Vec3{band, band, band}, th = max(max(a, b), c) + Vec3{band, band, band};
        const int x0 = std::max(0, int(std::floor((tl.x - origin.x) / cell))),
                  x1 = std::min(nx - 1, int(std::ceil((th.x - origin.x) / cell)));
        const int y0 = std::max(0, int(std::floor((tl.y - origin.y) / cell))),
                  y1 = std::min(ny - 1, int(std::ceil((th.y - origin.y) / cell)));
        const int z0 = std::max(0, int(std::floor((tl.z - origin.z) / cell))),
                  z1 = std::min(nz - 1, int(std::ceil((th.z - origin.z) / cell)));
        tests += std::size_t(std::max(0, x1 - x0 + 1)) * std::size_t(std::max(0, y1 - y0 + 1)) *
                 std::size_t(std::max(0, z1 - z0 + 1));
        if (tests > 400000000u)
            return make_error(
                "remesh: the triangles are too large for this voxel size (the distance field would take too long)",
                "Use a bigger voxel (`remeshVoxel`) or fewer `remeshCells`.");
        for (int z = z0; z <= z1; ++z)
            for (int y = y0; y <= y1; ++y)
                for (int x = x0; x <= x1; ++x) {
                    const Vec3 p = origin + Vec3{float(x) * cell, float(y) * cell, float(z) * cell};
                    const float d2 = closest_on_triangle(p, a, b, c).distSq;
                    const std::size_t i = idx(x, y, z);
                    const float d = std::sqrt(d2);
                    if (d < dist[i]) {
                        dist[i] = d;
                        nearest[i] = std::int32_t(t);
                    }
                }
    }
    // ---- outside: flood from the border through the cells farther than the thickness ----
    std::vector<char> outside(total, 0);
    std::vector<std::uint32_t> stack;
    auto push = [&](int x, int y, int z) {
        const std::size_t i = idx(x, y, z);
        if (outside[i] || dist[i] <= thick) return;
        outside[i] = 1;
        stack.push_back(std::uint32_t(i));
    };
    for (int z = 0; z < nz; ++z)
        for (int y = 0; y < ny; ++y)
            for (int x = 0; x < nx; ++x)
                if (x == 0 || y == 0 || z == 0 || x == nx - 1 || y == ny - 1 || z == nz - 1) push(x, y, z);
    while (!stack.empty()) {
        const std::uint32_t i = stack.back();
        stack.pop_back();
        const int x = int(i % std::uint32_t(nx)), y = int((i / std::uint32_t(nx)) % std::uint32_t(ny)),
                  z = int(i / (std::uint32_t(nx) * std::uint32_t(ny)));
        if (x > 0) push(x - 1, y, z);
        if (x < nx - 1) push(x + 1, y, z);
        if (y > 0) push(x, y - 1, z);
        if (y < ny - 1) push(x, y + 1, z);
        if (z > 0) push(x, y, z - 1);
        if (z < nz - 1) push(x, y, z + 1);
    }
    // ---- the signed field ----
    auto vol = std::make_shared<ModelSdfVolume>();
    vol->origin = origin;
    vol->cell = cell;
    vol->nx = nx;
    vol->ny = ny;
    vol->nz = nz;
    vol->values.assign(total, 0);
    const float eps = cell * 0.05f;
    std::vector<float> depth(total, kFar);  // cells enclosed by the shell: how deep inside
    for (std::size_t i = 0; i < total; ++i) {
        if (outside[i]) {
            vol->values[i] = std::min(dist[i], band + cell) - thick;
        } else if (dist[i] <= thick) {
            vol->values[i] = std::min(dist[i] - thick, -eps);
            depth[i] = thick - dist[i];
        }
    }
    // 26-neighbour chamfer, forward and backward, over the enclosed cells only
    struct Off {
        int dx, dy, dz;
        float w;
    };
    std::vector<Off> fwd, bwd;
    for (int dz = -1; dz <= 1; ++dz)
        for (int dy = -1; dy <= 1; ++dy)
            for (int dx = -1; dx <= 1; ++dx) {
                if (!dx && !dy && !dz) continue;
                const int n = (dx != 0) + (dy != 0) + (dz != 0);
                const float w = cell * (n == 1 ? 1.0f : n == 2 ? 1.41421356f : 1.73205081f);
                const bool before = dz < 0 || (dz == 0 && (dy < 0 || (dy == 0 && dx < 0)));
                (before ? fwd : bwd).push_back({dx, dy, dz, w});
            }
    auto relax = [&](int x, int y, int z, const std::vector<Off>& offs) {
        const std::size_t i = idx(x, y, z);
        if (outside[i] || dist[i] <= thick) return;
        for (const Off& o : offs) {
            const int X = x + o.dx, Y = y + o.dy, Z = z + o.dz;
            if (X < 0 || Y < 0 || Z < 0 || X >= nx || Y >= ny || Z >= nz) continue;
            const float c = depth[idx(X, Y, Z)] + o.w;
            if (c < depth[i]) depth[i] = c;
        }
    };
    for (int z = 0; z < nz; ++z)
        for (int y = 0; y < ny; ++y)
            for (int x = 0; x < nx; ++x) relax(x, y, z, fwd);
    for (int z = nz - 1; z >= 0; --z)
        for (int y = ny - 1; y >= 0; --y)
            for (int x = nx - 1; x >= 0; --x) relax(x, y, z, bwd);
    for (std::size_t i = 0; i < total; ++i)
        if (!outside[i] && dist[i] > thick)
            vol->values[i] = depth[i] >= kFar * 0.5f ? -thick : -std::max(depth[i], eps);

    // ---- mesh ----
    ModelSdf sdf;
    ModelSdfShapeParams sp;
    sp.shape = ModelSdfShape::Volume;
    sp.volume = vol;
    const int node = sdf.add_shape(sp, Mat4::identity(), ModelSdfBlend::Union, 0, 0, std::nullopt);
    sdf.set_root(node);
    ModelSdfMeshParams mp;
    mp.voxelSize = cell;
    mp.uvs = false;
    mp.maxError = 0;  // the voxel grid is the detail; the caller decimates to its budget
    ModelSdfMeshInfo minfo;
    auto meshed = model_sdf_mesh(sdf, mp, &minfo);
    if (!meshed) return make_error("remesh: " + meshed.error().message, meshed.error().hint);
    ModelMesh out = std::move(*meshed);
    if (info) {
        info->voxel = cell;
        info->rawTriangles = minfo.rawTriangles;
        info->triangles = out.triangle_count();
        info->gx = std::size_t(nx);
        info->gy = std::size_t(ny);
        info->gz = std::size_t(nz);
    }
    if (out.empty()) return out;
    for (std::size_t v = 0; v < out.positions.size(); ++v)
        out.positions[v] = out.positions[v] - out.normals[v] * (thick * kMoveBack);

    // ---- parts and colours from the nearest source triangle ----
    auto nearest_triangle = [&](Vec3 p, Closest& best) -> std::int32_t {
        const int cx = int(std::floor((p.x - origin.x) / cell + 0.5f)),
                  cy = int(std::floor((p.y - origin.y) / cell + 0.5f)),
                  cz = int(std::floor((p.z - origin.z) / cell + 0.5f));
        std::int32_t bestT = -1;
        float bestD = std::numeric_limits<float>::max();
        for (int r = 1; r <= 3 && bestT < 0; ++r)
            for (int dz = -r; dz <= r; ++dz)
                for (int dy = -r; dy <= r; ++dy)
                    for (int dx = -r; dx <= r; ++dx) {
                        const int X = cx + dx, Y = cy + dy, Z = cz + dz;
                        if (X < 0 || Y < 0 || Z < 0 || X >= nx || Y >= ny || Z >= nz) continue;
                        const std::int32_t t = nearest[idx(X, Y, Z)];
                        if (t < 0) continue;
                        const Closest c = closest_on_triangle(p, mesh.positions[mesh.indices[std::size_t(t) * 3]],
                                                              mesh.positions[mesh.indices[std::size_t(t) * 3 + 1]],
                                                              mesh.positions[mesh.indices[std::size_t(t) * 3 + 2]]);
                        if (c.distSq < bestD) {
                            bestD = c.distSq;
                            bestT = t;
                            best = c;
                        }
                    }
        return bestT;
    };
    const bool srcColors = !mesh.colors.empty();
    bool anyTexture = false;
    std::vector<Vec4> colors(out.positions.size(), Vec4{1, 1, 1, 1});
    for (std::size_t v = 0; v < out.positions.size(); ++v) {
        Closest c;
        const std::int32_t t = nearest_triangle(out.positions[v], c);
        if (t < 0) continue;
        const std::uint32_t* ti = &mesh.indices[std::size_t(t) * 3];
        Vec4 col{1, 1, 1, 1};
        if (srcColors) col = mesh.colors[ti[0]] * c.u + mesh.colors[ti[1]] * c.v + mesh.colors[ti[2]] * c.w;
        if (sampler) {
            const std::uint32_t part = mesh.triParts.empty() ? 0 : mesh.triParts[std::size_t(t)];
            if (part < groupMaterial.size() && !groupMaterial[part].empty()) {
                const Vec2 uv = mesh.uvs[ti[0]] * c.u + mesh.uvs[ti[1]] * c.v + mesh.uvs[ti[2]] * c.w;
                if (auto tex = sampler(groupMaterial[part], uv)) {
                    col = {col.x * tex->x, col.y * tex->y, col.z * tex->z, col.w * tex->w};
                    anyTexture = true;
                }
            }
        }
        colors[v] = col;
    }
    if (srcColors || anyTexture)
        out.colors = std::move(colors);
    else
        out.colors.clear();
    if (info) info->texturesToColors = anyTexture;
    out.triParts.assign(out.triangle_count(), 0);
    if (!mesh.triParts.empty())
        for (std::size_t t = 0; t < out.triangle_count(); ++t) {
            const Vec3 centre = (out.positions[out.indices[t * 3]] + out.positions[out.indices[t * 3 + 1]] +
                                 out.positions[out.indices[t * 3 + 2]]) /
                                3.0f;
            Closest c;
            const std::int32_t s = nearest_triangle(centre, c);
            out.triParts[t] = s >= 0 ? mesh.triParts[std::size_t(s)] : 0;
        }
    out.uvs.assign(out.positions.size(), Vec2{0, 0});
    return out;
}

}  // namespace fa
