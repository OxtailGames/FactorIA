// Android, through JNI on the activity's JavaVM (as system_language_android.cpp does):
//   textScale     Context.getResources().getConfiguration().fontScale
//   reduceMotion  Settings.Global "animator_duration_scale" == 0 ("Remove animations" in the developer/accessibility settings)
//   highContrast  Settings.Secure "high_text_contrast_enabled" == 1
//   screenReader  AccessibilityManager.isTouchExplorationEnabled() (TalkBack)
// Any JNI failure leaves that value at its default. UNTESTED on a device: only compiled by CI.
#include <android/native_activity.h>
#include <jni.h>

#include <cstdarg>

#include "fa/platform/accessibility.h"
#include "sokol_app.h"

namespace fa {

namespace {
void clear_exception(JNIEnv* env) {
    if (env->ExceptionCheck()) env->ExceptionClear();
}

// Calls `obj.name(args)` with a signature and returns the object (null on failure).
jobject call_object(JNIEnv* env, jobject obj, const char* name, const char* sig, ...) {
    jclass cls = env->GetObjectClass(obj);
    jmethodID m = cls ? env->GetMethodID(cls, name, sig) : nullptr;
    jobject out = nullptr;
    if (m) {
        va_list args;
        va_start(args, sig);
        out = env->CallObjectMethodV(obj, m, args);
        va_end(args);
    }
    if (cls) env->DeleteLocalRef(cls);
    clear_exception(env);
    return out;
}
}  // namespace

AccessibilitySettings read_system_accessibility() {
    AccessibilitySettings s;
    const auto* activity = static_cast<const ANativeActivity*>(sapp_android_get_native_activity());
    if (!activity || !activity->vm || !activity->clazz) return s;
    JavaVM* vm = activity->vm;
    JNIEnv* env = nullptr;
    bool attached = false;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
        if (vm->AttachCurrentThread(&env, nullptr) != JNI_OK) return s;
        attached = true;
    }
    jobject context = activity->clazz;

    // fontScale
    if (jobject resources = call_object(env, context, "getResources", "()Landroid/content/res/Resources;")) {
        if (jobject config = call_object(env, resources, "getConfiguration", "()Landroid/content/res/Configuration;")) {
            if (jclass cls = env->GetObjectClass(config)) {
                if (jfieldID f = env->GetFieldID(cls, "fontScale", "F")) s.textScale = env->GetFloatField(config, f);
                env->DeleteLocalRef(cls);
            }
            env->DeleteLocalRef(config);
        }
        env->DeleteLocalRef(resources);
    }
    clear_exception(env);

    // Settings.Global / Settings.Secure through the content resolver
    if (jobject resolver = call_object(env, context, "getContentResolver", "()Landroid/content/ContentResolver;")) {
        if (jclass global = env->FindClass("android/provider/Settings$Global")) {
            if (jmethodID getFloat = env->GetStaticMethodID(global, "getFloat",
                                                            "(Landroid/content/ContentResolver;Ljava/lang/String;F)F")) {
                jstring key = env->NewStringUTF("animator_duration_scale");
                const jfloat scale = env->CallStaticFloatMethod(global, getFloat, resolver, key, 1.0f);
                if (!env->ExceptionCheck()) s.reduceMotion = scale == 0.0f;
                env->DeleteLocalRef(key);
            }
            clear_exception(env);
            env->DeleteLocalRef(global);
        }
        if (jclass secure = env->FindClass("android/provider/Settings$Secure")) {
            if (jmethodID getInt = env->GetStaticMethodID(secure, "getInt",
                                                          "(Landroid/content/ContentResolver;Ljava/lang/String;I)I")) {
                jstring key = env->NewStringUTF("high_text_contrast_enabled");
                const jint on = env->CallStaticIntMethod(secure, getInt, resolver, key, 0);
                if (!env->ExceptionCheck()) s.highContrast = on == 1;
                env->DeleteLocalRef(key);
            }
            clear_exception(env);
            env->DeleteLocalRef(secure);
        }
        env->DeleteLocalRef(resolver);
    }
    clear_exception(env);

    // TalkBack
    jstring service = env->NewStringUTF("accessibility");
    if (jobject manager = call_object(env, context, "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;", service)) {
        if (jclass cls = env->GetObjectClass(manager)) {
            if (jmethodID m = env->GetMethodID(cls, "isTouchExplorationEnabled", "()Z")) {
                const jboolean on = env->CallBooleanMethod(manager, m);
                if (!env->ExceptionCheck()) s.screenReader = on == JNI_TRUE;
            }
            env->DeleteLocalRef(cls);
        }
        env->DeleteLocalRef(manager);
    }
    env->DeleteLocalRef(service);
    clear_exception(env);
    if (attached) vm->DetachCurrentThread();
    return s;
}

}  // namespace fa
