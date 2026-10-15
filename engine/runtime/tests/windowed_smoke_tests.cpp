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
    auto event = d.event;
    d.frame = [frame, event](double dt) {
        frame(dt);
        // What sokol_app sends when a mobile app goes to the background and comes back.
        if (frames == 10) event(AppEvent{AppEvent::Type::Suspended});
        if (frames == 11) event(AppEvent{AppEvent::Type::Resumed});
        if (++frames == 80) app_request_quit();
    };
    CHECK(run_app(d) == 0);
    CHECK(frames >= 80);
    // The markers the iOS/Android device smoke tests look for (docs/MOBILE.md).
    auto logs = recent_logs(4096);
    auto logged = [&](const char* message) {
        return std::any_of(logs.begin(), logs.end(),
                           [&](const LogEntry& e) { return e.category == "player" && e.message == message; });
    };
    CHECK(logged("60 frames rendered"));
    CHECK(logged("suspended"));
    CHECK(logged("resumed"));
    CHECK(logged("60 frames rendered after resume"));
}
