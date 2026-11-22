// M75-P1a on a GPU: the level of detail each camera picks (by distance or screen size, MeshRenderer.lods and LodGroup), the dithered
// cross-fade between two levels (counters and a readback of which pixels each level draws), the batches that split per level and the
// shadow casters. The pure selection and the fade state are in engine/scene/tests/lod_tests.cpp; LodFades (no GPU) is tested here too.
#include "test_util.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdlib>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "fa/core/log.h"
#include "renderer_lod.h"

using namespace fa;
using namespace fa::test;

namespace {

Entity add_camera(World& w, Vec3 pos, Rect viewport = {0, 0, 1, 1}, int depth = 0) {
    Entity cam = make(w, "cam", pos);
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    c.viewport = viewport;
    c.depth = depth;
    c.clear = depth == 0;
    c.clearColor = Color::hex(0x202830);
    return cam;
}

// The warnings and errors logged while the object lives.
struct ProblemLog {
    struct Lines {
        std::mutex mu;
        std::vector<std::string> lines;
    };
    std::shared_ptr<Lines> shared = std::make_shared<Lines>();
    int id;
    ProblemLog()
        : id(add_log_sink([l = shared](const LogEntry& e) {
              if (e.level < LogLevel::Warn) return;
              std::lock_guard<std::mutex> lk(l->mu);
              l->lines.push_back(e.message);
          })) {}
    ~ProblemLog() { remove_log_sink(id); }
    ProblemLog(const ProblemLog&) = delete;
    ProblemLog& operator=(const ProblemLog&) = delete;
    int count(const std::string& needle) const {
        std::lock_guard<std::mutex> lk(shared->mu);
        return int(std::count_if(shared->lines.begin(), shared->lines.end(),
                                 [&](const std::string& x) { return x.find(needle) != std::string::npos; }));
    }
};

// A cube whose far level is a sphere beyond `at` metres (or below `screenSize` of the screen).
Entity add_lod_cube(World& w, Vec3 pos, float crossFade = 0.0f, float at = 30.0f, Vec3 scale = {1, 1, 1}) {
    Entity e = make(w, "lod", pos);
    w.get<Transform>(e)->scale = scale;
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = "cube";
    m.lods = Json::array({Json{{"mesh", "sphere"}, {"distance", at}}});
    m.lodCrossFade = crossFade;
    m.unlit = true;
    return e;
}

int triangles_of(const char* mesh) {
    Gfx& g = gfx();
    World w;
    add_camera(w, {0, 0, 10});
    Entity e = make(w, "m", {0, 0, 0});
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = mesh;
    g.render(w);
    return g.renderer.stats().triangles;
}

// Pixels of the image that differ from the same view of an empty scene (the sky is not one colour), and how many of them are red / green (the two cubes of the group test).
struct Coverage {
    int solid = 0, red = 0, green = 0;
};
Coverage coverage(const Image& img, const Image& empty) {
    Coverage c;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            const Color p = img.pixel(x, y), bg = empty.pixel(x, y);
            if (std::fabs(p.r - bg.r) < 0.02f && std::fabs(p.g - bg.g) < 0.02f && std::fabs(p.b - bg.b) < 0.02f)
                continue;
            ++c.solid;
            if (p.r > p.g + 0.3f && p.r > p.b + 0.3f) ++c.red;
            if (p.g > p.r + 0.3f && p.g > p.b + 0.3f) ++c.green;
        }
    return c;
}
}  // namespace

TEST_CASE("lod render: a MeshRenderer draws the level its distance picks") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const int cube = triangles_of("cube"), sphere = triangles_of("sphere");
    REQUIRE(cube != sphere);
    World w;
    add_camera(w, {0, 0, 10});
    Entity e = add_lod_cube(w, {0, 0, 0});  // 10 m: the cube
    g.render(w);
    CHECK(g.renderer.stats().triangles == cube);
    CHECK(g.renderer.stats().lodCrossFades == 0);
    w.get<Transform>(e)->position = {0, 0, -25};  // 35 m: the sphere
    g.render(w);
    CHECK(g.renderer.stats().triangles == sphere);
    w.get<Transform>(e)->position = {0, 0, -20};  // 30 m: the threshold itself belongs to the far level
    g.render(w);
    CHECK(g.renderer.stats().triangles == sphere);
    g.renderer.clear_asset_cache();
}

TEST_CASE("lod render: lodMode screenSize picks by the size on the screen, so a bigger object keeps its detail further "
          "away") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const int cube = triangles_of("cube"), sphere = triangles_of("sphere");
    World w;
    add_camera(w, {0, 0, 10});
    // The box of the cube is 1.73 m across when it is 1 m big; the view is 11.5 m tall at 10 m: 0.15 of the screen.
    Entity small = add_lod_cube(w, {0, 0, 0});
    w.get<MeshRenderer>(small)->lodMode = LodMode::ScreenSize;
    w.get<MeshRenderer>(small)->lods = Json::array({Json{{"mesh", "sphere"}, {"screenSize", 0.3}}});
    g.render(w);
    CHECK(g.renderer.stats().triangles == sphere);  // 0.15 < 0.3
    w.get<Transform>(small)->scale = {4, 4, 4};     // 0.6 of the screen: back to the cube, at the same distance
    g.render(w);
    CHECK(g.renderer.stats().triangles == cube);
    w.get<Transform>(small)->position = {0, 0, -30};  // the same cube 40 m away: 0.15 again
    g.render(w);
    CHECK(g.renderer.stats().triangles == sphere);
    g.renderer.clear_asset_cache();
}

TEST_CASE("lod render: a LodGroup draws the child its subtree's sphere picks and no other") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const int cube = triangles_of("cube"), sphere = triangles_of("sphere");
    World w;
    add_camera(w, {0, 0, 10});
    Entity group = make(w, "group", {0, 0, 0});
    auto& lg = w.add<LodGroup>(group);
    lg.thresholds.push_back(30.0f);
    Entity closeKid = make(w, "close", {0, 0, 0});  // not `near` and `far`: windows.h defines both as empty macros
    Entity distantKid = make(w, "distant", {0, 0, 0});
    for (Entity e : {closeKid, distantKid}) {
        w.set_parent(e, group);
        w.add<MeshRenderer>(e).mesh = e == closeKid ? "cube" : "sphere";
    }
    g.render(w);
    CHECK(g.renderer.stats().meshes == 1);
    CHECK(g.renderer.stats().triangles == cube);
    w.get<Transform>(group)->position = {0, 0, -30};
    g.render(w);
    CHECK(g.renderer.stats().meshes == 1);
    CHECK(g.renderer.stats().triangles == sphere);
    // A child that is itself a group's mesh sits in the parent's chain only: an entity outside the group is always drawn.
    Entity loose = make(w, "loose", {3, 0, 0});
    w.add<MeshRenderer>(loose).mesh = "cube";
    g.render(w);
    CHECK(g.renderer.stats().meshes == 2);
    g.renderer.clear_asset_cache();
}

TEST_CASE("lod render: a cross-fade draws both levels for crossFade seconds, then only the new one") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const int cube = triangles_of("cube"), sphere = triangles_of("sphere");
    World w;
    add_camera(w, {0, 0, 10});
    Entity e = add_lod_cube(w, {0, 0, 0}, 0.5f);
    const float dt = 0.125f;  // a power of two: the fade's steps add up exactly
    g.render(w, dt);
    CHECK(g.renderer.stats().lodCrossFades == 0);
    w.get<Transform>(e)->position = {0, 0, -30};
    int fading = 0;
    for (int i = 0; i < 10; ++i) {
        g.render(w, dt);
        const RenderStats& st = g.renderer.stats();
        if (st.lodCrossFades == 0) break;
        ++fading;
        CHECK(st.lodCrossFades == 2);  // each level of the entity counts
        CHECK(st.meshes == 2);
        CHECK(st.triangles == cube + sphere);
    }
    CHECK(fading == 3);  // t = 0.25, 0.5, 0.75; the fourth frame reaches 1
    CHECK(g.renderer.stats().meshes == 1);
    CHECK(g.renderer.stats().triangles == sphere);
    // Nothing keeps fading afterwards.
    g.render(w, dt);
    CHECK(g.renderer.stats().lodCrossFades == 0);
    g.renderer.clear_asset_cache();
}

TEST_CASE("lod render: going back during a fade does not restart it, and a hard switch (crossFade 0) never fades") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    triangles_of(
        "cube");  // both levels are loaded before the test starts: a level still loading is not drawn, so it cannot fade
    triangles_of("sphere");
    World w;
    add_camera(w, {0, 0, 10});
    Entity e = add_lod_cube(w, {0, 0, 0}, 0.5f);
    const float dt = 0.125f;
    g.render(w, dt);
    w.get<Transform>(e)->position = {0, 0, -30};
    g.render(w, dt);  // t = 0.25
    CHECK(g.renderer.stats().lodCrossFades == 2);
    w.get<Transform>(e)->position = {0, 0, 0};
    g.render(w, dt);  // back to the cube: it fades in again from where it stood (0.75), and this frame adds 0.25
    CHECK(g.renderer.stats().lodCrossFades == 0);
    w.get<MeshRenderer>(e)->lodCrossFade = 0.0f;
    w.get<Transform>(e)->position = {0, 0, -30};
    g.render(w, dt);
    CHECK(g.renderer.stats().lodCrossFades == 0);
    CHECK(g.renderer.stats().meshes == 1);
    g.renderer.clear_asset_cache();
}

TEST_CASE("lod render: the two levels of a cross-fade cover every pixel once (the dither is complementary)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    add_camera(w, {0, 0, 10});
    Entity group = make(w, "group", {0, 0, 0});
    auto& lg = w.add<LodGroup>(group);
    lg.thresholds.push_back(30.0f);
    lg.crossFade = 0.5f;
    Entity red = make(w, "red", {0, 0, 0}), green = make(w, "green", {0, 0, 0});
    for (Entity e : {red, green}) {
        w.set_parent(e, group);
        w.get<Transform>(e)->scale = {3, 3, 3};
        auto& m = w.add<MeshRenderer>(e);
        m.mesh = "cube";
        m.unlit = true;
        m.color = e == red ? Color{1, 0, 0, 1} : Color{0, 1, 0, 1};
    }
    const float dt = 0.125f;
    World none;
    add_camera(none, {0, 0, 10});
    const Image empty = g.render(none);
    const Coverage settled = coverage(g.render(w, dt), empty);
    REQUIRE(settled.red > 400);
    CHECK(settled.green == 0);
    // Where the group is 36 m away the green cube takes over (a smaller picture: compare the fade with the same place).
    w.get<Transform>(group)->position = {0, 0, -26};
    Coverage fade;
    g.render(w, dt);                     // t = 0.25
    const Image half = g.render(w, dt);  // t = 0.5
    CHECK(g.renderer.stats().lodCrossFades == 2);
    fade = coverage(half, empty);
    CHECK(fade.red > 0);
    CHECK(fade.green > 0);
    // No pixel is drawn twice or left empty: every pixel of the picture is one cube's colour. With MSAA the pixels on the silhouette
    // mix a colour with the background or the other cube, so a tenth of them may be neither (without MSAA none is).
    CHECK((fade.solid - fade.red - fade.green) * 10 <= fade.solid);
    const float share = float(fade.green) / float(fade.solid);
    CHECK(share > 0.35f);
    CHECK(share < 0.65f);
    g.render(w, dt);  // t = 0.75
    g.render(w, dt);  // done
    const Coverage after = coverage(g.render(w, dt), empty);
    CHECK(after.red == 0);
    CHECK(std::abs(after.solid - fade.solid) * 10 <= fade.solid);  // the silhouette is the one the fade covered
    CHECK((after.solid - after.green) * 10 <= after.solid);
    g.renderer.clear_asset_cache();
}

TEST_CASE("lod render: instanced draws split per level, and only a fading entity leaves its batch") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    add_camera(w, {0, 0, 10});
    Entity moving = kNullEntity;
    for (int i = 0; i < 4; ++i) {
        Entity e = add_lod_cube(w, {float(i) - 1.5f, 0, 0}, 0.5f);
        if (i == 0) moving = e;
    }
    const float dt = 0.125f;
    g.render(w, dt);
    CHECK(g.renderer.stats().meshBatches == 1);  // four cubes, one draw
    w.get<Transform>(moving)->position = {-1.5f, 0, -30};
    g.render(w, dt);  // t = 0.25: the three cubes, the new level of the one that moved, and its old level
    CHECK(g.renderer.stats().meshes == 5);
    CHECK(g.renderer.stats().meshBatches == 3);
    for (int i = 0; i < 4; ++i) g.render(w, dt);
    CHECK(g.renderer.stats().meshes == 4);
    CHECK(g.renderer.stats().meshBatches == 2);  // the cubes and the sphere: a batch per level
    g.renderer.clear_asset_cache();
}

TEST_CASE("lod render: a split-screen camera picks the level of its own distance") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const int cube = triangles_of("cube"), sphere = triangles_of("sphere");
    World w;
    add_camera(w, {0, 0, 10}, Rect{0, 0, 0.5f, 1}, 0);
    add_camera(w, {0, 0, 60}, Rect{0.5f, 0, 0.5f, 1}, 1);
    add_lod_cube(w, {0, 0, 0});
    g.render(w);
    CHECK(g.renderer.stats().triangles == cube + sphere);  // 10 m from the left camera, 60 m from the right one
    g.renderer.clear_asset_cache();
}

TEST_CASE("lod render: a shadow caster fading casts the new level only") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("cascadedShadows")) {
        MESSAGE("cascadedShadows is not supported on this GPU: the test did not run");
        return;
    }
    World w;
    add_camera(w, {0, 2, 10});
    Entity sun = make(w, "sun", {0, 5, 0});
    w.get<Transform>(sun)->rotation = {-40, -35, 0};
    auto& l = w.add<Light>(sun);
    l.type = LightType::Directional;
    l.castShadows = true;
    Entity e = add_lod_cube(w, {0, 0, 0}, 0.5f);
    w.get<MeshRenderer>(e)->unlit = false;
    const float dt = 0.125f;
    g.render(w, dt);
    CHECK(g.renderer.stats().shadowCasters == 1);
    w.get<Transform>(e)->position = {0, 0, -30};
    g.render(w, dt);
    CHECK(g.renderer.stats().lodCrossFades == 2);
    CHECK(g.renderer.stats().shadowCasters == 1);  // not 2: the level fading out leaves the shadow map at once
    g.renderer.clear_asset_cache();
}

TEST_CASE("lod render: a mesh with no lods and a scene with no LodGroup draw as before") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    add_camera(w, {0, 0, 10});
    for (int i = 0; i < 5; ++i) {
        Entity e = make(w, "m", {float(i) - 2.0f, 0, 0});
        w.add<MeshRenderer>(e).mesh = "cube";
    }
    g.render(w, 0.1f);
    CHECK(g.renderer.stats().meshes == 5);
    CHECK(g.renderer.stats().meshBatches == 1);
    CHECK(g.renderer.stats().lodCrossFades == 0);
    g.renderer.clear_asset_cache();
}

TEST_CASE("hlod: past hlodThreshold a LodGroup draws its proxy with its own matrix and no child") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const int cube = triangles_of("cube"), sphere = triangles_of("sphere");
    REQUIRE(cube != sphere);
    World w;
    add_camera(w, {0, 0, 10});
    Entity group = make(w, "group", {0, 0, 0});
    auto& lg = w.add<LodGroup>(group);
    lg.hlodProxy = "sphere";
    lg.hlodThreshold = 30.0f;
    for (int i = 0; i < 3; ++i) {
        Entity kid = make(w, "kid", {float(i) - 1.0f, 0, 0});
        w.set_parent(kid, group);
        w.add<MeshRenderer>(kid).mesh = "cube";
    }
    // a group has one child per level, so three children without thresholds draw the first one; the proxy replaces it
    g.render(w);
    CHECK(g.renderer.stats().hlodProxies == 0);
    CHECK(g.renderer.stats().meshes == 1);
    CHECK(g.renderer.stats().triangles == cube);
    w.get<Transform>(group)->position = {0, 0, -30};  // 40 m away
    g.render(w);
    CHECK(g.renderer.stats().hlodProxies == 1);
    CHECK(g.renderer.stats().meshes == 1);
    CHECK(g.renderer.stats().triangles == sphere);
    // nearer again: the children come back and the counter goes to 0
    w.get<Transform>(group)->position = {0, 0, 0};
    g.render(w);
    CHECK(g.renderer.stats().hlodProxies == 0);
    CHECK(g.renderer.stats().triangles == cube);
    g.renderer.clear_asset_cache();
}

TEST_CASE(
    "hlod: a streamed cell's proxy entity (EntityInfo::streamedProxy) counts in renderStats.hlodProxies and draws") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const int cube = triangles_of("cube");
    World w;
    add_camera(w, {0, 0, 10});
    Entity plain = make(w, "plain", {-2, 0, 0});
    w.add<MeshRenderer>(plain).mesh = "cube";
    g.render(w);
    CHECK(g.renderer.stats().hlodProxies == 0);
    CHECK(g.renderer.stats().meshes == 1);
    Entity proxy = make(w, "hlod 0,0", {2, 0, 0});
    w.add<MeshRenderer>(proxy).mesh = "cube";
    w.info(proxy).streamedProxy = true;  // what the world streamer sets on the entity of a cell's HLOD proxy
    g.render(w);
    CHECK(g.renderer.stats().hlodProxies == 1);  // the plain cube is not one
    CHECK(g.renderer.stats().meshes == 2);
    CHECK(g.renderer.stats().triangles == 2 * cube);
    w.destroy(proxy);
    g.render(w);
    CHECK(g.renderer.stats().hlodProxies == 0);
    g.renderer.clear_asset_cache();
}

TEST_CASE("hlod: the proxy casts the shadow and the children it replaces do not") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("cascadedShadows")) {
        MESSAGE("cascadedShadows is not supported on this GPU: the test did not run");
        return;
    }
    World w;
    add_camera(w, {0, 2, 10});
    Entity sun = make(w, "sun", {0, 5, 0});
    w.get<Transform>(sun)->rotation = {-40, -35, 0};
    auto& l = w.add<Light>(sun);
    l.type = LightType::Directional;
    l.castShadows = true;
    Entity group = make(w, "group", {0, 0, 0});
    auto& lg = w.add<LodGroup>(group);
    lg.hlodProxy = "sphere";
    lg.hlodThreshold = 30.0f;
    for (int i = 0; i < 3; ++i) {
        Entity kid = make(w, "kid", {float(i) - 1.0f, 0, 0});
        w.set_parent(kid, group);
        w.add<MeshRenderer>(kid).mesh = "cube";
    }
    g.render(w);
    CHECK(g.renderer.stats().hlodProxies == 0);
    CHECK(g.renderer.stats().shadowCasters == 1);  // the first child
    w.get<Transform>(group)->position = {0, 0, -30};
    g.render(w);
    CHECK(g.renderer.stats().hlodProxies == 1);
    CHECK(g.renderer.stats().shadowCasters == 1);  // the proxy, and no child
    g.renderer.clear_asset_cache();
}

TEST_CASE("hlod: crossFade fades the children out and the proxy in, like a LOD switch") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const int cube = triangles_of("cube"), sphere = triangles_of("sphere");
    World w;
    add_camera(w, {0, 0, 10});
    Entity group = make(w, "group", {0, 0, 0});
    auto& lg = w.add<LodGroup>(group);
    lg.hlodProxy = "sphere";
    lg.hlodThreshold = 30.0f;
    lg.crossFade = 0.5f;
    Entity kid = make(w, "kid", {0, 0, 0});
    w.set_parent(kid, group);
    w.add<MeshRenderer>(kid).mesh = "cube";
    const float dt = 0.125f;
    g.render(w, dt);
    CHECK(g.renderer.stats().lodCrossFades == 0);
    w.get<Transform>(group)->position = {0, 0, -30};
    int fading = 0;
    for (int i = 0; i < 10; ++i) {
        g.render(w, dt);
        const RenderStats& st = g.renderer.stats();
        if (st.lodCrossFades == 0) break;
        ++fading;
        CHECK(st.lodCrossFades == 2);
        CHECK(st.meshes == 2);
        CHECK(st.triangles == cube + sphere);
        CHECK(st.hlodProxies == 1);
    }
    CHECK(fading == 3);
    CHECK(g.renderer.stats().meshes == 1);
    CHECK(g.renderer.stats().triangles == sphere);
    CHECK(g.renderer.stats().hlodProxies == 1);
    g.renderer.clear_asset_cache();
}

TEST_CASE("hlod: an unreadable proxy draws the children as before, a group without a proxy costs nothing") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const int cube = triangles_of("cube");
    ProblemLog log;
    World w;
    add_camera(w, {0, 0, 10});
    Entity group = make(w, "group", {0, 0, -30});
    auto& lg = w.add<LodGroup>(group);
    lg.hlodProxy = "missing/never_baked.glb";
    lg.hlodThreshold = 30.0f;
    Entity kid = make(w, "kid", {0, 0, -30});
    w.set_parent(kid, group);
    w.add<MeshRenderer>(kid).mesh = "cube";
    g.render(w);
    g.render(w);  // the warning is logged once, and the group keeps drawing its child
    g.render(w);
    CHECK(log.count("never_baked.glb") == 1);  // one line, not one from Assets::mesh and another from the group
    CHECK(log.count("world.bake_hlod") == 1);  // and it says how to fix it
    CHECK(g.renderer.stats().hlodProxies == 0);
    CHECK(g.renderer.stats().meshes == 1);
    CHECK(g.renderer.stats().triangles == cube);
    // the same scene with no proxy anywhere: the same counts and draws
    lg.hlodProxy.clear();
    g.render(w);
    CHECK(g.renderer.stats().hlodProxies == 0);
    CHECK(g.renderer.stats().meshes == 1);
    CHECK(g.renderer.stats().triangles == cube);
    g.renderer.clear_asset_cache();
}

TEST_CASE("hlod: with no hlodProxy anywhere the draws and counts are those of a group without the field") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const auto run = [&](bool setThresholdOnly) {
        World w;
        add_camera(w, {0, 0, 10});
        Entity group = make(w, "group", {0, 0, -40});
        auto& lg = w.add<LodGroup>(group);
        lg.thresholds.push_back(30.0f);
        if (setThresholdOnly) lg.hlodThreshold = 20.0f;  // a threshold without a proxy does nothing
        Entity a = make(w, "a", {0, 0, -40}), b = make(w, "b", {0, 0, -40});
        w.set_parent(a, group);
        w.set_parent(b, group);
        w.add<MeshRenderer>(a).mesh = "cube";
        w.add<MeshRenderer>(b).mesh = "sphere";
        g.render(w);
        const RenderStats& st = g.renderer.stats();
        return std::array<int, 5>{int(st.meshes), int(st.triangles), int(st.drawCalls), int(st.shadowCasters),
                                  int(st.hlodProxies)};
    };
    const auto plain = run(false);
    const auto withThreshold = run(true);
    CHECK(plain == withThreshold);
    CHECK(plain[4] == 0);
    g.renderer.clear_asset_cache();
}

// ---- LodFades: no GPU ----

TEST_CASE("lod fades: a new entity starts settled, a change fades per camera, and what nobody asked about is dropped") {
    render::LodFades f;
    f.begin_frame();
    render::LodPick p = f.step(1, 7, render::LodKind::Mesh, 2, 1.0f, 0.25f);
    CHECK(p.level == 2);  // first seen: no fade from level 0
    CHECK_FALSE(p.fading());
    f.end_frame();
    f.begin_frame();
    p = f.step(1, 7, render::LodKind::Mesh, 1, 1.0f, 0.25f);
    CHECK(p.level == 1);
    CHECK(p.from == 2);
    CHECK(p.amount == doctest::Approx(0.25f));
    const render::LodPick other = f.step(2, 7, render::LodKind::Mesh, 1, 1.0f, 0.25f);  // another camera: its own state
    CHECK_FALSE(other.fading());
    const render::LodPick group =
        f.step(1, 7, render::LodKind::Group, 3, 1.0f, 0.25f);  // another kind of the same entity
    CHECK_FALSE(group.fading());
    CHECK(f.size() == 3);
    f.end_frame();
    f.begin_frame();
    f.step(1, 7, render::LodKind::Mesh, 1, 1.0f, 0.25f);
    f.end_frame();
    CHECK(f.size() == 1);  // the other two were not asked about this frame
}

TEST_CASE("lod fades: the first main camera's picks are what a capture follows") {
    render::LodFades f;
    f.begin_frame();
    CHECK_FALSE(f.main_set());
    f.remember(5, render::LodKind::Mesh, render::LodPick{3, -1, 0.0f});
    f.remember(5, render::LodKind::Mesh, render::LodPick{1, -1, 0.0f});  // a second camera does not overwrite
    f.set_main();
    REQUIRE(f.main_pick(5, render::LodKind::Mesh) != nullptr);
    CHECK(f.main_pick(5, render::LodKind::Mesh)->level == 3);
    CHECK(f.main_pick(5, render::LodKind::Group) == nullptr);
    CHECK(f.main_pick(6, render::LodKind::Mesh) == nullptr);
    f.end_frame();
    f.begin_frame();  // a new frame forgets them
    CHECK_FALSE(f.main_set());
    CHECK(f.main_pick(5, render::LodKind::Mesh) == nullptr);
}

TEST_CASE("hlod: the proxy is the group's level past every child, fading with the group's own pick") {
    render::LodPick pick{kHlodLevel, -1, 0.0f};
    float fade = 7.0f;
    CHECK(render::hlod_proxy_shown(pick, true, fade));
    CHECK(fade == 0.0f);
    pick = render::LodPick{2, -1, 0.0f};  // a child level: the proxy is not drawn
    CHECK_FALSE(render::hlod_proxy_shown(pick, true, fade));
    pick = render::LodPick{kHlodLevel, 2, 0.25f};  // fading in from the children
    CHECK(render::hlod_proxy_shown(pick, true, fade));
    CHECK(fade == doctest::Approx(0.25f));
    CHECK(render::hlod_proxy_shown(pick, false, fade));  // a draw with no dither program switches at once
    CHECK(fade == 0.0f);
    pick = render::LodPick{1, kHlodLevel, 0.25f};  // fading out towards a child
    CHECK(render::hlod_proxy_shown(pick, true, fade));
    CHECK(fade == doctest::Approx(-0.25f));
    CHECK_FALSE(render::hlod_proxy_shown(pick, false, fade));
    CHECK(fade == 0.0f);
}

TEST_CASE("lod fades: an entity on a farther level keeps it until the metric pushed farther picks a nearer one too") {
    render::LodFades f;
    // crossFade 0 (a hard switch): the slot is kept for the hysteresis all the same.
    const auto pick = [&](int target, int farTarget) {
        f.begin_frame();
        const render::LodPick p = f.step(1, 7, render::LodKind::Mesh, target, 0.0f, 0.016f, farTarget);
        f.end_frame();
        return p.level;
    };
    CHECK(pick(0, 0) == 0);  // first seen at level 0
    CHECK(pick(1, 1) == 1);  // past the threshold: at once
    CHECK(pick(0, 1) == 1);  // back inside it, but not 5% inside: stays
    CHECK(pick(0, 1) == 1);
    CHECK(pick(0, 0) == 0);  // 5% inside: the nearer level
    CHECK(pick(0, 1) == 0);  // held level 0: the far pick says 1 only where the metric is near the threshold, and 0 is the level held
    // Several levels: 2 held, the near pick says 0 and the far pick 1: 1 is the nearest the far pick allows
    CHECK(pick(2, 2) == 2);
    CHECK(pick(0, 1) == 1);
    // No far pick given: no hysteresis
    f.begin_frame();
    CHECK(f.step(1, 7, render::LodKind::Mesh, 0, 0.0f, 0.016f).level == 0);
    f.end_frame();
}

TEST_CASE("lod render: a camera that shakes at a threshold does not flip a hard-switched level every frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const int cube = triangles_of("cube"), sphere = triangles_of("sphere");
    World w;
    add_camera(w, {0, 0, 10});
    Entity e = add_lod_cube(w, {0, 0, -20});  // 30 m: the sphere from 30 m on, crossFade 0
    const auto tris = [&](float z) {
        w.get<Transform>(e)->position = {0, 0, z};
        g.render(w);
        return g.renderer.stats().triangles;
    };
    CHECK(tris(-19.0f) == cube);    // 29 m
    CHECK(tris(-20.5f) == sphere);  // 30.5 m: at once past the threshold
    CHECK(tris(-19.5f) == sphere);  // 29.5 m: inside it, but not 5% (28.5 m): the sphere stays
    CHECK(tris(-20.2f) == sphere);
    CHECK(tris(-18.6f) == sphere);  // 28.6 m: the threshold over 1.05 is 28.57 m, not yet
    CHECK(tris(-18.4f) == cube);    // 28.4 m: the cube is back
    CHECK(tris(-19.9f) == cube);    // 29.9 m: and it stays until the threshold itself
    CHECK(tris(-20.0f) == sphere);
    g.renderer.clear_asset_cache();
}

TEST_CASE("lod render: a LodGroup keeps its farther child at a threshold the same way") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const int cube = triangles_of("cube"), sphere = triangles_of("sphere");
    World w;
    add_camera(w, {0, 0, 10});
    Entity group = make(w, "group", {0, 0, -20});
    auto& lg = w.add<LodGroup>(group);
    lg.thresholds = {30.0f};
    Entity a = make(w, "a", {0, 0, 0}), b = make(w, "b", {0, 0, 0});
    w.set_parent(a, group);
    w.set_parent(b, group);
    w.add<MeshRenderer>(a).mesh = "cube";
    w.add<MeshRenderer>(b).mesh = "sphere";
    const auto tris = [&](float z) {
        w.get<Transform>(group)->position = {0, 0, z};
        g.render(w);
        return g.renderer.stats().triangles;
    };
    CHECK(tris(-19.0f) == cube);
    CHECK(tris(-20.5f) == sphere);
    CHECK(tris(-19.5f) == sphere);  // 29.5 m: inside the threshold, not 5%
    CHECK(tris(-18.4f) == cube);    // 28.4 m
    g.renderer.clear_asset_cache();
}

TEST_CASE("hlod: a group nested in a child of another group shows its proxy only while the outer group shows that child") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const int cube = triangles_of("cube"), sphere = triangles_of("sphere"), cylinder = triangles_of("cylinder");
    REQUIRE(cube != cylinder);
    REQUIRE(sphere != cylinder);
    World w;
    add_camera(w, {0, 0, 10});
    Entity outer = make(w, "outer", {0, 0, 0});
    auto& og = w.add<LodGroup>(outer);
    og.thresholds = {100.0f};
    Entity inner = make(w, "inner", {0, 0, 0});  // the outer's child 0, itself a group with a proxy
    w.set_parent(inner, outer);
    auto& ig = w.add<LodGroup>(inner);
    ig.hlodProxy = "sphere";
    ig.hlodThreshold = 30.0f;
    Entity kid = make(w, "kid", {0, 0, 0});
    w.set_parent(kid, inner);
    w.add<MeshRenderer>(kid).mesh = "cube";
    Entity far = make(w, "far", {0, 0, 0});  // the outer's child 1
    w.set_parent(far, outer);
    w.add<MeshRenderer>(far).mesh = "cylinder";
    const auto at = [&](float distance) {
        w.get<Transform>(outer)->position = {0, 0, 10.0f - distance};
        g.render(w);
        return std::array<int, 3>{int(g.renderer.stats().hlodProxies), int(g.renderer.stats().meshes),
                                  int(g.renderer.stats().triangles)};
    };
    CHECK(at(10.0f) == std::array<int, 3>{0, 1, cube});         // the inner group's child
    CHECK(at(50.0f) == std::array<int, 3>{1, 1, sphere});       // the inner group's proxy
    CHECK(at(150.0f) == std::array<int, 3>{0, 1, cylinder});    // the outer group chose child 1: the proxy of child 0 goes with it
    CHECK(at(50.0f) == std::array<int, 3>{1, 1, sphere});       // and back
    g.renderer.clear_asset_cache();
}
