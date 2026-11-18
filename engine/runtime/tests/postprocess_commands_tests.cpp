// M71: postprocess.get, postprocess.set, postprocess.presets, render.supports and render.output.
#include <doctest.h>

#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/postprocess.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "PostProcess Commands Test",
  "id": "com.example.postprocesscommands",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {}, "PostProcess": { "bloomEnabled": true, "bloomIntensity": 0.9 } } },
    { "id": "plain", "name": "plain", "components": { "Transform": {} } }
  ]
})";

struct TempProject {
    stdfs::path dir;
    TempProject() {
        dir = fs::make_temp_dir("fa_postprocesscmd_test").value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary) << kScene;
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

EngineConfig cfg(const TempProject& p) {
    EngineConfig c;
    c.projectDir = p.dir.generic_string();
    c.headless = true;
    c.hotReload = false;
    return c;
}

}  // namespace

TEST_CASE("postprocess and render.supports commands are documented and closed") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    for (const char* name : {"postprocess.get", "postprocess.set", "postprocess.presets", "render.supports"}) {
        INFO(name);
        const CommandInfo* info = e.commands().info(name);
        REQUIRE(info != nullptr);
        CHECK(info->description.find("Example") != std::string::npos);
        CHECK(info->inputSchema["additionalProperties"] == false);
        CHECK_FALSE(info->description.empty());
    }
    CHECK(e.commands().info("postprocess.get")->readOnly);
    CHECK(e.commands().info("postprocess.presets")->readOnly);
    CHECK(e.commands().info("render.supports")->readOnly);
    CHECK_FALSE(e.commands().info("postprocess.set")->readOnly);
    e.shutdown();
}

TEST_CASE("postprocess.get reads the component, and only the fields asked for") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto r = c.call("postprocess.get", Json::parse(R"({"id":"cam"})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["id"] == "cam");
    CHECK(r.result["effects"] == Json::parse(R"(["bloom"])"));
    CHECK(r.result["order"].size() == std::size_t(kPostEffectCount));
    CHECK(r.result["order"][0] == "ssao");
    CHECK(r.result["order"][std::size_t(kPostEffectCount) - 1] == "colorFilter");
    CHECK(r.result["value"]["bloomIntensity"] == doctest::Approx(0.9));
    CHECK(r.result["value"]["tonemapEnabled"] == false);
    CHECK(r.result["value"]["shape"] == "global");

    r = c.call("postprocess.get", Json::parse(R"({"id":"cam","fields":["bloomEnabled","weight"]})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["value"].size() == 2);
    CHECK(r.result["value"]["bloomEnabled"] == true);
    CHECK(r.result["value"]["weight"] == 1.0);
    e.shutdown();
}

TEST_CASE("postprocess.get teaches: no component, unknown entity, unknown field, unknown argument") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto r = c.call("postprocess.get", Json::parse(R"({"id":"plain"})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("no PostProcess") != std::string::npos);
    CHECK(r.error["hint"].get<std::string>().find("postprocess.set") != std::string::npos);
    r = c.call("postprocess.get", Json::parse(R"({"id":"nobody"})"));
    CHECK_FALSE(r.ok);
    r = c.call("postprocess.get", Json::parse(R"({"id":"cam","fields":["bloomIntensty"]})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("bloomIntensity") != std::string::npos);
    r = c.call("postprocess.get", Json::parse(R"({"id":"cam","field":["bloomEnabled"]})"));
    CHECK_FALSE(r.ok);
    e.shutdown();
}

TEST_CASE("postprocess.set adds the component, sets fields and changes nothing on an error") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto r = c.call("postprocess.set",
                    Json::parse(R"({"id":"plain","fields":{"shape":"sphere","size":[7,7,7],"blendDistance":2,
                                    "vignetteEnabled":true,"vignetteIntensity":0.6,"tonemapEnabled":true,"tonemapMode":"agx"}})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["effects"] == Json::parse(R"(["tonemap","vignette"])"));  // in the order they run
    CHECK(r.result["value"]["shape"] == "sphere");
    const PostProcess* pp = e.world().get<PostProcess>(e.world().find("plain"));
    REQUIRE(pp);
    CHECK(pp->shape == PostShape::Sphere);
    CHECK(pp->tonemapMode == TonemapMode::Agx);
    CHECK(pp->vignetteIntensity == doctest::Approx(0.6f));
    CHECK(pp->blendDistance == 2.0f);

    // A bad value is refused with the allowed names and nothing is changed.
    r = c.call("postprocess.set",
               Json::parse(R"({"id":"plain","fields":{"bloomEnabled":true,"tonemapMode":"filmic"}})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("agx") != std::string::npos);
    CHECK_FALSE(e.world().get<PostProcess>(e.world().find("plain"))->bloomEnabled);
    r = c.call("postprocess.set", Json::parse(R"({"id":"plain","fields":{"bloomIntensty":1}})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("bloomIntensity") != std::string::npos);
    r = c.call("postprocess.set", Json::parse(R"({"id":"plain"})"));  // no fields
    CHECK_FALSE(r.ok);
    r = c.call("postprocess.set", Json::parse(R"({"id":"plain","fields":{"bloomEnabled":true},"merge":true})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(e.world().get<PostProcess>(e.world().find("plain"))->bloomEnabled);
    e.shutdown();
}

TEST_CASE("postprocess.presets lists no presets yet") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto r = e.commands().call("postprocess.presets", Json::object());
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    REQUIRE(r.result["presets"].is_array());
    CHECK(r.result["presets"].empty());
    e.shutdown();
}

TEST_CASE("render.supports answers with a status, or says there is no renderer, and teaches an unknown name") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto r = c.call("render.supports", Json::parse(R"({"feature":"bloomm"})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "invalid_argument");
    CHECK(r.error["message"].get<std::string>().find("bloom") != std::string::npos);  // did you mean
    r = c.call("render.supports", Json::parse(R"({"feture":"bloom"})"));
    CHECK_FALSE(r.ok);
    r = c.call("render.supports", Json::parse(R"({"feature":7})"));
    CHECK_FALSE(r.ok);

    r = c.call("render.supports", Json::object());
    if (!r.ok) {
        CHECK(r.error["code"] == "unavailable");  // graphics=false: no GPU to ask
    } else {
        CHECK(r.result["features"].size() == 6 + std::size_t(kPostEffectCount));
        r = c.call("render.supports", Json::parse(R"({"feature":"bloom"})"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["feature"] == "bloom");
        CHECK(r.result["status"].is_string());
        r = c.call("render.supports", Json::parse(R"({"feature":"ssao"})"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["supported"] == false);  // M71 in progress: the renderer does not draw it yet
    }
    e.shutdown();
}

TEST_CASE("render.output: a headless run shows the standard range, says why and teaches an unknown argument") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    const CommandInfo* info = c.info("render.output");
    REQUIRE(info != nullptr);
    CHECK(info->readOnly);
    CHECK(info->description.find("Example") != std::string::npos);
    CHECK(info->inputSchema["additionalProperties"] == false);

    auto r = c.call("render.output", Json::object());
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["hdrActive"] == false);
    CHECK(r.result["encoding"] == "sdr");
    CHECK(r.result["swapchainFormat"] == "");
    CHECK(r.result["requested"] == false);
    CHECK(r.result["headroom"] == 1.0);
    CHECK(r.result["display"]["known"] == false);
    CHECK(r.result["display"]["offers"] == Json::array());
    CHECK(r.result["status"].get<std::string>().find("no window") != std::string::npos);

    // The scene asks for HDR: requested, with its paper white, and still the standard range without a window.
    e.world().settings().hdrOutput = HdrOutput::Auto;
    e.world().settings().paperWhiteNits = 320.0f;
    r = c.call("render.output", Json::object());
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["requested"] == true);
    CHECK(r.result["paperWhiteNits"] == doctest::Approx(320.0));
    CHECK(r.result["hdrActive"] == false);

    r = c.call("render.output", Json::parse(R"({"display":0})"));
    CHECK_FALSE(r.ok);
    e.shutdown();
}
