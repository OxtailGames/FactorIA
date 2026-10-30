// Renderer::capture_world and render.captureTexture({ entity | rect, scale }): the world drawn off-screen at a pixel scale. The
// subject is hidden, covered and a long way off the camera, and no frame was ever drawn. Real engine, real renderer (headless GPU).
#include <doctest.h>

#include <cmath>
#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "World Capture Test",
  "id": "com.example.worldcapture",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

// The subject is a red 40 x 20 shape at (5000, 5000), switched off, with a green 10 x 10 child to the right of its middle and a blue
// child that is off. A big blue-grey cover lies over all of it. The camera looks at the origin, 5000 units away.
const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Transform": { "position": [0, 0, 0] }, "Camera": { "orthoSize": 90 } } },
    { "id": "subject", "active": false,
      "components": { "Transform": { "position": [5000, 5000, 0] }, "Shape2D": { "size": [40, 20], "color": "#ff0000", "layer": 1 } },
      "children": [
        { "id": "kid", "components": { "Transform": { "position": [10, 0, 0] }, "Shape2D": { "size": [10, 10], "color": "#00ff00", "layer": 2 } } },
        { "id": "ghost", "active": false, "components": { "Transform": { "position": [-15, 0, 0] }, "Shape2D": { "size": [10, 10], "color": "#0000ff", "layer": 3 } } }
      ] },
    { "id": "cover", "components": { "Transform": { "position": [5000, 5000, 0] }, "Shape2D": { "size": [400, 400], "color": "#808080", "layer": 10 } } }
  ]
})";

struct TempProject {
    stdfs::path dir;
    TempProject() {
        dir = fs::make_temp_dir("fa_world_capture");
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary) << kScene;
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

struct Rig {
    TempProject project;
    Engine e;
    Rig() {
        EngineConfig c;
        c.projectDir = project.dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        std::string err;
        REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
        REQUIRE(e.renderer());
    }
};

struct Px { int r, g, b, a; };
Px at(const Image& img, int x, int y) {
    const std::size_t i = (std::size_t(y) * std::size_t(img.width) + std::size_t(x)) * 4;
    return {img.rgba[i], img.rgba[i + 1], img.rgba[i + 2], img.rgba[i + 3]};
}
bool near_color(Px p, int r, int g, int b, int a = 255) {
    return std::abs(p.r - r) <= 3 && std::abs(p.g - g) <= 3 && std::abs(p.b - b) <= 3 && std::abs(p.a - a) <= 3;
}
std::string show(Px p) { return "(" + std::to_string(p.r) + "," + std::to_string(p.g) + "," + std::to_string(p.b) + "," + std::to_string(p.a) + ")"; }

}  // namespace

TEST_CASE("capture_world of an entity: hidden, covered, off camera, and no frame drawn first") {
    Rig rig;
    REQUIRE(rig.e.frame_index() == 0);
    const RenderStats before = rig.e.renderer()->stats();
    Renderer::WorldCapture spec;
    spec.subject = rig.e.world().find("subject");
    spec.rect = Rect{4980, 4990, 40, 20};
    spec.scale = 2.0f;
    Image img;
    std::string err;
    REQUIRE_MESSAGE(rig.e.renderer()->capture_world(rig.e.world(), spec, img, &err), err);
    REQUIRE(img.width == 80);
    REQUIRE(img.height == 40);
    // The root's own flag (off) is ignored: the red shape is there. The green child is on the right of the middle, the child that is
    // off and the cover (not part of the subject) are not drawn: the left end stays red, nothing is grey.
    const Px red = at(img, 10, 20), green = at(img, 60, 20), mid = at(img, 40, 5);
    CHECK_MESSAGE(near_color(red, 255, 0, 0), show(red));
    CHECK_MESSAGE(near_color(green, 0, 255, 0), show(green));
    CHECK_MESSAGE(near_color(mid, 255, 0, 0), show(mid));
    // Outside the shapes the picture is transparent: a rect bigger than the subject shows it.
    spec.rect = Rect{4970, 4980, 60, 40};
    spec.scale = 1.0f;
    REQUIRE_MESSAGE(rig.e.renderer()->capture_world(rig.e.world(), spec, img, &err), err);
    REQUIRE(img.width == 60);
    CHECK(at(img, 2, 2).a == 0);
    CHECK_MESSAGE(near_color(at(img, 30, 20), 255, 0, 0), show(at(img, 30, 20)));
    // Nothing of the frame changed: no frame was drawn, the stats are the ones before.
    CHECK(rig.e.frame_index() == 0);
    CHECK(rig.e.renderer()->stats().drawCalls == before.drawCalls);
    CHECK(rig.e.renderer()->stats().renderTargets == before.renderTargets);
}

TEST_CASE("capture_world of a rect draws what is active in it, the cover included") {
    Rig rig;
    Renderer::WorldCapture spec;
    spec.rect = Rect{4980, 4990, 40, 20};
    spec.scale = 4.0f;
    Image img;
    std::string err;
    REQUIRE_MESSAGE(rig.e.renderer()->capture_world(rig.e.world(), spec, img, &err), err);
    CHECK(img.width == 160);
    CHECK(img.height == 80);
    const Px p = at(img, 80, 40);
    CHECK_MESSAGE(near_color(p, 128, 128, 128), show(p));  // the cover; the subject is off
    // Switched on, it is under the cover (layer 10): the rect shows the cover over it.
    rig.e.world().set_active(rig.e.world().find("subject"), true);
    REQUIRE_MESSAGE(rig.e.renderer()->capture_world(rig.e.world(), spec, img, &err), err);
    CHECK_MESSAGE(near_color(at(img, 80, 40), 128, 128, 128), show(at(img, 80, 40)));
}

TEST_CASE("capture_world has no 2048 px cap and teaches when the picture is too big") {
    Rig rig;
    Renderer::WorldCapture spec;
    spec.subject = rig.e.world().find("subject");
    spec.rect = Rect{4980, 4990, 40, 20};
    spec.scale = 100.0f;  // 4000 x 2000
    Image img;
    std::string err;
    REQUIRE_MESSAGE(rig.e.renderer()->capture_world(rig.e.world(), spec, img, &err), err);
    CHECK(img.width == 4000);
    CHECK(img.height == 2000);
    const Px red = at(img, 500, 1000), green = at(img, 3000, 1000);
    CHECK_MESSAGE(near_color(red, 255, 0, 0), show(red));
    CHECK_MESSAGE(near_color(green, 0, 255, 0), show(green));
    spec.scale = 150.0f;  // 6000 wide
    CHECK_FALSE(rig.e.renderer()->capture_world(rig.e.world(), spec, img, &err));
    CHECK_MESSAGE(err.find("4096") != std::string::npos, err);
    CHECK_MESSAGE(err.find("smaller scale") != std::string::npos, err);
    spec.scale = 0.0f;
    CHECK_FALSE(rig.e.renderer()->capture_world(rig.e.world(), spec, img, &err));
    CHECK_MESSAGE(err.find("scale") != std::string::npos, err);
    spec.scale = 1.0f;
    spec.rect = Rect{0, 0, 0, 10};
    CHECK_FALSE(rig.e.renderer()->capture_world(rig.e.world(), spec, img, &err));
    CHECK_MESSAGE(err.find("empty") != std::string::npos, err);
}

TEST_CASE("render.captureTexture({ entity | rect, scale }) from a script") {
    Rig rig;
    const stdfs::path dir = rig.project.dir;
    stdfs::create_directories(dir / "tests");
    std::ofstream(dir / "tests/capture.test.js", std::ios::binary) << R"JS(
import { test, expect } from 'factoria:test';
import { render, world } from 'factoria';

test('an entity: hidden, covered and off camera, at an explicit scale', () => {
  const subject = world.find('subject');
  expect(subject.active).toBe(false);
  const tex = render.captureTexture({ entity: subject, scale: 2 });
  expect([tex.width, tex.height]).toEqual([80, 40]);
  expect(tex.placeholder).toBe(false);
  expect(tex.id.startsWith('runtime:')).toBe(true);
  expect(subject.active).toBe(false);                     // the capture does not switch anything on
  tex.destroy();
});

test('a rect, a scale beyond 2048 px and the 4096 px limit', () => {
  const big = render.captureTexture({ rect: [4980, 4990, 40, 20], space: 'world', scale: 100 });
  expect([big.width, big.height]).toEqual([4000, 2000]);
  big.destroy();
  expect(() => render.captureTexture({ rect: [4980, 4990, 40, 20], scale: 150 })).toThrow('4096');
  const frame = render.captureTexture({ width: 64, height: 36 });   // the frame form keeps working
  expect([frame.width, frame.height]).toEqual([64, 36]);
  frame.destroy();
});

test('wrong arguments say what to write', () => {
  const subject = world.find('subject');
  expect(() => render.captureTexture({ entity: subject, rect: [0, 0, 1, 1] })).toThrow('exactly one');
  expect(() => render.captureTexture({ scale: 2 })).toThrow('exactly one');
  expect(() => render.captureTexture({ rect: [0, 0, 0, 5] })).toThrow('positive width');
  expect(() => render.captureTexture({ rect: [0, 0, 5, 5], space: 'screen' })).toThrow('"world"');
  expect(() => render.captureTexture({ rect: [0, 0, 5, 5], scale: -1 })).toThrow('above 0');
  expect(() => render.captureTexture({ rect: [0, 0, 5, 5], width: 10 })).toThrow('drop width');
  const empty = world.spawn({ components: {} });
  expect(() => render.captureTexture({ entity: empty })).toThrow('draw nothing');
  empty.destroy();
});
)JS";
    auto t = rig.e.commands().call("project.test", Json::object());
    REQUIRE_MESSAGE(t.ok, t.error.dump());
    CHECK_MESSAGE(t.result["ok"].get<bool>(), t.result.dump());
}
