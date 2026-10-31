#include "fa/scene/mesh_surface.h"

#include <cgltf.h>

#include <cmath>
#include <format>
#include <map>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/gltf_file.h"
#include "fa/scene/mesh_geometry.h"
#include "fa/scene/mesh_store.h"

namespace fa {

namespace {

constexpr const char* kPrimitiveNames[] = {"cube", "sphere", "plane", "cylinder", "capsule", "cone", "quad"};

// The vertices below are made in the same order, with the same UVs, as the renderer's build_primitive (fa_render assets.cpp);
// only the normals and tangents are left out. A test in fa_test_render compares the two.
void add_face(MeshSurface& s, Vec3 r, Vec3 u, Vec3 center, float half) {
    const auto base = std::uint32_t(s.positions.size());
    const Vec2 uvs[4] = {{0, 1}, {1, 1}, {1, 0}, {0, 0}};
    const float sx[4] = {-1, 1, 1, -1}, sy[4] = {-1, -1, 1, 1};
    for (int i = 0; i < 4; ++i) {
        s.positions.push_back(center + r * (sx[i] * half) + u * (sy[i] * half));
        s.uvs.push_back(uvs[i]);
    }
    s.indices.insert(s.indices.end(), {base, base + 1, base + 2, base, base + 2, base + 3});
}

// rings: x = radius, y = height, z = v coordinate.
void add_revolved(MeshSurface& s, int segments, const std::vector<Vec3>& rings) {
    const auto base = std::uint32_t(s.positions.size());
    for (const Vec3& ring : rings)
        for (int i = 0; i <= segments; ++i) {
            const float a = float(i) / float(segments) * kTau;
            s.positions.push_back({ring.x * std::cos(a), ring.y, ring.x * std::sin(a)});
            s.uvs.push_back({float(i) / float(segments), ring.z});
        }
    for (std::size_t r = 0; r + 1 < rings.size(); ++r)
        for (int i = 0; i < segments; ++i) {
            const std::uint32_t a = base + std::uint32_t(r) * (segments + 1) + i, b = a + segments + 1;
            s.indices.insert(s.indices.end(), {a, b, a + 1, a + 1, b, b + 1});
        }
}

void add_disc(MeshSurface& s, int segments, float radius, float y) {
    const auto base = std::uint32_t(s.positions.size());
    s.positions.push_back({0, y, 0});
    s.uvs.push_back({0.5f, 0.5f});
    for (int i = 0; i <= segments; ++i) {
        const float a = float(i) / float(segments) * kTau;
        s.positions.push_back({radius * std::cos(a), y, radius * std::sin(a)});
        s.uvs.push_back({0.5f + 0.5f * std::cos(a), 0.5f + 0.5f * std::sin(a)});
    }
    for (int i = 0; i < segments; ++i) s.indices.insert(s.indices.end(), {base, base + 1 + std::uint32_t(i), base + 2 + std::uint32_t(i)});
}

bool build_primitive_surface(const std::string& name, MeshSurface& s) {
    const float h = 0.5f;
    if (name == "cube") {
        add_face(s, {1, 0, 0}, {0, 1, 0}, {0, 0, h}, h);
        add_face(s, {-1, 0, 0}, {0, 1, 0}, {0, 0, -h}, h);
        add_face(s, {0, 0, -1}, {0, 1, 0}, {h, 0, 0}, h);
        add_face(s, {0, 0, 1}, {0, 1, 0}, {-h, 0, 0}, h);
        add_face(s, {1, 0, 0}, {0, 0, -1}, {0, h, 0}, h);
        add_face(s, {1, 0, 0}, {0, 0, 1}, {0, -h, 0}, h);
    } else if (name == "plane") {
        add_face(s, {1, 0, 0}, {0, 0, -1}, {0, 0, 0}, h);
    } else if (name == "quad") {
        add_face(s, {1, 0, 0}, {0, 1, 0}, {0, 0, 0}, h);
    } else if (name == "sphere") {
        std::vector<Vec3> r;
        for (int i = 0; i <= 16; ++i) {
            const float t = float(i) / 16.0f * kPi;
            r.push_back({std::sin(t) * h, std::cos(t) * h, float(i) / 16.0f});
        }
        add_revolved(s, 32, r);
    } else if (name == "cylinder") {
        add_revolved(s, 32, {{h, h, 0.0f}, {h, -h, 1.0f}});
        add_disc(s, 32, h, h);
        add_disc(s, 32, h, -h);
    } else if (name == "capsule") {
        std::vector<Vec3> r;
        for (int i = 0; i <= 8; ++i) {
            const float t = float(i) / 8.0f * (kPi * 0.5f);
            r.push_back({std::sin(t) * h, std::cos(t) * h + 0.5f, float(i) / 18.0f});
        }
        for (int i = 0; i <= 8; ++i) {
            const float t = kPi * 0.5f + float(i) / 8.0f * (kPi * 0.5f);
            r.push_back({std::sin(t) * h, std::cos(t) * h - 0.5f, float(9 + i) / 18.0f});
        }
        add_revolved(s, 32, r);
    } else if (name == "cone") {
        add_revolved(s, 32, {{0.0f, h, 0.0f}, {h, -h, 1.0f}});
        add_disc(s, 32, h, -h);
    } else {
        return false;
    }
    return true;
}

Result<std::shared_ptr<const MeshSurface>> load_gltf_surface(const std::string& path) {
    auto bytes = fs::read_bytes(path);
    if (!bytes)
        return make_error(std::format("mesh '{}' is not a built-in primitive and cannot be read as a model: {}", path, bytes.error().message),
                          "Use a primitive name (cube, sphere, plane, cylinder, capsule, cone, quad) or a project-relative path to a "
                          ".gltf/.glb file, e.g. \"assets/models/screen.glb\".");
    cgltf_options opts{};
    gltf_use_fs(opts);
    cgltf_data* data = nullptr;
    cgltf_result r = cgltf_parse(&opts, bytes->data(), bytes->size(), &data);
    if (r != cgltf_result_success)
        return make_error(std::format("cgltf could not parse '{}' (error code {})", path, int(r)),
                          "The file must be a valid glTF 2.0 (.gltf or .glb) file.");
    struct Guard {
        cgltf_data* d;
        ~Guard() { cgltf_free(d); }
    } guard{data};
    r = cgltf_load_buffers(&opts, data, path.c_str());
    if (r != cgltf_result_success)
        return make_error(std::format("cannot load the buffers referenced by '{}' (cgltf error {})", path, int(r)),
                          "External .bin files must sit next to the .gltf and be inside the project.");
    auto s = std::make_shared<MeshSurface>();
    for (cgltf_size ni = 0; ni < data->nodes_count; ++ni) {
        const cgltf_node& node = data->nodes[ni];
        if (!node.mesh) continue;
        Mat4 world;
        cgltf_node_transform_world(&node, world.m);
        for (cgltf_size pi = 0; pi < node.mesh->primitives_count; ++pi) {
            const cgltf_primitive& prim = node.mesh->primitives[pi];
            if (prim.type != cgltf_primitive_type_triangles) continue;
            const cgltf_accessor *pos = nullptr, *uv = nullptr;
            for (cgltf_size a = 0; a < prim.attributes_count; ++a) {
                if (prim.attributes[a].type == cgltf_attribute_type_position && prim.attributes[a].index == 0) pos = prim.attributes[a].data;
                if (prim.attributes[a].type == cgltf_attribute_type_texcoord && prim.attributes[a].index == 0) uv = prim.attributes[a].data;
            }
            if (!pos) continue;
            const auto base = std::uint32_t(s->positions.size());
            for (cgltf_size i = 0; i < pos->count; ++i) {
                float p[3] = {0, 0, 0}, t[2] = {0, 0};
                cgltf_accessor_read_float(pos, i, p, 3);
                if (uv) cgltf_accessor_read_float(uv, i, t, 2);
                s->positions.push_back(world.transform_point({p[0], p[1], p[2]}));
                s->uvs.push_back({t[0], t[1]});
            }
            if (prim.indices) {
                for (cgltf_size i = 0; i + 2 < prim.indices->count; i += 3)
                    for (int k = 0; k < 3; ++k) s->indices.push_back(base + std::uint32_t(cgltf_accessor_read_index(prim.indices, i + k)));
            } else {
                for (cgltf_size i = 0; i + 2 < pos->count; i += 3)
                    for (int k = 0; k < 3; ++k) s->indices.push_back(base + std::uint32_t(i + k));
            }
        }
    }
    if (s->indices.empty())
        return make_error(std::format("'{}' contains no triangle meshes, so the pointer cannot reach a texture on it", path),
                          "Export the model with at least one mesh made of triangles.");
    return std::shared_ptr<const MeshSurface>(std::move(s));
}

}  // namespace

Result<std::shared_ptr<const MeshSurface>> load_mesh_surface(const std::string& mesh) {
    static std::map<std::string, std::shared_ptr<const MeshSurface>> cache;
    if (mesh.empty())
        return make_error("a MeshRenderer has no `mesh`", "Set MeshRenderer.mesh to a primitive name (cube, sphere, plane, cylinder, "
                                                           "capsule, cone, quad) or a .gltf/.glb path.");
    const std::string key = mesh_key(mesh);
    if (auto it = cache.find(key); it != cache.end()) return it->second;
    Result<std::shared_ptr<const MeshSurface>> out = std::shared_ptr<const MeshSurface>();
    bool primitive = false;
    for (const char* p : kPrimitiveNames) primitive = primitive || key == p;
    if (primitive) {
        auto s = std::make_shared<MeshSurface>();
        build_primitive_surface(key, *s);
        out = std::shared_ptr<const MeshSurface>(std::move(s));
    } else {
        const std::string lower = to_lower(mesh);
        if (!lower.ends_with(".gltf") && !lower.ends_with(".glb")) {
            std::vector<std::string> names(std::begin(kPrimitiveNames), std::end(kPrimitiveNames));
            return make_error(std::format("unknown mesh '{}'", mesh),
                              "Use a primitive name (cube, sphere, plane, cylinder, capsule, cone, quad) or a project-relative "
                              ".gltf/.glb path. " + did_you_mean(mesh, names));
        }
        out = load_gltf_surface(mesh);
    }
    if (out) cache[key] = out.value();
    return out;
}

Result<std::shared_ptr<const MeshSurface>> load_mesh_surface(MeshStore& store, const std::string& mesh) {
    if (!MeshStore::is_id(mesh)) return load_mesh_surface(mesh);
    if (auto s = store.surface(mesh)) {
        if (!s->indices.empty()) return s;
        return make_error(std::format("procedural mesh '{}' has no drawn triangles, so the pointer cannot reach a texture on it", mesh),
                          "Give the mesh indices, and submeshes that cover them (indices outside every submesh are not drawn).");
    }
    return store.get(mesh).error();
}

namespace {

// Moller-Trumbore, both sides. Returns t and the barycentric weights of b and c.
bool hit_triangle(Vec3 o, Vec3 d, Vec3 a, Vec3 b, Vec3 c, float& t, float& u, float& v) {
    const Vec3 e1 = b - a, e2 = c - a;
    const Vec3 p = cross(d, e2);
    const float det = dot(e1, p);
    if (std::fabs(det) < 1e-12f) return false;
    const float inv = 1.0f / det;
    const Vec3 s = o - a;
    u = dot(s, p) * inv;
    if (u < -1e-5f || u > 1.0f + 1e-5f) return false;
    const Vec3 q = cross(s, e1);
    v = dot(d, q) * inv;
    if (v < -1e-5f || u + v > 1.0f + 1e-5f) return false;
    t = dot(e2, q) * inv;
    return t >= 0.0f;
}

}  // namespace

std::optional<SurfaceHit> raycast_surface(const MeshSurface& s, const Mat4& model, Vec3 origin, Vec3 dir) {
    const Mat4 inv = model.inverse();
    const Vec3 o = inv.transform_point(origin), d = inv.transform_dir(dir);
    std::optional<SurfaceHit> best;
    for (std::size_t i = 0; i + 2 < s.indices.size(); i += 3) {
        const std::uint32_t ia = s.indices[i], ib = s.indices[i + 1], ic = s.indices[i + 2];
        float t, u, v;
        if (!hit_triangle(o, d, s.positions[ia], s.positions[ib], s.positions[ic], t, u, v)) continue;
        if (best && t >= best->distance) continue;
        SurfaceHit h;
        h.distance = t;
        h.uv = s.uvs[ia] * (1.0f - u - v) + s.uvs[ib] * u + s.uvs[ic] * v;
        h.triangle = std::uint32_t(i / 3);
        best = h;
    }
    return best;
}

std::optional<Vec2> surface_uv_on_plane(const MeshSurface& s, const Mat4& model, std::uint32_t triangle, Vec3 origin, Vec3 dir) {
    if (std::size_t(triangle) * 3 + 2 >= s.indices.size()) return std::nullopt;
    const std::uint32_t ia = s.indices[triangle * 3], ib = s.indices[triangle * 3 + 1], ic = s.indices[triangle * 3 + 2];
    const Mat4 inv = model.inverse();
    const Vec3 o = inv.transform_point(origin), d = inv.transform_dir(dir);
    const Vec3 a = s.positions[ia], e1 = s.positions[ib] - a, e2 = s.positions[ic] - a;
    const Vec3 n = cross(e1, e2);
    if (dot(n, n) < 1e-18f) return std::nullopt;
    const float denom = dot(n, d);
    if (std::fabs(denom) < 1e-9f * std::sqrt(dot(n, n)) * std::sqrt(dot(d, d))) return std::nullopt;
    const float t = dot(n, a - o) / denom;
    const Vec3 p = o + d * t - a;
    // Solve p = u e1 + v e2 in the plane.
    const float d11 = dot(e1, e1), d12 = dot(e1, e2), d22 = dot(e2, e2), dp1 = dot(p, e1), dp2 = dot(p, e2);
    const float det = d11 * d22 - d12 * d12;
    if (std::fabs(det) < 1e-18f) return std::nullopt;
    const float u = (d22 * dp1 - d12 * dp2) / det, v = (d11 * dp2 - d12 * dp1) / det;
    return s.uvs[ia] * (1.0f - u - v) + s.uvs[ib] * u + s.uvs[ic] * v;
}

}  // namespace fa
