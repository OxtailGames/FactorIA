// The inertia of capsules and convex hulls comes from their shape (inertia3d.h): known values of the solids.
#include <doctest.h>

#include <cmath>

#include "../src/inertia3d.h"
#include "fa/scene/mesh_geometry.h"

using namespace fa;
using namespace fa::detail;

namespace {
std::shared_ptr<ShapeData> hull_of(const char* mesh) {
    auto g = load_mesh_geometry(mesh);
    REQUIRE_MESSAGE(g.ok(), (g.ok() ? std::string() : g.error().to_string()));
    return make_shape_data(*g, true, false);
}
}  // namespace

TEST_CASE("inertia: a capsule is a cylinder plus two hemispheres") {
    // radius 1, cylinder height 2 (segHalf 1), mass 1: the cylinder holds 0.6 of the mass, the hemispheres 0.4.
    const Vec3 c = capsule_inertia(1.0f, 1.0f, 1.0f);
    CHECK(c.y == doctest::Approx(0.6 * 0.5 + 0.4 * 0.4));                                 // about its axis
    CHECK(c.x == doctest::Approx(0.6 * (0.25 + 4.0 / 12.0) + 0.4 * (0.4 + 1.0 + 0.75)));  // across it
    CHECK(c.z == c.x);
    CHECK(c.x > c.y);  // a long capsule is harder to tip than to spin

    // No cylinder: a solid sphere, 2/5 m r^2 about every axis.
    const Vec3 s = capsule_inertia(3.0f, 0.5f, 0.0f);
    CHECK(s.x == doctest::Approx(0.4 * 3.0 * 0.25));
    CHECK(s.y == doctest::Approx(0.4 * 3.0 * 0.25));

    // It scales with mass, and with the square of the size for the same proportions.
    const Vec3 big = capsule_inertia(2.0f, 2.0f, 2.0f), small = capsule_inertia(1.0f, 1.0f, 1.0f);
    CHECK(big.x == doctest::Approx(small.x * 2.0 * 4.0));
    CHECK(big.y == doctest::Approx(small.y * 2.0 * 4.0));
}

TEST_CASE("inertia: the tetrahedra of a hull give a box's moments, scaled per axis") {
    auto cube = hull_of("cube");
    REQUIRE(cube->hullMoments.volume > 0.0);
    CHECK(cube->hullMoments.volume == doctest::Approx(1.0));
    Vec3 i;
    REQUIRE(hull_inertia(6.0f, *cube, {1, 1, 1}, i));
    CHECK(i.x == doctest::Approx(1.0));  // m (a^2 + a^2) / 12 = 6 * 2 / 12
    CHECK(i.y == doctest::Approx(1.0));
    CHECK(i.z == doctest::Approx(1.0));
    // A 2 x 1 x 3 box of mass 12: Ix = m (h^2 + d^2) / 12 = 10, Iy = m (w^2 + d^2) / 12 = 13, Iz = m (w^2 + h^2) / 12 = 5.
    REQUIRE(hull_inertia(12.0f, *cube, {2, 1, 3}, i));
    CHECK(i.x == doctest::Approx(10.0));
    CHECK(i.y == doctest::Approx(13.0));
    CHECK(i.z == doctest::Approx(5.0));
}

TEST_CASE("inertia: a cylinder hull matches the formulas of the cylinder") {
    auto cyl = hull_of("cylinder");  // radius 0.5, height 1, centred on its origin
    Vec3 i;
    REQUIRE(hull_inertia(1.0f, *cyl, {1, 1, 1}, i));
    // About its axis m r^2 / 2, across it m (3 r^2 + h^2) / 12; the model is a polygon, so a small tolerance.
    CHECK(i.y == doctest::Approx(0.125).epsilon(0.02));
    CHECK(i.x == doctest::Approx((3 * 0.25 + 1.0) / 12.0).epsilon(0.02));
    CHECK(i.z == doctest::Approx(i.x).epsilon(0.02));
    // The same cylinder twice as tall: the tall axis keeps the moment about it, the others grow.
    Vec3 tall;
    REQUIRE(hull_inertia(1.0f, *cyl, {1, 2, 1}, tall));
    CHECK(tall.y == doctest::Approx(i.y).epsilon(0.001));
    CHECK(tall.x == doctest::Approx((3 * 0.25 + 4.0) / 12.0).epsilon(0.02));
}

TEST_CASE("inertia: a hull is measured about the model origin, a flat one has no volume") {
    // A unit cube with its corner at the origin: the parallel axes theorem, I = m/6 + m * (0.5^2 + 0.5^2) = m * 2/3.
    std::vector<Vec3> p = {{0, 0, 0}, {1, 0, 0}, {1, 1, 0}, {0, 1, 0}, {0, 0, 1}, {1, 0, 1}, {1, 1, 1}, {0, 1, 1}};
    std::vector<std::uint32_t> idx = {0, 3, 2, 0, 2, 1, 4, 5, 6, 4, 6, 7, 0, 1, 5, 0, 5, 4,
                                      3, 7, 6, 3, 6, 2, 0, 4, 7, 0, 7, 3, 1, 2, 6, 1, 6, 5};
    const SolidMoments m = solid_moments(p, idx);
    CHECK(m.volume == doctest::Approx(1.0));
    CHECK(m.xx == doctest::Approx(1.0 / 3.0));  // the integral of x^2 over [0,1]^3
    CHECK(m.yy == doctest::Approx(1.0 / 3.0));
    ShapeData d;
    d.hullMoments = m;
    Vec3 i;
    REQUIRE(hull_inertia(1.0f, d, {1, 1, 1}, i));
    CHECK(i.x == doctest::Approx(2.0 / 3.0));
    ShapeData flat;  // no volume: the caller keeps the bounding box
    CHECK_FALSE(hull_inertia(1.0f, flat, {1, 1, 1}, i));
}
