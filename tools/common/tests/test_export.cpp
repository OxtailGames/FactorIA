#include <doctest.h>

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <optional>

#if !defined(_WIN32)
#include <sys/wait.h>
#endif

#include "fa/tooling/export.h"
#include "fa/tooling/scaffold.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

bool has(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }

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

TEST_CASE("export: platform names are normalized") {
    CHECK(normalize_export_platform("Win") == "windows");
    CHECK(normalize_export_platform("OSX") == "macos");
    CHECK(normalize_export_platform("android") == "android");
    CHECK(normalize_export_platform("amiga").empty());
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
        if (std::string(platform) == "macos") {
            game = root + "/Space Dodge.app/Contents/Resources/game";
            exe = root + "/Space Dodge.app/Contents/MacOS/space-dodge";
            CHECK(testing::read_all(root + "/Space Dodge.app/Contents/Info.plist").find("com.example.spacedodge") != std::string::npos);
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
    }
    // The project itself is untouched.
    CHECK(stdfs::exists(stdfs::path(proj) / "ENGINE_FEEDBACK.json"));
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
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    const auto& rep = r.value();
    CHECK(rep.mode == "source");
    CHECK(rep.to_json()["mode"] == "source");
    stdfs::path root = rep.outputDir;
    for (const char* f : {"settings.gradle", "build.gradle", "gradle.properties", "gradle/wrapper/gradle-wrapper.properties",
                          "app/build.gradle", "app/src/main/AndroidManifest.xml", "app/src/main/res/values/strings.xml",
                          "app/src/main/assets/factoria.json", "app/src/main/assets/scenes/main.scene.json",
                          "app/src/main/assets/assets_index.txt"})
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
    std::string strings = testing::read_all(root / "app/src/main/res/values/strings.xml");
    CHECK(strings.find("Space Dodge\\'s") != std::string::npos);
    CHECK(strings.find("&quot;") != std::string::npos);
    CHECK(testing::read_all(root / "gradle.properties").find("factoria.engineDir=") != std::string::npos);
    CHECK_FALSE(stdfs::exists(root / "app/src/main/jniLibs"));
    for (auto& f : rep.files) CHECK(testing::read_all(root / f).find("{{") == std::string::npos);

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
            if (rel != "assets_index.txt") onDisk.push_back(rel);
        }
    std::sort(onDisk.begin(), onDisk.end());
    auto sorted = lines;
    std::sort(sorted.begin(), sorted.end());
    CHECK(sorted == onDisk);
    CHECK(rep.nextSteps.size() >= 3);
    bool mentionsGradlew = false;
    for (auto& s : rep.nextSteps) mentionsGradlew |= s.find("./gradlew assembleDebug") != std::string::npos;
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
    CHECK_FALSE(stdfs::exists(root / "game/ENGINE_FEEDBACK.json"));
    REQUIRE(stdfs::exists(root / "build_ios.sh"));
    std::string script = testing::read_all(root / "build_ios.sh");
    CHECK(script.find("-G Xcode") != std::string::npos);
    CHECK(script.find("-DCMAKE_SYSTEM_NAME=iOS") != std::string::npos);
    CHECK(script.find("-DFA_GAME_PROJECT_DIR=\"$HERE/game\"") != std::string::npos);
    CHECK(script.find("-DFA_GAME_BUNDLE_ID='com.example.spacedodge'") != std::string::npos);
    CHECK(script.find("-DFA_GAME_NAME='Space Dodge'") != std::string::npos);
    CHECK(script.find("--config Release") != std::string::npos);
    CHECK(script.find("cmake -S \"$ENGINE_DIR\"") != std::string::npos);
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
        std::string text = testing::read_all(root / f);
        CHECK_MESSAGE(text.find("{{") == std::string::npos, f);
        CHECK_MESSAGE(text.find(nowhere) == std::string::npos, f);
    }
    CHECK(rep.warnings.empty());

    std::string steps;
    for (auto& s : rep.nextSteps) steps += s + "\n";
    CHECK(steps.find("./gradlew assembleDebug") != std::string::npos);
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
    CHECK(script.find("cmake -S \"$HERE\" -B \"$HERE/build\" -G Xcode") != std::string::npos);
    CHECK(script.find("-DCMAKE_SYSTEM_NAME=iOS") != std::string::npos);
    CHECK(script.find("-DFA_GAME_BUNDLE_ID='com.example.spacedodge'") != std::string::npos);
    CHECK(script.find("-DFA_GAME_PROJECT_DIR=\"$HERE/game\"") != std::string::npos);
    CHECK(script.find("ENGINE_DIR") == std::string::npos);
    CHECK(script.find("FA_BUILD_TOOLS") == std::string::npos);
    CHECK(script.find("-sdk \"$SYSROOT\"") != std::string::npos);
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
    for (const char* field : {"platform", "out", "release"})
        CHECK_FALSE(info->inputSchema["properties"][field].value("description", std::string()).empty());

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
    CHECK(testing::read_all(root / "build_ios.sh").find("--config Release") != std::string::npos);

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
