// factoria validate: *.anim.json files, and the clips each Animator names.
#include <doctest.h>

#include <filesystem>

#include "fa/scene/serialize.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kGoodClip = R"({"format":"factoria.anim/1","duration":1,"loop":true,"tracks":[
  {"path":"arm","field":"rotation.z","keys":[{"t":0,"value":-20},{"t":0.5,"value":20},{"t":1,"value":-20}]}]})";

const ValidationIssue* find_in(const std::vector<ValidationIssue>& list, const std::string& file, const std::string& text) {
    for (const ValidationIssue& i : list)
        if (i.file == file && i.message.find(text) != std::string::npos) return &i;
    return nullptr;
}

// A project with a hero (child "arm") whose Animator plays the given clips.
stdfs::path make_project(testing::TempDir& tmp, const char* clips) {
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const stdfs::path dir = tmp.path / "game";
    auto scene = load_json_file((dir / "scenes/main.scene.json").string());
    REQUIRE(scene.ok());
    Json hero = Json::parse(R"({"id":"hero","name":"hero","components":{"Animator":{}},"children":[{"id":"arm","name":"arm","components":{"Shape2D":{"size":[4,20]}}}]})");
    hero["components"]["Animator"]["clips"] = Json::parse(clips);
    (*scene)["entities"].push_back(hero);
    REQUIRE(save_scene_json_file((dir / "scenes/main.scene.json").string(), *scene).ok());
    return dir;
}

}  // namespace

TEST_CASE("validate: a good clip played by an Animator passes") {
    testing::TempDir tmp;
    const stdfs::path dir = make_project(tmp, R"({"walk":"anim/walk.anim.json"})");
    testing::write_all(dir / "anim/walk.anim.json", kGoodClip);
    const ValidationReport r = validate_project(dir.string());
    for (const auto& e : r.errors) MESSAGE(e.to_string());
    CHECK(r.ok);
}

TEST_CASE("validate: a clip file that is wrong names the file, the JSON pointer and the fix") {
    testing::TempDir tmp;
    const stdfs::path dir = make_project(tmp, R"({"walk":"anim/walk.anim.json"})");
    testing::write_all(dir / "anim/walk.anim.json", kGoodClip);
    // Not played by anything, but still checked.
    testing::write_all(dir / "anim/loose.anim.json", R"({"format":"factoria.anim/1","duration":1,"tracks":[{"field":"rotaton.z","keys":[{"t":0,"value":1}]}]})");
    testing::write_all(dir / "anim/syntax.anim.json", "{ not json");
    const ValidationReport r = validate_project(dir.string());
    CHECK_FALSE(r.ok);
    const ValidationIssue* loose = find_in(r.errors, "anim/loose.anim.json", "");
    REQUIRE(loose);
    CHECK_FALSE(loose->pointer.empty());
    CHECK_FALSE(loose->hint.empty());
    CHECK(find_in(r.errors, "anim/syntax.anim.json", ""));
    CHECK_FALSE(find_in(r.errors, "anim/walk.anim.json", ""));
}

TEST_CASE("validate: an Animator whose clip file is missing, with a did-you-mean") {
    testing::TempDir tmp;
    const stdfs::path dir = make_project(tmp, R"({"walk":"anim/wlak.anim.json"})");
    testing::write_all(dir / "anim/walk.anim.json", kGoodClip);
    const ValidationReport r = validate_project(dir.string());
    CHECK_FALSE(r.ok);
    const ValidationIssue* missing = find_in(r.errors, "scenes/main.scene.json", "does not exist");
    REQUIRE(missing);
    CHECK(missing->pointer.find("/components/Animator/clips/walk") != std::string::npos);
    CHECK(missing->message.find("anim/walk.anim.json") != std::string::npos);  // did you mean
}

TEST_CASE("validate: a track that names no part of the Animator's entity") {
    testing::TempDir tmp;
    const stdfs::path dir = make_project(tmp, R"({"walk":"anim/walk.anim.json","wave":"anim/wave.anim.json"})");
    testing::write_all(dir / "anim/walk.anim.json", kGoodClip);
    testing::write_all(dir / "anim/wave.anim.json", R"({"format":"factoria.anim/1","duration":1,"tracks":[
      {"path":"hand","field":"rotation.z","keys":[{"t":0,"value":0},{"t":1,"value":10}]},
      {"path":"arm","component":"Sprite","field":"color.a","keys":[{"t":0,"value":0},{"t":1,"value":1}]}]})");
    const ValidationReport r = validate_project(dir.string());
    CHECK_FALSE(r.ok);
    const ValidationIssue* hand = find_in(r.errors, "scenes/main.scene.json", "hand");
    REQUIRE(hand);
    CHECK(hand->message.find("wave") != std::string::npos);
    CHECK(hand->message.find("hero") != std::string::npos);
    CHECK(hand->hint.find("arm") != std::string::npos);
    CHECK(find_in(r.errors, "scenes/main.scene.json", "no Sprite component"));
}
