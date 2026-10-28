// Export: the built-in fonts that are files (builtin:serif, ...) ship only in games that name them (tools/common/src/export_fonts.cpp).
#include <doctest.h>

#include <filesystem>

#include "fa/render/builtin_fonts.h"
#include "fa/tooling/export.h"
#include "fa/tooling/notices.h"
#include "fa/tooling/scaffold.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {
struct FontExport {
    testing::TempDir tmp;
    std::string proj = tmp.sub("proj");
    std::string player = tmp.sub("fake_player/factoria_player");
    FontExport() {
        auto r = create_project(proj, "2d-platformer");
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        testing::write_all(player, "#!/bin/sh\nexit 0\n");
    }
    stdfs::path game() { return tmp.path / "out/proj-linux/game"; }
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

TEST_CASE("export: a game that names no built-in font file ships none of them, and none of their licenses") {
    FontExport f;
    auto r = f.export_linux();
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r->builtinFonts.empty());
    CHECK_FALSE(stdfs::exists(f.game() / kBuiltinFontDir));
    const std::string notices = testing::read_all(f.game().parent_path() / kExportNoticesFile);
    CHECK(notices.find("Press Start 2P") != std::string::npos);  // the fonts inside the player are always listed
    for (const char* name : {"Crimson Text", "Kalam", "UnifrakturMaguntia", "IM Fell English"}) CHECK(notices.find(name) == std::string::npos);
}

TEST_CASE("export: only the built-in font families a scene or script names are copied, with their licenses") {
    FontExport f;
    testing::write_all(stdfs::path(f.proj) / "scripts/title.js", "const f = 'builtin:hand'; // 'builtin:handwriting' is not a font\n");
    testing::write_all(stdfs::path(f.proj) / "scenes/story.scene.json",
                       R"({"entities":[{"name":"t","components":{"Text":{"text":"x","font":"builtin:serif"}}}]})");
    auto r = f.export_linux();
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r->builtinFonts == std::vector<std::string>{"builtin:serif", "builtin:hand"});
    for (const char* file : {"CrimsonText-Regular.ttf", "CrimsonText-Bold.ttf", "CrimsonText-Italic.ttf", "CrimsonText-BoldItalic.ttf",
                             "Kalam-Regular.ttf", "Kalam-Bold.ttf"}) {
        CAPTURE(file);
        CHECK(stdfs::file_size(f.game() / kBuiltinFontDir / file) > 50000);
    }
    CHECK_FALSE(stdfs::exists(f.game() / kBuiltinFontDir / "UnifrakturMaguntia-Book.ttf"));
    CHECK_FALSE(stdfs::exists(f.game() / kBuiltinFontDir / "IMFeENrm28P.ttf"));
    CHECK_FALSE(stdfs::exists(stdfs::path(f.proj) / kBuiltinFontDir));  // the project folder is not touched
    const std::string notices = testing::read_all(f.game().parent_path() / kExportNoticesFile);
    CHECK(notices.find("\nCrimson Text (") != std::string::npos);
    CHECK(notices.find("\nKalam (") != std::string::npos);
    CHECK(notices.find("UnifrakturMaguntia") == std::string::npos);
    CHECK(notices.find("IM Fell English") == std::string::npos);
    CHECK(third_party_notices(NoticeScope::All).find("\nUnifrakturMaguntia (") != std::string::npos);  // the full list has all of them
}
