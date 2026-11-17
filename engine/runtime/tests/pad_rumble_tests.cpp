// Pad rumble with a real Engine: a request ends by itself on the engine's clock (game.step), and the engine stops every pad
// when the game pauses (game.paused, the editor's pause), at a scene change and at quit. The hardware layer is not here (a
// headless run has none): this reads Input, which it is copied from (docs/SCRIPTING.md, "Pad rumble").
#include <filesystem>
#include <string>

#include "doctest.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct RumbleProject {
    stdfs::path dir = fs::make_temp_dir("fa_pad_rumble").value();
    RumbleProject() {
        write("factoria.json", R"({"format":"factoria.project/1","name":"Rumble","id":"com.example.rumble",
                                   "mainScene":"main.scene.json","display":{"width":64,"height":64},"physics":{"fixedHz":60}})");
        write("main.scene.json",
              R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}}]})");
        write("other.scene.json",
              R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}}]})");
    }
    ~RumbleProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const char* rel, const char* text) const {
        stdfs::create_directories((dir / rel).parent_path());
        REQUIRE(fs::write_text((dir / rel).generic_string(), text).ok());
    }
    EngineConfig config() const {
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        c.memoryStorage = true;
        return c;
    }
};

}  // namespace

TEST_CASE("pad rumble: it ends on the engine clock, and pause, a scene change and quit stop it") {
    RumbleProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    Input& in = e.input();
    in.on_gamepad_connected(0, true);
    e.step(1);

    SUBCASE("a request of half a second ends after 30 frames of 1/60 s, not before") {
        in.rumble({0, 0.5f, 0.5f, 0.5f});
        e.step(20);
        CHECK(in.rumble_state(0).active());
        CHECK(in.rumble_state(0).remaining == doctest::Approx(0.5f - 20.0f / 60.0f).epsilon(0.01));
        e.step(11);
        CHECK_FALSE(in.rumble_state(0).active());
    }
    SUBCASE("a request shorter than a frame is still there when the frame ends, and gone at the start of the next") {
        in.rumble({0, 1.0f, 1.0f, 0.01f});
        CHECK(in.rumble_state(0).active());  // what the window copies to the hardware after the frame it was asked in
        e.step(1);
        CHECK_FALSE(in.rumble_state(0).active());
    }
    SUBCASE("the editor's pause stops it, and a request while paused still ends by itself") {
        in.rumble({0, 0.5f, 0.5f, 5.0f});
        e.set_paused(true);
        CHECK_FALSE(in.rumble_state(0).active());
        in.rumble({0, 0.5f, 0.5f, 0.1f});
        for (int i = 0; i < 10; ++i) e.frame(1.0 / 60.0);  // paused frames: the engine clock still runs
        CHECK_FALSE(in.rumble_state(0).active());
    }
    SUBCASE("a scene change stops it") {
        in.rumble({0, 0.5f, 0.5f, 5.0f});
        std::string loadErr;
        REQUIRE_MESSAGE(e.load_scene("other.scene.json", &loadErr), loadErr);
        CHECK_FALSE(in.rumble_state(0).active());
    }
    SUBCASE("quit (shutdown) stops it") {
        in.rumble({0, 0.5f, 0.5f, 5.0f});
        e.shutdown();
        CHECK_FALSE(in.rumble_state(0).active());
    }
    e.shutdown();
}

TEST_CASE("pad rumble: a request of the frame that pauses the game never stays; one of a frame that does not does") {
    RumbleProject p;
    p.write("scripts/pauser.js", R"JS(
import { Behaviour, input, time } from "factoria";
export default class Pauser extends Behaviour {
  fired = false;
  onUpdate() {
    if (this.fired) return;
    this.fired = true;
    input.rumble(0, 1, 1, 5);
    time.scale = 0;                 // the same frame: no buzz of one frame
  }
}
)JS");
    p.write("scripts/rumbler.js", R"JS(
import { Behaviour, input } from "factoria";
export default class Rumbler extends Behaviour {
  fired = false;
  onUpdate() {
    if (this.fired) return;
    this.fired = true;
    input.rumble(0, 1, 1, 5);
  }
}
)JS");
    p.write("pause.scene.json", R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}},
        {"id":"p","components":{"Transform":{},"Script":{"path":"scripts/pauser.js"}}}]})");
    p.write("play.scene.json", R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}},
        {"id":"p","components":{"Transform":{},"Script":{"path":"scripts/rumbler.js"}}}]})");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    Input& in = e.input();

    std::string loadErr;
    REQUIRE_MESSAGE(e.load_scene("play.scene.json", &loadErr), loadErr);
    in.on_gamepad_connected(0, true);
    bool played = false;
    for (int i = 0; i < 4; ++i) {
        e.step(1);
        played = played || in.rumble_state(0).active();
    }
    CHECK(played);  // the control: without the pause the request is there when the frame ends

    REQUIRE_MESSAGE(e.load_scene("pause.scene.json", &loadErr), loadErr);
    in.on_gamepad_connected(0, true);
    for (int i = 0; i < 4; ++i) {
        e.step(1);
        INFO("after frame " << i);
        CHECK_FALSE(in.rumble_state(0).active());  // never seen, not even at the end of the frame that asked
    }
    e.shutdown();
}

TEST_CASE("pad rumble: a pause and a rumble of one frame cancel out in onLateUpdate too, in either order") {
    RumbleProject p;
    p.write("scripts/late_rumble.js", R"JS(
import { Behaviour, input, time } from "factoria";
export default class LateRumble extends Behaviour {
  runWhilePaused = true;            // its onLateUpdate runs in the frame that paused the game, after onUpdate did
  fired = false;
  onUpdate() {
    if (this.fired) return;
    this.fired = true;
    time.scale = 0;                 // paused in onUpdate...
  }
  onLateUpdate() {
    if (this.fired && !this.sent) {
      this.sent = true;
      input.rumble(0, 1, 1, 5);     // ...and the rumble comes after it, in the same frame
    }
  }
}
)JS");
    p.write("scripts/late_pause.js", R"JS(
import { Behaviour, input, time } from "factoria";
export default class LatePause extends Behaviour {
  fired = false;
  onUpdate() {
    if (this.fired) return;
    this.fired = true;
    input.rumble(0, 1, 1, 5);       // rumbled in onUpdate...
  }
  onLateUpdate() {
    if (this.fired && !this.paused) {
      this.paused = true;
      time.scale = 0;               // ...and paused after it, in the same frame
    }
  }
}
)JS");
    p.write("scripts/late_control.js", R"JS(
import { Behaviour, input } from "factoria";
export default class LateControl extends Behaviour {
  sent = false;
  onLateUpdate() {
    if (this.sent) return;
    this.sent = true;
    input.rumble(0, 1, 1, 5);       // no pause: this one must play
  }
}
)JS");
    p.write("late_control.scene.json",
            R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}},
        {"id":"p","components":{"Transform":{},"Script":{"path":"scripts/late_control.js"}}}]})");
    p.write("late_rumble.scene.json",
            R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}},
        {"id":"p","components":{"Transform":{},"Script":{"path":"scripts/late_rumble.js"}}}]})");
    p.write("late_pause.scene.json",
            R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}},
        {"id":"p","components":{"Transform":{},"Script":{"path":"scripts/late_pause.js"}}}]})");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    Input& in = e.input();
    {
        std::string loadErr;
        REQUIRE_MESSAGE(e.load_scene("late_control.scene.json", &loadErr), loadErr);
        in.on_gamepad_connected(0, true);
        bool played = false;
        for (int i = 0; i < 4; ++i) {
            e.step(1);
            played = played || in.rumble_state(0).active();
        }
        CHECK(played);  // the control: onLateUpdate's request is there when the frame ends
    }
    for (const char* scene : {"late_rumble.scene.json", "late_pause.scene.json"}) {
        std::string loadErr;
        REQUIRE_MESSAGE(e.load_scene(scene, &loadErr), loadErr);
        in.on_gamepad_connected(0, true);
        for (int i = 0; i < 4; ++i) {
            e.step(1);
            INFO(scene << ", after frame " << i);
            CHECK_FALSE(in.rumble_state(0).active());  // not even at the end of the frame that asked
        }
    }
    e.shutdown();
}

TEST_CASE("pad rumble: game.paused stops it once; the game's own requests while paused play on") {
    RumbleProject p;
    p.write("tests/pause.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { input } from "factoria";
test("a pad stops when the game pauses and not again for a request made while paused", () => {
  game.gamepad(0).connect({ canRumble: true });
  game.step(1);
  input.rumble(0, 0.5, 0.5, 5);
  game.step(2);
  expect(game.rumbleState(0).seconds).toBeGreaterThan(4.9);
  game.paused = true;
  game.step(1);
  expect(game.rumbleState(0).seconds).toBe(0);
  input.rumble(0, 0.5, 0.5, 5);                 // a menu click while paused: it plays
  game.step(3);
  expect(game.rumbleState(0).seconds).toBeGreaterThan(4.9);
  game.paused = false;
  game.step(1);
  expect(game.rumbleState(0).seconds).toBeGreaterThan(4.8);
});
test("a scene change stops it", () => {
  game.gamepad(0).connect({ canRumble: true });
  input.rumble(0, 0.5, 0.5, 5);
  game.load("other.scene.json");
  expect(game.rumbleState(0).seconds).toBe(0);
});
)JS");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    TestReport rep = e.scripts().run_tests({"tests/pause.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    e.shutdown();
}
