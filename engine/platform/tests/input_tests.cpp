#include <doctest.h>

#include <cmath>

#include "fa/platform/gamepad.h"
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

TEST_CASE("the first finger drives the mouse like a device: position, MouseLeft down and up") {
    Input in;
    in.set_actions(Json::parse(R"({"click": ["MouseLeft"]})"));
    in.begin_frame();
    in.on_touch_begin(7, {10, 20});
    CHECK(in.mouse_position() == Vec2{10, 20});
    CHECK(in.mouse_down(MouseButton::Left));
    CHECK(in.mouse_pressed(MouseButton::Left));
    CHECK(in.action_pressed("click"));
    CHECK(in.touches().size() == 1);

    in.begin_frame();
    CHECK_FALSE(in.mouse_pressed(MouseButton::Left));  // an edge lasts one frame
    in.on_touch_move(7, {30, 40});
    CHECK(in.mouse_position() == Vec2{30, 40});
    CHECK(in.mouse_down(MouseButton::Left));

    // a second finger neither moves the mouse nor presses anything
    in.on_touch_begin(8, {200, 300});
    in.on_touch_move(8, {210, 310});
    CHECK(in.mouse_position() == Vec2{30, 40});
    in.on_touch_end(8);
    CHECK(in.mouse_down(MouseButton::Left));  // the first finger is still down

    in.begin_frame();
    in.on_touch_end(7);
    CHECK_FALSE(in.mouse_down(MouseButton::Left));
    CHECK(in.mouse_released(MouseButton::Left));
    CHECK(in.mouse_position() == Vec2{30, 40});  // released where the finger lifted
    CHECK(in.touches().empty());

    // the next finger to land becomes the mouse finger, even while another finger is still down
    in.begin_frame();
    in.on_touch_begin(1, {5, 5});
    in.on_touch_begin(2, {6, 6});
    in.on_touch_end(1);  // the mouse finger lifts first
    CHECK_FALSE(in.mouse_down(MouseButton::Left));
    in.on_touch_end(2);
    in.on_touch_begin(3, {70, 80});
    CHECK(in.mouse_position() == Vec2{70, 80});
    CHECK(in.mouse_down(MouseButton::Left));

    // release_all (focus lost, test reset) lifts the mouse finger too, so the next finger starts clean
    in.release_all();
    CHECK_FALSE(in.mouse_down(MouseButton::Left));
    in.begin_frame();
    in.on_touch_begin(4, {1, 2});
    CHECK(in.mouse_pressed(MouseButton::Left));
    in.on_touch_end(99);  // an unknown finger changes nothing
    CHECK(in.mouse_down(MouseButton::Left));
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

// ---------------------------------------------------------------------------- gamepads
TEST_CASE("gamepad button and axis names round-trip, case-insensitively") {
    for (size_t i = 0; i < size_t(GamepadButton::Count); ++i) {
        GamepadButton b{};
        REQUIRE(gamepad_button_from_name(gamepad_button_name(GamepadButton(i)), b));
        CHECK(b == GamepadButton(i));
    }
    for (size_t i = 0; i < size_t(GamepadAxis::Count); ++i) {
        GamepadAxis a{};
        REQUIRE(gamepad_axis_from_name(gamepad_axis_name(GamepadAxis(i)), a));
        CHECK(a == GamepadAxis(i));
    }
    GamepadButton b = GamepadButton::A;
    GamepadAxis a = GamepadAxis::LeftX;
    CHECK(gamepad_button_from_name("dpadleft", b));
    CHECK(b == GamepadButton::DpadLeft);
    CHECK(gamepad_axis_from_name("righttrigger", a));
    CHECK(a == GamepadAxis::RightTrigger);
    CHECK_FALSE(gamepad_button_from_name("Z", b));
    CHECK(b == GamepadButton::DpadLeft);  // an unknown name leaves the output alone
    CHECK_FALSE(gamepad_axis_from_name("LeftZ", a));
    CHECK(gamepad_button_names().size() == size_t(GamepadButton::Count));
}

TEST_CASE("gamepad buttons: edges, connected flags, a binding matches any pad") {
    Input in;
    CHECK(in.set_actions(Json::parse(R"({"jump": ["Space", "GamepadA"], "pause": ["gamepadstart"]})")).empty());
    CHECK_FALSE(in.gamepad_connected(0));
    in.begin_frame();
    in.on_gamepad_button(2, GamepadButton::A, true);  // the first event of a pad connects it
    CHECK(in.gamepad_connected(2));
    CHECK_FALSE(in.gamepad_connected(0));
    CHECK(in.gamepad_down(2, GamepadButton::A));
    CHECK(in.gamepad_pressed(2, GamepadButton::A));
    CHECK_FALSE(in.gamepad_down(0, GamepadButton::A));
    CHECK(in.action_down("jump"));
    CHECK(in.action_pressed("jump"));
    CHECK_FALSE(in.action_down("pause"));

    in.begin_frame();
    CHECK(in.action_down("jump"));
    CHECK_FALSE(in.action_pressed("jump"));
    CHECK_FALSE(in.gamepad_pressed(2, GamepadButton::A));
    in.on_gamepad_button(0, GamepadButton::A, true);  // a second pad on the same action: not a new press
    CHECK_FALSE(in.action_pressed("jump"));

    in.begin_frame();
    in.on_gamepad_button(2, GamepadButton::A, false);
    CHECK(in.gamepad_released(2, GamepadButton::A));
    CHECK(in.action_down("jump"));  // pad 0 still holds it
    CHECK_FALSE(in.action_released("jump"));
    in.on_gamepad_connected(0, false);  // unplugging releases what was held
    CHECK_FALSE(in.gamepad_connected(0));
    CHECK_FALSE(in.action_down("jump"));
    CHECK(in.action_released("jump"));
    CHECK(in.gamepad_released(0, GamepadButton::A));

    in.on_gamepad_button(7, GamepadButton::A, true);  // outside 0..3: ignored
    in.on_gamepad_button(-1, GamepadButton::A, true);
    in.on_gamepad_axis(4, GamepadAxis::LeftX, 1.0f);
    CHECK_FALSE(in.gamepad_connected(4));
    CHECK_FALSE(in.gamepad_down(7, GamepadButton::A));

    in.on_gamepad_connected(1, true);  // connecting alone also works
    CHECK(in.gamepad_connected(1));
    in.on_gamepad_button(1, GamepadButton::Start, true);
    CHECK(in.action_down("pause"));
    in.release_all();  // focus lost / test reset: every pad goes away
    CHECK_FALSE(in.gamepad_connected(1));
    CHECK_FALSE(in.action_down("pause"));
    CHECK(in.action_released("pause"));
}

TEST_CASE("analog bindings: radial deadzone, rescaling, the down threshold, any pad") {
    Input in;
    CHECK(in.set_actions(Json::parse(R"({
        "left": ["A", "GamepadLeftStickLeft"], "right": ["D", "GamepadLeftStickRight"],
        "down": ["S", "GamepadLeftStickDown"], "up": ["W", "GamepadLeftStickUp"],
        "aim_right": ["GamepadRightStickRight"], "fire": ["GamepadRightTrigger"], "brake": ["GamepadLeftTrigger"]
    })")).empty());
    CHECK(in.gamepad_deadzone() == doctest::Approx(0.2f));
    in.begin_frame();

    in.on_gamepad_axis(0, GamepadAxis::LeftX, 0.15f);  // inside the deadzone
    CHECK(in.action_value("right") == 0.0f);
    CHECK(in.axis("left", "right") == 0.0f);

    in.on_gamepad_axis(0, GamepadAxis::LeftX, 0.62f);  // (0.62 - 0.2) / 0.8 = 0.525: just above the down threshold
    CHECK(in.action_value("right") == doctest::Approx(0.525f));
    CHECK(in.action_down("right"));
    CHECK(in.action_value("left") == 0.0f);
    in.on_gamepad_axis(0, GamepadAxis::LeftX, 0.58f);  // 0.475
    CHECK(in.action_value("right") < 0.5f);
    CHECK_FALSE(in.action_down("right"));

    in.on_gamepad_axis(0, GamepadAxis::LeftX, 1.0f);
    CHECK(in.action_value("right") == doctest::Approx(1.0f));
    in.on_gamepad_axis(0, GamepadAxis::LeftX, -1.0f);
    CHECK(in.action_value("left") == doctest::Approx(1.0f));
    CHECK(in.action_value("right") == 0.0f);
    CHECK(in.axis("left", "right") == doctest::Approx(-1.0f));
    in.on_gamepad_axis(0, GamepadAxis::LeftX, -3.0f);  // clamped
    CHECK(in.gamepad_raw_axis(0, GamepadAxis::LeftX) == doctest::Approx(-1.0f));

    // The deadzone is radial: the stick pair is measured together, so a small second component survives.
    in.on_gamepad_axis(0, GamepadAxis::LeftX, 0.8f);
    in.on_gamepad_axis(0, GamepadAxis::LeftY, 0.1f);
    CHECK(in.action_value("right") == doctest::Approx(0.752f).epsilon(0.01));
    CHECK(in.action_value("up") == doctest::Approx(0.094f).epsilon(0.02));
    in.on_gamepad_axis(0, GamepadAxis::LeftX, 0.0f);
    in.on_gamepad_axis(0, GamepadAxis::LeftY, 0.0f);

    // +Y is up: pushing up gives "up"; vector() normalises only above length 1.
    in.on_gamepad_axis(0, GamepadAxis::LeftY, 1.0f);
    CHECK(in.action_value("up") == doctest::Approx(1.0f));
    CHECK(in.action_value("down") == 0.0f);
    Vec2 v = in.vector("left", "right", "down", "up");
    CHECK(v.x == doctest::Approx(0.0f));
    CHECK(v.y == doctest::Approx(1.0f));
    in.on_gamepad_axis(0, GamepadAxis::LeftY, 0.6f);  // a half-tilted stick stays short
    v = in.vector("left", "right", "down", "up");
    CHECK(v.y == doctest::Approx(0.5f));
    in.on_gamepad_axis(0, GamepadAxis::LeftY, 0.0f);
    in.on_key(Key::D, true);  // keys give exactly 1, and a diagonal of two keys is a unit vector
    in.on_key(Key::W, true);
    v = in.vector("left", "right", "down", "up");
    CHECK(v.x == doctest::Approx(0.7071f).epsilon(0.01));
    CHECK(v.y == doctest::Approx(0.7071f).epsilon(0.01));
    in.on_key(Key::W, false);
    CHECK(in.axis("left", "right") == 1.0f);  // exactly
    in.on_key(Key::D, false);
    in.on_gamepad_connected(0, false);

    // Triggers: 0..1 after the deadzone; sticks and triggers of any pad count.
    in.on_gamepad_axis(3, GamepadAxis::RightTrigger, 0.5f);  // (0.5 - 0.2) / 0.8 = 0.375
    CHECK(in.action_value("fire") == doctest::Approx(0.375f));
    CHECK_FALSE(in.action_down("fire"));
    in.on_gamepad_axis(3, GamepadAxis::RightTrigger, 1.0f);
    CHECK(in.action_down("fire"));
    CHECK(in.action_value("brake") == 0.0f);
    in.on_gamepad_axis(1, GamepadAxis::RightX, 0.4f);
    CHECK(in.action_value("aim_right") == doctest::Approx(0.25f));

    // An override is a full press.
    in.set_action_override("aim_right", true);
    CHECK(in.action_value("aim_right") == 1.0f);
    in.set_action_override("aim_right", false);

    // The calibration knob.
    in.set_gamepad_deadzone(0.5f);
    CHECK(in.gamepad_deadzone() == 0.5f);
    CHECK(in.action_value("aim_right") == 0.0f);  // 0.4 is inside a 0.5 deadzone
    in.set_gamepad_deadzone(7.0f);  // clamped below 1: no division by zero
    CHECK(in.gamepad_deadzone() < 1.0f);
    in.set_gamepad_deadzone(0.0f);
    CHECK(in.action_value("aim_right") == doctest::Approx(0.4f));
}

TEST_CASE("analog bindings produce pressed and released edges") {
    Input in;
    in.set_actions(Json::parse(R"({"right": ["GamepadLeftStickRight"], "fire": ["GamepadLeftTrigger", "Space"]})"));
    in.begin_frame();
    in.on_gamepad_axis(0, GamepadAxis::LeftX, 1.0f);
    CHECK(in.action_pressed("right"));
    CHECK_FALSE(in.action_released("right"));
    in.begin_frame();
    CHECK(in.action_down("right"));
    CHECK_FALSE(in.action_pressed("right"));  // held across the frame boundary: not a new press
    in.on_gamepad_axis(0, GamepadAxis::LeftX, 0.1f);  // back into the deadzone
    CHECK_FALSE(in.action_down("right"));
    CHECK(in.action_released("right"));
    in.begin_frame();
    CHECK_FALSE(in.action_released("right"));

    // Another binding that is already down hides the analog one's press.
    in.on_key(Key::Space, true);
    in.begin_frame();
    in.on_gamepad_axis(2, GamepadAxis::LeftTrigger, 1.0f);
    CHECK_FALSE(in.action_pressed("fire"));
    in.begin_frame();
    in.on_key(Key::Space, false);
    in.on_gamepad_axis(2, GamepadAxis::LeftTrigger, 0.0f);
    CHECK(in.action_released("fire"));
}

TEST_CASE("unknown gamepad binding names are rejected with a suggestion") {
    Input in;
    auto problems = in.set_actions(Json::parse(R"({
        "a": ["GamepadAA"], "b": ["Gamepad:A"], "c": ["GamepadLeftSitckLeft"], "d": ["GamepadFoo"],
        "ok": ["GamepadDpadLeft", "GamepadRightStickUp"]
    })"));
    REQUIRE(problems.size() == 4);
    CHECK(problems[0].find("input.actions.a") != std::string::npos);
    CHECK(problems[0].find("Did you mean 'GamepadA'") != std::string::npos);
    CHECK(problems[1].find("Did you mean 'GamepadA'") != std::string::npos);
    CHECK(problems[2].find("GamepadLeftStickLeft") != std::string::npos);
    CHECK(problems[3].find("GamepadFoo") != std::string::npos);
    CHECK(in.has_action("ok"));
    in.begin_frame();
    in.on_gamepad_button(0, GamepadButton::DpadLeft, true);
    CHECK(in.action_down("ok"));
}

TEST_CASE("poll_gamepads runs on this machine with or without a pad plugged in") {
    Input in;
    in.begin_frame();
    poll_gamepads(in);  // the device backend (XInput, joystick API, GameController) or a no-op; never crashes
    poll_gamepads(in);
    for (int i = 0; i < kMaxGamepads; ++i) {
        CAPTURE(i);
        CHECK(std::abs(in.gamepad_raw_axis(i, GamepadAxis::LeftX)) <= 1.0f);
    }
}

TEST_CASE("snapshot lists connected gamepads only") {
    Input in;
    CHECK_FALSE(in.snapshot().contains("gamepads"));
    in.on_gamepad_button(1, GamepadButton::X, true);
    in.on_gamepad_axis(1, GamepadAxis::LeftX, 0.5f);
    Json s = in.snapshot();
    REQUIRE(s["gamepads"].size() == 1);
    CHECK(s["gamepads"][0]["index"] == 1);
    CHECK(s["gamepads"][0]["buttonsDown"][0] == "X");
    CHECK(s["gamepads"][0]["axes"]["LeftX"].get<double>() == doctest::Approx(0.5));
}

// ======================================================================================================================
// Options-menu settings: rebinding, last input, button names per pad family, text, cursor and keyboard state
// ======================================================================================================================
namespace {
Json jump_and_move() {
    return Json::parse(R"({"jump": ["Space", "GamepadA"], "left": ["A", "GamepadLeftStickLeft"], "fire": ["MouseLeft", "GamepadRightTrigger"]})");
}
}  // namespace

TEST_CASE("rebind replaces the bindings of an action and input follows") {
    Input in;
    in.set_actions(jump_and_move());
    CHECK(in.bindings("jump") == std::vector<std::string>{"Space", "GamepadA"});
    CHECK(in.rebind("jump", {"w", "gamepadx"}).empty());  // case-insensitive, stored canonical
    CHECK(in.bindings("jump") == std::vector<std::string>{"W", "GamepadX"});
    in.begin_frame();
    in.on_key(Key::Space, true);
    CHECK_FALSE(in.action_down("jump"));  // the old binding is gone
    in.on_key(Key::W, true);
    CHECK(in.action_down("jump"));
    CHECK(in.action_pressed("jump"));
    CHECK(in.rebind("jump", {}).empty());  // an empty list unbinds but keeps the action
    CHECK(in.has_action("jump"));
    CHECK(in.bindings("jump").empty());
    CHECK_FALSE(in.action_down("jump"));
}

TEST_CASE("rebind is all-or-nothing and its errors teach") {
    Input in;
    in.set_actions(jump_and_move());
    auto badBinding = in.rebind("jump", {"Enter", "Spce"});
    REQUIRE(badBinding.size() == 1);
    CHECK(badBinding[0].find("'Spce'") != std::string::npos);
    CHECK(badBinding[0].find("Did you mean 'Space'") != std::string::npos);
    CHECK(in.bindings("jump") == std::vector<std::string>{"Space", "GamepadA"});  // nothing changed
    auto badAction = in.rebind("jmp", {"Space"});
    REQUIRE(badAction.size() == 1);
    CHECK(badAction[0].find("Did you mean 'jump'") != std::string::npos);
    CHECK(badAction[0].find("fire, jump, left") != std::string::npos);  // the actions are listed
    CHECK_FALSE(in.has_action("jmp"));
    CHECK(in.bindings("jmp").empty());
}

TEST_CASE("reset_bindings goes back to what set_actions was given") {
    Input in;
    in.set_actions(jump_and_move());
    in.rebind("jump", {"Enter"});
    in.rebind("left", {"Left"});
    CHECK(in.reset_bindings("jump").empty());
    CHECK(in.bindings("jump") == std::vector<std::string>{"Space", "GamepadA"});
    CHECK(in.bindings("left") == std::vector<std::string>{"Left"});  // only the named action
    CHECK(in.reset_bindings().empty());
    CHECK(in.bindings("left") == std::vector<std::string>{"A", "GamepadLeftStickLeft"});
    CHECK(in.reset_bindings("nope").size() == 1);
    in.bind("extra", "Q");  // not declared by the project: a reset takes its bindings away
    CHECK(in.reset_bindings("extra").empty());
    CHECK_FALSE(in.has_action("extra"));
    in.set_actions(Json::parse(R"({"other": ["Z"]})"));  // a new set_actions replaces what a reset returns to
    in.rebind("other", {"X"});
    in.reset_bindings();
    CHECK(in.bindings("other") == std::vector<std::string>{"Z"});
    CHECK_FALSE(in.has_action("jump"));
}

TEST_CASE("bindings are reported by their canonical names, including half axes and mouse") {
    Input in;
    in.set_actions(Json::parse(R"({"all": ["touch", "mouseright", "gamepadleftstickup", "GamepadRightStickDown", "gamepadlefttrigger", "gamepadstart", "esc"]})"));
    CHECK(in.bindings("all") == std::vector<std::string>{"Touch", "MouseRight", "GamepadLeftStickUp", "GamepadRightStickDown",
                                                          "GamepadLeftTrigger", "GamepadStart", "Escape"});
}

TEST_CASE("last_pressed names the binding that went down this frame") {
    Input in;
    in.begin_frame();
    CHECK(in.last_pressed().empty());
    in.on_key(Key::Space, true);
    CHECK(in.last_pressed() == "Space");
    in.begin_frame();
    CHECK(in.last_pressed().empty());  // held keys are not new
    in.on_key(Key::Space, false);
    CHECK(in.last_pressed().empty());
    in.begin_frame();
    in.on_mouse_button(MouseButton::Right, true);
    CHECK(in.last_pressed() == "MouseRight");
    in.begin_frame();
    in.on_gamepad_button(0, GamepadButton::LeftShoulder, true);
    CHECK(in.last_pressed() == "GamepadLeftShoulder");
    in.begin_frame();
    in.on_key(Key::A, true);
    in.on_mouse_button(MouseButton::Left, true);
    in.on_gamepad_button(1, GamepadButton::B, true);
    CHECK(in.last_pressed() == "A");  // several in one frame: keys come first
    in.begin_frame();
    in.on_touch_begin(7, {10, 10});
    CHECK(in.last_pressed() == "Touch");  // not the MouseLeft the finger also presses
}

TEST_CASE("last_pressed sees sticks and triggers cross half way, once, in the right direction") {
    Input in;
    in.begin_frame();
    in.on_gamepad_axis(0, GamepadAxis::LeftX, 0.4f);  // past the deadzone (0.2) but under half after rescaling
    CHECK(in.last_pressed().empty());
    in.on_gamepad_axis(0, GamepadAxis::LeftX, -1.0f);
    CHECK(in.last_pressed() == "GamepadLeftStickLeft");
    in.begin_frame();
    CHECK(in.last_pressed().empty());  // still held, not new
    in.on_gamepad_axis(0, GamepadAxis::LeftX, 0.0f);
    in.begin_frame();
    in.on_gamepad_axis(0, GamepadAxis::LeftY, 1.0f);  // +Y is up
    CHECK(in.last_pressed() == "GamepadLeftStickUp");
    in.on_gamepad_axis(0, GamepadAxis::LeftY, 0.0f);
    in.begin_frame();
    in.on_gamepad_axis(2, GamepadAxis::RightTrigger, 1.0f);
    CHECK(in.last_pressed() == "GamepadRightTrigger");
    in.on_gamepad_axis(2, GamepadAxis::RightTrigger, 0.0f);
    in.begin_frame();
    in.on_gamepad_axis(0, GamepadAxis::RightY, -0.9f);
    CHECK(in.last_pressed() == "GamepadRightStickDown");
}

TEST_CASE("last_device follows the device that produced input last") {
    Input in;
    CHECK(in.last_device() == InputDevice::Keyboard);
    CHECK(std::string(input_device_name(in.last_device())) == "keyboard");
    in.on_mouse_move({0, 0});  // no movement: not input
    CHECK(in.last_device() == InputDevice::Keyboard);
    in.on_mouse_move({5, 5});
    CHECK(in.last_device() == InputDevice::Mouse);
    in.on_gamepad_button(0, GamepadButton::A, true);
    CHECK(in.last_device() == InputDevice::Gamepad);
    in.on_key(Key::A, true);
    CHECK(in.last_device() == InputDevice::Keyboard);
    in.on_mouse_wheel(1.0f);
    CHECK(in.last_device() == InputDevice::Mouse);
    in.on_touch_begin(1, {20, 20});  // a finger also moves and presses the mouse: still touch
    CHECK(in.last_device() == InputDevice::Touch);
    in.on_touch_move(1, {30, 30});
    CHECK(in.last_device() == InputDevice::Touch);
    in.on_touch_end(1);
    CHECK(in.last_device() == InputDevice::Touch);
    in.on_mouse_button(MouseButton::Left, true);
    CHECK(in.last_device() == InputDevice::Mouse);
    // A pad that is polled every frame must not keep stealing the device: only a CHANGE past the deadzone counts.
    in.on_gamepad_axis(0, GamepadAxis::LeftX, 0.1f);  // drift
    CHECK(in.last_device() == InputDevice::Mouse);
    in.on_gamepad_axis(0, GamepadAxis::LeftX, 0.8f);
    CHECK(in.last_device() == InputDevice::Gamepad);
    in.on_key(Key::B, true);
    in.on_gamepad_axis(0, GamepadAxis::LeftX, 0.8f);  // the same value again, as the next poll feeds it
    CHECK(in.last_device() == InputDevice::Keyboard);
    in.on_gamepad_button(0, GamepadButton::A, true);  // already down: the poll feeds it every frame
    CHECK(in.last_device() == InputDevice::Keyboard);
}

TEST_CASE("pad families come from vendor ids first, names second") {
    CHECK(gamepad_type_from_ids(0x045e, "") == GamepadType::Xbox);
    CHECK(gamepad_type_from_ids(0x054c, "Wireless Controller") == GamepadType::PlayStation);
    CHECK(gamepad_type_from_ids(0x057e, "Pro Controller") == GamepadType::Nintendo);
    CHECK(gamepad_type_from_ids(0x28de, "Steam Deck Controller") == GamepadType::SteamDeck);
    CHECK(gamepad_type_from_ids(0x046d, "Logitech F310") == GamepadType::Generic);
    CHECK(gamepad_type_from_ids(0, "Xbox One Wireless Controller") == GamepadType::Xbox);
    CHECK(gamepad_type_from_ids(0, "DualSense Wireless Controller") == GamepadType::PlayStation);
    CHECK(gamepad_type_from_ids(0, "DualShock 4") == GamepadType::PlayStation);
    CHECK(gamepad_type_from_ids(0, "Nintendo Switch Pro Controller") == GamepadType::Nintendo);
    CHECK(gamepad_type_from_ids(0x046d, "Xbox clone") == GamepadType::Xbox);  // a third party that says so
    CHECK(gamepad_type_from_ids(0x054c, "xbox") == GamepadType::PlayStation);  // the vendor decides
    CHECK(gamepad_type_from_ids(0, "") == GamepadType::Generic);
    GamepadType t{};
    CHECK(gamepad_type_from_name("PlayStation", t));
    CHECK(t == GamepadType::PlayStation);
    CHECK_FALSE(gamepad_type_from_name("ps5", t));
    CHECK(gamepad_type_names().size() == 5);
}

TEST_CASE("a pad's type is kept for connected pads and starts generic") {
    Input in;
    CHECK(in.gamepad_type(0) == GamepadType::Generic);
    in.on_gamepad_connected(0, true);
    in.set_gamepad_type(0, GamepadType::PlayStation);
    in.set_gamepad_type(9, GamepadType::Xbox);  // out of range: ignored
    CHECK(in.gamepad_type(0) == GamepadType::PlayStation);
    CHECK(in.gamepad_type(1) == GamepadType::Generic);
    in.release_all();  // focus lost: the pad disconnects, and comes back with its type
    CHECK(in.gamepad_type(0) == GamepadType::Generic);
    in.on_gamepad_connected(0, true);
    CHECK(in.gamepad_type(0) == GamepadType::PlayStation);
}

TEST_CASE("button names per pad family") {
    struct Row { GamepadType type; const char* binding; const char* label; };
    const Row rows[] = {
        {GamepadType::Xbox, "GamepadA", "A"}, {GamepadType::Xbox, "GamepadLeftShoulder", "LB"},
        {GamepadType::Xbox, "GamepadRightTrigger", "RT"}, {GamepadType::Xbox, "GamepadBack", "View"},
        {GamepadType::Xbox, "GamepadStart", "Menu"},
        {GamepadType::PlayStation, "GamepadA", "Cross"}, {GamepadType::PlayStation, "GamepadB", "Circle"},
        {GamepadType::PlayStation, "GamepadX", "Square"}, {GamepadType::PlayStation, "GamepadY", "Triangle"},
        {GamepadType::PlayStation, "GamepadLeftShoulder", "L1"}, {GamepadType::PlayStation, "GamepadLeftTrigger", "L2"},
        {GamepadType::PlayStation, "GamepadBack", "Create"}, {GamepadType::PlayStation, "GamepadStart", "Options"},
        {GamepadType::PlayStation, "GamepadLeftThumb", "L3"},
        {GamepadType::Nintendo, "GamepadA", "B"}, {GamepadType::Nintendo, "GamepadB", "A"},  // by position: bottom = Nintendo B
        {GamepadType::Nintendo, "GamepadX", "Y"}, {GamepadType::Nintendo, "GamepadY", "X"},
        {GamepadType::Nintendo, "GamepadLeftShoulder", "L"}, {GamepadType::Nintendo, "GamepadRightTrigger", "ZR"},
        {GamepadType::Nintendo, "GamepadStart", "+"}, {GamepadType::Nintendo, "GamepadBack", "-"},
        {GamepadType::SteamDeck, "GamepadA", "A"}, {GamepadType::SteamDeck, "GamepadRightShoulder", "R1"},
        {GamepadType::SteamDeck, "GamepadRightTrigger", "R2"}, {GamepadType::SteamDeck, "GamepadStart", "Menu"},
        {GamepadType::SteamDeck, "GamepadBack", "View"},
        {GamepadType::Generic, "GamepadA", "A"}, {GamepadType::Generic, "GamepadRightShoulder", "RB"},  // the Xbox names
        {GamepadType::Generic, "GamepadLeftTrigger", "LT"},
        {GamepadType::Xbox, "GamepadDpadUp", "D-Pad Up"}, {GamepadType::PlayStation, "GamepadLeftStickLeft", "Left Stick Left"},
        {GamepadType::Nintendo, "GamepadRightStickUp", "Right Stick Up"},
        // keys, the mouse and touch do not depend on the pad
        {GamepadType::PlayStation, "space", "Space"}, {GamepadType::PlayStation, "W", "W"},
        {GamepadType::Nintendo, "MouseLeft", "Left Click"}, {GamepadType::Xbox, "mousemiddle", "Middle Click"},
        {GamepadType::Xbox, "Touch", "Touch"},
    };
    for (const Row& r : rows) {
        CAPTURE(gamepad_type_name(r.type));
        CAPTURE(r.binding);
        CHECK(Input::binding_label(r.binding, r.type) == r.label);
    }
    CHECK(Input::binding_label("GamepadFoo", GamepadType::Xbox).empty());
    CHECK(Input::binding_label("jump", GamepadType::Xbox).empty());  // an action name is not a binding
}

TEST_CASE("every binding has a label for every family") {
    for (const std::string& name : Input::binding_names())
        for (GamepadType t : {GamepadType::Generic, GamepadType::Xbox, GamepadType::PlayStation, GamepadType::Nintendo, GamepadType::SteamDeck}) {
            CAPTURE(name);
            CHECK_FALSE(Input::binding_label(name, t).empty());
        }
}

TEST_CASE("button_name of an action follows the last device and the pad's family") {
    Input in;
    in.set_actions(jump_and_move());
    in.on_gamepad_connected(0, true);
    in.set_gamepad_type(0, GamepadType::PlayStation);
    in.on_key(Key::Space, true);  // the last device is the keyboard
    CHECK(in.button_name("jump") == "Space");
    CHECK(in.button_name("fire") == "Left Click");  // the first keyboard or mouse binding
    in.on_gamepad_button(0, GamepadButton::Y, true);  // now the pad
    CHECK(in.button_name("jump") == "Cross");
    CHECK(in.button_name("fire") == "R2");
    CHECK(in.button_name("left") == "Left Stick Left");
    CHECK(in.button_name("GamepadB") == "Circle");  // a binding name works too
    CHECK(in.button_name("GamepadB", 1) == "B");    // pad 1 is not connected: generic names
    in.set_gamepad_type(0, GamepadType::Nintendo);
    CHECK(in.button_name("jump") == "B");
    CHECK(in.button_name("nope").empty());
    in.rebind("jump", {"Space"});  // no pad binding: fall back to what it has
    CHECK(in.button_name("jump") == "Space");
    in.rebind("jump", {});
    CHECK(in.button_name("jump").empty());
}

TEST_CASE("text input reaches text_utf8 as UTF-8 and is cleared each frame") {
    Input in;
    in.begin_frame();
    for (char32_t c : std::u32string(U"aé€\U0001F600")) in.on_text(c);
    CHECK(in.text_utf8() == "a\xC3\xA9\xE2\x82\xAC\xF0\x9F\x98\x80");
    CHECK(in.text_input().size() == 4);
    CHECK(in.snapshot()["text"] == in.text_utf8());
    in.begin_frame();
    CHECK(in.text_utf8().empty());
}

TEST_CASE("locked mouse movement arrives as a delta without moving the pointer") {
    Input in;
    in.begin_frame();
    in.on_mouse_move({100, 100});
    in.begin_frame();
    in.on_mouse_move({100, 100});  // frozen while locked
    in.on_mouse_delta({3, -2});
    in.on_mouse_delta({1, 1});
    CHECK(in.mouse_position() == Vec2{100, 100});
    CHECK(in.mouse_delta() == Vec2{4, -1});
    CHECK(in.last_device() == InputDevice::Mouse);
}

TEST_CASE("cursor and on-screen keyboard state is kept for the window to apply") {
    Input in;
    CHECK(in.mouse_visible());
    CHECK_FALSE(in.mouse_locked());
    CHECK_FALSE(in.keyboard_shown());
    in.set_mouse_visible(false);
    in.set_mouse_locked(true);
    in.set_keyboard_shown(true);
    CHECK_FALSE(in.mouse_visible());
    CHECK(in.mouse_locked());
    CHECK(in.keyboard_shown());
    in.release_all();  // losing focus does not forget what the game asked for
    CHECK(in.mouse_locked());
}

TEST_CASE("pads announce connect, disconnect and reconnect and keep a stable id") {
    Input in;
    GamepadInfo a;
    a.name = "Wireless Controller";
    a.vendor = 0x054c;
    a.product = 0x09cc;
    a.type = GamepadType::PlayStation;
    a.id = make_gamepad_id(a.vendor, a.product, a.name, "aa:bb");
    CHECK(a.id == "054c:09cc:Wireless Controller#aa:bb");
    CHECK(make_gamepad_id(1, 2, "X", "") == "0001:0002:X");

    in.set_gamepad_info(2, a);
    in.on_gamepad_connected(2, true);
    in.on_gamepad_connected(2, true);  // a backend repeats it every poll: one event
    in.on_gamepad_button(2, GamepadButton::A, true);
    auto events = in.take_gamepad_events();
    REQUIRE(events.size() == 1);
    CHECK(events[0].connected);
    CHECK(events[0].slot == 2);
    CHECK(events[0].info.id == a.id);
    CHECK(events[0].info.name == "Wireless Controller");
    CHECK(events[0].info.type == GamepadType::PlayStation);
    CHECK(in.take_gamepad_events().empty());

    in.on_gamepad_connected(2, false);
    in.on_gamepad_connected(2, false);  // a free slot is reported every poll too: one event
    events = in.take_gamepad_events();
    REQUIRE(events.size() == 1);
    CHECK_FALSE(events[0].connected);
    CHECK(events[0].info.id == a.id);  // the id outlives the pad
    CHECK(in.gamepad_info(2).id == a.id);

    // Back again: announced again, with the same id.
    in.set_gamepad_info(2, a);
    in.on_gamepad_connected(2, true);
    events = in.take_gamepad_events();
    REQUIRE(events.size() == 1);
    CHECK(events[0].connected);
    CHECK(events[0].info.id == a.id);
}

TEST_CASE("losing the focus does not announce a pad that is still plugged in") {
    Input in;
    in.on_gamepad_connected(0, true);
    in.take_gamepad_events();
    in.release_all();  // focus lost: disconnects quietly
    CHECK_FALSE(in.gamepad_connected(0));
    in.on_gamepad_connected(0, true);  // the next poll finds it again
    CHECK(in.gamepad_connected(0));
    CHECK(in.take_gamepad_events().empty());
    in.release_all();
    in.on_gamepad_connected(0, false);  // unplugged while the window was unfocused
    auto events = in.take_gamepad_events();
    REQUIRE(events.size() == 1);
    CHECK_FALSE(events[0].connected);
}

TEST_CASE("a pad that comes back gets its old slot when it is free") {
    Input in;
    GamepadInfo red, blue;
    red.id = "red";
    blue.id = "blue";
    in.set_gamepad_info(0, red);
    in.on_gamepad_connected(0, true);
    in.set_gamepad_info(1, blue);
    in.on_gamepad_connected(1, true);
    in.on_gamepad_connected(0, false);  // red leaves; blue stays in slot 1
    in.on_gamepad_connected(1, false);
    bool occupied[kMaxGamepads] = {};
    CHECK(in.choose_gamepad_slot("blue", occupied) == 1);
    CHECK(in.choose_gamepad_slot("red", occupied) == 0);
    CHECK(in.choose_gamepad_slot("green", occupied) == 0);  // a stranger takes the first free one
    occupied[1] = true;                                      // someone sits in blue's old slot
    CHECK(in.choose_gamepad_slot("blue", occupied) == 0);
    occupied[0] = occupied[2] = occupied[3] = true;
    CHECK(in.choose_gamepad_slot("blue", occupied) == -1);  // full
    CHECK(in.choose_gamepad_slot("blue", std::span<const bool>()) == 1);  // nothing occupied
    in.reset_options();  // a new test forgets the pads
    CHECK(in.choose_gamepad_slot("blue", std::span<const bool>()) == 0);
}

TEST_CASE("a pad nobody described gets an id from its slot; reset_options starts clean") {
    Input in;
    in.on_gamepad_button(3, GamepadButton::B, true);  // a button connects the pad
    auto events = in.take_gamepad_events();
    REQUIRE(events.size() == 1);
    CHECK(events[0].info.id.find("slot 3") != std::string::npos);
    CHECK(events[0].info.name == "Gamepad");
    in.reset_options();
    in.on_gamepad_button(3, GamepadButton::B, true);  // still plugged in the test's eyes, but a new test: announced again
    CHECK(in.take_gamepad_events().size() == 1);
}

// ---------------------------------------------------------------------------
// Players: one device each
// ---------------------------------------------------------------------------
namespace {
const char* const kPlayerActions = R"({
    "left": ["A", "Left", "GamepadDpadLeft", "GamepadLeftStickLeft"],
    "right": ["D", "Right", "GamepadDpadRight", "GamepadLeftStickRight"],
    "up": ["W", "Up", "GamepadDpadUp", "GamepadLeftStickUp"],
    "down": ["S", "Down", "GamepadDpadDown", "GamepadLeftStickDown"],
    "jump": ["Space", "Enter", "GamepadA"],
    "pause": ["Escape", "MouseRight"]
})";

std::string join_lines(const std::vector<std::string>& v) {
    std::string s;
    for (const auto& p : v) s += p + "\n";
    return s;
}
}  // namespace

TEST_CASE("two pads drive two players' move independently, and the global actions hear both") {
    Input in;
    REQUIRE(in.set_actions(Json::parse(kPlayerActions)).empty());
    REQUIRE(in.use_player_device(0, PlayerDevice{0, "", ""}).empty());
    REQUIRE(in.use_player_device(1, PlayerDevice{1, "", ""}).empty());
    in.on_gamepad_connected(0, true);
    in.on_gamepad_connected(1, true);
    in.begin_frame();
    in.on_gamepad_axis(0, GamepadAxis::LeftX, 1.0f);
    in.on_gamepad_button(1, GamepadButton::DpadLeft, true);
    CHECK(in.player_action_down(0, "right"));
    CHECK_FALSE(in.player_action_down(0, "left"));
    CHECK(in.player_action_down(1, "left"));
    CHECK_FALSE(in.player_action_down(1, "right"));
    CHECK(in.player_axis(0, "left", "right") == doctest::Approx(1.0f));
    CHECK(in.player_axis(1, "left", "right") == doctest::Approx(-1.0f));
    CHECK(in.player_vector(0, "left", "right", "down", "up").x == doctest::Approx(1.0f));
    CHECK(in.player_vector(1, "left", "right", "down", "up").x == doctest::Approx(-1.0f));
    CHECK(in.player_action_pressed(1, "left"));
    CHECK_FALSE(in.player_action_pressed(0, "left"));
    // the global actions are unchanged: every device
    CHECK(in.action_down("left"));
    CHECK(in.action_down("right"));
    in.begin_frame();
    in.on_gamepad_button(1, GamepadButton::DpadLeft, false);
    CHECK(in.player_action_released(1, "left"));
    CHECK_FALSE(in.player_action_released(0, "right"));
    CHECK_FALSE(in.player_action_pressed(1, "left"));
}

TEST_CASE("a player with no device reads nothing; the pointer is not shared") {
    Input in;
    REQUIRE(in.set_actions(Json::parse(kPlayerActions)).empty());
    in.on_gamepad_connected(0, true);
    in.begin_frame();
    in.on_key(Key::A, true);
    in.on_mouse_button(MouseButton::Right, true);
    in.on_gamepad_button(0, GamepadButton::A, true);
    CHECK_FALSE(in.player_action_down(0, "left"));
    CHECK_FALSE(in.player_action_down(0, "jump"));
    CHECK_FALSE(in.player_action_pressed(0, "jump"));
    CHECK(in.player_axis(0, "left", "right") == 0.0f);
    // a pad-only player does not read the keyboard; a keys player does not read pads
    REQUIRE(in.use_player_device(0, PlayerDevice{0, "", ""}).empty());
    CHECK_FALSE(in.player_action_down(0, "left"));
    CHECK(in.player_action_down(0, "jump"));
    REQUIRE(in.use_player_device(0, PlayerDevice{-1, "", "all"}).empty());
    CHECK(in.player_action_down(0, "left"));
    CHECK_FALSE(in.player_action_down(0, "jump"));
    CHECK_FALSE(in.player_action_down(0, "pause"));  // MouseRight: the shared pointer, not a player's
    CHECK(in.action_down("pause"));
    // out of range reads nothing and ignores changes
    CHECK_FALSE(in.player_action_down(-1, "left"));
    CHECK_FALSE(in.player_action_down(kMaxPlayers, "left"));
    CHECK_FALSE(in.use_player_device(kMaxPlayers, PlayerDevice{}).empty());
    // an unknown action reads nothing
    CHECK_FALSE(in.player_action_down(0, "nonsense"));
}

TEST_CASE("the keyboard halves: two players on one keyboard read their own keys") {
    Input in;
    REQUIRE(in.set_actions(Json::parse(kPlayerActions)).empty());
    REQUIRE(in.use_player_device(0, PlayerDevice{-1, "", "left"}).empty());
    REQUIRE(in.use_player_device(1, PlayerDevice{-1, "", "right"}).empty());
    in.begin_frame();
    in.on_key(Key::A, true);
    in.on_key(Key::Right, true);
    in.on_key(Key::Space, true);
    CHECK(in.player_action_down(0, "left"));
    CHECK_FALSE(in.player_action_down(0, "right"));
    CHECK(in.player_action_down(1, "right"));
    CHECK_FALSE(in.player_action_down(1, "left"));
    CHECK(in.player_action_down(0, "jump"));  // Space is the left half's
    CHECK_FALSE(in.player_action_down(1, "jump"));
    CHECK(in.player_bindings(0, "jump") == std::vector<std::string>{"Space"});
    CHECK(in.player_bindings(1, "jump") == std::vector<std::string>{"Enter"});
    CHECK(in.player_bindings(1, "left") == std::vector<std::string>{"Left"});
    CHECK(in.player_last_pressed(0) == "A");
    CHECK(in.player_last_pressed(1) == "Right");
}

TEST_CASE("rebinding player 2 leaves player 1 alone, and the global bindings too") {
    Input in;
    REQUIRE(in.set_actions(Json::parse(kPlayerActions)).empty());
    REQUIRE(in.use_player_device(0, PlayerDevice{0, "", "left"}).empty());
    REQUIRE(in.use_player_device(1, PlayerDevice{1, "", "right"}).empty());
    const auto before0 = in.player_bindings(0, "jump");
    REQUIRE(in.player_rebind(1, "jump", {"Backspace"}).empty());
    CHECK(in.player_bindings(1, "jump", "keys") == std::vector<std::string>{"Backspace"});
    CHECK(in.player_bindings(1, "jump", "pad") == std::vector<std::string>{"GamepadA"});  // the other family is untouched
    REQUIRE(in.player_rebind(1, "jump", {"GamepadX"}).empty());
    CHECK(in.player_bindings(1, "jump") == (std::vector<std::string>{"Backspace", "GamepadX"}));
    CHECK(in.player_bindings(0, "jump") == before0);
    CHECK(in.bindings("jump") == (std::vector<std::string>{"Space", "Enter", "GamepadA"}));
    in.begin_frame();
    in.on_key(Key::Backspace, true);
    CHECK(in.player_action_down(1, "jump"));
    CHECK_FALSE(in.player_action_down(0, "jump"));
    CHECK_FALSE(in.action_down("jump"));  // global bindings unchanged
    // reset one action, then all
    REQUIRE(in.player_rebind(1, "left", {"Period"}).empty());
    REQUIRE(in.player_reset(1, "jump").empty());
    CHECK(in.player_bindings(1, "jump") == (std::vector<std::string>{"Enter", "GamepadA"}));
    CHECK(in.player_bindings(1, "left", "keys") == std::vector<std::string>{"Period"});
    REQUIRE(in.player_reset(1).empty());
    CHECK(in.player_bindings(1, "left", "keys") == std::vector<std::string>{"Left"});
}

TEST_CASE("player rebind validates: did you mean, scheme keys, pointer, family") {
    Input in;
    REQUIRE(in.set_actions(Json::parse(kPlayerActions)).empty());
    REQUIRE(in.use_player_device(0, PlayerDevice{0, "", "left"}).empty());
    auto p = in.player_rebind(0, "jmp", {"Space"});
    REQUIRE(p.size() == 1);
    CHECK(join_lines(p).find("jump") != std::string::npos);
    p = in.player_rebind(0, "jump", {"Spce"});
    REQUIRE(p.size() == 1);
    CHECK(join_lines(p).find("Space") != std::string::npos);
    p = in.player_rebind(0, "jump", {"Enter"});  // a key of the right half
    REQUIRE(p.size() == 1);
    CHECK(join_lines(p).find("scheme 'left'") != std::string::npos);
    p = in.player_rebind(0, "jump", {"MouseLeft"});
    REQUIRE(p.size() == 1);
    CHECK(join_lines(p).find("pointer") != std::string::npos);
    p = in.player_rebind(0, "jump", {"GamepadB"}, "keys");
    CHECK(p.size() == 1);
    p = in.player_rebind(0, "jump", {"Z", "GamepadB"});
    CHECK(p.size() == 1);
    p = in.player_rebind(0, "jump", {"Z"}, "hands");
    CHECK(p.size() == 1);
    // all or nothing: nothing changed
    CHECK(in.player_bindings(0, "jump", "keys") == std::vector<std::string>{"Space"});
    CHECK_FALSE(in.player_rebind(7, "jump", {"Z"}).empty());
}

TEST_CASE("use_player_device validates and a player follows its pad id to another slot") {
    Input in;
    REQUIRE(in.set_actions(Json::parse(kPlayerActions)).empty());
    auto p = in.use_player_device(0, PlayerDevice{9, "", ""});
    CHECK(p.size() == 1);
    p = in.use_player_device(0, PlayerDevice{0, "x", ""});
    CHECK(p.size() == 1);
    p = in.use_player_device(0, PlayerDevice{-1, "", "lefft"});
    REQUIRE(p.size() == 1);
    CHECK(p[0].find("left") != std::string::npos);
    CHECK(in.player_device(0) == PlayerDevice{});  // nothing changed

    GamepadInfo red;
    red.name = "Red";
    red.id = make_gamepad_id(1, 1, "Red", "r");
    GamepadInfo blue;
    blue.name = "Blue";
    blue.id = make_gamepad_id(1, 2, "Blue", "b");
    in.set_gamepad_info(0, red);
    in.on_gamepad_connected(0, true);
    in.set_gamepad_info(1, blue);
    in.on_gamepad_connected(1, true);
    REQUIRE(in.use_player_device(0, PlayerDevice{-1, red.id, ""}).empty());
    REQUIRE(in.use_player_device(1, PlayerDevice{-1, blue.id, ""}).empty());
    CHECK(in.player_pad(0) == 0);
    CHECK(in.player_pad(1) == 1);
    in.on_gamepad_connected(0, false);  // both unplug: their players read nothing
    in.on_gamepad_connected(1, false);
    CHECK(in.player_pad(0) == -1);
    in.set_gamepad_info(0, blue);  // blue comes back first, in slot 0
    in.on_gamepad_connected(0, true);
    in.set_gamepad_info(1, red);
    in.on_gamepad_connected(1, true);
    CHECK(in.player_pad(0) == 1);  // follows red
    CHECK(in.player_pad(1) == 0);
    in.begin_frame();
    in.on_gamepad_button(1, GamepadButton::A, true);
    CHECK(in.player_action_down(0, "jump"));
    CHECK_FALSE(in.player_action_down(1, "jump"));
}

TEST_CASE("project key schemes: extends, keys, actions, and errors that teach") {
    Input in;
    REQUIRE(in.set_actions(Json::parse(kPlayerActions)).empty());
    auto p = in.set_key_schemes(Json::parse(R"({
        "pad1": {"extends": "left", "actions": {"jump": ["Z"]}},
        "ijkl": ["I", "J", "K", "L"]
    })"));
    CHECK(p.empty());
    CHECK(in.key_scheme_names() == (std::vector<std::string>{"all", "left", "right", "ijkl", "pad1"}));
    REQUIRE(in.use_player_device(0, PlayerDevice{-1, "", "pad1"}).empty());
    CHECK(in.player_bindings(0, "jump") == std::vector<std::string>{"Z"});
    CHECK(in.player_bindings(0, "left") == std::vector<std::string>{"A"});
    in.begin_frame();
    in.on_key(Key::Z, true);
    CHECK(in.player_action_down(0, "jump"));
    in.on_key(Key::Z, false);
    in.on_key(Key::Space, true);  // in the scheme (left half) but not bound to jump there
    CHECK_FALSE(in.player_action_down(0, "jump"));

    auto bad = in.set_key_schemes(Json::parse(R"({
        "left": ["A"],
        "x": {"extends": "lefft"},
        "y": {"keys": ["Spce"]},
        "z": {"extends": "left", "actions": {"jmp": ["A"]}},
        "w": {"extend": "left"},
        "v": {}
    })"));
    const std::string all = join_lines(bad);
    INFO(all);
    CHECK(bad.size() == 6);  // one problem per scheme; "w" only reports its unknown field
    CHECK(all.find("built-in scheme") != std::string::npos);
    CHECK(all.find("left") != std::string::npos);
    CHECK(all.find("Space") != std::string::npos);
    CHECK(all.find("jump") != std::string::npos);
    CHECK(all.find("extends") != std::string::npos);
    CHECK(in.key_scheme_names().size() == 3);  // none of them was accepted
}

TEST_CASE("player bindings export and import: only what differs, bad entries skipped and reported") {
    Input in;
    REQUIRE(in.set_actions(Json::parse(kPlayerActions)).empty());
    REQUIRE(in.use_player_device(0, PlayerDevice{0, "", "left"}).empty());
    CHECK(in.player_export(0) == Json::object());
    REQUIRE(in.player_rebind(0, "jump", {"X"}).empty());
    REQUIRE(in.player_rebind(0, "jump", {"GamepadY"}).empty());
    Json saved = in.player_export(0);
    CHECK(saved == Json::parse(R"({"keys": {"jump": ["X"]}, "pad": {"jump": ["GamepadY"]}})"));
    REQUIRE(in.player_reset(0).empty());
    CHECK(in.player_export(0) == Json::object());
    CHECK(in.player_import(0, saved).empty());
    CHECK(in.player_bindings(0, "jump") == (std::vector<std::string>{"X", "GamepadY"}));
    auto p = in.player_import(0, Json::parse(R"({"keys": {"jump": ["Q"], "gone": ["A"], "left": ["Nope"]}, "pad": {"jump": ["Q"]}})"));
    CHECK(p.size() == 3);
    CHECK(in.player_bindings(0, "jump", "keys") == std::vector<std::string>{"Q"});
    CHECK(in.player_bindings(0, "jump", "pad") == std::vector<std::string>{"GamepadA"});  // defaults again
    CHECK(in.player_bindings(0, "left", "keys") == std::vector<std::string>{"A"});
}

TEST_CASE("reset_options forgets players; snapshot lists players with a device") {
    Input in;
    REQUIRE(in.set_actions(Json::parse(kPlayerActions)).empty());
    CHECK_FALSE(in.snapshot().contains("players"));
    REQUIRE(in.use_player_device(2, PlayerDevice{-1, "", "right"}).empty());
    in.begin_frame();
    in.on_key(Key::Right, true);
    Json snap = in.snapshot();
    REQUIRE(snap.contains("players"));
    CHECK(snap["players"][0]["player"] == 2);
    CHECK(snap["players"][0]["keys"] == "right");
    CHECK(snap["players"][0]["actionsDown"] == Json::parse(R"(["right"])"));
    in.reset_options();
    CHECK(in.player_device(2) == PlayerDevice{});
    CHECK_FALSE(in.snapshot().contains("players"));
}
