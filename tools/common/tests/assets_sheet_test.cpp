// assets.slice_sheet: grid checks, finding and repacking uneven sprites, making a solid background transparent.
// The images are drawn here, pixel by pixel, so each expectation can be read off the code.
#include <doctest.h>

#include "asset_test_helpers.h"

using namespace fa;
using namespace fa::testing;

namespace {

const Rgba kRed{255, 0, 0, 255}, kGreen{0, 255, 0, 255}, kBlue{0, 0, 255, 255}, kClear{0, 0, 0, 0};

std::string message(const CommandResult& r) { return r.error["message"].get<std::string>(); }
std::string hint(const CommandResult& r) { return r.error["hint"].get<std::string>(); }

// Three sprites of different sizes on a transparent 40x12 image, all in one row:
// A 6x8 red at (2,2), B 10x4 green at (14,4), C 4x4 blue at (30,3).
Image uneven_sprites() {
    Image img = make_image(40, 12, kClear);
    fill_rect(img, 2, 2, 6, 8, kRed);
    fill_rect(img, 14, 4, 10, 4, kGreen);
    fill_rect(img, 30, 3, 4, 4, kBlue);
    return img;
}

}  // namespace

TEST_CASE("assets.slice_sheet: a grid is checked against the image and recorded") {
    AssetsProject p;
    Image sheet = make_image(64, 32, kClear);
    for (int f = 0; f < 8; ++f) fill_rect(sheet, (f % 4) * 16 + 6, (f / 4) * 16 + 6, 4, 4, kRed);
    write_png(p.file("assets/walk.png"), sheet);
    const std::string before = read_all(p.file("assets/walk.png"));

    const Json r = p.ok("assets.slice_sheet", {{"path", "assets/walk.png"}, {"columns", 4}, {"rows", 2}, {"fps", 12}});
    CHECK(r["mode"] == "grid");
    CHECK(r["path"] == "assets/walk.png");
    CHECK(r["written"] == false);
    CHECK(r["sheet"] == Json::object({{"columns", 4}, {"rows", 2}, {"frameWidth", 16}, {"frameHeight", 16}, {"frames", 8}}));
    CHECK(r["spriteAnimator"] == Json::object({{"columns", 4}, {"rows", 2}, {"firstFrame", 0}, {"lastFrame", 7}, {"fps", 12.0}, {"loop", true}}));
    CHECK_FALSE(r.contains("warnings"));
    CHECK(has_text(r["nextSteps"], "SpriteAnimator"));
    CHECK(read_all(p.file("assets/walk.png")) == before);  // the image is not touched
    CHECK(p.manifest()["assets"]["assets/walk.png"]["sheet"] == r["sheet"]);

    // The same grid by the size of a frame; `frames` leaves the last cells unused.
    const Json byFrame = p.ok("assets.slice_sheet", {{"path", "assets/walk.png"}, {"frameWidth", 32}, {"frameHeight", 16}, {"frames", 3}});
    CHECK(byFrame["sheet"]["columns"] == 2);
    CHECK(byFrame["sheet"]["rows"] == 2);
    CHECK(byFrame["sheet"]["frames"] == 3);
    CHECK(byFrame["spriteAnimator"]["lastFrame"] == 2);
    CHECK(p.manifest()["assets"]["assets/walk.png"]["sheet"]["frames"] == 3);
}

TEST_CASE("assets.slice_sheet: a grid that does not fit the image is an error that lists what fits") {
    AssetsProject p;
    write_png(p.file("assets/walk.png"), make_image(64, 32, kRed));

    CommandResult uneven = p.call("assets.slice_sheet", {{"path", "assets/walk.png"}, {"columns", 3}});
    REQUIRE_FALSE(uneven.ok);
    CHECK(message(uneven).find("cannot be cut into 3 columns") != std::string::npos);
    CHECK(hint(uneven).find("1, 2, 4, 8, 16, 32, 64") != std::string::npos);
    CHECK(hint(uneven).find("auto: true") != std::string::npos);

    CommandResult width = p.call("assets.slice_sheet", {{"path", "assets/walk.png"}, {"frameWidth", 10}});
    REQUIRE_FALSE(width.ok);
    CHECK(message(width).find("does not divide the image width (64 px)") != std::string::npos);
    CHECK(message(width).find("4 px are left over") != std::string::npos);

    CommandResult both = p.call("assets.slice_sheet", {{"path", "assets/walk.png"}, {"columns", 2}, {"frameWidth", 16}});
    REQUIRE_FALSE(both.ok);
    CHECK(message(both).find("disagree") != std::string::npos);

    CommandResult tooMany = p.call("assets.slice_sheet", {{"path", "assets/walk.png"}, {"columns", 4}, {"rows", 2}, {"frames", 9}});
    REQUIRE_FALSE(tooMany.ok);
    CHECK(message(tooMany).find("frames is 9 but a 4 x 2 grid has 8 cells") != std::string::npos);

    CommandResult missing = p.call("assets.slice_sheet", {{"path", "assets/nope.png"}, {"columns", 2}});
    REQUIRE_FALSE(missing.ok);
    CHECK(missing.error["code"] == "not_found");
    write_all(p.file("assets/text.png"), "this is not an image");
    CHECK_FALSE(p.call("assets.slice_sheet", {{"path", "assets/text.png"}, {"columns", 2}}).ok);
    CHECK_FALSE(p.exists("assets.json"));  // nothing was recorded
}

TEST_CASE("assets.slice_sheet: empty frames are reported") {
    AssetsProject p;
    Image sheet = make_image(64, 32, kClear);
    for (int f = 0; f < 4; ++f) fill_rect(sheet, f * 16 + 4, 4, 8, 8, kBlue);  // only the first row is drawn
    write_png(p.file("assets/half.png"), sheet);
    const Json r = p.ok("assets.slice_sheet", {{"path", "assets/half.png"}, {"columns", 4}, {"rows", 2}});
    REQUIRE(r.contains("warnings"));
    CHECK(has_warning(r, "4 of the 8 frames are empty (frames 4, 5, 6, 7)"));
    // Counting only the drawn frames is fine.
    CHECK_FALSE(p.ok("assets.slice_sheet", {{"path", "assets/half.png"}, {"columns", 4}, {"rows", 2}, {"frames", 4}}).contains("warnings"));
}

TEST_CASE("assets.slice_sheet: auto finds uneven sprites and repacks them into a uniform grid") {
    AssetsProject p;
    write_png(p.file("assets/raw.png"), uneven_sprites());
    const Json r = p.ok("assets.slice_sheet", {{"path", "assets/raw.png"}, {"auto", true}, {"frames", 3}});
    CHECK(r["mode"] == "auto");
    CHECK(r["path"] == "assets/raw_sheet.png");
    CHECK(r["written"] == true);
    CHECK(r["imageSize"] == Json::array({30, 8}));
    CHECK(r["sheet"] == Json::object({{"columns", 3}, {"rows", 1}, {"frameWidth", 10}, {"frameHeight", 8}, {"frames", 3}}));
    CHECK(r["foundSprites"] == Json::array({Json::array({2, 2, 6, 8}), Json::array({14, 4, 10, 4}), Json::array({30, 3, 4, 4})}));
    CHECK(r["spriteAnimator"]["lastFrame"] == 2);
    CHECK(has_text(r["nextSteps"], "assets/raw_sheet.png"));

    const Image out = read_png(p.file("assets/raw_sheet.png"));
    REQUIRE(out.width == 30);
    REQUIRE(out.height == 8);
    // Centred in 10x8 cells: A (6x8) at x 2, B (10x4) at y 2, C (4x4) at x 3, y 2 of the third cell.
    CHECK(get(out, 2, 0) == kRed);
    CHECK(get(out, 7, 7) == kRed);
    CHECK(get(out, 1, 0) == kClear);
    CHECK(get(out, 10, 2) == kGreen);
    CHECK(get(out, 19, 5) == kGreen);
    CHECK(get(out, 10, 1) == kClear);
    CHECK(get(out, 23, 2) == kBlue);
    CHECK(get(out, 26, 5) == kBlue);
    CHECK(get(out, 22, 2) == kClear);
    CHECK(read_all(p.file("assets/raw.png")) == png_string(uneven_sprites()));  // the source is kept
    CHECK(p.manifest()["assets"]["assets/raw_sheet.png"]["sheet"] == r["sheet"]);

    // align bottom puts every sprite on the ground line; columns wraps the new sheet; out names the file.
    const Json bottom = p.ok("assets.slice_sheet", {{"path", "assets/raw.png"}, {"auto", true}, {"align", "bottom"}, {"columns", 2}, {"out", "assets/ground.png"}});
    CHECK(bottom["path"] == "assets/ground.png");
    CHECK(bottom["sheet"]["columns"] == 2);
    CHECK(bottom["sheet"]["rows"] == 2);
    const Image ground = read_png(p.file("assets/ground.png"));
    REQUIRE(ground.width == 20);
    REQUIRE(ground.height == 16);
    CHECK(get(ground, 10, 4) == kGreen);  // B: 4 rows tall, in the bottom half of its 8 row cell
    CHECK(get(ground, 10, 3) == kClear);
    CHECK(get(ground, 10, 7) == kGreen);
    CHECK(get(ground, 3, 15) == kBlue);  // C: second row, first column, bottom aligned
    CHECK(get(ground, 3, 12) == kBlue);
    CHECK(get(ground, 3, 11) == kClear);
}

TEST_CASE("assets.slice_sheet: auto groups sprites into rows and keeps detached parts with their sprite") {
    AssetsProject p;
    Image img = make_image(40, 30, kClear);
    // Row 1: a hollow frame with a dot inside (touching nothing, but inside the frame's box): one sprite; then a plain square.
    for (int i = 0; i < 10; ++i) {
        fill_rect(img, 2 + i, 2, 1, 1, kRed);
        fill_rect(img, 2 + i, 11, 1, 1, kRed);
        fill_rect(img, 2, 2 + i, 1, 1, kRed);
        fill_rect(img, 11, 2 + i, 1, 1, kRed);
    }
    fill_rect(img, 6, 6, 2, 2, kGreen);
    fill_rect(img, 20, 4, 6, 6, kBlue);
    // Row 2.
    fill_rect(img, 5, 20, 8, 6, kGreen);
    write_png(p.file("assets/rows.png"), img);

    const Json r = p.ok("assets.slice_sheet", {{"path", "assets/rows.png"}, {"auto", true}});
    CHECK(r["foundSprites"] == Json::array({Json::array({2, 2, 10, 10}), Json::array({20, 4, 6, 6}), Json::array({5, 20, 8, 6})}));
    CHECK(r["sheet"] == Json::object({{"columns", 2}, {"rows", 2}, {"frameWidth", 10}, {"frameHeight", 10}, {"frames", 3}}));
    CHECK(r["imageSize"] == Json::array({20, 20}));
    const Image out = read_png(p.file("assets/rows_sheet.png"));
    CHECK(get(out, 4, 4) == kGreen);  // the dot stayed inside the first frame
    CHECK(get(out, 10 + 2, 2) == kBlue);  // the square, centred in the second cell: (10-6)/2 = 2
    CHECK(get(out, 10 + 1, 2) == kClear);
    CHECK(get(out, 1, 10 + 2) == kGreen);  // the third sprite starts the second row, (10-8)/2 = 1
}

TEST_CASE("assets.slice_sheet: auto explains what it cannot do") {
    AssetsProject p;
    write_png(p.file("assets/raw.png"), uneven_sprites());

    CommandResult count = p.call("assets.slice_sheet", {{"path", "assets/raw.png"}, {"auto", true}, {"frames", 5}});
    REQUIRE_FALSE(count.ok);
    CHECK(message(count).find("Found 3 sprites but frames is 5") != std::string::npos);
    CHECK(message(count).find("[x 14, y 4, 10x4]") != std::string::npos);
    CHECK(hint(count).find("gutter") != std::string::npos);
    CommandResult fewer = p.call("assets.slice_sheet", {{"path", "assets/raw.png"}, {"auto", true}, {"frames", 2}});
    REQUIRE_FALSE(fewer.ok);
    CHECK(hint(fewer).find("Specks") != std::string::npos);

    CommandResult grid = p.call("assets.slice_sheet", {{"path", "assets/raw.png"}, {"auto", true}, {"rows", 2}});
    REQUIRE_FALSE(grid.ok);
    CHECK(message(grid).find("describe a grid") != std::string::npos);

    write_png(p.file("assets/empty.png"), make_image(16, 16, kClear));
    CommandResult empty = p.call("assets.slice_sheet", {{"path", "assets/empty.png"}, {"auto", true}});
    REQUIRE_FALSE(empty.ok);
    CHECK(message(empty).find("no visible pixel") != std::string::npos);

    write_png(p.file("assets/solid.png"), make_image(16, 16, kRed));
    CommandResult solid = p.call("assets.slice_sheet", {{"path", "assets/solid.png"}, {"auto", true}});
    REQUIRE_FALSE(solid.ok);
    CHECK(message(solid).find("one single sprite") != std::string::npos);
    CHECK(hint(solid).find("background") != std::string::npos);

    CommandResult notPng = p.call("assets.slice_sheet", {{"path", "assets/raw.png"}, {"auto", true}, {"out", "assets/raw.jpg"}});
    REQUIRE_FALSE(notPng.ok);
    CHECK(message(notPng).find(".png") != std::string::npos);
    CHECK_FALSE(p.exists("assets/raw_sheet.png"));
}

TEST_CASE("assets.slice_sheet: background auto makes a solid background transparent") {
    AssetsProject p;
    const Rgba backdrop{0, 255, 128, 255};
    Image img = make_image(30, 12, backdrop);
    fill_rect(img, 3, 2, 8, 8, kRed);
    fill_rect(img, 5, 4, 2, 2, backdrop);  // a hole inside a sprite: the same colour, but enclosed
    fill_rect(img, 18, 2, 6, 8, kBlue);
    write_png(p.file("assets/green.png"), img);

    const Json r = p.ok("assets.slice_sheet", {{"path", "assets/green.png"}, {"auto", true}, {"background", "auto"}, {"frames", 2}});
    CHECK(r["path"] == "assets/green_sheet.png");
    CHECK(r["sheet"]["frames"] == 2);
    CHECK(r["backgroundPixelsCleared"] == 30 * 12 - 8 * 8 - 6 * 8);  // the hole in the red sprite is not reached from outside
    const Image out = read_png(p.file("assets/green_sheet.png"));
    CHECK(get(out, 0, 0) == kRed);  // two cells of 8x8: the red sprite fills the first one
    CHECK(get(out, 2, 2) == backdrop);  // the enclosed pixels stay
    CHECK(get(out, 8, 0) == kClear);  // the blue sprite (6 wide) is centred in the second cell, and its sides are clear
    CHECK(get(out, 9, 0) == kBlue);
    CHECK(read_png(p.file("assets/green.png")).rgba == img.rgba);  // the source is kept

    // On a grid it also writes the transparent image next to the source, and the grid is checked on it.
    const Json grid = p.ok("assets.slice_sheet", {{"path", "assets/green.png"}, {"columns", 2}, {"background", "auto"}, {"out", "assets/clear.png"}});
    CHECK(grid["path"] == "assets/clear.png");
    CHECK(grid["written"] == true);
    CHECK(grid["sheet"]["frameWidth"] == 15);
    CHECK(read_png(p.file("assets/clear.png")).rgba[3] == 0);

    // Corners of different colours: nothing to guess.
    Image mixed = make_image(10, 10, kRed);
    fill_rect(mixed, 9, 9, 1, 1, kBlue);
    write_png(p.file("assets/mixed.png"), mixed);
    CommandResult bad = p.call("assets.slice_sheet", {{"path", "assets/mixed.png"}, {"auto", true}, {"background", "auto"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(message(bad).find("four corners") != std::string::npos);

    // Already transparent: left alone, with a note.
    write_png(p.file("assets/clean.png"), uneven_sprites());
    const Json clean = p.ok("assets.slice_sheet", {{"path", "assets/clean.png"}, {"auto", true}, {"background", "auto"}});
    CHECK(has_warning(clean, "already transparent"));
}

TEST_CASE("assets.slice_sheet: the provenance of the source follows the new sheet") {
    AssetsProject p;
    write_png(p.tmp.path / "art/raw.png", uneven_sprites());
    p.ok("assets.import", {{"source", (p.tmp.path / "art/raw.png").string()}, {"license", "CC-BY 4.0"}, {"author", "Ana"}, {"ai", false}});
    p.ok("assets.slice_sheet", {{"path", "assets/raw.png"}, {"auto", true}});
    const Json entry = p.manifest()["assets"]["assets/raw_sheet.png"];
    CHECK(entry["provenance"]["license"] == "CC-BY 4.0");
    CHECK(entry["provenance"]["author"] == "Ana");
    CHECK(entry["provenance"]["origin"] == "imported");
    CHECK(entry["provenance"]["notes"].get<std::string>().find("Sliced from assets/raw.png") != std::string::npos);
    CHECK(entry["sheet"]["frames"] == 3);

    // A broken assets.json stops the command before it writes anything.
    write_all(p.file("assets.json"), "{ nope");
    CommandResult broken = p.call("assets.slice_sheet", {{"path", "assets/raw.png"}, {"auto", true}, {"out", "assets/again.png"}});
    REQUIRE_FALSE(broken.ok);
    CHECK_FALSE(p.exists("assets/again.png"));
}
