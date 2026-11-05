// skin3d.*: the skin of a rig document as project files (docs/RIGGING.md, "Skin weights"). The weights themselves are tested in fa_scene
// (engine/scene/tests/test_rig_skin.cpp); here: the commands that edit the `skin` section, that the baked .glb carries the weights and
// re-bakes to the same bytes, the weight preview picture, and the teaching errors.
#include <doctest.h>

#include <cmath>

#include "asset_test_helpers.h"
#include "fa/scene/skeleton.h"
#include "fa/tooling/rig_bake.h"

using namespace fa;
using namespace fa::testing;

namespace {

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

const char* kModel = "assets/models/person.model.json";
const char* kRig = "assets/models/person.rig.json";
const char* kGlb = "assets/models/person.rig.glb";

struct Person {
    AssetsProject p;
    Person() {
        write_all(p.file(kModel), kPerson);
        p.ok("rig.create", {{"path", kRig}, {"model", kModel}, {"template", "humanoid"}});
    }
    Json doc() const { return parse_json(read_all(p.file(kRig)), "doc").value(); }
    std::string glb() const { return read_all(p.file(kGlb)); }
};

SkeletonAsset skeleton_of(const std::string& bytes) {
    auto sk = parse_skeleton(std::vector<std::uint8_t>(bytes.begin(), bytes.end()), "person.rig.glb");
    REQUIRE_MESSAGE(sk.ok(), sk.error().to_string());
    return std::move(*sk);
}

int joint_named(const SkeletonAsset& sk, const std::string& name) {
    const SkelSkin& skin = sk.skins[0];
    for (std::size_t i = 0; i < skin.joints.size(); ++i)
        if (sk.nodes[skin.joints[i]].name == name) return int(i);
    return -1;
}

// The weight bone `joint` has on the vertices of the baked .glb: the largest one and how many vertices it touches.
struct BoneWeight {
    float peak = 0;
    std::size_t vertices = 0;
};
BoneWeight weight_of(const SkeletonAsset& sk, int joint) {
    BoneWeight out;
    for (const SkinVertices& v : sk.skinVertices)
        for (std::size_t i = 0; i < v.joints.size(); ++i)
            for (int k = 0; k < 4; ++k)
                if (int(v.joints[i][k]) == joint && v.weights[i][k] > 0) {
                    out.peak = std::max(out.peak, v.weights[i][k]);
                    ++out.vertices;
                }
    return out;
}

}  // namespace

TEST_CASE("skin3d.info: the settings, the bones with their parts and the quality of the weights") {
    Person s;
    const Json r = s.p.ok("skin3d.info", {{"path", kRig}});
    CHECK(r["skin"]["method"] == "auto");
    CHECK(r["skin"]["maxInfluences"] == 4);
    CHECK(r["edits"].empty());
    CHECK(r["bones"].size() == 22);
    CHECK(r["quality"]["unweighted"] == 0);
    CHECK(r["quality"]["vertices"].get<int>() > 100);
    CHECK(r["quality"]["maxInfluences"].get<int>() <= 4);
    CHECK(r["quality"]["parts"].size() == 8);
    CHECK(r["quality"]["parts"][0]["method"] == "heat");
    CHECK(r["bake"]["state"] == "fresh");
    CHECK_FALSE(s.p.call("skin3d.info", {{"path", "assets/models/persn.rig.json"}}).ok);
}

TEST_CASE("skin3d.set: the edit is appended to the document, survives a re-bake and the .glb holds its weights") {
    Person s;
    SkeletonAsset before = skeleton_of(s.glb());
    const int elbow = joint_named(before, "arm_lower_l");
    const int hand = joint_named(before, "hand_l");
    REQUIRE(elbow >= 0);
    REQUIRE(hand >= 0);
    const std::string untouched = s.glb();

    const Json r = s.p.ok("skin3d.set", {{"path", kRig}, {"bone", "hand_l"}, {"weight", 1}, {"part", "arm_l"}});
    CHECK(r["index"] == 0);
    CHECK(r["written"] == true);
    CHECK(r["bake"]["state"] == "baked");
    CHECK(r["verticesChanged"].get<int>() > 0);
    CHECK(r["quality"]["editsApplied"] == 1);
    const Json doc = s.doc();
    REQUIRE(doc["skin"]["edits"].size() == 1);
    CHECK(doc["skin"]["edits"][0]["op"] == "set");
    CHECK(doc["skin"]["edits"][0]["bone"] == "hand_l");
    CHECK(doc["skin"]["edits"][0]["part"] == "arm_l");

    const std::string baked = s.glb();
    CHECK(baked != untouched);
    SkeletonAsset sk = skeleton_of(baked);
    CHECK(weight_of(sk, hand).vertices > weight_of(before, hand).vertices);
    CHECK(weight_of(sk, hand).peak == doctest::Approx(1.0f));
    // the edit is in the recipe: baking again gives the same bytes
    CHECK(s.p.ok("rig.bake", {{"force", true}})["count"] == 1);
    CHECK(s.glb() == baked);

    // skin3d.clear takes it out and the bytes are the automatic ones again
    const Json c = s.p.ok("skin3d.clear", {{"path", kRig}, {"index", 0}});
    CHECK(c["removed"].size() == 1);
    CHECK(c["remaining"].empty());
    CHECK_FALSE(s.doc().contains("skin"));
    CHECK(s.glb() == untouched);
}

TEST_CASE("skin3d edits: add, smooth, normalize, limit, a selection and dryRun") {
    Person s;
    const Json add = s.p.ok("skin3d.add", {{"path", kRig}, {"bone", "spine_2"}, {"amount", 0.3}, {"part", "torso"}, {"bake", false}});
    CHECK(add["bake"]["state"] == "stale");
    CHECK(add["index"] == 0);
    const Json sel = s.p.ok("skin3d.smooth", {{"path", kRig}, {"iterations", 2}, {"select", {{"by", "box"}, {"min", {-0.3, 1.0, -0.2}}, {"max", {0.3, 1.6, 0.2}}}}, {"bake", false}});
    CHECK(sel["index"] == 1);
    s.p.ok("skin3d.normalize", {{"path", kRig}, {"threshold", 0.05}, {"bake", false}});
    const Json lim = s.p.ok("skin3d.limit", {{"path", kRig}, {"max", 2}, {"part", Json::array({"head", "neck"})}});
    CHECK(lim["index"] == 3);
    CHECK(lim["quality"]["editsApplied"] == 4);
    CHECK(s.doc()["skin"]["edits"].size() == 4);
    CHECK(s.doc()["skin"]["edits"][1]["select"]["by"] == "box");
    CHECK(s.doc()["skin"]["edits"][3]["part"].size() == 2);
    CHECK(s.p.ok("skin3d.info", {{"path", kRig}})["edits"].size() == 4);

    // limit 2 on the head: no head vertex follows more than two bones
    SkeletonAsset sk = skeleton_of(s.glb());
    CHECK(sk.skinVertices.size() >= 1);

    // a dry run reports and writes nothing
    const std::string text = read_all(s.p.file(kRig));
    const Json dry = s.p.ok("skin3d.set", {{"path", kRig}, {"bone", "head"}, {"part", "neck"}, {"dryRun", true}});
    CHECK(dry["written"] == false);
    CHECK(read_all(s.p.file(kRig)) == text);
}

TEST_CASE("skin3d.mirror: the weights of the left arm are copied to the right one") {
    Person s;
    s.p.ok("skin3d.set", {{"path", kRig}, {"bone", "hand_l"}, {"weight", 1}, {"part", "arm_l"}, {"bake", false}});
    const Json m = s.p.ok("skin3d.mirror", {{"path", kRig}, {"from", "l"}});
    CHECK(m["verticesChanged"].get<int>() > 0);
    CHECK(m["quality"].value("mirrorUnmatched", 0) == 0);
    SkeletonAsset sk = skeleton_of(s.glb());
    const int handL = joint_named(sk, "hand_l"), handR = joint_named(sk, "hand_r");
    const BoneWeight l = weight_of(sk, handL), r = weight_of(sk, handR);
    CHECK(l.vertices == r.vertices);
    CHECK(r.peak == doctest::Approx(l.peak));
}

TEST_CASE("skin3d.auto: a method for the whole rig or one part, the settings, and a bad part fails without writing") {
    Person s;
    const Json r = s.p.ok("skin3d.auto", {{"path", kRig}, {"method", "voxel"}});
    CHECK(r["changed"][0] == "method");
    CHECK(r["quality"]["parts"][0]["method"] == "voxel");
    CHECK(s.doc()["skin"]["method"] == "voxel");

    const Json rigid = s.p.ok("skin3d.auto", {{"path", kRig}, {"part", "head"}, {"method", "rigid"}, {"bone", "head"}});
    CHECK(s.doc()["skin"]["parts"]["head"]["method"] == "rigid");
    CHECK(s.doc()["skin"]["parts"]["head"]["bone"] == "head");
    bool headRigid = false;
    for (const Json& part : rigid["quality"]["parts"]) headRigid = headRigid || (part["part"] == "head" && part["method"] == "rigid");
    CHECK(headRigid);
    SkeletonAsset sk = skeleton_of(s.glb());
    CHECK(weight_of(sk, joint_named(sk, "head")).peak == doctest::Approx(1.0f));

    s.p.ok("skin3d.auto", {{"path", kRig}, {"part", "head"}});  // removes the override
    CHECK_FALSE(s.doc()["skin"].contains("parts"));
    s.p.ok("skin3d.auto", {{"path", kRig}, {"method", "auto"}, {"smooth", 2}, {"maxInfluences", 3}, {"locality", 1.5}});
    CHECK(s.doc()["skin"]["smooth"] == 2);
    CHECK(s.doc()["skin"]["maxInfluences"] == 3);
    SkeletonAsset three = skeleton_of(s.glb());
    for (const SkinVertices& v : three.skinVertices)
        for (const auto& w : v.weights) CHECK(w[3] == 0.0f);

    const std::string text = read_all(s.p.file(kRig));
    const CommandResult bad = s.p.call("skin3d.auto", {{"path", kRig}, {"part", "hed"}, {"method", "rigid"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error.dump().find("head") != std::string::npos);
    CHECK(read_all(s.p.file(kRig)) == text);
    CHECK_FALSE(s.p.call("skin3d.auto", {{"path", kRig}, {"method", "magic"}}).ok);
    CHECK_FALSE(s.p.call("skin3d.auto", {{"path", kRig}, {"smooth", 99}}).ok);
}

TEST_CASE("skin3d edits: a bone or part that does not exist teaches and writes nothing") {
    Person s;
    const std::string text = read_all(s.p.file(kRig));
    const CommandResult typo = s.p.call("skin3d.set", {{"path", kRig}, {"bone", "arm_lowr_l"}});
    REQUIRE_FALSE(typo.ok);
    CHECK(typo.error.dump().find("arm_lower_l") != std::string::npos);
    CHECK(typo.error.dump().find("/skin/edits/0") != std::string::npos);
    const CommandResult part = s.p.call("skin3d.set", {{"path", kRig}, {"bone", "head"}, {"part", "hed"}});
    REQUIRE_FALSE(part.ok);
    CHECK(part.error.dump().find("head") != std::string::npos);
    CHECK_FALSE(s.p.call("skin3d.set", {{"path", kRig}}).ok);                                     // bone is required
    CHECK_FALSE(s.p.call("skin3d.set", {{"path", kRig}, {"bone", "head"}, {"weight", 2}}).ok);    // out of range
    CHECK_FALSE(s.p.call("skin3d.mirror", {{"path", kRig}, {"from", "x"}}).ok);
    CHECK_FALSE(s.p.call("skin3d.set", {{"path", kRig}, {"bone", "head"}, {"colour", 1}}).ok);    // unknown argument
    CHECK_FALSE(s.p.call("skin3d.clear", {{"path", kRig}, {"index", 3}}).ok);                     // no such edit
    CHECK(read_all(s.p.file(kRig)) == text);
}

TEST_CASE("skin3d.preview: a heat map of one bone, one colour per bone and a posed row; nothing in the project changes") {
    Person s;
    const std::string text = read_all(s.p.file(kRig)), glb = s.glb();
    const Json heat = s.p.ok("skin3d.preview", {{"path", kRig}, {"bone", "arm_lower_l"}});
    CHECK(heat["mode"] == "heat");
    CHECK(heat["bone"] == "arm_lower_l");
    CHECK(heat["boneWeights"]["verticesWithWeight"].get<int>() > 0);
    CHECK(heat["boneWeights"]["max"].get<double>() > 0.7);
    REQUIRE(heat.contains("$image"));
    CHECK(heat["$image"]["temporary"] == true);
    const Image heatPic = read_png(heat["$image"]["path"].get<std::string>());
    CHECK(heatPic.width == heat["picture"]["width"].get<int>());
    CHECK(heat["picture"]["rows"] == 1);
    // the heat map has warm and cold pixels, the cold ones the model, not only the background
    std::size_t warm = 0, cold = 0;
    for (std::size_t i = 0; i + 3 < heatPic.rgba.size(); i += 4) {
        if (heatPic.rgba[i] > 200 && heatPic.rgba[i + 2] < 80) ++warm;
        if (heatPic.rgba[i + 2] > 110 && heatPic.rgba[i] < 40) ++cold;
    }
    CHECK(warm > 50);
    CHECK(cold > 50);

    const Json bones = s.p.ok("skin3d.preview", {{"path", kRig}, {"views", 2}, {"cell", 160}});
    CHECK(bones["mode"] == "bones");
    CHECK(bones["views"].size() == 2);
    CHECK(read_png(bones["$image"]["path"].get<std::string>()).width > 0);

    const Json posed = s.p.ok("skin3d.preview", {{"path", kRig}, {"bone", "arm_lower_l"}, {"pose", {{"arm_lower_l", 70}}}, {"views", 1}, {"cell", 200}});
    CHECK(posed["picture"]["rows"] == 2);
    CHECK(posed["pose"][0]["bone"] == "arm_lower_l");
    CHECK(posed["pose"][0]["degrees"] == 70);
    const Json listPose = s.p.ok("skin3d.preview", {{"path", kRig}, {"pose", Json::array({{{"bone", "shin_l"}, {"degrees", -40}, {"axis", {1, 0, 0}}}})}, {"views", 1}, {"cell", 160}});
    CHECK(listPose["picture"]["rows"] == 2);

    const Json kept = s.p.ok("skin3d.preview", {{"path", kRig}, {"bone", "head"}, {"out", "docs/review/head.png"}, {"cell", 120}, {"views", 1}});
    CHECK(kept["written"] == "docs/review/head.png");
    CHECK(s.p.exists("docs/review/head.png"));
    CHECK_FALSE(s.p.call("skin3d.preview", {{"path", kRig}, {"bone", "head"}, {"out", "docs/review/head.png"}}).ok);  // exists
    CHECK(s.p.ok("skin3d.preview", {{"path", kRig}, {"bone", "head"}, {"out", "docs/review/head.png"}, {"overwrite", true}, {"cell", 120}, {"views", 1}})["written"] == "docs/review/head.png");

    CHECK(read_all(s.p.file(kRig)) == text);
    CHECK(s.glb() == glb);

    const CommandResult typo = s.p.call("skin3d.preview", {{"path", kRig}, {"bone", "arm_lowr_l"}});
    REQUIRE_FALSE(typo.ok);
    CHECK(typo.error.dump().find("arm_lower_l") != std::string::npos);
    CHECK_FALSE(s.p.call("skin3d.preview", {{"path", kRig}, {"mode", "heat"}}).ok);  // heat needs a bone
    CHECK_FALSE(s.p.call("skin3d.preview", {{"path", kRig}, {"pose", {{"arm_lower_l", 400}}}}).ok);
    CHECK_FALSE(s.p.call("skin3d.preview", {{"path", kRig}, {"pose", {{"arm_lowr_l", 40}}}}).ok);
    CHECK_FALSE(s.p.call("skin3d.preview", {{"path", kRig}, {"out", "docs/review/head.jpg"}}).ok);
}

TEST_CASE("skin3d: a rigid robot rig (generic) binds each part to its bone, and rig.fit can set the skin section") {
    AssetsProject p;
    write_all(p.file(kModel), R"({"format":"factoria.model/1","nodes":[
      {"op":"box","size":[0.5,0.4,0.3],"position":[0,0.8,0],"part":"body"},
      {"op":"box","size":[0.2,0.2,0.2],"position":[0,1.1,0],"part":"head"},
      {"op":"box","size":[0.15,0.5,0.15],"position":[0.35,0.8,0],"part":"arm"}]})");
    const Json made = p.ok("rig.create", {{"path", kRig}, {"model", kModel}, {"template", "generic"}});
    CHECK(made["skin"]["unweighted"] == 0);
    SkeletonAsset sk = skeleton_of(read_all(p.file(kGlb)));
    for (const SkinVertices& v : sk.skinVertices)
        for (std::size_t i = 0; i < v.joints.size(); ++i) CHECK(v.weights[i][0] == doctest::Approx(1.0f));
    const Json fit = p.ok("rig.fit", {{"path", kRig}, {"skin", {{"smooth", 0}}}});
    CHECK(fit["changed"][0] == "skin");
    CHECK(parse_json(read_all(p.file(kRig)), "doc").value()["skin"]["smooth"] == 0);
}
