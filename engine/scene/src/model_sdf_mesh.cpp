// Meshing a signed-distance field (model_sdf.h): marching tetrahedra on the Kuhn subdivision of a regular grid, vertices moved onto the exact
// zero of the field, quadric decimation, then normals, colours and uvs from the field.
//
// Why marching tetrahedra and not surface nets or dual contouring. Those place one vertex per cell and so need rules for the cells where the
// sign pattern is ambiguous (two opposite corners inside); where a thin part or a tight blend passes through such a cell they leave
// non-manifold edges or pinched vertices, and a boolean or a bevel later refuses the mesh. The cube is cut into six tetrahedra around its main
// diagonal in the same way in every cell, so neighbouring cells agree on the diagonal of their shared face, and the surface of the piecewise
// linear field inside a tetrahedron has no ambiguous case: the result is a closed 2-manifold whatever the field does, by construction. The
// price is more, thinner triangles; the decimation after it (model_decimate.h) removes them where the surface is flat. Sharp features are
// not recovered (the field is sampled, not differentiated), which suits organic shapes: smooth blends are what the SDF tree is for.
#include <algorithm>
#include <cmath>
#include <format>
#include <unordered_map>

#include "fa/scene/model_decimate.h"
#include "fa/scene/model_sdf.h"

namespace fa {

namespace {

constexpr int kTets[6][4] = {{0, 1, 3, 7}, {0, 1, 5, 7}, {0, 2, 3, 7}, {0, 2, 6, 7}, {0, 4, 5, 7}, {0, 4, 6, 7}};

struct Field {
    const ModelSdf& sdf;
    float noiseAmp, noiseFreq;
    int noiseOctaves, noiseSeed;
    float operator()(Vec3 p) const {
        float d = sdf.distance(p);
        if (noiseAmp != 0) d += noiseAmp * model_sdf_noise(p, noiseFreq, noiseOctaves, noiseSeed);
        return d;
    }
};

std::string metres(double v) { return std::format("{:.4g}", v); }

}  // namespace

Result<ModelMesh> model_sdf_mesh(const ModelSdf& sdf, const ModelSdfMeshParams& P, ModelSdfMeshInfo* infoOut) {
    ModelSdfMeshInfo info;
    ModelMesh mesh;
    auto done = [&]() {
        if (infoOut) *infoOut = info;
    };
    Vec3 lo{}, hi{};
    if (!sdf.bounds(lo, hi) || sdf.leaf_count() == 0) {
        done();
        return mesh;
    }
    const Field field{sdf, P.noiseAmplitude, P.noiseFrequency, P.noiseOctaves, P.noiseSeed};
    const float margin = std::fabs(P.noiseAmplitude);
    lo = lo - Vec3{margin, margin, margin};
    hi = hi + Vec3{margin, margin, margin};
    const Vec3 ext0 = hi - lo;
    const float longest = std::max(ext0.x, std::max(ext0.y, ext0.z));
    float h = P.voxelSize > 0 ? P.voxelSize : longest / float(std::max(P.cells, 4));
    h = std::max(h, 1.0e-4f);
    const float pad = 2.0f * h;
    const Vec3 origin = lo - Vec3{pad, pad, pad};
    const Vec3 ext = ext0 + Vec3{2 * pad, 2 * pad, 2 * pad};
    const double gx = std::ceil(double(ext.x) / h) + 1, gy = std::ceil(double(ext.y) / h) + 1, gz = std::ceil(double(ext.z) / h) + 1;
    const double samplesD = gx * gy * gz;
    const double costD = samplesD * double(sdf.leaf_count());
    if (samplesD > double(kModelSdfMaxSamples) || costD > double(kModelSdfMaxCost)) {
        const double byMemory = std::cbrt(samplesD / double(kModelSdfMaxSamples)), byCost = std::cbrt(costD / double(kModelSdfMaxCost));
        const double needed = double(h) * std::max(byMemory, byCost) * 1.02;
        return make_error(std::format("the sdf would sample {:.0f} x {:.0f} x {:.0f} = {:.0f} points ({} m cells over a box of {} x {} x {} m, {} shape(s)), more than the {} points or {} evaluations allowed",
                                      gx, gy, gz, samplesD, metres(h), metres(ext.x), metres(ext.y), metres(ext.z), sdf.leaf_count(), kModelSdfMaxSamples, kModelSdfMaxCost),
                          "Raise `voxelSize` to " + metres(needed) + " or more (or lower `quality`), or split the shape into several sdf nodes of their own.");
    }
    const int nx = int(gx), ny = int(gy), nz = int(gz);
    const std::size_t samples = std::size_t(nx) * std::size_t(ny) * std::size_t(nz);
    info.voxelSize = h;
    info.gridX = nx;
    info.gridY = ny;
    info.gridZ = nz;
    info.samples = samples;
    info.boundsMin = origin;
    info.boundsMax = origin + Vec3{float(nx - 1) * h, float(ny - 1) * h, float(nz - 1) * h};

    // ---- sample the field; the outermost layer is forced outside so the surface is always closed -------------------------------------
    std::vector<float> f(samples);
    {
        std::size_t k = 0;
        for (int z = 0; z < nz; ++z)
            for (int y = 0; y < ny; ++y)
                for (int x = 0; x < nx; ++x, ++k) {
                    float v = field(origin + Vec3{float(x) * h, float(y) * h, float(z) * h});
                    if (x == 0 || y == 0 || z == 0 || x == nx - 1 || y == ny - 1 || z == nz - 1) {
                        if (v < 0) info.touchedEdge = true;
                        v = std::max(v, 1.0e-6f * h);
                    }
                    f[k] = v;
                }
    }

    // ---- marching tetrahedra ----------------------------------------------------------------------------------------------------------
    struct EdgeVertex {
        std::uint32_t inside, outside;  // the grid points the vertex lies between
    };
    std::vector<Vec3> pos;
    std::vector<EdgeVertex> ends;
    std::vector<std::uint32_t> idx;
    std::unordered_map<std::uint64_t, std::uint32_t> lookup;
    lookup.reserve(4096);
    std::size_t offs[8];
    for (int c = 0; c < 8; ++c) offs[c] = std::size_t(c & 1) + std::size_t(nx) * (std::size_t((c >> 1) & 1) + std::size_t(ny) * std::size_t(c >> 2));

    for (int z = 0; z + 1 < nz; ++z) {
        for (int y = 0; y + 1 < ny; ++y)
            for (int x = 0; x + 1 < nx; ++x) {
                const std::size_t base = std::size_t(x) + std::size_t(nx) * (std::size_t(y) + std::size_t(ny) * std::size_t(z));
                std::size_t g[8];
                float val[8];
                int mask = 0;
                for (int c = 0; c < 8; ++c) {
                    g[c] = base + offs[c];
                    val[c] = f[g[c]];
                    if (val[c] < 0) mask |= 1 << c;
                }
                if (mask == 0 || mask == 255) continue;
                Vec3 cp[8];
                for (int c = 0; c < 8; ++c) cp[c] = origin + Vec3{float(x + (c & 1)) * h, float(y + ((c >> 1) & 1)) * h, float(z + (c >> 2)) * h};

                auto edge_vertex = [&](int ci, int co) -> std::uint32_t {
                    const std::uint64_t a = g[ci], b = g[co];
                    const std::uint64_t key = a < b ? (a << 32) | b : (b << 32) | a;
                    auto it = lookup.find(key);
                    if (it != lookup.end()) return it->second;
                    const float fi = val[ci], fo = val[co];
                    const float t = clamp(fi / (fi - fo), 0.01f, 0.99f);
                    const auto id = std::uint32_t(pos.size());
                    pos.push_back(cp[ci] + (cp[co] - cp[ci]) * t);
                    ends.push_back({std::uint32_t(a), std::uint32_t(b)});
                    lookup.emplace(key, id);
                    return id;
                };
                auto emit = [&](std::uint32_t a, std::uint32_t b, std::uint32_t c, Vec3 outward) {
                    if (dot(cross(pos[b] - pos[a], pos[c] - pos[a]), outward) < 0) std::swap(b, c);
                    idx.push_back(a);
                    idx.push_back(b);
                    idx.push_back(c);
                };

                for (const auto& tet : kTets) {
                    int in[4], out[4], ni = 0, no = 0;
                    for (int k = 0; k < 4; ++k) (val[tet[k]] < 0 ? in[ni++] : out[no++]) = tet[k];
                    if (ni == 0 || ni == 4) continue;
                    Vec3 mi{}, mo{};
                    for (int k = 0; k < ni; ++k) mi = mi + cp[in[k]];
                    for (int k = 0; k < no; ++k) mo = mo + cp[out[k]];
                    const Vec3 outward = mo / float(no) - mi / float(ni);
                    if (ni == 1) {
                        emit(edge_vertex(in[0], out[0]), edge_vertex(in[0], out[1]), edge_vertex(in[0], out[2]), outward);
                    } else if (ni == 3) {
                        emit(edge_vertex(in[0], out[0]), edge_vertex(in[1], out[0]), edge_vertex(in[2], out[0]), outward);
                    } else {
                        const std::uint32_t q0 = edge_vertex(in[0], out[0]), q1 = edge_vertex(in[0], out[1]), q2 = edge_vertex(in[1], out[1]), q3 = edge_vertex(in[1], out[0]);
                        emit(q0, q1, q2, outward);
                        emit(q0, q2, q3, outward);
                    }
                }
            }
        if (idx.size() / 3 > kModelSdfMaxRawTriangles) {
            const double ratio = std::sqrt(double(idx.size() / 3) / double(kModelSdfMaxRawTriangles)) * double(nz) / double(z + 1);
            return make_error(std::format("the sdf makes more than {} triangles before decimation at a cell size of {} m", kModelSdfMaxRawTriangles, metres(h)),
                              "Raise `voxelSize` to about " + metres(double(h) * std::max(ratio, 1.5)) + " or more (or lower `quality`).");
        }
    }
    lookup = {};
    info.rawTriangles = idx.size() / 3;
    if (idx.empty()) {
        done();
        return mesh;
    }

    // ---- move every vertex onto the zero of the field along its edge (false position on the real field) ---------------------------
    auto grid_pos = [&](std::uint32_t id) {
        const std::size_t i = id;
        const int x = int(i % std::size_t(nx)), y = int((i / std::size_t(nx)) % std::size_t(ny)), z = int(i / (std::size_t(nx) * std::size_t(ny)));
        return origin + Vec3{float(x) * h, float(y) * h, float(z) * h};
    };
    for (std::size_t v = 0; v < pos.size(); ++v) {
        Vec3 a = grid_pos(ends[v].inside), b = grid_pos(ends[v].outside);
        float fa = f[ends[v].inside], fb = f[ends[v].outside];
        float t = clamp(fa / (fa - fb), 0.01f, 0.99f);
        for (int it = 0; it < 4; ++it) {
            const Vec3 p = a + (b - a) * t;
            const float fp = field(p);
            if (fp < 0) {
                a = p;
                fa = fp;
            } else {
                b = p;
                fb = fp;
            }
            t = clamp(fa / (fa - fb), 0.01f, 0.99f);
        }
        // Keep the vertex off the grid points: where the surface passes almost through one, the vertices of its edges would otherwise sit
        // closer to each other than any tool welds, and a mesh without decimation could read as non-manifold. Costs at most 5% of a cell.
        const Vec3 from = grid_pos(ends[v].inside), span = grid_pos(ends[v].outside) - from;
        const float s = clamp(dot(a + (b - a) * t - from, span) / dot(span, span), 0.05f, 0.95f);
        pos[v] = from + span * s;
    }
    f = {};
    ends = {};

    // ---- the part of each triangle: whoever owns its centre -----------------------------------------------------------------------------
    std::vector<std::uint32_t> parts(idx.size() / 3, 0);
    if (sdf.has_several_groups()) {
        for (std::size_t t = 0; t < parts.size(); ++t) {
            const Vec3 c = (pos[idx[t * 3]] + pos[idx[t * 3 + 1]] + pos[idx[t * 3 + 2]]) / 3.0f;
            parts[t] = sdf.sample(c).group;
        }
    } else {
        parts.assign(parts.size(), sdf.sample(pos[idx[0]]).group);
    }

    // ---- decimate ----------------------------------------------------------------------------------------------------------------------
    double maxError = 0;
    if (P.maxError >= 0) maxError = P.maxError;
    else if (P.targetTriangles == 0) maxError = 0.25 * double(h);
    info.maxErrorUsed = float(maxError);
    if (P.targetTriangles > 0 || maxError > 0) {
        ModelDecimateParams dp;
        dp.targetTriangles = P.targetTriangles;
        dp.maxError = maxError;
        model_decimate(pos, idx, parts, dp);
    }
    info.triangles = idx.size() / 3;

    // ---- attributes from the field ------------------------------------------------------------------------------------------------------
    const std::size_t triCount = idx.size() / 3;
    std::vector<Vec3> faceSum(pos.size());
    for (std::size_t t = 0; t < triCount; ++t) {
        const Vec3 n = cross(pos[idx[t * 3 + 1]] - pos[idx[t * 3]], pos[idx[t * 3 + 2]] - pos[idx[t * 3]]);
        for (int k = 0; k < 3; ++k) faceSum[idx[t * 3 + std::size_t(k)]] = faceSum[idx[t * 3 + std::size_t(k)]] + n;
    }
    const float e = std::max(0.5f * h, 1.0e-4f);
    std::vector<Vec3> normals(pos.size());
    std::vector<Vec4> colors;
    if (sdf.has_color()) colors.resize(pos.size());
    for (std::size_t v = 0; v < pos.size(); ++v) {
        const Vec3 p = pos[v];
        const Vec3 grad{field({p.x + e, p.y, p.z}) - field({p.x - e, p.y, p.z}), field({p.x, p.y + e, p.z}) - field({p.x, p.y - e, p.z}),
                        field({p.x, p.y, p.z + e}) - field({p.x, p.y, p.z - e})};
        Vec3 n = normalize(grad);
        if (length_sq(n) < 0.5f) n = normalize(faceSum[v]);
        if (length_sq(n) < 0.5f) n = {0, 1, 0};
        normals[v] = n;
        if (sdf.has_color()) colors[v] = sdf.sample(p).color;
    }

    // ---- uvs: a box projection in metres, so a vertex is split where the projection axis changes ----------------------------------
    mesh.triParts = std::move(parts);
    if (P.uvs) {
        std::vector<std::int32_t> split(pos.size() * 3, -1);
        mesh.indices.resize(idx.size());
        for (std::size_t t = 0; t < triCount; ++t) {
            const Vec3 n = cross(pos[idx[t * 3 + 1]] - pos[idx[t * 3]], pos[idx[t * 3 + 2]] - pos[idx[t * 3]]);
            const float ax = std::fabs(n.x), ay = std::fabs(n.y), az = std::fabs(n.z);
            const int axis = ax >= ay && ax >= az ? 0 : (ay >= az ? 1 : 2);
            const float sgn = n[axis] < 0 ? -1.0f : 1.0f;
            for (int k = 0; k < 3; ++k) {
                const std::uint32_t v = idx[t * 3 + std::size_t(k)];
                std::int32_t& slot = split[std::size_t(v) * 3 + std::size_t(axis)];
                if (slot < 0) {
                    slot = std::int32_t(mesh.positions.size());
                    const Vec3 p = pos[v];
                    Vec2 uv = axis == 0 ? Vec2{-p.z * sgn, -p.y} : axis == 1 ? Vec2{p.x, p.z * sgn} : Vec2{p.x * sgn, -p.y};
                    mesh.positions.push_back(p);
                    mesh.normals.push_back(normals[v]);
                    mesh.uvs.push_back(uv);
                    if (!colors.empty()) mesh.colors.push_back(colors[v]);
                }
                mesh.indices[t * 3 + std::size_t(k)] = std::uint32_t(slot);
            }
        }
    } else {
        mesh.positions = std::move(pos);
        mesh.normals = std::move(normals);
        mesh.uvs.assign(mesh.positions.size(), Vec2{0, 0});
        mesh.colors = std::move(colors);
        mesh.indices = std::move(idx);
    }
    done();
    return mesh;
}

}  // namespace fa
