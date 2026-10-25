// Android gamepads. sokol_app owns the NativeActivity's AInputQueue and has ONE official hook into it:
// sapp_desc.android.native_event_cb. It is called for every input event, on the looper thread that also runs the frame
// callback, BEFORE sokol's own touch and key handling, and an event it returns true for is marked handled and never
// reaches them. to_sapp_desc() installs android_gamepad_event there, so external/ stays untouched. Consuming is
// what we need anyway: sokol would treat every motion event, a stick's included, as a touch, and Android would turn
// unhandled pad buttons into system keys.
//
// This file only reads AInputEvent; what the keys and axes mean lives in android_gamepads.cpp (unit-tested on every
// OS). The static_asserts keep that file's numeric Android constants honest against the NDK headers.
//
// The event API cannot say that a pad was unplugged or what a pad's Z/RZ axes are, so poll_gamepads() asks the Java
// side with JNI, through the activity's JavaVM (sapp_android_get_native_activity()): InputDevice.getDevice(id) is null
// for a device that is gone, and InputDevice.getMotionRange(axis) is null for an axis the device does not report.
// This runs on the sokol_app loop thread (the thread of the frame and input callbacks), only when a pad has not been
// asked yet, about every 2 s, and when the app comes back after a pause of more than a second. The class and method ids
// are looked up once; a check allocates nothing on the C++ side. If JNI fails the pads keep working with the
// "layout unknown" behaviour and keep their slots (see android_gamepads.h). UNTESTED on a device: the decisions are
// unit-tested (android_gamepads.cpp), this glue is only compiled by CI.
#include <android/input.h>
#include <android/keycodes.h>

#include <chrono>
#include <mutex>
#include <string>

#include "android_jni.h"
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
[[maybe_unused]] const bool g_waiting = (g_pads.wait_for_info(true), true);  // a pad is announced once its identity has been asked

bool has_source(int32_t source, int32_t flags) { return (source & flags) == flags; }

float axis(const AInputEvent* e, int32_t id) { return AMotionEvent_getAxisValue(e, id, 0); }

// ---- JNI: android.view.InputDevice -------------------------------------------------------------------------------
struct InputDeviceJni {
    jclass cls = nullptr;               // global reference
    jmethodID getDevice = nullptr;      // static InputDevice getDevice(int id): null when the device is gone
    jmethodID getMotionRange = nullptr; // InputDevice.MotionRange getMotionRange(int axis): null when it has no such axis
    jmethodID getName = nullptr, getDescriptor = nullptr;  // String getName(), String getDescriptor(): the device's name and its stable id
    jmethodID getVendorId = nullptr, getProductId = nullptr;  // int, 0 = unknown
    bool ready = false, failed = false;
};
InputDeviceJni g_jni;

bool init_jni(JNIEnv* env) {
    if (g_jni.ready) return true;
    if (g_jni.failed) return false;
    jclass local = env->FindClass("android/view/InputDevice");  // a framework class: found from a native thread too
    if (android_clear_exception(env) || !local) {
        g_jni.failed = true;
        return false;
    }
    g_jni.cls = static_cast<jclass>(env->NewGlobalRef(local));
    env->DeleteLocalRef(local);
    g_jni.getDevice = env->GetStaticMethodID(g_jni.cls, "getDevice", "(I)Landroid/view/InputDevice;");
    g_jni.getMotionRange = env->GetMethodID(g_jni.cls, "getMotionRange", "(I)Landroid/view/InputDevice$MotionRange;");
    if (android_clear_exception(env) || !g_jni.getDevice || !g_jni.getMotionRange) {
        g_jni.failed = true;
        return false;
    }
    // The identity getters are optional: without them a pad gets an id from its device number and keeps working.
    g_jni.getName = env->GetMethodID(g_jni.cls, "getName", "()Ljava/lang/String;");
    g_jni.getDescriptor = env->GetMethodID(g_jni.cls, "getDescriptor", "()Ljava/lang/String;");
    g_jni.getVendorId = env->GetMethodID(g_jni.cls, "getVendorId", "()I");
    g_jni.getProductId = env->GetMethodID(g_jni.cls, "getProductId", "()I");
    android_clear_exception(env);
    g_jni.ready = true;
    return true;
}

enum class DeviceState { Unknown, Gone, Present };

// Is the device still there, and when `caps` is given, which axes does it report? The AXIS_* numbers of
// InputDevice/MotionEvent are the AMOTION_EVENT_AXIS_* of the NDK.
std::string jni_string(JNIEnv* env, jobject device, jmethodID method) {
    if (!method) return {};
    auto str = static_cast<jstring>(env->CallObjectMethod(device, method));
    if (android_clear_exception(env) || !str) return {};
    std::string out;
    if (const char* chars = env->GetStringUTFChars(str, nullptr)) {
        out = chars;
        env->ReleaseStringUTFChars(str, chars);
    }
    env->DeleteLocalRef(str);
    return out;
}

// The pad's identity: its name, vendor and product, and the descriptor (a hash of the device's serial number or, without one,
// of its vendor, product and location: stable across replugging, which the numeric device id is not).
GamepadInfo query_info(JNIEnv* env, jobject device, int deviceId) {
    GamepadInfo info;
    info.name = jni_string(env, device, g_jni.getName);
    if (g_jni.getVendorId) info.vendor = std::uint16_t(env->CallIntMethod(device, g_jni.getVendorId));
    if (g_jni.getProductId) info.product = std::uint16_t(env->CallIntMethod(device, g_jni.getProductId));
    android_clear_exception(env);
    const std::string descriptor = jni_string(env, device, g_jni.getDescriptor);
    if (info.name.empty()) info.name = "Gamepad";
    info.type = gamepad_type_from_ids(info.vendor, info.name);
    info.id = make_gamepad_id(info.vendor, info.product, info.name, descriptor.empty() ? "device " + std::to_string(deviceId) : descriptor);
    return info;
}

DeviceState query_device(JNIEnv* env, int deviceId, AndroidAxisCaps* caps, GamepadInfo* info) {
    jobject device = env->CallStaticObjectMethod(g_jni.cls, g_jni.getDevice, jint(deviceId));
    if (android_clear_exception(env)) return DeviceState::Unknown;
    if (!device) return DeviceState::Gone;
    if (caps) {
        auto has = [&](int32_t axisId) {
            jobject range = env->CallObjectMethod(device, g_jni.getMotionRange, jint(axisId));
            if (android_clear_exception(env)) return false;
            if (!range) return false;
            env->DeleteLocalRef(range);
            return true;
        };
        caps->z = has(AMOTION_EVENT_AXIS_Z);
        caps->rz = has(AMOTION_EVENT_AXIS_RZ);
        caps->rx = has(AMOTION_EVENT_AXIS_RX);
        caps->ry = has(AMOTION_EVENT_AXIS_RY);
        caps->ltrigger = has(AMOTION_EVENT_AXIS_LTRIGGER);
        caps->rtrigger = has(AMOTION_EVENT_AXIS_RTRIGGER);
        caps->brake = has(AMOTION_EVENT_AXIS_BRAKE);
        caps->gas = has(AMOTION_EVENT_AXIS_GAS);
    }
    if (info) *info = query_info(env, device, deviceId);
    env->DeleteLocalRef(device);
    return DeviceState::Present;
}

// One pass over the pads: release the unplugged ones, give the new ones their layout. The JNI calls run outside the lock.
void check_devices() {
    int ids[kMaxGamepads];
    bool wantsLayout[kMaxGamepads];
    bool any = false;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        for (int i = 0; i < kMaxGamepads; ++i) {
            ids[i] = g_pads.device_id(i);
            wantsLayout[i] = g_pads.needs_layout(i);
            any = any || ids[i] >= 0;
        }
    }
    if (!any) return;

    DeviceState states[kMaxGamepads] = {};
    AndroidAxisCaps caps[kMaxGamepads] = {};
    GamepadInfo infos[kMaxGamepads];
    if (JNIEnv* env = android_thread_env(); env && init_jni(env) && env->PushLocalFrame(32) == JNI_OK) {
        for (int i = 0; i < kMaxGamepads; ++i)
            if (ids[i] >= 0) states[i] = query_device(env, ids[i], wantsLayout[i] ? &caps[i] : nullptr, wantsLayout[i] ? &infos[i] : nullptr);
        env->PopLocalFrame(nullptr);
    }

    std::lock_guard<std::mutex> lock(g_mutex);
    for (int i = 0; i < kMaxGamepads; ++i) {
        if (ids[i] < 0) continue;
        if (states[i] == DeviceState::Gone) g_pads.release_device(ids[i]);
        else if (wantsLayout[i]) {  // Unknown: JNI failed, ask no more and let the pad use the layout-unknown behaviour
            if (states[i] == DeviceState::Present) g_pads.set_info(ids[i], infos[i]);
            else  // no name, no ids: the pad is "a gamepad, Android device N"
                g_pads.set_info(ids[i], GamepadInfo{make_gamepad_id(0, 0, "Gamepad", "device " + std::to_string(ids[i])), "Gamepad", 0, 0, GamepadType::Generic});
            g_pads.set_layout(ids[i], states[i] == DeviceState::Present ? android_layout_for(caps[i]) : AndroidLayout{});
        }
    }
}

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
    static unsigned frame = 0;
    static std::chrono::steady_clock::time_point lastPoll{};
    // poll_gamepads() is not called while the app is paused or unfocused: a gap of more than a second means it is back
    // (a pad may have been unplugged meanwhile). Otherwise look about every 2 s (at 60 fps), and at once for a new pad.
    const auto now = std::chrono::steady_clock::now();
    bool check = now - lastPoll > std::chrono::seconds(1) || (++frame % 120) == 0;
    lastPoll = now;
    if (!check) {
        std::lock_guard<std::mutex> lock(g_mutex);
        check = g_pads.any_needs_layout();
    }
    if (check) check_devices();
    std::lock_guard<std::mutex> lock(g_mutex);
    g_pads.feed(in);
}

}  // namespace fa
