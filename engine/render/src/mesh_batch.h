// CPU side of the 3D pass, free of any GPU call so tests can look at it: frustum culling, instancing batches and the
// choice of the lights that fit the shader.
#pragma once

#include <array>
#include <cstdint>
#include <string_view>
#include <vector>

#include "render_internal.h"

namespace fa::render {

// One MeshRenderer entity, gathered for this frame.
struct MeshItem {
    MeshAsset* mesh = nullptr;
    Mat4 model;
    const MeshRenderer* mr = nullptr;
    Entity entity;                      // the MeshRenderer's entity
    TextureAsset* tex = nullptr;        // MeshRenderer.texture (null = the glTF material's, or white)
    TextureAsset* normalTex = nullptr;  // MeshRenderer.normalMap (null = the glTF material's, or none)
    float dist = 0;                     // distance to the camera (blended meshes are drawn far to near)
    MaterialAsset* material =
        nullptr;  // MeshRenderer.material (null = none); a failed one is drawn with the error material
    std::size_t paramsHash =
        0;  // hash of MeshRenderer.materialParams (0 = no overrides): different overrides never share a draw
    std::size_t colorsHash = 0;  // hash of MeshRenderer.materialColors (0 = none): different colours never share a draw
    Color flash{0, 0, 0, 0};     // feel.h flash: rgb = the colour, a = how much of it replaces the shading (0 = none)
    const Animator* anim =
        nullptr;  // set when the mesh is drawn skinned by this Animator's palette: never batched with another
    Vec3 bmin{0, 0, 0}, bmax{0, 0, 0};  // model-space bounds used for culling (the mesh's, or the skinned ones)
    bool visible = true;                // inside the camera frustum: drawn in the main pass
    bool casts = false;                 // inside the light frustum and castShadows: drawn in the shadow pass
    std::uint64_t sortKey = 0;  // SortKeyTable: the order of the material fields as one integer (valid when `keyed`)
    bool keyed = false;         // sortKey is set; an unkeyed item is ordered by the comparator (build_batches)
};

// What the sort of the opaque meshes reads of an item (a MeshItem, or a SceneMesh before a camera makes its item).
struct SortFields {
    const MeshAsset* mesh = nullptr;
    const TextureAsset* tex = nullptr;
    const TextureAsset* normalTex = nullptr;
    const MeshRenderer* mr = nullptr;
    Entity entity;
    const Animator* anim = nullptr;
    const MaterialAsset* material = nullptr;
    std::size_t paramsHash = 0, colorsHash = 0;
    Color flash{0, 0, 0, 0};
};
inline SortFields fields_of(const MeshItem& m) {
    return {m.mesh, m.tex, m.normalTex, m.mr, m.entity, m.anim, m.material, m.paramsHash, m.colorsHash, m.flash};
}

// The 64-bit sort key: four fields, most significant first, each the RANK of the value among those of the frame (never
// an address or an id that changes from one run to the next): the mesh by name, the colour texture, the normal map by
// name (one name table for both), and "rest" = every other value the batches differ by (MeshRenderer colours and
// factors, skinning entity, material by name, override hashes, flash), by the tuple the old comparator used. The ranks
// keep the order of the values, so sorting the keys (stable) gives the order the comparator gave, and two items have
// equal keys exactly when they compare equal.
constexpr unsigned kSortMeshBits = 12, kSortTexBits = 11, kSortNormalBits = 11, kSortRestBits = 30;
static_assert(kSortMeshBits + kSortTexBits + kSortNormalBits + kSortRestBits == 64, "the sort key is 64 bits");
// Packs the four ranks; false (key untouched) when a rank does not fit its bits.
bool pack_sort_key(std::uint64_t mesh, std::uint64_t tex, std::uint64_t normal, std::uint64_t rest, std::uint64_t& key);

// The ranks of one frame's items. Rebuilt from nothing by every build() (so it never grows across frames); names are
// views into the assets and components the items point to, valid while those items are.
class SortKeyTable {
public:
    // Ranks `items` and writes their keys (keys[i] for items[i]). `extraMeshNames` are meshes a camera may swap in later
    // (lods). Returns false, leaving valid() false, when a field needs more ranks than its bits hold: the caller then
    // leaves its items unkeyed and the comparator orders them.
    bool build(const std::vector<SortFields>& items, const std::vector<std::string_view>& extraMeshNames,
               std::vector<std::uint64_t>& keys);
    bool valid() const { return valid_; }
    // The key of an item whose mesh or textures a camera changed; false when a value is not in the table.
    bool key_of(const SortFields& f, std::uint64_t& key) const;

private:
    // Every value of an item that is not a name above, in the order of the old comparator (floats through order_float).
    struct Rest {
        std::array<float, 10> shading;  // colour rgba, metallic, roughness, emissive rgb, emissiveStrength
        bool unlit = false, receiveShadows = true;
        std::array<float, 3> uvNormal;  // uvScale x, y, normalScale
        std::uint64_t skinEntity = 0;   // Entity::bits() of a skinned item, else 0
        std::string_view material;      // by name
        std::size_t paramsHash = 0, colorsHash = 0;
        std::array<float, 4> flash;
        std::uint64_t hash = 0;  // equal for equal Rests
    };
    static Rest rest_of(const SortFields& f);
    static bool rest_less(const Rest& a, const Rest& b);
    std::vector<std::string_view> meshNames_, texNames_;  // sorted, distinct
    std::vector<Rest> rests_;                             // sorted, distinct
    bool valid_ = false;
};

// True unless every corner of the box (bmin..bmax in model space, moved by `model`) lies outside the same plane of the
// clip volume of `viewProj`. Conservative: a box near a frustum corner may pass. `zeroToOne` = D3D/Metal depth range.
bool box_in_frustum(const Mat4& viewProj, bool zeroToOne, Vec3 bmin, Vec3 bmax, const Mat4& model);

// Culling bounds of a skinned mesh: the box of its bind pose carried by every joint of the palette, all joined. A
// vertex is a convex blend of joint transforms of a bind-pose point, so it stays inside this box whatever the pose
// (a little generous when joints move far from the vertices they own, never too small).
void skinned_bounds(const std::vector<Mat4>& palette, Vec3 bmin, Vec3 bmax, Vec3& outMin, Vec3& outMax);

// A run of items drawn with one instanced draw per mesh part. The model matrices of the visible items sit at
// mainMats[mainFirst .. +mainCount), those of the shadow casters at shadowMats[shadowFirst .. +shadowCount).
struct MeshBatch {
    std::size_t rep = 0;  // index in `items` of the first item (stands for the material of the whole batch)
    std::uint32_t mainFirst = 0, mainCount = 0, shadowFirst = 0, shadowCount = 0;
};

// Groups `items` (sorted in place by material when `sortByMaterial`, otherwise kept in order and only neighbours merge:
// blended meshes stay far-to-near).
void build_batches(std::vector<MeshItem>& items, bool sortByMaterial, std::vector<MeshBatch>& batches,
                   std::vector<Mat4>& mainMats, std::vector<Mat4>& shadowMats);

struct LightData {
    Vec4 pos, color, dir;
    int rank = 2;     // 0 = shadow-casting directional, 1 = directional, 2 = point/spot
    float score = 0;  // how relevant the light is to the camera (larger = keep first)
};

// Orders the lights by relevance (the shadow caster first, then directional lights, then point and spot lights by
// brightness over distance to the camera: `score`) and drops what exceeds `maxCount`. Returns how many were dropped.
int select_lights(std::vector<LightData>& lights, std::size_t maxCount);

}  // namespace fa::render
