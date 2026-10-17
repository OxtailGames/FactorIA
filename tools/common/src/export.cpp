// Game export: planning, the report, project loading, the helpers the platform files share, and the command.
// The platform work lives in export_desktop.cpp, export_android.cpp and export_ios.cpp; what they share is declared in
// export_internal.h (namespace fa::export_detail). The behaviour and the options are described in
// fa/tooling/export.h and docs/EXPORTING.md.
#include "fa/tooling/export.h"

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <filesystem>
#include <regex>
#include <set>

#include "export_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/json.h"
#include "fa/core/strings.h"
#include "fa/tooling/ai_disclosure.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/export_settings.h"
#include "fa/tooling/icons.h"
#include "fa/tooling/notices.h"
#include "fa/tooling/project_fs.h"
#include "fa/tooling/setup.h"
#include "util.h"

#if defined(_WIN32)
#include <windows.h>
#elif defined(__APPLE__)
#include <mach-o/dyld.h>
#endif

namespace fa::export_detail {

// ---- helpers shared with the platform files (declared in export_internal.h) ------------------------

const std::vector<std::string>& export_formats() {
    static const std::vector<std::string> formats = {"apk", "aab", "gradle"};
    return formats;
}

bool is_export_format(const std::string& format) {
    return std::find(export_formats().begin(), export_formats().end(), format) != export_formats().end();
}

const std::vector<std::string>& all_export_formats() {
    static const std::vector<std::string> formats = {"apk", "aab", "gradle", "appimage"};
    return formats;
}

std::string host_platform() {
#if defined(_WIN32)
    return "windows";
#elif defined(__APPLE__)
    return "macos";
#else
    return "linux";
#endif
}

std::string xml_escape(const std::string& s, bool androidString) {
    std::string o;
    for (char c : s) {
        switch (c) {
            case '&': o += "&amp;"; break;
            case '<': o += "&lt;"; break;
            case '>': o += "&gt;"; break;
            case '"': o += androidString ? "\\&quot;" : "&quot;"; break;
            case '\'': o += androidString ? "\\'" : "&apos;"; break;
            case '@': o += androidString ? "\\@" : "@"; break;
            default: o += c;
        }
    }
    return o;
}

std::string sh_quote(const std::string& s) {
    std::string o = "'";
    for (char c : s) o += c == '\'' ? std::string("'\\''") : std::string(1, c);
    return o + "'";
}

Result<void> copy_game(const Project& p, const std::vector<std::string>& files, const stdfs::path& dest) {
    std::error_code ec;
    stdfs::create_directories(os_path(dest), ec);
    for (const auto& f : files) {
        stdfs::path to = dest / f;
        stdfs::create_directories(os_path(to.parent_path()), ec);
        const auto staged = p.staged.find(f);
        const stdfs::path from = staged != p.staged.end() ? staged->second : p.dir / f;
        stdfs::copy_file(os_path(from), os_path(to), stdfs::copy_options::overwrite_existing, ec);
        if (ec) return err("export: cannot copy '" + f + "' to " + generic(to) + ": " + ec.message());
    }
    return {};
}

Result<void> write_text(const stdfs::path& path, const std::string& text, bool executable) {
    std::string e;
    if (!write_file(path, text, &e)) return err("export: " + e);
    if (executable) {
        std::error_code ec;
        stdfs::permissions(os_path(path), stdfs::perms::owner_exec | stdfs::perms::group_exec | stdfs::perms::others_exec,
                           stdfs::perm_options::add, ec);
    }
    return {};
}

std::string safe_version_name(const std::string& v) {
    std::string o;
    for (char c : v) if (std::isalnum(static_cast<unsigned char>(c)) || c == '.' || c == '-' || c == '_' || c == '+') o += c;
    return o.empty() ? "0.1.0" : o;
}

Result<Image> load_platform_icon(const Project& p, const std::string& platform, std::vector<std::string>& warnings) {
    const std::string rel = p.settings.icon_for(platform);
    if (rel.empty()) return Image{};
    const std::string pointer = rel == p.settings.icon ? "/icon" : "/export/" + platform + "/icon";
    std::vector<ExportSettingsIssue> issues;
    auto icon = load_icon_image(generic(p.dir), rel, pointer, &issues);
    if (!icon.ok()) return icon.error();
    for (const ExportSettingsIssue& i : issues) warnings.push_back(i.to_string());
    return std::move(icon.value());
}

// ---- mobile: templates shared by the Android and iOS exports ----------------------------------------

// The files of the project template platforms/<dir>: from the engine checkout in source mode, from this binary otherwise.
Result<std::vector<TemplateFile>> load_templates(const MobileSetup& m, const std::string& dir) {
    std::vector<TemplateFile> out;
    if (m.prebuilt) {
        const std::string prefix = "platforms/" + dir + "/";
        for (const std::string& path : bundled_list(prefix)) {
            auto data = bundled_read(path);
            if (!data) return err("export: cannot read the built-in template " + path);
            out.push_back({path.substr(prefix.size()), std::move(*data)});
        }
        if (out.empty())
            return err("export: this factoria has no built-in " + dir + " project template",
                       "this is an engine bug; report it, or use --engine-root with a source checkout");
        return out;
    }
    const stdfs::path tpl = m.engine / "platforms" / dir;
    std::error_code ec;
    for (stdfs::recursive_directory_iterator it(tpl, ec), end; !ec && it != end; it.increment(ec)) {
        if (!it->is_regular_file(ec)) continue;
        auto data = read_file(it->path());
        if (!data) return err("export: cannot read template " + generic(it->path()));
        out.push_back({generic(stdfs::relative(it->path(), tpl, ec)), std::move(*data)});
    }
    return out;
}

// Template sections: the lines between one that is only "{{#source}}" and one that is only "{{/source}}" are kept in
// source mode and dropped in prebuilt mode. The marker lines themselves are never written.
Result<std::string> select_sections(const std::string& text, bool source, const std::string& where) {
    std::string out;
    bool inSource = false, bad = false;
    for (std::size_t pos = 0; pos < text.size();) {
        const std::size_t nl = text.find('\n', pos);
        const std::size_t end = nl == std::string::npos ? text.size() : nl + 1;
        const std::string line = text.substr(pos, end - pos);
        pos = end;
        const std::string_view t = trim(line);
        if (t == "{{#source}}" || t == "{{/source}}") {
            bad = bad || inSource != (t == "{{/source}}");  // nested, or closed without being open
            inSource = !inSource;
        } else if (!inSource || source) {
            out += line;
        }
    }
    if (bad || inSource) return err("export: bad section markers in template " + where, "this is an engine bug; report it");
    return out;
}

}  // namespace fa::export_detail

namespace fa {
using namespace export_detail;

namespace {

bool is_inside(const stdfs::path& child, const stdfs::path& parent) {
    auto c = child.begin(), p = parent.begin();
    for (; p != parent.end(); ++p, ++c)
        if (c == child.end() || *c != *p) return false;
    return true;
}

bool is_reverse_dns(const std::string& id) {
    static const std::regex re("^[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z][A-Za-z0-9_]*)+$");
    return std::regex_match(id, re);
}

bool is_java_keyword(const std::string& s) {
    static const std::set<std::string> kw = {
        "abstract", "assert",  "boolean",   "break",     "byte",   "case",      "catch",  "char",      "class",
        "const",    "continue", "default",  "do",        "double", "else",      "enum",   "extends",   "final",
        "finally",  "float",   "for",       "goto",      "if",     "implements", "import", "instanceof", "int",
        "interface", "long",   "native",    "new",       "package", "private",  "protected", "public",  "return",
        "short",    "static",  "strictfp",  "super",     "switch", "synchronized", "this", "throw",     "throws",
        "transient", "try",    "void",      "volatile",  "while",  "true",      "false",  "null"};
    return kw.count(s) > 0;
}

// ---- project -----------------------------------------------------------------------------------

Result<Project> load_and_validate(const ExportOptions& o, const std::string& platform, std::vector<std::string>& warnings) {
    Project p;
    std::error_code ec;
    if (o.projectDir.empty()) return err("export: no project directory given", "pass the folder that contains factoria.json");
    p.dir = stdfs::weakly_canonical(o.projectDir, ec);
    if (!stdfs::is_directory(p.dir, ec)) return err("export: project directory '" + o.projectDir + "' does not exist");
    stdfs::path file = p.dir / "factoria.json";
    auto text = read_file(file);
    if (!text)
        return err("export: " + generic(file) + " not found",
                   "pass the game folder (the one containing factoria.json); create a game with `factoria new <dir>`");
    auto parsed = parse_json(*text, generic(file));
    if (!parsed.ok()) return parsed.error();
    const Json& j = parsed.value();
    if (!j.is_object()) return err(generic(file) + "#/: expected a JSON object");

    p.name = j.value("name", std::string());
    if (p.name.empty()) return err(generic(file) + "#/name: missing or empty", "set \"name\": \"My Game\" in factoria.json");
    if (j.contains("id")) {
        if (!j["id"].is_string()) return err(generic(file) + "#/id: expected a string");
        p.id = j["id"].get<std::string>();
    }
    const bool mobile = platform == "android" || platform == "ios";
    if (p.id.empty()) {
        if (mobile)
            return err(generic(file) + "#/id: missing (required for " + platform + " bundles)",
                       "add a reverse-DNS id, e.g. \"id\": \"com.example." + slugify(p.name, '_') + "\"");
    } else if (!is_reverse_dns(p.id)) {
        return err(generic(file) + "#/id: '" + p.id + "' is not a reverse-DNS identifier",
                   "use letters, digits and underscores in at least two dot-separated parts, each starting with a letter "
                   "(e.g. com.example.spacedodge)");
    }
    if (mobile) {
        std::string bad;
        std::string seg;
        for (std::size_t i = 0; i <= p.id.size(); ++i) {
            if (i == p.id.size() || p.id[i] == '.') {
                if (is_java_keyword(seg)) bad = seg;
                seg.clear();
            } else {
                seg += p.id[i];
            }
        }
        if (!bad.empty())
            return err(generic(file) + "#/id: segment '" + bad + "' is a Java keyword and cannot be used in an Android package name",
                       "rename that part of the id, e.g. '" + bad + "_game'");
    }
    if (j.contains("version") && j["version"].is_string()) p.version = j["version"].get<std::string>();
    if (j.contains("mainScene") && j["mainScene"].is_string()) p.mainScene = j["mainScene"].get<std::string>();
    if (j.contains("feedbackFile") && j["feedbackFile"].is_string()) p.feedbackFile = j["feedbackFile"].get<std::string>();
    if (j.contains("display") && j["display"].is_object() && j["display"].contains("orientation") &&
        j["display"]["orientation"].is_string())
        p.orientation = j["display"]["orientation"].get<std::string>();
    if (p.orientation != "landscape" && p.orientation != "portrait" && p.orientation != "any") {
        warnings.push_back("display.orientation '" + p.orientation + "' is not landscape|portrait|any; using landscape");
        p.orientation = "landscape";
    }
    if (j.contains("platforms") && j["platforms"].is_array()) {
        p.hasPlatformsField = true;
        for (auto& e : j["platforms"])
            if (e.is_string()) p.platforms.push_back(e.get<std::string>());
        if (std::find(p.platforms.begin(), p.platforms.end(), platform) == p.platforms.end())
            warnings.push_back("factoria.json \"platforms\" does not list '" + platform +
                               "'; exporting anyway (add it to silence this warning)");
    }
    if (!stdfs::exists(p.dir / p.mainScene, ec))
        return err(generic(file) + "#/mainScene: '" + p.mainScene + "' does not exist in the project",
                   "create the scene or fix the path (project-relative, forward slashes)");
    // `icon` and `export` (docs/EXPORTING.md, "Platform settings"): a wrong value is an error, an unknown key a warning.
    auto settings = load_export_settings(generic(p.dir), &warnings);
    if (!settings.ok()) return settings.error();
    p.settings = std::move(settings.value());
    // Native plugins: the export needs each one's build for this platform (docs/EXTENDING.md, "Native plugins").
    auto project = j.contains("plugins") ? load_project(generic(p.dir)) : Result<ProjectSettings>(ProjectSettings{});
    if (!project.ok()) return project.error();
    for (const PluginSettings& plugin : project->plugins) {
        if (auto folder = plugin_folder(generic(p.dir), plugin); folder.ok()) p.pluginFolders.push_back(folder.value());
        const std::vector<std::string> platforms = project->plugin_platforms(plugin);
        if (std::find(platforms.begin(), platforms.end(), platform) == platforms.end()) continue;
        auto build = plugin_build(generic(p.dir), plugin, platform);
        if (!build.ok()) return build.error();
        p.plugins.push_back({plugin.name, build.value()});
    }
    if (p.settings.icon_for(platform).empty())
        warnings.push_back("No icon is set for " + platform + ", so the app gets the platform's default icon. Set \"icon\" in "
                           "factoria.json (a square PNG or JPG, 1024x1024 recommended), or \"export." + platform +
                           ".icon\" for this platform only");
    return p;
}

// ---- game file collection ----------------------------------------------------------------------

bool excluded_top_level(const std::string& name, const std::string& feedbackFile) {
    // steam_appid.txt makes a game run as the app it names, whoever starts it (the Steam plugin reads it in development):
    // a shipped game gets its app id from the Steam client.
    static const std::set<std::string> names = {"build", "tests", "tools", "types", "node_modules", "AGENTS.md",
                                                "CLAUDE.md", "jsconfig.json", "ENGINE_FEEDBACK.json", "steam_appid.txt"};
    return names.count(name) > 0 || name == feedbackFile;
}

// Project-relative paths (forward slashes, sorted) of every file that ships.
std::vector<std::string> collect_game_files(const Project& p, const stdfs::path& outDirAbs) {
    std::vector<std::string> out;
    std::error_code ec;
    for (stdfs::recursive_directory_iterator it(p.dir, ec), end; !ec && it != end; it.increment(ec)) {
        const stdfs::path& full = it->path();
        stdfs::path rel = stdfs::relative(full, p.dir, ec);
        std::string name = full.filename().string();
        bool skip = !name.empty() && name[0] == '.';
        if (!skip && rel.has_parent_path() == false && excluded_top_level(name, p.feedbackFile)) skip = true;
        if (!skip && (!outDirAbs.empty() || !p.pluginFolders.empty()) && it->is_directory(ec)) {
            std::error_code ec2;
            const stdfs::path dir = stdfs::weakly_canonical(full, ec2);
            if (!outDirAbs.empty() && is_inside(dir, outDirAbs)) skip = true;  // never copy the export into itself
            // A native plugin's folder: its build is copied or linked for the platform, its sources do not ship.
            for (const stdfs::path& f : p.pluginFolders) skip = skip || dir == stdfs::weakly_canonical(f, ec2);
        }
        if (skip) {
            if (it->is_directory(ec)) it.disable_recursion_pending();
            continue;
        }
        if (it->is_regular_file(ec)) out.push_back(generic(rel));
    }
    std::sort(out.begin(), out.end());
    return out;
}

// The files of an export, relative to its root. An Android export that ran Gradle holds thousands of build products too
// (.gradle/, build/, app/build/, plugins/<name>/build/): they are not part of the export and are left out.
std::vector<std::string> list_files(const stdfs::path& root, bool skipGradleOutput) {
    std::vector<std::string> out;
    std::error_code ec;
    const stdfs::path osRoot = os_path(root);
    for (stdfs::recursive_directory_iterator it(osRoot, ec), end; !ec && it != end; it.increment(ec)) {
        const std::string rel = generic(it->path().lexically_relative(osRoot));
        const std::size_t pluginSlash = rel.rfind("plugins/", 0) == 0 ? rel.find('/', 8) : std::string::npos;
        if (skipGradleOutput && it->is_directory(ec) &&
            (rel == ".gradle" || rel == ".kotlin" || rel == "build" || rel == "app/build" ||
             (pluginSlash != std::string::npos && rel.compare(pluginSlash, std::string::npos, "/build") == 0))) {
            it.disable_recursion_pending();
            continue;
        }
        if (it->is_regular_file(ec)) out.push_back(rel);
    }
    std::sort(out.begin(), out.end());
    return out;
}

// ---- mobile: choosing the mode (the modes are described in export_internal.h) ------------------------

bool android_libs_present(const stdfs::path& libs) {
    std::error_code ec;
    for (const char* abi : kAndroidAbis)
        if (!stdfs::is_regular_file(libs / "jniLibs" / abi / "libfactoria_player.so", ec)) return false;
    return true;
}

bool ios_libs_present(const stdfs::path& libs) {
    std::error_code ec;
    for (const char* slice : kIosSlices)
        if (!stdfs::is_regular_file(libs / slice / kIosMarkerLib, ec)) return false;
    return true;
}

Result<stdfs::path> engine_checkout(const std::string& root, const char* need, const std::string& requestedBy) {
    std::error_code ec;
    stdfs::path r = stdfs::weakly_canonical(root, ec);
    if (!stdfs::exists(r / "CMakeLists.txt", ec) || !stdfs::exists(r / need, ec))
        return err("export: engine checkout not found at '" + generic(r) + "' (missing " + need +
                       (requestedBy.empty() ? "" : "; requested with " + requestedBy) + ")",
                   "point it at the FactorIA repository folder (the one with CMakeLists.txt and platforms/), or leave "
                   "--engine-root and $FACTORIA_ENGINE_DIR unset to use the prebuilt players of the FactorIA download");
    return r;
}

// Picks the mode. In order:
//   1. an engine checkout was asked for (--engine-root, else $FACTORIA_ENGINE_DIR when no --mobile-dir was given): source;
//   2. a prebuilt players folder was given (--mobile-dir) or <factoria dir>/mobile holds them: prebuilt;
//   3. the checkout factoria was built from still exists (a development build): source;
//   4. otherwise an error that says what to do.
Result<MobileSetup> resolve_mobile(const ExportOptions& o, const std::string& platform) {
    const bool android = platform == "android";
    const char* need = android ? "platforms/android/settings.gradle" : "platforms/ios/Info.plist.in";
    const std::string sub = android ? "android" : "ios";
    const stdfs::path mobile = o.mobileDir.empty() ? executable_dir() / "mobile" : stdfs::path(o.mobileDir);
    const stdfs::path libs = mobile / sub;

    std::string root = o.engineRoot, via = "--engine-root";
    if (root.empty() && o.mobileDir.empty()) {
        if (const char* env = std::getenv("FACTORIA_ENGINE_DIR"); env && *env) root = env, via = "$FACTORIA_ENGINE_DIR";
    }
    MobileSetup s;
    if (!root.empty()) {
        auto engine = engine_checkout(root, need, via);
        if (!engine.ok()) return engine.error();
        s.engine = *engine;
        return s;
    }
    if (android ? android_libs_present(libs) : ios_libs_present(libs)) {
        s.prebuilt = true;
        s.libs = libs;
        return s;
    }
    const std::string what = android ? "libfactoria_player.so in " + generic(libs / "jniLibs" / "<abi>")
                                     : std::string(kIosMarkerLib) + " in " + generic(libs / "<iphoneos|iphonesimulator>");
    if (!o.mobileDir.empty())
        return err("export: no prebuilt " + std::string(android ? "Android" : "iOS") + " player: " + what + " not found",
                   "point --mobile-dir at the mobile/ folder of the FactorIA download, or omit it");
    const std::string builtFrom = o.buildSourceRoot.empty() ? std::string(FA_SOURCE_ROOT) : o.buildSourceRoot;
    if (auto engine = engine_checkout(builtFrom, need, {}); engine.ok()) {
        s.engine = *engine;
        return s;
    }
    // The mobile libraries `factoria setup players` downloaded for this factoria version (<home>/players/<version>/mobile).
    if (const std::string installed = installed_mobile_dir(); !installed.empty()) {
        const stdfs::path installedLibs = stdfs::path(installed) / sub;
        if (android ? android_libs_present(installedLibs) : ios_libs_present(installedLibs)) {
            s.prebuilt = true;
            s.libs = installedLibs;
            return s;
        }
    }
    return err("export: cannot export for " + platform + ": no prebuilt player (" + what + " not found) and no engine "
                   "source checkout (the one factoria was built from, '" + builtFrom + "', has no " + need + ")",
               "run `factoria setup players` (the editor: Set up in the Export window) to download the prebuilt players of "
               "this FactorIA version" + std::string(android ? "" : " (the iOS ones come from the macOS package)") +
                   ", use the FactorIA download from https://github.com/OxtailGames/FactorIA/releases, whose mobile/ folder "
                   "holds them, or set FACTORIA_ENGINE_DIR (or pass --engine-root) to a FactorIA source checkout to compile the "
                   "engine from source");
}

// ---- license notices -----------------------------------------------------------------------------

// The runtime inside the game is FactorIA (MIT) plus third-party code whose licenses ask for their notices in every
// copy: FACTORIA_NOTICES.txt goes where it ships with the game (next to the executable, or inside the app bundle/APK).
stdfs::path notices_dir(const Project& p, const std::string& platform, const stdfs::path& outRoot) {
    if (platform == "macos") return outRoot / (fs_safe_name(p.name) + ".app") / "Contents" / "Resources";
    if (platform == "android") return outRoot / "app" / "src" / "main" / "assets";
    if (platform == "ios") return outRoot / "game";
    return outRoot;
}

Result<void> write_notices(const Project& p, const std::string& platform, const stdfs::path& outRoot, ExportReport& report) {
    const stdfs::path dir = notices_dir(p, platform, outRoot);
    if (auto r = write_text(dir / kExportNoticesFile, third_party_notices(NoticeScope::Game)); !r.ok()) return r;
    report.notices = generic((dir.lexically_relative(outRoot) / kExportNoticesFile).lexically_normal());
    report.nextSteps.push_back(report.notices + " holds the licenses of the FactorIA runtime inside the game: keep it in "
                               "what you distribute (docs/EXPORTING.md, \"License notices\")");
    return {};
}

// AI_CONTENT_DISCLOSURE.md at the top of the export when any asset of the project is recorded as made with AI
// (provenance in assets.json): the text for the AI questions of Steam's content survey. `projectFiles` are the project's
// files before the asset steps swapped some for their converted forms.
Result<void> write_ai_disclosure(const Project& p, const std::vector<std::string>& projectFiles, const stdfs::path& outRoot,
                                 ExportReport& report) {
    auto text = read_file(p.dir / assets::kManifestFile);
    if (!text) return {};
    auto manifest = parse_json(*text, assets::kManifestFile);
    if (!manifest.ok() || !has_ai_content(*manifest)) return {};
    if (auto r = write_text(outRoot / kAiDisclosureFile, ai_content_disclosure(*manifest, projectFiles)); !r.ok()) return r;
    report.nextSteps.push_back(std::string(kAiDisclosureFile) + " answers the AI-generated content questions of store forms (Steam); "
                               "check its section on assets without provenance first");
    return {};
}

// ---- the output folder: only one an export wrote is replaced ---------------------------------------

// kExportMarkerFile, written first into every export folder (so an export that stopped halfway is replaced too).
std::string marker_text(const Project& p, const std::string& platform) {
    return "Written by `factoria export` (" + platform + " export of \"" + replace_all(p.name, "\n", " ") + "\").\n"
           "The next export of this game deletes this folder and writes it again. A folder of that name without this\n"
           "file is never deleted: the export stops with an error instead (docs/EXPORTING.md). The game does not need\n"
           "this file; leave it out of what you ship if you like.\n";
}

// export_project deletes <out>/<slug>-<platform> before writing it, so the plan accepts it only when an export wrote
// it: the marker is there, or FACTORIA_NOTICES.txt is where this platform's export puts it (exports made before the
// marker existed). Absent or empty is fine too. Anything else, e.g. a folder of the user's that happens to have the
// name, is an error that says how to proceed.
Result<void> check_replaceable(const Project& p, const std::string& platform, const stdfs::path& outRoot) {
    std::error_code ec;
    if (!stdfs::exists(stdfs::symlink_status(os_path(outRoot), ec))) return {};
    const std::string where = "'" + generic(outRoot) + "'";
    const std::string choose =
        "choose another output folder (--out, the `out` argument of project.export, or Choose... in the editor's Export "
        "window)";
    if (!stdfs::is_directory(os_path(outRoot), ec))
        return err("export: " + where + " already exists and is not a folder; an export would delete it, so it is left "
                   "as it is",
                   choose + ", or move or delete that file yourself");
    if (stdfs::is_regular_file(os_path(outRoot / kExportMarkerFile), ec)) return {};
    if (stdfs::is_regular_file(os_path(notices_dir(p, platform, outRoot) / kExportNoticesFile), ec)) return {};
    if (bool empty = stdfs::is_empty(os_path(outRoot), ec); empty && !ec) return {};
    return err("export: the output folder " + where + " already exists and was not written by an export (it has no " +
                   kExportMarkerFile + " file); an export would delete it, so it is left as it is",
               choose + ", or move or delete that folder yourself if nothing in it is needed. A folder an older "
               "factoria exported has no marker either: delete it once and export again; later exports replace it on "
               "their own");
}

// ---- plan: every check, before anything is written ------------------------------------------------

struct Plan {
    std::string platform;
    Project project;
    stdfs::path outParent, outRoot;  // absolute; outRoot = outParent/<slug>-<platform>, replaced by the export (absent,
                                     // empty or an earlier export: check_replaceable)
    stdfs::path player;              // desktop
    MobileSetup mobile;              // android/ios
    Image icon;                      // linux/windows/macos/ios, only when the plan is made for an export: the platform's icon
    AndroidPlan android;             // android
    AppImagePlan appimage;           // linux, format "appimage"
    std::vector<std::string> warnings;
};

// With `forExport` the icon of a desktop or iOS export is decoded (it is used right away); a plan alone only checks
// that its file exists (plan_export runs every few seconds in the editor), with the same error the export would give.
Result<Plan> make_plan(const ExportOptions& options, bool forExport = false) {
    Plan plan;
    plan.platform = normalize_export_platform(options.platform);
    if (plan.platform.empty())
        return err("export: unknown platform '" + options.platform + "'", "use one of: linux, windows, macos, android, ios");
    auto project = load_and_validate(options, plan.platform, plan.warnings);
    if (!project.ok()) return project.error();
    plan.project = std::move(project.value());
    const Project& p = plan.project;

    std::error_code ec;
    const stdfs::path outParent = options.outDir.empty() ? p.dir / "build" / "export" : stdfs::path(options.outDir);
    plan.outParent = stdfs::weakly_canonical(stdfs::absolute(outParent, ec), ec);
    const std::string slug = slugify(p.name, '-').empty() ? "game" : slugify(p.name, '-');
    plan.outRoot = plan.outParent / (slug + "-" + plan.platform);
    if (is_inside(p.dir, plan.outRoot) || plan.outRoot == p.dir)
        return err("export: output folder '" + generic(plan.outRoot) + "' would contain the project", "choose another --out folder");
    if (auto r = check_replaceable(p, plan.platform, plan.outRoot); !r.ok()) return r.error();

    // Checked before the player: on a computer that cannot build an AppImage, a missing player is beside the point.
    const bool appimage = plan.platform == "linux" && to_lower(options.format) == "appimage";
    if (appimage) {
        auto image = plan_appimage(options, p, plan.outRoot);
        if (!image.ok()) return image.error();
        plan.appimage = std::move(image.value());
    }

    if (plan.platform == "android" || plan.platform == "ios") {
        auto setup = resolve_mobile(options, plan.platform);
        if (!setup.ok()) return setup.error();
        plan.mobile = std::move(setup.value());
    } else {
        auto player = find_player(options, plan.platform);
        if (!player.ok()) return player.error();
        plan.player = std::move(player.value());
    }
    if (plan.platform == "android") {  // the Android export loads its own icons (they are a set of layers)
        auto android = plan_android(options, p, plan.outRoot, plan.warnings, forExport);
        if (!android.ok()) return android.error();
        plan.android = std::move(android.value());
    } else {
        if (!options.format.empty() && !appimage)
            plan.warnings.push_back("The format '" + options.format + "' only applies to android (apk, aab, gradle) and linux (appimage); " + plan.platform +
                                    " has a single format, so it is ignored");
        const std::string rel = p.settings.icon_for(plan.platform);
        std::error_code iconEc;
        if (forExport || (!rel.empty() && !stdfs::is_regular_file(p.dir / rel, iconEc))) {
            auto icon = load_platform_icon(p, plan.platform, plan.warnings);
            if (!icon.ok()) return icon.error();
            plan.icon = std::move(icon.value());
        }
    }
    return plan;
}

}  // namespace

namespace export_detail {

std::vector<std::string> list_game_files(const stdfs::path& dir, const std::string& feedbackFile) {
    Project p;
    p.dir = dir;
    p.feedbackFile = feedbackFile;
    if (auto project = load_project(generic(dir)); project.ok())
        for (const PluginSettings& plugin : project->plugins)
            if (auto folder = plugin_folder(generic(dir), plugin); folder.ok()) p.pluginFolders.push_back(folder.value());
    return collect_game_files(p, {});
}

}  // namespace export_detail

stdfs::path executable_dir() {
    std::error_code ec;
#if defined(_WIN32)
    wchar_t buf[MAX_PATH * 4];
    DWORD n = GetModuleFileNameW(nullptr, buf, DWORD(sizeof(buf) / sizeof(buf[0])));
    if (n > 0) return stdfs::path(std::wstring(buf, n)).parent_path();
#elif defined(__APPLE__)
    char buf[4096];
    uint32_t size = sizeof(buf);
    if (_NSGetExecutablePath(buf, &size) == 0) return stdfs::weakly_canonical(buf, ec).parent_path();
#else
    stdfs::path p = stdfs::read_symlink("/proc/self/exe", ec);
    if (!ec) return p.parent_path();
#endif
    return stdfs::current_path(ec);
}

std::string normalize_export_platform(const std::string& name) {
    std::string n;
    for (char c : name) n += static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    if (n.empty()) return host_platform();
    if (n == "win" || n == "win32" || n == "windows" || n == "win64") return "windows";
    if (n == "mac" || n == "macos" || n == "osx" || n == "darwin") return "macos";
    if (n == "linux") return "linux";
    if (n == "android") return "android";
    if (n == "ios" || n == "iphone") return "ios";
    return {};
}

Json ExportReport::to_json() const {
    Json j = Json::object();
    j["outputDir"] = outputDir;
    if (!mode.empty()) j["mode"] = mode;
    if (!format.empty()) j["format"] = format;
    if (!artifact.empty()) j["artifact"] = artifact;
    j["notices"] = notices;
    j["files"] = files;
    j["nextSteps"] = nextSteps;
    j["warnings"] = warnings;
    return j;
}

Json ExportPlan::to_json() const {
    Json j = Json::object();
    j["platform"] = platform;
    j["outputDir"] = outputDir;
    if (!mode.empty()) j["mode"] = mode;
    if (!format.empty()) j["format"] = format;
    if (!artifact.empty()) j["artifact"] = artifact;
    if (!toolchain.jdk.empty() || !toolchain.sdk.empty())
        j["toolchain"] = Json::object({{"jdk", toolchain.jdk},
                                       {"jdkFrom", toolchain.jdkFrom},
                                       {"jdkMajor", toolchain.jdkMajor},
                                       {"sdk", toolchain.sdk},
                                       {"sdkFrom", toolchain.sdkFrom}});
    if (!player.empty()) j["player"] = player;
    j["warnings"] = warnings;
    return j;
}

Result<ExportPlan> plan_export(const ExportOptions& options) {
    auto planned = make_plan(options);
    if (!planned.ok()) return planned.error();
    const Plan& plan = planned.value();
    ExportPlan out;
    out.platform = plan.platform;
    out.outputDir = generic(plan.outRoot);
    if (plan.platform == "android" || plan.platform == "ios") out.mode = plan.mobile.prebuilt ? "prebuilt" : "source";
    else out.player = generic(plan.player);
    if (plan.appimage.enabled) {
        out.format = "appimage";
        out.artifact = generic(plan.appimage.artifact);
    }
    if (plan.platform == "android") {
        out.format = plan.android.format;
        out.artifact = generic(plan.android.artifact);
        if (plan.android.format != "gradle") out.toolchain = plan.android.toolchain;
        out.toolchain.problems.clear();
        out.toolchain.warnings.clear();  // the plan's warnings carry them
    }
    out.warnings = plan.warnings;
    return out;
}

Result<ExportReport> export_project(const ExportOptions& options) {
    auto planned = make_plan(options, true);  // every check first: a failed one leaves the previous export in place
    if (!planned.ok()) return planned.error();
    const Plan& plan = planned.value();
    Project p = plan.project;  // the asset steps fill p.staged
    const std::string& platform = plan.platform;
    const stdfs::path& outRoot = plan.outRoot;
    ExportReport report;
    report.warnings = plan.warnings;

    std::error_code ec;
    stdfs::create_directories(os_path(plan.outParent), ec);
    if (ec) return err("export: cannot create output directory '" + generic(plan.outParent) + "': " + ec.message());
    stdfs::remove_all(os_path(outRoot), ec);  // always a fresh <slug>-<platform> folder; the plan checked that an export wrote it
    stdfs::create_directories(os_path(outRoot), ec);
    if (ec) return err("export: cannot create '" + generic(outRoot) + "': " + ec.message());
    if (auto r = write_text(outRoot / kExportMarkerFile, marker_text(p, platform)); !r.ok()) return r.error();

    std::vector<std::string> files = collect_game_files(p, plan.outParent == p.dir ? outRoot : plan.outParent);
    // The release keystore never ships: a keystore kept inside the project folder would end up in the app.
    if (const std::string keystore = p.settings.android.signing.keystore; !keystore.empty() && !stdfs::path(keystore).is_absolute()) {
        const std::string rel = generic(stdfs::path(keystore).lexically_normal());
        const auto it = std::find(files.begin(), files.end(), rel);
        if (it != files.end()) {
            files.erase(it);
            if (platform == "android")
                report.warnings.push_back("The keystore '" + rel + "' is inside the project folder. It is left out of the app, but keep it out of "
                                          "your repository too (add it to .gitignore, or move it outside the project and use an absolute path in "
                                          "export.android.signing.keystore): anyone who gets it can sign apps as you");
        }
    }

    const std::vector<std::string> projectFiles = files;  // before the asset steps swap files for their converted forms
    if (auto assetsReady = prepare_game_assets(p, platform, files, report); !assetsReady.ok()) {
        stdfs::remove_all(os_path(outRoot), ec);
        return assetsReady.error();
    }

    Result<void> r;
    bool keepOutput = false;  // a failed Gradle build leaves its project in place, so that it can be opened and fixed
    if (platform == "android" || platform == "ios") {
        report.mode = plan.mobile.prebuilt ? "prebuilt" : "source";
        r = platform == "android" ? export_android(p, plan.mobile, plan.android, outRoot, files, report)
                                  : export_ios(options, p, plan.mobile, outRoot, files, plan.icon, report);
    } else {
        r = export_desktop(p, platform, plan.player, outRoot, files, plan.icon, report);
    }
    if (r.ok()) r = write_notices(p, platform, outRoot, report);  // before the build: the APK carries the notices
    if (r.ok()) r = write_ai_disclosure(p, projectFiles, outRoot, report);
    if (r.ok() && plan.appimage.enabled) {  // the folder is complete by now: a failed appimagetool leaves it, like a failed Gradle build leaves its project
        r = build_appimage(options, p, plan.appimage, outRoot, report);
        keepOutput = !r.ok();
    }
    if (r.ok() && platform == "android") r = build_android(options, p, plan.mobile, plan.android, outRoot, report, keepOutput);
    if (!r.ok()) {
        if (!keepOutput) stdfs::remove_all(os_path(outRoot), ec);
        return r.error();
    }
    if (platform == "macos") {  // last: the signature seals every file of the bundle, the notices too
        const std::string app = fs_safe_name(p.name) + ".app";
        if (std::string why = sign_app_ad_hoc(outRoot / app); !why.empty()) {
            report.warnings.push_back("The app bundle is not signed as a whole (" + why + "), so macOS will call it "
                                      "damaged once it is downloaded. On a Mac: codesign --force --sign - '" + app +
                                      "', or sign it with your Developer ID (next steps)");
        }
    }
    report.outputDir = generic(outRoot);
    report.files = list_files(outRoot, platform == "android");
    return report;
}

void register_export_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "project.export";
    info.category = "project";
    info.readOnly = false;
    info.summary = "Package the game for a platform: a desktop bundle, an Android APK/AAB, or an iOS project.";
    info.description =
        "Validates the project (factoria.json, name, mainScene, reverse-DNS id, the icon and export settings) and writes a "
        "fresh <out>/<game-slug>-<platform>/ folder (deleted and recreated on every call, but only when it is empty or an "
        "export wrote it: every export leaves a .factoria-export file at its top, and any other existing folder of that "
        "name is an error that says how to proceed, never deleted; the project itself is not modified). "
        "linux/windows/macos: the game plus the factoria_player runtime found next to the running factoria "
        "binary, so exporting for another OS than this machine's fails with a hint. android: a complete Gradle project "
        "that is then BUILT with its own Gradle wrapper (needs a JDK 17+ and the Android SDK, found automatically; the "
        "first build downloads Gradle and the Android Gradle plugin, so it takes minutes and needs network): `format` "
        "\"apk\" (default) or \"aab\" (Google Play bundle) leaves <slug>[-debug].apk/.aab next to the project and reports "
        "it as `artifact`; \"gradle\" only writes the project and builds nothing. `release` builds the release variant "
        "(signed with export.android.signing, else with the debug key and a warning). ios: the game plus an Xcode/CMake "
        "project and build_ios.sh. Android and iOS have a mode, reported as `mode`: \"prebuilt\" (the engine is the "
        "ready-made player in the mobile/ folder next to the factoria binary of the FactorIA download: no engine source, "
        "and for Android no NDK or CMake) or \"source\" (the engine is compiled from a source checkout, chosen by "
        "$FACTORIA_ENGINE_DIR or when factoria runs from a development build); with no players and no checkout the error "
        "says what to do. A failed Gradle build is an error that quotes what went wrong and where the log is "
        "(<out>/<slug>-android/build.log); the Gradle project stays on disk. linux with `format` \"appimage\" also builds the whole game as one "
        "<out>/<slug>-linux/<slug>-x86_64.AppImage (reported as `artifact`; needs Linux x86_64 or WSL and the tools of `setup.install` component appimage; the "
        "folder export stays). macOS: sign and notarize the exported app with `sign.macos`. Every export also writes "
        "FACTORIA_NOTICES.txt, the licenses of the engine code inside the game, where it ships with it (`notices`). "
        "Returns {outputDir, mode (android/ios), format and artifact (android), notices, files[], nextSteps[], "
        "warnings[]}; nextSteps lists what to do next (e.g. the adb install command). dryRun: true runs every check and "
        "writes nothing (no Gradle either): it returns {platform, outputDir (the folder an export would replace), mode, "
        "format, artifact (the file a build would write) and toolchain (android: the JDK and SDK found and where from), "
        "player (desktop), warnings[]} or the error the export would give (e.g. no JDK installed). Details: docs_read "
        "{\"name\":\"exporting\"}. Examples: {\"platform\":\"windows\",\"release\":true}, "
        "{\"platform\":\"android\",\"format\":\"aab\",\"release\":true}.";
    info.inputSchema = Json::parse(R"({
      "type":"object",
      "properties":{
        "platform":{"type":"string","description":"linux, windows, macos, android or ios (aliases win, mac, osx also work). Default: the machine running factoria."},
        "out":{"type":"string","description":"Parent folder of the export, relative to the project folder and inside it. Default: build/export."},
        "format":{"type":"string","enum":["apk","aab","gradle","appimage"],"description":"Android: apk (an installable app, the default unless export.android.format says otherwise), aab (the Google Play bundle) or gradle (only the Gradle project, nothing is built and no JDK or SDK is needed); apk and aab run Gradle and need a JDK 17+ and the Android SDK. Linux: appimage also builds <slug>-x86_64.AppImage, the whole game as one file (needs Linux x86_64 or WSL, and `setup.install` component appimage once). Other platforms ignore it."},
        "release":{"type":"boolean","description":"Android: build the release APK/AAB (signed with export.android.signing and the keystore passwords from FACTORIA_ANDROID_KEYSTORE_PASSWORD / FACTORIA_ANDROID_KEY_PASSWORD or ~/.factoria/export.json; without a keystore the debug key is used, with a warning). Other platforms: only changes the build commands in nextSteps (and the iOS script).","default":false},
        "dryRun":{"type":"boolean","description":"Only check whether the export can run (project, player or mobile mode, output folder): returns the plan or the error, writes nothing.","default":false}
      }})");
    registry.add(info, [projectDir](const Json& args) {
        ExportOptions o;
        o.projectDir = projectDir;
        o.platform = tooling_detail::arg_string(args, "platform", false);
        if (!o.platform.empty() && normalize_export_platform(o.platform).empty()) {
            const std::vector<std::string> platforms = {"linux", "windows", "macos", "android", "ios"};
            throw CommandError("invalid_argument", "Unknown platform '" + o.platform + "'.", did_you_mean(o.platform, platforms));
        }
        // Inside the project only, like fs.*: the export folder is deleted and rewritten on every call (when an export
        // wrote it).
        if (std::string out = tooling_detail::arg_string(args, "out", false); !out.empty()) {
            auto dir = resolve_project_path(projectDir, out);
            if (!dir) throw CommandError("invalid_argument", dir.error().message, dir.error().hint);
            o.outDir = dir->string();
        }
        o.format = tooling_detail::arg_string(args, "format", false);
        if (!o.format.empty() && std::find(all_export_formats().begin(), all_export_formats().end(), o.format) == all_export_formats().end())
            throw CommandError("invalid_argument", "Unknown format '" + o.format + "'.", did_you_mean(o.format, all_export_formats()));
        o.release = tooling_detail::arg_bool(args, "release", false);
        if (tooling_detail::arg_bool(args, "dryRun", false)) {
            auto plan = plan_export(o);
            if (!plan.ok()) throw CommandError("failed", plan.error().message, plan.error().hint);
            return plan->to_json();
        }
        auto r = export_project(o);
        if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
        return r->to_json();
    });
}

}  // namespace fa
