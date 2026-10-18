// Private declarations shared by publish.cpp (planning, tools, running, the commands) and publish_stores.cpp (what each
// store's uploader is given). The public API is fa/tooling/publish.h.
#pragma once

#include <filesystem>
#include <map>
#include <string>
#include <utility>
#include <vector>

#include "export_internal.h"
#include "fa/tooling/publish.h"

namespace fa::publish_detail {

namespace stdfs = export_detail::stdfs;
using export_detail::err;
using export_detail::generic;
using export_detail::os_path;

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
    std::string launch;    // the game's executable relative to `path` (forward slashes): <exe>, <Name>.app/Contents/MacOS/<exe> (desktop_exe_name)
};

// What a planner works with.
struct Context {
    PublishOptions options;
    stdfs::path projectDir;
    stdfs::path workDir;        // <project>/.factoria/publish/<store>: the files the uploader reads
    std::string name, slug, safeName, version;
    PublishSettings settings;
    std::vector<Folder> folders;
    // The mobile stores upload one built file instead of folders (Store::mobile):
    stdfs::path artifact;       // absolute .ipa / .aab
    bool artifactGiven = false; // the `artifact` option named it (so FactorIA did not build it and cannot tell how it was signed)
    std::string bundleId, iosBuild;  // "id" of factoria.json: bundle id / Android package; iOS CFBundleVersion
    int androidVersionCode = 0;
    bool androidKeystore = false;    // export.android.signing.keystore is set in factoria.json
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
    std::vector<stdfs::path> clearDirs;  // emptied first (build files that must not outlive their settings)
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
    std::string mobile;                   // "ios" | "android": uploads one built file (.ipa / .aab), not the desktop export folders
    bool macOnly = false;                 // the uploader exists only on macOS (App Store Connect's altool)
};

const Store* find_store(const std::string& name);

inline bool is_dir(const stdfs::path& p) {
    std::error_code ec;
    return stdfs::is_directory(os_path(p), ec);
}
inline bool is_file(const stdfs::path& p) {
    std::error_code ec;
    return stdfs::is_regular_file(os_path(p), ec);
}

}  // namespace fa::publish_detail
