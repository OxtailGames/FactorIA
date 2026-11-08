// Load trace: which game files a run reads, in which order, and how long its loads take.
//
// While a LoadTrace object exists, every read through fa::fs (read_bytes, read_text, read_view, warm) is recorded in
// it: the path, the bytes, whether it came from the game pack (and how many bytes it took there), and the time of the
// read. Loaders that turn bytes into something (textures, meshes, sounds, fonts) wrap their work in an AssetLoadScope,
// which records the asset with the time the read took and the time the rest (the decode) took. Hosts that develop a
// game create one (the engine does when EngineConfig::traceLoads is on: `factoria run`, `play.auto`, a Play in the
// editor); a shipped game never does, and without a trace each hook costs one relaxed atomic load.
//
// Two results come out of it:
//   - order(): for each scene loaded during the trace, the files first read while it was the current scene, in the order
//     they were first read. `factoria export` packs game.pak in that order (fa/core/pack.h, PackWriter::set_order).
//   - report(): the "loading" section of a play report (time to the first frame, load time per scene, the slowest
//     assets, the reads). Times depend on the machine: they are rounded to 0.1 ms and are never a pass or a fail.
//
// Caps are counts (deterministic): at most kMaxFiles distinct files in the order, kMaxScenes scene loads, the
// kMaxSlowest slowest assets; anything above is counted in the totals only. Thread-safe: reads on loader threads are
// recorded too. Times come from a steady clock, never the simulation's: nothing here changes what a game does.
#pragma once

#include <atomic>
#include <cstdint>
#include <mutex>
#include <string>
#include <string_view>
#include <unordered_set>
#include <vector>

#include "fa/core/json.h"

namespace fa {

// One scene's files in first-read order: an entry of LoadTrace::order().
struct SceneFiles {
    std::string scene;
    std::vector<std::string> files;
    bool operator==(const SceneFiles&) const = default;
};
using LoadOrder = std::vector<SceneFiles>;

class LoadTrace {
public:
    static constexpr std::size_t kMaxFiles = 20000;
    static constexpr std::size_t kMaxScenes = 64;
    static constexpr std::size_t kMaxSlowest = 10;

    LoadTrace();   // starts recording: the clock of time_to_first_frame starts now
    ~LoadTrace();  // stops
    LoadTrace(const LoadTrace&) = delete;
    LoadTrace& operator=(const LoadTrace&) = delete;

    // `scene` (a project-relative path, or a name for a scene that is not a file) starts loading: the files read from
    // now on are its files, and its load time runs until the next frame_ended().
    void scene_started(std::string scene);
    // A frame was drawn (or simulated) completely: closes the first frame and the load time of a scene started before it.
    void frame_ended();

    LoadOrder order() const;
    // {"timeToFirstFrameMs", "scenes": [{"scene", "loadMs", "files", "bytes"}], "slowestAssets": [{"kind", "path",
    //  "bytes", "readMs", "decodeMs"}], "reads": {"count", "bytes", "fromPack", "packStoredBytes"}, "note"}.
    // A time that was not reached yet (no frame ended) is null.
    Json report() const;

    // ---- hooks (fa::fs and the loaders call them; cheap when no trace exists) ----
    static bool any() { return activeCount_.load(std::memory_order_relaxed) > 0; }
    // A file read finished: `bytes` returned, `storedBytes` taken from the pack (== bytes for a loose file).
    static void file_read(std::string_view path, std::uint64_t bytes, std::uint64_t storedBytes, bool fromPack, std::int64_t readNs);
    static std::int64_t now_ns();  // the steady clock of every time here
    // Nanoseconds this thread spent in file reads since it started (AssetLoadScope subtracts it from its total).
    static std::int64_t thread_read_ns();

private:
    friend class AssetLoadScope;
    static void asset_loaded(std::string_view kind, std::string_view path, std::uint64_t bytes, std::int64_t totalNs, std::int64_t readNs);
    void record_file(std::string_view path, std::uint64_t bytes, std::uint64_t storedBytes, bool fromPack);
    void record_asset(std::string_view kind, std::string_view path, std::uint64_t bytes, std::int64_t totalNs, std::int64_t readNs);

    struct SceneLoad {
        std::string scene;
        std::int64_t startNs = 0, endNs = -1;
        std::uint64_t files = 0, bytes = 0;
    };
    struct Asset {
        std::string kind, path;
        std::uint64_t bytes = 0;
        std::int64_t readNs = 0, decodeNs = 0;
    };

    static std::atomic<int> activeCount_;

    mutable std::mutex mutex_;
    std::int64_t startNs_ = 0, firstFrameNs_ = -1;
    std::vector<SceneLoad> loads_;
    LoadOrder order_;
    std::size_t current_ = 0;  // the entry of order_ new files go to
    std::unordered_set<std::string> seen_;
    std::vector<Asset> slowest_;  // sorted by decode time, longest first
    std::uint64_t reads_ = 0, bytes_ = 0, packReads_ = 0, packStored_ = 0;
};

// Wraps one asset load (a texture, a mesh, a sound, a font) for the load trace: records it, with the decode time (its
// whole time minus the file reads it made on this thread), when it ends. Does nothing when no trace exists, and records
// nothing for a load that read no bytes (a built-in font, a primitive mesh, a file that is missing).
class AssetLoadScope {
public:
    AssetLoadScope(const char* kind, std::string_view path);
    ~AssetLoadScope();
    AssetLoadScope(const AssetLoadScope&) = delete;
    AssetLoadScope& operator=(const AssetLoadScope&) = delete;
    void set_bytes(std::uint64_t bytes) { bytes_ = bytes; }  // the size of the file it read (else the bytes its reads returned)

private:
    const char* kind_;
    std::string path_;
    std::int64_t startNs_ = -1, readStartNs_ = 0;
    std::uint64_t bytes_ = 0, readBytesStart_ = 0;
};

}  // namespace fa
