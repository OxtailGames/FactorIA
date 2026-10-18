// One-click setup of everything an export needs: `factoria setup`, commands "setup.status" and "setup.install".
//
// FactorIA never only tells the user what to install when it can install it. Five components:
//   android   JDK 21 (Eclipse Temurin) + the Android SDK (the command-line tools revision pinned below, platform-tools,
//             platform 36, build-tools 35.0.0) with its license accepted: what `factoria export --platform android` builds an
//             APK/AAB with.
//   players   the factoria_player of the other desktop OSes and the prebuilt mobile libraries, from the GitHub release of
//             this factoria's version: what `factoria export --platform windows|linux|macos` (for another OS) and the
//             prebuilt Android/iOS exports copy into the game.
//   cmake     CMake 3.24+ for the iOS export's build_ios.sh (macOS).
//   xcode     status and guidance only (macOS): a program cannot install Xcode; install opens its App Store page.
//   appimage  appimagetool and the AppImage runtime (Linux x86_64 only): what `factoria export --platform linux --format
//             appimage` builds an AppImage with. Pinned releases, checked against SHA-256 values kept in this file.
// Everything lands under factoria_home() (`$FACTORIA_HOME`, else ~/.factoria) and nothing outside it except the
// machine config (~/.factoria/export.json, fa/tooling/export_settings.h) that learns where the JDK and SDK are. Every
// download is verified against the checksum its publisher lists; an archive is unpacked next to its destination and
// moved into place, so a half-finished install never looks installed. docs/EXPORTING.md ("Setting up this computer").
//
// The Android SDK license must be accepted by a human: the install refuses (code "license_required") until
// `acceptLicenses` is set, and the text to show is in the status of the component. Once it is set, the install records
// exactly that one license (the line `sdkmanager --licenses` would write for it, see sdk_license_hash), nothing more.
//
// Downloads and child processes go through SetupContext::download and ::run, so tests (and embedders) replace them;
// the defaults are the `curl` executable and fa::run_process.
#pragma once

#include <atomic>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/process.h"
#include "fa/core/types.h"
#include "fa/tooling/export_settings.h"

namespace fa {

// What `setup` installs (changing one needs the matching docs/EXPORTING.md text updated).
inline constexpr int kSetupJdkMajor = 21;                                  // the JDK that is downloaded
inline constexpr const char* kSetupAndroidPlatformTools = "platform-tools";
inline constexpr const char* kSetupAndroidPlatform = "platforms;android-36";    // = the default targetSdk
inline constexpr const char* kSetupAndroidBuildTools = "build-tools;35.0.0";    // the Android Gradle plugin's default
inline constexpr const char* kSetupAndroidLicenseId = "android-sdk-license";
// The Android command-line tools: a PINNED revision of the classic, Java-based sdkmanager, not `cmdline-tools;latest`. Revision 23
// (2026) turned sdkmanager into a shell script in front of Google's "Android CLI": it unpacks a ~250 MB copy of itself into
// $ANDROID_USER_HOME on first use, shows Google's terms and sends Google usage statistics, and has no switch to turn that off.
// 22.0 is the newest revision whose bin/sdkmanager still launches com.android.sdklib.tool.sdkmanager.SdkManagerCli from lib/*.jar
// (its bin/android is never called by it). Raising this means checking that again, and the text of docs/EXPORTING.md.
inline constexpr const char* kSetupAndroidCmdlineTools = "cmdline-tools;22.0";
// What is installed instead when Google's listing no longer offers the pinned package (missing or obsolete): the Android CLI front.
inline constexpr const char* kSetupAndroidCmdlineToolsFallback = "cmdline-tools;latest";
inline constexpr const char* kSetupCmakeVersion = "3.31.6";
inline constexpr const char* kSetupCmakeMinimum = "3.24";                  // what the engine and build_ios.sh need
// The AppImage tools: the same releases and hashes as scripts/package-appimage.sh (a test keeps the two equal). To upgrade,
// change the script and these four together.
inline constexpr const char* kSetupAppimagetoolVersion = "1.9.1";
inline constexpr const char* kSetupAppimagetoolSha256 = "ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0";
inline constexpr const char* kSetupAppImageRuntimeVersion = "20251108";  // github.com/AppImage/type2-runtime release tag
inline constexpr const char* kSetupAppImageRuntimeSha256 = "2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d";

// The folder everything is installed into: $FACTORIA_HOME when set, else <HOME>/.factoria
// (%USERPROFILE%\.factoria on Windows). It is also where ai.json lives (export.json follows FACTORIA_HOME unless
// FACTORIA_EXPORT_CONFIG names it).
std::string factoria_home(const ExportEnvLookup& env = system_export_env());

// ---------------------------------------------------------------------------------------------------------------
// Doing things in the world (replaceable)
// ---------------------------------------------------------------------------------------------------------------

using ProcessRunner = std::function<Result<ProcessResult>(const ProcessOptions&)>;

struct DownloadRequest {
    std::string url;                          // https:// (file:// works too: tests)
    std::string destination;                  // the file to write; it is written as <destination>.part and renamed
    std::vector<std::string> headers;         // "Accept: application/vnd.github+json"
    std::uint64_t expectedBytes = 0;          // for progress only; 0 = unknown
    std::string what;                         // "JDK 21 (Eclipse Temurin)": names the download in errors
    std::function<void(std::uint64_t bytesSoFar)> onBytes;  // about twice a second while it runs; may be empty
    const CancelFlag* cancel = nullptr;
};

struct DownloadResult {
    bool ok = true;
    bool cancelled = false;
    int httpStatus = 0;  // the server's status when it answered with an error (404, 403...); 0 = none or unknown
    Error error;         // when !ok: what failed and how to fix it
};
using Downloader = std::function<DownloadResult(const DownloadRequest&)>;

// The default: the `curl` executable (macOS, Windows 10+ and most Linux have it) run through `run` (default
// fa::run_process): `curl -fL --retry 3 --connect-timeout 30 -o <file>.part <url>`, redirects only to https, proxies from
// the standard environment variables. While it runs, the size of the .part file is polled for `onBytes`; cancelling
// kills curl.
Downloader curl_downloader(ProcessRunner run = {});

struct SetupCache;  // optional per-process cache of the Android repository listing (below)

struct SetupContext {
    ExportEnvLookup env = system_export_env();
    std::string home;               // "" = factoria_home(env)
    std::string machineConfigPath;  // "" = machine_export_config_path(env)
    std::string host;               // "macos" | "windows" | "linux"; "" = this machine (tests change it)
    std::string hostArch;           // "aarch64" | "x64"; "" = this machine's
    std::string engineVersion;      // "" = FA_ENGINE_VERSION: the release the players come from
    std::string executableDir;      // "" = the folder of the running factoria (where mobile/ is looked for)
    std::string applicationsDir;    // macOS: where Xcode*.app is looked for; "" = /Applications
    Downloader download;            // empty = curl_downloader()
    ProcessRunner run;              // empty = fa::run_process
    std::function<void(const std::string& line)> progress;  // "Downloading JDK 21 (190 MB): 40%": may be empty
    const CancelFlag* cancel = nullptr;
    std::optional<AndroidToolchainSearch> toolchainSearch;  // nullopt = default_android_toolchain_search(env)
    std::shared_ptr<SetupCache> cache;                       // null = every call fetches what it needs again

    // The effective values (the defaults above filled in).
    std::string home_dir() const;
    std::string host_os() const;
    std::string host_architecture() const;
    std::string version() const;
    std::string config_path() const;
    AndroidToolchainSearch search() const;
    DownloadResult fetch(const DownloadRequest& request) const;       // download, or the injected downloader
    Result<ProcessResult> run_process_with(const ProcessOptions& options) const;
    void say(const std::string& line) const { if (progress) progress(line); }
};

struct SetupCache {
    std::mutex mutex;
    std::string repositoryXml;  // repository2-3.xml of the Android SDK, kept for a few minutes
    std::int64_t fetchedAtSeconds = 0;
};

// ---------------------------------------------------------------------------------------------------------------
// Status
// ---------------------------------------------------------------------------------------------------------------

struct SetupLicense {
    std::string id;     // "android-sdk-license"
    std::string title;  // "Android Software Development Kit License Agreement"
    std::string text;   // the full text to show to the user before they agree
};

struct SetupComponent {
    std::string id;       // "android" | "players" | "cmake" | "xcode" | "appimage"
    std::string title;
    std::string state;    // "installed" | "missing" | "partial" | "unsupported" (nothing to do on this machine)
    std::string details;  // one or two sentences: what was found, what an install does
    std::vector<std::pair<std::string, std::string>> paths;  // "jdk" -> folder, "sdk" -> folder, "cmake" -> file...
    std::vector<std::string> problems;   // what is missing or wrong, each with the way to fix it
    int installSizeMb = 0;               // download size of an install, approximately (0 = nothing to download)
    std::vector<SetupLicense> licenses;  // licenses to show before `acceptLicenses`; only while not yet accepted
    bool canInstall = false;             // `setup.install` can do something here
    Json to_json() const;
};

struct SetupStatus {
    std::string home;  // factoria_home()
    std::string host;  // "macos-aarch64"
    std::vector<SetupComponent> components;
    const SetupComponent* find(const std::string& id) const;
    Json to_json() const;
};

// Every component of this machine, or only `component` ("" = all). Looks at folders and runs version probes
// (`cmake --version`, `xcodebuild -version`); the only network request is the license text of the Android SDK,
// fetched when the licenses are not accepted yet and `fetchLicenses` is set.
SetupStatus setup_status(const SetupContext& context = {}, const std::string& component = {}, bool fetchLicenses = true);

// ---------------------------------------------------------------------------------------------------------------
// Install
// ---------------------------------------------------------------------------------------------------------------

struct SetupInstallOptions {
    std::string component;                 // "android" | "players" | "cmake" | "xcode" | "appimage"
    bool acceptLicenses = false;           // android: the user agreed to the Android SDK license
    std::vector<std::string> platforms;    // players: "windows" | "linux" | "macos" | "mobile" | "web"; empty = the default
    bool force = false;                    // reinstall even when it is found (android, cmake)
};

struct SetupStep {
    std::string id;       // "jdk", "cmdline-tools", "licenses", "packages", "player-windows"...
    std::string title;
    std::string outcome;  // "installed" | "skipped" (already there, or done by a later step) | "guidance"
    std::string detail;
    std::string path;     // where it is now
    std::uint64_t downloadedBytes = 0;
    double seconds = 0;
    Json to_json() const;
};

struct SetupReport {
    std::string component;
    bool changed = false;                  // something was downloaded or written
    std::vector<SetupStep> steps;
    std::vector<std::pair<std::string, std::string>> paths;
    std::vector<std::string> nextSteps;    // what the user does next (xcode: install it, open it once...)
    std::vector<std::string> warnings;
    double seconds = 0;
    Json to_json() const;
};

struct SetupResult {
    bool ok = false;
    SetupReport report;   // always filled as far as the install got (the steps done before a failure)
    std::string code;     // when !ok: "license_required" | "cancelled" | "network" | "checksum_mismatch" | "no_release" |
                          // "unsupported" | "invalid_argument" | "failed"
    Error error;          // when !ok
};

SetupResult setup_install(const SetupInstallOptions& options, const SetupContext& context = {});

// ---------------------------------------------------------------------------------------------------------------
// What the export asks for
// ---------------------------------------------------------------------------------------------------------------

// The factoria_player of `platform` ("windows" | "linux" | "macos") that `setup players` installed for this factoria's
// version: <home>/players/<version>/<platform>/factoria_player[.exe]; "" when it is not there. "web" gives the path of
// <home>/players/<version>/web/factoria_player.js (factoria_player.wasm is next to it).
std::string installed_player(const std::string& platform);
std::string installed_player(const SetupContext& context, const std::string& platform);

// <home>/players/<version>/mobile (the layout of the download's mobile/ folder) when it holds prebuilt Android or iOS
// libraries; "" otherwise.
std::string installed_mobile_dir();
std::string installed_mobile_dir(const SetupContext& context);

// A CMake 3.24 or newer, as an executable path: PATH, /opt/homebrew/bin, /usr/local/bin, /Applications/CMake.app,
// Program Files, then <home>/tools/cmake (what `setup cmake` installs); "" when none.
std::string find_cmake();
std::string find_cmake(const SetupContext& context);

// The files `setup appimage` installed: <home>/tools/appimage/appimagetool-<version>-x86_64.AppImage and runtime-<version>-x86_64.
// Both empty when either is missing.
struct AppImageTools {
    std::string tool, runtime;
};
AppImageTools installed_appimage_tools(const SetupContext& context);

// Registers "setup.status" (read-only) and "setup.install" (category "setup"). They need no project, so they are
// registered with the tooling commands and with the project-less command set; the editor calls the C++ API above.
void register_setup_commands(CommandRegistry& registry);

}  // namespace fa
