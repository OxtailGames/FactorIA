// http.fetch and replays: the "http" field of a replay entry queues the answers of the game's requests, and the input recording
// writes what each request got, in request order, in the frame of the request (docs/NETWORKING.md "Replays").
#include <doctest.h>

#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct NetProject {
    stdfs::path dir;
    NetProject() {
        dir = fs::make_temp_dir("fa_http_replay_test");
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json") << R"({
          "format": "factoria.project/1", "name": "Net", "mainScene": "scenes/main.scene.json",
          "network": {"hosts": ["api.example.com"], "purpose": "Daily challenge."}
        })";
        std::ofstream(dir / "scenes/main.scene.json") << R"({"format":"factoria.scene/1","entities":[]})";
    }
    ~NetProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

}  // namespace

TEST_CASE("http.fetch: a replay's http entries are the answers of the game's requests, in order, and the recording keeps them") {
    NetProject p;
    EngineConfig cfg;
    cfg.projectDir = p.dir.generic_string();
    cfg.headless = true;
    cfg.hotReload = false;
    cfg.platformBackend = "fake";  // what headless runs, tests and sessions ask for
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg, nullptr, &err), err);
    e.start_input_recording();

    std::vector<std::string> problems;
    e.apply_input_entry(Json::parse(R"({"http":[
        {"result":{"status":200,"headers":{},"text":"{\"daily\":7}"}},
        {"error":"network","message":"timed out","hint":"Try again."}]})"), problems, 0);
    CHECK(problems.empty());
    auto run = [&](const std::string& code) {
        auto r = e.scripts().eval(code);
        INFO(code << " -> " << (r.ok() ? r.value().dump() : r.error().message));
        REQUIRE(r.ok());
        return r.value();
    };
    run("globalThis.out = []; const url = 'https://api.example.com/daily';"
        "http.fetch(url).then((r) => out.push(r.json().daily));"
        "http.fetch(url).catch((x) => out.push(x.code + ': ' + x.hint));");
    e.step(2);
    CHECK(run("out") == Json::parse(R"([7, "network: Try again."])"));
    // A third request has nobody's answer: the fake rejects it.
    run("http.fetch('https://api.example.com/daily').catch((x) => out.push(x.code))");
    e.step(2);
    CHECK(run("out[2]") == "network");

    // The recording has every answer, in request order, in the frame of the request (both made in the first frame, the third
    // two frames later).
    const Json replay = e.stop_input_recording();
    Json http = Json::array();
    for (const auto& [frame, entry] : replay["frames"].items())
        if (entry.contains("http"))
            for (const Json& a : entry["http"]) http.push_back(Json::object({{"frame", std::stoi(frame)}, {"answer", a}}));
    INFO(replay.dump());
    REQUIRE(http.size() == 3);
    CHECK(http[0]["answer"]["result"]["text"] == R"({"daily":7})");
    CHECK(http[1]["answer"]["error"] == "network");
    CHECK(http[1]["answer"]["hint"] == "Try again.");
    CHECK(http[2]["answer"]["error"] == "network");
    CHECK(http[0]["frame"] == http[1]["frame"]);
    CHECK(http[2]["frame"].get<int>() == http[0]["frame"].get<int>() + 2);

    // Mistakes in the entry are reported, not ignored.
    problems.clear();
    e.apply_input_entry(Json::parse(R"({"http":"nope"})"), problems, 4);
    REQUIRE(problems.size() == 1);
    CHECK(problems[0].find("'http' must be an array of answers") != std::string::npos);
    problems.clear();
    e.apply_input_entry(Json::parse(R"({"htp":[]})"), problems, 5);
    REQUIRE(problems.size() == 1);
    CHECK(problems[0].find("Did you mean 'http'") != std::string::npos);
    e.shutdown();
}
