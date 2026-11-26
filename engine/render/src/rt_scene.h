// The acceleration structures of the scene (M79 P1s; docs/design/ARCHITECTURE_RT_SCENE.md): one BLAS for every submesh of every mesh
// asset the frame draws, one TLAS rebuilt every frame from the drawn mesh instances, and the buffer of per-instance records the ray query
// kernels read (rt_records.h). Written against fa::gpu only: it runs on the RecordingDevice, and on D3D12, Vulkan and Metal where their
// packages have brought the calls.
//
// A frame, in the order the renderer calls it (all on the render thread):
//   configure()      the settings or the device changed (main thread, between frames): turns the scene on or off
//   begin_frame()    the frame starts: the compaction answers of the frames before arrive, compacted BLASes replace the originals
//   collect()        the main camera's job has gathered its mesh items: the instances of the TLAS are chosen (cap, LOD, skipped kinds), the
//                    BLASes they need are made (the memory; nothing is built yet)
//   record()         the frame graph pass "rt-accel": builds the new BLASes, asks for their compacted size, copies the ones whose compacted
//                    size came back, writes the records and builds the TLAS
//   forget()         a mesh asset's buffers are about to go: its BLASes are freed
//   shift()          the floating origin moved: what is kept in world space moves with it
//   release()        ray tracing was turned off, or the renderer shuts down: everything is freed
// With the scene off (never configured, or released) every call is a branch and returns: no buffer, no BLAS, no work.
#pragma once

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
        0;  // skinned meshes (an Animator's palette): not traced until the skinning runs on the GPU (P1k)
    std::uint32_t skippedImpostor = 0;  // cards of an impostor: the entity is not traced while it is one
    std::uint32_t skippedTerrain = 0;   // nodes of a Terrain
    std::uint32_t skippedFading = 0;    // the level fading out of a LOD cross-fade (the level fading in is traced)
    std::uint32_t skippedGpuDriven =
        0;  // a mesh drawn from compute buffers: the instances are where the buffer puts them, unknown here
    std::uint32_t skippedUntraceable =
        0;  // a mesh with no vertex buffer a build can read (a placeholder), or with no triangle
    std::uint32_t skippedNoBlas = 0;  // instances whose BLAS failed or waits for a later frame's build budget
    std::uint32_t blasLive = 0;       // BLASes alive
    std::uint32_t blasBuilt = 0;      // BLASes built by the last record()
    std::uint32_t blasCompacted = 0;  // compaction copies the last record() made
    std::uint64_t blasBytes = 0;      // acceleration structure memory of the BLASes
    std::uint64_t tlasBytes = 0;      // acceleration structure memory of the TLAS
    std::uint32_t cap = 0;            // instances the scene may hold
};

class RtScene {
public:
    // The most BLAS builds one frame records (a deterministic work count: a scene with more waits for the next frames).
    static constexpr std::uint32_t kMaxBuildsPerFrame = 256;
    // The compacted sizes in flight at once (8 bytes each in one buffer); a BLAS with no free slot is simply not compacted.
    static constexpr std::uint32_t kSizeSlots = 4096;

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

    // The skinned meshes (an item with an Animator's palette) are not traced yet: called once per skinned item collect() skips, before it
    // does. P1k (compute skinning, then a refit of the BLAS) replaces this branch; until then the hook is for a test or a tool that counts.
    std::function<void(const MeshItem&)> onSkinned;

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
    bool blas_has_asset(const MeshAsset* mesh) const { return meshes_.count(mesh) != 0; }
    // The structure of a live BLAS (invalid for one that is gone), and how many are waiting to be destroyed, for a test.
    gpu::AccelStructure blas_structure(std::uint32_t id) const {
        const auto it = blas_.find(id);
        return it == blas_.end() ? gpu::AccelStructure{} : it->second.structure;
    }
    std::size_t retired_count() const { return graveyard_.size(); }

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
    };
    struct MeshEntry {
        std::uint64_t version = 0;
        std::uint64_t signature = 0;      // the buffers of the parts (their ids): a change of any rebuilds the BLASes
        std::vector<std::uint32_t> blas;  // per part; 0 = none
        std::vector<std::uint8_t> untraceable;  // per part: 1 = nothing a build can read
        std::uint64_t checkedFrame = 0;         // the frameCounter_ of the last signature check (once per frame)
    };
    struct Item {
        const MeshAsset* mesh = nullptr;
        std::uint32_t part = 0;
        std::uint32_t blasId = 0;
        std::uint32_t entityId = 0;
        float dist = 0.0f;
        gpu::AccelInstance instance;
        RtInstanceRecord record;
    };

    std::uint32_t blas_for(const MeshAsset& mesh, std::size_t part, const std::string& key, bool& failed);
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
    bool warnedCap_ = false, warnedSkinned_ = false, warnedBlasMake_ = false, warnedBlasBuild_ = false,
         warnedTlasMake_ = false, warnedTlasBuild_ = false, warnedBuffers_ = false, warnedRead_ = false;
};

}  // namespace fa::render
