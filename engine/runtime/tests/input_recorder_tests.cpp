// The input recorder writes the input replay format: what it records, `factoria run --headless --input` plays back.
#include <filesystem>

#include "doctest.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/input_recorder.h"

using namespace fa;
namespace stdfs = std::filesystem;

TEST_CASE("input recorder: frames are relative to the start, releases are recorded on release_all") {
    InputRecorder r;
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

TEST_CASE("input recorder: timing has one [dt, steps] per frame, unreported frames are step(1) calls") {
    InputRecorder r;
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

TEST_CASE("input recorder: the recorded file is read by the headless replay without problems") {
    const stdfs::path dir = fs::make_temp_dir("fa_play_recorder");
    REQUIRE(fs::write_text((dir / "factoria.json").generic_string(),
                           R"({"format":"factoria.project/1","name":"Rec","id":"com.example.rec","mainScene":"main.scene.json",
                               "display":{"width":64,"height":64},"physics":{"fixedHz":60}})").ok());
    REQUIRE(fs::write_text((dir / "main.scene.json").generic_string(),
                           R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}}]})").ok());
    InputRecorder r;
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

TEST_CASE("input recorder: http answers go to the frame of the request, in request order") {
    InputRecorder r;
    r.start(100);
    r.http(102, Json::parse(R"({"result":{"status":200,"headers":{},"text":"first"}})"));
    r.http(102, Json::parse(R"({"error":"network","message":"timed out","hint":"Try again."})"));
    r.http(110, Json::parse(R"({"result":{"status":404,"headers":{},"text":""}})"));
    const Json in = r.input();
    REQUIRE(in["frames"]["2"]["http"].size() == 2);
    CHECK(in["frames"]["2"]["http"][0]["result"]["text"] == "first");
    CHECK(in["frames"]["2"]["http"][1]["error"] == "network");
    REQUIRE(in["frames"]["10"]["http"].size() == 1);
    CHECK(in["frames"]["10"]["http"][0]["result"]["status"] == 404);
}

TEST_CASE("input recorder: a recording with http answers replays headless without problems") {
    const stdfs::path dir = fs::make_temp_dir("fa_input_recorder_http");
    REQUIRE(fs::write_text((dir / "factoria.json").generic_string(),
                           R"({"format":"factoria.project/1","name":"Rec","id":"com.example.rec","mainScene":"main.scene.json",
                               "display":{"width":64,"height":64},"physics":{"fixedHz":60},
                               "network":{"hosts":["api.example.com"],"purpose":"Test."}})").ok());
    REQUIRE(fs::write_text((dir / "main.scene.json").generic_string(),
                           R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}}]})").ok());
    InputRecorder r;
    r.start(0);
    r.http(1, Json::parse(R"({"result":{"status":200,"headers":{"content-type":"application/json"},"text":"{\"daily\":7}"}})"));
    r.http(1, Json::parse(R"({"error":"network","message":"no route","hint":"Try again."})"));
    REQUIRE(save_json_file((dir / "input.json").generic_string(), r.input()).ok());

    EngineConfig c;
    c.projectDir = dir.generic_string();
    HeadlessRunOptions o;
    o.frames = 4;
    o.inputReplayPath = (dir / "input.json").generic_string();
    Json report;
    CHECK(run_headless(c, o, &report) == 0);
    CHECK_FALSE(report.contains("problems"));
    std::error_code ec;
    stdfs::remove_all(dir, ec);
}

TEST_CASE("input recorder: a play at variable frame times replays exactly (onUpdate dt, fixed steps, input edges)") {
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
        const std::uint64_t start = e.frame_index();
        e.start_input_recording();  // the engine records what its Input receives and what each frame took
        const double dts[] = {0.016, 0.05, 0.004, 0.004, 0.3, 0.033, 0.001, 0.07, 0.016, 0.02, 0.009, 0.045};
        for (int i = 0; i < int(std::size(dts)); ++i) {
            if (i == 1 || i == 6) e.input().on_key(Key::Space, true);
            if (i == 3 || i == 9) e.input().on_key(Key::Space, false);
            e.frame(dts[i]);
        }
        frames = int(e.frame_index() - start);
        played = position(e.state());
        const Json recorded = e.stop_input_recording();
        e.shutdown();
        REQUIRE(save_json_file((dir / "input.json").generic_string(), recorded).ok());
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

namespace {

struct RecProject {
    stdfs::path dir = fs::make_temp_dir("fa_input_rec");
    RecProject() {
        write("factoria.json", R"({"format":"factoria.project/1","name":"Rec","id":"com.example.rec","mainScene":"scenes/main.scene.json",
                                   "display":{"width":64,"height":64},"physics":{"fixedHz":60}})");
        write("scenes/main.scene.json",
              R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}},
                  {"id":"p","components":{"Transform":{},"Script":{"path":"p.js"}}},
                  {"id":"q","components":{"Transform":{},"Script":{"path":"props.js"}}}]})");
        write("p.js", "import { Behaviour, input } from 'factoria';\n"
                      "export default class P extends Behaviour {\n"
                      "  onFixedUpdate() {\n"
                      "    const pad = input.gamepad(0), p = this.entity.position;\n"
                      "    p.x += pad.axis('LeftX') * 0.5;\n"
                      "    if (pad.pressed('A')) p.y += 1;\n"
                      "    if (input.keyDown('Space')) p.z += 0.25;\n"
                      "    if (input.keyPressed('Enter')) p.z += 100;\n"
                      "  }\n"
                      "}\n");
        write("props.js", "import { Behaviour, game, input, scene } from 'factoria';\n"
                          "export default class Q extends Behaviour {\n"
                          "  onStart() { const pr = game.sceneProps(); this.entity.position.x = pr.level === undefined ? -1 : pr.level;\n"
                          "              this.entity.position.y = (pr.nested && pr.nested.list) ? pr.nested.list.length : 0; }\n"
                          "  onUpdate() { if (input.keyPressed('L')) scene.load('scenes/main.scene.json', { level: 9 });\n"
                          "               if (input.keyPressed('K')) scene.load('scenes/main.scene.json');\n"
                          "               if (input.keyPressed('R')) scene.reload(); }\n"
                          "}\n");
    }
    ~RecProject() {
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

Json entity_position(const Json& state, const char* id) {
    for (const Json& e : state["entities"])
        if (e["id"] == id) {  // a default position is not written, nor a Transform that has nothing else
            const Json& c = e["components"];
            return c.contains("Transform") ? c["Transform"].value("position", Json::array({0, 0, 0})) : Json::array({0, 0, 0});
        }
    return Json();
}

}  // namespace

TEST_CASE("input recorder: gamepads, touches and Back are recorded in order, repeats of a pad state are not") {
    InputRecorder r;
    std::uint64_t frame = 3;
    r.set_frame_source(&frame);
    Input in;
    in.set_observer(&r);
    in.on_gamepad_axis(0, GamepadAxis::LeftX, 0.0f);  // before start(): nothing is recorded
    r.start(3);
    in.on_gamepad_button(0, GamepadButton::A, true);
    in.on_gamepad_axis(0, GamepadAxis::LeftX, 0.5f);
    in.on_gamepad_axis(0, GamepadAxis::LeftX, 0.5f);  // a poll feeds the same value again: not an event
    in.on_gamepad_button(0, GamepadButton::A, true);
    in.on_touch_move(7, Vec2{1, 1});     // nobody put finger 7 down: a replay must not begin it
    in.on_touch_begin(1, Vec2{10, 20});  // the mouse it drives is a consequence, not an event
    frame = 5;
    in.on_touch_end(1);
    in.on_back();
    in.on_gamepad_button(0, GamepadButton::A, false);
    in.on_gamepad_connected(1, true);
    frame = 6;
    in.release_all();  // pad 0 (connected by its events) and pad 1 disconnect
    const Json j = r.input();
    const Json& f0 = j["frames"]["0"];
    REQUIRE(f0["gamepad"].size() == 1);  // the button and the axis of pad 0 share one object
    CHECK(f0["gamepad"][0]["buttons"]["A"] == true);
    CHECK(f0["gamepad"][0]["axes"]["LeftX"] == 0.5);
    REQUIRE(f0["touch"].size() == 1);
    CHECK(f0["touch"][0]["id"] == 1);
    CHECK_FALSE(f0.contains("mouse"));
    const Json& f2 = j["frames"]["2"];
    CHECK(f2["touch"][0]["down"] == false);
    CHECK(f2["back"] == true);
    CHECK(f2["gamepad"][0]["buttons"]["A"] == false);
    CHECK(f2["gamepad"][1]["connected"] == true);
    const Json& f3 = j["frames"]["3"];
    REQUIRE(f3["gamepad"].size() == 2);
    CHECK(f3["gamepad"][0]["connected"] == false);
    CHECK(f3["gamepad"][1]["connected"] == false);

    r.stop();
    in.on_key(Key::A, true);  // stopped: nothing more
    CHECK(r.input()["frames"].size() == j["frames"].size());
}

TEST_CASE("input recorder: a recorded keyboard and pad session replays to the same state") {
    RecProject p;
    Json played;
    int frames = 0;
    {
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
        e.input().on_key(Key::Space, true);  // held when the recording starts: part of the session
        e.start_input_recording();
        const double dts[] = {0.016, 0.05, 0.004, 0.02, 0.3, 0.033, 0.001, 0.07, 0.016, 0.02, 0.009, 0.045, 0.016, 0.016};
        for (int i = 0; i < int(std::size(dts)); ++i) {
            if (i == 1) e.input().on_gamepad_axis(0, GamepadAxis::LeftX, 0.8f);
            if (i == 2) e.input().on_gamepad_button(0, GamepadButton::A, true);
            if (i == 4) e.input().on_gamepad_button(0, GamepadButton::A, false);
            if (i == 5) e.input().on_key(Key::Space, false);
            if (i == 6) e.input().on_key(Key::Enter, true);
            if (i == 7) e.input().on_key(Key::Enter, false);
            if (i == 9) e.input().on_gamepad_axis(0, GamepadAxis::LeftX, -0.4f);
            if (i == 11) e.input().on_gamepad_axis(0, GamepadAxis::LeftX, 0.0f);
            e.frame(dts[i]);
        }
        frames = int(e.input_recording_frames());
        played = e.state()["entities"];
        const Json replay = e.stop_input_recording();
        CHECK_FALSE(e.input_recording());
        REQUIRE(save_json_file((p.dir / "session.json").generic_string(), replay).ok());
        CHECK(replay["frames"]["0"]["keys"]["Space"] == true);
        CHECK(replay["frames"]["1"]["gamepad"][0]["axes"]["LeftX"].get<double>() == doctest::Approx(0.8));
        e.shutdown();
    }
    REQUIRE(frames == 14);
    const Json playedState = Json::object({{"entities", played}});
    CHECK(entity_position(playedState, "p")[1].get<double>() == doctest::Approx(1.0));  // the A press
    CHECK(entity_position(playedState, "p")[0].get<double>() != 0.0);
    HeadlessRunOptions o;
    o.frames = frames;
    o.inputReplayPath = (p.dir / "session.json").generic_string();
    o.stateOutPath = (p.dir / "state.json").generic_string();
    Json report;
    CHECK(run_headless(p.config(), o, &report) == 0);
    CHECK_FALSE(report.contains("problems"));
    auto st = load_json_file(o.stateOutPath);
    REQUIRE(st.ok());
    CHECK(std::hash<std::string>{}(st.value()["entities"].dump()) == std::hash<std::string>{}(played.dump()));
}

TEST_CASE("input recorder: a chord (Ctrl held, then a key) is recorded as its keys and replays without problems") {
    RecProject p;
    Json replay;
    int frames = 0;
    {
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
        e.start_input_recording();
        for (int i = 0; i < 6; ++i) {
            if (i == 1) e.input().on_key(Key::LeftControl, true);
            if (i == 2) e.input().on_key(Key::Z, true);
            if (i == 3) e.input().on_key(Key::Z, false);
            if (i == 4) e.input().on_key(Key::LeftControl, false);
            e.frame(0.016);
        }
        frames = int(e.input_recording_frames());
        replay = e.stop_input_recording();
        REQUIRE(save_json_file((p.dir / "chord.json").generic_string(), replay).ok());
        e.shutdown();
    }
    CHECK(replay["frames"]["1"]["keys"]["LeftControl"] == true);
    CHECK(replay["frames"]["2"]["keys"]["Z"] == true);
    HeadlessRunOptions o;
    o.frames = frames;
    o.inputReplayPath = (p.dir / "chord.json").generic_string();
    Json report;
    CHECK(run_headless(p.config(), o, &report) == 0);
    CHECK_FALSE(report.contains("problems"));
}

TEST_CASE("input.record: start, stop returns the replay, path writes it, stop without start teaches") {
    RecProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    auto r = e.commands().call("input.record", Json::parse(R"({"action":"stop"})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["hint"].get<std::string>().find("start") != std::string::npos);
    r = e.commands().call("input.record", Json::parse(R"({"action":"start"})"));
    REQUIRE(r.ok);
    CHECK(r.result["recording"] == true);
    e.commands().call("game.input", Json::parse(R"({"key":"Space","down":true})"));
    e.commands().call("game.input", Json::parse(R"({"gamepad":{"index":0,"buttons":{"A":true}}})"));
    e.step(3);
    r = e.commands().call("input.record", Json::parse(R"({"action":"stop","path":"replays/run.json"})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["frames"] == 3);
    CHECK(r.result["replay"]["frames"]["0"]["keys"]["Space"] == true);
    CHECK(r.result["replay"]["frames"]["0"]["gamepad"][0]["buttons"]["A"] == true);
    CHECK(r.result["replay"]["timing"].size() == 3);
    CHECK(stdfs::exists(p.dir / "replays" / "run.json"));
    r = e.commands().call("input.record", Json::parse(R"({"action":"stop"})"));
    CHECK_FALSE(r.ok);
    e.shutdown();
}

TEST_CASE("scene props: a scene started with props sees them in its first start(), a reload keeps them, a plain load drops them") {
    RecProject p;
    EngineConfig c = p.config();
    c.sceneProps = Json::parse(R"({"level":3,"nested":{"list":[1,2]}})");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    CHECK(entity_position(e.state(), "q")[0] == 0.0);  // onStart has not run yet
    e.step(1);
    Json pos = entity_position(e.state(), "q");
    CHECK(pos[0] == 3);
    CHECK(pos[1] == 2);
    CHECK(e.scene_props()["level"] == 3);

    e.reload_scene();
    e.step(1);
    CHECK(entity_position(e.state(), "q")[0] == 3);  // same scene, same props

    REQUIRE(e.load_scene("scenes/main.scene.json", &err));
    e.step(1);
    CHECK(entity_position(e.state(), "q")[0] == -1);  // a load without props: none
    CHECK(e.scene_props().empty());

    REQUIRE(e.load_scene("scenes/main.scene.json", Json::parse(R"({"level":7})"), &err));
    e.step(1);
    CHECK(entity_position(e.state(), "q")[0] == 7);

    // The command, and a script's scene.load(path, props) / scene.load(path) / scene.reload().
    auto r = e.commands().call("scene.load", Json::parse(R"({"path":"scenes/main.scene.json","props":{"level":5}})"));
    REQUIRE(r.ok);
    e.step(1);
    CHECK(entity_position(e.state(), "q")[0] == 5);
    e.commands().call("game.input", Json::parse(R"({"key":"L","down":true})"));
    e.step(2);
    e.commands().call("game.input", Json::parse(R"({"key":"L","down":false})"));
    CHECK(entity_position(e.state(), "q")[0] == 9);
    e.commands().call("game.input", Json::parse(R"({"key":"R","down":true})"));
    e.step(2);
    e.commands().call("game.input", Json::parse(R"({"key":"R","down":false})"));
    CHECK(entity_position(e.state(), "q")[0] == 9);  // scene.reload() keeps them
    e.commands().call("game.input", Json::parse(R"({"key":"K","down":true})"));
    e.step(2);
    CHECK(entity_position(e.state(), "q")[0] == -1);  // scene.load(path) drops them
    r = e.commands().call("scene.load", Json::parse(R"({"path":"scenes/main.scene.json","props":5})"));
    CHECK_FALSE(r.ok);
    e.shutdown();
}
