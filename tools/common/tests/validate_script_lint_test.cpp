// factoria validate against the engine's API: imported names, members of imported objects, literal component names,
// project.* calls that an export breaks, a top level that throws, and colour arrays that mix scales.
#include <doctest.h>

#include <filesystem>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/serialize.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/tooling.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

ValidationReport validate_with_engine(const std::string& dir) {
    const stdfs::path savedRoot = fs::project_root();
    EngineConfig cfg;
    cfg.projectDir = dir;
    cfg.headless = true;
    cfg.graphics = false;
    cfg.audioDevice = false;
    cfg.hotReload = false;
    cfg.memoryStorage = true;
    Engine engine;
    std::string err;
    REQUIRE_MESSAGE(engine.init(cfg, nullptr, &err), err);
    ValidationReport report = validate_project(dir, engine_validate_options(engine));
    engine.shutdown();
    fs::set_project_root(savedRoot);
    return report;
}

const ValidationIssue* find_issue(const std::vector<ValidationIssue>& list, const std::string& needle) {
    for (const ValidationIssue& i : list)
        if (i.to_string().find(needle) != std::string::npos) return &i;
    return nullptr;
}

std::string make_game(testing::TempDir& tmp) {
    const std::string dir = tmp.sub("game");
    REQUIRE(create_project(dir, "2d-empty").ok());
    return dir;
}

void write_script(const std::string& dir, const char* rel, const std::string& text) {
    testing::write_all(stdfs::path(dir) / rel, text);
}

}  // namespace

TEST_CASE("validate scripts: a name imported from factoria that does not exist is an error with line, column and a "
          "suggestion") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    write_script(dir, "scripts/bad.js",
                 "import { Behaviour, wrold } from \"factoria\";\nexport default class Bad extends Behaviour {\n  "
                 "onStart() { wrold.find(\"x\"); }\n}\n");
    write_script(dir, "scripts/good.js",
                 "import { Behaviour, world } from \"factoria\";\nexport default class Good extends Behaviour {\n  "
                 "onStart() { world.find(\"x\"); }\n}\n");
    const ValidationReport r = validate_with_engine(dir);
    const ValidationIssue* e = find_issue(r.errors, "scripts/bad.js:1:21");
    REQUIRE(e != nullptr);
    CHECK(e->message.find("does not export 'wrold'") != std::string::npos);
    CHECK(e->hint.find("world") != std::string::npos);
    CHECK(find_issue(r.errors, "scripts/good.js") == nullptr);
    CHECK_FALSE(r.ok);
}

TEST_CASE("validate scripts: a member the engine's object does not have is an error; a local of the same name is left "
          "alone") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    write_script(
        dir, "scripts/members.js",
        "import { Behaviour, physics } from \"factoria\";\nimport * as f from \"factoria\";\n"
        "export default class M extends Behaviour {\n  onStart() {\n    physics.raycats({x: 0, y: 0}, {x: 1, y: 0});\n"
        "    f.wrold;\n    physics.raycast({x: 0, y: 0}, {x: 1, y: 0});\n  }\n}\n");
    write_script(dir, "scripts/shadow.js",
                 "import { Behaviour, physics } from \"factoria\";\nexport default class S extends Behaviour {\n"
                 "  onStart() { this.use({ nothing: 1 }); }\n  use(physics) { return physics.nothing; }\n}\n");
    const ValidationReport r = validate_with_engine(dir);
    for (const ValidationIssue& i : r.errors) MESSAGE("error: " << i.to_string());
    const ValidationIssue* e = find_issue(r.errors, "scripts/members.js:5:13");
    REQUIRE(e != nullptr);
    CHECK(e->message.find("'physics.raycats'") != std::string::npos);
    CHECK(e->hint.find("raycast") != std::string::npos);
    CHECK(find_issue(r.errors, "scripts/members.js:6:7") != nullptr);  // f.wrold
    CHECK(find_issue(r.errors, "scripts/members.js:7") == nullptr);    // the real member
    CHECK(find_issue(r.errors, "scripts/shadow.js") == nullptr);
}

TEST_CASE("validate scripts: literal component names are warnings; the exact name and unrelated gets are not") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    write_script(dir, "scripts/comps.js",
                 "import { Behaviour } from \"factoria\";\nexport default class C extends Behaviour {\n  onStart() {\n"
                 "    this.entity.get(\"Transfrom\");\n    this.entity.has(\"transform\");\n    "
                 "this.entity.get(\"Transform\");\n"
                 "    const cache = new Map();\n    cache.get(\"Hero\");\n    this.entity.get(\"speed\");\n  }\n}\n");
    const ValidationReport r = validate_with_engine(dir);
    for (const ValidationIssue& i : r.warnings) MESSAGE("warning: " << i.to_string());
    CHECK(r.ok);  // warnings only
    const ValidationIssue* typo = find_issue(r.warnings, "scripts/comps.js:4:21");
    REQUIRE(typo != nullptr);
    CHECK(typo->hint.find("Transform") != std::string::npos);
    const ValidationIssue* ci = find_issue(r.warnings, "scripts/comps.js:5:21");
    REQUIRE(ci != nullptr);
    CHECK(ci->message.find("'Transform'") != std::string::npos);
    CHECK(find_issue(r.warnings, "scripts/comps.js:6") == nullptr);
    CHECK(find_issue(r.warnings, "scripts/comps.js:8") == nullptr);
    CHECK(find_issue(r.warnings, "scripts/comps.js:9") == nullptr);
}

TEST_CASE("validate scripts: a game script that calls a command of a tool warns with its line, like the export") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    write_script(dir, "tools/scatter.js",
                 "export default { name: \"scatter\", summary: \"x\", run() { return {}; } };\n");
    write_script(dir, "scripts/uses.js",
                 "import { Behaviour, fa } from \"factoria\";\nexport default class U extends Behaviour {\n"
                 "  onStart() {\n    fa.call(\"project.scatter\", {});\n    fa.call(\"scene.list\");\n  }\n}\n");
    const ValidationReport r = validate_with_engine(dir);
    const ValidationIssue* w =
        find_issue(r.warnings, "scripts/uses.js:4 calls project.scatter, the command of tools/scatter.js");
    REQUIRE(w != nullptr);
    CHECK(r.ok);
    CHECK(find_issue(r.warnings, "scene.list") == nullptr);
}

TEST_CASE("validate scripts: a module whose top level throws is an error with the file and line of the throw, once") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    write_script(dir, "scripts/boom.js", "export const x = 1;\nthrow new Error(\"top level failed\");\n");
    for (const char* name : {"a", "b"})
        write_script(dir, (std::string("scripts/") + name + ".js").c_str(),
                     "import { Behaviour } from \"factoria\";\nimport { x } from \"./boom.js\";\n"
                     "export default class A extends Behaviour { onStart() { x; } }\n");
    const ValidationReport r = validate_with_engine(dir);
    for (const ValidationIssue& i : r.errors) MESSAGE("error: " << i.to_string());
    CHECK_FALSE(r.ok);
    int boom = 0;
    for (const ValidationIssue& i : r.errors)
        if (i.message.find("top level failed") != std::string::npos) {
            ++boom;
            CHECK(i.file == "scripts/boom.js");
            CHECK(i.message.find("scripts/boom.js:2") != std::string::npos);
        }
    CHECK(boom == 1);  // the two importers share the problem
}

TEST_CASE("validate scripts: a colour that mixes 0..1 and 0..255 warns with the pointer and both readings") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    auto scene = load_json_file(dir + "/scenes/main.scene.json");
    REQUIRE(scene.ok());
    (*scene)["entities"].push_back(
        Json::parse(R"({"id": "a", "components": {"Shape2D": {"size": [1, 1], "color": [255, 255, 255, 1]}}})"));
    (*scene)["entities"].push_back(
        Json::parse(R"({"id": "b", "components": {"Shape2D": {"size": [1, 1], "color": [255, 128, 0, 255]}}})"));
    (*scene)["entities"].push_back(
        Json::parse(R"({"id": "c", "components": {"Shape2D": {"size": [1, 1], "color": [1, 0.5, 0, 1]}}})"));
    REQUIRE(save_scene_json_file(dir + "/scenes/main.scene.json", *scene).ok());
    const ValidationReport r = validate_project(dir);
    int mixed = 0;
    for (const ValidationIssue& w : r.warnings)
        if (w.message.find("mixes channels over 1") != std::string::npos) {
            ++mixed;
            CHECK(w.pointer.find("/color") != std::string::npos);
            CHECK(w.message.find("0.004") != std::string::npos);  // 1/255, the 0..255 reading of the alpha
            CHECK(w.message.find("[255, 255, 255, 1]") != std::string::npos);
        }
    CHECK(mixed == 1);  // [255, 128, 0, 255] and [1, 0.5, 0, 1] are fine
    Color c;
    std::string err;
    CHECK_FALSE(json_to(Json::parse("[1, 2]"), c, &err));
    CHECK(err.find("0..255 when any channel is over 1") != std::string::npos);
}

TEST_CASE(
    "validate scripts: an emissive colour over 1 warns that it is read as 0..255 and points to emissiveStrength") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    auto scene = load_json_file(dir + "/scenes/main.scene.json");
    REQUIRE(scene.ok());
    (*scene)["entities"].push_back(
        Json::parse(R"({"id": "mixed", "components": {"MeshRenderer": {"emissive": [1.5, 1, 0.4, 1]}}})"));
    (*scene)["entities"].push_back(
        Json::parse(R"({"id": "dark", "components": {"MeshRenderer": {"emissive": [2, 2, 2]}}})"));
    (*scene)["entities"].push_back(Json::parse(
        R"({"id": "fine", "components": {"MeshRenderer": {"emissive": [1, 0.8, 0.4, 1], "emissiveStrength": 3}}})"));
    (*scene)["entities"].push_back(
        Json::parse(R"({"id": "bytes", "components": {"MeshRenderer": {"emissive": [255, 200, 100]}}})"));
    (*scene)["entities"].push_back(
        Json::parse(R"({"id": "shape", "components": {"Shape2D": {"size": [1, 1], "color": [2, 2, 2]}}})"));
    REQUIRE(save_scene_json_file(dir + "/scenes/main.scene.json", *scene).ok());
    const ValidationReport r = validate_project(dir);
    int emissiveWarnings = 0, shapeWarnings = 0;
    for (const ValidationIssue& w : r.warnings) {
        if (w.pointer.find("/MeshRenderer/emissive") != std::string::npos) {
            ++emissiveWarnings;
            CHECK(w.message.find("0..255") != std::string::npos);
            CHECK(w.message.find("MeshRenderer.emissiveStrength") != std::string::npos);
        }
        if (w.pointer.find("/Shape2D/color") != std::string::npos) {
            ++shapeWarnings;
            CHECK(w.message.find("almost black") != std::string::npos);
            CHECK(w.message.find("emissiveStrength") ==
                  std::string::npos);  // only an emissive colour has a strength to point to
        }
    }
    CHECK(emissiveWarnings == 2);  // [1.5, 1, 0.4, 1] and [2, 2, 2]; the colour with a strength and the bytes are fine
    CHECK(shapeWarnings == 1);
}

TEST_CASE("validate scripts: a default import of factoria is the whole module and its members are checked") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    write_script(dir, "scripts/dflt.js",
                 "import F from \"factoria\";\nimport { default as G } from \"factoria\";\n"
                 "export default class D extends F.Behaviour {\n  onStart() {\n    F.world.find(\"x\");\n    "
                 "G.wrold;\n  }\n}\n");
    const ValidationReport r = validate_with_engine(dir);
    for (const ValidationIssue& i : r.errors) MESSAGE("error: " << i.to_string());
    CHECK(find_issue(r.errors, "no default export") == nullptr);
    CHECK(find_issue(r.errors, "scripts/dflt.js:3") == nullptr);
    CHECK(find_issue(r.errors, "scripts/dflt.js:5") == nullptr);
    CHECK(find_issue(r.errors, "scripts/dflt.js:6:7") != nullptr);  // G.wrold
}

TEST_CASE("validate scripts: plural receivers, the case caveat, later declarators and commented tool calls") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    write_script(dir, "tools/scatter.js",
                 "export default { name: \"scatter\", summary: \"x\", run() { return {}; } };\n");
    write_script(dir, "scripts/polish.js",
                 "import { Behaviour, physics } from \"factoria\";\nexport default class P extends Behaviour {\n"
                 "  onStart() {\n    const levels = new Set();\n    levels.has(\"Intro\");\n    "
                 "this.entity.has(\"transform\");\n"
                 "    let a = 1, physics = { nothing: 2 };\n    return physics.nothing + a;\n  }\n}\n"
                 "// fa.call(\"project.scatter\")\n/* fa.call(\"project.scatter\") */\nconst text = "
                 "'fa.call(\"project.scatter\")';\n");
    const ValidationReport r = validate_with_engine(dir);
    for (const ValidationIssue& i : r.warnings) MESSAGE("warning: " << i.to_string());
    for (const ValidationIssue& i : r.errors) MESSAGE("error: " << i.to_string());
    CHECK(find_issue(r.warnings, "scripts/polish.js:5") == nullptr);  // levels.has("Intro"): a plural is a collection
    const ValidationIssue* ci = find_issue(r.warnings, "scripts/polish.js:6");
    REQUIRE(ci != nullptr);
    CHECK(ci->message.find("if this is not an entity, ignore this warning") != std::string::npos);
    CHECK(find_issue(r.errors, "scripts/polish.js:8") ==
          nullptr);                                               // `physics` is declared by `let a = 1, physics = ...`
    CHECK(find_issue(r.warnings, "project.scatter") == nullptr);  // only in a comment and a string
}

TEST_CASE("validate scripts: a name declared after a template substitution is still declared") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    write_script(
        dir, "scripts/after.js",
        "import { Behaviour, physics } from \"factoria\";\nexport default class P extends Behaviour {\n"
        "  onStart() {\n    let a = `x${1}`, physics = { nothing: 2 };\n    return physics.nothing + a;\n  }\n}\n");
    const ValidationReport r = validate_with_engine(dir);
    for (const ValidationIssue& i : r.errors) MESSAGE("error: " << i.to_string());
    CHECK(find_issue(r.errors, "scripts/after.js:5") == nullptr);  // `physics` is declared after the `${}`
}

TEST_CASE("validate scripts: a call inside a template substitution is found, a call in the template's text is not") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    write_script(dir, "tools/scatter.js",
                 "export default { name: \"scatter\", summary: \"x\", run() { return {}; } };\n");
    write_script(dir, "scripts/tpl.js",
                 "import { Behaviour, fa } from \"factoria\";\nexport default class T extends Behaviour {\n"
                 "  onStart() {\n    const s = `text ${ [1].map((x) => `${x}`).join(\"\") + "
                 "fa.call(\"project.scatter\", {}) } end`;\n"
                 "    return s;\n  }\n}\n");
    const ValidationReport r = validate_with_engine(dir);
    for (const ValidationIssue& i : r.warnings) MESSAGE("warning: " << i.to_string());
    CHECK(find_issue(r.warnings, "scripts/tpl.js:4 calls project.scatter, the command of tools/scatter.js") != nullptr);
}
