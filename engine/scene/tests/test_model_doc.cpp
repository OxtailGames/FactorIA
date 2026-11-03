// Model documents: reading (defaults, errors with pointers, did-you-mean), evaluation (parts, materials, colours, transforms,
// determinism), finding nodes and the schema.
#include <doctest.h>

#include <cmath>
#include <cstring>

#include "fa/core/json_schema.h"
#include "fa/scene/model_doc.h"

using namespace fa;

namespace {

Json J(const char* text) { return parse_json(text, "test").value(); }

std::vector<ModelIssue> issues_of(const char* text) {
    std::vector<ModelIssue> issues;
    (void)parse_model_doc(J(text), "t.model.json", &issues);
    return issues;
}

bool has_issue(const std::vector<ModelIssue>& issues, const std::string& pointer, const std::string& messagePart = {}, const std::string& hintPart = {}) {
    for (const ModelIssue& i : issues)
        if (i.pointer == pointer && i.message.find(messagePart) != std::string::npos && i.hint.find(hintPart) != std::string::npos) return true;
    return false;
}

ModelBuild build_of(const char* text, const ModelEvalOptions& options = {}) {
    auto doc = parse_model_doc(J(text), "t.model.json");
    REQUIRE_MESSAGE(doc.ok(), (doc.ok() ? std::string() : doc.error().to_string()));
    auto build = evaluate_model(*doc, options);
    REQUIRE_MESSAGE(build.ok(), (build.ok() ? std::string() : build.error().to_string()));
    return std::move(*build);
}

ModelTextOutline square_glyph() {
    ModelTextOutline o;
    auto cmd = [&](ModelGlyphCmd::Kind k, float x, float y) {
        ModelGlyphCmd c;
        c.kind = k;
        c.x = x;
        c.y = y;
        o.cmds.push_back(c);
    };
    cmd(ModelGlyphCmd::Move, 0, -1);
    cmd(ModelGlyphCmd::Line, 1, -1);
    cmd(ModelGlyphCmd::Line, 1, 0);
    cmd(ModelGlyphCmd::Line, 0, 0);
    cmd(ModelGlyphCmd::Close, 0, 0);
    o.glyphs = 1;
    return o;
}

}  // namespace

TEST_CASE("model doc: the catalog lists every operation with documented fields") {
    const char* expected[] = {"box", "rounded_box", "cylinder", "cone", "sphere", "capsule", "torus", "grid", "stairs", "arch", "pipe", "text", "group"};
    REQUIRE(model_ops().size() == std::size(expected));
    for (std::size_t i = 0; i < std::size(expected); ++i) {
        const ModelOpInfo& op = model_ops()[i];
        CHECK(op.op == expected[i]);
        CHECK(!op.doc.empty());
        for (const ModelFieldInfo& f : op.fields) CHECK_MESSAGE(!f.doc.empty(), op.op << "." << f.key);
    }
    for (const ModelFieldInfo& f : model_common_fields()) CHECK_MESSAGE(!f.doc.empty(), f.key);
}

TEST_CASE("model doc: a minimal document gets the documented defaults") {
    auto doc = parse_model_doc(J(R"({"format":"factoria.model/1","nodes":[{"op":"cylinder"},{"op":"sphere","radius":2}]})"));
    REQUIRE(doc.ok());
    REQUIRE(doc->nodes.size() == 2);
    CHECK(doc->nodes[0].params["segments"] == 24);
    CHECK(doc->nodes[0].params["capTop"] == true);
    CHECK_FALSE(doc->nodes[0].params.contains("radiusTop"));
    CHECK(doc->nodes[1].params["radius"] == 2.0);
    CHECK_FALSE(doc->nodes[1].params.contains("rings"));
    CHECK(doc->nodes[1].pointer == "/nodes/1");
    CHECK(doc->nodes[0].scale.x == 1.0f);
}

TEST_CASE("model doc: problems carry the JSON pointer, the fix and did-you-mean") {
    auto a = issues_of(R"({"format":"factoria.model/1","nodes":[{"op":"cylnder"}]})");
    CHECK(has_issue(a, "/nodes/0/op", "unknown operation", "cylinder"));

    auto b = issues_of(R"({"format":"factoria.model/1","nodes":[{"op":"box","sise":[1,2,3]}]})");
    CHECK(has_issue(b, "/nodes/0/sise", "not a field", "size"));

    auto c = issues_of(R"({"format":"factoria.model/1","nodes":[{"op":"group","children":[{"op":"sphere","radius":-1},{"op":"box","size":[1,2]}]}]})");
    CHECK(has_issue(c, "/nodes/0/children/0/radius", "from 0.001 to 1000"));
    CHECK(has_issue(c, "/nodes/0/children/1/size", "list"));

    auto d = issues_of(R"({"format":"factoria.model/1","materials":{"wood":{}},"nodes":[{"op":"box","material":"wod"}]})");
    CHECK(has_issue(d, "/nodes/0/material", "not in", "wood"));

    auto e = issues_of(R"({"format":"factoria.model/1","nodes":[{"op":"box","id":"a"},{"op":"box","id":"a"}]})");
    CHECK(has_issue(e, "/nodes/1/id", "already used by /nodes/0"));

    auto f = issues_of(R"({"format":"factoria.model/1","nodes":[{"op":"torus","radius":0.2,"tube":0.5},{"op":"arch","openingWidth":3},{"op":"capsule","height":0.5}]})");
    CHECK(has_issue(f, "/nodes/0/tube", "larger"));
    CHECK(has_issue(f, "/nodes/1/openingWidth", "not smaller"));
    CHECK(has_issue(f, "/nodes/2/height", "less than twice"));

    auto g = issues_of(R"({"nodes":[{"op":"text"}],"extra":1})");
    CHECK(has_issue(g, "/format"));
    CHECK(has_issue(g, "/extra"));
    CHECK(has_issue(g, "/nodes/0", "need \"text\""));

    auto h = issues_of(R"({"format":"factoria.model/1","nodes":[{"op":"box","scale":[1,0,1],"color":[2,0,0],"align":"middle"}]})");
    CHECK(has_issue(h, "/nodes/0/scale", "0"));
    CHECK(has_issue(h, "/nodes/0/color"));
    CHECK(has_issue(h, "/nodes/0/align", "one of", "center"));

    // the first problem is the returned error, with the file and the pointer
    auto bad = parse_model_doc(J(R"({"format":"factoria.model/1","nodes":[{"op":"boxx"},{"op":"sphere","segments":1}]})"), "door.model.json");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("door.model.json /nodes/0/op") != std::string::npos);
    CHECK(bad.error().message.find("1 more problem") != std::string::npos);
}

TEST_CASE("model doc: limits on nodes and nesting") {
    std::string deep = R"({"format":"factoria.model/1","nodes":[)";
    for (int i = 0; i < kModelDocMaxDepth + 2; ++i) deep += R"({"op":"group","children":[)";
    deep += R"({"op":"box"})";
    for (int i = 0; i < kModelDocMaxDepth + 2; ++i) deep += "]}";
    deep += "]}";
    std::vector<ModelIssue> issues;
    (void)parse_model_doc(parse_json(deep, "t").value(), "t", &issues);
    bool found = false;
    for (const ModelIssue& i : issues) found |= i.message.find("nested") != std::string::npos;
    CHECK(found);
}

TEST_CASE("model eval: parts and materials become submeshes, colours and parts are inherited") {
    const ModelBuild b = build_of(R"({
        "format":"factoria.model/1",
        "materials":{"wood":{"color":[0.5,0.3,0.1,1]},"steel":{"color":[0.7,0.7,0.8,1],"metallic":1}},
        "nodes":[
          {"op":"group","part":"door","material":"wood","children":[
              {"op":"box","size":[1,2,0.1]},
              {"op":"cylinder","radius":0.05,"height":0.2,"material":"steel","part":"handle","position":[0.4,0,0.1],"color":"#ff0000"}]},
          {"op":"box","size":[0.2,0.2,0.2],"position":[3,0,0]}
        ]})");
    REQUIRE(b.parts.size() == 3);
    CHECK(b.parts[0].part == "door");
    CHECK(b.parts[0].material == "wood");
    CHECK(b.parts[0].triangles == 12);
    CHECK(b.parts[1].part == "handle");
    CHECK(b.parts[1].material == "steel");
    CHECK(b.parts[2].part.empty());
    CHECK(b.parts[2].material.empty());
    REQUIRE(b.data.submeshes.size() == 3);
    CHECK(b.data.submeshes[0].part == "door");
    CHECK(b.data.submeshes[1].material.name == "steel");
    CHECK(b.data.submeshes[1].material.metallic.value_or(0) == 1.0f);
    CHECK(b.data.submeshes[0].start == 0);
    CHECK(b.data.submeshes[1].start == b.data.submeshes[0].count);
    CHECK(b.data.submeshes[2].start + b.data.submeshes[2].count == b.data.indices.size());
    CHECK(b.stats.triangles == b.data.triangle_count());
    // vertex colours: the handle is red, the others white (the colours exist for every vertex)
    REQUIRE(b.data.colors.size() == b.data.vertex_count() * 4);
    const std::uint32_t handleVertex = b.data.indices[b.data.submeshes[1].start];
    CHECK(b.data.colors[handleVertex * 4] == 1.0f);
    CHECK(b.data.colors[handleVertex * 4 + 1] == 0.0f);
    const std::uint32_t doorVertex = b.data.indices[0];
    CHECK(b.data.colors[doorVertex * 4 + 1] == 1.0f);
    // the part's bounds are its own
    CHECK(b.parts[2].bmin.x == doctest::Approx(2.9f));
    CHECK(b.parts[2].bmax.x == doctest::Approx(3.1f));
}

TEST_CASE("model eval: transforms, align, enabled and mirroring") {
    const ModelBuild stand = build_of(R"({"format":"factoria.model/1","nodes":[{"op":"box","size":[1,2,1],"align":"bottom","position":[0,5,0]}]})");
    CHECK(stand.stats.bmin.y == doctest::Approx(5.0f));
    CHECK(stand.stats.bmax.y == doctest::Approx(7.0f));
    const ModelBuild hang = build_of(R"({"format":"factoria.model/1","nodes":[{"op":"box","size":[1,2,1],"align":"top"}]})");
    CHECK(hang.stats.bmax.y == doctest::Approx(0.0f));

    const ModelBuild rot = build_of(R"({"format":"factoria.model/1","nodes":[{"op":"box","size":[2,1,1],"rotation":[0,90,0]}]})");
    CHECK(rot.stats.bmax.x == doctest::Approx(0.5f));
    CHECK(rot.stats.bmax.z == doctest::Approx(1.0f));

    const ModelBuild off = build_of(R"({"format":"factoria.model/1","nodes":[{"op":"box"},{"op":"sphere","enabled":false},{"op":"group","enabled":false,"children":[{"op":"box"}]}]})");
    CHECK(off.stats.triangles == 12);

    // a mirrored node keeps facing out: the solid still has a positive volume and is closed
    const ModelBuild mirror = build_of(R"({"format":"factoria.model/1","nodes":[{"op":"cone","scale":[-1,1,1],"position":[2,0,0]}]})");
    CHECK(mirror.stats.closed());
    CHECK(mirror.stats.volume > 0);

    // nested groups multiply
    const ModelBuild nest = build_of(R"({"format":"factoria.model/1","nodes":[{"op":"group","position":[10,0,0],"scale":2,"children":[{"op":"box","position":[1,0,0]}]}]})");
    CHECK(nest.stats.bmin.x == doctest::Approx(11.0f));
    CHECK(nest.stats.bmax.x == doctest::Approx(13.0f));
}

TEST_CASE("model eval: the same document gives byte-identical meshes, closed and facing out") {
    const char* text = R"({"format":"factoria.model/1","nodes":[
        {"op":"rounded_box","size":[1,1,1],"radius":0.2},{"op":"capsule","position":[2,0,0]},{"op":"torus","position":[4,0,0]},
        {"op":"pipe","position":[6,0,0]},{"op":"stairs","position":[8,0,0]},{"op":"arch","position":[10,0,0]},{"op":"sphere","position":[12,0,0]}]})";
    const ModelBuild a = build_of(text), b = build_of(text);
    REQUIRE(a.data.positions.size() == b.data.positions.size());
    CHECK(std::memcmp(a.data.positions.data(), b.data.positions.data(), a.data.positions.size() * sizeof(float)) == 0);
    CHECK(std::memcmp(a.data.normals.data(), b.data.normals.data(), a.data.normals.size() * sizeof(float)) == 0);
    CHECK(std::memcmp(a.data.uvs.data(), b.data.uvs.data(), a.data.uvs.size() * sizeof(float)) == 0);
    CHECK(a.data.indices == b.data.indices);
    CHECK(a.stats.closed());
    CHECK(a.stats.volume > 0);
    CHECK(a.stats.degenerateTriangles == 0);
}

TEST_CASE("model eval: text uses the given outline source and reports what it needs") {
    auto doc = parse_model_doc(J(R"({"format":"factoria.model/1","nodes":[{"op":"text","text":"I","font":"assets/fonts/x.ttf","size":2,"depth":0.5}]})"));
    REQUIRE(doc.ok());
    // without a source the node says so, with its pointer
    auto none = evaluate_model(*doc);
    REQUIRE_FALSE(none.ok());
    CHECK(none.error().message.find("/nodes/0") != std::string::npos);

    ModelTextRequest seen;
    ModelEvalOptions options;
    options.text = [&](const ModelTextRequest& r) -> Result<ModelTextOutline> {
        seen = r;
        ModelTextOutline o = square_glyph();
        o.missing = {U'中'};
        return o;
    };
    auto build = evaluate_model(*doc, options);
    REQUIRE(build.ok());
    CHECK(seen.text == "I");
    CHECK(seen.font == "assets/fonts/x.ttf");
    CHECK(seen.anchor == "middle");
    CHECK(build->stats.closed());
    CHECK(build->stats.bmax.y == doctest::Approx(2.0f));
    CHECK(build->stats.bmax.z == doctest::Approx(0.25f));
    REQUIRE(build->inputs.size() == 1);
    CHECK(build->inputs[0] == "assets/fonts/x.ttf");
    REQUIRE(build->warnings.size() == 1);
    CHECK(build->warnings[0].find("U+4E2D") != std::string::npos);

    options.text = [](const ModelTextRequest&) -> Result<ModelTextOutline> { return make_error("font 'x' not found", "Check the path."); };
    auto failed = evaluate_model(*doc, options);
    REQUIRE_FALSE(failed.ok());
    CHECK(failed.error().message.find("/nodes/0: font 'x' not found") != std::string::npos);
}

TEST_CASE("model eval: an empty model is an error that says what to do") {
    auto doc = parse_model_doc(J(R"({"format":"factoria.model/1","nodes":[{"op":"box","enabled":false}]})"));
    REQUIRE(doc.ok());
    auto build = evaluate_model(*doc);
    REQUIRE_FALSE(build.ok());
    CHECK(build.error().message.find("no triangles") != std::string::npos);
}

TEST_CASE("model doc: finding nodes by id and by pointer") {
    Json doc = J(R"({"format":"factoria.model/1","nodes":[{"op":"box","id":"base"},{"op":"group","id":"top","children":[{"op":"sphere","id":"ball"},{"op":"box"}]}]})");
    std::string pointer, why;
    Json* ball = find_model_node(doc, "ball", &pointer, &why);
    REQUIRE(ball);
    CHECK(pointer == "/nodes/1/children/0");
    CHECK((*ball)["op"] == "sphere");
    CHECK(find_model_node(doc, "/nodes/1/children/1", &pointer, &why) != nullptr);
    CHECK(find_model_node(doc, "/nodes/0", &pointer, &why) != nullptr);

    CHECK(find_model_node(doc, "bal", &pointer, &why) == nullptr);
    CHECK(why.find("ball") != std::string::npos);
    CHECK(find_model_node(doc, "/nodes/7", &pointer, &why) == nullptr);
    CHECK(why.find("outside") != std::string::npos);
    CHECK(find_model_node(doc, "/format", &pointer, &why) == nullptr);
    CHECK(find_model_node(doc, "/nodes/0/size", &pointer, &why) == nullptr);

    const auto ids = model_node_ids(doc);
    REQUIRE(ids.size() == 3);
    CHECK(ids[2].first == "ball");
    CHECK(ids[2].second == "/nodes/1/children/0");
}

TEST_CASE("model doc: the schema accepts what the reader accepts and rejects what it rejects") {
    const Json schema = model_doc_schema();
    const Json good = J(R"({"$schema":"x","format":"factoria.model/1","doc":"d","output":{"path":"assets/a.glb"},
        "materials":{"m":{"color":[1,0,0,1],"roughness":0.5}},
        "nodes":[{"op":"group","part":"p","material":"m","color":"#ff00ff","children":[
            {"op":"box","size":2,"segments":[1,2,3],"align":"bottom","rotation":[0,45,0]},
            {"op":"text","text":"hi","anchor":"start"}]},{"op":"cylinder","radiusTop":0.2}]})");
    for (const SchemaError& e : validate_json(schema, good)) FAIL_CHECK(e.to_string());
    REQUIRE(parse_model_doc(good).ok());

    CHECK_FALSE(validate_json(schema, J(R"({"format":"factoria.model/2","nodes":[]})")).empty());
    CHECK_FALSE(validate_json(schema, J(R"({"format":"factoria.model/1","nodes":[{"op":"boxx"}]})")).empty());
    CHECK_FALSE(validate_json(schema, J(R"({"format":"factoria.model/1","nodes":[{"op":"box","sise":1}]})")).empty());
    CHECK_FALSE(validate_json(schema, J(R"({"format":"factoria.model/1","nodes":[{"op":"sphere","segments":2}]})")).empty());
    CHECK_FALSE(validate_json(schema, J(R"({"format":"factoria.model/1","nodes":[{"op":"text"}]})")).empty());
}
