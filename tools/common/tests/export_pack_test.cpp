// `--release` desktop exports: the whole game in one game.pak (fa/core/pack.h), scripts as bytecode, and the files no game reads
// (README.md...) left out of every export.
#include <doctest.h>

#include <algorithm>
#include <filesystem>

#include "fa/core/fs.h"
#include "fa/core/pack.h"
#include "fa/script/bytecode.h"
#include "fa/tooling/export.h"
#include "fa/tooling/scaffold.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

bool has(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }

std::string make_fake_player(const testing::TempDir& tmp) {
    std::string p = tmp.sub("fake_player/factoria_player");
    testing::write_all(p, "#!/bin/sh\nexit 0\n");
    return p;
}

// A project made from `tpl`, with a README.md deeper in the tree (a credits file a game may load).
std::string make_project(const testing::TempDir& tmp, const std::string& tpl = "2d-platformer") {
    std::string dir = tmp.sub("proj");
    ScaffoldOptions so;
    so.name = "Pack Test";
    so.id = "com.example.packtest";
    auto r = create_project(dir, tpl, so);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    testing::write_all(stdfs::path(dir) / "data" / "README.md", "credits the game shows");
    testing::write_all(stdfs::path(dir) / ".factoria" / "cache.bin", "x");
    return dir;
}

ExportOptions options_for(const testing::TempDir& tmp, const std::string& proj, const char* platform, bool release) {
    ExportOptions o;
    o.projectDir = proj;
    o.platform = platform;
    o.outDir = tmp.sub("out");
    o.playerBinary = make_fake_player(tmp);
    o.release = release;
    return o;
}

// Where a desktop export puts the game's data: <root>/game.pak or <root>/<app>/Contents/Resources/game.pak
std::string pack_dir(const std::string& root, const std::string& platform) {
    return platform == "macos" ? root + "/Pack Test.app/Contents/Resources" : root;
}

std::vector<std::string> files_below(const stdfs::path& root) {
    std::vector<std::string> out;
    for (const auto& e : stdfs::recursive_directory_iterator(root))
        if (e.is_regular_file()) out.push_back(stdfs::relative(e.path(), root).generic_string());
    return out;
}

void set_bytecode_setting(const std::string& proj, bool on) {
    const stdfs::path file = stdfs::path(proj) / "factoria.json";
    auto j = parse_json(testing::read_all(file), "factoria.json");
    REQUIRE(j.ok());
    (*j)["export"]["scriptBytecode"] = on;
    testing::write_all(file, j->dump(2));
}

}  // namespace

TEST_CASE("export --release: a desktop game is one game.pak, with no loose scripts and no README.md") {
    testing::TempDir tmp;
    const std::string proj = make_project(tmp);

    for (const char* platformName : {"linux", "windows", "macos"}) {
        const std::string platform = platformName;
        CAPTURE(platform);
        auto r = export_project(options_for(tmp, proj, platformName, true));
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        const ExportReport& rep = r.value();
        const std::string root = tmp.sub("out/pack-test-" + platform);
        const std::string where = pack_dir(root, platform);

        // On disk: the executable, the notices and game.pak. No game/ folder, no .js, no README.md, nothing of the project.
        const auto onDisk = files_below(root);
        CHECK(stdfs::exists(where + "/game.pak"));
        CHECK_FALSE(stdfs::exists(where + "/game"));
        for (const std::string& f : onDisk) {
            INFO("loose file: ", f);
            CHECK(stdfs::path(f).extension() != ".js");
            CHECK(stdfs::path(f).filename() != "README.md");
            CHECK(f.find("scenes/") == std::string::npos);
        }
        CHECK(has(rep.files, platform == "macos" ? "Pack Test.app/Contents/Resources/game.pak" : "game.pak"));
        CHECK(rep.pack == "game.pak");

        // In the pack: the game, scripts as bytecode, the data file with the README's name (deeper than the top level) included.
        auto pack = PackReader::open(where + "/game.pak");
        REQUIRE_MESSAGE(pack.ok(), (pack.ok() ? "" : pack.error().to_string()));
        const PackReader& p = *pack.value();
        CHECK(p.contains("factoria.json"));
        CHECK(p.contains("scenes/main.scene.json"));
        CHECK(p.contains("data/README.md"));
        CHECK_FALSE(p.contains("README.md"));
        CHECK_FALSE(p.contains("AGENTS.md"));
        CHECK_FALSE(p.contains("ENGINE_FEEDBACK.json"));
        CHECK(p.list(".factoria", true).empty());
        CHECK(p.list("tests", true).empty());
        CHECK(p.list("tools", true).empty());
        const auto scripts = p.list("scripts", true);
        REQUIRE_FALSE(scripts.empty());
        for (const std::string& s : scripts) {
            INFO("script: ", s);
            auto data = p.read(s);
            REQUIRE(data.ok());
            CHECK(is_script_bytecode(std::string_view(reinterpret_cast<const char*>(data->data()), data->size())));
        }
        CHECK(rep.packed.size() == p.file_count());
        CHECK(has(rep.packed, "scenes/main.scene.json"));

        const Json j = rep.to_json();
        CHECK(j["pack"] == "game.pak");
        CHECK(j["packed"].size() == p.file_count());
        bool mentionsPack = false;
        for (const auto& step : rep.nextSteps) mentionsPack = mentionsPack || step.find("game.pak") != std::string::npos;
        CHECK(mentionsPack);
        // The pack stays when the same game is exported again (the folder was written by an export, so it is replaced).
        CHECK(export_project(options_for(tmp, proj, platformName, true)).ok());
    }
    // The project itself is untouched.
    CHECK(stdfs::exists(stdfs::path(proj) / "README.md"));
    CHECK(testing::read_all(stdfs::path(proj) / "scripts" / "player.js").find("export default") != std::string::npos);
}

TEST_CASE("export --release: export.scriptBytecode false packs the scripts as the source they are") {
    testing::TempDir tmp;
    const std::string proj = make_project(tmp);
    set_bytecode_setting(proj, false);
    auto r = export_project(options_for(tmp, proj, "linux", true));
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    auto pack = PackReader::open(tmp.sub("out/pack-test-linux/game.pak"));
    REQUIRE(pack.ok());
    auto data = pack.value()->read("scripts/player.js");
    REQUIRE(data.ok());
    const std::string text(data->begin(), data->end());
    CHECK_FALSE(is_script_bytecode(text));
    CHECK(text == testing::read_all(stdfs::path(proj) / "scripts" / "player.js"));
    bool mentionsSource = false;
    for (const auto& step : r->nextSteps) mentionsSource = mentionsSource || step.find("scripts as source") != std::string::npos;
    CHECK(mentionsSource);
}

TEST_CASE("export --release: a script that does not compile is packed as source, with a warning that names file and line") {
    testing::TempDir tmp;
    const std::string proj = make_project(tmp);
    testing::write_all(stdfs::path(proj) / "scripts" / "broken.js", "export const ok = 1;\nconst = ;\n");
    auto r = export_project(options_for(tmp, proj, "windows", true));
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    bool warned = false;
    for (const auto& w : r->warnings)
        if (w.find("scripts/broken.js:2") != std::string::npos && w.find("packed as plain source") != std::string::npos) warned = true;
    CHECK(warned);
    auto pack = PackReader::open(tmp.sub("out/pack-test-windows/game.pak"));
    REQUIRE(pack.ok());
    auto broken = pack.value()->read("scripts/broken.js");
    REQUIRE(broken.ok());
    CHECK(std::string(broken->begin(), broken->end()) == "export const ok = 1;\nconst = ;\n");
    auto fine = pack.value()->read("scripts/player.js");
    REQUIRE(fine.ok());
    CHECK(is_script_bytecode(std::string_view(reinterpret_cast<const char*>(fine->data()), fine->size())));
}

TEST_CASE("export: without --release a desktop game is still a game/ folder of loose files") {
    testing::TempDir tmp;
    const std::string proj = make_project(tmp);
    auto r = export_project(options_for(tmp, proj, "linux", false));
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    const std::string game = tmp.sub("out/pack-test-linux/game");
    CHECK_FALSE(stdfs::exists(tmp.sub("out/pack-test-linux/game.pak")));
    CHECK(stdfs::exists(game + "/scripts/player.js"));
    CHECK(testing::read_all(game + "/scripts/player.js") == testing::read_all(stdfs::path(proj) / "scripts" / "player.js"));
    CHECK(r->pack.empty());
    CHECK_FALSE(r->to_json().contains("pack"));
}

TEST_CASE("export: the project's own README.md is not part of any export, a README.md deeper in the project is") {
    testing::TempDir tmp;
    const std::string proj = make_project(tmp);
    testing::write_all(stdfs::path(proj) / "Readme.MD", "other capitalization");
    auto r = export_project(options_for(tmp, proj, "windows", false));
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    const std::string game = tmp.sub("out/pack-test-windows/game");
    CHECK_FALSE(stdfs::exists(game + "/README.md"));
    CHECK_FALSE(stdfs::exists(game + "/Readme.MD"));
    CHECK(stdfs::exists(game + "/data/README.md"));
}
