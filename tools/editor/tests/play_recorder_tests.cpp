// The play recorder writes the input replay format: what it records, `factoria run --headless --input` plays back.
#include <filesystem>

#include "doctest.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "play_recorder.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

TEST_CASE("play recorder: frames are relative to the start, releases are recorded on release_all") {
    PlayRecorder r;
    r.start(100);
    r.key(100, Key::Space, true);
    r.mouse_position(102, Vec2{10, 20});
    r.mouse_button(102, MouseButton::Left, true);
    r.release_all(105);
    const Json in = r.input();
    CHECK(in["frames"]["0"]["keys"]["Space"] == true);
    CHECK(in["frames"]["2"]["mouse"]["position"][1] == 20);
    CHECK(in["frames"]["2"]["mouse"]["left"] == true);
    CHECK(in["frames"]["5"]["keys"]["Space"] == false);
    CHECK(in["frames"]["5"]["mouse"]["left"] == false);
}

TEST_CASE("play recorder: timing has one [dt, steps] per frame, unreported frames are step(1) calls") {
    PlayRecorder r;
    r.start(10);
    r.timing(11, 0.05, 3, 0.02);
    r.timing(14, 0.01, 0, 0.02);  // frames 12 and 13 ran as step(1)
    const Json t = r.input()["timing"];
    REQUIRE(t.size() == 4);
    CHECK(t[0] == Json::array({0.05, 3}));
    CHECK(t[1] == Json::array({0.02, 1}));
    CHECK(t[2] == Json::array({0.02, 1}));
    CHECK(t[3] == Json::array({0.01, 0}));
}

TEST_CASE("play recorder: the recorded file is read by the headless replay without problems") {
    const stdfs::path dir = fs::make_temp_dir("fa_play_recorder");
    REQUIRE(fs::write_text((dir / "factoria.json").generic_string(),
                           R"({"format":"factoria.project/1","name":"Rec","id":"com.example.rec","mainScene":"main.scene.json",
                               "display":{"width":64,"height":64},"physics":{"fixedHz":60}})").ok());
    REQUIRE(fs::write_text((dir / "main.scene.json").generic_string(),
                           R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}}]})").ok());
    PlayRecorder r;
    r.start(0);
    r.key(1, Key::A, true);
    r.mouse_position(2, Vec2{5, 6});
    r.mouse_button(2, MouseButton::Right, true);
    r.release_all(4);
    REQUIRE(save_json_file((dir / "input.json").generic_string(), r.input()).ok());

    EngineConfig c;
    c.projectDir = dir.generic_string();
    HeadlessRunOptions o;
    o.frames = 6;
    o.inputReplayPath = (dir / "input.json").generic_string();
    Json report;
    CHECK(run_headless(c, o, &report) == 0);
    CHECK(report["frames"] == 6);
    CHECK_FALSE(report.contains("problems"));
    std::error_code ec;
    stdfs::remove_all(dir, ec);
}

TEST_CASE("play recorder: a play at variable frame times replays exactly (onUpdate dt, fixed steps, input edges)") {
    const stdfs::path dir = fs::make_temp_dir("fa_play_exact");
    auto w = [&](const char* rel, const char* text) { REQUIRE(fs::write_text((dir / rel).generic_string(), text).ok()); };
    w("factoria.json", R"({"format":"factoria.project/1","name":"Exact","id":"com.example.exact","mainScene":"main.scene.json",
                           "display":{"width":64,"height":64},"physics":{"fixedHz":60}})");
    w("main.scene.json", R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}},
                             {"id":"p","components":{"Transform":{},"Script":{"path":"p.js"}}}]})");
    w("p.js", "import { Behaviour, input } from 'factoria';\n"
              "export default class P extends Behaviour {\n"
              "  onUpdate(dt) { const p = this.entity.position; if (input.keyDown('Space')) p.x += dt * 10; if (input.keyPressed('Space')) p.y += 1; }\n"
              "  onFixedUpdate() { this.entity.position.z += input.keyDown('Space') ? 1 : 0.01; }\n"
              "}\n");
    EngineConfig c;
    c.projectDir = dir.generic_string();
    c.headless = true;
    c.hotReload = false;
    c.memoryStorage = true;
    auto position = [](const Json& state) {
        for (const Json& e : state["entities"])
            if (e["id"] == "p") return e["components"]["Transform"]["position"];
        return Json();
    };

    // The "editor": variable frame times (0 to 5 fixed steps per frame, one clamped), Space pressed/released between frames.
    Json played;
    int frames = 0;
    {
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
        PlayRecorder r;
        const std::uint64_t start = e.frame_index();
        r.start(start);
        const double dts[] = {0.016, 0.05, 0.004, 0.004, 0.3, 0.033, 0.001, 0.07, 0.016, 0.02, 0.009, 0.045};
        for (int i = 0; i < int(std::size(dts)); ++i) {
            if (i == 1 || i == 6) { e.input().on_key(Key::Space, true); r.key(e.frame_index(), Key::Space, true); }
            if (i == 3 || i == 9) { e.input().on_key(Key::Space, false); r.key(e.frame_index(), Key::Space, false); }
            const std::uint64_t steps = e.fixed_step_index();
            e.frame(dts[i]);
            r.timing(e.frame_index(), dts[i], int(e.fixed_step_index() - steps), 1.0 / 60.0);
        }
        frames = int(e.frame_index() - start);
        played = position(e.state());
        e.shutdown();
        REQUIRE(save_json_file((dir / "input.json").generic_string(), r.input()).ok());
    }
    REQUIRE(played.is_array());
    CHECK(played[1].get<double>() == doctest::Approx(2.0));  // two presses

    auto replay = [&](const char* inputFile) {
        HeadlessRunOptions o;
        o.frames = frames;
        o.inputReplayPath = (dir / inputFile).generic_string();
        o.stateOutPath = (dir / "state.json").generic_string();
        Json report;
        CHECK(run_headless(c, o, &report) == 0);
        CHECK_FALSE(report.contains("problems"));
        auto st = load_json_file(o.stateOutPath);
        REQUIRE(st.ok());
        return position(st.value());
    };
    const Json replayed = replay("input.json");
    for (int k = 0; k < 3; ++k) CHECK(replayed[k].get<double>() == played[k].get<double>());

    // Without the timing (one fixed step per frame) the same input ends somewhere else: the test would catch a regression.
    Json noTiming = load_json_file((dir / "input.json").generic_string()).value();
    noTiming.erase("timing");
    REQUIRE(save_json_file((dir / "input-frames.json").generic_string(), noTiming).ok());
    CHECK(replay("input-frames.json") != played);
    std::error_code ec;
    stdfs::remove_all(dir, ec);
}
