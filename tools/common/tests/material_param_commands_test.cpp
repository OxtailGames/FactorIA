// material.param.create|rename|delete and material.texture.create|rename|delete (tools/common/src/material_graph_commands.cpp): the commands
// behind the Graph panel's list of params and textures. Same checks as the file, the nodes that read a name follow a rename, a delete that
// would break the graph is refused with the nodes' ids, and a snippet the graph generated stays in step.
#include <doctest.h>

#include "fa/core/command.h"
#include "fa/tooling/material_graph.h"
#include "fa/tooling/shaders.h"
#include "fa/tooling/validate.h"
#include "shaders_internal.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* const kMat = "materials/dissolve.material.json";
const char* const kSnippet = "shaders/dissolve.surface.glsl";

const char* const kDissolve = R"({
  "format": "factoria.material/1",
  "doc": "Dissolve.",
  "shader": "shaders/dissolve.surface.glsl",
  "alphaMode": "clip",
  "params": {
    "dissolve": { "type": "float", "default": 0.0, "min": 0.0, "max": 1.0, "doc": "0 shows the surface, 1 dissolves it all." }
  },
  "graph": {
    "nodes": [
      { "id": "noise", "type": "noise.fbm", "pos": [0, 0], "inputs": { "scale": 6.0 } },
      { "id": "amount", "type": "param", "pos": [0, 120], "param": "dissolve" },
      { "id": "burn", "type": "dissolve", "pos": [220, 60], "inputs": { "edgeWidth": 0.06 } },
      { "id": "out", "type": "output", "pos": [440, 60], "inputs": { "albedo": [0.6, 0.6, 0.65] } }
    ],
    "links": [
      { "from": "noise.value", "to": "burn.noise" },
      { "from": "amount.value", "to": "burn.threshold" },
      { "from": "burn.alpha", "to": "out.alpha" },
      { "from": "burn.emission", "to": "out.emission" }
    ]
  }
})";

std::string failure(const CommandResult& r) {
    return r.ok ? std::string() : r.error.value("message", std::string()) + " " + r.error.value("hint", std::string());
}

struct Project {
    testing::TempDir dir;
    CommandRegistry registry;
    Project() {
        write(kMat, kDissolve);
        register_material_graph_commands(registry, dir.str());
    }
    void write(const std::string& rel, const std::string& text) { testing::write_all(dir.path / rel, text); }
    std::string read(const std::string& rel) const { return testing::read_all(dir.path / rel); }
    Json doc() const { return Json::parse(read(kMat)); }
    // `args` plus {"material": kMat}
    CommandResult call(const char* name, const char* args) {
        Json a = Json::parse(args);
        a["material"] = kMat;
        return registry.call(name, a);
    }
    CommandResult call(const char* name, Json a) {
        a["material"] = kMat;
        return registry.call(name, a);
    }
    void generate() {
        const CommandResult r = registry.call("material.graph.generate", Json::object({{"material", kMat}}));
        REQUIRE_MESSAGE(r.ok, failure(r));
    }
};

}  // namespace

TEST_CASE("material.param.create adds a param with the file's own checks, and dryRun writes nothing") {
    Project p;
    const std::string before = p.read(kMat);
    auto dry = p.call("material.param.create", R"({"name":"glow","type":"float","dryRun":true})");
    REQUIRE_MESSAGE(dry.ok, failure(dry));
    CHECK(dry.result["written"] == false);
    CHECK(dry.result["entry"]["default"] == 0.0);
    CHECK(p.read(kMat) == before);

    auto made =
        p.call("material.param.create", R"({"name":"glow","type":"float","min":0.25,"max":1,"doc":"Edge glow."})");
    REQUIRE_MESSAGE(made.ok, failure(made));
    CHECK(made.result["written"] == true);
    CHECK(p.doc()["params"]["glow"]["default"] == 0.25);  // zero moved into min..max
    CHECK(p.doc()["params"]["glow"]["doc"] == "Edge glow.");
    CHECK(p.doc()["params"].size() == 2);
    // a colour starts white; the doc is a placeholder the file format accepts
    auto color = p.call("material.param.create", R"({"name":"tint","type":"color"})");
    REQUIRE_MESSAGE(color.ok, failure(color));
    CHECK(p.doc()["params"]["tint"]["default"] == Json::parse("[1,1,1,1]"));
    CHECK_FALSE(p.doc()["params"]["tint"]["doc"].get<std::string>().empty());
    // the graph is untouched
    CHECK(p.doc()["graph"] == Json::parse(kDissolve)["graph"]);

    auto tex = p.call("material.texture.create", R"({"name":"maskMap","sampler":"linearRepeat","doc":"Mask."})");
    REQUIRE_MESSAGE(tex.ok, failure(tex));
    CHECK(p.doc()["textures"]["maskMap"]["sampler"] == "linearRepeat");
}

TEST_CASE("material.param.create and texture.create refuse what the file refuses, with the fix, and write nothing") {
    Project p;
    const std::string before = p.read(kMat);
    auto refused = [&](const char* name, const char* args, const char* code, const char* hintPart) {
        auto r = p.call(name, args);
        INFO(name << " " << args);
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"].get<std::string>() == code);
        CHECK_FALSE(r.error["hint"].get<std::string>().empty());
        CHECK(r.error["hint"].get<std::string>().find(hintPart) != std::string::npos);
        CHECK(p.read(kMat) == before);
    };
    refused("material.param.create", R"({"name":"dissolve","type":"float"})", "already_exists", "another name");
    refused("material.param.create", R"({"name":"gn_hash","type":"float"})", "reserved_name", "hash");
    refused("material.texture.create", R"({"name":"gn_map"})", "reserved_name", "map");
    refused("material.param.create", R"({"name":"fa_time","type":"float"})", "invalid_value", "time");
    refused("material.param.create", R"({"name":"glow","type":"flaot"})", "invalid_value", "float");
    refused("material.param.create", R"({"name":"main","type":"float"})", "invalid_value", "main");
    refused("material.param.create", R"({"name":"glow","type":"float","default":[1,2]})", "invalid_value", "number");
    refused("material.param.create", R"({"name":"glow","type":"float","min":1,"max":2,"default":5})", "invalid_value",
            "max");
    refused("material.param.create", R"({"name":"1glow","type":"float"})", "invalid_value", "waveHeight");
    refused("material.texture.create", R"({"name":"noise"})", "invalid_value", "noiseMap");
    refused("material.texture.create", R"({"name":"dissolve"})", "already_exists", "namespace");
    // the message of a file error names the pointer
    auto r = p.call("material.param.create", R"({"name":"glow","type":"flaot"})");
    CHECK(r.error["message"].get<std::string>().find("/params/glow/type") != std::string::npos);
    // a material takes at most four textures: the fifth is refused with the pointer
    for (const char* n : {"t1", "t2", "t3", "t4", "t5"}) {
        Json a = Json::object({{"name", n}});
        auto t = p.call("material.texture.create", a);
        if (std::string(n) == "t5") {
            REQUIRE_FALSE(t.ok);
            CHECK(t.error["message"].get<std::string>().find("/textures") != std::string::npos);
        } else {
            REQUIRE_MESSAGE(t.ok, failure(t));
        }
    }
}

TEST_CASE("material.param.rename follows the nodes that read it, keeps the snippet in step and refuses bad names") {
    Project p;
    p.generate();
    REQUIRE(p.read(kSnippet).find("dissolve") != std::string::npos);

    const std::string before = p.read(kMat);
    auto dry = p.call("material.param.rename", R"({"name":"dissolve","newName":"burn","dryRun":true})");
    REQUIRE_MESSAGE(dry.ok, failure(dry));
    CHECK(dry.result["renamedNodes"] == Json::parse(R"(["amount"])"));
    CHECK(dry.result["written"] == false);
    CHECK(p.read(kMat) == before);

    auto r = p.call("material.param.rename", R"({"name":"dissolve","newName":"amountLeft"})");
    REQUIRE_MESSAGE(r.ok, failure(r));
    CHECK(r.result["renamedNodes"] == Json::parse(R"(["amount"])"));
    CHECK(r.result["snippet"]["regenerated"] == true);
    const Json doc = p.doc();
    CHECK_FALSE(doc["params"].contains("dissolve"));
    CHECK(doc["params"]["amountLeft"]["max"] == 1.0);
    CHECK(doc["graph"]["nodes"][1]["param"] == "amountLeft");
    CHECK(doc["graph"]["nodes"][0]["inputs"]["scale"] == 6.0);  // nothing else changed
    const std::string snippet = p.read(kSnippet);
    CHECK(snippet.find("amountLeft") != std::string::npos);
    CHECK(doc["graphHash"] == graph_snippet_hash(snippet));
    auto v = p.registry.call("material.graph.validate", Json::object({{"material", kMat}}));
    CHECK(v.result["snippet"]["state"] == "in_sync");

    // a graph held in memory is followed too (an unsaved node included), and never written
    Json graph = doc["graph"];
    graph["nodes"].push_back(Json::parse(R"({"id":"extra","type":"param","pos":[0,0],"param":"amountLeft"})"));
    auto back = p.call("material.param.rename",
                       Json::object({{"name", "amountLeft"}, {"newName", "dissolve"}, {"graph", graph}}));
    REQUIRE_MESSAGE(back.ok, failure(back));
    CHECK(back.result["graph"]["nodes"][4]["param"] == "dissolve");
    CHECK(back.result["graph"]["nodes"][1]["param"] == "dissolve");
    CHECK(back.result["renamedNodes"].size() == 2);
    CHECK(p.doc()["params"].contains("dissolve"));
    CHECK(p.doc()["graph"]["nodes"].size() == 4);

    // errors: unknown name (did you mean), taken, reserved, a GLSL word; nothing is written
    auto unknown = p.call("material.param.rename", R"({"name":"disolve","newName":"x"})");
    REQUIRE_FALSE(unknown.ok);
    CHECK(unknown.error["code"] == "not_found");
    CHECK(unknown.error["hint"].get<std::string>().find("dissolve") != std::string::npos);
    REQUIRE(p.call("material.param.create", R"({"name":"other","type":"float"})").ok);
    const std::string withOther = p.read(kMat);
    for (const char* bad : {"other", "gn_x", "float", "fa_x", "a b"}) {
        auto e = p.call("material.param.rename", Json::object({{"name", "dissolve"}, {"newName", bad}}));
        INFO(bad);
        REQUIRE_FALSE(e.ok);
        CHECK_FALSE(e.error["hint"].get<std::string>().empty());
        CHECK(p.read(kMat) == withOther);
    }
    // the same name again is not an error and writes nothing
    auto same = p.call("material.param.rename", R"({"name":"dissolve","newName":"dissolve"})");
    REQUIRE(same.ok);
    CHECK(same.result["written"] == false);
}

TEST_CASE("material.param.rename leaves a hand-edited snippet alone, and a texture rename follows its nodes") {
    Project p;
    p.generate();
    p.write(kSnippet, p.read(kSnippet) + "// my edit\n");
    const std::string edited = p.read(kSnippet);
    auto r = p.call("material.param.rename", R"({"name":"dissolve","newName":"fade"})");
    REQUIRE_MESSAGE(r.ok, failure(r));
    CHECK(r.result["snippet"]["regenerated"] == false);
    CHECK(r.result["snippet"]["state"] == "hand_edited");
    CHECK(p.read(kSnippet) == edited);
    CHECK(p.doc()["params"].contains("fade"));

    REQUIRE(p.call("material.texture.create", R"({"name":"maskMap"})").ok);
    Json doc = p.doc();
    doc["graph"]["nodes"].push_back(Json::parse(R"({"id":"mask","type":"texture","pos":[0,300],"texture":"maskMap"})"));
    p.write(kMat, doc.dump(2));
    auto rt = p.call("material.texture.rename", R"({"name":"maskMap","newName":"coverMap"})");
    REQUIRE_MESSAGE(rt.ok, failure(rt));
    CHECK(rt.result["renamedNodes"] == Json::parse(R"(["mask"])"));
    CHECK(p.doc()["graph"]["nodes"][4]["texture"] == "coverMap");
    CHECK(p.doc()["textures"].contains("coverMap"));
    // a param name is not a texture
    auto wrongKind = p.call("material.texture.rename", R"({"name":"fade","newName":"x"})");
    REQUIRE_FALSE(wrongKind.ok);
    CHECK(wrongKind.error["code"] == "not_found");
}

TEST_CASE("material.param.delete: an unused param goes, a used one is refused with its nodes unless forced") {
    Project p;
    REQUIRE(p.call("material.param.create", R"({"name":"spare","type":"vec2"})").ok);
    const std::string before = p.read(kMat);

    // used: refused with the node ids; nothing changes
    auto used = p.call("material.param.delete", R"({"name":"dissolve"})");
    REQUIRE_FALSE(used.ok);
    CHECK(used.error["code"] == "in_use");
    CHECK(used.error["data"]["nodes"] == Json::parse(R"(["amount"])"));
    CHECK(used.error["message"].get<std::string>().find("amount") != std::string::npos);
    CHECK(used.error["hint"].get<std::string>().find("force") != std::string::npos);
    CHECK(p.read(kMat) == before);

    // a node of the graph held in memory counts too
    Json graph = p.doc()["graph"];
    graph["nodes"].push_back(Json::parse(R"({"id":"s","type":"param","pos":[0,0],"param":"spare"})"));
    auto memUsed = p.call("material.param.delete", Json::object({{"name", "spare"}, {"graph", graph}}));
    REQUIRE_FALSE(memUsed.ok);
    CHECK(memUsed.error["data"]["nodes"] == Json::parse(R"(["s"])"));

    // unused: gone; `entry` takes it back
    auto gone = p.call("material.param.delete", R"({"name":"spare"})");
    REQUIRE_MESSAGE(gone.ok, failure(gone));
    CHECK(gone.result["removedNodes"].empty());
    CHECK_FALSE(p.doc()["params"].contains("spare"));
    Json again = Json::object({{"name", "spare"}});
    for (const char* k : {"type", "default", "doc"}) again[k] = gone.result["entry"][k];
    REQUIRE(p.call("material.param.create", again).ok);
    CHECK(p.doc()["params"]["spare"] == gone.result["entry"]);

    // forced: the nodes that read it and their links go; the snippet follows
    p.generate();
    auto forced = p.call("material.param.delete", R"({"name":"dissolve","force":true})");
    REQUIRE_MESSAGE(forced.ok, failure(forced));
    CHECK(forced.result["removedNodes"] == Json::parse(R"(["amount"])"));
    CHECK(forced.result["snippet"]["regenerated"] == true);
    const Json doc = p.doc();
    CHECK_FALSE(doc["params"].contains("dissolve"));
    CHECK(doc["graph"]["nodes"].size() == 3);
    CHECK(doc["graph"]["links"].size() == 3);
    for (const Json& l : doc["graph"]["links"]) CHECK(l["from"].get<std::string>().rfind("amount", 0) != 0);
    auto v = p.registry.call("material.graph.validate", Json::object({{"material", kMat}}));
    CHECK(v.result["snippet"]["state"] == "in_sync");

    // a missing name: did you mean; a texture the same way
    auto unknown = p.call("material.texture.delete", R"({"name":"nothing"})");
    REQUIRE_FALSE(unknown.ok);
    CHECK(unknown.error["code"] == "not_found");
    REQUIRE(p.call("material.texture.create", R"({"name":"maskMap"})").ok);
    p.generate();  // graphHash now follows "textures" in the file
    auto delTex = p.call("material.texture.delete", R"({"name":"maskMap"})");
    REQUIRE_MESSAGE(delTex.ok, failure(delTex));
    // the last one leaves the section empty where it was: a create afterwards does not add the key at the end of the file
    CHECK(p.doc()["textures"].empty());
    auto order = [&] {
        std::string keys;
        const Json d = p.doc();
        for (auto it = d.begin(); it != d.end(); ++it) keys += it.key() + " ";
        return keys;
    };
    const std::string keysBefore = order();
    REQUIRE(p.call("material.texture.create", R"({"name":"again"})").ok);
    CHECK(order() == keysBefore);
    CHECK(p.doc()["textures"].contains("again"));
}

TEST_CASE("material.param|texture.create takes an index, and delete returns the one to put the entry back at") {
    Project p;
    REQUIRE(p.call("material.param.create", R"({"name":"spare","type":"vec2"})").ok);
    REQUIRE(p.call("material.texture.create", R"({"name":"aMap"})").ok);
    REQUIRE(p.call("material.texture.create", R"({"name":"bMap"})").ok);
    REQUIRE(p.call("material.texture.create", R"({"name":"cMap"})").ok);
    auto keys = [&](const char* list) {
        const Json doc = p.doc();
        std::string out;
        for (auto it = doc[list].begin(); it != doc[list].end(); ++it) out += it.key() + " ";
        return out;
    };
    CHECK(keys("textures") == "aMap bMap cMap ");

    // delete in the middle, create it back with the entry and the index it returned: same order (the order is the slots)
    auto gone = p.call("material.texture.delete", R"({"name":"bMap"})");
    REQUIRE_MESSAGE(gone.ok, failure(gone));
    CHECK(gone.result["index"] == 1);
    CHECK(keys("textures") == "aMap cMap ");
    Json back = Json::object({{"name", "bMap"}, {"index", gone.result["index"]}});
    for (const char* k : {"default", "sampler", "doc"})
        if (gone.result["entry"].contains(k)) back[k] = gone.result["entry"][k];
    auto made = p.call("material.texture.create", back);
    REQUIRE_MESSAGE(made.ok, failure(made));
    CHECK(made.result["index"] == 1);
    CHECK(keys("textures") == "aMap bMap cMap ");

    // the same for params; 0 is first, past the end is last, none is the end
    auto first = p.call("material.param.create", R"({"name":"first","type":"float","index":0})");
    REQUIRE_MESSAGE(first.ok, failure(first));
    CHECK(keys("params") == "first dissolve spare ");
    auto last = p.call("material.param.create", R"({"name":"last","type":"float","index":99})");
    REQUIRE_MESSAGE(last.ok, failure(last));
    CHECK(last.result["index"] == 3);
    CHECK(keys("params") == "first dissolve spare last ");
    auto dry = p.call("material.param.create", R"({"name":"mid","type":"float","index":2,"dryRun":true})");
    REQUIRE_MESSAGE(dry.ok, failure(dry));
    CHECK(dry.result["index"] == 2);
    CHECK(keys("params") == "first dissolve spare last ");

    // a bad index is refused with the pointer and the fix; nothing is written
    for (const char* bad : {R"({"name":"x","type":"float","index":-1})", R"({"name":"x","type":"float","index":1.5})",
                            R"({"name":"x","type":"float","index":"1"})"}) {
        auto r = p.call("material.param.create", bad);
        INFO(bad);
        REQUIRE_FALSE(r.ok);
        // the input schema (integer, minimum 0) refuses it first; the command's own check says the same for a caller
        // that skips the schema
        CHECK((r.error["code"] == "invalid_arguments" || r.error["code"] == "invalid_argument"));
        CHECK(r.error.dump().find("index") != std::string::npos);
    }
    CHECK(keys("params") == "first dissolve spare last ");
}

TEST_CASE("material.param.create fixes a graph that reads a param the file does not declare") {
    Project p;
    Json doc = p.doc();
    doc.erase("params");
    p.write(kMat, doc.dump(2));
    // the graph is broken for every command that loads the file whole
    CHECK_FALSE(p.registry.call("material.graph.generate", Json::object({{"material", kMat}})).ok);
    auto made = p.call("material.param.create", R"({"name":"dissolve","type":"float"})");
    REQUIRE_MESSAGE(made.ok, failure(made));
    CHECK(made.result["written"] == true);
    p.generate();
    // a create that leaves the graph broken says what is wrong, and writes nothing
    p.write(kMat, doc.dump(2));
    const std::string before = p.read(kMat);
    auto other = p.call("material.param.create", R"({"name":"other","type":"float"})");
    REQUIRE_FALSE(other.ok);
    CHECK(other.error["message"].get<std::string>().find("/graph/nodes/1") != std::string::npos);
    CHECK(p.read(kMat) == before);
    // an error outside the graph is not tolerated
    Json broken = doc;
    broken["alphaMode"] = "nope";
    p.write(kMat, broken.dump(2));
    CHECK_FALSE(p.call("material.param.create", R"({"name":"dissolve","type":"float"})").ok);
}

TEST_CASE("material.param.rename and delete warn when a snippet they leave alone still uses the name") {
    Project p;
    p.generate();
    p.write(kSnippet, p.read(kSnippet) + "// my edit\n");
    auto r = p.call("material.param.rename", R"({"name":"dissolve","newName":"fade"})");
    REQUIRE_MESSAGE(r.ok, failure(r));
    REQUIRE(r.result["warnings"].size() == 1);
    CHECK(r.result["warnings"][0]["message"].get<std::string>().find("\"dissolve\"") != std::string::npos);
    CHECK(r.result["warnings"][0]["message"].get<std::string>().find(kSnippet) != std::string::npos);

    // a hand-written snippet that does not use the name: no warning; one that does: a warning on delete too
    Project q;
    Json doc = q.doc();
    doc.erase("graph");
    doc["params"]["spare"] = Json::parse(R"({"type":"float","default":0,"doc":"x."})");
    q.write(kMat, doc.dump(2));
    q.write(kSnippet, "void surface(in SurfaceInput i, inout Surface s) { s.albedo = vec3(spare); }\n");
    auto d = q.call("material.param.delete", R"({"name":"dissolve"})");
    REQUIRE_MESSAGE(d.ok, failure(d));
    CHECK(d.result["warnings"].empty());
    auto d2 = q.call("material.param.delete", R"({"name":"spare"})");
    REQUIRE_MESSAGE(d2.ok, failure(d2));
    CHECK(d2.result["snippet"]["state"] == "none");
    REQUIRE(d2.result["warnings"].size() == 1);
    const std::string warning = d2.result["warnings"][0]["message"].get<std::string>();
    CHECK(warning.find("hand-written snippet") != std::string::npos);
    CHECK(warning.find(kSnippet) != std::string::npos);
    CHECK(warning.find("\"spare\"") != std::string::npos);
    CHECK_FALSE(d2.result["warnings"][0]["hint"].get<std::string>().empty());
}

TEST_CASE("a graph that is null is an error with a pointer, not a hand-written snippet") {
    Project p;
    Json doc = p.doc();
    doc["graph"] = Json();
    p.write(kMat, doc.dump(2));
    const std::vector<std::pair<const char*, const char*>> calls = {
        {"material.graph.generate", "{}"},
        {"material.param.rename", R"({"name":"dissolve","newName":"x"})"},
        {"material.param.create", R"({"name":"x","type":"float"})"}};
    // the JSON pointer of the error, from the data the command returns (not from the wording of a sentence)
    auto points_at_graph = [](const CommandResult& r) {
        return r.error.is_object() && r.error.contains("data") && r.error["data"].is_object() &&
               r.error["data"].value("pointer", std::string()) == "/graph";
    };
    for (const auto& [name, args] : calls) {
        auto r = p.call(name, args);
        INFO(name);
        REQUIRE_FALSE(r.ok);
        INFO(r.error.dump());
        CHECK(r.error["code"] != "no_graph");
        CHECK(points_at_graph(r));
    }
    auto v = p.call("material.graph.validate", Json::object());
    REQUIRE(v.ok);
    CHECK(v.result["ok"] == false);
    CHECK(v.result["errors"][0]["pointer"] == "/graph");
    // the same for the `graph` argument
    Project q;
    auto g = q.call("material.graph.generate", Json::parse(R"({"graph":null})"));
    REQUIRE_FALSE(g.ok);
    INFO(g.error.dump());
    // the argument is checked by the command's input schema before the handler runs: its error names the argument, whatever its wording
    CHECK(g.error["code"] == "invalid_arguments");
    CHECK(g.error["message"].get<std::string>().find("graph") != std::string::npos);
}

TEST_CASE("a bare number for a vecN constant of a graph is refused with the form, a float input takes one") {
    Project p;
    Json graph = p.doc()["graph"];
    graph["nodes"][3]["inputs"]["albedo"] = 0.5;
    auto v = p.registry.call("material.graph.validate", Json::object({{"material", kMat}, {"graph", graph}}));
    REQUIRE(v.ok);
    REQUIRE(v.result["errors"].size() == 1);
    CHECK(v.result["errors"][0]["pointer"] == "/graph/nodes/3/inputs/albedo");
    CHECK(v.result["errors"][0]["message"].get<std::string>().find("an array of 3 numbers") != std::string::npos);
    CHECK(v.result["errors"][0]["hint"].get<std::string>().find("[1.0, 0.5, 0.0]") != std::string::npos);
    graph["nodes"][3]["inputs"]["albedo"] = Json::parse("[0.5, 0.5, 0.5]");
    graph["nodes"][3]["inputs"]["roughness"] = 0.5;
    auto ok = p.registry.call("material.graph.validate", Json::object({{"material", kMat}, {"graph", graph}}));
    CHECK(ok.result["ok"] == true);
}

TEST_CASE("material paths: ..x is inside the project, ../x is not; shader.compile says to generate a missing snippet") {
    Project p;
    CHECK(p.registry.call("material.graph.validate", Json::object({{"material", "materials/dissolve"}})).ok);
    for (const char* bad : {"../x.material.json", "a/../../x.material.json", "/abs/x.material.json"}) {
        auto r = p.registry.call("material.graph.validate", Json::object({{"material", bad}}));
        INFO(bad);
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "invalid_argument");
    }
    p.write("..x.material.json", p.read(kMat));
    auto dots = p.registry.call("material.graph.validate", Json::object({{"material", "..x.material.json"}}));
    CHECK_MESSAGE(dots.ok, failure(dots));

    CommandRegistry shaders;
    register_shader_commands(shaders, p.dir.str());
    auto missing = shaders.call("shader.compile", Json::object({{"material", kMat}}));
    REQUIRE_FALSE(missing.ok);
    CHECK(missing.error["hint"].get<std::string>().find("material.graph.generate") != std::string::npos);
    CHECK(material_snippet_state(p.dir.str(), kMat) == "missing");
    p.generate();
    CHECK(material_snippet_state(p.dir.str(), kMat) == "in_sync");
    Json doc = p.doc();
    doc["graph"]["nodes"][3]["inputs"]["roughness"] = 0.9;
    p.write(kMat, doc.dump(2));
    CHECK(material_snippet_state(p.dir.str(), kMat) == "graph_changed");
    doc.erase("graph");
    doc.erase("graphHash");
    p.write(kMat, doc.dump(2));
    CHECK(material_snippet_state(p.dir.str(), kMat).empty());
}

TEST_CASE("a material path of the wrong shape is refused the same on every OS") {
    Project p;
    CommandRegistry shaders;
    register_shader_commands(shaders, p.dir.str());
    // "c:x" is a drive path to Windows only by the host's own path rules: refused on POSIX too, with the shape named
    for (const char* bad :
         {"c:x.material.json", "C:/x.material.json", "materials\\dissolve.material.json", "~/x.material.json"}) {
        for (const char* name : {"shader.compile", "material.info"}) {
            auto r = shaders.call(name, Json::object({{"material", bad}}));
            INFO(name << " " << bad);
            REQUIRE_FALSE(r.ok);
            CHECK(r.error["code"] == "invalid_argument");
        }
        auto g = p.registry.call("material.graph.validate", Json::object({{"material", bad}}));
        INFO(bad);
        REQUIRE_FALSE(g.ok);
        CHECK(g.error["code"] == "invalid_argument");
    }
    CHECK(shaders_detail::material_path_shape_problem("materials/dissolve.material.json").empty());
    CHECK(shaders_detail::material_path_shape_problem("..x.material.json").empty());
    CHECK(shaders_detail::material_path_shape_problem("~tmp.material.json").empty());
    CHECK_FALSE(shaders_detail::material_path_shape_problem("a/../x.material.json").empty());
}

TEST_CASE("a snippet that is there and cannot be read is 'unreadable', never 'does not exist yet'") {
    Project p;
    // a folder in the place of the file: a read fails on every OS (no permission tricks, which a root user ignores)
    stdfs::create_directories(p.dir.path / kSnippet);
    CHECK(material_snippet_state(p.dir.str(), kMat) == "unreadable");
    auto v = p.registry.call("material.graph.validate", Json::object({{"material", kMat}}));
    REQUIRE_MESSAGE(v.ok, failure(v));
    CHECK(v.result["snippet"]["state"] == "unreadable");
    const std::string why = v.result["snippet"]["error"].get<std::string>();
    CHECK(why.find(kSnippet) != std::string::npos);
    CHECK(why.find("folder") != std::string::npos);
    auto g = p.registry.call("material.graph.generate", Json::object({{"material", kMat}, {"force", true}}));
    REQUIRE_FALSE(g.ok);
    CHECK(g.error["message"].get<std::string>().find("cannot read the snippet") != std::string::npos);
    CHECK(stdfs::is_directory(p.dir.path / kSnippet));  // nothing replaced it
}

TEST_CASE("validate without sokol-shdc still warns of a changed graph and reports a missing or unreadable snippet") {
    Project p;
    SetupContext noTool;  // no SOKOL_SHDC, no PATH, a home without tools: the compiler is not found
    noTool.env = [](const std::string&) { return std::string(); };
    noTool.home = p.dir.str();
    noTool.host = "linux";

    ValidationReport missing;
    validate_materials(p.dir.str(), noTool, missing);
    REQUIRE_FALSE(missing.errors.empty());
    CHECK(missing.errors[0].hint.find("material.graph.generate") != std::string::npos);

    p.generate();
    Json doc = p.doc();
    doc["graph"]["nodes"][3]["inputs"]["roughness"] = 0.9;
    p.write(kMat, doc.dump(2));
    ValidationReport changed;
    validate_materials(p.dir.str(), noTool, changed);
    const auto w = std::find_if(changed.warnings.begin(), changed.warnings.end(),
                                [](const ValidationIssue& i) { return i.pointer == "/graph"; });
    REQUIRE(w != changed.warnings.end());
    CHECK(w->hint.find("material.graph.generate") != std::string::npos);
    // (an unreadable snippet takes the same branch as a missing one; whether a folder in its place fails to read is up to the OS, so it has no case here)
}
