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
#include "fa/scene/camera_geometry.h"
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

// A looping animator, one that ends, an emitter that bursts once and is destroyed when its particles are gone, and one that waits for a
// burst; a Parallax layer behind a camera that the test moves; and a panel that fits a button and a label whose size comes from the
// text shaping (Latin, Japanese, wrapped), which a run with no renderer measures on the CPU.
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
                                           "speed": 30, "seed": 5 } } },
    { "id": "sky", "name": "Sky",
      "components": { "Sprite": { "texture": "assets/sheet.png" }, "Parallax": { "factor": [0.25, 0.5] } } },
    { "id": "menu", "name": "Menu",
      "components": { "Panel": { "layout": "column", "fit": true, "spacing": 6 } },
      "children": [
        { "id": "play", "components": { "Button": { "text": "Play the game", "autoSize": true, "maxWidth": 90 } } },
        { "id": "jp", "components": { "Button": { "text": "\u65e5\u672c\u8a9e\u306e\u9577\u3044\u6587\u7ae0", "autoSize": true, "maxWidth": 80 } } },
        { "id": "label", "components": { "Text": { "text": "Score: 12345", "space": "screen", "fontSize": 24 } } }
      ] }
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
    Vec2 panelSize[2];
    for (int mode = 0; mode < 2; ++mode) {
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(config(p, mode == 1), nullptr, &err), err);
        if (mode == 1 && e.renderer() == nullptr) {  // no GPU on this runner: graphics=true fell back to no graphics
            MESSAGE("no GPU here: the comparison with a renderer that draws runs on the CI runners that have one");
            e.shutdown();
            return;
        }
        CHECK((e.renderer() != nullptr) == (mode == 1));
        const Entity cam = e.world().find_by_id("cam");
        REQUIRE(cam);
        for (int i = 0; i < 70; ++i) {
            e.world().get<Transform>(cam)->position.x = 2.0f * float(i);  // a moving camera: the Parallax layer follows it
            e.frame(1.0 / 60.0);  // simulates one fixed step and, with a renderer, draws it
            hashes[mode].push_back(state_hash_hex(world_state_hash(e.world()).hash));
            particles[mode].push_back(e.world().particles().particle_count());
        }
        // The things a renderer used to measure: the parallax offset follows the camera, the panel was fitted to the shaped text.
        const Parallax* sky = e.world().get<Parallax>(e.world().find_by_id("sky"));
        const Panel* menu = e.world().get<Panel>(e.world().find_by_id("menu"));
        REQUIRE(sky);
        REQUIRE(menu);
        CHECK(sky->offset.x != 0.0f);
        panelSize[mode] = menu->size;
        e.shutdown();
    }
    REQUIRE(hashes[0].size() == hashes[1].size());
    CHECK(hashes[0].front() != hashes[0].back());
    CHECK(hashes[0] == hashes[1]);
    CHECK(particles[0] == particles[1]);
    CHECK(panelSize[0].x == panelSize[1].x);
    CHECK(panelSize[0].y == panelSize[1].y);
    CHECK(panelSize[0].x > 0.0f);
    CHECK(particles[0][1] > 0);
    CHECK(particles[0].back() == 0);
}

TEST_CASE("sim: the camera queries of a script answer right after a load, before any frame has ended") {
    TempProject p("camfirst");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(config(p, false), nullptr, &err), err);
    REQUIRE(e.renderer() == nullptr);
    // The loaded scene's camera is in the set already (a script's onStart runs before the first frame ends).
    REQUIRE(e.camera_set() != nullptr);
    REQUIRE_FALSE(e.camera_set()->all().empty());
    const char* code = "JSON.stringify([camera.worldToScreen([10, 20, 0]), camera.screenToWorld([200, 50]), camera.screenRay([200, 50])])";
    auto before = e.commands().call("script.eval", Json::object({{"code", code}}));
    REQUIRE_MESSAGE(before.ok, before.error.dump());
    e.step(1);
    auto after = e.commands().call("script.eval", Json::object({{"code", code}}));
    REQUIRE(after.ok);
    CHECK(before.result == after.result);
    // The default camera shows the design height (180 units) over 180 pixels: 10 units right of the origin is 10 pixels right of the centre.
    auto point = e.commands().call("script.eval", Json::object({{"code", "camera.worldToScreen([10, 0, 0])"}}));
    REQUIRE(point.ok);
    CHECK(point.result["value"][0].get<double>() == doctest::Approx(170.0).epsilon(0.01));
    CHECK(point.result["value"][1].get<double>() == doctest::Approx(90.0).epsilon(0.01));
    e.shutdown();
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
    CHECK(only.result["components"].get<int>() == 5);  // Sprite + SpriteAnimator on two entities, and the Sprite of the Parallax layer
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
