// Android gamepads. sokol_app owns the NativeActivity's AInputQueue and has ONE official hook into it:
// sapp_desc.android.native_event_cb. It is called for every input event, on the looper thread that also runs the frame
// callback, BEFORE sokol's own touch and key handling, and an event it returns true for is marked handled and never
// reaches them. to_sapp_desc() installs android_gamepad_event there, so external/ stays untouched. Consuming is
// what we need anyway: sokol would treat every motion event, a stick's included, as a touch, and Android would turn
// unhandled pad buttons into system keys.
//
// This file only reads AInputEvent; what the keys and axes mean lives in android_gamepads.cpp (unit-tested on every
// OS). The static_asserts keep that file's numeric Android constants honest against the NDK headers.
#include <android/input.h>
#include <android/keycodes.h>

#include <mutex>

#include "fa/platform/android_gamepads.h"
#include "fa/platform/gamepad.h"

namespace fa {

namespace {

static_assert(kAndroidKeyDpadUp == AKEYCODE_DPAD_UP && kAndroidKeyDpadDown == AKEYCODE_DPAD_DOWN &&
                  kAndroidKeyDpadLeft == AKEYCODE_DPAD_LEFT && kAndroidKeyDpadRight == AKEYCODE_DPAD_RIGHT &&
                  kAndroidKeyDpadCenter == AKEYCODE_DPAD_CENTER,
              "kAndroidKeyDpad* must match android/keycodes.h");
static_assert(kAndroidKeyButtonA == AKEYCODE_BUTTON_A && kAndroidKeyButtonB == AKEYCODE_BUTTON_B &&
                  kAndroidKeyButtonC == AKEYCODE_BUTTON_C && kAndroidKeyButtonX == AKEYCODE_BUTTON_X &&
                  kAndroidKeyButtonY == AKEYCODE_BUTTON_Y && kAndroidKeyButtonZ == AKEYCODE_BUTTON_Z &&
                  kAndroidKeyButtonL1 == AKEYCODE_BUTTON_L1 && kAndroidKeyButtonR1 == AKEYCODE_BUTTON_R1 &&
                  kAndroidKeyButtonL2 == AKEYCODE_BUTTON_L2 && kAndroidKeyButtonR2 == AKEYCODE_BUTTON_R2 &&
                  kAndroidKeyButtonThumbL == AKEYCODE_BUTTON_THUMBL && kAndroidKeyButtonThumbR == AKEYCODE_BUTTON_THUMBR &&
                  kAndroidKeyButtonStart == AKEYCODE_BUTTON_START && kAndroidKeyButtonSelect == AKEYCODE_BUTTON_SELECT &&
                  kAndroidKeyButtonMode == AKEYCODE_BUTTON_MODE,
              "kAndroidKeyButton* must match android/keycodes.h");
static_assert(kAndroidKeyButton1 == AKEYCODE_BUTTON_1 && kAndroidKeyButton16 == AKEYCODE_BUTTON_16 &&
                  AKEYCODE_BUTTON_16 - AKEYCODE_BUTTON_1 == 15,
              "BUTTON_1..BUTTON_16 must be consecutive");

std::mutex g_mutex;  // the input callback and the frame callback share a thread today; this keeps it true to the letter
AndroidGamepads g_pads;

bool has_source(int32_t source, int32_t flags) { return (source & flags) == flags; }

float axis(const AInputEvent* e, int32_t id) { return AMotionEvent_getAxisValue(e, id, 0); }

}  // namespace

bool android_gamepad_event(const void* nativeEvent) {
    const auto* e = static_cast<const AInputEvent*>(nativeEvent);
    const int32_t source = AInputEvent_getSource(e);
    if (!has_source(source, AINPUT_SOURCE_GAMEPAD) && !has_source(source, AINPUT_SOURCE_JOYSTICK) &&
        !has_source(source, AINPUT_SOURCE_DPAD))
        return false;  // touch screen, mouse, keyboard...: sokol's business
    const int device = AInputEvent_getDeviceId(e);
    const int32_t type = AInputEvent_getType(e);

    if (type == AINPUT_EVENT_TYPE_KEY) {
        const int32_t action = AKeyEvent_getAction(e);
        const int code = AKeyEvent_getKeyCode(e);
        if (action != AKEY_EVENT_ACTION_DOWN && action != AKEY_EVENT_ACTION_UP) return AndroidGamepads::is_gamepad_key(code);
        std::lock_guard<std::mutex> lock(g_mutex);
        return g_pads.on_key(device, code, action == AKEY_EVENT_ACTION_DOWN);
    }
    if (type == AINPUT_EVENT_TYPE_MOTION && has_source(source, AINPUT_SOURCE_JOYSTICK)) {
        AndroidMotionAxes a;
        a.x = axis(e, AMOTION_EVENT_AXIS_X);
        a.y = axis(e, AMOTION_EVENT_AXIS_Y);
        a.z = axis(e, AMOTION_EVENT_AXIS_Z);
        a.rz = axis(e, AMOTION_EVENT_AXIS_RZ);
        a.rx = axis(e, AMOTION_EVENT_AXIS_RX);
        a.ry = axis(e, AMOTION_EVENT_AXIS_RY);
        a.hatX = axis(e, AMOTION_EVENT_AXIS_HAT_X);
        a.hatY = axis(e, AMOTION_EVENT_AXIS_HAT_Y);
        a.ltrigger = axis(e, AMOTION_EVENT_AXIS_LTRIGGER);
        a.rtrigger = axis(e, AMOTION_EVENT_AXIS_RTRIGGER);
        a.brake = axis(e, AMOTION_EVENT_AXIS_BRAKE);
        a.gas = axis(e, AMOTION_EVENT_AXIS_GAS);
        std::lock_guard<std::mutex> lock(g_mutex);
        g_pads.on_motion(device, a);
        return true;
    }
    return false;
}

void poll_gamepads(Input& in) {
    std::lock_guard<std::mutex> lock(g_mutex);
    g_pads.feed(in);
}

}  // namespace fa
