// M73-P3d: the physical sky (SceneSettings.skyModel = physical; src/physical_sky.h, src/renderer_sky_phys.h, shaders/sky_physical.glsl).
// The first half needs no GPU: the air, the sun light's factor, the quantisation and the keys that decide when the environment is baked
// again are plain arithmetic, so they are checked on the CPU. The second half draws: the tables are built when they should be (and only
// then), a bake of the environment follows the sun in slices, the pictures (noon, sunset, overcast, a metal sphere) match their goldens.
#include "test_util.h"

#include <algorithm>
#include <cctype>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iterator>
#include <limits>
#include <string>
#include <vector>

#include "physical_sky.h"
#include "renderer_env.h"  // kEnvPasses, kEnvSlices
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;
using namespace fa::render;

namespace {

PhysicalSkyState state_with(float sx, float sy, float sz) {
    PhysicalSkyState st;
    st.sunDir[0] = sx;
    st.sunDir[1] = sy;
    st.sunDir[2] = sz;
    return st;
}

}  // namespace

TEST_CASE("physical sky: the air is the physics of molecules and aerosols, the same on every call") {
    const SkyAir a = sky_air(2.0), b = sky_air(2.0);
    CHECK(std::memcmp(&a, &b, sizeof(a)) == 0);  // no clock, no random: bit for bit
    // Rayleigh scattering per kilometre at 680, 550 and 440 nm: about 5.8e-3, 1.35e-2 and 3.3e-2 (the blue sky).
    CHECK(a.rayleigh[0] == doctest::Approx(5.8e-3).epsilon(0.2));
    CHECK(a.rayleigh[1] == doctest::Approx(1.35e-2).epsilon(0.2));
    CHECK(a.rayleigh[2] == doctest::Approx(3.3e-2).epsilon(0.2));
    CHECK(a.rayleigh[0] < a.rayleigh[1]);
    CHECK(a.rayleigh[1] < a.rayleigh[2]);
    // Aerosols: the optical depth of the zenith is 0.02 * turbidity^1.5, the more haze the more of it.
    CHECK((a.mieScatter + a.mieAbsorb) * kSkyMieScaleKm == doctest::Approx(0.02 * std::pow(2.0, 1.5)));
    CHECK(a.mieScatter > a.mieAbsorb);
    CHECK(sky_air(10.0).mieScatter > sky_air(1.0).mieScatter * 10.0);
    // Ozone takes green out of the beam more than red and blue.
    CHECK(a.ozone[1] > a.ozone[0]);
    CHECK(a.ozone[1] > a.ozone[2]);
    // A turbidity outside its range is clamped, not extrapolated.
    CHECK(sky_air(100.0).mieScatter == sky_air(10.0).mieScatter);
    CHECK(sky_air(-5.0).mieScatter == sky_air(1.0).mieScatter);
}

TEST_CASE("physical sky: the optical depth grows towards the horizon and the sun's light keeps its energy sanity") {
    const SkyAir air = sky_air(2.0);
    double zen[3], mid[3], low[3];
    sky_optical_depth(air, kSkyObserverKm, 1.0, zen);
    sky_optical_depth(air, kSkyObserverKm, 0.3, mid);
    sky_optical_depth(air, kSkyObserverKm, 0.02, low);
    for (int c = 0; c < 3; ++c) {
        CAPTURE(c);
        CHECK(zen[c] > 0.0);
        CHECK(mid[c] > zen[c]);
        CHECK(low[c] > mid[c]);
        // The air mass at the horizon is about 38 times the zenith's.
        CHECK(low[c] / zen[c] > 12.0);
        CHECK(low[c] / zen[c] < 60.0);
    }
    CHECK(zen[2] > zen[0]);  // blue light is scattered out first
    // The transmittance relative to a sun overhead: 1 there, never above 1, rising with the sun, red before blue at a low sun,
    // nothing when the planet hides the sun.
    double t[3];
    sky_sun_transmittance(air, 1.0, t);
    for (int c = 0; c < 3; ++c) CHECK(t[c] == doctest::Approx(1.0));
    double prev[3] = {0.0, 0.0, 0.0};
    for (double mu = 0.02; mu <= 1.0001; mu += 0.02) {
        sky_sun_transmittance(air, mu, t);
        for (int c = 0; c < 3; ++c) {
            CAPTURE(mu);
            CHECK(t[c] >= 0.0);
            CHECK(t[c] <= 1.0 + 1e-9);
            CHECK(t[c] >= prev[c] - 1e-12);
            prev[c] = t[c];
        }
    }
    sky_sun_transmittance(air, 0.06, t);
    CHECK(t[0] > t[2]);
    CHECK(t[0] > t[2] * 2.0);
    sky_sun_transmittance(air, -0.2, t);
    for (int c = 0; c < 3; ++c) CHECK(t[c] == 0.0);
    // The visibility of the sun fades over its own width at the horizon of an observer at 10 m.
    CHECK(sky_sun_visibility(kSkyObserverKm, 0.5) == 1.0);
    CHECK(sky_sun_visibility(kSkyObserverKm, -0.5) == 0.0);
    const double mid_v =
        sky_sun_visibility(kSkyObserverKm, -std::sqrt(kSkyObserverKm * (2 * kSkyPlanetKm + kSkyObserverKm)) /
                                               (kSkyPlanetKm + kSkyObserverKm));
    CHECK(mid_v == doctest::Approx(0.5));
}

TEST_CASE("physical sky: clouds take part of the sun's light, more with more coverage and density") {
    PhysicalSkySettings clear;
    clear.coverage = 0.0f;
    CHECK(sky_cloud_sun_factor(clear) == 1.0);
    PhysicalSkySettings s;
    s.density = 0.8f;
    double prev = 1.0;
    for (float cov : {0.1f, 0.3f, 0.6f, 1.0f}) {
        s.coverage = cov;
        const double f = sky_cloud_sun_factor(s);
        CHECK(f < prev);
        CHECK(f >= 0.08);
        prev = f;
    }
    s.coverage = 1.0f;
    s.density = 0.0f;
    CHECK(sky_cloud_sun_factor(s) == 1.0);  // no density: no cloud
    // The factor of the light: air and clouds together, per channel, below the clear factor.
    PhysicalSkySettings clouds;
    clouds.coverage = 0.9f;
    clouds.density = 0.9f;
    float lo[3], hi[3];
    sky_sun_light_factor(clouds, 0.3f, lo);
    clouds.coverage = 0.0f;
    sky_sun_light_factor(clouds, 0.3f, hi);
    for (int c = 0; c < 3; ++c) {
        CHECK(lo[c] < hi[c]);
        CHECK(hi[c] > 0.0f);
        CHECK(hi[c] <= 1.0f);
    }
}

TEST_CASE("physical sky: the settings are clamped to their ranges and a NaN gives the default") {
    SceneSettings ss;
    ss.skySunSize = std::numeric_limits<float>::quiet_NaN();
    ss.skyTurbidity = 1000.0f;
    ss.skyExposure = -3.0f;
    ss.cloudCoverage = 7.0f;
    ss.cloudDensity = std::numeric_limits<float>::infinity();
    ss.cloudAltitude = 5.0f;
    ss.cloudWind = Vec2{1.0e9f, -1.0e9f};
    const PhysicalSkySettings s = physical_sky_settings(ss);
    CHECK(s.sunSizeDeg == doctest::Approx(0.53f));
    CHECK(s.turbidity == 10.0f);
    CHECK(s.exposure == 0.0f);
    CHECK(s.coverage == 1.0f);
    CHECK(std::isfinite(s.density));
    CHECK(s.altitudeM == 300.0f);
    CHECK(s.windX == 1000.0f);
    CHECK(s.windZ == -1000.0f);
}

TEST_CASE("physical sky: the environment's state is quantised, so a frame rate does not change what is baked") {
    PhysicalSkyState st = state_with(100.0f / 256.0f, 208.0f / 256.0f, 112.0f / 256.0f);
    st.s.coverage = 0.4f;
    st.s.density = 0.5f;
    st.time = 123.456;
    const PhysicalSkyState q = sky_quantised(st);
    const float len = std::sqrt(q.sunDir[0] * q.sunDir[0] + q.sunDir[1] * q.sunDir[1] + q.sunDir[2] * q.sunDir[2]);
    CHECK(len == doctest::Approx(1.0f));
    CHECK(std::fmod(q.time, kSkyCloudStep) == 0.0);
    CHECK(q.time <= st.time);
    CHECK(q.time > st.time - kSkyCloudStep);
    // A sun and a clock that moved less than half a step are the same environment...
    PhysicalSkyState near = st;
    near.sunDir[0] += 0.001f;
    near.sunDir[1] -= 0.001f;
    near.time = st.time + 0.5;
    if (std::floor(near.time / kSkyCloudStep) == std::floor(st.time / kSkyCloudStep))
        CHECK(sky_env_key(sky_quantised(near)) == sky_env_key(q));
    // ...a sun a degree away, another one.
    PhysicalSkyState far = st;
    far.sunDir[0] += 0.02f;
    CHECK(sky_env_key(sky_quantised(far)) != sky_env_key(q));
    // Quantising twice changes nothing.
    const PhysicalSkyState qq = sky_quantised(q);
    CHECK(sky_env_key(qq) == sky_env_key(q));
    // An animated sun colour or exposure moves in steps: a change of a thousandth is the same static key (no whole bake per frame).
    PhysicalSkyState tint = st;
    tint.sunColor[0] += 0.001f;
    tint.s.exposure += 0.001f;
    CHECK(sky_env_static_key(sky_quantised(tint)) == sky_env_static_key(q));
    tint.sunColor[0] += 0.05f;
    CHECK(sky_env_static_key(sky_quantised(tint)) != sky_env_static_key(q));
    // A still sky keeps the clock at 0: its environment never depends on the time.
    PhysicalSkyState still = st;
    still.s.windX = still.s.windZ = 0.0f;
    still.time = 500.0;
    CHECK(sky_quantised(still).time == 0.0);
    PhysicalSkyState clear = st;
    clear.s.coverage = 0.0f;
    clear.time = 500.0;
    CHECK(sky_quantised(clear).time == 0.0);
    // A direction that rounds to nothing is straight up, a NaN time is 0.
    PhysicalSkyState zero = state_with(0.0f, 0.0f, 0.0f);
    zero.time = std::numeric_limits<double>::quiet_NaN();
    const PhysicalSkyState qz = sky_quantised(zero);
    CHECK(qz.sunDir[1] == 1.0f);
    CHECK(qz.time == 0.0);
}

TEST_CASE("physical sky: the keys say what each table and the environment depend on") {
    PhysicalSkyState base = state_with(0.2f, 0.9f, 0.3f);
    // The air tables: the air and the ground only.
    PhysicalSkySettings s = base.s;
    const std::uint64_t air = sky_air_key(s);
    PhysicalSkySettings s2 = s;
    s2.exposure = 3.0f;
    s2.coverage = 0.9f;
    CHECK(sky_air_key(s2) == air);
    s2 = s;
    s2.turbidity += 1.0f;
    CHECK(sky_air_key(s2) != air);
    s2 = s;
    s2.groundAlbedo[2] = 0.9f;
    CHECK(sky_air_key(s2) != air);
    // The sky view: also the sun's height (and not its azimuth: the table is drawn relative to the sun).
    CHECK(sky_view_key(s, 0.5f) == sky_view_key(s, 0.5f));
    CHECK(sky_view_key(s, 0.5f) != sky_view_key(s, 0.6f));
    // The static key of the environment: everything but the sun's direction and the clock.
    const std::uint64_t st0 = sky_env_static_key(base);
    PhysicalSkyState b2 = base;
    b2.sunDir[0] = -0.5f;
    b2.time = 77.0;
    CHECK(sky_env_static_key(b2) == st0);
    b2 = base;
    b2.s.exposure = 2.0f;
    CHECK(sky_env_static_key(b2) != st0);
    b2 = base;
    b2.s.coverage = 0.9f;
    CHECK(sky_env_static_key(b2) != st0);
    b2 = base;
    b2.s.altitudeM = 4000.0f;
    CHECK(sky_env_static_key(b2) != st0);
    b2 = base;
    b2.sunColor[1] = 0.5f;
    CHECK(sky_env_static_key(b2) != st0);
    b2 = base;
    b2.linear = false;
    CHECK(sky_env_static_key(b2) != st0);
    // The full key follows the sun and the clock too.
    PhysicalSkyState q0 = sky_quantised(base), q1 = sky_quantised(base);
    q1.sunDir[2] += 0.1f;
    CHECK(sky_env_key(q0) != sky_env_key(q1));
}

TEST_CASE("physical sky: the shader's numbers: the wind drifts the clouds with the clock and wraps, never wall time") {
    PhysicalSkyState st = state_with(0.0f, 1.0f, 0.0f);
    st.s.windX = 10.0f;
    st.s.windZ = 0.0f;
    st.sunColor[0] = st.sunColor[1] = st.sunColor[2] = 2.0f;
    st.s.exposure = 1.5f;
    const SkyShaderParams a = sky_shader_params(st, true), again = sky_shader_params(st, true);
    CHECK(std::memcmp(&a, &again, sizeof(a)) == 0);
    CHECK(a.v[1][0] == doctest::Approx(3.0f));  // colour * exposure
    CHECK(a.v[4][3] == 1.0f);                   // the disc
    CHECK(sky_shader_params(st, false).v[4][3] == 0.0f);
    CHECK(a.v[3][3] == 1.0f);  // clouds on
    st.time = 100.0;
    const SkyShaderParams later = sky_shader_params(st, true);
    CHECK(later.v[4][0] != a.v[4][0]);
    CHECK(later.v[4][0] >= 0.0f);
    CHECK(later.v[4][0] < float(kSkyCloudPeriod));
    st.time = 1.0e9;  // a very long game keeps the offset in range
    const SkyShaderParams old = sky_shader_params(st, true);
    CHECK(old.v[4][0] >= 0.0f);
    CHECK(old.v[4][0] < float(kSkyCloudPeriod));
    st.s.coverage = 0.0f;
    CHECK(sky_shader_params(st, true).v[3][3] == 0.0f);
}

// ---- the GPU half ----

namespace {

struct SkyScene {
    World w;
    Entity sun;
    Entity cam;
    SkyScene(float sunElevationDeg, float sunYawDeg = 180.0f, float camElevationDeg = 20.0f, float camYawDeg = 0.0f) {
        cam = make(w, "cam", {0, 1.5f, 0});
        auto& c = w.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 60;
        w.get<Transform>(cam)->rotation = {camElevationDeg, camYawDeg, 0};
        sun = make(w, "sun", {0, 5, 0});
        auto& l = w.add<Light>(sun);
        l.type = LightType::Directional;
        l.intensity = 1.0f;
        l.castShadows = false;
        set_sun(sunElevationDeg, sunYawDeg);
        w.settings().skyModel = SkyModel::Physical;
        w.settings().ambientLight = Color{0, 0, 0, 1};
    }
    // The light shines down and away: the sun is at `elevation` above the horizon, on the side `yaw` looks to (180 = -Z).
    void set_sun(float elevationDeg, float yawDeg = 180.0f) {
        w.get<Transform>(sun)->rotation = {-elevationDeg, yawDeg, 0};
    }
    Entity mesh(const char* name, Vec3 pos, Color c, Vec3 scale = {1, 1, 1}) {
        Entity e = make(w, name, pos);
        w.get<Transform>(e)->scale = scale;
        auto& m = w.add<MeshRenderer>(e);
        m.mesh = name;
        m.color = c;
        return e;
    }
};

bool physical_sky_supported(Gfx& g) { return g.renderer.supports("physicalSky"); }

}  // namespace

TEST_CASE("physical sky: the tables are drawn when the air or the sun's height changes, and only then") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!physical_sky_supported(g)) {
        MESSAGE("physicalSky is not supported on this GPU: not run");
        return;
    }
    SkyScene s(40.0f);
    s.mesh("sphere", {0, 0.5f, -4}, Color::white());
    g.render(s.w);
    g.render(s.w);
    const SkyBuilds base = renderer_sky_builds(g.renderer);
    g.render(s.w);
    SkyBuilds now = renderer_sky_builds(g.renderer);
    CHECK(now.air == base.air);  // nothing changed: nothing drawn
    CHECK(now.view == base.view);
    CHECK(now.envView == base.envView);
    s.w.settings().skyTurbidity = 5.0f;
    g.render(s.w);
    now = renderer_sky_builds(g.renderer);
    CHECK(now.air == base.air + 1);     // the air changed: its two tables are drawn again
    CHECK(now.view == base.view + 1);   // and the views, which were made from the old air
    s.w.settings().skyExposure = 2.0f;  // the colour is applied when the sky is drawn: no table depends on it
    s.w.settings().cloudCoverage = 0.7f;
    g.render(s.w);
    const SkyBuilds after = renderer_sky_builds(g.renderer);
    CHECK(after.air == now.air);
    CHECK(after.view == now.view);
    s.set_sun(41.0f);  // the sun's height changed: the picture's view is drawn again
    g.render(s.w);
    const SkyBuilds moved = renderer_sky_builds(g.renderer);
    CHECK(moved.air == after.air);
    CHECK(moved.view == after.view + 1);
    s.set_sun(41.0f, 150.0f);  // the azimuth alone: the view is relative to the sun, no new table
    g.render(s.w);
    CHECK(renderer_sky_builds(g.renderer).view == moved.view);
}

TEST_CASE("physical sky: the environment is baked whole on a big change and follows a moving sun in slices") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!physical_sky_supported(g)) {
        MESSAGE("physicalSky is not supported on this GPU: not run");
        return;
    }
    SkyScene s(40.0f);
    s.mesh("sphere", {0, 0.5f, -4}, Color::white());
    s.w.settings().cloudCoverage = 0.0f;  // a still sky: the clock does not matter
    auto calls = [&]() { return g.renderer.stats().drawCalls; };
    g.render(s.w);
    g.render(s.w);
    g.render(s.w);
    const int idle = calls();
    g.render(s.w);
    CHECK(calls() == idle);  // a sky that did not change is not baked again, nor drawn into a table
    s.w.advance_clock(100.0);
    g.render(s.w);
    CHECK(calls() == idle);  // a still sky never reads the clock

    // A sun that moves a few hundredths of a degree is below the quantisation: the picture's table is drawn, the environment is not.
    s.set_sun(40.01f);
    g.render(s.w);
    CHECK(calls() == idle + 1);

    // A sun that moves a degree or more: a whole bake in one frame (the picture's view, the environment's, the 60 passes).
    s.set_sun(46.0f);
    g.render(s.w);
    CHECK(calls() == idle + 2 + kEnvPasses);
    g.render(s.w);
    CHECK(calls() == idle);

    // A sun that moves half a degree: the same bake in kEnvSlices frames, a share of the passes in each, then nothing again.
    s.set_sun(46.5f);
    int extra[kEnvSlices + 1];
    for (int i = 0; i < kEnvSlices + 1; ++i) {
        g.render(s.w);
        extra[i] = calls() - idle;
    }
    CHECK(extra[0] >= 2);
    int total = extra[0] - 2;  // the first frame also draws the two sky views
    for (int i = 1; i < kEnvSlices; ++i) {
        CHECK(extra[i] > 0);
        CHECK(extra[i] < kEnvPasses);
        total += extra[i];
    }
    CHECK(total == kEnvPasses);
    CHECK(extra[0] < kEnvPasses);  // the first frame is a share of the work, not all of it
    CHECK(extra[kEnvSlices] == 0);
    g.render(s.w);
    CHECK(calls() == idle);

    // Another colour of the sun, a new exposure: whole bakes, in one frame.
    s.w.settings().skyExposure = 1.7f;
    g.render(s.w);
    CHECK(calls() == idle + kEnvPasses);
    s.w.get<Light>(s.sun)->color = Color{1.0f, 0.8f, 0.6f, 1.0f};
    g.render(s.w);
    CHECK(calls() == idle + kEnvPasses);
}

TEST_CASE(
    "physical sky: drifting clouds bake the environment again every kSkyCloudStep of game time, not at every frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!physical_sky_supported(g)) {
        MESSAGE("physicalSky is not supported on this GPU: not run");
        return;
    }
    SkyScene s(40.0f);
    s.mesh("sphere", {0, 0.5f, -4}, Color::white());
    s.w.settings().cloudCoverage = 0.5f;
    s.w.settings().cloudDensity = 0.6f;
    s.w.settings().cloudWind = Vec2{8.0f, 3.0f};
    auto calls = [&]() { return g.renderer.stats().drawCalls; };
    g.render(s.w);
    g.render(s.w);
    g.render(s.w);
    const int idle = calls();
    // 0.25 s of game time per frame: the environment changes every second frame at most... a step is two seconds.
    int bakes = 0;
    for (int i = 0; i < 40; ++i) {  // ten seconds
        s.w.advance_clock(0.25);
        g.render(s.w);
        if (calls() > idle + 5) ++bakes;  // a bake or a slice of one
    }
    CHECK(bakes >= 1 + 4);               // at least a sequence per two seconds...
    CHECK(bakes <= 5 * kEnvSlices + 2);  // ...and no more than one per step
    // The same game time in smaller frames asks for the same number of sequences: not more.
    SkyScene t(40.0f);
    t.mesh("sphere", {0, 0.5f, -4}, Color::white());
    t.w.settings().cloudCoverage = 0.5f;
    t.w.settings().cloudDensity = 0.6f;
    t.w.settings().cloudWind = Vec2{8.0f, 3.0f};
    g.render(t.w);
    g.render(t.w);
    g.render(t.w);
    const int idle2 = calls();
    int bakes2 = 0;
    for (int i = 0; i < 100; ++i) {  // ten seconds in frames of 0.1 s
        t.w.advance_clock(0.1);
        g.render(t.w);
        if (calls() > idle2 + 5) ++bakes2;
    }
    CHECK(bakes2 <= 5 * kEnvSlices + 2);
}

TEST_CASE("physical sky: the sky model falls back to the gradient where the sky is a material, and back") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!physical_sky_supported(g)) {
        MESSAGE("physicalSky is not supported on this GPU: not run");
        return;
    }
    SkyScene gradient(40.0f);
    gradient.w.settings().skyModel = SkyModel::Gradient;
    const Image grad = g.render(gradient.w);
    SkyScene phys(40.0f);
    const Image sky = g.render(phys.w);
    // The two skies are different pictures (the physical one is blue overhead and pale at the horizon, the gradient is the scene's colours).
    CHECK(diff_images(grad, sky, 4.0f / 255.0f).meanError > 0.02);
    // The gradient again, pixel for pixel what it was: the physical sky leaves nothing behind.
    const Image grad2 = g.render(gradient.w);
    CHECK(diff_images(grad, grad2, 1.0f / 255.0f).meanError < 0.0005);
}

TEST_CASE(
    "physical sky: every float of the GLES3 and WebGL2 fragment sources is highp (a mobile GPU's mediump is fp16)") {
    // sokol-shdc writes `precision mediump float;` as the default of a GLSL ES 3.00 fragment shader and qualifies every declaration
    // (variables, parameters, uniforms, samplers, inputs, outputs) with highp. The atmosphere (6360 km squared overflows fp16) needs that
    // on a phone. The generated header only holds the GLES3 sources when it is built for GLES3, so this reads its text (the sources are
    // arrays of hex bytes) and scans the fragment shader of each of the four programs for a declaration without highp.
    std::ifstream in(std::string(FA_REPO_ROOT) + "/engine/render/src/shaders/sky_physical.glsl.h", std::ios::binary);
    REQUIRE(in.good());
    const std::string header((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    int found = 0;
    for (const char* name : {"transmittance", "multiscatter", "skyview", "sky"}) {
        const std::string key = std::string("skyphys_fs_") + name + "_source_glsl300es[";
        const std::size_t at = header.find(key);
        CAPTURE(key);
        REQUIRE(at != std::string::npos);
        const std::size_t open = header.find('{', at), close = header.find('}', open);
        REQUIRE(close != std::string::npos);
        std::string src;
        for (std::size_t i = header.find("0x", open); i != std::string::npos && i < close; i = header.find("0x", i + 2))
            src.push_back(char(std::strtoul(header.substr(i + 2, 2).c_str(), nullptr, 16)));
        CHECK(src.find("precision mediump float;") !=
              std::string::npos);  // the default is what it is: the declarations decide
        CHECK(src.find("highp") != std::string::npos);
        const std::vector<std::string> bad = unqualified_floats(src);
        for (const std::string& l : bad) MESSAGE("not highp: " << l);
        CHECK(bad.empty());
        ++found;
    }
    CHECK(found == 4);
}

namespace {

// A renderer of its own (the physical sky's GPU objects are made per renderer): the test hook makes its tables fail.
struct SkyOwnRenderer {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    explicit SkyOwnRenderer(Gfx& gx) : g(gx) {
        RendererDesc d;
        d.designWidth = 320;
        d.designHeight = 180;
        d.sampleCount = 1;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
    }
    ~SkyOwnRenderer() { r.shutdown(); }
    SkyOwnRenderer(const SkyOwnRenderer&) = delete;
    SkyOwnRenderer& operator=(const SkyOwnRenderer&) = delete;
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

TEST_CASE("physical sky: where the tables cannot be made the gradient is drawn and the sun light is not tinted") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    EnvGuard hook("FA_PHYSICAL_SKY", "invalid");  // the tables fail on a GPU that never would
    SkyOwnRenderer own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    // A sun at the horizon: tinted it would be orange and dark, and a lit cube would show it.
    auto build = [](SkyScene& s, SkyModel model) {
        s.w.settings().skyModel = model;
        s.w.settings().ambientLight = Color{0.05f, 0.05f, 0.05f, 1};
        s.mesh("plane", {0, 0, -6}, Color{0.5f, 0.5f, 0.5f, 1}, {40, 1, 40});
        s.mesh("cube", {0, 1.0f, -6}, Color::white(), {2, 2, 2});
    };
    SkyScene physical(8.0f, 180.0f, 5.0f), gradient(8.0f, 180.0f, 5.0f);
    build(physical, SkyModel::Physical);
    build(gradient, SkyModel::Gradient);
    const Image a = own.draw(physical.w);
    const Image b = own.draw(gradient.w);
    CHECK(diff_images(a, b, 1.0f / 255.0f).meanError < 0.0005);
}

TEST_CASE("physical sky: without a directional light there is no sun disc at the zenith") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!physical_sky_supported(g)) {
        MESSAGE("physicalSky is not supported on this GPU: not run");
        return;
    }
    // The camera looks straight up. With a sun standing overhead the middle of the picture is its (white) disc; without a light the
    // sky keeps its glow there.
    // The disc is under two pixels wide (0.53 degrees at 180 px for 60 degrees): the brightest of the 3 x 3 pixels round the middle is
    // measured, so where on the pixel grid the disc falls does not matter.
    auto brightest_r = [](const Image& img) {
        float best = 0.0f;
        for (int dy = -1; dy <= 1; ++dy)
            for (int dx = -1; dx <= 1; ++dx)
                best = std::max(best, img.pixel(img.width / 2 + dx, img.height / 2 + dy).r);
        return best;
    };
    SkyScene withSun(90.0f, 180.0f, 90.0f);
    withSun.w.settings().cloudCoverage = 0.0f;
    const float disc = brightest_r(g.render(withSun.w));
    CHECK(disc > 0.95f);
    SkyScene none(90.0f, 180.0f, 90.0f);
    none.w.settings().cloudCoverage = 0.0f;
    none.w.remove<Light>(none.sun);
    const float zenith = brightest_r(g.render(none.w));
    // The air's own glow round the sun's direction is left (a pale sky), the disc is not: it is clearly darker than the disc.
    CHECK(zenith < disc - 0.1f);
    // A point light is no sun: only a directional light makes the disc, so the same light as a point light leaves the sky as it is without one.
    SkyScene point(90.0f, 180.0f, 90.0f);
    point.w.settings().cloudCoverage = 0.0f;
    point.w.get<Light>(point.sun)->type = LightType::Point;
    const float lamp = brightest_r(g.render(point.w));
    CHECK(lamp < disc - 0.1f);
    CHECK(std::abs(lamp - zenith) < 0.02f);
}

TEST_CASE("physical sky: the pictures: noon, sunset, overcast and a metal sphere that reflects the sky") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!physical_sky_supported(g)) {
        MESSAGE("physicalSky is not supported on this GPU: not run");
        return;
    }
    // The goldens: one picture serves every backend, so the limits are wide enough for the differences of the half-float tables and of
    // the filtering, and the checks below hold on any of them.
    GoldenLimits wide = golden_limits(0.008);
    wide.maxDifferingShare = 0.2;
    {  // Noon: a high sun in front of the camera, at the top of the picture, clear sky, a grey floor.
        SkyScene s(55.0f, 180.0f, 28.0f);
        s.w.settings().cloudCoverage = 0.0f;
        s.mesh("plane", {0, 0, -6}, Color{0.5f, 0.5f, 0.5f, 1}, {40, 1, 40});
        s.mesh("cube", {0, 1.0f, -6}, Color::hex(0xc08040), {2, 2, 2});
        const Image img = g.render(s.w);
        expect_golden(img, "3d_physical_sky_noon", wide);
        const Color high = img.pixel(30, 8), low = img.pixel(30, img.height - 30);
        CHECK(high.b > high.r + 0.05f);                           // a blue sky...
        CHECK(low.r + low.g + low.b > high.r + high.g + high.b);  // ...paler (lighter) towards the horizon
        CHECK(low.r > high.r);
    }
    {  // Sunset: the sun a few degrees above the horizon in front of the camera; the sky is warm and the light red.
        SkyScene s(4.0f, 180.0f, 6.0f);
        s.w.settings().cloudCoverage = 0.0f;
        s.mesh("plane", {0, 0, -6}, Color{0.5f, 0.5f, 0.5f, 1}, {40, 1, 40});
        s.mesh("cube", {2.5f, 1.0f, -6}, Color::hex(0xc08040), {2, 2, 2});
        const Image img = g.render(s.w);
        expect_golden(img, "3d_physical_sky_sunset", wide);
        // The sun disc is the brightest thing of the picture and the light that lit the cube is not white (the air took the blue away).
        float best = 0.0f;
        for (int y = 0; y < img.height; ++y)
            for (int x = 0; x < img.width; ++x) {
                const Color c = img.pixel(x, y);
                best = std::max(best, c.r + c.g + c.b);
            }
        CHECK(best > 2.0f);
        const Color glow = img.pixel(img.width / 2, img.height / 2 - 6);
        CHECK(glow.r > glow.b);
    }
    {  // Overcast: clouds cover most of the sky and the sun's light, the picture is grey and nothing is bright.
        SkyScene s(50.0f, 180.0f, 30.0f);
        s.w.settings().cloudCoverage = 0.95f;
        s.w.settings().cloudDensity = 0.9f;
        s.mesh("plane", {0, 0, -6}, Color{0.5f, 0.5f, 0.5f, 1}, {40, 1, 40});
        s.mesh("cube", {0, 1.0f, -6}, Color::hex(0xc08040), {2, 2, 2});
        const Image img = g.render(s.w);
        expect_golden(img, "3d_physical_sky_overcast", wide);
        SkyScene clear(50.0f, 180.0f, 30.0f);
        clear.w.settings().cloudCoverage = 0.0f;
        clear.mesh("plane", {0, 0, -6}, Color{0.5f, 0.5f, 0.5f, 1}, {40, 1, 40});
        clear.mesh("cube", {0, 1.0f, -6}, Color::hex(0xc08040), {2, 2, 2});
        const Image blue = g.render(clear.w);
        auto top_blue_share = [](const Image& i) {  // how blue the top of the picture is, 0..1 (blue minus red)
            double sum = 0.0;
            int n = 0;
            for (int y = 0; y < i.height / 4; ++y)
                for (int x = 0; x < i.width; ++x, ++n) {
                    const Color c = i.pixel(x, y);
                    sum += c.b - c.r;
                }
            return sum / n;
        };
        CHECK(top_blue_share(img) < top_blue_share(blue));
    }
    {  // A metal sphere with the sky alone around it: it shows the sky (the environment is baked from the same sky).
        SkyScene s(35.0f, 90.0f, 10.0f);  // the sun to the right of the picture
        s.w.settings().cloudCoverage = 0.3f;
        s.w.settings().cloudDensity = 0.7f;
        Entity sphere = s.mesh("sphere", {0, 1.5f, -4}, Color::white(), {2.4f, 2.4f, 2.4f});
        s.w.get<MeshRenderer>(sphere)->metallic = 1.0f;
        s.w.get<MeshRenderer>(sphere)->roughness = 0.05f;
        const Image img = g.render(s.w);
        expect_golden(img, "3d_physical_sky_metal_sphere", wide);
        // The upper half of the sphere reflects the blue sky, the lower half the ground: they differ.
        const int cx = img.width / 2, cy = img.height / 2;
        const Color up = img.pixel(cx, cy - 25), down = img.pixel(cx, cy + 25);
        CHECK(up.b > up.r);
        CHECK(std::fabs(up.b - down.b) + std::fabs(up.r - down.r) > 0.02f);
    }
}

TEST_CASE("physical sky: the clouds drift with the engine's clock and the same clock draws the same picture") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!physical_sky_supported(g)) {
        MESSAGE("physicalSky is not supported on this GPU: not run");
        return;
    }
    auto make_scene = [](SkyScene& s) {
        s.w.settings().cloudCoverage = 0.5f;
        s.w.settings().cloudDensity = 0.7f;
        s.w.settings().cloudWind = Vec2{40.0f, 0.0f};
    };
    SkyScene a(50.0f, 180.0f, 40.0f), b(50.0f, 180.0f, 40.0f);
    make_scene(a);
    make_scene(b);
    const Image a0 = g.render(a.w);
    a.w.advance_clock(30.0);
    const Image a1 = g.render(a.w);
    CHECK(diff_images(a0, a1, 3.0f / 255.0f).meanError > 0.002);  // the wind moved the clouds
    b.w.advance_clock(30.0);
    const Image b1 = g.render(b.w);
    CHECK(diff_images(a1, b1, 1.0f / 255.0f).meanError <
          0.0005);  // the same clock, the same picture, however it got there
}

TEST_CASE("physical sky: what the tables and a bake cost (reported, never asserted)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!physical_sky_supported(g)) {
        MESSAGE("physicalSky is not supported on this GPU: not run");
        return;
    }
    // Wall time of a whole frame including the read-back (so the GPU work is in it), median of 15 frames, in four situations: the
    // sky unchanged, the air changing every frame (the two tables and the views), the sun moving in slices, a whole bake each frame.
    auto median_ms = [&](int mode) {
        SkyScene s(40.0f);
        s.mesh("sphere", {0, 0.5f, -4}, Color::white());
        s.w.settings().cloudCoverage = 0.0f;
        g.render(s.w);
        g.render(s.w);
        std::vector<double> ms;
        for (int f = 0; f < 15; ++f) {
            if (mode == 1) s.w.settings().skyTurbidity = 2.0f + 0.1f * float(f + 1);
            if (mode == 2) s.set_sun(40.0f + 0.5f * float(f + 1));
            if (mode == 3) s.w.settings().skyExposure = 1.0f + 0.05f * float(f + 1);
            const auto t0 = std::chrono::steady_clock::now();
            g.render(s.w);
            ms.push_back(std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count());
        }
        std::sort(ms.begin(), ms.end());
        return ms[ms.size() / 2];
    };
    const double idle = median_ms(0), air = median_ms(1), slices = median_ms(2), whole = median_ms(3);
    char line[400];
    std::snprintf(line, sizeof line,
                  "physical sky, frame wall time: unchanged %.2f ms, tables of the air redrawn every frame %.2f ms, a "
                  "sun that moves "
                  "half a degree a frame (sliced bake) %.2f ms, a whole bake every frame %.2f ms",
                  idle, air, slices, whole);
    MESSAGE(line);
}
