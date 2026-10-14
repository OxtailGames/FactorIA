// Android gamepad state: what the NativeActivity input queue says about pads, as FactorIA's Xbox-style pad.
//
// Android hands the app key events (AKEYCODE_BUTTON_A, AKEYCODE_DPAD_UP...) and joystick motion events (AXIS_X,
// AXIS_Z, AXIS_LTRIGGER, AXIS_HAT_X...) per input DEVICE. gamepad_android.cpp reads them from the AInputEvent and calls
// this class, which owns the decisions (which keycode is which button, which axes are the right stick, the pad
// slots) and has no Android dependency, so every OS unit-tests it. Android's own layout files already normalise
// pads to the Xbox-style naming, so unlike Linux there is no per-pad table.
//
// Deliberate cuts: a pad that is unplugged is not noticed (the NDK has no device-removal callback; Android
// recentres the axes and releases the keys of a removed device itself, so nothing sticks, but the pad keeps its
// slot until a new pad needs it); pads that put the right stick on RX/RY while ALSO using Z/RZ as triggers are not
// told apart; AKEYCODE_DPAD_CENTER, BUTTON_C/Z/1..16 are swallowed but not mapped.
#pragma once

#include <array>
#include <cstdint>

#include "fa/platform/gamepad_mapping.h"
#include "fa/platform/input.h"

namespace fa {

// Android key codes (android/keycodes.h). Numeric so this compiles everywhere; gamepad_android.cpp static_asserts
// every one of them against the NDK headers.
inline constexpr int kAndroidKeyDpadUp = 19, kAndroidKeyDpadDown = 20, kAndroidKeyDpadLeft = 21,
                     kAndroidKeyDpadRight = 22, kAndroidKeyDpadCenter = 23;
inline constexpr int kAndroidKeyButtonA = 96, kAndroidKeyButtonB = 97, kAndroidKeyButtonC = 98, kAndroidKeyButtonX = 99,
                     kAndroidKeyButtonY = 100, kAndroidKeyButtonZ = 101, kAndroidKeyButtonL1 = 102,
                     kAndroidKeyButtonR1 = 103, kAndroidKeyButtonL2 = 104, kAndroidKeyButtonR2 = 105,
                     kAndroidKeyButtonThumbL = 106, kAndroidKeyButtonThumbR = 107, kAndroidKeyButtonStart = 108,
                     kAndroidKeyButtonSelect = 109, kAndroidKeyButtonMode = 110;
inline constexpr int kAndroidKeyButton1 = 188, kAndroidKeyButton16 = 203;  // BUTTON_1..BUTTON_16 are consecutive

// The axes of one joystick motion event (AMotionEvent_getAxisValue), each read by its Android name. Sticks run -1..1
// with +Y DOWN, triggers 0..1, hats -1/0/1.
struct AndroidMotionAxes {
    float x = 0, y = 0;            // AXIS_X, AXIS_Y: left stick
    float z = 0, rz = 0;           // AXIS_Z, AXIS_RZ: right stick on most pads
    float rx = 0, ry = 0;          // AXIS_RX, AXIS_RY: right stick on the others
    float hatX = 0, hatY = 0;      // AXIS_HAT_X, AXIS_HAT_Y: the D-pad (-1 left/up, 1 right/down)
    float ltrigger = 0, rtrigger = 0;  // AXIS_LTRIGGER, AXIS_RTRIGGER
    float brake = 0, gas = 0;      // AXIS_BRAKE, AXIS_GAS: the triggers of the pads that use these names
};

class AndroidGamepads {
public:
    // True for the keycodes a gamepad sends (and only those), so the caller can consume exactly them: A..MODE
    // (96..110), BUTTON_1..16 (188..203) and the D-pad keys (19..23). KEYCODE_BACK is deliberately NOT one: the system
    // Back button keeps leaving the app.
    static bool is_gamepad_key(int keyCode);

    // A key event from a gamepad source. Returns whether the key is a gamepad key (see is_gamepad_key); the state
    // changes for the ones that map to a button. Repeated "down" events are harmless.
    bool on_key(int deviceId, int keyCode, bool down);
    // A joystick motion event: the new position of every axis.
    void on_motion(int deviceId, const AndroidMotionAxes& axes);

    // Feeds every known pad (connect + all buttons and axes) to `input`. Call it once per frame.
    void feed(Input& input) const;

    int pad_count() const { return count_; }
    GamepadState state(int pad) const;  // pad in 0..pad_count()-1

private:
    struct Pad {
        int deviceId = -1;
        std::uint64_t lastSeen = 0;
        std::array<bool, size_t(GamepadButton::Count)> keys{};  // buttons from key events
        bool l2Key = false, r2Key = false;                      // BUTTON_L2/R2: digital triggers
        bool analogLeft = false, analogRight = false;           // the trigger axis has moved: ignore the digital key
        AndroidMotionAxes axes;
    };
    Pad& pad_for(int deviceId);  // the pad of a device; a new device takes a free slot or the longest silent one

    std::array<Pad, kMaxGamepads> pads_;
    int count_ = 0;
    std::uint64_t tick_ = 0;
};

}  // namespace fa
