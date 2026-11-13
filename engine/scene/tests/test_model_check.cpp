// model_check.h: the faults found by measuring a mesh (docs/MODELING.md, "Looking at a model: model.preview and model.check").
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <string>

#include "fa/core/json_schema.h"
#include "fa/scene/model_check.h"
#include "fa/scene/model_doc.h"
#include "fa/scene/model_game_ready.h"

using namespace fa;

namespace {

Json J(const std::string& text) { return parse_json(text, "test").value(); }

ModelBuild build(const std::string& text) {
    auto doc = parse_model_doc(J(text), "t.model.json");
    REQUIRE_MESSAGE(doc.ok(), (doc.ok() ? std::string() : doc.error().to_string()));
    auto b = evaluate_model(*doc);
    REQUIRE_MESSAGE(b.ok(), (b.ok() ? std::string() : b.error().to_string()));
    return std::move(*b);
}

// A cube of side `s` centred at (cx, cy, cz), triangles counter-clockwise seen from outside, normals pointing out of the middle.
MeshData cube(float s = 1.8f, float cx = 0, float cy = 0, float cz = 0) {
    MeshData m;
    for (int v = 0; v < 8; ++v) {
        float x = (v & 1 ? 0.5f : -0.5f), y = (v & 2 ? 0.5f : -0.5f), z = (v & 4 ? 0.5f : -0.5f);
        m.positions.insert(m.positions.end(), {cx + x * s, cy + y * s, cz + z * s});
        Vec3 n = normalize(Vec3{x, y, z});
        m.normals.insert(m.normals.end(), {n.x, n.y, n.z});
    }
    m.indices = {1, 3, 7, 1, 7, 5, 0, 4, 6, 0, 6, 2, 2, 6, 7, 2, 7, 3,
                 0, 1, 5, 0, 5, 4, 4, 5, 7, 4, 7, 6, 0, 2, 3, 0, 3, 1};
    MeshSubmesh sm;
    sm.start = 0;
    sm.count = std::uint32_t(m.indices.size());
    m.submeshes.push_back(sm);
    return m;
}

const ModelFinding* find(const ModelCheckReport& r, const std::string& code) {
    for (const ModelFinding& f : r.findings)
        if (f.code == code) return &f;
    return nullptr;
}

void reverse_all(MeshData& m) {
    for (std::size_t i = 0; i + 2 < m.indices.size(); i += 3) std::swap(m.indices[i + 1], m.indices[i + 2]);
}

}  // namespace

TEST_CASE("check: a closed cube is clean and measured") {
    auto r = check_model_mesh(cube(1.8f), {});
    CHECK(r.ok());
    CHECK(r.findings.empty());
    CHECK(r.triangles == 12);
    CHECK(r.pieces == 1);
    CHECK(r.openEdges == 0);
    CHECK(r.scale.height == doctest::Approx(1.8));
    CHECK(r.scale.versusFigure == doctest::Approx(1.0));
    CHECK(r.scale.volume == doctest::Approx(1.8 * 1.8 * 1.8).epsilon(0.001));
}

TEST_CASE("check: a piece turned inside out is an error that says where") {
    MeshData m = cube();
    reverse_all(m);
    auto r = check_model_mesh(m, {});
    REQUIRE(find(r, "inside_out"));
    CHECK_FALSE(r.ok());
    const ModelFinding& f = *find(r, "inside_out");
    CHECK(f.severity == "error");
    CHECK(f.count == 12);
    CHECK(f.hint.size() > 20);
    CHECK_FALSE(f.samples.empty());
    CHECK(f.bmin.x == doctest::Approx(-0.9));
    // the stored normals point out while the winding says in
    REQUIRE(find(r, "flipped_normals"));
    CHECK(find(r, "flipped_normals")->severity == "warning");
    CHECK(r.findings.front().severity == "error");  // errors come first
}

TEST_CASE("check: one flipped triangle disagrees with its neighbours") {
    MeshData m = cube();
    std::swap(m.indices[1], m.indices[2]);
    auto r = check_model_mesh(m, {});
    REQUIRE(find(r, "inconsistent_winding"));
    CHECK(find(r, "inconsistent_winding")->count == 3);  // its three edges
    CHECK_FALSE(find(r, "inside_out"));
}

TEST_CASE("check: a missing face leaves open edges, which can be ignored") {
    MeshData m = cube();
    m.indices.resize(m.indices.size() - 6);  // the -z face
    m.submeshes[0].count = std::uint32_t(m.indices.size());
    auto r = check_model_mesh(m, {});
    REQUIRE(find(r, "open_edges"));
    CHECK(find(r, "open_edges")->count == 4);
    CHECK(r.ok());  // a warning, not an error
    CHECK(find(r, "open_edges")->hint.find("ignore") != std::string::npos);
    ModelCheckOptions o;
    o.ignore = {"open_edges"};
    CHECK_FALSE(find(check_model_mesh(m, o), "open_edges"));
}

TEST_CASE("check: an edge shared by three triangles is non-manifold") {
    MeshData m = cube();
    m.indices.insert(m.indices.end(), {1, 3, 7});  // the same face twice
    m.submeshes[0].count = std::uint32_t(m.indices.size());
    auto r = check_model_mesh(m, {});
    REQUIRE(find(r, "non_manifold"));
    CHECK(find(r, "non_manifold")->severity == "error");
    CHECK(r.nonManifoldEdges == 3);
}

TEST_CASE("check: triangles with no area") {
    MeshData m = cube();
    m.indices.insert(m.indices.end(), {0, 0, 1, 2, 2, 2});
    m.submeshes[0].count = std::uint32_t(m.indices.size());
    auto r = check_model_mesh(m, {});
    REQUIRE(find(r, "degenerate"));
    CHECK(find(r, "degenerate")->count == 2);
    CHECK_FALSE(find(r, "open_edges"));  // degenerate triangles do not count as edges
}

TEST_CASE("check: findings name the parts they are in") {
    MeshData m = cube();
    m.submeshes.clear();
    MeshSubmesh a, b;
    a.part = "top";
    a.start = 0;
    a.count = 24;
    b.part = "bottom";
    b.start = 24;
    b.count = 9;  // the +z face and the first triangle of the -z face
    m.submeshes = {a, b};
    m.indices.resize(33);  // the second triangle of the -z face is missing
    auto r = check_model_mesh(m, {});
    REQUIRE(find(r, "open_edges"));
    const ModelFinding& f = *find(r, "open_edges");
    CHECK(std::find(f.parts.begin(), f.parts.end(), "bottom") != f.parts.end());
    CHECK(f.message.find("bottom") != std::string::npos);
}

TEST_CASE("check: scale against the expected height") {
    ModelCheckOptions o;
    o.expectedHeight = 1.8;
    CHECK_FALSE(find(check_model_mesh(cube(1.7f), o), "scale"));
    auto r = check_model_mesh(cube(0.018f), o);
    REQUIRE(find(r, "scale"));
    CHECK(find(r, "scale")->message.find("small") != std::string::npos);
    CHECK(find(r, "scale")->hint.find("100") != std::string::npos);  // centimetres to metres
    auto big = check_model_mesh(cube(180.f), o);
    REQUIRE(find(big, "scale"));
    CHECK(find(big, "scale")->message.find("big") != std::string::npos);
    // without an expectation only the absurd is reported
    CHECK_FALSE(find(check_model_mesh(cube(0.5f), {}), "scale"));
    CHECK(find(check_model_mesh(cube(0.002f), {}), "scale"));
    CHECK(find(check_model_mesh(cube(400.f), {}), "scale"));
}

TEST_CASE("check: a model far from its origin") {
    auto r = check_model_mesh(cube(1.0f, 50, 0, 0), {});
    REQUIRE(find(r, "origin"));
    CHECK(find(r, "origin")->hint.find("origin") != std::string::npos);
    CHECK_FALSE(find(check_model_mesh(cube(1.0f, 0.5f, 0.5f, 0), {}), "origin"));
}

TEST_CASE("check: an empty mesh") {
    MeshData m;
    m.submeshes.push_back({});
    auto r = check_model_mesh(m, {});
    REQUIRE(find(r, "empty"));
    CHECK_FALSE(r.ok());
}

TEST_CASE("check: triangle budgets use the platform table of the game-ready code") {
    auto b = build(
        R"({"format":"factoria.model/1","nodes":[{"op":"sphere","radius":0.5,"segments":256,"rings":128,"position":[0,0.5,0]}]})");
    REQUIRE(b.data.triangle_count() > 40000);
    auto r = check_model_mesh(b.data, {});
    std::vector<std::string> platforms;
    for (const ModelFinding& f : r.findings)
        if (f.code == "triangle_budget") platforms.push_back(f.platform);
    CHECK(platforms == std::vector<std::string>{"mobile", "web"});
    for (const ModelFinding& f : r.findings)
        if (f.code == "triangle_budget") {
            const ModelPlatformBudget* row = nullptr;
            for (const ModelPlatformBudget& pb : model_platform_budgets())
                if (pb.platform == f.platform) row = &pb;
            REQUIRE(row);
            CHECK(f.message.find(std::to_string(row->triangles)) != std::string::npos);
            CHECK(f.severity == "warning");
        }
    // a platform can be chosen, and a LOD that fits turns the warning into information
    ModelCheckOptions o;
    o.platforms = {"mobile"};
    o.lodTriangles = {15000};
    auto mobile = check_model_mesh(b.data, o);
    REQUIRE(find(mobile, "triangle_budget"));
    CHECK(find(mobile, "triangle_budget")->severity == "info");
    CHECK(find(mobile, "triangle_budget")->message.find("LOD1") != std::string::npos);
    CHECK(mobile.infos == 1);
    CHECK(mobile.warnings == 0);
}

TEST_CASE("check: more submeshes than a platform's draw call budget") {
    std::string nodes;
    for (int i = 0; i < 17; ++i)
        nodes += std::string(i ? "," : "") + R"({"op":"box","size":[0.2,0.2,0.2],"part":"p)" + std::to_string(i) +
                 R"(","position":[)" + std::to_string(i * 0.25) + R"(,0.1,0]})";
    auto b = build(R"({"format":"factoria.model/1","nodes":[)" + nodes + "]}");
    REQUIRE(b.data.submeshes.size() == 17);
    ModelCheckOptions o;
    o.platforms = {"desktop"};
    auto r = check_model_mesh(b.data, o);
    REQUIRE(find(r, "draw_call_budget"));
    CHECK(find(r, "draw_call_budget")->platform == "desktop");
    CHECK(find(r, "draw_call_budget")->hint.find("merge") != std::string::npos);
}

TEST_CASE("check: evaluated documents are clean solids") {
    auto b = build(R"({"format":"factoria.model/1","nodes":[
        {"op":"boolean","mode":"union","children":[{"op":"box","size":[3,1,1],"position":[0,0.5,0]},{"op":"box","size":[1,3,1],"position":[-1,1.5,0]}]},
        {"op":"sphere","radius":0.4,"position":[2,0.4,0],"part":"ball"}]})");
    auto r = check_model_mesh(b.data, {});
    CHECK(r.findings.empty());
    CHECK(r.pieces == 2);
    CHECK(r.insideOutPieces == 0);
    CHECK(r.openEdges == 0);
    // mirrored nodes keep their triangles facing out
    auto m = build(
        R"({"format":"factoria.model/1","nodes":[{"op":"cylinder","radius":0.3,"height":1,"scale":[-1,1,1],"position":[0,0.5,0]}]})");
    CHECK(check_model_mesh(m.data, {}).findings.empty());
}

TEST_CASE("check: deterministic, and every code a report can hold is in the catalog") {
    MeshData m = cube(0.002f, 40, 0, 0);
    reverse_all(m);
    m.indices.insert(m.indices.end(), {0, 0, 1});
    m.submeshes[0].count = std::uint32_t(m.indices.size());
    auto a = check_model_mesh(m, {});
    auto b = check_model_mesh(m, {});
    REQUIRE(a.findings.size() == b.findings.size());
    for (std::size_t i = 0; i < a.findings.size(); ++i) {
        CHECK(a.findings[i].code == b.findings[i].code);
        CHECK(a.findings[i].message == b.findings[i].message);
    }
    CHECK(a.findings.size() >= 4);
    for (const ModelFinding& f : a.findings) {
        bool known = false;
        for (const ModelCheckKind& k : model_check_kinds()) known = known || k.code == f.code;
        CHECK_MESSAGE(known, f.code);
        CHECK_FALSE(f.hint.empty());
        CHECK_FALSE(f.message.empty());
    }
}
