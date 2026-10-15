// Engine updates for the downloaded packages (docs/GETTING_STARTED.md, "Updates").
//
// The editor checks GitHub Releases when it opens and, when a newer version is published, shows its release notes
// with Update / Not now. Update downloads this OS's package and replaces the files of the folder factoria runs from.
// Builds from source have no update repository (FA_UPDATE_REPO is empty, see CMakeLists.txt) and never update.
#pragma once

#include <cstdint>
#include <filesystem>
#include <functional>
#include <string>
#include <string_view>

#include "fa/ai/http.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

struct UpdateInfo {
    std::string current;           // this build's version (FA_ENGINE_VERSION)
    std::string latest;            // newest published release newer than `current`; "" = up to date
    std::string packageUrl;        // download of this OS's package in that release
    std::uint64_t packageSize = 0; // bytes (0 = unknown)
    std::string notes;             // Markdown: the notes of every release newer than `current`, newest first
    bool available() const { return !latest.empty(); }
};

// GitHub "owner/repo" this build updates from; "" when updates are off (builds from source).
std::string update_repo();
// Name of this OS's release package: FactorIA-windows-x64.zip, FactorIA-macos-arm64.tar.gz, FactorIA-linux-x64.tar.gz.
std::string update_package_name();
// True when version `a` is newer than `b` ("1.10.0" > "1.9.2"; a leading "v" is ignored).
bool version_newer(std::string_view a, std::string_view b);

// Reads a GitHub "list releases" reply (drafts and pre-releases are skipped).
Result<UpdateInfo> parse_releases(const Json& releases, std::string_view current);
// Asks GitHub for the releases of update_repo(). Up to date (or updates off) => !available().
Result<UpdateInfo> check_for_update(const ai::HttpTransport& http = ai::http_request);

// Downloads the package and replaces the files of `installDir` with the ones in it. A replaced file is kept as
// <name>.old, since Windows cannot overwrite a running exe (it can rename it); a failure puts the old files back.
// `progress` gets 0..1 while downloading.
Result<void> install_update(const UpdateInfo& info, const std::filesystem::path& installDir,
                            const std::function<void(double)>& progress = {},
                            const ai::HttpTransport& http = ai::http_request);
// Deletes the <name>.old files and the download folder a previous install_update left in `installDir`.
void remove_update_leftovers(const std::filesystem::path& installDir);

// Starts `factoria editor [projectDir]` from executable_dir() as a new process (the restart after an update).
Result<void> start_editor_process(const std::string& projectDir);

}  // namespace fa
