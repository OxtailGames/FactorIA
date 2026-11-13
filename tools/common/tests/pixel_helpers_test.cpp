// Pixel helpers (docs/IMAGES.md, "Pixel helpers"): the algorithms of fa/tooling/pixel_art.h on small crafted sprites with exact rows,
// and the commands image.pixel.outline / shade / dither / cleanup / rotate / scale and image.to_pixel_art.
#include <doctest.h>

#include <cstdio>
#include <set>

#include "asset_test_helpers.h"
#include "fa/tooling/pixel_art.h"

using namespace fa;
using namespace fa::testing;
using namespace std::string_literals;

namespace {

PixelPalette pal5() {
    PixelPalette p;
    p.entries = {{"outline", {0x1a, 0x1c, 0x2c}}, {"skin-dark", {0xb0, 0x6a, 0x40}}, {"skin", {0xe0, 0xa0, 0x70}}, {"skin-light", {0xf8, 0xd0, 0xa8}}, {"sky", {0x38, 0xb7, 0x64}}};
    p.ramps = {{1, 2, 3}};
    return p;
}

IndexGrid G(std::vector<std::string> rows) { return index_grid_from_rows(rows, -1).value(); }

std::string T(const IndexGrid& g) {
    std::string out;
    for (const std::string& r : index_grid_rows(g)) out += r + "|";
    return out;
}

}  // namespace


namespace {
const PixelMask kNoMask;
}

TEST_CASE("pixel_outline: outer 4- and 8-connected, inner, flat colour") {
    const PixelPalette p = pal5();
    const IndexGrid sq = G({"....", ".22.", ".22.", "...."});
    PixelOutline o;
    o.color = 0;
    IndexGrid g = sq;
    CHECK(pixel_outline(g, p, o) == 8);
    CHECK(T(g) == ".00.|0220|0220|.00.|");   // 4-connected: the corners stay open
    g = sq;
    o.eightConnected = true;
    CHECK(pixel_outline(g, p, o) == 12);
    CHECK(T(g) == "0000|0220|0220|0000|");
    g = G({".....", ".222.", ".222.", ".222.", "....."});
    o.inner = true;
    o.eightConnected = false;
    CHECK(pixel_outline(g, p, o) == 8);
    CHECK(T(g) == ".....|.000.|.020.|.000.|.....|");
}

TEST_CASE("pixel_outline: darkest of the ramp and selective sel-out") {
    const PixelPalette p = pal5();
    IndexGrid g = G({"......", ".2222.", ".2222.", ".2222.", ".2222.", "......"});
    PixelOutline o;
    o.colour = PixelOutline::Colour::RampDarkest;
    pixel_outline(g, p, o);
    CHECK(T(g) == ".1111.|122221|122221|122221|122221|.1111.|");   // skin-dark, the darkest of the skin ramp
    // sel-out: the lightest fill, 2 steps darker on the shadow side, 1 step on the side facing the upper-left light
    g = G({"......", ".3333.", ".3333.", ".3333.", ".3333.", "......"});
    o = PixelOutline{};
    o.colour = PixelOutline::Colour::Selective;
    o.shade = 2;
    o.litShade = 1;
    o.hasLight = true;
    o.lightDegrees = 135;
    pixel_outline(g, p, o);
    CHECK(T(g) == ".2222.|233331|233331|233331|233331|.1111.|");
    // without a light every pixel is `shade` steps darker
    g = G({"......", ".3333.", ".3333.", ".3333.", ".3333.", "......"});
    o.hasLight = false;
    pixel_outline(g, p, o);
    CHECK(T(g) == ".1111.|133331|133331|133331|133331|.1111.|");
    // a selection limits what is written
    g = G({"....", ".22.", ".22.", "...."});
    o = PixelOutline{};
    o.color = 0;
    PixelMask left(16, 0);
    for (int y = 0; y < 4; ++y) left[std::size_t(y) * 4] = 1;
    CHECK(pixel_outline(g, p, o, left) == 2);
    CHECK(T(g) == "....|022.|022.|....|");   // only the outline pixels in column 0
}

TEST_CASE("pixel_shade: shadow on the side away from the light, highlight on the side facing it") {
    const PixelPalette p = pal5();
    const std::vector<std::string> body = {"..........", ".22222222.", ".22222222.", ".22222222.", ".22222222.",
                                           ".22222222.", ".22222222.", ".22222222.", ".22222222.", ".........."};
    IndexGrid g = G(body);
    PixelShade s;
    s.lightDegrees = 135;   // upper-left
    s.shadowWidth = 2;
    s.highlightWidth = 1;
    CHECK(pixel_shade(g, p, s) > 0);
    CHECK(T(g) == "..........|.33333311.|.32222211.|.32222211.|.32222211.|.32222211.|.32222211.|.11111111.|.11111111.|..........|");
    // the light from the right flips the sides
    g = G(body);
    s.lightDegrees = 0;
    pixel_shade(g, p, s);
    CHECK(T(g).substr(0, 22) == "..........|.11222223.|");
    // a stored selection keeps the rest untouched
    g = G(body);
    PixelMask m(100, 0);
    for (int y = 1; y < 9; ++y)
        for (int x = 1; x < 5; ++x) m[std::size_t(y) * 10 + x] = 1;
    s.lightDegrees = 135;
    pixel_shade(g, p, s, m);
    CHECK(T(g).find("2222222") == std::string::npos);
    CHECK(index_grid_rows(g)[4] == ".32112222.");   // the selection is shaded as its own shape
}

TEST_CASE("pixel_shade: a dithered transition mixes the two bands and is deterministic") {
    const PixelPalette p = pal5();
    IndexGrid a = G({"..........", ".22222222.", ".22222222.", ".22222222.", ".22222222.", ".22222222.", ".22222222.", ".22222222.", ".22222222.", ".........."});
    IndexGrid b = a;
    PixelShade s;
    s.shadowWidth = 2;
    s.shadowLevels = 2;
    s.highlightLevels = 0;
    s.dither = 1;
    pixel_shade(a, p, s);
    pixel_shade(b, p, s);
    CHECK(T(a) == T(b));
    for (int v : a.v) CHECK((v == -1 || v == 1 || v == 2));   // never a colour outside the ramp steps
}

TEST_CASE("pixel_dither: checker and Bayer patterns, gradients, canvas-aligned origin") {
    IndexGrid g(8, 4);
    CHECK(pixel_dither_blend(g, 1, 2, 0.5, DitherPattern::Checker) == 32);
    CHECK(T(g) == "21212121|12121212|21212121|12121212|");
    pixel_dither_blend(g, 1, 2, 0.25, DitherPattern::Bayer4);
    CHECK(T(g) == "21212121|11111111|21212121|11111111|");
    pixel_dither_blend(g, 1, 2, 0.0, DitherPattern::Bayer4);
    CHECK(T(g) == "11111111|11111111|11111111|11111111|");
    pixel_dither_blend(g, 1, 2, 1.0, DitherPattern::Bayer8);
    CHECK(T(g) == "22222222|22222222|22222222|22222222|");
    // two layers dithered alike match: the origin shifts the pattern
    IndexGrid shifted(8, 4);
    pixel_dither_blend(shifted, 1, 2, 0.5, DitherPattern::Checker, kNoMask, false, {1, 0});
    CHECK(T(shifted) == "12121212|21212121|12121212|21212121|");
    // only filled pixels
    IndexGrid part = G({"3.", ".."});
    pixel_dither_blend(part, 1, 2, 1.0, DitherPattern::Bayer2, kNoMask, true);
    CHECK(T(part) == "2.|..|");
    // a gradient: first colour at `from`, last at `to`
    IndexGrid grad(8, 4);
    pixel_dither_gradient(grad, {1, 2}, {0, 0}, {7, 0}, DitherPattern::Bayer4);
    CHECK(T(grad) == "11212222|11121212|11212122|11121222|");
    // three colours: the middle one in the middle
    IndexGrid three(9, 1);
    pixel_dither_gradient(three, {0, 1, 2}, {0, 0}, {8, 0}, DitherPattern::Bayer2);
    CHECK(three.at(0, 0) == 0);
    CHECK(three.at(8, 0) == 2);
    CHECK(three.at(4, 0) == 1);
}

TEST_CASE("pixel_cleanup: orphans, doubles, jaggies and the report") {
    IndexGrid g = G({".....", "..2..", ".....", "..33.", "..33."});
    PixelCleanup only;
    only.doubles = only.jaggies = false;
    PixelCleanupReport r = pixel_cleanup(g, only);
    CHECK(T(g) == ".....|.....|.....|..33.|..33.|");
    CHECK(r.orphans == 1);
    REQUIRE(r.changed.size() == 1);
    CHECK(r.changed[0] == PixelPoint{2, 1});
    // an orphan inside another colour takes that colour
    g = G({"222", "232", "222"});
    r = pixel_cleanup(g, only);
    CHECK(T(g) == "222|222|222|");
    // `keep` leaves a highlight on purpose
    g = G({"222", "232", "222"});
    PixelCleanup keep = only;
    keep.keep = {3};
    CHECK(pixel_cleanup(g, keep).changed.empty());
    // a double: the corner pixel of an L bend
    g = G({"00...", ".0...", ".00..", "..0.."});
    PixelCleanup dbl;
    dbl.orphans = dbl.jaggies = false;
    r = pixel_cleanup(g, dbl);
    CHECK(T(g) == "0....|.0...|.00..|..0..|");
    CHECK(r.doubles == 1);
    // the right-angled corners of a filled shape stay
    g = G({"222", "222", "222"});
    CHECK(pixel_cleanup(g, PixelCleanup{}).changed.empty());
    // a jaggy: uneven steps on a nearly straight line become even
    g = G({"000.........", "...000......", "......0.....", ".......000..", "..........00"});
    PixelCleanup jag;
    jag.orphans = jag.doubles = false;
    r = pixel_cleanup(g, jag);
    CHECK(T(g) == "00..........|..000.......|.....00.....|.......000..|..........00|");
    CHECK(r.jaggies == 4);
    // an even line is left as it is
    g = G({"000.......", "...000....", "......0000", ".........."});
    CHECK(pixel_cleanup(g, jag).changed.empty());
}

TEST_CASE("pixel_scale2x and pixel_scale3x round corners; pixel_resample is exact") {
    IndexGrid g = G({"2.", "22"});
    CHECK(T(pixel_scale2x(g)) == "22..|222.|2222|2222|");
    CHECK(pixel_scale3x(g).w == 6);
    // nearest: whole blocks
    CHECK(T(pixel_resample(G({"23", "41"}), 4, 4, PixelResample::Nearest)) == "2233|2233|4411|4411|");
    // mode: the commonest colour of the old pixels covered, no blend
    CHECK(T(pixel_resample(G({"2233", "2233", "4411", "4411"}), 2, 2, PixelResample::Mode)) == "23|41|");
    CHECK(T(pixel_resample(G({"2223", "2223"}), 2, 1, PixelResample::Mode)) == "22|");
}

TEST_CASE("pixel_rotate: 90 degrees is an exact turn, 45 degrees keeps the palette") {
    const IndexGrid g = G({"2.2", ".2.", "3.."});
    for (PixelRotateMethod m : {PixelRotateMethod::RotSprite, PixelRotateMethod::Nearest}) {
        CHECK(T(pixel_rotate(g, 90, m)) == "3.2|.2.|..2|");
        CHECK(T(pixel_rotate(g, 180, m)) == "..3|.2.|2.2|");
        CHECK(T(pixel_rotate(g, 270, m)) == "2..|.2.|2.3|");
        CHECK(T(pixel_rotate(g, -90, m)) == "2..|.2.|2.3|");
        CHECK(T(pixel_rotate(g, 360, m)) == T(g));
    }
    const IndexGrid disc = G({"..22..", ".2222.", "223322", "223322", ".2222.", "..22.."});
    for (PixelRotateMethod m : {PixelRotateMethod::RotSprite, PixelRotateMethod::Nearest}) {
        const IndexGrid r = pixel_rotate(disc, 45, m);
        std::set<int> colours(r.v.begin(), r.v.end());
        colours.erase(-1);
        CHECK(colours == std::set<int>{2, 3});   // no colour that was not there
        CHECK(r.w >= 8);
    }
    CHECK(T(pixel_rotate(disc, 45, PixelRotateMethod::RotSprite)) ==
          ".........|.........|..22222..|..22222..|..22322..|..22222..|..22222..|.........|.........|");
}

TEST_CASE("pixel_dominant_downscale and pixel_area_downscale") {
    const PixelPalette p = pal5();
    Image src;
    src.width = 4;
    src.height = 4;
    src.rgba.assign(64, 0);
    auto set = [&](int x, int y, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a = 255) {
        std::uint8_t* d = &src.rgba[(std::size_t(y) * 4 + x) * 4];
        d[0] = r, d[1] = g, d[2] = b, d[3] = a;
    };
    // left half almost skin (one stray pixel of another colour), right half transparent
    for (int y = 0; y < 4; ++y)
        for (int x = 0; x < 2; ++x) set(x, y, 0xe0, 0xa1, 0x70);
    set(0, 0, 0x38, 0xb7, 0x65);
    const IndexGrid d = pixel_dominant_downscale(src, p, 2, 2, 0.5);
    CHECK(T(d) == "2.|2.|");   // the stray sky-green pixel does not win its area
    const Image a = pixel_area_downscale(src, 2, 2);
    CHECK(a.width == 2);
    CHECK(a.rgba[3] == 255);
    CHECK(a.rgba[7] == 0);
}

// ---- the commands ---------------------------------------------------------------------------------------------------------------

namespace {

constexpr const char* kDoc = "assets/art/h.image.json";

Json palette_json() {
    return Json::array({{{"name", "outline"}, {"color", "#1a1c2c"}}, {{"name", "skin-dark"}, {"color", "#b06a40"}}, {{"name", "skin"}, {"color", "#e0a070"}},
                        {{"name", "skin-light"}, {"color", "#f8d0a8"}}, {{"name", "sky"}, {"color", "#38b764"}}});
}

void make_doc(const AssetsProject& p, int w = 12, int h = 12) {
    p.ok("image.create", {{"path", kDoc}, {"width", w}, {"height", h}, {"palette", palette_json()}, {"ramps", Json::array({Json::array({"skin-dark", "skin", "skin-light"})})}});
}

Json read_doc(const AssetsProject& p) { return parse_json(read_all(p.file(kDoc)), kDoc).value(); }

std::string rows_of(const Json& layer) {
    std::string out;
    for (const Json& r : layer["rows"]) out += r.get<std::string>() + "|";
    return out;
}

std::string error_of(const CommandResult& r) { return r.error["message"].get<std::string>() + " " + r.error.value("hint", std::string()); }

}  // namespace

namespace {
void block3(const AssetsProject& p, const char* layer = "s", int frame = -1) {
    Json a = {{"path", kDoc}, {"layer", layer}, {"create", true}, {"stamp", {{"x", 4}, {"y", 4}, {"rows", Json::array({"3333", "3333", "3333", "3333"})}}}};
    if (frame >= 0) a["frame"] = frame;
    p.ok("image.pixel", a);
}
}  // namespace

TEST_CASE("image.pixel.outline: selective outline with the style light, region and preview like image.pixel") {
    AssetsProject p;
    make_doc(p);
    write_all(p.file("assets.json"), Json({{"style", {{"lightDirection", "upper-left"}}}}).dump(2));
    block3(p);
    Json r = p.ok("image.pixel.outline", {{"path", kDoc}, {"layer", "s"}, {"mode", "selective"}});
    CHECK(rows_of(read_doc(p)["layers"][0]) == "............|............|............|....2222....|...233331...|...233331...|...233331...|...233331...|....1111....|............|............|............|");
    CHECK(r["changed"] == true);
    CHECK(r["pixelsChanged"] == 16);
    CHECK(r["region"] == Json({{"x", 3}, {"y", 3}, {"width", 6}, {"height", 6}}));
    CHECK(r["light"] == "upper-left");
    CHECK(r.contains("$image"));
    CHECK(p.exists("assets/art/h.png"));
    // the same outline again changes nothing: it is the shape that is outlined, the outline included, so ask for inner instead
    Json inner = p.ok("image.pixel.outline", {{"path", kDoc}, {"layer", "s"}, {"side", "inner"}, {"mode", "flat"}, {"color", "outline"}});
    CHECK(inner["pixelsChanged"].get<int>() > 0);
}

TEST_CASE("image.pixel.outline teaches: flat needs a colour, unknown colour, unknown mode, pixels layer") {
    AssetsProject p;
    make_doc(p);
    block3(p);
    auto noColor = p.call("image.pixel.outline", {{"path", kDoc}, {"layer", "s"}, {"mode", "flat"}});
    REQUIRE_FALSE(noColor.ok);
    CHECK(error_of(noColor).find("/color") != std::string::npos);
    auto typo = p.call("image.pixel.outline", {{"path", kDoc}, {"layer", "s"}, {"color", "outlin"}});
    REQUIRE_FALSE(typo.ok);
    CHECK(error_of(typo).find("outline") != std::string::npos);
    auto mode = p.call("image.pixel.outline", {{"path", kDoc}, {"layer", "s"}, {"mode", "selectiv"}});
    REQUIRE_FALSE(mode.ok);
    CHECK(error_of(mode).find("selective") != std::string::npos);
    auto conn = p.call("image.pixel.outline", {{"path", kDoc}, {"layer", "s"}, {"connectivity", 6}});
    REQUIRE_FALSE(conn.ok);
    CHECK(error_of(conn).find("Allowed values: 4, 8") != std::string::npos);
    auto key = p.call("image.pixel.outline", {{"path", kDoc}, {"layer", "s"}, {"colour", "outline"}});
    REQUIRE_FALSE(key.ok);
    CHECK(error_of(key).find("color") != std::string::npos);
    p.ok("image.layer.add", {{"path", kDoc}, {"layer", {{"kind", "fill"}, {"name", "bg"}, {"color", "#000000"}}}});
    auto wrong = p.call("image.pixel.outline", {{"path", kDoc}, {"layer", "bg"}, {"color", "outline"}});
    REQUIRE_FALSE(wrong.ok);
    CHECK(error_of(wrong).find("indexed") != std::string::npos);
}

TEST_CASE("image.pixel.shade: the light from the argument, else the style, else an error that teaches both") {
    AssetsProject p;
    make_doc(p);
    block3(p);
    auto none = p.call("image.pixel.shade", {{"path", kDoc}, {"layer", "s"}});
    REQUIRE_FALSE(none.ok);
    CHECK(error_of(none).find("lightDirection") != std::string::npos);
    CHECK(error_of(none).find("light") != std::string::npos);
    auto badName = p.call("image.pixel.shade", {{"path", kDoc}, {"layer", "s"}, {"light", "upper-lef"}});
    REQUIRE_FALSE(badName.ok);
    CHECK(error_of(badName).find("upper-left") != std::string::npos);
    Json r = p.ok("image.pixel.shade", {{"path", kDoc}, {"layer", "s"}, {"light", "upper-left"}, {"shadowWidth", 1}});
    CHECK(rows_of(read_doc(p)["layers"][0]) == "............|............|............|............|....3332....|....3332....|....3332....|....2222....|............|............|............|............|");
    CHECK(r["light"]["name"] == "upper-left");
    CHECK(r["light"]["from"] == "light");
    write_all(p.file("assets.json"), Json({{"style", {{"lightDirection", "left"}}}}).dump(2));
    Json s = p.ok("image.pixel.shade", {{"path", kDoc}, {"layer", "s"}});
    CHECK(s["light"]["from"] == "style.lightDirection");
}

TEST_CASE("image.pixel.dither: a constant blend, a gradient, a rect, the ramp") {
    AssetsProject p;
    make_doc(p, 8, 4);
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"create", true}, {"pixels", Json::array({Json::array({0, 0, 1})})}});
    Json r = p.ok("image.pixel.dither", {{"path", kDoc}, {"layer", "s"}, {"colors", Json::array({"skin-dark", "skin"})}, {"level", 0.5}, {"pattern", "checker"}});
    CHECK(rows_of(read_doc(p)["layers"][0]) == "21212121|12121212|21212121|12121212|");
    CHECK(r["pixelsChanged"].get<int>() > 0);
    CHECK(r["pattern"] == "checker");
    p.ok("image.pixel.dither", {{"path", kDoc}, {"layer", "s"}, {"colors", Json::array({"skin-dark", "skin"})}, {"gradient", {{"from", {0, 0}}, {"to", {7, 0}}}}});
    CHECK(rows_of(read_doc(p)["layers"][0]) == "11212222|11121212|11212122|11121222|");
    // a rect limits the region
    p.ok("image.pixel.dither", {{"path", kDoc}, {"layer", "s"}, {"colors", Json::array({"skin", "skin"})}, {"level", 0}, {"rect", {{"x", 0}, {"y", 0}, {"width", 2}, {"height", 1}}}});
    CHECK(read_doc(p)["layers"][0]["rows"][0].get<std::string>().substr(0, 2) == "22");
    // the ramp: the three skin colours, light to dark
    p.ok("image.pixel.dither", {{"path", kDoc}, {"layer", "s"}, {"ramp", "skin"}, {"gradient", {{"from", {0, 0}}, {"to", {7, 0}}}}});
    const std::string top = read_doc(p)["layers"][0]["rows"][0].get<std::string>();
    CHECK(top.front() == '3');
    CHECK(top.back() == '1');
}

TEST_CASE("image.pixel.dither teaches: level and gradient together, a colour outside the palette") {
    AssetsProject p;
    make_doc(p, 8, 4);
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"create", true}, {"pixels", Json::array({Json::array({0, 0, 1})})}});
    auto both = p.call("image.pixel.dither", {{"path", kDoc}, {"layer", "s"}, {"colors", Json::array({"skin", "sky"})}, {"level", 0.5}, {"gradient", {{"from", {0, 0}}, {"to", {7, 0}}}}});
    REQUIRE_FALSE(both.ok);
    CHECK(error_of(both).find("level") != std::string::npos);
    auto off = p.call("image.pixel.dither", {{"path", kDoc}, {"layer", "s"}, {"colors", Json::array({"skin", "#010203"})}, {"level", 0.5}});
    REQUIRE_FALSE(off.ok);
    CHECK(error_of(off).find("/colors/1") != std::string::npos);
    auto none = p.call("image.pixel.dither", {{"path", kDoc}, {"layer", "s"}, {"level", 0.5}});
    REQUIRE_FALSE(none.ok);
    CHECK(error_of(none).find("colors") != std::string::npos);
    auto same = p.call("image.pixel.dither", {{"path", kDoc}, {"layer", "s"}, {"colors", Json::array({"skin", "sky"})}, {"gradient", {{"from", {1, 1}}, {"to", {1, 1}}}}});
    REQUIRE_FALSE(same.ok);
    CHECK(error_of(same).find("same pixel") != std::string::npos);
}

TEST_CASE("image.pixel.cleanup reports what it fixed") {
    AssetsProject p;
    make_doc(p, 6, 5);
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"create", true}, {"stamp", {{"x", 0}, {"y", 0}, {"rows", Json::array({".....", "..2..", ".....", "..33.", "..33."})}}}});
    Json r = p.ok("image.pixel.cleanup", {{"path", kDoc}, {"layer", "s"}});
    CHECK(rows_of(read_doc(p)["layers"][0]) == "......|......|......|..33..|..33..|");
    CHECK(r["orphans"] == 1);
    CHECK(r["doubles"] == 0);
    CHECK(r["jaggies"] == 0);
    CHECK(r["changedPixels"] == Json::array({Json::array({2, 1})}));
    // nothing left to clean: a warning, not an error
    Json again = p.ok("image.pixel.cleanup", {{"path", kDoc}, {"layer", "s"}});
    CHECK(again["changed"] == false);
    CHECK(has_warning(again, "No pixel changed"));
    auto bad = p.call("image.pixel.cleanup", {{"path", kDoc}, {"layer", "s"}, {"passes", Json::array({"orphan"})}});
    REQUIRE_FALSE(bad.ok);
    CHECK(error_of(bad).find("orphans") != std::string::npos);
}

TEST_CASE("image.pixel.rotate and image.pixel.scale") {
    AssetsProject p;
    make_doc(p, 8, 8);
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"create", true}, {"stamp", {{"x", 2}, {"y", 2}, {"rows", Json::array({"2.2", ".2.", "3.."})}}}});
    Json r = p.ok("image.pixel.rotate", {{"path", kDoc}, {"layer", "s"}, {"angle", 90}});
    CHECK(rows_of(read_doc(p)["layers"][0]) == "........|........|..3.2...|...2....|....2...|........|........|........|");
    CHECK(r["size"] == Json({{"width", 3}, {"height", 3}}));
    Json sc = p.ok("image.pixel.scale", {{"path", kDoc}, {"layer", "s"}, {"factor", 2}});
    CHECK(rows_of(read_doc(p)["layers"][0]) == "........|.33..22.|.33..22.|...22...|...22...|.....22.|.....22.|........|");
    CHECK(sc["size"] == Json({{"width", 6}, {"height", 6}}));
    // a rotation by 45 degrees keeps the palette: only colours 2 and 3 are in the rows
    p.ok("image.pixel.rotate", {{"path", kDoc}, {"layer", "s"}, {"angle", 45}});
    const Json rotated = read_doc(p);
    for (const Json& row : rotated["layers"][0]["rows"])
        for (char c : row.get<std::string>()) CHECK((c == '.' || c == '2' || c == '3'));
    auto badAngle = p.call("image.pixel.rotate", {{"path", kDoc}, {"layer", "s"}});
    REQUIRE_FALSE(badAngle.ok);
    CHECK(error_of(badAngle).find("angle") != std::string::npos);
    auto both = p.call("image.pixel.scale", {{"path", kDoc}, {"layer", "s"}, {"factor", 2}, {"size", {{"width", 4}}}});
    REQUIRE_FALSE(both.ok);
    CHECK(error_of(both).find("not both") != std::string::npos);
    auto x2 = p.call("image.pixel.scale", {{"path", kDoc}, {"layer", "s"}, {"factor", 3}, {"method", "scale2x"}});
    REQUIRE_FALSE(x2.ok);
    CHECK(error_of(x2).find("exactly 2 times") != std::string::npos);
}

TEST_CASE("pixel helpers honour a stored selection and a range of frames") {
    AssetsProject p;
    make_doc(p, 8, 4);
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "s"}, {"create", true}, {"stamp", {{"x", 0}, {"y", 0}, {"rows", Json::array({"22222222", "22222222", "22222222", "22222222"})}}}});
    p.ok("image.select", {{"path", kDoc}, {"name", "left"}, {"by", "rect"}, {"x", 0}, {"y", 0}, {"width", 4}, {"height", 4}});
    p.ok("image.pixel.dither", {{"path", kDoc}, {"layer", "s"}, {"colors", Json::array({"skin", "skin-dark"})}, {"level", 1}, {"selection", "left"}});
    CHECK(rows_of(read_doc(p)["layers"][0]) == "11112222|11112222|11112222|11112222|");
    auto missing = p.call("image.pixel.dither", {{"path", kDoc}, {"layer", "s"}, {"colors", Json::array({"skin", "sky"})}, {"level", 1}, {"selection", "nope"}});
    REQUIRE_FALSE(missing.ok);
    CHECK(error_of(missing).find("no selection named 'nope'") != std::string::npos);
    CHECK(error_of(missing).find("left") != std::string::npos);
    // frames: the same change on every cel of an animation
    p.ok("image.frame.add", {{"path", kDoc}, {"count", 2}, {"from", 0}});
    Json all = p.ok("image.pixel.dither", {{"path", kDoc}, {"layer", "s"}, {"colors", Json::array({"skin", "sky"})}, {"level", 1}, {"frames", "all"}, {"selection", "left"}});
    CHECK(all["processedFrames"] == Json::array({0, 1, 2}));
    CHECK(all["perFrame"].size() == 3);
    CHECK(all["pixelsChanged"] == 48);
    // a single frame leaves the others alone
    Json one = p.ok("image.pixel.dither", {{"path", kDoc}, {"layer", "s"}, {"colors", Json::array({"skin", "skin-light"})}, {"level", 1}, {"frame", 1}, {"selection", "left"}});
    CHECK(one["frame"] == 1);
    CHECK(one["pixelsChanged"] == 16);
    auto badFrame = p.call("image.pixel.dither", {{"path", kDoc}, {"layer", "s"}, {"colors", Json::array({"skin", "sky"})}, {"level", 1}, {"frames", Json::array({0, 7})}});
    REQUIRE_FALSE(badFrame.ok);
    CHECK(error_of(badFrame).find("/frames/1") != std::string::npos);
    auto twice = p.call("image.pixel.dither", {{"path", kDoc}, {"layer", "s"}, {"colors", Json::array({"skin", "sky"})}, {"level", 1}, {"frames", "all"}, {"frame", 0}});
    REQUIRE_FALSE(twice.ok);
    CHECK(error_of(twice).find("not both") != std::string::npos);
}

TEST_CASE("image.to_pixel_art: a painted layer becomes a palette-exact indexed layer of the target size") {
    AssetsProject p;
    make_doc(p, 16, 16);
    p.ok("image.layer.add", {{"path", kDoc}, {"layer", {{"kind", "fill"}, {"name", "paint"}, {"color", "#e0a171"}}}});
    Json r = p.ok("image.to_pixel_art", {{"path", kDoc}, {"source", "paint"}, {"into", "art"}, {"width", 4}, {"outline", "outline"}});
    CHECK(r["sourceSize"] == Json({{"width", 16}, {"height", 16}}));
    CHECK(r["size"] == Json({{"width", 6}, {"height", 6}}));   // 4 x 4 plus the outline ring
    Json art;
    const Json doc = read_doc(p);
    for (const Json& l : doc["layers"])
        if (l["name"] == "art") art = l;
    REQUIRE(art.is_object());
    CHECK(art["kind"] == "indexed");
    CHECK(rows_of(art) == ".0000.|022220|022220|022220|022220|.0000.|");   // 4-connected: corners open
    CHECK(art["x"] == -1);
    CHECK(r["colorsUsed"] == 2);
    // the same call again replaces the layer
    Json again = p.ok("image.to_pixel_art", {{"path", kDoc}, {"source", "paint"}, {"into", "art"}, {"pixelSize", 8}});
    CHECK(again["replacedLayer"] == true);
    CHECK(again["size"] == Json({{"width", 2}, {"height", 2}}));
    // average + dither only uses palette colours
    Json dith = p.ok("image.to_pixel_art", {{"path", kDoc}, {"source", "paint"}, {"into", "art2"}, {"width", 8}, {"method", "average"}, {"dither", "bayer4"}});
    CHECK(dith["orphansFixed"] == 0);   // a dither is made of single pixels: orphans are off unless asked for
    auto bad = p.call("image.to_pixel_art", {{"path", kDoc}, {"source", "paint"}, {"into", "art3"}, {"width", 8}, {"dither", "bayer4"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(error_of(bad).find("average") != std::string::npos);
    auto noSize = p.call("image.to_pixel_art", {{"path", kDoc}, {"source", "paint"}, {"into", "art3"}});
    REQUIRE_FALSE(noSize.ok);
    CHECK(error_of(noSize).find("pixelSize") != std::string::npos);
    auto noSrc = p.call("image.to_pixel_art", {{"path", kDoc}, {"into", "art3"}, {"width", 4}});
    REQUIRE_FALSE(noSrc.ok);
    CHECK(error_of(noSrc).find("source") != std::string::npos);
}
