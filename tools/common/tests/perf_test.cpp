// Performance budgets (fa/tooling/perf.h): the comparison, tolerances, runner id and the perf.* commands on a tiny project.
#include <doctest.h>

#include <cstdlib>
#include <filesystem>

#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/tooling/perf.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/tooling.h"
#include "test_helpers.h"

using namespace fa;
using fa::testing::TempDir;

namespace {

PerfSample sample(double avg, double p95, double mem, int draws, int entities) {
    PerfSample s;
    s.frames = 300;
    s.cpuMsAvg = avg;
    s.cpuMsP95 = p95;
    s.cpuMsMax = p95 * 2;
    s.peakMemoryMB = mem;
    s.drawCalls = draws;
    s.entities = entities;
    return s;
}

const PerfCheckRow* row(const PerfVerdict& v, const char* metric) {
    for (const PerfCheckRow& r : v.rows)
        if (r.metric == metric) return &r;
    return nullptr;
}

}  // namespace

TEST_CASE("perf_compare: the baseline itself and small noise pass") {
    const PerfSample base = sample(5, 8, 100, 40, 200);
    CHECK(perf_compare(base, base, PerfTolerance{}, true).status == "pass");
    CHECK(perf_compare(sample(6.5, 11, 104, 42, 205), base, PerfTolerance{}, true).status == "pass");
}

TEST_CASE("perf_compare: memory, draw calls and entities fail always; time fails only when strict") {
    const PerfSample base = sample(5, 8, 100, 40, 200);
    PerfVerdict v = perf_compare(sample(5, 8, 140, 40, 200), base, PerfTolerance{}, false);
    CHECK(v.status == "fail");  // +40% memory, even outside CI
    CHECK(row(v, "peakMemoryMB")->exceeded);
    v = perf_compare(sample(5, 8, 100, 80, 200), base, PerfTolerance{}, false);
    CHECK(v.status == "fail");
    CHECK(row(v, "drawCalls")->exceeded);
    v = perf_compare(sample(5, 8, 100, 40, 400), base, PerfTolerance{}, false);
    CHECK(row(v, "entities")->exceeded);

    const PerfSample slow = sample(20, 40, 100, 40, 200);  // 4x the time, same memory and draw calls
    v = perf_compare(slow, base, PerfTolerance{}, false);
    CHECK(v.status == "warn");
    CHECK(row(v, "cpuMsAvg")->timing);
    CHECK(row(v, "cpuMsAvg")->exceeded);
    CHECK(perf_compare(slow, base, PerfTolerance{}, true).status == "fail");
}

TEST_CASE("perf_compare: a limit is the larger of the ratio and the slack, so tiny baselines do not flap") {
    const PerfSample base = sample(0.2, 0.3, 50, 1, 2);
    const PerfVerdict v = perf_compare(sample(0.9, 1.1, 55, 3, 4), base, PerfTolerance{}, true);
    CHECK(v.status == "pass");  // 0.9 ms is 4.5x the baseline but under 0.2 + 1 ms of slack; 3 calls <= 1 + 2
    CHECK(row(v, "cpuMsAvg")->limit == doctest::Approx(1.2));
    CHECK(row(v, "drawCalls")->limit == doctest::Approx(3.0));
    CHECK(perf_compare(sample(1.3, 1.1, 55, 3, 4), base, PerfTolerance{}, true).status == "fail");
}

TEST_CASE("perf_compare: a baseline lowered below the measurement is a regression") {
    const PerfSample measured = sample(5, 8, 100, 40, 200);
    PerfSample lowered = measured;
    lowered.peakMemoryMB = 20;
    lowered.drawCalls = 10;
    CHECK(perf_compare(measured, lowered, PerfTolerance{}, false).status == "fail");
}

TEST_CASE("perf tolerances: overrides, and problems teach") {
    std::vector<std::string> problems;
    const PerfTolerance t = perf_tolerance_from_json(Json::parse(R"({"memory":0.5,"cpuAvg":3})"), &problems);
    CHECK(problems.empty());
    CHECK(t.memory == doctest::Approx(0.5));
    CHECK(t.cpuAvg == doctest::Approx(3));
    CHECK(t.drawCalls == doctest::Approx(0.10));  // untouched
    perf_tolerance_from_json(Json::parse(R"({"memry":0.5,"drawCalls":-1})"), &problems);
    REQUIRE(problems.size() == 2);
    CHECK(problems[0].find("memory") != std::string::npos);  // did you mean
    CHECK(problems[1].find("drawCalls") != std::string::npos);
}

TEST_CASE("perf samples round-trip through JSON") {
    const PerfSample s = sample(1.5, 2.5, 64.5, 7, 9);
    const PerfSample r = perf_sample_from_json(perf_sample_json(s));
    CHECK(r.frames == 300);
    CHECK(r.cpuMsAvg == doctest::Approx(1.5));
    CHECK(r.peakMemoryMB == doctest::Approx(64.5));
    CHECK(r.drawCalls == 7);
    CHECK(r.entities == 9);
    CHECK(perf_sample_from_json(Json("not an object")).frames == 0);
}

TEST_CASE("perf_runner_id: os-compiler-renderer, with an override") {
#if defined(_WIN32)
    _putenv_s("FACTORIA_PERF_RUNNER", "");
#else
    unsetenv("FACTORIA_PERF_RUNNER");
#endif
    const std::string warp = perf_runner_id("D3D11 WARP software / Microsoft Basic Render Driver (feature level 0xb100)");
    CHECK(warp.find("d3d11-warp") != std::string::npos);
    CHECK(perf_runner_id("EGL surfaceless / llvmpipe (LLVM 19)").find("-llvmpipe") != std::string::npos);
    CHECK(perf_runner_id("Metal / Apple M1").find("-metal") != std::string::npos);
    CHECK(perf_runner_id("none").find("-nogpu") != std::string::npos);
    CHECK(perf_runner_id("D3D11 hardware / AMD Radeon").find("-d3d11") != std::string::npos);
    const std::string id = perf_runner_id("none");
#if defined(_WIN32)
    CHECK(id.rfind("windows-msvc-", 0) == 0);
    _putenv_s("FACTORIA_PERF_RUNNER", "my-box");
    CHECK(perf_runner_id("none") == "my-box");
    _putenv_s("FACTORIA_PERF_RUNNER", "");
#else
    CHECK((id.rfind("linux-", 0) == 0 || id.rfind("macos-", 0) == 0 || id.rfind("android-", 0) == 0 || id.rfind("web-", 0) == 0));
    setenv("FACTORIA_PERF_RUNNER", "my-box", 1);
    CHECK(perf_runner_id("none") == "my-box");
    unsetenv("FACTORIA_PERF_RUNNER");
#endif
}

TEST_CASE("perf.baseline then perf.check on a tiny project (no GPU needed)") {
    TempDir t;
    auto made = create_project(t.str(), "2d-empty");
    REQUIRE(made.ok());
    CommandRegistry reg;
    register_tooling_commands(reg, t.str());
    CHECK(reg.has("perf.measure"));
    CHECK(reg.has("perf.check"));
    CHECK(reg.has("perf.baseline"));

    CommandResult none = reg.call("perf.check", Json::object({{"file", "perf.json"}}));
    REQUIRE_FALSE(none.ok);  // no budget file: the error says how to create it
    CHECK(none.error["hint"].get<std::string>().find("perf.baseline") != std::string::npos);

    CommandResult b = reg.call("perf.baseline", Json::object({{"frames", 30}, {"repeats", 1}}));
    REQUIRE(b.ok);
    CHECK(b.result["created"] == true);
    auto file = load_json_file((std::filesystem::path(t.str()) / "perf.json").generic_string());
    REQUIRE(file.ok());
    const std::string runner = b.result["runner"].get<std::string>();
    CHECK(file.value()["runners"].contains(runner));
    CHECK(file.value()["frames"] == 30);

    // Same game, same runner: within the budget (CI or not).
    CommandResult c = reg.call("perf.check", Json::object({{"strictTime", false}}));
    REQUIRE(c.ok);
    CHECK((c.result["status"] == "pass" || c.result["status"] == "warn"));

    // Lower the baseline's memory below what the game needs: the check fails with a code that teaches.
    Json lowered = file.value();
    lowered["runners"][runner]["peakMemoryMB"] = 1;
    REQUIRE(fs::write_text((std::filesystem::path(t.str()) / "perf.json").generic_string(), dump_json(lowered)).ok());
    CommandResult f = reg.call("perf.check", Json::object());
    REQUIRE_FALSE(f.ok);
    CHECK(f.error["code"] == "perf_budget_exceeded");
    CHECK(f.error["message"].get<std::string>().find("peakMemoryMB") != std::string::npos);

    // A runner with no entry passes and prints the entry to commit.
    Json other = file.value();
    other["runners"] = Json::object({{"some-other-runner", other["runners"][runner]}});
    REQUIRE(fs::write_text((std::filesystem::path(t.str()) / "perf.json").generic_string(), dump_json(other)).ok());
    CommandResult n = reg.call("perf.check", Json::object());
    REQUIRE(n.ok);
    CHECK(n.result["status"] == "no_baseline");
    CHECK(n.result["baselineEntry"].contains(runner));
    // ...unless the caller requires one (the engine's CI): then it fails with the same entry to commit.
    CommandResult r = reg.call("perf.check", Json::object({{"requireBaseline", true}}));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "perf_no_baseline");
    CHECK(r.error["message"].get<std::string>().find(runner) != std::string::npos);
}
