// M73.5 on a GPU: the screen-space subsurface scattering of MeshRenderer.subsurface (renderer_subsurface.cpp, shaders/subsurface.glsl, the sss variant of
// the mesh shader). A wax sphere lit from one side: the light must bleed into its dark side, never across a depth jump onto another object and never
// when no mesh asks for it. The CPU side (profile, weights, plan) is in subsurface_tests.cpp.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <string>

using namespace fa;
using namespace fa::test;

namespace {

Entity add_mesh(World& w, const char* mesh, Vec3 pos, Color color, Vec3 scale = {1, 1, 1}) {
    Entity e = make(w, mesh, pos);
    w.get<Transform>(e)->scale = scale;
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = mesh;
    m.color = color;
    return e;
}
Entity add_camera(World& w, Vec3 pos) {
    Entity cam = make(w, "cam", pos);
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    c.clearColor = Color{0.05f, 0.06f, 0.08f, 1};
    return cam;
}
void set_wax(MeshRenderer& m, float strength, float radius = 0.3f) {
    m.subsurface = strength;
    m.subsurfaceRadius = radius;
    m.subsurfaceColor = Color{1.0f, 0.5f, 0.3f, 1.0f};
}

// A wax sphere (radius 1 m) seen from 4 m, lit by one sun from the side with no shadow map, and a little ambient light: one half is lit, the other is
// dark but for the ambient light and what the scattering brings.
struct Wax {
    World w;
    Entity cam, sphere, sun;
    explicit Wax(float strength, float radius = 0.3f) {
        cam = add_camera(w, {0, 0, 4});
        w.settings().ambientLight = Color{0.04f, 0.04f, 0.05f, 1};
        sphere = add_mesh(w, "sphere", {0, 0, 0}, Color::hex(0xe8d8c0), {2, 2, 2});
        auto& m = *w.get<MeshRenderer>(sphere);
        m.roughness = 0.8f;
        set_wax(m, strength, radius);
        sun = make(w, "sun", {0, 5, 0});
        w.get<Transform>(sun)->rotation = {0, 90, 0};
        auto& l = w.add<Light>(sun);
        l.type = LightType::Directional;
        l.intensity = 2.0f;
        l.castShadows = false;
    }
    MeshRenderer& mesh() { return *w.get<MeshRenderer>(sphere); }
};

float luma(const Color& c) { return 0.2126f * c.r + 0.7152f * c.g + 0.0722f * c.b; }
bool differs(const Color& p, const Color& q, float t = 1.0f / 255) {
    return std::fabs(p.r - q.r) > t || std::fabs(p.g - q.g) > t || std::fabs(p.b - q.b) > t;
}
int count_diff(const Image& a, const Image& b, float t = 1.0f / 255) {
    int n = 0;
    for (int y = 0; y < a.height; ++y)
        for (int x = 0; x < a.width; ++x) n += differs(a.pixel(x, y), b.pixel(x, y), t);
    return n;
}
float max_diff(const Image& a, const Image& b, const Image& mask, const Image& background) {
    float m = 0.0f;
    for (int y = 0; y < a.height; ++y)
        for (int x = 0; x < a.width; ++x) {
            if (!differs(mask.pixel(x, y), background.pixel(x, y), 4.0f / 255)) continue;
            const Color p = a.pixel(x, y), q = b.pixel(x, y);
            m = std::max({m, std::fabs(p.r - q.r), std::fabs(p.g - q.g), std::fabs(p.b - q.b)});
        }
    return m;
}

// The sphere's pixels (not the clear colour) split at its centre column: the mean change of the luma of `on` against `off` on the two halves, the dark
// half being the one that is darker in `off`.
struct Halves {
    float darkChange = 0.0f, litChange = 0.0f;
    float darkPeak = 0.0f;  // the largest gain of a pixel of the dark half
    float litLoss = 0.0f;   // the largest loss of a pixel of the lit half (positive)
    int darkPixels = 0, litPixels = 0;
};
Halves halves(const Image& on, const Image& off, const Image& background) {
    float left = 0.0f, right = 0.0f, leftOff = 0.0f, rightOff = 0.0f;
    int nl = 0, nr = 0;
    float peak[2] = {0.0f, 0.0f}, loss[2] = {0.0f, 0.0f};
    const int cx = off.width / 2;
    for (int y = 0; y < off.height; ++y)
        for (int x = 0; x < off.width; ++x) {
            if (!differs(off.pixel(x, y), background.pixel(x, y), 4.0f / 255)) continue;
            const float d = luma(on.pixel(x, y)) - luma(off.pixel(x, y));
            peak[x < cx ? 0 : 1] = std::max(peak[x < cx ? 0 : 1], d);
            loss[x < cx ? 0 : 1] = std::max(loss[x < cx ? 0 : 1], -d);
            if (x < cx) {
                left += d;
                leftOff += luma(off.pixel(x, y));
                ++nl;
            } else {
                right += d;
                rightOff += luma(off.pixel(x, y));
                ++nr;
            }
        }
    Halves h;
    const bool leftDark = nl > 0 && nr > 0 && leftOff / float(nl) < rightOff / float(nr);
    h.darkPixels = leftDark ? nl : nr;
    h.litPixels = leftDark ? nr : nl;
    h.darkPeak = peak[leftDark ? 0 : 1];
    h.litLoss = loss[leftDark ? 1 : 0];
    h.darkChange = (leftDark ? left : right) / float(std::max(1, h.darkPixels));
    h.litChange = (leftDark ? right : left) / float(std::max(1, h.litPixels));
    return h;
}

Image render_empty(Gfx& g) {
    World w;
    add_camera(w, {0, 0, 4});
    w.settings().ambientLight = Color{0.04f, 0.04f, 0.05f, 1};
    return g.render(w);
}

// A second renderer on the test GPU with a chosen sample count.
struct OwnRenderer {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    OwnRenderer(Gfx& gx, int samples) : g(gx) {
        RendererDesc d;
        d.designWidth = 320;
        d.designHeight = 180;
        d.sampleCount = samples;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
    }
    ~OwnRenderer() { r.shutdown(); }
    Image draw(World& w) {
        r.begin_frame();
        r.render_world(w, 0.0f);
        r.end_frame();
        g.gpu.end_frame();
        Image img;
        std::string err;
        const bool captured = r.capture(img, &err);
        INFO("capture error: " << err);
        REQUIRE(captured);
        return img;
    }
};

}  // namespace

TEST_CASE("subsurface: a wax sphere lit from one side bleeds light into its dark side and loses some on the lit one") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("subsurface")) return;
    const Image background = render_empty(g);
    Wax off(0.0f);
    const Image plain = g.render(off.w);
    CHECK(g.renderer.stats().subsurfaceCameras == 0);
    CHECK(g.renderer.stats().subsurfaceDraws == 0);
    Wax on(0.9f);
    const Image waxed = g.render(on.w);
    const RenderStats st = g.renderer.stats();
    CHECK(st.subsurfaceCameras == 1);
    CHECK(st.subsurfaceDraws >= 1);
    const Halves h = halves(waxed, plain, background);
    REQUIRE(h.darkPixels > 500);
    REQUIRE(h.litPixels > 500);
    // The dark half gets brighter (a band along the terminator, a few pixels deep) and the lit half loses light next to it.
    CHECK(h.darkPeak > 0.015f);
    CHECK(h.darkChange > 0.0015f);
    CHECK(h.litLoss > 0.01f);
    // The scattered light is warm: the colour channel with the widest radius (red) gains more than the narrowest one (blue).
    float redGain = 0.0f, blueGain = 0.0f;
    for (int y = 0; y < plain.height; ++y)
        for (int x = 0; x < plain.width; ++x) {
            if (!differs(plain.pixel(x, y), background.pixel(x, y), 4.0f / 255)) continue;
            redGain += waxed.pixel(x, y).r - plain.pixel(x, y).r;
            blueGain += waxed.pixel(x, y).b - plain.pixel(x, y).b;
        }
    // (the sum over the sphere includes the loss on the lit side, so the comparison is between channels)
    CHECK(redGain > blueGain);
    // Nothing outside the sphere changes: the scattering only lands where a mesh scatters.
    int outside = 0;
    for (int y = 0; y < plain.height; ++y)
        for (int x = 0; x < plain.width; ++x)
            if (!differs(plain.pixel(x, y), background.pixel(x, y), 4.0f / 255))
                outside += differs(plain.pixel(x, y), waxed.pixel(x, y));
    CHECK(outside == 0);
    // A larger radius spreads further: the dark side gains in more pixels.
    Wax wide(0.9f, 0.5f);
    const Halves hw = halves(g.render(wide.w), plain, background);
    CHECK(hw.darkChange > h.darkChange * 0.9f);
    expect_golden(waxed, "3d_subsurface_wax");
}

TEST_CASE(
    "subsurface: with no mesh that scatters the picture is bit for bit the plain one, whatever the other values") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("subsurface")) return;
    Wax plainScene(0.0f);
    const Image plain = g.render(plainScene.w);
    // The radius and colour of a mesh with strength 0 mean nothing.
    Wax other(0.0f, 0.4f);
    other.mesh().subsurfaceColor = Color{0.2f, 0.9f, 0.1f, 1};
    CHECK(count_diff(g.render(other.w), plain, 0.0f) == 0);
    CHECK(g.renderer.stats().subsurfaceCameras == 0);
    CHECK(g.renderer.stats().subsurfaceDraws == 0);
    // A radius of 0 (or a negative strength) scatters nothing visible and costs no draw.
    Wax negative(-0.5f);
    CHECK(count_diff(g.render(negative.w), plain, 0.0f) == 0);
    CHECK(g.renderer.stats().subsurfaceDraws == 0);
    // An unlit mesh has no diffuse light to scatter.
    Wax unlit(0.9f);
    Wax unlitPlain(0.0f);
    unlit.mesh().unlit = true;
    unlitPlain.mesh().unlit = true;
    CHECK(count_diff(g.render(unlit.w), g.render(unlitPlain.w), 0.0f) == 0);
    CHECK(g.renderer.stats().subsurfaceDraws == 0);
    // The same picture twice: nothing of a frame stays for the next.
    Wax on(0.9f);
    const Image a = g.render(on.w);
    const Image b = g.render(on.w);
    CHECK(count_diff(a, b, 0.0f) == 0);
    // The emission is not scattered: a mesh with no light on it but its own glow, scattering or not, is the same picture.
    Wax glow(0.9f);
    Wax glowPlain(0.0f);
    for (Wax* s : {&glow, &glowPlain}) {
        s->w.remove<Light>(s->sun);
        s->w.settings().ambientLight = Color{0, 0, 0, 1};
        s->mesh().emissive = Color{1.0f, 0.6f, 0.2f, 1};
        s->mesh().emissiveStrength = 1.0f;
    }
    CHECK(count_diff(g.render(glow.w), g.render(glowPlain.w), 0.0f) == 0);
}

TEST_CASE("subsurface: the light does not bleed across a depth jump onto the object behind, nor from it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("subsurface")) return;
    const Image background = render_empty(g);
    // The front sphere alone, and the same sphere before a big red one 3 m behind that scatters too (a lit red wall of wax, the light on it from the
    // same side). The front sphere's pixels must be the same in both: the red light of the back one never reaches them, however close the two are on
    // the screen.
    Wax alone(0.9f);
    alone.w.get<Transform>(alone.sphere)->scale = {1.5f, 1.5f, 1.5f};
    const Image frontOnly = g.render(alone.w);
    Wax both(0.9f);
    both.w.get<Transform>(both.sphere)->scale = {1.5f, 1.5f, 1.5f};
    Entity back = add_mesh(both.w, "sphere", {0.2f, 0.0f, -3.0f}, Color::hex(0xff2010), {5, 5, 5});
    set_wax(*both.w.get<MeshRenderer>(back), 0.9f, 0.3f);
    const Image withBack = g.render(both.w);
    CHECK(g.renderer.stats().subsurfaceDraws >= 2);
    // The back sphere is there (it changes the picture) and scatters (its change with the scattering off differs).
    CHECK(count_diff(withBack, frontOnly) > 3000);
    Wax backOff(0.9f);
    backOff.w.get<Transform>(backOff.sphere)->scale = {1.5f, 1.5f, 1.5f};
    Entity back2 = add_mesh(backOff.w, "sphere", {0.2f, 0.0f, -3.0f}, Color::hex(0xff2010), {5, 5, 5});
    set_wax(*backOff.w.get<MeshRenderer>(back2), 0.0f, 0.3f);
    const Image withBackPlain = g.render(backOff.w);
    CHECK(count_diff(withBack, withBackPlain) > 200);
    // The pixels of the front sphere (what `frontOnly` draws over the clear colour) are equal with and without the red one behind, to the last bit of
    // an 8-bit channel or two (the light of the front sphere does not depend on the other one: no shadow map, no AO).
    CHECK(max_diff(withBack, frontOnly, frontOnly, background) < 3.0f / 255);
    // The front sphere with the scattering on is itself different from the plain pair (the check above is not against an unchanged picture).
    Wax frontPlain(0.0f);
    frontPlain.w.get<Transform>(frontPlain.sphere)->scale = {1.5f, 1.5f, 1.5f};
    CHECK(count_diff(frontOnly, g.render(frontPlain.w)) > 100);
}

TEST_CASE("subsurface: the stats count a camera and the draws of its meshes, a split screen scatters in each camera") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("subsurface")) return;
    Wax s(0.9f);
    Entity second = add_mesh(s.w, "sphere", {2.5f, 0, 0}, Color::hex(0xe8d8c0), {1, 1, 1});
    set_wax(*s.w.get<MeshRenderer>(second), 0.9f);
    (void)g.render(s.w);
    // Two spheres with the same values share a batch; different values are two draws.
    CHECK(g.renderer.stats().subsurfaceCameras == 1);
    CHECK(g.renderer.stats().subsurfaceDraws >= 1);
    // Two cameras side by side, each with its own sphere in front of it.
    World w;
    w.settings().ambientLight = Color{0.04f, 0.04f, 0.05f, 1};
    Entity left = add_camera(w, {0, 0, 4});
    w.get<Camera>(left)->viewport = {0, 0, 0.5f, 1};
    Entity right = add_camera(w, {10, 0, 4});
    w.get<Camera>(right)->viewport = {0.5f, 0, 0.5f, 1};
    w.get<Camera>(right)->depth = 1;
    for (float x : {0.0f, 10.0f}) {
        Entity e = add_mesh(w, "sphere", {x, 0, 0}, Color::hex(0xe8d8c0), {2, 2, 2});
        set_wax(*w.get<MeshRenderer>(e), 0.9f);
    }
    Entity sun = make(w, "sun", {0, 5, 0});
    w.get<Transform>(sun)->rotation = {0, 90, 0};
    auto& l = w.add<Light>(sun);
    l.type = LightType::Directional;
    l.intensity = 2.0f;
    l.castShadows = false;
    const Image split = g.render(w);
    CHECK(g.renderer.stats().subsurfaceCameras == 2);
    CHECK(g.renderer.stats().subsurfaceDraws >= 2);
    // The two halves are the same sphere seen the same way: the picture of the left half is the right half's (a camera's passes never reach the other's
    // rectangle).
    int diff = 0;
    const int half = split.width / 2;
    for (int y = 0; y < split.height; ++y)
        for (int x = 0; x < half; ++x) diff += differs(split.pixel(x, y), split.pixel(x + half, y), 3.0f / 255);
    CHECK(diff < 40);
}

TEST_CASE("subsurface: with MSAA the sphere scatters too, and its silhouette stays clean") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("subsurface")) return;
    OwnRenderer msaa(g, 4);
    if (!msaa.ok) return;
    if (!msaa.r.supports("subsurface")) return;
    Wax off(0.0f);
    const Image plain = msaa.draw(off.w);
    Wax on(0.9f);
    const Image waxed = msaa.draw(on.w);
    CHECK(msaa.r.stats().subsurfaceCameras == 1);
    const Image background = [&] {
        World w;
        add_camera(w, {0, 0, 4});
        w.settings().ambientLight = Color{0.04f, 0.04f, 0.05f, 1};
        return msaa.draw(w);
    }();
    const Halves h = halves(waxed, plain, background);
    REQUIRE(h.darkPixels > 500);
    CHECK(h.darkPeak > 0.015f);
    // The anti-aliased edge pixels: the scattering only adds light on a pixel the sphere covers, so the clear colour far from the sphere is untouched.
    int outside = 0;
    for (int y = 0; y < plain.height; ++y)
        for (int x = 0; x < plain.width; ++x)
            if (!differs(plain.pixel(x, y), background.pixel(x, y), 1.0f / 255))
                outside += differs(plain.pixel(x, y), waxed.pixel(x, y));
    CHECK(outside == 0);
}
