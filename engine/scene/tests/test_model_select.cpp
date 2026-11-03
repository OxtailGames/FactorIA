// Selections by meaning and the edits on them (model_select.h): each query kind, each edit, kept parts, stability when the tree is
// re-evaluated or an upstream parameter changes, teaching warnings for an empty selection, validation errors and determinism.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <string>

#include "fa/scene/model_doc.h"
#include "fa/scene/model_select.h"

using namespace fa;

namespace {

Json J(const std::string& text) { return parse_json(text, "test").value(); }

ModelBuild build_of(const std::string& text) {
    auto doc = parse_model_doc(J(text), "t.model.json");
    REQUIRE_MESSAGE(doc.ok(), (doc.ok() ? std::string() : doc.error().to_string()));
    auto build = evaluate_model(*doc);
    REQUIRE_MESSAGE(build.ok(), (build.ok() ? std::string() : build.error().to_string()));
    return std::move(*build);
}

// A document with one edit node over `child`.
std::string doc_of(const std::string& node) { return R"({"format":"factoria.model/1","nodes":[)" + node + "]}"; }

std::string wrap(const std::string& op, const std::string& fields, const std::string& child) {
    return doc_of(R"({"op":")" + op + R"(",)" + fields + R"(,"children":[)" + child + "]}");
}

const std::string kBox = R"({"op":"box","size":[1,1,1],"part":"body"})";
const std::string kBox4 = R"({"op":"box","size":[1,1,1],"segments":[4,4,4],"part":"body"})";

std::vector<ModelIssue> issues_of(const std::string& text) {
    std::vector<ModelIssue> issues;
    (void)parse_model_doc(J(text), "t.model.json", &issues);
    return issues;
}

std::size_t part_triangles(const ModelBuild& b, const std::string& part) {
    std::size_t n = 0;
    for (const ModelPartInfo& p : b.parts)
        if (p.part == part) n += p.triangles;
    return n;
}

template <typename T>
bool same_vec(const std::vector<T>& x, const std::vector<T>& y) {
    return x.size() == y.size() && (x.empty() || std::memcmp(x.data(), y.data(), x.size() * sizeof(T)) == 0);
}
bool same_build(const ModelBuild& a, const ModelBuild& b) {
    return same_vec(a.data.positions, b.data.positions) && same_vec(a.data.normals, b.data.normals) && same_vec(a.data.indices, b.data.indices);
}

const ModelSelectionReport& first_edit(const ModelBuild& b) {
    REQUIRE(!b.edits.empty());
    return b.edits.front();
}

bool warned(const ModelSelectionReport& r, const std::string& part) {
    for (const std::string& w : r.warnings)
        if (w.find(part) != std::string::npos) return true;
    return false;
}

}  // namespace

TEST_CASE("model select: the catalog lists every query with documented fields") {
    const auto& queries = model_queries();
    for (const char* by : {"normal", "part", "top", "bottom", "box", "sphere", "halfspace", "and", "or", "not", "grow", "shrink", "border", "sharp",
                           "between_parts", "loop"}) {
        bool found = false;
        for (const ModelQueryInfo& q : queries)
            if (q.by == by) {
                found = true;
                CHECK_FALSE(q.doc.empty());
                for (const ModelFieldInfo& f : q.fields) CHECK_FALSE(f.doc.empty());
            }
        CHECK_MESSAGE(found, by);
    }
    for (const char* op : {"extrude_faces", "inset_faces", "loop_cut", "bevel_edges", "delete_faces", "assign_faces"}) {
        CHECK(model_is_edit_op(op));
        bool found = false;
        for (const ModelOpInfo& o : model_ops()) found = found || o.op == op;
        CHECK_MESSAGE(found, op);
    }
    CHECK_FALSE(model_is_edit_op("box"));
}

TEST_CASE("model select: face queries by normal, part, region, extreme") {
    auto count = [&](const std::string& query, const std::string& child = kBox) {
        // assign_faces reports without changing the shape
        const ModelBuild b = build_of(wrap("assign_faces", R"("toPart":"x","faces":)" + query, child));
        return first_edit(b).matched;
    };
    CHECK(count(R"({"by":"normal","direction":"top"})") == 2);
    CHECK(count(R"({"by":"normal","direction":"top"})", kBox4) == 32);
    CHECK(count(R"({"by":"normal","direction":[0,-1,0]})") == 2);
    CHECK(count(R"({"by":"normal","direction":"left","tolerance":100})") == 10);  // the left face plus the four sides at 90 degrees
    CHECK(count(R"({"by":"part","part":"body"})") == 12);
    CHECK(count(R"({"by":"part","parts":["body","other"]})") == 12);
    CHECK(count(R"({"by":"top"})") == 2);
    CHECK(count(R"({"by":"bottom","axis":"x"})") == 2);
    CHECK(count(R"({"by":"box","min":[-1,0.1,-1],"max":[1,1,1],"contain":"all"})", kBox4) == 64);
    CHECK(count(R"({"by":"box","min":[-1,0.1,-1],"max":[1,1,1],"contain":"any"})", kBox4) > 32);
    CHECK(count(R"({"by":"sphere","center":[0,0.5,0],"radius":0.2,"contain":"any"})", kBox4) > 0);
    CHECK(count(R"({"by":"halfspace","point":[0,0,0],"normal":[0,1,0],"contain":"all"})", kBox4) == 96);
    CHECK(count(R"({"by":"all"})") == 12);
}

TEST_CASE("model select: and, or, not, grow, shrink") {
    auto count = [&](const std::string& query) {
        return first_edit(build_of(wrap("assign_faces", R"("toPart":"x","faces":)" + query, kBox4))).matched;
    };
    const std::string top = R"({"by":"normal","direction":"top"})";
    const std::string front = R"({"by":"normal","direction":"front"})";
    CHECK(count(R"({"by":"or","of":[)" + top + "," + front + "]}") == 64);
    CHECK(count(R"({"by":"and","of":[)" + top + "," + front + "]}") == 0);
    CHECK(count(R"({"by":"not","of":)" + top + "}") == 192 - 32);
    CHECK(count(R"({"by":"grow","of":)" + top + "}") > 32);
    CHECK(count(R"({"by":"shrink","of":)" + top + "}") < 32);
    CHECK(count(R"({"by":"shrink","of":{"by":"grow","of":)" + top + "}}") >= 32);
}

TEST_CASE("model select: space node and model") {
    const std::string tilted = doc_of(R"({"op":"assign_faces","toPart":"x","faces":{"by":"normal","direction":"top","tolerance":10,"space":"model"},)"
                                      R"("rotation":[0,0,90],"children":[)" + kBox + "]}");
    const ModelBuild b = build_of(tilted);
    CHECK(first_edit(b).matched == 2);
    // in the node's space the same query picks the faces that point up before the rotation (also two)
    const std::string node = doc_of(R"({"op":"assign_faces","toPart":"x","faces":{"by":"normal","direction":"top","tolerance":10},)"
                                    R"("rotation":[0,0,90],"children":[)" + kBox + "]}");
    CHECK(first_edit(build_of(node)).matched == 2);
    CHECK_FALSE(same_build(b, build_of(node)));  // different faces got the part, so the part split differs
}

TEST_CASE("model select: edge queries") {
    auto edges = [&](const std::string& query, const std::string& child) {
        return first_edit(build_of(wrap("bevel_edges", R"("width":0.02,"segments":1,"edges":)" + query, child))).matched;
    };
    CHECK(edges(R"({"by":"sharp","angle":30})", kBox) == 12);
    CHECK(edges(R"({"by":"sharp","angle":120})", kBox) == 0);
    CHECK(edges(R"({"by":"border","faces":{"by":"normal","direction":"top"}})", kBox) == 4);
    CHECK(edges(R"({"by":"all"})", kBox) > 12);
    CHECK(edges(R"({"by":"not","of":{"by":"sharp"}})", kBox4) > 0);
    CHECK(edges(R"({"by":"and","of":[{"by":"sharp"},{"by":"border","faces":{"by":"normal","direction":"top"}}]})", kBox) == 4);
    CHECK(edges(R"({"by":"or","of":[{"by":"sharp"},{"by":"border","faces":{"by":"normal","direction":"top"}}]})", kBox) == 12);
    // between_parts needs two parts
    const std::string split = R"({"op":"assign_faces","toPart":"lid","faces":{"by":"normal","direction":"top"},"children":[)" + kBox4 + "]}";
    const ModelBuild b = build_of(wrap("bevel_edges", R"("width":0.02,"segments":1,"edges":{"by":"between_parts","a":"lid","b":"body"})", split));
    CHECK(b.edits.back().matched == 16);
    CHECK(b.stats.closed());
}

TEST_CASE("model edit: extrude_faces keeps the surface closed, parts and volume") {
    const ModelBuild b = build_of(wrap("extrude_faces", R"("faces":{"by":"normal","direction":"top"},"distance":0.25,"newPart":"bump")", kBox));
    CHECK(b.stats.closed());
    CHECK(b.stats.volume == doctest::Approx(1.25).epsilon(0.01));
    CHECK(part_triangles(b, "bump") > 0);
    CHECK(part_triangles(b, "body") > 0);
    CHECK(b.stats.bmax.y == doctest::Approx(0.75f));
    // without newPart the new faces inherit the source part
    const ModelBuild inherit = build_of(wrap("extrude_faces", R"("faces":{"by":"normal","direction":"top"},"distance":0.25)", kBox));
    CHECK(part_triangles(inherit, "body") == inherit.stats.triangles);
}

TEST_CASE("model edit: inset_faces, pocket with negative depth and the width limit") {
    const ModelBuild b = build_of(wrap("inset_faces", R"("faces":{"by":"normal","direction":"top"},"thickness":0.2,"newPart":"frame")", kBox));
    CHECK(b.stats.closed());
    CHECK(b.stats.volume == doctest::Approx(1.0).epsilon(0.001));
    CHECK(part_triangles(b, "frame") == 8);
    const ModelBuild pocket = build_of(wrap("inset_faces", R"("faces":{"by":"normal","direction":"top"},"thickness":0.2,"depth":-0.1)", kBox));
    CHECK(pocket.stats.closed());
    CHECK(pocket.stats.volume == doctest::Approx(1.0 - 0.1 / 3 * (1 + 0.36 + 0.6)).epsilon(0.002));
    auto doc = parse_model_doc(J(wrap("inset_faces", R"("faces":{"by":"normal","direction":"top"},"thickness":2)", kBox)), "t.model.json");
    REQUIRE(doc.ok());
    auto wide = evaluate_model(*doc);
    REQUIRE_FALSE(wide.ok());
    CHECK(wide.error().to_string().find("most") != std::string::npos);
}

TEST_CASE("model edit: loop_cut keeps the shape, splits faces and keeps parts") {
    const ModelBuild b = build_of(wrap("loop_cut", R"("axis":"y","ratio":0.5)", kBox));
    CHECK(b.stats.closed());
    CHECK(b.stats.volume == doctest::Approx(1.0).epsilon(1e-4));
    CHECK(b.stats.triangles > 12);
    CHECK(part_triangles(b, "body") == b.stats.triangles);
    const ModelBuild two = build_of(wrap("loop_cut", R"("count":2)", kBox));
    CHECK(two.stats.closed());
    CHECK(two.stats.volume == doctest::Approx(1.0).epsilon(1e-4));
    CHECK(two.stats.triangles > b.stats.triangles);
    // a loop query on the result finds the ring
    const std::string cut = R"({"op":"loop_cut","at":0.1,"children":[)" + kBox + "]}";
    const ModelBuild ring = build_of(wrap("bevel_edges", R"("width":0.01,"segments":1,"edges":{"by":"loop","at":0.1})", cut));
    CHECK(ring.edits.back().matched >= 4);
    CHECK(ring.edits.back().measure == doctest::Approx(4.0).epsilon(1e-3));
}

TEST_CASE("model edit: bevel_edges rounds only the chosen edges") {
    const ModelBuild one = build_of(wrap("bevel_edges", R"("width":0.1,"segments":2,"edges":{"by":"border","faces":{"by":"normal","direction":"top"}})", kBox));
    CHECK(one.stats.closed());
    CHECK(one.stats.volume < 1.0);
    const ModelBuild all = build_of(wrap("bevel_edges", R"("width":0.1,"segments":2,"edges":{"by":"sharp"})", kBox));
    CHECK(all.stats.closed());
    CHECK(all.stats.volume < one.stats.volume);
    CHECK(part_triangles(one, "body") == one.stats.triangles);
}

TEST_CASE("model edit: delete_faces and assign_faces") {
    const ModelBuild del = build_of(wrap("delete_faces", R"("faces":{"by":"normal","direction":"top"})", kBox));
    CHECK(del.stats.triangles == 10);
    CHECK(del.stats.boundaryEdges == 4);
    const ModelBuild as = build_of(wrap("assign_faces", R"("faces":{"by":"normal","direction":"top"},"toPart":"lid")", kBox));
    CHECK(as.stats.closed());
    CHECK(part_triangles(as, "lid") == 2);
    CHECK(part_triangles(as, "body") == 10);
    CHECK(as.stats.volume == doctest::Approx(1.0).epsilon(1e-5));
}

TEST_CASE("model select: the same query follows an upstream change") {
    for (const char* segs : {"[1,1,1]", "[3,3,3]", "[8,8,8]"}) {
        for (const char* size : {"[1,1,1]", "[2,3,2]"}) {
            const std::string box = std::string(R"({"op":"box","size":)") + size + R"(,"segments":)" + segs + R"(,"part":"body"})";
            const ModelBuild b = build_of(wrap("extrude_faces", R"("faces":{"by":"normal","direction":"top"},"distance":0.2,"newPart":"bump")", box));
            CHECK_MESSAGE(b.stats.closed(), segs, size);
            const float top = std::string(size) == "[1,1,1]" ? 0.5f : 1.5f;
            CHECK_MESSAGE(b.stats.bmax.y == doctest::Approx(top + 0.2f), segs, size);
            CHECK_MESSAGE(first_edit(b).matched == 2u * std::stoul(std::string(1, segs[1])) * std::stoul(std::string(1, segs[1])), segs, size);
        }
    }
}

TEST_CASE("model select: an empty selection leaves the mesh and says what to try") {
    {
        const ModelBuild b = build_of(wrap("extrude_faces", R"("faces":{"by":"part","part":"bodi"})", kBox));
        const ModelSelectionReport& r = first_edit(b);
        CHECK(r.matched == 0);
        REQUIRE(!r.warnings.empty());
        CHECK(warned(r, "body"));  // did you mean
        CHECK(b.stats.triangles == 12);
        CHECK(!b.warnings.empty());
    }
    {
        const ModelBuild b = build_of(wrap("extrude_faces", R"("faces":{"by":"normal","direction":"top"},"distance":0.1,"newPart":"a")", R"({"op":"box","size":[1,1,1],"rotation":[0,0,0]})"));
        CHECK(first_edit(b).matched == 2);
    }
    {
        const ModelBuild b = build_of(wrap("extrude_faces", R"("faces":{"by":"box","min":[5,5,5],"max":[6,6,6]})", kBox));
        CHECK(first_edit(b).matched == 0);
        CHECK(warned(first_edit(b), "spans"));
    }
    {
        const ModelBuild b = build_of(wrap("bevel_edges", R"("edges":{"by":"loop","at":3})", kBox));
        CHECK(first_edit(b).matched == 0);
        CHECK_FALSE(first_edit(b).warnings.empty());
    }
}

TEST_CASE("model select: wrong queries are errors that teach") {
    auto err = [&](const std::string& faces) {
        return issues_of(wrap("extrude_faces", R"("faces":)" + faces, kBox));
    };
    auto has = [&](const std::vector<ModelIssue>& issues, const std::string& part) {
        for (const ModelIssue& i : issues)
            if ((i.message + " " + i.hint).find(part) != std::string::npos) return true;
        return false;
    };
    CHECK(has(err(R"({"by":"nromal"})"), "normal"));
    CHECK(has(err(R"({"by":"normal","direction":"top","bogus":1})"), "bogus"));
    CHECK(!err(R"({"by":"sharp"})").empty());  // an edge query where faces are expected
    CHECK(!err(R"({"by":"box","min":[1,1,1],"max":[0,0,0]})").empty());
    CHECK(!err(R"({"by":"normal","direction":[0,0,0]})").empty());
    CHECK(!err(R"({"by":"normal","direction":"up"})").empty());
    CHECK(has(err(R"({"by":"normal","direction":"up"})"), "top"));
    CHECK(!issues_of(wrap("loop_cut", R"("at":0.1,"ratio":0.5)", kBox)).empty());
    CHECK(!issues_of(wrap("assign_faces", R"("faces":{"by":"all"})", kBox)).empty());
    CHECK(!issues_of(wrap("extrude_faces", R"("distance":1)", kBox)).empty());
    CHECK(err(R"({"by":"normal","direction":"top"})").empty());
}

TEST_CASE("model select: building twice is byte-identical") {
    const std::string text = wrap("extrude_faces", R"("faces":{"by":"and","of":[{"by":"normal","direction":"top","space":"model"},{"by":"part","part":"body"}]},"distance":0.2,"newPart":"p","rotation":[10,20,30])",
                                  R"({"op":"loop_cut","count":3,"children":[)" + kBox4 + "]}");
    CHECK(same_build(build_of(text), build_of(text)));
}
