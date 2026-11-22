// The world streamer (docs/BIG_WORLDS.md, "Streaming"): loads and unloads the cells of a streamed world around the StreamingAnchor
// entities. One per engine, made with the engine, never serialized. Main thread only.
//
//   StreamedWorld (a component) names the index file (<name>.world.json, fa/scene/world_index.h). Every FIXED TICK `update()` reads the
//   anchors (and, with StreamedWorld.cameraLoadRadius, the camera), decides which cells are WANTED (nearer than an anchor's
//   loadRadius) and which are KEPT (a cell that is loaded or loading stays until it is farther than every anchor's unloadRadius:
//   the hysteresis), cancels what is no longer kept and starts the wanted cells that are not loading yet. Every FRAME `apply()` (called
//   where the BackgroundLoader ticks) takes the cells the loader finished and adds them to the world, and removes the cells that are
//   no longer kept.
//
//   A cell load is a BackgroundLoader job of Kind::CellLoad: its file (and the files its scene names) is read and PARSED off the main
//   thread; the main thread only creates the entities. Several run at once (StreamedWorld.maxLoadsInFlight); a cell counts as in
//   flight from the moment its job starts until it is applied. At most StreamedWorld.maxAppliesPerFrame cells are added or removed
//   per frame, unloads first, the loads in the order they were started.
//
//   Everything is a function of the anchors' positions at the fixed ticks and of the unit budgets (the IO threads only decide how
//   soon a result is ready, and an exact budget waits for it): the same inputs load the same cells in the same order.
//
//   POSITIONS. The plane of the world is XZ for a "3d" index and XY for a "2d" one. The radii are measured on that plane between the
//   ABSOLUTE position of the anchor (the floating origin plus its local position; the origin counts as 0 until M75.4, see
//   absolute_plane_position) and the cell's bounds (absolute too): the height of an anchor never matters.
//
//   A cell's entities are children of a ROOT entity "cell <i>,<j>" (id "cell_<i>_<j>", EntityInfo::streamedCell) at the origin of
//   the world: their positions in the cell's scene are world positions. Unloading destroys the root (and so its subtree) on the main
//   thread; the physics world drops its bodies at its next sync. Events: "cellLoaded" and "cellUnloaded" ({world, id, coord, ...}).
#pragma once

#include <cstddef>
#include <cstdint>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/runtime/internal/background_loader.h"
#include "fa/scene/components_world.h"
#include "fa/scene/world.h"
#include "fa/scene/world_index.h"

namespace fa {

class WorldStreamer {
public:
    enum class State { Unloaded, Queued, Loading, Loaded, Unloading };
    static const char* state_name(State s);

    static constexpr int kMaxLoadsInFlight = 16;    // StreamedWorld.maxLoadsInFlight is clamped to 1..this
    static constexpr int kMaxAppliesPerFrame = 64;  // StreamedWorld.maxAppliesPerFrame is clamped to 1..this
    static constexpr std::int64_t kEagerFileChecks =
        4096;  // an index with more cells is not checked file by file when it is read

    WorldStreamer(World& world, BackgroundLoader& loader);
    WorldStreamer(const WorldStreamer&) = delete;
    WorldStreamer& operator=(const WorldStreamer&) = delete;

    // One fixed tick: reads the StreamedWorld and the anchors, cancels the loads that are no longer wanted, marks the cells to unload and
    // starts the loads that fit under maxLoadsInFlight.
    void update();
    // One frame (after BackgroundLoader::tick): takes the cells it finished (`results` is consumed), unloads and applies within
    // StreamedWorld.maxAppliesPerFrame. `units` = the loader's units of this frame (status only).
    void apply(std::vector<BackgroundLoader::CellResult>& results, int units);
    // The scene is being replaced (the world is cleared by the caller): every cell job is cancelled, everything is forgotten and
    // nothing is applied to the new scene. No event is sent.
    void reset();
    // True while a cell is loading, waiting to be applied or to be unloaded: the engine ticks the streamer even when the loader is idle.
    bool busy() const { return !tracked_.empty(); }

    // world.cells: the cells of the index with their state (`stateFilter` "" = all), sorted by distance to the nearest anchor (cells
    // with no anchor last), at most `limit`. Throws nothing: {error} fields tell what is wrong.
    Json cells(const std::string& stateFilter, std::size_t limit);
    // world.stream_status.
    Json status();
    // The text of the last problem ("" = none); also in status().
    const std::string& last_error() const { return lastError_; }
    // Reads the index of the StreamedWorld in the scene now when it has changed (the commands call it so they answer before the first
    // fixed tick). False when there is none or it is wrong (last_error says).
    bool ensure_index();

private:
    struct CellState {
        State state = State::Unloaded;
        int job = 0;                      // BackgroundLoader job id while Loading
        std::shared_ptr<const Json> doc;  // the parsed scene, once the job finished and before it is applied
        bool failed = false;              // its load failed: it is not tried again until it has left the wanted set
        Entity root;                      // the cell's root entity while Loaded
        std::int64_t entities = 0;        // entities under the root
        std::uint64_t bytes = 0;          // bytes its load read
    };
    struct Anchor {
        double a = 0, b = 0;
        double loadRadius = 0, unloadRadius = 0;
        std::int32_t priority = 0;
    };
    struct Settings {
        bool found = false;  // a StreamedWorld exists (the first one that is enabled and active)
        bool enabled = false;
        std::string world;
        int maxLoads = 2, maxApplies = 1;
        bool keepLoaded = false;
        float cameraLoad = 0, cameraUnload = 0;
    };

    Settings read_settings() const;
    std::vector<Anchor> gather_anchors(const Settings& s) const;
    void load_index(const std::string& path);
    void drop_everything(bool sendEvents);  // unload every cell now and forget the index
    void set_state(std::size_t idx, State s);
    void cancel_cell(std::size_t idx);
    void do_apply(std::size_t idx);
    void do_unload(std::size_t idx);
    void send_event(const char* name, const WorldCell& cell, Json extra, Entity source);
    std::vector<std::size_t> candidates(double a, double b, double radius) const;

    World& world_;
    BackgroundLoader& loader_;
    WorldIndex index_;
    std::string indexPath_;          // the path index_ was read from ("" = none)
    std::string failedPath_;         // a path whose index was wrong (not read again until the path changes)
    std::vector<CellState> cells_;   // parallel to index_.cells
    std::set<std::size_t> tracked_;  // cells that are not Unloaded
    std::set<std::size_t> failed_;   // cells with `failed` set
    Settings settings_;
    std::int64_t minI_ = 0, maxI_ = -1, minJ_ = 0, maxJ_ = -1;  // the coordinate range of the index
    std::string lastError_;
    // statistics (world.stream_status)
    std::int64_t loadsStarted_ = 0, loadsCancelled_ = 0, cellsApplied_ = 0, unloadsDone_ = 0, bytesLoaded_ = 0;
    int appliedThisFrame_ = 0, unloadedThisFrame_ = 0, unitsThisFrame_ = 0;
    std::size_t anchorCount_ = 0;
    mutable bool warnedMultiple_ = false;
};

// The ABSOLUTE position on the plane of the world of a local position: the floating origin (docs/BIG_WORLDS.md, M75.4) plus the
// local position, on the plane axes of the index (x and z for "3d", x and y for "2d"). The origin is 0 until the floating origin is
// built: this is the one place that changes then.
void absolute_plane_position(const WorldIndex& index, Vec3 local, double& a, double& b);

}  // namespace fa
