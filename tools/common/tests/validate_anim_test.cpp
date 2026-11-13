// factoria validate: *.anim.json files, and the clips each Animator names.
#include <doctest.h>

#include <filesystem>

#include "asset_test_helpers.h"
#include "fa/scene/serialize.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kGoodClip = R"({"format":"factoria.anim/1","duration":1,"loop":true,"tracks":[
  {"path":"arm","field":"rotation.z","keys":[{"t":0,"value":-20},{"t":0.5,"value":20},{"t":1,"value":-20}]}]})";

const ValidationIssue* find_in(const std::vector<ValidationIssue>& list, const std::string& file,
                               const std::string& text) {
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
    Json hero = Json::parse(
        R"({"id":"hero","name":"hero","components":{"Animator":{}},"children":[{"id":"arm","name":"arm","components":{"Shape2D":{"size":[4,20]}}}]})");
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
    testing::write_all(
        dir / "anim/loose.anim.json",
        R"({"format":"factoria.anim/1","duration":1,"tracks":[{"field":"rotaton.z","keys":[{"t":0,"value":1}]}]})");
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

// ---- 3D bone clips and IK3D -------------------------------------------------------------------------------------------------------------

namespace {

const char* kBox = R"({"format":"factoria.model/1","nodes":[
  {"op":"box","size":[0.36,0.2,0.2],"position":[0,0.95,0],"part":"pelvis"},
  {"op":"box","size":[0.4,0.5,0.22],"position":[0,1.3,0],"part":"torso"},
  {"op":"box","size":[0.1,0.1,0.1],"position":[0,1.6,0],"part":"neck"},
  {"op":"box","size":[0.22,0.25,0.22],"position":[0,1.77,0.02],"part":"head"},
  {"op":"box","size":[0.7,0.1,0.1],"position":[0.55,1.5,0],"part":"arm_l"},
  {"op":"box","size":[0.7,0.1,0.1],"position":[-0.55,1.5,0],"part":"arm_r"},
  {"op":"box","size":[0.14,0.9,0.14],"position":[0.11,0.45,0],"part":"leg_l"},
  {"op":"box","size":[0.14,0.9,0.14],"position":[-0.11,0.45,0],"part":"leg_r"}]})";

// A project with a baked humanoid (assets/models/hero.rig.glb) and a "hero" entity that shows it with an Animator and optionally an IK3D.
stdfs::path make_rig_project(testing::TempDir& tmp, const char* clips, const char* ik3d = nullptr) {
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const stdfs::path dir = tmp.path / "game";
    CommandRegistry registry;
    register_asset_commands(registry, dir.string());
    testing::write_all(dir / "assets/models/hero.model.json", kBox);
    const CommandResult made = registry.call(
        "rig.create",
        Json::parse(
            R"({"path":"assets/models/hero.rig.json","model":"assets/models/hero.model.json","template":"humanoid"})"));
    REQUIRE_MESSAGE(made.ok, made.error.dump());
    auto scene = load_json_file((dir / "scenes/main.scene.json").string());
    REQUIRE(scene.ok());
    Json hero = Json::parse(
        R"({"id":"hero","name":"hero","components":{"MeshRenderer":{"mesh":"assets/models/hero.rig.glb"},"Animator":{"model":"assets/models/hero.rig.glb"}}})");
    hero["components"]["Animator"]["clips"] = Json::parse(clips);
    if (ik3d) hero["components"]["IK3D"] = Json::parse(ik3d);
    (*scene)["entities"].push_back(hero);
    REQUIRE(save_scene_json_file((dir / "scenes/main.scene.json").string(), *scene).ok());
    return dir;
}

const char* kGoodClip3D = R"({"format":"factoria.anim3d/1","duration":1,"loop":true,"tracks":[
  {"bone":"spine_1","keys":[{"t":0,"value":[0,0,0]},{"t":0.5,"value":[10,0,0]},{"t":1,"value":[0,0,0]}]}]})";

}  // namespace

TEST_CASE("validate: a 3D bone clip played by an Animator on a skinned model passes, and IK3D with good solvers too") {
    testing::TempDir tmp;
    const stdfs::path dir = make_rig_project(tmp, R"({"walk":"anim/walk.anim.json"})",
                                             R"({"solvers":[{"type":"lookAt","bone":"head","target":[0,1.6,3]}]})");
    testing::write_all(dir / "anim/walk.anim.json", kGoodClip3D);
    const ValidationReport r = validate_project(dir.string());
    for (const auto& e : r.errors) MESSAGE(e.to_string());
    CHECK(r.ok);
}

TEST_CASE(
    "validate: a 3D clip with a bad key, a bone the model lacks, a missing file, and a 2D clip on a model all teach") {
    testing::TempDir tmp;
    const stdfs::path dir = make_rig_project(
        tmp, R"({"walk":"anim/walk.anim.json","ghost":"anim/ghost.anim.json","gone":"anim/gone.anim.json"})");
    testing::write_all(dir / "anim/walk.anim.json", R"({"format":"factoria.anim3d/1","duration":1,"tracks":[
      {"bone":"spine_1","keys":[{"t":0,"value":[0,0]}]}]})");
    testing::write_all(dir / "anim/ghost.anim.json", R"({"format":"factoria.anim3d/1","duration":1,"tracks":[
      {"bone":"spin_1","keys":[{"t":0,"value":[0,0,0]}]}]})");
    const ValidationReport r = validate_project(dir.string());
    CHECK_FALSE(r.ok);
    const ValidationIssue* bad = find_in(r.errors, "anim/walk.anim.json", "");
    REQUIRE(bad);
    CHECK(bad->pointer.find("/tracks/0") == 0);
    CHECK_FALSE(bad->hint.empty());
    const ValidationIssue* ghost = find_in(r.errors, "scenes/main.scene.json", "spin_1");
    REQUIRE(ghost);
    CHECK(ghost->pointer.find("/components/Animator/clips/ghost") != std::string::npos);
    CHECK(ghost->hint.find("spine_1") != std::string::npos);
    CHECK(find_in(r.errors, "scenes/main.scene.json", "anim/gone.anim.json"));
}

TEST_CASE("validate: IK3D solvers are checked against the model's bones, and an IK3D needs an Animator on a model") {
    testing::TempDir tmp;
    const stdfs::path dir = make_rig_project(
        tmp, R"({})",
        R"({"weight":2,"solvers":[{"type":"twoBone","root":"thigh_l","mid":"shin_q","end":"foot_l"},{"type":"lookAt","bone":"head","yawLimit":900}]})");
    ValidationReport r = validate_project(dir.string());
    CHECK_FALSE(r.ok);
    const ValidationIssue* mid = find_in(r.errors, "scenes/main.scene.json", "shin_q");
    REQUIRE(mid);
    CHECK(mid->pointer.find("/components/IK3D/solvers/0/mid") != std::string::npos);
    CHECK(mid->hint.find("shin_l") != std::string::npos);
    CHECK(find_in(r.errors, "scenes/main.scene.json", "yawLimit"));
    CHECK(find_in(r.errors, "scenes/main.scene.json", "weight"));

    // an IK3D whose entity has no Animator
    auto scene = load_json_file((dir / "scenes/main.scene.json").string());
    REQUIRE(scene.ok());
    (*scene)["entities"].push_back(Json::parse(R"({"id":"lonely","name":"lonely","components":{"IK3D":{}}})"));
    REQUIRE(save_scene_json_file((dir / "scenes/main.scene.json").string(), *scene).ok());
    r = validate_project(dir.string());
    const ValidationIssue* lonely = find_in(r.errors, "scenes/main.scene.json", "needs an Animator");
    REQUIRE(lonely);
    CHECK(lonely->message.find("lonely") != std::string::npos);
}

namespace {
// make_project, then the hero's Animator gets `events` (a JSON array text) and `clips`.
stdfs::path make_event_project(testing::TempDir& tmp, const char* events) {
    const stdfs::path dir = make_project(tmp, R"({"walk":"anim/walk.anim.json"})");
    testing::write_all(dir / "anim/walk.anim.json", kGoodClip);
    auto scene = load_json_file((dir / "scenes/main.scene.json").string());
    REQUIRE(scene.ok());
    Json& entities = (*scene)["entities"];
    for (Json& e : entities)
        if (e.value("id", std::string()) == "hero") e["components"]["Animator"]["events"] = Json::parse(events);
    REQUIRE(save_scene_json_file((dir / "scenes/main.scene.json").string(), *scene).ok());
    return dir;
}
}  // namespace

TEST_CASE("validate: inline Animator events with the wrong JSON types name the pointer and the fix") {
    testing::TempDir tmp;
    const stdfs::path dir = make_event_project(tmp, R"([{"clip":"walk","time":0.2,"name":"ok"},
        {"clip":"walk","time":0.2,"name":5},{"clip":"walk","time":0.2,"feel":{"action":5}},{"clip":"walk","time":"x","name":"a"},
        {"clip":"walk","time":0.2,"feel":{"action":"hitStp"}}])");
    const ValidationReport r = validate_project(dir.string());
    CHECK_FALSE(r.ok);
    bool name = false, action = false, time = false, typo = false;
    for (const ValidationIssue& i : r.errors) {
        if (i.pointer.find("events/1/name") != std::string::npos) name = true;
        if (i.pointer.find("events/2/feel") != std::string::npos) action = true;
        if (i.pointer.find("events/3/time") != std::string::npos) time = true;
        if (i.pointer.find("events/4/feel") != std::string::npos && i.message.find("hitStop") != std::string::npos)
            typo = true;
    }
    CHECK(name);
    CHECK(action);
    CHECK(time);
    CHECK(typo);
}

TEST_CASE("validate: a spawn without a lifetime is a warning unless the prefab ends itself") {
    testing::TempDir tmp;
    const stdfs::path dir = make_event_project(tmp, R"([
        {"clip":"walk","time":0.1,"feel":{"action":"spawn","prefab":"prefabs/dust.prefab.json"}},
        {"clip":"walk","time":0.2,"feel":{"action":"spawn","prefab":"prefabs/dust.prefab.json","lifetime":0.5}},
        {"clip":"walk","time":0.3,"feel":{"action":"spawn","prefab":"prefabs/self.prefab.json"}},
        {"clip":"walk","time":0.4,"feel":{"action":"spawn","prefab":"prefabs/puff.prefab.json"}}])");
    testing::write_all(dir / "prefabs/dust.prefab.json",
                       R"({"format":"factoria.prefab/1","entity":{"id":"dust","components":{"Sprite":{}}}})");
    testing::write_all(
        dir / "prefabs/self.prefab.json",
        R"({"format":"factoria.prefab/1","entity":{"id":"s","components":{"Script":{"path":"scripts/x.js"}}}})");
    testing::write_all(
        dir / "prefabs/puff.prefab.json",
        R"({"format":"factoria.prefab/1","entity":{"id":"p","components":{"ParticleEmitter":{"autoDestroy":true}}}})");
    const ValidationReport r = validate_project(dir.string());
    int lifetimeWarnings = 0;
    bool firstOne = false;
    for (const ValidationIssue& w : r.warnings) {
        if (w.message.find("no `lifetime`") == std::string::npos) continue;
        ++lifetimeWarnings;
        if (w.pointer.find("events/0/feel/prefab") != std::string::npos) firstOne = true;
    }
    CHECK(lifetimeWarnings == 1);
    CHECK(firstOne);
    for (const ValidationIssue& e : r.errors)
        CHECK_MESSAGE(e.message.find("no `lifetime`") == std::string::npos, e.to_string());
}

TEST_CASE("validate: a spawn whose prefab instances another prefab that ends itself is not a warning") {
    testing::TempDir tmp;
    const stdfs::path dir = make_event_project(tmp, R"([
        {"clip":"walk","time":0.1,"feel":{"action":"spawn","prefab":"prefabs/wrapper.prefab.json"}},
        {"clip":"walk","time":0.2,"feel":{"action":"spawn","prefab":"prefabs/loop_a.prefab.json"}},
        {"clip":"walk","time":0.3,"feel":{"action":"spawn","prefab":"prefabs/vfx.prefab.json"}}])");
    testing::write_all(
        dir / "prefabs/inner.prefab.json",
        R"({"format":"factoria.prefab/1","entity":{"id":"i","components":{"ParticleEmitter":{"autoDestroy":true}}}})");
    testing::write_all(dir / "prefabs/wrapper.prefab.json",
                       R"({"format":"factoria.prefab/1","entity":{"id":"w","components":{"Transform":{}},
        "children":[{"id":"w_in","prefab":"prefabs/inner.prefab.json"}]}})");
    testing::write_all(dir / "prefabs/loop_a.prefab.json",
                       R"({"format":"factoria.prefab/1","entity":{"id":"a","prefab":"prefabs/loop_b.prefab.json"}})");
    testing::write_all(dir / "prefabs/loop_b.prefab.json",
                       R"({"format":"factoria.prefab/1","entity":{"id":"b","prefab":"prefabs/loop_a.prefab.json"}})");
    testing::write_all(
        dir / "prefabs/vfx.prefab.json",
        R"({"format":"factoria.prefab/1","entity":{"id":"v","components":{"Vfx":{"effect":"fx/x.vfx.json","autoDestroy":true}}}})");
    const ValidationReport r = validate_project(dir.string());
    int warned = 0;
    std::string which;
    for (const ValidationIssue& w : r.warnings)
        if (w.message.find("no `lifetime`") != std::string::npos) {
            ++warned;
            which += w.pointer + " ";
        }
    CHECK_MESSAGE(warned == 1,
                  which);  // only the two prefabs that instance each other never end (the cycle ends the walk, no hang)
    CHECK(which.find("events/1/") != std::string::npos);
}

TEST_CASE("validate: a sound that exists only as its .qoa twin is not reported missing") {
    testing::TempDir tmp;
    const stdfs::path dir = make_event_project(tmp, R"([
        {"clip":"walk","time":0.1,"feel":{"action":"sound","path":"audio/step.wav"}},
        {"clip":"walk","time":0.2,"feel":{"action":"sound","path":"audio/gone.wav"}}])");
    testing::write_all(dir / "audio/step.wav.qoa", "qoa");
    const ValidationReport r = validate_project(dir.string());
    bool step = false, gone = false;
    for (const ValidationIssue& e : r.errors) {
        if (e.message.find("'audio/step.wav'") != std::string::npos)
            step = true;  // (the candidates of the other error name the twin)
        if (e.message.find("'audio/gone.wav'") != std::string::npos) gone = true;
    }
    CHECK_FALSE(step);
    CHECK(gone);
}
