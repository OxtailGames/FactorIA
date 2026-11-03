// Pixel art (docs/IMAGES.md, "Pixel art"): the drawing algorithms pixel by pixel, the palette lock and its errors, colour ramps, the
// indexed layer kind in an image document, and image.pixel / image.draw / image.palette / image.layer.convert.
#include <doctest.h>

#include <algorithm>
#include <set>

#include "asset_test_helpers.h"
#include "fa/tooling/image_doc.h"
#include "fa/tooling/pixel_art.h"

using namespace fa;
using namespace fa::testing;

namespace {

std::string draw(const std::vector<PixelPoint>& pts, int w, int h) {
    IndexGrid g(w, h);
    for (const PixelPoint& p : pts) g.set(p.x, p.y, 0);
    std::string out;
    for (const std::string& r : index_grid_rows(g)) out += r + "\n";
    return out;
}

PixelPalette sample_palette() {
    PixelPalette p;
    p.entries = {{"outline", {0x1a, 0x1c, 0x2c}}, {"skin-dark", {0xb0, 0x6a, 0x40}}, {"skin", {0xe0, 0xa0, 0x70}}, {"skin-light", {0xf8, 0xd0, 0xa8}}, {"sky", {0x38, 0xb7, 0x64}}};
    return p;
}

constexpr const char* kDoc = "assets/art/p.image.json";
constexpr const char* kPng = "assets/art/p.png";

Json palette_json() {
    return Json::array({{{"name", "outline"}, {"color", "#1a1c2c"}}, {{"name", "skin-dark"}, {"color", "#b06a40"}}, {{"name", "skin"}, {"color", "#e0a070"}}, {{"name", "skin-light"}, {"color", "#f8d0a8"}}, {{"name", "sky"}, {"color", "#38b764"}}});
}

void make_doc(const AssetsProject& p, int w = 16, int h = 16) {
    p.ok("image.create", {{"path", kDoc}, {"width", w}, {"height", h}, {"palette", palette_json()}, {"ramps", Json::array({Json::array({"skin-dark", "skin", "skin-light"})})}});
}

Json read_doc(const AssetsProject& p) { return parse_json(read_all(p.file(kDoc)), kDoc).value(); }

Json layer0(const AssetsProject& p) { return read_doc(p)["layers"][0]; }

std::string rows_text(const Json& layer) {
    std::string out;
    for (const Json& r : layer["rows"]) out += r.get<std::string>() + "\n";
    return out;
}

std::string error_of(const CommandResult& r) { return r.error["message"].get<std::string>() + " " + r.error.value("hint", std::string()); }

}  // namespace

TEST_CASE("pixel_line: Bresenham, both ends, any direction") {
    CHECK(draw(pixel_line({0, 0}, {5, 0}), 6, 1) == "000000\n");
    CHECK(draw(pixel_line({0, 0}, {4, 4}), 5, 5) == "0....\n.0...\n..0..\n...0.\n....0\n");
    CHECK(draw(pixel_line({0, 0}, {6, 2}), 7, 3) == "00.....\n..000..\n.....00\n");
    const auto fwd = pixel_line({1, 4}, {7, 0});
    auto back = pixel_line({7, 0}, {1, 4});
    CHECK(fwd.front() == PixelPoint{1, 4});
    CHECK(fwd.back() == PixelPoint{7, 0});
    std::reverse(back.begin(), back.end());
    CHECK(std::set<PixelPoint>(fwd.begin(), fwd.end()).size() == fwd.size());
    CHECK(pixel_line({3, 3}, {3, 3}).size() == 1);
}

TEST_CASE("pixel_perfect removes the L corners of a bending line") {
    const auto chain = pixel_polyline({{0, 0}, {3, 0}, {3, 3}}, false);
    const auto perfect = pixel_polyline({{0, 0}, {3, 0}, {3, 3}}, true);
    CHECK(chain.size() == 7);
    CHECK(perfect.size() == 6);   // the corner pixel (3,0) touches both neighbours diagonally: dropped
    // a staircase has L-corners
    const std::vector<PixelPoint> stairs = {{0, 0}, {1, 0}, {1, 1}, {2, 1}, {2, 2}};
    const auto fixed = pixel_perfect(stairs);
    CHECK(fixed.size() == 3);
    CHECK(draw(fixed, 3, 3) == "0..\n.0.\n..0\n");
    CHECK(pixel_perfect({{0, 0}}).size() == 1);
}

TEST_CASE("pixel_rect: outline and filled, no duplicates") {
    CHECK(draw(pixel_rect(1, 1, 4, 3, false), 6, 5) == "......\n.0000.\n.0..0.\n.0000.\n......\n");
    CHECK(draw(pixel_rect(1, 1, 4, 3, true), 6, 5) == "......\n.0000.\n.0000.\n.0000.\n......\n");
    CHECK(pixel_rect(0, 0, 1, 1, false).size() == 1);
    CHECK(pixel_rect(0, 0, 5, 1, false).size() == 5);
    const auto o = pixel_rect(0, 0, 6, 6, false);
    CHECK(std::set<PixelPoint>(o.begin(), o.end()).size() == o.size());
}

TEST_CASE("pixel_ellipse: symmetric, inside its box, filled covers the outline") {
    for (auto [w, h] : {std::pair{7, 7}, {8, 8}, {9, 5}, {10, 4}, {1, 6}, {2, 2}, {12, 12}}) {
        CAPTURE(w);
        CAPTURE(h);
        const auto outline = pixel_ellipse(3, 2, w, h, false);
        const auto filled = pixel_ellipse(3, 2, w, h, true);
        const std::set<PixelPoint> o(outline.begin(), outline.end()), f(filled.begin(), filled.end());
        CHECK(o.size() == outline.size());
        CHECK(f.size() == filled.size());
        for (const PixelPoint& p : f) {
            CHECK(p.x >= 3);
            CHECK(p.x < 3 + w);
            CHECK(p.y >= 2);
            CHECK(p.y < 2 + h);
            CHECK(f.count({3 + (3 + w - 1) - p.x, p.y}) == 1);   // mirrored left-right
            CHECK(f.count({p.x, 2 + (2 + h - 1) - p.y}) == 1);   // mirrored top-bottom
        }
        for (const PixelPoint& p : o) CHECK(f.count(p) == 1);
    }
    CHECK(draw(pixel_ellipse(0, 0, 5, 5, true), 5, 5) == ".000.\n00000\n00000\n00000\n.000.\n");
    // a circle of diameter 7 touches the middle of every side
    const auto c = pixel_ellipse(0, 0, 7, 7, false);
    CHECK(std::count(c.begin(), c.end(), PixelPoint{3, 0}) == 1);
    CHECK(std::count(c.begin(), c.end(), PixelPoint{0, 3}) == 1);
    CHECK(std::count(c.begin(), c.end(), PixelPoint{3, 3}) == 0);
}

TEST_CASE("pixel_polygon: outline and even-odd fill") {
    const std::vector<PixelPoint> tri = {{0, 0}, {6, 0}, {0, 6}};
    const auto filled = pixel_polygon(tri, true);
    const auto outline = pixel_polygon(tri, false);
    const std::set<PixelPoint> f(filled.begin(), filled.end());
    CHECK(f.count({1, 1}) == 1);
    CHECK(f.count({5, 5}) == 0);
    for (const PixelPoint& p : outline) CHECK(f.count(p) == 1);
    CHECK(f.size() > outline.size());
    const auto square = pixel_polygon({{1, 1}, {4, 1}, {4, 4}, {1, 4}}, true);
    CHECK(draw(square, 6, 6) == "......\n.0000.\n.0000.\n.0000.\n.0000.\n......\n");
}

TEST_CASE("pixel_flood: 4 and 8 connectivity") {
    IndexGrid g(5, 5);
    for (int i = 0; i < 5; ++i) g.set(i, i, 1);   // a diagonal wall of index 1
    // 4-connected fill from the lower-left stays below the diagonal
    const auto four = pixel_flood(g, 0, 4, false);
    const auto eight = pixel_flood(g, 0, 4, true);
    CHECK(four.size() == 10);
    CHECK(eight.size() == 20);  // 8 neighbours slip through the diagonal wall to the other side
    IndexGrid h(3, 3);
    h.set(1, 0, 1);
    h.set(0, 1, 1);
    h.set(2, 1, 1);
    h.set(1, 2, 1);
    CHECK(pixel_flood(h, 1, 1, false).size() == 1);   // the centre is cut off for 4 neighbours
    CHECK(pixel_flood(h, 0, 0, true).size() == 5);    // 8 neighbours reach the other corners across the diagonals
    CHECK(pixel_flood(h, 9, 9, false).empty());
    CHECK(pixel_flood(h, 0, 0, false).size() == 1);
}

TEST_CASE("index grid rows round trip and teach on a bad character") {
    IndexGrid g(4, 2);
    g.set(0, 0, 0);
    g.set(3, 0, 12);
    g.set(1, 1, 80);
    const auto rows = index_grid_rows(g);
    CHECK(rows == std::vector<std::string>{"0..c", ".~.."});
    auto back = index_grid_from_rows(rows, 81);
    REQUIRE(back.ok());
    CHECK(back->v == g.v);
    auto bad = index_grid_from_rows({"0.1", "0 1"}, 4);
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("Row 1") != std::string::npos);
    auto ragged = index_grid_from_rows({"0.1", "0."}, 4);
    CHECK_FALSE(ragged.ok());
    auto range = index_grid_from_rows({"05"}, 3);
    REQUIRE_FALSE(range.ok());
    CHECK(range.error().message.find("3 colours") != std::string::npos);
}

TEST_CASE("palette lock: a colour outside the palette names the nearest one") {
    const PixelPalette pal = sample_palette();
    CHECK(*pixel_palette_find(pal, Json("skin"), false) == 2);
    CHECK(*pixel_palette_find(pal, Json(3), false) == 3);
    CHECK(*pixel_palette_find(pal, Json("#E0A070"), false) == 2);
    CHECK(*pixel_palette_find(pal, Json("4"), false) == 4);
    CHECK(*pixel_palette_find(pal, Json(), true) == -1);
    CHECK(*pixel_palette_find(pal, Json("."), true) == -1);
    CHECK_FALSE(pixel_palette_find(pal, Json(), false).ok());
    auto off = pixel_palette_find(pal, Json("#e0a071"), false);
    REQUIRE_FALSE(off.ok());
    CHECK(off.error().message.find("skin") != std::string::npos);
    auto typo = pixel_palette_find(pal, Json("skn"), false);
    REQUIRE_FALSE(typo.ok());
    CHECK((typo.error().message + " " + typo.error().hint).find("skin") != std::string::npos);
    auto range = pixel_palette_find(pal, Json(9), false);
    CHECK_FALSE(range.ok());
}

TEST_CASE("ramps: a declared ramp is followed, otherwise the step is derived by lightness") {
    PixelPalette pal = sample_palette();
    pal.ramps = {{1, 2, 3}};
    CHECK(pal.step(2, -1) == 1);
    CHECK(pal.step(2, 1) == 3);
    CHECK(pal.step(1, -1) == 1);    // stops at the end
    CHECK(pal.step(1, 5) == 3);
    CHECK(pal.step(1, 0) == 1);
    CHECK(pal.ramp_of(3)->second == 2);
    CHECK_FALSE(pal.ramp_of(0).has_value());
    // outside any ramp: the nearest colour that is darker / lighter
    PixelPalette plain = sample_palette();
    CHECK(plain.step(2, -1) == 1);
    CHECK(plain.step(2, 1) == 3);
    CHECK(plain.step(0, -1) == 0);   // the darkest has no darker one
    // deterministic
    CHECK(plain.step(4, 1) == plain.step(4, 1));
}

TEST_CASE("an indexed layer bakes through the compositor and rejects bad rows with a pointer") {
    AssetsProject p;
    make_doc(p);
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "sprite"}, {"create", true}, {"pixels", Json::array({Json::array({3, 4, "skin"}), Json::array({4, 4, 0})})}});
    const Image img = read_png(p.file(kPng));
    REQUIRE(img.width == 16);
    auto px = [&](int x, int y) { return Rgba{img.rgba[(y * 16 + x) * 4], img.rgba[(y * 16 + x) * 4 + 1], img.rgba[(y * 16 + x) * 4 + 2], img.rgba[(y * 16 + x) * 4 + 3]}; };
    CHECK(px(3, 4).r == 0xe0);
    CHECK(px(3, 4).g == 0xa0);
    CHECK(px(3, 4).a == 255);
    CHECK(px(4, 4).r == 0x1a);
    CHECK(px(5, 4).a == 0);
    // a hand-written document with a row index beyond the palette is refused with a pointer
    Json doc = read_doc(p);
    doc["layers"][0]["rows"][0] = "9...............";
    write_all(p.file(kDoc), doc.dump(2));
    Json r = p.ok("image.info", {{"path", kDoc}});
    CHECK(r["valid"] == false);
    CHECK(r["problems"].dump().find("/layers/0/rows") != std::string::npos);
    CHECK(r["problems"].dump().find("5 colours") != std::string::npos);
    auto baked = p.call("image.bake", {{"path", kDoc}});
    REQUIRE_FALSE(baked.ok);
    CHECK(error_of(baked).find("/layers/0/rows") != std::string::npos);
}

TEST_CASE("image.pixel: pixels, runs, stamp, relative steps, regions") {
    AssetsProject p;
    make_doc(p, 8, 4);
    Json r = p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"create", true}, {"pixels", Json::array({Json::array({0, 0, "skin"})})},
                                  {"runs", Json::array({Json::array({2, 1, 4, "outline"})})},
                                  {"stamp", {{"x", 5}, {"y", 2}, {"rows", Json::array({"12", "3."})}}}});
    CHECK(r["pixelsSet"] == 4 + 1 + 3);
    CHECK(r["changed"] == true);
    CHECK(rows_text(layer0(p)) == "2.......\n..0000..\n.....12.\n.....3..\n");
    // relative step: one darker, on the pixel as it is
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"pixels", Json::array({Json::array({0, 0, {{"step", -1}}}), Json::array({1, 0, {{"step", -1}}})})}});
    CHECK(rows_text(layer0(p)).substr(0, 8) == "1.......");
    // {"color": "skin", "step": 1} is skin-light
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"pixels", Json::array({Json::array({7, 3, {{"color", "skin"}, {"step", 1}}})})}});
    CHECK(rows_text(layer0(p)).back() == '\n');
    CHECK(rows_text(layer0(p)).find(".....3.3") != std::string::npos);
    // erase with null
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"pixels", Json::array({Json::array({2, 1, nullptr})})}});
    CHECK(rows_text(layer0(p)).find("..") != std::string::npos);
    CHECK(layer0(p)["rows"][1] == "...000..");
    // pixels outside are dropped and reported
    Json out = p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"pixels", Json::array({Json::array({99, 0, 1})})}});
    CHECK(has_warning(out, "outside"));
}

TEST_CASE("image.pixel teaches: colour outside the palette, unknown name, wrong layer kind, missing layer") {
    AssetsProject p;
    make_doc(p);
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"create", true}, {"pixels", Json::array({Json::array({0, 0, 1})})}});
    auto off = p.call("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"pixels", Json::array({Json::array({0, 0, "#e0a071"})})}});
    REQUIRE_FALSE(off.ok);
    CHECK(error_of(off).find("/pixels/0/2") != std::string::npos);
    CHECK(error_of(off).find("skin") != std::string::npos);
    auto typo = p.call("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"pixels", Json::array({Json::array({0, 0, "skn"})})}});
    REQUIRE_FALSE(typo.ok);
    CHECK(error_of(typo).find("skin") != std::string::npos);
    auto gone = p.call("image.pixel", {{"path", kDoc}, {"layer", "nope"}, {"pixels", Json::array({Json::array({0, 0, 1})})}});
    REQUIRE_FALSE(gone.ok);
    CHECK(error_of(gone).find("create") != std::string::npos);
    auto badKey = p.call("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"pixel", Json::array()}});
    REQUIRE_FALSE(badKey.ok);
    CHECK(error_of(badKey).find("pixels") != std::string::npos);
    p.ok("image.layer.add", {{"path", kDoc}, {"layer", {{"kind", "fill"}, {"name", "bg"}, {"color", "#000000"}}}});
    auto wrong = p.call("image.pixel", {{"path", kDoc}, {"layer", "bg"}, {"pixels", Json::array({Json::array({0, 0, 1})})}});
    REQUIRE_FALSE(wrong.ok);
    CHECK(error_of(wrong).find("not an indexed one") != std::string::npos);
    // the failed calls left the document as it was
    CHECK(read_doc(p)["layers"][0]["rows"][0].get<std::string>().substr(0, 1) == "1");
}

TEST_CASE("image.paint and image.edit refuse an indexed layer instead of anti-aliasing it") {
    AssetsProject p;
    make_doc(p);
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"create", true}, {"pixels", Json::array({Json::array({0, 0, 1})})}});
    auto paint = p.call("image.paint", {{"path", kDoc}, {"layer", "s"}, {"strokes", Json::array({{{"points", Json::array({Json::array({1, 1}), Json::array({8, 8})})}, {"color", "#ffffff"}}})}});
    REQUIRE_FALSE(paint.ok);
    CHECK(error_of(paint).find("indexed") != std::string::npos);
    CHECK(error_of(paint).find("image.draw") != std::string::npos);
}

TEST_CASE("image.draw: a 16x16 sprite, shape by shape") {
    AssetsProject p;
    make_doc(p);
    Json r = p.ok("image.draw", {{"path", kDoc}, {"layer", "sprite"}, {"create", true},
                                 {"shapes", Json::array({{{"type", "ellipse"}, {"x", 2}, {"y", 2}, {"width", 12}, {"height", 12}, {"fill", "skin"}, {"color", "outline"}},
                                                        {{"type", "rect"}, {"x", 5}, {"y", 5}, {"width", 2}, {"height", 2}, {"fill", "outline"}},
                                                        {{"type", "line"}, {"points", Json::array({Json::array({5, 10}), Json::array({8, 12}), Json::array({11, 10})})}, {"color", "outline"}, {"perfect", true}},
                                                        {{"type", "fill"}, {"at", Json::array({8, 8})}, {"color", "skin-light"}}})}});
    CHECK(r["region"]["width"].get<int>() > 0);
    CHECK(r["pixelsSet"].get<int>() > 50);
    CHECK(r.contains("$image"));
    const Json layer = layer0(p);
    CHECK(layer["rows"].size() == 16);
    const std::string text = rows_text(layer);
    CHECK(text.find('3') != std::string::npos);   // flood filled
    CHECK(layer["rows"][5].get<std::string>().substr(5, 2) == "00");
    // flood fill is bounded by the outline: the corner stays transparent
    CHECK(layer["rows"][0].get<std::string>()[0] == '.');
    // the same commands on a fresh project give the same bytes
    AssetsProject q;
    make_doc(q);
    q.ok("image.draw", {{"path", kDoc}, {"layer", "sprite"}, {"create", true}, {"shapes", Json::array({{{"type", "ellipse"}, {"x", 2}, {"y", 2}, {"width", 12}, {"height", 12}, {"fill", "skin"}, {"color", "outline"}},
                                                                                                        {{"type", "rect"}, {"x", 5}, {"y", 5}, {"width", 2}, {"height", 2}, {"fill", "outline"}},
                                                                                                        {{"type", "line"}, {"points", Json::array({Json::array({5, 10}), Json::array({8, 12}), Json::array({11, 10})})}, {"color", "outline"}, {"perfect", true}},
                                                                                                        {{"type", "fill"}, {"at", Json::array({8, 8})}, {"color", "skin-light"}}})}});
    CHECK(read_all(p.file(kPng)) == read_all(q.file(kPng)));
    CHECK(read_all(p.file(kDoc)) == read_all(q.file(kDoc)));
}

TEST_CASE("image.draw teaches: unknown shape, missing field, fill outside, bad connectivity") {
    AssetsProject p;
    make_doc(p);
    auto call = [&](Json shape) { return p.call("image.draw", {{"path", kDoc}, {"layer", "s"}, {"create", true}, {"shapes", Json::array({std::move(shape)})}}); };
    auto bad = call({{"type", "elipse"}, {"x", 0}});
    REQUIRE_FALSE(bad.ok);
    CHECK(error_of(bad).find("ellipse") != std::string::npos);
    CHECK(error_of(bad).find("/shapes/0/type") != std::string::npos);
    auto missing = call({{"type", "rect"}, {"x", 1}, {"y", 1}, {"width", 3}, {"color", 0}});
    REQUIRE_FALSE(missing.ok);
    CHECK(error_of(missing).find("height") != std::string::npos);
    auto outside = call({{"type", "fill"}, {"at", Json::array({40, 40})}, {"color", 1}});
    REQUIRE_FALSE(outside.ok);
    CHECK(error_of(outside).find("outside") != std::string::npos);
    auto conn = call({{"type", "fill"}, {"at", Json::array({1, 1})}, {"color", 1}, {"connectivity", 6}});
    REQUIRE_FALSE(conn.ok);
    CHECK(error_of(conn).find("4") != std::string::npos);
    auto frac = call({{"type", "line"}, {"points", Json::array({Json::array({0.5, 0}), Json::array({4, 4})})}, {"color", 0}});
    REQUIRE_FALSE(frac.ok);
    CHECK(error_of(frac).find("/points/0/0") != std::string::npos);
    auto colour = call({{"type", "line"}, {"points", Json::array({Json::array({0, 0}), Json::array({4, 4})})}, {"color", "#123456"}});
    REQUIRE_FALSE(colour.ok);
    CHECK(error_of(colour).find("nearest") != std::string::npos);
}

TEST_CASE("image.draw fills 4-connected by default and 8-connected on request") {
    AssetsProject p;
    make_doc(p, 5, 5);
    // a diagonal wall splits a 5x5 canvas
    Json diag = Json::array();
    for (int i = 0; i < 5; ++i) diag.push_back({{"type", "rect"}, {"x", i}, {"y", i}, {"width", 1}, {"height", 1}, {"color", "outline"}});
    p.ok("image.draw", {{"path", kDoc}, {"layer", "s"}, {"create", true}, {"shapes", diag}});
    // transparent pixels on both sides: 4-connected fills only one side
    p.ok("image.draw", {{"path", kDoc}, {"layer", "s"}, {"shapes", Json::array({{{"type", "fill"}, {"at", Json::array({0, 4})}, {"color", "sky"}}})}});
    const std::string t = rows_text(layer0(p));
    CHECK(t == "0....\n40...\n440..\n4440.\n44440\n");
}

TEST_CASE("image.palette reads, replaces and reports usage") {
    AssetsProject p;
    make_doc(p);
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"create", true}, {"pixels", Json::array({Json::array({0, 0, 2}), Json::array({1, 0, 2})})}});
    Json info = p.ok("image.palette", {{"path", kDoc}});
    CHECK(info["palette"]["source"] == "document");
    CHECK(info["palette"]["colors"].size() == 5);
    CHECK(info["palette"]["colors"][2]["used"] == 2);
    CHECK(info["palette"]["colors"][2]["shade"] == "skin-dark");
    CHECK(info["palette"]["colors"][2]["light"] == "skin-light");
    CHECK(info["palette"]["colors"][2]["char"] == "2");
    Json changed = p.ok("image.palette", {{"path", kDoc}, {"palette", Json::array({"#000000", "#ffffff", "#ff0000"})}, {"ramps", nullptr}});
    CHECK(has_warning(changed, "INDEX"));
    const Image img = read_png(p.file(kPng));
    CHECK(img.rgba[0] == 255);
    CHECK(img.rgba[1] == 0);
    auto dup = p.call("image.palette", {{"path", kDoc}, {"palette", Json::array({"#000000", "#000000"})}});
    CHECK_FALSE(dup.ok);
    // the palette shrank under the pixels: the document is refused with a pointer, not baked
    auto shrink = p.call("image.palette", {{"path", kDoc}, {"palette", Json::array({"#000000", "#ffffff"})}});
    REQUIRE_FALSE(shrink.ok);
    CHECK(error_of(shrink).find("/layers/0/rows") != std::string::npos);
}

TEST_CASE("the style palette is the default and is copied into the document on first use") {
    AssetsProject p;
    write_all(p.file("assets.json"), Json({{"style", {{"palette", Json::array({"#102030", "#405060", "#a0b0c0"})}}}}).dump(2));
    p.ok("image.create", {{"path", kDoc}, {"width", 4}, {"height", 4}});
    Json info = p.ok("image.palette", {{"path", kDoc}});
    CHECK(info["palette"]["source"] == "style");
    CHECK(info["palette"]["colors"].size() == 3);
    Json r = p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"create", true}, {"pixels", Json::array({Json::array({0, 0, 2})})}});
    CHECK(r.contains("palettePinned"));
    CHECK(read_doc(p)["palette"].size() == 3);
}

TEST_CASE("image.layer.convert: pixels -> indexed -> pixels") {
    AssetsProject p;
    make_doc(p, 8, 8);
    p.ok("image.layer.add", {{"path", kDoc}, {"layer", {{"kind", "fill"}, {"name", "box"}, {"color", "#e0a070"}, {"x", 2}, {"y", 2}, {"width", 3}, {"height", 3}}}});
    Json r = p.ok("image.layer.convert", {{"path", kDoc}, {"layer", "box"}, {"to", "indexed"}});
    CHECK(r["colorsUsed"] == 1);
    Json layer = layer0(p);
    CHECK(layer["kind"] == "indexed");
    CHECK(layer["name"] == "box");
    CHECK(layer["x"] == 2);
    CHECK(layer["y"] == 2);
    CHECK(rows_text(layer) == "222\n222\n222\n");
    const Image before = read_png(p.file(kPng));
    Json back = p.ok("image.layer.convert", {{"path", kDoc}, {"layer", "box"}, {"to", "pixels"}});
    CHECK(layer0(p)["kind"] == "pixels");
    const Image after = read_png(p.file(kPng));
    CHECK(before.rgba == after.rgba);
    auto same = p.call("image.layer.convert", {{"path", kDoc}, {"layer", "box"}, {"to", "pixels"}});
    CHECK_FALSE(same.ok);
    // a dithered conversion leaves palette colours alone: the round trip is exact
    p.ok("image.layer.convert", {{"path", kDoc}, {"layer", "box"}, {"to", "indexed"}, {"dither", "bayer4"}});
    CHECK(rows_text(layer0(p)) == "222\n222\n222\n");
    CHECK(read_png(p.file(kPng)).rgba == before.rgba);
}

TEST_CASE("image.layer.convert quantizes a gradient to the palette, with and without dither, deterministically") {
    auto run = [](const char* dither) {
        AssetsProject p;
        make_doc(p, 8, 4);
        p.ok("image.layer.add", {{"path", kDoc}, {"layer", {{"kind", "gradient"}, {"name", "g"}, {"gradient", {{"type", "linear"}, {"angle", 90}, {"stops", Json::array({{{"at", 0}, {"color", "#1a1c2c"}}, {{"at", 1}, {"color", "#f8d0a8"}}})}}}}}});
        p.ok("image.layer.convert", {{"path", kDoc}, {"layer", "g"}, {"to", "indexed"}, {"dither", dither}});
        return rows_text(layer0(p));
    };
    const std::string plain = run("none"), dithered = run("bayer4"), again = run("bayer4");
    CHECK(dithered == again);
    CHECK(plain.find('.') == std::string::npos);
    CHECK(plain != dithered);
    AssetsProject p;
    make_doc(p);
    p.ok("image.layer.add", {{"path", kDoc}, {"layer", {{"kind", "fill"}, {"name", "f"}, {"color", "#ffffff"}}}});
    auto bad = p.call("image.layer.convert", {{"path", kDoc}, {"layer", "f"}, {"to", "indexed"}, {"dither", "bayer5"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(error_of(bad).find("bayer4") != std::string::npos);
}
