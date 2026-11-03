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
    REQUIRE(catalog["operations"].size() == 46);
    CHECK(catalog["operations"][0]["op"] == "box");
    // the modifiers are in the catalogue with their children, ranges and defaults
    const Json* array = nullptr;
    const Json* lathe = nullptr;
    for (const Json& op : catalog["operations"]) {
        if (op["op"] == "array") array = &op;
        if (op["op"] == "lathe") lathe = &op;
    }
    REQUIRE(array);
    CHECK((*array)["kind"] == "modifier");
    bool countOk = false, childrenOk = false;
    for (const Json& f : (*array)["fields"]) {
        if (f["key"] == "count") countOk = f["min"] == 1 && f["max"] == 4096 && f["default"] == 2;
        if (f["key"] == "children") childrenOk = f.contains("doc");
    }
    CHECK(countOk);
    CHECK(childrenOk);
    REQUIRE(lathe);
    CHECK((*lathe)["kind"] == "primitive");
    bool profileOk = false;
    for (const Json& f : (*lathe)["fields"])
        if (f["key"] == "profile") profileOk = f["type"] == "points2" && f["minItems"] == 2 && f["maxItems"] == 256 && f["required"] == true;
    CHECK(profileOk);
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

TEST_CASE("model.create, model.edit and model.bake: modifiers wrap children, take edits by id and bake a closed .glb") {
    AssetsProject p;
    const std::string path = "assets/models/gear.model.json";
    const Json created = p.ok("model.create", {{"path", path},
                                               {"nodes", Json::array({{{"op", "boolean"}, {"id", "cut"}, {"mode", "difference"},
                                                                       {"children", Json::array({{{"op", "cylinder"}, {"id", "disc"}, {"radius", 1}, {"height", 0.3}},
                                                                                                 {{"op", "cylinder"}, {"id", "bore"}, {"radius", 0.3}, {"height", 1}}})}}})}});
    CHECK(created["nodeCount"] == 3);
    CHECK(created["tree"][0]["op"] == "boolean");
    CHECK(created["measurements"]["closed"] == true);
    const double bored = created["measurements"]["volume"].get<double>();

    // edit a child by id: the whole document is checked and the .glb baked again
    p.ok("model.edit", {{"path", path}, {"op", "set"}, {"target", "bore"}, {"values", {{"radius", 0.5}}}});
    const Json after = p.ok("model.info", {{"path", path}});
    CHECK(after["measurements"]["volume"].get<double>() < bored);
    CHECK(after["measurements"]["closed"] == true);

    // add into a modifier, and wrap an existing node by adding a modifier on top
    const Json add = p.ok("model.edit", {{"path", path}, {"op", "add"}, {"parent", "cut"}, {"node", {{"op", "box"}, {"size", {0.1, 0.1, 1}}, {"position", {0.8, 0, 0}}}}});
    CHECK(add["edit"]["pointer"] == "/nodes/0/children/2");
    p.ok("model.edit", {{"path", path}, {"op", "add"}, {"node", {{"op", "radial_array"}, {"id", "ring"}, {"count", 3}, {"children", Json::array({{{"op", "sphere"}, {"position", {2, 0, 0}}}})}}}});
    const Json built = p.ok("model.info", {{"path", path}});
    CHECK(built["valid"] == true);
    CHECK(built["measurements"]["closed"] == true);

    // mistakes in a modifier come back with the pointer and did-you-mean, and nothing is written
    const std::string before = read_all(p.file(path));
    auto bad = p.call("model.edit", {{"path", path}, {"op", "set"}, {"target", "ring"}, {"values", {{"count", 0}, {"axiss", "y"}}}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error.dump().find("/nodes/1/count") != std::string::npos);
    CHECK(bad.error.dump().find("axis") != std::string::npos);
    CHECK(read_all(p.file(path)) == before);

    // a boolean of something that is not a solid: the document is valid and kept, the bake says which operand and why
    const Json open = p.ok("model.edit", {{"path", path}, {"op", "add"}, {"parent", "cut"}, {"node", {{"op", "grid"}, {"id", "sheet"}}}});
    CHECK(open["bake"]["state"] == "failed");
    CHECK(open["bake"]["message"].get<std::string>().find("not a closed solid") != std::string::npos);
    CHECK(open["bake"]["message"].get<std::string>().find("/nodes/0/children/3") != std::string::npos);
    p.ok("model.edit", {{"path", path}, {"op", "remove"}, {"target", "sheet"}});

    // a primitive is not a place to add children
    auto notParent = p.call("model.edit", {{"path", path}, {"op", "add"}, {"parent", "disc"}, {"node", {{"op", "box"}}}});
    CHECK_FALSE(notParent.ok);

    // the bake is the same twice
    p.ok("model.bake", {{"path", path}, {"force", true}});
    const std::string glb = read_all(p.file("assets/models/gear.glb"));
    p.ok("model.bake", {{"path", path}, {"force", true}});
    CHECK(read_all(p.file("assets/models/gear.glb")) == glb);
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

TEST_CASE("model.create, model.edit and model.bake: an sdf node melts shapes into a closed .glb, takes edits by id and teaches on a misplaced shape") {
    AssetsProject p;
    const std::string path = "assets/models/rock.model.json";
    const Json created = p.ok("model.create", {{"path", path},
                                               {"materials", {{"stone", {{"color", {0.5, 0.5, 0.5, 1}}}}}},
                                               {"nodes", Json::array({{{"op", "sdf"}, {"id", "rock"}, {"quality", "draft"}, {"noiseAmplitude", 0.05}, {"noiseSeed", 3}, {"align", "bottom"},
                                                                       {"children", Json::array({{{"op", "sdf_ellipsoid"}, {"id", "base"}, {"radii", {0.8, 0.5, 0.6}}, {"material", "stone"}},
                                                                                                 {{"op", "sdf_sphere"}, {"id", "lump"}, {"radius", 0.4}, {"position", {0.5, 0.3, 0}}, {"smooth", 0.2}, {"material", "stone"}}})}}})}});
    CHECK(created["nodeCount"] == 3);
    CHECK(created["tree"][0]["op"] == "sdf");
    CHECK(created["measurements"]["closed"] == true);
    CHECK(created["measurements"]["bounds"]["min"][1].get<double>() == doctest::Approx(0.0).epsilon(0.001));
    const double before = created["measurements"]["volume"].get<double>();

    // an edit by id rebuilds the .glb: the lump grows and so does the volume
    p.ok("model.edit", {{"path", path}, {"op", "set"}, {"target", "lump"}, {"values", {{"radius", 0.6}}}});
    const Json bigger = p.ok("model.info", {{"path", path}});
    CHECK(bigger["measurements"]["volume"].get<double>() > before);
    CHECK(bigger["measurements"]["closed"] == true);

    // add a shape into the sdf and a group of shapes into it; a cut is a shape with blend "subtract"
    const Json add = p.ok("model.edit", {{"path", path}, {"op", "add"}, {"parent", "rock"},
                                         {"node", {{"op", "sdf_group"}, {"id", "pits"}, {"blend", "subtract"}, {"smooth", 0.05}, {"mirror", "z"},
                                                   {"children", Json::array({{{"op", "sdf_sphere"}, {"radius", 0.15}, {"position", {0.2, 0.4, 0.3}}}})}}}});
    CHECK(add["edit"]["pointer"] == "/nodes/0/children/2");
    const Json pitted = p.ok("model.info", {{"path", path}});
    CHECK(pitted["valid"] == true);
    CHECK(pitted["measurements"]["closed"] == true);
    CHECK(pitted["measurements"]["volume"].get<double>() < bigger["measurements"]["volume"].get<double>());

    // a shape outside an sdf, and a mesh inside one, are refused with the pointer and the way out; nothing is written
    const std::string saved = read_all(p.file(path));
    auto outside = p.call("model.edit", {{"path", path}, {"op", "add"}, {"node", {{"op", "sdf_sphere"}}}});
    REQUIRE_FALSE(outside.ok);
    CHECK(outside.error.dump().find("works only inside") != std::string::npos);
    auto inside = p.call("model.edit", {{"path", path}, {"op", "add"}, {"parent", "rock"}, {"node", {{"op", "box"}}}});
    REQUIRE_FALSE(inside.ok);
    CHECK(inside.error.dump().find("cannot go inside") != std::string::npos);
    CHECK(read_all(p.file(path)) == saved);

    // a modifier wraps the sdf and a boolean takes it as an operand
    p.ok("model.edit", {{"path", path}, {"op", "add"}, {"node", {{"op", "mirror"}, {"id", "twin"}, {"axis", "x"}, {"children", Json::array({{{"op", "sdf"}, {"quality", "draft"}, {"position", {2, 0, 0}},
                                                                                                                                      {"children", Json::array({{{"op", "sdf_sphere"}, {"radius", 0.5}}})}}})}}}});
    CHECK(p.ok("model.info", {{"path", path}})["measurements"]["closed"] == true);

    // the bake is the same twice
    p.ok("model.bake", {{"path", path}, {"force", true}});
    const std::string glb = read_all(p.file("assets/models/rock.glb"));
    REQUIRE(glb.size() > 100);
    p.ok("model.bake", {{"path", path}, {"force", true}});
    CHECK(read_all(p.file("assets/models/rock.glb")) == glb);
}

TEST_CASE("model.info: the catalogue lists the sdf shapes with their kind and the ranges the checker uses") {
    AssetsProject p;
    const Json catalog = p.ok("model.info", {});
    const Json* sdf = nullptr;
    const Json* sphere = nullptr;
    for (const Json& op : catalog["operations"]) {
        if (op["op"] == "sdf") sdf = &op;
        if (op["op"] == "sdf_sphere") sphere = &op;
    }
    REQUIRE(sdf);
    REQUIRE(sphere);
    CHECK((*sdf)["kind"] == "sdf");
    CHECK((*sphere)["kind"] == "sdf_shape");
    bool qualityOk = false, blendOk = false;
    for (const Json& f : (*sdf)["fields"])
        if (f["key"] == "quality") qualityOk = f["default"] == "normal" && f["choices"].size() == 4;
    for (const Json& f : (*sphere)["fields"])
        if (f["key"] == "blend") blendOk = f["default"] == "union" && f["choices"].size() == 3;
    CHECK(qualityOk);
    CHECK(blendOk);
}

TEST_CASE("docs/MODELING.md: every sdf example is a valid document that builds a closed surface") {
    namespace stdfs = std::filesystem;
    const std::string text = read_all(stdfs::path(FA_REPO_ROOT) / "docs" / "MODELING.md");
    int found = 0;
    for (std::size_t at = text.find("```json\n"); at != std::string::npos; at = text.find("```json\n", at + 1)) {
        const std::size_t begin = at + 8, end = text.find("```", begin);
        REQUIRE(end != std::string::npos);
        const std::string block = text.substr(begin, end - begin);
        if (block.find("\"op\": \"sdf\"") == std::string::npos) continue;
        ++found;
        auto json = parse_json(block, "MODELING.md");
        REQUIRE_MESSAGE(json.ok(), (json.ok() ? std::string() : json.error().to_string()));
        auto doc = parse_model_doc(*json, "MODELING.md");
        REQUIRE_MESSAGE(doc.ok(), (doc.ok() ? std::string() : doc.error().to_string()));
        auto build = evaluate_model(*doc);
        REQUIRE_MESSAGE(build.ok(), (build.ok() ? std::string() : build.error().to_string()));
        CHECK_MESSAGE(build->stats.closed(), block.substr(0, 120));
        CHECK(build->warnings.empty());
        CHECK(build->stats.triangles > 100);
    }
    CHECK(found == 4);  // the creature, the rock, the tree and the mushroom
}

TEST_CASE("model.select: tries a query on the mesh a node receives; model.info lists the queries and what each edit node selected") {
    AssetsProject p;
    const Json catalog = p.ok("model.info", {});
    REQUIRE(catalog.contains("selections"));
    bool normal = false, loop = false;
    for (const Json& q : catalog["selections"]["queries"]["faces"])
        if (q["by"] == "normal") normal = !q["doc"].get<std::string>().empty();
    for (const Json& q : catalog["selections"]["queries"]["edges"])
        if (q["by"] == "loop") loop = !q["doc"].get<std::string>().empty();
    CHECK(normal);
    CHECK(loop);

    const Json doc = Json::object(
        {{"format", "factoria.model/1"},
         {"nodes", Json::array({{{"op", "extrude_faces"}, {"id", "bump"}, {"distance", 0.2}, {"newPart", "bump"}, {"faces", {{"by", "normal"}, {"direction", "top"}}},
                                 {"children", Json::array({{{"op", "box"}, {"id", "base"}, {"part", "body"}}})}}})}});
    p.ok("model.create", {{"path", "assets/models/crate.model.json"}, {"nodes", doc["nodes"]}});

    // on the primitive's mesh, with a query of the call, and with the edit node's own selection
    const Json top = p.ok("model.select", {{"path", "assets/models/crate.model.json"}, {"node", "base"}, {"faces", {{"by", "normal"}, {"direction", "top"}}}});
    CHECK(top["matched"] == 2);
    CHECK(top["total"] == 12);
    CHECK(top["area"].get<double>() == doctest::Approx(1.0));
    CHECK(top["parts"][0]["part"] == "body");
    CHECK(top["bounds"]["max"][1].get<double>() == doctest::Approx(0.5));
    const Json own = p.ok("model.select", {{"path", "assets/models/crate.model.json"}, {"node", "bump"}});
    CHECK(own["matched"] == 2);

    // nothing matched: a warning that teaches, not an error
    const Json none = p.ok("model.select", {{"path", "assets/models/crate.model.json"}, {"node", "base"}, {"faces", {{"by", "part"}, {"part", "bodi"}}}});
    CHECK(none["matched"] == 0);
    REQUIRE(none.contains("warnings"));
    CHECK(contains(none["warnings"], "body"));

    // errors teach
    auto wrong = p.call("model.select", {{"path", "assets/models/crate.model.json"}, {"node", "base"}, {"faces", {{"by", "nromal"}}}});
    REQUIRE_FALSE(wrong.ok);
    CHECK(contains(wrong.error, "normal"));
    auto missing = p.call("model.select", {{"path", "assets/models/crate.model.json"}, {"node", "bas"}, {"faces", {{"by", "all"}}}});
    REQUIRE_FALSE(missing.ok);
    CHECK(contains(missing.error, "base"));

    // model.info of a document lists what each edit node selected
    const Json info = p.ok("model.info", {{"path", "assets/models/crate.model.json"}});
    REQUIRE(info["measurements"].contains("edits"));
    CHECK(info["measurements"]["edits"][0]["matched"] == 2);
    CHECK(info["measurements"]["edits"][0]["op"] == "extrude_faces");
    CHECK(info["measurements"]["closed"] == true);
}

TEST_CASE("docs/MODELING.md: every example of Selections and edits is a valid document that builds a closed surface without warnings") {
    namespace stdfs = std::filesystem;
    const std::string text = read_all(stdfs::path(FA_REPO_ROOT) / "docs" / "MODELING.md");
    const std::size_t from = text.find("## Selections and edits");
    REQUIRE(from != std::string::npos);
    const std::size_t to = text.find("\n## ", from + 5);
    REQUIRE(to != std::string::npos);
    const std::string section = text.substr(from, to - from);
    int found = 0;
    for (std::size_t at = section.find("```json\n"); at != std::string::npos; at = section.find("```json\n", at + 1)) {
        const std::size_t begin = at + 8, end = section.find("```", begin);
        REQUIRE(end != std::string::npos);
        const std::string block = section.substr(begin, end - begin);
        ++found;
        auto json = parse_json(block, "MODELING.md");
        REQUIRE_MESSAGE(json.ok(), (json.ok() ? std::string() : json.error().to_string()));
        auto doc = parse_model_doc(*json, "MODELING.md");
        REQUIRE_MESSAGE(doc.ok(), (doc.ok() ? block.substr(0, 80) : doc.error().to_string()));
        auto build = evaluate_model(*doc);
        REQUIRE_MESSAGE(build.ok(), (build.ok() ? std::string() : build.error().to_string()));
        CHECK_MESSAGE(build->stats.closed(), block.substr(0, 120));
        CHECK_MESSAGE(build->warnings.empty(), block.substr(0, 120));
        CHECK(!build->edits.empty());
        for (const ModelSelectionReport& r : build->edits) CHECK_MESSAGE(r.matched > 0, block.substr(0, 120));
    }
    CHECK(found == 4);  // the button, the rim, the belt and the recess
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
        {"op": "stairs", "steps": 5}, {"op": "arch"}, {"op": "pipe"}, {"op": "text", "text": "A"},
        {"op": "mirror", "axis": "x", "children": [{"op": "lathe", "profile": [[0.2, 0], [0.4, 1]]}]},
        {"op": "boolean", "mode": "intersection", "children": [{"op": "box"}, {"op": "sphere"}]},
        {"op": "sdf", "quality": "fine", "align": "bottom", "children": [{"op": "sdf_group", "mirror": "x", "children": [{"op": "sdf_capsule"}, {"op": "sdf_torus", "blend": "subtract"}]}]}]}]})", "nested");
    CHECK(validate_json(*schema, nested).empty());
    Json broken = *sample;
    broken["nodes"][0]["op"] = "cube";
    CHECK_FALSE(validate_json(*schema, broken).empty());
    broken = *sample;
    broken["nodes"][0]["sise"] = 1;
    CHECK_FALSE(validate_json(*schema, broken).empty());
}

// ---- model.uv ---------------------------------------------------------------------------------------------------

namespace {

const char* kCrate = R"({"format": "factoria.model/1", "doc": "a crate with a barrel on it",
    "materials": {"wood": {"color": [0.55, 0.35, 0.2, 1]}},
    "nodes": [
        {"op": "box", "id": "crate", "size": [1, 1, 1], "part": "crate", "material": "wood"},
        {"op": "cylinder", "id": "barrel", "radius": 0.3, "height": 0.8, "position": [0, 0.9, 0], "part": "barrel", "material": "wood"}]})";
const char* kCratePath = "assets/models/crate.model.json";

}  // namespace

TEST_CASE("model.uv: a document with no uv section is measured on the primitives' own uvs and nothing is written") {
    AssetsProject p;
    write_all(p.file(kCratePath), kCrate);
    const std::string before = read_all(p.file(kCratePath));
    const Json r = p.ok("model.uv", {{"path", kCratePath}});
    CHECK(r["changed"] == false);
    CHECK(r["uv"].is_null());
    CHECK(r["source"].get<std::string>().find("primitives' own uvs") != std::string::npos);
    CHECK(r["report"]["triangles"].get<int>() > 0);
    CHECK(r["report"]["parts"].size() == 2);
    CHECK(read_all(p.file(kCratePath)) == before);
    CHECK_FALSE(p.exists("assets/models/crate.glb"));  // an unchanged document is not baked by a measurement
    REQUIRE(r.contains("$image"));
    CHECK(r["$image"]["mimeType"] == "image/png");
    CHECK(r["$image"]["temporary"] == true);
    CHECK(std::filesystem::exists(r["$image"]["path"].get<std::string>()));
    CHECK(read_all(r["$image"]["path"].get<std::string>()).substr(1, 3) == "PNG");
    CHECK_FALSE(p.ok("model.uv", {{"path", kCratePath}, {"picture", false}}).contains("$image"));
}

TEST_CASE("model.uv: set writes the section, bakes the .glb with the uvs and measures them; set merges, replace replaces, clear removes") {
    AssetsProject p;
    write_all(p.file(kCratePath), kCrate);
    const Json r = p.ok("model.uv", {{"path", kCratePath}, {"set", {{"method", "unwrap"}, {"texelsPerUnit", 256}}}});
    CHECK(r["changed"] == true);
    CHECK(r["uv"]["method"] == "unwrap");
    CHECK(r["uv"]["texelsPerUnit"] == 256);
    CHECK(r["bake"]["state"] == "baked");
    CHECK(p.exists("assets/models/crate.glb"));
    CHECK(r["report"]["texelsPerUnit"] == 256);
    CHECK(r["report"]["overlap"].get<double>() < 0.001);
    CHECK(r["report"]["flippedTriangles"] == 0);
    CHECK(r["report"]["utilization"].get<double>() > 0.2);
    CHECK(r["report"]["texelsPerMeter"]["mean"].get<double>() > 200);
    CHECK(r["report"]["texelsPerMeter"]["mean"].get<double>() < 300);
    CHECK(r["report"]["textureSize"].get<int>() >= 512);
    const Json saved = parse_json(read_all(p.file(kCratePath)), "doc").value();
    CHECK(saved["uv"]["method"] == "unwrap");
    CHECK(saved["nodes"].size() == 2);  // the rest of the document is untouched

    // a merge keeps what is not named; a null removes a field; a part merges field by field
    const Json m = p.ok("model.uv", {{"path", kCratePath},
                                      {"set", {{"seams", "many"}, {"parts", {{"barrel", {{"method", "cylinder"}, {"axis", "y"}}}}}}},
                                      {"picture", false}});
    CHECK(m["uv"]["method"] == "unwrap");
    CHECK(m["uv"]["texelsPerUnit"] == 256);
    CHECK(m["uv"]["seams"] == "many");
    CHECK(m["uv"]["parts"]["barrel"]["method"] == "cylinder");
    bool cylinder = false;
    for (const Json& part : m["report"]["parts"]) cylinder = cylinder || (part["part"] == "barrel" && part["method"] == "cylinder");
    CHECK(cylinder);
    const Json n = p.ok("model.uv", {{"path", kCratePath}, {"set", {{"texelsPerUnit", nullptr}, {"parts", {{"barrel", {{"axis", nullptr}}}}}}}, {"picture", false}});
    CHECK_FALSE(n["uv"].contains("texelsPerUnit"));
    CHECK(n["uv"]["parts"]["barrel"]["method"] == "cylinder");
    CHECK_FALSE(n["uv"]["parts"]["barrel"].contains("axis"));
    const Json same = p.ok("model.uv", {{"path", kCratePath}, {"set", {{"seams", "many"}}}, {"picture", false}});
    CHECK(same["changed"] == false);

    const Json rep = p.ok("model.uv", {{"path", kCratePath}, {"set", {{"method", "box"}}}, {"replace", true}, {"picture", false}});
    CHECK(rep["uv"]["method"] == "box");
    CHECK(rep["uv"]["seams"] == "balanced");  // the settings come back with their defaults filled in
    CHECK_FALSE(rep["uv"].contains("parts"));

    const Json cleared = p.ok("model.uv", {{"path", kCratePath}, {"clear", true}, {"picture", false}});
    CHECK(cleared["changed"] == true);
    CHECK(cleared["uv"].is_null());
    CHECK_FALSE(parse_json(read_all(p.file(kCratePath)), "doc").value().contains("uv"));
}

TEST_CASE("model.uv: bake false leaves the .glb stale; the tile layout and a mistake that writes nothing and teaches") {
    AssetsProject p;
    write_all(p.file(kCratePath), kCrate);
    p.ok("model.bake", {});
    const std::string glb = read_all(p.file("assets/models/crate.glb"));
    const Json r = p.ok("model.uv", {{"path", kCratePath}, {"set", {{"layout", "tile"}, {"texelsPerUnit", 64}, {"textureSize", 512}}}, {"bake", false}, {"picture", false}});
    CHECK(r["report"]["layout"] == "tile");
    CHECK(r["bake"]["state"] == "stale");
    CHECK(read_all(p.file("assets/models/crate.glb")) == glb);
    CHECK(p.ok("model.uv", {{"path", kCratePath}, {"set", {{"method", "box"}}}, {"picture", false}})["bake"]["state"] == "baked");

    const std::string before = read_all(p.file(kCratePath));
    CommandResult bad = p.call("model.uv", {{"path", kCratePath}, {"set", {{"method", "unwarp"}, {"padding", 99}, {"parts", {{"barell", {{"method", "box"}}}}}}}});
    CHECK_FALSE(bad.ok);
    CHECK(bad.error["code"] == "invalid_document");
    const Json issues = bad.error["data"]["issues"];
    REQUIRE(issues.size() >= 2);
    CHECK(issues[0]["pointer"].get<std::string>().rfind("/uv/", 0) == 0);
    CHECK(read_all(p.file(kCratePath)) == before);

    // a tile layout cannot unwrap: the evaluation says so
    CommandResult tileUnwrap = p.call("model.uv", {{"path", kCratePath}, {"set", {{"layout", "tile"}, {"method", "unwrap"}}}});
    CHECK_FALSE(tileUnwrap.ok);
    CHECK(tileUnwrap.error.dump().find("cannot use") != std::string::npos);
    CHECK(tileUnwrap.error.dump().find("Nothing was written.") != std::string::npos);

    CHECK_FALSE(p.call("model.uv", {{"path", kCratePath}, {"set", {{"method", "box"}}}, {"clear", true}}).ok);
    CHECK_FALSE(p.call("model.uv", {{"path", kCratePath}, {"replace", true}}).ok);
    CHECK_FALSE(p.call("model.uv", {{"path", "assets/models/nope.model.json"}}).ok);
    CHECK_FALSE(p.call("model.uv", {{"path", "assets/models/crate.glb"}}).ok);
    CHECK_FALSE(p.call("model.uv", {{"path", kCratePath}, {"colour", 1}}).ok);

    // an unknown part name is a warning of the build, not an error
    const Json warn = p.ok("model.uv", {{"path", kCratePath}, {"set", {{"parts", {{"barell", {{"method", "box"}}}}}}}, {"picture", false}});
    bool did = false;
    for (const Json& w : warn["warnings"]) did = did || w.get<std::string>().find("barrel") != std::string::npos;
    CHECK(did);
}

TEST_CASE("model.uv: the texel density comes from assets.json style.texelsPerUnit and the .glb goes stale when the style changes it") {
    AssetsProject p;
    auto set_style = [&](const Json& density) {
        Json m = p.exists("assets.json") ? p.manifest() : Json({{"format", "factoria.assets/1"}});
        if (density.is_null()) m.erase("style");
        else m["style"] = Json::object({{"texelsPerUnit", density}});
        write_all(p.file("assets.json"), m.dump(2) + "\n");
    };
    auto glb_state = [&]() {
        const Json r = p.ok("assets.regenerate", {{"path", "assets/models/crate.glb"}, {"dryRun", true}});
        return r["wouldRun"].empty() ? Json(false) : r["wouldRun"][0]["stale"];
    };
    write_all(p.file(kCratePath), kCrate);
    p.ok("model.bake", {});  // creates the manifest
    set_style(64);
    p.ok("model.uv", {{"path", kCratePath}, {"set", {{"method", "unwrap"}}}, {"picture", false}});
    const Json r = p.ok("model.uv", {{"path", kCratePath}, {"picture", false}});
    CHECK(r["report"]["texelsPerUnit"] == 64);
    CHECK(r["report"]["texelsPerMeter"]["mean"].get<double>() < 80);
    CHECK(r["styleTexelsPerUnit"] == 64);
    CHECK(glb_state() == false);
    set_style(128);
    CHECK(glb_state() == true);
    p.ok("assets.regenerate", {{"stale", true}});
    CHECK(glb_state() == false);
    CHECK(p.ok("model.uv", {{"path", kCratePath}, {"picture", false}})["report"]["texelsPerMeter"]["mean"].get<double>() > 110);
    // a density of the section's own does not depend on the style
    p.ok("model.uv", {{"path", kCratePath}, {"set", {{"texelsPerUnit", 200}}}, {"picture", false}});
    set_style(32);
    CHECK(glb_state() == false);
    CHECK(p.ok("model.uv", {{"path", kCratePath}, {"picture", false}})["report"]["texelsPerMeter"]["mean"].get<double>() > 170);
}

TEST_CASE("model.create and model.edit: the uv section can be given with the document and replaced through the document operation") {
    AssetsProject p;
    const Json r = p.ok("model.create", {{"path", "assets/models/box.model.json"}, {"nodes", Json::array({{{"op", "box"}}})}, {"uv", {{"method", "unwrap"}, {"texelsPerUnit", 64}}}});
    CHECK(r["measurements"]["uv"]["layout"] == "atlas");
    CHECK(r["measurements"]["uv"]["charts"].get<int>() >= 1);
    CHECK(parse_json(read_all(p.file("assets/models/box.model.json")), "doc").value()["uv"]["texelsPerUnit"] == 64);
    const Json info = p.ok("model.info", {{"path", "assets/models/box.model.json"}});
    CHECK(info["measurements"]["uv"]["layout"] == "atlas");
    const Json edited = p.ok("model.edit", {{"path", "assets/models/box.model.json"}, {"op", "document"}, {"uv", {{"layout", "tile"}}}});
    CHECK(edited["measurements"]["uv"]["layout"] == "tile");
    CHECK(p.ok("model.edit", {{"path", "assets/models/box.model.json"}, {"op", "document"}, {"uv", nullptr}})["measurements"].contains("uv") == false);
}

TEST_CASE("model.game_ready: settings go into the document, the bake writes LODs, the collider and a prefab, and fewer LODs remove the old files") {
    AssetsProject p;
    write_all(p.file("assets/models/ball.model.json"),
              R"({"format": "factoria.model/1", "nodes": [{"op": "sphere", "id": "s", "radius": 0.5, "position": [0, 2, 0], "part": "ball"}]})");
    // no settings: a report, nothing written
    const Json report = p.ok("model.game_ready", {{"path", "assets/models/ball.model.json"}});
    CHECK(report.contains("report"));
    CHECK_FALSE(p.exists("assets/models/ball.glb"));

    const Json r = p.ok("model.game_ready", {{"path", "assets/models/ball.model.json"}, {"origin", "bottom_center"},
                                             {"lods", Json::array({{{"ratio", 0.5}}, {{"ratio", 0.2}}})}, {"collider", {{"shape", "convex"}}}});
    CHECK(r["gameReady"].contains("lods"));
    CHECK(r["extras"].size() == 4);
    for (const char* f : {"ball.glb", "ball.lod1.glb", "ball.lod2.glb", "ball.collider.glb", "ball.prefab.json"}) CHECK(p.exists(std::string("assets/models/") + f));
    const Json prefab = parse_json(read_all(p.file("assets/models/ball.prefab.json")), "prefab").value();
    CHECK(prefab["format"] == "factoria.prefab/1");
    CHECK(prefab["entity"]["components"]["MeshRenderer"]["lods"].size() == 2);
    CHECK(prefab["entity"]["components"]["Collider3D"]["shape"] == "convex");
    const Json doc = parse_json(read_all(p.file("assets/models/ball.model.json")), "doc").value();
    CHECK(doc["gameReady"]["origin"] == "bottom_center");
    CHECK(p.manifest()["assets"].contains("assets/models/ball.lod2.glb"));
    CHECK(model_bake_status(p.dir, "assets/models/ball.model.json").state == ModelBakeState::Fresh);

    // a LOD file that is gone makes the document's bake missing
    std::filesystem::remove(p.file("assets/models/ball.lod1.glb"));
    CHECK(model_bake_status(p.dir, "assets/models/ball.model.json").state == ModelBakeState::Missing);
    p.ok("model.bake", {{"path", "assets/models/ball.model.json"}});
    CHECK(p.exists("assets/models/ball.lod1.glb"));

    // one LOD less: its file and manifest entry go
    p.ok("model.game_ready", {{"path", "assets/models/ball.model.json"}, {"lods", Json::array({{{"ratio", 0.5}}})}});
    CHECK_FALSE(p.exists("assets/models/ball.lod2.glb"));
    CHECK_FALSE(p.manifest()["assets"].contains("assets/models/ball.lod2.glb"));
    // the same settings, the same bytes
    const std::string lod1 = read_all(p.file("assets/models/ball.lod1.glb"));
    p.ok("model.bake", {{"path", "assets/models/ball.model.json"}, {"force", true}});
    CHECK(read_all(p.file("assets/models/ball.lod1.glb")) == lod1);

    // a bad setting teaches and writes nothing
    const std::string before = read_all(p.file("assets/models/ball.model.json"));
    CHECK_FALSE(p.call("model.game_ready", {{"path", "assets/models/ball.model.json"}, {"collider", {{"shape", "convx"}}}}).ok);
    CHECK(read_all(p.file("assets/models/ball.model.json")) == before);
    // clear
    p.ok("model.game_ready", {{"path", "assets/models/ball.model.json"}, {"clear", true}});
    CHECK_FALSE(p.exists("assets/models/ball.lod1.glb"));
    CHECK_FALSE(p.exists("assets/models/ball.prefab.json"));
}
