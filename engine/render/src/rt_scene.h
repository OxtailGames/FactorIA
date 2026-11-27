// The acceleration structures of the scene (M79 P1s; docs/design/ARCHITECTURE_RT_SCENE.md): one BLAS for every submesh of every mesh
// asset the frame draws, one TLAS rebuilt every frame from the drawn mesh instances, and the buffer of per-instance records the ray query
// kernels read (rt_records.h). Written against fa::gpu only: it runs on the RecordingDevice, and on D3D12, Vulkan and Metal where their
// packages have brought the calls.
//
// A frame, in the order the renderer calls it (all on the render thread):
//   configure()      the settings or the device changed (main thread, between frames): turns the scene on or off
//   begin_frame()    the frame starts: the compaction answers of the frames before arrive, compacted BLASes replace the originals
//   collect()        the main camera's job has gathered its mesh items: the instances of the TLAS are chosen (cap, LOD, skipped kinds), the
//                    BLASes they need are made (the memory; nothing is built yet); a skinned item gets a BLAS of its own (M79 P1k)
//   record()         the frame graph pass "rt-accel": skins the skinned instances (one compute pass), builds the new BLASes, refits the
//                    skinned ones, asks for the compacted size of the static ones, copies the ones whose compacted size came back, writes
//                    the records and builds the TLAS
//   forget()         a mesh asset's buffers are about to go: its BLASes are freed
//   shift()          the floating origin moved: what is kept in world space moves with it
//   release()        ray tracing was turned off, or the renderer shuts down: everything is freed
// With the scene off (never configured, or released) every call is a branch and returns: no buffer, no BLAS, no work.
#pragma once

#include <algorithm>
#include <cstdint>
#include <functional>
#include <map>
#include <string>
#include <unordered_map>
#include <vector>

#include "fa/core/math.h"
#include "gpu/device.h"
#include "mesh_batch.h"
#include "rt_records.h"

namespace fa::render {

struct MeshAsset;

// What the last collect() / record() did, in units of counts (never of time).
struct RtSceneStats {
    std::uint32_t candidates = 0;      // mesh items the main camera's job offered
    std::uint32_t instances = 0;       // instances of the TLAS (records written)
    std::uint32_t droppedOverCap = 0;  // the farthest items left out because the scene holds more than `cap`
    std::uint32_t skippedSkinned =
        0;  // skinned instances left out: over the skinned budget (kMaxSkinnedVertices, kRtSkinMaxPartVertices) or no skinning program
    std::uint32_t skippedImpostor = 0;  // cards of an impostor: the entity is not traced while it is one
    std::uint32_t skippedTerrain = 0;   // nodes of a Terrain
    std::uint32_t skippedFading = 0;    // the level fading out of a LOD cross-fade (the level fading in is traced)
    std::uint32_t skippedGpuDriven =
        0;  // a mesh drawn from compute buffers: the instances are where the buffer puts them, unknown here
    std::uint32_t skippedUntraceable =
        0;  // a mesh with no vertex buffer a build can read (a placeholder), or with no triangle
    std::uint32_t skippedNoBlas = 0;  // instances whose BLAS failed or waits for a later frame's build budget
    // M79-P2a-2: the parts that cast a shadow (MeshRenderer.castShadows) in the scene's candidates that the ray traced sun shadow does NOT see this
    // frame: terrain nodes, impostor cards, GPU-driven meshes, untraceable parts, skinned parts over the budget, the farthest over the cap, parts
    // whose BLAS fails or waits for its build, and the cutout (alpha-tested) parts, which are in the TLAS but never commit a hit (the kernel has no
    // alpha texture). A count of parts, but only whether it is zero matters: the lit pass then takes the cascades' shadow too (min), so none of
    // them loses its shadow (docs/design/ARCHITECTURE_RT_EFFECTS.md, "No caster loses its shadow").
    std::uint32_t untracedCasters = 0;
    std::uint32_t blasLive = 0;       // BLASes alive
    std::uint32_t blasBuilt = 0;      // BLASes built by the last record()
    std::uint32_t blasCompacted = 0;  // compaction copies the last record() made
    std::uint64_t blasBytes = 0;      // acceleration structure memory of the BLASes
    std::uint64_t tlasBytes = 0;      // acceleration structure memory of the TLAS
    std::uint32_t cap = 0;            // instances the scene may hold
    // The skinned meshes (rt_scene_skin.cpp):
    std::uint32_t skinnedInstances = 0;
    std::uint32_t skinnedDispatches = 0;  // skinning dispatches the last record() made (one per skinned BLAS)
    std::uint32_t skinnedBuilds =
        0;  // skinned BLASes built from scratch by the last record() (first, periodic or extent rebuild)
    std::uint32_t skinnedRefits = 0;    // skinned BLASes refitted by the last record()
    std::uint64_t skinnedVertices = 0;  // vertices the last record() skinned
};

class RtScene {
public:
    // The most BLAS builds one frame records (a deterministic work count: a scene with more waits for the next frames).
    static constexpr std::uint32_t kMaxBuildsPerFrame = 256;
    // The compacted sizes in flight at once (8 bytes each in one buffer); a BLAS with no free slot is simply not compacted.
    static constexpr std::uint32_t kSizeSlots = 4096;
    // The skinned meshes (docs/design/ARCHITECTURE_RT_SCENE.md, "Skinned meshes"): the vertices skinned in one frame, a deterministic work count (the
    // nearest instances to the main camera stay; the rest are not traced, with one warning).
    static constexpr std::uint64_t kMaxSkinnedVertices = 1ull << 22;
    static constexpr std::uint32_t kMaxSkinnedInstances = 4096;  // and the instances (a palette each: 3 KB)
    // A skinned BLAS is refitted every frame and built from scratch again every this many frames (a refit keeps the tree of the first pose, which
    // gets worse the more the mesh moves from it), and when the extent of its bones jumps by more than kSkinExtentJump of the largest side of
    // the box it was built for (a teleport of a bone, a new animation: the refit alone would trace a wrong tree).
    static constexpr std::uint32_t kSkinRebuildFrames = 60;
    static constexpr std::uint32_t kSkinRebuildSpread =
        16;  // the rebuilds due are spread over this many frames (by BLAS id)
    static constexpr float kSkinExtentJump = 0.35f;
    // The scratch memory the builds of the skinned BLASes of one frame get side by side (builds past it share the start, which the backend
    // serializes): 64 MiB.
    static constexpr std::uint64_t kSkinScratchBytes = 64ull << 20;

    RtScene() = default;
    ~RtScene();
    RtScene(const RtScene&) = delete;
    RtScene& operator=(const RtScene&) = delete;

    // The scene works on `device` with at most `maxInstances` instances (the setting; the device's own limit lowers it). `on` false
    // frees everything. Calling it again with what it has is free. A device that cannot trace leaves the scene off (the renderer says why).
    // Returns whether the scene is on afterwards.
    bool configure(gpu::Device* device, bool on, std::uint32_t maxInstances);
    bool active() const { return device_ != nullptr; }
    std::uint32_t cap() const { return cap_; }

    // See the header comment. `commit` makes the work recorded so far reach the GPU before a read-back (Gpu::commit_frame + note_commit);
    // it is called only when a read is about to be asked for. `headless`: a read-back is waited for (the result never depends on the GPU's speed).
    void begin_frame(bool headless, const std::function<void()>& commit);
    // The items of the main camera's job (every item: the ones outside the view count, a ray may hit them). `camera` is where the nearest-first
    // cap measures from; `linear` the scene's colour space (to_scene).
    // A new frame graph starts (Renderer::begin_frame_graph): nothing is collected for it yet.
    void begin_graph() { collected_ = false; }
    void collect(const std::vector<MeshItem>& opaque, const std::vector<MeshItem>& blended, const Vec3& camera,
                 bool linear);
    // Whether collect() ran since begin_frame().
    bool collected() const { return collected_; }
    // The items of the last collect() that can be in the TLAS (the kinds the scene leaves out, a mesh with no triangle and the ones over the cap are
    // not counted). Known at plan time, while the TLAS is built later in the graph: 0 means this frame's TLAS will have no instance.
    std::uint32_t traceable_items() const { return collected_ ? std::uint32_t(items_.size()) : 0; }
    // The frame graph pass: records on `list` (outside any pass). Does nothing without instances.
    void record(gpu::CommandList& list);
    void forget(const MeshAsset* mesh);
    void shift(const Vec3& offset);
    void release();

    // What the effects of later packages read: the TLAS (invalid until the first frame with an instance), the record buffer (the instance
    // with customIndex i is record i), the number of instances of the last collect().
    gpu::AccelStructure tlas() const { return tlasBuilt_ ? tlas_ : gpu::AccelStructure{}; }
    gpu::Buffer records_buffer() const { return tlasBuilt_ ? recordsBuffer_ : gpu::Buffer{}; }
    std::uint32_t instance_count() const { return tlasBuilt_ ? tlasInstances_ : 0; }
    const RtSceneStats& stats() const { return stats_; }
    // M79-P5a: what the path tracer asks to know whether the picture it accumulates is still the scene's: a hash of the instances of the last
    // record() (their transforms, masks, BLAS ids and records; a frame with a skinned instance never repeats). It is only computed while
    // `set_track_changes(true)` (the cost is one pass over the frame's instances, so the scene is free of it otherwise); 0 without instances.
    void set_track_changes(bool on) { trackChanges_ = on; }
    std::uint64_t content_hash() const { return contentHash_; }

    // The compute pipeline of the skinning kernel (rt_skin.glsl: slots in rt_skin.h), asked for in every frame that skins (the handle is never
    // kept: the renderer's pipeline cache destroys an idle one). The renderer makes it on first use; without it (or without compute shaders) the skinned instances are not traced.
    std::function<gpu::Pipeline()> skinKernel;

    // For the tests: the instances and records of the last collect() (after the cap and the filter of record()), and the records of the
    // frame before (the world-space cache shift() moves).
    struct FrameInstance {
        gpu::AccelInstance instance;
        RtInstanceRecord record;
        std::uint32_t blasId = 0;
        std::uint32_t entityId = 0;  // Entity::bits() truncated, for a test to find its entity
    };
    const std::vector<FrameInstance>& frame_instances() const { return frame_; }
    const std::vector<RtInstanceRecord>& previous_records() const { return previous_; }
    // Live BLAS ids of a mesh asset, in part order (0 = a part with none), and the state names ("pending", "built", "queried", "reading",
    // "compact-pending", "swap", "compacted", "failed") of every BLAS, for a test.
    std::vector<std::uint32_t> blas_ids_of(const MeshAsset* mesh) const;
    std::string blas_state(std::uint32_t id) const;
    // The buffer the skinning kernel writes the positions of a skinned instance's BLAS into (invalid for a static one or a BLAS that is gone).
    gpu::Buffer skinned_positions_of(std::uint32_t id) const {
        auto it = blas_.find(id);
        return it == blas_.end() ? gpu::Buffer{} : it->second.positions;
    }
    bool blas_has_asset(const MeshAsset* mesh) const { return meshes_.count(mesh) != 0; }
    // The structure of a live BLAS (invalid for one that is gone), and how many are waiting to be destroyed, for a test.
    gpu::AccelStructure blas_structure(std::uint32_t id) const {
        const auto it = blas_.find(id);
        return it == blas_.end() ? gpu::AccelStructure{} : it->second.structure;
    }
    std::size_t retired_count() const { return graveyard_.size(); }
    // Tests: lower the builds of a frame (kMaxBuildsPerFrame by default) to see a scene whose rebuilds outnumber the budget without
    // thousands of instances; the frame count and the frame of a BLAS's last full build.
    void set_builds_per_frame(std::uint32_t n) { buildsPerFrame_ = std::min(n, kMaxBuildsPerFrame); }
    std::uint64_t frame_counter() const { return frameCounter_; }
    std::uint64_t blas_built_frame(std::uint32_t id) const {
        const auto it = blas_.find(id);
        return it == blas_.end() ? 0 : it->second.builtFrame;
    }

private:
    enum class State : std::uint8_t { Pending, Built, Queried, Reading, CopyPending, Swap, Compacted, Failed };
    struct Blas {
        std::uint32_t id = 0;
        State state = State::Pending;
        gpu::AccelStructure structure{};
        gpu::AccelStructure compact{};  // CopyPending / Swap: the smaller one the original is copied into
        std::uint64_t size = 0;
        std::uint64_t buildScratch = 0;
        std::uint64_t compactedSize = 0;
        std::int32_t slot = -1;
        gpu::AccelTriangles triangles{};
        std::string label;
        // A skinned instance's own BLAS (never compacted, built with allowUpdate): refitted every frame from `positions`, which the skinning
        // kernel writes.
        bool skinned = false;
        std::uint64_t entity = 0;
        const MeshAsset* mesh = nullptr;
        std::uint32_t part = 0;
        std::uint64_t signature = 0;  // the mesh's signature and version when it was made
        std::uint32_t vertexCount = 0;
        gpu::Buffer positions{};
        gpu::View outView{};
        std::uint64_t updateScratch = 0;
        std::uint64_t seen = 0;        // the frameCounter_ of the last collect() that kept an instance of it
        std::uint64_t builtFrame = 0;  // the frameCounter_ of the last full build
        Vec3 builtMin{0, 0, 0}, builtMax{0, 0, 0};  // the bone extent at that build
    };
    // The storage views of a skinned part's source buffers (made on first use, freed with the mesh entry).
    struct SkinSource {
        gpu::Buffer vb{}, skinVb{};
        gpu::View vbView{}, skinView{};
    };
    struct SkinKey {
        std::uint64_t entity = 0;
        const MeshAsset* mesh = nullptr;
        std::uint32_t part = 0;
        bool operator<(const SkinKey& o) const {
            if (entity != o.entity) return entity < o.entity;
            if (mesh != o.mesh) return std::less<const MeshAsset*>()(mesh, o.mesh);
            return part < o.part;
        }
    };
    struct MeshEntry {
        std::uint64_t version = 0;
        std::uint64_t signature = 0;      // the buffers of the parts (their ids): a change of any rebuilds the BLASes
        std::vector<std::uint32_t> blas;  // per part; 0 = none
        std::vector<std::uint8_t> untraceable;  // per part: 1 = nothing a build can read
        std::vector<SkinSource> sources;        // per part, once a skinned instance of it was traced
        std::uint64_t checkedFrame = 0;         // the frameCounter_ of the last signature check (once per frame)
    };
    struct Item {
        const MeshAsset* mesh = nullptr;
        std::uint32_t part = 0;
        std::uint32_t blasId = 0;
        std::uint32_t entityId = 0;
        float dist = 0.0f;
        bool skinned = false;
        std::uint64_t entity = 0;
        const std::vector<Mat4>* palette =
            nullptr;  // skinned: the Animator's palette of the part's skin (valid during collect() only)
        std::uint32_t vertexCount = 0;
        std::uint32_t paletteIndex = 0;           // skinned: the palette's slot in paletteRows_
        Vec3 boneMin{0, 0, 0}, boneMax{0, 0, 0};  // skinned: the extent of the bones' boxes of the part
        gpu::AccelInstance instance;
        RtInstanceRecord record;
    };

    std::uint32_t blas_for(const MeshAsset& mesh, std::size_t part, const std::string& key, bool& failed);
    // The skinned instances (rt_scene_skin.cpp).
    void prepare_skinned(const Vec3& camera);
    std::uint32_t skinned_blas(MeshEntry& entry, const MeshAsset& mesh, std::uint32_t part, std::uint64_t entity);
    void free_unseen_skinned();
    bool skin_sources(MeshEntry& entry, const MeshAsset& mesh, std::uint32_t part);
    bool ensure_palette_buffer();
    // What record() does for the skinned BLASes of the frame (one entry per BLAS, in id order).
    struct SkinWork {
        std::uint32_t id = 0;
        bool full = false;  // build from scratch (first build, periodic or extent rebuild); false = refit in place
        Vec3 boneMin{0, 0, 0}, boneMax{0, 0, 0};
        std::size_t scratchOffset = 0;
        std::uint32_t paletteIndex = 0;  // the slot of its palette in paletteRows_
    };
    void plan_skin(std::vector<SkinWork>& work, std::uint32_t buildBudget, std::uint64_t& scratchNeed);
    void record_skin_dispatches(gpu::CommandList& list, const std::vector<SkinWork>& work);
    std::uint32_t record_skin_builds(gpu::CommandList& list, const std::vector<SkinWork>& work);
    void release_skin();
    gpu::Pipeline skin_kernel() const;
    void warn_skin_budget(const std::string& key, std::uint32_t vertices);
    // A BLAS that is no longer wanted. A TLAS does not keep its BLASes alive, so the structure of a BLAS the frames in flight may still trace
    // goes to the graveyard and is destroyed kRetireFrames frames later (begin_frame); never destroy a BLAS with destroy_accel_structure.
    void retire_blas(gpu::AccelStructure structure);
    void drain_graveyard(bool all);
    void free_blas(std::uint32_t id);
    void record_frame(gpu::CommandList& list);
    void free_mesh_entry(MeshEntry& e);
    void poll_compaction(bool headless, const std::function<void()>& commit);
    void apply_compacted(std::uint32_t id, std::uint64_t size);
    bool ensure_buffers(std::uint64_t scratch,
                        std::uint32_t instances);  // false: a buffer could not be made, the frame builds nothing
    void warn_once(bool& flag, const char* what, const std::string& message);
    std::int32_t take_slot();

    gpu::Device* device_ = nullptr;
    std::uint32_t maxInstances_ = 0;
    std::uint32_t cap_ = 0;
    bool collected_ = false;
    std::uint32_t nextId_ = 1;
    std::map<std::uint32_t, Blas> blas_;  // by id: ordered, so every walk (builds, frees) is the same on every run
    std::unordered_map<const MeshAsset*, MeshEntry> meshes_;  // only looked up, never walked in order
    std::vector<std::uint32_t> pending_;                      // ids waiting for their build, in creation order
    std::vector<std::uint32_t> queried_;  // built, their compacted size asked: the next begin_frame commits and reads
    std::vector<std::uint32_t> copyPending_;  // their compacted size came back: record() copies them
    std::vector<std::uint32_t> swap_;         // copied last frame: begin_frame() swaps the compact one in
    std::uint64_t frameCounter_ = 0;
    std::uint32_t buildsPerFrame_ = kMaxBuildsPerFrame;  // set_builds_per_frame
    // The skinned instances: BLAS id by (entity, mesh, part) (only looked up, never walked in order), the palettes of the frame (collect() copies
    // each distinct one, kRtSkinPaletteFloats floats), and the buffer record() writes them to.
    std::map<SkinKey, std::uint32_t> skinned_;
    std::vector<float> paletteRows_;
    std::uint32_t paletteCount_ = 0;
    gpu::Buffer paletteBuffer_{};
    gpu::View paletteView_{};
    std::uint32_t paletteCapacity_ = 0;  // palettes the buffer holds
    // The compacted-size answers.
    gpu::Buffer sizeBuffer_{};
    std::vector<std::int32_t> freeSlots_;
    std::int32_t slotHigh_ = 0;  // slots 0 .. slotHigh_ - 1 have been handed out
    gpu::ReadTicket readTicket_{};
    struct Reading {
        std::uint32_t id = 0;
        std::int32_t slot = 0;
    };
    std::vector<Reading> reading_;  // the BLASes the ticket (or the next synchronous read) answers
    // The frame.
    std::vector<Item> items_;
    std::vector<FrameInstance> frame_;
    std::vector<RtInstanceRecord> previous_;
    bool trackChanges_ = false;
    std::uint64_t contentHash_ = 0;
    std::uint64_t skinSerial_ = 0;
    gpu::AccelStructure tlas_{};
    std::uint32_t tlasCapacity_ = 0;  // instances the TLAS memory was sized for
    bool tlasBuilt_ = false;
    std::uint32_t tlasInstances_ = 0;
    gpu::Buffer recordsBuffer_{};
    std::uint32_t recordsCapacity_ = 0;
    gpu::Buffer scratch_{};
    std::uint64_t scratchSize_ = 0;
    RtSceneStats stats_;
    struct Retired {
        gpu::AccelStructure structure{};
        std::uint64_t frame = 0;  // frameCounter_ when it was retired
    };
    std::vector<Retired> graveyard_;  // in retirement order
    // One flag per cause of a warning: each says itself once.
    std::uint32_t untracedCollected_ = 0;  // RtSceneStats::untracedCasters as collect() left it
    bool warnedCap_ = false, warnedSkinned_ = false, warnedBlasMake_ = false, warnedBlasBuild_ = false,
         warnedTlasMake_ = false, warnedTlasBuild_ = false, warnedBuffers_ = false, warnedRead_ = false,
         warnedSkinKernel_ = false;
};

}  // namespace fa::render
