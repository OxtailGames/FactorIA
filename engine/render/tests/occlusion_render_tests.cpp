// M75.2 on a GPU: the occlusion culling in the renderer (src/renderer_occlusion.cpp; docs/BIG_WORLDS.md, "Occlusion"). A wall Occluder hides
// the meshes behind it from the main pass, the picture is the one the scene draws without the culling, the shadow passes are not culled, a
// scene with no enabled Occluder takes the old path (the counters stay 0) and render.occlusion reports what happened.
#include "test_util.h"

#include <cmath>
#include <filesystem>

#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;

namespace {

struct Scene {
    Entity wall, hiddenCube, sideCube, frontCube, sun;
};

Entity add_mesh(World& w, const char* name, const char* mesh, Vec3 pos, Vec3 scale, Color color) {
    Entity e = make(w, name, pos);
    w.get<Transform>(e)->scale = scale;
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = mesh;
    m.color = color;
    return e;
}

// A camera at z = 12 looking at -Z; a wall (10 x 6 x 1, an Occluder box of 1 m scaled by the Transform) at the origin, a cube behind it
// that it hides, a cube far to the side that it does not, and a cube in front of it. `occluder` false leaves the Occluder component off
// the wall (the same meshes otherwise).
Scene make_scene(World& w, bool occluder, bool sunShadows = false) {
    Scene s;
    Entity cam = make(w, "cam", {0, 2, 12});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    w.settings().ambientLight = Color{0.2f, 0.2f, 0.25f, 1};
    s.wall = add_mesh(w, "wall", "cube", {0, 2, 0}, {10, 6, 1}, Color::hex(0xb0a898));
    s.hiddenCube = add_mesh(w, "hidden", "cube", {0, 2, -10}, {2, 2, 2}, Color::hex(0xe03020));
    s.sideCube = add_mesh(w, "side", "cube", {16, 2, -10}, {2, 2, 2}, Color::hex(0x2060e0));
    s.frontCube = add_mesh(w, "front", "cube", {-2, 0.5f, 7}, {1, 1, 1}, Color::hex(0x20e060));
    s.sun = make(w, "sun", {0, 5, 0});
    w.get<Transform>(s.sun)->rotation = {-50, 25, 0};
    auto& l = w.add<Light>(s.sun);
    l.type = LightType::Directional;
    l.intensity = 1.0f;
    l.castShadows = sunShadows;
    if (occluder) w.add<Occluder>(s.wall).size = {1, 1, 1};
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

}  // namespace

TEST_CASE("occlusion on a GPU: a wall hides the cube behind it, the picture does not change, the counters say so") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World with, without;
    make_scene(with, true);
    make_scene(without, false);
    const Image plain = g.render(without);
    const RenderStats off = g.renderer.stats();
    CHECK(off.occluders == 0);
    CHECK(off.occlusionTests == 0);
    CHECK(off.meshesOccluded == 0);
    const Image culled = g.render(with);
    const RenderStats on = g.renderer.stats();
    CHECK(on.occluders == 1);
    CHECK(on.occlusionTests == 3);  // the cubes; the wall is the occluder and is not tested against itself
    CHECK(on.meshesOccluded == 1);  // the cube straight behind the wall
    // The cube it hides was not drawn, and the picture is the same one, pixel for pixel.
    CHECK(on.drawCalls < off.drawCalls);
    CHECK(differing(plain, culled) == 0);
    // Drawn twice: the counters are of the frame, not summed.
    g.render(with);
    CHECK(g.renderer.stats().meshesOccluded == 1);
    CHECK(g.renderer.stats().occluders == 1);
}

TEST_CASE(
    "occlusion on a GPU: Occluder.enabled false, a removed component and a missing mesh take the path without it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    const Scene s = make_scene(w, true);
    g.render(w);
    CHECK(g.renderer.stats().meshesOccluded == 1);
    w.get<Occluder>(s.wall)->enabled = false;
    g.render(w);
    CHECK(g.renderer.stats().occluders == 0);
    CHECK(g.renderer.stats().occlusionTests == 0);
    CHECK(g.renderer.stats().meshesOccluded == 0);
    w.get<Occluder>(s.wall)->enabled = true;
    g.render(w);
    CHECK(g.renderer.stats().meshesOccluded == 1);
    // A mesh occluder whose mesh cannot be read hides nothing (a warning, once) and the frame is drawn.
    auto& o = *w.get<Occluder>(s.wall);
    o.shape = OccluderShape::Mesh;
    o.mesh = "models/not_there.glb";
    g.render(w);
    CHECK(g.renderer.stats().occluders == 0);
    CHECK(g.renderer.stats().meshesOccluded == 0);
    // A mesh occluder of the entity's own MeshRenderer ("cube", 12 triangles, scaled by the Transform): hides the same cube.
    o.mesh.clear();
    g.render(w);
    CHECK(g.renderer.stats().occluders == 1);
    CHECK(g.renderer.stats().meshesOccluded == 1);
    w.remove<Occluder>(s.wall);
    g.render(w);
    CHECK(g.renderer.stats().occluders == 0);
    CHECK(g.renderer.stats().meshesOccluded == 0);
}

TEST_CASE("occlusion on a GPU: a culled mesh still casts its shadow") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World with, without;
    make_scene(with, true, true);
    make_scene(without, false, true);
    const Image plain = g.render(without);
    const int casters = g.renderer.stats().shadowCasters;
    const Image culled = g.render(with);
    const RenderStats s = g.renderer.stats();
    CHECK(s.meshesOccluded >= 1);
    CHECK(s.shadowCasters == casters);
    CHECK(casters > 0);
    CHECK(differing(plain, culled) == 0);
}

TEST_CASE("occlusion on a GPU: render.occlusion's report and the debug view") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World none, w;
    make_scene(none, false);
    g.render(none);
    Json r = g.renderer.occlusion_report();
    CHECK(r["supported"].get<bool>());
    CHECK_FALSE(r["active"].get<bool>());
    CHECK(r.contains("message"));
    CHECK(r["limits"]["width"].get<int>() == 256);

    make_scene(w, true);
    g.render(w);
    r = g.renderer.occlusion_report();
    CHECK(r["active"].get<bool>());
    CHECK(r["occluders"].get<int>() == 1);
    CHECK(r["tests"].get<int>() == 3);
    CHECK(r["hidden"].get<int>() == 1);
    CHECK(r["width"].get<int>() == 256);
    CHECK(r["height"].get<int>() == 144);  // the 320 x 180 test picture is 16:9
    CHECK(r["triangles"].get<int>() == 12);
    CHECK(r["coveredCells"].get<int>() > 500);
    CHECK_FALSE(r.contains("file"));

    r = g.renderer.occlusion_report("assets/occlusion_report.png");
    REQUIRE(r.contains("file"));
    CHECK(std::filesystem::exists(g.projectDir / "assets" / "occlusion_report.png"));

    // The debug view draws the boxes (green: the occluder, red: the culled cube) from the next frame and changes the picture.
    const Image before = g.draw(w);
    g.renderer.set_debug_view(DebugView::Occlusion);
    g.draw(w);  // the boxes are made by this frame and drawn by the next
    const Image after = g.draw(w);
    CHECK(differing(before, after) > 100);
    CHECK(g.renderer.occlusion_report()["debugView"].get<bool>());
    g.renderer.set_debug_view(DebugView::None);
    g.draw(w);
    const Image back = g.draw(w);
    CHECK(differing(before, back) == 0);
}

TEST_CASE(
    "occlusion on a GPU: moving the camera in front of the cube shows it again, and a sprite scene has no occlusion") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    const Scene s = make_scene(w, true);
    g.render(w);
    CHECK(g.renderer.stats().meshesOccluded == 1);
    // Beside the wall the cube behind it is in view.
    Transform* camT = nullptr;
    w.each<Camera>([&](Entity e, Camera&) { camT = w.get<Transform>(e); });
    REQUIRE(camT);
    camT->position = {0, 2, -30};
    camT->rotation = {0, 0, 0};  // looks to -Z, away from the wall
    g.render(w);
    CHECK(g.renderer.stats().meshesOccluded == 0);
    // The camera inside the wall's box gets no occlusion from it.
    camT->position = {0, 2, 0};
    g.render(w);
    CHECK(g.renderer.stats().meshesOccluded == 0);
    (void)s;
}
