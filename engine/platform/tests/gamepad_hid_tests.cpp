// Windows HID gamepads, the platform-neutral half (fa/platform/gamepad_hid.h): the layout of a report descriptor, the
// report parser, the GUID and the Windows database, the default mapping, the IG_ filter, the slot table and the XInput
// probe schedule. There is no hid.dll here: the caps and reports below are what HidP_* would return for real pads.
#include <doctest.h>

#include <string>
#include <vector>

#include "fa/platform/gamepad_hid.h"

using namespace fa;

namespace {

// A DualShock 4 (USB, report 0x01) as its descriptor declares it: 14 buttons, X Y Z Rz (sticks), Rx Ry (L2 R2), all
// 8-bit 0..255, a hat 0..7 (null state 8), and a vendor-defined value that is no axis.
std::vector<HidButtonCap> ds4_buttons() { return {{kHidPageButton, 1, 14}}; }
std::vector<HidValueCap> ds4_values() {
    return {
        // Declared in the descriptor's order (X Y Z Rz, then the hat, then Rx Ry), not DirectInput's.
        {kHidPageGenericDesktop, kHidUsageX, kHidUsageX, 8, 1, 0, 255},
        {kHidPageGenericDesktop, kHidUsageY, kHidUsageY, 8, 1, 0, 255},
        {kHidPageGenericDesktop, kHidUsageZ, kHidUsageZ, 8, 1, 0, 255},
        {kHidPageGenericDesktop, kHidUsageRz, kHidUsageRz, 8, 1, 0, 255},
        {kHidPageGenericDesktop, kHidUsageHatSwitch, kHidUsageHatSwitch, 4, 1, 0, 7},
        {kHidPageGenericDesktop, kHidUsageRx, kHidUsageRx, 8, 1, 0, 255},
        {kHidPageGenericDesktop, kHidUsageRy, kHidUsageRy, 8, 1, 0, 255},
        {0xff00, 0x20, 0x20, 8, 54, 0, 255},  // vendor page: ignored
    };
}

HidLayoutValue value(std::uint16_t usage, std::uint16_t bits, std::int32_t min, std::int32_t max) {
    return {usage, bits, min, max};
}

using SlotKey = GamepadSlotTable::Key;
SlotKey xinput(int i) { return {GamepadSlotTable::Source::XInput, std::uint64_t(i)}; }
SlotKey hid(std::uint64_t handle) { return {GamepadSlotTable::Source::Hid, handle}; }

}  // namespace

TEST_CASE("HID layout: buttons by usage, axes in DirectInput's order, the first hat, unknown pages ignored") {
    const std::vector<HidButtonCap> buttons = ds4_buttons();
    const std::vector<HidValueCap> values = ds4_values();
    const HidLayout layout = make_hid_layout(buttons, values);
    REQUIRE(layout.buttons.size() == 14);
    CHECK(layout.buttons.front() == 1);  // usage 1 is raw button 0
    CHECK(layout.buttons.back() == 14);
    REQUIRE(layout.axes.size() == 6);
    const std::uint16_t order[] = {kHidUsageX, kHidUsageY, kHidUsageZ, kHidUsageRx, kHidUsageRy, kHidUsageRz};
    for (size_t i = 0; i < 6; ++i) CHECK(layout.axes[i].usage == order[i]);
    REQUIRE(layout.hats.size() == 1);
    CHECK(layout.hats[0].logicalMax == 7);

    // Ranges, duplicates, a second hat, sliders past the second, arrays of values and buttons of another page.
    const std::vector<HidButtonCap> more = {{kHidPageButton, 5, 8}, {kHidPageButton, 1, 6}, {0x0c, 1, 3}};
    const std::vector<HidValueCap> morev = {
        {kHidPageGenericDesktop, kHidUsageX, kHidUsageRz, 16, 1, -32768, 32767},  // a range: six axes
        {kHidPageGenericDesktop, kHidUsageWheel, kHidUsageWheel, 8, 1, 0, 255},
        {kHidPageGenericDesktop, kHidUsageSlider, kHidUsageDial, 8, 1, 0, 255},
        {kHidPageGenericDesktop, kHidUsageHatSwitch, kHidUsageHatSwitch, 4, 1, 1, 8},
        {kHidPageGenericDesktop, kHidUsageHatSwitch, kHidUsageHatSwitch, 4, 1, 0, 3},
        {kHidPageGenericDesktop, kHidUsageX, kHidUsageX, 8, 1, 0, 255},  // X again: the first one stays
        {kHidPageGenericDesktop, 0x40, 0x40, 8, 4, 0, 255},              // an array of values: not an axis
    };
    const HidLayout l2 = make_hid_layout(more, morev);
    CHECK(l2.buttons == std::vector<std::uint16_t>{1, 2, 3, 4, 5, 6, 7, 8});
    REQUIRE(l2.axes.size() == 8);  // six axes + two sliders (Slider, Dial); Wheel is a third slider: dropped
    CHECK(l2.axes[0].bitSize == 16);
    CHECK(l2.axes[6].usage == kHidUsageSlider);
    CHECK(l2.axes[7].usage == kHidUsageDial);
    REQUIRE(l2.hats.size() == 1);
    CHECK(l2.hats[0].logicalMin == 1);

    CHECK(make_hid_layout({}, {}).empty());
}

TEST_CASE("HID values: axes scaled by the logical range, signed values sign-extended, a broken maximum read unsigned") {
    const HidLayoutValue u8 = value(kHidUsageX, 8, 0, 255);
    CHECK(hid_axis_value(0, u8) == -1.0f);
    CHECK(hid_axis_value(255, u8) == 1.0f);
    CHECK(hid_axis_value(128, u8) == doctest::Approx(0.0f).epsilon(0.01));
    CHECK(hid_axis_value(1000, u8) == doctest::Approx(hid_axis_value(1000 & 0xff, u8)));  // bits past the size: masked

    const HidLayoutValue s16 = value(kHidUsageX, 16, -32768, 32767);
    CHECK(hid_axis_value(0x8000, s16) == -1.0f);  // HidP_GetUsageValue hands the bits over: 0x8000 is -32768
    CHECK(hid_axis_value(0x7fff, s16) == 1.0f);
    CHECK(hid_axis_value(0, s16) == doctest::Approx(0.0f).epsilon(0.001));
    CHECK(hid_axis_value(0xffff, s16) == doctest::Approx(0.0f).epsilon(0.001));  // -1

    const HidLayoutValue broken = value(kHidUsageX, 16, 0, -1);  // 0..65535 written in two bytes
    CHECK(hid_axis_value(0, broken) == -1.0f);
    CHECK(hid_axis_value(0xffff, broken) == 1.0f);
    CHECK(hid_axis_value(0x8000, broken) == doctest::Approx(0.0f).epsilon(0.001));

    CHECK(hid_axis_value(5, value(kHidUsageX, 8, 3, 3)) == 0.0f);  // no range: at rest
    CHECK(hid_axis_value(5, value(kHidUsageX, 0, 0, 1)) == 1.0f);  // bit size 0 counts as 1 bit
}

TEST_CASE("HID hats: eight positions clockwise from up, four positions, and the null state centred") {
    const HidLayoutValue eight = value(kHidUsageHatSwitch, 4, 0, 7);
    const int want[8] = {1, 3, 2, 6, 4, 12, 8, 9};
    for (std::uint32_t i = 0; i < 8; ++i) CHECK(hid_hat_mask(i, eight) == want[i]);
    CHECK(hid_hat_mask(8, eight) == 0);
    CHECK(hid_hat_mask(15, eight) == 0);

    const HidLayoutValue oneBased = value(kHidUsageHatSwitch, 4, 1, 8);
    CHECK(hid_hat_mask(1, oneBased) == 1);
    CHECK(hid_hat_mask(3, oneBased) == 2);
    CHECK(hid_hat_mask(0, oneBased) == 0);  // below the range: centred

    const HidLayoutValue four = value(kHidUsageHatSwitch, 2, 0, 3);
    CHECK(hid_hat_mask(0, four) == 1);
    CHECK(hid_hat_mask(1, four) == 2);
    CHECK(hid_hat_mask(2, four) == 4);
    CHECK(hid_hat_mask(3, four) == 8);
}

TEST_CASE("the Windows GUID of a HID pad is SDL's DirectInput one, and the built-in Windows lines map a DualShock 4") {
    const GamepadIdentity id = windows_hid_identity(0x054c, 0x09cc, "Wireless Controller");
    CHECK(gamepad_guid(id) == "030000004c050000cc09000000000000");
    CHECK(id.name == "Wireless Controller");

    std::optional<GamepadMapping> found = find_gamepad_mapping({}, {}, id, builtin_windows_gamepad_database());
    REQUIRE(found.has_value());
    CHECK(found->name == "PS4 Controller");
    CHECK(found->guid == gamepad_guid(id));  // an exact line, not a near miss

    // A report: Cross (button usage 2: b1, the line's a), R1 (usage 6: b5), the left stick right and up, the right stick
    // (Z) left, L2 (Rx: a3) fully pulled, the hat at down-left.
    const std::vector<HidButtonCap> buttons = ds4_buttons();
    const std::vector<HidValueCap> values = ds4_values();
    const HidLayout layout = make_hid_layout(buttons, values);
    GamepadMapper pad(*found);
    HidReport r;
    r.hasButtons = true;
    r.pressed = {2, 6};
    r.values = {{kHidUsageX, 255},  {kHidUsageY, 0},  {kHidUsageZ, 0},         {kHidUsageRz, 128},
                {kHidUsageRx, 255}, {kHidUsageRy, 0}, {kHidUsageHatSwitch, 5}, {0x99, 7}};
    apply_hid_report(layout, r, pad);
    GamepadState st = pad.state();
    CHECK(st.buttons[size_t(GamepadButton::A)]);
    CHECK(st.buttons[size_t(GamepadButton::RightShoulder)]);
    CHECK_FALSE(st.buttons[size_t(GamepadButton::X)]);  // Square is b0: not pressed
    CHECK(st.axes[size_t(GamepadAxis::LeftX)] == 1.0f);
    CHECK(st.axes[size_t(GamepadAxis::LeftY)] == 1.0f);  // HID's Y grows downwards; FactorIA's +Y is up
    CHECK(st.axes[size_t(GamepadAxis::RightX)] == -1.0f);
    CHECK(st.axes[size_t(GamepadAxis::RightY)] == doctest::Approx(0.0f).epsilon(0.01));
    CHECK(st.axes[size_t(GamepadAxis::LeftTrigger)] == 1.0f);
    CHECK(st.axes[size_t(GamepadAxis::RightTrigger)] == 0.0f);
    CHECK(st.buttons[size_t(GamepadButton::DpadDown)]);
    CHECK(st.buttons[size_t(GamepadButton::DpadLeft)]);
    CHECK_FALSE(st.buttons[size_t(GamepadButton::DpadUp)]);

    // A report without the buttons (they live in another report) and without the sticks keeps both as they were.
    HidReport other;
    other.values = {{kHidUsageRx, 0}};
    apply_hid_report(layout, other, pad);
    st = pad.state();
    CHECK(st.buttons[size_t(GamepadButton::A)]);
    CHECK(st.axes[size_t(GamepadAxis::LeftX)] == 1.0f);
    CHECK(st.axes[size_t(GamepadAxis::LeftTrigger)] == 0.0f);

    // A report with the buttons and none down releases them all.
    HidReport released;
    released.hasButtons = true;
    apply_hid_report(layout, released, pad);
    CHECK_FALSE(pad.state().buttons[size_t(GamepadButton::A)]);
    released.clear();
    CHECK_FALSE(released.hasButtons);
}

TEST_CASE(
    "the embedded Windows SDL_GameControllerDB: every line parses except the digital sticks, the pads are there") {
    const std::string_view text = embedded_windows_gamepad_database_text();
    REQUIRE_FALSE(text.empty());
    GamepadMappingSet all = parse_gamepad_mappings(text, "gamecontrollerdb_windows.txt", "Windows");
    CHECK(all.mappings.size() > 800);
    for (const std::string& problem : all.problems) {
        INFO(problem);
        CHECK((problem.find("digital stick") != std::string::npos || problem.find("'xinput'") != std::string::npos));
    }
    CHECK(all.problems.size() < 30);
    CHECK(parse_gamepad_mappings(text, "gamecontrollerdb_windows.txt", "Linux").mappings.empty());  // Windows only

    const GamepadMappingDb& db = builtin_windows_gamepad_database();
    CHECK(db.size() > 800);
    CHECK(&db == &builtin_windows_gamepad_database());  // built once
    struct Pad {
        std::uint16_t vendor, product;
        const char* name;
    };
    for (const Pad& p : {Pad{0x054c, 0x05c4, "PS4 Controller"}, Pad{0x054c, 0x0ce6, "PS5 Controller"},
                         Pad{0x057e, 0x2009, "Nintendo Switch Pro Controller"}}) {
        INFO(p.name);
        std::optional<GamepadMapping> m = db.find(windows_hid_identity(p.vendor, p.product, {}));
        REQUIRE(m.has_value());
        CHECK(m->name == p.name);
    }
    // The Linux database does not know Windows numbering: a DualShock 4 there has another line.
    CHECK(builtin_gamepad_database()
              .find(windows_hid_identity(0x054c, 0x09cc, {}))
              ->buttons[size_t(GamepadButton::A)]
              .index == 0);
    CHECK(db.find(windows_hid_identity(0x054c, 0x09cc, {}))->buttons[size_t(GamepadButton::A)].index == 1);
}

TEST_CASE("user lines win over the Windows database; a pad nobody lists gets no line") {
    const GamepadIdentity ds4 = windows_hid_identity(0x054c, 0x09cc, {});
    auto user = parse_gamepad_mapping(
        "030000004c050000cc09000000000000,My DS4,a:b0,b:b1,x:b2,y:b3,leftx:a0,lefty:a1,platform:Windows,");
    REQUIRE(user.ok());
    const std::vector<GamepadMapping> file = {*user};
    std::optional<GamepadMapping> m = find_gamepad_mapping({}, file, ds4, builtin_windows_gamepad_database());
    REQUIRE(m.has_value());
    CHECK(m->name == "My DS4");
    CHECK_FALSE(
        find_gamepad_mapping({}, {}, windows_hid_identity(0xbeef, 0xcafe, {}), builtin_windows_gamepad_database())
            .has_value());
}

TEST_CASE("the default HID mapping is built from the pad's own layout") {
    SUBCASE("Z/Rz right stick, Rx/Ry triggers, a hat") {
        const std::vector<HidButtonCap> buttons = ds4_buttons();
        const std::vector<HidValueCap> values = ds4_values();
        const HidLayout layout = make_hid_layout(buttons, values);
        const GamepadMapping m = default_hid_gamepad_mapping(layout);
        CHECK(m.guid == "00000000000000000000000000000000");
        GamepadMapper pad(m);
        HidReport r;
        r.hasButtons = true;
        r.pressed = {1, 10, 13};  // b0 (A), b9 (start), b12 (guide)
        r.values = {{kHidUsageZ, 255}, {kHidUsageRz, 0}, {kHidUsageRx, 255}, {kHidUsageHatSwitch, 2}};
        apply_hid_report(layout, r, pad);
        const GamepadState st = pad.state();
        CHECK(st.buttons[size_t(GamepadButton::A)]);
        CHECK(st.buttons[size_t(GamepadButton::Start)]);
        CHECK(st.buttons[size_t(GamepadButton::Guide)]);
        CHECK(st.axes[size_t(GamepadAxis::RightX)] == 1.0f);
        CHECK(st.axes[size_t(GamepadAxis::RightY)] == 1.0f);  // Rz 0 is up
        CHECK(st.axes[size_t(GamepadAxis::LeftTrigger)] == 1.0f);
        CHECK(st.axes[size_t(GamepadAxis::RightTrigger)] == 0.0f);  // never reported: at rest
        CHECK(st.buttons[size_t(GamepadButton::DpadRight)]);
    }
    SUBCASE("no Z/Rz pair: the right stick on Rx/Ry; one trigger axis is not a pair, so the triggers are buttons") {
        const std::vector<HidButtonCap> buttons = {{kHidPageButton, 1, 10}};
        const std::vector<HidValueCap> values = {
            {kHidPageGenericDesktop, kHidUsageX, kHidUsageY, 16, 1, -32768, 32767},
            {kHidPageGenericDesktop, kHidUsageRx, kHidUsageRy, 16, 1, -32768, 32767},
            {kHidPageGenericDesktop, kHidUsageZ, kHidUsageZ, 8, 1, 0, 255},  // both triggers on one axis
        };
        const GamepadMapping m = default_hid_gamepad_mapping(make_hid_layout(buttons, values));
        // Raw axes: X0 Y1 Z2 Rx3 Ry4.
        CHECK(m.axes[size_t(GamepadAxis::RightX)].index == 3);
        CHECK(m.axes[size_t(GamepadAxis::RightY)].index == 4);
        CHECK(m.axes[size_t(GamepadAxis::LeftTrigger)].kind == GamepadSource::Kind::Button);
        CHECK(m.axes[size_t(GamepadAxis::LeftTrigger)].index == 6);
        CHECK(m.axes[size_t(GamepadAxis::RightTrigger)].index == 7);
    }
    SUBCASE("six axes: Z/Rz is the right stick and Rx/Ry the triggers (the DualShock order)") {
        const std::vector<HidValueCap> values = {
            {kHidPageGenericDesktop, kHidUsageX, kHidUsageRz, 8, 1, 0, 255},
        };
        const GamepadMapping m = default_hid_gamepad_mapping(make_hid_layout({}, values));
        CHECK(m.axes[size_t(GamepadAxis::RightX)].index == 2);        // Z
        CHECK(m.axes[size_t(GamepadAxis::RightY)].index == 5);        // Rz
        CHECK(m.axes[size_t(GamepadAxis::LeftTrigger)].index == 3);   // Rx
        CHECK(m.axes[size_t(GamepadAxis::RightTrigger)].index == 4);  // Ry
    }
    SUBCASE("a pad with only X/Y and 12 buttons: digital triggers on buttons 6 and 7, no right stick, no D-pad") {
        const std::vector<HidButtonCap> buttons = {{kHidPageButton, 1, 12}};
        const std::vector<HidValueCap> values = {{kHidPageGenericDesktop, kHidUsageX, kHidUsageY, 8, 1, 0, 255}};
        const GamepadMapping m = default_hid_gamepad_mapping(make_hid_layout(buttons, values));
        CHECK(m.axes[size_t(GamepadAxis::LeftTrigger)].kind == GamepadSource::Kind::Button);
        CHECK(m.axes[size_t(GamepadAxis::LeftTrigger)].index == 6);
        CHECK(m.axes[size_t(GamepadAxis::RightTrigger)].index == 7);
        CHECK(m.axes[size_t(GamepadAxis::RightX)].kind == GamepadSource::Kind::None);
        CHECK(m.buttons[size_t(GamepadButton::DpadUp)].kind == GamepadSource::Kind::None);
        CHECK(m.buttons[size_t(GamepadButton::Guide)].kind ==
              GamepadSource::Kind::None);  // b12: the pad has 12 (b0..b11)
        CHECK(m.buttons[size_t(GamepadButton::RightThumb)].index == 11);
    }
}

TEST_CASE("XInput's own pads are told apart by IG_ in their device path") {
    CHECK(hid_path_is_xinput(
        R"(\\?\HID#VID_045E&PID_02FF&IG_00#7&2f2b5b6a&0&0000#{4d1e55b2-f16f-11cf-88cb-001111000030})"));
    CHECK(hid_path_is_xinput(R"(\\?\hid#vid_045e&pid_0b13&ig_00#...)"));
    CHECK_FALSE(hid_path_is_xinput(
        R"(\\?\HID#VID_054C&PID_09CC&MI_03#8&1b0e0b1&0&0000#{4d1e55b2-f16f-11cf-88cb-001111000030})"));
    CHECK_FALSE(hid_path_is_xinput(
        R"(\\?\HID#{00001124-0000-1000-8000-00805f9b34fb}_VID&0002054c_PID&0ce6#9&2a3e&0&0000#{4d1e55b2})"));
    CHECK_FALSE(hid_path_is_xinput("IG"));
    CHECK_FALSE(hid_path_is_xinput(""));
}

TEST_CASE("a generic HID pad has no driver and says why it cannot rumble") {
    CHECK(std::string(kHidRumbleWhy).find("XInput") != std::string::npos);
    CHECK(std::string(kHidRumbleWhy).find("DualSense") != std::string::npos);
    CHECK(make_hid_pad_driver(0xbeef, 0xcafe, HidTransport::Usb) == nullptr);
    CHECK(make_hid_pad_driver(0x054c, 0x0268, HidTransport::Usb) == nullptr);  // a DualShock 3: no driver
}

TEST_CASE("pad slots: stable while connected, gaps filled, XInput and HID mixed, a fifth device waits") {
    GamepadSlotTable t;
    t.add(xinput(0));
    t.add(hid(0x1000));
    t.add(xinput(1));
    CHECK(t.slot_of(xinput(0)) == -1);  // waiting until assign()
    CHECK(t.assign() == 3);
    CHECK(t.slot_of(xinput(0)) == 0);
    CHECK(t.slot_of(hid(0x1000)) == 1);
    CHECK(t.slot_of(xinput(1)) == 2);
    CHECK(t.owner(1) == hid(0x1000));
    CHECK_FALSE(t.owner(3).has_value());
    CHECK_FALSE(t.owner(-1).has_value());
    CHECK_FALSE(t.owner(kMaxGamepads).has_value());

    // The HID pad leaves: the others keep their slots, and the next device fills the gap.
    const std::uint32_t gen1 = t.generation(1);
    t.remove(hid(0x1000));
    CHECK_FALSE(t.owner(1).has_value());
    CHECK(t.generation(1) != gen1);
    CHECK(t.slot_of(xinput(0)) == 0);
    CHECK(t.slot_of(xinput(1)) == 2);
    t.add(hid(0x2000));
    t.assign();
    CHECK(t.slot_of(hid(0x2000)) == 1);
    t.add(hid(0x2000));  // already known: nothing changes
    CHECK_FALSE(t.has_waiting());

    // Full: a fifth device waits, and takes the first slot that frees up.
    t.add(hid(0x3000));
    t.add(hid(0x4000));
    CHECK(t.assign() == 1);
    CHECK(t.slot_of(hid(0x3000)) == 3);
    CHECK(t.slot_of(hid(0x4000)) == -1);
    CHECK(t.has_waiting());
    CHECK(t.assign() == 0);
    t.remove(xinput(0));
    CHECK(t.assign() == 1);
    CHECK(t.slot_of(hid(0x4000)) == 0);

    // A waiting device that goes away leaves the queue.
    t.add(hid(0x5000));
    t.remove(hid(0x5000));
    CHECK_FALSE(t.has_waiting());
    CHECK(t.generation(-1) == 0);
}

TEST_CASE("pad slots: a device takes the slot it prefers when free, else the lowest free one") {
    GamepadSlotTable t;
    t.add(hid(1));
    t.add(hid(2));
    t.add(hid(3));
    t.assign([&](const SlotKey& key, std::span<const bool> occupied) {
        CHECK(occupied.size() == size_t(kMaxGamepads));
        if (key == hid(1)) return 2;  // free: taken
        if (key == hid(2)) return 2;  // taken by now: the lowest free (0)
        return 99;                    // out of range: the lowest free (1)
    });
    CHECK(t.slot_of(hid(1)) == 2);
    CHECK(t.slot_of(hid(2)) == 0);
    CHECK(t.slot_of(hid(3)) == 1);
}

TEST_CASE("empty XInput slots are probed at a low rate, and in a short burst after a device notification") {
    GamepadProbeSchedule s;
    int probes = 0;
    CHECK(s.tick());  // the first poll probes
    for (unsigned i = 1; i < GamepadProbeSchedule::kIdleEvery * 10; ++i) probes += s.tick() ? 1 : 0;
    CHECK(probes == 9);  // once per kIdleEvery polls, not every poll

    s.notify();
    int burst = 0;
    for (unsigned i = 0; i < GamepadProbeSchedule::kBurstLength; ++i) burst += s.tick() ? 1 : 0;
    CHECK(burst == int(GamepadProbeSchedule::kBurstLength / GamepadProbeSchedule::kBurstEvery));
    CHECK(burst >= 4);
    s.notify();
    CHECK(s.tick());  // at once after a notification
}
