// The Graphics settings window's rules (fa/tooling/graphics_settings.h): reading, checking and saving render.graphicsPreset,
// render.upscaler and render.dynamicResolution in factoria.json, with the engine's own validation. No window, no GPU.
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
