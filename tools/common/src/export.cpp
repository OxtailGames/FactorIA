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
#include "fa/core/json.h"
#include "fa/core/strings.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/export_settings.h"
#include "fa/tooling/icons.h"
#include "fa/tooling/notices.h"
#include "fa/tooling/project_fs.h"
#include "util.h"

#if defined(_WIN32)
#include <windows.h>
#elif defined(__APPLE__)
#include <mach-o/dyld.h>
#endif

namespace fa::export_detail {

// ---- helpers shared with the platform files (declared in export_internal.h) ------------------------

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
    stdfs::create_directories(dest, ec);
    for (const auto& f : files) {
        stdfs::path to = dest / f;
        stdfs::create_directories(to.parent_path(), ec);
        stdfs::copy_file(p.dir / f, to, stdfs::copy_options::overwrite_existing, ec);
        if (ec) return err("export: cannot copy '" + f + "' to " + generic(to) + ": " + ec.message());
    }
    return {};
}

Result<void> write_text(const stdfs::path& path, const std::string& text, bool executable) {
    std::string e;
    if (!write_file(path, text, &e)) return err("export: " + e);
    if (executable) {
        std::error_code ec;
        stdfs::permissions(path, stdfs::perms::owner_exec | stdfs::perms::group_exec | stdfs::perms::others_exec,
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
    auto settings = load_export_settings(o.projectDir, &warnings);  // `icon` and `export`: errors fail, unknown keys warn
    if (!settings.ok()) return settings.error();
    p.settings = std::move(settings.value());
    return p;
}

// ---- game file collection ----------------------------------------------------------------------

bool excluded_top_level(const std::string& name, const std::string& feedbackFile) {
    static const std::set<std::string> names = {"build", "tests", "tools", "types", "node_modules", "AGENTS.md",
                                                "CLAUDE.md", "jsconfig.json", "ENGINE_FEEDBACK.json"};
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
        if (!skip && it->is_directory(ec)) {
            std::error_code ec2;
            if (is_inside(stdfs::weakly_canonical(full, ec2), outDirAbs)) skip = true;  // never copy the export into itself
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

std::vector<std::string> list_files(const stdfs::path& root) {
    std::vector<std::string> out;
    std::error_code ec;
    for (stdfs::recursive_directory_iterator it(root, ec), end; !ec && it != end; it.increment(ec))
        if (it->is_regular_file(ec)) out.push_back(generic(stdfs::relative(it->path(), root, ec)));
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
    return err("export: cannot export for " + platform + ": no prebuilt player (" + what + " not found) and no engine "
                   "source checkout (the one factoria was built from, '" + builtFrom + "', has no " + need + ")",
               "use the FactorIA download from https://github.com/OxtailGames/FactorIA/releases, whose mobile/ folder "
               "holds the prebuilt players" + std::string(android ? "" : " (iOS ones ship in the macOS package only: export on a Mac)") +
                   ", or set FACTORIA_ENGINE_DIR (or pass --engine-root) to a FactorIA source checkout to compile the engine "
                   "from source");
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
    if (!stdfs::exists(stdfs::symlink_status(outRoot, ec))) return {};
    const std::string where = "'" + generic(outRoot) + "'";
    const std::string choose =
        "choose another output folder (--out, the `out` argument of project.export, or Choose... in the editor's Export "
        "window)";
    if (!stdfs::is_directory(outRoot, ec))
        return err("export: " + where + " already exists and is not a folder; an export would delete it, so it is left "
                   "as it is",
                   choose + ", or move or delete that file yourself");
    if (stdfs::is_regular_file(outRoot / kExportMarkerFile, ec)) return {};
    if (stdfs::is_regular_file(notices_dir(p, platform, outRoot) / kExportNoticesFile, ec)) return {};
    if (bool empty = stdfs::is_empty(outRoot, ec); empty && !ec) return {};
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

    if (plan.platform == "android" || plan.platform == "ios") {
        auto setup = resolve_mobile(options, plan.platform);
        if (!setup.ok()) return setup.error();
        plan.mobile = std::move(setup.value());
    } else {
        auto player = find_player(options, plan.platform);
        if (!player.ok()) return player.error();
        plan.player = std::move(player.value());
    }
    if (plan.platform != "android") {  // the Android export loads its own icons (they are a set of layers)
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
    out.warnings = plan.warnings;
    return out;
}

Result<ExportReport> export_project(const ExportOptions& options) {
    auto planned = make_plan(options, true);  // every check first: a failed one leaves the previous export in place
    if (!planned.ok()) return planned.error();
    const Plan& plan = planned.value();
    const Project& p = plan.project;
    const std::string& platform = plan.platform;
    const stdfs::path& outRoot = plan.outRoot;
    ExportReport report;
    report.warnings = plan.warnings;

    std::error_code ec;
    stdfs::create_directories(plan.outParent, ec);
    if (ec) return err("export: cannot create output directory '" + generic(plan.outParent) + "': " + ec.message());
    stdfs::remove_all(outRoot, ec);  // always a fresh <slug>-<platform> folder; the plan checked that an export wrote it
    stdfs::create_directories(outRoot, ec);
    if (ec) return err("export: cannot create '" + generic(outRoot) + "': " + ec.message());
    if (auto r = write_text(outRoot / kExportMarkerFile, marker_text(p, platform)); !r.ok()) return r.error();

    std::vector<std::string> files = collect_game_files(p, plan.outParent == p.dir ? outRoot : plan.outParent);

    Result<void> r;
    if (platform == "android" || platform == "ios") {
        report.mode = plan.mobile.prebuilt ? "prebuilt" : "source";
        r = platform == "android" ? export_android(options, p, plan.mobile, outRoot, files, report)
                                  : export_ios(options, p, plan.mobile, outRoot, files, plan.icon, report);
    } else {
        r = export_desktop(p, platform, plan.player, outRoot, files, plan.icon, report);
    }
    if (r.ok()) r = write_notices(p, platform, outRoot, report);
    if (!r.ok()) {
        stdfs::remove_all(outRoot, ec);
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
    report.files = list_files(outRoot);
    return report;
}

void register_export_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "project.export";
    info.category = "project";
    info.readOnly = false;
    info.summary = "Package the game for a platform: a desktop bundle, or an Android/iOS project.";
    info.description =
        "Validates the project (factoria.json, name, mainScene, reverse-DNS id) and writes a fresh "
        "<out>/<game-slug>-<platform>/ folder (deleted and recreated on every call, but only when it is empty or an "
        "export wrote it: every export leaves a .factoria-export file at its top, and any other existing folder of that "
        "name is an error that says how to proceed, never deleted; the project itself is not modified). "
        "linux/windows/macos: the game plus the factoria_player runtime found next to the running factoria binary, so "
        "exporting for another OS than this machine's fails with a hint. android: a complete Gradle project; ios: the game "
        "plus an Xcode/CMake project and build_ios.sh. Both have a mode, reported as `mode`: \"prebuilt\" (the engine is the "
        "ready-made player in the mobile/ folder next to the factoria binary of the FactorIA download: no engine source, "
        "and for Android no NDK or CMake) or \"source\" (the engine is compiled from a source checkout, chosen by "
        "$FACTORIA_ENGINE_DIR or when factoria runs from a development build); with no players and no checkout the error "
        "says what to do. Every export also writes FACTORIA_NOTICES.txt, the licenses of the engine code inside the game, "
        "where it ships with it (`notices`). Returns {outputDir, mode (android/ios), notices, files[], nextSteps[], "
        "warnings[]}; nextSteps lists what to "
        "do next (e.g. the Gradle build command). Nothing is built here (a macOS app is only sealed with an ad hoc "
        "signature). dryRun: true runs every check and writes nothing: it returns {platform, outputDir (the folder an "
        "export would replace), mode, player (desktop), warnings[]} or the error the export would give. Details: docs_read "
        "{\"name\":\"exporting\"}. Example: {\"platform\":\"windows\",\"release\":true}.";
    info.inputSchema = Json::parse(R"({
      "type":"object",
      "properties":{
        "platform":{"type":"string","description":"linux, windows, macos, android or ios (aliases win, mac, osx also work). Default: the machine running factoria."},
        "out":{"type":"string","description":"Parent folder of the export, relative to the project folder and inside it. Default: build/export."},
        "release":{"type":"boolean","description":"Release build: only changes the build commands in nextSteps (and the iOS script).","default":false},
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
