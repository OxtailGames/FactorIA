// Windows HID gamepads, the platform-neutral half: everything gamepad_win32.cpp decides about a HID pad that does not need
// a Windows header, so every OS unit-tests it (engine/platform/tests/gamepad_hid_tests.cpp).
//
// What a HID pad is to the engine:
//   - Its layout (make_hid_layout): the buttons, axes and hat its report descriptor declares (the caps HidP_GetButtonCaps
//     and HidP_GetValueCaps return), numbered the way DirectInput numbers them, because SDL_GameControllerDB's
//     platform:Windows lines were written against SDL's DirectInput driver: buttons by ascending usage (usage 1 is b0 on
//     nearly every pad), axes in DirectInput's order X, Y, Z, Rx, Ry, Rz, then up to two sliders (Slider, Dial, Wheel),
//     and the first hat switch as h0.
//   - Its reports (apply_hid_report): what HidP_GetUsages (the buttons down) and HidP_GetUsageValue (each axis and the
//     hat) read from one input report, fed to a GamepadMapper. Axes are scaled by the descriptor's logical minimum and
//     maximum to -1..1; the hat becomes SDL's direction bits.
//   - Its GUID (windows_hid_identity + gamepad_guid): bus 0x03, vendor, product, version 0, the GUID SDL's DirectInput
//     driver gives every pad and so the one every platform:Windows line carries.
//   - Its mapping: SDL_GAMECONTROLLERCONFIG, then the project's gamecontrollerdb.txt, then the built-in Windows lines
//     (builtin_windows_gamepad_database), then a default built from its own layout (default_hid_gamepad_mapping).
//   - Its slot (GamepadSlotTable): XInput pads and HID pads share the engine's pad indices 0..kMaxGamepads-1.
#pragma once

#include <array>
#include <cstdint>
#include <functional>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

#include "fa/platform/gamepad.h"
#include "fa/platform/gamepad_mapping.h"

namespace fa {

// HID usages (HID Usage Tables 1.4): the pages and the Generic Desktop usages a gamepad layout reads.
inline constexpr std::uint16_t kHidPageGenericDesktop = 0x01;
inline constexpr std::uint16_t kHidPageButton = 0x09;
inline constexpr std::uint16_t kHidUsageJoystick = 0x04;
inline constexpr std::uint16_t kHidUsageGamepad = 0x05;
inline constexpr std::uint16_t kHidUsageX = 0x30;
inline constexpr std::uint16_t kHidUsageY = 0x31;
inline constexpr std::uint16_t kHidUsageZ = 0x32;
inline constexpr std::uint16_t kHidUsageRx = 0x33;
inline constexpr std::uint16_t kHidUsageRy = 0x34;
inline constexpr std::uint16_t kHidUsageRz = 0x35;
inline constexpr std::uint16_t kHidUsageSlider = 0x36;
inline constexpr std::uint16_t kHidUsageDial = 0x37;
inline constexpr std::uint16_t kHidUsageWheel = 0x38;
inline constexpr std::uint16_t kHidUsageHatSwitch = 0x39;

// One button capability of a report descriptor (HIDP_BUTTON_CAPS, input reports): a usage range (min == max for one).
struct HidButtonCap {
    std::uint16_t usagePage = 0;
    std::uint16_t usageMin = 0, usageMax = 0;
};
// One value capability (HIDP_VALUE_CAPS, input reports).
struct HidValueCap {
    std::uint16_t usagePage = 0;
    std::uint16_t usageMin = 0, usageMax = 0;  // min == max for one usage
    std::uint16_t bitSize = 0;                 // bits of one value in the report
    std::uint16_t reportCount = 1;             // >1 with one usage: an array of values, which the layout does not read
    std::int32_t logicalMin = 0, logicalMax = 0;
};

// An axis or hat of a layout: its Generic Desktop usage and how its raw value is read.
struct HidLayoutValue {
    std::uint16_t usage = 0;
    std::uint16_t bitSize = 0;
    std::int32_t logicalMin = 0, logicalMax = 0;
};

// What a pad's descriptor offers, numbered for mapping lines (see the top of this file).
struct HidLayout {
    std::vector<std::uint16_t> buttons;  // button usages (page 9), ascending: raw button N is buttons[N]
    std::vector<HidLayoutValue> axes;    // raw axis N
    std::vector<HidLayoutValue> hats;    // raw hat N (at most one: the first hat switch)
    bool empty() const { return buttons.empty() && axes.empty() && hats.empty(); }
};
// At most kGamepadMaxRawButtons buttons are kept (the lowest usages); a usage declared twice counts once.
HidLayout make_hid_layout(std::span<const HidButtonCap> buttons, std::span<const HidValueCap> values);

// A raw axis value (what HidP_GetUsageValue returned: the report's bits, not sign-extended) -> -1..1 over the logical
// range. A negative logical minimum sign-extends the value from bitSize bits. A descriptor whose maximum came out below
// its minimum (an unsigned 0..65535 written in two bytes reads as 0..-1) is read as unsigned bitSize-bit numbers.
float hid_axis_value(std::uint32_t raw, const HidLayoutValue& v);
// A raw hat value -> SDL's direction bits (1 up, 2 right, 4 down, 8 left; 0 centred). Eight positions (logical range of 8
// or more) go clockwise from up; four go up, right, down, left. A value outside them (the "null state") is centred.
int hid_hat_mask(std::uint32_t raw, const HidLayoutValue& v);

// What the OS read from one input report.
struct HidValue {
    std::uint16_t usage = 0;  // Generic Desktop page
    std::uint32_t raw = 0;
};
struct HidReport {
    bool hasButtons = false;             // the report carries the buttons (false: they are in another report)
    std::vector<std::uint16_t> pressed;  // the button usages down (page 9)
    std::vector<HidValue> values;        // the axes and the hat this report carries; one missing keeps its last value
    void clear() {                       // keeps the capacity: a report arrives up to 1000 times a second
        hasButtons = false;
        pressed.clear();
        values.clear();
    }
};
// Gives one report to `mapper`, through `layout`'s numbering. Values and button usages the layout does not know are
// ignored.
void apply_hid_report(const HidLayout& layout, const HidReport& report, GamepadMapper& mapper);

// What identifies a HID pad on Windows (see the top of this file). The name is kept for messages and the pad's family.
inline constexpr std::uint16_t kHidBusUsb = 0x03;
GamepadIdentity windows_hid_identity(std::uint16_t vendor, std::uint16_t product, std::string name);

// The mapping a HID pad gets when no line names it: A B X Y on buttons 0..3, the shoulders on 4 and 5, back 8, start 9,
// the stick clicks 10 and 11, guide 12 (the order most generic USB pads use); the left stick on X/Y; the right stick on
// Z/Rz when the pad has both (then Rx/Ry, when present, are the triggers), else on Rx/Ry (then Z and Rz, when present,
// are the triggers); triggers that are not axes on buttons 6 and 7; the D-pad on the hat. Only what the pad has is bound.
// GUID all zeros.
GamepadMapping default_hid_gamepad_mapping(const HidLayout& layout);

// The built-in Windows database: SDL_GameControllerDB's platform:Windows lines (external/sdl_gamecontrollerdb/), embedded
// in the binary and indexed on first use. Its own object file (gamepad_hid_db.cpp): only the Windows backend and the tests
// reference it, so the other platforms' players do not carry the text.
const GamepadMappingDb& builtin_windows_gamepad_database();
std::string_view embedded_windows_gamepad_database_text();

// True for the HID interface of a pad that XInput serves (its device path carries "IG_", any case): XInput reads it, so
// the HID path skips it and the pad never appears twice.
bool hid_path_is_xinput(std::string_view devicePath);

// What canRumble says for a HID pad that has no driver of its own (HidPadDriver) yet.
inline constexpr const char* kHidRumbleWhy =
    "this pad is read as a generic HID pad, whose motors FactorIA does not drive on Windows yet: rumble for the "
    "DualShock 4, DualSense and Switch Pro is coming (planned as M98.5b2); Xbox pads (XInput) can rumble";

// A pad whose own reports the generic path does not read well or whose motors need its own output reports (M98.5b2:
// DualShock 4, DualSense, Switch Pro). Chosen by vendor and product id when the pad appears; gamepad_win32.cpp gives it
// every input report before the generic parser and asks it whether the pad can rumble.
class HidPadDriver {
public:
    virtual ~HidPadDriver() = default;
    // One input report as the OS hands it over (the report id first; 0 when the device numbers none). True: this driver
    // read it into `state`, which is what the pad reports from then on. False: the generic parser reads it.
    virtual bool read_report(std::span<const std::uint8_t> report, GamepadState& state) = 0;
    // Whether the pad's motors can be driven, and if not why.
    virtual GamepadRumbleSupport rumble_support() const = 0;
};
// The driver of a pad, or nullptr: the generic path (today, for every pad).
std::unique_ptr<HidPadDriver> make_hid_pad_driver(std::uint16_t vendor, std::uint16_t product);

// Which engine pad index each device holds. XInput user indices and HID devices share the kMaxGamepads indices: a device
// keeps its index while it stays connected, and a device that appears takes a free one (the one it would like when that
// is free, else the lowest). With every index taken a new device waits and takes the first one that frees up.
class GamepadSlotTable {
public:
    enum class Source : std::uint8_t { XInput, Hid };
    struct Key {
        Source source = Source::Hid;
        std::uint64_t id = 0;  // XInput: the user index; HID: the device handle
        bool operator==(const Key&) const = default;
    };
    // A device appeared: it waits for an index (assign() gives it one). A device already known changes nothing.
    void add(Key key);
    // A device went away: its index is free (for the next assign()), or it leaves the waiting list.
    void remove(Key key);
    bool has_waiting() const { return !waiting_.empty(); }
    // Gives free indices to the waiting devices, the one that appeared first first. `prefer(key, occupied)` names the
    // index a device would like (Input::choose_gamepad_slot: the one it had last time); one that is out of range or taken
    // falls back to the lowest free index. No prefer: the lowest free index. Returns how many devices got an index.
    int assign(const std::function<int(const Key&, std::span<const bool>)>& prefer = {});
    int slot_of(const Key& key) const;  // -1: waiting or unknown
    std::optional<Key> owner(int slot) const;
    // Changes every time `slot` is freed or taken, so the caller can tell a new device in a slot from the one it fed.
    std::uint32_t generation(int slot) const;

private:
    std::array<std::optional<Key>, kMaxGamepads> owners_{};
    std::array<std::uint32_t, kMaxGamepads> generations_{};
    std::vector<Key> waiting_;
};

// When to ask the XInput slots that hold no pad. XInputGetState on an empty slot is slow (it asks the driver), so instead
// of 4 calls every frame the empty slots are probed once every kIdleEvery polls, and after a device notification (a pad
// came or went: WM_INPUT_DEVICE_CHANGE) every kBurstEvery polls for kBurstLength polls, because XInput may take a pad a
// moment after its device appears. Slots that hold a pad are read every poll (that is how XInput reports state).
class GamepadProbeSchedule {
public:
    static constexpr unsigned kIdleEvery = 120;   // ~2 s at 60 frames per second
    static constexpr unsigned kBurstEvery = 15;   // ~0.25 s
    static constexpr unsigned kBurstLength = 90;  // ~1.5 s: 6 probes
    void notify();                                // a device came or went
    bool tick();  // one poll: true when the empty slots are to be probed now (the first poll always is)

private:
    unsigned polls_ = 0;
    unsigned burstLeft_ = 0, burstPos_ = 0;
};

}  // namespace fa
