// Android gamepad state (see fa/platform/android_gamepads.h). Platform-neutral; gamepad_android.cpp is the NDK glue.
#include "fa/platform/android_gamepads.h"

#include <algorithm>
#include <cmath>

namespace fa {

namespace {

bool key_to_button(int keyCode, GamepadButton& out) {
    switch (keyCode) {
        case kAndroidKeyButtonA: out = GamepadButton::A; return true;
        case kAndroidKeyButtonB: out = GamepadButton::B; return true;
        case kAndroidKeyButtonX: out = GamepadButton::X; return true;
        case kAndroidKeyButtonY: out = GamepadButton::Y; return true;
        case kAndroidKeyButtonL1: out = GamepadButton::LeftShoulder; return true;
        case kAndroidKeyButtonR1: out = GamepadButton::RightShoulder; return true;
        case kAndroidKeyButtonThumbL: out = GamepadButton::LeftThumb; return true;
        case kAndroidKeyButtonThumbR: out = GamepadButton::RightThumb; return true;
        case kAndroidKeyButtonStart: out = GamepadButton::Start; return true;
        case kAndroidKeyButtonSelect: out = GamepadButton::Back; return true;
        case kAndroidKeyButtonMode: out = GamepadButton::Guide; return true;
        case kAndroidKeyDpadUp: out = GamepadButton::DpadUp; return true;
        case kAndroidKeyDpadDown: out = GamepadButton::DpadDown; return true;
        case kAndroidKeyDpadLeft: out = GamepadButton::DpadLeft; return true;
        case kAndroidKeyDpadRight: out = GamepadButton::DpadRight; return true;
        default: return false;
    }
}

// The right stick is Z/RZ on most pads and RX/RY on the others; the pad that is not using a pair leaves it at 0, so
// the one that is further from rest is the stick.
float larger(float a, float b) { return std::fabs(a) >= std::fabs(b) ? a : b; }

}  // namespace

bool AndroidGamepads::is_gamepad_key(int keyCode) {
    return (keyCode >= kAndroidKeyButtonA && keyCode <= kAndroidKeyButtonMode) ||
           (keyCode >= kAndroidKeyButton1 && keyCode <= kAndroidKeyButton16) ||
           (keyCode >= kAndroidKeyDpadUp && keyCode <= kAndroidKeyDpadCenter);
}

AndroidGamepads::Pad& AndroidGamepads::pad_for(int deviceId) {
    ++tick_;
    for (int i = 0; i < count_; ++i)
        if (pads_[size_t(i)].deviceId == deviceId) {
            pads_[size_t(i)].lastSeen = tick_;
            return pads_[size_t(i)];
        }
    // A new device. Android gives a pad that reconnects a NEW device id and the NDK reports no removals, so when all
    // slots are taken the one that has been silent longest is the best guess for the pad that went away.
    int slot = count_;
    if (count_ < kMaxGamepads) {
        ++count_;
    } else {
        slot = 0;
        for (int i = 1; i < kMaxGamepads; ++i)
            if (pads_[size_t(i)].lastSeen < pads_[size_t(slot)].lastSeen) slot = i;
    }
    Pad& pad = pads_[size_t(slot)];
    pad = Pad{};
    pad.deviceId = deviceId;
    pad.lastSeen = tick_;
    return pad;
}

bool AndroidGamepads::on_key(int deviceId, int keyCode, bool down) {
    if (!is_gamepad_key(keyCode)) return false;
    Pad& pad = pad_for(deviceId);
    GamepadButton button = GamepadButton::A;
    if (key_to_button(keyCode, button)) pad.keys[size_t(button)] = down;
    else if (keyCode == kAndroidKeyButtonL2) pad.l2Key = down;
    else if (keyCode == kAndroidKeyButtonR2) pad.r2Key = down;
    return true;  // C/Z/1..16/DPAD_CENTER: swallowed, not mapped
}

void AndroidGamepads::on_motion(int deviceId, const AndroidMotionAxes& axes) {
    Pad& pad = pad_for(deviceId);
    pad.axes = axes;
    if (std::max(axes.ltrigger, axes.brake) > 0.0f) pad.analogLeft = true;
    if (std::max(axes.rtrigger, axes.gas) > 0.0f) pad.analogRight = true;
}

GamepadState AndroidGamepads::state(int index) const {
    GamepadState st;
    if (index < 0 || index >= count_) return st;
    const Pad& pad = pads_[size_t(index)];
    const AndroidMotionAxes& a = pad.axes;
    st.buttons = pad.keys;
    // The D-pad is keys on some pads and the hat axes on the others.
    auto dpad = [&](GamepadButton b, bool hat) { st.buttons[size_t(b)] = st.buttons[size_t(b)] || hat; };
    dpad(GamepadButton::DpadLeft, a.hatX < -0.5f);
    dpad(GamepadButton::DpadRight, a.hatX > 0.5f);
    dpad(GamepadButton::DpadUp, a.hatY < -0.5f);
    dpad(GamepadButton::DpadDown, a.hatY > 0.5f);
    st.axes[size_t(GamepadAxis::LeftX)] = a.x;
    st.axes[size_t(GamepadAxis::LeftY)] = 0.0f - a.y;  // Android's +Y is down
    st.axes[size_t(GamepadAxis::RightX)] = larger(a.z, a.rx);
    st.axes[size_t(GamepadAxis::RightY)] = 0.0f - larger(a.rz, a.ry);
    // A trigger with an analog axis uses it; one that only has the digital key is all or nothing.
    st.axes[size_t(GamepadAxis::LeftTrigger)] = pad.analogLeft ? std::max(a.ltrigger, a.brake) : (pad.l2Key ? 1.0f : 0.0f);
    st.axes[size_t(GamepadAxis::RightTrigger)] = pad.analogRight ? std::max(a.rtrigger, a.gas) : (pad.r2Key ? 1.0f : 0.0f);
    return st;
}

void AndroidGamepads::feed(Input& input) const {
    for (int i = 0; i < count_; ++i) state(i).feed(input, i);
}

}  // namespace fa
