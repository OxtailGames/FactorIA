#include "render_scene.h"

#include <algorithm>
#include <functional>

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

bool mesh_is_blended(const MeshRenderer& mr, const MeshAsset& mesh, const MaterialAsset* material) {
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
// Do `kept` (a copy made without the left-out names; null = none) and `now` hold the same values, left-out names aside? No
// allocation.
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

void RenderScene::build(World& world, Assets& assets, Entity scopeRoot, bool wantTargets) {
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
    for (std::size_t i = 0; i < meshes_.size(); ++i) {
        SceneMesh& sm = meshes_[i];
        const MeshRenderer& mr = *sm.mr;
        sm.mesh = assets.mesh(mr.mesh);
        sm.tex = mr.texture.empty() ? nullptr : assets.texture(mr.texture);
        sm.material = mr.material.empty() ? nullptr : assets.material(mr.material);
        if (sm.material && sm.material->ok && sm.material->kind != MaterialKind::Mesh) {
            // A mesh is drawn with the programs of a mesh material only: a sprite material (quad programs) would be bound to a
            // vertex layout it was not made for, and a compute material has no draw program. The mesh is drawn with the
            // engine's own shader.
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
            sm.blended = mesh_is_blended(mr, *sm.mesh, sm.material);
        }
    });
    if (wholeWorld) hashes_.end_frame();

    // The sort keys, once for every camera: ranks of names and values over the whole scene (a rebuilt table, so nothing
    // accumulates across frames). The lod levels are ranked too, for the cameras that swap them in.
    fields_.resize(meshes_.size());
    lodNames_.clear();
    for (std::size_t i = 0; i < meshes_.size(); ++i) {
        const SceneMesh& sm = meshes_[i];
        fields_[i] = {sm.mesh, sm.tex,      sm.normalTex,  sm.mr,         sm.entity,
                      sm.anim, sm.material, sm.paramsHash, sm.colorsHash, sm.flash};
        if (!sm.hasLods || !sm.mr->lods.is_array()) continue;
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
