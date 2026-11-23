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

std::string project_text(const std::string& renderBlock) {
    return std::string(R"({
  "format": "factoria.project/1",
  "name": "Upscaler Test",
  "id": "com.example.upscalertest",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" })") +
           renderBlock + "\n}";
}

const char* kScene =
    R"({ "format": "factoria.scene/1", "entities": [ { "id": "cam", "components": { "Camera": {} } } ] })";

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name, const std::string& renderBlock = "") {
        dir = fs::make_temp_dir("fa_upscaler_test_" + name).value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary) << project_text(renderBlock);
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
    // Nothing draws yet: the effective mode stays stretch, and the scale is the quality's.
    CHECK(r.result["effectiveMode"] == "stretch");
    CHECK(r.result["scale"].get<double>() == doctest::Approx(1.0 / 1.5).epsilon(0.001));

    r = c.call("render.upscaler", Json::parse(R"({"mode":"temporal","quality":"performance","sharpness":0.25})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["mode"] == "temporal");
    CHECK(r.result["quality"] == "performance");
    CHECK(r.result["sharpness"].get<double>() == doctest::Approx(0.25));
    CHECK(r.result["scale"].get<double>() == doctest::Approx(0.5));

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
    auto bad = e.commands().call("script.eval", Json::object({{"code", "game.graphics.preset('hihg')"}}));
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error.dump().find("high") != std::string::npos);
    CHECK(eval(e, "game.graphics.preset('custom').preset") == "custom");
    e.shutdown();
}
