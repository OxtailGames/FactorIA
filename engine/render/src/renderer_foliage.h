// The Foliage component drawn (M75.6, docs/BIG_WORLDS_TERRAIN.md "Foliage"): the instances file is read and sorted into chunks off the main
// thread (a job of the job system: the frame never waits for it), and per camera the chunks in view become MeshItems, one per instance, that
// the ordinary mesh pipeline batches into instanced draws per (mesh, LOD): the prepass, the shadow maps, the clustered lights and the fog
// treat them as they treat any MeshRenderer. What an instance needs on top of that is done on the CPU, so no program is added (nothing grows
// in the players, and every backend draws it): the wind is a shear of the instance's matrix, the distance fade is the dither of the LOD
// cross-fade in kFoliageFadeSteps steps, the thinning of `density` a stable rank per instance.
#pragma once

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "fa/core/jobs.h"
#include "foliage_chunks.h"
#include "mesh_batch.h"
#include "render_internal.h"

namespace fa {
class World;
}

namespace fa::render {

class OcclusionBuffer;

class FoliageRenderer {
public:
    FoliageRenderer() = default;
    FoliageRenderer(const FoliageRenderer&) = delete;
    FoliageRenderer& operator=(const FoliageRenderer&) = delete;
    ~FoliageRenderer() { destroy(); }

    // What gather() needs of one camera of one frame.
    struct View {
        World* world = nullptr;
        Entity scopeRoot;
        std::function<bool(Entity)> drawn;  // Camera.showTags / hideTags (null = every entity)
        Assets* assets = nullptr;
        Mat4 viewProj;
        bool z01 = false;
        Vec3 camera;
        float time = 0.0f;         // World::time(): the clock of the wind
        std::uint64_t serial = 0;  // Renderer::Impl::frameSerial
        const OcclusionBuffer* occlusion =
            nullptr;  // this camera's CPU depth buffer (null: no Occluder, nothing is tested)
    };
    struct Counts {
        int entities = 0;  // Foliage entities with instances ready to draw
        int culled = 0;    // instances left out by the frustum, the occlusion or the fade distance (after the density)
        int items = 0;     // MeshItems appended
    };
    // Appends one MeshItem per instance that is drawn, or that casts a shadow into the view, to `out` (and a flag to `blended`, kept in step
    // with it: 1 = a mesh drawn with the blended ones). Starts and adopts the reads of the instances files.
    Counts gather(const View& view, std::vector<MeshItem>& out, std::vector<char>& blended);

    // Forgets every entry (the context is going away or the world was replaced); a read still running is abandoned.
    void destroy();
    // A file is being read or decoded now (a capture waits for it, wait_loaded()).
    bool loading() const;
    // Waits for the reads in flight; the next gather() adopts them. For tests and captures: a frame never calls it.
    void wait_loaded();
    std::size_t size() const { return entries_.size(); }
    // Files read since the renderer was made (a test looks at it: an unchanged file is read once).
    std::uint64_t loads() const { return loads_; }
    // Bytes the chunked instances take on the CPU.
    std::size_t bytes() const;

private:
    struct Load;  // what a read job fills
    struct Entry {
        std::string file;           // Foliage.instances as the data below was read from it (normalized)
        std::size_t meshCount = 0;  // Foliage.meshes.size() of that read
        std::shared_ptr<const FoliageChunks> data;
        std::vector<std::uint32_t> kept;  // per chunk: the instances the density keeps
        float keptDensity = -1.0f;
        // A read in flight, and what it is for.
        std::shared_ptr<Load> load;
        jobs::Handle handle;
        std::string loadFile;
        std::size_t loadMeshes = 0;
        // The file's size and time when the data was read (-1: it was missing), to find a rewrite; checked every few frames.
        std::int64_t fileTime = -1, fileSize = -1;
        std::uint64_t checkedAt = 0, reloadSeen = 0, seen = 0;
        bool failed = false;  // the last read failed: not tried again until the file changes
        std::string warned;   // the last problem said (said once)
        // The meshes: what Foliage.meshes names, one MeshRenderer each (the items point at them), and the next LOD of each (a model's
        // "<name>.lod1.glb" when that file exists, else empty).
        std::vector<std::string> names, lodNames;
        std::vector<MeshRenderer> mrs;
        std::uint64_t lodCheck = ~std::uint64_t(0);  // Assets::reload_generation() the lodNames were checked at
    };
    void start_load(Entry& en, const std::string& file, std::size_t meshes);
    void adopt(Entry& en, const std::string& entityId);

    std::unordered_map<std::uint64_t, std::unique_ptr<Entry>> entries_;  // by Entity::bits()
    std::uint64_t pruned_ = ~std::uint64_t(0);
    std::uint64_t loads_ = 0;
    std::vector<std::vector<MeshItem>>
        buckets_;  // gather(): the items of one Foliage by (mesh, level), appended in this order
    bool capWarned_ = false;
};

// "<dir>/<name>.lod1.<ext>" for a model path "<dir>/<name>.<ext>" (.glb, .gltf), the file model.generate_lods writes; "" for a primitive or
// any other name.
std::string foliage_lod_name(const std::string& mesh);

}  // namespace fa::render
