#include <doctest.h>

#include "fa/core/math.h"

using namespace fa;

static bool near(Vec3 a, Vec3 b, float eps = 1e-4f) {
    return approx_equal(a.x, b.x, eps) && approx_equal(a.y, b.y, eps) && approx_equal(a.z, b.z, eps);
}

TEST_CASE("math: euler order is Ry * Rx * Rz") {
    Vec3 e{30, 45, 60};
    Mat4 expected = Mat4::rotate_y_deg(45) * Mat4::rotate_x_deg(30) * Mat4::rotate_z_deg(60);
    Mat4 got = Mat4::rotate_euler_deg(e);
    for (int i = 0; i < 16; ++i) CHECK(approx_equal(expected.m[i], got.m[i]));
    // Yaw 90 turns forward (-Z) into -X (right-handed, +Y up).
    CHECK(near(Mat4::rotate_y_deg(90).transform_dir(kForward), Vec3{-1, 0, 0}));
    // Roll 90 about Z maps +X to +Y (counter-clockwise).
    CHECK(near(Mat4::rotate_z_deg(90).transform_dir({1, 0, 0}), Vec3{0, 1, 0}));
}

TEST_CASE("math: quaternion matches matrix and roundtrips euler") {
    for (Vec3 e : {Vec3{0, 0, 0}, Vec3{30, 45, 60}, Vec3{-20, 170, 10}, Vec3{80, -100, -45}}) {
        Quat q = Quat::from_euler_deg(e);
        Mat4 a = Mat4::from_quat(q), b = Mat4::rotate_euler_deg(e);
        for (int i = 0; i < 16; ++i) CHECK(approx_equal(a.m[i], b.m[i], 1e-4f));
        Vec3 back = q.to_euler_deg();
        Mat4 c = Mat4::rotate_euler_deg(back);  // euler angles can differ, the rotation must not
        for (int i = 0; i < 16; ++i) CHECK(approx_equal(b.m[i], c.m[i], 1e-3f));
    }
    Vec3 e{10, 20, 30};
    CHECK(near(Quat::from_euler_deg(e).to_euler_deg(), e, 1e-3f));
    CHECK(near(Quat::from_euler_deg({0, 90, 0}).rotate(kForward), Vec3{-1, 0, 0}));
}

TEST_CASE("math: trs and inverse") {
    Mat4 m = Mat4::trs({1, 2, 3}, {10, 20, 30}, {2, 2, 2});
    Mat4 id = m * m.inverse();
    for (int c = 0; c < 4; ++c)
        for (int r = 0; r < 4; ++r) CHECK(approx_equal(id.at(c, r), c == r ? 1.0f : 0.0f, 1e-4f));
    CHECK(near(m.transform_point({0, 0, 0}), {1, 2, 3}));
    CHECK(near(m.translation(), {1, 2, 3}));
    // Singular matrix -> identity.
    Mat4 zero;
    for (float& v : zero.m) v = 0;
    Mat4 inv = zero.inverse();
    CHECK(inv.at(0, 0) == 1.0f);
}

TEST_CASE("math: projections for both depth conventions") {
    for (bool zo : {false, true}) {
        Mat4 p = Mat4::perspective(60, 16.0f / 9.0f, 0.1f, 100.0f, zo);
        auto ndc_z = [&](float z) {
            Vec4 c = p * Vec4{0, 0, -z, 1};
            return c.z / c.w;
        };
        CHECK(approx_equal(ndc_z(0.1f), zo ? 0.0f : -1.0f, 1e-3f));
        CHECK(approx_equal(ndc_z(100.0f), 1.0f, 1e-3f));

        Mat4 o = Mat4::ortho(-10, 10, -5, 5, 0.0f, 100.0f, zo);
        Vec4 nearP = o * Vec4{10, 5, 0, 1}, farP = o * Vec4{-10, -5, -100, 1};
        CHECK(approx_equal(nearP.x, 1.0f));
        CHECK(approx_equal(nearP.y, 1.0f));
        CHECK(approx_equal(nearP.z, zo ? 0.0f : -1.0f));
        CHECK(approx_equal(farP.x, -1.0f));
        CHECK(approx_equal(farP.z, 1.0f));
    }
    // Vertical fov 90 -> a point at (0, z, -z) is at the top edge.
    Mat4 p = Mat4::perspective(90, 1.0f, 0.1f, 10.0f, false);
    Vec4 c = p * Vec4{0, 2, -2, 1};
    CHECK(approx_equal(c.y / c.w, 1.0f));
}

TEST_CASE("math: look_at") {
    Mat4 v = Mat4::look_at({0, 0, 5}, {0, 0, 0});
    CHECK(near(v.transform_point({0, 0, 0}), {0, 0, -5}));  // target ends up straight ahead (-Z)
    CHECK(near(v.transform_point({0, 0, 5}), {0, 0, 0}));   // eye is the origin of view space
    Mat4 side = Mat4::look_at({5, 0, 0}, {0, 0, 0});
    CHECK(near(side.transform_point({0, 0, 0}), {0, 0, -5}));
    CHECK(near(side.transform_point({0, 1, 0}), {0, 1, -5}));  // +Y stays up
}

TEST_CASE("math: rng is deterministic and well-behaved") {
    Rng a(42), b(42), c(43);
    bool differs = false;
    for (int i = 0; i < 100; ++i) {
        std::uint32_t x = a.next_u32();
        CHECK(x == b.next_u32());
        differs |= x != c.next_u32();
    }
    CHECK(differs);
    Rng r(7);
    for (int i = 0; i < 1000; ++i) {
        float f = r.next_float();
        CHECK(f >= 0.0f);
        CHECK(f < 1.0f);
        int n = r.range_int(3, 6);
        CHECK(n >= 3);
        CHECK(n <= 6);
    }
    Rng s1(5);
    s1.next_u32();
    Rng s2(5);
    s2.next_u32();
    CHECK(s1.state() == s2.state());
    s2.reseed(5);
    CHECK(s2.next_u32() == Rng(5).next_u32());
}

TEST_CASE("math: misc helpers") {
    CHECK(approx_equal(wrap_angle_deg(190), -170));
    CHECK(approx_equal(wrap_angle_deg(-190), 170));
    CHECK(approx_equal(remap(5, 0, 10, 0, 100), 50));
    CHECK(approx_equal(length(normalize(Vec3{3, 4, 0})), 1.0f));
    CHECK(Color::hex(0xff8000).g > 0.49f);
    CHECK(Color::rgba8(255, 0, 0).to_rgba8() == 0xff0000ffu);
}
