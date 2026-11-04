// The measurable house style (assets.json "style"), the picture measurements, assets.check_art and the style warnings of
// project.validate (fa/tooling/art_check.h, fa/tooling/style_guide.h). Every picture is generated here.
#include <doctest.h>

#include <filesystem>

#include "asset_test_helpers.h"
#include "fa/core/json.h"
#include "fa/tooling/art_check.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/style_guide.h"
#include "fa/tooling/validate.h"

using namespace fa;
using namespace fa::testing;
namespace stdfs = std::filesystem;

namespace {

const Rgba kRed{255, 0, 0, 255}, kBlack{0, 0, 0, 255}, kWhite{255, 255, 255, 255}, kClear{0, 0, 0, 0}, kCream{250, 235, 200, 255};

// A 20x20 picture with a 12x12 block (red unless given), optionally ringed by a 1 px line.
Image block(Rgba fill, std::optional<Rgba> ring = std::nullopt) {
    Image img = make_image(20, 20, kClear);
    if (ring) {
        fill_rect(img, 4, 4, 12, 12, *ring);
        fill_rect(img, 5, 5, 10, 10, fill);
    } else {
        fill_rect(img, 4, 4, 12, 12, fill);
    }
    return img;
}

bool mentions(const std::vector<StyleProblem>& problems, const std::string& needle) {
    for (const StyleProblem& p : problems)
        if (p.message.find(needle) != std::string::npos || p.hint.find(needle) != std::string::npos) return true;
    return false;
}

const ArtRule* find_rule(const std::vector<ArtRule>& rules, const std::string& name) {
    for (const ArtRule& r : rules)
        if (r.rule == name) return &r;
    return nullptr;
}

const Json* find_json_rule(const Json& rules, const std::string& name, int nth = 0) {
    for (const Json& r : rules)
        if (r["rule"] == name && nth-- == 0) return &r;
    return nullptr;
}

StyleGuide guide_of(const std::string& json) {
    StyleParse p = parse_style(Json::parse(json));
    const std::string first = p.problems.empty() ? std::string() : p.problems[0].pointer + ": " + p.problems[0].message;
    REQUIRE_MESSAGE(p.problems.empty(), first);
    return p.guide;
}

}  // namespace

// ---- the style section -------------------------------------------------------------------------------------------

TEST_CASE("style: every rule parses into the shared struct") {
    const StyleParse p = parse_style(Json::parse(R"({
        "prompt": "flat colours", "palette": ["#000000", "#ffffff"],
        "outline": {"color": "#101010", "width": 2},
        "lightDirection": "upper-left", "texelsPerUnit": 16, "pixelArt": true,
        "value": {"min": 0.1, "max": 0.9}, "saturation": {"max": 0.8},
        "audio": {"loudnessLufs": {"music": -18, "sfx": -14}, "toleranceLu": 2},
        "ignore": ["assets/ui/", "./assets/logo.png"]})"));
    CHECK(p.problems.empty());
    const StyleGuide& g = p.guide;
    CHECK(g.prompt == "flat colours");
    REQUIRE(g.palette);
    CHECK(g.palette->size() == 2);
    REQUIRE(g.outline);
    CHECK(g.outline->width == 2.0);
    CHECK(g.outline->colorText == "#101010");
    REQUIRE(g.lightDirection);
    CHECK(*g.lightDirection == doctest::Approx(135.0));
    CHECK(g.lightDirectionName == "upper-left");
    CHECK(*g.texelsPerUnit == 16.0);
    CHECK(*g.pixelArt);
    CHECK(*g.value->min == 0.1);
    CHECK_FALSE(g.saturation->min.has_value());
    CHECK(*g.saturation->max == 0.8);
    REQUIRE(g.audio);
    CHECK(g.audio->loudnessLufs.at("music") == -18.0);
    CHECK(g.audio->toleranceLu == 2.0);
    CHECK(g.has_art_rules());
    CHECK(g.ignores("assets/ui/button.png"));
    CHECK(g.ignores("assets/logo.png"));
    CHECK_FALSE(g.ignores("assets/hero.png"));
}

TEST_CASE("style: degrees and names both set the light direction; a project with only a prompt has no art rules") {
    CHECK(*guide_of(R"({"lightDirection": 45})").lightDirection == doctest::Approx(45.0));
    CHECK(*guide_of(R"({"lightDirection": -90})").lightDirection == doctest::Approx(270.0));
    CHECK(*guide_of(R"({"lightDirection": "top"})").lightDirection == doctest::Approx(90.0));
    CHECK(*guide_of(R"({"lightDirection": "Top-Left"})").lightDirection == doctest::Approx(135.0));
    CHECK_FALSE(guide_of(R"({"prompt": "x", "references": ["a.png"]})").has_art_rules());
    CHECK_FALSE(guide_of(R"({"audio": {"loudnessLufs": {"music": -16}}})").has_art_rules());
    CHECK_FALSE(guide_of("{}").has_art_rules());
}

TEST_CASE("style: mistakes name the pointer, the fix and the closest key") {
    StyleParse p = parse_style(Json::parse(R"({"outlin": {"color": "#000000"}})"));
    REQUIRE(p.problems.size() == 1);
    CHECK(p.problems[0].pointer == "/style/outlin");
    CHECK(mentions(p.problems, "outline"));  // did you mean
    CHECK_FALSE(p.guide.outline.has_value());

    p = parse_style(Json::parse(R"({"outline": {"color": "#000000", "width": "thick"}})"));
    REQUIRE_FALSE(p.problems.empty());
    CHECK(p.problems[0].pointer == "/style/outline/width");
    CHECK_FALSE(p.problems[0].hint.empty());

    p = parse_style(Json::parse(R"({"value": {"min": 0.9, "max": 0.1}})"));
    REQUIRE_FALSE(p.problems.empty());
    CHECK(p.problems[0].pointer.rfind("/style/value", 0) == 0);

    p = parse_style(Json::parse(R"({"saturation": {"max": 3}})"));
    REQUIRE_FALSE(p.problems.empty());
    CHECK(p.problems[0].pointer == "/style/saturation/max");

    p = parse_style(Json::parse(R"({"lightDirection": "sideways"})"));
    REQUIRE_FALSE(p.problems.empty());
    CHECK(p.problems[0].pointer == "/style/lightDirection");
    CHECK(mentions(p.problems, "upper-left"));  // the accepted names are listed

    p = parse_style(Json::parse(R"({"pixelArt": "yes", "texelsPerUnit": -4})"));
    CHECK(p.problems.size() == 2);

    p = parse_style(Json::parse(R"([1, 2])"));
    REQUIRE(p.problems.size() == 1);
    CHECK(p.problems[0].pointer == "/style");
}

// ---- measurements ------------------------------------------------------------------------------------------------

TEST_CASE("measure_art: colours, silhouette ring, partial alpha and a JSON round trip") {
    const ArtMeasure m = measure_art(block(kRed));
    CHECK(m.width == 20);
    CHECK(m.visible == 144);
    CHECK(m.distinct == 1);
    CHECK(m.exact);
    REQUIRE(m.colours.size() == 1);
    CHECK(m.colours[0].r == 255);
    CHECK(m.colours[0].count == 144);
    CHECK(m.partialShare == 0.0);
    CHECK(m.ringPixels == 44);  // the border of a 12x12 block
    CHECK(m.valueHigh == doctest::Approx(1.0));
    CHECK(m.saturationMean == doctest::Approx(1.0));

    const ArtMeasure ringed = measure_art(block(kRed, kBlack));
    REQUIRE_FALSE(ringed.ringColours.empty());
    CHECK(ringed.ringColours[0].r == 0);
    CHECK(ringed.ringColours[0].g == 0);
    CHECK(ringed.ringWidth == doctest::Approx(1.0));
    CHECK(ringed.distinct == 2);

    Image soft = block(kRed);
    fill_rect(soft, 16, 4, 1, 12, {255, 0, 0, 128});
    CHECK(measure_art(soft).partialShare > 0.05);

    const auto again = ArtMeasure::from_json(ringed.to_json());
    REQUIRE(again);
    CHECK(again->to_json() == ringed.to_json());
}

TEST_CASE("measure_art: the shading lean and the size of the pixel blocks") {
    Image ramp = make_image(32, 32, kWhite);  // brighter at the top
    for (int y = 0; y < 32; ++y) {
        const std::uint8_t v = std::uint8_t(250 - y * 6);
        fill_rect(ramp, 0, y, 32, 1, {v, v, v, 255});
    }
    const ArtMeasure up = measure_art(ramp);
    CHECK(up.lightDegrees == doctest::Approx(90.0).epsilon(0.1));
    CHECK(up.lightStrength > 0.3);

    Image left = make_image(32, 32, kWhite);  // brighter at the left
    for (int x = 0; x < 32; ++x) {
        const std::uint8_t v = std::uint8_t(250 - x * 6);
        fill_rect(left, x, 0, 1, 32, {v, v, v, 255});
    }
    const ArtMeasure l = measure_art(left);
    CHECK(std::fabs(l.lightDegrees - 180.0) < 15.0);

    Image small = make_image(8, 8, kBlack);  // 2 px blocks of an 8x8 pattern
    for (int y = 0; y < 8; ++y)
        for (int x = 0; x < 8; ++x) {
            const std::uint8_t v = std::uint8_t(((x * 7 + y * 13) % 5) * 50);
            fill_rect(small, x, y, 1, 1, {v, std::uint8_t(255 - v), std::uint8_t(v / 2), 255});
        }
    Image big = make_image(16, 16, kBlack);
    for (int y = 0; y < 16; ++y)
        for (int x = 0; x < 16; ++x) {
            const Rgba c = get(small, x / 2, y / 2);
            fill_rect(big, x, y, 1, 1, c);
        }
    CHECK(measure_art(big).blockSize == 2);
    CHECK(measure_art(small).blockSize == 1);
}

// ---- the rules ---------------------------------------------------------------------------------------------------

TEST_CASE("style rules: only the rules that are set are judged, and a broken one says what to do") {
    const ArtMeasure red = measure_art(block(kRed));
    const ArtMeasure ringed = measure_art(block(kRed, kBlack));

    CHECK(evaluate_style_rules(red, StyleGuide{}, {}).empty());  // no rules set: nothing is judged

    const StyleGuide outline = guide_of(R"({"outline": {"color": "#000000", "width": 1}})");
    auto rules = evaluate_style_rules(red, outline, {});
    const ArtRule* colour = find_rule(rules, "outline.color");
    REQUIRE(colour);
    CHECK(colour->verdict == Verdict::Fail);
    CHECK(colour->message.find("#000000") != std::string::npos);
    CHECK(colour->hint.find("style.ignore") != std::string::npos);
    CHECK(find_rule(rules, "value.min") == nullptr);

    rules = evaluate_style_rules(ringed, outline, {});
    CHECK(find_rule(rules, "outline.color")->verdict == Verdict::Ok);
    REQUIRE(find_rule(rules, "outline.width"));
    CHECK(find_rule(rules, "outline.width")->verdict == Verdict::Ok);

    const StyleGuide thick = guide_of(R"({"outline": {"color": "#000000", "width": 4}})");
    CHECK(find_rule(evaluate_style_rules(ringed, thick, {}), "outline.width")->verdict == Verdict::Fail);

    const StyleGuide dim = guide_of(R"({"value": {"max": 0.5}, "saturation": {"max": 0.5}})");
    rules = evaluate_style_rules(red, dim, {});
    CHECK(find_rule(rules, "value.max")->verdict == Verdict::Fail);
    CHECK(find_rule(rules, "saturation.max")->verdict == Verdict::Fail);

    const StyleGuide palette = guide_of(R"({"palette": ["#00ff00", "#0000ff"]})");
    rules = evaluate_style_rules(red, palette, {});
    const ArtRule* off = find_rule(rules, "palette.offShare");
    REQUIRE(off);
    CHECK(off->verdict == Verdict::Fail);
    CHECK(off->value == doctest::Approx(1.0));
    CHECK(off->message.find("#ff0000") != std::string::npos);  // the colour that is off
    const StyleGuide fits = guide_of(R"({"palette": ["#ff0000", "#0000ff"]})");
    CHECK(find_rule(evaluate_style_rules(red, fits, {}), "palette.offShare")->verdict == Verdict::Ok);
}

TEST_CASE("style rules: pixel art is strict about soft edges and the palette") {
    Image soft = block(kRed);
    fill_rect(soft, 16, 4, 1, 12, {255, 0, 0, 128});
    const StyleGuide pixel = guide_of(R"({"pixelArt": true, "palette": ["#ff0000", "#000000"]})");
    const auto rules = evaluate_style_rules(measure_art(soft), pixel, {});
    CHECK(find_rule(rules, "pixelArt.edges")->verdict == Verdict::Fail);
    CHECK(find_rule(rules, "pixelArt.colours")->verdict == Verdict::Ok);
    CHECK(find_rule(rules, "palette.offShare")->verdict == Verdict::Ok);

    // a colour 5 levels off the palette is off it in pixel art, not in smooth art
    const ArtMeasure near = measure_art(block({250, 5, 0, 255}));
    CHECK(find_rule(evaluate_style_rules(near, pixel, {}), "palette.offShare")->verdict == Verdict::Fail);
    const StyleGuide smooth = guide_of(R"({"palette": ["#ff0000", "#000000"]})");
    CHECK(find_rule(evaluate_style_rules(near, smooth, {}), "palette.offShare")->verdict == Verdict::Ok);
}

TEST_CASE("style rules: texelsPerUnit compares with how the scenes draw the texture") {
    const ArtMeasure m = measure_art(block(kRed));
    TextureUse use;
    use.scene = "scenes/main.scene.json";
    use.texture = "assets/a.png";
    use.framePx[0] = use.framePx[1] = 16;
    use.world[0] = use.world[1] = 1;  // 16 texels per unit
    const std::vector<const TextureUse*> uses = {&use};
    CHECK(find_rule(evaluate_style_rules(m, guide_of(R"({"texelsPerUnit": 16})"), uses), "texelsPerUnit")->verdict == Verdict::Ok);
    CHECK(find_rule(evaluate_style_rules(m, guide_of(R"({"texelsPerUnit": 8})"), uses), "texelsPerUnit")->verdict == Verdict::Fail);
    CHECK(find_rule(evaluate_style_rules(m, guide_of(R"({"texelsPerUnit": 16})"), {}), "texelsPerUnit") == nullptr);  // not drawn: not judged
}

// ---- assets.check_art --------------------------------------------------------------------------------------------

TEST_CASE("assets.check_art: a picture with rules, backgrounds, sizes and an annotated image") {
    AssetsProject p;
    write_png(p.file("assets/hero.png"), block(kRed, kBlack));
    const Json r = p.ok("assets.check_art", Json{{"path", "assets/hero.png"}, {"backgrounds", Json::array({"#202020", "#f0f0f0"})}, {"onScreenPx", 8}});
    REQUIRE(r["assets"].size() == 1);
    const Json& a = r["assets"][0];
    CHECK(a["backgrounds"]["source"] == "explicit");
    CHECK(a["backgrounds"]["used"].size() == 2);
    CHECK(a["onScreen"]["source"] == "explicit");
    const Json* dark = find_json_rule(a["rules"], "contrast", 0);
    const Json* light = find_json_rule(a["rules"], "contrast", 1);
    REQUIRE(dark);
    REQUIRE(light);
    CHECK((*dark)["threshold"] == 3.0);
    const Json* size = find_json_rule(a["rules"], "readability.size");
    REQUIRE(size);
    CHECK((*size)["value"] == 8.0);
    CHECK((*size)["verdict"] == "warn");  // 8 px: readable only barely
    CHECK_FALSE((*size)["hint"].get<std::string>().empty());
    CHECK(find_json_rule(a["rules"], "readability.silhouette"));
    CHECK(a["palette"]["distinctColours"] == 2);
    CHECK(a["tiles"].size() == 5);  // the picture, its value, two backgrounds, one size
    REQUIRE(r.contains("$image"));
    CHECK(r["$image"]["temporary"] == true);
    const Image pic = read_png(r["$image"]["path"].get<std::string>());
    CHECK(pic.width == r["picture"]["width"].get<int>());
    CHECK(r["style"]["applied"] == false);
    // the black outline is what separates it from the dark background: it vanishes there, and stands out on the light one
    CHECK((*dark)["verdict"] == "fail");
    CHECK((*light)["verdict"] == "ok");
    CHECK(r["verdict"] == "fail");
}

TEST_CASE("assets.check_art: without backgrounds or scenes it uses a light and a dark default and says so") {
    AssetsProject p;
    write_png(p.file("assets/hero.png"), block(kCream));
    const Json r = p.ok("assets.check_art", Json{{"path", "assets/hero.png"}});
    const Json& a = r["assets"][0];
    CHECK(a["backgrounds"]["source"] == "default");
    CHECK(a["backgrounds"]["used"].size() == 2);
    CHECK(a["onScreen"]["source"] == "none");
    CHECK(has_text(a["notes"], "No scene draws this picture"));
    // cream on the light default does not stand out; on the dark default it does
    const Json* onLight = find_json_rule(a["rules"], "contrast", 0);
    const Json* onDark = find_json_rule(a["rules"], "contrast", 1);
    REQUIRE(onLight);
    REQUIRE(onDark);
    CHECK((*onLight)["verdict"] == "fail");
    CHECK((*onDark)["verdict"] == "ok");
    CHECK((*onLight)["hint"].get<std::string>().find("style.outline") != std::string::npos);
}

TEST_CASE("assets.check_art: backgrounds and sizes come from the scenes that draw the picture") {
    AssetsProject p;
    write_png(p.file("assets/hero.png"), block(kCream));
    write_all(p.file("scenes/main.scene.json"),
              Json::object({{"format", "factoria.scene/1"},
                            {"entities", Json::array({Json::object({{"id", "camera"}, {"components", Json::object({{"Camera", Json::object({{"primary", true}, {"orthoSize", 360}, {"clearColor", "#f5f5f0"}})}})}}),
                                                      Json::object({{"id", "hero"}, {"components", Json::object({{"Sprite", Json::object({{"texture", "assets/hero.png"}, {"size", Json::array({40, 40})}})}})}})})}})
                  .dump());
    const Json r = p.ok("assets.check_art", Json{{"path", "assets/hero.png"}});
    const Json& a = r["assets"][0];
    CHECK(a["backgrounds"]["source"] == "scenes");
    CHECK(a["backgrounds"]["used"][0]["color"] == "#f5f5f0");
    CHECK(a["scenes"][0] == "scenes/main.scene.json");
    CHECK(a["onScreen"]["source"] == "scenes");
    REQUIRE(a["onScreen"]["sizes"].size() == 2);
    // 40 world units of a 720-high view (1280x720 design), shown "fit" on 844x390: x0.5417; on 1920x1080: x1.5
    CHECK(a["onScreen"]["sizes"][0]["px"].get<double>() == doctest::Approx(40.0 * 390.0 / 720.0).epsilon(0.05));
    CHECK(a["onScreen"]["sizes"][1]["px"].get<double>() == doctest::Approx(40.0 * 1080.0 / 720.0).epsilon(0.05));
    CHECK(a["onScreen"]["sizes"][0]["scene"] == "scenes/main.scene.json");
    const Json* contrast = find_json_rule(a["rules"], "contrast");
    REQUIRE(contrast);
    CHECK((*contrast)["verdict"] == "fail");  // cream on an off-white clear colour
}

TEST_CASE("assets.check_art: halos and dark fringes on the alpha edge") {
    AssetsProject p;
    Image img = make_image(24, 24, kClear);
    fill_rect(img, 5, 5, 14, 14, {250, 240, 150, 255});
    fill_rect(img, 4, 4, 16, 1, {0, 0, 0, 128});  // a dark half-transparent line around a light shape
    fill_rect(img, 4, 19, 16, 1, {0, 0, 0, 128});
    fill_rect(img, 4, 4, 1, 16, {0, 0, 0, 128});
    fill_rect(img, 19, 4, 1, 16, {0, 0, 0, 128});
    write_png(p.file("assets/halo.png"), img);
    write_png(p.file("assets/clean.png"), block(kRed, kBlack));
    const Json r = p.ok("assets.check_art", Json{{"paths", Json::array({"assets/halo.png", "assets/clean.png"})}, {"backgrounds", Json::array({"#808080"})}, {"onScreenPx", 24}});
    const Json* fringe = find_json_rule(r["assets"][0]["rules"], "fringe.partial");
    REQUIRE(fringe);
    CHECK((*fringe)["verdict"] == "fail");
    CHECK((*fringe)["message"].get<std::string>().find("dark fringe") != std::string::npos);
    CHECK(find_json_rule(r["assets"][1]["rules"], "fringe.partial") == nullptr);  // no partial alpha at all
}

TEST_CASE("assets.check_art: several paths are also judged as a set") {
    AssetsProject p;
    write_png(p.file("assets/a.png"), block(kRed, kBlack));
    write_png(p.file("assets/b.png"), block({40, 120, 220, 255}, kWhite));
    const Json r = p.ok("assets.check_art", Json{{"paths", Json::array({"assets/a.png", "assets/b.png"})}, {"backgrounds", Json::array({"#808080"})}, {"onScreenPx", 20}});
    REQUIRE(r.contains("set"));
    const Json* colour = find_json_rule(r["set"]["rules"], "set.outlineColour");
    REQUIRE(colour);
    CHECK((*colour)["verdict"] == "warn");  // black against white
    CHECK(find_json_rule(r["set"]["rules"], "set.outlineWidth"));
    const Json* spread = find_json_rule(r["set"]["rules"], "set.paletteSpread");
    REQUIRE(spread);
    CHECK((*spread)["value"].get<double>() > 0.9);  // no colour in common
    CHECK(r["assets"].size() == 2);
    CHECK(r["assets"][1]["tiles"][0]["tile"] == 5);  // the second row's numbers follow the first row's four tiles
}

TEST_CASE("assets.check_art: the style rules of assets.json are judged, and style:false skips them") {
    AssetsProject p;
    write_png(p.file("assets/plain.png"), block(kRed));
    write_all(p.file("assets.json"), Json::object({{"format", "factoria.assets/1"}, {"style", Json::object({{"outline", Json::object({{"color", "#000000"}, {"width", 1}})}})}}).dump());
    Json r = p.ok("assets.check_art", Json{{"path", "assets/plain.png"}, {"backgrounds", Json::array({"#808080"})}, {"onScreenPx", 20}});
    const Json* outline = find_json_rule(r["assets"][0]["rules"], "outline.color");
    REQUIRE(outline);
    CHECK((*outline)["verdict"] == "fail");
    CHECK(r["style"]["applied"] == true);
    CHECK(r["verdict"] == "fail");
    r = p.ok("assets.check_art", Json{{"path", "assets/plain.png"}, {"backgrounds", Json::array({"#808080"})}, {"onScreenPx", 20}, {"style", false}});
    CHECK(find_json_rule(r["assets"][0]["rules"], "outline.color") == nullptr);
    CHECK(r["style"]["applied"] == false);
}

TEST_CASE("assets.check_art: the same call gives the same numbers, and the second measurement comes from the cache") {
    AssetsProject p;
    write_png(p.file("assets/hero.png"), block(kRed, kBlack));
    const Json args = Json{{"path", "assets/hero.png"}, {"backgrounds", Json::array({"#808080"})}, {"onScreenPx", 12}};
    const Json first = p.ok("assets.check_art", args);
    const Json second = p.ok("assets.check_art", args);
    CHECK(first["assets"][0]["measure"]["fromCache"] == false);
    CHECK(second["assets"][0]["measure"]["fromCache"] == true);
    CHECK(first["assets"][0]["rules"] == second["assets"][0]["rules"]);
    CHECK(first["assets"][0]["palette"] == second["assets"][0]["palette"]);
    CHECK(stdfs::exists(p.file(".factoria/art-cache")));
    // the cache follows the file: new bytes are measured again
    write_png(p.file("assets/hero.png"), block(kRed));
    CHECK(p.ok("assets.check_art", args)["assets"][0]["measure"]["fromCache"] == false);
}

TEST_CASE("assets.check_art: wrong arguments say what to pass") {
    AssetsProject p;
    write_png(p.file("assets/hero.png"), block(kRed));
    auto message = [](const CommandResult& r) { return r.error["message"].get<std::string>() + " " + r.error.value("hint", std::string()); };

    CommandResult r = p.call("assets.check_art", Json::object());
    REQUIRE_FALSE(r.ok);
    CHECK(message(r).find("path") != std::string::npos);
    r = p.call("assets.check_art", Json{{"path", "assets/hero.png"}, {"paths", Json::array({"assets/hero.png"})}});
    REQUIRE_FALSE(r.ok);
    r = p.call("assets.check_art", Json{{"path", "assets/missing.png"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "not_found");
    r = p.call("assets.check_art", Json{{"path", "assets/hero.png"}, {"onScreenPx", 0}});
    REQUIRE_FALSE(r.ok);
    CHECK(message(r).find("/onScreenPx") != std::string::npos);
    r = p.call("assets.check_art", Json{{"path", "assets/hero.png"}, {"backgrounds", Json::array({"assets/nothing.png"})}});
    REQUIRE_FALSE(r.ok);
    CHECK(message(r).find("/backgrounds/0") != std::string::npos);
    r = p.call("assets.check_art", Json{{"path", "assets/hero.png"}, {"onScreenpx", 20}});
    REQUIRE_FALSE(r.ok);
    CHECK(message(r).find("onScreenPx") != std::string::npos);  // did you mean
}

TEST_CASE("assets.check_art: an image used as a background stands for its dark, middle and light parts") {
    AssetsProject p;
    write_png(p.file("assets/hero.png"), block(kRed));
    Image sky = make_image(16, 16, {20, 20, 60, 255});
    fill_rect(sky, 0, 8, 16, 8, {240, 240, 255, 255});
    write_png(p.file("assets/sky.png"), sky);
    const Json r = p.ok("assets.check_art", Json{{"path", "assets/hero.png"}, {"backgrounds", Json::array({"assets/sky.png"})}, {"onScreenPx", 20}});
    const Json& used = r["assets"][0]["backgrounds"]["used"];
    CHECK(used.size() >= 2);
    CHECK(used[0]["label"].get<std::string>().find("assets/sky.png") != std::string::npos);
}

// ---- project.validate --------------------------------------------------------------------------------------------

namespace {

struct Game {
    TempDir tmp;
    std::string dir;
    Game() {
        dir = tmp.sub("game");
        REQUIRE(create_project(dir, "2d-empty").ok());
    }
    void style(const Json& s) {
        write_all(stdfs::path(dir) / "assets.json", Json::object({{"format", "factoria.assets/1"}, {"style", s}}).dump());
    }
    void sprite(const std::string& texture, double size = 0) {
        Json sp = Json::object({{"texture", texture}});
        if (size > 0) sp["size"] = Json::array({size, size});
        Json entities = Json::array({Json::object({{"id", "camera"}, {"components", Json::object({{"Camera", Json::object({{"primary", true}})}})}}),
                                     Json::object({{"id", "s"}, {"components", Json::object({{"Sprite", sp}})}})});
        REQUIRE(save_json_file(dir + "/scenes/main.scene.json", Json::object({{"format", "factoria.scene/1"}, {"entities", entities}})).ok());
    }
    std::vector<ValidationIssue> warnings(const std::string& file) const {
        std::vector<ValidationIssue> found;
        for (const ValidationIssue& w : validate_project(dir).warnings)
            if (w.file == file) found.push_back(w);
        return found;
    }
};

}  // namespace

TEST_CASE("validate: a texture that breaks a style rule that is set gets a warning naming the rule and the fix") {
    Game g;
    write_png(stdfs::path(g.dir) / "assets/plain.png", block(kRed));
    g.sprite("assets/plain.png");
    g.style(Json::object({{"outline", Json::object({{"color", "#000000"}, {"width", 1}})}}));
    const auto w = g.warnings("assets/plain.png");
    REQUIRE(w.size() == 1);
    CHECK(w[0].message.find("outline.color") != std::string::npos);
    CHECK_FALSE(w[0].hint.empty());
    CHECK(validate_project(g.dir).ok);  // a warning, not an error

    // the same picture with its outline passes
    write_png(stdfs::path(g.dir) / "assets/plain.png", block(kRed, kBlack));
    CHECK(g.warnings("assets/plain.png").empty());
    CHECK(stdfs::exists(stdfs::path(g.dir) / ".factoria/art-cache"));
}

TEST_CASE("validate: no style rule, no warning; and style.ignore opts a file or a folder out") {
    Game g;
    write_png(stdfs::path(g.dir) / "assets/ui/button.png", block(kRed));
    g.sprite("assets/ui/button.png");
    CHECK(g.warnings("assets/ui/button.png").empty());  // no assets.json style

    g.style(Json::object({{"prompt", "flat colours"}}));
    CHECK(g.warnings("assets/ui/button.png").empty());  // a prompt is not a rule

    g.style(Json::object({{"value", Json::object({{"max", 0.5}})}}));
    CHECK(g.warnings("assets/ui/button.png").size() == 1);

    g.style(Json::object({{"value", Json::object({{"max", 0.5}})}, {"ignore", Json::array({"assets/ui/"})}}));
    CHECK(g.warnings("assets/ui/button.png").empty());
}

TEST_CASE("validate: texelsPerUnit warns when the scenes draw a texture at another density") {
    Game g;
    write_png(stdfs::path(g.dir) / "assets/tile.png", make_image(16, 16, kRed));
    g.style(Json::object({{"texelsPerUnit", 1}}));
    g.sprite("assets/tile.png", 16);  // 16 px drawn 16 units wide: 1 texel per unit
    CHECK(g.warnings("assets/tile.png").empty());
    g.sprite("assets/tile.png", 64);  // 4 times bigger: 0.25 texel per unit
    const auto w = g.warnings("assets/tile.png");
    REQUIRE(w.size() == 1);
    CHECK(w[0].message.find("texelsPerUnit") != std::string::npos);
    CHECK(w[0].hint.find("Sprite.size") != std::string::npos);
}

TEST_CASE("validate: a mistake in the style section is an error with its pointer; an unknown bus is a warning") {
    Game g;
    g.style(Json::object({{"value", Json::object({{"min", 0.9}, {"max", 0.1}})}}));
    ValidationReport report = validate_project(g.dir);
    CHECK_FALSE(report.ok);
    bool found = false;
    for (const ValidationIssue& e : report.errors)
        if (e.file == "assets.json" && e.pointer.rfind("/style/value", 0) == 0) found = true;
    CHECK(found);

    g.style(Json::object({{"outlin", Json::object({{"color", "#000000"}})}}));
    report = validate_project(g.dir);
    CHECK_FALSE(report.ok);
    int atKey = 0;
    for (const ValidationIssue& e : report.errors)
        if (e.file == "assets.json" && e.pointer == "/style/outlin") ++atKey;
    CHECK(atKey == 1);  // the schema and the style parser do not both report it

    g.style(Json::object({{"audio", Json::object({{"loudnessLufs", Json::object({{"musik", -16}})}})}}));
    const auto w = g.warnings("assets.json");
    REQUIRE(w.size() == 1);
    CHECK(w[0].pointer == "/style/audio/loudnessLufs/musik");
    CHECK(w[0].hint.find("music") != std::string::npos);
}
