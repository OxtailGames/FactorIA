// A loading screen through the whole engine: scene.preload runs a little every frame, so the loading scene keeps running
// (its bar grows frame by frame) until the level is read, and the scene.load that follows reads nothing from the disk.
#include <doctest.h>

#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/components.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Preload Test",
  "id": "com.example.preload",
  "mainScene": "scenes/loading.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" }
})";

const char* kLoading = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "bar", "components": { "Transform": {}, "Shape2D": { "size": [1, 8] }, "Script": { "path": "scripts/loading.js" } } }
  ]
})";

const char* kLevel = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "m1", "components": { "Transform": {}, "MeshRenderer": { "mesh": "assets/m1.glb" } } },
    { "id": "m2", "components": { "Transform": {}, "MeshRenderer": { "mesh": "assets/m2.glb" } } },
    { "id": "m3", "components": { "Transform": {}, "MeshRenderer": { "mesh": "assets/m3.glb" } } },
    { "id": "m4", "components": { "Transform": {}, "MeshRenderer": { "mesh": "assets/m4.glb" } } },
    { "id": "m5", "components": { "Transform": {}, "MeshRenderer": { "mesh": "assets/m5.glb" } } },
    { "id": "m6", "components": { "Transform": {}, "MeshRenderer": { "mesh": "assets/m6.glb" } } },
    { "id": "m7", "components": { "Transform": {}, "MeshRenderer": { "mesh": "assets/m7.glb" } } },
    { "id": "m8", "components": { "Transform": {}, "MeshRenderer": { "mesh": "assets/m8.glb" } } },
    { "id": "m9", "components": { "Transform": {}, "MeshRenderer": { "mesh": "assets/m9.glb" } } },
    { "id": "m10", "components": { "Transform": {}, "MeshRenderer": { "mesh": "assets/m10.glb" } } },
    { "id": "m11", "components": { "Transform": {}, "MeshRenderer": { "mesh": "assets/m11.glb" } } },
    { "id": "m12", "components": { "Transform": {}, "MeshRenderer": { "mesh": "assets/m12.glb" } } }
  ]
})";

const char* kScript = R"JS(
import { Behaviour, scene } from "factoria";
export default class Loading extends Behaviour {
  onStart() {
    this.frames = 0;
    this.job = scene.preload("scenes/level.scene.json");
    this.job.promise.then(() => { scene.load("scenes/level.scene.json"); });
  }
  onUpdate() {
    this.frames++;
    globalThis.loadingFrames = this.frames;
    this.entity.get("Shape2D").size = [Math.max(1, 300 * this.job.progress), 8];
  }
}
)JS";

struct TempProject {
    stdfs::path dir;
    TempProject() {
        dir = fs::make_temp_dir("fa_preload_test");
        write("factoria.json", kProject);
        write("scenes/loading.scene.json", kLoading);
        write("scenes/level.scene.json", kLevel);
        write("scripts/loading.js", kScript);
        for (int i = 1; i <= 12; ++i) write("assets/m" + std::to_string(i) + ".glb", std::string(1000, 'x'));
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

}  // namespace

TEST_CASE("preload: a loading screen keeps running while the level is read, then the load reads nothing") {
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    e.step(1);
    REQUIRE(e.world().scene_path() == "scenes/loading.scene.json");

    float lastWidth = 0;
    int growing = 0;
    int frames = 0;
    // The scan (the level file), then twelve models: 13 units, 4 per frame. The load happens when the Promise settles.
    while (e.world().scene_path() == "scenes/loading.scene.json" && frames < 40) {
        e.step(1);
        ++frames;
        e.world().each<Shape2D>([&](Entity, Shape2D& s) {
            if (s.size.x > lastWidth) ++growing;
            lastWidth = s.size.x;
        });
    }
    CHECK(e.world().scene_path() == "scenes/level.scene.json");
    CHECK(growing >= 3);  // the bar moved on several frames: the loading scene was running and drawing meanwhile
    CHECK(frames <= 8);
    e.shutdown();
}

TEST_CASE("preload: scene.load of a preloaded scene reads no file") {
    TempProject p;
    p.write("factoria.json", std::string(kProject).replace(std::string(kProject).find("loading"), 7, "idle"));
    p.write("scenes/idle.scene.json", R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}}]})");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    e.step(1);
    eval(e, "globalThis.job = scene.preload('scenes/level.scene.json')");
    int frames = 0;
    while (!eval(e, "globalThis.job.done")["value"].get<bool>() && frames < 40) {
        e.step(1);
        ++frames;
    }
    const std::uint64_t before = fs::disk_reads();
    REQUIRE(e.load_scene("scenes/level.scene.json", &err));
    CHECK(fs::disk_reads() == before);
    e.shutdown();
}
