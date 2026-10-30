// Texture + mesh caches, procedural primitives and glTF loading.
#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <format>

#include <cgltf.h>

#include "fa/core/asset_manifest.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/scene/gltf_file.h"
#include "fa/scene/skeleton.h"
#include "render_internal.h"

namespace fa::render {

// ---------------------------------------------------------------------------
// Procedural primitives
// ---------------------------------------------------------------------------
namespace {

void add_face(std::vector<MeshVertex>& v, std::vector<std::uint32_t>& idx, Vec3 n, Vec3 r, Vec3 u, Vec3 center, float half) {
    auto base = std::uint32_t(v.size());
    const Vec2 uvs[4] = {{0, 1}, {1, 1}, {1, 0}, {0, 0}};
    const float sx[4] = {-1, 1, 1, -1}, sy[4] = {-1, -1, 1, 1};
    for (int i = 0; i < 4; ++i) {
        Vec3 p = center + r * (sx[i] * half) + u * (sy[i] * half);
        v.push_back({p.x, p.y, p.z, n.x, n.y, n.z, uvs[i].x, uvs[i].y});
    }
    idx.insert(idx.end(), {base, base + 1, base + 2, base, base + 2, base + 3});
}

// Makes every triangle counter-clockwise when seen from the side its vertex normals point to.
void fix_winding(const std::vector<MeshVertex>& v, std::vector<std::uint32_t>& idx) {
    for (std::size_t i = 0; i + 2 < idx.size(); i += 3) {
        const MeshVertex &a = v[idx[i]], &b = v[idx[i + 1]], &c = v[idx[i + 2]];
        Vec3 pa{a.px, a.py, a.pz}, pb{b.px, b.py, b.pz}, pc{c.px, c.py, c.pz};
        Vec3 fn = cross(pb - pa, pc - pa);
        Vec3 vn{a.nx + b.nx + c.nx, a.ny + b.ny + c.ny, a.nz + b.nz + c.nz};
        if (dot(fn, vn) < 0.0f) std::swap(idx[i + 1], idx[i + 2]);
    }
}

void add_revolved(std::vector<MeshVertex>& v, std::vector<std::uint32_t>& idx, int segments,
                  const std::vector<Vec3>& rings /* x = radius, y = height, z = v coordinate */,
                  const std::vector<Vec2>& ringNormals /* x = radial, y = vertical */) {
    auto base = std::uint32_t(v.size());
    for (std::size_t r = 0; r < rings.size(); ++r) {
        for (int s = 0; s <= segments; ++s) {
            float a = float(s) / float(segments) * kTau;
            float ca = std::cos(a), sa = std::sin(a);
            Vec3 n = normalize(Vec3{ringNormals[r].x * ca, ringNormals[r].y, ringNormals[r].x * sa});
            v.push_back({rings[r].x * ca, rings[r].y, rings[r].x * sa, n.x, n.y, n.z, float(s) / float(segments), rings[r].z});
        }
    }
    for (std::size_t r = 0; r + 1 < rings.size(); ++r) {
        for (int s = 0; s < segments; ++s) {
            std::uint32_t a = base + std::uint32_t(r) * (segments + 1) + s;
            std::uint32_t b = a + segments + 1;
            idx.insert(idx.end(), {a, b, a + 1, a + 1, b, b + 1});
        }
    }
}

void add_disc(std::vector<MeshVertex>& v, std::vector<std::uint32_t>& idx, int segments, float radius, float y, float ny) {
    auto base = std::uint32_t(v.size());
    v.push_back({0, y, 0, 0, ny, 0, 0.5f, 0.5f});
    for (int s = 0; s <= segments; ++s) {
        float a = float(s) / float(segments) * kTau;
        float ca = std::cos(a), sa = std::sin(a);
        v.push_back({radius * ca, y, radius * sa, 0, ny, 0, 0.5f + 0.5f * ca, 0.5f + 0.5f * sa});
    }
    for (int s = 0; s < segments; ++s) idx.insert(idx.end(), {base, base + 1 + std::uint32_t(s), base + 2 + std::uint32_t(s)});
}

// Tangents from the UVs, per triangle and averaged over the vertex (the MikkTSpace idea without its vertex splitting):
// tangent = direction of growing u, bitangent = direction of growing v with v up (glTF flips the image's v), handedness w
// from the sign of cross(normal, tangent) . bitangent. Triangles without a UV area add nothing.
void generate_tangents(std::vector<MeshVertex>& v, const std::vector<std::uint32_t>& idx) {
    std::vector<Vec3> tan(v.size()), bit(v.size());
    for (std::size_t i = 0; i + 2 < idx.size(); i += 3) {
        const MeshVertex &a = v[idx[i]], &b = v[idx[i + 1]], &c = v[idx[i + 2]];
        Vec3 e1{b.px - a.px, b.py - a.py, b.pz - a.pz}, e2{c.px - a.px, c.py - a.py, c.pz - a.pz};
        float du1 = b.u - a.u, du2 = c.u - a.u;
        float dv1 = a.v - b.v, dv2 = a.v - c.v;  // v up
        float det = du1 * dv2 - du2 * dv1;
        if (std::fabs(det) < 1e-12f) continue;
        float r = 1.0f / det;
        Vec3 t = (e1 * dv2 - e2 * dv1) * r;
        Vec3 bt = (e2 * du1 - e1 * du2) * r;
        for (std::uint32_t k : {idx[i], idx[i + 1], idx[i + 2]}) { tan[k] = tan[k] + t; bit[k] = bit[k] + bt; }
    }
    for (std::size_t i = 0; i < v.size(); ++i) {
        MeshVertex& x = v[i];
        Vec3 n = normalize(Vec3{x.nx, x.ny, x.nz});
        const float tl = length(tan[i]);
        Vec3 t = tl > 0.0f ? tan[i] / tl : Vec3{};
        t = t - n * dot(n, t);
        if (length(t) < 1e-3f) {  // no usable UVs (or a tangent along the normal): any direction across the normal
            t = std::fabs(n.y) < 0.9f ? cross(Vec3{0, 1, 0}, n) : cross(Vec3{1, 0, 0}, n);
        }
        t = normalize(t);
        x.tx = t.x; x.ty = t.y; x.tz = t.z;
        x.tw = dot(cross(n, t), bit[i]) < 0.0f ? -1.0f : 1.0f;
    }
}

}  // namespace

bool build_primitive(const std::string& rawName, std::vector<MeshVertex>& v, std::vector<std::uint32_t>& idx) {
    std::string name = to_lower(rawName);
    v.clear();
    idx.clear();
    const float h = 0.5f;
    if (name == "cube") {
        add_face(v, idx, {0, 0, 1}, {1, 0, 0}, {0, 1, 0}, {0, 0, h}, h);
        add_face(v, idx, {0, 0, -1}, {-1, 0, 0}, {0, 1, 0}, {0, 0, -h}, h);
        add_face(v, idx, {1, 0, 0}, {0, 0, -1}, {0, 1, 0}, {h, 0, 0}, h);
        add_face(v, idx, {-1, 0, 0}, {0, 0, 1}, {0, 1, 0}, {-h, 0, 0}, h);
        add_face(v, idx, {0, 1, 0}, {1, 0, 0}, {0, 0, -1}, {0, h, 0}, h);
        add_face(v, idx, {0, -1, 0}, {1, 0, 0}, {0, 0, 1}, {0, -h, 0}, h);
    } else if (name == "plane") {
        add_face(v, idx, {0, 1, 0}, {1, 0, 0}, {0, 0, -1}, {0, 0, 0}, h);
    } else if (name == "quad") {
        add_face(v, idx, {0, 0, 1}, {1, 0, 0}, {0, 1, 0}, {0, 0, 0}, h);
    } else if (name == "sphere") {
        const int seg = 32, rings = 16;
        std::vector<Vec3> r;
        std::vector<Vec2> n;
        for (int i = 0; i <= rings; ++i) {
            float t = float(i) / float(rings) * kPi;
            r.push_back({std::sin(t) * h, std::cos(t) * h, float(i) / float(rings)});
            n.push_back({std::sin(t), std::cos(t)});
        }
        add_revolved(v, idx, seg, r, n);
    } else if (name == "cylinder") {
        const int seg = 32;
        add_revolved(v, idx, seg, {{h, h, 0.0f}, {h, -h, 1.0f}}, {{1, 0}, {1, 0}});
        add_disc(v, idx, seg, h, h, 1.0f);
        add_disc(v, idx, seg, h, -h, -1.0f);
    } else if (name == "capsule") {
        const int seg = 32, half = 8;
        std::vector<Vec3> r;
        std::vector<Vec2> n;
        for (int i = 0; i <= half; ++i) {  // top hemisphere
            float t = float(i) / float(half) * (kPi * 0.5f);
            r.push_back({std::sin(t) * h, std::cos(t) * h + 0.5f, float(i) / float(2 * half + 2)});
            n.push_back({std::sin(t), std::cos(t)});
        }
        for (int i = 0; i <= half; ++i) {  // bottom hemisphere
            float t = kPi * 0.5f + float(i) / float(half) * (kPi * 0.5f);
            r.push_back({std::sin(t) * h, std::cos(t) * h - 0.5f, float(half + 1 + i) / float(2 * half + 2)});
            n.push_back({std::sin(t), std::cos(t)});
        }
        add_revolved(v, idx, seg, r, n);
    } else if (name == "cone") {
        const int seg = 32;
        float slope = h / 1.0f;  // radius / height
        Vec2 sn = {1.0f, slope};
        add_revolved(v, idx, seg, {{0.0f, h, 0.0f}, {h, -h, 1.0f}}, {sn, sn});
        add_disc(v, idx, seg, h, -h, -1.0f);
    } else {
        return false;
    }
    fix_winding(v, idx);
    generate_tangents(v, idx);
    return true;
}

namespace {

void compute_bounds(const std::vector<MeshVertex>& v, Vec3& bmin, Vec3& bmax) {
    bmin = {1e30f, 1e30f, 1e30f};
    bmax = {-1e30f, -1e30f, -1e30f};
    for (const auto& x : v) {
        bmin = min(bmin, Vec3{x.px, x.py, x.pz});
        bmax = max(bmax, Vec3{x.px, x.py, x.pz});
    }
    if (v.empty()) bmin = bmax = {0, 0, 0};
}

SubMesh upload_submesh(const std::vector<MeshVertex>& v, const std::vector<std::uint32_t>& idx, const char* label) {
    SubMesh m;
    sg_buffer_desc vb{};
    vb.data = {v.data(), v.size() * sizeof(MeshVertex)};
    vb.label = label;
    m.vb = sg_make_buffer(&vb);
    sg_buffer_desc ib{};
    ib.usage.index_buffer = true;
    ib.usage.vertex_buffer = false;
    ib.data = {idx.data(), idx.size() * sizeof(std::uint32_t)};
    ib.label = label;
    m.ib = sg_make_buffer(&ib);
    m.vertexCount = int(v.size());
    m.indexCount = int(idx.size());
    compute_bounds(v, m.bmin, m.bmax);
    return m;
}

}  // namespace

// ---------------------------------------------------------------------------
// glTF loader
// ---------------------------------------------------------------------------
class MeshLoader {
public:
    MeshLoader(Assets& assets) : assets_(assets) {}

    bool load(const std::string& path, MeshAsset& out, std::string& error) {
        auto bytes = fs::read_bytes(path);
        if (!bytes) {
            error = bytes.error().message;
            return false;
        }
        cgltf_options opts{};
        gltf_use_fs(opts);
        cgltf_data* data = nullptr;
        cgltf_result r = cgltf_parse(&opts, bytes->data(), bytes->size(), &data);
        if (r != cgltf_result_success) {
            error = std::format("cgltf could not parse '{}' (error code {}). The file must be a valid glTF 2.0 (.gltf or .glb) file.", path, int(r));
            return false;
        }
        struct Guard { cgltf_data* d; ~Guard() { cgltf_free(d); } } guard{data};
        r = cgltf_load_buffers(&opts, data, path.c_str());
        if (r != cgltf_result_success) {
            error = std::format("cannot load the buffers referenced by '{}' (cgltf error {}). External .bin files must sit next to the .gltf and be inside the project.", path, int(r));
            return false;
        }
        std::string dir = fs::parent(path);
        out.bmin = {1e30f, 1e30f, 1e30f};
        out.bmax = {-1e30f, -1e30f, -1e30f};
        for (cgltf_size ni = 0; ni < data->nodes_count; ++ni) {
            const cgltf_node& node = data->nodes[ni];
            if (!node.mesh) continue;
            Mat4 world;
            cgltf_node_transform_world(&node, world.m);
            // glTF: the transform of a skinned mesh node is ignored (the joints place the mesh); it is drawn in bind pose.
            // A rigid part keeps its node transform: the importer's rigid skin (skeleton.cpp) moves it with its animated node.
            if (node.skin) world = Mat4::identity();
            Mat4 normalMat = world.inverse().transposed();
            for (cgltf_size pi = 0; pi < node.mesh->primitives_count; ++pi) {
                const cgltf_primitive& prim = node.mesh->primitives[pi];
                if (prim.type != cgltf_primitive_type_triangles) {
                    FA_WARN("render", "{}: mesh '{}' primitive {} uses a non-triangle mode; skipped", path,
                            node.mesh->name ? node.mesh->name : "?", pi);
                    continue;
                }
                std::vector<MeshVertex> verts;
                std::vector<std::uint32_t> idx;
                if (!read_primitive(prim, world, normalMat, verts, idx)) continue;
                SubMesh sm = upload_submesh(verts, idx, path.c_str());
                apply_material(prim.material, dir, data, sm);
                attach_skin(path, int(ni), int(pi), verts.size(), sm);
                out.bmin = min(out.bmin, sm.bmin);
                out.bmax = max(out.bmax, sm.bmax);
                out.parts.push_back(sm);
            }
        }
        if (out.parts.empty()) {
            error = std::format("'{}' contains no triangle meshes", path);
            return false;
        }
        return true;
    }

private:
    // Gives a part of a skinned glTF node its joints and weights (vertex buffer 2). Each part is drawn with the
    // palette of its own skin; a skin with more than kMaxSkinJoints joints is not drawn skinned, so the part stays in bind pose.
    void attach_skin(const std::string& path, int node, int primitive, std::size_t vertexCount, SubMesh& sm) {
        if (!skeleton_) {
            auto r = load_skeleton(path);
            if (!r) return;
            skeleton_ = *r;
        }
        for (const SkinVertices& sv : skeleton_->skinVertices) {
            if (sv.node != node || sv.primitive != primitive || sv.joints.size() != vertexCount) continue;
            const std::size_t joints = skeleton_->skins[std::size_t(sv.skin)].joints.size();
            if (joints > std::size_t(kMaxSkinJoints)) {
                FA_WARN("render", "{}: the skin has {} joints - drawn in bind pose, not animated. Skinning supports skins with at most "
                                  "{} joints; re-export the model with fewer joints.", path, joints, kMaxSkinJoints);
                return;
            }
            std::vector<SkinVertex> v(vertexCount);
            for (std::size_t i = 0; i < vertexCount; ++i)
                for (std::size_t k = 0; k < 4; ++k) {
                    v[i].joints[k] = std::uint8_t(sv.joints[i][k]);
                    v[i].weights[k] = sv.weights[i][k];
                }
            sg_buffer_desc bd{};
            bd.data = {v.data(), v.size() * sizeof(SkinVertex)};
            bd.label = "skin";
            sm.skinVb = sg_make_buffer(&bd);
            sm.skin = sv.skin;
            return;
        }
    }

    std::shared_ptr<const SkeletonAsset> skeleton_;

    bool read_primitive(const cgltf_primitive& prim, const Mat4& world, const Mat4& normalMat,
                        std::vector<MeshVertex>& verts, std::vector<std::uint32_t>& idx) {
        const cgltf_accessor *pos = nullptr, *nrm = nullptr, *uv = nullptr, *tng = nullptr;
        for (cgltf_size a = 0; a < prim.attributes_count; ++a) {
            const cgltf_attribute& at = prim.attributes[a];
            if (at.type == cgltf_attribute_type_position && at.index == 0) pos = at.data;
            else if (at.type == cgltf_attribute_type_normal && at.index == 0) nrm = at.data;
            else if (at.type == cgltf_attribute_type_texcoord && at.index == 0) uv = at.data;
            else if (at.type == cgltf_attribute_type_tangent && at.index == 0 && at.data->type == cgltf_type_vec4) tng = at.data;
        }
        if (!pos) return false;
        verts.resize(pos->count);
        for (cgltf_size i = 0; i < pos->count; ++i) {
            float p[3] = {0, 0, 0};
            cgltf_accessor_read_float(pos, i, p, 3);
            Vec3 wp = world.transform_point({p[0], p[1], p[2]});
            MeshVertex& v = verts[i];
            v.px = wp.x; v.py = wp.y; v.pz = wp.z;
            float n[3] = {0, 1, 0};
            if (nrm) cgltf_accessor_read_float(nrm, i, n, 3);
            Vec3 wn = normalize(normalMat.transform_dir({n[0], n[1], n[2]}));
            v.nx = wn.x; v.ny = wn.y; v.nz = wn.z;
            float t[2] = {0, 0};
            if (uv) cgltf_accessor_read_float(uv, i, t, 2);
            v.u = t[0]; v.v = t[1];
            float tn[4] = {1, 0, 0, 1};
            if (tng) cgltf_accessor_read_float(tng, i, tn, 4);
            Vec3 wt = normalize(world.transform_dir({tn[0], tn[1], tn[2]}));
            v.tx = wt.x; v.ty = wt.y; v.tz = wt.z; v.tw = tn[3] < 0.0f ? -1.0f : 1.0f;
        }
        if (prim.indices) {
            idx.resize(prim.indices->count);
            for (cgltf_size i = 0; i < prim.indices->count; ++i) idx[i] = std::uint32_t(cgltf_accessor_read_index(prim.indices, i));
        } else {
            idx.resize(pos->count);
            for (cgltf_size i = 0; i < pos->count; ++i) idx[i] = std::uint32_t(i);
        }
        // Negative-determinant node transforms mirror the mesh: flip winding to keep faces outward.
        Vec3 c0{world.at(0, 0), world.at(0, 1), world.at(0, 2)};
        Vec3 c1{world.at(1, 0), world.at(1, 1), world.at(1, 2)};
        Vec3 c2{world.at(2, 0), world.at(2, 1), world.at(2, 2)};
        const bool mirrored = dot(cross(c0, c1), c2) < 0.0f;
        if (mirrored) {
            for (std::size_t i = 0; i + 2 < idx.size(); i += 3) std::swap(idx[i + 1], idx[i + 2]);
            for (auto& v : verts) v.tw = -v.tw;
        }
        if (!nrm) generate_normals(verts, idx);
        if (!tng) generate_tangents(verts, idx);
        return !idx.empty();
    }

    static void generate_normals(std::vector<MeshVertex>& v, const std::vector<std::uint32_t>& idx) {
        for (auto& x : v) x.nx = x.ny = x.nz = 0;
        for (std::size_t i = 0; i + 2 < idx.size(); i += 3) {
            MeshVertex &a = v[idx[i]], &b = v[idx[i + 1]], &c = v[idx[i + 2]];
            Vec3 n = cross(Vec3{b.px - a.px, b.py - a.py, b.pz - a.pz}, Vec3{c.px - a.px, c.py - a.py, c.pz - a.pz});
            for (MeshVertex* m : {&a, &b, &c}) { m->nx += n.x; m->ny += n.y; m->nz += n.z; }
        }
        for (auto& x : v) {
            Vec3 n = normalize(Vec3{x.nx, x.ny, x.nz});
            if (length_sq(n) < 0.5f) n = {0, 1, 0};
            x.nx = n.x; x.ny = n.y; x.nz = n.z;
        }
    }

    void apply_material(const cgltf_material* mat, const std::string& dir, const cgltf_data* data, SubMesh& sm) {
        if (!mat) return;
        if (mat->name) sm.materialName = mat->name;
        sm.doubleSided = mat->double_sided;
        sm.blended = mat->alpha_mode == cgltf_alpha_mode_blend;
        if (mat->has_pbr_metallic_roughness) {
            const auto& pbr = mat->pbr_metallic_roughness;
            sm.baseColor = Color{pbr.base_color_factor[0], pbr.base_color_factor[1], pbr.base_color_factor[2], pbr.base_color_factor[3]};
            const cgltf_texture* tex = pbr.base_color_texture.texture;
            if (tex && tex->image) sm.texture = image_texture(*tex->image, dir, data);
            sm.hasPbr = true;
            sm.metallic = pbr.metallic_factor;
            sm.roughness = pbr.roughness_factor;
            const cgltf_texture* mr = pbr.metallic_roughness_texture.texture;
            if (mr && mr->image) sm.mrTex = image_texture(*mr->image, dir, data);
        }
        const cgltf_texture* nt = mat->normal_texture.texture;
        if (nt && nt->image) {
            sm.normalTex = image_texture(*nt->image, dir, data);
            sm.normalScale = mat->normal_texture.scale;
        }
        const cgltf_texture* ot = mat->occlusion_texture.texture;
        if (ot && ot->image) {
            sm.occlusionTex = image_texture(*ot->image, dir, data);
            sm.occlusionStrength = mat->occlusion_texture.scale;
        }
        const cgltf_texture* et = mat->emissive_texture.texture;
        if (et && et->image) sm.emissiveTex = image_texture(*et->image, dir, data);
        float strength = mat->has_emissive_strength ? mat->emissive_strength.emissive_strength : 1.0f;
        sm.emissiveFactor = Color{mat->emissive_factor[0] * strength, mat->emissive_factor[1] * strength,
                                  mat->emissive_factor[2] * strength, 1.0f};
    }

    TextureAsset* image_texture(const cgltf_image& img, const std::string& dir, const cgltf_data* data) {
        if (img.buffer_view) {
            const auto* base = static_cast<const std::uint8_t*>(img.buffer_view->buffer->data);
            auto decoded = decode_image(base + img.buffer_view->offset, img.buffer_view->size);
            std::string name = std::format("<gltf-embedded:{}>", img.name ? img.name : "image");
            if (!decoded) {
                assets_.note_failure("texture", name, decoded.error().message, decoded.error().hint);
                return assets_.texture("<missing-embedded-image>");
            }
            return assets_.make_texture(name, *decoded, true);
        }
        if (img.uri) {
            std::string uri = img.uri;
            if (uri.rfind("data:", 0) == 0) {
                auto comma = uri.find(',');
                if (comma != std::string::npos) {
                    auto raw = base64_decode(std::string_view(uri).substr(comma + 1));
                    auto decoded = decode_image(raw.data(), raw.size());
                    if (decoded) return assets_.make_texture("<gltf-data-uri>", *decoded, true);
                }
                return assets_.texture("<missing-embedded-image>");
            }
            std::vector<char> buf(uri.begin(), uri.end());
            buf.push_back('\0');
            cgltf_decode_uri(buf.data());
            uri = buf.data();
            return assets_.texture(dir.empty() ? uri : fs::join(dir, uri));
        }
        (void)data;
        return nullptr;
    }

    Assets& assets_;
};

// ---------------------------------------------------------------------------
// Assets
// ---------------------------------------------------------------------------
Assets::Assets(Gpu& gpu) : gpu_(gpu) {
    Image white;
    white.width = white.height = 1;
    white.rgba = {255, 255, 255, 255};
    white_ = std::make_unique<TextureAsset>();
    white_->path = "<white>";
    upload_texture(*white_, white, false);

    // Magenta/black checker for missing textures.
    Image chk;
    chk.width = chk.height = 32;
    chk.rgba.resize(32 * 32 * 4);
    for (int y = 0; y < 32; ++y) {
        for (int x = 0; x < 32; ++x) {
            bool on = ((x / 8) + (y / 8)) % 2 == 0;
            std::uint8_t* p = &chk.rgba[(std::size_t(y) * 32 + x) * 4];
            p[0] = on ? 255 : 0; p[1] = 0; p[2] = on ? 255 : 0; p[3] = 255;
        }
    }
    placeholderTex_ = std::make_unique<TextureAsset>();
    placeholderTex_->path = "<missing>";
    placeholderTex_->placeholder = true;
    upload_texture(*placeholderTex_, chk, false);

    std::vector<MeshVertex> v;
    std::vector<std::uint32_t> idx;
    build_primitive("cube", v, idx);
    placeholderMesh_ = std::make_unique<MeshAsset>();
    placeholderMesh_->key = "<missing>";
    placeholderMesh_->placeholder = true;
    SubMesh sm = upload_submesh(v, idx, "placeholder-cube");
    sm.texture = placeholderTex_.get();
    placeholderMesh_->bmin = sm.bmin;
    placeholderMesh_->bmax = sm.bmax;
    placeholderMesh_->parts.push_back(sm);
}

Assets::~Assets() {
    clear();
    for (auto& [k, t] : runtime_) destroy_texture(*t);
    runtime_.clear();
    destroy_texture(*white_);
    destroy_texture(*placeholderTex_);
    destroy_mesh(*placeholderMesh_);
}

void Assets::destroy_texture(TextureAsset& t) {
    if (!t.atlas) {  // a packed texture borrows the GPU image of its atlas
        if (t.view.id) sg_destroy_view(t.view);
        if (t.image.id) sg_destroy_image(t.image);
    }
    t.view = {};
    t.image = {};
    t.atlas = nullptr;
}

void Assets::destroy_mesh(MeshAsset& m) {
    for (auto& p : m.parts) {
        sg_destroy_buffer(p.vb);
        sg_destroy_buffer(p.ib);
        if (p.skinVb.id) sg_destroy_buffer(p.skinVb);
    }
    m.parts.clear();
}

void Assets::clear() {
    for (auto& [k, v] : videoTextures_) destroy_texture(*v.tex);
    videoTextures_.clear();
    for (auto& [k, t] : textures_) destroy_texture(*t);
    textures_.clear();
    for (auto& t : anonymous_) destroy_texture(*t);
    anonymous_.clear();
    for (auto& [k, m] : meshes_) destroy_mesh(*m);
    meshes_.clear();
    for (auto& [k, pm] : procedural_) destroy_procedural(pm);
    procedural_.clear();
    meshStore_ = nullptr;
    meshStoreSerial_ = 0;
    for (auto& [k, m] : materials_)
        for (MaterialProgram& p : m->programs)
            if (p.shader.id) gpu_.destroy_shader(p.shader);
    materials_.clear();
    failures_.clear();
    meshSources_.clear();
}

TextureAsset* Assets::white() { return white_.get(); }

void Assets::upload_texture(TextureAsset& t, const Image& img, bool mips) {
    const std::vector<Image> chain = mips ? mip_chain(img) : std::vector<Image>();
    sg_image_desc d{};
    d.width = img.width;
    d.height = img.height;
    d.pixel_format = SG_PIXELFORMAT_RGBA8;
    d.num_mipmaps = mips ? int(chain.size()) : 1;
    d.data.mip_levels[0] = {img.rgba.data(), img.rgba.size()};
    t.bytes = img.rgba.size();
    for (std::size_t i = 1; i < chain.size(); ++i) {
        d.data.mip_levels[i] = {chain[i].rgba.data(), chain[i].rgba.size()};
        t.bytes += chain[i].rgba.size();
    }
    d.label = t.path.c_str();
    t.image = make_image(d);
    sg_view_desc vd{};
    vd.texture.image = t.image;
    vd.label = t.path.c_str();
    t.view = sg_make_view(&vd);
    t.width = img.width;
    t.height = img.height;
    t.format = SG_PIXELFORMAT_RGBA8;
}

// Uploads a KTX2 file in the best format the GPU samples. Falls back to RGBA8 when the driver rejects a compressed one.
bool Assets::upload_ktx2(TextureAsset& t, const std::vector<std::uint8_t>& file, std::string& error) {
    for (bool compressed : {true, false}) {
        auto tex = transcode_ktx2(file.data(), file.size(), compressed);
        if (!tex) {
            error = tex.error().message;
            return false;
        }
        sg_image_desc d{};
        d.width = tex->width;
        d.height = tex->height;
        d.pixel_format = tex->format;
        d.num_mipmaps = int(tex->levels.size());
        t.bytes = 0;
        for (std::size_t i = 0; i < tex->levels.size(); ++i) {
            d.data.mip_levels[i] = {tex->levels[i].data(), tex->levels[i].size()};
            t.bytes += tex->levels[i].size();
        }
        d.label = t.path.c_str();
        t.image = make_image(d);
        if (sg_query_image_state(t.image) == SG_RESOURCESTATE_VALID) {
            sg_view_desc vd{};
            vd.texture.image = t.image;
            vd.label = t.path.c_str();
            t.view = sg_make_view(&vd);
            t.width = tex->width;
            t.height = tex->height;
            t.format = tex->format;
            return true;
        }
        sg_destroy_image(t.image);
        t.image = {};
        if (tex->format == SG_PIXELFORMAT_RGBA8) break;
    }
    error = "the GPU rejected the texture";
    return false;
}

void Assets::use_placeholder(TextureAsset& t) {
    t.placeholder = true;
    t.image = placeholderTex_->image;  // shared handles; never destroyed through this asset
    t.view = placeholderTex_->view;
    t.width = placeholderTex_->width;
    t.height = placeholderTex_->height;
    t.format = SG_PIXELFORMAT_RGBA8;
    t.bytes = 0;
}

TextureAsset* Assets::make_texture(const std::string& name, const Image& img, bool mips) {
    auto t = std::make_unique<TextureAsset>();
    t->path = name;
    upload_texture(*t, img, mips);
    anonymous_.push_back(std::move(t));
    return anonymous_.back().get();
}

std::string Assets::make_runtime_texture(const Image& img) {
    const std::string id = "runtime:" + std::to_string(nextRuntime_++);
    auto t = std::make_unique<TextureAsset>();
    t->path = id;
    upload_texture(*t, img, true);
    runtime_[id] = std::move(t);
    return id;
}

bool Assets::destroy_runtime_texture(const std::string& id) {
    auto it = runtime_.find(id);
    if (it == runtime_.end()) return false;
    destroy_texture(*it->second);
    runtime_.erase(it);
    // A Sprite that still names the id drew the placeholder from now on: forget a stale lookup made before.
    textures_.erase(id);
    return true;
}

TextureAsset* Assets::video_texture(const std::shared_ptr<VideoDecoder>& decoder) {
    auto it = videoTextures_.find(decoder.get());
    if (it != videoTextures_.end() && it->second.decoder.lock() != decoder) {  // an address reused by another decoder
        destroy_texture(*it->second.tex);
        videoTextures_.erase(it);
        it = videoTextures_.end();
    }
    if (it == videoTextures_.end()) {
        VideoTexture v;
        v.decoder = decoder;
        v.tex = std::make_unique<TextureAsset>();
        v.tex->path = "<video>";
        it = videoTextures_.emplace(decoder.get(), std::move(v)).first;
    }
    VideoTexture& v = it->second;
    v.seen = true;
    TextureAsset& t = *v.tex;
    const VideoInfo& info = decoder->info();
    if (!t.image.id || t.width != info.width || t.height != info.height) {
        // One image per video, written in place: making an image for each picture cost a 60 fps video tens of
        // milliseconds a frame on a software renderer (llvmpipe). sokol keeps a copy per frame in flight.
        destroy_texture(t);
        sg_image_desc d{};
        d.usage.write_transient = true;
        d.width = info.width;
        d.height = info.height;
        d.pixel_format = SG_PIXELFORMAT_RGBA8;
        d.label = "video";
        t.image = make_image(d);
        sg_view_desc vd{};
        vd.texture.image = t.image;
        vd.label = "video";
        t.view = sg_make_view(&vd);
        t.width = info.width;
        t.height = info.height;
        t.format = SG_PIXELFORMAT_RGBA8;
        t.bytes = std::size_t(info.width) * std::size_t(info.height) * 4 * SG_NUM_INFLIGHT_FRAMES;
        v.writtenFrame = 0;
    }
    // A write-transient image is written in every sokol frame that draws it, once and before it is bound: a second
    // draw before the commit (editor screenshots, render_now) shows what the first one wrote.
    if (v.writtenFrame != gpu_.frame() + 1) {
        sg_write_image_desc w{};
        w.src.data = {decoder->picture(), std::size_t(info.width) * std::size_t(info.height) * 4};
        w.dst.image = t.image;
        sg_write_image_transient(&w);
        v.writtenFrame = gpu_.frame() + 1;
    }
    return &t;
}

void Assets::end_video_frame() {
    for (auto it = videoTextures_.begin(); it != videoTextures_.end();) {
        if (!it->second.seen) {
            destroy_texture(*it->second.tex);
            it = videoTextures_.erase(it);
        } else {
            it->second.seen = false;
            ++it;
        }
    }
}

std::string Assets::missing_hint(const std::string& path, std::string_view ext) const {
    std::vector<std::string> candidates = fs::list("assets", true, ext);
    std::string parent = fs::parent(path);
    if (!parent.empty() && parent != "assets") {
        auto local = fs::list(parent, false, ext);
        candidates.insert(candidates.end(), local.begin(), local.end());
    }
    std::string best = closest_match(path, candidates);
    std::string root = fs::project_root().generic_string();
    std::string msg = std::format("file not found: {} (project root is {}).", path, root);
    if (!best.empty()) msg += std::format(" Did you mean {}?", best);
    else if (candidates.empty()) msg += std::format(" No {} files exist under assets/; put the file in <project>/assets/ and reference it as assets/<name>.", ext.empty() ? "asset" : std::string(ext));
    else msg += " Existing files: " + did_you_mean(path, candidates, 8);
    return msg;
}

void Assets::note_failure(const std::string& kind, const std::string& path, const std::string& message, const std::string& hint) {
    if (failure_logged(kind, path)) return;
    failures_.push_back({kind, path, message, hint});
    const bool hinted = hint.empty() || message.find(hint) != std::string::npos;  // a shader diagnostic carries its hints
    FA_ERROR("render", "{}{}", message, hinted ? std::string() : " Hint: " + hint);
}

bool Assets::failure_logged(const std::string& kind, const std::string& path) const {
    for (const auto& f : failures_)
        if (f.kind == kind && f.path == path) return true;
    return false;
}

TextureAsset* Assets::load_texture(const std::string& path) {
    auto& slot = textures_[path];
    if (!slot) slot = std::make_unique<TextureAsset>();
    TextureAsset& t = *slot;
    t.path = path;
    destroy_texture(t);
    t.placeholder = false;
    // A successful (re)load clears an older failure record.
    auto loaded = [&]() -> TextureAsset* {
        failures_.erase(std::remove_if(failures_.begin(), failures_.end(),
                                       [&](const Failure& f) { return f.kind == "texture" && f.path == path; }),
                        failures_.end());
        return &t;
    };
    auto failed = [&](const std::string& message, const std::string& hint) -> TextureAsset* {
        note_failure("texture", path, message, hint);  // one error per path, even across reloads
        use_placeholder(t);
        return &t;
    };

    // An export packed this texture into an atlas (assets.json `packed`): borrow the atlas's GPU image.
    if (const assets::PackedTexture packed = assets::packed_texture(path); !packed.atlas.empty()) {
        TextureAsset* atlas = texture(packed.atlas);
        if (atlas->placeholder)
            return failed(std::format("texture '{}' is packed into the atlas '{}', which could not be loaded", path, packed.atlas),
                          "Export the project again.");
        t.atlas = atlas;
        t.atlasX = packed.x;
        t.atlasY = packed.y;
        t.width = packed.w;
        t.height = packed.h;
        t.format = atlas->format;
        t.bytes = 0;
        return loaded();
    }

    // An export replaces a texture by its compressed twin (path + ".ktx2"): the twin is loaded in place of the original.
    const std::string twin = fs::extension(path) == kTextureTwinExtension ? path : path + kTextureTwinExtension;
    if (fs::exists(twin)) {
        std::string error;
        auto bytes = fs::read_bytes(twin);
        if (!bytes) error = bytes.error().message;
        if (bytes && upload_ktx2(t, *bytes, error)) return loaded();
        return failed(std::format("texture '{}' could not be loaded: {}", twin, error), "Export the project again.");
    }
    if (!fs::exists(path)) {
        return failed("texture " + missing_hint(path, fs::extension(path)), "");
    }
    auto img = load_image(path);
    if (!img) return failed(std::format("texture '{}' could not be loaded: {}", path, img.error().message), img.error().hint);
    upload_texture(t, *img, true);
    return loaded();
}

TextureAsset* Assets::texture(const std::string& path) {
    if (path.empty()) return white_.get();
    if (is_runtime_id(path)) {  // before fs::normalize: the id is not a file path
        if (auto r = runtime_.find(path); r != runtime_.end()) return r->second.get();
        auto& slot = textures_[path];
        if (!slot) {
            slot = std::make_unique<TextureAsset>();
            slot->path = path;
            note_failure("texture", path,
                         std::format("'{}' is not a texture file but a run-time texture id, and no such texture exists now (it was "
                                     "destroyed with texture.destroy(), or it was made by an earlier run of the game).", path),
                         "Make the texture again with render.captureTexture() or render.textureFromPNG() and use its `id`.");
            use_placeholder(*slot);
        }
        return slot.get();
    }
    if (is_target_id(path)) {  // a render target: live, never cached (its image is remade when the camera's size changes)
        TextureAsset* t = targetResolver_ ? targetResolver_(path.substr(7)) : nullptr;
        if (t) {
            if (!failures_.empty())  // a camera renders into it now: an older "nobody renders into it" record is stale
                failures_.erase(std::remove_if(failures_.begin(), failures_.end(),
                                               [&](const Failure& f) { return f.kind == "texture" && f.path == path; }),
                                failures_.end());
            return t;
        }
        if (drawing_) note_failure("texture", path,
                     std::format("'{}' is a render target id but no active Camera renders into it now (Camera.renderTarget = '{}'). "
                                 "Until one does, the missing-texture checker is drawn.", path, path.substr(7)),
                     "Add a Camera entity with \"renderTarget\": \"" + path.substr(7) + "\" (and a renderTargetSize), keep it active, "
                     "and check the name against the camera's.");
        return placeholderTex_.get();
    }
    std::string key = fs::normalize(path);
    if (key.empty()) key = path;
    auto it = textures_.find(key);
    if (it != textures_.end()) return it->second.get();
    return load_texture(key);
}

bool Assets::has_loaded(const std::string& path) const {
    return textures_.count(path) || meshes_.count(path);
}

MeshAsset* Assets::load_mesh(const std::string& name) {
    auto& slot = meshes_[name];
    if (!slot) slot = std::make_unique<MeshAsset>();
    MeshAsset& m = *slot;
    destroy_mesh(m);
    m.key = name;
    m.placeholder = false;
    std::vector<MeshVertex> v;
    std::vector<std::uint32_t> idx;
    if (build_primitive(name, v, idx)) {
        SubMesh sm = upload_submesh(v, idx, name.c_str());
        m.bmin = sm.bmin;
        m.bmax = sm.bmax;
        m.parts.push_back(sm);
        return &m;
    }
    // A glTF/GLB asset path.
    static const char* kPrimitives = "cube, sphere, plane, cylinder, capsule, cone, quad";
    std::string ext = fs::extension(name);
    if (ext != ".gltf" && ext != ".glb") {
        std::vector<std::string> names = {"cube", "sphere", "plane", "cylinder", "capsule", "cone", "quad"};
        note_failure("mesh", name,
                     std::format("unknown mesh '{}'. {} Or use the path of a .gltf/.glb file (primitives: {}).", name,
                                 did_you_mean(name, names), kPrimitives),
                     "");
        m.placeholder = true;
        m.parts = placeholderMesh_->parts;  // shared GPU handles
        m.bmin = placeholderMesh_->bmin;
        m.bmax = placeholderMesh_->bmax;
        meshSources_.erase(name);
        return &m;
    }
    meshSources_[name] = name;
    std::string path = fs::normalize(name);
    std::string error;
    bool ok = false;
    if (!fs::exists(path)) {
        error = "mesh " + missing_hint(path, ext);
    } else {
        MeshLoader loader(*this);
        MeshAsset tmp;
        ok = loader.load(path, tmp, error);
        if (ok) {
            m.parts = std::move(tmp.parts);
            m.bmin = tmp.bmin;
            m.bmax = tmp.bmax;
        } else {
            error = "mesh " + error;
        }
    }
    if (!ok) {
        note_failure("mesh", name, error, "");
        m.placeholder = true;
        m.parts = placeholderMesh_->parts;
        m.bmin = placeholderMesh_->bmin;
        m.bmax = placeholderMesh_->bmax;
    }
    return &m;
}

MeshAsset* Assets::mesh(const std::string& name) {
    if (MeshStore::is_id(name)) return procedural_mesh(name);
    std::string key = name.empty() ? std::string("cube") : name;
    auto it = meshes_.find(key);
    if (it != meshes_.end()) return it->second.get();
    return load_mesh(key);
}

// ---------------------------------------------------------------------------
// Procedural meshes
// ---------------------------------------------------------------------------
void Assets::destroy_procedural(ProceduralMesh& pm) {
    for (sg_buffer* b : {&pm.vb, &pm.ib, &pm.vbStage, &pm.ibStage}) {
        if (b->id) sg_destroy_buffer(*b);
        *b = {};
    }
    pm.vbCap = pm.ibCap = 0;
    pm.stagedFrame = 0;
    if (pm.asset) pm.asset->parts.clear();
}

void Assets::set_mesh_store(const MeshStore* store) {
    if (!store || store->serial() != meshStoreSerial_) {
        for (auto& [id, pm] : procedural_) destroy_procedural(pm);
        procedural_.clear();
    }
    meshStore_ = store;
    meshStoreSerial_ = store ? store->serial() : 0;
    for (auto it = procedural_.begin(); it != procedural_.end();) {
        if (!store || !store->find(it->first)) {
            destroy_procedural(it->second);
            it = procedural_.erase(it);
        } else {
            ++it;
        }
    }
}

MeshAsset* Assets::procedural_mesh(const std::string& id) {
    const MeshStore::Entry* e = meshStore_ ? meshStore_->find(id) : nullptr;
    if (!e) {
        std::string message = std::format("MeshRenderer.mesh '{}' is not a mesh that exists", id), hint;
        if (meshStore_) {
            const Error err = meshStore_->get(id).error();
            message = "MeshRenderer.mesh: " + err.message;
            hint = err.hint;
        }
        note_failure("mesh", id, message,
                     hint.empty() ? "Make the mesh with mesh.create() in a script of the scene that shows it, and set MeshRenderer.mesh to its `id`."
                                  : hint);
        return placeholderMesh_.get();
    }
    ProceduralMesh& pm = procedural_[id];
    if (!pm.asset) {
        pm.asset = std::make_unique<MeshAsset>();
        pm.asset->key = id;
    }
    if (pm.version != e->version || pm.asset->parts.empty()) {
        upload_procedural(pm, *e);
        pm.version = e->version;
    }
    // Textures are looked up on every use: a run-time texture can be destroyed and a file can be reloaded under the part.
    for (std::size_t i = 0; i < pm.asset->parts.size() && i < pm.partTextures.size(); ++i)
        pm.asset->parts[i].texture = pm.partTextures[i].empty() ? nullptr : texture(pm.partTextures[i]);
    return pm.asset.get();
}

void Assets::upload_procedural(ProceduralMesh& pm, const MeshStore::Entry& e) {
    const MeshData& d = e.data;
    const std::size_t n = d.vertex_count();
    std::vector<MeshVertex> verts(n);
    for (std::size_t i = 0; i < n; ++i) {
        MeshVertex& v = verts[i];
        v.px = d.positions[i * 3]; v.py = d.positions[i * 3 + 1]; v.pz = d.positions[i * 3 + 2];
        v.nx = d.normals[i * 3]; v.ny = d.normals[i * 3 + 1]; v.nz = d.normals[i * 3 + 2];
        v.u = d.uvs[i * 2]; v.v = d.uvs[i * 2 + 1];
        v.tx = d.tangents[i * 4]; v.ty = d.tangents[i * 4 + 1]; v.tz = d.tangents[i * 4 + 2]; v.tw = d.tangents[i * 4 + 3];
    }
    const std::size_t vbBytes = n * sizeof(MeshVertex), ibBytes = d.indices.size() * sizeof(std::uint32_t);

    // Outside a pass the buffers are written through staging buffers and kept while the data fits (a mesh deformed every frame
    // costs two copies, no allocation). Inside a pass (a copy cannot run there) or when the staging buffers were already written
    // this frame (a transient write after a copy is not allowed), new buffers are made.
    const bool canCopy = sg_query_pass_state() == SG_PASSSTATE_NONE;
    const std::uint64_t frameTag = gpu_.frame() + 1;
    if (canCopy) {
        const bool fits = pm.vbStage.id && vbBytes <= pm.vbCap && ibBytes <= pm.ibCap && pm.stagedFrame != frameTag;
        if (!fits) {
            const bool grow = pm.vb.id && (vbBytes > pm.vbCap || ibBytes > pm.ibCap);
            std::size_t vbCap = std::max(vbBytes, pm.vbCap), ibCap = std::max(ibBytes, pm.ibCap);
            if (grow) {  // headroom for a mesh that keeps growing
                vbCap = std::max(vbCap, vbBytes + vbBytes / 2);
                ibCap = std::max(ibCap, ibBytes + ibBytes / 2);
            }
            vbCap = (vbCap + 3) & ~std::size_t(3);
            ibCap = (ibCap + 3) & ~std::size_t(3);
            destroy_procedural(pm);
            pm.vbCap = vbCap;
            pm.ibCap = ibCap;
            sg_buffer_desc bd{};
            bd.size = vbCap;
            bd.usage.vertex_buffer = true;
            bd.usage.copy_dst = true;
            bd.label = "procedural-vb";
            pm.vb = sg_make_buffer(&bd);
            bd = {};
            bd.size = ibCap;
            bd.usage.vertex_buffer = false;
            bd.usage.index_buffer = true;
            bd.usage.copy_dst = true;
            bd.label = "procedural-ib";
            pm.ib = sg_make_buffer(&bd);
            bd = {};
            bd.size = vbCap;
            bd.usage.vertex_buffer = false;
            bd.usage.staging_buffer = true;
            bd.usage.write_transient = true;
            bd.usage.copy_src = true;
            bd.label = "procedural-vb-staging";
            pm.vbStage = sg_make_buffer(&bd);
            bd.size = ibCap;
            bd.usage.staging_buffer = !sg_query_features().separate_buffer_types;
            bd.usage.staging_index_buffer = sg_query_features().separate_buffer_types;
            bd.label = "procedural-ib-staging";
            pm.ibStage = sg_make_buffer(&bd);
        }
        sg_write_buffer_desc w{};
        w.src.data = {verts.data(), vbBytes};
        w.dst.buffer = pm.vbStage;
        sg_write_buffer_transient(&w);
        sg_copy_buffer_to_buffer_desc c{};
        c.src.buffer = pm.vbStage;
        c.dst.buffer = pm.vb;
        c.size = vbBytes;
        sg_copy_buffer_to_buffer(&c);
        w = {};
        w.src.data = {d.indices.data(), ibBytes};
        w.dst.buffer = pm.ibStage;
        sg_write_buffer_transient(&w);
        c = {};
        c.src.buffer = pm.ibStage;
        c.dst.buffer = pm.ib;
        c.size = ibBytes;
        sg_copy_buffer_to_buffer(&c);
        pm.stagedFrame = frameTag;
    } else {
        destroy_procedural(pm);
        sg_buffer_desc bd{};
        bd.data = {verts.data(), vbBytes};
        bd.label = "procedural-vb";
        pm.vb = sg_make_buffer(&bd);
        bd = {};
        bd.usage.vertex_buffer = false;
        bd.usage.index_buffer = true;
        bd.data = {d.indices.data(), ibBytes};
        bd.label = "procedural-ib";
        pm.ib = sg_make_buffer(&bd);
        pm.vbCap = vbBytes;
        pm.ibCap = ibBytes;
    }

    MeshAsset& a = *pm.asset;
    a.parts.clear();
    a.placeholder = false;
    a.bmin = d.bmin;
    a.bmax = d.bmax;
    pm.partTextures.clear();
    for (const MeshSubmesh& s : d.submeshes) {
        SubMesh sm;
        sm.vb = pm.vb;
        sm.ib = pm.ib;
        sm.ibOffset = int(s.start * sizeof(std::uint32_t));
        sm.vertexCount = int(n);
        sm.indexCount = int(s.count);
        sm.bmin = d.bmin;
        sm.bmax = d.bmax;
        const MeshMaterial& m = s.material;
        sm.materialName = m.name;
        sm.baseColor = m.color;
        sm.hasPbr = m.metallic.has_value() || m.roughness.has_value();
        sm.metallic = m.metallic.value_or(0.0f);
        sm.roughness = m.roughness.value_or(0.6f);
        sm.emissiveFactor = Color{m.emissive.r, m.emissive.g, m.emissive.b, 1.0f};
        sm.doubleSided = m.doubleSided;
        sm.blended = m.blend;
        a.parts.push_back(sm);
        pm.partTextures.push_back(m.texture);
    }
}

void Assets::reload(const std::string& pathIn) {
    std::string path = fs::normalize(pathIn);
    if (path.empty()) path = pathIn;
    auto t = textures_.find(path);
    if (t == textures_.end() && fs::extension(path) == kTextureTwinExtension)  // the twin of a texture changed
        t = textures_.find(path.substr(0, path.size() - std::strlen(kTextureTwinExtension)));
    if (t != textures_.end()) {
        // Placeholder-shared handles must not be destroyed: load_texture() handles that via destroy_texture,
        // so detach them first.
        if (t->second->placeholder) {
            t->second->image = {};
            t->second->view = {};
        }
        load_texture(t->first);
    }
    auto m = meshes_.find(path);
    if (m != meshes_.end()) {
        if (m->second->placeholder) m->second->parts.clear();  // shared handles
        failures_.erase(std::remove_if(failures_.begin(), failures_.end(),
                                       [&](const Failure& f) { return f.kind == "mesh" && f.path == path; }),
                        failures_.end());
        load_mesh(path);
    }
    // Meshes referencing a reloaded texture keep pointing at the same TextureAsset (updated in place).
    // A material rebuilds in place when its file, its snippet or its compiled twin changed.
    const std::string dialect = backend_dialect(sg_query_backend());
    for (auto& [key, mat] : materials_)
        if (path == key || path == mat->snippet || path == key + "." + dialect + ".shader") build_material(*mat);
}

std::size_t Assets::texture_bytes() const {
    std::size_t total = 0;
    for (const auto& [k, t] : textures_)
        if (!t->placeholder && !t->atlas) total += t->bytes;
    for (const auto& [k, v] : videoTextures_) total += v.tex->bytes;
    for (const auto& [k, t] : runtime_) total += t->bytes;
    return total;
}

Json Assets::report() const {
    Json j = Json::object();
    Json tex = Json::array();
    for (const auto& [k, t] : textures_) {
        if (t->placeholder) continue;
        Json entry = {{"path", k}, {"width", t->width}, {"height", t->height}, {"format", pixel_format_name(t->format)}, {"bytes", t->bytes}};
        if (t->atlas) entry["atlas"] = t->atlas->path;  // packed: the bytes are the atlas's
        tex.push_back(std::move(entry));
    }
    for (const auto& [k, t] : runtime_)
        tex.push_back({{"path", k}, {"width", t->width}, {"height", t->height}, {"format", pixel_format_name(t->format)},
                       {"bytes", t->bytes}, {"runtime", true}});
    Json meshes = Json::array();
    for (const auto& [k, m] : meshes_) {
        if (m->placeholder) continue;
        int tris = 0;
        for (const auto& p : m->parts) tris += p.indexCount / 3;
        meshes.push_back({{"mesh", k}, {"triangles", tris}, {"parts", m->parts.size()}});
    }
    for (const auto& [k, pm] : procedural_) {
        int tris = 0;
        for (const auto& p : pm.asset->parts) tris += p.indexCount / 3;
        meshes.push_back({{"mesh", k}, {"triangles", tris}, {"parts", pm.asset->parts.size()}, {"procedural", true},
                          {"version", pm.version}, {"bytes", pm.vbCap + pm.ibCap}});
    }
    Json fails = Json::array();
    for (const auto& f : failures_) fails.push_back({{"kind", f.kind}, {"path", f.path}, {"message", f.message}, {"hint", f.hint}});
    Json mats = Json::array();
    for (const auto& [k, m] : materials_) {
        Json entry = {{"material", k}, {"ok", m->ok}, {"generation", m->generation}};
        if (!m->error.empty()) entry["error"] = m->error;
        mats.push_back(std::move(entry));
    }
    j["textures"] = tex;
    j["materials"] = mats;
    j["meshes"] = meshes;
    j["failures"] = fails;
    return j;
}

}  // namespace fa::render
