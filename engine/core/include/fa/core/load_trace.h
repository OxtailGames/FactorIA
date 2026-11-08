// Load trace: which game files a run reads, in which order, and how long its loads take.
//
// A trace belongs to an OWNER: a token unique in the process (LoadTrace::new_owner(); each Engine takes one when it is
// made, and no later engine ever gets the same one, so a read that arrives after its engine is gone is nobody's). It
// records the reads through fa::fs (read_bytes, read_text, read_view, warm) made while that owner is the thread's current
// reader, set by a LoadTrace::ReadingFor scope: the engine opens one in its public entry points (init, frame, step, the
// scene loads, render_now) and in the primitives under them (a frame, a draw, a scene load), so the runners, play.auto
// and the screenshots that call those directly are covered too. Reads outside such a scope are not the game's (the
// editor's panels and asset browser, an AI or MCP tool, another engine in the process such as an in-process play.auto,
// which has its own trace) and are left out. A trace made without an owner (kNoOwner) records every read of the process
// (tests, tools). Loaders that turn bytes into something
// (textures, meshes, sounds, fonts) wrap their work in an AssetLoadScope, which records the asset with the time the read
// took and the time the rest (the decode) took, for the same owner. Hosts that develop a game create one (the engine does
// when EngineConfig::traceLoads is on: `factoria run`, `play.auto`, a Play in the editor); a shipped game never does, and
// without a trace each hook costs one relaxed atomic load.
//
// Work handed to another thread keeps its owner: whoever queues a read or a decode on an IO thread or a job worker takes
// LoadTrace::current_owner() with the job and opens a ReadingFor(owner) around the job's work on that thread (the music
// loader's thread does, audio.cpp). That is how a background loader (M70.3) attributes its reads to the engine that asked
// for them; a thread is never an owner by itself.
//
// Two results come out of it:
//   - order(): the files read before the first scene (factoria.json, the start-up scripts) as the group kStartupScene,
//     then, for each scene loaded during the trace, the files first read while it was the current scene, in the order
//     they were first read. `factoria export` packs game.pak in that order (fa/core/pack.h, PackWriter::set_order).
//   - report(): the "loading" section of a play report (time to the first frame, load time per scene, the slowest
//     assets, the reads). Times depend on the machine: they are rounded to 0.1 ms and are never a pass or a fail.
//
// Caps are counts (deterministic): at most kMaxFiles distinct files in the order, kMaxScenes scene loads, the
// kMaxSlowest slowest assets; anything above is counted in the totals only. Thread-safe. Times come from a steady clock,
// never the simulation's: nothing here changes what a game does.
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
    // Set by the tools, never by a trace (fa/tooling/load_order.h): the order of this scene comes from a cold session
    // (`factoria run`, play.auto), which ranks above an editor Play's.
    bool cold = false;
    bool operator==(const SceneFiles&) const = default;
};
using LoadOrder = std::vector<SceneFiles>;

class LoadTrace {
public:
    static constexpr std::size_t kMaxFiles = 20000;
    static constexpr std::size_t kMaxScenes = 64;
    static constexpr std::size_t kMaxSlowest = 10;

    // The group of the files read before the first scene starts (the engine opens factoria.json by its absolute path, so it
    // is not one of them).
    static constexpr const char* kStartupScene = "(start-up)";
    // The token of whoever reads (an Engine): never reused within the process. kNoOwner: nobody's.
    using Owner = std::uint64_t;
    static constexpr Owner kNoOwner = 0;
    // A token no one had before (thread-safe).
    static Owner new_owner();

    // Starts recording the reads of `owner` (kNoOwner: every read): the clock of time_to_first_frame starts now.
    explicit LoadTrace(Owner owner = kNoOwner);
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

    // The owner this thread reads for now (kNoOwner outside every ReadingFor scope).
    static Owner current_owner();
    // Makes `owner` this thread's current reader until the scope ends (scopes nest: the previous one comes back, and a
    // scope for the owner that is current already changes nothing). Free.
    class ReadingFor {
    public:
        explicit ReadingFor(Owner owner);
        ~ReadingFor();
        ReadingFor(const ReadingFor&) = delete;
        ReadingFor& operator=(const ReadingFor&) = delete;

    private:
        Owner previous_;
    };

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

    bool records(Owner reader) const { return owner_ == kNoOwner || owner_ == reader; }

    const Owner owner_;
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
// whole time minus the file reads it made on this thread), when it ends, in the traces of the thread's current owner.
// Does nothing when no trace exists, and records nothing for a load that read no bytes (a built-in font, a primitive
// mesh, a file that is missing).
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
