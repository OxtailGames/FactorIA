// M73.2a on a GPU: the cascaded shadows of the sun are drawn, near and far, stable from frame to frame, and the filters and the cascade
// debug view show. The CPU side (splits, snapping, the atlas layout) is in shadow_cascades_tests.cpp.
#include "test_util.h"

#include <algorithm>
#include <cmath>

using namespace fa;
using namespace fa::test;

namespace {

void add_camera(World& w, Vec3 pos, Vec3 lookAt) {
    Entity cam = make(w, "cam", pos);
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    const Vec3 f = normalize(lookAt - pos);
    w.get<Transform>(cam)->rotation = {degrees(std::asin(f.y)), degrees(std::atan2(-f.x, -f.z)), 0};
}
Entity add_mesh(World& w, const char* mesh, Vec3 pos, Color color, Vec3 scale = {1, 1, 1}) {
    Entity e = make(w, mesh, pos);
    w.get<Transform>(e)->scale = scale;
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = mesh;
    m.color = color;
    return e;
}
Entity add_sun(World& w, Vec3 rot, bool casts) {
    Entity e = make(w, "sun", {0, 5, 0});
    w.get<Transform>(e)->rotation = rot;
    auto& l = w.add<Light>(e);
    l.type = LightType::Directional;
    l.intensity = 1.0f;
    l.castShadows = casts;
    return e;
}

// A long ground with cubes along the view, from 5 m to 70 m away, lit by a sun that casts.
Entity long_scene(World& w, int cascades, ShadowFilter filter = ShadowFilter::Pcf) {
    add_camera(w, {0, 3, 8}, {0, 0.5f, -30});
    w.settings().ambientLight = Color{0.12f, 0.12f, 0.14f, 1};
    w.settings().shadowCascades = cascades;
    w.settings().shadowDistance = 90;
    add_mesh(w, "plane", {0, -0.5f, -50}, Color::hex(0xb8b8b8), {120, 1, 160});
    const float zs[] = {0, -8, -18, -32, -50, -70};
    for (int i = 0; i < 6; ++i) {
        const float k =
            1.0f + std::fabs(zs[i]) * 0.07f;  // the far ones are bigger, so that their shadows show from here
        add_mesh(w, "cube", {(i % 2 ? 2.5f : -2.5f) * k, 0.5f + (k - 1) * 1.0f, zs[i]}, Color::hex(0xd8d8d8),
                 {1.5f * k, 2 * k, 1.5f * k});
        add_mesh(w, "cube", {(i % 2 ? -4.5f : 4.5f) * k, 0.5f + (k - 1) * 1.0f, zs[i] - 3}, Color::hex(0xd8c8b8),
                 {k, 2 * k, k});
    }
    Entity sun = add_sun(w, {-40, -35, 0}, true);
    w.get<Light>(sun)->shadowFilter = filter;
    return sun;
}

// The number of pixels of rows y0..y1 that differ by more than `t` in any channel.
int differing(const Image& a, const Image& b, int y0, int y1, float t = 0.04f) {
    int n = 0;
    for (int y = y0; y < y1; ++y)
        for (int x = 0; x < a.width; ++x) {
            const Color p = a.pixel(x, y), q = b.pixel(x, y);
            if (std::fabs(p.r - q.r) > t || std::fabs(p.g - q.g) > t || std::fabs(p.b - q.b) > t) ++n;
        }
    return n;
}
struct DebugViewScope {
    Renderer& r;
    DebugViewScope(Renderer& rr, DebugView v) : r(rr) { r.set_debug_view(v); }
    ~DebugViewScope() { r.set_debug_view(DebugView::None); }
    DebugViewScope(const DebugViewScope&) = delete;
    DebugViewScope& operator=(const DebugViewScope&) = delete;
};
}  // namespace

TEST_CASE("cascaded shadows: four cascades shadow the ground near the camera and far from it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("cascadedShadows")) {
        MESSAGE("cascadedShadows is not supported on this GPU: the test did not run");
        return;
    }
    World w;
    const Entity sun = long_scene(w, 4);
    const Image shadowed = g.render(w);
    const RenderStats withShadows = g.renderer.stats();
    w.get<Light>(sun)->castShadows = false;
    const Image plain = g.render(w);
    CHECK(withShadows.shadowCasters == 13);  // twelve cubes and the ground
    // The picture changes where a shadow falls: in the near half of the ground and in the far strip below the horizon.
    CHECK(differing(shadowed, plain, 110, 180) > 300);
    CHECK(differing(shadowed, plain, 78, 100) > 20);
    expect_golden(shadowed, "3d_shadows_cascades");
}

TEST_CASE(
    "cascaded shadows: the atlas made for one cascade grows when a later frame asks for four, and nothing is lost") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("cascadedShadows")) {
        MESSAGE("cascadedShadows is not supported on this GPU: the test did not run");
        return;
    }
    World w;
    const Entity sun = long_scene(w, 1);
    g.render(w);
    CHECK(g.renderer.stats().shadowCasters > 0);
    w.settings().shadowCascades = 4;  // a bigger atlas: the old one is retired after the frame
    const Image grown = g.render(w);
    const RenderStats withShadows = g.renderer.stats();
    CHECK(withShadows.shadowCasters == 13);
    const Image again = g.render(w);  // the retired atlas is gone and the frame after it is the same
    CHECK(differing(grown, again, 0, 180) == 0);
    w.get<Light>(sun)->castShadows = false;
    const Image plain = g.render(w);
    CHECK(differing(grown, plain, 110, 180) > 300);
}

TEST_CASE(
    "cascaded shadows: the same scene gives the same picture twice, and a cascade costs a pass with its casters") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("cascadedShadows")) {
        MESSAGE("cascadedShadows is not supported on this GPU: the test did not run");
        return;
    }
    World w;
    long_scene(w, 3);
    const Image a = g.render(w);
    const int drawsThree = g.renderer.stats().drawCalls;
    const Image b = g.render(w);
    CHECK(differing(a, b, 0, a.height, 0.0f) == 0);  // no noise that changes with the frame
    w.settings().shadowCascades = 1;
    g.render(w);
    const int drawsOne = g.renderer.stats().drawCalls;
    CHECK(drawsThree > drawsOne);  // one shadow draw more per extra cascade that holds a caster
    MESSAGE("draw calls with 1 cascade: " << drawsOne << ", with 3: " << drawsThree);
}

TEST_CASE("cascaded shadows: PCSS widens the edge with the distance to the caster, hard and pcf differ from it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("cascadedShadows")) {
        MESSAGE("cascadedShadows is not supported on this GPU: the test did not run");
        return;
    }
    World w;
    add_camera(w, {0, 6, 9}, {0, 0.5f, 0});
    w.settings().ambientLight = Color{0.1f, 0.1f, 0.12f, 1};
    w.settings().shadowCascades = 1;
    w.settings().shadowDistance = 30;
    add_mesh(w, "plane", {0, -0.5f, 0}, Color::hex(0xc8c8c8), {20, 1, 20});
    add_mesh(w, "cube", {-1, 3.5f, 0}, Color::hex(0xd0d0d0),
             {0.6f, 6, 0.6f});  // a pillar: its shadow gets softer away from the foot
    Entity sun = add_sun(w, {-35, -50, 0}, true);
    Light* light = w.get<Light>(sun);
    light->shadowSoftness = 4;
    light->shadowFilter = ShadowFilter::Pcss;
    const Image pcss = g.render(w);
    expect_golden(pcss, "3d_shadows_pcss");
    light->shadowFilter = ShadowFilter::Hard;
    const Image hard = g.render(w);
    light->shadowFilter = ShadowFilter::Pcf;
    const Image pcf = g.render(w);
    CHECK(differing(pcss, hard, 0, 180, 0.03f) > 150);
    CHECK(differing(pcss, pcf, 0, 180, 0.03f) > 60);
    CHECK(differing(hard, pcf, 0, 180, 0.03f) > 20);
}

TEST_CASE("cascaded shadows: render.debug_view cascades tints the ground by cascade") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("cascadedShadows")) {
        MESSAGE("cascadedShadows is not supported on this GPU: the test did not run");
        return;
    }
    World w;
    long_scene(w, 2);
    w.settings().shadowDistance = 60;
    DebugViewScope view(g.renderer, DebugView::Cascades);
    const Image img = g.render(w);
    int lowestRed = -1, highestGreen = 1000;
    for (int y = 82; y < img.height; ++y) {
        const Color c = img.pixel(160, y);
        if (c.r > c.g + 0.12f && c.r > c.b + 0.12f) lowestRed = std::max(lowestRed, y);
        if (c.g > c.r + 0.08f && c.g > c.b + 0.08f) highestGreen = std::min(highestGreen, y);
    }
    CHECK(lowestRed >= 140);    // the near ground is the first cascade
    CHECK(highestGreen < 130);  // the stretch beyond its end is the second
    CHECK(highestGreen < lowestRed);
}
