// M73.2b on a GPU: the shadows of point and spot lights are drawn from the shadow atlas, the budget degrades them without a crash, and
// a scene with no local caster is drawn exactly as before. The CPU side (faces, budget, records) is in local_shadows_tests.cpp.
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
Entity add_local(World& w, LightType type, Vec3 pos, Vec3 rot, float range, float intensity = 3.0f) {
    Entity e = make(w, "lamp", pos);
    w.get<Transform>(e)->rotation = rot;
    auto& l = w.add<Light>(e);
    l.type = type;
    l.intensity = intensity;
    l.range = range;
    l.spotAngle = 45;
    l.castShadows = true;
    return e;
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

// A floor, a back wall and two pillars lit by one lamp. Nothing else lights the scene, so the shadows are what the picture shows.
void room(World& w) {
    add_camera(w, {0, 4, 9}, {0, 0.5f, 0});
    w.settings().ambientLight = Color{0.05f, 0.05f, 0.06f, 1};
    add_mesh(w, "plane", {0, 0, 0}, Color::hex(0xc8c8c8), {16, 1, 16});
    add_mesh(w, "cube", {0, 3, -7}, Color::hex(0xc8c8c8), {16, 6, 0.4f});  // the back wall
    add_mesh(w, "cube", {-1.5f, 1, -1}, Color::hex(0xd8d0c8), {1, 2, 1});
    add_mesh(w, "cube", {2.5f, 0.75f, 1.5f}, Color::hex(0xc8d0d8), {1.2f, 1.5f, 1.2f});
}

}  // namespace

TEST_CASE("local shadows: a spot light's shadow is drawn from one tile of the atlas") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("spotShadows")) return;
    World w;
    room(w);
    const Entity lamp = add_local(w, LightType::Spot, {0, 6, 2}, {-90, 0, 0}, 14);
    w.get<Light>(lamp)->spotAngle = 55;
    const Image shadowed = g.render(w);
    const RenderStats with = g.renderer.stats();
    w.get<Light>(lamp)->castShadows = false;
    const Image plain = g.render(w);
    const RenderStats without = g.renderer.stats();
    CHECK(with.shadowCasters == 3);  // the floor and the two pillars: the wall is outside the cone of the spot
    CHECK(with.drawCalls > without.drawCalls);
    CHECK(differing(shadowed, plain, 60, 180) > 150);  // the pillars' shadows fall on the floor
    expect_golden(shadowed, "3d_shadows_spot");
}

TEST_CASE("local shadows: a point light's shadows are drawn from six faces of the atlas") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("pointShadows")) return;
    World w;
    room(w);
    const Entity lamp = add_local(w, LightType::Point, {0.5f, 3.2f, 0.5f}, {0, 0, 0}, 12);
    const Image shadowed = g.render(w);
    const RenderStats with = g.renderer.stats();
    w.get<Light>(lamp)->castShadows = false;
    const Image plain = g.render(w);
    const RenderStats without = g.renderer.stats();
    CHECK(with.shadowCasters == 4);
    CHECK(with.drawCalls > without.drawCalls + 3);  // the casters are drawn into the faces that hold them
    CHECK(differing(shadowed, plain, 60, 180) > 400);
    expect_golden(shadowed, "3d_shadows_point");
    // The same scene twice gives the same picture: the budget and the faces depend on the scene only.
    w.get<Light>(lamp)->castShadows = true;
    const Image a = g.render(w);
    const Image b = g.render(w);
    CHECK(differing(a, b, 0, a.height, 0.0f) == 0);
    CHECK(differing(a, shadowed, 0, a.height, 0.0f) == 0);
}

TEST_CASE("local shadows: hard, PCF and PCSS filters differ, and the shadow distance fades the shadow out") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("spotShadows")) return;
    World w;
    room(w);
    const Entity lamp = add_local(w, LightType::Spot, {0, 6, 2}, {-90, 0, 0}, 14);
    Light* light = w.get<Light>(lamp);
    light->spotAngle = 55;
    light->shadowSoftness = 5;
    light->shadowFilter = ShadowFilter::Hard;
    const Image hard = g.render(w);
    light->shadowFilter = ShadowFilter::Pcf;
    const Image pcf = g.render(w);
    light->shadowFilter = ShadowFilter::Pcss;
    const Image pcss = g.render(w);
    CHECK(differing(hard, pcf, 60, 180, 0.03f) > 20);
    CHECK(differing(pcss, pcf, 60, 180, 0.03f) > 20);
    // A shadow distance shorter than the camera's distance to the light (the camera is 9 m from the scene): the shadow is gone and
    // the picture equals the one of a light that casts none.
    light->shadowFilter = ShadowFilter::Pcf;
    light->shadowDistance = 1;
    const Image faded = g.render(w);
    light->castShadows = false;
    const Image plain = g.render(w);
    CHECK(differing(faded, plain, 0, faded.height, 0.0f) == 0);
}

TEST_CASE("local shadows: a light with no caster in its range, or a scene with no local caster, is drawn exactly as before") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("pointShadows")) return;
    World w;
    room(w);
    // A lamp far from everything (its range reaches no caster) that asks for shadows.
    const Entity far = add_local(w, LightType::Point, {60, 3, 60}, {0, 0, 0}, 6);
    const Image asked = g.render(w);
    const RenderStats withAsk = g.renderer.stats();
    w.get<Light>(far)->castShadows = false;
    const Image none = g.render(w);
    const RenderStats withoutAsk = g.renderer.stats();
    CHECK(differing(asked, none, 0, asked.height, 0.0f) == 0);
    CHECK(withAsk.drawCalls == withoutAsk.drawCalls);
    // A lamp near the casters that does not ask: no shadow draw at all.
    const Entity near = add_local(w, LightType::Point, {0.5f, 3.2f, 0.5f}, {0, 0, 0}, 12);
    w.get<Light>(near)->castShadows = false;
    g.render(w);
    const int quiet = g.renderer.stats().drawCalls;
    w.get<Light>(near)->castShadows = true;
    g.render(w);
    CHECK(g.renderer.stats().drawCalls > quiet);
}

TEST_CASE("local shadows: more lights than the atlas holds lose their shadows in order and never fail") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("pointShadows")) return;
    World w;
    room(w);
    w.settings().shadowAtlasSize = 512;  // eight faces of 128... far fewer than the 16 lamps (96 faces) ask for
    for (int i = 0; i < 16; ++i) {
        const float x = -7.5f + float(i), z = (i % 2) ? 3.0f : -2.0f;
        const Entity e = add_local(w, LightType::Point, {x, 3.0f, z}, {0, 0, 0}, 5, 0.5f);
        w.get<Light>(e)->shadowResolution = 256;
    }
    const Image a = g.render(w);
    const RenderStats st = g.renderer.stats();
    CHECK(st.shadowCasters > 0);
    CHECK(st.drawCalls > 0);
    const Image b = g.render(w);
    CHECK(differing(a, b, 0, a.height, 0.0f) == 0);  // the same lights lose the same shadows every frame
    // Fewer lights fit: the picture changes (a light that kept its shadow now draws it).
    w.each<Light>([&](Entity e, Light& l) {
        if (w.get<Transform>(e)->position.x > -4.0f) l.castShadows = false;
    });
    const Image c = g.render(w);
    CHECK(differing(a, c, 0, a.height, 0.0f) > 0);
}
