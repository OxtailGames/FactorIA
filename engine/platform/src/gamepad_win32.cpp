// Windows gamepads through XInput. The DLL is loaded at run time (no import library, no new link dependency): Windows 8+
// has xinput1_4.dll, older systems xinput9_1_0.dll. Written against the Windows SDK's xinput.h; the pad layout is the
// Xbox one that XInput reports natively.
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <xinput.h>

#include <algorithm>
#include <string>

#include "fa/platform/gamepad.h"

namespace fa {

namespace {

using GetStateFn = DWORD(WINAPI*)(DWORD, XINPUT_STATE*);

GetStateFn load_get_state() {
    for (const char* dll : {"xinput1_4.dll", "xinput9_1_0.dll"})
        if (HMODULE m = LoadLibraryA(dll))
            if (auto fn = reinterpret_cast<GetStateFn>(reinterpret_cast<void*>(GetProcAddress(m, "XInputGetState")))) return fn;
    return nullptr;
}

float thumb(SHORT v) { return std::clamp(float(v) / 32767.0f, -1.0f, 1.0f); }

}  // namespace

void poll_gamepads(Input& in) {
    static const GetStateFn get_state = load_get_state();
    if (!get_state) return;
    // Asking an empty slot is slow on some drivers, so a slot without a pad is asked once per ~2 s (at 60 fps).
    static bool present[kMaxGamepads] = {};
    static unsigned frame = 0;
    const bool rescan = (frame++ % 120) == 0;
    for (int i = 0; i < kMaxGamepads; ++i) {
        if (!present[i] && !rescan) continue;
        XINPUT_STATE st{};
        bool ok = get_state(DWORD(i), &st) == ERROR_SUCCESS;
        if (ok && !present[i]) {
            // XInput tells nothing about the pad (no name, no ids, no serial): it is "an Xbox pad in XInput slot i", and the id
            // says so. The slot IS the identity: a pad that is replugged gets its XInput user index back when it is free.
            GamepadInfo info;
            info.name = "Xbox controller (XInput)";
            info.vendor = 0x045e;  // Microsoft: what XInput pads present as; the product is unknown
            info.type = GamepadType::Xbox;  // XInput only serves Xbox-style pads
            info.id = make_gamepad_id(info.vendor, 0, "XInput controller", "xinput" + std::to_string(i));
            in.set_gamepad_info(i, std::move(info));
        }
        if (ok != present[i]) in.on_gamepad_connected(i, ok);
        present[i] = ok;
        if (!ok) continue;
        const XINPUT_GAMEPAD& g = st.Gamepad;
        const struct { WORD mask; GamepadButton button; } map[] = {
            {XINPUT_GAMEPAD_A, GamepadButton::A}, {XINPUT_GAMEPAD_B, GamepadButton::B},
            {XINPUT_GAMEPAD_X, GamepadButton::X}, {XINPUT_GAMEPAD_Y, GamepadButton::Y},
            {XINPUT_GAMEPAD_START, GamepadButton::Start}, {XINPUT_GAMEPAD_BACK, GamepadButton::Back},
            {XINPUT_GAMEPAD_DPAD_LEFT, GamepadButton::DpadLeft}, {XINPUT_GAMEPAD_DPAD_RIGHT, GamepadButton::DpadRight},
            {XINPUT_GAMEPAD_DPAD_UP, GamepadButton::DpadUp}, {XINPUT_GAMEPAD_DPAD_DOWN, GamepadButton::DpadDown},
            {XINPUT_GAMEPAD_LEFT_SHOULDER, GamepadButton::LeftShoulder},
            {XINPUT_GAMEPAD_RIGHT_SHOULDER, GamepadButton::RightShoulder},
            {XINPUT_GAMEPAD_LEFT_THUMB, GamepadButton::LeftThumb}, {XINPUT_GAMEPAD_RIGHT_THUMB, GamepadButton::RightThumb}};
        for (const auto& m : map) in.on_gamepad_button(i, m.button, (g.wButtons & m.mask) != 0);
        in.on_gamepad_axis(i, GamepadAxis::LeftX, thumb(g.sThumbLX));
        in.on_gamepad_axis(i, GamepadAxis::LeftY, thumb(g.sThumbLY));  // XInput's +Y is up already
        in.on_gamepad_axis(i, GamepadAxis::RightX, thumb(g.sThumbRX));
        in.on_gamepad_axis(i, GamepadAxis::RightY, thumb(g.sThumbRY));
        in.on_gamepad_axis(i, GamepadAxis::LeftTrigger, float(g.bLeftTrigger) / 255.0f);
        in.on_gamepad_axis(i, GamepadAxis::RightTrigger, float(g.bRightTrigger) / 255.0f);
    }
}

}  // namespace fa
