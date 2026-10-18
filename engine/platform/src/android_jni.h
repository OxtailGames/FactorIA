// JNI helpers shared by the Android files of fa_platform (gamepad_android.cpp, mobile_android.cpp). Private to fa_platform.
// The VM is reached through the activity sokol_app keeps (sapp_android_get_native_activity()); no Java class of ours
// is needed, only the framework's.
#pragma once

#include <android/native_activity.h>
#include <jni.h>

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

}  // namespace fa
