// Web gamepads through the browser Gamepad API (emscripten/html5.h). Browsers hide a pad from the page until a button is
// pressed on it, then report it in navigator.getGamepads(); emscripten_sample_gamepad_data() copies that list and
// emscripten_get_gamepad_status() reads one pad. A pad with the "standard" mapping (Xbox, PlayStation, Switch Pro, Steam
// Deck... in every current browser) numbers its buttons and axes by position, which is the engine's convention too:
//   buttons 0 A, 1 B, 2 X, 3 Y, 4/5 shoulders, 6/7 triggers (analog), 8 Back, 9 Start, 10/11 stick clicks, 12-15 d-pad
//   up/down/left/right, 16 Guide; axes 0/1 left stick, 2/3 right stick (+Y is DOWN there, the engine's is up).
// A pad without that mapping is used with the same numbers (the best a page can do) and logged once as untested.
// A pad keeps its slot while it stays connected: a new pad takes the slot it had before when that is free (else the first
// free one), an unplugged pad frees its own. Each pad has a stable id (GamepadInfo) built from the browser's Gamepad.id.
#include <emscripten/html5.h>

#include <cstdint>
#include <cstring>
#include <string>

#include "fa/core/log.h"
#include "fa/platform/gamepad.h"

namespace fa {
namespace {

int g_slotOf[kMaxGamepads];  // browser gamepad index in this slot, -1 = free
bool g_init = false;
bool g_unsupportedLogged = false;

void init_slots() {
    if (g_init) return;
    g_init = true;
    for (int& s : g_slotOf) s = -1;
}

bool button(const EmscriptenGamepadEvent& pad, int i) { return i < pad.numButtons && pad.digitalButton[i]; }
float analog(const EmscriptenGamepadEvent& pad, int i) { return i < pad.numButtons ? float(pad.analogButton[i]) : 0.0f; }
float axis(const EmscriptenGamepadEvent& pad, int i) { return i < pad.numAxes ? float(pad.axis[i]) : 0.0f; }

// The browser's Gamepad.id is "Wireless Controller (STANDARD GAMEPAD Vendor: 054c Product: 09cc)" in Chrome and
// "054c-09cc-Wireless Controller" in Firefox. The vendor and product are taken out of either, the rest is the name. The page
// gets no serial number (browsers hide it against fingerprinting), so two pads of one model share an id and take the slots in
// plugging order.
GamepadInfo info_of(const EmscriptenGamepadEvent& pad) {
    const std::string raw = pad.id;
    auto hex4 = [](const std::string& s, size_t at, std::uint16_t& out) {
        if (at + 4 > s.size()) return false;
        unsigned v = 0;
        for (size_t i = at; i < at + 4; ++i) {
            const char c = s[i];
            const int d = c >= '0' && c <= '9' ? c - '0' : c >= 'a' && c <= 'f' ? c - 'a' + 10 : c >= 'A' && c <= 'F' ? c - 'A' + 10 : -1;
            if (d < 0) return false;
            v = v * 16 + unsigned(d);
        }
        out = std::uint16_t(v);
        return true;
    };
    GamepadInfo info;
    info.name = raw;
    const size_t v = raw.find("Vendor: "), p = raw.find("Product: ");
    if (v != std::string::npos && p != std::string::npos) {
        hex4(raw, v + 8, info.vendor);
        hex4(raw, p + 9, info.product);
        info.name = raw.substr(0, raw.find(" ("));
    } else if (raw.size() > 10 && raw[4] == '-' && raw[9] == '-' && hex4(raw, 0, info.vendor) && hex4(raw, 5, info.product)) {
        info.name = raw.substr(10);
    }
    info.type = gamepad_type_from_ids(info.vendor, raw);
    info.id = make_gamepad_id(info.vendor, info.product, info.name, "");
    return info;
}

void feed(Input& in, int slot, const EmscriptenGamepadEvent& pad) {
    in.set_gamepad_info(slot, info_of(pad));
    in.on_gamepad_connected(slot, true);
    constexpr GamepadButton kButtons[] = {
        GamepadButton::A, GamepadButton::B, GamepadButton::X, GamepadButton::Y, GamepadButton::LeftShoulder,
        GamepadButton::RightShoulder, GamepadButton::Count /* 6: left trigger */, GamepadButton::Count /* 7: right trigger */,
        GamepadButton::Back, GamepadButton::Start, GamepadButton::LeftThumb, GamepadButton::RightThumb, GamepadButton::DpadUp,
        GamepadButton::DpadDown, GamepadButton::DpadLeft, GamepadButton::DpadRight, GamepadButton::Guide};
    for (int i = 0; i < int(sizeof(kButtons) / sizeof(kButtons[0])); ++i)
        if (kButtons[i] != GamepadButton::Count) in.on_gamepad_button(slot, kButtons[i], button(pad, i));
    in.on_gamepad_axis(slot, GamepadAxis::LeftX, axis(pad, 0));
    in.on_gamepad_axis(slot, GamepadAxis::LeftY, -axis(pad, 1));
    in.on_gamepad_axis(slot, GamepadAxis::RightX, axis(pad, 2));
    in.on_gamepad_axis(slot, GamepadAxis::RightY, -axis(pad, 3));
    in.on_gamepad_axis(slot, GamepadAxis::LeftTrigger, analog(pad, 6));
    in.on_gamepad_axis(slot, GamepadAxis::RightTrigger, analog(pad, 7));
}

}  // namespace

void poll_gamepads(Input& in) {
    init_slots();
    if (emscripten_sample_gamepad_data() != EMSCRIPTEN_RESULT_SUCCESS) {
        if (!g_unsupportedLogged) {
            g_unsupportedLogged = true;
            FA_INFO("gamepad", "this browser has no Gamepad API: gamepads are not available (keyboard, mouse and touch work)");
        }
        return;
    }
    const int count = emscripten_get_num_gamepads();
    EmscriptenGamepadEvent pads[kMaxGamepads * 4];
    bool present[kMaxGamepads * 4] = {};
    const int browserPads = count < int(sizeof(present)) ? count : int(sizeof(present));
    for (int b = 0; b < browserPads; ++b) {
        std::memset(&pads[b], 0, sizeof(pads[b]));
        present[b] = emscripten_get_gamepad_status(b, &pads[b]) == EMSCRIPTEN_RESULT_SUCCESS && pads[b].connected;
    }
    // Free the slots of pads that are gone.
    for (int s = 0; s < kMaxGamepads; ++s) {
        const int b = g_slotOf[s];
        if (b < 0 || (b < browserPads && present[b])) continue;
        FA_INFO("gamepad", "pad {} disconnected", s);
        g_slotOf[s] = -1;
    }
    // New pads take the first free slot.
    for (int b = 0; b < browserPads; ++b) {
        if (!present[b]) continue;
        bool known = false;
        for (int s = 0; s < kMaxGamepads && !known; ++s) known = g_slotOf[s] == b;
        if (known) continue;
        bool occupied[kMaxGamepads];
        for (int s = 0; s < kMaxGamepads; ++s) occupied[s] = g_slotOf[s] >= 0;
        const int free = in.choose_gamepad_slot(info_of(pads[b]).id, occupied);  // its old slot when that is free
        if (free < 0) break;  // four pads already
        g_slotOf[free] = b;
        FA_INFO("gamepad", "pad {} connected: {}{}", free, pads[b].id,
                std::strcmp(pads[b].mapping, "standard") == 0 ? "" : " (not the browser's standard layout: buttons may be misplaced)");
    }
    for (int s = 0; s < kMaxGamepads; ++s) {
        if (g_slotOf[s] >= 0) feed(in, s, pads[g_slotOf[s]]);
        else in.on_gamepad_connected(s, false);
    }
}

}  // namespace fa
