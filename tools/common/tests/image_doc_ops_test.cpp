// The adjustments and effects of layered images (M52.2): measurable properties of each operation on small known images,
// their validation errors and determinism (docs/IMAGES.md, "Adjustments" and "Effects").
#include <doctest.h>

#include <chrono>
#include <cmath>
#include <filesystem>

#include "asset_test_helpers.h"
#include "fa/core/json_schema.h"
#include "fa/tooling/image_doc.h"
#include "fa_test_paths.h"

using namespace fa;
using namespace fa::testing;
namespace stdfs = std::filesystem;

namespace {

Json fill(const std::string& color, Json extra = Json::object()) {
    Json j = {{"kind", "fill"}, {"color", color}};
    for (auto& [k, v] : extra.items()) j[k] = v;
    return j;
}
Json doc_of(int w, int h, Json layers) { return {{"format", kImageDocFormat}, {"width", w}, {"height", h}, {"layers", std::move(layers)}}; }
Json op(const std::string& type, Json extra = Json::object()) {
    Json j = {{"type", type}};
    for (auto& [k, v] : extra.items()) j[k] = v;
    return j;
}
// One fill layer (the whole canvas) with these operations.
Json with_adjust(int w, int h, const std::string& color, Json ops) { return doc_of(w, h, Json::array({fill(color, {{"adjustments", std::move(ops)}})})); }
// A `size` x `size` square at (at, at) of a canvas, with effects.
Json with_effects(int canvas, int size, int at, const std::string& color, Json ops) {
    return doc_of(canvas, canvas, Json::array({fill(color, {{"width", size}, {"height", size}, {"x", at}, {"y", at}, {"effects", std::move(ops)}})}));
}

Result<ImageRender> try_draw(const Json& doc, const std::string& dir) {
    auto parsed = parse_image_document(doc, "test.image.json", dir);
    if (!parsed.ok()) return make_error(parsed.error().message, parsed.error().hint);
    return composite_image_document(*parsed, {dir});
}
Image draw(const Json& doc, const std::string& dir = "") {
    auto r = try_draw(doc, dir);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().message));
    return r->image;
}
std::vector<ImageIssue> problems(const Json& doc, const std::string& dir = "") {
    std::vector<ImageIssue> issues;
    auto parsed = parse_image_document(doc, "test.image.json", dir, &issues);
    CHECK(parsed.ok() == issues.empty());
    return issues;
}
const ImageIssue* issue_at(const std::vector<ImageIssue>& issues, const std::string& pointer) {
    for (const ImageIssue& i : issues)
        if (i.pointer == pointer) return &i;
    return nullptr;
}
bool near(Rgba a, Rgba b, int tol = 1) {
    return std::abs(int(a.r) - int(b.r)) <= tol && std::abs(int(a.g) - int(b.g)) <= tol && std::abs(int(a.b) - int(b.b)) <= tol && std::abs(int(a.a) - int(b.a)) <= tol;
}
int count_if_pixels(const Image& img, bool (*pred)(Rgba)) {
    int n = 0;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) n += pred(get(img, x, y)) ? 1 : 0;
    return n;
}
double alpha_mass(const Image& img) {
    double s = 0;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) s += get(img, x, y).a / 255.0;
    return s;
}

}  // namespace

TEST_CASE("image ops: levels, curves, posterize, threshold") {
    CHECK(near(get(draw(with_adjust(2, 2, "#808080", Json::array({op("levels", {{"inBlack", 0.25}, {"inWhite", 0.75}})}))), 0, 0), {129, 129, 129, 255}));
    CHECK(near(get(draw(with_adjust(2, 2, "#808080", Json::array({op("levels", {{"gamma", 2}})}))), 0, 0), {181, 181, 181, 255}, 2));
    CHECK(near(get(draw(with_adjust(2, 2, "#808080", Json::array({op("levels", {{"outBlack", 0.2}, {"outWhite", 0.6}})}))), 0, 0), {102, 102, 102, 255}, 2));
    // one channel only
    CHECK(near(get(draw(with_adjust(2, 2, "#808080", Json::array({op("levels", {{"channel", "red"}, {"inWhite", 0.5}})}))), 0, 0), {255, 128, 128, 255}));
    // a curve passes through its points, never overshoots between them, and one channel can be changed alone
    const Json pts = Json::array({Json::array({0, 0}), Json::array({0.5, 0.8}), Json::array({1, 1})});
    CHECK(near(get(draw(with_adjust(2, 2, "#808080", Json::array({op("curves", {{"points", pts}})}))), 0, 0), {205, 205, 205, 255}, 2));
    CHECK(near(get(draw(with_adjust(2, 2, "#808080", Json::array({op("curves", {{"points", pts}, {"channel", "blue"}})}))), 0, 0), {128, 128, 205, 255}, 2));
    int last = -1;
    for (int v = 0; v <= 255; v += 5) {
        char color[8];
        std::snprintf(color, sizeof color, "#%02x%02x%02x", v, v, v);
        const int out = get(draw(with_adjust(1, 1, color, Json::array({op("curves", {{"points", pts}})}))), 0, 0).r;
        CHECK(out >= last);  // monotone
        CHECK(out >= v - 1);   // this curve lifts the tones
        last = out;
    }
    const Json identity = Json::array({Json::array({0, 0}), Json::array({1, 1})});
    CHECK(near(get(draw(with_adjust(1, 1, "#336699", Json::array({op("curves", {{"points", identity}})}))), 0, 0), {0x33, 0x66, 0x99, 255}));
    // posterize: 2 levels is black and white
    CHECK(near(get(draw(with_adjust(1, 1, "#664422", Json::array({op("posterize", {{"levels", 2}})}))), 0, 0), {0, 0, 0, 255}));
    CHECK(near(get(draw(with_adjust(1, 1, "#99bbdd", Json::array({op("posterize", {{"levels", 2}})}))), 0, 0), {255, 255, 255, 255}));
    CHECK(near(get(draw(with_adjust(1, 1, "#808080", Json::array({op("posterize", {{"levels", 3}})}))), 0, 0), {128, 128, 128, 255}));
    // threshold
    CHECK(near(get(draw(with_adjust(1, 1, "#909090", Json::array({op("threshold", {{"level", 0.5}})}))), 0, 0), {255, 255, 255, 255}));
    CHECK(near(get(draw(with_adjust(1, 1, "#707070", Json::array({op("threshold", {{"level", 0.5}, {"above", "#ff0000"}, {"below", "#0000ff"}})}))), 0, 0), {0, 0, 255, 255}));
}

TEST_CASE("image ops: hsv, gradient map, colour balance") {
    CHECK(near(get(draw(with_adjust(1, 1, "#ff0000", Json::array({op("hsv", {{"hue", 120}})}))), 0, 0), {0, 255, 0, 255}));
    CHECK(near(get(draw(with_adjust(1, 1, "#ff0000", Json::array({op("hsv", {{"hue", -120}})}))), 0, 0), {0, 0, 255, 255}));
    CHECK(near(get(draw(with_adjust(1, 1, "#ff0000", Json::array({op("hsv", {{"saturation", -1}})}))), 0, 0), {255, 255, 255, 255}));
    CHECK(near(get(draw(with_adjust(1, 1, "#ff0000", Json::array({op("hsv", {{"value", -0.5}})}))), 0, 0), {128, 0, 0, 255}));
    // colorize: a grey takes the hue and keeps its brightness
    CHECK(near(get(draw(with_adjust(1, 1, "#808080", Json::array({op("hsv", {{"colorize", true}, {"hue", 120}, {"saturation", 1}})}))), 0, 0), {0, 128, 0, 255}, 1));
    const Json stops = Json::array({{{"at", 0}, {"color", "#ff0000"}}, {{"at", 1}, {"color", "#0000ff"}}});
    CHECK(near(get(draw(with_adjust(1, 1, "#000000", Json::array({op("gradientMap", {{"stops", stops}})}))), 0, 0), {255, 0, 0, 255}));
    CHECK(near(get(draw(with_adjust(1, 1, "#ffffff", Json::array({op("gradientMap", {{"stops", stops}})}))), 0, 0), {0, 0, 255, 255}));
    CHECK(near(get(draw(with_adjust(1, 1, "#808080", Json::array({op("gradientMap", {{"stops", stops}})}))), 0, 0), {127, 0, 128, 255}, 2));
    CHECK(near(get(draw(with_adjust(1, 1, "#000000", Json::array({op("colorBalance", {{"shadows", Json::array({0, 0, 1})}})}))), 0, 0), {0, 0, 128, 255}));
    CHECK(near(get(draw(with_adjust(1, 1, "#ffffff", Json::array({op("colorBalance", {{"shadows", Json::array({0, 0, 1})}})}))), 0, 0), {255, 255, 255, 255}));
}

TEST_CASE("image ops: quantize and dither") {
    const Json bw = Json::array({"#000000", "#ffffff"});
    CHECK(near(get(draw(with_adjust(1, 1, "#303030", Json::array({op("quantize", {{"palette", bw}})}))), 0, 0), {0, 0, 0, 255}));
    CHECK(near(get(draw(with_adjust(1, 1, "#d0d0d0", Json::array({op("quantize", {{"palette", bw}})}))), 0, 0), {255, 255, 255, 255}));
    // the nearest colour is measured in a perceptual space: a mid grey is nearer to a bright palette entry than in plain RGB
    const Json two = Json::array({"#000000", "#ffffff"});
    CHECK(near(get(draw(with_adjust(1, 1, "#777777", Json::array({op("quantize", {{"palette", two}, {"space", "oklab"}})}))), 0, 0), {255, 255, 255, 255}));
    CHECK(near(get(draw(with_adjust(1, 1, "#777777", Json::array({op("quantize", {{"palette", two}, {"space", "rgb"}})}))), 0, 0), {0, 0, 0, 255}));
    // alpha stays
    CHECK(get(draw(doc_of(1, 1, Json::array({fill("#80808040", {{"adjustments", Json::array({op("quantize", {{"palette", bw}})})}})}))), 0, 0).a == 64);

    // ordered dither: half grey on a 4x4 tile is half white
    auto whites = [](Rgba c) { return c.r == 255; };
    auto blacks = [](Rgba c) { return c.r == 0; };
    for (const char* method : {"bayer2", "bayer4", "bayer8"}) {
        const Image img = draw(with_adjust(8, 8, "#808080", Json::array({op("dither", {{"method", method}})})));
        CHECK(count_if_pixels(img, whites) + count_if_pixels(img, blacks) == 64);
        CHECK(count_if_pixels(img, whites) == 32);
    }
    // error diffusion keeps the mean tone
    for (const char* method : {"floydSteinberg"}) {
        const Image img = draw(with_adjust(32, 32, "#404040", Json::array({op("dither", {{"method", method}})})));
        CHECK(count_if_pixels(img, whites) + count_if_pixels(img, blacks) == 1024);
        CHECK(std::abs(count_if_pixels(img, whites) - 256) <= 16);
    }
    {  // atkinson spreads three quarters of the error: darker tones lose detail but only palette colours come out
        const Image img = draw(with_adjust(32, 32, "#808080", Json::array({op("dither", {{"method", "atkinson"}})})));
        CHECK(count_if_pixels(img, whites) + count_if_pixels(img, blacks) == 1024);
        CHECK(count_if_pixels(img, whites) > 300);
        CHECK(count_if_pixels(img, whites) < 724);
    }
    // quantize with a dither is the dither operation with that palette; levels without a palette
    CHECK(draw(with_adjust(16, 16, "#808080", Json::array({op("quantize", {{"palette", bw}, {"dither", "bayer4"}})}))).rgba ==
          draw(with_adjust(16, 16, "#808080", Json::array({op("dither", {{"palette", bw}, {"method", "bayer4"}})}))).rgba);
    CHECK(near(get(draw(with_adjust(1, 1, "#aa5500", Json::array({op("dither", {{"method", "none"}, {"levels", 3}})}))), 0, 0), {128, 128, 0, 255}, 1));
    // transparent pixels are left alone
    CHECK(get(draw(doc_of(2, 2, Json::array({fill("#80808000", {{"adjustments", Json::array({op("dither", {{"method", "floydSteinberg"}})})}})}))), 0, 0).a == 0);
}

TEST_CASE("image ops: the style palette") {
    AssetsProject p;
    write_all(p.file("assets.json"), R"({"style": {"palette": ["#102030", "#f0e0d0"], "lightDirection": 0}})");
    const Json ops = Json::array({op("quantize", {{"palette", "style"}})});
    CHECK(near(get(draw(with_adjust(1, 1, "#202020", ops), p.dir), 0, 0), {0x10, 0x20, 0x30, 255}));
    CHECK(near(get(draw(with_adjust(1, 1, "#e0e0e0", Json::array({op("quantize")})), p.dir), 0, 0), {0xf0, 0xe0, 0xd0, 255}));
    CHECK(near(get(draw(with_adjust(1, 1, "#e0e0e0", Json::array({op("dither", {{"palette", "style"}, {"method", "floydSteinberg"}})})), p.dir), 0, 0), {0xf0, 0xe0, 0xd0, 255}));

    AssetsProject empty;
    auto r = try_draw(with_adjust(1, 1, "#202020", ops), empty.dir);
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("/layers/0/adjustments") != std::string::npos);
    CHECK(r.error().message.find("style.palette") != std::string::npos);
}

TEST_CASE("image ops: outline and stroke") {
    auto opaque_dark = [](Rgba c) { return c.a == 255 && c.r == 0; };
    auto opaque_any = [](Rgba c) { return c.a == 255; };
    {  // width 1 outside a 4x4 square is the 4-connected ring of 16 pixels
        const Image img = draw(with_effects(12, 4, 4, "#ff0000", Json::array({op("outline", {{"color", "#000000"}, {"width", 1}})})));
        CHECK(count_if_pixels(img, opaque_dark) == 16);
        CHECK(count_if_pixels(img, opaque_any) == 32);
        CHECK(get(img, 3, 5) == Rgba{0, 0, 0, 255});
        CHECK(get(img, 8, 5) == Rgba{0, 0, 0, 255});
        CHECK(get(img, 5, 3) == Rgba{0, 0, 0, 255});
        CHECK(get(img, 3, 3).a == 0);  // no diagonal corner
        CHECK(get(img, 2, 5).a == 0);
        CHECK(get(img, 5, 5) == Rgba{255, 0, 0, 255});
    }
    {  // width 2 reaches the corners (distance sqrt 2) but not (distance 2.24) the knight's move
        const Image img = draw(with_effects(14, 4, 5, "#ff0000", Json::array({op("outline", {{"width", 2}})})));
        CHECK(get(img, 4, 4) == Rgba{0, 0, 0, 255});
        CHECK(get(img, 3, 3).a == 0);
        CHECK(get(img, 3, 5) == Rgba{0, 0, 0, 255});
        CHECK(get(img, 2, 6).a == 0);
    }
    {  // inside: the ring of the shape itself, the footprint does not change
        const Image img = draw(with_effects(12, 6, 3, "#ff0000", Json::array({op("outline", {{"width", 1}, {"position", "inside"}})})));
        CHECK(count_if_pixels(img, opaque_dark) == 20);  // 6x6 minus the 4x4 inside
        CHECK(count_if_pixels(img, opaque_any) == 36);
        CHECK(get(img, 5, 5) == Rgba{255, 0, 0, 255});
    }
    {  // center: width 2 is one pixel each side
        const Image img = draw(with_effects(12, 4, 4, "#ff0000", Json::array({op("stroke", {{"width", 2}})})));
        CHECK(get(img, 3, 5) == Rgba{0, 0, 0, 255});
        CHECK(get(img, 4, 5) == Rgba{0, 0, 0, 255});
        CHECK(get(img, 5, 5) == Rgba{255, 0, 0, 255});
        CHECK(get(img, 2, 5).a == 0);
    }
    {  // a stroke colour with alpha, and the smooth edge
        const Image img = draw(with_effects(12, 4, 4, "#ff0000", Json::array({op("outline", {{"color", "#00000080"}})})));
        CHECK(near(get(img, 3, 5), {0, 0, 0, 128}));
        const Image soft = draw(with_effects(12, 4, 4, "#ff0000", Json::array({op("outline", {{"width", 1}, {"smooth", true}})})));
        CHECK(get(soft, 3, 3).a > 0);
        CHECK(get(soft, 3, 3).a < 255);
        CHECK(get(soft, 3, 5).a == 255);
    }
    {  // a layer that touches the edge of its raster can still be outlined inside
        const Image img = draw(with_effects(8, 4, 0, "#ff0000", Json::array({op("outline", {{"position", "inside"}})})));
        CHECK(get(img, 0, 0) == Rgba{0, 0, 0, 255});
        CHECK(get(img, 1, 1) == Rgba{255, 0, 0, 255});
    }
}

TEST_CASE("image ops: shadows and glows") {
    {  // a hard shadow: the shape moved by the offset, behind the layer
        const Image img = draw(with_effects(20, 4, 4, "#ff0000", Json::array({op("dropShadow", {{"offsetX", 3}, {"offsetY", 3}, {"blur", 0}, {"opacity", 1}})})));
        CHECK(get(img, 5, 5) == Rgba{255, 0, 0, 255});
        CHECK(get(img, 10, 10) == Rgba{0, 0, 0, 255});
        CHECK(get(img, 11, 11).a == 0);
        CHECK(get(img, 8, 5).a == 0);
        CHECK(get(img, 8, 8) == Rgba{0, 0, 0, 255});
    }
    {  // a soft shadow keeps its mass, spreads past the hard edge and can be coloured
        const Image hard = draw(with_effects(40, 6, 14, "#ffffff", Json::array({op("dropShadow", {{"offsetX", 8}, {"offsetY", 0}, {"blur", 0}, {"opacity", 1}, {"color", "#0000ff"}})})));
        const Image soft = draw(with_effects(40, 6, 14, "#ffffff", Json::array({op("dropShadow", {{"offsetX", 8}, {"offsetY", 0}, {"blur", 6}, {"opacity", 1}, {"color", "#0000ff"}})})));
        CHECK(std::abs(alpha_mass(hard) - alpha_mass(soft)) < 0.05 * alpha_mass(hard));
        CHECK(get(hard, 27, 16).a == 255);
        CHECK(get(hard, 28, 16).a == 0);
        CHECK(get(soft, 28, 16).a > 0);
        CHECK(near(get(soft, 28, 16), {0, 0, 255, get(soft, 28, 16).a}));
    }
    {  // the glow falls off with the distance and leaves the layer alone
        const Image img = draw(with_effects(24, 4, 10, "#ff0000", Json::array({op("outerGlow", {{"color", "#ffff00"}, {"size", 8}, {"strength", 2}})})));
        CHECK(get(img, 11, 11) == Rgba{255, 0, 0, 255});
        CHECK(get(img, 9, 11).a > get(img, 7, 11).a);
        CHECK(get(img, 7, 11).a > get(img, 4, 11).a);
        CHECK(get(img, 4, 11).a > 0);
        CHECK(get(img, 9, 11).r == 255);
        CHECK(get(img, 9, 11).g == 255);
    }
    {  // the inner glow lights the edge, not the middle, and keeps the alpha
        const Image img = draw(with_effects(24, 16, 4, "#000000", Json::array({op("innerGlow", {{"color", "#ffffff"}, {"size", 6}})})));
        CHECK(get(img, 4, 12).r > get(img, 8, 12).r);
        CHECK(get(img, 8, 12).r > get(img, 12, 12).r);
        CHECK(get(img, 4, 12).a == 255);
        CHECK(get(img, 3, 12).a == 0);
    }
}

TEST_CASE("image ops: blur and sharpen") {
    {
        const Image img = draw(with_effects(25, 1, 12, "#ffffff", Json::array({op("blur", {{"radius", 2}})})));
        CHECK(std::abs(alpha_mass(img) - 1.0) < 0.12);
        CHECK(get(img, 11, 12) == Rgba{255, 255, 255, get(img, 11, 12).a});  // a blur does not darken the colour
        CHECK(get(img, 11, 12).a == get(img, 13, 12).a);
        CHECK(get(img, 12, 12).a > get(img, 11, 12).a);
        CHECK(get(img, 12, 12).a < 255);
        CHECK(get(img, 0, 0).a == 0);
    }
    {  // box: a window of 3 over one pixel is nine 1/9
        const Image img = draw(with_effects(9, 1, 4, "#ffffff", Json::array({op("blur", {{"mode", "box"}, {"radius", 1}})})));
        CHECK(near(get(img, 4, 4), {255, 255, 255, 28}));
        CHECK(near(get(img, 3, 3), {255, 255, 255, 28}));
        CHECK(get(img, 2, 4).a == 0);
    }
    {  // radius 0 changes nothing
        const Image a = draw(with_effects(9, 3, 3, "#336699", Json::array()));
        CHECK(draw(with_effects(9, 3, 3, "#336699", Json::array({op("blur", {{"radius", 0}})}))).rgba == a.rgba);
    }
    {  // sharpen: the sides of an edge move apart, flat areas stay, alpha stays
        Json merged = doc_of(16, 4, Json::array({{{"kind", "group"}, {"layers", Json::array({fill("#666666", {{"width", 8}}), fill("#999999", {{"width", 8}, {"x", 8}})})}, {"effects", Json::array({op("sharpen", {{"radius", 1}, {"amount", 1}})})}}}));
        const Image img = draw(merged);
        const Image plain = draw(doc_of(16, 4, Json::array({fill("#666666", {{"width", 8}}), fill("#999999", {{"width", 8}, {"x", 8}})})));
        CHECK(get(img, 7, 2).r < get(plain, 7, 2).r);
        CHECK(get(img, 8, 2).r > get(plain, 8, 2).r);
        CHECK(get(img, 3, 2).r == get(plain, 3, 2).r);
        CHECK(get(img, 7, 2).a == 255);
        // a threshold above the edge's contrast leaves it alone
        merged["layers"][0]["effects"][0]["threshold"] = 0.9;
        CHECK(draw(merged).rgba == plain.rgba);
    }
}

TEST_CASE("image ops: noise is seeded and deterministic") {
    const auto make = [](int seed, double amount, const char* mode) {
        return with_effects(16, 16, 0, "#808080", Json::array({op("noise", {{"seed", seed}, {"amount", amount}, {"mode", mode}})}));
    };
    const Image a = draw(make(1, 0.2, "mono")), b = draw(make(1, 0.2, "mono")), c = draw(make(2, 0.2, "mono"));
    CHECK(a.rgba == b.rgba);
    CHECK(a.rgba != c.rgba);
    CHECK(draw(make(1, 0, "mono")).rgba == draw(with_effects(16, 16, 0, "#808080", Json::array())).rgba);
    double sum = 0;
    int distinct = 0;
    for (int y = 0; y < 16; ++y)
        for (int x = 0; x < 16; ++x) {
            const Rgba p = get(a, x, y);
            CHECK(p.r == p.g);
            CHECK(p.g == p.b);
            CHECK(std::abs(int(p.r) - 128) <= 52);  // 0.2 * 255 = 51
            sum += p.r - 128.0;
            if (p.r != get(a, 0, 0).r) ++distinct;
        }
    CHECK(distinct > 100);
    CHECK(std::abs(sum / 256.0) < 8.0);
    const Image col = draw(make(1, 0.2, "color"));
    int differing = 0;
    for (int i = 0; i < 16; ++i) differing += get(col, i, 0).r != get(col, i, 0).g;
    CHECK(differing > 5);
    // the pattern belongs to the pixel, not to the size of the layer: the same pixel gets the same noise on a bigger canvas
    const Image big = draw(with_effects(24, 16, 0, "#808080", Json::array({op("noise", {{"seed", 1}, {"amount", 0.2}})})));
    CHECK(get(big, 5, 5) == get(a, 5, 5));
}

TEST_CASE("image ops: shading from a normal map or from the alpha") {
    // a 12x12 grey square lit from the upper left (135 degrees): its left and top edges are brighter than its right and bottom
    const Json square = with_effects(20, 12, 4, "#808080", Json::array({op("shade", {{"lightDirection", 135}})}));
    const Image lit = draw(square);
    CHECK(get(lit, 10, 10) == Rgba{128, 128, 128, 255});  // the flat middle keeps its colour
    CHECK(get(lit, 4, 10).r > get(lit, 15, 10).r);
    CHECK(get(lit, 10, 4).r > get(lit, 10, 15).r);
    CHECK(get(lit, 4, 10).r > 128);
    CHECK(get(lit, 15, 10).r < 128);
    CHECK(get(lit, 4, 10).a == 255);
    // from the upper right the sides swap
    const Image other = draw(with_effects(20, 12, 4, "#808080", Json::array({op("shade", {{"lightDirection", 45}})})));
    CHECK(get(other, 4, 10).r < get(other, 15, 10).r);
    // amount 0 changes nothing
    CHECK(draw(with_effects(20, 12, 4, "#808080", Json::array({op("shade", {{"amount", 0}})}))).rgba == draw(with_effects(20, 12, 4, "#808080", Json::array())).rgba);

    // a normal map leaning to +x (red 255, green flat, blue 255): bright with the light at 0 degrees, dark at 180
    AssetsProject p;
    write_png(p.file("art/n.png"), make_image(20, 20, {255, 128, 255, 255}));
    const Image right = draw(with_effects(20, 12, 4, "#808080", Json::array({op("shade", {{"normalMap", "art/n.png"}, {"lightDirection", 0}})})), p.dir);
    const Image left = draw(with_effects(20, 12, 4, "#808080", Json::array({op("shade", {{"normalMap", "art/n.png"}, {"lightDirection", 180}})})), p.dir);
    CHECK(get(right, 8, 8).r > 128);
    CHECK(get(left, 8, 8).r < 128);
    // a normal map that leans down the picture (green 255 is up in OpenGL maps: light from the top is brighter, flipGreen reverses)
    write_png(p.file("art/ny.png"), make_image(20, 20, {128, 255, 255, 255}));
    const Image up = draw(with_effects(20, 12, 4, "#808080", Json::array({op("shade", {{"normalMap", "art/ny.png"}, {"lightDirection", 90}})})), p.dir);
    const Image flipped = draw(with_effects(20, 12, 4, "#808080", Json::array({op("shade", {{"normalMap", "art/ny.png"}, {"lightDirection", 90}, {"flipGreen", true}})})), p.dir);
    CHECK(get(up, 8, 8).r > 128);
    CHECK(get(flipped, 8, 8).r < 128);
    // the default light is the style's
    write_all(p.file("assets.json"), R"({"style": {"lightDirection": 180}})");
    const Image styled = draw(with_effects(20, 12, 4, "#808080", Json::array({op("shade", {{"normalMap", "art/n.png"}})})), p.dir);
    CHECK(styled.rgba == left.rgba);
}

TEST_CASE("image ops: adjustments in an adjustment layer, effects keep the layer in place") {
    const Image img = draw(doc_of(4, 4, Json::array({fill("#808080"), {{"kind", "adjustment"}, {"adjustments", Json::array({op("threshold")})}}})));
    CHECK(near(get(img, 1, 1), {255, 255, 255, 255}));
    // an effect that grows the layer keeps the pixels where they were, also with a layer offset and a mask
    const Image shifted = draw(doc_of(20, 20, Json::array({fill("#ff0000", {{"width", 4}, {"height", 4}, {"x", 6}, {"y", 7}, {"effects", Json::array({op("outline", {{"width", 2}})})}})})));
    CHECK(get(shifted, 6, 7) == Rgba{255, 0, 0, 255});
    CHECK(get(shifted, 5, 7) == Rgba{0, 0, 0, 255});
    CHECK(get(shifted, 4, 7) == Rgba{0, 0, 0, 255});
    CHECK(get(shifted, 3, 7).a == 0);
    // adjustments run before the masks and effects: a mask cuts the adjusted pixels, the outline follows the cut shape
    const Image masked = draw(doc_of(20, 20, Json::array({fill("#ff0000", {{"width", 8}, {"height", 8}, {"x", 4}, {"y", 4}, {"adjustments", Json::array({op("invert")})},
                                                                               {"masks", Json::array({{{"type", "rect"}, {"x", 0}, {"y", 0}, {"width", 4}, {"height", 8}}})},
                                                                               {"effects", Json::array({op("outline", {{"color", "#ffffff"}})})}})})));
    CHECK(get(masked, 5, 6) == Rgba{0, 255, 255, 255});
    CHECK(get(masked, 8, 6) == Rgba{255, 255, 255, 255});  // the outline of the masked shape
    CHECK(get(masked, 9, 6).a == 0);
    // effects compose in order: a blur then an outline outlines the blurred shape
    const Image chained = draw(with_effects(30, 4, 13, "#ff0000", Json::array({op("blur", {{"radius", 1}}), op("outline", {{"width", 1}})})));
    CHECK(chained.width == 30);
    CHECK(get(chained, 12, 15).a == 255);  // the outline of the blurred shape, behind its soft edge
    CHECK(get(chained, 12, 15).r < 128);
    CHECK(get(chained, 11, 15).a > 0);                  // the halo of the blur, past the outline
    CHECK(get(chained, 11, 15).a < 255);
}

TEST_CASE("image ops: validation names the pointer and suggests") {
    auto in_adj = [](Json o) { return doc_of(4, 4, Json::array({fill("#fff", {{"adjustments", Json::array({std::move(o)})}})})); };
    auto in_fx = [](Json o) { return doc_of(4, 4, Json::array({fill("#fff", {{"effects", Json::array({std::move(o)})}})})); };
    {
        auto issues = problems(in_adj(op("levls")));
        const ImageIssue* i = issue_at(issues, "/layers/0/adjustments/0/type");
        REQUIRE(i != nullptr);
        CHECK(i->hint.find("levels") != std::string::npos);
        issues = problems(in_fx(op("dropShadw")));
        i = issue_at(issues, "/layers/0/effects/0/type");
        REQUIRE(i != nullptr);
        CHECK(i->hint.find("dropShadow") != std::string::npos);
    }
    {
        auto issues = problems(in_adj(op("levels", {{"gama", 2}})));
        const ImageIssue* i = issue_at(issues, "/layers/0/adjustments/0/gama");
        REQUIRE(i != nullptr);
        CHECK(i->hint.find("gamma") != std::string::npos);
    }
    CHECK(issue_at(problems(in_adj(op("levels", {{"gamma", 0}}))), "/layers/0/adjustments/0/gamma") != nullptr);
    CHECK(issue_at(problems(in_adj(op("levels", {{"inBlack", 0.8}, {"inWhite", 0.2}}))), "/layers/0/adjustments/0/inWhite") != nullptr);
    CHECK(issue_at(problems(in_adj(op("levels", {{"channel", "alpha"}}))), "/layers/0/adjustments/0/channel") != nullptr);
    CHECK(issue_at(problems(in_adj(op("curves"))), "/layers/0/adjustments/0") != nullptr);
    CHECK(issue_at(problems(in_adj(op("curves", {{"points", Json::array({Json::array({0, 0}), Json::array({0.5, 0.5}), Json::array({0.5, 0.9})})}}))), "/layers/0/adjustments/0/points/2") != nullptr);
    CHECK(issue_at(problems(in_adj(op("curves", {{"points", Json::array({Json::array({0, 0}), Json::array({2, 1})})}}))), "/layers/0/adjustments/0/points/1") != nullptr);
    CHECK(issue_at(problems(in_adj(op("hsv", {{"saturation", 3}}))), "/layers/0/adjustments/0/saturation") != nullptr);
    CHECK(issue_at(problems(in_adj(op("hsv", {{"colorize", true}, {"hue", -10}}))), "/layers/0/adjustments/0/hue") != nullptr);
    CHECK(issue_at(problems(in_adj(op("posterize", {{"levels", 1}}))), "/layers/0/adjustments/0/levels") != nullptr);
    CHECK(issue_at(problems(in_adj(op("posterize", {{"levels", 2.5}}))), "/layers/0/adjustments/0/levels") != nullptr);
    {
        auto issues = problems(in_adj(op("dither", {{"method", "floydSteinburg"}})));
        const ImageIssue* i = issue_at(issues, "/layers/0/adjustments/0/method");
        REQUIRE(i != nullptr);
        CHECK(i->hint.find("floydSteinberg") != std::string::npos);
    }
    CHECK(issue_at(problems(in_adj(op("quantize", {{"palette", Json::array({"#000000", "nope"})}}))), "/layers/0/adjustments/0/palette/1") != nullptr);
    CHECK(issue_at(problems(in_adj(op("quantize", {{"palette", "mine"}}))), "/layers/0/adjustments/0/palette") != nullptr);
    CHECK(issue_at(problems(in_adj(op("quantize", {{"space", "lab"}}))), "/layers/0/adjustments/0/space") != nullptr);
    CHECK(issue_at(problems(in_adj(op("gradientMap", {{"stops", Json::array({{{"at", 0}, {"color", "#000"}}})}}))), "/layers/0/adjustments/0/stops") != nullptr);
    CHECK(issue_at(problems(in_adj(op("gradientMap", {{"stops", Json::array({{{"at", 0.8}, {"color", "#000"}}, {{"at", 0.2}, {"color", "#fff"}}})}}))), "/layers/0/adjustments/0/stops/1/at") != nullptr);
    CHECK(issue_at(problems(in_adj(op("colorBalance", {{"shadows", Json::array({0, 0})}}))), "/layers/0/adjustments/0/shadows") != nullptr);
    CHECK(issue_at(problems(in_adj(op("threshold", {{"above", "bogus"}}))), "/layers/0/adjustments/0/above") != nullptr);

    CHECK(issue_at(problems(in_fx(op("outline", {{"position", "outwards"}}))), "/layers/0/effects/0/position") != nullptr);
    CHECK(issue_at(problems(in_fx(op("outline", {{"width", 0}}))), "/layers/0/effects/0/width") != nullptr);
    CHECK(issue_at(problems(in_fx(op("dropShadow", {{"opacity", 2}}))), "/layers/0/effects/0/opacity") != nullptr);
    CHECK(issue_at(problems(in_fx(op("dropShadow", {{"blur", -1}}))), "/layers/0/effects/0/blur") != nullptr);
    CHECK(issue_at(problems(in_fx(op("outerGlow", {{"color", 7}}))), "/layers/0/effects/0/color") != nullptr);
    CHECK(issue_at(problems(in_fx(op("blur", {{"mode", "gauss"}}))), "/layers/0/effects/0/mode") != nullptr);
    CHECK(issue_at(problems(in_fx(op("blur", {{"radius", 100}}))), "/layers/0/effects/0/radius") != nullptr);
    CHECK(issue_at(problems(in_fx(op("sharpen", {{"radius", 0}}))), "/layers/0/effects/0/radius") != nullptr);
    CHECK(issue_at(problems(in_fx(op("noise", {{"seed", -1}}))), "/layers/0/effects/0/seed") != nullptr);
    CHECK(issue_at(problems(in_fx(op("shade", {{"elevation", 0}}))), "/layers/0/effects/0/elevation") != nullptr);
    CHECK(issue_at(problems(in_fx(op("shade", {{"normalMap", "art/n.jpg"}}))), "/layers/0/effects/0/normalMap") != nullptr);
    AssetsProject p;
    {
        auto issues = problems(in_fx(op("shade", {{"normalMap", "art/missing.png"}})), p.dir);
        const ImageIssue* i = issue_at(issues, "/layers/0/effects/0/normalMap");
        REQUIRE(i != nullptr);
        CHECK(i->message.find("art/missing.png") != std::string::npos);
    }
    // every problem of a document is reported together
    CHECK(problems(doc_of(4, 4, Json::array({fill("#fff", {{"adjustments", Json::array({op("posterize", {{"levels", 1}}), op("hsv", {{"value", 5}})})}})}))).size() == 2);
}

TEST_CASE("image ops: the schema lists every operation") {
    auto schema = parse_json(testing::read_all(stdfs::path(FA_REPO_ROOT) / "schemas" / "image.schema.json"), "image.schema.json");
    REQUIRE(schema.ok());
    const Json& type = (*schema)["$defs"]["operation"]["properties"]["type"];
    const std::string adj = (*schema)["$defs"]["layer"]["properties"]["adjustments"]["description"].get<std::string>();
    const std::string fx = (*schema)["$defs"]["layer"]["properties"]["effects"]["description"].get<std::string>();
    for (const ImageOpInfo& info : image_adjustment_types()) {
        CHECK_MESSAGE(type["description"].get<std::string>().find(info.name) != std::string::npos, info.name);
        CHECK_MESSAGE(adj.find(info.name) != std::string::npos, info.name);
    }
    for (const ImageOpInfo& info : image_effect_types()) {
        CHECK_MESSAGE(type["description"].get<std::string>().find(info.name) != std::string::npos, info.name);
        CHECK_MESSAGE(fx.find(info.name) != std::string::npos, info.name);
    }
    Json sample = with_effects(
        16, 8, 4, "#808080",
        Json::array({op("outline", {{"width", 1}, {"position", "outside"}}), op("dropShadow", {{"offsetX", 1}}), op("shade", {{"strength", 2}, {"flipGreen", false}}),
                     op("noise", {{"seed", 3}})}));
    sample["layers"][0]["adjustments"] = Json::array({op("levels", {{"inBlack", 0.1}, {"channel", "red"}}), op("quantize", {{"palette", Json::array({"#000", "#fff"})}, {"dither", "bayer4"}}),
                                                       op("curves", {{"points", Json::array({Json::array({0, 0}), Json::array({1, 1})})}}),
                                                       op("gradientMap", {{"stops", Json::array({{{"at", 0}, {"color", "#000"}}, {{"at", 1}, {"color", "#fff"}}})}}),
                                                       op("colorBalance", {{"shadows", Json::array({0, 0, 0.1})}})});
    CHECK(validate_json(*schema, sample).empty());
    CHECK(problems(sample).empty());
}

TEST_CASE("image ops: a 1024 by 1024 layer is processed in reasonable time") {
    const Json doc = doc_of(1024, 1024, Json::array({fill("#406080", {{"width", 900}, {"height", 900}, {"x", 60}, {"y", 60},
                                                                         {"adjustments", Json::array({op("levels", {{"gamma", 1.2}}), op("hsv", {{"hue", 20}}), op("dither", {{"method", "floydSteinberg"}, {"levels", 4}})})},
                                                                         {"effects", Json::array({op("outline", {{"width", 3}}), op("dropShadow", {{"blur", 8}, {"offsetX", 6}, {"offsetY", 6}}), op("sharpen"), op("noise")})}})}));
    const auto start = std::chrono::steady_clock::now();
    const Image img = draw(doc);
    const double seconds = std::chrono::duration<double>(std::chrono::steady_clock::now() - start).count();
    MESSAGE("1024x1024, 3 adjustments and 4 effects: " << seconds << " s");
    CHECK(img.width == 1024);
    CHECK(seconds < 60.0);
}
