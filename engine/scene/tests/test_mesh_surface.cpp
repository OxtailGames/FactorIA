// load_mesh_surface / raycast_surface: the texture coordinate a ray lands on, the way the pointer reaches a render target.
#include <doctest.h>

#include <cmath>

#include "fa/scene/mesh_surface.h"

using namespace fa;

namespace {

const Vec3 kDown{0, 0, -1};

SurfaceHit hit_of(const MeshSurface& s, const Mat4& model, Vec3 origin, Vec3 dir = kDown) {
    const auto h = raycast_surface(s, model, origin, dir);
    REQUIRE(h.has_value());
    return *h;
}

}  // namespace

TEST_CASE("mesh surface: a quad answers the UV under the ray, v growing downwards") {
    auto s = load_mesh_surface("quad");
    REQUIRE(s.ok());
    const MeshSurface& q = **s;
    SurfaceHit h = hit_of(q, Mat4::identity(), {0, 0, 5});
    CHECK(h.uv.x == doctest::Approx(0.5f));
    CHECK(h.uv.y == doctest::Approx(0.5f));
    CHECK(h.distance == doctest::Approx(5.0f));
    h = hit_of(q, Mat4::identity(), {-0.4f, 0.4f, 5});  // top-left
    CHECK(h.uv.x == doctest::Approx(0.1f));
    CHECK(h.uv.y == doctest::Approx(0.1f));
    h = hit_of(q, Mat4::identity(), {0.25f, -0.25f, 5});  // bottom-right quarter
    CHECK(h.uv.x == doctest::Approx(0.75f));
    CHECK(h.uv.y == doctest::Approx(0.75f));
    CHECK_FALSE(raycast_surface(q, Mat4::identity(), {0.6f, 0, 5}, kDown).has_value());
    CHECK_FALSE(raycast_surface(q, Mat4::identity(), {0, 0, 5}, {0, 0, 1}).has_value());  // pointing away
}

TEST_CASE("mesh surface: the model matrix moves, stretches and turns the surface, and the back side answers too") {
    auto s = load_mesh_surface("quad");
    REQUIRE(s.ok());
    const Mat4 m = Mat4::trs({10, 2, 0}, {0, 0, 0}, {4, 2, 1});  // 4 x 2, centred on (10, 2)
    SurfaceHit h = hit_of(**s, m, {11, 2.5f, 3});
    CHECK(h.uv.x == doctest::Approx(0.75f));
    CHECK(h.uv.y == doctest::Approx(0.25f));
    h = hit_of(**s, m, {11, 2.5f, -3}, {0, 0, 1});  // from behind: the same point
    CHECK(h.uv.x == doctest::Approx(0.75f));
    CHECK(h.uv.y == doctest::Approx(0.25f));
    const Mat4 turned = Mat4::trs({0, 0, 0}, {0, 60, 0}, {2, 1, 1});  // turned 60 degrees about y
    const Vec3 corner = turned.transform_point({0.5f, 0.5f, 0});     // the top-right corner, in the world
    h = hit_of(**s, turned, corner * 0.98f + Vec3{0, 0, 5}, kDown);
    CHECK(h.uv.x == doctest::Approx(0.98f).epsilon(0.05f));
}

TEST_CASE("mesh surface: a cylinder is curved, so the UV follows the surface and the nearest side wins") {
    auto s = load_mesh_surface("cylinder");
    REQUIRE(s.ok());
    // Seen from +z the front of the side is u = 0.25 (angle 90 degrees); the ray also crosses the back, which is further.
    SurfaceHit h = hit_of(**s, Mat4::identity(), {0, 0, 5});
    CHECK(h.uv.x == doctest::Approx(0.25f).epsilon(0.01f));
    CHECK(h.uv.y == doctest::Approx(0.5f));
    CHECK(h.distance == doctest::Approx(4.5f).epsilon(0.01f));
    // Off to the side the surface turns away: x = 0.3 is angle asin(0.3 / 0.5) further round.
    h = hit_of(**s, Mat4::identity(), {0.3f, 0, 5});
    const float angle = kPi * 0.5f - std::asin(0.6f);
    CHECK(h.uv.x == doctest::Approx(angle / kTau).epsilon(0.02f));
    // Sphere: the pole row is v = 0 at the top.
    auto sphere = load_mesh_surface("sphere");
    REQUIRE(sphere.ok());
    h = hit_of(**sphere, Mat4::identity(), {0, 0.3f, 5});
    CHECK(h.uv.y < 0.5f);
}

TEST_CASE("mesh surface: surface_uv_on_plane continues past the edge of the triangle") {
    auto s = load_mesh_surface("quad");
    REQUIRE(s.ok());
    const MeshSurface& q = **s;
    SurfaceHit inside = hit_of(q, Mat4::identity(), {0.3f, 0.2f, 5});
    const auto out = surface_uv_on_plane(q, Mat4::identity(), inside.triangle, {1.5f, 0.2f, 5}, kDown);
    REQUIRE(out.has_value());
    CHECK(out->x == doctest::Approx(2.0f));
    CHECK(out->y == doctest::Approx(0.3f));
    // Parallel to the plane: no answer.
    CHECK_FALSE(surface_uv_on_plane(q, Mat4::identity(), inside.triangle, {0, 0, 5}, {1, 0, 0}).has_value());
    CHECK_FALSE(surface_uv_on_plane(q, Mat4::identity(), 999, {0, 0, 5}, kDown).has_value());
}

TEST_CASE("mesh surface: an unknown mesh is an error that suggests a primitive") {
    auto s = load_mesh_surface("quadd");
    REQUIRE_FALSE(s.ok());
    CHECK(s.error().message.find("quadd") != std::string::npos);
    CHECK(s.error().hint.find("quad") != std::string::npos);
    CHECK_FALSE(load_mesh_surface("").ok());
}
