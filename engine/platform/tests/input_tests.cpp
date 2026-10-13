#include <doctest.h>

#include "fa/platform/input.h"

using namespace fa;

TEST_CASE("key names round-trip") {
    CHECK(std::string(key_name(Key::A)) == "A");
    CHECK(std::string(key_name(Key::Num1)) == "1");
    CHECK(std::string(key_name(Key::Space)) == "Space");
    CHECK(std::string(key_name(Key::LeftShift)) == "LeftShift");
    CHECK(std::string(key_name(Key::F12)) == "F12");
    for (size_t i = 1; i < size_t(Key::Count); ++i) {
        Key k = Key(i);
        CHECK(key_from_name(key_name(k)) == k);
    }
    CHECK(key_from_name("space") == Key::Space);
    CHECK(key_from_name("nonsense") == Key::Unknown);
}

TEST_CASE("raw key edges") {
    Input in;
    in.begin_frame();
    in.on_key(Key::W, true);
    CHECK(in.key_down(Key::W));
    CHECK(in.key_pressed(Key::W));
    in.begin_frame();
    CHECK(in.key_down(Key::W));
    CHECK_FALSE(in.key_pressed(Key::W));
    in.on_key(Key::W, false);
    CHECK(in.key_released(Key::W));
    in.begin_frame();
    CHECK_FALSE(in.key_released(Key::W));
}

TEST_CASE("actions: bindings, edges, axis, vector") {
    Input in;
    auto problems = in.set_actions(Json::parse(R"({
        "jump": ["Space", "W", "GamepadA"],
        "move_left": ["A", "Left"],
        "move_right": ["D", "Right"],
        "move_up": ["Up"],
        "move_down": ["Down"],
        "fire": ["MouseLeft", "Touch"]
    })"));
    CHECK(problems.empty());
    CHECK(in.has_action("jump"));
    CHECK_FALSE(in.has_action("nope"));
    CHECK(in.action_names().size() == 6);

    in.begin_frame();
    in.on_key(Key::Space, true);
    CHECK(in.action_down("jump"));
    CHECK(in.action_pressed("jump"));
    in.begin_frame();
    CHECK(in.action_down("jump"));
    CHECK_FALSE(in.action_pressed("jump"));
    in.on_key(Key::W, true);  // second binding while already down: not a new press
    CHECK_FALSE(in.action_pressed("jump"));
    in.begin_frame();
    in.on_key(Key::Space, false);
    CHECK(in.action_down("jump"));  // W still held
    CHECK_FALSE(in.action_released("jump"));
    in.on_key(Key::W, false);
    CHECK_FALSE(in.action_down("jump"));
    CHECK(in.action_released("jump"));

    // axis / vector
    in.begin_frame();
    in.on_key(Key::A, true);
    CHECK(in.axis("move_left", "move_right") == doctest::Approx(-1.0f));
    in.on_key(Key::D, true);
    CHECK(in.axis("move_left", "move_right") == doctest::Approx(0.0f));
    in.on_key(Key::A, false);
    in.on_key(Key::Up, true);
    Vec2 v = in.vector("move_left", "move_right", "move_down", "move_up");
    CHECK(v.x == doctest::Approx(0.7071f).epsilon(0.01));
    CHECK(v.y == doctest::Approx(0.7071f).epsilon(0.01));

    // mouse + touch bindings
    in.begin_frame();
    in.on_mouse_button(MouseButton::Left, true);
    CHECK(in.action_pressed("fire"));
    in.begin_frame();
    in.on_mouse_button(MouseButton::Left, false);
    in.on_touch_begin(7, {10, 20});
    CHECK(in.action_down("fire"));  // touch holds it
    CHECK(in.touches().size() == 1);
    in.on_touch_end(7);
    CHECK_FALSE(in.action_down("fire"));
    CHECK(in.action_released("fire"));
}

TEST_CASE("a press and release within one frame still yields both edges") {
    Input in;
    in.set_actions(Json::parse(R"({"jump": ["Space"]})"));
    in.begin_frame();
    in.on_key(Key::Space, true);
    in.on_key(Key::Space, false);
    CHECK_FALSE(in.action_down("jump"));
    CHECK(in.action_pressed("jump"));
    CHECK(in.action_released("jump"));
}

TEST_CASE("set_actions reports unknown bindings with suggestions") {
    Input in;
    auto problems = in.set_actions(Json::parse(R"({"jump": ["Spce", "W"], "bad": 5, "fire": ["MouseLeftt"]})"));
    REQUIRE(problems.size() == 3);
    CHECK(problems[0].find("Spce") != std::string::npos);
    CHECK(problems[0].find("Did you mean 'Space'") != std::string::npos);
    CHECK(problems[0].find("jump") != std::string::npos);
    CHECK(problems[2].find("MouseLeft") != std::string::npos);
    CHECK(in.has_action("jump"));  // valid bindings still installed
    in.begin_frame();
    in.on_key(Key::W, true);
    CHECK(in.action_down("jump"));
}

TEST_CASE("action overrides produce edges and do not need bindings") {
    Input in;
    in.set_actions(Json::parse(R"({"jump": ["Space"]})"));
    in.begin_frame();
    in.set_action_override("jump", true);
    CHECK(in.action_down("jump"));
    CHECK(in.action_pressed("jump"));
    in.begin_frame();
    CHECK(in.action_down("jump"));
    CHECK_FALSE(in.action_pressed("jump"));
    in.set_action_override("jump", false);
    CHECK_FALSE(in.action_down("jump"));
    CHECK(in.action_released("jump"));
    in.begin_frame();
    CHECK_FALSE(in.action_released("jump"));

    in.set_action_override("undeclared", true);  // works even for unbound actions
    CHECK(in.action_down("undeclared"));
    in.clear_action_overrides();
    CHECK_FALSE(in.action_down("undeclared"));
}

TEST_CASE("mouse, wheel, text and snapshot") {
    Input in;
    in.begin_frame();
    in.on_mouse_move({100, 50});
    in.on_mouse_move({110, 60});
    CHECK(in.mouse_position() == Vec2{110, 60});
    CHECK(in.mouse_delta() == Vec2{110, 60});
    in.on_mouse_wheel(1.0f);
    in.on_mouse_wheel(2.0f);
    CHECK(in.mouse_wheel() == doctest::Approx(3.0f));
    in.on_text(U'h');
    in.on_text(0xE9);
    CHECK(in.text_input().size() == 2);
    in.on_key(Key::Enter, true);
    Json snap = in.snapshot();
    CHECK(snap["keysDown"][0] == "Enter");
    CHECK(snap["mouse"]["position"][0] == 110);
    in.begin_frame();
    CHECK(in.text_input().empty());
    CHECK(in.mouse_wheel() == 0.0f);
    CHECK(in.mouse_delta() == Vec2{});
    in.release_all();
    CHECK_FALSE(in.key_down(Key::Enter));
    CHECK(in.key_released(Key::Enter));
}
