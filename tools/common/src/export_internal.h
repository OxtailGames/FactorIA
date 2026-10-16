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

#include "fa/core/image.h"
#include "fa/core/types.h"
#include "fa/tooling/export.h"
#include "fa/tooling/export_settings.h"
#include "util.h"

namespace fa::export_detail {

namespace stdfs = std::filesystem;
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
};

// ---- helpers (export.cpp) -----------------------------------------------------------------------------

std::string host_platform();  // linux | windows | macos: the machine running factoria
std::string replace_all(std::string text, const std::string& from, const std::string& to);
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

Result<void> export_android(const ExportOptions& o, const Project& p, const MobileSetup& setup, const stdfs::path& outRoot,
                            const std::vector<std::string>& files, ExportReport& report);

// ---- ios (export_ios.cpp) ---------------------------------------------------------------------------

// `icon` is the iOS icon (load_platform_icon), empty when none is set: it becomes Assets.xcassets next to build_ios.sh.
Result<void> export_ios(const ExportOptions& o, const Project& p, const MobileSetup& setup, const stdfs::path& outRoot,
                        const std::vector<std::string>& files, const Image& icon, ExportReport& report);

}  // namespace fa::export_detail
