// The editor's command-backed pieces (the Audio feed, what Save writes), run against a real headless Engine in a temporary
// project: the same commands the panels call, the same results they show. GPU-free.
#include <filesystem>
#include <fstream>
#include <sstream>

#include "doctest.h"
#include "editor_internal.h"
#include "fa/core/image.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Editor Tools Test",
  "id": "com.example.editortools",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "name": "Camera", "components": { "Camera": { "clearColor": "#102030" } } },
    { "id": "squad", "name": "Squad", "tags": ["enemy", "tilemap:old"],
      "components": { "Transform": { "position": [120, 40, 0] }, "Shape2D": { "size": [30, 20], "color": "#cc3030" } },
      "children": [
        { "id": "gunner", "name": "Gunner",
          "components": { "Transform": { "position": [10, 5, 0] }, "Shape2D": { "shape": "circle", "size": [8, 8] } } }
      ] }
  ]
})";

struct Session {
    stdfs::path dir;
    Engine engine;

    explicit Session(const std::string& name, bool editorMode = true) {
        dir = fs::make_temp_dir("fa_editor_tools_" + name);
        stdfs::create_directories(dir / "scenes");
        write("factoria.json", kProject);
        write("scenes/main.scene.json", kScene);
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        c.editorMode = editorMode;
        std::string err;
        REQUIRE_MESSAGE(engine.init(c, nullptr, &err), err);
    }
    ~Session() {
        engine.shutdown();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    const CommandRegistry& commands() { return engine.commands(); }
    void write(const std::string& rel, const std::string& text) const {
        stdfs::create_directories((dir / rel).parent_path());
        std::ofstream(dir / rel, std::ios::binary) << text;
    }
    std::string read(const std::string& rel) const {
        std::ifstream in(dir / rel, std::ios::binary);
        std::stringstream ss;
        ss << in.rdbuf();
        return ss.str();
    }
    void tileset() const {  // 64 x 32: two 32 x 32 tiles
        Image img;
        img.width = 64;
        img.height = 32;
        img.rgba.assign(std::size_t(img.width) * img.height * 4, 200);
        REQUIRE(save_png(img, (dir / "assets/tiles.png").generic_string()).ok());
    }
    void wav(const std::string& rel) const {  // 0.1 s of silence, 16-bit mono PCM
        const std::uint32_t n = 4410;
        std::string b;
        auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) b.push_back(char((v >> (8 * i)) & 0xff)); };
        auto u16 = [&](std::uint16_t v) { b.push_back(char(v & 0xff)); b.push_back(char(v >> 8)); };
        b += "RIFF"; u32(36 + n * 2); b += "WAVEfmt "; u32(16); u16(1); u16(1); u32(44100); u32(88200); u16(2); u16(16);
        b += "data"; u32(n * 2);
        b.append(std::size_t(n) * 2, '\0');
        write(rel, b);
    }
};

const char* kCoinPrefab = R"({"format":"factoria.prefab/1","entity":{"name":"Coin","components":{"Shape2D":{"shape":"circle","size":[12,12]}}}})";

}  // namespace

// ------------------------------------------------------------------------------------------------- Saving scenes
TEST_CASE("scenes saved by the editor are already in the canonical layout") {
    Session s("canonical");
    s.tileset();
    s.write("prefabs/coin.prefab.json", kCoinPrefab);
    // The hand-written fixtures are not canonical; what the editor writes below is.
    REQUIRE(s.commands().call("scene.format", Json::object()).ok);
    // Build a scene with the things whose layout used to differ by hand: short arrays, colours, a Tilemap's rows.
    REQUIRE(s.engine.commands().call("scene.import_ascii", Json::parse(R"({
      "rows": ["..o..o..", ".o......", "########"],
      "legend": {"#": 0, "o": {"prefab": "prefabs/coin.prefab.json"}},
      "tilemap": {"tileset": "assets/tiles.png", "tileSize": [32, 32], "solidTiles": [0]}, "entity": "map"})")).ok);
    // The editor saves with save_scene_file (Editor::save_scene_now and its scene.save override).
    REQUIRE(save_scene_file(s.engine.world(), "scenes/main.scene.json").ok());
    REQUIRE(save_scene_file(s.engine.world(), "scenes/copy.scene.json").ok());
    CommandResult c = s.commands().call("scene.format", Json::object({{"check", true}}));
    REQUIRE_MESSAGE(c.ok, c.error.dump());
    CHECK_MESSAGE(c.result["notCanonical"].empty(), "not canonical: " << c.result["notCanonical"].dump());
    CHECK(c.result["errors"].empty());
    CHECK(c.result["unchanged"].get<int>() >= 2);
    // The text itself: Tilemap rows on separate lines, short arrays on one line.
    const std::string text = s.read("scenes/main.scene.json");
    CHECK(text.find("\"tileSize\": [32.0, 32.0]") != std::string::npos);
    CHECK(text.find("0,  0,  0,  0,  0,  0,  0,  0\n") != std::string::npos);  // the last map row on one line, columns aligned
}

// ------------------------------------------------------------------------------------------------- Audio panel
TEST_CASE("audio feed: polls only newer plays, keeps failed loads visible, filters and clears") {
    Session s("audio");
    s.wav("assets/blip.wav");
    s.engine.step(2);
    AudioLogState a;
    CHECK(poll_audio_log(s.commands(), a) == 0);
    CHECK(a.error.empty());
    CHECK(a.plays.empty());

    REQUIRE(s.commands().call("script.eval", Json::parse(R"({"code":"audio.play('assets/blip.wav', {bus: 'ui', volume: 0.5}); audio.play('assets/missing.wav');"})")).ok);
    CHECK(poll_audio_log(s.commands(), a) == 2);
    REQUIRE(a.plays.size() == 2);
    CHECK(a.plays[0].path == "assets/blip.wav");
    CHECK(a.plays[0].bus == "ui");
    CHECK(a.plays[0].volume == doctest::Approx(0.5f));
    CHECK(a.plays[0].ok);
    CHECK(a.plays[0].seq == 1);
    CHECK(a.plays[0].frame == s.engine.world().frame());
    CHECK(a.plays[1].path == "assets/missing.wav");
    CHECK_FALSE(a.plays[1].ok);  // a failed load is in the log, flagged
    CHECK(a.after == 2);

    // Nothing new: nothing added (the poll asks `after` the last seq).
    CHECK(poll_audio_log(s.commands(), a) == 0);
    CHECK(a.plays.size() == 2);

    // Filters.
    a.filter = "BLIP";
    CHECK(audio_play_visible(a.plays[0], a));
    CHECK_FALSE(audio_play_visible(a.plays[1], a));
    a.filter.clear();
    a.onlyFailed = true;
    CHECK_FALSE(audio_play_visible(a.plays[0], a));
    CHECK(audio_play_visible(a.plays[1], a));
    a.onlyFailed = false;

    // Clear forgets what was shown but not the position: only later plays appear.
    clear_audio_log(a);
    CHECK(a.plays.empty());
    CHECK(poll_audio_log(s.commands(), a) == 0);
    REQUIRE(s.commands().call("script.eval", Json::parse(R"({"code":"audio.play('assets/blip.wav');"})")).ok);
    CHECK(poll_audio_log(s.commands(), a) == 1);
    REQUIRE(a.plays.size() == 1);
    CHECK(a.plays[0].seq == 3);

    // A new project starts a new log at seq 1.
    reset_audio_log(a);
    CHECK(a.after == 0);
    CHECK(poll_audio_log(s.commands(), a) == 3);
}
