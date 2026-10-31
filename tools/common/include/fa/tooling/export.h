// Game export / packaging: `factoria export`, command "project.export".
//
// export_project() validates a game project and writes a shippable folder:
//   linux / windows : <out>/<slug>-<platform>/{<slug>[.exe], game/...}
//   macos           : <out>/<slug>-macos/<Name>.app/Contents/{Info.plist, MacOS/<slug>, Resources/game/...}
//   With `release` the game/ folder of these three is replaced by ONE archive, game.pak, in the same place (next to the
//   executable, in Contents/Resources of the .app): every file of the game packed as it is (fa/core/pack.h; the player reads it
//   through fa::fs), the .js scripts as QuickJS bytecode unless export.scriptBytecode is false in factoria.json
//   (fa/script/bytecode.h). No loose game files are left. ExportReport::pack / packed say what went in.
//   android         : <out>/<slug>-android/  a complete Gradle project (with its own Gradle wrapper) with the game in
//                     app/src/main/assets/ plus assets_index.txt (the file list the engine VFS needs to enumerate files
//                     inside an APK: one project-relative path per line). Unless the format is "gradle", the export then
//                     runs the project's Gradle wrapper and leaves the finished app next to the project:
//                     <out>/<slug>-android/<slug>[-debug].apk or .aab (ExportReport::artifact)
//   ios             : <out>/<slug>-ios/{game/..., build_ios.sh, ...}  the script configures the Xcode project with
//                     CMake (-DFA_GAME_PROJECT_DIR=game ...) using the same settings as the `ios` preset
//   web             : <out>/<slug>-web/{index.html, favicon.png (from the icon), factoria_player.js, factoria_player.wasm, game.pak, FACTORIA_NOTICES.txt} and,
//                     next to that folder, <out>/<slug>-web.zip with the same files and index.html at its root (what itch.io
//                     takes as an HTML5 game; ExportReport::artifact, format "zip"). The game is always ONE game.pak (like a
//                     desktop `release`), the page is platforms/web/shell.html (embedded in factoria) with {{title}},
//                     {{wasmBytes}}, {{pakBytes}} and {{favicon}} filled in. The player is two Emscripten files found by --player, then
//                     <factoria dir>/web, then `factoria setup players --platforms web`, then a web build of the source;
//                     ExportReport::mode says which ("explicit", "package", "installed" or "build").
// Android and iOS have two modes (ExportReport::mode); docs/EXPORTING.md has the rule that picks one:
//   prebuilt : the engine runtime is the ready-made player of the FactorIA download (<factoria dir>/mobile/): Android
//              packages android/jniLibs/<abi>/libfactoria_player.so, iOS links ios/<sdk>/*.a. No engine source (and,
//              on Android, no NDK or CMake) is needed; the project templates come from the factoria binary (platforms/).
//   source   : the engine is compiled from a source checkout (--engine-root, $FACTORIA_ENGINE_DIR, or the build-time
//              source root of a development build), with that checkout's platforms/ templates.
// Custom materials (*.material.json, fa/tooling/shaders.h) ship compiled: each gets <material>.json.<slang>.shader for the
// shader dialects of the platform (windows hlsl5, linux glsl430, macos metal_macos, ios metal_ios and metal_sim, android and
// web glsl300es) and the GLSL snippets they name are not shipped. A material that does not compile fails the export with the
// errors `factoria validate` lists. ExportReport::materials lists them.
// The built-in fonts that are files of factoria (builtin:serif, builtin:hand, builtin:blackletter, builtin:display) ship as
// builtin-fonts/<file> when a scene, prefab, script, data file or factoria.json of the project names them (the name written out
// in full); games that do not use them do not grow. ExportReport::builtinFonts lists them.
// Every export also writes FACTORIA_NOTICES.txt (the licenses of the runtime inside the game, fa/tooling/notices.h):
// next to the executable (linux, windows), in Contents/Resources (macos), in the APK assets (android), in game/ (ios).
// A project with assets recorded as made with AI (provenance in assets.json) also gets AI_CONTENT_DISCLOSURE.md at the top
// of <out>/<slug>-<platform>/ (fa/tooling/ai_disclosure.h), for the AI-generated content questions of store forms.
// It also writes kExportMarkerFile at the top of <out>/<slug>-<platform>/: an export replaces an existing folder of that
// name only when it is empty or an export wrote it (the marker, or FACTORIA_NOTICES.txt where that platform's export
// puts it, for exports older than the marker). Any other folder is an error, so an unrelated one is never deleted.
// Never shipped (every platform, release or not): files that are not game data, so no game reads them. Top level of the
// project: .factoria/ and every other dot-file/dot-folder (.git, .gitignore, .mcp.json), build/ (earlier exports), tests/,
// tools/, types/, node_modules/, ENGINE_FEEDBACK.json (the file named by feedbackFile), AGENTS.md, CLAUDE.md, jsconfig.json,
// README.md (any capitalization: the project's own documentation), steam_appid.txt, the folder of a native plugin that lives in
// the project (its build ships instead), and the output folder itself. A README.md or CREDITS.md deeper in the project, a
// LICENSE, a data file of any kind: shipped, because a game may load them. Everything else the project holds is shipped.
#pragma once

#include <cstdint>
#include <filesystem>
#include <functional>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/process.h"
#include "fa/core/types.h"
#include "fa/tooling/export_settings.h"

namespace fa {

struct SetupContext;  // fa/tooling/setup.h

// File every export writes at the top of its <out>/<slug>-<platform>/ folder: the mark that the next export may replace it.
inline constexpr const char* kExportMarkerFile = ".factoria-export";

struct ExportOptions {
    std::string projectDir;     // folder containing factoria.json
    std::string platform;       // linux | windows | macos | android | ios | web ("" = the platform running factoria)
    std::string outDir;         // parent folder of the export ("" = <projectDir>/build/export)
    bool release = false;       // android: builds the release APK/AAB (signed with export.android.signing; without a
                                // keystore it is an error unless allowDebugKey). linux/windows/macos: the game ships as
                                // ONE archive, game.pak, with the scripts as bytecode (export.scriptBytecode). ios: only
                                // changes the build commands of the script
    bool allowDebugKey = false; // android release without a keystore: sign with the debug key (fine to try on a device,
                                // Google Play rejects it) instead of failing
    std::string playerBinary;   // web: the folder with factoria_player.js and factoria_player.wasm (or factoria_player.js itself)
                                // desktop: path of factoria_player for the target platform
                                // ("" = next to the running factoria binary, or the build tree layout)
    bool allowPlayerMismatch = false;  // bundle a player (desktop, web, prebuilt Android/iOS) built from another commit than this factoria (its
                                // build fingerprint differs, or it has none) with a warning instead of stopping; the
                                // game may not run on that player
    bool allowMissingPlugins = false;  // a native plugin whose build for the target platform is missing (optional or not) is left
                                // out of the export, with a warning and an entry in ExportReport::pluginsLeftOut, instead
                                // of stopping it
    std::string engineRoot;     // android/ios: engine checkout; giving it selects "source" mode
    std::string mobileDir;      // android/ios: folder of the prebuilt players (android/jniLibs/<abi>/libfactoria_player.so,
                                // ios/{iphoneos,iphonesimulator}/*.a); giving it selects "prebuilt" mode.
                                // With neither: $FACTORIA_ENGINE_DIR set = source; else <factoria dir>/mobile when it
                                // holds the players = prebuilt; else the build-time source root = source (docs/EXPORTING.md)
    std::string buildSourceRoot;  // the checkout factoria was built from ("" = FA_SOURCE_ROOT); only tests change it
    std::string format;         // the kind of file a platform exports ("" = export.android.format of factoria.json, else the
                                // platform's default). android: "apk" (default: built with Gradle), "aab" (the Google
                                // Play bundle, built with Gradle) or "gradle" (only the Gradle project; nothing is built
                                // and no JDK or SDK is needed). linux: "appimage" also writes the game as one AppImage file
                                // (needs Linux x86_64 and `factoria setup appimage`); without it the folder is all there is.
                                // windows: "msix" also writes <out>/<slug>-windows.msix, the Microsoft Store package, next to
                                // the folder (any host; export.windows.format in factoria.json); "folder" is the default.
                                // The other platforms have one format and ignore it
    std::function<void(const std::string& line)> progress;  // optional: called from the exporting thread with each line
                                // the Gradle build of an Android export prints (the same lines go to <out>/build.log);
                                // may be empty
    const CancelFlag* cancel = nullptr;  // optional: set to true to stop the Gradle build (its process tree is killed);
                                // the export then fails with "cancelled" and the Gradle project stays on disk
    const AndroidToolchainSearch* androidSearch = nullptr;  // where to look for the JDK and SDK, the environment variables
                                // and ~/.factoria/export.json (nullptr = this machine); only tests change it
    const SetupContext* setup = nullptr;  // linux appimage: which computer this is, where the AppImage tools are installed and how
                                // programs are run (nullptr = this machine); only tests change it
};

// One row of the size report of an export (ExportReport::largestFolders, ExportReport::webFiles).
struct ExportSize {
    std::string name;                // a project folder ("assets/audio", "(top level)") or a file of the web export
    std::uint64_t files = 0;         // folders: how many files; web files: 1
    std::uint64_t bytes = 0;         // as shipped (after the asset steps)
    std::uint64_t gzipBytes = 0;     // web files: about what a host that gzips sends; folders: 0
};

struct ExportReport {
    std::string outputDir;                 // absolute folder that was written
    std::string mode;                      // android/ios: "prebuilt" or "source" (see above); web: where the player came from;
                                           // empty for desktop exports
    std::string format;                    // the format that was exported (see ExportOptions::format); empty when none
    std::string artifact;                  // absolute path of the file that was built: <outputDir>/<slug>[-debug].apk or
                                           // .aab of an Android export (release builds have no "-debug"), or the
                                           // <outputDir>/<slug>-x86_64.AppImage of a linux one, or the <out>/<slug>-windows.msix
                                           // of a windows one (next to outputDir); empty otherwise
    std::string notices;                   // FACTORIA_NOTICES.txt, relative to outputDir (fa/tooling/notices.h)
    std::vector<std::string> files;        // paths relative to outputDir (forward slashes, sorted): what is on disk, so a release
                                           // export of a desktop game lists game.pak, not the files in it
    std::string pack;                      // release desktop export: the game's pack, as a path relative to the folder it is in
                                           // (game.pak: next to the executable, in Contents/Resources of a macOS app); else empty
    std::vector<std::string> packed;       // release desktop export: the project-relative paths in the pack, sorted
    std::vector<std::string> materials;    // the *.material.json that ship (project-relative, sorted), each with its compiled
                                           // shaders <material>.json.<slang>.shader for the platform's dialects
    std::vector<std::string> builtinFonts;  // the built-in fonts that are files, not inside the player ("builtin:serif"), that the project
                                           // names: shipped as builtin-fonts/<file>, with their licenses in FACTORIA_NOTICES.txt
    std::vector<std::string> pluginsLeftOut;  // allowMissingPlugins: the native plugins whose build for this platform was missing, so the
                                           // export does not hold them (a warning names each); empty otherwise
    std::vector<ExportSize> largestFolders;  // the folders (at most two levels deep) that weigh most in what ships, biggest first (at most 5)
    std::vector<ExportSize> webFiles;      // web export: every file of the zip with its raw and about-gzip size, biggest first; else empty
    std::uint64_t webBytes = 0;            // web export: their total, raw
    std::uint64_t webGzipBytes = 0;        // web export: their total, about gzip (the deflate size of the zip plus the 18 bytes of a gzip frame)
    std::vector<std::string> nextSteps;    // what the user does next, in order
    std::vector<std::string> warnings;     // non-fatal problems
    // The size report as text lines (what `factoria export` prints): the largest folders and, for the web, the files and the download
    // time of the gzip total at 1, 5, 20 and 100 Mbit/s. Empty when there is nothing to say.
    std::vector<std::string> size_lines() const;
    Json to_json() const;
};

Result<ExportReport> export_project(const ExportOptions& options);

// What export_project would do, checked without writing anything: the same validation (platform, factoria.json, name,
// mainScene, reverse-DNS id), the desktop player or the mobile mode, and the output folder (outside the project, and
// either absent, empty or written by an earlier export). An error is the one
// export_project would return. The editor's Export window shows it for each platform before an export.
struct ExportPlan {
    std::string platform;               // normalized: linux | windows | macos | android | ios | web
    std::string outputDir;              // absolute folder the export replaces: <out>/<game-slug>-<platform>
    std::string mode;                   // android/ios: "prebuilt" or "source"; web: where the player comes from ("explicit",
                                        // "package", "installed" or "build"); empty for desktop exports
    std::string format;                 // the format the export would produce (see ExportOptions::format); empty when none
    std::string artifact;               // absolute path of the file the export would build (.apk / .aab / .AppImage / .msix / the web export's .zip); else empty
    AndroidToolchain toolchain;         // android apk/aab: the JDK and SDK the build would use, and where each was found
                                        // (problems stays empty: a missing one is the plan's error); else empty
    std::string player;                 // desktop: the factoria_player that is copied into the export; web: its factoria_player.js
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
