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

TEST_CASE("perf_compare: render numbers are budgeted only when the baseline recorded them") {
    PerfSample measured = sample(5, 8, 100, 40, 200);
    measured.triangles = 5000;
    measured.lights = 4;
    measured.textureMB = 20;
    PerfSample old = sample(5, 8, 100, 40, 200);  // a baseline from before the render numbers: triangles = -1
    CHECK(old.triangles < 0);
    PerfVerdict v = perf_compare(measured, old, PerfTolerance{}, true);
    CHECK(v.status == "pass");
    CHECK(row(v, "triangles") == nullptr);
    CHECK(row(v, "lights") == nullptr);
    CHECK(row(v, "textureMB") == nullptr);
    // A baseline that has them: the scene going over fails.
    PerfSample base = old;
    base.triangles = 5000;
    base.lights = 4;
    base.textureMB = 20;
    CHECK(perf_compare(measured, base, PerfTolerance{}, true).status == "pass");
    measured.triangles = 9000;
    v = perf_compare(measured, base, PerfTolerance{}, false);
    CHECK(v.status == "fail");
    REQUIRE(row(v, "triangles") != nullptr);
    CHECK(row(v, "triangles")->exceeded);
    CHECK(row(v, "triangles")->limit == doctest::Approx(5500));
    // The file round-trips without inventing fields the baseline never had.
    CHECK_FALSE(perf_sample_json(old).contains("triangles"));
    CHECK(perf_sample_from_json(perf_sample_json(old)).triangles < 0);
    CHECK(perf_sample_from_json(perf_sample_json(base)).triangles == 5000);
}

TEST_CASE("perf budgets: absolute caps, unknown keys teach") {
    std::vector<std::string> problems;
    const PerfBudgets b = perf_budgets_from_json(Json::parse(R"({"maxTriangles":100,"maxLight":3})"), &problems);
    CHECK(b.maxTriangles == 100);
    REQUIRE(problems.size() == 1);
    CHECK(problems[0].find("maxLights") != std::string::npos);  // did you mean
    PerfSample m = sample(1, 1, 50, 10, 10);
    m.triangles = 101;
    m.lights = 1;
    m.textureMB = 1;
    const auto rows = perf_budget_rows(m, b);
    REQUIRE(rows.size() == 1);
    CHECK(rows[0].metric == "maxTriangles");
    CHECK(rows[0].exceeded);
    m.triangles = 100;
    CHECK_FALSE(perf_budget_rows(m, b)[0].exceeded);
    CHECK(perf_budget_rows(m, PerfBudgets{}).empty());
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
    // A CI runner without a graphics card gets WARP as its "hardware" adapter: the same runner id.
    CHECK(perf_runner_id("D3D11 hardware / Microsoft Basic Render Driver (feature level 0xb100)") == warp);
    CHECK(perf_runner_id("EGL surfaceless / llvmpipe (LLVM 19)").find("-llvmpipe") != std::string::npos);
    CHECK(perf_runner_id("Metal / Apple M1").find("-metal") != std::string::npos);
    CHECK(perf_runner_id("none").find("-nogpu") != std::string::npos);
    CHECK(perf_runner_id("D3D11 hardware / AMD Radeon").find("-d3d11") != std::string::npos);
    const std::string id = perf_runner_id("none");
#if defined(NDEBUG)
    CHECK_FALSE(id.ends_with("-debug"));
#else
    CHECK(id.ends_with("-nogpu-debug"));  // a Debug build is a kind of its own: it never meets a release build's baseline
#endif
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

TEST_CASE("perf_runner_id: GitHub's macOS VM and a Mac's own GPU are different kinds") {
#if defined(_WIN32)
    _putenv_s("FACTORIA_PERF_RUNNER", "");
#else
    unsetenv("FACTORIA_PERF_RUNNER");
#endif
    // The CI runner's Metal device costs ~6 MB less memory than an M5 on the same build: a baseline of one would fail the other.
    const std::string vm = perf_runner_id("Metal / Apple Paravirtual device");
    const std::string mac = perf_runner_id("Metal / Apple M5");
    CHECK(vm != mac);
#if defined(NDEBUG)
    CHECK(vm.ends_with("-metal-paravirtual"));
    CHECK(mac.ends_with("-metal"));
#else
    CHECK(vm.ends_with("-metal-paravirtual-debug"));
    CHECK(mac.ends_with("-metal-debug"));
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

TEST_CASE("perf.profile: where the time goes, on a small project with two behaviours") {
    TempDir t;
    auto made = create_project(t.str(), "2d-empty");
    REQUIRE(made.ok());
    const std::filesystem::path dir(t.str());
    REQUIRE(fs::write_text((dir / "scripts/heavy.js").generic_string(),
                           "import { Behaviour } from \"factoria\";\n"
                           "export default class Heavy extends Behaviour {\n"
                           "  onUpdate(dt) { let x = 0; for (let i = 0; i < 150000; i++) x += Math.sqrt(i); this.x = x; }\n}\n").ok());
    REQUIRE(fs::write_text((dir / "scripts/light.js").generic_string(),
                           "import { Behaviour } from \"factoria\";\n"
                           "export default class Light extends Behaviour {\n  onUpdate(dt) {}\n}\n").ok());
    REQUIRE(fs::write_text((dir / "scenes/main.scene.json").generic_string(), R"({
      "format": "factoria.scene/1",
      "entities": [
        { "id": "cam", "components": { "Camera": { "primary": true } } },
        { "id": "heavy", "components": { "Script": { "path": "scripts/heavy.js" } } },
        { "id": "light", "components": { "Script": { "path": "scripts/light.js" } } }
      ] })").ok());
    CommandRegistry reg;
    register_tooling_commands(reg, t.str());
    REQUIRE(reg.has("perf.profile"));

    CommandResult bad = reg.call("perf.profile", Json::object({{"frames", 0}}));
    REQUIRE_FALSE(bad.ok);
    CHECK_FALSE(bad.error["hint"].get<std::string>().empty());

    CommandResult r = reg.call("perf.profile", Json::object({{"frames", 20}, {"warmup", 3}}));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK_FALSE(r.result["runner"].get<std::string>().empty());
    const Json& p = r.result["profile"];
    CHECK(p["frames"] == 20);
    REQUIRE(p["behaviours"].size() >= 2);
    CHECK(p["behaviours"][0]["class"] == "Heavy");  // the slowest first
    const Json* light = nullptr;
    for (const Json& b : p["behaviours"])
        if (b["class"] == "Light") light = &b;
    REQUIRE(light);  // (the bucket for timers and events may rank above it: both are almost free)
    CHECK(p["behaviours"][0]["avgMs"].get<double>() > (*light)["avgMs"].get<double>());
    CHECK(p["behaviours"][0]["callsPerFrame"].get<double>() == doctest::Approx(1.0));
    CHECK(p["systems"].contains("scriptsUpdate"));
    CHECK(p["systems"].contains("render"));
    CHECK(p["gpu"].contains("reason"));
}

TEST_CASE("perf.profile and perf.measure from an engine that owns the GPU: a teaching error, not an abort") {
    TempDir t;
    REQUIRE(create_project(t.str(), "2d-empty").ok());
    Engine host;  // stands for the editor / a window: this process now owns a graphics device (when the machine has one)
    EngineConfig cfg;
    cfg.projectDir = t.str();
    cfg.headless = true;
    cfg.hotReload = false;
    cfg.memoryStorage = true;
    std::string err;
    REQUIRE_MESSAGE(host.init(cfg, nullptr, &err), err);
    CommandRegistry reg;
    register_tooling_commands(reg, t.str());
    for (const char* name : {"perf.profile", "perf.measure"}) {
        CommandResult r = reg.call(name, Json::object({{"frames", 3}}));
        if (host.renderer()) {
            REQUIRE_FALSE(r.ok);
            CHECK(r.error["code"] == "gpu_busy");
            CHECK(r.error["hint"].get<std::string>().find("--no-graphics") != std::string::npos);
        } else {
            CHECK(r.ok);  // no GPU on this machine: nothing to clash with
        }
    }
    host.shutdown();
}

TEST_CASE("perf.check: a triangle budget fails when the scene goes over it") {
    TempDir t;
    auto made = create_project(t.str(), "2d-empty");
    REQUIRE(made.ok());
    const std::filesystem::path root(t.str());
    // Five meshes under a camera and a sun.
    const std::string scene = R"({"format":"factoria.scene/1","entities":[
      {"id":"camera","components":{"Transform":{"position":[0,3,8],"rotation":[-15,0,0]},"Camera":{"projection":"perspective","primary":true}}},
      {"id":"sun","components":{"Transform":{"rotation":[-50,-30,0]},"Light":{"type":"directional"}}},
      {"id":"floor","components":{"Transform":{"scale":[20,1,20]},"MeshRenderer":{"mesh":"plane"}}},
      {"id":"c1","components":{"Transform":{"position":[-2,1,0]},"MeshRenderer":{"mesh":"cube"}}},
      {"id":"c2","components":{"Transform":{"position":[2,1,0]},"MeshRenderer":{"mesh":"cube"}}}]})";
    auto project = load_json_file((root / "factoria.json").generic_string());
    REQUIRE(project.ok());
    const std::string mainScene = project.value()["mainScene"].get<std::string>();
    REQUIRE(fs::write_text((root / mainScene).generic_string(), scene).ok());
    CommandRegistry reg;
    register_tooling_commands(reg, t.str());
    CommandResult m = reg.call("perf.measure", Json::object({{"frames", 5}}));
    REQUIRE_MESSAGE(m.ok, m.error.dump());
    const Json& sample = m.result["sample"];
    CHECK(sample.contains("triangles"));
    CHECK(sample.contains("lights"));
    CHECK(sample.contains("textureMB"));
    const int triangles = sample["triangles"].get<int>();
    if (triangles == 0) return;  // no GPU on this machine: nothing is drawn, so there is nothing to put over a budget
    CHECK(triangles == 26);
    CHECK(sample["lights"] == 1);
    REQUIRE(fs::write_text((root / "perf.json").generic_string(),
                           R"({"format":"factoria.perf/1","frames":5,"budgets":{"maxTriangles":26,"maxLights":1}})").ok());
    CommandResult ok = reg.call("perf.check", Json::object());  // no baseline for this runner: the caps still apply
    REQUIRE_MESSAGE(ok.ok, ok.error.dump());
    CHECK(ok.result["status"] == "no_baseline");
    // The scene goes over a lower cap (file or argument): fails with the numbers.
    CommandResult over = reg.call("perf.check", Json::object({{"budgets", Json::object({{"maxTriangles", 25}})}}));
    REQUIRE_FALSE(over.ok);
    CHECK(over.error["code"] == "perf_budget_exceeded");
    CHECK(over.error["message"].get<std::string>().find("maxTriangles 26 > budget 25") != std::string::npos);
    // A typo in a budget name teaches.
    CommandResult typo = reg.call("perf.check", Json::object({{"budgets", Json::object({{"maxTriangels", 25}})}}));
    REQUIRE_FALSE(typo.ok);
    CHECK(typo.error["message"].get<std::string>().find("maxTriangles") != std::string::npos);
    // With a baseline of this runner, an old one without render numbers keeps passing.
    CommandResult b = reg.call("perf.baseline", Json::object({{"frames", 5}, {"repeats", 1}}));
    REQUIRE(b.ok);
    auto file = load_json_file((root / "perf.json").generic_string());
    REQUIRE(file.ok());
    Json old = file.value();
    const std::string runner = b.result["runner"].get<std::string>();
    old["runners"][runner].erase("triangles");
    old["runners"][runner].erase("lights");
    old["runners"][runner].erase("textureMB");
    old.erase("budgets");
    REQUIRE(fs::write_text((root / "perf.json").generic_string(), dump_json(old)).ok());
    CommandResult pass = reg.call("perf.check", Json::object({{"strictTime", false}}));
    REQUIRE_MESSAGE(pass.ok, pass.error.dump());
    for (const Json& r : pass.result["rows"]) CHECK(r["metric"] != "triangles");
}
