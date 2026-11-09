// SpriteAnimator and ParticleEmitter advance in the fixed simulation step, whatever the renderer (docs/ARCHITECTURE.md, "Animation"):
// a run with graphics=false moves them like a run that draws, and the world state is the same frame by frame.
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/runtime/engine.h"
#include "fa/scene/components.h"
#include "fa/scene/particle_store.h"
#include "fa/scene/state_hash.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1", "name": "Sim Test", "id": "com.example.simtest",
  "mainScene": "scenes/main.scene.json", "display": { "width": 320, "height": 180 },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

// A looping animator, one that ends, an emitter that bursts once and is destroyed when its particles are gone, and one that waits for a burst.
const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "name": "Camera", "components": { "Camera": {} } },
    { "id": "spin", "name": "Spin",
      "components": { "Sprite": { "texture": "assets/sheet.png" },
                      "SpriteAnimator": { "columns": 4, "rows": 1, "lastFrame": 3, "fps": 12, "loop": true } } },
    { "id": "once", "name": "Once",
      "components": { "Sprite": { "texture": "assets/sheet.png" },
                      "SpriteAnimator": { "columns": 4, "rows": 1, "lastFrame": 3, "fps": 12, "loop": false } } },
    { "id": "puff", "name": "Puff",
      "components": { "Transform": { "position": [20, 0, 0] },
                      "ParticleEmitter": { "emitting": false, "rate": 0, "burst": 20, "lifetime": 0.5, "lifetimeVariance": 0,
                                           "speed": 30, "autoDestroy": true, "seed": 3 } } },
    { "id": "wait", "name": "Wait",
      "components": { "Transform": { "position": [-20, 0, 0] },
                      "ParticleEmitter": { "emitting": false, "rate": 0, "burst": 0, "lifetime": 0.5, "lifetimeVariance": 0,
                                           "speed": 30, "seed": 5 } } }
  ]
})";

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name) {
        dir = fs::make_temp_dir("fa_sim_test_" + name);
        stdfs::create_directories(dir / "scenes");
        stdfs::create_directories(dir / "assets");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scenes" / "main.scene.json", std::ios::binary) << kScene;
        Image sheet;  // 4 frames of 8x8 in a row
        sheet.width = 32;
        sheet.height = 8;
        sheet.rgba.resize(32 * 8 * 4);
        for (int y = 0; y < 8; ++y)
            for (int x = 0; x < 32; ++x) sheet.set_pixel(x, y, Color::hex(0x204060 + 0x303030 * unsigned(x / 8)));
        REQUIRE(save_png(sheet, (dir / "assets" / "sheet.png").generic_string()).ok());
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

EngineConfig config(const TempProject& p, bool graphics) {
    EngineConfig c;
    c.projectDir = p.dir.generic_string();
    c.headless = true;
    c.graphics = graphics;
    c.hotReload = false;
    c.jobThreads = "0";
    return c;
}

}  // namespace

TEST_CASE("sim: with graphics=false the animators advance, a clip ends and a finished emitter destroys itself") {
    TempProject p("nogfx");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(config(p, false), nullptr, &err), err);
    REQUIRE(e.renderer() == nullptr);
    World& w = e.world();
    const Entity spin = w.find_by_id("spin"), once = w.find_by_id("once");
    REQUIRE(spin);
    REQUIRE(once);
    e.step(1);
    // The first step drew frame 0: its cell of the sheet (8x8 in a 32x8 texture) is the sprite's region.
    CHECK(w.get<Sprite>(spin)->region.x == doctest::Approx(0.0f));
    CHECK(w.get<Sprite>(spin)->region.w == doctest::Approx(8.0f));
    CHECK(w.get<Sprite>(spin)->region.h == doctest::Approx(8.0f));
    e.step(10);  // 11/60 s at 12 fps: frame 2
    CHECK(w.get<SpriteAnimator>(spin)->frame == 2);
    CHECK(w.get<Sprite>(spin)->region.x == doctest::Approx(16.0f));
    e.step(60);  // looped round again
    CHECK(w.get<SpriteAnimator>(spin)->frame >= 0);
    CHECK(w.get<SpriteAnimator>(spin)->frame <= 3);
    CHECK_FALSE(w.get<SpriteAnimator>(spin)->ended);
    // The one that does not loop stopped on its last frame and reported it.
    CHECK(w.get<SpriteAnimator>(once)->ended);
    CHECK(w.get<SpriteAnimator>(once)->frame == 3);
    CHECK(w.get<Sprite>(once)->region.x == doctest::Approx(24.0f));
    // The emitter that bursts once: its particles were born at once and it was destroyed when the last one died (0.5 s lifetime).
    CHECK_FALSE(w.find_by_id("puff"));
    CHECK(w.find_by_id("wait"));
    e.shutdown();
}

TEST_CASE("sim: a burst queued on a world is born in the next step without a renderer, and two worlds do not share emitters") {
    TempProject p("burst");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(config(p, false), nullptr, &err), err);
    World& w = e.world();
    const Entity wait = w.find_by_id("wait");
    REQUIRE(wait);
    e.step(1);
    CHECK(w.particles().particle_count() == 20);  // puff's burst
    w.particles().queue_burst(w, wait, 7);
    e.step(1);
    CHECK(w.particles().particle_count() == 27);
    const ParticleEmitterState* st = w.particles().find(wait);
    REQUIRE(st);
    CHECK(st->sim.particles.size() == 7);
    // Another world whose entity has the very same bits: nothing of the first one's particles is in it.
    World other;
    const Entity same = other.create("wait");
    other.add<ParticleEmitter>(same);
    CHECK(other.particles().particle_count() == 0);
    CHECK(other.particles().find(same) == nullptr);
    e.shutdown();
}

TEST_CASE("sim: the world state is the same frame by frame with a renderer that draws and with graphics=false") {
    TempProject p("same");
    std::vector<std::string> hashes[2];
    std::vector<std::size_t> particles[2];
    for (int mode = 0; mode < 2; ++mode) {
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(config(p, mode == 1), nullptr, &err), err);
        CHECK((e.renderer() != nullptr) == (mode == 1));
        for (int i = 0; i < 70; ++i) {
            e.frame(1.0 / 60.0);  // simulates one fixed step and, with a renderer, draws it
            hashes[mode].push_back(state_hash_hex(world_state_hash(e.world()).hash));
            particles[mode].push_back(e.world().particles().particle_count());
        }
        e.shutdown();
    }
    REQUIRE(hashes[0].size() == hashes[1].size());
    CHECK(hashes[0].front() != hashes[0].back());
    CHECK(hashes[0] == hashes[1]);
    CHECK(particles[0] == particles[1]);
    CHECK(particles[0][1] > 0);
    CHECK(particles[0].back() == 0);
}

TEST_CASE("game.state_hash components: hashes only the named component types and names a mistyped one") {
    TempProject p("hashfilter");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(config(p, false), nullptr, &err), err);
    e.step(5);
    auto only = e.commands().call("game.state_hash", Json::parse(R"({"components":["SpriteAnimator","Sprite"]})"));
    REQUIRE_MESSAGE(only.ok, only.error.dump());
    auto whole = e.commands().call("game.state_hash", Json::object());
    REQUIRE(whole.ok);
    CHECK(only.result["hash"] != whole.result["hash"]);
    CHECK(only.result["components"].get<int>() == 4);  // Sprite + SpriteAnimator on two entities
    // The other components are not part of it: moving an entity that has none of these changes nothing.
    Transform* t = e.world().get<Transform>(e.world().find_by_id("wait"));
    REQUIRE(t);
    t->position.x += 1.0f;
    auto after = e.commands().call("game.state_hash", Json::parse(R"({"components":["SpriteAnimator","Sprite"]})"));
    REQUIRE(after.ok);
    CHECK(after.result["hash"] == only.result["hash"]);
    auto typo = e.commands().call("game.state_hash", Json::parse(R"({"components":["Sprit"]})"));
    REQUIRE_FALSE(typo.ok);
    CHECK(typo.error["message"].get<std::string>().find("/components/0") != std::string::npos);
    CHECK(typo.error["hint"].get<std::string>().find("Sprite") != std::string::npos);
    e.shutdown();
}
