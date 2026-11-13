// The first-use order of a game's files, kept per project in .factoria/cache/load-order.json, and the pack order a
// release export builds from it (docs/EXPORTING.md, "Compression and pack order").
//
// A play session (the editor's Play, `factoria run`, play.auto) runs with a load trace (fa/core/load_trace.h): the files
// read before the first scene (the group LoadTrace::kStartupScene: factoria.json, the start-up scripts), then for each
// scene the project files first read while it was the current scene, in the order they were read. When the session ends
// the engine hands that order to EngineConfig::loadOrderSink, and the tools merge it into the project's file here.
//
// Which session wins. A COLD session (`factoria run`, play.auto: a fresh engine that reads every file it needs itself)
// sets a scene's order: its files come first in the order it read them, the files earlier sessions recorded for that
// scene and this one did not read follow in their old order, and the scene is marked cold. An EDITOR session (Play in
// the editor, whose engine has most files cached from Edit mode and reads only the rest) never reorders a scene: it only
// adds the files the scene did not list yet, at its end. A scene not seen before is added after the others either way.
// So the order comes from the cold runs whenever there was one, and editor Plays only fill in what they missed.
//
//   { "format": "factoria.loadorder/1",
//     "scenes": [ { "scene": "(start-up)", "files": ["factoria.json", ...], "source": "run" },
//                 { "scene": "scenes/main.scene.json", "files": ["scenes/main.scene.json", "assets/hero.png", ...],
//                   "source": "editor" }, ... ] }
//
// A release export then writes game.pak in that order (PackWriter::set_order), so the files a scene needs lie next to
// each other in the pack, in the order the game asks for them. The file is a cache: nothing a game does depends on it,
// a missing or damaged one only means the export packs by path. Every write is a read-modify-write under the project's
// lock (ShareLock in .factoria/cache, fa/tooling/feedback_share.h): two sessions that end at once both land, and a lock
// that cannot be taken is reported and changes nothing. Nothing is recorded for an exported game (a folder inside an
// export, found by its .factoria-export marker, or while a game pack is mounted): a shipped player has no trace, and
// `factoria run` on an export must not write into the game it ships.
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

// Who recorded an order (see "Which session wins" above).
enum class LoadOrderSource {
    Editor,  // the editor's Play: only adds files
    Run,     // `factoria run`, play.auto: sets the order of the scenes it played
};

struct LoadOrderMerge {
    std::size_t scenes = 0;  // scenes in the file after the merge
    std::size_t files = 0;   // file entries in it
    std::size_t added = 0;   // entries this merge added
    bool changed = false;  // the merge changed the order (new files, a reorder by a cold session, a scene marked cold)
    bool skipped = false;  // nothing recorded: the project is an exported game (load_order_recordable)
};

// `recorded` with `seen` merged in (see the top of this file). Pure and deterministic.
LoadOrder merge_load_order(LoadOrder recorded, const LoadOrder& seen, LoadOrderMerge* stats = nullptr,
                           LoadOrderSource source = LoadOrderSource::Editor);

// False (with the reason in `why`) when a session of this project must not record: the folder is inside an exported
// game (it or one of its parents holds the export's .factoria-export marker) or a game pack is mounted in this process.
bool load_order_recordable(const std::filesystem::path& projectDir, std::string* why = nullptr);

// The project's recorded order; empty when there is no file. An error when the file is there but is not a load order
// (its path, the JSON pointer and what to do in the message).
Result<LoadOrder> read_load_order(const std::filesystem::path& projectDir);

// Merges `seen` into the project's file under the lock. An error (nothing written) when the lock is busy or the folder
// cannot hold it, or the file cannot be written; a damaged file is replaced by the merge of `seen` alone. For an exported
// game it writes nothing and returns `skipped`.
Result<LoadOrderMerge> record_load_order(const std::filesystem::path& projectDir, const LoadOrder& seen,
                                         LoadOrderSource source = LoadOrderSource::Editor);
// record_load_order that logs a failure as a warning ("loadorder" category) instead of returning it: for a session's end.
void record_load_order_logged(const std::filesystem::path& projectDir, const LoadOrder& seen,
                              LoadOrderSource source = LoadOrderSource::Editor);
// The same on a background thread, one write after the other, for a UI thread that must never wait on a lock or a disk
// (the editor's Play, an Editor source). wait_load_order_writes() returns once every write queued before the call is done.
void record_load_order_async(std::filesystem::path projectDir, LoadOrder seen);
void wait_load_order_writes();

// The order game.pak is written in: the start-up group's files first (what the game reads before its first scene), then
// the main scene's, then each other scene's in the recorded order, each file once and only when it is in `shipped` (the
// project-relative paths the export packs). Files the order does not name follow by path (PackWriter does that).
// `scenes` counts the recorded groups (the start-up group and each scene) that gave at least one file.
struct PackOrder {
    std::vector<std::string> files;
    std::size_t scenes = 0;
};
PackOrder pack_order(const LoadOrder& recorded, std::string_view mainScene, const std::vector<std::string>& shipped);

}  // namespace fa
