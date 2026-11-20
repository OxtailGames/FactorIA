// Texture + mesh caches, procedural primitives and glTF loading.
#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <format>

#include <cgltf.h>

#include "fa/core/asset_manifest.h"
#include "fa/core/load_trace.h"
#include "fa/core/fs.h"
#include "fa/core/image_float.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/render/cube_lut.h"
#include "fa/scene/gltf_file.h"
#include "fa/scene/material_layers.h"
#include "fa/scene/skeleton.h"
#include "render_internal.h"

namespace fa::render {

// ---------------------------------------------------------------------------
// Procedural primitives
// ---------------------------------------------------------------------------
namespace {

void add_face(std::vector<MeshVertex>& v, std::vector<std::uint32_t>& idx, Vec3 n, Vec3 r, Vec3 u, Vec3 center,
              float half) {
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
            v.push_back(
                {rings[r].x * ca, rings[r].y, rings[r].x * sa, n.x, n.y, n.z, float(s) / float(segments), rings[r].z});
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

void add_disc(std::vector<MeshVertex>& v, std::vector<std::uint32_t>& idx, int segments, float radius, float y,
              float ny) {
    auto base = std::uint32_t(v.size());
    v.push_back({0, y, 0, 0, ny, 0, 0.5f, 0.5f});
    for (int s = 0; s <= segments; ++s) {
        float a = float(s) / float(segments) * kTau;
        float ca = std::cos(a), sa = std::sin(a);
        v.push_back({radius * ca, y, radius * sa, 0, ny, 0, 0.5f + 0.5f * ca, 0.5f + 0.5f * sa});
    }
    for (int s = 0; s < segments; ++s)
        idx.insert(idx.end(), {base, base + 1 + std::uint32_t(s), base + 2 + std::uint32_t(s)});
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
        for (std::uint32_t k : {idx[i], idx[i + 1], idx[i + 2]}) {
            tan[k] = tan[k] + t;
            bit[k] = bit[k] + bt;
        }
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
        x.tx = t.x;
        x.ty = t.y;
        x.tz = t.z;
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
// glTF loader: decode_gltf (CPU, any thread) + MeshLoader::upload (GPU, main thread). A load on first use runs both at
// once; background loading runs the first on a job and the second when the main thread adopts the result.
// ---------------------------------------------------------------------------
namespace {

void generate_normals(std::vector<MeshVertex>& v, const std::vector<std::uint32_t>& idx) {
    for (auto& x : v) x.nx = x.ny = x.nz = 0;
    for (std::size_t i = 0; i + 2 < idx.size(); i += 3) {
        MeshVertex &a = v[idx[i]], &b = v[idx[i + 1]], &c = v[idx[i + 2]];
        Vec3 n = cross(Vec3{b.px - a.px, b.py - a.py, b.pz - a.pz}, Vec3{c.px - a.px, c.py - a.py, c.pz - a.pz});
        for (MeshVertex* m : {&a, &b, &c}) {
            m->nx += n.x;
            m->ny += n.y;
            m->nz += n.z;
        }
    }
    for (auto& x : v) {
        Vec3 n = normalize(Vec3{x.nx, x.ny, x.nz});
        if (length_sq(n) < 0.5f) n = {0, 1, 0};
        x.nx = n.x;
        x.ny = n.y;
        x.nz = n.z;
    }
}

// `uv1` and `color1` get TEXCOORD_1 (two floats per vertex) and COLOR_1 (packed like MeshVertex::color) when the
// primitive has them, the channels a material's "vertexAttributes" read; they stay empty otherwise.
bool read_primitive(const cgltf_primitive& prim, const Mat4& world, const Mat4& normalMat,
                    std::vector<MeshVertex>& verts, std::vector<std::uint32_t>& idx, std::vector<float>& uv1,
                    std::vector<std::uint32_t>& color1) {
    const cgltf_accessor *pos = nullptr, *nrm = nullptr, *uv = nullptr, *tng = nullptr, *col = nullptr;
    const cgltf_accessor *uvB = nullptr, *colB = nullptr;
    for (cgltf_size a = 0; a < prim.attributes_count; ++a) {
        const cgltf_attribute& at = prim.attributes[a];
        if (at.type == cgltf_attribute_type_position && at.index == 0)
            pos = at.data;
        else if (at.type == cgltf_attribute_type_normal && at.index == 0)
            nrm = at.data;
        else if (at.type == cgltf_attribute_type_texcoord && at.index == 0)
            uv = at.data;
        else if (at.type == cgltf_attribute_type_tangent && at.index == 0 && at.data->type == cgltf_type_vec4)
            tng = at.data;
        else if (at.type == cgltf_attribute_type_color && at.index == 0 &&
                 (at.data->type == cgltf_type_vec3 || at.data->type == cgltf_type_vec4))
            col = at.data;  // COLOR_0: multiplies the base color (rgb or rgba, floats or normalized integers)
        else if (at.type == cgltf_attribute_type_texcoord && at.index == 1)
            uvB = at.data;
        else if (at.type == cgltf_attribute_type_color && at.index == 1 &&
                 (at.data->type == cgltf_type_vec3 || at.data->type == cgltf_type_vec4))
            colB = at.data;
    }
    if (!pos) return false;
    if (uvB) {
        uv1.assign(pos->count * 2, 0.0f);
        for (cgltf_size i = 0; i < pos->count && i < uvB->count; ++i) cgltf_accessor_read_float(uvB, i, &uv1[i * 2], 2);
    }
    if (colB) {
        color1.assign(pos->count, 0xFFFFFFFFu);
        for (cgltf_size i = 0; i < pos->count && i < colB->count; ++i) {
            float c[4] = {1, 1, 1, 1};
            cgltf_accessor_read_float(colB, i, c, colB->type == cgltf_type_vec3 ? 3 : 4);
            color1[i] = pack_vertex_color(c[0], c[1], c[2], c[3]);
        }
    }
    verts.resize(pos->count);
    for (cgltf_size i = 0; i < pos->count; ++i) {
        float p[3] = {0, 0, 0};
        cgltf_accessor_read_float(pos, i, p, 3);
        Vec3 wp = world.transform_point({p[0], p[1], p[2]});
        MeshVertex& v = verts[i];
        v.px = wp.x;
        v.py = wp.y;
        v.pz = wp.z;
        float n[3] = {0, 1, 0};
        if (nrm) cgltf_accessor_read_float(nrm, i, n, 3);
        Vec3 wn = normalize(normalMat.transform_dir({n[0], n[1], n[2]}));
        v.nx = wn.x;
        v.ny = wn.y;
        v.nz = wn.z;
        float t[2] = {0, 0};
        if (uv) cgltf_accessor_read_float(uv, i, t, 2);
        v.u = t[0];
        v.v = t[1];
        float tn[4] = {1, 0, 0, 1};
        if (tng) cgltf_accessor_read_float(tng, i, tn, 4);
        Vec3 wt = normalize(world.transform_dir({tn[0], tn[1], tn[2]}));
        v.tx = wt.x;
        v.ty = wt.y;
        v.tz = wt.z;
        v.tw = tn[3] < 0.0f ? -1.0f : 1.0f;
        if (col) {
            float c[4] = {1, 1, 1, 1};
            cgltf_accessor_read_float(col, i, c, col->type == cgltf_type_vec3 ? 3 : 4);
            v.color = pack_vertex_color(c[0], c[1], c[2], c[3]);
        }
    }
    if (prim.indices) {
        idx.resize(prim.indices->count);
        for (cgltf_size i = 0; i < prim.indices->count; ++i)
            idx[i] = std::uint32_t(cgltf_accessor_read_index(prim.indices, i));
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

PreparedTextureRef image_ref(const cgltf_image& img, const std::string& dir) {
    PreparedTextureRef r;
    if (img.buffer_view) {
        const auto* base = static_cast<const std::uint8_t*>(img.buffer_view->buffer->data);
        auto decoded = decode_image(base + img.buffer_view->offset, img.buffer_view->size);
        std::string name = std::format("<gltf-embedded:{}>", img.name ? img.name : "image");
        if (!decoded) {
            r.kind = PreparedTextureRef::Kind::Missing;
            r.name = std::move(name);
            r.error = decoded.error().message;
            r.hint = decoded.error().hint;
            return r;
        }
        r.kind = PreparedTextureRef::Kind::Image;
        r.name = std::move(name);
        r.image = std::move(*decoded);
        return r;
    }
    if (img.uri) {
        std::string uri = img.uri;
        if (uri.rfind("data:", 0) == 0) {
            auto comma = uri.find(',');
            if (comma != std::string::npos) {
                auto raw = base64_decode(std::string_view(uri).substr(comma + 1));
                auto decoded = decode_image(raw.data(), raw.size());
                if (decoded) {
                    r.kind = PreparedTextureRef::Kind::Image;
                    r.name = "<gltf-data-uri>";
                    r.image = std::move(*decoded);
                    return r;
                }
            }
            r.kind = PreparedTextureRef::Kind::Missing;
            return r;
        }
        std::vector<char> buf(uri.begin(), uri.end());
        buf.push_back('\0');
        cgltf_decode_uri(buf.data());
        uri = buf.data();
        r.kind = PreparedTextureRef::Kind::Path;
        r.path = dir.empty() ? uri : fs::join(dir, uri);
    }
    return r;
}

// The layers of a glTF material, worked out once per material (the parts that share it share the packed maps).
struct LayerCache {
    struct Entry {
        MaterialLayers layers;
        int packed = 0;
        PreparedTextureRef occlusion, metalRough;  // the composites, when packed != 0
    };
    std::map<const cgltf_material*, Entry> byMaterial;
};

// The five layer extensions of `mat`: their factors, and their textures packed into the occlusion and metallic-roughness maps
// of `part` (pack_layer_textures). Reads the extension once per material; later parts copy the result.
void prepare_layers(const cgltf_material* mat, const cgltf_data* data, const std::string& path, const std::string& dir,
                    PreparedPart& part, LayerCache& cache, std::vector<std::string>& warnings) {
    auto it = cache.byMaterial.find(mat);
    if (it == cache.byMaterial.end()) {
        LayerCache::Entry e;
        const std::string what = std::format(
            "{}: material '{}'", path, mat->name && *mat->name ? mat->name : std::format("#{}", mat - data->materials));
        read_material_layers(*mat, what, e.layers, warnings);
        LayerTextureRefs refs;
        auto ref = [&](const cgltf_texture_view& v, PreparedTextureRef& out) {
            if (v.texture && v.texture->image) out = image_ref(*v.texture->image, dir);
        };
        if (mat->has_clearcoat) {
            ref(mat->clearcoat.clearcoat_texture, refs.clearcoat);
            ref(mat->clearcoat.clearcoat_roughness_texture, refs.clearcoatRoughness);
            ref(mat->clearcoat.clearcoat_normal_texture, refs.clearcoatNormal);
        }
        if (mat->has_sheen) {
            ref(mat->sheen.sheen_color_texture, refs.sheenColor);
            ref(mat->sheen.sheen_roughness_texture, refs.sheenRoughness);
        }
        if (mat->has_anisotropy) ref(mat->anisotropy.anisotropy_texture, refs.anisotropy);
        if (mat->has_specular) {
            ref(mat->specular.specular_texture, refs.specular);
            ref(mat->specular.specular_color_texture, refs.specularColor);
        }
        if (refs.any()) {
            e.occlusion = part.occlusion;
            e.metalRough = part.metalRough;
            e.packed = pack_layer_textures(refs, what, std::format("<gltf-layers:{}:{}>", path, mat - data->materials),
                                           e.occlusion, e.metalRough, warnings);
        }
        it = cache.byMaterial.emplace(mat, std::move(e)).first;
    }
    const LayerCache::Entry& e = it->second;
    part.material.layers = e.layers;
    part.material.layersPacked = e.packed;
    if (e.packed & 1) part.occlusion = e.occlusion;
    if (e.packed & 2) part.metalRough = e.metalRough;
}

void prepare_material(const cgltf_material* mat, const cgltf_data* data, const std::string& path,
                      const std::string& dir, PreparedPart& part, LayerCache& cache,
                      std::vector<std::string>& warnings) {
    if (!mat) return;
    SubMesh& sm = part.material;
    if (mat->name) sm.materialName = mat->name;
    sm.doubleSided = mat->double_sided;
    sm.blended = mat->alpha_mode == cgltf_alpha_mode_blend;
    if (mat->has_pbr_metallic_roughness) {
        const auto& pbr = mat->pbr_metallic_roughness;
        sm.baseColor = Color{pbr.base_color_factor[0], pbr.base_color_factor[1], pbr.base_color_factor[2],
                             pbr.base_color_factor[3]};
        const cgltf_texture* tex = pbr.base_color_texture.texture;
        if (tex && tex->image) part.base = image_ref(*tex->image, dir);
        sm.hasPbr = true;
        sm.metallic = pbr.metallic_factor;
        sm.roughness = pbr.roughness_factor;
        const cgltf_texture* mr = pbr.metallic_roughness_texture.texture;
        if (mr && mr->image) part.metalRough = image_ref(*mr->image, dir);
    }
    const cgltf_texture* nt = mat->normal_texture.texture;
    if (nt && nt->image) {
        part.normal = image_ref(*nt->image, dir);
        sm.normalScale = mat->normal_texture.scale;
    }
    const cgltf_texture* ot = mat->occlusion_texture.texture;
    if (ot && ot->image) {
        part.occlusion = image_ref(*ot->image, dir);
        sm.occlusionStrength = mat->occlusion_texture.scale;
    }
    const cgltf_texture* et = mat->emissive_texture.texture;
    if (et && et->image) part.emissive = image_ref(*et->image, dir);
    float strength = mat->has_emissive_strength ? mat->emissive_strength.emissive_strength : 1.0f;
    sm.emissiveFactor = Color{mat->emissive_factor[0] * strength, mat->emissive_factor[1] * strength,
                              mat->emissive_factor[2] * strength, 1.0f};
    if (mat->has_clearcoat || mat->has_sheen || mat->has_anisotropy || mat->has_specular || mat->has_ior)
        prepare_layers(mat, data, path, dir, part, cache, warnings);
}

// Gives a part of a skinned glTF node its joints and weights (vertex buffer 2). Each part is drawn with the palette of its
// own skin; a skin with more than kMaxSkinJoints joints is not drawn skinned, so the part stays in bind pose.
void prepare_skin(const std::string& path, std::shared_ptr<const SkeletonAsset>& skeleton, int node, int primitive,
                  PreparedPart& part, std::vector<std::string>& warnings) {
    if (!skeleton) {
        auto r = load_skeleton(path);
        if (!r) return;
        skeleton = *r;
    }
    const std::size_t vertexCount = part.verts.size();
    for (const SkinVertices& sv : skeleton->skinVertices) {
        if (sv.node != node || sv.primitive != primitive || sv.joints.size() != vertexCount) continue;
        const std::size_t joints = skeleton->skins[std::size_t(sv.skin)].joints.size();
        if (joints > std::size_t(kMaxSkinJoints)) {
            warnings.push_back(
                std::format("{}: the skin has {} joints - drawn in bind pose, not animated. Skinning supports skins "
                            "with at most {} joints; re-export the model with fewer joints.",
                            path, joints, kMaxSkinJoints));
            return;
        }
        part.skin.resize(vertexCount);
        for (std::size_t i = 0; i < vertexCount; ++i)
            for (std::size_t k = 0; k < 4; ++k) {
                part.skin[i].joints[k] = std::uint8_t(sv.joints[i][k]);
                part.skin[i].weights[k] = sv.weights[i][k];
            }
        part.skinIndex = sv.skin;
        return;
    }
}

}  // namespace

bool decode_gltf(const std::string& path, const std::uint8_t* bytes, std::size_t size, PreparedMesh& out,
                 std::string& error) {
    cgltf_options opts{};
    gltf_use_fs(opts);
    cgltf_data* data = nullptr;
    cgltf_result r = cgltf_parse(&opts, bytes, size, &data);
    if (r != cgltf_result_success) {
        error = std::format(
            "cgltf could not parse '{}' (error code {}). The file must be a valid glTF 2.0 (.gltf or .glb) file.", path,
            int(r));
        return false;
    }
    struct Guard {
        cgltf_data* d;
        ~Guard() { cgltf_free(d); }
    } guard{data};
    if (auto sizes = gltf_check_buffer_sizes(data, path); !sizes) {
        error = sizes.error().message + ". " + sizes.error().hint;
        return false;
    }
    r = cgltf_load_buffers(&opts, data, path.c_str());
    if (r != cgltf_result_success) {
        error = std::format("cannot load the buffers referenced by '{}' (cgltf error {}). External .bin files must sit "
                            "next to the .gltf and be inside the project.",
                            path, int(r));
        return false;
    }
    if (auto sound = gltf_check(data, path); !sound) {
        error = sound.error().message + " " + sound.error().hint;
        return false;
    }
    const std::string dir = fs::parent(path);
    std::shared_ptr<const SkeletonAsset> skeleton;
    LayerCache layerCache;
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
                out.warnings.push_back(std::format("{}: mesh '{}' primitive {} uses a non-triangle mode; skipped", path,
                                                   node.mesh->name ? node.mesh->name : "?", pi));
                continue;
            }
            PreparedPart part;
            if (!read_primitive(prim, world, normalMat, part.verts, part.idx, part.uv1, part.color1)) continue;
            compute_bounds(part.verts, part.material.bmin, part.material.bmax);
            prepare_material(prim.material, data, path, dir, part, layerCache, out.warnings);
            prepare_skin(path, skeleton, int(ni), int(pi), part, out.warnings);
            out.bmin = min(out.bmin, part.material.bmin);
            out.bmax = max(out.bmax, part.material.bmax);
            out.parts.push_back(std::move(part));
        }
    }
    if (out.parts.empty()) {
        error = std::format("'{}' contains no triangle meshes", path);
        return false;
    }
    return true;
}

class MeshLoader {
public:
    MeshLoader(Assets& assets) : assets_(assets) {}

    bool load(const std::string& path, MeshAsset& out, std::string& error) {
        AssetLoadScope trace("mesh",
                             path);  // the load trace's read and decode time (fa/core/load_trace.h); free without one
        auto bytes = fs::read_bytes(path);
        if (!bytes) {
            error = bytes.error().message;
            return false;
        }
        PreparedMesh prepared;
        if (!decode_gltf(path, bytes->data(), bytes->size(), prepared, error)) return false;
        upload(path, prepared, out);
        return true;
    }

    // Main thread: the GPU buffers and textures of a decoded model. Returns the GPU bytes it uploaded (its buffers and its
    // embedded images; image files are textures of their own).
    std::uint64_t upload(const std::string& path, PreparedMesh& p, MeshAsset& out) {
        for (const std::string& w : p.warnings) FA_WARN("render", "{}", w);
        std::uint64_t bytes = 0;
        for (PreparedPart& part : p.parts) {
            SubMesh sm = upload_submesh(part.verts, part.idx, path.c_str());
            bytes += part.verts.size() * sizeof(MeshVertex) + part.idx.size() * sizeof(std::uint32_t);
            const SubMesh& m = part.material;
            sm.materialName = m.materialName;
            sm.baseColor = m.baseColor;
            sm.normalScale = m.normalScale;
            sm.occlusionStrength = m.occlusionStrength;
            sm.hasPbr = m.hasPbr;
            sm.layers = m.layers;
            sm.layersPacked = m.layersPacked;
            sm.metallic = m.metallic;
            sm.roughness = m.roughness;
            sm.emissiveFactor = m.emissiveFactor;
            sm.doubleSided = m.doubleSided;
            sm.blended = m.blended;
            // The order a load on first use looks them up in: base color, metallic-roughness, normal, occlusion, emissive.
            sm.texture = texture(part.base);
            sm.mrTex = texture(part.metalRough);
            sm.normalTex = texture(part.normal);
            sm.occlusionTex = texture(part.occlusion);
            sm.emissiveTex = texture(part.emissive);
            if (!part.skin.empty()) {
                sg_buffer_desc bd{};
                bd.data = {part.skin.data(), part.skin.size() * sizeof(SkinVertex)};
                bd.label = "skin";
                sm.skinVb = sg_make_buffer(&bd);
                sm.skin = part.skinIndex;
                bytes += part.skin.size() * sizeof(SkinVertex);
            }
            if (!part.uv1.empty()) {
                sg_buffer_desc bd{};
                bd.data = {part.uv1.data(), part.uv1.size() * sizeof(float)};
                bd.label = "uv1";
                sm.uv1Vb = sg_make_buffer(&bd);
                bytes += part.uv1.size() * sizeof(float);
            }
            if (!part.color1.empty()) {
                sg_buffer_desc bd{};
                bd.data = {part.color1.data(), part.color1.size() * sizeof(std::uint32_t)};
                bd.label = "color1";
                sm.color1Vb = sg_make_buffer(&bd);
                bytes += part.color1.size() * sizeof(std::uint32_t);
            }
            out.parts.push_back(sm);
        }
        out.bmin = p.bmin;
        out.bmax = p.bmax;
        return bytes + embeddedBytes_;
    }

private:
    TextureAsset* texture(PreparedTextureRef& r) {
        switch (r.kind) {
            case PreparedTextureRef::Kind::None: return nullptr;
            case PreparedTextureRef::Kind::Path: return assets_.texture(r.path);
            case PreparedTextureRef::Kind::Image: {
                // The maps packed from a material's layer textures are shared by the parts that use the material.
                const bool packed = r.name.rfind("<gltf-layers:", 0) == 0;
                if (packed)
                    if (auto it = packedTextures_.find(r.name); it != packedTextures_.end()) return it->second;
                TextureAsset* t = assets_.make_texture(r.name, r.image, true);
                embeddedBytes_ += t->bytes;
                if (packed) packedTextures_[r.name] = t;
                return t;
            }
            case PreparedTextureRef::Kind::Missing:
                if (!r.name.empty()) assets_.note_failure("texture", r.name, r.error, r.hint);
                return assets_.texture("<missing-embedded-image>");
        }
        return nullptr;
    }

    Assets& assets_;
    std::uint64_t embeddedBytes_ = 0;
    std::unordered_map<std::string, TextureAsset*> packedTextures_;  // by name: <gltf-layers:...>
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
            p[0] = on ? 255 : 0;
            p[1] = 0;
            p[2] = on ? 255 : 0;
            p[3] = 255;
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
    // A texture that failed to load shares the checker's handles (use_placeholder): only the checker itself owns them.
    const bool borrowed = t.placeholder && &t != placeholderTex_.get();
    if (!t.atlas && !borrowed) {  // a packed texture borrows the GPU image of its atlas
        if (t.view.id) sg_destroy_view(t.view);
        if (t.image.id) sg_destroy_image(t.image);
    }
    t.view = {};
    t.image = {};
    t.atlas = nullptr;
}

void Assets::destroy_mesh_lightmap(MeshAsset& m) {
    if (!m.lightmap) return;
    for (sg_buffer* b : {&m.lightmap->vb, &m.lightmap->ib, &m.lightmap->uv, &m.lightmap->color1})
        if (b->id) sg_destroy_buffer(*b);
    m.lightmap.reset();
}

void Assets::destroy_mesh(MeshAsset& m) {
    destroy_mesh_lightmap(m);
    for (auto& p : m.parts) {
        sg_destroy_buffer(p.vb);
        sg_destroy_buffer(p.ib);
        if (p.skinVb.id) sg_destroy_buffer(p.skinVb);
        if (p.uv1Vb.id) sg_destroy_buffer(p.uv1Vb);
        if (p.color1Vb.id) sg_destroy_buffer(p.color1Vb);
    }
    m.parts.clear();
}

void Assets::clear() {
    for (auto& [k, v] : videoTextures_) destroy_texture(*v.tex);
    videoTextures_.clear();
    for (auto& [k, t] : textures_) destroy_texture(*t);
    textures_.clear();
    for (auto& [k, l] : luts_) destroy_lut(*l);
    luts_.clear();
    for (auto& t : anonymous_) destroy_texture(*t);
    anonymous_.clear();
    for (auto& [k, m] : meshes_) destroy_mesh(*m);
    meshes_.clear();
    destroy_lightmap_set();
    lightmapSetPath_.clear();
    if (zeroUv1_.id) sg_destroy_buffer(zeroUv1_);
    zeroUv1_ = {};
    zeroUv1Vertices_ = 0;
    for (auto& [k, pm] : procedural_) destroy_procedural(pm);
    procedural_.clear();
    meshStore_ = nullptr;
    meshStoreSerial_ = 0;
    for (auto& [k, m] : materials_)
        for (MaterialProgram& p : m->programs)
            if (p.shader.id) gpu_.destroy_shader(p.shader);
    materials_.clear();
    drop_material_cache();
    variantsChangedNoted_ = false;  // a later change of materialParams during a frame warns again
    failures_.clear();
    meshSources_.clear();
}

TextureAsset* Assets::white() { return white_.get(); }

void Assets::destroy_lut(LutAsset& l) {
    if (l.view.id) sg_destroy_view(l.view);
    if (l.image.id) sg_destroy_image(l.image);
    l.view = {};
    l.image = {};
}

const LutAsset* Assets::lut(const std::string& pathIn) {
    if (pathIn.empty()) return nullptr;
    std::string key = fs::normalize(pathIn);
    if (key.empty()) key = pathIn;
    bool secondTry = false;  // the slot's first read or parse failed: this is the one retry, its failure is final
    LutAsset* slotPtr = nullptr;
    if (auto it = luts_.find(key); it != luts_.end()) {
        if (it->second->view.id) return it->second.get();
        if (!it->second->retryPending)
            return nullptr;  // a failed load stays in the cache: one error, no read every frame
        it->second->retryPending = false;
        secondTry = true;
        slotPtr = it->second.get();
    } else {
        auto slot = std::make_unique<LutAsset>();
        slotPtr = slot.get();
        slot->path = key;
        luts_[key] = std::move(slot);
    }
    LutAsset& l = *slotPtr;
    auto fail = [&](const std::string& message, const std::string& hint) -> const LutAsset* {
        note_failure("lut", key, message, hint);
        return nullptr;
    };
    if (!fs::exists(key))
        return fail("colour grading LUT " + missing_hint(key, fs::extension(key)),
                    "Set PostProcess.colorGradingLut to a .cube file in the project (import one with assets.import).");
    const std::int64_t bytes = fs::file_size(key);
    if (bytes > std::int64_t(kCubeLutMaxFileBytes))
        return fail(std::format("colour grading LUT '{}' is {} MB, over the {} MB a .cube file may have", key,
                                bytes >> 20, kCubeLutMaxFileBytes >> 20),
                    "Export a 32 or 33 entry LUT (a 64 entry one is about 8 MB).");
    // A file that is read or parses badly is tried once more on the next ask (the next frame) before it is an error: on Windows the
    // editor that saves a .cube may still be writing it (a half-written file) when the hot reload finds it.
    // The slot stays in the cache with retryPending set (so a file nobody asks for again costs nothing, and a later ask still gets its
    // retry); the first failure is logged as a warning, so a one-frame render (a capture, the CLI) does not fail in silence.
    auto retry_once = [&](const std::string& what) {
        if (secondTry) return false;  // the second failure is the real one
        l.retryPending = true;
        FA_WARN("render",
                "colour grading LUT '{}' {}; trying once more on the next frame (a file that is still being written).",
                key, what);
        return true;
    };
    auto text = fs::read_text(key);
    if (!text) {
        if (retry_once("could not be read: " + text.error().message)) return nullptr;
        return fail(std::format("colour grading LUT '{}' could not be read: {}", key, text.error().message),
                    text.error().hint);
    }
    auto parsed = parse_cube_lut(*text, key);
    if (!parsed) {
        const std::string message = parsed.error().message, hint = parsed.error().hint;
        if (retry_once("does not parse: " + message)) return nullptr;
        return fail("colour grading LUT " + message, hint);
    }
    const CubeLutStrip strip = cube_lut_strip(*parsed);
    sg_image_desc d{};
    d.width = strip.width();
    d.height = strip.height();
    d.pixel_format = SG_PIXELFORMAT_RGBA8;  // the table's own numbers: never decoded as sRGB
    d.data.mip_levels[0] = {strip.rgba.data(), strip.rgba.size()};
    d.label = key.c_str();
    l.image = make_image(d);
    if (sg_query_image_state(l.image) != SG_RESOURCESTATE_VALID) {
        destroy_lut(l);
        return fail(std::format("colour grading LUT '{}': the GPU could not make its {}x{} image", key, strip.width(),
                                strip.height()),
                    "Use a smaller LUT (32 entries per side).");
    }
    sg_view_desc vd{};
    vd.texture.image = l.image;
    vd.label = key.c_str();
    l.view = sg_make_view(&vd);
    l.size = strip.size;
    l.cols = strip.cols;
    l.rows = strip.rows;
    l.bytes = strip.rgba.size();
    // A successful (re)load clears an older failure record.
    failures_.erase(std::remove_if(failures_.begin(), failures_.end(),
                                   [&](const Failure& f) { return f.kind == "lut" && f.path == key; }),
                    failures_.end());
    return &l;
}

void Assets::upload_texture(TextureAsset& t, const Image& img, bool mips) {
    // In a linear scene the image is made as sRGB (upload_rgba): the mips average in linear light, as the GPU filters it.
    const bool srgb = gpu_.texture_format(SG_PIXELFORMAT_RGBA8) != SG_PIXELFORMAT_RGBA8;
    upload_rgba(t, img, mips ? mip_chain(img, srgb) : std::vector<Image>());
}

// RGBA8 pixels with their mip chain (empty: no mips; chain[0] is not read, mip_chain puts the base there).
void Assets::upload_rgba(TextureAsset& t, const Image& img, const std::vector<Image>& chain) {
    sg_image_desc d{};
    d.width = img.width;
    d.height = img.height;
    // A linear scene reads colours as linear light: made as sRGB the GPU decodes them (the mip chain was averaged in linear light
    // for it, see upload_texture; one made for the other colour space stays as it was).
    const sg_pixel_format format = gpu_.texture_format(SG_PIXELFORMAT_RGBA8);
    d.pixel_format = format;
    d.num_mipmaps = chain.empty() ? 1 : int(chain.size());
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
    t.format = format;
    t.enc = format == SG_PIXELFORMAT_RGBA8 ? TexEncoding::Raw : TexEncoding::Srgb;
}

// Uploads transcoded KTX2 levels; false (nothing kept) when the GPU rejects them.
bool Assets::upload_transcoded(TextureAsset& t, const TranscodedTexture& tex) {
    sg_image_desc d{};
    d.width = tex.width;
    d.height = tex.height;
    const sg_pixel_format format =
        gpu_.texture_format(tex.format);  // the sRGB variant in a linear scene: the same blocks
    d.pixel_format = format;
    d.num_mipmaps = int(tex.levels.size());
    t.bytes = 0;
    for (std::size_t i = 0; i < tex.levels.size(); ++i) {
        d.data.mip_levels[i] = {tex.levels[i].data(), tex.levels[i].size()};
        t.bytes += tex.levels[i].size();
    }
    d.label = t.path.c_str();
    t.image = make_image(d);
    if (sg_query_image_state(t.image) == SG_RESOURCESTATE_VALID) {
        sg_view_desc vd{};
        vd.texture.image = t.image;
        vd.label = t.path.c_str();
        t.view = sg_make_view(&vd);
        t.width = tex.width;
        t.height = tex.height;
        t.format = format;
        t.enc = format == tex.format ? TexEncoding::Raw : TexEncoding::Srgb;
        return true;
    }
    sg_destroy_image(t.image);
    t.image = {};
    t.bytes = 0;
    return false;
}

// Uploads a KTX2 file in the best format the GPU samples. Falls back to RGBA8 when the driver rejects a compressed one.
bool Assets::upload_ktx2(TextureAsset& t, const std::vector<std::uint8_t>& file, std::string& error) {
    for (bool compressed : {true, false}) {
        auto tex = transcode_ktx2(file.data(), file.size(), compressed);
        if (!tex) {
            error = tex.error().message;
            return false;
        }
        if (upload_transcoded(t, *tex)) return true;
        if (tex->format == SG_PIXELFORMAT_RGBA8) break;
    }
    error = "the GPU rejected the texture";
    return false;
}

Result<PreparedTexture> decode_texture_file(const std::string& key, const std::string& file, const std::uint8_t* data,
                                            std::size_t size, sg_pixel_format ktx2Format, bool srgbMips) {
    AssetLoadScope trace("texture", key);  // the decode time (the read was the IO thread's); free without a load trace
    trace.set_bytes(size);
    PreparedTexture p;
    p.key = key;
    p.file = file;
    if (fs::extension(file) == kTextureTwinExtension) {
        auto tex = transcode_ktx2_as(data, size, ktx2Format);
        if (!tex) return tex.error();
        p.ktx2 = true;
        p.transcoded = std::move(*tex);
        return p;
    }
    auto img = decode_image(data, size);
    if (!img) return img.error();
    p.chain = mip_chain(*img, srgbMips);
    p.srgbMips = srgbMips;
    p.image = std::move(*img);
    return p;
}

std::uint64_t Assets::adopt_texture(PreparedTexture& p, std::vector<std::string> files) {
    if (p.key.empty() || textures_.count(p.key)) return 0;  // loaded on first use meanwhile: that one stays
    auto t = std::make_unique<TextureAsset>();
    t->path = p.key;
    if (!p.ktx2) {
        // The colour space was asked when the load was requested; a linear scene may have rendered since (the format of
        // the GPU image follows it): the chain is made again, on this thread, when the two differ.
        const bool srgb = gpu_.texture_format(SG_PIXELFORMAT_RGBA8) != SG_PIXELFORMAT_RGBA8;
        if (srgb != p.srgbMips) {
            p.chain = mip_chain(p.image, srgb);
            p.srgbMips = srgb;
        }
    }
    const bool ok = p.ktx2 ? upload_transcoded(*t, p.transcoded) : (upload_rgba(*t, p.image, p.chain), true);
    if (!ok) return 0;  // the GPU rejected the compressed format: the load on first use falls back to RGBA8
    t->untraced = std::move(files);
    const std::uint64_t bytes = t->bytes;
    textures_[p.key] = std::move(t);
    return bytes;
}

std::uint64_t Assets::adopt_mesh(const std::string& key, PreparedMesh& p, std::vector<std::string> files) {
    if (key.empty() || meshes_.count(key)) return 0;
    auto m = std::make_unique<MeshAsset>();
    m->key = key;
    meshSources_[key] = key;
    MeshLoader loader(*this);
    const std::uint64_t bytes = loader.upload(key, p, *m);
    m->untraced = std::move(files);
    meshes_[key] = std::move(m);
    return bytes;
}

// The first use of an asset loaded in the background: its files enter the load order now, where a load on first use would
// have read them (fa/core/load_trace.h). Not while reading ahead (a model's upload looks its textures up).
void Assets::report_first_use(TextureAsset& t) {
    if (LoadTrace::current_ahead_tag() != 0) return;
    for (const std::string& f : t.untraced) LoadTrace::file_used(f);
    t.untraced.clear();
}

void Assets::report_first_use(MeshAsset& m) {
    if (LoadTrace::current_ahead_tag() != 0) return;
    for (const std::string& f : m.untraced) LoadTrace::file_used(f);
    m.untraced.clear();
    for (SubMesh& part : m.parts)
        for (TextureAsset* t : {part.texture, part.mrTex, part.normalTex, part.occlusionTex, part.emissiveTex})
            if (t && !t->untraced.empty()) report_first_use(*t);
}

void Assets::use_placeholder(TextureAsset& t) {
    t.placeholder = true;
    t.image = placeholderTex_->image;  // shared handles; never destroyed through this asset
    t.view = placeholderTex_->view;
    t.width = placeholderTex_->width;
    t.height = placeholderTex_->height;
    t.format = placeholderTex_->format;
    t.enc = placeholderTex_->enc;
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
    if (!best.empty())
        msg += std::format(" Did you mean {}?", best);
    else if (candidates.empty())
        msg += std::format(
            " No {} files exist under assets/; put the file in <project>/assets/ and reference it as assets/<name>.",
            ext.empty() ? "asset" : std::string(ext));
    else
        msg += " Existing files: " + did_you_mean(path, candidates, 8);
    return msg;
}

void Assets::note_failure(const std::string& kind, const std::string& path, const std::string& message,
                          const std::string& hint) {
    if (failure_logged(kind, path)) return;
    failures_.push_back({kind, path, message, hint});
    const bool hinted =
        hint.empty() || message.find(hint) != std::string::npos;  // a shader diagnostic carries its hints
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
            return failed(std::format("texture '{}' is packed into the atlas '{}', which could not be loaded", path,
                                      packed.atlas),
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

    AssetLoadScope trace("texture",
                         path);  // the load trace's read and decode time (fa/core/load_trace.h); free without one
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
    if (!img)
        return failed(std::format("texture '{}' could not be loaded: {}", path, img.error().message), img.error().hint);
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
            note_failure(
                "texture", path,
                std::format(
                    "'{}' is not a texture file but a run-time texture id, and no such texture exists now (it was "
                    "destroyed with texture.destroy(), or it was made by an earlier run of the game).",
                    path),
                "Make the texture again with render.captureTexture() or render.textureFromPNG() and use its `id`.");
            use_placeholder(*slot);
        }
        return slot.get();
    }
    if (is_compute_id(
            path)) {  // a storage image of a compute material: live, never cached (compute.resize_image remakes it)
        std::string why;
        TextureAsset* t = computeResolver_ ? computeResolver_(path, &why) : nullptr;
        if (t) {
            if (!failures_.empty())  // an older "no such image" record is stale now
                failures_.erase(std::remove_if(failures_.begin(), failures_.end(),
                                               [&](const Failure& f) { return f.kind == "texture" && f.path == path; }),
                                failures_.end());
            return t;
        }
        if (drawing_)
            note_failure("texture", path,
                         why.empty() ? std::format("'{}' is a compute image id but no such image exists now.", path)
                                     : why,
                         "Make the image with compute.create_image and use its `textureId`; compute.list_images names "
                         "the live ones.");
        return placeholderTex_.get();
    }
    if (is_target_id(
            path)) {  // a render target: live, never cached (its image is remade when the camera's size changes)
        TextureAsset* t = targetResolver_ ? targetResolver_(path.substr(7)) : nullptr;
        if (t) {
            if (!failures_.empty())  // a camera renders into it now: an older "nobody renders into it" record is stale
                failures_.erase(std::remove_if(failures_.begin(), failures_.end(),
                                               [&](const Failure& f) { return f.kind == "texture" && f.path == path; }),
                                failures_.end());
            return t;
        }
        if (drawing_)
            note_failure(
                "texture", path,
                std::format(
                    "'{}' is a render target id but no active Camera renders into it now (Camera.renderTarget = '{}'). "
                    "Until one does, the missing-texture checker is drawn.",
                    path, path.substr(7)),
                "Add a Camera entity with \"renderTarget\": \"" + path.substr(7) +
                    "\" (and a renderTargetSize), keep it active, "
                    "and check the name against the camera's.");
        return placeholderTex_.get();
    }
    std::string key = fs::normalize(path);
    if (key.empty()) key = path;
    auto it = textures_.find(key);
    if (it != textures_.end()) {
        if (!it->second->untraced.empty()) report_first_use(*it->second);
        return it->second.get();
    }
    if (LoadTrace::current_ahead_tag() == 0) return load_texture(key);
    // Loaded while a background load adopts a model (its texture was not prepared on its own): the files it reads are
    // reported at its first use, like those of a prepared texture.
    std::vector<std::string> files;
    TextureAsset* t = nullptr;
    {
        const LoadTrace::FileCollector collect(&files);
        t = load_texture(key);
    }
    if (t && t != placeholderTex_.get() && !files.empty()) t->untraced = std::move(files);
    return t;
}

bool Assets::has_loaded(const std::string& path) const { return textures_.count(path) || meshes_.count(path); }

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
    if (it != meshes_.end()) {
        if (!it->second->untraced.empty()) report_first_use(*it->second);
        return it->second.get();
    }
    return load_mesh(key);
}

// ---------------------------------------------------------------------------
// Lightmaps (M73.4a)
// ---------------------------------------------------------------------------
namespace {
constexpr std::uint64_t kLightmapMaxGpuBytes = std::uint64_t(1) << 30;  // the pages of one scene, RGBA16F

// The size a Radiance file says it has ("-Y <height> +X <width>", the line after the blank line that ends the header),
// read without decoding a pixel. False when the header does not have that line (decode_hdr then reports what is wrong).
bool hdr_header_size(const std::vector<std::uint8_t>& bytes, std::int64_t& width, std::int64_t& height) {
    const std::size_t limit = std::min<std::size_t>(bytes.size(), 4096);
    std::size_t lineStart = 0;
    bool afterBlank = false;
    for (std::size_t i = 0; i < limit; ++i) {
        if (bytes[i] != '\n') continue;
        const std::string line(reinterpret_cast<const char*>(bytes.data()) + lineStart, i - lineStart);
        lineStart = i + 1;
        if (afterBlank) {
            long long h = 0, w = 0;
            if (std::sscanf(line.c_str(), "-Y %lld +X %lld", &h, &w) != 2 || h <= 0 || w <= 0) return false;
            width = w;
            height = h;
            return true;
        }
        afterBlank = line.empty() || line == "\r";
    }
    return false;
}
}  // namespace

void Assets::destroy_lightmap_set() {
    if (!lightmapSet_) return;
    for (LightmapPageGpu& pg : lightmapSet_->pages) {
        if (pg.view.id) sg_destroy_view(pg.view);
        if (pg.image.id) sg_destroy_image(pg.image);
    }
    lightmapSet_.reset();
}

const LightmapSetAsset* Assets::lightmaps(const std::string& manifestPath) {
    if (manifestPath.empty()) {
        if (lightmapSet_ || !lightmapSetPath_.empty()) {
            destroy_lightmap_set();
            lightmapSetPath_.clear();
        }
        return nullptr;
    }
    if (manifestPath == lightmapSetPath_) return lightmapSet_ && lightmapSet_->ok ? lightmapSet_.get() : nullptr;
    destroy_lightmap_set();
    lightmapSetPath_ = manifestPath;
    failures_.erase(std::remove_if(failures_.begin(), failures_.end(),
                                   [&](const Failure& f) {
                                       return f.kind == "lightmap" || f.kind == "lightmap-page" ||
                                              f.kind == "lightmap-stale";
                                   }),
                    failures_.end());
    lightmapSet_ = std::make_unique<LightmapSetAsset>();
    lightmapSet_->path = manifestPath;
    const std::string path = fs::normalize(manifestPath);
    auto manifest = load_lightmap_manifest(path);
    if (!manifest) {
        note_failure("lightmap", manifestPath,
                     "SceneSettings.lightmaps: " + manifest.error().message +
                         " The scene is drawn without its lightmap.",
                     manifest.error().hint);
        return nullptr;
    }
    lightmapSet_->manifest = std::move(*manifest);
    LightmapSetAsset& set = *lightmapSet_;
    std::uint64_t total = 0;
    for (const LightmapPage& pg : set.manifest.pages) total += std::uint64_t(pg.width) * std::uint64_t(pg.height) * 8u;
    if (total > kLightmapMaxGpuBytes) {
        note_failure(
            "lightmap", manifestPath,
            std::format("{}: the pages hold {} MB of lightmap, more than the {} MB a scene may use. The scene is drawn "
                        "without its lightmap.",
                        manifestPath, total >> 20, kLightmapMaxGpuBytes >> 20),
            "Bake again with a lower density (a smaller MeshRenderer.lightmapScale or a lower texelsPerMeter).");
        return nullptr;
    }
    set.ok = true;
    set.pages.resize(set.manifest.pages.size());
    for (std::size_t i = 0; i < set.pages.size(); ++i) {
        LightmapPageGpu& page = set.pages[i];
        const LightmapPage& want = set.manifest.pages[i];
        page.file = want.file;
        page.width = want.width;
        page.height = want.height;
        const std::string ptr = "/pages/" + std::to_string(i) + "/file";
        // The header says the size before any pixel is decoded: a page that is not the size of the manifest (or whose
        // size alone is more than a scene may use) is refused without allocating its pixels.
        auto bytes = fs::read_bytes(fs::normalize(want.file));
        std::int64_t fileW = 0, fileH = 0;
        if (bytes && hdr_header_size(*bytes, fileW, fileH) &&
            (fileW != want.width || fileH != want.height ||
             std::uint64_t(fileW) * std::uint64_t(fileH) * 8u > kLightmapMaxGpuBytes)) {
            note_failure(
                "lightmap-page", want.file,
                std::format("{}{}: the page '{}' is {}x{} texels but the manifest says {}x{} (a scene may use {} MB "
                            "of lightmap). Entities on this page are drawn without a lightmap.",
                            manifestPath, ptr, want.file, fileW, fileH, want.width, want.height,
                            kLightmapMaxGpuBytes >> 20),
                "The page and the manifest are from different bakes: bake the lightmap again.");
            continue;
        }
        Result<ImageF> img = bytes ? decode_hdr(bytes->data(), bytes->size()) : Result<ImageF>(bytes.error());
        if (!img) {
            note_failure("lightmap-page", want.file,
                         std::format("{}{}: the lightmap page '{}' could not be read: {} Entities on this page are "
                                     "drawn without a lightmap.",
                                     manifestPath, ptr, want.file, img.error().message),
                         img.error().hint.empty()
                             ? "Bake the lightmap again (lightmap.bake) or fix the path in the manifest."
                             : img.error().hint);
            continue;
        }
        if (img->width != want.width || img->height != want.height) {
            note_failure("lightmap-page", want.file,
                         std::format("{}{}: the page '{}' is {}x{} texels but the manifest says {}x{}. Entities on "
                                     "this page are drawn without a "
                                     "lightmap.",
                                     manifestPath, ptr, want.file, img->width, img->height, want.width, want.height),
                         "The page and the manifest are from different bakes: bake the lightmap again.");
            continue;
        }
        std::vector<std::uint16_t> half(std::size_t(img->width) * std::size_t(img->height) * 4);
        for (std::size_t px = 0; px < half.size() / 4; ++px) {
            const float* src = &img->data[px * std::size_t(img->channels)];
            for (int c = 0; c < 3; ++c) half[px * 4 + std::size_t(c)] = float_to_half_bits(src[c]);
            half[px * 4 + 3] = 0x3C00;  // 1.0
        }
        sg_image_desc d{};
        d.width = img->width;
        d.height = img->height;
        d.pixel_format = SG_PIXELFORMAT_RGBA16F;
        d.data.mip_levels[0] = {half.data(), half.size() * sizeof(std::uint16_t)};
        d.label = want.file.c_str();
        page.image = make_image(d);
        if (sg_query_image_state(page.image) != SG_RESOURCESTATE_VALID) {
            sg_destroy_image(page.image);
            page.image = {};
            note_failure("lightmap-page", want.file,
                         std::format("{}{}: the GPU rejected the lightmap page '{}' ({}x{} RGBA16F). Entities on this "
                                     "page are drawn without a lightmap.",
                                     manifestPath, ptr, want.file, img->width, img->height),
                         "Bake again with smaller pages (the GPU's largest texture is smaller than this page).");
            continue;
        }
        sg_view_desc vd{};
        vd.texture.image = page.image;
        vd.label = want.file.c_str();
        page.view = sg_make_view(&vd);
        page.bytes = half.size() * sizeof(std::uint16_t);
        set.bytes += page.bytes;
        page.ok = true;
    }
    return &set;
}

bool Assets::lightmap_use(const LightmapSetAsset& set, const std::string& entityId, MeshAsset& mesh,
                          const std::string& meshName, LightmapUse& out) {
    const LightmapEntry* e = set.manifest.find(entityId);
    if (!e || e->page < 0 || std::size_t(e->page) >= set.pages.size()) return false;
    const LightmapPageGpu& page = set.pages[std::size_t(e->page)];
    if (!page.ok || mesh.placeholder || MeshStore::is_id(mesh.key)) return false;
    if (e->mesh != meshName) return false;  // another mesh than the one baked (or a lod level): drawn without
    if (!mesh.lightmap) {
        mesh.lightmap = std::make_unique<MeshLightmap>();
        MeshLightmap& lm = *mesh.lightmap;
        auto built = build_lightmap_mesh(meshName);
        if (!built) {
            note_failure("lightmap-stale", mesh.key,
                         "lightmap of '" + meshName + "': " + built.error().message +
                             " Entities with this mesh are drawn without a lightmap.",
                         built.error().hint);
        } else if (built->geo.uvKind == "gltf") {
            lm.parts = mesh.parts;  // its own buffers: TEXCOORD_1 is the lightmap UV
            lm.ok = !lm.parts.empty() && lm.parts.size() + 1 == built->geo.partFirstIndex.size();
            if (lm.ok)
                for (SubMesh& p : lm.parts)
                    if (!p.uv1Vb.id) lm.ok = false;
        } else {
            lm.parts = mesh.parts;
            lm.ok = !lm.parts.empty() && lm.parts.size() + 1 == built->geo.partFirstIndex.size();
            if (lm.ok) {
                const LightmapBuild& b = *built;
                sg_buffer_desc vb{};
                vb.data = {b.verts.data(), b.verts.size() * sizeof(MeshVertex)};
                vb.label = "lightmap-vb";
                lm.vb = sg_make_buffer(&vb);
                sg_buffer_desc ib{};
                ib.usage.index_buffer = true;
                ib.usage.vertex_buffer = false;
                ib.data = {b.geo.indices.data(), b.geo.indices.size() * sizeof(std::uint32_t)};
                ib.label = "lightmap-ib";
                lm.ib = sg_make_buffer(&ib);
                std::vector<float> uv;
                uv.reserve(b.geo.uv.size() * 2);
                for (const Vec2& t : b.geo.uv) {
                    uv.push_back(t.x);
                    uv.push_back(t.y);
                }
                sg_buffer_desc ub{};
                ub.data = {uv.data(), uv.size() * sizeof(float)};
                ub.label = "lightmap-uv";
                lm.uv = sg_make_buffer(&ub);
                if (!b.color1.empty()) {
                    sg_buffer_desc cb{};
                    cb.data = {b.color1.data(), b.color1.size() * sizeof(std::uint32_t)};
                    cb.label = "lightmap-color1";
                    lm.color1 = sg_make_buffer(&cb);
                }
                for (std::size_t i = 0; i < lm.parts.size(); ++i) {
                    SubMesh& p = lm.parts[i];
                    p.vb = lm.vb;
                    p.ib = lm.ib;
                    p.uv1Vb = lm.uv;
                    p.color1Vb = lm.color1;
                    p.skinVb = {};
                    p.skin = -1;
                    p.ibOffset = int(b.geo.partFirstIndex[i] * sizeof(std::uint32_t));
                    p.indexCount = int(b.geo.partFirstIndex[i + 1] - b.geo.partFirstIndex[i]);
                    p.vertexCount = int(b.verts.size());
                }
            }
        }
        if (built) {
            lm.uvKind = built->geo.uvKind;
            lm.hashHex = lightmap_hash_hex(built->geo.hash);
            if (!lm.ok)
                note_failure(
                    "lightmap-stale", mesh.key,
                    "lightmap of '" + meshName +
                        "': the mesh has no usable lightmap UVs (its parts do not match the model file). Entities with "
                        "this mesh are drawn without a lightmap.",
                    "Re-import the model, or bake the lightmap again.");
        }
    }
    const MeshLightmap& lm = *mesh.lightmap;
    if (!lm.ok) return false;
    if ((!e->meshHash.empty() && e->meshHash != lm.hashHex) || e->uv != lm.uvKind) {
        note_failure(
            "lightmap-stale", mesh.key,
            std::format("the lightmap of '{}' was baked for a different version of the mesh (the manifest says {} UVs "
                        "and hash {}, the "
                        "mesh now has {} UVs and hash {}). Entities with this mesh are drawn without a lightmap.",
                        meshName, e->uv, e->meshHash, lm.uvKind, lm.hashHex),
            "Bake the lightmap again (lightmap.bake): the model, or the engine's unwrap, changed after the bake.");
        return false;
    }
    out.mesh = &lm;
    out.page = &page;
    for (int i = 0; i < 4; ++i) out.scaleOffset[i] = e->scaleOffset[i];
    return true;
}

sg_buffer Assets::zero_uv1(std::size_t vertices) {
    if (vertices <= zeroUv1Vertices_ && zeroUv1_.id) return zeroUv1_;
    std::size_t cap = std::max<std::size_t>(zeroUv1Vertices_ * 2, 4096);
    while (cap < vertices) cap *= 2;
    if (zeroUv1_.id) sg_destroy_buffer(zeroUv1_);
    std::vector<float> zeros(cap * 2, 0.0f);
    sg_buffer_desc d{};
    d.data = {zeros.data(), zeros.size() * sizeof(float)};
    d.label = "zero-uv1";
    zeroUv1_ = sg_make_buffer(&d);
    zeroUv1Vertices_ = cap;
    return zeroUv1_;
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
                     hint.empty() ? "Make the mesh with mesh.create() in a script of the scene that shows it, and set "
                                    "MeshRenderer.mesh to its `id`."
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
        v.px = d.positions[i * 3];
        v.py = d.positions[i * 3 + 1];
        v.pz = d.positions[i * 3 + 2];
        v.nx = d.normals[i * 3];
        v.ny = d.normals[i * 3 + 1];
        v.nz = d.normals[i * 3 + 2];
        v.u = d.uvs[i * 2];
        v.v = d.uvs[i * 2 + 1];
        v.tx = d.tangents[i * 4];
        v.ty = d.tangents[i * 4 + 1];
        v.tz = d.tangents[i * 4 + 2];
        v.tw = d.tangents[i * 4 + 3];
        if (!d.colors.empty())
            v.color = pack_vertex_color(d.colors[i * 4], d.colors[i * 4 + 1], d.colors[i * 4 + 2], d.colors[i * 4 + 3]);
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
        sm.layers = m.layers;
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
    if (auto l = luts_.find(path); l != luts_.end()) {  // forgotten: the next frame that names it loads the new file
        destroy_lut(*l->second);
        luts_.erase(l);
        failures_.erase(std::remove_if(failures_.begin(), failures_.end(),
                                       [&](const Failure& f) { return f.kind == "lut" && f.path == path; }),
                        failures_.end());
    }
    if (lightmapSet_ || !lightmapSetPath_.empty()) {
        // The manifest or one of its pages changed (or is rewritten by a bake right now): forget the set, the next
        // frame reads it again.
        bool mine = path == fs::normalize(lightmapSetPath_);
        if (lightmapSet_)
            for (const LightmapPageGpu& pg : lightmapSet_->pages) mine = mine || path == fs::normalize(pg.file);
        if (mine) {
            destroy_lightmap_set();
            lightmapSetPath_.clear();
            failures_.erase(std::remove_if(failures_.begin(), failures_.end(),
                                           [&](const Failure& f) {
                                               return f.kind == "lightmap" || f.kind == "lightmap-page" ||
                                                      f.kind == "lightmap-stale";
                                           }),
                            failures_.end());
        }
    }
    auto m = meshes_.find(path);
    if (m != meshes_.end()) {
        if (m->second->placeholder) m->second->parts.clear();  // shared handles
        failures_.erase(std::remove_if(failures_.begin(), failures_.end(),
                                       [&](const Failure& f) { return f.kind == "mesh" && f.path == path; }),
                        failures_.end());
        // A material that lacked a channel of this mesh is told again after the reload (a glTF that now has it draws
        // normally and its "material-mesh" report goes; one that still lacks it is reported again, once).
        const std::string onMesh = " on " + path;
        failures_.erase(std::remove_if(failures_.begin(), failures_.end(),
                                       [&](const Failure& f) {
                                           return f.kind == "material-mesh" && f.path.size() >= onMesh.size() &&
                                                  f.path.compare(f.path.size() - onMesh.size(), onMesh.size(),
                                                                 onMesh) == 0;
                                       }),
                        failures_.end());
        for (auto& [key, mat] : materials_) mat->missingNoted.clear();
        failures_.erase(std::remove_if(failures_.begin(), failures_.end(),
                                       [&](const Failure& f) { return f.kind == "lightmap-stale" && f.path == path; }),
                        failures_.end());
        load_mesh(path);
    }
    // Meshes referencing a reloaded texture keep pointing at the same TextureAsset (updated in place).
    // A material rebuilds in place when its file, its snippet or its compiled twin changed.
    const std::string dialect = backend_dialect(sg_query_backend());
    drop_material_cache();
    variantsChangedNoted_ = false;  // a hot reload starts the "params changed during the frame" warning again
    for (auto& [key, mat] : materials_)
        if (path == key || path == mat->snippet || path == key + "." + dialect + ".shader") build_material(*mat);
}

std::size_t Assets::texture_bytes() const {
    std::size_t total = 0;
    for (const auto& [k, t] : textures_)
        if (!t->placeholder && !t->atlas) total += t->bytes;
    for (const auto& [k, v] : videoTextures_) total += v.tex->bytes;
    for (const auto& [k, t] : runtime_) total += t->bytes;
    for (const auto& [k, l] : luts_) total += l->bytes;
    return total;
}

Json Assets::report() const {
    Json j = Json::object();
    Json tex = Json::array();
    for (const auto& [k, t] : textures_) {
        if (t->placeholder) continue;
        Json entry = {{"path", k},
                      {"width", t->width},
                      {"height", t->height},
                      {"format", pixel_format_name(t->format)},
                      {"bytes", t->bytes}};
        if (t->atlas) entry["atlas"] = t->atlas->path;  // packed: the bytes are the atlas's
        tex.push_back(std::move(entry));
    }
    for (const auto& [k, t] : runtime_)
        tex.push_back({{"path", k},
                       {"width", t->width},
                       {"height", t->height},
                       {"format", pixel_format_name(t->format)},
                       {"bytes", t->bytes},
                       {"runtime", true}});
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
        meshes.push_back({{"mesh", k},
                          {"triangles", tris},
                          {"parts", pm.asset->parts.size()},
                          {"procedural", true},
                          {"version", pm.version},
                          {"bytes", pm.vbCap + pm.ibCap}});
    }
    Json fails = Json::array();
    for (const auto& f : failures_)
        fails.push_back({{"kind", f.kind}, {"path", f.path}, {"message", f.message}, {"hint", f.hint}});
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
