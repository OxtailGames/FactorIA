// factoria validate: data files imported by scripts (.json) and scene/prefab files that are not in the canonical layout.
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

// Runs validate_project with the script hooks of a logic-only engine, like `factoria validate` does.
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

std::size_t count_mentioning(const std::vector<ValidationIssue>& list, const std::string& needle) {
    std::size_t n = 0;
    for (const ValidationIssue& i : list)
        if (i.to_string().find(needle) != std::string::npos) ++n;
    return n;
}

}  // namespace

TEST_CASE("validate: a broken .json imported by two scripts is reported once, as file:line:column, without a props warning") {
    testing::TempDir tmp;
    const std::string dir = tmp.sub("game");
    REQUIRE(create_project(dir, "2d-empty").ok());
    // An entity whose Script.props (speed) validate checks against the behaviour once it loads.
    auto scene = load_json_file(dir + "/scenes/main.scene.json");
    REQUIRE(scene.ok());
    (*scene)["entities"].push_back(Json::parse(
        R"({"id": "player", "components": {"Script": {"path": "scripts/player.js", "props": {"speed": 300}}}})"));
    REQUIRE(save_scene_json_file(dir + "/scenes/main.scene.json", *scene).ok());
    // Line 3, the second comma of "[1, 2,,]".
    testing::write_all(stdfs::path(dir) / "scripts/levels.json", "{\n  \"a\": 1,\n  \"b\": [1, 2,,]\n}\n");
    // Both scripts import the broken file.
    for (const char* name : {"player", "other"})
        testing::write_all(stdfs::path(dir) / "scripts" / (std::string(name) + ".js"),
                           "import { Behaviour } from \"factoria\";\nimport levels from \"./levels.json\";\n"
                           "export default class Importer extends Behaviour {\n  speed = 1;\n  onUpdate() { levels; }\n}\n");

    ValidationReport r = validate_with_engine(dir);
    for (const ValidationIssue& i : r.errors) MESSAGE("error: " << i.to_string());
    for (const ValidationIssue& i : r.warnings) MESSAGE("warning: " << i.to_string());
    REQUIRE(r.errors.size() == 1);  // once, not once per importing script
    const ValidationIssue& issue = r.errors[0];
    CHECK(issue.file == "scripts/levels.json");  // the issue is IN the data file
    CHECK(issue.message.rfind("scripts/levels.json:3:", 0) == 0);  // file:line:column
    CHECK(issue.message.find("invalid JSON") != std::string::npos);
    CHECK_FALSE(issue.hint.empty());
    CHECK(count_mentioning(r.warnings, "levels.json") == 0);  // no cascading Script.props warning
    CHECK(count_mentioning(r.warnings, "scripts/player.js") == 0);
    CHECK_FALSE(r.ok);

    // Fixing the file clears everything, props included.
    testing::write_all(stdfs::path(dir) / "scripts/levels.json", "{\"a\": 1}\n");
    ValidationReport fixed = validate_with_engine(dir);
    for (const ValidationIssue& i : fixed.errors) MESSAGE("error: " << i.to_string());
    CHECK(fixed.ok);
}

TEST_CASE("validate: a scene or prefab that is not in the canonical layout is one warning per file, with the fix") {
    testing::TempDir tmp;
    const std::string dir = tmp.sub("game");
    REQUIRE(create_project(dir, "2d-empty").ok());
    CHECK(count_mentioning(validate_project(dir).warnings, "canonical") == 0);  // what the templates write is canonical

    testing::write_all(stdfs::path(dir) / "prefabs/messy.prefab.json",
                       "{\"format\":\"factoria.prefab/1\",\"entity\":{\"name\":\"Messy\",\n\"components\":{\"Shape2D\":{\"size\":[10,10]}}}}");
    testing::write_all(stdfs::path(dir) / "scenes/second.scene.json",
                       "{\"format\":\"factoria.scene/1\",\"entities\":[{\"id\":\"a\",\"components\":{\"Transform\":{\"position\":[1,2,0]}}}]}");
    ValidationReport r = validate_project(dir);
    CHECK(r.ok);  // a layout is a warning, never an error
    std::vector<std::string> files;
    for (const ValidationIssue& w : r.warnings)
        if (w.message.find("canonical layout") != std::string::npos) {
            files.push_back(w.file);
            CHECK(w.hint.find("scene.format") != std::string::npos);
        }
    CHECK(files == std::vector<std::string>{"scenes/second.scene.json", "prefabs/messy.prefab.json"});

    // Writing them the way scene.format does (the shared canonical_scene_layout) clears the warnings.
    for (const char* rel : {"prefabs/messy.prefab.json", "scenes/second.scene.json"}) {
        const stdfs::path file = stdfs::path(dir) / rel;
        auto layout = canonical_scene_layout(file.generic_string());
        REQUIRE(layout.ok());
        CHECK_FALSE(layout->same);
        testing::write_all(file, layout->text);
    }
    CHECK(count_mentioning(validate_project(dir).warnings, "canonical layout") == 0);
}
