// Pad rumble: the request checks, Input's motors and their clock, and the copy to the hardware (against a fake one). The
// real backends (XInput, evdev, Android vibrators, CoreHaptics, the browser's Gamepad API) need a pad and are not covered
// here; the numbers they send are in rumble_map_tests.cpp.
#include <doctest.h>

#include <cmath>
#include <string>
#include <vector>

#include "fa/platform/gamepad.h"

using namespace fa;

namespace {

std::string text_of(const Result<RumbleRequest>& r) {
    REQUIRE_FALSE(r.ok());
    CHECK_FALSE(r.error().hint.empty());  // errors teach
    return r.error().message + " " + r.error().hint;
}

struct FakeHardware final : GamepadRumbleSink {
    struct Call {
        int slot;
        float low, high, seconds;
        bool operator==(const Call&) const = default;
    };
    bool can = true;
    bool accept = true;
    std::vector<Call> calls;
    GamepadRumbleSupport support(int) override { return {can, can ? "" : "no motors"}; }
    bool play(int slot, float low, float high, float seconds) override {
        calls.push_back({slot, low, high, seconds});
        return accept;
    }
};

RumbleRequest req(int pad, float low, float high, float seconds) { return RumbleRequest{pad, low, high, seconds}; }

}  // namespace

TEST_CASE("rumble requests: strengths are clamped, bad pads and seconds are explained") {
    auto ok = make_rumble_request("input.rumble", 2, 1.5, -0.5, 0.25);
    REQUIRE(ok.ok());
    CHECK(ok->pad == 2);
    CHECK(ok->low == 1.0f);  // clamped, not an error: a curve that overshoots is harmless
    CHECK(ok->high == 0.0f);
    CHECK(ok->seconds == 0.25f);

    const std::string badPad = text_of(make_rumble_request("input.rumble", 4, 0.5, 0.5, 0.2));
    CHECK(badPad.find("input.rumble: pad must be a whole number from 0 to 3") != std::string::npos);
    CHECK(badPad.find("got 4") != std::string::npos);
    CHECK(text_of(make_rumble_request("x", 0.5, 0.5, 0.5, 0.2)).find("got 0.5") != std::string::npos);
    CHECK(text_of(make_rumble_request("x", -1, 0.5, 0.5, 0.2)).find("pad must be") != std::string::npos);

    CHECK(text_of(make_rumble_request("x", 0, std::nan(""), 0.5, 0.2)).find("low must be a number from 0 to 1") !=
          std::string::npos);
    CHECK(text_of(make_rumble_request("x", 0, 0.5, HUGE_VAL, 0.2)).find("high must be a number") != std::string::npos);

    for (double seconds : {0.0, -1.0, 10.5, 1e9, std::nan("")}) {
        INFO("seconds " << seconds);
        const std::string t = text_of(make_rumble_request("game.rumble", 0, 0.5, 0.5, seconds));
        CHECK(t.find("game.rumble: seconds must be above 0 and up to 10") != std::string::npos);
        CHECK(t.find("input.stopRumble") != std::string::npos);
    }
    CHECK(make_rumble_request("x", 0, 0, 0, 10.0).ok());  // the longest one
}

TEST_CASE("Input rumble: a request replaces the one before, runs down on the engine clock and ends by itself") {
    Input in;
    in.on_gamepad_connected(0, true);
    in.on_gamepad_connected(2, true);
    in.rumble(req(0, 0.5f, 0.25f, 0.5f));
    RumbleState s = in.rumble_state(0);
    CHECK(s.low == 0.5f);
    CHECK(s.high == 0.25f);
    CHECK(s.remaining == doctest::Approx(0.5f));
    CHECK(s.active());
    CHECK_FALSE(in.rumble_state(2).active());  // another pad is not touched

    in.advance_rumble(0.25);
    CHECK(in.rumble_state(0).remaining == doctest::Approx(0.25f));
    const std::uint32_t serial = in.rumble_state(0).serial;
    in.rumble(req(0, 1.0f, 0.0f, 0.4f));  // replaces: new strengths and a new time, not the sum
    CHECK(in.rumble_state(0).low == 1.0f);
    CHECK(in.rumble_state(0).high == 0.0f);
    CHECK(in.rumble_state(0).remaining == doctest::Approx(0.4f));
    CHECK(in.rumble_state(0).serial != serial);

    in.advance_rumble(0.3);
    CHECK(in.rumble_state(0).active());
    in.advance_rumble(0.3);  // the time is up
    CHECK_FALSE(in.rumble_state(0).active());
    CHECK(in.rumble_state(0).low == 0.0f);
    in.advance_rumble(0.0);  // no time, no change; a negative time is ignored
    in.advance_rumble(-1.0);
}

TEST_CASE("Input rumble: the log keeps what was asked, clamped, also for a pad that is not there") {
    Input in;
    in.rumble(req(1, 2.0f, -3.0f, 99.0f));  // pad 1 is not connected: logged, clamped, no motors
    in.rumble(req(7, 0.5f, 0.5f, 0.5f));    // not a pad: ignored
    in.rumble(req(-1, 0.5f, 0.5f, 0.5f));
    REQUIRE(in.rumble_requests().size() == 1);
    CHECK(in.rumble_requests()[0] == req(1, 1.0f, 0.0f, kMaxRumbleSeconds));
    CHECK_FALSE(in.rumble_state(1).active());

    in.on_gamepad_connected(1, true);
    in.rumble(req(1, 0.5f, 0.5f, 1.0f));
    in.stop_rumble(1);  // a stop is a request of 0 seconds
    REQUIRE(in.rumble_requests().size() == 3);
    CHECK(in.rumble_requests()[2] == req(1, 0.0f, 0.0f, 0.0f));
    CHECK_FALSE(in.rumble_state(1).active());

    in.stop_rumble(-1);  // every pad
    CHECK(in.rumble_requests().size() == 3 + kMaxGamepads);
    in.clear_rumble_requests();
    CHECK(in.rumble_requests().empty());
    for (int i = 0; i < 1000; ++i) in.rumble(req(0, 0.1f, 0.1f, 0.1f));
    CHECK(in.rumble_requests().size() == 256);  // nobody clears it in a headless run: the log stays short
}

TEST_CASE("Input rumble: unplugging, losing the focus, the engine's stop and a test reset stop the motors") {
    Input in;
    for (int i = 0; i < 3; ++i) in.on_gamepad_connected(i, true);
    auto start = [&] {
        for (int i = 0; i < 3; ++i) in.rumble(req(i, 0.5f, 0.5f, 5.0f));
    };
    start();
    in.on_gamepad_connected(1, false);  // a pad that is unplugged stops
    CHECK_FALSE(in.rumble_state(1).active());
    CHECK(in.rumble_state(0).active());
    in.rumble(req(1, 0.5f, 0.5f, 1.0f));  // and one that is not there does not start
    CHECK_FALSE(in.rumble_state(1).active());

    in.release_all();  // focus lost: every pad is released and silenced
    for (int i = 0; i < 3; ++i) CHECK_FALSE(in.rumble_state(i).active());

    for (int i = 0; i < 3; ++i) in.on_gamepad_connected(i, true);
    start();
    in.stop_all_rumble();  // pause, a scene change, quit
    for (int i = 0; i < 3; ++i) CHECK_FALSE(in.rumble_state(i).active());

    start();
    in.set_gamepad_rumble_support(0, true, "");
    CHECK(in.gamepad_can_rumble(0));
    in.reset_options();  // a test starts with nothing rumbling, nothing logged and no pad able to rumble
    CHECK(in.rumble_requests().empty());
    CHECK_FALSE(in.rumble_state(0).active());
    CHECK_FALSE(in.gamepad_can_rumble(0));
}

TEST_CASE("Input rumble support: only a connected pad can rumble, and the reason is kept") {
    Input in;
    CHECK_FALSE(in.gamepad_can_rumble(0));
    CHECK_FALSE(in.gamepad_can_rumble(9));
    CHECK(in.gamepad_rumble_reason(9).empty());
    in.set_gamepad_rumble_support(0, true, "ignored when it can");
    CHECK_FALSE(in.gamepad_can_rumble(0));  // no pad in the slot
    in.on_gamepad_connected(0, true);
    CHECK(in.gamepad_can_rumble(0));
    CHECK(in.gamepad_rumble_reason(0).empty());
    in.set_gamepad_rumble_support(0, false, "this pad has no motors");
    CHECK_FALSE(in.gamepad_can_rumble(0));
    CHECK(in.gamepad_rumble_reason(0) == "this pad has no motors");
    in.set_gamepad_rumble_support(-1, true, "");  // ignored
    in.set_gamepad_rumble_support(4, true, "");
}

TEST_CASE("apply_gamepad_rumble logic: a new request starts the motors once, the end and a stop send one stop") {
    Input in;
    GamepadRumbleSync sync;
    FakeHardware hw;
    in.on_gamepad_connected(0, true);

    sync.apply(in, hw);  // nothing asked
    CHECK(hw.calls.empty());
    CHECK(in.gamepad_can_rumble(0));  // the hardware said yes

    in.rumble(req(0, 0.5f, 0.25f, 0.5f));
    sync.apply(in, hw);
    sync.apply(in, hw);  // the same request still playing: nothing new is sent
    REQUIRE(hw.calls.size() == 1);
    CHECK(hw.calls[0] == FakeHardware::Call{0, 0.5f, 0.25f, 0.5f});

    in.advance_rumble(0.25);
    sync.apply(in, hw);
    CHECK(hw.calls.size() == 1);

    in.rumble(req(0, 0.5f, 0.25f, 0.5f));  // the same strengths, asked again: the hardware restarts with the new time
    sync.apply(in, hw);
    REQUIRE(hw.calls.size() == 2);
    CHECK(hw.calls[1].seconds == doctest::Approx(0.5f));

    in.advance_rumble(1.0);  // ends by itself: one stop
    sync.apply(in, hw);
    sync.apply(in, hw);
    REQUIRE(hw.calls.size() == 3);
    CHECK(hw.calls[2] == FakeHardware::Call{0, 0.0f, 0.0f, 0.0f});

    in.rumble(req(0, 1.0f, 1.0f, 2.0f));
    sync.apply(in, hw);
    in.stop_rumble(0);
    sync.apply(in, hw);
    REQUIRE(hw.calls.size() == 5);
    CHECK(hw.calls[4] == FakeHardware::Call{0, 0.0f, 0.0f, 0.0f});

    in.rumble(req(0, 1.0f, 1.0f, 2.0f));
    sync.apply(in, hw);
    in.release_all();  // focus lost: the stop is sent although the pad is gone from Input
    sync.apply(in, hw);
    REQUIRE(hw.calls.size() == 7);
    CHECK(hw.calls[6].low == 0.0f);
}

TEST_CASE(
    "apply_gamepad_rumble logic: a pad that cannot rumble is never driven; a refusal does not stop the bookkeeping") {
    Input in;
    GamepadRumbleSync sync;
    FakeHardware hw;
    hw.can = false;
    in.on_gamepad_connected(0, true);
    in.rumble(req(0, 1.0f, 1.0f, 1.0f));
    sync.apply(in, hw);
    CHECK(hw.calls.empty());
    CHECK_FALSE(in.gamepad_can_rumble(0));
    CHECK(in.gamepad_rumble_reason(0) == "no motors");
    CHECK(in.rumble_state(0).active());  // Input still shows what was asked: a test reads it

    hw.can = true;
    hw.accept = false;  // the system refuses (an unplugged pad): tried once, not every frame
    sync.apply(in, hw);
    sync.apply(in, hw);
    CHECK(hw.calls.size() == 1);
}

#if defined(__linux__) || defined(__APPLE__) || defined(__ANDROID__)
TEST_CASE("the Linux, Apple and Android backends answer 'no' with a reason while no pad is attached") {
    // poll_gamepads() is never called here, so the backend has no pad in any slot: it must not touch the hardware.
    Input in;
    in.on_gamepad_connected(0, true);
    in.rumble(req(0, 1.0f, 1.0f, 1.0f));
    apply_gamepad_rumble(in);
    CHECK_FALSE(in.gamepad_can_rumble(0));
    CHECK_FALSE(in.gamepad_rumble_reason(0).empty());
    CHECK_FALSE(gamepad_backend_rumble_support(-1).can);
    CHECK_FALSE(gamepad_backend_rumble_support(kMaxGamepads).can);
    CHECK_FALSE(gamepad_backend_rumble(0, 1.0f, 1.0f, 1.0f));
}
#endif
