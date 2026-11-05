// Game feel (fa/scene/feel.h) through the whole engine: the feel.* commands, hit-stop against the game clock, the effects that
// leave no trace in the scene (shake, squash, flash), knockback and the accessibility switches.
#include <doctest.h>

#include <cmath>
#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Feel Test",
  "id": "com.example.feeltest",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": { "orthoSize": 90 } } },
    { "id": "ball", "components": { "Transform": { "position": [0, 60, 0] },
                                    "Shape2D": { "shape": "circle", "size": [20, 20] },
                                    "RigidBody2D": {}, "Collider2D": { "shape": "circle", "radius": 10 } } },
    { "id": "crate", "components": { "Transform": { "position": [10, 5, 0], "scale": [2, 3, 1] },
                                     "Sprite": { "size": [8, 8], "color": "#336699" } } },
    { "id": "game", "components": { "Script": { "path": "scripts/game.js" } } },
    { "id": "menu", "components": { "Script": { "path": "scripts/menu.js" } } }
  ]
})";

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name) {
        dir = fs::make_temp_dir("fa_feel_test_" + name);
        write("factoria.json", kProject);
        write("scenes/main.scene.json", kScene);
        write("scripts/game.js", "import { Behaviour, time } from 'factoria';\n"
                                 "export default class Game extends Behaviour { updates = 0; dt = -1;\n"
                                 "  onUpdate() { this.updates++; this.dt = time.dt; } }\n");
        write("scripts/menu.js", "import { Behaviour, time } from 'factoria';\n"
                                 "export default class Menu extends Behaviour {\n"
                                 "  runWhilePaused = true; updates = 0; dt = -1; timeDt = -1;\n"
                                 "  onUpdate(dt) { this.updates++; this.dt = dt; this.timeDt = time.dt; } }\n");
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const std::string& rel, const std::string& text) const {
        stdfs::create_directories((dir / rel).parent_path());
        std::ofstream(dir / rel, std::ios::binary) << text;
    }
};

struct Game {
    TempProject p;
    Engine e;
    explicit Game(const std::string& name) : p(name) {
        EngineConfig c;
        c.projectDir = p.dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        std::string err;
        REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    }
    ~Game() { e.shutdown(); }
    double num(const char* code) {
        auto r = e.scripts().eval(code);
        REQUIRE_MESSAGE(r.ok(), code);
        return r.value().get<double>();
    }
    void run(const char* code) {
        auto r = e.scripts().eval(code);
        REQUIRE_MESSAGE(r.ok(), code);
    }
    Json state() {
        auto r = e.commands().call("feel.state", Json::object());
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        return r.result;
    }
    Json entry(const char* id) {
        const Json st = state();
        for (const Json& j : st["entities"])
            if (j["entity"] == id) return j;
        return Json();
    }
    Json call(const char* name, const char* args) {
        auto r = e.commands().call(name, Json::parse(args));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        return r.result;
    }
};

}  // namespace

TEST_CASE("feel commands: documented, closed, and an unknown option is refused with a hint") {
    Game g("commands");
    for (const char* name : {"feel.shake", "feel.hitStop", "feel.flash", "feel.knockback", "feel.squash", "feel.cancel", "feel.settings",
                             "feel.spawn", "feel.sound", "feel.state"}) {
        INFO(name);
        const CommandInfo* info = g.e.commands().info(name);
        REQUIRE(info != nullptr);
        CHECK(info->description.find("Example") != std::string::npos);
        CHECK(info->category == "feel");
        CHECK(info->inputSchema["additionalProperties"] == false);
    }
    CHECK(g.e.commands().info("feel.state")->readOnly);
    CHECK_FALSE(g.e.commands().info("feel.shake")->readOnly);
    // A typo is not silently ignored.
    auto r = g.e.commands().call("feel.shake", Json::parse(R"({"amout":0.5})"));
    CHECK_FALSE(r.ok);
    // Another entity's flash without an entity says what to pass.
    r = g.e.commands().call("feel.flash", Json::object());
    CHECK_FALSE(r.ok);
}

TEST_CASE("hit-stop: freezes gameplay in real time, UI-time code and time.scale keep going, overlapping calls do not add up") {
    Game g("hitstop");
    g.e.step(5);
    const double y0 = g.num("world.find('ball').position.y");
    const double gameUpdates = g.num("world.find('game').behaviour.updates");
    const double menuUpdates = g.num("world.find('menu').behaviour.updates");
    g.run("time.hitStop(0.2)");
    g.e.step(3);
    CHECK(g.num("world.find('ball').position.y") == y0);                          // physics frozen
    CHECK(g.num("world.find('game').behaviour.updates") == gameUpdates);          // gameplay onUpdate stopped
    CHECK(g.num("world.find('menu').behaviour.updates") == menuUpdates + 3);      // runWhilePaused keeps going
    CHECK(g.num("world.find('menu').behaviour.dt") == doctest::Approx(1.0 / 60.0));  // with the real dt
    CHECK(g.num("world.find('menu').behaviour.timeDt") == 0);                     // time.dt is the effective step
    CHECK(g.num("time.scale") == 1);                                              // the user's scale is untouched
    CHECK(g.num("game.paused ? 1 : 0") == 0);
    CHECK(g.num("time.hitStopRemaining") > 0.0);
    g.e.step(20);  // 0.2 s of real time is 12 frames at 60 Hz
    CHECK(g.num("time.hitStopRemaining") == 0);
    CHECK(g.num("world.find('ball').position.y") < y0);                           // running again
    CHECK(g.num("world.find('game').behaviour.updates") > gameUpdates);

    // Calls overlap: the longest wins (not the sum), a shorter one inside it changes nothing.
    g.run("time.hitStop(0.1); time.hitStop(0.2)");
    CHECK(g.num("time.hitStopRemaining") == doctest::Approx(0.2).epsilon(0.001));
    g.run("time.hitStop(0.05)");
    CHECK(g.num("time.hitStopRemaining") == doctest::Approx(0.2).epsilon(0.001));
    CHECK(g.state()["hitStop"]["running"] == 1);
    // A slow-motion stop and a freeze together: the smallest scale applies.
    g.run("feel.cancel(); time.hitStop(0.3, { scale: 0.5 }); time.hitStop(0.1)");
    CHECK(g.state()["hitStop"]["scale"] == 0.0);
    CHECK(g.state()["hitStop"]["running"] == 2);
    // Not a unit mix-up: 90 "seconds" is refused with the fix.
    auto r = g.e.scripts().eval("time.hitStop(90)");
    CHECK_FALSE(r.ok());
    g.run("feel.cancel()");
    CHECK(g.num("time.hitStopRemaining") == 0);
}

TEST_CASE("hit-stop: a pause stays a pause and a hit-stop inside it is harmless") {
    Game g("hitstop_pause");
    g.e.step(2);
    g.run("game.paused = true");
    g.run("time.hitStop(0.1)");
    g.e.step(20);
    CHECK(g.num("time.scale") == 0);
    g.run("game.paused = false");
    CHECK(g.num("time.scale") == 1);
    g.e.step(2);
    CHECK(g.num("world.find('game').behaviour.updates") > 2);
}

TEST_CASE("shake: smooth, deterministic from the RNG, decays to nothing and never touches the camera's Transform") {
    auto run_shake = [](const char* tag) {
        Game g(tag);
        g.e.step(2);
        g.run("camera.shake(0.8, { duration: 0.5 })");
        std::vector<double> xs;
        for (int i = 0; i < 40; ++i) {
            g.e.step(1);
            Json c = g.entry("cam");
            if (!c.is_null() && c.contains("pose")) xs.push_back(c["pose"]["position"][0].get<double>());
            CHECK(g.num("world.find('cam').position.x") == 0);  // the Transform is exactly what the scene says
            CHECK(g.num("world.find('cam').position.y") == 0);
        }
        return xs;
    };
    const std::vector<double> a = run_shake("shake_a");
    const std::vector<double> b = run_shake("shake_b");
    REQUIRE(a.size() >= 20);
    CHECK(a == b);  // the same game, the same shake
    double maxStep = 0, peak = 0;
    for (std::size_t i = 1; i < a.size(); ++i) maxStep = std::max(maxStep, std::fabs(a[i] - a[i - 1]));
    for (double v : a) peak = std::max(peak, std::fabs(v));
    CHECK(peak > 0.5);                       // it moves (maxOffset is 4.5 units for an orthoSize of 90)
    CHECK(peak <= 4.5 * 0.64 + 1e-3);        // never above maxOffset * trauma^2
    CHECK(maxStep < peak * 1.5 + 1.0);       // smooth noise, not white noise
    CHECK(a.size() <= 32);                   // 0.5 s = 30 frames: it died out
}

TEST_CASE("shake: hit-stop does not stop it, trauma stacks to the cap and time.scale 0 holds it") {
    Game g("shake_clock");
    g.run("camera.shake(0.3); camera.shake(0.3); camera.shake(0.9, { cap: 0.6 })");
    CHECK_FALSE(g.entry("cam").contains("pose"));  // the pose is computed at the end of the next frame
    g.e.step(1);
    const double trauma0 = g.entry("cam")["shake"]["trauma"].get<double>();
    CHECK(trauma0 <= 0.6 + 1e-6);
    g.run("time.hitStop(0.3)");
    g.e.step(6);
    CHECK(g.entry("cam")["shake"]["trauma"].get<double>() < trauma0);  // it ran through the freeze
    g.run("feel.cancel(); camera.shake(0.8); time.scale = 0");
    g.e.step(1);
    const double held = g.entry("cam")["shake"]["trauma"].get<double>();
    g.e.step(10);
    CHECK(g.entry("cam")["shake"]["trauma"].get<double>() == held);  // a paused game does not shake
}

TEST_CASE("squash: keeps the volume, springs back and leaves the exact scale") {
    Game g("squash");
    g.e.step(1);
    g.run("world.find('crate').squash({ amount: 0.4, duration: 0.25 })");
    double minY = 10, maxY = 0;
    for (int i = 0; i < 30; ++i) {
        g.e.step(1);
        Json c = g.entry("crate");
        if (c.is_null() || !c.contains("pose")) continue;
        const Json s = c["pose"]["scale"];
        CHECK(s[0].get<double>() * s[1].get<double>() == doctest::Approx(1.0).epsilon(1e-4));  // x * y stays constant in 2D
        minY = std::min(minY, s[1].get<double>());
        maxY = std::max(maxY, s[1].get<double>());
        CHECK(g.num("world.find('crate').transform.scale.x") == 2);  // the entity's own scale is never written
        CHECK(g.num("world.find('crate').transform.scale.y") == 3);
    }
    CHECK(minY < 0.8);  // it squashed ...
    CHECK(maxY > 1.0);  // ... and overshot the other way on the spring back
    CHECK(g.entry("crate").is_null());  // nothing left: the record and the pose are gone
    CHECK(g.num("world.find('crate').transform.scale.x") == 2);
    CHECK(g.num("world.find('crate').transform.scale.y") == 3);
    CHECK(g.num("world.find('crate').transform.scale.z") == 1);
}

TEST_CASE("flash: restores the colour, fades, and a cancel ends it at once") {
    Game g("flash");
    g.e.step(1);
    g.run("world.find('crate').flash({ color: '#ffffff', duration: 0.2 })");
    Json f = g.entry("crate");
    REQUIRE(f.contains("flash"));
    CHECK(f["flash"]["strength"] == 1.0);
    CHECK(f["flash"]["fade"] == true);
    g.e.step(4);
    CHECK(g.entry("crate")["flash"]["remaining"].get<double>() < 0.2);
    CHECK(g.num("world.find('crate').get('Sprite').color.r") == doctest::Approx(0x33 / 255.0).epsilon(0.01));  // own colour kept
    g.e.step(20);
    CHECK(g.entry("crate").is_null());
    CHECK(g.num("world.find('crate').get('Sprite').color.r") == doctest::Approx(0x33 / 255.0).epsilon(0.01));
    g.run("world.find('crate').flash({ duration: 5 }); feel.cancel(world.find('crate'))");
    CHECK(g.entry("crate").is_null());
    // Dies with its entity: no record outlives it.
    g.run("world.find('crate').flash({ duration: 5 }); world.find('crate').destroy()");
    g.e.step(2);
    CHECK(g.entry("crate").is_null());
}

TEST_CASE("knockback: an impulse on a dynamic body, a decaying slide without one, and isKnockedBack for the lock time") {
    Game g("knockback");
    g.e.step(1);
    // With a body: the velocity changes, the lock flag follows lockTime.
    g.run("world.find('ball').knockback(vec2(1, 0), { speed: 300, lockTime: 0.2 })");
    CHECK(g.num("world.find('ball').isKnockedBack ? 1 : 0") == 1);
    CHECK(g.num("world.find('ball').knockbackRemaining") == doctest::Approx(0.2).epsilon(0.01));
    const double x0 = g.num("world.find('ball').position.x");
    g.e.step(6);
    CHECK(g.num("world.find('ball').position.x") > x0 + 1.0);
    g.e.step(10);
    CHECK(g.num("world.find('ball').isKnockedBack ? 1 : 0") == 0);
    // Without a body: it slides and slows, stops, and a hit-stop holds it.
    const double c0 = g.num("world.find('crate').position.x");
    g.run("world.find('crate').knockback([-1, 0], { speed: 40, lockTime: 0.3, decay: 6 })");
    g.e.step(6);
    const double c1 = g.num("world.find('crate').position.x");
    CHECK(c1 < c0 - 1.0);
    g.run("time.hitStop(0.2)");
    g.e.step(4);
    CHECK(g.num("world.find('crate').position.x") == c1);  // frozen with the simulation
    CHECK(g.num("world.find('crate').isKnockedBack ? 1 : 0") == 1);
    g.e.step(240);  // exp(-6 t) takes the 40 units/s under the 0.01 cut-off after about 1.4 s
    const double c2 = g.num("world.find('crate').position.x");
    g.e.step(10);
    CHECK(g.num("world.find('crate').position.x") == c2);  // it came to rest
    CHECK(g.num("world.find('crate').isKnockedBack ? 1 : 0") == 0);
    CHECK(g.num("world.find('crate').knockbackRemaining") == 0);
    // No direction: the error says what to pass.
    CHECK_FALSE(g.e.scripts().eval("world.find('crate').knockback([0, 0])").ok());
}

TEST_CASE("accessibility: reduceMotion shrinks shake and squash and shortens hit-stop, reducedEffects softens the flash") {
    Game g("a11y");
    g.e.step(1);
    CHECK(g.num("feel.reduceMotion ? 1 : 0") == 0);
    g.run("feel.reduceMotion = true");
    CHECK(g.num("feel.reduceMotion ? 1 : 0") == 1);
    g.run("camera.shake(0.8)");
    g.e.step(1);
    CHECK(g.entry("cam")["shake"]["trauma"].get<double>() <= 0.8 * 0.25 + 1e-6);
    g.run("world.find('crate').squash({ amount: 0.4 })");
    g.e.step(1);
    CHECK(std::fabs(g.entry("crate")["squash"]["amount"].get<double>()) <= 0.4 * 0.25 + 1e-6);
    g.run("feel.cancel(); time.hitStop(0.2)");
    CHECK(g.num("time.hitStopRemaining") == doctest::Approx(0.1).epsilon(0.001));
    // reduceMotion does not touch the flash (that is reducedEffects) ...
    g.run("feel.cancel(); world.find('crate').flash({ fade: false })");
    CHECK(g.entry("crate")["flash"]["strength"] == 1.0);
    // ... but the reduced flash is faint and always fading, the square wave is gone.
    g.run("feel.reducedEffects = true; world.find('crate').flash({ fade: false })");
    CHECK(g.entry("crate")["flash"]["strength"].get<double>() <= 0.35 + 1e-6);
    CHECK(g.entry("crate")["flash"]["fade"] == true);
    // The game's choice can go back to following the system (false here: the headless system value).
    g.run("feel.reduceMotion = null; feel.reducedEffects = null");
    CHECK(g.num("feel.reduceMotion ? 1 : 0") == 0);
    CHECK(g.num("feel.reducedEffects ? 1 : 0") == 0);
    // Through the command as well.
    Json s = g.call("feel.settings", R"({"reduceMotion":true})");
    CHECK(s["reduceMotion"] == true);
    CHECK(s["reducedEffects"] == false);
}

TEST_CASE("feel commands run the effects, and a scene load drops them but keeps the player's accessibility choice") {
    Game g("scene_load");
    g.call("feel.settings", R"({"reduceMotion":true})");
    g.call("feel.flash", R"({"entity":"crate","color":[1,0,0,1],"duration":5})");
    g.call("feel.squash", R"({"entity":"crate","amount":0.3})");
    g.call("feel.knockback", R"({"entity":"ball","direction":[1,0],"speed":50})");
    g.call("feel.hitStop", R"({"duration":1})");
    g.call("feel.shake", R"({"amount":0.5})");
    g.e.step(1);
    CHECK(g.state()["entities"].size() == 3);  // crate, ball, camera
    g.call("scene.load", R"({"path":"scenes/main.scene.json"})");
    g.e.step(2);
    CHECK(g.state()["entities"].empty());
    CHECK(g.state()["hitStop"]["running"] == 0);
    CHECK(g.state()["reduceMotion"] == true);
}

TEST_CASE("feel.spawn and feel.sound: queued for the frame, a spawn appears at the entity and ends with its lifetime") {
    Game g("spawn_sound");
    g.p.write("prefabs/spark.prefab.json", R"({"format":"factoria.prefab/1","entity":{"id":"spark","components":{"Transform":{}}}})");
    g.e.step(1);
    g.call("feel.spawn", R"({"entity":"crate","prefab":"prefabs/spark.prefab.json","offset":[1,2],"lifetime":0.2})");
    CHECK(g.state()["queued"]["spawns"] == 1);
    CHECK(g.num("world.find('spark') ? 1 : 0") == 0);  // not inside the call: the frame's feel pass makes it
    g.e.step(1);
    REQUIRE(g.num("world.find('spark') ? 1 : 0") == 1);
    CHECK(g.num("world.find('spark').position.x") == doctest::Approx(11.0));
    CHECK(g.num("world.find('spark').position.y") == doctest::Approx(7.0));
    CHECK(g.state()["queued"]["spawnLifetimes"] == 1);
    g.e.step(30);  // 0.5 s
    CHECK(g.num("world.find('spark') ? 1 : 0") == 0);
    CHECK(g.state()["queued"]["spawnLifetimes"] == 0);

    // a wrong option is refused with the option names; a good sound waits for the audio update
    auto bad = g.e.commands().call("feel.sound", Json::parse(R"({"path":"audio/hit.wav","volum":0.5})"));
    CHECK_FALSE(bad.ok);
    auto bad2 = g.e.commands().call("feel.spawn", Json::parse(R"({"offset":[0,0]})"));
    CHECK_FALSE(bad2.ok);
    g.call("feel.sound", R"({"path":"audio/hit.wav","volume":0.5})");
    CHECK(g.state()["queued"]["sounds"] == 1);
}
