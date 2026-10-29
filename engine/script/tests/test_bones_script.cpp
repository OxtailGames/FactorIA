// Scripts pose bones and read skins through the component views; debug.bones() takes an entity or nothing.
#include <doctest.h>

#include "fa/scene/bones2d.h"
#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {
Json eval_ok(TestHost& h, const char* code) {
    auto r = h.scripts.eval(code);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    return r.value();
}
}  // namespace

TEST_CASE("scripts: Bone2D, SpriteSkin and IK2D are components like the others; debug.bones() is checked") {
    TestHost h("bones_script");
    h.file("scenes/main.scene.json", Json::object({{"format", "factoria.scene/1"}, {"entities", Json::array({
        Json::parse(R"({"id":"arm","components":{"Sprite":{"size":[80,20],"meshColumns":8,"meshRows":2},
            "SpriteSkin":{"bones":["b0","b1"]}}, "children":[
              {"id":"b0","components":{"Transform":{"position":[-40,0,0]},"Bone2D":{"length":40}}, "children":[
                {"id":"b1","components":{"Transform":{"position":[40,0,0]},"Bone2D":{"length":40,"minAngle":-10,"maxAngle":120},
                  "IK2D":{"target":"goal","bend":"negative","solver":"twoBone"}}}]}]})"),
        Json::parse(R"({"id":"goal","components":{"Transform":{"position":[20,30,0]}}})")})}}).dump());
    REQUIRE(h.start());
    CHECK(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(1);
    bind_pending_skins(h.w);  // the engine does this when a scene loads; this host has no engine
    CHECK(eval_ok(h, "world.find('b1').get('Bone2D').maxAngle").get<double>() == doctest::Approx(120.0));
    CHECK(eval_ok(h, "world.find('b1').get('IK2D').bend") == "negative");
    CHECK(eval_ok(h, "world.find('b1').get('IK2D').target.id") == "goal");
    CHECK(eval_ok(h, "world.find('arm').get('SpriteSkin').bones.length").get<int>() == 2);
    // A script poses a bone: the footprint of the skinned sprite follows it (bound above, at the authored pose).
    CHECK(eval_ok(h, "world.find('arm').bounds().h").get<double>() == doctest::Approx(20.0).epsilon(0.01));
    CHECK(eval_ok(h, "world.find('b1').transform.rotation = [0, 0, 90]; world.find('arm').bounds().h").get<double>() > 40.0);
    // debug.bones: an entity or nothing; with no renderer in this host it draws nothing, and it never throws for those.
    eval_ok(h, "debug.bones(); debug.bones(world.find('b0')); debug.bones(world.find('b0'), [1, 0, 0, 1])");
    auto bad = h.scripts.eval("debug.bones('b0')");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().to_string().find("must be an entity") != std::string::npos);
}
