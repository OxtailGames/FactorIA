#include "fa/tooling/export.h"

#include <algorithm>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <regex>
#include <set>

#include "fa/core/json.h"
#include "fa/core/strings.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/notices.h"
#include "fa/tooling/project_fs.h"
#include "util.h"

#if defined(_WIN32)
#include <windows.h>
#elif defined(__APPLE__)
#include <mach-o/dyld.h>
#endif

namespace fa {
namespace stdfs = std::filesystem;
using tooling_detail::read_file;
using tooling_detail::slugify;
using tooling_detail::write_file;

namespace {

Error err(std::string message, std::string hint = {}) { return Error{std::move(message), std::move(hint)}; }

std::string host_platform() {
#if defined(_WIN32)
    return "windows";
#elif defined(__APPLE__)
    return "macos";
#else
    return "linux";
#endif
}

std::string replace_all(std::string text, const std::string& from, const std::string& to) {
    if (from.empty()) return text;
    std::size_t pos = 0;
    while ((pos = text.find(from, pos)) != std::string::npos) {
        text.replace(pos, from.size(), to);
        pos += to.size();
    }
    return text;
}

std::string xml_escape(const std::string& s, bool androidString = false) {
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

std::string generic(const stdfs::path& p) { return p.generic_string(); }

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

struct Project {
    stdfs::path dir;
    std::string name, id, version = "0.1.0", orientation = "landscape", feedbackFile = "ENGINE_FEEDBACK.json";
    std::string mainScene = "scenes/main.scene.json";
    std::vector<std::string> platforms;
    bool hasPlatformsField = false;
};

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

Result<void> write_text(const stdfs::path& path, const std::string& text, bool executable = false) {
    std::string e;
    if (!write_file(path, text, &e)) return err("export: " + e);
    if (executable) {
        std::error_code ec;
        stdfs::permissions(path, stdfs::perms::owner_exec | stdfs::perms::group_exec | stdfs::perms::others_exec,
                           stdfs::perm_options::add, ec);
    }
    return {};
}

std::vector<std::string> list_files(const stdfs::path& root) {
    std::vector<std::string> out;
    std::error_code ec;
    for (stdfs::recursive_directory_iterator it(root, ec), end; !ec && it != end; it.increment(ec))
        if (it->is_regular_file(ec)) out.push_back(generic(stdfs::relative(it->path(), root, ec)));
    std::sort(out.begin(), out.end());
    return out;
}

// ---- desktop ------------------------------------------------------------------------------------

Result<stdfs::path> find_player(const ExportOptions& o, const std::string& platform) {
    std::error_code ec;
    const std::string exe = platform == "windows" ? "factoria_player.exe" : "factoria_player";
    if (!o.playerBinary.empty()) {
        if (!stdfs::is_regular_file(o.playerBinary, ec))
            return err("export: player binary '" + o.playerBinary + "' not found",
                       "build it with `cmake --build <build dir> --target factoria_player`");
        return stdfs::path(o.playerBinary);
    }
    if (platform != host_platform())
        return err("export: cannot export for " + platform + " from a " + host_platform() +
                       " machine without a player binary built for " + platform,
                   "build factoria_player on " + platform + " (see docs/BUILDING.md) and pass it with --player <path>");
    stdfs::path dir = executable_dir();
    for (const stdfs::path& c : {dir / exe, dir.parent_path() / "player" / exe, dir.parent_path().parent_path() / "player" / exe})
        if (stdfs::is_regular_file(c, ec)) return c;
    return err("export: factoria_player not found next to the factoria binary (" + generic(dir) + ")",
               "build it with `cmake --build <build dir> --target factoria_player`, or pass --player <path>");
}

std::string macos_plist(const Project& p, const std::string& exeName) {
    return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
           "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
           "<plist version=\"1.0\">\n<dict>\n"
           "\t<key>CFBundleExecutable</key><string>" + xml_escape(exeName) + "</string>\n"
           "\t<key>CFBundleIdentifier</key><string>" + xml_escape(p.id.empty() ? "com.example.game" : p.id) + "</string>\n"
           "\t<key>CFBundleName</key><string>" + xml_escape(p.name) + "</string>\n"
           "\t<key>CFBundleDisplayName</key><string>" + xml_escape(p.name) + "</string>\n"
           "\t<key>CFBundlePackageType</key><string>APPL</string>\n"
           "\t<key>CFBundleShortVersionString</key><string>" + xml_escape(p.version) + "</string>\n"
           "\t<key>CFBundleVersion</key><string>" + xml_escape(p.version) + "</string>\n"
           "\t<key>LSMinimumSystemVersion</key><string>11.0</string>\n"
           "\t<key>NSHighResolutionCapable</key><true/>\n"
           "\t<key>LSApplicationCategoryType</key><string>public.app-category.games</string>\n"
           "</dict>\n</plist>\n";
}

std::string fs_safe_name(const std::string& s) {
    std::string o;
    for (char c : s) o += (std::strchr("/\\:*?\"<>|", c) || static_cast<unsigned char>(c) < 32) ? '_' : c;
    while (!o.empty() && (o.back() == ' ' || o.back() == '.')) o.pop_back();
    return o.empty() ? "Game" : o;
}

// Seals an exported .app with an ad hoc signature; returns "" or what went wrong. The executable inside is a copy of
// factoria_player, which a release download carries signed with FactorIA's Developer ID. That signature covers the
// executable alone, so the finished bundle (its Info.plist, the game files) would fail `codesign --verify` ("code has
// no resources but signature indicates they must be present"), and a Mac that downloads such an app calls it damaged
// instead of offering Open Anyway. Signed as a whole, ad hoc, the bundle is valid and runs on this Mac; to share the
// game, its developer signs it with their own Developer ID (nextSteps, docs/EXPORTING.md).
std::string sign_app_ad_hoc(const stdfs::path& app) {
#if defined(__APPLE__)
    const std::string cmd = "/usr/bin/codesign --force --sign - --timestamp=none " + sh_quote(app.string()) + " 2>&1";
    FILE* pipe = popen(cmd.c_str(), "r");
    if (!pipe) return "could not run /usr/bin/codesign";
    std::string out;
    char buf[512];
    while (std::fgets(buf, sizeof buf, pipe)) out += buf;
    const int status = pclose(pipe);
    if (status == 0) return {};
    while (!out.empty() && (out.back() == '\n' || out.back() == '\r')) out.pop_back();
    return out.empty() ? "codesign failed" : out;
#else
    (void)app;
    return "codesign runs only on macOS";
#endif
}

Result<void> export_desktop(const Project& p, const std::string& platform, const stdfs::path& player, const stdfs::path& outRoot,
                            const std::vector<std::string>& files, ExportReport& report) {
    const std::string slug = slugify(p.name, '-').empty() ? "game" : slugify(p.name, '-');
    const std::string exeName = slug + (platform == "windows" ? ".exe" : "");
    std::error_code ec;
    stdfs::path exeDest, gameDest;
    if (platform == "macos") {
        stdfs::path app = outRoot / (fs_safe_name(p.name) + ".app") / "Contents";
        exeDest = app / "MacOS" / exeName;
        gameDest = app / "Resources" / "game";
        if (auto r = write_text(app / "Info.plist", macos_plist(p, exeName)); !r.ok()) return r.error();
    } else {
        exeDest = outRoot / exeName;
        gameDest = outRoot / "game";
    }
    stdfs::create_directories(exeDest.parent_path(), ec);
    stdfs::copy_file(player, exeDest, stdfs::copy_options::overwrite_existing, ec);
    if (ec) return err("export: cannot copy the player to " + generic(exeDest) + ": " + ec.message());
    stdfs::permissions(exeDest, stdfs::perms::owner_exec | stdfs::perms::group_exec | stdfs::perms::others_exec,
                       stdfs::perm_options::add, ec);
    if (auto r = copy_game(p, files, gameDest); !r.ok()) return r;

    if (platform == "macos") {
        stdfs::path app = stdfs::path(fs_safe_name(p.name) + ".app");
        report.nextSteps = {
            "Run it: open '" + generic(outRoot / app) + "'",
            "To distribute outside your machine, sign and notarize the app: codesign --force --deep --options runtime "
            "--timestamp --sign \"Developer ID Application: <you>\" '" + app.string() + "', then xcrun notarytool "
            "submit and xcrun stapler staple (see docs/EXPORTING.md)",
            "Zip it for sharing: ditto -c -k --keepParent '" + app.string() + "' " + slug + "-macos.zip"};
    } else if (platform == "windows") {
        report.nextSteps = {"Run it: " + exeName + " (from " + generic(outRoot) + ")",
                            "Zip the folder '" + generic(outRoot.filename()) + "' to share it; keep game/ next to the exe"};
    } else {
        report.nextSteps = {"Run it: " + generic(outRoot / exeName),
                            "Archive to share: tar czf " + outRoot.filename().string() + ".tar.gz -C " +
                                generic(outRoot.parent_path()) + " " + outRoot.filename().string()};
    }
    return {};
}

// ---- mobile: prebuilt players or the engine source ------------------------------------------------
//
// Android and iOS exports run in one of two modes (ExportReport::mode, docs/EXPORTING.md has the rule):
//   prebuilt : the engine runtime is the ready-made player the FactorIA download carries in <factoria dir>/mobile/
//              (android/jniLibs/<abi>/libfactoria_player.so, ios/{iphoneos,iphonesimulator}/*.a); the project
//              templates come from this binary (platforms/ is embedded like docs/ and templates/).
//   source   : the engine is compiled from a source checkout, with that checkout's templates (engine developers).

constexpr const char* kAndroidAbis[] = {"arm64-v8a", "x86_64"};  // what the release workflow builds (= abiFilters in the template)
constexpr const char* kIosSlices[] = {"iphoneos", "iphonesimulator"};
constexpr const char* kIosMarkerLib = "libfactoria_player_main.a";  // the player's own archive, next to the engine ones

struct MobileSetup {
    bool prebuilt = false;
    stdfs::path engine;  // source: the engine checkout
    stdfs::path libs;    // prebuilt: <mobile dir>/<android|ios>
};

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

struct TemplateFile {
    std::string rel;  // path inside the template folder, forward slashes
    std::string data;
};

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

// ---- android -------------------------------------------------------------------------------------

std::string version_code(const std::string& v) {
    long parts[3] = {0, 0, 0};
    int idx = 0;
    std::size_t i = 0;
    while (idx < 3 && i < v.size() && std::isdigit(static_cast<unsigned char>(v[i]))) {
        long n = 0;
        while (i < v.size() && std::isdigit(static_cast<unsigned char>(v[i]))) n = std::min(n * 10 + (v[i++] - '0'), 99L);
        parts[idx++] = n;
        if (i < v.size() && v[i] == '.') ++i; else break;
    }
    long code = parts[0] * 10000 + parts[1] * 100 + parts[2];
    return std::to_string(code < 1 ? 1 : code);
}

std::string safe_version_name(const std::string& v) {
    std::string o;
    for (char c : v) if (std::isalnum(static_cast<unsigned char>(c)) || c == '.' || c == '-' || c == '_' || c == '+') o += c;
    return o.empty() ? "0.1.0" : o;
}

bool is_text_template(const stdfs::path& p) {
    std::string e = p.extension().string();
    return e == ".gradle" || e == ".properties" || e == ".xml" || e == ".kts" || e == ".txt" || e == ".md";
}

Result<void> export_android(const ExportOptions& o, const Project& p, const MobileSetup& setup, const stdfs::path& outRoot,
                            const std::vector<std::string>& files, ExportReport& report) {
    const std::string slug = slugify(p.name, '-').empty() ? "game" : slugify(p.name, '-');
    const std::string orient = p.orientation == "portrait" ? "sensorPortrait" : p.orientation == "any" ? "fullSensor" : "sensorLandscape";
    const std::vector<std::pair<std::string, std::string>> vars = {
        {"APPLICATION_ID", p.id},
        {"PROJECT_SLUG", slug},
        {"APP_NAME_XML", xml_escape(p.name, true)},
        {"VERSION_NAME", safe_version_name(p.version)},
        {"VERSION_CODE", version_code(p.version)},
        {"SCREEN_ORIENTATION", orient},
        {"ENGINE_ROOT", setup.prebuilt ? std::string() : generic(setup.engine)},
    };
    auto templates = load_templates(setup, "android");
    if (!templates.ok()) return templates.error();
    for (const TemplateFile& t : *templates) {
        const stdfs::path to = outRoot / t.rel;
        if (is_text_template(t.rel)) {
            auto text = select_sections(t.data, !setup.prebuilt, t.rel);
            if (!text.ok()) return text.error();
            for (auto& [k, v] : vars) *text = replace_all(*text, "{{" + k + "}}", v);
            if (text->find("{{") != std::string::npos)
                return err("export: unreplaced placeholder in template " + t.rel, "this is an engine bug; report it");
            if (auto r = write_text(to, *text); !r.ok()) return r;
        } else if (auto r = write_text(to, t.data); !r.ok()) {
            return r;
        }
    }
    std::error_code ec;
    if (setup.prebuilt)
        for (const char* abi : kAndroidAbis) {
            const stdfs::path to = outRoot / "app" / "src" / "main" / "jniLibs" / abi / "libfactoria_player.so";
            stdfs::create_directories(to.parent_path(), ec);
            stdfs::copy_file(setup.libs / "jniLibs" / abi / "libfactoria_player.so", to, stdfs::copy_options::overwrite_existing, ec);
            if (ec) return err(std::string("export: cannot copy the prebuilt ") + abi + " player to " + generic(to) + ": " + ec.message());
        }
    stdfs::path assets = outRoot / "app" / "src" / "main" / "assets";
    if (auto r = copy_game(p, files, assets); !r.ok()) return r;
    std::string index;
    for (auto& f : files) index += f + "\n";
    if (auto r = write_text(assets / "assets_index.txt", index); !r.ok()) return r;

    const std::string task = o.release ? "assembleRelease" : "assembleDebug";
    const std::string apk = o.release ? "app/build/outputs/apk/release/app-release-unsigned.apk" : "app/build/outputs/apk/debug/app-debug.apk";
    const std::string wrapper = "Create the Gradle wrapper once (needs Gradle 8.7+ installed; Android Studio does this itself): gradle wrapper --gradle-version 8.7";
    report.nextSteps = {
        setup.prebuilt ? "Install the prerequisites once: JDK 17 and the Android SDK (set ANDROID_SDK_ROOT) with platform 34: sdkmanager "
                         "\"platforms;android-34\" \"build-tools;34.0.0\". The engine is prebuilt (mode: prebuilt), so no NDK or CMake is needed"
                       : "Install the prerequisites once: JDK 17, the Android SDK (set ANDROID_SDK_ROOT) with NDK r27+, CMake 3.31.6 and "
                         "platform 34: sdkmanager \"ndk;27.2.12479018\" \"cmake;3.31.6\" \"platforms;android-34\" \"build-tools;34.0.0\" "
                         "(mode: source, the engine is compiled from its checkout)",
        "cd '" + generic(outRoot) + "'",
        wrapper,
        "./gradlew " + task +
            (setup.prebuilt ? "   (nothing is compiled but the Java glue, so it is quick; the APK is " : "   (first build compiles the whole engine; the APK is ") +
            apk + ")",
        "adb install -r " + apk +
            (setup.prebuilt ? "  (the engine is " + generic(setup.libs / "jniLibs") + " copied to app/src/main/jniLibs)"
                            : "  (the engine is located via factoria.engineDir in gradle.properties: " + generic(setup.engine) + ")"),
    };
    if (o.release) report.nextSteps.push_back("Release builds must be signed: see docs/MOBILE.md (Signing) for the keystore setup, or use ./gradlew bundleRelease for Google Play");
    return {};
}

// ---- ios -----------------------------------------------------------------------------------------

// Prebuilt mode: the CMake project (CMakeLists.txt + cmake/) and the engine archives (lib/<sdk>/*.a) of the app.
Result<void> write_ios_prebuilt_project(const MobileSetup& setup, const stdfs::path& outRoot) {
    static const std::pair<const char*, const char*> kFiles[] = {
        {"platforms/ios/prebuilt/CMakeLists.txt", "CMakeLists.txt"},
        {"platforms/ios/plist.cmake", "cmake/plist.cmake"},
        {"platforms/ios/Info.plist.in", "cmake/Info.plist.in"},
        {"platforms/common/copy_game.cmake", "cmake/copy_game.cmake"}};
    for (const auto& [from, to] : kFiles) {
        auto data = bundled_read(from);
        if (!data)
            return err(std::string("export: this factoria has no built-in iOS template ") + from, "this is an engine bug; report it");
        if (auto r = write_text(outRoot / to, *data); !r.ok()) return r;
    }
    std::error_code ec;
    for (const char* slice : kIosSlices) {
        stdfs::create_directories(outRoot / "lib" / slice, ec);
        for (stdfs::directory_iterator it(setup.libs / slice, ec), end; !ec && it != end; it.increment(ec)) {
            if (it->path().extension() != ".a") continue;
            std::error_code ec2;
            stdfs::copy_file(it->path(), outRoot / "lib" / slice / it->path().filename(), stdfs::copy_options::overwrite_existing, ec2);
            if (ec2) return err("export: cannot copy the prebuilt iOS library " + generic(it->path()) + ": " + ec2.message());
        }
    }
    return {};
}

Result<void> export_ios(const ExportOptions& o, const Project& p, const MobileSetup& setup, const stdfs::path& outRoot,
                        const std::vector<std::string>& files, ExportReport& report) {
    if (auto r = copy_game(p, files, outRoot / "game"); !r.ok()) return r;
    if (setup.prebuilt)
        if (auto r = write_ios_prebuilt_project(setup, outRoot); !r.ok()) return r;
    const std::string config = o.release ? "Release" : "Debug";
    std::string s;
    s += "#!/usr/bin/env bash\n";
    s += "# Generated by `factoria export --platform ios` for \"" + replace_all(p.name, "\n", " ") + "\" (mode: " + report.mode + ").\n";
    s += setup.prebuilt ? "# Configures the Xcode project (CMakeLists.txt) with the game in ./game bundled; the engine is linked from the prebuilt\n"
                    "# libraries in ./lib, so no engine source is needed.\n"
                  : "# Configures the Xcode project (same settings as the `ios` CMake preset) with the game in ./game bundled.\n";
    s += "#   ./build_ios.sh                    Xcode project for a device, then opens it\n";
    s += "#   ./build_ios.sh --simulator        same for the iOS Simulator\n";
    s += "#   ./build_ios.sh --build            also compile (" + config + "). A device build needs FA_IOS_DEVELOPMENT_TEAM and\n";
    s += "#                                     the iPhone/iPad connected (FA_IOS_DEVICE=<udid> picks one): the first build\n";
    s += "#                                     for a team registers it there. Simulator builds are not signed.\n";
    s += "#   ./build_ios.sh [--simulator] --run   build, install and start the game, its console in this terminal\n";
    s += "#   ./build_ios.sh --build -- <args>  everything after -- goes to xcodebuild\n";
    s += "# Needs macOS, Xcode (full app), CMake 3.24+.\n";
    s += "set -euo pipefail\n";
    s += "HERE=\"$(cd \"$(dirname \"${BASH_SOURCE[0]}\")\" && pwd)\"\n";
    if (!setup.prebuilt) s += "ENGINE_DIR=\"${FACTORIA_ENGINE_DIR:-" + generic(setup.engine) + "}\"\n";
    s += "SYSROOT=iphoneos\nBUILD=0\nRUN=0\nXCODE_ARGS=()\n";
    s += "while [ $# -gt 0 ]; do\n  case \"$1\" in\n    --simulator) SYSROOT=iphonesimulator ;;\n    --build) BUILD=1 ;;\n"
         "    --run) BUILD=1; RUN=1 ;;\n"
         "    --) shift; XCODE_ARGS=(\"$@\"); break ;;\n"
         "    *) echo \"unknown option: $1 (options: --simulator, --build, --run, -- <xcodebuild arguments>)\" >&2; exit 2 ;;\n"
         "  esac\n  shift\ndone\n";
    if (!setup.prebuilt)
        s += "[ -f \"$ENGINE_DIR/CMakeLists.txt\" ] || { echo \"engine not found at $ENGINE_DIR: set FACTORIA_ENGINE_DIR\" >&2; exit 1; }\n";
    s += std::string("cmake -S ") + (setup.prebuilt ? "\"$HERE\"" : "\"$ENGINE_DIR\"") + " -B \"$HERE/build\" -G Xcode \\\n"
         "  -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_DEPLOYMENT_TARGET=16.3 -DCMAKE_OSX_SYSROOT=\"$SYSROOT\" \\\n" +
         (setup.prebuilt ? "" : "  -DFA_BUILD_TOOLS=OFF -DFA_BUILD_TESTS=OFF \\\n") +
         "  -DFA_GAME_PROJECT_DIR=\"$HERE/game\" \\\n"
         "  -DFA_GAME_BUNDLE_ID=" + sh_quote(p.id) + " \\\n"
         "  -DFA_GAME_NAME=" + sh_quote(p.name) + " \\\n"
         "  -DFA_GAME_VERSION=" + sh_quote(safe_version_name(p.version)) + " \\\n"
         "  -DFA_GAME_ORIENTATION=" + sh_quote(p.orientation) + " \\\n"
         "  -DFA_IOS_DEVELOPMENT_TEAM=\"${FA_IOS_DEVELOPMENT_TEAM:-}\"\n";
    std::string build = R"SH(if [ "$BUILD" = 0 ]; then
  echo "Open $HERE/build/FactorIA.xcodeproj, pick the 'factoria_player' scheme, set Signing & Capabilities > Team, press Run."
  open "$HERE/build/FactorIA.xcodeproj" 2>/dev/null || true
  exit 0
fi
CONFIG=@CONFIG@
BUNDLE_ID=@BUNDLE_ID@
# The connected iPhone or iPad (FA_IOS_DEVICE=<udid> picks one).
device_udid() {
  if [ -n "${FA_IOS_DEVICE:-}" ]; then echo "$FA_IOS_DEVICE"; return; fi
  local list; list="$(mktemp)"
  if xcrun devicectl list devices --json-output "$list" >/dev/null 2>&1; then
    python3 -c 'import json, sys
for d in json.load(open(sys.argv[1]))["result"]["devices"]:
    hw, conn = d.get("hardwareProperties", {}), d.get("connectionProperties", {})
    if hw.get("reality") == "physical" and hw.get("platform") == "iOS" and conn.get("tunnelState") == "connected":
        print(hw["udid"]); break' "$list"
  fi
  rm -f "$list"
}
# A booted simulator, else the first iPhone of the newest iOS runtime.
simulator_udid() {
  xcrun simctl list devices available -j | python3 -c 'import json, sys
data = json.load(sys.stdin)["devices"]
def version(key): return [int(p) for p in key.rsplit(".", 1)[-1].split("-")[1:] if p.isdigit()]
runtimes = sorted((k for k in data if ".iOS-" in k), key=version, reverse=True)
devices = [d for k in runtimes for d in data[k] if d.get("isAvailable", True)]
pick = [d for d in devices if d["state"] == "Booted"] or [d for d in devices if d["name"].startswith("iPhone")]
print(pick[0]["udid"] if pick else "")'
}
if [ "$SYSROOT" = iphonesimulator ]; then
  # Simulator apps need no team: build unsigned, then sign ad hoc as Xcode does for the simulator.
  cmake --build "$HERE/build" --config "$CONFIG" --target factoria_player -- -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO \
    ${XCODE_ARGS[@]+"${XCODE_ARGS[@]}"}
else
  # A scheme build with a destination (not cmake --build, which builds a target and ignores the destination), so that
  # Xcode can register the connected device with the team and create the provisioning profile on the first build.
  DEVICE="$(device_udid)"
  if [ -n "$DEVICE" ]; then
    DESTINATION="id=$DEVICE"
  else
    DESTINATION="generic/platform=iOS"
    echo "note: no iPhone or iPad connected: building for any device. A team's first build needs the device connected," >&2
    echo "      unlocked and in Developer Mode (Settings > Privacy & Security), so Xcode can register it." >&2
  fi
  xcodebuild -project "$HERE/build/FactorIA.xcodeproj" -scheme factoria_player -configuration "$CONFIG" \
    -destination "$DESTINATION" -allowProvisioningUpdates -allowProvisioningDeviceRegistration build \
    ${XCODE_ARGS[@]+"${XCODE_ARGS[@]}"}
fi
APP="$(find "$HERE/build" -maxdepth 4 -type d -path "*/$CONFIG-$SYSROOT/factoria_player.app" | head -n 1)"
[ -n "$APP" ] || { echo "error: the build left no factoria_player.app for $SYSROOT under $HERE/build" >&2; exit 1; }
echo "Built $APP"
[ "$RUN" = 1 ] || exit 0
if [ "$SYSROOT" = iphonesimulator ]; then
  codesign --force --sign - --timestamp=none "$APP"
  SIM="$(simulator_udid)"
  [ -n "$SIM" ] || { echo "error: no iOS simulator; add one in Xcode (Settings > Components)" >&2; exit 1; }
  xcrun simctl boot "$SIM" 2>/dev/null || true
  open -a Simulator 2>/dev/null || true
  xcrun simctl bootstatus "$SIM" -b >/dev/null
  xcrun simctl install "$SIM" "$APP"
  echo "Starting $BUNDLE_ID in the simulator; its console follows (Ctrl+C ends the game)."
  exec xcrun simctl launch --terminate-running-process --console-pty "$SIM" "$BUNDLE_ID"
fi
[ -n "$DEVICE" ] || { echo "error: connect an iPhone or iPad (unlocked, Developer Mode on) to run the game on it" >&2; exit 1; }
xcrun devicectl device install app --device "$DEVICE" "$APP"
echo "Starting $BUNDLE_ID on the device; its console follows (Ctrl+C ends the game)."
exec xcrun devicectl device process launch --console --terminate-existing --device "$DEVICE" "$BUNDLE_ID"
)SH";
    build = replace_all(build, "@CONFIG@", config);
    build = replace_all(build, "@BUNDLE_ID@", sh_quote(p.id));
    s += build;
    if (auto r = write_text(outRoot / "build_ios.sh", s, true); !r.ok()) return r;
    report.nextSteps = {
        "On a Mac with Xcode and CMake 3.24+, copy or open this folder: cd '" + generic(outRoot) + "'",
        "./build_ios.sh --simulator --run   builds the game, starts it in the iOS Simulator and shows its console",
        "On an iPhone/iPad (connected, unlocked, Developer Mode on): FA_IOS_DEVELOPMENT_TEAM=<TEAMID> ./build_ios.sh --run. "
            "Or ./build_ios.sh creates build/FactorIA.xcodeproj and opens it: select the 'factoria_player' scheme, set a "
            "Team under Signing & Capabilities (bundle id " + p.id + "), then Run",
        std::string(setup.prebuilt ? "Mode prebuilt: the engine is linked from lib/, copied from " + generic(setup.libs) + " (no engine source needed). "
                                   : "Mode source: the engine is compiled from " + generic(setup.engine) + ". ") +
            "Details and App Store notes: docs/MOBILE.md"};
    return {};
}

// ---- license notices -----------------------------------------------------------------------------

// The runtime inside the game is FactorIA (MIT) plus third-party code whose licenses ask for their notices in every
// copy: FACTORIA_NOTICES.txt goes where it ships with the game (next to the executable, or inside the app bundle/APK).
Result<void> write_notices(const Project& p, const std::string& platform, const stdfs::path& outRoot, ExportReport& report) {
    stdfs::path dir = outRoot;
    if (platform == "macos") dir = outRoot / (fs_safe_name(p.name) + ".app") / "Contents" / "Resources";
    else if (platform == "android") dir = outRoot / "app" / "src" / "main" / "assets";
    else if (platform == "ios") dir = outRoot / "game";
    if (auto r = write_text(dir / kExportNoticesFile, third_party_notices(NoticeScope::Game)); !r.ok()) return r;
    report.notices = generic((dir.lexically_relative(outRoot) / kExportNoticesFile).lexically_normal());
    report.nextSteps.push_back(report.notices + " holds the licenses of the FactorIA runtime inside the game: keep it in "
                               "what you distribute (docs/EXPORTING.md, \"License notices\")");
    return {};
}

// ---- plan: every check, before anything is written ------------------------------------------------

struct Plan {
    std::string platform;
    Project project;
    stdfs::path outParent, outRoot;  // absolute; outRoot = outParent/<slug>-<platform>, replaced by the export
    stdfs::path player;              // desktop
    MobileSetup mobile;              // android/ios
    std::vector<std::string> warnings;
};

Result<Plan> make_plan(const ExportOptions& options) {
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

    if (plan.platform == "android" || plan.platform == "ios") {
        auto setup = resolve_mobile(options, plan.platform);
        if (!setup.ok()) return setup.error();
        plan.mobile = std::move(setup.value());
    } else {
        auto player = find_player(options, plan.platform);
        if (!player.ok()) return player.error();
        plan.player = std::move(player.value());
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
    auto planned = make_plan(options);  // every check first: a failed one leaves the previous export in place
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
    stdfs::remove_all(outRoot, ec);  // always a fresh <slug>-<platform> folder
    stdfs::create_directories(outRoot, ec);
    if (ec) return err("export: cannot create '" + generic(outRoot) + "': " + ec.message());

    std::vector<std::string> files = collect_game_files(p, plan.outParent == p.dir ? outRoot : plan.outParent);

    Result<void> r;
    if (platform == "android" || platform == "ios") {
        report.mode = plan.mobile.prebuilt ? "prebuilt" : "source";
        r = platform == "android" ? export_android(options, p, plan.mobile, outRoot, files, report)
                                  : export_ios(options, p, plan.mobile, outRoot, files, report);
    } else {
        r = export_desktop(p, platform, plan.player, outRoot, files, report);
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
        "<out>/<game-slug>-<platform>/ folder (deleted and recreated on every call; the project itself is not modified). "
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
        // Inside the project only, like fs.*: the export folder is deleted and rewritten on every call.
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
