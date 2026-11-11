// image.resize (the canvas of an image document, docs/IMAGES.md "Resizing the canvas") and the scope of the style rules: style.ignore
// with rules, roles (provenance.role, style.roles) and what assets.check_art reports as skipped (docs/ASSETS.md).
#include <doctest.h>

#include <filesystem>

#include "asset_test_helpers.h"
#include "fa/tooling/image_doc.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/style_guide.h"
#include "fa/tooling/validate.h"

using namespace fa;
using namespace fa::testing;
namespace stdfs = std::filesystem;

namespace {

constexpr const char* kDoc = "assets/art/dot.image.json";

const Rgba kRed{255, 0, 0, 255}, kClear{0, 0, 0, 0}, kGreen{0, 255, 0, 255};

Json read_doc(const AssetsProject& p) { return parse_json(read_all(p.file(kDoc)), kDoc).value(); }

Image frame_of(const AssetsProject& p, int frame) {
    auto doc = load_image_document(p.dir, kDoc);
    REQUIRE_MESSAGE(doc.ok(), (doc.ok() ? "" : doc.error().message));
    ImageRenderOptions options;
    options.projectDir = p.dir;
    options.frame = frame;
    auto r = composite_image_document(*doc, options);
    REQUIRE(r.ok());
    return r->image;
}

// 4x4, three frames, an indexed layer "dot" whose red pixel is at (f, 0) in frame f, a tag, and a pixels layer "bar": a 4x1 green PNG at (0, 3).
void make_dot(const AssetsProject& p) {
    write_png(p.file("assets/art/bar.png"), make_image(4, 1, kGreen));
    p.ok("image.create", {{"path", kDoc}, {"width", 4}, {"height", 4}, {"palette", Json::array({"#000000", "#ff0000"})}});
    p.ok("image.layer.add", {{"path", kDoc}, {"layer", {{"kind", "pixels"}, {"name", "bar"}, {"source", "assets/art/bar.png"}, {"x", 0}, {"y", 3}}}});
    p.ok("image.pixel", {{"path", kDoc}, {"layer", "dot"}, {"create", true}, {"pixels", Json::array({Json::array({0, 0, 1})})}});
    p.ok("image.frame.add", {{"path", kDoc}, {"count", 2}});
    for (int f = 1; f < 3; ++f) {
        p.ok("image.frame.cel", {{"path", kDoc}, {"layer", "dot"}, {"frame", f}, {"clear", true}});
        p.ok("image.pixel", {{"path", kDoc}, {"layer", "dot"}, {"frame", f}, {"pixels", Json::array({Json::array({f, 0, 1})})}});
    }
    p.ok("image.tag.set", {{"path", kDoc}, {"name", "walk"}, {"from", 0}, {"to", 2}});
}

}  // namespace

TEST_CASE("image.resize: growing with an anchor moves every layer, frame and cel; palette, tags and the sheet stay") {
    AssetsProject p;
    make_dot(p);
    const Json before = read_doc(p);
    const Json r = p.ok("image.resize", {{"path", kDoc}, {"width", 6}, {"height", 5}, {"anchor", "bottom-right"}});
    CHECK(r["resized"]["offset"]["x"] == 2);
    CHECK(r["resized"]["offset"]["y"] == 1);
    CHECK(r["resized"]["filled"] == false);
    const Json after = read_doc(p);
    CHECK(after["width"] == 6);
    CHECK(after["height"] == 5);
    CHECK(after["palette"] == before["palette"]);
    CHECK(after["tags"] == before["tags"]);
    CHECK(after["frames"] == before["frames"]);
    for (int f = 0; f < 3; ++f) {
        const Image img = frame_of(p, f);
        REQUIRE(img.width == 6);
        REQUIRE(img.height == 5);
        CHECK(get(img, 2 + f, 1) == kRed);  // the red pixel moved by (2, 1) and still walks one pixel per frame
        CHECK(get(img, 0, 0) == kClear);    // the new area is transparent
        CHECK(get(img, 2, 4) == kGreen);    // the pixels layer bar: (0, 3) + (2, 1)
        CHECK(get(img, 1, 4) == kClear);
    }
    // the baked sheet has the new cell size
    const Json sheet = p.manifest()["assets"]["assets/art/dot.png"]["sheet"];
    CHECK(sheet["frameWidth"] == 6);
    CHECK(sheet["frameHeight"] == 5);
    CHECK(sheet["clips"][0]["name"] == "walk");
}

TEST_CASE("image.resize: an indexed layer whose frame 0 is empty (art only in a cel) moves with the anchor") {
    AssetsProject p;
    const Json doc = Json::parse(R"({"format":"factoria.image/1","width":4,"height":4,"palette":["#000000","#ff0000"],
        "frames":[{"duration":80},{"duration":80}],
        "layers":[{"kind":"indexed","name":"art","cels":[{"frame":1,"rows":[".1..","....","....","...."]}]}]})");
    p.ok("image.save", {{"path", kDoc}, {"document", doc}});
    CHECK(get(frame_of(p, 1), 1, 0) == kRed);
    p.ok("image.resize", {{"path", kDoc}, {"width", 8}, {"height", 8}, {"anchor", "bottom-right"}});
    const Image f1 = frame_of(p, 1);
    CHECK(f1.width == 8);
    CHECK(get(f1, 5, 4) == kRed);
    CHECK_FALSE(get(f1, 1, 0) == kRed);
}

TEST_CASE("image.resize: cropping drops what leaves the canvas, mixed grow and crop, and the default anchor is the centre") {
    AssetsProject p;
    make_dot(p);
    // 4x4 -> 3x4 from the top-right: x shifts by -1, so the pixel of frame 0 is cropped and frames 1 and 2 land at 0 and 1
    p.ok("image.resize", {{"path", kDoc}, {"width", 3}, {"height", 4}, {"anchor", "top-right"}});
    CHECK(frame_of(p, 0).width == 3);
    bool any = false;
    const Image f0 = frame_of(p, 0);
    for (int x = 0; x < 3; ++x) any = any || get(f0, x, 0) == kRed;
    CHECK_FALSE(any);
    CHECK(get(frame_of(p, 1), 0, 0) == kRed);
    CHECK(get(frame_of(p, 2), 1, 0) == kRed);
    // mixed: wider and shorter, centred: +3 columns (floor(1.5) = 1 on the left), -2 rows (1 off the top): bar (row 3) is at row 2
    const Json r = p.ok("image.resize", {{"path", kDoc}, {"width", 6}, {"height", 2}});
    CHECK(r["resized"]["anchor"] == "center");
    CHECK(r["resized"]["offset"]["x"] == 1);
    CHECK(r["resized"]["offset"]["y"] == -1);
    const Image img = frame_of(p, 2);
    CHECK(img.width == 6);
    CHECK(img.height == 2);
    CHECK(get(img, 2, 0) == kClear);  // y: row 0 of the old canvas was cropped off... the dot (frame 2) was at row 0 -> row -1
}

TEST_CASE("image.resize: fill paints only the area a bigger canvas adds") {
    AssetsProject p;
    make_dot(p);
    const Json r = p.ok("image.resize", {{"path", kDoc}, {"width", 6}, {"height", 6}, {"fill", "#0000ff"}});
    CHECK(r["resized"]["filled"] == true);
    const Image img = frame_of(p, 0);
    const Rgba blue{0, 0, 255, 255};
    CHECK(get(img, 0, 0) == blue);
    CHECK(get(img, 5, 5) == blue);
    CHECK(get(img, 1, 1) == kRed);     // the old canvas keeps its own pixels (the dot at (0,0) moved by (1,1))
    CHECK(get(img, 3, 1) == kClear);   // inside the old canvas, transparent stays transparent
    CHECK(read_doc(p)["layers"][0]["name"] == "resize fill");
    // a crop adds nothing to fill
    const Json c = p.ok("image.resize", {{"path", kDoc}, {"width", 5}, {"height", 5}, {"fill", "#0000ff"}});
    CHECK(c["resized"]["filled"] == false);
}

TEST_CASE("image.resize: errors name the pointer, the fix and the nearest anchor") {
    AssetsProject p;
    make_dot(p);
    const std::string before = read_all(p.file(kDoc));
    CommandResult r = p.call("image.resize", {{"path", kDoc}, {"width", 8}, {"height", 8}, {"anchor", "centre"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["hint"].get<std::string>().find("center") != std::string::npos);
    r = p.call("image.resize", {{"path", kDoc}, {"width", 5000}, {"height", 8}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("/width") != std::string::npos);
    r = p.call("image.resize", {{"path", kDoc}, {"width", 4}, {"height", 4}});
    REQUIRE_FALSE(r.ok);
    r = p.call("image.resize", {{"path", kDoc}, {"width", 4}});
    REQUIRE_FALSE(r.ok);
    CHECK(read_all(p.file(kDoc)) == before);  // nothing was written
}

// ---- the scope of the style rules ----------------------------------------------------------------------------------

namespace {

Image block(Rgba fill) {
    Image img = make_image(20, 20, kClear);
    fill_rect(img, 4, 4, 12, 12, fill);
    return img;
}

void write_style(const AssetsProject& p, const Json& style, const Json& assets = Json::object()) {
    Json m = Json::object({{"format", "factoria.assets/1"}, {"style", style}});
    if (!assets.empty()) m["assets"] = assets;
    write_all(p.file("assets.json"), m.dump());
}

bool has_rule(const Json& rules, const std::string& name) {
    for (const Json& r : rules)
        if (r["rule"] == name) return true;
    return false;
}

const Json* skipped_rule(const Json& asset, const std::string& name) {
    if (!asset.contains("styleSkipped")) return nullptr;
    for (const Json& s : asset["styleSkipped"])
        if (s["rule"] == name) return &s;
    return nullptr;
}

// value.max fails on a bright block, outline.color fails without a line around it.
const Json kStyle = Json::parse(R"({"value": {"max": 0.5}, "outline": {"color": "#000000", "width": 1}})");

Json check(const AssetsProject& p, const std::string& path) {
    const Json r = p.ok("assets.check_art", {{"path", path}});
    return r["assets"][0];
}

}  // namespace

TEST_CASE("style.ignore: rules by path skip only those rules and say so") {
    AssetsProject p;
    write_png(p.file("assets/fx/spark.png"), block(kRed));
    write_style(p, kStyle);
    Json a = check(p, "assets/fx/spark.png");
    CHECK(has_rule(a["rules"], "value.max"));
    CHECK(has_rule(a["rules"], "outline.color"));
    CHECK_FALSE(a.contains("styleSkipped"));

    const Json r = p.ok("style.ignore", {{"path", "assets/fx/spark.png"}, {"rules", Json::array({"outline"})}});
    CHECK(r["changed"] == true);
    CHECK(p.manifest()["style"]["ignore"][0] == Json::parse(R"({"path":"assets/fx/spark.png","rules":["outline"]})"));
    a = check(p, "assets/fx/spark.png");
    CHECK_FALSE(has_rule(a["rules"], "outline.color"));
    CHECK(has_rule(a["rules"], "value.max"));  // a real problem is still reported
    const Json* skipped = skipped_rule(a, "outline.color");
    REQUIRE(skipped);
    CHECK((*skipped)["reason"].get<std::string>().find("style.ignore") != std::string::npos);

    // a second call adds to the entry; the same rule again changes nothing
    p.ok("style.ignore", {{"path", "assets/fx/spark.png"}, {"rules", Json::array({"value.max", "outline"})}});
    CHECK(p.manifest()["style"]["ignore"].size() == 1);
    CHECK(p.manifest()["style"]["ignore"][0]["rules"] == Json::parse(R"(["outline","value.max"])"));
    { const Json after = check(p, "assets/fx/spark.png"); CHECK_FALSE(has_rule(after["rules"], "value.max")); CHECK_FALSE(has_rule(after["rules"], "outline.color")); }

    // taking one rule back; then the entry
    p.ok("style.ignore", {{"path", "assets/fx/spark.png"}, {"rules", Json::array({"outline"})}, {"remove", true}});
    CHECK(p.manifest()["style"]["ignore"][0]["rules"] == Json::parse(R"(["value.max"])"));
    p.ok("style.ignore", {{"path", "assets/fx/spark.png"}, {"remove", true}});
    CHECK_FALSE(p.manifest()["style"].contains("ignore"));

    // a folder glob, every rule
    p.ok("style.ignore", {{"path", "assets/fx/**"}});
    CHECK(p.manifest()["style"]["ignore"][0] == "assets/fx/**");
    CHECK(parse_style(p.manifest()["style"]).guide.ignores("assets/fx/deep/spark.png"));
}

TEST_CASE("style.ignore: unknown rules and bad paths are errors that teach") {
    AssetsProject p;
    write_style(p, kStyle);
    CommandResult r = p.call("style.ignore", {{"path", "assets/a.png"}, {"rules", Json::array({"outlin"})}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("/rules/0") != std::string::npos);
    CHECK(r.error["message"].get<std::string>().find("outline") != std::string::npos);
    r = p.call("style.ignore", {{"path", "../outside.png"}});
    REQUIRE_FALSE(r.ok);
    r = p.call("style.set_role", {{"path", "assets/ui/"}, {"role", "icn"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["hint"].get<std::string>().find("icon") != std::string::npos);
    // a mistake written by hand is a problem of the style parser with its pointer
    const StyleParse bad = parse_style(Json::parse(R"({"ignore": [{"path": "a.png", "rules": ["outlin"]}], "roles": {"assets/ui/**": "button"}})"));
    REQUIRE(bad.problems.size() == 2);
    CHECK(bad.problems[0].pointer == "/style/ignore/0/rules/0");
    CHECK(bad.problems[1].pointer == "/style/roles/assets~1ui~1**");
}

TEST_CASE("style roles: provenance.role and a style.roles glob turn off the rules that do not apply, and the check says why") {
    AssetsProject p;
    write_png(p.file("assets/fx/flame.png"), block(kRed));
    write_png(p.file("assets/fx/panel.png"), block(kRed));
    write_png(p.file("assets/art/hero.png"), block(kRed));
    write_style(p, kStyle,
                Json::parse(R"({"assets/fx/panel.png": {"provenance": {"origin": "original", "date": "2026-01-01", "role": "ui"}}})"));
    p.ok("style.set_role", {{"path", "assets/fx/**"}, {"role", "effect"}});
    CHECK(p.manifest()["style"]["roles"]["assets/fx/**"] == "effect");

    // a glob: the effect role turns off value and outline
    Json a = check(p, "assets/fx/flame.png");
    CHECK_FALSE(has_rule(a["rules"], "value.max")); CHECK_FALSE(has_rule(a["rules"], "outline.color"));
    REQUIRE(skipped_rule(a, "value.max"));
    CHECK((*skipped_rule(a, "value.max"))["reason"].get<std::string>().find("style.roles assets/fx/**") != std::string::npos);
    CHECK(a["role"]["role"] == "effect");
    // the provenance role wins over the glob, and ui does not turn off value or outline
    a = check(p, "assets/fx/panel.png");
    CHECK(a["role"]["from"] == "provenance.role");
    CHECK(has_rule(a["rules"], "value.max"));
    CHECK_FALSE(a.contains("styleSkipped"));
    // no role: all rules
    CHECK(has_rule(check(p, "assets/art/hero.png")["rules"], "value.max"));

    p.ok("style.set_role", {{"path", "assets/fx/**"}, {"remove", true}});
    CHECK_FALSE(p.manifest()["style"].contains("roles"));
    CHECK(has_rule(check(p, "assets/fx/flame.png")["rules"], "value.max"));
}

TEST_CASE("style roles: texelsPerUnit follows the role in project.validate, and style.ignore with rules keeps the others") {
    AssetsProject p;
    REQUIRE(create_project(p.dir, "2d-empty").ok());
    write_png(p.file("assets/hud.png"), make_image(16, 16, kRed));
    Json sprite = Json::object({{"texture", "assets/hud.png"}, {"size", Json::array({64, 64})}});
    Json entities = Json::array({Json::object({{"id", "camera"}, {"components", Json::object({{"Camera", Json::object({{"primary", true}})}})}}),
                                 Json::object({{"id", "s"}, {"components", Json::object({{"Sprite", sprite}})}})});
    REQUIRE(save_json_file(p.dir + "/scenes/main.scene.json", Json::object({{"format", "factoria.scene/1"}, {"entities", entities}})).ok());
    auto warnings = [&] {
        std::vector<ValidationIssue> found;
        for (const ValidationIssue& w : validate_project(p.dir).warnings)
            if (w.file == "assets/hud.png") found.push_back(w);
        return found;
    };
    write_style(p, Json::parse(R"({"texelsPerUnit": 1, "value": {"max": 0.5}})"));
    CHECK(warnings().size() == 2);  // 16 px drawn 64 units wide, and a bright picture
    p.ok("style.set_role", {{"path", "assets/hud.png"}, {"role", "ui"}});
    const auto left = warnings();
    REQUIRE(left.size() == 1);  // ui does not ask for a density; the brightness rule still does
    CHECK(left[0].message.find("value.max") != std::string::npos);
    p.ok("style.ignore", {{"path", "assets/hud.png"}, {"rules", Json::array({"value"})}});
    CHECK(warnings().empty());
}
