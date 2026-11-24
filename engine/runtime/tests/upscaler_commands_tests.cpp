// M76: the engine-wide upscaler settings (project key, command, window.upscaler) and the graphics.* stubs.
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <string>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/render/renderer.h"
#include "fa/runtime/project.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

std::string project_text(const std::string& renderBlock, const std::string& scaleMode) {
    return std::string(R"({
  "format": "factoria.project/1",
  "name": "Upscaler Test",
  "id": "com.example.upscalertest",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": ")") +
           scaleMode + "\" }" + renderBlock + "\n}";
}

const char* kScene =
    R"({ "format": "factoria.scene/1", "entities": [ { "id": "cam", "components": { "Camera": {} } } ] })";

struct TempProject {
    stdfs::path dir;
    // The display's scale mode is "pixelPerfect" unless a test asks for another ("fit": the smooth scaling the spatial upscaler draws for).
    explicit TempProject(const std::string& name, const std::string& renderBlock = "",
                         const std::string& scaleMode = "pixelPerfect") {
        dir = fs::make_temp_dir("fa_upscaler_test_" + name).value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary) << project_text(renderBlock, scaleMode);
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

}  // namespace

TEST_CASE("project: render.upscaler loads, round-trips and defaults to stretch") {
    TempProject plain("plain");
    auto s = load_project(plain.path());
    REQUIRE(s.ok());
    CHECK(s->upscaler == render::UpscalerSettings{});
    CHECK_FALSE(s->to_json().contains("render"));

    TempProject set("set",
                    R"(, "render": { "upscaler": { "mode": "temporal", "quality": "balanced", "sharpness": 0.8 } })");
    auto t = load_project(set.path());
    REQUIRE_MESSAGE(t.ok(), t.error().message);
    CHECK(t->upscaler.mode == render::UpscalerMode::Temporal);
    CHECK(t->upscaler.quality == render::UpscalerQuality::Balanced);
    CHECK(t->upscaler.sharpness == doctest::Approx(0.8f));
    auto j = t->to_json();
    CHECK(j["render"]["upscaler"]["mode"] == "temporal");
    CHECK(j["render"]["upscaler"]["quality"] == "balanced");
    CHECK_FALSE(j["render"].contains("interpolation"));  // only what is not the default is written
}

TEST_CASE("project: a wrong render.upscaler teaches with the JSON pointer") {
    TempProject bad("bad", R"(, "render": { "upscaler": { "mode": "tempral" } })");
    auto s = load_project(bad.path());
    REQUIRE_FALSE(s.ok());
    const std::string text = s.error().message + " " + s.error().hint;
    CHECK(text.find("/render/upscaler") != std::string::npos);
    CHECK(text.find("temporal") != std::string::npos);

    TempProject range("range", R"(, "render": { "upscaler": { "sharpness": 2 } })");
    auto r = load_project(range.path());
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("sharpness") != std::string::npos);
}

TEST_CASE("render.upscaler: reports, sets, and refuses without changing anything") {
    TempProject p("cmd", R"(, "render": { "upscaler": { "mode": "spatial", "quality": "quality" } })");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    const CommandInfo* info = c.info("render.upscaler");
    REQUIRE(info != nullptr);
    CHECK_FALSE(info->readOnly);
    CHECK(info->description.size() < 1500);

    auto r = c.call("render.upscaler", Json::object());
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["mode"] == "spatial");
    CHECK(r.result["quality"] == "quality");
    // The display is pixel perfect: its hard pixels are kept, so the effective mode is stretch whatever is asked for; the scale is the quality's.
    CHECK(r.result["effectiveMode"] == "stretch");
    CHECK(r.result["scale"].get<double>() == doctest::Approx(1.0 / 1.5).epsilon(0.001));

    r = c.call("render.upscaler", Json::parse(R"({"mode":"temporal","quality":"performance","sharpness":0.25})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["mode"] == "temporal");
    CHECK(r.result["quality"] == "performance");
    CHECK(r.result["sharpness"].get<double>() == doctest::Approx(0.25));
    CHECK(r.result["scale"].get<double>() == doctest::Approx(0.5));
    CHECK(r.result["effectiveMode"] == "stretch");

    r = c.call("render.upscaler", Json::parse(R"({"mode":"tempral"})"));
    CHECK_FALSE(r.ok);
    CHECK(r.error.dump().find("temporal") != std::string::npos);
    r = c.call("render.upscaler", Json::parse(R"({"sharpness":3})"));
    CHECK_FALSE(r.ok);
    r = c.call("render.upscaler", Json::object());
    REQUIRE(r.ok);
    CHECK(r.result["mode"] == "temporal");
    CHECK(r.result["quality"] == "performance");
    e.shutdown();
}

TEST_CASE("window.upscaler reads and sets the same settings from a script") {
    TempProject p("js");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    CHECK(eval(e, "window.upscaler.mode") == "stretch");
    CHECK(eval(e, "window.upscaler.effectiveMode") == "stretch");
    eval(e, "window.upscaler = { mode: 'spatial', quality: 'ultraPerformance' }; 0");
    auto r = e.commands().call("render.upscaler", Json::object());
    REQUIRE(r.ok);
    CHECK(r.result["mode"] == "spatial");
    CHECK(r.result["quality"] == "ultraPerformance");
    CHECK(eval(e, "window.upscaler.scale").get<double>() == doctest::Approx(1.0 / 3.0).epsilon(0.001));
    auto bad = e.commands().call("script.eval", Json::object({{"code", "window.upscaler = { quality: 'ultra' }"}}));
    CHECK_FALSE(bad.ok);
    CHECK(eval(e, "window.upscaler.quality") == "ultraPerformance");
    e.shutdown();
}

TEST_CASE("the project's upscaler is applied when the engine starts") {
    TempProject p("start", R"(, "render": { "upscaler": { "mode": "metalfx", "quality": "native" } })");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto r = e.commands().call("render.upscaler", Json::object());
    REQUIRE(r.ok);
    CHECK(r.result["mode"] == "metalfx");
    CHECK(r.result["quality"] == "native");
    CHECK(r.result["effectiveMode"] == "stretch");
    // The renderer is created after the project settings are applied: it must hold the project's value too.
    REQUIRE(e.renderer() != nullptr);
    {
        CHECK(e.renderer()->upscaler().mode == render::UpscalerMode::MetalFx);
        CHECK(e.renderer()->upscaler().quality == render::UpscalerQuality::Native);
        // And a later change reaches it.
        r = e.commands().call("render.upscaler", Json::parse(R"({"mode":"spatial"})"));
        REQUIRE(r.ok);
        CHECK(e.renderer()->upscaler().mode == render::UpscalerMode::Spatial);
    }
    // A wrong value names the caller that was used.
    r = e.commands().call("render.upscaler", Json::parse(R"({"mode":"spatail"})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("render.upscaler") != std::string::npos);
    CHECK(r.error.dump().find("window.upscaler") == std::string::npos);
    e.shutdown();
}

TEST_CASE("render.upscaler: a quality below native draws the game smaller with the upscale stage on, temporal says so, "
          "native undoes it") {
    TempProject p("quality", "", "fit");  // pixel art (the default of these projects) is always stretch
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    REQUIRE(e.renderer() != nullptr);
    auto& c = e.commands();
    CHECK_FALSE(e.renderer()->upscale_stage());
    auto r = c.call("render.upscaler", Json::parse(R"({"mode":"temporal","quality":"performance"})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["effectiveMode"] == "temporal");  // M76-P4: drawn, as the renderer can draw it
    CHECK(e.renderer()->upscale_stage());
    CHECK(e.renderer()->effective_upscaler_mode() == render::UpscalerMode::Temporal);
    // Stretch at the same quality is the upscale stage with a plain scale-up.
    r = c.call("render.upscaler", Json::parse(R"({"mode":"stretch"})"));
    REQUIRE(r.ok);
    CHECK(r.result["effectiveMode"] == "stretch");
    CHECK(e.renderer()->upscale_stage());
    // Native: the whole size, no stage.
    r = c.call("render.upscaler", Json::parse(R"({"mode":"temporal","quality":"native"})"));
    REQUIRE(r.ok);
    CHECK_FALSE(e.renderer()->upscale_stage());
    e.shutdown();
}

TEST_CASE("graphics.preset and graphics.detect are stubs that say so") {
    TempProject p("stub");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    REQUIRE(c.info("graphics.preset") != nullptr);
    REQUIRE(c.info("graphics.detect") != nullptr);
    CHECK(c.info("graphics.detect")->readOnly);
    CHECK_FALSE(c.info("graphics.preset")->readOnly);
    auto r = c.call("graphics.detect", Json::object());
    CHECK_FALSE(r.ok);
    CHECK(r.error.dump().find("not built yet") != std::string::npos);
    r = c.call("graphics.preset", Json::parse(R"({"name":"high"})"));
    CHECK_FALSE(r.ok);
    CHECK(r.error.dump().find("not built yet") != std::string::npos);
    e.shutdown();
}

TEST_CASE("render.upscaler spatial changes the size drawn and the effective mode; pixel perfect keeps stretch") {
    TempProject p("spatial", "", "fit");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    REQUIRE(e.renderer() != nullptr);
    auto& c = e.commands();
    auto stats = [&]() {
        auto s = c.call("game.render_stats", Json::object());
        REQUIRE_MESSAGE(s.ok, s.error.dump());
        return s.result;
    };
    // The default: stretch at the design size, no stage.
    Json s0 = stats();
    CHECK(s0["width"] == 320);
    CHECK(s0["height"] == 180);
    CHECK(s0["renderScale"].get<double>() == doctest::Approx(1.0));
    CHECK_FALSE(e.renderer()->upscale_stage());

    auto r = c.call("render.upscaler", Json::parse(R"({"mode":"spatial","quality":"performance"})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["mode"] == "spatial");
    CHECK(r.result["effectiveMode"] == "spatial");
    CHECK(r.result["scale"].get<double>() == doctest::Approx(0.5));
    CHECK(e.renderer()->upscale_stage());
    CHECK(e.renderer()->effective_upscaler_mode() == render::UpscalerMode::Spatial);
    Json s1 = stats();
    CHECK(s1["width"] == 160);  // the size the game is drawn at, not the design size
    CHECK(s1["height"] == 90);
    CHECK(s1["renderScale"].get<double>() == doctest::Approx(0.5));
    CHECK(eval(e, "window.upscaler.effectiveMode") == "spatial");
    CHECK(eval(e, "window.upscaler.scale").get<double>() == doctest::Approx(0.5));

    // window.renderScale multiplies with the quality, down to the floor of 0.25.
    eval(e, "window.renderScale = 0.75; 0");
    Json s2 = stats();
    CHECK(s2["renderScale"].get<double>() == doctest::Approx(0.375));
    CHECK(s2["width"] == 120);
    // (window.renderScale itself is 0.33 .. 1.) 0.5 x 1/3 would be 0.167: below the floor.
    eval(e, "window.renderScale = 0.5; window.upscaler = { quality: 'ultraPerformance' }; 0");
    CHECK(stats()["renderScale"].get<double>() == doctest::Approx(0.25));
    CHECK(stats()["width"] == 80);
    CHECK(eval(e, "window.renderScale").get<double>() == doctest::Approx(0.5));  // the player's option is what was set
    eval(e, "window.upscaler = { quality: 'performance' }; 0");
    eval(e, "window.renderScale = 1; 0");

    // The scale of the quality is the same under temporal, metalfx and auto; auto picks the temporal upscaler (the best drawable here), and
    // metalfx draws as the next best until its own package lands.
    r = c.call("render.upscaler", Json::parse(R"({"mode":"auto"})"));
    REQUIRE(r.ok);
    CHECK(r.result["effectiveMode"] == "temporal");
    r = c.call("render.upscaler", Json::parse(R"({"mode":"metalfx"})"));
    REQUIRE(r.ok);
    CHECK(r.result["effectiveMode"] == "temporal");
    r = c.call("render.upscaler", Json::parse(R"({"mode":"spatial"})"));
    REQUIRE(r.ok);
    CHECK(r.result["effectiveMode"] == "spatial");

    // Back to stretch at native: no stage, the design size.
    r = c.call("render.upscaler", Json::parse(R"({"mode":"stretch","quality":"native"})"));
    REQUIRE(r.ok);
    CHECK(r.result["effectiveMode"] == "stretch");
    CHECK_FALSE(e.renderer()->upscale_stage());
    Json s3 = stats();
    CHECK(s3["width"] == 320);
    CHECK(s3["renderScale"].get<double>() == doctest::Approx(1.0));

    // Spatial at native with a sharpness: the stage runs for the sharpen alone at the design size; with sharpness 0 it does not.
    r = c.call("render.upscaler", Json::parse(R"({"mode":"spatial","sharpness":0.5})"));
    REQUIRE(r.ok);
    CHECK(e.renderer()->upscale_stage());
    CHECK(stats()["width"] == 320);
    e.shutdown();
}

TEST_CASE("render.upscaler on a pixel-perfect display: the quality still sets the size, the mode stays stretch") {
    TempProject p("pixel");  // scaleMode pixelPerfect
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    REQUIRE(e.renderer() != nullptr);
    auto r = e.commands().call("render.upscaler", Json::parse(R"({"mode":"spatial","quality":"performance"})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["mode"] == "spatial");
    CHECK(r.result["effectiveMode"] == "stretch");
    CHECK(e.renderer()->effective_upscaler_mode() == render::UpscalerMode::Stretch);
    auto s = e.commands().call("game.render_stats", Json::object());
    REQUIRE(s.ok);
    CHECK(s.result["width"] == 160);
    CHECK(s.result["height"] == 90);
    e.shutdown();
}

TEST_CASE("without a renderer effectiveMode is what a GPU would draw: pixel perfect is stretch, smooth scaling follows "
          "the setting") {
    const char* spatial = R"(, "render": { "upscaler": { "mode": "spatial", "quality": "quality" } })";
    {
        TempProject p("nogpu_pixel", spatial, "pixelPerfect");
        EngineConfig c = cfg(p);
        c.graphics = false;
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
        REQUIRE(e.renderer() == nullptr);
        auto r = e.commands().call("render.upscaler", Json::object());
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["mode"] == "spatial");
        CHECK(r.result["effectiveMode"] == "stretch");
        CHECK(eval(e, "window.upscaler.effectiveMode") == "stretch");
    }
    {
        TempProject p("nogpu_fit", spatial, "fit");
        EngineConfig c = cfg(p);
        c.graphics = false;
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
        REQUIRE(e.renderer() == nullptr);
        auto r = e.commands().call("render.upscaler", Json::object());
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["effectiveMode"] == "spatial");
        CHECK(eval(e, "window.upscaler.effectiveMode") == "spatial");
        r = e.commands().call("render.upscaler", Json::parse(R"({"mode":"stretch"})"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["effectiveMode"] == "stretch");
    }
}
