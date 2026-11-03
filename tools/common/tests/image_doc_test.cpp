// Layered image documents (*.image.json): the format and its teaching errors, the compositor (every blend mode against the W3C
// formulas written out again here, masks, clipping, groups, each layer kind), determinism, baking with its recipe, the image.*
// commands, project.validate and the export (docs/IMAGES.md).
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <filesystem>

#include "asset_test_helpers.h"
#include "fa/core/json_schema.h"
#include "fa/tooling/image_doc.h"
#include "fa/tooling/export.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
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

Json doc_of(int w, int h, Json layers, Json extra = Json::object()) {
    Json j = {{"format", kImageDocFormat}, {"width", w}, {"height", h}, {"layers", std::move(layers)}};
    for (auto& [k, v] : extra.items()) j[k] = v;
    return j;
}

Image draw(const Json& doc, const std::string& dir = "") {
    auto parsed = parse_image_document(doc, "test.image.json", dir);
    REQUIRE_MESSAGE(parsed.ok(), (parsed.ok() ? "" : parsed.error().message));
    auto render = composite_image_document(*parsed, {dir});
    REQUIRE_MESSAGE(render.ok(), (render.ok() ? "" : render.error().message));
    return render->image;
}

// The problems a document has: every issue, with its pointer.
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
    return std::abs(int(a.r) - int(b.r)) <= tol && std::abs(int(a.g) - int(b.g)) <= tol && std::abs(int(a.b) - int(b.b)) <= tol &&
           std::abs(int(a.a) - int(b.a)) <= tol;
}

// ---- the W3C compositing and blending formulas, written again from the specification (doubles, sorting for the hue modes) ----

struct Rgb {
    double c[3];
};

double ref_lum(const Rgb& x) { return 0.3 * x.c[0] + 0.59 * x.c[1] + 0.11 * x.c[2]; }

Rgb ref_clip(Rgb x) {
    const double l = ref_lum(x);
    const double n = std::min({x.c[0], x.c[1], x.c[2]}), m = std::max({x.c[0], x.c[1], x.c[2]});
    for (double& v : x.c) {
        if (n < 0) v = l + (v - l) * l / (l - n);
    }
    if (m > 1)
        for (double& v : x.c) v = l + (v - l) * (1 - l) / (m - l);
    return x;
}

Rgb ref_set_lum(Rgb x, double l) {
    const double d = l - ref_lum(x);
    for (double& v : x.c) v += d;
    return ref_clip(x);
}

double ref_sat(const Rgb& x) { return std::max({x.c[0], x.c[1], x.c[2]}) - std::min({x.c[0], x.c[1], x.c[2]}); }

Rgb ref_set_sat(Rgb x, double s) {
    int idx[3] = {0, 1, 2};
    std::sort(idx, idx + 3, [&](int a, int b) { return x.c[a] < x.c[b]; });  // idx[0] = min, idx[2] = max
    Rgb out{{0, 0, 0}};
    const double mn = x.c[idx[0]], md = x.c[idx[1]], mx = x.c[idx[2]];
    if (mx > mn) {
        out.c[idx[1]] = (md - mn) * s / (mx - mn);
        out.c[idx[2]] = s;
    }
    return out;
}

double ref_hard_light(double cb, double cs) { return cs <= 0.5 ? cb * 2 * cs : cb + (2 * cs - 1) - cb * (2 * cs - 1); }

double ref_channel(ImageBlend mode, double cb, double cs) {
    switch (mode) {
        case ImageBlend::Normal: return cs;
        case ImageBlend::Multiply: return cb * cs;
        case ImageBlend::Screen: return cb + cs - cb * cs;
        case ImageBlend::Overlay: return ref_hard_light(cs, cb);
        case ImageBlend::Darken: return std::min(cb, cs);
        case ImageBlend::Lighten: return std::max(cb, cs);
        case ImageBlend::ColorDodge: return cb == 0 ? 0 : cs >= 1 ? 1 : std::min(1.0, cb / (1 - cs));
        case ImageBlend::ColorBurn: return cb >= 1 ? 1 : cs <= 0 ? 0 : 1 - std::min(1.0, (1 - cb) / cs);
        case ImageBlend::HardLight: return ref_hard_light(cb, cs);
        case ImageBlend::SoftLight: {
            if (cs <= 0.5) return cb - (1 - 2 * cs) * cb * (1 - cb);
            const double d = cb <= 0.25 ? ((16 * cb - 12) * cb + 4) * cb : std::sqrt(cb);
            return cb + (2 * cs - 1) * (d - cb);
        }
        case ImageBlend::Difference: return std::fabs(cb - cs);
        case ImageBlend::Exclusion: return cb + cs - 2 * cb * cs;
        case ImageBlend::Add: return std::min(1.0, cb + cs);
        case ImageBlend::Subtract: return std::max(0.0, cb - cs);
        default: return cs;
    }
}

Rgb ref_blend(ImageBlend mode, const Rgb& cb, const Rgb& cs) {
    switch (mode) {
        case ImageBlend::Hue: return ref_set_lum(ref_set_sat(cs, ref_sat(cb)), ref_lum(cb));
        case ImageBlend::Saturation: return ref_set_lum(ref_set_sat(cb, ref_sat(cs)), ref_lum(cb));
        case ImageBlend::Color: return ref_set_lum(cs, ref_lum(cb));
        case ImageBlend::Luminosity: return ref_set_lum(cb, ref_lum(cs));
        default: {
            Rgb out{};
            for (int i = 0; i < 3; ++i) out.c[i] = ref_channel(mode, cb.c[i], cs.c[i]);
            return out;
        }
    }
}

// Cr = (1 - as/ar) Cb + as/ar ((1 - ab) Cs + ab B(Cb, Cs)),  ar = as + ab (1 - as)
Color ref_composite(ImageBlend mode, Color b, Color s) {
    const double ab = b.a, as = s.a, ar = as + ab * (1 - as);
    if (ar <= 0) return {0, 0, 0, 0};
    const Rgb cb{{b.r, b.g, b.b}}, cs{{s.r, s.g, s.b}};
    const Rgb mixed = ref_blend(mode, cb, cs);
    double r[3];
    for (int i = 0; i < 3; ++i) r[i] = (1 - as / ar) * cb.c[i] + as / ar * ((1 - ab) * cs.c[i] + ab * mixed.c[i]);
    return {float(r[0]), float(r[1]), float(r[2]), float(ar)};
}

}  // namespace

// ---- blend modes -------------------------------------------------------------------------------------------------------

TEST_CASE("image blend: names, parsing and the eighteen modes") {
    const std::vector<std::string> names = image_blend_names();
    CHECK(names.size() == 18);
    for (std::size_t i = 0; i < names.size(); ++i) {
        auto mode = parse_image_blend(names[i]);
        REQUIRE(mode.has_value());
        CHECK(int(*mode) == int(i));
        CHECK(names[i] == image_blend_name(*mode));
    }
    CHECK_FALSE(parse_image_blend("multiplyy").has_value());
    CHECK(image_layer_kind_names().size() == 11);
}

TEST_CASE("image blend: every mode matches the W3C formulas for opaque, translucent and transparent backdrops") {
    const Color colors[] = {{0.2f, 0.5f, 0.8f, 1.0f},  {0.9f, 0.3f, 0.1f, 1.0f}, {0.0f, 0.0f, 0.0f, 1.0f}, {1.0f, 1.0f, 1.0f, 1.0f},
                            {0.5f, 0.5f, 0.5f, 1.0f},  {0.1f, 0.9f, 0.4f, 0.6f}, {0.7f, 0.2f, 0.6f, 0.5f}, {0.3f, 0.3f, 0.9f, 0.25f},
                            {0.8f, 0.8f, 0.2f, 0.0f},  {1.0f, 0.0f, 0.0f, 1.0f}, {0.25f, 0.75f, 0.25f, 1.0f}, {0.4f, 0.6f, 0.45f, 0.9f}};
    int checked = 0;
    for (const std::string& name : image_blend_names()) {
        const ImageBlend mode = *parse_image_blend(name);
        for (const Color& b : colors)
            for (const Color& s : colors) {
                if (s.a <= 0) continue;  // a source with no alpha leaves the backdrop alone: tested below
                const Color got = blend_pixel(mode, b, s);
                const Color want = ref_composite(mode, b, s);
                const std::string where = name + " backdrop (" + std::to_string(b.r) + "," + std::to_string(b.g) + "," + std::to_string(b.b) + "," +
                                          std::to_string(b.a) + ") source (" + std::to_string(s.r) + "," + std::to_string(s.g) + "," +
                                          std::to_string(s.b) + "," + std::to_string(s.a) + ")";
                CHECK_MESSAGE(std::fabs(got.a - want.a) < 1e-4, where);
                if (want.a > 0) {
                    CHECK_MESSAGE(std::fabs(got.r - want.r) < 2e-4, where);
                    CHECK_MESSAGE(std::fabs(got.g - want.g) < 2e-4, where);
                    CHECK_MESSAGE(std::fabs(got.b - want.b) < 2e-4, where);
                }
                ++checked;
            }
        const Color untouched = blend_pixel(mode, colors[0], {1, 0, 0, 0});
        CHECK(untouched.r == doctest::Approx(colors[0].r));
        CHECK(untouched.a == doctest::Approx(1.0f));
    }
    CHECK(checked > 18 * 100);
}

TEST_CASE("image blend: known values of the classic modes") {
    const Color gray{0.5f, 0.5f, 0.5f, 1}, red{1, 0, 0, 1};
    CHECK(blend_pixel(ImageBlend::Multiply, gray, red).r == doctest::Approx(0.5f));
    CHECK(blend_pixel(ImageBlend::Multiply, gray, red).g == doctest::Approx(0.0f));
    CHECK(blend_pixel(ImageBlend::Screen, gray, red).g == doctest::Approx(0.5f));
    CHECK(blend_pixel(ImageBlend::Difference, red, red).r == doctest::Approx(0.0f));
    CHECK(blend_pixel(ImageBlend::Add, {0.7f, 0, 0, 1}, {0.6f, 0, 0, 1}).r == doctest::Approx(1.0f));
    CHECK(blend_pixel(ImageBlend::Subtract, {0.7f, 0, 0, 1}, {0.6f, 0, 0, 1}).r == doctest::Approx(0.1f));
    // luminosity keeps the backdrop's hue: a gray source on red makes a darker red, never a gray
    const Color lum = blend_pixel(ImageBlend::Luminosity, red, {0.2f, 0.2f, 0.2f, 1});
    CHECK(lum.r > lum.g);
    // a half-transparent normal layer over transparent keeps its colour (straight alpha): no darkening of the edge
    const Color edge = blend_pixel(ImageBlend::Normal, {0, 0, 0, 0}, {1, 0.5f, 0.25f, 0.5f});
    CHECK(edge.r == doctest::Approx(1.0f));
    CHECK(edge.g == doctest::Approx(0.5f));
    CHECK(edge.a == doctest::Approx(0.5f));
}

// ---- the compositor ------------------------------------------------------------------------------------------------------

TEST_CASE("image doc: opacity, background, visibility and offsets") {
    {
        const Image img = draw(doc_of(4, 4, Json::array({fill("#0000ff"), fill("#ff0000", {{"opacity", 0.5}})})));
        CHECK(near(get(img, 1, 1), {128, 0, 128, 255}));
    }
    {  // over nothing the colour stays whole and only the alpha is half: straight alpha, like the PNG a Sprite draws
        const Image img = draw(doc_of(4, 4, Json::array({fill("#ff0000", {{"opacity", 0.5}})})));
        CHECK(near(get(img, 1, 1), {255, 0, 0, 128}));
    }
    {
        const Image img = draw(doc_of(4, 4, Json::array(), {{"background", "#336699"}}));
        CHECK(get(img, 2, 2) == Rgba{0x33, 0x66, 0x99, 255});
    }
    {  // a transparent canvas is (0, 0, 0, 0)
        const Image img = draw(doc_of(2, 2, Json::array()));
        CHECK(get(img, 0, 0) == Rgba{0, 0, 0, 0});
    }
    {
        const Image img = draw(doc_of(4, 4, Json::array({fill("#00ff00", {{"visible", false}})}), {{"background", "#000000"}}));
        CHECK(get(img, 1, 1) == Rgba{0, 0, 0, 255});
    }
    {  // a layer box (width, height) moved by x, y; negative offsets and parts outside the canvas are cut
        const Image img = draw(doc_of(8, 8, Json::array({fill("#ffffff", {{"width", 4}, {"height", 4}, {"x", -2}, {"y", 6}})})));
        CHECK(get(img, 0, 6).a == 255);
        CHECK(get(img, 1, 7).a == 255);
        CHECK(get(img, 2, 6).a == 0);
        CHECK(get(img, 0, 5).a == 0);
    }
}

TEST_CASE("image doc: a blend mode on a layer mixes with the pixels below") {
    const Image img = draw(doc_of(2, 2, Json::array({fill("#ff8040"), fill("#808080", {{"blend", "multiply"}})})));
    CHECK(near(get(img, 0, 0), {128, 64, 32, 255}));
    const Image screen = draw(doc_of(2, 2, Json::array({fill("#000000"), fill("#336699", {{"blend", "screen"}})})));
    CHECK(near(get(screen, 0, 0), {0x33, 0x66, 0x99, 255}));
}

TEST_CASE("image doc: groups are drawn together, with their own opacity, and isolate the blend modes inside") {
    {
        // two layers in a group at 50%: the overlap shows the top one at 50% over white, not the bottom one through it
        const Image img = draw(doc_of(8, 8,
                                      Json::array({fill("#ffffff"),
                                                   {{"kind", "group"}, {"opacity", 0.5}, {"layers", Json::array({fill("#ff0000"), fill("#0000ff", {{"width", 4}, {"height", 4}})})}}})));
        CHECK(near(get(img, 1, 1), {128, 128, 255, 255}));
        CHECK(near(get(img, 6, 6), {255, 128, 128, 255}));
    }
    {
        // the multiply layer is inside a group over nothing, so it multiplies with nothing; the same layer outside multiplies the gray
        const Image grouped = draw(doc_of(2, 2, Json::array({{{"kind", "group"}, {"layers", Json::array({fill("#ff0000", {{"blend", "multiply"}})})}}}), {{"background", "#808080"}}));
        CHECK(near(get(grouped, 0, 0), {255, 0, 0, 255}));
        const Image flat = draw(doc_of(2, 2, Json::array({fill("#ff0000", {{"blend", "multiply"}})}), {{"background", "#808080"}}));
        CHECK(near(get(flat, 0, 0), {128, 0, 0, 255}));
    }
    {  // a group takes the blend mode, masks and offset of its own
        const Image img = draw(doc_of(4, 4, Json::array({{{"kind", "group"}, {"x", 2}, {"blend", "multiply"}, {"layers", Json::array({fill("#808080")})}}}), {{"background", "#ffffff"}}));
        CHECK(near(get(img, 3, 0), {128, 128, 128, 255}));
        CHECK(get(img, 1, 0) == Rgba{255, 255, 255, 255});
    }
}

TEST_CASE("image doc: masks hide the layer by rectangle, ellipse, polygon, path and picture, invert and feather") {
    const auto masked = [](Json mask) { return draw(doc_of(16, 16, Json::array({fill("#ffffff", {{"masks", Json::array({mask})}})}))); };
    {
        const Image img = masked({{"type", "rect"}, {"x", 4}, {"y", 4}, {"width", 4}, {"height", 8}});
        CHECK(get(img, 4, 4).a == 255);
        CHECK(get(img, 7, 11).a == 255);
        CHECK(get(img, 8, 4).a == 0);
        CHECK(get(img, 3, 4).a == 0);
        CHECK(get(img, 4, 12).a == 0);
    }
    {
        const Image img = masked({{"type", "rect"}, {"x", 4}, {"y", 4}, {"width", 4}, {"height", 8}, {"invert", true}});
        CHECK(get(img, 4, 4).a == 0);
        CHECK(get(img, 0, 0).a == 255);
    }
    {
        const Image img = masked({{"type", "ellipse"}, {"x", 0}, {"y", 0}, {"width", 16}, {"height", 16}});
        CHECK(get(img, 8, 8).a == 255);
        CHECK(get(img, 0, 0).a == 0);
        CHECK(get(img, 15, 15).a == 0);
        int partial = 0;  // the anti-aliased rim of the circle
        for (int y = 0; y < 16; ++y)
            for (int x = 0; x < 16; ++x) partial += get(img, x, y).a > 0 && get(img, x, y).a < 255;
        CHECK(partial > 8);
    }
    {
        const Image img = masked({{"type", "polygon"}, {"points", Json::array({Json::array({0, 0}), Json::array({16, 0}), Json::array({0, 16})})}});
        CHECK(get(img, 1, 1).a == 255);
        CHECK(get(img, 14, 14).a == 0);
    }
    {
        const Image img = masked({{"type", "path"}, {"path", "M0 0 H8 V16 H0 Z"}});
        CHECK(get(img, 3, 8).a == 255);
        CHECK(get(img, 12, 8).a == 0);
        const Image curve = masked({{"type", "path"}, {"path", "M0 8 C0 0 16 0 16 8 Q8 20 0 8 Z"}});
        CHECK(get(curve, 8, 5).a == 255);
        CHECK(get(curve, 8, 15).a == 0);
    }
    {
        AssetsProject p;
        Image m = make_image(16, 16, {0, 0, 0, 255});
        fill_rect(m, 0, 0, 8, 16, {255, 255, 255, 255});
        write_png(p.file("m.png"), m);
        const Image img = draw(doc_of(16, 16, Json::array({fill("#ffffff", {{"masks", Json::array({{{"type", "pixels"}, {"source", "m.png"}}})}})})), p.dir);
        CHECK(get(img, 2, 2).a == 255);
        CHECK(get(img, 12, 2).a == 0);
        // a picture mask smaller than the layer hides everything outside it
        Image small = make_image(4, 4, {255, 255, 255, 255});
        write_png(p.file("small.png"), small);
        const Image img2 = draw(doc_of(16, 16, Json::array({fill("#ffffff", {{"masks", Json::array({{{"type", "pixels"}, {"source", "small.png"}, {"x", 6}, {"y", 6}}})}})})), p.dir);
        CHECK(get(img2, 7, 7).a == 255);
        CHECK(get(img2, 2, 2).a == 0);
        CHECK(get(img2, 11, 11).a == 0);
    }
    {  // several masks multiply: the intersection
        const Image img = draw(doc_of(16, 16, Json::array({fill("#ffffff", {{"masks", Json::array({{{"type", "rect"}, {"x", 0}, {"y", 0}, {"width", 8}, {"height", 16}},
                                                                                                  {{"type", "rect"}, {"x", 4}, {"y", 0}, {"width", 12}, {"height", 16}}})}})})));
        CHECK(get(img, 2, 3).a == 0);
        CHECK(get(img, 5, 3).a == 255);
        CHECK(get(img, 10, 3).a == 0);
    }
    {  // mask coordinates are the layer's own, so they move with the layer's offset
        const Image img = draw(doc_of(16, 16, Json::array({fill("#ffffff", {{"width", 8}, {"height", 8}, {"x", 8}, {"y", 8}, {"masks", Json::array({{{"type", "rect"}, {"x", 0}, {"y", 0}, {"width", 2}, {"height", 2}}})}})})));
        CHECK(get(img, 8, 8).a == 255);
        CHECK(get(img, 9, 9).a == 255);
        CHECK(get(img, 10, 10).a == 0);
        CHECK(get(img, 0, 0).a == 0);
    }
    {  // a feathered edge goes smoothly from shown to hidden
        const Image img = masked({{"type", "rect"}, {"x", 4}, {"y", 4}, {"width", 8}, {"height", 8}, {"feather", 6}});
        int previous = -1;
        bool rising = true;
        for (int x = 0; x <= 8; ++x) {
            const int a = get(img, x, 8).a;
            if (a < previous) rising = false;
            previous = a;
        }
        CHECK(rising);
        CHECK(get(img, 8, 8).a > 100);
        CHECK(get(img, 8, 8).a < 255);
        CHECK(get(img, 0, 8).a < 60);
        CHECK(get(img, 4, 4).a < get(img, 8, 8).a);  // a corner is softer than the middle of an edge... and the middle is the brightest
    }
}

TEST_CASE("image doc: clipping follows the shape of the layer below") {
    const Json base = fill("#ff0000", {{"width", 4}, {"height", 4}, {"x", 2}, {"y", 2}});
    {
        const Image img = draw(doc_of(8, 8, Json::array({base, fill("#0000ff", {{"clip", true}})})));
        CHECK(get(img, 3, 3) == Rgba{0, 0, 255, 255});
        CHECK(get(img, 0, 0).a == 0);
        CHECK(get(img, 6, 6).a == 0);
    }
    {  // two clipped layers follow the same base
        const Image img = draw(doc_of(8, 8, Json::array({base, fill("#0000ff", {{"clip", true}, {"x", 2}, {"width", 2}, {"height", 8}}), fill("#00ff00", {{"clip", true}, {"x", 4}, {"width", 4}, {"height", 8}})})));
        CHECK(get(img, 2, 3) == Rgba{0, 0, 255, 255});
        CHECK(get(img, 4, 3) == Rgba{0, 255, 0, 255});
        CHECK(get(img, 7, 3).a == 0);
    }
    {  // a clipped layer keeps its own blend mode inside the base's shape
        const Image img = draw(doc_of(8, 8, Json::array({fill("#ffffff"), base, fill("#808080", {{"clip", true}, {"blend", "multiply"}})})));
        CHECK(near(get(img, 3, 3), {128, 0, 0, 255}));
        CHECK(get(img, 0, 0) == Rgba{255, 255, 255, 255});
    }
    {  // a hidden base hides the layers clipped to it
        const Image img = draw(doc_of(8, 8, Json::array({fill("#ff0000", {{"width", 4}, {"height", 4}, {"visible", false}}), fill("#0000ff", {{"clip", true}})})));
        CHECK(get(img, 1, 1).a == 0);
    }
    {  // the base's masks shape the clip too
        const Image img = draw(doc_of(8, 8, Json::array({fill("#ff0000", {{"masks", Json::array({{{"type", "rect"}, {"x", 0}, {"y", 0}, {"width", 4}, {"height", 8}}})}}), fill("#0000ff", {{"clip", true}})})));
        CHECK(get(img, 1, 1) == Rgba{0, 0, 255, 255});
        CHECK(get(img, 6, 1).a == 0);
    }
}

TEST_CASE("image doc: gradient layers, linear and radial") {
    {
        const Image img = draw(doc_of(4, 4, Json::array({{{"kind", "gradient"}, {"gradient", {{"type", "linear"}, {"angle", 0}, {"stops", Json::array({{{"at", 0}, {"color", "#000000"}}, {{"at", 1}, {"color", "#ffffff"}}})}}}}})));
        CHECK(near(get(img, 1, 0), {32, 32, 32, 255}));
        CHECK(near(get(img, 1, 3), {223, 223, 223, 255}));
        CHECK(get(img, 0, 1) == get(img, 3, 1));
    }
    {
        const Image img = draw(doc_of(4, 4, Json::array({{{"kind", "gradient"}, {"gradient", {{"angle", 90}, {"stops", Json::array({{{"at", 0}, {"color", "#000000"}}, {{"at", 1}, {"color", "#ffffff"}}})}}}}})));
        CHECK(near(get(img, 0, 2), {32, 32, 32, 255}));
        CHECK(near(get(img, 3, 2), {223, 223, 223, 255}));
        CHECK(get(img, 1, 0) == get(img, 1, 3));
    }
    {
        const Image img = draw(doc_of(8, 8, Json::array({{{"kind", "gradient"}, {"gradient", {{"type", "radial"}, {"stops", Json::array({{{"at", 0}, {"color", "#ffffff"}}, {{"at", 1}, {"color", "#000000"}}})}}}}})));
        CHECK(get(img, 3, 3).r > 200);
        CHECK(get(img, 0, 0).r < 60);
        CHECK(get(img, 3, 3).r > get(img, 1, 1).r);
    }
    {  // three stops, and the stops' alpha is interpolated premultiplied: no dark fringe between a colour and transparent
        const Image img = draw(doc_of(8, 1, Json::array({{{"kind", "gradient"}, {"gradient", {{"angle", 90}, {"stops", Json::array({{{"at", 0}, {"color", "#ff0000"}}, {{"at", 1}, {"color", "#ff000000"}}})}}}}})));
        const Rgba mid = get(img, 4, 0);
        CHECK(mid.r >= 254);
        CHECK(mid.a > 0);
        CHECK(mid.a < 255);
    }
}

TEST_CASE("image doc: procedural layers are the texture generator's pictures") {
    AssetsProject p;
    p.ok("assets.generate_texture", {{"path", "assets/t.png"}, {"preset", "parchment"}, {"width", 16}, {"height", 16}, {"seed", 3}});
    const Image direct = read_png(p.file("assets/t.png"));
    const Image layered = draw(doc_of(16, 16, Json::array({{{"kind", "procedural"}, {"texture", {{"preset", "parchment"}, {"seed", 3}}}}})), p.dir);
    REQUIRE(layered.width == 16);
    CHECK(layered.rgba == direct.rgba);
}

TEST_CASE("image doc: svg layers from text and from a file, fitted inside the box") {
    const char* svg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100' width='100' height='100'><rect width='100' height='100' fill='#ff0000'/></svg>";
    {
        const Image img = draw(doc_of(16, 16, Json::array({{{"kind", "svg"}, {"svg", svg}}})));
        CHECK(near(get(img, 8, 8), {255, 0, 0, 255}));
        CHECK(near(get(img, 0, 0), {255, 0, 0, 255}));
    }
    {
        AssetsProject p;
        write_all(p.file("crest.svg"), svg);
        const Image img = draw(doc_of(16, 16, Json::array({{{"kind", "svg"}, {"source", "crest.svg"}, {"width", 8}, {"height", 8}, {"x", 4}, {"y", 4}}})), p.dir);
        CHECK(near(get(img, 8, 8), {255, 0, 0, 255}));
        CHECK(get(img, 1, 1).a == 0);
        auto parsed = load_image_document(p.dir, "none.image.json");
        CHECK_FALSE(parsed.ok());
    }
}

TEST_CASE("image doc: text layers are drawn with an engine font, aligned from their x") {
    const auto bounds = [](const Image& img) {
        int minX = img.width, maxX = -1;
        for (int y = 0; y < img.height; ++y)
            for (int x = 0; x < img.width; ++x)
                if (get(img, x, y).a > 0) {
                    minX = std::min(minX, x);
                    maxX = std::max(maxX, x);
                }
        return std::pair<int, int>(minX, maxX);
    };
    const auto text = [&](const std::string& align) {
        return draw(doc_of(96, 40, Json::array({{{"kind", "text"}, {"text", "Hello"}, {"size", 20}, {"color", "#ffffff"}, {"x", 48}, {"y", 8}, {"align", align}}})));
    };
    const Image left = text("left"), center = text("center"), right = text("right");
    const auto [l0, l1] = bounds(left);
    const auto [c0, c1] = bounds(center);
    const auto [r0, r1] = bounds(right);
    REQUIRE(l1 > 0);
    CHECK(l0 >= 46);
    CHECK(c0 < 48);
    CHECK(c1 > 48);
    CHECK(r1 <= 50);
    CHECK(r0 < c0);
    CHECK(c0 < l0);
    // the colour is the layer's, the alpha the glyph's coverage
    bool solid = false;
    for (int y = 0; y < left.height; ++y)
        for (int x = 0; x < left.width; ++x)
            if (get(left, x, y).a == 255) {
                CHECK(get(left, x, y).r == 255);
                solid = true;
            }
    CHECK(solid);
    // the pixel font works too, and a missing font is a teaching error
    CHECK(bounds(draw(doc_of(64, 16, Json::array({{{"kind", "text"}, {"text", "ok"}, {"font", "builtin:pixel"}, {"size", 8}}})))).second > 0);
    CHECK(problems(doc_of(8, 8, Json::array({{{"kind", "text"}, {"text", "x"}, {"font", "builtin:pixle"}}})))[0].pointer == "/layers/0/font");
}

TEST_CASE("image doc: pixels layers copy a PNG at their offset; provider layers draw the same") {
    AssetsProject p;
    Image src = make_image(2, 2, {10, 20, 30, 255});
    fill_rect(src, 1, 1, 1, 1, {200, 100, 50, 128});
    write_png(p.file("art/src.png"), src);
    for (const char* kind : {"pixels", "provider"}) {
        const Image img = draw(doc_of(6, 6, Json::array({{{"kind", kind}, {"source", "art/src.png"}, {"x", 3}, {"y", 2}}})), p.dir);
        CHECK(get(img, 3, 2) == Rgba{10, 20, 30, 255});
        CHECK(get(img, 4, 3) == Rgba{200, 100, 50, 128});
        CHECK(get(img, 0, 0).a == 0);
        CHECK(get(img, 5, 5).a == 0);
    }
}

TEST_CASE("image doc: adjustments, adjustment layers and effects") {
    {
        const Image img = draw(doc_of(2, 2, Json::array({fill("#ff0000", {{"adjustments", Json::array({{{"type", "invert"}}})}})})));
        CHECK(get(img, 0, 0) == Rgba{0, 255, 255, 255});
    }
    {  // the adjustment layer works on what is below it, within its masks
        const Image img = draw(doc_of(8, 8, Json::array({fill("#ff0000"), {{"kind", "adjustment"}, {"adjustments", Json::array({{{"type", "invert"}}})}, {"masks", Json::array({{{"type", "rect"}, {"x", 0}, {"y", 0}, {"width", 4}, {"height", 8}}})}}})));
        CHECK(get(img, 1, 1) == Rgba{0, 255, 255, 255});
        CHECK(get(img, 6, 1) == Rgba{255, 0, 0, 255});
        const Image half = draw(doc_of(2, 2, Json::array({fill("#000000"), {{"kind", "adjustment"}, {"opacity", 0.5}, {"adjustments", Json::array({{{"type", "invert"}}})}}})));
        CHECK(near(get(half, 0, 0), {128, 128, 128, 255}));
        const Image bright = draw(doc_of(2, 2, Json::array({fill("#000000"), {{"kind", "adjustment"}, {"adjustments", Json::array({{{"type", "brightness"}, {"amount", 0.5}}})}}})));
        CHECK(near(get(bright, 0, 0), {128, 128, 128, 255}));
    }
    {  // an adjustment layer that clips only touches the base's shape
        const Image img = draw(doc_of(8, 8, Json::array({fill("#ff0000", {{"width", 4}, {"height", 8}}), {{"kind", "adjustment"}, {"clip", true}, {"adjustments", Json::array({{{"type", "invert"}}})}}})));
        CHECK(get(img, 1, 1) == Rgba{0, 255, 255, 255});
        CHECK(get(img, 6, 1).a == 0);
    }
    {
        const Image img = draw(doc_of(2, 2, Json::array({fill("#000000", {{"effects", Json::array({{{"type", "colorOverlay"}, {"color", "#ffffff"}, {"amount", 0.5}}})}})})));
        CHECK(near(get(img, 0, 0), {128, 128, 128, 255}));
    }
}

TEST_CASE("image doc: the same document draws the same bytes, and the bake does too") {
    AssetsProject p;
    write_png(p.file("src.png"), make_image(8, 8, {40, 90, 140, 255}));
    const Json doc = doc_of(
        48, 32,
        Json::array({{{"kind", "procedural"}, {"texture", {{"preset", "parchment"}, {"seed", 5}}}},
                     {{"kind", "gradient"}, {"blend", "overlay"}, {"gradient", {{"type", "radial"}, {"stops", Json::array({{{"at", 0}, {"color", "#ffffff"}}, {{"at", 1}, {"color", "#000000"}}})}}}},
                     {{"kind", "pixels"}, {"source", "src.png"}, {"x", 5}, {"y", 5}, {"blend", "softLight"}, {"masks", Json::array({{{"type", "ellipse"}, {"x", 0}, {"y", 0}, {"width", 8}, {"height", 8}, {"feather", 2}}})}},
                     {{"kind", "text"}, {"text", "Hi"}, {"size", 14}, {"x", 20}, {"y", 6}, {"color", "#ffeecc"}},
                     {{"kind", "group"}, {"opacity", 0.7}, {"layers", Json::array({fill("#223344", {{"width", 10}, {"height", 10}}), fill("#aa5500", {{"width", 5}, {"height", 5}, {"blend", "difference"}})})}}}));
    const Image a = draw(doc, p.dir), b = draw(doc, p.dir);
    CHECK(a.rgba == b.rgba);
    write_all(p.file("d.image.json"), doc.dump(2));
    p.ok("image.bake", {{"path", "d.image.json"}});
    const std::string first = read_all(p.file("d.png"));
    std::filesystem::remove(p.file("d.png"));
    p.ok("image.bake", {{"path", "d.image.json"}});
    CHECK(read_all(p.file("d.png")) == first);
    CHECK(read_png(p.file("d.png")).rgba == a.rgba);
}

// ---- validation: teaching errors -----------------------------------------------------------------------------------------

TEST_CASE("image doc: problems say the JSON pointer, what is wrong and a suggestion") {
    SUBCASE("unknown layer kind") {
        auto issues = problems(doc_of(8, 8, Json::array({{{"kind", "fil"}, {"color", "#fff"}}})));
        const ImageIssue* i = issue_at(issues, "/layers/0/kind");
        REQUIRE(i != nullptr);
        CHECK(i->message.find("'fil'") != std::string::npos);
        CHECK(i->hint.find("fill") != std::string::npos);
    }
    SUBCASE("unknown blend mode, with the nested pointer of a group child") {
        auto issues = problems(doc_of(8, 8, Json::array({fill("#fff"), {{"kind", "group"}, {"layers", Json::array({fill("#fff", {{"blend", "multiplyy"}})})}}})));
        const ImageIssue* i = issue_at(issues, "/layers/1/layers/0/blend");
        REQUIRE(i != nullptr);
        CHECK(i->hint.find("multiply") != std::string::npos);
    }
    SUBCASE("unknown key") {
        auto issues = problems(doc_of(8, 8, Json::array({fill("#fff", {{"opacty", 0.5}})})));
        const ImageIssue* i = issue_at(issues, "/layers/0/opacty");
        REQUIRE(i != nullptr);
        CHECK(i->hint.find("opacity") != std::string::npos);
    }
    SUBCASE("unknown key of the document") {
        Json j = doc_of(8, 8, Json::array());
        j["widht"] = 3;
        auto issues = problems(j);
        const ImageIssue* i = issue_at(issues, "/widht");
        REQUIRE(i != nullptr);
        CHECK(i->hint.find("width") != std::string::npos);
    }
    SUBCASE("the canvas") {
        CHECK(issue_at(problems(Json{{"layers", Json::array()}, {"height", 8}}), "") != nullptr);
        CHECK(issue_at(problems(doc_of(0, 8, Json::array())), "/width") != nullptr);
        CHECK(issue_at(problems(doc_of(8, 5000, Json::array())), "/height") != nullptr);
        CHECK(issue_at(problems(doc_of(8, 8, Json::array(), {{"format", "factoria.image/9"}})), "/format") != nullptr);
        CHECK(issue_at(problems(Json::array()), "") != nullptr);
        CHECK(issue_at(problems(Json{{"width", 8}, {"height", 8}}), "") != nullptr);
    }
    SUBCASE("values out of range and of the wrong type") {
        CHECK(issue_at(problems(doc_of(8, 8, Json::array({fill("#fff", {{"opacity", 2}})}))), "/layers/0/opacity") != nullptr);
        CHECK(issue_at(problems(doc_of(8, 8, Json::array({fill("#fff", {{"visible", "yes"}})}))), "/layers/0/visible") != nullptr);
        CHECK(issue_at(problems(doc_of(8, 8, Json::array({fill("#nothex")}))), "/layers/0/color") != nullptr);
        CHECK(issue_at(problems(doc_of(8, 8, Json::array({{{"kind", "fill"}}}))), "/layers/0") != nullptr);
        CHECK(issue_at(problems(doc_of(8, 8, Json::array({5}))), "/layers/0") != nullptr);
    }
    SUBCASE("clip needs a layer below") {
        auto issues = problems(doc_of(8, 8, Json::array({fill("#fff", {{"clip", true}})})));
        const ImageIssue* i = issue_at(issues, "/layers/0/clip");
        REQUIRE(i != nullptr);
        CHECK(i->hint.find("bottom") != std::string::npos);
    }
    SUBCASE("gradients") {
        auto stops = [](Json s) { return doc_of(8, 8, Json::array({{{"kind", "gradient"}, {"gradient", {{"stops", s}}}}})); };
        CHECK(issue_at(problems(stops(Json::array({{{"at", 0}, {"color", "#fff"}}}))), "/layers/0/gradient/stops") != nullptr);
        CHECK(issue_at(problems(stops(Json::array({{{"at", 0.8}, {"color", "#fff"}}, {{"at", 0.2}, {"color", "#000"}}}))), "/layers/0/gradient/stops/1/at") != nullptr);
        CHECK(issue_at(problems(stops(Json::array({{{"at", 0}, {"color", "#fff"}}, {{"at", 3}, {"color", "#000"}}}))), "/layers/0/gradient/stops/1/at") != nullptr);
        CHECK(issue_at(problems(doc_of(8, 8, Json::array({{{"kind", "gradient"}}}))), "/layers/0") != nullptr);
        auto t = problems(doc_of(8, 8, Json::array({{{"kind", "gradient"}, {"gradient", {{"type", "radail"}, {"stops", Json::array({{{"at", 0}, {"color", "#fff"}}, {{"at", 1}, {"color", "#000"}}})}}}}})));
        const ImageIssue* i = issue_at(t, "/layers/0/gradient/type");
        REQUIRE(i != nullptr);
        CHECK(i->hint.find("radial") != std::string::npos);
    }
    SUBCASE("masks") {
        auto issues = problems(doc_of(8, 8, Json::array({fill("#fff", {{"masks", Json::array({{{"type", "elipse"}}})}})})));
        const ImageIssue* i = issue_at(issues, "/layers/0/masks/0/type");
        REQUIRE(i != nullptr);
        CHECK(i->hint.find("ellipse") != std::string::npos);
        CHECK(issue_at(problems(doc_of(8, 8, Json::array({fill("#fff", {{"masks", Json::array({{{"type", "rect"}, {"x", 0}}})}})}))), "/layers/0/masks/0") != nullptr);
        CHECK(issue_at(problems(doc_of(8, 8, Json::array({fill("#fff", {{"masks", Json::array({{{"type", "path"}, {"path", "M 10 Q"}}})}})}))), "/layers/0/masks/0/path") != nullptr);
        CHECK(issue_at(problems(doc_of(8, 8, Json::array({fill("#fff", {{"masks", Json::array({{{"type", "polygon"}, {"points", Json::array({Json::array({0, 0}), Json::array({1, 1})})}}})}})}))), "/layers/0/masks/0/points") != nullptr);
    }
    SUBCASE("adjustments and effects") {
        auto issues = problems(doc_of(8, 8, Json::array({fill("#fff", {{"adjustments", Json::array({{{"type", "invrt"}}})}})})));
        const ImageIssue* i = issue_at(issues, "/layers/0/adjustments/0/type");
        REQUIRE(i != nullptr);
        CHECK(i->hint.find("invert") != std::string::npos);
        CHECK(issue_at(problems(doc_of(8, 8, Json::array({fill("#fff", {{"effects", Json::array({{{"type", "colorOverlay"}}})}})}))), "/layers/0/effects/0") != nullptr);
        CHECK(issue_at(problems(doc_of(8, 8, Json::array({fill("#fff", {{"adjustments", Json::array({{{"type", "brightness"}, {"amount", 4}}})}})}))), "/layers/0/adjustments/0/amount") != nullptr);
        CHECK(issue_at(problems(doc_of(8, 8, Json::array({{{"kind", "adjustment"}}}))), "/layers/0/adjustments") != nullptr);
    }
    SUBCASE("procedural") {
        auto issues = problems(doc_of(8, 8, Json::array({{{"kind", "procedural"}, {"texture", {{"preset", "parchmnt"}}}}})));
        REQUIRE(!issues.empty());
        CHECK(issues[0].pointer.find("/layers/0/texture") == 0);
        CHECK(issues[0].hint.find("parchment") != std::string::npos);
    }
    SUBCASE("svg and text") {
        CHECK(issue_at(problems(doc_of(8, 8, Json::array({{{"kind", "svg"}}}))), "/layers/0") != nullptr);
        CHECK(issue_at(problems(doc_of(8, 8, Json::array({{{"kind", "svg"}, {"svg", "not svg"}}}))), "/layers/0/svg") != nullptr);
        CHECK(issue_at(problems(doc_of(8, 8, Json::array({{{"kind", "text"}, {"text", "x"}, {"align", "centre"}}}))), "/layers/0/align") != nullptr);
        CHECK(issue_at(problems(doc_of(8, 8, Json::array({{{"kind", "text"}}}))), "/layers/0") != nullptr);
        CHECK(issue_at(problems(doc_of(8, 8, Json::array({{{"kind", "group"}}}))), "/layers/0") != nullptr);
    }
    SUBCASE("a file that is not in the project") {
        AssetsProject p;
        auto issues = problems(doc_of(8, 8, Json::array({{{"kind", "pixels"}, {"source", "art/missing.png"}}})), p.dir);
        const ImageIssue* i = issue_at(issues, "/layers/0/source");
        REQUIRE(i != nullptr);
        CHECK(i->message.find("art/missing.png") != std::string::npos);
        auto notPng = problems(doc_of(8, 8, Json::array({{{"kind", "pixels"}, {"source", "art/x.jpg"}}})), p.dir);
        CHECK(issue_at(notPng, "/layers/0/source") != nullptr);
        auto escape = problems(doc_of(8, 8, Json::array({{{"kind", "pixels"}, {"source", "../outside.png"}}})), p.dir);
        CHECK(issue_at(escape, "/layers/0/source") != nullptr);
    }
}

TEST_CASE("image doc: the error of a document names the file, the pointer and how many more problems there are") {
    std::vector<ImageIssue> issues;
    auto parsed = parse_image_document(doc_of(8, 8, Json::array({{{"kind", "fil"}}, fill("#fff", {{"opacity", 9}, {"blend", "mulitply"}})})), "art/bad.image.json", "", &issues);
    REQUIRE_FALSE(parsed.ok());
    CHECK(issues.size() >= 3);
    const std::string message = parsed.error().message;
    CHECK(message.find("art/bad.image.json") != std::string::npos);
    CHECK(message.find("/layers/0/kind") != std::string::npos);
    CHECK(message.find("more problem") != std::string::npos);
    CHECK_FALSE(parsed.error().hint.empty());
}

TEST_CASE("image doc: a file with a JSON syntax error says where") {
    AssetsProject p;
    write_all(p.file("bad.image.json"), "{\n  \"width\": 8,\n  \"height\": 8,\n  \"layers\": [\n}");
    auto doc = load_image_document(p.dir, "bad.image.json");
    REQUIRE_FALSE(doc.ok());
    CHECK(doc.error().message.find("bad.image.json") != std::string::npos);
    CHECK(doc.error().message.find("bad.image.json:5:") != std::string::npos);  // file:line:column
    CHECK(bake_image_document(p.dir, "bad.image.json").ok() == false);
    CHECK(image_bake_status(p.dir, "bad.image.json").state == ImageBakeState::Broken);
}

TEST_CASE("image schema: matches the code, and valid documents pass it") {
    const std::string text = testing::read_all(stdfs::path(FA_REPO_ROOT) / "schemas" / "image.schema.json");
    auto schema = parse_json(text, "image.schema.json");
    REQUIRE(schema.ok());
    const Json& layer = (*schema)["$defs"]["layer"]["properties"];
    CHECK(layer["blend"]["enum"] == Json(image_blend_names()));
    CHECK(layer["kind"]["enum"] == Json(image_layer_kind_names()));
    const Json sample = doc_of(
        32, 32,
        Json::array({fill("#202020", {{"blend", "multiply"}, {"masks", Json::array({{{"type", "ellipse"}, {"x", 0}, {"y", 0}, {"width", 16}, {"height", 16}, {"feather", 2}}})}}),
                     {{"kind", "gradient"}, {"gradient", {{"type", "radial"}, {"stops", Json::array({{{"at", 0}, {"color", "#ffffff"}}, {{"at", 1}, {"color", "#000000"}}})}}}},
                     {{"kind", "text"}, {"text", "Hi"}, {"size", 12}, {"align", "center"}},
                     {{"kind", "group"}, {"layers", Json::array({{{"kind", "procedural"}, {"texture", {{"preset", "parchment"}}}}})}},
                     {{"kind", "adjustment"}, {"adjustments", Json::array({{{"type", "brightness"}, {"amount", 0.1}}})}}}),
        {{"background", "#ffffff"}, {"description", "a sample"}});
    CHECK(validate_json(*schema, sample).empty());
    CHECK(problems(sample).empty());
    Json broken = sample;
    broken["layers"][0]["blend"] = "multiplyy";
    CHECK_FALSE(validate_json(*schema, broken).empty());
}

// ---- baking, provenance and recipes ---------------------------------------------------------------------------------------

namespace {

const Json kSimple = Json::parse(R"({"width": 8, "height": 8, "layers": [{"kind": "fill", "color": "#336699"}]})");

}  // namespace

TEST_CASE("image bake: writes the PNG next to the document with a recipe, and tracks whether it is fresh") {
    AssetsProject p;
    write_all(p.file("art/sky.image.json"), kSimple.dump(2));
    CHECK(image_bake_status(p.dir, "art/sky.image.json").state == ImageBakeState::Missing);
    CHECK(image_document_output(*load_image_document(p.dir, "art/sky.image.json"), "art/sky.image.json") == "art/sky.png");

    const Json r = p.ok("image.bake", {{"path", "art/sky.image.json"}});
    CHECK(r["document"] == "art/sky.image.json");
    CHECK(r["path"] == "art/sky.png");
    CHECK(r["width"] == 8);
    CHECK(r["written"] == true);
    CHECK(r.contains("$image"));
    CHECK(read_png(p.file("art/sky.png")).width == 8);
    CHECK(get(read_png(p.file("art/sky.png")), 3, 3) == Rgba{0x33, 0x66, 0x99, 255});

    const Json prov = p.manifest()["assets"]["art/sky.png"]["provenance"];
    CHECK(prov["recipe"]["command"] == "image.bake");
    CHECK(prov["recipe"]["args"]["path"] == "art/sky.image.json");
    CHECK(prov["recipe"]["inputs"][0]["path"] == "art/sky.image.json");
    CHECK(prov["recipe"]["inputs"][0]["sha256"].is_string());
    CHECK(prov["origin"] == "original");
    CHECK(prov["ai"] == false);
    CHECK(image_bake_status(p.dir, "art/sky.image.json").state == ImageBakeState::Fresh);

    // onlyIfNeeded does nothing while it is fresh
    CHECK(p.ok("image.bake", {{"path", "art/sky.image.json"}, {"onlyIfNeeded", true}})["written"] == false);

    // a changed document is stale, and assets.regenerate (or image.bake) makes the picture again
    Json edited = kSimple;
    edited["layers"][0]["color"] = "#ff0000";
    write_all(p.file("art/sky.image.json"), edited.dump(2));
    CHECK(image_bake_status(p.dir, "art/sky.image.json").state == ImageBakeState::Stale);
    const Json regenerated = p.ok("assets.regenerate", {{"path", "art/sky.png"}});
    CHECK(regenerated["count"] == 1);
    CHECK(get(read_png(p.file("art/sky.png")), 0, 0) == Rgba{255, 0, 0, 255});
    CHECK(image_bake_status(p.dir, "art/sky.image.json").state == ImageBakeState::Fresh);
}

TEST_CASE("image bake: a file a layer reads is an input of the recipe, so changing it makes the bake stale") {
    AssetsProject p;
    write_png(p.file("src.png"), make_image(4, 4, {1, 2, 3, 255}));
    write_all(p.file("d.image.json"), doc_of(4, 4, Json::array({{{"kind", "pixels"}, {"source", "src.png"}}})).dump());
    const Json r = p.ok("image.bake", {{"path", "d.image.json"}});
    CHECK(has_text(r["inputs"], "src.png"));
    CHECK(has_text(r["inputs"], "d.image.json"));
    CHECK(image_bake_status(p.dir, "d.image.json").state == ImageBakeState::Fresh);
    write_png(p.file("src.png"), make_image(4, 4, {9, 9, 9, 255}));
    const ImageBakeStatus stale = image_bake_status(p.dir, "d.image.json");
    CHECK(stale.state == ImageBakeState::Stale);
    CHECK(stale.reason.find("src.png") != std::string::npos);
    p.ok("image.bake", {{"path", "d.image.json"}, {"onlyIfNeeded", true}});
    CHECK(get(read_png(p.file("d.png")), 0, 0) == Rgba{9, 9, 9, 255});
}

TEST_CASE("image bake: a PNG nobody recorded is Unrecorded, an opaque picture is saved without alpha, a custom output works") {
    AssetsProject p;
    write_png(p.file("d.png"), make_image(8, 8, {5, 5, 5, 255}));
    write_all(p.file("d.image.json"), kSimple.dump());
    CHECK(image_bake_status(p.dir, "d.image.json").state == ImageBakeState::Unrecorded);
    p.ok("image.bake", {{"path", "d.image.json"}});
    CHECK(image_bake_status(p.dir, "d.image.json").state == ImageBakeState::Fresh);
    CHECK(get(read_png(p.file("d.png")), 0, 0) == Rgba{0x33, 0x66, 0x99, 255});

    Json custom = kSimple;
    custom["output"] = "out/final.png";
    write_all(p.file("c.image.json"), custom.dump());
    const Json r = p.ok("image.bake", {{"path", "c.image.json"}});
    CHECK(r["path"] == "out/final.png");
    CHECK(p.exists("out/final.png"));
    CHECK(p.manifest()["assets"].contains("out/final.png"));
}

TEST_CASE("image bake: a provider layer makes the picture AI-made and keeps the source's record") {
    AssetsProject p;
    write_png(p.file("gen/key.png"), make_image(4, 4, {200, 160, 40, 255}));
    const Json doc = doc_of(4, 4, Json::array({{{"kind", "provider"}, {"source", "gen/key.png"}, {"provenance", {{"provider", "openai"}, {"model", "gpt-image-1"}, {"prompt", "a brass key"}}}}}));
    write_all(p.file("k.image.json"), doc.dump());
    const Json r = p.ok("image.bake", {{"path", "k.image.json"}});
    const Json m = p.manifest();
    CHECK(m["assets"]["k.png"]["provenance"]["ai"] == true);
    CHECK(r["provenance"]["ai"] == true);
    REQUIRE(m["assets"].contains("gen/key.png"));
    CHECK(m["assets"]["gen/key.png"]["provenance"]["provider"] == "openai");
    CHECK(m["assets"]["gen/key.png"]["provenance"]["prompt"] == "a brass key");
    // a plain pixels layer of an AI-made file passes the flag on
    write_all(p.file("k2.image.json"), doc_of(4, 4, Json::array({{{"kind", "pixels"}, {"source", "gen/key.png"}}})).dump());
    p.ok("image.bake", {{"path", "k2.image.json"}});
    CHECK(p.manifest()["assets"]["k2.png"]["provenance"]["ai"] == true);
}

TEST_CASE("image bake: bake_image_documents_if_needed bakes what is missing or stale and fails on a broken document") {
    AssetsProject p;
    write_all(p.file("a.image.json"), kSimple.dump());
    write_all(p.file("sub/b.image.json"), kSimple.dump());
    write_all(p.file("node_modules/x/c.image.json"), "garbage");
    write_all(p.file(".hidden/d.image.json"), "garbage");
    const auto listed = list_image_documents(p.dir);
    CHECK(listed == std::vector<std::string>{"a.image.json", "sub/b.image.json"});
    auto baked = bake_image_documents_if_needed(p.dir);
    REQUIRE_MESSAGE(baked.ok(), (baked.ok() ? "" : baked.error().message));
    CHECK(baked->size() == 2);
    CHECK(p.exists("a.png"));
    CHECK(p.exists("sub/b.png"));
    auto again = bake_image_documents_if_needed(p.dir);
    REQUIRE(again.ok());
    CHECK(again->empty());
    write_all(p.file("e.image.json"), "{\"width\": 8}");
    auto broken = bake_image_documents_if_needed(p.dir);
    REQUIRE_FALSE(broken.ok());
    CHECK(broken.error().message.find("e.image.json") != std::string::npos);
}

TEST_CASE("image.save: checks the document, writes it as canonical JSON and bakes; a bad document writes nothing") {
    AssetsProject p;
    const Json r = p.ok("image.save", {{"path", "art/new.image.json"}, {"document", kSimple}});
    CHECK(r["path"] == "art/new.png");
    CHECK(p.exists("art/new.png"));
    const std::string text = read_all(p.file("art/new.image.json"));
    CHECK(text.back() == '\n');
    CHECK(Json::parse(text)["width"] == 8);

    const CommandResult bad = p.call("image.save", {{"path", "art/bad.image.json"}, {"document", doc_of(8, 8, Json::array({{{"kind", "fil"}}}))}});
    CHECK_FALSE(bad.ok);
    CHECK(bad.error.dump().find("/layers/0/kind") != std::string::npos);
    CHECK_FALSE(p.exists("art/bad.image.json"));
    CHECK_FALSE(p.call("image.save", {{"path", "art/notadoc.json"}, {"document", kSimple}}).ok);

    p.ok("image.save", {{"path", "art/nobake.image.json"}, {"document", kSimple}, {"bake", false}});
    CHECK(p.exists("art/nobake.image.json"));
    CHECK_FALSE(p.exists("art/nobake.png"));

    const CommandResult missing = p.call("image.bake", {{"path", "art/nothing.image.json"}});
    CHECK_FALSE(missing.ok);
    const CommandResult wrongName = p.call("image.bake", {{"path", "art/sky.json"}});
    CHECK_FALSE(wrongName.ok);
}

TEST_CASE("image bake: a layer whose file went missing fails with the layer's pointer") {
    AssetsProject p;
    write_png(p.file("src.png"), make_image(4, 4, {1, 2, 3, 255}));
    write_all(p.file("d.image.json"), doc_of(4, 4, Json::array({{{"kind", "pixels"}, {"source", "src.png"}}})).dump());
    p.ok("image.bake", {{"path", "d.image.json"}});
    stdfs::remove(p.file("src.png"));
    const CommandResult r = p.call("image.bake", {{"path", "d.image.json"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("/layers/0/source") != std::string::npos);
    CHECK(r.error.dump().find("src.png") != std::string::npos);
}

// ---- project.validate and export ---------------------------------------------------------------------------------------------

TEST_CASE("validate: a broken image document is an error with its pointer; an unbaked one is a warning with the command") {
    TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const std::string dir = tmp.sub("game");
    const ValidationReport before = validate_project(dir);
    write_all(stdfs::path(dir) / "art/bad.image.json", doc_of(8, 8, Json::array({fill("#fff", {{"blend", "multiplyy"}})})).dump());
    write_all(stdfs::path(dir) / "art/ok.image.json", kSimple.dump());
    const ValidationReport r = validate_project(dir);
    CHECK_FALSE(r.ok);
    const ValidationIssue* error = nullptr;
    for (const ValidationIssue& e : r.errors)
        if (e.file == "art/bad.image.json") error = &e;
    REQUIRE(error != nullptr);
    CHECK(error->pointer == "/layers/0/blend");
    CHECK(error->hint.find("multiply") != std::string::npos);
    const ValidationIssue* warning = nullptr;
    for (const ValidationIssue& w : r.warnings)
        if (w.file == "art/ok.image.json") warning = &w;
    REQUIRE(warning != nullptr);
    CHECK(warning->hint.find("image.bake") != std::string::npos);

    // baked, and the warning is gone; edited after, and the stale warning is the recipe check's
    std::filesystem::remove(stdfs::path(dir) / "art/bad.image.json");
    CommandRegistry registry;
    register_asset_commands(registry, dir);
    REQUIRE(registry.call("image.bake", {{"path", "art/ok.image.json"}}).ok);
    const ValidationReport baked = validate_project(dir);
    CHECK(baked.ok);
    CHECK(baked.warnings.size() == before.warnings.size());
    Json edited = kSimple;
    edited["layers"][0]["color"] = "#000000";
    write_all(stdfs::path(dir) / "art/ok.image.json", edited.dump());
    const ValidationReport stale = validate_project(dir);
    bool staleWarning = false;
    for (const ValidationIssue& w : stale.warnings) staleWarning = staleWarning || w.message.find("stale") != std::string::npos;
    CHECK(staleWarning);
}

TEST_CASE("export: image documents are baked before the game is packed") {
    testing::TempDir tmp;
    const std::string proj = tmp.sub("proj");
    REQUIRE(create_project(proj, "2d-platformer").ok());
    const std::string player = tmp.sub("fake_player/factoria_player");
    write_all(player, "#!/bin/sh\nexit 0\n");
    write_all(stdfs::path(proj) / "art/logo.image.json", kSimple.dump());
    ExportOptions o;
    o.projectDir = proj;
    o.platform = "linux";
    o.outDir = tmp.sub("out");
    o.playerBinary = player;
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(stdfs::exists(stdfs::path(proj) / "art/logo.png"));
    CHECK(stdfs::exists(stdfs::path(tmp.sub("out/proj-linux/game")) / "art/logo.png"));

    // a document that does not load stops the export before it touches the output
    write_all(stdfs::path(proj) / "art/broken.image.json", "{\"width\": 8}");
    auto failed = export_project(o);
    REQUIRE_FALSE(failed.ok());
    CHECK(failed.error().message.find("broken.image.json") != std::string::npos);
    CHECK(stdfs::exists(stdfs::path(tmp.sub("out/proj-linux/game")) / "art/logo.png"));
}
