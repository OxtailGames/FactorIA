// CPU side of the 3D pass, free of any GPU call so tests can look at it: frustum culling, instancing batches and the
// choice of the lights that fit the shader.
#pragma once

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <string_view>
#include <unordered_map>
#include <utility>
#include <vector>

#include "probe_select.h"
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
    std::uint64_t castMask =
        1;  // with `casts`: bit v = drawn into shadow view v (a cascade of the sun, a face of a local light)
    std::uint64_t sortKey = 0;  // SortKeyTable: the order of the material fields as one integer (valid when `keyed`)
    bool keyed = false;         // sortKey is set; an unkeyed item is ordered by the comparator (build_batches)
    bool noCull = false;        // never frustum-culled: a mesh material with buffers and no MeshRenderer.instanceBounds
    // Lit by a baked lightmap (M73.4a): drawn with `lm.mesh->parts` and the page rectangle of its entity, so never batched with another.
    LightmapUse lm;
    // Baked light probes (M73.4d): the SH the item receives instead of the sky ambient (null = none; points into the RenderScene)
    // and its quantised key (probe_light_key, 0 = none). Items with different keys never share a draw.
    const ProbeLight* probe = nullptr;
    std::uint64_t probeKey = 0;  // also folds in `refl`: items that reflect other probes never share a draw either
    // The reflection probes the item reflects (M73-P3c, probe_select.h): up to two, with their shares of the light; none = the sky.
    ProbePick refl;
};

// What the decal pass of the shader needs to know of a mesh (MeshRenderer.receiveDecals / decalLayer): 0 = it receives none, else
// 1 + the layer (0..15). Part of every batch key: two meshes with different values never share a draw.
inline int decal_recv(const MeshRenderer& mr) {
    return mr.receiveDecals ? std::clamp<int>(mr.decalLayer, 0, 15) + 1 : 0;
}

// What the subsurface pass of the shader reads of a mesh (MeshRenderer.subsurface*, M73.5): strength, radius in metres and the three channel
// spreads, each finite and clamped; all zero when the strength is 0 (the radius and the colour of a mesh that does not scatter are not part
// of a batch's key: two such meshes still share a draw). Part of every batch key: two meshes with different values never share a draw.
inline std::array<float, 5> subsurface_of(const MeshRenderer& mr) {
    auto fin = [](float v, float lo, float hi) { return std::isfinite(v) ? std::clamp(v, lo, hi) : lo; };
    const float k = fin(mr.subsurface, 0.0f, 1.0f);
    if (!(k > 0.0f)) return {0.0f, 0.0f, 0.0f, 0.0f, 0.0f};
    return {k, fin(mr.subsurfaceRadius, 0.0f, 0.5f), fin(mr.subsurfaceColor.r, 0.0f, 1.0f),
            fin(mr.subsurfaceColor.g, 0.0f, 1.0f), fin(mr.subsurfaceColor.b, 0.0f, 1.0f)};
}

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
    bool lightmapped =
        false;  // a batch of its own, like a skinned one: its entity is part of what the batches differ by
    std::uint64_t probeKey = 0;  // probe_light_key: items with other light probe SH are other batches
};
inline SortFields fields_of(const MeshItem& m) {
    return {m.mesh,       m.tex,   m.normalTex,          m.mr,      m.entity, m.anim, m.material, m.paramsHash,
            m.colorsHash, m.flash, m.lm.mesh != nullptr, m.probeKey};
}

// The 64-bit sort key: four fields, most significant first, each the RANK of the value among those of the frame (never
// an address or an id that changes from one run to the next): the mesh by name, the colour texture, the normal map by
// name (one name table for both), and "rest" = every other value the batches differ by (MeshRenderer colours and
// factors and layers, skinning entity, material by name, override hashes, flash), by the tuple the old comparator used. The ranks
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
        // colour rgba, metallic, roughness, emissive rgb, emissiveStrength, then the material layers (M73.6a): clearcoat,
        // clearcoatRoughness, sheenColor rgb, sheenRoughness, anisotropy, anisotropyRotation, specular, ior, then the
        // transmission and the volume (M73.6b): transmission, thickness, attenuationColor rgb, attenuationDistance, then the
        // subsurface (M73.5, subsurface_of: strength, radius, colour rgb)
        std::array<float, 31> shading;
        bool unlit = false, receiveShadows = true;
        int decalRecv = 1;              // decal_recv()
        std::array<float, 3> uvNormal;  // uvScale x, y, normalScale
        std::uint64_t skinEntity = 0;   // Entity::bits() of a skinned item, else 0
        std::uint64_t probeKey = 0;     // SortFields::probeKey
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
// mainMats[mainFirst .. +mainCount).
// The most shadow views of a frame: the cascades of the sun, then the tile of each shadowed spot light and the six faces of each
// shadowed point light (shadow_cascades.h, local_shadows.h). A view is one tile of the shadow atlas drawn with one matrix.
constexpr int kMaxShadowViews = 64;

// The casters of one shadow view inside a batch: shadowMats[first .. +count), and the per-instance params of the same run at
// shadowData[extra ..) (a material with "instanced" params).
struct ShadowRun {
    std::uint32_t view = 0, first = 0, count = 0, extra = 0;
};

struct MeshBatch {
    std::size_t rep = 0;  // index in `items` of the first item (stands for the material of the whole batch)
    std::uint32_t mainFirst = 0, mainCount = 0;
    // The shadow runs of the batch, one per view that holds a caster of it, in ascending view order: runs[runFirst .. +runCount) of the
    // vector build_batches filled (the one the caller passed).
    // Neighbouring batches that differ only in their probe SH (MeshItem::probeKey) share one set of runs, held by the first of
    // them (the others have runCount 0): the shadow pass never reads the SH. shadowEnd = the end (in `items`) of the casters
    // of those runs.
    std::uint32_t runFirst = 0, runCount = 0, shadowEnd = 0;
    // The per-instance params of a material with "instanced" params (pack_instance_params): instanceVec4 vec4 for each
    // instance, at mainData[mainExtra ..) (floats) for the visible items; the casters' are ShadowRun::extra. instanceVec4 is 0
    // for a batch without them.
    std::uint32_t instanceVec4 = 0, mainExtra = 0;
};

// Groups `items` (sorted in place by material when `sortByMaterial`, otherwise kept in order and only neighbours merge:
// blended meshes stay far-to-near).
// The casters (`casts`, one run per bit of castMask) go to shadowMats and, as ShadowRun entries in `runs` (null = not kept), per batch.
void build_batches(std::vector<MeshItem>& items, bool sortByMaterial, std::vector<MeshBatch>& batches,
                   std::vector<Mat4>& mainMats, std::vector<Mat4>& shadowMats, std::vector<ShadowRun>* runs = nullptr);

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
// matrices, and sets the batch's instanceVec4 and mainExtra (and the extra of its shadow runs). Entities with different values share the
// batch: the values are not part of the batch key (MaterialHashCache::refresh). Batches of other materials are left
// alone. `cache` (null = none) keeps the packed values of each entity between frames. `runs` is the vector build_batches filled: each
// run of a batch gets its `extra`.
void pack_instance_extras(const std::vector<MeshItem>& items, std::vector<MeshBatch>& batches,
                          std::vector<float>& mainData, std::vector<float>& shadowData,
                          InstanceParamCache* cache = nullptr, std::vector<ShadowRun>* runs = nullptr);

// The directional lights of a view: every cluster loops over all of them, so there are at most this many (the shader's light table
// keeps them first).
inline constexpr int kMaxDirectionalLights = 32;

// Contact shadows (M73.2c) fade out between half of this distance from the camera and this distance (metres): a pixel of the prepass covers
// too much of the world there for a ray of a few centimetres.
inline constexpr float kContactShadowFadeEnd = 40.0f;

struct LightData {
    Vec4 pos, color, dir;
    int rank = 2;     // 0 = shadow-casting directional, 1 = directional, 2 = point/spot
    float score = 0;  // how relevant the light is to the camera (larger = keep first)
    // A spot's cos(innerAngle) (the cone inside which it is at full strength); 2 = Light.innerAngle 0, the default fade of the
    // outer quarter of the cone (shaders/light_data.glsl).
    float cosInner = 2.0f;
    // The extension texels (shaders/light_data.glsl, +4 .. +7): an area light's axes and size, a cookie's or an IES profile's atlas
    // tile. Only written when `hasExt`; a view where any light has them stores every light with 8 texels (LightTexture::stride).
    Vec4 ext[4];
    bool hasExt = false;
    float extent =
        0;  // an area light: the radius of the sphere around its emitter (the range is measured from its surface)
    // The shadow of a point or spot light (Light.castShadows and the fields after it, collect_lights); the sun's are SunShadow.
    struct LocalShadow {
        bool casts = false;
        int resolution = 0;  // Light.shadowResolution: texels per side of a tile (0 = from the distance to the camera)
        float bias = 0, normalBias = 0;  // Light.shadowBias / shadowNormalBias in metres (0 = automatic)
        float softness = 1;              // Light.shadowSoftness
        float distance = 0;              // metres from the camera past which the shadow fades out (0 = no limit)
        int filter = 0;                  // 0 pcf, 1 hard, 2 pcss (Light.shadowFilter)
        float spotAngle = 0;             // a spot's cone half angle in degrees (0 for a point light and an area light)
        float emitter = 0;  // an area light: its mean full size in metres, the PCSS light size (0 = not an area light)
    } shadow;
    bool baked =
        false;  // Light.mode Baked: its direct light is in the lightmaps, so a lightmapped surface skips it (M73.4a)
    // Light.volumetric (M73.5): the strength of this light's shafts in the volumetric fog; 0 = none.
    float volumetric = 0.0f;
    // Light.contactShadowLength (M73.2c) in metres when SceneSettings.contactShadows is on and the frame draws contact shadows; 0 = none.
    // Packed in the y of the light's texel of the shadow region of the light data texture (shaders/light_data.glsl).
    float contactLength = 0.0f;
};

// Orders the lights by relevance (the shadow caster first, then directional lights, then point and spot lights by
// brightness over distance to the camera: `score`) and drops what exceeds `maxCount` lights or `maxDirectional` directional ones.
// Returns how many were dropped.
int select_lights(std::vector<LightData>& lights, std::size_t maxCount,
                  std::size_t maxDirectional = std::size_t(kMaxDirectionalLights));

}  // namespace fa::render
