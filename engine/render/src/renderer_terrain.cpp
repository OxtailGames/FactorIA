#include "renderer_terrain.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <format>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/log.h"
#include "fa/scene/world.h"
#include "render_jobs.h"
#include "render_scene.h"
#include "shader_cache.h"
#include "shaders/terrain.glsl.h"

namespace fa::render {

namespace {

// The slots a built-in program declares (as Gpu's program_slots).
MaterialProgram program_slots(sg_shader shader, const sg_shader_desc* desc) {
    MaterialProgram out;
    out.shader = shader;
    for (int i = 0; i < SG_MAX_UNIFORMBLOCK_BINDSLOTS; ++i) {
        if (desc->uniform_blocks[i].stage == SG_SHADERSTAGE_NONE) continue;
        out.ubMask |= 1u << i;
        out.ubSize[i] = desc->uniform_blocks[i].size;
    }
    for (int i = 0; i < SG_MAX_VIEW_BINDSLOTS; ++i)
        if (desc->views[i].texture.stage != SG_SHADERSTAGE_NONE) out.viewMask |= 1u << i;
    for (int i = 0; i < SG_MAX_SAMPLER_BINDSLOTS; ++i)
        if (desc->samplers[i].stage != SG_SHADERSTAGE_NONE) out.samplerMask |= 1u << i;
    return out;
}

float number_of(const Json& o, const char* key, float fallback, float lo, float hi) {
    auto it = o.find(key);
    if (it == o.end() || !it->is_number()) return fallback;
    const double v = it->get<double>();
    return std::isfinite(v) ? float(std::clamp(v, double(lo), double(hi))) : fallback;
}

std::string string_of(const Json& o, const char* key) {
    auto it = o.find(key);
    return it != o.end() && it->is_string() ? it->get<std::string>() : std::string();
}

std::uint64_t mix(std::uint64_t h, std::uint64_t v) {
    h ^= v + 0x9e3779b97f4a7c15ull + (h << 6) + (h >> 2);
    return h;
}

}  // namespace

std::vector<TerrainLayerInfo> terrain_layers(const Terrain3D& t) {
    std::vector<TerrainLayerInfo> out;
    if (!t.layers.is_array()) return out;
    for (std::size_t i = 0; i < t.layers.size() && i < std::size_t(kMaxTerrainLayers); ++i) {
        TerrainLayerInfo info;
        if (t.layers[i].is_object()) {
            const Json& l = t.layers[i];
            info.albedo = string_of(l, "albedo");
            info.normal = string_of(l, "normal");
            info.tileSize = number_of(l, "tileSize", info.tileSize, 0.01f, 100000.0f);
            info.roughness = number_of(l, "roughness", info.roughness, 0.0f, 1.0f);
            info.metallic = number_of(l, "metallic", info.metallic, 0.0f, 1.0f);
            info.normalScale = number_of(l, "normalScale", info.normalScale, 0.0f, 4.0f);
        }
        out.push_back(std::move(info));
    }
    return out;
}

namespace {

void free_texture(TextureAsset& t) {
    if (t.view.id) sg_destroy_view(t.view);
    if (t.image.id) sg_destroy_image(t.image);
    t.view = {};
    t.image = {};
    t.bytes = 0;
}

// Wraps `d` (an array image) in a TextureAsset; false (nothing kept) when the GPU rejects it.
bool finish_array(TextureAsset& out, const sg_image_desc& d, const char* label, std::size_t bytes) {
    sg_image image = make_array_image(d);
    if (!image.id || sg_query_image_state(image) != SG_RESOURCESTATE_VALID) {
        if (image.id) sg_destroy_image(image);
        return false;
    }
    sg_view_desc vd{};
    vd.texture.image = image;
    vd.label = label;
    out.image = image;
    out.view = sg_make_view(&vd);
    out.path = label;
    out.width = d.width;
    out.height = d.height;
    out.format = d.pixel_format;
    out.bytes = bytes;
    return true;
}

// One RGBA8 array from the pictures of the layers (a layer without one stays zeros), with its mip chain. The pictures are given up as they
// are packed (the chain of the last one is all that exists next to the array).
bool make_picture_array(TextureAsset& out, const char* label, TerrainLayerImages& li, sg_pixel_format format,
                        bool srgbMips, std::string& why) {
    const int slices = int(li.images.size());
    const sg_limits lim = sg_query_limits();
    if (slices > lim.max_image_array_layers || li.width > lim.max_image_size_array ||
        li.height > lim.max_image_size_array) {
        why = std::format(
            "this GPU holds array textures of {} layers of {} x {} pixels at most, and the layers need {} of {} x {}",
            lim.max_image_array_layers, lim.max_image_size_array, lim.max_image_size_array, slices, li.width,
            li.height);
        return false;
    }
    std::vector<std::vector<std::uint8_t>> levels;  // per mip level, every slice one after the other
    for (int s = 0; s < slices; ++s) {
        if (li.images[std::size_t(s)].empty()) continue;
        std::vector<Image> chain = mip_chain(std::move(li.images[std::size_t(s)]), srgbMips);
        li.images[std::size_t(s)] = Image();
        if (levels.empty()) {
            levels.resize(chain.size());
            for (std::size_t m = 0; m < chain.size(); ++m)
                levels[m].assign(chain[m].rgba.size() * std::size_t(slices), 0);
        }
        for (std::size_t m = 0; m < chain.size() && m < levels.size(); ++m)
            std::memcpy(levels[m].data() + chain[m].rgba.size() * std::size_t(s), chain[m].rgba.data(),
                        chain[m].rgba.size());
    }
    if (levels.empty() || levels.size() > std::size_t(SG_MAX_MIPMAPS)) {
        why = "there is no picture to make the array from";
        return false;
    }
    sg_image_desc d{};
    d.type = SG_IMAGETYPE_ARRAY;
    d.width = li.width;
    d.height = li.height;
    d.num_slices = slices;
    d.num_mipmaps = int(levels.size());
    d.pixel_format = format;
    d.label = label;
    std::size_t bytes = 0;
    for (std::size_t m = 0; m < levels.size(); ++m) {
        d.data.mip_levels[m] = {levels[m].data(), levels[m].size()};
        bytes += levels[m].size();
    }
    if (!finish_array(out, d, label, bytes)) {
        why = "the GPU could not make the texture array (out of memory?)";
        return false;
    }
    return true;
}

// The bilinear sample of an RGBA8 picture at texel centres (as the GPU filters it, edges clamped), channel c, at (x, y) given in the
// source's texel units with 0 at the centre of its first texel.
float bilinear_channel(const std::vector<std::uint8_t>& px, int w, int h, float x, float y, int c) {
    x = std::clamp(x, 0.0f, float(w - 1));
    y = std::clamp(y, 0.0f, float(h - 1));
    const int x0 = int(x), y0 = int(y), x1 = std::min(x0 + 1, w - 1), y1 = std::min(y0 + 1, h - 1);
    const float fx = x - float(x0), fy = y - float(y0);
    auto at = [&](int xx, int yy) {
        return float(px[(std::size_t(yy) * std::size_t(w) + std::size_t(xx)) * 4 + std::size_t(c)]);
    };
    return (at(x0, y0) * (1 - fx) + at(x1, y0) * fx) * (1 - fy) + (at(x0, y1) * (1 - fx) + at(x1, y1) * fx) * fy;
}

// The control array: the splat maps (RGBA, one slice each; `maps` slices, the ones a terrain does not have are zeros) and, when there are
// holes, a slice with 255 in its red channel for the hole cells. Every slice is `side` x `side`: the size of the biggest splat map (the
// smaller one is resampled bilinearly), and with holes at least min(cells, kTerrainMaxSplatSide) so one pixel is one cell where it can.
bool make_control_array(TextureAsset& out, const TerrainHeights& h, int maps, bool holes, int& side, std::string& why) {
    const sg_limits lim = sg_query_limits();
    const int cells = std::max(1, h.samples - 1);
    int w = 1;
    for (int m = 0; m < maps; ++m) w = std::max(w, h.splat[std::size_t(m)].valid() ? h.splat[std::size_t(m)].size : 1);
    if (holes) w = std::max(w, std::min(cells, kTerrainMaxSplatSide));
    const int ht = w;
    side = w;
    const int slices = maps + (holes ? 1 : 0);
    if (slices > lim.max_image_array_layers || w > lim.max_image_size_array) {
        why =
            std::format("this GPU holds array textures of {} layers of {} x {} pixels at most, and the splat maps and "
                        "holes need {} of {} x {}",
                        lim.max_image_array_layers, lim.max_image_size_array, lim.max_image_size_array, slices, w, ht);
        return false;
    }
    const std::size_t slice = std::size_t(w) * std::size_t(ht) * 4;
    std::vector<std::uint8_t> data(slice * std::size_t(slices), 0);
    for (int m = 0; m < maps; ++m) {
        const TerrainSplat& map = h.splat[std::size_t(m)];
        if (!map.valid()) continue;
        std::uint8_t* dst = data.data() + slice * std::size_t(m);
        if (map.size == w) {
            std::memcpy(dst, map.rgba.data(), slice);
            continue;
        }
        for (int y = 0; y < ht; ++y)
            for (int x = 0; x < w; ++x) {
                const float sx = (float(x) + 0.5f) * float(map.size) / float(w) - 0.5f;
                const float sy = (float(y) + 0.5f) * float(map.size) / float(ht) - 0.5f;
                for (int c = 0; c < 4; ++c)
                    dst[(std::size_t(y) * std::size_t(w) + std::size_t(x)) * 4 + std::size_t(c)] = std::uint8_t(
                        std::clamp(bilinear_channel(map.rgba, map.size, map.size, sx, sy, c) + 0.5f, 0.0f, 255.0f));
            }
    }
    if (holes) {
        std::uint8_t* dst = data.data() + slice * std::size_t(maps);
        for (int y = 0; y < ht; ++y) {
            const int r =
                int(std::min<std::int64_t>(cells - 1, (std::int64_t(2) * y + 1) * cells / (std::int64_t(2) * ht)));
            for (int x = 0; x < w; ++x) {
                const int c =
                    int(std::min<std::int64_t>(cells - 1, (std::int64_t(2) * x + 1) * cells / (std::int64_t(2) * w)));
                if (h.hole(c, r)) dst[(std::size_t(y) * std::size_t(w) + std::size_t(x)) * 4] = 255;
            }
        }
    }
    sg_image_desc d{};
    d.type = SG_IMAGETYPE_ARRAY;
    d.width = w;
    d.height = ht;
    d.num_slices = slices;
    d.pixel_format = SG_PIXELFORMAT_RGBA8;
    d.data.mip_levels[0] = {data.data(), data.size()};
    d.label = "terrain-control";
    if (!finish_array(out, d, "terrain-control", data.size())) {
        why = "the GPU could not make the texture array (out of memory?)";
        return false;
    }
    return true;
}

std::uint64_t hash_string(std::uint64_t h, const std::string& s) {
    for (unsigned char c : s) h = mix(h, c);
    return mix(h, s.size());
}

}  // namespace

TerrainRenderer::Entry::~Entry() {
    free_texture(tex);
    free_texture(albedoArr);
    free_texture(normalArr);
    free_texture(controlArr);
    if (stage.id) sg_destroy_buffer(stage);
}

void TerrainRenderer::destroy() {
    entries_.clear();
    for (std::unique_ptr<MeshAsset>* slot : {&patch_, &splitPatch_}) {
        if (!*slot) continue;
        for (SubMesh& p : (*slot)->parts) {
            if (p.vb.id) sg_destroy_buffer(p.vb);
            if (p.ib.id) sg_destroy_buffer(p.ib);
        }
        slot->reset();
    }
    material_.reset();
    free_texture(dummy_);
    for (sg_shader& s : shaders_) {
        if (s.id) sg_destroy_shader(s);
        s = {};
    }
    matState_ = 0;
}

std::size_t TerrainRenderer::bytes() const {
    std::size_t total = 0;
    for (const auto& [key, en] : entries_)
        total += en->tex.bytes + en->albedoArr.bytes + en->normalArr.bytes + en->controlArr.bytes + en->stageCap;
    return total + dummy_.bytes;
}

// The patch: 33 x 33 vertices at the integers (gx, 0, gz), 32 x 32 cells of two triangles each on the diagonal (0, 0) - (1, 1) (the
// diagonal of the physics heightfield and of terrain_vertex_raw), counter-clockwise seen from +y. Shared: one vertex serves the cells around
// it. The SPLIT patch (a terrain with holes) gives every cell its own four vertices, whose uv is the cell's lower-left corner (0..31):
// vertex() of shaders/terrain.glsl collapses the four vertices of a cell that is a hole, which no shared vertex can do.
MeshAsset* TerrainRenderer::patch(bool split) {
    std::unique_ptr<MeshAsset>& slot = split ? splitPatch_ : patch_;
    if (slot) return slot.get();
    std::vector<MeshVertex> v;
    std::vector<std::uint32_t> idx;
    idx.reserve(std::size_t(kTerrainTrianglesPerNode) * 3);
    auto vertex = [&](int x, int z, float u, float w) {
        MeshVertex m{};
        m.px = float(x);
        m.pz = float(z);
        m.ny = 1.0f;
        m.u = u;
        m.v = w;
        m.tx = 1.0f;
        m.tw = 1.0f;
        v.push_back(m);
    };
    if (split) {
        v.reserve(std::size_t(kTerrainPatchCells) * kTerrainPatchCells * 4);
        for (int z = 0; z < kTerrainPatchCells; ++z)
            for (int x = 0; x < kTerrainPatchCells; ++x) {
                const std::uint32_t a = std::uint32_t(v.size()), b = a + 1, c = a + 2, d = a + 3;
                vertex(x, z, float(x), float(z));
                vertex(x + 1, z, float(x), float(z));
                vertex(x, z + 1, float(x), float(z));
                vertex(x + 1, z + 1, float(x), float(z));
                idx.insert(idx.end(), {a, c, d, a, d, b});
            }
    } else {
        v.reserve(std::size_t(kTerrainPatch) * kTerrainPatch);
        for (int z = 0; z < kTerrainPatch; ++z)
            for (int x = 0; x < kTerrainPatch; ++x)
                vertex(x, z, float(x) / float(kTerrainPatchCells), float(z) / float(kTerrainPatchCells));
        for (int z = 0; z < kTerrainPatchCells; ++z)
            for (int x = 0; x < kTerrainPatchCells; ++x) {
                const std::uint32_t a = std::uint32_t(z * kTerrainPatch + x), b = a + 1, c = a + kTerrainPatch,
                                    d = c + 1;
                idx.insert(idx.end(), {a, c, d, a, d, b});
            }
    }
    auto mesh = std::make_unique<MeshAsset>();
    mesh->key = split ? "<terrain-patch-split>" : "<terrain-patch>";
    SubMesh sm;
    sg_buffer_desc vb{};
    vb.data = {v.data(), v.size() * sizeof(MeshVertex)};
    vb.label = split ? "terrain-patch-split" : "terrain-patch";
    sm.vb = sg_make_buffer(&vb);
    sg_buffer_desc ib{};
    ib.usage.index_buffer = true;
    ib.usage.vertex_buffer = false;
    ib.data = {idx.data(), idx.size() * sizeof(std::uint32_t)};
    ib.label = vb.label;
    sm.ib = sg_make_buffer(&ib);
    sm.vertexCount = int(v.size());
    sm.indexCount = int(idx.size());
    sm.bmin = {0, 0, 0};
    sm.bmax = {float(kTerrainPatchCells), 0, float(kTerrainPatchCells)};
    mesh->bmin = sm.bmin;
    mesh->bmax = sm.bmax;
    mesh->parts.push_back(sm);
    slot = std::move(mesh);
    return slot.get();
}

// The in-memory material the nodes are drawn with: the three programs of shaders/terrain.glsl and the slots of its textures (the heights
// through a nearest sampler, the albedo and normal arrays of the layers, the control array of the splat maps and holes). A hole is cut in the
// geometry (the split patch, vertex() of shaders/terrain.glsl), so no program discards. null when the GPU rejects the shaders (said once).
MaterialAsset* TerrainRenderer::material() {
    if (matState_ != 0) return matState_ > 0 ? material_.get() : nullptr;
    const sg_backend backend = sg_query_backend();
    const sg_shader_desc* descs[3] = {terrain_terrain_shader_desc(backend), terrain_shadow_shader_desc(backend),
                                      terrain_prepass_shader_desc(backend)};
    const char* labels[3] = {"terrain_terrain", "terrain_shadow", "terrain_prepass"};
    bool ok = true;
    for (int i = 0; i < 3; ++i) {
        shaders_[i] = descs[i] ? make_shader(descs[i], labels[i]) : sg_shader{};
        ok = ok && shaders_[i].id && sg_query_shader_state(shaders_[i]) == SG_RESOURCESTATE_VALID;
    }
    if (!ok) {
        for (sg_shader& s : shaders_) {
            if (s.id) sg_destroy_shader(s);
            s = {};
        }
        matState_ = -1;
        FA_ERROR("render", "The Terrain program could not be built for this graphics backend (see the sokol log lines "
                           "above), so terrains are "
                           "not drawn. Hint: update the graphics driver (Mesa: try LIBGL_ALWAYS_SOFTWARE=1).");
        return nullptr;
    }
    auto m = std::make_unique<MaterialAsset>();
    m->path = "<terrain>";
    m->kind = MaterialKind::Mesh;
    m->lighting = "pbr";
    m->instanceVec4 = 2;
    m->textures = {{"height", nullptr, SamplerKind::Nearest},
                   {"albedo", nullptr, SamplerKind::LinearRepeat},
                   {"normal", nullptr, SamplerKind::LinearRepeat},
                   {"control", nullptr, SamplerKind::LinearClamp}};
    m->programs[kProgMesh] = program_slots(shaders_[0], descs[0]);
    m->programs[kProgShadow] = program_slots(shaders_[1], descs[1]);
    m->programs[kProgPrepass] = program_slots(shaders_[2], descs[2]);
    m->generation = 1;
    m->ok = true;
    material_ = std::move(m);
    matState_ = 1;
    return material_.get();
}

// The largest 2^k + 1 that is at most `limit` (the sizes a heightmap can have), at least 33.
static int largest_samples_within(int limit) {
    int n = 33;
    while (n * 2 - 1 <= limit) n = n * 2 - 1;
    return n;
}

// RG8 pixels of the heights of the rectangle `r` (the whole grid for an empty one): r = the high byte, g = the low byte.
static std::vector<std::uint8_t> pack_heights(const fa::TerrainHeights& h, const TerrainRect& r) {
    const int w = r.c1 - r.c0 + 1, ht = r.r1 - r.r0 + 1;
    std::vector<std::uint8_t> px(std::size_t(w) * std::size_t(ht) * 2);
    std::size_t o = 0;
    for (int y = r.r0; y <= r.r1; ++y) {
        const std::uint16_t* row = h.data.data() + std::size_t(y) * std::size_t(h.samples) + std::size_t(r.c0);
        for (int x = 0; x < w; ++x) {
            px[o++] = std::uint8_t(row[x] >> 8);
            px[o++] = std::uint8_t(row[x] & 0xFF);
        }
    }
    return px;
}

// A sculpt changed `rect` of the heights: the texture of the terrain takes only those samples (a staging buffer written for the frame and
// copied into it), not the whole 2 bytes per sample again. The first sculpt makes the texture one that takes copies (the whole of it once, through a
// staging buffer of its size that is freed again); the later ones keep a staging buffer the size of the largest rectangle. False (nothing
// changed) where a copy cannot run: inside a pass, a second write in the same frame, no Gpu, or the GPU said no; the caller makes the
// whole texture again then.
bool TerrainRenderer::copy_rect(Entry& en, const View& v, const TerrainRect& rect) {
    const fa::TerrainHeights& h = *en.heights;
    if (!v.gpu || !en.tex.image.id || en.tex.width != h.samples || sg_query_pass_state() != SG_PASSSTATE_NONE)
        return false;
    const std::uint64_t frameTag = v.gpu->frame() + 1;
    if (en.stagedFrame == frameTag) return false;
    TerrainRect whole;
    whole.c0 = whole.r0 = 0;
    whole.c1 = whole.r1 = h.samples - 1;
    const bool convert = !en.copyable;
    const TerrainRect& r = convert ? whole : rect;
    const std::vector<std::uint8_t> px = pack_heights(h, r);
    v.gpu->begin_transient_writes();  // before the first write of the frame (render_internal.h)
    sg_image target = en.tex.image;
    sg_view targetView = en.tex.view;
    if (convert) {
        sg_image_desc d{};
        d.width = d.height = h.samples;
        d.pixel_format = SG_PIXELFORMAT_RG8;
        d.usage.copy_dst = true;
        d.label = "terrain-heights";
        target = make_image(d);
        if (!target.id || sg_query_image_state(target) != SG_RESOURCESTATE_VALID) {
            if (target.id) sg_destroy_image(target);
            return false;
        }
    }
    const std::size_t need = px.size();
    sg_buffer stage = en.stage;
    std::size_t cap = en.stageCap;
    if (!stage.id || cap < need) {
        sg_buffer fresh{};
        const std::size_t newCap =
            convert ? need : std::min(std::size_t(h.samples) * std::size_t(h.samples) * 2, need + need / 2);
        sg_buffer_desc bd{};
        bd.size = newCap;
        bd.usage.vertex_buffer = false;
        bd.usage.staging_buffer = true;
        bd.usage.write_transient = true;
        bd.usage.copy_src = true;
        bd.label = "terrain-heights-staging";
        fresh = sg_make_buffer(&bd);
        if (!fresh.id || sg_query_buffer_state(fresh) != SG_RESOURCESTATE_VALID) {
            if (fresh.id) sg_destroy_buffer(fresh);
            if (convert) sg_destroy_image(target);
            return false;
        }
        if (en.stage.id) sg_destroy_buffer(en.stage);
        en.stage = stage = fresh;
        en.stageCap = cap = newCap;
    }
    sg_write_buffer_desc w{};
    w.src.data = {px.data(), px.size()};
    w.dst.buffer = stage;
    sg_write_buffer_transient(&w);
    sg_copy_buffer_to_image_desc c{};
    c.src.buffer = stage;
    c.src.bytes_per_row = (r.c1 - r.c0 + 1) * 2;
    c.src.bytes_per_slice = c.src.bytes_per_row * (r.r1 - r.r0 + 1);
    c.dst.image = target;
    c.dst.x = r.c0;
    c.dst.y = r.r0;
    c.size.width = r.c1 - r.c0 + 1;
    c.size.height = r.r1 - r.r0 + 1;
    c.size.num_slices = 1;
    sg_copy_buffer_to_image(&c);
    en.stagedFrame = frameTag;
    if (convert) {
        sg_view_desc vd{};
        vd.texture.image = target;
        vd.label = "terrain-heights";
        sg_view fresh = sg_make_view(&vd);
        if (targetView.id) sg_destroy_view(targetView);
        sg_destroy_image(en.tex.image);
        en.tex.image = target;
        en.tex.view = fresh;
        en.copyable = true;
        // The staging buffer of the whole texture is not kept: the later copies are rectangles.
        sg_destroy_buffer(en.stage);
        en.stage = {};
        en.stageCap = 0;
        en.stagedFrame = 0;
        ++uploads_;
    } else {
        ++rectUploads_;
    }
    return true;
}

// Makes the RG8 height texture of `en` from its CPU heights: the whole texture (2 bytes per sample, 33.5 MB for 4097 x 4097), or, when
// `rect` says which part a sculpt changed, only that part (copy_rect).
bool TerrainRenderer::upload(Entry& en, const View& v, const TerrainRect* rect) {
    const fa::TerrainHeights& h = *en.heights;
    if (rect && !rect->empty() && en.tex.image.id &&
        2 * std::int64_t(rect->c1 - rect->c0 + 1) * std::int64_t(rect->r1 - rect->r0 + 1) <=
            std::int64_t(h.samples) * h.samples &&
        copy_rect(en, v, *rect))
        return true;
    free_texture(en.tex);
    en.copyable = false;
    const int limit = std::max(1, sg_query_limits().max_image_size_2d);
    if (h.samples > limit) {
        en.failed = true;
        const int best = largest_samples_within(limit);
        FA_ERROR("render",
                 "A Terrain heightmap has {0} x {0} samples, but this GPU's largest texture is {1} x {1}, so the "
                 "terrain is not drawn. "
                 "Hint: resample the heightmap to {2} x {2} samples or fewer (a power of two plus one: {2} is the "
                 "largest this GPU "
                 "holds).",
                 h.samples, limit, best);
        return false;
    }
    TerrainRect whole;
    whole.c0 = whole.r0 = 0;
    whole.c1 = whole.r1 = h.samples - 1;
    const std::vector<std::uint8_t> px = pack_heights(h, whole);
    sg_image_desc d{};
    d.width = d.height = h.samples;
    d.pixel_format = SG_PIXELFORMAT_RG8;
    d.data.mip_levels[0] = {px.data(), px.size()};
    d.label = "terrain-heights";
    en.tex.path = "<terrain-heights>";
    en.tex.image = make_image(d);
    if (!en.tex.image.id || sg_query_image_state(en.tex.image) != SG_RESOURCESTATE_VALID) {
        if (en.tex.image.id) sg_destroy_image(en.tex.image);
        en.tex.image = {};
        en.failed = true;
        FA_ERROR("render",
                 "The height texture of a Terrain ({0} x {0}) could not be created (out of GPU memory?), so the "
                 "terrain is not drawn.",
                 h.samples);
        return false;
    }
    sg_view_desc vd{};
    vd.texture.image = en.tex.image;
    vd.label = "terrain-heights";
    en.tex.view = sg_make_view(&vd);
    en.tex.width = en.tex.height = h.samples;
    en.tex.format = SG_PIXELFORMAT_RG8;
    en.tex.bytes = px.size();
    ++uploads_;
    return true;
}

// The one-pixel array bound where a terrain has no layer pictures or no control array: a shader that declares an array texture needs an
// array image in every slot, even one it never reads.
TextureAsset* TerrainRenderer::dummy_array() {
    if (dummy_.image.id) return &dummy_;
    const std::uint8_t white[4] = {255, 255, 255, 255};
    sg_image_desc d{};
    d.type = SG_IMAGETYPE_ARRAY;
    d.width = d.height = 1;
    d.num_slices = 1;
    d.pixel_format = SG_PIXELFORMAT_RGBA8;
    d.data.mip_levels[0] = {white, sizeof white};
    d.label = "terrain-dummy-array";
    finish_array(dummy_, d, "terrain-dummy-array", sizeof white);
    return &dummy_;
}

// Brings the layer arrays and the control array of `en` up to date with the Terrain `t`: made again only when the pictures, their format,
// the splat maps or the holes changed (or one of the picture files was reloaded). A problem is said once and leaves the layer neutral.
void TerrainRenderer::update_layers(Entry& en, const View& v, Entity e, const Terrain3D& t,
                                    const std::vector<TerrainLayerInfo>& layers) {
    Assets& assets = *v.assets;
    const std::uint64_t generation = assets.reload_generation();
    std::set<std::string> files;
    for (const TerrainLayerInfo& l : layers)
        for (const std::string* p : {&l.albedo, &l.normal})
            if (!p->empty()) files.insert(fs::normalize(*p));
    const bool reloaded = en.reloadSeen != generation && !files.empty() && assets.reloaded_any_of(en.reloadSeen, files);
    en.reloadSeen = generation;
    std::string notes;
    for (int kind = 0; kind < 2; ++kind) {
        const bool albedo = kind == 0;
        const char* name = albedo ? "albedo" : "normal";
        std::uint64_t key = mix(0x517cc1b727220a95ull, std::uint64_t(albedo ? v.albedoFormat : SG_PIXELFORMAT_RGBA8));
        key = mix(key, layers.size());
        for (const TerrainLayerInfo& l : layers) key = hash_string(key, albedo ? l.albedo : l.normal);
        TextureAsset& arr = albedo ? en.albedoArr : en.normalArr;
        std::uint64_t& seenKey = albedo ? en.albedoKey : en.normalKey;
        unsigned& mask = albedo ? en.albedoMask : en.normalMask;
        if (seenKey == key && !reloaded) continue;
        seenKey = key;
        free_texture(arr);
        mask = 0;
        bool any = false;
        for (const TerrainLayerInfo& l : layers) any = any || !(albedo ? l.albedo : l.normal).empty();
        if (!any) continue;
        auto imgs = load_terrain_layer_images(t, name);
        if (!imgs) {
            notes += std::format(
                "Terrain on entity {}: {} Hint: {} The layers' {} textures are not used until this is fixed. ",
                e.bits(), imgs.error().message, imgs.error().hint, name);
            continue;
        }
        for (const std::string& problem : imgs->problems) notes += problem + " ";
        if (imgs->present == 0) continue;
        unsigned bits = 0;
        for (std::size_t i = 0; i < imgs->images.size(); ++i)
            if (!imgs->images[i].empty()) bits |= 1u << i;
        const sg_pixel_format fmt = albedo ? v.albedoFormat : SG_PIXELFORMAT_RGBA8;
        std::string why;
        if (make_picture_array(arr, albedo ? "terrain-albedo" : "terrain-normal", *imgs, fmt,
                               albedo && fmt != SG_PIXELFORMAT_RGBA8, why)) {
            arr.enc = fmt == SG_PIXELFORMAT_RGBA8 ? TexEncoding::Raw : TexEncoding::Srgb;
            mask = bits;
            ++layerBuilds_;
        } else {
            notes += std::format(
                "Terrain on entity {}: the layers' {} textures cannot be used: {}. Hint: use fewer layers or smaller "
                "textures. ",
                e.bits(), name, why);
        }
    }
    en.albedoFormat = v.albedoFormat;
    // The control array: the splat maps and the holes, kept in the TerrainHeights the commands paint into (their versions tell when).
    const fa::TerrainHeights& th = *en.heights;
    const int need = layers.size() > 1 ? int((layers.size() + 3) / 4) : 0;
    int maps = 0;
    for (int m = 0; m < std::min(need, kTerrainSplatMaps); ++m)
        if (th.splat[std::size_t(m)].valid()) maps = m + 1;
    const bool holes = !th.holes.empty();
    std::uint64_t ckey = mix(mix(0x2545f4914f6cdd1dull, std::uint64_t(maps)), std::uint64_t(holes));
    for (int m = 0; m < maps; ++m)
        ckey = mix(mix(ckey, th.splat[std::size_t(m)].version), std::uint64_t(th.splat[std::size_t(m)].size));
    ckey = mix(ckey, holes ? th.holesVersion : 0);
    ckey = mix(ckey, reinterpret_cast<std::uintptr_t>(en.heights.get()));
    if (en.controlKey != ckey) {
        en.controlKey = ckey;
        free_texture(en.controlArr);
        en.splatMaps = 0;
        en.holesOn = false;
        en.controlSide = 1;
        if (maps > 0 || holes) {
            std::string why;
            int side = 1;
            if (make_control_array(en.controlArr, th, maps, holes, side, why)) {
                en.splatMaps = maps;
                en.holesOn = holes;
                en.controlSide = holes ? side : 1;
                ++layerBuilds_;
            } else {
                notes += std::format(
                    "Terrain on entity {}: the splat maps and holes cannot be used: {}. Hint: use smaller splat maps. ",
                    e.bits(), why);
            }
        }
    }
    if (!th.planesProblem.empty()) notes += th.planesProblem + " ";
    if (!notes.empty() && notes != en.note) FA_ERROR("render", "{}", notes);
    en.note = notes;
}

TerrainRenderer::Entry* TerrainRenderer::prepare(const View& v, Entity e) {
    std::string problem;
    std::shared_ptr<fa::TerrainHeights> h = v.world->terrain().heights(*v.world, e, &problem);
    if (!h || !h->valid()) return nullptr;
    std::unique_ptr<Entry>& slot = entries_[e.bits()];
    if (!slot) slot = std::make_unique<Entry>();
    Entry& en = *slot;
    en.seen = v.serial;
    if (en.heights != h) {
        en.heights = h;
        en.failed = false;
        if (!upload(en, v, nullptr)) return nullptr;
        en.bounds.build(*h);
        en.seenVersion = h->version;
    } else if (h->version != en.seenVersion) {
        TerrainRect rect;
        const bool known = h->dirty_since(en.seenVersion, rect);
        en.seenVersion = h->version;
        if (!upload(en, v, known ? &rect : nullptr)) return nullptr;
        if (known)
            en.bounds.update(*h, rect);
        else
            en.bounds.build(*h);
    }
    return en.failed ? nullptr : &en;
}

int TerrainRenderer::gather(const View& v, std::deque<TerrainDraw>& draws, std::vector<MeshItem>& out) {
    World& world = *v.world;
    if (pruned_ != v.serial) {
        pruned_ = v.serial;
        // Terrains nobody asked for in the last two seconds or so (a hidden camera, a removed entity) give their texture back.
        for (auto it = entries_.begin(); it != entries_.end();) {
            if (it->second->seen + 120 < v.serial)
                it = entries_.erase(it);
            else
                ++it;
        }
        if (!entries_.empty()) world.terrain().prune(world);
    }
    struct Job {
        Entity entity;
        Entry* entry = nullptr;
        TerrainDraw* draw = nullptr;
        Mat4 model;
        TerrainGrid grid;
        TerrainLodRanges ranges;
        Vec3 camLocal;
        bool cull = false;
        TerrainSelection sel;
    };
    std::vector<Job> jobs;
    world.each<Terrain3D>([&](Entity e, Terrain3D& t) {
        if (!entity_active_in_scope(world, v.scopeRoot, e)) return;
        if (v.drawn && !v.drawn(e)) return;
        if (!(t.size.x > 0.0f) || !(t.size.y > 0.0f) || !std::isfinite(t.size.x) || !std::isfinite(t.size.y) ||
            !std::isfinite(t.heightScale) || !std::isfinite(t.heightOffset))
            return;  // terrain_problems reports it
        const Mat4 model = world.drawn_matrix(e);
        for (float f : model.m)
            if (!std::isfinite(f)) return;
        Entry* en = prepare(v, e);
        if (!en) return;
        Job j;
        j.entity = e;
        j.entry = en;
        j.model = model;
        j.grid = terrain_grid_of(t, en->heights->samples);
        j.ranges = TerrainLodRanges::make(j.grid, en->bounds.levels(), t.lodQuality);
        j.camLocal = model.inverse().transform_point(v.camera);
        j.cull = !t.castShadows;
        const std::vector<TerrainLayerInfo> layers = terrain_layers(t);
        update_layers(*en, v, e, t, layers);
        draws.emplace_back();
        TerrainDraw& d = draws.back();
        d.mr.castShadows = t.castShadows;
        d.mr.roughness = layers.empty() ? 0.9f : layers[0].roughness;
        d.mr.metallic = layers.empty() ? 0.0f : layers[0].metallic;
        d.mr.color = Color{0.5f, 0.5f, 0.5f, 1.0f};  // what a layer without an albedo picture shows
        std::memcpy(d.params, model.m, sizeof(model.m));
        const float cells = float(j.grid.cells());
        const float p4[4] = {j.camLocal.x, j.camLocal.y, j.camLocal.z, cells};
        const float p5[4] = {j.grid.cellX, j.grid.cellZ, j.grid.heightScale * (1.0f / kTerrainRawMax),
                             j.grid.heightOffset};
        // The albedo array is sRGB8 in a linear scene where the GPU decodes it (nothing to fix); else the shader converts it.
        const bool albedoSrgb = en->albedoFormat != SG_PIXELFORMAT_RGBA8;
        const int albedoFix = v.linear ? (albedoSrgb ? 0 : 1) : (albedoSrgb ? 2 : 0);
        const float p6[4] = {float(en->splatMaps), en->holesOn ? 1.0f : 0.0f,
                             en->albedoMask ? 1.0f + float(albedoFix) : 0.0f, en->normalMask ? 1.0f : 0.0f};
        const float p7[4] = {float(en->albedoMask), float(en->normalMask), float(en->controlSide),
                             float(layers.size())};
        std::memcpy(d.params[4], p4, sizeof p4);
        std::memcpy(d.params[5], p5, sizeof p5);
        std::memcpy(d.params[6], p6, sizeof p6);
        std::memcpy(d.params[7], p7, sizeof p7);
        for (std::size_t k = 0; k < layers.size(); ++k) {
            const float lp[4] = {1.0f / layers[k].tileSize, layers[k].roughness, layers[k].metallic,
                                 layers[k].normalScale};
            std::memcpy(d.params[8 + k], lp, sizeof lp);
        }
        TextureAsset* dummy = dummy_array();
        d.textures[0] = &en->tex;
        d.textures[1] = en->albedoArr.image.id ? &en->albedoArr : dummy;
        d.textures[2] = en->normalArr.image.id ? &en->normalArr : dummy;
        d.textures[3] = en->controlArr.image.id ? &en->controlArr : dummy;
        std::uint64_t hash = mix(0x9e3779b97f4a7c15ull, e.bits());
        for (const auto& row : d.params)
            for (float f : row) {
                std::uint32_t u;
                std::memcpy(&u, &f, sizeof u);
                hash = mix(hash, u);
            }
        for (const TextureAsset* tex : d.textures) hash = mix(hash, tex->gpu_view().id);
        d.hash = std::size_t(hash);
        j.draw = &d;
        jobs.push_back(std::move(j));
    });
    if (jobs.empty()) return 0;
    MaterialAsset* mat = material();
    MeshAsset* mesh = mat ? patch(false) : nullptr;
    if (!mesh) return 0;
    // The selection of every terrain, as jobs: it walks the quadtree of the terrain and tests each box against the frustum.
    rjobs::run("render.terrain_select", rjobs::split(jobs.size(), 1, 2), [&](const jobs::Chunk& c) {
        for (std::size_t i = c.begin; i < c.end; ++i) {
            Job& j = jobs[i];
            std::function<bool(Vec3, Vec3)> visible;
            if (j.cull)  // a terrain that casts no shadow needs only the nodes in view; one that does keeps the others for the shadow maps
                visible = [&](Vec3 lo, Vec3 hi) { return box_in_frustum(v.viewProj, v.z01, lo, hi, j.model); };
            select_terrain_nodes(j.grid, j.entry->bounds, j.ranges, j.camLocal, visible, j.sel);
        }
    });
    for (Job& j : jobs) {
        out.reserve(out.size() + j.sel.nodes.size());
        for (const TerrainNode& n : j.sel.nodes) {
            MeshItem mi;
            mi.mesh = j.entry->holesOn ? patch(true) : mesh;
            mi.model = j.model;
            mi.mr = &j.draw->mr;
            mi.entity = j.entity;
            mi.material = mat;
            mi.paramsHash = j.draw->hash;
            mi.keyed =
                true;  // after every item of the scene, in the order gathered: a terrain is never what the comparator is asked to rank
            mi.sortKey = kTerrainSortKey;
            mi.terrain = j.draw;
            terrain_node_box(j.grid, n, mi.bmin, mi.bmax);
            mi.terrainNode = {float(n.first_column()),
                              float(n.first_row()),
                              float(n.step()),
                              float(n.level),
                              j.ranges.morph_start(int(n.level)),
                              j.ranges.morph_end(int(n.level)),
                              0.0f,
                              0.0f};
            mi.dist = length(j.model.transform_point((mi.bmin + mi.bmax) * 0.5f) - v.camera);
            out.push_back(std::move(mi));
        }
    }
    return int(jobs.size());
}

}  // namespace fa::render
