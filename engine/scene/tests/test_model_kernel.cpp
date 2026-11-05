// The mesh kernel of model documents: every primitive's counts, closedness, bounds, orientation and determinism.
#include <doctest.h>

#include <cmath>
#include <cstring>

#include "fa/scene/model_kernel.h"

using namespace fa;

namespace {

constexpr double kPiD = 3.14159265358979323846;

bool same_bits(const ModelMesh& a, const ModelMesh& b) {
    auto eq = [](const auto& x, const auto& y) {
        return x.size() == y.size() && (x.empty() || std::memcmp(x.data(), y.data(), x.size() * sizeof(x[0])) == 0);
    };
    return eq(a.positions, b.positions) && eq(a.normals, b.normals) && eq(a.uvs, b.uvs) && eq(a.indices, b.indices);
}

// Every normal is a unit vector, every triangle's own normal agrees with the normals of its corners and no uv is outside [0, 1].
void check_shape(const ModelMesh& m) {
    REQUIRE(m.positions.size() == m.normals.size());
    REQUIRE(m.positions.size() == m.uvs.size());
    REQUIRE(m.indices.size() % 3 == 0);
    for (const Vec3& n : m.normals) CHECK(std::fabs(length(n) - 1.0f) < 1e-4f);
    for (const Vec2& uv : m.uvs) {
        CHECK(uv.x >= -1e-5f);
        CHECK(uv.x <= 1.0f + 1e-5f);
        CHECK(uv.y >= -1e-5f);
        CHECK(uv.y <= 1.0f + 1e-5f);
    }
    int disagree = 0;
    for (std::size_t t = 0; t < m.triangle_count(); ++t) {
        const std::uint32_t a = m.indices[t * 3], b = m.indices[t * 3 + 1], c = m.indices[t * 3 + 2];
        REQUIRE(a < m.positions.size());
        REQUIRE(b < m.positions.size());
        REQUIRE(c < m.positions.size());
        const Vec3 g = cross(m.positions[b] - m.positions[a], m.positions[c] - m.positions[a]);
        if (length(g) < 1e-9f) continue;
        if (dot(normalize(g), m.normals[a] + m.normals[b] + m.normals[c]) <= 0) ++disagree;
    }
    CHECK(disagree == 0);
}

void check_closed(const ModelMesh& m, double expectedVolume, double tolerance) {
    const ModelMeshStats s = model_mesh_stats(m);
    CHECK(s.boundaryEdges == 0);
    CHECK(s.nonManifoldEdges == 0);
    CHECK(s.degenerateTriangles == 0);
    CHECK(s.closed());
    CHECK(s.volume > 0);
    CHECK(std::fabs(s.volume - expectedVolume) <= tolerance * expectedVolume);
}

}  // namespace

TEST_CASE("model kernel: box counts, bounds and orientation") {
    const ModelMesh m = model_box({});
    CHECK(m.vertex_count() == 24);
    CHECK(m.triangle_count() == 12);
    check_shape(m);
    check_closed(m, 1.0, 1e-5);
    Vec3 lo, hi;
    m.bounds(lo, hi);
    CHECK(lo == Vec3{-0.5f, -0.5f, -0.5f});
    CHECK(hi == Vec3{0.5f, 0.5f, 0.5f});
    for (std::size_t i = 0; i < m.positions.size(); ++i) CHECK(dot(m.normals[i], m.positions[i]) > 0.4f);  // away from the centre

    const ModelMesh big = model_box({{1, 2, 3}, 2, 3, 4});
    CHECK(big.triangle_count() == 2 * 2 * (2 * 3 + 2 * 4 + 3 * 4));
    check_closed(big, 6.0, 1e-5);
    big.bounds(lo, hi);
    CHECK(hi == Vec3{0.5f, 1.0f, 1.5f});
    CHECK(same_bits(big, model_box({{1, 2, 3}, 2, 3, 4})));
}

TEST_CASE("model kernel: rounded box is a closed convex solid inside the plain box") {
    const ModelMesh m = model_rounded_box({{1, 1, 1}, 0.1f, 4});
    CHECK(m.vertex_count() == 600);
    CHECK(m.triangle_count() == 972);
    check_shape(m);
    const ModelMeshStats s = model_mesh_stats(m);
    CHECK(s.closed());
    CHECK(s.volume > 0.97);
    CHECK(s.volume < 1.0);
    CHECK(s.bmax.x == doctest::Approx(0.5f));
    CHECK(s.bmin.y == doctest::Approx(-0.5f));
    for (std::size_t i = 0; i < m.positions.size(); ++i) CHECK(dot(m.normals[i], m.positions[i]) > 0.3f);
    // radius 0 is the plain box
    CHECK(model_rounded_box({{1, 1, 1}, 0, 4}).triangle_count() == 12);
    // a radius above half the side is clamped: the box becomes a sphere
    const ModelMeshStats cap = model_mesh_stats(model_rounded_box({{1, 1, 1}, 9, 4}));
    CHECK(cap.closed());
    CHECK(cap.bmax.x == doctest::Approx(0.5f));
}

TEST_CASE("model kernel: cylinder, cone and pipe") {
    const ModelMesh cyl = model_cylinder({});
    CHECK(cyl.vertex_count() == 150);
    CHECK(cyl.triangle_count() == 96);
    check_shape(cyl);
    check_closed(cyl, 12 * 0.25 * std::sin(2 * kPiD / 24), 1e-4);
    Vec3 lo, hi;
    cyl.bounds(lo, hi);
    CHECK(hi.y == doctest::Approx(0.5f));
    CHECK(lo.y == doctest::Approx(-0.5f));
    CHECK(hi.x == doctest::Approx(0.5f).epsilon(1e-4));

    ModelCylinderParams open;
    open.capTop = false;
    open.capBottom = false;
    const ModelMeshStats tube = model_mesh_stats(model_cylinder(open));
    CHECK(tube.triangles == 48);
    CHECK(tube.boundaryEdges == 48);  // the two open rims

    ModelCylinderParams tapered;
    tapered.radiusTop = 0.25f;
    tapered.heightSegments = 3;
    const ModelMesh frustum = model_cylinder(tapered);
    check_shape(frustum);
    check_closed(frustum, 1.75 * std::sin(2 * kPiD / 24), 1e-4);

    const ModelMesh cone = model_cone({});
    CHECK(cone.vertex_count() == 100);
    CHECK(cone.triangle_count() == 48);
    check_shape(cone);
    check_closed(cone, 12 * 0.25 * std::sin(2 * kPiD / 24) / 3, 1e-4);
    ModelConeParams cut;
    cut.radiusTop = 0.2f;
    check_closed(model_cone(cut), 1.56 * std::sin(2 * kPiD / 24), 1e-4);

    const ModelMesh pipe = model_pipe({});
    CHECK(pipe.vertex_count() == 200);
    CHECK(pipe.triangle_count() == 192);
    check_shape(pipe);
    check_closed(pipe, 12 * (0.25 - 0.16) * std::sin(2 * kPiD / 24), 1e-4);
}

TEST_CASE("model kernel: sphere, capsule and torus") {
    const ModelMesh sph = model_sphere({});
    CHECK(sph.vertex_count() == 325);
    CHECK(sph.triangle_count() == 528);
    check_shape(sph);
    check_closed(sph, 4.0 / 3.0 * kPiD * 0.125, 0.05);
    Vec3 lo, hi;
    sph.bounds(lo, hi);
    CHECK(hi.y == doctest::Approx(0.5f));
    CHECK(lo.y == doctest::Approx(-0.5f));
    for (std::size_t i = 0; i < sph.positions.size(); ++i) CHECK(dot(sph.normals[i], normalize(sph.positions[i])) > 0.999f);

    const ModelMesh cap = model_capsule({});
    CHECK(cap.vertex_count() == 450);
    CHECK(cap.triangle_count() == 768);
    check_shape(cap);
    check_closed(cap, kPiD * 0.25 * 1.0 + 4.0 / 3.0 * kPiD * 0.125, 0.03);
    cap.bounds(lo, hi);
    CHECK(hi.y == doctest::Approx(1.0f));
    CHECK(lo.y == doctest::Approx(-1.0f));
    ModelCapsuleParams ball;
    ball.height = 1;  // exactly 2 * radius: a sphere
    check_closed(model_capsule(ball), 4.0 / 3.0 * kPiD * 0.125, 0.05);

    const ModelMesh tor = model_torus({});
    CHECK(tor.vertex_count() == 561);
    CHECK(tor.triangle_count() == 1024);
    check_shape(tor);
    check_closed(tor, 2 * kPiD * kPiD * 0.5 * 0.0225, 0.05);
    tor.bounds(lo, hi);
    CHECK(hi.x == doctest::Approx(0.65f));
    CHECK(hi.y == doctest::Approx(0.15f).epsilon(1e-3));
    // the normal of a torus points away from the centre of the tube
    for (std::size_t i = 0; i < tor.positions.size(); ++i) {
        const Vec3 p = tor.positions[i];
        const Vec3 ringPoint = normalize(Vec3{p.x, 0, p.z}) * 0.5f;
        CHECK(dot(tor.normals[i], normalize(p - ringPoint)) > 0.999f);
    }
}

TEST_CASE("model kernel: grid is an open plane facing up") {
    const ModelMesh g = model_grid({2, 3, 2, 3});
    CHECK(g.vertex_count() == 12);
    CHECK(g.triangle_count() == 12);
    check_shape(g);
    const ModelMeshStats s = model_mesh_stats(g);
    CHECK(s.boundaryEdges == 10);
    CHECK(s.area == doctest::Approx(6.0));
    CHECK(s.bmin == Vec3{-1, 0, -1.5f});
    for (const Vec3& n : g.normals) CHECK(n == Vec3{0, 1, 0});
    // the uv follows the plane: the +Z (front) edge of the plane is the bottom of the image
    for (std::size_t i = 0; i < g.positions.size(); ++i) {
        CHECK(g.uvs[i].x == doctest::Approx((g.positions[i].x + 1) / 2));
        CHECK(g.uvs[i].y == doctest::Approx((g.positions[i].z + 1.5f) / 3));
    }
}

TEST_CASE("model kernel: stairs climb towards -Z") {
    const ModelMesh m = model_stairs({});
    check_shape(m);
    check_closed(m, 1.0 * 1.5 * 1.0 * 7.0 / 12.0, 1e-4);
    Vec3 lo, hi;
    m.bounds(lo, hi);
    CHECK(lo.x == doctest::Approx(-0.5f));
    CHECK(hi.x == doctest::Approx(0.5f));
    CHECK(lo.y == doctest::Approx(-0.5f));
    CHECK(hi.y == doctest::Approx(0.5f));
    CHECK(lo.z == doctest::Approx(-0.75f));
    CHECK(hi.z == doctest::Approx(0.75f));
    for (const Vec3& p : m.positions)
        if (p.y > 0.49f) CHECK(p.z <= -0.49f);  // the top step is at the far end
    ModelStairsParams one;
    one.steps = 1;
    check_closed(model_stairs(one), 1.5, 1e-4);
    CHECK(model_stairs(one).triangle_count() == 12);  // a box: two caps of 2 triangles and four walls of 2
}

TEST_CASE("model kernel: arch has a doorway through it") {
    const ModelMesh m = model_arch({});
    check_shape(m);
    const double wall = 2.0 * 2.5 * 0.4, hole = (1.0 * 1.3 + kPiD * 0.25 / 2) * 0.4;
    check_closed(m, wall - hole, 0.02);
    Vec3 lo, hi;
    m.bounds(lo, hi);
    CHECK(lo.y == doctest::Approx(-1.25f));
    CHECK(hi.y == doctest::Approx(1.25f));
    CHECK(hi.z == doctest::Approx(0.2f));
    // the opening is empty: no vertex strictly inside the doorway's rectangle above the bottom
    for (const Vec3& p : m.positions) CHECK(!(std::fabs(p.x) < 0.499f && p.y < -1.25f + 1.2f && p.y > -1.25f + 0.01f));
}

namespace {

double triangles_area(const std::vector<Vec2>& pts, const std::vector<std::uint32_t>& tris) {
    double a = 0;
    for (std::size_t i = 0; i + 2 < tris.size(); i += 3) {
        const double ar = cross(pts[tris[i + 1]] - pts[tris[i]], pts[tris[i + 2]] - pts[tris[i]]);
        CHECK(ar > 0);  // every triangle counter-clockwise
        a += ar / 2;
    }
    return a;
}

}  // namespace

TEST_CASE("model kernel: triangulate_polygon handles concave outlines and holes") {
    // an L: area 3
    const std::vector<Vec2> ell{{0, 0}, {2, 0}, {2, 1}, {1, 1}, {1, 2}, {0, 2}};
    const auto t1 = triangulate_polygon(ell, {});
    CHECK(t1.size() == 12);
    CHECK(triangles_area(ell, t1) == doctest::Approx(3.0));

    // the same L given clockwise gives the same counter-clockwise triangles
    std::vector<Vec2> cw(ell.rbegin(), ell.rend());
    const auto t2 = triangulate_polygon(cw, {});
    CHECK(triangles_area(cw, t2) == doctest::Approx(3.0));

    // a square with a square hole: the indices run outline, then hole
    const std::vector<Vec2> outer{{0, 0}, {4, 0}, {4, 4}, {0, 4}}, hole{{1, 1}, {1, 3}, {3, 3}, {3, 1}};
    const auto t3 = triangulate_polygon(outer, {hole});
    CHECK(t3.size() == 8 * 3);
    std::vector<Vec2> all = outer;
    all.insert(all.end(), hole.begin(), hole.end());
    CHECK(triangles_area(all, t3) == doctest::Approx(12.0));

    // two holes
    const std::vector<Vec2> hole2{{-3, -1}, {-3, 1}, {-1, 1}, {-1, -1}};
    const std::vector<Vec2> bigOuter{{-4, -3}, {4, -3}, {4, 3}, {-4, 3}}, hole1{{1, -1}, {1, 1}, {3, 1}, {3, -1}};
    const auto t4 = triangulate_polygon(bigOuter, {hole1, hole2});
    std::vector<Vec2> all2 = bigOuter;
    all2.insert(all2.end(), hole1.begin(), hole1.end());
    all2.insert(all2.end(), hole2.begin(), hole2.end());
    CHECK(triangles_area(all2, t4) == doctest::Approx(48.0 - 8.0));

    CHECK(triangulate_polygon({{0, 0}, {1, 0}}, {}).empty());
}

TEST_CASE("model kernel: transform keeps triangles facing out, also through a mirror") {
    ModelMesh m = model_box({{1, 2, 3}, 1, 1, 1});
    m.transform(Mat4::trs({5, 0, 0}, {10, 20, 30}, {2, 1, 1}));
    check_shape(m);
    CHECK(model_mesh_stats(m).volume == doctest::Approx(12.0).epsilon(1e-3));
    ModelMesh mirrored = model_stairs({});
    mirrored.transform(Mat4::scale({-1, 1, 1}));
    check_shape(mirrored);
    CHECK(model_mesh_stats(mirrored).closed());
    CHECK(model_mesh_stats(mirrored).volume > 0);
    CHECK(model_mesh_stats(mirrored).volume == doctest::Approx(model_mesh_stats(model_stairs({})).volume));
}

TEST_CASE("model kernel: append shifts indices and pads colours") {
    ModelMesh a = model_box({});
    ModelMesh b = model_sphere({});
    a.set_color({1, 0, 0, 1});
    a.set_part(1);
    b.set_part(2);
    const std::size_t av = a.vertex_count(), at = a.triangle_count();
    a.append(b);
    CHECK(a.vertex_count() == av + b.vertex_count());
    CHECK(a.colors.size() == a.positions.size());
    CHECK(a.colors[0] == Vec4{1, 0, 0, 1});
    CHECK(a.colors[av] == Vec4{1, 1, 1, 1});
    CHECK(a.triParts.size() == a.triangle_count());
    CHECK(a.triParts[0] == 1);
    CHECK(a.triParts[at] == 2);
    CHECK(a.indices[at * 3] >= av);
    CHECK(model_mesh_stats(a).closed());
}

namespace {

// The glyph commands of a square with a square hole, in the em units of outline_text (y down).
ModelTextOutline ring_glyph() {
    ModelTextOutline o;
    auto rect = [&](float x0, float y0, float x1, float y1, bool flip) {
        auto cmd = [&](ModelGlyphCmd::Kind k, float x, float y) {
            ModelGlyphCmd c;
            c.kind = k;
            c.x = x;
            c.y = y;
            o.cmds.push_back(c);
        };
        cmd(ModelGlyphCmd::Move, x0, y0);
        if (!flip) {
            cmd(ModelGlyphCmd::Line, x1, y0);
            cmd(ModelGlyphCmd::Line, x1, y1);
            cmd(ModelGlyphCmd::Line, x0, y1);
        } else {
            cmd(ModelGlyphCmd::Line, x0, y1);
            cmd(ModelGlyphCmd::Line, x1, y1);
            cmd(ModelGlyphCmd::Line, x1, y0);
        }
        cmd(ModelGlyphCmd::Close, 0, 0);
    };
    rect(0, -1, 1, 0, false);
    rect(0.25f, -0.75f, 0.75f, -0.25f, true);
    o.glyphs = 1;
    return o;
}

}  // namespace

TEST_CASE("model kernel: text extrudes glyph outlines and finds the holes") {
    const ModelMesh m = model_text(ring_glyph(), {2.0f, 0.5f, 6});
    check_shape(m);
    check_closed(m, (4.0 - 1.0) * 0.5, 1e-4);  // (2 x 2 square - 1 x 1 hole) x 0.5 deep
    Vec3 lo, hi;
    m.bounds(lo, hi);
    CHECK(lo == Vec3{0, 0, -0.25f});
    CHECK(hi == Vec3{2, 2, 0.25f});
    CHECK(same_bits(m, model_text(ring_glyph(), {2.0f, 0.5f, 6})));
    CHECK(model_text(ModelTextOutline{}, {}).empty());

    // a curve: a half disc made of a line and a quadratic curve
    ModelTextOutline round;
    ModelGlyphCmd mv, ln, qd, cl;
    mv.kind = ModelGlyphCmd::Move;
    mv.x = 0;
    mv.y = 0;
    ln.kind = ModelGlyphCmd::Line;
    ln.x = 1;
    ln.y = 0;
    qd.kind = ModelGlyphCmd::Quad;
    qd.cx = 0.5f;
    qd.cy = -1;
    qd.x = 0;
    qd.y = 0;
    cl.kind = ModelGlyphCmd::Close;
    round.cmds = {mv, ln, qd, cl};
    ModelTextParams tp;
    tp.curveSegments = 8;
    const ModelMesh arc = model_text(round, tp);
    check_shape(arc);
    CHECK(model_mesh_stats(arc).closed());
    CHECK(arc.triangle_count() > 8);
}
