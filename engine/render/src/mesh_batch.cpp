#include "mesh_batch.h"

#include <algorithm>
#include <cstdint>
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
            const Vec3 p = m.transform_point({(i & 1) ? bmax.x : bmin.x, (i & 2) ? bmax.y : bmin.y, (i & 4) ? bmax.z : bmin.z});
            outMin = min(outMin, p);
            outMax = max(outMax, p);
        }
}

namespace {
auto material_key(const MeshItem& a) {
    const MeshRenderer& r = *a.mr;
    return std::make_tuple(a.mesh, a.tex, a.normalTex, r.color.r, r.color.g, r.color.b, r.color.a, r.metallic, r.roughness,
                           r.emissive.r, r.emissive.g, r.emissive.b, r.unlit, r.receiveShadows, r.uvScale.x, r.uvScale.y,
                           r.normalScale, a.anim, a.material, a.paramsHash, a.colorsHash, a.flash.r, a.flash.g, a.flash.b, a.flash.a);
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
    return std::make_tuple(name_of(a.mesh), name_of(a.tex), name_of(a.normalTex), order_float(r.color.r),
                           order_float(r.color.g), order_float(r.color.b), order_float(r.color.a),
                           order_float(r.metallic), order_float(r.roughness), order_float(r.emissive.r),
                           order_float(r.emissive.g), order_float(r.emissive.b), r.unlit, r.receiveShadows,
                           order_float(r.uvScale.x), order_float(r.uvScale.y), order_float(r.normalScale),
                           a.anim ? a.entity.bits() : std::uint64_t(0), name_of(a.material), a.paramsHash,
                           a.colorsHash, order_float(a.flash.r), order_float(a.flash.g), order_float(a.flash.b),
                           order_float(a.flash.a));
}

// Items that can share one instanced draw have the same mesh, textures and every MeshRenderer value the shader reads.
bool same_material(const MeshItem& a, const MeshItem& b) { return material_key(a) == material_key(b); }
bool material_less(const MeshItem& a, const MeshItem& b) { return order_key(a) < order_key(b); }

// The items of a camera are sorted by material as jobs from this many on, in chunks of kSortGrain (render_jobs.h:
// the same order as one std::stable_sort).
constexpr std::size_t kParallelSortItems = 1024;
constexpr std::size_t kSortGrain = 256;
}  // namespace

void build_batches(std::vector<MeshItem>& items, bool sortByMaterial, std::vector<MeshBatch>& batches,
                   std::vector<Mat4>& mainMats, std::vector<Mat4>& shadowMats) {
    if (sortByMaterial) rjobs::stable_sort("render.sort_meshes", items, material_less, kParallelSortItems, kSortGrain);
    for (std::size_t i = 0; i < items.size(); ++i) {
        if (batches.empty() || !same_material(items[batches.back().rep], items[i])) {
            MeshBatch b;
            b.rep = i;
            b.mainFirst = std::uint32_t(mainMats.size());
            b.shadowFirst = std::uint32_t(shadowMats.size());
            batches.push_back(b);
        }
        MeshBatch& b = batches.back();
        if (items[i].visible) { mainMats.push_back(items[i].model); ++b.mainCount; }
        if (items[i].casts) { shadowMats.push_back(items[i].model); ++b.shadowCount; }
    }
}

int select_lights(std::vector<LightData>& lights, std::size_t maxCount) {
    std::stable_sort(lights.begin(), lights.end(), [](const LightData& a, const LightData& b) {
        if (a.rank != b.rank) return a.rank < b.rank;
        return a.score > b.score;
    });
    if (lights.size() <= maxCount) return 0;
    const int dropped = int(lights.size() - maxCount);
    lights.resize(maxCount);
    return dropped;
}

}  // namespace fa::render
