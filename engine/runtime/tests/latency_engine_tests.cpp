// M78-P6a: low latency in the engine (docs/LATENCY.md): the project key, the command render.latency and Engine::set_latency. The
// SDKs and the pacing are tested in engine/render/tests/latency_tests.cpp with fakes; a headless run paces nothing, so here the setting
// is read, written, refused and reported.
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <string>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/project.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name, const std::string& renderBlock = "") {
        dir = fs::make_temp_dir("fa_latency_test_" + name).value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary)
            << R"({ "format": "factoria.project/1", "name": "Latency Test", "id": "com.example.latency",
  "mainScene": "scenes/main.scene.json", "display": { "width": 320, "height": 180, "scaleMode": "fit" })"
            << renderBlock << "\n}";
        std::ofstream(dir / "scenes" / "main.scene.json", std::ios::binary)
            << R"({ "format": "factoria.scene/1", "entities": [ { "id": "cam", "components": { "Camera": {} } } ] })";
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    std::string path() const { return dir.generic_string(); }
};

EngineConfig cfg(const TempProject& p) {
    EngineConfig c;
    c.projectDir = p.path();
    c.headless = true;
    c.hotReload = false;
    return c;
}

}  // namespace

TEST_CASE("project: render.latency loads, round-trips, defaults to off and teaches with the pointer") {
    TempProject plain("plain");
    auto s = load_project(plain.path());
    REQUIRE(s.ok());
    CHECK(s->latency == render::LatencySettings{});
    CHECK_FALSE(s->to_json().contains("render"));

    TempProject set("set", R"(, "render": { "latency": { "mode": "xell", "boost": true } })");
    auto t = load_project(set.path());
    REQUIRE_MESSAGE(t.ok(), t.error().message);
    CHECK(t->latency.mode == render::LatencyMode::Xell);
    CHECK(t->latency.boost);
    const Json j = t->to_json();
    REQUIRE(j.contains("render"));
    CHECK(j["render"]["latency"]["mode"] == "xell");
    CHECK(j["render"]["latency"]["boost"] == true);

    TempProject bad("bad", R"(, "render": { "latency": { "mode": "antilag" } })");
    auto b = load_project(bad.path());
    REQUIRE_FALSE(b.ok());
    CHECK(b.error().message.find("/render/latency/mode") != std::string::npos);
    CHECK(b.error().hint.find("antilag2") != std::string::npos);  // did you mean

    TempProject badKey("badkey", R"(, "render": { "latency": { "boosts": true } })");
    auto k = load_project(badKey.path());
    REQUIRE_FALSE(k.ok());
    CHECK(k.error().message.find("/render/latency/boosts") != std::string::npos);
}

TEST_CASE("render.latency: reads, sets, and refuses without changing anything (headless: remembered, nothing paced)") {
    TempProject p("command");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto r = c.call("render.latency", Json::object());
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["mode"] == "off");
    CHECK(r.result["boost"] == false);
    CHECK(r.result["driver"] == "none");
    CHECK(r.result["changed"] == false);
    CHECK(r.result.contains("report"));

    r = c.call("render.latency", Json::parse(R"({"mode":"auto","boost":true})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["mode"] == "auto");
    CHECK(r.result["boost"] == true);
    CHECK(r.result["changed"] == true);
    CHECK(r.result["driver"] == "none");  // no window: nothing to pace
    CHECK(r.result["reason"].get<std::string>().find("headless") != std::string::npos);
    CHECK(e.latency().mode == render::LatencyMode::Auto);

    // The same value again changes nothing, and a key that is not given is kept.
    r = c.call("render.latency", Json::parse(R"({"mode":"auto"})"));
    REQUIRE(r.ok);
    CHECK(r.result["changed"] == false);
    CHECK(r.result["boost"] == true);

    // Wrong calls teach and change nothing.
    r = c.call("render.latency", Json::parse(R"({"mode":"antilag"})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("antilag2") != std::string::npos);
    r = c.call("render.latency", Json::parse(R"({"mood":"off"})"));
    REQUIRE_FALSE(r.ok);
    r = c.call("render.latency", Json::parse(R"({"boost":3})"));
    REQUIRE_FALSE(r.ok);
    r = c.call("render.latency", Json::object());
    REQUIRE(r.ok);
    CHECK(r.result["mode"] == "auto");
    CHECK(r.result["boost"] == true);
}

TEST_CASE("project: a render.latency start value is the setting the engine starts with") {
    TempProject p("start", R"(, "render": { "latency": { "mode": "antilag2" } })");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    CHECK(e.latency().mode == render::LatencyMode::AntiLag2);
    auto r = e.commands().call("render.latency", Json::object());
    REQUIRE(r.ok);
    CHECK(r.result["mode"] == "antilag2");
    CHECK(r.result["driver"] == "none");
}
