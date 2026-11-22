// Normal maps as pictures you can edit (M74, docs/images/IMAGES_EFFECTS_COMMANDS.md "Normal maps"): the generator is the engine's kernel, the edits keep a map unit
// length, the preview light is the formula of the `shade` operation, and image.normal.generate / image.paint { normal } reach it all.
#include <doctest.h>

#include <algorithm>
#include <cmath>

#include "asset_test_helpers.h"
#include "fa/core/image_tools.h"
#include "fa/tooling/image_doc.h"
#include "fa/tooling/image_normal.h"

using namespace fa;
using namespace fa::testing;

namespace {

constexpr const char* kDoc = "assets/art/hero.image.json";

std::string error_of(const CommandResult& r) {
    return r.error["message"].get<std::string>() + " " + r.error.value("hint", std::string());
}

// A 24x20 sprite: a lit disc (colour varies with x) on a transparent background, so the bevel and the luminance both matter.
Image make_sprite() {
    Image img = make_image(24, 20, {0, 0, 0, 0});
    for (int y = 0; y < 20; ++y)
        for (int x = 0; x < 24; ++x) {
            const double dx = x - 11.5, dy = y - 9.5;
            if (dx * dx + dy * dy > 81) continue;
            std::uint8_t* p = &img.rgba[(std::size_t(y) * 24 + std::size_t(x)) * 4];
            p[0] = std::uint8_t(60 + x * 7);
            p[1] = std::uint8_t(90 + y * 5);
            p[2] = 120;
            p[3] = 255;
        }
    return img;
}

// A noisy grey height picture.
Image make_height() {
    Image img = make_image(16, 16, {0, 0, 0, 255});
    for (int y = 0; y < 16; ++y)
        for (int x = 0; x < 16; ++x) {
            const std::uint8_t v = std::uint8_t(((x * 37 + y * 91 + x * y * 13) % 200) + 20);
            std::uint8_t* p = &img.rgba[(std::size_t(y) * 16 + std::size_t(x)) * 4];
            p[0] = p[1] = p[2] = v;
        }
    return img;
}

double length_of(Rgba c) {
    const double x = c.r / 127.5 - 1, y = c.g / 127.5 - 1, z = c.b / 127.5 - 1;
    return std::sqrt(x * x + y * y + z * z);
}

// A document with the sprite as the pixels layer "hero" (the PNG is project/assets/art/hero-src.png).
void make_hero(const AssetsProject& p, const Image& sprite) {
    write_png(p.file("assets/art/hero-src.png"), sprite);
    p.ok("image.create", {{"path", kDoc}, {"width", sprite.width}, {"height", sprite.height}});
    p.ok("image.layer.add",
         {{"path", kDoc}, {"layer", {{"kind", "pixels"}, {"name", "hero"}, {"source", "assets/art/hero-src.png"}}}});
}

Image draw_doc(const Json& doc, const std::string& dir) {
    auto parsed = parse_image_document(doc, "test.image.json", dir);
    REQUIRE_MESSAGE(parsed.ok(), (parsed.ok() ? "" : parsed.error().message));
    auto r = composite_image_document(*parsed, {dir});
    REQUIRE(r.ok());
    return r->image;
}

Json normal_doc(int w, int h, const std::string& png, Json ops) {
    return {{"format", kImageDocFormat},
            {"width", w},
            {"height", h},
            {"layers",
             Json::array({{{"kind", "pixels"}, {"name", "n"}, {"source", png}, {"adjustments", std::move(ops)}}})}};
}

}  // namespace

TEST_CASE("normal maps: the generator is byte-identical to the engine's kernel") {
    const Image sprite = make_sprite(), height = make_height();
    for (double strength : {0.0, 1.0, 2.5, 8.0}) {
        CAPTURE(strength);
        CHECK(make_normal_map(sprite, "sprite", strength, false).rgba == normal_map_from_sprite(sprite, strength).rgba);
        CHECK(make_normal_map(height, "height", strength, false).rgba ==
              normal_map_from_height_image(height, strength).rgba);
    }
    const Image flat = make_normal_map(sprite, "sprite", 0, false);
    CHECK(get(flat, 0, 0) == Rgba{128, 128, 255, 255});  // opaque, even where the sprite is transparent
    CHECK(make_normal_map(sprite, "nothing", 1, false).empty());
    CHECK(make_normal_map(Image{}, "sprite", 1, false).empty());
    // tile wraps the border: the left and right edges of a tiling height map see each other
    const Image tiled = make_normal_map(height, "height", 4, true),
                clamped = make_normal_map(height, "height", 4, false);
    CHECK(tiled.rgba != clamped.rgba);
    CHECK(get(tiled, 5, 5) == get(clamped, 5, 5));
}

TEST_CASE("normal maps: the normalMap operation, image.normal.generate and image.export give the runtime's bytes") {
    AssetsProject p;
    const Image sprite = make_sprite();
    make_hero(p, sprite);
    const Image expected = normal_map_from_sprite(sprite, 2.0);

    // the operation on a pixels layer (an adjustment of the layer: what the panel's Operations list adds)
    const Image viaOp = draw_doc(
        normal_doc(24, 20, "assets/art/hero-src.png", Json::array({{{"type", "normalMap"}, {"strength", 2}}})), p.dir);
    CHECK(viaOp.rgba == expected.rgba);

    // the command: a hidden pixels layer; the picture of the document does not change
    const Json before = p.ok("image.export", {{"path", kDoc}, {"out", "assets/art/before.png"}});
    const Json r = p.ok("image.normal.generate", {{"path", kDoc}, {"layer", "hero"}, {"strength", 2}});
    CHECK(r["normalMap"]["layer"] == "normal");
    CHECK(r["normalMap"]["from"] == "sprite");
    const Json doc = parse_json(read_all(p.file(kDoc)), kDoc).value();
    REQUIRE(doc["layers"].size() == 2);
    CHECK(doc["layers"][1]["name"] == "normal");
    CHECK(doc["layers"][1]["visible"] == false);
    p.ok("image.export", {{"path", kDoc}, {"out", "assets/art/after.png"}});
    CHECK(read_png(p.file("assets/art/after.png")).rgba == read_png(p.file("assets/art/before.png")).rgba);

    // the export of that layer is a PNG a Sprite.normalMap can use, equal to what the renderer generates for the same sprite
    p.ok("image.export", {{"path", kDoc}, {"layer", "normal"}, {"out", "assets/art/hero-n.png"}});
    const Image exported = read_png(p.file("assets/art/hero-n.png"));
    CHECK(exported.width == 24);
    CHECK(exported.rgba == expected.rgba);
    (void)before;

    // from the whole picture (no layer), a second layer gets a numbered name
    const Json again = p.ok("image.normal.generate", {{"path", kDoc}, {"strength", 2}});
    CHECK(again["normalMap"]["layer"] == "normal 2");

    // a height source
    write_png(p.file("assets/art/h-src.png"), make_height());
    p.ok("image.create", {{"path", "assets/art/h.image.json"}, {"width", 16}, {"height", 16}});
    p.ok("image.layer.add", {{"path", "assets/art/h.image.json"},
                             {"layer", {{"kind", "pixels"}, {"name", "h"}, {"source", "assets/art/h-src.png"}}}});
    p.ok("image.normal.generate",
         {{"path", "assets/art/h.image.json"}, {"layer", "h"}, {"from", "height"}, {"strength", 3}, {"name", "hn"}});
    p.ok("image.export", {{"path", "assets/art/h.image.json"}, {"layer", "hn"}, {"out", "assets/art/h-n.png"}});
    CHECK(read_png(p.file("assets/art/h-n.png")).rgba == normal_map_from_height_image(make_height(), 3.0).rgba);
}

TEST_CASE("normal maps: image.normal.generate goes above the clip chain of its layer, so the picture does not change") {
    AssetsProject p;
    make_hero(p, make_sprite());
    p.ok("image.layer.add",
         {{"path", kDoc}, {"layer", {{"kind", "fill"}, {"name", "tint"}, {"color", "#ff0000"}, {"clip", true}}}});
    p.ok("image.export", {{"path", kDoc}, {"out", "assets/art/clip-before.png"}});
    const Json r = p.ok("image.normal.generate", {{"path", kDoc}, {"layer", "hero"}});
    const Json doc = parse_json(read_all(p.file(kDoc)), kDoc).value();
    REQUIRE(doc["layers"].size() == 3);
    CHECK(doc["layers"][1]["name"] == "tint");  // still right above hero: the hidden layer did not become its clip base
    CHECK(doc["layers"][2]["name"] == "normal");
    CHECK(r["normalMap"]["index"] == "2");
    p.ok("image.export", {{"path", kDoc}, {"out", "assets/art/clip-after.png"}});
    CHECK(read_png(p.file("assets/art/clip-after.png")).rgba == read_png(p.file("assets/art/clip-before.png")).rgba);
}

TEST_CASE("normal maps: image.normal.generate and the operations explain what is wrong") {
    AssetsProject p;
    make_hero(p, make_sprite());
    CommandResult badFrom = p.call("image.normal.generate", {{"path", kDoc}, {"from", "sprit"}});
    REQUIRE_FALSE(badFrom.ok);
    CHECK(error_of(badFrom).find("/from") != std::string::npos);
    CHECK(error_of(badFrom).find("sprite") != std::string::npos);
    CommandResult badStrength = p.call("image.normal.generate", {{"path", kDoc}, {"strength", 99}});
    REQUIRE_FALSE(badStrength.ok);
    CHECK(error_of(badStrength).find("/strength") != std::string::npos);
    CommandResult unknownKey = p.call("image.normal.generate", {{"path", kDoc}, {"strenth", 2}});
    REQUIRE_FALSE(unknownKey.ok);
    CHECK(error_of(unknownKey).find("strength") != std::string::npos);
    CommandResult noLayer = p.call("image.normal.generate", {{"path", kDoc}, {"layer", "heroo"}});
    REQUIRE_FALSE(noLayer.ok);
    CHECK(error_of(noLayer).find("hero") != std::string::npos);
    // a layer, and the generated layer is not in the way of a second command
    p.ok("image.layer.add",
         {{"path", kDoc},
          {"layer", {{"kind", "adjustment"}, {"name", "adj"}, {"adjustments", Json::array({{{"type", "invert"}}})}}}});
    CommandResult adj = p.call("image.normal.generate", {{"path", kDoc}, {"layer", "adj"}});
    REQUIRE_FALSE(adj.ok);
    CHECK(error_of(adj).find("/layer") != std::string::npos);

    // the operations: a JSON pointer at the field
    auto problems_of = [&](Json ops) {
        std::vector<ImageIssue> out;
        (void)parse_image_document(normal_doc(24, 20, "assets/art/hero-src.png", std::move(ops)), "t.image.json", p.dir,
                                   &out);
        return out;
    };
    auto first = [&](Json op) -> std::string {
        const auto out = problems_of(Json::array({std::move(op)}));
        return out.empty() ? std::string() : out[0].pointer + " | " + out[0].message;
    };
    CHECK(first({{"type", "normalFlip"}, {"channel", "z"}}).find("/adjustments/0/channel") != std::string::npos);
    CHECK(first({{"type", "normalFlip"}, {"channel", "z"}}).find("y") != std::string::npos);
    CHECK(first({{"type", "normalSmooth"}, {"radius", 40}}).find("/adjustments/0/radius") != std::string::npos);
    CHECK(first({{"type", "normalStrength"}, {"amount", -1}}).find("/adjustments/0/amount") != std::string::npos);
    CHECK(first({{"type", "normalMap"}, {"from", "heigth"}}).find("/adjustments/0/from") != std::string::npos);
    CHECK(first({{"type", "normalMap"}, {"strength", 100}}).find("/adjustments/0/strength") != std::string::npos);
    CHECK(first({{"type", "normalMap"}, {"source", "assets/art/missing.png"}, {"from", "height"}})
              .find("/adjustments/0/source") != std::string::npos);
    CHECK(first({{"type", "normalMap"}, {"source", "assets/art/hero-src.png"}}).find("height") != std::string::npos);
    CHECK(first({{"type", "normalize"}, {"flatten", "yes"}}).find("/adjustments/0/flatten") != std::string::npos);
    CHECK(first({{"type", "normalFlip"}, {"channel", "y"}}).empty());
}

TEST_CASE("normal maps: smooth, scale and normalize keep every pixel a unit vector; flip is its own inverse") {
    const Image sprite = make_sprite();
    Image map = make_normal_map(sprite, "sprite", 6, false);

    Image flipped = map;
    normal_map_flip(flipped, false, true);
    CHECK(flipped.rgba != map.rgba);
    // a flat pixel (128) mirrors to 127: the byte of the mirrored component
    CHECK(get(flipped, 0, 0).g == 255 - get(map, 0, 0).g);
    CHECK(get(flipped, 5, 5).r == get(map, 5, 5).r);
    normal_map_flip(flipped, false, true);
    CHECK(flipped.rgba == map.rgba);
    Image both = map;
    normal_map_flip(both, true, true);
    normal_map_flip(both, true, true);
    CHECK(both.rgba == map.rgba);

    Image smooth = map;
    normal_map_smooth(smooth, 1.5, false);
    CHECK(smooth.rgba != map.rgba);
    double worst = 0, rough = 0, roughSmooth = 0;
    for (int y = 0; y < smooth.height; ++y)
        for (int x = 0; x < smooth.width; ++x) {
            worst = std::max(worst, std::abs(length_of(get(smooth, x, y)) - 1.0));
            if (x > 0) {
                rough += std::abs(int(get(map, x, y).r) - int(get(map, x - 1, y).r));
                roughSmooth += std::abs(int(get(smooth, x, y).r) - int(get(smooth, x - 1, y).r));
            }
        }
    CHECK(worst < 0.02);               // the bytes quantize, nothing else
    CHECK(roughSmooth < rough * 0.8);  // it did blur
    CHECK(get(smooth, 0, 0) == Rgba{128, 128, 255, 255});
    Image none = map;
    normal_map_smooth(none, 0, false);
    CHECK(none.rgba == map.rgba);

    // scale: 0 flattens, 1 keeps (to a byte), 2 steepens, and the length stays 1
    Image flat = map;
    normal_map_scale(flat, 0);
    for (std::size_t i = 0; i < flat.rgba.size(); i += 4)
        CHECK(Rgba{flat.rgba[i], flat.rgba[i + 1], flat.rgba[i + 2], flat.rgba[i + 3]} == Rgba{128, 128, 255, 255});
    Image same = map, steeper = map;
    normal_map_scale(same, 1);
    normal_map_scale(steeper, 2);
    int far = 0;
    double slope = 0, slopeSteep = 0;
    for (std::size_t i = 0; i < map.rgba.size(); i += 4) {
        far += std::abs(int(same.rgba[i]) - int(map.rgba[i])) > 1 ||
               std::abs(int(same.rgba[i + 2]) - int(map.rgba[i + 2])) > 1;
        slope += std::abs(int(map.rgba[i]) - 128);
        slopeSteep += std::abs(int(steeper.rgba[i]) - 128);
        CHECK(std::abs(length_of({steeper.rgba[i], steeper.rgba[i + 1], steeper.rgba[i + 2], 255}) - 1.0) < 0.02);
    }
    CHECK(far == 0);
    CHECK(slopeSteep > slope);

    // normalize: a drifted pixel becomes unit length, a transparent pixel flat and opaque (flatten), a half-transparent one half flat
    Image drift = make_image(3, 1, {255, 255, 255, 255});
    drift.rgba[4] = 0;
    drift.rgba[5] = 0;
    drift.rgba[6] = 0;
    drift.rgba[7] = 0;
    drift.rgba[8] = 255;
    drift.rgba[9] = 128;
    drift.rgba[10] = 255;
    drift.rgba[11] = 128;
    Image kept = drift;
    normal_map_normalize(kept, false);
    CHECK(std::abs(length_of(get(kept, 0, 0)) - 1.0) < 0.02);
    CHECK(get(kept, 1, 0).a == 0);
    Image flattened = drift;
    normal_map_normalize(flattened, true);
    CHECK(get(flattened, 1, 0) == Rgba{128, 128, 255, 255});
    CHECK(get(flattened, 2, 0).a == 255);
    CHECK(get(flattened, 2, 0).r > 128);
    CHECK(get(flattened, 2, 0).r < 255);
    for (int x = 0; x < 3; ++x) CHECK(std::abs(length_of(get(flattened, x, 0)) - 1.0) < 0.02);
}

TEST_CASE("normal maps: the operations on a layer give the same bytes as the functions, and a hidden transparent edge "
          "stays valid") {
    AssetsProject p;
    const Image map = make_normal_map(make_sprite(), "sprite", 5, false);
    write_png(p.file("assets/art/n.png"), map);
    auto drawn = [&](Json op) {
        return draw_doc(normal_doc(24, 20, "assets/art/n.png", Json::array({std::move(op)})), p.dir);
    };

    Image flip = map;
    normal_map_flip(flip, false, true);
    CHECK(drawn({{"type", "normalFlip"}}).rgba == flip.rgba);
    Image flipX = map;
    normal_map_flip(flipX, true, false);
    CHECK(drawn({{"type", "normalFlip"}, {"channel", "x"}}).rgba == flipX.rgba);
    Image smooth = map;
    normal_map_smooth(smooth, 2, false);
    CHECK(drawn({{"type", "normalSmooth"}, {"radius", 2}}).rgba == smooth.rgba);
    Image scaled = map;
    normal_map_scale(scaled, 3);
    CHECK(drawn({{"type", "normalStrength"}, {"amount", 3}}).rgba == scaled.rgba);
    Image norm = map;
    normal_map_normalize(norm, true);
    CHECK(drawn({{"type", "normalize"}}).rgba == norm.rgba);

    // a transparent sprite through an adjustment LAYER over a hidden source: the generated map is opaque, not the sprite's silhouette
    const Image sprite = make_sprite();
    write_png(p.file("assets/art/s.png"), sprite);
    const Json doc = {
        {"format", kImageDocFormat},
        {"width", 24},
        {"height", 20},
        {"layers", Json::array({{{"kind", "pixels"}, {"name", "s"}, {"source", "assets/art/s.png"}},
                                {{"kind", "adjustment"}, {"adjustments", Json::array({{{"type", "normalMap"}}})}}})}};
    CHECK(draw_doc(doc, p.dir).rgba == normal_map_from_sprite(sprite, 1.0).rgba);
}

TEST_CASE("normal maps: the paint colour of a direction, and image.paint with `normal`") {
    CHECK(normal_direction_color(0, 0).r == doctest::Approx(128.0 / 255.0).epsilon(0.001));
    const Color right = normal_direction_color(0, 45), up = normal_direction_color(90, 45),
                left = normal_direction_color(180, 45), down = normal_direction_color(270, 45),
                flat = normal_direction_color(0, 0);
    auto byte = [](float v) { return int(std::lround(v * 255.0f)); };
    CHECK(byte(flat.r) == 128);
    CHECK(byte(flat.g) == 128);
    CHECK(byte(flat.b) == 255);
    CHECK(byte(right.r) == 218);
    CHECK(byte(right.g) == 128);
    CHECK(byte(right.b) == 218);
    CHECK(byte(up.g) == 218);
    CHECK(byte(left.r) == 37);
    CHECK(byte(down.g) == 37);
    CHECK(normal_direction_color(0, 200).b < 0.52f);  // the tilt is clamped to 89 degrees

    AssetsProject p;
    make_hero(p, make_sprite());
    p.ok("image.normal.generate", {{"path", kDoc}, {"layer", "hero"}, {"strength", 0}});
    const Json r = p.ok("image.paint",
                        {{"path", kDoc},
                         {"layer", "normal"},
                         {"strokes", Json::array({{{"points", Json::array({Json::array({8, 8}), Json::array({12, 8})})},
                                                   {"size", 3},
                                                   {"normal", {{"azimuth", 0}, {"tilt", 45}}}}})}});
    CHECK(r["stamps"].get<int>() > 0);  // the layer is hidden, so the picture of the document does not change
    p.ok("image.export", {{"path", kDoc}, {"layer", "normal"}, {"out", "assets/art/p-n.png"}});
    const Image painted = read_png(p.file("assets/art/p-n.png"));
    CHECK(get(painted, 10, 8) == Rgba{218, 128, 218, 255});
    CHECK(get(painted, 1, 1) == Rgba{128, 128, 255, 255});

    CommandResult both =
        p.call("image.paint", {{"path", kDoc},
                               {"layer", "normal"},
                               {"strokes", Json::array({{{"points", Json::array({Json::array({1, 1})})},
                                                         {"color", "#ff0000"},
                                                         {"normal", {{"azimuth", 0}}}}})}});
    REQUIRE_FALSE(both.ok);
    CHECK(error_of(both).find("/strokes/0/normal") != std::string::npos);
    CommandResult steep = p.call(
        "image.paint",
        {{"path", kDoc},
         {"layer", "normal"},
         {"strokes", Json::array({{{"points", Json::array({Json::array({1, 1})})}, {"normal", {{"tilt", 120}}}}})}});
    REQUIRE_FALSE(steep.ok);
    CHECK(error_of(steep).find("/strokes/0/normal/tilt") != std::string::npos);
    CommandResult typo = p.call(
        "image.paint",
        {{"path", kDoc},
         {"layer", "normal"},
         {"strokes", Json::array({{{"points", Json::array({Json::array({1, 1})})}, {"normal", {{"azimut", 10}}}}})}});
    REQUIRE_FALSE(typo.ok);
    CHECK(error_of(typo).find("azimuth") != std::string::npos);
}

TEST_CASE("normal maps: the preview light is the formula of the shade operation, and a lamp lights the side it is on") {
    AssetsProject p;
    // a map that leans differently across the picture
    const Image map = make_normal_map(make_height(), "height", 12, false);
    write_png(p.file("assets/art/n.png"), map);
    Image base = make_image(16, 16, {200, 160, 120, 255});
    for (double dir : {0.0, 135.0, 250.0}) {
        CAPTURE(dir);
        const Json doc = {{"format", kImageDocFormat},
                          {"width", 16},
                          {"height", 16},
                          {"layers", Json::array({{{"kind", "fill"},
                                                   {"color", "#c8a078"},
                                                   {"effects", Json::array({{{"type", "shade"},
                                                                             {"normalMap", "assets/art/n.png"},
                                                                             {"lightDirection", dir},
                                                                             {"elevation", 40},
                                                                             {"intensity", 1.5}}})}}})}};
        const Image viaShade = draw_doc(doc, p.dir);
        NormalLight light;
        light.point = false;
        light.azimuth = dir;
        light.elevation = 40;
        light.intensity = 1.5;
        const Image viaPreview = light_with_normal_map(base, map, light);
        REQUIRE(viaPreview.rgba.size() == viaShade.rgba.size());
        int worst = 0;
        for (std::size_t i = 0; i < viaShade.rgba.size(); ++i)
            worst = std::max(worst, std::abs(int(viaShade.rgba[i]) - int(viaPreview.rgba[i])));
        CHECK(worst <= 1);
    }
    // the picture's transparent pixels stay transparent and a flat map keeps the colour
    Image holes = base;
    holes.rgba[3] = 0;
    NormalLight lamp;
    lamp.height = 20;
    lamp.x = 8;
    lamp.y = 8;
    CHECK(light_with_normal_map(holes, map, lamp).rgba[3] == 0);
    CHECK(get(light_with_normal_map(base, make_image(16, 16, {128, 128, 255, 255}), lamp), 4, 4) ==
          Rgba{200, 160, 120, 255});
    // a surface leaning to +x is brighter with the lamp on its right than on its left
    const Image lean = make_image(16, 16, {255, 128, 255, 255});
    NormalLight onRight = lamp, onLeft = lamp;
    onRight.x = 40;
    onLeft.x = -30;
    CHECK(get(light_with_normal_map(base, lean, onRight), 8, 8).r >
          get(light_with_normal_map(base, lean, onLeft), 8, 8).r);
    // a lamp above a row is brighter for a surface leaning up the picture (+y of the map) than down; flipGreen swaps it
    const Image leanUp = make_image(16, 16, {128, 255, 255, 255});
    NormalLight above = lamp;
    above.x = 8;
    above.y = -30;
    NormalLight dx = above;
    dx.flipGreen = true;
    CHECK(get(light_with_normal_map(base, leanUp, above), 8, 8).r >
          get(light_with_normal_map(base, leanUp, dx), 8, 8).r);
    // the preview can be smaller than the picture
    const Image big = make_image(64, 32, {255, 255, 255, 255});
    const Image small = light_with_normal_map(big, Image{}, lamp, 16);
    CHECK(small.width == 16);
    CHECK(small.height == 8);
    CHECK(light_with_normal_map(Image{}, map, lamp).empty());
}
