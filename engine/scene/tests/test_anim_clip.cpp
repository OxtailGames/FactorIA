// Keyframed 2D clips (*.anim.json): the loader and its errors, every interpolation, and the Animator that plays them.
#include <doctest.h>

#include <chrono>
#include <cmath>
#include <filesystem>
#include <string>

#include <fstream>
#include <set>
#include <sstream>

#include "fa/core/fs.h"
#include "fa_test_paths.h"
#include "fa/scene/anim_clip.h"
#include "fa/scene/animation.h"
#include "fa/scene/components.h"
#include "fa/scene/serialize.h"

using namespace fa;

namespace {

struct TempProject {
    std::filesystem::path dir, oldRoot;
    TempProject() {
        ensure_builtin_components();
        oldRoot = fs::project_root();
        dir = std::filesystem::temp_directory_path() /
              ("fa_test_animclip_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
        std::filesystem::create_directories(dir);
        fs::set_project_root(dir);
        clear_anim_clip_cache();
    }
    ~TempProject() {
        fs::set_project_root(oldRoot);
        clear_anim_clip_cache();
        std::error_code ec;
        std::filesystem::remove_all(dir, ec);
    }
    void write(const std::string& path, const std::string& text) { REQUIRE(fs::write_text(path, text).ok()); }
};

// {"path": ..., "component": ..., "field": ..., "keys": [...]} with `keys` written by the caller.
std::string track(const std::string& path, const std::string& component, const std::string& field, const std::string& keys) {
    return "{\"path\":\"" + path + "\",\"component\":\"" + component + "\",\"field\":\"" + field + "\",\"keys\":" + keys + "}";
}
std::string clip(float duration, bool loop, const std::string& tracks, const std::string& events = "[]") {
    return "{\"format\":\"factoria.anim/1\",\"duration\":" + std::to_string(duration) + ",\"loop\":" + (loop ? "true" : "false") +
           ",\"tracks\":[" + tracks + "],\"events\":" + events + "}";
}

std::shared_ptr<const ClipAsset> parse(const std::string& text) {
    auto r = parse_anim_clip(Json::parse(text), "test.anim.json");
    const std::string err = r.ok() ? std::string() : r.error().to_string();
    INFO(err);
    REQUIRE(r.ok());
    return *r;
}

float value_at(const std::string& keys, float t, const char* field = "rotation.z") {
    auto c = parse(clip(10, true, track("", "Transform", field, keys)));
    std::array<float, 4> out{};
    sample_clip_track(c->tracks[0], t, out, nullptr);
    return out[0];
}

// hero -> body (Transform, Sprite) -> arm (Transform, Sprite)
struct Rig {
    World world;
    Entity hero, body, arm;
    Animator* a;
    Rig() {
        hero = world.create("hero", "hero");
        a = &world.add<Animator>(hero);
        body = world.create("body", "body");
        world.set_parent(body, hero);
        world.add<Sprite>(body);
        arm = world.create("arm", "arm");
        world.set_parent(arm, body);
        world.add<Sprite>(arm);
    }
    Transform& bodyT() { return *world.get<Transform>(body); }
    Transform& armT() { return *world.get<Transform>(arm); }
    Sprite& bodyS() { return *world.get<Sprite>(body); }
    Sprite& armS() { return *world.get<Sprite>(arm); }
    // One fixed step; the names of the game events it produced.
    std::vector<std::string> step(float dt = 0.25f) {
        update_animators(world, dt);
        std::vector<std::string> names;
        for (const GameEvent& g : world.events().game) names.push_back(g.name);
        world.events().game.clear();
        return names;
    }
    void clips(const char* json) { a->clips = Json::parse(json); }
};

int count(const std::vector<std::string>& v, const std::string& name) {
    int n = 0;
    for (const auto& s : v) n += s == name;
    return n;
}

}  // namespace

// ============================================================================================ interpolation ======

TEST_CASE("anim clip: linear, step and keys outside the range") {
    TempProject p;
    const std::string keys = R"([{"t":0,"value":0},{"t":2,"value":10},{"t":4,"value":10,"interp":"step"},{"t":6,"value":-5}])";
    CHECK(value_at(keys, 0.0f) == doctest::Approx(0.0f));
    CHECK(value_at(keys, 1.0f) == doctest::Approx(5.0f));
    CHECK(value_at(keys, 2.0f) == doctest::Approx(10.0f));
    CHECK(value_at(keys, 3.0f) == doctest::Approx(10.0f));
    CHECK(value_at(keys, 5.0f) == doctest::Approx(10.0f));    // step: holds the key until the next one
    CHECK(value_at(keys, 6.0f) == doctest::Approx(-5.0f));
    CHECK(value_at(keys, 9.0f) == doctest::Approx(-5.0f));    // past the last key: held
    CHECK(value_at(R"([{"t":1,"value":3}])", 0.0f) == doctest::Approx(3.0f));  // before the first key: held
}

TEST_CASE("anim clip: every easing name of tween() is an interp and runs from 0 to 1") {
    TempProject p;
    const std::vector<std::string>& names = clip_ease_names();
    REQUIRE(names.size() > 20);
    CHECK(names.front() == "linear");
    for (std::size_t i = 0; i < names.size(); ++i) {
        INFO(names[i]);
        CHECK(clip_ease(int(i), 0.0f) == doctest::Approx(0.0f).epsilon(1e-4));
        CHECK(clip_ease(int(i), 1.0f) == doctest::Approx(1.0f).epsilon(1e-4));
        const std::string keys = "[{\"t\":0,\"value\":0,\"interp\":\"" + names[i] + "\"},{\"t\":1,\"value\":100}]";
        CHECK(value_at(keys, 1.0f) == doctest::Approx(100.0f).epsilon(1e-3));
        CHECK(value_at(keys, 0.0f) == doctest::Approx(0.0f).epsilon(1e-3));
    }
    CHECK(value_at(R"([{"t":0,"value":0,"interp":"quadOut"},{"t":1,"value":100}])", 0.5f) == doctest::Approx(75.0f));
    CHECK(value_at(R"([{"t":0,"value":0,"interp":"quadIn"},{"t":1,"value":100}])", 0.5f) == doctest::Approx(25.0f));
    // an easing with overshoot leaves the range between the two keys
    CHECK(value_at(R"([{"t":0,"value":0,"interp":"backOut"},{"t":1,"value":100}])", 0.8f) > 100.0f);
}

TEST_CASE("anim clip: bezier follows the tangents of the keys, and builds smooth ones when they are missing") {
    TempProject p;
    // Hermite with out = 10 at the first key and in = 0 at the second: at the middle 0.5*0 + 0.125*10 + 0.5*10 - 0.125*0.
    const std::string keys = R"([{"t":0,"value":0,"interp":"bezier","out":10},{"t":1,"value":10,"in":0}])";
    CHECK(value_at(keys, 0.5f) == doctest::Approx(6.25f));
    CHECK(value_at(keys, 0.0f) == doctest::Approx(0.0f));
    CHECK(value_at(keys, 1.0f) == doctest::Approx(10.0f));
    // auto tangents: zero slope at the ends, the neighbours' slope inside -> an S curve through the keys
    const std::string autoKeys = R"([{"t":0,"value":0,"interp":"bezier"},{"t":1,"value":10,"interp":"bezier"},{"t":2,"value":10}])";
    CHECK(value_at(autoKeys, 1.0f) == doctest::Approx(10.0f));
    CHECK(value_at(autoKeys, 0.5f) == doctest::Approx(0.5f * 0.0f + 0.125f * 0.0f + 0.5f * 10.0f - 0.125f * 5.0f));  // in slope (10-0)/2 = 5
    CHECK(value_at(autoKeys, 0.5f) > 0.0f);
    // vector tangents
    auto c = parse(clip(1, true, track("", "Transform", "position", R"([{"t":0,"value":[0,0,0],"interp":"bezier","out":[10,0,0]},{"t":1,"value":[10,5,0],"in":[0,0,0]}])")));
    std::array<float, 4> out{};
    sample_clip_track(c->tracks[0], 0.5f, out, nullptr);
    CHECK(out[0] == doctest::Approx(6.25f));
    CHECK(out[1] == doctest::Approx(2.5f));
}

TEST_CASE("anim clip: vectors, colours and one channel of a vector interpolate; bool, int, enum and asset only step") {
    TempProject p;
    auto c = parse(clip(1, true,
                        track("", "Transform", "position", R"([{"t":0,"value":[0,0,0]},{"t":1,"value":[10,20,30]}])") + "," +
                            track("", "Sprite", "color", R"([{"t":0,"value":[1,0,0,1]},{"t":1,"value":[0,0,1,0]}])") + "," +
                            track("", "Transform", "scale.y", R"([{"t":0,"value":1},{"t":1,"value":0.5}])") + "," +
                            track("", "Sprite", "flipX", R"([{"t":0,"value":false},{"t":0.5,"value":true}])") + "," +
                            track("", "Sprite", "layer", R"([{"t":0,"value":1},{"t":0.5,"value":4}])") + "," +
                            track("", "Sprite", "blend", R"([{"t":0,"value":"alpha"},{"t":0.5,"value":"additive"}])") + "," +
                            track("", "Sprite", "texture", R"([{"t":0,"value":"a.png"},{"t":0.5,"value":"b.png"}])")));
    REQUIRE(c->tracks.size() == 7);
    std::array<float, 4> v{};
    sample_clip_track(c->tracks[0], 0.5f, v, nullptr);
    CHECK(v[0] == doctest::Approx(5)); CHECK(v[1] == doctest::Approx(10)); CHECK(v[2] == doctest::Approx(15));
    sample_clip_track(c->tracks[1], 0.5f, v, nullptr);
    CHECK(v[0] == doctest::Approx(0.5)); CHECK(v[2] == doctest::Approx(0.5)); CHECK(v[3] == doctest::Approx(0.5));
    CHECK(c->tracks[2].channel == 1);
    sample_clip_track(c->tracks[2], 1.0f, v, nullptr);
    CHECK(v[0] == doctest::Approx(0.5));
    const Json* raw = nullptr;
    for (int i = 3; i < 7; ++i) {
        CHECK(c->tracks[std::size_t(i)].stepped);
        sample_clip_track(c->tracks[std::size_t(i)], 0.49f, v, &raw);
        REQUIRE(raw);
        const Json before = *raw;
        sample_clip_track(c->tracks[std::size_t(i)], 0.5f, v, &raw);
        REQUIRE(raw);
        CHECK(*raw != before);
    }
    CHECK(c->tracks[0].angle == false);
    CHECK(parse(clip(1, true, track("", "Transform", "rotation.z", R"([{"t":0,"value":0}])")))->tracks[0].angle);
}

// ======================================================================================================= errors ======

namespace {
std::vector<ClipIssue> issues_of(const std::string& text) {
    std::vector<ClipIssue> issues;
    auto r = parse_anim_clip(Json::parse(text), "anim/x.anim.json", &issues);
    CHECK_FALSE(r.ok());
    return issues;
}
bool has_issue(const std::vector<ClipIssue>& is, const std::string& pointer, const std::string& word) {
    for (const ClipIssue& i : is)
        if (i.pointer == pointer && (i.message + " " + i.hint).find(word) != std::string::npos) return true;
    return false;
}
}  // namespace

TEST_CASE("anim clip errors: file, JSON pointer, what is wrong and how to fix it") {
    TempProject p;
    SUBCASE("a field that cannot be animated") {
        auto is = issues_of(clip(1, true, track("", "Animator", "clip", R"([{"t":0,"value":"x"}])")));
        REQUIRE(is.size() == 1);
        CHECK(is[0].pointer == "/tracks/0/field");
        CHECK(is[0].message.find("cannot be animated") != std::string::npos);
        CHECK(is[0].hint.find("Animatable fields of Animator") != std::string::npos);
    }
    SUBCASE("a misspelled field and component") {
        auto is = issues_of(clip(1, true, track("", "Transform", "rotaton.z", R"([{"t":0,"value":0}])") + "," +
                                             track("", "Sprit", "color", R"([{"t":0,"value":[1,1,1,1]}])")));
        CHECK(has_issue(is, "/tracks/0/field", "rotation"));
        CHECK(has_issue(is, "/tracks/1/component", "Sprite"));
    }
    SUBCASE("a value of the wrong type") {
        auto is = issues_of(clip(1, true, track("", "Transform", "rotation.z", R"([{"t":0,"value":"high"}])") + "," +
                                             track("", "Sprite", "color", R"([{"t":0,"value":[1,2]}])") + "," +
                                             track("", "Sprite", "layer", R"([{"t":0,"value":1.5}])") + "," +
                                             track("", "Sprite", "blend", R"([{"t":0,"value":"glowy"}])")));
        CHECK(has_issue(is, "/tracks/0/keys/0/value", "expected a number"));
        CHECK(has_issue(is, "/tracks/1/keys/0/value", "array"));
        CHECK(has_issue(is, "/tracks/2/keys/0/value", "integer"));
        CHECK(has_issue(is, "/tracks/3/keys/0/value", "additive"));  // did you mean / the valid names
    }
    SUBCASE("keys out of order, equal times and keys past the duration") {
        auto is = issues_of(clip(2, true, track("", "Transform", "rotation.z", R"([{"t":1,"value":0},{"t":0.5,"value":1},{"t":3,"value":2},{"t":1,"value":4}])")));
        CHECK(has_issue(is, "/tracks/0/keys/1/t", "ascending"));
        CHECK(has_issue(is, "/tracks/0/keys/2/t", "duration"));
        CHECK(has_issue(is, "/tracks/0/keys/3/t", "ascending"));
    }
    SUBCASE("two tracks on the same channel") {
        auto is = issues_of(clip(1, true, track("", "Transform", "position", R"([{"t":0,"value":[0,0,0]}])") + "," +
                                             track("", "Transform", "position.x", R"([{"t":0,"value":1}])") + "," +
                                             track("", "Transform", "rotation.z", R"([{"t":0,"value":1}])") + "," +
                                             track("", "Transform", "rotation.x", R"([{"t":0,"value":1}])")));
        REQUIRE(is.size() == 1);
        CHECK(is[0].pointer == "/tracks/1/field");
        CHECK(is[0].message.find("already driven") != std::string::npos);
    }
    SUBCASE("unknown interp, unknown keys and bad events") {
        const std::string text = "{\"format\":\"factoria.anim/1\",\"duration\":1,\"lop\":true,\"tracks\":[" +
                                 track("", "Transform", "rotation.z", R"([{"t":0,"value":0,"interp":"quadOutt"}])") +
                                 "],\"events\":[{\"t\":2,\"name\":\"hit\"},{\"t\":0.5}]}";
        auto is = issues_of(text);
        CHECK(has_issue(is, "/lop", "loop"));
        CHECK(has_issue(is, "/tracks/0/keys/0/interp", "quadOut"));
        CHECK(has_issue(is, "/events/0/t", "duration"));
        CHECK(has_issue(is, "/events/1/name", "name"));
        auto reserved = issues_of(clip(1, true, "", R"([{"t":0,"name":"hit","data":{"time":3}}])"));
        CHECK(has_issue(reserved, "/events/0/data/time", "Rename"));
    }
    SUBCASE("the error names the file, the pointer and how many more problems there are") {
        auto r = parse_anim_clip(Json::parse(clip(1, true, track("", "Transform", "rotaton", R"([{"t":0,"value":0}])") + "," +
                                                               track("", "Transform", "rotaton", R"([{"t":0,"value":0}])"))),
                                 "anim/x.anim.json");
        REQUIRE_FALSE(r.ok());
        const std::string m = r.error().message;
        CHECK(m.find("anim/x.anim.json /tracks/0/field") != std::string::npos);
        CHECK(m.find("1 more problem") != std::string::npos);
    }
    SUBCASE("a missing file and an invalid one") {
        CHECK_FALSE(load_anim_clip("anim/none.anim.json").ok());
        p.write("anim/bad.anim.json", "{ nope");
        auto r = load_anim_clip("anim/bad.anim.json");
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().to_string().find("anim/bad.anim.json") != std::string::npos);
    }
}

// =========================================================================================== path resolution ======

TEST_CASE("anim clip paths: names below the entity, and a path that is wrong teaches") {
    TempProject p;
    Rig rig;
    CHECK(*resolve_clip_path(rig.world, rig.hero, "") == rig.hero);
    CHECK(*resolve_clip_path(rig.world, rig.hero, "body/arm") == rig.arm);
    auto typo = resolve_clip_path(rig.world, rig.hero, "bdy/arm");
    REQUIRE_FALSE(typo.ok());
    CHECK(typo.error().hint.find("body") != std::string::npos);  // did you mean
    auto deep = resolve_clip_path(rig.world, rig.hero, "arm");   // exists, but one level down
    REQUIRE_FALSE(deep.ok());
    CHECK(deep.error().hint.find("body/arm") != std::string::npos);
    auto c = parse(clip(1, true, track("body/arm", "Transform", "rotation.z", R"([{"t":0,"value":0}])") + "," +
                                     track("nope", "Transform", "rotation.z", R"([{"t":0,"value":0}])")));
    auto bad = check_clip_paths(rig.world, rig.hero, *c);
    REQUIRE(bad.size() == 1);
    CHECK(bad[0].pointer == "/tracks/1/path");
}

// ========================================================================================== the Animator ======

TEST_CASE("animator 2D clips: the clip drives the fields of the entity and its children") {
    TempProject p;
    p.write("anim/walk.anim.json",
            clip(1, true,
                 track("body", "Transform", "rotation.z", R"([{"t":0,"value":0},{"t":1,"value":90}])") + "," +
                     track("body/arm", "Sprite", "color.a", R"([{"t":0,"value":1},{"t":1,"value":0}])") + "," +
                     track("body/arm", "Sprite", "flipX", R"([{"t":0,"value":false},{"t":0.5,"value":true}])")));
    Rig rig;
    rig.clips(R"({"walk":"anim/walk.anim.json"})");
    rig.a->clip = "walk";
    rig.step(0.25f);
    CHECK(rig.bodyT().rotation.z == doctest::Approx(22.5f));
    CHECK(rig.armS().color.a == doctest::Approx(0.75f));
    CHECK_FALSE(rig.armS().flipX);
    CHECK(rig.a->time == doctest::Approx(0.25f));
    rig.step(0.25f);
    CHECK(rig.bodyT().rotation.z == doctest::Approx(45.0f));
    CHECK(rig.armS().flipX);                       // the step key at 0.5
    rig.step(0.5f);                                // t = 1: the loop wrapped to 0
    CHECK(rig.bodyT().rotation.z == doctest::Approx(0.0f));
    CHECK(rig.armS().color.a == doctest::Approx(1.0f));
    CHECK_FALSE(rig.armS().flipX);
    // speed
    rig.a->speed = 2.0f;
    rig.step(0.25f);
    CHECK(rig.bodyT().rotation.z == doctest::Approx(45.0f));
    // what the clip does not touch stays
    CHECK(rig.armT().rotation.z == doctest::Approx(0.0f));
    CHECK(rig.armS().size.x == doctest::Approx(0.0f));
}

TEST_CASE("animator 2D clips: a script play() and the errors it teaches") {
    TempProject p;
    p.write("anim/idle.anim.json", clip(1, true, track("body", "Transform", "position.x", R"([{"t":0,"value":4}])")));
    p.write("anim/typo.anim.json", clip(1, true, track("bdy", "Transform", "position.x", R"([{"t":0,"value":4}])")));
    Rig rig;
    rig.clips(R"({"idle":"anim/idle.anim.json","typo":"anim/typo.anim.json","gone":"anim/gone.anim.json"})");
    CHECK(animator_play(rig.world, rig.hero, "idle", 0).ok());
    rig.step(0.1f);
    CHECK(rig.bodyT().position.x == doctest::Approx(4.0f));
    auto name = animator_play(rig.world, rig.hero, "idel", 0);
    REQUIRE_FALSE(name.ok());
    CHECK(name.error().to_string().find("idle") != std::string::npos);
    auto path = animator_play(rig.world, rig.hero, "typo", 0);
    REQUIRE_FALSE(path.ok());
    CHECK(path.error().message.find("anim/typo.anim.json /tracks/0/path") != std::string::npos);
    CHECK(path.error().hint.find("body") != std::string::npos);
    auto file = animator_play(rig.world, rig.hero, "gone", 0);
    REQUIRE_FALSE(file.ok());
    CHECK(file.error().to_string().find("anim/gone.anim.json") != std::string::npos);
    CHECK(rig.a->clip == "idle");  // a play() that failed leaves the clip playing
    auto list = animator_clips(rig.world, rig.hero);
    REQUIRE(list.ok());
    REQUIRE(list->size() == 3);
    CHECK((*list)[0]["name"] == "idle");
    CHECK((*list)[0]["duration"].get<float>() == doctest::Approx(1.0f));
    CHECK((*list)[2].contains("error"));
}

TEST_CASE("animator 2D clips: clip events fire once per loop, anim.finished once for a clip that does not loop") {
    TempProject p;
    p.write("anim/step.anim.json",
            clip(1, true, track("", "Transform", "position.x", R"([{"t":0,"value":0},{"t":1,"value":10}])"),
                 R"([{"t":0.5,"name":"footstep","data":{"foot":"left"}},{"t":1,"name":"lap"}])"));
    p.write("anim/once.anim.json", clip(1, false, track("", "Transform", "position.x", R"([{"t":0,"value":0},{"t":1,"value":10}])"),
                                        R"([{"t":0.75,"name":"mid"}])"));
    Rig rig;
    rig.clips(R"({"step":"anim/step.anim.json","once":"anim/once.anim.json"})");
    rig.a->clip = "step";
    int steps = 0, lap = 0;
    Json firstData;
    for (int i = 0; i < 12; ++i) {  // 3 seconds = 3 loops
        update_animators(rig.world, 0.25f);
        for (const GameEvent& g : rig.world.events().game) {
            if (g.name == "footstep") {
                if (steps++ == 0) firstData = g.data;
            }
            lap += g.name == "lap";
        }
        rig.world.events().game.clear();
    }
    CHECK(steps == 3);
    CHECK(lap == 3);
    CHECK(firstData["foot"] == "left");
    CHECK(firstData["clip"] == "step");
    CHECK(firstData["id"] == "hero");
    CHECK(firstData["time"].get<float>() == doctest::Approx(0.5f));
    // a clip that does not loop
    CHECK(animator_play(rig.world, rig.hero, "once", 0).ok());
    int mids = 0, finished = 0;
    for (int i = 0; i < 8; ++i) {
        for (const std::string& n : rig.step(0.25f)) {
            mids += n == "mid";
            finished += n == "anim.finished";
        }
    }
    CHECK(mids == 1);
    CHECK(finished == 1);
    CHECK_FALSE(rig.a->playing);
    CHECK(rig.world.get<Transform>(rig.hero)->position.x == doctest::Approx(10.0f));  // holds the last pose
}

TEST_CASE("animator 2D clips: a clip's own loop:false applies unless the Animator or a state decides") {
    TempProject p;
    p.write("anim/once.anim.json", clip(1, false, track("", "Transform", "position.x", R"([{"t":0,"value":0},{"t":1,"value":10}])")));
    Rig rig;
    rig.clips(R"({"once":"anim/once.anim.json"})");
    rig.a->clip = "once";
    for (int i = 0; i < 6; ++i) rig.step(0.25f);
    CHECK(rig.world.get<Transform>(rig.hero)->position.x == doctest::Approx(10.0f));
    // a state that says loop: true wins over the file
    Rig loopy;
    loopy.clips(R"({"once":"anim/once.anim.json"})");
    loopy.a->states = Json::parse(R"({"go":{"clip":"once","loop":true}})");
    for (int i = 0; i < 5; ++i) loopy.step(0.25f);
    CHECK(loopy.world.get<Transform>(loopy.hero)->position.x == doctest::Approx(2.5f));
}

TEST_CASE("animator 2D clips: a cross-fade lerps the values, takes the short way round an angle and switches steps halfway") {
    TempProject p;
    p.write("anim/a.anim.json", clip(1, true,
                                     track("body", "Transform", "rotation.z", R"([{"t":0,"value":350}])") + "," +
                                         track("body", "Transform", "position.x", R"([{"t":0,"value":0}])") + "," +
                                         track("body", "Sprite", "flipX", R"([{"t":0,"value":false}])")));
    p.write("anim/b.anim.json", clip(1, true,
                                     track("body", "Transform", "rotation.z", R"([{"t":0,"value":10}])") + "," +
                                         track("body", "Transform", "position.x", R"([{"t":0,"value":100}])") + "," +
                                         track("body", "Sprite", "flipX", R"([{"t":0,"value":true}])")));
    Rig rig;
    rig.clips(R"({"a":"anim/a.anim.json","b":"anim/b.anim.json"})");
    rig.a->clip = "a";
    rig.step(0.1f);
    CHECK(rig.bodyT().rotation.z == doctest::Approx(350.0f));
    CHECK(animator_play(rig.world, rig.hero, "b", 1.0f).ok());
    rig.step(0.25f);
    CHECK(rig.bodyT().position.x == doctest::Approx(25.0f));
    CHECK(rig.bodyT().rotation.z == doctest::Approx(355.0f));   // 350 -> 370 the short way, not 350 -> 10 backwards
    CHECK_FALSE(rig.bodyS().flipX);
    rig.step(0.25f);
    CHECK(rig.bodyT().rotation.z == doctest::Approx(360.0f));
    CHECK(rig.bodyT().position.x == doctest::Approx(50.0f));
    CHECK(rig.bodyS().flipX);                                    // at half the fade
    rig.step(0.6f);                                              // the fade is over
    CHECK(rig.bodyT().position.x == doctest::Approx(100.0f));
    CHECK(std::remainder(rig.bodyT().rotation.z - 10.0f, 360.0f) == doctest::Approx(0.0f).epsilon(1e-3));
}

TEST_CASE("animator 2D clips: a field the current clip does not drive goes back to where it was") {
    TempProject p;
    p.write("anim/a.anim.json", clip(1, true, track("body", "Transform", "position.x", R"([{"t":0,"value":50}])")));
    p.write("anim/b.anim.json", clip(1, true, track("body", "Transform", "rotation.z", R"([{"t":0,"value":20}])")));
    Rig rig;
    rig.bodyT().position = {7, 8, 9};
    rig.clips(R"({"a":"anim/a.anim.json","b":"anim/b.anim.json"})");
    rig.a->clip = "a";
    rig.step(0.1f);
    CHECK(rig.bodyT().position.x == doctest::Approx(50.0f));
    CHECK(rig.bodyT().position.y == doctest::Approx(8.0f));  // only the channel the clip drives
    CHECK(animator_play(rig.world, rig.hero, "b", 0).ok());
    rig.step(0.1f);
    CHECK(rig.bodyT().position.x == doctest::Approx(7.0f));
    CHECK(rig.bodyT().rotation.z == doctest::Approx(20.0f));
    CHECK(animator_stop(rig.world, rig.hero).ok());
    CHECK(rig.bodyT().rotation.z == doctest::Approx(0.0f));
    CHECK(rig.bodyT().position.x == doctest::Approx(7.0f));
    rig.step(0.1f);
    CHECK(rig.bodyT().rotation.z == doctest::Approx(0.0f));    // stopped: nothing plays
    CHECK_FALSE(rig.a->playing);
}

// ----------------------------------------------------------------------------------------------------- layers --

TEST_CASE("animator 2D clips: a layer with a mask blends only the parts under it") {
    TempProject p;
    p.write("anim/base.anim.json", clip(1, true,
                                        track("body", "Transform", "position.x", R"([{"t":0,"value":10}])") + "," +
                                            track("body/arm", "Transform", "rotation.z", R"([{"t":0,"value":0}])")));
    p.write("anim/wave.anim.json", clip(1, true,
                                        track("body", "Transform", "position.x", R"([{"t":0,"value":100}])") + "," +
                                            track("body/arm", "Transform", "rotation.z", R"([{"t":0,"value":40}])") + "," +
                                            track("body/arm", "Sprite", "color.a", R"([{"t":0,"value":0.5}])")));
    Rig rig;
    rig.clips(R"({"base":"anim/base.anim.json","wave":"anim/wave.anim.json"})");
    rig.a->clip = "base";
    rig.a->layers = Json::parse(R"([{"name":"arms","clip":"wave","weight":0.5,"mask":["body/arm"]}])");
    rig.step(0.1f);
    CHECK(rig.bodyT().position.x == doctest::Approx(10.0f));    // outside the mask
    CHECK(rig.armT().rotation.z == doctest::Approx(20.0f));     // half way to the layer
    CHECK(rig.armS().color.a == doctest::Approx(1.0f * 0.5f + 0.5f * 0.5f));  // the base does not drive it: rest is 1
    CHECK(animator_set_layer_weight(rig.world, rig.hero, "arms", 1.0f).ok());
    rig.step(0.1f);
    CHECK(rig.armT().rotation.z == doctest::Approx(40.0f));
    CHECK(rig.a->layers[0]["weight"].get<float>() == doctest::Approx(1.0f));  // the weight is visible in the component
    CHECK(animator_set_layer_weight(rig.world, rig.hero, "arms", 0.0f).ok());
    rig.step(0.1f);
    CHECK(rig.armT().rotation.z == doctest::Approx(0.0f));
    CHECK(rig.armS().color.a == doctest::Approx(1.0f));
    auto bad = animator_set_layer_weight(rig.world, rig.hero, "arm", 1.0f);
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().to_string().find("arms") != std::string::npos);
}

TEST_CASE("animator 2D clips: an additive layer adds the change from its first pose") {
    TempProject p;
    p.write("anim/base.anim.json", clip(1, true, track("body", "Transform", "rotation.z", R"([{"t":0,"value":10}])")));
    p.write("anim/bob.anim.json", clip(1, true, track("body", "Transform", "rotation.z", R"([{"t":0,"value":100},{"t":1,"value":130}])") + "," +
                                                    track("body", "Sprite", "flipX", R"([{"t":0,"value":true}])")));
    Rig rig;
    rig.clips(R"({"base":"anim/base.anim.json","bob":"anim/bob.anim.json"})");
    rig.a->clip = "base";
    rig.a->layers = Json::parse(R"([{"name":"bob","clip":"bob","mode":"additive","weight":1}])");
    rig.step(0.5f);
    CHECK(rig.bodyT().rotation.z == doctest::Approx(10.0f + 15.0f));  // 100 -> 115 is +15, not +115
    CHECK_FALSE(rig.bodyS().flipX);                                    // a field that only steps is not added
    CHECK(animator_set_layer_weight(rig.world, rig.hero, "bob", 0.5f).ok());
    rig.step(0.0f + 0.25f);
    CHECK(rig.bodyT().rotation.z == doctest::Approx(10.0f + 0.5f * 22.5f));
}

TEST_CASE("animator 2D clips: a layer plays and fades a clip of its own, and a layer at weight 0 is not playing") {
    TempProject p;
    p.write("anim/hold.anim.json", clip(2, true, track("body/arm", "Transform", "rotation.z", R"([{"t":0,"value":0},{"t":2,"value":20}])"),
                                        R"([{"t":0.5,"name":"layer.mark"}])"));
    p.write("anim/point.anim.json", clip(2, true, track("body/arm", "Transform", "rotation.z", R"([{"t":0,"value":90}])")));
    Rig rig;
    rig.clips(R"({"hold":"anim/hold.anim.json","point":"anim/point.anim.json"})");
    rig.a->layers = Json::parse(R"([{"name":"arm","clip":"hold","weight":0}])");
    for (int i = 0; i < 4; ++i) CHECK(count(rig.step(0.25f), "layer.mark") == 0);  // weight 0: nothing plays
    CHECK(rig.armT().rotation.z == doctest::Approx(0.0f));
    CHECK(animator_set_layer_weight(rig.world, rig.hero, "arm", 1.0f).ok());
    int marks = 0;
    for (int i = 0; i < 3; ++i) marks += count(rig.step(0.25f), "layer.mark");   // starts from its first pose
    CHECK(marks == 1);
    CHECK(rig.armT().rotation.z == doctest::Approx(0.75f * 10.0f));
    CHECK(animator_play_layer(rig.world, rig.hero, "arm", "point", 1.0f).ok());
    rig.step(0.5f);
    CHECK(rig.armT().rotation.z == doctest::Approx(51.25f));  // half way between the old clip (12.5 at t=1.25) and 90
    CHECK(rig.a->layers[0]["clip"] == "point");
    auto none = animator_play_layer(rig.world, rig.hero, "nope", "point", 0);
    REQUIRE_FALSE(none.ok());
    CHECK(none.error().to_string().find("arm") != std::string::npos);
}

// ---------------------------------------------------------------------------------------------- state machine --

TEST_CASE("animator 2D clips: the state machine runs on file clips") {
    TempProject p;
    p.write("anim/idle.anim.json", clip(1, true, track("body", "Transform", "position.x", R"([{"t":0,"value":1}])")));
    p.write("anim/run.anim.json", clip(1, true, track("body", "Transform", "position.x", R"([{"t":0,"value":5}])")));
    p.write("anim/hit.anim.json", clip(0.5f, false, track("body", "Transform", "position.x", R"([{"t":0,"value":9}])")));
    Rig rig;
    rig.clips(R"({"idle":"anim/idle.anim.json","run":"anim/run.anim.json","hit":"anim/hit.anim.json"})");
    rig.a->params = Json::parse(R"({"speed":0})");
    rig.a->states = Json::parse(R"({"idle":{"clip":"idle","onEnter":"state.idle"},"run":{"clip":"run","speed":2},"hit":{"clip":"hit"}})");
    rig.a->transitions = Json::parse(R"([
        {"from":"*","to":"hit","when":"hit","fade":0},
        {"from":"hit","to":"idle","onFinish":true,"fade":0},
        {"from":"idle","to":"run","when":"speed > 0.1","fade":0},
        {"from":"run","to":"idle","when":"speed <= 0.1","fade":0}])");
    auto n = rig.step(0.1f);
    CHECK(count(n, "state.idle") == 1);
    CHECK(rig.a->state == "idle");
    CHECK(rig.bodyT().position.x == doctest::Approx(1.0f));
    CHECK(animator_set(rig.world, rig.hero, "speed", 3).ok());
    rig.step(0.1f);
    CHECK(rig.a->state == "run");
    CHECK(rig.bodyT().position.x == doctest::Approx(5.0f));
    CHECK(rig.a->speed == doctest::Approx(2.0f));
    CHECK(animator_trigger(rig.world, rig.hero, "hit").ok());
    rig.step(0.25f);
    CHECK(rig.a->state == "hit");
    CHECK(rig.bodyT().position.x == doctest::Approx(9.0f));
    int finished = 0;
    for (int i = 0; i < 4; ++i) finished += count(rig.step(0.25f), "anim.finished");
    CHECK(finished == 1);
    CHECK(rig.a->state != "hit");  // onFinish went back
}

TEST_CASE("animator 2D clips: a layer can run its own states from the shared parameters") {
    TempProject p;
    p.write("anim/lo.anim.json", clip(1, true, track("body", "Transform", "position.y", R"([{"t":0,"value":1}])")));
    p.write("anim/hi.anim.json", clip(1, true, track("body", "Transform", "position.y", R"([{"t":0,"value":8}])")));
    Rig rig;
    rig.clips(R"({"lo":"anim/lo.anim.json","hi":"anim/hi.anim.json"})");
    rig.a->params = Json::parse(R"({"up":false})");
    rig.a->layers = Json::parse(R"([{"name":"y","states":{"lo":{"clip":"lo"},"hi":{"clip":"hi"}},
        "transitions":[{"from":"lo","to":"hi","when":"up","fade":0},{"from":"hi","to":"lo","when":"!up","fade":0}]}])");
    rig.step(0.1f);
    CHECK(rig.bodyT().position.y == doctest::Approx(1.0f));
    CHECK(animator_set(rig.world, rig.hero, "up", true).ok());
    rig.step(0.1f);
    CHECK(rig.bodyT().position.y == doctest::Approx(8.0f));
    CHECK(animator_play_layer(rig.world, rig.hero, "y", "lo", 0).error().message.find("states") != std::string::npos);
}

// ---------------------------------------------------------------------------------------------------- the rest --

TEST_CASE("animator 2D clips: sample() poses without playing") {
    TempProject p;
    p.write("anim/walk.anim.json", clip(1, true, track("body", "Transform", "rotation.z", R"([{"t":0,"value":0},{"t":1,"value":90}])")));
    Rig rig;
    rig.clips(R"({"walk":"anim/walk.anim.json"})");
    CHECK(animator_sample(rig.world, rig.hero, "walk", 0.5f).ok());
    CHECK(rig.bodyT().rotation.z == doctest::Approx(45.0f));
    CHECK_FALSE(rig.a->playing);
    for (int i = 0; i < 3; ++i) rig.step(0.25f);
    CHECK(rig.bodyT().rotation.z == doctest::Approx(45.0f));    // it stays posed
    CHECK(animator_sample(rig.world, rig.hero, "walk", 9.0f).ok());
    CHECK(rig.bodyT().rotation.z == doctest::Approx(90.0f));    // clamped to the clip
    CHECK_FALSE(animator_sample(rig.world, rig.hero, "wlk", 0.0f).ok());
    // a glTF animator has no 2D clips
    World w;
    Entity e = w.create("m", "m");
    w.add<Animator>(e);
    auto r = animator_sample(w, e, "walk", 0);
    REQUIRE_FALSE(r.ok());
}

TEST_CASE("animator 2D clips: the pose is a runtime state, scene.save and prefabs write where the fields rested") {
    TempProject p;
    p.write("anim/walk.anim.json", clip(1, true,
                                        track("body", "Transform", "rotation.z", R"([{"t":0,"value":30},{"t":1,"value":90}])") + "," +
                                            track("body/arm", "Sprite", "color", R"([{"t":0,"value":[1,0,0,1]}])") + "," +
                                            track("body/arm", "Sprite", "flipX", R"([{"t":0,"value":true}])")));
    Rig rig;
    rig.bodyT().rotation = {0, 0, 5};
    rig.armS().color = Color(0.2f, 0.4f, 0.6f, 1.0f);
    rig.clips(R"({"walk":"anim/walk.anim.json"})");
    rig.a->clip = "walk";
    rig.step(0.5f);
    CHECK(rig.bodyT().rotation.z == doctest::Approx(60.0f));
    CHECK(rig.armS().flipX);
    for (const Json& scene : {save_scene(rig.world), make_prefab(rig.world, rig.hero)}) {
        const Json& hero = scene.contains("entities") ? scene["entities"][0] : scene["entity"];
        const Json& body = hero["children"][0];
        CHECK(body["components"]["Transform"]["rotation"][2].get<float>() == doctest::Approx(5.0f));
        const Json& arm = body["children"][0];
        CHECK(arm["components"]["Sprite"]["color"][0].get<float>() == doctest::Approx(0.2f));
        CHECK_FALSE(arm["components"]["Sprite"].contains("flipX"));  // its rest is the default
    }
    // the live entity still shows the pose, and the Animator keeps playing
    CHECK(rig.bodyT().rotation.z == doctest::Approx(60.0f));
    // a field that no clip drives is written as it is
    rig.bodyT().position.x = 3.0f;
    CHECK(save_scene(rig.world)["entities"][0]["children"][0]["components"]["Transform"]["position"][0].get<float>() == doctest::Approx(3.0f));
    // entity.get style output (no PoseRest) shows what the field holds now
    CHECK(entity_to_json(rig.world, rig.body)["components"]["Transform"]["rotation"][2].get<float>() == doctest::Approx(60.0f));
    // copying an Animator copies its settings, not the pose bookkeeping of the original tree
    Animator copy = *rig.a;
    CHECK(copy.rt.clip.get() == nullptr);
    CHECK(copy.clips == rig.a->clips);
}

TEST_CASE("animator 2D clips: a clip file that changes on disk is played from the next poll") {
    TempProject p;
    const std::string v1 = clip(1, true, track("body", "Transform", "position.x", R"([{"t":0,"value":10}])"));
    p.write("anim/c.anim.json", v1);
    Rig rig;
    rig.clips(R"({"c":"anim/c.anim.json"})");
    rig.a->clip = "c";
    rig.step(0.1f);
    CHECK(rig.bodyT().position.x == doctest::Approx(10.0f));
    // a longer file, with a second track
    p.write("anim/c.anim.json", clip(2, true,
                                     track("body", "Transform", "position.x", R"([{"t":0,"value":20}])") + "," +
                                         track("body", "Transform", "position.y", R"([{"t":0,"value":30}])")));
    for (int i = 0; i < 20; ++i) rig.step(0.01f);
    CHECK(rig.bodyT().position.x == doctest::Approx(20.0f));
    CHECK(rig.bodyT().position.y == doctest::Approx(30.0f));
    // a broken file keeps the last good clip and warns instead of stopping the game
    p.write("anim/c.anim.json", "{ broken");
    for (int i = 0; i < 20; ++i) rig.step(0.01f);
    CHECK(rig.bodyT().position.x == doctest::Approx(20.0f));
    // and a track that is dropped hands its field back
    p.write("anim/c.anim.json", clip(3, true, track("body", "Transform", "position.x", R"([{"t":0,"value":21}])")));
    for (int i = 0; i < 20; ++i) rig.step(0.01f);
    CHECK(rig.bodyT().position.x == doctest::Approx(21.0f));
    CHECK(rig.bodyT().position.y == doctest::Approx(0.0f));
}

TEST_CASE("animator 2D clips: parts that appear later are found, and parts that go away do not crash") {
    TempProject p;
    p.write("anim/c.anim.json", clip(1, true, track("body/hand", "Transform", "position.x", R"([{"t":0,"value":10}])")));
    Rig rig;
    rig.clips(R"({"c":"anim/c.anim.json"})");
    rig.a->clip = "c";
    rig.step(0.1f);                                   // no 'hand' yet: a warning, nothing else
    Entity hand = rig.world.create("hand", "hand");
    rig.world.set_parent(hand, rig.body);
    for (int i = 0; i < 20; ++i) rig.step(0.01f);
    CHECK(rig.world.get<Transform>(hand)->position.x == doctest::Approx(10.0f));
    rig.world.destroy(hand);
    rig.world.flush();
    for (int i = 0; i < 20; ++i) rig.step(0.01f);
}

TEST_CASE("animator 2D clips: the same steps give the same poses and events") {
    TempProject p;
    p.write("anim/a.anim.json", clip(1.3f, true,
                                     track("body", "Transform", "rotation.z", R"([{"t":0,"value":0,"interp":"bezier"},{"t":0.7,"value":80,"interp":"backOut"},{"t":1.3,"value":10}])") + "," +
                                         track("body/arm", "Sprite", "color", R"([{"t":0,"value":[1,0,0,1],"interp":"quadInOut"},{"t":1,"value":[0,1,0,1]}])"),
                                     R"([{"t":0.4,"name":"e1"},{"t":1.3,"name":"e2"}])"));
    p.write("anim/b.anim.json", clip(0.8f, true, track("body", "Transform", "rotation.z", R"([{"t":0,"value":300},{"t":0.8,"value":20}])")));
    auto run = [&] {
        Rig rig;
        rig.clips(R"({"a":"anim/a.anim.json","b":"anim/b.anim.json"})");
        rig.a->clip = "a";
        rig.a->layers = Json::parse(R"([{"name":"l","clip":"b","weight":0.4,"mask":["body"]}])");
        std::vector<float> trace;
        std::vector<std::string> events;
        for (int i = 0; i < 90; ++i) {
            if (i == 30) (void)animator_play(rig.world, rig.hero, "b", 0.3f);
            if (i == 60) (void)animator_play(rig.world, rig.hero, "a", 0.0f);
            for (const std::string& n : rig.step(1.0f / 60.0f)) events.push_back(n + "@" + std::to_string(i));
            trace.push_back(rig.bodyT().rotation.z);
            trace.push_back(rig.armS().color.g);
        }
        return std::pair{trace, events};
    };
    const auto first = run(), second = run();
    CHECK(first.first == second.first);
    CHECK(first.second == second.second);
    CHECK(first.second.size() >= 2);
}

TEST_CASE("schemas/anim.schema.json lists what the loader accepts") {
    std::ifstream f(std::string(FA_REPO_ROOT) + "/schemas/anim.schema.json", std::ios::binary);
    std::stringstream ss;
    ss << f.rdbuf();
    const Json schema = Json::parse(ss.str());
    CHECK(schema["properties"]["format"]["const"] == "factoria.anim/1");
    std::set<std::string> top;
    for (auto& [k, v] : schema["properties"].items()) top.insert(k);
    CHECK(top == std::set<std::string>{"$schema", "format", "doc", "duration", "loop", "tracks", "events"});
    // the easing names of the schema are the ones tween() and the loader know
    std::set<std::string> eases;
    for (const Json& n : schema["$defs"]["key"]["properties"]["interp"]["anyOf"][1]["enum"]) eases.insert(n.get<std::string>());
    std::set<std::string> known(clip_ease_names().begin() + 1, clip_ease_names().end());
    CHECK(eases == known);
    std::set<std::string> keys;
    for (auto& [k, v] : schema["$defs"]["key"]["properties"].items()) keys.insert(k);
    CHECK(keys == std::set<std::string>{"t", "value", "interp", "in", "out"});
    std::set<std::string> tracks;
    for (auto& [k, v] : schema["$defs"]["track"]["properties"].items()) tracks.insert(k);
    CHECK(tracks == std::set<std::string>{"path", "component", "field", "keys"});
    std::set<std::string> events;
    for (auto& [k, v] : schema["$defs"]["event"]["properties"].items()) events.insert(k);
    CHECK(events == std::set<std::string>{"t", "name", "data"});
}
