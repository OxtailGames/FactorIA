// Linux: speech-dispatcher through libspeechd.so.2, loaded with dlopen so that nothing is linked (the Steam Runtime
// "sniper" build and machines without it keep working). Missing library or no running dispatcher = not available.
// UNTESTED with a speaker in CI: the check is that the backend reports itself unavailable where there is none.
#include <dlfcn.h>

#include <string>

#include "fa/platform/speech.h"

namespace fa {

namespace {

// The few pieces of libspeechd.h we use (stable ABI since 0.8): SPDConnection is opaque, SPD_TEXT = 3, SPD_MODE_SINGLE = 0.
struct SPDConnection;
constexpr int kSpdModeSingle = 0;
constexpr int kSpdText = 3;

class SpeechdBackend final : public SpeechBackend {
public:
    SpeechdBackend() {
        lib_ = dlopen("libspeechd.so.2", RTLD_NOW | RTLD_LOCAL);
        if (!lib_) return;
        open_ = reinterpret_cast<OpenFn>(dlsym(lib_, "spd_open"));
        close_ = reinterpret_cast<CloseFn>(dlsym(lib_, "spd_close"));
        say_ = reinterpret_cast<SayFn>(dlsym(lib_, "spd_say"));
        cancel_ = reinterpret_cast<CancelFn>(dlsym(lib_, "spd_cancel"));
        setLanguage_ = reinterpret_cast<SetLanguageFn>(dlsym(lib_, "spd_set_language"));
        if (!open_ || !close_ || !say_ || !cancel_) {
            dlclose(lib_);
            lib_ = nullptr;
        }
    }
    ~SpeechdBackend() override {
        if (connection_) {
            cancel_(connection_);
            close_(connection_);
        }
        if (lib_) dlclose(lib_);
    }

    bool available() override {
        if (!lib_) return false;
        if (!tried_) {  // the connection is made once; a dispatcher that is not running answers null
            tried_ = true;
            connection_ = open_("factoria", "game", nullptr, kSpdModeSingle);
        }
        return connection_ != nullptr;
    }

    void speak(std::string_view text, std::string_view language, bool interrupt) override {
        if (!available()) return;
        if (interrupt) cancel_(connection_);
        if (setLanguage_ && language != lastLanguage_) {
            lastLanguage_ = std::string(language);
            // speech-dispatcher takes an ISO 639 code ("es", "pt"): the primary subtag; "" keeps the default voice.
            if (!lastLanguage_.empty()) setLanguage_(connection_, lastLanguage_.substr(0, lastLanguage_.find('-')).c_str());
        }
        say_(connection_, kSpdText, std::string(text).c_str());
    }

    void stop() override {
        if (available()) cancel_(connection_);
    }

private:
    using OpenFn = SPDConnection* (*)(const char*, const char*, const char*, int);
    using CloseFn = void (*)(SPDConnection*);
    using SayFn = int (*)(SPDConnection*, int, const char*);
    using CancelFn = int (*)(SPDConnection*);
    using SetLanguageFn = int (*)(SPDConnection*, const char*);

    void* lib_ = nullptr;
    OpenFn open_ = nullptr;
    CloseFn close_ = nullptr;
    SayFn say_ = nullptr;
    CancelFn cancel_ = nullptr;
    SetLanguageFn setLanguage_ = nullptr;
    SPDConnection* connection_ = nullptr;
    bool tried_ = false;
    std::string lastLanguage_;
};

}  // namespace

std::unique_ptr<SpeechBackend> make_system_speech_backend() { return std::make_unique<SpeechdBackend>(); }

}  // namespace fa
