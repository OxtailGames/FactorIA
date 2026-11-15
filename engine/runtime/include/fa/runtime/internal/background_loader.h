// Background loading of an Engine: scene.preload, assets.preload and scene.load {async: true} (docs/PERFORMANCE.md,
// "Background loading"; docs/ARCHITECTURE.md, "Background loading").
//
// A JOB reads what a scene or a list of files needs, off the main thread, and puts it where the first use finds it:
//   - the SCAN (one unit) reads the scene (or the listed JSON files and scripts) and everything they point at that is
//     text (prefabs, materials, scripts, .gltf models) into the file system's warm set, and lists the binary files;
//   - then one UNIT per binary file: a texture, a model or a font the renderer decodes into its cache, a sound the mixer
//     decodes into its cache, any other file (a .bin buffer, a video) only made warm. Models come last, so the textures
//     they name are in the cache when they are uploaded.
// Each unit is an IoQueue item (fa/core/background_io.h): the IO thread reads it, a job decodes it, and the main thread
// TAKES it in tick(), which uploads it to the GPU (the only part that runs on the main thread). A unit whose asset is in
// the cache already does nothing.
//
// How many units a frame takes is the BUDGET:
//   exact (tests, headless runs, the editor, replays): exactly `units` units this frame, in a fixed order, waiting for each
//          when it is not ready; so a run gives the same frames on any machine, with any number of worker threads;
//   timed (a game with a window): the units that are READY, in the same fixed order, until `ms` milliseconds or
//          `uploadMB` megabytes of GPU uploads are spent (at least one unit when the queue is not threaded). A frame never
//          waits for a file. A replay of such a session takes the recorded count of units per frame.
// The fixed order: round after round, one unit of each job in the order the jobs started. A timed frame stops at the
// first job whose next unit is not ready, so what it took is always a prefix of that order and a count replays it.
//
// Warm files are counted across the loaders of every engine in the process (a reference per item that read a file, then
// per job or finished load holding it): fs::unwarm runs when the last reference goes, so one engine's cancel never drops
// a file another engine read ahead.
// The warm files of a job are dropped once what they hold is in a cache. Those still warm when it finishes (the scene
// file, scripts, prefabs, files the renderer does not decode) stay through the first scene load after it finished and are
// dropped at the second (or by cancel()), so memory stays bounded: about one scene's files beyond the one in use.
//
// Main thread only. Results never outlive the loader: a decode still running when it stops is thrown away.
#pragma once

#include <cstdint>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <vector>

#include "fa/core/background_io.h"
#include "fa/core/json.h"
#include "fa/core/load_trace.h"
#include "fa/render/renderer.h"

namespace fa {

class Audio;

class BackgroundLoader {
public:
    static constexpr int kFixedUnitsPerFrame = 4;   // the exact budget of a run that does not depend on the machine
    static constexpr int kMaxInFlight = 16;         // units one job has queued on the IO thread at once
    static constexpr std::size_t kHistory = 16;     // finished jobs load.status still answers for
    static constexpr int kMaxReplayUnits = 100000;  // the most units a replay entry may ask for in one frame

    enum class Kind { ScenePreload, Assets, SceneLoad };
    enum class Origin { Script, Tool };  // who started it: a script (its handle gets the updates) or a command

    struct Budget {
        bool exact = true;
        int units = kFixedUnitsPerFrame;  // exact: units this frame (0: none)
        double ms = 4.0;                  // timed: main-thread milliseconds
        double uploadMB = 16.0;           // timed: GPU upload megabytes
    };
    struct Update {
        int id = 0;
        Origin origin = Origin::Script;
        int done = 0, total = 1;  // units: the scan counts as one
        std::uint64_t bytes = 0, uploadedBytes = 0;
        bool finished = false, cancelled = false;
        std::string error, hint;
        Json to_json() const;  // {id, done, total, bytes, uploadedBytes, finished, cancelled, error, hint}
    };
    struct
        SceneReady {  // an async scene load whose files are ready: the engine switches to it at the end of this frame
        int id = 0;
        std::string path;
        std::optional<Json> props;
        std::uint64_t traceTag = 0;
        Origin origin = Origin::Tool;
    };
    struct Frame {
        std::vector<Update> updates;  // the jobs that changed (and those cancelled since the last tick)
        std::vector<SceneReady> scenes;
        int units = 0;  // units taken (what a recording keeps)
        std::uint64_t uploadedBytes = 0;
    };

    BackgroundLoader(jobs::Owner* jobs, LoadTrace::Owner traceOwner);
    ~BackgroundLoader();
    BackgroundLoader(const BackgroundLoader&) = delete;
    BackgroundLoader& operator=(const BackgroundLoader&) = delete;

    // Starts a job. Checks the paths at once: a missing file is an error with "did you mean" (nothing starts). `trace`:
    // the engine's load trace (null: none); an async scene load opens its entry there. Starting an async scene load
    // cancels the async scene loads before it (the last request wins).
    Result<int> start(Kind kind, const std::vector<std::string>& paths, std::optional<Json> props, Origin origin,
                      LoadTrace* trace);
    // Stops a running job (its update, cancelled, comes with the next tick) or gives a finished job's warm files back.
    // False when the id is unknown.
    bool cancel(int id, LoadTrace* trace);
    // Cancels every async scene load still loading (a scene change was asked for meanwhile). Returns how many.
    int cancel_scene_loads(LoadTrace* trace);
    // Cancels every job a script started (its JavaScript context is gone) and forgets their updates not delivered yet.
    void cancel_origin(Origin origin, LoadTrace* trace);
    // Cancels every job and drops every file this loader holds warm (a script test file starts afresh). Files another
    // engine's loader holds stay warm.
    void reset(LoadTrace* trace);
    // Cancels every job and drops its files; the IO thread lets go of this engine's files before it returns. The engine
    // then waits for its jobs owner (the decodes still running) and destroys the loader.
    void stop(LoadTrace* trace);

    Frame tick(Renderer* renderer, Audio* audio, const Budget& budget);
    // A scene was loaded: the warm files of the jobs that finished before it are dropped at the second load.
    void scene_loaded();

    bool active() const { return !jobs_.empty() || !pending_.empty() || !orphans_.empty(); }
    bool loading() const { return !jobs_.empty(); }  // a job runs: this frame's units count (recordings)
    bool threaded() const { return io_.threaded(); }
    // load.status: one job (null when unknown), or {"jobs": [...running and recent...], "threaded", "warmBytes"}.
    Json status(int id) const;
    Json status_all() const;

    struct Shared;  // what a queued item shares with the main thread (background_loader.cpp)

private:
    enum class UnitKind { Warm, Render, Sound };
    struct Unit {
        std::string path;
        UnitKind kind = UnitKind::Warm;
        Renderer::BackgroundKind renderKind = Renderer::BackgroundKind::None;
        bool trivial = false;  // cached already: nothing to read
        IoQueue::Ticket ticket = 0;
        std::shared_ptr<Shared> shared;
    };
    struct Job {
        int id = 0;
        Kind kind = Kind::Assets;
        Origin origin = Origin::Script;
        std::vector<std::string> roots;
        std::optional<Json> props;
        std::uint64_t tag = 0;  // its reads' load-trace tag (fa/core/load_trace.h)
        bool scanned = false;
        IoQueue::Ticket scanTicket = 0;
        std::shared_ptr<Shared> scanShared;
        std::vector<Unit> units;
        std::size_t nextSubmit = 0, nextTake = 0;
        int done = 0, total = 1;
        double progress = 0.0;
        std::uint64_t bytes = 0, uploaded = 0;
        std::set<std::string> warmed;  // files this job holds warm
        std::string error, hint;
        bool cancelled = false;
        bool finished() const { return cancelled || !error.empty() || (scanned && nextTake >= units.size()); }
    };
    void submit_scan(Job& job);
    void submit_units(Job& job, Renderer* renderer);
    bool front_ready(const Job& job) const;
    void run_unit(Job& job, Renderer* renderer, Audio* audio, std::uint64_t& uploaded);
    void take_scan(Job& job, Renderer* renderer, Audio* audio);
    void abandon(Job& job);                        // its queued items become orphans; its warm files are dropped
    void hold(Job& job, const std::string& path);  // the job takes over an item's reference to a warm file
    void drop(const std::string& path);            // gives one reference back (warm_release)
    void collect_orphans(bool all);
    void remember(const Job& job);
    Json job_status(const Job& job) const;
    Update update_of(const Job& job) const;

    IoQueue io_;
    LoadTrace::Owner traceOwner_;
    std::vector<Job> jobs_;
    std::vector<Update> pending_;                   // updates of jobs cancelled since the last tick
    std::vector<std::shared_ptr<Shared>> orphans_;  // items of cancelled jobs the IO thread may still be reading
    struct Kept {
        std::set<std::string> files;
        int loads = 0;  // scene loads since the job finished
    };
    std::map<int, Kept> kept_;
    std::vector<Json> history_;  // the status of the last kHistory jobs that ended
    int nextId_ = 1;
};

}  // namespace fa
