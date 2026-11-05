#include <doctest.h>

#include "fa/core/asset_manifest.h"
#include "fa/scene/components.h"
#include "fa/scene/feel.h"
#include "fa/scene/sprite_animator.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {
std::shared_ptr<const assets::Sheet> test_sheet() {
    return assets::parse_sheet(Json::parse(R"({"columns":4,"rows":2,"frameWidth":14,"frameHeight":14,"frames":7,"padding":1,"pivot":[0.5,1],
        "clips":[{"name":"spin","firstFrame":0,"lastFrame":3,"fps":10,"loop":true},
                 {"name":"pop","firstFrame":4,"lastFrame":6,"fps":10,"loop":false,"pivot":[0.25,0.75]}]})"));
}
// Steps by one fixed 1/60 s until `seconds` passed; collects the frames and whether the end was reported.
struct Run {
    std::vector<int> frames;
    int ends = 0;
};
Run play(SpriteAnimator& a, const SpriteAnimPlan& plan, int steps, float dt = 0.1f) {
    Run r;
    for (int i = 0; i < steps; ++i) {
        if (sprite_animator_step(a, plan, dt)) ++r.ends;
        r.frames.push_back(a.frame);
    }
    return r;
}
}  // namespace

TEST_CASE("sprite animator: a clip by name takes grid, frames, fps and loop from the sheet") {
    SpriteAnimator a;
    a.clip = "pop";
    const auto plan = resolve_sprite_animator(a, "assets/coin.png", test_sheet());
    CHECK(plan.error.empty());
    CHECK(plan.columns == 4);
    CHECK(plan.rows == 2);
    CHECK(plan.firstFrame == 4);
    CHECK(plan.lastFrame == 6);
    CHECK(plan.fps == doctest::Approx(10.0f));
    CHECK_FALSE(plan.loop);
    CHECK(plan.padding == 1);
}

TEST_CASE("sprite animator: numeric fields override the clip when they differ from their defaults") {
    SpriteAnimator a;
    a.clip = "spin";
    a.fps = 30;
    a.lastFrame = 2;
    a.loop = false;
    const auto plan = resolve_sprite_animator(a, "assets/coin.png", test_sheet());
    CHECK(plan.fps == doctest::Approx(30.0f));
    CHECK(plan.lastFrame == 2);
    CHECK(plan.firstFrame == 0);
    CHECK_FALSE(plan.loop);
    a.columns = 8;  // another grid than the sheet's: its gutter and pivot do not apply
    const auto other = resolve_sprite_animator(a, "assets/coin.png", test_sheet());
    CHECK(other.columns == 8);
    CHECK(other.padding == 0);
    CHECK_FALSE(other.pivot.has_value());
}

TEST_CASE("sprite animator: a wrong clip name lists the clips and suggests the closest") {
    SpriteAnimator a;
    a.clip = "spn";
    const auto plan = resolve_sprite_animator(a, "assets/coin.png", test_sheet());
    CHECK_FALSE(plan.error.empty());
    CHECK(plan.error.find("spin, pop") != std::string::npos);
    CHECK(plan.error.find("Did you mean") != std::string::npos);
    CHECK(plan.error.find("spin") != std::string::npos);
    a.clip = "spin";
    CHECK(resolve_sprite_animator(a, "assets/none.png", nullptr).error.find("no `sheet` entry") != std::string::npos);
}

TEST_CASE("sprite animator: forward, reverse and pingpong walk the frames") {
    SpriteAnimator a;
    a.clip = "spin";
    SpriteAnimPlan plan = resolve_sprite_animator(a, "t.png", test_sheet());
    CHECK(play(a, plan, 6).frames == std::vector<int>{1, 2, 3, 0, 1, 2});
    SpriteAnimator r;
    r.clip = "spin";
    r.mode = SpriteAnimMode::Reverse;
    plan = resolve_sprite_animator(r, "t.png", test_sheet());
    CHECK(play(r, plan, 5).frames == std::vector<int>{2, 1, 0, 3, 2});
    SpriteAnimator p;
    p.clip = "spin";
    p.mode = SpriteAnimMode::PingPong;
    plan = resolve_sprite_animator(p, "t.png", test_sheet());
    CHECK(sprite_anim_steps(plan) == 6);  // 0 1 2 3 2 1, the end frames are not repeated
    CHECK(play(p, plan, 8).frames == std::vector<int>{1, 2, 3, 2, 1, 0, 1, 2});
}

TEST_CASE("sprite animator: a clip that does not loop ends once and clipEnded is reported once") {
    SpriteAnimator a;
    a.clip = "pop";
    const auto plan = resolve_sprite_animator(a, "t.png", test_sheet());
    const Run r = play(a, plan, 6);
    CHECK(r.frames == std::vector<int>{5, 6, 6, 6, 6, 6});
    CHECK(r.ends == 1);
    CHECK_FALSE(a.playing);
    CHECK(a.ended);
    // reverse ends on its first frame, pingpong back on the first too
    SpriteAnimator rv;
    rv.clip = "pop";
    rv.mode = SpriteAnimMode::Reverse;
    const auto rp = resolve_sprite_animator(rv, "t.png", test_sheet());
    CHECK(play(rv, rp, 4).frames == std::vector<int>{5, 4, 4, 4});
    SpriteAnimator pp;
    pp.clip = "pop";
    pp.mode = SpriteAnimMode::PingPong;
    const auto pPlan = resolve_sprite_animator(pp, "t.png", test_sheet());
    const Run pr = play(pp, pPlan, 6);
    CHECK(pr.frames == std::vector<int>{5, 6, 5, 4, 4, 4});
    CHECK(pr.ends == 1);
}

TEST_CASE("sprite animator: changing the clip restarts, rewinding time runs a finished clip again") {
    SpriteAnimator a;
    a.clip = "pop";
    auto plan = resolve_sprite_animator(a, "t.png", test_sheet());
    play(a, plan, 5);
    REQUIRE(a.ended);
    a.clip = "spin";  // a finished animation plays the next clip right away
    plan = resolve_sprite_animator(a, "t.png", test_sheet());
    CHECK(play(a, plan, 2).frames == std::vector<int>{1, 2});
    a.clip = "pop";
    plan = resolve_sprite_animator(a, "t.png", test_sheet());
    play(a, plan, 5);
    REQUIRE(a.ended);
    a.time = 0;
    a.playing = true;
    CHECK(play(a, plan, 2).frames == std::vector<int>{5, 6});
}

TEST_CASE("sprite animator: the plain numeric grid works as before, with a sheet's padding when the grid is its own") {
    SpriteAnimator a;
    a.columns = 4;
    a.rows = 2;
    a.lastFrame = 7;
    a.fps = 4;
    auto plan = resolve_sprite_animator(a, "t.png", nullptr);
    CHECK(play(a, plan, 3, 0.25f).frames == std::vector<int>{1, 2, 3});
    const Rect r = sprite_frame_rect(plan, 5, 64, 32);
    CHECK(r.x == 16);
    CHECK(r.y == 16);
    CHECK(r.w == 16);
    // the same grid over a padded sheet: the cells are 16 px with 1 px of gutter
    plan = resolve_sprite_animator(a, "t.png", test_sheet());
    const Rect g = sprite_frame_rect(plan, 5, 64, 32);
    CHECK(g.x == 17);
    CHECK(g.y == 17);
    CHECK(g.w == 14);
    CHECK(g.h == 14);
}

TEST_CASE("sprite animator: the sheet pivot counts from the top, only for a sprite that keeps the default pivot") {
    SpriteAnimator a;
    Sprite s;
    a.clip = "spin";
    auto plan = resolve_sprite_animator(a, "t.png", test_sheet());
    Vec2 p = sprite_effective_pivot(s, a, plan);
    CHECK(p.x == doctest::Approx(0.5f));
    CHECK(p.y == doctest::Approx(0.0f));  // [0.5, 1] from the top-left is the bottom edge: Sprite.pivot y 0
    a.clip = "pop";  // the clip's own pivot [0.25, 0.75] wins
    plan = resolve_sprite_animator(a, "t.png", test_sheet());
    p = sprite_effective_pivot(s, a, plan);
    CHECK(p.x == doctest::Approx(0.25f));
    CHECK(p.y == doctest::Approx(0.25f));
    s.pivot = {0.1f, 0.9f};  // the sprite sets its own
    CHECK(sprite_effective_pivot(s, a, plan).x == doctest::Approx(0.1f));
    s.pivot = {0.5f, 0.5f};
    a.sheetPivot = false;
    CHECK(sprite_effective_pivot(s, a, plan).x == doctest::Approx(0.5f));
}

namespace {
// An entity with the animator, stepped like the renderer does: step, then run the frame events.
struct EventRig {
    World world;
    Entity e;
    SpriteAnimator* a = nullptr;
    SpriteAnimPlan plan;
    explicit EventRig(const char* clip, const char* events) {
        ensure_builtin_components();
        e = world.create("hero", "hero");
        a = &world.add<SpriteAnimator>(e);
        a->clip = clip;
        a->events = Json::parse(events);
        plan = resolve_sprite_animator(*a, "t.png", test_sheet());
    }
    void step(float dt) {
        sprite_animator_step(*a, plan, dt);
        sprite_animator_fire_events(world, e, *a, plan);
    }
    int sounds() { return int(feel_take_sounds(world).size()); }
    std::vector<int> game_frames() {
        std::vector<int> frames;
        for (const GameEvent& g : world.events().game) frames.push_back(g.data["frame"].get<int>());
        world.events().game.clear();
        return frames;
    }
};
}  // namespace

TEST_CASE("sprite animator events: a frame fires once per pass, with its game event and its feel actions") {
    EventRig r("spin", R"([{"frame":2,"name":"hit","data":{"hand":"left"},"feel":{"action":"sound","path":"audio/hit.wav"}}])");
    for (int i = 0; i < 12; ++i) r.step(0.1f);  // 3 loops of the 4 frames
    CHECK(r.game_frames() == std::vector<int>{2, 2, 2});
    CHECK(r.sounds() == 3);
}

TEST_CASE("sprite animator events: a long frame time skips no event, in order, and a nameless event sends no game event") {
    EventRig r("spin", R"([{"frame":1,"feel":{"action":"sound","path":"audio/a.wav"}},{"frame":3,"name":"end"},{"frame":0,"name":"start"}])");
    r.step(0.05f);  // frame 0
    CHECK(r.game_frames() == std::vector<int>{0});
    r.world.events().game.clear();
    r.step(0.46f);  // 0.51 s: steps 1..5, frames 1 2 3 0 1
    std::vector<std::string> names;
    for (const GameEvent& g : r.world.events().game) names.push_back(g.name);
    CHECK(names == std::vector<std::string>{"end", "start"});  // frame 1 has only feel actions; its two passes: 1 and 5
    CHECK(r.sounds() == 2);
}

TEST_CASE("sprite animator events: pingpong shows its middle frames twice, a rewind fires nothing for the jump, clip scopes an event") {
    EventRig p("spin", R"([{"frame":2,"name":"mid"},{"clip":"pop","frame":4,"name":"pop"}])");
    p.a->mode = SpriteAnimMode::PingPong;
    p.plan = resolve_sprite_animator(*p.a, "t.png", test_sheet());
    for (int i = 0; i < 12; ++i) p.step(0.1f);  // two passes of 0 1 2 3 2 1
    CHECK(p.game_frames() == std::vector<int>{2, 2, 2, 2});  // frame 2 is shown twice per pass; the event of clip "pop" never fires
    EventRig r("spin", R"([{"frame":2,"name":"mid"}])");
    for (int i = 0; i < 3; ++i) r.step(0.1f);
    CHECK(r.game_frames().size() == 1);
    r.a->time = 0.0f;  // a script seeks back
    r.step(0.001f);
    CHECK(r.game_frames().empty());
    for (int i = 0; i < 3; ++i) r.step(0.1f);  // and the clip plays on: the frame fires again
    CHECK(r.game_frames().size() == 1);
}

TEST_CASE("sprite animator events: a clip that does not loop fires each frame once and nothing after its end") {
    EventRig r("pop", R"([{"frame":6,"name":"last"},{"frame":4,"name":"first"}])");
    for (int i = 0; i < 10; ++i) r.step(0.1f);
    CHECK(r.game_frames() == std::vector<int>{4, 6});
}

TEST_CASE("sprite animator events: the checks name the pointer, the key and the fix") {
    const auto sheet = test_sheet();
    auto issues = check_sprite_events(Json::parse(R"([{"frame":1,"name":"a"},{"frme":2,"name":"b"},{"frame":-1,"name":"c"},
        {"frame":1},{"frame":1,"clip":"spn","name":"d"},{"frame":2,"feel":{"action":"flsh"}},5])"), "/events", sheet);
    auto has = [&](const std::string& pointer, const std::string& word) {
        for (const ClipIssue& i : issues)
            if (i.pointer == pointer && (i.message + " " + i.hint).find(word) != std::string::npos) return true;
        return false;
    };
    CHECK(has("/events/1/frme", "frame"));        // did you mean
    CHECK(has("/events/1/frame", "needs"));
    CHECK(has("/events/2/frame", "whole number"));
    CHECK(has("/events/3", "name"));              // neither name nor feel
    CHECK(has("/events/4/clip", "spin"));         // the sheet's clips
    CHECK(has("/events/5/feel", "flash"));
    CHECK(has("/events/6", "object"));
    CHECK(check_sprite_events(Json::parse(R"([{"frame":1,"name":"a"}])"), "/events", sheet).empty());
    CHECK_FALSE(check_sprite_events(Json::parse(R"({"frame":1})"), "/events", sheet).empty());
}
