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
        write("main.scene.json", R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}}]})");
        write("other.scene.json", R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}}]})");
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
