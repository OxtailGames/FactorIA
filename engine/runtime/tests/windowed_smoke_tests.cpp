// Manual windowed smoke check. Runs only when FA_WINDOWED_SMOKE=1 and a display exists:
//   FA_WINDOWED_SMOKE=1 xvfb-run -a -s "-screen 0 1280x720x24" build/.../fa_test_runtime -tc="windowed*"
// (sokol_gfx is a process singleton: run this test case alone in its process.)
#include <doctest.h>

#include <algorithm>
#include <cstdlib>
#include <filesystem>
#include <fstream>

#include "fa/core/log.h"
#include "fa/runtime/engine.h"
#include "fa/core/fs.h"

using namespace fa;

TEST_CASE("windowed smoke: Engine runs inside run_app, renders, presents and quits"
          * doctest::skip(std::getenv("FA_WINDOWED_SMOKE") == nullptr)) {
    namespace stdfs = std::filesystem;
    stdfs::path dir = fs::make_temp_dir("fa_runtime_windowed");
    stdfs::create_directories(dir / "scenes");
    std::ofstream(dir / "factoria.json") << R"({"name":"Windowed","display":{"width":320,"height":180}})";
    std::ofstream(dir / "scenes/main.scene.json")
        << R"({"entities":[{"id":"cam","components":{"Camera":{}}},{"id":"b","components":{"Shape2D":{"size":[50,50]}}}]})";

    EngineConfig cfg;
    cfg.projectDir = dir.generic_string();
    AppDesc d = make_app_desc(cfg);
    CHECK(d.title == "Windowed");
    static int frames = 0;
    auto frame = d.frame;
    d.frame = [frame](double dt) {
        frame(dt);
        if (++frames == 65) app_request_quit();
    };
    CHECK(run_app(d) == 0);
    CHECK(frames >= 65);
    // The run marker the iOS/Android device smoke tests look for.
    auto logs = recent_logs(4096);
    CHECK(std::any_of(logs.begin(), logs.end(),
                      [](const LogEntry& e) { return e.category == "player" && e.message == "60 frames rendered"; }));
}
