// Game export / packaging: `factoria export`, command "project.export".
//
// export_project() validates a game project and writes a shippable folder:
//   linux / windows : <out>/<slug>-<platform>/{<slug>[.exe], game/...}
//   macos           : <out>/<slug>-macos/<Name>.app/Contents/{Info.plist, MacOS/<slug>, Resources/game/...}
//   android         : <out>/<slug>-android/  a complete Gradle project (from platforms/android of the engine
//                     checkout) with the game in app/src/main/assets/ plus assets_index.txt (the file list
//                     the engine VFS needs to enumerate files inside an APK: one project-relative path per line)
//   ios             : <out>/<slug>-ios/{game/..., build_ios.sh}  the script configures the Xcode project with
//                     CMake (-DFA_GAME_PROJECT_DIR=game ...) using the same settings as the `ios` preset
// Never shipped: .factoria/, tests/, tools/, types/, ENGINE_FEEDBACK.json, AGENTS.md, CLAUDE.md,
// jsconfig.json, every dot-file/dot-folder, and the output folder itself.
#pragma once

#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

struct ExportOptions {
    std::string projectDir;     // folder containing factoria.json
    std::string platform;       // linux | windows | macos | android | ios ("" = the platform running factoria)
    std::string outDir;         // parent folder of the export ("" = <projectDir>/build/export)
    bool release = false;       // only changes the build commands in nextSteps / the iOS script
    std::string playerBinary;   // desktop: path of factoria_player for the target platform
                                // ("" = next to the running factoria binary, or the build tree layout)
    std::string engineRoot;     // android/ios: engine checkout ("" = $FACTORIA_ENGINE_DIR, else FA_SOURCE_ROOT)
};

struct ExportReport {
    std::string outputDir;                 // absolute folder that was written
    std::vector<std::string> files;        // paths relative to outputDir (forward slashes, sorted)
    std::vector<std::string> nextSteps;    // what the user does next, in order
    std::vector<std::string> warnings;     // non-fatal problems
    Json to_json() const;
};

Result<ExportReport> export_project(const ExportOptions& options);

// Normalizes "win"/"mac"/"osx"/"Linux" -> "windows"/"macos"/"linux"; "" if unknown.
std::string normalize_export_platform(const std::string& name);

}  // namespace fa
