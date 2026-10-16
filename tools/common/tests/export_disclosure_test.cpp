// Export: AI_CONTENT_DISCLOSURE.md next to a game that has assets made with AI (fa/tooling/ai_disclosure.h).
#include <doctest.h>

#include <algorithm>
#include <filesystem>

#include "fa/core/image.h"
#include "fa/tooling/export.h"
#include "fa/tooling/scaffold.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// A 2d-platformer project in tmp/proj with one picture, and a fake desktop player, so the export needs no built player.
struct DisclosureFixture {
    testing::TempDir tmp;
    std::string proj = tmp.sub("proj");
    DisclosureFixture() {
        auto r = create_project(proj, "2d-platformer");
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        testing::write_all(tmp.sub("fake_player/factoria_player"), "#!/bin/sh\nexit 0\n");
        Image img;
        img.width = img.height = 2;
        img.rgba.assign(16, 255);
        REQUIRE(save_png(img, (stdfs::path(proj) / "assets/potion.png").string()).ok());
    }
    Result<ExportReport> export_linux() {
        ExportOptions o;
        o.projectDir = proj;
        o.platform = "linux";
        o.outDir = tmp.sub("out");
        o.playerBinary = tmp.sub("fake_player/factoria_player");
        return export_project(o);
    }
    static bool mentions(const std::vector<std::string>& lines, const std::string& text) {
        return std::any_of(lines.begin(), lines.end(), [&](const std::string& l) { return l.find(text) != std::string::npos; });
    }
};

}  // namespace

TEST_CASE("export: a game with AI-made assets gets AI_CONTENT_DISCLOSURE.md at the top of the export") {
    DisclosureFixture f;
    testing::write_all(stdfs::path(f.proj) / "assets.json", R"({
      "format": "factoria.assets/1",
      "assets": {"assets/potion.png": {"provenance": {"origin": "generated", "ai": true, "kind": "image", "provider": "openai",
                                                       "model": "gpt-image-1", "prompt": "secret plans", "date": "2026-10-16"}}}
    })");
    auto r = f.export_linux();
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));

    const stdfs::path file = stdfs::path(f.tmp.sub("out/proj-linux")) / "AI_CONTENT_DISCLOSURE.md";
    REQUIRE(stdfs::exists(file));
    const std::string md = testing::read_all(file);
    CHECK(md.find("1 asset was made with AI tools.") != std::string::npos);
    CHECK(md.find("| Art and images | 1 | openai (gpt-image-1) |") != std::string::npos);
    CHECK(md.find("secret plans") == std::string::npos);  // prompts stay home
    CHECK(std::find(r->files.begin(), r->files.end(), "AI_CONTENT_DISCLOSURE.md") != r->files.end());
    CHECK(DisclosureFixture::mentions(r->nextSteps, "AI_CONTENT_DISCLOSURE.md"));
    // the shipped assets.json carries no provenance
    CHECK(testing::read_all(f.tmp.sub("out/proj-linux/game/assets.json")).find("openai") == std::string::npos);
}

TEST_CASE("export: no disclosure file without AI-made assets") {
    DisclosureFixture f;
    {
        auto r = f.export_linux();  // no assets.json at all
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        CHECK_FALSE(stdfs::exists(f.tmp.sub("out/proj-linux/AI_CONTENT_DISCLOSURE.md")));
        CHECK_FALSE(DisclosureFixture::mentions(r->nextSteps, "AI_CONTENT_DISCLOSURE"));
    }
    testing::write_all(stdfs::path(f.proj) / "assets.json", R"({
      "format": "factoria.assets/1",
      "assets": {"assets/potion.png": {"provenance": {"origin": "original", "ai": false, "date": "2026-10-16"}}}
    })");
    auto r = f.export_linux();
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK_FALSE(stdfs::exists(f.tmp.sub("out/proj-linux/AI_CONTENT_DISCLOSURE.md")));
    CHECK_FALSE(DisclosureFixture::mentions(r->nextSteps, "AI_CONTENT_DISCLOSURE"));
}
