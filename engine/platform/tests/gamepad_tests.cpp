// Gamepad mappings (SDL GameControllerDB lines), the raw -> logical translation and the Android pad state. All of it is
// platform-neutral, so these run on every OS even though only Linux/Android use them at run time.
#include <doctest.h>

#include <string>

#include "fa/platform/android_gamepads.h"
#include "fa/platform/gamepad_mapping.h"

using namespace fa;

namespace {

// A line as pasted from SDL's GameControllerDB (extra fields included).
const char* const kDs4Line =
    "030000004C050000CC09000011810000,PS4 Controller,a:b0,b:b1,back:b8,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,"
    "guide:b10,leftshoulder:b4,leftstick:b11,lefttrigger:a2,leftx:a0,lefty:a1,rightshoulder:b5,rightstick:b12,"
    "righttrigger:a5,rightx:a3,righty:a4,start:b9,x:b3,y:b2,touchpad:b13,misc1:b14,platform:Linux,";

GamepadMapping parse_ok(const std::string& line) {
    auto r = parse_gamepad_mapping(line);
    const std::string why = r.ok() ? std::string() : r.error().to_string();
    INFO(why);
    REQUIRE(r.ok());
    return *r;
}

// The message AND the hint of a rejected line, for substring checks.
std::string error_text(const std::string& line) {
    auto r = parse_gamepad_mapping(line);
    REQUIRE_FALSE(r.ok());
    CHECK_FALSE(r.error().hint.empty());  // errors teach
    return r.error().message + " " + r.error().hint;
}

constexpr const char* kZeroGuid = "00000000000000000000000000000000";

GamepadIdentity identity(unsigned bus, unsigned vendor, unsigned product, unsigned version) {
    GamepadIdentity id;
    id.bus = std::uint16_t(bus);
    id.vendor = std::uint16_t(vendor);
    id.product = std::uint16_t(product);
    id.version = std::uint16_t(version);
    return id;
}

// A real pad of SDL_GameControllerDB that is NOT an Xbox pad: the DragonRise-style "USB Gamepad" (vendor 0x0079, product
// 0x0006, version 0x0107). Its line is a:b2,b:b1,x:b3,y:b0, triggers on the buttons 6 and 7, right stick on axes 3 and 4.
GamepadIdentity generic_usb_pad() { return identity(3, 0x0079, 0x0006, 0x0107); }

}  // namespace

TEST_CASE("a pasted DualShock 4 line parses: guid lower-cased, sources, ignored fields") {
    GamepadMapping m = parse_ok(kDs4Line);
    CHECK(m.guid == "030000004c050000cc09000011810000");
    CHECK(m.name == "PS4 Controller");
    CHECK(m.buttons[size_t(GamepadButton::A)].kind == GamepadSource::Kind::Button);
    CHECK(m.buttons[size_t(GamepadButton::A)].index == 0);
    CHECK(m.buttons[size_t(GamepadButton::X)].index == 3);  // square
    CHECK(m.buttons[size_t(GamepadButton::Y)].index == 2);  // triangle
    CHECK(m.buttons[size_t(GamepadButton::Guide)].index == 10);
    CHECK(m.buttons[size_t(GamepadButton::LeftThumb)].index == 11);
    const GamepadSource& up = m.buttons[size_t(GamepadButton::DpadUp)];
    CHECK(up.kind == GamepadSource::Kind::Hat);
    CHECK(up.index == 0);
    CHECK(up.hatMask == 1);
    CHECK(m.buttons[size_t(GamepadButton::DpadLeft)].hatMask == 8);
    CHECK(m.axes[size_t(GamepadAxis::RightX)].kind == GamepadSource::Kind::Axis);
    CHECK(m.axes[size_t(GamepadAxis::RightX)].index == 3);
    CHECK(m.axes[size_t(GamepadAxis::LeftTrigger)].index == 2);
    CHECK(m.axes[size_t(GamepadAxis::RightTrigger)].index == 5);

    // An empty name and stray commas are tolerated; the fields keep their positions.
    GamepadMapping bare = parse_ok(std::string(kZeroGuid) + ",,a:b7,,");
    CHECK(bare.name.empty());
    CHECK(bare.buttons[size_t(GamepadButton::A)].index == 7);
}

TEST_CASE("DualShock 4 raw events map to the right buttons and axes") {
    GamepadMapper pad(parse_ok(kDs4Line));
    GamepadState st = pad.state();
    CHECK_FALSE(st.buttons[size_t(GamepadButton::A)]);

    pad.set_button(0, true);  // cross
    pad.set_button(2, true);  // triangle
    pad.set_button(3, true);  // square
    pad.set_button(9, true);  // options
    st = pad.state();
    CHECK(st.buttons[size_t(GamepadButton::A)]);
    CHECK(st.buttons[size_t(GamepadButton::Y)]);
    CHECK(st.buttons[size_t(GamepadButton::X)]);
    CHECK(st.buttons[size_t(GamepadButton::Start)]);
    CHECK_FALSE(st.buttons[size_t(GamepadButton::B)]);
    pad.set_button(0, false);
    CHECK_FALSE(pad.state().buttons[size_t(GamepadButton::A)]);

    pad.set_axis(0, 0.25f);   // left stick X
    pad.set_axis(1, 1.0f);    // left stick Y: the joystick API's +Y is down, FactorIA's is up
    pad.set_axis(3, 0.5f);    // right stick X
    pad.set_axis(4, -1.0f);   // right stick Y pushed up
    st = pad.state();
    CHECK(st.axes[size_t(GamepadAxis::LeftX)] == doctest::Approx(0.25f));
    CHECK(st.axes[size_t(GamepadAxis::LeftY)] == doctest::Approx(-1.0f));
    CHECK(st.axes[size_t(GamepadAxis::RightX)] == doctest::Approx(0.5f));
    CHECK(st.axes[size_t(GamepadAxis::RightY)] == doctest::Approx(1.0f));

    // Triggers rest at -1 and reach +1 on the joystick API: 0..1 for the game.
    pad.set_axis(2, -1.0f);
    pad.set_axis(5, 1.0f);
    st = pad.state();
    CHECK(st.axes[size_t(GamepadAxis::LeftTrigger)] == doctest::Approx(0.0f));
    CHECK(st.axes[size_t(GamepadAxis::RightTrigger)] == doctest::Approx(1.0f));
    pad.set_axis(2, 0.0f);
    CHECK(pad.state().axes[size_t(GamepadAxis::LeftTrigger)] == doctest::Approx(0.5f));
}

TEST_CASE("hats drive the D-pad, from a hat mask or from the joystick API's two axes") {
    GamepadMapper pad(parse_ok(kDs4Line));
    pad.set_hat(0, 1 | 2);  // up + right
    GamepadState st = pad.state();
    CHECK(st.buttons[size_t(GamepadButton::DpadUp)]);
    CHECK(st.buttons[size_t(GamepadButton::DpadRight)]);
    CHECK_FALSE(st.buttons[size_t(GamepadButton::DpadDown)]);
    CHECK_FALSE(st.buttons[size_t(GamepadButton::DpadLeft)]);
    pad.set_hat(0, 0);
    CHECK_FALSE(pad.state().buttons[size_t(GamepadButton::DpadUp)]);

    // Axis form: x -1 left / +1 right, y -1 up / +1 down. The other component survives a release.
    pad.set_hat_axis(0, false, 1.0f);
    pad.set_hat_axis(0, true, -1.0f);
    st = pad.state();
    CHECK(st.buttons[size_t(GamepadButton::DpadRight)]);
    CHECK(st.buttons[size_t(GamepadButton::DpadUp)]);
    pad.set_hat_axis(0, false, 0.0f);
    st = pad.state();
    CHECK_FALSE(st.buttons[size_t(GamepadButton::DpadRight)]);
    CHECK(st.buttons[size_t(GamepadButton::DpadUp)]);
    pad.set_hat_axis(0, true, 1.0f);
    pad.set_hat_axis(0, false, -1.0f);
    st = pad.state();
    CHECK(st.buttons[size_t(GamepadButton::DpadDown)]);
    CHECK(st.buttons[size_t(GamepadButton::DpadLeft)]);
    CHECK_FALSE(st.buttons[size_t(GamepadButton::DpadUp)]);

    pad.set_hat(7, 1);        // out of range: ignored
    pad.set_hat_axis(-1, true, 1.0f);
    pad.set_axis(99, 1.0f);
    pad.set_button(300, true);
}

TEST_CASE("half axes, inverted axes and axes read as buttons") {
    GamepadMapper pad(parse_ok(std::string(kZeroGuid) +
        ",Odd pad,lefttrigger:+a1,righttrigger:-a1,leftx:a0~,rightx:a2,a:+a3,b:-a3,x:a4,y:a5~,platform:Linux,"));
    pad.set_axis(1, 0.5f);  // +a1: the positive half, 0..1
    GamepadState st = pad.state();
    CHECK(st.axes[size_t(GamepadAxis::LeftTrigger)] == doctest::Approx(0.5f));
    CHECK(st.axes[size_t(GamepadAxis::RightTrigger)] == doctest::Approx(0.0f));
    pad.set_axis(1, -0.25f);  // -a1: the negative half, as 0..1
    st = pad.state();
    CHECK(st.axes[size_t(GamepadAxis::LeftTrigger)] == doctest::Approx(0.0f));
    CHECK(st.axes[size_t(GamepadAxis::RightTrigger)] == doctest::Approx(0.25f));

    pad.set_axis(0, 0.4f);  // a0~: inverted
    CHECK(pad.state().axes[size_t(GamepadAxis::LeftX)] == doctest::Approx(-0.4f));
    pad.set_axis(2, 0.4f);
    CHECK(pad.state().axes[size_t(GamepadAxis::RightX)] == doctest::Approx(0.4f));

    // An axis read as a button is pressed past the middle of its range.
    pad.set_axis(3, 0.4f);
    st = pad.state();
    CHECK_FALSE(st.buttons[size_t(GamepadButton::A)]);
    CHECK_FALSE(st.buttons[size_t(GamepadButton::B)]);
    pad.set_axis(3, 0.6f);
    CHECK(pad.state().buttons[size_t(GamepadButton::A)]);
    pad.set_axis(3, -0.6f);
    st = pad.state();
    CHECK_FALSE(st.buttons[size_t(GamepadButton::A)]);
    CHECK(st.buttons[size_t(GamepadButton::B)]);
    pad.set_axis(4, 0.1f);  // a full-range axis: pressed above its centre
    CHECK(pad.state().buttons[size_t(GamepadButton::X)]);
    pad.set_axis(4, -0.1f);
    CHECK_FALSE(pad.state().buttons[size_t(GamepadButton::X)]);
    pad.set_axis(5, -0.9f);  // a5~
    CHECK(pad.state().buttons[size_t(GamepadButton::Y)]);
}

TEST_CASE("a Switch Pro: digital triggers, positional face buttons and a hat D-pad") {
    GamepadIdentity id;
    id.bus = 3;
    id.vendor = 0x057e;
    id.product = 0x2009;
    id.version = 0x8111;
    GamepadMapper pad(select_gamepad_mapping({}, id));
    CHECK(pad.mapping().name == "Nintendo Switch Pro Controller");
    pad.set_button(7, true);   // ZL
    pad.set_hat_axis(0, true, -1.0f);  // D-pad up
    pad.set_button(5, true);   // L
    pad.set_button(1, true);   // the button east of the centre: GamepadB
    pad.set_axis(2, 0.5f);     // right stick X
    GamepadState st = pad.state();
    CHECK(st.axes[size_t(GamepadAxis::LeftTrigger)] == 1.0f);
    CHECK(st.axes[size_t(GamepadAxis::RightTrigger)] == 0.0f);
    CHECK(st.buttons[size_t(GamepadButton::DpadUp)]);
    CHECK(st.buttons[size_t(GamepadButton::LeftShoulder)]);
    CHECK(st.buttons[size_t(GamepadButton::B)]);
    CHECK(st.axes[size_t(GamepadAxis::RightX)] == doctest::Approx(0.5f));
    pad.set_button(7, false);
    CHECK(pad.state().axes[size_t(GamepadAxis::LeftTrigger)] == 0.0f);
}

TEST_CASE("malformed mapping lines are rejected with a message that teaches") {
    const std::string head = std::string(kZeroGuid) + ",Test pad,";
    CHECK(error_text("garbage").find("at least a GUID and a name") != std::string::npos);
    CHECK(error_text("1234,Pad,a:b0").find("32 hexadecimal digits") != std::string::npos);
    CHECK(error_text(head + "a").find("has no ':'") != std::string::npos);

    // Unknown element: a "did you mean" and the list of valid names.
    std::string typo = error_text(head + "leftshouldr:b4");
    CHECK(typo.find("Unknown element 'leftshouldr'") != std::string::npos);
    CHECK(typo.find("Did you mean 'leftshoulder'") != std::string::npos);
    CHECK(typo.find("Test pad") != std::string::npos);  // names the pad

    // Bad sources.
    CHECK(error_text(head + "a:x3").find("starts with b (button), a (axis) or h (hat)") != std::string::npos);
    CHECK(error_text(head + "a:b").find("b followed by a number") != std::string::npos);
    CHECK(error_text(head + "a:b999").find("out of range") != std::string::npos);
    CHECK(error_text(head + "leftx:a64").find("out of range") != std::string::npos);
    CHECK(error_text(head + "dpup:h0").find("h<hat>.<mask>") != std::string::npos);
    CHECK(error_text(head + "dpup:h9.1").find("hat 9 is out of range") != std::string::npos);
    CHECK(error_text(head + "dpup:h0.0").find("direction mask") != std::string::npos);
    CHECK(error_text(head + "a:+b3").find("only apply to axes") != std::string::npos);
    CHECK(error_text(head + "a:+").find("nothing after the sign") != std::string::npos);

    // Cuts, reported instead of half-applied.
    CHECK(error_text(head + "leftx:b3").find("stick axis can only read an axis") != std::string::npos);
    CHECK(error_text(head + "righty:h0.1").find("stick axis can only read an axis") != std::string::npos);
    CHECK(error_text(head + "lefttrigger:h0.1").find("cannot read a hat") != std::string::npos);
    // SDL's digital sticks (+leftx:h0.2,-leftx:h0.8...) get their own explanation, not a "did you mean".
    std::string digital = error_text(head + "a:b0,+rightx:b11,-rightx:b8");
    CHECK(digital.find("digital stick") != std::string::npos);
    CHECK(digital.find("Test pad") != std::string::npos);
    CHECK(digital.find("Did you mean") == std::string::npos);

    // The message of the first problem wins and is specific to its field.
    std::string src = error_text(head + "a:b0,x:q1");
    CHECK(src.find("'x:q1'") != std::string::npos);
}

TEST_CASE("a mapping text: comments, blank lines, other platforms and bad lines") {
    const std::string text =
        "# my pads\n"
        "\n"
        "030000004c050000cc09000011810000,PS4 Controller,a:b0,b:b1,platform:Linux,\r\n"
        "030000005e040000ea02000000000000,Xbox,a:b0,b:b1,platform:Windows,\n"       // another OS: skipped silently
        "xinput,Xbox,a:b0,platform:Windows,\n"                                      // would be a bad GUID, but skipped
        "030000004c050000cc09000011810000,Broken,leftshouldr:b4,platform:Linux,\n"  // line 6: rejected
        "00000000000000000000000000000001,No platform field,a:b2";
    GamepadMappingSet set = parse_gamepad_mappings(text, "SDL_GAMECONTROLLERCONFIG", "Linux");
    REQUIRE(set.mappings.size() == 2);
    CHECK(set.mappings[0].name == "PS4 Controller");
    CHECK(set.mappings[1].name == "No platform field");
    REQUIRE(set.problems.size() == 1);
    CHECK(set.problems[0].find("SDL_GAMECONTROLLERCONFIG, line 6:") == 0);
    CHECK(set.problems[0].find("Did you mean 'leftshoulder'") != std::string::npos);

    // Without a platform filter every line counts.
    CHECK(parse_gamepad_mappings("xinput,Xbox,a:b0,platform:Windows,", "x", "").problems.size() == 1);
    CHECK(parse_gamepad_mappings("", "x", "Linux").mappings.empty());
}

TEST_CASE("the built-in mappings all parse, and identify the common pads") {
    // Six lines are written in the source; a line that did not parse would be missing here.
    CHECK(builtin_gamepad_mappings().size() == 6);
    const GamepadMapping& fallback = fallback_gamepad_mapping();
    CHECK(fallback.guid == kZeroGuid);
    CHECK(fallback.buttons[size_t(GamepadButton::A)].kind == GamepadSource::Kind::Button);
    CHECK(fallback.axes[size_t(GamepadAxis::LeftTrigger)].kind == GamepadSource::Kind::Axis);

    auto name_for = [](unsigned bus, unsigned vendor, unsigned product, unsigned version) {
        GamepadIdentity id;
        id.bus = std::uint16_t(bus);
        id.vendor = std::uint16_t(vendor);
        id.product = std::uint16_t(product);
        id.version = std::uint16_t(version);
        return select_gamepad_mapping({}, id).name;
    };
    CHECK(name_for(3, 0x054c, 0x09cc, 0x8111) == "PS4 Controller");  // DualShock 4 v2, USB
    CHECK(name_for(5, 0x054c, 0x09cc, 0x8100) == "PS4 Controller");  // the same over Bluetooth
    CHECK(name_for(5, 0x054c, 0x09cc, 0x7777) == "PS4 Controller");  // a version nobody listed: bus and version ignored
    CHECK(name_for(3, 0x054c, 0x05c4, 0x0100) == "PS4 Controller");  // DualShock 4 v1
    CHECK(name_for(3, 0x054c, 0x0ce6, 0x8111) == "PS5 Controller");  // DualSense
    CHECK(name_for(3, 0x057e, 0x2009, 0x8111) == "Nintendo Switch Pro Controller");
    CHECK(name_for(3, 0x045e, 0x028e, 0x0114) == "Xbox 360 Controller");  // listed in SDL_GameControllerDB
    CHECK(name_for(3, 0xbeef, 0xcafe, 0x0100) == fallback.name);           // listed nowhere: the xpad layout
    CHECK(name_for(0, 0, 0, 0) == fallback.name);

    GamepadIdentity ds4;
    ds4.bus = 3;
    ds4.vendor = 0x054c;
    ds4.product = 0x09cc;
    ds4.version = 0x8111;
    CHECK(gamepad_guid(ds4) == "030000004c050000cc09000011810000");  // SDL's Linux GUID layout
}

TEST_CASE("the xpad fallback keeps the layout the engine always assumed") {
    GamepadMapper pad(fallback_gamepad_mapping());
    pad.set_button(0, true);  // A
    pad.set_button(2, true);  // X
    pad.set_button(3, true);  // Y
    pad.set_button(6, true);  // select -> Back
    pad.set_button(8, true);  // mode -> Guide
    pad.set_axis(2, 1.0f);    // left trigger fully pulled
    pad.set_hat_axis(0, false, -1.0f);
    GamepadState st = pad.state();
    CHECK(st.buttons[size_t(GamepadButton::A)]);
    CHECK(st.buttons[size_t(GamepadButton::X)]);
    CHECK(st.buttons[size_t(GamepadButton::Y)]);
    CHECK(st.buttons[size_t(GamepadButton::Back)]);
    CHECK(st.buttons[size_t(GamepadButton::Guide)]);
    CHECK(st.buttons[size_t(GamepadButton::DpadLeft)]);
    CHECK(st.axes[size_t(GamepadAxis::LeftTrigger)] == doctest::Approx(1.0f));
    CHECK(st.axes[size_t(GamepadAxis::RightTrigger)] == doctest::Approx(0.0f));
}

TEST_CASE("user mappings win over built-in ones, an exact version over a loose one, the later line over the earlier") {
    GamepadIdentity ds4;
    ds4.bus = 3;
    ds4.vendor = 0x054c;
    ds4.product = 0x09cc;
    ds4.version = 0x8111;

    // The user remaps the DualShock 4's cross to B.
    GamepadMappingSet user = parse_gamepad_mappings(
        "030000004c050000cc09000000000000,My PS4,b:b0,platform:Linux,", "SDL_GAMECONTROLLERCONFIG", "Linux");
    REQUIRE(user.mappings.size() == 1);
    GamepadMapping m = select_gamepad_mapping(user.mappings, ds4);
    CHECK(m.name == "My PS4");
    CHECK(m.buttons[size_t(GamepadButton::B)].index == 0);
    CHECK(m.buttons[size_t(GamepadButton::A)].kind == GamepadSource::Kind::None);

    GamepadMappingSet two = parse_gamepad_mappings(
        "030000004c050000cc09000011810000,Exact,a:b0,platform:Linux,\n"
        "030000004c050000cc09000000000000,Loose,a:b0,platform:Linux,\n", "t", "Linux");
    REQUIRE(two.mappings.size() == 2);
    CHECK(select_gamepad_mapping(two.mappings, ds4).name == "Exact");  // exact version, though the loose one is later
    ds4.version = 0x0001;
    CHECK(select_gamepad_mapping(two.mappings, ds4).name == "Loose");

    GamepadMappingSet twice = parse_gamepad_mappings(
        "030000004c050000cc09000000000000,First,a:b0,platform:Linux,\n"
        "030000004c050000cc09000000000000,Second,a:b0,platform:Linux,\n", "t", "Linux");
    CHECK(select_gamepad_mapping(twice.mappings, ds4).name == "Second");

    // A GUID made of a name (vendor and product 0) matches nothing.
    GamepadMappingSet named = parse_gamepad_mappings("6e616d65000000000000000000000000,Named,a:b0,", "t", "Linux");
    GamepadIdentity none;
    CHECK(select_gamepad_mapping(named.mappings, none).guid == kZeroGuid);
}

// ---------------------------------------------------------------------------
// The built-in database (SDL_GameControllerDB, Linux lines) and the user's own mapping file
// ---------------------------------------------------------------------------
TEST_CASE("the embedded SDL_GameControllerDB is indexed once and every line parses, except the digital sticks") {
    const std::string_view text = embedded_gamepad_database_text();
    REQUIRE_FALSE(text.empty());
    GamepadMappingSet all = parse_gamepad_mappings(text, "gamecontrollerdb_linux.txt", "Linux");
    CHECK(all.mappings.size() > 700);
    // The lines FactorIA does not apply are known and explained: sticks driven by buttons or a hat (N64 pads, Joy-Cons)
    // and the "xinput" line that carries no vendor/product ids. A new kind of problem after a database update fails here.
    for (const std::string& problem : all.problems) {
        INFO(problem);
        CHECK((problem.find("digital stick") != std::string::npos || problem.find("'xinput'") != std::string::npos));
    }
    CHECK(all.problems.size() < 30);

    const GamepadMappingDb& db = builtin_gamepad_database();
    CHECK(db.size() > 700);
    CHECK(&db == &builtin_gamepad_database());  // built once
}

TEST_CASE("a generic pad of the database maps its buttons and axes by its own line, not by the Xbox layout") {
    const GamepadIdentity id = generic_usb_pad();
    GamepadMapping m = select_gamepad_mapping({}, id);
    CHECK(m.name == "USB Gamepad");
    CHECK(m.guid == gamepad_guid(id));  // the database's own line, not a fallback or a near miss
    GamepadMapper pad(m);

    pad.set_button(2, true);  // a:b2 (the Xbox layout's button 2 is X)
    GamepadState st = pad.state();
    CHECK(st.buttons[size_t(GamepadButton::A)]);
    CHECK_FALSE(st.buttons[size_t(GamepadButton::X)]);
    pad.set_button(2, false);
    pad.set_button(1, true);  // b:b1
    pad.set_button(3, true);  // x:b3
    pad.set_button(0, true);  // y:b0 (the Xbox layout's button 0 is A)
    pad.set_button(9, true);  // start:b9
    pad.set_button(8, true);  // back:b8
    pad.set_button(4, true);  // leftshoulder:b4
    st = pad.state();
    CHECK(st.buttons[size_t(GamepadButton::B)]);
    CHECK(st.buttons[size_t(GamepadButton::X)]);
    CHECK(st.buttons[size_t(GamepadButton::Y)]);
    CHECK_FALSE(st.buttons[size_t(GamepadButton::A)]);
    CHECK(st.buttons[size_t(GamepadButton::Start)]);
    CHECK(st.buttons[size_t(GamepadButton::Back)]);
    CHECK(st.buttons[size_t(GamepadButton::LeftShoulder)]);

    // Digital triggers on buttons 6 and 7; the right stick on axes 3 and 4; the D-pad as hat 0.
    pad.set_button(7, true);
    pad.set_axis(3, 0.5f);
    pad.set_axis(4, -1.0f);
    pad.set_hat_axis(0, true, -1.0f);
    st = pad.state();
    CHECK(st.axes[size_t(GamepadAxis::LeftTrigger)] == 0.0f);
    CHECK(st.axes[size_t(GamepadAxis::RightTrigger)] == 1.0f);
    CHECK(st.axes[size_t(GamepadAxis::RightX)] == doctest::Approx(0.5f));
    CHECK(st.axes[size_t(GamepadAxis::RightY)] == doctest::Approx(1.0f));
    CHECK(st.buttons[size_t(GamepadButton::DpadUp)]);

    // The same events through the Xbox layout would press A (button 0) and read the triggers off axes: the lookup mattered.
    GamepadMapper xpad(fallback_gamepad_mapping());
    xpad.set_button(0, true);
    CHECK(xpad.state().buttons[size_t(GamepadButton::A)]);
}

TEST_CASE("a GUID nobody lists falls back to the Xbox (xpad) layout") {
    const GamepadIdentity unknown = identity(3, 0xbeef, 0xcafe, 0x0100);
    CHECK_FALSE(builtin_gamepad_database().find(unknown).has_value());
    CHECK(select_gamepad_mapping({}, unknown).guid == kZeroGuid);
    CHECK(select_gamepad_mapping({}, {}, unknown).guid == kZeroGuid);
    CHECK_FALSE(builtin_gamepad_database().find(identity(0, 0, 0, 0)).has_value());  // no ids: nothing to look up
}

TEST_CASE("mapping priority: SDL_GAMECONTROLLERCONFIG, then the user's file, then the built-in database") {
    const GamepadIdentity id = generic_usb_pad();
    auto lines = [&](unsigned version, const char* name, const char* button) {
        GamepadIdentity other = id;
        other.version = std::uint16_t(version);
        GamepadMappingSet set =
            parse_gamepad_mappings(gamepad_guid(other) + "," + name + "," + button + ",platform:Linux,", "t", "Linux");
        REQUIRE(set.mappings.size() == 1);
        return set.mappings;
    };
    const std::vector<GamepadMapping> env = lines(id.version, "Env pad", "a:b7");
    const std::vector<GamepadMapping> file = lines(id.version, "File pad", "a:b6");

    GamepadMapping m = select_gamepad_mapping(env, file, id);
    CHECK(m.name == "Env pad");
    CHECK(m.buttons[size_t(GamepadButton::A)].index == 7);
    m = select_gamepad_mapping({}, file, id);
    CHECK(m.name == "File pad");
    CHECK(m.buttons[size_t(GamepadButton::A)].index == 6);
    m = select_gamepad_mapping({}, {}, id);
    CHECK(m.name == "USB Gamepad");  // the database
    CHECK(m.buttons[size_t(GamepadButton::A)].index == 2);
    CHECK(select_gamepad_mapping(env, id).name == "Env pad");  // the two-argument form is the environment alone

    // A tier outranks the ones below it even with a worse match: the user's word is final. This env line is for another
    // version of the pad (a loose match); the database has the exact one.
    const std::vector<GamepadMapping> looseEnv = lines(0x0999, "Loose env pad", "a:b7");
    CHECK(select_gamepad_mapping(looseEnv, {}, id).name == "Loose env pad");
    // Inside a tier an exact match still beats a loose one.
    std::vector<GamepadMapping> both = looseEnv;
    both.push_back(file.front());
    CHECK(select_gamepad_mapping(both, {}, id).name == "File pad");
}

TEST_CASE("an exact line of the database beats the hand-written one; an unlisted version gets the kernel driver's layout") {
    // A DualShock 4 on the legacy generic HID driver (version 0x0111) numbers its buttons differently (a:b1) from one
    // bound to hid-sony (0x8111, a:b0). The database lists both; the hand-written line is the answer for the rest.
    GamepadMapping legacy = select_gamepad_mapping({}, identity(3, 0x054c, 0x09cc, 0x0111));
    CHECK(legacy.name == "PS4 Controller");
    CHECK(legacy.buttons[size_t(GamepadButton::A)].index == 1);
    GamepadMapping sony = select_gamepad_mapping({}, identity(3, 0x054c, 0x09cc, 0x8111));
    CHECK(sony.buttons[size_t(GamepadButton::A)].index == 0);
    GamepadMapping unlisted = select_gamepad_mapping({}, identity(3, 0x054c, 0x09cc, 0x7777));
    CHECK(unlisted.buttons[size_t(GamepadButton::A)].index == 0);
}

TEST_CASE("a database line FactorIA cannot apply is skipped for the next candidate and reported") {
    const std::string text =
        "# comment\n"
        "\n"
        "030000001111000022220000aaaa0000,Exact,a:b0,platform:Linux,\n"
        "030000001111000022220000bbbb0000,Other version,a:b1,platform:Linux,\n"
        "xinput,No ids,a:b2,platform:Linux,\n"                                   // skipped silently: can never match
        "6e616d65000000000000000000000000,Made of a name,a:b3,platform:Linux,\n"  // vendor and product are 0: same
        "030000001111000022220000cccc0000,Broken,leftshouldr:b4,platform:Linux,\n";  // line 7
    GamepadMappingDb db;
    db.add_text(text, "test db");
    CHECK(db.size() == 3);

    std::vector<std::string> problems;
    CHECK(db.find(identity(3, 0x1111, 0x2222, 0xaaaa), &problems)->name == "Exact");
    CHECK(problems.empty());
    CHECK(db.find(identity(3, 0x1111, 0x2222, 0xbbbb))->name == "Other version");
    CHECK_FALSE(db.find(identity(3, 0x1111, 0x3333, 0xaaaa)).has_value());

    // An unlisted version: the last line would be the pick, but it does not parse, so the line before it is used.
    auto m = db.find(identity(3, 0x1111, 0x2222, 0x1234), &problems);
    REQUIRE(m.has_value());
    CHECK(m->name == "Other version");
    REQUIRE(problems.size() == 1);
    CHECK(problems[0].find("test db, line 7:") == 0);
    CHECK(problems[0].find("Did you mean 'leftshoulder'") != std::string::npos);

    // Only broken candidates: no mapping, so the caller falls back; the problems say why.
    const std::string onlyBroken = "030000001111000044440000aaaa0000,Broken,+leftx:h0.2,-leftx:h0.8,platform:Linux,\n";
    GamepadMappingDb bad;
    bad.add_text(onlyBroken, "bad db");
    problems.clear();
    CHECK_FALSE(bad.find(identity(3, 0x1111, 0x4444, 0xaaaa), &problems).has_value());
    REQUIRE(problems.size() == 1);
    CHECK(problems[0].find("digital stick") != std::string::npos);
}

TEST_CASE("real digital-stick pads of the database: an N64 pad falls back, a Joy-Con takes its next candidate") {
    // The NSO N64 controller is listed three times, each with a stick driven by buttons: nothing to apply.
    std::vector<std::string> problems;
    GamepadMapping m = select_gamepad_mapping({}, {}, identity(3, 0x057e, 0x2019, 0x8111), &problems);
    CHECK(m.guid == kZeroGuid);
    REQUIRE_FALSE(problems.empty());
    CHECK(problems[0].find("digital stick") != std::string::npos);
    CHECK(problems[0].find("SDL_GameControllerDB (built in), line ") == 0);

    // The Joy-Con (L) on USB is a hat-driven stick, but the database also lists it for another bus and version with
    // plain axes: the exact line is reported and skipped, that one is used.
    problems.clear();
    m = select_gamepad_mapping({}, {}, identity(3, 0x057e, 0x2006, 0x0001), &problems);
    CHECK(m.name == "Nintendo Switch Joy-Con (L)");
    CHECK(m.guid != kZeroGuid);
    CHECK(m.axes[size_t(GamepadAxis::LeftX)].kind == GamepadSource::Kind::Axis);
    REQUIRE_FALSE(problems.empty());
    CHECK(problems[0].find("digital stick") != std::string::npos);
}

TEST_CASE("joystick API axes are renumbered the way the mapping format counts them") {
    using K = EvdevAxisRoute::Kind;
    // xpad / hid-sony: X Y Z RX RY RZ then the hat.
    const std::uint8_t xpad[] = {0, 1, 2, 3, 4, 5, 0x10, 0x11};
    auto r = route_evdev_axes(xpad);
    REQUIRE(r.size() == 8);
    for (int i = 0; i < 6; ++i) {
        CHECK(r[size_t(i)].kind == K::Axis);
        CHECK(r[size_t(i)].index == i);
    }
    CHECK(r[6].kind == K::HatX);
    CHECK(r[6].index == 0);
    CHECK(r[7].kind == K::HatY);
    CHECK(r[7].index == 0);

    // A pad with other axes between (THROTTLE = 6) and two hats: the hats do not take axis numbers.
    const std::uint8_t odd[] = {0, 1, 6, 0x10, 0x11, 0x12, 0x13};
    r = route_evdev_axes(odd);
    REQUIRE(r.size() == 7);
    CHECK(r[2].kind == K::Axis);
    CHECK(r[2].index == 2);
    CHECK(r[3].kind == K::HatX);
    CHECK(r[4].kind == K::HatY);
    CHECK(r[5].kind == K::HatX);
    CHECK(r[5].index == 1);
    CHECK(r[6].kind == K::HatY);
    CHECK(r[6].index == 1);
    CHECK(route_evdev_axes({}).empty());
}

TEST_CASE("a Linux pad end to end: DualShock 4 events through the routes into Input") {
    // What gamepad_linux.cpp does, without the kernel: the pad's evdev axes, raw events, feed.
    const std::uint8_t codes[] = {0, 1, 2, 3, 4, 5, 0x10, 0x11};
    const auto routes = route_evdev_axes(codes);
    GamepadMapper pad(select_gamepad_mapping({}, [] {
        GamepadIdentity id;
        id.bus = 3;
        id.vendor = 0x054c;
        id.product = 0x09cc;
        id.version = 0x8111;
        return id;
    }()));
    auto axis_event = [&](int number, float v) {
        const EvdevAxisRoute& e = routes[size_t(number)];
        if (e.kind == EvdevAxisRoute::Kind::Axis) pad.set_axis(e.index, v);
        else pad.set_hat_axis(e.index, e.kind == EvdevAxisRoute::Kind::HatY, v);
    };
    Input in;
    in.begin_frame();
    axis_event(2, -1.0f);  // the INIT events: triggers at rest
    axis_event(5, -1.0f);
    pad.set_button(3, true);  // square
    axis_event(7, -1.0f);     // D-pad up (hat Y -1)
    axis_event(0, -1.0f);     // left stick left
    pad.state().feed(in, 0);
    CHECK(in.gamepad_connected(0));
    CHECK(in.gamepad_down(0, GamepadButton::X));
    CHECK_FALSE(in.gamepad_down(0, GamepadButton::A));
    CHECK(in.gamepad_down(0, GamepadButton::DpadUp));
    CHECK(in.gamepad_raw_axis(0, GamepadAxis::LeftX) == doctest::Approx(-1.0f));
    CHECK(in.gamepad_raw_axis(0, GamepadAxis::LeftTrigger) == doctest::Approx(0.0f));
}

TEST_CASE("an axis the device never reported leaves its element at rest, not in the middle of the range") {
    GamepadMapper pad(fallback_gamepad_mapping());  // names axes 0..5
    GamepadState st = pad.state();
    for (float v : st.axes) CHECK(v == 0.0f);
    pad.set_axis(0, 1.0f);  // only the left stick X ever reports
    st = pad.state();
    CHECK(st.axes[size_t(GamepadAxis::LeftX)] == doctest::Approx(1.0f));
    CHECK(st.axes[size_t(GamepadAxis::LeftTrigger)] == 0.0f);  // a2 never spoke: not 0.5
    CHECK(st.axes[size_t(GamepadAxis::RightY)] == 0.0f);
}

TEST_CASE("a pad that stays plugged in comes back connected after a focus loss, without sending an event") {
    GamepadMapper pad(fallback_gamepad_mapping());
    pad.set_button(0, true);  // A held
    pad.set_axis(0, 0.8f);
    GamepadMapper idle(fallback_gamepad_mapping());  // never touched since it was opened
    Input in;
    pad.state().feed(in, 0);
    idle.state().feed(in, 1);
    REQUIRE(in.gamepad_connected(0));
    REQUIRE(in.gamepad_connected(1));

    in.release_all();  // the window lost focus: Input drops every pad
    CHECK_FALSE(in.gamepad_connected(0));
    CHECK_FALSE(in.gamepad_connected(1));
    CHECK_FALSE(in.gamepad_down(0, GamepadButton::A));

    // Focus is back and the next poll feeds the mirrors again. Neither pad produced an event meanwhile.
    pad.state().feed(in, 0);
    idle.state().feed(in, 1);
    CHECK(in.gamepad_connected(0));
    CHECK(in.gamepad_connected(1));
    CHECK(in.gamepad_down(0, GamepadButton::A));
    CHECK(in.gamepad_raw_axis(0, GamepadAxis::LeftX) == doctest::Approx(0.8f));
    CHECK_FALSE(in.gamepad_down(1, GamepadButton::A));
    CHECK(in.gamepad_raw_axis(2, GamepadAxis::LeftX) == 0.0f);
}

// ---------------------------------------------------------------------------
// Android
// ---------------------------------------------------------------------------
TEST_CASE("Android: which keycodes belong to a gamepad") {
    CHECK(AndroidGamepads::is_gamepad_key(96));    // BUTTON_A
    CHECK(AndroidGamepads::is_gamepad_key(110));   // BUTTON_MODE
    CHECK(AndroidGamepads::is_gamepad_key(188));   // BUTTON_1
    CHECK(AndroidGamepads::is_gamepad_key(203));   // BUTTON_16
    CHECK(AndroidGamepads::is_gamepad_key(19));    // DPAD_UP
    CHECK(AndroidGamepads::is_gamepad_key(23));    // DPAD_CENTER
    CHECK_FALSE(AndroidGamepads::is_gamepad_key(4));    // BACK stays the system's
    CHECK_FALSE(AndroidGamepads::is_gamepad_key(29));   // the A key of a keyboard
    CHECK_FALSE(AndroidGamepads::is_gamepad_key(111));  // ESCAPE
    CHECK_FALSE(AndroidGamepads::is_gamepad_key(204));
}

TEST_CASE("Android: key events become buttons on a pad slot per device, in order of first sight") {
    AndroidGamepads pads;
    CHECK(pads.pad_count() == 0);
    CHECK_FALSE(pads.on_key(5, 4, true));  // BACK: not ours, and it does not conjure a pad
    CHECK(pads.pad_count() == 0);

    CHECK(pads.on_key(42, kAndroidKeyButtonA, true));
    CHECK(pads.on_key(42, kAndroidKeyButtonB, true));
    CHECK(pads.on_key(7, kAndroidKeyButtonX, true));  // a second device: pad 1
    CHECK(pads.on_key(42, kAndroidKeyDpadLeft, true));
    REQUIRE(pads.pad_count() == 2);
    GamepadState a = pads.state(0), b = pads.state(1);
    CHECK(a.buttons[size_t(GamepadButton::A)]);
    CHECK(a.buttons[size_t(GamepadButton::B)]);
    CHECK(a.buttons[size_t(GamepadButton::DpadLeft)]);
    CHECK_FALSE(a.buttons[size_t(GamepadButton::X)]);
    CHECK(b.buttons[size_t(GamepadButton::X)]);
    CHECK_FALSE(b.buttons[size_t(GamepadButton::A)]);

    // Every button.
    const struct { int key; GamepadButton button; } all[] = {
        {kAndroidKeyButtonA, GamepadButton::A}, {kAndroidKeyButtonB, GamepadButton::B},
        {kAndroidKeyButtonX, GamepadButton::X}, {kAndroidKeyButtonY, GamepadButton::Y},
        {kAndroidKeyButtonL1, GamepadButton::LeftShoulder}, {kAndroidKeyButtonR1, GamepadButton::RightShoulder},
        {kAndroidKeyButtonThumbL, GamepadButton::LeftThumb}, {kAndroidKeyButtonThumbR, GamepadButton::RightThumb},
        {kAndroidKeyButtonStart, GamepadButton::Start}, {kAndroidKeyButtonSelect, GamepadButton::Back},
        {kAndroidKeyButtonMode, GamepadButton::Guide}, {kAndroidKeyDpadUp, GamepadButton::DpadUp},
        {kAndroidKeyDpadDown, GamepadButton::DpadDown}, {kAndroidKeyDpadLeft, GamepadButton::DpadLeft},
        {kAndroidKeyDpadRight, GamepadButton::DpadRight}};
    for (const auto& c : all) {
        AndroidGamepads one;
        one.on_key(1, c.key, true);
        CAPTURE(c.key);
        CHECK(one.state(0).buttons[size_t(c.button)]);
        one.on_key(1, c.key, true);  // a repeat
        CHECK(one.state(0).buttons[size_t(c.button)]);
        one.on_key(1, c.key, false);
        CHECK_FALSE(one.state(0).buttons[size_t(c.button)]);
    }

    // Swallowed but unmapped: C, Z, BUTTON_1, DPAD_CENTER.
    AndroidGamepads other;
    for (int key : {kAndroidKeyButtonC, kAndroidKeyButtonZ, kAndroidKeyButton1, kAndroidKeyDpadCenter}) {
        CHECK(other.on_key(1, key, true));
        GamepadState st = other.state(0);
        for (bool down : st.buttons) CHECK_FALSE(down);
    }

    CHECK(pads.state(5).buttons[0] == false);  // a pad that does not exist
}

TEST_CASE("Android: motion events give sticks (+Y flipped), triggers and the hat") {
    AndroidGamepads pads;
    AndroidMotionAxes m;
    m.x = 0.5f;
    m.y = 1.0f;  // Android's +Y is down
    m.z = 0.25f;
    m.rz = -1.0f;
    pads.on_motion(3, m);
    GamepadState st = pads.state(0);
    CHECK(st.axes[size_t(GamepadAxis::LeftX)] == doctest::Approx(0.5f));
    CHECK(st.axes[size_t(GamepadAxis::LeftY)] == doctest::Approx(-1.0f));
    CHECK(st.axes[size_t(GamepadAxis::RightX)] == doctest::Approx(0.25f));
    CHECK(st.axes[size_t(GamepadAxis::RightY)] == doctest::Approx(1.0f));

    // The pads that put the right stick on RX/RY: whichever pair is off centre wins.
    m = AndroidMotionAxes{};
    m.rx = -0.75f;
    m.ry = 0.5f;
    pads.on_motion(3, m);
    st = pads.state(0);
    CHECK(st.axes[size_t(GamepadAxis::RightX)] == doctest::Approx(-0.75f));
    CHECK(st.axes[size_t(GamepadAxis::RightY)] == doctest::Approx(-0.5f));

    // Triggers by either name; the hat and the D-pad keys both press the D-pad.
    m = AndroidMotionAxes{};
    m.ltrigger = 0.4f;
    m.gas = 0.9f;
    m.hatX = -1.0f;
    m.hatY = 1.0f;
    pads.on_motion(3, m);
    st = pads.state(0);
    CHECK(st.axes[size_t(GamepadAxis::LeftTrigger)] == doctest::Approx(0.4f));
    CHECK(st.axes[size_t(GamepadAxis::RightTrigger)] == doctest::Approx(0.9f));
    CHECK(st.buttons[size_t(GamepadButton::DpadLeft)]);
    CHECK(st.buttons[size_t(GamepadButton::DpadDown)]);
    CHECK_FALSE(st.buttons[size_t(GamepadButton::DpadUp)]);
    pads.on_key(3, kAndroidKeyDpadUp, true);
    CHECK(pads.state(0).buttons[size_t(GamepadButton::DpadUp)]);
    m = AndroidMotionAxes{};
    m.brake = 0.6f;
    pads.on_motion(3, m);
    st = pads.state(0);
    CHECK(st.axes[size_t(GamepadAxis::LeftTrigger)] == doctest::Approx(0.6f));
    CHECK_FALSE(st.buttons[size_t(GamepadButton::DpadLeft)]);  // the hat is back at rest
    CHECK(st.buttons[size_t(GamepadButton::DpadUp)]);          // the key is still down
}

TEST_CASE("Android: BUTTON_L2/R2 are the trigger only until the pad shows an analog trigger axis") {
    AndroidGamepads pads;
    pads.on_key(1, kAndroidKeyButtonL2, true);
    pads.on_key(1, kAndroidKeyButtonR2, true);
    CHECK(pads.state(0).axes[size_t(GamepadAxis::LeftTrigger)] == 1.0f);
    CHECK(pads.state(0).axes[size_t(GamepadAxis::RightTrigger)] == 1.0f);
    pads.on_key(1, kAndroidKeyButtonL2, false);
    CHECK(pads.state(0).axes[size_t(GamepadAxis::LeftTrigger)] == 0.0f);

    AndroidMotionAxes m;
    m.ltrigger = 0.3f;  // an analog trigger: from now on its axis rules, the key's click does not jump it to 1
    pads.on_motion(1, m);
    pads.on_key(1, kAndroidKeyButtonL2, true);
    CHECK(pads.state(0).axes[size_t(GamepadAxis::LeftTrigger)] == doctest::Approx(0.3f));
    m.ltrigger = 0.0f;
    pads.on_motion(1, m);
    CHECK(pads.state(0).axes[size_t(GamepadAxis::LeftTrigger)] == 0.0f);  // released, though the key was still down
    CHECK(pads.state(0).axes[size_t(GamepadAxis::RightTrigger)] == 1.0f);  // R2 never had an analog axis
}

TEST_CASE("Android: four slots; a fifth device replaces the pad that has been silent longest") {
    AndroidGamepads pads;
    for (int device = 1; device <= 4; ++device) pads.on_key(device, kAndroidKeyButtonA, true);
    REQUIRE(pads.pad_count() == 4);
    for (int device : {3, 2, 4}) pads.on_key(device, kAndroidKeyButtonB, true);  // device 1 has been silent longest
    pads.on_key(99, kAndroidKeyButtonY, true);
    CHECK(pads.pad_count() == 4);
    GamepadState replaced = pads.state(0);  // device 1 held slot 0
    CHECK(replaced.buttons[size_t(GamepadButton::Y)]);
    CHECK_FALSE(replaced.buttons[size_t(GamepadButton::A)]);  // a fresh pad: the old state is gone
    CHECK(pads.state(1).buttons[size_t(GamepadButton::A)]);   // the others are untouched
    pads.on_key(2, kAndroidKeyButtonX, true);  // device 2 still has its slot
    CHECK(pads.state(1).buttons[size_t(GamepadButton::X)]);
}

TEST_CASE("Android: feeding Input connects every known pad again after a focus loss") {
    AndroidGamepads pads;
    pads.on_key(8, kAndroidKeyButtonA, true);
    AndroidMotionAxes m;
    m.x = -0.5f;
    pads.on_motion(8, m);
    Input in;
    pads.feed(in);
    CHECK(in.gamepad_connected(0));
    CHECK_FALSE(in.gamepad_connected(1));
    CHECK(in.gamepad_down(0, GamepadButton::A));
    in.release_all();
    CHECK_FALSE(in.gamepad_connected(0));
    pads.feed(in);
    CHECK(in.gamepad_connected(0));
    CHECK(in.gamepad_down(0, GamepadButton::A));
    CHECK(in.gamepad_raw_axis(0, GamepadAxis::LeftX) == doctest::Approx(-0.5f));
}

TEST_CASE("Android: the axes a device reports decide what Z and RZ are") {
    using R = AndroidRightStick;
    // DualShock 4, Xbox One and most pads: the right stick is Z/RZ, the triggers have their own axes.
    AndroidLayout l = android_layout_for({.z = true, .rz = true, .ltrigger = true, .rtrigger = true});
    CHECK(l.rightStick == R::ZRz);
    CHECK_FALSE(l.zrzAreTriggers);
    l = android_layout_for({.z = true, .rz = true, .brake = true, .gas = true});  // the trigger axes by their other names
    CHECK(l.rightStick == R::ZRz);
    // The Xbox-like layout: RX/RY is the stick and Z/RZ are the triggers, since nothing else is.
    l = android_layout_for({.z = true, .rz = true, .rx = true, .ry = true});
    CHECK(l.rightStick == R::RxRy);
    CHECK(l.zrzAreTriggers);
    // RX/RY with dedicated triggers: the stick, and no Z/RZ to worry about.
    l = android_layout_for({.rx = true, .ry = true, .ltrigger = true, .rtrigger = true});
    CHECK(l.rightStick == R::RxRy);
    CHECK_FALSE(l.zrzAreTriggers);
    // Both pairs AND dedicated triggers: nobody can say which pair is the stick.
    l = android_layout_for({.z = true, .rz = true, .rx = true, .ry = true, .ltrigger = true, .rtrigger = true});
    CHECK(l.rightStick == R::Unknown);
    CHECK_FALSE(l.zrzAreTriggers);
    // No second stick at all; and half a pair is not a stick.
    CHECK(android_layout_for({}).rightStick == R::None);
    CHECK(android_layout_for({.ltrigger = true, .rtrigger = true}).rightStick == R::None);
    CHECK(android_layout_for({.z = true, .rx = true}).rightStick == R::None);
}

TEST_CASE("Android: a pad with Z/RZ triggers does not push its right stick, and its triggers read 0..1") {
    // An Xbox-like pad: Z/RZ are the triggers and rest at -1; RX/RY is the right stick.
    AndroidMotionAxes m;
    m.z = -1.0f;   // left trigger released
    m.rz = 1.0f;   // right trigger fully pulled
    m.rx = 0.5f;
    m.ry = -0.5f;  // Android's +Y is down: the stick is pushed up

    AndroidGamepads asked;
    asked.on_key(1, kAndroidKeyButtonA, true);
    asked.set_layout(1, android_layout_for({.z = true, .rz = true, .rx = true, .ry = true}));
    asked.on_motion(1, m);
    GamepadState st = asked.state(0);
    CHECK(st.axes[size_t(GamepadAxis::RightX)] == doctest::Approx(0.5f));
    CHECK(st.axes[size_t(GamepadAxis::RightY)] == doctest::Approx(0.5f));
    CHECK(st.axes[size_t(GamepadAxis::LeftTrigger)] == doctest::Approx(0.0f));
    CHECK(st.axes[size_t(GamepadAxis::RightTrigger)] == doctest::Approx(1.0f));
    m.z = 0.0f;  // half pulled
    asked.on_motion(1, m);
    CHECK(asked.state(0).axes[size_t(GamepadAxis::LeftTrigger)] == doctest::Approx(0.5f));

    // The same events on a pad nobody asked: the trigger at rest (-1) wins "further from rest" and pushes the stick.
    m.z = -1.0f;
    AndroidGamepads unasked;
    unasked.on_motion(1, m);
    CHECK(unasked.state(0).axes[size_t(GamepadAxis::RightX)] == doctest::Approx(-1.0f));
    CHECK(unasked.state(0).axes[size_t(GamepadAxis::LeftTrigger)] == 0.0f);

    // Before the pad's first motion event Z/RZ are 0, which must not read as half-pulled triggers.
    AndroidGamepads quiet;
    quiet.on_key(1, kAndroidKeyButtonA, true);
    quiet.set_layout(1, android_layout_for({.z = true, .rz = true, .rx = true, .ry = true}));
    CHECK(quiet.state(0).axes[size_t(GamepadAxis::LeftTrigger)] == 0.0f);
    CHECK(quiet.state(0).axes[size_t(GamepadAxis::RightTrigger)] == 0.0f);
}

TEST_CASE("Android: a pad with Z/RZ as the right stick keeps its dedicated triggers and ignores RX/RY") {
    AndroidGamepads pads;
    pads.on_key(1, kAndroidKeyButtonA, true);
    pads.set_layout(1, android_layout_for({.z = true, .rz = true, .ltrigger = true, .rtrigger = true}));
    AndroidMotionAxes m;
    m.z = 0.25f;
    m.rz = -0.5f;
    m.rx = 0.9f;  // not a stick on this pad: ignored
    m.ltrigger = 0.3f;
    pads.on_motion(1, m);
    GamepadState st = pads.state(0);
    CHECK(st.axes[size_t(GamepadAxis::RightX)] == doctest::Approx(0.25f));
    CHECK(st.axes[size_t(GamepadAxis::RightY)] == doctest::Approx(0.5f));
    CHECK(st.axes[size_t(GamepadAxis::LeftTrigger)] == doctest::Approx(0.3f));

    // A pad with no right stick reports zeros there whatever its other axes do.
    AndroidGamepads none;
    none.on_key(1, kAndroidKeyButtonA, true);
    none.set_layout(1, android_layout_for({.ltrigger = true, .rtrigger = true}));
    none.on_motion(1, m);
    CHECK(none.state(0).axes[size_t(GamepadAxis::RightX)] == 0.0f);
    CHECK(none.state(0).axes[size_t(GamepadAxis::RightY)] == 0.0f);
}

TEST_CASE("Android: layouts are asked for once per pad, and again for the pad that takes a freed slot") {
    AndroidGamepads pads;
    CHECK_FALSE(pads.any_needs_layout());
    pads.on_key(10, kAndroidKeyButtonA, true);
    pads.on_key(20, kAndroidKeyButtonA, true);
    CHECK(pads.any_needs_layout());
    CHECK(pads.needs_layout(0));
    CHECK(pads.needs_layout(1));
    CHECK_FALSE(pads.needs_layout(2));  // no pad there
    pads.set_layout(10, android_layout_for({.z = true, .rz = true}));
    pads.set_layout(20, AndroidLayout{});  // what the glue does when JNI fails: asked, nothing learned
    pads.set_layout(99, AndroidLayout{});  // a device with no slot: ignored
    CHECK_FALSE(pads.any_needs_layout());
    pads.release_device(20);
    pads.on_key(30, kAndroidKeyButtonA, true);  // takes slot 1: a different pad, so it has to be asked
    CHECK(pads.needs_layout(1));
    CHECK_FALSE(pads.needs_layout(0));
}

TEST_CASE("Android: an unplugged pad frees its slot; the others keep theirs") {
    AndroidGamepads pads;
    for (int device : {10, 20, 30}) pads.on_key(device, kAndroidKeyButtonA, true);
    pads.on_key(20, kAndroidKeyButtonX, true);
    REQUIRE(pads.pad_count() == 3);
    CHECK(pads.device_id(0) == 10);
    CHECK(pads.device_id(1) == 20);
    CHECK(pads.device_id(2) == 30);

    Input in;
    pads.feed(in);
    REQUIRE(in.gamepad_connected(1));
    CHECK(in.gamepad_down(1, GamepadButton::X));

    pads.release_device(20);  // InputDevice.getDevice(20) returned null
    CHECK(pads.pad_count() == 2);
    CHECK(pads.device_id(1) == -1);
    CHECK(pads.device_id(0) == 10);  // player 1 and player 3 stay where they were
    CHECK(pads.device_id(2) == 30);
    GamepadState gone = pads.state(1);
    for (bool down : gone.buttons) CHECK_FALSE(down);
    pads.feed(in);
    CHECK_FALSE(in.gamepad_connected(1));  // the game sees the pad leave
    CHECK_FALSE(in.gamepad_down(1, GamepadButton::X));
    CHECK(in.gamepad_connected(0));
    CHECK(in.gamepad_connected(2));
    CHECK(in.gamepad_down(2, GamepadButton::A));

    // The next pad takes the free slot, with nothing left of the old one.
    pads.on_key(40, kAndroidKeyButtonY, true);
    CHECK(pads.device_id(1) == 40);
    CHECK(pads.pad_count() == 3);
    GamepadState fresh = pads.state(1);
    CHECK(fresh.buttons[size_t(GamepadButton::Y)]);
    CHECK_FALSE(fresh.buttons[size_t(GamepadButton::A)]);
    CHECK_FALSE(fresh.buttons[size_t(GamepadButton::X)]);

    // Releasing a device that has no slot, or twice, changes nothing.
    pads.release_device(777);
    pads.release_device(20);
    CHECK(pads.pad_count() == 3);

    // With every pad gone, every slot is free and all four are reported disconnected.
    for (int device : {10, 30, 40}) pads.release_device(device);
    CHECK(pads.pad_count() == 0);
    pads.feed(in);
    for (int i = 0; i < kMaxGamepads; ++i) CHECK_FALSE(in.gamepad_connected(i));
}
