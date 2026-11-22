#include "renderer_terrain.h"

#include <algorithm>
#include <cmath>
#include <cstring>

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

TerrainLayer0 terrain_layer0(const Terrain3D& t) {
    TerrainLayer0 out;
    if (!t.layers.is_array() || t.layers.empty() || !t.layers[0].is_object()) return out;
    const Json& l = t.layers[0];
    out.albedo = string_of(l, "albedo");
    out.normal = string_of(l, "normal");
    out.tileSize = number_of(l, "tileSize", out.tileSize, 0.01f, 100000.0f);
    out.roughness = number_of(l, "roughness", out.roughness, 0.0f, 1.0f);
    out.metallic = number_of(l, "metallic", out.metallic, 0.0f, 1.0f);
    out.normalScale = number_of(l, "normalScale", out.normalScale, 0.0f, 4.0f);
    return out;
}

TerrainRenderer::Entry::~Entry() {
    if (tex.view.id) sg_destroy_view(tex.view);
    if (tex.image.id) sg_destroy_image(tex.image);
}

void TerrainRenderer::destroy() {
    entries_.clear();
    if (patch_) {
        for (SubMesh& p : patch_->parts) {
            if (p.vb.id) sg_destroy_buffer(p.vb);
            if (p.ib.id) sg_destroy_buffer(p.ib);
        }
        patch_.reset();
    }
    material_.reset();
    for (sg_shader& s : shaders_) {
        if (s.id) sg_destroy_shader(s);
        s = {};
    }
    matState_ = 0;
}

std::size_t TerrainRenderer::bytes() const {
    std::size_t total = 0;
    for (const auto& [key, en] : entries_) total += en->tex.bytes;
    return total;
}

// The shared patch: 33 x 33 vertices at the integers (gx, 0, gz), 32 x 32 cells of two triangles each on the diagonal (0, 0) - (1, 1)
// (the diagonal of the physics heightfield and of terrain_vertex_raw), counter-clockwise seen from +y.
MeshAsset* TerrainRenderer::patch() {
    if (patch_) return patch_.get();
    std::vector<MeshVertex> v;
    v.reserve(std::size_t(kTerrainPatch) * kTerrainPatch);
    for (int z = 0; z < kTerrainPatch; ++z)
        for (int x = 0; x < kTerrainPatch; ++x) {
            MeshVertex m{};
            m.px = float(x);
            m.pz = float(z);
            m.ny = 1.0f;
            m.u = float(x) / float(kTerrainPatchCells);
            m.v = float(z) / float(kTerrainPatchCells);
            m.tx = 1.0f;
            m.tw = 1.0f;
            v.push_back(m);
        }
    std::vector<std::uint32_t> idx;
    idx.reserve(std::size_t(kTerrainTrianglesPerNode) * 3);
    for (int z = 0; z < kTerrainPatchCells; ++z)
        for (int x = 0; x < kTerrainPatchCells; ++x) {
            const std::uint32_t a = std::uint32_t(z * kTerrainPatch + x), b = a + 1, c = a + kTerrainPatch, d = c + 1;
            idx.insert(idx.end(), {a, c, d, a, d, b});
        }
    auto mesh = std::make_unique<MeshAsset>();
    mesh->key = "<terrain-patch>";
    SubMesh sm;
    sg_buffer_desc vb{};
    vb.data = {v.data(), v.size() * sizeof(MeshVertex)};
    vb.label = "terrain-patch";
    sm.vb = sg_make_buffer(&vb);
    sg_buffer_desc ib{};
    ib.usage.index_buffer = true;
    ib.usage.vertex_buffer = false;
    ib.data = {idx.data(), idx.size() * sizeof(std::uint32_t)};
    ib.label = "terrain-patch";
    sm.ib = sg_make_buffer(&ib);
    sm.vertexCount = int(v.size());
    sm.indexCount = int(idx.size());
    sm.bmin = {0, 0, 0};
    sm.bmax = {float(kTerrainPatchCells), 0, float(kTerrainPatchCells)};
    mesh->bmin = sm.bmin;
    mesh->bmax = sm.bmax;
    mesh->parts.push_back(sm);
    patch_ = std::move(mesh);
    return patch_.get();
}

// The in-memory material the nodes are drawn with: the three programs of shaders/terrain.glsl and the slots of its textures (the heights
// through a nearest sampler, then the albedo and the normal map of layer 0). null when the GPU rejects the shaders (said once).
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
    m->alphaMode = "opaque";
    m->instanceVec4 = 2;
    m->textures = {{"height", nullptr, SamplerKind::Nearest},
                   {"albedo", nullptr, SamplerKind::LinearRepeat},
                   {"normal", nullptr, SamplerKind::LinearRepeat}};
    m->programs[kProgMesh] = program_slots(shaders_[0], descs[0]);
    m->programs[kProgShadow] = program_slots(shaders_[1], descs[1]);
    m->programs[kProgPrepass] = program_slots(shaders_[2], descs[2]);
    m->generation = 1;
    m->ok = true;
    material_ = std::move(m);
    matState_ = 1;
    return material_.get();
}

// Makes the RG8 height texture of `en` from its CPU heights. The whole texture every time (a sub-rectangle copy needs a staging
// buffer and a frame discipline the renderer does not have): 2 bytes per sample, 33.5 MB for 4097 x 4097.
bool TerrainRenderer::upload(Entry& en, Entity e) {
    (void)e;
    const fa::TerrainHeights& h = *en.heights;
    if (en.tex.view.id) sg_destroy_view(en.tex.view);
    if (en.tex.image.id) sg_destroy_image(en.tex.image);
    en.tex.view = {};
    en.tex.image = {};
    en.tex.bytes = 0;
    const int limit = std::max(1, sg_query_limits().max_image_size_2d);
    if (h.samples > limit) {
        en.failed = true;
        FA_ERROR("render",
                 "A Terrain heightmap has {0} x {0} samples, but this GPU's largest texture is {1} x {1}, so the "
                 "terrain is not drawn. "
                 "Hint: resample the heightmap to {2} samples a side or fewer (2^n + 1).",
                 h.samples, limit, std::max(33, limit - (limit % 32 == 0 ? 0 : 0)));
        return false;
    }
    const std::size_t n = std::size_t(h.samples) * std::size_t(h.samples);
    std::vector<std::uint8_t> px(n * 2);
    for (std::size_t i = 0; i < n; ++i) {
        px[2 * i] = std::uint8_t(h.data[i] >> 8);
        px[2 * i + 1] = std::uint8_t(h.data[i] & 0xFF);
    }
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
        if (!upload(en, e)) return nullptr;
        en.bounds.build(*h);
        en.seenVersion = h->version;
    } else if (h->version != en.seenVersion) {
        TerrainRect rect;
        const bool known = h->dirty_since(en.seenVersion, rect);
        en.seenVersion = h->version;
        if (!upload(en, e)) return nullptr;
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
        const TerrainLayer0 l0 = terrain_layer0(t);
        TextureAsset* albedo = nullptr;
        TextureAsset* normal = nullptr;
        if (l0.albedo != en->albedoPath || (!l0.albedo.empty() && !en->albedo)) {
            en->albedoPath = l0.albedo;
            en->albedo = l0.albedo.empty() ? nullptr : v.assets->texture(l0.albedo);
        }
        if (l0.normal != en->normalPath || (!l0.normal.empty() && !en->normal)) {
            en->normalPath = l0.normal;
            en->normal = l0.normal.empty() ? nullptr : v.assets->texture(l0.normal);
        }
        albedo = en->albedo;
        normal = en->normal;
        draws.emplace_back();
        TerrainDraw& d = draws.back();
        d.mr.castShadows = t.castShadows;
        d.mr.roughness = l0.roughness;
        d.mr.metallic = l0.metallic;
        d.mr.color = albedo ? Color{1, 1, 1, 1} : Color{0.5f, 0.5f, 0.5f, 1.0f};
        std::memcpy(d.params, model.m, sizeof(model.m));
        const float cells = float(j.grid.cells());
        const float p4[4] = {j.camLocal.x, j.camLocal.y, j.camLocal.z, cells};
        const float p5[4] = {j.grid.cellX, j.grid.cellZ, j.grid.heightScale * (1.0f / kTerrainRawMax),
                             j.grid.heightOffset};
        const float p6[4] = {1.0f / l0.tileSize, 1.0f / l0.tileSize,
                             albedo ? 1.0f + float(albedo->tex_fix(v.linear, true)) : 0.0f,
                             normal ? 1.0f + float(normal->tex_fix(v.linear, false)) : 0.0f};
        std::memcpy(d.params[4], p4, sizeof p4);
        std::memcpy(d.params[5], p5, sizeof p5);
        std::memcpy(d.params[6], p6, sizeof p6);
        d.params[7][0] = l0.normalScale;
        d.textures[0] = &en->tex;
        d.textures[1] = albedo ? albedo : v.assets->white();
        d.textures[2] = normal ? normal : v.assets->white();
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
    MeshAsset* mesh = mat ? patch() : nullptr;
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
            mi.mesh = mesh;
            mi.model = j.model;
            mi.mr = &j.draw->mr;
            mi.entity = j.entity;
            mi.material = mat;
            mi.paramsHash = j.draw->hash;
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
