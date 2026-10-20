// Android: android.speech.tts.TextToSpeech through JNI on the sokol_app loop thread (android_jni.h; framework classes
// only, no Java code of ours).
//
// We have no Java class to implement TextToSpeech.OnInitListener, so the object is made with a null listener. The engine
// starts on the main looper some tens of milliseconds later; until then speak() answers ERROR. So a line that could not be
// said is kept and tried again every frame (update()) for a few seconds; a line that interrupts drops the ones before it.
// "Available" means at least one speech engine is installed (TextToSpeech.getEngines()); the manifest declares the
// android.intent.action.TTS_SERVICE query that Android 11+ needs to see them.
//
// UNTESTED on a device: only compiled by CI (and syntax-checked with the NDK). In particular the null listener is the
// documented-by-source behaviour, not one verified on hardware.
#include <chrono>
#include <deque>
#include <string>

#include "android_jni.h"
#include "fa/core/log.h"
#include "fa/core/utf8.h"
#include "fa/platform/speech.h"

namespace fa {

namespace {

constexpr jint kQueueFlush = 0;
constexpr jint kQueueAdd = 1;
constexpr auto kGiveUpAfter = std::chrono::seconds(8);

class AndroidTtsBackend final : public SpeechBackend {
public:
    AndroidTtsBackend() {
        JNIEnv* env = android_thread_env();
        const ANativeActivity* activity = android_activity();
        if (!env || !activity || !activity->clazz) return;
        jclass cls = env->FindClass("android/speech/tts/TextToSpeech");
        if (android_clear_exception(env) || !cls) return;
        cls_ = static_cast<jclass>(env->NewGlobalRef(cls));
        env->DeleteLocalRef(cls);
        jmethodID ctor = env->GetMethodID(cls_, "<init>", "(Landroid/content/Context;Landroid/speech/tts/TextToSpeech$OnInitListener;)V");
        if (android_clear_exception(env) || !ctor) return;
        jobject tts = env->NewObject(cls_, ctor, activity->clazz, nullptr);
        if (android_clear_exception(env) || !tts) return;
        tts_ = env->NewGlobalRef(tts);
        env->DeleteLocalRef(tts);
        mSpeak_ = env->GetMethodID(cls_, "speak", "(Ljava/lang/CharSequence;ILandroid/os/Bundle;Ljava/lang/String;)I");
        mStop_ = env->GetMethodID(cls_, "stop", "()I");
        mSetLanguage_ = env->GetMethodID(cls_, "setLanguage", "(Ljava/util/Locale;)I");
        mShutdown_ = env->GetMethodID(cls_, "shutdown", "()V");
        mEngines_ = env->GetMethodID(cls_, "getEngines", "()Ljava/util/List;");
        android_clear_exception(env);
        if (!mSpeak_ || !mStop_ || !mSetLanguage_) tts_ = nullptr;
    }

    ~AndroidTtsBackend() override {
        JNIEnv* env = android_thread_env();
        if (!env) return;
        if (tts_) {
            if (mShutdown_) env->CallVoidMethod(tts_, mShutdown_);
            android_clear_exception(env);
            env->DeleteGlobalRef(tts_);
        }
        if (cls_) env->DeleteGlobalRef(cls_);
    }

    bool available() override {
        if (!tts_) return false;
        if (!enginesChecked_) {
            enginesChecked_ = true;
            JNIEnv* env = android_thread_env();
            haveEngine_ = true;  // when the list cannot be read, assume there is one: speak() then simply fails to say
            if (env && mEngines_) {
                jobject list = env->CallObjectMethod(tts_, mEngines_);
                if (!android_clear_exception(env) && list) {
                    jclass listCls = env->GetObjectClass(list);
                    jmethodID isEmpty = env->GetMethodID(listCls, "isEmpty", "()Z");
                    if (!android_clear_exception(env) && isEmpty) {
                        haveEngine_ = !env->CallBooleanMethod(list, isEmpty);
                        android_clear_exception(env);
                    }
                    env->DeleteLocalRef(listCls);
                    env->DeleteLocalRef(list);
                }
            }
        }
        return haveEngine_;
    }

    void speak(std::string_view text, std::string_view language, bool interrupt) override {
        if (!available()) return;
        if (interrupt) pending_.clear();
        pending_.push_back({std::string(text), std::string(language), interrupt, std::chrono::steady_clock::now()});
        drain();
    }

    void stop() override {
        pending_.clear();
        JNIEnv* env = android_thread_env();
        if (!env || !tts_) return;
        env->CallIntMethod(tts_, mStop_);
        android_clear_exception(env);
    }

    void update() override {
        if (!pending_.empty()) drain();
    }

private:
    struct Line {
        std::string text, language;
        bool interrupt;
        std::chrono::steady_clock::time_point asked;
    };

    // Says the kept lines in order; stops at the first the engine refuses (it is not started yet), and gives up on lines
    // that waited too long (no engine ever started: nothing to be said, and no reason to say it late).
    void drain() {
        JNIEnv* env = android_thread_env();
        if (!env) return;
        while (!pending_.empty()) {
            const Line& line = pending_.front();
            if (std::chrono::steady_clock::now() - line.asked > kGiveUpAfter) {
                fa::log(LogLevel::Warn, "speech", "ui.speak: the Android speech engine did not start; the line was dropped");
                pending_.clear();
                return;
            }
            if (!try_say(env, line)) return;
            pending_.pop_front();
        }
    }

    bool try_say(JNIEnv* env, const Line& line) {
        if (line.language != appliedLanguage_ && !line.language.empty()) {
            jclass localeCls = env->FindClass("java/util/Locale");
            jmethodID forTag = localeCls ? env->GetStaticMethodID(localeCls, "forLanguageTag", "(Ljava/lang/String;)Ljava/util/Locale;") : nullptr;
            if (!android_clear_exception(env) && forTag) {
                const std::u16string tag16 = utf8_to_utf16(line.language);
                jstring tag = env->NewString(reinterpret_cast<const jchar*>(tag16.data()), jsize(tag16.size()));
                jobject locale = env->CallStaticObjectMethod(localeCls, forTag, tag);
                if (!android_clear_exception(env) && locale) {
                    env->CallIntMethod(tts_, mSetLanguage_, locale);  // LANG_NOT_SUPPORTED keeps the previous voice
                    android_clear_exception(env);
                    env->DeleteLocalRef(locale);
                }
                env->DeleteLocalRef(tag);
            }
            if (localeCls) env->DeleteLocalRef(localeCls);
            appliedLanguage_ = line.language;
        }
        const std::u16string text16 = utf8_to_utf16(line.text);
        jstring text = env->NewString(reinterpret_cast<const jchar*>(text16.data()), jsize(text16.size()));
        jstring id = env->NewStringUTF("factoria");
        const jint rc = env->CallIntMethod(tts_, mSpeak_, text, line.interrupt ? kQueueFlush : kQueueAdd, nullptr, id);
        const bool threw = android_clear_exception(env);
        env->DeleteLocalRef(text);
        env->DeleteLocalRef(id);
        if (threw || rc != 0) {
            appliedLanguage_.clear();  // setLanguage before the engine started was lost: apply it again on the retry
            return false;
        }
        return true;
    }

    jclass cls_ = nullptr;
    jobject tts_ = nullptr;
    jmethodID mSpeak_ = nullptr, mStop_ = nullptr, mSetLanguage_ = nullptr, mShutdown_ = nullptr, mEngines_ = nullptr;
    bool enginesChecked_ = false, haveEngine_ = false;
    std::string appliedLanguage_;
    std::deque<Line> pending_;
};

}  // namespace

std::unique_ptr<SpeechBackend> make_system_speech_backend() { return std::make_unique<AndroidTtsBackend>(); }

}  // namespace fa
