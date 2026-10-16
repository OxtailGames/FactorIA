#include <doctest.h>

#include <algorithm>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <optional>

#if !defined(_WIN32)
#include <sys/wait.h>
#endif

#include "fa/core/fs.h"
#include "fa/tooling/export.h"
#include "fa/tooling/scaffold.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

bool has(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }

// The warnings of a report without the one every project without an icon gets.
std::vector<std::string> warnings_without_icon_note(const std::vector<std::string>& warnings) {
    std::vector<std::string> out;
    for (const auto& w : warnings)
        if (w.find("No icon is set") == std::string::npos) out.push_back(w);
    return out;
}

// Fake "player" so layout tests do not depend on a built factoria_player.
std::string make_fake_player(const testing::TempDir& tmp) {
    std::string p = tmp.sub("fake_player/factoria_player");
    testing::write_all(p, "#!/bin/sh\nexit 0\n");
    return p;
}

std::string make_project(const testing::TempDir& tmp, const std::string& name = "Space Dodge", const std::string& tpl = "2d-platformer") {
    std::string dir = tmp.sub("proj");
    ScaffoldOptions so;
    so.name = name;
    so.id = "com.example.spacedodge";
    auto r = create_project(dir, tpl, so);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    testing::write_all(stdfs::path(dir) / "assets" / "sprites" / "hero.png", "png");
    testing::write_all(stdfs::path(dir) / ".factoria" / "cache.bin", "x");
    return dir;
}

// Sets (or, with nullptr, clears) an environment variable for the life of the object.
struct ScopedEnv {
    std::string name;
    std::optional<std::string> old;
    ScopedEnv(const char* n, const char* value) : name(n) {
        if (const char* cur = std::getenv(n)) old = cur;
        set(value);
    }
    ~ScopedEnv() { set(old ? old->c_str() : nullptr); }
    void set(const char* value) const {
#if defined(_WIN32)
        _putenv_s(name.c_str(), value ? value : "");  // an empty value removes the variable
#else
        if (value) setenv(name.c_str(), value, 1);
        else unsetenv(name.c_str());
#endif
    }
};

// A fake FactorIA download: <tmp>/<dir>/{android/jniLibs/<abi>/libfactoria_player.so, ios/<sdk>/*.a}. Returns its path.
std::string make_fake_mobile(const testing::TempDir& tmp, const std::string& dir = "download/mobile",
                             std::vector<std::string> abis = {"arm64-v8a", "x86_64"},
                             std::vector<std::string> slices = {"iphoneos", "iphonesimulator"}) {
    const stdfs::path root = stdfs::path(tmp.sub(dir));
    for (const auto& abi : abis) testing::write_all(root / "android" / "jniLibs" / abi / "libfactoria_player.so", "fake " + abi);
    for (const auto& sdk : slices) {
        testing::write_all(root / "ios" / sdk / "libfactoria_player_main.a", "fake player " + sdk);
        testing::write_all(root / "ios" / sdk / "libfa_core.a", "fake core " + sdk);
    }
    return root.string();
}

// The fake download placed where factoria looks by default: next to the running executable. Removed again afterwards;
// `active` is false (and nothing is touched) when a mobile/ folder is already there.
struct MobileNextToExe {
    stdfs::path dir = executable_dir() / "mobile";
    bool active = false;
    MobileNextToExe() {
        std::error_code ec;
        if (stdfs::exists(dir, ec)) return;
        active = true;
        for (const char* abi : {"arm64-v8a", "x86_64"}) testing::write_all(dir / "android" / "jniLibs" / abi / "libfactoria_player.so", abi);
    }
    ~MobileNextToExe() {
        std::error_code ec;
        if (active) stdfs::remove_all(dir, ec);
    }
};

}  // namespace

// The build command the next steps of an Android export name: the wrapper script of this OS.
#if defined(_WIN32)
constexpr const char* kGradlewAssemble = "gradlew.bat assembleDebug";
#else
constexpr const char* kGradlewAssemble = "./gradlew assembleDebug";
#endif

TEST_CASE("export: platform names are normalized") {
    CHECK(normalize_export_platform("Win") == "windows");
    CHECK(normalize_export_platform("OSX") == "macos");
    CHECK(normalize_export_platform("android") == "android");
    CHECK(normalize_export_platform("amiga").empty());
}

TEST_CASE("export: format and artifact are serialized only when set") {
    ExportReport report;
    CHECK_FALSE(report.to_json().contains("format"));
    CHECK_FALSE(report.to_json().contains("artifact"));
    report.format = "apk";
    report.artifact = "/out/game-android/game.apk";
    CHECK(report.to_json()["format"] == "apk");
    CHECK(report.to_json()["artifact"] == "/out/game-android/game.apk");

    ExportPlan plan;
    CHECK_FALSE(plan.to_json().contains("format"));
    CHECK_FALSE(plan.to_json().contains("artifact"));
    plan.format = "aab";
    plan.artifact = "/out/game-android/game.aab";
    CHECK(plan.to_json()["format"] == "aab");
    CHECK(plan.to_json()["artifact"] == "/out/game-android/game.aab");

    ExportOptions options;  // the options have defaults that mean "the project's setting"
    CHECK(options.format.empty());
    CHECK_FALSE(options.progress);
}

TEST_CASE("export: desktop layout (linux, windows, macos)") {
    testing::TempDir tmp;
    std::string proj = make_project(tmp);
    std::string player = make_fake_player(tmp);

    for (const char* platform : {"linux", "windows", "macos"}) {
        CAPTURE(platform);
        ExportOptions o;
        o.projectDir = proj;
        o.platform = platform;
        o.outDir = tmp.sub("out");
        o.playerBinary = player;
        auto r = export_project(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        const auto& rep = r.value();
        std::string root = tmp.sub("out/space-dodge-") + platform;
        // Compare canonical paths: macOS temp dirs are symlinked (/var -> /private/var).
        CHECK(stdfs::weakly_canonical(rep.outputDir) == stdfs::weakly_canonical(root));
        std::string game = root + "/game";
        std::string exe = root + "/space-dodge" + (std::string(platform) == "windows" ? ".exe" : "");
        std::string notices = "FACTORIA_NOTICES.txt";
        if (std::string(platform) == "macos") {
            game = root + "/Space Dodge.app/Contents/Resources/game";
            exe = root + "/Space Dodge.app/Contents/MacOS/space-dodge";
            notices = "Space Dodge.app/Contents/Resources/FACTORIA_NOTICES.txt";
            CHECK(testing::read_all(root + "/Space Dodge.app/Contents/Info.plist").find("com.example.spacedodge") != std::string::npos);
#if !defined(__APPLE__)
            // codesign runs only on macOS: the report says how to seal the bundle on a Mac (macOS: next test case).
            bool warned = false;
            for (const auto& w : rep.warnings) warned = warned || w.find("codesign --force --sign -") != std::string::npos;
            CHECK(warned);
#endif
        }
        CHECK(stdfs::exists(exe));
        CHECK(stdfs::exists(game + "/factoria.json"));
        CHECK(stdfs::exists(game + "/scenes/main.scene.json"));
        CHECK(stdfs::exists(game + "/assets/sprites/hero.png"));
        CHECK_FALSE(stdfs::exists(game + "/.factoria"));
        CHECK_FALSE(stdfs::exists(game + "/tests"));
        CHECK_FALSE(stdfs::exists(game + "/tools"));
        CHECK_FALSE(stdfs::exists(game + "/ENGINE_FEEDBACK.json"));
        CHECK_FALSE(stdfs::exists(game + "/AGENTS.md"));
        CHECK_FALSE(rep.nextSteps.empty());
        CHECK(rep.to_json()["files"].is_array());
        // The licenses of the runtime ship with the game, next to the executable (inside the bundle on macOS).
        CHECK(rep.notices == notices);
        CHECK(rep.to_json()["notices"] == notices);
        CHECK(testing::read_all(root + "/" + notices).find("Permission is hereby granted") != std::string::npos);
        CHECK_FALSE(stdfs::exists(game + "/FACTORIA_NOTICES.txt"));
    }
    // The project itself is untouched.
    CHECK(stdfs::exists(stdfs::path(proj) / "ENGINE_FEEDBACK.json"));
}

// A macOS app nests four folders, so on Windows its files easily pass MAX_PATH (260 characters): the export reaches them
// through fs::os_path whether or not long paths are enabled on the machine.
TEST_CASE("export: an output folder deeper than Windows' MAX_PATH works") {
    testing::TempDir tmp;
    const std::string proj = make_project(tmp);
    const stdfs::path deep = stdfs::path(tmp.sub("out")) / std::string(90, 'a') / std::string(90, 'b');
    ExportOptions o;
    o.projectDir = proj;
    o.platform = "macos";
    o.outDir = deep.string();
    o.playerBinary = make_fake_player(tmp);
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    const stdfs::path scene = stdfs::path(r->outputDir) / "Space Dodge.app/Contents/Resources/game/scenes/main.scene.json";
    CHECK(scene.string().size() > 260);
    std::error_code ec;
    CHECK(stdfs::is_regular_file(fs::os_path(scene), ec));
    CHECK(std::find(r->files.begin(), r->files.end(), "Space Dodge.app/Contents/Resources/game/scenes/main.scene.json") != r->files.end());
    // Exporting again replaces the folder (the marker is found and the old tree removed, all past the limit).
    auto again = export_project(o);
    REQUIRE_MESSAGE(again.ok(), (again.ok() ? "" : again.error().to_string()));
    CHECK(again->files == r->files);
    stdfs::remove_all(fs::os_path(deep), ec);  // TempDir's own remove_all would stop at the long paths on Windows
}

#if defined(__APPLE__)
TEST_CASE("export: the macOS app is signed as a whole, so codesign --verify accepts it") {
    // A real executable signed on its own, as factoria_player is in a signed release download. Copied into the bundle
    // unchanged, its signature does not cover the Info.plist and the game files: `codesign --verify` rejects the app
    // ("code has no resources but signature indicates they must be present") and a Mac that downloads it calls it damaged.
    testing::TempDir tmp;
    std::string proj = make_project(tmp);
    std::string player = tmp.sub("signed_player/factoria_player");
    stdfs::create_directories(stdfs::path(player).parent_path());
    stdfs::copy_file("/usr/bin/true", player);
    REQUIRE(std::system(("/usr/bin/codesign --force --sign - --options runtime '" + player + "' 2>/dev/null").c_str()) == 0);

    ExportOptions o;
    o.projectDir = proj;
    o.platform = "macos";
    o.outDir = tmp.sub("out");
    o.playerBinary = player;
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(warnings_without_icon_note(r.value().warnings).empty());
    const std::string app = tmp.sub("out/space-dodge-macos/Space Dodge.app");
    CHECK(std::system(("/usr/bin/codesign --verify --strict '" + app + "' 2>/dev/null").c_str()) == 0);
    bool forceInSteps = false;
    for (const auto& s : r.value().nextSteps) forceInSteps = forceInSteps || s.find("codesign --force") != std::string::npos;
    CHECK(forceInSteps);  // re-signing a signed app needs --force
}
#endif

TEST_CASE("export: plan_export checks what export_project would, and writes nothing") {
    testing::TempDir tmp;
    std::string proj = make_project(tmp);
    ExportOptions o;
    o.projectDir = proj;
    o.platform = "Win";
    o.outDir = tmp.sub("out");
    o.playerBinary = make_fake_player(tmp);
    auto plan = plan_export(o);
    REQUIRE_MESSAGE(plan.ok(), (plan.ok() ? "" : plan.error().to_string()));
    CHECK(plan->platform == "windows");
    CHECK(stdfs::weakly_canonical(plan->outputDir) == stdfs::weakly_canonical(tmp.sub("out/space-dodge-windows")));
    CHECK(stdfs::weakly_canonical(plan->player) == stdfs::weakly_canonical(o.playerBinary));
    CHECK(plan->mode.empty());
    CHECK_FALSE(stdfs::exists(tmp.sub("out")));  // not even the parent folder
    CHECK(plan->to_json()["outputDir"] == plan->outputDir);

    // The export writes exactly the folder the plan named.
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r->outputDir == plan->outputDir);

    // A failed check is export_project's error, and a previous export stays where it is.
    o.playerBinary = tmp.sub("no/such/player.exe");
    auto bad = plan_export(o);
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("player binary") != std::string::npos);
    auto failed = export_project(o);
    REQUIRE_FALSE(failed.ok());
    CHECK(failed.error().message == bad.error().message);
    CHECK(stdfs::exists(stdfs::path(plan->outputDir) / "space-dodge.exe"));

    // Mobile: the mode, or why there is none; a missing id is reported before anything else.
    ExportOptions m;
    m.projectDir = proj;
    m.platform = "android";
    m.outDir = tmp.sub("out");
    m.mobileDir = make_fake_mobile(tmp);
    m.format = "gradle";  // an apk would need a JDK and the Android SDK (the plan checks them: see the android tests)
    auto mobile = plan_export(m);
    REQUIRE_MESSAGE(mobile.ok(), (mobile.ok() ? "" : mobile.error().to_string()));
    CHECK(mobile->mode == "prebuilt");
    CHECK(mobile->player.empty());
    CHECK_FALSE(stdfs::exists(tmp.sub("out/space-dodge-android")));
}

TEST_CASE("export: only an empty folder or one an export wrote is replaced") {
    testing::TempDir tmp;
    std::string proj = make_project(tmp);
    ExportOptions o;
    o.projectDir = proj;
    o.platform = "linux";
    o.outDir = tmp.sub("out");
    o.playerBinary = make_fake_player(tmp);
    const stdfs::path root = tmp.sub("out/space-dodge-linux");

    // A folder of the user's that happens to have the export's name: the plan and the export refuse, nothing is touched.
    testing::write_all(root / "thesis" / "draft.txt", "years of work");
    auto plan = plan_export(o);
    REQUIRE_FALSE(plan.ok());
    CHECK(plan.error().message.find("space-dodge-linux") != std::string::npos);
    CHECK(plan.error().message.find("not written by an export") != std::string::npos);
    CHECK(plan.error().message.find(kExportMarkerFile) != std::string::npos);
    CHECK(plan.error().hint.find("choose another output folder") != std::string::npos);
    CHECK(plan.error().hint.find("delete") != std::string::npos);
    auto refused = export_project(o);
    REQUIRE_FALSE(refused.ok());
    CHECK(refused.error().message == plan.error().message);
    CHECK(testing::read_all(root / "thesis" / "draft.txt") == "years of work");
    CHECK_FALSE(stdfs::exists(root / kExportMarkerFile));
    CHECK_FALSE(stdfs::exists(root / "space-dodge"));

    // A file where the folder would go is not deleted either.
    {
        ExportOptions w = o;
        w.platform = "windows";
        testing::write_all(tmp.sub("out/space-dodge-windows"), "notes");
        auto file = plan_export(w);
        REQUIRE_FALSE(file.ok());
        CHECK(file.error().message.find("is not a folder") != std::string::npos);
        CHECK_FALSE(file.error().hint.empty());
        CHECK_FALSE(export_project(w).ok());
        CHECK(testing::read_all(tmp.sub("out/space-dodge-windows")) == "notes");
    }

    // An empty folder is fine, and the export leaves its marker at the top.
    stdfs::remove_all(root);
    stdfs::create_directories(root);
    REQUIRE(plan_export(o).ok());
    auto first = export_project(o);
    REQUIRE_MESSAGE(first.ok(), (first.ok() ? "" : first.error().to_string()));
    CHECK(has(first->files, kExportMarkerFile));
    CHECK(testing::read_all(root / kExportMarkerFile).find("factoria export") != std::string::npos);
    CHECK_FALSE(stdfs::exists(root / "game" / kExportMarkerFile));  // not a game file

    // The next export replaces its own folder: what was added to it goes.
    testing::write_all(root / "stale.txt", "old");
    auto second = export_project(o);
    REQUIRE_MESSAGE(second.ok(), (second.ok() ? "" : second.error().to_string()));
    CHECK_FALSE(stdfs::exists(root / "stale.txt"));
    CHECK(stdfs::exists(root / kExportMarkerFile));

    // Exports made before the marker existed: FACTORIA_NOTICES.txt where that platform's export puts it is enough, and
    // nowhere else (the same places write_notices uses; a top-level one is not where a macOS export puts it).
    o.mobileDir = make_fake_mobile(tmp);
    const std::vector<std::pair<std::string, std::string>> legacy = {
        {"linux", "FACTORIA_NOTICES.txt"},
        {"windows", "FACTORIA_NOTICES.txt"},
        {"macos", "Space Dodge.app/Contents/Resources/FACTORIA_NOTICES.txt"},
        {"android", "app/src/main/assets/FACTORIA_NOTICES.txt"},
        {"ios", "game/FACTORIA_NOTICES.txt"}};
    for (const auto& [platform, notices] : legacy) {
        CAPTURE(platform);
        ExportOptions l = o;
        l.platform = platform;
        if (platform == "android") l.format = "gradle";  // the folder is what is checked, not this computer's JDK and SDK
        const stdfs::path dir = tmp.sub("legacy-" + platform + "/space-dodge-" + platform);
        l.outDir = dir.parent_path().string();
        testing::write_all(dir / "old-file.txt", "from an earlier export");
        CHECK_FALSE(plan_export(l).ok());
        if (platform == "macos") {
            testing::write_all(dir / "FACTORIA_NOTICES.txt", "notices");
            CHECK_FALSE(plan_export(l).ok());
        }
        testing::write_all(dir / notices, "notices");
        auto ok = plan_export(l);
        CHECK_MESSAGE(ok.ok(), (ok.ok() ? "" : ok.error().to_string()));
    }
    stdfs::remove(root / kExportMarkerFile);
    testing::write_all(root / "stale.txt", "old");
    auto migrated = export_project(o);
    REQUIRE_MESSAGE(migrated.ok(), (migrated.ok() ? "" : migrated.error().to_string()));
    CHECK_FALSE(stdfs::exists(root / "stale.txt"));
    CHECK(stdfs::exists(root / kExportMarkerFile));

    // project.export {dryRun:true} explains it before anything is written, with the same message and hint.
    stdfs::path taken = stdfs::path(proj) / "dist" / "space-dodge-ios";
    testing::write_all(taken / "notes.txt", "mine");
    CommandRegistry reg;
    register_export_commands(reg, proj);
    auto dry = reg.call("project.export", {{"platform", "ios"}, {"out", "dist"}, {"dryRun", true}});
    REQUIRE_FALSE(dry.ok);
    CHECK(dry.error["message"].get<std::string>().find("not written by an export") != std::string::npos);
    CHECK(dry.error["hint"].get<std::string>().find("choose another output folder") != std::string::npos);
    CHECK_FALSE(reg.call("project.export", {{"platform", "ios"}, {"out", "dist"}}).ok);
    CHECK(testing::read_all(taken / "notes.txt") == "mine");
}

TEST_CASE("export: validation errors are clear") {
    testing::TempDir tmp;
    {
        ExportOptions o;
        o.projectDir = tmp.sub("nothing");
        o.platform = "linux";
        auto r = export_project(o);
        CHECK_FALSE(r.ok());
    }
    {
        std::string proj = make_project(tmp);
        ExportOptions o;
        o.projectDir = proj;
        o.platform = "amiga";
        auto r = export_project(o);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("unknown platform") != std::string::npos);

        // not reverse DNS
        std::string json = testing::read_all(stdfs::path(proj) / "factoria.json");
        auto pos = json.find("com.example.spacedodge");
        REQUIRE(pos != std::string::npos);
        json.replace(pos, 22, "spacedodge");
        testing::write_all(stdfs::path(proj) / "factoria.json", json);
        o.platform = "android";
        auto r2 = export_project(o);
        REQUIRE_FALSE(r2.ok());
        CHECK(r2.error().message.find("reverse-DNS") != std::string::npos);
        CHECK_FALSE(r2.error().hint.empty());
    }
    {
        testing::TempDir t2;
        std::string proj = make_project(t2);
        ExportOptions o;
        o.projectDir = proj;
        o.platform = normalize_export_platform("windows");
        o.outDir = t2.sub("out");
        auto r = export_project(o);  // no player given and cross-platform on non-windows hosts
        if (!r.ok()) CHECK_FALSE(r.error().hint.empty());
    }
}

TEST_CASE("export: android source mode produces a Gradle project that compiles the engine") {
    testing::TempDir tmp;
    std::string proj = make_project(tmp, "Space Dodge's \"Run\"");
    ExportOptions o;
    o.projectDir = proj;
    o.platform = "android";
    o.outDir = tmp.sub("out");
    o.engineRoot = FA_REPO_ROOT;  // asking for a checkout is what selects source mode
    o.format = "gradle";          // the project only: this test never runs Gradle
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    const auto& rep = r.value();
    CHECK(rep.mode == "source");
    CHECK(rep.to_json()["mode"] == "source");
    stdfs::path root = rep.outputDir;
    for (const char* f : {"settings.gradle", "build.gradle", "gradle.properties", "gradle/wrapper/gradle-wrapper.properties",
                          "app/build.gradle", "app/src/main/AndroidManifest.xml", "app/src/main/res/values/strings.xml",
                          "app/src/main/assets/factoria.json", "app/src/main/assets/scenes/main.scene.json",
                          "app/src/main/assets/assets_index.txt", "app/src/main/assets/FACTORIA_NOTICES.txt"})
        CHECK_MESSAGE(stdfs::exists(root / f), f);
    CHECK_FALSE(stdfs::exists(root / "app/src/main/assets/ENGINE_FEEDBACK.json"));
    CHECK_FALSE(stdfs::exists(root / "app/src/main/assets/.factoria"));

    std::string gradle = testing::read_all(root / "app/build.gradle");
    CHECK(gradle.find("applicationId 'com.example.spacedodge'") != std::string::npos);
    CHECK(gradle.find("namespace 'com.example.spacedodge'") != std::string::npos);
    CHECK(gradle.find("minSdk 26") != std::string::npos);
    CHECK(gradle.find("-DFA_BUILD_TOOLS=OFF") != std::string::npos);
    CHECK(gradle.find("'arm64-v8a', 'x86_64'") != std::string::npos);
    CHECK(gradle.find("targets 'factoria_player'") != std::string::npos);
    CHECK(gradle.find("externalNativeBuild") != std::string::npos);
    CHECK(gradle.find("ndkVersion") != std::string::npos);
    CHECK(gradle.find("{{") == std::string::npos);
    CHECK(gradle.find("versionName '0.1.0'") != std::string::npos);
    CHECK(gradle.find("versionCode 100") != std::string::npos);
    std::string manifest = testing::read_all(root / "app/src/main/AndroidManifest.xml");
    CHECK(manifest.find("android.app.NativeActivity") != std::string::npos);
    CHECK(manifest.find("android:value=\"factoria_player\"") != std::string::npos);
    CHECK(manifest.find("sensorLandscape") != std::string::npos);
    // A configuration change the activity does not list restarts it, which ends a sokol NativeActivity process.
    const std::string attr = "android:configChanges=\"";
    REQUIRE(manifest.find(attr) != std::string::npos);
    const std::size_t from = manifest.find(attr) + attr.size();
    const std::string changes = "|" + manifest.substr(from, manifest.find('"', from) - from) + "|";
    for (const char* change : {"mcc", "mnc", "locale", "fontScale", "layoutDirection", "orientation", "uiMode"})
        CHECK(changes.find(std::string("|") + change + "|") != std::string::npos);
    // The one restart it cannot list (assets paths) ends the process: without stateNotNeeded Android drops the activity.
    CHECK(manifest.find("android:stateNotNeeded=\"true\"") != std::string::npos);
    std::string strings = testing::read_all(root / "app/src/main/res/values/strings.xml");
    CHECK(strings.find("Space Dodge\\'s") != std::string::npos);
    CHECK(strings.find("&quot;") != std::string::npos);
    CHECK(testing::read_all(root / "gradle.properties").find("factoria.engineDir=") != std::string::npos);
    CHECK_FALSE(stdfs::exists(root / "app/src/main/jniLibs"));
    for (auto& f : rep.files)
        if (stdfs::path(f).extension() != ".jar") CHECK(testing::read_all(root / f).find("{{") == std::string::npos);

    // assets_index.txt: every shipped file, project-relative, one per line, nothing else.
    std::string index = testing::read_all(root / "app/src/main/assets/assets_index.txt");
    std::vector<std::string> lines;
    std::size_t pos = 0;
    while (pos < index.size()) {
        auto nl = index.find('\n', pos);
        lines.push_back(index.substr(pos, nl - pos));
        pos = nl + 1;
    }
    CHECK(has(lines, "factoria.json"));
    CHECK(has(lines, "scenes/main.scene.json"));
    CHECK(has(lines, "assets/sprites/hero.png"));
    CHECK_FALSE(has(lines, "assets_index.txt"));
    std::vector<std::string> onDisk;
    for (auto& e : stdfs::recursive_directory_iterator(root / "app/src/main/assets"))
        if (e.is_regular_file()) {
            std::string rel = stdfs::relative(e.path(), root / "app/src/main/assets").generic_string();
            if (rel != "assets_index.txt" && rel != "FACTORIA_NOTICES.txt") onDisk.push_back(rel);  // not game files
        }
    std::sort(onDisk.begin(), onDisk.end());
    auto sorted = lines;
    std::sort(sorted.begin(), sorted.end());
    CHECK(sorted == onDisk);
    CHECK(rep.nextSteps.size() >= 3);
    bool mentionsGradlew = false;
    for (auto& s : rep.nextSteps) mentionsGradlew |= s.find(kGradlewAssemble) != std::string::npos;
    CHECK(mentionsGradlew);
}

TEST_CASE("export: android orientation and keyword ids") {
    testing::TempDir tmp;
    std::string proj = make_project(tmp);
    std::string json = testing::read_all(stdfs::path(proj) / "factoria.json");
    auto pos = json.find("\"landscape\"");
    REQUIRE(pos != std::string::npos);
    json.replace(pos, 11, "\"portrait\"");
    testing::write_all(stdfs::path(proj) / "factoria.json", json);
    ExportOptions o;
    o.projectDir = proj;
    o.platform = "android";
    o.outDir = tmp.sub("out");
    o.mobileDir = make_fake_mobile(tmp);
    o.format = "gradle";
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(testing::read_all(stdfs::path(r->outputDir) / "app/src/main/AndroidManifest.xml").find("sensorPortrait") != std::string::npos);

    json = testing::read_all(stdfs::path(proj) / "factoria.json");
    pos = json.find("com.example.spacedodge");
    json.replace(pos, 22, "com.example.new");
    testing::write_all(stdfs::path(proj) / "factoria.json", json);
    auto bad = export_project(o);
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("Java keyword") != std::string::npos);
}

TEST_CASE("export: ios source mode produces a script and the game folder") {
    testing::TempDir tmp;
    std::string proj = make_project(tmp);
    ExportOptions o;
    o.projectDir = proj;
    o.platform = "ios";
    o.outDir = tmp.sub("out");
    o.release = true;
    o.engineRoot = FA_REPO_ROOT;
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r->mode == "source");
    stdfs::path root = r->outputDir;
    CHECK(stdfs::exists(root / "game/factoria.json"));
    CHECK(r->notices == "game/FACTORIA_NOTICES.txt");  // game/ is copied into the app bundle
    CHECK(stdfs::exists(root / "game/FACTORIA_NOTICES.txt"));
    CHECK_FALSE(stdfs::exists(root / "game/ENGINE_FEEDBACK.json"));
    REQUIRE(stdfs::exists(root / "build_ios.sh"));
    std::string script = testing::read_all(root / "build_ios.sh");
    CHECK(script.find("-G Xcode") != std::string::npos);
    CHECK(script.find("-DCMAKE_SYSTEM_NAME=iOS") != std::string::npos);
    CHECK(script.find("-DFA_GAME_PROJECT_DIR=\"$HERE/game\"") != std::string::npos);
    CHECK(script.find("-DFA_GAME_BUNDLE_ID='com.example.spacedodge'") != std::string::npos);
    CHECK(script.find("-DFA_GAME_NAME='Space Dodge'") != std::string::npos);
    CHECK(script.find("CONFIG=Release") != std::string::npos);
    CHECK(script.find("BUNDLE_ID='com.example.spacedodge'") != std::string::npos);
    // A device build is a scheme build with a destination, so Xcode can register a connected device with the team (a
    // target build ignores the destination and fails with "Your team has no devices"); --run installs and starts it.
    CHECK(script.find("-scheme factoria_player") != std::string::npos);
    CHECK(script.find("-allowProvisioningDeviceRegistration") != std::string::npos);
    CHECK(script.find("--run) BUILD=1; RUN=1") != std::string::npos);
    CHECK(script.find("xcrun devicectl device install app") != std::string::npos);
    CHECK(script.find("xcrun simctl launch --terminate-running-process --console-pty") != std::string::npos);
    CHECK(script.find("\"$CMAKE\" -S \"$ENGINE_DIR\"") != std::string::npos);
    CHECK(script.find("-DFA_BUILD_TOOLS=OFF") != std::string::npos);
    CHECK(script.find("XCODE_ARGS") != std::string::npos);  // everything after `--` goes to xcodebuild
    CHECK_FALSE(stdfs::exists(root / "CMakeLists.txt"));
    CHECK_FALSE(stdfs::exists(root / "lib"));
#ifndef _WIN32
    CHECK((stdfs::status(root / "build_ios.sh").permissions() & stdfs::perms::owner_exec) != stdfs::perms::none);
#endif
    bool mentionsScript = false;
    for (auto& s : r->nextSteps) mentionsScript |= s.find("build_ios.sh") != std::string::npos;
    CHECK(mentionsScript);
}

TEST_CASE("export: android prebuilt mode packages the downloaded libraries and needs no engine") {
    testing::TempDir tmp;
    std::string proj = make_project(tmp);
    ExportOptions o;
    o.projectDir = proj;
    o.platform = "android";
    o.outDir = tmp.sub("out");
    o.mobileDir = make_fake_mobile(tmp);
    o.buildSourceRoot = tmp.sub("no-checkout-here");  // factoria "was built" from a folder that does not exist
    o.format = "gradle";
    ScopedEnv noEngine("FACTORIA_ENGINE_DIR", nullptr);
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    const auto& rep = r.value();
    CHECK(rep.mode == "prebuilt");
    CHECK(rep.to_json()["mode"] == "prebuilt");
    stdfs::path root = rep.outputDir;

    // The prebuilt players are copied where Gradle packages them as they are.
    CHECK(testing::read_all(root / "app/src/main/jniLibs/arm64-v8a/libfactoria_player.so") == "fake arm64-v8a");
    CHECK(testing::read_all(root / "app/src/main/jniLibs/x86_64/libfactoria_player.so") == "fake x86_64");
    for (const char* f : {"settings.gradle", "build.gradle", "gradle.properties", "gradle/wrapper/gradle-wrapper.properties",
                          "app/build.gradle", "app/src/main/AndroidManifest.xml", "app/src/main/res/values/strings.xml",
                          "app/src/main/assets/factoria.json", "app/src/main/assets/assets_index.txt"})
        CHECK_MESSAGE(stdfs::exists(root / f), f);

    // Nothing in the project compiles native code or points at an engine checkout.
    std::string gradle = testing::read_all(root / "app/build.gradle");
    CHECK(gradle.find("applicationId 'com.example.spacedodge'") != std::string::npos);
    CHECK(gradle.find("abiFilters 'arm64-v8a', 'x86_64'") != std::string::npos);
    CHECK(gradle.find("externalNativeBuild") == std::string::npos);
    CHECK(gradle.find("ndkVersion") == std::string::npos);
    CHECK(gradle.find("cmake") == std::string::npos);
    CHECK(gradle.find("engineDir") == std::string::npos);
    CHECK(testing::read_all(root / "gradle.properties").find("engineDir=") == std::string::npos);
    CHECK(testing::read_all(root / "gradle.properties").find("cmakeVersion") == std::string::npos);
    const std::string nowhere = stdfs::path(tmp.sub("no-checkout-here")).generic_string();
    for (auto& f : rep.files) {
        const std::string ext = stdfs::path(f).extension().string();
        if (ext == ".jar" || ext == ".png" || ext == ".so") continue;  // binary files
        std::string text = testing::read_all(root / f);
        CHECK_MESSAGE(text.find("{{") == std::string::npos, f);
        CHECK_MESSAGE(text.find(nowhere) == std::string::npos, f);
    }
    CHECK(warnings_without_icon_note(rep.warnings).empty());

    std::string steps;
    for (auto& s : rep.nextSteps) steps += s + "\n";
    CHECK(steps.find(kGradlewAssemble) != std::string::npos);
    CHECK(steps.find("no NDK or CMake") != std::string::npos);
    CHECK(steps.find("ndk;") == std::string::npos);

    // The same manifest as source mode: the template is shared, only the native build differs.
    CHECK(testing::read_all(root / "app/src/main/AndroidManifest.xml").find("android:value=\"factoria_player\"") != std::string::npos);
}

TEST_CASE("export: android picks the mode by the documented rule") {
    testing::TempDir tmp;
    std::string proj = make_project(tmp);
    ExportOptions base;
    base.projectDir = proj;
    base.platform = "android";
    base.outDir = tmp.sub("out");
    base.format = "gradle";  // only the mode matters here, and an apk would run Gradle
    auto mode = [&](const ExportOptions& o) {
        auto r = export_project(o);
        return r.ok() ? r->mode : "error: " + r.error().message;
    };

    SUBCASE("libraries next to the executable, no engine asked for: prebuilt") {
        MobileNextToExe fake;
        if (!fake.active) return;  // a real mobile/ folder is there: do not touch it
        ScopedEnv noEngine("FACTORIA_ENGINE_DIR", nullptr);
        CHECK(mode(base) == "prebuilt");
    }
    SUBCASE("$FACTORIA_ENGINE_DIR asks for source, even with libraries next to the executable") {
        MobileNextToExe fake;
        if (!fake.active) return;
        ScopedEnv engine("FACTORIA_ENGINE_DIR", FA_REPO_ROOT);
        CHECK(mode(base) == "source");
    }
    SUBCASE("--engine-root asks for source and beats --mobile-dir") {
        ExportOptions o = base;
        o.engineRoot = FA_REPO_ROOT;
        o.mobileDir = make_fake_mobile(tmp);
        CHECK(mode(o) == "source");
    }
    SUBCASE("--mobile-dir asks for prebuilt and beats $FACTORIA_ENGINE_DIR") {
        ScopedEnv engine("FACTORIA_ENGINE_DIR", FA_REPO_ROOT);
        ExportOptions o = base;
        o.mobileDir = make_fake_mobile(tmp);
        CHECK(mode(o) == "prebuilt");
    }
    SUBCASE("nothing asked for and no libraries: the checkout factoria was built from, as before") {
        if (stdfs::exists(executable_dir() / "mobile")) return;
        ScopedEnv noEngine("FACTORIA_ENGINE_DIR", nullptr);
        ExportOptions o = base;
        o.buildSourceRoot = FA_REPO_ROOT;
        CHECK(mode(o) == "source");
    }
}

TEST_CASE("export: android without prebuilt players or a checkout says what to do") {
    testing::TempDir tmp;
    std::string proj = make_project(tmp);
    ScopedEnv noEngine("FACTORIA_ENGINE_DIR", nullptr);
    const std::string home = tmp.sub("factoria-home");  // not what `factoria setup players` installed on this computer
    ScopedEnv noSetup("FACTORIA_HOME", home.c_str());
    ExportOptions o;
    o.projectDir = proj;
    o.platform = "android";
    o.outDir = tmp.sub("out");

    SUBCASE("neither available") {
        if (stdfs::exists(executable_dir() / "mobile")) return;
        o.buildSourceRoot = tmp.sub("no-checkout-here");
        auto r = export_project(o);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("no prebuilt player") != std::string::npos);
        CHECK(r.error().message.find("no engine source checkout") != std::string::npos);
        CHECK(r.error().message.find("libfactoria_player.so") != std::string::npos);
        CHECK(r.error().hint.find("mobile/") != std::string::npos);
        CHECK(r.error().hint.find("FACTORIA_ENGINE_DIR") != std::string::npos);
        CHECK(r.error().hint.find("releases") != std::string::npos);
        CHECK_FALSE(stdfs::exists(tmp.sub("out/space-dodge-android")));  // nothing half-written is left
    }
    SUBCASE("--mobile-dir without players") {
        o.mobileDir = tmp.sub("empty-download");
        auto r = export_project(o);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("no prebuilt Android player") != std::string::npos);
        CHECK(r.error().hint.find("--mobile-dir") != std::string::npos);
    }
    SUBCASE("--mobile-dir with only one ABI") {
        o.mobileDir = make_fake_mobile(tmp, "download/mobile", {"arm64-v8a"});
        auto r = export_project(o);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("no prebuilt Android player") != std::string::npos);
    }
    SUBCASE("--engine-root that is not a checkout") {
        o.engineRoot = tmp.sub("not-an-engine");
        auto r = export_project(o);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("engine checkout not found") != std::string::npos);
        CHECK(r.error().message.find("--engine-root") != std::string::npos);
        CHECK(r.error().hint.find("prebuilt") != std::string::npos);
    }
    SUBCASE("$FACTORIA_ENGINE_DIR that is not a checkout") {
        const std::string bogus = tmp.sub("not-an-engine");
        ScopedEnv engine("FACTORIA_ENGINE_DIR", bogus.c_str());
        auto r = export_project(o);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("$FACTORIA_ENGINE_DIR") != std::string::npos);
    }
}

TEST_CASE("export: ios prebuilt mode writes a project that links the downloaded libraries") {
    testing::TempDir tmp;
    std::string proj = make_project(tmp);
    ExportOptions o;
    o.projectDir = proj;
    o.platform = "ios";
    o.outDir = tmp.sub("out");
    o.mobileDir = make_fake_mobile(tmp);
    o.buildSourceRoot = tmp.sub("no-checkout-here");
    ScopedEnv noEngine("FACTORIA_ENGINE_DIR", nullptr);
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r->mode == "prebuilt");
    CHECK(r->to_json()["mode"] == "prebuilt");
    stdfs::path root = r->outputDir;

    for (const char* f : {"CMakeLists.txt", "cmake/plist.cmake", "cmake/Info.plist.in", "cmake/copy_game.cmake", "build_ios.sh",
                          "game/factoria.json", "lib/iphoneos/libfactoria_player_main.a", "lib/iphoneos/libfa_core.a",
                          "lib/iphonesimulator/libfactoria_player_main.a", "lib/iphonesimulator/libfa_core.a"})
        CHECK_MESSAGE(stdfs::exists(root / f), f);
    CHECK(testing::read_all(root / "lib/iphonesimulator/libfa_core.a") == "fake core iphonesimulator");
    CHECK_FALSE(stdfs::exists(root / "game/ENGINE_FEEDBACK.json"));

    // The project is self-contained: its CMake file only includes files that were written next to it.
    std::string cmake = testing::read_all(root / "CMakeLists.txt");
    CHECK(cmake.find("cmake/plist.cmake") != std::string::npos);
    CHECK(cmake.find("cmake/copy_game.cmake") != std::string::npos);
    CHECK(cmake.find("lib/${FA_IOS_SLICE}") != std::string::npos);
    CHECK(cmake.find("FA_ROOT") == std::string::npos);  // would be the engine checkout
    CHECK(testing::read_all(root / "cmake/Info.plist.in").find("@FA_GAME_BUNDLE_ID@") != std::string::npos);

    std::string script = testing::read_all(root / "build_ios.sh");
    CHECK(script.find("mode: prebuilt") != std::string::npos);
    CHECK(script.find("\"$CMAKE\" -S \"$HERE\" -B \"$HERE/build\" -G Xcode") != std::string::npos);
    CHECK(script.find("CMAKE=\"${FACTORIA_CMAKE:-}\"") != std::string::npos);  // CMake: FACTORIA_CMAKE, the found one, PATH
    CHECK(script.find("factoria setup cmake") != std::string::npos);
    CHECK(script.find("-DCMAKE_SYSTEM_NAME=iOS") != std::string::npos);
    CHECK(script.find("-DFA_GAME_BUNDLE_ID='com.example.spacedodge'") != std::string::npos);
    CHECK(script.find("-DFA_GAME_PROJECT_DIR=\"$HERE/game\"") != std::string::npos);
    CHECK(script.find("ENGINE_DIR") == std::string::npos);
    CHECK(script.find("FA_BUILD_TOOLS") == std::string::npos);
    CHECK(script.find("-sdk iphonesimulator CODE_SIGNING_ALLOWED=NO") != std::string::npos);
    CHECK(script.find("-scheme factoria_player") != std::string::npos);
    CHECK(script.find("--) shift; XCODE_ARGS") != std::string::npos);
    std::string steps;
    for (auto& s : r->nextSteps) steps += s + "\n";
    CHECK(steps.find("no engine source needed") != std::string::npos);
}

TEST_CASE("export: ios needs both prebuilt slices, or says what to do") {
    testing::TempDir tmp;
    std::string proj = make_project(tmp);
    ScopedEnv noEngine("FACTORIA_ENGINE_DIR", nullptr);
    ExportOptions o;
    o.projectDir = proj;
    o.platform = "ios";
    o.outDir = tmp.sub("out");

    SUBCASE("only the simulator libraries") {
        o.mobileDir = make_fake_mobile(tmp, "download/mobile", {"arm64-v8a"}, {"iphonesimulator"});
        auto r = export_project(o);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("no prebuilt iOS player") != std::string::npos);
        CHECK(r.error().message.find("libfactoria_player_main.a") != std::string::npos);
    }
    SUBCASE("neither available") {
        if (stdfs::exists(executable_dir() / "mobile")) return;
        o.buildSourceRoot = tmp.sub("no-checkout-here");
        auto r = export_project(o);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("no engine source checkout") != std::string::npos);
        CHECK(r.error().hint.find("macOS") != std::string::npos);  // the iOS libraries ship in the macOS package
        CHECK(r.error().hint.find("FACTORIA_ENGINE_DIR") != std::string::npos);
    }
}

TEST_CASE("export: command project.export (MCP tool project_export)") {
    testing::TempDir tmp;
    std::string proj = make_project(tmp);
    CommandRegistry reg;
    register_export_commands(reg, proj);
    REQUIRE(reg.has("project.export"));
    const CommandInfo* info = reg.info("project.export");
    CHECK_FALSE(info->readOnly);
    for (const char* field : {"platform", "out", "release", "dryRun"})
        CHECK_FALSE(info->inputSchema["properties"][field].value("description", std::string()).empty());

    // dryRun: the plan, nothing written; a check that fails is the same error a real export gives.
    auto dry = reg.call("project.export", {{"platform", "ios"}, {"dryRun", true}});
    REQUIRE_MESSAGE(dry.ok, dry.error.dump());
    CHECK(dry.result["platform"] == "ios");
    CHECK(stdfs::weakly_canonical(dry.result["outputDir"].get<std::string>()) ==
          stdfs::weakly_canonical(stdfs::path(proj) / "build" / "export" / "space-dodge-ios"));
    CHECK(dry.result.contains("mode"));
    CHECK_FALSE(dry.result.contains("files"));
    CHECK_FALSE(stdfs::exists(stdfs::path(proj) / "build" / "export"));

    // ios needs no player binary; a relative `out` is relative to the project; "iphone" is an alias. A first export to the
    // default build/export must not be shipped inside the second one.
    REQUIRE(reg.call("project.export", {{"platform", "ios"}}).ok);
    auto ok = reg.call("project.export", {{"platform", "iphone"}, {"out", "dist"}, {"release", true}});
    REQUIRE_MESSAGE(ok.ok, ok.error.dump());
    stdfs::path root = ok.result["outputDir"].get<std::string>();
    CHECK(stdfs::weakly_canonical(root) == stdfs::weakly_canonical(stdfs::path(proj) / "dist" / "space-dodge-ios"));
    CHECK(stdfs::exists(root / "build_ios.sh"));
    CHECK(has(ok.result["files"].get<std::vector<std::string>>(), "game/factoria.json"));
    for (const std::string& f : ok.result["files"].get<std::vector<std::string>>()) CHECK(f.find("game/build/") != 0);
    CHECK_FALSE(ok.result["nextSteps"].empty());
    CHECK(ok.result["warnings"].is_array());
    CHECK(testing::read_all(root / "build_ios.sh").find("CONFIG=Release") != std::string::npos);

    // Unknown platform: a teaching error, nothing written.
    auto bad = reg.call("project.export", {{"platform", "windwos"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error["code"] == "invalid_argument");
    CHECK(bad.error["hint"].get<std::string>().find("windows") != std::string::npos);

    // `out` stays inside the project, like fs.*: the export folder is deleted and rewritten.
    auto outside = reg.call("project.export", {{"platform", "ios"}, {"out", "../elsewhere"}});
    REQUIRE_FALSE(outside.ok);
    CHECK(outside.error["code"] == "invalid_argument");
    CHECK_FALSE(stdfs::exists(stdfs::path(proj).parent_path() / "elsewhere"));

    // Errors from export_project keep their message and hint.
    CommandRegistry empty;
    register_export_commands(empty, tmp.sub("no-project"));
    auto missing = empty.call("project.export", {{"platform", "linux"}});
    REQUIRE_FALSE(missing.ok);
    CHECK(missing.error["message"].get<std::string>().find("does not exist") != std::string::npos);
}

// End to end on Linux: export a game and run the exported player for a few seconds under a (virtual) display.
#if defined(__linux__)
constexpr bool kIsLinux = true;
#else
constexpr bool kIsLinux = false;
#endif
TEST_CASE("export: the exported linux player runs the game" * doctest::skip(!kIsLinux)) {
    // Locate the player in the build tree: <build>/tools/common/fa_test_tooling -> <build>/player/factoria_player.
    stdfs::path exeDir = stdfs::read_symlink("/proc/self/exe").parent_path();
    stdfs::path player;
    for (auto c : {exeDir / "../../player/factoria_player", exeDir / "../player/factoria_player", exeDir / "factoria_player"})
        if (stdfs::exists(c)) { player = stdfs::weakly_canonical(c); break; }
    if (player.empty()) { MESSAGE("factoria_player not built; skipping"); return; }
    if (std::system("command -v xvfb-run >/dev/null 2>&1 && command -v timeout >/dev/null 2>&1") != 0) {
        MESSAGE("xvfb-run/timeout not installed; skipping");
        return;
    }
    testing::TempDir tmp;
    std::string proj = make_project(tmp);
    ExportOptions o;
    o.projectDir = proj;
    o.platform = "linux";
    o.outDir = tmp.sub("out");
    o.playerBinary = player.string();
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    std::string log = tmp.sub("run.log");
    std::string cmd = "cd '" + r->outputDir + "' && xvfb-run -a -s '-screen 0 1280x720x24' timeout 5 ./space-dodge >'" + log + "' 2>&1";
    int rc = std::system(cmd.c_str());
    std::string out = testing::read_all(log);
    INFO(out);
    // timeout exits with 124 when the game was still running after 5 s.
#ifdef _WIN32
    (void)rc;
#else
    CHECK(WEXITSTATUS(rc) == 124);
#endif
    CHECK(out.find("Loaded scenes/main.scene.json") != std::string::npos);
    // Engine log lines look like "[  0.101] ERROR script: ...". Engine/platform/render errors fail the test;
    // script errors are reported (they are the template's business) but do not.
    std::size_t pos = 0;
    while ((pos = out.find("] ERROR ", pos)) != std::string::npos) {
        std::size_t eol = out.find('\n', pos);
        std::string line = out.substr(pos, eol - pos);
        if (line.find("] ERROR script:") != std::string::npos) MESSAGE("script error in exported game: " << line);
        else CHECK_MESSAGE(false, line);
        pos += 8;
    }
}
