// The Video component through the whole engine: it follows the engine clock (time.scale 0 pauses it, scripts can still seek
// it), the headless mixer plays its sound, and a scene change takes it away without a late "ended".
#include <doctest.h>

#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/components.h"
#include "fa_test_paths.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Video Test",
  "id": "com.example.video",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "intro", "components": { "Video": { "path": "assets/video/colors.mpg", "size": [320, 180] } } }
  ]
})";

const char* kOther = R"({
  "format": "factoria.scene/1",
  "entities": [ { "id": "cam", "components": { "Camera": {} } } ]
})";

struct TempProject {
    stdfs::path dir;
    TempProject() {
        dir = fs::make_temp_dir("fa_video_player_test");
        write("factoria.json", kProject);
        write("scenes/main.scene.json", kScene);
        write("scenes/other.scene.json", kOther);
        stdfs::create_directories(dir / "assets/video");
        stdfs::copy_file(FA_VIDEO_FIXTURE, dir / "assets/video/colors.mpg");
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

Json eval(Engine& e, const std::string& code) {
    auto r = e.commands().call("script.eval", Json::object({{"code", code}}));
    INFO(code << " -> " << r.error.dump());
    REQUIRE(r.ok);
    return r.result;
}

Video* the_video(Engine& e) {
    Video* found = nullptr;
    e.world().each<Video>([&](Entity, Video& v) { found = &v; });
    return found;
}

}  // namespace

TEST_CASE("video: the engine advances a Video with its clock; time.scale 0 pauses it") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    e.step(30);
    Video* v = the_video(e);
    REQUIRE(v);
    CHECK(v->playing);
    CHECK(v->time == doctest::Approx(0.5).epsilon(0.02));
    eval(e, "time.scale = 0");
    e.step(60);
    CHECK(v->time == doctest::Approx(0.5).epsilon(0.02));  // frozen with the game
    eval(e, "globalThis.v = world.find('intro').video; v.seek(0.2)");
    e.step(2);
    CHECK(v->time == doctest::Approx(0.2).epsilon(0.001));  // a seek applies while paused
    eval(e, "time.scale = 1");
    e.step(30);
    CHECK(v->time == doctest::Approx(0.7).epsilon(0.03));
    eval(e, "time.scale = 2");  // twice as fast: the clock is time.scale times the real steps
    e.step(15);
    CHECK(v->time == doctest::Approx(1.2).epsilon(0.05));
    e.shutdown();
}

TEST_CASE("video: the headless mixer plays the sound of a Video, and a scene change stops it") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    e.step(10);
    CHECK(e.audio().stats()["activeVoices"].get<int>() == 1);
    const auto log = e.audio().play_log();
    REQUIRE(log.size() == 1);
    CHECK(log[0].path == "assets/video/colors.mpg");
    CHECK(log[0].source == "intro");
    eval(e, "globalThis.late = 0; world.on('video.ended', () => late++); scene.load('scenes/other.scene.json')");
    e.step(120);  // longer than the video: an ended event of the old scene would have come by now
    CHECK(the_video(e) == nullptr);
    CHECK(e.audio().stats()["activeVoices"].get<int>() == 0);
    CHECK(eval(e, "late")["value"].get<int>() == 0);
    e.shutdown();
}
