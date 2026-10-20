// Text to speech (`ui.speak` in scripts). Output only: it never touches the simulation, saves or determinism.
//
//   Windows    SAPI 5 (COM ISpVoice, asynchronous; the voice is chosen by language).
//   macOS/iOS  AVSpeechSynthesizer.
//   Android    android.speech.tts.TextToSpeech through JNI (no Java class of ours; speech asked before the engine has
//              started is kept and said once it has).
//   Linux      speech-dispatcher, libspeechd.so.2 loaded with dlopen: missing = not available, and nothing is linked.
//   web        window.speechSynthesis.
//
// `Speech` wraps one backend: it records every line it was asked to say (what `game.spoken()` returns in tests),
// warns once when the system has no speech, and drops empty lines. Without a backend (headless runs, tests) it only
// records.
#pragma once

#include <cstddef>
#include <functional>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

namespace fa {

// One platform's speech engine. Called from the main/game thread only.
class SpeechBackend {
public:
    virtual ~SpeechBackend() = default;
    // True when the system can speak (a voice engine exists). Checked on every speak; cache the answer.
    virtual bool available() = 0;
    // Says `text` in `language` (a BCP 47 tag such as "es" or "pt-BR"; "" = the system's default voice). `interrupt`
    // stops what is being said first; otherwise the line waits for the ones before it.
    virtual void speak(std::string_view text, std::string_view language, bool interrupt) = 0;
    virtual void stop() = 0;
    // Called every frame: backends that start asynchronously (Android) say what they kept. Default: nothing.
    virtual void update() {}
};

// The backend of this platform; never null: where the system has no speech its available() is false.
std::unique_ptr<SpeechBackend> make_system_speech_backend();

struct SpokenLine {
    std::string text;
    std::string language;  // the language it was asked in ("" = none given)
    bool interrupt = true;
};

class Speech {
public:
    // `backend` null = record only (headless runs and tests).
    explicit Speech(std::unique_ptr<SpeechBackend> backend = nullptr) : backend_(std::move(backend)) {}
    // A real backend made on the first use (starting COM, loading libspeechd or the Android engine costs time a game that
    // never speaks should not pay).
    void set_backend_factory(std::function<std::unique_ptr<SpeechBackend>()> factory) { factory_ = std::move(factory); }

    // False when a backend exists and the system cannot speak. A recording-only Speech is available (so that tests
    // exercise the code that speaks).
    bool available();
    // Records the line and, with a backend that can speak, says it. Returns false when it was not said because the
    // system has no speech (the first time also logs one warning); an empty text is ignored (true, not recorded).
    bool speak(std::string_view text, std::string_view language, bool interrupt);
    void stop();
    void update();

    // The recorded lines, oldest first (capped at the last kMaxRecorded).
    const std::vector<SpokenLine>& spoken() const { return spoken_; }
    void clear_spoken() { spoken_.clear(); }
    static constexpr std::size_t kMaxRecorded = 1000;

private:
    SpeechBackend* backend();  // makes the backend from the factory the first time
    std::unique_ptr<SpeechBackend> backend_;
    std::function<std::unique_ptr<SpeechBackend>()> factory_;
    std::vector<SpokenLine> spoken_;
    bool warned_ = false;
};

}  // namespace fa
