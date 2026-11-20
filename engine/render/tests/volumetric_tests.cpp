// M73.5: the volumetric fog and the light shafts (src/renderer_volumetric.cpp, shaders/volumetric.glsl). The CPU parts (the quality table, the maths the
// shader mirrors, the choice of lights, the plan) need no GPU. The GPU tests draw scenes of a dark room with white fog, so a pixel's brightness is the
// light the medium scatters toward the camera.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <set>
#include <string>
#include <vector>

#include "frame_graph.h"
#include "mesh_batch.h"
#include "postprocess.h"
#include "renderer_test_access.h"
#include "renderer_volumetric.h"

using namespace fa;
using namespace fa::test;
using namespace fa::render;

namespace {

// ---------------------------------------------------------------------------
// CPU helpers
// ---------------------------------------------------------------------------

LightData directional(float volumetric, Vec3 toLight = {0, 1, 0}, int rank = 1) {
    LightData l;
    l.pos = Vec4{toLight.x, toLight.y, toLight.z, 0.0f};
    l.color = Vec4{1.0f, 0.9f, 0.8f, 0.0f};
    l.dir = Vec4{0, 0, 0, 0};
    l.rank = rank;
    l.volumetric = volumetric;
    return l;
}
LightData point(float volumetric, float score = 1.0f, float range = 10.0f) {
    LightData l;
    l.pos = Vec4{1, 2, 3, range};
    l.color = Vec4{1.0f, 1.0f, 1.0f, 1.0f};
    l.dir = Vec4{0, 0, 0, 0};
    l.rank = 2;
    l.score = score;
    l.volumetric = volumetric;
    return l;
}
LightData spot(float volumetric, float cosOuter = 0.7f, float cosInner = 2.0f) {
    LightData l = point(volumetric);
    l.color.w = 2.0f;
    l.dir = Vec4{0, -1, 0, cosOuter};
    l.cosInner = cosInner;
    return l;
}

CameraGeometry camera_info(bool perspective = true) {
    CameraGeometry c;
    c.view = Mat4::translate({0, 0, -10});
    c.proj = perspective ? Mat4::perspective(60.0f, 16.0f / 9.0f, 0.1f, 1000.0f, true)
                         : Mat4::ortho(-8.0f, 8.0f, -4.5f, 4.5f, 0.1f, 1000.0f, true);
    c.viewProj = c.proj * c.view;
    c.invViewProj = c.viewProj.inverse();
    c.position = {0, 0, 10};
    c.perspective = perspective;
    return c;
}
SceneSettings fog_settings() {
    SceneSettings ss;
    ss.volumetricFog = true;
    ss.volumetricDensity = 0.05f;
    return ss;
}

// ---------------------------------------------------------------------------
// GPU helpers
// ---------------------------------------------------------------------------

Entity add_camera(World& w, Vec3 pos, Vec3 lookAt) {
    Entity cam = make(w, "cam", pos);
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60.0f;
    c.clearColor = Color{0, 0, 0, 1};
    const Vec3 f = normalize(lookAt - pos);
    w.get<Transform>(cam)->rotation = {degrees(std::asin(f.y)), degrees(std::atan2(-f.x, -f.z)), 0};
    return cam;
}
Entity add_box(World& w, Vec3 pos, Vec3 scale, Color color = Color{0.03f, 0.03f, 0.03f, 1.0f}) {
    Entity e = make(w, "box", pos);
    w.get<Transform>(e)->scale = scale;
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = "cube";
    m.color = color;
    return e;
}
Entity add_light(World& w, LightType type, Vec3 pos, Vec3 rot, float volumetric, float intensity = 4.0f) {
    Entity e = make(w, "lamp", pos);
    w.get<Transform>(e)->rotation = rot;
    auto& l = w.add<Light>(e);
    l.type = type;
    l.intensity = intensity;
    l.range = 30.0f;
    l.spotAngle = 35.0f;
    l.volumetric = volumetric;
    return e;
}
// A dark, unlit-by-ambient room seen from z = 12: a back wall at z = -10 and the white fog.
Entity fog_room(World& w, float density = 0.06f) {
    const Entity cam = add_camera(w, {0, 2, 12}, {0, 2, 0});
    SceneSettings& ss = w.settings();
    ss.ambientLight = Color{0, 0, 0, 1};
    ss.skyColor = ss.horizonColor = Color{0, 0, 0, 1};
    ss.fogColor = Color{1, 1, 1, 1};
    ss.volumetricFog = true;
    ss.volumetricDensity = density;
    ss.volumetricDistance = 40.0f;
    ss.volumetricAnisotropy = 0.0f;
    add_box(w, {0, 3, -10}, {40, 12, 0.5f});
    return cam;
}
float luma(const Image& img, int x, int y) {
    const Color c = img.pixel(x, y);
    return (c.r + c.g + c.b) / 3.0f;
}
// The mean brightness of the w x h block whose top-left pixel is (x, y).
float block(const Image& img, int x, int y, int w, int h) {
    double s = 0;
    for (int j = 0; j < h; ++j)
        for (int i = 0; i < w; ++i) s += luma(img, x + i, y + j);
    return float(s / double(w * h));
}
int differing(const Image& a, const Image& b, float t = 0.0f) {
    REQUIRE(a.width == b.width);
    REQUIRE(a.height == b.height);
    int n = 0;
    for (int y = 0; y < a.height; ++y)
        for (int x = 0; x < a.width; ++x) {
            const Color p = a.pixel(x, y), q = b.pixel(x, y);
            if (std::fabs(p.r - q.r) > t || std::fabs(p.g - q.g) > t || std::fabs(p.b - q.b) > t) ++n;
        }
    return n;
}
bool has_pass(const std::vector<std::string>& names, const char* part) {
    for (const std::string& n : names)
        if (n.find(part) != std::string::npos) return true;
    return false;
}
std::vector<std::string> pass_order(Gfx& g) {
    const FrameGraph* graph = renderer_frame_graph(g.renderer);
    REQUIRE(graph != nullptr);
    return graph->order_names();
}

}  // namespace

// ---------------------------------------------------------------------------
// CPU
// ---------------------------------------------------------------------------

TEST_CASE("volumetric: the quality table and the size of the march image") {
    const VolQuality lo = vol_quality(VolumetricQuality::Low);
    const VolQuality mid = vol_quality(VolumetricQuality::Medium);
    const VolQuality hi = vol_quality(VolumetricQuality::High);
    CHECK(lo.divisor == 4);
    CHECK(mid.divisor == 2);
    CHECK(hi.divisor == 2);
    // More quality never costs less, and every number fits the loops of the shader.
    CHECK(lo.steps < mid.steps);
    CHECK(mid.steps < hi.steps);
    CHECK(lo.maxLights < mid.maxLights);
    CHECK(mid.maxLights < hi.maxLights);
    CHECK(lo.samples < mid.samples);
    CHECK(mid.samples < hi.samples);
    for (const VolQuality& q : {lo, mid, hi}) {
        CHECK(q.steps <= kVolMaxSteps);
        CHECK(q.samples <= kVolMaxSamples);
        CHECK(q.maxLights <= kVolMaxLocal);
    }
    int w = 0, h = 0;
    vol_grid_size(320, 180, 2, &w, &h);
    CHECK(w == 160);
    CHECK(h == 90);
    vol_grid_size(321, 181, 4, &w, &h);
    CHECK(w == 81);
    CHECK(h == 46);
    vol_grid_size(0, -5, 2, &w, &h);
    CHECK(w == 1);
    CHECK(h == 1);
}

TEST_CASE("volumetric: the phase function, the jitter and the density") {
    for (const float c : {-1.0f, -0.3f, 0.0f, 0.8f, 1.0f}) CHECK(vol_phase(0.0f, c) == doctest::Approx(1.0f));
    CHECK(vol_phase(0.6f, 1.0f) > vol_phase(0.6f, -1.0f));
    CHECK(vol_phase(-0.6f, -1.0f) > vol_phase(-0.6f, 1.0f));
    // The phase function (times 4 pi) averages to 1 over the sphere: the fog scatters as much light as it takes in.
    for (const float g : {0.4f, -0.7f, 0.9f}) {
        double sum = 0;
        const int n = 20000;
        for (int i = 0; i < n; ++i) sum += double(vol_phase(g, -1.0f + 2.0f * (float(i) + 0.5f) / float(n)));
        CHECK(float(sum / n) == doctest::Approx(1.0f).epsilon(0.01));
    }
    // The jitter is a function of the pixel: in [0, 1), the same on every call, spread over the range.
    double mean = 0;
    std::set<int> buckets;
    for (int y = 0; y < 64; ++y)
        for (int x = 0; x < 64; ++x) {
            const float j = vol_jitter(x, y);
            REQUIRE(j >= 0.0f);
            REQUIRE(j < 1.0f);
            CHECK(vol_jitter(x, y) == j);
            mean += double(j);
            buckets.insert(int(j * 10.0f));
        }
    CHECK(float(mean / 4096.0) == doctest::Approx(0.5f).epsilon(0.05));
    CHECK(buckets.size() == 10);

    CHECK(vol_density(0.02f, 5.0f, 0.5f, 1.0f) == doctest::Approx(0.02f));  // below the base
    CHECK(vol_density(0.02f, 5.0f, 0.5f, 5.0f) == doctest::Approx(0.02f));
    CHECK(vol_density(0.02f, 5.0f, 0.5f, 7.0f) == doctest::Approx(0.02f * std::exp(-1.0f)));
    CHECK(vol_density(0.02f, 5.0f, 0.0f, 50.0f) == doctest::Approx(0.02f));  // no falloff: the same at every height
}

TEST_CASE("volumetric: the optical depth is the integral of the density along the ray") {
    struct Case {
        float density, base, falloff, y0, ry, t;
    };
    const Case cases[] = {
        {0.05f, 2.0f, 0.3f, 1.0f, 0.2f, 40.0f},   // rising through the base
        {0.05f, 2.0f, 0.3f, 6.0f, -0.3f, 30.0f},  // descending into it
        {0.05f, 2.0f, 0.3f, 6.0f, 0.0f, 25.0f},   // level
        {0.02f, 0.0f, 0.0f, 3.0f, 0.4f, 50.0f},   // no falloff
        {0.1f, -3.0f, 1.5f, 0.0f, 0.05f, 12.0f},  // steep falloff, a base below the camera
    };
    for (const Case& c : cases) {
        double acc = 0;
        const int n = 20000;
        for (int i = 0; i < n; ++i) {
            const float t = c.t * (float(i) + 0.5f) / float(n);
            acc += double(vol_density(c.density, c.base, c.falloff, c.y0 + c.ry * t)) * double(c.t) / double(n);
        }
        INFO("density " << c.density << " falloff " << c.falloff << " ry " << c.ry);
        CHECK(vol_optical_depth(c.density, c.base, c.falloff, c.y0, c.ry, c.t) == doctest::Approx(float(acc)).epsilon(0.005));
    }
    CHECK(vol_optical_depth(0.05f, 0.0f, 0.0f, 0.0f, 0.5f, 0.0f) == 0.0f);
}

TEST_CASE("volumetric: the lights that shine in the fog") {
    // Nothing shines with volumetric 0, and a light with no colour never counts.
    {
        std::vector<LightData> lights{directional(0.0f), point(0.0f), spot(0.0f)};
        LightData dark = point(1.0f);
        dark.color = Vec4{0, 0, 0, 1};
        lights.push_back(dark);
        LightData rangeless = point(1.0f, 1.0f, 0.0f);
        lights.push_back(rangeless);
        const VolLightPick pick = pick_volumetric_lights(lights, 8);
        CHECK(pick.directional.empty());
        CHECK(pick.local.empty());
        CHECK(pick.dropped == 0);
    }
    // Directional lights keep their table order, up to the shader's four; the rest are counted.
    {
        std::vector<LightData> lights;
        for (int i = 0; i < 5; ++i) lights.push_back(directional(1.0f));
        const VolLightPick pick = pick_volumetric_lights(lights, 8);
        CHECK(pick.directional == std::vector<int>{0, 1, 2, 3});
        CHECK(pick.dropped == 1);
    }
    // More local lights than the quality allows: the most important by score * volumetric stay, listed in table order.
    {
        std::vector<LightData> lights;
        lights.push_back(directional(1.0f));
        const float scores[] = {1, 9, 2, 8, 3, 7};  // table indices 1..6
        for (const float s : scores) lights.push_back(point(1.0f, s));
        lights.push_back(spot(0.0f));  // off: never counted
        const VolLightPick pick = pick_volumetric_lights(lights, 3);
        CHECK(pick.directional == std::vector<int>{0});
        CHECK(pick.local == std::vector<int>{2, 4, 6});  // scores 9, 8, 7
        CHECK(pick.dropped == 3);
        // The strength counts too: a dim shaft of an important light loses to a strong one.
        lights[2].volumetric = 0.1f;
        const VolLightPick again = pick_volumetric_lights(lights, 3);
        CHECK(again.local == std::vector<int>{4, 5, 6});  // scores 8, 3 * 1, 7: index 2 (0.9) and 1 (1.0) lose
    }
    // Equal ranks: the lower table index wins, and the choice is the same on every call.
    {
        std::vector<LightData> lights;
        for (int i = 0; i < 6; ++i) lights.push_back(point(1.0f, 5.0f));
        const VolLightPick a = pick_volumetric_lights(lights, 4);
        const VolLightPick b = pick_volumetric_lights(lights, 4);
        CHECK(a.local == std::vector<int>{0, 1, 2, 3});
        CHECK(a.local == b.local);
        CHECK(a.dropped == 2);
    }
    // A cap above the shader's arrays is cut to them.
    {
        std::vector<LightData> lights;
        for (int i = 0; i < kVolMaxLocal + 4; ++i) lights.push_back(point(1.0f));
        const VolLightPick pick = pick_volumetric_lights(lights, 1000);
        CHECK(int(pick.local.size()) == kVolMaxLocal);
        CHECK(pick.dropped == 4);
    }
}

TEST_CASE("volumetric: the plan is off where nothing can be drawn, and clamps what it is given") {
    const std::vector<LightData> none;
    const CameraGeometry cam = camera_info();
    SceneSettings ss = fog_settings();
    CHECK(make_vol_plan(ss, cam, none, false, 320, 180, false, false).on);

    SceneSettings off = ss;
    off.volumetricFog = false;
    CHECK_FALSE(make_vol_plan(off, cam, none, false, 320, 180, false, false).on);
    CHECK_FALSE(make_vol_plan(ss, camera_info(false), none, false, 320, 180, false, false).on);  // an orthographic camera
    CHECK_FALSE(make_vol_plan(ss, cam, none, false, 0, 180, false, false).on);
    CHECK_FALSE(make_vol_plan(ss, cam, none, false, 320, 0, false, false).on);
    SceneSettings zero = ss;
    zero.volumetricDensity = 0.0f;
    CHECK_FALSE(make_vol_plan(zero, cam, none, false, 320, 180, false, false).on);
    SceneSettings nan = ss;
    nan.volumetricDensity = std::nanf("");
    CHECK_FALSE(make_vol_plan(nan, cam, none, false, 320, 180, false, false).on);
    CameraGeometry bad = cam;
    bad.proj = Mat4{};
    bad.proj.m[0] = std::nanf("");
    CHECK_FALSE(make_vol_plan(ss, bad, none, false, 320, 180, false, false).on);

    // Clamps: a density past 10 is 10, the anisotropy stays inside (-1, 1), NaN falls back to the default.
    SceneSettings wild = ss;
    wild.volumetricDensity = 1e9f;
    wild.volumetricAnisotropy = 7.0f;
    wild.volumetricDistance = std::nanf("");
    wild.volumetricHeightFalloff = -4.0f;
    const VolPlan w = make_vol_plan(wild, cam, none, false, 320, 180, false, false);
    REQUIRE(w.on);
    CHECK(w.density == doctest::Approx(10.0f));
    CHECK(w.anisotropy < 1.0f);
    CHECK(w.distance == doctest::Approx(100.0f));
    CHECK(w.heightFalloff == 0.0f);

    // The quality picks the size of the image and the loop counts; the camera's numbers reach the plan.
    for (const VolumetricQuality q : {VolumetricQuality::Low, VolumetricQuality::Medium, VolumetricQuality::High}) {
        SceneSettings s = ss;
        s.volumetricQuality = q;
        const VolPlan p = make_vol_plan(s, cam, none, false, 320, 180, false, false);
        REQUIRE(p.on);
        const VolQuality vq = vol_quality(q);
        CHECK(p.quality.steps == vq.steps);
        CHECK(p.width == (320 + vq.divisor - 1) / vq.divisor);
        CHECK(p.height == (180 + vq.divisor - 1) / vq.divisor);
        CHECK(p.proj[0] == doctest::Approx(cam.proj.at(0, 0)));
        CHECK(p.eye.z == doctest::Approx(10.0f));
    }
}

TEST_CASE("volumetric: the plan lays the lights out as the shader reads them") {
    const CameraGeometry cam = camera_info();
    SceneSettings ss = fog_settings();
    std::vector<LightData> lights;
    lights.push_back(directional(2.0f, {0, 1, 0}, 0));
    lights.push_back(point(0.5f));
    lights.push_back(spot(1.0f, 0.6f));            // the default inner cone
    lights.push_back(spot(1.0f, 0.6f, 0.9f));      // an inner cone of its own
    lights.back().shadow.casts = true;
    lights.push_back(directional(0.0f));            // off
    // Shadows drawn and the sun is the caster.
    const VolPlan p = make_vol_plan(ss, cam, lights, false, 320, 180, true, true);
    REQUIRE(p.on);
    CHECK(p.directionalCount == 1);
    CHECK(p.localCount == 3);
    CHECK(p.lightsUsed == 4);
    CHECK(p.lightsDropped == 0);
    CHECK(p.directional[0][3] == 1.0f);  // the sun's shadow applies
    CHECK(p.directional[1][0] == doctest::Approx(2.0f * 1.0f));
    CHECK(p.directional[1][1] == doctest::Approx(2.0f * 0.9f));
    // Four vectors per local light: position + range; colour * strength + cos(inner); axis + cos(outer); table index + 1 when it casts.
    // The point light: no cone (the marker -2), no shadow.
    CHECK(p.local[0][3] == doctest::Approx(10.0f));
    CHECK(p.local[1][0] == doctest::Approx(0.5f));
    CHECK(p.local[1][3] == 1.0f);
    CHECK(p.local[2][3] == -2.0f);
    CHECK(p.local[3][0] == 1.0f);  // table index 1
    CHECK(p.local[3][1] == 0.0f);
    // The spots: the default inner cone is a quarter of the way from the outer one to the axis; an own inner cone is kept.
    CHECK(p.local[5][3] == doctest::Approx(0.6f + 0.25f * 0.4f));
    CHECK(p.local[6][3] == doctest::Approx(0.6f));
    CHECK(p.local[7][1] == 0.0f);  // this spot does not cast
    CHECK(p.local[9][3] == doctest::Approx(0.9f));
    CHECK(p.local[11][0] == 3.0f);
    CHECK(p.local[11][1] == 1.0f);  // its shadow tiles are read
    // The same lights with the shadow pass off: nobody reads the atlas.
    const VolPlan noShadows = make_vol_plan(ss, cam, lights, false, 320, 180, false, false);
    CHECK(noShadows.directional[0][3] == 0.0f);
    CHECK(noShadows.local[11][1] == 0.0f);
    // Ambient colour times the share of it the fog scatters; a linear scene converts it.
    ss.ambientLight = Color{0.5f, 0.5f, 0.5f, 1.0f};
    ss.volumetricAmbient = 0.5f;
    const VolPlan amb = make_vol_plan(ss, cam, lights, false, 320, 180, false, false);
    CHECK(amb.ambient[0] == doctest::Approx(0.25f));
    const VolPlan lin = make_vol_plan(ss, cam, lights, true, 320, 180, false, false);
    CHECK(lin.ambient[0] < amb.ambient[0]);
}

// ---------------------------------------------------------------------------
// GPU
// ---------------------------------------------------------------------------

TEST_CASE("volumetric: a scene without volumetricFog is the picture it was, and draws no volumetric pass") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World plain;
    fog_room(plain);
    plain.settings().volumetricFog = false;
    add_light(plain, LightType::Spot, {0, 8, 0}, {-90, 0, 0}, 0.0f);
    const Image reference = g.render(plain);
    CHECK(g.renderer.stats().volumetricCameras == 0);
    CHECK_FALSE(has_pass(pass_order(g), "vol-"));

    // The other volumetric settings and Light.volumetric do nothing while the switch is off.
    World other;
    fog_room(other, 0.5f);
    other.settings().volumetricFog = false;
    other.settings().volumetricQuality = VolumetricQuality::High;
    other.settings().volumetricAnisotropy = 0.8f;
    const Entity lamp = add_light(other, LightType::Spot, {0, 8, 0}, {-90, 0, 0}, 3.0f);
    (void)lamp;
    const Image img = g.render(other);
    CHECK(differing(img, reference) == 0);
    const RenderStats st = g.renderer.stats();
    CHECK(st.volumetricCameras == 0);
    CHECK(st.volumetricLights == 0);
    CHECK(st.volumetricLightsDropped == 0);
    CHECK_FALSE(has_pass(pass_order(g), "vol-"));
}

TEST_CASE("volumetric: an ambient-only fog fills the view, thicker toward the far wall, and the passes are in the graph") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("volumetricFog")) return;
    World none;
    fog_room(none);
    none.settings().volumetricFog = false;
    const Image clear = g.render(none);

    World w;
    fog_room(w);
    w.settings().ambientLight = Color{0.5f, 0.5f, 0.5f, 1};
    const Image fogged = g.render(w);
    const std::vector<std::string> order = pass_order(g);
    CHECK(has_pass(order, "vol-march"));
    CHECK(has_pass(order, "vol-apply"));
    const RenderStats st = g.renderer.stats();
    CHECK(st.volumetricCameras == 1);
    CHECK(st.volumetricLights == 0);
    // The black room is lit by the fog alone now.
    CHECK(block(clear, 100, 80, 8, 8) < 0.02f);
    CHECK(block(fogged, 100, 80, 8, 8) > 0.05f);
    // The same picture every frame and after a pass through another scene: nothing depends on the clock or the frame.
    const Image again = g.render(w);
    CHECK(differing(fogged, again) == 0);
    // No light, no ambient: a medium that scatters nothing leaves the picture alone but for the light it takes out (a black room stays black).
    World dark;
    fog_room(dark);
    const Image darkImg = g.render(dark);
    CHECK(block(darkImg, 100, 80, 8, 8) < 0.02f);
}

TEST_CASE("volumetric: a spot light with Light.volumetric draws a shaft, and without it nothing") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("volumetricFog")) return;
    World w;
    fog_room(w);
    const Entity lamp = add_light(w, LightType::Spot, {0, 9, 0}, {-90, 0, 0}, 0.0f);
    const Image off = g.render(w);
    CHECK(g.renderer.stats().volumetricLights == 0);
    w.get<Light>(lamp)->volumetric = 1.0f;
    const Image on = g.render(w);
    const RenderStats st = g.renderer.stats();
    CHECK(st.volumetricCameras == 1);
    CHECK(st.volumetricLights == 1);
    CHECK(st.volumetricLightsDropped == 0);
    // The shaft stands in the middle of the picture (the camera looks along the room, the spot shines down through it): its core is much brighter
    // than the dark sides, and than the same pixels without the shaft.
    const float core = block(on, 150, 20, 20, 30);
    const float side = block(on, 4, 20, 20, 30);
    CHECK(core > side + 0.04f);
    CHECK(core > block(off, 150, 20, 20, 30) + 0.04f);
    CHECK(block(off, 150, 20, 20, 30) == doctest::Approx(block(off, 4, 20, 20, 30)).epsilon(0.5));
    // The same picture twice.
    CHECK(differing(on, g.render(w)) == 0);
    expect_golden(on, "3d_volumetric_spot", 0.01);
    // A stronger shaft is brighter.
    w.get<Light>(lamp)->volumetric = 3.0f;
    CHECK(block(g.render(w), 150, 20, 20, 30) > core);
}

TEST_CASE("volumetric: the sun's shadows cut a shaft through a gap, and without a caster it fills the view") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("volumetricFog")) return;
    World w;
    fog_room(w, 0.04f);
    // A roof of two slabs with a gap of 3 m at x = 0, from far behind the camera to past the back wall.
    add_box(w, {-8.5f, 7, 0}, {14, 0.4f, 60});
    add_box(w, {8.5f, 7, 0}, {14, 0.4f, 60});
    const Entity sun = add_light(w, LightType::Directional, {0, 20, 0}, {-90, 0, 0}, 1.0f, 1.2f);
    w.get<Light>(sun)->castShadows = true;
    const Image shafted = g.render(w);
    const RenderStats st = g.renderer.stats();
    CHECK(st.volumetricCameras == 1);
    CHECK(st.volumetricLights == 1);
    CHECK(st.shadowCasters >= 2);
    const float lit = block(shafted, 150, 60, 20, 20);   // the ray along the gap
    const float shade = block(shafted, 4, 60, 20, 20);   // the rays under a slab
    CHECK(lit > shade + 0.03f);
    expect_golden(shafted, "3d_volumetric_sun_gap", 0.01);
    // The roof does not shadow the fog when the sun casts no shadows.
    w.get<Light>(sun)->castShadows = false;
    const Image open = g.render(w);
    CHECK(block(open, 4, 60, 20, 20) > shade + 0.03f);
}

TEST_CASE("volumetric: the volumetric fog replaces the analytic fog of the scene, and an orthographic camera keeps it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("volumetricFog")) return;
    World a;
    fog_room(a);
    add_light(a, LightType::Point, {0, 4, 4}, {0, 0, 0}, 1.0f);
    const Image volOnly = g.render(a);
    World b;
    fog_room(b);
    add_light(b, LightType::Point, {0, 4, 4}, {0, 0, 0}, 1.0f);
    b.settings().fogDensity = 0.08f;
    const Image both = g.render(b);
    // The analytic fog is off where the volumetric one is drawn: no double fog.
    CHECK(differing(volOnly, both) == 0);
    CHECK(g.renderer.stats().volumetricCameras == 1);

    // An orthographic camera cannot draw it: the analytic fog stays and no pass is added.
    World c;
    const Entity camC = fog_room(c);
    c.settings().fogDensity = 0.08f;
    c.get<Camera>(camC)->projection = Projection::Orthographic;
    const Image ortho = g.render(c);
    CHECK(g.renderer.stats().volumetricCameras == 0);
    CHECK_FALSE(has_pass(pass_order(g), "vol-"));
    World d;
    const Entity camD = fog_room(d);
    d.settings().fogDensity = 0.08f;
    d.settings().volumetricFog = false;
    d.get<Camera>(camD)->projection = Projection::Orthographic;
    CHECK(differing(ortho, g.render(d)) == 0);
}

TEST_CASE("volumetric: the lights over the quality's limit are left out and counted") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("volumetricFog")) return;
    World w;
    fog_room(w);
    w.settings().volumetricQuality = VolumetricQuality::Low;  // four lights
    for (int i = 0; i < 7; ++i) {
        const Entity e = add_light(w, LightType::Point, {float(i) * 3.0f - 9.0f, 4, 2}, {0, 0, 0}, 1.0f, 2.0f);
        w.get<Light>(e)->range = 6.0f;
    }
    const Image low = g.render(w);
    RenderStats st = g.renderer.stats();
    CHECK(st.volumetricCameras == 1);
    CHECK(st.volumetricLights == vol_quality(VolumetricQuality::Low).maxLights);
    CHECK(st.volumetricLightsDropped == 7 - vol_quality(VolumetricQuality::Low).maxLights);
    w.settings().volumetricQuality = VolumetricQuality::High;  // sixteen: all seven fit
    g.render(w);
    st = g.renderer.stats();
    CHECK(st.volumetricLights == 7);
    CHECK(st.volumetricLightsDropped == 0);
    // The stats are in the JSON of game.render_stats.
    const std::string json = dump_json(st.to_json());
    CHECK(json.find("volumetricCameras") != std::string::npos);
    CHECK(json.find("volumetricLights") != std::string::npos);
    CHECK(json.find("volumetricLightsDropped") != std::string::npos);
}

TEST_CASE("volumetric: a blended mesh in front of the fog is fogged like the surface behind it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("volumetricFog")) return;
    World w;
    fog_room(w);
    w.settings().ambientLight = Color{0.5f, 0.5f, 0.5f, 1};
    add_box(w, {0, 2, 6}, {3, 3, 0.2f}, Color{0.0f, 0.0f, 0.0f, 0.5f});  // alpha below 1: a blended mesh
    const Image img = g.render(w);
    CHECK(g.renderer.stats().volumetricCameras == 1);
    // The picture shows the wall's fog through the pane, not an unfogged pane: the pixels under it are as bright as the pixels beside it, give or
    // take what the pane absorbs.
    const float behind = block(img, 150, 80, 20, 10);
    const float beside = block(img, 20, 80, 20, 10);
    CHECK(behind > 0.5f * beside);
    CHECK(behind > 0.02f);
}
