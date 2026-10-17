// Android: java.util.Locale.getDefault().toLanguageTag() of the process, through JNI on the activity's JavaVM
// (sapp_android_get_native_activity(), as gamepad_android.cpp does). Locale.getDefault() is the system language the
// framework set when the app started ("es-ES", "zh-Hans-CN"). Any JNI failure gives an empty list: the game then starts in
// its default language. UNTESTED on a device: only compiled by CI.
#include <android/native_activity.h>
#include <jni.h>

#include "fa/platform/system_language.h"
#include "sokol_app.h"

namespace fa {

std::vector<std::string> system_languages() {
    const auto* activity = static_cast<const ANativeActivity*>(sapp_android_get_native_activity());
    if (!activity || !activity->vm) return {};
    JavaVM* vm = activity->vm;
    JNIEnv* env = nullptr;
    bool attached = false;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
        if (vm->AttachCurrentThread(&env, nullptr) != JNI_OK) return {};
        attached = true;
    }
    std::vector<std::string> raw;
    if (jclass cls = env->FindClass("java/util/Locale")) {
        jmethodID getDefault = env->GetStaticMethodID(cls, "getDefault", "()Ljava/util/Locale;");
        jmethodID toTag = env->GetMethodID(cls, "toLanguageTag", "()Ljava/lang/String;");
        if (getDefault && toTag) {
            if (jobject locale = env->CallStaticObjectMethod(cls, getDefault)) {
                if (auto tag = static_cast<jstring>(env->CallObjectMethod(locale, toTag))) {
                    if (const char* chars = env->GetStringUTFChars(tag, nullptr)) {
                        raw.emplace_back(chars);
                        env->ReleaseStringUTFChars(tag, chars);
                    }
                    env->DeleteLocalRef(tag);
                }
                env->DeleteLocalRef(locale);
            }
        }
        env->DeleteLocalRef(cls);
    }
    if (env->ExceptionCheck()) env->ExceptionClear();
    if (attached) vm->DetachCurrentThread();
    return normalize_language_list(raw);
}

}  // namespace fa
