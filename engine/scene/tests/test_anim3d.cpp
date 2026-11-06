// 3D bone clips, IK, generators and retargeting (docs/ANIMATION.md, "3D bone clips"; docs/RIGGING.md).
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <filesystem>
#include <memory>

#include "fa/core/fs.h"
#include "fa/scene/anim3d.h"
#include "fa/scene/anim3d_gen.h"
#include "fa/scene/anim3d_retarget.h"
#include "fa/scene/animation.h"
#include "fa/scene/ik3d.h"
#include "fa/scene/model_doc.h"
#include "fa/scene/rig3d.h"
#include "fa/scene/rig_doc.h"
#include "fa/scene/rig_fit.h"
#include "fa/scene/rig_glb.h"
#include "fa/scene/serialize.h"
#include "fa_test_paths.h"

#include <fstream>
#include <set>
#include <sstream>

using namespace fa;

namespace {

Json J(const char* text) { return parse_json(text, "test").value(); }

const char* kPerson = R"({"format":"factoria.model/1","nodes":[
  {"op":"box","size":[0.36,0.2,0.2],"position":[0,0.95,0],"part":"pelvis"},
  {"op":"box","size":[0.4,0.5,0.22],"position":[0,1.3,0],"part":"torso"},
  {"op":"box","size":[0.1,0.1,0.1],"position":[0,1.6,0],"part":"neck"},
  {"op":"box","size":[0.22,0.25,0.22],"position":[0,1.77,0.02],"part":"head"},
  {"op":"box","size":[0.7,0.1,0.1],"position":[0.55,1.5,0],"part":"arm_l"},
  {"op":"box","size":[0.7,0.1,0.1],"position":[-0.55,1.5,0],"part":"arm_r"},
  {"op":"box","size":[0.14,0.9,0.14],"position":[0.11,0.45,0],"part":"leg_l"},
  {"op":"box","size":[0.14,0.9,0.14],"position":[-0.11,0.45,0],"part":"leg_r"}]})";
// A smaller person with other proportions: shorter legs, a longer torso.
const char* kKid = R"({"format":"factoria.model/1","nodes":[
  {"op":"box","size":[0.3,0.16,0.16],"position":[0,0.6,0],"part":"pelvis"},
  {"op":"box","size":[0.32,0.5,0.18],"position":[0,0.93,0],"part":"torso"},
  {"op":"box","size":[0.08,0.08,0.08],"position":[0,1.23,0],"part":"neck"},
  {"op":"box","size":[0.22,0.24,0.22],"position":[0,1.4,0.02],"part":"head"},
  {"op":"box","size":[0.5,0.08,0.08],"position":[0.4,1.15,0],"part":"arm_l"},
  {"op":"box","size":[0.5,0.08,0.08],"position":[-0.4,1.15,0],"part":"arm_r"},
  {"op":"box","size":[0.12,0.6,0.12],"position":[0.09,0.3,0],"part":"leg_l"},
  {"op":"box","size":[0.12,0.6,0.12],"position":[-0.09,0.3,0],"part":"leg_r"}]})";
const char* kDog = R"({"format":"factoria.model/1","nodes":[
  {"op":"box","size":[0.4,0.4,1.0],"position":[0,0.8,0],"part":"body"},
  {"op":"box","size":[0.15,0.3,0.15],"position":[0,1.0,0.6],"part":"neck"},
  {"op":"box","size":[0.25,0.25,0.35],"position":[0,1.1,0.85],"part":"head"},
  {"op":"box","size":[0.08,0.08,0.5],"position":[0,0.85,-0.75],"part":"tail"},
  {"op":"box","size":[0.1,0.6,0.1],"position":[0.15,0.3,0.4],"part":"foreleg_l"},
  {"op":"box","size":[0.1,0.6,0.1],"position":[-0.15,0.3,0.4],"part":"foreleg_r"},
  {"op":"box","size":[0.1,0.6,0.1],"position":[0.15,0.3,-0.4],"part":"hindleg_l"},
  {"op":"box","size":[0.1,0.6,0.1],"position":[-0.15,0.3,-0.4],"part":"hindleg_r"}]})";
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
const char* kTailModel = R"({"format":"factoria.model/1","nodes":[
  {"op":"box","size":[0.2,0.2,0.4],"position":[0,0.5,0.2],"part":"body"},
  {"op":"box","size":[0.1,0.1,2.0],"position":[0,0.5,-1.0],"part":"tail"}]})";

// A baked rig kept alive with the skeleton its Rig3D points at.
struct Baked {
    std::vector<std::uint8_t> glb;
    std::unique_ptr<SkeletonAsset> sk;
    Rig3D rig;
    int node(const char* name) const {
        const int n = rig.find(name);
        REQUIRE_MESSAGE(n >= 0, name);
        return n;
    }
};

std::shared_ptr<Baked> bake(const char* model, const char* tmpl, const char* options = "{}") {
    auto doc = parse_model_doc(J(model), "t.model.json");
    REQUIRE(doc.ok());
    auto b = evaluate_model(*doc);
    REQUIRE(b.ok());
    std::string text = std::string(R"({"format":"factoria.rig/1","model":"p.model.json","template":")") + tmpl + R"(","options":)" + options + "}";
    std::vector<RigIssue> issues;
    auto rd = parse_rig_doc(J(text.c_str()), "t.rig.json", &issues);
    REQUIRE_MESSAGE(rd.ok(), (rd.ok() ? std::string() : rd.error().to_string()));
    auto fit = fit_rig(*rd, b->data);
    REQUIRE_MESSAGE(fit.ok(), (fit.ok() ? std::string() : fit.error().to_string()));
    auto bytes = rig_to_glb(b->data, *fit, "x.rig.glb");
    REQUIRE(bytes.ok());
    auto out = std::make_shared<Baked>();
    out->glb = *bytes;
    auto sk = parse_skeleton(out->glb, "x.rig.glb");
    REQUIRE_MESSAGE(sk.ok(), (sk.ok() ? std::string() : sk.error().to_string()));
    out->sk = std::make_unique<SkeletonAsset>(std::move(*sk));
    out->rig = make_rig3d(*out->sk);
    return out;
}

std::shared_ptr<Baked> person() { static auto p = bake(kPerson, "humanoid"); return p; }
std::shared_ptr<Baked> kid() { static auto p = bake(kKid, "humanoid"); return p; }
std::shared_ptr<Baked> dog() { static auto p = bake(kDog, "quadruped"); return p; }
std::shared_ptr<Baked> bird() { static auto p = bake(kBird, "bird"); return p; }
std::shared_ptr<Baked> tailrig() { static auto p = bake(kTailModel, "tail", R"({"segments":4})"); return p; }

Anim3DClip generate(const Baked& b, const char* kind, const char* params = "{}") {
    auto r = generate_anim3d(b.rig, kind, J(params));
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().to_string()));
    return *r;
}

// Global position of a bone's head when `clip` is at `t`.
Vec3 head_at(const Baked& b, const Anim3DClip& clip, const char* bone, float t, const Vec3& extra = {}) {
    (void)extra;
    const Anim3DBinding bind = bind_anim3d(clip, *b.sk);
    Pose pose = b.rig.rest;
    sample_anim3d(clip, bind, *b.sk, t, pose);
    return pose_frame(*b.sk, pose).pos[std::size_t(b.node(bone))];
}

float wrap_time(float t, float d) { return t - d * std::floor(t / d); }

bool in_contact(const Anim3DContact& c, float t, float duration) {
    t = wrap_time(t, duration);
    return c.from <= c.to ? (t >= c.from && t <= c.to) : (t >= c.from || t <= c.to);
}

// Every contact of the clip: while the foot is in stance (a little inside it) it stays on the ground and moves back at the ground speed.
void check_stance(const Baked& b, const Anim3DClip& clip, float speedScale, float tolY, float tolV) {
    REQUIRE_FALSE(clip.contacts.empty());
    const float dt = 1.0f / 240.0f;
    for (const Anim3DContact& c : clip.contacts) {
        const int node = b.node(c.bone.c_str());
        const float restY = b.rig.rest_head(node).y;
        int samples = 0;
        for (float t = 0.01f; t < clip.duration - 0.01f; t += 0.01f) {
            const float margin = 0.04f;
            if (!in_contact(c, t - margin, clip.duration) || !in_contact(c, t + margin, clip.duration)) continue;
            const Vec3 p0 = head_at(b, clip, c.bone.c_str(), t - dt), p1 = head_at(b, clip, c.bone.c_str(), t + dt);
            const Vec3 p = head_at(b, clip, c.bone.c_str(), t);
            INFO(c.bone << " at t=" << t << ": height " << p.y << " rest " << restY << ", z speed " << (p1.z - p0.z) / (2 * dt)
                          << " ground speed " << clip.groundSpeed * speedScale);
            CHECK(std::fabs(p.y - restY) <= tolY);
            CHECK(std::fabs((p1.z - p0.z) / (2 * dt) + clip.groundSpeed * speedScale) <= tolV * clip.groundSpeed * speedScale + 1e-3f);
            CHECK(std::fabs((p1.x - p0.x) / (2 * dt)) <= 0.15f);
            ++samples;
        }
        CHECK(samples > 5);
    }
}

struct TempProject {
    std::filesystem::path dir, old;
    TempProject() {
        old = fs::project_root();
        dir = std::filesystem::temp_directory_path() / ("fa_anim3d_test_" + std::to_string(std::uintptr_t(this) % 100000));
        std::filesystem::remove_all(dir);
        std::filesystem::create_directories(dir);
        fs::set_project_root(dir);
        clear_anim3d_cache();
    }
    ~TempProject() {
        fs::set_project_root(old);
        std::error_code ec;
        std::filesystem::remove_all(dir, ec);
    }
};

}  // namespace

TEST_CASE("rig3d: roles, sides, chains and rest directions of a baked rig") {
    const Baked& b = *person();
    CHECK(b.rig.templateName == "humanoid");
    CHECK(b.rig.hasRoles);
    CHECK(b.rig.identityRest);
    CHECK(b.rig.find("thigh_l") >= 0);
    CHECK(b.rig.find("nope") == -1);
    CHECK(b.rig.find_role("thigh", 0, "l") == b.rig.find("thigh_l"));
    CHECK(b.rig.chain("spine").size() >= 2);
    // The extras written by rig.bake: unit axis and a length per bone.
    const int shin = b.node("shin_l");
    CHECK(length(b.rig.axis[std::size_t(shin)]) == doctest::Approx(1.0f).epsilon(1e-3));
    CHECK(b.rig.axis[std::size_t(shin)].y < -0.9f);
    CHECK(b.rig.length[std::size_t(shin)] > 0.2f);
    CHECK(rig_generator_problem(b.rig).empty());
    CHECK(b.rig.rest_head(b.node("foot_l")).y < b.rig.rest_head(b.node("shin_l")).y);
    const auto names = b.rig.bone_names();
    CHECK(std::find(names.begin(), names.end(), "head") != names.end());
}

TEST_CASE("anim3d: a clip round-trips through JSON and the loader names the first problem") {
    const char* text = R"({"format":"factoria.anim3d/1","doc":"nod","duration":1.0,"loop":true,"groundSpeed":0.5,
      "tracks":[{"bone":"head","channel":"rotation","keys":[{"t":0,"value":[0,0,0]},{"t":0.5,"value":[20,0,0],"interp":"quadInOut"},{"t":1,"value":[0,0,0]}]},
                {"bone":"root","channel":"translation","keys":[{"t":0,"value":[0,0,0]},{"t":1,"value":[0,0.1,0],"interp":"step"}]}],
      "events":[{"t":0.25,"name":"nod","data":{"k":1}}],
      "contacts":[{"bone":"foot_l","from":0.7,"to":0.2}]})";
    std::vector<ClipIssue> issues;
    auto c = parse_anim3d(J(text), "nod.anim.json", &issues);
    REQUIRE_MESSAGE(c.ok(), (c.ok() ? std::string() : c.error().to_string()));
    CHECK(issues.empty());
    CHECK((*c)->tracks.size() == 2);
    CHECK((*c)->groundSpeed == doctest::Approx(0.5f));
    CHECK((*c)->contacts.size() == 1);
    CHECK((*c)->events.size() == 1);
    const Json out = anim3d_to_json(**c);
    auto again = parse_anim3d(out, "again.anim.json");
    REQUIRE(again.ok());
    CHECK(anim3d_to_json(**again).dump() == out.dump());
    CHECK(is_anim3d_json(out));

    // Bad files teach: the pointer, what is wrong, the way out.
    auto bad = parse_anim3d(J(R"({"format":"factoria.anim3d/1","duration":1,"tracks":[{"bone":"head","channel":"spin","keys":[]}]})"), "bad.anim.json", &issues);
    CHECK_FALSE(bad.ok());
    REQUIRE_FALSE(issues.empty());
    CHECK(issues[0].pointer.find("/tracks/0") == 0);
    CHECK_FALSE(issues[0].hint.empty());
    auto notAClip = parse_anim3d(J(R"({"format":"factoria.anim/1","duration":1,"tracks":[]})"), "x.anim.json");
    CHECK_FALSE(notAClip.ok());
}

TEST_CASE("anim3d: sampling poses the bones (euler, quaternion, easing) and matches the Animator clip") {
    const Baked& b = *person();
    Anim3DClip clip;
    clip.duration = 1.0f;
    Anim3DTrack head;
    head.bone = "head";
    ClipKey k0, k1;
    k0.t = 0;
    k0.value = {0, 0, 0, 0};
    k1.t = 1;
    k1.value = {30, 0, 0, 0};
    head.keys = {k0, k1};
    clip.tracks.push_back(head);
    Anim3DTrack root;
    root.bone = "root";
    root.channel = Anim3DChannel::Translation;
    k0.value = {0, 0, 0, 0};
    k1.value = {0, 0.2f, 0, 0};
    root.keys = {k0, k1};
    clip.tracks.push_back(root);
    clip.tracks.push_back(Anim3DTrack{"ghost", Anim3DChannel::Rotation, {k0, k1}});

    const Anim3DBinding bind = bind_anim3d(clip, *b.sk);
    CHECK(bind.node[0] == b.node("head"));
    CHECK(bind.node[2] == -1);
    REQUIRE(bind.missing.size() == 1);
    CHECK(bind.missing[0] == "ghost");
    CHECK_FALSE(check_anim3d_rig(clip, b.rig).empty());

    Pose pose = b.rig.rest;
    sample_anim3d(clip, bind, *b.sk, 0.5f, pose);
    const Quat want = Quat::from_euler_deg({15, 0, 0});
    const Quat got = pose.rotation[std::size_t(b.node("head"))];
    CHECK(rotation_angle_deg(got * want.conjugate()) < 0.05f);
    CHECK(pose.translation[std::size_t(b.node("root"))].y - b.rig.rest.translation[std::size_t(b.node("root"))].y ==
          doctest::Approx(0.1f).epsilon(1e-3));

    // The Animator plays a dense AnimClip: both agree.
    const AnimClip ac = anim3d_to_anim_clip(clip, bind, *b.sk, "nod");
    CHECK(ac.name == "nod");
    CHECK(ac.duration == doctest::Approx(1.0f));
    Pose viaClip = b.rig.rest;
    sample_clip(*b.sk, ac, 0.5f, viaClip);
    for (std::size_t i = 0; i < pose.rotation.size(); ++i) {
        CHECK(rotation_angle_deg(pose.rotation[i] * viaClip.rotation[i].conjugate()) < 0.05f);
        CHECK(length(pose.translation[i] - viaClip.translation[i]) < 1e-4f);
    }

    // Quaternion tracks.
    Anim3DClip q;
    q.quat = true;
    q.duration = 1;
    const Quat half = Quat::axis_angle_deg({1, 0, 0}, 45);
    Anim3DTrack qt;
    qt.bone = "head";
    ClipKey a, z;
    a.t = 0;
    a.value = {0, 0, 0, 1};
    z.t = 1;
    z.value = {half.x, half.y, half.z, half.w};
    qt.keys = {a, z};
    q.tracks.push_back(qt);
    Pose p2 = b.rig.rest;
    sample_anim3d(q, bind_anim3d(q, *b.sk), *b.sk, 1.0f, p2);
    CHECK(rotation_angle_deg(p2.rotation[std::size_t(b.node("head"))] * half.conjugate()) < 0.05f);
}

TEST_CASE("anim3d_gen: a biped walk and run keep the stance foot on the ground and moving back at the ground speed") {
    for (const char* kind : {"walk", "run"}) {
        for (auto bk : {person(), bird()}) {
            INFO(kind << " " << bk->rig.templateName);
            const Anim3DClip clip = generate(*bk, kind);
            CHECK(clip.loop);
            CHECK(clip.groundSpeed > 0.3f);
            CHECK(clip.contacts.size() == 2);
            CHECK(clip.duration > 0.2f);
            check_stance(*bk, clip, 1.0f, 0.01f, 0.06f);
        }
    }
}

TEST_CASE("anim3d_gen: stride parameters set the speed and the gait of a quadruped follows its pattern") {
    const Baked& d = *dog();
    const Anim3DClip walk = generate(d, "walk");
    CHECK(walk.contacts.size() == 4);
    check_stance(d, walk, 1.0f, 0.01f, 0.06f);
    const Anim3DClip trot = generate(d, "trot");
    CHECK(trot.contacts.size() == 4);
    check_stance(d, trot, 1.0f, 0.01f, 0.06f);
    const Anim3DClip gallop = generate(d, "gallop");
    CHECK(gallop.contacts.size() == 4);
    CHECK(gallop.groundSpeed > trot.groundSpeed);
    check_stance(d, gallop, 1.0f, 0.01f, 0.08f);
    // Walk is a lateral sequence: the left hind lands before the left fore, a quarter of a cycle apart.
    auto from = [&](const Anim3DClip& c, const char* bone) {
        for (const auto& k : c.contacts)
            if (k.bone == bone) return k.from / c.duration;
        return -1.0f;
    };
    const float lh = from(walk, "foot_hind_l") >= 0 ? from(walk, "foot_hind_l") : from(walk, "foot_l");
    CHECK(lh >= 0.0f);
    // `run` on a quadruped is a gallop.
    const Anim3DClip run = generate(d, "run");
    CHECK(run.generated["kind"].get<std::string>() == "gallop");

    const Anim3DClip fast = generate(*person(), "walk", R"({"strideLength":0.6,"cadence":2})");
    CHECK(fast.groundSpeed == doctest::Approx(1.2f).epsilon(1e-3));
    CHECK(fast.duration == doctest::Approx(0.5f).epsilon(1e-3));
}

TEST_CASE("anim3d_gen: feet lift in the swing, the legs keep their length, the loop closes and the output is deterministic") {
    const Baked& p = *person();
    const Anim3DClip clip = generate(p, "walk", R"({"footLift":0.12,"bounce":0.03})");
    const int foot = p.node("foot_l");
    const float restY = p.rig.rest_head(foot).y;
    float maxY = 0;
    for (float t = 0; t <= clip.duration; t += 0.01f) maxY = std::max(maxY, head_at(p, clip, "foot_l", t).y);
    CHECK(maxY - restY > 0.08f);
    CHECK(maxY - restY < 0.2f);

    // Bones are rigid: the thigh to ankle distance never exceeds the rest length.
    const float reach = length(p.rig.rest_head(foot) - p.rig.rest_head(p.node("thigh_l")));
    for (float t = 0; t <= clip.duration; t += 0.05f) {
        const float d = length(head_at(p, clip, "foot_l", t) - head_at(p, clip, "thigh_l", t));
        CHECK(d <= reach + 1e-3f);
    }
    // Pelvis bounce: the root dips below its rest height and rises back.
    float minRoot = 10, maxRoot = -10;
    for (float t = 0; t <= clip.duration; t += 0.01f) {
        const float y = head_at(p, clip, "root", t).y;
        minRoot = std::min(minRoot, y);
        maxRoot = std::max(maxRoot, y);
    }
    CHECK(maxRoot - minRoot > 0.01f);
    CHECK(maxRoot - minRoot < 0.08f);

    // The loop closes: the first and the last pose agree.
    const Anim3DBinding bind = bind_anim3d(clip, *p.sk);
    Pose a = p.rig.rest, z = p.rig.rest;
    sample_anim3d(clip, bind, *p.sk, 0.0f, a);
    sample_anim3d(clip, bind, *p.sk, clip.duration, z);
    for (std::size_t i = 0; i < a.rotation.size(); ++i) {
        CHECK(rotation_angle_deg(a.rotation[i] * z.rotation[i].conjugate()) < 0.01f);
        CHECK(length(a.translation[i] - z.translation[i]) < 1e-4f);
    }

    // Same rig, same parameters, same file bytes.
    const Anim3DClip again = generate(p, "walk", R"({"footLift":0.12,"bounce":0.03})");
    CHECK(anim3d_to_json(clip).dump() == anim3d_to_json(again).dump());
    // The resolved parameters are recorded, and feeding them back makes the same clip.
    const Anim3DClip fromRecorded = generate(p, "walk", clip.generated["params"].dump().c_str());
    CHECK(fromRecorded.tracks.size() == clip.tracks.size());
    for (float tm = 0; tm <= clip.duration; tm += 0.1f)
        CHECK(length(head_at(p, fromRecorded, "foot_r", tm) - head_at(p, clip, "foot_r", tm)) < 1e-4f);
    // Footstep events at each landing.
    int steps = 0;
    for (const ClipEvent& e : clip.events) steps += e.name == "footstep" ? 1 : 0;
    CHECK(steps == 2);
}

TEST_CASE("anim3d_gen: the catalog lists every kind and parameter, and errors teach") {
    const Json cat = anim3d_generator_catalog();
    REQUIRE(cat.is_array());
    CHECK(cat.size() == anim3d_generator_kinds().size());
    const Baked& p = *person();
    for (const Json& k : cat) {
        CHECK_FALSE(k["doc"].get<std::string>().empty());
        for (const Json& prm : k["params"]) {
            CHECK_FALSE(prm["doc"].get<std::string>().empty());
            CHECK(prm.contains("default"));
        }
        // Every catalog parameter is accepted and every resolved key is in the catalog.
        const std::string kind = k["kind"].get<std::string>();
        auto tmpl = k["templates"];
        if (std::find(tmpl.begin(), tmpl.end(), "humanoid") == tmpl.end()) continue;
        const Anim3DClip c = generate(p, kind.c_str());
        for (auto it = c.generated["params"].begin(); it != c.generated["params"].end(); ++it) {
            bool found = false;
            for (const Json& prm : k["params"]) found = found || prm["name"].get<std::string>() == it.key();
            INFO(kind << " " << it.key());
            CHECK(found);
        }
    }
    auto bad = generate_anim3d(p.rig, "walk", J(R"({"stridelength":1})"));
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().to_string().find("strideLength") != std::string::npos);
    auto kind = generate_anim3d(p.rig, "wlak");
    REQUIRE_FALSE(kind.ok());
    CHECK(kind.error().to_string().find("walk") != std::string::npos);
    auto trot = generate_anim3d(p.rig, "trot");
    REQUIRE_FALSE(trot.ok());
    CHECK_FALSE(trot.error().hint.empty());
    auto far = generate_anim3d(p.rig, "walk", J(R"({"strideLength":5})"));
    REQUIRE_FALSE(far.ok());
    CHECK(far.error().to_string().find("strideLength") != std::string::npos);
    auto noLegs = generate_anim3d(tailrig()->rig, "walk");
    REQUIRE_FALSE(noLegs.ok());
}

TEST_CASE("anim3d_gen: idle, swing and hit") {
    const Baked& p = *person();
    const Anim3DClip idle = generate(p, "idle", R"({"duration":3,"breaths":2,"breathAmount":8})");
    CHECK(idle.loop);
    CHECK(idle.duration == doctest::Approx(3.0f));
    CHECK(idle.groundSpeed == 0.0f);
    // The chest moves, and it moves twice over the clip.
    float lo = 1e9f, hi = -1e9f;
    int crossings = 0;
    std::vector<float> ys;
    const float rest = p.rig.rest_head(p.node("head")).y;
    for (float t = 0; t <= 3.0f; t += 0.02f) {
        const float y = head_at(p, idle, "head", t).y - rest;
        lo = std::min(lo, y);
        hi = std::max(hi, y);
        ys.push_back(y);
    }
    const float mid = (hi + lo) * 0.5f;
    for (std::size_t i = 1; i < ys.size(); ++i) crossings += (ys[i - 1] < mid && ys[i] >= mid) ? 1 : 0;
    CHECK(hi - lo > 0.002f);
    CHECK(crossings == 2);

    // Swing a tail: yaw waves about the rest line and grows towards the tip.
    const Baked& t = *tailrig();
    const Anim3DClip sw = generate(t, "swing", R"({"period":2,"amplitude":20,"growth":1.5})");
    CHECK(sw.loop);
    CHECK(sw.duration == doctest::Approx(2.0f));
    const Anim3DBinding bind = bind_anim3d(sw, *t.sk);
    float first = 0, last = 0;
    const auto chain = t.rig.chain("tail");
    REQUIRE(chain.size() >= 3);
    for (float tm = 0; tm <= 2.0f; tm += 0.02f) {
        Pose pose = t.rig.rest;
        sample_anim3d(sw, bind, *t.sk, tm, pose);
        first = std::max(first, rotation_angle_deg(pose.rotation[std::size_t(chain.front())]));
        last = std::max(last, rotation_angle_deg(pose.rotation[std::size_t(chain.back())]));
    }
    CHECK(first > 1.0f);
    CHECK(last > first);
    auto unknown = generate_anim3d(p.rig, "swing", J(R"({"bones":["nonsense"]})"));
    REQUIRE_FALSE(unknown.ok());

    // A hit reaction plays once, flinches away and returns to rest, and fires its event.
    const Anim3DClip hit = generate(p, "hit", R"({"strength":30,"fromAngle":0,"event":"hurt"})");
    CHECK_FALSE(hit.loop);
    const float restHead = p.rig.rest_head(p.node("head")).z;
    float maxShift = 0;
    for (float tm = 0; tm <= hit.duration; tm += 0.01f) maxShift = std::max(maxShift, std::fabs(head_at(p, hit, "head", tm).z - restHead));
    INFO("max shift " << maxShift);
    CHECK(maxShift > 0.03f);
    CHECK(std::fabs(head_at(p, hit, "head", hit.duration).z - restHead) < 0.01f);
    CHECK_FALSE(hit.events.empty());
    // From the left the flinch goes to the right (-x).
    const Anim3DClip left = generate(p, "hit", R"({"fromAngle":90})");
    const Anim3DClip right = generate(p, "hit", R"({"fromAngle":-90})");
    float sl = 0, sr = 0;
    for (float tm = 0; tm <= left.duration; tm += 0.01f) {
        sl += head_at(p, left, "head", tm).x - p.rig.rest_head(p.node("head")).x;
        sr += head_at(p, right, "head", tm).x - p.rig.rest_head(p.node("head")).x;
    }
    CHECK(sl * sr < 0.0f);
}

TEST_CASE("anim3d_retarget: a walk keeps its feet planted on a rig with other proportions") {
    const Baked& p = *person();
    const Baked& k = *kid();
    const Anim3DClip walk = generate(p, "walk");
    auto r = retarget_anim3d(walk, p.rig, k.rig);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().to_string()));
    const float legP = length(p.rig.rest_head(p.node("thigh_l")) - p.rig.rest_head(p.node("foot_l")));
    const float legK = length(k.rig.rest_head(k.node("thigh_l")) - k.rig.rest_head(k.node("foot_l")));
    CHECK(r->scale == doctest::Approx(legK / legP).epsilon(0.02));
    CHECK(r->clip.groundSpeed == doctest::Approx(walk.groundSpeed * r->scale).epsilon(0.02));
    CHECK(r->clip.duration == doctest::Approx(walk.duration));
    CHECK(r->mapped > 10);
    CHECK(r->dropped.empty());
    CHECK(r->planted.size() == 2);
    CHECK(r->clip.contacts.size() == 2);
    check_stance(k, r->clip, 1.0f, 0.015f, 0.12f);

    // Without planting the tracks are only scaled copies, and the feet slide on the shorter legs less accurately.
    RetargetOptions loose;
    loose.plantFeet = false;
    auto l = retarget_anim3d(walk, p.rig, k.rig, loose);
    REQUIRE(l.ok());
    CHECK(l->planted.empty());

    // The explicit scale wins.
    RetargetOptions two;
    two.scale = 2.0f;
    auto t = retarget_anim3d(walk, p.rig, k.rig, two);
    REQUIRE(t.ok());
    CHECK(t->scale == doctest::Approx(2.0f));
    CHECK(t->clip.groundSpeed == doctest::Approx(walk.groundSpeed * 2.0f));
}

TEST_CASE("anim3d_retarget: bones with no counterpart are dropped and chains of other lengths are resampled") {
    const Baked& p = *person();
    // A person with a longer spine.
    static auto tall = bake(kPerson, "humanoid", R"({"spine":5})");
    const Anim3DClip walk = generate(p, "walk");
    auto r = retarget_anim3d(walk, p.rig, tall->rig);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().to_string()));
    REQUIRE_FALSE(r->resampled.empty());
    CHECK(r->resampled[0].find("spine") == 0);
    check_stance(*tall, r->clip, 1.0f, 0.015f, 0.12f);

    // A person to a tail: nothing in common but the root.
    auto none = retarget_anim3d(walk, p.rig, tailrig()->rig);
    if (none.ok()) {
        CHECK_FALSE(none->dropped.empty());
        CHECK_FALSE(none->notes.empty());
    } else {
        CHECK_FALSE(none.error().hint.empty());
    }

    // A person to a dog: the legs map by role (thigh/shin/foot are the hind legs, arm_upper/arm_lower/hand the fore legs).
    auto dogged = retarget_anim3d(walk, p.rig, dog()->rig);
    REQUIRE_MESSAGE(dogged.ok(), (dogged.ok() ? std::string() : dogged.error().to_string()));
    CHECK(dogged->mapped > 5);
}

// ------------------------------------------------------------------------------------------------------------------- IK --
TEST_CASE("ik3d: two-bone IK reaches a target inside the reach and bends towards the pole") {
    const Baked& p = *person();
    const int up = p.node("arm_upper_l"), lo = p.node("arm_lower_l"), hand = p.node("hand_l");
    const Vec3 shoulder = p.rig.rest_head(up);
    const float l1 = length(p.rig.rest_head(lo) - shoulder), l2 = length(p.rig.rest_head(hand) - p.rig.rest_head(lo));

    // A target in front of the shoulder, inside the reach; the elbow bends down (pole below) or up (pole above).
    const Vec3 target = shoulder + Vec3{0.1f, 0.0f, 0.45f};
    for (float side : {-1.0f, 1.0f}) {
        Pose pose = p.rig.rest;
        auto r = solve_two_bone(*p.sk, pose, up, lo, hand, target, shoulder + Vec3{0.1f, side, 0.2f});
        REQUIRE(r.ok());
        CHECK(r->reached);
        CHECK(r->error < 1e-3f);
        const PoseFrame f = pose_frame(*p.sk, pose);
        CHECK(length(f.pos[std::size_t(hand)] - target) < 2e-3f);
        // Bone lengths are kept.
        CHECK(length(f.pos[std::size_t(lo)] - f.pos[std::size_t(up)]) == doctest::Approx(l1).epsilon(1e-3));
        CHECK(length(f.pos[std::size_t(hand)] - f.pos[std::size_t(lo)]) == doctest::Approx(l2).epsilon(1e-3));
        // The elbow is on the pole's side of the shoulder-target line.
        const Vec3 line = normalize(target - shoulder);
        const Vec3 elbow = f.pos[std::size_t(lo)] - shoulder;
        const Vec3 off = elbow - line * dot(elbow, line);
        CHECK(off.y * side > 0.0f);
    }

    // Out of reach: the limb is straight towards the target, `reached` is false and the error is the shortfall.
    Pose far = p.rig.rest;
    const Vec3 away = shoulder + Vec3{0, 0, 3.0f};
    auto r = solve_two_bone(*p.sk, far, up, lo, hand, away);
    REQUIRE(r.ok());
    CHECK_FALSE(r->reached);
    CHECK(r->error == doctest::Approx(3.0f - (l1 + l2)).epsilon(1e-2));
    const PoseFrame ff = pose_frame(*p.sk, far);
    CHECK(length(ff.pos[std::size_t(hand)] - shoulder) == doctest::Approx(l1 + l2).epsilon(1e-3));

    // Weight blends from the animated pose to the solved one.
    Pose half = p.rig.rest;
    auto h = solve_two_bone(*p.sk, half, up, lo, hand, target, std::nullopt, 0.5f);
    REQUIRE(h.ok());
    const Vec3 restHand = p.rig.rest_head(hand);
    const Vec3 got = pose_frame(*p.sk, half).pos[std::size_t(hand)];
    CHECK(length(got - target) < length(restHand - target));
    CHECK(length(got - restHand) < length(target - restHand));
    Pose none = p.rig.rest;
    REQUIRE(solve_two_bone(*p.sk, none, up, lo, hand, target, std::nullopt, 0.0f).ok());
    CHECK(length(pose_frame(*p.sk, none).pos[std::size_t(hand)] - restHand) < 1e-4f);

    // Nodes that are not a chain are refused with a teaching error.
    Pose bad = p.rig.rest;
    auto e = solve_two_bone(*p.sk, bad, up, hand, lo, target);
    CHECK_FALSE(e.ok());
}

TEST_CASE("ik3d: look-at aims the bone within its limits") {
    const Baked& p = *person();
    const int head = p.node("head");
    const Vec3 eye = p.rig.rest_head(head);
    auto aim = [&](Vec3 target, LookAtParams params, Quat& state, LookAtResult& res) {
        Pose pose = p.rig.rest;
        res = solve_look_at(*p.sk, pose, head, target, params, state);
        const PoseFrame f = pose_frame(*p.sk, pose);
        return f.rot[std::size_t(head)].rotate(params.forward);
    };
    Quat state;
    LookAtResult res;
    // Inside the limits the head looks straight at the target.
    Vec3 want = normalize(Vec3{0.4f, 0.1f, 1.0f});
    Vec3 got = aim(eye + want * 3.0f, {}, state, res);
    CHECK_FALSE(res.clamped);
    CHECK(length(got - want) < 1e-3f);
    CHECK(res.yaw > 0.0f);  // +Z towards +X is positive
    CHECK(res.pitch > 0.0f);

    // Behind the character: clamped to the yaw limit.
    state = Quat{};
    LookAtParams lim;
    lim.yawLimit = 50.0f;
    got = aim(eye + Vec3{0, 0, -3.0f} + Vec3{1.0f, 0, 0}, lim, state, res);
    CHECK(res.clamped);
    CHECK(std::fabs(res.yaw) <= 50.0f + 0.01f);
    CHECK(std::fabs(res.yaw) > 45.0f);

    // Looking far up: the pitch limit.
    state = Quat{};
    LookAtParams pl;
    pl.pitchLimit = 20.0f;
    got = aim(eye + Vec3{0, 5.0f, 0.5f}, pl, state, res);
    CHECK(res.clamped);
    CHECK(res.pitch == doctest::Approx(20.0f).epsilon(0.02));

    // Weight 0 leaves the animated pose; a turn-speed cap moves it a bit at a time.
    state = Quat{};
    LookAtParams zero;
    zero.weight = 0.0f;
    got = aim(eye + Vec3{3.0f, 0, 1.0f}, zero, state, res);
    CHECK(length(got - Vec3{0, 0, 1}) < 1e-4f);
    state = Quat{};
    LookAtParams slow;
    slow.maxTurn = radians(5.0f);
    got = aim(eye + Vec3{3.0f, 0, 1.0f}, slow, state, res);
    CHECK(std::fabs(res.yaw) <= 5.01f);
    got = aim(eye + Vec3{3.0f, 0, 1.0f}, slow, state, res);
    CHECK(std::fabs(res.yaw) <= 10.01f);
    CHECK(std::fabs(res.yaw) > 5.0f);
}

namespace {

// A person standing in a scene: an Animator on the bind pose and an IK3D with `solvers`. The model is the in-memory rig written to a
// temporary project, because the Animator loads its model by path.
struct IKScene {
    TempProject project;
    World world;
    Entity e;
    Animator* a;
    IK3D* ik;
    explicit IKScene(const Baked& baked, const char* solvers) {
        ensure_builtin_components();
        REQUIRE(fs::write_bytes("hero.rig.glb", baked.glb.data(), baked.glb.size()));
        e = world.create("hero", "hero");
        world.add<MeshRenderer>(e).mesh = "hero.rig.glb";
        a = &world.add<Animator>(e);
        ik = &world.add<IK3D>(e);
        ik->solvers = J(solvers);
        ik->pelvisSmooth = 0.0f;
    }
    void step(const GroundRaycast& ground, float dt = 1.0f / 60.0f) {
        update_animators(world, dt);
        update_ik3d(world, dt, ground);
    }
    // Where the palette puts a bone's head (rest position through the skinning matrix).
    Vec3 head(const Baked& b, const char* bone) const {
        const int node = b.node(bone);
        return a->palette.at(std::size_t(b.rig.boneOfNode[std::size_t(node)])).transform_point(b.rig.rest_head(node));
    }
};

}  // namespace

TEST_CASE("ik3d: foot placement lowers the pelvis for a lower foot and lifts a foot onto a step") {
    const Baked& p = *person();
    IKScene s(p, R"([{"type":"foot","side":"l"},{"type":"foot","side":"r"}])");
    const float restY = p.rig.rest_head(p.node("foot_l")).y;

    // Flat ground at 0: nothing moves.
    auto flat = [](Vec3 origin, Vec3, float, std::int32_t, Entity) -> std::optional<GroundHit> { return GroundHit{{origin.x, 0, origin.z}, {0, 1, 0}}; };
    s.step(flat);
    CHECK(s.head(p, "foot_l").y == doctest::Approx(restY).epsilon(0.02));
    CHECK(s.head(p, "foot_r").y == doctest::Approx(restY).epsilon(0.02));
    CHECK(s.head(p, "root").y == doctest::Approx(p.rig.rest_head(p.node("root")).y).epsilon(0.01));
    REQUIRE(s.ik->status.is_array());
    CHECK(s.ik->status.size() == 2);

    // A step under the left foot only: that foot is lifted on it, the right one stays, the pelvis does not move.
    auto step = [](Vec3 origin, Vec3, float, std::int32_t, Entity) -> std::optional<GroundHit> {
        return GroundHit{{origin.x, origin.x > 0 ? 0.1f : 0.0f, origin.z}, {0, 1, 0}};
    };
    s.step(step);
    CHECK(s.head(p, "foot_l").y == doctest::Approx(restY + 0.1f).epsilon(0.02));
    CHECK(s.head(p, "foot_r").y == doctest::Approx(restY).epsilon(0.02));
    CHECK(s.ik->rt.pelvisShift == doctest::Approx(0.0f).epsilon(0.01));

    // A drop under the left foot: the pelvis goes down to the lowest ground and the right leg bends to keep its foot on its ground.
    auto drop = [](Vec3 origin, Vec3, float, std::int32_t, Entity) -> std::optional<GroundHit> {
        return GroundHit{{origin.x, origin.x > 0 ? -0.2f : 0.0f, origin.z}, {0, 1, 0}};
    };
    s.step(drop);
    CHECK(s.ik->rt.pelvisShift == doctest::Approx(-0.2f).epsilon(0.02));
    CHECK(s.head(p, "foot_l").y == doctest::Approx(restY - 0.2f).epsilon(0.03));
    CHECK(s.head(p, "foot_r").y == doctest::Approx(restY).epsilon(0.03));
    CHECK(s.head(p, "root").y < p.rig.rest_head(p.node("root")).y - 0.15f);

    // The pelvis drop is capped.
    auto pit = [](Vec3 origin, Vec3, float, std::int32_t, Entity) -> std::optional<GroundHit> { return GroundHit{{origin.x, -0.7f, origin.z}, {0, 1, 0}}; };
    s.ik->rayDown = 2.0f;
    s.step(pit);
    CHECK(s.ik->rt.pelvisShift == doctest::Approx(-s.ik->maxPelvisDrop).epsilon(0.01));

    // No ground under the feet: the animated pose again.
    auto none = [](Vec3, Vec3, float, std::int32_t, Entity) -> std::optional<GroundHit> { return std::nullopt; };
    s.step(none);
    CHECK(s.head(p, "foot_l").y == doctest::Approx(restY).epsilon(0.02));
    CHECK(s.head(p, "root").y == doctest::Approx(p.rig.rest_head(p.node("root")).y).epsilon(0.01));

    // Disabled: the animated pose is drawn again at once.
    s.step(drop);
    s.ik->enabled = false;
    s.step(drop);
    CHECK(s.head(p, "root").y == doctest::Approx(p.rig.rest_head(p.node("root")).y).epsilon(0.01));
}

TEST_CASE("ik3d: foot placement tilts the foot to a slope and a two-bone solver follows a named entity") {
    const Baked& p = *person();
    IKScene s(p, R"([{"type":"foot","side":"l","alignToGround":true},{"type":"twoBone","limb":"arm","side":"l","target":[0.5,1.3,0.5]},
                     {"type":"lookAt","bone":"head","target":[0,1.8,3]}])");
    auto slope = [](Vec3 origin, Vec3, float, std::int32_t, Entity) -> std::optional<GroundHit> {
        const Vec3 n = normalize(Vec3{0, 1, 0.3f});
        return GroundHit{{origin.x, 0.0f, origin.z}, n};
    };
    s.step(slope);
    const Vec3 hand = s.head(p, "hand_l");
    CHECK(length(hand - Vec3{0.5f, 1.3f, 0.5f}) < 0.02f);
    REQUIRE(s.ik->status.size() == 3);
    CHECK(s.ik->status[1]["reached"].get<bool>());
    CHECK(s.ik->status[2]["type"].get<std::string>() == "lookAt");

    // The sole follows the slope: the toe end is no longer at the ankle's height.
    const int foot = p.node("foot_l");
    const Vec3 tip = s.a->palette.at(std::size_t(p.rig.boneOfNode[std::size_t(foot)]))
                         .transform_point(p.rig.rest_head(foot) + p.rig.axis[std::size_t(foot)] * p.rig.length[std::size_t(foot)]);
    const Vec3 ank = s.head(p, "foot_l");
    CHECK(std::fabs(tip.y - ank.y) > 0.005f);

    // A mistake in a solver is reported once and skips only that solver; the others still run.
    IKScene bad(p, R"([{"type":"lookAt","bone":"hed","target":[0,1.8,3]},{"type":"twoBone","limb":"arm","side":"l","target":[0.5,1.3,0.5]}])");
    bad.step(slope);
    CHECK(length(bad.head(p, "hand_l") - Vec3{0.5f, 1.3f, 0.5f}) < 0.02f);
    CHECK(bad.ik->status[0].contains("problem"));

    const auto issues = ik3d_check_solvers(J(R"([{"type":"lookAt","bone":"hed","target":[0,1,3]},{"type":"fly"},{"type":"twoBone","limb":"arm"}])"), &p.rig);
    REQUIRE(issues.size() >= 3);
    CHECK(issues[0].pointer == "/0/bone");
    const bool suggests = issues[0].message.find("head") != std::string::npos || issues[0].hint.find("head") != std::string::npos;
    CHECK(suggests);
    CHECK(issues[1].pointer.find("/1") == 0);
}

// ------------------------------------------------------------------------------------------------------- runtime playback --
TEST_CASE("anim3d: the Animator plays a 3D clip file on a skinned rig, with events, looping and a changed file") {
    const Baked& p = *person();
    TempProject project;
    ensure_builtin_components();
    REQUIRE(fs::write_bytes("hero.rig.glb", p.glb.data(), p.glb.size()));
    const std::string nod = R"({"format":"factoria.anim3d/1","duration":1.0,"loop":true,
      "tracks":[{"bone":"head","channel":"rotation","keys":[{"t":0,"value":[0,0,0]},{"t":1,"value":[40,0,0]}]},
                {"bone":"root","channel":"translation","keys":[{"t":0,"value":[0,0,0]},{"t":1,"value":[0,0.5,0]}]}],
      "events":[{"t":0.5,"name":"mid"}]})";
    REQUIRE(fs::write_text("nod.anim.json", nod));

    World world;
    Entity e = world.create("hero", "hero");
    world.add<MeshRenderer>(e).mesh = "hero.rig.glb";
    Animator& a = world.add<Animator>(e);
    a.clips = J(R"({"nod":"nod.anim.json"})");
    a.clip = "nod";
    a.fade = 0.0f;
    const int headNode = p.node("head");
    const int headJoint = p.rig.boneOfNode[std::size_t(headNode)];
    const int rootJoint = p.rig.boneOfNode[std::size_t(p.node("root"))];
    auto step = [&](float dt) {
        update_animators(world, dt);
        std::vector<std::string> names;
        for (const GameEvent& g : world.events().game) names.push_back(g.name);
        world.events().game.clear();
        return names;
    };
    auto headTop = [&] {  // where the top of the head ends up
        return a.palette.at(std::size_t(headJoint)).transform_point(p.rig.rest_head(headNode) + Vec3{0, 0.2f, 0});
    };
    auto rootY = [&] { return a.palette.at(std::size_t(rootJoint)).transform_point(p.rig.rest_head(p.node("root"))).y; };

    CHECK(step(0.25f).empty());
    CHECK(a.palette.size() == p.sk->skins[0].joints.size());
    CHECK(rootY() - p.rig.rest_head(p.node("root")).y == doctest::Approx(0.125f).epsilon(0.02));
    const Vec3 restTop = p.rig.rest_head(headNode) + Vec3{0, 0.2f, 0};
    CHECK(headTop().z > restTop.z + 0.01f);  // +pitch tips the head forward
    const auto ev = step(0.3f);
    REQUIRE(ev.size() == 1);
    CHECK(ev[0] == "mid");
    // The clip loops: after a second the head is back near the start.
    step(0.2f);
    step(0.5f);
    CHECK(a.time < 0.5f);
    CHECK(rootY() - p.rig.rest_head(p.node("root")).y < 0.3f);

    // loop=false holds the last pose.
    a.loop = false;
    a.time = 0.0f;
    for (int i = 0; i < 8; ++i) step(0.25f);
    CHECK(rootY() - p.rig.rest_head(p.node("root")).y == doctest::Approx(0.5f).epsilon(0.02));

    // A file that names a bone the model lacks still plays, skipping that track (one warning, in clipWarnings).
    REQUIRE(fs::write_text("ghost.anim.json", R"({"format":"factoria.anim3d/1","duration":1,"tracks":[{"bone":"ghost","channel":"rotation","keys":[{"t":0,"value":[0,0,0]},{"t":1,"value":[10,0,0]}]}]})"));
    a.clips = J(R"({"nod":"nod.anim.json","ghost":"ghost.anim.json"})");
    a.clip = "ghost";
    step(0.1f);
    CHECK_FALSE(a.rt.clipWarnings.empty());
    CHECK(a.rt.clipWarnings[0].find("ghost") != std::string::npos);
}

TEST_CASE("schemas/anim3d.schema.json lists what the loader accepts") {
    std::ifstream f(std::string(FA_REPO_ROOT) + "/schemas/anim3d.schema.json", std::ios::binary);
    std::stringstream ss;
    ss << f.rdbuf();
    const Json schema = Json::parse(ss.str());
    CHECK(schema["properties"]["format"]["const"] == kAnim3DFormat);
    auto keysOf = [](const Json& o) {
        std::set<std::string> out;
        for (auto& [k, v] : o.items()) out.insert(k);
        return out;
    };
    CHECK(keysOf(schema["properties"]) == std::set<std::string>{"$schema", "format", "doc", "rig", "template", "duration", "loop", "rotation",
                                                                 "groundSpeed", "tracks", "events", "contacts", "generated"});
    CHECK(keysOf(schema["$defs"]["track"]["properties"]) == std::set<std::string>{"bone", "channel", "keys"});
    CHECK(keysOf(schema["$defs"]["key"]["properties"]) == std::set<std::string>{"t", "value", "interp", "in", "out"});
    CHECK(keysOf(schema["$defs"]["event"]["properties"]) == std::set<std::string>{"t", "name", "data", "feel"});
    CHECK(keysOf(schema["$defs"]["contact"]["properties"]) == std::set<std::string>{"bone", "from", "to"});
    std::set<std::string> eases;
    for (const Json& n : schema["$defs"]["key"]["properties"]["interp"]["anyOf"][1]["enum"]) eases.insert(n.get<std::string>());
    CHECK(eases == std::set<std::string>(clip_ease_names().begin() + 1, clip_ease_names().end()));
    // A 2D loader pointed at a 3D file says what it is.
    auto two = parse_anim_clip(J(R"({"format":"factoria.anim3d/1","duration":1,"tracks":[]})"), "x.anim.json");
    REQUIRE_FALSE(two.ok());
    CHECK(two.error().hint.find("3D bone clip") != std::string::npos);
}
