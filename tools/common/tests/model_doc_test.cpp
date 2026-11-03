// model.info, model.bake, model.create and model.edit: model documents as project files (docs/MODELING.md). The format, the kernel and the
// evaluator are tested in fa_scene (engine/scene/tests/test_model_doc.cpp, test_model_kernel.cpp); here: the files, the recipe, staleness,
// validation, the editing commands and their errors.
#include <doctest.h>

#include <cstdlib>
#include <fstream>

#include "asset_test_helpers.h"
#include "fa/core/json_schema.h"
#include "fa/scene/model_doc.h"
#include "fa/tooling/model_bake.h"
#include "fa/tooling/validate.h"
#include "fa_test_paths.h"

using namespace fa;
using namespace fa::testing;

namespace {

Json recipe_of_entry(const AssetsProject& p, const std::string& rel) { return p.manifest()["assets"][rel]["provenance"]["recipe"]; }

const char* kDoor = R"({"format": "factoria.model/1", "doc": "test door",
    "materials": {"wood": {"color": [0.55, 0.35, 0.2, 1]}, "brass": {"color": [0.8, 0.65, 0.3, 1], "metallic": 1}},
    "nodes": [
        {"op": "box", "id": "panel", "size": [1, 2, 0.08], "part": "door", "material": "wood"},
        {"op": "sphere", "id": "knob", "radius": 0.05, "position": [0.4, 0, 0.07], "part": "knob", "material": "brass"}]})";

bool contains(const Json& j, const std::string& needle) { return j.dump().find(needle) != std::string::npos; }

}  // namespace

TEST_CASE("model.create: writes the document, bakes the .glb, records provenance and a recipe, and gives every node an id") {
    AssetsProject p;
    const Json r = p.ok("model.create", {{"path", "assets/models/crate.model.json"},
                                         {"nodes", Json::array({{{"op", "box"}}, {{"op", "box"}, {"position", {0, 1, 0}}}, {{"op", "cylinder"}}})}});
    CHECK(r["output"] == "assets/models/crate.glb");
    CHECK(r["nodeCount"] == 3);
    CHECK(r["tree"][0]["id"] == "box_1");
    CHECK(r["tree"][1]["id"] == "box_2");
    CHECK(r["tree"][2]["id"] == "cylinder_1");
    CHECK(r["measurements"]["triangles"].get<int>() > 0);
    CHECK(r["provenance"]["provider"] == "factoria model.bake");

    const std::string glb = read_all(p.file("assets/models/crate.glb"));
    REQUIRE(glb.size() > 20);
    CHECK(glb.substr(0, 4) == "glTF");
    const Json saved = parse_json(read_all(p.file("assets/models/crate.model.json")), "doc").value();
    CHECK(saved["format"] == "factoria.model/1");
    CHECK(saved["nodes"][2]["id"] == "cylinder_1");

    const Json prov = p.manifest()["assets"]["assets/models/crate.glb"]["provenance"];
    CHECK(prov["kind"] == "model3d");
    CHECK(prov["source"] == "assets/models/crate.model.json");
    const Json recipe = recipe_of_entry(p, "assets/models/crate.glb");
    CHECK(recipe["command"] == "model.bake");
    CHECK(recipe["args"]["path"] == "assets/models/crate.model.json");
    REQUIRE(recipe["inputs"].size() == 1);
    CHECK(recipe["inputs"][0]["path"] == "assets/models/crate.model.json");

    auto again = p.call("model.create", {{"path", "assets/models/crate.model.json"}});
    CHECK_FALSE(again.ok);
    CHECK(again.error.dump().find("overwrite") != std::string::npos);
    CHECK(read_all(p.file("assets/models/crate.model.json")) == dump_json(saved));
    // the default is one box
    const Json def = p.ok("model.create", {{"path", "assets/models/one.model.json"}, {"bake", false}});
    CHECK(def["nodeCount"] == 1);
    CHECK(def["tree"][0]["op"] == "box");
    CHECK(def["bake"]["state"] == "missing");
    CHECK_FALSE(p.exists("assets/models/one.glb"));
}

TEST_CASE("model.create: a document with mistakes lists every issue with its pointer and writes nothing") {
    AssetsProject p;
    auto bad = p.call("model.create", {{"path", "assets/models/bad.model.json"},
                                       {"nodes", Json::array({{{"op", "cilinder"}}, {{"op", "box"}, {"sise", {1, 1, 1}}}, {{"op", "sphere"}, {"radius", -1}}})}});
    REQUIRE_FALSE(bad.ok);
    const std::string text = bad.error.dump();
    CHECK(text.find("cylinder") != std::string::npos);  // did you mean
    CHECK(text.find("/nodes/0") != std::string::npos);
    CHECK(text.find("size") != std::string::npos);
    CHECK(text.find("/nodes/2/radius") != std::string::npos);
    CHECK_FALSE(p.exists("assets/models/bad.model.json"));

    auto outside = p.call("model.create", {{"path", "models/x.model.json"}});
    CHECK_FALSE(outside.ok);
    auto suffix = p.call("model.create", {{"path", "assets/models/x.json"}});
    CHECK_FALSE(suffix.ok);
    auto typo = p.call("model.create", {{"path", "assets/models/x.model.json"}, {"nods", 1}});
    CHECK_FALSE(typo.ok);
}

TEST_CASE("model.bake: bakes missing documents, skips fresh ones, dryRun writes nothing, the same bytes come out again") {
    AssetsProject p;
    write_all(p.file("assets/models/door.model.json"), kDoor);
    const Json plan = p.ok("model.bake", {{"dryRun", true}});
    REQUIRE(plan["wouldBake"].size() == 1);
    CHECK(plan["wouldBake"][0]["reason"] == "missing");
    CHECK_FALSE(p.exists("assets/models/door.glb"));

    const Json r = p.ok("model.bake", {});
    REQUIRE(r["count"] == 1);
    CHECK(r["baked"][0]["out"] == "assets/models/door.glb");
    const Json& m = r["baked"][0]["measurements"];
    REQUIRE(m["parts"].size() == 2);
    CHECK(m["parts"][0]["part"] == "door");
    CHECK(m["parts"][0]["material"] == "wood");
    CHECK(m["parts"][1]["part"] == "knob");
    CHECK(m["bounds"]["size"][1].get<double>() == doctest::Approx(2.0).epsilon(0.001));
    CHECK(m["closed"] == true);

    const std::string glb = read_all(p.file("assets/models/door.glb"));
    CHECK(glb.find("\"part\":\"door\"") != std::string::npos);
    CHECK(glb.find("\"part\":\"knob\"") != std::string::npos);
    CHECK(glb.find("brass") != std::string::npos);

    const Json second = p.ok("model.bake", {});
    CHECK(second["count"] == 0);
    CHECK(second["unchanged"].size() == 1);
    CHECK(p.ok("model.bake", {{"path", "assets/models/door.model.json"}, {"force", true}})["count"] == 1);
    CHECK(read_all(p.file("assets/models/door.glb")) == glb);
}

TEST_CASE("model.bake: output.path moves the .glb; a file nothing baked is never replaced unless overwrite") {
    AssetsProject p;
    write_all(p.file("assets/models/door.model.json"),
              R"({"format": "factoria.model/1", "output": {"path": "assets/baked/door.glb"}, "nodes": [{"op": "box"}]})");
    p.ok("model.bake", {});
    CHECK(p.exists("assets/baked/door.glb"));
    CHECK_FALSE(p.exists("assets/models/door.glb"));

    write_all(p.file("assets/models/other.model.json"), R"({"format": "factoria.model/1", "nodes": [{"op": "box"}]})");
    write_all(p.file("assets/models/other.glb"), "not mine");
    const Json all = p.ok("model.bake", {});
    REQUIRE(all.contains("failed"));
    CHECK(all["failed"][0]["error"]["message"].get<std::string>().find("already exists") != std::string::npos);
    CHECK(read_all(p.file("assets/models/other.glb")) == "not mine");
    auto single = p.call("model.bake", {{"path", "assets/models/other.model.json"}});
    CHECK_FALSE(single.ok);
    CHECK(single.error.dump().find("overwrite") != std::string::npos);
    CHECK(read_all(p.file("assets/models/other.glb")) == "not mine");
    p.ok("model.bake", {{"path", "assets/models/other.model.json"}, {"overwrite", true}});
    CHECK(read_all(p.file("assets/models/other.glb")).substr(0, 4) == "glTF");
}

TEST_CASE("model.bake: a changed document makes the .glb stale; validate warns, regenerate and bake build it again") {
    AssetsProject p;
    write_all(p.file("assets/models/door.model.json"), kDoor);
    p.ok("model.bake", {});
    const std::string first = read_all(p.file("assets/models/door.glb"));
    CHECK(p.ok("assets.regenerate", {{"stale", true}})["count"] == 0);
    CHECK(p.ok("model.info", {{"path", "assets/models/door.model.json"}})["bake"]["state"] == "fresh");

    std::string changed = kDoor;
    changed.replace(changed.find("\"radius\": 0.05"), 14, "\"radius\": 0.09");
    write_all(p.file("assets/models/door.model.json"), changed);
    CHECK(p.ok("model.info", {{"path", "assets/models/door.model.json"}})["bake"]["state"] == "stale");
    bool warned = false;
    for (const ValidationIssue& w : validate_project(p.dir).warnings) warned = warned || w.message.find("'assets/models/door.glb' is stale") != std::string::npos;
    CHECK(warned);
    const Json plan = p.ok("model.bake", {{"dryRun", true}});
    REQUIRE(plan["wouldBake"].size() == 1);
    CHECK(plan["wouldBake"][0]["reason"] == "stale");
    CHECK(read_all(p.file("assets/models/door.glb")) == first);
    CHECK(p.ok("assets.regenerate", {{"stale", true}})["count"] == 1);
    const std::string second = read_all(p.file("assets/models/door.glb"));
    CHECK(second != first);
    CHECK(p.ok("model.bake", {})["count"] == 0);

    // the bake before an export
    write_all(p.file("assets/models/door.model.json"), changed + " ");
    CHECK(model_bake_status(p.dir, "assets/models/door.model.json").state == ModelBakeState::Stale);
    auto baked = bake_model_documents_if_needed(p.dir);
    REQUIRE(baked.ok());
    CHECK(baked->size() == 1);
    CHECK(bake_model_documents_if_needed(p.dir)->empty());
    CHECK(read_all(p.file("assets/models/door.glb")) == second);
}

TEST_CASE("project.validate: a model document with mistakes is an error per issue; a document not baked yet is a warning") {
    AssetsProject p;
    write_all(p.file("assets/models/a.model.json"), R"({"format": "factoria.model/1", "nodes": [{"op": "box"}]})");
    write_all(p.file("assets/models/bad.model.json"), R"({"format": "factoria.model/1", "nodes": [{"op": "box", "size": -1}, {"op": "ball"}]})");
    const ValidationReport v = validate_project(p.dir);
    int pointers = 0;
    for (const ValidationIssue& e : v.errors)
        if (e.file == "assets/models/bad.model.json" && !e.pointer.empty()) ++pointers;
    CHECK(pointers >= 2);
    bool notBaked = false;
    for (const ValidationIssue& w : v.warnings) notBaked = notBaked || (w.file == "assets/models/a.model.json" && w.message.find("Not baked") != std::string::npos);
    CHECK(notBaked);
}

TEST_CASE("model.info: with no arguments lists the operations; with a document checks and measures it, and reports every issue of a broken one") {
    AssetsProject p;
    const Json catalog = p.ok("model.info", {});
    REQUIRE(catalog["operations"].size() == 13);
    CHECK(catalog["operations"][0]["op"] == "box");
    CHECK(catalog["operations"][0]["fields"][0].contains("doc"));
    CHECK(catalog["commonFields"].size() > 8);

    write_all(p.file("assets/models/door.model.json"), kDoor);
    const Json info = p.ok("model.info", {{"path", "assets/models/door.model.json"}});
    CHECK(info["valid"] == true);
    CHECK(info["nodeCount"] == 2);
    CHECK(info["output"] == "assets/models/door.glb");
    CHECK(info["bake"]["state"] == "missing");
    CHECK(info["measurements"]["triangles"].get<int>() > 100);
    CHECK_FALSE(p.exists("assets/models/door.glb"));
    CHECK_FALSE(p.ok("model.info", {{"path", "assets/models/door.model.json"}, {"evaluate", false}}).contains("measurements"));

    const Json inlineDoc = p.ok("model.info", {{"document", {{"nodes", Json::array({{{"op", "torus"}}})}}}});
    CHECK(inlineDoc["valid"] == true);
    CHECK(inlineDoc["measurements"]["closed"] == true);

    write_all(p.file("assets/models/bad.model.json"), R"({"format": "factoria.model/1", "nodes": [{"op": "box", "sise": [1, 1, 1]}, {"op": "capsul"}]})");
    const Json bad = p.ok("model.info", {{"path", "assets/models/bad.model.json"}});
    CHECK(bad["valid"] == false);
    REQUIRE(bad["issues"].size() == 2);
    CHECK(bad["issues"][0]["pointer"] == "/nodes/0/sise");
    CHECK(contains(bad["issues"][0], "size"));
    CHECK(contains(bad["issues"][1], "capsule"));

    auto missing = p.call("model.info", {{"path", "assets/models/nope.model.json"}});
    CHECK_FALSE(missing.ok);
    CHECK(missing.error.dump().find("door.model.json") != std::string::npos);
    auto both = p.call("model.info", {{"path", "assets/models/door.model.json"}, {"document", Json::object()}});
    CHECK_FALSE(both.ok);
    auto typo = p.call("model.info", {{"pth", "x"}});
    CHECK_FALSE(typo.ok);
}

TEST_CASE("model.edit: add, set, remove, move and document change one node by id, check the whole document and rebuild the .glb") {
    AssetsProject p;
    write_all(p.file("assets/models/door.model.json"), kDoor);
    p.ok("model.bake", {});
    const std::string first = read_all(p.file("assets/models/door.glb"));
    const std::string path = "assets/models/door.model.json";

    // set: a field by id, and a null value removes it
    const Json set = p.ok("model.edit", {{"path", path}, {"op", "set"}, {"target", "knob"}, {"values", {{"radius", 0.09}}}});
    CHECK(set["edit"]["op"] == "set");
    CHECK(parse_json(read_all(p.file(path)), "d").value()["nodes"][1]["radius"] == 0.09);
    CHECK(read_all(p.file("assets/models/door.glb")) != first);
    p.ok("model.edit", {{"path", path}, {"op", "set"}, {"target", "knob"}, {"values", {{"radius", nullptr}}}});
    CHECK_FALSE(parse_json(read_all(p.file(path)), "d").value()["nodes"][1].contains("radius"));

    // add: into a group, with an auto id; then by index
    p.ok("model.edit", {{"path", path}, {"op", "add"}, {"node", {{"op", "group"}, {"id", "hinges"}, {"children", Json::array()}}}});
    const Json add = p.ok("model.edit", {{"path", path}, {"op", "add"}, {"parent", "hinges"}, {"node", {{"op", "cylinder"}, {"radius", 0.03}}}});
    CHECK(add["edit"]["id"] == "cylinder_1");
    CHECK(add["edit"]["pointer"] == "/nodes/2/children/0");
    CHECK(add["nodeCount"] == 4);
    p.ok("model.edit", {{"path", path}, {"op", "add"}, {"index", 0}, {"node", {{"op", "box"}, {"id", "base"}}}});
    CHECK(parse_json(read_all(p.file(path)), "d").value()["nodes"][0]["id"] == "base");

    // move: out of the group to the top level
    p.ok("model.edit", {{"path", path}, {"op", "move"}, {"target", "cylinder_1"}, {"index", 1}});
    Json doc = parse_json(read_all(p.file(path)), "d").value();
    CHECK(doc["nodes"][1]["id"] == "cylinder_1");
    CHECK(doc["nodes"][4]["children"].empty());
    auto into = p.call("model.edit", {{"path", path}, {"op", "move"}, {"target", "hinges"}, {"parent", "hinges"}});
    CHECK_FALSE(into.ok);

    // remove, and the id is gone
    p.ok("model.edit", {{"path", path}, {"op", "remove"}, {"target", "base"}});
    doc = parse_json(read_all(p.file(path)), "d").value();
    CHECK(doc["nodes"].size() == 4);
    CHECK(doc["nodes"][0]["id"] == "cylinder_1");

    // document: materials
    p.ok("model.edit", {{"path", path}, {"op", "document"}, {"doc", "a door"}, {"materials", {{"wood", {{"color", {1, 0, 0, 1}}}}, {"brass", Json::object()}}}});
    doc = parse_json(read_all(p.file(path)), "d").value();
    CHECK(doc["doc"] == "a door");
    CHECK(doc["materials"]["wood"]["color"][0] == 1);
}

TEST_CASE("model.edit: a bad edit writes nothing and teaches; an unknown id suggests the ones that exist") {
    AssetsProject p;
    write_all(p.file("assets/models/door.model.json"), kDoor);
    const std::string path = "assets/models/door.model.json";
    const std::string before = read_all(p.file(path));

    auto bad = p.call("model.edit", {{"path", path}, {"op", "set"}, {"target", "knob"}, {"values", {{"radius", -2}, {"raduis", 1}}}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error.dump().find("/nodes/1/radius") != std::string::npos);
    CHECK(bad.error.dump().find("radius") != std::string::npos);
    CHECK(read_all(p.file(path)) == before);

    auto unknown = p.call("model.edit", {{"path", path}, {"op", "set"}, {"target", "knb"}, {"values", {{"radius", 1}}}});
    REQUIRE_FALSE(unknown.ok);
    CHECK(unknown.error.dump().find("knob") != std::string::npos);
    CHECK(read_all(p.file(path)) == before);

    auto op = p.call("model.edit", {{"path", path}, {"op", "ad"}, {"node", {{"op", "box"}}}});
    REQUIRE_FALSE(op.ok);
    CHECK(op.error.dump().find("add") != std::string::npos);
    auto matt = p.call("model.edit", {{"path", path}, {"op", "set"}, {"target", "knob"}, {"values", {{"material", "gold"}}}});
    REQUIRE_FALSE(matt.ok);
    CHECK(matt.error.dump().find("brass") != std::string::npos);
    auto range = p.call("model.edit", {{"path", path}, {"op", "add"}, {"index", 9}, {"node", {{"op", "box"}}}});
    CHECK_FALSE(range.ok);
    auto notGroup = p.call("model.edit", {{"path", path}, {"op", "add"}, {"parent", "knob"}, {"node", {{"op", "box"}}}});
    CHECK_FALSE(notGroup.ok);
    auto opChange = p.call("model.edit", {{"path", path}, {"op", "set"}, {"target", "knob"}, {"values", {{"op", "box"}}}});
    CHECK_FALSE(opChange.ok);
    auto missing = p.call("model.edit", {{"path", "assets/models/nope.model.json"}, {"op", "remove"}, {"target", "x"}});
    CHECK_FALSE(missing.ok);
    CHECK(read_all(p.file(path)) == before);
}

TEST_CASE("model.bake: a text node reads the engine's own font; the bake is deterministic and the document stays a plain recipe") {
    AssetsProject p;
    write_all(p.file("assets/models/sign.model.json"),
              R"({"format": "factoria.model/1", "nodes": [{"op": "text", "id": "label", "text": "Hi", "size": 0.5, "depth": 0.1}]})");
    const Json r = p.ok("model.bake", {});
    REQUIRE(r["count"] == 1);
    CHECK(r["baked"][0]["measurements"]["triangles"].get<int>() > 20);
    const std::string glb = read_all(p.file("assets/models/sign.glb"));
    p.ok("model.bake", {{"path", "assets/models/sign.model.json"}, {"force", true}});
    CHECK(read_all(p.file("assets/models/sign.glb")) == glb);
    // the built-in font is data of the engine, not a project file: the only input is the document
    CHECK(recipe_of_entry(p, "assets/models/sign.glb")["inputs"].size() == 1);
}

TEST_CASE("model schema: schemas/model.schema.json is the schema the catalog builds, and valid documents pass it") {
    namespace stdfs = std::filesystem;
    const stdfs::path file = stdfs::path(FA_REPO_ROOT) / "schemas" / "model.schema.json";
    const Json built = model_doc_schema();
    if (const char* regenerate = std::getenv("FA_REGENERATE_MODEL_SCHEMA"); regenerate && std::string(regenerate) == "1") {
        std::ofstream out(file, std::ios::binary);
        out << built.dump(2) << "\n";
    }
    auto schema = parse_json(read_all(file), "model.schema.json");
    REQUIRE(schema.ok());
    CHECK_MESSAGE(*schema == built, "schemas/model.schema.json is out of date: run the tests with FA_REGENERATE_MODEL_SCHEMA=1 to write it again");
    for (const ModelOpInfo& op : model_ops()) CHECK((*schema)["$defs"].contains(op.op));

    auto sample = parse_json(kDoor, "door");
    REQUIRE(sample.ok());
    CHECK(validate_json(*schema, *sample).empty());
    Json nested = *parse_json(R"({"format": "factoria.model/1", "nodes": [{"op": "group", "position": [1, 0, 0], "children": [
        {"op": "stairs", "steps": 5}, {"op": "arch"}, {"op": "pipe"}, {"op": "text", "text": "A"}]}]})", "nested");
    CHECK(validate_json(*schema, nested).empty());
    Json broken = *sample;
    broken["nodes"][0]["op"] = "cube";
    CHECK_FALSE(validate_json(*schema, broken).empty());
    broken = *sample;
    broken["nodes"][0]["sise"] = 1;
    CHECK_FALSE(validate_json(*schema, broken).empty());
}
