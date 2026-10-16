// Real-window check of `window.*` (M10): a script toggles full screen and resizes the window of a windowed run. Runs only
// when FA_WINDOWED_SMOKE=1 and a display exists (CI: ctest `runtime_windowed_fullscreen`, under xvfb on Linux):
//   FA_WINDOWED_SMOKE=1 xvfb-run -a -s "-screen 0 1280x720x24" build/.../fa_test_runtime -tc="windowed fullscreen*"
// (sokol_gfx is a process singleton: run this test case alone in its process, not together with "windowed smoke".)
#include <doctest.h>

#include <algorithm>
#include <cstdlib>
#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/platform/app.h"
#include "fa/runtime/engine.h"

using namespace fa;

TEST_CASE("windowed fullscreen: window.setFullscreen(true) in a script toggles the real window and back"
          * doctest::skip(std::getenv("FA_WINDOWED_SMOKE") == nullptr)) {
    namespace stdfs = std::filesystem;
    stdfs::path dir = fs::make_temp_dir("fa_runtime_windowed_fullscreen");
    stdfs::create_directories(dir / "scenes");
    stdfs::create_directories(dir / "scripts");
    std::ofstream(dir / "factoria.json") << R"({"name":"Windowed","display":{"width":320,"height":180}})";
    std::ofstream(dir / "scenes/main.scene.json")
        << R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}},
                           {"id":"g","components":{"Script":{"path":"scripts/game.js"}}}]})";
    std::ofstream(dir / "scripts/game.js") << R"(
import { Behaviour, window } from "factoria";
export default class G extends Behaviour {
  onStart() { this.n = 0; }
  onUpdate() {
    this.n++;
    if (this.n === 5) { window.setFullscreen(true); console.log("fs-on " + window.fullscreen); }
    if (this.n === 15) { window.setFullscreen(false); console.log("fs-off " + window.fullscreen); }
    if (this.n === 20) { window.setSize(480, 270); }
    if (this.n === 30) {
      console.log("size-ok " + (window.size.x > 0 && window.size.y > 0) + " available " + window.available);
      console.log("resolutions " + (window.resolutions().length > 0));    }
  }
}
)";

    EngineConfig cfg;
    cfg.projectDir = dir.generic_string();
    AppDesc d = make_app_desc(cfg);
    static int frames = 0;
    static bool fullAt10 = false, fullAt30 = true;
    auto frame = d.frame;
    d.frame = [frame](double dt) {
        frame(dt);
        ++frames;
        if (frames == 10) fullAt10 = app_is_fullscreen();  // the script went full screen at frame 5
        if (frames == 30) fullAt30 = app_is_fullscreen();  // and back to a window at frame 15
        if (frames == 40) app_request_quit();
    };
    CHECK(run_app(d) == 0);
    CHECK(frames >= 40);
    CHECK(fullAt10);
    CHECK_FALSE(fullAt30);
    auto logs = recent_logs(4096);
    auto logged = [&](const char* message) {
        return std::any_of(logs.begin(), logs.end(),
                           [&](const LogEntry& e) { return e.category == "script" && e.message == message; });
    };
    CHECK(logged("fs-on true"));
    CHECK(logged("fs-off false"));
    CHECK(logged("size-ok true available true"));
    CHECK(logged("resolutions true"));
    for (const LogEntry& e : logs)
        if (e.category == "script") CHECK_MESSAGE(e.level < LogLevel::Error, e.message);
}
