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
                           r.roughness, r.emissive.r, r.emissive.g, r.emissive.b, r.emissiveStrength, r.unlit,
                           r.receiveShadows, r.uvScale.x, r.uvScale.y, r.normalScale, a.anim, a.material, a.paramsHash,
                           a.colorsHash, a.flash.r, a.flash.g, a.flash.b, a.flash.a);
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
        order_float(r.emissiveStrength), r.unlit, r.receiveShadows, order_float(r.uvScale.x), order_float(r.uvScale.y),
        order_float(r.normalScale), a.anim ? a.entity.bits() : std::uint64_t(0), name_of(a.material), a.paramsHash,
        a.colorsHash, order_float(a.flash.r), order_float(a.flash.g), order_float(a.flash.b), order_float(a.flash.a));
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
                   std::vector<Mat4>& mainMats, std::vector<Mat4>& shadowMats) {
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
            b.shadowFirst = std::uint32_t(shadowMats.size());
            batches.push_back(b);
        }
        MeshBatch& b = batches.back();
        if (items[i].visible) {
            mainMats.push_back(items[i].model);
            ++b.mainCount;
        }
        if (items[i].casts) {
            shadowMats.push_back(items[i].model);
            ++b.shadowCount;
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
    x.shading = {order_float(r.color.r),         order_float(r.color.g),    order_float(r.color.b),
                 order_float(r.color.a),         order_float(r.metallic),   order_float(r.roughness),
                 order_float(r.emissive.r),      order_float(r.emissive.g), order_float(r.emissive.b),
                 order_float(r.emissiveStrength)};
    x.unlit = r.unlit;
    x.receiveShadows = r.receiveShadows;
    x.uvNormal = {order_float(r.uvScale.x), order_float(r.uvScale.y), order_float(r.normalScale)};
    x.skinEntity = f.anim ? f.entity.bits() : std::uint64_t(0);
    x.material = name_of(f.material);
    x.paramsHash = f.paramsHash;
    x.colorsHash = f.colorsHash;
    x.flash = {order_float(f.flash.r), order_float(f.flash.g), order_float(f.flash.b), order_float(f.flash.a)};
    std::uint64_t h = 0xcbf29ce484222325ull;
    for (float v : x.shading) h = mix(h, bits_of(v));
    for (float v : x.uvNormal) h = mix(h, bits_of(v));
    for (float v : x.flash) h = mix(h, bits_of(v));
    h = mix(h, std::uint64_t(x.unlit) | std::uint64_t(x.receiveShadows) << 1);
    h = mix(h, x.skinEntity);
    h = mix(h, std::hash<std::string_view>{}(x.material));
    h = mix(h, x.paramsHash);
    h = mix(h, x.colorsHash);
    x.hash = h;
    return x;
}

// The field order of the old comparator (order_key).
bool SortKeyTable::rest_less(const Rest& a, const Rest& b) {
    return std::tie(a.shading, a.unlit, a.receiveShadows, a.uvNormal, a.skinEntity, a.material, a.paramsHash,
                    a.colorsHash, a.flash) < std::tie(b.shading, b.unlit, b.receiveShadows, b.uvNormal, b.skinEntity,
                                                      b.material, b.paramsHash, b.colorsHash, b.flash);
}

bool SortKeyTable::build(const std::vector<SortFields>& items, const std::vector<std::string_view>& extraMeshNames,
                         std::vector<std::uint64_t>& keys) {
    valid_ = false;
    meshNames_.clear();
    texNames_.clear();
    rests_.clear();
    const std::size_t n = items.size();
    keys.assign(n, 0);
    if (std::uint64_t(n) > 0xFFFFFFFFull) return false;  // also on 32-bit size_t (wasm)
    meshNames_ = extraMeshNames;
    for (const SortFields& f : items) {
        meshNames_.push_back(name_of(f.mesh));
        texNames_.push_back(name_of(f.tex));
        texNames_.push_back(name_of(f.normalTex));
    }
    sort_unique(meshNames_);
    sort_unique(texNames_);
    if (meshNames_.size() > (std::size_t(1) << kSortMeshBits) || texNames_.size() > (std::size_t(1) << kSortTexBits) ||
        texNames_.size() > (std::size_t(1) << kSortNormalBits))
        return false;
    // The distinct Rests: items sorted by hash, equal ones found inside a run of equal hashes.
    std::vector<Rest> all(n);
    std::vector<std::pair<std::uint64_t, std::uint32_t>> byHash(n);
    for (std::size_t i = 0; i < n; ++i) {
        all[i] = rest_of(items[i]);
        byHash[i] = {all[i].hash, std::uint32_t(i)};
    }
    std::sort(byHash.begin(), byHash.end());
    std::vector<Rest> distinct;
    std::vector<std::uint32_t> distinctOf(n);
    for (std::size_t i = 0; i < n;) {
        std::size_t j = i;
        while (j < n && byHash[j].first == byHash[i].first) ++j;
        const std::size_t runFirst = distinct.size();
        for (std::size_t k = i; k < j; ++k) {
            const Rest& r = all[byHash[k].second];
            std::size_t d = runFirst;
            while (d < distinct.size() && (rest_less(r, distinct[d]) || rest_less(distinct[d], r))) ++d;
            if (d == distinct.size()) distinct.push_back(r);
            distinctOf[byHash[k].second] = std::uint32_t(d);
        }
        i = j;
    }
    std::vector<std::uint32_t> perm(distinct.size());
    for (std::size_t d = 0; d < perm.size(); ++d) perm[d] = std::uint32_t(d);
    std::sort(perm.begin(), perm.end(),
              [&](std::uint32_t a, std::uint32_t b) { return rest_less(distinct[a], distinct[b]); });
    std::vector<std::uint32_t> rankOf(distinct.size());
    rests_.reserve(distinct.size());
    for (std::size_t k = 0; k < perm.size(); ++k) {
        rankOf[perm[k]] = std::uint32_t(k);
        rests_.push_back(distinct[perm[k]]);
    }
    if (rests_.size() > (std::size_t(1) << kSortRestBits)) return false;
    for (std::size_t i = 0; i < n; ++i) {
        bool ok;
        const std::uint64_t m = name_rank(meshNames_, name_of(items[i].mesh), ok);
        const std::uint64_t t = name_rank(texNames_, name_of(items[i].tex), ok);
        const std::uint64_t nm = name_rank(texNames_, name_of(items[i].normalTex), ok);
        if (!pack_sort_key(m, t, nm, rankOf[distinctOf[i]], keys[i])) return false;
    }
    valid_ = true;
    return true;
}

bool SortKeyTable::key_of(const SortFields& f, std::uint64_t& key) const {
    if (!valid_) return false;
    bool okMesh, okTex, okNormal;
    const std::uint64_t m = name_rank(meshNames_, name_of(f.mesh), okMesh);
    const std::uint64_t t = name_rank(texNames_, name_of(f.tex), okTex);
    const std::uint64_t nm = name_rank(texNames_, name_of(f.normalTex), okNormal);
    if (!okMesh || !okTex || !okNormal) return false;
    const Rest r = rest_of(f);
    const auto it = std::lower_bound(rests_.begin(), rests_.end(), r, rest_less);
    if (it == rests_.end() || rest_less(r, *it)) return false;
    return pack_sort_key(m, t, nm, std::uint64_t(it - rests_.begin()), key);
}

int select_lights(std::vector<LightData>& lights, std::size_t maxCount) {
    std::stable_sort(lights.begin(), lights.end(), [](const LightData& a, const LightData& b) {
        if (a.rank != b.rank) return a.rank < b.rank;
        // A NaN score (a NaN light position) counts as the lowest, so the order stays a strict weak one.
        return rjobs::order_float(-a.score) < rjobs::order_float(-b.score);
    });
    if (lights.size() <= maxCount) return 0;
    const int dropped = int(lights.size() - maxCount);
    lights.resize(maxCount);
    return dropped;
}

}  // namespace fa::render
