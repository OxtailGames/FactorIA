// The Animation panel's 3D mode (anim3d_model.h): every edit is the anim3d.* / ik3d.key call an AI would make and returns the undo the editor's stack
// keeps, a clip opens with the rig that poses it, and the maths of the bone tools (rings, planes, limbs) agree with the camera of the view. No window:
// the model calls the real commands of a temporary project.
#include <cmath>
#include <filesystem>
#include <fstream>
#include <format>

#include "anim3d_model.h"
#include "doctest.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/scene/ik3d.h"
#include "fa/tooling/asset_import.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

std::string person() {
    return R"({"format":"factoria.model/1","nodes":[
        {"op":"box","size":[0.36,0.2,0.2],"position":[0,0.95,0],"part":"pelvis"},
        {"op":"box","size":[0.4,0.5,0.22],"position":[0,1.3,0],"part":"torso"},
        {"op":"box","size":[0.1,0.1,0.1],"position":[0,1.6,0],"part":"neck"},
        {"op":"box","size":[0.22,0.25,0.22],"position":[0,1.77,0.02],"part":"head"},
        {"op":"box","size":[0.7,0.1,0.1],"position":[0.55,1.5,0],"part":"arm_l"},
        {"op":"box","size":[0.7,0.1,0.1],"position":[-0.55,1.5,0],"part":"arm_r"},
        {"op":"box","size":[0.14,0.9,0.14],"position":[0.11,0.45,0],"part":"leg_l"},
        {"op":"box","size":[0.14,0.9,0.14],"position":[-0.11,0.45,0],"part":"leg_r"}]})";
}

constexpr const char* kRig = "assets/models/hero.rig.glb";
constexpr const char* kClip = "anim/hero_walk.anim.json";

struct Anim3DProject {
    stdfs::path dir;
    CommandRegistry registry;
    std::unique_ptr<Anim3DModel> model;
    Anim3DProject() {
        dir = fs::make_temp_dir("fa_anim3d_panel").value();
        register_asset_commands(registry, dir.string());
        model = std::make_unique<Anim3DModel>(
            dir.string(), [this](const std::string& name, const Json& args) { return registry.call(name, args); });
        stdfs::create_directories(dir / "assets/models");
        std::ofstream(dir / "assets/models/hero.model.json") << person();
        ok("rig.create", {{"path", "assets/models/hero.rig.json"},
                          {"model", "assets/models/hero.model.json"},
                          {"template", "humanoid"}});
        ok("anim3d.generate", {{"rig", kRig}, {"kind", "walk"}, {"out", kClip}});
    }
    ~Anim3DProject() {
        model.reset();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    Json ok(const std::string& name, const Json& args) {
        CommandResult r = registry.call(name, args);
        REQUIRE_MESSAGE(r.ok, name << ": " << r.error.dump());
        return r.result;
    }
    void open() { REQUIRE_MESSAGE(model->open(kClip, kRig), model->error()); }
    std::string text(const std::string& rel = kClip) const {
        std::ifstream in(dir / rel, std::ios::binary);
        return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    }
    // Plays an edit's undo back, as the editor's Undo does.
    void undo(const Anim3DEdit& e) {
        REQUIRE(e.undo.is_object());
        ok(e.undo["command"].get<std::string>(), e.undo["args"]);
        REQUIRE(model->reload());
    }
};

}  // namespace

TEST_CASE("a 3D clip opens with its rig, lists the rig's bones with their key counts and samples a pose") {
    Anim3DProject p;
    p.open();
    CHECK(p.model->is_open());
    CHECK(p.model->has_rig());
    REQUIRE(p.model->clip());
    CHECK(p.model->clip()->duration > 0.3f);
    const std::vector<Anim3DBoneRow> rows = p.model->rows();
    REQUIRE(rows.size() > 8);
    CHECK(rows[0].depth == 0);
    bool any = false;
    for (const Anim3DBoneRow& r : rows) {
        CHECK(p.model->node_of(r.name) == r.node);
        CHECK(p.model->bone_name(r.node) == r.name);
        any = any || r.keys > 0;
    }
    CHECK(any);
    const Pose a = p.model->pose_at(0.0), b = p.model->pose_at(double(p.model->clip()->duration) * 0.25);
    bool differs = false;
    for (std::size_t i = 0; i < a.rotation.size(); ++i)
        if (std::fabs(a.rotation[i].x - b.rotation[i].x) + std::fabs(a.rotation[i].w - b.rotation[i].w) > 1e-4)
            differs = true;
    CHECK(differs);
    const MeshData mesh = p.model->skin(b);
    CHECK(mesh.positions.size() >= 3);
    CHECK(p.model->node_of("no_such_bone") < 0);
}

TEST_CASE("a clip that does not load is an error, and a clip without its rig still opens for the dopesheet") {
    Anim3DProject p;
    CHECK_FALSE(p.model->open("anim/nothing.anim.json", kRig));
    CHECK_FALSE(p.model->error().empty());
    CHECK_FALSE(p.model->is_open());
    CHECK(p.model->open(kClip, "assets/models/missing.rig.glb"));
    CHECK(p.model->clip());
    CHECK_FALSE(p.model->has_rig());
    CHECK_FALSE(p.model->error().empty());
    p.model->close();
    CHECK_FALSE(p.model->is_open());
}

TEST_CASE("anim3d_file_is_3d tells 3D clips from 2D ones and from files that are not clips") {
    Anim3DProject p;
    CHECK(anim3d_file_is_3d(p.dir.string(), kClip));
    stdfs::create_directories(p.dir / "anim");
    std::ofstream(p.dir / "anim/flat.anim.json") << R"({"format":"factoria.anim/1","duration":1,"tracks":[]})";
    CHECK_FALSE(anim3d_file_is_3d(p.dir.string(), "anim/flat.anim.json"));
    CHECK_FALSE(anim3d_file_is_3d(p.dir.string(), "anim/absent.anim.json"));
}

TEST_CASE(
    "keys: set, move, change the easing and delete are one command each, and the undo they return restores the file") {
    Anim3DProject p;
    p.open();
    const std::string before = p.text();
    const std::uint64_t rev = p.model->revision();

    const Anim3DEdit set = p.model->set_key("thigh_l", 0, 0.5, {30, 0, 0, 0});
    REQUIRE_MESSAGE(set.ok, set.error);
    CHECK(p.model->revision() > rev);
    const ClipKey* k = p.model->key_at(Key3D{"thigh_l", 0, 500});
    REQUIRE(k);
    CHECK(std::fabs(k->value[0] - 30.0f) < 0.01f);
    p.undo(set);
    CHECK(p.text() == before);

    const Anim3DEdit sampled = p.model->key_sampled("arm_upper_r", 0, 0.25);
    REQUIRE_MESSAGE(sampled.ok, sampled.error);
    CHECK(p.model->key_at(Key3D{"arm_upper_r", 0, 250}));
    p.undo(sampled);
    CHECK(p.text() == before);

    // an existing key
    Key3D first;
    for (const Anim3DTrack& t : p.model->clip()->tracks)
        if (!t.keys.empty() && t.channel == Anim3DChannel::Rotation) {
            first = Key3D{t.bone, 0, key3d_ms(double(t.keys[1 % t.keys.size()].t))};
            break;
        }
    REQUIRE_FALSE(first.bone.empty());
    REQUIRE(p.model->key_at(first));
    const Anim3DEdit ease = p.model->set_interp({first}, "step");
    REQUIRE_MESSAGE(ease.ok, ease.error);
    CHECK(key3d_interp(*p.model->key_at(first)) == "step");
    p.undo(ease);
    CHECK(p.text() == before);

    const Anim3DEdit moved = p.model->move_keys({first}, 0.04);
    REQUIRE_MESSAGE(moved.ok, moved.error);
    CHECK_FALSE(p.model->key_at(first));
    CHECK(p.model->key_at(Key3D{first.bone, 0, first.ms + 40}));
    p.undo(moved);
    CHECK(p.text() == before);

    const Anim3DEdit gone = p.model->remove_keys({first});
    REQUIRE_MESSAGE(gone.ok, gone.error);
    CHECK_FALSE(p.model->key_at(first));
    p.undo(gone);
    CHECK(p.text() == before);

    const Anim3DEdit bad = p.model->set_interp({Key3D{"thigh_l", 0, 123456}}, "linear");
    CHECK_FALSE(bad.ok);
    CHECK_FALSE(bad.error.empty());
}

TEST_CASE("a rotation key made from a gizmo pose reads back as the same pose") {
    Anim3DProject p;
    p.open();
    const int node = p.model->node_of("thigh_l");
    REQUIRE(node >= 0);
    const Anim3DRigModel& rig = *p.model->rig();
    Pose base = p.model->pose_at(0.0);
    const Vec3 headBefore = bone_head(rig, base, node);
    Pose turned = base;
    turned.rotation[std::size_t(node)] = rotated_local(rig, base, node, 0, 0.5);
    const Quat delta = pose_delta_rotation(rig.rig, turned, node);
    const auto value = rotation_key_value(*p.model->clip(), delta);
    const Anim3DEdit e = p.model->set_key("thigh_l", 0, 0.0, value);
    REQUIRE_MESSAGE(e.ok, e.error);
    const Pose back = p.model->pose_at(0.0);
    const Quat& a = back.rotation[std::size_t(node)];
    const Quat& b = turned.rotation[std::size_t(node)];
    CHECK(std::fabs(std::fabs(a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w) - 1.0f) < 1e-3f);
    CHECK(length(bone_head(rig, back, node) - headBefore) <
          1e-4f);  // turning a bone moves its tail and children, not its own head
}

TEST_CASE("an IK key poses the limb and keys the chain; the undo restores the clip") {
    Anim3DProject p;
    p.open();
    const int foot = p.model->node_of("foot_l");
    REQUIRE(foot >= 0);
    const Anim3DRigModel& rig = *p.model->rig();
    const Anim3DLimb limb = limb_of(rig, foot);
    REQUIRE(limb.valid());
    CHECK(limb.end == foot);
    const std::string before = p.text();
    const Pose pose = p.model->pose_at(0.0);
    const Vec3 start = bone_head(rig, pose, foot);
    const Vec3 target = start + Vec3{0.0f, 0.12f, 0.08f};
    const Vec3 pole = default_pole(rig, pose, limb);
    const Json solver = two_bone_solver(rig, limb, target, pole);
    const Anim3DEdit e = p.model->ik_key(0.0, solver);
    REQUIRE_MESSAGE(e.ok, e.error);
    const Pose after = p.model->pose_at(0.0);
    CHECK(length(bone_head(rig, after, foot) - target) < 0.03f);
    p.undo(e);
    CHECK(p.text() == before);
}

TEST_CASE("the live IK preview solves without writing anything") {
    Anim3DProject p;
    p.open();
    const int foot = p.model->node_of("foot_r");
    const Anim3DRigModel& rig = *p.model->rig();
    const Anim3DLimb limb = limb_of(rig, foot);
    REQUIRE(limb.valid());
    const std::string before = p.text();
    Pose pose = p.model->pose_at(0.0);
    const Vec3 target = bone_head(rig, pose, foot) + Vec3{0.0f, 0.1f, 0.1f};
    const auto res =
        ik3d_solve_once(rig.rig, pose, two_bone_solver(rig, limb, target, default_pole(rig, pose, limb)), 0.0f);
    REQUIRE(res.ok());
    CHECK(length(bone_head(rig, pose, foot) - target) < 0.03f);
    CHECK(p.text() == before);
}

TEST_CASE("mirror pose keys the other side by canonical names and one undo takes it back") {
    Anim3DProject p;
    p.open();
    REQUIRE(p.model->set_key("arm_upper_l", 0, 0.0, {0, 0, 40, 0}).ok);
    const std::string before = p.text();
    const Anim3DEdit e = p.model->mirror(0.0, 0.0, "left");
    REQUIRE_MESSAGE(e.ok, e.error);
    CHECK(p.model->key_at(Key3D{"arm_upper_r", 0, 0}));
    p.undo(e);
    CHECK(p.text() == before);
}

TEST_CASE("events: add, move, rename and remove are commands with an undo each") {
    Anim3DProject p;
    p.open();
    const std::string before = p.text();
    const std::size_t n = p.model->clip()->events.size();
    const Anim3DEdit added = p.model->add_event(0.2, "step");
    REQUIRE_MESSAGE(added.ok, added.error);
    REQUIRE(p.model->clip()->events.size() == n + 1);
    int index = -1;
    for (std::size_t i = 0; i < p.model->clip()->events.size(); ++i)
        if (p.model->clip()->events[i].name == "step") index = int(i);
    REQUIRE(index >= 0);
    const Anim3DEdit renamed = p.model->set_event(index, Json::object({{"name", "thud"}}));
    REQUIRE_MESSAGE(renamed.ok, renamed.error);
    CHECK(p.model->clip()->events[std::size_t(index)].name == "thud");
    const Anim3DEdit moved = p.model->set_event(index, Json::object({{"t", 0.3}}));
    REQUIRE_MESSAGE(moved.ok, moved.error);
    CHECK(std::fabs(p.model->clip()->events[std::size_t(index)].t - 0.3f) < 1e-4f);
    const Anim3DEdit removed = p.model->remove_event(index);
    REQUIRE_MESSAGE(removed.ok, removed.error);
    CHECK(p.model->clip()->events.size() == n);
    p.undo(removed);
    p.undo(moved);
    p.undo(renamed);
    p.undo(added);
    CHECK(p.text() == before);
    CHECK_FALSE(p.model->remove_event(99).ok);
}

TEST_CASE("clip settings and the file changing on disk") {
    Anim3DProject p;
    p.open();
    const Anim3DEdit e = p.model->set_clip(Json::object({{"duration", 2.0}, {"loop", false}}));
    REQUIRE_MESSAGE(e.ok, e.error);
    CHECK(std::fabs(p.model->clip()->duration - 2.0f) < 1e-4f);
    CHECK_FALSE(p.model->clip()->loop);
    CHECK_FALSE(p.model->poll());  // nothing changed behind its back
    const std::uint64_t rev = p.model->revision();
    p.ok("anim3d.set_clip", {{"path", kClip}, {"loop", true}});  // another tool wrote the file
    stdfs::last_write_time(p.dir / kClip, stdfs::last_write_time(p.dir / kClip) + std::chrono::seconds(5));
    CHECK(p.model->poll());
    CHECK(p.model->revision() > rev);
    CHECK(p.model->clip()->loop);
}

TEST_CASE("generate and retarget write new clips and report the undo that deletes them") {
    Anim3DProject p;
    p.open();
    const Anim3DEdit g = p.model->generate("idle", Json::object(), "anim/hero_idle.anim.json");
    REQUIRE_MESSAGE(g.ok, g.error);
    CHECK(stdfs::exists(p.dir / "anim/hero_idle.anim.json"));
    const Anim3DEdit again = p.model->generate("idle", Json::object(), "anim/hero_idle.anim.json");
    CHECK_FALSE(again.ok);  // the file exists
    const Anim3DEdit replaced = p.model->generate("idle", Json::object(), "anim/hero_idle.anim.json", true);
    CHECK(replaced.ok);
    const std::string first = p.text("anim/hero_idle.anim.json");
    p.ok(replaced.undo["command"].get<std::string>(),
         replaced.undo["args"]);  // the replace brings the first document back
    CHECK(p.text("anim/hero_idle.anim.json") == first);
    p.ok(g.undo["command"].get<std::string>(), g.undo["args"]);  // the generation itself: the file goes
    CHECK_FALSE(stdfs::exists(p.dir / "anim/hero_idle.anim.json"));
}

TEST_CASE("the ring maths: angles accumulate the short way, the ring point is on the ring and a click on it measures "
          "the same angle") {
    CHECK(std::fabs(angle_delta(3.0, -3.0) - (2.0 * 3.14159265358979323846 - 6.0)) < 1e-9);
    CHECK(std::fabs(angle_delta(-3.0, 3.0) + (2.0 * 3.14159265358979323846 - 6.0)) < 1e-9);
    CHECK(std::fabs(angle_delta(0.1, 0.4) - 0.3) < 1e-9);

    ModelViewOptions o;
    o.width = 400;
    o.height = 300;
    o.yawDeg = -25;
    o.pitchDeg = 12;
    const ModelViewCamera cam = model_view_camera(o, Vec3{0, 1, 0}, 1.2);
    const Vec3 center{0.1f, 1.0f, 0.0f}, axis{0, 0, 1};
    for (double angle : {-2.0, -0.5, 0.0, 0.7, 2.5}) {
        const Vec3 pt = ring_point(center, axis, 0.3, angle);
        CHECK(std::fabs(length(pt - center) - 0.3f) < 1e-5f);
        CHECK(std::fabs(dot(pt - center, axis)) < 1e-5f);
        double sx = 0, sy = 0, depth = 0;
        REQUIRE(cam.project(pt, sx, sy, depth));
        double measured = 0;
        REQUIRE(ring_angle(cam, sx, sy, center, axis, measured));
        CHECK(std::fabs(angle_delta(measured, angle)) < 1e-3);
    }
    // a plane hit lands on the plane, and a line parameter is the distance along the line
    double sx = 0, sy = 0, depth = 0;
    REQUIRE(cam.project(Vec3{0.3f, 1.2f, 0.1f}, sx, sy, depth));
    Vec3 hit;
    REQUIRE(plane_hit(cam, sx, sy, Vec3{0, 0, 0.1f}, Vec3{0, 0, 1}, hit));
    CHECK(std::fabs(hit.z - 0.1f) < 1e-4f);
    CHECK(std::fabs(hit.x - 0.3f) < 1e-3f);
    double s = 0;
    REQUIRE(cam.project(Vec3{0.5f, 1.0f, 0.0f}, sx, sy, depth));
    REQUIRE(line_param(cam, sx, sy, Vec3{0, 1, 0}, Vec3{1, 0, 0}, s));
    CHECK(std::fabs(s - 0.5) < 1e-3);
    CHECK(std::fabs(segment_distance(5, 5, 0, 0, 10, 0) - 5.0) < 1e-9);
    CHECK(std::fabs(segment_distance(-3, 4, 0, 0, 10, 0) - 5.0) < 1e-9);
}

TEST_CASE("limbs: a hand or a foot has a root, a mid and an end; a spine bone does not; the head aims") {
    Anim3DProject p;
    p.open();
    const Anim3DRigModel& rig = *p.model->rig();
    const Anim3DLimb leg = limb_of(rig, p.model->node_of("foot_l"));
    REQUIRE(leg.valid());
    CHECK(p.model->bone_name(leg.mid) == "shin_l");
    CHECK(p.model->bone_name(leg.root) == "thigh_l");
    CHECK_FALSE(limb_of(rig, p.model->node_of("pelvis")).valid());
    CHECK(aims_like_a_head(rig, p.model->node_of("head")));
    CHECK_FALSE(aims_like_a_head(rig, p.model->node_of("foot_l")));
    const Pose pose = p.model->pose_at(0.0);
    const Vec3 pole = default_pole(rig, pose, leg);
    const Json s = two_bone_solver(rig, leg, bone_head(rig, pose, leg.end), pole);
    CHECK(s.is_object());
    const Json look = look_at_solver(rig, p.model->node_of("head"), Vec3{0, 1.7f, 2.0f});
    CHECK(look.is_object());
}
