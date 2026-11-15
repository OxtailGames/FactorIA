// vfx.play, vfx.stop and vfx.list, and the `vfx` API of scripts: an effect document played through the engine, headless. The
// timeline follows the fixed step, so what happens at which frame does not depend on the machine. This executable does not link
// fa_authoring, so its Engine has exactly the commands of the player (vfx.check, vfx.budget and vfx.filmstrip are tested in
// tools/authoring/tests/vfx_review_commands_tests.cpp).
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <memory>
#include <vector>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/vfx.h"
#include "fa/runtime/internal/engine_impl.h"  // Engine::Impl::vfxHost: the host an effect runs its commands with

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

TEST_CASE("vfx commands: documented, closed and registered") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    for (const char* name : {"vfx.play", "vfx.stop", "vfx.list"}) {
        INFO(name);
        const CommandInfo* info = e.commands().info(name);
        REQUIRE(info != nullptr);
        CHECK(info->description.find("Example") != std::string::npos);
        CHECK(info->inputSchema["additionalProperties"] == false);
        for (auto it = info->inputSchema["properties"].begin(); it != info->inputSchema["properties"].end(); ++it)
            CHECK_MESSAGE(it.value().contains("description"), it.key());
    }
    CHECK(e.commands().info("vfx.list")->readOnly);
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
    // Keep the result: a range-for over a member of the temporary call result would read it after it is destroyed.
    const auto after = c.call("vfx.list", Json::object());
    REQUIRE(after.ok);
    for (const Json& fx : after.result["playing"]) CHECK(fx["id"] != id);
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
            trace.push_back(
                Json::array({e.world().entity_count(), c.call("audio.log", Json::object()).result["count"]}));
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

    auto r =
        c.call("vfx.play", Json::parse(R"({"effect":"assets/vfx/hit.vfx.json","entity":"hero","position":[0,10]})"));
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

TEST_CASE("vfx: a command part cannot write files or change settings, through vfx.play") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    for (const char* name : {"audio.bake", "audio.create", "feel.settings"}) {
        p.put("assets/vfx/evil.vfx.json", std::string(R"({"format":"factoria.vfx/1","parts":[
            {"type":"command","command":")") + name +
                                              R"(","args":{}}]})");
        const std::size_t entities = e.world().entity_count();
        auto play = c.call("vfx.play", Json::parse(R"({"effect":"assets/vfx/evil.vfx.json"})"));
        INFO(name);
        CHECK_FALSE(play.ok);
        CHECK(play.error.dump().find("/parts/0/command") != std::string::npos);
        CHECK(e.world().entity_count() == entities);  // nothing started
    }
    auto list = c.call("vfx.list", Json::object());
    REQUIRE(list.ok);
    CHECK(list.result["limits"]["allowedCommands"].size() == vfx_allowed_commands().size());
    e.shutdown();
}

TEST_CASE(
    "vfx: the host of the engine checks the command name again (a document built in code cannot call audio.bake)") {
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
    CHECK(host.call("feel.shake", Json::parse(R"({"amount":0.1,"duration":0.1})")).empty());  // an allowed name runs
    const std::string wrong = host.call(
        "feel.shake", Json::parse(R"({"amount":"strong"})"));  // an allowed name with wrong arguments says why
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
    std::vector<std::string> answers;  // what the host of the engine said to each command the system called
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

    auto r = c.call(
        "script.eval",
        Json::parse(
            R"j({"code":"const fx = vfx.play('assets/vfx/hit.vfx.json', { position: [10, 20], scale: 2 }); [fx.id, vfx.playing().length]"})j"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    INFO(r.result.dump());
    CHECK(r.result["value"][0].is_string());
    CHECK(r.result["value"][1].get<int>() ==
          2);  // the torch and the new effect: one that vfx.play made counts before its first step
    e.step(2);
    CHECK(c.call("vfx.list", Json::object()).result["count"].get<int>() >= 2);
    auto bad = c.call("script.eval", Json::parse(R"j({"code":"vfx.play('assets/vfx/nope.vfx.json')"})j"));
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error["message"].get<std::string>().find("nope.vfx.json") != std::string::npos);
    auto wrong = c.call("script.eval", Json::parse(R"j({"code":"vfx.play(3)"})j"));
    REQUIRE_FALSE(wrong.ok);
    e.shutdown();
}

TEST_CASE(
    "vfx.play: the command parts of an effect run the game feel commands (shake, hit-stop, flash) at their frame") {
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

TEST_CASE("vfx: an Engine with only the commands of the player plays the sounds and commands of an effect") {
    TempProject p;
    p.put("assets/vfx/both.vfx.json", R"({
      "format": "factoria.vfx/1",
      "parts": [
        {"type": "sound", "at": 0.1, "clip": "assets/sfx/beep.wav", "volume": 0.5},
        {"type": "command", "at": 0.1, "command": "feel.shake", "args": {"amount": 0.5, "duration": 0.3}}
      ]})");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);

    // The player's set: it has the game API of effects, not the tools that check, measure and film one (tools/authoring).
    const std::vector<std::string> names = e.runtime_command_names();
    auto has = [&](const char* n) { return std::find(names.begin(), names.end(), n) != names.end(); };
    for (const char* n : {"vfx.play", "vfx.stop", "vfx.list"}) CHECK_MESSAGE(has(n), n);
    for (const char* n : {"vfx.check", "vfx.budget", "vfx.filmstrip", "mesh.create", "mesh.update", "mesh.destroy",
                          "mesh.save", "mesh.list", "mesh.info"}) {
        CHECK_FALSE_MESSAGE(has(n), n);
        CHECK_FALSE_MESSAGE(e.commands().has(n), n);
    }

    // update_vfx plays the sound and calls the command through Impl::vfxHost, which must be filled without the authoring commands.
    REQUIRE(e.runtime_impl().vfxHost.play_sound);
    REQUIRE(e.runtime_impl().vfxHost.call);
    auto play = e.commands().call("vfx.play", Json::parse(R"({"effect":"assets/vfx/both.vfx.json"})"));
    REQUIRE_MESSAGE(play.ok, play.error.dump());
    e.step(5);
    CHECK(e.commands().call("audio.log", Json::object()).result["count"] == 0);
    CHECK(e.commands().call("feel.state", Json::object()).result["entities"].size() == 0);
    e.step(2);
    const auto log = e.commands().call("audio.log", Json::object());
    REQUIRE(log.ok);
    CHECK(log.result["count"] == 1);
    const auto st = e.commands().call("feel.state", Json::object());
    REQUIRE_MESSAGE(st.ok, st.error.dump());
    REQUIRE(st.result["entities"].size() == 1);  // the camera: the effect called feel.shake
    CHECK(st.result["entities"][0]["shake"]["trauma"].get<double>() > 0.0);
    e.shutdown();
}
