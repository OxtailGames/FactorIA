// Game export / packaging: `factoria export`, command "project.export".
//
// export_project() validates a game project and writes a shippable folder:
//   linux / windows : <out>/<slug>-<platform>/{<slug>[.exe], game/...}
//   macos           : <out>/<slug>-macos/<Name>.app/Contents/{Info.plist, MacOS/<slug>, Resources/game/...}
//   android         : <out>/<slug>-android/  a complete Gradle project with the game in app/src/main/assets/ plus
//                     assets_index.txt (the file list the engine VFS needs to enumerate files inside an APK: one
//                     project-relative path per line)
//   ios             : <out>/<slug>-ios/{game/..., build_ios.sh, ...}  the script configures the Xcode project with
//                     CMake (-DFA_GAME_PROJECT_DIR=game ...) using the same settings as the `ios` preset
// Android and iOS have two modes (ExportReport::mode); docs/EXPORTING.md has the rule that picks one:
//   prebuilt : the engine runtime is the ready-made player of the FactorIA download (<factoria dir>/mobile/): Android
//              packages android/jniLibs/<abi>/libfactoria_player.so, iOS links ios/<sdk>/*.a. No engine source (and,
//              on Android, no NDK or CMake) is needed; the project templates come from the factoria binary (platforms/).
//   source   : the engine is compiled from a source checkout (--engine-root, $FACTORIA_ENGINE_DIR, or the build-time
//              source root of a development build), with that checkout's platforms/ templates.
// Every export also writes FACTORIA_NOTICES.txt (the licenses of the runtime inside the game, fa/tooling/notices.h):
// next to the executable (linux, windows), in Contents/Resources (macos), in the APK assets (android), in game/ (ios).
// It also writes kExportMarkerFile at the top of <out>/<slug>-<platform>/: an export replaces an existing folder of that
// name only when it is empty or an export wrote it (the marker, or FACTORIA_NOTICES.txt where that platform's export
// puts it, for exports older than the marker). Any other folder is an error, so an unrelated one is never deleted.
// Never shipped: .factoria/, build/ (earlier exports), tests/, tools/, types/, ENGINE_FEEDBACK.json, AGENTS.md, CLAUDE.md,
// jsconfig.json, every dot-file/dot-folder, and the output folder itself.
#pragma once

#include <filesystem>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

// File every export writes at the top of its <out>/<slug>-<platform>/ folder: the mark that the next export may replace it.
inline constexpr const char* kExportMarkerFile = ".factoria-export";

struct ExportOptions {
    std::string projectDir;     // folder containing factoria.json
    std::string platform;       // linux | windows | macos | android | ios ("" = the platform running factoria)
    std::string outDir;         // parent folder of the export ("" = <projectDir>/build/export)
    bool release = false;       // only changes the build commands in nextSteps / the iOS script
    std::string playerBinary;   // desktop: path of factoria_player for the target platform
                                // ("" = next to the running factoria binary, or the build tree layout)
    std::string engineRoot;     // android/ios: engine checkout; giving it selects "source" mode
    std::string mobileDir;      // android/ios: folder of the prebuilt players (android/jniLibs/<abi>/libfactoria_player.so,
                                // ios/{iphoneos,iphonesimulator}/*.a); giving it selects "prebuilt" mode.
                                // With neither: $FACTORIA_ENGINE_DIR set = source; else <factoria dir>/mobile when it
                                // holds the players = prebuilt; else the build-time source root = source (docs/EXPORTING.md)
    std::string buildSourceRoot;  // the checkout factoria was built from ("" = FA_SOURCE_ROOT); only tests change it
};

struct ExportReport {
    std::string outputDir;                 // absolute folder that was written
    std::string mode;                      // android/ios: "prebuilt" or "source" (see above); empty for desktop exports
    std::string notices;                   // FACTORIA_NOTICES.txt, relative to outputDir (fa/tooling/notices.h)
    std::vector<std::string> files;        // paths relative to outputDir (forward slashes, sorted)
    std::vector<std::string> nextSteps;    // what the user does next, in order
    std::vector<std::string> warnings;     // non-fatal problems
    Json to_json() const;
};

Result<ExportReport> export_project(const ExportOptions& options);

// What export_project would do, checked without writing anything: the same validation (platform, factoria.json, name,
// mainScene, reverse-DNS id), the desktop player or the mobile mode, and the output folder (outside the project, and
// either absent, empty or written by an earlier export). An error is the one
// export_project would return. The editor's Export window shows it for each platform before an export.
struct ExportPlan {
    std::string platform;               // normalized: linux | windows | macos | android | ios
    std::string outputDir;              // absolute folder the export replaces: <out>/<game-slug>-<platform>
    std::string mode;                   // android/ios: "prebuilt" or "source"; empty for desktop exports
    std::string player;                 // desktop: the factoria_player that is copied into the export
    std::vector<std::string> warnings;  // non-fatal problems found so far (the export's report repeats them)
    Json to_json() const;
};

Result<ExportPlan> plan_export(const ExportOptions& options);

// Normalizes "win"/"mac"/"osx"/"Linux" -> "windows"/"macos"/"linux"; "" if unknown.
std::string normalize_export_platform(const std::string& name);

// Registers command "project.export" (-> MCP tool project_export, `factoria call`, editor console, fa.call) for the
// project at `projectDir`. It runs export_project() and returns ExportReport::to_json(); with dryRun it runs
// plan_export() and returns ExportPlan::to_json().
void register_export_commands(CommandRegistry& registry, const std::string& projectDir);

// Folder of the running executable (factoria finds factoria_player there; the editor updates its files).
std::filesystem::path executable_dir();

}  // namespace fa
