// M78-P5a: frame generation in the engine (docs/FRAME_GENERATION.md): the project key, the command render.frame_generation and
// Engine::set_frame_generation. The controller and the output passes are tested in engine/render/tests/framegen_tests.cpp with fakes; a
// headless run generates nothing, so here the setting is read, written, refused and reported.
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
        dir = fs::make_temp_dir("fa_framegen_test_" + name).value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary)
            << R"({ "format": "factoria.project/1", "name": "Frame Generation Test", "id": "com.example.framegen",
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

TEST_CASE("project: render.frameGeneration loads, round-trips, defaults to off and teaches with the pointer") {
    TempProject plain("plain");
    auto s = load_project(plain.path());
    REQUIRE(s.ok());
    CHECK(s->frameGeneration == render::FrameGenSettings{});
    CHECK_FALSE(s->to_json().contains("render"));

    TempProject set("set", R"(, "render": { "frameGeneration": { "mode": "fsr", "minBaseFps": 45 } })");
    auto t = load_project(set.path());
    REQUIRE_MESSAGE(t.ok(), t.error().message);
    CHECK(t->frameGeneration.mode == render::FrameGenMode::Fsr);
    CHECK(t->frameGeneration.minBaseFps == 45);
    const Json j = t->to_json();
    REQUIRE(j.contains("render"));
    CHECK(j["render"]["frameGeneration"]["mode"] == "fsr");
    CHECK(j["render"]["frameGeneration"]["minBaseFps"] == 45);

    TempProject bad("bad", R"(, "render": { "frameGeneration": { "mode": "dlls" } })");
    auto b = load_project(bad.path());
    REQUIRE_FALSE(b.ok());
    CHECK(b.error().message.find("/render/frameGeneration/mode") != std::string::npos);
    CHECK(b.error().hint.find("dlss") != std::string::npos);  // did you mean

    TempProject badKey("badkey", R"(, "render": { "frameGeneration": { "minBaseFp": 30 } })");
    auto k = load_project(badKey.path());
    REQUIRE_FALSE(k.ok());
    CHECK(k.error().message.find("/render/frameGeneration/minBaseFp") != std::string::npos);

    TempProject badRange("badrange", R"(, "render": { "frameGeneration": { "minBaseFps": 5000 } })");
    auto r = load_project(badRange.path());
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("/render/frameGeneration/minBaseFps") != std::string::npos);
}

TEST_CASE("render.frame_generation: reads, sets, and refuses without changing anything (headless: remembered, nothing generated)") {
    TempProject p("command");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto r = c.call("render.frame_generation", Json::object());
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["mode"] == "off");
    CHECK(r.result["minBaseFps"] == 60);
    CHECK(r.result["provider"] == "none");
    CHECK(r.result["state"] == "off");
    CHECK(r.result["changed"] == false);
    CHECK(r.result.contains("report"));

    r = c.call("render.frame_generation", Json::parse(R"({"mode":"auto","minBaseFps":40})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["mode"] == "auto");
    CHECK(r.result["minBaseFps"] == 40);
    CHECK(r.result["changed"] == true);
    CHECK(r.result["provider"] == "none");  // no window: nothing generates
    CHECK(r.result["state"] == "refused");
    CHECK_FALSE(r.result["reason"].get<std::string>().empty());
    CHECK(e.frame_generation().mode == render::FrameGenMode::Auto);

    // The same value again changes nothing, and a key that is not given is kept.
    r = c.call("render.frame_generation", Json::parse(R"({"mode":"auto"})"));
    REQUIRE(r.ok);
    CHECK(r.result["changed"] == false);
    CHECK(r.result["minBaseFps"] == 40);

    // Wrong calls teach and change nothing.
    r = c.call("render.frame_generation", Json::parse(R"({"mode":"dlls"})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("dlss") != std::string::npos);
    r = c.call("render.frame_generation", Json::parse(R"({"minBaseFp":1})"));
    REQUIRE_FALSE(r.ok);
    r = c.call("render.frame_generation", Json::parse(R"({"minBaseFps":-3})"));
    REQUIRE_FALSE(r.ok);
    r = c.call("render.frame_generation", Json::parse(R"({"minBaseFps":1.5})"));
    REQUIRE_FALSE(r.ok);
    r = c.call("render.frame_generation", Json::object());
    REQUIRE(r.ok);
    CHECK(r.result["mode"] == "auto");
    CHECK(r.result["minBaseFps"] == 40);

    // The profile's readout says why nothing was generated.
    const Json readout = e.profile_frame_generation();
    CHECK(readout["generatedFrames"] == 0);
    CHECK(readout["provider"] == "none");
    CHECK_FALSE(readout["reason"].get<std::string>().empty());
}

TEST_CASE("project: a render.frameGeneration start value is the setting the engine starts with") {
    TempProject p("start", R"(, "render": { "frameGeneration": { "mode": "xess", "minBaseFps": 0 } })");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    CHECK(e.frame_generation().mode == render::FrameGenMode::Xess);
    CHECK(e.frame_generation().minBaseFps == 0);
    auto r = e.commands().call("render.frame_generation", Json::object());
    REQUIRE(r.ok);
    CHECK(r.result["mode"] == "xess");
    CHECK(r.result["provider"] == "none");
}
