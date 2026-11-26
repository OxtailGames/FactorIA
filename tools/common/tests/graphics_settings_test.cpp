// The Graphics settings window's rules (fa/tooling/graphics_settings.h): reading, checking and saving render.graphicsPreset,
// render.upscaler, render.dynamicResolution and render.latency in factoria.json, with the engine's own validation. No window, no GPU.
#include <algorithm>
#include <cctype>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <sstream>

#include "doctest.h"
#include "fa/core/fs.h"
#include "fa/runtime/project.h"
#include "fa/tooling/graphics_settings.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct Dir {
    stdfs::path dir;
    Dir() { dir = fs::make_temp_dir("fa_graphics_settings").value(); }
    ~Dir() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    std::string str() const { return dir.generic_string(); }
    void write(const std::string& text) const { std::ofstream(dir / "factoria.json", std::ios::binary) << text; }
    std::string read() const {
        std::ifstream in(dir / "factoria.json", std::ios::binary);
        std::stringstream ss;
        ss << in.rdbuf();
        return ss.str();
    }
};

const char* kBare =
    "{\n  \"format\": \"factoria.project/1\",\n  \"name\": \"G\",\n  \"physics\": { \"fixedHz\": 60 }\n}\n";

}  // namespace

TEST_CASE("graphics settings: a file with no render key reads as the defaults") {
    Dir d;
    d.write(kBare);
    auto s = read_graphics_settings(d.str());
    REQUIRE(s.ok());
    CHECK(*s == GraphicsSettings{});
    CHECK(s->preset == "custom");
    CHECK(s->mode == "stretch");
    CHECK(s->quality == "native");
    CHECK(s->sharpness == doctest::Approx(0.5));
}

TEST_CASE("graphics settings: save writes the two keys, leaves the rest of the file and reads back") {
    Dir d;
    d.write(kBare);
    GraphicsSettings g;
    g.preset = "high";
    g.mode = "spatial";
    g.quality = "balanced";
    g.sharpness = 0.7;
    REQUIRE(write_graphics_settings(d.str(), g).ok());
    const std::string text = d.read();
    CHECK(text.find("\"physics\": { \"fixedHz\": 60 }") != std::string::npos);  // untouched, byte for byte
    auto back = read_graphics_settings(d.str());
    REQUIRE(back.ok());
    CHECK(*back == g);
    // The project loader reads the same values.
    auto project = load_project(d.str());
    REQUIRE(project.ok());
    CHECK(project->graphicsPreset == render::GraphicsPreset::High);
    CHECK(project->upscaler.mode == render::UpscalerMode::Spatial);
    CHECK(project->upscaler.quality == render::UpscalerQuality::Balanced);
    CHECK(project->upscaler.sharpness == doctest::Approx(0.7f));
}

TEST_CASE("graphics settings: back to the defaults removes the keys and an empty render object") {
    Dir d;
    d.write(kBare);
    GraphicsSettings g;
    g.preset = "low";
    g.mode = "auto";
    REQUIRE(write_graphics_settings(d.str(), g).ok());
    REQUIRE(d.read().find("\"render\"") != std::string::npos);
    REQUIRE(write_graphics_settings(d.str(), GraphicsSettings{}).ok());
    CHECK(d.read() == kBare);  // exactly the file we started with
}

TEST_CASE("graphics settings: other render keys stay when the window's keys come and go") {
    Dir d;
    d.write("{\n  \"name\": \"G\",\n  \"render\": { \"interpolation\": true, \"graphicsPreset\": \"ultra\" }\n}\n");
    auto s = read_graphics_settings(d.str());
    REQUIRE(s.ok());
    CHECK(s->preset == "ultra");
    s->preset = "custom";
    REQUIRE(write_graphics_settings(d.str(), *s).ok());
    const std::string text = d.read();
    CHECK(text.find("\"interpolation\": true") != std::string::npos);
    CHECK(text.find("graphicsPreset") == std::string::npos);
    CHECK(text.find("upscaler") == std::string::npos);
}

TEST_CASE(
    "graphics settings: wrong values are refused with a pointer and the engine's sentence, and nothing is written") {
    Dir d;
    d.write(kBare);
    GraphicsSettings g;
    g.preset = "hihg";
    g.mode = "spatail";
    g.quality = "best";
    g.sharpness = 1.5;
    const auto problems = check_graphics_settings(g);
    REQUIRE(problems.size() == 4);
    CHECK(problems[0].pointer == "/render/graphicsPreset");
    CHECK(problems[0].message.find("high") != std::string::npos);  // did you mean
    CHECK(problems[1].pointer == "/render/upscaler/mode");
    CHECK(problems[1].message.find("spatial") != std::string::npos);
    CHECK(problems[2].pointer == "/render/upscaler/quality");
    CHECK(problems[3].pointer == "/render/upscaler/sharpness");
    auto r = write_graphics_settings(d.str(), g);
    CHECK_FALSE(r.ok());
    CHECK(d.read() == kBare);
    CHECK(check_graphics_settings(GraphicsSettings{}).empty());
    g = GraphicsSettings{};
    g.sharpness = -0.1;
    CHECK(check_graphics_settings(g).size() == 1);
}

TEST_CASE(
    "graphics settings: a hand-written wrong file opens with the engine's error, a broken one is not overwritten") {
    Dir d;
    d.write("{\"name\":\"G\",\"render\":{\"upscaler\":{\"mode\":\"sharp\"}}}");
    auto s = read_graphics_settings(d.str());
    REQUIRE_FALSE(s.ok());
    CHECK(s.error().message.find("/render/upscaler") != std::string::npos);
    d.write("{\"name\":\"G\",");
    CHECK_FALSE(write_graphics_settings(d.str(), GraphicsSettings{}).ok());
    GraphicsSettings g;
    g.preset = "low";
    CHECK_FALSE(write_graphics_settings(d.str(), g).ok());
    CHECK(d.read() == "{\"name\":\"G\",");
    CHECK_FALSE(read_graphics_settings((d.dir / "nope").generic_string()).ok());
}

TEST_CASE("graphics settings: the lists are the engine's names") {
    CHECK(graphics_presets().size() == 5);
    CHECK(upscaler_modes().size() == 8);
    CHECK(upscaler_qualities().size() == 5);
    CHECK(std::find(upscaler_modes().begin(), upscaler_modes().end(), "metalfx") != upscaler_modes().end());
}

TEST_CASE("graphics settings: a file with a UTF-8 BOM keeps it when saved") {
    Dir d;
    const std::string bom = "\xEF\xBB\xBF";
    d.write(bom + kBare);
    auto s = read_graphics_settings(d.str());
    REQUIRE(s.ok());
    s->preset = "medium";
    REQUIRE(write_graphics_settings(d.str(), *s).ok());
    const std::string text = d.read();
    REQUIRE(text.size() > 3);
    CHECK(text.compare(0, 3, bom) == 0);
    CHECK(text.compare(3, 3, bom) != 0);  // once, not twice
    auto back = read_graphics_settings(d.str());
    REQUIRE(back.ok());
    CHECK(back->preset == "medium");
    REQUIRE(write_graphics_settings(d.str(), GraphicsSettings{}).ok());
    CHECK(d.read() == bom + kBare);
}

TEST_CASE("graphics settings: \"render\": null is the same as no render settings, on read and on write") {
    Dir d;
    d.write("{\n  \"name\": \"G\",\n  \"render\": null\n}\n");
    auto s = read_graphics_settings(d.str());
    REQUIRE(s.ok());
    CHECK(*s == GraphicsSettings{});
    REQUIRE(write_graphics_settings(d.str(), GraphicsSettings{}).ok());  // nothing to write
    s->mode = "spatial";
    REQUIRE(write_graphics_settings(d.str(), *s).ok());
    auto back = read_graphics_settings(d.str());
    REQUIRE(back.ok());
    CHECK(back->mode == "spatial");
    auto project = load_project(d.str());
    REQUIRE(project.ok());
    CHECK(project->upscaler.mode == render::UpscalerMode::Spatial);
}

TEST_CASE("graphics settings: dynamic resolution is saved as its own key, read back and read by the project loader") {
    Dir d;
    d.write(kBare);
    auto s = read_graphics_settings(d.str());
    REQUIRE(s.ok());
    CHECK_FALSE(s->dynamic.enabled);
    CHECK(s->dynamic.targetMs == 0.0);
    CHECK(s->dynamic.minScale == doctest::Approx(0.5f));
    CHECK(s->dynamic.maxScale == doctest::Approx(1.0f));
    s->dynamic.enabled = true;
    s->dynamic.targetMs = 16.7;
    s->dynamic.minScale = 0.6f;
    REQUIRE(write_graphics_settings(d.str(), *s).ok());
    const std::string text = d.read();
    CHECK(text.find("\"dynamicResolution\"") != std::string::npos);
    CHECK(text.find("\"physics\": { \"fixedHz\": 60 }") != std::string::npos);
    CHECK(text.find("upscaler") == std::string::npos);  // the upscaler is at its default: no key
    auto back = read_graphics_settings(d.str());
    REQUIRE(back.ok());
    CHECK(*back == *s);
    auto project = load_project(d.str());
    REQUIRE(project.ok());
    CHECK(project->dynamicResolution.enabled);
    CHECK(project->dynamicResolution.targetMs == doctest::Approx(16.7));
    CHECK(project->dynamicResolution.minScale == doctest::Approx(0.6f));
    // Back to the defaults: the key and the empty render object go.
    REQUIRE(write_graphics_settings(d.str(), GraphicsSettings{}).ok());
    CHECK(d.read() == kBare);
}

TEST_CASE("graphics settings: dynamic resolution problems are named by pointer with the engine's sentence") {
    GraphicsSettings g;
    g.dynamic.targetMs = 2.0;  // below 4 ms
    g.dynamic.minScale = 0.1f;
    auto problems = check_graphics_settings(g);
    REQUIRE(problems.size() == 2);
    CHECK(problems[0].pointer == "/render/dynamicResolution/targetMs");
    CHECK(problems[1].pointer == "/render/dynamicResolution/minScale");
    g = GraphicsSettings{};
    g.dynamic.minScale = 0.8f;
    g.dynamic.maxScale = 0.6f;  // each alone is fine: the pair is not
    problems = check_graphics_settings(g);
    REQUIRE(problems.size() == 1);
    CHECK(problems[0].pointer == "/render/dynamicResolution/minScale");
    CHECK(problems[0].message.find("maxScale") != std::string::npos);
    Dir d;
    d.write(kBare);
    CHECK_FALSE(write_graphics_settings(d.str(), g).ok());
    CHECK(d.read() == kBare);
    g = GraphicsSettings{};
    g.dynamic.maxScale = std::nanf("");
    CHECK(check_graphics_settings(g).size() == 1);
}

TEST_CASE("graphics settings: a hand-written wrong dynamicResolution opens with the engine's error") {
    Dir d;
    d.write("{\"name\":\"G\",\"render\":{\"dynamicResolution\":{\"enabeld\":true}}}");
    auto s = read_graphics_settings(d.str());
    REQUIRE_FALSE(s.ok());
    CHECK(s.error().message.find("/render/dynamicResolution") != std::string::npos);
    CHECK((s.error().hint + s.error().message).find("enabled") != std::string::npos);
}

TEST_CASE("graphics settings: a sharpness of the file is read as written, not as the parser's float") {
    Dir d;
    d.write("{\"format\": \"factoria.project/1\", \"name\": \"G\", \"render\": {\"upscaler\": {\"mode\": \"spatial\", "
            "\"sharpness\": 0.123}}}\n");
    auto s = read_graphics_settings(d.str());
    REQUIRE(s.ok());
    CHECK(s->sharpness == 0.123);
    // Saving another key leaves the number as it was.
    s->preset = "low";
    REQUIRE(write_graphics_settings(d.str(), *s).ok());
    const std::string text = d.read();
    const std::size_t at = text.find("0.123");
    REQUIRE(at != std::string::npos);
    CHECK_FALSE(std::isdigit(static_cast<unsigned char>(text[at + 5])));  // not 0.12300000339
}

TEST_CASE("project.graphics reads and writes the graphics keys of factoria.json") {
    Dir d;
    d.write(kBare);
    CommandRegistry registry;
    register_graphics_settings_commands(registry, d.str());
    REQUIRE(registry.info("project.graphics") != nullptr);
    CHECK_FALSE(registry.info("project.graphics")->readOnly);
    CHECK_FALSE(registry.info("project.graphics")->description.empty());

    // A read changes nothing.
    auto r = registry.call("project.graphics", Json::object());
    REQUIRE(r.ok);
    CHECK(r.result["preset"] == "custom");
    CHECK(r.result["written"] == false);
    CHECK(d.read() == kBare);

    // A write: only the keys given change, the rest of the upscaler stays, the rest of the file is byte for byte.
    r = registry.call("project.graphics",
                      Json::parse(R"({"preset":"medium","upscaler":{"mode":"auto","quality":"balanced"}})"));
    REQUIRE(r.ok);
    CHECK(r.result["written"] == true);
    CHECK(r.result["upscaler"]["mode"] == "auto");
    CHECK(r.result["upscaler"]["sharpness"] == 0.5);
    CHECK(d.read().find("\"physics\": { \"fixedHz\": 60 }") != std::string::npos);
    r = registry.call("project.graphics", Json::parse(R"({"upscaler":{"sharpness":0.25}})"));
    REQUIRE(r.ok);
    CHECK(r.result["upscaler"]["mode"] == "auto");
    CHECK(r.result["upscaler"]["quality"] == "balanced");
    auto project = load_project(d.str());
    REQUIRE(project.ok());
    CHECK(project->graphicsPreset == render::GraphicsPreset::Medium);
    CHECK(project->upscaler.mode == render::UpscalerMode::Auto);
    CHECK(project->upscaler.sharpness == doctest::Approx(0.25f));
    // The same values again write nothing.
    r = registry.call("project.graphics", Json::parse(R"({"preset":"medium"})"));
    REQUIRE(r.ok);
    CHECK(r.result["written"] == false);

    // A wrong value or key is named with a hint, and the file is not touched.
    const std::string before = d.read();
    r = registry.call("project.graphics", Json::parse(R"({"preset":"hihg"})"));
    CHECK_FALSE(r.ok);
    CHECK(r.error.dump().find("high") != std::string::npos);
    r = registry.call("project.graphics", Json::parse(R"({"upscaler":{"mode":"sptial"}})"));
    CHECK_FALSE(r.ok);
    CHECK(r.error.dump().find("spatial") != std::string::npos);
    r = registry.call("project.graphics", Json::parse(R"({"presets":"low"})"));
    CHECK_FALSE(r.ok);
    CHECK(r.error.dump().find("preset") != std::string::npos);
    r = registry.call("project.graphics", Json::parse(R"({"dynamicResolution":{"minScale":0.9,"maxScale":0.6}})"));
    CHECK_FALSE(r.ok);
    CHECK(d.read() == before);

    // Back to the defaults removes the keys and the empty `render` object.
    r = registry.call(
        "project.graphics",
        Json::parse(R"({"preset":"custom","upscaler":{"mode":"stretch","quality":"native","sharpness":0.5}})"));
    REQUIRE(r.ok);
    CHECK(d.read().find("render") == std::string::npos);
}

TEST_CASE("project.graphics writes only the keys it is given, with the numbers of the file as they are") {
    Dir d;
    d.write(R"({ "format": "factoria.project/1", "name": "G", "id": "com.example.g",
  "render": { "upscaler": { "mode": "spatial" },
    "dynamicResolution": { "enabled": true, "targetMs": 16.67, "minScale": 0.333 } } })");
    CommandRegistry registry;
    register_graphics_settings_commands(registry, d.str());
    // Only a preset: the upscaler (one key) and the dynamic resolution (16.67, 0.333) are not rewritten.
    auto r = registry.call("project.graphics", Json::parse(R"({"preset":"low"})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["written"] == true);
    std::string text = d.read();
    CHECK(text.find("\"targetMs\": 16.67") != std::string::npos);
    CHECK(text.find("\"minScale\": 0.333") != std::string::npos);
    CHECK(text.find("\"upscaler\": { \"mode\": \"spatial\" }") != std::string::npos);
    CHECK(r.result["dynamicResolution"]["targetMs"].get<double>() == doctest::Approx(16.67));
    // Another key of the dynamic resolution: the numbers it does not name stay as written.
    r = registry.call("project.graphics", Json::parse(R"({"dynamicResolution":{"maxScale":0.9}})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    text = d.read();
    CHECK(text.find("16.67") != std::string::npos);
    CHECK(text.find("0.333") != std::string::npos);
    CHECK(text.find("16.7,") == std::string::npos);
    // A number the call names is written as given.
    r = registry.call("project.graphics", Json::parse(R"({"dynamicResolution":{"targetMs":22.22}})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(d.read().find("22.22") != std::string::npos);
    CHECK(d.read().find("0.333") != std::string::npos);
    // The editor's model still works in tenths and hundredths.
    auto s = read_graphics_settings(d.str());
    REQUIRE(s.ok());
    CHECK(s->dynamic.minScale == doctest::Approx(0.33f));
}

TEST_CASE("graphics settings: render.latency is saved as its own key, read back and read by the project loader") {
    Dir d;
    d.write(kBare);
    auto s = read_graphics_settings(d.str());
    REQUIRE(s.ok());
    CHECK(s->latencyMode == "off");
    CHECK_FALSE(s->latencyBoost);
    CHECK(latency_modes() == std::vector<std::string>{"off", "auto", "reflex", "antilag2", "xell"});
    CHECK(latency_mode_has_boost("xell"));
    CHECK(latency_mode_has_boost("auto"));
    CHECK_FALSE(latency_mode_has_boost("antilag2"));
    CHECK_FALSE(latency_mode_has_boost("off"));
    s->latencyMode = "auto";
    s->latencyBoost = true;
    REQUIRE(write_graphics_settings(d.str(), *s).ok());
    const std::string text = d.read();
    CHECK(text.find("\"latency\"") != std::string::npos);
    CHECK(text.find("\"physics\": { \"fixedHz\": 60 }") != std::string::npos);
    CHECK(text.find("upscaler") == std::string::npos);  // the upscaler is at its default: no key
    auto back = read_graphics_settings(d.str());
    REQUIRE(back.ok());
    CHECK(*back == *s);
    auto project = load_project(d.str());
    REQUIRE(project.ok());
    CHECK(project->latency.mode == render::LatencyMode::Auto);
    CHECK(project->latency.boost);
    // Back to the defaults: the key and the empty render object go.
    REQUIRE(write_graphics_settings(d.str(), GraphicsSettings{}).ok());
    CHECK(d.read() == kBare);
}

TEST_CASE("graphics settings: a wrong latency mode is named by pointer with a did-you-mean, and nothing is written") {
    Dir d;
    d.write(kBare);
    GraphicsSettings g;
    g.latencyMode = "antilag";
    const auto problems = check_graphics_settings(g);
    REQUIRE(problems.size() == 1);
    CHECK(problems[0].pointer == "/render/latency/mode");
    CHECK(problems[0].message.find("antilag2") != std::string::npos);
    CHECK_FALSE(write_graphics_settings(d.str(), g).ok());
    CHECK(d.read() == kBare);
    d.write(R"({"format":"factoria.project/1","name":"G","render":{"latency":{"mode":"xel"}}})");
    auto bad = read_graphics_settings(d.str());
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("/render/latency") != std::string::npos);
}

TEST_CASE("project.graphics reads and writes the latency key, and only when it is given") {
    Dir d;
    d.write(kBare);
    CommandRegistry registry;
    register_graphics_settings_commands(registry, d.str());
    auto r = registry.call("project.graphics", Json::object());
    REQUIRE(r.ok);
    CHECK(r.result["latency"]["mode"] == "off");
    CHECK(r.result["latency"]["boost"] == false);
    CHECK(r.result["written"] == false);
    r = registry.call("project.graphics", Json::parse(R"({"latency":{"mode":"xell"}})"));
    REQUIRE(r.ok);
    CHECK(r.result["written"] == true);
    CHECK(r.result["latency"]["mode"] == "xell");
    r = registry.call("project.graphics", Json::parse(R"({"latency":{"boost":true}})"));
    REQUIRE(r.ok);
    CHECK(r.result["latency"]["mode"] == "xell");  // the key not given stays
    CHECK(r.result["latency"]["boost"] == true);
    r = registry.call("project.graphics", Json::parse(R"({"preset":"low"})"));
    REQUIRE(r.ok);
    CHECK(r.result["latency"]["mode"] == "xell");  // another key leaves it alone
    auto project = load_project(d.str());
    REQUIRE(project.ok());
    CHECK(project->latency.mode == render::LatencyMode::Xell);
    CHECK(project->latency.boost);
    const std::string before = d.read();
    r = registry.call("project.graphics", Json::parse(R"({"latency":{"mode":"reflexx"}})"));
    CHECK_FALSE(r.ok);
    CHECK(d.read() == before);
    r = registry.call("project.graphics", Json::parse(R"({"latency":{"mode":"off","boost":false}})"));
    REQUIRE(r.ok);
    CHECK(d.read().find("latency") == std::string::npos);  // at the default: the key goes
}

TEST_CASE(
    "graphics settings: render.frameGeneration is saved as its own key, read back and read by the project loader") {
    Dir d;
    d.write(kBare);
    auto s = read_graphics_settings(d.str());
    REQUIRE(s.ok());
    CHECK(s->frameGenMode == "off");
    CHECK(s->frameGenMinBaseFps == 60);
    CHECK(frame_gen_modes() == std::vector<std::string>{"off", "auto", "dlss", "fsr", "xess"});
    s->frameGenMode = "fsr";
    s->frameGenMinBaseFps = 45;
    REQUIRE(write_graphics_settings(d.str(), *s).ok());
    const std::string text = d.read();
    CHECK(text.find("\"frameGeneration\"") != std::string::npos);
    CHECK(text.find("\"physics\": { \"fixedHz\": 60 }") != std::string::npos);
    CHECK(text.find("upscaler") == std::string::npos);
    auto back = read_graphics_settings(d.str());
    REQUIRE(back.ok());
    CHECK(*back == *s);
    auto project = load_project(d.str());
    REQUIRE(project.ok());
    CHECK(project->frameGeneration.mode == render::FrameGenMode::Fsr);
    CHECK(project->frameGeneration.minBaseFps == 45);
    // A mode off with a changed minimum keeps both keys (the file says what it was told); the defaults remove the key and the empty render.
    s->frameGenMode = "off";
    REQUIRE(write_graphics_settings(d.str(), *s).ok());
    CHECK(d.read().find("\"minBaseFps\": 45") != std::string::npos);
    REQUIRE(write_graphics_settings(d.str(), GraphicsSettings{}).ok());
    CHECK(d.read() == kBare);
}

TEST_CASE("graphics settings: a wrong frame generation value is named by pointer, and nothing is written") {
    Dir d;
    d.write(kBare);
    GraphicsSettings g;
    g.frameGenMode = "dlls";
    g.frameGenMinBaseFps = 5000;
    const auto problems = check_graphics_settings(g);
    REQUIRE(problems.size() == 2);
    CHECK(problems[0].pointer == "/render/frameGeneration/mode");
    CHECK(problems[0].message.find("dlss") != std::string::npos);
    CHECK(problems[1].pointer == "/render/frameGeneration/minBaseFps");
    CHECK_FALSE(write_graphics_settings(d.str(), g).ok());
    CHECK(d.read() == kBare);
    d.write(R"({"format":"factoria.project/1","name":"G","render":{"frameGeneration":{"mode":"xes"}}})");
    auto bad = read_graphics_settings(d.str());
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("/render/frameGeneration/mode") != std::string::npos);
}

TEST_CASE("project.graphics reads and writes the frameGeneration key, and only when it is given") {
    Dir d;
    d.write(kBare);
    CommandRegistry registry;
    register_graphics_settings_commands(registry, d.str());
    auto r = registry.call("project.graphics", Json::object());
    REQUIRE(r.ok);
    CHECK(r.result["frameGeneration"]["mode"] == "off");
    CHECK(r.result["frameGeneration"]["minBaseFps"] == 60);
    CHECK(r.result["written"] == false);
    r = registry.call("project.graphics", Json::parse(R"({"frameGeneration":{"mode":"auto"}})"));
    REQUIRE(r.ok);
    CHECK(r.result["written"] == true);
    CHECK(r.result["frameGeneration"]["mode"] == "auto");
    r = registry.call("project.graphics", Json::parse(R"({"frameGeneration":{"minBaseFps":30}})"));
    REQUIRE(r.ok);
    CHECK(r.result["frameGeneration"]["mode"] == "auto");  // the key not given stays
    CHECK(r.result["frameGeneration"]["minBaseFps"] == 30);
    r = registry.call("project.graphics", Json::parse(R"({"latency":{"mode":"auto"}})"));
    REQUIRE(r.ok);
    CHECK(r.result["frameGeneration"]["minBaseFps"] == 30);  // another key leaves it alone
    auto project = load_project(d.str());
    REQUIRE(project.ok());
    CHECK(project->frameGeneration.mode == render::FrameGenMode::Auto);
    CHECK(project->frameGeneration.minBaseFps == 30);
    const std::string before = d.read();
    r = registry.call("project.graphics", Json::parse(R"({"frameGeneration":{"mode":"dlls"}})"));
    CHECK_FALSE(r.ok);
    CHECK(d.read() == before);
    r = registry.call("project.graphics", Json::parse(R"({"frameGeneration":{"minBaseFps":1.5}})"));
    CHECK_FALSE(r.ok);
    CHECK(d.read() == before);
    r = registry.call("project.graphics", Json::parse(R"({"frameGeneration":{"mode":"off","minBaseFps":60}})"));
    REQUIRE(r.ok);
    CHECK(d.read().find("frameGeneration") == std::string::npos);  // at the default: the key goes
}

TEST_CASE("frame generation modes: what render.supports says of each one, and the lines the window shows") {
    const Json report = Json::parse(R"({"features":[
        {"name":"dlssFrameGen","supported":false,"status":"needs an NVIDIA RTX GPU"},
        {"name":"fsrFrameGen","supported":true,"status":"supported"},
        {"name":"xessFrameGen","supported":false,"status":"needs an Intel Arc GPU"}]})");
    CHECK(frame_gen_mode_support(report, "off").usable);
    CHECK(frame_gen_mode_support(report, "auto").usable);
    CHECK(frame_gen_mode_support(report, "fsr").usable);
    const FrameGenModeSupport dlss = frame_gen_mode_support(report, "dlss");
    CHECK_FALSE(dlss.usable);
    CHECK(dlss.why == "needs an NVIDIA RTX GPU");
    CHECK(frame_gen_mode_support(report, "xess").why == "needs an Intel Arc GPU");
    // No report: the SDK modes are not usable, with a reason; a report without the row (an older engine) leaves them usable.
    const FrameGenModeSupport none = frame_gen_mode_support(Json::object(), "fsr");
    CHECK_FALSE(none.usable);
    CHECK_FALSE(none.why.empty());
    CHECK(frame_gen_mode_support(Json::parse(R"({"features":[]})"), "fsr").usable);

    GraphicsSettings g;
    CHECK(frame_gen_describe(g, report).find("Off:") == 0);
    g.frameGenMode = "auto";
    const std::string autoLine = frame_gen_describe(g, report);
    CHECK(autoLine.find("usable on this machine: fsr)") != std::string::npos);
    CHECK(autoLine.find("fewer than 60 frames per second") != std::string::npos);
    CHECK(autoLine.find("above 66") != std::string::npos);
    g.frameGenMinBaseFps = 0;
    CHECK(frame_gen_describe(g, report).find("never switches off") != std::string::npos);
    CHECK(frame_gen_describe(g, Json::object()).find("no SDK can run") != std::string::npos);
    g.frameGenMode = "dlss";
    const std::string no = frame_gen_describe(g, report);
    CHECK(no.find("Not usable on this machine: needs an NVIDIA RTX GPU") == 0);
    g.frameGenMode = "fsr";
    CHECK(frame_gen_describe(g, report).find("Usable on this machine") == 0);

    // The advice: only with frame generation on and no low-latency mode; DLSS-G forces Reflex, and says so.
    g = GraphicsSettings{};
    CHECK(frame_gen_latency_hint(g).empty());
    g.frameGenMode = "fsr";
    CHECK(frame_gen_latency_hint(g).find("low-latency mode") != std::string::npos);
    CHECK(frame_gen_latency_hint(g).find("Reflex") == std::string::npos);
    g.frameGenMode = "dlss";
    CHECK(frame_gen_latency_hint(g).find("turns NVIDIA Reflex on by itself") != std::string::npos);
    g.latencyMode = "auto";
    CHECK(frame_gen_latency_hint(g).empty());

    // The profiler's readout as one line.
    CHECK(frame_gen_state_line(Json::object(), 60).find("Off") == 0);
    const Json active = Json::parse(
        R"({"provider":"fsr","state":"active","baseFps":62.04,"presentedFps":124.0,"generatedFrames":3021,"reason":""})");
    CHECK(frame_gen_state_line(active, 60) == "Active (fsr): base 62.0 fps, presented 124.0 fps, 3021 generated.");
    const Json paused = Json::parse(
        R"({"provider":"fsr","state":"paused","baseFps":41.5,"presentedFps":41.5,"generatedFrames":10,"reason":"x"})");
    const std::string pausedLine = frame_gen_state_line(paused, 60);
    CHECK(pausedLine.find("below the minimum of 60 fps") != std::string::npos);
    CHECK(pausedLine.find("above 66 fps") != std::string::npos);
    const Json refused =
        Json::parse(R"({"provider":"none","state":"refused","reason":"restart the game to turn it on"})");
    CHECK(frame_gen_state_line(refused, 60) == "Refused: restart the game to turn it on");
    CHECK(frame_gen_state_line(Json::parse(R"({"state":"measuring","provider":"dlss"})"), 60).find("Measuring") == 0);
    // A null or mistyped number or string (a broken or older readout) reads as its default and never throws.
    CHECK(frame_gen_state_line(
              Json::parse(
                  R"({"state":"active","provider":"fsr","baseFps":null,"presentedFps":"x","generatedFrames":null})"),
              60) == "Active (fsr): base 0.0 fps, presented 0.0 fps, 0 generated.");
    CHECK(frame_gen_state_line(Json::parse(R"({"state":null,"provider":null,"reason":null})"), 60) ==
          "Off: nothing is generated.");
}

TEST_CASE("graphics settings: render.rayTracing and render.pathTracer are saved as their own keys, read back and read "
          "by the project loader") {
    Dir d;
    d.write(kBare);
    GraphicsSettings g;
    g.preset = "high";
    g.rayTracing.enabled = true;
    g.rayTracing.shadows = render::RtShadows::Soft;
    g.rayTracing.ao = true;
    g.rayTracing.gi = render::RtGi::Probes;
    g.rayTracing.raysPerPixel = 4;
    g.pathTracer.enabled = true;
    g.pathTracer.samplesPerFrame = 2;
    g.pathTracer.maxSamples = 128;
    REQUIRE(write_graphics_settings(d.str(), g).ok());
    const std::string text = d.read();
    CHECK(text.find("\"rayTracing\"") != std::string::npos);
    CHECK(text.find("\"pathTracer\"") != std::string::npos);
    CHECK(text.find("\"physics\": { \"fixedHz\": 60 }") != std::string::npos);
    auto back = read_graphics_settings(d.str());
    REQUIRE(back.ok());
    CHECK(*back == g);
    auto project = load_project(d.str());
    REQUIRE(project.ok());
    CHECK(project->rayTracing == g.rayTracing);
    CHECK(project->pathTracer.enabled);
    CHECK(project->pathTracer.samplesPerFrame == 2);
    CHECK(project->pathTracer.maxSamples == 128);

    // Back to the defaults removes both keys and keeps the others.
    g.rayTracing = render::RayTracingSettings{};
    g.pathTracer = render::PathTracerSettings{};
    REQUIRE(write_graphics_settings(d.str(), g).ok());
    const std::string text2 = d.read();
    CHECK(text2.find("rayTracing") == std::string::npos);
    CHECK(text2.find("pathTracer") == std::string::npos);
    CHECK(text2.find("\"graphicsPreset\": \"high\"") != std::string::npos);
}

TEST_CASE("graphics settings: a number that is not finite in the ray tracing keys is named by pointer") {
    GraphicsSettings g;
    CHECK(check_graphics_settings(g).empty());
    // Whole numbers outside their range are clamped by the engine, never an error.
    g.rayTracing.raysPerPixel = 99;
    g.pathTracer.samplesPerFrame = -4;
    CHECK(check_graphics_settings(g).empty());
    g.pathTracer.fireflyClamp = std::nanf("");
    const auto problems = check_graphics_settings(g);
    REQUIRE(problems.size() == 1);
    CHECK(problems[0].pointer == "/render/pathTracer/fireflyClamp");
    CHECK_FALSE(problems[0].message.empty());
}

TEST_CASE("project.graphics reads and writes the rayTracing and pathTracer keys, and only when they are given") {
    Dir d;
    d.write(kBare);
    CommandRegistry registry;
    register_graphics_settings_commands(registry, d.str());
    auto r = registry.call("project.graphics", Json::object());
    REQUIRE(r.ok);
    CHECK(r.result["rayTracing"]["enabled"] == false);
    CHECK(r.result["rayTracing"]["shadows"] == "off");
    CHECK(r.result["pathTracer"]["enabled"] == false);
    CHECK(d.read() == kBare);

    r = registry.call(
        "project.graphics",
        Json::parse(
            R"({"rayTracing":{"enabled":true,"shadows":"hard","ao":true},"pathTracer":{"samplesPerFrame":3}})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["written"] == true);
    CHECK(r.result["rayTracing"]["shadows"] == "hard");
    CHECK(r.result["pathTracer"]["samplesPerFrame"] == 3);
    // A later call that names one key keeps the others.
    r = registry.call("project.graphics", Json::parse(R"({"rayTracing":{"reflections":true}})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["rayTracing"]["enabled"] == true);
    CHECK(r.result["rayTracing"]["ao"] == true);
    CHECK(r.result["rayTracing"]["reflections"] == true);
    CHECK(r.result["pathTracer"]["samplesPerFrame"] == 3);
    auto project = load_project(d.str());
    REQUIRE(project.ok());
    CHECK(project->rayTracing.reflections);
    CHECK(project->rayTracing.shadows == render::RtShadows::Hard);
    // The same values again write nothing.
    const std::string before = d.read();
    r = registry.call("project.graphics", Json::parse(R"({"rayTracing":{"shadows":"hard"}})"));
    REQUIRE(r.ok);
    CHECK(r.result["written"] == false);
    CHECK(d.read() == before);
    // A wrong name is refused with a did-you-mean and writes nothing.
    r = registry.call("project.graphics", Json::parse(R"({"rayTracing":{"shadows":"sofft"}})"));
    CHECK_FALSE(r.ok);
    CHECK(r.error.dump().find("soft") != std::string::npos);
    CHECK(d.read() == before);
    // Back to the defaults removes the keys.
    r = registry.call(
        "project.graphics",
        Json::parse(
            R"({"rayTracing":{"enabled":false,"shadows":"off","ao":false,"reflections":false},"pathTracer":{"samplesPerFrame":1}})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(d.read().find("rayTracing") == std::string::npos);
    CHECK(d.read().find("pathTracer") == std::string::npos);
}

TEST_CASE("ray tracing in the window: the lists, the support row, the preset's note and the coming modes") {
    CHECK(ray_tracing_shadow_modes() == std::vector<std::string>{"off", "hard", "soft"});
    CHECK(ray_tracing_gi_modes() == std::vector<std::string>{"off", "probes", "perPixel"});
    CHECK(ray_tracing_gi_coming("probes").empty());
    CHECK(ray_tracing_gi_coming("off").empty());
    CHECK(ray_tracing_gi_coming("perPixel").find("Coming") == 0);

    const Json yes = Json::parse(R"({"features":[{"name":"raytracing","supported":true,"status":"supported"}]})");
    const Json no =
        Json::parse(R"({"features":[{"name":"raytracing","supported":false,"status":"opengl has no ray queries"}]})");
    CHECK(ray_tracing_support(yes).usable);
    const RayTracingSupport cannot = ray_tracing_support(no);
    CHECK_FALSE(cannot.usable);
    CHECK(cannot.why.find("opengl has no ray queries") == 0);
    CHECK(cannot.why.find("graphics.backend") != std::string::npos);
    CHECK_FALSE(ray_tracing_support(Json::object()).usable);
    CHECK_FALSE(ray_tracing_support(Json::parse(R"({"features":[]})")).usable);

    GraphicsSettings g;
    g.preset = "low";
    CHECK(ray_tracing_preset_note(g).empty());  // ray tracing is off: nothing to cap
    g.rayTracing.enabled = true;
    g.rayTracing.shadows = render::RtShadows::Soft;
    g.rayTracing.ao = true;
    const std::string low = ray_tracing_preset_note(g);
    CHECK(low.find("\"low\"") != std::string::npos);
    CHECK(low.find("shadows (off)") != std::string::npos);
    CHECK(low.find("ao") != std::string::npos);
    CHECK(low.find("never turns") != std::string::npos);
    g.preset = "high";
    const std::string high = ray_tracing_preset_note(g);
    CHECK(high.find("shadows (hard)") != std::string::npos);
    CHECK(high.find("ao") == std::string::npos);
    g.preset = "ultra";
    CHECK(ray_tracing_preset_note(g).empty());
    g.preset = "custom";
    CHECK(ray_tracing_preset_note(g).empty());
    // A preset that allows what is asked changes nothing: high with hard shadows and ao.
    g.preset = "high";
    g.rayTracing.shadows = render::RtShadows::Hard;
    CHECK(ray_tracing_preset_note(g).empty());
}
