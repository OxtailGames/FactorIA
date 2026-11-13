// model.texture, model.decal, model.palette and model.bake_maps: the texturing of model documents as project files (docs/MODELING.md,
// "Texturing"). The bake itself (maps, wear, decals, triplanar) is tested in fa_scene (engine/scene/tests/test_model_texture.cpp); here: the
// layer pictures, the image document, what a re-bake keeps, staleness, the LODs and the commands' errors.
#include <doctest.h>

#include <fstream>

#include "asset_test_helpers.h"
#include "fa/core/json_schema.h"
#include "fa/scene/model_doc.h"
#include "fa/tooling/image_doc.h"
#include "fa/tooling/model_bake.h"
#include "fa_test_paths.h"

using namespace fa;
using namespace fa::testing;

namespace {

const char* kCrate = "assets/models/crate.model.json";
const char* kCrateDoc = R"({"format": "factoria.model/1",
    "materials": {"wood": {"color": [0.55, 0.35, 0.2, 1]}},
    "nodes": [{"op": "rounded_box", "id": "body", "size": [1, 1, 1], "radius": 0.08, "part": "body", "material": "wood"}]})";

std::string glb_uris(const std::string& glb) {
    const std::size_t at = glb.find("\"images\":");
    return at == std::string::npos ? std::string() : glb.substr(at, glb.find(']', at) - at + 1);
}

Image solid_image(int size, Rgba c) { return make_image(size, size, c); }

struct Textured {
    AssetsProject p;
    Json first;
    explicit Textured(const Json& set = {{"size", 256},
                                         {"ao", true},
                                         {"wear", Json::array({{{"mask", "edges"}, {"color", "#e0d8c8"}}})}}) {
        write_all(p.file(kCrate), kCrateDoc);
        first = p.ok("model.texture", {{"path", kCrate}, {"set", set}, {"picture", false}});
    }
    Json doc() const { return parse_json(read_all(p.file(kCrate)), "doc").value(); }
    ModelBakeState state() const { return model_bake_status(p.dir, kCrate).state; }
};

}  // namespace

TEST_CASE("model.texture: adds the atlas, writes the layer pictures and the image document, and the .glb draws the "
          "composed picture") {
    Textured t;
    const Json& r = t.first;
    CHECK(r["changed"] == true);
    CHECK(r["uvAdded"]["method"] == "unwrap");
    CHECK(r["texturing"]["size"] == 256);
    CHECK(r["texturing"]["ao"]["strength"].get<double>() == doctest::Approx(0.7));
    CHECK(t.doc()["uv"]["method"] == "unwrap");
    CHECK(r["bake"]["state"] == "baked");
    CHECK(r["texture"]["document"] == "assets/models/crate.texture.image.json");
    CHECK(r["texture"]["image"] == "assets/models/crate.texture.png");
    CHECK(r["texture"]["created"] == true);
    for (const char* f : {"base", "uv", "wear", "occlusion"})
        CHECK(t.p.exists(std::string("assets/models/crate.") + f + ".png"));
    CHECK_FALSE(t.p.exists("assets/models/crate.decals.png"));  // no decals: no layer
    CHECK_FALSE(t.p.exists("assets/models/crate.ao.png"));      // not in maps.write
    CHECK(t.p.exists("assets/models/crate.paint.png"));         // the blank layer to paint on
    CHECK(t.p.exists("assets/models/crate.texture.png"));
    CHECK(r["texture"]["report"]["size"] == 256);
    CHECK(r["texture"]["report"]["texels"].get<int>() > 10000);
    CHECK(r["texture"]["report"]["wear"][0]["coverage"].get<double>() > 0);

    // the document lists the model's layers bottom first, then the paint layer, and is a valid image document
    const Json image = parse_json(read_all(t.p.file("assets/models/crate.texture.image.json")), "doc").value();
    std::vector<std::string> names;
    for (const Json& l : image["layers"]) names.push_back(l["name"].get<std::string>());
    CHECK(names == std::vector<std::string>{"model: base", "model: wear", "model: occlusion", "model: uv", "paint"});
    CHECK(image["layers"][2]["blend"] == "multiply");
    CHECK(image["layers"][3]["visible"] == false);
    CHECK(image_bake_status(t.p.dir, "assets/models/crate.texture.image.json").state == ImageBakeState::Fresh);

    // the .glb references the composed picture, not the material colour; the layer pictures are extras of the model with their own manifest entries
    CHECK(glb_uris(read_all(t.p.file("assets/models/crate.glb"))).find("crate.texture.png") != std::string::npos);
    const Json manifest = t.p.manifest();
    CHECK(manifest["assets"].contains("assets/models/crate.base.png"));
    CHECK(manifest["assets"]["assets/models/crate.base.png"]["provenance"]["kind"] == "image");
    CHECK(manifest["assets"]["assets/models/crate.glb"]["provenance"]["texture"]["document"] ==
          "assets/models/crate.texture.image.json");
    CHECK(t.state() == ModelBakeState::Fresh);

    // a picture the size of the atlas, not blank: the wood colour is in it
    const Image out = read_png(t.p.file("assets/models/crate.texture.png"));
    CHECK(out.width == 256);
    bool any = false;
    for (int y = 0; y < out.height && !any; y += 7)
        for (int x = 0; x < out.width; x += 7) {
            const Rgba c = get(out, x, y);
            if (c.r > c.b + 30 && c.a == 255) any = true;  // brownish, not the grey background
        }
    CHECK(any);
}

TEST_CASE("model.texture: the same document gives the same bytes, and a second call with no change writes nothing") {
    Textured t;
    const std::string png = read_all(t.p.file("assets/models/crate.texture.png"));
    const std::string base = read_all(t.p.file("assets/models/crate.base.png"));
    const std::string glb = read_all(t.p.file("assets/models/crate.glb"));
    const Json again = t.p.ok("model.texture", {{"path", kCrate}, {"picture", false}});
    CHECK(again["changed"] == false);
    CHECK(again["bake"]["reason"].get<std::string>().find("nothing changed") != std::string::npos);
    CHECK(read_all(t.p.file("assets/models/crate.texture.png")) == png);
    t.p.ok("model.bake", {{"path", kCrate}, {"force", true}});
    CHECK(read_all(t.p.file("assets/models/crate.base.png")) == base);
    CHECK(read_all(t.p.file("assets/models/crate.texture.png")) == png);
    CHECK(read_all(t.p.file("assets/models/crate.glb")) == glb);
}

TEST_CASE("model.texture: a re-bake keeps the layers that were painted and rewrites only the model's own") {
    Textured t;
    // paint on the layer the bake added (a red square), as image.paint would
    Image paint = read_png(t.p.file("assets/models/crate.paint.png"));
    fill_rect(paint, 40, 40, 30, 30, {255, 0, 0, 255});
    write_png(t.p.file("assets/models/crate.paint.png"), paint);
    // the painted picture makes the model stale: the image document composes it
    CHECK(t.state() == ModelBakeState::Stale);
    t.p.ok("model.bake", {{"path", kCrate}});
    CHECK(t.state() == ModelBakeState::Fresh);
    CHECK(get(read_png(t.p.file("assets/models/crate.texture.png")), 50, 50) == Rgba{255, 0, 0, 255});

    // a new wear entry changes the model's layers; the paint layer, its picture and the red square stay
    const std::string paintBytes = read_all(t.p.file("assets/models/crate.paint.png"));
    const Json r =
        t.p.ok("model.texture",
               {{"path", kCrate},
                {"set", {{"wear", Json::array({{{"mask", "edges"}, {"color", "#e0d8c8"}}, {{"mask", "cavity"}}})}}},
                {"picture", false}});
    CHECK(r["texture"]["created"] == false);
    CHECK(read_all(t.p.file("assets/models/crate.paint.png")) == paintBytes);
    CHECK(get(read_png(t.p.file("assets/models/crate.texture.png")), 50, 50) == Rgba{255, 0, 0, 255});
    const Json image = parse_json(read_all(t.p.file("assets/models/crate.texture.image.json")), "doc").value();
    CHECK(image["layers"].back()["name"] == "paint");

    // a layer the user put in the document, in the middle of the stack, stays where it is; the model's layers keep their order around it
    Json edited = image;
    Json mine = {{"kind", "pixels"}, {"name", "dirt"}, {"source", "assets/models/crate.paint.png"}, {"opacity", 0.5}};
    edited["layers"].insert(edited["layers"].begin() + 1, mine);
    edited["layers"][0]["opacity"] = 0.9;  // a setting on a model layer is the user's too
    write_all(t.p.file("assets/models/crate.texture.image.json"), dump_json(edited));
    t.p.ok("model.texture", {{"path", kCrate}, {"set", {{"decals", Json::array()}}}, {"picture", false}});
    const Json after = parse_json(read_all(t.p.file("assets/models/crate.texture.image.json")), "doc").value();
    CHECK(after["layers"][1]["name"] == "dirt");
    CHECK(after["layers"][1]["opacity"] == 0.5);
    CHECK(after["layers"][0]["opacity"] == 0.9);
}

TEST_CASE("model.texture: a uv change under painted layers is warned about, an unpainted texture is not") {
    Textured t;
    // nothing painted yet: changing the uv size is silent
    const Json quiet = t.p.ok("model.texture", {{"path", kCrate}, {"set", {{"size", 128}}}, {"picture", false}});
    CHECK_FALSE(quiet.contains("warnings"));
    Image paint = read_png(t.p.file("assets/models/crate.paint.png"));
    fill_rect(paint, 10, 10, 20, 20, {0, 255, 0, 255});
    write_png(t.p.file("assets/models/crate.paint.png"), paint);
    const Json loud = t.p.ok("model.texture", {{"path", kCrate}, {"set", {{"size", 256}}}, {"picture", false}});
    REQUIRE(loud.contains("warnings"));
    CHECK(loud["warnings"].dump().find("you painted") != std::string::npos);
    // the painted layer is still there and the document is the new size
    CHECK(parse_json(read_all(t.p.file("assets/models/crate.texture.image.json")), "doc").value()["width"] == 256);
    CHECK(get(read_png(t.p.file("assets/models/crate.paint.png")), 15, 15) == Rgba{0, 255, 0, 255});
}

TEST_CASE("model.texture: the .glb is stale when a decal picture, a material texture or the texture document changes") {
    Textured t;
    write_png(t.p.file("assets/textures/mark.png"), solid_image(16, {200, 30, 30, 255}));
    const Json d = t.p.ok("model.decal", {{"path", kCrate},
                                          {"add",
                                           {{"name", "mark"},
                                            {"image", "assets/textures/mark.png"},
                                            {"position", {0, 0, 0.5}},
                                            {"normal", "front"},
                                            {"size", {0.5, 0.5}}}},
                                          {"picture", false}});
    CHECK(d["texture"]["report"]["decals"][0]["texels"].get<int>() > 100);
    CHECK(t.p.exists("assets/models/crate.decals.png"));
    CHECK(t.state() == ModelBakeState::Fresh);
    const Json recipe = t.p.manifest()["assets"]["assets/models/crate.glb"]["provenance"]["recipe"];
    bool listed = false;
    for (const Json& in : recipe["inputs"]) listed = listed || in["path"] == "assets/textures/mark.png";
    CHECK(listed);

    write_png(t.p.file("assets/textures/mark.png"), solid_image(16, {30, 30, 200, 255}));
    CHECK(t.state() == ModelBakeState::Stale);
    t.p.ok("model.bake", {{"path", kCrate}});
    CHECK(t.state() == ModelBakeState::Fresh);

    // the texture's image document: a hand edit makes it stale, and the layer picture too
    Json image = parse_json(read_all(t.p.file("assets/models/crate.texture.image.json")), "doc").value();
    image["layers"][0]["opacity"] = 0.5;
    write_all(t.p.file("assets/models/crate.texture.image.json"), dump_json(image));
    CHECK(t.state() == ModelBakeState::Stale);
    t.p.ok("model.bake", {{"path", kCrate}});
    CHECK(t.state() == ModelBakeState::Fresh);

    // a layer picture that is gone makes the model missing
    std::filesystem::remove(t.p.file("assets/models/crate.wear.png"));
    CHECK(t.state() == ModelBakeState::Missing);
    t.p.ok("model.bake", {{"path", kCrate}});
    CHECK(t.p.exists("assets/models/crate.wear.png"));
}

TEST_CASE("model.texture: the LODs of gameReady draw the same texture as the .glb") {
    Textured t;
    t.p.ok("model.game_ready", {{"path", kCrate}, {"lods", Json::array({{{"ratio", 0.5}}})}});
    const std::string main = glb_uris(read_all(t.p.file("assets/models/crate.glb")));
    const std::string lod = glb_uris(read_all(t.p.file("assets/models/crate.lod1.glb")));
    CHECK(main.find("crate.texture.png") != std::string::npos);
    CHECK(lod == main);
    const Json prefab = parse_json(read_all(t.p.file("assets/models/crate.prefab.json")), "prefab").value();
    CHECK(prefab["format"] == "factoria.prefab/1");
    CHECK(t.state() == ModelBakeState::Fresh);
}

TEST_CASE("model.texture: clear removes the layer pictures and keeps the image document and what was painted") {
    Textured t({{"size", 128},
                {"maps", {{"write", Json::array({"curvature"})}}},
                {"wear", Json::array({{{"mask", "edges"}}})}});
    CHECK(t.p.exists("assets/models/crate.curvature.png"));
    const Json r = t.p.ok("model.texture", {{"path", kCrate}, {"clear", true}});
    CHECK(r["texturing"].is_null());
    CHECK(r["nextSteps"].dump().find("image document") != std::string::npos);
    for (const char* f : {"base", "uv", "wear", "curvature"})
        CHECK_FALSE(t.p.exists(std::string("assets/models/crate.") + f + ".png"));
    CHECK_FALSE(t.p.manifest()["assets"].contains("assets/models/crate.base.png"));
    CHECK(t.p.exists("assets/models/crate.texture.image.json"));
    CHECK(t.p.exists("assets/models/crate.paint.png"));
    CHECK_FALSE(t.doc().contains("texturing"));
    CHECK(glb_uris(read_all(t.p.file("assets/models/crate.glb"))).empty());  // back to the material colour
    CHECK(t.state() == ModelBakeState::Fresh);
}

TEST_CASE("model.texture: set merges (maps field by field), replace replaces, and a mistake writes nothing and lists "
          "every issue") {
    Textured t({{"size", 128}, {"maps", {{"samples", 8}, {"edgeAngle", 30}}}});
    t.p.ok("model.texture", {{"path", kCrate}, {"set", {{"maps", {{"samples", 12}}}}}, {"bake", false}});
    CHECK(t.doc()["texturing"]["maps"]["samples"] == 12);
    CHECK(t.doc()["texturing"]["maps"]["edgeAngle"] == 30);
    CHECK(t.doc()["texturing"]["size"] == 128);
    t.p.ok("model.texture", {{"path", kCrate}, {"set", {{"size", nullptr}}}, {"bake", false}});
    CHECK_FALSE(t.doc()["texturing"].contains("size"));
    t.p.ok("model.texture", {{"path", kCrate}, {"set", {{"ao", true}}}, {"replace", true}, {"bake", false}});
    CHECK(t.doc()["texturing"] == Json({{"ao", true}}));

    const std::string before = read_all(t.p.file(kCrate));
    auto bad = t.p.call(
        "model.texture",
        {{"path", kCrate}, {"set", {{"size", 7}, {"wear", Json::array({{{"mask", "edgess"}}})}, {"decalz", 1}}}});
    REQUIRE_FALSE(bad.ok);
    const std::string text = bad.error.dump();
    CHECK(text.find("/texturing/size") != std::string::npos);
    CHECK(text.find("/texturing/wear/0/mask") != std::string::npos);
    CHECK(text.find("edges") != std::string::npos);  // did you mean
    CHECK(text.find("decals") != std::string::npos);
    CHECK(text.find("Nothing was written") != std::string::npos);
    CHECK(read_all(t.p.file(kCrate)) == before);
    // arguments
    CHECK_FALSE(t.p.call("model.texture", {{"path", kCrate}, {"set", {{"ao", true}}}, {"clear", true}}).ok);
    CHECK_FALSE(t.p.call("model.texture", {{"path", kCrate}, {"replace", true}}).ok);
    CHECK_FALSE(t.p.call("model.texture", {{"path", "assets/models/nope.model.json"}}).ok);
    CHECK_FALSE(t.p.call("model.texture", {{"path", kCrate}, {"sett", {}}}).ok);
}

TEST_CASE(
    "model.texture: a tile uv layout cannot be textured; a material texture is projected triplanar and reported") {
    AssetsProject p;
    write_png(p.file("assets/textures/stripes.png"), [] {
        Image img = make_image(16, 16, {200, 160, 60, 255});
        fill_rect(img, 0, 0, 8, 16, {40, 40, 200, 255});
        return img;
    }());
    write_all(p.file(kCrate), R"({"format": "factoria.model/1",
        "materials": {"stripes": {"color": [1, 1, 1, 1], "texture": "assets/textures/stripes.png", "textureScale": 0.5}},
        "uv": {"layout": "tile"},
        "nodes": [{"op": "box", "size": [1, 1, 1], "part": "body", "material": "stripes"}]})");
    auto tile = p.call("model.texture", {{"path", kCrate}, {"set", {{"size", 128}}}});
    REQUIRE_FALSE(tile.ok);
    CHECK(tile.error.dump().find("tile") != std::string::npos);
    CHECK(read_all(p.file(kCrate)).find("texturing") == std::string::npos);

    const Json r = p.ok(
        "model.uv",
        {{"path", kCrate}, {"set", {{"layout", "atlas"}, {"method", "unwrap"}}}, {"picture", false}, {"bake", false}});
    const Json t = p.ok("model.texture", {{"path", kCrate}, {"set", {{"size", 128}}}, {"picture", false}});
    CHECK(t["texture"]["report"]["parts"][0]["mapping"] == "triplanar");
    CHECK(t["texture"]["report"]["parts"][0]["texture"] == "assets/textures/stripes.png");
    // both colours of the texture are in the baked picture
    const Image out = read_png(p.file("assets/models/crate.texture.png"));
    bool blue = false, yellow = false;
    for (int y = 0; y < out.height; y += 3)
        for (int x = 0; x < out.width; x += 3) {
            const Rgba c = get(out, x, y);
            blue = blue || (c.b > 150 && c.r < 80);
            yellow = yellow || (c.r > 150 && c.b < 100);
        }
    CHECK(blue);
    CHECK(yellow);
    // the texture is an input of the bake
    const Json recipe = p.manifest()["assets"]["assets/models/crate.glb"]["provenance"]["recipe"];
    bool listed = false;
    for (const Json& in : recipe["inputs"]) listed = listed || in["path"] == "assets/textures/stripes.png";
    CHECK(listed);
    (void)r;
}

TEST_CASE("model.decal: add, replace by name, remove and clear; a missing picture writes nothing and teaches") {
    Textured t({{"size", 256}});
    write_png(t.p.file("assets/textures/mark.png"), solid_image(16, {250, 250, 20, 255}));
    const Json a = t.p.ok(
        "model.decal",
        {{"path", kCrate},
         {"add",
          {{"image", "assets/textures/mark.png"}, {"position", {0, 0, 0.5}}, {"normal", "front"}, {"size", 0.4}}},
         {"picture", false}});
    CHECK(a["changes"][0] == "added 'decal1'");
    CHECK(a["decals"].size() == 1);
    CHECK(a["decals"][0]["name"] == "decal1");
    CHECK(a["texture"]["report"]["decals"][0]["texels"].get<int>() > 100);
    CHECK(t.p.exists("assets/models/crate.decals.png"));
    // the decal's colour is in the baked texture
    const Image tex = read_png(t.p.file("assets/models/crate.texture.png"));
    bool yellow = false;
    for (std::size_t i = 0; i + 3 < tex.rgba.size(); i += 4)
        yellow = yellow || (tex.rgba[i] > 240 && tex.rgba[i + 1] > 240 && tex.rgba[i + 2] < 60);
    CHECK(yellow);

    const Json b = t.p.ok("model.decal", {{"path", kCrate},
                                          {"add", Json::array({{{"name", "decal1"},
                                                                {"image", "assets/textures/mark.png"},
                                                                {"position", {0, 0, -0.5}},
                                                                {"normal", "back"},
                                                                {"size", 0.2}},
                                                               {{"name", "side"},
                                                                {"image", "assets/textures/mark.png"},
                                                                {"position", {0.5, 0, 0}},
                                                                {"normal", "right"},
                                                                {"size", 0.2}}})},
                                          {"picture", false}});
    CHECK(b["decals"].size() == 2);
    CHECK(b["changes"][0] == "replaced 'decal1'");
    CHECK(b["decals"][0]["normal"] == Json::array({0.0, 0.0, -1.0}));
    // a name that does not exist teaches
    auto none = t.p.call("model.decal", {{"path", kCrate}, {"remove", "sid"}});
    REQUIRE_FALSE(none.ok);
    CHECK(none.error.dump().find("side") != std::string::npos);
    const Json c = t.p.ok("model.decal", {{"path", kCrate}, {"remove", "decal1"}, {"picture", false}});
    CHECK(c["decals"].size() == 1);
    const Json d = t.p.ok("model.decal", {{"path", kCrate}, {"clear", true}, {"picture", false}});
    CHECK(d["decals"].empty());
    CHECK_FALSE(t.doc()["texturing"].contains("decals"));
    CHECK_FALSE(t.p.exists("assets/models/crate.decals.png"));
    // listing changes nothing
    CHECK(t.p.ok("model.decal", {{"path", kCrate}, {"picture", false}})["changed"] == false);

    const std::string before = read_all(t.p.file(kCrate));
    auto missing = t.p.call(
        "model.decal",
        {{"path", kCrate}, {"add", {{"image", "assets/textures/nope.png"}, {"position", {0, 0, 0.5}}, {"size", 0.4}}}});
    REQUIRE_FALSE(missing.ok);
    CHECK(missing.error.dump().find("assets/textures/nope.png") != std::string::npos);
    CHECK(read_all(t.p.file(kCrate)) == before);
    auto incomplete = t.p.call("model.decal", {{"path", kCrate}, {"add", {{"image", "assets/textures/mark.png"}}}});
    REQUIRE_FALSE(incomplete.ok);
    CHECK(incomplete.error.dump().find("/texturing/decals/0") != std::string::npos);
    CHECK(read_all(t.p.file(kCrate)) == before);
    CHECK_FALSE(t.p.call("model.decal", {{"path", kCrate}, {"add", {}}, {"clear", true}}).ok);
}

TEST_CASE("model.decal: a decal that misses the surface is reported and a model with no texturing section gets one") {
    AssetsProject p;
    write_all(p.file(kCrate), kCrateDoc);
    write_png(p.file("assets/textures/mark.png"), solid_image(16, {250, 250, 20, 255}));
    const Json r = p.ok("model.decal", {{"path", kCrate},
                                        {"add",
                                         {{"name", "far"},
                                          {"image", "assets/textures/mark.png"},
                                          {"position", {0, 0, 5}},
                                          {"normal", "front"},
                                          {"size", 0.4},
                                          {"depth", 0.1}}},
                                        {"picture", false}});
    CHECK(r["uvAdded"]["method"] == "unwrap");
    CHECK(r["texture"]["report"]["decals"][0]["texels"] == 0);
    CHECK(r["nextSteps"].dump().find("painted no texel") != std::string::npos);
    CHECK(r["warnings"].dump().find("far") != std::string::npos);
}

TEST_CASE("model.palette: sets the vertexColors section, reports the colours and returns the swatches; the style "
          "palette makes the bake depend on the style guide") {
    AssetsProject p;
    write_all(p.file("assets/models/house.model.json"), R"({"format": "factoria.model/1", "nodes": [
        {"op": "box", "size": [2, 1, 2], "part": "wall"}, {"op": "box", "size": [2.2, 0.2, 2.2], "position": [0, 0.6, 0], "part": "roof"}]})");
    const char* house = "assets/models/house.model.json";
    const Json r =
        p.ok("model.palette",
             {{"path", house},
              {"set",
               {{"palette", Json::array({"#8a3b2b", "#d8c8a0", "#445566"})},
                {"flat", true},
                {"variation", 0.04},
                {"parts", {{"wall", {{"color", 1}}}, {"roof", {{"color", 0}}}, {"ghost", {{"color", 2}}}}}}}});
    CHECK(r["changed"] == true);
    CHECK(r["vertexColors"]["flat"] == true);
    CHECK(r["palette"].size() == 3);
    CHECK(r["report"]["coloredTriangles"] == 24);
    CHECK(r["report"]["verticesAfter"].get<int>() > r["report"]["verticesBefore"].get<int>());
    CHECK(r["warnings"].dump().find("ghost") != std::string::npos);
    CHECK(r["$image"]["temporary"] == true);
    CHECK(r["bake"]["state"] == "baked");
    CHECK(p.exists("assets/models/house.glb"));
    // merging: another part's colour, the rest stays
    p.ok("model.palette", {{"path", house},
                           {"set", {{"parts", {{"ghost", nullptr}, {"wall", {{"variation", 0.1}}}}}}},
                           {"picture", false}});
    const Json doc = parse_json(read_all(p.file(house)), "doc").value();
    CHECK_FALSE(doc["vertexColors"]["parts"].contains("ghost"));
    CHECK(doc["vertexColors"]["parts"]["wall"]["color"] == 1);
    CHECK(doc["vertexColors"]["parts"]["wall"]["variation"].get<double>() == doctest::Approx(0.1));
    // errors write nothing
    const std::string before = read_all(p.file(house));
    auto bad = p.call("model.palette", {{"path", house}, {"set", {{"flatt", true}, {"variation", 3}}}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error.dump().find("/vertexColors/variation") != std::string::npos);
    CHECK(read_all(p.file(house)) == before);

    // the style palette
    Json manifest = p.manifest();
    manifest["style"] = {{"palette", Json::array({"#ff0000", "#00ff00", "#0000ff"})}};
    write_all(p.file("assets.json"), manifest.dump(2) + "\n");
    p.ok("model.palette", {{"path", house}, {"set", {{"palette", "style"}}}, {"picture", false}});
    CHECK(model_bake_status(p.dir, house).state == ModelBakeState::Fresh);
    manifest = p.manifest();
    manifest["style"]["palette"] = Json::array({"#ff00ff", "#00ffff", "#ffff00"});
    write_all(p.file("assets.json"), manifest.dump(2) + "\n");
    const Json stale = p.ok("assets.regenerate", {{"path", "assets/models/house.glb"}, {"dryRun", true}});
    REQUIRE_FALSE(stale["wouldRun"].empty());
    CHECK(stale["wouldRun"][0]["stale"] == true);
    // clear
    p.ok("model.palette", {{"path", house}, {"clear", true}, {"picture", false}});
    CHECK_FALSE(parse_json(read_all(p.file(house)), "doc").value().contains("vertexColors"));
}

TEST_CASE("model.bake_maps: measures ao, curvature and thickness in the atlas without writing anything") {
    AssetsProject p;
    write_all(p.file(kCrate), kCrateDoc);
    const std::string before = read_all(p.file(kCrate));
    const Json r = p.ok("model.bake_maps", {{"path", kCrate}, {"size", 128}, {"samples", 8}});
    CHECK(r["size"] == 128);
    CHECK(r["uvAdded"]["method"] == "unwrap");
    REQUIRE(r["report"]["maps"].size() == 3);
    for (const Json& m : r["report"]["maps"]) {
        CHECK(m["min"].get<double>() <= m["mean"].get<double>());
        CHECK(m["mean"].get<double>() <= m["max"].get<double>());
        CHECK(m["max"].get<double>() <= 1.0);
    }
    CHECK(r["report"]["texels"].get<int>() > 3000);
    CHECK(r["$image"]["temporary"] == true);
    CHECK(read_all(p.file(kCrate)) == before);
    CHECK_FALSE(p.exists("assets/models/crate.glb"));
    // the same call gives the same numbers
    CHECK(p.ok("model.bake_maps", {{"path", kCrate}, {"size", 128}, {"samples", 8}, {"picture", false}})["report"] ==
          r["report"]);
    // one map; the document's own texturing.maps are the defaults
    const Json one = p.ok("model.bake_maps",
                          {{"path", kCrate}, {"size", 64}, {"maps", Json::array({"curvature"})}, {"picture", false}});
    CHECK(one["report"]["maps"].size() == 1);
    CHECK(one["report"]["maps"][0]["name"] == "curvature");
    CHECK_FALSE(one.contains("$image"));
    auto bad = p.call("model.bake_maps", {{"path", kCrate}, {"maps", Json::array({"curvatur"})}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error.dump().find("curvature") != std::string::npos);
    CHECK_FALSE(p.call("model.bake_maps", {{"path", kCrate}, {"size", 5}}).ok);
}

TEST_CASE("model.create and model.edit: the texturing and vertexColors sections can be given with the document and "
          "replaced through the document operation") {
    AssetsProject p;
    const Json r = p.ok("model.create", {{"path", kCrate},
                                         {"nodes", Json::array({{{"op", "box"}, {"part", "body"}}})},
                                         {"uv", {{"method", "unwrap"}}},
                                         {"texturing", {{"size", 64}, {"ao", true}}},
                                         {"vertexColors", {{"color", "#80a0c0"}}}});
    CHECK(r["texture"]["document"] == "assets/models/crate.texture.image.json");
    CHECK(r["measurements"]["vertexColors"]["coloredTriangles"] == 12);
    CHECK(p.exists("assets/models/crate.occlusion.png"));
    const Json info = p.ok("model.info", {{"path", kCrate}, {"evaluate", false}});
    CHECK(info["texturing"]["size"] == 64);
    CHECK(info["vertexColors"]["color"] == "#80a0c0");
    CHECK(info["bake"]["state"] == "fresh");
    p.ok("model.edit", {{"path", kCrate}, {"op", "document"}, {"texturing", nullptr}, {"vertexColors", nullptr}});
    CHECK_FALSE(p.exists("assets/models/crate.occlusion.png"));
    CHECK_FALSE(p.ok("model.info", {{"path", kCrate}, {"evaluate", false}}).contains("texturing"));
    // texturing without a uv section is refused by the document check, with the fix
    auto bad = p.call("model.create", {{"path", "assets/models/other.model.json"}, {"texturing", {{"size", 64}}}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error.dump().find("uv") != std::string::npos);
    CHECK_FALSE(p.exists("assets/models/other.model.json"));
}

TEST_CASE("docs/MODELING.md: the examples of Texturing are valid documents") {
    namespace stdfs = std::filesystem;
    const std::string text = read_text(stdfs::path(FA_REPO_ROOT) / "docs" / "MODELING.md");
    const std::size_t from = text.find("\n## Texturing\n"), to = text.find("\n## Game-ready models\n");
    REQUIRE(from != std::string::npos);
    REQUIRE(to != std::string::npos);
    int found = 0;
    for (std::size_t at = text.find("```json\n", from); at != std::string::npos && at < to;
         at = text.find("```json\n", at + 1)) {
        const std::size_t begin = at + 8, end = text.find("```", begin);
        REQUIRE(end != std::string::npos);
        std::string block = text.substr(begin, end - begin);
        const std::size_t dots = block.find("[ ... ]");
        REQUIRE(dots != std::string::npos);  // the examples leave the nodes out; a box stands in for them
        block.replace(dots, 7, R"([{"op": "box", "part": "body", "size": [1, 1, 1]}])");
        ++found;
        auto json = parse_json(block, "MODELING.md");
        REQUIRE_MESSAGE(json.ok(), (json.ok() ? std::string() : json.error().to_string()));
        auto doc = parse_model_doc(*json, "MODELING.md");
        CHECK_MESSAGE(doc.ok(), (doc.ok() ? std::string() : doc.error().to_string()));
    }
    CHECK(found == 2);
}
