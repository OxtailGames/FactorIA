// factoria validate: a scene entity that repeats the components of a prefab inline warns (it will drift from the prefab).
#include <doctest.h>

#include <filesystem>

#include "fa/scene/serialize.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {
std::vector<ValidationIssue> inline_copy_warnings(const ValidationReport& r) {
    std::vector<ValidationIssue> out;
    for (const ValidationIssue& i : r.warnings)
        if (i.message.find("inline") != std::string::npos || i.message.find("prefab's own values") != std::string::npos) out.push_back(i);
    return out;
}
}  // namespace

TEST_CASE("validate: an inline copy of a prefab warns, an instance and an unlike entity do not") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const stdfs::path dir = tmp.path / "game";
    stdfs::create_directories(dir / "prefabs");
    Json prefab = Json::parse(R"({"format":"factoria.prefab/1","entity":{"name":"Coin","components":{
        "Transform":{},"Shape2D":{"shape":"circle","size":[20,20],"color":"gold"},"Collider2D":{"shape":"circle","size":[20,20]}}}})");
    REQUIRE(save_scene_json_file((dir / "prefabs/coin.prefab.json").string(), prefab).ok());
    auto scene = load_json_file((dir / "scenes/main.scene.json").string());
    REQUIRE(scene.ok());
    auto& ents = (*scene)["entities"];
    ents.push_back(Json::parse(R"({"id":"copy","name":"Coin","components":{"Transform":{"position":[5,0,0]},
        "Shape2D":{"shape":"circle","size":[20,20],"color":"gold"},"Collider2D":{"shape":"circle","size":[20,20]}}})"));
    ents.push_back(Json::parse(R"({"id":"inst","prefab":"prefabs/coin.prefab.json","components":{"Transform":{"position":[9,0,0]}}})"));
    ents.push_back(Json::parse(R"({"id":"other","name":"Coin","components":{"Transform":{},
        "Shape2D":{"shape":"rect","size":[300,10],"color":"red"},"Collider2D":{"shape":"box","size":[300,10],"isTrigger":true}}})"));
    REQUIRE(save_scene_json_file((dir / "scenes/main.scene.json").string(), *scene).ok());

    const auto w = inline_copy_warnings(validate_project(dir.string()));
    REQUIRE(w.size() == 1);
    CHECK(w[0].file == "scenes/main.scene.json");
    CHECK(w[0].pointer == "/entities/" + std::to_string(ents.size() - 3));
    CHECK(w[0].message.find("prefabs/coin.prefab.json") != std::string::npos);
    CHECK(w[0].hint.find("\"prefab\":\"prefabs/coin.prefab.json\"") != std::string::npos);
    CHECK(w[0].hint.find("scene.save") != std::string::npos);
}

TEST_CASE("validate: an instance that also saves two components with the prefab's values warns") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const stdfs::path dir = tmp.path / "game";
    stdfs::create_directories(dir / "prefabs");
    Json prefab = Json::parse(R"({"format":"factoria.prefab/1","entity":{"name":"Coin","components":{
        "Shape2D":{"shape":"circle","size":[20,20],"color":"gold"},"Collider2D":{"shape":"circle","size":[20,20]}}}})");
    REQUIRE(save_scene_json_file((dir / "prefabs/coin.prefab.json").string(), prefab).ok());
    auto scene = load_json_file((dir / "scenes/main.scene.json").string());
    REQUIRE(scene.ok());
    // One repeated component is an override that equals the prefab: no warning.
    (*scene)["entities"].push_back(Json::parse(R"({"id":"one","prefab":"prefabs/coin.prefab.json","components":{
        "Collider2D":{"shape":"circle","size":[20,20]},"Transform":{"position":[1,0,0]}}})"));
    (*scene)["entities"].push_back(Json::parse(R"({"id":"inst","prefab":"prefabs/coin.prefab.json","components":{
        "Shape2D":{"shape":"circle","size":[20,20],"color":"gold"},"Collider2D":{"shape":"circle","size":[20,20]},
        "Transform":{"position":[9,0,0]}}})"));
    REQUIRE(save_scene_json_file((dir / "scenes/main.scene.json").string(), *scene).ok());
    const auto w = inline_copy_warnings(validate_project(dir.string()));
    REQUIRE(w.size() == 1);
    CHECK(w[0].message.find("Shape2D") != std::string::npos);
    CHECK(w[0].message.find("Collider2D") != std::string::npos);
    CHECK(w[0].message.find("Transform") == std::string::npos);
}
