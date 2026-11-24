#include "renderer_impostor.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <format>
#include <set>
#include <utility>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "shader_cache.h"
#include "gpu/sokol_shaders.h"
#include "shaders/impostor.glsl.h"

namespace fa::render {

namespace {

// How often a file that failed is read again (frames): a file written after the first draw is found without a reload event.
constexpr std::uint64_t kRetryFrames = 64;
// After a reload of the file or of one of its pictures, a problem is held back this many frames: the three files change one by one (a
// hot reload sees the new json before the new pictures, or the other way round), and the warning would name a state that lasts a frame.
constexpr std::uint64_t kSettleFrames = 30;
// The albedo and the roughness every impostor is lit with: the atlas keeps the base colour and the normal only (docs/BIG_WORLDS_LOD.md).
constexpr float kImpostorRoughness = 0.85f;

// The slots a built-in program declares (as Gpu's program_slots).
MaterialProgram program_slots(gpu::Shader shader, const gpu::ShaderDesc& desc) {
    MaterialProgram out;
    out.shader = shader;
    for (int i = 0; i < gpu::kMaxUniformBlocks; ++i) {
        if (desc.uniformBlocks[i].stage == gpu::ShaderStage::None) continue;
        out.ubMask |= 1u << i;
        out.ubSize[i] = desc.uniformBlocks[i].size;
    }
    for (int i = 0; i < gpu::kMaxViews; ++i)
        if (desc.views[i].texture.stage != gpu::ShaderStage::None) out.viewMask |= 1u << i;
    for (int i = 0; i < gpu::kMaxSamplers; ++i)
        if (desc.samplers[i].stage != gpu::ShaderStage::None) out.samplerMask |= 1u << i;
    return out;
}

std::uint64_t mix(std::uint64_t h, std::uint64_t v) {
    h ^= v + 0x9e3779b97f4a7c15ull + (h << 6) + (h >> 2);
    return h;
}

// The quaternion of the rotation whose columns are the unit axes c0, c1, c2 (model -> world).
Quat quat_of_axes(Vec3 c0, Vec3 c1, Vec3 c2) {
    const float r00 = c0.x, r10 = c0.y, r20 = c0.z;
    const float r01 = c1.x, r11 = c1.y, r21 = c1.z;
    const float r02 = c2.x, r12 = c2.y, r22 = c2.z;
    const float trace = r00 + r11 + r22;
    Quat q;
    if (trace > 0.0f) {
        const float s = std::sqrt(trace + 1.0f) * 2.0f;
        q = {(r21 - r12) / s, (r02 - r20) / s, (r10 - r01) / s, 0.25f * s};
    } else if (r00 > r11 && r00 > r22) {
        const float s = std::sqrt(1.0f + r00 - r11 - r22) * 2.0f;
        q = {0.25f * s, (r01 + r10) / s, (r02 + r20) / s, (r21 - r12) / s};
    } else if (r11 > r22) {
        const float s = std::sqrt(1.0f + r11 - r00 - r22) * 2.0f;
        q = {(r01 + r10) / s, 0.25f * s, (r12 + r21) / s, (r02 - r20) / s};
    } else {
        const float s = std::sqrt(1.0f + r22 - r00 - r11) * 2.0f;
        q = {(r02 + r20) / s, (r12 + r21) / s, 0.25f * s, (r10 - r01) / s};
    }
    return normalize(q);
}

}  // namespace

const ImpostorDraw* ImpostorDraws::draw(const ImpostorUse& use, const ImpostorCamera& cam) {
    if (auto it = index_.find(use.id); it != index_.end()) return &draws_[it->second];
    ImpostorDraw d;
    const ImpostorAtlas& a = *use.atlas;
    const float p0[4] = {cam.position.x, cam.position.y, cam.position.z, float(a.views)};
    const float p1[4] = {cam.right.x, cam.right.y, cam.right.z, a.mode == ImpostorMode::HemiOctahedral ? 1.0f : 0.0f};
    const float p2[4] = {cam.up.x, cam.up.y, cam.up.z, float(use.albedo->tex_fix(cam.linear, true))};
    const float p3[4] = {float(use.normal->tex_fix(cam.linear, false)), kImpostorRoughness, float(a.frameSize), 0.0f};
    std::memcpy(d.params[0], p0, sizeof p0);
    std::memcpy(d.params[1], p1, sizeof p1);
    std::memcpy(d.params[2], p2, sizeof p2);
    std::memcpy(d.params[3], p3, sizeof p3);
    d.textures[0] = use.albedo;
    d.textures[1] = use.normal;
    std::uint64_t hash = 0x9e3779b97f4a7c15ull;
    for (const auto& row : d.params)
        for (float f : row) {
            std::uint32_t u;
            std::memcpy(&u, &f, sizeof u);
            hash = mix(hash, u);
        }
    for (const TextureAsset* tex : d.textures) hash = mix(hash, tex->gpu_view().id);
    d.hash = std::size_t(hash);
    d.ordinal = std::uint32_t(draws_.size());
    index_[use.id] = draws_.size();
    draws_.push_back(d);
    return &draws_.back();
}

void ImpostorRenderer::destroy() {
    byRaw_.clear();
    lastEntry_ = nullptr;
    lastRaw_.clear();
    entries_.clear();
    if (quad_) {
        for (SubMesh& p : quad_->parts) {
            if (p.vb.id) device_->destroy_buffer(p.vb);
            if (p.ib.id) device_->destroy_buffer(p.ib);
        }
        quad_.reset();
    }
    material_.reset();
    for (gpu::Shader& s : shaders_) {
        if (s.id) device_->destroy_shader(s);
        s = {};
    }
    matState_ = 0;
    device_ = nullptr;
}

// The card: the square (-1..1, -1..1) at z = 0, two triangles. vertex() of shaders/impostor.glsl places it from the instance data, so the
// mesh only says which corner each vertex is.
MeshAsset* ImpostorRenderer::quad(gpu::Device& device) {
    if (quad_) return quad_.get();
    std::vector<MeshVertex> v;
    for (int k = 0; k < 4; ++k) {
        MeshVertex m{};
        m.px = (k & 1) ? 1.0f : -1.0f;
        m.py = (k & 2) ? 1.0f : -1.0f;
        m.nz = 1.0f;
        m.u = (k & 1) ? 1.0f : 0.0f;
        m.v = (k & 2) ? 0.0f : 1.0f;
        m.tx = 1.0f;
        m.tw = 1.0f;
        v.push_back(m);
    }
    const std::uint32_t idx[6] = {0, 1, 3, 0, 3, 2};
    auto mesh = std::make_unique<MeshAsset>();
    mesh->key = "<impostor-card>";
    SubMesh sm;
    gpu::BufferDesc vb;
    vb.usage.vertexBuffer = true;
    vb.size = v.size() * sizeof(MeshVertex);
    vb.data = {v.data(), vb.size};
    vb.label = "impostor-card";
    sm.vb = device.make_buffer(vb);
    gpu::BufferDesc ib;
    ib.usage.indexBuffer = true;
    ib.size = sizeof idx;
    ib.data = {idx, sizeof idx};
    ib.label = vb.label;
    sm.ib = device.make_buffer(ib);
    sm.vertexCount = 4;
    sm.indexCount = 6;
    sm.bmin = {-1, -1, 0};
    sm.bmax = {1, 1, 0};
    mesh->bmin = sm.bmin;
    mesh->bmax = sm.bmax;
    mesh->parts.push_back(sm);
    quad_ = std::move(mesh);
    return quad_.get();
}

// The in-memory material the cards are drawn with: the three programs of shaders/impostor.glsl and the slots of its two textures. alphaMode
// "clip" makes the engine run surface() in the shadow and prepass programs and fade the card with the dither of the LOD cross-fade; doubleSided
// because the card faces the camera whatever the winding. null when the GPU rejects the shaders (said once).
MaterialAsset* ImpostorRenderer::material(gpu::Device& device) {
    if (matState_ != 0) return matState_ > 0 ? material_.get() : nullptr;
    device_ = &device;
    const gpu::ShaderDesc descs[3] = {gpu::generated_shader_desc(impostor_impostor_shader_desc),
                                      gpu::generated_shader_desc(impostor_shadow_shader_desc),
                                      gpu::generated_shader_desc(impostor_prepass_shader_desc)};
    const char* labels[3] = {"impostor_impostor", "impostor_shadow", "impostor_prepass"};
    bool ok = true;
    for (int i = 0; i < 3; ++i) {
        shaders_[i] = make_shader(device, descs[i], labels[i]);
        ok = ok && shaders_[i].id && device.state(shaders_[i]) == gpu::ResourceState::Valid;
    }
    if (!ok) {
        for (gpu::Shader& s : shaders_) {
            if (s.id) device.destroy_shader(s);
            s = {};
        }
        matState_ = -1;
        FA_ERROR(
            "render",
            "The impostor program could not be built for this graphics backend (see the sokol log lines above), so "
            "MeshRenderer.impostor draws nothing and the last level of detail keeps being drawn. Hint: update the "
            "graphics driver (Mesa: try LIBGL_ALWAYS_SOFTWARE=1).");
        return nullptr;
    }
    auto m = std::make_unique<MaterialAsset>();
    m->path = "<impostor>";
    m->kind = MaterialKind::Mesh;
    m->lighting = "pbr";
    m->alphaMode = "clip";
    m->doubleSided = true;
    m->instanceVec4 = 2;
    m->textures = {{"albedo", nullptr, SamplerKind::LinearClamp}, {"normal", nullptr, SamplerKind::LinearClamp}};
    m->programs[kProgMesh] = program_slots(shaders_[0], descs[0]);
    m->programs[kProgShadow] = program_slots(shaders_[1], descs[1]);
    m->programs[kProgPrepass] = program_slots(shaders_[2], descs[2]);
    m->generation = 1;
    m->ok = true;
    material_ = std::move(m);
    matState_ = 1;
    return material_.get();
}

bool ImpostorRenderer::resolve(gpu::Device& device, Assets& assets, std::uint64_t serial, const MeshRenderer& mr,
                               Entity entity, ImpostorUse& out) {
    device_ = &device;
    if (!material(device) || !quad(device)) return false;
    Entry* slot = nullptr;
    std::string key;  // the normalised path, only where an entry is made or read again
    if (lastEntry_ && lastRaw_ == mr.impostor) {
        slot = lastEntry_;
    } else if (auto it = byRaw_.find(mr.impostor); it != byRaw_.end()) {
        slot = it->second;
    } else {
        key = fs::normalize(mr.impostor);
        std::unique_ptr<Entry>& owned = entries_[key];
        if (!owned) owned = std::make_unique<Entry>();
        slot = owned.get();
        byRaw_.emplace(mr.impostor, slot);
    }
    if (lastEntry_ != slot || lastRaw_ != mr.impostor) {
        lastEntry_ = slot;
        lastRaw_ = mr.impostor;
    }
    Entry& en = *slot;
    const std::uint64_t generation = assets.reload_generation();
    const bool reloaded = en.loaded && en.reloadSeen != generation && assets.reloaded_any_of(en.reloadSeen, en.watch);
    if (reloaded) en.settleUntil = serial + kSettleFrames;
    const bool settling = serial < en.settleUntil;
    const bool retry = en.loaded && !en.ok && (settling || en.settlePending || serial - en.triedAt >= kRetryFrames);
    std::string problem;
    if (!en.loaded || reloaded || retry) {
        if (key.empty()) key = fs::normalize(mr.impostor);
        en.loaded = true;
        en.ok = false;
        en.reloadSeen = generation;
        en.triedAt = serial;
        en.texSerial = ~std::uint64_t(0);
        en.watch = {key};
        auto text = fs::read_text(key);
        if (!text) {
            problem = std::format("the file cannot be read: {}", text.error().message);
        } else {
            auto json = parse_json(*text, key);
            if (!json) {
                problem = json.error().message + " " + json.error().hint;
            } else {
                auto atlas = impostor_from_json(*json, key);
                if (!atlas)
                    problem = atlas.error().message + " " + atlas.error().hint;
                else {
                    en.atlas = *atlas;
                    en.ok = true;
                    en.watch.insert(fs::normalize(en.atlas.albedo));
                    en.watch.insert(fs::normalize(en.atlas.normal));
                }
            }
        }
    }
    en.reloadSeen = generation;
    if (en.ok &&
        en.texSerial !=
            serial) {  // the pictures: fetched once a frame (a cached pointer would dangle after Assets::clear())
        en.texSerial = serial;
        en.albedo = assets.texture(en.atlas.albedo);
        en.normal = assets.texture(en.atlas.normal);
        const int side = en.atlas.atlasSize();
        for (const TextureAsset* t : {en.albedo, en.normal}) {
            if (problem.empty() && t->placeholder)
                problem = std::format("the picture '{}' cannot be loaded (see the error above).", t->path);
            else if (problem.empty() && t->atlas)
                problem = std::format(
                    "the picture '{}' was packed into a texture atlas by the export, which impostors cannot "
                    "read.",
                    t->path);
            else if (problem.empty() && (t->width != side || t->height != side))
                problem = std::format("the picture '{}' is {} x {} pixels but the file says {} x {} ({} views of {}).",
                                      t->path, t->width, t->height, side, side, en.atlas.views, en.atlas.frameSize);
        }
        if (!problem.empty()) en.ok = false;
    }
    // A problem seen while the files are still being replaced (the frames after a reload) is held back and looked at again every frame
    // until they settle: the first frame after that says it, if it is still there.
    en.settlePending = !problem.empty() && settling;
    if (en.settlePending) return false;
    if (!en.ok) {
        if (!problem.empty() && problem != en.note) {
            FA_WARN("render",
                    "MeshRenderer.impostor '{}' (entity {}): {} The last level of detail keeps being drawn instead. "
                    "Hint: bake it again "
                    "with model.bake_impostor (its views, resolution and apply arguments write the files and set this "
                    "field), or "
                    "clear MeshRenderer.impostor.",
                    mr.impostor, entity.bits(), problem);
            en.note = problem;
        }
        return false;
    }
    en.note.clear();
    out.atlas = &en.atlas;
    out.albedo = en.albedo;
    out.normal = en.normal;
    out.id = &en;
    return true;
}

void ImpostorRenderer::make_item(MeshItem& item, ImpostorDraws& draws, const ImpostorUse& use,
                                 const ImpostorCamera& cam) {
    const Mat4& m = item.model;
    Vec3 axis[3];
    float scale = 0.0f;
    for (int c = 0; c < 3; ++c) {
        const Vec3 col{m.at(c, 0), m.at(c, 1), m.at(c, 2)};
        const float len = length(col);
        scale = std::max(scale, len);
        axis[c] = len > 1e-12f ? col / len : Vec3{c == 0 ? 1.0f : 0.0f, c == 1 ? 1.0f : 0.0f, c == 2 ? 1.0f : 0.0f};
    }
    if (!(scale > 0.0f) || !std::isfinite(scale)) scale = 1.0f;
    // A matrix that mirrors (negative determinant: a negative scale) is a proper rotation after the model's x axis is flipped: the rotation is
    // made from -x, and the radius carries the sign for the shader (shaders/impostor.glsl) to flip x back where it reads the atlas.
    const bool mirrored = dot(cross(axis[0], axis[1]), axis[2]) < 0.0f;
    if (mirrored) axis[0] = axis[0] * -1.0f;
    const Quat toWorld = quat_of_axes(axis[0], axis[1], axis[2]);
    const Quat toModel = toWorld.conjugate();
    const Vec3 centre = m.transform_point(use.atlas->center);
    const float radius = use.atlas->radius * scale;
    const ImpostorDraw* d = draws.draw(use, cam);
    item.mesh = quad(*device_);  // item.mr stays the entity's own: its shadow, decal and unlit flags still apply
    item.material = material(*device_);
    item.tex = nullptr;
    item.normalTex = nullptr;
    item.anim = nullptr;
    item.lm = {};
    item.model = Mat4::identity();  // vertex() reads the instance data, never the matrix; the box below is in the world
    const float reach = radius * 1.4143f;  // the corner of the card
    item.bmin = centre - Vec3{reach, reach, reach};
    item.bmax = centre + Vec3{reach, reach, reach};
    item.noCull = false;
    item.paramsHash = d->hash;
    item.colorsHash = 0;
    item.keyed = true;
    item.sortKey = kImpostorSortKey + d->ordinal;
    item.impostor = d;
    item.terrainNode = {centre.x,  centre.y,  centre.z,  mirrored ? -radius : radius,
                        toModel.x, toModel.y, toModel.z, toModel.w};
}

}  // namespace fa::render
