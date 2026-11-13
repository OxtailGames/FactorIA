// rig.templates, rig.create, rig.fit, rig.info and rig.bake: rig documents as project files (docs/RIGGING.md). The format, the templates and the
// fit are tested in fa_scene (engine/scene/tests/test_rig.cpp); here: the files, the baked skinned .glb read back through the skeleton loader, the
// recipe, staleness, validation and the teaching errors.
#include <doctest.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdlib>
#include <fstream>

#include "asset_test_helpers.h"
#include "fa/core/json_schema.h"
#include "fa/scene/animation.h"
#include "fa/scene/rig_doc.h"
#include "fa/scene/skeleton.h"
#include "fa/tooling/rig_bake.h"
#include "fa/tooling/validate.h"
#include "fa_test_paths.h"

using namespace fa;
using namespace fa::testing;

namespace {

const char* kPerson = R"({"format":"factoria.model/1","nodes":[
  {"op":"box","size":[0.36,0.2,0.2],"position":[0,0.95,0],"part":"pelvis"},
  {"op":"box","size":[0.4,0.5,0.22],"position":[0,1.3,0],"part":"torso"},
  {"op":"box","size":[0.1,0.1,0.1],"position":[0,1.6,0],"part":"neck"},
  {"op":"box","size":[0.22,0.25,0.22],"position":[0,1.77,0.02],"part":"head"},
  {"op":"box","size":[0.7,0.1,0.1],"position":[0.55,1.5,0],"part":"arm_l"},
  {"op":"box","size":[0.7,0.1,0.1],"position":[-0.55,1.5,0],"part":"arm_r"},
  {"op":"box","size":[0.14,0.9,0.14],"position":[0.11,0.45,0],"part":"leg_l"},
  {"op":"box","size":[0.14,0.9,0.14],"position":[-0.11,0.45,0],"part":"leg_r"}]})";

const char* kModel = "assets/models/person.model.json";
const char* kRig = "assets/models/person.rig.json";
const char* kGlb = "assets/models/person.rig.glb";

Json create_args(const char* templateName = "humanoid") {
    return {{"path", kRig}, {"model", kModel}, {"template", templateName}};
}

std::vector<std::uint8_t> bytes_of(const std::filesystem::path& p) {
    const std::string s = read_all(p);
    return std::vector<std::uint8_t>(s.begin(), s.end());
}

const SkelNode* node_named(const SkeletonAsset& sk, const std::string& name) {
    for (const SkelNode& n : sk.nodes)
        if (n.name == name) return &n;
    return nullptr;
}

}  // namespace

TEST_CASE("rig.templates: the catalog, then the bones and landmarks of one template with its options") {
    AssetsProject p;
    const Json all = p.ok("rig.templates", {});
    std::vector<std::string> names;
    for (const Json& t : all["templates"]) {
        names.push_back(t["name"]);
        CHECK_FALSE(t["doc"].get<std::string>().empty());
        CHECK_FALSE(t["partWords"].empty());
    }
    CHECK(names == std::vector<std::string>{"humanoid", "quadruped", "bird", "tail", "chain", "generic"});

    const Json human = p.ok("rig.templates", {{"name", "humanoid"}});
    CHECK(human["bones"].size() == 22);
    CHECK(human["bones"][0]["name"] == "root");
    CHECK(human["bones"][0]["parent"] == "");
    bool toeLeaf = false, hasTailLandmark = false;
    for (const Json& b : human["bones"]) toeLeaf = toeLeaf || (b["name"] == "toe_l" && b["leaf"] == true);
    for (const Json& l : human["landmarks"]) hasTailLandmark = hasTailLandmark || l == "toe_l.tail";
    CHECK(toeLeaf);
    CHECK(hasTailLandmark);
    CHECK(p.ok("rig.templates", {{"name", "humanoid"}, {"options", {{"spine", 5}, {"tail", 3}}}})["bones"].size() ==
          22 + 2 + 3);
    CHECK(p.ok("rig.templates", {{"name", "tail"}, {"options", {{"segments", 4}}}})["bones"].size() == 5);

    const CommandResult typo = p.call("rig.templates", {{"name", "humanod"}});
    REQUIRE_FALSE(typo.ok);
    CHECK(typo.error.dump().find("humanoid") != std::string::npos);
    CHECK_FALSE(p.call("rig.templates", {{"name", "humanoid"}, {"options", {{"spine", 9}}}}).ok);
    CHECK_FALSE(p.call("rig.templates", {{"options", {{"spine", 2}}}}).ok);
}

TEST_CASE("rig.create: writes the document, fits and bakes a skinned .glb that loads as a skin and rests in the "
          "model's pose") {
    AssetsProject p;
    write_all(p.file(kModel), kPerson);
    const Json r = p.ok("rig.create", create_args());
    CHECK(r["output"] == kGlb);
    CHECK(r["boneCount"] == 22);
    CHECK(r["fit"]["state"] == "fitted");
    CHECK(r["fit"]["landmarks"]["estimated"] == 0);
    CHECK(r["fit"]["matched"].contains("arm_upper_l"));
    CHECK(r["bake"]["state"] == "baked");
    CHECK(r["bake"]["joints"] == 22);

    const Json saved = parse_json(read_all(p.file(kRig)), "doc").value();
    CHECK(saved["format"] == "factoria.rig/1");
    CHECK(saved["template"] == "humanoid");
    CHECK(saved["model"] == kModel);

    const Json prov = p.manifest()["assets"][kGlb]["provenance"];
    CHECK(prov["kind"] == "model3d");
    CHECK(prov["provider"] == "factoria rig.bake");
    CHECK(prov["source"] == kRig);
    CHECK(prov["recipe"]["command"] == "rig.bake");
    CHECK(prov["recipe"]["args"]["path"] == kRig);
    CHECK(prov["recipe"]["inputs"].size() == 2);

    auto sk = parse_skeleton(bytes_of(p.file(kGlb)), kGlb);
    REQUIRE_MESSAGE(sk.ok(), (sk.ok() ? std::string() : sk.error().to_string()));
    REQUIRE(sk->skins.size() >= 1);
    const SkelSkin& skin = sk->skins[0];
    REQUIRE(skin.joints.size() == 22);
    CHECK(sk->nodes[skin.joints[0]].name == "root");
    const SkelNode* head = node_named(*sk, "head");
    const SkelNode* hand = node_named(*sk, "hand_l");
    REQUIRE(head);
    REQUIRE(hand);
    CHECK(head->translation.y > 0);
    CHECK(hand->translation.x > 0);  // character-left is +X
    CHECK(node_named(*sk, "toe_r") != nullptr);

    // every vertex carries up to four bones whose weights sum to 1 (automatic skin weights, docs/RIGGING.md "Skin weights")
    REQUIRE_FALSE(sk->skinVertices.empty());
    for (const SkinVertices& v : sk->skinVertices) {
        REQUIRE_FALSE(v.joints.empty());
        CHECK(v.joints.size() == v.weights.size());
        for (std::size_t i = 0; i < v.joints.size(); ++i) {
            float total = 0;
            for (int k = 0; k < 4; ++k) {
                total += v.weights[i][k];
                if (v.weights[i][k] > 0) CHECK(v.joints[i][k] < skin.joints.size());
            }
            CHECK(total == doctest::Approx(1.0f).epsilon(1e-4));
            CHECK(v.weights[i][0] >= v.weights[i][1]);
        }
    }
    CHECK(r["skin"]["unweighted"] == 0);
    CHECK(r["skin"]["maxInfluences"].get<int>() <= 4);

    // at rest the skin palette is the identity: the model draws exactly as it was built
    const std::vector<Mat4> palette = skin_palette(*sk, rest_pose(*sk), 0);
    REQUIRE(palette.size() == 22);
    for (const Mat4& m : palette)
        for (int i = 0; i < 16; ++i)
            CHECK(m.m[i] == doctest::Approx((i % 5 == 0) ? 1.0f : 0.0f).epsilon(1e-5).scale(1.0));

    // the same inputs give the same bytes
    const std::string first = read_all(p.file(kGlb));
    CHECK(p.ok("rig.bake", {{"force", true}})["count"] == 1);
    CHECK(read_all(p.file(kGlb)) == first);
}

TEST_CASE("rig.create: a model that does not exist, a template typo, an existing document and a bad option teach") {
    AssetsProject p;
    write_all(p.file(kModel), kPerson);

    const CommandResult noModel =
        p.call("rig.create", {{"path", kRig}, {"model", "assets/models/persn.model.json"}, {"template", "humanoid"}});
    REQUIRE_FALSE(noModel.ok);
    CHECK(noModel.error["code"] == "not_found");
    CHECK(noModel.error.dump().find("person.model.json") != std::string::npos);

    const CommandResult typo = p.call("rig.create", create_args("quadruped_"));
    REQUIRE_FALSE(typo.ok);
    CHECK(typo.error.dump().find("quadruped") != std::string::npos);

    const CommandResult bad = p.call(
        "rig.create", {{"path", kRig}, {"model", kModel}, {"template", "humanoid"}, {"options", {{"spine", 99}}}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error.dump().find("/options/spine") != std::string::npos);
    CHECK_FALSE(p.exists(kRig));

    CHECK_FALSE(
        p.call("rig.create", {{"path", "assets/models/person.json"}, {"model", kModel}, {"template", "humanoid"}}).ok);
    CHECK_FALSE(
        p.call("rig.create", {{"path", "elsewhere/person.rig.json"}, {"model", kModel}, {"template", "humanoid"}}).ok);

    p.ok("rig.create", create_args());
    const CommandResult again = p.call("rig.create", create_args());
    REQUIRE_FALSE(again.ok);
    CHECK(again.error.dump().find("overwrite") != std::string::npos);
    p.ok("rig.create",
         {{"path", kRig}, {"model", kModel}, {"template", "humanoid"}, {"overwrite", true}, {"bake", false}});
}

TEST_CASE(
    "rig.create: other templates, a generic rig gets one bone per part, and bake false only writes the document") {
    AssetsProject p;
    write_all(p.file(kModel), kPerson);
    const Json generic =
        p.ok("rig.create",
             {{"path", "assets/models/g.rig.json"}, {"model", kModel}, {"template", "generic"}, {"bake", false}});
    CHECK(generic["boneCount"] == 9);  // root and the 8 parts
    CHECK(generic["bake"]["state"] == "missing");
    CHECK_FALSE(p.exists("assets/models/g.rig.glb"));
    const Json saved = parse_json(read_all(p.file("assets/models/g.rig.json")), "g").value();
    CHECK(saved["bones"].size() == 8);  // `root` is implicit

    const Json tail = p.ok("rig.create", {{"path", "assets/models/t.rig.json"},
                                          {"model", kModel},
                                          {"template", "tail"},
                                          {"options", {{"segments", 5}}}});
    CHECK(tail["boneCount"] == 6);
    CHECK(p.exists("assets/models/t.rig.glb"));
}

TEST_CASE("rig.fit: parts and landmarks change the fit and re-bake; a name that does not exist writes nothing and says "
          "what to use") {
    AssetsProject p;
    write_all(p.file(kModel), kPerson);
    p.ok("rig.create", create_args());
    const std::string before = read_all(p.file(kRig));
    const std::string glbBefore = read_all(p.file(kGlb));

    const CommandResult missing = p.call("rig.fit", {{"path", kRig}, {"parts", {{"head", Json::array({"hed"})}}}});
    REQUIRE_FALSE(missing.ok);
    CHECK(missing.error["code"] == "fit_failed");
    CHECK(missing.error.dump().find("Did you mean 'head'") != std::string::npos);
    const CommandResult badBone = p.call("rig.fit", {{"path", kRig}, {"landmarks", {{"hed", {0, 1, 0}}}}});
    REQUIRE_FALSE(badBone.ok);
    CHECK(badBone.error["code"] == "invalid_document");
    CHECK(badBone.error.dump().find("/landmarks/hed") != std::string::npos);
    CHECK(read_all(p.file(kRig)) == before);

    const Json plan = p.ok("rig.fit", {{"path", kRig}, {"landmarks", {{"head", {0, 1.6, 0.02}}}}, {"dryRun", true}});
    CHECK(plan["written"] == false);
    CHECK(read_all(p.file(kRig)) == before);
    CHECK(read_all(p.file(kGlb)) == glbBefore);

    const Json r = p.ok("rig.fit", {{"path", kRig}, {"landmarks", {{"head", {0, 1.6, 0.02}}}}, {"strict", true}});
    CHECK(r["written"] == true);
    CHECK(r["fit"]["landmarks"]["override"] == 1);
    CHECK(r["bake"]["state"] == "baked");
    CHECK(read_all(p.file(kGlb)) != glbBefore);
    const Json saved = parse_json(read_all(p.file(kRig)), "doc").value();
    CHECK(saved["landmarks"]["head"][1] == doctest::Approx(1.6));
    CHECK(saved["strict"] == true);
    auto sk = parse_skeleton(bytes_of(p.file(kGlb)), kGlb);
    REQUIRE(sk.ok());
    const SkelNode* neck = node_named(*sk, "head");
    REQUIRE(neck);
    CHECK(neck->translation.y == doctest::Approx(1.6f - 1.55f).epsilon(0.001));  // relative to the neck's head

    // null removes an entry, then the entry is gone
    p.ok("rig.fit", {{"path", kRig}, {"landmarks", {{"head", nullptr}}}});
    CHECK_FALSE(parse_json(read_all(p.file(kRig)), "doc").value().contains("landmarks"));

    // nothing to change: only shows the fit
    const Json show = p.ok("rig.fit", {{"path", kRig}});
    CHECK(show["written"] == false);
    CHECK(show["fit"]["state"] == "fitted");
}

TEST_CASE("rig.fit: strict turns an estimated joint into an error that says what to give; a model without the parts "
          "only warns otherwise") {
    AssetsProject p;
    write_all(p.file("assets/models/blob.model.json"),
              R"({"format":"factoria.model/1","nodes":[{"op":"box","size":[0.5,1.8,0.3],"position":[0,0.9,0]}]})");
    const Json r = p.ok("rig.create", {{"path", "assets/models/blob.rig.json"},
                                       {"model", "assets/models/blob.model.json"},
                                       {"template", "humanoid"}});
    CHECK(r["fit"]["landmarks"]["estimated"].get<int>() > 0);
    CHECK_FALSE(r["fit"]["warnings"].empty());
    const CommandResult strict = p.call("rig.fit", {{"path", "assets/models/blob.rig.json"}, {"strict", true}});
    REQUIRE_FALSE(strict.ok);
    CHECK(strict.error["code"] == "fit_failed");
    CHECK(strict.error.dump().find("landmarks") != std::string::npos);
    CHECK_FALSE(parse_json(read_all(p.file("assets/models/blob.rig.json")), "d").value().contains("strict"));
}

TEST_CASE("rig.info: validity with every issue, the output, the bake state and the fit") {
    AssetsProject p;
    write_all(p.file(kModel), kPerson);
    p.ok("rig.create", create_args());
    const Json info = p.ok("rig.info", {{"path", kRig}});
    CHECK(info["valid"] == true);
    CHECK(info["template"] == "humanoid");
    CHECK(info["bake"]["state"] == "fresh");
    CHECK(info["fit"]["boneCount"] == 22);
    CHECK(p.ok("rig.info", {{"path", kRig}, {"fit", false}}).contains("fit") == false);

    write_all(
        p.file("assets/models/bad.rig.json"),
        R"({"format":"factoria.rig/1","model":"assets/models/person.model.json","template":"humanod","options":{"spine":99},"bogus":1})");
    const Json bad = p.ok("rig.info", {{"path", "assets/models/bad.rig.json"}});
    CHECK(bad["valid"] == false);
    CHECK(bad["issues"].size() >= 2);
    CHECK(bad["issues"].dump().find("humanoid") != std::string::npos);

    const CommandResult gone = p.call("rig.info", {{"path", "assets/models/persn.rig.json"}});
    REQUIRE_FALSE(gone.ok);
    CHECK(gone.error["code"] == "not_found");
    CHECK(gone.error.dump().find("person.rig.json") != std::string::npos);
}

TEST_CASE(
    "rig.bake: a changed model or document makes the .glb stale; validate warns, regenerate and bake build it again") {
    AssetsProject p;
    write_all(p.file(kModel), kPerson);
    p.ok("rig.create", create_args());
    CHECK(p.ok("assets.regenerate", {{"stale", true}})["count"] == 0);
    CHECK(p.ok("rig.bake", {})["count"] == 0);
    CHECK(rig_bake_status(p.dir, kRig).state == RigBakeState::Fresh);

    std::string changed = kPerson;
    changed.replace(changed.find("[0.7,0.1,0.1],\"position\":[0.55"), 5, "[0.9,");
    write_all(p.file(kModel), changed);
    CHECK(rig_bake_status(p.dir, kRig).state == RigBakeState::Stale);
    CHECK(p.ok("rig.info", {{"path", kRig}, {"fit", false}})["bake"]["state"] == "stale");
    bool warned = false;
    for (const ValidationIssue& w : validate_project(p.dir).warnings)
        warned = warned || w.message.find("'assets/models/person.rig.glb' is stale") != std::string::npos;
    CHECK(warned);
    const Json plan = p.ok("rig.bake", {{"dryRun", true}});
    REQUIRE(plan["wouldBake"].size() == 1);
    CHECK(plan["wouldBake"][0]["reason"] == "stale");
    const std::string first = read_all(p.file(kGlb));
    CHECK(p.ok("assets.regenerate", {{"stale", true}})["count"] == 1);
    const std::string second = read_all(p.file(kGlb));
    CHECK(second != first);
    CHECK(rig_bake_status(p.dir, kRig).state == RigBakeState::Fresh);

    // the bake before an export
    write_all(p.file(kRig), read_all(p.file(kRig)) + " ");
    CHECK(rig_bake_status(p.dir, kRig).state == RigBakeState::Stale);
    auto baked = bake_rig_documents_if_needed(p.dir);
    REQUIRE(baked.ok());
    CHECK(baked->size() == 1);
    CHECK(bake_rig_documents_if_needed(p.dir)->empty());
}

TEST_CASE("rig.bake: a file nobody baked is not replaced unless overwrite is true") {
    AssetsProject p;
    write_all(p.file(kModel), kPerson);
    p.ok("rig.create", {{"path", kRig}, {"model", kModel}, {"template", "humanoid"}, {"bake", false}});
    write_all(p.file(kGlb), "not mine");
    const CommandResult r = p.call("rig.bake", {{"path", kRig}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("overwrite") != std::string::npos);
    CHECK(read_all(p.file(kGlb)) == "not mine");
    p.ok("rig.bake", {{"path", kRig}, {"overwrite", true}});
    CHECK(read_all(p.file(kGlb)).substr(0, 4) == "glTF");
}

TEST_CASE("project.validate: a rig document with mistakes is an error per issue; one not baked yet is a warning") {
    AssetsProject p;
    write_all(p.file(kModel), kPerson);
    p.ok("rig.create", {{"path", kRig}, {"model", kModel}, {"template", "humanoid"}, {"bake", false}});
    bool notBaked = false;
    const ValidationReport warn = validate_project(p.dir);
    for (const ValidationIssue& w : warn.warnings)
        notBaked = notBaked || (w.file == kRig && w.hint.find("rig.bake") != std::string::npos);
    CHECK(notBaked);
    for (const ValidationIssue& e : warn.errors) CHECK_MESSAGE(e.file != kRig, e.message);

    write_all(
        p.file("assets/models/bad.rig.json"),
        R"({"format":"factoria.rig/1","model":"assets/models/person.model.json","template":"humanoid","landmarks":{"hed":[0,1,0]},"parts":{"head":["nothing"]}})");
    int onBad = 0;
    for (const ValidationIssue& e : validate_project(p.dir).errors)
        if (e.file == "assets/models/bad.rig.json") ++onBad;
    CHECK(onBad >= 1);
}

TEST_CASE("rig schema: schemas/rig.schema.json is the schema the catalog builds, and valid documents pass it") {
    namespace stdfs = std::filesystem;
    const stdfs::path file = stdfs::path(FA_REPO_ROOT) / "schemas" / "rig.schema.json";
    const Json built = rig_doc_schema();
    if (const char* regenerate = std::getenv("FA_REGENERATE_RIG_SCHEMA");
        regenerate && std::string(regenerate) == "1") {
        std::ofstream out(file, std::ios::binary);
        out << built.dump(2) << "\n";
    }
    auto schema = parse_json(read_all(file), "rig.schema.json");
    REQUIRE(schema.ok());
    CHECK_MESSAGE(
        *schema == built,
        "schemas/rig.schema.json is out of date: run the tests with FA_REGENERATE_RIG_SCHEMA=1 to write it again");

    Json sample = *parse_json(
        R"({"format":"factoria.rig/1","model":"assets/models/a.model.json","template":"quadruped","options":{"tail":4},
        "parts":{"head":["skull","jaw"]},"landmarks":{"head":[0,1,0.5],"tail_1.tail":[0,0.8,-1]},"symmetryX":0,"strict":true,
        "skin":{"method":"heat","maxInfluences":3,"smooth":2,"parts":{"sleeve":{"method":"rigid","bone":"arm_upper_l"}},
                "edits":[{"op":"set","bone":"hand_l","weight":1,"part":"glove"},{"op":"mirror","from":"l"},{"op":"limit","max":2,"part":["a","b"]}]}})",
        "sample");
    CHECK(validate_json(*schema, sample).empty());
    Json broken = sample;
    broken["template"] = "dragon";
    CHECK_FALSE(validate_json(*schema, broken).empty());
    broken = sample;
    broken["landmarks"]["head"] = Json::array({0, 1});
    CHECK_FALSE(validate_json(*schema, broken).empty());
    broken = sample;
    broken["skin"]["method"] = "magic";
    CHECK_FALSE(validate_json(*schema, broken).empty());
    broken = sample;
    broken["skin"]["edits"][0]["op"] = "paint";
    CHECK_FALSE(validate_json(*schema, broken).empty());
}

TEST_CASE("rig.bake mergeParts: parts that share a material become one submesh, the vertices and so the pose stay the "
          "same, and the choice is kept") {
    AssetsProject p;
    write_all(p.file(kModel), kPerson);
    const Json created = p.ok("rig.create", create_args());
    CHECK(created["bake"]["state"] == "baked");
    const std::vector<std::uint8_t> unmerged = bytes_of(p.file(kGlb));

    const Json r = p.ok("rig.bake", {{"path", kRig}, {"mergeParts", true}});
    REQUIRE(r["baked"].size() == 1);
    CHECK(r["baked"][0]["mergeParts"] == true);
    CHECK(r["baked"][0]["submeshesBefore"] == 8);
    CHECK(r["baked"][0]["submeshes"] == 1);
    CHECK(bytes_of(p.file(kGlb)) != unmerged);
    CHECK(p.manifest()["assets"][kGlb]["provenance"]["recipe"]["args"]["mergeParts"] == true);

    // omitted: the last bake's choice is repeated; false turns it off again and gives the first bytes back
    p.ok("rig.bake", {{"path", kRig}});
    CHECK(p.manifest()["assets"][kGlb]["provenance"]["recipe"]["args"]["mergeParts"] == true);
    p.ok("rig.bake", {{"path", kRig}, {"mergeParts", false}});
    CHECK(bytes_of(p.file(kGlb)) == unmerged);
    // with no path, an explicit mergeParts bakes only the documents whose choice changes: the others would write the same bytes
    CHECK(p.ok("rig.bake", {{"mergeParts", false}})["count"] == 0);
    CHECK(p.ok("rig.bake", {{"mergeParts", true}})["count"] == 1);
    CHECK(p.ok("rig.bake", {{"mergeParts", true}})["count"] == 0);
    p.ok("rig.bake", {{"path", kRig}, {"mergeParts", false}});

    // the merge itself: same vertex arrays, same set of triangles, one submesh per material
    auto doc = load_rig_document(p.dir, kRig);
    REQUIRE(doc.ok());
    auto eval = rig_evaluate(p.dir, *doc, true);
    REQUIRE(eval.ok());
    MeshData merged = eval->mesh;
    CHECK(rig_merge_parts(merged) == 1);
    CHECK(merged.positions == eval->mesh.positions);
    CHECK(merged.indices.size() == eval->mesh.indices.size());
    CHECK(merged.submeshes.size() == 1);
    CHECK(merged.submeshes[0].count == merged.indices.size());
    CHECK(merged.submeshes[0].part.find("head") != std::string::npos);
    auto triangles = [](const MeshData& m) {
        std::vector<std::array<std::uint32_t, 3>> t;
        for (const MeshSubmesh& s : m.submeshes)
            for (std::uint32_t i = s.start; i < s.start + s.count; i += 3)
                t.push_back({m.indices[i], m.indices[i + 1], m.indices[i + 2]});
        std::sort(t.begin(), t.end());
        return t;
    };
    CHECK(triangles(merged) == triangles(eval->mesh));
}
