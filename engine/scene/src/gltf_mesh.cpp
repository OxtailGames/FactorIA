// Reading a glTF file into one MeshData (fa/scene/gltf_mesh.h).
#include "fa/scene/gltf_mesh.h"

#include <cgltf.h>

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <format>
#include <limits>
#include <map>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/json.h"
#include "fa/core/strings.h"
#include "fa/scene/gltf_file.h"

namespace fa {

namespace {

constexpr std::size_t kNoMaterial = std::numeric_limits<std::size_t>::max();

std::string directory_of(const std::string& path) {
    const auto slash = path.find_last_of('/');
    return slash == std::string::npos ? std::string() : path.substr(0, slash + 1);
}

// The part a primitive names in its extras ({"part": "wheel"}), "" when it has none.
std::string primitive_part(const cgltf_data* data, const cgltf_primitive& prim) {
    if (prim.extras.start_offset == prim.extras.end_offset) return {};
    cgltf_size size = 0;
    if (cgltf_copy_extras_json(data, &prim.extras, nullptr, &size) != cgltf_result_success || size == 0) return {};
    std::string text(size, '\0');
    if (cgltf_copy_extras_json(data, &prim.extras, text.data(), &size) != cgltf_result_success) return {};
    auto json = parse_json(text.c_str(), "extras");
    if (!json.ok() || !json->is_object() || !json->contains("part") || !(*json)["part"].is_string()) return {};
    return (*json)["part"].get<std::string>();
}

struct Group {
    std::size_t material = kNoMaterial;
    std::string part;
    std::vector<std::uint32_t> indices;  // into the merged vertex arrays
};

}  // namespace

Result<GltfMesh> read_gltf_mesh(const std::string& path) {
    const std::string lower = to_lower(path);
    if (!ends_with(lower, ".glb") && !ends_with(lower, ".gltf"))
        return make_error(
            std::format("'{}' is not a .glb or .gltf file", path),
            "Give a glTF 2.0 file, e.g. \"assets/models/robot.glb\". An OBJ or FBX goes through assets.import first.");
    auto bytes = fs::read_bytes(path);
    if (!bytes)
        return make_error(std::format("cannot read '{}': {}", path, bytes.error().message),
                          "Give a project-relative path to a file that exists, e.g. \"assets/models/robot.glb\".");
    return read_gltf_mesh_bytes(*bytes, path);
}

Result<GltfMesh> read_gltf_mesh_bytes(const std::vector<std::uint8_t>& bytes, const std::string& path) {
    cgltf_options opts{};
    gltf_use_fs(opts);
    cgltf_data* data = nullptr;
    if (cgltf_parse(&opts, bytes.data(), bytes.size(), &data) != cgltf_result_success)
        return make_error(
            std::format("cgltf could not parse '{}'", path),
            "The file must be a valid glTF 2.0 (.gltf or .glb) file; export it again from the tool that made it.");
    struct Guard {
        cgltf_data* d;
        ~Guard() { cgltf_free(d); }
    } guard{data};
    if (cgltf_load_buffers(&opts, data, path.c_str()) != cgltf_result_success)
        return make_error(std::format("cannot load the buffers of '{}'", path),
                          "External .bin files must sit next to the .gltf and inside the project.");

    if (auto sound = gltf_check(data, path); !sound) return sound.error();
    GltfMesh out;
    const std::string dir = directory_of(fs::normalize(path));

    // distinct materials in the order they are first used
    std::map<const cgltf_material*, std::size_t> materialIndex;
    std::set<std::string> usedNames;
    auto material_of = [&](const cgltf_material* m) -> std::size_t {
        if (!m) return kNoMaterial;
        if (auto it = materialIndex.find(m); it != materialIndex.end()) return it->second;
        MeshMaterial mm;
        std::string base = m->name && *m->name ? m->name : "material_" + std::to_string(out.materials.size() + 1);
        std::string name = base;
        for (int n = 2; !usedNames.insert(name).second; ++n) name = base + "_" + std::to_string(n);
        mm.name = name;
        const cgltf_pbr_metallic_roughness& pbr = m->pbr_metallic_roughness;
        if (m->has_pbr_metallic_roughness) {
            mm.color = Color{pbr.base_color_factor[0], pbr.base_color_factor[1], pbr.base_color_factor[2],
                             pbr.base_color_factor[3]};
            mm.metallic = pbr.metallic_factor;
            mm.roughness = pbr.roughness_factor;
            const cgltf_image* image = pbr.base_color_texture.texture ? pbr.base_color_texture.texture->image : nullptr;
            if (image) {
                if (image->uri && std::strncmp(image->uri, "data:", 5) != 0) {
                    std::string uri = image->uri;
                    std::vector<char> decoded(uri.begin(), uri.end());
                    decoded.push_back('\0');
                    cgltf_decode_uri(decoded.data());
                    const std::string joined = fs::normalize(dir + decoded.data());
                    if (joined.empty())
                        out.warnings.push_back(std::format("material '{}': its texture '{}' is outside the project, so "
                                                           "the material keeps its colour only",
                                                           name, uri));
                    else
                        mm.texture = joined;
                } else if (image->buffer_view || (image->uri && std::strncmp(image->uri, "data:", 5) == 0)) {
                    GltfEmbeddedImage emb;
                    emb.material = out.materials.size();
                    const std::string mime = image->mime_type ? image->mime_type : "";
                    emb.extension =
                        mime.find("jpeg") != std::string::npos || mime.find("jpg") != std::string::npos ? "jpg" : "png";
                    if (image->buffer_view) {
                        const auto* src = static_cast<const std::uint8_t*>(image->buffer_view->buffer->data) +
                                          image->buffer_view->offset;
                        emb.bytes.assign(src, src + image->buffer_view->size);
                    } else {
                        const char* comma = std::strchr(image->uri, ',');
                        if (comma) {
                            const std::string b64 = comma + 1;
                            void* decodedData = nullptr;
                            cgltf_options o{};
                            // base64: size = 3/4 of the text minus padding
                            const cgltf_size padding =
                                b64.size() >= 2 ? (b64[b64.size() - 1] == '=') + (b64[b64.size() - 2] == '=') : 0;
                            const cgltf_size size = (b64.size() * 3) / 4 - padding;
                            if (cgltf_load_buffer_base64(&o, size, b64.c_str(), &decodedData) == cgltf_result_success &&
                                decodedData) {
                                emb.bytes.assign(static_cast<std::uint8_t*>(decodedData),
                                                 static_cast<std::uint8_t*>(decodedData) + size);
                                std::free(decodedData);
                            }
                        }
                    }
                    if (!emb.bytes.empty()) out.embedded.push_back(std::move(emb));
                }
            }
        }
        mm.emissive = Color{m->emissive_factor[0], m->emissive_factor[1], m->emissive_factor[2], 1};
        mm.doubleSided = m->double_sided;
        mm.blend = m->alpha_mode == cgltf_alpha_mode_blend;
        out.materials.push_back(mm);
        return materialIndex[m] = out.materials.size() - 1;
    };

    std::vector<float> positions, normals, uvs, colors;
    bool allNormals = true, anyUvs = false, allUvs = true, anyColors = false, allColors = true;
    std::vector<Group> groups;
    std::vector<std::string> plusParts;  // part names with a "+" already warned about
    std::size_t skipped = 0, skinned = 0, indexTotal = 0;
    for (cgltf_size ni = 0; ni < data->nodes_count; ++ni) {
        const cgltf_node& node = data->nodes[ni];
        if (!node.mesh) continue;
        ++out.meshNodes;
        if (node.skin) ++skinned;
        float world[16];
        cgltf_node_transform_world(&node, world);
        // normal matrix: the inverse transpose of the upper 3x3; uniform scale and rotation are the common case, a general matrix is handled
        float m3[9] = {world[0], world[4], world[8], world[1], world[5],
                       world[9], world[2], world[6], world[10]};  // rows = columns of the column-major matrix
        const float det = m3[0] * (m3[4] * m3[8] - m3[5] * m3[7]) - m3[1] * (m3[3] * m3[8] - m3[5] * m3[6]) +
                          m3[2] * (m3[3] * m3[7] - m3[4] * m3[6]);
        const bool mirrored = det < 0;
        float inv[9] = {};
        if (std::fabs(det) > 1e-20f) {
            inv[0] = (m3[4] * m3[8] - m3[5] * m3[7]) / det;
            inv[1] = (m3[2] * m3[7] - m3[1] * m3[8]) / det;
            inv[2] = (m3[1] * m3[5] - m3[2] * m3[4]) / det;
            inv[3] = (m3[5] * m3[6] - m3[3] * m3[8]) / det;
            inv[4] = (m3[0] * m3[8] - m3[2] * m3[6]) / det;
            inv[5] = (m3[2] * m3[3] - m3[0] * m3[5]) / det;
            inv[6] = (m3[3] * m3[7] - m3[4] * m3[6]) / det;
            inv[7] = (m3[1] * m3[6] - m3[0] * m3[7]) / det;
            inv[8] = (m3[0] * m3[4] - m3[1] * m3[3]) / det;
        }
        for (cgltf_size pi = 0; pi < node.mesh->primitives_count; ++pi) {
            const cgltf_primitive& prim = node.mesh->primitives[pi];
            if (prim.type != cgltf_primitive_type_triangles) {
                ++skipped;
                continue;
            }
            const cgltf_accessor *pos = nullptr, *nrm = nullptr, *uv = nullptr, *col = nullptr;
            for (cgltf_size a = 0; a < prim.attributes_count; ++a) {
                const cgltf_attribute& at = prim.attributes[a];
                if (at.index != 0) continue;
                if (at.type == cgltf_attribute_type_position)
                    pos = at.data;
                else if (at.type == cgltf_attribute_type_normal)
                    nrm = at.data;
                else if (at.type == cgltf_attribute_type_texcoord)
                    uv = at.data;
                else if (at.type == cgltf_attribute_type_color)
                    col = at.data;
            }
            if (!pos || pos->count == 0) continue;
            // Nodes may share one mesh, so a few thousand bytes of file can place millions of vertices: stop before the arrays grow.
            if (positions.size() / 3 + pos->count > kMaxProceduralVertices)
                return make_error(
                    std::format("'{}' has more than the {} vertices a mesh can hold once every node is placed", path,
                                kMaxProceduralVertices),
                    "Decimate it in the tool that made it, or split it into several files.");
            const auto base = std::uint32_t(positions.size() / 3);
            for (cgltf_size i = 0; i < pos->count; ++i) {
                float p[3] = {0, 0, 0};
                cgltf_accessor_read_float(pos, i, p, 3);
                positions.push_back(world[0] * p[0] + world[4] * p[1] + world[8] * p[2] + world[12]);
                positions.push_back(world[1] * p[0] + world[5] * p[1] + world[9] * p[2] + world[13]);
                positions.push_back(world[2] * p[0] + world[6] * p[1] + world[10] * p[2] + world[14]);
                if (nrm) {
                    float n[3] = {0, 0, 1};
                    cgltf_accessor_read_float(nrm, i, n, 3);
                    float x = inv[0] * n[0] + inv[3] * n[1] + inv[6] * n[2];
                    float y = inv[1] * n[0] + inv[4] * n[1] + inv[7] * n[2];
                    float z = inv[2] * n[0] + inv[5] * n[1] + inv[8] * n[2];
                    const float l = std::sqrt(x * x + y * y + z * z);
                    if (l > 1e-12f) {
                        x /= l;
                        y /= l;
                        z /= l;
                    }
                    normals.insert(normals.end(), {x, y, z});
                }
                if (uv) {
                    float t[2] = {0, 0};
                    cgltf_accessor_read_float(uv, i, t, 2);
                    uvs.insert(uvs.end(), {t[0], t[1]});
                } else {
                    uvs.insert(uvs.end(), {0, 0});
                }
                if (col) {
                    float c[4] = {1, 1, 1, 1};
                    cgltf_accessor_read_float(col, i, c, cgltf_num_components(col->type) >= 4 ? 4 : 3);
                    colors.insert(colors.end(), {c[0], c[1], c[2], cgltf_num_components(col->type) >= 4 ? c[3] : 1.0f});
                } else {
                    colors.insert(colors.end(), {1, 1, 1, 1});
                }
            }
            if (!nrm) allNormals = false;
            if (uv)
                anyUvs = true;
            else
                allUvs = false;
            if (col)
                anyColors = true;
            else
                allColors = false;
            if (!nrm)
                normals.insert(normals.end(), pos->count * 3,
                               0.0f);  // keeps the arrays the same length; dropped below when any primitive had none

            const std::size_t material = material_of(prim.material);
            const std::string part = primitive_part(data, prim);
            if (part.find('+') != std::string::npos &&
                std::find(plusParts.begin(), plusParts.end(), part) == plusParts.end()) {
                plusParts.push_back(part);
                out.warnings.push_back(
                    std::format("the part name \"{}\" contains \"+\", which joins the names of merged parts (rig.bake "
                                "mergeParts), so model.game_ready's collider.part cannot pick it on its own; "
                                "rename it in the file's primitive extras (e.g. \"{}\")",
                                part, replace_all(part, "+", "_")));
            }
            auto it = std::find_if(groups.begin(), groups.end(),
                                   [&](const Group& g) { return g.material == material && g.part == part; });
            if (it == groups.end()) {
                groups.push_back({material, part, {}});
                it = groups.end() - 1;
            }
            const cgltf_size count = prim.indices ? prim.indices->count : pos->count;
            indexTotal += count - count % 3;
            if (indexTotal > kMaxProceduralIndices)
                return make_error(
                    std::format("'{}' has more than the {} triangles a mesh can hold once every node is placed", path,
                                kMaxProceduralIndices / 3),
                    "Decimate it in the tool that made it, or split it into several files.");
            for (cgltf_size i = 0; i + 2 < count; i += 3) {
                std::uint32_t t[3];
                for (int k = 0; k < 3; ++k) {
                    const cgltf_size idx = prim.indices ? cgltf_accessor_read_index(prim.indices, i + k) : i + k;
                    t[k] = base + std::uint32_t(idx);
                }
                if (mirrored) std::swap(t[1], t[2]);
                it->indices.insert(it->indices.end(), {t[0], t[1], t[2]});
            }
        }
    }
    if (skipped > 0)
        out.warnings.push_back(
            std::format("{} primitive(s) are not triangles (points or lines) and were skipped", skipped));
    if (skinned > 0)
        out.warnings.push_back(
            "the file is skinned: the mesh is read in its bind pose and the skeleton and animations are not kept");
    if (positions.empty() || groups.empty())
        return make_error(std::format("'{}' contains no triangle meshes", path),
                          "Export the model with at least one mesh made of triangles.");
    if (positions.size() / 3 > kMaxProceduralVertices)
        return make_error(std::format("'{}' has {} vertices, more than the {} a mesh can hold", path,
                                      positions.size() / 3, kMaxProceduralVertices),
                          "Decimate it in the tool that made it, or split it into several files.");

    MeshInput in;
    in.positions = std::move(positions);
    if (allNormals) in.normals = std::move(normals);
    if (anyUvs) {
        in.uvs = std::move(uvs);
        if (!allUvs) out.warnings.push_back("some primitives have no texture coordinates (their uvs are 0, 0)");
    }
    if (anyColors) {
        in.colors = std::move(colors);
        if (!allColors) out.warnings.push_back("some primitives have no vertex colours (white is used for them)");
    }
    in.hasIndices = true;
    // groups in order of first use; the material list follows the same order
    for (const Group& g : groups) {
        MeshSubmesh sm;
        sm.start = std::uint32_t(in.indices.size());
        sm.count = std::uint32_t(g.indices.size());
        sm.part = g.part;
        if (g.material != kNoMaterial) sm.material = out.materials[g.material];
        in.indices.insert(in.indices.end(), g.indices.begin(), g.indices.end());
        in.submeshes.push_back(sm);
        out.submeshMaterial.push_back(g.material);
    }
    if (in.indices.size() > kMaxProceduralIndices)
        return make_error(std::format("'{}' has {} triangles, more than the {} a mesh can hold", path,
                                      in.indices.size() / 3, kMaxProceduralIndices / 3),
                          "Decimate it in the tool that made it, or split it into several files.");
    auto built = build_mesh_data(in);
    if (!built) return make_error(std::format("'{}': {}", path, built.error().message), built.error().hint);
    out.data = std::move(*built);
    return out;
}

}  // namespace fa
