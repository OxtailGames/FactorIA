#include "render_scene.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <functional>
#include <unordered_map>

#include "fa/core/log.h"
#include "render_jobs.h"

namespace fa::render {

bool entity_active_in_scope(const World& w, Entity scopeRoot, Entity e) {
    if (scopeRoot == kNullEntity) return w.active_in_hierarchy(e) && !w.pending_destroy(e);
    if (!w.alive(e) || w.pending_destroy(e)) return false;
    for (Entity x = e; x != kNullEntity; x = w.parent(x)) {
        if (x == scopeRoot) return true;  // reached the subject: what is above it does not matter
        if (!w.info(x).active) return false;
    }
    return false;  // not part of the subject
}

void mesh_cull_bounds(const MeshAsset& mesh, const Animator* animator, Vec3& bmin, Vec3& bmax, const Animator*& anim) {
    bmin = mesh.bmin;
    bmax = mesh.bmax;
    anim = nullptr;
    // A skinned model with a computed pose is drawn deformed by the Animator's palette (before its first fixed step the
    // palette is empty and the model shows in bind pose).
    if (!animator || animator->palette.empty()) return;
    for (const SubMesh& p : mesh.parts)
        if (p.skinVb.id) anim = animator;
    if (!anim) return;
    bool first = true;  // the box of every skinned part carried by the joints of its own skin, joined with the rest
    for (const SubMesh& p : mesh.parts) {
        Vec3 lo = p.bmin, hi = p.bmax;
        if (p.skinVb.id) skinned_bounds(palette_of(*animator, p.skin), p.bmin, p.bmax, lo, hi);
        bmin = first ? lo : min(bmin, lo);
        bmax = first ? hi : max(bmax, hi);
        first = false;
    }
}

bool mesh_is_transmissive(const MeshRenderer& mr, const MeshAsset& mesh, const MaterialAsset* material) {
    // An unlit mesh transmits nothing (fill_fs zeroes it): no copy of the picture, no glass culling.
    if (mr.unlit || (material && (material->full || material->lighting == "unlit"))) return false;
    if (std::isfinite(mr.transmission) && mr.transmission > 0.0f) return true;
    for (const SubMesh& p : mesh.parts)
        if (p.layers.transmission > 0.0f) return true;
    return false;
}

bool mesh_is_blended(const MeshRenderer& mr, const MeshAsset& mesh, const MaterialAsset* material) {
    if (mesh_is_transmissive(mr, mesh, material)) return true;
    // The alphaMode of a material decides (blend = drawn far to near with the blended meshes; opaque and clip are not),
    // whatever Color.a or the glTF material say.
    if (material) return material->alphaMode == "blend";
    bool anyBlend = mr.color.a < 0.999f;
    for (const SubMesh& p : mesh.parts) anyBlend = anyBlend || p.blended;
    return anyBlend;
}

MaterialHashCache::Entry* MaterialHashCache::touch(Entity e) {
    const auto [it, fresh] = entries_.try_emplace(e.bits());
    Entry& en = it->second;
    if (fresh || en.seen != frame_) ++touched_;  // distinct entries: asking twice for one must not hide a stale one
    en.seen = frame_;
    return &en;
}

namespace {
bool left_out(const std::vector<std::string>* names, const std::string& key) {
    return names && std::binary_search(names->begin(), names->end(), key);
}
// Do `kept` (a copy made without the left-out names; null = none) and `now` hold the same values, left-out names aside?
// No allocation.
bool same_without(const Json& kept, const Json& now, const std::vector<std::string>* leftOut) {
    if (!leftOut || leftOut->empty() || !now.is_object()) return kept == now;
    std::size_t count = 0;
    for (auto it = now.begin(); it != now.end(); ++it) {
        if (left_out(leftOut, it.key())) continue;
        ++count;
        if (!kept.is_object()) return false;
        auto k = kept.find(it.key());
        if (k == kept.end() || !(*k == it.value())) return false;
    }
    return count == 0 ? kept.is_null() : kept.is_object() && kept.size() == count;
}
}  // namespace

void MaterialHashCache::refresh(Entry& entry, const Json* params, const Json* colors,
                                const std::vector<std::string>* leftOut, std::size_t leftOutKey) {
    auto one = [&](Json& kept, std::size_t& hash, const Json* now, const std::vector<std::string>* out, bool stale) {
        if (!now) {
            kept = Json();
            hash = 0;
            return;
        }
        if (!stale && same_without(kept, *now, out))
            return;  // the same value as when the hash was made: nothing to compute
        if (out && !out->empty() && now->is_object()) {
            Json filtered = Json::object();
            for (auto it = now->begin(); it != now->end(); ++it)
                if (!left_out(out, it.key())) filtered[it.key()] = it.value();
            kept = filtered.empty() ? Json() : std::move(filtered);
        } else {
            kept = *now;
        }
        hash = kept.is_null() ? 0 : std::hash<std::string>{}(kept.dump());
        computed_.fetch_add(1, std::memory_order_relaxed);
    };
    const bool stale = entry.leftOutKey != leftOutKey;
    entry.leftOutKey = leftOutKey;
    one(entry.params, entry.paramsHash, params, leftOut, stale);
    one(entry.colors, entry.colorsHash, colors, nullptr, false);
}

void MaterialHashCache::end_frame() {
    if (entries_.size() > touched_) std::erase_if(entries_, [&](const auto& kv) { return kv.second.seen != frame_; });
}

void MaterialHashCache::hashes(Entity e, const Json* params, const Json* colors, std::size_t& paramsHash,
                               std::size_t& colorsHash, const MaterialAsset* material) {
    Entry* en = touch(e);
    // As RenderScene::build does: the instanced params of the entity's material are not part of the params hash.
    refresh(*en, params, colors,
            params && material && !material->instancedNames.empty() ? &material->instancedNames : nullptr,
            params && material ? material->instancedKey : 0);
    paramsHash = en->paramsHash;
    colorsHash = en->colorsHash;
}

namespace {
// The probes are read at the sample point snapped to this lattice (metres, round to the nearest node), so meshes within a
// quarter of a metre of each other get the same light, the same key and one instanced draw (a coin field is a few draws, not
// one per coin). A moving object's light steps by at most the gradient over this distance.
constexpr float kProbeSnap = 0.25f;
float probe_snap(float v) { return std::floor(v / kProbeSnap + 0.5f) * kProbeSnap; }
}  // namespace

// A missing or disabled anchor entity is the same as none. A point that is not finite reads nothing (NaN: coverage 0).
Vec3 probe_point(const World& world, const MeshRenderer& mr, const Mat4& model, Vec3 bmin, Vec3 bmax) {
    Vec3 p = model.transform_point((bmin + bmax) * 0.5f);
    if (mr.probeAnchor != kNullEntity && world.alive(mr.probeAnchor) && world.active_in_hierarchy(mr.probeAnchor))
        p = world.drawn_matrix(mr.probeAnchor).translation();
    if (!std::isfinite(p.x) || !std::isfinite(p.y) || !std::isfinite(p.z)) return {NAN, NAN, NAN};
    return {probe_snap(p.x), probe_snap(p.y), probe_snap(p.z)};
}

// The LodGroups (M75.1): for each active group, which meshes sit under each of its children, and the sphere around all of them (the
// whole subtree, whichever child is drawn, so the screen size does not change when the level does). Runs after the boxes and matrices of
// the meshes are known.
void RenderScene::build_lod_groups(World& world, Entity scopeRoot) {
    // Entity index -> index in meshes_ (kNoMesh = none): a flat table the scene keeps between builds, no hashing. A stale entity (the
    // slot was reused) is told apart by the entity the mesh holds.
    constexpr std::uint32_t kNoMesh = UINT32_MAX;
    std::uint32_t slots = 0;
    for (const SceneMesh& sm : meshes_) slots = std::max(slots, sm.entity.index + 1);
    meshOf_.assign(slots, kNoMesh);
    for (std::size_t i = 0; i < meshes_.size(); ++i) meshOf_[meshes_[i].entity.index] = std::uint32_t(i);
    const auto mesh_of = [&](Entity x) {
        if (x.index >= meshOf_.size() || meshOf_[x.index] == kNoMesh) return kNoMesh;
        return meshes_[meshOf_[x.index]].entity == x ? meshOf_[x.index] : kNoMesh;
    };
    world.each<LodGroup>([&](Entity e, LodGroup& g) {
        if (!entity_active_in_scope(world, scopeRoot, e)) return;
        SceneLodGroup& sg = lodGroups_.emplace_back();
        sg.entity = e;
        sg.group = &g;
        sg.origin = world.drawn_matrix(e).translation();
    });
    std::vector<std::pair<std::uint32_t, std::uint32_t>> links;  // (mesh index, chain entry)
    std::vector<Entity> stack;
    for (std::size_t gi = 0; gi < lodGroups_.size(); ++gi) {
        SceneLodGroup& sg = lodGroups_[gi];
        const std::vector<Entity>& kids = world.children(sg.entity);
        sg.children = int(kids.size());
        Vec3 lo{1e30f, 1e30f, 1e30f}, hi{-1e30f, -1e30f, -1e30f};
        bool any = false;
        for (std::size_t ci = 0; ci < kids.size(); ++ci) {
            const std::uint32_t child = ci <= std::size_t(kMaxLodThresholds) ? std::uint32_t(ci) : 15u;
            stack.assign(1, kids[ci]);
            while (!stack.empty()) {
                const Entity x = stack.back();
                stack.pop_back();
                if (const std::uint32_t found = mesh_of(x); found != kNoMesh) {
                    const SceneMesh& sm = meshes_[found];
                    links.emplace_back(found, (std::uint32_t(gi) << 4) | child);
                    for (int c = 0; c < 8; ++c) {
                        const Vec3 p =
                            sm.model.transform_point({(c & 1) ? sm.bmax.x : sm.bmin.x, (c & 2) ? sm.bmax.y : sm.bmin.y,
                                                      (c & 4) ? sm.bmax.z : sm.bmin.z});
                        lo = min(lo, p);
                        hi = max(hi, p);
                    }
                    any = true;
                }
                for (Entity k : world.children(x)) stack.push_back(k);
            }
        }
        if (any) {
            sg.radius = 0.5f * length(hi - lo);
        }
    }
    std::stable_sort(links.begin(), links.end(), [](const auto& a, const auto& b) { return a.first < b.first; });
    lodChains_.reserve(links.size());
    for (std::size_t i = 0; i < links.size();) {
        SceneMesh& sm = meshes_[links[i].first];
        sm.chainFirst = std::uint32_t(lodChains_.size());
        std::size_t j = i;
        for (; j < links.size() && links[j].first == links[i].first; ++j) lodChains_.push_back(links[j].second);
        sm.chainCount = std::uint32_t(j - i);
        i = j;
    }
}

void RenderScene::build(World& world, Assets& assets, Entity scopeRoot, bool wantTargets,
                        const std::vector<ProbeVolume>* probeVolumes) {
    meshes_.clear();
    scope_ = scopeRoot;
    built_ = true;
    // A build of a subtree (Renderer::capture_world) shares the cache without a frame of its own: end_frame would drop the
    // entries of the rest of the world.
    const bool wholeWorld = scopeRoot == kNullEntity;
    if (wholeWorld) hashes_.begin_frame();
    const bool anyFlash = world.feel().any_flash();

    world.each<MeshRenderer>([&](Entity e, MeshRenderer& mr) {
        if (!entity_active_in_scope(world, scopeRoot, e)) return;
        SceneMesh& sm = meshes_.emplace_back();
        sm.mr = &mr;
        sm.entity = e;
    });

    // The asset lookups stay on this thread (a mesh, texture or material may be loaded), and so do the cache entries (a map
    // that grows); the jobs below only read the assets and write their own items and entries. Every active MeshRenderer is
    // resolved, also one no camera shows (a tag filter, outside every frustum): a broken path warns once even then.
    std::vector<MaterialHashCache::Entry*>& entries = entries_;
    entries.assign(meshes_.size(), nullptr);
    const LightmapSetAsset* lightmaps = assets.lightmaps(world.settings().lightmaps);
    const ProbeSet* probes =
        lightmaps && lightmaps->probes.baked() && lightmaps->probes.size() > 0 ? &lightmaps->probes : nullptr;
    hasProbes_ = probes != nullptr;
    if (probes)
        probeLights_.assign(meshes_.size(), ProbeLight{});
    else
        probeLights_.clear();
    for (std::size_t i = 0; i < meshes_.size(); ++i) {
        SceneMesh& sm = meshes_[i];
        const MeshRenderer& mr = *sm.mr;
        sm.mesh = assets.mesh(mr.mesh);
        sm.tex = mr.texture.empty() ? nullptr : assets.texture(mr.texture);
        sm.material = mr.material.empty() ? nullptr : assets.material(mr.material);
        if (sm.material && sm.material->ok && sm.material->kind != MaterialKind::Mesh) {
            // A mesh is drawn with the programs of a mesh material only: a sprite material (quad programs) would be
            // bound to a vertex layout it was not made for, and a compute material has no draw program. The mesh is
            // drawn with the engine's own shader.
            if (sm.material->warned.insert("\x01kind").second)
                FA_WARN(
                    "render",
                    "MeshRenderer.material '{}' is a \"{}\" material: only \"mesh\" materials draw a MeshRenderer, so "
                    "the engine's own shader is used (a \"sprite\" material is for the 2D quad pipeline, a \"compute\" "
                    "one for the compute.* commands, a \"sky\" one for the sky and a \"post\" one for "
                    "PostProcess.customPasses)",
                    mr.material, material_kind_name(sm.material->kind));
            sm.material = nullptr;
        }
        sm.normalTex = mr.normalMap.empty() ? nullptr : assets.texture(mr.normalMap);
        // A baked lightmap lights the entity when the manifest lists it (by its stable id) with this very mesh. The engine's own shader
        // reads it; so does a custom mesh material that declares "uv1" in vertexAttributes (the lightmap UV travels in that channel); a
        // full-shader material, one drawn from compute buffers and one without the channel do not, and are lit as without a lightmap.
        const bool materialReads =
            !sm.material || (sm.material->ok && !sm.material->full && sm.material->buffers.empty() && sm.material->uv1);
        if (lightmaps && mr.receiveGI && mr.lightmapScale > 0.0f && materialReads) {
            static const std::string kCube = "cube";  // not a std::string made for every entity of every frame
            assets.lightmap_use(*lightmaps, world.id_of(sm.entity), *sm.mesh, mr.mesh.empty() ? kCube : mr.mesh, sm.lm);
        }
        sm.hasLods = !mr.lods.empty();
        sm.liveTextures = Assets::is_target_id(mr.texture) || Assets::is_target_id(mr.normalMap);
        const bool params = sm.material && mr.materialParams.is_object() && !mr.materialParams.empty();
        const bool colors = mr.materialColors.is_object() && !mr.materialColors.empty();
        if (params || colors) entries[i] = hashes_.touch(sm.entity);
        if (!wantTargets) continue;
        auto add = [&](const std::string& path) {
            if (!Assets::is_target_id(path)) return;
            std::string name = path.substr(7);
            if (std::find(sm.targets.begin(), sm.targets.end(), name) == sm.targets.end())
                sm.targets.push_back(std::move(name));
        };
        add(mr.texture);
        add(mr.normalMap);
        if (mr.materialParams.is_object())
            for (auto& [k, v] : mr.materialParams.items())
                if (v.is_string()) add(v.get<std::string>());
    }

    // Matrices and flashes, then boxes, blending and hashes: each chunk writes only its own items (and their entries).
    const rjobs::Split split = rjobs::split(meshes_.size(), kMeshGrain, kParallelMeshes);
    rjobs::run("render.mesh_matrices", split, [&](const jobs::Chunk& c) {
        for (std::size_t i = c.begin; i < c.end; ++i) {
            SceneMesh& sm = meshes_[i];
            sm.model = world.drawn_matrix(sm.entity);
            if (!anyFlash) continue;
            for (Entity x = sm.entity; x != kNullEntity; x = world.parent(x))
                if (const auto flash = world.feel().flash_of(x)) {  // feel.h: flashing items never share a draw
                    sm.flash = *flash;
                    break;
                }
        }
    });
    rjobs::run("render.mesh_cull", split, [&](const jobs::Chunk& c) {
        std::unordered_map<std::uint64_t, std::size_t>
            probeCache;  // snapped node -> the mesh of this chunk that read it
        constexpr std::size_t kProbeCacheMax = 4096;
        for (std::size_t i = c.begin; i < c.end; ++i) {
            SceneMesh& sm = meshes_[i];
            const MeshRenderer& mr = *sm.mr;
            if (MaterialHashCache::Entry* en = entries[i]) {
                const bool params = sm.material && mr.materialParams.is_object() && !mr.materialParams.empty();
                const bool colors = mr.materialColors.is_object() && !mr.materialColors.empty();
                hashes_.refresh(*en, params ? &mr.materialParams : nullptr, colors ? &mr.materialColors : nullptr,
                                params && !sm.material->instancedNames.empty() ? &sm.material->instancedNames : nullptr,
                                params ? sm.material->instancedKey : 0);
                sm.paramsHash = en->paramsHash;
                sm.colorsHash = en->colorsHash;
            }
            mesh_cull_bounds(*sm.mesh, world.get<Animator>(sm.entity), sm.bmin, sm.bmax, sm.anim);
            if (sm.anim) sm.lm = {};  // a skinned mesh is deformed: its baked light would not follow it
            if (probes && mr.receiveGI && !mr.unlit && !sm.lm.mesh &&
                (!sm.material || (sm.material->ok && !sm.material->full && sm.material->buffers.empty()))) {
                // A mesh without a lightmap (a moving object, lightmapScale 0, a skinned mesh) receives the baked probes at the centre of its
                // box, or at the MeshRenderer.probeAnchor entity.
                const Vec3 at = probe_point(world, mr, sm.model, sm.bmin, sm.bmax);
                if (std::isfinite(at.x)) {
                    // probe_light_at is a pure function of the snapped point, so a mesh on a node an earlier mesh of this chunk
                    // already read gets that result (a field of coins is a few lookups): the same value, whatever the order.
                    const bool cacheable =
                        std::fabs(at.x) < 1.0e5f && std::fabs(at.y) < 1.0e5f && std::fabs(at.z) < 1.0e5f;
                    std::uint64_t key = 0;
                    if (cacheable) {  // llround of a huge value is undefined, so only a point in range is snapped
                        const std::int64_t kx = std::int64_t(std::llround(at.x / kProbeSnap)),
                                           ky = std::int64_t(std::llround(at.y / kProbeSnap)),
                                           kz = std::int64_t(std::llround(at.z / kProbeSnap));
                        key = (std::uint64_t(kx & 0x1fffff) << 42) | (std::uint64_t(ky & 0x1fffff) << 21) |
                              std::uint64_t(kz & 0x1fffff);
                    }
                    auto hit = cacheable ? probeCache.find(key) : probeCache.end();
                    if (hit != probeCache.end()) {
                        probeLights_[i] = probeLights_[hit->second];
                    } else {
                        probeLights_[i] = probe_light_at(*probes, at);
                        if (cacheable && probeCache.size() < kProbeCacheMax) probeCache.emplace(key, i);
                    }
                } else {
                    probeLights_[i] = ProbeLight{};
                }
                if (probeLights_[i].coverage > 0.0f) {
                    sm.probe = &probeLights_[i];
                    sm.probeKey = probe_light_key(probeLights_[i]);
                }
            }
            sm.blended = mesh_is_blended(mr, *sm.mesh, sm.material);
            if (sm.material && !sm.material->buffers.empty()) {
                // A mesh drawn from compute buffers (mesh_buffer_draw.h) is a batch of its own (the entity is part of
                // what batches differ by), has no lod levels, and is culled by MeshRenderer.instanceBounds: its
                // instances are where the buffer puts them, so the mesh's own box says nothing.
                std::uint64_t mixed = sm.paramsHash ^ (sm.entity.bits() * 0x9e3779b97f4a7c15ull);
                mixed ^= mixed >> 32;  // two entities differ in the low bits: spread them before the hash is compared
                mixed *= 0xd6e8feb86659fd93ull;
                mixed ^= mixed >> 32;
                sm.paramsHash = std::size_t(mixed ? mixed : 1);
                sm.hasLods = false;
                const float h = std::isfinite(mr.instanceBounds) ? mr.instanceBounds : 0.0f;
                sm.noCull = !(h > 0.0f);
                if (!sm.noCull) {
                    sm.bmin = {-h, -h, -h};
                    sm.bmax = {h, h, h};
                }
            }
            if (probeVolumes && !probeVolumes->empty() && !mr.unlit) {
                // The reflection probes of the mesh (M73-P3c): chosen at the centre of its box, a pure function of the position, so the
                // same scene picks the same whatever the job split. The pick is part of the batch key.
                const Vec3 at = sm.model.transform_point((sm.bmin + sm.bmax) * 0.5f);
                sm.refl = pick_probes(*probeVolumes, at);
                if (sm.refl.any()) {
                    std::uint64_t k = std::uint64_t(sm.refl.key()) * 0x9e3779b97f4a7c15ull;
                    k ^= k >> 31;
                    sm.probeKey = (sm.probeKey ^ k) * 0xff51afd7ed558ccdull + sm.refl.key();
                    if (sm.probeKey == 0) sm.probeKey = 1;
                }
            }
        }
    });
    if (wholeWorld) hashes_.end_frame();

    lodGroups_.clear();
    lodChains_.clear();
    anyLods_ = false;
    if (world.any<LodGroup>()) build_lod_groups(world, scopeRoot);

    // The sort keys, once for every camera: ranks of names and values over the whole scene (a rebuilt table, so nothing
    // accumulates across frames). The lod levels are ranked too, for the cameras that swap them in.
    fields_.resize(meshes_.size());
    lodNames_.clear();
    for (std::size_t i = 0; i < meshes_.size(); ++i) {
        const SceneMesh& sm = meshes_[i];
        fields_[i] = {sm.mesh,       sm.tex,   sm.normalTex,          sm.mr,
                      sm.entity,     sm.anim,  sm.material,           sm.paramsHash,
                      sm.colorsHash, sm.flash, sm.lm.mesh != nullptr, sm.probeKey};
        if (!sm.hasLods || !sm.mr->lods.is_array()) continue;
        anyLods_ = true;
        for (const Json& e : sm.mr->lods) {
            if (!e.is_object()) continue;
            const auto m = e.find("mesh");
            if (m != e.end() && m->is_string()) lodNames_.push_back(m->get_ref<const std::string&>());
        }
    }
    const bool keyed = sortTable_.build(fields_, lodNames_, keys_);
    if (!keyed) {
        // Not an error (the comparator gives the same order, only slower), but a scene that big is worth knowing about.
        if (sortKeyFallbacks_++ == 0) {
            const char* overflow = sortTable_.overflow() ? sortTable_.overflow() : "values";
            const std::string what =
                std::string_view(overflow) == "items" ? "mesh renderers" : std::string("distinct ") + overflow;
            FA_WARN(
                "render",
                "the 3D scene has more {} than the sort key holds (limits per frame: {} meshes, {} textures, {} "
                "material value sets): its opaque meshes are sorted by the slower comparator. The draw order is the "
                "same, only slower; use fewer distinct meshes or textures (share assets between entities). Counted "
                "in RenderScene::sort_key_fallbacks()",
                what, 1u << kSortMeshBits, 1u << kSortTexBits, 1u << kSortRestBits);
        }
    }
    for (std::size_t i = 0; i < meshes_.size(); ++i) {
        meshes_[i].keyed = keyed;
        meshes_[i].sortKey = keyed ? keys_[i] : 0;
    }
    // The work buffers keep their capacity between frames, unless a huge frame left far more than this one needs.
    release_peak(fields_, meshes_.size());
    release_peak(keys_, meshes_.size());
    release_peak(entries_, meshes_.size());
}

}  // namespace fa::render
