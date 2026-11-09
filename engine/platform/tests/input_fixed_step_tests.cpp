// The fixed-step view of Input (Input::FixedScope, end_fixed_step): its own edges, kept until a fixed step takes them.
#include <doctest.h>

#include "fa/platform/input.h"

using namespace fa;

namespace {

struct Reads {
    int fixedPressed = 0, fixedReleased = 0, fixedAction = 0, framePressed = 0, frameAction = 0;
};

// One engine frame, as Engine::run_frame does it: `steps` fixed steps (each reads in a FixedScope, then closes), then the
// frame's own reads, then begin_frame().
Reads run_frame_reads(Input& in, int steps, Key key, const char* action) {
    Reads r;
    for (int i = 0; i < steps; ++i) {
        Input::FixedScope scope(in);
        r.fixedPressed += in.key_pressed(key) ? 1 : 0;
        r.fixedReleased += in.key_released(key) ? 1 : 0;
        r.fixedAction += in.action_pressed(action) ? 1 : 0;
        in.end_fixed_step();
    }
    r.framePressed = in.key_pressed(key) ? 1 : 0;
    r.frameAction = in.action_pressed(action) ? 1 : 0;
    in.begin_frame();
    return r;
}

}  // namespace

TEST_CASE("fixed-step view: a key press is seen by one step whatever the number of steps in the frame") {
    for (int steps : {1, 2, 5}) {
        INFO("steps " << steps);
        Input in;
        in.set_actions(Json::parse(R"({"jump": ["Space"]})"));
        in.on_key(Key::Space, true);
        const Reads r = run_frame_reads(in, steps, Key::Space, "jump");
        CHECK(r.fixedPressed == 1);
        CHECK(r.fixedAction == 1);
        CHECK(r.framePressed == 1);  // the frame's own view is untouched by the steps
        CHECK(r.frameAction == 1);
        const Reads held = run_frame_reads(in, steps, Key::Space, "jump");  // held: no new edge anywhere
        CHECK(held.fixedPressed == 0);
        CHECK(held.fixedAction == 0);
        CHECK(held.framePressed == 0);
        CHECK(in.key_down(Key::Space));
    }
}

TEST_CASE("fixed-step view: an edge arriving in a frame with no step is kept for the next step") {
    Input in;
    in.set_actions(Json::parse(R"({"jump": ["Space"]})"));
    in.on_key(Key::Space, true);
    const Reads none = run_frame_reads(in, 0, Key::Space, "jump");
    CHECK(none.fixedPressed == 0);
    CHECK(none.framePressed == 1);
    const Reads next = run_frame_reads(in, 3, Key::Space, "jump");
    CHECK(next.fixedPressed == 1);  // seen by the first step of the next frame, only
    CHECK(next.fixedAction == 1);
    CHECK(next.framePressed == 0);  // the frame view saw it in its own frame
    in.on_key(Key::Space, false);
    CHECK(run_frame_reads(in, 0, Key::Space, "jump").fixedReleased == 0);
    CHECK(run_frame_reads(in, 2, Key::Space, "jump").fixedReleased == 1);
    CHECK(run_frame_reads(in, 2, Key::Space, "jump").fixedReleased == 0);
}

TEST_CASE("fixed-step view: a press and a release between two steps are both kept, once") {
    Input in;
    in.on_key(Key::A, true);
    run_frame_reads(in, 0, Key::A, "none");
    in.on_key(Key::A, false);
    const Reads r = run_frame_reads(in, 4, Key::A, "none");
    CHECK(r.fixedPressed == 1);
    CHECK(r.fixedReleased == 1);
}

TEST_CASE("fixed-step view: mouse, touch, pad, wheel, delta, text, Back and overrides") {
    Input in;
    in.set_actions(Json::parse(R"({"fire": ["MouseLeft"], "pad": ["GamepadA"], "ovr": ["Q"]})"));
    in.on_mouse_move({10, 20});
    in.on_mouse_button(MouseButton::Left, true);
    in.on_gamepad_button(0, GamepadButton::A, true);
    in.on_mouse_wheel(3.0f);
    in.on_text('x');
    in.on_back();
    in.set_action_override("ovr", true);
    in.on_touch_begin(7, {10, 20});
    in.begin_frame();  // a frame with no step: the frame view is done with it all, the fixed-step view has not been asked
    {
        Input::FixedScope scope(in);
        CHECK(in.in_fixed_step());
        CHECK(in.mouse_pressed(MouseButton::Left));
        CHECK(in.action_pressed("fire"));
        CHECK(in.gamepad_pressed(0, GamepadButton::A));
        CHECK(in.action_pressed("pad"));
        CHECK(in.action_pressed("ovr"));
        CHECK(in.mouse_wheel() == doctest::Approx(3.0f));
        CHECK(in.mouse_delta().x == doctest::Approx(10.0f));
        CHECK(in.text_utf8() == "x");
        CHECK(in.back_pressed());
        REQUIRE(in.touches().size() == 1);
        CHECK(in.touch_pressed(in.touches()[0]));
        in.end_fixed_step();
        CHECK_FALSE(in.mouse_pressed(MouseButton::Left));
        CHECK_FALSE(in.action_pressed("fire"));
        CHECK_FALSE(in.gamepad_pressed(0, GamepadButton::A));
        CHECK_FALSE(in.action_pressed("ovr"));
        CHECK(in.mouse_wheel() == 0.0f);
        CHECK(in.mouse_delta().x == 0.0f);
        CHECK(in.text_input().empty());
        CHECK_FALSE(in.back_pressed());
        CHECK_FALSE(in.touch_pressed(in.touches()[0]));
        CHECK(in.mouse_down(MouseButton::Left));  // holds are shared
        CHECK(in.action_down("fire"));
    }
    CHECK_FALSE(in.in_fixed_step());
    CHECK_FALSE(in.mouse_pressed(MouseButton::Left));  // the frame view was advanced by begin_frame() above
    in.on_mouse_button(MouseButton::Left, false);
    CHECK(in.mouse_released(MouseButton::Left));
    {
        Input::FixedScope scope(in);
        CHECK(in.mouse_released(MouseButton::Left));
        CHECK(in.action_released("fire"));
    }
}

TEST_CASE("fixed-step view: nested scopes restore the view, discard_idle_motion clears the deltas of both") {
    Input in;
    {
        Input::FixedScope outer(in);
        {
            Input::FixedScope inner(in);
            CHECK(in.in_fixed_step());
        }
        CHECK(in.in_fixed_step());
    }
    CHECK_FALSE(in.in_fixed_step());
    in.on_mouse_wheel(1.0f);
    in.on_text('z');
    in.discard_idle_motion();
    CHECK(in.mouse_wheel() == 0.0f);
    Input::FixedScope scope(in);
    CHECK(in.mouse_wheel() == 0.0f);
    CHECK(in.text_input().empty());
}

TEST_CASE("fixed-step view: a press the UI consumed is not given to a step that has not run yet") {
    Input in;
    in.set_actions(Json::parse(R"({"pause": ["Escape"]})"));
    in.on_key(Key::Escape, true);
    in.consume_action("pause");  // the UI handled it, in a frame whose steps did not take it
    CHECK_FALSE(in.action_pressed("pause"));
    Input::FixedScope scope(in);
    CHECK_FALSE(in.action_pressed("pause"));
    CHECK(in.key_pressed(Key::Escape));  // the raw key is not an action: consuming does not hide it
    CHECK(in.action_down("pause"));
}

TEST_CASE("fixed-step view: consuming after a step took the press does not silence the next press") {
    Input in;
    in.set_actions(Json::parse(R"({"pause": ["Escape"]})"));
    in.on_key(Key::Escape, true);
    {
        Input::FixedScope scope(in);
        CHECK(in.action_pressed("pause"));
        in.end_fixed_step();
    }
    in.consume_action("pause");  // the UI, after the step: the fixed-step view has no press of it waiting
    in.begin_frame();
    in.on_key(Key::Escape, false);
    {
        Input::FixedScope scope(in);
        in.end_fixed_step();
    }
    in.on_key(Key::Escape, true);
    Input::FixedScope scope(in);
    CHECK(in.action_pressed("pause"));
}

TEST_CASE("fixed-step view: a second press after a consumed one is not silenced when no step ran in between") {
    Input in;
    in.set_actions(Json::parse(R"({"pause": ["Escape"], "shoot": ["MouseLeft"]})"));
    in.on_key(Key::Escape, true);
    in.on_mouse_button(MouseButton::Left, true);
    in.consume_action("pause");  // the UI handled the first press; no step ran yet
    in.begin_frame();
    in.on_key(Key::Escape, false);
    in.on_key(Key::Escape, true);  // pressed again before any step took the first
    {
        Input::FixedScope scope(in);
        CHECK(in.action_pressed("pause"));  // the later press is not hidden
        CHECK(in.action_pressed("shoot"));  // never consumed
        in.end_fixed_step();
    }
    // A press that is consumed and still held stays consumed until it is released.
    in.on_key(Key::Escape, false);
    in.on_key(Key::Escape, true);
    in.consume_action("pause");
    in.on_mouse_button(MouseButton::Left, false);
    Input::FixedScope scope(in);
    CHECK_FALSE(in.action_pressed("pause"));
    CHECK(in.action_released("shoot"));
}

TEST_CASE("fixed-step view: an event fed while a step runs reaches the next step, once") {
    Input in;
    in.set_actions(Json::parse(R"({"jump": ["Space"]})"));
    {
        Input::FixedScope scope(in);
        CHECK_FALSE(in.key_pressed(Key::Space));
        in.on_key(Key::Space, true);  // an onFixedUpdate injects a key
        in.on_mouse_wheel(2.0f);
        in.on_text('q');
        in.on_touch_begin(5, {1, 2});
        in.on_gamepad_button(0, GamepadButton::B, true);
        in.on_back();
        in.end_fixed_step();  // the step is over: what it injected is for the next one
    }
    {
        Input::FixedScope scope(in);
        CHECK(in.key_pressed(Key::Space));
        CHECK(in.action_pressed("jump"));
        CHECK(in.mouse_wheel() == doctest::Approx(2.0f));
        CHECK(in.text_utf8() == "q");
        REQUIRE(in.touches().size() == 1);
        CHECK(in.touch_pressed(in.touches()[0]));
        CHECK(in.gamepad_pressed(0, GamepadButton::B));
        CHECK(in.back_pressed());
        in.end_fixed_step();
    }
    Input::FixedScope scope(in);
    CHECK_FALSE(in.key_pressed(Key::Space));
    CHECK_FALSE(in.action_pressed("jump"));
    CHECK(in.mouse_wheel() == 0.0f);
    CHECK(in.text_input().empty());
    REQUIRE(in.touches().size() == 1);
    CHECK_FALSE(in.touch_pressed(in.touches()[0]));
    CHECK_FALSE(in.gamepad_pressed(0, GamepadButton::B));
    CHECK_FALSE(in.back_pressed());
    CHECK(in.key_down(Key::Space));
}

TEST_CASE("fixed-step view: what arrived before a step is taken by it, what arrived during it stays") {
    Input in;
    in.set_actions(Json::parse(R"({"jump": ["Space"], "fire": ["F"]})"));
    in.on_key(Key::Space, true);  // before the step
    {
        Input::FixedScope scope(in);
        CHECK(in.action_pressed("jump"));
        in.on_key(Key::F, true);  // during it
        in.end_fixed_step();
    }
    Input::FixedScope scope(in);
    CHECK_FALSE(in.action_pressed("jump"));
    CHECK(in.action_pressed("fire"));
}

TEST_CASE("fixed-step view: a tap that lands and lifts between two steps is seen once by each view") {
    Input in;
    in.on_touch_begin(9, {5, 6});
    in.on_touch_end(9);
    CHECK(in.touches().empty());  // the state: no finger is down
    {
        const std::vector<Touch> frame = in.touches_in_view();  // the frame view has not looked yet
        REQUIRE(frame.size() == 1);
        CHECK(frame[0].id == 9);
        CHECK(in.touch_pressed(frame[0]));
        CHECK(frame[0].position == Vec2{5, 6});
    }
    {
        Input::FixedScope scope(in);
        const std::vector<Touch> fixed = in.touches_in_view();
        REQUIRE(fixed.size() == 1);
        CHECK(in.touch_pressed(fixed[0]));
        in.end_fixed_step();
        CHECK(in.touches_in_view().empty());
    }
    in.begin_frame();  // the frame view saw it in its own time
    CHECK(in.touches_in_view().empty());

    // The frame saw the tap and no step has run: the next step still gets it, and the next frame does not.
    in.on_touch_begin(10, {1, 1});
    in.on_touch_end(10);
    CHECK(in.touches_in_view().size() == 1);
    in.begin_frame();
    CHECK(in.touches_in_view().empty());
    {
        Input::FixedScope scope(in);
        CHECK(in.touches_in_view().size() == 1);
        in.end_fixed_step();
    }
    {
        Input::FixedScope scope(in);
        CHECK(in.touches_in_view().empty());
    }
}

TEST_CASE("fixed-step view: a view nobody advances stays bounded") {
    Input in;
    in.set_actions(Json::parse(R"({"jump": ["Space"]})"));
    for (int i = 0; i < 20000; ++i) {
        in.on_text('a');
        in.on_key(Key::Space, true);
        in.consume_action("jump");
        in.on_key(Key::Space, false);
    }
    Input::FixedScope scope(in);
    CHECK(in.text_input().size() <= Input::kMaxTextPerView);
    CHECK(in.text_input().size() >= 1000);
    in.on_key(Key::Space, true);
    CHECK(in.action_pressed("jump"));  // not left consumed by the earlier releases
}
