// Export: the asset steps (tools/common/src/export_assets.cpp) and the assets.json that ships.
#include <doctest.h>

#include <filesystem>

#include "fa/core/json.h"
#include "fa/tooling/export.h"
#include "fa/tooling/scaffold.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// A 2d-platformer project in tmp/proj and a fake desktop player, so the export needs no built player.
struct ExportFixture {
    testing::TempDir tmp;
    std::string proj = tmp.sub("proj");
    std::string player = tmp.sub("fake_player/factoria_player");
    ExportFixture() {
        auto r = create_project(proj, "2d-platformer");
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        testing::write_all(player, "#!/bin/sh\nexit 0\n");
    }
    Result<ExportReport> export_linux() {
        ExportOptions o;
        o.projectDir = proj;
        o.platform = "linux";
        o.outDir = tmp.sub("out");
        o.playerBinary = player;
        return export_project(o);
    }
};

}  // namespace

TEST_CASE("export: the shipped assets.json keeps import settings and drops provenance and style") {
    ExportFixture f;
    const char* manifest = R"({
      "format": "factoria.assets/1",
      "style": {"prompt": "pixel art"},
      "defaults": {"audio": {"normalize": true}},
      "assets": {
        "assets/tileset.png": {"provenance": {"origin": "generated", "date": "2026-10-16", "prompt": "secret plans"}},
        "assets/music.ogg": {"import": {"stream": "always"}, "provenance": {"origin": "original", "date": "2026-10-16"}}
      }
    })";
    testing::write_all(stdfs::path(f.proj) / "assets.json", manifest);

    auto r = f.export_linux();
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    const std::string shipped = testing::read_all(f.tmp.sub("out/proj-linux/game/assets.json"));
    auto j = parse_json(shipped);
    REQUIRE(j.ok());
    CHECK_FALSE(j->contains("style"));
    CHECK((*j)["defaults"]["audio"]["normalize"] == true);
    CHECK((*j)["assets"]["assets/music.ogg"]["import"]["stream"] == "always");
    CHECK_FALSE((*j)["assets"]["assets/music.ogg"].contains("provenance"));
    CHECK_FALSE((*j)["assets"].contains("assets/tileset.png"));  // nothing left but provenance
    CHECK(shipped.find("secret plans") == std::string::npos);
    // The project keeps its own file.
    CHECK(testing::read_all(stdfs::path(f.proj) / "assets.json") == manifest);
}

TEST_CASE("export: a project without assets.json ships none") {
    ExportFixture f;
    auto r = f.export_linux();
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK_FALSE(stdfs::exists(f.tmp.sub("out/proj-linux/game/assets.json")));
}
