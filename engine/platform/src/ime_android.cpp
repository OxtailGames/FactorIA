// The IME backend of Android: composition through an InputConnection.
//
// A NativeActivity has no text editor, so on its own a keyboard can only send keys (android_keys.cpp). The engine's Java
// class factoria.engine.Ime (platforms/android/app/src/main/java/factoria/engine/Ime.java, part of every exported
// project) adds a view that is a text editor while a TextField has the focus; the input method's calls on its connection
// come back here as native methods, on the app's UI thread, and wait in an ime_ic::Session (ime_ic.h: the decisions,
// unit-tested on every OS) until the game thread feeds them into Input (ime_android_poll, from mobile_poll).
//
// This file is the JNI glue, on the sokol_app loop thread (the game's): it loads the class through the activity's class
// loader the first time the IME is turned on, registers the native methods and calls the static methods of Ime, which
// post their work to the UI thread. Whatever fails (an APK without the class: a project with its own manifest and
// android:hasCode="false", a JNI call that throws) leaves the IME off, logged once: the keyboard then sends keys as before.
//
// UNTESTED on a device by the engine's tests: the decisions are unit-tested, this glue is compiled by CI.
#include <android/native_activity.h>
#include <jni.h>

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <string>
#include <utility>
#include <vector>

#include "android_jni.h"
#include "fa/core/log.h"
#include "fa/platform/ime.h"
#include "ime_android.h"
#include "ime_ic.h"
#include "ime_impl.h"
#include "sokol_app.h"

namespace fa {

namespace {

ime_ic::Session g_session;

struct Bridge {
    jclass cls = nullptr;  // global reference to factoria.engine.Ime
    jmethodID setEnabled = nullptr, restart = nullptr, setCaret = nullptr, showKeyboard = nullptr;
    bool ready = false, failed = false;
};
Bridge g_bridge;          // the game thread only
bool g_attached = false;  // between app.cpp's on_init and on_cleanup: the UI's teardown after that tells the OS nothing

// ---- Java -> C++: the UI thread ---------------------------------------------------------------------------------------
std::u16string read_string(JNIEnv* env, jstring s) {
    if (!s) return {};
    const jsize n = std::min<jsize>(env->GetStringLength(s), jsize(ime_ic::kMaxText));
    std::vector<jchar> units(std::size_t(std::max<jsize>(n, 0)));
    if (n > 0) env->GetStringRegion(s, 0, n, units.data());
    if (android_clear_exception(env)) return {};
    std::u16string out;
    out.reserve(units.size());
    for (jchar u : units) out.push_back(char16_t(u));
    return out;
}

void push(ime_ic::Event e) {
    if (g_session.push(std::move(e))) return;
    static bool warned = false;  // the UI thread only
    if (!warned) {
        warned = true;
        FA_WARN("platform", "IME: more than {} input method events waited for the game; the rest are dropped",
                ime_ic::kMaxQueued);
    }
}

ime_ic::Event event(ime_ic::Event::Kind kind, jint generation) {
    ime_ic::Event e;
    e.kind = kind;
    e.generation = std::int32_t(generation);
    return e;
}

void JNICALL native_compose(JNIEnv* env, jclass, jint generation, jstring text, jint cursor, jintArray clauses) {
    ime_ic::Event e = event(ime_ic::Event::Kind::Compose, generation);
    e.text = read_string(env, text);
    e.cursor = int(cursor);
    if (clauses) {
        const jsize n = std::min<jsize>(env->GetArrayLength(clauses), jsize(2 * ime_ic::kMaxClauses));
        std::vector<jint> v(std::size_t(std::max<jsize>(n, 0)));
        if (n > 0) env->GetIntArrayRegion(clauses, 0, n, v.data());
        if (!android_clear_exception(env)) {
            for (std::size_t i = 0; i + 1 < v.size(); i += 2) {
                if (v[i] < 0 || v[i + 1] <= v[i]) continue;  // a span Java could not place (-1)
                e.clauses.push_back({std::size_t(v[i]), std::size_t(v[i + 1] - v[i]), true});
            }
        }
    }
    push(std::move(e));
}

void JNICALL native_commit(JNIEnv* env, jclass, jint generation, jstring text) {
    ime_ic::Event e = event(ime_ic::Event::Kind::Commit, generation);
    e.text = read_string(env, text);
    push(std::move(e));
}

void JNICALL native_finish(JNIEnv*, jclass, jint generation) { push(event(ime_ic::Event::Kind::Finish, generation)); }

void JNICALL native_delete(JNIEnv*, jclass, jint generation, jint before, jint after) {
    ime_ic::Event e = event(ime_ic::Event::Kind::Delete, generation);
    e.before = int(before);
    e.after = int(after);
    push(std::move(e));
}

void JNICALL native_action(JNIEnv*, jclass, jint generation) { push(event(ime_ic::Event::Kind::Action, generation)); }

void JNICALL native_close(JNIEnv*, jclass, jint generation) { push(event(ime_ic::Event::Kind::Close, generation)); }

// ---- C++ -> Java: the game thread -------------------------------------------------------------------------------------
void give_up(const char* what) {
    g_bridge.failed = true;
    g_bridge.ready = false;
    FA_WARN(
        "platform",
        "IME: {}; composition (Japanese, Chinese, Korean, predictive words) is off and the keyboard sends keys. The "
        "class factoria.engine.Ime comes with every Android project `factoria export` writes; a project with its "
        "own AndroidManifest.xml needs android:hasCode=\"true\"",
        what);
}

// factoria.engine.Ime through the activity's class loader (FindClass on a native thread sees only the system's classes),
// with its native methods registered. Once; a failure is final.
bool ensure_bridge(JNIEnv* env, jobject activity) {
    if (g_bridge.ready) return true;
    if (g_bridge.failed) return false;
    if (env->PushLocalFrame(16) != JNI_OK) {
        android_clear_exception(env);
        give_up("no room for JNI references");
        return false;
    }
    jclass cls = nullptr;
    jclass activityCls = env->GetObjectClass(activity);
    jmethodID getLoader = env->GetMethodID(activityCls, "getClassLoader", "()Ljava/lang/ClassLoader;");
    jobject loader =
        (!android_clear_exception(env) && getLoader) ? env->CallObjectMethod(activity, getLoader) : nullptr;
    if (!android_clear_exception(env) && loader) {
        jmethodID loadClass =
            env->GetMethodID(env->GetObjectClass(loader), "loadClass", "(Ljava/lang/String;)Ljava/lang/Class;");
        jstring name =
            (!android_clear_exception(env) && loadClass) ? env->NewStringUTF("factoria.engine.Ime") : nullptr;
        if (name) cls = static_cast<jclass>(env->CallObjectMethod(loader, loadClass, name));
        if (android_clear_exception(env)) cls = nullptr;
    }
    if (!cls) {
        env->PopLocalFrame(nullptr);
        give_up("this APK has no class factoria.engine.Ime");
        return false;
    }
    static const JNINativeMethod natives[] = {
        {"nativeCompose", "(ILjava/lang/String;I[I)V", reinterpret_cast<void*>(native_compose)},
        {"nativeCommit", "(ILjava/lang/String;)V", reinterpret_cast<void*>(native_commit)},
        {"nativeFinish", "(I)V", reinterpret_cast<void*>(native_finish)},
        {"nativeDelete", "(III)V", reinterpret_cast<void*>(native_delete)},
        {"nativeAction", "(I)V", reinterpret_cast<void*>(native_action)},
        {"nativeClose", "(I)V", reinterpret_cast<void*>(native_close)},
    };
    const bool registered = env->RegisterNatives(cls, natives, jint(sizeof natives / sizeof natives[0])) == JNI_OK &&
                            !android_clear_exception(env);
    Bridge b;
    if (registered) {
        b.setEnabled = env->GetStaticMethodID(cls, "setEnabled", "(Landroid/app/Activity;ZI)V");
        b.restart = env->GetStaticMethodID(cls, "restart", "(Landroid/app/Activity;I)V");
        b.setCaret = env->GetStaticMethodID(cls, "setCaret", "(Landroid/app/Activity;FFFFII)V");
        b.showKeyboard = env->GetStaticMethodID(cls, "showKeyboard", "(Landroid/app/Activity;Z)V");
    }
    const bool found =
        registered && !android_clear_exception(env) && b.setEnabled && b.restart && b.setCaret && b.showKeyboard;
    if (found) b.cls = static_cast<jclass>(env->NewGlobalRef(cls));
    env->PopLocalFrame(nullptr);
    android_clear_exception(env);
    if (!found || !b.cls) {
        give_up("the class factoria.engine.Ime is not the one this engine expects (an export of another version?)");
        return false;
    }
    b.ready = true;
    g_bridge = b;
    return true;
}

// Calls a static method of Ime with the activity first. A call that throws turns the IME off for good.
template <typename... Args>
bool call(jmethodID method, Args... args) {
    if (!g_bridge.ready) return false;
    JNIEnv* env = android_thread_env();
    const ANativeActivity* act = android_activity();
    if (!env || !act || !act->clazz) return false;
    env->CallStaticVoidMethod(g_bridge.cls, method, act->clazz, args...);
    if (android_clear_exception(env)) {
        give_up("a call into factoria.engine.Ime threw");
        return false;
    }
    return true;
}

}  // namespace

void ime_android_attach(bool attached) {
    if (attached == g_attached) return;
    if (!attached) {
        ime_backend_set_enabled(false);  // the text view leaves the focus (a no-op when it was off)
        g_session.cancel();
    }
    g_attached = attached;
    if (!attached) return;
    const ImeState state = ime_state();  // what the UI asked before the window was up
    if (state.enabled) ime_backend_set_enabled(true);
}

void ime_backend_set_enabled(bool enabled) {
    if (!g_attached) return;  // not attached (tests, the editor, the engine's teardown after the app ended)
    const std::int32_t generation = g_session.set_enabled(enabled);
    if (enabled && !g_bridge.ready && !g_bridge.failed) {
        JNIEnv* env = android_thread_env();
        const ANativeActivity* act = android_activity();
        if (!env || !act || !act->clazz || !ensure_bridge(env, act->clazz)) return;
    }
    call(g_bridge.setEnabled, jboolean(enabled ? JNI_TRUE : JNI_FALSE), jint(generation));
}

void ime_backend_set_caret_rect(Rect r) {
    if (!g_attached) return;
    call(g_bridge.setCaret, jfloat(r.x), jfloat(r.y), jfloat(r.w), jfloat(r.h), jint(sapp_width()),
         jint(sapp_height()));
}

void ime_backend_cancel() {
    if (!g_attached) return;
    if (g_session.cancel()) call(g_bridge.restart, jint(g_session.generation()));
}

void ime_android_poll(Input& input) { g_session.feed(input); }

void ime_android_push_keys(const std::vector<AndroidKeys::Item>& items) {
    if (g_session.push_keys(items)) return;
    static bool warned = false;  // the game thread only
    if (!warned) {
        warned = true;
        FA_WARN("platform",
                "input: more than {} keys and input method events waited for one frame; the rest are dropped",
                ime_ic::kMaxQueued);
    }
}

bool ime_android_show_keyboard(bool show) { return call(g_bridge.showKeyboard, jboolean(show ? JNI_TRUE : JNI_FALSE)); }

}  // namespace fa
