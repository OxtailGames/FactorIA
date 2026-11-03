// model.preview and model.check (docs/MODELING.md, "Looking at a model"), and the software rasterizer they share with the editor's Model panel
// (fa/tooling/model_view.h). The mesh checks themselves are tested in fa_scene (engine/scene/tests/test_model_check.cpp).
#include <doctest.h>

#include <algorithm>
#include <fstream>

#include "asset_test_helpers.h"
#include "fa/core/image.h"
#include "fa/core/json_schema.h"
#include "fa/scene/model_doc.h"
#include "fa/tooling/model_view.h"

using namespace fa;
using namespace fa::testing;

namespace {

const char* kCratePath = "assets/models/crate.model.json";
const char* kCrate = R"({"format":"factoria.model/1","nodes":[
    {"op":"rounded_box","size":[1,1,1],"radius":0.05,"position":[0,0.5,0],"part":"body"},
    {"op":"cylinder","radius":0.1,"height":0.4,"position":[0,1.2,0],"part":"post"}]})";

void write_doc(const AssetsProject& p, const char* rel, const char* text) {
    std::filesystem::create_directories(p.file(rel).parent_path());
    std::ofstream(p.file(rel), std::ios::binary) << text;
}

Image load_picture(const Json& result) {
    REQUIRE(result.contains("$image"));
    auto img = load_image(result["$image"]["path"].get<std::string>());
    REQUIRE_MESSAGE(img.ok(), (img.ok() ? std::string() : img.error().message));
    return std::move(*img);
}

std::size_t differing_pixels(const Image& a, const Image& b) {
    REQUIRE(a.width == b.width);
    REQUIRE(a.height == b.height);
    std::size_t n = 0;
    for (std::size_t i = 0; i + 3 < a.rgba.size(); i += 4)
        if (a.rgba[i] != b.rgba[i] || a.rgba[i + 1] != b.rgba[i + 1] || a.rgba[i + 2] != b.rgba[i + 2]) ++n;
    return n;
}

MeshData built_mesh(const char* text) {
    auto doc = parse_model_doc(parse_json(text, "t").value(), "t.model.json");
    REQUIRE(doc.ok());
    auto b = evaluate_model(*doc);
    REQUIRE(b.ok());
    return std::move(b->data);
}

}  // namespace

// ---- the rasterizer ---------------------------------------------------------------------------------------------------------

TEST_CASE("model view: a box seen from the front fills the middle, the corners stay background, and the same view is the same pixels") {
    const MeshData box = built_mesh(R"({"format":"factoria.model/1","nodes":[{"op":"box","size":[1,1,1]}]})");
    ModelViewItem item;
    item.mesh = &box;
    ModelViewOptions o;
    o.width = o.height = 128;
    o.ground = false;
    o.yawDeg = 0;
    o.pitchDeg = 0;
    o.orthographic = true;
    const Image a = render_model_view({item}, o), b = render_model_view({item}, o);
    REQUIRE(a.width == 128);
    REQUIRE(a.height == 128);
    CHECK(differing_pixels(a, b) == 0);
    const auto px = [&](int x, int y) { return a.rgba.data() + (std::size_t(y) * 128 + std::size_t(x)) * 4; };
    CHECK(px(64, 64)[0] > 60);              // lit surface
    CHECK(px(2, 2)[0] == 33);               // background 0.13 * 255
    CHECK(px(2, 125)[2] == px(125, 2)[2]);  // corners are the same background
}

TEST_CASE("model view: the inside of a surface is dark red") {
    MeshData box = built_mesh(R"({"format":"factoria.model/1","nodes":[{"op":"box","size":[1,1,1]}]})");
    for (std::size_t i = 0; i + 2 < box.indices.size(); i += 3) std::swap(box.indices[i + 1], box.indices[i + 2]);
    ModelViewItem item;
    item.mesh = &box;
    ModelViewOptions o;
    o.width = o.height = 96;
    o.ground = false;
    o.yawDeg = 20;
    o.pitchDeg = 15;
    const Image img = render_model_view({item}, o);
    const std::uint8_t* c = img.rgba.data() + (std::size_t(48) * 96 + 48) * 4;
    CHECK(c[0] > c[1] + 40);
    CHECK(c[0] > c[2] + 40);
}

TEST_CASE("model view: wireframe and highlighted parts change the picture, hidden-line wireframe draws no surface") {
    const MeshData m = built_mesh(kCrate);
    ModelViewItem item;
    item.mesh = &m;
    ModelViewOptions o;
    o.width = o.height = 160;
    o.ground = false;
    const Image shaded = render_model_view({item}, o);
    o.wireframe = true;
    const Image both = render_model_view({item}, o);
    CHECK(differing_pixels(shaded, both) > 200);
    o.wireframe = false;
    item.highlightPart = "post";
    const Image lit = render_model_view({item}, o);
    CHECK(differing_pixels(shaded, lit) > 50);
    o.shaded = false;
    o.wireframe = true;
    item.highlightPart.clear();
    const Image wire = render_model_view({item}, o);
    // a hidden-line view is mostly background
    std::size_t background = 0;
    for (std::size_t i = 0; i + 3 < wire.rgba.size(); i += 4) background += wire.rgba[i] == 33 && wire.rgba[i + 1] == 36 && wire.rgba[i + 2] == 43;
    CHECK(background > wire.rgba.size() / 4 * 7 / 10);
}

TEST_CASE("model view: the reference figure is 1.8 m tall and stands on the ground") {
    const MeshData& f = model_reference_figure();
    REQUIRE_FALSE(f.positions.empty());
    float lo = 1e9f, hi = -1e9f;
    for (std::size_t i = 1; i < f.positions.size(); i += 3) {
        lo = std::min(lo, f.positions[i]);
        hi = std::max(hi, f.positions[i]);
    }
    CHECK(lo == doctest::Approx(0.0f).epsilon(0.001));
    CHECK(hi == doctest::Approx(1.8f).epsilon(0.001));
    const Vec3 off = reference_figure_offset({-1, 0, -1}, {1, 2, 1});
    CHECK(off.x > 1.0f);
    CHECK(off.y == 0.0f);
}

// ---- model.preview ----------------------------------------------------------------------------------------------------------

TEST_CASE("model.preview: a turntable sheet next to the 1.8 m figure, as a PNG") {
    AssetsProject p;
    write_doc(p, kCratePath, kCrate);
    const Json r = p.ok("model.preview", {{"path", kCratePath}});
    CHECK(r["$image"]["temporary"] == true);
    const Image img = load_picture(r);
    CHECK(img.width == r["picture"]["width"].get<int>());
    CHECK(img.height == r["picture"]["height"].get<int>());
    CHECK(r["views"].size() == 6);
    CHECK(r["views"][0]["yaw"] == 30.0);
    CHECK(r["views"][1]["yaw"] == 90.0);
    CHECK(r["stats"]["triangles"].get<int>() > 100);
    CHECK(r["stats"]["bounds"]["size"][1].get<double>() == doctest::Approx(1.4).epsilon(0.01));
    CHECK(r["stats"]["heightVersusFigure"].get<double>() == doctest::Approx(1.4 / 1.8).epsilon(0.01));
    CHECK(r["stats"]["parts"].size() == 2);
    // the sheet is not blank: many pixels differ from the header colour
    std::size_t plain = 0;
    for (std::size_t i = 0; i + 3 < img.rgba.size(); i += 4) plain += img.rgba[i] == img.rgba[0] && img.rgba[i + 1] == img.rgba[1] && img.rgba[i + 2] == img.rgba[2];
    CHECK(plain < img.rgba.size() / 4 * 8 / 10);
    // nothing was written to the project besides the temporary picture
    CHECK_FALSE(p.exists("assets/models/crate.glb"));
    CHECK(r["nextSteps"].size() >= 2);
}

TEST_CASE("model.preview: the same call draws the same pixels; the options change them") {
    AssetsProject p;
    write_doc(p, kCratePath, kCrate);
    const Image a = load_picture(p.ok("model.preview", {{"path", kCratePath}, {"cell", 160}}));
    const Image b = load_picture(p.ok("model.preview", {{"path", kCratePath}, {"cell", 160}}));
    CHECK(differing_pixels(a, b) == 0);
    const Image noFigure = load_picture(p.ok("model.preview", {{"path", kCratePath}, {"cell", 160}, {"figure", false}}));
    CHECK(differing_pixels(a, noFigure) > 500);
    const Image wire = load_picture(p.ok("model.preview", {{"path", kCratePath}, {"cell", 160}, {"mode", "shaded_wireframe"}}));
    CHECK(differing_pixels(a, wire) > 500);
    const Image part = load_picture(p.ok("model.preview", {{"path", kCratePath}, {"cell", 160}, {"part", "post"}}));
    CHECK(differing_pixels(a, part) > 100);
}

TEST_CASE("model.preview: 4 to 8 views, laid out in a grid") {
    AssetsProject p;
    write_doc(p, kCratePath, kCrate);
    const Json four = p.ok("model.preview", {{"path", kCratePath}, {"views", 4}, {"yaw", 0}, {"cell", 128}});
    CHECK(four["picture"]["columns"] == 2);
    CHECK(four["picture"]["rows"] == 2);
    CHECK(four["views"][2]["yaw"] == 180.0);
    const Json eight = p.ok("model.preview", {{"path", kCratePath}, {"views", 8}, {"cell", 128}, {"pitch", 35}});
    CHECK(eight["picture"]["columns"] == 4);
    CHECK(eight["picture"]["rows"] == 2);
    CHECK(eight["views"][7]["pitch"] == 35.0);
    CHECK(eight["picture"]["width"].get<int>() > four["picture"]["width"].get<int>());
}

TEST_CASE("model.preview: mistakes say what is allowed and what was meant") {
    AssetsProject p;
    write_doc(p, kCratePath, kCrate);
    auto few = p.call("model.preview", {{"path", kCratePath}, {"views", 3}});
    REQUIRE_FALSE(few.ok);
    CHECK(few.error.dump().find("4") != std::string::npos);
    auto mode = p.call("model.preview", {{"path", kCratePath}, {"mode", "wirefram"}});
    REQUIRE_FALSE(mode.ok);
    CHECK(mode.error.dump().find("wireframe") != std::string::npos);
    auto part = p.call("model.preview", {{"path", kCratePath}, {"part", "pots"}});
    REQUIRE_FALSE(part.ok);
    CHECK(part.error.dump().find("post") != std::string::npos);
    auto missing = p.call("model.preview", {{"path", "assets/models/crat.model.json"}});
    REQUIRE_FALSE(missing.ok);
    CHECK(missing.error.dump().find("crate.model.json") != std::string::npos);
    auto none = p.call("model.preview", Json::object());
    REQUIRE_FALSE(none.ok);
    CHECK(none.error.dump().find("path") != std::string::npos);
    auto typo = p.call("model.preview", {{"path", kCratePath}, {"view", 4}});
    REQUIRE_FALSE(typo.ok);
    CHECK(typo.error.dump().find("views") != std::string::npos);
    auto bad = p.call("model.preview", {{"document", {{"nodes", Json::array({{{"op", "bxo"}}})}}}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error.dump().find("box") != std::string::npos);
}

TEST_CASE("model.preview: out keeps the PNG in the project and does not overwrite by accident") {
    AssetsProject p;
    write_doc(p, kCratePath, kCrate);
    const Json r = p.ok("model.preview", {{"path", kCratePath}, {"out", "docs/review/crate.png"}, {"cell", 128}});
    CHECK(r["written"] == "docs/review/crate.png");
    CHECK(p.exists("docs/review/crate.png"));
    CHECK_FALSE(r["$image"].contains("temporary"));
    auto again = p.call("model.preview", {{"path", kCratePath}, {"out", "docs/review/crate.png"}});
    REQUIRE_FALSE(again.ok);
    CHECK(again.error.dump().find("overwrite") != std::string::npos);
    p.ok("model.preview", {{"path", kCratePath}, {"out", "docs/review/crate.png"}, {"overwrite", true}, {"cell", 128}});
    auto notPng = p.call("model.preview", {{"path", kCratePath}, {"out", "docs/crate.jpg"}});
    REQUIRE_FALSE(notPng.ok);
}

TEST_CASE("model.preview: it draws the mesh the game gets, with the gameReady origin applied") {
    AssetsProject p;
    write_doc(p, "assets/models/lamp.model.json",
              R"({"format":"factoria.model/1","gameReady":{"origin":"bottom_center"},"nodes":[{"op":"cylinder","radius":0.2,"height":1,"position":[3,5,2]}]})");
    const Json r = p.ok("model.preview", {{"path", "assets/models/lamp.model.json"}, {"cell", 128}, {"views", 4}});
    CHECK(r["stats"]["mesh"] == "gameReady");
    CHECK(r["stats"]["bounds"]["min"][1].get<double>() == doctest::Approx(0.0).epsilon(0.001));
    CHECK(r["stats"]["bounds"]["min"][0].get<double>() == doctest::Approx(-0.2).epsilon(0.01));
}

// ---- model.check ------------------------------------------------------------------------------------------------------------

TEST_CASE("model.check: with no document it lists the checks and the platform budgets of model.game_ready") {
    AssetsProject p;
    const Json r = p.ok("model.check", Json::object());
    REQUIRE(r.contains("checks"));
    std::vector<std::string> codes;
    for (const Json& c : r["checks"]) codes.push_back(c["code"].get<std::string>());
    for (const char* code : {"inside_out", "open_edges", "scale", "triangle_budget"}) CHECK(std::find(codes.begin(), codes.end(), code) != codes.end());
    CHECK(r["platformBudgets"].size() == 3);
    CHECK(r["referenceFigure"]["height"] == 1.8);
}

TEST_CASE("model.check: a clean solid, then scale, open surfaces and budgets, each finding teaching where and how to fix") {
    AssetsProject p;
    write_doc(p, kCratePath, kCrate);
    const Json clean = p.ok("model.check", {{"path", kCratePath}});
    CHECK(clean["ok"] == true);
    CHECK(clean["errors"] == 0);
    CHECK(clean["findings"].empty());
    CHECK(clean["mesh"]["openEdges"] == 0);
    CHECK(clean["mesh"]["pieces"] == 2);
    CHECK(clean["mesh"]["height"].get<double>() == doctest::Approx(1.4).epsilon(0.01));
    CHECK(clean["checked"]["platforms"].size() == 3);

    const Json scale = p.ok("model.check", {{"path", kCratePath}, {"expectedHeight", 14}});
    REQUIRE(scale["findings"].size() == 1);
    CHECK(scale["findings"][0]["code"] == "scale");
    CHECK(scale["findings"][0]["severity"] == "warning");
    CHECK(scale["findings"][0]["hint"].get<std::string>().find("scale") != std::string::npos);
    CHECK(scale["ok"] == true);  // a warning
    CHECK(p.ok("model.check", {{"path", kCratePath}, {"expectedHeight", 1.5}})["findings"].empty());

    write_doc(p, "assets/models/sheet.model.json", R"({"format":"factoria.model/1","nodes":[{"op":"grid","width":2,"depth":2}]})");
    const Json open = p.ok("model.check", {{"path", "assets/models/sheet.model.json"}});
    REQUIRE_FALSE(open["findings"].empty());
    CHECK(open["findings"][0]["code"] == "open_edges");
    CHECK(open["findings"][0]["count"].get<int>() > 0);
    CHECK_FALSE(open["findings"][0]["samples"].empty());
    CHECK(open["findings"][0]["bounds"]["min"].size() == 3);
    CHECK(open["findings"][0]["hint"].get<std::string>().find("ignore") != std::string::npos);
    const Json ignored = p.ok("model.check", {{"path", "assets/models/sheet.model.json"}, {"ignore", Json::array({"open_edges"})}});
    CHECK(ignored["findings"].empty());

    write_doc(p, "assets/models/ball.model.json", R"({"format":"factoria.model/1","nodes":[{"op":"sphere","radius":0.5,"segments":256,"rings":128,"position":[0,0.5,0]}]})");
    const Json budget = p.ok("model.check", {{"path", "assets/models/ball.model.json"}});
    std::vector<std::string> platforms;
    for (const Json& f : budget["findings"])
        if (f["code"] == "triangle_budget") platforms.push_back(f["platform"].get<std::string>());
    CHECK(platforms == std::vector<std::string>{"mobile", "web"});
    const Json mobile = p.ok("model.check", {{"path", "assets/models/ball.model.json"}, {"platforms", Json::array({"mobile"})}});
    CHECK(mobile["findings"].size() == 1);
    CHECK(mobile["checked"]["platforms"] == Json::array({"mobile"}));
}

TEST_CASE("model.check: the LODs of the document's gameReady make a budget finding information") {
    AssetsProject p;
    write_doc(p, "assets/models/ball.model.json",
              R"({"format":"factoria.model/1","gameReady":{"lods":[{"ratio":0.3}]},"nodes":[{"op":"sphere","radius":0.5,"segments":160,"rings":80,"position":[0,0.5,0]}]})");
    const Json r = p.ok("model.check", {{"path", "assets/models/ball.model.json"}, {"platforms", Json::array({"mobile"})}});
    REQUIRE(r["findings"].size() == 1);
    CHECK(r["findings"][0]["severity"] == "info");
    CHECK(r["findings"][0]["message"].get<std::string>().find("LOD1") != std::string::npos);
    CHECK(r["infos"] == 1);
    CHECK(r["warnings"] == 0);
}

TEST_CASE("model.check: mistakes teach") {
    AssetsProject p;
    write_doc(p, kCratePath, kCrate);
    auto code = p.call("model.check", {{"path", kCratePath}, {"ignore", Json::array({"open_edge"})}});
    REQUIRE_FALSE(code.ok);
    CHECK(code.error.dump().find("open_edges") != std::string::npos);
    auto platform = p.call("model.check", {{"path", kCratePath}, {"platforms", Json::array({"mobil"})}});
    REQUIRE_FALSE(platform.ok);
    CHECK(platform.error.dump().find("mobile") != std::string::npos);
    auto height = p.call("model.check", {{"path", kCratePath}, {"expectedHeight", -1}});
    REQUIRE_FALSE(height.ok);
    auto typo = p.call("model.check", {{"path", kCratePath}, {"expectedHight", 1.8}});
    REQUIRE_FALSE(typo.ok);
    CHECK(typo.error.dump().find("expectedHeight") != std::string::npos);
    auto both = p.call("model.check", {{"path", kCratePath}, {"document", Json::object()}});
    REQUIRE_FALSE(both.ok);
    auto bad = p.call("model.check", {{"document", {{"nodes", Json::array({{{"op", "box"}, {"sise", {1, 1, 1}}}})}}}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error.dump().find("size") != std::string::npos);
}

TEST_CASE("model.check: an inline document is checked without being written") {
    AssetsProject p;
    const Json r = p.ok("model.check", {{"document", {{"nodes", Json::array({{{"op", "box"}, {"size", {0.01, 0.01, 0.01}}}})}}}});
    REQUIRE_FALSE(r["findings"].empty());
    CHECK(r["path"] == "document");
    bool scale = false;
    for (const Json& f : r["findings"]) scale = scale || f["code"] == "scale";
    CHECK(scale);
}
