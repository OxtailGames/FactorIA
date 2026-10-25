// The play recorder and http.fetch: the answers a play session got are written as the "http" field of the frame of the request,
// in request order, and the headless replay reads them back without problems.
#include <filesystem>

#include "doctest.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "play_recorder.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

TEST_CASE("play recorder: http answers go to the frame of the request, in request order") {
    PlayRecorder r;
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

TEST_CASE("play recorder: a recording with http answers replays headless without problems") {
    const stdfs::path dir = fs::make_temp_dir("fa_play_recorder_http");
    REQUIRE(fs::write_text((dir / "factoria.json").generic_string(),
                           R"({"format":"factoria.project/1","name":"Rec","id":"com.example.rec","mainScene":"main.scene.json",
                               "display":{"width":64,"height":64},"physics":{"fixedHz":60},
                               "network":{"hosts":["api.example.com"],"purpose":"Test."}})").ok());
    REQUIRE(fs::write_text((dir / "main.scene.json").generic_string(),
                           R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}}]})").ok());
    PlayRecorder r;
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
