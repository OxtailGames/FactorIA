// model.generate_lods and the `gameReady.lodChain` setting (docs/BIG_WORLDS.md, "Automatic LOD chain"): the chain's files, the screen-size prefab, determinism,
// the settings round trip, the errors that teach, and the levels a tiny mesh skips.
#include <doctest.h>

#include "asset_test_helpers.h"
#include "fa/scene/model_doc.h"
#include "fa/scene/model_game_ready.h"
#include "fa/tooling/model_bake.h"

using namespace fa;
using namespace fa::testing;

namespace {

const char* kBall =
    R"({"format": "factoria.model/1", "nodes": [{"op": "sphere", "id": "s", "radius": 1, "part": "ball"}]})";
const char* kCube = R"({"format": "factoria.model/1", "nodes": [{"op": "box", "id": "b", "size": [1, 1, 1]}]})";

}  // namespace

TEST_CASE("model.generate_lods: a chain of falling triangle counts, screen-size prefab, same bytes twice") {
    AssetsProject p;
    write_all(p.file("assets/models/ball.model.json"), kBall);
    const Json r = p.ok("model.generate_lods", {{"model", "assets/models/ball.model.json"}, {"levels", 3}});
    REQUIRE(r["levels"].size() == 3);
    long previous = r["fullTriangles"].get<long>();
    double screen = 2;
    for (const Json& l : r["levels"]) {
        CHECK(l["triangles"].get<long>() < previous);
        previous = l["triangles"].get<long>();
        CHECK(l["screenSize"].get<double>() < screen);
        screen = l["screenSize"].get<double>();
        CHECK(p.exists(l["file"].get<std::string>()));
    }
    CHECK(r["levels"][0]["screenSize"].get<double>() == doctest::Approx(0.5));
    CHECK(r["levels"][2]["screenSize"].get<double>() == doctest::Approx(0.12));
    CHECK(r["levels"][0]["error"].get<double>() > 0);
    const Json prefab = parse_json(read_all(p.file("assets/models/ball.prefab.json")), "prefab").value();
    const Json& mr = prefab["entity"]["components"]["MeshRenderer"];
    CHECK(mr["lodMode"] == "screenSize");
    REQUIRE(mr["lods"].size() == 3);
    CHECK(mr["lods"][0]["mesh"] == "assets/models/ball.lod1.glb");
    CHECK(mr["lods"][1]["screenSize"].get<double>() == doctest::Approx(0.25));
    CHECK_FALSE(mr["lods"][0].contains("distance"));

    // settings round trip: the document keeps the chain, game_ready reports it
    const Json doc = parse_json(read_all(p.file("assets/models/ball.model.json")), "doc").value();
    CHECK(doc["gameReady"]["lodChain"]["enabled"] == true);
    CHECK(doc["gameReady"]["lodChain"]["levels"] == 3);
    const Json info = p.ok("model.game_ready", {{"path", "assets/models/ball.model.json"}});
    CHECK(info["settings"]["lodChain"]["enabled"] == true);
    CHECK(info["report"]["lods"].size() == 4);

    // determinism: a forced bake rewrites the same bytes, and the .glb of the .model.json route gives the same chain
    const std::string lod2 = read_all(p.file("assets/models/ball.lod2.glb"));
    p.ok("model.bake", {{"path", "assets/models/ball.model.json"}, {"force", true}});
    CHECK(read_all(p.file("assets/models/ball.lod2.glb")) == lod2);
    const Json again = p.ok("model.generate_lods", {{"model", "assets/models/ball.glb"}, {"levels", 3}});
    CHECK(again["levels"] == r["levels"]);
    CHECK(read_all(p.file("assets/models/ball.lod2.glb")) == lod2);

    // fewer levels: the extra file goes, a stale per-level list does not break it
    p.ok("model.generate_lods", {{"model", "assets/models/ball.model.json"}, {"ratios", {0.5, 0.5, 0.5}}});
    const Json two = p.ok("model.generate_lods", {{"model", "assets/models/ball.model.json"}, {"levels", 2}});
    CHECK(two["levels"].size() == 2);
    CHECK(two.contains("notes"));
    CHECK_FALSE(p.exists("assets/models/ball.lod3.glb"));

    // dryRun reports and writes nothing
    const std::string before = read_all(p.file("assets/models/ball.model.json"));
    const Json dry =
        p.ok("model.generate_lods", {{"model", "assets/models/ball.model.json"}, {"levels", 1}, {"dryRun", true}});
    CHECK(dry["written"] == false);
    CHECK(read_all(p.file("assets/models/ball.model.json")) == before);
}

TEST_CASE("model.generate_lods: a tiny mesh skips the levels under minTriangles and says so") {
    AssetsProject p;
    write_all(p.file("assets/models/cube.model.json"), kCube);
    const Json r = p.ok("model.generate_lods", {{"model", "assets/models/cube.model.json"}});
    CHECK(r["levels"].empty());
    REQUIRE(r.contains("notes"));
    CHECK(r["notes"][0].get<std::string>().find("minTriangles") != std::string::npos);
    CHECK_FALSE(p.exists("assets/models/cube.prefab.json"));
    // minTriangles 2: the simplifier cannot reduce a 12-triangle cube at 0.5 either, so still no level
    const Json r2 =
        p.ok("model.generate_lods", {{"model", "assets/models/cube.model.json"}, {"minTriangles", 2}, {"levels", 1}});
    CHECK(r2["levels"].size() == 0);  // 12 triangles: even at 2 the first level halves below it, so it stops
}

TEST_CASE("model.generate_lods: errors name the JSON pointer and the fix") {
    AssetsProject p;
    write_all(p.file("assets/models/ball.model.json"), kBall);
    // unknown key: did you mean
    CommandResult r = p.call("model.generate_lods", {{"model", "assets/models/ball.model.json"}, {"level", 2}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("levels") != std::string::npos);
    // model not found: suggestions
    r = p.call("model.generate_lods", {{"model", "assets/models/bal.model.json"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "not_found");
    CHECK(r.error.dump().find("ball.model.json") != std::string::npos);
    // a falling list must fall, with a pointer; nothing written
    const std::string before = read_all(p.file("assets/models/ball.model.json"));
    r = p.call("model.generate_lods",
               {{"model", "assets/models/ball.model.json"}, {"levels", 2}, {"screenSizes", {0.2, 0.4}}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("/gameReady/lodChain/screenSizes/1") != std::string::npos);
    CHECK(read_all(p.file("assets/models/ball.model.json")) == before);
    // wrong list length
    r = p.call("model.generate_lods", {{"model", "assets/models/ball.model.json"}, {"levels", 2}, {"ratios", {0.5}}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("/gameReady/lodChain/ratios") != std::string::npos);
    // contradiction: maxError and errors
    r = p.call("model.generate_lods",
               {{"model", "assets/models/ball.model.json"}, {"maxError", 0.1}, {"errors", {0.1, 0.1, 0.1}}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("/maxError") != std::string::npos);
    // explicit distance LODs and a chain are two ways of the same thing
    p.ok("model.game_ready", {{"path", "assets/models/ball.model.json"}, {"lods", Json::array({{{"ratio", 0.5}}})}});
    r = p.call("model.generate_lods", {{"model", "assets/models/ball.model.json"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("/gameReady/lods") != std::string::npos);
    // a mesh no document baked
    write_all(p.file("assets/models/raw.glb"), "glTF");
    r = p.call("model.generate_lods", {{"model", "assets/models/raw.glb"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("model.import_clean") != std::string::npos);
}

TEST_CASE("model.generate_lods: a skinned mesh (a rig's .glb) is refused") {
    AssetsProject p;
    write_all(p.file("assets/models/ball.model.json"), kBall);
    p.ok("model.bake", {{"path", "assets/models/ball.model.json"}});
    // make assets.json say a rig baked the file
    Json manifest = p.manifest();
    manifest["assets"]["assets/models/ball.glb"]["provenance"]["recipe"]["command"] = "rig.bake";
    write_all(p.file("assets.json"), manifest.dump(2));
    const CommandResult r = p.call("model.generate_lods", {{"model", "assets/models/ball.glb"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "unsupported");
    CHECK(r.error.dump().find("skin") != std::string::npos);
}

TEST_CASE("gameReady.lodChain: parse, defaults round trip, conflicts and unknown keys") {
    auto good = parse_game_ready(
        Json::parse(R"({"lodChain": {"enabled": true, "levels": 2, "screenSizes": [0.4, 0.1]}})"), "/gameReady");
    REQUIRE(good.ok());
    CHECK(good->lodChain.enabled);
    CHECK(good->lodChain.levels == 2);
    CHECK_FALSE(good->is_default());
    auto again = parse_game_ready(game_ready_to_json(*good), "/gameReady");
    REQUIRE(again.ok());
    CHECK(game_ready_to_json(*again) == game_ready_to_json(*good));
    auto both =
        parse_game_ready(Json::parse(R"({"lods": [{"ratio": 0.5}], "lodChain": {"enabled": true}})"), "/gameReady");
    REQUIRE_FALSE(both.ok());
    CHECK(both.error().message.find("/gameReady/lodChain") != std::string::npos);
    auto typo = parse_game_ready(Json::parse(R"({"lodChain": {"enabled": true, "minTriangle": 3}})"), "/gameReady");
    REQUIRE_FALSE(typo.ok());
    CHECK(typo.error().hint.find("minTriangles") != std::string::npos);
}

TEST_CASE("model.game_ready: lodChain null removes the chain and its files; chain and lods switch") {
    AssetsProject p;
    write_all(p.file("assets/models/ball.model.json"), kBall);
    p.ok("model.generate_lods", {{"model", "assets/models/ball.model.json"}, {"levels", 2}});
    CHECK(p.exists("assets/models/ball.lod2.glb"));
    // the chain and lods are exclusive; the error names the way out
    CommandResult both = p.call("model.game_ready",
                                {{"path", "assets/models/ball.model.json"}, {"lods", Json::array({{{"ratio", 0.5}}})}});
    REQUIRE_FALSE(both.ok);
    CHECK(both.error.dump().find("lodChain\\\": null") != std::string::npos);
    // switch to distance LODs in one call
    p.ok("model.game_ready",
         {{"path", "assets/models/ball.model.json"}, {"lodChain", nullptr}, {"lods", Json::array({{{"ratio", 0.5}}})}});
    CHECK_FALSE(p.exists("assets/models/ball.lod2.glb"));
    Json prefab = parse_json(read_all(p.file("assets/models/ball.prefab.json")), "prefab").value();
    CHECK(prefab["entity"]["components"]["MeshRenderer"]["lods"][0].contains("distance"));
    CHECK_FALSE(prefab["entity"]["components"]["MeshRenderer"].contains("lodMode"));
    // and back to a chain, then remove it
    p.ok("model.game_ready", {{"path", "assets/models/ball.model.json"},
                              {"lods", nullptr},
                              {"lodChain", {{"enabled", true}, {"levels", 1}}}});
    CHECK(p.exists("assets/models/ball.lod1.glb"));
    p.ok("model.game_ready", {{"path", "assets/models/ball.model.json"}, {"lodChain", nullptr}});
    CHECK_FALSE(p.exists("assets/models/ball.lod1.glb"));
    CHECK_FALSE(p.exists("assets/models/ball.prefab.json"));
    const Json doc = parse_json(read_all(p.file("assets/models/ball.model.json")), "doc").value();
    CHECK_FALSE(doc.contains("gameReady"));
    // bake:false says the files are bake's
    const Json nb = p.ok("model.generate_lods", {{"model", "assets/models/ball.model.json"}, {"bake", false}});
    CHECK(nb["nextSteps"][0].get<std::string>().find("model.bake") != std::string::npos);
}
