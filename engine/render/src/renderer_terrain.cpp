#include "renderer_terrain.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <format>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/jobs.h"
#include "fa/core/log.h"
#include "fa/scene/world.h"
#include "render_jobs.h"
#include "render_scene.h"
#include "shader_cache.h"
#include "gpu/sokol_shaders.h"
#include "shaders/terrain.glsl.h"

namespace fa::render {

namespace {

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

void free_texture(gpu::Device& device, TextureAsset& t) {
    if (t.view.id) device.destroy_view(t.view);
    if (t.image.id) device.destroy_image(t.image);
    t.view = {};
    t.image = {};
    t.bytes = 0;
}

// The image `d` makes, or none (the half-made one destroyed) when the GPU rejects it.
gpu::Image make_valid_image(gpu::Device& device, const gpu::ImageDesc& d) {
    gpu::Image image = device.make_image(d);
    if (image.id && device.state(image) == gpu::ResourceState::Valid) return image;
    if (image.id) device.destroy_image(image);
    return {};
}

// A staging buffer of `size` bytes (rewritten every frame with write_buffer, the source of copies), or none when the GPU rejects it.
gpu::Buffer make_staging_buffer(gpu::Device& device, std::size_t size, const char* label) {
    gpu::BufferDesc bd;
    bd.size = size;
    bd.usage.stagingBuffer = true;
    bd.usage.writeTransient = true;
    bd.usage.copySrc = true;
    bd.label = label;
    gpu::Buffer buffer = device.make_buffer(bd);
    if (buffer.id && device.state(buffer) == gpu::ResourceState::Valid) return buffer;
    if (buffer.id) device.destroy_buffer(buffer);
    return {};
}

gpu::View make_texture_view(gpu::Device& device, gpu::Image image, const char* label) {
    gpu::ViewDesc vd;
    vd.texture.image = image;
    vd.label = label;
    return device.make_view(vd);
}

// Wraps `d` (an array image) in a TextureAsset; false (nothing kept) when the GPU rejects it.
bool finish_array(gpu::Device& device, TextureAsset& out, const gpu::ImageDesc& d, const char* label,
                  std::size_t bytes) {
    const gpu::Image image = make_valid_image(device, d);
    if (!image.id) return false;
    out.image = image;
    out.view = make_texture_view(device, image, label);
    out.path = label;
    out.width = d.width;
    out.height = d.height;
    out.format = d.pixelFormat;
    out.bytes = bytes;
    return true;
}

// The largest 2^k + 1 that is at most `limit` (the sizes a heightmap can have), at least 33.
int largest_samples_within(int limit) {
    int n = 33;
    while (n * 2 - 1 <= limit) n = n * 2 - 1;
    return n;
}

// What an array texture of this size would break on this GPU, said once with the fix: the number of layers or the side. False (`why`
// untouched) when it fits. `what` is the thing named in the message ("the layers' albedo textures"), `fix` what to change to fit.
bool array_over_limit(const gpu::Device& device, int slices, int width, int height, const std::string& what,
                      const std::string& fix, Error& why) {
    const gpu::Limits lim = device.limits();
    const int sideMax = lim.maxImageSizeArray, layersMax = lim.maxImageArrayLayers;
    if (slices > layersMax) {
        why = make_error(std::format("{} need {} array layers, but this GPU's array textures have at most {}", what,
                                     slices, layersMax),
                         std::format("Use at most {} layers.", layersMax));
        return true;
    }
    if (width > sideMax || height > sideMax) {
        why = make_error(std::format("{} are {} x {} pixels, but this GPU's largest array texture is {} x {} pixels",
                                     what, width, height, sideMax, sideMax),
                         std::format("{} {} x {} pixels or less.", fix, sideMax, sideMax));
        return true;
    }
    return false;
}

// The array image could not be made although it is within the limits above: the GPU is out of memory, or the driver's real limit is
// lower than it says. Names the size and the GPU's largest, so the author sees whether the size is the cause.
Error array_failed(const gpu::Device& device, const std::string& what, int slices, int width, int height,
                   std::size_t bytes) {
    const gpu::Limits lim = device.limits();
    return make_error(
        std::format("the GPU could not make the array texture of {} ({} x {} pixels, {} layers, {} MB; this GPU's "
                    "largest array texture is {} x {} pixels): out of graphics memory?",
                    what, width, height, slices, bytes / (1024 * 1024), lim.maxImageSizeArray, lim.maxImageSizeArray),
        "Use smaller textures or fewer layers (the memory of a terrain is listed in docs/BIG_WORLDS_TERRAIN.md, "
        "\"Cost\").");
}

// The CPU half of an albedo or normal array, run by a job: the mip chain of every picture, laid out as the array's levels (a layer
// without a picture stays zeros). The pictures are given up as they are packed (the chain of the last one is all that exists next to
// the array).
void pack_picture_levels(TerrainLayerImages& li, bool srgbMips, TerrainLayerBuild& out) {
    const int slices = int(li.images.size());
    out.width = li.width;
    out.height = li.height;
    out.slices = slices;
    out.present = li.present;
    for (int s = 0; s < slices; ++s) {
        if (li.images[std::size_t(s)].empty()) continue;
        out.mask |= 1u << s;
        std::vector<Image> chain = mip_chain(std::move(li.images[std::size_t(s)]), srgbMips);
        li.images[std::size_t(s)] = Image();
        if (out.levels.empty()) {
            out.levels.resize(chain.size());
            for (std::size_t m = 0; m < chain.size(); ++m)
                out.levels[m].assign(chain[m].rgba.size() * std::size_t(slices), 0);
        }
        for (std::size_t m = 0; m < chain.size() && m < out.levels.size(); ++m)
            std::memcpy(out.levels[m].data() + chain[m].rgba.size() * std::size_t(s), chain[m].rgba.data(),
                        chain[m].rgba.size());
    }
}

// The GPU half: one RGBA8 array from the packed levels of `b`. False, with `why`, when it does not fit this GPU or cannot be made.
bool make_picture_array(gpu::Device& device, TextureAsset& out, const char* label, const char* kind,
                        const TerrainLayerBuild& b, gpu::PixelFormat format, Error& why) {
    if (b.levels.empty() || b.levels.size() > std::size_t(gpu::kMaxMipmaps)) {
        why = make_error("there is no picture to make the array from", "Check the paths of the layers' pictures.");
        return false;
    }
    if (array_over_limit(device, b.slices, b.width, b.height, std::format("the layers' {} textures", kind),
                         "Resize the pictures (they all need the same size) to", why))
        return false;
    gpu::ImageDesc d;
    d.type = gpu::ImageType::Array;
    d.width = b.width;
    d.height = b.height;
    d.numSlices = b.slices;
    d.numMipmaps = int(b.levels.size());
    d.pixelFormat = format;
    d.label = label;
    std::size_t bytes = 0;
    for (std::size_t m = 0; m < b.levels.size(); ++m) {
        d.data.mipLevels[m] = gpu::Range{b.levels[m].data(), b.levels[m].size()};
        bytes += b.levels[m].size();
    }
    if (!finish_array(device, out, d, label, bytes)) {
        why = array_failed(device, std::format("the layers' {} textures", kind), b.slices, b.width, b.height, bytes);
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

// The RGBA8 pixels of the rectangle `r` (inclusive, in the pixels of the array) of splat map `m` as slice `m` of a control array `side` x
// `side` holds it, written at `dst` (w * h * 4 bytes). A map the terrain does not have is zeros; one of another size than `side` is
// resampled bilinearly.
void pack_splat_rect(const TerrainSplat& map, int side, const TerrainRect& r, std::uint8_t* dst) {
    const int w = r.c1 - r.c0 + 1, ht = r.r1 - r.r0 + 1;
    if (!map.valid()) {
        std::memset(dst, 0, std::size_t(w) * std::size_t(ht) * 4);
        return;
    }
    if (map.size == side) {
        for (int y = 0; y < ht; ++y)
            std::memcpy(dst + std::size_t(y) * std::size_t(w) * 4,
                        map.rgba.data() + (std::size_t(r.r0 + y) * std::size_t(side) + std::size_t(r.c0)) * 4,
                        std::size_t(w) * 4);
        return;
    }
    for (int y = 0; y < ht; ++y)
        for (int x = 0; x < w; ++x) {
            const float sx = (float(r.c0 + x) + 0.5f) * float(map.size) / float(side) - 0.5f;
            const float sy = (float(r.r0 + y) + 0.5f) * float(map.size) / float(side) - 0.5f;
            for (int c = 0; c < 4; ++c)
                dst[(std::size_t(y) * std::size_t(w) + std::size_t(x)) * 4 + std::size_t(c)] = std::uint8_t(
                    std::clamp(bilinear_channel(map.rgba, map.size, map.size, sx, sy, c) + 0.5f, 0.0f, 255.0f));
        }
}

// The control array: the splat maps (RGBA, one slice each; `maps` slices, the ones a terrain does not have are zeros), every slice `side` x
// `side` (the size of the biggest map; a smaller one is resampled bilinearly). The holes are NOT in it (make_holes_texture), so it is
// at most 2 x 64 MB (4096 x 4096 maps). Made with its data, immutable; the first repaint makes it again as one that takes copies.
bool make_control_array(gpu::Device& device, TextureAsset& out, const TerrainHeights& h, int maps, int side,
                        Error& why) {
    if (array_over_limit(device, maps, side, side, "the splat maps", "Make the splat maps", why)) return false;
    const std::size_t slice = std::size_t(side) * std::size_t(side) * 4;
    std::vector<std::uint8_t> data(slice * std::size_t(maps), 0);
    TerrainRect whole;
    whole.c0 = whole.r0 = 0;
    whole.c1 = whole.r1 = side - 1;
    for (int m = 0; m < maps; ++m)
        pack_splat_rect(h.splat[std::size_t(m)], side, whole, data.data() + slice * std::size_t(m));
    gpu::ImageDesc d;
    d.type = gpu::ImageType::Array;
    d.width = d.height = side;
    d.numSlices = maps;
    d.pixelFormat = gpu::PixelFormat::Rgba8;
    d.data.mipLevels[0] = gpu::Range{data.data(), data.size()};
    d.label = "terrain-control";
    if (!finish_array(device, out, d, "terrain-control", data.size())) {
        why = array_failed(device, "the splat maps", maps, side, side, data.size());
        return false;
    }
    return true;
}

// The holes: an R8 texture of one pixel per cell (255 = hole), the one thing the vertex stage reads besides the heights. cells x cells
// bytes (16.8 MB for a 4097 x 4097 terrain), made again whenever the mask changed.
bool make_holes_texture(gpu::Device& device, TextureAsset& out, const TerrainHeights& h, Error& why) {
    const int cells = std::max(1, h.samples - 1);
    const int limit = std::max(1, device.limits().maxImageSize2d);
    if (cells > limit) {
        why = make_error(
            std::format("the holes of a {0} x {0} cell terrain need a {0} x {0} texture, but this GPU's largest "
                        "texture is {1} x {1}",
                        cells, limit),
            std::format("Use a heightmap of {} x {} samples or fewer.", largest_samples_within(limit),
                        largest_samples_within(limit)));
        return false;
    }
    std::vector<std::uint8_t> px(std::size_t(cells) * std::size_t(cells));
    for (std::size_t i = 0; i < px.size(); ++i) px[i] = i < h.holes.size() && h.holes[i] ? 255 : 0;
    gpu::ImageDesc d;
    d.width = d.height = cells;
    d.pixelFormat = gpu::PixelFormat::R8;
    d.data.mipLevels[0] = gpu::Range{px.data(), px.size()};
    d.label = "terrain-holes";
    const gpu::Image image = make_valid_image(device, d);
    if (!image.id) {
        why = make_error(
            std::format(
                "the GPU could not make the {0} x {0} holes texture ({1} MB; this GPU's largest texture is {2} x "
                "{2}): out of graphics memory?",
                cells, px.size() / (1024 * 1024), limit),
            "Use a smaller heightmap, or remove the holes.");
        return false;
    }
    out.image = image;
    out.view = make_texture_view(device, image, "terrain-holes");
    out.path = "<terrain-holes>";
    out.width = out.height = cells;
    out.format = gpu::PixelFormat::R8;
    out.bytes = px.size();
    return true;
}

std::uint64_t hash_string(std::uint64_t h, const std::string& s) {
    for (unsigned char c : s) h = mix(h, c);
    return mix(h, s.size());
}

}  // namespace

TerrainRenderer::Entry::~Entry() {
    if (!device) return;  // nothing was made
    free_texture(*device, tex);
    free_texture(*device, albedoArr);
    free_texture(*device, normalArr);
    free_texture(*device, controlArr);
    free_texture(*device, holesTex);
    if (stage.id) device->destroy_buffer(stage);
    if (controlStage.id) device->destroy_buffer(controlStage);
    if (holesStage.id) device->destroy_buffer(holesStage);
}

void TerrainRenderer::destroy() {
    entries_.clear();
    for (std::unique_ptr<MeshAsset>* slot : {&patch_, &splitPatch_}) {
        if (!*slot) continue;
        for (SubMesh& p : (*slot)->parts) {
            if (p.vb.id) device_->destroy_buffer(p.vb);
            if (p.ib.id) device_->destroy_buffer(p.ib);
        }
        slot->reset();
    }
    material_.reset();
    if (device_) {
        free_texture(*device_, dummy_);
        free_texture(*device_, dummyHoles_);
    }
    for (gpu::Shader& s : shaders_) {
        if (s.id) device_->destroy_shader(s);
        s = {};
    }
    matState_ = 0;
    device_ = nullptr;
}

std::size_t TerrainRenderer::bytes() const {
    std::size_t total = 0;
    for (const auto& [key, en] : entries_)
        total += en->tex.bytes + en->albedoArr.bytes + en->normalArr.bytes + en->controlArr.bytes + en->holesTex.bytes +
                 en->stageCap + en->controlStageCap + en->holesStageCap;
    return total + dummy_.bytes + dummyHoles_.bytes;
}

bool TerrainRenderer::loading() const {
    for (const auto& [bits, en] : entries_)
        for (const Entry::LayerJob& j : en->layerJob)
            if (j.handle.valid()) return true;  // running, or done and not adopted yet
    return false;
}

void TerrainRenderer::wait_loaded() {
    for (auto& [bits, en] : entries_)
        for (Entry::LayerJob& j : en->layerJob)
            if (j.handle.valid()) (void)jobs::wait(j.handle);
}

// The patch: 33 x 33 vertices at the integers (gx, 0, gz), 32 x 32 cells of two triangles each on the diagonal (0, 0) - (1, 1) (the
// diagonal of the physics heightfield and of terrain_vertex_raw), counter-clockwise seen from +y. Shared: one vertex serves the cells around
// it. The SPLIT patch (a terrain with holes) gives every cell its own four vertices, whose uv is the cell's lower-left corner (0..31):
// vertex() of shaders/terrain.glsl collapses the four vertices of a cell that is a hole, which no shared vertex can do.
MeshAsset* TerrainRenderer::patch(gpu::Device& device, bool split) {
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
    gpu::BufferDesc vb;
    vb.usage.vertexBuffer = true;
    vb.data = {v.data(), v.size() * sizeof(MeshVertex)};
    vb.label = split ? "terrain-patch-split" : "terrain-patch";
    sm.vb = device.make_buffer(vb);
    gpu::BufferDesc ib;
    ib.usage.indexBuffer = true;
    ib.data = {idx.data(), idx.size() * sizeof(std::uint32_t)};
    ib.label = vb.label;
    sm.ib = device.make_buffer(ib);
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
// through a nearest sampler, the albedo and normal arrays of the layers, the control array of the splat maps; the holes texture rides in the
// vertex copy of the last slot). A hole is cut in the
// geometry (the split patch, vertex() of shaders/terrain.glsl), so no program discards. null when the GPU rejects the shaders (said once).
MaterialAsset* TerrainRenderer::material(gpu::Device& device) {
    if (matState_ != 0) return matState_ > 0 ? material_.get() : nullptr;
    const gpu::ShaderDesc descs[3] = {gpu::generated_shader_desc(terrain_terrain_shader_desc),
                                      gpu::generated_shader_desc(terrain_shadow_shader_desc),
                                      gpu::generated_shader_desc(terrain_prepass_shader_desc)};
    const char* labels[3] = {"terrain_terrain", "terrain_shadow", "terrain_prepass"};
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
    // "control" is the splat array for the fragment stage; the vertex stage's copy of that slot gets the holes texture instead
    // (TerrainDraw::holes, MaterialInputs::vsTextures).
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
    if (!v.gpu || !en.tex.image.id || en.tex.width != h.samples ||
        v.gpu->commands().pass_state() != gpu::PassState::None)
        return false;
    const std::uint64_t frameTag = v.gpu->frame() + 1;
    if (en.stagedFrame == frameTag) return false;
    gpu::Device& device = v.gpu->device();
    TerrainRect whole;
    whole.c0 = whole.r0 = 0;
    whole.c1 = whole.r1 = h.samples - 1;
    const bool convert = !en.copyable;
    const TerrainRect& r = convert ? whole : rect;
    const std::vector<std::uint8_t> px = pack_heights(h, r);
    v.gpu->begin_transient_writes();  // before the first write of the frame (render_internal.h)
    gpu::Image target = en.tex.image;
    const gpu::View targetView = en.tex.view;
    if (convert) {
        gpu::ImageDesc d;
        d.width = d.height = h.samples;
        d.pixelFormat = gpu::PixelFormat::Rg8;
        d.usage.copyDst = true;
        d.label = "terrain-heights";
        target = make_valid_image(device, d);
        if (!target.id) return false;
    }
    const std::size_t need = px.size();
    gpu::Buffer stage = en.stage;
    if (!stage.id || en.stageCap < need) {
        const std::size_t newCap =
            convert ? need : std::min(std::size_t(h.samples) * std::size_t(h.samples) * 2, need + need / 2);
        const gpu::Buffer fresh = make_staging_buffer(device, newCap, "terrain-heights-staging");
        if (!fresh.id) {
            if (convert) device.destroy_image(target);
            return false;
        }
        if (en.stage.id) device.destroy_buffer(en.stage);
        stage = fresh;
        en.stage = fresh;
        en.stageCap = newCap;
    }
    gpu::CommandList& list = v.gpu->commands();
    gpu::BufferWrite w;
    w.data = gpu::Range{px.data(), px.size()};
    w.buffer = stage;
    list.write_buffer(w);
    gpu::BufferImageCopy c;
    c.src = stage;
    c.bytesPerRow = (r.c1 - r.c0 + 1) * 2;
    c.bytesPerSlice = c.bytesPerRow * (r.r1 - r.r0 + 1);
    c.dst.image = target;
    c.dst.x = r.c0;
    c.dst.y = r.r0;
    c.size.width = r.c1 - r.c0 + 1;
    c.size.height = r.r1 - r.r0 + 1;
    c.size.numSlices = 1;
    list.copy_buffer_to_image(c);
    en.stagedFrame = frameTag;
    if (convert) {
        const gpu::View fresh = make_texture_view(device, target, "terrain-heights");
        if (targetView.id) device.destroy_view(targetView);
        device.destroy_image(en.tex.image);
        en.tex.image = target;
        en.tex.view = fresh;
        en.copyable = true;
        // The staging buffer of the whole texture is not kept: the later copies are rectangles.
        device.destroy_buffer(en.stage);
        en.stage = {};
        en.stageCap = 0;
        en.stagedFrame = 0;
        ++uploads_;
    } else {
        ++rectUploads_;
    }
    return true;
}

// The holes texture takes the cells of `rect` (cell coordinates, inclusive) from the CPU mask: one byte per cell through a staging buffer, as
// copy_rect does for the heights. The first one makes the texture one that takes copies (the whole of it once). False (nothing changed)
// where a copy cannot run (inside a pass, a second write in the same frame, no Gpu, the GPU said no): the caller makes it again whole.
bool TerrainRenderer::copy_holes(Entry& en, const View& v, const TerrainRect& rect) {
    const fa::TerrainHeights& h = *en.heights;
    const int cells = std::max(1, h.samples - 1);
    if (!v.gpu || !en.holesTex.image.id || en.holesTex.width != cells ||
        v.gpu->commands().pass_state() != gpu::PassState::None)
        return false;
    const std::uint64_t frameTag = v.gpu->frame() + 1;
    if (en.holesStagedFrame == frameTag) return false;
    if (h.holes.size() != std::size_t(cells) * std::size_t(cells)) return false;
    gpu::Device& device = v.gpu->device();
    TerrainRect whole;
    whole.c0 = whole.r0 = 0;
    whole.c1 = whole.r1 = cells - 1;
    const bool convert = !en.holesCopyable;
    const TerrainRect& r = convert ? whole : rect;
    const int w = r.c1 - r.c0 + 1, rows = r.r1 - r.r0 + 1;
    std::vector<std::uint8_t> px(std::size_t(w) * std::size_t(rows));
    for (int y = 0; y < rows; ++y)
        for (int x = 0; x < w; ++x)
            px[std::size_t(y) * std::size_t(w) + std::size_t(x)] =
                h.holes[std::size_t(r.r0 + y) * std::size_t(cells) + std::size_t(r.c0 + x)] ? 255 : 0;
    v.gpu->begin_transient_writes();  // before the first write of the frame (render_internal.h)
    gpu::Image target = en.holesTex.image;
    if (convert) {
        gpu::ImageDesc d;
        d.width = d.height = cells;
        d.pixelFormat = gpu::PixelFormat::R8;
        d.usage.copyDst = true;
        d.label = "terrain-holes";
        target = make_valid_image(device, d);
        if (!target.id) return false;
    }
    const std::size_t need = px.size();
    if (!en.holesStage.id || en.holesStageCap < need) {
        const std::size_t newCap = convert ? need : std::min(std::size_t(cells) * std::size_t(cells), need + need / 2);
        const gpu::Buffer fresh = make_staging_buffer(device, newCap, "terrain-holes-staging");
        if (!fresh.id) {
            if (convert) device.destroy_image(target);
            return false;
        }
        if (en.holesStage.id) device.destroy_buffer(en.holesStage);
        en.holesStage = fresh;
        en.holesStageCap = newCap;
    }
    gpu::CommandList& list = v.gpu->commands();
    gpu::BufferWrite wd;
    wd.data = gpu::Range{px.data(), px.size()};
    wd.buffer = en.holesStage;
    list.write_buffer(wd);
    gpu::BufferImageCopy c;
    c.src = en.holesStage;
    c.bytesPerRow = w;
    c.bytesPerSlice = w * rows;
    c.dst.image = target;
    c.dst.x = r.c0;
    c.dst.y = r.r0;
    c.size.width = w;
    c.size.height = rows;
    c.size.numSlices = 1;
    list.copy_buffer_to_image(c);
    en.holesStagedFrame = frameTag;
    if (convert) {
        const gpu::View fresh = make_texture_view(device, target, "terrain-holes");
        if (en.holesTex.view.id) device.destroy_view(en.holesTex.view);
        device.destroy_image(en.holesTex.image);
        en.holesTex.image = target;
        en.holesTex.view = fresh;
        en.holesCopyable = true;
        // The staging buffer of the whole mask is not kept: the later copies are rectangles.
        device.destroy_buffer(en.holesStage);
        en.holesStage = {};
        en.holesStageCap = 0;
        en.holesStagedFrame = 0;
        ++holesUploads_;
    } else {
        ++holesRects_;
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
    gpu::Device& device = *device_;
    free_texture(device, en.tex);
    en.copyable = false;
    const int limit = std::max(1, device.limits().maxImageSize2d);
    if (h.samples > limit) {
        en.failed = true;
        const int best = largest_samples_within(limit);
        FA_ERROR(
            "render",
            "A Terrain heightmap has {0} x {0} samples, but this GPU's largest texture is {1} x {1}, so the terrain is "
            "not "
            "drawn. Hint: resample the heightmap to {2} x {2} samples or fewer (2^n + 1: {2} is the largest this GPU "
            "holds).",
            h.samples, limit, best);
        return false;
    }
    TerrainRect whole;
    whole.c0 = whole.r0 = 0;
    whole.c1 = whole.r1 = h.samples - 1;
    const std::vector<std::uint8_t> px = pack_heights(h, whole);
    gpu::ImageDesc d;
    d.width = d.height = h.samples;
    d.pixelFormat = gpu::PixelFormat::Rg8;
    d.data.mipLevels[0] = gpu::Range{px.data(), px.size()};
    d.label = "terrain-heights";
    en.tex.path = "<terrain-heights>";
    const gpu::Image image = make_valid_image(device, d);
    en.tex.image = image;
    if (!image.id) {
        en.failed = true;
        FA_ERROR(
            "render",
            "The height texture of a Terrain ({0} x {0}, {1} MB; this GPU's largest texture is {2} x {2}) could not be "
            "created, so the terrain is not drawn. Hint: the GPU is out of graphics memory (close other programs, or "
            "resample the heightmap to {3} x {3} samples or fewer).",
            h.samples, px.size() / (1024 * 1024), limit, std::max(33, h.samples / 2 + 1));
        return false;
    }
    en.tex.view = make_texture_view(device, image, "terrain-heights");
    en.tex.width = en.tex.height = h.samples;
    en.tex.format = gpu::PixelFormat::Rg8;
    en.tex.bytes = px.size();
    ++uploads_;
    return true;
}

// The one-pixel array bound where a terrain has no layer pictures or no control array: a shader that declares an array texture needs an
// array image in every slot, even one it never reads.
TextureAsset* TerrainRenderer::dummy_array(gpu::Device& device) {
    if (dummy_.image.id) return &dummy_;
    const std::uint8_t white[4] = {255, 255, 255, 255};
    gpu::ImageDesc d;
    d.type = gpu::ImageType::Array;
    d.width = d.height = 1;
    d.numSlices = 1;
    d.pixelFormat = gpu::PixelFormat::Rgba8;
    d.data.mipLevels[0] = gpu::Range{white, sizeof white};
    d.label = "terrain-dummy-array";
    finish_array(device, dummy_, d, "terrain-dummy-array", sizeof white);
    return &dummy_;
}

// The 1 x 1 holes texture of a terrain without holes: the vertex stage declares the texture, so something has to be bound.
// `fallback` (a 2D texture of the terrain) is returned when the 1 x 1 one cannot be made.
TextureAsset* TerrainRenderer::dummy_holes(gpu::Device& device, TextureAsset* fallback) {
    if (dummyHoles_.image.id) return &dummyHoles_;
    const std::uint8_t zero = 0;
    gpu::ImageDesc d;
    d.width = d.height = 1;
    d.pixelFormat = gpu::PixelFormat::R8;
    d.data.mipLevels[0] = gpu::Range{&zero, 1};
    d.label = "terrain-dummy-holes";
    const gpu::Image image = device.make_image(d);
    // Not made (the GPU is out of memory): the terrain's own height texture is also a 2D texture the vertex stage can sample, and
    // the draw does not read the holes of a terrain without any, so the slot is never bound to nothing.
    if (!image.id) return fallback;
    dummyHoles_.image = image;
    dummyHoles_.view = make_texture_view(device, image, "terrain-dummy-holes");
    dummyHoles_.path = "<terrain-dummy-holes>";
    dummyHoles_.width = dummyHoles_.height = 1;
    dummyHoles_.format = gpu::PixelFormat::R8;
    dummyHoles_.bytes = 1;
    return &dummyHoles_;
}

// Brings the layer arrays, the control array and the holes texture of `en` up to date with the Terrain `t`. The albedo and normal arrays
// are decoded by jobs and adopted here once they are done (update_pictures), the control array follows the splat maps by rectangle
// (update_control), the holes texture is made again when the mask changed. A problem is said once and leaves the layer neutral.
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
    update_pictures(en, v, t, layers, reloaded, e);
    en.albedoFormat = v.albedoFormat;
    update_control(en, v, layers, e);
    const fa::TerrainHeights& th = *en.heights;
    const int cells = std::max(1, th.samples - 1);
    const bool holes = !th.holes.empty() && th.holes.size() == std::size_t(cells) * std::size_t(cells);
    // The texture is made again whole when its shape changed (the heights object, holes or none); a paint of the mask sends only the
    // cells it changed (copy_holes), and a holesVersion bumped with no rectangle makes the texture again.
    const std::uint64_t hkey =
        holes ? mix(0x7f4a7c159e3779b9ull, reinterpret_cast<std::uintptr_t>(en.heights.get())) : 0;
    auto rebuild = [&] {
        free_texture(*device_, en.holesTex);
        if (en.holesStage.id) device_->destroy_buffer(en.holesStage);
        en.holesStage = {};
        en.holesStageCap = 0;
        en.holesCopyable = false;
        en.holesOn = false;
        en.holesNote.clear();
        en.holesSeen = th.holesVersion;
        if (holes) {
            Error why;
            if (make_holes_texture(*device_, en.holesTex, th, why)) {
                en.holesOn = true;
                ++holesUploads_;
            } else {
                en.holesNote = std::format("Terrain on entity {}: the holes cannot be used: {}. Hint: {} ", e.bits(),
                                           why.message, why.hint);
            }
        }
    };
    if (en.holesKey != hkey) {
        en.holesKey = hkey;
        rebuild();
    } else if (holes && th.holesVersion != en.holesSeen) {
        TerrainRect rect;
        const bool known = en.holesOn && th.holes_dirty_since(en.holesSeen, rect);
        if (known && rect.empty()) {
            en.holesSeen = th.holesVersion;
        } else if (known &&
                   2 * std::int64_t(rect.c1 - rect.c0 + 1) * std::int64_t(rect.r1 - rect.r0 + 1) <=
                       std::int64_t(cells) * cells &&
                   copy_holes(en, v, rect)) {
            en.holesSeen = th.holesVersion;
        } else {
            rebuild();
        }
    }
    std::string notes = en.layerNote[0] + en.layerNote[1] + en.controlNote + en.holesNote;
    if (!th.planesProblem.empty()) notes += th.planesProblem + " ";
    if (!notes.empty() && notes != en.note) FA_ERROR("render", "{}", notes);
    en.note = notes;
}

// The albedo and the normal array of `en`. A job (render.terrain_layers) reads the pictures, builds their mip chains and packs the whole
// array; this thread adopts it with one image creation when the job is done, so a 4096 x 4096 x 8 layer set no longer stalls the frame
// for the decode and the mips. While a job runs, the array the terrain had stays bound when the same layers are being reloaded, and
// the neutral one (one grey) is bound when the layers changed.
void TerrainRenderer::update_pictures(Entry& en, const View& v, const Terrain3D& t,
                                      const std::vector<TerrainLayerInfo>& layers, bool reloaded, Entity e) {
    for (int kind = 0; kind < 2; ++kind) {
        const bool albedo = kind == 0;
        const char* name = albedo ? "albedo" : "normal";
        const gpu::PixelFormat fmt = albedo ? v.albedoFormat : gpu::PixelFormat::Rgba8;
        std::uint64_t key = mix(0x517cc1b727220a95ull, std::uint64_t(fmt));
        key = mix(key, layers.size());
        for (const TerrainLayerInfo& l : layers) key = hash_string(key, albedo ? l.albedo : l.normal);
        TextureAsset& arr = albedo ? en.albedoArr : en.normalArr;
        std::uint64_t& loadedKey = albedo ? en.albedoKey : en.normalKey;
        unsigned& mask = albedo ? en.albedoMask : en.normalMask;
        Entry::LayerJob& job = en.layerJob[kind];
        bool any = false;
        for (const TerrainLayerInfo& l : layers) any = any || !(albedo ? l.albedo : l.normal).empty();
        if (reloaded) {
            en.layerPending[kind] = true;
            if (job.handle.valid()) job.stale = true;  // it may have read the old file
        }
        if (!any) {  // nothing to decode: the array goes, and a job still running for the old layers is dropped when it ends
            free_texture(*device_, arr);
            mask = 0;
            loadedKey = key;
            en.layerNote[kind].clear();
            en.layerPending[kind] = false;
            if (job.handle.valid()) job.stale = true;
        }
        // What a finished job made: this layer set's array, or nothing (a newer set, a reload or the layers were removed since).
        auto adopt = [&] {
            std::shared_ptr<TerrainLayerBuild> b = std::move(job.build);
            const bool current = any && !job.stale && job.key == key && b != nullptr;
            job.handle = {};
            job.build.reset();
            job.stale = false;
            if (!b || !b->ran) {  // skipped (the job system was shutting down): not read again by itself
                if (current) {
                    loadedKey = key;
                    en.layerNote[kind] =
                        std::format("Terrain on entity {}: the layers' {} textures were not read (the job was "
                                    "cancelled). ",
                                    e.bits(), name);
                }
                return;
            }
            if (!current) return;
            free_texture(*device_, arr);
            mask = 0;
            loadedKey = key;
            std::string note;
            if (!b->error.empty()) {
                note = std::format(
                    "Terrain on entity {}: {} Hint: {} The layers' {} textures are not used until this is fixed. ",
                    e.bits(), b->error, b->hint, name);
            } else {
                for (const std::string& problem : b->problems) note += problem + " ";
                if (b->present > 0) {
                    Error why;
                    if (make_picture_array(*device_, arr, albedo ? "terrain-albedo" : "terrain-normal", name, *b, fmt,
                                           why)) {
                        arr.enc = fmt == gpu::PixelFormat::Rgba8 ? TexEncoding::Raw : TexEncoding::Srgb;
                        mask = b->mask;
                        ++layerBuilds_;
                    } else {
                        note += std::format(
                            "Terrain on entity {}: {}. Hint: {} The layers' {} textures are not used until this is "
                            "fixed. ",
                            e.bits(), why.message, why.hint, name);
                    }
                }
            }
            en.layerNote[kind] = note;
        };
        if (job.handle.valid() && job.handle.done()) adopt();
        if (!any || job.handle.valid()) continue;
        if (loadedKey == key && !en.layerPending[kind]) continue;
        if (loadedKey != key) {  // other layers: the old pictures would show on the wrong layers
            free_texture(*device_, arr);
            mask = 0;
        }
        en.layerPending[kind] = false;
        auto build = std::make_shared<TerrainLayerBuild>();
        Terrain3D copy;  // the job reads only the layers
        copy.layers = t.layers;
        job.build = build;
        job.key = key;
        job.stale = false;
        ++layerLoads_;
        const bool srgbMips = albedo && fmt != gpu::PixelFormat::Rgba8;
        job.handle = jobs::submit("render.terrain_layers",
                                  [build, copy = std::move(copy), kindName = std::string(name), srgbMips] {
                                      auto imgs = load_terrain_layer_images(copy, kindName);
                                      if (!imgs) {
                                          build->error = imgs.error().message;
                                          build->hint = imgs.error().hint;
                                      } else {
                                          build->problems = imgs->problems;
                                          pack_picture_levels(*imgs, srgbMips, *build);
                                      }
                                      build->ran = true;
                                  });
        if (job.handle.done()) adopt();  // no workers: it ran inside submit()
    }
}

// The control array follows the splat maps. The shape (how many maps, their sizes, which objects) decides when it is made again whole;
// a repaint that only changed pixels (TerrainSplat::mark_dirty) sends just the rectangle it painted (copy_splat), and any other change of
// a map's version (code that bumps it without a rectangle) makes the array again.
void TerrainRenderer::update_control(Entry& en, const View& v, const std::vector<TerrainLayerInfo>& layers, Entity e) {
    const fa::TerrainHeights& th = *en.heights;
    const int need = layers.size() > 1 ? int((layers.size() + 3) / 4) : 0;
    int maps = 0;
    for (int m = 0; m < std::min(need, kTerrainSplatMaps); ++m)
        if (th.splat[std::size_t(m)].valid()) maps = m + 1;
    int side = 1;
    for (int m = 0; m < maps; ++m)
        if (th.splat[std::size_t(m)].valid()) side = std::max(side, th.splat[std::size_t(m)].size);
    bool resampled = false, moved = false;
    std::uint64_t skey = mix(mix(0x2545f4914f6cdd1dull, std::uint64_t(maps)), std::uint64_t(side));
    for (int m = 0; m < maps; ++m) {
        const TerrainSplat& s = th.splat[std::size_t(m)];
        skey = mix(mix(skey, s.serial), std::uint64_t(s.size));
        resampled = resampled || (s.valid() && s.size != side);
        moved = moved || s.version != en.splatSeen[m];
    }
    skey = mix(skey, reinterpret_cast<std::uintptr_t>(en.heights.get()));
    auto whole = [&] {
        free_texture(*device_, en.controlArr);
        en.controlCopyable = false;
        if (en.controlStage.id) device_->destroy_buffer(en.controlStage);
        en.controlStage = {};
        en.controlStageCap = 0;
        en.controlStagedFrame = 0;
        en.splatMaps = 0;
        en.controlSide = 1;
        en.controlNote.clear();
        en.controlKey = skey;
        for (int m = 0; m < kTerrainSplatMaps; ++m) en.splatSeen[m] = th.splat[std::size_t(m)].version;
        if (maps == 0) return;
        Error why;
        if (make_control_array(*device_, en.controlArr, th, maps, side, why)) {
            en.splatMaps = maps;
            en.controlSide = side;
            ++layerBuilds_;
        } else {
            en.controlNote =
                std::format("Terrain on entity {}: {}. Hint: {} The splat maps are not used until this is fixed. ",
                            e.bits(), why.message, why.hint);
        }
    };
    if (en.controlKey != skey)
        whole();
    else if (moved && (resampled || !en.controlArr.image.id || !copy_splat(en, v, maps, side)))
        whole();
}

// A repaint changed `rect` of some splat maps: the control array takes only those pixels (a staging buffer written for the frame and
// copied into each map's slice). The first repaint makes the array one that takes copies (every map, whole, through a staging buffer that
// is freed again); the later ones keep a staging buffer the size of the largest rectangles. False (nothing changed) where a copy cannot
// run: inside a pass, a second write in the same frame, no Gpu, a rectangle that is not known, or the GPU said no; the caller makes the
// array again then.
bool TerrainRenderer::copy_splat(Entry& en, const View& v, int maps, int side) {
    const fa::TerrainHeights& th = *en.heights;
    if (!v.gpu || !en.controlArr.image.id || en.controlArr.width != side || maps != en.splatMaps || maps <= 0 ||
        v.gpu->commands().pass_state() != gpu::PassState::None)
        return false;
    gpu::Device& device = v.gpu->device();
    const std::uint64_t frameTag = v.gpu->frame() + 1;
    if (en.controlStagedFrame == frameTag) return false;
    const bool convert = !en.controlCopyable;
    TerrainRect rects[kTerrainSplatMaps];
    std::size_t need = 0;
    for (int m = 0; m < maps; ++m) {
        const TerrainSplat& s = th.splat[std::size_t(m)];
        if (convert) {
            rects[m] = TerrainRect{0, 0, side - 1, side - 1};
        } else if (s.version != en.splatSeen[m]) {
            if (!s.dirty_since(en.splatSeen[m], rects[m])) return false;
            rects[m].c0 = std::max(rects[m].c0, 0);
            rects[m].r0 = std::max(rects[m].r0, 0);
            rects[m].c1 = std::min(rects[m].c1, side - 1);
            rects[m].r1 = std::min(rects[m].r1, side - 1);
        }
        if (!rects[m].empty())
            need += std::size_t(rects[m].c1 - rects[m].c0 + 1) * std::size_t(rects[m].r1 - rects[m].r0 + 1) * 4;
    }
    if (need == 0) {  // versions moved with nothing painted
        for (int m = 0; m < maps; ++m) en.splatSeen[m] = th.splat[std::size_t(m)].version;
        return true;
    }
    v.gpu->begin_transient_writes();  // before the first write of the frame (render_internal.h)
    gpu::Image target = en.controlArr.image;
    const gpu::View targetView = en.controlArr.view;
    if (convert) {
        gpu::ImageDesc d;
        d.type = gpu::ImageType::Array;
        d.width = d.height = side;
        d.numSlices = maps;
        d.pixelFormat = gpu::PixelFormat::Rgba8;
        d.usage.copyDst = true;
        d.label = "terrain-control";
        target = make_valid_image(device, d);
        if (!target.id) return false;
    }
    gpu::Buffer stage = en.controlStage;
    if (!stage.id || en.controlStageCap < need) {
        const std::size_t whole = std::size_t(side) * std::size_t(side) * 4 * std::size_t(maps);
        const std::size_t newCap = convert ? need : std::min(whole, need + need / 2);
        const gpu::Buffer fresh = make_staging_buffer(device, newCap, "terrain-control-staging");
        if (!fresh.id) {
            if (convert) device.destroy_image(target);
            return false;
        }
        if (en.controlStage.id) device.destroy_buffer(en.controlStage);
        stage = fresh;
        en.controlStage = fresh;
        en.controlStageCap = newCap;
    }
    std::vector<std::uint8_t> px(need);
    std::size_t at = 0;
    for (int m = 0; m < maps; ++m) {
        if (rects[m].empty()) continue;
        pack_splat_rect(th.splat[std::size_t(m)], side, rects[m], px.data() + at);
        at += std::size_t(rects[m].c1 - rects[m].c0 + 1) * std::size_t(rects[m].r1 - rects[m].r0 + 1) * 4;
    }
    gpu::CommandList& list = v.gpu->commands();
    gpu::BufferWrite w;
    w.data = gpu::Range{px.data(), px.size()};
    w.buffer = stage;
    list.write_buffer(w);
    std::size_t offset = 0;
    int copies = 0;
    for (int m = 0; m < maps; ++m) {
        if (rects[m].empty()) continue;
        const int cw = rects[m].c1 - rects[m].c0 + 1, ch = rects[m].r1 - rects[m].r0 + 1;
        gpu::BufferImageCopy c;
        c.src = stage;
        c.srcOffset = offset;
        c.bytesPerRow = cw * 4;
        c.bytesPerSlice = cw * 4 * ch;
        c.dst.image = target;
        c.dst.x = rects[m].c0;
        c.dst.y = rects[m].r0;
        c.dst.slice = m;
        c.size.width = cw;
        c.size.height = ch;
        c.size.numSlices = 1;
        list.copy_buffer_to_image(c);
        offset += std::size_t(cw) * std::size_t(ch) * 4;
        ++copies;
    }
    en.controlStagedFrame = frameTag;
    for (int m = 0; m < maps; ++m) en.splatSeen[m] = th.splat[std::size_t(m)].version;
    if (convert) {
        const gpu::View fresh = make_texture_view(device, target, "terrain-control");
        if (targetView.id) device.destroy_view(targetView);
        device.destroy_image(en.controlArr.image);
        en.controlArr.image = target;
        en.controlArr.view = fresh;
        en.controlCopyable = true;
        // The staging buffer of the whole array is not kept: the later copies are rectangles.
        device.destroy_buffer(en.controlStage);
        en.controlStage = {};
        en.controlStageCap = 0;
        en.controlStagedFrame = 0;
        ++layerBuilds_;
    } else {
        splatRects_ += std::uint64_t(copies);
    }
    return true;
}

TerrainRenderer::Entry* TerrainRenderer::prepare(const View& v, Entity e) {
    std::string problem;
    // The heightmap file was rewritten (the asset reload log names it): the store reads it again, outside its lock, and replaces the
    // heights when they differ and nothing in memory is unsaved. This thread reads the file (a 4097 x 4097 map is 33 MB: a short stall,
    // once per rewrite). A new entry has nothing to compare with: it starts at the current generation.
    auto found = entries_.find(e.bits());
    const std::uint64_t generation = v.assets ? v.assets->reload_generation() : 0;
    // A heightmap that failed to read has no entry here (nothing to draw): failedSeen_ keeps the generation it was last looked at, so
    // the file rewritten afterwards gets its second try (TerrainStore::reload reads a terrain that never loaded too).
    std::uint64_t* seenGeneration = nullptr;
    if (found != entries_.end())
        seenGeneration = &found->second->heightsReloadSeen;
    else if (auto f = failedSeen_.find(e.bits()); f != failedSeen_.end())
        seenGeneration = &f->second;
    if (seenGeneration && v.assets && *seenGeneration != generation) {
        const Terrain3D* t = v.world->get<Terrain3D>(e);
        const std::uint64_t since = *seenGeneration;
        *seenGeneration = generation;
        if (t && !t->heightmap.empty() && v.assets->reloaded_any_of(since, {fs::normalize(t->heightmap)}))
            v.world->terrain().reload(*v.world, e);
    }
    std::shared_ptr<fa::TerrainHeights> h = v.world->terrain().heights(*v.world, e, &problem);
    if (!h || !h->valid()) {
        if (found == entries_.end()) failedSeen_.emplace(e.bits(), generation);
        return nullptr;
    }
    failedSeen_.erase(e.bits());
    std::unique_ptr<Entry>& slot = entries_[e.bits()];
    if (!slot) {
        slot = std::make_unique<Entry>();
        slot->device = device_;
        slot->heightsReloadSeen = generation;
    }
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
    FA_ASSERT(v.gpu, "TerrainRenderer::gather needs the renderer's Gpu");
    device_ = &v.gpu->device();
    if (pruned_ != v.serial) {
        pruned_ = v.serial;
        // Terrains nobody asked for in the last two seconds or so (a hidden camera, a removed entity) give their texture back.
        for (auto it = entries_.begin(); it != entries_.end();) {
            if (it->second->seen + 120 < v.serial)
                it = entries_.erase(it);
            else
                ++it;
        }
        for (auto it = failedSeen_.begin(); it != failedSeen_.end();) {
            if (!world.alive(Entity::from_bits(it->first)))
                it = failedSeen_.erase(it);
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
        j.ranges = TerrainLodRanges::make(j.grid, en->bounds.levels(), t.lodQuality * v.lodQuality);
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
        const bool albedoSrgb = en->albedoFormat != gpu::PixelFormat::Rgba8;
        const int albedoFix = v.linear ? (albedoSrgb ? 0 : 1) : (albedoSrgb ? 2 : 0);
        const float p6[4] = {float(en->splatMaps), en->holesOn ? 1.0f : 0.0f,
                             en->albedoMask ? 1.0f + float(albedoFix) : 0.0f, en->normalMask ? 1.0f : 0.0f};
        const float p7[4] = {float(en->albedoMask), float(en->normalMask),
                             float(en->holesOn ? std::max(1, en->heights->samples - 1) : 1), float(layers.size())};
        std::memcpy(d.params[4], p4, sizeof p4);
        std::memcpy(d.params[5], p5, sizeof p5);
        std::memcpy(d.params[6], p6, sizeof p6);
        std::memcpy(d.params[7], p7, sizeof p7);
        for (std::size_t k = 0; k < layers.size(); ++k) {
            const float lp[4] = {1.0f / layers[k].tileSize, layers[k].roughness, layers[k].metallic,
                                 layers[k].normalScale};
            std::memcpy(d.params[8 + k], lp, sizeof lp);
        }
        TextureAsset* dummy = dummy_array(*device_);
        d.textures[0] = &en->tex;
        d.textures[1] = en->albedoArr.image.id ? &en->albedoArr : dummy;
        d.textures[2] = en->normalArr.image.id ? &en->normalArr : dummy;
        d.textures[3] = en->controlArr.image.id ? &en->controlArr : dummy;
        d.holes = en->holesOn ? &en->holesTex : dummy_holes(*device_, &en->tex);
        std::uint64_t hash = mix(0x9e3779b97f4a7c15ull, e.bits());
        for (const auto& row : d.params)
            for (float f : row) {
                std::uint32_t u;
                std::memcpy(&u, &f, sizeof u);
                hash = mix(hash, u);
            }
        for (const TextureAsset* tex : d.textures) hash = mix(hash, tex->gpu_view().id);
        hash = mix(hash, d.holes->gpu_view().id);
        d.hash = std::size_t(hash);
        j.draw = &d;
        jobs.push_back(std::move(j));
    });
    if (jobs.empty()) return 0;
    MaterialAsset* mat = material(*device_);
    MeshAsset* mesh = mat ? patch(*device_, false) : nullptr;
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
            mi.mesh = j.entry->holesOn ? patch(*device_, true) : mesh;
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
