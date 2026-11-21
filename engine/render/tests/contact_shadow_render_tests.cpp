// M73.2c on a GPU: the contact shadows of the mesh fragment shader (shaders/light_loop.glsl, block fa_contact). A small object on a floor lit
// by a grazing sun: with the shadow map off, the only thing that darkens the floor next to the object is the screen-space ray. The CPU side
// (the light data texture's region) is in light_clusters_tests.cpp, the slot table in mesh_slots_tests.cpp.
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

// What the tests share: a floor, a small box on it and a sun 20 degrees over the horizon that casts no shadow map, so every dark pixel
// next to the box comes from the contact ray. The camera looks at the box from the front and above.
struct Scene {
    World w;
    Entity floor, box, sun;
    Scene(float contactLength, bool master) {
        add_camera(w, {0.5f, 3.0f, 5.0f}, {-0.5f, 0.0f, 0.0f});
        w.settings().ambientLight = Color{0.1f, 0.1f, 0.12f, 1};
        w.settings().contactShadows = master;
        floor = add_mesh(w, "plane", {0, 0, 0}, Color::hex(0xc8c8c8), {16, 1, 16});
        box = add_mesh(w, "cube", {0, 0.3f, 0}, Color::hex(0xd8c8b0), {1.2f, 0.6f, 1.2f});
        sun = make(w, "sun", {0, 5, 0});
        w.get<Transform>(sun)->rotation = {
            -20, 60, 0};  // the light travels toward -x, -z and down: the shade falls left and behind
        auto& l = w.add<Light>(sun);
        l.type = LightType::Directional;
        l.intensity = 1.5f;
        l.castShadows = false;
        l.contactShadowLength = contactLength;
    }
};

float luma(const Color& c) { return 0.2126f * c.r + 0.7152f * c.g + 0.0722f * c.b; }

struct Diff {
    int darker = 0;   // pixels where `on` is darker than `off` by more than the threshold
    int lighter = 0;  // pixels where `on` is lighter
    int any = 0;      // pixels that differ at all (any channel, more than 1/255)
    float meanDark = 0.0f;
};
Diff compare(const Image& on, const Image& off, float t = 0.02f) {
    Diff d;
    float sum = 0.0f;
    for (int y = 0; y < on.height; ++y)
        for (int x = 0; x < on.width; ++x) {
            const Color p = on.pixel(x, y), q = off.pixel(x, y);
            if (std::fabs(p.r - q.r) > 1.0f / 255 || std::fabs(p.g - q.g) > 1.0f / 255 ||
                std::fabs(p.b - q.b) > 1.0f / 255)
                ++d.any;
            const float dl = luma(q) - luma(p);
            if (dl > t) {
                ++d.darker;
                sum += dl;
            }
            if (dl < -t) ++d.lighter;
        }
    d.meanDark = d.darker > 0 ? sum / float(d.darker) : 0.0f;
    return d;
}

}  // namespace

TEST_CASE("contact shadows: a grazing sun darkens the floor where a box touches it, and nowhere else") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("contactShadows")) return;
    Scene on(1.5f, true);
    const Image shaded = g.render(on.w);
    const RenderStats withStats = g.renderer.stats();
    Scene off(1.5f, false);
    const Image plain = g.render(off.w);
    const RenderStats withoutStats = g.renderer.stats();
    CHECK(withStats.contactShadowLights == 1);
    CHECK(withoutStats.contactShadowLights == 0);
    const Diff d = compare(shaded, plain);
    // A band of floor along the box (the ray is 1.5 m long, the floor is seen from 3 m up): a few hundred pixels of a 320x180 picture,
    // never lighter, clearly darker (the direct light is most of the floor's brightness).
    CHECK(d.darker > 150);
    CHECK(d.darker < 6000);
    CHECK(d.lighter == 0);
    CHECK(d.meanDark > 0.05f);
    // Far from the box (the picture's top rows are the horizon, its lower right corner the floor 2 m from the box in the light) nothing
    // changed: the ray is 1.5 m long and the contact fades out.
    int farChanged = 0;
    for (int y = 0; y < 30; ++y)
        for (int x = 0; x < shaded.width; ++x) {
            const Color p = shaded.pixel(x, y), q = plain.pixel(x, y);
            farChanged += std::fabs(p.r - q.r) > 1.0f / 255 || std::fabs(p.g - q.g) > 1.0f / 255;
        }
    CHECK(farChanged == 0);
    expect_golden(shaded, "3d_contact_shadows");
}

TEST_CASE(
    "contact shadows: switched off (the master switch, or a length of 0) the picture is bit for bit the plain one") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("contactShadows")) return;
    Scene plainScene(0.0f, true);  // the master is on, no light asks for a ray: no prepass, no ray
    const Image plain = g.render(plainScene.w);
    CHECK(g.renderer.stats().contactShadowLights == 0);
    Scene masterOff(1.5f, false);
    const Image off = g.render(masterOff.w);
    CHECK(g.renderer.stats().contactShadowLights == 0);
    CHECK(compare(off, plain).any == 0);
    // A negative or NaN length counts as none.
    Scene bad(-2.0f, true);
    CHECK(compare(g.render(bad.w), plain).any == 0);
    // A mesh that does not receive shadows gets no contact shadow either.
    Scene noRecv(1.5f, true);
    noRecv.w.get<MeshRenderer>(noRecv.floor)->receiveShadows = false;
    Scene noRecvOff(1.5f, false);
    noRecvOff.w.get<MeshRenderer>(noRecvOff.floor)->receiveShadows = false;
    CHECK(compare(g.render(noRecv.w), g.render(noRecvOff.w)).any == 0);
}

TEST_CASE("contact shadows: the picture does not change from frame to frame and a longer ray shades more") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("contactShadows")) return;
    Scene shortRay(0.4f, true);
    const Image a = g.render(shortRay.w);
    const Image b = g.render(shortRay.w);
    CHECK(compare(a, b).any == 0);  // the jitter is the pixel's, never the frame's
    Scene longRay(2.0f, true);
    Scene off(0.0f, true);
    const Image plain = g.render(off.w);
    const Diff shortDiff = compare(a, plain), longDiff = compare(g.render(longRay.w), plain);
    CHECK(shortDiff.darker > 20);
    CHECK(longDiff.darker > shortDiff.darker);
}

TEST_CASE("contact shadows: a point light's ray and a second sun that has none") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("contactShadows")) return;
    Scene s(0.0f, true);
    const Image plain = g.render(s.w);
    // A point light low beside the box, with no shadow map: only its ray shades the floor behind the box.
    Entity lamp = make(s.w, "lamp", {1.6f, 0.5f, 1.0f});
    auto& l = s.w.add<Light>(lamp);
    l.type = LightType::Point;
    l.intensity = 4.0f;
    l.range = 8.0f;
    l.castShadows = false;
    const Image lit = g.render(s.w);
    l.contactShadowLength = 2.0f;
    const Image shaded = g.render(s.w);
    CHECK(g.renderer.stats().contactShadowLights == 1);
    const Diff d = compare(shaded, lit);
    CHECK(d.darker > 50);
    CHECK(d.lighter == 0);
    CHECK(compare(lit, plain).any >
          0);  // the lamp lights the scene: the comparison above is not against an empty change
    // An area light is marched toward the point of its emitter like a point light: the same ray shades the floor behind the box.
    l.type = LightType::Area;
    l.contactShadowLength = 0.0f;
    const Image areaPlain = g.render(s.w);
    l.contactShadowLength = 2.0f;
    const Image area = g.render(s.w);
    CHECK(g.renderer.stats().contactShadowLights == 1);
    const Diff da = compare(area, areaPlain);
    CHECK(da.darker > 20);
    CHECK(da.lighter == 0);
}
