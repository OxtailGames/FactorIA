// JNI helpers shared by the Android files of fa_platform (gamepad_android.cpp, mobile_android.cpp, http_android.cpp,
// websocket_android.cpp, ime_android.cpp...). Private to fa_platform.
// The VM is reached through the activity sokol_app keeps (sapp_android_get_native_activity()). The framework's classes are
// enough for these files; the one Java class of the engine, factoria.engine.Ime, is ime_android.cpp's.
#pragma once

#include <android/native_activity.h>
#include <jni.h>

#include <string>

#include "sokol_app.h"

namespace fa {

inline const ANativeActivity* android_activity() {
    return static_cast<const ANativeActivity*>(sapp_android_get_native_activity());
}

// The JNIEnv of this thread, attaching it to the VM the first time. The sokol_app loop thread is a plain pthread; it stays
// attached until it ends, and `Detach` (a thread_local) detaches it then. A thread somebody else attached is left alone.
inline JNIEnv* android_thread_env() {
    struct Detach {
        JavaVM* vm = nullptr;
        ~Detach() {
            if (vm) vm->DetachCurrentThread();
        }
    };
    static thread_local Detach detach;
    const ANativeActivity* activity = android_activity();
    JavaVM* vm = activity ? activity->vm : nullptr;
    if (!vm) return nullptr;
    JNIEnv* env = nullptr;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) == JNI_OK) return env;
    if (vm->AttachCurrentThread(&env, nullptr) != JNI_OK) return nullptr;
    detach.vm = vm;
    return env;
}

// A JNI call that threw leaves the exception pending: clear it, report that it did.
inline bool android_clear_exception(JNIEnv* env) {
    if (!env->ExceptionCheck()) return false;
    env->ExceptionClear();
    return true;
}

// A Java string as UTF-8 ("" for null). Does not delete the reference.
inline std::string android_string(JNIEnv* env, jstring s) {
    if (!s) return {};
    const char* chars = env->GetStringUTFChars(s, nullptr);
    if (!chars) {
        env->ExceptionClear();
        return {};
    }
    std::string out(chars);
    env->ReleaseStringUTFChars(s, chars);
    return out;
}

// The pending exception (none: all empty), cleared: its class name ("java.net.UnknownHostException") and its message, and
// those of its cause when it has one (an SSLHandshakeException that wraps a CertificateException).
struct JavaError {
    std::string cls, message;
    std::string causeCls, causeMessage;
};
inline JavaError android_take_exception(JNIEnv* env) {
    JavaError e;
    jthrowable ex = env->ExceptionOccurred();
    env->ExceptionClear();
    if (!ex) return e;
    jclass throwable = env->FindClass("java/lang/Throwable");
    env->ExceptionClear();
    jclass classClass = env->FindClass("java/lang/Class");
    env->ExceptionClear();
    jmethodID getClass = throwable ? env->GetMethodID(throwable, "getClass", "()Ljava/lang/Class;") : nullptr;
    env->ExceptionClear();
    jmethodID getMessage = throwable ? env->GetMethodID(throwable, "getMessage", "()Ljava/lang/String;") : nullptr;
    env->ExceptionClear();
    jmethodID getCause = throwable ? env->GetMethodID(throwable, "getCause", "()Ljava/lang/Throwable;") : nullptr;
    env->ExceptionClear();
    jmethodID getName = classClass ? env->GetMethodID(classClass, "getName", "()Ljava/lang/String;") : nullptr;
    env->ExceptionClear();
    const auto describe = [&](jobject t, std::string& cls, std::string& message) {
        if (getClass && getName) {
            if (jobject c = env->CallObjectMethod(t, getClass)) {
                if (auto name = static_cast<jstring>(env->CallObjectMethod(c, getName))) {
                    cls = android_string(env, name);
                    env->DeleteLocalRef(name);
                }
                env->DeleteLocalRef(c);
            }
            env->ExceptionClear();
        }
        if (getMessage) {
            if (auto m = static_cast<jstring>(env->CallObjectMethod(t, getMessage))) {
                message = android_string(env, m);
                env->DeleteLocalRef(m);
            }
            env->ExceptionClear();
        }
    };
    describe(ex, e.cls, e.message);
    if (getCause) {
        jobject cause = env->CallObjectMethod(ex, getCause);
        env->ExceptionClear();
        if (cause) {
            describe(cause, e.causeCls, e.causeMessage);
            env->DeleteLocalRef(cause);
        }
    }
    if (throwable) env->DeleteLocalRef(throwable);
    if (classClass) env->DeleteLocalRef(classClass);
    env->DeleteLocalRef(ex);
    return e;
}

}  // namespace fa
