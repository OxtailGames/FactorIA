// assets.rasterize_svg: an SVG to a PNG with nanosvg, offline.
#include <doctest.h>

#include "asset_test_helpers.h"

using namespace fa;
using namespace fa::testing;

namespace {

// A 100x100 drawing: a red square on the left, a blue disc on the right, a green stroked line, the rest empty.
const char* kSvg =
    "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100' width='100' height='100'>"
    "<rect x='0' y='0' width='50' height='50' fill='#ff0000'/>"
    "<circle cx='75' cy='75' r='20' fill='#0000ff'/>"
    "<rect x='60' y='0' width='40' height='20' fill='#00ff00' opacity='0.5'/>"
    "</svg>";

std::string message(const CommandResult& r) { return r.error["message"].get<std::string>(); }

}  // namespace

TEST_CASE("assets.rasterize_svg: shapes land where the SVG puts them, at the asked size") {
    AssetsProject p;
    const Json r = p.ok("assets.rasterize_svg", Json{{"path", "assets/art/shapes.png"}, {"svg", kSvg}, {"width", 200}});
    CHECK(r["width"] == 200);
    CHECK(r["height"] == 200);  // the SVG is square: the height follows
    CHECK_FALSE(r.contains("warnings"));
    const Image img = read_png(p.file("assets/art/shapes.png"));
    REQUIRE(img.width == 200);
    REQUIRE(img.height == 200);
    CHECK(get(img, 50, 50) == Rgba{255, 0, 0, 255});    // the red square
    CHECK(get(img, 150, 150) == Rgba{0, 0, 255, 255});  // the blue disc
    CHECK(get(img, 100, 100).a == 0);                   // empty space is transparent
    CHECK(get(img, 150, 100 - 60).a == 0);              // above the disc
    const Rgba half = get(img, 160, 20);                // the half-transparent green rect
    CHECK(half.g > 240);
    CHECK(half.a > 120);
    CHECK(half.a < 135);
    const Rgba edge = get(img, 150 + 40 - 1, 150);      // the edge of the disc is anti-aliased
    CHECK(edge.a > 0);

    // same SVG, same size: same bytes
    p.ok("assets.rasterize_svg", Json{{"path", "assets/art/again.png"}, {"svg", kSvg}, {"width", 200}});
    CHECK(read_all(p.file("assets/art/again.png")) == read_all(p.file("assets/art/shapes.png")));
}

TEST_CASE("assets.rasterize_svg: sizes, proportions, background and the declared size") {
    AssetsProject p;
    const std::string wide =
        "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 200 100'><rect width='200' height='100' fill='#102030'/></svg>";
    Json r = p.ok("assets.rasterize_svg", Json{{"path", "assets/a.png"}, {"svg", wide}});
    CHECK(r["width"] == 200);  // no width or height: the declared (viewBox) size
    CHECK(r["height"] == 100);
    r = p.ok("assets.rasterize_svg", Json{{"path", "assets/b.png"}, {"svg", wide}, {"height", 50}});
    CHECK(r["width"] == 100);
    r = p.ok("assets.rasterize_svg", Json{{"path", "assets/c.png"}, {"svg", wide}, {"width", 100}, {"height", 100}});
    const Image fit = read_png(p.file("assets/c.png"));  // fitted inside a square, centred, aspect kept
    CHECK(fit.width == 100);
    CHECK(fit.height == 100);
    CHECK(get(fit, 50, 50) == Rgba{0x10, 0x20, 0x30, 255});
    CHECK(get(fit, 50, 5).a == 0);
    CHECK(get(fit, 50, 95).a == 0);

    // a background colour makes it opaque
    p.ok("assets.rasterize_svg", Json{{"path", "assets/d.png"}, {"svg", kSvg}, {"background", "#ffffff"}});
    const Image bg = read_png(p.file("assets/d.png"));
    CHECK(get(bg, 70, 50) == Rgba{255, 255, 255, 255});
    CHECK(get(bg, 25, 25) == Rgba{255, 0, 0, 255});
}

TEST_CASE("assets.rasterize_svg: a file of the project, provenance and gradients") {
    AssetsProject p;
    std::filesystem::create_directories(p.file("assets/art"));
    write_all(p.file("assets/art/grad.svg"),
              "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><defs>"
              "<linearGradient id='g' x1='0%' y1='0%' x2='100%' y2='0%'><stop offset='0' stop-color='#ff0000'/><stop offset='1' stop-color='#0000ff'/></linearGradient>"
              "</defs><rect width='100' height='100' fill='url(#g)'/></svg>");
    const Json r = p.ok("assets.rasterize_svg", Json{{"path", "assets/art/grad.png"}, {"source", "assets/art/grad.svg"}, {"width", 100}, {"ai", false}, {"author", "Ana"}, {"license", "CC-BY-4.0"}});
    const Image img = read_png(p.file("assets/art/grad.png"));
    CHECK(get(img, 2, 50).r > 230);
    CHECK(get(img, 97, 50).b > 230);
    const Json prov = p.manifest()["assets"]["assets/art/grad.png"]["provenance"];
    CHECK(prov["ai"] == false);
    CHECK(prov["origin"] == "original");
    CHECK(prov["author"] == "Ana");
    CHECK(prov["license"] == "CC-BY-4.0");
    CHECK(prov["source"] == "assets/art/grad.svg");

    // the default: the agent wrote the SVG, so it counts as AI-made
    p.ok("assets.rasterize_svg", Json{{"path", "assets/art/ai.png"}, {"svg", kSvg}, {"width", 32}});
    const Json aiProv = p.manifest()["assets"]["assets/art/ai.png"]["provenance"];
    CHECK(aiProv["ai"] == true);
    CHECK(aiProv["origin"] == "generated");
    CHECK(aiProv["kind"] == "image");
}

TEST_CASE("assets.rasterize_svg: unsupported features are named, and errors teach") {
    AssetsProject p;
    const Json r = p.ok("assets.rasterize_svg",
                        Json{{"path", "assets/t.png"},
                             {"svg", "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><rect width='100' height='100' fill='#000' filter='url(#b)'/>"
                                     "<text x='5' y='50'>Hello</text></svg>"}});
    CHECK(has_warning(r, "text:"));
    CHECK(has_warning(r, "filter:"));
    CHECK(has_warning(r, "Text entity"));

    auto none = p.call("assets.rasterize_svg", Json{{"path", "assets/n.png"}, {"svg", "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'><text>x</text></svg>"}});
    REQUIRE_FALSE(none.ok);
    CHECK(none.error["code"] == "no_shapes");
    CHECK(none.error["hint"].get<std::string>().find("text") != std::string::npos);

    auto notSvg = p.call("assets.rasterize_svg", Json{{"path", "assets/n.png"}, {"svg", "hello"}});
    CHECK(notSvg.error["code"] == "invalid_svg");
    auto both = p.call("assets.rasterize_svg", Json{{"path", "assets/n.png"}, {"svg", kSvg}, {"source", "assets/x.svg"}});
    CHECK(both.error["code"] == "invalid_argument");
    auto neither = p.call("assets.rasterize_svg", Json{{"path", "assets/n.png"}});
    CHECK(neither.error["code"] == "invalid_argument");
    auto missing = p.call("assets.rasterize_svg", Json{{"path", "assets/n.png"}, {"source", "assets/nope.svg"}});
    CHECK(missing.error["code"] == "not_found");
    auto outside = p.call("assets.rasterize_svg", Json{{"path", "out.png"}, {"svg", kSvg}});
    CHECK(message(outside).find("under assets/") != std::string::npos);
    auto huge = p.call("assets.rasterize_svg", Json{{"path", "assets/n.png"}, {"svg", kSvg}, {"width", 9000}});
    CHECK_FALSE(huge.ok);
    CHECK_FALSE(p.exists("assets/n.png"));

    p.ok("assets.rasterize_svg", Json{{"path", "assets/o.png"}, {"svg", kSvg}, {"width", 16}});
    auto again = p.call("assets.rasterize_svg", Json{{"path", "assets/o.png"}, {"svg", kSvg}, {"width", 16}});
    CHECK(again.error["code"] == "exists");
}

namespace {

double diff(const Image& a, const Image& b) {
    double d = 0;
    for (std::size_t i = 0; i < a.rgba.size(); ++i) d += std::abs(int(a.rgba[i]) - int(b.rgba[i]));
    return d / a.rgba.size();
}

}  // namespace

TEST_CASE("assets.rasterize_svg: style paints a watercolour, ink or paper look, seeded") {
    AssetsProject p;
    Json base = Json{{"path", "assets/art/plain.png"}, {"svg", kSvg}, {"width", 160}};
    p.ok("assets.rasterize_svg", base);
    const Image plain = read_png(p.file("assets/art/plain.png"));
    for (const char* style : {"watercolor", "ink", "inkwash", "paper"}) {
        INFO(std::string(style));
        Json a = Json{{"path", "assets/art/styled.png"}, {"svg", kSvg}, {"width", 160}, {"style", style}, {"seed", 5}, {"overwrite", true}};
        const Json r = p.ok("assets.rasterize_svg", a);
        CHECK(r["provenance"]["notes"].get<std::string>().find(std::string("style ") + style) != std::string::npos);
        const Image styled = read_png(p.file("assets/art/styled.png"));
        REQUIRE(styled.width == 160);
        CHECK(diff(plain, styled) > 1.0);                // the picture changed
        CHECK(get(styled, 120, 70).a == 0);              // empty space stays transparent (nothing is painted outside the shapes)
        CHECK(get(styled, 25, 25).a == 255);             // the inside of a shape stays solid
        const std::string first = read_all(p.file("assets/art/styled.png"));
        p.ok("assets.rasterize_svg", a);
        CHECK(read_all(p.file("assets/art/styled.png")) == first);  // same seed, same bytes
        a["seed"] = 6;
        p.ok("assets.rasterize_svg", a);
        CHECK(read_all(p.file("assets/art/styled.png")) != first);  // another seed, another take
    }
}

TEST_CASE("assets.rasterize_svg: styleStrength scales the style; a style that does not exist teaches") {
    AssetsProject p;
    p.ok("assets.rasterize_svg", Json{{"path", "assets/art/plain.png"}, {"svg", kSvg}, {"width", 160}});
    const Image plain = read_png(p.file("assets/art/plain.png"));
    p.ok("assets.rasterize_svg", Json{{"path", "assets/art/soft.png"}, {"svg", kSvg}, {"width", 160}, {"style", "paper"}, {"styleStrength", 0.2}});
    p.ok("assets.rasterize_svg", Json{{"path", "assets/art/full.png"}, {"svg", kSvg}, {"width", 160}, {"style", "paper"}});
    CHECK(diff(plain, read_png(p.file("assets/art/soft.png"))) < diff(plain, read_png(p.file("assets/art/full.png"))));

    auto typo = p.call("assets.rasterize_svg", Json{{"path", "assets/art/x.png"}, {"svg", kSvg}, {"style", "watercolour"}});
    REQUIRE_FALSE(typo.ok);
    CHECK(typo.error["hint"].get<std::string>().find("watercolor") != std::string::npos);
    CHECK_FALSE(p.call("assets.rasterize_svg", Json{{"path", "assets/art/x.png"}, {"svg", kSvg}, {"style", "paper"}, {"styleStrength", 3}}).ok);
    const Json ignored = p.ok("assets.rasterize_svg", Json{{"path", "assets/art/y.png"}, {"svg", kSvg}, {"seed", 4}});
    REQUIRE(ignored.contains("warnings"));
    CHECK(ignored["warnings"][0].get<std::string>().find("only matter with a `style`") != std::string::npos);
    CHECK_FALSE(p.exists("assets/art/x.png"));
}

TEST_CASE("assets.rasterize_svg: clip-path clips a group and a shape, with transforms") {
    AssetsProject p;
    // a red square clipped to a circle (on a group), and a blue square clipped to a rect inside a translated group
    const std::string svg =
        "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><defs>"
        "<clipPath id='c'><circle cx='25' cy='25' r='20'/></clipPath>"
        "<clipPath id='r'><rect x='0' y='0' width='10' height='100'/></clipPath></defs>"
        "<g clip-path='url(#c)'><rect width='50' height='50' fill='#ff0000'/></g>"
        "<g transform='translate(50 0)'><rect x='0' y='50' width='50' height='50' fill='#0000ff' clip-path='url(#r)'/></g></svg>";
    const Json r = p.ok("assets.rasterize_svg", Json{{"path", "assets/clip.png"}, {"svg", svg}, {"width", 100}});
    CHECK_FALSE(r.contains("warnings"));
    const Image img = read_png(p.file("assets/clip.png"));
    CHECK(get(img, 25, 25) == Rgba{255, 0, 0, 255});  // inside the circle
    CHECK(get(img, 3, 3).a == 0);                      // the square's corner is outside the circle
    CHECK(get(img, 48, 48).a == 0);
    CHECK(get(img, 55, 75) == Rgba{0, 0, 255, 255});   // the clip rect follows the translate: x 50..60
    CHECK(get(img, 70, 75).a == 0);
    CHECK(get(img, 5, 75).a == 0);                      // not where the untranslated clip would be

    // a missing id and objectBoundingBox clip units are named, never silent
    const Json w = p.ok("assets.rasterize_svg",
                        Json{{"path", "assets/clip2.png"},
                             {"svg", "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'><clipPath id='b' clipPathUnits='objectBoundingBox'><rect width='1' height='1'/></clipPath>"
                                     "<rect width='10' height='10' clip-path='url(#nope)'/><rect width='5' height='5' clip-path='url(#b)'/></svg>"}});
    CHECK(has_warning(w, "does not point to a <clipPath>"));
    CHECK(has_warning(w, "objectBoundingBox"));
}

TEST_CASE("assets.rasterize_svg: a pattern fill hatches a shape, in user space and in bounding-box units") {
    AssetsProject p;
    // horizontal lines every 10 units, 2 thick, in a disc; rows 0..2 of every tile are black
    const std::string svg =
        "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><defs>"
        "<pattern id='h' patternUnits='userSpaceOnUse' width='10' height='10'><rect width='10' height='2' fill='#000000'/></pattern></defs>"
        "<circle cx='50' cy='50' r='40' fill='url(#h)'/></svg>";
    p.ok("assets.rasterize_svg", Json{{"path", "assets/pat.png"}, {"svg", svg}, {"width", 100}});
    const Image img = read_png(p.file("assets/pat.png"));
    CHECK(get(img, 50, 51) == Rgba{0, 0, 0, 255});   // y 51 is in the line y 50..52
    CHECK(get(img, 50, 56).a == 0);                  // between lines
    CHECK(get(img, 3, 51).a == 0);                   // outside the disc
    int ink = 0, total = 0;
    for (int y = 12; y < 88; ++y) {
        ++total;
        if (get(img, 50, y).a > 128) ++ink;
    }
    CHECK(ink > total / 8);
    CHECK(ink < total / 3);

    // rotated hatching, objectBoundingBox units (the default), and the stroke of the same shape stays
    const std::string rot =
        "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'>"
        "<pattern id='d' width='0.1' height='0.1' patternContentUnits='objectBoundingBox' patternTransform='rotate(45)'><rect width='0.1' height='0.03' fill='#c00000'/></pattern>"
        "<rect x='10' y='10' width='80' height='80' fill='url(#d)' stroke='#00ff00' stroke-width='4'/></svg>";
    p.ok("assets.rasterize_svg", Json{{"path", "assets/rot.png"}, {"svg", rot}, {"width", 100}});
    const Image r = read_png(p.file("assets/rot.png"));
    CHECK(get(r, 10, 50) == Rgba{0, 255, 0, 255});  // the stroke
    int red = 0, empty = 0;
    for (int y = 20; y < 80; ++y)
        for (int x = 20; x < 80; ++x) {
            const Rgba c = get(r, x, y);
            if (c.a > 200 && c.r > 150 && c.g < 50) ++red;
            else if (c.a == 0) ++empty;
        }
    CHECK(red > 200);
    CHECK(empty > 200);
    CHECK(get(r, 5, 5).a == 0);  // nothing outside the shape
}

TEST_CASE("assets.rasterize_svg: a luminance mask fades a shape") {
    AssetsProject p;
    const std::string svg =
        "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><defs>"
        "<linearGradient id='g' x1='0%' y1='0%' x2='100%' y2='0%'><stop offset='0' stop-color='#ffffff'/><stop offset='1' stop-color='#000000'/></linearGradient>"
        "<mask id='m'><rect width='100' height='100' fill='url(#g)'/></mask></defs>"
        "<rect width='100' height='100' fill='#ff0000' mask='url(#m)'/></svg>";
    const Json r = p.ok("assets.rasterize_svg", Json{{"path", "assets/mask.png"}, {"svg", svg}, {"width", 100}});
    CHECK_FALSE(r.contains("warnings"));
    const Image img = read_png(p.file("assets/mask.png"));
    CHECK(get(img, 2, 50).a > 240);
    CHECK(get(img, 50, 50).a > 100);
    CHECK(get(img, 50, 50).a < 160);
    CHECK(get(img, 97, 50).a < 20);
    CHECK(get(img, 50, 50).r == 255);
}
