#include "mesh_batch.h"

#include <algorithm>
#include <tuple>

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

namespace {
auto material_key(const MeshItem& a) {
    const MeshRenderer& r = *a.mr;
    return std::make_tuple(a.mesh, a.tex, a.normalTex, r.color.r, r.color.g, r.color.b, r.color.a, r.metallic, r.roughness,
                           r.emissive.r, r.emissive.g, r.emissive.b, r.unlit, r.receiveShadows, r.uvScale.x, r.uvScale.y,
                           r.normalScale);
}

// Items that can share one instanced draw have the same mesh, textures and every MeshRenderer value the shader reads.
bool same_material(const MeshItem& a, const MeshItem& b) { return material_key(a) == material_key(b); }
bool material_less(const MeshItem& a, const MeshItem& b) { return material_key(a) < material_key(b); }
}  // namespace

void build_batches(std::vector<MeshItem>& items, bool sortByMaterial, std::vector<MeshBatch>& batches,
                   std::vector<Mat4>& mainMats, std::vector<Mat4>& shadowMats) {
    if (sortByMaterial) std::stable_sort(items.begin(), items.end(), material_less);
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
