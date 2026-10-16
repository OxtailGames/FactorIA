// platform.add_backend: sets a store backend up in a game in one call (docs/PLATFORM.md, "Store backends"): the plugin
// from its template, its build for this computer, and what that store needs next to it. One file per backend
// (platform_setup_<backend>.cpp) says what "set up" means for it; this header is what they share.
#pragma once

#include <functional>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"

namespace fa::platform_setup {

// What one call of platform.add_backend works with, and what it reports.
struct Context {
    std::string projectDir;
    std::string backend;  // "steam", "apple": also the plugin's name and its template (platforms/plugins/<backend>)
    Json args;            // the command's arguments, defaults filled in
    CommandRegistry* registry = nullptr;
    std::string folder;   // the plugin's folder once ensure_plugin ran: the result's "folder"

    // Declares the plugin from its template (project.new_plugin) unless factoria.json already declares it, and returns its
    // folder (absolute, generic separators; also kept in `folder`). `platforms`: what the plugin is declared for.
    std::string ensure_plugin(const std::vector<std::string>& platforms);
    // Runs CMake with `arguments` (the CMake that `setup` installs when the computer has none). Throws a CommandError that
    // says what failed with the end of CMake's output. `what` names the step in that error ("configure the steam plugin").
    void run_cmake(const std::vector<std::string>& arguments, const std::string& what);
    // Builds the plugin's CMake project for this computer: <folder>/build, Release (its CMakeLists.txt copies the library
    // into <folder>/<platform>/). `configureArguments` are added to the configure step (-D...).
    void build_plugin(const std::string& folder, const std::vector<std::string>& configureArguments = {});

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

// One per backend file.
Backend steam_backend();  // platform_setup_steam.cpp
Backend apple_backend();  // platform_setup_apple.cpp

}  // namespace fa::platform_setup
