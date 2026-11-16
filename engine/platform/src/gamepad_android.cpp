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
//
// Rumble (the two gamepad_backend_rumble* hooks at the end) also goes through JNI, on the same loop thread, once per
// request and not per frame. A pad's motors are the vibrators of its InputDevice: API 31+ has getVibratorManager() (one
// vibrator: a combined effect; two: low on the first and high on the second, as one CombinedVibration), API 26-30 has
// getVibrator(). The question "can this pad rumble" is asked once per Android device id and cached. Rumble needs no more
// permission than the manifest already has (VIBRATE, for input.vibrate()); the framework's input-device vibrators do not
// check it, as far as the documentation says. Also unverified on a device.
#include <android/input.h>
#include <android/keycodes.h>

#include <algorithm>
#include <chrono>
#include <mutex>
#include <string>

#include "android_jni.h"
#include "fa/platform/android_gamepads.h"
#include "fa/platform/gamepad.h"
#include "fa/platform/gamepad_rumble_map.h"

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
                  kAndroidKeyButtonThumbL == AKEYCODE_BUTTON_THUMBL &&
                  kAndroidKeyButtonThumbR == AKEYCODE_BUTTON_THUMBR &&
                  kAndroidKeyButtonStart == AKEYCODE_BUTTON_START &&
                  kAndroidKeyButtonSelect == AKEYCODE_BUTTON_SELECT && kAndroidKeyButtonMode == AKEYCODE_BUTTON_MODE,
              "kAndroidKeyButton* must match android/keycodes.h");
static_assert(kAndroidKeyButton1 == AKEYCODE_BUTTON_1 && kAndroidKeyButton16 == AKEYCODE_BUTTON_16 &&
                  AKEYCODE_BUTTON_16 - AKEYCODE_BUTTON_1 == 15,
              "BUTTON_1..BUTTON_16 must be consecutive");

std::mutex g_mutex;  // the input callback and the frame callback share a thread today; this keeps it true to the letter
AndroidGamepads g_pads;
[[maybe_unused]] const bool g_waiting =
    (g_pads.wait_for_info(true), true);  // a pad is announced once its identity has been asked

bool has_source(int32_t source, int32_t flags) { return (source & flags) == flags; }

float axis(const AInputEvent* e, int32_t id) { return AMotionEvent_getAxisValue(e, id, 0); }

// ---- JNI: android.view.InputDevice -------------------------------------------------------------------------------
struct InputDeviceJni {
    jclass cls = nullptr;           // global reference
    jmethodID getDevice = nullptr;  // static InputDevice getDevice(int id): null when the device is gone
    jmethodID getMotionRange =
        nullptr;  // InputDevice.MotionRange getMotionRange(int axis): null when it has no such axis
    jmethodID getName = nullptr,
              getDescriptor = nullptr;  // String getName(), String getDescriptor(): the device's name and its stable id
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
    info.id = make_gamepad_id(info.vendor, info.product, info.name,
                              descriptor.empty() ? "device " + std::to_string(deviceId) : descriptor);
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
            if (ids[i] >= 0)
                states[i] = query_device(env, ids[i], wantsLayout[i] ? &caps[i] : nullptr,
                                         wantsLayout[i] ? &infos[i] : nullptr);
        env->PopLocalFrame(nullptr);
    }

    std::lock_guard<std::mutex> lock(g_mutex);
    for (int i = 0; i < kMaxGamepads; ++i) {
        if (ids[i] < 0) continue;
        if (states[i] == DeviceState::Gone)
            g_pads.release_device(ids[i]);
        else if (wantsLayout[i]) {  // Unknown: JNI failed, ask no more and let the pad use the layout-unknown behaviour
            if (states[i] == DeviceState::Present)
                g_pads.set_info(ids[i], infos[i]);
            else  // no name, no ids: the pad is "a gamepad, Android device N"
                g_pads.set_info(ids[i],
                                GamepadInfo{make_gamepad_id(0, 0, "Gamepad", "device " + std::to_string(ids[i])),
                                            "Gamepad", 0, 0, GamepadType::Generic});
            g_pads.set_layout(ids[i],
                              states[i] == DeviceState::Present ? android_layout_for(caps[i]) : AndroidLayout{});
        }
    }
}

// ---- rumble: android.os.Vibrator / VibratorManager of the InputDevice ---------------------------------------------------
struct VibratorJni {
    jclass vibrationEffect = nullptr, combined = nullptr;  // global references (they have static methods)
    jmethodID getVibratorManager = nullptr;                // InputDevice.getVibratorManager(): API 31+, null before
    jmethodID getVibrator = nullptr;                       // InputDevice.getVibrator()
    jmethodID getVibratorIds = nullptr, managerVibrate = nullptr, managerCancel = nullptr;  // VibratorManager (API 31)
    jmethodID createParallel = nullptr, startParallel = nullptr, addVibrator = nullptr, combine = nullptr;
    jmethodID createOneShot = nullptr;  // VibrationEffect.createOneShot(long, int), API 26
    jmethodID hasVibrator = nullptr, vibrate = nullptr, cancel = nullptr;  // Vibrator
    bool ready = false, failed = false;
};
VibratorJni g_vib;

jclass find_class(JNIEnv* env, const char* name) {  // a local reference, or null when the class does not exist
    jclass local = env->FindClass(name);
    return android_clear_exception(env) ? nullptr : local;
}
jclass global_class(JNIEnv* env, const char* name) {
    jclass local = find_class(env, name);
    if (!local) return nullptr;
    auto global = static_cast<jclass>(env->NewGlobalRef(local));
    env->DeleteLocalRef(local);
    return global;
}

bool init_vibrator_jni(JNIEnv* env) {
    if (g_vib.ready) return true;
    if (g_vib.failed) return false;
    VibratorJni v;
    // The minimum API is 26, so VibrationEffect, Vibrator and InputDevice.getVibrator() always exist; the manager is 31+.
    jclass inputDevice = find_class(env, "android/view/InputDevice");
    jclass vibrator = find_class(env, "android/os/Vibrator");
    v.vibrationEffect = global_class(env, "android/os/VibrationEffect");  // the classes that are called statically stay
    if (!inputDevice || !vibrator || !v.vibrationEffect) {
        g_vib.failed = true;
        return false;
    }
    v.getVibrator = env->GetMethodID(inputDevice, "getVibrator", "()Landroid/os/Vibrator;");
    v.hasVibrator = env->GetMethodID(vibrator, "hasVibrator", "()Z");
    v.vibrate = env->GetMethodID(vibrator, "vibrate", "(Landroid/os/VibrationEffect;)V");
    v.cancel = env->GetMethodID(vibrator, "cancel", "()V");
    v.createOneShot = env->GetStaticMethodID(v.vibrationEffect, "createOneShot", "(JI)Landroid/os/VibrationEffect;");
    const bool basic =
        !android_clear_exception(env) && v.getVibrator && v.hasVibrator && v.vibrate && v.cancel && v.createOneShot;
    // The manager classes exist on API 31+ only: a missing one is not an error.
    if (basic) {
        jclass manager = find_class(env, "android/os/VibratorManager");
        v.combined = manager ? global_class(env, "android/os/CombinedVibration") : nullptr;
        jclass parallel = v.combined ? find_class(env, "android/os/CombinedVibration$ParallelCombination") : nullptr;
        if (manager && v.combined && parallel) {
            v.getVibratorManager =
                env->GetMethodID(inputDevice, "getVibratorManager", "()Landroid/os/VibratorManager;");
            v.getVibratorIds = env->GetMethodID(manager, "getVibratorIds", "()[I");
            v.managerVibrate = env->GetMethodID(manager, "vibrate", "(Landroid/os/CombinedVibration;)V");
            v.managerCancel = env->GetMethodID(manager, "cancel", "()V");
            v.createParallel = env->GetStaticMethodID(v.combined, "createParallel",
                                                      "(Landroid/os/VibrationEffect;)Landroid/os/CombinedVibration;");
            v.startParallel = env->GetStaticMethodID(v.combined, "startParallel",
                                                     "()Landroid/os/CombinedVibration$ParallelCombination;");
            v.addVibrator = env->GetMethodID(parallel, "addVibrator",
                                             "(ILandroid/os/VibrationEffect;)"
                                             "Landroid/os/CombinedVibration$ParallelCombination;");
            v.combine = env->GetMethodID(parallel, "combine", "()Landroid/os/CombinedVibration;");
            if (android_clear_exception(env) || !v.getVibratorManager || !v.getVibratorIds || !v.managerVibrate ||
                !v.managerCancel || !v.createParallel || !v.startParallel || !v.addVibrator || !v.combine)
                v.getVibratorManager = nullptr;  // use getVibrator() only
        }
        if (manager) env->DeleteLocalRef(manager);
        if (parallel) env->DeleteLocalRef(parallel);
    }
    if (inputDevice) env->DeleteLocalRef(inputDevice);
    if (vibrator) env->DeleteLocalRef(vibrator);
    if (!basic) {
        g_vib.failed = true;
        return false;
    }
    g_vib = v;
    g_vib.ready = true;
    return true;
}

// What a pad's motors are, asked once per Android device id.
struct PadRumble {
    int deviceId = -1;  // the device this answer is for
    bool can = false;
    std::string why;
    int vibrators = 0;     // via the manager: how many (1 = combined, 2 or more: low and high)
    jint ids[2] = {0, 0};  // the first two vibrator ids of the manager
    bool viaManager = false;
    bool playing = false;
};
PadRumble g_rumble[kMaxGamepads];

void probe_rumble(JNIEnv* env, int deviceId, PadRumble& r) {
    r = PadRumble{};
    r.deviceId = deviceId;
    if (!init_vibrator_jni(env)) {
        r.why = "Android's vibrator classes could not be reached through JNI";
        return;
    }
    jobject device = env->CallStaticObjectMethod(g_jni.cls, g_jni.getDevice, jint(deviceId));
    if (android_clear_exception(env) || !device) {
        r.why = "Android no longer lists this pad";
        return;
    }
    if (g_vib.getVibratorManager) {  // API 31+
        jobject manager = env->CallObjectMethod(device, g_vib.getVibratorManager);
        if (!android_clear_exception(env) && manager) {
            auto ids = static_cast<jintArray>(env->CallObjectMethod(manager, g_vib.getVibratorIds));
            if (!android_clear_exception(env) && ids) {
                const jsize n = env->GetArrayLength(ids);
                if (n > 0) {
                    jint first[2] = {0, 0};
                    env->GetIntArrayRegion(ids, 0, std::min<jsize>(n, 2), first);
                    if (!android_clear_exception(env)) {
                        r.can = r.viaManager = true;
                        r.vibrators = n;
                        r.ids[0] = first[0];
                        r.ids[1] = n > 1 ? first[1] : first[0];
                    }
                }
                env->DeleteLocalRef(ids);
            }
            env->DeleteLocalRef(manager);
        }
    }
    if (!r.can) {  // API 26-30, or a manager with no vibrators
        jobject vibrator = env->CallObjectMethod(device, g_vib.getVibrator);
        if (!android_clear_exception(env) && vibrator) {
            if (env->CallBooleanMethod(vibrator, g_vib.hasVibrator) && !android_clear_exception(env)) {
                r.can = true;
                r.vibrators = 1;
            }
            android_clear_exception(env);
            env->DeleteLocalRef(vibrator);
        }
    }
    env->DeleteLocalRef(device);
    if (!r.can)
        r.why =
            "Android reports no vibration motor for this pad (InputDevice.getVibratorManager() and getVibrator() find "
            "none: many pads, above all over Bluetooth, do not expose their rumble motors to Android)";
}

// Cancels what plays on the pad's vibrators.
bool cancel_rumble(JNIEnv* env, int deviceId, const PadRumble& r) {
    jobject device = env->CallStaticObjectMethod(g_jni.cls, g_jni.getDevice, jint(deviceId));
    if (android_clear_exception(env) || !device) return false;
    bool ok = false;
    if (r.viaManager) {
        if (jobject manager = env->CallObjectMethod(device, g_vib.getVibratorManager);
            !android_clear_exception(env) && manager) {
            env->CallVoidMethod(manager, g_vib.managerCancel);
            ok = !android_clear_exception(env);
            env->DeleteLocalRef(manager);
        }
    } else if (jobject vibrator = env->CallObjectMethod(device, g_vib.getVibrator);
               !android_clear_exception(env) && vibrator) {
        env->CallVoidMethod(vibrator, g_vib.cancel);
        ok = !android_clear_exception(env);
        env->DeleteLocalRef(vibrator);
    }
    env->DeleteLocalRef(device);
    return ok;
}

jobject one_shot(JNIEnv* env, long long millis, int amplitude) {
    jobject effect =
        env->CallStaticObjectMethod(g_vib.vibrationEffect, g_vib.createOneShot, jlong(millis), jint(amplitude));
    return android_clear_exception(env) ? nullptr : effect;
}

bool start_rumble(JNIEnv* env, int deviceId, const PadRumble& r, const AndroidRumble& plan) {
    jobject device = env->CallStaticObjectMethod(g_jni.cls, g_jni.getDevice, jint(deviceId));
    if (android_clear_exception(env) || !device) return false;
    bool ok = false;
    if (r.viaManager) {
        jobject manager = env->CallObjectMethod(device, g_vib.getVibratorManager);
        if (!android_clear_exception(env) && manager) {
            jobject combined = nullptr;
            if (r.vibrators <= 1) {  // one vibrator: one effect on it
                if (jobject effect = one_shot(env, plan.millis, plan.amplitude[0])) {
                    combined = env->CallStaticObjectMethod(g_vib.combined, g_vib.createParallel, effect);
                    env->DeleteLocalRef(effect);
                }
            } else if (jobject builder = env->CallStaticObjectMethod(g_vib.combined, g_vib.startParallel);
                       !android_clear_exception(env) &&
                       builder) {  // low on the first, high on the second; 0 = left out
                bool any = false;
                for (int i = 0; i < 2; ++i) {
                    if (plan.amplitude[i] <= 0) continue;
                    jobject effect = one_shot(env, plan.millis, plan.amplitude[i]);
                    if (!effect) continue;
                    jobject next = env->CallObjectMethod(builder, g_vib.addVibrator, r.ids[i], effect);
                    env->DeleteLocalRef(effect);
                    if (android_clear_exception(env)) continue;
                    if (next) env->DeleteLocalRef(next);  // the builder itself
                    any = true;
                }
                if (any) combined = env->CallObjectMethod(builder, g_vib.combine);
                env->DeleteLocalRef(builder);
            }
            if (android_clear_exception(env)) combined = nullptr;
            if (combined) {
                env->CallVoidMethod(manager, g_vib.managerVibrate, combined);  // replaces what played
                ok = !android_clear_exception(env);
                env->DeleteLocalRef(combined);
            }
            env->DeleteLocalRef(manager);
        }
    } else if (jobject vibrator = env->CallObjectMethod(device, g_vib.getVibrator);
               !android_clear_exception(env) && vibrator) {
        if (jobject effect = one_shot(env, plan.millis, plan.amplitude[0])) {
            env->CallVoidMethod(vibrator, g_vib.vibrate, effect);
            ok = !android_clear_exception(env);
            env->DeleteLocalRef(effect);
        }
        env->DeleteLocalRef(vibrator);
    }
    env->DeleteLocalRef(device);
    return ok;
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
        if (action != AKEY_EVENT_ACTION_DOWN && action != AKEY_EVENT_ACTION_UP)
            return AndroidGamepads::is_gamepad_key(code);
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

GamepadRumbleSupport gamepad_backend_rumble_support(int slot) {
    if (slot < 0 || slot >= kMaxGamepads) return {false, "there is no pad in this slot"};
    int deviceId;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        deviceId = g_pads.device_id(slot);
    }
    if (deviceId < 0) return {false, "there is no pad in this slot"};
    PadRumble& r = g_rumble[slot];
    if (r.deviceId != deviceId) {  // a new pad (or none asked yet): ask Android once
        JNIEnv* env = android_thread_env();
        if (!env || !init_jni(env) || env->PushLocalFrame(32) != JNI_OK) {
            r = PadRumble{};
            return {false, "Android's InputDevice could not be reached through JNI"};
        }
        probe_rumble(env, deviceId, r);
        env->PopLocalFrame(nullptr);
    }
    return {r.can, r.can ? std::string() : r.why};
}

bool gamepad_backend_rumble(int slot, float low, float high, float seconds) {
    if (slot < 0 || slot >= kMaxGamepads) return false;
    PadRumble& r = g_rumble[slot];
    if (!r.can || r.deviceId < 0) return false;
    JNIEnv* env = android_thread_env();
    if (!env || env->PushLocalFrame(32) != JNI_OK) return false;
    bool ok;
    if (seconds <= 0.0f && low <= 0.0f && high <= 0.0f) {  // stop
        ok = !r.playing || cancel_rumble(env, r.deviceId, r);
        r.playing = false;
    } else {
        const AndroidRumble plan = android_rumble(low, high, seconds, r.vibrators);
        if (plan.amplitude[0] == 0 && plan.amplitude[1] == 0) {
            ok = cancel_rumble(env, r.deviceId, r);
            r.playing = false;
        } else {
            ok = start_rumble(env, r.deviceId, r, plan);
            r.playing = ok;
        }
    }
    env->PopLocalFrame(nullptr);
    return ok;
}

}  // namespace fa
