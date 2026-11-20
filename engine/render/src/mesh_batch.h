// CPU side of the 3D pass, free of any GPU call so tests can look at it: frustum culling, instancing batches and the
// choice of the lights that fit the shader.
#pragma once

#include <array>
#include <cstdint>
#include <string_view>
#include <unordered_map>
#include <utility>
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
    bool casts = false;                 // inside a shadow map's frustum and castShadows: drawn in the shadow pass
    std::uint32_t castMask = 1;  // with `casts`: bit c = drawn into cascade c of the sun's shadow (1 = the first only)
    std::uint64_t sortKey = 0;   // SortKeyTable: the order of the material fields as one integer (valid when `keyed`)
    bool keyed = false;          // sortKey is set; an unkeyed item is ordered by the comparator (build_batches)
    bool noCull = false;  // never frustum-culled: a mesh material with buffers and no MeshRenderer.instanceBounds
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

// Lets go of the memory of a work buffer that a huge frame left behind: when its capacity is far above what this frame
// needed (`used` elements), the buffer is freed; a buffer that stays near its use keeps its capacity between frames.
template <class V>
void release_peak(V& v, std::size_t used) {
    if (v.capacity() > 4 * used + 4096) V().swap(v);
}

// The ranks of one frame's items. Rebuilt from nothing by every build() (so its content never grows across frames; the
// work buffers keep their capacity from one frame to the next instead of allocating every frame, and let it go when
// it is more than four times what a frame used plus 4096 entries: release_peak); names are views into the assets and
// components the items point to, valid while those items are.
//
// Limits (distinct NAMES among the items of ONE frame): meshes 4096 (kSortMeshBits); textures 2048 (kSortTexBits): the
// normal map ranks come from the same table of texture names, so colour and normal maps share the 2048, and the empty name
// of "no texture" counts as one; the lod levels a camera may swap in (`extraMeshNames`) count as meshes; "rest" values 2^30.
// Past a limit build() returns false (overflow() says which) and the caller sorts with the comparator.
class SortKeyTable {
public:
    // Ranks `items` and writes their keys (keys[i] for items[i]). `extraMeshNames` are meshes a camera may swap in later
    // (lods). Returns false, leaving valid() false, when a field needs more ranks than its bits hold: the caller then
    // leaves its items unkeyed and the comparator orders them.
    bool build(const std::vector<SortFields>& items, const std::vector<std::string_view>& extraMeshNames,
               std::vector<std::uint64_t>& keys);
    bool valid() const { return valid_; }
    // Which limit made the last build() return false: "meshes", "textures", "values" or "items"; nullptr when it fitted.
    const char* overflow() const { return overflow_; }
    // Empties the table (valid() false), keeping the capacity of the work buffers.
    void clear();
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
    // Asset pointer -> rank of its name, for the items of the last build (key_of looks a camera's asset up by pointer first).
    std::unordered_map<const void*, std::uint32_t> meshRank_, texRank_;
    // Work buffers of build(), kept between frames.
    std::vector<Rest> all_;
    std::vector<std::pair<std::uint64_t, std::uint32_t>> byHash_;
    std::vector<std::uint32_t> distinctRep_, distinctOf_, perm_, rankOf_;
    std::vector<std::uint32_t> itemMesh_, itemTex_,
        itemNormal_;  // per item: index of its asset among the distinct ones
    std::vector<std::pair<const void*, std::string_view>> meshAssets_,
        texAssets_;  // the distinct assets, in first-seen order
    std::vector<std::uint32_t> meshAssetRank_, texAssetRank_;
    const char* overflow_ = nullptr;
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
// The most cascades of the sun's shadow a batch lists (render's kMaxShadowCascades, shadow_cascades.h).
constexpr int kMaxBatchCascades = 4;

struct MeshBatch {
    std::size_t rep = 0;  // index in `items` of the first item (stands for the material of the whole batch)
    std::uint32_t mainFirst = 0, mainCount = 0, shadowFirst = 0, shadowCount = 0;
    // The casters of each cascade of the sun's shadow: shadowMats[cascadeFirst[c] .. +cascadeCount[c]) (the casters whose castMask has
    // bit c), and the per-instance params of the same run at shadowData[cascadeExtra[c] ..). shadowFirst, shadowCount and shadowExtra
    // are those of cascade 0, the only one when there is one shadow map.
    std::uint32_t cascadeFirst[kMaxBatchCascades] = {}, cascadeCount[kMaxBatchCascades] = {},
                  cascadeExtra[kMaxBatchCascades] = {};
    // The per-instance params of a material with "instanced" params (pack_instance_params): instanceVec4 vec4 for each
    // instance, at mainData[mainExtra ..) (floats) for the visible items and shadowData[shadowExtra ..) for the
    // casters, in the order of the matrices. instanceVec4 is 0 for a batch without them.
    std::uint32_t instanceVec4 = 0, mainExtra = 0, shadowExtra = 0;
};

// Groups `items` (sorted in place by material when `sortByMaterial`, otherwise kept in order and only neighbours merge:
// blended meshes stay far-to-near).
void build_batches(std::vector<MeshItem>& items, bool sortByMaterial, std::vector<MeshBatch>& batches,
                   std::vector<Mat4>& mainMats, std::vector<Mat4>& shadowMats, int cascades = 1);

// The packed per-instance params (pack_instance_params) of each entity, kept between frames: 10 000 instances of one
// material must not run the param lookup 10 000 times per frame and camera. An entry is valid while the material is the
// same build (pointer and generation) and MeshRenderer.materialParams equals the copy it was packed from (a JSON
// comparison, like MaterialHashCache: nothing counts the writes of a component). Entities without overrides share one
// block per material. One thread at a time (pack_instance_extras runs on the thread that plans the draw).
class InstanceParamCache {
public:
    // Starts the frame `serial` (Renderer::Impl::frameSerial); calling it again for the same serial is a no-op. Entries
    // nobody asked for in the previous frame are dropped.
    void begin_frame(std::uint64_t serial);
    // The `m.instanceVec4 * 4` floats of `mr` for the material `m` (equal to what pack_instance_params writes); the
    // pointer is valid until the next begin_frame or clear.
    const float* get(Entity entity, const MeshRenderer& mr, MaterialAsset& m);
    void clear();
    std::size_t size() const { return entries_.size(); }
    // Packs done (not served from the cache) since the cache was made; a test looks at it.
    std::uint64_t packed() const { return packed_; }

private:
    struct Entry {
        Json overrides;  // the materialParams the floats were packed from
        const MaterialAsset* material = nullptr;
        int generation = -1;
        std::vector<float> floats;
        std::uint64_t seen = 0;
    };
    struct Default {
        int generation = -1;
        std::vector<float> floats;
    };
    std::unordered_map<std::uint64_t, Entry> entries_;  // by Entity::bits()
    std::unordered_map<const MaterialAsset*, Default> defaults_;
    std::uint64_t serial_ = ~std::uint64_t(0);
    std::size_t touched_ = 0;  // distinct entries asked for in this frame
    std::uint64_t packed_ = 0;
};

// Packs the per-instance params of every batch whose material has instanced ones (MaterialAsset::instanceVec4, built):
// appends to `mainData` and `shadowData` the floats of each visible / casting item, in the order build_batches put the
// matrices, and sets the batch's instanceVec4, mainExtra and shadowExtra. Entities with different values share the
// batch: the values are not part of the batch key (MaterialHashCache::refresh). Batches of other materials are left
// alone. `cache` (null = none) keeps the packed values of each entity between frames.
void pack_instance_extras(const std::vector<MeshItem>& items, std::vector<MeshBatch>& batches,
                          std::vector<float>& mainData, std::vector<float>& shadowData,
                          InstanceParamCache* cache = nullptr, int cascades = 1);

// The directional lights of a view: every cluster loops over all of them, so there are at most this many (the shader's light table
// keeps them first).
inline constexpr int kMaxDirectionalLights = 32;

struct LightData {
    Vec4 pos, color, dir;
    int rank = 2;     // 0 = shadow-casting directional, 1 = directional, 2 = point/spot
    float score = 0;  // how relevant the light is to the camera (larger = keep first)
    // A spot's cos(innerAngle) (the cone inside which it is at full strength); 2 = Light.innerAngle 0, the default fade of the
    // outer quarter of the cone (shaders/light_data.glsl).
    float cosInner = 2.0f;
};

// Orders the lights by relevance (the shadow caster first, then directional lights, then point and spot lights by
// brightness over distance to the camera: `score`) and drops what exceeds `maxCount` lights or `maxDirectional` directional ones.
// Returns how many were dropped.
int select_lights(std::vector<LightData>& lights, std::size_t maxCount,
                  std::size_t maxDirectional = std::size_t(kMaxDirectionalLights));

}  // namespace fa::render
