// Private declarations shared by export.cpp, export_desktop.cpp, export_android.cpp and export_ios.cpp.
//
//   export.cpp          planning, the report, project loading, the command, and the helpers below marked "(export.cpp)"
//   export_desktop.cpp  linux / windows / macos
//   export_android.cpp  the Android Gradle project
//   export_ios.cpp      the iOS project and build_ios.sh
//
// Nothing here is part of the fa_tooling API (that is fa/tooling/export.h).
#pragma once

#include <filesystem>
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
    std::vector<Plugin> plugins;             // the native plugins of the platform being exported
    std::vector<stdfs::path> pluginFolders;  // every plugin's folder: the ones inside the project stay out of game/
};

// ---- helpers (export.cpp) -----------------------------------------------------------------------------

// The values of ExportOptions::format / export.android.format: "apk", "aab", "gradle" (lower case).
const std::vector<std::string>& export_formats();
bool is_export_format(const std::string& format);

std::string host_platform();  // linux | windows | macos: the machine running factoria
std::string xml_escape(const std::string& s, bool androidString = false);
std::string sh_quote(const std::string& s);

// Copies the project files `files` (project-relative) into `dest`, keeping their paths.
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
// The game name with the characters a file name cannot hold replaced (the .app folder of macOS).
std::string fs_safe_name(const std::string& s);
// Seals an exported .app with an ad hoc signature; returns "" or what went wrong.
std::string sign_app_ad_hoc(const stdfs::path& app);
// `icon` is the platform's icon (load_platform_icon), empty when none is set: the .icns of a macOS app, the icon of the
// Windows exe, the PNG and .desktop file of a Linux build.
Result<void> export_desktop(const Project& p, const std::string& platform, const stdfs::path& player,
                            const stdfs::path& outRoot, const std::vector<std::string>& files, const Image& icon,
                            ExportReport& report);

// ---- android (export_android.cpp) -------------------------------------------------------------------

// Everything the Android export decides before it writes anything (so plan_export can report it and fail early).
struct AndroidPlan {
    std::string format;                  // "apk" | "aab" | "gradle"
    bool release = false;
    AndroidToolchain toolchain;          // JDK + SDK (found for every format: the SDK also goes to local.properties)
    stdfs::path artifact;                // <outRoot>/<slug>[-debug].apk|aab; empty for "gradle"
    // Release signing (apk/aab only): the keystore of export.android.signing resolved against the project folder, its
    // alias, and the passwords (environment variables win over ~/.factoria/export.json). Empty keystore = signed with
    // the debug key, with a warning.
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

}  // namespace fa::export_detail
