// model_import_clean (fa/scene/model_import_clean.h): a deliberately dirty mesh - duplicate vertices, floating bits, an offset, the wrong
// scale, a flipped triangle, a hole - comes out welded, recentred, scaled, closed and within budget, with a report that says so.
#include <doctest.h>

#include <cmath>

#include "fa/scene/model_import_clean.h"
#include "fa/scene/model_kernel.h"

using namespace fa;

namespace {

// A box 100 x 180 x 100 (centimetres) as 12 triangles of a soup (36 vertices, nothing shared), moved 300 along x, with the sixth
// triangle turned inside out and a tetrahedron speck 4 m above it.
MeshData dirty_cube(bool withSpeck = true, bool flip = true) {
    const float P[8][3] = {{-50, 0, -50}, {50, 0, -50}, {50, 180, -50}, {-50, 180, -50}, {-50, 0, 50}, {50, 0, 50}, {50, 180, 50}, {-50, 180, 50}};
    const int F[12][3] = {{0, 2, 1}, {0, 3, 2}, {4, 5, 6}, {4, 6, 7}, {0, 1, 5}, {0, 5, 4}, {2, 3, 7}, {2, 7, 6}, {1, 2, 6}, {1, 6, 5}, {3, 0, 4}, {3, 4, 7}};
    MeshInput in;
    in.hasIndices = true;
    auto add = [&](float x, float y, float z) {
        in.positions.insert(in.positions.end(), {x, y, z});
        in.indices.push_back(std::uint32_t(in.indices.size()));
    };
    for (int t = 0; t < 12; ++t) {
        int a = F[t][0], b = F[t][1], c = F[t][2];
        if (flip && t == 5) std::swap(b, c);
        for (int v : {a, b, c}) add(P[v][0] + 300, P[v][1], P[v][2]);
    }
    if (withSpeck) {
        const float S[4][3] = {{300, 580, 0}, {301, 580, 0}, {300, 581, 0}, {300, 580, 1}};
        const int T[4][3] = {{0, 2, 1}, {0, 1, 3}, {0, 3, 2}, {1, 2, 3}};
        for (const auto& t : T)
            for (int v : t) add(S[v][0], S[v][1], S[v][2]);
    }
    auto data = build_mesh_data(in);
    REQUIRE(data.ok());
    return *data;
}

ModelMesh to_model(const MeshData& d) {
    ModelMesh m;
    for (std::size_t v = 0; v < d.vertex_count(); ++v) m.positions.push_back({d.positions[v * 3], d.positions[v * 3 + 1], d.positions[v * 3 + 2]});
    m.indices = d.indices;
    return m;
}

}  // namespace

TEST_CASE("model_import_clean: a dirty mesh is welded, loses its floating bit, is scaled to a height, recentred and closed") {
    ModelCleanOptions o;
    o.height = 1.8;
    auto r = model_import_clean(dirty_cube(), o);
    REQUIRE(r.ok());
    const ModelCleanReport& rep = r->report;
    CHECK(rep.trianglesBefore == 16);
    CHECK(rep.trianglesAfter == 12);
    CHECK(rep.verticesBefore == 48);
    CHECK(rep.verticesAfter == 8 * 3 + 2);  // a box keeps one vertex per face corner direction (normals differ): 8 corners x up to 3 normals
    CHECK(rep.pieces == 2);
    CHECK(rep.removedPieceCount == 1);
    CHECK(rep.removedPieceTriangles == 4);
    CHECK(rep.trianglesReoriented == 1);
    CHECK(rep.scaleFactor == doctest::Approx(0.01));
    CHECK(rep.sizeAfter.y == doctest::Approx(1.8f));
    CHECK(rep.sizeAfter.x == doctest::Approx(1.0f));
    CHECK(rep.statsBefore.closed() == false);   // the speck shares nothing, but a flipped triangle makes an edge used twice in the same direction
    CHECK(rep.statsAfter.closed());
    CHECK(rep.statsAfter.volume > 0);
    CHECK(rep.statsAfter.bmin.y == doctest::Approx(0.0f).epsilon(0.0001));
    CHECK(0.5f * (rep.statsAfter.bmin.x + rep.statsAfter.bmax.x) == doctest::Approx(0.0f).epsilon(0.0001));
    CHECK(0.5f * (rep.statsAfter.bmin.z + rep.statsAfter.bmax.z) == doctest::Approx(0.0f).epsilon(0.0001));
    CHECK(rep.removedPieces.size() == 1);
    CHECK(rep.removedPieces[0].center.y == doctest::Approx(580.5f));
    const Json j = model_clean_report_json(rep);
    CHECK(j["pieces"]["removed"] == 1);
    CHECK(j["scale"]["factor"] == doctest::Approx(0.01));
    CHECK(j["nonManifoldEdgesFixed"].get<int>() >= 0);
}

TEST_CASE("model_import_clean: without a scale option the size is kept and an odd size is warned about") {
    auto r = model_import_clean(dirty_cube(), {});
    REQUIRE(r.ok());
    CHECK(r->report.scaleFactor == 1);
    bool warned = false;
    for (const std::string& w : r->report.warnings) warned = warned || (w.find("pass `height`") != std::string::npos && w.find("0.01 for centimetres") != std::string::npos);
    CHECK(warned);
    ModelCleanOptions s;
    s.scale = 0.01;
    auto r2 = model_import_clean(dirty_cube(), s);
    REQUIRE(r2.ok());
    CHECK(r2->report.sizeAfter.y == doctest::Approx(1.8f));
    CHECK(r2->report.warnings.empty());
}

TEST_CASE("model_import_clean: z-up sources are turned upright, origin options place the model") {
    MeshInput in;
    in.hasIndices = true;
    // a flat plate 2 x 2 (x, y) and 0.5 tall in z, as 12 box triangles
    ModelBoxParams bp;
    bp.size = {2, 2, 0.5f};
    const ModelMesh box = model_box(bp);
    for (const Vec3& p : box.positions) in.positions.insert(in.positions.end(), {p.x, p.y, p.z});
    in.indices = box.indices;
    auto data = build_mesh_data(in);
    REQUIRE(data.ok());
    ModelCleanOptions o;
    o.upAxis = "z";
    o.origin = "bottom_center";
    auto r = model_import_clean(*data, o);
    REQUIRE(r.ok());
    CHECK(r->report.sizeAfter.y == doctest::Approx(0.5f));
    CHECK(r->report.statsAfter.bmin.y == doctest::Approx(0.0f).epsilon(0.0001));
    o.upAxis = "y";
    o.origin = "center";
    auto c = model_import_clean(*data, o);
    REQUIRE(c.ok());
    CHECK(c->report.statsAfter.bmin.y == doctest::Approx(-1.0f));
    o.origin = "keep";
    auto k = model_import_clean(*data, o);
    REQUIRE(k.ok());
    CHECK(k->report.offset == Vec3{});
}

TEST_CASE("model_import_clean: seams (different uvs on one position) survive the weld, equal vertices merge") {
    MeshInput in;
    in.hasIndices = true;
    // two triangles sharing the edge (1,0,0)-(0,1,0) written with separate vertices; the second triangle has other uvs on the shared edge
    in.positions = {0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 1, 0};
    in.uvs = {0, 0, 1, 0, 0, 1, 0.5f, 0.5f, 0.2f, 0.9f, 1, 1};
    in.indices = {0, 1, 2, 3, 5, 4};
    auto data = build_mesh_data(in);
    REQUIRE(data.ok());
    auto r = model_import_clean(*data, {});
    REQUIRE(r.ok());
    CHECK(r->report.verticesAfter == 6);  // the uvs differ: nothing merges
    CHECK(r->report.verticesWelded == 0);
    in.uvs = {0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 1, 1};
    data = build_mesh_data(in);
    REQUIRE(data.ok());
    auto same = model_import_clean(*data, {});
    REQUIRE(same.ok());
    CHECK(same->report.verticesAfter == 4);
    CHECK(same->report.verticesWelded == 2);
    CHECK(same->mesh.hasUvs);
}

TEST_CASE("model_import_clean: removeFloating false keeps the speck; the biggest piece is never removed") {
    ModelCleanOptions o;
    o.removeFloating = false;
    auto r = model_import_clean(dirty_cube(), o);
    REQUIRE(r.ok());
    CHECK(r->report.removedPieceCount == 0);
    CHECK(r->report.trianglesAfter == 16);
    o.removeFloating = true;
    o.minPieceSize = 1;
    auto big = model_import_clean(dirty_cube(), o);
    REQUIRE(big.ok());
    CHECK(big->report.trianglesAfter >= 12);
    CHECK(big->report.removedPieceCount == 1);
}

TEST_CASE("model_import_clean: decimation reaches the triangle target on a closed surface") {
    ModelSphereParams sp;
    sp.radius = 0.9f;
    sp.segments = 64;
    sp.rings = 32;
    const ModelMesh sphere = model_sphere(sp);
    MeshInput in;
    in.hasIndices = true;
    for (const Vec3& p : sphere.positions) in.positions.insert(in.positions.end(), {p.x, p.y, p.z});
    in.indices = sphere.indices;
    auto data = build_mesh_data(in);
    REQUIRE(data.ok());
    ModelCleanOptions o;
    o.targetTriangles = 400;
    auto r = model_import_clean(*data, o);
    REQUIRE(r.ok());
    CHECK(r->report.decimated);
    CHECK(r->report.trianglesAfter <= 440);
    CHECK(r->report.trianglesBeforeDecimate > 3000);
    CHECK(r->report.statsAfter.closed());
    CHECK(r->report.sizeAfter.y == doctest::Approx(1.8f).epsilon(0.05));
}

TEST_CASE("model_import_clean: remesh closes a surface with a hole and makes it manifold") {
    ModelSphereParams sp;
    sp.radius = 0.5f;
    sp.segments = 24;
    sp.rings = 12;
    ModelMesh sphere = model_sphere(sp);
    // cut a hole: drop the triangles around one side
    MeshInput in;
    in.hasIndices = true;
    for (const Vec3& p : sphere.positions) in.positions.insert(in.positions.end(), {p.x, p.y, p.z});
    for (std::size_t t = 0; t < sphere.triangle_count(); ++t) {
        const Vec3 c = (sphere.positions[sphere.indices[t * 3]] + sphere.positions[sphere.indices[t * 3 + 1]] + sphere.positions[sphere.indices[t * 3 + 2]]) / 3.0f;
        if (c.x > 0.3f) continue;
        in.indices.insert(in.indices.end(), {sphere.indices[t * 3], sphere.indices[t * 3 + 1], sphere.indices[t * 3 + 2]});
    }
    auto data = build_mesh_data(in);
    REQUIRE(data.ok());
    ModelCleanOptions plain;
    auto open = model_import_clean(*data, plain);
    REQUIRE(open.ok());
    CHECK(open->report.statsAfter.boundaryEdges > 0);
    bool advised = false;
    for (const std::string& w : open->report.warnings) advised = advised || w.find("remesh") != std::string::npos;
    CHECK(advised);

    ModelCleanOptions o;
    o.remesh = true;
    o.remeshCells = 40;
    auto r = model_import_clean(*data, o);
    REQUIRE(r.ok());
    CHECK(r->report.remeshed);
    CHECK(r->report.statsAfter.closed());
    CHECK(r->report.statsAfter.volume > 0);
    CHECK(r->report.sizeAfter.y == doctest::Approx(1.0f).epsilon(0.1));
    CHECK_FALSE(r->mesh.hasUvs);
    // same input, same bits
    auto again = model_import_clean(*data, o);
    REQUIRE(again.ok());
    CHECK(again->mesh.positions == r->mesh.positions);
    CHECK(again->mesh.indices == r->mesh.indices);
}

TEST_CASE("model_import_clean: a small hole is closed by the remesh into a solid that decimates to its budget") {
    ModelSphereParams sp;
    sp.radius = 0.5f;
    sp.segments = 32;
    sp.rings = 16;
    const ModelMesh sphere = model_sphere(sp);
    MeshInput in;
    in.hasIndices = true;
    for (const Vec3& p : sphere.positions) in.positions.insert(in.positions.end(), {p.x, p.y, p.z});
    for (std::size_t t = 0; t < sphere.triangle_count(); ++t) {
        const Vec3 c = (sphere.positions[sphere.indices[t * 3]] + sphere.positions[sphere.indices[t * 3 + 1]] + sphere.positions[sphere.indices[t * 3 + 2]]) / 3.0f;
        if (length(c - Vec3{0.5f, 0, 0}) < 0.07f) continue;  // a pinhole
        in.indices.insert(in.indices.end(), {sphere.indices[t * 3], sphere.indices[t * 3 + 1], sphere.indices[t * 3 + 2]});
    }
    auto data = build_mesh_data(in);
    REQUIRE(data.ok());
    ModelCleanOptions o;
    o.remesh = true;
    o.remeshCells = 16;
    o.targetTriangles = 300;
    auto r = model_import_clean(*data, o);
    REQUIRE(r.ok());
    INFO(model_clean_report_json(r->report).dump());
    CHECK(r->report.statsBefore.boundaryEdges > 0);
    CHECK(r->report.statsAfter.closed());
    CHECK(r->report.statsAfter.volume > 0.3);  // a solid ball, not a shell: 4/3 pi 0.5^3 = 0.52
    CHECK(r->report.trianglesAfter <= 330);
}

TEST_CASE("model_import_clean: remesh carries vertex colours and texture colours from the nearest triangle") {
    const ModelMesh box = model_box({});
    MeshInput in;
    in.hasIndices = true;
    for (const Vec3& p : box.positions) in.positions.insert(in.positions.end(), {p.x, p.y, p.z});
    for (const Vec2& t : box.uvs) in.uvs.insert(in.uvs.end(), {t.x, t.y});
    in.indices = box.indices;
    MeshSubmesh sm;
    sm.material.name = "paint";
    sm.start = 0;
    sm.count = std::uint32_t(box.indices.size());
    in.submeshes.push_back(sm);
    auto data = build_mesh_data(in);
    REQUIRE(data.ok());
    ModelCleanOptions o;
    o.remesh = true;
    o.remeshCells = 24;
    o.textureSampler = [](const std::string& material, Vec2) -> std::optional<Vec4> {
        if (material == "paint") return Vec4{1, 0, 0, 1};
        return std::nullopt;
    };
    auto r = model_import_clean(*data, o);
    REQUIRE(r.ok());
    CHECK(r->report.texturesToColors);
    REQUIRE(r->mesh.colors.size() == r->mesh.vertex_count() * 4);
    CHECK(r->mesh.colors[0] == doctest::Approx(1.0f));
    CHECK(r->mesh.colors[1] == doctest::Approx(0.0f));
    REQUIRE(r->mesh.submeshes.size() == 1);
    CHECK(r->mesh.submeshes[0].material.name == "paint");
}

TEST_CASE("model_import_clean: errors say what is wrong and how to fix it") {
    ModelCleanOptions o;
    o.upAxis = "x";
    auto r = model_import_clean(dirty_cube(), o);
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("upAxis 'x'") != std::string::npos);
    CHECK(r.error().hint.find("\"z\"") != std::string::npos);
    o = {};
    o.height = 2;
    o.scale = 2;
    r = model_import_clean(dirty_cube(), o);
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("height") != std::string::npos);
    o = {};
    o.origin = "bottom-center";
    r = model_import_clean(dirty_cube(), o);
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("bottom-center") != std::string::npos);
}
