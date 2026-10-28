// Noticing that this very program was replaced on disk (docs/EDITOR.md "Updates", docs/MCP.md "After an update").
//
// A new FactorIA can be put over the old one without the in-app updater (files copied next to `factoria`). A program that is
// already running then keeps the old code: the editor, and the `factoria mcp` process an AI client started. UpdateWatch is the
// shared detection: a cheap look at the executable's size and modification time, and only when they changed a read of the
// build identity inside the file (the version and fingerprint markers of fa/core/build_info.h). The editor offers a restart;
// the MCP server restarts itself (fa/mcp/update_monitor.h). `engine.update_status` reports the result to AIs.
#pragma once

#include <cstdint>
#include <filesystem>
#include <functional>
#include <mutex>
#include <string>

#include "fa/core/command.h"
#include "fa/core/json.h"

namespace fa {

// The absolute path of the running executable, resolved once when the process starts (a file renamed to <name>.old by an
// update, as install_update does, would otherwise be reported under its new name). On Linux a " (deleted)" suffix is removed.
// Empty when the system cannot say.
std::filesystem::path executable_path();

// Which build a program is: the version and the commit fingerprint written in its bytes.
struct BuildId {
    std::string version;      // "0.3.0"; "" when the program has no version marker
    std::string fingerprint;  // 12 hex digits, "-dirty" appended for uncommitted changes; "" = none; "unknown" = no git
    // True when the fingerprint can be compared (a program built outside git says "unknown" and has none to compare).
    bool comparable() const { return !fingerprint.empty() && fingerprint != "unknown"; }
    bool empty() const { return version.empty() && fingerprint.empty(); }
    // "0.3.0 build f530fda3e543", "0.3.0" or "an unidentified build".
    std::string label() const;
    Json to_json() const;
};
// The build of this program (FA_ENGINE_VERSION and build_fingerprint()).
BuildId running_build_id();
// The build written in a file's bytes (any program that links fa_core), empty when the file is unreadable or has no marker.
// Reads the file in blocks: nothing is held in memory but one block.
BuildId read_build_id(const std::filesystem::path& file);

// The part of a file that says cheaply whether it changed.
struct FileStamp {
    bool exists = false;
    std::uint64_t size = 0;
    std::int64_t mtime = 0;  // the file system's own clock ticks; only compared, never converted
    bool operator==(const FileStamp& o) const { return exists == o.exists && size == o.size && mtime == o.mtime; }
    bool operator!=(const FileStamp& o) const { return !(*this == o); }
};
FileStamp file_stamp(const std::filesystem::path& file);
// Modification time of a file in milliseconds since 1970-01-01 UTC, 0 when the file does not exist.
std::int64_t file_mtime_ms(const std::filesystem::path& file);

enum class UpdateCheck {
    Unchanged,     // the file is as it was when last looked at
    Settling,      // the file changed (or is missing) but was not seen twice alike yet: it may still be being written
    Same,          // it changed but holds the build that runs (a rebuild of the same commit, a touch)
    Unidentified,  // it changed and has no comparable identity (no marker, or built outside git): never counted as an update
    Updated,       // it holds another build than the running one
};

// Watches one executable for being replaced by another build. Thread-safe.
//   check(): stat the file (microseconds). A different stamp must be seen twice in a row before the file is read, so that a
//   copy that is still going on is not read half way (Settling); then the build identity is read once for that stamp.
//   Pass `settled` = true to read at once (a command that must answer now).
class UpdateWatch {
public:
    UpdateWatch(std::filesystem::path executable, BuildId running);

    UpdateCheck check(bool settled = false);
    // Looks again without a stat: the state of the last check().
    bool updated() const;                 // the file holds another build than the running one
    BuildId running() const;
    BuildId on_disk() const;              // the running build until an update is seen
    const std::filesystem::path& executable() const { return executable_; }
    // The file's stamp as last examined; two updates in a row differ in it, which is how "quiet until the file changes
    // again" is told from "still the same update".
    FileStamp examined_stamp() const;

private:
    std::filesystem::path executable_;
    mutable std::mutex mu_;
    BuildId running_;
    BuildId onDisk_;
    FileStamp examined_;  // the stamp whose identity is in onDisk_
    FileStamp pending_;   // a stamp seen once, waiting to be seen again
    bool hasPending_ = false;
    bool updated_ = false;
    bool unidentified_ = false;
};

// The watch of this process: its executable_path() and running_build_id(), created on first use.
UpdateWatch& process_update_watch();

// What `engine.update_status` adds under "editor" or "mcp": whoever hosts the process (the editor, `factoria mcp`) sets it.
// Called on the thread that runs the command; keep it quick.
void set_update_status_extra(std::string key, std::function<Json()> provider);

// {running, onDisk, restartDue, state, executable, ...extras} for `watch` (checked now).
Json update_status_json(UpdateWatch& watch);

// Registers engine.update_status (read-only).
void register_update_commands(CommandRegistry& registry);

}  // namespace fa
