// Signed-distance modelling: the field (shapes, smooth blends, mirror, transforms), meshing (closed, manifold, outward, accurate), parts and
// colours per triangle, decimation, determinism, the cost bound, noise, and the `sdf` node in model documents (docs/MODELING.md).
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <numbers>

#include "fa/core/json_schema.h"
#include "fa/scene/model_decimate.h"
#include "fa/scene/model_doc.h"
#include "fa/scene/model_sdf.h"

using namespace fa;

namespace {

Json J(const char* text) { return parse_json(text, "test").value(); }

ModelSdfShapeParams sphere(float r) {
    ModelSdfShapeParams s;
    s.shape = ModelSdfShape::Sphere;
    s.radius = r;
    return s;
}

int add_sphere(ModelSdf& sdf, float r, Vec3 at, ModelSdfBlend blend = ModelSdfBlend::Union, float smooth = 0, std::uint32_t group = 0,
               std::optional<Vec4> color = std::nullopt) {
    return sdf.add_shape(sphere(r), Mat4::translate(at), blend, smooth, group, color);
}

ModelSdf one_sphere(float r) {
    ModelSdf sdf;
    sdf.set_root(add_sphere(sdf, r, {0, 0, 0}));
    return sdf;
}

ModelSdf joined(const std::vector<int>& kids, ModelSdf sdf) {
    sdf.set_root(sdf.add_group(kids, Mat4::identity(), ModelSdfBlend::Union, 0, -1));
    return sdf;
}

ModelMesh mesh_of(const ModelSdf& sdf, ModelSdfMeshParams p = {}, ModelSdfMeshInfo* info = nullptr) {
    auto made = model_sdf_mesh(sdf, p, info);
    REQUIRE_MESSAGE(made.ok(), (made.ok() ? std::string() : made.error().to_string()));
    return std::move(*made);
}

bool same_bits(const ModelMesh& a, const ModelMesh& b) {
    return a.positions.size() == b.positions.size() && a.indices == b.indices && a.triParts == b.triParts &&
           std::memcmp(a.positions.data(), b.positions.data(), a.positions.size() * sizeof(Vec3)) == 0 &&
           std::memcmp(a.normals.data(), b.normals.data(), a.normals.size() * sizeof(Vec3)) == 0 &&
           std::memcmp(a.uvs.data(), b.uvs.data(), a.uvs.size() * sizeof(Vec2)) == 0 &&
           std::memcmp(a.colors.data(), b.colors.data(), a.colors.size() * sizeof(Vec4)) == 0;
}

Result<ModelBuild> build_doc(const char* text) {
    auto doc = parse_model_doc(J(text), "t.model.json");
    REQUIRE_MESSAGE(doc.ok(), (doc.ok() ? std::string() : doc.error().to_string()));
    return evaluate_model(*doc);
}

std::vector<ModelIssue> issues_of(const char* text) {
    std::vector<ModelIssue> issues;
    (void)parse_model_doc(J(text), "t.model.json", &issues);
    return issues;
}

bool has_issue(const std::vector<ModelIssue>& issues, const std::string& pointer, const std::string& messagePart) {
    for (const ModelIssue& i : issues)
        if (i.pointer == pointer && i.message.find(messagePart) != std::string::npos) return true;
    return false;
}

}  // namespace

TEST_CASE("sdf field: the shapes are exact distances where they should be") {
    auto dist = [](const ModelSdfShapeParams& s, Vec3 p) {
        ModelSdf sdf;
        sdf.set_root(sdf.add_shape(s, Mat4::identity(), ModelSdfBlend::Union, 0, 0, std::nullopt));
        return sdf.distance(p);
    };
    CHECK(dist(sphere(1), {3, 0, 0}) == doctest::Approx(2));
    CHECK(dist(sphere(1), {0, 0, 0}) == doctest::Approx(-1));
    CHECK(dist(sphere(1), {0.5f, 0, 0}) == doctest::Approx(-0.5f));

    ModelSdfShapeParams cap;
    cap.shape = ModelSdfShape::Capsule;
    cap.radius = 0.25f;
    cap.height = 2;  // balls at y = -0.75 and +0.75
    CHECK(dist(cap, {0, 1.5f, 0}) == doctest::Approx(0.5f));
    CHECK(dist(cap, {1, 0, 0}) == doctest::Approx(0.75f));
    CHECK(dist(cap, {0, 0, 0}) == doctest::Approx(-0.25f));
    cap.radiusTop = 0.1f;  // a round cone: tip to tip is still 2, centred between the ball centres (-0.825 and +0.825), so the tips are at -1.075 and 0.925
    CHECK(std::fabs(dist(cap, {0, 0.925f, 0})) < 1e-5f);
    CHECK(std::fabs(dist(cap, {0, -1.075f, 0})) < 1e-5f);
    CHECK(dist(cap, {0.2f, 0.825f, 0}) > 0);  // the top ball is thinner than the bottom one

    ModelSdfShapeParams box;
    box.shape = ModelSdfShape::Box;
    box.size = {2, 2, 2};
    CHECK(dist(box, {3, 0, 0}) == doctest::Approx(2));
    CHECK(dist(box, {0, 0, 0}) == doctest::Approx(-1));
    CHECK(dist(box, {2, 2, 0}) == doctest::Approx(std::sqrt(2.0f)));
    box.round = 0.5f;  // the corner is rounded off: the point (1, 1, 1) is now outside
    CHECK(dist(box, {1, 1, 1}) > 0.1f);
    CHECK(dist(box, {1, 0, 0}) == doctest::Approx(0));

    ModelSdfShapeParams cyl;
    cyl.shape = ModelSdfShape::Cylinder;
    cyl.radius = 0.5f;
    cyl.height = 2;
    CHECK(dist(cyl, {1.5f, 0, 0}) == doctest::Approx(1));
    CHECK(dist(cyl, {0, 2, 0}) == doctest::Approx(1));
    CHECK(dist(cyl, {0, 0, 0}) == doctest::Approx(-0.5f));

    ModelSdfShapeParams cone;
    cone.shape = ModelSdfShape::Cone;
    cone.radius = 1;
    cone.radiusTop = 0;
    cone.height = 2;  // base at y = -1, tip at y = +1
    CHECK(dist(cone, {0, 1.5f, 0}) == doctest::Approx(0.5f));
    CHECK(dist(cone, {0, -1.5f, 0}) == doctest::Approx(0.5f));
    CHECK(dist(cone, {0, 0, 0}) < 0);
    CHECK(dist(cone, {0.9f, 0.9f, 0}) > 0);  // beside the tip, outside

    ModelSdfShapeParams torus;
    torus.shape = ModelSdfShape::Torus;
    torus.radius = 1;
    torus.tube = 0.25f;
    CHECK(dist(torus, {1, 0, 0}) == doctest::Approx(-0.25f));
    CHECK(dist(torus, {0, 0, 0}) == doctest::Approx(0.75f));
    CHECK(dist(torus, {0, 0.25f, 1}) == doctest::Approx(0).epsilon(0.001).scale(1.0));

    ModelSdfShapeParams ell;
    ell.shape = ModelSdfShape::Ellipsoid;
    ell.size = {2, 1, 1};
    CHECK(std::fabs(dist(ell, {2, 0, 0})) < 1e-4f);
    CHECK(std::fabs(dist(ell, {0, 1, 0})) < 1e-4f);
    CHECK(dist(ell, {0, 0, 0}) < 0);
    CHECK(dist(ell, {3, 0, 0}) > 0);
}

TEST_CASE("sdf field: node transforms move, turn and scale a shape; a group mirrors") {
    ModelSdf sdf;
    sdf.set_root(sdf.add_shape(sphere(1), Mat4::trs({5, 0, 0}, {0, 0, 0}, {2, 2, 2}), ModelSdfBlend::Union, 0, 0, std::nullopt));
    CHECK(sdf.distance({5, 0, 0}) == doctest::Approx(-2));
    CHECK(sdf.distance({9, 0, 0}) == doctest::Approx(2));

    ModelSdf mirrored;
    const int s = add_sphere(mirrored, 0.5f, {2, 0, 0});
    mirrored.set_root(mirrored.add_group({s}, Mat4::identity(), ModelSdfBlend::Union, 0, 0));
    CHECK(mirrored.distance({2, 0, 0}) == doctest::Approx(-0.5f));
    CHECK(mirrored.distance({-2, 0, 0}) == doctest::Approx(-0.5f));
    CHECK(mirrored.distance({0, 2, 0}) == doctest::Approx(std::sqrt(8.0f) - 0.5f));
}

TEST_CASE("sdf field: union, subtraction and intersection, hard and smooth") {
    auto two = [](ModelSdfBlend blend, float smooth) {
        ModelSdf sdf;
        const int a = add_sphere(sdf, 1, {-0.6f, 0, 0});
        const int b = add_sphere(sdf, 1, {0.6f, 0, 0}, blend, smooth);
        return joined({a, b}, std::move(sdf));
    };
    const ModelSdf hardUnion = two(ModelSdfBlend::Union, 0), softUnion = two(ModelSdfBlend::Union, 0.5f);
    CHECK(hardUnion.distance({0, 0.9f, 0}) == doctest::Approx(std::min(std::sqrt(0.36f + 0.81f) - 1, std::sqrt(0.36f + 0.81f) - 1)));
    CHECK(hardUnion.distance({0, 0, 0}) == doctest::Approx(-0.4f));
    // a smooth union is never above the hard one and fills the crease between the balls
    for (Vec3 p : {Vec3{0, 0.9f, 0}, Vec3{0, 1.1f, 0}, Vec3{0, 0, 1.2f}, Vec3{3, 0, 0}})
        CHECK(softUnion.distance(p) <= hardUnion.distance(p) + 1e-5f);
    CHECK(softUnion.distance({0, 0.95f, 0}) < hardUnion.distance({0, 0.95f, 0}) - 0.01f);
    // far from the join it is the same
    CHECK(softUnion.distance({-3, 0, 0}) == doctest::Approx(hardUnion.distance({-3, 0, 0})).epsilon(1e-4));

    const ModelSdf cut = two(ModelSdfBlend::Subtract, 0);
    CHECK(cut.distance({-1.4f, 0, 0}) < 0);   // far side of the first ball is kept
    CHECK(cut.distance({0.6f, 0, 0}) > 0);    // the middle of the cutter is gone
    CHECK(cut.distance({0, 0, 0}) > 0);       // and so is the overlap
    const ModelSdf common = two(ModelSdfBlend::Intersect, 0);
    CHECK(common.distance({0, 0, 0}) < 0);
    CHECK(common.distance({-1.4f, 0, 0}) > 0);
    CHECK(common.distance({1.4f, 0, 0}) > 0);

    // a smooth subtraction rounds the cut: the rim lies farther from the cutter than with a hard edge
    const ModelSdf softCut = two(ModelSdfBlend::Subtract, 0.4f);
    CHECK(softCut.distance({-0.05f, 0.75f, 0}) >= cut.distance({-0.05f, 0.75f, 0}) - 1e-5f);
}

TEST_CASE("sdf field: bounds contain the inside; an empty field says so") {
    ModelSdf sdf;
    const int a = add_sphere(sdf, 1, {-2, 0, 0});
    const int b = add_sphere(sdf, 0.5f, {2, 1, 0});
    sdf = joined({a, b}, std::move(sdf));
    Vec3 lo, hi;
    REQUIRE(sdf.bounds(lo, hi));
    CHECK(lo.x <= -3.0f);
    CHECK(hi.x >= 2.5f);
    CHECK(hi.y >= 1.5f);
    CHECK(lo.y <= -1.0f);
    ModelSdf none;
    CHECK(none.empty());
    CHECK_FALSE(none.bounds(lo, hi));
}

TEST_CASE("sdf mesh: a sphere is a closed manifold with outward normals and the right radius") {
    const ModelSdf sdf = one_sphere(1);
    ModelSdfMeshInfo info;
    ModelMesh m = mesh_of(sdf, {}, &info);
    const ModelMeshStats st = model_mesh_stats(m);
    CHECK(st.closed());
    CHECK(st.boundaryEdges == 0);
    CHECK(st.nonManifoldEdges == 0);
    CHECK(st.degenerateTriangles == 0);
    CHECK(st.volume > 0);
    CHECK(st.volume == doctest::Approx(4.0 / 3.0 * std::numbers::pi).epsilon(0.02));
    CHECK(info.triangles == m.triangle_count());
    CHECK(info.rawTriangles >= info.triangles);
    CHECK_FALSE(info.touchedEdge);

    float worst = 0, worstNormal = 1;
    for (std::size_t i = 0; i < m.positions.size(); ++i) {
        worst = std::max(worst, std::fabs(length(m.positions[i]) - 1.0f));
        worstNormal = std::min(worstNormal, dot(m.normals[i], normalize(m.positions[i])));
        CHECK(length(m.normals[i]) == doctest::Approx(1).epsilon(1e-3));
    }
    CHECK(worst < 0.5f * info.voxelSize);   // decimation (error limit: a quarter of a cell) may move a vertex a little
    CHECK(worstNormal > 0.97f);             // the gradient of the field: smooth and pointing out
    CHECK(m.uvs.size() == m.positions.size());
}

TEST_CASE("sdf mesh: the resolution follows voxelSize or cells, and a finer one is more accurate") {
    const ModelSdf sdf = one_sphere(1);
    ModelSdfMeshParams coarse, fine;
    coarse.voxelSize = 0.2f;
    fine.voxelSize = 0.05f;
    coarse.maxError = fine.maxError = 0;  // no decimation: compare the raw surfaces
    ModelSdfMeshInfo ci, fi;
    const ModelMesh a = mesh_of(sdf, coarse, &ci), b = mesh_of(sdf, fine, &fi);
    CHECK(ci.voxelSize == doctest::Approx(0.2f));
    CHECK(fi.voxelSize == doctest::Approx(0.05f));
    CHECK(b.triangle_count() > a.triangle_count() * 8);
    auto radius_error = [](const ModelMesh& m) {
        float e = 0;
        for (const Vec3& p : m.positions) e = std::max(e, std::fabs(length(p) - 1.0f));
        return e;
    };
    // vertices are moved onto the zero of the field along their cell edge (kept 5% of a cell off the grid points), so even a coarse mesh has its vertices on the surface
    CHECK(radius_error(a) < 0.1f * 0.2f);
    CHECK(radius_error(b) < 0.1f * 0.05f);
    CHECK(radius_error(b) < radius_error(a));
    CHECK(model_mesh_stats(a).closed());
    CHECK(model_mesh_stats(b).closed());

    ModelSdfMeshParams cells;
    cells.cells = 30;
    ModelSdfMeshInfo ki;
    (void)mesh_of(sdf, cells, &ki);
    CHECK(ki.gridX >= 30);
    CHECK(ki.gridX <= 40);
}

TEST_CASE("sdf mesh: smooth union is one closed surface, and a hard subtraction makes a closed manifold with a hole") {
    ModelSdf blob;
    const int a = add_sphere(blob, 1, {-0.7f, 0, 0});
    const int b = add_sphere(blob, 1, {0.7f, 0, 0}, ModelSdfBlend::Union, 0.5f);
    blob = joined({a, b}, std::move(blob));
    ModelMesh m = mesh_of(blob);
    ModelMeshStats st = model_mesh_stats(m);
    CHECK(st.closed());
    CHECK(st.volume > 0);

    ModelSdf ring;
    const int body = ring.add_shape(sphere(1), Mat4::identity(), ModelSdfBlend::Union, 0, 0, std::nullopt);
    ModelSdfShapeParams cyl;
    cyl.shape = ModelSdfShape::Cylinder;
    cyl.radius = 0.4f;
    cyl.height = 4;
    const int bore = ring.add_shape(cyl, Mat4::identity(), ModelSdfBlend::Subtract, 0, 0, std::nullopt);
    ring = joined({body, bore}, std::move(ring));
    m = mesh_of(ring);
    st = model_mesh_stats(m);
    CHECK(st.closed());
    CHECK(st.volume > 0);
    // the bore removes pi r^2 h of the ball: 4/3 pi - (2 pi/3 (3 R^2 ... cap)) is simpler to bound: it is less than the ball and more than half
    CHECK(st.volume < 4.0 / 3.0 * std::numbers::pi);
    CHECK(st.volume > 2.0);
    // a torus has a hole through it and is still a closed manifold
    ModelSdf t;
    ModelSdfShapeParams torus;
    torus.shape = ModelSdfShape::Torus;
    torus.radius = 1;
    torus.tube = 0.3f;
    t.set_root(t.add_shape(torus, Mat4::identity(), ModelSdfBlend::Union, 0, 0, std::nullopt));
    st = model_mesh_stats(mesh_of(t));
    CHECK(st.closed());
    CHECK(st.volume == doctest::Approx(2.0 * std::numbers::pi * std::numbers::pi * 1.0 * 0.09).epsilon(0.03));
}

TEST_CASE("sdf mesh: a shape too thin for a cell can vanish, and nothing left is an empty mesh, not an error") {
    ModelSdf sdf;
    const int a = add_sphere(sdf, 1, {0, 0, 0});
    const int b = add_sphere(sdf, 2, {0, 0, 0}, ModelSdfBlend::Subtract);
    sdf = joined({a, b}, std::move(sdf));
    auto made = model_sdf_mesh(sdf, {});
    REQUIRE(made.ok());
    CHECK(made->empty());
}

TEST_CASE("sdf mesh: every triangle belongs to the part of the shape that owns it, and colours melt across a blend") {
    ModelSdf sdf;
    const int a = add_sphere(sdf, 1, {-0.8f, 0, 0}, ModelSdfBlend::Union, 0, 3, Vec4{1, 0, 0, 1});
    const int b = add_sphere(sdf, 1, {0.8f, 0, 0}, ModelSdfBlend::Union, 0.4f, 5, Vec4{0, 0, 1, 1});
    sdf = joined({a, b}, std::move(sdf));
    REQUIRE(sdf.has_color());
    REQUIRE(sdf.has_several_groups());
    ModelMesh m = mesh_of(sdf);
    REQUIRE(m.triParts.size() == m.triangle_count());
    std::size_t left = 0, right = 0;
    for (std::size_t t = 0; t < m.triangle_count(); ++t) {
        const Vec3 c = (m.positions[m.indices[t * 3]] + m.positions[m.indices[t * 3 + 1]] + m.positions[m.indices[t * 3 + 2]]) / 3.0f;
        CHECK((m.triParts[t] == 3 || m.triParts[t] == 5));
        if (std::fabs(c.x) > 1.3f) CHECK(m.triParts[t] == (c.x < 0 ? 3u : 5u));  // far from the join the owner is obvious
        (m.triParts[t] == 3 ? left : right)++;
    }
    CHECK(left > 100);
    CHECK(right > 100);
    // the colour of a vertex far to the left is red, far to the right blue, and at the join a mix
    REQUIRE(m.colors.size() == m.positions.size());
    bool mixed = false;
    for (std::size_t i = 0; i < m.positions.size(); ++i) {
        const Vec3 p = m.positions[i];
        if (p.x < -1.6f) CHECK(m.colors[i].x > 0.95f);
        if (p.x > 1.6f) CHECK(m.colors[i].z > 0.95f);
        if (std::fabs(p.x) < 0.1f && m.colors[i].x > 0.2f && m.colors[i].z > 0.2f) mixed = true;
    }
    CHECK(mixed);
    // the part boundary closes round: the parts together are still one closed surface
    CHECK(model_mesh_stats(m).closed());
}

TEST_CASE("sdf mesh: decimation reaches the target, keeps the surface closed and the parts apart") {
    ModelSdf sdf;
    const int a = add_sphere(sdf, 1, {-0.9f, 0, 0}, ModelSdfBlend::Union, 0, 1);
    const int b = add_sphere(sdf, 0.8f, {0.9f, 0, 0}, ModelSdfBlend::Union, 0.3f, 2);
    sdf = joined({a, b}, std::move(sdf));
    ModelSdfMeshParams raw;
    raw.maxError = 0;
    const ModelMesh full = mesh_of(sdf, raw);
    const ModelMeshStats fullStats = model_mesh_stats(full);
    for (auto [target, tolerance] : {std::pair<std::size_t, double>{2000, 0.02}, {500, 0.05}, {150, 0.12}}) {
        ModelSdfMeshParams p;
        p.targetTriangles = target;
        ModelSdfMeshInfo info;
        const ModelMesh m = mesh_of(sdf, p, &info);
        const ModelMeshStats st = model_mesh_stats(m);
        CAPTURE(target);
        CHECK(st.closed());
        CHECK(m.triangle_count() <= target + target / 10 + 8);
        CHECK(m.triangle_count() >= target / 2);
        CHECK(st.volume == doctest::Approx(fullStats.volume).epsilon(tolerance));
        CHECK(info.rawTriangles > m.triangle_count());
        std::size_t one = 0, two = 0;
        for (std::uint32_t part : m.triParts) (part == 1 ? one : two)++;
        CHECK(one > 0);
        CHECK(two > 0);
        // the part boundary still runs between the balls: the left part keeps its far end, the right part its own
        for (std::size_t t = 0; t < m.triangle_count(); ++t) {
            const Vec3 c = (m.positions[m.indices[t * 3]] + m.positions[m.indices[t * 3 + 1]] + m.positions[m.indices[t * 3 + 2]]) / 3.0f;
            if (c.x < -1.4f) CHECK(m.triParts[t] == 1u);
            if (c.x > 1.4f) CHECK(m.triParts[t] == 2u);
        }
    }
    // an error limit alone also decimates, and never more than the limit allows
    ModelSdfMeshParams byError;
    byError.maxError = 0.01f;
    ModelSdfMeshInfo ei;
    const ModelMesh reduced = mesh_of(sdf, byError, &ei);
    CHECK(reduced.triangle_count() < full.triangle_count());
    CHECK(model_mesh_stats(reduced).closed());
}

TEST_CASE("sdf mesh: decimation on its own works on a plain welded mesh") {
    // a box: eight welded corners, 12 triangles, nothing to collapse without opening it up -> stays closed and does not grow
    std::vector<Vec3> pos = {{0, 0, 0}, {1, 0, 0}, {1, 1, 0}, {0, 1, 0}, {0, 0, 1}, {1, 0, 1}, {1, 1, 1}, {0, 1, 1}};
    std::vector<std::uint32_t> idx = {0, 2, 1, 0, 3, 2, 4, 5, 6, 4, 6, 7, 0, 1, 5, 0, 5, 4, 3, 7, 6, 3, 6, 2, 0, 4, 7, 0, 7, 3, 1, 2, 6, 1, 6, 5};
    std::vector<std::uint32_t> parts;
    ModelDecimateParams p;
    p.targetTriangles = 4;
    p.maxError = 0.0001;
    const ModelDecimateStats s = model_decimate(pos, idx, parts, p);
    CHECK(s.trianglesBefore == 12);
    CHECK(s.trianglesAfter == idx.size() / 3);
    CHECK(s.trianglesAfter >= 4);
    CHECK(s.trianglesAfter <= 12);
    for (std::uint32_t i : idx) CHECK(i < pos.size());
}

TEST_CASE("decimation: a big flat region collapses evenly, keeps its border and does not pile up in one vertex") {
    const int n = 120;  // a flat grid of n x n quads, 28800 triangles
    std::vector<Vec3> pos;
    std::vector<std::uint32_t> idx, parts;
    for (int y = 0; y <= n; ++y)
        for (int x = 0; x <= n; ++x) pos.push_back({float(x), float(y), 0});
    for (int y = 0; y < n; ++y)
        for (int x = 0; x < n; ++x) {
            const std::uint32_t a = std::uint32_t(y * (n + 1) + x), b = a + 1, c = a + std::uint32_t(n + 1), d = c + 1;
            for (std::uint32_t v : {a, b, d, a, d, c}) idx.push_back(v);
        }
    ModelDecimateParams p;
    p.targetTriangles = 1200;  // the border alone is 480 vertices: an open border is never merged along, so a lower target cannot be reached
    const ModelDecimateStats s = model_decimate(pos, idx, parts, p);
    CHECK(s.trianglesBefore == 28800);
    CHECK(s.trianglesAfter <= 1200);
    CHECK(s.trianglesAfter >= 480);
    CHECK(s.maxErrorReached < 1e-2);  // a plane loses nothing (the simplifier measures in float: noise of a few 1e-3 on a 120 m grid)
    // the corners and the border survive: nothing left outside the square, the four corners are still there
    int corners = 0;
    std::vector<int> valence(pos.size(), 0);
    for (std::uint32_t i : idx) ++valence[i];
    int worst = 0;
    for (std::size_t v = 0; v < pos.size(); ++v) {
        CHECK(pos[v].z == 0);
        CHECK(pos[v].x >= 0);
        CHECK(pos[v].x <= float(n));
        if ((pos[v].x == 0 || pos[v].x == float(n)) && (pos[v].y == 0 || pos[v].y == float(n))) ++corners;
        worst = std::max(worst, valence[v]);
    }
    CHECK(corners == 4);
    CHECK(worst < 40);  // triangle corners per vertex: no hub
}

TEST_CASE("sdf mesh: the same field gives the same bits, and different noise seeds do not") {
    ModelSdf sdf;
    const int a = add_sphere(sdf, 1, {-0.5f, 0, 0}, ModelSdfBlend::Union, 0, 0, Vec4{0.5f, 0.4f, 0.3f, 1});
    const int b = add_sphere(sdf, 0.7f, {0.6f, 0.3f, 0}, ModelSdfBlend::Union, 0.3f, 1, Vec4{0.2f, 0.6f, 0.3f, 1});
    sdf = joined({a, b}, std::move(sdf));
    ModelSdfMeshParams p;
    p.targetTriangles = 800;
    p.noiseAmplitude = 0.08f;
    p.noiseSeed = 4;
    const ModelMesh one = mesh_of(sdf, p), again = mesh_of(sdf, p);
    CHECK(same_bits(one, again));
    p.noiseSeed = 5;
    const ModelMesh other = mesh_of(sdf, p);
    CHECK_FALSE(same_bits(one, other));
    CHECK(model_mesh_stats(other).closed());
}

TEST_CASE("sdf mesh: noise roughens the surface by about its amplitude and stays closed") {
    const ModelSdf sdf = one_sphere(1);
    ModelSdfMeshParams p;
    p.noiseAmplitude = 0.1f;
    p.noiseFrequency = 2;
    p.noiseOctaves = 3;
    p.maxError = 0;
    const ModelMesh m = mesh_of(sdf, p);
    CHECK(model_mesh_stats(m).closed());
    float lo = 10, hi = 0;
    for (const Vec3& v : m.positions) {
        lo = std::min(lo, length(v));
        hi = std::max(hi, length(v));
    }
    CHECK(hi - lo > 0.03f);
    CHECK(hi - lo < 0.45f);  // never more than twice the amplitude on each side
    // the noise function is in -1..1 and the same wherever it is asked
    for (int k = 0; k < 50; ++k) {
        const Vec3 q{0.37f * float(k), 0.11f * float(k) - 2, 0.23f * float(k) + 1};
        const float v = model_sdf_noise(q, 2, 3, 4);
        CHECK(v >= -1.001f);
        CHECK(v <= 1.001f);
        CHECK(v == model_sdf_noise(q, 2, 3, 4));
    }
}

TEST_CASE("sdf mesh: a request that would cost too much is refused with the voxel size that fits") {
    const ModelSdf sdf = one_sphere(50);
    ModelSdfMeshParams p;
    p.voxelSize = 0.01f;
    auto made = model_sdf_mesh(sdf, p);
    REQUIRE_FALSE(made.ok());
    CHECK(made.error().message.find("points") != std::string::npos);
    CHECK(made.error().hint.find("voxelSize") != std::string::npos);

    // many shapes at a fine grid hit the evaluation cost bound
    ModelSdf many;
    std::vector<int> kids;
    for (int i = 0; i < 400; ++i) kids.push_back(add_sphere(many, 0.5f, {float(i % 20) * 0.3f, float(i / 20) * 0.3f, 0}, ModelSdfBlend::Union, 0.1f));
    many = joined(kids, std::move(many));
    ModelSdfMeshParams fine;
    fine.voxelSize = 0.01f;
    CHECK_FALSE(model_sdf_mesh(many, fine).ok());
}

TEST_CASE("sdf node: a document with sdf children makes a closed mesh with parts and materials") {
    auto built = build_doc(R"({"format":"factoria.model/1",
        "materials":{"skin":{"color":[0.8,0.6,0.5,1]},"eye":{"color":[0,0,0,1]}},
        "nodes":[{"op":"sdf","id":"blob","children":[
            {"op":"sdf_ellipsoid","radii":[0.6,0.45,0.5],"part":"body","material":"skin"},
            {"op":"sdf_sphere","radius":0.3,"position":[0.5,0.2,0],"part":"head","material":"skin","smooth":0.2},
            {"op":"sdf_sphere","radius":0.06,"position":[0.75,0.3,0.12],"part":"eye","material":"eye"}]}]})");
    REQUIRE(built.ok());
    CHECK(built->stats.closed());
    CHECK(built->stats.triangles > 200);
    CHECK(built->stats.triangles < 20000);
    std::vector<std::string> parts;
    for (const ModelPartInfo& p : built->parts) parts.push_back(p.part);
    CHECK(std::find(parts.begin(), parts.end(), "body") != parts.end());
    CHECK(std::find(parts.begin(), parts.end(), "head") != parts.end());
    CHECK(std::find(parts.begin(), parts.end(), "eye") != parts.end());
    auto again = build_doc(R"({"format":"factoria.model/1","materials":{"skin":{"color":[0.8,0.6,0.5,1]},"eye":{"color":[0,0,0,1]}},
        "nodes":[{"op":"sdf","id":"blob","children":[
            {"op":"sdf_ellipsoid","radii":[0.6,0.45,0.5],"part":"body","material":"skin"},
            {"op":"sdf_sphere","radius":0.3,"position":[0.5,0.2,0],"part":"head","material":"skin","smooth":0.2},
            {"op":"sdf_sphere","radius":0.06,"position":[0.75,0.3,0.12],"part":"eye","material":"eye"}]}]})");
    REQUIRE(again.ok());
    REQUIRE(built->data.positions.size() == again->data.positions.size());
    CHECK(std::memcmp(built->data.positions.data(), again->data.positions.data(), built->data.positions.size() * sizeof(float)) == 0);
    CHECK(std::memcmp(built->data.normals.data(), again->data.normals.data(), built->data.normals.size() * sizeof(float)) == 0);
}

TEST_CASE("sdf node: align, the node transform and a group with mirror") {
    auto stand = build_doc(R"({"format":"factoria.model/1","nodes":[{"op":"sdf","align":"bottom","position":[0,2,0],"children":[{"op":"sdf_sphere","radius":0.5}]}]})");
    REQUIRE(stand.ok());
    CHECK(stand->stats.bmin.y == doctest::Approx(2.0f).epsilon(0.001));
    auto pair = build_doc(R"({"format":"factoria.model/1","nodes":[{"op":"sdf","children":[
        {"op":"sdf_group","mirror":"x","children":[{"op":"sdf_sphere","radius":0.3,"position":[0.8,0,0]}]}]}]})");
    REQUIRE(pair.ok());
    CHECK(pair->stats.closed());
    CHECK(pair->stats.bmin.x == doctest::Approx(-1.1f).epsilon(0.03));
    CHECK(pair->stats.bmax.x == doctest::Approx(1.1f).epsilon(0.03));
    // two balls: the surface is two closed pieces but each is manifold
    CHECK(pair->stats.nonManifoldEdges == 0);
}

TEST_CASE("sdf node: it is a mesh like any other, so modifiers wrap it and booleans take it") {
    auto mirrored = build_doc(R"({"format":"factoria.model/1","nodes":[{"op":"mirror","axis":"x","children":[
        {"op":"sdf","position":[1,0,0],"children":[{"op":"sdf_sphere","radius":0.5}]}]}]})");
    REQUIRE(mirrored.ok());
    CHECK(mirrored->stats.bmin.x < -1.4f);
    CHECK(mirrored->stats.bmax.x > 1.4f);
    auto cut = build_doc(R"({"format":"factoria.model/1","nodes":[{"op":"boolean","mode":"difference","children":[
        {"op":"sdf","children":[{"op":"sdf_sphere","radius":0.6}]},
        {"op":"box","size":[0.46,2,0.46]}]}]})");
    REQUIRE_MESSAGE(cut.ok(), (cut.ok() ? std::string() : cut.error().to_string()));
    CHECK(cut->stats.closed());
    auto whole = build_doc(R"({"format":"factoria.model/1","nodes":[{"op":"sdf","children":[{"op":"sdf_sphere","radius":0.6}]}]})");
    REQUIRE(whole.ok());
    CHECK(whole->stats.closed());
    CHECK(cut->stats.volume < whole->stats.volume);
    auto smoothed = build_doc(R"({"format":"factoria.model/1","nodes":[{"op":"subdivide","levels":1,"children":[
        {"op":"sdf","quality":"draft","children":[{"op":"sdf_sphere","radius":0.6}]}]}]})");
    REQUIRE(smoothed.ok());
    CHECK(smoothed->stats.triangles > 0);
}

TEST_CASE("sdf node: mistakes name the pointer and teach") {
    // a shape outside an sdf, and something else inside one
    auto out = issues_of(R"({"format":"factoria.model/1","nodes":[{"op":"sdf_sphere"}]})");
    CHECK(has_issue(out, "/nodes/0/op", "works only inside"));
    auto in = issues_of(R"({"format":"factoria.model/1","nodes":[{"op":"sdf","children":[{"op":"box"}]}]})");
    CHECK(has_issue(in, "/nodes/0/children/0/op", "cannot go inside"));
    auto nested = issues_of(R"({"format":"factoria.model/1","nodes":[{"op":"sdf","children":[{"op":"sdf_group","children":[{"op":"group"}]}]}]})");
    CHECK(has_issue(nested, "/nodes/0/children/0/children/0/op", "cannot go inside"));
    // shape rules
    CHECK(has_issue(issues_of(R"({"format":"factoria.model/1","nodes":[{"op":"sdf","children":[{"op":"sdf_capsule","radius":1,"height":1}]}]})"),
                    "/nodes/0/children/0/height", "do not fit"));
    CHECK(has_issue(issues_of(R"({"format":"factoria.model/1","nodes":[{"op":"sdf","children":[{"op":"sdf_torus","radius":0.2,"tube":0.5}]}]})"),
                    "/nodes/0/children/0/tube", "tube"));
    CHECK(has_issue(issues_of(R"({"format":"factoria.model/1","nodes":[{"op":"sdf","children":[{"op":"sdf_box","size":[1,1,1],"round":0.9}]}]})"),
                    "/nodes/0/children/0/round", "half"));
    CHECK(has_issue(issues_of(R"({"format":"factoria.model/1","nodes":[{"op":"sdf","children":[{"op":"sdf_sphere","blend":"unite"}]}]})"),
                    "/nodes/0/children/0/blend", ""));
    CHECK(has_issue(issues_of(R"({"format":"factoria.model/1","nodes":[{"op":"sdf","children":[{"op":"sdf_sphere","radius":-1}]}]})"),
                    "/nodes/0/children/0/radius", ""));
    // an sdf without shapes reads fine and fails to evaluate, naming the node
    auto empty = build_doc(R"({"format":"factoria.model/1","nodes":[{"op":"sdf","id":"nothing","children":[]}]})");
    REQUIRE_FALSE(empty.ok());
    CHECK(empty.error().message.find("/nodes/0") != std::string::npos);
    CHECK(empty.error().message.find("at least one") != std::string::npos);
    // a request that costs too much names the node and the fix
    auto huge = build_doc(R"({"format":"factoria.model/1","nodes":[{"op":"sdf","voxelSize":0.001,"children":[{"op":"sdf_sphere","radius":20}]}]})");
    REQUIRE_FALSE(huge.ok());
    CHECK(huge.error().message.find("/nodes/0") != std::string::npos);
    CHECK(huge.error().message.find("voxelSize") != std::string::npos);
    // the schema lists the new nodes
    const Json schema = model_doc_schema();
    CHECK(schema["$defs"].contains("sdf"));
    CHECK(schema["$defs"].contains("sdf_torus"));
    CHECK(schema["$defs"]["sdf"]["properties"].contains("align"));
    CHECK_FALSE(schema["$defs"]["sdf_sphere"]["properties"].contains("align"));
}
