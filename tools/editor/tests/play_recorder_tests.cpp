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
