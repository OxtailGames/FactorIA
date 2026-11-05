// fa/scene/feel.h: the effects as data and clocks, without an engine around them.
#include <doctest.h>

#include <cmath>

#include "fa/scene/feel.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {

struct Fixture {
    World w;
    Entity cam, box;
    Fixture() {
        ensure_builtin_components();
        cam = w.create("cam", "cam");
        w.add<Camera>(cam).orthoSize = 90.0f;
        box = w.create("box", "box");
        w.get<Transform>(box)->position = {3, 4, 0};
        w.get<Transform>(box)->scale = {2, 3, 1};
        w.add<Sprite>(box);
    }
    // One step of the clocks as the engine runs them at 60 Hz.
    void frame(double dt = 1.0 / 60.0) {
        feel_begin_frame(w, dt, false);
        feel_fixed_update(w, dt * (w.feel().hit_stop_factor()));
        feel_update(w, dt);
    }
};

}  // namespace

TEST_CASE("feel noise: a pure function, smooth, within [-1, 1], different per seed and channel") {
    for (double x = -3.0; x < 3.0; x += 0.37) {
        const float v = feel_noise(7, 0, x);
        CHECK(v == feel_noise(7, 0, x));
        CHECK(std::fabs(v) <= 1.0f);
        CHECK(std::fabs(feel_noise(7, 0, x + 0.01) - v) < 0.1f);  // continuous
    }
    int differ = 0;
    for (double x = 0; x < 5; x += 0.5) differ += feel_noise(1, 0, x) != feel_noise(2, 0, x) ? 1 : 0;
    CHECK(differ > 5);
    CHECK(feel_noise(1, 0, 2.5) != feel_noise(1, 1, 2.5));
}

TEST_CASE("shake: the same RNG state shakes the same, the RNG is not consumed, trauma decays to nothing") {
    auto run = [](std::uint64_t seed) {
        Fixture f;
        f.w.rng().reseed(seed);
        const auto before = f.w.rng().state();
        REQUIRE(feel_shake(f.w, f.cam, {0.9f, 0.5f}).ok());
        CHECK(f.w.rng().state() == before);  // seeding the noise does not change the game's random numbers
        std::vector<float> xs;
        float lastTrauma = 2.0f;
        for (int i = 0; i < 40; ++i) {
            f.frame();
            const FeelEntity* r = f.w.feel().find(f.cam);
            if (!r) break;
            REQUIRE(r->shake);
            CHECK(r->shake->trauma < lastTrauma);  // it only goes down
            lastTrauma = r->shake->trauma;
            xs.push_back(r->pose.position.x);
        }
        CHECK(f.w.feel().find(f.cam) == nullptr);  // over: no record, no pose
        CHECK(f.w.feel().pose_of(f.cam) == nullptr);
        return xs;
    };
    const auto a = run(42), b = run(42), c = run(43);
    CHECK(a == b);
    CHECK(a != c);
    CHECK(a.size() >= 25);
}

TEST_CASE("shake: stacking adds trauma up to the cap, a longer shake is kept, the offset is trauma squared") {
    Fixture f;
    REQUIRE(feel_shake(f.w, f.cam, {0.5f, 0.4f}).ok());
    REQUIRE(feel_shake(f.w, f.cam, {0.5f, 1.0f, 25.0f, 0.0f, 2.0f, 0.8f}).ok());
    const FeelShake& s = *f.w.feel().find(f.cam)->shake;
    CHECK(s.trauma == doctest::Approx(0.8f));  // 1.0 would pass the cap
    CHECK(s.remaining == doctest::Approx(1.0f));
    CHECK(s.maxOffset == doctest::Approx(90.0f * 2.0f * 0.025f));  // the default of an orthographic camera
    f.frame();
    const FeelEntity* r = f.w.feel().find(f.cam);
    const float m = r->shake->trauma * r->shake->trauma;
    CHECK(std::fabs(r->pose.position.x) <= s.maxOffset * m + 1e-4f);
    CHECK(std::fabs(r->pose.rotation.z) <= 2.0f * m + 1e-4f);
    // Errors teach.
    auto bad = feel_shake(f.w, f.cam, {-1.0f});
    CHECK_FALSE(bad.ok());
}

TEST_CASE("pose: drawn_matrix is world_matrix without effects, adds the pose with them, and the Transform never changes") {
    Fixture f;
    CHECK(f.w.drawn_matrix(f.box).m[12] == f.w.world_matrix(f.box).m[12]);
    REQUIRE(feel_squash(f.w, f.box, {0.4f, 0.3f}).ok());
    f.frame();
    const Mat4 drawn = f.w.drawn_matrix(f.box);
    const Mat4 plain = f.w.world_matrix(f.box);
    CHECK(drawn.m[0] != plain.m[0]);
    const Transform* t = f.w.get<Transform>(f.box);
    CHECK(t->scale.x == 2.0f);
    CHECK(t->scale.y == 3.0f);
    for (int i = 0; i < 30; ++i) f.frame();
    CHECK(f.w.feel().find(f.box) == nullptr);
    CHECK(f.w.drawn_matrix(f.box).m[0] == plain.m[0]);  // exactly back
    CHECK(t->scale.x == 2.0f);
    CHECK(t->scale.y == 3.0f);
    CHECK(t->scale.z == 1.0f);
}

TEST_CASE("squash: x * y stays 1 all along the pulse, for both axes and with a negative amount") {
    for (char axis : {'x', 'y'})
        for (float amount : {0.5f, -0.4f}) {
            Fixture f;
            REQUIRE(feel_squash(f.w, f.box, {amount, 0.3f, axis}).ok());
            for (int i = 0; i < 18; ++i) {
                f.frame();
                const FeelPose* p = f.w.feel().pose_of(f.box);
                if (!p) continue;
                CHECK(p->scale.x * p->scale.y == doctest::Approx(1.0f).epsilon(1e-4));
            }
        }
}

TEST_CASE("hit-stop: the longest wins instead of adding up, runs in real time, and is shortened by reduce motion") {
    Fixture f;
    REQUIRE(feel_hit_stop(f.w, {0.1f}).ok());
    REQUIRE(feel_hit_stop(f.w, {0.2f}).ok());
    REQUIRE(feel_hit_stop(f.w, {0.05f}).ok());
    CHECK(f.w.feel().hit_stop_remaining() == doctest::Approx(0.2f));
    CHECK(f.w.feel().hit_stop_factor() == 0.0f);
    for (int i = 0; i < 6; ++i) f.frame();
    CHECK(f.w.feel().hit_stop_remaining() == doctest::Approx(0.1f).epsilon(0.02));
    for (int i = 0; i < 8; ++i) f.frame();
    CHECK(f.w.feel().hit_stop_remaining() == 0.0f);
    CHECK(f.w.feel().hit_stop_factor() == 1.0f);
    // Slow motion and freeze overlap: the strongest.
    REQUIRE(feel_hit_stop(f.w, {0.3f, 0.25f}).ok());
    CHECK(f.w.feel().hit_stop_factor() == 0.25f);
    REQUIRE(feel_hit_stop(f.w, {0.1f, 0.0f}).ok());
    CHECK(f.w.feel().hit_stop_factor() == 0.0f);
    f.w.feel().reduceMotionSetting = true;
    f.w.feel().hitStops.clear();
    REQUIRE(feel_hit_stop(f.w, {0.2f}).ok());
    CHECK(f.w.feel().hit_stop_remaining() == doctest::Approx(0.2f * kReduceMotionHitStop));
    CHECK_FALSE(feel_hit_stop(f.w, {0.0f}).ok());
    CHECK_FALSE(feel_hit_stop(f.w, {kMaxHitStopSeconds + 1}).ok());
}

TEST_CASE("flash: fades from its strength to nothing and is not left behind; reduced effects are faint and fade") {
    Fixture f;
    REQUIRE(feel_flash(f.w, f.box, {Color{1, 0, 0, 1}, 0.2f, false, 1.0f}).ok());
    f.frame();
    auto c = f.w.feel().flash_of(f.box);
    REQUIRE(c);
    CHECK(c->a == 1.0f);  // square: full for the whole duration
    CHECK(c->r == 1.0f);
    for (int i = 0; i < 20; ++i) f.frame();
    CHECK_FALSE(f.w.feel().flash_of(f.box));
    CHECK_FALSE(f.w.feel().any_flash());
    CHECK(f.w.get<Sprite>(f.box)->color.r == 1.0f);  // the sprite's own colour was never written

    REQUIRE(feel_flash(f.w, f.box, {Color{1, 1, 1, 1}, 0.2f, true, 1.0f}).ok());
    f.frame();
    f.frame();
    const float a1 = f.w.feel().flash_of(f.box)->a;
    f.frame();
    CHECK(f.w.feel().flash_of(f.box)->a < a1);  // fading

    f.w.feel().reducedEffectsSetting = true;
    REQUIRE(feel_flash(f.w, f.box, {Color{1, 1, 1, 1}, 0.2f, false, 1.0f}).ok());
    CHECK(f.w.feel().flash_of(f.box)->a <= kReducedEffectsFlash);
    f.frame();
    f.frame();
    const float b1 = f.w.feel().flash_of(f.box)->a;
    f.frame();
    CHECK(f.w.feel().flash_of(f.box)->a < b1);  // the square wave became a fade
}

TEST_CASE("reduce motion: shake and squash shrink to a quarter; the system value is followed until the game sets its own") {
    Fixture f;
    f.w.feel().systemReduceMotion = true;
    CHECK(f.w.feel().reduce_motion());
    CHECK(f.w.feel().reduced_effects());
    REQUIRE(feel_shake(f.w, f.cam, {0.8f}).ok());
    CHECK(f.w.feel().find(f.cam)->shake->trauma == doctest::Approx(0.8f * kReduceMotionShake));
    REQUIRE(feel_squash(f.w, f.box, {0.4f, 0.3f}).ok());
    CHECK(f.w.feel().find(f.box)->squash->amount == doctest::Approx(0.4f * kReduceMotionSquash));
    f.w.feel().reduceMotionSetting = false;  // the player says no, whatever the system says
    CHECK_FALSE(f.w.feel().reduce_motion());
    CHECK(f.w.feel().reduced_effects());  // the two switches are independent
    f.w.feel().reduceMotionSetting.reset();
    CHECK(f.w.feel().reduce_motion());
}

TEST_CASE("knockback: a body-less entity slides and slows, the lock follows lockTime, clear keeps the player's choices") {
    Fixture f;
    REQUIRE(feel_knockback(f.w, f.box, {{1, 0, 0}, 10.0f, 0.2f, 5.0f}).ok());
    CHECK(f.w.feel().knocked_back(f.box));
    float x = f.w.world_position(f.box).x;
    f.frame();
    const float step1 = f.w.world_position(f.box).x - x;
    CHECK(step1 == doctest::Approx(10.0f / 60.0f).epsilon(0.01));
    x = f.w.world_position(f.box).x;
    f.frame();
    CHECK(f.w.world_position(f.box).x - x < step1);  // decaying
    for (int i = 0; i < 20; ++i) f.frame();
    CHECK_FALSE(f.w.feel().knocked_back(f.box));
    CHECK_FALSE(feel_knockback(f.w, f.box, {{0, 0, 0}}).ok());

    f.w.feel().reduceMotionSetting = true;
    REQUIRE(feel_hit_stop(f.w, {0.1f}).ok());
    f.w.clear();
    CHECK(f.w.feel().hitStops.empty());
    CHECK(f.w.feel().reduceMotionSetting == std::optional<bool>(true));
}

TEST_CASE("feel_apply_action: data in, effects out, and the mistakes name the fix") {
    Fixture f;
    CHECK(feel_apply_action(f.w, f.box, Json::parse(R"({"action":"flash","color":"#ff0000","duration":0.1})")).ok());
    CHECK(feel_apply_action(f.w, f.box, Json::parse(R"({"action":"squash","amount":0.2,"axis":"x"})")).ok());
    CHECK(feel_apply_action(f.w, f.box, Json::parse(R"({"action":"knockback","direction":[1,0]})")).ok());
    CHECK(feel_apply_action(f.w, kNullEntity, Json::parse(R"({"action":"shake","amount":0.3})")).ok());  // the main camera
    CHECK(feel_apply_action(f.w, kNullEntity, Json::parse(R"({"action":"hitStop","duration":0.05})")).ok());

    auto r = feel_apply_action(f.w, f.box, Json::parse(R"({"action":"flsh"})"));
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("flash") != std::string::npos);  // did you mean
    r = feel_apply_action(f.w, f.box, Json::parse(R"({"action":"flash","duraton":0.1})"));
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("duration") != std::string::npos);
    r = feel_apply_action(f.w, f.box, Json::parse(R"({"action":"flash","duration":"long"})"));
    CHECK_FALSE(r.ok());
    r = feel_apply_action(f.w, f.box, Json::parse(R"({"action":"squash","axis":"z"})"));
    CHECK_FALSE(r.ok());
    r = feel_apply_action(f.w, f.box, Json::parse(R"({"amount":1})"));
    CHECK_FALSE(r.ok());
    // A dead target is refused, not crashed on.
    Entity gone = f.w.create("gone", "gone");
    f.w.destroy(gone);
    f.w.flush();
    CHECK_FALSE(feel_apply_action(f.w, gone, Json::parse(R"({"action":"flash"})")).ok());
}
