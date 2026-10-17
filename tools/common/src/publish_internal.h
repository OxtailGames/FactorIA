// Private declarations shared by publish.cpp (planning, tools, running, the commands) and publish_stores.cpp (what each
// store's uploader is given). The public API is fa/tooling/publish.h.
#pragma once

#include <filesystem>
#include <map>
#include <string>
#include <utility>
#include <vector>

#include "fa/tooling/publish.h"

namespace fa::publish_detail {

namespace stdfs = std::filesystem;

// Left out of every upload: they belong to the export, not to the game (docs/EXPORTING.md). Paths are relative to the
// export folder.
inline const std::vector<std::string>& excluded_files() {
    static const std::vector<std::string> files = {".factoria-export", "AI_CONTENT_DISCLOSURE.md"};
    return files;
}

inline constexpr const char* kRedacted = "<redacted>";

// One export folder to upload.
struct Folder {
    std::string platform;  // windows | macos | linux
    stdfs::path path;      // absolute
    std::string launch;    // the game's executable relative to `path` (forward slashes): <slug>.exe, <slug> (game-bin for the slug game), <Name>.app/Contents/MacOS/<slug>
};

// What a planner works with.
struct Context {
    PublishOptions options;
    stdfs::path projectDir;
    stdfs::path workDir;        // <project>/.factoria/publish/<store>: the files the uploader reads
    std::string name, slug, safeName, version;
    PublishSettings settings;
    std::vector<Folder> folders;
    std::string tool;           // absolute path of the uploader
    std::vector<std::string> warnings, nextSteps;
};

// One run of an uploader.
struct Job {
    std::string title;
    std::vector<std::string> argv;    // argv[0] is filled in by the runner (the tool found); planners leave it empty
    std::vector<std::string> shown;   // argv with every secret replaced by kRedacted (same length)
    std::map<std::string, std::string> env;  // added to the child's environment; values are never shown
    std::vector<std::pair<stdfs::path, std::string>> files;  // written before the run (and in a dry run)
    std::vector<stdfs::path> dirs;    // created before the run (and in a dry run): folders the uploader expects to exist
    std::vector<std::pair<std::string, std::string>> uploads;  // (platform, destination) this run uploads
    std::vector<std::string> secrets; // values scrubbed from the log and the progress lines
    std::string failureHint;          // what to check when this uploader fails
};

struct Store {
    std::string name;                     // steam
    std::string tool;                     // steamcmd: the name used in messages
    std::string envVar;                   // FACTORIA_STEAMCMD: names the executable or its folder
    std::string configKey;                // "steamcmd" in the "publish" object of ~/.factoria/export.json
    std::vector<std::string> exeNames;    // what to look for on PATH and inside a folder (".exe" is added on Windows)
    std::string download;                 // where to get it, for the error
    bool needsLaunch = false;             // the game's executable is part of what the store is told (Epic, GOG)
    // Does factoria.json say enough about `platform` to upload it to this store? (Steam: a depot; Epic: an artifact.)
    bool (*configured)(const PublishSettings&, const std::string& platform) = nullptr;
    // Fills `jobs` (and warnings/nextSteps in the context). An Error means nothing is written or run.
    Result<std::vector<Job>> (*plan)(Context&) = nullptr;
};

const Store* find_store(const std::string& name);

inline std::string generic(const stdfs::path& p) { return p.generic_string(); }

}  // namespace fa::publish_detail
