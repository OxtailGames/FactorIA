// Android half of fa/runtime/gpu_launch.h: the Vulkan activity starts the OpenGL one (M77-P9e2, docs/RENDERING.md
// "Choosing the GPU backend"). Android has no exec of another binary inside an app: each player is a shared library that
// an activity loads, and a process loads one of them (both define ANativeActivity_onCreate and sokol_main). So the two
// players are two activities of the same app, the OpenGL one (factoria.engine.GlActivity) in its own process ":gl", and
// the Vulkan one hands over to it with an intent whose extras carry the marker.
//
// Both functions run inside sokol_main, which sokol_app calls on the main thread from ANativeActivity_onCreate: the
// activity's own JNIEnv (ANativeActivity::env) is the one of that thread. Only framework classes are looked up.
#include <android/native_activity.h>
#include <jni.h>
#include <stdlib.h>

#include <string>

#include "fa/core/log.h"
#include "fa/runtime/gpu_backend_choice.h"
#include "fa/runtime/gpu_launch.h"

namespace fa {

namespace {

constexpr const char* kGlActivityClass = "factoria.engine.GlActivity";

bool clear(JNIEnv* env) {
    if (!env->ExceptionCheck()) return false;
    env->ExceptionDescribe();
    env->ExceptionClear();
    return true;
}

std::string take_string(JNIEnv* env, jstring s) {
    if (!s) return {};
    const char* chars = env->GetStringUTFChars(s, nullptr);
    std::string out = chars ? chars : "";
    if (chars) env->ReleaseStringUTFChars(s, chars);
    env->DeleteLocalRef(s);
    return out;
}

}  // namespace

Result<void> android_start_gl_activity(void* nativeActivity, const std::string& fromBackend,
                                       const std::string& reason) {
    auto* activity = static_cast<ANativeActivity*>(nativeActivity);
    JNIEnv* env = activity ? activity->env : nullptr;
    if (!env || !activity->clazz)
        return make_error("cannot start the OpenGL activity: no activity", "This player draws the game itself.");
    if (env->PushLocalFrame(16) != 0) {
        clear(env);
        return make_error("cannot start the OpenGL activity: out of JNI local references", "");
    }
    auto fail = [&](const char* what) -> Result<void> {
        clear(env);
        env->PopLocalFrame(nullptr);
        return make_error(std::string("cannot start the OpenGL activity (") + kGlActivityClass + "): " + what,
                          "Export the game again: it declares that activity and ships libfactoria_player.so next to "
                          "the Vulkan player. This player draws the game itself.");
    };
    jclass intentClass = env->FindClass("android/content/Intent");
    jclass activityClass = env->GetObjectClass(activity->clazz);
    if (!intentClass || !activityClass) return fail("the framework classes are not there");
    jmethodID ctor = env->GetMethodID(intentClass, "<init>", "()V");
    jmethodID setClassName = env->GetMethodID(intentClass, "setClassName",
                                              "(Landroid/content/Context;Ljava/lang/String;)Landroid/content/Intent;");
    jmethodID putExtra =
        env->GetMethodID(intentClass, "putExtra", "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;");
    jmethodID putExtras =
        env->GetMethodID(intentClass, "putExtras", "(Landroid/content/Intent;)Landroid/content/Intent;");
    jmethodID getIntent = env->GetMethodID(activityClass, "getIntent", "()Landroid/content/Intent;");
    jmethodID startActivity = env->GetMethodID(activityClass, "startActivity", "(Landroid/content/Intent;)V");
    if (!ctor || !setClassName || !putExtra || !putExtras || !getIntent || !startActivity)
        return fail("a framework method is missing");
    jobject intent = env->NewObject(intentClass, ctor);
    if (!intent || clear(env)) return fail("new Intent() failed");
    // The extras this activity was started with go along (what argv and the environment are on Linux).
    jobject own = env->CallObjectMethod(activity->clazz, getIntent);
    if (!clear(env) && own) {
        env->CallObjectMethod(intent, putExtras, own);
        if (clear(env)) return fail("Intent.putExtras failed");
    }
    jstring cls = env->NewStringUTF(kGlActivityClass);
    env->CallObjectMethod(intent, setClassName, activity->clazz, cls);
    if (clear(env)) return fail("Intent.setClassName failed");
    if (!fromBackend.empty()) {
        env->CallObjectMethod(intent, putExtra, env->NewStringUTF(kGpuFallbackFromEnv),
                              env->NewStringUTF(fromBackend.c_str()));
        env->CallObjectMethod(intent, putExtra, env->NewStringUTF(kGpuFallbackReasonEnv),
                              env->NewStringUTF(reason.c_str()));
        if (clear(env)) return fail("Intent.putExtra failed");
    }
    env->CallVoidMethod(activity->clazz, startActivity, intent);
    if (clear(env)) return fail("startActivity failed (is the activity declared in the manifest?)");
    env->PopLocalFrame(nullptr);
    ANativeActivity_finish(activity);
    FA_INFO("player", "started the OpenGL activity in place of this one{}", fromBackend.empty() ? "" : " (fallback)");
    return {};
}

void android_take_gpu_fallback_extras(void* nativeActivity) {
    auto* activity = static_cast<ANativeActivity*>(nativeActivity);
    JNIEnv* env = activity ? activity->env : nullptr;
    if (!env || !activity->clazz) return;
    if (env->PushLocalFrame(8) != 0) {
        clear(env);
        return;
    }
    jclass activityClass = env->GetObjectClass(activity->clazz);
    jclass intentClass = env->FindClass("android/content/Intent");
    jmethodID getIntent =
        activityClass ? env->GetMethodID(activityClass, "getIntent", "()Landroid/content/Intent;") : nullptr;
    jmethodID getStringExtra =
        intentClass ? env->GetMethodID(intentClass, "getStringExtra", "(Ljava/lang/String;)Ljava/lang/String;")
                    : nullptr;
    jobject intent = (getIntent && getStringExtra) ? env->CallObjectMethod(activity->clazz, getIntent) : nullptr;
    if (intent && !clear(env)) {
        for (const char* key : {kGpuFallbackFromEnv, kGpuFallbackReasonEnv}) {
            auto value = take_string(
                env, static_cast<jstring>(env->CallObjectMethod(intent, getStringExtra, env->NewStringUTF(key))));
            if (clear(env)) break;
            if (!value.empty()) ::setenv(key, value.c_str(), 1);
        }
    }
    clear(env);
    env->PopLocalFrame(nullptr);
}

}  // namespace fa
