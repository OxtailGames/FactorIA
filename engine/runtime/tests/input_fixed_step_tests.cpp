// A press or a release reaches exactly one onFixedUpdate and exactly one onUpdate, however many fixed steps (0 to 5) the frame
// that carries it runs (docs/SCRIPTING.md, "Which callback sees what"; fa/platform/input.h, "TWO VIEWS").
#include <filesystem>
#include <map>
#include <string>

#include "doctest.h"
#include "fa/core/fs.h"
#include "fa/core/json.h"
#include "fa/runtime/engine.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

constexpr double kFixedDt = 1.0 / 60.0;

// One entity per kind of input. Each counts, in its position: x = what onFixedUpdate saw (summed), y = what onUpdate saw, z = what
// onFixedUpdate saw of the release. "press" is an expression that is a number or a boolean; "release" likewise.
struct Counter {
    const char* id;
    const char* press;
    const char* release;
};

const Counter kCounters[] = {
    {"key", "input.keyPressed('Space')", "input.keyReleased('Space')"},
    {"action", "input.pressed('jump')", "input.released('jump')"},
    {"mouse", "input.mouse.pressed('left')", "input.mouse.released('left')"},
    {"touch", "input.touches.some((t) => t.pressed)", "0"},
    {"pad", "input.gamepad(0).pressed('A')", "input.gamepad(0).released('A')"},
    {"padaction", "input.pressed('confirm')", "input.released('confirm')"},
    {"wheel", "input.mouse.wheel", "0"},
    {"delta", "input.mouse.delta.x", "0"},
    {"text", "input.text.length", "0"},
};

struct FixedStepProject {
    stdfs::path dir = fs::make_temp_dir("fa_input_fixed");
    FixedStepProject() {
        write("factoria.json", R"({"format":"factoria.project/1","name":"FixedInput","id":"com.example.fixedinput",
                                   "mainScene":"main.scene.json","display":{"width":64,"height":64},"physics":{"fixedHz":60},
                                   "input":{"actions":{"jump":["J"],"confirm":["GamepadA"]}}})");
        std::string entities = R"({"id":"cam","components":{"Camera":{}}})";
        for (const Counter& c : kCounters) {
            entities += std::string(R"(,{"id":")") + c.id + R"(","components":{"Transform":{},"Script":{"path":")" + c.id + R"(.js"}}})";
            const std::string p = std::string("(") + c.press + ")", r = std::string("(") + c.release + ")";
            write((std::string(c.id) + ".js").c_str(),
                  ("import { Behaviour, input } from 'factoria';\n"
                   "export default class C extends Behaviour {\n"
                   "  onFixedUpdate() { const p = this.entity.position; p.x += Number(" + p + "); p.z += Number(" + r + "); }\n"
                   "  onUpdate() { const p = this.entity.position; p.y += Number(" + p + "); }\n"
                   "}\n").c_str());
        }
        write("main.scene.json", (std::string(R"({"format":"factoria.scene/1","entities":[)") + entities + "]}").c_str());
    }
    ~FixedStepProject() {
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

struct Seen {
    double fixedPress = 0, updatePress = 0, fixedRelease = 0;
};

Seen seen(Engine& e, const char* id) {
    const Entity ent = e.world().find(id);
    REQUIRE_MESSAGE(!ent.is_null(), "no entity " << id);
    const Transform* t = e.world().get<Transform>(ent);
    REQUIRE(t != nullptr);
    return {t->position.x, t->position.y, t->position.z};
}

// What one press_everything() adds up to for a counter: the wheel turned by 2, the mouse moved 3 along x, one letter typed.
double expected_count(const std::string& id) { return id == "wheel" ? 2.0 : id == "delta" ? 3.0 : 1.0; }

// A frame that runs exactly `steps` fixed steps (a little extra time that never adds up to one more over a test).
void frame_with_steps(Engine& e, int steps) { e.frame(steps * kFixedDt + kFixedDt * 1e-3); }

struct Session {
    FixedStepProject project;
    Engine e;
    Session() {
        std::string err;
        REQUIRE_MESSAGE(e.init(project.config(), nullptr, &err), err);
        frame_with_steps(e, 1);  // onStart and the first update
    }
    ~Session() { e.shutdown(); }
};

// Presses of every kind, once.
void press_everything(Input& in) {
    in.on_key(Key::Space, true);
    in.on_key(Key::J, true);
    in.on_mouse_move({3, 4});
    in.on_mouse_button(MouseButton::Left, true);
    in.on_gamepad_button(0, GamepadButton::A, true);
    in.on_touch_begin(1, {3, 4});  // where the mouse already is: the finger adds no motion
    in.on_mouse_wheel(2.0f);
    in.on_text('a');
}
void release_everything(Input& in) {
    in.on_key(Key::Space, false);
    in.on_key(Key::J, false);
    in.on_mouse_button(MouseButton::Left, false);
    in.on_gamepad_button(0, GamepadButton::A, false);
    in.on_touch_end(1);
}

}  // namespace

TEST_CASE("input per fixed step: a press in a frame with 1 step is seen once by each callback") {
    Session s;
    press_everything(s.e.input());
    frame_with_steps(s.e, 1);
    for (const Counter& c : kCounters) {
        INFO(c.id);
        const Seen v = seen(s.e, c.id);
        const double expected = expected_count(c.id);
        CHECK(v.fixedPress == doctest::Approx(expected));
        CHECK(v.updatePress == doctest::Approx(expected));
    }
    frame_with_steps(s.e, 1);  // nothing new: neither sees the press again
    for (const Counter& c : kCounters) {
        INFO(c.id);
        const Seen v = seen(s.e, c.id);
        const double expected = expected_count(c.id);
        CHECK(v.fixedPress == doctest::Approx(expected));
        CHECK(v.updatePress == doctest::Approx(expected));
    }
}

TEST_CASE("input per fixed step: a frame with 5 steps gives the press to the first step only") {
    Session s;
    press_everything(s.e.input());
    frame_with_steps(s.e, 5);
    for (const Counter& c : kCounters) {
        INFO(c.id);
        const Seen v = seen(s.e, c.id);
        const double expected = expected_count(c.id);
        CHECK(v.fixedPress == doctest::Approx(expected));  // not 5 times
        CHECK(v.updatePress == doctest::Approx(expected));
    }
    release_everything(s.e.input());
    frame_with_steps(s.e, 5);
    for (const Counter& c : {kCounters[0], kCounters[1], kCounters[2], kCounters[4], kCounters[5]}) {
        INFO(c.id);
        CHECK(seen(s.e, c.id).fixedRelease == doctest::Approx(1.0));
    }
}

TEST_CASE("input per fixed step: a press in a frame with 0 steps waits for the next step; onUpdate sees it at once") {
    Session s;
    press_everything(s.e.input());
    frame_with_steps(s.e, 0);
    for (const Counter& c : kCounters) {
        INFO(c.id);
        const Seen v = seen(s.e, c.id);
        CHECK(v.fixedPress == doctest::Approx(0.0));  // no step ran
        CHECK(v.updatePress > 0.0);                   // the frame did
    }
    frame_with_steps(s.e, 0);  // another frame with no step: still waiting, and onUpdate does not see it twice
    for (const Counter& c : kCounters) {
        INFO(c.id);
        CHECK(seen(s.e, c.id).fixedPress == doctest::Approx(0.0));
    }
    const double updateSeen = seen(s.e, "key").updatePress;
    CHECK(updateSeen == doctest::Approx(1.0));
    frame_with_steps(s.e, 2);  // the next frame with steps: the first one takes it, the second does not
    for (const Counter& c : kCounters) {
        INFO(c.id);
        const Seen v = seen(s.e, c.id);
        const double expected = expected_count(c.id);
        CHECK(v.fixedPress == doctest::Approx(expected));
        CHECK(v.updatePress == doctest::Approx(expected));
    }
}

TEST_CASE("input per fixed step: a release waits too, and a press and a release between two steps are both seen once") {
    Session s;
    Input& in = s.e.input();
    in.on_key(Key::Space, true);
    in.on_gamepad_button(0, GamepadButton::A, true);
    frame_with_steps(s.e, 1);
    CHECK(seen(s.e, "key").fixedPress == doctest::Approx(1.0));
    in.on_key(Key::Space, false);  // released in a frame with no step
    in.on_gamepad_button(0, GamepadButton::A, false);
    frame_with_steps(s.e, 0);
    CHECK(seen(s.e, "key").fixedRelease == doctest::Approx(0.0));
    frame_with_steps(s.e, 3);
    CHECK(seen(s.e, "key").fixedRelease == doctest::Approx(1.0));
    CHECK(seen(s.e, "padaction").fixedRelease == doctest::Approx(1.0));
    CHECK(seen(s.e, "pad").fixedRelease == doctest::Approx(1.0));

    // Down and up again before any step runs: the next step sees both edges, once each.
    in.on_key(Key::Space, true);
    frame_with_steps(s.e, 0);
    in.on_key(Key::Space, false);
    frame_with_steps(s.e, 0);
    frame_with_steps(s.e, 4);
    const Seen v = seen(s.e, "key");
    CHECK(v.fixedPress == doctest::Approx(2.0));
    CHECK(v.fixedRelease == doctest::Approx(2.0));
    CHECK(v.updatePress == doctest::Approx(2.0));
}

TEST_CASE("input per fixed step: holds are unchanged, a key held for many frames of 0, 1 and 5 steps is one press") {
    Session s;
    s.e.input().on_key(Key::Space, true);
    for (int steps : {0, 1, 5, 0, 2, 1}) frame_with_steps(s.e, steps);
    const Seen v = seen(s.e, "key");
    CHECK(v.fixedPress == doctest::Approx(1.0));
    CHECK(v.updatePress == doctest::Approx(1.0));
}

TEST_CASE("input per fixed step: Engine::step (one step per frame) keeps what it always did") {
    Session s;
    s.e.input().on_key(Key::Space, true);
    s.e.step(1);
    s.e.input().on_key(Key::Space, false);
    s.e.step(1);
    s.e.step(3);
    const Seen v = seen(s.e, "key");
    CHECK(v.fixedPress == doctest::Approx(1.0));
    CHECK(v.updatePress == doctest::Approx(1.0));
    CHECK(v.fixedRelease == doctest::Approx(1.0));
}

TEST_CASE("input per fixed step: a paused game keeps the press for the step after it resumes") {
    Session s;
    s.e.input().on_key(Key::Space, true);
    s.e.set_paused(true);
    s.e.frame(0.1);  // a redraw: nothing simulates, nothing consumes
    s.e.set_paused(false);
    frame_with_steps(s.e, 1);
    const Seen v = seen(s.e, "key");
    CHECK(v.fixedPress == doctest::Approx(1.0));
    CHECK(v.updatePress == doctest::Approx(1.0));
}

TEST_CASE("input per fixed step: a tap that lands and lifts before any step is seen once by each callback") {
    Session s;
    Input& in = s.e.input();
    in.on_touch_begin(4, {3, 4});
    in.on_touch_end(4);  // the finger is gone before the frame runs
    frame_with_steps(s.e, 3);
    const Seen v = seen(s.e, "touch");
    CHECK(v.fixedPress == doctest::Approx(1.0));
    CHECK(v.updatePress == doctest::Approx(1.0));
    frame_with_steps(s.e, 3);
    CHECK(seen(s.e, "touch").fixedPress == doctest::Approx(1.0));
    CHECK(seen(s.e, "touch").updatePress == doctest::Approx(1.0));

    in.on_touch_begin(5, {3, 4});  // and in a frame with no step: the next step gets it
    in.on_touch_end(5);
    frame_with_steps(s.e, 0);
    CHECK(seen(s.e, "touch").updatePress == doctest::Approx(2.0));
    CHECK(seen(s.e, "touch").fixedPress == doctest::Approx(1.0));
    frame_with_steps(s.e, 2);
    CHECK(seen(s.e, "touch").fixedPress == doctest::Approx(2.0));
    CHECK(seen(s.e, "touch").updatePress == doctest::Approx(2.0));
}

namespace {

double position_of(const Json& state, const char* id, int axis) {
    for (const Json& ent : state["entities"])
        if (ent.value("id", "") == id) return ent["components"]["Transform"]["position"][std::size_t(axis)].get<double>();
    FAIL("no entity " << id << " in the state");
    return -1.0;
}

}  // namespace

TEST_CASE("input per fixed step: a recording made with frames of any dt replays with the same counts") {
    Session s;
    Input& in = s.e.input();
    s.e.start_input_recording();
    // Frames of very different lengths (0 to 5 steps), with presses and releases between them.
    struct Frame {
        double dt;
        int act;  // 0 nothing, 1 press everything, 2 release everything
    };
    const Frame frames[] = {{0.05, 1},   {0.002, 0},  {0.0167, 2}, {0.09, 1},  {0.001, 0},   {0.034, 2},
                            {0.0005, 1}, {0.0005, 0}, {0.0005, 2}, {0.2, 1},   {0.0167, 0},  {0.0167, 2}};
    int count = 0;
    for (const Frame& f : frames) {
        if (f.act == 1) {
            in.on_key(Key::Space, true);
            in.on_key(Key::J, true);
            in.on_mouse_button(MouseButton::Left, true);
            in.on_gamepad_button(0, GamepadButton::A, true);
            in.on_touch_begin(1, {3, 4});
        } else if (f.act == 2) {
            release_everything(in);
        }
        s.e.frame(f.dt);
        ++count;
    }
    const Json recorded = s.e.stop_input_recording();
    REQUIRE(recorded["timing"].is_array());
    CHECK(recorded["timing"].size() == std::size_t(count));
    bool zero = false, several = false;
    for (const Json& t : recorded["timing"]) {
        zero = zero || t[1].get<int>() == 0;
        several = several || t[1].get<int>() >= 3;
    }
    CHECK(zero);     // a frame with no step took part
    CHECK(several);  // and a frame with many
    std::map<std::string, Seen> live;
    for (const Counter& c : kCounters) live[c.id] = seen(s.e, c.id);

    // Replay it: every frame runs the recorded dt and number of steps. (One graphics context per process: the recording
    // engine ends first.)
    s.e.shutdown();
    const stdfs::path replayPath = s.project.dir / "recorded.json";
    REQUIRE(fs::write_text(replayPath.generic_string(), recorded.dump()).ok());
    HeadlessRunOptions o;
    o.frames = count;
    o.inputReplayPath = replayPath.generic_string();
    o.stateOutPath = (s.project.dir / "state.json").generic_string();
    Json report;
    REQUIRE(run_headless(s.project.config(), o, &report) == 0);
    auto st = load_json_file(o.stateOutPath);
    REQUIRE(st.ok());
    for (const Counter& c : kCounters) {
        const std::string id = c.id;
        if (id == "wheel" || id == "delta" || id == "text") continue;  // not part of a recording
        INFO(id);
        CHECK(live[id].fixedPress > 0.0);
        CHECK(position_of(st.value(), c.id, 0) == doctest::Approx(live[id].fixedPress));
        CHECK(position_of(st.value(), c.id, 1) == doctest::Approx(live[id].updatePress));
        CHECK(position_of(st.value(), c.id, 2) == doctest::Approx(live[id].fixedRelease));
    }
}
