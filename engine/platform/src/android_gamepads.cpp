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

// For a pad whose layout is not known: the right stick is Z/RZ on most pads and RX/RY on the others; the pair the pad is
// not using stays at 0 (a Z/RZ trigger that rests at -1 gets this wrong, which is what android_layout_for fixes), so the
// one that is further from rest is the stick.
float larger(float a, float b) { return std::fabs(a) >= std::fabs(b) ? a : b; }

// A trigger on a centred axis (Z/RZ): -1 released .. +1 pulled -> 0..1.
float trigger_from_centred(float v) { return std::clamp((v + 1.0f) * 0.5f, 0.0f, 1.0f); }

}  // namespace

AndroidLayout android_layout_for(const AndroidAxisCaps& caps) {
    const bool dedicatedTriggers = caps.ltrigger || caps.rtrigger || caps.brake || caps.gas;
    const bool zrz = caps.z && caps.rz;
    const bool rxry = caps.rx && caps.ry;
    AndroidLayout l;
    if (zrz && rxry) {
        if (dedicatedTriggers) return l;  // both pairs AND real triggers: no telling which pair is the stick
        l.rightStick = AndroidRightStick::RxRy;  // the Xbox-like layout: Z/RZ are the triggers
        l.zrzAreTriggers = true;
    } else if (rxry) {
        l.rightStick = AndroidRightStick::RxRy;
    } else if (zrz) {
        l.rightStick = AndroidRightStick::ZRz;
    } else {
        l.rightStick = AndroidRightStick::None;
    }
    return l;
}

bool AndroidGamepads::is_gamepad_key(int keyCode) {
    return (keyCode >= kAndroidKeyButtonA && keyCode <= kAndroidKeyButtonMode) ||
           (keyCode >= kAndroidKeyButton1 && keyCode <= kAndroidKeyButton16) ||
           (keyCode >= kAndroidKeyDpadUp && keyCode <= kAndroidKeyDpadCenter);
}

AndroidGamepads::Pad* AndroidGamepads::find(int deviceId) {
    for (Pad& pad : pads_)
        if (pad.used && pad.deviceId == deviceId) return &pad;
    return nullptr;
}

AndroidGamepads::Pad& AndroidGamepads::pad_for(int deviceId) {
    ++tick_;
    if (Pad* pad = find(deviceId)) {
        pad->lastSeen = tick_;
        return *pad;
    }
    // A new device: the first free slot (an unplugged pad's, once release_device() has been told). When there is none,
    // the pad that has been silent longest is the best guess for the one that went away without anybody telling us.
    auto free = std::ranges::find_if(pads_, [](const Pad& p) { return !p.used; });
    Pad& slot = free != pads_.end() ? *free : *std::ranges::min_element(pads_, {}, &Pad::lastSeen);
    slot = Pad{};
    slot.used = true;
    slot.deviceId = deviceId;
    slot.lastSeen = tick_;
    return slot;
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
    pad.motionSeen = true;
    if (std::max(axes.ltrigger, axes.brake) > 0.0f) pad.analogLeft = true;
    if (std::max(axes.rtrigger, axes.gas) > 0.0f) pad.analogRight = true;
}

void AndroidGamepads::set_layout(int deviceId, const AndroidLayout& layout) {
    if (Pad* pad = find(deviceId)) {
        pad->layout = layout;
        pad->layoutSet = true;
    }
}

void AndroidGamepads::set_info(int deviceId, const GamepadInfo& info) {
    if (Pad* pad = find(deviceId)) pad->info = info;
}

void AndroidGamepads::release_device(int deviceId) {
    if (Pad* pad = find(deviceId)) *pad = Pad{};
}

int AndroidGamepads::device_id(int slot) const {
    return slot >= 0 && slot < kMaxGamepads && pads_[size_t(slot)].used ? pads_[size_t(slot)].deviceId : -1;
}

bool AndroidGamepads::needs_layout(int slot) const {
    return slot >= 0 && slot < kMaxGamepads && pads_[size_t(slot)].used && !pads_[size_t(slot)].layoutSet;
}

bool AndroidGamepads::any_needs_layout() const {
    return std::ranges::any_of(pads_, [](const Pad& p) { return p.used && !p.layoutSet; });
}

int AndroidGamepads::pad_count() const { return int(std::ranges::count_if(pads_, &Pad::used)); }

GamepadState AndroidGamepads::state(int slot) const {
    GamepadState st;
    if (slot < 0 || slot >= kMaxGamepads || !pads_[size_t(slot)].used) return st;
    const Pad& pad = pads_[size_t(slot)];
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

    float rx = 0.0f, ry = 0.0f;
    switch (pad.layout.rightStick) {
        case AndroidRightStick::ZRz: rx = a.z; ry = a.rz; break;
        case AndroidRightStick::RxRy: rx = a.rx; ry = a.ry; break;
        case AndroidRightStick::None: break;
        case AndroidRightStick::Unknown: rx = larger(a.z, a.rx); ry = larger(a.rz, a.ry); break;
    }
    st.axes[size_t(GamepadAxis::RightX)] = rx;
    st.axes[size_t(GamepadAxis::RightY)] = 0.0f - ry;

    if (pad.layout.zrzAreTriggers && pad.motionSeen) {  // before the first motion event Z/RZ are 0, which would read as half pulled
        st.axes[size_t(GamepadAxis::LeftTrigger)] = trigger_from_centred(a.z);
        st.axes[size_t(GamepadAxis::RightTrigger)] = trigger_from_centred(a.rz);
    } else {
        // A trigger with an analog axis uses it; one that only has the digital key is all or nothing.
        st.axes[size_t(GamepadAxis::LeftTrigger)] = pad.analogLeft ? std::max(a.ltrigger, a.brake) : (pad.l2Key ? 1.0f : 0.0f);
        st.axes[size_t(GamepadAxis::RightTrigger)] = pad.analogRight ? std::max(a.rtrigger, a.gas) : (pad.r2Key ? 1.0f : 0.0f);
    }
    return st;
}

void AndroidGamepads::feed(Input& input) {
    // A pad that is waiting for its info is not there yet; one that has it goes to the slot it had before, if that is free.
    auto announced = [&](const Pad& p) { return p.used && (!waitForInfo_ || p.layoutSet); };
    for (int i = 0; i < kMaxGamepads; ++i) {
        Pad& pad = pads_[size_t(i)];
        if (!announced(pad) || pad.placed) continue;
        pad.placed = true;
        if (pad.info.id.empty()) continue;
        bool occupied[kMaxGamepads];
        for (int s = 0; s < kMaxGamepads; ++s) occupied[s] = s != i && pads_[size_t(s)].used;
        const int want = input.choose_gamepad_slot(pad.info.id, occupied);
        if (want >= 0 && want != i) std::swap(pads_[size_t(want)], pad);  // `want` is free: a pad that is not there yet
    }
    for (int i = 0; i < kMaxGamepads; ++i) {
        const Pad& pad = pads_[size_t(i)];
        if (announced(pad)) {
            if (!pad.info.id.empty()) input.set_gamepad_info(i, pad.info);  // before the feed, which connects the pad
            state(i).feed(input, i);
        } else {
            input.on_gamepad_connected(i, false);
        }
    }
}

}  // namespace fa
