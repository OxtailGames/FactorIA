// The node graph of a material (fa/tooling/material_graph.h): the library, the checks and their teaching errors, the generated
// snippet (a golden text, determinism, the hash), hand-edit protection of the commands, and one graph with every node type
// compiled by the real sokol-shdc for every dialect (skipped with a message where none is installed).
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <set>

#include "fa/core/hash.h"
#include "fa/core/json_schema.h"
#include "fa/tooling/material_graph.h"
#include "fa/tooling/shaders.h"
#include "fa_test_paths.h"  // FA_REPO_ROOT
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// The dissolve of the docs: noise burns the surface away; a param drives the threshold.
const char* kDissolveMaterial = R"({
  "format": "factoria.material/1",
  "doc": "Dissolve: noise burns the surface away with a glowing edge.",
  "shader": "shaders/dissolve.surface.glsl",
  "alphaMode": "clip",
  "params": {
    "dissolve": { "type": "float", "default": 0.0, "min": 0.0, "max": 1.0, "doc": "0 shows the surface, 1 dissolves it all." }
  },
  "graph": {
    "nodes": [
      { "id": "noise", "type": "noise.fbm", "pos": [0, 0], "inputs": { "scale": 6.0 } },
      { "id": "amount", "type": "param", "pos": [0, 120], "param": "dissolve" },
      { "id": "burn", "type": "dissolve", "pos": [220, 60], "inputs": { "edgeWidth": 0.06, "edgeColor": [1.0, 0.4, 0.1] } },
      { "id": "out", "type": "output", "pos": [440, 60], "inputs": { "albedo": [0.6, 0.6, 0.65], "roughness": 0.7 } }
    ],
    "links": [
      { "from": "noise.value", "to": "burn.noise" },
      { "from": "amount.value", "to": "burn.threshold" },
      { "from": "burn.alpha", "to": "out.alpha" },
      { "from": "burn.emission", "to": "out.emission" }
    ]
  }
})";

std::string fixture(const std::string& name) {
    return testing::read_all(stdfs::path(FA_REPO_ROOT) / "tools/common/tests/fixtures" / name);
}

std::string without_cr(std::string s) {
    s.erase(std::remove(s.begin(), s.end(), '\r'), s.end());
    return s;
}

// A material the checks run on: params, textures and the graph under test.
MaterialDef material_with(const Json& doc) {
    MaterialParse mp = parse_material(doc, "");
    // a graph error is a parse error: the material is still filled in as far as it got
    return mp.material;
}

Json base_doc() {
    return Json::parse(R"({
      "format": "factoria.material/1",
      "shader": "shaders/g.surface.glsl",
      "params": {
        "amount": { "type": "float", "default": 0.5, "doc": "A float." },
        "tint": { "type": "color", "default": [1, 0, 0, 1], "doc": "A color." },
        "wave": { "type": "vec2", "default": [1, 2], "doc": "A vec2." }
      },
      "textures": { "albedoTex": { "doc": "Albedo." } }
    })");
}

// The checker's errors of a graph on the base material.
GraphCheck check_of(const char* graph, const std::string& kind = "mesh") {
    Json doc = base_doc();
    const MaterialDef def = material_with(doc);
    return check_material_graph(Json::parse(graph), def, kind);
}

bool has_error(const GraphCheck& c, const std::string& pointer, const std::string& text) {
    for (const MaterialIssue& e : c.errors)
        if (e.pointer == pointer && e.message.find(text) != std::string::npos) return true;
    return false;
}
std::string failure(const CommandResult& r) {
    return r.ok ? std::string() : r.error.value("message", std::string()) + " " + r.error.value("hint", std::string());
}
std::string all_errors(const GraphCheck& c) {
    std::string out;
    for (const MaterialIssue& e : c.errors) out += e.to_string() + "\n";
    return out;
}

struct Project {
    testing::TempDir dir;
    CommandRegistry registry;
    Project() {
        write("materials/dissolve.material.json", kDissolveMaterial);
        register_material_graph_commands(registry, dir.str());
    }
    void write(const std::string& rel, const std::string& text) { testing::write_all(dir.path / rel, text); }
    std::string read(const std::string& rel) const { return testing::read_all(dir.path / rel); }
    Json doc(const std::string& rel = "materials/dissolve.material.json") const { return Json::parse(read(rel)); }
    CommandResult call(const char* name, const char* args) { return registry.call(name, Json::parse(args)); }
};

}  // namespace

// ---------------------------------------------------------------------------------------------------------------
// The library
// ---------------------------------------------------------------------------------------------------------------

TEST_CASE("graph library: every node type and port is documented and the table is consistent") {
    std::set<std::string> seen;
    CHECK(graph_node_library().size() >= 45);
    for (const GraphNodeType& t : graph_node_library()) {
        CAPTURE(t.type);
        // a type is listed once; only the output node has one entry per kind (same name, the fields of its kind)
        std::string key = t.type;
        if (t.type == kGraphOutputNode)
            for (const std::string& k : t.kinds) key += "/" + k;
        CHECK(seen.insert(key).second);
        CHECK_FALSE(t.doc.empty());
        CHECK_FALSE(t.category.empty());
        CHECK_FALSE(t.kinds.empty());
        CHECK(t.expr.size() == t.outputs.size());
        for (const GraphPort& p : t.inputs) {
            CAPTURE(p.name);
            CHECK_FALSE(p.doc.empty());
            CHECK((p.type == "float" || p.type == "vec2" || p.type == "vec3" || p.type == "vec4" || p.type == "gen"));
        }
        for (const GraphPort& p : t.outputs) {
            CAPTURE(p.name);
            CHECK_FALSE(p.doc.empty());
        }
        CHECK((t.ref.empty() || t.ref == "param" || t.ref == "texture"));
        for (const std::string& h : t.helpers) {
            bool found = false;
            for (const auto& [name, code] : graph_helper_functions()) found = found || name == h;
            CHECK_MESSAGE(found, "helper " << h << " of " << t.type << " does not exist");
        }
        // library names do not collide with the engine's (fa_ is reserved) and expressions use no stray braces
        for (const std::string& e : t.expr) CHECK(e.find("fa_tangent") == std::string::npos);
    }
    for (const char* type : {"const.float",    "param",           "uv",          "time",           "vertex.color",
                             "position.world", "normal.world",    "texture",     "math.add",       "math.lerp",
                             "math.clamp",     "math.smoothstep", "math.pow",    "math.dot",       "math.normalize",
                             "math.split",     "math.combine",    "noise.value", "noise.gradient", "noise.voronoi",
                             "noise.fbm",      "dissolve",        "flow",        "fresnel",        "triplanar",
                             "parallax",       "output"})
        CHECK_MESSAGE(find_graph_node_type(type) != nullptr, "missing node type " << type);
    // the surface-value defaults of the ports name values that exist
    for (const GraphNodeType& t : graph_node_library())
        for (const GraphPort& p : t.inputs)
            if (p.defaultValue.is_string()) CHECK(p.defaultValue.get<std::string>()[0] == '$');
    CHECK(find_graph_node_type("noise.fbm") != nullptr);
    CHECK(find_graph_node_type("noise.fbn") == nullptr);
    CHECK(graph_supported_kinds() == std::vector<std::string>{"mesh", "sprite", "post"});
    // the output node has one entry per kind with that kind's fields; the lookup by kind picks it
    const GraphNodeType* meshOut = find_graph_node_type("output", "mesh");
    const GraphNodeType* spriteOut = find_graph_node_type("output", "sprite");
    REQUIRE(meshOut);
    REQUIRE(spriteOut);
    CHECK(meshOut != spriteOut);
    const GraphNodeType* postOut = find_graph_node_type("output", "post");
    REQUIRE(postOut);
    CHECK(postOut != meshOut);
    CHECK(postOut != spriteOut);
    std::vector<std::string> postFields;
    for (const GraphPort& p : postOut->inputs) {
        postFields.push_back(p.name);
        CHECK_MESSAGE(p.assign.find("{}") != std::string::npos, "post output field " << p.name << " has no statement");
    }
    CHECK(postFields == std::vector<std::string>{"color", "rgb"});  // no vertex stage, so no vertexOffset
    CHECK(find_graph_node_type("output", "sky") == nullptr);
    CHECK(find_graph_node_type("output") == meshOut);
    std::vector<std::string> spriteFields;
    for (const GraphPort& p : spriteOut->inputs) {
        spriteFields.push_back(p.name);
        CHECK_MESSAGE(p.assign.find("{}") != std::string::npos,
                      "sprite output field " << p.name << " has no statement");
    }
    CHECK(spriteFields == std::vector<std::string>{"color", "rgb", "alpha", "vertexOffset"});
    // every node that does not serve sprites says what to use there instead: the error teaches
    for (const GraphNodeType& t : graph_node_library()) {
        if (std::find(t.kinds.begin(), t.kinds.end(), "sprite") != t.kinds.end()) continue;
        bool hint = false;
        for (const auto& [kind, text] : t.instead) hint = hint || (kind == "sprite" && text.size() > 20);
        CHECK_MESSAGE((hint || t.type == kGraphOutputNode), t.type << " has no hint for a sprite graph");
    }
    // ...and the same for a post graph
    for (const GraphNodeType& t : graph_node_library()) {
        if (std::find(t.kinds.begin(), t.kinds.end(), "post") != t.kinds.end()) continue;
        bool hint = false;
        for (const auto& [kind, text] : t.instead) hint = hint || (kind == "post" && text.size() > 20);
        CHECK_MESSAGE((hint || t.type == kGraphOutputNode), t.type << " has no hint for a post graph");
    }
}

TEST_CASE("graph library: material.graph.nodes filters and its example is a valid material") {
    Project p;
    auto all = p.call("material.graph.nodes", "{}");
    REQUIRE(all.ok);
    CHECK(all.result["nodes"].size() == graph_node_library().size());
    CHECK_FALSE(all.result["format"].get<std::string>().empty());
    // the example passes the checks and generates
    const Json example = all.result["example"];
    MaterialParse mp = parse_material(example, "");
    REQUIRE_MESSAGE(mp.ok(), (mp.errors.empty() ? "" : mp.errors[0].to_string()));
    CHECK(generate_graph_snippet(mp.material.graph, mp.material).check.ok());

    auto noise = p.call("material.graph.nodes", R"({"category":"noise"})");
    REQUIRE(noise.ok);
    CHECK(noise.result["nodes"].size() == 4);
    auto one = p.call("material.graph.nodes", R"({"type":"noise.fbm","kind":"mesh"})");
    REQUIRE(one.ok);
    REQUIRE(one.result["nodes"].size() == 1);
    CHECK(one.result["nodes"][0]["inputs"][0]["name"] == "p");
    CHECK(one.result["nodes"][0]["inputs"][0]["default"] == "$uv");
    CHECK(one.result["nodes"][0]["stage"] == "any");
    auto tex = p.call("material.graph.nodes", R"({"type":"texture"})");
    REQUIRE(tex.ok);
    CHECK(tex.result["nodes"][0]["stage"] == "fragment");
    CHECK(tex.result["nodes"][0]["needs"] == "texture");

    auto bad = p.call("material.graph.nodes", R"({"type":"noise.fbn"})");
    CHECK_FALSE(bad.ok);
    CHECK(bad.error["hint"].get<std::string>().find("noise.fbm") != std::string::npos);
    CHECK_FALSE(p.call("material.graph.nodes", R"({"category":"nose"})").ok);

    // declared: reads and writes
    CHECK(p.registry.info("material.graph.nodes")->readOnly);
    CHECK(p.registry.info("material.graph.validate")->readOnly);
    CHECK_FALSE(p.registry.info("material.graph.generate")->readOnly);
    CHECK(p.registry.info("material.graph.generate")->capabilities.has(Capability::WriteProject));
    CHECK_FALSE(p.registry.info("material.graph.generate")->description.empty());
}

// ---------------------------------------------------------------------------------------------------------------
// The generated snippet
// ---------------------------------------------------------------------------------------------------------------

TEST_CASE("graph generate: a small dissolve graph gives the golden text") {
    MaterialParse mp = parse_material(Json::parse(kDissolveMaterial), "");
    REQUIRE_MESSAGE(mp.ok(), (mp.errors.empty() ? "" : mp.errors[0].to_string()));
    const GeneratedGraph g = generate_graph_snippet(mp.material.graph, mp.material);
    REQUIRE_MESSAGE(g.check.ok(), all_errors(g.check));
    CHECK(g.snippet == without_cr(fixture("graph_dissolve.surface.glsl")));
    CHECK(g.hash == graph_snippet_hash(g.snippet));
    CHECK(g.hash.size() == 64);
    CHECK(g.usedNodes == std::vector<std::string>{"amount", "burn", "noise"});
    CHECK_FALSE(g.hasVertex);
    // one line per node, each naming its id
    CHECK(g.snippet.find("// noise (noise.fbm)") != std::string::npos);
    CHECK(g.snippet.find("// burn (dissolve)") != std::string::npos);
    // a file saved with CRLF hashes like the text generated
    std::string crlf;
    for (char c : g.snippet) crlf += c == '\n' ? std::string("\r\n") : std::string(1, c);
    CHECK(graph_snippet_hash(crlf) == g.hash);
}

TEST_CASE("graph generate: the same graph gives the same bytes whatever the positions and the order of the arrays") {
    Json doc = Json::parse(kDissolveMaterial);
    MaterialParse a = parse_material(doc, "");
    REQUIRE(a.ok());
    const GeneratedGraph first = generate_graph_snippet(a.material.graph, a.material);
    // shuffle: reverse nodes and links, move every node
    Json shuffled = doc;
    std::reverse(shuffled["graph"]["nodes"].begin(), shuffled["graph"]["nodes"].end());
    std::reverse(shuffled["graph"]["links"].begin(), shuffled["graph"]["links"].end());
    for (Json& n : shuffled["graph"]["nodes"]) n["pos"] = Json::array({n["pos"][1], n["pos"][0]});
    MaterialParse b = parse_material(shuffled, "");
    REQUIRE(b.ok());
    CHECK(generate_graph_snippet(b.material.graph, b.material).snippet == first.snippet);
    // and a different graph gives a different hash
    Json other = doc;
    other["graph"]["nodes"][0]["inputs"]["scale"] = 7.0;
    MaterialParse c = parse_material(other, "");
    REQUIRE(c.ok());
    CHECK(generate_graph_snippet(c.material.graph, c.material).hash != first.hash);
}

TEST_CASE("graph generate: a vertex offset writes vertex() and the fragment nodes stay in surface()") {
    Json doc = base_doc();
    doc["graph"] = Json::parse(R"({
      "nodes": [
        {"id": "t", "type": "time"},
        {"id": "n", "type": "normal.world"},
        {"id": "off", "type": "math.mul", "inputs": {"b": 0.1}},
        {"id": "dir", "type": "math.mul"},
        {"id": "out", "type": "output", "inputs": {"albedo": [1, 1, 1]}}
      ],
      "links": [
        {"from": "t.sin", "to": "off.a"},
        {"from": "n.normal", "to": "dir.a"},
        {"from": "off.result", "to": "dir.b"},
        {"from": "dir.result", "to": "out.vertexOffset"}
      ]})");
    const MaterialDef def = material_with(doc);
    const GeneratedGraph g = generate_graph_snippet(doc["graph"], def);
    REQUIRE_MESSAGE(g.check.ok(), all_errors(g.check));
    CHECK(g.hasVertex);
    const std::size_t v = g.snippet.find("void vertex(inout VertexData v)");
    const std::size_t s = g.snippet.find("void surface(in SurfaceInput i, inout Surface s)");
    REQUIRE(v != std::string::npos);
    REQUIRE(s != std::string::npos);
    CHECK(v < s);
    CHECK(g.snippet.find("v.world_pos += n_dir_result;") != std::string::npos);
    CHECK(g.snippet.find("v.world_normal") != std::string::npos);  // normal.world reads the vertex data there
    CHECK(g.snippet.find("i.world_normal") == std::string::npos);
    CHECK(g.snippet.find("s.albedo = vec3(1.0, 1.0, 1.0);") != std::string::npos);
}

// ---------------------------------------------------------------------------------------------------------------
// Validation: every error teaches
// ---------------------------------------------------------------------------------------------------------------

TEST_CASE("graph check: node errors name the pointer, the problem and the fix") {
    // unknown node type, with did you mean
    auto c = check_of(R"({"nodes":[{"id":"a","type":"noise.fbn"},{"id":"out","type":"output"}]})");
    CHECK(has_error(c, "/graph/nodes/0/type", "unknown node type \"noise.fbn\""));
    CHECK(c.errors[0].hint.find("noise.fbm") != std::string::npos);
    // not an object / missing nodes
    CHECK(has_error(check_of(R"({"links":[]})"), "/graph/nodes", "missing"));
    CHECK(has_error(check_of(R"({"nodes":[]})"), "/graph/nodes", "non-empty array"));
    CHECK(has_error(check_of(R"({"nodes":[3]})"), "/graph/nodes/0", "expected an object"));
    CHECK(has_error(check_of(R"({"nodes":[{"id":"out","type":"output"}],"lynks":[]})"), "/graph/lynks", "unknown key"));
    // ids
    c = check_of(R"({"nodes":[{"id":"a","type":"time"},{"id":"a","type":"uv"},{"id":"out","type":"output"}]})");
    CHECK(has_error(c, "/graph/nodes/1/id", "used twice"));
    c = check_of(R"({"nodes":[{"id":"a b","type":"time"},{"id":"out","type":"output"}]})");
    CHECK(has_error(c, "/graph/nodes/0/id", "not usable"));
    c = check_of(R"({"nodes":[{"type":"time"},{"id":"out","type":"output"}]})");
    CHECK(has_error(c, "/graph/nodes/0/id", "missing"));
    // output node: none, two
    c = check_of(R"({"nodes":[{"id":"a","type":"time"}]})");
    CHECK(has_error(c, "/graph/nodes", "no output node"));
    c = check_of(R"({"nodes":[{"id":"o1","type":"output"},{"id":"o2","type":"output"}]})");
    CHECK(has_error(c, "/graph/nodes/1", "second output node"));
    // constants: unknown input, wrong shape, wrong size
    c = check_of(R"({"nodes":[{"id":"n","type":"noise.fbm","inputs":{"scal":3}},{"id":"out","type":"output"}]})");
    CHECK(has_error(c, "/graph/nodes/0/inputs/scal", "has no input"));
    CHECK(c.errors[0].hint.find("scale") != std::string::npos);
    c = check_of(R"({"nodes":[{"id":"n","type":"noise.fbm","inputs":{"p":3}},{"id":"out","type":"output"}]})");
    CHECK(has_error(c, "/graph/nodes/0/inputs/p", "expected an array of 2 numbers"));
    c = check_of(R"({"nodes":[{"id":"out","type":"output","inputs":{"albedo":[1,0]}}]})");
    CHECK(has_error(c, "/graph/nodes/0/inputs/albedo", "expected an array of 3 numbers"));
    c = check_of(R"({"nodes":[{"id":"out","type":"output","inputs":{"roughness":"rough"}}]})");
    CHECK(has_error(c, "/graph/nodes/0/inputs/roughness", "expected a number"));
    // params and textures
    c = check_of(R"({"nodes":[{"id":"p","type":"param","param":"amout"},{"id":"out","type":"output"}]})");
    CHECK(has_error(c, "/graph/nodes/0/param", "no param \"amout\""));
    CHECK(c.errors[0].hint.find("amount") != std::string::npos);
    c = check_of(R"({"nodes":[{"id":"p","type":"param"},{"id":"out","type":"output"}]})");
    CHECK(has_error(c, "/graph/nodes/0/param", "missing"));
    c = check_of(R"({"nodes":[{"id":"t","type":"texture","texture":"albedo"},{"id":"out","type":"output"}]})");
    CHECK(has_error(c, "/graph/nodes/0/texture", "no texture \"albedo\""));
    CHECK(c.errors[0].hint.find("albedoTex") != std::string::npos);
    c = check_of(R"({"nodes":[{"id":"t","type":"time","param":"amount"},{"id":"out","type":"output"}]})");
    CHECK(has_error(c, "/graph/nodes/0/param", "has no \"param\" field"));
}

TEST_CASE("graph check: link errors name the link, the type and the fix") {
    // a link to a node that does not exist, with did you mean
    auto c = check_of(R"({"nodes":[{"id":"noise","type":"noise.fbm"},{"id":"out","type":"output"}],
                          "links":[{"from":"noyse.value","to":"out.alpha"}]})");
    CHECK(has_error(c, "/graph/links/0/from", "no node with id \"noyse\""));
    CHECK(c.errors[0].hint.find("noise") != std::string::npos);
    // a port that does not exist
    c = check_of(R"({"nodes":[{"id":"noise","type":"noise.fbm"},{"id":"out","type":"output"}],
                     "links":[{"from":"noise.valu","to":"out.alpha"}]})");
    CHECK(has_error(c, "/graph/links/0/from", "has no output \"valu\""));
    CHECK(c.errors[0].hint.find("value") != std::string::npos);
    c = check_of(R"({"nodes":[{"id":"noise","type":"noise.fbm"},{"id":"out","type":"output"}],
                     "links":[{"from":"noise.value","to":"out.alfa"}]})");
    CHECK(has_error(c, "/graph/links/0/to", "has no input \"alfa\""));
    // not node.port
    c = check_of(R"({"nodes":[{"id":"out","type":"output"}],"links":[{"from":"noise","to":"out.alpha"}]})");
    CHECK(has_error(c, "/graph/links/0/from", "is not \"nodeId.port\""));
    c = check_of(R"({"nodes":[{"id":"out","type":"output"}],"links":[{"to":"out.alpha"}]})");
    CHECK(has_error(c, "/graph/links/0/from", "missing"));
    // an input takes one link
    c = check_of(R"({"nodes":[{"id":"a","type":"time"},{"id":"b","type":"time"},{"id":"out","type":"output"}],
                     "links":[{"from":"a.time","to":"out.alpha"},{"from":"b.time","to":"out.alpha"}]})");
    CHECK(has_error(c, "/graph/links/1/to", "already has the link /graph/links/0"));
    // type mismatches
    c = check_of(R"({"nodes":[{"id":"tex","type":"texture","texture":"albedoTex"},{"id":"out","type":"output"}],
                     "links":[{"from":"tex.rgba","to":"out.albedo"}]})");
    CHECK(has_error(c, "/graph/links/0/to", "cannot link vec4"));
    CHECK(c.errors[0].hint.find("math.split") != std::string::npos);
    c = check_of(R"({"nodes":[{"id":"uv","type":"uv"},{"id":"out","type":"output"}],
                     "links":[{"from":"uv.uv","to":"out.roughness"}]})");
    CHECK(has_error(c, "/graph/links/0/to", "cannot link vec2"));
    CHECK(c.errors[0].hint.find("math.split") != std::string::npos);
    // vec3 into vec4 would need an alpha
    c = check_of(
        R"({"nodes":[{"id":"n","type":"normal.world"},{"id":"c","type":"math.combine"},{"id":"out","type":"output"},
                              {"id":"d","type":"dissolve"}],
                     "links":[{"from":"n.normal","to":"d.edgeColor"},{"from":"d.emission","to":"c.x"}]})");
    CHECK(has_error(c, "/graph/links/1/to", "cannot link vec3"));
    // gen inputs that disagree
    c = check_of(R"({"nodes":[{"id":"n","type":"normal.world"},{"id":"u","type":"uv"},{"id":"m","type":"math.add"},
                              {"id":"out","type":"output"}],
                     "links":[{"from":"n.normal","to":"m.a"},{"from":"u.uv","to":"m.b"}]})");
    CHECK(has_error(c, "/graph/links/1/to", "disagree"));
    // a float widens by itself: no error
    c = check_of(R"({"nodes":[{"id":"t","type":"time"},{"id":"out","type":"output"}],
                     "links":[{"from":"t.sin","to":"out.albedo"}]})");
    CHECK_MESSAGE(c.ok(), all_errors(c));
    // split output the vector does not have
    c = check_of(R"({"nodes":[{"id":"u","type":"uv"},{"id":"s","type":"math.split"},{"id":"out","type":"output"}],
                     "links":[{"from":"u.uv","to":"s.value"},{"from":"s.z","to":"out.alpha"}]})");
    CHECK(has_error(c, "/graph/links/1/from", "needs a vector of 3 components"));
    // a constant under a link is ignored: a warning
    c = check_of(R"({"nodes":[{"id":"t","type":"time"},{"id":"out","type":"output","inputs":{"alpha":0.5}}],
                     "links":[{"from":"t.sin","to":"out.alpha"}]})");
    CHECK(c.ok());
    REQUIRE(c.warnings.size() >= 1);
    CHECK(c.warnings[0].pointer == "/graph/nodes/1/inputs/alpha");
}

TEST_CASE("graph check: cycles, vertex offsets and the output node") {
    // a cycle is found and named
    auto c =
        check_of(R"({"nodes":[{"id":"a","type":"math.add"},{"id":"b","type":"math.mul"},{"id":"out","type":"output"}],
                          "links":[{"from":"a.result","to":"b.a"},{"from":"b.result","to":"a.a"},{"from":"b.result","to":"out.alpha"}]})");
    REQUIRE_FALSE(c.ok());
    bool cycle = false;
    for (const MaterialIssue& e : c.errors) {
        const bool named =
            e.message.find("a -> b -> a") != std::string::npos || e.message.find("b -> a -> b") != std::string::npos;
        cycle = cycle || (e.message.find("closes a cycle") != std::string::npos && named);
    }
    CHECK_MESSAGE(cycle, all_errors(c));
    // a node linked into itself
    c = check_of(R"({"nodes":[{"id":"a","type":"math.add"},{"id":"out","type":"output"}],
                     "links":[{"from":"a.result","to":"a.a"}]})");
    CHECK(has_error(c, "/graph/links/0/to", "closes a cycle: a -> a"));
    // a node that samples a texture feeds vertexOffset
    c = check_of(R"({"nodes":[{"id":"tex","type":"texture","texture":"albedoTex"},{"id":"s","type":"math.split"},
                              {"id":"c","type":"math.combine"},{"id":"out","type":"output"}],
                     "links":[{"from":"tex.rgb","to":"s.value"},{"from":"s.x","to":"c.x"},{"from":"c.vec3","to":"out.vertexOffset"}]})");
    CHECK(has_error(c, "/graph/nodes/0/type", "feeds vertexOffset"));
    // the same node is fine in the surface fields
    c = check_of(R"({"nodes":[{"id":"tex","type":"texture","texture":"albedoTex"},{"id":"out","type":"output"}],
                     "links":[{"from":"tex.rgb","to":"out.albedo"}]})");
    CHECK_MESSAGE(c.ok(), all_errors(c));
    // normal and tangentNormal both
    c = check_of(R"({"nodes":[{"id":"n","type":"normal.world"},{"id":"out","type":"output"}],
                     "links":[{"from":"n.normal","to":"out.normal"},{"from":"n.normal","to":"out.tangentNormal"}]})");
    CHECK(has_error(c, "/graph/nodes/1/inputs/tangentNormal", "both set"));
    // a node nobody uses: a warning, not an error
    c = check_of(R"({"nodes":[{"id":"t","type":"time"},{"id":"out","type":"output","inputs":{"albedo":[1,1,1]}}]})");
    CHECK(c.ok());
    bool unused = false;
    for (const MaterialIssue& w : c.warnings)
        unused = unused || w.message.find("not linked to the output") != std::string::npos;
    CHECK(unused);
}

TEST_CASE("graph check: a node used in a kind it does not support, and a kind with no graphs") {
    // an unknown or not yet supported kind is refused with the pointer of the kind
    auto c = check_of(R"({"nodes":[{"id":"out","type":"output"}]})", "sky");
    CHECK(has_error(c, "/kind", "node graphs are generated for materials of kind mesh, sprite, post only"));
    c = check_of(R"({"nodes":[{"id":"out","type":"output"}]})", "sprite");
    CHECK(c.ok());
    // a node that does not list the kind (position.world works in meshes only)
    const GraphNodeType* pos = find_graph_node_type("position.world");
    REQUIRE(pos);
    CHECK(std::find(pos->kinds.begin(), pos->kinds.end(), "sprite") == pos->kinds.end());
    CHECK(std::find(pos->kinds.begin(), pos->kinds.end(), "mesh") != pos->kinds.end());
    c = check_of(R"({"nodes":[{"id":"p","type":"position.world"},{"id":"out","type":"output"}]})", "sprite");
    CHECK(has_error(c, "/graph/nodes/0/type", "does not work in a material of kind \"sprite\""));
    // pure nodes list every kind
    const GraphNodeType* add = find_graph_node_type("math.add");
    REQUIRE(add);
    CHECK(add->kinds.size() >= 3);
}

TEST_CASE("graph check: parse_material runs the graph checks and a graph needs no snippet file yet") {
    testing::TempDir dir;
    Json doc = Json::parse(kDissolveMaterial);
    // the snippet does not exist: a material with a graph is fine, its snippet is generated
    MaterialParse ok = parse_material(doc, dir.str(), "materials/dissolve.material.json");
    CHECK_MESSAGE(ok.ok(), (ok.errors.empty() ? "" : ok.errors[0].to_string()));
    CHECK(ok.material.graph.is_object());
    // without a graph the missing snippet is an error
    Json plain = doc;
    plain.erase("graph");
    CHECK_FALSE(parse_material(plain, dir.str()).ok());
    // a graph error is a material error with the pointer into the material file
    doc["graph"]["links"][0]["to"] = "burn.nois";
    MaterialParse bad = parse_material(doc, dir.str());
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.errors[0].pointer == "/graph/links/0/to");
    CHECK(bad.errors[0].hint.find("noise") != std::string::npos);
    // graphHash without a graph, and a hash that is not a hash
    Json orphan = plain;
    orphan["graphHash"] = std::string(64, 'a');
    orphan["shader"] = "shaders/x.surface.glsl";
    testing::write_all(dir.path / "shaders/x.surface.glsl", "void surface(in SurfaceInput i, inout Surface s) {}\n");
    MaterialParse op = parse_material(orphan, dir.str());
    REQUIRE_FALSE(op.ok());
    CHECK(op.errors[0].pointer == "/graphHash");
    Json badHash = Json::parse(kDissolveMaterial);
    badHash["graphHash"] = "abc";
    MaterialParse bh = parse_material(badHash, dir.str());
    REQUIRE_FALSE(bh.ok());
    CHECK(bh.errors[0].pointer == "/graphHash");
    // the schema knows both keys
    const Json schema = Json::parse(testing::read_all(stdfs::path(FA_REPO_ROOT) / "schemas/material.schema.json"));
    CHECK(schema["properties"].contains("graph"));
    CHECK(schema["properties"].contains("graphHash"));
    const auto problems = validate_json(schema, Json::parse(kDissolveMaterial));
    CHECK_MESSAGE(problems.empty(), (problems.empty() ? "" : problems[0].to_string()));
    Json hashed = Json::parse(kDissolveMaterial);
    hashed["graphHash"] = std::string(64, 'b');
    CHECK(validate_json(schema, hashed).empty());
}

// ---------------------------------------------------------------------------------------------------------------
// The commands: generate, hand-edit protection, validate
// ---------------------------------------------------------------------------------------------------------------

TEST_CASE("material.graph.generate: writes the snippet and graphHash, and a second run changes nothing") {
    Project p;
    auto v = p.call("material.graph.validate", R"({"material":"materials/dissolve.material.json"})");
    REQUIRE(v.ok);
    CHECK(v.result["ok"] == true);
    CHECK(v.result["snippet"]["state"] == "missing");

    auto dry = p.call("material.graph.generate", R"({"material":"materials/dissolve","dryRun":true})");
    REQUIRE(dry.ok);
    CHECK(dry.result["written"] == false);
    CHECK(dry.result["dryRun"] == true);
    CHECK_FALSE(stdfs::exists(p.dir.path / "shaders/dissolve.surface.glsl"));

    auto gen = p.call("material.graph.generate", R"({"material":"materials/dissolve.material.json"})");
    REQUIRE_MESSAGE(gen.ok, failure(gen));
    CHECK(gen.result["written"] == true);
    CHECK(gen.result["state"] == "missing");
    const std::string snippet = p.read("shaders/dissolve.surface.glsl");
    CHECK(snippet == without_cr(fixture("graph_dissolve.surface.glsl")));
    const Json doc = p.doc();
    CHECK(doc["graphHash"] == gen.result["hash"]);
    CHECK(doc["graphHash"] == graph_snippet_hash(snippet));
    CHECK(doc["graph"] == Json::parse(kDissolveMaterial)["graph"]);  // the graph is kept as written
    CHECK(doc["params"] == Json::parse(kDissolveMaterial)["params"]);

    const std::string materialBefore = p.read("materials/dissolve.material.json");
    auto again = p.call("material.graph.generate", R"({"material":"materials/dissolve.material.json"})");
    REQUIRE(again.ok);
    CHECK(again.result["state"] == "in_sync");
    CHECK(again.result["written"] == false);
    CHECK(p.read("materials/dissolve.material.json") == materialBefore);
    CHECK(p.read("shaders/dissolve.surface.glsl") == snippet);
    v = p.call("material.graph.validate", R"({"material":"materials/dissolve.material.json"})");
    CHECK(v.result["snippet"]["state"] == "in_sync");

    // a changed graph updates the snippet: the old one is what the previous graph made
    Json changed = p.doc();
    changed["graph"]["nodes"][0]["inputs"]["scale"] = 9.0;
    p.write("materials/dissolve.material.json", changed.dump(2));
    v = p.call("material.graph.validate", R"({"material":"materials/dissolve.material.json"})");
    CHECK(v.result["snippet"]["state"] == "graph_changed");
    auto upd = p.call("material.graph.generate", R"({"material":"materials/dissolve.material.json"})");
    REQUIRE(upd.ok);
    CHECK(upd.result["written"] == true);
    CHECK(p.read("shaders/dissolve.surface.glsl") != snippet);
    CHECK(p.read("shaders/dissolve.surface.glsl").find("9.0") != std::string::npos);
    CHECK(p.doc()["graphHash"] == upd.result["hash"]);
}

TEST_CASE("material.graph.generate: a hand-edited snippet is never overwritten without force") {
    Project p;
    REQUIRE(p.call("material.graph.generate", R"({"material":"materials/dissolve.material.json"})").ok);
    const std::string generated = p.read("shaders/dissolve.surface.glsl");
    const std::string edited = generated + "// a hand-written tweak\n";
    p.write("shaders/dissolve.surface.glsl", edited);
    const std::string materialBefore = p.read("materials/dissolve.material.json");

    auto v = p.call("material.graph.validate", R"({"material":"materials/dissolve.material.json"})");
    CHECK(v.result["snippet"]["state"] == "hand_edited");

    auto refused = p.call("material.graph.generate", R"({"material":"materials/dissolve.material.json"})");
    REQUIRE_FALSE(refused.ok);
    CHECK(refused.error["code"].get<std::string>() == "hand_edited");
    CHECK(refused.error["message"].get<std::string>().find("edited by hand") != std::string::npos);
    CHECK(refused.error["hint"].get<std::string>().find("force") != std::string::npos);
    CHECK(refused.error["hint"].get<std::string>().find("delete the \"graph\"") != std::string::npos);
    CHECK(p.read("shaders/dissolve.surface.glsl") == edited);  // nothing changed
    CHECK(p.read("materials/dissolve.material.json") == materialBefore);

    // a dry run refuses too: it tells what a real run would do
    CHECK_FALSE(
        p.call("material.graph.generate", R"({"material":"materials/dissolve.material.json","dryRun":true})").ok);

    // a snippet saved with CRLF by an editor is not a hand edit
    std::string crlf;
    for (char c : generated) crlf += c == '\n' ? std::string("\r\n") : std::string(1, c);
    p.write("shaders/dissolve.surface.glsl", crlf);
    auto fine = p.call("material.graph.generate", R"({"material":"materials/dissolve.material.json"})");
    REQUIRE(fine.ok);
    CHECK(fine.result["state"] == "in_sync");
    p.write("shaders/dissolve.surface.glsl", edited);

    // force overwrites
    auto forced = p.call("material.graph.generate", R"({"material":"materials/dissolve.material.json","force":true})");
    REQUIRE(forced.ok);
    CHECK(forced.result["written"] == true);
    CHECK(p.read("shaders/dissolve.surface.glsl") == generated);

    // delete the graph to keep the hand-written code: the material is a plain one again
    p.write("shaders/dissolve.surface.glsl", edited);
    Json plain = p.doc();
    plain.erase("graph");
    plain.erase("graphHash");
    p.write("materials/dissolve.material.json", plain.dump(2));
    MaterialParse mp = read_material(p.dir.str(), "materials/dissolve.material.json");
    CHECK(mp.ok());
    CHECK(mp.material.graph.is_null());
    auto noGraph = p.call("material.graph.generate", R"({"material":"materials/dissolve.material.json"})");
    REQUIRE_FALSE(noGraph.ok);
    CHECK(noGraph.error["code"].get<std::string>() == "no_graph");
    CHECK(p.read("shaders/dissolve.surface.glsl") == edited);
}

TEST_CASE("material.graph.generate: a snippet that no generator wrote is protected too, and a graph with errors writes "
          "nothing") {
    Project p;
    p.write("shaders/dissolve.surface.glsl",
            "void surface(in SurfaceInput i, inout Surface s) { s.albedo = vec3(1.0); }\n");
    auto v = p.call("material.graph.validate", R"({"material":"materials/dissolve.material.json"})");
    CHECK(v.result["snippet"]["state"] == "unmanaged");
    auto refused = p.call("material.graph.generate", R"({"material":"materials/dissolve.material.json"})");
    REQUIRE_FALSE(refused.ok);
    CHECK(refused.error["code"].get<std::string>() == "hand_edited");
    CHECK(refused.error["message"].get<std::string>().find("no generator wrote it") != std::string::npos);

    // a graph with an error: generate says where and writes nothing
    Json broken = p.doc();
    broken["graph"]["links"][1]["from"] = "amoun.value";
    p.write("materials/dissolve.material.json", broken.dump(2));
    const std::string before = p.read("shaders/dissolve.surface.glsl");
    auto bad = p.call("material.graph.generate", R"({"material":"materials/dissolve.material.json","force":true})");
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error["message"].get<std::string>().find("/graph/links/1/from") != std::string::npos);
    CHECK(p.read("shaders/dissolve.surface.glsl") == before);
    // validate lists the same error
    auto vv = p.call("material.graph.validate", R"({"material":"materials/dissolve.material.json"})");
    REQUIRE(vv.ok);
    CHECK(vv.result["ok"] == false);
    CHECK(vv.result["errors"][0]["pointer"] == "/graph/links/1/from");
    CHECK(vv.result["snippet"]["state"] == "unchecked");
    CHECK_FALSE(p.call("material.graph.generate", R"({"material":"materials/nothing.material.json"})").ok);
}

// ---------------------------------------------------------------------------------------------------------------
// Every node type through the real sokol-shdc
// ---------------------------------------------------------------------------------------------------------------

namespace {

// Builds a graph that uses every node type of the library, every node reachable from the output.
struct GraphBuilder {
    Json nodes = Json::array(), links = Json::array();
    std::set<std::string> types;
    void node(const std::string& id, const std::string& type, Json inputs = Json::object(),
              const std::string& refKey = {}, const std::string& ref = {}) {
        Json n = Json::object({{"id", id}, {"type", type}});
        if (!inputs.empty()) n["inputs"] = std::move(inputs);
        if (!refKey.empty()) n[refKey] = ref;
        nodes.push_back(std::move(n));
        types.insert(type);
    }
    void link(const std::string& from, const std::string& to) {
        links.push_back(Json::object({{"from", from}, {"to", to}}));
    }
    // Adds the values (ids "node.output" of one size) together in a chain of math.add nodes; returns the last output.
    std::string sum(const std::string& prefix, const std::vector<std::string>& values) {
        std::string acc = values[0];
        for (std::size_t i = 1; i < values.size(); ++i) {
            const std::string id = prefix + std::to_string(i);
            node(id, "math.add");
            link(acc, id + ".a");
            link(values[i], id + ".b");
            acc = id + ".result";
        }
        return acc;
    }
};

Json all_nodes_material() {
    GraphBuilder g;
    // constants and params
    g.node("cf", "const.float", Json::object({{"value", 0.5}}));
    g.node("c2", "const.vec2", Json::object({{"value", Json::array({0.3, 0.7})}}));
    g.node("c3", "const.vec3", Json::object({{"value", Json::array({0.2, 0.4, 0.6})}}));
    g.node("c4", "const.vec4", Json::object({{"value", Json::array({1, 1, 1, 1})}}));
    g.node("cc", "const.color", Json::object({{"rgba", Json::array({0.8, 0.2, 0.1, 1.0})}}));
    g.node("pf", "param", {}, "param", "amount");
    g.node("p2", "param", {}, "param", "offset2");
    g.node("p3", "param", {}, "param", "dir3");
    g.node("p4", "param", {}, "param", "vec4p");
    g.node("pc", "param", {}, "param", "tint");
    // inputs of the surface
    g.node("uv1", "uv", Json::object({{"tiling", Json::array({2.0, 2.0})}}));
    g.node("tm", "time", Json::object({{"speed", 0.5}}));
    g.node("vc", "vertex.color");
    g.node("pw", "position.world");
    g.node("pv", "position.view");
    g.node("nw", "normal.world");
    g.node("vd", "view.dir");
    // textures
    g.node("par", "parallax", Json::object({{"scale", 0.04}, {"steps", 12.0}}), "texture", "heightTex");
    g.link("uv1.uv", "par.uv");
    g.node("tx", "texture", {}, "texture", "albedoTex");
    g.link("par.uv", "tx.uv");
    g.node("tn", "texture.normal", Json::object({{"strength", 1.5}}), "texture", "normalTex");
    g.link("par.uv", "tn.uv");
    g.node("tp", "triplanar", Json::object({{"scale", 0.5}}), "texture", "rockTex");
    // a vec3 chain through every math node
    g.node("add1", "math.add");
    g.link("tx.rgb", "add1.a");
    g.link("c3.value", "add1.b");
    g.node("sub1", "math.sub", Json::object({{"b", 0.1}}));
    g.link("add1.result", "sub1.a");
    g.node("mul1", "math.mul");
    g.link("sub1.result", "mul1.a");
    g.link("cc.rgb", "mul1.b");
    g.node("div1", "math.div", Json::object({{"b", 2.0}}));
    g.link("mul1.result", "div1.a");
    g.node("min1", "math.min");
    g.link("div1.result", "min1.a");
    g.link("tp.rgb", "min1.b");
    g.node("max1", "math.max");
    g.link("min1.result", "max1.a");
    g.link("c3.value", "max1.b");
    g.node("pow1", "math.pow", Json::object({{"b", 1.2}}));
    g.link("max1.result", "pow1.a");
    g.node("lerp1", "math.lerp");
    g.link("pow1.result", "lerp1.a");
    g.link("p3.value", "lerp1.b");
    g.link("tx.a", "lerp1.t");
    g.node("clamp1", "math.clamp", Json::object({{"min", 0.1}, {"max", 0.9}}));
    g.link("lerp1.result", "clamp1.x");
    g.node("sat1", "math.saturate");
    g.link("clamp1.result", "sat1.x");
    g.node("smooth1", "math.smoothstep", Json::object({{"edge0", 0.1}, {"edge1", 0.9}}));
    g.link("sat1.result", "smooth1.x");
    g.node("step1", "math.step", Json::object({{"edge", 0.3}}));
    g.link("smooth1.result", "step1.x");
    g.node("abs1", "math.abs");
    g.link("step1.result", "abs1.x");
    g.node("fract1", "math.fract");
    g.link("abs1.result", "fract1.x");
    g.node("sin1", "math.sin");
    g.link("fract1.result", "sin1.x");
    g.node("one1", "math.oneminus");
    g.link("sin1.result", "one1.x");
    g.node("dot1", "math.dot");
    g.link("one1.result", "dot1.a");
    g.link("nw.normal", "dot1.b");
    g.node("len1", "math.length");
    g.link("pv.position", "len1.x");
    g.node("norm1", "math.normalize");
    g.link("pw.position", "norm1.x");
    g.node("split1", "math.split");
    g.link("pw.position", "split1.value");
    g.node("comb1", "math.combine");
    g.link("split1.x", "comb1.x");
    g.link("split1.y", "comb1.y");
    g.link("split1.z", "comb1.z");
    // noise and effects
    g.node("nv", "noise.value", Json::object({{"scale", 5.0}}));
    g.node("ng", "noise.gradient");
    g.node("nvo", "noise.voronoi");
    g.node("nf", "noise.fbm", Json::object({{"octaves", 5.0}}));
    g.node("ds", "dissolve");
    g.link("nf.value", "ds.noise");
    g.link("pf.value", "ds.threshold");
    g.node("fl", "flow", Json::object({{"flow", Json::array({0.2, 0.1})}}));
    g.link("uv1.uv", "fl.uv");
    g.node("fr", "fresnel");
    // sums: every remaining output is used by one of them
    const std::string v2 = g.sum("v2_", {"c2.value", "p2.value", "fl.uv0", "fl.uv1"});
    g.link(v2, "ng.p");
    const std::string v4 =
        g.sum("v4_", {"p4.value", "c4.value", "tx.rgba", "tp.rgba", "vc.rgba", "cc.rgba", "pc.value"});
    g.node("split4", "math.split");
    g.link(v4, "split4.value");
    const std::string f = g.sum("f_", {"dot1.result", "len1.result", "fr.value", "tm.time", "tm.sin", "tm.cos",
                                       "nvo.distance", "nvo.cell", "nvo.edge", "nv.value", "ng.value", "fl.blend",
                                       "vc.a", "ds.edge", "par.depth", "split4.x", "cf.value"});
    g.node("rough", "math.saturate");
    g.link(f, "rough.x");
    const std::string v3 = g.sum("v3_", {"norm1.result", "comb1.vec3", "vc.rgb", "vd.direction", "ds.emission"});
    // the vertex offset path: nodes that do not need the fragment stage
    g.node("vn", "noise.fbm");
    g.node("vm", "math.mul", Json::object({{"b", 0.1}}));
    g.link("vn.value", "vm.a");
    g.node("vo", "math.mul");
    g.link("nw.normal", "vo.a");
    g.link("vm.result", "vo.b");
    // the output
    g.node("out", "output", Json::object({{"metallic", 0.0}}));
    g.link("one1.result", "out.albedo");
    g.link("ds.alpha", "out.alpha");
    g.link(v3, "out.emission");
    g.link("rough.result", "out.roughness");
    g.link("split4.w", "out.occlusion");
    g.link("tn.normal", "out.tangentNormal");
    g.link("vo.result", "out.vertexOffset");

    Json doc = Json::parse(R"({
      "format": "factoria.material/1",
      "doc": "Every node type of the graph library in one material.",
      "shader": "shaders/all.surface.glsl",
      "alphaMode": "clip",
      "params": {
        "amount": { "type": "float", "default": 0.3, "min": 0, "max": 1, "doc": "A float." },
        "offset2": { "type": "vec2", "default": [0.1, 0.2], "doc": "A vec2." },
        "dir3": { "type": "vec3", "default": [0, 1, 0], "doc": "A vec3." },
        "vec4p": { "type": "vec4", "default": [1, 1, 1, 1], "doc": "A vec4." },
        "tint": { "type": "color", "default": [1, 0.5, 0.2, 1], "doc": "A color." }
      },
      "textures": {
        "albedoTex": { "sampler": "linearRepeat", "doc": "Albedo." },
        "normalTex": { "sampler": "linearRepeat", "doc": "Normal map." },
        "heightTex": { "sampler": "linearRepeat", "doc": "Height map." },
        "rockTex": { "sampler": "linearRepeat", "doc": "Rock." }
      }
    })");
    doc["graph"] = Json::object({{"nodes", g.nodes}, {"links", g.links}});
    return doc;
}

}  // namespace

TEST_CASE("graph all nodes: one graph uses every node type of the library and generates") {
    const Json doc = all_nodes_material();
    std::set<std::string> used;
    for (const Json& n : doc["graph"]["nodes"]) used.insert(n["type"].get<std::string>());
    for (const GraphNodeType& t : graph_node_library())
        if (std::find(t.kinds.begin(), t.kinds.end(), "mesh") != t.kinds.end())
            CHECK_MESSAGE(used.count(t.type) == 1, "the all-nodes graph lacks " << t.type);
    MaterialParse mp = parse_material(doc, "");
    REQUIRE_MESSAGE(mp.ok(), (mp.errors.empty() ? "" : mp.errors[0].to_string()));
    const GeneratedGraph g = generate_graph_snippet(doc["graph"], mp.material);
    REQUIRE_MESSAGE(g.check.ok(), all_errors(g.check));
    CHECK(g.check.warnings.empty());
    CHECK(g.hasVertex);
    // every node the graph has is drawn (the whole graph is reachable from the output)
    CHECK(g.usedNodes.size() + 1 == doc["graph"]["nodes"].size());  // all but the output node
    // the helpers every noise and texture node needs are pasted exactly once
    for (const auto& [name, code] : graph_helper_functions()) {
        std::size_t count = 0;
        for (std::size_t at = g.snippet.find(name + "("); at != std::string::npos;
             at = g.snippet.find(name + "(", at + 1))
            if (at == 0 || g.snippet[at - 1] == ' ' || g.snippet[at - 1] == '\n') ++count;
        CHECK_MESSAGE(count >= 1, name << " is not in the snippet");
    }
}

TEST_CASE("graph all nodes: the generated snippet compiles with the real sokol-shdc for every dialect") {
    SetupContext context;
    FA_SKIP_WITHOUT_SHDC(
        context, "sokol-shdc is not installed (SOKOL_SHDC, or `factoria setup shaders`): the graph is generated "
                 "but not compiled here; CI compiles it");
    testing::TempDir dir;
    testing::write_all(dir.path / "materials/all.material.json", all_nodes_material().dump(2));
    CommandRegistry registry;
    register_material_graph_commands(registry, dir.str());
    auto gen = registry.call("material.graph.generate", Json::parse(R"({"material":"materials/all.material.json"})"));
    REQUIRE_MESSAGE(gen.ok, failure(gen));
    CHECK(gen.result["warnings"].empty());

    ShaderCompileOptions options;
    options.setup = context;
    options.useCache = false;
    auto r = compile_material(dir.str(), "materials/all.material.json", options);
    REQUIRE(r.ok());
    std::string why;
    for (const ShaderIssue& e : r->errors) why += e.to_string() + "\n";
    INFO(why);
    REQUIRE(r->ok);
    CHECK(r->twins.size() == 6);
    for (const std::string slang : {"hlsl5", "glsl430", "glsl300es", "metal_macos", "metal_ios", "metal_sim"}) {
        CAPTURE(slang);
        REQUIRE(r->twins.count(slang) == 1);
        const Json& twin = r->twins.at(slang);
        // vertex() and clip: the shadow programs exist
        CHECK(twin["programs"].contains("shadow"));
        CHECK_FALSE(twin["programs"]["mesh"]["fs"].get<std::string>().empty());
    }
    // the dissolve of the docs compiles too
    testing::write_all(dir.path / "materials/dissolve.material.json", kDissolveMaterial);
    auto d =
        registry.call("material.graph.generate", Json::parse(R"({"material":"materials/dissolve.material.json"})"));
    REQUIRE(d.ok);
    auto dr = compile_material(dir.str(), "materials/dissolve.material.json", options);
    REQUIRE(dr.ok());
    std::string dwhy;
    for (const ShaderIssue& e : dr->errors) dwhy += e.to_string() + "\n";
    INFO(dwhy);
    CHECK(dr->ok);
}

// ---------------------------------------------------------------------------------------------------------------
// Sprite materials: the same graph, the entry points fragment() and vertex() of the sprite template
// ---------------------------------------------------------------------------------------------------------------

namespace {

// The dissolve of the docs, on a sprite: the sprite's own colour burns away.
const char* kSpriteDissolveMaterial = R"({
  "format": "factoria.material/1",
  "kind": "sprite",
  "doc": "Sprite dissolve: noise burns the sprite away with a glowing edge.",
  "shader": "shaders/sdissolve.fragment.glsl",
  "params": {
    "dissolve": { "type": "float", "default": 0.0, "min": 0.0, "max": 1.0, "doc": "0 shows the sprite, 1 dissolves it all." }
  },
  "graph": {
    "nodes": [
      { "id": "noise", "type": "noise.fbm", "pos": [0, 0], "inputs": { "scale": 6.0 } },
      { "id": "amount", "type": "param", "pos": [0, 120], "param": "dissolve" },
      { "id": "burn", "type": "dissolve", "pos": [220, 60], "inputs": { "edgeWidth": 0.06, "edgeColor": [1.0, 0.4, 0.1] } },
      { "id": "pic", "type": "sprite.color", "pos": [0, 240] },
      { "id": "lit", "type": "math.add", "pos": [440, 60] },
      { "id": "out", "type": "output", "pos": [660, 60] }
    ],
    "links": [
      { "from": "noise.value", "to": "burn.noise" },
      { "from": "amount.value", "to": "burn.threshold" },
      { "from": "pic.rgb", "to": "lit.a" },
      { "from": "burn.emission", "to": "lit.b" },
      { "from": "lit.result", "to": "out.rgb" },
      { "from": "burn.alpha", "to": "out.alpha" }
    ]
  }
})";

// Every node type that works in a sprite, every node reachable from the output.
Json sprite_all_nodes_material() {
    GraphBuilder g;
    g.node("cf", "const.float", Json::object({{"value", 0.5}}));
    g.node("c2", "const.vec2", Json::object({{"value", Json::array({0.3, 0.7})}}));
    g.node("c3", "const.vec3", Json::object({{"value", Json::array({0.2, 0.4, 0.6})}}));
    g.node("c4", "const.vec4", Json::object({{"value", Json::array({1, 1, 1, 1})}}));
    g.node("cc", "const.color", Json::object({{"rgba", Json::array({0.8, 0.2, 0.1, 1.0})}}));
    g.node("pf", "param", {}, "param", "amount");
    g.node("p2", "param", {}, "param", "offset2");
    g.node("p3", "param", {}, "param", "dir3");
    g.node("p4", "param", {}, "param", "vec4p");
    g.node("pc", "param", {}, "param", "tint");
    g.node("uv1", "uv", Json::object({{"tiling", Json::array({2.0, 2.0})}}));
    g.node("tm", "time", Json::object({{"speed", 0.5}}));
    // what a 2D item gives
    g.node("sc", "sprite.color");
    g.node("st", "sprite.tint");
    g.node("sl", "sprite.life");
    g.node("scu", "sprite.custom");
    g.node("sp", "sprite.position");
    g.node("fl", "flow", Json::object({{"flow", Json::array({0.2, 0.1})}}));
    g.link("uv1.uv", "fl.uv");
    g.node("stx", "sprite.texture");
    g.link("fl.uv0", "stx.uv");
    g.node("tx", "texture", {}, "texture", "albedoTex");
    g.link("uv1.uv", "tx.uv");
    // a vec3 chain through every math node
    g.node("add1", "math.add");
    g.link("tx.rgb", "add1.a");
    g.link("c3.value", "add1.b");
    g.node("sub1", "math.sub", Json::object({{"b", 0.1}}));
    g.link("add1.result", "sub1.a");
    g.node("mul1", "math.mul");
    g.link("sub1.result", "mul1.a");
    g.link("cc.rgb", "mul1.b");
    g.node("div1", "math.div", Json::object({{"b", 2.0}}));
    g.link("mul1.result", "div1.a");
    g.node("min1", "math.min");
    g.link("div1.result", "min1.a");
    g.link("stx.rgb", "min1.b");
    g.node("max1", "math.max");
    g.link("min1.result", "max1.a");
    g.link("c3.value", "max1.b");
    g.node("pow1", "math.pow", Json::object({{"b", 1.2}}));
    g.link("max1.result", "pow1.a");
    g.node("lerp1", "math.lerp");
    g.link("pow1.result", "lerp1.a");
    g.link("p3.value", "lerp1.b");
    g.link("tx.a", "lerp1.t");
    g.node("clamp1", "math.clamp", Json::object({{"min", 0.1}, {"max", 0.9}}));
    g.link("lerp1.result", "clamp1.x");
    g.node("sat1", "math.saturate");
    g.link("clamp1.result", "sat1.x");
    g.node("smooth1", "math.smoothstep", Json::object({{"edge0", 0.1}, {"edge1", 0.9}}));
    g.link("sat1.result", "smooth1.x");
    g.node("step1", "math.step", Json::object({{"edge", 0.3}}));
    g.link("smooth1.result", "step1.x");
    g.node("abs1", "math.abs");
    g.link("step1.result", "abs1.x");
    g.node("fract1", "math.fract");
    g.link("abs1.result", "fract1.x");
    g.node("sin1", "math.sin");
    g.link("fract1.result", "sin1.x");
    g.node("one1", "math.oneminus");
    g.link("sin1.result", "one1.x");
    g.node("dot1", "math.dot");
    g.link("one1.result", "dot1.a");
    g.link("sc.rgb", "dot1.b");
    g.node("len1", "math.length");
    g.link("sp.world", "len1.x");
    g.node("norm1", "math.normalize");
    g.link("st.rgb", "norm1.x");
    g.node("split1", "math.split");
    g.link("sc.rgb", "split1.value");
    g.node("comb1", "math.combine");
    g.link("split1.x", "comb1.x");
    g.link("split1.y", "comb1.y");
    g.link("split1.z", "comb1.z");
    // noise and effects
    g.node("nv", "noise.value", Json::object({{"scale", 5.0}}));
    g.node("ng", "noise.gradient");
    g.node("nvo", "noise.voronoi");
    g.node("nf", "noise.fbm", Json::object({{"octaves", 5.0}}));
    g.node("ds", "dissolve");
    g.link("nf.value", "ds.noise");
    g.link("pf.value", "ds.threshold");
    const std::string v2 = g.sum("v2_", {"c2.value", "p2.value", "fl.uv0", "fl.uv1", "sp.world", "sp.screen"});
    g.link(v2, "ng.p");
    const std::string v4 = g.sum("v4_", {"p4.value", "c4.value", "tx.rgba", "stx.rgba", "st.rgba", "sc.rgba", "cc.rgba",
                                         "pc.value", "scu.custom"});
    g.node("split4", "math.split");
    g.link(v4, "split4.value");
    const std::string f = g.sum("f_", {"dot1.result", "len1.result", "tm.time", "tm.sin", "tm.cos", "nvo.distance",
                                       "nvo.cell", "nvo.edge", "nv.value", "ng.value", "fl.blend", "st.a", "sc.a",
                                       "stx.a", "ds.edge", "sl.life", "split4.x", "cf.value"});
    g.node("rough", "math.saturate");
    g.link(f, "rough.x");
    const std::string v3 = g.sum("v3_", {"norm1.result", "comb1.vec3", "st.rgb", "sc.rgb", "ds.emission"});
    g.node("mix3", "math.mul");
    g.link(v3, "mix3.a");
    g.link("one1.result", "mix3.b");
    g.node("al", "math.mul");
    g.link("rough.result", "al.a");
    g.link("ds.alpha", "al.b");
    // the vertex offset path: nodes that do not sample textures
    g.node("vn", "noise.fbm");
    g.node("vm", "math.mul", Json::object({{"b", 0.1}}));
    g.link("vn.value", "vm.a");
    g.node("vo", "math.mul");
    g.link("st.rgb", "vo.a");
    g.link("vm.result", "vo.b");
    g.node("out", "output");
    g.link(v4, "out.color");
    g.link("mix3.result", "out.rgb");
    g.link("al.result", "out.alpha");
    g.link("vo.result", "out.vertexOffset");

    Json doc = Json::parse(R"({
      "format": "factoria.material/1",
      "kind": "sprite",
      "doc": "Every node type of the graph library that works in a sprite, in one material.",
      "shader": "shaders/sprite_all.fragment.glsl",
      "params": {
        "amount": { "type": "float", "default": 0.3, "min": 0, "max": 1, "doc": "A float." },
        "offset2": { "type": "vec2", "default": [0.1, 0.2], "doc": "A vec2." },
        "dir3": { "type": "vec3", "default": [0, 1, 0], "doc": "A vec3." },
        "vec4p": { "type": "vec4", "default": [1, 1, 1, 1], "doc": "A vec4." },
        "tint": { "type": "color", "default": [1, 0.5, 0.2, 1], "doc": "A color." }
      },
      "textures": {
        "albedoTex": { "sampler": "linearRepeat", "doc": "Albedo." }
      }
    })");
    doc["graph"] = Json::object({{"nodes", g.nodes}, {"links", g.links}});
    return doc;
}

}  // namespace

TEST_CASE("graph sprite: a dissolve graph writes fragment() of the sprite template") {
    MaterialParse mp = parse_material(Json::parse(kSpriteDissolveMaterial), "");
    REQUIRE_MESSAGE(mp.ok(), (mp.errors.empty() ? "" : mp.errors[0].to_string()));
    CHECK(mp.material.kind == "sprite");
    const GeneratedGraph g = generate_graph_snippet(mp.material.graph, mp.material, "sprite");
    REQUIRE_MESSAGE(g.check.ok(), all_errors(g.check));
    CHECK(g.check.warnings.empty());
    CHECK_FALSE(g.hasVertex);
    CHECK(g.snippet.find("void fragment(in QuadInput i, inout QuadSurface s) {\n") != std::string::npos);
    CHECK(g.snippet.find("surface(") == std::string::npos);
    CHECK(g.snippet.find("vertex(") == std::string::npos);
    // the sprite's own colour is read where the node is, and written back by the output at the end
    CHECK(g.snippet.find("// pic (sprite.color)") != std::string::npos);
    CHECK(g.snippet.find("= s.color;") != std::string::npos);
    CHECK(g.snippet.find("    s.color.rgb = n_lit_result;  // out (output)\n") != std::string::npos);
    CHECK(g.snippet.find("    s.color.a = n_burn_alpha;  // out (output)\n") != std::string::npos);
    // the same graph gives the same bytes, and the mesh generator does not write what the sprite one does
    const GeneratedGraph again = generate_graph_snippet(mp.material.graph, mp.material, "sprite");
    CHECK(again.snippet == g.snippet);
    CHECK(again.hash == graph_snippet_hash(g.snippet));
    // the line map names the node of a line, the output's lines name the output node
    for (std::size_t n = 0; n < g.lineNodes.size(); ++n)
        if (g.snippet.find("s.color.a = ") != std::string::npos && g.lineNodes[n] == "out") {
            CHECK(graph_node_at_line(g.lineNodes, int(n) + 1) == "out");
            break;
        }
}

TEST_CASE("graph sprite: a vertex offset writes vertex() of the sprite template, and a node that reads the fragment "
          "may not feed it") {
    Json doc = Json::parse(kSpriteDissolveMaterial);
    doc["graph"]["nodes"].push_back(Json::parse(R"({"id":"wob","type":"sprite.tint"})"));
    doc["graph"]["nodes"].push_back(Json::parse(R"({"id":"amp","type":"math.mul","inputs":{"b":0.1}})"));
    doc["graph"]["links"].push_back(Json::parse(R"({"from":"wob.rgb","to":"amp.a"})"));
    doc["graph"]["links"].push_back(Json::parse(R"({"from":"amp.result","to":"out.vertexOffset"})"));
    MaterialParse mp = parse_material(doc, "");
    REQUIRE_MESSAGE(mp.ok(), (mp.errors.empty() ? "" : mp.errors[0].to_string()));
    const GeneratedGraph g = generate_graph_snippet(mp.material.graph, mp.material, "sprite");
    REQUIRE_MESSAGE(g.check.ok(), all_errors(g.check));
    CHECK(g.hasVertex);
    const std::size_t v = g.snippet.find("void vertex(inout QuadVertex v) {\n");
    const std::size_t f = g.snippet.find("void fragment(in QuadInput i, inout QuadSurface s) {\n");
    REQUIRE(v != std::string::npos);
    REQUIRE(f != std::string::npos);
    CHECK(v < f);
    // the tint is read from the vertex in vertex() and from the fragment input in fragment()
    CHECK(g.snippet.find("v.color", v) != std::string::npos);
    CHECK(g.snippet.find("    v.world_pos += n_amp_result;  // out (output)\n") != std::string::npos);

    // sprite.color (the lit picture) exists in the fragment stage only
    Json bad = doc;
    bad["graph"]["links"][bad["graph"]["links"].size() - 2]["from"] = "pic.rgb";
    const MaterialDef def = material_with(bad);
    const GraphCheck c = check_material_graph(bad["graph"], def, "sprite");
    bool found = false;
    for (const MaterialIssue& e : c.errors)
        found = found || (e.message.find("fragment") != std::string::npos && !e.hint.empty());
    CHECK_MESSAGE(found, all_errors(c));
}

TEST_CASE("graph sprite: one graph uses every node type that works in a sprite and generates") {
    const Json doc = sprite_all_nodes_material();
    std::set<std::string> used;
    for (const Json& n : doc["graph"]["nodes"]) used.insert(n["type"].get<std::string>());
    for (const GraphNodeType& t : graph_node_library())
        if (std::find(t.kinds.begin(), t.kinds.end(), "sprite") != t.kinds.end())
            CHECK_MESSAGE(used.count(t.type) == 1, "the sprite all-nodes graph lacks " << t.type);
    MaterialParse mp = parse_material(doc, "");
    REQUIRE_MESSAGE(mp.ok(), (mp.errors.empty() ? "" : mp.errors[0].to_string()));
    const GeneratedGraph g = generate_graph_snippet(doc["graph"], mp.material, "sprite");
    REQUIRE_MESSAGE(g.check.ok(), all_errors(g.check));
    CHECK(g.check.warnings.empty());
    CHECK(g.hasVertex);
    CHECK(g.usedNodes.size() + 1 == doc["graph"]["nodes"].size());
}

TEST_CASE("graph sprite: the generated snippet compiles with the real sokol-shdc for every dialect") {
    SetupContext context;
    FA_SKIP_WITHOUT_SHDC(
        context, "sokol-shdc is not installed (SOKOL_SHDC, or `factoria setup shaders`): the sprite graph is generated "
                 "but not compiled here; CI compiles it");
    testing::TempDir dir;
    testing::write_all(dir.path / "materials/sall.material.json", sprite_all_nodes_material().dump(2));
    testing::write_all(dir.path / "materials/sdissolve.material.json", kSpriteDissolveMaterial);
    CommandRegistry registry;
    register_material_graph_commands(registry, dir.str());
    ShaderCompileOptions options;
    options.setup = context;
    options.useCache = false;
    for (const char* name : {"sall", "sdissolve"}) {
        CAPTURE(name);
        const std::string rel = std::string("materials/") + name + ".material.json";
        auto gen = registry.call("material.graph.generate", Json::object({{"material", rel}}));
        REQUIRE_MESSAGE(gen.ok, failure(gen));
        CHECK(gen.result["warnings"].empty());
        auto r = compile_material(dir.str(), rel, options);
        REQUIRE(r.ok());
        std::string why;
        for (const ShaderIssue& e : r->errors) why += e.to_string() + "\n";
        INFO(why);
        REQUIRE(r->ok);
        CHECK(r->twins.size() == 6);
        for (const std::string slang : {"hlsl5", "glsl430", "glsl300es", "metal_macos", "metal_ios", "metal_sim"}) {
            CAPTURE(slang);
            REQUIRE(r->twins.count(slang) == 1);
            const Json& twin = r->twins.at(slang);
            CHECK_FALSE(twin["programs"]["quad"]["fs"].get<std::string>().empty());
            CHECK_FALSE(twin["programs"]["quad_plain"]["fs"].get<std::string>().empty());
        }
    }
}

TEST_CASE("graph sprite: a node of the 3D kinds is refused with its place, why and what to use instead") {
    std::size_t refused = 0;
    for (const GraphNodeType& t : graph_node_library()) {
        if (std::find(t.kinds.begin(), t.kinds.end(), "sprite") != t.kinds.end() || t.type == kGraphOutputNode)
            continue;
        CAPTURE(t.type);
        Json node = Json::object({{"id", "n"}, {"type", t.type}});
        if (t.ref == "texture") node["texture"] = "albedoTex";
        const Json graph =
            Json::object({{"nodes", Json::array({node, Json::parse(R"({"id":"out","type":"output"})")})}});
        const MaterialDef def = material_with(base_doc());
        const GraphCheck c = check_material_graph(graph, def, "sprite");
        REQUIRE_FALSE(c.ok());
        bool teaches = false;
        for (const MaterialIssue& e : c.errors)
            if (e.pointer == "/graph/nodes/0/type" && e.message.find("\"sprite\"") != std::string::npos &&
                e.hint.find("`material.graph.nodes` with kind \"sprite\"") != std::string::npos && e.hint.size() > 80)
                teaches = true;
        CHECK_MESSAGE(teaches, all_errors(c));
        ++refused;
    }
    CHECK(
        refused >=
        9);  // vertex.color, position.world/view, normal.world, view.dir, texture.normal, triplanar, parallax, fresnel
    // the hints name the sprite alternative
    const MaterialDef def = material_with(base_doc());
    auto fresnel = check_material_graph(
        Json::parse(R"({"nodes":[{"id":"f","type":"fresnel"},{"id":"out","type":"output"}]})"), def, "sprite");
    REQUIRE_FALSE(fresnel.errors.empty());
    CHECK(fresnel.errors[0].hint.find("math.smoothstep") != std::string::npos);
    // a field of the mesh output is not one of the sprite output: the error lists the fields of the kind
    const GraphCheck wrong =
        check_of(R"({"nodes":[{"id":"out","type":"output","inputs":{"albedo":[1,0,0]}}]})", "sprite");
    bool lists = false;
    for (const MaterialIssue& e : wrong.errors)
        lists = lists || (e.pointer == "/graph/nodes/0/inputs/albedo" && e.hint.find("rgb") != std::string::npos);
    CHECK_MESSAGE(lists, all_errors(wrong));
    // a sprite graph with an output that writes nothing is a warning, not an error
    const GraphCheck empty = check_of(R"({"nodes":[{"id":"out","type":"output"}]})", "sprite");
    CHECK(empty.ok());
    CHECK_FALSE(empty.warnings.empty());
}

TEST_CASE("material.graph commands: a sprite material is generated, hand edits are protected like in a mesh") {
    Project p;
    p.write("materials/sdissolve.material.json", kSpriteDissolveMaterial);
    const char* args = R"({"material":"materials/sdissolve.material.json"})";
    auto v = p.call("material.graph.validate", args);
    REQUIRE_MESSAGE(v.ok, failure(v));
    CHECK(v.result["ok"] == true);
    CHECK(v.result["snippet"]["state"] == "missing");

    auto gen = p.call("material.graph.generate", args);
    REQUIRE_MESSAGE(gen.ok, failure(gen));
    CHECK(gen.result["written"] == true);
    const std::string generated = p.read("shaders/sdissolve.fragment.glsl");
    CHECK(generated.find("void fragment(in QuadInput i, inout QuadSurface s)") != std::string::npos);
    const Json written = p.doc("materials/sdissolve.material.json");
    CHECK(written["graphHash"] == graph_snippet_hash(generated));
    CHECK(written["kind"] == "sprite");

    // a second run changes nothing
    auto second = p.call("material.graph.generate", args);
    REQUIRE(second.ok);
    CHECK(second.result["written"] == false);
    CHECK(second.result["state"] == "in_sync");

    // the same hash rule as a mesh: CRLF is not an edit, a hand-written line is
    std::string crlf;
    for (char c : generated) crlf += c == '\n' ? std::string("\r\n") : std::string(1, c);
    p.write("shaders/sdissolve.fragment.glsl", crlf);
    CHECK(p.call("material.graph.validate", args).result["snippet"]["state"] == "in_sync");
    const std::string edited = generated + "// a hand-written tweak\n";
    p.write("shaders/sdissolve.fragment.glsl", edited);
    CHECK(p.call("material.graph.validate", args).result["snippet"]["state"] == "hand_edited");
    auto refused = p.call("material.graph.generate", args);
    REQUIRE_FALSE(refused.ok);
    CHECK(refused.error["code"].get<std::string>() == "hand_edited");
    CHECK(p.read("shaders/sdissolve.fragment.glsl") == edited);
    // a hand-touched graphHash: the code the graph makes with a hash that does not say so is "hash_missing" (generate refreshes
    // it), the same code edited by hand is a hand edit, never silently overwritten
    Json touched = p.doc("materials/sdissolve.material.json");
    touched["graphHash"] = std::string(64, 'c');
    p.write("materials/sdissolve.material.json", touched.dump(2));
    p.write("shaders/sdissolve.fragment.glsl", generated);
    CHECK(p.call("material.graph.validate", args).result["snippet"]["state"] == "hash_missing");
    p.write("shaders/sdissolve.fragment.glsl", edited);
    CHECK(p.call("material.graph.validate", args).result["snippet"]["state"] == "hand_edited");
    CHECK_FALSE(p.call("material.graph.generate", args).ok);
    auto forced = p.call("material.graph.generate", R"({"material":"materials/sdissolve.material.json","force":true})");
    REQUIRE_MESSAGE(forced.ok, failure(forced));
    CHECK(p.read("shaders/sdissolve.fragment.glsl") == generated);

    // a sprite is always blended: a graph material with alphaMode clip is an error that names the field
    Json clip = p.doc("materials/sdissolve.material.json");
    clip["alphaMode"] = "clip";
    p.write("materials/clip.material.json", clip.dump(2));
    auto cv = p.call("material.graph.validate", R"({"material":"materials/clip.material.json"})");
    REQUIRE(cv.ok);
    CHECK(cv.result["ok"] == false);
    CHECK(cv.result["errors"][0]["pointer"] == "/alphaMode");
}

TEST_CASE("material.graph.nodes: the kind sprite lists its nodes, its output and a sprite example that generates") {
    Project p;
    auto s = p.call("material.graph.nodes", R"({"kind":"sprite"})");
    REQUIRE_MESSAGE(s.ok, failure(s));
    std::set<std::string> types;
    const Json* output = nullptr;
    for (const Json& n : s.result["nodes"]) {
        types.insert(n["type"].get<std::string>());
        if (n["type"] == "output") output = &n;
    }
    CHECK(types.count("sprite.color") == 1);
    CHECK(types.count("noise.fbm") == 1);
    CHECK(types.count("fresnel") == 0);
    CHECK(types.count("position.world") == 0);
    CHECK(types.count("triplanar") == 0);
    REQUIRE(output);
    std::vector<std::string> fields;
    for (const Json& in : (*output)["inputs"]) fields.push_back(in["name"].get<std::string>());
    CHECK(fields == std::vector<std::string>{"color", "rgb", "alpha", "vertexOffset"});
    // the mesh list has the mesh output and the 3D nodes, and no sprite node
    auto m = p.call("material.graph.nodes", R"({"kind":"mesh"})");
    REQUIRE(m.ok);
    std::set<std::string> meshTypes;
    for (const Json& n : m.result["nodes"]) meshTypes.insert(n["type"].get<std::string>());
    CHECK(meshTypes.count("fresnel") == 1);
    CHECK(meshTypes.count("sprite.color") == 0);
    // the example is a sprite material that passes the checks and generates the template of a sprite
    const Json example = s.result["example"];
    CHECK(example["kind"] == "sprite");
    MaterialParse mp = parse_material(example, "");
    REQUIRE_MESSAGE(mp.ok(), (mp.errors.empty() ? "" : mp.errors[0].to_string()));
    const GeneratedGraph g = generate_graph_snippet(mp.material.graph, mp.material, "sprite");
    REQUIRE_MESSAGE(g.check.ok(), all_errors(g.check));
    CHECK(g.snippet.find("void fragment(in QuadInput i, inout QuadSurface s)") != std::string::npos);
    // a sprite node with no kind given is listed with its kinds
    auto one = p.call("material.graph.nodes", R"({"type":"sprite.life"})");
    REQUIRE(one.ok);
    CHECK(one.result["nodes"][0]["kinds"] == Json::parse(R"(["sprite"])"));
}

// ---------------------------------------------------------------------------------------------------------------
// Post materials: the same graph, the entry point post() of the post template
// ---------------------------------------------------------------------------------------------------------------

namespace {

// A material of kind post with a param, a colour param and a texture, for the graphs below.
Json post_doc(const std::string& name) {
    Json doc = Json::parse(R"({
      "format": "factoria.material/1",
      "kind": "post",
      "doc": "A post pass made of nodes.",
      "params": {
        "amount": { "type": "float", "default": 0.3, "min": 0, "max": 1, "doc": "A float." },
        "tint": { "type": "color", "default": [1, 0.5, 0.2, 1], "doc": "A color." }
      },
      "textures": { "albedoTex": { "sampler": "linearRepeat", "doc": "A texture." } }
    })");
    doc["shader"] = "shaders/" + name + ".post.glsl";
    return doc;
}

// A trail: the picture, or what the pass drew last frame faded by a param, whichever is brighter. The material asks for the history by
// using the node: the file has nothing to declare.
Json post_trail_material() {
    Json doc = post_doc("trail");
    doc["graph"] = Json::parse(R"({
      "nodes": [
        { "id": "pic", "type": "post.scene" },
        { "id": "last", "type": "post.history" },
        { "id": "keep", "type": "param", "param": "amount" },
        { "id": "fade", "type": "math.mul" },
        { "id": "bright", "type": "math.max" },
        { "id": "out", "type": "output" }
      ],
      "links": [
        { "from": "last.rgb", "to": "fade.a" },
        { "from": "keep.value", "to": "fade.b" },
        { "from": "pic.rgb", "to": "bright.a" },
        { "from": "fade.result", "to": "bright.b" },
        { "from": "bright.result", "to": "out.rgb" }
      ]})");
    return doc;
}

// Every node type that works in a post pass, with its defaults; every output goes through a math.length into one sum that the output
// node writes, so every node is reachable.
Json post_all_nodes_material() {
    GraphBuilder g;
    std::vector<std::string> floats;
    auto reduce = [&](const std::string& id, const std::string& from) {
        g.node("len_" + id, "math.length");
        g.link(from, "len_" + id + ".x");
        floats.push_back("len_" + id + ".result");
    };
    int k = 0;
    for (const GraphNodeType& t : graph_node_library()) {
        if (t.type == kGraphOutputNode || std::find(t.kinds.begin(), t.kinds.end(), "post") == t.kinds.end()) continue;
        const std::string id = "n" + std::to_string(k++);
        if (t.ref == "param") {
            g.node(id, t.type, {}, "param", "amount");
            reduce(id + "_value", id + ".value");
            const std::string c = id + "c";
            g.node(c, t.type, {}, "param", "tint");
            reduce(c + "_value", c + ".value");
            continue;
        }
        if (t.ref == "texture")
            g.node(id, t.type, {}, "texture", "albedoTex");
        else
            g.node(id, t.type);
        for (std::size_t o = 0; o < t.outputs.size(); ++o) {
            if (t.type == "math.split" && o > 0) continue;  // a float has no y, z or w
            reduce(id + "_" + t.outputs[o].name, id + "." + t.outputs[o].name);
        }
    }
    const std::string total = g.sum("sum", floats);
    g.node("out", "output");
    g.link(total, "out.rgb");
    Json doc = post_doc("postall");
    doc["doc"] = "Every node type of the graph library that works in a post pass, in one material.";
    doc["graph"] = Json::object({{"nodes", g.nodes}, {"links", g.links}});
    return doc;
}

}  // namespace

TEST_CASE("graph post: the example of material.graph.nodes writes post() of the post template and nothing else") {
    Project p;
    auto s = p.call("material.graph.nodes", R"({"kind":"post"})");
    REQUIRE_MESSAGE(s.ok, failure(s));
    const Json example = s.result["example"];
    CHECK(example["kind"] == "post");
    MaterialParse mp = parse_material(example, "");
    REQUIRE_MESSAGE(mp.ok(), (mp.errors.empty() ? "" : mp.errors[0].to_string()));
    const GeneratedGraph g = generate_graph_snippet(mp.material.graph, mp.material, "post");
    REQUIRE_MESSAGE(g.check.ok(), all_errors(g.check));
    CHECK(g.check.warnings.empty());
    CHECK_FALSE(g.hasVertex);
    CHECK(g.snippet.find("void post(in PostInput i, inout PostSurface s) {\n") != std::string::npos);
    CHECK(g.snippet.find("surface(") == std::string::npos);
    CHECK(g.snippet.find("fragment(") == std::string::npos);
    CHECK(g.snippet.find("vertex(") == std::string::npos);
    CHECK(g.snippet.find("fa_scene_color(n_moved_result)") != std::string::npos);  // the picture, read at the moved uv
    CHECK(g.snippet.find("    s.color.rgb = n_lit_result;  // out (output)\n") != std::string::npos);
    CHECK(g.snippet.find("fa_history") == std::string::npos);  // the pass keeps no history: it never asked for one
    const GeneratedGraph again = generate_graph_snippet(mp.material.graph, mp.material, "post");
    CHECK(again.snippet == g.snippet);
    CHECK(again.hash == graph_snippet_hash(g.snippet));
    // the list of the kind has the post nodes and the post output, and none of the other kinds' nodes
    std::set<std::string> types;
    const Json* output = nullptr;
    for (const Json& n : s.result["nodes"]) {
        types.insert(n["type"].get<std::string>());
        if (n["type"] == "output") output = &n;
    }
    for (const char* t :
         {"post.scene", "post.depth", "post.normal", "post.history", "post.screen", "noise.fbm", "flow", "uv", "time"})
        CHECK_MESSAGE(types.count(t) == 1, t);
    for (const char* t : {"sprite.color", "fresnel", "position.world", "triplanar"})
        CHECK_MESSAGE(types.count(t) == 0, t);
    REQUIRE(output);
    std::vector<std::string> fields;
    for (const Json& in : (*output)["inputs"]) fields.push_back(in["name"].get<std::string>());
    CHECK(fields == std::vector<std::string>{"color", "rgb"});
    // a post node is in neither the mesh nor the sprite list
    CHECK_FALSE(p.call("material.graph.nodes", R"({"kind":"mesh","type":"post.scene"})").ok);
    CHECK_FALSE(p.call("material.graph.nodes", R"({"kind":"sprite","type":"post.depth"})").ok);
}

TEST_CASE("graph post: one graph uses every node type that works in a post pass and generates") {
    const Json doc = post_all_nodes_material();
    std::set<std::string> used;
    for (const Json& n : doc["graph"]["nodes"]) used.insert(n["type"].get<std::string>());
    for (const GraphNodeType& t : graph_node_library())
        if (std::find(t.kinds.begin(), t.kinds.end(), "post") != t.kinds.end())
            CHECK_MESSAGE(used.count(t.type) == 1, "the post all-nodes graph lacks " << t.type);
    MaterialParse mp = parse_material(doc, "");
    REQUIRE_MESSAGE(mp.ok(), (mp.errors.empty() ? "" : mp.errors[0].to_string()));
    const GeneratedGraph g = generate_graph_snippet(doc["graph"], mp.material, "post");
    REQUIRE_MESSAGE(g.check.ok(), all_errors(g.check));
    CHECK(g.check.warnings.empty());
    CHECK_FALSE(g.hasVertex);
    CHECK(g.usedNodes.size() + 1 == doc["graph"]["nodes"].size());
    for (const char* call :
         {"fa_scene_color(", "fa_depth(", "fa_normal(", "fa_history(", "i.texel", "i.size", "fa_time.x"})
        CHECK_MESSAGE(g.snippet.find(call) != std::string::npos, call);
}

TEST_CASE("graph post: the history is asked for by the node alone, with nothing to declare in the material file") {
    const Json doc = post_trail_material();
    MaterialParse mp = parse_material(doc, "");
    REQUIRE_MESSAGE(mp.ok(), (mp.errors.empty() ? "" : mp.errors[0].to_string()));
    const GeneratedGraph g = generate_graph_snippet(doc["graph"], mp.material, "post");
    REQUIRE_MESSAGE(g.check.ok(), all_errors(g.check));
    CHECK(g.check.warnings.empty());
    // what makes the renderer keep the output is the call the snippet makes (docs/shaders/SHADERS_POST.md, "History")
    CHECK(g.snippet.find("vec4 n_last_rgba = fa_history(i.uv);") != std::string::npos);
    CHECK(g.snippet.find("float n_last_valid = (fa_history_valid ? 1.0 : 0.0);") != std::string::npos);
    // the same graph without the history node calls nothing of the kind, and the material file has the same keys
    Json without = doc;
    without["graph"] = Json::parse(R"({"nodes":[{"id":"pic","type":"post.scene"},{"id":"out","type":"output"}],
                                       "links":[{"from":"pic.rgb","to":"out.rgb"}]})");
    CHECK(without.size() == doc.size());
    const GeneratedGraph none = generate_graph_snippet(without["graph"], material_with(without), "post");
    REQUIRE_MESSAGE(none.check.ok(), all_errors(none.check));
    CHECK(none.snippet.find("fa_history") == std::string::npos);
    // the history node does not exist in the other kinds: there it is refused with its place and the kinds it works in
    for (const char* kind : {"mesh", "sprite"}) {
        CAPTURE(kind);
        const GraphCheck c =
            check_of(R"({"nodes":[{"id":"h","type":"post.history"},{"id":"out","type":"output"}]})", kind);
        CHECK(has_error(c, "/graph/nodes/0/type",
                        std::string("does not work in a material of kind \"") + kind + "\" (it works in post)"));
    }
}

TEST_CASE("graph colours: a sprite or post graph converts const.color and colour params with fa_scene_rgb, a mesh "
          "graph does not") {
    const Json doc = post_doc("tinted");
    const MaterialDef def = material_with(doc);
    const Json graph = Json::parse(R"({
      "nodes": [
        { "id": "c", "type": "const.color", "inputs": { "rgba": [0.2, 0.4, 0.6, 1] } },
        { "id": "t", "type": "param", "param": "tint" },
        { "id": "amt", "type": "param", "param": "amount" },
        { "id": "mix", "type": "math.lerp" },
        { "id": "out", "type": "output" }
      ],
      "links": [
        { "from": "c.rgba", "to": "mix.a" },
        { "from": "t.value", "to": "mix.b" },
        { "from": "amt.value", "to": "mix.t" },
        { "from": "mix.result", "to": "out.color" }
      ]
    })");
    const char* kinds[] = {"mesh", "sprite", "post"};
    for (const char* kind : kinds) {
        CAPTURE(kind);
        Json g = graph;
        if (std::string(kind) ==
            "mesh") {  // the mesh output has no color and takes three components: the same colours, as albedo
            g = Json::parse(R"({
              "nodes": [
                { "id": "c", "type": "const.color", "inputs": { "rgba": [0.2, 0.4, 0.6, 1] } },
                { "id": "out", "type": "output" }
              ],
              "links": [ { "from": "c.rgb", "to": "out.albedo" } ]
            })");
        }
        const GeneratedGraph gen = generate_graph_snippet(g, def, kind);
        REQUIRE_MESSAGE(gen.check.ok(), all_errors(gen.check));
        const bool converts = std::string(kind) != "mesh";
        CHECK((gen.snippet.find("fa_scene_rgb(vec4(0.2, 0.4, 0.6, 1.0).rgb)") != std::string::npos) == converts);
        if (converts)
            CHECK(gen.snippet.find("fa_scene_rgb(tint.rgb)") != std::string::npos);
        else
            CHECK(gen.snippet.find("fa_scene_rgb") == std::string::npos);
        CHECK(gen.snippet.find("fa_scene_rgb(amount") == std::string::npos);  // only colours
    }
}

TEST_CASE("graph check: the message of a graph with no output node suggests a field of its own kind") {
    const char* graph = R"({"nodes":[{"id":"t","type":"time"}]})";
    const struct {
        const char* kind;
        const char* field;
    } cases[] = {{"mesh", "\"albedo\""}, {"sprite", "\"color\""}, {"post", "\"rgb\""}};
    for (const auto& c : cases) {
        CAPTURE(c.kind);
        const GraphCheck check = check_of(graph, c.kind);
        bool found = false;
        for (const MaterialIssue& e : check.errors)
            if (e.message.find("no output node") != std::string::npos)
                found = found || e.hint.find(c.field) != std::string::npos;
        CHECK(found);
    }
}

TEST_CASE("graph post: a node of the 3D or sprite kinds is refused with its place, why and what to use instead") {
    std::size_t refused = 0;
    for (const GraphNodeType& t : graph_node_library()) {
        if (std::find(t.kinds.begin(), t.kinds.end(), "post") != t.kinds.end() || t.type == kGraphOutputNode) continue;
        CAPTURE(t.type);
        Json node = Json::object({{"id", "n"}, {"type", t.type}});
        if (t.ref == "texture") node["texture"] = "albedoTex";
        Json doc = post_doc("bad");
        doc["graph"] = Json::object({{"nodes", Json::array({node, Json::parse(R"({"id":"out","type":"output"})")})}});
        const MaterialDef def = material_with(doc);
        const GraphCheck c = check_material_graph(doc["graph"], def, "post");
        REQUIRE_FALSE(c.ok());
        bool teaches = false;
        for (const MaterialIssue& e : c.errors)
            if (e.pointer == "/graph/nodes/0/type" && e.message.find("\"post\"") != std::string::npos &&
                e.hint.find("`material.graph.nodes` with kind \"post\"") != std::string::npos && e.hint.size() > 80)
                teaches = true;
        CHECK_MESSAGE(teaches, all_errors(c));
        ++refused;
    }
    CHECK(refused >= 14);  // the nine of the 3D kinds and the six of the sprite
    // the hints name the post alternative
    const Json doc = post_doc("bad");
    const MaterialDef def = material_with(doc);
    auto normal = check_material_graph(
        Json::parse(R"({"nodes":[{"id":"n","type":"normal.world"},{"id":"out","type":"output"}]})"), def, "post");
    REQUIRE_FALSE(normal.errors.empty());
    CHECK(normal.errors[0].hint.find("post.normal") != std::string::npos);
    auto sc = check_material_graph(
        Json::parse(R"({"nodes":[{"id":"n","type":"sprite.color"},{"id":"out","type":"output"}]})"), def, "post");
    REQUIRE_FALSE(sc.errors.empty());
    CHECK(sc.errors[0].hint.find("post.scene") != std::string::npos);
    // a field of the mesh output, or a vertex offset, is not one of the post output: the error lists the fields of the kind
    for (const char* wrong : {R"({"nodes":[{"id":"out","type":"output","inputs":{"albedo":[1,0,0]}}]})",
                              R"({"nodes":[{"id":"out","type":"output","inputs":{"vertexOffset":[1,0,0]}}]})"}) {
        const GraphCheck c = check_material_graph(Json::parse(wrong), def, "post");
        bool lists = false;
        for (const MaterialIssue& e : c.errors)
            lists =
                lists || (e.pointer.rfind("/graph/nodes/0/inputs/", 0) == 0 && e.hint.find("rgb") != std::string::npos);
        CHECK_MESSAGE(lists, all_errors(c));
    }
    // an output that writes nothing is a warning that says the picture stays as it is
    const GraphCheck empty =
        check_material_graph(Json::parse(R"({"nodes":[{"id":"out","type":"output"}]})"), def, "post");
    CHECK(empty.ok());
    REQUIRE_FALSE(empty.warnings.empty());
    CHECK(empty.warnings[0].message.find("picture as it is") != std::string::npos);
}

TEST_CASE("graph post: the generated snippet compiles with the real sokol-shdc for every dialect") {
    SetupContext context;
    FA_SKIP_WITHOUT_SHDC(
        context, "sokol-shdc is not installed (SOKOL_SHDC, or `factoria setup shaders`): the post graph is generated "
                 "but not compiled here; CI compiles it");
    testing::TempDir dir;
    Project helper;
    auto nodes = helper.call("material.graph.nodes", R"({"kind":"post"})");
    REQUIRE(nodes.ok);
    testing::write_all(dir.path / "materials/pall.material.json", post_all_nodes_material().dump(2));
    testing::write_all(dir.path / "materials/ptrail.material.json", post_trail_material().dump(2));
    testing::write_all(dir.path / "materials/pwobble.material.json", nodes.result["example"].dump(2));
    CommandRegistry registry;
    register_material_graph_commands(registry, dir.str());
    ShaderCompileOptions options;
    options.setup = context;
    options.useCache = false;
    for (const char* name : {"pall", "ptrail", "pwobble"}) {
        CAPTURE(name);
        const std::string rel = std::string("materials/") + name + ".material.json";
        auto gen = registry.call("material.graph.generate", Json::object({{"material", rel}}));
        REQUIRE_MESSAGE(gen.ok, failure(gen));
        CHECK(gen.result["warnings"].empty());
        auto r = compile_material(dir.str(), rel, options);
        REQUIRE(r.ok());
        std::string why;
        for (const ShaderIssue& e : r->errors) why += e.to_string() + "\n";
        INFO(why);
        REQUIRE(r->ok);
        CHECK(r->twins.size() == 6);
        for (const std::string slang : {"hlsl5", "glsl430", "glsl300es", "metal_macos", "metal_ios", "metal_sim"}) {
            CAPTURE(slang);
            REQUIRE(r->twins.count(slang) == 1);
            CHECK_FALSE(r->twins.at(slang)["programs"]["post"]["fs"].get<std::string>().empty());
        }
    }
}

TEST_CASE("material.graph commands: a post material is generated, hand edits are protected like in a mesh") {
    Project p;
    auto nodes = p.call("material.graph.nodes", R"({"kind":"post"})");
    REQUIRE(nodes.ok);
    p.write("materials/wobble.material.json", nodes.result["example"].dump(2));
    const char* args = R"({"material":"materials/wobble.material.json"})";
    auto v = p.call("material.graph.validate", args);
    REQUIRE_MESSAGE(v.ok, failure(v));
    CHECK(v.result["ok"] == true);
    CHECK(v.result["snippet"]["state"] == "missing");
    auto gen = p.call("material.graph.generate", args);
    REQUIRE_MESSAGE(gen.ok, failure(gen));
    CHECK(gen.result["written"] == true);
    const std::string generated = p.read("shaders/wobble-vignette.post.glsl");
    CHECK(generated.find("void post(in PostInput i, inout PostSurface s)") != std::string::npos);
    const Json written = p.doc("materials/wobble.material.json");
    CHECK(written["graphHash"] == graph_snippet_hash(generated));
    CHECK(written["kind"] == "post");
    // a second run changes nothing; a hand edit is never overwritten without force
    CHECK(p.call("material.graph.generate", args).result["written"] == false);
    const std::string edited = generated + "// a hand-written tweak\n";
    p.write("shaders/wobble-vignette.post.glsl", edited);
    CHECK(p.call("material.graph.validate", args).result["snippet"]["state"] == "hand_edited");
    auto refused = p.call("material.graph.generate", args);
    REQUIRE_FALSE(refused.ok);
    CHECK(refused.error["code"].get<std::string>() == "hand_edited");
    CHECK(p.read("shaders/wobble-vignette.post.glsl") == edited);
    auto forced = p.call("material.graph.generate", R"({"material":"materials/wobble.material.json","force":true})");
    REQUIRE_MESSAGE(forced.ok, failure(forced));
    CHECK(p.read("shaders/wobble-vignette.post.glsl") == generated);
}

// ---------------------------------------------------------------------------------------------------------------
// The editor's needs: "editor" and "version" keys, the check of a graph held in memory, no cascade, reserved names
// ---------------------------------------------------------------------------------------------------------------

TEST_CASE("graph editor keys: version and editor are accepted, the generator ignores them, wrong ones are errors") {
    Project p;
    Json doc = p.doc();
    const std::string plain = check_material_document(doc, p.dir.str()).snippet;
    REQUIRE_FALSE(plain.empty());

    doc["graph"]["version"] = 1;
    doc["graph"]["editor"] = Json::parse(R"({"zoom":1.5,"pan":[10,20],"comments":["a"]})");
    doc["graph"]["nodes"][0]["editor"] = Json::parse(R"({"collapsed":true})");
    MaterialGraphReport r = check_material_document(doc, p.dir.str());
    CHECK_MESSAGE(r.ok(), all_errors(GraphCheck{r.errors, r.warnings}));
    CHECK(r.snippet == plain);
    CHECK(r.hash == graph_snippet_hash(plain));

    doc["graph"]["version"] = 2;
    r = check_material_document(doc, p.dir.str());
    REQUIRE_FALSE(r.ok());
    CHECK(has_error(GraphCheck{r.errors, r.warnings}, "/graph/version", "reads graph version 1"));
    doc["graph"]["version"] = 1;
    doc["graph"]["editor"] = 3;
    doc["graph"]["nodes"][0]["editor"] = "x";
    r = check_material_document(doc, p.dir.str());
    GraphCheck gc{r.errors, r.warnings};
    CHECK(has_error(gc, "/graph/editor", "expected an object"));
    CHECK(has_error(gc, "/graph/nodes/0/editor", "expected an object"));
}

TEST_CASE("material.graph.validate and generate take a graph held in memory") {
    Project p;
    Json graph = p.doc()["graph"];
    graph["nodes"][0]["inputs"]["scale"] = 11.0;
    Json args = {{"material", "materials/dissolve.material.json"}, {"graph", graph}};
    auto v = p.registry.call("material.graph.validate", args);
    REQUIRE_MESSAGE(v.ok, failure(v));
    CHECK(v.result["ok"] == true);
    // the file is untouched
    CHECK(p.doc()["graph"]["nodes"][0]["inputs"]["scale"] == 6.0);

    graph["links"][1]["from"] = "amoun.value";
    args["graph"] = graph;
    v = p.registry.call("material.graph.validate", args);
    REQUIRE(v.ok);
    CHECK(v.result["ok"] == false);
    CHECK(v.result.dump().find("/graph/links/1/from") != std::string::npos);

    // generate with a graph writes that graph into the material and its snippet
    graph = p.doc()["graph"];
    graph["nodes"][0]["inputs"]["scale"] = 11.0;
    graph["version"] = 1;
    graph["nodes"][0]["pos"] = Json::parse("[5,6]");
    auto gen = p.registry.call("material.graph.generate",
                               Json{{"material", "materials/dissolve.material.json"}, {"graph", graph}});
    REQUIRE_MESSAGE(gen.ok, failure(gen));
    CHECK(gen.result["written"] == true);
    const Json saved = p.doc();
    CHECK(saved["graph"] == graph);
    CHECK(saved["graphHash"] == graph_snippet_hash(p.read("shaders/dissolve.surface.glsl")));
    CHECK(p.read("shaders/dissolve.surface.glsl").find("11.0") != std::string::npos);
}

TEST_CASE("graph check: a failed param or texture node does not cascade into a type mismatch") {
    auto c = check_of(R"({"nodes":[{"id":"p","type":"param","param":"amout"},
                                   {"id":"n","type":"noise.fbm","inputs":{"scale":1}},
                                   {"id":"mul","type":"dissolve"},
                                   {"id":"out","type":"output"}],
                          "links":[{"from":"p.value","to":"mul.threshold"},{"from":"n.value","to":"mul.noise"},
                                   {"from":"mul.alpha","to":"out.alpha"}]})");
    CHECK(has_error(c, "/graph/nodes/0/param", "no param \"amout\""));
    for (const MaterialIssue& e : c.errors)
        CHECK_MESSAGE(e.message.find("mismatch") == std::string::npos, e.to_string());
    CHECK(c.errors.size() == 1);
}

TEST_CASE("graph check: params and textures named gn_ are refused with the fix") {
    Json doc = base_doc();
    doc["params"]["gn_amount"] = Json::parse(R"({"type":"float","default":0.5,"doc":"x"})");
    doc["textures"]["gn_tex"] = Json::parse(R"({"doc":"x"})");
    doc["graph"] = Json::parse(R"({"nodes":[{"id":"out","type":"output"}]})");
    const MaterialGraphReport r = check_material_document(doc);
    const GraphCheck gc{r.errors, r.warnings};
    CHECK(has_error(gc, "/params/gn_amount", "starts with gn_"));
    CHECK(has_error(gc, "/textures/gn_tex", "starts with gn_"));
    for (const MaterialIssue& e : r.errors)
        if (e.pointer == "/params/gn_amount") CHECK(e.hint.find("Rename") != std::string::npos);
}

TEST_CASE("graph line map: every line of a node or the output names the node that wrote it") {
    Project p;
    const MaterialGraphReport r = check_material_document(p.doc(), p.dir.str(), "materials/dissolve.material.json");
    REQUIRE(r.errors.empty());
    const std::string& snippet = r.snippet;
    const std::size_t lines = std::size_t(std::count(snippet.begin(), snippet.end(), '\n'));
    REQUIRE(r.lineNodes.size() == lines);  // one entry per line
    // a node line ends with "// <id> (<type>)", an output line with "// <id> (output)": the map and the marker agree
    std::size_t start = 0;
    std::set<std::string> named;
    for (int line = 1; start < snippet.size(); ++line) {
        const std::size_t end = snippet.find('\n', start);
        const std::string text = snippet.substr(start, end - start);
        start = end + 1;
        const std::string owner = graph_node_at_line(r.lineNodes, line);
        if (owner.empty()) continue;
        named.insert(owner);
        const std::size_t marker = text.rfind("// ");
        REQUIRE(marker != std::string::npos);
        CHECK_MESSAGE(text.compare(marker + 3, owner.size() + 2, owner + " (") == 0,
                      "line " << line << " is mapped to " << owner << ": " << text);
    }
    CHECK(named == std::set<std::string>{"amount", "burn", "noise", "out"});
    // outside the snippet: no node
    CHECK(graph_node_at_line(r.lineNodes, 0).empty());
    CHECK(graph_node_at_line(r.lineNodes, int(lines) + 1).empty());
}

TEST_CASE("graph line map: a vertexOffset graph maps the vertex function's lines too") {
    Json doc = Json::parse(kDissolveMaterial);
    doc["graph"]["nodes"][3]["inputs"]["vertexOffset"] = Json::parse("[0.0, 0.1, 0.0]");
    const MaterialGraphReport r = check_material_document(doc);
    REQUIRE(r.errors.empty());
    REQUIRE(r.hasVertex);
    const std::size_t lines = std::size_t(std::count(r.snippet.begin(), r.snippet.end(), '\n'));
    CHECK(r.lineNodes.size() == lines);
    int vertexLine = 0, line = 0;
    std::size_t start = 0;
    while (start < r.snippet.size()) {
        const std::size_t end = r.snippet.find('\n', start);
        ++line;
        if (r.snippet.substr(start, end - start).find("v.world_pos +=") != std::string::npos) vertexLine = line;
        start = end + 1;
    }
    REQUIRE(vertexLine > 0);
    CHECK(graph_node_at_line(r.lineNodes, vertexLine) == "out");
    // the surface() function after it is still mapped (the blank line between the two has no node)
    CHECK(graph_node_at_line(r.lineNodes, line - 1) == "out");
}

TEST_CASE("material.param.set_default writes one default, checks the value, and says what it replaced") {
    Project p;
    const std::string before = p.read("materials/dissolve.material.json");
    auto dry =
        p.call("material.param.set_default",
               R"({"material":"materials/dissolve.material.json","param":"dissolve","value":0.4,"dryRun":true})");
    REQUIRE_MESSAGE(dry.ok, failure(dry));
    CHECK(dry.result["written"] == false);
    CHECK(p.read("materials/dissolve.material.json") == before);

    auto set = p.call("material.param.set_default",
                      R"({"material":"materials/dissolve.material.json","param":"dissolve","value":0.4})");
    REQUIRE_MESSAGE(set.ok, failure(set));
    CHECK(set.result["written"] == true);
    CHECK(set.result["previous"] == 0.0);
    CHECK(p.doc()["params"]["dissolve"]["default"] == 0.4);
    CHECK(p.doc()["graph"] == Json::parse(kDissolveMaterial)["graph"]);  // the graph is untouched

    // the same value again writes nothing; `previous` takes the change back
    auto again = p.call("material.param.set_default",
                        R"({"material":"materials/dissolve.material.json","param":"dissolve","value":0.4})");
    REQUIRE(again.ok);
    CHECK(again.result["written"] == false);
    auto back = p.registry.call("material.param.set_default", Json{{"material", "materials/dissolve.material.json"},
                                                                   {"param", "dissolve"},
                                                                   {"value", set.result["previous"]}});
    REQUIRE(back.ok);
    CHECK(p.doc()["params"]["dissolve"]["default"] == 0.0);

    // a value of the wrong shape or outside min..max is refused with the pointer, and nothing changes
    const std::string now = p.read("materials/dissolve.material.json");
    auto wrong = p.call("material.param.set_default",
                        R"({"material":"materials/dissolve.material.json","param":"dissolve","value":[1,2]})");
    REQUIRE_FALSE(wrong.ok);
    CHECK(wrong.error["message"].get<std::string>().find("/params/dissolve/default") != std::string::npos);
    auto range = p.call("material.param.set_default",
                        R"({"material":"materials/dissolve.material.json","param":"dissolve","value":7})");
    REQUIRE_FALSE(range.ok);
    CHECK(range.error["message"].get<std::string>().find("/params/dissolve/default") != std::string::npos);
    CHECK(range.error["hint"].is_string());
    CHECK_FALSE(range.error["hint"].get<std::string>().empty());
    // a param that is not an object ({"a": 5}) is an error of the command, never an exception
    p.write("materials/odd.material.json",
            R"({"format":"factoria.material/1","shader":"shaders/odd.surface.glsl","params":{"a":5}})");
    p.write("shaders/odd.surface.glsl", "void surface(inout SurfaceOut s) {}\n");
    const std::string odd = p.read("materials/odd.material.json");
    auto notObject =
        p.call("material.param.set_default", R"({"material":"materials/odd.material.json","param":"a","value":1})");
    REQUIRE_FALSE(notObject.ok);
    // (the material check of load_material refuses it first, with the pointer; the command's own is_object check is a second guard)
    CHECK(notObject.error["code"].get<std::string>() == "invalid_material");
    CHECK(notObject.error["message"].get<std::string>().find("/params/a") != std::string::npos);
    CHECK_FALSE(notObject.error["hint"].get<std::string>().empty());
    CHECK(p.read("materials/odd.material.json") == odd);
    // a param the file does not have: did you mean
    auto unknown = p.call("material.param.set_default",
                          R"({"material":"materials/dissolve.material.json","param":"disolve","value":0.1})");
    REQUIRE_FALSE(unknown.ok);
    CHECK(unknown.error["code"].get<std::string>() == "not_found");
    CHECK(unknown.error["hint"].get<std::string>().find("dissolve") != std::string::npos);
    CHECK(p.read("materials/dissolve.material.json") == now);
}
