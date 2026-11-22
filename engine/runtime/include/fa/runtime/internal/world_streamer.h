// The world streamer (docs/BIG_WORLDS_STREAMING.md, "Streaming"): loads and unloads the cells of a streamed world around the StreamingAnchor
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
//   ABSOLUTE position of the anchor (World::absolute_position: the floating origin plus its local position, in doubles; see
//   absolute_plane_position) and the cell's bounds (absolute too): the height of an anchor never matters.
//
//   A cell's entities are children of a ROOT entity "cell <i>,<j>" (id "cell_<i>_<j>", EntityInfo::streamedCell) at the ABSOLUTE
//   (0, 0, 0) (local position World::to_local(0): minus the floating origin): the positions in the cell's scene are ABSOLUTE, and an
//   additive load_scene under a parent leaves placing to the parent, so the cell's entities land at their absolute position. Unloading destroys the root (and so its subtree) on the main
//   thread; the physics world drops its bodies at its next sync. Events: "cellLoaded" and "cellUnloaded" ({world, id, coord, ...}).
//
//   HLOD PROXIES (M75 P1e). A cell of the index may name a proxy mesh (WorldCell::hlod, a .glb in the space of the cell's corner:
//   world_cell_corner). With StreamedWorld.hlodDistance above 0, every cell whose proxy is within that distance (and its own
//   hlod.maxDistance) of an anchor gets a BackgroundLoader job of Kind::HlodLoad that decodes the mesh into the renderer's cache, off the
//   main thread, nearest cells first, at most kMaxHlodProxies prepared (kMaxProxyLoadsInFlight reading at once). The proxy is SHOWN, as
//   an entity "hlod <i>,<j>" (EntityInfo::streamedProxy: never saved) at the cell's absolute corner, only while its mesh is ready and the
//   cell's entities are not in the world: apply() adds and removes it in the same call that adds or removes the cell's root, so a
//   frame never draws both or (once the proxy is ready) neither. A proxy that cannot be read is reported once, tried again after
//   kRetryTicks fixed ticks while its cell is still in range, and forgotten when the cell leaves the range. A proxy casts no shadow
//   (MeshRenderer.castShadows false: it stands for what is far away, and a shadow pass over hundreds of them costs more than it shows). Which proxies exist is a function of the anchors at the fixed ticks and of the loader's units: the same
//   run makes the same ones.
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
    static constexpr int kRetryTicks =
        120;  // fixed ticks before a cell whose load failed is tried again while it is still wanted
    static constexpr int kMaxHlodProxies = 512;       // proxies prepared at once (the nearest cells)
    static constexpr int kMaxProxyLoadsInFlight = 4;  // proxy models read at once
    static constexpr double kProxyKeepFactor =
        1.1;  // a proxy stays until the anchors are this much farther than the range (hysteresis)
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
    // True while a cell is loading, waiting to be applied or to be unloaded, or a proxy is prepared: the engine ticks the streamer even when
    // the loader is idle.
    bool busy() const { return !tracked_.empty() || !proxies_.empty(); }

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
    // The HLOD proxy of a cell: None (not wanted), Loading (its model is being read), Ready (in the renderer's cache) or Failed (reported;
    // tried again after kRetryTicks fixed ticks while it is wanted, forgotten once it is not).
    enum class Proxy { None, Loading, Ready, Failed };
    struct CellState {
        State state = State::Unloaded;
        Proxy proxy = Proxy::None;
        int proxyJob = 0;                     // BackgroundLoader job id while the proxy is Loading
        std::uint64_t proxyFailedAtTick = 0;  // tick_ when the proxy failed (Failed: tried again after kRetryTicks)
        bool proxyWarned = false;             // a failure was reported and the cell has stayed in range since
        Entity proxyEntity;                   // the entity that draws the proxy now (null = not shown)
        int job = 0;                          // BackgroundLoader job id while Loading
        std::shared_ptr<const Json> doc;      // the parsed scene, once the job finished and before it is applied
        // its load failed: tried again after kRetryTicks fixed ticks, or once it has left the wanted set
        bool failed = false;
        std::uint64_t failedAtTick = 0;  // tick_ when it failed
        Entity root;                     // the cell's root entity while Loaded
        std::int64_t entities = 0;       // entities under the root
        std::uint64_t bytes = 0;         // bytes its load read
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
        double hlodDistance = 0;  // StreamedWorld.hlodDistance (0 = no proxy)
    };

    static const char* proxy_name(const CellState& st);
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
    void update_proxies(const std::vector<Anchor>& anchors);  // fixed tick: which proxies are wanted, start their loads
    void take_proxy_result(const BackgroundLoader::CellResult& r);
    void mark_proxy_failed(std::size_t idx, const std::string& message, const std::string& hint);
    void sync_proxies();                  // frame: show a proxy where its cell is not loaded, hide it where it is
    void release_proxy(std::size_t idx);  // cancel its job, destroy its entity, forget it (whatever its state)
    void drop_proxies();                  // release every proxy (an index change, a scene change that keeps the world)

    World& world_;
    BackgroundLoader& loader_;
    WorldIndex index_;
    std::string indexPath_;          // the path index_ was read from ("" = none)
    std::string failedPath_;         // a path whose index was wrong (not read again until the path changes)
    std::vector<CellState> cells_;   // parallel to index_.cells
    std::set<std::size_t> tracked_;  // cells that are not Unloaded
    std::set<std::size_t> failed_;   // cells with `failed` set
    std::set<std::size_t>
        proxies_;  // cells whose proxy is not None (a Failed one stays until its retry or until the cell is out of range)
    Settings settings_;
    std::int64_t minI_ = 0, maxI_ = -1, minJ_ = 0, maxJ_ = -1;  // the coordinate range of the index
    std::string lastError_;
    std::string
        lastErrorCell_;  // the id of the cell lastError_ is about ("" = the index or no cell): its next good load clears it
    std::uint64_t tick_ = 0;  // fixed ticks seen by update()
    // statistics (world.stream_status)
    std::int64_t proxyLoadsStarted_ = 0;
    std::int64_t loadsStarted_ = 0, loadsCancelled_ = 0, cellsApplied_ = 0, unloadsDone_ = 0, bytesLoaded_ = 0;
    int appliedThisFrame_ = 0, unloadedThisFrame_ = 0, unitsThisFrame_ = 0;
    std::size_t anchorCount_ = 0;
    mutable bool warnedMultiple_ = false;
};

// The ABSOLUTE position on the plane of the world of a local position: the floating origin `origin` (World::origin(), docs/BIG_WORLDS.md
// "Floating origin") plus the local position, added in doubles, on the plane axes of the index (x and z for "3d", x and y for "2d").
void absolute_plane_position(const WorldIndex& index, const DVec3& origin, Vec3 local, double& a, double& b);

}  // namespace fa
