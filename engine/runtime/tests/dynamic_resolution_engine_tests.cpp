// M76-P6c: dynamic resolution in the engine (docs/UPSCALING.md, "Dynamic resolution"): the project key, the command, window.dynamicResolution, the render
// stats, and the controller fed injected frame times (Engine::set_dynamic_resolution_frame_ms): the scale moves, the image is the one of a fixed scale of
// the same size, and off draws what a build without the feature draws.
#include <doctest.h>

#include <filesystem>
#include <functional>
#include <fstream>
#include <string>

#include "fa/core/fs.h"
#include "fa/render/renderer.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/project.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kScene = R"({ "format": "factoria.scene/1", "entities": [
  { "id": "cam", "components": { "Camera": {} } },
  { "id": "a", "components": { "Transform": { "position": [-40, 10] }, "Sprite": { "size": [60, 40], "color": "#d04020" } } },
  { "id": "b", "components": { "Transform": { "position": [50, -20] }, "Sprite": { "size": [30, 70], "color": "#2060d0" } } } ] })";

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name, const std::string& renderBlock = "") {
        dir = fs::make_temp_dir("fa_dynres_test_" + name).value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary)
            << R"({ "format": "factoria.project/1", "name": "Dyn Res Test", "id": "com.example.dynres",
  "mainScene": "scenes/main.scene.json", "display": { "width": 320, "height": 180, "scaleMode": "fit" })"
            << renderBlock << "\n}";
        std::ofstream(dir / "scenes" / "main.scene.json", std::ios::binary) << kScene;
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

Json eval(Engine& e, const std::string& code) {
    auto r = e.commands().call("script.eval", Json::object({{"code", code}}));
    INFO(code << " -> " << r.error.dump());
    REQUIRE(r.ok);
    return r.result["value"];
}

Json stats(Engine& e) {
    auto s = e.commands().call("game.render_stats", Json::object());
    REQUIRE_MESSAGE(s.ok, s.error.dump());
    return s.result;
}

}  // namespace

TEST_CASE("project: render.dynamicResolution loads, round-trips, defaults to off and teaches with the pointer") {
    TempProject plain("plain");
    auto s = load_project(plain.path());
    REQUIRE(s.ok());
    CHECK(s->dynamicResolution == render::DynamicResolutionSettings{});
    CHECK_FALSE(s->to_json().contains("render"));

    TempProject set("set", R"(, "render": { "dynamicResolution": { "enabled": true, "targetMs": 33.3, "minScale": 0.6 } })");
    auto t = load_project(set.path());
    REQUIRE_MESSAGE(t.ok(), t.error().message);
    CHECK(t->dynamicResolution.enabled);
    CHECK(t->dynamicResolution.targetMs == doctest::Approx(33.3));
    CHECK(t->dynamicResolution.minScale == doctest::Approx(0.6f));
    CHECK(t->dynamicResolution.maxScale == 1.0f);
    const Json j = t->to_json();
    REQUIRE(j.contains("render"));
    CHECK(j["render"]["dynamicResolution"]["enabled"] == true);

    TempProject bad("bad", R"(, "render": { "dynamicResolution": { "minScale": 0.1 } })");
    auto b = load_project(bad.path());
    REQUIRE_FALSE(b.ok());
    CHECK(b.error().message.find("/render/dynamicResolution/minScale") != std::string::npos);
    CHECK(b.error().message.find("0.25..1") != std::string::npos);
}

TEST_CASE("render.dynamic_resolution: reads, sets, and refuses without changing anything") {
    TempProject p("command");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto r = c.call("render.dynamic_resolution", Json::object());
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["enabled"] == false);
    CHECK(r.result["scale"].get<double>() == doctest::Approx(1.0));
    CHECK(r.result["source"] == "none");
    CHECK(r.result["changed"] == false);

    r = c.call("render.dynamic_resolution", Json::parse(R"({"enabled":true,"targetMs":33.3,"minScale":0.6})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["enabled"] == true);
    CHECK(r.result["changed"] == true);
    CHECK(r.result["effectiveTargetMs"].get<double>() == doctest::Approx(33.3));
    CHECK(r.result["minScale"].get<double>() == doctest::Approx(0.6));
    CHECK(r.result["maxScale"].get<double>() == doctest::Approx(1.0));
    // Following the display (60 Hz where the platform cannot tell).
    r = c.call("render.dynamic_resolution", Json::parse(R"({"targetMs":0})"));
    REQUIRE(r.ok);
    CHECK(r.result["effectiveTargetMs"].get<double>() == doctest::Approx(16.7));

    // Wrong calls teach and change nothing.
    for (const char* bad : {R"({"minScale":0.9,"maxScale":0.5})", R"({"targetMs":2})", R"({"enabled":"yes"})", R"({"enable":true})"}) {
        const Json before = c.call("render.dynamic_resolution", Json::object()).result;
        auto f = c.call("render.dynamic_resolution", Json::parse(bad));
        INFO(bad);
        REQUIRE_FALSE(f.ok);
        CHECK(f.error["code"].get<std::string>().rfind("invalid_argument", 0) == 0);
        CHECK(c.call("render.dynamic_resolution", Json::object()).result == before);
    }
    auto minmax = c.call("render.dynamic_resolution", Json::parse(R"({"minScale":0.9,"maxScale":0.5})"));
    CHECK(minmax.error["message"].get<std::string>().find("minScale 0.9 is above maxScale 0.5") != std::string::npos);

    auto sup = c.call("render.supports", Json::parse(R"({"feature":"dynamicResolution"})"));
    REQUIRE_MESSAGE(sup.ok, sup.error.dump());
    CHECK(sup.result.dump().find("planned") == std::string::npos);
    e.shutdown();
}

TEST_CASE("window.dynamicResolution reads and sets the same setting; window.upscaler reports the factor, read-only") {
    TempProject p("script");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    CHECK(eval(e, "window.dynamicResolution.enabled") == false);
    CHECK(eval(e, "window.upscaler.dynamicScale").get<double>() == doctest::Approx(1.0));
    CHECK(eval(e, "window.upscaler.frameMs").get<double>() == doctest::Approx(0.0));
    eval(e, "window.dynamicResolution = { enabled: true, targetMs: 16.7, minScale: 0.5 }; 0");
    CHECK(eval(e, "window.dynamicResolution.enabled") == true);
    CHECK(eval(e, "window.dynamicResolution.minScale").get<double>() == doctest::Approx(0.5));
    CHECK(eval(e, "window.dynamicResolution.effectiveTargetMs").get<double>() == doctest::Approx(16.7));
    CHECK(eval(e, "window.dynamicResolution.scale").get<double>() == doctest::Approx(1.0));
    // A wrong value throws and the setting stays; writing the read-only fields of window.upscaler changes nothing.
    auto bad = e.commands().call("script.eval", Json::object({{"code", "window.dynamicResolution = { minScale: 2 }"}}));
    CHECK_FALSE(bad.ok);
    CHECK(eval(e, "window.dynamicResolution.minScale").get<double>() == doctest::Approx(0.5));
    eval(e, "window.upscaler = { dynamicScale: 0.3, frameMs: 99, quality: 'native' }; 0");
    CHECK(eval(e, "window.upscaler.dynamicScale").get<double>() == doctest::Approx(1.0));
    e.shutdown();
}

TEST_CASE("the project's dynamic resolution is applied when the engine starts") {
    TempProject p("start", R"(, "render": { "dynamicResolution": { "enabled": true, "targetMs": 20 } })");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    CHECK(eval(e, "window.dynamicResolution.enabled") == true);
    CHECK(eval(e, "window.dynamicResolution.effectiveTargetMs").get<double>() == doctest::Approx(20.0));
    e.shutdown();
}

TEST_CASE("dynamic resolution with injected frame times: the scale follows the time, the stats report it, and it comes back") {
    TempProject p("inject");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    REQUIRE(e.renderer() != nullptr);
    auto& c = e.commands();
    REQUIRE(c.call("render.dynamic_resolution", Json::parse(R"({"enabled":true,"targetMs":16.7,"minScale":0.5})")).ok);
    // Enabled, nothing measured: the full size.
    CHECK(stats(e)["width"] == 320);
    CHECK(stats(e)["dynamicScale"].get<double>() == doctest::Approx(1.0));

    e.set_dynamic_resolution_frame_ms(40.0);  // every frame takes 40 ms: far over the target
    e.step(60 * 8);
    const Json heavy = stats(e);
    CHECK(heavy["dynamicScale"].get<double>() == doctest::Approx(0.5));
    CHECK(heavy["renderScale"].get<double>() == doctest::Approx(0.5));
    CHECK(heavy["width"] == 160);
    CHECK(heavy["height"] == 90);
    CHECK(heavy["frameMs"].get<double>() > 16.7);
    CHECK(e.renderer()->upscale_stage());
    CHECK(eval(e, "window.upscaler.dynamicScale").get<double>() == doctest::Approx(0.5));
    CHECK(eval(e, "window.dynamicResolution.source") == "injected");
    // window.renderScale is what the player set, not what is drawn.
    CHECK(eval(e, "window.renderScale").get<double>() == doctest::Approx(1.0));

    e.set_dynamic_resolution_frame_ms(5.0);  // the scene is light again
    e.step(60 * 40);
    const Json light = stats(e);
    CHECK(light["dynamicScale"].get<double>() == doctest::Approx(1.0));
    CHECK(light["width"] == 320);
    CHECK_FALSE(e.renderer()->upscale_stage());

    // Turned off, it is the fixed scale again whatever the controller had.
    e.set_dynamic_resolution_frame_ms(40.0);
    e.step(60 * 4);
    CHECK(stats(e)["dynamicScale"].get<double>() < 1.0);
    REQUIRE(c.call("render.dynamic_resolution", Json::parse(R"({"enabled":false})")).ok);
    CHECK(stats(e)["dynamicScale"].get<double>() == doctest::Approx(1.0));
    CHECK(stats(e)["width"] == 320);
    e.shutdown();
}

TEST_CASE("dynamic resolution multiplies into window.renderScale and the upscaler's quality, never below 0.25") {
    TempProject p("multiply");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    REQUIRE(c.call("render.upscaler", Json::parse(R"({"mode":"spatial","quality":"performance"})")).ok);  // 0.5
    REQUIRE(c.call("render.dynamic_resolution", Json::parse(R"({"enabled":true,"minScale":0.25})")).ok);
    e.set_dynamic_resolution_frame_ms(80.0);
    e.step(60 * 12);
    CHECK(stats(e)["dynamicScale"].get<double>() == doctest::Approx(0.25));
    CHECK(stats(e)["renderScale"].get<double>() == doctest::Approx(0.25));  // 0.5 x 0.25 = 0.125: the renderer's floor
    CHECK(stats(e)["width"] == 80);
    // The player's option is a part of the base: 0.8 x 0.5 x 0.25 is below the floor too, and the factor is still reported as it is.
    eval(e, "window.renderScale = 0.8; 0");
    CHECK(stats(e)["renderScale"].get<double>() == doctest::Approx(0.25));
    e.shutdown();
}

TEST_CASE("dynamic resolution: the picture is the one of a fixed scale of the same size; off and not measured are bit identical") {
    TempProject p("image");
    std::string err;
    // One engine at a time: the graphics layer is one per process.
    auto picture = [&](const std::function<void(Engine&)>& setup, Image& img) {
        Engine e;
        REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
        setup(e);
        const bool ok = e.capture_frame(img, &err);
        e.shutdown();
        return ok;
    };
    Image reference;
    if (!picture([](Engine&) {}, reference)) {
        MESSAGE("no picture can be captured on this machine's graphics: the image checks are skipped");
        return;
    }
    REQUIRE(reference.width > 0);

    // Off with the other keys set (enabled false), and on with nothing measured yet: the same pixels as a build without the feature.
    Image off, notMeasured;
    REQUIRE(picture([](Engine& e) { REQUIRE(e.commands().call("render.dynamic_resolution", Json::parse(R"({"targetMs":20,"minScale":0.3})")).ok); }, off));
    CHECK(off.width == reference.width);
    CHECK(off.rgba == reference.rgba);
    REQUIRE(picture([](Engine& e) { REQUIRE(e.commands().call("render.dynamic_resolution", Json::parse(R"({"enabled":true})")).ok); }, notMeasured));
    CHECK(notMeasured.rgba == reference.rgba);

    // The controller at its floor draws what window.renderScale 0.5 draws.
    Image dynamic, fixed;
    REQUIRE(picture(
        [](Engine& e) {
            REQUIRE(e.commands().call("render.dynamic_resolution", Json::parse(R"({"enabled":true,"minScale":0.5})")).ok);
            e.set_dynamic_resolution_frame_ms(60.0);
            e.step(60 * 8);
            REQUIRE(e.renderer()->render_scale() == doctest::Approx(0.5f));
        },
        dynamic));
    REQUIRE(picture([](Engine& e) { eval(e, "window.renderScale = 0.5; 0"); }, fixed));
    CHECK(dynamic.width == fixed.width);
    CHECK(dynamic.height == fixed.height);
    CHECK(dynamic.rgba == fixed.rgba);
    CHECK(dynamic.rgba != reference.rgba);  // and it is not the full-size picture
}
