// The 3D world of one frame, gathered once and shared by every camera job (the cameras, the render targets, the
// CameraViews): each MeshRenderer with its drawn matrix, its resolved assets, its bounds and the hashes of its
// overrides. A camera then only tests its frustum and tag mask over the list and sorts its own blended meshes
// (Renderer::Impl::gather_meshes). docs/design/ARCHITECTURE_RENDERING.md, "Rendering".
#pragma once

#include <atomic>
#include <cstdint>
#include <deque>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "fa/scene/world.h"
#include "mesh_batch.h"

namespace fa::render {

// The 3D gather of a frame (the scene's matrices, boxes and hashes, a camera's frustum tests) runs as jobs from this many
// MeshRenderers on, kMeshGrain per chunk: an item costs ~1 us (a skinned one several), a chunk a few to hand out.
constexpr std::size_t kParallelMeshes = 256;
constexpr std::size_t kMeshGrain = 64;

// The palette of glTF skin `skin` of an animator (a part is drawn with its own skin's); skin 0 when it has none for it.
inline const std::vector<Mat4>& palette_of(const Animator& a, int skin) {
    return skin > 0 && std::size_t(skin) < a.skinPalettes.size() ? a.skinPalettes[std::size_t(skin)] : a.palette;
}

// The culling box of `mesh` as `mr` is drawn: the mesh's own, or, for a skinned mesh whose Animator has a pose, the box of
// every skinned part carried by the joints of its own skin, joined with the rest. `anim` is set when the mesh is drawn
// deformed by that Animator's palette (such an item is never batched with another).
void mesh_cull_bounds(const MeshAsset& mesh, const Animator* animator, Vec3& bmin, Vec3& bmax, const Animator*& anim);

// Whether `mr` draws `mesh` as a transmissive surface (glass, liquid; M73.6b): MeshRenderer.transmission above 0, or the transmission of a
// glTF part of the model (KHR_materials_transmission) when the field is 0. A material that is a full shader draws none (it has no template
// to read the picture behind it with), and neither does an unlit mesh or a material with lighting "unlit".
bool mesh_is_transmissive(const MeshRenderer& mr, const MeshAsset& mesh, const MaterialAsset* material);

// Whether `mr` is drawn with the blended meshes (far to near) rather than the opaque ones. The alphaMode of a material
// decides; without one, a translucent colour or a blended glTF part does. A transmissive mesh (mesh_is_transmissive) is always one of them:
// it is drawn after the opaque picture is finished, because it reads it.
bool mesh_is_blended(const MeshRenderer& mr, const MeshAsset& mesh, const MaterialAsset* material);

// Hashes of MeshRenderer.materialParams and materialColors: items with different overrides never share a draw. They were
// computed (dump + hash) per mesh, per camera, per frame; now a copy of each entity's JSON is kept and a hash is made again
// only when the value differs from the copy (a JSON comparison, no allocation). Nothing in the scene module counts the
// writes of a component (any code holding the MeshRenderer may assign its fields), so comparing is the one place that
// sees every write: through the reflection, a script, a command, a prefab, the inspector or an undo.
class MaterialHashCache {
public:
    struct Entry {
        Json params, colors;  // the values the hashes are of (null = no overrides)
        std::size_t paramsHash = 0, colorsHash = 0;
        std::size_t leftOutKey =
            0;                   // the instancedKey of the material the params hash was made for (names it left out)
        std::uint64_t seen = 0;  // the frame that last asked for it
    };
    // Starts a frame: the entries it does not ask for are dropped at end_frame().
    void begin_frame() {
        ++frame_;
        touched_ = 0;
    }
    // A build over a subtree (RenderScene::build with a scopeRoot) must not call begin_frame / end_frame: it asks for the
    // entries of that subtree only, and end_frame would drop the rest, which the next frame of the whole world rehashes.
    // The entry of `e` (made if missing), marked as used this frame. Pointers stay valid until end_frame().
    Entry* touch(Entity e);
    // Makes the hashes of `entry` right for these values (nullptr = none, hash 0): when they equal the kept copy, nothing is
    // computed. "Equal" is Json::operator==, which finds 1 and 1.0 equal (and 0.0 and -0.0) while dump() prints them
    // differently ("1" and "1.0"). So after an edit from 1 to 1.0 the kept hash stays the one of "1", and two entities with
    // the same overrides written differently can hash differently, or alike, depending on the history of their edits: the
    // batches then split (or merge) by edit history. The pixels are the same either way, as the shader reads the numbers,
    // not the text. Entries of different entities may be refreshed from different threads at once.
    // `leftOut` = the names of the material's instanced params (MaterialAsset::instancedNames, `leftOutKey` its
    // instancedKey): they travel in the instance buffer, so their values are not part of the params hash and entities
    // that differ only there share a draw. Overrides with nothing else hash as none (0).
    void refresh(Entry& entry, const Json* params, const Json* colors,
                 const std::vector<std::string>* leftOut = nullptr, std::size_t leftOutKey = 0);
    // Drops the entries nobody asked for this frame (entities that died, were hidden or lost their overrides), so a slot
    // that is reused starts from nothing.
    void end_frame();
    // Both hashes of `e` in one call: touch + refresh. `material` = the entity's material (null = none): its instanced
    // params are left out of the hash, as in RenderScene::build.
    void hashes(Entity e, const Json* params, const Json* colors, std::size_t& paramsHash, std::size_t& colorsHash,
                const MaterialAsset* material = nullptr);
    std::size_t size() const { return entries_.size(); }
    // Hashes computed since the cache was made (a test looks at it: no edit, no new hash).
    std::uint64_t computed() const { return computed_.load(std::memory_order_relaxed); }
    void clear() { entries_.clear(); }

private:
    std::unordered_map<std::uint64_t, Entry> entries_;  // by Entity::bits()
    std::uint64_t frame_ = 0;
    std::size_t touched_ = 0;  // DISTINCT entries asked for this frame (a second touch of one counts once)
    std::atomic<std::uint64_t> computed_{0};
};

// One MeshRenderer of the scene.
struct SceneMesh {
    const MeshRenderer* mr = nullptr;
    Entity entity;
    Mat4 model;                   // World::drawn_matrix
    MeshAsset* mesh = nullptr;    // MeshRenderer.mesh (the nearest level: lods are chosen per camera)
    TextureAsset* tex = nullptr;  // as MeshItem
    TextureAsset* normalTex = nullptr;
    MaterialAsset* material = nullptr;
    Color flash{0, 0, 0, 0};            // feel.h flash, a = 0 when none
    const Animator* anim = nullptr;     // drawn skinned by this Animator's palette
    Vec3 bmin{0, 0, 0}, bmax{0, 0, 0};  // culling box of `mesh` (mesh_cull_bounds)
    std::size_t paramsHash = 0, colorsHash = 0;
    bool blended = false;
    bool noCull =
        false;  // reads compute buffers with no instanceBounds: never frustum-culled (MeshRenderer.instanceBounds)
    // SortKeyTable key of the item as the scene sees it (a camera redoes it for `special` ones).
    std::uint64_t sortKey = 0;
    bool keyed = false;
    LightmapUse lm;  // lit by a baked lightmap (SceneSettings.lightmaps, M73.4a); lm.mesh null = not
    // Baked light probes (M73.4d): what a mesh without a lightmap receives instead of the sky ambient; points into
    // a vector of the RenderScene (null = no probes reach it, or none are baked), probeKey = probe_light_key of it.
    const ProbeLight* probe = nullptr;
    std::uint64_t probeKey =
        0;                 // the light probe key with the reflection pick folded in (they choose different draws too)
    ProbePick refl;        // the reflection probes that reach the mesh (probe_select.h); none without volumes
    bool hasLods = false;  // MeshRenderer.lods: mesh, box and blending are chosen again per camera
    // The LodGroups above the mesh (M75.1): chain entries lodChains()[chainFirst .. + chainCount), each (group index << 4) | child
    // index of the group (15 = a child past the ninth level, never drawn). The mesh is drawn only when every group above it shows that child.
    std::uint32_t chainFirst = 0, chainCount = 0;
    // texture or normalMap is a render target ("target:<name>"): which image that is depends on the job that draws (a
    // camera's own target is the checker in its own frame), so every job resolves the texture again.
    bool liveTextures = false;
    std::vector<std::string> targets;  // the names of the render targets this mesh shows (only when asked for)
    // The HLOD proxy of a LodGroup (M75 P1d): a mesh made for the group (`mr` is one of the scene's own default MeshRenderers, `entity` the group's)
    // that stands for its whole subtree. 0 = an ordinary MeshRenderer; else 1 + the index in lod_groups() of the group it belongs to (set once the
    // groups are known). A camera draws it only where hlod_proxy_shown says so.
    std::uint32_t hlodGroup = 0;
    bool hlodProxy = false;  // the mesh is a proxy (hlodGroup is set for it by build_lod_groups)
    // The mesh is the HLOD proxy of a streamed cell that is not loaded (EntityInfo::streamedProxy, M75 P1e): an ordinary MeshRenderer that
    // renderStats.hlodProxies counts too.
    bool streamProxy = false;
};

// A LodGroup of the scene (M75.1) with the sphere that bounds the meshes of its whole subtree, in world space.
struct SceneLodGroup {
    Entity entity;
    const LodGroup* group = nullptr;
    Vec3 origin{0, 0,
                0};  // the group entity's position: the distance of a group is measured to it, as of a MeshRenderer
    float radius = 0.0f;  // of the sphere around the boxes of every mesh of the subtree; 0 = the subtree draws no mesh
    int children = 0;
    bool proxy =
        false;  // LodGroup.hlodProxy is set and its mesh was read: the proxy is a mesh of the scene (SceneMesh::hlodGroup)
};

class RenderScene {
public:
    // Gathers every MeshRenderer that is active (and, with `scopeRoot`, inside that subtree: Renderer::capture_world), with
    // the asset lookups on this thread and the matrices, flashes, boxes and hashes as jobs ("render.mesh_matrices",
    // "render.mesh_cull"). The order is the world's own, whatever the job threads. `wantTargets` also lists, per mesh, the
    // render targets it shows.
    // `probeVolumes`: the boxes of this frame's reflection probes (null or empty = none: every mesh reflects the sky).
    void build(World& world, Assets& assets, Entity scopeRoot, bool wantTargets,
               const std::vector<ProbeVolume>* probeVolumes = nullptr);
    const std::vector<SceneMesh>& meshes() const { return meshes_; }
    // The LodGroups of the scene and the chains of SceneMesh::chainFirst (M75.1); empty when the world has no LodGroup.
    const std::vector<SceneLodGroup>& lod_groups() const { return lodGroups_; }
    const std::vector<std::uint32_t>& lod_chains() const { return lodChains_; }
    // Some mesh has lods or some LodGroup exists: the cameras then pick levels. False costs a gather one check.
    bool has_lods() const { return anyLods_ || !lodGroups_.empty(); }
    Entity scope() const { return scope_; }
    bool built() const { return built_; }
    MaterialHashCache& hash_cache() { return hashes_; }
    // The ranks the meshes' sort keys were made with; valid() is false when a field had more values than its bits hold.
    const SortKeyTable& sort_table() const { return sortTable_; }
    // True when the scene's lightmap manifest carries baked light probes this frame.
    bool has_probes() const { return hasProbes_; }
    // Forgets the meshes (the world they point into may go away) but keeps the hash cache.
    void reset() {
        meshes_.clear();
        sortTable_.clear();
        probeLights_.clear();
        hasProbes_ = false;
        built_ = false;
        lodGroups_.clear();
        lodChains_.clear();
        hlodRenderers_.clear();
        anyLods_ = false;
    }
    // Frames (builds of the whole world or of a subtree) whose sort keys did not fit (SortKeyTable limits): their opaque
    // meshes were sorted by the comparator, slower but with the same result. Counted since the scene was made; the first one
    // also logs a warning that names the limit.
    std::uint64_t sort_key_fallbacks() const { return sortKeyFallbacks_; }

private:
    std::vector<SceneMesh> meshes_;
    MaterialHashCache hashes_;
    SortKeyTable sortTable_;
    // Work buffers of build(), kept between frames.
    std::vector<ProbeLight> probeLights_;  // SceneMesh::probe points here; sized once per build, only with baked probes
    bool hasProbes_ = false;
    std::vector<SortFields> fields_;
    std::vector<std::string_view> lodNames_;
    std::vector<std::uint64_t> keys_;
    std::vector<MaterialHashCache::Entry*> entries_;
    std::uint64_t sortKeyFallbacks_ = 0;
    std::vector<SceneLodGroup> lodGroups_;
    std::vector<std::uint32_t> lodChains_;
    std::vector<std::uint32_t> meshOf_;  // build_lod_groups' scratch: entity index -> index in meshes_
    std::vector<std::uint32_t>
        proxyOf_;  // the same for the HLOD proxy meshes (a group entity may have its own MeshRenderer too)
    std::deque<MeshRenderer>
        hlodRenderers_;  // the MeshRenderers of the proxy meshes (SceneMesh::mr points here); pointers stay good
    std::unordered_set<std::string> hlodWarned_;  // "<entity bits>|<path>" of a proxy already reported as unreadable
    bool anyLods_ = false;
    void add_hlod_proxies(World& world, Assets& assets, Entity scopeRoot);
    void build_lod_groups(World& world, Entity scopeRoot);
    Entity scope_;
    bool built_ = false;
};

// Where a mesh without a lightmap reads the light probes (M73.4d): the MeshRenderer.probeAnchor entity when it is alive, else the centre of the
// mesh's box (`bmin`..`bmax`, model space) in the world.
Vec3 probe_point(const World& world, const MeshRenderer& mr, const Mat4& model, Vec3 bmin, Vec3 bmax);

// `e` is drawn inside `scopeRoot` (entity_active of a Frame with that scopeRoot): with none, active in the hierarchy; with
// one, the root and the descendants whose own flag and whose ancestors' flags below the root are on.
bool entity_active_in_scope(const World& w, Entity scopeRoot, Entity e);

}  // namespace fa::render
