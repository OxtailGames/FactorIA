#include "mesh_batch.h"

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <string_view>
#include <tuple>

#include "render_jobs.h"

namespace fa::render {

bool box_in_frustum(const Mat4& viewProj, bool zeroToOne, Vec3 bmin, Vec3 bmax, const Mat4& model) {
    const Mat4 m = viewProj * model;
    // Bit i of a mask: the corner lies outside plane i (x<-w, x>w, y<-w, y>w, z<near, z>w). The box is outside when all
    // corners share one such plane.
    unsigned outside = 0x3F;
    for (int c = 0; c < 8; ++c) {
        Vec4 p = m * Vec4{(c & 1) ? bmax.x : bmin.x, (c & 2) ? bmax.y : bmin.y, (c & 4) ? bmax.z : bmin.z, 1.0f};
        unsigned out = 0;
        if (p.x < -p.w) out |= 1u;
        if (p.x > p.w) out |= 2u;
        if (p.y < -p.w) out |= 4u;
        if (p.y > p.w) out |= 8u;
        if (p.z < (zeroToOne ? 0.0f : -p.w)) out |= 16u;
        if (p.z > p.w) out |= 32u;
        outside &= out;
        if (!outside) return true;
    }
    return false;
}

void skinned_bounds(const std::vector<Mat4>& palette, Vec3 bmin, Vec3 bmax, Vec3& outMin, Vec3& outMax) {
    outMin = bmin;
    outMax = bmax;
    if (palette.empty()) return;
    outMin = {1e30f, 1e30f, 1e30f};
    outMax = {-1e30f, -1e30f, -1e30f};
    for (const Mat4& m : palette)
        for (int i = 0; i < 8; ++i) {
            const Vec3 p =
                m.transform_point({(i & 1) ? bmax.x : bmin.x, (i & 2) ? bmax.y : bmin.y, (i & 4) ? bmax.z : bmin.z});
            outMin = min(outMin, p);
            outMax = max(outMax, p);
        }
}

namespace {
auto material_key(const MeshItem& a) {
    const MeshRenderer& r = *a.mr;
    return std::make_tuple(a.mesh, a.tex, a.normalTex, r.color.r, r.color.g, r.color.b, r.color.a, r.metallic,
                           r.roughness, r.emissive.r, r.emissive.g, r.emissive.b, r.emissiveStrength, r.clearcoat,
                           r.clearcoatRoughness, r.sheenColor.r, r.sheenColor.g, r.sheenColor.b, r.sheenRoughness,
                           r.anisotropy, r.anisotropyRotation, r.specular, r.ior, r.unlit, r.receiveShadows,
                           r.uvScale.x, r.uvScale.y, r.normalScale, a.anim, a.material, a.paramsHash, a.colorsHash,
                           a.flash.r, a.flash.g, a.flash.b, a.flash.a, a.lm.mesh ? a.entity.bits() : std::uint64_t(0), decal_recv(r), a.probeKey);
}

// The order of the batches: the same values, with each asset by its name (path or key) and a skinned item by its
// entity, never by its address. Addresses differ from one process to the next (ASLR, the heap), and so would the
// order of opaque meshes of different materials, and with it the pixels of coplanar ones. Floats go through
// order_float (NaN would break the sort's strict weak order). Items with equal material_key have equal order_key, so
// they sort next to each other and share a batch (the asset caches hold one asset per name; two of one name would
// only split a batch, never merge two).
std::string_view name_of(const MeshAsset* m) { return m ? std::string_view(m->key) : std::string_view(); }
std::string_view name_of(const TextureAsset* t) { return t ? std::string_view(t->path) : std::string_view(); }
std::string_view name_of(const MaterialAsset* m) { return m ? std::string_view(m->path) : std::string_view(); }

auto order_key(const MeshItem& a) {
    const MeshRenderer& r = *a.mr;
    using rjobs::order_float;
    return std::make_tuple(
        name_of(a.mesh), name_of(a.tex), name_of(a.normalTex), order_float(r.color.r), order_float(r.color.g),
        order_float(r.color.b), order_float(r.color.a), order_float(r.metallic), order_float(r.roughness),
        order_float(r.emissive.r), order_float(r.emissive.g), order_float(r.emissive.b),
        order_float(r.emissiveStrength), order_float(r.clearcoat), order_float(r.clearcoatRoughness),
        order_float(r.sheenColor.r), order_float(r.sheenColor.g), order_float(r.sheenColor.b),
        order_float(r.sheenRoughness), order_float(r.anisotropy), order_float(r.anisotropyRotation),
        order_float(r.specular), order_float(r.ior), r.unlit, r.receiveShadows, order_float(r.uvScale.x),
        order_float(r.uvScale.y), order_float(r.normalScale),
        (a.anim || a.lm.mesh) ? a.entity.bits() : std::uint64_t(0), name_of(a.material), a.paramsHash, a.colorsHash,
        order_float(a.flash.r), order_float(a.flash.g), order_float(a.flash.b), order_float(a.flash.a), decal_recv(r), a.probeKey);
}

// Items that can share one instanced draw have the same mesh, textures and every MeshRenderer value the shader reads.
// Different keys mean different names or values, so there is no need to look at the fields.
bool same_material(const MeshItem& a, const MeshItem& b) {
    if (a.keyed && b.keyed && a.sortKey != b.sortKey) return false;
    return material_key(a) == material_key(b);
}
bool material_less(const MeshItem& a, const MeshItem& b) { return order_key(a) < order_key(b); }

// The items of a camera are sorted by material as jobs from this many on, in chunks of kSortGrain (render_jobs.h:
// the same order as one std::stable_sort).
constexpr std::size_t kParallelSortItems = 1024;
constexpr std::size_t kSortGrain = 256;
}  // namespace

void build_batches(std::vector<MeshItem>& items, bool sortByMaterial, std::vector<MeshBatch>& batches,
                   std::vector<Mat4>& mainMats, std::vector<Mat4>& shadowMats, std::vector<ShadowRun>* runsOut) {
    std::vector<ShadowRun> discarded;
    std::vector<ShadowRun>& runs = runsOut ? *runsOut : discarded;
    const std::size_t firstNewBatch = batches.size();
    if (sortByMaterial) {
        const bool allKeyed = std::all_of(items.begin(), items.end(), [](const MeshItem& m) { return m.keyed; });
        if (allKeyed) {
            // A stable sort of (key, index) pairs: equal keys are equal items, so this is the order the comparator gives.
            struct Entry {
                std::uint64_t key;
                std::uint32_t index;
            };
            std::vector<Entry> order(items.size());
            for (std::size_t i = 0; i < items.size(); ++i) order[i] = {items[i].sortKey, std::uint32_t(i)};
            rjobs::stable_sort(
                "render.sort_meshes", order, [](const Entry& a, const Entry& b) { return a.key < b.key; },
                kParallelSortItems, kSortGrain);
            std::vector<MeshItem> sorted;
            sorted.reserve(items.size());
            for (const Entry& e : order) sorted.push_back(std::move(items[e.index]));
            items.swap(sorted);
        } else {
            rjobs::stable_sort("render.sort_meshes", items, material_less, kParallelSortItems, kSortGrain);
        }
    }
    for (std::size_t i = 0; i < items.size(); ++i) {
        if (batches.empty() || !same_material(items[batches.back().rep], items[i])) {
            MeshBatch b;
            b.rep = i;
            b.mainFirst = std::uint32_t(mainMats.size());
            batches.push_back(b);
        }
        MeshBatch& b = batches.back();
        if (items[i].visible) {
            mainMats.push_back(items[i].model);
            ++b.mainCount;
        }
    }
    // The casters, batch by batch and inside a batch view by view: each view's pass draws one contiguous run of instances.
    for (std::size_t bi = firstNewBatch; bi < batches.size(); ++bi) {
        MeshBatch& b = batches[bi];
        const std::size_t end = bi + 1 < batches.size() ? batches[bi + 1].rep : items.size();
        std::uint64_t views = 0;
        for (std::size_t i = b.rep; i < end; ++i)
            if (items[i].casts) views |= items[i].castMask;
        b.runFirst = std::uint32_t(runs.size());
        for (int v = 0; v < kMaxShadowViews; ++v) {
            if (!(views >> v & 1u)) continue;
            ShadowRun r;
            r.view = std::uint32_t(v);
            r.first = std::uint32_t(shadowMats.size());
            for (std::size_t i = b.rep; i < end; ++i)
                if (items[i].casts && (items[i].castMask >> v & 1u)) shadowMats.push_back(items[i].model);
            r.count = std::uint32_t(shadowMats.size()) - r.first;
            runs.push_back(r);
        }
        b.runCount = std::uint32_t(runs.size()) - b.runFirst;
    }
}

void InstanceParamCache::begin_frame(std::uint64_t serial) {
    if (serial == serial_) return;
    // Drop what the previous frame did not ask for (an entity that died, hid or changed material).
    if (entries_.size() > touched_) std::erase_if(entries_, [&](const auto& kv) { return kv.second.seen != serial_; });
    serial_ = serial;
    touched_ = 0;
}

void InstanceParamCache::clear() {
    entries_.clear();
    defaults_.clear();
    serial_ = ~std::uint64_t(0);
    touched_ = 0;
}

const float* InstanceParamCache::get(Entity entity, const MeshRenderer& mr, MaterialAsset& m) {
    const std::size_t floats = std::size_t(m.instanceVec4) * 4;
    const Json& over = mr.materialParams;
    if (!over.is_object() || over.empty()) {  // the defaults: one block for every entity of the material
        Default& d = defaults_[&m];
        if (d.generation != m.generation || d.floats.size() != floats) {
            d.floats.assign(floats, 0.0f);
            pack_instance_params(m, Json(), d.floats.data());
            d.generation = m.generation;
            ++packed_;
        }
        return d.floats.data();
    }
    Entry& e = entries_[entity.bits()];
    if (e.seen != serial_ || e.generation < 0) ++touched_;
    e.seen = serial_;
    if (e.material != &m || e.generation != m.generation || e.floats.size() != floats || !(e.overrides == over)) {
        e.floats.assign(floats, 0.0f);
        pack_instance_params(m, over, e.floats.data());
        e.overrides = over;
        e.material = &m;
        e.generation = m.generation;
        ++packed_;
    }
    return e.floats.data();
}

void pack_instance_extras(const std::vector<MeshItem>& items, std::vector<MeshBatch>& batches,
                          std::vector<float>& mainData, std::vector<float>& shadowData, InstanceParamCache* cache,
                          std::vector<ShadowRun>* runs) {
    for (std::size_t bi = 0; bi < batches.size(); ++bi) {
        MeshBatch& b = batches[bi];
        MaterialAsset* mat = items[b.rep].material;
        if (!mat || !mat->ok || mat->instanceVec4 <= 0) continue;
        const std::size_t end = bi + 1 < batches.size() ? batches[bi + 1].rep : items.size();
        const std::size_t floats = std::size_t(mat->instanceVec4) * 4;
        b.instanceVec4 = std::uint32_t(mat->instanceVec4);
        b.mainExtra = std::uint32_t(mainData.size());
        // The values of an entity: from the cache, or packed straight into the buffer that needs them.
        auto append = [&](std::vector<float>& data, const MeshItem& mi) {
            const float* packed = cache ? cache->get(mi.entity, *mi.mr, *mat) : nullptr;
            const std::size_t at = data.size();
            data.resize(at + floats);
            if (packed)
                std::memcpy(data.data() + at, packed, floats * sizeof(float));
            else
                pack_instance_params(*mat, mi.mr->materialParams, data.data() + at);
        };
        for (std::size_t i = b.rep; i < end; ++i)
            if (items[i].visible) append(mainData, items[i]);
        if (!runs) continue;
        for (std::uint32_t k = 0; k < b.runCount; ++k) {
            ShadowRun& r = (*runs)[b.runFirst + k];
            r.extra = std::uint32_t(shadowData.size());
            for (std::size_t i = b.rep; i < end; ++i)
                if (items[i].casts && (items[i].castMask >> r.view & 1u)) append(shadowData, items[i]);
        }
    }
}

// ---- the sort key ----

bool pack_sort_key(std::uint64_t mesh, std::uint64_t tex, std::uint64_t normal, std::uint64_t rest,
                   std::uint64_t& key) {
    if (mesh >> kSortMeshBits || tex >> kSortTexBits || normal >> kSortNormalBits || rest >> kSortRestBits)
        return false;
    key = (mesh << (kSortTexBits + kSortNormalBits + kSortRestBits)) | (tex << (kSortNormalBits + kSortRestBits)) |
          (normal << kSortRestBits) | rest;
    return true;
}

namespace {
std::uint64_t mix(std::uint64_t h, std::uint64_t v) { return (h ^ v) * 0x100000001b3ull + (h >> 29); }
std::uint64_t bits_of(float v) {
    if (v == 0) v = 0;  // -0 and +0 compare equal, so they hash alike
    std::uint32_t u;
    std::memcpy(&u, &v, sizeof u);
    return u;
}
std::size_t name_rank(const std::vector<std::string_view>& names, std::string_view n, bool& found) {
    const auto it = std::lower_bound(names.begin(), names.end(), n);
    found = it != names.end() && *it == n;
    return std::size_t(it - names.begin());
}
void sort_unique(std::vector<std::string_view>& v) {
    std::sort(v.begin(), v.end());
    v.erase(std::unique(v.begin(), v.end()), v.end());
}
}  // namespace

SortKeyTable::Rest SortKeyTable::rest_of(const SortFields& f) {
    const MeshRenderer& r = *f.mr;
    using rjobs::order_float;
    Rest x;
    x.shading = {order_float(r.color.r),          order_float(r.color.g),      order_float(r.color.b),
                 order_float(r.color.a),          order_float(r.metallic),     order_float(r.roughness),
                 order_float(r.emissive.r),       order_float(r.emissive.g),   order_float(r.emissive.b),
                 order_float(r.emissiveStrength), order_float(r.clearcoat),    order_float(r.clearcoatRoughness),
                 order_float(r.sheenColor.r),     order_float(r.sheenColor.g), order_float(r.sheenColor.b),
                 order_float(r.sheenRoughness),   order_float(r.anisotropy),   order_float(r.anisotropyRotation),
                 order_float(r.specular),         order_float(r.ior)};
    x.unlit = r.unlit;
    x.receiveShadows = r.receiveShadows;
    x.decalRecv = decal_recv(r);
    x.uvNormal = {order_float(r.uvScale.x), order_float(r.uvScale.y), order_float(r.normalScale)};
    x.skinEntity = (f.anim || f.lightmapped) ? f.entity.bits() : std::uint64_t(0);
    x.probeKey = f.probeKey;
    x.material = name_of(f.material);
    x.paramsHash = f.paramsHash;
    x.colorsHash = f.colorsHash;
    x.flash = {order_float(f.flash.r), order_float(f.flash.g), order_float(f.flash.b), order_float(f.flash.a)};
    std::uint64_t h = 0xcbf29ce484222325ull;
    for (float v : x.shading) h = mix(h, bits_of(v));
    for (float v : x.uvNormal) h = mix(h, bits_of(v));
    for (float v : x.flash) h = mix(h, bits_of(v));
    h = mix(h, std::uint64_t(x.unlit) | std::uint64_t(x.receiveShadows) << 1 | std::uint64_t(x.decalRecv) << 2);
    h = mix(h, x.skinEntity);
    h = mix(h, x.probeKey);
    h = mix(h, std::hash<std::string_view>{}(x.material));
    h = mix(h, x.paramsHash);
    h = mix(h, x.colorsHash);
    x.hash = h;
    return x;
}

// The field order of the old comparator (order_key).
bool SortKeyTable::rest_less(const Rest& a, const Rest& b) {
    return std::tie(a.shading, a.unlit, a.receiveShadows, a.uvNormal, a.skinEntity, a.material, a.paramsHash,
                    a.colorsHash, a.flash, a.decalRecv, a.probeKey) < std::tie(b.shading, b.unlit, b.receiveShadows, b.uvNormal,
                                                                   b.skinEntity, b.material, b.paramsHash, b.colorsHash,
                                                                   b.flash, b.decalRecv, b.probeKey);
}

void SortKeyTable::clear() {
    valid_ = false;
    overflow_ = nullptr;
    meshNames_.clear();
    texNames_.clear();
    rests_.clear();
    meshRank_.clear();
    texRank_.clear();
}

namespace {
// Gives each distinct asset (by pointer) an index in first-seen order; `last` makes a run of items with the same asset (the
// common case) one comparison.
struct Interner {
    std::unordered_map<const void*, std::uint32_t>& index;
    std::vector<std::pair<const void*, std::string_view>>& list;
    const void* last = nullptr;
    std::uint32_t lastIndex = 0;
    bool haveLast = false;
    std::uint32_t operator()(const void* p, std::string_view name) {
        if (haveLast && p == last) return lastIndex;
        const auto [it, fresh] = index.try_emplace(p, std::uint32_t(list.size()));
        if (fresh) list.emplace_back(p, name);
        haveLast = true;
        last = p;
        lastIndex = it->second;
        return lastIndex;
    }
};

// Ranks the distinct assets by name, against the sorted distinct `names` (which hold at least their names), and points the
// pointer map at the ranks from then on.
void rank_assets(const std::vector<std::string_view>& names,
                 const std::vector<std::pair<const void*, std::string_view>>& list,
                 std::unordered_map<const void*, std::uint32_t>& index, std::vector<std::uint32_t>& rankOfAsset) {
    rankOfAsset.resize(list.size());
    for (std::size_t d = 0; d < list.size(); ++d) {
        bool found = false;
        rankOfAsset[d] = std::uint32_t(name_rank(names, list[d].second, found));
        index[list[d].first] = rankOfAsset[d];
    }
}
}  // namespace

bool SortKeyTable::build(const std::vector<SortFields>& items, const std::vector<std::string_view>& extraMeshNames,
                         std::vector<std::uint64_t>& keys) {
    clear();
    const std::size_t n = items.size();
    keys.assign(n, 0);
    if (std::uint64_t(n) > 0xFFFFFFFFull) {  // also on 32-bit size_t (wasm)
        overflow_ = "items";
        return false;
    }
    // The distinct assets first (by pointer, a few per scene), then their names: sorting and comparing strings is done once
    // per distinct asset instead of three times per item.
    meshAssets_.clear();
    texAssets_.clear();
    itemMesh_.resize(n);
    itemTex_.resize(n);
    itemNormal_.resize(n);
    {
        Interner meshes{meshRank_, meshAssets_}, texes{texRank_, texAssets_};
        for (std::size_t i = 0; i < n; ++i) {
            const SortFields& f = items[i];
            itemMesh_[i] = meshes(f.mesh, name_of(f.mesh));
            itemTex_[i] = texes(f.tex, name_of(f.tex));
            itemNormal_[i] = texes(f.normalTex, name_of(f.normalTex));
        }
    }
    meshNames_ = extraMeshNames;
    for (const auto& a : meshAssets_) meshNames_.push_back(a.second);
    for (const auto& a : texAssets_) texNames_.push_back(a.second);
    sort_unique(meshNames_);
    sort_unique(texNames_);
    if (meshNames_.size() > (std::size_t(1) << kSortMeshBits)) {
        overflow_ = "meshes";
        return false;
    }
    if (texNames_.size() > (std::size_t(1) << kSortTexBits)) {  // kSortNormalBits is the same: one table of names
        overflow_ = "textures";
        return false;
    }
    rank_assets(meshNames_, meshAssets_, meshRank_, meshAssetRank_);
    rank_assets(texNames_, texAssets_, texRank_, texAssetRank_);
    // The distinct Rests: items sorted by hash, equal ones found inside a run of equal hashes.
    all_.resize(n);
    byHash_.resize(n);
    for (std::size_t i = 0; i < n; ++i) {
        all_[i] = rest_of(items[i]);
        byHash_[i] = {all_[i].hash, std::uint32_t(i)};
    }
    std::sort(byHash_.begin(), byHash_.end());
    distinctRep_.clear();  // the index of the first item of each distinct Rest
    distinctOf_.resize(n);
    for (std::size_t i = 0; i < n;) {
        std::size_t j = i;
        while (j < n && byHash_[j].first == byHash_[i].first) ++j;
        const std::size_t runFirst = distinctRep_.size();
        for (std::size_t k = i; k < j; ++k) {
            const Rest& r = all_[byHash_[k].second];
            std::size_t d = runFirst;
            while (d < distinctRep_.size() &&
                   (rest_less(r, all_[distinctRep_[d]]) || rest_less(all_[distinctRep_[d]], r)))
                ++d;
            if (d == distinctRep_.size()) distinctRep_.push_back(byHash_[k].second);
            distinctOf_[byHash_[k].second] = std::uint32_t(d);
        }
        i = j;
    }
    perm_.resize(distinctRep_.size());
    for (std::size_t d = 0; d < perm_.size(); ++d) perm_[d] = std::uint32_t(d);
    std::sort(perm_.begin(), perm_.end(), [&](std::uint32_t a, std::uint32_t b) {
        return rest_less(all_[distinctRep_[a]], all_[distinctRep_[b]]);
    });
    rankOf_.resize(perm_.size());
    rests_.reserve(perm_.size());
    for (std::size_t k = 0; k < perm_.size(); ++k) {
        rankOf_[perm_[k]] = std::uint32_t(k);
        rests_.push_back(all_[distinctRep_[perm_[k]]]);
    }
    if (rests_.size() > (std::size_t(1) << kSortRestBits)) {
        overflow_ = "values";
        return false;
    }
    for (std::size_t i = 0; i < n; ++i)
        if (!pack_sort_key(meshAssetRank_[itemMesh_[i]], texAssetRank_[itemTex_[i]], texAssetRank_[itemNormal_[i]],
                           rankOf_[distinctOf_[i]], keys[i])) {
            overflow_ = "values";  // not reachable: every rank is below its limit
            return false;
        }
    // A table that stays small between frames keeps its buffers; one that held a huge frame lets them go.
    release_peak(all_, n);
    release_peak(byHash_, n);
    release_peak(distinctRep_, n);
    release_peak(distinctOf_, n);
    release_peak(perm_, n);
    release_peak(rankOf_, n);
    release_peak(itemMesh_, n);
    release_peak(itemTex_, n);
    release_peak(itemNormal_, n);
    valid_ = true;
    return true;
}

bool SortKeyTable::key_of(const SortFields& f, std::uint64_t& key) const {
    if (!valid_) return false;
    // By pointer when the asset is one of the frame's items; by name for one that is not (a lod level, a render target).
    auto rank = [](const std::unordered_map<const void*, std::uint32_t>& byPtr,
                   const std::vector<std::string_view>& names, const void* p, std::string_view name,
                   std::uint64_t& out) {
        const auto it = byPtr.find(p);
        if (it != byPtr.end()) {
            out = it->second;
            return true;
        }
        bool found = false;
        out = name_rank(names, name, found);
        return found;
    };
    std::uint64_t m = 0, t = 0, nm = 0;
    if (!rank(meshRank_, meshNames_, f.mesh, name_of(f.mesh), m) ||
        !rank(texRank_, texNames_, f.tex, name_of(f.tex), t) ||
        !rank(texRank_, texNames_, f.normalTex, name_of(f.normalTex), nm))
        return false;
    const Rest r = rest_of(f);
    const auto it = std::lower_bound(rests_.begin(), rests_.end(), r, rest_less);
    if (it == rests_.end() || rest_less(r, *it)) return false;
    return pack_sort_key(m, t, nm, std::uint64_t(it - rests_.begin()), key);
}

int select_lights(std::vector<LightData>& lights, std::size_t maxCount, std::size_t maxDirectional) {
    std::stable_sort(lights.begin(), lights.end(), [](const LightData& a, const LightData& b) {
        if (a.rank != b.rank) return a.rank < b.rank;
        // A NaN score (a NaN light position) counts as the lowest, so the order stays a strict weak one.
        return rjobs::order_float(-a.score) < rjobs::order_float(-b.score);
    });
    int dropped = 0;
    // The directional lights (rank 0 and 1) come first: the least bright ones past maxDirectional are left out.
    std::size_t directional = 0;
    while (directional < lights.size() && lights[directional].rank < 2) ++directional;
    if (directional > maxDirectional) {
        lights.erase(lights.begin() + std::ptrdiff_t(maxDirectional), lights.begin() + std::ptrdiff_t(directional));
        dropped += int(directional - maxDirectional);
    }
    if (lights.size() > maxCount) {
        dropped += int(lights.size() - maxCount);
        lights.resize(maxCount);
    }
    return dropped;
}

}  // namespace fa::render
