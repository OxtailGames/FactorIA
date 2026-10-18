#include <doctest.h>

#include <cmath>
#include <cstring>
#include <string>

#include "fa/core/fs.h"
#include "fa/scene/animation.h"
#include "fa/scene/serialize.h"
#include "fa_test_paths.h"

using namespace fa;

namespace {

// engine/render/tests/data/skinned_two_bone.gltf: bones Root (node 1, joint 0) and Tip (node 2, joint 1, at y = 1).
// Clips: Bend (Tip rotates 0 -> 90 deg about Z over 1 s, LINEAR), Slide (Root x = 0, 1, 2 at t = 0, .5, 1; STEP),
// Spline (Tip y 1 -> 2 with an out tangent (1,0,0), CUBICSPLINE).
const char* kModel = "engine/render/tests/data/skinned_two_bone.gltf";

struct Fixture {
    Fixture() {
        old = fs::project_root();
        fs::set_project_root(FA_REPO_ROOT);
        ensure_builtin_components();
    }
    ~Fixture() { fs::set_project_root(old); }
    std::filesystem::path old;
};

std::shared_ptr<const SkeletonAsset> model() {
    auto r = load_skeleton(kModel);
    const std::string err = r.ok() ? std::string() : r.error().to_string();
    INFO(err);
    REQUIRE(r.ok());
    return *r;
}

bool near(Vec3 a, Vec3 b, float eps = 1e-4f) { return length(a - b) < eps; }

// Where the palette of joint `j` sends the bind-pose point `p`.
Vec3 skinned(const std::vector<Mat4>& palette, int j, Vec3 p) { return palette.at(std::size_t(j)).transform_point(p); }

std::vector<Mat4> palette_of(const SkeletonAsset& sk, const char* clip, float time) {
    Pose pose = rest_pose(sk);
    sample_clip(sk, sk.clips[std::size_t(sk.find_clip(clip))], time, pose);
    return skin_palette(sk, pose, 0);
}

struct Scene {
    World world;
    Entity e;
    Animator* a;
    explicit Scene(Json fields = Json::object()) {
        e = world.create("hero", "hero");
        world.add<MeshRenderer>(e).mesh = kModel;
        a = &world.add<Animator>(e);
        auto r = object_patch_from_json(*TypeRegistry::global().find("Animator"), a, fields);
        const std::string err = r.ok() ? std::string() : r.error().to_string();
    INFO(err);
    REQUIRE(r.ok());
    }
    // One fixed step; returns the names of the events it produced, in order.
    std::vector<std::string> step(float dt = 0.25f) {
        update_animators(world, dt);
        std::vector<std::string> names;
        for (const GameEvent& g : world.events().game) names.push_back(g.name);
        world.events().game.clear();
        return names;
    }
};

int count(const std::vector<std::string>& v, const std::string& name) {
    int n = 0;
    for (const auto& s : v) n += s == name;
    return n;
}

}  // namespace

TEST_CASE("skeleton: nodes, skin, clips and vertex weights of the two-bone sample") {
    Fixture fx;
    auto sk = model();
    REQUIRE(sk->nodes.size() == 3);
    CHECK(sk->nodes[2].parent == 1);
    CHECK(near(sk->nodes[2].translation, {0, 1, 0}));
    CHECK(sk->order.size() == 3);
    REQUIRE(sk->skins.size() == 1);
    CHECK(sk->skins[0].joints == std::vector<int>{1, 2});
    CHECK(near(sk->skins[0].inverseBind[1].translation(), {0, -1, 0}));
    REQUIRE(sk->clips.size() == 3);
    CHECK(sk->find_clip("Bend") == 0);
    CHECK(sk->find_clip("Nope") == -1);
    CHECK(sk->clips[0].duration == doctest::Approx(1.0f));
    REQUIRE(sk->skinVertices.size() == 1);
    const SkinVertices& sv = sk->skinVertices[0];
    CHECK(sv.node == 0);
    REQUIRE(sv.joints.size() == 12);
    CHECK(sv.joints[0][0] == 0);
    CHECK(sv.weights[0][0] == doctest::Approx(1.0f));
    CHECK(sv.joints[4][1] == 1);                              // middle ring: half Root, half Tip
    CHECK(sv.weights[4][0] == doctest::Approx(0.5f));
    CHECK(sv.weights[4][1] == doctest::Approx(0.5f));
    CHECK(sv.joints[8][0] == 1);
    for (const auto& w : sv.weights) CHECK(w[0] + w[1] + w[2] + w[3] == doctest::Approx(1.0f));
}

TEST_CASE("skeleton: a missing file and a missing clip teach") {
    Fixture fx;
    CHECK_FALSE(load_skeleton("engine/render/tests/data/nope.gltf").ok());
    World w;
    Entity e = w.create("x", "x");
    w.add<MeshRenderer>(e).mesh = kModel;
    w.add<Animator>(e);
    auto r = animator_play(w, e, "Bnd", 0);
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().to_string().find("Bend") != std::string::npos);  // did you mean
}

TEST_CASE("sampling: the bind pose is the identity palette") {
    Fixture fx;
    auto sk = model();
    for (const Mat4& m : skin_palette(*sk, rest_pose(*sk), 0)) CHECK(near(m.transform_point({0.3f, 1.2f, -0.1f}), {0.3f, 1.2f, -0.1f}));
}

TEST_CASE("sampling: LINEAR rotation halfway bends the tip 45 degrees") {
    Fixture fx;
    auto sk = model();
    const auto p = palette_of(*sk, "Bend", 0.5f);
    const float s = std::sqrt(0.5f);
    CHECK(near(skinned(p, 1, {0, 2, 0}), {-s, 1.0f + s, 0}));  // hand-computed: T(0,1,0) Rz(45) T(0,-1,0) (0,2,0)
    CHECK(near(skinned(p, 0, {0, 2, 0}), {0, 2, 0}));          // Root does not move
    CHECK(near(skinned(palette_of(*sk, "Bend", 1.0f), 1, {0, 2, 0}), {-1, 1, 0}));
    CHECK(near(skinned(palette_of(*sk, "Bend", 9.0f), 1, {0, 2, 0}), {-1, 1, 0}));  // clamped past the end
}

TEST_CASE("sampling: STEP holds the key until the next one") {
    Fixture fx;
    auto sk = model();
    CHECK(near(skinned(palette_of(*sk, "Slide", 0.49f), 0, {0, 0, 0}), {0, 0, 0}));
    CHECK(near(skinned(palette_of(*sk, "Slide", 0.5f), 0, {0, 0, 0}), {1, 0, 0}));
    CHECK(near(skinned(palette_of(*sk, "Slide", 0.99f), 0, {0, 0, 0}), {1, 0, 0}));
    CHECK(near(skinned(palette_of(*sk, "Slide", 1.0f), 0, {0, 0, 0}), {2, 0, 0}));
}

TEST_CASE("sampling: CUBICSPLINE uses the Hermite basis with the tangents") {
    Fixture fx;
    auto sk = model();
    // Tip translation: (0,1,0) -> (0,2,0), out tangent of key 0 = (1,0,0), in tangent of key 1 = 0; at t = .5 the Hermite
    // weights are h00 = .5, h10 = .125, h01 = .5, h11 = -.125, so it is (.125, 1.5, 0). palette[1] = T(that) T(0,-1,0).
    CHECK(near(skinned(palette_of(*sk, "Spline", 0.5f), 1, {0, 0, 0}), {0.125f, 0.5f, 0}));
    CHECK(near(skinned(palette_of(*sk, "Spline", 0.0f), 1, {0, 0, 0}), {0, 0, 0}));
    CHECK(near(skinned(palette_of(*sk, "Spline", 1.0f), 1, {0, 0, 0}), {0, 1, 0}));
}

TEST_CASE("animator: plays a clip in the fixed step and writes the palette") {
    Fixture fx;
    Scene s(Json::parse(R"({"clip": "Bend"})"));
    s.step();
    CHECK(s.a->time == doctest::Approx(0.25f));
    REQUIRE(s.a->palette.size() == 2);
    s.step();
    CHECK(s.a->time == doctest::Approx(0.5f));
    const float c = std::sqrt(0.5f);
    CHECK(near(skinned(s.a->palette, 1, {0, 2, 0}), {-c, 1.0f + c, 0}));
    s.a->playing = false;
    s.step();
    CHECK(s.a->time == doctest::Approx(0.5f));  // paused
    s.a->playing = true;
    s.a->speed = 2.0f;
    s.step();
    CHECK(s.a->time == doctest::Approx(0.0f));  // 0.5 + 0.25 * 2 = 1.0, wrapped
}

TEST_CASE("animator: cross-fade blends the outgoing and incoming clip") {
    Fixture fx;
    Scene s(Json::parse(R"({"clip": "Bend"})"));
    s.step();                                              // Bend at 0.25
    REQUIRE(animator_play(s.world, s.e, "Slide", 1.0f).ok());
    s.step(0.5f);                                          // Slide at 0.5 (Root x = 1); Bend carried on to 0.75; fade at halfway
    const float bendDeg = 0.75f * 90.0f;
    const float half = radians(bendDeg) * 0.5f;            // slerp(Rz(67.5), identity, .5) = Rz(33.75)
    const float a = half;                                  // angle of the blended rotation
    const Vec3 tipFromJoint = {-std::sin(a), std::cos(a), 0};  // (0,1,0) turned by Rz(33.75)
    CHECK(near(skinned(s.a->palette, 1, {0, 2, 0}), Vec3{0.5f, 1.0f, 0} + tipFromJoint));
    s.step(0.5f);                                          // fade over: pure Slide
    CHECK(s.a->clip == "Slide");
    CHECK(near(skinned(s.a->palette, 1, {0, 2, 0}), {0, 2, 0}));  // Slide wrapped from 1.0 to 0.0: Root back at x = 0
}

TEST_CASE("animator: setting `clip` switches with the fade field") {
    Fixture fx;
    Scene s(Json::parse(R"({"clip": "Bend", "fade": 0.5})"));
    s.step();
    s.a->clip = "Slide";
    s.step();
    CHECK(s.a->rt.activeClip == "Slide");
    CHECK(s.a->rt.fromIndex >= 0);
    CHECK(s.a->rt.fadeElapsed == doctest::Approx(0.25f));
    s.step();
    s.step();
    CHECK(s.a->rt.fromIndex == -1);
}

TEST_CASE("animator: clip events fire exactly once per loop, in the step that passes them") {
    Fixture fx;
    Scene s(Json::parse(R"({"clip": "Bend", "events": [{"clip": "Bend", "time": 0.5, "name": "half"},
                                                      {"clip": "Bend", "time": 0, "name": "start"},
                                                      {"clip": "Slide", "time": 0.25, "name": "other"}]})"));
    std::vector<int> half, start;
    int other = 0;
    for (int i = 1; i <= 12; ++i) {
        const auto ev = s.step();
        if (count(ev, "half")) half.push_back(i);
        if (count(ev, "start")) start.push_back(i);
        other += count(ev, "other");
    }
    CHECK(half == std::vector<int>{2, 6, 10});          // t = .5, 1.5, 2.5
    CHECK(start == std::vector<int>{1, 4, 8, 12});      // t = 0 (first step), 1, 2, 3
    CHECK(other == 0);                                  // another clip's events never fire
}

TEST_CASE("animator: event data names the clip and the entity") {
    Fixture fx;
    Scene s(Json::parse(R"({"clip": "Bend", "events": [{"clip": "Bend", "time": 0.25, "name": "tap"}]})"));
    s.world.events().game.clear();
    update_animators(s.world, 0.25f);
    REQUIRE(s.world.events().game.size() == 1);
    const GameEvent& g = s.world.events().game[0];
    CHECK(g.name == "tap");
    CHECK(g.source == s.e);
    CHECK(g.data["id"] == "hero");
    CHECK(g.data["clip"] == "Bend");
}

TEST_CASE("animator: a non-looping clip stops on its last pose and sends anim.finished once") {
    Fixture fx;
    Scene s(Json::parse(R"({"clip": "Bend", "loop": false})"));
    int finished = 0;
    for (int i = 0; i < 8; ++i) finished += count(s.step(), "anim.finished");
    CHECK(finished == 1);
    CHECK_FALSE(s.a->playing);
    CHECK(s.a->time == doctest::Approx(1.0f));
    CHECK(near(skinned(s.a->palette, 1, {0, 2, 0}), {-1, 1, 0}));
}

TEST_CASE("animator: a seek does not fire the events it jumps over") {
    Fixture fx;
    Scene s(Json::parse(R"({"clip": "Bend", "events": [{"clip": "Bend", "time": 0.5, "name": "half"}]})"));
    s.step();
    s.a->time = 0.75f;
    CHECK(count(s.step(0.0625f), "half") == 0);
    CHECK(s.a->time == doctest::Approx(0.8125f));
}

TEST_CASE("state machine: parameters drive transitions, with onEnter events, triggers and onFinish") {
    Fixture fx;
    Scene s(Json::parse(R"({
      "params": {"speed": 0, "grounded": true},
      "states": {"idle": {"clip": "Slide", "onEnter": "in_idle"},
                 "run": {"clip": "Bend", "onEnter": "in_run"},
                 "hit": {"clip": "Spline", "loop": false}},
      "transitions": [
        {"from": "idle", "to": "run", "when": "speed > 0.1 && grounded", "fade": 0.5},
        {"from": "run", "to": "idle", "when": "speed <= 0.1"},
        {"to": "hit", "when": "hurt"},
        {"from": "hit", "to": "idle", "onFinish": true}
      ]})"));
    auto ev = s.step();
    CHECK(s.a->state == "idle");
    CHECK(s.a->clip == "Slide");
    CHECK(count(ev, "in_idle") == 1);
    CHECK(s.step().empty());                       // nothing changes without input
    REQUIRE(animator_set(s.world, s.e, "speed", 3).ok());
    ev = s.step();
    CHECK(s.a->state == "run");
    CHECK(s.a->clip == "Bend");
    CHECK(count(ev, "in_run") == 1);
    CHECK(s.a->rt.fadeDuration == doctest::Approx(0.5f));
    REQUIRE(animator_set(s.world, s.e, "grounded", false).ok());
    REQUIRE(animator_trigger(s.world, s.e, "hurt").ok());
    s.step();
    CHECK(s.a->state == "hit");
    CHECK_FALSE(s.a->loop);
    s.step(); s.step(); s.step();                  // Spline lasts 1 s (0.25 played): finished after three more steps
    CHECK_FALSE(s.a->playing);
    CHECK(s.a->state == "hit");
    s.step();                                      // the onFinish transition fires on the next step
    CHECK(s.a->state == "idle");                   // idle -> run needs grounded, which is false
}

TEST_CASE("state machine: errors name the declared parameters") {
    Fixture fx;
    Scene s(Json::parse(R"({"params": {"speed": 0}, "states": {"a": {"clip": "Bend"}}})"));
    s.step();
    auto r = animator_set(s.world, s.e, "spead", 1);
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().to_string().find("speed") != std::string::npos);
    CHECK_FALSE(animator_set(s.world, s.e, "speed", "fast").ok());
    CHECK(animator_set(s.world, s.e, "speed", 2).ok());
    CHECK(s.a->values["speed"] == 2);
}

TEST_CASE("animator: two identical runs give identical palettes and events") {
    Fixture fx;
    const char* cfg = R"({"clip": "Bend", "events": [{"clip": "Bend", "time": 0.3, "name": "e"}],
                           "params": {"v": 0}, "states": {"a": {"clip": "Bend"}, "b": {"clip": "Spline"}},
                           "transitions": [{"from": "a", "to": "b", "when": "v > 1", "fade": 0.4}]})";
    Scene a(Json::parse(cfg)), b(Json::parse(cfg));
    std::vector<std::string> evA, evB;
    for (int i = 0; i < 90; ++i) {
        if (i == 30) { CHECK(animator_set(a.world, a.e, "v", 2).ok()); CHECK(animator_set(b.world, b.e, "v", 2).ok()); }
        for (auto& n : a.step(1.0f / 60.0f)) evA.push_back(n);
        for (auto& n : b.step(1.0f / 60.0f)) evB.push_back(n);
        REQUIRE(a.a->palette.size() == b.a->palette.size());
        CHECK(std::memcmp(a.a->palette.data(), b.a->palette.data(), a.a->palette.size() * sizeof(Mat4)) == 0);
    }
    CHECK(evA == evB);
    CHECK(!evA.empty());
}

TEST_CASE("animator: scene JSON round trip keeps the configuration and drops the runtime data") {
    Fixture fx;
    Scene s(Json::parse(R"({"clip": "Bend", "speed": 2, "params": {"x": 1}})"));
    s.step();
    const TypeInfo& t = *TypeRegistry::global().find("Animator");
    Json j = object_to_json(t, s.a, false, false);
    CHECK(j["clip"] == "Bend");
    CHECK(j["speed"] == 2);
    CHECK_FALSE(j.contains("time"));
    CHECK_FALSE(j.contains("values"));
}
