// image.inpaint and image.generate_layer: a picture from the image provider becomes a masked `provider` layer of an image
// document (docs/IMAGES.md, "Pictures from a provider"). The fake provider and recorded OpenAI answers; no network.
#include "asset_test.h"
#include "fa/ai/assets.h"
#include "fa/ai/image_provider.h"
#include "fa/tooling/asset_import.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

namespace {

constexpr const char* kDoc = "assets/art/scene.image.json";

// A game with the fake image provider, the tooling commands (image.*) and a 64x48 document with two fill layers.
struct Scene : Game {
    explicit Scene(const AiConfig& cfg = fake_config(), ProviderRuntime rt = {}) : Game(cfg, std::move(rt)) {
        fa::register_asset_commands(registry, dir.str());
        ok("image.create", {{"path", kDoc}, {"width", 64}, {"height", 48},
                            {"layers", Json::array({{{"kind", "fill"}, {"name", "sky"}, {"color", "#406080"}},
                                                    {{"kind", "fill"}, {"name", "ground"}, {"color", "#506030"}, {"x", 0}, {"y", 30}, {"width", 64}, {"height", 18}}})}});
    }
    Json select_rect(const std::string& name, int x, int y, int w, int h, Json then = Json::array()) {
        return ok("image.select", {{"path", kDoc}, {"name", name}, {"by", "rect"}, {"x", x}, {"y", y}, {"width", w}, {"height", h}, {"then", then}});
    }
    Image baked() { return decode_png(file("assets/art/scene.png")); }
    Json doc() { return Json::parse(file(kDoc)); }
};

struct Rgba {
    std::uint8_t r, g, b, a;
    bool operator==(const Rgba& o) const { return r == o.r && g == o.g && b == o.b && a == o.a; }
    bool operator!=(const Rgba& o) const { return !(*this == o); }
};
std::ostream& operator<<(std::ostream& os, const Rgba& c) { return os << int(c.r) << "," << int(c.g) << "," << int(c.b) << "," << int(c.a); }

Rgba px(const Image& img, int x, int y) {
    const std::uint8_t* p = &img.rgba[(std::size_t(y) * img.width + x) * 4];
    return {p[0], p[1], p[2], p[3]};
}

}  // namespace

TEST_CASE("image.inpaint with the fake provider: a provider layer whose mask is the selection, the rest of the picture untouched") {
    Scene g;
    const Image before = g.baked();
    g.select_rect("hole", 16, 8, 24, 16);
    auto r = g.call("image.inpaint", {{"path", kDoc}, {"selection", "hole"}, {"prompt", "a round window"}, {"seed", 7}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());

    // the new layer
    const Json doc = g.doc();
    REQUIRE(doc["layers"].size() == 3);
    const Json& layer = doc["layers"][2];
    CHECK(layer["kind"] == "provider");
    CHECK(layer["name"] == "inpaint");
    CHECK(layer["provenance"]["provider"] == "fake");
    CHECK(layer["provenance"]["prompt"] == "a round window");
    CHECK(layer["provenance"]["seed"] == 7);
    CHECK_FALSE(layer["provenance"]["license"].get<std::string>().empty());
    CHECK(layer["provenance"]["notes"].get<std::string>().find("selection 'hole'") != std::string::npos);
    REQUIRE(layer["masks"].size() == 1);
    CHECK(layer["masks"][0]["type"] == "pixels");

    // the mask is the selection, byte for byte
    const Image mask = decode_png(g.file(layer["masks"][0]["source"].get<std::string>()));
    const Image selection = decode_png(g.file(".factoria/selections/" + std::string(kDoc) + "/hole.png"));
    CHECK(mask.width == 64);
    CHECK(mask.rgba == selection.rgba);

    // the picture: changed inside the selection, the same outside it
    const Image after = g.baked();
    CHECK(px(after, 20, 12) != px(before, 20, 12));
    CHECK(px(after, 2, 2) == px(before, 2, 2));
    CHECK(px(after, 60, 45) == px(before, 60, 45));
    CHECK(px(after, 15, 12) == px(before, 15, 12));
    CHECK(px(after, 40, 12) == px(before, 40, 12));   // just right of the selection (x 16..39)

    // provenance of the layer's PNG in assets.json; the baked picture counts as AI-made
    const std::string source = layer["source"];
    CHECK(g.provenance(source)["origin"] == "generated");
    CHECK(g.provenance(source)["ai"] == true);
    CHECK(g.provenance(source)["provider"] == "fake");
    CHECK(g.provenance("assets/art/scene.png")["ai"] == true);
    CHECK(r.result["layer"]["kind"] == "provider");
    CHECK(r.result["$image"].is_object());

    // the document stays valid
    CHECK(g.ok("image.info", {{"path", kDoc}})["valid"] == true);
}

TEST_CASE("image.inpaint: a feathered selection feathers the layer, an inline selection is stored, layer and seed are honoured") {
    Scene g;
    g.select_rect("soft", 10, 10, 30, 20, Json::array({{{"feather", 3}}}));
    g.ok("image.inpaint", {{"path", kDoc}, {"selection", "soft"}, {"prompt", "moss"}});
    const Json doc = g.doc();
    const Image mask = decode_png(g.file(doc["layers"][2]["masks"][0]["source"].get<std::string>()));
    bool partial = false;
    for (std::size_t i = 0; i < mask.rgba.size(); i += 4) partial = partial || (mask.rgba[i] > 0 && mask.rgba[i] < 255);
    CHECK(partial);

    // an inline selection: stored under selectionName, then used
    auto r = g.call("image.inpaint", {{"path", kDoc}, {"prompt", "a door"}, {"name", "door"}, {"selectionName", "door-area"},
                                      {"selection", {{"by", "rect"}, {"x", 4}, {"y", 4}, {"width", 8}, {"height", 12}}}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(g.exists(".factoria/selections/" + std::string(kDoc) + "/door-area.png"));
    CHECK(g.doc()["layers"][3]["name"] == "door");

    // the same request twice gives the same picture; another seed another one
    auto first = g.ok("image.inpaint", {{"path", kDoc}, {"selection", "soft"}, {"prompt", "x"}, {"layer", "sky"}, {"seed", 1}, {"name", "a"}});
    auto second = g.ok("image.inpaint", {{"path", kDoc}, {"selection", "soft"}, {"prompt", "x"}, {"layer", "sky"}, {"seed", 1}, {"name", "b"}});
    auto third = g.ok("image.inpaint", {{"path", kDoc}, {"selection", "soft"}, {"prompt", "x"}, {"layer", "sky"}, {"seed", 2}, {"name", "c"}});
    const Json d = g.doc();
    auto bytes = [&](int i) { return g.file(d["layers"][i]["source"].get<std::string>()); };
    CHECK(bytes(4) == bytes(5));
    CHECK(bytes(4) != bytes(6));

    // only `layer` is sent: a document layer alone
    g.ok("image.inpaint", {{"path", kDoc}, {"selection", "soft"}, {"layer", "sky"}, {"prompt", "x"}, {"name", "d"}});
}

TEST_CASE("image.inpaint in a document with a palette: the result has palette colours only") {
    Scene g;
    g.ok("image.palette", {{"path", kDoc}, {"palette", Json::array({"#101820", "#e04030", "#f0d060", "#406080"})}});
    g.select_rect("area", 8, 8, 32, 24);
    auto r = g.call("image.inpaint", {{"path", kDoc}, {"selection", "area"}, {"prompt", "fire"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Json doc = g.doc();
    const Image pic = decode_png(g.file(doc["layers"][2]["source"].get<std::string>()));
    const std::set<std::uint32_t> allowed = {0x101820, 0xe04030, 0xf0d060, 0x406080};
    for (std::uint32_t c : colours_of(pic)) CHECK(allowed.count(c));
    CHECK(doc["layers"][2]["provenance"]["notes"].get<std::string>().find("4 colours of the document's palette") != std::string::npos);

    // quantize:false keeps the provider's colours
    auto raw = g.call("image.inpaint", {{"path", kDoc}, {"selection", "area"}, {"prompt", "fire"}, {"quantize", false}, {"name", "raw"}});
    REQUIRE_MESSAGE(raw.ok, raw.error.dump());
    CHECK(colours_of(decode_png(g.file(g.doc()["layers"][3]["source"].get<std::string>()))).size() > 4);
}

TEST_CASE("image.inpaint: dryRun sends nothing, wrong calls teach") {
    Scene g;
    g.select_rect("hole", 0, 0, 10, 10);
    const std::string docBefore = g.file(kDoc);
    auto dry = g.ok("image.inpaint", {{"path", kDoc}, {"selection", "hole"}, {"prompt", "x"}, {"dryRun", true}});
    CHECK(dry["dryRun"] == true);
    CHECK(dry["estimate"]["provider"] == "fake");
    CHECK(dry["estimate"]["images"] == 1);
    CHECK(dry["estimate"]["selectedPixels"] == 100);
    CHECK(dry["estimate"]["sentSize"] == "512x384");   // 64x48 is magnified by 8 before it is sent
    CHECK(g.file(kDoc) == docBefore);

    auto noSel = g.call("image.inpaint", {{"path", kDoc}, {"prompt", "x"}});
    REQUIRE_FALSE(noSel.ok);
    CHECK(noSel.error["message"].get<std::string>().find("selection") != std::string::npos);
    CHECK(noSel.error["hint"].get<std::string>().find("selection") != std::string::npos);

    auto wrong = g.call("image.inpaint", {{"path", kDoc}, {"selection", "hol"}, {"prompt", "x"}});
    REQUIRE_FALSE(wrong.ok);
    CHECK(wrong.error["hint"].get<std::string>().find("hole") != std::string::npos);

    auto typo = g.call("image.inpaint", {{"path", kDoc}, {"selection", "hole"}, {"promt", "x"}});
    REQUIRE_FALSE(typo.ok);
    CHECK(typo.error["hint"].get<std::string>().find("prompt") != std::string::npos);

    auto blank = g.call("image.inpaint", {{"path", kDoc}, {"selection", "hole"}, {"prompt", " "}});
    REQUIRE_FALSE(blank.ok);

    g.ok("image.inpaint", {{"path", kDoc}, {"selection", "hole"}, {"prompt", "x"}, {"name", "patch"}});
    auto dup = g.call("image.inpaint", {{"path", kDoc}, {"selection", "hole"}, {"prompt", "x"}, {"name", "patch"}});
    REQUIRE_FALSE(dup.ok);
    CHECK(dup.error["message"].get<std::string>().find("exists already") != std::string::npos);
}

TEST_CASE("image.inpaint and image.generate_layer without a provider say what is missing, how to configure one and the offline route") {
    Scene g(config_from(R"({})"));
    g.select_rect("hole", 0, 0, 10, 10);
    for (const char* name : {"image.inpaint", "image.generate_layer"}) {
        Json args = {{"path", kDoc}, {"prompt", "x"}};
        if (std::string(name) == "image.inpaint") args["selection"] = "hole";
        auto r = g.call(name, args);
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "no_provider");
        CHECK(r.error["message"].get<std::string>().find("No provider is configured for image") != std::string::npos);
        const std::string hint = r.error["hint"];
        CHECK(hint.find("ai.json") != std::string::npos);
        CHECK(hint.find("AI Settings") != std::string::npos);
        CHECK(hint.find("Offline and free") != std::string::npos);
        CHECK(hint.find(kDoc) != std::string::npos);
        CHECK(hint.find("image.layer.add") != std::string::npos);
    }
    // the inpaint hint names the selection commands
    auto inpaint = g.call("image.inpaint", {{"path", kDoc}, {"selection", "hole"}, {"prompt", "x"}});
    CHECK(inpaint.error["hint"].get<std::string>().find("\"selection\":\"hole\"") != std::string::npos);
    CHECK(inpaint.error["hint"].get<std::string>().find("image.edit") != std::string::npos);
    // nothing was written
    CHECK(g.doc()["layers"].size() == 2);
}

TEST_CASE("image.inpaint with a provider that cannot inpaint names the ones that can") {
    Scene g(config_from(R"({"providers":{"painter":{"type":"asset-command","command":"painter","argv":["{prompt}","{output}"]},
                            "inpainter":{"type":"asset-command","command":"painter","argv":["{prompt}","{input}","{mask}","{output}"]}},
                           "assets":{"image":{"provider":"painter"}}})"));
    g.select_rect("hole", 0, 0, 10, 10);
    auto r = g.call("image.inpaint", {{"path", kDoc}, {"selection", "hole"}, {"prompt", "x"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "no_provider");
    CHECK(r.error["message"].get<std::string>().find("cannot inpaint") != std::string::npos);
    CHECK(r.error["hint"].get<std::string>().find("inpainter") != std::string::npos);
    CHECK(r.error["hint"].get<std::string>().find("fake") != std::string::npos);
    // a provider that can is chosen with `provider`
    auto dry = g.call("image.inpaint", {{"path", kDoc}, {"selection", "hole"}, {"prompt", "x"}, {"provider", "inpainter"}, {"dryRun", true}});
    CHECK_MESSAGE(dry.ok, dry.error.dump());
}

TEST_CASE("image.generate_layer: size, placement, transparent background and a selection mask") {
    Scene g;
    g.select_rect("window", 20, 10, 20, 20);
    auto r = g.call("image.generate_layer", {{"path", kDoc}, {"prompt", "a brass key"}, {"size", {{"width", 32}, {"height", 24}}},
                                             {"placement", {{"x", 12}, {"y", 6}}}, {"transparent", true}, {"selection", "window"}, {"name", "key"}, {"seed", 3}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Json layer = g.doc()["layers"][2];
    CHECK(layer["kind"] == "provider");
    CHECK(layer["name"] == "key");
    CHECK(layer["x"] == 12);
    CHECK(layer["y"] == 6);
    CHECK(layer["provenance"]["seed"] == 3);
    // the mask is in the layer's own pixels: the selection sits at minus the layer's place
    CHECK(layer["masks"][0]["x"] == -12);
    CHECK(layer["masks"][0]["y"] == -6);
    const Image pic = decode_png(g.file(layer["source"]));
    CHECK(pic.width == 32);
    CHECK(pic.height == 24);
    CHECK(px(pic, 0, 0).a == 0);   // transparent background
    // only inside the selection (canvas 20..39 x 10..29) does the layer show
    const Image before = decode_png(g.file("assets/art/scene.png"));
    CHECK(px(before, 13, 7) == px(before, 13, 7));
    CHECK(g.ok("image.info", {{"path", kDoc}})["valid"] == true);

    // default: the whole canvas, "center" with a size and no placement
    g.ok("image.generate_layer", {{"path", kDoc}, {"prompt", "mist"}, {"name", "mist"}});
    CHECK(decode_png(g.file(g.doc()["layers"][3]["source"])).width == 64);
    g.ok("image.generate_layer", {{"path", kDoc}, {"prompt", "icon"}, {"name", "icon"}, {"size", {{"width", 16}, {"height", 16}}}});
    const Json icon = g.doc()["layers"][4];
    CHECK(icon["x"] == 24);
    CHECK(icon["y"] == 16);

    auto bad = g.call("image.generate_layer", {{"path", kDoc}, {"prompt", "x"}, {"placement", "middle"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error["hint"].get<std::string>().find("center") != std::string::npos);
}

TEST_CASE("the three steps of an edit (plan, run, store) are what the commands do, and a result for another document is not applied by them") {
    Scene g;
    g.select_rect("hole", 8, 8, 16, 16);
    ImageEditEnv env{[] { return Result<AiConfig>(fake_config()); }, g.dir.str(), {}};
    ImageEditPlan plan = plan_image_edit(env, true, {{"path", kDoc}, {"selection", "hole"}, {"prompt", "a pond"}, {"seed", 5}});
    CHECK(plan.layerName == "inpaint");
    CHECK(plan.provider.name == "fake");
    CHECK(plan.estimate["images"] == 1);
    CHECK(g.doc()["layers"].size() == 2);   // planning changes nothing

    auto made = run_image_edit(plan, env.runtime);
    REQUIRE(made.ok());
    CHECK(g.doc()["layers"].size() == 2);   // neither does the provider call
    ImageEditStored stored = store_image_edit(env, plan, *made);
    CHECK(g.doc()["layers"].size() == 2);   // the document changes when the layer is added
    CHECK(g.exists(stored.addArgs["source"]));
    auto added = g.call("image.layer.add_provider", stored.addArgs);
    REQUIRE_MESSAGE(added.ok, added.error.dump());
    CHECK(g.doc()["layers"].size() == 3);

    // image.layer.add_provider checks what it is given
    auto noProvider = g.call("image.layer.add_provider", {{"path", kDoc}, {"source", stored.addArgs["source"]}, {"provenance", {{"prompt", "x"}}}, {"name", "other"}});
    REQUIRE_FALSE(noProvider.ok);
    CHECK(noProvider.error["message"].get<std::string>().find("provider") != std::string::npos);
    auto noFile = g.call("image.layer.add_provider", {{"path", kDoc}, {"source", "assets/nope.png"}, {"provenance", {{"provider", "fake"}}}});
    REQUIRE_FALSE(noFile.ok);
}

TEST_CASE("image.inpaint through OpenAI: /images/edits with the picture, the mask (transparent = repaint) and the prompt") {
    Wire wire;
    wire.replies = {Wire::reply(200, fixture("openai_image.json"))};
    Scene g(config_from(R"({"assets":{"image":{"provider":"openai"}}})"), wire.runtime({{"OPENAI_API_KEY", "sk-test-0123456789abcdef"}}));
    g.select_rect("hole", 16, 8, 24, 16);
    auto r = g.call("image.inpaint", {{"path", kDoc}, {"selection", "hole"}, {"prompt", "a stained glass window"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    REQUIRE(wire.requests.size() == 1);
    const HttpRequest& req = wire.requests[0];
    CHECK(req.url == "https://api.openai.com/v1/images/edits");
    CHECK(Wire::header(req, "Content-Type").rfind("multipart/form-data; boundary=", 0) == 0);
    CHECK(req.body.find("name=\"image[]\"; filename=\"picture.png\"") != std::string::npos);
    CHECK(req.body.find("name=\"mask\"; filename=\"mask.png\"") != std::string::npos);
    CHECK(req.body.find("name=\"prompt\"\r\n\r\na stained glass window\r\n") != std::string::npos);

    // pull the mask part out and check it: transparent where the selection is
    const std::size_t at = req.body.find("name=\"mask\"; filename=\"mask.png\"");
    const std::size_t start = req.body.find("\r\n\r\n", at) + 4;
    const std::size_t end = req.body.find("\r\n--factoria-form-boundary", start);
    const Image mask = decode_png(req.body.substr(start, end - start));
    CHECK(mask.width == 512);                 // the 64x48 canvas magnified 8 times
    CHECK(px(mask, 20 * 8, 10 * 8).a == 0);   // inside the selection: repaint
    CHECK(px(mask, 2, 2).a == 255);           // outside: keep
    CHECK(g.doc()["layers"][2]["provenance"]["provider"] == "openai");
    CHECK(g.doc()["layers"][2]["provenance"]["license"].get<std::string>().find("openai.com") != std::string::npos);
    CHECK(g.file("assets.json").find("sk-test") == std::string::npos);
}

TEST_CASE("which providers can inpaint: openai, fake, and an asset-command with {input} and {mask}") {
    CHECK(asset_can_inpaint(*config_from(R"({"providers":{"p":{"type":"asset-command","command":"x","argv":["{input}","{mask}","{output}"]}}})").provider("p")));
    CHECK_FALSE(asset_can_inpaint(*config_from(R"({"providers":{"p":{"type":"asset-command","command":"x","argv":["{input}","{output}"]}}})").provider("p")));
    CHECK(asset_can_inpaint(*config_from(R"({})").provider("fake")));
}
