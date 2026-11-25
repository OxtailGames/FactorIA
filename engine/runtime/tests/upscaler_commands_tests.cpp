// M76: the engine-wide upscaler settings (project key, command, window.upscaler) and the graphics presets (graphics.preset, graphics.detect, game.graphics, render.graphicsPreset).
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <string>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/render/graphics_preset.h"
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

TEST_CASE("rayReconstruction: the project's key, the command, the script and render.supports agree") {
    TempProject p("rr", R"(, "render": { "upscaler": { "mode": "dlss", "rayReconstruction": true } })");
    auto s = load_project(p.path());
    REQUIRE_MESSAGE(s.ok(), s.error().message);
    CHECK(s->upscaler.rayReconstruction);
    CHECK(s->to_json()["render"]["upscaler"]["rayReconstruction"] == true);
    TempProject bad("rrbad", R"(, "render": { "upscaler": { "rayReconstruction": "yes" } })");
    auto b = load_project(bad.path());
    REQUIRE_FALSE(b.ok());
    CHECK(b.error().message.find("/render/upscaler/rayReconstruction") != std::string::npos);

    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto r = c.call("render.upscaler", Json::object());
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["rayReconstruction"] == true);
    CHECK(eval(e, "window.upscaler.rayReconstruction") == true);
    r = c.call("render.upscaler", Json::parse(R"({"rayReconstruction":false})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["rayReconstruction"] == false);
    CHECK(r.result["mode"] == "dlss");
    eval(e, "window.upscaler = { rayReconstruction: true }; 0");
    CHECK(eval(e, "window.upscaler.rayReconstruction") == true);
    r = c.call("render.upscaler", Json::parse(R"({"rayReconstruction":"on"})"));
    CHECK_FALSE(r.ok);
    CHECK(r.error.dump().find("rayReconstruction") != std::string::npos);
    CHECK(eval(e, "window.upscaler.rayReconstruction") == true);  // the refusal changed nothing
    // The support row exists, and on this machine (no NVIDIA RTX, no Streamline) it says why it is not there.
    auto sup = c.call("render.supports", Json::parse(R"({"feature":"dlssRayReconstruction"})"));
    REQUIRE_MESSAGE(sup.ok, sup.error.dump());
    CHECK(sup.result["supported"] == false);
    CHECK(sup.result["status"].get<std::string>().find("Ray Reconstruction") != std::string::npos);
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
    r = c.call("render.upscaler", Json::parse(R"({"mode":"stretch","quality":"native"})"));
    REQUIRE(r.ok);
    CHECK_FALSE(e.renderer()->upscale_stage());
    // A temporal mode at native keeps the flag on (a frame with several cameras makes it spatial: the renderer decides each frame),
    // and draws nothing: the render size is the design size.
    r = c.call("render.upscaler", Json::parse(R"({"mode":"temporal","quality":"native"})"));
    REQUIRE(r.ok);
    CHECK(e.renderer()->upscale_stage());
    CHECK(e.renderer()->render_scale() == 1.0f);
    e.shutdown();
}

TEST_CASE("hold_render_scale after the player's render scale is a held size: no quality, no stage, until the player "
          "sets it again") {
    TempProject p("holdsize", "", "fit");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    REQUIRE(e.renderer() != nullptr);
    auto& c = e.commands();
    REQUIRE(c.call("render.upscaler", Json::parse(R"({"mode":"spatial","quality":"performance"})")).ok);
    eval(e, "window.renderScale = 0.75; 0");  // the player's option: 0.75 x 0.5
    CHECK(e.renderer()->upscale_stage());
    CHECK(e.renderer()->render_scale() == doctest::Approx(0.375f));
    // The video recorder or --render-scale: a size of its own, the quality does not multiply into it and the stage is off.
    REQUIRE_MESSAGE(e.hold_render_scale(2.0, &err), err);
    CHECK_FALSE(e.renderer()->upscale_stage());
    CHECK(e.renderer()->render_scale() == doctest::Approx(2.0f));
    // The same size again changes nothing; the player's option takes over again from a later set.
    REQUIRE_MESSAGE(e.hold_render_scale(2.0, &err), err);
    CHECK(e.renderer()->render_scale() == doctest::Approx(2.0f));
    eval(e, "window.renderScale = 0.75; 0");
    CHECK(e.renderer()->upscale_stage());
    CHECK(e.renderer()->render_scale() == doctest::Approx(0.375f));
    e.shutdown();
}

TEST_CASE("window.renderScale: the same value again, with a quality that is not native, recreates no target; a held "
          "size and the "
          "player's option in a row apply once each") {
    TempProject p("samescale", "", "fit");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    REQUIRE(e.renderer() != nullptr);
    auto& c = e.commands();
    REQUIRE(c.call("render.upscaler", Json::parse(R"({"mode":"spatial","quality":"performance"})")).ok);
    const std::uint32_t first = e.renderer()->game_target_texture().image;
    eval(e, "window.renderScale = 0.75; 0");  // 0.75 x 0.5: the targets are made once, at their final size
    const std::uint32_t scaled = e.renderer()->game_target_texture().image;
    CHECK(scaled != first);
    CHECK(e.renderer()->render_scale() == doctest::Approx(0.375f));
    // A settings menu or a slider that assigns the value it already has: nothing is rebuilt (the temporal history would start again).
    for (int i = 0; i < 3; ++i) {
        eval(e, "window.renderScale = 0.75; 0");
        CHECK(e.renderer()->game_target_texture().image == scaled);
        CHECK(e.renderer()->render_scale() == doctest::Approx(0.375f));
    }
    // A held size over the player's option, then the player's option again: each changes the size once, never through a size in between.
    REQUIRE_MESSAGE(e.hold_render_scale(0.75, &err), err);
    CHECK(e.renderer()->render_scale() == doctest::Approx(0.75f));
    const std::uint32_t held = e.renderer()->game_target_texture().image;
    CHECK(held != scaled);
    REQUIRE_MESSAGE(e.hold_render_scale(0.75, &err), err);
    CHECK(e.renderer()->game_target_texture().image == held);
    eval(e, "window.renderScale = 0.75; 0");
    CHECK(e.renderer()->render_scale() == doctest::Approx(0.375f));
    CHECK(e.renderer()->upscale_stage());
    e.shutdown();
}

namespace {

std::string dump_of(const CommandResult& r) { return r.error.dump(); }

}  // namespace

TEST_CASE("graphics.preset: applies a preset, reports what changed, and reads with no arguments") {
    TempProject p("preset",
                  R"(, "render": { "upscaler": { "mode": "spatial", "quality": "quality", "sharpness": 0.75 } })");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    const CommandInfo* info = c.info("graphics.preset");
    REQUIRE(info != nullptr);
    CHECK_FALSE(info->readOnly);
    REQUIRE(c.info("graphics.detect") != nullptr);
    CHECK(c.info("graphics.detect")->readOnly);

    auto r = c.call("graphics.preset", Json::object());
    REQUIRE_MESSAGE(r.ok, dump_of(r));
    CHECK(r.result["preset"] == "custom");
    CHECK_FALSE(r.result["changed"].get<bool>());
    CHECK(r.result["changes"].empty());
    CHECK(r.result["limits"] == render::quality_limits_to_json(render::QualityLimits{}));

    r = c.call("graphics.preset", Json::parse(R"({"name":"low"})"));
    REQUIRE_MESSAGE(r.ok, dump_of(r));
    CHECK(r.result["preset"] == "low");
    CHECK(r.result["previous"] == "custom");
    CHECK(r.result["changed"].get<bool>());
    CHECK(r.result["limits"]["ssao"] == false);
    CHECK(r.result["limits"]["shadowCascades"] == 1);
    CHECK(r.result["upscaler"]["mode"] == "auto");
    CHECK(r.result["upscaler"]["quality"] == "performance");
    CHECK(r.result["upscaler"]["scale"].get<double>() == doctest::Approx(0.5));
    bool sawSsao = false, sawUpscaler = false;
    for (const Json& ch : r.result["changes"]) {
        CHECK(ch.contains("knob"));
        CHECK(ch.contains("from"));
        CHECK(ch.contains("to"));
        if (ch["knob"] == "ssao") sawSsao = true;
        if (ch["knob"] == "upscaler") sawUpscaler = true;
    }
    CHECK(sawSsao);
    CHECK(sawUpscaler);
    CHECK(r.result["capped"].is_array());
    if (e.renderer() != nullptr && e.renderer()->initialized())
        CHECK(e.renderer()->quality() == e.renderer()->resolve_graphics_preset(render::GraphicsPreset::Low).limits);

    // The engine's own upscaler is what the preset set.
    auto up = c.call("render.upscaler", Json::object());
    REQUIRE(up.ok);
    CHECK(up.result["mode"] == "auto");
    CHECK(up.result["quality"] == "performance");

    // The same preset again changes nothing; reading answers the same.
    r = c.call("graphics.preset", Json::parse(R"({"name":"low"})"));
    REQUIRE(r.ok);
    CHECK_FALSE(r.result["changed"].get<bool>());
    r = c.call("graphics.preset", Json::object());
    REQUIRE(r.ok);
    CHECK(r.result["preset"] == "low");
    CHECK_FALSE(r.result["changed"].get<bool>());

    r = c.call("graphics.preset", Json::parse(R"({"name":"high"})"));
    REQUIRE(r.ok);
    CHECK(r.result["previous"] == "low");
    CHECK(r.result["limits"]["shadowCascades"] == 3);
    CHECK(r.result["upscaler"]["quality"] == "quality");
    e.shutdown();
}

TEST_CASE("graphics.preset custom brings the game's own settings back bit for bit") {
    TempProject p("custom",
                  R"(, "render": { "upscaler": { "mode": "spatial", "quality": "quality", "sharpness": 0.75 } })");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    const Json upscalerBefore = c.call("render.upscaler", Json::object()).result;
    const Json limitsBefore = c.call("graphics.preset", Json::object()).result["limits"];
    const render::QualityLimits qualityBefore =
        e.renderer() != nullptr ? e.renderer()->quality() : render::QualityLimits{};
    CHECK(qualityBefore == render::QualityLimits{});

    for (const char* name : {"low", "medium", "high", "ultra"}) {
        auto r = c.call("graphics.preset", Json::object({{"name", name}}));
        REQUIRE_MESSAGE(r.ok, dump_of(r));
        CHECK(r.result["preset"] == name);
        r = c.call("graphics.preset", Json::parse(R"({"name":"custom"})"));
        REQUIRE_MESSAGE(r.ok, dump_of(r));
        CHECK(r.result["preset"] == "custom");
        CHECK(r.result["previous"] == name);
        CHECK(r.result["limits"] == limitsBefore);
        CHECK(r.result["capped"].empty());
        CHECK(c.call("render.upscaler", Json::object()).result == upscalerBefore);
        if (e.renderer() != nullptr) CHECK(e.renderer()->quality() == qualityBefore);
    }
    // A manual upscaler change while a preset is on is what `custom` goes back to.
    REQUIRE(c.call("graphics.preset", Json::parse(R"({"name":"medium"})")).ok);
    REQUIRE(c.call("render.upscaler", Json::parse(R"({"mode":"spatial","quality":"balanced"})")).ok);
    REQUIRE(c.call("graphics.preset", Json::parse(R"({"name":"custom"})")).ok);
    auto up = c.call("render.upscaler", Json::object());
    CHECK(up.result["mode"] == "spatial");
    CHECK(up.result["quality"] == "balanced");
    e.shutdown();
}

TEST_CASE("graphics.preset: a wrong call teaches and changes nothing") {
    TempProject p("errors");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    REQUIRE(c.call("graphics.preset", Json::parse(R"({"name":"medium"})")).ok);
    auto r = c.call("graphics.preset", Json::parse(R"({"name":"hihg"})"));
    REQUIRE_FALSE(r.ok);
    CHECK(dump_of(r).find("high") != std::string::npos);
    CHECK(dump_of(r).find("hihg") != std::string::npos);
    r = c.call("graphics.preset", Json::parse(R"({"nmae":"high"})"));
    REQUIRE_FALSE(r.ok);
    CHECK(dump_of(r).find("name") != std::string::npos);
    r = c.call("graphics.preset", Json::parse(R"({"name":3})"));
    REQUIRE_FALSE(r.ok);
    CHECK(dump_of(r).find("string") != std::string::npos);
    r = c.call("graphics.detect", Json::parse(R"({"x":1})"));
    CHECK_FALSE(r.ok);
    CHECK(c.call("graphics.preset", Json::object()).result["preset"] == "medium");
    e.shutdown();
}

TEST_CASE("graphics.detect: a valid preset, the GPU, a bounded benchmark, and nothing changed") {
    TempProject p("detect");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    REQUIRE(c.call("graphics.preset", Json::parse(R"({"name":"high"})")).ok);
    const Json before = c.call("graphics.preset", Json::object()).result;
    auto r = c.call("graphics.detect", Json::object());
    REQUIRE_MESSAGE(r.ok, dump_of(r));
    const Json& d = r.result;
    REQUIRE(d["preset"].is_string());
    CHECK(render::parse_graphics_preset(d["preset"].get<std::string>()).has_value());
    CHECK(d["preset"] != "custom");
    CHECK_FALSE(d["reason"].get<std::string>().empty());
    REQUIRE(d["gpu"].is_object());
    CHECK(d["gpu"].contains("backend"));
    CHECK(d["gpu"].contains("name"));
    CHECK(d["gpu"].contains("memoryMB"));
    REQUIRE(d["benchmarkMs"].is_number());
    CHECK(d["benchmarkMs"].get<double>() >= 0.0);
    CHECK(d["benchmarkMs"].get<double>() < 30000.0);  // the safety net of the benchmark is 4 s
    CHECK(d["benchmark"].contains("ran"));
    CHECK(d["device"].contains("tier"));
    if (!d["benchmark"]["ran"].get<bool>()) CHECK_FALSE(d["benchmark"]["why"].get<std::string>().empty());
    // detect changes nothing: the preset, the limits and the upscaler are what they were.
    CHECK(c.call("graphics.preset", Json::object()).result == before);
    if (e.renderer() != nullptr && e.renderer()->initialized())
        CHECK(e.renderer()->quality() == e.renderer()->resolve_graphics_preset(render::GraphicsPreset::High).limits);
    e.shutdown();
}

TEST_CASE("graphics.detect: an engine without graphics suggests from the device and says why") {
    TempProject p("nographics");
    EngineConfig conf = cfg(p);
    conf.graphics = false;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(conf, nullptr, &err), err);
    auto r = e.commands().call("graphics.detect", Json::object());
    REQUIRE_MESSAGE(r.ok, dump_of(r));
    CHECK_FALSE(r.result["benchmark"]["ran"].get<bool>());
    CHECK(render::parse_graphics_preset(r.result["preset"].get<std::string>()).has_value());
    CHECK(r.result["reason"].get<std::string>().find("no benchmark") != std::string::npos);
    // A preset still applies (nothing to cap, nothing drawn) and says so.
    auto set = e.commands().call("graphics.preset", Json::parse(R"({"name":"medium"})"));
    REQUIRE_MESSAGE(set.ok, dump_of(set));
    CHECK(set.result["headless"].get<bool>());
    CHECK(set.result["capped"].empty());
    e.shutdown();
}

TEST_CASE("project: render.graphicsPreset loads, round-trips, starts the preset and teaches when wrong") {
    TempProject plain("gp-plain");
    auto s = load_project(plain.path());
    REQUIRE(s.ok());
    CHECK(s->graphicsPreset == render::GraphicsPreset::Custom);

    TempProject set("gp-set", R"(, "render": { "graphicsPreset": "medium" })");
    auto t = load_project(set.path());
    REQUIRE_MESSAGE(t.ok(), t.error().message);
    CHECK(t->graphicsPreset == render::GraphicsPreset::Medium);
    CHECK(t->to_json()["render"]["graphicsPreset"] == "medium");
    t->graphicsPreset = render::GraphicsPreset::Custom;
    CHECK_FALSE(t->to_json().contains("render"));

    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(set), nullptr, &err), err);
    auto r = e.commands().call("graphics.preset", Json::object());
    REQUIRE(r.ok);
    CHECK(r.result["preset"] == "medium");
    CHECK(r.result["upscaler"]["quality"] == "balanced");
    e.shutdown();

    // render.upscaler is what `custom` uses; with a preset the preset's own upscaler is on.
    TempProject both(
        "gp-both",
        R"(, "render": { "graphicsPreset": "high", "upscaler": { "mode": "spatial", "quality": "ultraPerformance" } })");
    Engine e2;
    REQUIRE_MESSAGE(e2.init(cfg(both), nullptr, &err), err);
    CHECK(e2.commands().call("render.upscaler", Json::object()).result["quality"] == "quality");
    REQUIRE(e2.commands().call("graphics.preset", Json::parse(R"({"name":"custom"})")).ok);
    CHECK(e2.commands().call("render.upscaler", Json::object()).result["quality"] == "ultraPerformance");
    e2.shutdown();

    TempProject bad("gp-bad", R"(, "render": { "graphicsPreset": "hihg" })");
    auto b = load_project(bad.path());
    REQUIRE_FALSE(b.ok());
    const std::string text = b.error().message + " " + b.error().hint;
    CHECK(text.find("/render/graphicsPreset") != std::string::npos);
    CHECK(text.find("high") != std::string::npos);
    TempProject num("gp-num", R"(, "render": { "graphicsPreset": 3 })");
    auto n = load_project(num.path());
    REQUIRE_FALSE(n.ok());
    CHECK(n.error().message.find("/render/graphicsPreset") != std::string::npos);
}

TEST_CASE("game.graphics: a script reads, sets and detects, and a wrong name throws with a hint") {
    TempProject p("gp-js");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    CHECK(eval(e, "game.graphics.preset().preset") == "custom");
    CHECK(eval(e, "game.graphics.preset('low').preset") == "low");
    CHECK(eval(e, "game.graphics.preset().preset") == "low");
    CHECK(eval(e, "game.graphics.preset('low').changes.length") == 0);
    auto r = e.commands().call("graphics.preset", Json::object());
    REQUIRE(r.ok);
    CHECK(r.result["preset"] == "low");
    CHECK(eval(e, "typeof game.graphics.detect().preset") == "string");
    CHECK(eval(e, "game.graphics.detect().gpu.backend.length > 0") == true);
    // What a script reads leaves out the times of the benchmark, and is frozen all the way down.
    CHECK(eval(e, "'benchmarkMs' in game.graphics.detect()") == false);
    CHECK(eval(e, "'frameMs' in game.graphics.detect().benchmark") == false);
    CHECK(eval(e, "'totalMs' in game.graphics.detect().benchmark") == false);
    CHECK(eval(e, "JSON.stringify(game.graphics.detect()).includes('Ms')") == false);
    CHECK(eval(e, "const d = game.graphics.detect(); [d, d.gpu, d.device, d.benchmark].every(Object.isFrozen)") ==
          true);
    CHECK(eval(e,
               "(() => { const d = game.graphics.detect(); try { d.gpu.name = 'x'; d.device.tier = 'x'; } catch (_) {} "
               "return d.gpu.name !== 'x' && d.device.tier !== 'x'; })()") == true);
    auto bad = e.commands().call("script.eval", Json::object({{"code", "game.graphics.preset('hihg')"}}));
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error.dump().find("high") != std::string::npos);
    CHECK(eval(e, "game.graphics.preset('custom').preset") == "custom");
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

    // The scale of the quality is the same under temporal, metalfx and auto; auto picks the best drawable here: MetalFX where this machine
    // has it (the Metal backend on an OS and a GPU with its scalers), else the temporal upscaler; metalfx draws as the next best where it
    // cannot (the reason is in the log and in render.supports).
    const std::string bestHere = render::metalfx_available_here().available ? "metalfx" : "temporal";
    r = c.call("render.upscaler", Json::parse(R"({"mode":"auto"})"));
    REQUIRE(r.ok);
    CHECK(r.result["effectiveMode"] == bestHere);
    r = c.call("render.upscaler", Json::parse(R"({"mode":"metalfx"})"));
    REQUIRE(r.ok);
    CHECK(r.result["effectiveMode"] == bestHere);
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
        // Temporal: what a GPU here would draw. Auto and metalfx: what the default GPU of this machine would draw (M76-P5b): metalfx on an
        // Apple build where MetalFX is available (metalfx_available_here, asked of the system), else temporal. Temporal itself stays temporal.
        const std::string best = render::metalfx_available_here().available ? "metalfx" : "temporal";
        for (const char* mode : {"temporal", "auto", "metalfx"}) {
            r = e.commands().call("render.upscaler", Json::parse(std::string("{\"mode\":\"") + mode + "\"}"));
            REQUIRE_MESSAGE(r.ok, r.error.dump());
            const std::string want = std::string(mode) == "temporal" ? "temporal" : best;
            CHECK_MESSAGE(r.result["effectiveMode"] == want, mode);
            CHECK_MESSAGE(eval(e, "window.upscaler.effectiveMode") == want, mode);
        }
    }
    {
        TempProject p("nogpu_pixel_temporal", R"(, "render": { "upscaler": { "mode": "temporal" } })", "pixelPerfect");
        EngineConfig c = cfg(p);
        c.graphics = false;
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
        for (const char* mode : {"temporal", "auto", "metalfx"}) {
            auto r = e.commands().call("render.upscaler", Json::parse(std::string("{\"mode\":\"") + mode + "\"}"));
            REQUIRE_MESSAGE(r.ok, r.error.dump());
            CHECK_MESSAGE(r.result["effectiveMode"] == "stretch", mode);
        }
    }
}

namespace {

// A 3D scene (a lit ground and two cubes, a sun with shadows, an occlusion-darkened crease) on a project that scales with "fit", so the
// upscaler is free to draw (pixel art is always stretch).
struct ScenePixelProject {
    stdfs::path dir;
    explicit ScenePixelProject(const std::string& name, const std::string& renderBlock = "") {
        dir = fs::make_temp_dir("fa_upscaler_test_" + name).value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary) << R"({
  "format": "factoria.project/1",
  "name": "Preset Pixels",
  "id": "com.example.presetpixels",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "fit" })" + renderBlock +
                                                                      "\n}";
        std::ofstream(dir / "scenes" / "main.scene.json", std::ios::binary) << R"({
  "format": "factoria.scene/1",
  "settings": { "shadowCascades": 3, "ambientLight": [0.2, 0.2, 0.25, 1] },
  "entities": [
    { "id": "cam", "components": {
        "Transform": { "position": [0, 4, 9], "rotation": [-20, 0, 0] },
        "Camera": { "projection": "perspective", "fov": 60 },
        "PostProcess": { "ssaoEnabled": true, "motionBlurEnabled": true } } },
    { "id": "sun", "components": {
        "Transform": { "rotation": [-50, 30, 0] },
        "Light": { "type": "directional", "castShadows": true, "shadowFilter": "pcss" } } },
    { "id": "ground", "components": {
        "Transform": { "position": [0, -0.5, 0], "scale": [30, 1, 30] },
        "MeshRenderer": { "mesh": "plane", "color": [0.7, 0.7, 0.7, 1] } } },
    { "id": "a", "components": {
        "Transform": { "position": [-1.5, 0.6, 0], "scale": [1.2, 1.2, 1.2], "rotation": [0, 25, 0] },
        "MeshRenderer": { "mesh": "cube", "color": [0.8, 0.4, 0.2, 1] } } },
    { "id": "b", "components": {
        "Transform": { "position": [1.5, 0.8, -1] },
        "MeshRenderer": { "mesh": "sphere", "color": [0.2, 0.5, 0.8, 1], "roughness": 0.3 } } }
  ] })";
    }
    ~ScenePixelProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

bool draw_frame(Engine& e, Image& out) {
    e.step(2);
    e.render_now();
    std::string err;
    const bool ok = e.renderer() != nullptr && e.renderer()->capture(out, &err);
    INFO("capture: " << err);
    return ok;
}

bool same_pixels(const Image& a, const Image& b) {
    return a.width == b.width && a.height == b.height && a.rgba == b.rgba;
}

}  // namespace

TEST_CASE(
    "graphics.preset: ultra is custom's picture bit for bit, with the game's own upscaler merged in; low is not") {
    for (const char* block :
         {"", R"(, "render": { "upscaler": { "mode": "spatial", "quality": "balanced", "sharpness": 0.8 } })"}) {
        ScenePixelProject p("pixels", block);
        EngineConfig conf;
        conf.projectDir = p.dir.generic_string();
        conf.headless = true;
        conf.hotReload = false;
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(conf, nullptr, &err), err);
        if (e.renderer() == nullptr || !e.renderer()->initialized()) {
            MESSAGE("no GPU in this run: the pixel comparison did not run");
            e.shutdown();
            return;
        }
        auto& c = e.commands();
        Image own, ultra, low, back;
        REQUIRE(draw_frame(e, own));
        const Json upscalerOwn = c.call("render.upscaler", Json::object()).result;
        REQUIRE(c.call("graphics.preset", Json::parse(R"({"name":"ultra"})")).ok);
        // The upscaler is the game's own, whatever it is.
        CHECK(c.call("render.upscaler", Json::object()).result == upscalerOwn);
        REQUIRE(draw_frame(e, ultra));
        CHECK(same_pixels(own, ultra));
        REQUIRE(c.call("graphics.preset", Json::parse(R"({"name":"low"})")).ok);
        REQUIRE(draw_frame(e, low));
        CHECK_FALSE(same_pixels(own, low));
        // From low to ultra the game's own upscaler comes back (ultra writes none), and custom after it is the same again.
        REQUIRE(c.call("graphics.preset", Json::parse(R"({"name":"ultra"})")).ok);
        CHECK(c.call("render.upscaler", Json::object()).result == upscalerOwn);
        REQUIRE(draw_frame(e, ultra));
        CHECK(same_pixels(own, ultra));
        REQUIRE(c.call("graphics.preset", Json::parse(R"({"name":"custom"})")).ok);
        REQUIRE(draw_frame(e, back));
        CHECK(same_pixels(own, back));
        e.shutdown();
    }
}

TEST_CASE("graphics.preset: a partial upscaler change while a preset is on keeps the game's own mode and quality for "
          "custom") {
    TempProject p("partial",
                  R"(, "render": { "upscaler": { "mode": "spatial", "quality": "quality", "sharpness": 0.75 } })");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    REQUIRE(c.call("graphics.preset", Json::parse(R"({"name":"medium"})")).ok);
    CHECK(c.call("render.upscaler", Json::object()).result["quality"] == "balanced");
    // The change applies at once, over what is in force...
    REQUIRE(c.call("render.upscaler", Json::parse(R"({"sharpness":0.2})")).ok);
    auto now = c.call("render.upscaler", Json::object()).result;
    CHECK(now["mode"] == "auto");
    CHECK(now["quality"] == "balanced");
    CHECK(now["sharpness"].get<double>() == doctest::Approx(0.2));
    // ... and `custom` goes back to the game's own setting with the change written over it, not to the preset's mode and quality.
    REQUIRE(c.call("graphics.preset", Json::parse(R"({"name":"custom"})")).ok);
    now = c.call("render.upscaler", Json::object()).result;
    CHECK(now["mode"] == "spatial");
    CHECK(now["quality"] == "quality");
    CHECK(now["sharpness"].get<double>() == doctest::Approx(0.2));
    // The same from a script.
    REQUIRE(c.call("graphics.preset", Json::parse(R"({"name":"high"})")).ok);
    eval(e, "window.upscaler = { quality: 'performance' }; 0");
    CHECK(eval(e, "window.upscaler.quality") == "performance");
    CHECK(eval(e, "window.upscaler.mode") == "auto");
    REQUIRE(c.call("graphics.preset", Json::parse(R"({"name":"custom"})")).ok);
    now = c.call("render.upscaler", Json::object()).result;
    CHECK(now["mode"] == "spatial");
    CHECK(now["quality"] == "performance");
    CHECK(now["sharpness"].get<double>() == doctest::Approx(0.2));
    // A refused change (a wrong name) writes nothing anywhere.
    REQUIRE(c.call("graphics.preset", Json::parse(R"({"name":"low"})")).ok);
    CHECK_FALSE(c.call("render.upscaler", Json::parse(R"({"mode":"nope"})")).ok);
    REQUIRE(c.call("graphics.preset", Json::parse(R"({"name":"custom"})")).ok);
    CHECK(c.call("render.upscaler", Json::object()).result["quality"] == "performance");
    e.shutdown();
}

TEST_CASE("graphics.preset: the upscaler it reports is the effective mode of the renderer, stretch for pixel art") {
    TempProject p("effective");  // pixelPerfect: the renderer draws stretch whatever the setting says
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto r = e.commands().call("graphics.preset", Json::parse(R"({"name":"medium"})"));
    REQUIRE(r.ok);
    CHECK(r.result["upscaler"]["mode"] == "auto");
    CHECK(r.result["upscaler"]["effectiveMode"] == "stretch");
    e.shutdown();
}

// ---- M78-P1: the vendor modes (dlss, xess, fsr) --------------------------------------------------------------------------------------

TEST_CASE("render.upscaler: dlss, xess and fsr load from the project, round-trip, and are documented") {
    for (const char* mode : {"dlss", "xess", "fsr"}) {
        TempProject p(std::string("vendor_load_") + mode, std::string(R"(, "render": { "upscaler": { "mode": ")") +
                                                              mode + R"(", "quality": "quality" } })");
        auto s = load_project(p.path());
        REQUIRE_MESSAGE(s.ok(), s.error().message);
        CHECK(std::string(render::upscaler_mode_name(s->upscaler.mode)) == mode);
        CHECK(s->to_json()["render"]["upscaler"]["mode"] == mode);
    }
    TempProject bad("vendor_bad", R"(, "render": { "upscaler": { "mode": "dlls" } })");
    auto b = load_project(bad.path());
    REQUIRE_FALSE(b.ok());
    const std::string badText = b.error().message + " " + b.error().hint;
    CHECK(badText.find("dlss") != std::string::npos);

    TempProject p("vendor_doc");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    const CommandInfo* info = e.commands().info("render.upscaler");
    REQUIRE(info != nullptr);
    const std::string doc = info->description + " " + info->details + " " + info->inputSchema.dump();
    for (const char* word : {"dlss", "xess", "fsr", "factoria setup"})
        CHECK_MESSAGE(doc.find(word) != std::string::npos, word);
    CHECK(info->description.size() < 1500);
    e.shutdown();
}

TEST_CASE("render.upscaler: a vendor mode with no SDK usable reports the mode asked and draws as the next best; "
          "render.supports says why") {
    TempProject p("vendor_cmd", "", "fit");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    REQUIRE(e.renderer() != nullptr);
    auto& c = e.commands();
    for (const char* mode : {"dlss", "xess", "fsr"}) {
        auto r = c.call("render.upscaler",
                        Json::parse(std::string("{\"mode\":\"") + mode + "\",\"quality\":\"performance\"}"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["mode"] == mode);
        // The SDKs are not installed on a test machine (and are Windows only): the mode is not the effective one.
        CHECK_MESSAGE(r.result["effectiveMode"] != mode, mode);
        CHECK_MESSAGE(r.result["effectiveMode"] != "stretch", mode);  // the next best, never a bare stretch
        CHECK(r.result["scale"].get<double>() == doctest::Approx(0.5));
        auto s = c.call("render.supports", Json::parse(std::string("{\"feature\":\"") + mode + "\"}"));
        REQUIRE_MESSAGE(s.ok, s.error.dump());
        const std::string text = s.result.dump();
        CHECK_MESSAGE(text.find("\"supported\":false") != std::string::npos, text);
        const bool teaches = text.find("factoria setup") != std::string::npos ||
                             text.find("Windows") != std::string::npos || text.find("NVIDIA") != std::string::npos ||
                             text.find("needs") != std::string::npos;
        CHECK_MESSAGE(teaches, text);
    }
    e.shutdown();
}

TEST_CASE("render.upscaler without a renderer: a vendor mode is what the next best would draw") {
    TempProject p("vendor_nogpu", R"(, "render": { "upscaler": { "mode": "dlss" } })", "fit");
    EngineConfig cf = cfg(p);
    cf.graphics = false;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cf, nullptr, &err), err);
    REQUIRE(e.renderer() == nullptr);
    const std::string best = render::metalfx_available_here().available ? "metalfx" : "temporal";
    for (const char* mode : {"dlss", "xess", "fsr"}) {
        auto r = e.commands().call("render.upscaler", Json::parse(std::string("{\"mode\":\"") + mode + "\"}"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK_MESSAGE(r.result["mode"] == mode, mode);
        CHECK_MESSAGE(r.result["effectiveMode"] == best, mode);
    }
    TempProject art("vendor_nogpu_art", R"(, "render": { "upscaler": { "mode": "fsr" } })", "pixelPerfect");
    EngineConfig ca = cfg(art);
    ca.graphics = false;
    Engine a;
    REQUIRE_MESSAGE(a.init(ca, nullptr, &err), err);
    CHECK(a.commands().call("render.upscaler", Json::object()).result["effectiveMode"] == "stretch");
}
