// M79-P0a: ray tracing settings in the engine (docs/RAY_TRACING.md): the project key render.rayTracing, the command render.ray_tracing and
// Engine::set_ray_tracing. No effect draws with rays yet, so the setting is read, written, refused and reported (`active` false, with the
// reason); the renderer's own rows are tested in engine/render/tests/raytracing_tests.cpp.
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <string>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/internal/engine_impl.h"
#include "fa/runtime/project.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name, const std::string& renderBlock = "") {
        dir = fs::make_temp_dir("fa_raytracing_test_" + name).value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary)
            << R"({ "format": "factoria.project/1", "name": "Ray Tracing Test", "id": "com.example.raytracing",
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

bool contains(const std::string& s, const std::string& part) { return s.find(part) != std::string::npos; }

}  // namespace

TEST_CASE("project: render.rayTracing loads, round-trips, defaults to off and teaches with the pointer") {
    TempProject plain("plain");
    auto s = load_project(plain.path());
    REQUIRE(s.ok());
    CHECK(s->rayTracing == render::RayTracingSettings{});
    CHECK_FALSE(s->to_json().contains("render"));  // off writes nothing

    TempProject set(
        "set",
        R"(, "render": { "rayTracing": { "enabled": true, "shadows": "soft", "gi": "probes", "raysPerPixel": 99 } })");
    auto t = load_project(set.path());
    REQUIRE_MESSAGE(t.ok(), t.error().message);
    CHECK(t->rayTracing.enabled);
    CHECK(t->rayTracing.shadows == render::RtShadows::Soft);
    CHECK(t->rayTracing.gi == render::RtGi::Probes);
    CHECK(t->rayTracing.raysPerPixel == 16);  // clamped
    const Json j = t->to_json();
    REQUIRE(j.contains("render"));
    CHECK(j["render"]["rayTracing"]["shadows"] == "soft");
    CHECK(j["render"]["rayTracing"]["raysPerPixel"] == 16);

    TempProject bad("bad", R"(, "render": { "rayTracing": { "shadows": "sofft" } })");
    auto b = load_project(bad.path());
    REQUIRE_FALSE(b.ok());
    CHECK(contains(b.error().message, "/render/rayTracing/shadows"));
    CHECK(contains(b.error().hint, "soft"));  // did you mean

    TempProject badKey("badkey", R"(, "render": { "rayTracing": { "reflection": true } })");
    auto k = load_project(badKey.path());
    REQUIRE_FALSE(k.ok());
    CHECK(contains(k.error().message, "/render/rayTracing/reflection"));
    CHECK(contains(k.error().hint, "reflections"));

    TempProject badType("badtype", R"(, "render": { "rayTracing": { "enabled": "yes" } })");
    auto y = load_project(badType.path());
    REQUIRE_FALSE(y.ok());
    CHECK(contains(y.error().message, "/render/rayTracing/enabled"));
}

TEST_CASE("render.ray_tracing: reads, sets and refuses without changing anything (no effect traces yet: active is "
          "false and says why)") {
    TempProject p("command");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    CHECK(c.info("render.ray_tracing") != nullptr);

    auto r = c.call("render.ray_tracing", Json::object());
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["enabled"] == false);
    CHECK(r.result["shadows"] == "off");
    CHECK(r.result["gi"] == "off");
    CHECK(r.result["raysPerPixel"] == 1);
    CHECK(r.result["maxInstances"] == 65536);
    // Whether this machine's GPU can trace rays (a Mac with Metal ray tracing says true, a runner without says false and why):
    // `active` is false while no effect is on, whatever the device.
    REQUIRE(r.result["supported"].is_boolean());
    CHECK(r.result["active"] == false);
    CHECK(r.result["changed"] == false);
    CHECK(r.result["reason"] == "");  // off: nothing to explain

    r = c.call("render.ray_tracing", Json::parse(R"({"enabled":true,"shadows":"hard","raysPerPixel":4})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["enabled"] == true);
    CHECK(r.result["shadows"] == "hard");
    CHECK(r.result["raysPerPixel"] == 4);
    CHECK(r.result["changed"] == true);
    CHECK(r.result["active"] == r.result["supported"]);          // the shadows are on: traced where the device traces
    CHECK_FALSE(r.result["reason"].get<std::string>().empty());  // the device's reason, or what is traced
    // A device that cannot trace says why (its own reason, never an empty string).
    if (!r.result["supported"].get<bool>()) CHECK(r.result["reason"].get<std::string>().size() > 10);
    CHECK(e.ray_tracing().shadows == render::RtShadows::Hard);

    // The same value again changes nothing, and a key that is not given is kept; numbers are clamped.
    r = c.call("render.ray_tracing", Json::parse(R"({"shadows":"hard","maxInstances":99999999})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["changed"] == true);  // maxInstances moved (clamped to 1048576)
    CHECK(r.result["maxInstances"] == 1048576);
    CHECK(r.result["raysPerPixel"] == 4);
    r = c.call("render.ray_tracing", Json::parse(R"({"shadows":"hard"})"));
    REQUIRE(r.ok);
    CHECK(r.result["changed"] == false);

    // Wrong calls teach and change nothing.
    r = c.call("render.ray_tracing", Json::parse(R"({"shadows":"sofft"})"));
    REQUIRE_FALSE(r.ok);
    CHECK(contains(r.error.dump(), "soft"));
    r = c.call("render.ray_tracing", Json::parse(R"({"raysPerPixel":1.5})"));
    REQUIRE_FALSE(r.ok);
    r = c.call("render.ray_tracing", Json::parse(R"({"enable":true})"));
    REQUIRE_FALSE(r.ok);
    r = c.call("render.ray_tracing", Json::object());
    REQUIRE(r.ok);
    CHECK(r.result["shadows"] == "hard");
    CHECK(r.result["raysPerPixel"] == 4);
    e.shutdown();
}

TEST_CASE("project: a render.rayTracing start value is the setting the engine starts with") {
    TempProject p("start", R"(, "render": { "rayTracing": { "enabled": true, "ao": true, "gi": "perPixel" } })");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    CHECK(e.ray_tracing().enabled);
    CHECK(e.ray_tracing().ao);
    CHECK(e.ray_tracing().gi == render::RtGi::PerPixel);
    auto r = e.commands().call("render.ray_tracing", Json::object());
    REQUIRE(r.ok);
    CHECK(r.result["gi"] == "perPixel");
    e.shutdown();
}

TEST_CASE(
    "render.ray_tracing: with only ao on, active follows the device and the reason names the occlusion of the main "
    "camera, not the shadows") {
    TempProject p("aoonly");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto r = c.call("render.ray_tracing", Json::parse(R"({"enabled":true,"ao":true})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["shadows"] == "off");
    CHECK(r.result["ao"] == true);
    CHECK(r.result["active"] == r.result["supported"]);  // ao alone is an effect that draws with rays
    const std::string reason = r.result["reason"].get<std::string>();
    REQUIRE_FALSE(reason.empty());
    if (r.result["supported"].get<bool>()) {
        CHECK(contains(reason, "ambient occlusion"));
        CHECK(contains(reason, "main camera"));
        CHECK_FALSE(contains(reason, "shadow"));
        CHECK_FALSE(contains(reason, "every world camera"));
    }
    // Shadows too: both are named, each as the main camera's.
    r = c.call("render.ray_tracing", Json::parse(R"({"shadows":"hard"})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    if (r.result["supported"].get<bool>()) {
        const std::string both = r.result["reason"].get<std::string>();
        CHECK(contains(both, "shadow"));
        CHECK(contains(both, "ambient occlusion"));
        CHECK_FALSE(contains(both, "every world camera"));
    }
    // ao off again with shadows on: the occlusion is no longer named.
    r = c.call("render.ray_tracing", Json::parse(R"({"ao":false})"));
    REQUIRE(r.ok);
    if (r.result["supported"].get<bool>()) CHECK_FALSE(contains(r.result["reason"].get<std::string>(), "occlusion"));
    e.shutdown();
}
