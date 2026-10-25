// Private declarations shared by export.cpp, export_desktop.cpp, export_android.cpp and export_ios.cpp.
//
//   export.cpp          planning, the report, project loading, the command, and the helpers below marked "(export.cpp)"
//   export_desktop.cpp  linux / windows / macos
//   export_android.cpp  the Android Gradle project
//   export_ios.cpp      the iOS project and build_ios.sh
//   export_assets.cpp   the asset steps every export runs before copying the game (assets.json import settings):
//   export_textures.cpp   texture compression and atlases
//   export_audio.cpp      audio conversion and loudness
//   export_shaders.cpp    the compiled shaders of custom materials
//
// Nothing here is part of the fa_tooling API (that is fa/tooling/export.h).
#pragma once

#include <filesystem>
#include <map>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/fs.h"  // os_path
#include "fa/core/image.h"
#include "fa/core/strings.h"  // replace_all
#include "fa/core/types.h"
#include "fa/runtime/plugins.h"
#include "fa/tooling/export.h"
#include "fa/tooling/export_settings.h"
#include "fa/tooling/icons.h"
#include "util.h"

namespace fa::export_detail {

namespace stdfs = std::filesystem;
// Every file system call on the output folder goes through fs::os_path: an export lands deep (a macOS .app nests four
// folders), and Windows refuses paths over MAX_PATH without its \\?\ prefix (docs/EXPORTING.md, "Long paths on Windows").
using fs::os_path;
using tooling_detail::read_file;
using tooling_detail::slugify;
using tooling_detail::write_file;

inline Error err(std::string message, std::string hint = {}) { return Error{std::move(message), std::move(hint)}; }

inline std::string generic(const stdfs::path& p) { return p.generic_string(); }

// ---- project -----------------------------------------------------------------------------------------

struct Project {
    stdfs::path dir;
    std::string name, id, version = "0.1.0", orientation = "landscape", feedbackFile = "ENGINE_FEEDBACK.json";
    std::string mainScene = "scenes/main.scene.json";
    std::vector<std::string> platforms;
    bool hasPlatformsField = false;
    ProjectExportSettings settings;  // `icon` and `export` of factoria.json (load_export_settings), defaults filled in
    struct Plugin {
        std::string name;
        stdfs::path build;  // <plugin folder>/<platform> (plugin_build): what the export copies or links
    };
    std::vector<std::string> pluginsLeftOut;  // allowMissingPlugins: the plugins whose build for this platform is missing
    std::vector<Plugin> plugins;             // the native plugins of the platform being exported
    std::vector<stdfs::path> pluginFolders;  // every plugin's folder: the ones inside the project stay out of game/
    // Shipped path -> the file copy_game copies instead of <dir>/<path>: what the asset steps converted (export_assets.cpp).
    std::map<std::string, stdfs::path> staged;
};

// ---- helpers (export.cpp) -----------------------------------------------------------------------------

// The values of ExportOptions::format / export.android.format: "apk", "aab", "gradle" (lower case).
const std::vector<std::string>& export_formats();
bool is_export_format(const std::string& format);
// Every value `format` of project.export accepts: the Android ones, "appimage" (linux), "msix" (windows) and "folder" (the
// default of linux and windows).
const std::vector<std::string>& all_export_formats();

std::string host_platform();  // linux | windows | macos: the machine running factoria
std::string xml_escape(const std::string& s, bool androidString = false);
std::string sh_quote(const std::string& s);

// (export.cpp) The project-relative files (forward slashes, sorted) an export ships from the project at `dir`: everything but
// the hidden files and folders, build/, tests/, tools/, types/... project.validate weighs them.
std::vector<std::string> list_game_files(const stdfs::path& dir, const std::string& feedbackFile);

// (export_textures.cpp) The warning for textures that cannot be GPU-compressed (sides not multiples of 4), shared by the
// export and `factoria validate`. texture_block_compressed: false when a texture of this size, with the import settings of
// `manifest` (assets.json), would ship uncompressed for that reason (not in an atlas, compression not "none").
std::string not_block_sized_message(const std::vector<std::string>& paths);
bool texture_block_compressed(const Json& manifest, const std::string& path, int width, int height);

// Copies the project files `files` (project-relative) into `dest`, keeping their paths. A file in p.staged is copied from
// there instead.
Result<void> copy_game(const Project& p, const std::vector<std::string>& files, const stdfs::path& dest);
// Writes a text file (creating its folders); `executable` also sets the exec bits.
Result<void> write_text(const stdfs::path& path, const std::string& text, bool executable = false);
// A version name that is safe in a Gradle / Xcode setting.
std::string safe_version_name(const std::string& v);

// (export.cpp) The icon of `platform` (settings.icon_for) decoded as a square image; an empty Image when no icon is set.
// A missing or undecodable file is an Error (it names factoria.json and the JSON pointer); what load_icon_image warns
// about (not square, smaller than 512 px) is appended to `warnings`.
Result<Image> load_platform_icon(const Project& p, const std::string& platform, std::vector<std::string>& warnings);

// ---- mobile: prebuilt players or the engine source ------------------------------------------------
//
// Android and iOS exports run in one of two modes (ExportReport::mode, docs/EXPORTING.md has the rule):
//   prebuilt : the engine runtime is the ready-made player the FactorIA download carries in <factoria dir>/mobile/
//              (android/jniLibs/<abi>/libfactoria_player.so, ios/{iphoneos,iphonesimulator}/*.a); the project
//              templates come from this binary (platforms/ is embedded like docs/ and templates/).
//   source   : the engine is compiled from a source checkout, with that checkout's templates (engine developers).

inline constexpr const char* kAndroidAbis[] = {"arm64-v8a", "x86_64"};  // what the release workflow builds (= abiFilters in the template)
inline constexpr const char* kIosSlices[] = {"iphoneos", "iphonesimulator"};
inline constexpr const char* kIosMarkerLib = "libfactoria_player_main.a";  // the player's own archive, next to the engine ones

struct MobileSetup {
    bool prebuilt = false;
    stdfs::path engine;  // source: the engine checkout
    stdfs::path libs;    // prebuilt: <mobile dir>/<android|ios>
};

struct TemplateFile {
    std::string rel;  // path inside the template folder, forward slashes
    std::string data;
};

// (export.cpp) The files of the project template platforms/<dir>: from the engine checkout in source mode, from this
// binary otherwise.
Result<std::vector<TemplateFile>> load_templates(const MobileSetup& m, const std::string& dir);
// (export.cpp) Keeps or drops the {{#source}} ... {{/source}} sections of a template for the mode.
Result<std::string> select_sections(const std::string& text, bool source, const std::string& where);

// ---- desktop (export_desktop.cpp) ------------------------------------------------------------------

Result<stdfs::path> find_player(const ExportOptions& o, const std::string& platform);
// The player must come from the same build as this factoria (fa/core/build_info.h): its fingerprint is read from the file's
// bytes. A different one stops the export unless ExportOptions::allowPlayerMismatch (then `warnings` says so). Files that
// are no executable (a test's stand-in) and a factoria or player built outside git ("unknown") are not compared; the same
// commit with "-dirty" on one side only is a warning.
Result<void> check_player_build(const ExportOptions& o, const stdfs::path& player, const std::string& platform,
                                std::vector<std::string>& warnings);
// The game name with the characters a file name cannot hold replaced (the .app folder of macOS).
std::string fs_safe_name(const std::string& s);
// The game's executable in a desktop export: <slug>.exe on Windows, else <slug>. On Linux the slug `game` gives game-bin:
// the data folder is game/ next to the executable, and a slug (no dots) can meet nothing else there.
// The export, the AppImage and publish all use it.
std::string desktop_exe_name(const std::string& slug, const std::string& platform);
// Seals an exported .app with an ad hoc signature; returns "" or what went wrong.
std::string sign_app_ad_hoc(const stdfs::path& app);
// `icon` is the platform's icon (load_platform_icon), empty when none is set: the .icns of a macOS app, the icon of the
// Windows exe, the PNG and .desktop file of a Linux build. With options.release the game goes into one pack
// (game.pak, fa/core/pack.h) instead of the game/ folder; scripts become bytecode unless export.scriptBytecode is false.
Result<void> export_desktop(const ExportOptions& options, const Project& p, const std::string& platform, const stdfs::path& player,
                            const stdfs::path& outRoot, const std::vector<std::string>& files, const Image& icon,
                            ExportReport& report);

// Packs `files` (project-relative; p.staged applies) into the pack `packFile`, scripts as bytecode unless
// export.scriptBytecode is false (the release build of a desktop export, and every web export).
Result<void> pack_project(const Project& p, const std::vector<std::string>& files, const stdfs::path& packFile, ExportReport& report);

// ---- web (export_web.cpp) ---------------------------------------------------------------------------

// The web player: factoria_player.js and the factoria_player.wasm next to it (Emscripten output).
struct WebPlayer {
    stdfs::path js, wasm;
    std::string from;  // "explicit" (--player), "package" (web/ next to factoria), "installed" (factoria setup players) or
                       // "build" (a web build of the engine source)
};

// --player (a folder or factoria_player.js), else <factoria dir>/web, else `factoria setup players --platforms web`, else a
// web build next to the factoria binary or in the checkout `sourceRoot`; an error that says how to get one.
Result<WebPlayer> find_web_player(const ExportOptions& o, const std::string& sourceRoot);

// <outRoot>/{index.html, factoria_player.js, factoria_player.wasm, game.pak}. The page is platforms/web/shell.html with its
// placeholders filled in (docs/EXPORTING.md, "Web").
Result<void> export_web(const Project& p, const WebPlayer& player, const stdfs::path& outRoot, const std::vector<std::string>& files,
                        ExportReport& report);

// After the notices are in outRoot: <zipFile> holds the export folder (index.html at its root) for itch.io and other hosts. Sets
// report.format and report.artifact; limits of itch.io are warnings.
Result<void> zip_web(const stdfs::path& outRoot, const stdfs::path& zipFile, ExportReport& report);

// (export_appimage.cpp) The plain icon of a game that set none: a dark 256x256 square with a light "play" triangle, as a PNG.
Image placeholder_icon_image();
std::vector<std::uint8_t> placeholder_icon_png();

// ---- windows MSIX (export_msix.cpp) ------------------------------------------------------------------

// What the plan decides for `format: "msix"` on a Windows export. enabled is false for every other export.
struct MsixPlan {
    bool enabled = false;
    stdfs::path artifact;  // <out>/<slug>-windows.msix, next to the export folder
};

// Checks the msix settings and names the file the package will be. Missing identity fields are warnings (the package gets a
// placeholder identity that only installs on your own PC).
Result<MsixPlan> plan_msix(const ExportOptions& o, const Project& p, const stdfs::path& outParent, std::vector<std::string>& warnings);

// The AppxManifest.xml of the package (UTF-8, LF) for the game: identity, logos, the executable and the capabilities.
// Placeholders are used where the settings have no identity; `placeholderIdentity` says so.
std::string msix_manifest(const Project& p, bool& placeholderIdentity);

// After the export folder is complete (notices included): writes the package from the folder's files and the logos made from
// `icon` (an empty Image: the placeholder icon). Sets report.format / report.artifact / the first next steps.
Result<void> build_msix(const ExportOptions& o, const Project& p, const MsixPlan& plan, const stdfs::path& outRoot, const Image& icon,
                        ExportReport& report);

// ---- linux AppImage (export_appimage.cpp) -----------------------------------------------------------

// What the plan decides for `format: "appimage"` on a Linux export: the tools `factoria setup appimage` installed and the file the
// AppImage will be. enabled is false for every other export.
struct AppImagePlan {
    bool enabled = false;
    stdfs::path tool, runtime;
    stdfs::path artifact;  // <outRoot>/<slug>-x86_64.AppImage
};

// Checks that this computer can build an AppImage (Linux x86_64 with the tools installed) and names the file it will write.
Result<AppImagePlan> plan_appimage(const ExportOptions& o, const Project& p, const stdfs::path& outRoot);

// Writes the AppDir of an exported game: AppRun, <slug>.desktop (the export's, fixed for AppImage), the icon and usr/bin holding
// the export folder `exportRoot` as it is. `artifactName` (the AppImage that is going to be written) and the export's own marker
// files are left out. A missing icon is replaced by a plain one, with a warning.
Result<void> write_appdir(const Project& p, const stdfs::path& exportRoot, const stdfs::path& appDir, const std::string& artifactName,
                          std::vector<std::string>& warnings);

// After the export folder is complete (notices included): builds the AppDir beside it, runs appimagetool, removes the AppDir and
// sets report.format / report.artifact / the first next steps.
Result<void> build_appimage(const ExportOptions& o, const Project& p, const AppImagePlan& a, const stdfs::path& outRoot, ExportReport& report);

// ---- android (export_android.cpp) -------------------------------------------------------------------

// Everything the Android export decides before it writes anything (so plan_export can report it and fail early).
struct AndroidPlan {
    std::string format;                  // "apk" | "aab" | "gradle"
    bool release = false;
    AndroidToolchain toolchain;          // JDK + SDK (found for every format: the SDK also goes to local.properties)
    // The CMake of a source-mode build: the SDK's pinned version when it is installed, else the newest CMake 3.24+ of the SDK,
    // else a CMake of this computer (cmakeDir -> cmake.dir in local.properties). cmakeVersion goes to factoria.cmakeVersion.
    std::string cmakeVersion;
    std::string cmakeDir;                // "" = the one in the SDK
    std::string cmakeNote;               // "the SDK has no CMake 3.31.6; ..." when it is not the pinned one
    stdfs::path artifact;                // <outRoot>/<slug>[-debug].apk|aab; empty for "gradle"
    // Release signing (apk/aab only): the keystore of export.android.signing resolved against the project folder, its
    // alias, and the passwords (environment variables win over ~/.factoria/export.json). Empty keystore = signed with
    // the debug key (only when ExportOptions::allowDebugKey, with a warning).
    std::string keystore, alias;
    AndroidSigningSecrets secrets;
    // The icons, decoded once by the plan (empty/none = no icon set).
    bool hasIcon = false;
    Image icon;
    AdaptiveIcon adaptive;
};

// Resolves and checks everything an Android export needs: the format, the icons, the toolchain (apk/aab), the release
// signing. Appends non-fatal findings to `warnings`.
// `decodeIcons` false (a dry run) only checks that the icon files exist; the export decodes them.
Result<AndroidPlan> plan_android(const ExportOptions& o, const Project& p, const stdfs::path& outRoot,
                                 std::vector<std::string>& warnings, bool decodeIcons);

// Writes the Gradle project into outRoot (templates, icons, game, prebuilt players). Sets report.format.
Result<void> export_android(const Project& p, const MobileSetup& setup, const AndroidPlan& a, const stdfs::path& outRoot,
                            const std::vector<std::string>& files, ExportReport& report);

// After FACTORIA_NOTICES.txt is in the project: runs Gradle unless the format is "gradle", copies the APK/AAB next to the
// project and writes the next steps (before the ones already in the report). `keepOutput` is set when a failed export must
// leave outRoot in place (the Gradle project of a failed or cancelled build).
Result<void> build_android(const ExportOptions& o, const Project& p, const MobileSetup& setup, const AndroidPlan& a,
                           const stdfs::path& outRoot, ExportReport& report, bool& keepOutput);

// ---- ios (export_ios.cpp) ---------------------------------------------------------------------------

// `icon` is the iOS icon (load_platform_icon), empty when none is set: it becomes Assets.xcassets next to build_ios.sh.
Result<void> export_ios(const ExportOptions& o, const Project& p, const MobileSetup& setup, const stdfs::path& outRoot,
                        const std::vector<std::string>& files, const Image& icon, ExportReport& report);

// ---- assets (export_assets.cpp, export_textures.cpp, export_audio.cpp) -------------------------------

// What the asset steps work on. A step may replace a shipped file by a converted one (assets/hero.png ->
// assets/hero.png.ktx2: the engine loads such a twin in place of the original), add files or drop them.
struct ExportAssets {
    Project& project;
    const std::string& platform;       // linux | windows | macos | android | ios | web
    std::vector<std::string>& files;   // shipped project-relative paths (sorted again after the steps)
    stdfs::path cacheDir;              // <project>/.factoria/export-cache/<platform>: converted files, kept between exports
    Json manifest;                     // the assets.json that ships: import settings, no provenance; steps may add to it
    ExportReport& report;              // warnings
    const SetupContext& setup;         // how sokol-shdc is found and started (convert_shaders)
    bool mobile() const { return platform == "android" || platform == "ios"; }
    // Devices whose GPUs may sample only 2048 px on a side (GLES3 phones, and browsers, which run on them too): atlas pages stay
    // that small. The web otherwise ships PNGs like the desktop: WebGL2 guarantees no compressed texture format.
    bool small_textures() const { return mobile() || platform == "web"; }
    // Ships `source` (an absolute file, usually under cacheDir) as `shipped`, in place of `original` ("" = an added file).
    void replace(const std::string& original, const std::string& shipped, const stdfs::path& source);
};

// Runs the asset steps on `files` (what collect_game_files found) and records the converted files in p.staged.
Result<void> prepare_game_assets(Project& p, const std::string& platform, std::vector<std::string>& files, ExportReport& report,
                                 const SetupContext& setup);

// Custom materials (export_shaders.cpp): every shipped *.material.json gets <material>.json.<slang>.shader for each dialect
// of the platform, and the snippets they name are not shipped. A material that does not compile fails the export.
Result<void> convert_shaders(ExportAssets& ea);
// Texture compression (KTX2 / Basis Universal) and atlas packing by the import settings (export_textures.cpp).
Result<void> convert_textures(ExportAssets& ea);
// Audio conversion and loudness by the import settings (export_audio.cpp).
Result<void> convert_audio(ExportAssets& ea);

}  // namespace fa::export_detail
