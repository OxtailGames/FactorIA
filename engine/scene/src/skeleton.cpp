#include "fa/scene/skeleton.h"

#include <cgltf.h>

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <format>
#include <map>
#include <mutex>

#include "fa/core/fs.h"
#include "fa/scene/gltf_file.h"

namespace fa {

namespace {

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

// Rotation matrix (columns already divided by the scale) to a unit quaternion.
Quat quat_from_basis(const float c[3][3]) {
    const float m00 = c[0][0], m10 = c[0][1], m20 = c[0][2];  // column 0
    const float m01 = c[1][0], m11 = c[1][1], m21 = c[1][2];
    const float m02 = c[2][0], m12 = c[2][1], m22 = c[2][2];
    Quat q;
    const float tr = m00 + m11 + m22;
    if (tr > 0) {
        const float s = std::sqrt(tr + 1.0f) * 2.0f;
        q = {(m21 - m12) / s, (m02 - m20) / s, (m10 - m01) / s, 0.25f * s};
    } else if (m00 > m11 && m00 > m22) {
        const float s = std::sqrt(1.0f + m00 - m11 - m22) * 2.0f;
        q = {0.25f * s, (m01 + m10) / s, (m02 + m20) / s, (m21 - m12) / s};
    } else if (m11 > m22) {
        const float s = std::sqrt(1.0f + m11 - m00 - m22) * 2.0f;
        q = {(m01 + m10) / s, 0.25f * s, (m12 + m21) / s, (m02 - m20) / s};
    } else {
        const float s = std::sqrt(1.0f + m22 - m00 - m11) * 2.0f;
        q = {(m02 + m20) / s, (m12 + m21) / s, 0.25f * s, (m10 - m01) / s};
    }
    return normalize(q);
}

void read_node_rest(const cgltf_node& n, SkelNode& out) {
    if (n.has_matrix) {  // column-major, may contain scale
        const float* m = n.matrix;
        out.translation = {m[12], m[13], m[14]};
        float c[3][3];
        Vec3 sc;
        for (int i = 0; i < 3; ++i) {
            const float l = std::sqrt(m[i * 4] * m[i * 4] + m[i * 4 + 1] * m[i * 4 + 1] + m[i * 4 + 2] * m[i * 4 + 2]);
            (&sc.x)[i] = l;
            const float inv = l > 1e-8f ? 1.0f / l : 0.0f;
            for (int j = 0; j < 3; ++j) c[i][j] = m[i * 4 + j] * inv;
        }
        out.scale = sc;
        out.rotation = quat_from_basis(c);
        return;
    }
    if (n.has_translation) out.translation = {n.translation[0], n.translation[1], n.translation[2]};
    if (n.has_rotation) out.rotation = normalize(Quat{n.rotation[0], n.rotation[1], n.rotation[2], n.rotation[3]});
    if (n.has_scale) out.scale = {n.scale[0], n.scale[1], n.scale[2]};
}

}  // namespace

void gltf_use_fs(cgltf_options& opts) {
    opts.file.read = &file_read;
    opts.file.release = &file_release;
}

int SkeletonAsset::find_clip(std::string_view name) const {
    for (std::size_t i = 0; i < clips.size(); ++i)
        if (clips[i].name == name) return int(i);
    return -1;
}

std::vector<std::string> SkeletonAsset::clip_names() const {
    std::vector<std::string> out;
    for (const AnimClip& c : clips) out.push_back(c.name);
    return out;
}

Result<SkeletonAsset> parse_skeleton(const std::vector<std::uint8_t>& bytes, std::string_view pathView) {
    const std::string path(pathView);
    cgltf_options opts{};
    gltf_use_fs(opts);
    cgltf_data* data = nullptr;
    cgltf_result r = cgltf_parse(&opts, bytes.data(), bytes.size(), &data);
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

    SkeletonAsset out;
    out.path = path;
    auto node_index = [&](const cgltf_node* n) { return n ? int(n - data->nodes) : -1; };

    out.nodes.resize(data->nodes_count);
    for (cgltf_size i = 0; i < data->nodes_count; ++i) {
        SkelNode& n = out.nodes[i];
        n.name = data->nodes[i].name ? data->nodes[i].name : "";
        n.parent = node_index(data->nodes[i].parent);
        read_node_rest(data->nodes[i], n);
    }
    // Parents before children, whatever the order of the file (stable: file order among siblings).
    std::vector<char> placed(out.nodes.size(), 0);
    while (out.order.size() < out.nodes.size()) {
        const std::size_t before = out.order.size();
        for (std::size_t i = 0; i < out.nodes.size(); ++i) {
            if (placed[i]) continue;
            const int p = out.nodes[i].parent;
            if (p < 0 || placed[std::size_t(p)]) {
                placed[i] = 1;
                out.order.push_back(int(i));
            }
        }
        if (out.order.size() == before)
            return make_error(std::format("'{}': the node hierarchy has a cycle", path), "glTF nodes must form a forest.");
    }

    for (cgltf_size si = 0; si < data->skins_count; ++si) {
        const cgltf_skin& sk = data->skins[si];
        SkelSkin skin;
        skin.name = sk.name ? sk.name : "";
        for (cgltf_size j = 0; j < sk.joints_count; ++j) skin.joints.push_back(node_index(sk.joints[j]));
        skin.inverseBind.assign(sk.joints_count, Mat4::identity());
        if (sk.inverse_bind_matrices) {
            if (sk.inverse_bind_matrices->count < sk.joints_count)
                return make_error(std::format("'{}': skin {} has {} joints but only {} inverse bind matrices", path, si,
                                              sk.joints_count, sk.inverse_bind_matrices->count),
                                  "Re-export the model: every joint needs an inverse bind matrix.");
            for (cgltf_size j = 0; j < sk.joints_count; ++j)
                cgltf_accessor_read_float(sk.inverse_bind_matrices, j, skin.inverseBind[j].m, 16);
        }
        out.skins.push_back(std::move(skin));
    }

    for (cgltf_size ai = 0; ai < data->animations_count; ++ai) {
        const cgltf_animation& an = data->animations[ai];
        AnimClip clip;
        clip.name = an.name ? an.name : std::format("animation{}", ai);
        for (cgltf_size ci = 0; ci < an.channels_count; ++ci) {
            const cgltf_animation_channel& ch = an.channels[ci];
            if (!ch.target_node || !ch.sampler) continue;
            AnimChannel c;
            switch (ch.target_path) {
                case cgltf_animation_path_type_translation: c.path = AnimPath::Translation; break;
                case cgltf_animation_path_type_rotation: c.path = AnimPath::Rotation; break;
                case cgltf_animation_path_type_scale: c.path = AnimPath::Scale; break;
                default: continue;  // morph target weights are not supported yet
            }
            const cgltf_animation_sampler& sm = *ch.sampler;
            c.node = node_index(ch.target_node);
            c.interp = sm.interpolation == cgltf_interpolation_type_step           ? AnimInterp::Step
                       : sm.interpolation == cgltf_interpolation_type_cubic_spline ? AnimInterp::CubicSpline
                                                                                   : AnimInterp::Linear;
            const cgltf_size comps = c.path == AnimPath::Rotation ? 4 : 3;
            const cgltf_size perKey = c.interp == AnimInterp::CubicSpline ? 3 : 1;
            if (sm.input->count == 0 || sm.output->count != sm.input->count * perKey)
                return make_error(std::format("'{}': animation '{}' channel {} has {} keys but {} values", path, clip.name,
                                              ci, sm.input->count, sm.output->count),
                                  c.interp == AnimInterp::CubicSpline
                                      ? "CUBICSPLINE needs three values per key (in tangent, value, out tangent)."
                                      : "A sampler needs one output value per input time.");
            c.times.resize(sm.input->count);
            cgltf_accessor_unpack_floats(sm.input, c.times.data(), c.times.size());
            c.values.resize(sm.output->count * comps);
            cgltf_accessor_unpack_floats(sm.output, c.values.data(), c.values.size());
            clip.duration = std::max(clip.duration, c.times.back());
            clip.channels.push_back(std::move(c));
        }
        out.clips.push_back(std::move(clip));
    }

    for (cgltf_size ni = 0; ni < data->nodes_count; ++ni) {
        const cgltf_node& node = data->nodes[ni];
        if (!node.mesh || !node.skin) continue;
        for (cgltf_size pi = 0; pi < node.mesh->primitives_count; ++pi) {
            const cgltf_primitive& prim = node.mesh->primitives[pi];
            if (prim.type != cgltf_primitive_type_triangles) continue;
            const cgltf_accessor *pos = nullptr, *jnt = nullptr, *wgt = nullptr;
            for (cgltf_size a = 0; a < prim.attributes_count; ++a) {
                const cgltf_attribute& at = prim.attributes[a];
                if (at.index != 0) continue;
                if (at.type == cgltf_attribute_type_position) pos = at.data;
                else if (at.type == cgltf_attribute_type_joints) jnt = at.data;
                else if (at.type == cgltf_attribute_type_weights) wgt = at.data;
            }
            if (!pos || !jnt || !wgt) continue;
            SkinVertices sv;
            sv.node = int(ni);
            sv.primitive = int(pi);
            sv.skin = int(node.skin - data->skins);
            sv.joints.resize(pos->count);
            sv.weights.resize(pos->count);
            const std::size_t jointCount = node.skin->joints_count;
            for (cgltf_size v = 0; v < pos->count; ++v) {
                cgltf_uint j[4] = {0, 0, 0, 0};
                float w[4] = {1, 0, 0, 0};
                if (v < jnt->count) cgltf_accessor_read_uint(jnt, v, j, 4);
                if (v < wgt->count) cgltf_accessor_read_float(wgt, v, w, 4);
                for (int k = 0; k < 4; ++k) {
                    if (j[k] >= jointCount) { j[k] = 0; w[k] = 0; }  // a bad index must not read outside the palette
                    sv.joints[v][k] = std::uint16_t(j[k]);
                }
                const float sum = w[0] + w[1] + w[2] + w[3];
                for (int k = 0; k < 4; ++k) sv.weights[v][k] = sum > 1e-8f ? w[k] / sum : (k == 0 ? 1.0f : 0.0f);
            }
            out.skinVertices.push_back(std::move(sv));
        }
    }
    return out;
}

namespace {
std::mutex g_cacheMutex;
struct CacheEntry {
    std::int64_t mtime = -1;
    std::shared_ptr<const SkeletonAsset> asset;
};
std::map<std::string, CacheEntry>& cache() {
    static std::map<std::string, CacheEntry> c;
    return c;
}
}  // namespace

Result<std::shared_ptr<const SkeletonAsset>> load_skeleton(std::string_view pathView) {
    const std::string path(pathView);
    const std::int64_t mtime = fs::modified_time(path);
    {
        std::lock_guard lock(g_cacheMutex);
        auto it = cache().find(path);
        if (it != cache().end() && it->second.mtime == mtime) return it->second.asset;
    }
    auto bytes = fs::read_bytes(path);
    if (!bytes) return bytes.error();
    auto parsed = parse_skeleton(*bytes, path);
    if (!parsed) return parsed.error();
    auto asset = std::make_shared<const SkeletonAsset>(std::move(*parsed));
    std::lock_guard lock(g_cacheMutex);
    cache()[path] = CacheEntry{mtime, asset};
    return asset;
}

}  // namespace fa
