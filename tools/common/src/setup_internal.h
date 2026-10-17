// Private declarations shared by the setup_*.cpp files (the public API is fa/tooling/setup.h).
//
//   setup.cpp          context defaults, status/install dispatch, JSON, commands, the helpers the export asks for
//   setup_core.cpp     downloading (curl), checksums, unpacking, moving into place, the install bookkeeping
//   setup_android.cpp  JDK + Android SDK
//   setup_players.cpp  factoria_player of the other OSes + prebuilt mobile libraries
//   setup_cmake.cpp    CMake for the iOS export
//   setup_xcode.cpp    Xcode: status and guidance
//   setup_appimage.cpp appimagetool + the AppImage runtime (Linux x86_64)
#pragma once

#include <chrono>
#include <filesystem>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "fa/tooling/setup.h"
#include "fa/tooling/setup_parse.h"

namespace fa::setup_detail {

namespace stdfs = std::filesystem;

// A failed step: a stable code (see SetupResult::code) and the teaching error.
struct Fail {
    std::string code;
    Error error;
};

// "190 MB", "1.2 GB", "512 KB".
std::string format_bytes(std::uint64_t bytes);
// Whole megabytes, rounded up (for installSizeMb).
int megabytes(std::uint64_t bytes);

inline std::string exe_suffix(const std::string& hostOs) { return hostOs == "windows" ? ".exe" : ""; }

bool is_file(const stdfs::path& p);
bool is_dir(const stdfs::path& p);

// ---- the install bookkeeping ---------------------------------------------------------------------------------------

// Collects the steps of one install, owns its staging folder (<home>/staging/<component>, emptied at the start and
// removed at the end, also when the install fails) and builds the result.
class Installer {
public:
    Installer(const SetupContext& ctx, std::string component);
    ~Installer();
    Installer(const Installer&) = delete;
    Installer& operator=(const Installer&) = delete;

    const SetupContext& ctx;
    SetupReport report;

    // The staging folder: created (and emptied of what a crashed run left) on the first use, so an install that has
    // nothing to download writes nothing.
    stdfs::path staging();
    // A fresh empty folder inside the staging folder.
    stdfs::path make_staging_subdir(const std::string& name);

    void add_step(SetupStep step);
    SetupResult fail(const Fail& f);
    SetupResult fail(std::string code, Error error);
    SetupResult finish();

    double elapsed() const;

private:
    stdfs::path staging_;
    bool staged_ = false;
    std::chrono::steady_clock::time_point start_;
};

// Stopwatch for one step.
class StepTimer {
public:
    StepTimer() : start_(std::chrono::steady_clock::now()) {}
    double seconds() const { return std::chrono::duration<double>(std::chrono::steady_clock::now() - start_).count(); }

private:
    std::chrono::steady_clock::time_point start_;
};

// ---- network ---------------------------------------------------------------------------------------------------------

// Downloads `url` to `destination` through ctx.fetch with progress lines ("Downloading <what> (190 MB): 40%"). `bytes`
// receives the size of the file when it is not null.
std::optional<Fail> download_file(const SetupContext& ctx, const std::string& url, const stdfs::path& destination,
                                  const std::string& what, std::uint64_t expectedBytes, std::uint64_t* bytes = nullptr,
                                  const std::vector<std::string>& headers = {});

// Downloads a small text (a JSON or XML listing) into memory. `httpStatus` receives the server's status on an HTTP
// error (404...). The temporary file lives in the staging folder `scratch`.
std::optional<Fail> fetch_text(const SetupContext& ctx, const std::string& url, const std::string& what,
                               const stdfs::path& scratch, std::string& out, int* httpStatus = nullptr,
                               const std::vector<std::string>& headers = {});

// "sha1" or "sha256" of `file` against `expected` (hex, case-insensitive). The Error names the file and both values.
std::optional<Fail> verify_checksum(const stdfs::path& file, const std::string& type, const std::string& expected,
                                    const std::string& what);

// ---- files ----------------------------------------------------------------------------------------------------------

// Unpacks a .zip, .tar.gz or .tgz into `destination` (created). macOS and Windows use the system bsdtar
// (/usr/bin/tar, %SystemRoot%\System32\tar.exe), Linux `tar` and `unzip`.
std::optional<Fail> extract_archive(const SetupContext& ctx, const stdfs::path& archive, const stdfs::path& destination);

// Moves `from` to `to`, replacing what is there: the old folder is renamed aside first and removed once the new one is in
// place; when the move fails the old one is put back.
std::optional<Fail> replace_dir(const stdfs::path& from, const stdfs::path& to);

// The folder that holds the one top-level folder of an unpacked archive (cmake-3.31.6-.../, FactorIA/...): `root` itself
// when it holds several entries or none.
stdfs::path single_child_dir(const stdfs::path& root);

// Adds the execute bits to `file` (POSIX).
void make_executable(const stdfs::path& file);
void make_tree_executable(const stdfs::path& dir);  // every regular file of <dir> (cmdline-tools/bin)

// ---- components -----------------------------------------------------------------------------------------------------

SetupComponent android_status(const SetupContext& ctx, bool fetchLicenses);
SetupResult android_install(const SetupContext& ctx, const SetupInstallOptions& options);

SetupComponent players_status(const SetupContext& ctx);
std::string installed_player_path(const SetupContext& ctx, const std::string& platform);  // "" when not installed
std::string installed_mobile_path(const SetupContext& ctx);                              // "" when not installed
SetupResult players_install(const SetupContext& ctx, const SetupInstallOptions& options);

SetupComponent cmake_status(const SetupContext& ctx);
std::string find_cmake_path(const SetupContext& ctx);  // the first CMake 3.24+ found, "" when none
SetupResult cmake_install(const SetupContext& ctx, const SetupInstallOptions& options);

SetupComponent xcode_status(const SetupContext& ctx);
SetupResult xcode_install(const SetupContext& ctx, const SetupInstallOptions& options);

SetupComponent appimage_status(const SetupContext& ctx);
AppImageTools installed_appimage_path(const SetupContext& ctx);  // both empty when not installed
SetupResult appimage_install(const SetupContext& ctx, const SetupInstallOptions& options);

// What the three installers and the status share about Java and the SDK folders.
bool jdk_usable(const std::string& dir);        // bin/java + bin/javac + Java 17 or newer
bool sdk_looks_ok(const std::string& dir);      // platform-tools/, platforms/ or licenses/
stdfs::path find_sdkmanager(const stdfs::path& sdk);  // cmdline-tools/<latest|version>/bin/sdkmanager[.bat], or empty
bool sdk_license_accepted(const stdfs::path& sdk);    // licenses/android-sdk-license exists and is not empty

// The repository listing of the Android SDK (cached in ctx.cache for a few minutes when there is one).
std::optional<Fail> fetch_sdk_repository(const SetupContext& ctx, const stdfs::path& scratch, SdkRepositoryInfo& out);

}  // namespace fa::setup_detail
