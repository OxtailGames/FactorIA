// `ui.speak`, `ui.stopSpeaking`, `ui.speechAvailable` and `game.spoken()` against the test host (no window: lines are
// recorded, nothing is said), and ui.speak with a backend that cannot speak (the ScriptHost's Speech).
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {

class DeadBackend : public SpeechBackend {
public:
    bool available() override { return false; }
    void speak(std::string_view, std::string_view, bool) override { FAIL("a backend that is not available must not be asked to speak"); }
    void stop() override {}
};

}  // namespace

TEST_CASE("speech api: ui.speak records lines in the current language and game.spoken() lists them") {
    TestHost h("speech_record", Json::parse(R"({ "localization": { "defaultLanguage": "en", "languages": ["en", "es"] } })"));
    h.file("locales/en.json", R"({ "$name": "English", "hi": "Hello" })");
    h.file("locales/es.json", R"({ "$name": "Español", "hi": "Hola" })");
    h.file("tests/speech.test.js", R"js(
import { test, expect, game } from "factoria:test";
import { ui, i18n } from "factoria";

test("records", () => {
  expect(ui.speechAvailable).toBe(true);
  ui.speak(i18n.t("hi"));
  i18n.setLanguage("es");
  ui.speak(i18n.t("hi"), { interrupt: false });
  ui.speak(""); // nothing to say: not recorded
  ui.stopSpeaking();
  expect(game.spoken()).toEqual([
    { text: "Hello", language: "en", interrupt: true },
    { text: "Hola", language: "es", interrupt: false },
  ]);
  game.clearSpoken();
  expect(game.spoken()).toEqual([]);
});

test("each test starts with an empty list", () => {
  expect(game.spoken()).toEqual([]);
  ui.speak("left over");
});

test("wrong calls teach", () => {
  expect(() => ui.speak(3)).toThrow("expects the text as a string");
  expect(() => ui.speak("x", { interrupt: 1 })).toThrow("interrupt must be true");
  expect(() => ui.speak("x", "now")).toThrow("options object");
  expect(game.spoken()).toEqual([]);
});
)js");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/speech.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 3);
}

TEST_CASE("speech api: a system without speech reports ui.speechAvailable false and speaks nothing") {
    TestHost h("speech_dead");
    h.speech().set_backend_factory([] { return std::make_unique<DeadBackend>(); });
    h.file("tests/dead.test.js", R"js(
import { test, expect, game } from "factoria:test";
import { ui } from "factoria";
test("no speech", () => {
  expect(ui.speechAvailable).toBe(false);
  ui.speak("hello"); // a no-op, one warning per run
  ui.speak("again");
  ui.stopSpeaking();
});
)js");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/dead.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}
