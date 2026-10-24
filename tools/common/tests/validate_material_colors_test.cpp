// factoria validate: MeshRenderer.materialColors names are checked against the glTF model.
#include <doctest.h>

#include <filesystem>

#include "fa/scene/serialize.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {
// One triangle per material, "Body" and "Eyes".
const char* kTwoMaterialGltf = R"({
  "asset":{"version":"2.0"},
  "scene":0,"scenes":[{"nodes":[0]}],
  "nodes":[{"mesh":0}],
  "meshes":[{"primitives":[{"attributes":{"POSITION":0},"material":0},{"attributes":{"POSITION":0},"material":1}]}],
  "materials":[{"name":"Body"},{"name":"Eyes"}],
  "buffers":[{"byteLength":36,"uri":"data:application/octet-stream;base64,AAAAAAAAAAAAAAAAAACAPwAAAAAAAAAAAAAAAAAAgD8AAAAA"}],
  "bufferViews":[{"buffer":0,"byteLength":36}],
  "accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3","min":[0,0,0],"max":[1,1,0]}]
})";

const ValidationIssue* find_issue(const std::vector<ValidationIssue>& list, const std::string& suffix) {
    for (const ValidationIssue& i : list)
        if (i.file == "scenes/main.scene.json" && i.pointer.size() >= suffix.size() &&
            i.pointer.compare(i.pointer.size() - suffix.size(), suffix.size(), suffix) == 0)
            return &i;
    return nullptr;
}
}  // namespace

TEST_CASE("validate: materialColors names are checked against the model, with a did-you-mean") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const stdfs::path dir = tmp.path / "game";
    testing::write_all(dir / "assets/robot.gltf", kTwoMaterialGltf);
    auto scene = load_json_file((dir / "scenes/main.scene.json").string());
    REQUIRE(scene.ok());
    auto add = [&](const char* id, const char* fields) {
        (*scene)["entities"].push_back(
            Json::object({{"id", id}, {"components", Json::object({{"MeshRenderer", Json::parse(fields)}})}}));
    };
    add("good", R"({"mesh": "assets/robot.gltf", "materialColors": {"Body": [0.2, 0.8, 0.7, 1], "Eyes": [0, 0, 0]}})");
    add("typo", R"({"mesh": "assets/robot.gltf", "materialColors": {"Bodi": [0.2, 0.8, 0.7, 1]}})");
    add("shape", R"({"mesh": "assets/robot.gltf", "materialColors": {"Body": [0.2, 0.8]}})");
    add("cube", R"({"mesh": "cube", "materialColors": {"Body": [1, 0, 0, 1]}})");
    REQUIRE(save_scene_json_file((dir / "scenes/main.scene.json").string(), *scene).ok());

    const ValidationReport r = validate_project(dir.string());
    for (const auto& e : r.errors) MESSAGE(e.to_string());
    CHECK_FALSE(r.ok);
    const ValidationIssue* typo = find_issue(r.errors, "/MeshRenderer/materialColors/Bodi");
    REQUIRE(typo);
    CHECK(typo->message.find("no material named 'Bodi'") != std::string::npos);
    CHECK(typo->hint.find("Body") != std::string::npos);
    CHECK(find_issue(r.errors, "/MeshRenderer/materialColors/Body"));  // the entity with two numbers, not the good ones
    CHECK(r.errors.size() == 2);
    CHECK(find_issue(r.warnings, "/MeshRenderer/materialColors"));  // the cube
}
