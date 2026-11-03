// The modifiers of the model kernel (model_modifiers.h): counts, bounds, closed and manifold surfaces, outward normals, kept parts and
// determinism of every modifier, and the booleans on overlapping, touching and coplanar solids.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <set>

#include "fa/scene/model_modifiers.h"

using namespace fa;

namespace {

constexpr double kPiD = 3.14159265358979323846;

template <typename T>
bool same_vec(const std::vector<T>& x, const std::vector<T>& y) {
    return x.size() == y.size() && (x.empty() || std::memcmp(x.data(), y.data(), x.size() * sizeof(T)) == 0);
}
bool same_bits(const ModelMesh& a, const ModelMesh& b) {
    return same_vec(a.positions, b.positions) && same_vec(a.normals, b.normals) && same_vec(a.uvs, b.uvs) && same_vec(a.colors, b.colors) &&
           same_vec(a.indices, b.indices) && same_vec(a.triParts, b.triParts);
}

// Unit normals, every triangle's own normal agreeing with the normals of its corners (so they point out), matching array sizes.
void check_shape(const ModelMesh& m, float sliver = 0) {
    REQUIRE(m.positions.size() == m.normals.size());
    REQUIRE(m.positions.size() == m.uvs.size());
    REQUIRE(m.indices.size() % 3 == 0);
    REQUIRE(m.triParts.size() == m.triangle_count());
    int bad = 0, disagree = 0;
    for (const Vec3& n : m.normals)
        if (std::fabs(length(n) - 1.0f) > 1e-3f) ++bad;
    CHECK(bad == 0);
    for (std::size_t t = 0; t < m.triangle_count(); ++t) {
        const std::uint32_t a = m.indices[t * 3], b = m.indices[t * 3 + 1], c = m.indices[t * 3 + 2];
        REQUIRE(a < m.positions.size());
        REQUIRE(b < m.positions.size());
        REQUIRE(c < m.positions.size());
        const Vec3 g = cross(m.positions[b] - m.positions[a], m.positions[c] - m.positions[a]);
        const float longest = std::max({length_sq(m.positions[b] - m.positions[a]), length_sq(m.positions[c] - m.positions[b]), length_sq(m.positions[a] - m.positions[c])});
        if (length(g) < 1e-9f || length(g) < sliver * longest) continue;  // `sliver`: very thin triangles whose direction is noise
        if (dot(normalize(g), m.normals[a] + m.normals[b] + m.normals[c]) <= 0) ++disagree;
    }
    CHECK(disagree == 0);
}

void check_closed(const ModelMesh& m, double expectedVolume, double tolerance) {
    const ModelMeshStats s = model_mesh_stats(m);
    CHECK(s.boundaryEdges == 0);
    CHECK(s.nonManifoldEdges == 0);
    CHECK(s.degenerateTriangles == 0);
    CHECK(s.volume > 0);
    CHECK(std::fabs(s.volume - expectedVolume) <= tolerance * expectedVolume);
}

ModelMesh moved(ModelMesh m, Vec3 by) {
    m.transform(Mat4::translate(by));
    return m;
}
ModelMesh with_part(ModelMesh m, std::uint32_t part) {
    m.set_part(part);
    return m;
}
ModelMesh unit_box() { return model_box({}); }
ModelMesh ok(Result<ModelMesh> r) {
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().message));
    return std::move(*r);
}
void bounds(const ModelMesh& m, Vec3& lo, Vec3& hi) { m.bounds(lo, hi); }
double volume(const ModelMesh& m) { return model_mesh_stats(m).volume; }
bool near(Vec3 a, Vec3 b, float eps) { return length(a - b) <= eps; }

}  // namespace

// ---- placement and repetition -------------------------------------------------------------------------------------------------------------

TEST_CASE("modifiers: mirror doubles the mesh, keeps it closed and facing out") {
    const ModelMesh half = moved(unit_box(), {1, 0, 0});
    ModelMirrorParams p;
    p.axis = 0;
    const ModelMesh m = model_mirror(half, p);
    CHECK(m.triangle_count() == 24);
    check_shape(m);
    check_closed(m, 2.0, 1e-5);
    Vec3 lo, hi;
    bounds(m, lo, hi);
    CHECK(near(lo, {-1.5f, -0.5f, -0.5f}, 1e-5f));
    CHECK(near(hi, {1.5f, 0.5f, 0.5f}, 1e-5f));
    CHECK(same_bits(m, model_mirror(half, p)));

    p.axis = 1;
    p.offset = 2;  // the plane y = 2: the mirror image is above
    const ModelMesh up = model_mirror(unit_box(), p);
    bounds(up, lo, hi);
    CHECK(near(hi, {0.5f, 4.5f, 0.5f}, 1e-5f));
    check_closed(up, 2.0, 1e-5);
}

TEST_CASE("modifiers: mirror keeps parts and joins the seam when merging") {
    ModelMesh a = with_part(moved(unit_box(), {1, 0, 0}), 4);
    const ModelMesh m = model_mirror(a, {});
    REQUIRE(m.triParts.size() == 24);
    for (std::uint32_t part : m.triParts) CHECK(part == 4);

    ModelMesh grid = model_grid({1, 1, 2, 2});
    grid.transform(Mat4::translate({0.5f, 0, 0}));  // x from 0 to 1, vertices on the plane x = 0
    ModelMirrorParams merge, apart;
    merge.merge = true;
    apart.merge = false;
    const ModelMesh joined = model_mirror(grid, merge), loose = model_mirror(grid, apart);
    CHECK(joined.triangle_count() == 16);
    CHECK(loose.triangle_count() == 16);
    CHECK(joined.vertex_count() < loose.vertex_count());
    CHECK(model_mesh_stats(joined).boundaryEdges == 12);  // one 4 x 2 rectangle of cells: 12 edges round it
    check_shape(joined);
}

TEST_CASE("modifiers: array copies, steps, relative offsets and determinism") {
    ModelArrayParams p;
    p.count = 3;
    p.offset = {2, 0, 0};
    const ModelMesh m = model_array(unit_box(), p);
    CHECK(m.triangle_count() == 36);
    check_shape(m);
    check_closed(m, 3.0, 1e-5);
    Vec3 lo, hi;
    bounds(m, lo, hi);
    CHECK(near(lo, {-0.5f, -0.5f, -0.5f}, 1e-5f));
    CHECK(near(hi, {4.5f, 0.5f, 0.5f}, 1e-5f));
    CHECK(same_bits(m, model_array(unit_box(), p)));

    ModelArrayParams rel;
    rel.count = 4;
    rel.relative = true;
    rel.offset = {0, 1.5f, 0};  // one and a half box heights between copies
    bounds(model_array(unit_box(), rel), lo, hi);
    CHECK(near(hi, {0.5f, 5.0f, 0.5f}, 1e-4f));

    ModelArrayParams shrink;
    shrink.count = 3;
    shrink.offset = {0, 0, 0};
    shrink.stepScale = {0.5f, 0.5f, 0.5f};
    const ModelMesh s = model_array(unit_box(), shrink);
    CHECK(volume(s) == doctest::Approx(1.0 + 0.125 + 0.015625).epsilon(1e-4));

    ModelArrayParams spin;
    spin.count = 4;
    spin.offset = {0, 1, 0};
    spin.stepRotation = {0, 90, 0};
    const ModelMesh sp = model_array(model_box({{2, 0.5f, 0.5f}, 1, 1, 1}), spin);
    bounds(sp, lo, hi);
    CHECK(near(hi, {1.0f, 3.25f, 1.0f}, 1e-4f));  // the long box lies along Z in every second copy
    CHECK(near(lo, {-1.0f, -0.25f, -1.0f}, 1e-4f));
}

TEST_CASE("modifiers: array merge joins touching copies") {
    ModelArrayParams p;
    p.count = 2;
    p.offset = {1.0004f, 0, 0};  // a hairline gap between the copies
    const ModelMesh loose = model_array(model_grid({1, 1, 1, 1}), p);
    p.merge = true;
    const ModelMesh joined = model_array(model_grid({1, 1, 1, 1}), p);
    CHECK(joined.triangle_count() == loose.triangle_count());
    CHECK(model_mesh_stats(loose).boundaryEdges == 8);
    CHECK(model_mesh_stats(joined).boundaryEdges == 6);
}

TEST_CASE("modifiers: radial array") {
    ModelRadialArrayParams p;
    p.count = 4;
    const ModelMesh base = moved(unit_box(), {2, 0, 0});
    const ModelMesh m = model_radial_array(base, p);
    CHECK(m.triangle_count() == 48);
    check_shape(m);
    check_closed(m, 4.0, 1e-4);
    Vec3 lo, hi;
    bounds(m, lo, hi);
    CHECK(near(lo, {-2.5f, -0.5f, -2.5f}, 1e-4f));
    CHECK(near(hi, {2.5f, 0.5f, 2.5f}, 1e-4f));
    CHECK(same_bits(m, model_radial_array(base, p)));

    // half a circle: the first copy at 0 and the last at 180 degrees
    ModelRadialArrayParams half;
    half.count = 3;
    half.angle = 180;
    bounds(model_radial_array(base, half), lo, hi);
    CHECK(hi.x == doctest::Approx(2.5f).epsilon(1e-4));
    CHECK(lo.x == doctest::Approx(-2.5f).epsilon(1e-4));
    CHECK(hi.z == doctest::Approx(0.5f).epsilon(1e-3));  // turning about +Y takes +X towards -Z
    CHECK(lo.z == doctest::Approx(-2.5f).epsilon(1e-3));

    // a long box: turning with the circle puts every second copy along the other axis, keeping the orientation does not
    const ModelMesh plank = moved(model_box({{2, 0.2f, 0.2f}, 1, 1, 1}), {3, 0, 0});
    ModelRadialArrayParams turn, keep;
    turn.count = 4;
    keep.count = 4;
    keep.faceCenter = false;
    bounds(model_radial_array(plank, turn), lo, hi);
    CHECK(hi.z == doctest::Approx(4.0f).epsilon(1e-3));
    bounds(model_radial_array(plank, keep), lo, hi);
    CHECK(hi.z == doctest::Approx(3.1f).epsilon(1e-3));

    ModelRadialArrayParams about;
    about.count = 2;
    about.axis = 0;  // about the X axis through (0, 5, 0): the second copy is the first reflected through the axis
    about.center = {0, 5, 0};
    about.angle = 180;
    bounds(model_radial_array(unit_box(), about), lo, hi);
    CHECK(hi.y == doctest::Approx(10.5f).epsilon(1e-3));
}

// ---- bevel ----------------------------------------------------------------------------------------------------------------------------------

TEST_CASE("modifiers: bevel rounds a box and stays a closed solid") {
    ModelBevelParams p;
    p.width = 0.1f;
    p.segments = 3;
    std::size_t edges = 0;
    const ModelMesh m = ok(model_bevel(unit_box(), p, &edges));
    CHECK(edges == 12);
    CHECK(m.triangle_count() > 12 + 12 * 3 * 2);
    check_shape(m);
    const ModelMeshStats s = model_mesh_stats(m);
    CHECK(s.closed());
    CHECK(s.degenerateTriangles == 0);
    CHECK(s.volume < 0.995);
    CHECK(s.volume > 0.9);
    Vec3 lo, hi;
    bounds(m, lo, hi);
    CHECK(near(lo, {-0.5f, -0.5f, -0.5f}, 1e-5f));
    CHECK(near(hi, {0.5f, 0.5f, 0.5f}, 1e-5f));
    // the face centres keep a flat normal
    int flat = 0;
    for (std::size_t i = 0; i < m.positions.size(); ++i)
        if (std::fabs(m.positions[i].y - 0.5f) < 1e-5f && std::fabs(m.positions[i].x) < 0.41f && std::fabs(m.positions[i].z) < 0.41f && m.normals[i].y > 0.9999f) ++flat;
    CHECK(flat > 0);
    CHECK(same_bits(m, ok(model_bevel(unit_box(), p))));

    // one segment is a chamfer; more segments, more triangles
    ModelBevelParams one = p;
    one.segments = 1;
    const ModelMesh chamfer = ok(model_bevel(unit_box(), one));
    CHECK(chamfer.triangle_count() < m.triangle_count());
    check_closed(chamfer, 0.9453, 0.005);  // 12 edges lose a triangle of width 0.1 each
}

TEST_CASE("modifiers: bevel respects the angle, the width and the parts") {
    ModelBevelParams p;
    p.width = 0.05f;
    p.angle = 100;  // box edges turn by 90 degrees: none is sharp enough
    std::size_t edges = 99;
    const ModelMesh same = ok(model_bevel(unit_box(), p, &edges));
    CHECK(edges == 0);
    CHECK(same.triangle_count() == 12);

    ModelBevelParams wide;
    wide.width = 0.6f;
    auto r = model_bevel(unit_box(), wide);
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("wider") != std::string::npos);
    CHECK(r.error().hint.find("width") != std::string::npos);

    ModelMesh two = with_part(unit_box(), 3);
    two.append(with_part(moved(unit_box(), {3, 0, 0}), 7));
    std::size_t both = 0;
    const ModelMesh b = ok(model_bevel(two, {}, &both));
    CHECK(both == 24);
    std::set<std::uint32_t> parts(b.triParts.begin(), b.triParts.end());
    CHECK(parts == std::set<std::uint32_t>{3, 7});
    check_closed(b, 2.0, 0.05);
}

TEST_CASE("modifiers: bevel only the flat rims of a cylinder") {
    ModelBevelParams p;
    p.width = 0.05f;
    p.segments = 2;
    std::size_t edges = 0;
    const ModelMesh cyl = model_cylinder({});
    const ModelMesh m = ok(model_bevel(cyl, p, &edges));
    CHECK(edges == 48);  // the 24 edges of each rim; the side's own creases are 15 degrees
    check_shape(m);
    CHECK(model_mesh_stats(m).closed());
    CHECK(volume(m) < volume(cyl));
}

// ---- subdivision ----------------------------------------------------------------------------------------------------------------------------

TEST_CASE("modifiers: Catmull-Clark subdivision") {
    ModelSubdivideParams p;
    const ModelMesh one = model_subdivide(unit_box(), p);
    CHECK(one.triangle_count() == 48);  // 6 quads become 24
    CHECK(model_subdivide_triangle_bound(unit_box(), 1) >= one.triangle_count());
    check_shape(one);
    const ModelMeshStats s = model_mesh_stats(one);
    CHECK(s.closed());
    CHECK(s.volume < 0.9);
    CHECK(s.volume > 0.4);
    CHECK(s.bmax.x <= 0.5f + 1e-5f);  // the face points stay on the faces

    p.levels = 2;
    const ModelMesh two = model_subdivide(unit_box(), p);
    CHECK(two.triangle_count() == 192);
    CHECK(model_mesh_stats(two).closed());
    CHECK(volume(two) < s.volume);
    CHECK(same_bits(two, model_subdivide(unit_box(), p)));

    // with every edge a crease the box keeps its shape
    ModelSubdivideParams sharp;
    sharp.creaseAngle = 30;
    const ModelMesh keep = model_subdivide(unit_box(), sharp);
    CHECK(keep.triangle_count() == 48);
    CHECK(volume(keep) == doctest::Approx(1.0).epsilon(1e-4));
    Vec3 lo, hi;
    bounds(keep, lo, hi);
    CHECK(near(hi, {0.5f, 0.5f, 0.5f}, 1e-5f));
}

TEST_CASE("modifiers: subdivision keeps the parts and works on open surfaces") {
    ModelMesh m = with_part(unit_box(), 2);
    for (std::uint32_t part : model_subdivide(m, {}).triParts) CHECK(part == 2);
    const ModelMesh grid = model_subdivide(model_grid({1, 1, 2, 2}), {});
    CHECK(grid.triangle_count() == 8 * 4);
    check_shape(grid);
    Vec3 lo, hi;
    bounds(grid, lo, hi);
    CHECK(near(lo, {-0.5f, 0, -0.5f}, 1e-5f));  // the boundary of a flat sheet stays where it is
    CHECK(near(hi, {0.5f, 0, 0.5f}, 1e-5f));
    CHECK(model_subdivide(ModelMesh{}, {}).empty());
}

// ---- solidify -------------------------------------------------------------------------------------------------------------------------------

TEST_CASE("modifiers: solidify gives a surface thickness") {
    ModelSolidifyParams p;
    p.thickness = 0.1f;
    const ModelMesh slab = model_solidify(model_grid({1, 1, 2, 2}), p);
    CHECK(slab.triangle_count() == 8 + 8 + 16);
    check_shape(slab);
    check_closed(slab, 0.1, 0.02);
    Vec3 lo, hi;
    bounds(slab, lo, hi);
    CHECK(lo.y == doctest::Approx(-0.1f).epsilon(1e-3));  // grew against the +Y normals
    CHECK(std::fabs(hi.y) < 1e-4f);
    CHECK(same_bits(slab, model_solidify(model_grid({1, 1, 2, 2}), p)));

    p.offset = 1;
    bounds(model_solidify(model_grid({1, 1, 2, 2}), p), lo, hi);
    CHECK(lo.y == doctest::Approx(0.0f).epsilon(1e-3));
    CHECK(hi.y == doctest::Approx(0.1f).epsilon(1e-3));
    p.offset = 0;
    bounds(model_solidify(model_grid({1, 1, 2, 2}), p), lo, hi);
    CHECK(lo.y == doctest::Approx(-0.05f).epsilon(1e-3));
    CHECK(hi.y == doctest::Approx(0.05f).epsilon(1e-3));

    // a closed solid becomes a hollow shell: the outside stays, the inside is a second surface facing in
    const ModelMesh ball = model_sphere({0.5f, 24, 12});
    ModelSolidifyParams shell;
    shell.thickness = 0.05f;
    const ModelMesh hollow = model_solidify(ball, shell);
    CHECK(hollow.triangle_count() == 2 * ball.triangle_count());
    check_shape(hollow);
    const ModelMeshStats s = model_mesh_stats(hollow);
    CHECK(s.closed());
    CHECK(s.volume == doctest::Approx(volume(ball) * (1.0 - std::pow(0.45 / 0.5, 3.0))).epsilon(0.06));
    CHECK(s.bmax.x == doctest::Approx(0.5f).epsilon(1e-3));
}

// ---- booleans -------------------------------------------------------------------------------------------------------------------------------

TEST_CASE("modifiers: boolean union, difference and intersection of overlapping boxes") {
    const ModelMesh a = unit_box(), b = moved(unit_box(), {0.5f, 0, 0});
    const ModelMesh un = ok(model_boolean({a, b}, ModelBooleanMode::Union));
    check_shape(un);
    check_closed(un, 1.5, 1e-4);
    const ModelMesh diff = ok(model_boolean({a, b}, ModelBooleanMode::Difference));
    check_shape(diff);
    check_closed(diff, 0.5, 1e-4);
    const ModelMesh both = ok(model_boolean({a, b}, ModelBooleanMode::Intersection));
    check_shape(both);
    check_closed(both, 0.5, 1e-4);
    Vec3 lo, hi;
    bounds(both, lo, hi);
    CHECK(near(lo, {0, -0.5f, -0.5f}, 1e-5f));
    CHECK(near(hi, {0.5f, 0.5f, 0.5f}, 1e-5f));
    CHECK(same_bits(un, ok(model_boolean({a, b}, ModelBooleanMode::Union))));
    CHECK(same_bits(diff, ok(model_boolean({a, b}, ModelBooleanMode::Difference))));
}

TEST_CASE("modifiers: boolean on touching and coplanar solids") {
    const ModelMesh a = unit_box();
    // sharing a whole face
    const ModelMesh touching = ok(model_boolean({a, moved(unit_box(), {1, 0, 0})}, ModelBooleanMode::Union));
    check_shape(touching);
    check_closed(touching, 2.0, 1e-4);
    // the intersection of solids that only touch is empty
    CHECK(ok(model_boolean({a, moved(unit_box(), {1, 0, 0})}, ModelBooleanMode::Intersection)).empty());
    // coplanar top, bottom and back faces
    const ModelMesh coplanar = ok(model_boolean({a, moved(unit_box(), {0.5f, 0, 0})}, ModelBooleanMode::Union));
    check_closed(coplanar, 1.5, 1e-4);
    // identical solids
    check_closed(ok(model_boolean({a, unit_box()}, ModelBooleanMode::Union)), 1.0, 1e-4);
    CHECK(ok(model_boolean({a, unit_box()}, ModelBooleanMode::Difference)).empty());
    check_closed(ok(model_boolean({a, unit_box()}, ModelBooleanMode::Intersection)), 1.0, 1e-4);
    // a smaller box that shares the top face with a bigger one
    const ModelMesh flush = ok(model_boolean({a, moved(model_box({{0.5f, 0.5f, 0.5f}, 1, 1, 1}), {0, 0.25f, 0})}, ModelBooleanMode::Difference));
    check_shape(flush);
    check_closed(flush, 1.0 - 0.125, 1e-4);
    // disjoint solids stay two shells
    const ModelMesh far = ok(model_boolean({a, moved(unit_box(), {5, 0, 0})}, ModelBooleanMode::Union));
    check_closed(far, 2.0, 1e-4);
    // three operands: a bar through a ball and a block through it
    const ModelMesh three = ok(model_boolean({model_sphere({0.5f, 24, 12}), model_box({{0.2f, 2, 0.2f}, 1, 1, 1}), model_box({{2, 0.2f, 0.2f}, 1, 1, 1})}, ModelBooleanMode::Difference));
    check_shape(three);
    CHECK(model_mesh_stats(three).closed());
    CHECK(volume(three) < volume(model_sphere({0.5f, 24, 12})));
}

TEST_CASE("modifiers: boolean keeps the part of the surface each triangle came from") {
    const ModelMesh a = with_part(unit_box(), 1), b = with_part(moved(unit_box(), {0.5f, 0, 0}), 2);
    const ModelMesh diff = ok(model_boolean({a, b}, ModelBooleanMode::Difference));
    std::set<std::uint32_t> parts(diff.triParts.begin(), diff.triParts.end());
    CHECK(parts == std::set<std::uint32_t>{1, 2});  // the new wall inside the cut is the cutter's
    // the cut wall faces the removed volume: its normals point +X, away from the remaining solid
    int wall = 0;
    for (std::size_t t = 0; t < diff.triangle_count(); ++t)
        if (diff.triParts[t] == 2) {
            ++wall;
            const Vec3 n = diff.normals[diff.indices[t * 3]];
            CHECK(n.x > 0.99f);
        }
    CHECK(wall > 0);
    const ModelMesh un = ok(model_boolean({a, b}, ModelBooleanMode::Union));
    std::set<std::uint32_t> uparts(un.triParts.begin(), un.triParts.end());
    CHECK(uparts == std::set<std::uint32_t>{1, 2});
}

TEST_CASE("modifiers: boolean carries uvs, colours and smooth normals") {
    ModelMesh ball = model_sphere({0.5f, 32, 16});
    ball.set_color({1, 0, 0, 1});
    const ModelMesh cutter = moved(model_cylinder({0.2f, -1, 2, 24, 1, true, true}), {0, 0, 0});
    const ModelMesh m = ok(model_boolean({ball, cutter}, ModelBooleanMode::Difference));
    check_shape(m);
    check_closed(m, volume(ball) - 3.0 * 0.04 * 0.5 * 0.5 + 0.0, 0.5);  // a ball with a hole through it
    CHECK(volume(m) < volume(ball));
    REQUIRE(m.colors.size() == m.positions.size());
    // a vertex on the sphere's surface is still smooth: its normal points away from the centre
    int smooth = 0;
    for (std::size_t i = 0; i < m.positions.size(); ++i) {
        const float r = length(m.positions[i]);
        if (std::fabs(r - 0.5f) < 1e-3f && length({m.positions[i].x, 0, m.positions[i].z}) > 0.25f && dot(normalize(m.positions[i]), m.normals[i]) > 0.99f) ++smooth;
    }
    CHECK(smooth > 100);
}

TEST_CASE("modifiers: boolean refuses what is not a closed solid, with the operand named") {
    auto r = model_boolean({unit_box(), model_grid({1, 1, 1, 1})}, ModelBooleanMode::Union, {"/nodes/0/children/0", "/nodes/0/children/1"});
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("/nodes/0/children/1") != std::string::npos);
    CHECK(r.error().message.find("closed") != std::string::npos);
    CHECK_FALSE(r.error().hint.empty());

    ModelMesh inside = unit_box();
    inside.transform(Mat4::scale({-1, 1, 1}));  // transform() turns the winding back: a mirrored box is still a solid
    CHECK(model_boolean({unit_box(), inside}, ModelBooleanMode::Union).ok());
    ModelMesh inverted = unit_box();
    for (std::size_t t = 0; t < inverted.triangle_count(); ++t) std::swap(inverted.indices[t * 3 + 1], inverted.indices[t * 3 + 2]);
    auto bad = model_boolean({unit_box(), inverted}, ModelBooleanMode::Union);
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("inwards") != std::string::npos);

    // two boxes joined along one edge only
    ModelMesh pinched = unit_box();
    pinched.append(moved(unit_box(), {1, 1, 0}));
    auto edge = model_boolean({pinched}, ModelBooleanMode::Union);
    CHECK_FALSE(edge.ok());
}

// ---- deformers ------------------------------------------------------------------------------------------------------------------------------

TEST_CASE("modifiers: bend, twist and taper deform without tearing") {
    const ModelMesh bar = model_box({{0.2f, 2, 0.2f}, 1, 16, 1});
    ModelBendParams bp;
    bp.angle = 90;
    const ModelMesh bent = model_bend(bar, bp);
    CHECK(bent.triangle_count() == bar.triangle_count());
    check_shape(bent);
    check_closed(bent, 0.08, 0.05);
    Vec3 lo, hi;
    bounds(bent, lo, hi);
    CHECK(hi.z > 0.5f);   // bends towards +Z
    CHECK(lo.z > -0.2f);
    // the top end has turned to point along +Z
    const float radius = 2.0f / (float(kPiD) / 2.0f);
    CHECK(hi.z == doctest::Approx(radius).epsilon(0.01));
    CHECK(same_bits(bent, model_bend(bar, bp)));
    bp.angle = 0;
    CHECK(same_bits(model_bend(bar, bp), bar));
    ModelBendParams other;
    other.direction = 90;
    bounds(model_bend(bar, other), lo, hi);
    CHECK(hi.x > 0.5f);

    ModelTwistParams tp;
    tp.angle = 90;
    const ModelMesh twisted = model_twist(model_box({{1, 2, 1}, 1, 8, 1}), tp);
    check_shape(twisted);
    CHECK(model_mesh_stats(twisted).closed());
    // a corner at the top is rotated by a quarter turn about Y, its radius unchanged
    bool found = false;
    for (const Vec3& q : twisted.positions)
        if (std::fabs(q.y - 1.0f) < 1e-4f) {
            CHECK(std::sqrt(q.x * q.x + q.z * q.z) == doctest::Approx(std::sqrt(0.5f)).epsilon(1e-3));
            found = true;
        }
    CHECK(found);
    CHECK(same_bits(twisted, model_twist(model_box({{1, 2, 1}, 1, 8, 1}), tp)));

    ModelTaperParams ta;
    ta.startScale = 1;
    ta.endScale = 0.5f;
    const ModelMesh cone = model_taper(model_box({{1, 1, 1}, 1, 8, 1}), ta);
    check_shape(cone);
    check_closed(cone, (1 + 0.5 + 0.25) / 3.0, 0.01);
    bounds(cone, lo, hi);
    CHECK(near(hi, {0.5f, 0.5f, 0.5f}, 1e-5f));
    for (const Vec3& q : cone.positions)
        if (q.y > 0.499f) CHECK(std::fabs(q.x) <= 0.2501f);
}

TEST_CASE("modifiers: noise is seeded, bounded and keeps the surface closed") {
    const ModelMesh ball = model_sphere({0.5f, 32, 16});
    ModelNoiseParams p;
    p.amplitude = 0.05f;
    p.frequency = 4;
    p.seed = 7;
    const ModelMesh a = model_noise(ball, p);
    check_shape(a);
    CHECK(model_mesh_stats(a).closed());
    CHECK(same_bits(a, model_noise(ball, p)));
    float most = 0;
    int moved_count = 0;
    for (std::size_t i = 0; i < ball.positions.size(); ++i) {
        const float d = length(a.positions[i] - ball.positions[i]);
        most = std::max(most, d);
        if (d > 1e-5f) ++moved_count;
    }
    CHECK(most <= 0.05f + 1e-4f);
    CHECK(moved_count > int(ball.positions.size() / 2));
    ModelNoiseParams other = p;
    other.seed = 8;
    CHECK_FALSE(same_bits(a, model_noise(ball, other)));
    ModelNoiseParams flat = p;
    flat.amplitude = 0;
    const ModelMesh calm = model_noise(ball, flat);
    for (std::size_t i = 0; i < ball.positions.size(); ++i) REQUIRE(length(calm.positions[i] - ball.positions[i]) < 1e-5f);
    ModelNoiseParams free3 = p;
    free3.alongNormal = false;
    CHECK(model_mesh_stats(model_noise(ball, free3)).closed());
    ModelNoiseParams layers = p;
    layers.octaves = 3;
    CHECK(model_mesh_stats(model_noise(ball, layers)).closed());
}

// ---- smoothing, welding, shading ------------------------------------------------------------------------------------------------------------

TEST_CASE("modifiers: smooth relaxes noise and Taubin keeps the volume better than Laplacian") {
    ModelNoiseParams np;
    np.amplitude = 0.04f;
    np.frequency = 8;
    const ModelMesh rough = model_noise(model_sphere({0.5f, 32, 16}), np);
    ModelSmoothParams sp;
    sp.iterations = 6;
    const ModelMesh smooth = model_smooth(rough, sp);
    const ModelMeshStats before = model_mesh_stats(rough), after = model_mesh_stats(smooth);
    check_shape(smooth);
    CHECK(after.closed());
    CHECK(after.area < before.area);
    ModelSmoothParams lap = sp;
    lap.taubin = false;
    const ModelMesh shrunk = model_smooth(rough, lap);
    CHECK(model_mesh_stats(shrunk).volume < after.volume);
    CHECK(same_bits(smooth, model_smooth(rough, sp)));

    // sharp corners of a box stay with sharpAngle; without it they round off
    ModelSmoothParams keep;
    keep.sharpAngle = 30;
    Vec3 lo, hi;
    bounds(model_smooth(model_box({{1, 1, 1}, 4, 4, 4}), keep), lo, hi);
    CHECK(near(hi, {0.5f, 0.5f, 0.5f}, 1e-5f));
    bounds(model_smooth(model_box({{1, 1, 1}, 4, 4, 4}), sp), lo, hi);
    CHECK(std::fabs(hi.x - 0.5f) > 1e-3f);  // nothing is locked: the corners move

    // an open boundary is locked by default
    ModelMesh grid = model_grid({1, 1, 4, 4});
    bounds(model_smooth(grid, {}), lo, hi);
    CHECK(near(hi, {0.5f, 0, 0.5f}, 1e-6f));
}

TEST_CASE("modifiers: weld closes gaps and drops collapsed triangles") {
    ModelMesh left = model_grid({1, 1, 1, 1});
    ModelMesh right = moved(model_grid({1, 1, 1, 1}), {1.0004f, 0, 0});
    left.append(right);
    CHECK(model_mesh_stats(left).boundaryEdges == 8);
    const ModelMesh w = model_weld(left, {0.001f});
    CHECK(w.triangle_count() == 4);
    CHECK(model_mesh_stats(w).boundaryEdges == 6);
    check_shape(w);
    CHECK(same_bits(w, model_weld(left, {0.001f})));
    // a sliver thinner than the distance collapses
    ModelMesh sliver;
    sliver.positions = {{0, 0, 0}, {1, 0, 0}, {0.0001f, 0.0001f, 0}};
    sliver.normals = {{0, 0, 1}, {0, 0, 1}, {0, 0, 1}};
    sliver.uvs = {{0, 0}, {1, 0}, {0, 1}};
    sliver.indices = {0, 1, 2};
    sliver.triParts = {0};
    CHECK(model_weld(sliver, {0.001f}).empty());
}

TEST_CASE("modifiers: shading flat, smooth and by angle") {
    const ModelMesh ball = model_sphere({0.5f, 24, 12});
    ModelShadeParams s;
    s.mode = ModelShadeMode::Flat;
    const ModelMesh flat = model_shade(ball, s);
    CHECK(flat.triangle_count() == ball.triangle_count());
    for (std::size_t t = 0; t < flat.triangle_count(); ++t) {
        const Vec3 a = flat.normals[flat.indices[t * 3]], b = flat.normals[flat.indices[t * 3 + 1]], c = flat.normals[flat.indices[t * 3 + 2]];
        CHECK(near(a, b, 1e-4f));
        CHECK(near(a, c, 1e-4f));
    }
    s.mode = ModelShadeMode::Smooth;
    const ModelMesh smooth = model_shade(unit_box(), s);
    check_shape(smooth);
    for (const Vec3& n : smooth.normals) CHECK(std::fabs(std::fabs(n.x) - 0.57735f) < 1e-3f);  // at a corner the three faces average to the diagonal
    s.mode = ModelShadeMode::Auto;
    s.angle = 30;
    const ModelMesh box = model_shade(unit_box(), s);
    for (const Vec3& n : box.normals) CHECK(std::max({std::fabs(n.x), std::fabs(n.y), std::fabs(n.z)}) > 0.9999f);  // the sharp edges stay
    const ModelMesh round = model_shade(ball, s);
    int outward = 0;
    for (std::size_t i = 0; i < round.positions.size(); ++i)
        if (dot(normalize(round.positions[i]), round.normals[i]) > 0.99f) ++outward;
    CHECK(outward == int(round.positions.size()));
    CHECK(round.vertex_count() < flat.vertex_count());
    CHECK(same_bits(round, model_shade(ball, s)));
}

// ---- generators -------------------------------------------------------------------------------------------------------------------------------

TEST_CASE("modifiers: lathe turns a profile into a closed solid") {
    ModelLatheParams p;
    p.profile = {{0, 0}, {0.5f, 0}, {0.5f, 1}, {0, 1}};
    p.segments = 24;
    const ModelMesh m = model_lathe(p);
    check_shape(m);
    check_closed(m, 0.5 * 24 * 0.25 * std::sin(2 * kPiD / 24), 1e-4);
    Vec3 lo, hi;
    bounds(m, lo, hi);
    CHECK(near(lo, {-0.5f, 0, -0.5f}, 1e-4f));
    CHECK(near(hi, {0.5f, 1, 0.5f}, 1e-4f));
    CHECK(same_bits(m, model_lathe(p)));

    // the profile given the other way round makes the same solid
    ModelLatheParams back = p;
    std::reverse(back.profile.begin(), back.profile.end());
    check_closed(model_lathe(back), volume(m), 1e-4);

    // an end off the axis is closed with a disc; without cap it is open
    ModelLatheParams ring;
    ring.profile = {{0.3f, 0}, {0.5f, 0}, {0.5f, 1}};
    ring.segments = 24;
    ring.cap = false;
    CHECK(model_mesh_stats(model_lathe(ring)).boundaryEdges > 0);
    ring.cap = true;
    check_closed(model_lathe(ring), 0.5 * 24 * std::sin(2 * kPiD / 24) * 0.25, 1e-3);  // the ends are extended to the axis: a solid cylinder
    // an outline that returns to its first point is turned as it is: a tube
    ring.profile = {{0.3f, 0}, {0.5f, 0}, {0.5f, 1}, {0.3f, 1}, {0.3f, 0}};
    const ModelMesh tube = model_lathe(ring);
    check_shape(tube);
    check_closed(tube, 0.5 * 24 * std::sin(2 * kPiD / 24) * (0.25 - 0.09), 1e-3);

    // half a turn closed with flat walls
    ModelLatheParams halfTurn = p;
    halfTurn.angle = 180;
    halfTurn.segments = 12;
    const ModelMesh h = model_lathe(halfTurn);
    check_shape(h);
    check_closed(h, volume(m) / 2.0, 1e-3);

    // a profile with a pole on the axis (a ball): one vertex there
    ModelLatheParams ball;
    for (int k = 0; k <= 8; ++k) ball.profile.push_back({0.5f * std::sin(float(kPiD) * float(k) / 8.0f), -0.5f * std::cos(float(kPiD) * float(k) / 8.0f)});
    ball.segments = 16;
    ball.creaseAngle = 60;
    const ModelMesh b = model_lathe(ball);
    check_shape(b);
    CHECK(model_mesh_stats(b).closed());
    CHECK(volume(b) > 0.4);
    CHECK(model_lathe({}).empty());
}

TEST_CASE("modifiers: sweep moves a profile along a path") {
    ModelSweepParams p;
    p.profile = {{-0.1f, -0.1f}, {0.1f, -0.1f}, {0.1f, 0.1f}, {-0.1f, 0.1f}};
    p.path = {{0, 0, 0}, {0, 2, 0}};
    const ModelMesh straight = ok(model_sweep(p));
    check_shape(straight);
    check_closed(straight, 0.08, 1e-4);
    Vec3 lo, hi;
    bounds(straight, lo, hi);
    CHECK(near(lo, {-0.1f, 0, -0.1f}, 1e-4f));
    CHECK(near(hi, {0.1f, 2, 0.1f}, 1e-4f));
    CHECK(same_bits(straight, ok(model_sweep(p))));

    // the profile drawn the other way round gives the same solid
    ModelSweepParams rev = p;
    std::reverse(rev.profile.begin(), rev.profile.end());
    check_closed(ok(model_sweep(rev)), 0.08, 1e-4);

    // a curved path and a profile scaled along it
    ModelSweepParams curved = p;
    curved.path = {{0, 0, 0}, {1, 1, 0}, {2, 0, 0}};
    curved.scaleEnd = 0.5f;
    const ModelMesh arc = ok(model_sweep(curved));
    check_shape(arc);
    CHECK(model_mesh_stats(arc).closed());
    CHECK(volume(arc) > 0.04);

    // straight pieces with mitred corners keep the thickness
    ModelSweepParams mitre = p;
    mitre.smooth = false;
    mitre.path = {{0, 0, 0}, {1, 0, 0}, {1, 0, 1}};
    const ModelMesh corner = ok(model_sweep(mitre));
    CHECK(model_mesh_stats(corner).closed());
    CHECK(volume(corner) == doctest::Approx(0.04 * 2.0).epsilon(0.1));

    // a ring: a closed path has no caps and makes a closed solid
    ModelSweepParams ring = p;
    ring.closed = true;
    ring.path = {{1, 0, 0}, {0, 0, 1}, {-1, 0, 0}, {0, 0, -1}};
    const ModelMesh torus = ok(model_sweep(ring));
    check_shape(torus);
    const ModelMeshStats ts = model_mesh_stats(torus);
    CHECK(ts.closed());
    CHECK(ts.volume == doctest::Approx(0.04 * 2 * kPiD).epsilon(0.08));

    // twist keeps the volume
    ModelSweepParams twisty = p;
    twisty.twist = 90;
    twisty.path = {{0, 0, 0}, {0, 1, 0}, {0, 2, 0}};
    check_closed(ok(model_sweep(twisty)), 0.08, 0.06);

    // errors teach
    ModelSweepParams few = p;
    few.profile.resize(2);
    CHECK_FALSE(model_sweep(few).ok());
    ModelSweepParams still = p;
    still.path = {{0, 0, 0}, {0, 0, 0}};
    auto r = model_sweep(still);
    REQUIRE_FALSE(r.ok());
    CHECK_FALSE(r.error().hint.empty());
}

TEST_CASE("modifiers: loft skins sections") {
    ModelLoftParams p;
    p.sections = {{{-0.5f, 0, -0.5f}, {0.5f, 0, -0.5f}, {0.5f, 0, 0.5f}, {-0.5f, 0, 0.5f}},
                  {{-0.25f, 1, -0.25f}, {0.25f, 1, -0.25f}, {0.25f, 1, 0.25f}, {-0.25f, 1, 0.25f}}};
    p.smooth = false;
    p.steps = 2;
    const ModelMesh m = ok(model_loft(p));
    check_shape(m);
    check_closed(m, (1 + 0.25 + 0.5) / 3.0, 1e-4);
    Vec3 lo, hi;
    bounds(m, lo, hi);
    CHECK(near(lo, {-0.5f, 0, -0.5f}, 1e-5f));
    CHECK(near(hi, {0.5f, 1, 0.5f}, 1e-5f));
    CHECK(same_bits(m, ok(model_loft(p))));

    // the sections wound the other way, or listed from the top, make the same solid
    ModelLoftParams rev = p;
    for (auto& section : rev.sections) std::reverse(section.begin(), section.end());
    check_closed(ok(model_loft(rev)), (1 + 0.25 + 0.5) / 3.0, 1e-4);
    ModelLoftParams top = p;
    std::reverse(top.sections.begin(), top.sections.end());
    check_closed(ok(model_loft(top)), (1 + 0.25 + 0.5) / 3.0, 1e-4);

    // three sections through a curve
    ModelLoftParams three = p;
    three.smooth = true;
    three.sections.push_back({{-0.5f, 2, -0.5f}, {0.5f, 2, -0.5f}, {0.5f, 2, 0.5f}, {-0.5f, 2, 0.5f}});
    const ModelMesh waist = ok(model_loft(three));
    check_shape(waist);
    CHECK(model_mesh_stats(waist).closed());
    bounds(waist, lo, hi);
    CHECK(lo.y == doctest::Approx(0.0f).epsilon(1e-4));
    CHECK(hi.y == doctest::Approx(2.0f).epsilon(1e-4));

    // an open ribbon
    ModelLoftParams ribbon;
    ribbon.closed = false;
    ribbon.sections = {{{0, 0, 0}, {1, 0, 0}}, {{0, 1, 0}, {1, 1, 0.5f}}};
    ribbon.steps = 1;
    const ModelMesh r = ok(model_loft(ribbon));
    CHECK(r.triangle_count() == 2);
    CHECK(model_mesh_stats(r).boundaryEdges > 0);

    ModelLoftParams bad = p;
    bad.sections[1].pop_back();
    auto err = model_loft(bad);
    REQUIRE_FALSE(err.ok());
    CHECK(err.error().message.find("section 1") != std::string::npos);
    CHECK(model_loft({}).ok() == false);
}

TEST_CASE("modifiers: modifiers can be chained and stay deterministic") {
    ModelBevelParams wide;
    wide.width = 0.15f;
    ModelNoiseParams gentle;
    gentle.amplitude = 0.01f;
    ModelMesh m = unit_box();
    m = ok(model_bevel(m, wide));
    m = model_subdivide(m, {});
    m = model_smooth(m, {});
    m = model_noise(m, gentle);
    m = model_mirror(m, {});
    check_shape(m, 0.15f);
    ModelMesh n = unit_box();
    n = ok(model_bevel(n, wide));
    n = model_subdivide(n, {});
    n = model_smooth(n, {});
    n = model_noise(n, gentle);
    n = model_mirror(n, {});
    CHECK(same_bits(m, n));
}
