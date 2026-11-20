// The geometry a lightmap is baked onto and drawn with (include/fa/render/lightmap_geometry.h).
#include <cmath>
#include <format>

#include "fa/core/fs.h"
#include "fa/render/lightmap_geometry.h"
#include "fa/scene/lightmap_manifest.h"
#include "fa/scene/lightmap_uv.h"
#include "fa/scene/mesh_store.h"
#include "render_internal.h"

namespace fa::render {

namespace {

// What the parts of the mesh give before the unwrap: every vertex of every part one after the other, the indices of each part raised by
// the vertices before it.
struct Gathered {
    std::vector<MeshVertex> verts;
    std::vector<std::uint32_t> idx;
    std::vector<std::uint32_t> partFirstIndex{0};
    std::vector<float> uv1;             // two floats per vertex, only when every part has TEXCOORD_1
    std::vector<std::uint32_t> color1;  // one per vertex, only when every part has COLOR_1
    bool allUv1 = false, allColor1 = false;
};

Result<Gathered> gather(const std::string& meshName) {
    std::vector<std::vector<MeshVertex>> partVerts;
    std::vector<std::vector<std::uint32_t>> partIdx;
    std::vector<std::vector<float>> partUv1;
    std::vector<std::vector<std::uint32_t>> partColor1;
    {
        std::vector<MeshVertex> v;
        std::vector<std::uint32_t> idx;
        if (build_primitive(meshName, v, idx)) {
            partVerts.push_back(std::move(v));
            partIdx.push_back(std::move(idx));
            partUv1.emplace_back();
            partColor1.emplace_back();
        } else {
            const std::string ext = fs::extension(meshName);
            if (ext != ".gltf" && ext != ".glb")
                return make_error(
                    std::format("'{}' cannot be lightmapped: it is neither a built-in primitive nor a .gltf/.glb file", meshName),
                    "Only MeshRenderer.mesh values that are primitives (cube, sphere, plane, cylinder, capsule, cone, quad) or "
                    "model files have lightmap UVs; a mesh made by a script (\"mesh:N\") does not.");
            const std::string path = fs::normalize(meshName);
            auto bytes = fs::read_bytes(path);
            if (!bytes) return make_error(std::format("lightmap geometry of '{}': {}", meshName, bytes.error().message), bytes.error().hint);
            PreparedMesh prepared;
            std::string error;
            if (!decode_gltf(path, bytes->data(), bytes->size(), prepared, error))
                return make_error(std::format("lightmap geometry of '{}': {}", meshName, error),
                                  "Fix the model (see the error above) or give the entity another mesh.");
            for (PreparedPart& p : prepared.parts) {
                partVerts.push_back(std::move(p.verts));
                partIdx.push_back(std::move(p.idx));
                partUv1.push_back(std::move(p.uv1));
                partColor1.push_back(std::move(p.color1));
            }
        }
    }
    Gathered g;
    g.allUv1 = !partVerts.empty();
    g.allColor1 = !partVerts.empty();
    for (std::size_t i = 0; i < partVerts.size(); ++i) {
        g.allUv1 = g.allUv1 && partUv1[i].size() == partVerts[i].size() * 2;
        g.allColor1 = g.allColor1 && partColor1[i].size() == partVerts[i].size();
    }
    for (std::size_t i = 0; i < partVerts.size(); ++i) {
        const std::uint32_t base = std::uint32_t(g.verts.size());
        g.verts.insert(g.verts.end(), partVerts[i].begin(), partVerts[i].end());
        for (std::uint32_t k : partIdx[i]) g.idx.push_back(base + k);
        g.partFirstIndex.push_back(std::uint32_t(g.idx.size()));
        if (g.allUv1) g.uv1.insert(g.uv1.end(), partUv1[i].begin(), partUv1[i].end());
        if (g.allColor1) g.color1.insert(g.color1.end(), partColor1[i].begin(), partColor1[i].end());
    }
    if (g.idx.size() < 3)
        return make_error(std::format("'{}' has no triangles to light", meshName), "Give the entity a mesh with triangles.");
    for (std::uint32_t k : g.idx)
        if (k >= g.verts.size())
            return make_error(std::format("'{}' has an index past its last vertex", meshName), "Re-export the model.");
    return g;
}

// A hash that does not change with the last digit of a float: positions to a tenth of a millimetre, uv to 1/100000.
std::uint64_t geometry_hash(const LightmapMeshGeometry& geo) {
    std::uint64_t h = kLightmapHashSeed;
    auto mix_i = [&](std::int64_t v) { h = lightmap_hash_bytes(h, &v, sizeof v); };
    auto q = [](float f, double scale) { return std::int64_t(std::llround(double(f) * scale)); };
    mix_i(std::int64_t(geo.positions.size()));
    mix_i(std::int64_t(geo.indices.size()));
    for (const Vec3& p : geo.positions) {
        mix_i(q(p.x, 1e4));
        mix_i(q(p.y, 1e4));
        mix_i(q(p.z, 1e4));
    }
    for (std::uint32_t i : geo.indices) mix_i(i);
    for (const Vec2& t : geo.uv) {
        mix_i(q(t.x, 1e5));
        mix_i(q(t.y, 1e5));
    }
    for (std::uint32_t p : geo.partFirstIndex) mix_i(p);
    h = lightmap_hash_bytes(h, geo.uvKind.data(), geo.uvKind.size());
    return h;
}

}  // namespace

Result<LightmapBuild> build_lightmap_mesh(const std::string& meshIn) {
    const std::string meshName = meshIn.empty() ? std::string("cube") : meshIn;
    if (MeshStore::is_id(meshName))
        return make_error(std::format("'{}' is a mesh made by a script and cannot be lightmapped", meshName),
                          "Lightmaps need a mesh file or a built-in primitive, whose UVs are the same on every run.");
    auto g = gather(meshName);
    if (!g) return g.error();
    LightmapBuild out;
    LightmapMeshGeometry& geo = out.geo;
    geo.partFirstIndex = g->partFirstIndex;
    // Surface area from the file's triangles (the same as after the split).
    auto pos_of = [&](std::uint32_t i) { return Vec3{g->verts[i].px, g->verts[i].py, g->verts[i].pz}; };
    for (std::size_t t = 0; t + 2 < g->idx.size(); t += 3)
        geo.surfaceArea += 0.5 * double(length(cross(pos_of(g->idx[t + 1]) - pos_of(g->idx[t]), pos_of(g->idx[t + 2]) - pos_of(g->idx[t]))));
    if (g->allUv1) {
        geo.uvKind = "gltf";
        out.verts = g->verts;
        out.color1 = g->color1;
        geo.indices = g->idx;
        geo.uv.resize(g->verts.size());
        for (std::size_t i = 0; i < g->verts.size(); ++i) {
            geo.positions.push_back(pos_of(std::uint32_t(i)));
            geo.normals.push_back({g->verts[i].nx, g->verts[i].ny, g->verts[i].nz});
            const float u = g->uv1[2 * i], v = g->uv1[2 * i + 1];
            geo.uv[i] = {std::isfinite(u) ? u : 0.0f, std::isfinite(v) ? v : 0.0f};
        }
        // The UVs are the author's: they must be a usable atlas, or the light would land in the wrong place.
        for (const Vec2& t : geo.uv)
            if (t.x < -1e-3f || t.x > 1.001f || t.y < -1e-3f || t.y > 1.001f)
                return make_error(
                    std::format("TEXCOORD_1 of '{}' has a coordinate outside 0..1 ({}, {})", meshName, t.x, t.y),
                    "A lightmap UV set must lie inside the unit square without overlap. Export the model with such a second UV set, or "
                    "remove TEXCOORD_1 from it so the engine unwraps it.");
    } else {
        geo.uvKind = "generated";
        std::vector<Vec3> positions, normals;
        positions.reserve(g->verts.size());
        normals.reserve(g->verts.size());
        for (const MeshVertex& v : g->verts) {
            positions.push_back({v.px, v.py, v.pz});
            normals.push_back({v.nx, v.ny, v.nz});
        }
        auto r = generate_lightmap_uv(positions, normals, g->idx);
        if (!r) return make_error("lightmap UVs of '" + meshName + "': " + r.error().message, r.error().hint);
        geo.uv = std::move(r->uv);
        geo.indices = std::move(r->indices);
        geo.positions.reserve(r->source.size());
        geo.normals.reserve(r->source.size());
        out.verts.reserve(r->source.size());
        for (std::uint32_t s : r->source) {
            geo.positions.push_back(positions[s]);
            geo.normals.push_back(normals[s]);
            out.verts.push_back(g->verts[s]);
            if (g->allColor1) out.color1.push_back(g->color1[s]);
        }
    }
    geo.hash = geometry_hash(geo);
    return out;
}

Result<LightmapMeshGeometry> lightmap_mesh_geometry(const std::string& mesh) {
    auto b = build_lightmap_mesh(mesh);
    if (!b) return b.error();
    return std::move(b->geo);
}

}  // namespace fa::render
