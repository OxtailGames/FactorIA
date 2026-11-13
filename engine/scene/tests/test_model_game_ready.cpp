// Game-ready models: the settings of a document, origin and ground, merging, LODs, colliders (box, sphere, capsule, convex hull, convex
// decomposition), the budget report and determinism (docs/MODELING.md, "Game-ready models").
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstring>

#include "fa/core/hash.h"
#include "fa/core/json_schema.h"
#include "fa/scene/model_doc.h"
#include "fa/scene/model_game_ready.h"

using namespace fa;

namespace {

Json J(const char* text) { return parse_json(text, "test").value(); }

ModelBuild build(const char* text) {
    auto doc = parse_model_doc(J(text), "t.model.json");
    REQUIRE_MESSAGE(doc.ok(), (doc.ok() ? std::string() : doc.error().to_string()));
    auto b = evaluate_model(*doc);
    REQUIRE_MESSAGE(b.ok(), (b.ok() ? std::string() : b.error().to_string()));
    return std::move(*b);
}

ModelGameReady settings(const char* text) {
    auto g = parse_game_ready(J(text), "/gameReady");
    REQUIRE_MESSAGE(g.ok(), (g.ok() ? std::string() : g.error().to_string()));
    return *g;
}

const char* kBall = R"({"format":"factoria.model/1","nodes":[{"op":"sphere","radius":1,"segments":48,"rings":24}]})";
// an L: two boxes joined, concave
const char* kL = R"({"format":"factoria.model/1","nodes":[{"op":"boolean","mode":"union","children":[
    {"op":"box","size":[3,1,1],"position":[0,0.5,0]},{"op":"box","size":[1,3,1],"position":[-1,1.5,0]}]}]})";
// a lamp: two materials, two parts
const char* kLamp =
    R"({"format":"factoria.model/1","materials":{"brass":{"color":[0.8,0.6,0.2,1]},"cloth":{"color":[0.9,0.9,0.8,1]}},"nodes":[
    {"op":"sphere","radius":0.5,"segments":32,"rings":16,"part":"base","material":"brass","position":[0,0.5,3]},
    {"op":"cylinder","radius":0.2,"height":2,"segments":24,"part":"stem","material":"brass","position":[0,2,3]},
    {"op":"cone","radius":0.6,"height":1,"segments":32,"part":"shade","material":"cloth","position":[0,3.5,3]},
    {"op":"sphere","radius":0.3,"segments":16,"rings":8,"part":"bulb","material":"brass","position":[0,3,3]}]})";

std::string hash_of(const MeshData& m) {
    std::string bytes(reinterpret_cast<const char*>(m.positions.data()), m.positions.size() * 4);
    bytes.append(reinterpret_cast<const char*>(m.normals.data()), m.normals.size() * 4);
    bytes.append(reinterpret_cast<const char*>(m.indices.data()), m.indices.size() * 4);
    for (const MeshSubmesh& s : m.submeshes) bytes += s.part + std::to_string(s.start) + ":" + std::to_string(s.count);
    return sha256_hex(bytes);
}

}  // namespace

TEST_CASE("game ready: the settings are read with defaults and every mistake is explained") {
    const ModelGameReady g = settings(R"({})");
    CHECK(g.origin == "keep");
    CHECK_FALSE(g.merge);
    CHECK(g.lods.empty());
    CHECK(g.collider.shape == "none");
    CHECK(g.is_default());
    CHECK(g.platforms.size() == 3);

    const ModelGameReady full =
        settings(R"({"origin":"bottom_center","merge":true,"lods":[{"ratio":0.5},{"triangles":300,"distance":20}],
        "collider":{"shape":"decomposed","maxHulls":4,"maxVertices":24,"resolution":50000},"platforms":["mobile"]})");
    CHECK(full.origin == "bottom_center");
    CHECK(full.lods.size() == 2);
    CHECK(full.lods[1].distance == 20);
    CHECK(full.collider.maxHulls == 4);
    CHECK(full.platforms == std::vector<std::string>{"mobile"});
    // written and read again gives the same settings
    const Json again = game_ready_to_json(full);
    CHECK(game_ready_to_json(*parse_game_ready(again, "/gameReady")) == again);

    std::vector<ModelIssue> issues;
    auto bad = parse_game_ready(
        J(R"({"origin":"botom","lods":[{"ratio":3},{}],"collider":{"shape":"hul","maxVertices":900},"extra":1,"platforms":["phone"]})"),
        "/gameReady", &issues);
    CHECK_FALSE(bad.ok());
    auto find = [&](const std::string& pointer, const std::string& text) {
        return std::any_of(issues.begin(), issues.end(), [&](const ModelIssue& i) {
            return i.pointer == pointer && (i.message + i.hint).find(text) != std::string::npos;
        });
    };
    CHECK(find("/gameReady/origin", "bottom"));  // did you mean
    CHECK(find("/gameReady/lods/0/ratio", "between"));
    CHECK(find("/gameReady/lods/1", "ratio, triangles or error"));
    CHECK(find("/gameReady/collider/shape", "convex"));
    CHECK(find("/gameReady/collider/maxVertices", "256"));
    CHECK(find("/gameReady/extra", "not a field"));
    CHECK(find("/gameReady/platforms/0", "mobile"));
}

TEST_CASE("game ready: a model document carries the settings and the schema describes them") {
    auto doc = parse_model_doc(
        J(R"({"format":"factoria.model/1","gameReady":{"origin":"bottom","lods":[{"ratio":0.25}]},"nodes":[{"op":"box"}]})"),
        "t.model.json");
    REQUIRE(doc.ok());
    CHECK(doc->gameReady["origin"] == "bottom");
    CHECK(doc->gameReady["lods"].size() == 1);
    std::vector<ModelIssue> issues;
    auto bad =
        parse_model_doc(J(R"({"format":"factoria.model/1","gameReady":{"lods":[{"ratio":0}]},"nodes":[{"op":"box"}]})"),
                        "t.model.json", &issues);
    CHECK_FALSE(bad.ok());
    REQUIRE(!issues.empty());
    CHECK(issues[0].pointer == "/gameReady/lods/0/ratio");
    const Json schema = model_doc_schema();
    CHECK(schema["properties"].contains("gameReady"));
    CHECK(schema["properties"]["gameReady"]["properties"].contains("collider"));
}

TEST_CASE("game ready: origin and ground move the model, not its shape") {
    const ModelBuild b = build(kLamp);  // x 0, z 3, y from 0 to 4
    const Vec3 lo = b.data.bmin, hi = b.data.bmax;
    CHECK(model_origin_offset(b.data, "keep").y == 0);
    const Vec3 center = model_origin_offset(b.data, "center");
    const MeshData centered = model_translated(b.data, center);
    CHECK((centered.bmin.x + centered.bmax.x) == doctest::Approx(0).epsilon(1e-4).scale(1));
    CHECK((centered.bmin.y + centered.bmax.y) == doctest::Approx(0).scale(1).epsilon(1e-4));
    CHECK((centered.bmin.z + centered.bmax.z) == doctest::Approx(0).scale(1).epsilon(1e-4));
    const MeshData grounded = model_translated(b.data, model_origin_offset(b.data, "bottom"));
    CHECK(grounded.bmin.y == doctest::Approx(0.0f).scale(1).epsilon(1e-5));
    CHECK(grounded.bmin.z == doctest::Approx(lo.z));  // x and z kept
    CHECK(grounded.bmax.y - grounded.bmin.y == doctest::Approx(hi.y - lo.y));
    const MeshData both = model_translated(b.data, model_origin_offset(b.data, "bottom_center"));
    CHECK(both.bmin.y == doctest::Approx(0.0f).scale(1).epsilon(1e-5));
    CHECK(both.bmin.z == doctest::Approx(-both.bmax.z));
    // what the bounds say is what the positions say
    float minY = 1e9f;
    for (std::size_t i = 1; i < both.positions.size(); i += 3) minY = std::min(minY, both.positions[i]);
    CHECK(minY == doctest::Approx(both.bmin.y));
    // through make_game_ready too
    auto r = make_game_ready(b.data, settings(R"({"origin":"bottom_center"})"));
    REQUIRE(r.ok());
    CHECK(r->mesh.bmin.y == doctest::Approx(0.0f).scale(1).epsilon(1e-5));
    CHECK(r->offset.z == doctest::Approx(-3.0f));
}

TEST_CASE("game ready: merging joins the submeshes of one material and welds identical vertices") {
    const ModelBuild b = build(kLamp);
    REQUIRE(b.data.submeshes.size() == 4);
    ModelMergeInfo info;
    auto merged = model_merge_by_material(b.data, &info);
    REQUIRE(merged.ok());
    CHECK(info.submeshesBefore == 4);
    CHECK(info.submeshesAfter == 2);
    CHECK(merged->submeshes.size() == 2);
    CHECK(merged->triangle_count() == b.data.triangle_count());
    CHECK(info.verticesAfter <= info.verticesBefore);
    CHECK(merged->submeshes[0].material.name == "brass");
    CHECK(merged->submeshes[0].part == "base+stem+bulb");
    CHECK(merged->submeshes[1].material.name == "cloth");
    CHECK(merged->submeshes[1].part == "shade");
    CHECK(merged->bmin.y == doctest::Approx(b.data.bmin.y));
    CHECK(merged->bmax.y == doctest::Approx(b.data.bmax.y));
    for (std::uint32_t i : merged->indices) CHECK(i < merged->vertex_count());
    // the same surface: the same volume, from whichever way it is measured
    ModelCollider before = *model_fit_collider(b.data, {"box"}), after = *model_fit_collider(merged.value(), {"box"});
    CHECK(after.meshVolume == doctest::Approx(before.meshVolume).epsilon(1e-4));
    // a mesh that is already one submesh stays one, and welding a box drops its duplicate corners only when they are identical
    const ModelBuild box = build(R"({"format":"factoria.model/1","nodes":[{"op":"box"}]})");
    auto one = model_merge_by_material(box.data);
    REQUIRE(one.ok());
    CHECK(one->submeshes.size() == 1);
    CHECK(one->vertex_count() ==
          box.data.vertex_count());  // a flat shaded box: 24 vertices that differ in their normals
}

TEST_CASE("game ready: a LOD keeps the target, the materials, the parts and the shape") {
    const ModelBuild b = build(kLamp);
    const std::size_t full = b.data.triangle_count();
    ModelLodSpec half;
    half.ratio = 0.5;
    ModelLodInfo info;
    auto lod = model_make_lod(b.data, half, &info);
    REQUIRE(lod.ok());
    CHECK(lod->triangle_count() <= full / 2 + full / 20 + 2);
    CHECK(lod->triangle_count() >= full / 4);
    CHECK(info.reachedTarget);
    CHECK(info.triangles == lod->triangle_count());
    REQUIRE(lod->submeshes.size() == b.data.submeshes.size());
    for (std::size_t i = 0; i < lod->submeshes.size(); ++i) {
        CHECK(lod->submeshes[i].part == b.data.submeshes[i].part);
        CHECK(lod->submeshes[i].material.name == b.data.submeshes[i].material.name);
        CHECK(lod->submeshes[i].count > 0);
    }
    // bounds stay (a lamp shrinks by a sliver at most) and every normal is a unit vector
    CHECK(lod->bmax.y == doctest::Approx(b.data.bmax.y).epsilon(0.02));
    CHECK(lod->bmin.y == doctest::Approx(b.data.bmin.y).epsilon(0.02));
    for (std::size_t v = 0; v < lod->vertex_count(); ++v) {
        const float l =
            std::sqrt(lod->normals[v * 3] * lod->normals[v * 3] + lod->normals[v * 3 + 1] * lod->normals[v * 3 + 1] +
                      lod->normals[v * 3 + 2] * lod->normals[v * 3 + 2]);
        CHECK(l == doctest::Approx(1.0f).epsilon(1e-3));
    }
    for (std::uint32_t i : lod->indices) CHECK(i < lod->vertex_count());
}

TEST_CASE("game ready: LOD ratio, triangle count and error limit") {
    const ModelBuild b = build(kBall);
    const std::size_t full = b.data.triangle_count();
    std::size_t last = full;
    for (double ratio : {0.5, 0.25, 0.1}) {
        ModelLodSpec s;
        s.ratio = ratio;
        auto lod = model_make_lod(b.data, s);
        REQUIRE(lod.ok());
        CHECK(lod->triangle_count() < last);
        CHECK(double(lod->triangle_count()) <= double(full) * ratio * 1.1 + 4);
        last = lod->triangle_count();
    }
    ModelLodSpec tri;
    tri.triangles = 200;
    auto t = model_make_lod(b.data, tri);
    REQUIRE(t.ok());
    CHECK(t->triangle_count() <= 215);
    CHECK(t->triangle_count() >= 100);
    // both given: the smaller target
    ModelLodSpec both;
    both.ratio = 0.5;
    both.triangles = 100;
    CHECK(model_make_lod(b.data, both)->triangle_count() <= 110);
    // an error limit alone: the surface never moves farther than it says, and a tighter limit keeps more triangles
    ModelLodInfo loose, tight;
    ModelLodSpec e1, e2;
    e1.error = 0.05;
    e2.error = 0.005;
    auto l1 = model_make_lod(b.data, e1, &loose);
    auto l2 = model_make_lod(b.data, e2, &tight);
    REQUIRE(l1.ok());
    REQUIRE(l2.ok());
    CHECK(loose.error <= 0.05 + 1e-6);
    CHECK(tight.error <= 0.005 + 1e-6);
    CHECK(l1->triangle_count() < l2->triangle_count());
    CHECK(l2->triangle_count() < full);
    // the distance of an automatic LOD grows with the level and with the size of the model
    ModelLodSpec none;
    CHECK(model_lod_distance(b.data, 2, none) == doctest::Approx(2 * model_lod_distance(b.data, 1, none)));
    none.distance = 7;
    CHECK(model_lod_distance(b.data, 1, none) == 7);
    // mistakes
    CHECK_FALSE(model_make_lod(b.data, ModelLodSpec{}).ok());
}

TEST_CASE("game ready: a LOD of a sphere stays a sphere (volume and radius)") {
    const ModelBuild b = build(kBall);
    ModelLodSpec s;
    s.ratio = 0.2;
    auto lod = model_make_lod(b.data, s);
    REQUIRE(lod.ok());
    const double volume = model_fit_collider(*lod, {"box"})->meshVolume,
                 full = model_fit_collider(b.data, {"box"})->meshVolume;
    CHECK(volume == doctest::Approx(full).epsilon(0.12));
    for (std::size_t v = 0; v < lod->vertex_count(); ++v) {
        const float r = std::sqrt(lod->positions[v * 3] * lod->positions[v * 3] +
                                  lod->positions[v * 3 + 1] * lod->positions[v * 3 + 1] +
                                  lod->positions[v * 3 + 2] * lod->positions[v * 3 + 2]);
        CHECK(r == doctest::Approx(1.0f).epsilon(0.06));
    }
}

TEST_CASE("game ready: colliders fit the mesh") {
    const ModelBuild b = build(kL);  // 3 x 1 x 1 and 1 x 3 x 1: x -2..1.5? (see below), y 0..3
    ModelColliderSpec spec;
    spec.shape = "box";
    auto box = model_fit_collider(b.data, spec);
    REQUIRE(box.ok());
    CHECK(box->size.x == doctest::Approx(b.data.bmax.x - b.data.bmin.x));
    CHECK(box->size.y == doctest::Approx(3.0f));
    CHECK(box->center.y == doctest::Approx(1.5f));
    CHECK(box->volumeRatio > 1.2);  // an L in its box leaves room

    spec.shape = "sphere";
    auto sphere = model_fit_collider(b.data, spec);
    REQUIRE(sphere.ok());
    for (std::size_t i = 0; i < b.data.positions.size(); i += 3) {
        const Vec3 p{b.data.positions[i], b.data.positions[i + 1], b.data.positions[i + 2]};
        CHECK(length(p - sphere->center) <= sphere->radius + 1e-4f);
    }

    spec.shape = "capsule";
    auto capsule = model_fit_collider(
        build(R"({"format":"factoria.model/1","nodes":[{"op":"capsule","radius":0.4,"height":1.8}]})").data, spec);
    REQUIRE(capsule.ok());
    CHECK(capsule->radius == doctest::Approx(0.4f).epsilon(0.01));
    CHECK(capsule->height == doctest::Approx(1.8f).epsilon(0.01));
    CHECK(capsule->volumeRatio == doctest::Approx(1.0).epsilon(0.05));
    CHECK(capsule->warnings.empty());
    // a wide, low model does not fit a capsule on Y, and says so
    auto flat = model_fit_collider(
        build(R"({"format":"factoria.model/1","nodes":[{"op":"box","size":[4,0.5,4]}]})").data, spec);
    REQUIRE(flat.ok());
    CHECK_FALSE(flat->warnings.empty());

    spec.shape = "convex";
    spec.maxVertices = 16;
    auto convex = model_fit_collider(build(kBall).data, spec);
    REQUIRE(convex.ok());
    REQUIRE(convex->hulls.size() == 1);
    CHECK(convex->hulls[0].points.size() <= 16);
    CHECK(convex->hulls[0].points.size() >= 4);
    CHECK(convex->hulls[0].indices.size() % 3 == 0);
    CHECK(convex->volumeRatio < 1.0);  // a coarse hull sits inside the ball
    CHECK(convex->volumeRatio > 0.4);

    spec.maxVertices = 256;
    auto fine = model_fit_collider(build(kBall).data, spec);
    REQUIRE(fine.ok());
    CHECK(fine->volumeRatio > 0.97);
    CHECK(fine->hulls[0].points.size() <= 256);

    // a flat mesh has no hull
    MeshInput in;
    in.positions = {0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 1, 0};
    in.indices = {0, 1, 2, 1, 3, 2};
    in.hasIndices = true;
    auto plane = build_mesh_data(in);
    REQUIRE(plane.ok());
    spec.maxVertices = 32;
    CHECK_FALSE(model_fit_collider(*plane, spec).ok());
}

TEST_CASE("game ready: a concave model is cut into convex pieces that follow it closer than one hull") {
    const ModelBuild b = build(kL);
    ModelColliderSpec convexSpec;
    convexSpec.shape = "convex";
    auto convex = model_fit_collider(b.data, convexSpec);
    REQUIRE(convex.ok());
    ModelColliderSpec spec;
    spec.shape = "decomposed";
    spec.maxHulls = 6;
    spec.maxVertices = 32;
    spec.resolution = 100000;
    auto parts = model_fit_collider(b.data, spec);
    REQUIRE(parts.ok());
    CHECK(parts->shape == "decomposed");
    CHECK(parts->hulls.size() >= 2);
    CHECK(parts->hulls.size() <= 6);
    for (const ModelHull& h : parts->hulls) {
        CHECK(h.points.size() <= 32);
        CHECK(h.volume > 0);
    }
    // the pieces cover the L (volume 5) with much less spare room than the single hull
    CHECK(parts->volume < convex->volume);
    CHECK(parts->volumeRatio < convex->volumeRatio);
    CHECK(parts->volumeRatio >= 0.9);
    CHECK(parts->volumeRatio < 1.35);
    // every point of the L lies inside (or on) one of the pieces' bounding boxes
    for (std::size_t i = 0; i < b.data.positions.size(); i += 3) {
        const Vec3 p{b.data.positions[i], b.data.positions[i + 1], b.data.positions[i + 2]};
        bool inside = false;
        for (const ModelHull& h : parts->hulls) {
            Vec3 lo = h.points[0], hi = h.points[0];
            for (const Vec3& q : h.points) {
                lo = min(lo, q);
                hi = max(hi, q);
            }
            const float tol = 0.08f;
            inside = inside || (p.x >= lo.x - tol && p.x <= hi.x + tol && p.y >= lo.y - tol && p.y <= hi.y + tol &&
                                p.z >= lo.z - tol && p.z <= hi.z + tol);
        }
        CHECK(inside);
    }
    // a convex model gains nothing from being cut: one piece is enough
    ModelColliderSpec one = spec;
    one.maxHulls = 1;
    auto single = model_fit_collider(build(kBall).data, one);
    REQUIRE(single.ok());
    CHECK(single->hulls.size() == 1);
    // the hull as a mesh can be baked
    const MeshData hullMesh = model_hull_mesh(parts->hulls[0]);
    CHECK(hullMesh.triangle_count() == parts->hulls[0].indices.size() / 3);
}

TEST_CASE("game ready: the budget report names what is over and what fits") {
    const ModelBuild b = build(
        R"({"format":"factoria.model/1","nodes":[{"op":"sphere","radius":1,"segments":256,"rings":128}]})");  // 64k triangles
    REQUIRE(b.data.triangle_count() > 60000);
    auto plain = make_game_ready(b.data, settings(R"({})"));
    REQUIRE(plain.ok());
    REQUIRE(plain->budget.size() == 3);
    CHECK(plain->budget[0].platform == "desktop");
    CHECK(plain->budget[0].fullMeshFits);
    CHECK_FALSE(plain->budget[1].fullMeshFits);  // mobile 20000
    CHECK(plain->budget[1].firstFittingLod == -1);
    bool noLod = false;
    for (const std::string& w : plain->warnings)
        noLod = noLod || (w.find("mobile") == 0 && w.find("no LOD fits") != std::string::npos);
    CHECK(noLod);

    auto withLods = make_game_ready(b.data, settings(R"({"lods":[{"ratio":0.5},{"triangles":15000}]})"));
    REQUIRE(withLods.ok());
    REQUIRE(withLods->lodInfo.size() == 3);
    CHECK(withLods->lodInfo[0].triangles > withLods->lodInfo[1].triangles);
    CHECK(withLods->lodInfo[1].triangles > withLods->lodInfo[2].triangles);
    CHECK(withLods->budget[1].firstFittingLod == 2);
    bool fits = false;
    for (const std::string& w : withLods->warnings)
        fits = fits || (w.find("mobile") == 0 && w.find("LOD2") != std::string::npos);
    CHECK(fits);
    const Json report = game_ready_report_json(*withLods, settings(R"({"lods":[{"ratio":0.5},{"triangles":15000}]})"));
    CHECK(report["lods"].size() == 3);
    CHECK(report["budget"][1]["firstFittingLod"] == 2);
    CHECK(report["budget"][1]["lodFits"][2] == true);
    CHECK(report["budget"][1]["lodFits"][0] == false);

    // draw calls: four submeshes pass desktop, and merging reports the saving
    const ModelBuild lamp = build(kLamp);
    auto many = make_game_ready(lamp.data, settings(R"({"merge":true,"platforms":["mobile"]})"));
    REQUIRE(many.ok());
    CHECK(many->budget.size() == 1);
    CHECK(many->merge.submeshesAfter == 2);
    CHECK(many->budget[0].submeshesFit);
    // only the platforms asked for are checked
    CHECK(make_game_ready(lamp.data, settings(R"({"platforms":["web","desktop"]})"))->budget.size() == 2);
}

TEST_CASE("game ready: the settings work on an organic sdf result") {
    const ModelBuild b = build(
        R"({"format":"factoria.model/1","materials":{"skin":{"color":[0.8,0.5,0.4,1]}},"nodes":[{"op":"sdf","part":"blob","material":"skin","children":[
        {"op":"sdf_sphere","radius":0.8,"position":[0,0.8,0]},{"op":"sdf_sphere","radius":0.5,"position":[0.9,0.6,0],"blend":"union","smooth":0.3}]}]})");
    auto r = make_game_ready(
        b.data,
        settings(
            R"({"origin":"bottom_center","lods":[{"ratio":0.4}],"collider":{"shape":"convex","maxVertices":24}})"));
    REQUIRE(r.ok());
    CHECK(r->mesh.bmin.y == doctest::Approx(0.0f).scale(1).epsilon(1e-4));
    CHECK(r->lods.size() == 1);
    CHECK(r->lods[0].triangle_count() < b.data.triangle_count());
    CHECK(r->lods[0].submeshes[0].part == "blob");
    REQUIRE(r->collider.hulls.size() == 1);
    CHECK(r->collider.hulls[0].points.size() <= 24);
    CHECK(r->collider.volumeRatio > 0.6);
}

TEST_CASE("game ready: the same mesh gives the same bytes (and the same bytes on every platform)") {
    const ModelBuild b = build(kLamp);
    auto run = [&] {
        return make_game_ready(
            b.data,
            settings(
                R"({"origin":"bottom_center","merge":true,"lods":[{"ratio":0.5},{"ratio":0.15}],"collider":{"shape":"decomposed","maxHulls":4}})"));
    };
    auto a = run();
    auto c = run();
    REQUIRE(a.ok());
    REQUIRE(c.ok());
    CHECK(hash_of(a->mesh) == hash_of(c->mesh));
    REQUIRE(a->lods.size() == 2);
    for (std::size_t i = 0; i < a->lods.size(); ++i) CHECK(hash_of(a->lods[i]) == hash_of(c->lods[i]));
    REQUIRE(a->collider.hulls.size() == c->collider.hulls.size());
    for (std::size_t i = 0; i < a->collider.hulls.size(); ++i) {
        CHECK(a->collider.hulls[i].points.size() == c->collider.hulls[i].points.size());
        CHECK(std::memcmp(a->collider.hulls[i].points.data(), c->collider.hulls[i].points.data(),
                          a->collider.hulls[i].points.size() * sizeof(Vec3)) == 0);
    }
    // the bits that must not change from one machine to the next: pinned, so a platform that rounds differently fails here
    CHECK(a->lodInfo[1].triangles == 672);
    CHECK(a->lodInfo[2].triangles == 202);
    CHECK(hash_of(a->lods[0]) == "889eeb3a9d729d010b13a0015c3fc06cc628537bf9503eda652704766524ca9f");
    CHECK(hash_of(a->mesh) == "24b2f6f4630d30ecbb71441dcb307c393e377d7815c6324b3ec65caa845a9648");
    CHECK(a->collider.hulls.size() == 4);
    // a one-bit difference in a hull point must show: a hash of the points quantised to micrometres
    std::string q;
    for (const ModelHull& h : a->collider.hulls)
        for (const Vec3& p : h.points)
            q += std::to_string(std::lround(p.x * 1000)) + "," + std::to_string(std::lround(p.y * 1000)) + "," +
                 std::to_string(std::lround(p.z * 1000)) + ";";
    CHECK(sha256_hex(q) == "3e832ed4a035569d279b11f0986f39852beade59fd9dc267e95566bea27bcbb1");
}

#include "fa/scene/lod.h"

TEST_CASE("lod: MeshRenderer.lods picks the mesh by camera distance") {
    MeshRenderer mr;
    mr.mesh = "assets/lamp.glb";
    CHECK(lod_mesh(mr, 100.0f) == "assets/lamp.glb");  // no entries
    mr.lods = J(R"([{"mesh":"assets/lamp.lod1.glb","distance":10},{"mesh":"assets/lamp.lod2.glb","distance":30}])");
    CHECK(lod_mesh(mr, 0.0f) == "assets/lamp.glb");
    CHECK(lod_mesh(mr, 9.99f) == "assets/lamp.glb");
    CHECK(lod_mesh(mr, 10.0f) == "assets/lamp.lod1.glb");
    CHECK(lod_mesh(mr, 29.0f) == "assets/lamp.lod1.glb");
    CHECK(lod_mesh(mr, 30.0f) == "assets/lamp.lod2.glb");
    CHECK(lod_mesh(mr, 1e6f) == "assets/lamp.lod2.glb");
    // malformed entries are skipped, an unsorted list still picks by distance
    mr.lods = J(
        R"([{"mesh":"assets/b.glb","distance":30},7,{"mesh":"","distance":1},{"distance":2},{"mesh":"assets/a.glb","distance":10},{"mesh":"x","distance":"far"}])");
    CHECK(lod_mesh(mr, 5.0f) == "assets/lamp.glb");
    CHECK(lod_mesh(mr, 15.0f) == "assets/a.glb");
    CHECK(lod_mesh(mr, 40.0f) == "assets/b.glb");
    mr.lods = J(R"({"not":"a list"})");
    CHECK(lod_mesh(mr, 40.0f) == "assets/lamp.glb");
}

TEST_CASE("game ready: a collider fitted to one part, with a radius and height of its own") {
    const ModelBuild b = build(kLamp);
    ModelColliderSpec spec;
    spec.shape = "capsule";
    auto all = model_fit_collider(b.data, spec);
    REQUIRE(all.ok());
    spec.part = "stem";
    auto stem = model_fit_collider(b.data, spec);
    REQUIRE(stem.ok());
    CHECK(stem->radius == doctest::Approx(0.2f).epsilon(0.05));
    CHECK(stem->radius < all->radius);
    CHECK(stem->center.y == doctest::Approx(2.0f).epsilon(0.01));
    // make_game_ready fits the part before a merge joins the part names
    ModelGameReady g =
        settings(R"({"merge":true,"collider":{"shape":"capsule","part":"stem","radius":0.3,"height":1.5}})");
    CHECK(g.collider.part == "stem");
    auto made = make_game_ready(b.data, g);
    REQUIRE(made.ok());
    CHECK(made->collider.radius == doctest::Approx(0.3f));
    CHECK(made->collider.height == doctest::Approx(1.5f));
    CHECK(game_ready_to_json(g)["collider"]["part"] == "stem");
    // a merged mesh lists "base+stem+bulb" as one part: the bulb still matches inside it
    auto mergedMesh = model_merge_by_material(b.data);
    REQUIRE(mergedMesh.ok());
    ModelColliderSpec bulb;
    bulb.shape = "box";
    bulb.part = "bulb";
    CHECK(model_fit_collider(*mergedMesh, bulb).ok());
    // an unknown part names the parts
    spec.part = "stemm";
    auto bad = model_fit_collider(b.data, spec);
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().hint.find("stem") != std::string::npos);
    CHECK(bad.error().hint.find("shade") != std::string::npos);
    // radius and height only fit the shapes that have them
    CHECK_FALSE(parse_game_ready(J(R"({"collider":{"shape":"box","radius":1}})"), "/gameReady").ok());
    CHECK_FALSE(parse_game_ready(J(R"({"collider":{"shape":"sphere","height":1}})"), "/gameReady").ok());
}
