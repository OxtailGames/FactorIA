// Web: window.speechSynthesis. Voices load asynchronously in some browsers (getVoices() is empty at first): the voice is
// looked up at every speak. Browsers may refuse to speak before the player has touched the page once.
// UNTESTED here: only compiled by CI (web job).
#include <emscripten.h>

#include <string>

#include "fa/platform/speech.h"

EM_JS(int, fa_web_speech_available, (), { return (typeof speechSynthesis !== 'undefined' && typeof SpeechSynthesisUtterance !== 'undefined') ? 1 : 0; });

EM_JS(void, fa_web_speech_speak, (const char* text, const char* lang, int interrupt), {
    const synth = window.speechSynthesis;
    if (!synth) return;
    if (interrupt) synth.cancel();
    const u = new SpeechSynthesisUtterance(UTF8ToString(text));
    const tag = UTF8ToString(lang);
    if (tag) {
        u.lang = tag;
        const primary = tag.split('-')[0].toLowerCase();
        // Voices on the device first: an online voice (Chrome's "Google ...") sends the text to its provider.
        const voices = (synth.getVoices() || []).slice().sort((a, b) => b.localService - a.localService);
        const voice = voices.find((v) => v.lang && v.lang.replace('_', '-').toLowerCase() === tag.toLowerCase())
            || voices.find((v) => v.lang && v.lang.toLowerCase().split(/[-_]/)[0] === primary);
        if (voice) u.voice = voice;
    }
    synth.speak(u);
});

EM_JS(void, fa_web_speech_stop, (), { if (window.speechSynthesis) window.speechSynthesis.cancel(); });

namespace fa {

namespace {

class WebSpeechBackend final : public SpeechBackend {
public:
    bool available() override { return fa_web_speech_available() != 0; }
    void speak(std::string_view text, std::string_view language, bool interrupt) override {
        if (!available()) return;
        fa_web_speech_speak(std::string(text).c_str(), std::string(language).c_str(), interrupt ? 1 : 0);
    }
    void stop() override {
        if (available()) fa_web_speech_stop();
    }
};

}  // namespace

std::unique_ptr<SpeechBackend> make_system_speech_backend() { return std::make_unique<WebSpeechBackend>(); }

}  // namespace fa
