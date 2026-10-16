// Virtual file system.
//
// Game code and data refer to files with PROJECT-RELATIVE paths using forward
// slashes: "assets/player.png", "scenes/main.scene.json". The VFS maps them to
// the platform location:
//   desktop  -> <project root>/<path>
//   android  -> APK assets (AAssetManager), read-only
//   ios      -> app bundle resources, read-only
// Absolute paths are accepted on desktop (tools use them); on mobile they fail.
// Writes are for tools and save games; game data on mobile is read-only.
#pragma once

#include <cstdint>
#include <filesystem>
#include <functional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/types.h"

namespace fa::fs {

void set_project_root(const std::filesystem::path& root);
const std::filesystem::path& project_root();

// Writable per-user directory for save games / settings (created on demand):
//   desktop: <project>/.factoria/save  (dev) or OS app-data dir (shipped player)
//   mobile : app documents directory
void set_user_dir(const std::filesystem::path& dir);
const std::filesystem::path& user_dir();

// Creates a fresh, empty scratch directory under the system temp folder, named <prefix>_<process id>_<n>. Unique per
// process and call, so concurrent processes (parallel test runs, several agents building and testing at once) never
// share one. The caller removes it when done.
std::filesystem::path make_temp_dir(std::string_view prefix);

// Platform backends (called once by fa_platform at startup on mobile).
void set_android_asset_manager(void* aassetManager);

// Normalizes "./a\\b/../c" -> "a/c". Rejects paths escaping the root ("../x")
// for project-relative input.
// Returns "" if a project-relative path escapes the root; use normalize_checked
// when you want the explanation.
std::string normalize(std::string_view path);
// Same, but the error says why and how to fix it.
Result<std::string> normalize_checked(std::string_view path);
bool is_absolute(std::string_view path);
std::filesystem::path resolve(std::string_view path);  // absolute host path (desktop)

// The form of a host path to hand to the OS. On Windows a path of 248 characters or more (MAX_PATH, 260, minus room for
// an 8.3 file name: the folder limit) comes back absolute, with backslashes and the \\?\ prefix, which lifts the limit
// whether or not long paths are enabled on the machine; elsewhere, and for shorter paths, `p` as it is. For file system
// calls only: show users the path itself.
std::filesystem::path os_path(const std::filesystem::path& p);

Result<std::string> read_text(std::string_view path);
Result<std::vector<std::uint8_t>> read_bytes(std::string_view path);
Result<void> write_text(std::string_view path, std::string_view text);  // creates parent dirs
Result<void> write_bytes(std::string_view path, const void* data, std::size_t size);
bool exists(std::string_view path);
bool is_directory(std::string_view path);
std::int64_t modified_time(std::string_view path);  // -1 if missing; any monotonic unit

// Lists files (project-relative paths, sorted). `extension` like ".png" filters.
std::vector<std::string> list(std::string_view dir, bool recursive = true, std::string_view extension = {});

std::string extension(std::string_view path);  // ".png" (lowercase)
std::string filename(std::string_view path);   // "player.png"
std::string stem(std::string_view path);       // "player"
std::string parent(std::string_view path);     // "assets"
std::string join(std::string_view a, std::string_view b);

// ---- Write policy of the project folder -------------------------------------------------------------------------
// The VCS folder and `.factoria/` belong to tools: the engine and the editor keep screenshots, save games, AI
// transcripts and editor state in `.factoria/`. Commands that write or delete a file whose path comes from the caller
// (scene.save, scene.import_ascii with `path`, fs.write, fs.edit, fs.delete) refuse to touch them, with ONE exception:
// the scratch folder `.factoria/tmp/` is the place for throw-away files (generated inputs, test output). Everything in
// it may be created, overwritten and deleted by those commands; like the rest of `.factoria/` it is not committed.
constexpr const char* kScratchDir = ".factoria/tmp";

// `relativePath` is project-relative and normalized (forward slashes, no "." or ".." segments).
bool is_scratch_path(std::string_view relativePath);  // ".factoria/tmp" or anything below it
bool is_managed_path(std::string_view relativePath);  // the VCS folder, ".factoria" or below, except the scratch folder
// Ok when a command may write or delete `path` (project-relative, or absolute: then only paths inside the project root
// are judged). The error names the folder that is allowed (`.factoria/tmp/`).
Result<void> check_writable(std::string_view path);

// Polling file watcher for hot reload (desktop only; no-op on mobile).
class Watcher {
public:
    using Callback = std::function<void(const std::string& path)>;
    int watch(std::string path, Callback onChange);  // returns id
    void unwatch(int id);
    void poll();  // call ~4 times per second; fires callbacks for changed files

private:
    struct Entry {
        int id;
        std::string path;
        std::int64_t mtime;
        Callback cb;
    };
    std::vector<Entry> entries_;
    int nextId_ = 1;
};

}  // namespace fa::fs
