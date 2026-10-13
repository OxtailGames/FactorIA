#include <doctest.h>

#include <cstdlib>
#include <filesystem>
#include <fstream>

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
        CHECK(stdfs::path(rep.outputDir) == stdfs::path(root));
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

TEST_CASE("export: android produces a Gradle project") {
    testing::TempDir tmp;
    std::string proj = make_project(tmp, "Space Dodge's \"Run\"");
    ExportOptions o;
    o.projectDir = proj;
    o.platform = "android";
    o.outDir = tmp.sub("out");
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    const auto& rep = r.value();
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

TEST_CASE("export: ios produces a script and the game folder") {
    testing::TempDir tmp;
    std::string proj = make_project(tmp);
    ExportOptions o;
    o.projectDir = proj;
    o.platform = "ios";
    o.outDir = tmp.sub("out");
    o.release = true;
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
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
#ifndef _WIN32
    CHECK((stdfs::status(root / "build_ios.sh").permissions() & stdfs::perms::owner_exec) != stdfs::perms::none);
#endif
    bool mentionsScript = false;
    for (auto& s : r->nextSteps) mentionsScript |= s.find("build_ios.sh") != std::string::npos;
    CHECK(mentionsScript);
}

// End to end on Linux: export a game and run the exported player for a few seconds under a (virtual) display.
TEST_CASE("export: the exported linux player runs the game" * doctest::skip(
#if defined(__linux__)
    false
#else
    true
#endif
    )) {
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
    CHECK(out.find("[error]") == std::string::npos);
    CHECK(out.find("error:") == std::string::npos);
}
