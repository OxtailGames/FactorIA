// platform.add_backend: sets a store backend up in a game in one call (docs/PLATFORM.md, "Store backends"): the plugin
// from its template, its build for this computer, and what that store needs next to it. One file per backend
// (platform_setup_<backend>.cpp) says what "set up" means for it; this header is what they share.
#pragma once

#include <algorithm>
#include <functional>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/tooling/export_settings.h"

namespace fa::platform_setup {

// What one call of platform.add_backend works with, and what it reports.
struct Context {
    std::string projectDir;
    std::string backend;  // "steam", "apple", "googleplay": also the plugin's name and its template (platforms/plugins/<backend>)
    Json args;            // the command's arguments, defaults filled in
    CommandRegistry* registry = nullptr;
    std::string folder;   // the plugin's folder once ensure_plugin ran: the result's "folder"
    // googleplay: where to look for the Android SDK instead of the usual folders (tests); it must outlive the call.
    const AndroidToolchainSearch* androidSearch = nullptr;
    // run_cmake runs this CMake when set, else the one find_cmake() finds (googleplay: the Android SDK's own, which comes with Ninja).
    std::string cmakeExe;

    // Declares the plugin from its template (project.new_plugin) unless factoria.json already declares it, and returns its
    // folder (absolute, generic separators; also kept in `folder`). `platforms`: what the plugin is declared for.
    std::string ensure_plugin(const std::vector<std::string>& platforms);
    // Runs CMake with `arguments` (the CMake that `setup` installs when the computer has none). Throws a CommandError that
    // says what failed with the end of CMake's output. `what` names the step in that error ("configure the steam plugin").
    void run_cmake(const std::vector<std::string>& arguments, const std::string& what);
    // Builds the plugin's CMake project for this computer: <pluginDir>/build, Release (its CMakeLists.txt copies the
    // library into <pluginDir>/<platform>/). `configureArguments` are added to the configure step (-D...).
    void build_plugin(const std::string& pluginDir, const std::vector<std::string>& configureArguments = {});

    // dryRun: nothing is written, built or copied; each step records what it would do in `done` and the files and factoria.json
    // keys it would write in `files` and `keys` (the result's "wouldDo", "files" and "keys").
    bool dryRun = false;
    std::vector<std::string> files;      // files written (or, in a dry run, that would be)
    std::vector<std::string> keys;       // factoria.json keys written (or that would be): "factoria.json#/plugins/steam"
    // Records a file the command writes (generic separators).
    void wrote(const std::string& file) { if (std::find(files.begin(), files.end(), file) == files.end()) files.push_back(file); }

    std::vector<std::string> done;       // what was done, in order: the result's "done"
    std::vector<std::string> nextSteps;  // what the developer still does by hand: the result's "nextSteps"
    Json extra = Json::object();         // more fields for the result (backend-specific)
};

struct Backend {
    std::string name;         // "steam"
    std::string summary;      // one sentence for the command's description: what setting it up does
    Json properties;          // the JSON Schema "properties" this backend reads besides "backend" (may be an empty object)
    std::function<void(Context&)> run;  // does the work; throws CommandError (teaching) when something is missing
};

// `"a", "b"`: ids for a nextSteps sentence.
inline std::string quoted_list(const std::vector<std::string>& ids) {
    std::string out;
    for (const std::string& id : ids) out += (out.empty() ? "" : ", ") + std::string("\"") + id + "\"";
    return out;
}

// The Android SDK's NDK, CMake and Ninja (googleplay and admob build their C bridge with them): platform_setup_android.cpp.
struct NdkToolchain {
    std::string sdk, ndk, toolchainFile, cmake, ninja;
    std::vector<std::string> notes;  // "used NDK 28.0 because 27.2 is not installed"
};
// Finds them; throws a CommandError that says what to install. `backend` is the plugin ("admob"), `display` how a message names it
// ("the AdMob plugin").
NdkToolchain find_ndk_toolchain(const AndroidToolchainSearch& search, const std::string& backend, const std::string& display);
// Builds the plugin's C bridge in `folder` for arm64-v8a and x86_64 (a dry run only records the step) and fills ctx.done and
// ctx.extra["libraries"].
void build_android_abis(Context& ctx, const NdkToolchain& tc, const std::string& folder);

// One per backend file.
Backend steam_backend();  // platform_setup_steam.cpp
Backend apple_backend();  // platform_setup_apple.cpp
Backend googleplay_backend();  // platform_setup_googleplay.cpp
Backend admob_backend();  // platform_setup_admob.cpp

}  // namespace fa::platform_setup
