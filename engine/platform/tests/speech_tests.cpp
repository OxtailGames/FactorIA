#include <doctest.h>

#include "fa/platform/speech.h"

using namespace fa;

namespace {

struct Calls {
    std::vector<std::string> said;  // "text|language|interrupt"
    int stops = 0;
    int updates = 0;
};

class FakeBackend : public SpeechBackend {
public:
    FakeBackend(Calls* calls, bool available) : calls_(calls), available_(available) {}
    bool available() override { return available_; }
    void speak(std::string_view text, std::string_view language, bool interrupt) override {
        calls_->said.push_back(std::string(text) + "|" + std::string(language) + "|" + (interrupt ? "1" : "0"));
    }
    void stop() override { ++calls_->stops; }
    void update() override { ++calls_->updates; }

private:
    Calls* calls_;
    bool available_;
};

}  // namespace

TEST_CASE("speech: without a backend it only records, interrupt flag included") {
    Speech speech;
    CHECK(speech.available());
    CHECK(speech.speak("Play", "en", true));
    CHECK(speech.speak("Options", "es", false));
    CHECK(speech.speak("", "en", true));  // empty: ignored, not recorded
    REQUIRE(speech.spoken().size() == 2);
    CHECK(speech.spoken()[0].text == "Play");
    CHECK(speech.spoken()[0].interrupt);
    CHECK(speech.spoken()[1].language == "es");
    CHECK_FALSE(speech.spoken()[1].interrupt);
    speech.clear_spoken();
    CHECK(speech.spoken().empty());
}

TEST_CASE("speech: the recorder keeps the last kMaxRecorded lines") {
    Speech speech;
    for (std::size_t i = 0; i < Speech::kMaxRecorded + 5; ++i) speech.speak(std::to_string(i), "", true);
    REQUIRE(speech.spoken().size() == Speech::kMaxRecorded);
    CHECK(speech.spoken().front().text == "5");
}

TEST_CASE("speech: interrupt and queue reach the backend as asked") {
    Calls calls;
    Speech speech(std::make_unique<FakeBackend>(&calls, true));
    CHECK(speech.available());
    CHECK(speech.speak("one", "en-US", true));
    CHECK(speech.speak("two", "en-US", false));
    speech.stop();
    speech.update();
    REQUIRE(calls.said.size() == 2);
    CHECK(calls.said[0] == "one|en-US|1");
    CHECK(calls.said[1] == "two|en-US|0");
    CHECK(calls.stops == 1);
    CHECK(calls.updates == 1);
    CHECK(speech.spoken().size() == 2);
}

TEST_CASE("speech: a backend that cannot speak says nothing and reports it") {
    Calls calls;
    Speech speech(std::make_unique<FakeBackend>(&calls, false));
    CHECK_FALSE(speech.available());
    CHECK_FALSE(speech.speak("one", "en", true));
    CHECK_FALSE(speech.speak("two", "en", true));  // a no-op each time (one warning per run)
    speech.stop();
    CHECK(calls.said.empty());
    CHECK(calls.stops == 0);
}

TEST_CASE("speech: this platform's backend can be made and asked") {
    auto backend = make_system_speech_backend();
    REQUIRE(backend);
    const bool available = backend->available();  // true or false depending on the machine; it must not crash
    MESSAGE("system speech available: ", available);
    if (available) {  // say and stop at once: nothing audible for long, and it must not crash
        backend->speak("test", "en", true);
        backend->speak("test", "es-ES", false);
        backend->stop();
    }
}
