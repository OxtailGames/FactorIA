// M71: postprocess.get, postprocess.set, postprocess.presets, render.supports and render.output.
#include <doctest.h>

#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/core/reflect.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/postprocess_presets.h"
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
    for (const char* name : {"postprocess.get", "postprocess.set", "postprocess.presets", "postprocess.apply_preset",
                             "render.supports", "render.debug_view", "render.reset_post_history"}) {
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

TEST_CASE("postprocess.set customPasses: accepted, shown by get and resolved, replaced as a whole, a bad entry changes "
          "nothing") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto r = c.call("postprocess.set", Json::parse(R"({"id":"cam","fields":{"customPasses":[
        {"material":"materials/a.material.json","materialParams":{"amount":0.5},"position":"after:bloom"},
        {"material":"materials/b.material.json","enabled":false,"name":"second"}]}})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["customPasses"] == 2);
    const PostProcess* pp = e.world().get<PostProcess>(e.world().find("cam"));
    REQUIRE(pp);
    REQUIRE(pp->customPasses.size() == 2);
    CHECK(pp->bloomEnabled);  // the other fields keep their value

    r = c.call("postprocess.get", Json::parse(R"({"id":"cam","fields":["customPasses"]})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["value"]["customPasses"].size() == 2);

    // The resolved stack lists them in order, with their position and where they come from.
    r = c.call("postprocess.get", Json::parse(R"({"id":"cam","resolved":true})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Json& listed = r.result["resolved"]["customPasses"];
    REQUIRE(listed.size() == 2);
    CHECK(listed[0]["material"] == "materials/a.material.json");
    CHECK(listed[0]["position"] == "after:bloom");
    CHECK(listed[1]["name"] == "second");
    CHECK(listed[1]["enabled"] == false);

    // Reorder and remove: the array is sent whole.
    r = c.call("postprocess.set", Json::parse(R"({"id":"cam","fields":{"customPasses":[
        {"material":"materials/b.material.json"}]}})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(e.world().get<PostProcess>(e.world().find("cam"))->customPasses.size() == 1);

    // Bad entries: refused with the pointer, the valid values and a hint; nothing is written.
    r = c.call("postprocess.set", Json::parse(R"({"id":"cam","fields":{"bloomIntensity":2,"customPasses":[
        {"material":"materials/a.material.json","position":"after:bloon"}]}})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("/fields/customPasses/0") != std::string::npos);
    CHECK(r.error.dump().find("after:bloom") != std::string::npos);
    r = c.call("postprocess.set", Json::parse(R"({"id":"cam","fields":{"customPasses":[{"materal":"x"}]}})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("material") != std::string::npos);
    r = c.call("postprocess.set", Json::parse(R"({"id":"cam","fields":{"customPasses":"nope"}})"));
    CHECK_FALSE(r.ok);
    const PostProcess* after = e.world().get<PostProcess>(e.world().find("cam"));
    CHECK(after->customPasses.size() == 1);
    CHECK(after->bloomIntensity == doctest::Approx(0.9f));
    e.shutdown();
}

TEST_CASE("postprocess.presets lists the looks, and every field of every preset exists and is in range") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto r = e.commands().call("postprocess.presets", Json::object());
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    REQUIRE(r.result["presets"].is_array());
    std::vector<std::string> names;
    for (const Json& j : r.result["presets"]) names.push_back(j["name"].get<std::string>());
    CHECK(names == std::vector<std::string>{"neutral", "cinematic", "retro", "noir", "dreamy", "vivid", "horror"});
    CHECK(r.result["presets"][0]["effects"].empty());
    CHECK(r.result["presets"][1]["effects"].dump().find("bloom") != std::string::npos);

    // The data, field by field: a preset cannot name a field that does not exist or a value outside its range.
    ensure_builtin_components();
    const TypeInfo* type = TypeRegistry::global().of<PostProcess>();
    REQUIRE(type);
    CHECK(e.commands().call("postprocess.presets", Json::parse(R"({"x":1})")).ok == false);
    for (const PostPreset& preset : postprocess_presets()) {
        INFO(preset.name);
        CHECK_FALSE(preset.doc.empty());
        PostProcess scratch;
        auto patched = object_patch_from_json(*type, &scratch, preset.fields);
        REQUIRE_MESSAGE(patched.ok(), (patched.ok() ? std::string() : patched.error().message));
        for (auto it = preset.fields.begin(); it != preset.fields.end(); ++it) {
            INFO(it.key());
            const FieldInfo* f = type->field(it.key());
            REQUIRE(f != nullptr);
            CHECK(post_field_effect(f->name) >= 0);  // an effect field: a preset never sets a volume's shape or weight
            if (f->minValue != f->maxValue && it->is_number()) {
                CHECK(it->get<double>() >= double(f->minValue));
                CHECK(it->get<double>() <= double(f->maxValue));
            }
        }
    }
    e.shutdown();
}

TEST_CASE("postprocess.apply_preset replaces or keeps, says what is not drawn, and teaches") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    CHECK(c.info("postprocess.apply_preset")->description.find("Example") != std::string::npos);
    CHECK(c.info("postprocess.apply_preset")->inputSchema["additionalProperties"] == false);

    // The scene's camera has bloom 0.9. Replace (the default): the result is exactly the preset.
    auto r = c.call("postprocess.apply_preset", Json::parse(R"({"id":"cam","preset":"noir"})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    PostProcess* pp = e.world().get<PostProcess>(e.world().find("cam"));
    REQUIRE(pp);
    CHECK(pp->vignetteEnabled);
    CHECK(pp->colorGradingSaturation == doctest::Approx(0.0f));
    CHECK(pp->bloomIntensity == doctest::Approx(0.35f));  // the preset's own bloom, not the 0.9 of the scene
    CHECK(r.result["preset"] == "noir");
    CHECK(r.result["effects"].dump().find("sharpen") != std::string::npos);
    CHECK(r.result["notDrawn"].is_array());
    CHECK(r.result["drawnChecked"].is_boolean());
    CHECK(r.result["note"].is_string());

    // Keep: an effect the preset does not name stays. Neutral without keep switches everything off.
    pp->pixelateEnabled = true;
    r = c.call("postprocess.apply_preset", Json::parse(R"({"id":"cam","preset":"vivid","keep":true})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(e.world().get<PostProcess>(e.world().find("cam"))->pixelateEnabled);
    CHECK(e.world().get<PostProcess>(e.world().find("cam"))->colorGradingSaturation == doctest::Approx(1.4f));
    r = c.call("postprocess.apply_preset", Json::parse(R"({"id":"cam","preset":"neutral"})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["effects"].empty());
    CHECK_FALSE(e.world().get<PostProcess>(e.world().find("cam"))->pixelateEnabled);

    // A volume keeps its meta fields; the component is added where there is none.
    r = c.call("postprocess.set",
               Json::parse(R"({"id":"plain","fields":{"shape":"box","size":[4,4,4],"priority":3}})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    r = c.call("postprocess.apply_preset", Json::parse(R"({"id":"plain","preset":"horror"})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const PostProcess* vol = e.world().get<PostProcess>(e.world().find("plain"));
    REQUIRE(vol);
    CHECK(vol->shape == PostShape::Box);
    CHECK(vol->priority == 3);
    CHECK(vol->fogEnabled);

    // Teaching errors; nothing changed.
    r = c.call("postprocess.apply_preset", Json::parse(R"({"id":"cam","preset":"cinematc"})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("cinematic") != std::string::npos);
    r = c.call("postprocess.apply_preset", Json::parse(R"({"id":"cam"})"));
    CHECK_FALSE(r.ok);
    r = c.call("postprocess.apply_preset", Json::parse(R"({"id":"nobody","preset":"noir"})"));
    CHECK_FALSE(r.ok);
    r = c.call("postprocess.apply_preset", Json::parse(R"({"id":"cam","preset":"noir","keeps":true})"));
    CHECK_FALSE(r.ok);
    r = c.call("postprocess.apply_preset", Json::parse(R"({"id":"cam","preset":"noir","keep":"yes"})"));
    CHECK_FALSE(r.ok);
    e.shutdown();
}

TEST_CASE("postprocess.get resolved: the stack of a camera with the source of each value") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto r = c.call("postprocess.set", Json::parse(R"({"id":"plain","fields":{"shape":"box","size":[100,100,100],
                       "vignetteEnabled":true,"vignetteIntensity":0.6,"bloomEnabled":true,"bloomIntensity":0.2,"priority":1}})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    r = c.call("postprocess.get", Json::parse(R"({"id":"cam","resolved":true})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Json& rep = r.result["resolved"];
    REQUIRE(rep["layers"].size() == 2);
    CHECK(rep["layers"][0]["from"] == "own");
    CHECK(rep["layers"][1]["from"] == "volume:" + e.world().id_of(e.world().find("plain")));
    CHECK(rep["layers"][1]["priority"] == 1);
    CHECK(rep["layers"][1]["weight"] == doctest::Approx(1.0));
    REQUIRE(rep["effects"].size() == std::size_t(kPostEffectCount));
    CHECK(rep["effects"][0]["name"] == "ssao");  // canonical order
    CHECK(rep["count"] == 2);
    const Json* vignette = nullptr;
    const Json* bloom = nullptr;
    for (const Json& fx : rep["effects"]) {
        if (fx["name"] == "vignette") vignette = &fx;
        if (fx["name"] == "bloom") bloom = &fx;
    }
    REQUIRE(vignette);
    REQUIRE(bloom);
    CHECK((*vignette)["enabled"] == true);
    CHECK((*vignette)["fields"]["vignetteIntensity"]["from"].get<std::string>().rfind("volume:", 0) == 0);
    CHECK((*bloom)["fields"]["bloomIntensity"]["from"].get<std::string>().rfind("volume:", 0) == 0);  // the volume wins
    CHECK((*bloom)["layers"].size() == 2);

    // Without an id: the main camera. A non-camera, `fields` with resolved and a bad flag are taught.
    r = c.call("postprocess.get", Json::parse(R"({"resolved":true})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["id"] == "cam");
    // A camera that draws into a texture (a minimap) with a lower depth is never the main camera: the renderer skips it too.
    r = c.call("scene.spawn",
               Json::parse(R"({"id":"minimap","components":{"Camera":{"depth":-5,"renderTarget":"minimap"}}})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    r = c.call("postprocess.get", Json::parse(R"({"resolved":true})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["id"] == "cam");
    r = c.call("postprocess.get", Json::parse(R"({"id":"plain","resolved":true})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("no Camera") != std::string::npos);
    r = c.call("postprocess.get", Json::parse(R"({"id":"cam","resolved":true,"fields":["bloomEnabled"]})"));
    CHECK_FALSE(r.ok);
    r = c.call("postprocess.get", Json::parse(R"({"id":"cam","resolved":"yes"})"));
    CHECK_FALSE(r.ok);
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
        CHECK(r.result["features"].size() ==
              29 + std::size_t(kPostEffectCount));  // 8 capabilities and engine features, 21 lighting rows of M73
        r = c.call("render.supports", Json::parse(R"({"feature":"bloom"})"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["feature"] == "bloom");
        CHECK(r.result["status"].is_string());
        r = c.call("render.supports", Json::parse(R"({"feature":"ssao"})"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["supported"]
                  .is_boolean());  // drawn since M71-D1: true where the GPU has float targets and the prepass
        if (r.result["supported"] == false)
            CHECK(r.result["status"].get<std::string>().find("planned") == std::string::npos);
        r = c.call("render.supports", Json::parse(R"({"feature":"ssr"})"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["supported"]
                  .is_boolean());  // drawn since M71-D3a: true where the GPU has float targets and the prepass
        r = c.call("render.supports", Json::parse(R"({"feature":"fog"})"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["supported"].is_boolean());  // drawn since M71-D3b: true where the GPU has the prepass
        r = c.call("render.supports", Json::parse(R"({"feature":"sunShafts"})"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["supported"].is_boolean());
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

TEST_CASE("render.debug_view teaches an unknown view, and says there is no renderer without graphics") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    CHECK_FALSE(e.commands().info("render.debug_view")->readOnly);
    auto r = c.call("render.debug_view", Json::parse(R"({"view":"normal"})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "invalid_arguments");  // the schema's enum, with its did-you-mean hint
    CHECK(r.error.dump().find("Did you mean 'normals'?") != std::string::npos);
    CHECK_FALSE(c.call("render.debug_view", Json::parse(R"({"view":3})")).ok);
    CHECK_FALSE(c.call("render.debug_view", Json::parse(R"({"vew":"depth"})")).ok);
    r = c.call("render.debug_view", Json::object());
    if (!r.ok) {
        CHECK(r.error["code"] == "unavailable");
    } else {
        CHECK(r.result["view"] == "none");
        r = c.call("render.debug_view", Json::parse(R"({"view":"depth"})"));
        REQUIRE(r.ok);
        CHECK(r.result["view"] == "depth");
        CHECK(r.result["previous"] == "none");
        CHECK(c.call("render.debug_view", Json::object()).result["view"] == "depth");
        CHECK(c.call("render.debug_view", Json::parse(R"({"view":"none"})")).result["view"] == "none");
    }
    e.shutdown();
}

TEST_CASE("render.reset_post_history names the camera it forgets, and says there is no renderer without graphics") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    CHECK_FALSE(c.info("render.reset_post_history")->readOnly);
    CHECK_FALSE(c.call("render.reset_post_history", Json::parse(R"({"entiti":"Camera"})")).ok);
    auto r = c.call("render.reset_post_history", Json::parse(R"({"entity":"NoSuchCamera"})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "not_found");
    // An `entity` of another type is an error that says what to pass, not an exception out of the handler.
    for (const char* bad :
         {R"({"entity":5})", R"({"entity":["Camera"]})", R"({"entity":{"id":"Camera"}})", R"({"entity":true})"}) {
        r = c.call("render.reset_post_history", Json::parse(bad));
        INFO(bad);
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "invalid_arguments");
        CHECK(r.error["message"].get<std::string>().find("entity") != std::string::npos);
        CHECK_FALSE(r.error["hint"].get<std::string>().empty());
    }
    r = c.call("render.reset_post_history",
               Json::parse(R"({"entity":null})"));  // the schema wants a string, or no `entity`
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "invalid_arguments");
    r = c.call("render.reset_post_history", Json::object());
    if (!r.ok) {
        CHECK(r.error["code"] == "unavailable");
    } else {
        CHECK(r.result["reset"] == "all");
    }
    e.shutdown();
}
