// assets.preview_sheet: a labelled grid of the frames of a sheet, plus the checks on them.
#include <doctest.h>

#include "asset_test_helpers.h"
#include "fa/core/screenshot_files.h"

using namespace fa;
using namespace fa::testing;

namespace {

std::string message(const CommandResult& r) { return r.error["message"].get<std::string>(); }
std::string hint(const CommandResult& r) { return r.error.value("hint", std::string()); }

// A walking square: frame i of `frames` draws a 6x6 block at x = 2 + i inside a 16x16 cell (a gutter of `pad`).
void write_walk(AssetsProject& p, const std::string& path, int frames, int pad, Json sheetExtra = Json::object()) {
    const int cell = 16 + 2 * pad;
    Image img = make_image(cell * frames, cell);
    for (int i = 0; i < frames; ++i) fill_rect(img, i * cell + pad + 2 + i, pad + 5, 6, 6, {200, 80, 40, 255});
    write_png(p.file(path), img);
    Json sheet = Json::object({{"columns", frames}, {"rows", 1}, {"frameWidth", 16}, {"frameHeight", 16}, {"frames", frames}});
    if (pad) sheet["padding"] = pad;
    for (auto it = sheetExtra.begin(); it != sheetExtra.end(); ++it) sheet[it.key()] = it.value();
    write_all(p.file("assets.json"),
              Json::object({{"format", 1}, {"assets", Json::object({{path, Json::object({{"sheet", sheet}})}})}}).dump());
}

}  // namespace

TEST_CASE("assets.preview_sheet: returns a temporary picture with the frames, grid and no warnings for a good sheet") {
    AssetsProject p;
    // a walk that does not loop: its last frame is far from its first, which is right for it
    write_walk(p, "assets/walk.png", 4, 0,
               Json{{"clips", Json::array({Json{{"name", "walk"}, {"firstFrame", 0}, {"lastFrame", 3}, {"fps", 8}, {"loop", false}}})}});
    const Json r = p.ok("assets.preview_sheet", Json{{"path", "assets/walk.png"}});
    CHECK(r["grid"]["columns"] == 4);
    CHECK(r["grid"]["cellWidth"] == 16);
    CHECK(r["shownFrames"] == 4);
    CHECK(r["warnings"].empty());
    REQUIRE(r.contains("$image"));
    CHECK(r["$image"]["temporary"] == true);
    const std::string file = r["$image"]["path"].get<std::string>();
    CHECK(is_engine_named_screenshot(std::filesystem::path(file).filename().string()));
    CHECK(std::filesystem::exists(file));
    const Image pic = read_png(file);
    CHECK(pic.width == r["picture"]["width"].get<int>());
    CHECK(pic.height == r["picture"]["height"].get<int>());
    CHECK(r["frames"][2]["frame"] == 2);
    CHECK(r["frames"][2]["bbox"] == Json::array({4, 5, 6, 6}));
}

TEST_CASE("assets.preview_sheet: padding, clips with pivots and an unknown clip with did you mean") {
    AssetsProject p;
    Json clips = Json::array({Json{{"name", "walk"}, {"firstFrame", 0}, {"lastFrame", 3}, {"fps", 8}, {"loop", false}, {"pivot", Json::array({0.5, 1.0})}},
                              Json{{"name", "idle"}, {"firstFrame", 4}, {"lastFrame", 5}, {"fps", 2}, {"loop", false}}});
    write_walk(p, "assets/hero.png", 6, 2, Json{{"clips", clips}, {"pivot", Json::array({0.0, 0.0})}});
    Json r = p.ok("assets.preview_sheet", Json{{"path", "assets/hero.png"}, {"clip", "idle"}, {"onion", true}});
    CHECK(r["shownFrames"] == 2);
    CHECK(r["frames"][0]["frame"] == 4);
    CHECK(r["grid"]["padding"] == 2);
    CHECK(r["grid"]["cellWidth"] == 20);
    CHECK(r["frames"][0]["bbox"] == Json::array({2 + 4, 5, 6, 6}));  // measured inside the frame, past the gutter
    CHECK(r["clips"][0]["pivot"] == Json::array({0.0, 0.0}));        // idle has no pivot of its own: the sheet's
    r = p.ok("assets.preview_sheet", Json{{"path", "assets/hero.png"}, {"clip", "walk"}});
    CHECK(r["clips"][0]["pivot"] == Json::array({0.5, 1.0}));

    const CommandResult bad = p.call("assets.preview_sheet", Json{{"path", "assets/hero.png"}, {"clip", "wlak"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(message(bad).find("no clip \"wlak\"") != std::string::npos);
    CHECK(hint(bad).find("walk, idle") != std::string::npos);
    CHECK(hint(bad).find("Did you mean") != std::string::npos);
}

TEST_CASE("assets.preview_sheet: warns of empty frames, cut shapes, a jumping bounding box and a loop seam") {
    AssetsProject p;
    // frame 0 empty; frame 1 touches the cell edge; frame 2 far to the right of frame 1... 
    Image img = make_image(16 * 5, 16);
    fill_rect(img, 16 + 0, 4, 6, 6, {255, 255, 255, 255});       // frame 1: on the left edge
    fill_rect(img, 32 + 9, 4, 6, 6, {255, 255, 255, 255});       // frame 2: jumped right
    fill_rect(img, 48 + 2, 4, 4, 4, {255, 255, 255, 255});       // frame 3
    fill_rect(img, 64 + 2, 4, 12, 10, {255, 255, 255, 255});     // frame 4: very different from frame 3
    write_png(p.file("assets/bad.png"), img);
    write_all(p.file("assets.json"),
              Json::object({{"format", 1}, {"assets", Json::object({{"assets/bad.png", Json::object({{"sheet", Json{{"columns", 5}, {"rows", 1}, {"frameWidth", 16}, {"frameHeight", 16}}}})}})}}).dump());
    const Json r = p.ok("assets.preview_sheet", Json{{"path", "assets/bad.png"}});
    CHECK(has_warning(r, "draw nothing (frame 0)"));
    CHECK(has_warning(r, "touch the edge of the cell in 1 frame(s) (frame 1)"));
    CHECK(has_warning(r, "bounding box moves"));

    // a looping clip whose last frame pops
    Image pop = make_image(16 * 5, 16);
    const int sizes[5] = {2, 3, 4, 5, 10};
    for (int i = 0; i < 5; ++i) fill_rect(pop, i * 16 + 8 - sizes[i] / 2, 8 - sizes[i] / 2, sizes[i], sizes[i], {255, 255, 255, 255});
    write_png(p.file("assets/pop.png"), pop);
    write_all(p.file("assets.json"),
              Json::object({{"format", 1}, {"assets", Json::object({{"assets/pop.png", Json::object({{"sheet", Json{{"columns", 5}, {"rows", 1}, {"frameWidth", 16}, {"frameHeight", 16},
                                                                                                                  {"clips", Json::array({Json{{"name", "grow"}, {"firstFrame", 0}, {"lastFrame", 4}, {"fps", 6}, {"loop", true}}})}}}})}})}}).dump());
    const Json q = p.ok("assets.preview_sheet", Json{{"path", "assets/pop.png"}});
    CHECK(has_warning(q, "The loop of clip \"grow\" jumps"));
}

TEST_CASE("assets.preview_sheet: warns when the grid does not match the image, and needs a grid when there is no entry") {
    AssetsProject p;
    write_png(p.file("assets/odd.png"), make_image(50, 16, {255, 0, 0, 255}));
    write_all(p.file("assets.json"),
              Json::object({{"format", 1}, {"assets", Json::object({{"assets/odd.png", Json::object({{"sheet", Json{{"columns", 3}, {"rows", 1}, {"frameWidth", 16}, {"frameHeight", 16}}}})}})}}).dump());
    const Json r = p.ok("assets.preview_sheet", Json{{"path", "assets/odd.png"}});
    CHECK(has_warning(r, "The grid does not match the image"));

    write_png(p.file("assets/plain.png"), make_image(32, 16, {0, 255, 0, 255}));
    const CommandResult none = p.call("assets.preview_sheet", Json{{"path", "assets/plain.png"}});
    REQUIRE_FALSE(none.ok);
    CHECK(hint(none).find("columns") != std::string::npos);
    const Json given = p.ok("assets.preview_sheet", Json{{"path", "assets/plain.png"}, {"columns", 2}, {"rows", 1}});
    CHECK(given["shownFrames"] == 2);
    CHECK(given["grid"]["fromSheetEntry"] == false);

    CHECK_FALSE(p.call("assets.preview_sheet", Json{{"path", "assets/missing.png"}}).ok);
    CHECK_FALSE(p.call("assets.preview_sheet", Json{{"path", "assets/plain.png"}, {"colums", 2}}).ok);
}

TEST_CASE("assets.preview_sheet: judges the sheet that assets.animate_svg makes, padding included") {
    AssetsProject p;
    write_all(p.file("art/pulse.anim.js"),
              "export default function frame({progress}) {\n"
              "  const r = 2 + Math.sin(progress * Math.PI * 2);\n"
              "  return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'><circle cx='5' cy='5' r='${r}' fill='#fff'/></svg>`;\n"
              "}\n");
    p.ok("assets.animate_svg", Json{{"path", "assets/pulse.png"}, {"source", "art/pulse.anim.js"}, {"frames", 6}, {"frameWidth", 24}, {"padding", 2}});
    const Json r = p.ok("assets.preview_sheet", Json{{"path", "assets/pulse.png"}});
    CHECK(r["warnings"].empty());
    CHECK(r["grid"]["padding"] == 2);
    CHECK(r["shownFrames"] == 6);
    CHECK_FALSE(r["frames"][0]["empty"].get<bool>());
}
