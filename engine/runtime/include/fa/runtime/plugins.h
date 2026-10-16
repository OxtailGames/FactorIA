// Native plugins: per-game libraries that add commands and script functions through the C ABI of fa_plugin.h
// (docs/EXTENDING.md, "Native plugins"). factoria.json declares them:
//
//   "plugins": { "example": { "path": "plugins/example" },
//                "steam":   { "path": "${STEAMWORKS_PLUGIN}", "platforms": ["windows", "linux", "macos"] } }
//
// A plugin's folder holds one build per platform (plugin_library):
//   windows/example.dll   macos/libexample.dylib   linux/libexample.so      (each next to the libraries it needs)
//   android/              a Gradle library module (build.gradle) or .aar files; the APK carries libexample.so
//   ios/iphoneos/libexample.a, ios/iphonesimulator/libexample.a           (static: linked into the app)
//
// Engine::init loads the plugins of this platform (once per process: a library is never unloaded, so rebuilding a
// plugin needs a new process) and adds their commands to the engine's registry and their functions to scripts
// (plugins.<name>.<function>). A plugin that cannot load is a warning, not a failure: the game runs without it and
// scripts that use it get the reason, so a collaborator without a private SDK can still work on the game.
#pragma once

#include <functional>
#include <memory>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/types.h"
#include "fa/runtime/fa_plugin.h"
#include "fa/runtime/project.h"
#include "fa/script/script.h"
#include "fa/services/platform.h"

namespace fa {

// The plugin's folder: ${NAME} parts replaced by environment variables, then relative to `projectDir`. The error names
// the variable that is not set.
Result<std::string> plugin_folder(const std::string& projectDir, const PluginSettings& plugin);

// The file of the plugin's build for `platform`, relative to its folder: "windows/example.dll", "macos/libexample.dylib",
// "linux/libexample.so", "android" (the folder), "ios/iphoneos/libexample.a".
std::string plugin_library(const std::string& name, const std::string& platform);

// The folder of the plugin's build for `platform` (<folder>/<platform>), once it holds what that build needs: the library
// on desktop, both static libraries on iOS (iphoneos, iphonesimulator), a Gradle module (build.gradle or .kts) or .aar /
// .jar files on Android. The error says what is missing and how to make it. `factoria validate` and the export use it.
Result<std::string> plugin_build(const std::string& projectDir, const PluginSettings& plugin, const std::string& platform);

// A platform backend a plugin registered with api->add_backend (ABI version 2; docs/PLATFORM.md, "Writing a backend").
struct PluginBackend {
    std::string plugin;                 // the plugin's name in factoria.json
    std::string name;                   // the backend's name ("steam"): the keys of the catalog's "ids"
    std::vector<std::string> services;  // what it offers: a subset of platform_services_all()
    // A fresh adapter that forwards requests to the plugin: one per engine (the plugin outlives engines).
    std::function<std::unique_ptr<PlatformBackend>()> create;
};

struct PluginInstall {
    std::vector<std::string> problems;    // one teaching message per plugin that did not load; also logged as warnings
    std::vector<std::string> failed;      // the names of those plugins
    std::vector<PluginBackend> backends;  // of the plugins that loaded, in the order of factoria.json "plugins"
};

// What Engine::init does: loads (once per process) the plugins `project` declares for this platform and installs what
// they registered into `commands` and `scripts` (ScriptSystem::set_plugins, before its init); the platform backends
// they registered are returned for the engine to choose from (fa/runtime/platform_backend.h). `libraryDir` is where an
// exported game keeps the libraries (next to the executable; "" = each plugin's folder, for development runs).
PluginInstall install_plugins(const ProjectSettings& project, const std::string& projectDir, const std::string& libraryDir,
                              CommandRegistry& commands, ScriptSystem& scripts);

}  // namespace fa

// A plugin linked into the program (iOS, tests): install_plugins uses it instead of loading a library. The iOS app's
// generated code calls it before main for every plugin of the game.
extern "C" void fa_register_static_plugin(const char* name, FaPluginInitFn init);
