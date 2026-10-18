// Android: the system Back button, keyboards (hardware and on-screen), the safe area and vibration.
//
// sokol_app has one hook into the NativeActivity's input queue, sapp_desc.android.native_event_cb (see
// gamepad_android.cpp): it sees every AInputEvent on the sokol_app loop thread, before sokol's own handling, and an event
// it returns true for is consumed. to_sapp_desc() installs mobile_native_event there, which first offers the event to the
// gamepads and then handles the keys: the Back button becomes Input::on_back (sokol_app would end the app), the other
// keys become key edges and typed characters. What the keys mean is decided in android_keys.cpp (unit-tested on every OS);
// this file only reads the AInputEvent and talks to the Java side with JNI, through the activity's JavaVM
// (sapp_android_get_native_activity()), on the sokol_app loop thread. Framework classes only, no Java code of ours.
//
// UNTESTED on a device: the decisions are unit-tested, this glue is only compiled by CI (and syntax-checked with the NDK).
#include <android/input.h>
#include <android/keycodes.h>

#include <algorithm>
#include <mutex>

#include "android_jni.h"
#include "fa/core/log.h"
#include "fa/platform/android_keys.h"
#include "fa/platform/gamepad.h"
#include "mobile_impl.h"

namespace fa {

namespace {

static_assert(kAndroidKeyBack == AKEYCODE_BACK && kAndroidKey0 == AKEYCODE_0 && kAndroidKey9 == AKEYCODE_9 &&
                  kAndroidKeyA == AKEYCODE_A && kAndroidKeyZ == AKEYCODE_Z,
              "kAndroidKey* must match android/keycodes.h");
static_assert(AKEYCODE_DEL == 67 && AKEYCODE_ENTER == 66 && AKEYCODE_SPACE == 62 && AKEYCODE_FORWARD_DEL == 112 &&
                  AKEYCODE_DPAD_LEFT == 21 && AKEYCODE_ESCAPE == 111 && AKEYCODE_TAB == 61 && AKEYCODE_MOVE_HOME == 122 &&
                  AKEYCODE_NUMPAD_0 == 144 && AKEYCODE_F1 == 131 && AKEYCODE_COMMA == 55 && AKEYCODE_PLUS == 81,
              "the keycodes of android_keys.cpp must match android/keycodes.h");

std::mutex g_mutex;  // the input callback and the frame callback share a thread today; this keeps it true to the letter
AndroidKeys g_keys;
bool g_imeShown = false;  // what we asked of the keyboard last (the system may hide it by itself: Back)

// ---- small JNI helpers: every one returns null / the fallback when the call threw ---------------------------------------
jobject call_object(JNIEnv* env, jobject obj, const char* name, const char* sig) {
    jclass cls = env->GetObjectClass(obj);
    jmethodID id = env->GetMethodID(cls, name, sig);
    if (android_clear_exception(env) || !id) return nullptr;
    jobject result = env->CallObjectMethod(obj, id);
    return android_clear_exception(env) ? nullptr : result;
}

int call_int(JNIEnv* env, jobject obj, const char* name, int fallback = 0) {
    jclass cls = env->GetObjectClass(obj);
    jmethodID id = env->GetMethodID(cls, name, "()I");
    if (android_clear_exception(env) || !id) return fallback;
    const jint result = env->CallIntMethod(obj, id);
    return android_clear_exception(env) ? fallback : int(result);
}

// activity.getSystemService(name)
jobject system_service(JNIEnv* env, jobject activity, const char* name) {
    jclass cls = env->GetObjectClass(activity);
    jmethodID id = env->GetMethodID(cls, "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;");
    if (android_clear_exception(env) || !id) return nullptr;
    jstring key = env->NewStringUTF(name);
    jobject result = env->CallObjectMethod(activity, id, key);
    return android_clear_exception(env) ? nullptr : result;
}

// activity.getWindow().getDecorView()
jobject decor_view(JNIEnv* env, jobject activity) {
    jobject window = call_object(env, activity, "getWindow", "()Landroid/view/Window;");
    return window ? call_object(env, window, "getDecorView", "()Landroid/view/View;") : nullptr;
}

// ---- the character of a key ------------------------------------------------------------------------------------------
struct KeyEventJni {
    jclass cls = nullptr;                // global reference to android.view.KeyEvent
    jmethodID ctor = nullptr;            // KeyEvent(int action, int code)
    jmethodID getUnicodeChar = nullptr;  // int getUnicodeChar(int metaState)
    bool ready = false, failed = false;
};
KeyEventJni g_keyEvent;

bool init_key_event(JNIEnv* env) {
    if (g_keyEvent.ready) return true;
    if (g_keyEvent.failed) return false;
    jclass local = env->FindClass("android/view/KeyEvent");
    if (android_clear_exception(env) || !local) {
        g_keyEvent.failed = true;
        return false;
    }
    g_keyEvent.cls = static_cast<jclass>(env->NewGlobalRef(local));
    env->DeleteLocalRef(local);
    g_keyEvent.ctor = env->GetMethodID(g_keyEvent.cls, "<init>", "(II)V");
    g_keyEvent.getUnicodeChar = env->GetMethodID(g_keyEvent.cls, "getUnicodeChar", "(I)I");
    if (android_clear_exception(env) || !g_keyEvent.ctor || !g_keyEvent.getUnicodeChar) {
        g_keyEvent.failed = true;
        return false;
    }
    g_keyEvent.ready = true;
    return true;
}

// The character `keyCode` types with these meta keys held (shift...), 0 for none. The AMETA_* flags are the META_* of Java.
std::uint32_t typed_character(int keyCode, int32_t metaState) {
    JNIEnv* env = android_thread_env();
    if (!env || !init_key_event(env)) return 0;
    jobject event = env->NewObject(g_keyEvent.cls, g_keyEvent.ctor, jint(AKEY_EVENT_ACTION_DOWN), jint(keyCode));
    if (android_clear_exception(env) || !event) return 0;
    jint ch = env->CallIntMethod(event, g_keyEvent.getUnicodeChar, jint(metaState));
    const bool threw = android_clear_exception(env);
    env->DeleteLocalRef(event);
    // The top bit marks a dead key (an accent waiting for its letter): not a character by itself.
    return (threw || ch <= 0) ? 0 : std::uint32_t(ch);
}

// ---- the safe area -----------------------------------------------------------------------------------------------------
// Window insets of the decor view, in window pixels. API 30+: WindowInsets.getInsets(systemBars | displayCutout), what is
// really covering the window now (a hidden status bar counts for nothing, the keyboard is not a system bar). Before: the
// system window insets (left, top, right) and the display cutout (API 28).
EdgeInsets query_insets(JNIEnv* env, const ANativeActivity* act, float& scale) {
    jobject activity = act->clazz;
    jobject decor = decor_view(env, activity);
    if (!decor) return {};
    jobject insets = call_object(env, decor, "getRootWindowInsets", "()Landroid/view/WindowInsets;");  // null until attached
    if (!insets) return {};
    const int viewWidth = call_int(env, decor, "getWidth");
    scale = viewWidth > 0 && sapp_width() > 0 ? float(sapp_width()) / float(viewWidth) : 1.0f;

    EdgeInsets px;
    if (act->sdkVersion >= 30) {
        jclass typeCls = env->FindClass("android/view/WindowInsets$Type");
        jmethodID systemBars = typeCls ? env->GetStaticMethodID(typeCls, "systemBars", "()I") : nullptr;
        jmethodID displayCutout = typeCls ? env->GetStaticMethodID(typeCls, "displayCutout", "()I") : nullptr;
        if (android_clear_exception(env) || !systemBars || !displayCutout) return {};
        const jint mask = env->CallStaticIntMethod(typeCls, systemBars) | env->CallStaticIntMethod(typeCls, displayCutout);
        jclass insetsCls = env->GetObjectClass(insets);
        jmethodID getInsets = env->GetMethodID(insetsCls, "getInsets", "(I)Landroid/graphics/Insets;");
        if (android_clear_exception(env) || !getInsets) return {};
        jobject rect = env->CallObjectMethod(insets, getInsets, mask);  // android.graphics.Insets: public int fields
        if (android_clear_exception(env) || !rect) return {};
        jclass rectCls = env->GetObjectClass(rect);
        auto side = [&](const char* name) {
            jfieldID f = env->GetFieldID(rectCls, name, "I");
            const float v = (android_clear_exception(env) || !f) ? 0.0f : float(env->GetIntField(rect, f));
            return v;
        };
        px = {side("left"), side("top"), side("right"), side("bottom")};
    } else {
        px = {float(call_int(env, insets, "getSystemWindowInsetLeft")), float(call_int(env, insets, "getSystemWindowInsetTop")),
              float(call_int(env, insets, "getSystemWindowInsetRight")), 0.0f};  // the bottom would include the keyboard
        if (act->sdkVersion >= 28) {
            if (jobject cutout = call_object(env, insets, "getDisplayCutout", "()Landroid/view/DisplayCutout;")) {
                px.left = std::max(px.left, float(call_int(env, cutout, "getSafeInsetLeft")));
                px.top = std::max(px.top, float(call_int(env, cutout, "getSafeInsetTop")));
                px.right = std::max(px.right, float(call_int(env, cutout, "getSafeInsetRight")));
                px.bottom = std::max(px.bottom, float(call_int(env, cutout, "getSafeInsetBottom")));
            }
        }
    }
    return px;
}

}  // namespace

bool mobile_native_event(const void* nativeEvent) {
    if (android_gamepad_event(nativeEvent)) return true;
    const auto* e = static_cast<const AInputEvent*>(nativeEvent);
    if (AInputEvent_getType(e) != AINPUT_EVENT_TYPE_KEY) return false;
    const int32_t action = AKeyEvent_getAction(e);
    if (action != AKEY_EVENT_ACTION_DOWN && action != AKEY_EVENT_ACTION_UP) return false;  // ACTION_MULTIPLE: see android_keys.h
    const int code = AKeyEvent_getKeyCode(e);
    const bool down = action == AKEY_EVENT_ACTION_DOWN;
    const bool repeat = down && AKeyEvent_getRepeatCount(e) > 0;
    const std::uint32_t unicode = down && AndroidKeys::may_type(code) ? typed_character(code, AKeyEvent_getMetaState(e)) : 0;
    std::lock_guard<std::mutex> lock(g_mutex);
    return g_keys.on_key(code, down, unicode, repeat);
}

void mobile_poll(Input& input) {
    std::lock_guard<std::mutex> lock(g_mutex);
    g_keys.feed(input);
}

EdgeInsets mobile_safe_insets() {
    JNIEnv* env = android_thread_env();
    const ANativeActivity* act = android_activity();
    if (!env || !act || !act->clazz || env->PushLocalFrame(32) != JNI_OK) return {};
    float scale = 1.0f;
    EdgeInsets px = query_insets(env, act, scale);
    env->PopLocalFrame(nullptr);
    // Window pixels to framebuffer pixels (they differ only when the framebuffer was made smaller than the window).
    return {px.left * scale, px.top * scale, px.right * scale, px.bottom * scale};
}

void mobile_vibrate(float seconds) {
    JNIEnv* env = android_thread_env();
    const ANativeActivity* act = android_activity();
    if (!env || !act || !act->clazz || env->PushLocalFrame(16) != JNI_OK) return;
    static bool warned = false;
    const jlong ms = jlong(std::clamp(seconds, 0.001f, 10.0f) * 1000.0f);
    bool ok = false;
    if (jobject vibrator = system_service(env, act->clazz, "vibrator")) {
        jclass cls = env->GetObjectClass(vibrator);
        if (act->sdkVersion >= 26) {  // vibrate(long) is deprecated: VibrationEffect.createOneShot(ms, DEFAULT_AMPLITUDE)
            jclass effectCls = env->FindClass("android/os/VibrationEffect");
            jmethodID create = effectCls ? env->GetStaticMethodID(effectCls, "createOneShot", "(JI)Landroid/os/VibrationEffect;") : nullptr;
            jmethodID vibrate = env->GetMethodID(cls, "vibrate", "(Landroid/os/VibrationEffect;)V");
            if (!android_clear_exception(env) && create && vibrate) {
                jobject effect = env->CallStaticObjectMethod(effectCls, create, ms, jint(-1));
                if (!android_clear_exception(env) && effect) {
                    env->CallVoidMethod(vibrator, vibrate, effect);
                    ok = !android_clear_exception(env);
                }
            }
        } else {
            jmethodID vibrate = env->GetMethodID(cls, "vibrate", "(J)V");
            if (!android_clear_exception(env) && vibrate) {
                env->CallVoidMethod(vibrator, vibrate, ms);
                ok = !android_clear_exception(env);
            }
        }
    }
    env->PopLocalFrame(nullptr);
    if (!ok && !warned) {
        warned = true;
        FA_WARN("platform", "vibration failed: this device has no vibrator, or the app lacks the android.permission.VIBRATE "
                            "permission (the FactorIA Android template declares it; a project with its own manifest must too)");
    }
}

// InputMethodManager on the activity's decor view. The NativeActivity's own showSoftInput (what sokol_app calls) does
// nothing on many devices because the decor view is not a text editor; showSoftInput(view, SHOW_FORCED) can say no for the
// same reason, and then toggleSoftInput(SHOW_FORCED, 0) shows the keyboard regardless. Hiding is a plain hide, so it can
// be asked twice. Typed keys arrive as key events (mobile_native_event).
void mobile_show_keyboard(bool show) {
    if (show == g_imeShown && show) return;  // asking to show it again would toggle it away
    JNIEnv* env = android_thread_env();
    const ANativeActivity* act = android_activity();
    if (!env || !act || !act->clazz || env->PushLocalFrame(16) != JNI_OK) return;
    jobject imm = system_service(env, act->clazz, "input_method");
    jobject decor = decor_view(env, act->clazz);
    if (imm && decor) {
        jclass immCls = env->GetObjectClass(imm);
        if (show) {
            const jint kShowForced = 2;  // InputMethodManager.SHOW_FORCED
            jmethodID showSoftInput = env->GetMethodID(immCls, "showSoftInput", "(Landroid/view/View;I)Z");
            bool shown = false;
            if (!android_clear_exception(env) && showSoftInput) {
                shown = env->CallBooleanMethod(imm, showSoftInput, decor, kShowForced) == JNI_TRUE;
                if (android_clear_exception(env)) shown = false;
            }
            if (!shown) {
                jmethodID toggle = env->GetMethodID(immCls, "toggleSoftInput", "(II)V");
                if (!android_clear_exception(env) && toggle) {
                    env->CallVoidMethod(imm, toggle, kShowForced, jint(0));
                    android_clear_exception(env);
                }
            }
        } else {
            jobject token = call_object(env, decor, "getWindowToken", "()Landroid/os/IBinder;");
            jmethodID hide = env->GetMethodID(immCls, "hideSoftInputFromWindow", "(Landroid/os/IBinder;I)Z");
            if (!android_clear_exception(env) && hide && token) {
                env->CallBooleanMethod(imm, hide, token, jint(0));
                android_clear_exception(env);
            }
        }
    }
    env->PopLocalFrame(nullptr);
    g_imeShown = show;
}

}  // namespace fa
