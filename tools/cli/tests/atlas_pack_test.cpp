// assets.pack_atlas end to end: a Sprite whose `region` is a frame's rect from the table draws that frame (and not its neighbour)
// from the packed PNG. Rendered headless like the other acceptance tests; skipped where there is no GPU.
#include <doctest.h>

#include <filesystem>

#include "common.h"  // tools/cli/src: Session
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/tooling/asset_import.h"
#include "fa/tooling/scaffold.h"

namespace stdfs = std::filesystem;

namespace {

void write_solid(const stdfs::path& p, int w, int h, std::uint8_t r, std::uint8_t g, std::uint8_t b) {
    fa::Image img;
    img.width = w;
    img.height = h;
    img.rgba.resize(std::size_t(w) * h * 4);
    for (std::size_t i = 0; i < img.rgba.size(); i += 4) {
        img.rgba[i] = r;
        img.rgba[i + 1] = g;
        img.rgba[i + 2] = b;
        img.rgba[i + 3] = 255;
    }
    REQUIRE(fa::save_png(img, p.generic_string()).ok());
}

}  // namespace

TEST_CASE("A Sprite with a region from the packed table draws that frame") {
    const stdfs::path oldRoot = fa::fs::project_root();
    const stdfs::path tmp = fa::fs::make_temp_dir("fa_cli_atlas_pack");
    const std::string project = (tmp / "game").string();
    fa::ScaffoldOptions opt;
    opt.writeTypings = false;
    REQUIRE(fa::create_project(project, "2d-empty", opt).ok());

    write_solid(tmp / "game" / "art" / "red.png", 24, 24, 255, 0, 0);
    write_solid(tmp / "game" / "art" / "green.png", 20, 28, 0, 255, 0);
    write_solid(tmp / "game" / "art" / "blue.png", 16, 16, 0, 0, 255);
    fa::CommandRegistry registry;
    fa::register_asset_commands(registry, project);
    const fa::CommandResult packed = registry.call("assets.pack_atlas", {{"folder", "art"}, {"out", "assets/atlas.png"}, {"table", "data/atlas.json"}});
    REQUIRE_MESSAGE(packed.ok, packed.error.dump());
    auto text = fa::fs::read_text((tmp / "game" / "data" / "atlas.json").generic_string());
    REQUIRE(text.ok());
    const fa::Json table = fa::Json::parse(*text);
    const fa::Json rect = table["frames"]["green"]["rect"];

    fa::Json scene = fa::Json::parse(*fa::fs::read_text((tmp / "game" / "scenes" / "main.scene.json").generic_string()));
    scene["entities"].push_back({{"id", "frame"},
                                 {"components", {{"Transform", {{"position", {0, 0, 0}}}},
                                                 {"Sprite", {{"texture", table["texture"]}, {"region", rect}, {"size", {40, 40}}, {"pixelArt", true}}}}}});
    REQUIRE(fa::fs::write_text((tmp / "game" / "scenes" / "main.scene.json").generic_string(), scene.dump(1)).ok());

    fa::cli::SessionOptions so;
    so.gfx = fa::cli::Gfx::Auto;
    so.width = 320;
    so.height = 180;
    auto session = fa::cli::Session::open(project, so);
    if (!session->has_graphics()) {
        MESSAGE("no GPU on this machine: the render part of the test is skipped");
        fa::fs::set_project_root(oldRoot);
        std::error_code ec;
        stdfs::remove_all(tmp, ec);
        return;
    }
    session->engine().step(10);
    const stdfs::path shot = tmp / "shot.png";
    std::string err;
    REQUIRE_MESSAGE(session->engine().screenshot(shot.generic_string(), &err), err);
    auto img = fa::load_image(shot.generic_string());
    REQUIRE(img.ok());
    int green = 0, other = 0;
    for (std::size_t i = 0; i < img->rgba.size(); i += 4) {
        const std::uint8_t r = img->rgba[i], g = img->rgba[i + 1], b = img->rgba[i + 2];
        if (r < 8 && g > 247 && b < 8) ++green;
        if (r > 200 && g < 60 && b < 60) ++other;  // the red frame next to it
        if (r < 60 && g < 60 && b > 200) ++other;  // the blue one
    }
    CHECK(green > 400);
    CHECK(other == 0);
    const std::size_t centre = (std::size_t(img->height / 2) * img->width + img->width / 2) * 4;
    CHECK(img->rgba[centre] < 8);
    CHECK(img->rgba[centre + 1] > 247);
    CHECK(img->rgba[centre + 2] < 8);

    session.reset();
    fa::fs::set_project_root(oldRoot);
    std::error_code ec;
    stdfs::remove_all(tmp, ec);
}
