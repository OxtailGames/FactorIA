// audio.music_state and audio.music: the MusicPlayer of a scene, looked at and driven through the commands, on the engine's own headless
// audio (the null device advances with the game clock, so the answers do not depend on the machine).
#include <doctest.h>

#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Music Commands Test",
  "id": "com.example.musiccommands",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "theme", "name": "theme", "components": { "MusicPlayer": { "song": "music/test.song.json", "mode": "live", "volume": 1, "layerFade": 0.1 } } },
    { "id": "plain", "name": "plain", "components": { "Transform": {} } }
  ]
})";

const char* kSong = R"({
  "format": "factoria.song/1", "tempo": 120, "volume": 1.0,
  "mixer": {"master": {"loudness": "off", "limiter": false}},
  "tracks": {
    "pad": {"instrument": "pad", "patterns": {"a": "(Am@3):1 | (F@3):1", "i": "(Am@3):1", "o": "(F@3):1"}},
    "drums": {"instrument": "kit", "patterns": {"g": {"step": "8", "grid": {"kick": "x...x...", "hat": "x.x.x.x."}}}}
  },
  "layers": {"rhythm": ["drums"], "harmony": {"tracks": ["pad"], "intensity": 0.5}},
  "sections": [
    {"name": "intro", "kind": "intro", "play": {"pad": "i"}},
    {"name": "main", "kind": "loop", "play": {"pad": "a", "drums": "g*2"}},
    {"name": "outro", "kind": "outro", "play": {"pad": "o"}}]})";

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name) {
        dir = fs::make_temp_dir("fa_musiccmd_test_" + name);
        stdfs::create_directories(dir / "scenes");
        stdfs::create_directories(dir / "music");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary) << kScene;
        std::ofstream(dir / "music/test.song.json", std::ios::binary) << kSong;
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

TEST_CASE("audio.music_state and audio.music: the commands are documented and closed") {
    TempProject p("docs");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    for (const char* name : {"audio.music_state", "audio.music"}) {
        INFO(name);
        const CommandInfo* info = e.commands().info(name);
        REQUIRE(info != nullptr);
        CHECK(info->description.find("Example") != std::string::npos);
        CHECK(info->category == "audio");
        CHECK(info->inputSchema["additionalProperties"] == false);
    }
    CHECK(e.commands().info("audio.music_state")->readOnly);
    CHECK_FALSE(e.commands().info("audio.music")->readOnly);
    e.shutdown();
}

TEST_CASE("audio.music_state: the player of the scene plays, and audio.music drives it") {
    TempProject p("drive");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    e.step(5);
    auto r = c.call("audio.music_state", Json::object());
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    REQUIRE(r.result["players"].size() == 1);
    CHECK(r.result["players"][0]["entity"] == "theme");
    CHECK(r.result["players"][0]["ready"] == true);
    CHECK(r.result["players"][0]["playing"] == true);
    CHECK(r.result["players"][0]["section"] == "intro");
    CHECK(r.result["players"][0]["sections"] == Json::parse(R"(["intro","main","outro"])"));
    CHECK(r.result["mixedFrames"].get<std::uint64_t>() > 0);

    r = c.call("audio.music_state", Json::parse(R"({"entity":"theme"})"));
    REQUIRE(r.ok);
    CHECK(r.result["players"][0]["mode"] == "live");

    r = c.call("audio.music", Json::parse(R"({"entity":"theme","action":"setIntensity","intensity":1,"quantize":"none"})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["player"]["intensity"] == 1.0);
    r = c.call("audio.music", Json::parse(R"({"entity":"theme","action":"goToSection","section":"outro","quantize":"bar","fade":0.1})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["player"]["pending"] == 1);
    e.step(130);  // 2.2 s: the bar line at 2 s passed
    r = c.call("audio.music_state", Json::parse(R"({"entity":"theme"})"));
    CHECK(r.result["players"][0]["section"] == "outro");
    CHECK(r.result["players"][0]["pending"] == 0);
    r = c.call("audio.music", Json::parse(R"({"entity":"theme","action":"stop","fade":0.1})"));
    REQUIRE(r.ok);
    e.shutdown();
}

TEST_CASE("audio.music: a call that cannot be made says why") {
    TempProject p("errors");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    e.step(5);
    auto r = c.call("audio.music", Json::parse(R"({"entity":"plain","action":"play"})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("no MusicPlayer") != std::string::npos);
    CHECK(r.error["hint"].get<std::string>().find("scene.set_component") != std::string::npos);
    r = c.call("audio.music_state", Json::parse(R"({"entity":"plain"})"));
    CHECK_FALSE(r.ok);
    r = c.call("audio.music", Json::parse(R"({"entity":"theme","action":"goToSection","section":"bos"})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("intro") != std::string::npos);
    r = c.call("audio.music", Json::parse(R"({"entity":"theme","action":"goToSection"})"));
    CHECK_FALSE(r.ok);
    r = c.call("audio.music", Json::parse(R"({"entity":"theme","action":"dance"})"));
    CHECK_FALSE(r.ok);
    r = c.call("audio.music", Json::parse(R"({"entity":"theme","action":"stop","quantize":"bars"})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["hint"].get<std::string>().find("beat") != std::string::npos);
    r = c.call("audio.music", Json::parse(R"({"entity":"theme","action":"stop","quantise":"bar"})"));
    CHECK_FALSE(r.ok);  // a key the command does not declare
    r = c.call("audio.music", Json::parse(R"({"entity":"theme","action":"crossfadeTo","song":"music/nope.song.json"})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("does not exist") != std::string::npos);
    e.shutdown();
}
