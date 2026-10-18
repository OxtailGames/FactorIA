#include "fa/scene/mesh_geometry.h"

#include <cgltf.h>

#include <cmath>
#include <cstdlib>
#include <cstring>
#include <format>
#include <map>

#include "fa/core/fs.h"
#include "fa/core/strings.h"

namespace fa {

namespace {

constexpr float kPi = 3.14159265358979f;
const char* const kPrimitiveNames[] = {"cube", "sphere", "plane", "cylinder", "capsule", "cone", "quad"};

// Surface of revolution about Y through the profile (radius, y) points, `seg` segments around.
void revolve(MeshGeometry& g, int seg, const std::vector<Vec2>& profile) {
    const auto base = std::uint32_t(g.positions.size());
    const auto rows = std::uint32_t(profile.size());
    for (const Vec2& p : profile)
        for (int s = 0; s < seg; ++s) {
            const float a = float(s) / float(seg) * 2.0f * kPi;
            g.positions.push_back({p.x * std::cos(a), p.y, p.x * std::sin(a)});
        }
    for (std::uint32_t r = 0; r + 1 < rows; ++r)
        for (std::uint32_t s = 0; s < std::uint32_t(seg); ++s) {
            const std::uint32_t s1 = (s + 1) % std::uint32_t(seg);
            const std::uint32_t a = base + r * seg + s, b = base + r * seg + s1, c = base + (r + 1) * seg + s,
                                d = base + (r + 1) * seg + s1;
            g.indices.insert(g.indices.end(), {a, c, b, b, c, d});
        }
}

// A flat disc at height y (fan around a centre vertex).
void disc(MeshGeometry& g, int seg, float radius, float y) {
    const auto centre = std::uint32_t(g.positions.size());
    g.positions.push_back({0, y, 0});
    for (int s = 0; s < seg; ++s) {
        const float a = float(s) / float(seg) * 2.0f * kPi;
        g.positions.push_back({radius * std::cos(a), y, radius * std::sin(a)});
    }
    for (int s = 0; s < seg; ++s)
        g.indices.insert(g.indices.end(), {centre, centre + 1 + std::uint32_t(s), centre + 1 + std::uint32_t((s + 1) % seg)});
}

bool build_primitive_geometry(const std::string& name, MeshGeometry& g) {
    const float h = 0.5f;
    if (name == "cube") {
        for (int i = 0; i < 8; ++i) g.positions.push_back({(i & 1) ? h : -h, (i & 2) ? h : -h, (i & 4) ? h : -h});
        const std::uint32_t quads[6][4] = {{0, 1, 3, 2}, {4, 6, 7, 5}, {0, 2, 6, 4}, {1, 5, 7, 3}, {0, 4, 5, 1}, {2, 3, 7, 6}};
        for (auto& q : quads) g.indices.insert(g.indices.end(), {q[0], q[1], q[2], q[0], q[2], q[3]});
    } else if (name == "plane") {
        g.positions = {{-h, 0, -h}, {h, 0, -h}, {h, 0, h}, {-h, 0, h}};
        g.indices = {0, 2, 1, 0, 3, 2};
    } else if (name == "quad") {
        g.positions = {{-h, -h, 0}, {h, -h, 0}, {h, h, 0}, {-h, h, 0}};
        g.indices = {0, 1, 2, 0, 2, 3};
    } else if (name == "sphere") {
        std::vector<Vec2> profile;
        for (int i = 0; i <= 16; ++i) {
            const float t = float(i) / 16.0f * kPi;
            profile.push_back({std::sin(t) * h, std::cos(t) * h});
        }
        revolve(g, 32, profile);
    } else if (name == "cylinder") {
        revolve(g, 32, {{h, h}, {h, -h}});
        disc(g, 32, h, h);
        disc(g, 32, h, -h);
    } else if (name == "capsule") {
        std::vector<Vec2> profile;
        for (int i = 0; i <= 8; ++i) {
            const float t = float(i) / 8.0f * (kPi * 0.5f);
            profile.push_back({std::sin(t) * h, std::cos(t) * h + 0.5f});
        }
        for (int i = 0; i <= 8; ++i) {
            const float t = kPi * 0.5f + float(i) / 8.0f * (kPi * 0.5f);
            profile.push_back({std::sin(t) * h, std::cos(t) * h - 0.5f});
        }
        revolve(g, 32, profile);
    } else if (name == "cone") {
        revolve(g, 32, {{0.0f, h}, {h, -h}});
        disc(g, 32, h, -h);
    } else {
        return false;
    }
    return true;
}

void finish_bounds(MeshGeometry& g) {
    if (g.positions.empty()) return;
    g.bmin = g.bmax = g.positions[0];
    for (const Vec3& p : g.positions) {
        g.bmin = min(g.bmin, p);
        g.bmax = max(g.bmax, p);
    }
}

cgltf_result file_read(const cgltf_memory_options*, const cgltf_file_options*, const char* path, cgltf_size* size,
                       void** data) {
    auto bytes = fs::read_bytes(path);
    if (!bytes) return cgltf_result_file_not_found;
    void* mem = std::malloc(bytes->size() ? bytes->size() : 1);
    if (!mem) return cgltf_result_out_of_memory;
    std::memcpy(mem, bytes->data(), bytes->size());
    *size = bytes->size();
    *data = mem;
    return cgltf_result_success;
}
void file_release(const cgltf_memory_options*, const cgltf_file_options*, void* data, cgltf_size) { std::free(data); }

Result<std::shared_ptr<const MeshGeometry>> load_gltf_geometry(const std::string& path) {
    auto bytes = fs::read_bytes(path);
    if (!bytes)
        return make_error(std::format("mesh '{}' is not a built-in primitive and cannot be read as a model: {}", path,
                                      bytes.error().message),
                          "Use a primitive name (cube, sphere, plane, cylinder, capsule, cone, quad) or a "
                          "project-relative path to a .gltf/.glb file, e.g. \"assets/models/ramp.glb\".");
    cgltf_options opts{};
    opts.file.read = &file_read;
    opts.file.release = &file_release;
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
    auto g = std::make_shared<MeshGeometry>();
    for (cgltf_size ni = 0; ni < data->nodes_count; ++ni) {
        const cgltf_node& node = data->nodes[ni];
        if (!node.mesh) continue;
        Mat4 world;
        cgltf_node_transform_world(&node, world.m);
        for (cgltf_size pi = 0; pi < node.mesh->primitives_count; ++pi) {
            const cgltf_primitive& prim = node.mesh->primitives[pi];
            if (prim.type != cgltf_primitive_type_triangles) continue;
            const cgltf_accessor* pos = nullptr;
            for (cgltf_size a = 0; a < prim.attributes_count; ++a)
                if (prim.attributes[a].type == cgltf_attribute_type_position && prim.attributes[a].index == 0)
                    pos = prim.attributes[a].data;
            if (!pos) continue;
            const auto base = std::uint32_t(g->positions.size());
            for (cgltf_size i = 0; i < pos->count; ++i) {
                float p[3] = {0, 0, 0};
                cgltf_accessor_read_float(pos, i, p, 3);
                g->positions.push_back(world.transform_point({p[0], p[1], p[2]}));
            }
            if (prim.indices) {
                for (cgltf_size i = 0; i + 2 < prim.indices->count; i += 3)
                    for (int k = 0; k < 3; ++k)
                        g->indices.push_back(base + std::uint32_t(cgltf_accessor_read_index(prim.indices, i + k)));
            } else {
                for (cgltf_size i = 0; i + 2 < pos->count; i += 3)
                    for (int k = 0; k < 3; ++k) g->indices.push_back(base + std::uint32_t(i + k));
            }
        }
    }
    if (g->indices.empty())
        return make_error(std::format("'{}' contains no triangle meshes, so it has no collision geometry", path),
                          "Export the model with at least one mesh made of triangles.");
    finish_bounds(*g);
    return std::shared_ptr<const MeshGeometry>(std::move(g));
}

}  // namespace

bool is_primitive_mesh(const std::string& name) {
    const std::string lower = to_lower(name);
    for (const char* p : kPrimitiveNames)
        if (lower == p) return true;
    return false;
}

Result<std::shared_ptr<const MeshGeometry>> load_mesh_geometry(const std::string& mesh) {
    static std::map<std::string, std::shared_ptr<const MeshGeometry>> cache;
    if (mesh.empty())
        return make_error("a convex or mesh collider has no `mesh`",
                          "Set Collider3D.mesh to a primitive name (cube, sphere, plane, cylinder, capsule, cone, quad) or "
                          "a .gltf/.glb path, usually the same value as the entity's MeshRenderer.mesh.");
    const std::string key = is_primitive_mesh(mesh) ? to_lower(mesh) : mesh;
    if (auto it = cache.find(key); it != cache.end()) return it->second;
    Result<std::shared_ptr<const MeshGeometry>> out = std::shared_ptr<const MeshGeometry>();
    if (is_primitive_mesh(mesh)) {
        auto g = std::make_shared<MeshGeometry>();
        build_primitive_geometry(key, *g);
        finish_bounds(*g);
        out = std::shared_ptr<const MeshGeometry>(std::move(g));
    } else {
        const std::string lower = to_lower(mesh);
        if (!lower.ends_with(".gltf") && !lower.ends_with(".glb")) {
            std::vector<std::string> names(std::begin(kPrimitiveNames), std::end(kPrimitiveNames));
            return make_error(std::format("unknown collider mesh '{}'", mesh),
                              "Use a primitive name (cube, sphere, plane, cylinder, capsule, cone, quad) or a "
                              "project-relative .gltf/.glb path. " + did_you_mean(mesh, names));
        }
        out = load_gltf_geometry(mesh);
    }
    if (out) cache[key] = out.value();
    return out;
}

}  // namespace fa
