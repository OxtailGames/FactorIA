// The first-use order of a game's files, kept per project in .factoria/cache/load-order.json, and the pack order a
// release export builds from it (docs/EXPORTING.md, "The game pack").
//
// A play session (the editor's Play, `factoria run`, play.auto) runs with a load trace (fa/core/load_trace.h): for each
// scene, the project files first read while it was the current scene, in the order they were read. When the session
// ends the engine hands that order to EngineConfig::loadOrderSink, and the tools merge it into the project's file here:
// a scene seen before keeps its files and gains the new ones at the end, a new scene is added after the others. A
// release export then writes game.pak in that order (PackWriter::set_order), so the files a scene needs lie next to
// each other in the pack, in the order the game asks for them.
//
//   { "format": "factoria.loadorder/1",
//     "scenes": [ { "scene": "scenes/main.scene.json", "files": ["scenes/main.scene.json", "assets/hero.png", ...] }, ... ] }
//
// The file is a cache: nothing a game does depends on it, a missing or damaged one only means the export packs by path.
// Every write is a read-modify-write under the project's lock (ShareLock in .factoria/cache, fa/tooling/feedback_share.h):
// two sessions that end at once both land, and a lock that cannot be taken is reported and changes nothing. A shipped
// player records nothing (it runs without a trace).
#pragma once

#include <cstddef>
#include <filesystem>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/load_trace.h"
#include "fa/core/types.h"

namespace fa {

inline constexpr const char* kLoadOrderFormat = "factoria.loadorder/1";
// Caps of the file, in entries (deterministic: what a session adds past them is left out, the rest stays).
inline constexpr std::size_t kLoadOrderMaxScenes = 256;
inline constexpr std::size_t kLoadOrderMaxFiles = 50000;

// <projectDir>/.factoria/cache/load-order.json
std::filesystem::path load_order_file(const std::filesystem::path& projectDir);

struct LoadOrderMerge {
    std::size_t scenes = 0;  // scenes in the file after the merge
    std::size_t files = 0;   // file entries in it
    std::size_t added = 0;   // entries this merge added
};

// `recorded` with `seen` merged in (see the top of this file). Pure and deterministic.
LoadOrder merge_load_order(LoadOrder recorded, const LoadOrder& seen, LoadOrderMerge* stats = nullptr);

// The project's recorded order; empty when there is no file. An error when the file is there but is not a load order
// (its path, the JSON pointer and what to do in the message).
Result<LoadOrder> read_load_order(const std::filesystem::path& projectDir);

// Merges `seen` into the project's file under the lock. An error (nothing written) when the lock is busy or the folder
// cannot hold it, or the file cannot be written; a damaged file is replaced by the merge of `seen` alone.
Result<LoadOrderMerge> record_load_order(const std::filesystem::path& projectDir, const LoadOrder& seen);
// record_load_order that logs a failure as a warning ("loadorder" category) instead of returning it: for a session's end.
void record_load_order_logged(const std::filesystem::path& projectDir, const LoadOrder& seen);
// The same on a background thread, one write after the other, for a UI thread that must never wait on a lock or a disk
// (the editor's Play). wait_load_order_writes() returns once every write queued before the call is done.
void record_load_order_async(std::filesystem::path projectDir, LoadOrder seen);
void wait_load_order_writes();

// The order game.pak is written in: the main scene's files first, then each other scene's in the recorded order, each
// file once and only when it is in `shipped` (the project-relative paths the export packs). Files the order does not
// name follow by path (PackWriter does that). `scenes` counts the recorded scenes that gave at least one file.
struct PackOrder {
    std::vector<std::string> files;
    std::size_t scenes = 0;
};
PackOrder pack_order(const LoadOrder& recorded, std::string_view mainScene, const std::vector<std::string>& shipped);

}  // namespace fa
