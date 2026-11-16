// Render interpolation through the engine (fa/scene/interpolation.h): the accumulator's alpha reaches the draw pose, the
// real Transform is never touched, and a game that did not ask for it is unchanged.
#include <doctest.h>

#include <cmath>
#include <filesystem>
#include <fstream>
#include <string>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/internal/engine_impl.h"
#include "fa/scene/components.h"
#include "fa/scene/world.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "name": "Camera", "components": { "Camera": {} } },
    { "id": "ball", "name": "Ball",
      "components": { "RigidBody2D": { "gravityScale": 0, "velocity": [300, 0] }, "Collider2D": { "shape": "circle", "radius": 8 } } }
  ]
})";

struct TempProject {
    stdfs::path dir;
    TempProject(const std::string& name, bool interpolation) {
        dir = fs::make_temp_dir("fa_interp_test_" + name).value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary)
            << R"({ "format": "factoria.project/1", "name": "Interp", "id": "com.example.interp",
                    "mainScene": "scenes/main.scene.json", "display": { "width": 320, "height": 180 },
                    "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }, "render": { "interpolation": )"
            << (interpolation ? "true" : "false") << " } }";
        std::ofstream(dir / "scenes" / "main.scene.json", std::ios::binary) << kScene;
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

EngineConfig config(const TempProject& p) {
    EngineConfig c;
    c.projectDir = p.dir.generic_string();
    c.headless = true;
    c.graphics = false;
    c.hotReload = false;
    c.jobThreads = "0";
    return c;
}

}  // namespace

TEST_CASE("render.interpolation: a 2D body at constant speed is drawn in between its steps at 144 fps") {
    TempProject p("body", true);
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(config(p), nullptr, &err), err);
    REQUIRE(e.world().interp().enabled);
    World& w = e.world();
    const Entity ball = w.find_by_id("ball");
    REQUIRE(ball);
    const double dt = 1.0 / 144.0;  // 144 is not a multiple of 60
    double lastDrawn = 0.0;
    int checked = 0;
    for (int f = 0; f < 120; ++f) {
        e.frame(dt);
        const double alpha = e.runtime_impl().interpAlpha;  // what the engine drew with
        const double real = w.get<Transform>(ball)->position.x;
        const double drawn = w.drawn_matrix(ball).translation().x;
        if (f >= 3) {
            // Speed 300 px/s: 5 px per step; the draw is `(1 - alpha)` of a step behind the real pose.
            CHECK(drawn == doctest::Approx(real - 5.0 * (1.0 - alpha)).epsilon(0.001));
            CHECK(drawn - lastDrawn == doctest::Approx(300.0 * dt).epsilon(0.02));  // smooth: every frame moves the same
            ++checked;
        }
        CHECK(w.world_matrix(ball).translation().x == doctest::Approx(real));  // the simulation sees the real pose
        lastDrawn = drawn;
    }
    CHECK(checked > 100);
    e.shutdown();
}

TEST_CASE("render.interpolation: off by default the drawn pose is the Transform; step() never blends") {
    {
        TempProject p("off", false);
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(config(p), nullptr, &err), err);
        World& w = e.world();
        const Entity ball = w.find_by_id("ball");
        for (int f = 0; f < 30; ++f) {
            e.frame(1.0 / 144.0);
            CHECK(w.drawn_matrix(ball).translation().x == w.get<Transform>(ball)->position.x);
        }
        CHECK(w.interp().poseCount == 0);
        e.shutdown();
    }
    TempProject p("step", true);
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(config(p), nullptr, &err), err);
    World& w = e.world();
    const Entity ball = w.find_by_id("ball");
    e.step(10);
    CHECK(w.drawn_matrix(ball).translation().x == w.get<Transform>(ball)->position.x);
    e.shutdown();
}
