// Android half of fa/runtime/gpu_launch.h: the Vulkan activity starts the OpenGL one (M77-P9e2, docs/RENDERING.md
// "Choosing the GPU backend"). Android has no exec of another binary inside an app: each player is a shared library
// that an activity loads, and a process loads one of them (both define ANativeActivity_onCreate and sokol_main). So the
// two players are two activities of the same app, the OpenGL one (factoria.engine.GlActivity) in its own process ":gl",
// and the Vulkan one hands over to it with an intent whose extras carry the marker.
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

// GetMethodID and GetFieldID throw NoSuchMethodError / NoSuchFieldError when the member is not there, and CheckJNI
// (debug builds, many emulators) aborts the process at the next JNI call made with an exception pending: each lookup
// clears its own. Null: not there (or `cls` is null).
jmethodID method(JNIEnv* env, jclass cls, const char* name, const char* signature) {
    jmethodID id = cls ? env->GetMethodID(cls, name, signature) : nullptr;
    return clear(env) ? nullptr : id;
}

jfieldID field(JNIEnv* env, jclass cls, const char* name, const char* signature) {
    jfieldID id = cls ? env->GetFieldID(cls, name, signature) : nullptr;
    return clear(env) ? nullptr : id;
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
    jmethodID ctor = method(env, intentClass, "<init>", "()V");
    jmethodID setClassName = method(env, intentClass, "setClassName",
                                    "(Landroid/content/Context;Ljava/lang/String;)Landroid/content/Intent;");
    jmethodID putExtra =
        method(env, intentClass, "putExtra", "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;");
    jmethodID putExtras = method(env, intentClass, "putExtras", "(Landroid/content/Intent;)Landroid/content/Intent;");
    jmethodID getIntent = method(env, activityClass, "getIntent", "()Landroid/content/Intent;");
    jmethodID startActivity = method(env, activityClass, "startActivity", "(Landroid/content/Intent;)V");
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

bool android_gl_activity_in_task(void* nativeActivity) {
    auto* activity = static_cast<ANativeActivity*>(nativeActivity);
    JNIEnv* env = activity ? activity->env : nullptr;
    if (!env || !activity->clazz) return false;
    if (env->PushLocalFrame(32) != 0) {
        clear(env);
        return false;
    }
    auto done = [&](bool found) {
        clear(env);
        env->PopLocalFrame(nullptr);
        return found;
    };
    jclass activityClass = env->GetObjectClass(activity->clazz);
    jclass managerClass = env->FindClass("android/app/ActivityManager");
    jclass appTaskClass = managerClass ? env->FindClass("android/app/ActivityManager$AppTask") : nullptr;
    jclass infoClass = appTaskClass ? env->FindClass("android/app/ActivityManager$RecentTaskInfo") : nullptr;
    jclass listClass = infoClass ? env->FindClass("java/util/List") : nullptr;
    jclass componentClass = listClass ? env->FindClass("android/content/ComponentName") : nullptr;
    if (clear(env) || !activityClass || !componentClass) return done(false);
    jmethodID getSystemService =
        method(env, activityClass, "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;");
    jmethodID getTaskId = method(env, activityClass, "getTaskId", "()I");
    jmethodID getAppTasks = method(env, managerClass, "getAppTasks", "()Ljava/util/List;");
    jmethodID getTaskInfo = method(env, appTaskClass, "getTaskInfo", "()Landroid/app/ActivityManager$RecentTaskInfo;");
    jmethodID size = method(env, listClass, "size", "()I");
    jmethodID get = method(env, listClass, "get", "(I)Ljava/lang/Object;");
    jmethodID getClassName = method(env, componentClass, "getClassName", "()Ljava/lang/String;");
    // persistentId: the task's id on every API level (taskId only from API 29). baseActivity from API 23; from API 29 a
    // field of the superclass TaskInfo, which GetFieldID finds too.
    jfieldID persistentId = field(env, infoClass, "persistentId", "I");
    jfieldID baseActivity = field(env, infoClass, "baseActivity", "Landroid/content/ComponentName;");
    if (clear(env) || !getSystemService || !getTaskId || !getAppTasks || !getTaskInfo || !size || !get ||
        !getClassName || !persistentId || !baseActivity)
        return done(false);
    const jint ownTask = env->CallIntMethod(activity->clazz, getTaskId);
    if (clear(env)) return done(false);
    jobject manager = env->CallObjectMethod(activity->clazz, getSystemService, env->NewStringUTF("activity"));
    if (clear(env) || !manager) return done(false);
    jobject tasks = env->CallObjectMethod(manager, getAppTasks);
    if (clear(env) || !tasks) return done(false);
    const jint count = env->CallIntMethod(tasks, size);
    if (clear(env)) return done(false);
    for (jint i = 0; i < count; ++i) {
        jobject task = env->CallObjectMethod(tasks, get, i);
        if (clear(env) || !task) continue;
        jobject info = env->CallObjectMethod(task, getTaskInfo);
        env->DeleteLocalRef(task);
        if (clear(env) || !info) continue;  // a task that ended meanwhile throws: not this one
        const bool own = env->GetIntField(info, persistentId) == ownTask;
        jobject base = own ? env->GetObjectField(info, baseActivity) : nullptr;
        env->DeleteLocalRef(info);
        if (!own) continue;
        if (!base) return done(false);
        const std::string name = take_string(env, static_cast<jstring>(env->CallObjectMethod(base, getClassName)));
        return done(!clear(env) && name == kGlActivityClass);
    }
    return done(false);
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
        activityClass ? method(env, activityClass, "getIntent", "()Landroid/content/Intent;") : nullptr;
    jmethodID getStringExtra =
        intentClass ? method(env, intentClass, "getStringExtra", "(Ljava/lang/String;)Ljava/lang/String;") : nullptr;
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
