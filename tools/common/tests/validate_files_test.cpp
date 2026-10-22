// project.validate: which scene and prefab files it checks (every one of the project, not only scenes/ and prefabs/), and
// what it says about values outside a field's range().
#include <doctest.h>

#include <filesystem>

#include "fa/scene/serialize.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// A fresh 2d-empty project (validates clean) in tmp/game.
std::string new_project(testing::TempDir& tmp) {
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    return tmp.sub("game");
}

// Writes a scene or prefab in the canonical layout, so that only the content under test is reported.
void write_canonical(const std::string& file, const char* json) {
    stdfs::create_directories(stdfs::path(file).parent_path());
    REQUIRE(save_scene_json_file(file, Json::parse(json)).ok());
}

const ValidationIssue* find_issue(const std::vector<ValidationIssue>& list, const std::string& file, const std::string& pointer = {}) {
    for (const ValidationIssue& i : list)
        if (i.file == file && (pointer.empty() || i.pointer == pointer)) return &i;
    return nullptr;
}

const char* kBadSides = R"({"format": "factoria.scene/1", "entities": [
    {"id": "p", "components": {"Shape2D": {"shape": "polygon", "sides": 200}}}]})";

}  // namespace

TEST_CASE("validate: scenes and prefabs outside scenes/ and prefabs/ are checked too") {
    testing::TempDir tmp;
    const std::string dir = new_project(tmp);
    const ValidationReport before = validate_project(dir);
    REQUIRE(before.ok);

    // A scene in levels/ that is not in the canonical layout, with a mistake in it.
    testing::write_all(stdfs::path(dir) / "levels/base.scene.json",
                       "{\"format\":\"factoria.scene/1\",\"entities\":[{\"id\":\"a\",\"components\":{\"Camera\":{\"fvo\":3}}}]}");
    // A prefab in levels/ with a mistake, placed by no scene.
    write_canonical(dir + "/levels/boss.prefab.json",
                    R"({"format": "factoria.prefab/1", "entity": {"id": "boss", "components": {"Sprit": {}}}})");
    // A canonical, correct scene in a folder of its own.
    write_canonical(dir + "/maps/ok.scene.json", R"({"format": "factoria.scene/1", "entities": []})");

    const ValidationReport r = validate_project(dir);
    CHECK(r.scenesChecked == before.scenesChecked + 2);  // levels/base and maps/ok
    CHECK_FALSE(r.ok);
    // A hand-formatted file is valid: one note (not a warning) lists it.
    CHECK(find_issue(r.warnings, "levels/base.scene.json", "") == nullptr);
    REQUIRE(r.notes.size() == 1);
    CHECK(r.notes[0].message.find("formatted by hand") != std::string::npos);
    CHECK(r.notes[0].message.find("levels/base.scene.json") != std::string::npos);
    CHECK(r.notes[0].message.find("maps/ok.scene.json") == std::string::npos);
    CHECK(r.notes[0].hint.find("scene.format") != std::string::npos);
    CHECK(r.to_text().find("note: ") != std::string::npos);
    CHECK(r.to_json()["notes"].size() == 1);
    const ValidationIssue* field = find_issue(r.errors, "levels/base.scene.json", "/entities/0/components/Camera/fvo");
    REQUIRE(field != nullptr);
    CHECK(field->message.find("Unknown field 'fvo'") != std::string::npos);
    const ValidationIssue* component = find_issue(r.errors, "levels/boss.prefab.json", "/entity/components/Sprit");
    REQUIRE(component != nullptr);  // the pointer is the one in the prefab FILE
    CHECK(component->message.find("Unknown component 'Sprit'") != std::string::npos);
    CHECK(find_issue(r.warnings, "maps/ok.scene.json") == nullptr);
    CHECK(find_issue(r.errors, "maps/ok.scene.json") == nullptr);

    // A non-canonical prefab outside prefabs/ is reported like one inside it.
    testing::write_all(stdfs::path(dir) / "levels/loose.prefab.json", "{\"format\":\"factoria.prefab/1\",\"entity\":{\"id\":\"x\"}}");
    const ValidationReport r2 = validate_project(dir);
    REQUIRE(r2.notes.size() == 1);  // still ONE note, now naming both files
    CHECK(r2.notes[0].message.find("2 scene/prefab files are formatted by hand") != std::string::npos);
    CHECK(r2.notes[0].message.find("levels/loose.prefab.json") != std::string::npos);
    CHECK(find_issue(r2.warnings, "levels/loose.prefab.json") == nullptr);
}

TEST_CASE("validate: a canonical project has no note") {
    testing::TempDir tmp;
    const std::string dir = new_project(tmp);
    write_canonical(dir + "/maps/ok.scene.json", R"({"format": "factoria.scene/1", "entities": []})");
    const ValidationReport r = validate_project(dir);
    CHECK(r.notes.empty());
    CHECK(r.to_json()["notes"].empty());
}

TEST_CASE("validate: a valid hand-formatted scene gives 0 warnings and 1 note") {
    testing::TempDir tmp;
    const std::string dir = new_project(tmp);
    testing::write_all(stdfs::path(dir) / "maps/hand.scene.json", "{\"format\":\"factoria.scene/1\",\"entities\":[]}");
    const ValidationReport r = validate_project(dir);
    CHECK(r.ok);
    CHECK(r.warnings.empty());
    REQUIRE(r.notes.size() == 1);
    CHECK(r.notes[0].message.find("maps/hand.scene.json") != std::string::npos);
}

TEST_CASE("validate: hidden folders, node_modules and the top-level build/ are not scanned, like scene.format") {
    testing::TempDir tmp;
    const std::string dir = new_project(tmp);
    for (const char* skipped : {".factoria/tmp/a.scene.json", "build/export/b.scene.json", "node_modules/pkg/c.scene.json", ".hidden/d.prefab.json"})
        testing::write_all(stdfs::path(dir) / skipped, "{\"format\":\"factoria.scene/1\",\"entities\":[{\"colour\":1}]}");
    const ValidationReport r = validate_project(dir);
    for (const auto& i : r.errors) MESSAGE(i.to_string());
    for (const auto& i : r.warnings) MESSAGE(i.to_string());
    CHECK(r.ok);
}

TEST_CASE("validate: a value outside a field's range is an error with file, pointer and range, in scenes and prefabs") {
    testing::TempDir tmp;
    const std::string dir = new_project(tmp);
    write_canonical(dir + "/scenes/ranges.scene.json", kBadSides);
    // A prefab no scene places: only the prefab check can find it.
    write_canonical(dir + "/prefabs/ball.prefab.json",
                    R"({"format": "factoria.prefab/1", "entity": {"id": "ball", "components": {"Shape2D": {"shape": "star", "points": 100}}}})");
    const ValidationReport r = validate_project(dir);
    REQUIRE_FALSE(r.ok);

    const ValidationIssue* scene = find_issue(r.errors, "scenes/ranges.scene.json", "/entities/0/components/Shape2D/sides");
    REQUIRE(scene != nullptr);
    CHECK(scene->message.find("value 200 is outside the allowed range 3..64") != std::string::npos);
    CHECK(scene->hint.find("Use a value from 3 to 64") != std::string::npos);
    CHECK(scene->hint.find("the nearest is 64") != std::string::npos);

    const ValidationIssue* prefab = find_issue(r.errors, "prefabs/ball.prefab.json", "/entity/components/Shape2D/points");
    REQUIRE(prefab != nullptr);
    CHECK(prefab->message.find("value 100 is outside the allowed range 3..64") != std::string::npos);
    CHECK(prefab->hint.find("entity expanded from prefab") == std::string::npos);  // the file itself is the source
    int forPrefab = 0;
    for (const ValidationIssue& i : r.errors)
        if (i.file == "prefabs/ball.prefab.json") ++forPrefab;
    CHECK(forPrefab == 1);  // reported once

    // The limits themselves are fine.
    write_canonical(dir + "/scenes/ranges.scene.json",
                    R"({"format": "factoria.scene/1", "entities": [{"id": "p", "components": {"Shape2D": {"shape": "polygon", "sides": 64}}}]})");
    write_canonical(dir + "/prefabs/ball.prefab.json",
                    R"({"format": "factoria.prefab/1", "entity": {"id": "ball", "components": {"Shape2D": {"shape": "star", "points": 3}}}})");
    const ValidationReport fixed = validate_project(dir);
    for (const auto& i : fixed.errors) MESSAGE(i.to_string());
    CHECK(fixed.ok);
}

TEST_CASE("validate: a prefab that includes a missing prefab is an error at the pointer in its own file") {
    testing::TempDir tmp;
    const std::string dir = new_project(tmp);
    write_canonical(dir + "/prefabs/outer.prefab.json",
                    R"({"format": "factoria.prefab/1", "entity": {"id": "outer", "children": [{"prefab": "prefabs/missing.prefab.json"}]}})");
    const ValidationReport r = validate_project(dir);
    REQUIRE_FALSE(r.ok);
    const ValidationIssue* missing = find_issue(r.errors, "prefabs/outer.prefab.json", "/entity/children/0/prefab");
    REQUIRE(missing != nullptr);
    CHECK(missing->message.find("missing.prefab.json") != std::string::npos);
}

namespace {
struct ValidateProbe {
    Entity target;
};
}  // namespace

TEST_CASE("validate: an Entity field of a prefab may point outside the prefab, the scene that places it supplies the target") {
    if (!TypeRegistry::global().of<ValidateProbe>())
        TypeRegistry::global().add<ValidateProbe>("ValidateProbe", "Test component pointing at another entity.", "Test")
            .field("target", &ValidateProbe::target, "Entity it points at.");
    testing::TempDir tmp;
    const std::string dir = new_project(tmp);
    write_canonical(dir + "/prefabs/seeker.prefab.json",
                    R"({"format": "factoria.prefab/1", "entity": {"id": "seeker", "components": {"ValidateProbe": {"target": "player"}}}})");
    const ValidationReport alone = validate_project(dir);
    for (const auto& i : alone.errors) MESSAGE(i.to_string());
    CHECK(alone.ok);  // loaded on its own there is no "player" to find, which is not the prefab's fault

    write_canonical(dir + "/scenes/main.scene.json",
                    R"({"format": "factoria.scene/1", "entities": [{"id": "s", "prefab": "prefabs/seeker.prefab.json"}]})");
    const ValidationReport placed = validate_project(dir);
    REQUIRE_FALSE(placed.ok);  // no "player" in this scene: the scene reports it, at its own entity
    CHECK(find_issue(placed.errors, "scenes/main.scene.json", "/entities/0/components/ValidateProbe/target") != nullptr);
    CHECK(find_issue(placed.errors, "prefabs/seeker.prefab.json") == nullptr);
}
