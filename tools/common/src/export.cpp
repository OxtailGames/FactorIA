#include "fa/tooling/export.h"

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <regex>
#include <set>

#include "fa/core/json.h"
#include "fa/core/strings.h"
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

Result<void> export_desktop(const ExportOptions& o, const Project& p, const std::string& platform, const stdfs::path& outRoot,
                            const std::vector<std::string>& files, ExportReport& report) {
    auto player = find_player(o, platform);
    if (!player.ok()) return player.error();
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
    stdfs::copy_file(*player, exeDest, stdfs::copy_options::overwrite_existing, ec);
    if (ec) return err("export: cannot copy the player to " + generic(exeDest) + ": " + ec.message());
    stdfs::permissions(exeDest, stdfs::perms::owner_exec | stdfs::perms::group_exec | stdfs::perms::others_exec,
                       stdfs::perm_options::add, ec);
    if (auto r = copy_game(p, files, gameDest); !r.ok()) return r;

    if (platform == "macos") {
        stdfs::path app = stdfs::path(fs_safe_name(p.name) + ".app");
        report.nextSteps = {
            "Run it: open '" + generic(outRoot / app) + "'",
            "To distribute outside your machine, sign and notarize the app: codesign --deep --options runtime --sign "
            "\"Developer ID Application: <you>\" '" + app.string() + "' (see docs/EXPORTING.md)",
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

// ---- engine root --------------------------------------------------------------------------------

Result<stdfs::path> find_engine_root(const ExportOptions& o, const char* need) {
    std::string root = o.engineRoot;
    if (root.empty()) {
        if (const char* env = std::getenv("FACTORIA_ENGINE_DIR")) root = env;
    }
    if (root.empty()) root = FA_SOURCE_ROOT;
    std::error_code ec;
    stdfs::path r = stdfs::weakly_canonical(root, ec);
    if (!stdfs::exists(r / "CMakeLists.txt", ec) || !stdfs::exists(r / need, ec))
        return err("export: engine checkout not found at '" + generic(r) + "' (missing " + need + ")",
                   "mobile exports compile the engine from source: set FACTORIA_ENGINE_DIR to the FactorIA "
                   "repository folder");
    return r;
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

Result<void> export_android(const ExportOptions& o, const Project& p, const stdfs::path& outRoot,
                            const std::vector<std::string>& files, ExportReport& report) {
    auto engine = find_engine_root(o, "platforms/android/settings.gradle");
    if (!engine.ok()) return engine.error();
    const std::string slug = slugify(p.name, '-').empty() ? "game" : slugify(p.name, '-');
    const std::string orient = p.orientation == "portrait" ? "sensorPortrait" : p.orientation == "any" ? "fullSensor" : "sensorLandscape";
    const std::vector<std::pair<std::string, std::string>> vars = {
        {"APPLICATION_ID", p.id},
        {"PROJECT_SLUG", slug},
        {"APP_NAME_XML", xml_escape(p.name, true)},
        {"VERSION_NAME", safe_version_name(p.version)},
        {"VERSION_CODE", version_code(p.version)},
        {"SCREEN_ORIENTATION", orient},
        {"ENGINE_ROOT", generic(*engine)},
    };
    stdfs::path tpl = *engine / "platforms" / "android";
    std::error_code ec;
    for (stdfs::recursive_directory_iterator it(tpl, ec), end; !ec && it != end; it.increment(ec)) {
        if (!it->is_regular_file(ec)) continue;
        stdfs::path rel = stdfs::relative(it->path(), tpl, ec);
        stdfs::path to = outRoot / rel;
        if (is_text_template(rel)) {
            auto text = read_file(it->path());
            if (!text) return err("export: cannot read template " + generic(it->path()));
            for (auto& [k, v] : vars) *text = replace_all(*text, "{{" + k + "}}", v);
            if (text->find("{{") != std::string::npos)
                return err("export: unreplaced placeholder in template " + generic(it->path()), "this is an engine bug; report it");
            if (auto r = write_text(to, *text); !r.ok()) return r;
        } else {
            stdfs::create_directories(to.parent_path(), ec);
            stdfs::copy_file(it->path(), to, stdfs::copy_options::overwrite_existing, ec);
            if (ec) return err("export: cannot copy template file " + generic(rel) + ": " + ec.message());
        }
    }
    stdfs::path assets = outRoot / "app" / "src" / "main" / "assets";
    if (auto r = copy_game(p, files, assets); !r.ok()) return r;
    std::string index;
    for (auto& f : files) index += f + "\n";
    if (auto r = write_text(assets / "assets_index.txt", index); !r.ok()) return r;

    const std::string task = o.release ? "assembleRelease" : "assembleDebug";
    const std::string apk = o.release ? "app/build/outputs/apk/release/app-release-unsigned.apk" : "app/build/outputs/apk/debug/app-debug.apk";
    report.nextSteps = {
        "Install the prerequisites once: JDK 17, the Android SDK (set ANDROID_SDK_ROOT) with NDK r27+, CMake 3.31.6 and "
        "platform 34: sdkmanager \"ndk;27.2.12479018\" \"cmake;3.31.6\" \"platforms;android-34\" \"build-tools;34.0.0\"",
        "cd '" + generic(outRoot) + "'",
        "Create the Gradle wrapper once (needs Gradle 8.7+ installed; Android Studio does this itself): gradle wrapper --gradle-version 8.7",
        "./gradlew " + task + "   (first build compiles the whole engine; the APK is " + apk + ")",
        "adb install -r " + apk + "  (the engine is located via factoria.engineDir in gradle.properties: " + generic(*engine) + ")",
    };
    if (o.release) report.nextSteps.push_back("Release builds must be signed: see docs/MOBILE.md (Signing) for the keystore setup, or use ./gradlew bundleRelease for Google Play");
    return {};
}

// ---- ios -----------------------------------------------------------------------------------------

Result<void> export_ios(const ExportOptions& o, const Project& p, const stdfs::path& outRoot,
                        const std::vector<std::string>& files, ExportReport& report) {
    auto engine = find_engine_root(o, "platforms/ios/Info.plist.in");
    if (!engine.ok()) return engine.error();
    if (auto r = copy_game(p, files, outRoot / "game"); !r.ok()) return r;
    const std::string config = o.release ? "Release" : "Debug";
    std::string s;
    s += "#!/usr/bin/env bash\n";
    s += "# Generated by `factoria export --platform ios` for \"" + replace_all(p.name, "\n", " ") + "\".\n";
    s += "# Configures the Xcode project (same settings as the `ios` CMake preset) with the game in ./game bundled.\n";
    s += "#   ./build_ios.sh              Xcode project for a device, then opens it\n";
    s += "#   ./build_ios.sh --simulator  same for the iOS Simulator\n";
    s += "#   ./build_ios.sh --build      also compile (" + config + ", set FA_IOS_DEVELOPMENT_TEAM for device signing)\n";
    s += "# Needs macOS, Xcode (full app), CMake 3.24+.\n";
    s += "set -euo pipefail\n";
    s += "HERE=\"$(cd \"$(dirname \"${BASH_SOURCE[0]}\")\" && pwd)\"\n";
    s += "ENGINE_DIR=\"${FACTORIA_ENGINE_DIR:-" + generic(*engine) + "}\"\n";
    s += "SYSROOT=iphoneos\nBUILD=0\n";
    s += "for arg in \"$@\"; do\n  case \"$arg\" in\n    --simulator) SYSROOT=iphonesimulator ;;\n    --build) BUILD=1 ;;\n"
         "    *) echo \"unknown option: $arg\" >&2; exit 2 ;;\n  esac\ndone\n";
    s += "[ -f \"$ENGINE_DIR/CMakeLists.txt\" ] || { echo \"engine not found at $ENGINE_DIR: set FACTORIA_ENGINE_DIR\" >&2; exit 1; }\n";
    s += "cmake -S \"$ENGINE_DIR\" -B \"$HERE/build\" -G Xcode \\\n"
         "  -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_DEPLOYMENT_TARGET=16.3 -DCMAKE_OSX_SYSROOT=\"$SYSROOT\" \\\n"
         "  -DFA_BUILD_TOOLS=OFF -DFA_BUILD_TESTS=OFF \\\n"
         "  -DFA_GAME_PROJECT_DIR=\"$HERE/game\" \\\n"
         "  -DFA_GAME_BUNDLE_ID=" + sh_quote(p.id) + " \\\n"
         "  -DFA_GAME_NAME=" + sh_quote(p.name) + " \\\n"
         "  -DFA_GAME_VERSION=" + sh_quote(safe_version_name(p.version)) + " \\\n"
         "  -DFA_GAME_ORIENTATION=" + sh_quote(p.orientation) + " \\\n"
         "  -DFA_IOS_DEVELOPMENT_TEAM=\"${FA_IOS_DEVELOPMENT_TEAM:-}\"\n";
    s += "if [ \"$BUILD\" = 1 ]; then\n  cmake --build \"$HERE/build\" --config " + config + " --target factoria_player -- -allowProvisioningUpdates\n"
         "else\n  echo \"Open $HERE/build/FactorIA.xcodeproj, pick the 'factoria_player' scheme, set Signing & Capabilities > Team, press Run.\"\n"
         "  open \"$HERE/build/FactorIA.xcodeproj\" 2>/dev/null || true\nfi\n";
    if (auto r = write_text(outRoot / "build_ios.sh", s, true); !r.ok()) return r;
    report.nextSteps = {
        "On a Mac with Xcode and CMake 3.24+, copy or open this folder: cd '" + generic(outRoot) + "'",
        "./build_ios.sh --simulator   (or ./build_ios.sh for a device) creates build/FactorIA.xcodeproj and opens it",
        "In Xcode: select the 'factoria_player' scheme, set a Team under Signing & Capabilities (bundle id " + p.id +
            "), then Run. Or: FA_IOS_DEVELOPMENT_TEAM=<TEAMID> ./build_ios.sh --build",
        "Details and App Store notes: docs/MOBILE.md"};
    return {};
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
    j["files"] = files;
    j["nextSteps"] = nextSteps;
    j["warnings"] = warnings;
    return j;
}

Result<ExportReport> export_project(const ExportOptions& options) {
    const std::string platform = normalize_export_platform(options.platform);
    if (platform.empty())
        return err("export: unknown platform '" + options.platform + "'", "use one of: linux, windows, macos, android, ios");
    ExportReport report;
    auto project = load_and_validate(options, platform, report.warnings);
    if (!project.ok()) return project.error();
    const Project& p = project.value();

    std::error_code ec;
    stdfs::path outParent = options.outDir.empty() ? p.dir / "build" / "export" : stdfs::path(options.outDir);
    stdfs::create_directories(outParent, ec);
    if (ec) return err("export: cannot create output directory '" + outParent.string() + "': " + ec.message());
    outParent = stdfs::weakly_canonical(outParent, ec);

    const std::string slug = slugify(p.name, '-').empty() ? "game" : slugify(p.name, '-');
    stdfs::path outRoot = outParent / (slug + "-" + platform);
    if (is_inside(p.dir, outRoot) || outRoot == p.dir)
        return err("export: output folder '" + generic(outRoot) + "' would contain the project", "choose another --out folder");
    stdfs::remove_all(outRoot, ec);  // always a fresh <slug>-<platform> folder
    stdfs::create_directories(outRoot, ec);
    if (ec) return err("export: cannot create '" + generic(outRoot) + "': " + ec.message());

    std::vector<std::string> files = collect_game_files(p, outParent == p.dir ? outRoot : outParent);

    Result<void> r;
    if (platform == "android") r = export_android(options, p, outRoot, files, report);
    else if (platform == "ios") r = export_ios(options, p, outRoot, files, report);
    else r = export_desktop(options, p, platform, outRoot, files, report);
    if (!r.ok()) {
        stdfs::remove_all(outRoot, ec);
        return r.error();
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
        "exporting for another OS than this machine's fails with a hint. android: a complete Gradle project (needs the "
        "engine source checkout, $FACTORIA_ENGINE_DIR). ios: the game plus build_ios.sh. Returns {outputDir, files[], "
        "nextSteps[], warnings[]}; nextSteps lists what to do next (e.g. the Gradle build command). Nothing is built or "
        "signed here. Details: docs_read {\"name\":\"exporting\"}. Example: {\"platform\":\"windows\",\"release\":true}.";
    info.inputSchema = Json::parse(R"({
      "type":"object",
      "properties":{
        "platform":{"type":"string","description":"linux, windows, macos, android or ios (aliases win, mac, osx also work). Default: the machine running factoria."},
        "out":{"type":"string","description":"Parent folder of the export, relative to the project folder and inside it. Default: build/export."},
        "release":{"type":"boolean","description":"Release build: only changes the build commands in nextSteps (and the iOS script).","default":false}
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
        auto r = export_project(o);
        if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
        return r->to_json();
    });
}

}  // namespace fa
