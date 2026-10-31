// Android gamepad state: what the NativeActivity input queue says about pads, as FactorIA's Xbox-style pad.
//
// Android hands the app key events (AKEYCODE_BUTTON_A, AKEYCODE_DPAD_UP...) and joystick motion events (AXIS_X,
// AXIS_Z, AXIS_LTRIGGER, AXIS_HAT_X...) per input DEVICE. gamepad_android.cpp reads them from the AInputEvent and calls
// this class, which owns the decisions (which keycode is which button, which axes are the right stick, the pad
// slots) and has no Android dependency, so every OS unit-tests it. Android's own layout files already normalise
// pads to the Xbox-style naming, so unlike Linux there is no per-pad table.
//
// Two things the NDK's event API cannot tell, so gamepad_android.cpp asks the Java side (InputDevice, through JNI) at a
// low rate and hands the answers to this class:
//   * a pad was unplugged (InputDevice.getDevice(id) is null): release_device() frees its slot, so the next pad takes
//     it and the game sees the pad disconnect. Without the answer (JNI unavailable) a pad keeps its slot until a fifth
//     device needs one; Android recentres the axes and releases the keys of a removed device itself, so nothing sticks.
//   * what Z and RZ mean: the right stick on most pads, the analog triggers on others (the Xbox-like layout, where the
//     stick is RX/RY). android_layout_for() decides from which axes the device reports.
//
// Deliberate cuts: pads whose axes are ambiguous (see android_layout_for) use whichever pair is further from rest;
// AKEYCODE_DPAD_CENTER, BUTTON_C/Z/1..16 are swallowed but not mapped.
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

// Which motion axes an input device reports: whether InputDevice.getMotionRange(axis) is non-null for each of them.
struct AndroidAxisCaps {
    bool z = false, rz = false;              // AXIS_Z, AXIS_RZ
    bool rx = false, ry = false;             // AXIS_RX, AXIS_RY
    bool ltrigger = false, rtrigger = false; // AXIS_LTRIGGER, AXIS_RTRIGGER
    bool brake = false, gas = false;         // AXIS_BRAKE, AXIS_GAS
};

// Where a pad's right stick is.
enum class AndroidRightStick : std::uint8_t {
    Unknown,  // not asked yet, or ambiguous: whichever of Z/RZ and RX/RY is further from rest
    ZRz,      // AXIS_Z / AXIS_RZ
    RxRy,     // AXIS_RX / AXIS_RY
    None,     // the pad has no right stick
};

// How to read a pad's axes. The default (Unknown, no Z/RZ triggers) is what a pad gets before it has been asked.
struct AndroidLayout {
    AndroidRightStick rightStick = AndroidRightStick::Unknown;
    // Z and RZ are the left and right analog triggers. Android reports a trigger on a centred axis like any stick axis:
    // -1 released, +1 fully pulled (inferred from the framework's axis scaling, not seen on a real pad).
    bool zrzAreTriggers = false;
};

// The decision, from what the device reports:
//   * RX+RY and Z+RZ, and no LTRIGGER/RTRIGGER/BRAKE/GAS: the Xbox-like layout. RX/RY is the right stick, Z/RZ the triggers.
//   * Z+RZ and no RX+RY: the right stick is Z/RZ (DualShock 4, Xbox One, most pads), triggers on LTRIGGER/RTRIGGER/BRAKE/GAS.
//     A pad that has Z/RZ as its only extra axes and no trigger axes is taken for this one too (it could be a pad with
//     triggers and no right stick; there is no telling them apart).
//   * RX+RY and no Z+RZ: the right stick is RX/RY.
//   * both pairs AND dedicated trigger axes: one pair is the stick and the other something odd. Unknown.
//   * neither pair: no right stick.
AndroidLayout android_layout_for(const AndroidAxisCaps& caps);

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

    // The device was queried (see the top of this file): its axis layout. Ignored for a device that has no slot.
    void set_layout(int deviceId, const AndroidLayout& layout);
    // Who the device is (InputDevice name, vendor, product, descriptor: the id is built from them with make_gamepad_id).
    // Called with set_layout() for a new device. Ignored for a device that has no slot.
    void set_info(int deviceId, const GamepadInfo& info);
    // true: a pad is not announced to the game (feed() shows its slot as free) until set_layout() has been called for it, so the
    // "gamepadConnected" event carries the pad's real id and the pad can take the slot it had before. The JNI glue turns this
    // on (it answers every new device, even when JNI fails); the default is off, a pad then connects at its first event.
    void wait_for_info(bool wait) { waitForInfo_ = wait; }
    // The device is gone (InputDevice.getDevice(id) returned null): its slot is free for the next pad. The other pads
    // keep their slots, so player 2 stays player 2. No effect on a device that has no slot.
    void release_device(int deviceId);

    // Feeds every slot (a pad: connect + all buttons and axes; a free slot: disconnect) to `input`. Once per frame. A pad
    // whose info is known moves to the slot it had before when that is free (once, before it is announced).
    void feed(Input& input);

    // Slots are 0..kMaxGamepads-1, the pad numbers the game sees. A free slot is -1 / at rest.
    int device_id(int slot) const;      // the Android device id of the pad in the slot, or -1
    bool needs_layout(int slot) const;  // a pad is there and nobody has called set_layout() for it yet
    bool any_needs_layout() const;
    int pad_count() const;              // slots in use
    GamepadState state(int slot) const;

private:
    struct Pad {
        bool used = false;
        int deviceId = 0;
        std::uint64_t lastSeen = 0;
        bool layoutSet = false;
        bool placed = false;  // feed() has chosen its slot for good (its id is known)
        AndroidLayout layout;
        GamepadInfo info;
        std::array<bool, size_t(GamepadButton::Count)> keys{};  // buttons from key events
        bool l2Key = false, r2Key = false;                      // BUTTON_L2/R2: digital triggers
        bool analogLeft = false, analogRight = false;           // the trigger axis has moved: ignore the digital key
        bool motionSeen = false;                                // at least one motion event: `axes` is real
        AndroidMotionAxes axes;
    };
    Pad& pad_for(int deviceId);  // the pad of a device; a new device takes the first free slot or the longest silent one
    Pad* find(int deviceId);

    std::array<Pad, kMaxGamepads> pads_;
    std::uint64_t tick_ = 0;
    bool waitForInfo_ = false;
};

}  // namespace fa
