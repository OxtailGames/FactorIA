// The script budgets: runtime.scriptMemoryMB (the heap cap) and runtime.scriptFrameBudgetMs (the warning of a frame whose
// scripts took too long).
#include <doctest.h>

#include <string>

#include "fa/core/log.h"
#include "fa/core/profiler.h"
#include "fa/script/script_budget.h"
#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {

Json budget_scene() {
    return Json::object(
        {{"format", "factoria.scene/1"},
         {"entities",
          Json::array({Json::object(
              {{"id", "worker"},
               {"components", Json::object({{"Script", Json::object({{"path", "scripts/worker.js"}})}})}})})}});
}

// A behaviour that spends a few hundred thousand loop turns every frame: far above 0.001 ms, far below 1 s.
constexpr const char* kBusyScript = R"(
import { Behaviour } from "factoria";
export default class Worker extends Behaviour {
  onUpdate() {
    let s = 0;
    for (let i = 0; i < 200000; i++) s += i;
    if (s < 0) throw new Error("never");
  }
}
)";

Json runtime_settings(const Json& runtime) { return Json::object({{"runtime", runtime}}); }

// The warnings of the frame budget logged since the last clear_recent_logs().
std::vector<std::string> budget_warnings() {
    std::vector<std::string> out;
    for (const LogEntry& e : recent_logs(4096, LogLevel::Warn))
        if (e.category == "script" && e.message.find("scripts took") != std::string::npos) out.push_back(e.message);
    return out;
}

// Starts a game with the busy behaviour and the given runtime settings, scene loaded.
void start_busy(TestHost& h) {
    h.file("scripts/worker.js", kBusyScript);
    h.file("scenes/main.scene.json", budget_scene().dump());
    REQUIRE(h.start());
    h.load_scene_now("scenes/main.scene.json");
}

}  // namespace

TEST_CASE("script budgets: a per-platform number resolves to the entry of this platform, else default, else the fallback") {
    const std::string here = script_platform_name();
    CHECK(resolve_per_platform_number(Json(64), here, 768) == 64);
    CHECK(resolve_per_platform_number(Json::object({{"default", 100}, {here, 32}}), here, 768) == 32);
    CHECK(resolve_per_platform_number(Json::object({{"default", 100}}), here, 768) == 100);
    CHECK(resolve_per_platform_number(Json::object({{"android", 5}, {"ios", 6}, {"web", 7}, {"windows", 8}, {"macos", 9},
                                                    {"linux", 10}, {"default", 11}}),
                                      "nowhere", 768) == 11);
    CHECK(resolve_per_platform_number(Json::object({{"nowhere", 5}}), here, 768) == 768);
    CHECK(resolve_per_platform_number(Json(), here, 768) == 768);
    CHECK(resolve_per_platform_number(Json("big"), here, 768) == 768);
    CHECK(resolve_per_platform_number(Json::object({{here, "big"}}), here, 768) == 768);
}

TEST_CASE("script budgets: the defaults are 768 MB and 8 ms, a project can change them for this platform") {
    {
        TestHost h("budget_defaults");
        REQUIRE(h.start());
        CHECK(h.scripts.memory_limit_mb() == 768.0);
        CHECK(h.scripts.frame_budget_ms() == 8.0);
    }
    {
        TestHost h("budget_number",
                   runtime_settings(Json::object({{"scriptMemoryMB", 300}, {"scriptFrameBudgetMs", 12.5}})));
        REQUIRE(h.start());
        CHECK(h.scripts.memory_limit_mb() == 300.0);
        CHECK(h.scripts.frame_budget_ms() == 12.5);
    }
    {
        const Json own = Json::object({{"default", 400}, {script_platform_name(), 200}});
        const Json other = Json::object({{"default", 6}, {"nowhere", 7}});
        TestHost h("budget_platform", runtime_settings(Json::object({{"scriptMemoryMB", own}, {"scriptFrameBudgetMs", other}})));
        REQUIRE(h.start());
        CHECK(h.scripts.memory_limit_mb() == 200.0);
        CHECK(h.scripts.frame_budget_ms() == 6.0);
    }
}

TEST_CASE("script budgets: a script that fills the heap past the cap fails with an error that names the setting") {
    // The smallest cap the file accepts: a loop that keeps allocating reaches it in a few frames.
    TestHost h("budget_memory", runtime_settings(Json::object({{"scriptMemoryMB", 16}})));
    h.file("scripts/worker.js", R"(
import { Behaviour } from "factoria";
const keep = [];
export default class Worker extends Behaviour {
  onUpdate() {
    for (let i = 0; i < 100000; i++) keep.push(new Array(1000).fill(i));
  }
}
)");
    h.file("scenes/main.scene.json", budget_scene().dump());
    REQUIRE(h.start());
    CHECK(h.scripts.memory_limit_mb() == 16.0);
    h.load_scene_now("scenes/main.scene.json");
    h.step_frames(2);
    bool found = false;
    for (const ScriptError& e : h.scripts.errors()) {
        MESSAGE(e.to_string());
        if (e.message.find("out of memory") != std::string::npos) {
            found = true;
            CHECK(e.message.find("runtime.scriptMemoryMB") != std::string::npos);
            CHECK(e.message.find("16 MB") != std::string::npos);
        }
    }
    CHECK(found);
}

TEST_CASE("script budgets: a frame over the budget warns once, names the slowest callback, and warns again after 5 s") {
    clear_recent_logs();
    TestHost h("budget_warn", runtime_settings(Json::object({{"scriptFrameBudgetMs", 0.001}})));
    start_busy(h);
    h.step_frames(10);  // a sixth of a second of game time
    auto warnings = budget_warnings();
    REQUIRE(warnings.size() == 1);  // ten frames over budget, one line
    CHECK(warnings[0].find("scripts/worker.js#onUpdate") != std::string::npos);
    CHECK(warnings[0].find("runtime.scriptFrameBudgetMs") != std::string::npos);
    CHECK(warnings[0].find("0.001 ms") != std::string::npos);
    CHECK(warnings[0].find("frame 0") != std::string::npos);

    h.step_frames(320);  // past the 5 s of game time after the first warning
    warnings = budget_warnings();
    REQUIRE(warnings.size() == 2);
    CHECK(warnings[1].find("frames over budget since the last warning") != std::string::npos);
    // 330 frames are 5.5 s of game time: the second one came 5 s after the first and counted the frames in between (not
    // asserted to the frame: the clock is a sum of float steps).
    CHECK(warnings[1].find("frames over budget since the last warning") != std::string::npos);
    CHECK(warnings[1].find("the first warning") == std::string::npos);
}

TEST_CASE("script budgets: no warning under the budget, with the budget off, or with the budget raised") {
    for (double budget : {0.0, 1000.0}) {
        clear_recent_logs();
        TestHost h("budget_quiet" + std::to_string(int(budget)),
                   runtime_settings(Json::object({{"scriptFrameBudgetMs", budget}})));
        start_busy(h);
        h.step_frames(30);
        CHECK(budget_warnings().empty());
    }
}

TEST_CASE("script budgets: the profiler marks the frames over the budget") {
    clear_recent_logs();
    TestHost h("budget_profiler", runtime_settings(Json::object({{"scriptFrameBudgetMs", 0.001}})));
    start_busy(h);
    Profiler& p = Profiler::get();
    p.set_enabled(true);
    p.begin_frame();
    h.step_frames(1);
    p.end_frame();
    const ProfFrame f = p.last();
    p.set_enabled(false);
    REQUIRE(f.overBudget.size() == 1);
    CHECK(f.overBudget[0].name == "scripts");
    CHECK(f.overBudget[0].ms > 0.001);
    CHECK(f.overBudget[0].limitMs == doctest::Approx(0.001));
}
