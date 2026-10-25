// Bus effects and snapshots through the whole engine: the "audio" section of factoria.json becomes the snapshot catalog, and the
// audio.bus and audio.snapshot commands (one registry for scripts, MCP and the CLI) drive the mixer.
#include <doctest.h>

#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name, const std::string& audioSection) {
        dir = fs::make_temp_dir("fa_audiofx_test_" + name);
        write("factoria.json", std::string(R"({
  "format": "factoria.project/1",
  "name": "Audio Fx Test",
  "id": "com.example.audiofx",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" })") +
                                    (audioSection.empty() ? "" : ",\n  \"audio\": " + audioSection) + "\n}");
        write("scenes/main.scene.json", R"({ "format": "factoria.scene/1", "entities": [ { "id": "cam", "components": { "Camera": {} } } ] })");
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const std::string& rel, const std::string& text) const {
        stdfs::create_directories((dir / rel).parent_path());
        std::ofstream(dir / rel, std::ios::binary) << text;
    }
    EngineConfig config() const {
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        return c;
    }
};

const char* kSnapshots = R"({"snapshots": {
    "underwater": {"fade": 0.8, "buses": {"sfx": {"lowpass": 600, "reverb": 0.3}, "music": {"volume": 0.5, "lowpass": 400}}},
    "normal": {}}})";

}  // namespace

TEST_CASE("audio fx: the catalog comes from factoria.json and audio.snapshot applies it") {
    TempProject p("catalog", kSnapshots);
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    CommandRegistry& c = e.commands();
    REQUIRE(c.info("audio.bus") != nullptr);
    REQUIRE(c.info("audio.snapshot") != nullptr);
    CHECK(c.info("audio.snapshot")->category == "audio");

    auto list = c.call("audio.snapshot", Json::object());
    REQUIRE(list.ok);
    CHECK(list.result["snapshots"] == Json::parse(R"(["normal", "underwater"])"));
    CHECK(list.result["current"] == "");

    auto applied = c.call("audio.snapshot", Json::object({{"name", "underwater"}, {"fade", 0}}));
    REQUIRE_MESSAGE(applied.ok, applied.error.dump());
    CHECK(applied.result["current"] == "underwater");
    auto sfx = c.call("audio.bus", Json::object({{"bus", "sfx"}}));
    REQUIRE(sfx.ok);
    CHECK(sfx.result["lowpass"].get<double>() == doctest::Approx(600.0));
    CHECK(sfx.result["reverb"].get<double>() == doctest::Approx(0.3));
    auto music = c.call("audio.bus", Json::object({{"bus", "music"}}));
    CHECK(music.result["snapshotVolume"].get<double>() == doctest::Approx(0.5));
    CHECK(music.result["volume"].get<double>() == doctest::Approx(1.0));

    auto back = c.call("audio.snapshot", Json::object({{"name", "normal"}, {"fade", 0}}));
    REQUIRE(back.ok);
    CHECK(c.call("audio.bus", Json::object({{"bus", "sfx"}})).result["lowpass"].get<double>() == doctest::Approx(0.0));

    auto bad = c.call("audio.snapshot", Json::object({{"name", "underwatr"}}));
    CHECK_FALSE(bad.ok);
    CHECK(bad.error.dump().find("underwater") != std::string::npos);
}

TEST_CASE("audio fx: audio.bus sets only the keys it is given and teaches on a mistake") {
    TempProject p("bus", "");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    CommandRegistry& c = e.commands();

    auto r = c.call("audio.bus", Json::parse(R"({"bus": "music", "lowpass": 800, "reverb": 0.2, "fade": 0})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["bus"] == "music");
    CHECK(r.result["lowpass"].get<double>() == doctest::Approx(800.0));
    r = c.call("audio.bus", Json::parse(R"({"bus": "music", "duck": {"by": "sfx", "amount": 0.6}})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["duck"]["by"] == "sfx");
    CHECK(r.result["duck"]["amount"].get<double>() == doctest::Approx(0.6));
    CHECK(r.result["lowpass"].get<double>() == doctest::Approx(800.0));  // untouched
    r = c.call("audio.bus", Json::parse(R"({"bus": "music", "lowpass": null, "duck": null})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["lowpass"].get<double>() == doctest::Approx(0.0));
    CHECK(r.result["duck"].is_null());

    CHECK_FALSE(c.call("audio.bus", Json::parse(R"({"bus": "musci"})")).ok);
    auto self = c.call("audio.bus", Json::parse(R"({"bus": "music", "duck": {"by": "music"}})"));
    CHECK_FALSE(self.ok);
    CHECK(self.error.dump().find("cannot duck itself") != std::string::npos);
    auto noBy = c.call("audio.bus", Json::parse(R"({"bus": "music", "duck": {"amount": 0.5}})"));
    CHECK_FALSE(noBy.ok);
    CHECK(noBy.error.dump().find("\\\"by\\\"") != std::string::npos);
    CHECK_FALSE(c.call("audio.bus", Json::parse(R"({"bus": "master", "duck": {"by": "sfx"}})")).ok);

    // No catalog in the project: the command says so instead of failing silently.
    auto none = c.call("audio.snapshot", Json::parse(R"({"name": "underwater"})"));
    CHECK_FALSE(none.ok);
}

TEST_CASE("audio fx: a section with mistakes is reported and counts as empty") {
    TempProject p("broken", R"({"snapshots": {"loud": {"buses": {"sfxx": {"lowpass": 600}}}}})");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    auto list = e.commands().call("audio.snapshot", Json::object());
    REQUIRE(list.ok);
    CHECK(list.result["snapshots"].empty());
}
