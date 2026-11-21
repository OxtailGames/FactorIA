// M73.5: the CPU side of the screen-space subsurface scattering (subsurface.h): the profile, the weights of the taps, the pixel radius and the plan of
// a camera. No GPU. The passes are tested in subsurface_render_tests.cpp.
#include "test_util.h"

#include <cmath>
#include <limits>

#include "fa/scene/camera_geometry.h"

#include "mesh_batch.h"
#include "render_scene.h"
#include "subsurface.h"

using namespace fa;
using namespace fa::render;
using namespace fa::test;

TEST_CASE("subsurface profile: the four Gaussians integrate to 1 and follow the diffusion profile it was fitted to") {
    // The 1D kernel integrates to 1 (the weights add up to 1, each Gaussian is normalized): a Riemann sum over +-6 sigma of the widest.
    double sum = 0.0;
    const double step = 0.0005;
    for (double x = -5.0; x <= 5.0; x += step) sum += double(sss_kernel(float(x))) * step;
    CHECK(sum == doctest::Approx(1.0).epsilon(0.002));
    float wsum = 0.0f;
    for (const SssGaussian& g : kSssGauss) wsum += g.weight;
    CHECK(wsum == doctest::Approx(1.0f).epsilon(1e-4));
    // The kernel is the line integral of the 2D profile: its cumulative mass inside +-r is near the profile's share of light inside the distance r.
    // The 2D profile holds 90% of its light inside r = 1 (the unit of the radius), and 2 pi R(r) r integrates to its cdf.
    CHECK(sss_profile_cdf(1.0f) == doctest::Approx(0.9f).epsilon(0.002));
    double mass = 0.0;
    for (double r = 1e-5; r < 1.0; r += 1e-4)
        mass += 2.0 * 3.14159265358979 * double(sss_profile_2d(float(r))) * r * 1e-4;
    CHECK(mass == doctest::Approx(0.9).epsilon(0.01));
    // The fit: the kernel's mass inside +-1 is near the 2D profile's inside the unit disc along one axis, a loose bound (a 1D marginal is wider than a
    // disc of the same radius): both hold most of the light there.
    double inside = 0.0;
    for (double x = -1.0; x <= 1.0; x += step) inside += double(sss_kernel(float(x))) * step;
    CHECK(inside > 0.85);
    CHECK(inside < 0.99);
    // The kernel is even, positive and falls off.
    CHECK(sss_kernel(0.3f) == doctest::Approx(sss_kernel(-0.3f)));
    CHECK(sss_kernel(0.0f) > sss_kernel(0.2f));
    CHECK(sss_kernel(0.2f) > sss_kernel(0.8f));
    CHECK(sss_kernel(3.0f) > 0.0f);
}

TEST_CASE("subsurface profile: the weights of the taps add up to 1 for every colour radius and lose almost nothing") {
    for (float ratio : {1.0f, 0.5f, 0.2f, 0.05f, 0.02f}) {
        CAPTURE(ratio);
        float w[kSssTaps + 1];
        sss_tap_weights(ratio, w);
        float total = w[0];
        for (int k = 1; k <= kSssTaps; ++k) {
            CHECK(w[k] >= 0.0f);   // the outer taps of a narrow channel can underflow to 0
            total += 2.0f * w[k];  // one tap on each side
        }
        CHECK(total <= 1.0f + 1e-4f);
        CHECK(total > 0.95f);  // the light beyond the last edge (2.2 radii) is lost
        CHECK(w[0] > 0.0f);
    }
    // A narrower colour channel keeps more of its light in the centre tap.
    float wide[kSssTaps + 1], narrow[kSssTaps + 1];
    sss_tap_weights(1.0f, wide);
    sss_tap_weights(0.1f, narrow);
    CHECK(narrow[0] > wide[0]);
    // A ratio that is not finite or outside 0.02 .. 1 is clamped, never a NaN weight.
    float bad[kSssTaps + 1];
    sss_tap_weights(std::numeric_limits<float>::quiet_NaN(), bad);
    for (float v : bad) CHECK(std::isfinite(v));
    sss_tap_weights(-3.0f, bad);
    for (float v : bad) CHECK(std::isfinite(v));
    // The taps lie in order, inside the widest radius times the last edge.
    float prev = 0.0f;
    for (int k = 1; k <= kSssTaps; ++k) {
        const float off = sss_tap_offset(k, 10.0f);
        CHECK(off > prev);
        prev = off;
    }
    CHECK(prev < 10.0f * kSssCell[kSssTaps]);
}

TEST_CASE("subsurface: the radius in pixels follows the depth, is clamped and is 0 for what is not finite") {
    // 500 px per metre at depth 1: a 0.01 m radius is 5 px at 1 m and 2.5 px at 2 m.
    CHECK(sss_radius_px(0.01f, 1.0f, 500.0f, false) == doctest::Approx(5.0f));
    CHECK(sss_radius_px(0.01f, 2.0f, 500.0f, false) == doctest::Approx(2.5f));
    // Orthographic: the pixels per unit do not depend on the depth.
    CHECK(sss_radius_px(0.01f, 7.0f, 500.0f, true) == doctest::Approx(5.0f));
    CHECK(sss_radius_px(0.5f, 0.1f, 500.0f, false) == kSssMaxRadiusPx);
    CHECK(sss_radius_px(0.0f, 1.0f, 500.0f, false) == 0.0f);
    CHECK(sss_radius_px(-1.0f, 1.0f, 500.0f, false) == 0.0f);
    CHECK(sss_radius_px(0.01f, 0.0f, 500.0f, false) == 0.0f);
    CHECK(sss_radius_px(0.01f, -2.0f, 500.0f, false) == 0.0f);
    CHECK(sss_radius_px(0.01f, 1.0f, 0.0f, false) == 0.0f);
    const float nan = std::numeric_limits<float>::quiet_NaN();
    const float inf = std::numeric_limits<float>::infinity();
    CHECK(sss_radius_px(nan, 1.0f, 500.0f, false) == 0.0f);
    CHECK(sss_radius_px(0.01f, nan, 500.0f, false) == 0.0f);
    CHECK(sss_radius_px(0.01f, 1.0f, inf, false) == 0.0f);
}

TEST_CASE(
    "subsurface: the plan of a camera holds the pixels a metre covers at depth 1 and refuses an empty rectangle") {
    CameraGeometry cam;
    cam.perspective = true;
    cam.proj = Mat4::perspective(60.0f, 16.0f / 9.0f, 0.1f, 100.0f, true);
    const SssPlan p = make_sss_plan(cam, 320, 180);
    CHECK(p.on);
    CHECK(!p.ortho);
    CHECK(p.rectW == 320);
    CHECK(p.rectH == 180);
    // focal length in pixels: half the height over tan(fov / 2).
    CHECK(p.focalPx == doctest::Approx(90.0f / std::tan(30.0f * 3.14159265f / 180.0f)).epsilon(0.001));
    // The same camera on a picture twice as tall covers twice the pixels per metre.
    CHECK(make_sss_plan(cam, 640, 360).focalPx == doctest::Approx(2.0f * p.focalPx).epsilon(0.001));
    CHECK(!make_sss_plan(cam, 0, 180).on);
    CHECK(!make_sss_plan(cam, 320, 0).on);
    CameraGeometry broken;
    broken.perspective = true;
    broken.proj = Mat4{};
    broken.proj.at(1, 1) = std::numeric_limits<float>::quiet_NaN();
    CHECK(!make_sss_plan(broken, 320, 180).on);
}

TEST_CASE(
    "subsurface: the values of a mesh that scatters are part of its batch, and a mesh that does not scatter has none") {
    MeshRenderer off;
    CHECK(off.subsurface == 0.0f);
    for (float v : subsurface_of(off)) CHECK(v == 0.0f);
    // The radius and colour of a mesh with strength 0 are unused: they do not split batches.
    MeshRenderer other = off;
    other.subsurfaceRadius = 0.2f;
    other.subsurfaceColor = Color{0.1f, 0.2f, 0.3f, 1.0f};
    CHECK(subsurface_of(off) == subsurface_of(other));
    // A mesh that scatters carries its clamped values.
    MeshRenderer skin;
    skin.subsurface = 0.7f;
    skin.subsurfaceRadius = 0.02f;
    const auto s = subsurface_of(skin);
    CHECK(s[0] == doctest::Approx(0.7f));
    CHECK(s[1] == doctest::Approx(0.02f));
    CHECK(s != subsurface_of(off));
    // Out of range or not finite values are clamped (0 .. 1 strength, 0 .. kSssMaxRadiusM radius), never passed on.
    skin.subsurface = 5.0f;
    skin.subsurfaceRadius = 99.0f;
    const auto big = subsurface_of(skin);
    CHECK(big[0] == 1.0f);
    CHECK(big[1] == kSssMaxRadiusM);
    skin.subsurface = std::numeric_limits<float>::quiet_NaN();
    for (float v : subsurface_of(skin)) CHECK(v == 0.0f);
}

TEST_CASE("subsurface: every float of the GLES3 and WebGL2 sources of the blur and the add is highp (depth and weights "
          "need more than fp16)") {
    // A mobile GPU's mediump is fp16: a depth of 100 m with a tolerance of 1 cm does not fit in it. sokol-shdc writes `precision mediump float;`
    // as the default of a GLSL ES 3.00 fragment shader and qualifies every declaration with highp; this reads the generated header (the GLES3
    // sources are only in it when it is built for GLES3) and scans the fragment shader of each program.
    for (const char* name : {"blur_h", "blur_v", "add"}) {
        const std::string src =
            glsl_source_from_header("subsurface.glsl.h", std::string("subsurface_fs_") + name + "_source_glsl300es[");
        CAPTURE(std::string(name));
        REQUIRE(!src.empty());
        CHECK(src.find("highp") != std::string::npos);
        const std::vector<std::string> bad = unqualified_floats(src);
        for (const std::string& l : bad) MESSAGE("not highp: " << l);
        CHECK(bad.empty());
    }
}

TEST_CASE("transmission and subsurface: unlit, material-lit and blended meshes are left out by the one predicate the "
          "renderer and the cost report use") {
    MeshAsset mesh;
    MeshRenderer glass;
    glass.transmission = 0.8f;
    CHECK(mesh_is_transmissive(glass, mesh, nullptr));
    CHECK(mesh_is_blended(glass, mesh, nullptr));
    // An unlit mesh transmits nothing (fill_fs zeroes it): no copy of the picture, no glass culling, not drawn far to near.
    MeshRenderer unlit = glass;
    unlit.unlit = true;
    CHECK_FALSE(mesh_is_transmissive(unlit, mesh, nullptr));
    CHECK_FALSE(mesh_is_blended(unlit, mesh, nullptr));
    MaterialAsset flat;
    flat.lighting = "unlit";
    CHECK_FALSE(mesh_is_transmissive(glass, mesh, &flat));
    MaterialAsset lit;
    CHECK(mesh_is_transmissive(glass, mesh, &lit));
    MaterialAsset full;
    full.full = true;
    CHECK_FALSE(mesh_is_transmissive(glass, mesh, &full));

    MeshRenderer skin;
    skin.subsurface = 0.6f;
    CHECK(mesh_scatters(skin, nullptr, false));
    CHECK_FALSE(mesh_scatters(skin, nullptr, true));  // a blended mesh is not part of the subsurface pass
    CHECK_FALSE(mesh_scatters(skin, &lit, false));    // a material brings its own lighting
    skin.unlit = true;
    CHECK_FALSE(mesh_scatters(skin, nullptr, false));
}
