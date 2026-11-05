// Rig documents and the skeleton fit (docs/RIGGING.md).
#include <doctest.h>

#include <cmath>
#include <cstdio>

#include "fa/scene/animation.h"
#include "fa/scene/model_doc.h"
#include "fa/scene/rig_doc.h"
#include "fa/scene/rig_fit.h"
#include "fa/scene/rig_glb.h"
#include "fa/scene/skeleton.h"

using namespace fa;

namespace {

Json J(const char* text) { return parse_json(text, "test").value(); }

ModelBuild build(const char* text) {
    auto doc = parse_model_doc(J(text), "t.model.json");
    REQUIRE_MESSAGE(doc.ok(), (doc.ok() ? std::string() : doc.error().to_string()));
    auto b = evaluate_model(*doc);
    REQUIRE_MESSAGE(b.ok(), (b.ok() ? std::string() : b.error().to_string()));
    return std::move(*b);
}

RigDoc rig(const char* text) {
    std::vector<RigIssue> issues;
    auto d = parse_rig_doc(J(text), "t.rig.json", &issues);
    REQUIRE_MESSAGE(d.ok(), (d.ok() ? std::string() : d.error().to_string()));
    return *d;
}

RigFit fitted(const char* model, const char* rigJson) {
    ModelBuild b = build(model);
    auto f = fit_rig(rig(rigJson), b.data);
    REQUIRE_MESSAGE(f.ok(), (f.ok() ? std::string() : f.error().to_string()));
    return std::move(*f);
}

std::string error_of(const char* model, const char* rigJson) {
    ModelBuild b = build(model);
    auto f = fit_rig(rig(rigJson), b.data);
    REQUIRE_FALSE(f.ok());
    return f.error().to_string();
}

// The joint `bone` is at (x, y, z) within `tol`; the tail too when `tail` is given.
void joint(const RigFit& f, const char* bone, float x, float y, float z, float tol = 0.01f) {
    const int i = f.find(bone);
    REQUIRE_MESSAGE(i >= 0, bone);
    const Vec3 h = f.bones[std::size_t(i)].head;
    INFO(bone << " head is " << h.x << " " << h.y << " " << h.z);
    CHECK(std::fabs(h.x - x) <= tol);
    CHECK(std::fabs(h.y - y) <= tol);
    CHECK(std::fabs(h.z - z) <= tol);
}
void tail_of(const RigFit& f, const char* bone, float x, float y, float z, float tol = 0.01f) {
    const int i = f.find(bone);
    REQUIRE_MESSAGE(i >= 0, bone);
    const Vec3 t = f.bones[std::size_t(i)].tail;
    INFO(bone << " tail is " << t.x << " " << t.y << " " << t.z);
    CHECK(std::fabs(t.x - x) <= tol);
    CHECK(std::fabs(t.y - y) <= tol);
    CHECK(std::fabs(t.z - z) <= tol);
}
bool mentions(const std::vector<std::string>& v, const char* needle) {
    for (const std::string& s : v)
        if (s.find(needle) != std::string::npos) return true;
    return false;
}

// a 1.9 m person in T pose made of boxes
const char* kPerson = R"({"format":"factoria.model/1","nodes":[
  {"op":"box","size":[0.36,0.2,0.2],"position":[0,0.95,0],"part":"pelvis"},
  {"op":"box","size":[0.4,0.5,0.22],"position":[0,1.3,0],"part":"torso"},
  {"op":"box","size":[0.1,0.1,0.1],"position":[0,1.6,0],"part":"neck"},
  {"op":"box","size":[0.22,0.25,0.22],"position":[0,1.77,0.02],"part":"head"},
  {"op":"box","size":[0.7,0.1,0.1],"position":[0.55,1.5,0],"part":"arm_l"},
  {"op":"box","size":[0.7,0.1,0.1],"position":[-0.55,1.5,0],"part":"arm_r"},
  {"op":"box","size":[0.14,0.9,0.14],"position":[0.11,0.45,0],"part":"leg_l"},
  {"op":"box","size":[0.14,0.9,0.14],"position":[-0.11,0.45,0],"part":"leg_r"}]})";

// a dog-like animal looking towards +Z
const char* kDog = R"({"format":"factoria.model/1","nodes":[
  {"op":"box","size":[0.4,0.4,1.0],"position":[0,0.8,0],"part":"body"},
  {"op":"box","size":[0.15,0.3,0.15],"position":[0,1.0,0.6],"part":"neck"},
  {"op":"box","size":[0.25,0.25,0.35],"position":[0,1.1,0.85],"part":"head"},
  {"op":"box","size":[0.08,0.08,0.5],"position":[0,0.85,-0.75],"part":"tail"},
  {"op":"box","size":[0.1,0.6,0.1],"position":[0.15,0.3,0.4],"part":"foreleg_l"},
  {"op":"box","size":[0.1,0.6,0.1],"position":[-0.15,0.3,0.4],"part":"foreleg_r"},
  {"op":"box","size":[0.1,0.6,0.1],"position":[0.15,0.3,-0.4],"part":"hindleg_l"},
  {"op":"box","size":[0.1,0.6,0.1],"position":[-0.15,0.3,-0.4],"part":"hindleg_r"}]})";

// a bird with spread wings
const char* kBird = R"({"format":"factoria.model/1","nodes":[
  {"op":"box","size":[0.3,0.3,0.5],"position":[0,0.6,0],"part":"body"},
  {"op":"box","size":[0.1,0.3,0.1],"position":[0,0.85,0.3],"part":"neck"},
  {"op":"box","size":[0.15,0.15,0.15],"position":[0,1.05,0.35],"part":"head"},
  {"op":"box","size":[0.05,0.05,0.12],"position":[0,1.03,0.5],"part":"beak"},
  {"op":"box","size":[0.9,0.04,0.3],"position":[0.6,0.7,0],"part":"wing_l"},
  {"op":"box","size":[0.9,0.04,0.3],"position":[-0.6,0.7,0],"part":"wing_r"},
  {"op":"box","size":[0.15,0.04,0.35],"position":[0,0.6,-0.4],"part":"tail"},
  {"op":"box","size":[0.03,0.4,0.03],"position":[0.07,0.2,0],"part":"leg_l"},
  {"op":"box","size":[0.03,0.4,0.03],"position":[-0.07,0.2,0],"part":"leg_r"}]})";

// a snake-ish tail along -Z
const char* kTail = R"({"format":"factoria.model/1","nodes":[
  {"op":"box","size":[0.2,0.2,0.4],"position":[0,0.5,0.2],"part":"body"},
  {"op":"box","size":[0.1,0.1,2.0],"position":[0,0.5,-1.0],"part":"tail"}]})";
const char* kRod = R"({"format":"factoria.model/1","nodes":[{"op":"cylinder","radius":0.1,"height":3,"segments":12,"position":[0,1.5,0]}]})";
const char* kBlob = R"({"format":"factoria.model/1","nodes":[{"op":"box","size":[0.6,1.8,0.4],"position":[0,0.9,0]}]})";

}  // namespace


TEST_CASE("rig templates: the catalog, the canonical names and the bone counts") {
    std::vector<std::string> names;
    for (const RigTemplateInfo& t : rig_templates()) names.push_back(t.name);
    CHECK(names == std::vector<std::string>{"humanoid", "quadruped", "bird", "tail", "chain", "generic"});
    CHECK(find_rig_template("bird") != nullptr);
    CHECK(find_rig_template("dragon") == nullptr);

    auto count = [](const char* json) {
        const RigDoc d = rig(json);
        const auto bones = rig_template_bones(d);
        CHECK(bones.size() <= kRigMaxBones);
        CHECK(bones[0].name == "root");
        CHECK(bones[0].parent.empty());
        for (std::size_t i = 1; i < bones.size(); ++i) {
            bool parentBefore = false;
            for (std::size_t k = 0; k < i; ++k) parentBefore = parentBefore || bones[k].name == bones[i].parent;
            CHECK_MESSAGE(parentBefore, bones[i].name);
        }
        return bones.size();
    };
    CHECK(count(R"({"format":"factoria.rig/1","model":"a.model.json","template":"humanoid"})") == 22);
    CHECK(count(R"({"format":"factoria.rig/1","model":"a.model.json","template":"humanoid","options":{"spine":5,"neck":2,"tail":3,"toes":false}})") == 1 + 5 + 2 + 1 + 8 + 6 + 3);
    CHECK(count(R"({"format":"factoria.rig/1","model":"a.model.json","template":"quadruped"})") == 27);
    CHECK(count(R"({"format":"factoria.rig/1","model":"a.model.json","template":"bird"})") == 25);
    CHECK(count(R"({"format":"factoria.rig/1","model":"a.model.json","template":"tail","options":{"segments":7}})") == 8);
    CHECK(count(R"({"format":"factoria.rig/1","model":"a.model.json","template":"chain"})") == 7);

    // the index is there only when a role has more than one bone on a side; the sides are l and r
    const auto h = rig_template_bones(rig(R"({"format":"factoria.rig/1","model":"a.model.json","template":"humanoid"})"));
    auto has = [&](const char* n) {
        for (const auto& b : h)
            if (b.name == n) return true;
        return false;
    };
    CHECK(has("spine_1"));
    CHECK(has("neck"));
    CHECK_FALSE(has("neck_1"));
    CHECK(has("arm_upper_l"));
    CHECK(has("toe_r"));
    const auto t = rig_template_bones(rig(R"({"format":"factoria.rig/1","model":"a.model.json","template":"tail","options":{"segments":2}})"));
    CHECK(t.size() == 3);
    CHECK(t[1].name == "tail_1");
}

TEST_CASE("rig documents: every mistake is listed with a pointer, the fix and a suggestion") {
    std::vector<RigIssue> issues;
    auto bad = parse_rig_doc(J(R"({"format":"factoria.rig/1","model":"a.glb","template":"humanoyd","options":{"spine":99},"colour":1})"), "t.rig.json", &issues);
    CHECK_FALSE(bad.ok());
    CHECK(issues.size() >= 3);
    auto find = [&](const char* ptr) -> const RigIssue* {
        for (const RigIssue& i : issues)
            if (i.pointer == ptr) return &i;
        return nullptr;
    };
    REQUIRE(find("/template") != nullptr);
    CHECK(find("/template")->hint.find("humanoid") != std::string::npos);
    CHECK(find("/model") != nullptr);
    CHECK(find("/colour") != nullptr);

    issues.clear();
    auto badOption = parse_rig_doc(J(R"({"format":"factoria.rig/1","model":"a.model.json","template":"humanoid","options":{"spine":99}})"), "t.rig.json", &issues);
    CHECK_FALSE(badOption.ok());
    REQUIRE(find("/options/spine") != nullptr);

    issues.clear();
    auto badKey = parse_rig_doc(J(R"({"format":"factoria.rig/1","model":"a.model.json","template":"humanoid","options":{"spin":2}})"), "t.rig.json", &issues);
    CHECK_FALSE(badKey.ok());
    REQUIRE(find("/options/spin") != nullptr);
    CHECK(find("/options/spin")->hint.find("spine") != std::string::npos);

    // checks that need the template: names of bones in parts and landmarks
    RigDoc d = rig(R"({"format":"factoria.rig/1","model":"a.model.json","template":"humanoid","parts":{"arm_uper_l":["x"]},"landmarks":{"head.tail":[0,2,0],"hand.tail":[1,1,1]}})");
    const auto problems = rig_check_doc(d);
    bool sawName = false, sawTail = false;
    for (const RigIssue& i : problems) {
        if (i.pointer == "/parts/arm_uper_l") sawName = i.hint.find("arm_upper_l") != std::string::npos;
        if (i.pointer == "/landmarks/hand.tail") sawTail = true;
    }
    CHECK(sawName);
    CHECK(sawTail);

    // a document survives writing and reading
    RigDoc ok = rig(R"({"format":"factoria.rig/1","model":"a.model.json","template":"quadruped","options":{"tail":6},"parts":{"head":["skull"]},"landmarks":{"head":[0,1,1]},"strict":true})");
    RigDoc again = rig(dump_json(rig_doc_to_json(ok)).c_str());
    CHECK(dump_json(rig_doc_to_json(again)) == dump_json(rig_doc_to_json(ok)));
    CHECK(again.strict);
    CHECK(again.optionInt("tail", 0) == 6);
}

TEST_CASE("rig fit: a humanoid built of named parts") {
    const RigFit f = fitted(kPerson, R"({"format":"factoria.rig/1","model":"p.model.json","template":"humanoid"})");
    CHECK(f.bones.size() == 22);
    CHECK(f.estimated == 0);
    CHECK(f.warnings.empty());
    CHECK(f.unusedParts.empty());
    joint(f, "root", 0, 0.95f, 0);
    joint(f, "spine_1", 0, 1.1f, 0);
    joint(f, "spine_3", 0, 1.4f, 0);
    joint(f, "neck", 0, 1.55f, 0);
    joint(f, "head", 0, 1.645f, 0.02f);
    tail_of(f, "head", 0, 1.895f, 0.02f);
    joint(f, "arm_upper_l", 0.221f, 1.5f, 0);
    joint(f, "arm_lower_l", 0.55f, 1.5f, 0);
    joint(f, "hand_l", 0.83f, 1.5f, 0);
    tail_of(f, "hand_l", 0.9f, 1.5f, 0);
    joint(f, "arm_upper_r", -0.221f, 1.5f, 0);
    joint(f, "hand_r", -0.83f, 1.5f, 0);
    joint(f, "thigh_l", 0.11f, 0.882f, 0);
    joint(f, "foot_l", 0.11f, 0.063f, 0);
    joint(f, "toe_l", 0.11f, 0.022f, 0);
    tail_of(f, "toe_l", 0.11f, 0, 0);
    joint(f, "thigh_r", -0.11f, 0.882f, 0);
    // character-left is +X: the left bones are on the +X side, the right ones mirror them
    for (const RigBoneFit& b : f.bones) {
        if (b.side == "l") CHECK(b.head.x > 0);
        if (b.side == "r") CHECK(b.head.x < 0);
        if (b.parentIndex >= 0) CHECK(b.parentIndex < int(&b - f.bones.data()));
    }
    CHECK(f.bones[std::size_t(f.find("head"))].headSource == RigSource::Part);
    CHECK(f.fromParts > 0);
    CHECK(f.symmetrySource == "bounds");
}

TEST_CASE("rig fit: a humanoid with no parts is estimated and says so; strict refuses it") {
    const RigFit f = fitted(kBlob, R"({"format":"factoria.rig/1","model":"p.model.json","template":"humanoid"})");
    CHECK(f.estimated > 10);
    CHECK(mentions(f.warnings, "no named parts"));
    joint(f, "head", 0, 1.566f, 0);
    tail_of(f, "head", 0, 1.8f, 0);  // the top of the head is measured, not estimated
    CHECK(f.bones[std::size_t(f.find("head"))].tailSource == RigSource::Geometry);
    CHECK(f.bones[std::size_t(f.find("hand_l"))].headSource == RigSource::Proportion);

    const std::string err = error_of(kBlob, R"({"format":"factoria.rig/1","model":"p.model.json","template":"humanoid","strict":true})");
    CHECK(err.find("strict") != std::string::npos);
    CHECK(err.find("landmarks") != std::string::npos);
}

TEST_CASE("rig fit: landmarks override the fit, and a wrong name is explained") {
    const RigFit f = fitted(kPerson, R"({"format":"factoria.rig/1","model":"p.model.json","template":"humanoid","landmarks":{"neck":[0,1.6,0.05],"head.tail":[0,2,0.02]}})");
    joint(f, "neck", 0, 1.6f, 0.05f);
    tail_of(f, "head", 0, 2.0f, 0.02f);
    CHECK(f.bones[std::size_t(f.find("neck"))].headSource == RigSource::Override);
    CHECK(f.overrides == 2);
    CHECK(f.bones[std::size_t(f.find("head"))].parts.size() == 1);

    const std::string err = error_of(kPerson, R"({"format":"factoria.rig/1","model":"p.model.json","template":"humanoid","landmarks":{"nek":[0,1.6,0]}})");
    CHECK(err.find("/landmarks/nek") != std::string::npos);
    CHECK(err.find("neck") != std::string::npos);
}

TEST_CASE("rig fit: `parts` names the model parts of a bone, a missing part is a did-you-mean") {
    // the head bone is told to follow the neck and head parts together: its tail is still the top of the head
    const RigFit f = fitted(kPerson, R"({"format":"factoria.rig/1","model":"p.model.json","template":"humanoid","parts":{"head":["neck","head"]}})");
    tail_of(f, "head", 0, 1.895f, 0.02f);
    joint(f, "head", 0, 1.55f, 0.01f, 0.1f);
    const std::string err = error_of(kPerson, R"({"format":"factoria.rig/1","model":"p.model.json","template":"humanoid","parts":{"head":["hed"]}})");
    CHECK(err.find("hed") != std::string::npos);
    CHECK(err.find("head") != std::string::npos);
}

TEST_CASE("rig fit: a quadruped looks towards +Z, its legs and tail follow their parts") {
    const RigFit f = fitted(kDog, R"({"format":"factoria.rig/1","model":"p.model.json","template":"quadruped"})");
    CHECK(f.bones.size() == 27);
    CHECK(f.estimated == 0);
    joint(f, "root", 0, 0.8f, -0.3f);
    joint(f, "spine_3", 0, 0.8375f, 0.375f);
    joint(f, "neck_1", 0, 0.85f, 0.6f);
    joint(f, "head", 0, 1.1f, 0.675f);
    tail_of(f, "head", 0, 1.1f, 1.025f);
    joint(f, "arm_upper_l", 0.15f, 0.582f, 0.4f);
    joint(f, "hand_l", 0.15f, 0.06f, 0.4f);
    tail_of(f, "hand_l", 0.15f, 0, 0.4f);
    joint(f, "thigh_l", 0.15f, 0.588f, -0.4f);
    joint(f, "foot_r", -0.15f, 0.15f, -0.4f);
    joint(f, "tail_1", 0, 0.85f, -0.5f);
    tail_of(f, "tail_4", 0, 0.85f, -1.0f);
    // fewer tail bones are shorter segments of the same tail
    const RigFit s = fitted(kDog, R"({"format":"factoria.rig/1","model":"p.model.json","template":"quadruped","options":{"tail":2,"neck":1,"spine":1}})");
    tail_of(s, "tail_2", 0, 0.85f, -1.0f);
    joint(s, "tail_2", 0, 0.85f, -0.75f);
    CHECK(s.bones.size() == 1 + 1 + 1 + 1 + 8 + 8 + 2);
}

TEST_CASE("rig fit: a bird picks the pose of its wings") {
    const RigFit f = fitted(kBird, R"({"format":"factoria.rig/1","model":"p.model.json","template":"bird"})");
    CHECK(f.bones.size() == 25);
    joint(f, "arm_upper_l", 0.177f, 0.7f, 0);
    joint(f, "hand_l", 0.96f, 0.7f, 0);
    tail_of(f, "hand_l", 1.05f, 0.7f, 0);
    tail_of(f, "head", 0, 1.03f, 0.56f);
    joint(f, "tail_1", 0, 0.6f, -0.225f);
    tail_of(f, "tail_2", 0, 0.6f, -0.575f);
    joint(f, "thigh_r", -0.07f, 0.392f, 0);
    const RigFit g = fitted(kBird, R"({"format":"factoria.rig/1","model":"p.model.json","template":"bird","options":{"pose":"spread"}})");
    joint(g, "hand_l", 0.96f, 0.7f, 0);
}

TEST_CASE("rig fit: a tail and a chain split a stretch of the model into equal segments") {
    const RigFit t = fitted(kTail, R"({"format":"factoria.rig/1","model":"p.model.json","template":"tail","options":{"segments":4}})");
    CHECK(t.bones.size() == 5);
    joint(t, "root", 0, 0.5f, 0);
    joint(t, "tail_1", 0, 0.5f, 0);
    joint(t, "tail_3", 0, 0.5f, -1.0f);
    tail_of(t, "tail_4", 0, 0.5f, -2.0f);
    CHECK(mentions(t.warnings, "body"));  // the body part belongs to no bone and the fit says so

    const RigFit c = fitted(kRod, R"({"format":"factoria.rig/1","model":"p.model.json","template":"chain","options":{"segments":3}})");
    joint(c, "chain_1", 0, 3, 0);
    joint(c, "chain_2", 0, 2, 0);
    tail_of(c, "chain_3", 0, 0, 0);
    CHECK(c.bones[1].headSource == RigSource::Geometry);
    CHECK(c.estimated == 0);
    const RigFit x = fitted(kRod, R"({"format":"factoria.rig/1","model":"p.model.json","template":"chain","options":{"segments":3,"axis":"+y"},"strict":true})");
    joint(x, "chain_1", 0, 0, 0);
    tail_of(x, "chain_3", 0, 3, 0);
}

TEST_CASE("rig fit: a generic rig places its own bones on the parts they move") {
    const char* doc = R"({"format":"factoria.rig/1","model":"p.model.json","template":"generic","bones":[
        {"name":"hips","part":"pelvis","anchor":[0,0,0]},
        {"name":"chest","parent":"hips","part":"torso","anchor":[0,-1,0],"tailAnchor":[0,1,0]},
        {"name":"skull","parent":"chest","role":"head","part":"head","anchor":[0,-1,0]}]})";
    const RigFit f = fitted(kPerson, doc);
    CHECK(f.bones.size() == 4);
    CHECK(f.bones[0].name == "root");
    joint(f, "hips", 0, 0.95f, 0);
    joint(f, "chest", 0, 1.05f, 0);
    joint(f, "skull", 0, 1.645f, 0.02f);
    CHECK(f.bones[std::size_t(f.find("skull"))].role == "head");
    CHECK(f.bones[std::size_t(f.find("hips"))].role == "hips");
    joint(f, "root", 0, 0, 0);

    const std::string err = error_of(kPerson, R"({"format":"factoria.rig/1","model":"p.model.json","template":"generic","bones":[{"name":"hips","part":"pelvs"}]})");
    CHECK(err.find("pelvs") != std::string::npos);
    CHECK(err.find("pelvis") != std::string::npos);
}

TEST_CASE("rig fit: a creature made of SDF shapes fits the quadruped") {
    const char* creature = R"({"format":"factoria.model/1","nodes":[
      {"op":"sdf","id":"c","targetTriangles":4000,"children":[
        {"op":"sdf_ellipsoid","radii":[0.25,0.22,0.5],"position":[0,0.7,0],"part":"body"},
        {"op":"sdf_sphere","radius":0.18,"position":[0,0.95,0.6],"smooth":0.05,"part":"head"},
        {"op":"sdf_capsule","radius":0.05,"height":0.55,"position":[0.15,0.28,0.35],"part":"foreleg_l"},
        {"op":"sdf_capsule","radius":0.05,"height":0.55,"position":[-0.15,0.28,0.35],"part":"foreleg_r"},
        {"op":"sdf_capsule","radius":0.05,"height":0.55,"position":[0.15,0.28,-0.35],"part":"hindleg_l"},
        {"op":"sdf_capsule","radius":0.05,"height":0.55,"position":[-0.15,0.28,-0.35],"part":"hindleg_r"},
        {"op":"sdf_capsule","radius":0.04,"height":0.5,"position":[0,0.7,-0.75],"rotation":[90,0,0],"part":"tail"}]}]})";
    const RigFit f = fitted(creature, R"({"format":"factoria.rig/1","model":"p.model.json","template":"quadruped"})");
    CHECK(f.estimated == 0);
    const auto at = [&](const char* n) { return f.bones[std::size_t(f.find(n))].head; };
    CHECK(at("head").z > 0.4f);
    CHECK(at("head").y > 0.7f);
    CHECK(at("root").z < 0);
    CHECK(at("arm_upper_l").x > 0.05f);
    CHECK(at("arm_upper_r").x < -0.05f);
    CHECK(at("arm_upper_l").z > 0.2f);
    CHECK(at("thigh_l").z < -0.2f);
    CHECK(at("hand_l").y < 0.15f);
    CHECK(at("tail_1").z < -0.4f);
    CHECK(f.bones[std::size_t(f.find("tail_4"))].tail.z < -0.9f);
}

TEST_CASE("rig fit: the same document and model give the same joints") {
    const RigFit a = fitted(kDog, R"({"format":"factoria.rig/1","model":"p.model.json","template":"quadruped"})");
    const RigFit b = fitted(kDog, R"({"format":"factoria.rig/1","model":"p.model.json","template":"quadruped"})");
    CHECK(dump_json(rig_fit_to_json(a)) == dump_json(rig_fit_to_json(b)));
}

TEST_CASE("rig glb: the skeleton is a glTF skin that loads back and rests in the model's pose") {
    ModelBuild b = build(kPerson);
    auto doc = rig(R"({"format":"factoria.rig/1","model":"p.model.json","template":"humanoid"})");
    auto fit = fit_rig(doc, b.data);
    REQUIRE(fit.ok());
    auto bytes = rig_to_glb(b.data, *fit, "person.rig.glb");
    REQUIRE_MESSAGE(bytes.ok(), (bytes.ok() ? std::string() : bytes.error().to_string()));
    auto sk = parse_skeleton(*bytes, "person.rig.glb");
    REQUIRE_MESSAGE(sk.ok(), (sk.ok() ? std::string() : sk.error().to_string()));
    REQUIRE(sk->skins.size() == 1);
    const SkelSkin& skin = sk->skins[0];
    CHECK(skin.joints.size() == fit->bones.size());
    CHECK(skin.joints.size() <= kRigMaxBones);
    CHECK(skin.inverseBind.size() == skin.joints.size());
    for (std::size_t i = 0; i < skin.joints.size(); ++i) {
        const Vec3 h = fit->bones[i].head;
        // inverse bind = translate(-head): the joint's own position takes the vertex to the origin
        CHECK(skin.inverseBind[i].m[12] == doctest::Approx(-h.x).epsilon(1e-5).scale(1));
        CHECK(skin.inverseBind[i].m[13] == doctest::Approx(-h.y).epsilon(1e-5).scale(1));
        CHECK(skin.inverseBind[i].m[14] == doctest::Approx(-h.z).epsilon(1e-5).scale(1));
        CHECK(sk->nodes[std::size_t(skin.joints[i])].name == fit->bones[i].name);
    }
    // every vertex follows exactly one bone with weight 1
    REQUIRE(sk->skinVertices.size() >= 1);
    std::size_t verts = 0;
    for (const SkinVertices& sv : sk->skinVertices) {
        CHECK(sv.skin == 0);
        CHECK_FALSE(sv.rigid);
        for (std::size_t v = 0; v < sv.joints.size(); ++v) {
            CHECK(sv.weights[v][0] == doctest::Approx(1.0f));
            CHECK(sv.weights[v][1] == 0.0f);
            CHECK(sv.joints[v][0] < skin.joints.size());
        }
        verts += sv.joints.size();
    }
    // every primitive of the mesh (one per part) shares the vertex buffer, and each has the joints of all of them
    CHECK(verts == (b.data.positions.size() / 3) * sk->skinVertices.size());
    // rest pose: every joint matrix is the identity, so the model draws unchanged
    const auto palette = skin_palette(*sk, rest_pose(*sk), 0);
    REQUIRE(palette.size() == skin.joints.size());
    for (const Mat4& m : palette)
        for (int k = 0; k < 16; ++k) CHECK(m.m[k] == doctest::Approx((k % 5 == 0) ? 1.0f : 0.0f).scale(1).epsilon(1e-4));
    const auto bind = rig_rigid_binding(*fit, b.data);
    CHECK(bind.size() == b.data.positions.size() / 3);
    // the legs follow leg bones, the head follows the head
    for (const MeshSubmesh& sm : b.data.submeshes) {
        if (sm.part != "head") continue;
        const std::uint32_t first = b.data.indices[sm.start];
        CHECK(fit->bones[bind[first]].name == "head");
    }
}

TEST_CASE("rig: no template reaches the renderer's 64 joints, and a generic rig over the limit is refused with the fix") {
    CHECK(rig_template_bones(rig(R"({"format":"factoria.rig/1","model":"a.model.json","template":"humanoid","options":{"spine":5,"neck":3,"tail":12}})")).size() == 38);
    CHECK(rig_template_bones(rig(R"({"format":"factoria.rig/1","model":"a.model.json","template":"tail","options":{"segments":32}})")).size() == 33);

    Json bones = Json::array();
    for (int i = 0; i < 64; ++i) bones.push_back(Json::object({{"name", "b" + std::to_string(i)}}));
    Json j = J(R"({"format":"factoria.rig/1","model":"a.model.json","template":"generic"})");
    j["bones"] = bones;  // 64 bones and the root: one too many
    std::vector<RigIssue> issues;
    auto d = parse_rig_doc(j, "t.rig.json", &issues);
    bool refused = !d.ok();
    if (d.ok()) refused = !rig_check_doc(*d).empty();
    CHECK(refused);
}
