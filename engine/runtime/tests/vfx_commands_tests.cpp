// vfx.play, vfx.stop, vfx.list and vfx.check, and the `vfx` API of scripts: an effect document played through the engine, headless. The
// timeline follows the fixed step, so what happens at which frame does not depend on the machine.
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <memory>
#include <vector>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/vfx.h"
#include "fa/scene/vfx_budget.h"
#include "../src/engine_impl.h"  // Engine::Impl::vfxHost: the host an effect runs its commands with

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

const char* kTorch = R"({"format": "factoria.vfx/1", "parts": [{"type": "light", "name": "glow", "duration": 5, "light": {"radius": 90}}]})";

std::string wav() {  // 0.1 s of silence, 16-bit mono PCM
    const std::uint32_t n = 4410;
    std::string b;
    auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) b.push_back(char((v >> (8 * i)) & 0xff)); };
    auto u16 = [&](std::uint16_t v) { b.push_back(char(v & 0xff)); b.push_back(char(v >> 8)); };
    b += "RIFF"; u32(36 + n * 2); b += "WAVEfmt "; u32(16); u16(1); u16(1); u32(44100); u32(88200); u16(2); u16(16);
    b += "data"; u32(n * 2);
    b.append(std::size_t(n) * 2, '\0');
    return b;
}

struct TempProject {
    stdfs::path dir;
    TempProject() {
        dir = fs::make_temp_dir("fa_vfxcmd_test");
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

TEST_CASE("vfx commands: documented, closed and registered") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    for (const char* name : {"vfx.play", "vfx.stop", "vfx.list", "vfx.check", "vfx.budget", "vfx.filmstrip"}) {
        INFO(name);
        const CommandInfo* info = e.commands().info(name);
        REQUIRE(info != nullptr);
        CHECK(info->description.find("Example") != std::string::npos);
        CHECK(info->inputSchema["additionalProperties"] == false);
        for (auto it = info->inputSchema["properties"].begin(); it != info->inputSchema["properties"].end(); ++it)
            CHECK_MESSAGE(it.value().contains("description"), it.key());
    }
    CHECK(e.commands().info("vfx.check")->readOnly);
    CHECK(e.commands().info("vfx.budget")->readOnly);
    CHECK_FALSE(e.commands().info("vfx.filmstrip")->readOnly);  // it steps the game
    CHECK_FALSE(e.commands().info("vfx.play")->readOnly);
    e.shutdown();
}

TEST_CASE("vfx.play: the parts happen at their frames, the sound reaches the mixer and the command is called") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto r = c.call("vfx.play", Json::parse(R"({"effect":"assets/vfx/hit.vfx.json","position":[120,64]})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const std::string id = r.result["id"];
    CHECK(r.result["dropped"] == false);
    CHECK(r.result["duration"].get<double>() == doctest::Approx(0.3));
    CHECK(e.world().get<Transform>(e.world().find_by_id(id))->position.x == doctest::Approx(120.0f));

    // vfx.list shows the effect at once, before any step ran (time 0), with its duration.
    {
        auto now = c.call("vfx.list", Json::object());
        REQUIRE(now.ok);
        bool found = false;
        for (const Json& fx : now.result["playing"])
            if (fx["id"] == id) {
                found = true;
                CHECK(fx["time"].get<double>() == doctest::Approx(0.0));
                CHECK(fx["duration"].get<double>() == doctest::Approx(0.3));
            }
        CHECK(found);
    }

    // 0.1 s = 6 frames at 60 Hz: the sound is played in the 6th frame, not before.
    e.step(5);
    CHECK(c.call("audio.log", Json::object()).result["count"] == 0);
    e.step(2);
    auto log = c.call("audio.log", Json::object());
    REQUIRE(log.ok);
    REQUIRE(log.result["count"] == 1);
    CHECK(log.result["plays"][0]["path"] == "assets/sfx/beep.wav");
    CHECK(log.result["plays"][0]["bus"] == "ui");
    CHECK(log.result["plays"][0]["volume"].get<double>() == doctest::Approx(0.5));

    auto list = c.call("vfx.list", Json::object());
    REQUIRE(list.ok);
    CHECK(list.result["count"].get<int>() >= 1);

    e.step(60);  // well past the end at 0.3 s: the sound played once, the effect is no longer playing
    CHECK(c.call("audio.log", Json::object()).result["count"] == 1);
    for (const Json& fx : c.call("vfx.list", Json::object()).result["playing"])
        CHECK(fx["id"] != id);
    e.shutdown();
}

TEST_CASE("vfx.play: the same calls at the same frames give the same result twice") {
    auto run = []() {
        TempProject p;
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
        auto& c = e.commands();
        Json trace = Json::array();
        e.step(3);
        REQUIRE(c.call("vfx.play", Json::parse(R"({"effect":"assets/vfx/hit.vfx.json","speed":1.5})")).ok);
        for (int i = 0; i < 30; ++i) {
            e.step(1);
            trace.push_back(Json::array({e.world().entity_count(), c.call("audio.log", Json::object()).result["count"]}));
        }
        e.shutdown();
        return trace;
    };
    CHECK(run() == run());
}

TEST_CASE("vfx.play: errors name the problem; a follow target and vfx.stop work") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto bad = c.call("vfx.play", Json::parse(R"({"effect":"assets/vfx/nope.vfx.json"})"));
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error["message"].get<std::string>().find("nope.vfx.json") != std::string::npos);
    CHECK_FALSE(c.call("vfx.play", Json::parse(R"({"effect":"assets/vfx/hit.vfx.json","position":[1]})")).ok);
    CHECK_FALSE(c.call("vfx.play", Json::parse(R"({"effect":"assets/vfx/hit.vfx.json","position":[1,"a"]})")).ok);
    CHECK_FALSE(c.call("vfx.play", Json::parse(R"({"effect":"assets/vfx/hit.vfx.json","entity":"nobody"})")).ok);
    CHECK_FALSE(c.call("vfx.play", Json::parse(R"({"effect":"assets/vfx/hit.vfx.json","speed":0})")).ok);

    auto r = c.call("vfx.play", Json::parse(R"({"effect":"assets/vfx/hit.vfx.json","entity":"hero","position":[0,10]})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const std::string id = r.result["id"];
    CHECK(e.world().id_of(e.world().parent(e.world().find_by_id(id))) == "hero");
    CHECK_FALSE(c.call("vfx.stop", Json::parse(R"({"id":"hero"})")).ok);  // no Vfx on it
    REQUIRE(c.call("vfx.stop", Json::parse("{\"id\":\"" + id + "\",\"immediate\":true}")).ok);
    e.step(1);
    CHECK(e.world().find_by_id(id).is_null());
    e.shutdown();
}

TEST_CASE("vfx.play: past 64 playing effects a play is dropped, not an error") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    // the torch of the scene plays too: 63 more fill the budget
    for (int i = 0; i < kVfxMaxPlaying; ++i) {
        auto r = c.call("vfx.play", Json::parse(R"({"effect":"assets/vfx/hit.vfx.json"})"));
        REQUIRE(r.ok);
    }
    e.step(1);
    auto over = c.call("vfx.play", Json::parse(R"({"effect":"assets/vfx/hit.vfx.json"})"));
    REQUIRE(over.ok);
    CHECK(over.result["dropped"] == true);
    CHECK(over.result["id"].is_null());
    e.shutdown();
}

TEST_CASE("vfx: a command part cannot write files or change settings, through vfx.play and vfx.check") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    for (const char* name : {"audio.bake", "audio.create", "feel.settings"}) {
        p.put("assets/vfx/evil.vfx.json", std::string(R"({"format":"factoria.vfx/1","parts":[
            {"type":"command","command":")") + name + R"(","args":{}}]})");
        const std::size_t entities = e.world().entity_count();
        auto play = c.call("vfx.play", Json::parse(R"({"effect":"assets/vfx/evil.vfx.json"})"));
        INFO(name);
        CHECK_FALSE(play.ok);
        CHECK(play.error.dump().find("/parts/0/command") != std::string::npos);
        CHECK(e.world().entity_count() == entities);  // nothing started
        auto check = c.call("vfx.check", Json::parse(R"({"path":"assets/vfx/evil.vfx.json"})"));
        REQUIRE(check.ok);
        CHECK(check.result["ok"] == false);
        CHECK(check.result["errors"][0]["pointer"] == "/parts/0/command");
    }
    auto list = c.call("vfx.list", Json::object());
    REQUIRE(list.ok);
    CHECK(list.result["limits"]["allowedCommands"].size() == vfx_allowed_commands().size());
    e.shutdown();
}

TEST_CASE("vfx: the host of the engine checks the command name again (a document built in code cannot call audio.bake)") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    const VfxHost& host = e.runtime_impl().vfxHost;
    REQUIRE(host.call);
    for (const char* name : {"audio.bake", "audio.create", "feel.settings", "fs.write", "game.quit"}) {
        INFO(name);
        const std::string why = host.call(name, Json::object());
        CHECK(why.find("may not call") != std::string::npos);
        CHECK(why.find(name) != std::string::npos);
    }
    CHECK(host.call("feel.shake", Json::parse(R"({"amount":0.1,"duration":0.1})")).empty());   // an allowed name runs
    const std::string wrong = host.call("feel.shake", Json::parse(R"({"amount":"strong"})"));   // an allowed name with wrong arguments says why
    CHECK_FALSE(wrong.empty());
    CHECK(wrong.find("may not call") == std::string::npos);

    // The same through the system: a document built in memory, handed over by VfxHost::load, never reaches the command.
    auto doc = std::make_shared<VfxDoc>();
    doc->duration = 0.2;
    VfxPart part;
    part.kind = VfxPartKind::Command;
    part.name = "evil";
    part.at = 0.0;
    part.command = "audio.bake";
    part.args = Json::object();
    doc->parts.push_back(part);
    VfxHost hosted = host;
    std::vector<std::string> answers;   // what the host of the engine said to each command the system called
    hosted.call = [&](const std::string& command, const Json& args) {
        answers.push_back(host.call(command, args));
        return answers.back();
    };
    hosted.load = [doc](const std::string&) { return std::shared_ptr<const VfxDoc>(doc); };
    World w;
    Entity fx = w.create("fx");
    auto& v = w.add<Vfx>(fx);
    v.effect = "memory.vfx.json";
    v.autoplay = true;
    update_vfx(w, 0.05f, hosted);
    update_vfx(w, 0.05f, hosted);
    REQUIRE(answers.size() == 1);
    CHECK(answers[0].find("may not call 'audio.bake'") != std::string::npos);
    e.shutdown();
}

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

    p.put("assets/vfx/gone.vfx.json", R"({"format":"factoria.vfx/1","parts":[{"type":"sound","clip":"assets/sfx/absent.wav"}]})");
    auto gone = c.call("vfx.check", Json::parse(R"({"path":"assets/vfx/gone.vfx.json"})"));
    REQUIRE(gone.ok);
    CHECK(gone.result["ok"] == false);
    CHECK(gone.result["errors"][0]["pointer"] == "/parts/0/clip");

    auto missing = c.call("vfx.check", Json::parse(R"({"path":"assets/vfx/none.vfx.json"})"));
    REQUIRE(missing.ok);
    CHECK(missing.result["ok"] == false);
    e.shutdown();
}

TEST_CASE("Vfx component: an effect placed in a scene plays at the start, and scripts play effects with vfx.play") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    e.step(3);
    const Entity torch = e.world().find_by_id("torch");
    REQUIRE_FALSE(torch.is_null());
    CHECK(e.world().get<Vfx>(torch)->playing);
    CHECK(e.world().children(torch).size() == 1);  // the glow

    auto r = c.call("script.eval", Json::parse(R"j({"code":"const fx = vfx.play('assets/vfx/hit.vfx.json', { position: [10, 20], scale: 2 }); [fx.id, vfx.playing().length]"})j"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    INFO(r.result.dump());
    CHECK(r.result["value"][0].is_string());
    CHECK(r.result["value"][1].get<int>() == 2);  // the torch and the new effect: one that vfx.play made counts before its first step
    e.step(2);
    CHECK(c.call("vfx.list", Json::object()).result["count"].get<int>() >= 2);
    auto bad = c.call("script.eval", Json::parse(R"j({"code":"vfx.play('assets/vfx/nope.vfx.json')"})j"));
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error["message"].get<std::string>().find("nope.vfx.json") != std::string::npos);
    auto wrong = c.call("script.eval", Json::parse(R"j({"code":"vfx.play(3)"})j"));
    REQUIRE_FALSE(wrong.ok);
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
    const auto playingBefore = c.call("vfx.list", Json::object()).result["count"];  // the torch of the scene, which starts at the first step
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
    CHECK(c.call("vfx.budget", Json::parse(R"({"path":"assets/vfx/heavy.vfx.json","preset":"desktop"})")).result["ok"] == true);

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
        for (const Json& fx : c.call("vfx.list", Json::object()).result["playing"]) CHECK(fx["effect"] == "assets/vfx/torch.vfx.json");
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
    for (const Json& fx : c.call("vfx.list", Json::object()).result["playing"]) CHECK(fx["effect"] == "assets/vfx/torch.vfx.json");
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
const char* kOrb3d = R"({"format":"factoria.vfx/1","parts":[{"type":"emitter","name":"orb","emitter":{"is3D":true,"burst":1,"rate":0,"lifetime":0.5,
    "lifetimeVariance":0,"startSize":5,"endSize":5,"speed":0,"speedVariance":0,"maxParticles":4}}]})";
}  // namespace

TEST_CASE("vfx.budget: a 3D emitter's overdraw is measured through the main camera, and the answer says which camera (or that there is none)") {
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
    CHECK(r.result["peakOverdraw"].get<double>() == doctest::Approx(25.0 / (10.0 * 10.0 * 320.0 / 180.0)).epsilon(0.01));
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

TEST_CASE("vfx.filmstrip without position: a 3D game films 5 m in front of the camera and says so; a 2D game films the middle of the view") {
    for (const bool threeD : {true, false}) {
        TempProject p;
        if (threeD) p.put("scenes/main.scene.json", kScene3d);
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
        auto& c = e.commands();
        e.step(1);
        auto r = c.call("vfx.filmstrip", Json::parse(R"({"effect":"assets/vfx/hit.vfx.json","frames":2,"everyFrames":1})"));
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
        auto given = c.call("vfx.filmstrip", Json::parse(R"({"effect":"assets/vfx/hit.vfx.json","position":[0,2,4],"frames":2,"everyFrames":1})"));
        REQUIRE_MESSAGE(given.ok, given.error.dump());
        CHECK(given.result["positionDefault"] == false);
        CHECK_FALSE(given.result.contains("positionNote"));
        e.shutdown();
    }
}

TEST_CASE("vfx.play: the command parts of an effect run the game feel commands (shake, hit-stop, flash) at their frame") {
    TempProject p;
    p.put("assets/vfx/impact.vfx.json", R"({
      "format": "factoria.vfx/1",
      "parts": [
        {"type": "command", "at": 0.1, "command": "feel.shake", "args": {"amount": 0.5, "duration": 0.3}},
        {"type": "command", "at": 0.1, "command": "feel.hitStop", "args": {"duration": 0.2}},
        {"type": "command", "at": 0.1, "command": "feel.flash", "args": {"entity": "hero", "duration": 0.5, "fade": false}}
      ]})");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto state = [&]() {
        auto r = c.call("feel.state", Json::object());
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        return r.result;
    };
    auto entry = [&](const char* id) {
        const Json st = state();  // a named object: a range-for over a temporary's member would dangle
        for (const Json& j : st["entities"])
            if (j["entity"] == id) return j;
        return Json();
    };
    auto play = c.call("vfx.play", Json::parse(R"({"effect":"assets/vfx/impact.vfx.json"})"));
    REQUIRE_MESSAGE(play.ok, play.error.dump());

    // 0.1 s = 6 frames at 60 Hz: nothing has run before the 6th.
    e.step(5);
    CHECK(state()["hitStop"]["remaining"].get<double>() == doctest::Approx(0.0));
    CHECK(entry("cam").is_null());
    CHECK(entry("hero").is_null());

    e.step(2);
    CHECK(state()["hitStop"]["remaining"].get<double>() > 0.0);
    const Json cam = entry("cam");
    REQUIRE_FALSE(cam.is_null());
    CHECK(cam["shake"]["trauma"].get<double>() > 0.0);
    const Json hero = entry("hero");
    REQUIRE_FALSE(hero.is_null());
    CHECK(hero.contains("flash"));
    e.shutdown();
}
