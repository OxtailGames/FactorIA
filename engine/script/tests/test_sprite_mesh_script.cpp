// Scripts drive the deformable sprite, Sprite.skew, Tint and Shape2D gradient stops through the component views.
#include <doctest.h>

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

TEST_CASE("scripts: vertexOffsets, skew, Tint and gradientStops are written through the component views") {
    TestHost h("sprite_mesh_script");
    h.file("scenes/main.scene.json", Json::object({{"format", "factoria.scene/1"}, {"entities", Json::array({
        Json::parse(R"({"id":"page","components":{"Transform":{"position":[0,0,0]},
            "Sprite":{"size":[80,40],"meshColumns":4,"meshRows":1}, "Tint":{"color":[1,1,1,1]},
            "Shape2D":{"size":[10,10],"gradient":"linear"}}})")})}}).dump());
    REQUIRE(h.start());
    CHECK(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(1);
    CHECK(eval_ok(h, "world.find('page').get('Sprite').meshColumns").get<int>() == 4);
    CHECK(eval_ok(h, "const p = world.find('page'); const o = []; for (let i = 0; i < 10; ++i) { o.push(0); o.push(i * 2); } "
                     "p.get('Sprite').vertexOffsets = o; p.get('Sprite').vertexOffsets.length").get<int>() == 20);
    CHECK(eval_ok(h, "world.find('page').get('Sprite').vertexOffsets[3]").get<double>() == doctest::Approx(2.0));
    CHECK(eval_ok(h, "const s = world.find('page').get('Sprite'); s.skew.x = 15; s.skew.x").get<double>() == doctest::Approx(15.0));
    CHECK(eval_ok(h, "const t = world.find('page').get('Tint'); t.color.a = 0.25; t.color.a").get<double>() == doctest::Approx(0.25));
    CHECK(eval_ok(h, "const g = world.find('page').get('Shape2D'); g.gradientEase = 'cubicInOut'; "
                     "g.gradientStops = [[0, '#ff0000'], [0.5, [0, 1, 0, 1]], [1, '#0000ff']]; g.gradientStops.length").get<int>() == 3);
    CHECK(eval_ok(h, "world.find('page').get('Shape2D').gradientEase") == "cubicInOut");
    // bounds follow the offsets: the top row (y = +20) moved up by 0..8, the bottom row (y = -20) by 10..18: -10 .. 28
    CHECK(eval_ok(h, "world.find('page').bounds().h").get<double>() == doctest::Approx(38.0));
}
