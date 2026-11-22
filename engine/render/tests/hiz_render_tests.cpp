// M75.2b on a GPU: the occlusion culling with the depth pyramid (src/renderer_hiz.cpp, src/hiz.h; docs/BIG_WORLDS_LOD.md, "Occlusion"). The
// scene is the one of occlusion_render_tests.cpp, but the wall is a plain mesh: nothing says it is an occluder, the depth of the frame before
// proves the cube behind it hidden. The headless renderer waits for the copy of the depth grid at the start of the next frame, so what a
// frame knows is always the frame before: the tests count frames, never milliseconds. Skipped where the backend has no compute shaders.
#include "test_util.h"

#include <cmath>

#include "render_features.h"
#include "render_internal.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;

namespace {

struct Scene {
    Entity cam, wall, hiddenCube, sideCube, frontCube;
};

Entity add_mesh(World& w, const char* name, Vec3 pos, Vec3 scale, Color color) {
    Entity e = make(w, name, pos);
    w.get<Transform>(e)->scale = scale;
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = "cube";
    m.color = color;
    return e;
}

Scene make_scene(World& w, OcclusionMode mode, bool sunShadows = false) {
    Scene s;
    s.cam = make(w, "cam", {0, 2, 12});
    auto& c = w.add<Camera>(s.cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    w.settings().ambientLight = Color{0.2f, 0.2f, 0.25f, 1};
    w.settings().occlusionMode = mode;
    s.wall = add_mesh(w, "wall", {0, 2, 0}, {10, 6, 1}, Color::hex(0xb0a898));
    s.hiddenCube = add_mesh(w, "hidden", {0, 2, -10}, {2, 2, 2}, Color::hex(0xe03020));
    s.sideCube = add_mesh(w, "side", {16, 2, -10}, {2, 2, 2}, Color::hex(0x2060e0));
    s.frontCube = add_mesh(w, "front", {-2, 0.5f, 7}, {1, 1, 1}, Color::hex(0x20e060));
    Entity sun = make(w, "sun", {0, 5, 0});
    w.get<Transform>(sun)->rotation = {-50, 25, 0};
    auto& l = w.add<Light>(sun);
    l.type = LightType::Directional;
    l.intensity = 1.0f;
    l.castShadows = sunShadows;
    return s;
}

int differing(const Image& a, const Image& b) {
    int n = 0;
    for (int y = 0; y < a.height; ++y)
        for (int x = 0; x < a.width; ++x) {
            const Color p = a.pixel(x, y), q = b.pixel(x, y);
            if (std::fabs(p.r - q.r) > 0.0f || std::fabs(p.g - q.g) > 0.0f || std::fabs(p.b - q.b) > 0.0f) ++n;
        }
    return n;
}

bool has_hiz() {
    return render::feature_supported(render::feature_env_from_sokol(), render::find_feature("occlusionGpu")) &&
           render::AsyncBufferRead::supported();
}

// Draws `frames` frames of `w` and returns the last picture.
Image frames(Gfx& g, World& w, int n) {
    Image img;
    for (int i = 0; i < n; ++i) img = g.draw(w);
    return img;
}

}  // namespace

TEST_CASE("hi-z on a GPU: the default mode is free, and the pyramid is off") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const int before = RendererTestAccess::hiz_reduces(g.renderer);
    World w;
    make_scene(w, OcclusionMode::Cpu);
    frames(g, w, 4);
    CHECK(RendererTestAccess::hiz_reduces(g.renderer) == before);
    CHECK(RendererTestAccess::hiz_cameras(g.renderer) == 0);
    CHECK(g.renderer.stats().meshesOccluded == 0);
    CHECK(g.renderer.stats().occlusionTests == 0);
    const Json r = g.renderer.occlusion_report();
    CHECK(r["gpu"]["mode"].get<std::string>() == "cpu");
    CHECK_FALSE(r["gpu"]["active"].get<bool>());
}

TEST_CASE("hi-z on a GPU: a wall hides the cube behind it one frame later, the picture does not change") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!has_hiz()) {
        MESSAGE("no compute shaders or no asynchronous read-back on this backend: the CPU Occluders cull instead");
        return;
    }
    World plain, gpu;
    make_scene(plain, OcclusionMode::Cpu);
    make_scene(gpu, OcclusionMode::Gpu);
    const Image reference = frames(g, plain, 2);
    // The first frame has no depth picture yet: everything is drawn, and nothing is culled wrongly.
    g.draw(gpu);
    RenderStats st = g.renderer.stats();
    CHECK(st.meshesOccluded == 0);
    CHECK(RendererTestAccess::hiz_reduces(g.renderer) >= 1);
    // The second frame knows the first one's depth: the cube straight behind the wall is left out.
    const Image second = g.draw(gpu);
    st = g.renderer.stats();
    CHECK(st.meshesOccluded == 1);
    CHECK(st.occlusionTests >= 3);
    CHECK(differing(reference, second) == 0);
    CHECK(differing(reference, frames(g, gpu, 3)) == 0);
    CHECK(g.renderer.stats().meshesOccluded == 1);
    const Json r = g.renderer.occlusion_report();
    REQUIRE(r.contains("gpu"));
    CHECK(r["gpu"]["mode"].get<std::string>() == "gpu");
    CHECK(r["gpu"]["active"].get<bool>());
    CHECK(r["gpu"]["hidden"].get<int>() == 1);
    CHECK(r["gpu"]["ageFrames"].get<int>() == 1);
    CHECK(r["gpu"]["width"].get<int>() == 256);
    CHECK(r["gpu"]["height"].get<int>() == 144);  // the 320 x 180 test picture is 16:9
    CHECK(r["gpu"]["coveredCells"].get<int>() > 500);
}

TEST_CASE("hi-z on a GPU: a camera that moves far, or zooms, draws everything in the same frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!has_hiz()) return;
    World w, plain;
    const Scene s = make_scene(w, OcclusionMode::Gpu);
    const Scene p = make_scene(plain, OcclusionMode::Cpu);
    frames(g, w, 4);
    REQUIRE(g.renderer.stats().meshesOccluded == 1);
    // To x = 14 the line of sight to the cube passes beside the wall: it is visible, and the frame must draw it at once.
    w.get<Transform>(s.cam)->position = {14, 2, 12};
    plain.get<Transform>(p.cam)->position = {14, 2, 12};
    const Image moved = g.draw(w);
    CHECK(g.renderer.stats().meshesOccluded == 0);
    CHECK(differing(moved, g.draw(plain)) == 0);
    // A change of the field of view is a cut: nothing is culled in the frame that has it.
    frames(g, w, 3);
    w.get<Transform>(s.cam)->position = {0, 2, 12};
    frames(g, w, 3);
    CHECK(g.renderer.stats().meshesOccluded == 1);
    w.get<Camera>(s.cam)->fov = 45;
    g.draw(w);
    CHECK(g.renderer.stats().meshesOccluded == 0);
}

TEST_CASE("hi-z on a GPU: the camera's tags decide what hides what, and a removed wall shows the cube again") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!has_hiz()) return;
    World w;
    const Scene s = make_scene(w, OcclusionMode::Gpu);
    w.info(s.wall).tags = {"roof"};
    for (Entity e : {s.hiddenCube, s.sideCube, s.frontCube}) w.info(e).tags = {"thing"};
    Camera& cam = *w.get<Camera>(s.cam);
    cam.showTags = Json::array({"roof", "thing"});
    frames(g, w, 4);
    CHECK(g.renderer.stats().meshesOccluded == 1);
    // The camera stops drawing the wall: it is not in the depth picture of the next frames, so after the frame of latency the cube is drawn.
    cam.showTags = Json::array({"thing"});
    const int drawn = (g.draw(w), g.renderer.stats().meshes);
    frames(g, w, 3);
    CHECK(g.renderer.stats().meshesOccluded == 0);
    CHECK(g.renderer.stats().meshes >= drawn);
    // The wall comes back and hides it again.
    cam.showTags = Json::array({"roof", "thing"});
    frames(g, w, 4);
    CHECK(g.renderer.stats().meshesOccluded == 1);
    // Deleting the wall (the destroyed occluder hides nothing any more) shows the cube within a few frames.
    w.destroy(s.wall);
    frames(g, w, 4);
    CHECK(g.renderer.stats().meshesOccluded == 0);
}

TEST_CASE("hi-z on a GPU: a culled mesh still casts its shadow, and the Occluders do not cull a camera that uses the pyramid") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!has_hiz()) return;
    World plain, gpu;
    make_scene(plain, OcclusionMode::Cpu, true);
    const Scene s = make_scene(gpu, OcclusionMode::Gpu, true);
    const Image reference = frames(g, plain, 2);
    const int casters = g.renderer.stats().shadowCasters;
    const Image culled = frames(g, gpu, 4);
    const RenderStats st = g.renderer.stats();
    CHECK(st.meshesOccluded >= 1);
    CHECK(st.shadowCasters == casters);
    CHECK(casters > 0);
    CHECK(differing(reference, culled) == 0);
    // An Occluder on the wall is not rasterised for this camera (it would count in `occluders`): the pyramid is the one culling it.
    gpu.add<Occluder>(s.wall).size = {1, 1, 1};
    g.draw(gpu);
    CHECK(g.renderer.stats().occluders == 0);
    CHECK(g.renderer.stats().meshesOccluded == 1);
}

TEST_CASE("hi-z on a GPU: auto uses the pyramid where the GPU can, and the debug view and the saved picture work") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    make_scene(w, OcclusionMode::Auto);
    frames(g, w, 4);
    const Json r = g.renderer.occlusion_report("assets/hiz_report.png", 2);
    REQUIRE(r.contains("gpu"));
    CHECK(r["gpu"]["mode"].get<std::string>() == "auto");
    if (!has_hiz()) {
        CHECK_FALSE(r["gpu"]["supported"].get<bool>());
        CHECK(g.renderer.stats().meshesOccluded == 0);
        return;
    }
    CHECK(r["gpu"]["supported"].get<bool>());
    CHECK(g.renderer.stats().meshesOccluded == 1);
    REQUIRE(r["gpu"].contains("file"));
    CHECK(std::filesystem::exists(g.projectDir / "assets" / "hiz_report.png"));
    CHECK(r["gpu"]["level"].get<int>() == 2);
    const Image before = g.draw(w);
    g.renderer.set_debug_view(DebugView::Occlusion);
    g.draw(w);
    const Image after = g.draw(w);
    CHECK(differing(before, after) > 100);
    g.renderer.set_debug_view(DebugView::None);
    frames(g, w, 2);
    CHECK(differing(before, g.draw(w)) == 0);
}
