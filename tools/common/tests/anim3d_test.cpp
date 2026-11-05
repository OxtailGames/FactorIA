// anim3d.* and ik3d.*: 3D bone clips as project files (docs/ANIMATION.md, "3D bone clips"). The clip format, the generators, the retargeting and the
// solvers are tested in fa_scene (engine/scene/tests/test_anim3d.cpp); here: the commands, the files they write and read back, the filmstrip
// picture, and the teaching errors.
#include <doctest.h>

#include <cmath>
#include <format>
#include <set>

#include "asset_test_helpers.h"
#include "fa/scene/anim3d.h"

using namespace fa;
using namespace fa::testing;

namespace {

// A person of height proportional to `k` (legs, arms and trunk all scale), the same layout as rig_test.cpp's.
std::string person(double k) {
    auto n = [&](double v) { return std::format("{:.4f}", v * k); };
    return "{\"format\":\"factoria.model/1\",\"nodes\":[" +
           std::string("{\"op\":\"box\",\"size\":[") + n(0.36) + "," + n(0.2) + "," + n(0.2) + "],\"position\":[0," + n(0.95) + ",0],\"part\":\"pelvis\"}," +
           "{\"op\":\"box\",\"size\":[" + n(0.4) + "," + n(0.5) + "," + n(0.22) + "],\"position\":[0," + n(1.3) + ",0],\"part\":\"torso\"}," +
           "{\"op\":\"box\",\"size\":[" + n(0.1) + "," + n(0.1) + "," + n(0.1) + "],\"position\":[0," + n(1.6) + ",0],\"part\":\"neck\"}," +
           "{\"op\":\"box\",\"size\":[" + n(0.22) + "," + n(0.25) + "," + n(0.22) + "],\"position\":[0," + n(1.77) + "," + n(0.02) + "],\"part\":\"head\"}," +
           "{\"op\":\"box\",\"size\":[" + n(0.7) + "," + n(0.1) + "," + n(0.1) + "],\"position\":[" + n(0.55) + "," + n(1.5) + ",0],\"part\":\"arm_l\"}," +
           "{\"op\":\"box\",\"size\":[" + n(0.7) + "," + n(0.1) + "," + n(0.1) + "],\"position\":[" + n(-0.55) + "," + n(1.5) + ",0],\"part\":\"arm_r\"}," +
           "{\"op\":\"box\",\"size\":[" + n(0.14) + "," + n(0.9) + "," + n(0.14) + "],\"position\":[" + n(0.11) + "," + n(0.45) + ",0],\"part\":\"leg_l\"}," +
           "{\"op\":\"box\",\"size\":[" + n(0.14) + "," + n(0.9) + "," + n(0.14) + "],\"position\":[" + n(-0.11) + "," + n(0.45) + ",0],\"part\":\"leg_r\"}]}";
}

const char* kHero = "assets/models/hero.rig.glb";
const char* kGiant = "assets/models/giant.rig.glb";

// A project with two baked humanoids of different size.
struct RigProject : AssetsProject {
    RigProject() {
        write_all(file("assets/models/hero.model.json"), person(1.0));
        write_all(file("assets/models/giant.model.json"), person(1.5));
        ok("rig.create", {{"path", "assets/models/hero.rig.json"}, {"model", "assets/models/hero.model.json"}, {"template", "humanoid"}});
        ok("rig.create", {{"path", "assets/models/giant.rig.json"}, {"model", "assets/models/giant.model.json"}, {"template", "humanoid"}});
    }
    Json clip(const std::string& rel) const { return parse_json(read_all(file(rel)), rel).value(); }
    std::string error_text(const std::string& name, const Json& args) const {
        const CommandResult r = call(name, args);
        REQUIRE_FALSE(r.ok);
        return r.error.dump();
    }
};

bool contains(const std::string& text, const char* part) { return text.find(part) != std::string::npos; }

}  // namespace

TEST_CASE("anim3d.generators lists every kind with parameters, and the commands refuse unknown arguments") {
    AssetsProject p;
    const Json r = p.ok("anim3d.generators", Json::object());
    std::set<std::string> kinds;
    for (const Json& g : r["generators"]) {
        kinds.insert(g["kind"].get<std::string>());
        CHECK_FALSE(g["doc"].get<std::string>().empty());
        CHECK(g["params"].size() >= 2);
    }
    CHECK(kinds == std::set<std::string>{"walk", "run", "trot", "gallop", "idle", "swing", "hit"});
    const CommandResult bad = p.call("anim3d.generators", {{"kind", "walk"}});
    REQUIRE_FALSE(bad.ok);
    for (const char* cmd : {"anim3d.create", "anim3d.info", "anim3d.set_keys", "anim3d.remove_track", "anim3d.generate", "anim3d.retarget", "anim3d.preview", "ik3d.check", "ik3d.solve", "anim3d.restore", "anim3d.move_keys", "anim3d.remove_keys", "anim3d.set_interp",
                                  "anim3d.set_clip", "anim3d.add_event", "anim3d.set_event", "anim3d.remove_event", "anim3d.mirror_pose", "ik3d.key"}) {
        REQUIRE(p.registry.has(cmd));
        CHECK_FALSE(p.registry.info(cmd)->description.empty());
        CHECK_FALSE(p.registry.info(cmd)->summary.empty());
    }
}

TEST_CASE("anim3d.generate writes a walk clip that anim3d.info reads back, the same call writes the same bytes, and errors teach") {
    RigProject p;
    const Json r = p.ok("anim3d.generate", {{"rig", kHero}, {"kind", "walk"}, {"out", "anim/hero_walk.anim.json"}});
    CHECK(r["path"] == "anim/hero_walk.anim.json");
    CHECK(r["kind"] == "walk");
    CHECK(r["groundSpeed"].get<double>() > 0.5);
    CHECK(r["tracks"].get<int>() > 10);
    CHECK(r["contactList"].size() >= 2);
    CHECK(r["generated"]["kind"] == "walk");
    CHECK(contains(r["nextSteps"][0].get<std::string>(), "Animator"));
    const std::string first = read_all(p.file("anim/hero_walk.anim.json"));

    const Json info = p.ok("anim3d.info", {{"path", "anim/hero_walk.anim.json"}, {"rig", kHero}});
    CHECK(info["rig"] == kHero);
    CHECK(info["template"] == "humanoid");
    CHECK(info["rigCheck"]["ok"] == true);
    CHECK(info["duration"] == r["duration"]);
    CHECK(info["trackList"].size() == r["tracks"].get<std::size_t>());

    // the same inputs, the same bytes; an existing file is not replaced without overwrite
    const std::string exists = p.error_text("anim3d.generate", {{"rig", kHero}, {"kind", "walk"}, {"out", "anim/hero_walk.anim.json"}});
    CHECK(contains(exists, "overwrite"));
    p.ok("anim3d.generate", {{"rig", kHero}, {"kind", "walk"}, {"out", "anim/hero_walk.anim.json"}, {"overwrite", true}});
    CHECK(read_all(p.file("anim/hero_walk.anim.json")) == first);

    // the recorded parameters reproduce it
    Json again = {{"rig", kHero}, {"kind", "walk"}, {"out", "anim/again.anim.json"}, {"params", r["generated"]["params"]}};
    p.ok("anim3d.generate", again);
    const Json a = p.clip("anim/hero_walk.anim.json"), b = p.clip("anim/again.anim.json");
    CHECK(a["duration"] == b["duration"]);
    CHECK(a["tracks"].size() == b["tracks"].size());

    // parameters change the clip; a typo teaches; a missing rig lists the baked ones
    const Json fast = p.ok("anim3d.generate", {{"rig", kHero}, {"kind", "run"}, {"params", {{"strideLength", 2.2}}}});
    CHECK(fast["path"] == "anim/hero_run.anim.json");
    CHECK(fast["groundSpeed"].get<double>() > r["groundSpeed"].get<double>());
    const std::string typo = p.error_text("anim3d.generate", {{"rig", kHero}, {"kind", "walk"}, {"params", {{"strideLenght", 1.0}}}, {"out", "anim/x.anim.json"}});
    CHECK(contains(typo, "strideLength"));
    CHECK_FALSE(p.exists("anim/x.anim.json"));
    const std::string kind = p.error_text("anim3d.generate", {{"rig", kHero}, {"kind", "wlak"}, {"out", "anim/x.anim.json"}});
    CHECK(contains(kind, "walk"));
    const std::string noRig = p.error_text("anim3d.generate", {{"rig", "assets/models/hero.rig.glb2"}, {"kind", "walk"}});
    CHECK(contains(noRig, "hero.rig.glb"));
    const std::string noTail = p.error_text("anim3d.generate", {{"rig", kHero}, {"kind", "gallop"}, {"out", "anim/x.anim.json"}});
    CHECK(contains(noTail, "quadruped"));
    CHECK_FALSE(p.exists("anim/x.anim.json"));
    // a rig document works as the rig too
    p.ok("anim3d.generate", {{"rig", "assets/models/hero.rig.json"}, {"kind", "idle"}});
    CHECK(p.exists("anim/hero_idle.anim.json"));
}

TEST_CASE("anim3d.create, set_keys and remove_track edit a clip file; a refused edit leaves the file untouched") {
    RigProject p;
    p.ok("anim3d.create", {{"path", "anim/wave.anim.json"}, {"duration", 1.0}, {"loop", false}, {"rig", kHero}});
    CHECK(p.clip("anim/wave.anim.json")["format"] == "factoria.anim3d/1");
    CHECK(p.clip("anim/wave.anim.json")["template"] == "humanoid");
    CHECK(contains(p.error_text("anim3d.create", {{"path", "anim/wave.anim.json"}}), "overwrite"));
    CHECK(contains(p.error_text("anim3d.create", {{"path", "anim/wave.json"}}), ".anim.json"));

    const Json r = p.ok("anim3d.set_keys", {{"path", "anim/wave.anim.json"}, {"bone", "arm_upper_l"}, {"rig", kHero},
                                            {"keys", Json::array({{{"t", 0.8}, {"value", {0, 0, 0}}}, {{"t", 0.0}, {"value", {0, 0, 0}}}, {{"t", 0.4}, {"value", {0, 0, 150}}, {"interp", "quadOut"}}})}});
    CHECK(r["added"] == 3);
    CHECK(r["keys"] == 3);
    Json doc = p.clip("anim/wave.anim.json");
    REQUIRE(doc["tracks"].size() == 1);
    CHECK(doc["tracks"][0]["bone"] == "arm_upper_l");
    CHECK(doc["tracks"][0]["keys"][1]["t"].get<double>() == doctest::Approx(0.4));  // sorted by time
    CHECK(doc["tracks"][0]["keys"][1]["interp"] == "quadOut");

    // a key at the time of an existing one replaces it; another channel makes another track
    const Json again = p.ok("anim3d.set_keys", {{"path", "anim/wave.anim.json"}, {"bone", "arm_upper_l"}, {"keys", Json::array({{{"t", 0.4}, {"value", {0, 0, 120}}}})}});
    CHECK(again["replaced"] == 1);
    CHECK(again["added"] == 0);
    CHECK(p.clip("anim/wave.anim.json")["tracks"][0]["keys"][1]["value"][2].get<double>() == doctest::Approx(120));
    p.ok("anim3d.set_keys", {{"path", "anim/wave.anim.json"}, {"bone", "root"}, {"channel", "translation"}, {"keys", Json::array({{{"t", 0.0}, {"value", {0, 0.1, 0}}}})}});
    CHECK(p.clip("anim/wave.anim.json")["tracks"].size() == 2);

    // refused edits: a ghost bone (with the rig), a key past the duration, a bad value; nothing is written
    const std::string before = read_all(p.file("anim/wave.anim.json"));
    const std::string ghost = p.error_text("anim3d.set_keys", {{"path", "anim/wave.anim.json"}, {"bone", "arm_uper_l"}, {"rig", kHero}, {"keys", Json::array({{{"t", 0.0}, {"value", {0, 0, 0}}}})}});
    CHECK(contains(ghost, "arm_upper_l"));
    const std::string late = p.error_text("anim3d.set_keys", {{"path", "anim/wave.anim.json"}, {"bone", "head"}, {"keys", Json::array({{{"t", 5.0}, {"value", {0, 0, 0}}}})}});
    CHECK(contains(late, "/tracks/"));
    const std::string value = p.error_text("anim3d.set_keys", {{"path", "anim/wave.anim.json"}, {"bone", "head"}, {"keys", Json::array({{{"t", 0.1}, {"value", {0, 0}}}})}});
    CHECK(contains(value, "value"));
    CHECK(read_all(p.file("anim/wave.anim.json")) == before);
    // the duration can grow in the same call
    p.ok("anim3d.set_keys", {{"path", "anim/wave.anim.json"}, {"bone", "head"}, {"duration", 6.0}, {"keys", Json::array({{{"t", 5.0}, {"value", {0, 10, 0}}}})}});
    CHECK(p.clip("anim/wave.anim.json")["duration"].get<double>() == doctest::Approx(6.0));

    // remove_track
    const Json removed = p.ok("anim3d.remove_track", {{"path", "anim/wave.anim.json"}, {"bone", "root"}});
    CHECK(removed["removed"].size() == 1);
    CHECK(contains(p.error_text("anim3d.remove_track", {{"path", "anim/wave.anim.json"}, {"bone", "haed"}}), "head"));
    CHECK(p.clip("anim/wave.anim.json")["tracks"].size() == 2);

    // a 2D clip is not a 3D one, and the listing finds only 3D clips
    write_all(p.file("anim/flat.anim.json"), R"({"format":"factoria.anim/1","duration":1,"tracks":[]})");
    CHECK(contains(p.error_text("anim3d.info", {{"path", "anim/flat.anim.json"}}), "2D"));
    const Json list = p.ok("anim3d.info", Json::object());
    CHECK(list["clips"] == Json::array({"anim/wave.anim.json"}));
    CHECK(contains(p.error_text("anim3d.info", {{"path", "anim/wav.anim.json"}}), "wave.anim.json"));
}

TEST_CASE("anim3d.retarget carries a walk to a bigger rig, scales the root motion and keeps the contacts") {
    RigProject p;
    const Json walk = p.ok("anim3d.generate", {{"rig", kHero}, {"kind", "walk"}, {"out", "anim/hero_walk.anim.json"}});
    const Json r = p.ok("anim3d.retarget", {{"path", "anim/hero_walk.anim.json"}, {"to", kGiant}, {"out", "anim/giant_walk.anim.json"}});
    CHECK(r["from"] == kHero);  // the clip names its rig
    CHECK(r["to"] == kGiant);
    CHECK(r["scale"].get<double>() == doctest::Approx(1.5).epsilon(0.05));
    CHECK(r["groundSpeed"].get<double>() == doctest::Approx(walk["groundSpeed"].get<double>() * r["scale"].get<double>()).epsilon(0.02));
    CHECK(r["dropped"].size() == 0);
    CHECK(r["planted"].size() >= 2);
    CHECK(r["contacts"] == walk["contacts"]);
    const Json out = p.clip("anim/giant_walk.anim.json");
    CHECK(out["rig"] == kGiant);
    CHECK(out["template"] == "humanoid");
    // the clip plays on the giant: no track names a bone it lacks
    CHECK(p.ok("anim3d.info", {{"path", "anim/giant_walk.anim.json"}, {"rig", kGiant}})["rigCheck"]["ok"] == true);

    // an explicit scale, no re-planting, and the refusals
    const Json plain = p.ok("anim3d.retarget", {{"path", "anim/hero_walk.anim.json"}, {"to", kGiant}, {"out", "anim/giant_walk2.anim.json"}, {"scale", 2.0}, {"plantFeet", false}});
    CHECK(plain["scale"].get<double>() == doctest::Approx(2.0));
    CHECK(plain["planted"].size() == 0);
    CHECK(contains(p.error_text("anim3d.retarget", {{"path", "anim/hero_walk.anim.json"}, {"to", kGiant}, {"out", "anim/giant_walk.anim.json"}}), "overwrite"));
    CHECK(contains(p.error_text("anim3d.retarget", {{"path", "anim/hero_walk.anim.json"}, {"to", kGiant}}), "out"));
    CHECK(contains(p.error_text("anim3d.retarget", {{"path", "anim/hero_walk.anim.json"}, {"to", "assets/models/gaint.rig.glb"}, {"out", "anim/z.anim.json"}}), "giant.rig.glb"));
    p.ok("anim3d.create", {{"path", "anim/blank.anim.json"}});
    CHECK(contains(p.error_text("anim3d.retarget", {{"path", "anim/blank.anim.json"}, {"to", kGiant}, {"out", "anim/z.anim.json"}}), "from"));
}

TEST_CASE("anim3d.preview draws the filmstrip: deterministic, one picture, the poses differ, and it can keep a PNG") {
    RigProject p;
    p.ok("anim3d.generate", {{"rig", kHero}, {"kind", "walk"}, {"out", "anim/hero_walk.anim.json"}});
    const Json r = p.ok("anim3d.preview", {{"path", "anim/hero_walk.anim.json"}, {"frames", 6}, {"cell", 128}});
    CHECK(r["frames"] == 6);
    CHECK(r["times"].size() == 6);
    CHECK(r["picture"]["columns"] == 3);
    CHECK(r["picture"]["rows"] == 2);
    REQUIRE(r.contains("$image"));
    const Image pic = read_png(r["$image"]["path"].get<std::string>());
    CHECK(pic.width == r["picture"]["width"].get<int>());
    CHECK(pic.height == r["picture"]["height"].get<int>());
    const Json again = p.ok("anim3d.preview", {{"path", "anim/hero_walk.anim.json"}, {"frames", 6}, {"cell", 128}});
    CHECK(read_all(again["$image"]["path"].get<std::string>()) == read_all(r["$image"]["path"].get<std::string>()));

    // the first and the third cell hold different poses (the legs are somewhere else)
    const int cell = 128, pad = 8, header = 46;
    auto cell_pixels = [&](int index) {
        std::vector<std::uint8_t> out;
        const int col = index % 3, row = index / 3;
        const int x0 = pad + col * (cell + pad), y0 = header + pad + row * (cell + 34 + pad);
        for (int y = 0; y < cell; ++y)
            for (int x = 0; x < cell; ++x) {
                const std::uint8_t* px = pic.rgba.data() + (std::size_t(y0 + y) * std::size_t(pic.width) + std::size_t(x0 + x)) * 4;
                out.insert(out.end(), px, px + 3);
            }
        return out;
    };
    CHECK(cell_pixels(0) != cell_pixels(1));
    // a cell is not empty: something other than the flat background is drawn
    const std::vector<std::uint8_t> c0 = cell_pixels(0);
    std::size_t nonBackground = 0;
    for (std::size_t i = 0; i + 2 < c0.size(); i += 3)
        if (c0[i] != c0[0] || c0[i + 1] != c0[1] || c0[i + 2] != c0[2]) ++nonBackground;
    CHECK(nonBackground > 800);

    // keep the PNG
    const Json kept = p.ok("anim3d.preview", {{"path", "anim/hero_walk.anim.json"}, {"frames", 4}, {"out", "docs/walk.png"}});
    CHECK(kept["written"] == "docs/walk.png");
    CHECK(p.exists("docs/walk.png"));
    CHECK(contains(p.error_text("anim3d.preview", {{"path", "anim/hero_walk.anim.json"}, {"frames", 4}, {"out", "docs/walk.png"}}), "overwrite"));
    CHECK(contains(p.error_text("anim3d.preview", {{"path", "anim/hero_walk.anim.json"}, {"frames", 40}}), "frames"));
    CHECK(contains(p.error_text("anim3d.preview", {{"path", "anim/hero_walk.anim.json"}, {"out", "docs/walk.jpg"}}), ".png"));
    // a clip with no rig of its own needs one
    p.ok("anim3d.create", {{"path", "anim/blank.anim.json"}});
    CHECK(contains(p.error_text("anim3d.preview", {{"path", "anim/blank.anim.json"}}), "rig"));
    // a clip for another rig names the bones this one lacks only when they are missing: the hero's clip plays on the giant
    const Json onGiant = p.ok("anim3d.preview", {{"path", "anim/hero_walk.anim.json"}, {"rig", kGiant}, {"frames", 2}, {"cell", 96}});
    CHECK_FALSE(onGiant.contains("missingBones"));
}

TEST_CASE("ik3d.check and ik3d.solve work on a baked rig without a scene") {
    RigProject p;
    const Json good = p.ok("ik3d.check", {{"rig", kHero}, {"solvers", Json::array({{{"type", "lookAt"}, {"bone", "head"}, {"target", "player"}},
                                                                                    {{"type", "foot"}, {"thigh", "thigh_l"}, {"shin", "shin_l"}, {"foot", "foot_l"}}})}});
    CHECK(good["ok"] == true);
    CHECK(good["issues"].size() == 0);
    CHECK(good["bones"].size() == 22);
    const Json bad = p.ok("ik3d.check", {{"rig", kHero}, {"solvers", Json::array({{{"type", "twoBone"}, {"root", "thigh_l"}, {"mid", "shin_q"}, {"end", "foot_l"}}, {{"type", "lookat"}}})}});
    CHECK(bad["ok"] == false);
    REQUIRE(bad["issues"].size() >= 2);
    CHECK(bad["issues"][0]["pointer"] == "/0/mid");
    CHECK(contains(bad["issues"][0]["hint"].get<std::string>(), "shin_l"));

    // an arm reaches a point inside its reach; one far away is "not reached" and the arm is straight towards it
    const Json reach = p.ok("ik3d.solve", {{"rig", kHero}, {"solver", {{"type", "twoBone"}, {"root", "arm_upper_l"}, {"mid", "arm_lower_l"}, {"end", "hand_l"}, {"target", {0.45, 1.2, 0.35}}}}});
    CHECK(reach["reached"] == true);
    CHECK(reach["error"].get<double>() < 0.01);
    const Json far = p.ok("ik3d.solve", {{"rig", kHero}, {"solver", {{"type", "twoBone"}, {"root", "arm_upper_l"}, {"mid", "arm_lower_l"}, {"end", "hand_l"}, {"target", {5, 1.2, 0}}}}});
    CHECK(far["reached"] == false);
    CHECK(far["error"].get<double>() > 3.0);
    // a look-at beyond its limits is clamped, and says how far it turned
    const Json look = p.ok("ik3d.solve", {{"rig", kHero}, {"solver", {{"type", "lookAt"}, {"bone", "head"}, {"target", {0, 1.7, -4}}, {"yawLimit", 40}}}});
    CHECK(look["clamped"] == true);
    CHECK(std::fabs(look["yaw"].get<double>()) <= 40.5);
    // a foot solver on ground 0.1 higher raises the ankle
    const Json foot = p.ok("ik3d.solve", {{"rig", kHero}, {"solver", {{"type", "foot"}, {"thigh", "thigh_l"}, {"shin", "shin_l"}, {"foot", "foot_l"}}}, {"groundHeight", 0.1}});
    CHECK(foot["bones"][2]["head"][1].get<double>() > 0.1);

    // errors: an entity target has no scene, a clip pose needs a clip, typos teach
    CHECK(contains(p.error_text("ik3d.solve", {{"rig", kHero}, {"solver", {{"type", "lookAt"}, {"bone", "head"}, {"target", "player"}}}}), "scene"));
    CHECK(contains(p.error_text("ik3d.solve", {{"rig", kHero}, {"solver", {{"type", "lookAt"}, {"bone", "head"}, {"target", {0, 1, 1}}}}, {"time", 0.5}}), "clip"));
    CHECK(contains(p.error_text("ik3d.solve", {{"rig", kHero}, {"solver", {{"type", "lookAt"}, {"bone", "haed"}, {"target", {0, 1, 1}}}}}), "head"));
    CHECK(contains(p.error_text("ik3d.check", {{"rig", kHero}}), "solvers"));

    // posed by a clip: the foot solver reads the walk's pose
    p.ok("anim3d.generate", {{"rig", kHero}, {"kind", "walk"}, {"out", "anim/hero_walk.anim.json"}});
    const Json posed = p.ok("ik3d.solve", {{"rig", kHero}, {"clip", "anim/hero_walk.anim.json"}, {"time", 0.3},
                                           {"solver", {{"type", "foot"}, {"thigh", "thigh_l"}, {"shin", "shin_l"}, {"foot", "foot_l"}}}});
    CHECK(posed["pose"] == "anim/hero_walk.anim.json");
}

// ---- the commands behind the editor's Animation panel -------------------------------------------------------------------------------------------

namespace {
Json keys_of(const Json& clip, const std::string& bone, const std::string& channel = "rotation") {
    for (const Json& t : clip["tracks"])
        if (t["bone"] == bone && t.value("channel", "rotation") == channel) return t["keys"];
    return Json::array();
}
}  // namespace

TEST_CASE("anim3d edit commands move, remove and ease keys, edit events and clip settings, and every one returns an undo that restores the file") {
    RigProject p;
    p.ok("anim3d.create", {{"path", "anim/a.anim.json"}, {"duration", 1.0}, {"rig", kHero}});
    const Json made = p.ok("anim3d.set_keys", {{"path", "anim/a.anim.json"}, {"bone", "thigh_l"}, {"keys", Json::array({{{"t", 0.0}, {"value", {0, 0, 0}}}, {{"t", 0.5}, {"value", {30, 0, 0}}}, {{"t", 1.0}, {"value", {0, 0, 0}}}})}});
    REQUIRE(made.contains("undo"));
    CHECK(made["undo"]["command"] == "anim3d.restore");
    CHECK(made["undo"]["args"]["clip"]["tracks"].size() == 0);
    const Json start = p.clip("anim/a.anim.json");

    // move: the key goes to its new time, never out of the clip; a collision is refused, an unselected key at the target is replaced
    const Json moved = p.ok("anim3d.move_keys", {{"path", "anim/a.anim.json"}, {"keys", Json::array({{{"bone", "thigh_l"}, {"t", 0.5}}})}, {"dt", 0.25}});
    CHECK(moved["moved"] == 1);
    CHECK(keys_of(p.clip("anim/a.anim.json"), "thigh_l")[1]["t"].get<double>() == doctest::Approx(0.75));
    CHECK(contains(p.error_text("anim3d.move_keys", {{"path", "anim/a.anim.json"}, {"keys", Json::array({{{"bone", "thigh_l"}, {"t", 0.75}}})}, {"dt", 0.5}}), "after the end"));
    CHECK(contains(p.error_text("anim3d.move_keys", {{"path", "anim/a.anim.json"}, {"keys", Json::array({{{"bone", "thigh_l"}, {"t", 0.0}}})}, {"dt", -0.1}}), "before the start"));
    CHECK(contains(p.error_text("anim3d.move_keys", {{"path", "anim/a.anim.json"}, {"keys", Json::array({{{"bone", "thigh_l"}, {"t", 0.6}}})}, {"dt", 0.1}}), "t=0.6"));
    p.ok("anim3d.move_keys", {{"path", "anim/a.anim.json"}, {"keys", Json::array({{{"bone", "thigh_l"}, {"t", 0.75}}})}, {"dt", 0.25}});  // onto the key at 1.0: replaces it
    CHECK(keys_of(p.clip("anim/a.anim.json"), "thigh_l").size() == 2);
    const Json extended = p.ok("anim3d.move_keys", {{"path", "anim/a.anim.json"}, {"keys", Json::array({{{"bone", "thigh_l"}, {"t", 1.0}}})}, {"dt", 0.5}, {"extendDuration", true}});
    CHECK(extended["duration"].get<double>() == doctest::Approx(1.5));

    // undo of a move is a restore of the whole previous document; the restore's own undo goes forward again
    const Json undo = extended["undo"];
    const Json back = p.ok(undo["command"].get<std::string>(), undo["args"]);
    CHECK(p.clip("anim/a.anim.json")["duration"].get<double>() == doctest::Approx(1.0));
    const Json redo = p.ok(back["undo"]["command"].get<std::string>(), back["undo"]["args"]);
    CHECK(p.clip("anim/a.anim.json")["duration"].get<double>() == doctest::Approx(1.5));
    (void)redo;

    // easing and removal
    p.ok("anim3d.set_interp", {{"path", "anim/a.anim.json"}, {"keys", Json::array({{{"bone", "thigh_l"}, {"t", 0.0}}})}, {"interp", "quadInOut"}});
    CHECK(keys_of(p.clip("anim/a.anim.json"), "thigh_l")[0]["interp"] == "quadInOut");
    CHECK(contains(p.error_text("anim3d.set_interp", {{"path", "anim/a.anim.json"}, {"keys", Json::array({{{"bone", "thigh_l"}, {"t", 0.0}}})}, {"interp", "quadInOu"}}), "quadInOut"));
    CHECK(contains(p.error_text("anim3d.remove_keys", {{"path", "anim/a.anim.json"}, {"keys", Json::array({{{"bone", "thigh_l"}, {"t", 0.3}}})}}), "no key at"));
    const Json removed = p.ok("anim3d.remove_keys", {{"path", "anim/a.anim.json"}, {"keys", Json::array({{{"bone", "thigh_l"}, {"t", 0.0}}, {{"bone", "thigh_l"}, {"t", 1.5}}})}});
    CHECK(removed["removed"] == 2);
    CHECK(removed["tracksRemoved"] == 1);  // the track had two keys
    CHECK(p.clip("anim/a.anim.json")["tracks"].size() == 0);
    p.ok(removed["undo"]["command"].get<std::string>(), removed["undo"]["args"]);
    CHECK(p.clip("anim/a.anim.json")["tracks"].size() == 1);

    // events
    p.ok("anim3d.add_event", {{"path", "anim/a.anim.json"}, {"t", 0.5}, {"name", "footstep"}, {"data", {{"foot", "left"}}}});
    p.ok("anim3d.add_event", {{"path", "anim/a.anim.json"}, {"t", 0.1}, {"name", "swish"}});
    Json doc = p.clip("anim/a.anim.json");
    REQUIRE(doc["events"].size() == 2);
    CHECK(doc["events"][0]["name"] == "swish");  // sorted by t
    CHECK(contains(p.error_text("anim3d.add_event", {{"path", "anim/a.anim.json"}, {"t", 9.0}, {"name", "late"}}), "extendDuration"));
    p.ok("anim3d.set_event", {{"path", "anim/a.anim.json"}, {"event", {{"t", 0.5}, {"name", "footstep"}}}, {"t", 0.3}, {"name", "step"}});
    CHECK(p.clip("anim/a.anim.json")["events"][1]["name"] == "step");
    CHECK(p.clip("anim/a.anim.json")["events"][1]["data"]["foot"] == "left");
    // feel actions on an event: a valid one is stored, a typo teaches the right name, on add and on set
    p.ok("anim3d.add_event", {{"path", "anim/a.anim.json"}, {"t", 0.2}, {"feel", {{"action", "hitStop"}, {"duration", 0.05}}}});
    {
        const Json evs = p.clip("anim/a.anim.json")["events"];
        bool found = false;
        for (const Json& e : evs)
            if (e.contains("feel") && e["feel"].value("action", "") == "hitStop") found = true;
        CHECK(found);
    }
    const std::string addTypo = p.error_text("anim3d.add_event", {{"path", "anim/a.anim.json"}, {"t", 0.25}, {"feel", {{"action", "hitStp"}}}});
    CHECK(contains(addTypo, "hitStop"));
    CHECK(contains(addTypo, "Did you mean"));
    p.ok("anim3d.set_event", {{"path", "anim/a.anim.json"}, {"event", {{"t", 0.2}}}, {"feel", Json::array({{{"action", "shake"}, {"amount", 0.3}}})}});
    const std::string setTypo = p.error_text("anim3d.set_event", {{"path", "anim/a.anim.json"}, {"event", {{"t", 0.2}}}, {"feel", {{"action", "shak"}}}});
    CHECK(contains(setTypo, "shake"));
    CHECK(contains(setTypo, "Did you mean"));
    p.ok("anim3d.remove_event", {{"path", "anim/a.anim.json"}, {"event", 1}});  // the hit-stop event is no longer needed
    doc = p.clip("anim/a.anim.json");
    REQUIRE(doc["events"].size() == 2);
    CHECK(contains(p.error_text("anim3d.remove_event", {{"path", "anim/a.anim.json"}, {"event", 5}}), "no event 5"));
    const Json gone = p.ok("anim3d.remove_event", {{"path", "anim/a.anim.json"}, {"event", 0}});
    CHECK(gone["removed"]["name"] == "swish");
    CHECK(p.clip("anim/a.anim.json")["events"].size() == 1);

    // clip settings
    p.ok("anim3d.set_clip", {{"path", "anim/a.anim.json"}, {"duration", 2.0}, {"loop", false}, {"groundSpeed", 1.5}});
    doc = p.clip("anim/a.anim.json");
    CHECK(doc["duration"].get<double>() == doctest::Approx(2.0));
    CHECK(doc["loop"] == false);
    CHECK(doc["groundSpeed"].get<double>() == doctest::Approx(1.5));
    CHECK(contains(p.error_text("anim3d.set_clip", {{"path", "anim/a.anim.json"}, {"duration", 0.1}}), "/"));  // shorter than its last key
    CHECK(contains(p.error_text("anim3d.set_clip", {{"path", "anim/a.anim.json"}}), "nothing to change"));

    // restore can delete: the undo of a file a call created
    const Json created = p.ok("anim3d.create", {{"path", "anim/new.anim.json"}});
    CHECK(created["undo"]["args"]["clip"].is_null());
    p.ok("anim3d.restore", created["undo"]["args"].contains("path") ? Json{{"path", created["undo"]["args"]["path"]}, {"clip", nullptr}} : Json::object());
    CHECK_FALSE(p.exists("anim/new.anim.json"));
    // the original start is reachable through the first undo
    p.ok("anim3d.restore", {{"path", "anim/a.anim.json"}, {"clip", start}});
    CHECK(keys_of(p.clip("anim/a.anim.json"), "thigh_l").size() == 3);
    CHECK(contains(p.error_text("anim3d.restore", {{"path", "anim/a.anim.json"}, {"clip", Json::object({{"format", "factoria.anim/1"}})}}), "3D clip"));
}

TEST_CASE("anim3d.mirror_pose swaps or copies left and right by canonical name, and ik3d.key keys the bones a solver moved") {
    RigProject p;
    p.ok("anim3d.create", {{"path", "anim/m.anim.json"}, {"duration", 1.0}, {"rig", kHero}});
    p.ok("anim3d.set_keys", {{"path", "anim/m.anim.json"}, {"bone", "thigh_l"}, {"keys", Json::array({{{"t", 0.0}, {"value", {30, 10, 5}}}})}});
    p.ok("anim3d.set_keys", {{"path", "anim/m.anim.json"}, {"bone", "spine_1"}, {"keys", Json::array({{{"t", 0.0}, {"value", {4, 8, 6}}}})}});
    p.ok("anim3d.set_keys", {{"path", "anim/m.anim.json"}, {"bone", "root"}, {"channel", "translation"}, {"keys", Json::array({{{"t", 0.0}, {"value", {0.1, 0.2, 0.3}}}})}});

    // swap: the right thigh gets the mirrored left one (pitch stays, yaw and roll flip), the left one gets the (rest) right one; the spine mirrors in place
    p.ok("anim3d.mirror_pose", {{"path", "anim/m.anim.json"}, {"time", 0.0}, {"to", 0.5}});
    const Json doc = p.clip("anim/m.anim.json");
    const Json r = keys_of(doc, "thigh_r");
    REQUIRE(r.size() == 1);
    CHECK(r[0]["t"].get<double>() == doctest::Approx(0.5));
    CHECK(r[0]["value"][0].get<double>() == doctest::Approx(30).epsilon(0.001));
    CHECK(r[0]["value"][1].get<double>() == doctest::Approx(-10).epsilon(0.001));
    CHECK(r[0]["value"][2].get<double>() == doctest::Approx(-5).epsilon(0.001));
    const Json l = keys_of(doc, "thigh_l");
    REQUIRE(l.size() == 2);
    CHECK(std::abs(l[1]["value"][0].get<double>()) < 0.001);  // the right thigh was at rest
    const Json s = keys_of(doc, "spine_1");
    CHECK(s[1]["value"][1].get<double>() == doctest::Approx(-8).epsilon(0.001));
    CHECK(keys_of(doc, "root", "translation")[1]["value"][0].get<double>() == doctest::Approx(-0.1).epsilon(0.001));
    // copy left onto right leaves the left side and the spine alone
    p.ok("anim3d.create", {{"path", "anim/c.anim.json"}, {"duration", 1.0}, {"rig", kHero}, {"overwrite", true}});
    p.ok("anim3d.set_keys", {{"path", "anim/c.anim.json"}, {"bone", "thigh_l"}, {"keys", Json::array({{{"t", 0.0}, {"value", {30, 10, 5}}}})}});
    p.ok("anim3d.set_keys", {{"path", "anim/c.anim.json"}, {"bone", "spine_1"}, {"keys", Json::array({{{"t", 0.0}, {"value", {4, 8, 6}}}})}});
    p.ok("anim3d.mirror_pose", {{"path", "anim/c.anim.json"}, {"time", 0.0}, {"from", "left"}, {"to", 0.5}});
    const Json c = p.clip("anim/c.anim.json");
    CHECK(keys_of(c, "thigh_l").size() == 1);
    CHECK(keys_of(c, "spine_1").size() == 1);
    CHECK(keys_of(c, "thigh_r").size() == 1);
    CHECK(contains(p.error_text("anim3d.mirror_pose", {{"path", "anim/c.anim.json"}, {"time", 0.0}, {"from", "lefft"}}), "left"));
    CHECK(contains(p.error_text("anim3d.mirror_pose", {{"path", "anim/c.anim.json"}, {"time", 7.0}}), "0 to"));

    // ik3d.key: a two-bone arm reaches a target at 0.5 s; keys appear for the bones it moved and the hand ends near the target
    p.ok("anim3d.create", {{"path", "anim/ik.anim.json"}, {"duration", 1.0}, {"rig", kHero}});
    const Json solver = {{"type", "twoBone"}, {"root", "arm_upper_r"}, {"mid", "arm_lower_r"}, {"end", "hand_r"}, {"target", {-0.55, 1.2, 0.35}}, {"pole", {-0.6, 1.0, -0.6}}};
    const Json keyed = p.ok("ik3d.key", {{"path", "anim/ik.anim.json"}, {"time", 0.5}, {"solver", solver}});
    CHECK(keyed["keyed"].size() >= 2);
    CHECK(keyed["solved"]["reached"] == true);
    CHECK(keyed["undo"]["command"] == "anim3d.restore");
    const Json ik = p.clip("anim/ik.anim.json");
    CHECK(keys_of(ik, "arm_upper_r").size() == 1);
    CHECK(keys_of(ik, "arm_lower_r").size() == 1);
    p.ok("anim3d.restore", keyed["undo"]["args"]);
    CHECK(p.clip("anim/ik.anim.json")["tracks"].size() == 0);
    CHECK(contains(p.error_text("ik3d.key", {{"path", "anim/ik.anim.json"}, {"solver", solver}}), "time"));
}

TEST_CASE("anim3d.preview draws several sides in one sheet: a row per yaw, the rows differ, errors teach") {
    RigProject p;
    p.ok("anim3d.generate", {{"rig", kHero}, {"kind", "walk"}, {"out", "anim/hero_walk.anim.json"}});
    const Json r = p.ok("anim3d.preview", {{"path", "anim/hero_walk.anim.json"}, {"frames", 4}, {"cell", 96}, {"yaws", {-70, 0, 90}}});
    CHECK(r["picture"]["columns"] == 4);
    CHECK(r["picture"]["rows"] == 3);
    CHECK(r["yaws"].size() == 3);
    const Image pic = read_png(r["$image"]["path"].get<std::string>());
    CHECK(pic.width == r["picture"]["width"].get<int>());
    CHECK(pic.height == r["picture"]["height"].get<int>());
    const int cell = 96, pad = 8, header = 46;
    auto cell_pixels = [&](int col, int row) {
        std::vector<std::uint8_t> out;
        const int x0 = pad + col * (cell + pad), y0 = header + pad + row * (cell + 34 + pad);
        for (int y = 0; y < cell; ++y)
            for (int x = 0; x < cell; ++x) {
                const std::uint8_t* px = pic.rgba.data() + (std::size_t(y0 + y) * std::size_t(pic.width) + std::size_t(x0 + x)) * 4;
                out.insert(out.end(), px, px + 3);
            }
        return out;
    };
    CHECK(cell_pixels(0, 0) != cell_pixels(0, 1));  // the same time from another side
    CHECK(cell_pixels(0, 1) != cell_pixels(0, 2));
    // the single-yaw call still draws what it drew (its first row equals the same side of the sheet)
    const Json single = p.ok("anim3d.preview", {{"path", "anim/hero_walk.anim.json"}, {"frames", 4}, {"cell", 96}, {"yaw", 0}});
    CHECK(single["picture"]["rows"] == 1);
    CHECK(contains(p.error_text("anim3d.preview", {{"path", "anim/hero_walk.anim.json"}, {"yaw", 0}, {"yaws", {0, 90}}}), "not both"));
    CHECK(contains(p.error_text("anim3d.preview", {{"path", "anim/hero_walk.anim.json"}, {"yaws", Json::array()}}), "1 to 6"));
    CHECK(contains(p.error_text("anim3d.preview", {{"path", "anim/hero_walk.anim.json"}, {"frames", 12}, {"yaws", {0, 1, 2, 3, 4}}}), "48"));
}
