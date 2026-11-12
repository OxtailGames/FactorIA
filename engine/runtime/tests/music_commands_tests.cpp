// audio.music_state and audio.music: the MusicPlayer of a scene, looked at and driven through the commands, on the engine's own headless
// audio (the null device advances with the game clock, so the answers do not depend on the machine).
#include <doctest.h>

#include <filesystem>
#include <fstream>

#include "fa/audio/music_player.h"
#include "fa/audio/song.h"
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
        dir = fs::make_temp_dir("fa_musiccmd_test_" + name).value();
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
    REQUIRE(r.result["cache"].size() == 1);  // the memory of the music: one song, its bytes per stem
    CHECK(r.result["cache"][0]["bytes"].get<std::uint64_t>() == r.result["cacheBytes"].get<std::uint64_t>());
    CHECK(r.result["cacheBytes"].get<std::uint64_t>() > 0);

    r = c.call("audio.music_state", Json::parse(R"({"entity":"theme"})"));
    REQUIRE(r.ok);
    CHECK(r.result["players"][0]["mode"] == "live");

    r = c.call("audio.music", Json::parse(R"({"entity":"theme","action":"setIntensity","intensity":1,"quantize":"none"})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["player"]["intensity"] == 1.0);
    r = c.call("audio.music", Json::parse(R"({"entity":"theme","action":"goToSection","section":"outro","quantize":"bar","fade":0.1})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["player"]["pending"] == 1);
    // The answer says where the jump lands; audio.music_state keeps saying so until it does.
    REQUIRE(r.result["change"]["frame"].is_number());
    CHECK(r.result["change"]["quantize"] == "bar");
    const Json frame = r.result["change"]["frame"];
    r = c.call("audio.music_state", Json::parse(R"({"entity":"theme"})"));
    CHECK(r.result["players"][0]["pendingSong"].is_string());
    CHECK(r.result["players"][0]["pendingSection"] == "outro");
    CHECK(r.result["players"][0]["pendingAt"] == frame);
    CHECK(r.result["players"][0]["appliedIntensity"] == 1.0);
    CHECK(r.result["players"][0]["requestedIntensity"] == 1.0);
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

TEST_CASE("hot reload: a song edited on disk reaches the player that plays it (also in the editor's assets-only mode)") {
    TempProject p("hotsong");
    {   // songs live under assets/, which is what the watcher looks at
        std::string scene = kScene;
        const std::string from = "music/test.song.json";
        scene.replace(scene.find(from), from.size(), "assets/music/test.song.json");
        stdfs::create_directories(p.dir / "assets/music");
        std::ofstream(p.dir / "scenes/main.scene.json", std::ios::binary) << scene;
        std::ofstream(p.dir / "assets/music/test.song.json", std::ios::binary) << kSong;
    }
    Engine e;
    std::string err;
    EngineConfig c = cfg(p);
    c.hotReloadAssets = true;
    REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    e.step(240);  // the watch snapshot is taken, and 4 s of music play
    auto tempo = [&] {
        auto r = e.commands().call("audio.music_state", Json::parse(R"({"entity":"theme"})"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        return r.result["players"][0]["tempo"].get<double>();
    };
    CHECK(tempo() == doctest::Approx(120.0));
    Json song = Json::parse(kSong);
    song["tempo"] = 90;
    const stdfs::path file = p.dir / "assets/music/test.song.json";
    std::ofstream(file, std::ios::binary) << song.dump();
    stdfs::last_write_time(file, stdfs::file_time_type::clock::now() + std::chrono::seconds(30));  // never the same stamp twice
    e.step(60 * 8);   // the watcher polls every 0.25 s; the crossfade waits for the next beat
    CHECK(tempo() == doctest::Approx(90.0));
    e.shutdown();
}

TEST_CASE("game.setDevice reaches a MusicPlayer in mode auto: a song with stem files plays them on a desktop, a pretended phone and after game.setDevice()") {
    TempProject p("device");
    // The stems music.render would leave, and the assets.json entry that tells where they are.
    {
        const stdfs::path before = fs::project_root();
        fs::set_project_root(p.dir);
        auto song = load_song("music/test.song.json");
        REQUIRE(bool(song));
        auto tl = expand_song(*song);
        REQUIRE(bool(tl));
        auto live = music_render_source(*song, *tl, "music/test.song.json");
        REQUIRE(bool(live));
        Json stems = Json::array();
        for (const MusicStem& st : (*live)->stems) {
            const std::string file = "assets/music/test_" + st.name + ".wav";
            std::vector<std::uint8_t> b;
            auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) b.push_back(std::uint8_t(v >> (8 * i))); };
            auto u16 = [&](std::uint16_t v) { b.push_back(std::uint8_t(v)); b.push_back(std::uint8_t(v >> 8)); };
            auto tag = [&](const char* t) { for (int i = 0; i < 4; ++i) b.push_back(std::uint8_t(t[i])); };
            tag("RIFF"); u32(std::uint32_t(36 + st.pcm.size() * 2)); tag("WAVE"); tag("fmt "); u32(16); u16(1); u16(2); u32(kMusicRate);
            u32(kMusicRate * 4); u16(4); u16(16); tag("data"); u32(std::uint32_t(st.pcm.size() * 2));
            for (std::int16_t v : st.pcm) u16(std::uint16_t(std::int32_t(std::lround(double(v) * double(st.scale)))));
            stdfs::create_directories(p.dir / "assets/music");
            std::ofstream(p.dir / file, std::ios::binary).write(reinterpret_cast<const char*>(b.data()), std::streamsize(b.size()));
            stems.push_back(Json::object({{"path", file}, {"name", st.name}, {"intensity", st.threshold}}));
        }
        Json assets = Json::object({{"format", "factoria.assets/1"},
                                    {"assets", Json::object({{"assets/music/test.wav", Json::object({{"import", Json::object({{"music", Json::object({{"role", "mix"}, {"song", "music/test.song.json"}, {"stems", stems}})}})}})}})}});
        std::ofstream(p.dir / "assets.json", std::ios::binary) << assets.dump();
        fs::set_project_root(before);
    }
    // The player of the scene says "live"; make it "auto".
    {
        std::string scene = kScene;
        const std::string live = "\"mode\": \"live\", ";
        scene.erase(scene.find(live), live.size());
        std::ofstream(p.dir / "scenes/main.scene.json", std::ios::binary) << scene;
    }
    stdfs::create_directories(p.dir / "tests");
    std::ofstream(p.dir / "tests/device.test.js", std::ios::binary) << R"(
import { test, expect, game } from "factoria:test";
import { world } from "factoria";
const mode = () => world.find('theme').music.status.mode;
test('auto plays the stem files whatever the pretended device', () => {
  game.step(30);
  expect(mode()).toBe('stems');   // a headless run reports a desktop; the song has stem files
  game.setDevice({ formFactor: 'phone', tier: 'low' });
  game.step(240);
  expect(mode()).toBe('stems');
  game.setDevice({});
  game.step(240);
  expect(mode()).toBe('stems');
});
)";
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    TestReport rep = e.scripts().run_tests({"tests/device.test.js"});
    INFO(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 1);
    e.shutdown();
}
