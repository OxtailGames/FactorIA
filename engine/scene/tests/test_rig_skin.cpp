// Skin weights of a rig (docs/RIGGING.md, "Skin weights"): the document's `skin` section, the automatic weights on models the engine makes, the edits.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <map>
#include <set>

#include "fa/scene/model_doc.h"
#include "fa/scene/rig_doc.h"
#include "fa/scene/rig_fit.h"
#include "fa/scene/rig_glb.h"
#include "fa/scene/rig_skin.h"
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

RigDoc rig(const std::string& text) {
    std::vector<RigIssue> issues;
    auto d = parse_rig_doc(J(text.c_str()), "t.rig.json", &issues);
    REQUIRE_MESSAGE(d.ok(), (d.ok() ? std::string() : d.error().to_string()));
    return *d;
}

// A model, its fit and its weights.
struct Skinned {
    ModelBuild build;
    RigDoc doc;
    RigFit fit;
    RigSkinResult skin;
    const MeshData& mesh() const { return build.data; }
    Vec3 pos(std::size_t v) const {
        return {mesh().positions[v * 3], mesh().positions[v * 3 + 1], mesh().positions[v * 3 + 2]};
    }
    float weight_on(std::size_t v, const char* bone) const {
        const int b = fit.find(bone);
        float s = 0;
        for (int k = 0; k < 4; ++k)
            if (skin.weights.joints[v * 4 + std::size_t(k)] == b) s += skin.weights.weights[v * 4 + std::size_t(k)];
        return s;
    }
    int strongest(std::size_t v) const { return skin.weights.joints[v * 4]; }
    std::string strongest_name(std::size_t v) const { return fit.bones[std::size_t(strongest(v))].name; }
};

Skinned skinned(const char* model, const std::string& rigJson) {
    Skinned s;
    s.build = build(model);
    s.doc = rig(rigJson);
    auto f = fit_rig(s.doc, s.build.data);
    REQUIRE_MESSAGE(f.ok(), (f.ok() ? std::string() : f.error().to_string()));
    s.fit = std::move(*f);
    auto r = compute_rig_skin(s.doc.skin, s.fit, s.build.data);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().to_string()));
    s.skin = std::move(*r);
    return s;
}

std::string humanoid_rig(const std::string& skin = "") {
    return R"({"format":"factoria.rig/1","model":"p.model.json","template":"humanoid")" +
           (skin.empty() ? std::string() : ",\"skin\":" + skin) + "}";
}

// A person in T pose made of boxes with enough segments to bend
const char* kPerson = R"({"format":"factoria.model/1","nodes":[
  {"op":"box","size":[0.36,0.2,0.2],"position":[0,0.95,0],"part":"pelvis","segments":[3,2,2]},
  {"op":"box","size":[0.4,0.5,0.22],"position":[0,1.3,0],"part":"torso","segments":[4,6,2]},
  {"op":"box","size":[0.1,0.1,0.1],"position":[0,1.6,0],"part":"neck","segments":[2,2,2]},
  {"op":"box","size":[0.22,0.25,0.22],"position":[0,1.77,0.02],"part":"head","segments":[3,3,3]},
  {"op":"box","size":[0.7,0.1,0.1],"position":[0.55,1.5,0],"part":"arm_l","segments":[10,2,2]},
  {"op":"box","size":[0.7,0.1,0.1],"position":[-0.55,1.5,0],"part":"arm_r","segments":[10,2,2]},
  {"op":"box","size":[0.14,0.9,0.14],"position":[0.11,0.45,0],"part":"leg_l","segments":[2,10,2]},
  {"op":"box","size":[0.14,0.9,0.14],"position":[-0.11,0.45,0],"part":"leg_r","segments":[2,10,2]}]})";

bool near_mirror(Vec3 a, Vec3 b, float tol) {
    return std::fabs(a.x + b.x) < tol && std::fabs(a.y - b.y) < tol && std::fabs(a.z - b.z) < tol;
}

void check_valid(const Skinned& s) {
    const RigWeights& w = s.skin.weights;
    REQUIRE(w.vertex_count() == s.mesh().vertex_count());
    for (std::size_t v = 0; v < w.vertex_count(); ++v) {
        float sum = 0;
        for (int k = 0; k < 4; ++k) {
            const float x = w.weights[v * 4 + std::size_t(k)];
            CHECK(x >= 0);
            if (k > 0) CHECK(x <= w.weights[v * 4 + std::size_t(k) - 1] + 1e-6f);
            if (x > 0) CHECK(w.joints[v * 4 + std::size_t(k)] < s.fit.bones.size());
            sum += x;
        }
        REQUIRE(sum == doctest::Approx(1.0f).epsilon(1e-5));
    }
}

}  // namespace

TEST_CASE("rig skin document: the section parses, writes back without its defaults, and every mistake is explained") {
    RigDoc d = rig(humanoid_rig(
        R"({"method":"heat","maxInfluences":3,"smooth":2,"parts":{"torso":{"method":"rigid","bone":"spine_1"}},"edits":[
        {"op":"set","bone":"hand_l","weight":0.8,"part":"arm_l"},{"op":"smooth","iterations":3,"part":["arm_l","arm_r"]},{"op":"mirror","from":"l"},{"op":"limit","max":2},
        {"op":"normalize","threshold":0.05},{"op":"add","bone":"head","amount":-0.2}]})"));
    CHECK(d.skin.method == "heat");
    CHECK(d.skin.maxInfluences == 3);
    REQUIRE(d.skin.edits.size() == 6);
    CHECK(d.skin.edits[0].parts == std::vector<std::string>{"arm_l"});
    CHECK(d.skin.edits[0].pointer == "/skin/edits/0");
    CHECK(d.skin.edits[1].parts.size() == 2);
    CHECK(d.skin.edits[2].from == "l");
    CHECK(d.skin.parts[0].second.bone == "spine_1");
    const Json back = rig_doc_to_json(d);
    CHECK(back["skin"]["edits"].size() == 6);
    CHECK(back["skin"]["maxInfluences"] == 3);
    CHECK_FALSE(rig_doc_to_json(rig(humanoid_rig())).contains("skin"));

    auto bad = [](const std::string& skin) {
        std::vector<RigIssue> issues;
        auto r = parse_rig_doc(J(humanoid_rig(skin).c_str()), "t.rig.json", &issues);
        std::string all = r.ok() ? std::string() : r.error().to_string();
        for (const RigIssue& i : issues) all += i.pointer + " " + i.message + " " + i.hint + "\n";
        if (r.ok()) {
            for (const RigIssue& i : rig_check_doc(*r)) all += i.pointer + " " + i.message + " " + i.hint + "\n";
        }
        return all;
    };
    CHECK(bad(R"({"method":"heet"})").find("heat") != std::string::npos);
    CHECK(bad(R"({"maxInfluences":9})").find("/skin/maxInfluences") != std::string::npos);
    CHECK(bad(R"({"edits":[{"op":"sett","bone":"head"}]})").find("set") != std::string::npos);
    CHECK(bad(R"({"edits":[{"op":"set"}]})").find("bone") != std::string::npos);
    CHECK(bad(R"({"edits":[{"op":"set","bone":"hnad_l"}]})").find("hand_l") != std::string::npos);
    CHECK(bad(R"({"edits":[{"op":"mirror"}]})").find("from") != std::string::npos);
    CHECK(bad(R"({"parts":{"arm_l":{"bone":"arm_uper_l"}}})").find("arm_upper_l") != std::string::npos);
    CHECK(bad(R"({"edits":[{"op":"set","bone":"head","select":{"by":"nope"}}]})").find("/skin/edits/0/select") !=
          std::string::npos);
    // the old field is explained
    std::vector<RigIssue> issues;
    auto old = parse_rig_doc(
        J(R"({"format":"factoria.rig/1","model":"p.model.json","template":"humanoid","binding":"rigid"})"),
        "t.rig.json", &issues);
    std::string text = old.ok() ? std::string() : old.error().to_string();
    for (const RigIssue& i : issues) text += i.message + " " + i.hint;
    CHECK(text.find("skin") != std::string::npos);
}

TEST_CASE("rig skin: a humanoid of boxes gets local, normalised, smooth weights") {
    const Skinned s = skinned(kPerson, humanoid_rig());
    check_valid(s);
    const RigSkinReport& r = s.skin.report;
    CHECK(r.unweighted == 0);
    CHECK(r.farBlends == 0);
    CHECK(r.maxInfluences <= 4);
    CHECK(r.heatFailed == 0);
    CHECK(r.meanInfluences > 1.0);  // blended, not rigid
    int arm = 0, leg = 0, blended = 0;
    for (std::size_t v = 0; v < s.mesh().vertex_count(); ++v) {
        const Vec3 p = s.pos(v);
        // locality: an arm vertex is not weighted to a leg or the other arm, and the other way round
        if (p.y > 1.4f && p.x > 0.35f) {
            ++arm;
            for (const char* bone :
                 {"thigh_l", "shin_l", "foot_l", "thigh_r", "arm_upper_r", "arm_lower_r", "hand_r", "head"})
                CHECK(s.weight_on(v, bone) == 0.0f);
            CHECK(s.strongest_name(v).find("_l") != std::string::npos);
        }
        if (p.y < 0.8f) {
            ++leg;
            for (const char* bone : {"arm_upper_l", "arm_lower_l", "hand_l", "arm_upper_r", "hand_r", "head", "neck"})
                CHECK(s.weight_on(v, bone) == 0.0f);
        }
        if (s.skin.weights.weights[v * 4 + 1] > 0.05f) ++blended;
    }
    CHECK(arm > 20);
    CHECK(leg > 20);
    CHECK(blended > 20);
    // the tip of the hand follows the hand, the tip of the foot the foot or toe, the top of the head the head
    for (std::size_t v = 0; v < s.mesh().vertex_count(); ++v) {
        const Vec3 p = s.pos(v);
        if (p.x > 0.89f) CHECK(s.weight_on(v, "hand_l") > 0.6f);
        if (p.y > 1.88f) CHECK(s.weight_on(v, "head") > 0.8f);
    }
    // the parts of the report
    CHECK(r.parts.size() == 8);
    for (const RigSkinPartReport& p : r.parts) CHECK(p.method == "heat");
    CHECK(s.skin.report.boneVertices.size() == s.fit.bones.size());
}

TEST_CASE("rig skin: the same input gives the same bits, and the .glb stores the weights") {
    const Skinned a = skinned(kPerson, humanoid_rig());
    const Skinned b = skinned(kPerson, humanoid_rig());
    REQUIRE(a.skin.weights.joints == b.skin.weights.joints);
    REQUIRE(a.skin.weights.weights.size() == b.skin.weights.weights.size());
    CHECK(std::memcmp(a.skin.weights.weights.data(), b.skin.weights.weights.data(),
                      a.skin.weights.weights.size() * 4) == 0);

    auto bytes = rig_to_glb(a.mesh(), a.fit, "person.rig.glb", &a.skin.weights);
    REQUIRE_MESSAGE(bytes.ok(), (bytes.ok() ? std::string() : bytes.error().to_string()));
    auto sk = parse_skeleton(*bytes, "person.rig.glb");
    REQUIRE_MESSAGE(sk.ok(), (sk.ok() ? std::string() : sk.error().to_string()));
    REQUIRE(!sk->skinVertices.empty());
    const SkinVertices& sv = sk->skinVertices[0];
    REQUIRE(sv.joints.size() == a.mesh().vertex_count());
    std::size_t multi = 0;
    for (std::size_t v = 0; v < sv.joints.size(); ++v) {
        float sum = 0;
        for (int k = 0; k < 4; ++k) {
            sum += sv.weights[v][std::size_t(k)];
            CHECK(sv.weights[v][std::size_t(k)] == doctest::Approx(a.skin.weights.weights[v * 4 + std::size_t(k)]));
            CHECK(sv.joints[v][std::size_t(k)] == a.skin.weights.joints[v * 4 + std::size_t(k)]);
        }
        CHECK(sum == doctest::Approx(1.0f).epsilon(1e-5));
        if (sv.weights[v][1] > 0) ++multi;
    }
    CHECK(multi > 20);
}

TEST_CASE("rig skin: bending a bone moves its limb and nothing else, and the joint stays closed") {
    const Skinned s = skinned(kPerson, humanoid_rig());
    const int elbow = s.fit.find("arm_lower_l");
    REQUIRE(elbow >= 0);
    const std::vector<float> posed =
        rig_skin_pose(s.fit, s.skin.weights, s.mesh().positions, {{elbow, {0, 0, 0}, 60.0f}});
    REQUIRE(posed.size() == s.mesh().positions.size());
    const Vec3 head = s.fit.bones[std::size_t(elbow)].head;
    float handMoved = 0;
    for (std::size_t v = 0; v < s.mesh().vertex_count(); ++v) {
        const Vec3 p = s.pos(v);
        const Vec3 q{posed[v * 3], posed[v * 3 + 1], posed[v * 3 + 2]};
        REQUIRE(std::isfinite(q.x + q.y + q.z));
        const float moved = length(q - p);
        if (p.x < 0.1f || p.y < 1.2f) CHECK(moved == 0.0f);  // body, legs, other arm: not touched
        if (p.x > 0.85f) {
            // the tip of the hand turns about the elbow almost rigidly
            CHECK(moved > 0.3f);
            CHECK(length(q - head) == doctest::Approx(length(p - head)).epsilon(0.08));
            handMoved = std::max(handMoved, moved);
        }
        // nothing flies off: a vertex never ends further from where it was than the bone's reach
        CHECK(moved < 1.0f);
        if (p.x > 0.3f && p.x < 0.45f) CHECK(moved < 0.35f);  // the blend near the joint is partial, never a gap
    }
    CHECK(handMoved > 0.3f);
    // no pose: unchanged
    const std::vector<float> rest = rig_skin_pose(s.fit, s.skin.weights, s.mesh().positions, {});
    for (std::size_t i = 0; i < rest.size(); ++i)
        CHECK(rest[i] == doctest::Approx(s.mesh().positions[i]).epsilon(1e-5).scale(1));
    CHECK(rig_bone_hops(s.fit, elbow, s.fit.find("hand_l")) == 1);
    CHECK(rig_bone_hops(s.fit, s.fit.find("hand_l"), s.fit.find("hand_r")) > 2);
}

TEST_CASE("rig skin: the voxel method gives local weights too") {
    const Skinned s = skinned(kPerson, humanoid_rig(R"({"method":"voxel"})"));
    check_valid(s);
    CHECK(s.skin.report.unweighted == 0);
    CHECK(s.skin.report.farBlends == 0);
    for (const RigSkinPartReport& p : s.skin.report.parts) CHECK(p.method == "voxel");
    for (std::size_t v = 0; v < s.mesh().vertex_count(); ++v) {
        const Vec3 p = s.pos(v);
        if (p.y < 0.8f)
            for (const char* bone : {"arm_upper_l", "hand_l", "arm_upper_r", "hand_r", "head"})
                CHECK(s.weight_on(v, bone) == 0.0f);
        if (p.x > 0.89f) CHECK(s.weight_on(v, "hand_l") > 0.5f);
    }
}

TEST_CASE("rig skin: a robot's parts are rigid, one bone each, and the part to bone mapping can be overridden") {
    const char* robot = R"({"format":"factoria.model/1","nodes":[
      {"op":"box","size":[0.4,0.3,0.3],"position":[0,1.0,0],"part":"hips"},
      {"op":"box","size":[0.5,0.6,0.3],"position":[0,1.5,0],"part":"chest"},
      {"op":"box","size":[0.3,0.3,0.3],"position":[0,2.0,0],"part":"head"},
      {"op":"box","size":[0.5,0.15,0.15],"position":[0.5,1.6,0],"part":"upper_arm"},
      {"op":"box","size":[0.5,0.12,0.12],"position":[1.0,1.6,0],"part":"fore_arm"}]})";
    const char* generic = R"({"format":"factoria.rig/1","model":"p.model.json","template":"generic","bones":[
        {"name":"hips","part":"hips","anchor":[0,0,0]},
        {"name":"chest","parent":"hips","part":"chest","anchor":[0,-1,0],"tailAnchor":[0,1,0]},
        {"name":"skull","parent":"chest","role":"head","part":"head","anchor":[0,-1,0]},
        {"name":"arm_upper_l","parent":"chest","part":"upper_arm","anchor":[-1,0,0],"tailAnchor":[1,0,0]},
        {"name":"arm_lower_l","parent":"arm_upper_l","part":"fore_arm","anchor":[-1,0,0],"tailAnchor":[1,0,0]}])";
    const Skinned s = skinned(robot, generic + std::string("}"));
    check_valid(s);
    CHECK(s.skin.report.farBlends == 0);
    for (const RigSkinPartReport& p : s.skin.report.parts) CHECK(p.method == "rigid");
    for (std::size_t v = 0; v < s.mesh().vertex_count(); ++v) {
        CHECK(s.skin.weights.weights[v * 4] == 1.0f);
        CHECK(s.skin.weights.weights[v * 4 + 1] == 0.0f);
    }
    // every vertex of a part follows the same bone: the one that moves it
    std::map<std::string, std::set<int>> boneOfPart;
    for (const MeshSubmesh& sm : s.mesh().submeshes)
        for (std::uint32_t i = sm.start; i < sm.start + sm.count; ++i)
            boneOfPart[sm.part].insert(s.strongest(s.mesh().indices[i]));
    for (const auto& [part, bones] : boneOfPart) CHECK_MESSAGE(bones.size() == 1, part);
    CHECK(s.fit.bones[std::size_t(*boneOfPart["head"].begin())].name == "skull");
    CHECK(s.fit.bones[std::size_t(*boneOfPart["fore_arm"].begin())].name == "arm_lower_l");
    // overriding the bone of a part, and blending a part with heat
    const Skinned o = skinned(
        robot, generic + std::string(R"(,"skin":{"parts":{"head":{"bone":"chest"},"chest":{"method":"heat"}}})") + "}");
    check_valid(o);
    for (const MeshSubmesh& sm : o.mesh().submeshes)
        if (sm.part == "head")
            for (std::uint32_t i = sm.start; i < sm.start + sm.count; ++i)
                CHECK(o.strongest_name(o.mesh().indices[i]) == "chest");
    bool blended = false;
    for (const RigSkinPartReport& p : o.skin.report.parts) {
        if (p.part == "head") CHECK(p.method == "rigid");
        if (p.part == "chest") CHECK(p.method == "heat");
    }
    for (const MeshSubmesh& sm : o.mesh().submeshes)
        if (sm.part == "chest")
            for (std::uint32_t i = sm.start; i < sm.start + sm.count; ++i)
                blended = blended || o.skin.weights.weights[o.mesh().indices[i] * 4 + 1] > 0.01f;
    CHECK(blended);
}

TEST_CASE("rig skin: an SDF creature is skinned with heat diffusion, legs follow their legs") {
    const char* creature = R"({"format":"factoria.model/1","nodes":[
      {"op":"sdf","id":"c","targetTriangles":2500,"children":[
        {"op":"sdf_ellipsoid","radii":[0.25,0.22,0.5],"position":[0,0.7,0],"part":"body"},
        {"op":"sdf_sphere","radius":0.18,"position":[0,0.95,0.6],"smooth":0.05,"part":"head"},
        {"op":"sdf_capsule","radius":0.05,"height":0.55,"position":[0.15,0.28,0.35],"part":"foreleg_l"},
        {"op":"sdf_capsule","radius":0.05,"height":0.55,"position":[-0.15,0.28,0.35],"part":"foreleg_r"},
        {"op":"sdf_capsule","radius":0.05,"height":0.55,"position":[0.15,0.28,-0.35],"part":"hindleg_l"},
        {"op":"sdf_capsule","radius":0.05,"height":0.55,"position":[-0.15,0.28,-0.35],"part":"hindleg_r"},
        {"op":"sdf_capsule","radius":0.04,"height":0.5,"position":[0,0.7,-0.75],"rotation":[90,0,0],"part":"tail"}]}]})";
    const Skinned s = skinned(creature, R"({"format":"factoria.rig/1","model":"p.model.json","template":"quadruped"})");
    check_valid(s);
    CHECK(s.skin.report.unweighted == 0);
    CHECK(s.skin.report.farBlends == 0);
    CHECK(s.skin.report.heatFailed == 0);
    int paws = 0, tailTip = 0;
    for (std::size_t v = 0; v < s.mesh().vertex_count(); ++v) {
        const Vec3 p = s.pos(v);
        if (p.y < 0.05f && p.z > 0.2f && p.x > 0.08f) {  // the left front paw
            ++paws;
            CHECK(s.weight_on(v, "hand_l") + s.weight_on(v, "arm_lower_l") + s.weight_on(v, "toe_l") > 0.7f);
            CHECK(s.weight_on(v, "thigh_l") == 0.0f);
            CHECK(s.weight_on(v, "tail_1") == 0.0f);
        }
        if (p.z < -0.95f) {
            ++tailTip;
            CHECK(s.strongest_name(v).find("tail") == 0);
        }
        if (p.y < 0.3f && p.x < -0.08f)
            CHECK(s.weight_on(v, "arm_upper_l") + s.weight_on(v, "hand_l") + s.weight_on(v, "arm_lower_l") == 0.0f);
    }
    CHECK(paws > 3);
    CHECK(tailTip > 3);
}

TEST_CASE(
    "rig skin: edits set, add, smooth, normalize and limit weights on a part or a selection, and survive recomputing") {
    const std::string base = humanoid_rig();
    const Skinned plain = skinned(kPerson, base);
    // set: the whole left arm follows the hand
    const Skinned set =
        skinned(kPerson, humanoid_rig(R"({"edits":[{"op":"set","bone":"hand_l","weight":1,"part":"arm_l"}]})"));
    check_valid(set);
    CHECK(set.skin.report.editsApplied == 1);
    for (const MeshSubmesh& sm : set.mesh().submeshes) {
        for (std::uint32_t i = sm.start; i < sm.start + sm.count; ++i) {
            const std::uint32_t v = set.mesh().indices[i];
            if (sm.part == "arm_l") CHECK(set.weight_on(v, "hand_l") == doctest::Approx(1.0f));
        }
    }
    // a vertex of another part keeps what it had
    for (const MeshSubmesh& sm : set.mesh().submeshes)
        if (sm.part == "leg_r")
            for (std::uint32_t i = sm.start; i < sm.start + sm.count; ++i) {
                const std::uint32_t v = set.mesh().indices[i];
                for (int k = 0; k < 4; ++k)
                    CHECK(set.skin.weights.weights[v * 4 + std::size_t(k)] ==
                          plain.skin.weights.weights[v * 4 + std::size_t(k)]);
            }
    // set to 0.5 shares the rest in the proportions they had
    const Skinned half =
        skinned(kPerson, humanoid_rig(R"({"edits":[{"op":"set","bone":"head","weight":0.5,"part":"neck"}]})"));
    check_valid(half);
    for (const MeshSubmesh& sm : half.mesh().submeshes)
        if (sm.part == "neck")
            for (std::uint32_t i = sm.start; i < sm.start + sm.count; ++i)
                CHECK(half.weight_on(half.mesh().indices[i], "head") == doctest::Approx(0.5f).epsilon(0.1));
    // add: more weight to the head on the face selected by a box
    const Skinned add =
        skinned(kPerson, humanoid_rig(R"({"edits":[{"op":"add","bone":"head","amount":0.3,"part":"neck"}]})"));
    check_valid(add);
    for (const MeshSubmesh& sm : add.mesh().submeshes)
        if (sm.part == "neck")
            for (std::uint32_t i = sm.start; i < sm.start + sm.count; ++i) {
                const std::uint32_t v = add.mesh().indices[i];
                CHECK(add.weight_on(v, "head") >= plain.weight_on(v, "head") - 1e-6f);
            }
    // selecting faces by a box: only the vertices of the selected faces change
    const Skinned box = skinned(
        kPerson,
        humanoid_rig(
            R"({"edits":[{"op":"set","bone":"spine_1","weight":1,"select":{"by":"box","min":[0.6,1.4,-0.2],"max":[1,1.6,0.2]}}]})"));
    check_valid(box);
    std::size_t changed = 0;
    for (std::size_t v = 0; v < box.mesh().vertex_count(); ++v) {
        if (box.weight_on(v, "spine_1") == doctest::Approx(1.0f)) {
            ++changed;
            CHECK(box.pos(v).x > 0.5f);
        }
    }
    CHECK(changed > 0);
    // limit and normalize
    const Skinned limit = skinned(kPerson, humanoid_rig(R"({"edits":[{"op":"limit","max":1}]})"));
    check_valid(limit);
    for (std::size_t v = 0; v < limit.mesh().vertex_count(); ++v)
        CHECK(limit.skin.weights.weights[v * 4] == doctest::Approx(1.0f));
    CHECK(limit.skin.report.maxInfluences == 1);
    const Skinned norm = skinned(kPerson, humanoid_rig(R"({"edits":[{"op":"normalize","threshold":0.3}]})"));
    check_valid(norm);
    for (std::size_t v = 0; v < norm.mesh().vertex_count(); ++v)
        for (int k = 0; k < 4; ++k) {
            const float w = norm.skin.weights.weights[v * 4 + std::size_t(k)];
            CHECK((w == 0.0f || w >= 0.3f - 1e-5f || k == 0));
        }
    // smooth: neighbouring vertices end up closer to each other
    auto spread = [](const Skinned& s) {
        double total = 0;
        for (std::size_t t = 0; t + 2 < s.mesh().indices.size(); t += 3)
            for (int k = 0; k < 3; ++k) {
                const std::uint32_t a = s.mesh().indices[t + std::size_t(k)],
                                    b = s.mesh().indices[t + std::size_t((k + 1) % 3)];
                for (const char* bone : {"arm_upper_l", "arm_lower_l", "hand_l", "spine_3", "thigh_l"})
                    total += std::fabs(s.weight_on(a, bone) - s.weight_on(b, bone));
            }
        return total;
    };
    const Skinned rough = skinned(kPerson, humanoid_rig(R"({"smooth":0})"));
    const Skinned smoothed =
        skinned(kPerson, humanoid_rig(R"({"smooth":0,"edits":[{"op":"smooth","iterations":8,"strength":0.6}]})"));
    check_valid(smoothed);
    CHECK(spread(smoothed) < spread(rough));
    // edits do not depend on the order of the document's other fields: recomputing gives the same bits
    const Skinned again =
        skinned(kPerson, humanoid_rig(R"({"edits":[{"op":"set","bone":"hand_l","weight":1,"part":"arm_l"}]})"));
    CHECK(std::memcmp(again.skin.weights.weights.data(), set.skin.weights.weights.data(),
                      set.skin.weights.weights.size() * 4) == 0);
}

TEST_CASE("rig skin: mirror copies the weights of one side to the other with the bone names swapped") {
    // an asymmetric edit on the left arm, then mirrored to the right
    const Skinned s = skinned(
        kPerson,
        humanoid_rig(
            R"({"smooth":0,"edits":[{"op":"set","bone":"hand_l","weight":0.7,"part":"arm_l"},{"op":"mirror","from":"l"}]})"));
    check_valid(s);
    CHECK(s.skin.report.mirrorUnmatched == 0);
    std::size_t pairs = 0;
    std::vector<std::string> partOf(s.mesh().vertex_count());
    for (const MeshSubmesh& sm : s.mesh().submeshes)
        for (std::uint32_t i = sm.start; i < sm.start + sm.count; ++i)
            if (partOf[s.mesh().indices[i]].empty()) partOf[s.mesh().indices[i]] = sm.part;
    auto mirrored_part = [](std::string n) {
        if (n.size() > 2 && n[n.size() - 2] == '_') n.back() = n.back() == 'l' ? 'r' : 'l';
        return n;
    };
    for (std::size_t v = 0; v < s.mesh().vertex_count(); ++v) {
        const Vec3 p = s.pos(v);
        if (p.x < 0.05f) continue;
        for (std::size_t u = 0; u < s.mesh().vertex_count(); ++u) {
            if (!near_mirror(p, s.pos(u), 1e-4f) || partOf[u] != mirrored_part(partOf[v])) continue;
            ++pairs;
            // the right vertex has the left one's weights on the mirrored bones
            for (const char* bone : {"arm_upper", "arm_lower", "hand", "clavicle", "thigh", "shin", "foot", "toe"}) {
                const std::string l = std::string(bone) + "_l", r = std::string(bone) + "_r";
                if (s.fit.find(l.c_str()) < 0) continue;
                CHECK(s.weight_on(u, r.c_str()) == doctest::Approx(s.weight_on(v, l.c_str())).epsilon(1e-4).scale(1));
            }
            CHECK(s.weight_on(u, "spine_1") == doctest::Approx(s.weight_on(v, "spine_1")).epsilon(1e-4).scale(1));
            break;
        }
    }
    CHECK(pairs > 100);
    CHECK(s.weight_on(0, "head") >= 0);
}

TEST_CASE("rig skin: unknown parts and bones are explained, and a document with edits is checked against the model") {
    const ModelBuild b = build(kPerson);
    RigDoc d = rig(humanoid_rig(R"({"edits":[{"op":"set","bone":"hand_l","part":"arn_l"}]})"));
    auto fit = fit_rig(d, b.data);
    REQUIRE(fit.ok());
    auto r = compute_rig_skin(d.skin, *fit, b.data);
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().to_string().find("arm_l") != std::string::npos);
    RigDoc d2 = rig(humanoid_rig(R"({"parts":{"torzo":{"method":"rigid"}}})"));
    auto r2 = compute_rig_skin(d2.skin, *fit, b.data);
    REQUIRE_FALSE(r2.ok());
    CHECK(r2.error().to_string().find("torso") != std::string::npos);
}
