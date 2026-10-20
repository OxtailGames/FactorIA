#include "fa/platform/speech.h"

#include <utility>

#include "fa/core/log.h"

namespace fa {

SpeechBackend* Speech::backend() {
    if (!backend_ && factory_) {
        backend_ = factory_();
        factory_ = nullptr;
    }
    return backend_.get();
}

bool Speech::available() {
    SpeechBackend* b = backend();
    return !b || b->available();
}

bool Speech::speak(std::string_view text, std::string_view language, bool interrupt) {
    if (text.empty()) return true;
    spoken_.push_back({std::string(text), std::string(language), interrupt});
    if (spoken_.size() > kMaxRecorded) spoken_.erase(spoken_.begin());
    SpeechBackend* b = backend();
    if (!b) return true;
    if (!b->available()) {
        if (!warned_) {
            warned_ = true;
            fa::log(LogLevel::Warn, "speech",
                    "ui.speak: this system has no text to speech (Linux needs speech-dispatcher, libspeechd.so.2, and a "
                    "speech engine such as espeak-ng; Android needs a speech engine installed). Nothing will be said; "
                    "check ui.speechAvailable and hide the option instead of calling ui.speak.");
        }
        return false;
    }
    b->speak(text, language, interrupt);
    return true;
}

void Speech::stop() {
    if (backend_ && backend_->available()) backend_->stop();  // never made = nothing is being said
}

void Speech::update() {
    if (backend_) backend_->update();
}

}  // namespace fa
