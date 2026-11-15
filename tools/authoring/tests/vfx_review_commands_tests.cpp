// vfx.check, vfx.budget and vfx.filmstrip: the tools that read, measure and film an effect document (the commands of
// tools/authoring, which the player does not have). vfx.play, vfx.stop and vfx.list are in engine/runtime/tests/vfx_commands_tests.cpp.
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <memory>
#include <vector>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/vfx.h"
#include "fa/scene/vfx_budget.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Vfx Test",
  "id": "com.example.vfx",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "hero", "name": "hero", "components": { "Transform": { "position": [50, 20] } } },
    { "id": "torch", "name": "torch", "components": { "Vfx": { "effect": "assets/vfx/torch.vfx.json" } } }
  ]
})";

// A flash, a sound at 0.1 s and a mixer command at 0.2 s.
const char* kHit = R"({
  "format": "factoria.vfx/1",
  "doc": "A hit",
  "parts": [
    {"type": "emitter", "name": "sparks", "emitter": {"burst": 8, "lifetime": 0.2, "maxParticles": 20}},
    {"type": "light", "name": "flash", "duration": 0.3, "light": {"intensity": 2}},
    {"type": "sound", "at": 0.1, "clip": "assets/sfx/beep.wav", "volume": 0.5, "bus": "ui"},
    {"type": "command", "at": 0.2, "command": "audio.bus", "args": {"bus": "sfx", "volume": 0.7}}
  ]})";

const char* kTorch =
    R"({"format": "factoria.vfx/1", "parts": [{"type": "light", "name": "glow", "duration": 5, "light": {"radius": 90}}]})";

std::string wav() {  // 0.1 s of silence, 16-bit mono PCM
    const std::uint32_t n = 4410;
    std::string b;
    auto u32 = [&](std::uint32_t v) {
        for (int i = 0; i < 4; ++i) b.push_back(char((v >> (8 * i)) & 0xff));
    };
    auto u16 = [&](std::uint16_t v) {
        b.push_back(char(v & 0xff));
        b.push_back(char(v >> 8));
    };
    b += "RIFF";
    u32(36 + n * 2);
    b += "WAVEfmt ";
    u32(16);
    u16(1);
    u16(1);
    u32(44100);
    u32(88200);
    u16(2);
    u16(16);
    b += "data";
    u32(n * 2);
    b.append(std::size_t(n) * 2, '\0');
    return b;
}

struct TempProject {
    stdfs::path dir;
    TempProject() {
        dir = fs::make_temp_dir("fa_vfxcmd_test").value();
        put("factoria.json", kProject);
        put("scenes/main.scene.json", kScene);
        put("assets/vfx/hit.vfx.json", kHit);
        put("assets/vfx/torch.vfx.json", kTorch);
        put("assets/sfx/beep.wav", wav());
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void put(const std::string& rel, const std::string& text) const {
        stdfs::create_directories((dir / rel).parent_path());
        std::ofstream(dir / rel, std::ios::binary) << text;
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
TEST_CASE("vfx.check: lists errors with pointers, warnings, and a missing sound") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto ok = c.call("vfx.check", Json::parse(R"({"path":"assets/vfx/hit.vfx.json"})"));
    REQUIRE(ok.result.contains("ok"));
    CHECK(ok.result["ok"] == true);
    CHECK(ok.result["parts"].size() == 4);
    CHECK(ok.result["duration"].get<double>() == doctest::Approx(0.3));

    p.put("assets/vfx/bad.vfx.json", R"({"format":"factoria.vfx/1","parts":[
        {"type":"sound","clip":"assets/sfx/absent.wav"},
        {"type":"command","command":"fs.delete"}]})");
    auto bad = c.call("vfx.check", Json::parse(R"({"path":"assets/vfx/bad.vfx.json"})"));
    REQUIRE(bad.ok);
    CHECK(bad.result["ok"] == false);
    REQUIRE(bad.result["errors"].size() >= 1);
    CHECK(bad.result["errors"][0]["pointer"] == "/parts/1/command");

    p.put("assets/vfx/gone.vfx.json",
          R"({"format":"factoria.vfx/1","parts":[{"type":"sound","clip":"assets/sfx/absent.wav"}]})");
    auto gone = c.call("vfx.check", Json::parse(R"({"path":"assets/vfx/gone.vfx.json"})"));
    REQUIRE(gone.ok);
    CHECK(gone.result["ok"] == false);
    CHECK(gone.result["errors"][0]["pointer"] == "/parts/0/clip");

    auto missing = c.call("vfx.check", Json::parse(R"({"path":"assets/vfx/none.vfx.json"})"));
    REQUIRE(missing.ok);
    CHECK(missing.result["ok"] == false);
    e.shutdown();
}

TEST_CASE("vfx.budget: the numbers of an effect, repeatable, and findings with a fix for a phone") {
    TempProject p;
    p.put("assets/vfx/heavy.vfx.json", R"({"format":"factoria.vfx/1","parts":[
        {"type":"emitter","name":"smoke","emitter":{"burst":900,"rate":0,"lifetime":1,"lifetimeVariance":0,"startSize":6,"endSize":6,"maxParticles":1000}}]})");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    const auto playingBefore =
        c.call("vfx.list", Json::object()).result["count"];  // the torch of the scene, which starts at the first step
    auto a = c.call("vfx.budget", Json::parse(R"({"path":"assets/vfx/hit.vfx.json"})"));
    REQUIRE_MESSAGE(a.ok, a.error.dump());
    CHECK(a.result["preset"] == "phone");
    CHECK(a.result["peakParticles"] == 8);
    CHECK(a.result["ok"] == true);
    CHECK(a.result["perEmitter"].size() == 1);
    CHECK(a.result["perEmitter"][0]["name"] == "sparks");
    CHECK(a.result["timeline"].size() >= 1);
    auto again = c.call("vfx.budget", Json::parse(R"({"path":"assets/vfx/hit.vfx.json"})"));
    CHECK(again.result == a.result);

    auto h = c.call("vfx.budget", Json::parse(R"({"path":"assets/vfx/heavy.vfx.json"})"));
    REQUIRE_MESSAGE(h.ok, h.error.dump());
    CHECK(h.result["ok"] == false);
    REQUIRE(h.result["findings"].size() >= 1);
    const Json& f = h.result["findings"][0];
    CHECK(f["kind"] == "particles");
    CHECK(f["pointer"] == "/parts/0/emitter/maxParticles");
    CHECK(f["fix"]["command"] == "vfx.edit");
    CHECK(f["fix"]["args"]["path"] == "assets/vfx/heavy.vfx.json");
    CHECK(
        c.call("vfx.budget", Json::parse(R"({"path":"assets/vfx/heavy.vfx.json","preset":"desktop"})")).result["ok"] ==
        true);

    // The game is untouched: the budget started no effect and made no entity.
    CHECK(c.call("vfx.list", Json::object()).result["count"] == playingBefore);

    // Errors teach.
    auto bad = c.call("vfx.budget", Json::parse(R"({"path":"assets/vfx/nope.vfx.json"})"));
    CHECK_FALSE(bad.ok);
    auto preset = c.call("vfx.budget", Json::parse(R"({"path":"assets/vfx/hit.vfx.json","preset":"console"})"));
    REQUIRE_FALSE(preset.ok);
    CHECK(preset.error.dump().find("phone") != std::string::npos);
    CHECK_FALSE(c.call("vfx.budget", Json::parse(R"({"path":"assets/vfx/hit.vfx.json","view":[0,720]})")).ok);
    e.shutdown();
}

TEST_CASE("vfx.filmstrip films an effect, steps the game and leaves no effect behind") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    const std::string png = (p.dir / "strip.png").generic_string();
    const auto before = e.frame_index();
    Json args = Json::parse(R"({"effect":"assets/vfx/hit.vfx.json","position":[40,20],"frames":4,"everyFrames":3})");
    args["path"] = png;
    auto r = c.call("vfx.filmstrip", args);
    if (!r.ok) {
        // No graphics on this machine: the error says what works without them.
        CHECK(r.error.dump().find("vfx.budget") != std::string::npos);
        const auto left = c.call("vfx.list", Json::object());  // kept: the loop must not run over a destroyed temporary
        REQUIRE(left.ok);
        for (const Json& fx : left.result["playing"]) CHECK(fx["effect"] == "assets/vfx/torch.vfx.json");
        e.shutdown();
        return;
    }
    CHECK(r.result["frames"].size() == 4);
    CHECK(r.result["effect"] == "assets/vfx/hit.vfx.json");
    CHECK(r.result["everyFrames"] == 3);
    CHECK(stdfs::exists(png));
    CHECK(r.result["width"].get<int>() > 0);
    // The game advanced: 1 frame for the start, then 3 between the 4 pictures.
    CHECK(e.frame_index() - before == 1 + 3 * 3);
    CHECK(r.result["frames"][0]["t"].get<double>() < r.result["frames"][3]["t"].get<double>());
    // The effect that was filmed is gone, whatever its length: only the scene's own torch plays.
    const auto left = c.call("vfx.list", Json::object());  // kept: the loop must not run over a destroyed temporary
    REQUIRE(left.ok);
    for (const Json& fx : left.result["playing"]) CHECK(fx["effect"] == "assets/vfx/torch.vfx.json");
    // Errors teach and do not step the game.
    const auto frame = e.frame_index();
    CHECK_FALSE(c.call("vfx.filmstrip", Json::parse(R"({"effect":"assets/vfx/nope.vfx.json"})")).ok);
    CHECK_FALSE(c.call("vfx.filmstrip", Json::parse(R"({"effect":"assets/vfx/hit.vfx.json","frames":65})")).ok);
    CHECK(e.frame_index() == frame);
    e.shutdown();
}

namespace {
const char* kScene3d = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Transform": { "position": [0, 2, 10] }, "Camera": { "projection": "perspective", "fov": 90, "primary": true } } }
  ]
})";
const char* kOrb3d =
    R"({"format":"factoria.vfx/1","parts":[{"type":"emitter","name":"orb","emitter":{"is3D":true,"burst":1,"rate":0,"lifetime":0.5,
    "lifetimeVariance":0,"startSize":5,"endSize":5,"speed":0,"speedVariance":0,"maxParticles":4}}]})";
}  // namespace

TEST_CASE("vfx.budget: a 3D emitter's overdraw is measured through the main camera, and the answer says which camera "
          "(or that there is none)") {
    TempProject p;
    p.put("scenes/main.scene.json", kScene3d);
    p.put("assets/vfx/orb.vfx.json", kOrb3d);
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto r = c.call("vfx.budget", Json::parse(R"({"path":"assets/vfx/orb.vfx.json"})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["camera"]["used"] == true);
    CHECK(r.result["camera"]["projection"] == "perspective");
    CHECK(r.result["camera"]["distance"] == kVfxDefaultCameraDistance);
    CHECK(r.result["camera"]["fov"] == 90.0);
    // 25 / (10 * 10 * 320 / 180) of the design view (320 x 180): the aspect is the design size's.
    CHECK(r.result["peakOverdraw"].get<double>() ==
          doctest::Approx(25.0 / (10.0 * 10.0 * 320.0 / 180.0)).epsilon(0.01));
    CHECK(r.result["notes"][0].get<std::string>().find("main camera") != std::string::npos);
    // A 2D effect needs no camera.
    auto flat = c.call("vfx.budget", Json::parse(R"({"path":"assets/vfx/hit.vfx.json"})"));
    REQUIRE(flat.ok);
    CHECK(flat.result["camera"]["used"] == false);
    // Destroy the camera: the same call says there is nothing to project through, and measures no overdraw.
    REQUIRE(c.call("scene.destroy", Json::parse(R"({"id":"cam"})")).ok);
    auto none = c.call("vfx.budget", Json::parse(R"({"path":"assets/vfx/orb.vfx.json"})"));
    REQUIRE_MESSAGE(none.ok, none.error.dump());
    CHECK(none.result["camera"]["used"] == false);
    CHECK(none.result["camera"]["reason"].get<std::string>().find("no active primary Camera") != std::string::npos);
    CHECK(none.result["peakOverdraw"] == 0.0);
    CHECK(none.result["peakParticles"] == 1);
    CHECK(none.result["notes"][0].get<std::string>().find("no camera") != std::string::npos);
    e.shutdown();
}

TEST_CASE("vfx.filmstrip without position: a 3D game films 5 m in front of the camera and says so; a 2D game films the "
          "middle of the view") {
    for (const bool threeD : {true, false}) {
        TempProject p;
        if (threeD) p.put("scenes/main.scene.json", kScene3d);
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
        auto& c = e.commands();
        e.step(1);
        auto r =
            c.call("vfx.filmstrip", Json::parse(R"({"effect":"assets/vfx/hit.vfx.json","frames":2,"everyFrames":1})"));
        if (!r.ok) {
            // No graphics here: the error is the one of a missing renderer, not of a missing position.
            CHECK(r.error.dump().find("position") == std::string::npos);
            e.shutdown();
            continue;
        }
        CHECK(r.result["positionDefault"] == true);
        const std::string note = r.result["positionNote"].get<std::string>();
        if (threeD) {
            CHECK(note.find("3D camera") != std::string::npos);
            CHECK(note.find("5 m") != std::string::npos);
            CHECK(r.result["position"][0].get<double>() == doctest::Approx(0.0).epsilon(0.01).scale(1.0));
            CHECK(r.result["position"][1].get<double>() == doctest::Approx(2.0).epsilon(0.01));
            CHECK(r.result["position"][2].get<double>() == doctest::Approx(5.0).epsilon(0.01));
        } else {
            CHECK(note.find("middle of the view") != std::string::npos);
        }
        // With a position the answer says it was given.
        auto given = c.call(
            "vfx.filmstrip",
            Json::parse(R"({"effect":"assets/vfx/hit.vfx.json","position":[0,2,4],"frames":2,"everyFrames":1})"));
        REQUIRE_MESSAGE(given.ok, given.error.dump());
        CHECK(given.result["positionDefault"] == false);
        CHECK_FALSE(given.result.contains("positionNote"));
        e.shutdown();
    }
}

TEST_CASE("vfx.check, vfx.budget, vfx.filmstrip: documented, closed and registered with the authoring commands") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    const std::vector<std::string> player = e.runtime_command_names();
    for (const char* name : {"vfx.check", "vfx.budget", "vfx.filmstrip"}) {
        INFO(name);
        const CommandInfo* info = e.commands().info(name);
        REQUIRE(info != nullptr);
        CHECK_FALSE(std::binary_search(player.begin(), player.end(), name));  // not a command of the player
        CHECK(info->description.find("Example") != std::string::npos);
        CHECK(info->inputSchema["additionalProperties"] == false);
        for (auto it = info->inputSchema["properties"].begin(); it != info->inputSchema["properties"].end(); ++it)
            CHECK_MESSAGE(it.value().contains("description"), it.key());
    }
    CHECK(e.commands().info("vfx.check")->readOnly);
    CHECK(e.commands().info("vfx.budget")->readOnly);
    CHECK_FALSE(e.commands().info("vfx.filmstrip")->readOnly);  // it steps the game
    // The game API of effects is still the runtime's.
    for (const char* name : {"vfx.play", "vfx.stop", "vfx.list"})
        CHECK_MESSAGE(std::binary_search(player.begin(), player.end(), name), name);
    e.shutdown();
}

TEST_CASE("vfx.check: a command part that writes files or changes settings is an error with its pointer") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    for (const char* name : {"audio.bake", "audio.create", "feel.settings"}) {
        p.put("assets/vfx/evil.vfx.json", std::string(R"({"format":"factoria.vfx/1","parts":[
            {"type":"command","command":")") + name +
                                              R"(","args":{}}]})");
        INFO(name);
        auto check = e.commands().call("vfx.check", Json::parse(R"({"path":"assets/vfx/evil.vfx.json"})"));
        REQUIRE(check.ok);
        CHECK(check.result["ok"] == false);
        CHECK(check.result["errors"][0]["pointer"] == "/parts/0/command");
    }
    e.shutdown();
}
