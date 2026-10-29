// anim.* clip commands (create, edit, undo, list, pose, check, filmstrip) and bones.create / skin.* (M42.3).
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <set>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/project.h"
#include "fa/scene/anim_clip.h"
#include "fa/scene/components.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Anim Commands Test",
  "id": "com.example.animcommands",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "name": "Camera", "components": { "Camera": { "clearColor": "#202020" } } },
    { "id": "hero", "name": "hero", "components": {
        "Transform": { "position": [0, 0, 0] },
        "Animator": { "clips": { "walk": "anim/walk.anim.json" } } },
      "children": [
        { "id": "body", "name": "body", "components": { "Shape2D": { "size": [20, 40], "color": "#4080ff" } },
          "children": [
            { "id": "arm", "name": "arm", "components": { "Transform": { "position": [10, 10, 0] },
                                                          "Shape2D": { "size": [6, 24], "color": "#ffc040" } } } ] } ] },
    { "id": "leg", "name": "leg", "components": { "Transform": { "position": [100, 0, 0] },
        "Sprite": { "size": [20, 40], "pivot": [0.5, 1.0] } } }
  ]
})";

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name) {
        dir = fs::make_temp_dir("fa_animcmd_test_" + name);
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary) << kScene;
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

EngineConfig cfg(const TempProject& p) {
    EngineConfig c;
    c.projectDir = p.dir.generic_string();
    c.headless = true;
    c.hotReload = false;
    return c;
}

Json read_file_json(const TempProject& p, const std::string& rel) {
    std::ifstream in(p.dir / rel, std::ios::binary);
    std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    return Json::parse(text);
}

bool file_exists(const TempProject& p, const std::string& rel) { return stdfs::exists(p.dir / rel); }

constexpr const char* kWalk = "anim/walk.anim.json";

Json track(const char* path, const char* field) { return Json::object({{"path", path}, {"field", field}}); }

Json key(double t, double v) { return Json::object({{"t", t}, {"value", v}}); }

}  // namespace

TEST_CASE("anim.create_clip writes a valid file, refuses to replace it, and undoes by deleting it") {
    TempProject p("create");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto r = c.call("anim.create_clip", Json{{"path", kWalk}, {"duration", 0.8}, {"loop", true}, {"doc", "walk"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["duration"] == 0.8);
    CHECK(r.result["undo"]["command"] == "anim.restore");
    Json doc = read_file_json(p, kWalk);
    CHECK(doc["format"] == "factoria.anim/1");
    CHECK(doc["duration"] == 0.8);
    CHECK(doc["tracks"].is_array());

    auto again = c.call("anim.create_clip", Json{{"path", kWalk}, {"duration", 1.0}});
    CHECK_FALSE(again.ok);
    CHECK(again.error.dump().find("overwrite") != std::string::npos);

    auto bad_ext = c.call("anim.create_clip", Json{{"path", "anim/walk.json"}, {"duration", 1.0}});
    CHECK_FALSE(bad_ext.ok);
    auto neg = c.call("anim.create_clip", Json{{"path", "anim/x.anim.json"}, {"duration", -1}});
    CHECK_FALSE(neg.ok);
    CHECK_FALSE(file_exists(p, "anim/x.anim.json"));
    auto bad_track = c.call("anim.create_clip", Json{{"path", "anim/y.anim.json"}, {"duration", 1.0},
                                                     {"tracks", Json::array({Json::object({{"field", "nope"}, {"keys", Json::array({key(0, 1)})}})})}});
    CHECK_FALSE(bad_track.ok);
    CHECK_FALSE(file_exists(p, "anim/y.anim.json"));

    auto undo = c.call("anim.restore", r.result["undo"]["args"]);
    REQUIRE_MESSAGE(undo.ok, undo.error.dump());
    CHECK_FALSE(file_exists(p, kWalk));
    auto redo = c.call("anim.restore", undo.result["undo"]["args"]);
    REQUIRE_MESSAGE(redo.ok, redo.error.dump());
    CHECK(file_exists(p, kWalk));
    CHECK(read_file_json(p, kWalk)["duration"] == 0.8);
    auto over = c.call("anim.create_clip", Json{{"path", kWalk}, {"duration", 2.0}, {"overwrite", true}});
    CHECK(over.ok);
    CHECK(read_file_json(p, kWalk)["duration"] == 2.0);
}

TEST_CASE("anim.set_keys / remove_keys / move_keys / set_interp edit a track and undo") {
    TempProject p("keys");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    REQUIRE(c.call("anim.create_clip", Json{{"path", kWalk}, {"duration", 1.0}}).ok);
    auto s = c.call("anim.set_keys", Json{{"path", kWalk}, {"track", track("body/arm", "rotation.z")},
                                          {"keys", Json::array({key(0.5, 30), key(0, -30), key(1, -30)})}, {"entity", "hero"}});
    REQUIRE_MESSAGE(s.ok, s.error.dump());
    CHECK(s.result["added"] == 3);
    CHECK(s.result["track"] == 0);
    Json doc = read_file_json(p, kWalk);
    REQUIRE(doc["tracks"].size() == 1);
    CHECK(doc["tracks"][0]["keys"][0]["t"] == 0);  // sorted
    CHECK(doc["tracks"][0]["keys"][1]["t"] == 0.5);

    // Replace a key; a key past the duration is refused unless extendDuration.
    auto rep = c.call("anim.set_keys", Json{{"path", kWalk}, {"track", 0}, {"keys", Json::array({key(0.5, 45)})}});
    if (!rep.ok) rep = c.call("anim.set_keys", Json{{"path", kWalk}, {"track", track("body/arm", "rotation.z")}, {"keys", Json::array({key(0.5, 45)})}});
    REQUIRE_MESSAGE(rep.ok, rep.error.dump());
    CHECK(rep.result["replaced"] == 1);
    auto past = c.call("anim.set_keys", Json{{"path", kWalk}, {"track", track("body/arm", "rotation.z")}, {"keys", Json::array({key(2, 0)})}});
    CHECK_FALSE(past.ok);
    auto ext = c.call("anim.set_keys", Json{{"path", kWalk}, {"track", track("body/arm", "rotation.z")}, {"keys", Json::array({key(2, 0)})}, {"extendDuration", true}});
    REQUIRE_MESSAGE(ext.ok, ext.error.dump());
    CHECK(read_file_json(p, kWalk)["duration"] == 2.0);

    // A part that does not exist on the entity: teaching error.
    auto unk = c.call("anim.set_keys", Json{{"path", kWalk}, {"track", track("body/arn", "rotation.z")}, {"keys", Json::array({key(0, 0)})}, {"entity", "hero"}});
    CHECK_FALSE(unk.ok);
    CHECK(unk.error.dump().find("arm") != std::string::npos);  // did you mean

    // set_interp
    auto in = c.call("anim.set_interp", Json{{"path", kWalk}, {"keys", Json::array({Json::object({{"track", 0}, {"t", 0.5}})})}, {"interp", "quadOut"}});
    REQUIRE_MESSAGE(in.ok, in.error.dump());
    CHECK(read_file_json(p, kWalk)["tracks"][0]["keys"][1]["interp"] == "quadOut");
    auto badin = c.call("anim.set_interp", Json{{"path", kWalk}, {"keys", Json::array({Json::object({{"track", 0}, {"t", 0.5}})})}, {"interp", "quadOutt"}});
    CHECK_FALSE(badin.ok);

    // move_keys: scale about the first key; refused when landing on another key.
    auto mv = c.call("anim.move_keys", Json{{"path", kWalk}, {"keys", Json::array({Json::object({{"track", 0}, {"t", 0.5}})})}, {"offset", 0.1}});
    REQUIRE_MESSAGE(mv.ok, mv.error.dump());
    CHECK(read_file_json(p, kWalk)["tracks"][0]["keys"][1]["t"] == doctest::Approx(0.6));
    auto clash = c.call("anim.move_keys", Json{{"path", kWalk}, {"keys", Json::array({Json::object({{"track", 0}, {"t", 0.6}})})}, {"offset", 0.4}});
    CHECK_FALSE(clash.ok);
    auto neg = c.call("anim.move_keys", Json{{"path", kWalk}, {"keys", Json::array({Json::object({{"track", 0}, {"t", 0.6}})})}, {"offset", -5}});
    CHECK_FALSE(neg.ok);

    // remove_keys, then undo brings the key back.
    auto rm = c.call("anim.remove_keys", Json{{"path", kWalk}, {"track", 0}, {"times", Json::array({0.6})}});
    REQUIRE_MESSAGE(rm.ok, rm.error.dump());
    CHECK(rm.result["removed"] == 1);
    CHECK(read_file_json(p, kWalk)["tracks"][0]["keys"].size() == 3);
    auto missing = c.call("anim.remove_keys", Json{{"path", kWalk}, {"track", 0}, {"times", Json::array({0.33})}});
    CHECK_FALSE(missing.ok);
    CHECK(c.call("anim.restore", rm.result["undo"]["args"]).ok);
    CHECK(read_file_json(p, kWalk)["tracks"][0]["keys"].size() == 4);
    auto all = c.call("anim.remove_keys", Json{{"path", kWalk}, {"track", 0}, {"all", true}});
    REQUIRE(all.ok);
    CHECK(all.result["trackRemoved"] == true);
    CHECK(read_file_json(p, kWalk)["tracks"].empty());
    auto both = c.call("anim.remove_keys", Json{{"path", kWalk}, {"track", 0}});
    CHECK_FALSE(both.ok);
}

TEST_CASE("anim tracks, events and clip settings") {
    TempProject p("events");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    REQUIRE(c.call("anim.create_clip", Json{{"path", kWalk}, {"duration", 1.0}}).ok);

    auto at = c.call("anim.add_track", Json{{"path", kWalk}, {"track", track("body", "rotation.z")}, {"entity", "hero"}});
    REQUIRE_MESSAGE(at.ok, at.error.dump());
    CHECK(read_file_json(p, kWalk)["tracks"].size() == 1);
    auto rt = c.call("anim.remove_track", Json{{"path", kWalk}, {"track", 0}});
    REQUIRE_MESSAGE(rt.ok, rt.error.dump());
    CHECK(read_file_json(p, kWalk)["tracks"].empty());
    CHECK(c.call("anim.restore", rt.result["undo"]["args"]).ok);
    CHECK(read_file_json(p, kWalk)["tracks"].size() == 1);
    CHECK_FALSE(c.call("anim.remove_track", Json{{"path", kWalk}, {"track", 5}}).ok);

    auto ev = c.call("anim.add_event", Json{{"path", kWalk}, {"t", 0.5}, {"name", "footstep"}, {"data", Json{{"foot", "left"}}}});
    REQUIRE_MESSAGE(ev.ok, ev.error.dump());
    CHECK(ev.result["event"] == 0);
    REQUIRE(c.call("anim.add_event", Json{{"path", kWalk}, {"t", 0.1}, {"name", "start"}}).ok);
    CHECK(read_file_json(p, kWalk)["events"][0]["name"] == "start");  // sorted
    CHECK_FALSE(c.call("anim.add_event", Json{{"path", kWalk}, {"t", 3.0}, {"name", "late"}}).ok);
    CHECK_FALSE(c.call("anim.add_event", Json{{"path", kWalk}, {"t", 0.2}, {"name", ""}}).ok);

    auto mv = c.call("anim.move_event", Json{{"path", kWalk}, {"event", Json{{"t", 0.5}, {"name", "footstep"}}}, {"to", 0.05}});
    REQUIRE_MESSAGE(mv.ok, mv.error.dump());
    CHECK(read_file_json(p, kWalk)["events"][0]["name"] == "footstep");
    auto se = c.call("anim.set_event", Json{{"path", kWalk}, {"event", 0}, {"name", "step"}});
    REQUIRE_MESSAGE(se.ok, se.error.dump());
    CHECK(read_file_json(p, kWalk)["events"][0]["name"] == "step");
    auto re = c.call("anim.remove_event", Json{{"path", kWalk}, {"event", 0}});
    REQUIRE_MESSAGE(re.ok, re.error.dump());
    CHECK(read_file_json(p, kWalk)["events"].size() == 1);
    CHECK_FALSE(c.call("anim.remove_event", Json{{"path", kWalk}, {"event", 9}}).ok);

    auto sc = c.call("anim.set_clip", Json{{"path", kWalk}, {"duration", 2.0}, {"loop", false}});
    REQUIRE_MESSAGE(sc.ok, sc.error.dump());
    Json doc = read_file_json(p, kWalk);
    CHECK(doc["duration"] == 2.0);
    CHECK(doc["loop"] == false);
    CHECK_FALSE(c.call("anim.set_clip", Json{{"path", kWalk}}).ok);
    // Shorter than the last event/key is refused.
    REQUIRE(c.call("anim.set_keys", Json{{"path", kWalk}, {"track", track("body", "rotation.z")}, {"keys", Json::array({key(1.5, 10)})}}).ok);
    CHECK_FALSE(c.call("anim.set_clip", Json{{"path", kWalk}, {"duration", 1.0}}).ok);
    CHECK(c.call("anim.restore", sc.result["undo"]["args"]).ok);  // undo is whole-document
}

TEST_CASE("anim.list, anim.pose and anim.check") {
    TempProject p("check");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    // A clip with a swinging arm that does not return (loop_jump), a constant track (no_change), and a part that is not there.
    REQUIRE(c.call("anim.create_clip", Json{{"path", kWalk}, {"duration", 1.0}, {"loop", true}}).ok);
    REQUIRE(c.call("anim.set_keys", Json{{"path", kWalk}, {"track", track("body/arm", "rotation.z")}, {"keys", Json::array({key(0, 0), key(1, 90)})}}).ok);
    REQUIRE(c.call("anim.set_keys", Json{{"path", kWalk}, {"track", track("body", "position.y")}, {"keys", Json::array({key(0, 5), key(1, 5)})}}).ok);

    auto list = c.call("anim.list", Json{{"entity", "hero"}});
    REQUIRE_MESSAGE(list.ok, list.error.dump());
    CHECK(list.result.dump().find("walk") != std::string::npos);
    auto by_path = c.call("anim.list", Json{{"path", kWalk}, {"full", true}});
    REQUIRE_MESSAGE(by_path.ok, by_path.error.dump());
    CHECK(by_path.result.dump().find("source") != std::string::npos);
    CHECK(c.call("anim.list", Json::object()).ok);
    CHECK_FALSE(c.call("anim.list", Json{{"path", "anim/none.anim.json"}}).ok);

    auto pose = c.call("anim.pose", Json{{"entity", "hero"}, {"clip", "walk"}, {"t", 0.5}});
    REQUIRE_MESSAGE(pose.ok, pose.error.dump());
    const Entity arm = e.world().find("arm");
    REQUIRE(arm != kNullEntity);
    CHECK(e.world().get<Transform>(arm)->rotation.z == doctest::Approx(45).epsilon(0.02));
    CHECK_FALSE(c.call("anim.pose", Json{{"entity", "hero"}, {"clip", "wak"}}).ok);
    CHECK_FALSE(c.call("anim.pose", Json{{"entity", "nobody"}, {"clip", "walk"}}).ok);

    // A track that names a part the character does not have: anim.list shows it as a problem, anim.pose refuses, anim.check finds it.
    REQUIRE(c.call("anim.set_keys", Json{{"path", kWalk}, {"track", track("body/hand", "rotation.z")}, {"keys", Json::array({key(0, 0), key(1, 10)})}}).ok);
    CHECK(c.call("anim.list", Json{{"entity", "hero"}}).result.dump().find("body/hand") != std::string::npos);
    CHECK_FALSE(c.call("anim.pose", Json{{"entity", "hero"}, {"clip", "walk"}, {"t", 0.5}}).ok);

    auto chk = c.call("anim.check", Json{{"entity", "hero"}});
    REQUIRE_MESSAGE(chk.ok, chk.error.dump());
    std::set<std::string> kinds;
    for (const Json& f : chk.result["findings"]) kinds.insert(f["kind"].get<std::string>());
    CHECK(kinds.count("loop_jump"));
    CHECK(kinds.count("no_change"));
    CHECK(kinds.count("unknown_part"));
    CHECK(chk.result["ok"] == false);
    for (const Json& f : chk.result["findings"]) CHECK_FALSE(f["hint"].get<std::string>().empty());
    // The check puts the entity back as it was.
    auto alone = c.call("anim.check", Json{{"path", kWalk}});
    REQUIRE_MESSAGE(alone.ok, alone.error.dump());
    CHECK(alone.result["findings"].size() >= 2);
    CHECK_FALSE(c.call("anim.check", Json::object()).ok);

    // A clean clip passes.
    REQUIRE(c.call("anim.create_clip", Json{{"path", "anim/ok.anim.json"}, {"duration", 1.0}}).ok);
    REQUIRE(c.call("anim.set_keys", Json{{"path", "anim/ok.anim.json"}, {"track", track("body/arm", "rotation.z")}, {"keys", Json::array({key(0, -20), key(0.5, 20), key(1, -20)})}}).ok);
    auto ok = c.call("anim.check", Json{{"path", "anim/ok.anim.json"}});
    REQUIRE_MESSAGE(ok.ok, ok.error.dump());
    CHECK(ok.result["ok"] == true);

    // A broken file is an invalid_clip finding, not a command failure.
    stdfs::create_directories(p.dir / "anim");
    std::ofstream(p.dir / "anim/broken.anim.json", std::ios::binary) << R"({"format":"factoria.anim/1","duration":1,"tracks":[{"field":"nope","keys":[]}]})";
    auto broken = c.call("anim.check", Json{{"path", "anim/broken.anim.json"}});
    REQUIRE_MESSAGE(broken.ok, broken.error.dump());
    CHECK(broken.result["findings"][0]["kind"] == "invalid_clip");
}

TEST_CASE("anim.check: a part that leaves the view, and an IK target out of reach") {
    TempProject p("view");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    REQUIRE(c.call("anim.create_clip", Json{{"path", kWalk}, {"duration", 1.0}}).ok);
    // The body walks 1000 px to the right: out of the 320 px view.
    REQUIRE(c.call("anim.set_keys", Json{{"path", kWalk}, {"track", track("body", "position.x")}, {"keys", Json::array({key(0, 0), key(1, 1000)})}}).ok);
    auto chk = c.call("anim.check", Json{{"entity", "hero"}});
    REQUIRE_MESSAGE(chk.ok, chk.error.dump());
    bool leaves = false;
    for (const Json& f : chk.result["findings"]) leaves |= f["kind"] == "leaves_view";
    CHECK(leaves);

    // IK: a two-bone chain of 2 x 20 px with a target that the clip drags 100 px away.
    REQUIRE(c.call("bones.create", Json{{"parent", "leg"}, {"points", Json::array({Json::array({0, 0}), Json::array({0, -20}), Json::array({0, -40})})}, {"names", Json::array({"thigh", "shin"})}}).ok);
    REQUIRE_MESSAGE(c.call("scene.spawn", Json{{"name", "foot_target"}, {"id", "foot_target"}, {"parent", "leg"}}).ok, "spawn");
    REQUIRE_MESSAGE(c.call("scene.set_component", Json{{"id", "shin"}, {"component", "IK2D"}, {"fields", Json{{"target", "foot_target"}}}}).ok, "ik");
    REQUIRE_MESSAGE(c.call("scene.set_component", Json{{"id", "leg"}, {"component", "Animator"},
                                                       {"fields", Json{{"clips", Json{{"reach", "anim/reach.anim.json"}}}}}}).ok, "animator");
    REQUIRE(c.call("anim.create_clip", Json{{"path", "anim/reach.anim.json"}, {"duration", 1.0}}).ok);
    REQUIRE(c.call("anim.set_keys", Json{{"path", "anim/reach.anim.json"}, {"track", track("foot_target", "position.y")},
                                         {"keys", Json::array({key(0, -30), key(1, -300)})}}).ok);
    auto ik = c.call("anim.check", Json{{"entity", "leg"}});
    REQUIRE_MESSAGE(ik.ok, ik.error.dump());
    bool unreachable = false;
    for (const Json& f : ik.result["findings"]) unreachable |= f["kind"] == "ik_out_of_reach";
    CHECK_MESSAGE(unreachable, ik.result.dump());
}

TEST_CASE("bones.create, skin.bind, skin.auto_weights and skin.set_weights") {
    TempProject p("skin");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto bones = c.call("bones.create", Json{{"parent", "leg"}, {"points", Json::array({Json::array({0, 0}), Json::array({0, -20}), Json::array({0, -40})})},
                                              {"names", Json::array({"thigh", "shin"})}});
    REQUIRE_MESSAGE(bones.ok, bones.error.dump());
    REQUIRE(bones.result["bones"].size() == 2);
    CHECK(bones.result["bones"][0]["length"].get<double>() == doctest::Approx(20));
    const Entity thigh = e.world().find("thigh"), shin = e.world().find("shin");
    REQUIRE(thigh != kNullEntity);
    REQUIRE(shin != kNullEntity);
    CHECK(e.world().has<Bone2D>(thigh));
    CHECK(e.world().parent(shin) == thigh);
    CHECK(e.world().get<Transform>(thigh)->rotation.z == doctest::Approx(-90).epsilon(0.05));  // faces down

    CHECK_FALSE(c.call("bones.create", Json{{"parent", "leg"}, {"points", Json::array({Json::array({0, 0})})}}).ok);
    CHECK_FALSE(c.call("bones.create", Json{{"parent", "leg"}, {"points", Json::array({Json::array({0, 0}), Json::array({0, 5})})}, {"names", Json::array({"thigh"})}}).ok);  // duplicate name
    CHECK_FALSE(c.call("bones.create", Json{{"parent", "legg"}, {"points", Json::array({Json::array({0, 0}), Json::array({0, 5})})}}).ok);

    CHECK_FALSE(c.call("skin.bind", Json{{"entity", "hero"}, {"root", "thigh"}}).ok);  // no Sprite
    CHECK_FALSE(c.call("skin.bind", Json{{"entity", "leg"}}).ok);
    auto bind = c.call("skin.bind", Json{{"entity", "leg"}, {"root", "thigh"}, {"mesh", Json::array({2, 4})}});
    REQUIRE_MESSAGE(bind.ok, bind.error.dump());
    CHECK(bind.result["bones"].size() == 2);
    const Entity leg = e.world().find("leg");
    REQUIRE(e.world().has<SpriteSkin>(leg));
    CHECK(e.world().get<Sprite>(leg)->meshColumns == 2);
    CHECK(e.world().get<Sprite>(leg)->meshRows == 4);

    CHECK_FALSE(c.call("skin.auto_weights", Json{{"entity", "hero"}}).ok);
    auto aw = c.call("skin.auto_weights", Json{{"entity", "leg"}});
    REQUIRE_MESSAGE(aw.ok, aw.error.dump());
    CHECK(aw.result["vertices"] == 15);  // (2+1) * (4+1)
    CHECK(e.world().get<SpriteSkin>(leg)->weights.is_array());
    CHECK(e.world().get<SpriteSkin>(leg)->weights.size() == 15);

    auto set = c.call("skin.set_weights", Json{{"entity", "leg"}, {"vertices", Json::array({0, 1})}, {"bone", "shin"}, {"weight", 1.0}});
    REQUIRE_MESSAGE(set.ok, set.error.dump());
    const Json w0 = e.world().get<SpriteSkin>(leg)->weights[0];
    REQUIRE(w0.size() == 2);
    CHECK(w0[0] == 1);  // bone index of shin
    CHECK(w0[1].get<double>() == doctest::Approx(1.0));
    auto add = c.call("skin.set_weights", Json{{"entity", "leg"}, {"vertices", "all"}, {"bone", 0}, {"weight", 0.25}, {"mode", "add"}});
    REQUIRE_MESSAGE(add.ok, add.error.dump());
    for (const Json& v : e.world().get<SpriteSkin>(leg)->weights) {
        double sum = 0;
        for (std::size_t i = 1; i < v.size(); i += 2) sum += v[i].get<double>();
        CHECK(sum == doctest::Approx(1.0).epsilon(0.01));
        CHECK(v.size() <= 8);
    }
    auto smooth = c.call("skin.set_weights", Json{{"entity", "leg"}, {"vertices", Json{{"rect", Json::array({-10, -40, 10, 0})}}}, {"mode", "smooth"}});
    CHECK_MESSAGE(smooth.ok, smooth.error.dump());
    CHECK_FALSE(c.call("skin.set_weights", Json{{"entity", "leg"}, {"vertices", Json::array({999})}, {"bone", 0}, {"weight", 1}}).ok);
    CHECK_FALSE(c.call("skin.set_weights", Json{{"entity", "leg"}, {"vertices", "all"}, {"bone", "thig"}, {"weight", 1}}).ok);
    CHECK_FALSE(c.call("skin.set_weights", Json{{"entity", "leg"}, {"vertices", "all"}, {"bone", 0}, {"weight", 1}, {"mode", "paint"}}).ok);
}

TEST_CASE("anim.filmstrip draws the poses of a clip into one picture") {
    TempProject p("film");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    REQUIRE(c.call("anim.create_clip", Json{{"path", kWalk}, {"duration", 1.0}}).ok);
    REQUIRE(c.call("anim.set_keys", Json{{"path", kWalk}, {"track", track("body/arm", "rotation.z")}, {"keys", Json::array({key(0, -40), key(0.5, 40), key(1, -40)})}}).ok);
    const std::string png = (p.dir / "film.png").generic_string();
    auto r = c.call("anim.filmstrip", Json{{"entity", "hero"}, {"clip", "walk"}, {"frames", 4}, {"onionSkin", true}, {"path", png}});
    if (!r.ok && r.error.dump().find("unavailable") != std::string::npos) return;  // no graphics on this machine
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["frames"].size() == 4);
    CHECK(stdfs::exists(png));
    CHECK(r.result["width"].get<int>() > 0);
    CHECK_FALSE(c.call("anim.filmstrip", Json{{"entity", "hero"}, {"clip", "walk"}, {"frames", 65}}).ok);
    // The entity is put back: the arm is where the scene had it.
    CHECK(e.world().get<Transform>(e.world().find("arm"))->rotation.z == doctest::Approx(0.0f));
}
